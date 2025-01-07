--[[
    Barricades Hurt Zombies - Core Functionality
    Original mod by Brightex
    Build 42 update with SVU3 compatibility
    
    This mod makes zombies take damage when hitting barricades and vehicle armor.
    The damage system uses multipliers that stack with the base damage set in sandbox options:
    
    Default Damage Multipliers:
    - Wooden Barricades: 1.0x (baseline damage)
    - Metal Structures: 1.25x (25% more than wood)
    - Light Spikes: 1.5x (50% more than wood)
    - Heavy Spikes: 1.75x (75% more than wood)
    
    All multipliers can be adjusted through sandbox settings.
    The final damage is: (Base Damage) × (Material Multiplier) × (Game Speed Multiplier)
]]

-- Game speed multipliers help balance damage during fast-forward
-- For example, at 5x game speed, zombies hit 5x as often, so we multiply damage by 5
local GAME_SPEED_MULTIPLIERS = {1, 5, 20, 40}

-- These define our intended default multipliers for each material type
-- They serve as fallbacks if sandbox settings aren't available
local DEFAULT_MULTIPLIERS = {
    WOOD = 1.0,       -- Wood is our baseline for damage
    METAL = 1.25,     -- Metal does 25% more damage than wood
    LIGHT_SPIKE = 1.5, -- Light spikes do 50% more damage than wood
    HEAVY_SPIKE = 1.75 -- Heavy spikes do 75% more damage than wood
}

-- Active multipliers that will be updated from sandbox settings
-- We initialize everything to baseline wood damage for safety
local MaterialDamageMultiplier = {
    WOOD = DEFAULT_MULTIPLIERS.WOOD,       -- Wood always stays at baseline
    METAL = DEFAULT_MULTIPLIERS.WOOD,      -- Will be updated in onLoad
    LIGHT_SPIKE = DEFAULT_MULTIPLIERS.WOOD, -- Will be updated in onLoad
    HEAVY_SPIKE = DEFAULT_MULTIPLIERS.WOOD  -- Will be updated in onLoad
}

-- Core mod settings that get populated from sandbox options
---@class BarricadesHurtZombies
local BHZ = {
    THUMP_DMG = 0.5,      -- Base damage per hit (default 50%)
    THUMP_FUNC = nil,     -- Function determining what objects cause damage
    BLOOD_ENABLED = true  -- Whether to show blood effects
}

-- Check for SVU3 (Standardized Vehicle Upgrades 3) compatibility
local hasSVU = getModInfoByID("StandardizedVehicleUpgrades3Core") ~= nil and
               getModInfoByID("tsarslib") ~= nil

--- Determines what material type an object is to calculate appropriate damage
---@param target IsoObject The object being attacked
---@return string The material type: "WOOD", "METAL", "LIGHT_SPIKE", or "HEAVY_SPIKE"
local function getMaterialType(target)
    -- First check SVU3 vehicle parts if the mod is present
    if hasSVU and instanceof(target, "VehiclePart") then
        local partId = target:getId()
        -- Heavy armored parts like plows do maximum damage
        if partId:contains("HeavySpiked") or partId:contains("PlowSpiked") then
            return "HEAVY_SPIKE"
        -- Standard spiked armor does moderate spike damage
        elseif partId:contains("LightSpiked") or partId:contains("BullbarSpiked") then
            return "LIGHT_SPIKE"
        end
    end
    
    -- Then check vanilla game barricades and structures
    if instanceof(target, "IsoThumpable") then
        -- Check material property of the sprite
        return target:getSprite():getProperties():Is("Material") == "Metal" and "METAL" or "WOOD"
    elseif instanceof(target, "IsoBarricade") then
        -- Barricades have a direct metal check
        return target:isMetal() and "METAL" or "WOOD"
    end
    
    -- Default to wood damage if we can't determine the material
    return "WOOD"
end

--- Checks if an object should damage zombies in normal mode (sandbox option 1)
---@param thump_target IsoObject The object being attacked
---@return boolean True if this object should damage zombies
local function isPlayerBuiltOrMoved(thump_target)
    if not thump_target then return false end
    
    -- Check vanilla game barricades
    if instanceof(thump_target, "IsoThumpable") then 
        return true -- Player-built structures
    elseif instanceof(thump_target, "IsoBarricade") then 
        return true -- Window barricades
    elseif instanceof(thump_target, "BarricadeAble") and not instanceof(thump_target, "IsoThumpable") then
        return thump_target:isBarricaded() -- Other barricaded objects
    end

    -- Check SVU3 vehicle armor if available
    if hasSVU and instanceof(thump_target, "VehiclePart") then
        local partId = thump_target:getId()
        -- Match any SVU3 armor type
        if partId:contains("ATA2Protection") or
           partId:contains("Spiked") or
           partId:contains("Plow") then
            return true
        end
    end

    return false
end

--- Makes everything damage zombies (sandbox option 2)
---@param thump_target IsoObject The object being attacked
---@return boolean Always returns true
local function checkAll(thump_target)
    return thump_target ~= nil
end

--- Disables all damage (sandbox option 3)
---@param thump_target IsoObject The object being attacked
---@return boolean Always returns false
local function checkNothing(thump_target)
    return false
end

--- Gets the right damage check function based on sandbox settings
---@param option number The sandbox option (1=normal, 2=all objects, 3=none)
---@return function The function to use for damage checking
local function getHurtingBarricadeFunc(option)
    if option == 1 then 
        return isPlayerBuiltOrMoved
    elseif option == 2 then 
        return checkAll
    else 
        return checkNothing
    end
