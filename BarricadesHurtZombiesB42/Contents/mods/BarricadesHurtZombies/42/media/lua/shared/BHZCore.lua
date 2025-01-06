-- Barricades Hurt Zombies - Core Functionality
-- Original mod by Brightex
-- Build 42 update

-- Damage multiplier based on game speed
local GameSpeedToDmgMultiplier = {1, 5, 20, 40}

---@class BarricadesHurtZombies
local BHZ = {
    THUMP_DMG = 0,        -- Damage dealt to zombies per thump
    THUMP_FUNC = nil      -- Function to determine if a barricade should cause damage
}

--- Check if object is player built or moved
---@param thump_target IsoObject The object being attacked
---@return boolean
local function isPlayerBuiltOrMoved(thump_target)
    if not thump_target then return false end
    
    if instanceof(thump_target, "IsoThumpable") then 
        return true -- Player built structures
    elseif instanceof(thump_target, "IsoBarricade") then 
        return true -- Barricades on window frames
    elseif instanceof(thump_target, "BarricadeAble") and not instanceof(thump_target, "IsoThumpable") then
        return thump_target:isBarricaded() -- Only count if actually barricaded
    end
    return false
end

--- Check all objects
---@param thump_target IsoObject The object being attacked
---@return boolean
local function checkAll(thump_target)
    return thump_target ~= nil
end

--- Check no objects
---@param thump_target IsoObject The object being attacked
---@return boolean
local function checkNothing(thump_target)
    return false
end

--- Get the appropriate check function based on sandbox settings
---@param option number The sandbox option value
---@return function
local function getHurtingBarricadeFunc(option)
    if option == 1 then 
        return isPlayerBuiltOrMoved
    elseif option == 2 then 
        return checkAll
    else 
        return checkNothing
    end
end

--- Handle zombie taking damage from hitting barricades
---@param x number X coordinate of sound
---@param y number Y coordinate of sound
---@param z number Z coordinate of sound
---@param radius number Radius of sound effect
---@param volume number Volume of sound
---@param source IsoObject Source of the sound
local function onZombieThump(x, y, z, radius, volume, source)
    -- Check if source is a zombie in thump state
    if not (instanceof(source, "IsoZombie") and source:getCurrentStateName() == "ThumpState") then
        return
    end

    local zombie = source
    local thump_target = zombie:getThumpTarget()
    
    -- Validate thump target
    if not thump_target then return end

    -- Calculate damage
    local thump_dmg = BHZ.THUMP_DMG
    local blood_intensity = 1

    -- Check for custom damage multiplier in mod data
    local damage_multiplier = thump_target:getModData().BarricadeDamageMultiplier
    if damage_multiplier then
        thump_dmg = thump_dmg * damage_multiplier
        blood_intensity = blood_intensity * damage_multiplier
    else
        -- If no custom multiplier, check if this type of barricade should cause damage
        if BHZ.THUMP_FUNC and not BHZ.THUMP_FUNC(thump_target) then
            return
        end
    end

    -- Apply damage based on game speed
    local game_speed = getGameSpeed()
    local multiplier = GameSpeedToDmgMultiplier[game_speed] or 1 -- Default to 1 if undefined
    local damage = thump_dmg * multiplier
    local new_health = zombie:getHealth() - damage

    -- Handle zombie death or damage
    if new_health <= 0 then
        zombie:Kill(zombie:getCell():getFakeZombieForHit(), true)
    else
        zombie:setHealth(new_health)
        -- Add blood effect
        local square = zombie:getSquare()
        if square then 
            addBloodSplat(square, blood_intensity)
        end
    end
end

--- Update mod settings when loading game or changing sandbox options
local function onLoad()
    if SandboxVars and SandboxVars.BarricadesHurtZombies then
        -- Ensure BarricadeDamage is within 0-100
        local barricadeDamage = tonumber(SandboxVars.BarricadesHurtZombies.BarricadeDamage) or 50
        barricadeDamage = math.max(0, math.min(100, barricadeDamage))
        BHZ.THUMP_DMG = barricadeDamage / 100
        BHZ.THUMP_FUNC = getHurtingBarricadeFunc(SandboxVars.BarricadesHurtZombies.HurtingBarricade)
    else
        print("[BHZCore.lua] Error: SandboxVars.BarricadesHurtZombies is not defined. Using default settings.")
        -- Set default values
        BHZ.THUMP_DMG = 0.5 -- Default to 50%
        BHZ.THUMP_FUNC = getHurtingBarricadeFunc(1) -- Default option 1
    end
end

-- Register event handlers
Events.OnLoad.Add(onLoad)
Events.OnWorldSound.Add(onZombieThump)
