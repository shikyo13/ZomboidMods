--[[
    Barricades Hurt Zombies [Build 42]
    Original mod by Brightex
    Build 42 update and continued development by ZeroTheAbsolute

    A comprehensive zombie damage system that processes attacks on barricades,
    doors, windows, and vehicles. The mod implements sophisticated detection
    and damage calculation systems with high performance and configurability.

    Core Features:
    - Vehicle attack detection through AttackVehicleState targets
    - Material-based damage multipliers
    - Optimized processing with minimal performance impact
    - Comprehensive error handling and safety checks
    - Extensive debug capabilities (disabled by default)

    Damage Multiplier System:
    - Wood (baseline):    1.0x  - Standard damage
    - Metal:             1.25x - 25% increased damage
    - Heavy Metal:       1.4x  - 40% increased damage
    - Light Spikes:      1.5x  - 50% increased damage
    - Heavy Spikes:      1.75x - 75% increased damage
    - Reinforced:        2.0x  - Double damage

    Vehicle System Design:
    - State-based vehicle attack processing
    - Server RPC safety cooldown to prevent duplicate client commands
    - Comprehensive nil checks and error handling
    - Blood effects tied to damage multipliers

    Current SVU3 Status:
    Vehicle damage is functional for vanilla vehicles and can identify
    SVU3 armor script names or visible SVU armor vehicle parts when present.

    Performance Considerations:
    - Cached function calls for reduced overhead
    - Optimized loop structures
    - Minimal logging in production
    - Efficient damage cooldown system
    - Minimal per-zombie work outside attack states
--]]

-- ########################################################################
-- ##  LOGGING & DEBUG CONFIG
-- ########################################################################

local DEBUG_MODE       = false   -- Toggle detailed debug logs (set false for release)
local DEBUG_VEHICLES   = false   -- Extra logging for vehicles
local LOG_ENABLED      = false   -- Master switch for all logs

