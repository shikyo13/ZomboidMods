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
    - Wood (baseline):    1.0×  - Standard damage
    - Metal:             1.25× - 25% increased damage
    - Heavy Metal:       1.4×  - 40% increased damage
    - Light Spikes*:     1.5×  - 50% increased damage
    - Heavy Spikes*:     1.75× - 75% increased damage
    - Reinforced*:       2.0×  - Double damage
    * Coming with full SVU3 integration

    Vehicle System Design:
    - Periodic damage processing instead of per-tick
    - Customizable detection ranges per part type
    - Zombie cooldown system to prevent damage spam
    - Comprehensive nil checks and error handling
    - Blood effects tied to damage multipliers

    Current SVU3 Status:
    Vehicle damage is fully functional but currently uses base metal
    multiplier (1.25×) for all modded vehicles. Full SVU3 armor type
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

local DEBUG_MODE       = true    -- Toggle detailed debug logs (set false for release)
local DEBUG_VEHICLES   = true    -- Extra logging for vehicles
local LOG_ENABLED      = false   -- Master switch for all logs

local BHZ = {
    THUMP_DMG       = 0.05,  -- Base % damage from thumping
    THUMP_FUNC      = nil,   -- Decides which objects can hurt zombies
    BLOOD_ENABLED   = true,
    LOG_ENABLED     = LOG_ENABLED,
}

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

-- Our debugPrint respects DEBUG_MODE:
local function debugPrint(msg, category)
    if not DEBUG_MODE then return end
    BHZ.log(msg, category or "Debug")
end

-- ########################################################################
-- ##  MULTIPLIERS & MATERIAL TABLES
-- ########################################################################

local GAME_SPEED_MULTIPLIERS = {1, 5, 20, 40}

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
            -- e.g. “SVU_Armor_LuxuryCar_Heavy”
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
-- ##  SAFE VEHICLE DATA
-- ########################################################################

local function getSafeVehicleData(vehicle)
    if not (vehicle and instanceof(vehicle, "BaseVehicle")) then
        return nil, "Not a BaseVehicle"
    end

    if not vehicle.getX or not vehicle.getY then
        return nil, "Vehicle missing getX/getY methods"
    end

    local angleMethod = vehicle.getAngleZ or vehicle.getAngle
    if not angleMethod then
        return nil, "No angle method (getAngleZ/getAngle)"
    end

    local x = vehicle:getX()
    local y = vehicle:getY()
    local angle = angleMethod(vehicle)
    if angle == nil then
        return nil, "angle is nil"
    end

    return { x = x, y = y, angle = angle }, nil
end

-- ########################################################################
-- ##  GET ATTACKED VEHICLE & PART (PER-PART DISTANCE)
-- ########################################################################

-- Per-part detection radii (adjust as needed):
local PART_DETECTION_RADIUS = {
    Engine          = 2.6,
    TrunkDoor       = 2.7,
    TrunkLid        = 2.7,
    DoorFrontLeft   = 2.4,
    DoorFrontRight  = 2.4,
    DoorRearLeft    = 2.5,
    DoorRearRight   = 2.5,
    SVU_Armor_Front = 2.6,
    SVU_Armor_Left  = 2.6,
    SVU_Armor_Right = 2.6,
    SVU_Armor_Rear  = 2.7,

    default         = 2.2
}

local function getRangeForPart(partId)
    if not partId then
        return PART_DETECTION_RADIUS.default
    end
    return PART_DETECTION_RADIUS[partId] or PART_DETECTION_RADIUS.default
end