end

--- Main function that handles zombie damage when they hit objects
---@param x number X coordinate of sound
---@param y number Y coordinate of sound
---@param z number Z coordinate of sound
---@param radius number Radius of sound effect
---@param volume number Volume of sound
---@param source IsoObject Source of the sound
local function onZombieThump(x, y, z, radius, volume, source)
    -- Only proceed for zombie attack sounds
    if not (instanceof(source, "IsoZombie") and source:getCurrentStateName() == "ThumpState") then
        return
    end

    local zombie = source
    local thump_target = zombie:getThumpTarget()
    
    -- Need a valid target to proceed
    if not thump_target then return end

    -- Start with base damage from sandbox settings
    local thump_dmg = BHZ.THUMP_DMG
    local blood_intensity = 1

    -- Apply the material-based multiplier
    local materialType = getMaterialType(thump_target)
    local materialMultiplier = MaterialDamageMultiplier[materialType]
    thump_dmg = thump_dmg * materialMultiplier
    blood_intensity = blood_intensity * materialMultiplier

    -- Check for custom multipliers in mod data
    local damage_multiplier = thump_target:getModData().BarricadeDamageMultiplier
    if damage_multiplier then
        thump_dmg = thump_dmg * damage_multiplier
        blood_intensity = blood_intensity * damage_multiplier
    else
        -- If no custom multiplier, verify this object should cause damage
        if BHZ.THUMP_FUNC and not BHZ.THUMP_FUNC(thump_target) then
            return
        end
    end

    -- Apply final damage based on game speed
    local game_speed = getGameSpeed()
    local speed_mult = GAME_SPEED_MULTIPLIERS[game_speed] or 1
    local final_damage = thump_dmg * speed_mult
    local new_health = zombie:getHealth() - final_damage

    -- Apply the damage and effects
    if new_health <= 0 then
        zombie:Kill(zombie:getCell():getFakeZombieForHit(), true)
    else
        zombie:setHealth(new_health)
        -- Add blood effects if enabled
        if BHZ.BLOOD_ENABLED then
            local square = zombie:getSquare()
            if square then 
                addBloodSplat(square, blood_intensity)
            end
        end
    end
end

--- Initializes or updates mod settings from sandbox options
local function onLoad()
    if SandboxVars and SandboxVars.BarricadesHurtZombies then
        -- Load base damage (kept between 0-100%)
        local baseDamage = tonumber(SandboxVars.BarricadesHurtZombies.BaseDamage) or 50
        baseDamage = math.max(0, math.min(100, baseDamage))
        BHZ.THUMP_DMG = baseDamage / 100
        
        -- Load damage mode setting
        BHZ.THUMP_FUNC = getHurtingBarricadeFunc(SandboxVars.BarricadesHurtZombies.DamageMode)
        
        -- Load material multipliers (use defaults if settings missing)
        MaterialDamageMultiplier.METAL = SandboxVars.BarricadesHurtZombies.MetalMultiplier 
            or DEFAULT_MULTIPLIERS.METAL
        MaterialDamageMultiplier.LIGHT_SPIKE = SandboxVars.BarricadesHurtZombies.LightSpikeMultiplier 
            or DEFAULT_MULTIPLIERS.LIGHT_SPIKE
        MaterialDamageMultiplier.HEAVY_SPIKE = SandboxVars.BarricadesHurtZombies.HeavySpikeMultiplier 
            or DEFAULT_MULTIPLIERS.HEAVY_SPIKE
        
        -- Load blood effects setting
        BHZ.BLOOD_ENABLED = SandboxVars.BarricadesHurtZombies.BloodEffects
        
        -- Log the current configuration
        print(string.format("[BHZCore.lua] Initialized with: Base Damage=%d%%, Multipliers: Metal=%.2fx, Light Spikes=%.2fx, Heavy Spikes=%.2fx, Blood=%s, SVU3=%s",
            baseDamage,
            MaterialDamageMultiplier.METAL,
            MaterialDamageMultiplier.LIGHT_SPIKE,
            MaterialDamageMultiplier.HEAVY_SPIKE,
            BHZ.BLOOD_ENABLED and "On" or "Off",
            hasSVU and "Available" or "Not Found"
        ))
    else
        -- No sandbox settings found, use defaults
        print("[BHZCore.lua] No sandbox settings found, using defaults:")
        print(string.format("  Base Damage: 50%%, Multipliers: Metal=%.2fx, Light Spikes=%.2fx, Heavy Spikes=%.2fx",
            DEFAULT_MULTIPLIERS.METAL,
            DEFAULT_MULTIPLIERS.LIGHT_SPIKE,
            DEFAULT_MULTIPLIERS.HEAVY_SPIKE
        ))
        
        -- Set up default values
        BHZ.THUMP_DMG = 0.5  -- 50% base damage
        BHZ.THUMP_FUNC = getHurtingBarricadeFunc(1)  -- Normal damage rules
        BHZ.BLOOD_ENABLED = true
        
        -- Apply default multipliers
        MaterialDamageMultiplier.METAL = DEFAULT_MULTIPLIERS.METAL
        MaterialDamageMultiplier.LIGHT_SPIKE = DEFAULT_MULTIPLIERS.LIGHT_SPIKE
        MaterialDamageMultiplier.HEAVY_SPIKE = DEFAULT_MULTIPLIERS.HEAVY_SPIKE
    end
end

-- Register our event handlers
Events.OnLoad.Add(onLoad)
Events.OnWorldSound.Add(onZombieThump)