-- [Fix #11] Structured log levels for granular debug control
local LOG_LEVELS = { NONE = 0, ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4, TRACE = 5 }
local currentLogLevel = LOG_LEVELS.NONE
local DEBUG_LOG_FILE = "BHZDebug.log"
local DEBUG_LOG_DISPLAY_PATH = "Lua/BHZDebug.log"
local debugLogInitialized = false
local debugLogFailed = false
local debugLogFailureReported = false
local eventRegistration = { onLoad = false, onZombieUpdate = false, onClientCommand = false }

local BHZ = {
    VERSION         = "2.2.4",
    THUMP_DMG       = 0.05,   -- Base % damage from thumping
    VEHICLE_DMG     = 0.05,   -- Base % damage from vehicle attacks
    THUMP_FUNC      = nil,    -- Decides which objects can hurt zombies
    BLOOD_ENABLED   = true,
    LOG_ENABLED     = LOG_ENABLED,
}

-- [Fix #13] Debug-only statistics tracking
local stats = { thumpDamageCount = 0, vehicleDamageCount = 0, zombieKills = 0, cycleCount = 0 }

-- ########################################################################
-- ##  COMPATIBILITY HELPERS (42.0 -> 42.18+ safe)
-- ########################################################################

-- Safe game version detection (pcall guards against API differences across builds)
local function getGameVersion()
    local ok, result = pcall(function()
        return tostring(getCore():getVersion())
    end)
    return ok and result or "unknown"
end

-- Read a named sprite property as a string. Returns nil on any failure.
-- Used by getMaterialType to read ThumpSound/DoorSound sprite properties.
-- Canonical binding: props:get(key) (see ISMoveableSpriteProps.lua and
-- PropertyContainer.java:162).
local function getSpriteStringProp(target, key)
    if not target or not key then return nil end
    local ok1, sprite = pcall(target.getSprite, target)
    if not ok1 or not sprite then return nil end
    local ok2, props = pcall(sprite.getProperties, sprite)
    if not ok2 or not props then return nil end
    local ok3, has = pcall(props.has, props, key)
    if not ok3 or not has then return nil end
    local ok4, val = pcall(props.get, props, key)
    if ok4 and val and val ~= "" then return val end
    return nil
end

-- Get the sprite name for an IsoObject (nil on failure). Used as a heuristic
-- fallback for material detection when sprite properties are unset.
local function getSpriteName(target)
    if not target then return nil end
    local ok1, sprite = pcall(target.getSprite, target)
    if not ok1 or not sprite then return nil end
    local ok2, name = pcall(sprite.getName, sprite)
    if ok2 and name and name ~= "" then return name end
    return nil
end

-- Safe blood splat - guards against potential addBloodSplat signature changes
local function safeAddBloodSplat(square, intensity)
    if not square then return end
    if not addBloodSplat then return end
    pcall(addBloodSplat, square, intensity)
end

local function isLocalPlayerObject(player)
    if not player or not getSpecificPlayer then return false end

    local maxPlayers = 4
    if getNumActivePlayers then
        local okCount, count = pcall(getNumActivePlayers)
        if okCount and count and count > 0 then
            maxPlayers = count
        end
    end

    for i = 0, maxPlayers - 1 do
        local okPlayer, localPlayer = pcall(getSpecificPlayer, i)
        if okPlayer and localPlayer and localPlayer == player then
            return true
        end
    end

    return false
end

-- Per-zombie authority check. PZ delegates zombie simulation to the nearest
-- client via IsoZombie.authOwner (see NetworkZombieManager.moveZombie). The
-- side that owns the zombie is the side whose OnZombieUpdate sees accurate
-- state. Processing on the wrong side reads stale state and damage never
-- fires. In SP both isClient and isServer are false and we always process.
-- On a hosted/listen server (both true) the same process handles everything
-- so always process there too.
local function shouldProcessZombie(zombie)
    local client = isClient()
    local server = isServer()
    if not client and not server then return true end           -- singleplayer
    if client and server then return true end                   -- listen server
    local ok, owner = pcall(zombie.getOwner, zombie)
    if not ok then return false end
    if server then
        -- Dedicated server: owns the zombie iff it has NOT delegated authority
        return owner == nil
    end

    -- Dedicated client: when B42 exposes the owning player, only the local
    -- owning client should mutate health. This prevents remote clients from
    -- showing local pre-RPC damage for zombies delegated to another player.
    if zombie.getOwnerPlayer then
        local okPlayer, ownerPlayer = pcall(zombie.getOwnerPlayer, zombie)
        if okPlayer and ownerPlayer then
            return isLocalPlayerObject(ownerPlayer)
        end
    end

    -- Fallback for builds/API states where ownerPlayer is unavailable.
    return owner ~= nil
end

----------------------------------------------------------------------
-- Simple Logging Utilities
----------------------------------------------------------------------

-- We'll cache standard print for minor speed benefit:
local print = print

local function getDebugTimestamp()
    if getTimestampMs then
        local ok, result = pcall(getTimestampMs)
        if ok and result then return tostring(result) end
    end
    return "unknown"
end

local function getDebugSideLabel()
    local client = isClient()
    local server = isServer()
    if client and server then return "listen" end
    if client then return "client" end
    if server then return "server" end
    return "sp"
end

local function reportDebugFileFailure(reason)
    if debugLogFailureReported then return end
    debugLogFailureReported = true
    print("[BHZ] WARNING: " .. DEBUG_LOG_FILE .. " unavailable: " .. tostring(reason))
end

local function writeDebugFileRaw(line, append)
    if debugLogFailed then return end
    if not getFileWriter then
        debugLogFailed = true
        reportDebugFileFailure("getFileWriter missing")
        return
    end

    local okOpen, writer = pcall(getFileWriter, DEBUG_LOG_FILE, true, append == true)
    if not okOpen or not writer then
        debugLogFailed = true
        reportDebugFileFailure(writer or "open failed")
        return
    end

    local okWrite, writeErr = pcall(function()
        writer:write(tostring(line) .. "\n")
        writer:close()
    end)
    if not okWrite then
        debugLogFailed = true
        pcall(function() writer:close() end)
        reportDebugFileFailure(writeErr)
    end
end

local function ensureDebugLogFile()
    if debugLogInitialized or debugLogFailed or not BHZ.LOG_ENABLED then return end
    debugLogInitialized = true
    writeDebugFileRaw(string.format(
        "BHZDebug sessionStart ts=%s version=%s pz=%s side=%s logLevel=%s file=%s",
        getDebugTimestamp(), tostring(BHZ.VERSION), getGameVersion(),
        getDebugSideLabel(), tostring(currentLogLevel), DEBUG_LOG_DISPLAY_PATH), false)
    writeDebugFileRaw("Format: ts=<getTimestampMs> [BHZCore/<category>] <message>", true)
end

local function logToConsole(msg)
    if BHZ.LOG_ENABLED then
        print(msg)
    end
end

function BHZ.logToFile(msg)
    if not BHZ.LOG_ENABLED then return end
    ensureDebugLogFile()
    if debugLogFailed then return end
    writeDebugFileRaw("ts=" .. getDebugTimestamp() .. " " .. tostring(msg), true)
end

function BHZ.log(msg, category)
    if not BHZ.LOG_ENABLED then return end
    local prefix = "[BHZCore"
    if category then
        prefix = prefix .. "/" .. tostring(category)
    end
    prefix = prefix .. "] "
    local output = prefix .. tostring(msg)
    logToConsole(output)
    BHZ.logToFile(output)
end

-- [Fix #11] debugPrint now accepts an optional log level parameter
local function debugPrint(msg, category, level)
    if not DEBUG_MODE then return end
    level = level or LOG_LEVELS.DEBUG
    if currentLogLevel < level then return end
    BHZ.log(msg, category or "Debug")
end

local function logAt(level, category, msg)
    if currentLogLevel < level then return end
    BHZ.log(msg, category)
end

local function summarizeSimpleTable(tbl)
    if type(tbl) ~= "table" then return "nil" end
    local parts = {}
    for key, value in pairs(tbl) do
        local valueType = type(value)
        if valueType ~= "table" and valueType ~= "function" and valueType ~= "userdata" then
            parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)
        end
    end
    pcall(table.sort, parts)
    return table.concat(parts, ",")
end

local function getModInfoValue(modInfo, methodName)
    if not modInfo or not methodName then return nil end
    local method = modInfo[methodName]
    if not method then return nil end
    local ok, result = pcall(method, modInfo)
    if ok and result ~= nil and tostring(result) ~= "" then return tostring(result) end
    return nil
end

local function getActiveModsSummary()
    if not getActivatedMods then return "available=false" end
    local okList, list = pcall(getActivatedMods)
    if not okList or not list then return "available=false" end

    local count = 0
    local okSize, size = pcall(list.size, list)
    if okSize and size then count = size end

    local mods = {}
    for i = 0, count - 1 do
        local okGet, modId = pcall(list.get, list, i)
        if okGet and modId then
            modId = tostring(modId)
            local label = modId
            if getModInfoByID then
                local okInfo, modInfo = pcall(getModInfoByID, modId)
                if okInfo and modInfo then
                    local name = getModInfoValue(modInfo, "getName")
                    local version = getModInfoValue(modInfo, "getVersion")
                    local workshopId = getModInfoValue(modInfo, "getWorkshopID")
                    if name then label = label .. " name=" .. name end
                    if version then label = label .. " version=" .. version end
                    if workshopId then label = label .. " workshop=" .. workshopId end
                end
            end
            mods[#mods + 1] = label
        end
    end

    return "count=" .. tostring(count) .. " activeMods=[" .. table.concat(mods, "; ") .. "]"
end

local function clampHealthValue(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    return value
end

local function getExpectedHpAfter(currentHp, damage)
    return clampHealthValue((tonumber(currentHp) or 0) - (tonumber(damage) or 0))
end

local function getTicksToKill(currentHp, damage)
    currentHp = tonumber(currentHp) or 0
    damage = tonumber(damage) or 0
    if currentHp <= 0 then return "0" end
    if damage <= 0 then return "never" end
    return tostring(math.ceil(currentHp / damage))
end

local function formatFormula(baseLabel, baseDamage, materialType, materialMult, objectMult)
    if objectMult == nil or tostring(objectMult) == "nil" then
        return string.format("%s %.4f * %s %.3f", baseLabel, baseDamage, tostring(materialType), materialMult)
    end
    return string.format("%s %.4f * %s %.3f * object %.3f",
        baseLabel, baseDamage, tostring(materialType), materialMult, tonumber(objectMult) or 1.0)
end

local function getSideLabel()
    return getDebugSideLabel()
end

local function getPlayerLabel(player)
    if not player then return "nil" end

    local id = "?"
    if player.getOnlineID then
        local okId, onlineId = pcall(player.getOnlineID, player)
        if okId and onlineId ~= nil then id = tostring(onlineId) end
    end

    local name = nil
    if player.getUsername then
        local okUser, username = pcall(player.getUsername, player)
        if okUser and username then name = tostring(username) end
    end
    if not name and player.getDisplayName then
        local okDisplay, displayName = pcall(player.getDisplayName, player)
        if okDisplay and displayName then name = tostring(displayName) end
    end

    if not name then name = tostring(player) end
    return name .. "#" .. id
end

local function getZombieOwnerLabel(zombie)
    if not zombie then return "nil" end

    local ownerLabel = "missing"
    if zombie.getOwner then
        local okOwner, owner = pcall(zombie.getOwner, zombie)
        ownerLabel = okOwner and tostring(owner) or "err"
    end

    local playerLabel = "missing"
    if zombie.getOwnerPlayer then
        local okPlayer, ownerPlayer = pcall(zombie.getOwnerPlayer, zombie)
        playerLabel = okPlayer and getPlayerLabel(ownerPlayer) or "err"
    end

    return "owner=" .. ownerLabel .. " ownerPlayer=" .. playerLabel
end

local function getTargetLabel(target)
    if not target then return "nil" end

    local typeName = "Object"
    if instanceof(target, "IsoBarricade") then
        typeName = "IsoBarricade"
    elseif instanceof(target, "IsoWindow") then
        typeName = "IsoWindow"
    elseif instanceof(target, "IsoDoor") then
        typeName = "IsoDoor"
    elseif instanceof(target, "IsoThumpable") then
        typeName = "IsoThumpable"
    elseif instanceof(target, "BaseVehicle") then
        typeName = "BaseVehicle"
    end

    local spriteName = getSpriteName(target) or "nil"
    local pos = "?, ?, ?"
    local square = nil
    if target.getSquare then
        local okSquare, result = pcall(target.getSquare, target)
        if okSquare then square = result end
    end
    if square then
        pos = tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
    end

    return typeName .. " sprite=" .. spriteName .. " pos=" .. pos
end

local function getPartLabel(part)
    if not part then return "nil" end
    if part.getId then
        local okId, partId = pcall(part.getId, part)
        if okId and partId then return tostring(partId) end
    end
    return tostring(part)
end

local function getVehicleLabel(vehicle)
    if not vehicle then return "nil" end
    local scriptName = "unknown"
    if vehicle.getScript then
        local okScript, script = pcall(vehicle.getScript, vehicle)
        if okScript and script and script.getName then
            local okName, name = pcall(script.getName, script)
            if okName and name then scriptName = tostring(name) end
        end
    end
    return "script=" .. scriptName .. " obj=" .. tostring(vehicle)
end

-- ########################################################################
-- ##  MULTIPLIERS & MATERIAL TABLES
-- ########################################################################

local GAME_SPEED_MULTIPLIERS = {1, 2, 3, 4}

local DEFAULT_MULTIPLIERS = {
    WOOD         = 1.0,
    METAL        = 1.25,
    METAL_HEAVY  = 1.4,
    LIGHT_SPIKE  = 1.5,
    HEAVY_SPIKE  = 1.75,
    REINFORCED   = 2.0,
}

local MaterialDamageMultiplier = {
    WOOD         = DEFAULT_MULTIPLIERS.WOOD,
    METAL        = DEFAULT_MULTIPLIERS.METAL,
    METAL_HEAVY  = DEFAULT_MULTIPLIERS.METAL_HEAVY,
    LIGHT_SPIKE  = DEFAULT_MULTIPLIERS.LIGHT_SPIKE,
    HEAVY_SPIKE  = DEFAULT_MULTIPLIERS.HEAVY_SPIKE,
    REINFORCED   = DEFAULT_MULTIPLIERS.REINFORCED,
}

-- ########################################################################
-- ##  MOD DETECTION (SVU3)
-- ########################################################################

-- Helper to see if a given mod is active:
local function isModActive(modName)
    local getActivatedMods = getActivatedMods
    if not getActivatedMods then return false end

    local list = getActivatedMods()
    if not list then return false end

    for i = 0, list:size() - 1 do
        if list:get(i) == modName then
            return true
        end
    end
    return false
end

local SVU3_MOD_IDS       = { "StandardizedVehicleUpgrades3V", "\\StandardizedVehicleUpgrades3V" }
local KITSUNELIB_MOD_IDS = { "kitsunelib", "\\kitsunelib" }

local function isAnyModActive(modIds)
    for _, modId in ipairs(modIds) do
        if isModActive(modId) then return true end
    end
    return false
end

local hasSVU = isAnyModActive(SVU3_MOD_IDS) and isAnyModActive(KITSUNELIB_MOD_IDS)
debugPrint("SVU3 compatibility check: " .. tostring(hasSVU))

-- ########################################################################
-- ##  VEHICLE MATERIAL CLASSIFICATION
-- ########################################################################

-- If the partId literally starts with 'SVU_Armor_', treat it as heavy metal:
local function isSVUArmorPartId(part)
    if not part then return false end
    local partId = part:getId()
    local isSvu = partId and partId:find("^SVU_Armor_") ~= nil
    if DEBUG_VEHICLES then
        debugPrint("Checking SVU armor: "..tostring(partId)
                   .." => "..tostring(isSvu), "Vehicle")
    end
    return isSvu
end

local function getVehicleMaterialType(vehicle, part)
    if not vehicle then
        return "METAL"
    end

    -- 1) Possibly check the entire vehicle script name for SVU_ armor
    local script = vehicle:getScript()
    if not script then
        debugPrint("Vehicle script is nil. Defaulting to METAL.", "Vehicle")
        return "METAL"
    end

    local vehicleType = script:getName()
    if not vehicleType then
        debugPrint("Vehicle type name is nil. Defaulting to METAL.", "Vehicle")
        return "METAL"
    end

    debugPrint("Checking vehicle type: "..vehicleType, "Vehicle")

    -- If the entire script is an SVU armor type, see if it's spiked, light, or reinforced
    local lowerName = vehicleType:lower()
    if lowerName:find("svu_armor_") then
        if lowerName:find("spiked") then
            debugPrint("Detected spiked armor from script="..vehicleType, "Vehicle")
            return "HEAVY_SPIKE"
        elseif lowerName:find("light") then
            debugPrint("Detected light armor from script="..vehicleType, "Vehicle")
            return "LIGHT_SPIKE"
        elseif lowerName:find("reinforced") then
            debugPrint("Detected reinforced armor from script="..vehicleType, "Vehicle")
            return "REINFORCED"
        else
            -- e.g. "SVU_Armor_LuxuryCar_Heavy"
            debugPrint("Detected heavy armor from script="..vehicleType, "Vehicle")
            return "METAL_HEAVY"
        end
    end

    -- 2) If not an SVU_Armor script, but the part's ID is "SVU_Armor_Front", etc.
    if part and isSVUArmorPartId(part) then
        debugPrint("Found SVU armor part: "..part:getId(), "Vehicle")
        return "METAL_HEAVY"
    end

    -- 3) Fallback logic for standard vehicles
    if vehicleType:contains("Van") or vehicleType:contains("Truck") or vehicleType:contains("Step") then
        debugPrint("Heavy vehicle detected", "Vehicle")
        return "METAL"
    end

    debugPrint("Standard vehicle detected", "Vehicle")
    return "METAL"
end

local function getVehicleWindowForPart(part)
    if not part then return nil end

    local okWindow, window = pcall(part.getWindow, part)
    if (not okWindow) or not window then
        local okFind, foundWindow = pcall(part.findWindow, part)
        if okFind then window = foundWindow end
    end
    if not window then return nil end

    local okHit, isHit = pcall(window.isHittable, window)
    if okHit and isHit then
        return window
    end
    return nil
end

local function getVehicleAttackTarget(vehicle, zombie, target)
    if not vehicle or not zombie then return nil end

    -- Mirror enough of B42's AttackVehicleState part choice to identify armor
    -- parts when a vehicle mod exposes them through the normal vehicle part API.
    if target then
        local okSeat, seat = pcall(vehicle.getSeat, vehicle, target)
        if okSeat and seat and seat >= 0 then
            local okArea, areaId = pcall(vehicle.getPassengerArea, vehicle, seat)
            if okArea and areaId then
                local okInArea, inArea = pcall(vehicle.isInArea, vehicle, areaId, zombie)
                if okInArea and inArea then
                    local okDoor, door = pcall(vehicle.getPassengerDoor, vehicle, seat)
                    if okDoor and door then
                        local okDoorObj, doorObj = pcall(door.getDoor, door)
                        local okItem, invItem = pcall(door.getInventoryItem, door)
                        if okDoorObj and doorObj and okItem and invItem then
                            local okOpen, isOpen = pcall(doorObj.isOpen, doorObj)
                            if not (okOpen and isOpen) then
                                return door, getVehicleWindowForPart(door)
                            end
                        end
                    end
                end
            end
        end
    end

    local okPart, part = pcall(vehicle.getNearestBodyworkPart, vehicle, zombie)
    if okPart and part then
        return part, getVehicleWindowForPart(part)
    end

    return nil
end

-- ########################################################################
-- ##  ZOMBIE DAMAGE SYSTEM
-- ########################################################################

local DAMAGE_MODE      = 1

local cleanupCounter = 0
local zombieDamageCooldowns = {}
local zombieDamageStats = {}
local zombieHitSignals = {}
local zombieHitSubjects = {}
local vehicleHitSignals = {}
local hitSignalWarned = {}
local HIT_SIGNAL_EPSILON = 0.0001

-- ########################################################################
-- ##  THUMPING (Barricades/Doors/Windows)
-- ########################################################################

-- Sound prefix -> material mapping. Source: IsoThumpable.getSoundPrefix() and
-- IsoDoor.getSoundPrefix() (both read the sprite "DoorSound" property). These
-- are the canonical vanilla vocabulary for door/gate material classification.
local SOUND_PREFIX_MATERIAL = {
    WoodDoor            = "WOOD",
    MetalDoor           = "METAL",
    PrisonMetalDoor     = "METAL_HEAVY",
    MetalGate           = "METAL",        -- chainlink fence
    MetalPoleGate       = "METAL",
    MetalPoleGateDouble = "METAL",
    GarageDoor          = "METAL_HEAVY",
    SlidingGlassDoor    = "WOOD",         -- glass, treat as base damage
}

-- Sprite "ThumpSound" property -> material mapping. Used by non-door
-- IsoThumpables (log walls, player-built walls, metal walls) per
-- IsoThumpable.getMeleeHitSurface() switch at lines 2190-2200.
local THUMP_SOUND_MATERIAL = {
    ZombieThumpWood            = "WOOD",
    ZombieThumpGeneric         = "WOOD",
    ZombieThumpWindow          = "WOOD",
    ZombieThumpWindowExtra     = "WOOD",
    ZombieThumpMetal           = "METAL",
    ZombieThumpMetalPoleGate   = "METAL",
    ZombieThumpMetalPoleFence  = "METAL",
    ZombieThumpChainlinkFence  = "METAL",
    ZombieThumpGarageDoor      = "METAL_HEAVY",
}

local function getMaterialType(target)
    if not target then return "WOOD" end

    -- IsoBarricade: dedicated isMetal()/isMetalBar() class methods
    if instanceof(target, "IsoBarricade") then
        local ok1, isMetal = pcall(target.isMetal, target)
        if ok1 and isMetal then
            debugPrint("IsoBarricade => METAL")
            return "METAL"
        end
        local ok2, isMetalBar = pcall(target.isMetalBar, target)
        if ok2 and isMetalBar then
            debugPrint("IsoBarricade => METAL (bar)")
            return "METAL"
        end
        debugPrint("IsoBarricade => WOOD")
        return "WOOD"
    end

    -- IsoWindow: glass, no metal variants in vanilla
    if instanceof(target, "IsoWindow") then
        debugPrint("IsoWindow => WOOD (glass)")
        return "WOOD"
    end

    -- IsoDoor: always has closedSprite, so getSoundPrefix() reads DoorSound.
    if instanceof(target, "IsoDoor") then
        local ok, prefix = pcall(target.getSoundPrefix, target)
        if ok and prefix then
            local mat = SOUND_PREFIX_MATERIAL[prefix]
            if mat then
                debugPrint("IsoDoor DoorSound="..prefix.." => "..mat)
                return mat
            end
            debugPrint("IsoDoor DoorSound="..prefix.." unknown => WOOD")
        end
        return "WOOD"
    end

    -- IsoThumpable: split by isDoor() because non-door thumpables have no
    -- closedSprite, which makes getSoundPrefix() return "WoodDoor" unconditionally
    -- (see IsoThumpable.java:2173). Non-door thumpables (log walls, metal walls,
    -- chainlink fences) carry their material via the sprite "ThumpSound" property
    -- instead (matches PZ's own getMeleeHitSurface at IsoThumpable.java:2188).
    if instanceof(target, "IsoThumpable") then
        local okIsDoor, isDoor = pcall(target.isDoor, target)
        if okIsDoor and isDoor then
            local ok, prefix = pcall(target.getSoundPrefix, target)
            if ok and prefix then
                local mat = SOUND_PREFIX_MATERIAL[prefix]
                if mat then
                    debugPrint("Thumpable(door) DoorSound="..prefix.." => "..mat)
                    return mat
                end
                debugPrint("Thumpable(door) DoorSound="..prefix.." unknown => WOOD")
            end
            return "WOOD"
        end

        -- Non-door thumpable: use sprite ThumpSound property
        local thumpSound = getSpriteStringProp(target, "ThumpSound")
        if thumpSound then
            local mat = THUMP_SOUND_MATERIAL[thumpSound]
            if mat then
                debugPrint("Thumpable ThumpSound="..thumpSound.." => "..mat)
                return mat
            end
        end

        -- Sprite name heuristic fallback (for tiles with no ThumpSound set).
        -- Vanilla fencing sprite naming: fencing_01_24..28 short chainlink,
        -- fencing_01_56..60 tall chainlink, fencing_01_64..68 metal bars, etc.
        -- String.find is cheap and only runs when property lookup fails.
        local spriteName = getSpriteName(target)
        if spriteName then
            local lower = string.lower(spriteName)
            if string.find(lower, "chainlink", 1, true)
               or string.find(lower, "metal", 1, true)
               or string.find(lower, "bars", 1, true) then
                debugPrint("Thumpable sprite="..spriteName.." => METAL (heuristic)")
                return "METAL"
            end
            debugPrint("Thumpable sprite="..spriteName.." ts="..tostring(thumpSound).." => WOOD")
        else
            debugPrint("Thumpable no sprite, ts="..tostring(thumpSound).." => WOOD")
        end
        return "WOOD"
    end

    return "WOOD"
end

local function checkNormalDamageSources(thump_target)
    if not thump_target then return false end
    if instanceof(thump_target, "IsoThumpable") then return true end
    if instanceof(thump_target, "IsoBarricade") then return true end
    if instanceof(thump_target, "IsoDoor") then return true end
    if instanceof(thump_target, "IsoWindow") then return true end
    if instanceof(thump_target, "BarricadeAble") and not instanceof(thump_target, "IsoThumpable") then
        return thump_target:isBarricaded()
    end
    return false
end

local function checkAll(thump_target)
    return (thump_target ~= nil)
end

local function checkNothing(thump_target)
    return false
end

local function clampNumber(value, fallback, minValue, maxValue)
    local number = tonumber(value)
    if number == nil then number = fallback end
    if minValue ~= nil and number < minValue then number = minValue end
    if maxValue ~= nil and number > maxValue then number = maxValue end
    return number
end

local function getGameTimeScale()
    if not getGameTime then return 1.0 end
    local okTime, gameTime = pcall(getGameTime)
    if not okTime or not gameTime then return 1.0 end

    if gameTime.getTrueMultiplier then
        local okTrue, trueMultiplier = pcall(gameTime.getTrueMultiplier, gameTime)
        trueMultiplier = tonumber(trueMultiplier)
        if okTrue and trueMultiplier and trueMultiplier > 1 then
            return math.min(trueMultiplier, 100.0)
        end
    end

    if gameTime.getMultiplier then
        local okMult, multiplier = pcall(gameTime.getMultiplier, gameTime)
        multiplier = tonumber(multiplier)
        if okMult and multiplier and multiplier > 1 then
            return math.min(multiplier, 100.0)
        end
    end

    return 1.0
end

local function getEffectiveCooldown(configuredCooldown)
    configuredCooldown = tonumber(configuredCooldown) or 0
    if configuredCooldown <= 0 then return 0, 1.0 end

    local timeScale = getGameTimeScale()
    if timeScale <= 1.0 then return configuredCooldown, 1.0 end

    return math.max(1, configuredCooldown / timeScale), timeScale
end

-- ########################################################################
-- ##  SANDBOX SETTINGS
-- ########################################################################

local function onLoad()
    debugPrint("Loading BHZ sandbox settings...")

    -- Reset cooldowns and stats on load
    zombieDamageCooldowns = {}
    zombieDamageStats = {}
    zombieHitSignals = {}
    zombieHitSubjects = {}
    vehicleHitSignals = {}
    hitSignalWarned = {}
    debugLogInitialized = false
    debugLogFailed = false
    debugLogFailureReported = false
    cleanupCounter = 0
    stats.thumpDamageCount = 0
    stats.vehicleDamageCount = 0
    stats.zombieKills = 0
    stats.cycleCount = 0

    local SandboxVars = SandboxVars
    if SandboxVars and SandboxVars.BarricadesHurtZombies then
        local zombieToughness = "unknown"
        if SandboxVars.ZombieLore and SandboxVars.ZombieLore.Toughness ~= nil then
            zombieToughness = tostring(SandboxVars.ZombieLore.Toughness)
        end

        -- Process core damage settings
        local baseDamage = clampNumber(SandboxVars.BarricadesHurtZombies.BaseDamage, 5, 0, 100)
        BHZ.THUMP_DMG = baseDamage / 100
        debugPrint("BaseDamage=" .. baseDamage .. "% => THUMP_DMG=" .. BHZ.THUMP_DMG)

        -- Process vehicle base damage (separate from barricade damage)
        local vehicleBaseDamage = clampNumber(SandboxVars.BarricadesHurtZombies.VehicleBaseDamage, 5, 0, 100)
        BHZ.VEHICLE_DMG = vehicleBaseDamage / 100
        debugPrint("VehicleBaseDamage=" .. vehicleBaseDamage .. "% => VEHICLE_DMG=" .. BHZ.VEHICLE_DMG)

        -- Set up damage mode (what objects can hurt zombies)
        local mode = clampNumber(SandboxVars.BarricadesHurtZombies.DamageMode, 1, 1, 3)
        DAMAGE_MODE = mode
        if mode == 1 then
            BHZ.THUMP_FUNC = checkNormalDamageSources
        elseif mode == 2 then
            BHZ.THUMP_FUNC = checkAll
        else
            BHZ.THUMP_FUNC = checkNothing
        end

        -- Load material multipliers with fallbacks to defaults
        MaterialDamageMultiplier.METAL = clampNumber(SandboxVars.BarricadesHurtZombies.MetalMultiplier, DEFAULT_MULTIPLIERS.METAL, 1.0, 2.0)
        MaterialDamageMultiplier.METAL_HEAVY = clampNumber(SandboxVars.BarricadesHurtZombies.MetalHeavyMultiplier, DEFAULT_MULTIPLIERS.METAL_HEAVY, 1.0, 2.0)
        MaterialDamageMultiplier.LIGHT_SPIKE = clampNumber(SandboxVars.BarricadesHurtZombies.LightSpikeMultiplier, DEFAULT_MULTIPLIERS.LIGHT_SPIKE, 1.0, 2.0)
        MaterialDamageMultiplier.HEAVY_SPIKE = clampNumber(SandboxVars.BarricadesHurtZombies.HeavySpikeMultiplier, DEFAULT_MULTIPLIERS.HEAVY_SPIKE, 1.0, 2.0)
        MaterialDamageMultiplier.REINFORCED = clampNumber(SandboxVars.BarricadesHurtZombies.ReinforcedMultiplier, DEFAULT_MULTIPLIERS.REINFORCED, 1.0, 2.0)

        -- Configure visual effects
        BHZ.BLOOD_ENABLED = SandboxVars.BarricadesHurtZombies.BloodEffects ~= false

        -- Configure debug settings
        DEBUG_MODE = SandboxVars.BarricadesHurtZombies.DebugMode or false
        DEBUG_VEHICLES = SandboxVars.BarricadesHurtZombies.VehicleDebugMode or false

        -- LogLevel enum: 1=None, 2=Error, 3=Warn, 4=Info, 5=Debug, 6=Trace
        local logLevelEnum = clampNumber(SandboxVars.BarricadesHurtZombies.LogLevel, 1, 1, 6)
        currentLogLevel = math.max(0, logLevelEnum - 1) -- enum is 1-indexed, LOG_LEVELS is 0-indexed

        -- Debug toggles keep diagnostic logs visible, but trace spam is only
        -- enabled by explicitly setting LogLevel to Trace.
        if (DEBUG_MODE or DEBUG_VEHICLES) and currentLogLevel < LOG_LEVELS.DEBUG then
            currentLogLevel = LOG_LEVELS.DEBUG
        end

        BHZ.LOG_ENABLED = currentLogLevel > LOG_LEVELS.NONE

        logAt(LOG_LEVELS.INFO, "Environment", string.format(
            "pz=%s bhz=%s side=%s isClient=%s isServer=%s debugFile=%s",
            getGameVersion(), tostring(BHZ.VERSION), getSideLabel(), tostring(isClient()),
            tostring(isServer()), DEBUG_LOG_DISPLAY_PATH))

        logAt(LOG_LEVELS.INFO, "Sandbox", "BHZ " .. summarizeSimpleTable(SandboxVars.BarricadesHurtZombies))
        logAt(LOG_LEVELS.INFO, "Sandbox", "ZombieLore " .. summarizeSimpleTable(SandboxVars.ZombieLore))
        logAt(LOG_LEVELS.INFO, "Mods", getActiveModsSummary())

        logAt(LOG_LEVELS.INFO, "Config", string.format(
            "side=%s base=%.2f vehicleBase=%.2f mode=%s realHitRequired=true mults={wood=%.2f,metal=%.2f,heavy=%.2f,lightSpike=%.2f,heavySpike=%.2f,reinforced=%.2f} blood=%s debugMode=%s vehicleDebug=%s logLevel=%s debugFile=%s ZombieLore.Toughness=%s",
            getSideLabel(), baseDamage, vehicleBaseDamage, tostring(mode), MaterialDamageMultiplier.WOOD, MaterialDamageMultiplier.METAL,
            MaterialDamageMultiplier.METAL_HEAVY, MaterialDamageMultiplier.LIGHT_SPIKE,
            MaterialDamageMultiplier.HEAVY_SPIKE, MaterialDamageMultiplier.REINFORCED,
            tostring(BHZ.BLOOD_ENABLED), tostring(DEBUG_MODE), tostring(DEBUG_VEHICLES),
            tostring(currentLogLevel), DEBUG_LOG_DISPLAY_PATH, zombieToughness))

        logAt(LOG_LEVELS.INFO, "Events", string.format(
            "registered onLoad=%s onZombieUpdate=%s onClientCommand=%s",
            tostring(eventRegistration.onLoad), tostring(eventRegistration.onZombieUpdate),
            tostring(eventRegistration.onClientCommand)))

        -- Log the configuration if debugging is enabled
        if DEBUG_MODE then
            debugPrint("BHZ Configuration loaded:")
            debugPrint(string.format("  Base Damage: %.1f%%", baseDamage))
            debugPrint(string.format("  Damage Mode: %d", mode))
            debugPrint(string.format("  Metal Multiplier: %.2fx", MaterialDamageMultiplier.METAL))
            debugPrint("  Real Hit Required: true")
            debugPrint(string.format("  Log Level: %d", currentLogLevel))
        end
    else
        -- If no sandbox settings found, use safe defaults
        debugPrint("No sandbox config => using defaults")
        BHZ.THUMP_DMG = 0.05      -- 5% base damage
        BHZ.VEHICLE_DMG = 0.05    -- 5% vehicle base damage
        BHZ.THUMP_FUNC = checkNormalDamageSources
        BHZ.BLOOD_ENABLED = true
        DAMAGE_MODE = 1
        DEBUG_MODE = false
        DEBUG_VEHICLES = false
        BHZ.LOG_ENABLED = false
        currentLogLevel = LOG_LEVELS.NONE

        -- Reset all multipliers to defaults
        for mat, mult in pairs(DEFAULT_MULTIPLIERS) do
            MaterialDamageMultiplier[mat] = mult
        end
    end

    debugPrint("BHZ mod settings loaded")

    -- Always print startup banner (dev build visibility)
    local startupMessage = "[BHZ] BarricadesHurtZombies v" .. BHZ.VERSION .. " | PZ=" .. getGameVersion()
        .. " | THUMP_DMG=" .. BHZ.THUMP_DMG
        .. " VEHICLE_DMG=" .. BHZ.VEHICLE_DMG
        .. " LogLevel=" .. currentLogLevel
        .. " Blood=" .. tostring(BHZ.BLOOD_ENABLED)
        .. " Side=" .. getDebugSideLabel()
    print(startupMessage)
    BHZ.logToFile(startupMessage)
end

-- ########################################################################
-- ##  DAMAGE APPLICATION (authoritative side only)
-- ########################################################################

local function getZombieDamageStats(zombieId)
    local key = tostring(zombieId)
    local entry = zombieDamageStats[key]
    if not entry then
        entry = { hits = 0, computedTotal = 0, actualTotal = 0 }
        zombieDamageStats[key] = entry
    end
    return entry
end

local function detailValue(detail, key, fallback)
    if detail and detail[key] ~= nil then return detail[key] end
    return fallback
end

local function clearZombieHitSignals(zombieId)
    local idNeedle = ":" .. tostring(zombieId) .. ":"
    for key in pairs(zombieHitSignals) do
        if string.find(key, idNeedle, 1, true) then
            zombieHitSignals[key] = nil
        end
    end
    zombieHitSubjects[tostring(zombieId)] = nil
end

-- Apply a specific health value directly. The caller must already be on an
-- authoritative simulation side, or be applying an idempotent server target.
local function applyHealthLocally(zombie, zombieId, oldHealth, newHealth, damage, bloodIntensity, materialType, source, showBlood, detail)
    if showBlood == nil then showBlood = true end
    if newHealth < 0 then newHealth = 0 end
    local actualRemoved = oldHealth - newHealth
    if actualRemoved < 0 then actualRemoved = 0 end

    if currentLogLevel >= LOG_LEVELS.INFO then
        BHZ.log(string.format("DMG side=%s zombie=%s hp=%.3f->%.3f dmg=%.4f mat=%s src=%s blood=%s",
            getSideLabel(), tostring(zombieId), oldHealth, newHealth, damage,
            tostring(materialType or "unknown"), source, tostring(showBlood)), "Damage")

        local tickStats = getZombieDamageStats(zombieId)
        tickStats.hits = tickStats.hits + 1
        tickStats.computedTotal = tickStats.computedTotal + damage
        tickStats.actualTotal = tickStats.actualTotal + actualRemoved

        local formula = tostring(detailValue(detail, "formula", tostring(source) .. "Damage"))
        local baseDamage = tonumber(detailValue(detail, "base", damage)) or damage
        local materialLabel = tostring(materialType or detailValue(detail, "material", "unknown"))
        local materialMult = tonumber(detailValue(detail, "materialMult", 1.0)) or 1.0
        local objectMult = detailValue(detail, "objectMultRaw", nil)
        if objectMult == nil then objectMult = detailValue(detail, "objectMult", "nil") end
        local cooldown = detailValue(detail, "cooldown", "unknown")
        local effectiveCooldown = detailValue(detail, "effectiveCooldown", "unknown")
        local timeScale = detailValue(detail, "timeScale", "1")
        local targetLabel = tostring(detailValue(detail, "target", "nil"))
        local vehicleLabel = tostring(detailValue(detail, "vehicle", "nil"))
        local partLabel = tostring(detailValue(detail, "part", "nil"))
        local eventLabel = tostring(detailValue(detail, "event", "none"))
        local readableFormula = formatFormula("base", baseDamage, materialLabel, materialMult, objectMult)

        BHZ.log(string.format(
            "TICK side=%s zombie=%s hit=%s src=%s event=%s hp %.3f -> %.3f damage=%.4f actualRemoved=%.4f computedDmg=%.4f totals removed=%.4f computed=%.4f totalRemoved=%.4f totalComputed=%.4f readableFormula=(%s) formula=%s base=%.4f material=%s materialMult=%.3f objectMult=%s oldHp=%.3f newHp=%.3f cooldown=%s effectiveCooldown=%s timeScale=%s target=[%s] vehicle=[%s] part=%s blood=%s",
            getSideLabel(), tostring(zombieId), tostring(tickStats.hits), tostring(source),
            eventLabel, oldHealth, newHealth, damage, actualRemoved, damage, tickStats.actualTotal,
            tickStats.computedTotal, tickStats.actualTotal, tickStats.computedTotal,
            readableFormula, formula, baseDamage, materialLabel, materialMult,
            tostring(objectMult), oldHealth, newHealth, tostring(cooldown),
            tostring(effectiveCooldown), tostring(timeScale), targetLabel, vehicleLabel,
            partLabel, tostring(showBlood)), "Tick")
    end

    if newHealth <= 0 then
        zombieDamageCooldowns[zombieId] = nil
        zombieDamageStats[tostring(zombieId)] = nil
        clearZombieHitSignals(zombieId)
        zombie:setHealth(0)
        local cell = zombie:getCell()
        if cell then
            pcall(zombie.Kill, zombie, zombie)
        end
        if currentLogLevel >= LOG_LEVELS.DEBUG then
            BHZ.log("Killed zombie " .. tostring(zombieId) .. " (hp=" .. oldHealth .. "->0)", "Kill")
            stats.zombieKills = stats.zombieKills + 1
        end
    else
        zombie:setHealth(newHealth)
        if showBlood and BHZ.BLOOD_ENABLED then
            local square = zombie:getSquare()
            if square then safeAddBloodSplat(square, bloodIntensity) end
        end
    end

    return newHealth
end

-- Apply damage directly to the zombie. Runs on SP, server-owned zombies, or
-- client-owned zombies on their owning client. For client-owned MP zombies,
-- the local health mutation is required because PZ's regular zombie sync
-- packet serializes zombie.health from the owner.
local function applyDamageLocally(zombie, zombieId, damage, bloodIntensity, materialType, source, showBlood, detail)
    local oldHealth = zombie:getHealth()
    local newHealth = oldHealth - damage
    return applyHealthLocally(zombie, zombieId, oldHealth, newHealth, damage, bloodIntensity, materialType, source, showBlood, detail)
end

-- Apply an absolute target health value. Server RPCs from client-owned zombies
-- use this to avoid order-dependent double damage: if the regular zombie sync
-- packet already applied the same health, this becomes a no-op apart from blood.
local function applyTargetHealthLocally(zombie, zombieId, targetHealth, damage, bloodIntensity, materialType, source, detail)
    local oldHealth = zombie:getHealth()
    if targetHealth > oldHealth then targetHealth = oldHealth end
    return applyHealthLocally(zombie, zombieId, oldHealth, targetHealth, damage, bloodIntensity, materialType, source, true, detail)
end

-- Dispatch damage. On a pure client, apply locally first because this client
-- owns the zombie simulation and its next normal zombie sync packet carries
-- zombie.health to the server. Then send an idempotent server command for
-- blood feedback and for server state before the next sync packet arrives.
-- On SP, dedicated server, or listen server, apply directly.
local function dispatchZombieDamage(zombie, zombieId, damage, bloodIntensity, materialType, source, detail)
    if type(damage) ~= "number" or damage <= 0 then
        logAt(LOG_LEVELS.TRACE, "Damage", string.format(
            "SKIP_ZERO_DAMAGE side=%s zombie=%s src=%s damage=%s",
            getSideLabel(), tostring(zombieId), tostring(source), tostring(damage)))
        return
    end

    -- Server-side (dedicated or listen) and SP all apply locally
    if isServer() or not isClient() then
        applyDamageLocally(zombie, zombieId, damage, bloodIntensity, materialType, source, nil, detail)
        return
    end
    -- Pure client: forward to server via RPC
    if type(zombieId) ~= "number" or zombieId <= 0 then return end
    local targetHealth = applyDamageLocally(zombie, zombieId, damage, bloodIntensity, materialType, source, false, detail)
    sendClientCommand("BHZ", "applyDamage", {
        id = zombieId,
        dmg = damage,
        hp = targetHealth,
        blood = bloodIntensity,
        src = source,
        mat = materialType,
        formula = detailValue(detail, "formula", nil),
        base = detailValue(detail, "base", nil),
        materialMult = detailValue(detail, "materialMult", nil),
        objectMult = detailValue(detail, "objectMult", nil),
        objectMultRaw = detailValue(detail, "objectMultRaw", nil),
        cooldown = detailValue(detail, "cooldown", nil),
        effectiveCooldown = detailValue(detail, "effectiveCooldown", nil),
        timeScale = detailValue(detail, "timeScale", nil),
        target = detailValue(detail, "target", nil),
        vehicle = detailValue(detail, "vehicle", nil),
        part = detailValue(detail, "part", nil),
        event = detailValue(detail, "event", nil),
    })
    logAt(LOG_LEVELS.DEBUG, "MP", string.format(
        "RPC_SEND side=%s zombie=%s targetHp=%.3f dmg=%.4f src=%s %s",
        getSideLabel(), tostring(zombieId), targetHealth, damage, source, getZombieOwnerLabel(zombie)))
end

local function warnHitSignalUnavailable(source, status)
    local key = tostring(source) .. ":" .. tostring(status)
    if hitSignalWarned[key] then return end
    hitSignalWarned[key] = true
    logAt(LOG_LEVELS.WARN, "HitSignal", string.format(
        "HIT_SIGNAL_UNAVAILABLE src=%s status=%s action=skip_damage",
        tostring(source), tostring(status)))
end

local function makeSignalKey(source, id, subjectLabel)
    return tostring(source) .. ":" .. tostring(id) .. ":" .. tostring(subjectLabel)
end

local function readZombieThumpCondition(zombie)
    if not zombie then return nil, "missing_zombie" end

    local okCondition, condition = pcall(zombie.getThumpCondition, zombie)
    if not okCondition then
        return nil, "getThumpCondition_error:" .. tostring(condition)
    end

    condition = tonumber(condition)
    if condition == nil then
        return nil, "missing_thumpCondition"
    end

    return condition, "ok"
end

-- Vanilla ThumpState writes the hit object's condition onto the zombie after
-- a real structure thump. Track that per zombie, so a shared door health drop
-- does not damage every zombie touching the same door.
local function shouldProcessStructureHit(zombie, zombieId, subjectLabel)
    local condition, status = readZombieThumpCondition(zombie)
    if condition == nil then
        warnHitSignalUnavailable("thump", status)
        return false, "unavailable:" .. tostring(status)
    end

    local now = getTimestampMs()
    local key = makeSignalKey("thump", zombieId, subjectLabel)
    local subjectKey = tostring(zombieId)
    local subjectEntry = zombieHitSubjects[subjectKey]
    local entry = zombieHitSignals[key]
    if (not subjectEntry) or subjectEntry.subject ~= subjectLabel then
        zombieHitSubjects[subjectKey] = { subject = subjectLabel, lastSeen = now }
        zombieHitSignals[key] = { condition = condition, lastSeen = now }
        logAt(LOG_LEVELS.TRACE, "HitSignal", string.format(
            "PRIME_STRUCTURE_SIGNAL side=%s zombie=%s condition=%.4f reason=target_change subject=[%s]",
            getSideLabel(), tostring(zombieId), condition, tostring(subjectLabel)))
        return false, "prime"
    end

    subjectEntry.lastSeen = now
    if not entry then
        zombieHitSignals[key] = { condition = condition, lastSeen = now }
        logAt(LOG_LEVELS.TRACE, "HitSignal", string.format(
            "PRIME_STRUCTURE_SIGNAL side=%s zombie=%s condition=%.4f subject=[%s]",
            getSideLabel(), tostring(zombieId), condition, tostring(subjectLabel)))
        return false, "prime"
    end

    entry.lastSeen = now
    if condition < (entry.condition - HIT_SIGNAL_EPSILON) then
        entry.condition = condition
        return true, "ZombieThumpCondition"
    end

    if condition > (entry.condition + HIT_SIGNAL_EPSILON) then
        logAt(LOG_LEVELS.TRACE, "HitSignal", string.format(
            "RESET_STRUCTURE_SIGNAL side=%s zombie=%s old=%.4f new=%.4f subject=[%s]",
            getSideLabel(), tostring(zombieId), entry.condition, condition, tostring(subjectLabel)))
        entry.condition = condition
    else
        logAt(LOG_LEVELS.TRACE, "HitSignal", string.format(
            "SKIP_NO_STRUCTURE_HIT side=%s zombie=%s condition=%.4f subject=[%s]",
            getSideLabel(), tostring(zombieId), condition, tostring(subjectLabel)))
    end

    return false, "waiting"
end

local function readVehicleWindowHealth(window)
    if not window then return nil, "missing_window" end
    local okHealth, health = pcall(window.getHealth, window)
    if not okHealth then
        return nil, "getWindowHealth_error:" .. tostring(health)
    end
    health = tonumber(health)
    if health == nil then return nil, "missing_windowHealth" end
    return health, "ok"
end

local function readVehiclePartCondition(part)
    if not part then return nil, "missing_part" end
    local okCondition, condition = pcall(part.getCondition, part)
    if not okCondition then
        return nil, "getPartCondition_error:" .. tostring(condition)
    end
    condition = tonumber(condition)
    if condition == nil then return nil, "missing_partCondition" end
    return condition, "ok"
end

local function getVehicleHitMetric(vehicleLabel, part, window)
    local partLabel = getPartLabel(part)

    if window then
        local health, status = readVehicleWindowHealth(window)
        if health == nil then
            return nil, status, partLabel
        end
        return {
            key = "vehicle:" .. tostring(vehicleLabel) .. ":window:" .. tostring(partLabel),
            value = health,
            partLabel = partLabel,
            event = "VehicleWindowDamage",
        }, "ok", partLabel
    end

    if part then
        local condition, status = readVehiclePartCondition(part)
        if condition == nil then
            return nil, status, partLabel
        end
        return {
            key = "vehicle:" .. tostring(vehicleLabel) .. ":part:" .. tostring(partLabel),
            value = condition,
            partLabel = partLabel,
            event = "VehiclePartDamage",
        }, "ok", partLabel
    end

    return nil, "missing_vehicle_damage_target", partLabel
end

-- Vehicle damage is observed from the actual window/part health that vanilla
-- reduced. The signal is shared per vehicle part to avoid giving the same
-- single vehicle hit to every zombie currently in AttackVehicleState.
local function shouldProcessVehicleHit(zombieId, vehicleLabel, metric)
    if not metric then return false, "missing_metric" end

    local now = getTimestampMs()
    local entry = vehicleHitSignals[metric.key]
    if not entry then
        vehicleHitSignals[metric.key] = { value = metric.value, lastSeen = now }
        logAt(LOG_LEVELS.TRACE, "HitSignal", string.format(
            "PRIME_VEHICLE_SIGNAL side=%s zombie=%s value=%.4f vehicle=[%s] part=%s event=%s",
            getSideLabel(), tostring(zombieId), metric.value, tostring(vehicleLabel),
            tostring(metric.partLabel), tostring(metric.event)))
        return false, "prime"
    end

    entry.lastSeen = now
    if metric.value < (entry.value - HIT_SIGNAL_EPSILON) then
        entry.value = metric.value
        return true, metric.event
    end

    if metric.value > (entry.value + HIT_SIGNAL_EPSILON) then
        logAt(LOG_LEVELS.TRACE, "HitSignal", string.format(
            "RESET_VEHICLE_SIGNAL side=%s zombie=%s old=%.4f new=%.4f vehicle=[%s] part=%s event=%s",
            getSideLabel(), tostring(zombieId), entry.value, metric.value,
            tostring(vehicleLabel), tostring(metric.partLabel), tostring(metric.event)))
        entry.value = metric.value
    else
        logAt(LOG_LEVELS.TRACE, "HitSignal", string.format(
            "SKIP_NO_VEHICLE_HIT side=%s zombie=%s value=%.4f vehicle=[%s] part=%s event=%s",
            getSideLabel(), tostring(zombieId), metric.value, tostring(vehicleLabel),
            tostring(metric.partLabel), tostring(metric.event)))
    end

    return false, "waiting"
end

-- ########################################################################
-- ##  DAMAGE HANDLERS - OnZombieUpdate (Thump + Vehicle)
-- ########################################################################

-- Both handlers use OnZombieUpdate which fires per-zombie per-tick on the side
-- that owns the zombie's simulation (server for server-owned, client for
-- client-delegated). Vehicle detection uses zombie:getTarget():getVehicle()
-- (AttackVehicleState targets a player inside a vehicle, not the vehicle).

local function handleThumpDamage(zombie)
    local thump_target = zombie:getThumpTarget()
    if not thump_target then return end
    -- Skip vehicles - handled by handleVehicleDamage via AttackVehicleState
    if instanceof(thump_target, "BaseVehicle") then return end

    -- Gate on a Lua-visible vanilla hit result. No state-plus-timer gameplay fallback.
    local zombieId = zombie:getOnlineID()
    if not zombieId or zombieId <= 0 then zombieId = tostring(zombie) end
    local targetLabel = getTargetLabel(thump_target)
    if DAMAGE_MODE == 3 then
        logAt(LOG_LEVELS.TRACE, "Thump", string.format(
            "SKIP_DISABLED side=%s zombie=%s hp=%.3f target=[%s]",
            getSideLabel(), tostring(zombieId), zombie:getHealth(), targetLabel))
        return
    end
    local shouldProcessHit, eventLabel = shouldProcessStructureHit(zombie, zombieId, targetLabel)
    if not shouldProcessHit then return end

    local effectiveCooldown, timeScale = 0, getGameTimeScale()

    -- Filter check (runs BEFORE material detection to avoid wasted work and
    -- debug spam for targets that won't receive damage). ModData override
    -- bypasses the filter.
    local damage_multiplier = thump_target:getModData().BarricadeDamageMultiplier
    if not damage_multiplier then
        if BHZ.THUMP_FUNC and not BHZ.THUMP_FUNC(thump_target) then
            logAt(LOG_LEVELS.TRACE, "Thump", string.format(
                "SKIP_FILTER side=%s zombie=%s hp=%.3f target=[%s]",
                getSideLabel(), tostring(zombieId), zombie:getHealth(), getTargetLabel(thump_target)))
            return
        end
    end

    -- Calculate damage (material detection only runs for targets that passed the filter)
    local materialType = getMaterialType(thump_target)
    local materialMultiplier = MaterialDamageMultiplier[materialType] or 1.0
    local thump_dmg = BHZ.THUMP_DMG * materialMultiplier
    local blood_intensity = 1 * materialMultiplier

    if damage_multiplier then
        thump_dmg = thump_dmg * damage_multiplier
        blood_intensity = blood_intensity * damage_multiplier
    end

    if thump_dmg <= 0 then
        logAt(LOG_LEVELS.TRACE, "Thump", string.format(
            "SKIP_ZERO_DAMAGE side=%s zombie=%s hp=%.3f target=[%s] base=%.4f material=%s materialMult=%.3f objectMult=%s",
            getSideLabel(), tostring(zombieId), zombie:getHealth(), targetLabel,
            BHZ.THUMP_DMG, tostring(materialType), materialMultiplier, tostring(damage_multiplier or "none")))
        return
    end

    local objectMultiplier = damage_multiplier or 1.0
    local objectMultiplierLabel = tostring(damage_multiplier or "none")
    local cooldownLabel = "none"
    local detail = {
        formula = damage_multiplier and "base*materialMult*objectMult" or "base*materialMult",
        base = BHZ.THUMP_DMG,
        material = materialType,
        materialMult = materialMultiplier,
        objectMult = objectMultiplier,
        objectMultRaw = tostring(damage_multiplier),
        cooldown = cooldownLabel,
        effectiveCooldown = string.format("%.1f", effectiveCooldown),
        timeScale = string.format("%.2f", timeScale),
        target = targetLabel,
        vehicle = "nil",
        part = "nil",
        event = eventLabel,
    }

    local currentHealth = zombie:getHealth()
    local expectedHpAfter = getExpectedHpAfter(currentHealth, thump_dmg)
    local readableFormula = formatFormula("base", BHZ.THUMP_DMG, materialType, materialMultiplier, damage_multiplier)
    logAt(LOG_LEVELS.DEBUG, "Thump", string.format(
        "CALC thump side=%s zombie=%s event=%s target=[%s] hp=%.3f hpAfter=%.3f ticksToKill=%s damage=%.4f perHit formula=(%s) base=%.4f material=%s materialMult=%.3f objectMult=%s cooldown=%s effectiveCooldown=%.1fms timeScale=%.2f %s",
        getSideLabel(), tostring(zombieId), tostring(eventLabel), targetLabel, currentHealth, expectedHpAfter,
        getTicksToKill(currentHealth, thump_dmg), thump_dmg, readableFormula,
        BHZ.THUMP_DMG, tostring(materialType), materialMultiplier, objectMultiplierLabel,
        cooldownLabel, effectiveCooldown, timeScale, getZombieOwnerLabel(zombie)))

    dispatchZombieDamage(zombie, zombieId, thump_dmg, blood_intensity, materialType, "thump", detail)

    if currentLogLevel >= LOG_LEVELS.DEBUG then
        stats.thumpDamageCount = stats.thumpDamageCount + 1
    end
end

local function handleVehicleDamage(zombie)
    -- Get the vehicle from zombie's target (AttackVehicleState targets a player inside a vehicle)
    local target = zombie:getTarget()
    if not target then return end
    if not instanceof(target, "IsoGameCharacter") then return end
    local vehicle = target:getVehicle()
    if not vehicle then return end

    -- Gate on a Lua-visible vanilla hit result. No state-plus-timer gameplay fallback.
    local zombieId = zombie:getOnlineID()
    if not zombieId or zombieId <= 0 then zombieId = tostring(zombie) end
    local vehicleLabel = getVehicleLabel(vehicle)
    if DAMAGE_MODE == 3 then
        logAt(LOG_LEVELS.TRACE, "Vehicle", string.format(
            "SKIP_DISABLED side=%s zombie=%s hp=%.3f vehicle=[%s]",
            getSideLabel(), tostring(zombieId), zombie:getHealth(), vehicleLabel))
        return
    end

    local effectiveCooldown, timeScale = 0, getGameTimeScale()

    -- Calculate damage using vehicle material type
    local baseDmg = BHZ.VEHICLE_DMG
    local attackPart, attackWindow = getVehicleAttackTarget(vehicle, zombie, target)
    local metric, metricStatus, metricPartLabel = getVehicleHitMetric(vehicleLabel, attackPart, attackWindow)
    if not metric then
        logAt(LOG_LEVELS.TRACE, "Vehicle", string.format(
            "SKIP_NO_VEHICLE_HIT_SIGNAL side=%s zombie=%s hp=%.3f vehicle=[%s] part=%s status=%s",
            getSideLabel(), tostring(zombieId), zombie:getHealth(), vehicleLabel,
            tostring(metricPartLabel), tostring(metricStatus)))
        return
    end
    local shouldProcessHit, eventLabel = shouldProcessVehicleHit(zombieId, vehicleLabel, metric)
    if not shouldProcessHit then return end

    local materialPart = attackWindow and nil or attackPart
    local matType = getVehicleMaterialType(vehicle, materialPart)
    local matMult = MaterialDamageMultiplier[matType] or 1.0
    local finalDmg = baseDmg * matMult
    local partLabel = metric.partLabel or getPartLabel(attackPart)
    if finalDmg <= 0 then
        logAt(LOG_LEVELS.TRACE, "Vehicle", string.format(
            "SKIP_ZERO_DAMAGE side=%s zombie=%s hp=%.3f vehicle=[%s] part=%s base=%.4f material=%s materialMult=%.3f",
            getSideLabel(), tostring(zombieId), zombie:getHealth(), vehicleLabel,
            partLabel, baseDmg, tostring(matType), matMult))
        return
    end
    local cooldownLabel = "none"
    local detail = {
        formula = "vehicleBase*materialMult",
        base = baseDmg,
        material = matType,
        materialMult = matMult,
        objectMult = 1.0,
        objectMultRaw = "nil",
        cooldown = cooldownLabel,
        effectiveCooldown = string.format("%.1f", effectiveCooldown),
        timeScale = string.format("%.2f", timeScale),
        target = "nil",
        vehicle = vehicleLabel,
        part = partLabel,
        event = eventLabel,
    }

    local currentHealth = zombie:getHealth()
    local expectedHpAfter = getExpectedHpAfter(currentHealth, finalDmg)
    local readableFormula = formatFormula("vehicleBase", baseDmg, matType, matMult, nil)
    logAt(LOG_LEVELS.DEBUG, "Vehicle", string.format(
        "CALC vehicle side=%s zombie=%s event=%s vehicle=[%s] part=%s targetPlayer=%s hp=%.3f hpAfter=%.3f ticksToKill=%s damage=%.4f perHit formula=(%s) base=%.4f material=%s materialMult=%.3f cooldown=%s effectiveCooldown=%.1fms timeScale=%.2f %s",
        getSideLabel(), tostring(zombieId), tostring(eventLabel), vehicleLabel, partLabel, getPlayerLabel(target),
        currentHealth, expectedHpAfter, getTicksToKill(currentHealth, finalDmg),
        finalDmg, readableFormula, baseDmg, tostring(matType), matMult, cooldownLabel,
        effectiveCooldown, timeScale, getZombieOwnerLabel(zombie)))

    dispatchZombieDamage(zombie, zombieId, finalDmg, matMult, matType, "vehicle", detail)

    if currentLogLevel >= LOG_LEVELS.DEBUG then
        stats.vehicleDamageCount = stats.vehicleDamageCount + 1
    end
end

local function onZombieUpdate(zombie)
    if not zombie:isAlive() then return end
    if zombie:getHealth() <= 0 then return end
    if not shouldProcessZombie(zombie) then return end

    local stateName = zombie:getCurrentStateName()
    if not stateName then return end

    -- Periodic cooldown cleanup (~every 5000 zombie updates)
    cleanupCounter = cleanupCounter + 1
    if cleanupCounter >= 5000 then
        cleanupCounter = 0
        local now = getTimestampMs()
        for id, ts in pairs(zombieDamageCooldowns) do
            if (now - ts) > 10000 then
                zombieDamageCooldowns[id] = nil
            end
        end
        for id, entry in pairs(zombieHitSignals) do
            if (now - (entry.lastSeen or 0)) > 10000 then
                zombieHitSignals[id] = nil
            end
        end
        for id, entry in pairs(zombieHitSubjects) do
            if (now - (entry.lastSeen or 0)) > 10000 then
                zombieHitSubjects[id] = nil
            end
        end
        for id, entry in pairs(vehicleHitSignals) do
            if (now - (entry.lastSeen or 0)) > 10000 then
                vehicleHitSignals[id] = nil
            end
        end
        if currentLogLevel >= LOG_LEVELS.TRACE then
            local cooldownCount, thumpSignalCount, thumpSubjectCount, vehicleSignalCount = 0, 0, 0, 0
            for _ in pairs(zombieDamageCooldowns) do cooldownCount = cooldownCount + 1 end
            for _ in pairs(zombieHitSignals) do thumpSignalCount = thumpSignalCount + 1 end
            for _ in pairs(zombieHitSubjects) do thumpSubjectCount = thumpSubjectCount + 1 end
            for _ in pairs(vehicleHitSignals) do vehicleSignalCount = vehicleSignalCount + 1 end
            BHZ.log(string.format(
                "State table sizes: cooldown=%d thumpSignals=%d thumpSubjects=%d vehicleSignals=%d",
                cooldownCount, thumpSignalCount, thumpSubjectCount, vehicleSignalCount), "Perf")
        end
    end

    -- Dispatch to appropriate handler
    if stateName == "ThumpState" then
        handleThumpDamage(zombie)
    elseif stateName == "AttackVehicleState" then
        handleVehicleDamage(zombie)
    end
end

-- ########################################################################
-- ##  SERVER-SIDE RPC HANDLER
-- ########################################################################

-- Maximum damage per RPC (safety clamp against abuse: max 50% health per call)
local MAX_RPC_DAMAGE = 0.5
-- Minimum server-side cooldown (stricter than client's default 750ms would
-- be redundant; use 250ms to accept bursts within the client's throttle)
local SERVER_MIN_COOLDOWN = 250

-- Look up a zombie by online ID on the server. No direct getter exists in
-- Lua so we scan the current cell's zombie list. O(n) per RPC, but n is
-- bounded by rendered zombies and RPCs are gated by the 750ms client cooldown.
local function findServerZombieById(zombieId)
    local cell = getCell()
    if not cell then return nil end
    local list = cell:getZombieList()
    if not list then return nil end
    for i = 0, list:size() - 1 do
        local z = list:get(i)
        if z and z:getOnlineID() == zombieId then
            return z
        end
    end
    return nil
end

local function onServerApplyDamage(player, args)
    if type(args) ~= "table" then
        logAt(LOG_LEVELS.DEBUG, "MP", "RPC_REJECT reason=args_not_table player=" .. getPlayerLabel(player))
        return
    end
    local zombieId = args.id
    local damage = args.dmg
    local targetHealth = tonumber(args.hp)
    local bloodIntensity = args.blood or 1
    local source = args.src or "rpc"
    local materialType = args.mat or "unknown"
    local detail = {
        formula = args.formula,
        base = tonumber(args.base),
        material = materialType,
        materialMult = tonumber(args.materialMult),
        objectMult = tonumber(args.objectMult),
        objectMultRaw = args.objectMultRaw,
        cooldown = args.cooldown,
        effectiveCooldown = args.effectiveCooldown,
        timeScale = args.timeScale,
        target = args.target,
        vehicle = args.vehicle,
        part = args.part,
        event = args.event,
    }

    if type(zombieId) ~= "number" or zombieId <= 0 then
        logAt(LOG_LEVELS.DEBUG, "MP", "RPC_REJECT reason=bad_zombie_id player=" .. getPlayerLabel(player))
        return
    end
    if type(damage) ~= "number" or damage <= 0 then
        logAt(LOG_LEVELS.DEBUG, "MP", "RPC_REJECT reason=bad_damage player=" .. getPlayerLabel(player) .. " zombie=" .. tostring(zombieId))
        return
    end

    -- Clamp damage to prevent abuse
    if damage > MAX_RPC_DAMAGE then
        logAt(LOG_LEVELS.DEBUG, "MP", string.format(
            "RPC_CLAMP_DAMAGE player=%s zombie=%s requested=%.4f max=%.4f",
            getPlayerLabel(player), tostring(zombieId), damage, MAX_RPC_DAMAGE))
        damage = MAX_RPC_DAMAGE
    end

    -- Server-side cooldown safety net
    local currentTime = getTimestampMs()
    local lastTime = zombieDamageCooldowns[zombieId]
    local effectiveServerCooldown, serverTimeScale = getEffectiveCooldown(SERVER_MIN_COOLDOWN)
    if lastTime and (currentTime - lastTime) < effectiveServerCooldown then
        logAt(LOG_LEVELS.TRACE, "MP", string.format(
            "RPC_REJECT reason=server_cooldown player=%s zombie=%s delta=%s cooldown=%s effectiveCooldown=%.1f timeScale=%.2f",
            getPlayerLabel(player), tostring(zombieId), tostring(currentTime - lastTime),
            tostring(SERVER_MIN_COOLDOWN), effectiveServerCooldown, serverTimeScale))
        return
    end

    local zombie = findServerZombieById(zombieId)
    if not zombie then
        logAt(LOG_LEVELS.DEBUG, "MP", "RPC_REJECT reason=zombie_not_found player=" .. getPlayerLabel(player) .. " zombie=" .. tostring(zombieId))
        return
    end
    if not zombie:isAlive() then
        logAt(LOG_LEVELS.DEBUG, "MP", "RPC_REJECT reason=zombie_not_alive player=" .. getPlayerLabel(player) .. " zombie=" .. tostring(zombieId))
        return
    end
    if zombie:getHealth() <= 0 then
        logAt(LOG_LEVELS.DEBUG, "MP", string.format(
            "RPC_REJECT reason=zombie_zero_hp player=%s zombie=%s hp=%.3f",
            getPlayerLabel(player), tostring(zombieId), zombie:getHealth()))
        return
    end

    -- Client RPCs are only valid for zombies delegated to that same player.
    -- Server-owned zombies are damaged directly by the server OnZombieUpdate
    -- path and should not accept client-forged damage commands.
    local okOwner, ownerPlayer = false, nil
    if zombie.getOwnerPlayer then
        okOwner, ownerPlayer = pcall(zombie.getOwnerPlayer, zombie)
    end
    if okOwner then
        if not ownerPlayer then
            logAt(LOG_LEVELS.DEBUG, "MP", string.format(
                "RPC_REJECT reason=no_owner_player player=%s zombie=%s %s",
                getPlayerLabel(player), tostring(zombieId), getZombieOwnerLabel(zombie)))
            return
        end
        if player and ownerPlayer ~= player then
            logAt(LOG_LEVELS.DEBUG, "MP", string.format(
                "RPC_REJECT reason=owner_mismatch player=%s expected=%s zombie=%s %s",
                getPlayerLabel(player), getPlayerLabel(ownerPlayer), tostring(zombieId),
                getZombieOwnerLabel(zombie)))
            return
        end
    end

    local requestedTargetHealth = targetHealth
    if type(targetHealth) ~= "number" then
        targetHealth = zombie:getHealth() - damage
    end
    if targetHealth < 0 then targetHealth = 0 end

    -- Do not let a client request more than the clamped damage for this RPC.
    -- If the regular zombie sync already delivered this same health first,
    -- targetHealth will equal current health and this will not double-apply.
    local minimumAllowedHealth = zombie:getHealth() - damage
    if targetHealth < minimumAllowedHealth then
        logAt(LOG_LEVELS.DEBUG, "MP", string.format(
            "RPC_CLAMP_TARGET player=%s zombie=%s requestedTarget=%s minAllowed=%.3f hpNow=%.3f dmg=%.4f",
            getPlayerLabel(player), tostring(zombieId), tostring(requestedTargetHealth),
            minimumAllowedHealth, zombie:getHealth(), damage))
        targetHealth = minimumAllowedHealth
    end

    logAt(LOG_LEVELS.DEBUG, "MP", string.format(
        "RPC_APPLY player=%s zombie=%s hpNow=%.3f targetHp=%.3f dmg=%.4f src=%s blood=%s %s",
        getPlayerLabel(player), tostring(zombieId), zombie:getHealth(), targetHealth,
        damage, source, tostring(bloodIntensity), getZombieOwnerLabel(zombie)))

    zombieDamageCooldowns[zombieId] = currentTime
    applyTargetHealthLocally(zombie, zombieId, targetHealth, damage, bloodIntensity, materialType, source, detail)
end

local function onClientCommand(module, command, player, args)
    if module ~= "BHZ" then return end
    if not isServer() then return end
    if command == "applyDamage" then
        onServerApplyDamage(player, args)
    end
end

-- ########################################################################
-- ##  EVENT REGISTRATIONS
-- ########################################################################

if Events.OnLoad then
    eventRegistration.onLoad = true
    Events.OnLoad.Add(onLoad)
else
    print("[BHZ] WARNING: Events.OnLoad not available - mod may not initialize")
end

-- Both thump and vehicle damage: OnZombieUpdate fires per-zombie on the side
-- that owns the zombie's state machine (server for server-owned, client for
-- client-delegated via IsoZombie.authOwner).
if Events.OnZombieUpdate then
    eventRegistration.onZombieUpdate = true
    Events.OnZombieUpdate.Add(onZombieUpdate)
else
    print("[BHZ] WARNING: Events.OnZombieUpdate not available - mod will not function")
end

-- Server receives damage RPCs from clients that own delegated zombies
if Events.OnClientCommand then
    eventRegistration.onClientCommand = true
    Events.OnClientCommand.Add(onClientCommand)
else
    print("[BHZ] WARNING: Events.OnClientCommand not available - MP damage disabled")
end