local function getAttackedVehicleAndPart(zombie)
    if not zombie then 
        debugPrint("No zombie provided", "Vehicle")
        return nil, nil 
    end

    local function findBestPart(vehicleObj, zx, zy)
        if not (vehicleObj and instanceof(vehicleObj, "BaseVehicle")) then
            debugPrint("Vehicle missing or not BaseVehicle", "Vehicle")
            return nil
        end

        local vData, reason = getSafeVehicleData(vehicleObj)
        if not vData then
            debugPrint("Failed to get vehicle data: "..tostring(reason), "Vehicle")
            return nil
        end

        local relX = zx - vData.x
        local relY = zy - vData.y
        local angle = math.atan2(relY, relX) - vData.angle

        -- Normalize angle to -π..π
        while angle >  math.pi do angle = angle - (2*math.pi) end
        while angle < -math.pi do angle = angle + (2*math.pi) end

        debugPrint(string.format("Attack angle: %.2f", angle), "Vehicle")

        local script = vehicleObj:getScript()
        if not script then
            debugPrint("No vehicle script found", "Vehicle")
            return nil
        end
        local vehicleType = script:getName()
        debugPrint("Vehicle type: "..tostring(vehicleType), "Vehicle")

        local partLists = {
            [-0.785] = {
                primary  = {"SVU_Armor_Front"},
                fallback = {"Engine"},
            },
            [-2.356] = {
                primary  = {"SVU_Armor_Left"},
                fallback = {"DoorFrontLeft","DoorRearLeft"},
            },
            [0.785] = {
                primary  = {"SVU_Armor_Right"},
                fallback = {"DoorFrontRight","DoorRearRight"},
            },
            [2.356] = {
                primary  = {"SVU_Armor_Rear"},
                fallback = {"TrunkDoor","TrunkLid"},
            },
        }

        local angleKeys = {-0.785, -2.356, 0.785, 2.356}
        local closestKey, closestDist = nil, 999999.0
        for _, key in ipairs(angleKeys) do
            local dist = angle - key
            if dist < 0 then dist = -dist end -- abs
            if dist < closestDist then
                closestKey  = key
                closestDist = dist
            end
        end

        if not closestKey then
            debugPrint("No angle match found", "Vehicle")
            return nil
        end

        debugPrint("Using part list for angle "..tostring(closestKey), "Vehicle")
        local parts = partLists[closestKey]

        -- Try armor parts first
        for _, partId in ipairs(parts.primary) do
            local partObj = vehicleObj:getPartById(partId)
            if partObj then
                debugPrint("Found SVU armor part: "..partId, "Vehicle")
                return partObj
            end
        end

        -- Fallback standard parts
        for _, partId in ipairs(parts.fallback) do
            local partObj = vehicleObj:getPartById(partId)
            if partObj then
                debugPrint("Found fallback part: "..partId, "Vehicle")
                return partObj
            end
        end

        debugPrint("No suitable part found", "Vehicle")
        return nil
    end

    local square = zombie:getSquare()
    if not square then return nil, nil end
    local cell = square:getCell()
    if not cell then return nil, nil end

    local vehicles = cell:getVehicles()
    if not vehicles then return nil, nil end

    local zx, zy = zombie:getX(), zombie:getY()
    debugPrint(string.format("Checking for vehicles near zombie at %.2f,%.2f", zx, zy), "Vehicle")

    local closestDist = 999999.0
    local closestVehicle, closestPart = nil, nil

    local size = vehicles:size()
    for i=0, size-1 do
        local obj = vehicles:get(i)
        if obj and instanceof(obj, "BaseVehicle") then
            if obj.getX and obj.getY then
                local dx = zx - obj:getX()
                local dy = zy - obj:getY()
                local dist = (dx*dx + dy*dy)^0.5
                debugPrint(string.format("Vehicle %d - distance %.2f", i, dist), "Vehicle")
                if dist < closestDist then
                    closestDist    = dist
                    closestVehicle = obj
                    closestPart    = findBestPart(obj, zx, zy)
                end
            else
                debugPrint("Skipping vehicle with no getX/getY", "Vehicle")
            end
        else
            if obj then
                debugPrint("Skipping non-BaseVehicle entry: "..tostring(obj), "Vehicle")
            end
        end
    end

    if not closestVehicle then
        debugPrint("No vehicle found at all", "Vehicle")
        return nil, nil
    end

    if not closestPart then
        debugPrint("Returning vehicle without part", "Vehicle")
        return closestVehicle, nil
    end

    local partId = closestPart:getId()
    local detectionRange = getRangeForPart(partId)
    debugPrint("closestDist="..string.format("%.2f",closestDist)
               .." vs part "..tostring(partId)
               .." range="..tostring(detectionRange),
               "Vehicle")

    if closestDist > detectionRange then
        debugPrint(string.format("No vehicle in range (closest=%.2f) [needed <= %.2f]", 
                                 closestDist, detectionRange), "Vehicle")
        return nil, nil
    else
        debugPrint("Returning vehicle with part: "..partId, "Vehicle")
        return closestVehicle, closestPart
    end
end

-- ########################################################################
-- ##  ZOMBIE DAMAGE TICK SYSTEM
-- ########################################################################

local DAMAGE_COOLDOWN  = 0
local PROCESS_INTERVAL = 150

local tickCounter = 0
local zombieDamageCooldowns = {}

