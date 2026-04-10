--[[
    Barricades Hurt Zombies [Build 42]
    Original mod by Brightex
    Build 42 update and continued development by ZeroTheAbsolute

    A comprehensive zombie damage system that processes attacks on barricades,
    doors, windows, and vehicles. The mod implements sophisticated detection
    and damage calculation systems with high performance and configurability.

    Core Features:
    - Intelligent vehicle part detection using angle-based targeting
    - Material-based damage multipliers
    - Optimized processing with minimal performance impact
    - Comprehensive error handling and safety checks
    - Extensive debug capabilities (disabled by default)

    Damage Multiplier System:
    - Wood (baseline):    1.0x  - Standard damage
    - Metal:             1.25x - 25% increased damage
    - Heavy Metal:       1.4x  - 40% increased damage
    - Light Spikes*:     1.5x  - 50% increased damage
    - Heavy Spikes*:     1.75x - 75% increased damage
    - Reinforced*:       2.0x  - Double damage
    * Coming with full SVU3 integration

    Vehicle System Design:
    - Periodic damage processing instead of per-tick
    - Customizable detection ranges per part type
    - Zombie cooldown system to prevent damage spam
    - Comprehensive nil checks and error handling
    - Blood effects tied to damage multipliers

    Current SVU3 Status:
    Vehicle damage is fully functional but currently uses base metal
    multiplier (1.25x) for all modded vehicles. Full SVU3 armor type
    detection is under development.

    Performance Considerations:
    - Cached function calls for reduced overhead
    - Optimized loop structures
    - Minimal logging in production
    - Efficient damage cooldown system
    - Smart part detection to minimize calculations
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

local BHZ = {
    VERSION         = "2.2.1",
    THUMP_DMG       = 0.05,   -- Base % damage from thumping
    VEHICLE_DMG     = 0.05,   -- Base % damage from vehicle attacks
    THUMP_FUNC      = nil,    -- Decides which objects can hurt zombies
    BLOOD_ENABLED   = true,
    LOG_ENABLED     = LOG_ENABLED,
}

-- [Fix #13] Debug-only statistics tracking
local stats = { thumpDamageCount = 0, vehicleDamageCount = 0, zombieKills = 0, cycleCount = 0 }

-- ########################################################################
-- ##  COMPATIBILITY HELPERS (42.0 -> 42.16+ safe)
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
    -- Dedicated client: owns the zombie iff the server delegated it to us
    return owner ~= nil
end

----------------------------------------------------------------------
-- Simple Logging Utilities
----------------------------------------------------------------------

-- We'll cache standard print for minor speed benefit:
local print = print

local function logToConsole(msg)
    if BHZ.LOG_ENABLED then
        print(msg)
    end
end

function BHZ.logToFile(msg)
    -- Example (commented out to avoid overhead by default):
    -- local f = getFileWriter("BHZCore.log", true, false)
    -- f:write(msg .. "\n")
    -- f:close()
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
    -- BHZ.logToFile(output)
end

-- [Fix #11] debugPrint now accepts an optional log level parameter
local function debugPrint(msg, category, level)
    if not DEBUG_MODE then return end
    level = level or LOG_LEVELS.DEBUG
    if currentLogLevel < level then return end
    BHZ.log(msg, category or "Debug")
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

local SVU3_WORKSHOP_ID       = "\\StandardizedVehicleUpgrades3V"
local KITSUNELIB_WORKSHOP_ID = "\\kitsunelib"
local hasSVU = isModActive(SVU3_WORKSHOP_ID) and isModActive(KITSUNELIB_WORKSHOP_ID)
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

-- ########################################################################
-- ##  ZOMBIE DAMAGE SYSTEM
-- ########################################################################

-- Cooldown defaults (overridden by sandbox settings in onLoad)
local DAMAGE_COOLDOWN  = 500
local THUMP_COOLDOWN   = 500

local cleanupCounter = 0
local zombieDamageCooldowns = {}

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

local function isPlayerBuiltOrMoved(thump_target)
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

-- ########################################################################
-- ##  SANDBOX SETTINGS
-- ########################################################################

local function onLoad()
    debugPrint("Loading BHZ sandbox settings...")

    -- Reset cooldowns and stats on load
    zombieDamageCooldowns = {}
    cleanupCounter = 0
    stats.thumpDamageCount = 0
    stats.vehicleDamageCount = 0
    stats.zombieKills = 0
    stats.cycleCount = 0

    local SandboxVars = SandboxVars
    if SandboxVars and SandboxVars.BarricadesHurtZombies then
        -- Process core damage settings
        local baseDamage = tonumber(SandboxVars.BarricadesHurtZombies.BaseDamage) or 5
        if baseDamage < 0   then baseDamage = 0   end
        if baseDamage > 100 then baseDamage = 100 end
        BHZ.THUMP_DMG = baseDamage / 100
        debugPrint("BaseDamage=" .. baseDamage .. "% => THUMP_DMG=" .. BHZ.THUMP_DMG)

        -- Process vehicle base damage (separate from barricade damage)
        local vehicleBaseDamage = tonumber(SandboxVars.BarricadesHurtZombies.VehicleBaseDamage) or 5
        if vehicleBaseDamage < 0   then vehicleBaseDamage = 0   end
        if vehicleBaseDamage > 100 then vehicleBaseDamage = 100 end
        BHZ.VEHICLE_DMG = vehicleBaseDamage / 100
        debugPrint("VehicleBaseDamage=" .. vehicleBaseDamage .. "% => VEHICLE_DMG=" .. BHZ.VEHICLE_DMG)

        -- Set up damage mode (what objects can hurt zombies)
        local mode = SandboxVars.BarricadesHurtZombies.DamageMode
        if mode == 1 then
            BHZ.THUMP_FUNC = isPlayerBuiltOrMoved
        elseif mode == 2 then
            BHZ.THUMP_FUNC = checkAll
        else
            BHZ.THUMP_FUNC = checkNothing
        end

        -- Load material multipliers with fallbacks to defaults
        MaterialDamageMultiplier.METAL = SandboxVars.BarricadesHurtZombies.MetalMultiplier
            or DEFAULT_MULTIPLIERS.METAL
        MaterialDamageMultiplier.METAL_HEAVY = SandboxVars.BarricadesHurtZombies.MetalHeavyMultiplier
            or DEFAULT_MULTIPLIERS.METAL_HEAVY
        MaterialDamageMultiplier.LIGHT_SPIKE = SandboxVars.BarricadesHurtZombies.LightSpikeMultiplier
            or DEFAULT_MULTIPLIERS.LIGHT_SPIKE
        MaterialDamageMultiplier.HEAVY_SPIKE = SandboxVars.BarricadesHurtZombies.HeavySpikeMultiplier
            or DEFAULT_MULTIPLIERS.HEAVY_SPIKE
        MaterialDamageMultiplier.REINFORCED = SandboxVars.BarricadesHurtZombies.ReinforcedMultiplier
            or DEFAULT_MULTIPLIERS.REINFORCED

        -- Configure visual effects
        BHZ.BLOOD_ENABLED = SandboxVars.BarricadesHurtZombies.BloodEffects ~= false

        -- Set up cooldown configuration
        THUMP_COOLDOWN = SandboxVars.BarricadesHurtZombies.ThumpDamageCooldown or 500
        DAMAGE_COOLDOWN = SandboxVars.BarricadesHurtZombies.VehicleDamageCooldown or 500

        -- Configure debug settings
        DEBUG_MODE = SandboxVars.BarricadesHurtZombies.DebugMode or false
        DEBUG_VEHICLES = SandboxVars.BarricadesHurtZombies.VehicleDebugMode or false

        -- LogLevel enum: 1=None, 2=Error, 3=Warn, 4=Info, 5=Debug, 6=Trace
        local logLevelEnum = SandboxVars.BarricadesHurtZombies.LogLevel or 1
        currentLogLevel = math.max(0, logLevelEnum - 1) -- enum is 1-indexed, LOG_LEVELS is 0-indexed

        -- Legacy debug toggles override LogLevel if they set a higher level
        if DEBUG_VEHICLES and currentLogLevel < LOG_LEVELS.TRACE then
            currentLogLevel = LOG_LEVELS.TRACE
        elseif DEBUG_MODE and currentLogLevel < LOG_LEVELS.DEBUG then
            currentLogLevel = LOG_LEVELS.DEBUG
        end

        BHZ.LOG_ENABLED = currentLogLevel > LOG_LEVELS.NONE

        -- Log the configuration if debugging is enabled
        if DEBUG_MODE then
            debugPrint("BHZ Configuration loaded:")
            debugPrint(string.format("  Base Damage: %.1f%%", baseDamage))
            debugPrint(string.format("  Damage Mode: %d", mode))
            debugPrint(string.format("  Metal Multiplier: %.2fx", MaterialDamageMultiplier.METAL))
            debugPrint(string.format("  Vehicle Cooldown: %dms", DAMAGE_COOLDOWN))
            debugPrint(string.format("  Thump Cooldown: %dms", THUMP_COOLDOWN))
            debugPrint(string.format("  Log Level: %d", currentLogLevel))
        end
    else
        -- If no sandbox settings found, use safe defaults
        debugPrint("No sandbox config => using defaults")
        BHZ.THUMP_DMG = 0.05      -- 5% base damage
        BHZ.VEHICLE_DMG = 0.05    -- 5% vehicle base damage
        BHZ.THUMP_FUNC = isPlayerBuiltOrMoved
        BHZ.BLOOD_ENABLED = true
        DEBUG_MODE = false
        DEBUG_VEHICLES = false
        BHZ.LOG_ENABLED = false
        currentLogLevel = LOG_LEVELS.NONE
        THUMP_COOLDOWN = 500
        DAMAGE_COOLDOWN = 500

        -- Reset all multipliers to defaults
        for mat, mult in pairs(DEFAULT_MULTIPLIERS) do
            MaterialDamageMultiplier[mat] = mult
        end
    end

    debugPrint("BHZ mod settings loaded")

    -- Always print startup banner (dev build visibility)
    print("[BHZ] BarricadesHurtZombies v" .. BHZ.VERSION .. " | PZ=" .. getGameVersion()
        .. " | THUMP_DMG=" .. BHZ.THUMP_DMG
        .. " VEHICLE_DMG=" .. BHZ.VEHICLE_DMG
        .. " LogLevel=" .. currentLogLevel
        .. " Blood=" .. tostring(BHZ.BLOOD_ENABLED)
        .. " Side=" .. (isClient() and "client" or (isServer() and "server" or "sp")))
end

-- ########################################################################
-- ##  DAMAGE APPLICATION (authoritative side only)
-- ########################################################################

-- Apply damage directly to the zombie. Only runs on the side that owns the
-- zombie's simulation: SP (no MP), server for server-owned zombies, or the
-- server-side OnClientCommand handler for client-owned zombies after RPC.
-- Handles kill + blood splat. setHealth has no built-in sync so this MUST
-- run server-side in MP, never client-side.
local function applyDamageLocally(zombie, zombieId, damage, bloodIntensity, materialType, source)
    local oldHealth = zombie:getHealth()
    local newHealth = oldHealth - damage

    if currentLogLevel >= LOG_LEVELS.INFO then
        BHZ.log(string.format("DMG: zombie=%s hp=%.2f->%.2f dmg=%.4f mat=%s src=%s",
            tostring(zombieId), oldHealth, newHealth, damage, tostring(materialType or "unknown"), source), "Damage")
    end

    if newHealth <= 0 then
        zombieDamageCooldowns[zombieId] = nil
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
        if BHZ.BLOOD_ENABLED then
            local square = zombie:getSquare()
            if square then safeAddBloodSplat(square, bloodIntensity) end
        end
    end
end

-- Dispatch damage. On a pure client, forwards to server via sendClientCommand
-- because setHealth has no network sync. On SP, dedicated server, or listen
-- server, applies directly (the local process is authoritative).
local function dispatchZombieDamage(zombie, zombieId, damage, bloodIntensity, materialType, source)
    -- Server-side (dedicated or listen) and SP all apply locally
    if isServer() or not isClient() then
        applyDamageLocally(zombie, zombieId, damage, bloodIntensity, materialType, source)
        return
    end
    -- Pure client: forward to server via RPC
    if type(zombieId) ~= "number" or zombieId <= 0 then return end
    sendClientCommand("BHZ", "applyDamage", {
        id = zombieId,
        dmg = damage,
        blood = bloodIntensity,
        src = source,
    })
    if currentLogLevel >= LOG_LEVELS.DEBUG then
        BHZ.log(string.format("RPC: z=%s dmg=%.4f src=%s", tostring(zombieId), damage, source), "MP")
    end
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

    -- Cooldown check (cheap, do first)
    local zombieId = zombie:getOnlineID()
    if not zombieId or zombieId <= 0 then zombieId = tostring(zombie) end
    local currentTime = getTimestampMs()
    local lastTime = zombieDamageCooldowns[zombieId]
    if lastTime and (currentTime - lastTime) < THUMP_COOLDOWN then return end

    -- Filter check (runs BEFORE material detection to avoid wasted work and
    -- debug spam for targets that won't receive damage). ModData override
    -- bypasses the filter.
    local damage_multiplier = thump_target:getModData().BarricadeDamageMultiplier
    if not damage_multiplier then
        if BHZ.THUMP_FUNC and not BHZ.THUMP_FUNC(thump_target) then
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

    zombieDamageCooldowns[zombieId] = currentTime
    dispatchZombieDamage(zombie, zombieId, thump_dmg, blood_intensity, materialType, "thump")

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

    -- Cooldown check
    local zombieId = zombie:getOnlineID()
    if not zombieId or zombieId <= 0 then zombieId = tostring(zombie) end
    local currentTime = getTimestampMs()
    local lastTime = zombieDamageCooldowns[zombieId]
    if lastTime and (currentTime - lastTime) < DAMAGE_COOLDOWN then return end

    -- Calculate damage using vehicle material type
    local baseDmg = BHZ.VEHICLE_DMG
    local matType = getVehicleMaterialType(vehicle, nil)
    local matMult = MaterialDamageMultiplier[matType] or 1.0
    local finalDmg = baseDmg * matMult

    zombieDamageCooldowns[zombieId] = currentTime
    dispatchZombieDamage(zombie, zombieId, finalDmg, matMult, matType, "vehicle")

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
        if currentLogLevel >= LOG_LEVELS.DEBUG then
            local count = 0
            for _ in pairs(zombieDamageCooldowns) do count = count + 1 end
            BHZ.log("Cooldown table size: " .. count, "Perf")
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
-- Minimum server-side cooldown (stricter than client's default 500ms would
-- be redundant; use 250ms to accept bursts within the client's throttle)
local SERVER_MIN_COOLDOWN = 250

-- Look up a zombie by online ID on the server. No direct getter exists in
-- Lua so we scan the current cell's zombie list. O(n) per RPC, but n is
-- bounded by rendered zombies and RPCs are gated by the 500ms client cooldown.
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
    if type(args) ~= "table" then return end
    local zombieId = args.id
    local damage = args.dmg
    local bloodIntensity = args.blood or 1
    local source = args.src or "rpc"

    if type(zombieId) ~= "number" or zombieId <= 0 then return end
    if type(damage) ~= "number" or damage <= 0 then return end

    -- Clamp damage to prevent abuse
    if damage > MAX_RPC_DAMAGE then damage = MAX_RPC_DAMAGE end

    -- Server-side cooldown safety net
    local currentTime = getTimestampMs()
    local lastTime = zombieDamageCooldowns[zombieId]
    if lastTime and (currentTime - lastTime) < SERVER_MIN_COOLDOWN then
        return
    end

    local zombie = findServerZombieById(zombieId)
    if not zombie then return end
    if not zombie:isAlive() then return end
    if zombie:getHealth() <= 0 then return end

    zombieDamageCooldowns[zombieId] = currentTime
    applyDamageLocally(zombie, zombieId, damage, bloodIntensity, nil, source)
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
    Events.OnLoad.Add(onLoad)
else
    print("[BHZ] WARNING: Events.OnLoad not available - mod may not initialize")
end

-- Both thump and vehicle damage: OnZombieUpdate fires per-zombie on the side
-- that owns the zombie's state machine (server for server-owned, client for
-- client-delegated via IsoZombie.authOwner).
if Events.OnZombieUpdate then
    Events.OnZombieUpdate.Add(onZombieUpdate)
else
    print("[BHZ] WARNING: Events.OnZombieUpdate not available - mod will not function")
end

-- Server receives damage RPCs from clients that own delegated zombies
if Events.OnClientCommand then
    Events.OnClientCommand.Add(onClientCommand)
else
    print("[BHZ] WARNING: Events.OnClientCommand not available - MP damage disabled")
end
