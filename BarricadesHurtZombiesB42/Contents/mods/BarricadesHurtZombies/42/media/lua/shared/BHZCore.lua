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
    THUMP_DMG       = 0.05,   -- Base % damage from thumping
    VEHICLE_DMG     = 0.05,   -- Base % damage from vehicle attacks
    THUMP_FUNC      = nil,    -- Decides which objects can hurt zombies
    BLOOD_ENABLED   = true,
    LOG_ENABLED     = LOG_ENABLED,
}

-- [Fix #13] Debug-only statistics tracking
local stats = { thumpDamageCount = 0, vehicleDamageCount = 0, zombieKills = 0, cycleCount = 0 }

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

local function getMaterialType(target)
    if not target then
        debugPrint("getMaterialType: target=nil => WOOD")
        return "WOOD"
    end

    debugPrint("getMaterialType: Checking => "..tostring(target))

    if instanceof(target, "IsoThumpable") then
        local sprite = target:getSprite()
        if not sprite then return "WOOD" end
        local props = sprite:getProperties()
        if not props then return "WOOD" end
        local isMetal = props:Is("Material", "Metal")
        debugPrint("IsoThumpable => isMetal="..tostring(isMetal))
        return isMetal and "METAL" or "WOOD"
    elseif instanceof(target, "IsoBarricade") then
        local isMetal = target:isMetal()
        debugPrint("IsoBarricade => isMetal="..tostring(isMetal))
        return isMetal and "METAL" or "WOOD"
    elseif instanceof(target, "IsoDoor") or instanceof(target, "IsoWindow") then
        debugPrint("Door/Window => WOOD (base damage)")
        return "WOOD"
    end

    debugPrint("getMaterialType: default => WOOD")
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
    print("[BHZ] BarricadesHurtZombies loaded | THUMP_DMG=" .. BHZ.THUMP_DMG
        .. " VEHICLE_DMG=" .. BHZ.VEHICLE_DMG
        .. " LogLevel=" .. currentLogLevel
        .. " Blood=" .. tostring(BHZ.BLOOD_ENABLED))
end

-- ########################################################################
-- ##  DAMAGE HANDLERS — OnZombieUpdate (Thump + Vehicle)
-- ########################################################################

-- Both handlers use OnZombieUpdate which fires per-zombie per-tick on server+SP.
-- This eliminates grid scanning, search radius limits, and getOnlineID issues.
-- Vehicle detection uses zombie:getTarget():getVehicle() (confirmed via Java decompilation:
-- AttackVehicleState targets a player inside a vehicle, not the vehicle itself).

local function handleThumpDamage(zombie)
    local thump_target = zombie:getThumpTarget()
    if not thump_target then return end
    -- Skip vehicles — handled by handleVehicleDamage via AttackVehicleState
    if instanceof(thump_target, "BaseVehicle") then return end

    -- Cooldown check
    local zombieId = zombie:getOnlineID()
    if not zombieId or zombieId <= 0 then zombieId = tostring(zombie) end
    local currentTime = getTimestampMs()
    local lastTime = zombieDamageCooldowns[zombieId]
    if lastTime and (currentTime - lastTime) < THUMP_COOLDOWN then return end

    -- Calculate damage
    local thump_dmg = BHZ.THUMP_DMG
    local blood_intensity = 1
    local materialType = getMaterialType(thump_target)
    local materialMultiplier = MaterialDamageMultiplier[materialType] or 1.0
    thump_dmg = thump_dmg * materialMultiplier
    blood_intensity = blood_intensity * materialMultiplier

    -- Check mod data for custom multiplier (compatibility with other mods)
    local damage_multiplier = thump_target:getModData().BarricadeDamageMultiplier
    if damage_multiplier then
        thump_dmg = thump_dmg * damage_multiplier
        blood_intensity = blood_intensity * damage_multiplier
    else
        if BHZ.THUMP_FUNC and not BHZ.THUMP_FUNC(thump_target) then
            return
        end
    end

    -- Apply damage
    local oldHealth = zombie:getHealth()
    local newHealth = oldHealth - thump_dmg
    zombieDamageCooldowns[zombieId] = currentTime

    if currentLogLevel >= LOG_LEVELS.INFO then
        BHZ.log(string.format("DMG: zombie=%s hp=%.2f->%.2f dmg=%.4f mat=%s src=%s",
            tostring(zombieId), oldHealth, newHealth, thump_dmg, materialType, "thump"), "Damage")
    end
    if currentLogLevel >= LOG_LEVELS.DEBUG then
        BHZ.log(string.format("z=%s hp=%.2f->%.2f dmg=%.4f mat=%s",
            tostring(zombieId), oldHealth, newHealth, thump_dmg, materialType), "Thump")
    end

    if newHealth <= 0 then
        zombieDamageCooldowns[zombieId] = nil
        zombie:setHealth(0)
        local cell = zombie:getCell()
        if cell then
            zombie:Kill(zombie)
        end
        if currentLogLevel >= LOG_LEVELS.DEBUG then
            BHZ.log("Killed zombie " .. tostring(zombieId) .. " (hp=" .. oldHealth .. "->0)", "Kill")
            stats.zombieKills = stats.zombieKills + 1
        end
    else
        zombie:setHealth(newHealth)
        if BHZ.BLOOD_ENABLED then
            local square = zombie:getSquare()
            if square then addBloodSplat(square, blood_intensity) end
        end
    end

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

    local oldHealth = zombie:getHealth()
    local newHealth = oldHealth - finalDmg
    zombieDamageCooldowns[zombieId] = currentTime

    if currentLogLevel >= LOG_LEVELS.INFO then
        BHZ.log(string.format("DMG: zombie=%s hp=%.2f->%.2f dmg=%.4f mat=%s src=%s",
            tostring(zombieId), oldHealth, newHealth, finalDmg, matType, "vehicle"), "Damage")
    end
    if currentLogLevel >= LOG_LEVELS.DEBUG then
        BHZ.log(string.format("z=%s hp=%.2f->%.2f dmg=%.4f mat=%s",
            tostring(zombieId), oldHealth, newHealth, finalDmg, matType), "Vehicle")
    end

    if newHealth <= 0 then
        zombieDamageCooldowns[zombieId] = nil
        zombie:setHealth(0)
        local cell = zombie:getCell()
        if cell then
            zombie:Kill(zombie)
        end
        if currentLogLevel >= LOG_LEVELS.DEBUG then
            BHZ.log("Killed zombie " .. tostring(zombieId) .. " (hp=" .. oldHealth .. "->0)", "Kill")
            stats.zombieKills = stats.zombieKills + 1
        end
    else
        zombie:setHealth(newHealth)
        if BHZ.BLOOD_ENABLED then
            local square = zombie:getSquare()
            if square then addBloodSplat(square, matMult) end
        end
    end

    if currentLogLevel >= LOG_LEVELS.DEBUG then
        stats.vehicleDamageCount = stats.vehicleDamageCount + 1
    end
end

local function onZombieUpdate(zombie)
    -- MP: only process on server (isClient() returns false in SP, so this is safe)
    if isClient() then return end
    if not zombie:isAlive() then return end
    if zombie:getHealth() <= 0 then return end

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
-- ##  EVENT REGISTRATIONS
-- ########################################################################

Events.OnLoad.Add(onLoad)
-- Both thump and vehicle damage: OnZombieUpdate fires per-zombie on server+SP
Events.OnZombieUpdate.Add(onZombieUpdate)