local function processVehicleDamage()
    if not DEBUG_VEHICLES then return end

    tickCounter = tickCounter + 1
    if tickCounter < PROCESS_INTERVAL then return end
    tickCounter = 0

    debugPrint("Starting vehicle damage check cycle", "VehicleDamage")

    local player = getPlayer()
    if not player then
        debugPrint("getPlayer() returned nil", "VehicleDamage")
        return
    end

    local sq = player:getSquare()
    if not sq then
        debugPrint("player:getSquare() returned nil", "VehicleDamage")
        return
    end

    local cell = sq:getCell()
    if not cell then
        debugPrint("playerSquare:getCell() returned nil", "VehicleDamage")
        return
    end

    -- We'll gather zombies in a ~5x5 block around the player
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    local zombies    = {}
    local index      = 1

    for ox = -2,2 do
        for oy = -2,2 do
            local gx = px + ox
            local gy = py + oy
            local sqr = cell:getGridSquare(gx, gy, pz)
            if sqr then
                local mo = sqr:getMovingObjects()
                if mo then
                    local moSize = mo:size()
                    for i=0, moSize-1 do
                        local obj = mo:get(i)
                        if obj and instanceof(obj, "IsoZombie") then
                            debugPrint("Found zombie at "..gx..","..gy, "VehicleDamage")
                            zombies[index] = obj
                            index = index + 1
                        end
                    end
                end
            end
        end
    end

    local totalZombies = index - 1
    debugPrint("Found "..totalZombies.." zombies to check", "VehicleDamage")

    for i=1, totalZombies do
        local zombie = zombies[i]
        if zombie then
            local state = zombie:getCurrentState()
            if state then
                local zombieId    = zombie:getOnlineID()
                local currentTime = getTimestampMs()
                local lastTime    = zombieDamageCooldowns[zombieId]

                if not lastTime or (currentTime - lastTime) >= DAMAGE_COOLDOWN then
                    local stateStr = tostring(state)
                    debugPrint("Zombie state: "..stateStr, "VehicleDamage")

                    if stateStr:find("AttackVehicle") then
                        debugPrint("Processing attacking zombie "..zombieId, "VehicleDamage")

                        local vehicle, part = getAttackedVehicleAndPart(zombie)
                        if vehicle then
                            debugPrint("Zombie is attacking vehicle="..tostring(vehicle)
                                       .." part="..(part and part:getId() or "nil"),
                                       "VehicleDamage")

                            zombieDamageCooldowns[zombieId] = currentTime

                            -- ### DAMAGE LOGIC ###
                            local baseDmg   = BHZ.THUMP_DMG
                            local matType   = getVehicleMaterialType(vehicle, part)
                            local matMult   = MaterialDamageMultiplier[matType] or 1.0
                            local speedMult = 1 -- ignoring game-speed for vehicles

                            local finalDmg  = baseDmg * matMult * speedMult

                            debugPrint(string.format(
                                "VehicleDamage: Zombie=%d final=%.2f (base=%.2f, matType=%s, matMult=%.2f, speedMult=%.2f)",
                                zombieId, finalDmg, baseDmg, matType, matMult, speedMult
                            ), "DamageCalc")

                            local newHealth = zombie:getHealth() - finalDmg
                            if newHealth <= 0 then
                                zombie:Kill(nil)
                            else
                                zombie:setHealth(newHealth)
                            end

                            if BHZ.BLOOD_ENABLED then
                                local zSq = zombie:getSquare()
                                if zSq then
                                    addBloodSplat(zSq, matMult)
                                end
                            end
                            -- ### END DAMAGE LOGIC ###
                        end
                    end
                end
            end
        end
    end
end

-- ########################################################################
-- ##  THUMPING (Barricades/Doors/Windows)
-- ########################################################################

local function getMaterialType(target)
    if not target then
        debugPrint("getMaterialType: target=nil => WOOD")
        return "WOOD"
    end

    debugPrint("getMaterialType: Checking => "..tostring(target))

    if instanceof(target, "BaseVehicle") then
        local part = target:getCurrentPart()
        return getVehicleMaterialType(target, part)
    end

    if instanceof(target, "IsoThumpable") then
        local isMetal = target:getSprite():getProperties():Is("Material") == "Metal"
        debugPrint("IsoThumpable => isMetal="..tostring(isMetal))
        return isMetal and "METAL" or "WOOD"
    elseif instanceof(target, "IsoBarricade") then
        local isMetal = target:isMetal()
        debugPrint("IsoBarricade => isMetal="..tostring(isMetal))
        return isMetal and "METAL" or "WOOD"
    end

    debugPrint("getMaterialType: default => WOOD")
    return "WOOD"
end

local function isPlayerBuiltOrMoved(thump_target)
    if not thump_target then return false end
    if instanceof(thump_target, "BaseVehicle") then return true end
    if instanceof(thump_target, "IsoThumpable") then return true end
    if instanceof(thump_target, "IsoBarricade") then return true end
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

    local SandboxVars = SandboxVars
    if SandboxVars and SandboxVars.BarricadesHurtZombies then
        -- Process core damage settings
        local baseDamage = tonumber(SandboxVars.BarricadesHurtZombies.BaseDamage) or 5
        -- Clamp base damage between 0-100%
        if baseDamage < 0   then baseDamage = 0   end
        if baseDamage > 100 then baseDamage = 100 end
        -- Convert percentage to decimal (5% becomes 0.05)
        BHZ.THUMP_DMG = baseDamage / 100
        debugPrint("BaseDamage=" .. baseDamage .. "% => THUMP_DMG=" .. BHZ.THUMP_DMG)

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
        BHZ.BLOOD_ENABLED = SandboxVars.BarricadesHurtZombies.BloodEffects

        -- Set up vehicle system configuration
        DAMAGE_COOLDOWN = SandboxVars.BarricadesHurtZombies.VehicleDamageCooldown or 0
        PROCESS_INTERVAL = SandboxVars.BarricadesHurtZombies.VehicleUpdateInterval or 150

        -- Update vehicle detection ranges if custom ranges are enabled
        if SandboxVars.BarricadesHurtZombies.CustomVehicleRanges then
            PART_DETECTION_RADIUS = {
                -- Engine-related parts
                Engine = SandboxVars.BarricadesHurtZombies.VehicleEngineRange or 2.6,
                SVU_Armor_Front = SandboxVars.BarricadesHurtZombies.VehicleEngineRange or 2.6,
                
                -- Trunk-related parts
                TrunkDoor = SandboxVars.BarricadesHurtZombies.VehicleTrunkRange or 2.7,
                TrunkLid = SandboxVars.BarricadesHurtZombies.VehicleTrunkRange or 2.7,
                SVU_Armor_Rear = SandboxVars.BarricadesHurtZombies.VehicleTrunkRange or 2.7,
                
                -- Door-related parts
                DoorFrontLeft = SandboxVars.BarricadesHurtZombies.VehicleDoorRange or 2.4,
                DoorFrontRight = SandboxVars.BarricadesHurtZombies.VehicleDoorRange or 2.4,
                DoorRearLeft = SandboxVars.BarricadesHurtZombies.VehicleDoorRange or 2.5,
                DoorRearRight = SandboxVars.BarricadesHurtZombies.VehicleDoorRange or 2.5,
                SVU_Armor_Left = SandboxVars.BarricadesHurtZombies.VehicleDoorRange or 2.6,
                SVU_Armor_Right = SandboxVars.BarricadesHurtZombies.VehicleDoorRange or 2.6,

                -- Default fallback for unspecified parts
                default = 2.2
            }
        end

        -- Configure debug settings
        DEBUG_MODE = SandboxVars.BarricadesHurtZombies.DebugMode or false
        DEBUG_VEHICLES = SandboxVars.BarricadesHurtZombies.VehicleDebugMode or false
        BHZ.LOG_ENABLED = DEBUG_MODE or DEBUG_VEHICLES

        -- Log the configuration if debugging is enabled
        if DEBUG_MODE then
            debugPrint("BHZ Configuration loaded:")
            debugPrint(string.format("  Base Damage: %.1f%%", baseDamage))
            debugPrint(string.format("  Damage Mode: %d", mode))
            debugPrint(string.format("  Metal Multiplier: %.2fx", MaterialDamageMultiplier.METAL))
            debugPrint(string.format("  Vehicle Cooldown: %dms", DAMAGE_COOLDOWN))
            debugPrint(string.format("  Update Interval: %dms", PROCESS_INTERVAL))
            debugPrint(string.format("  Custom Ranges: %s", 
                SandboxVars.BarricadesHurtZombies.CustomVehicleRanges and "enabled" or "disabled"))
        end
    else
        -- If no sandbox settings found, use safe defaults
        debugPrint("No sandbox config => using defaults")
        BHZ.THUMP_DMG = 0.05      -- 5% base damage
        BHZ.THUMP_FUNC = isPlayerBuiltOrMoved
        BHZ.BLOOD_ENABLED = true
        DEBUG_MODE = false
        DEBUG_VEHICLES = false
        BHZ.LOG_ENABLED = false
        DAMAGE_COOLDOWN = 0
        PROCESS_INTERVAL = 150

        -- Reset all multipliers to defaults
        for mat, mult in pairs(DEFAULT_MULTIPLIERS) do
            MaterialDamageMultiplier[mat] = mult
        end
    end

    debugPrint("BHZ mod settings loaded")
end

-- ########################################################################
-- ##  EVENT REGISTRATIONS
-- ########################################################################

Events.OnLoad.Add(onLoad)
Events.OnWorldSound.Add(onZombieThump)
Events.OnTick.Add(processVehicleDamage)
