--[[
    BHZ Debug Helper
    Only active when DebugMode is enabled in sandbox settings.
    Provides in-game diagnostic utilities for testing and troubleshooting
    the Barricades Hurt Zombies mod.

    Usage (from Lua console):
        BHZDebug.printConfig()          -- Show current mod configuration
        BHZDebug.printNearbyZombies()   -- List zombies within 3 tiles
        BHZDebug.printNearbyVehicles()  -- List vehicles within 5 tiles
        BHZDebug.printMaterialInfo()    -- Show material type of nearby thumpables
        BHZDebug.printCooldowns()       -- Dump cooldown table state
--]]

BHZDebug = {}

local function isDebugEnabled()
    local sv = SandboxVars
    if not sv or not sv.BarricadesHurtZombies then return false end
    return sv.BarricadesHurtZombies.DebugMode == true
end

-- Print current BHZ configuration summary
function BHZDebug.printConfig()
    if not isDebugEnabled() then
        print("[BHZDebug] Debug mode is not enabled in sandbox settings.")
        return
    end

    local sv = SandboxVars.BarricadesHurtZombies
    print("=== BHZ Configuration ===")
    print("  BaseDamage: " .. tostring(sv.BaseDamage) .. "%")
    print("  DamageMode: " .. tostring(sv.DamageMode))

    local modeNames = { [1] = "Normal (player-built only)", [2] = "All objects", [3] = "Disabled" }
    print("  DamageMode meaning: " .. (modeNames[sv.DamageMode] or "Unknown"))

    print("  MetalMultiplier: " .. tostring(sv.MetalMultiplier) .. "x")
    print("  MetalHeavyMultiplier: " .. tostring(sv.MetalHeavyMultiplier) .. "x")
    print("  LightSpikeMultiplier: " .. tostring(sv.LightSpikeMultiplier) .. "x")
    print("  HeavySpikeMultiplier: " .. tostring(sv.HeavySpikeMultiplier) .. "x")
    print("  ReinforcedMultiplier: " .. tostring(sv.ReinforcedMultiplier) .. "x")

    print("  BloodEffects: " .. tostring(sv.BloodEffects))
    print("  ThumpDamageCooldown: " .. tostring(sv.ThumpDamageCooldown) .. "ms")
    print("  VehicleDamageCooldown: " .. tostring(sv.VehicleDamageCooldown) .. "ms")
    print("  VehicleUpdateInterval: " .. tostring(sv.VehicleUpdateInterval) .. " ticks")
    print("  CustomVehicleRanges: " .. tostring(sv.CustomVehicleRanges))

    if sv.CustomVehicleRanges then
        print("  VehicleEngineRange: " .. tostring(sv.VehicleEngineRange))
        print("  VehicleDoorRange: " .. tostring(sv.VehicleDoorRange))
        print("  VehicleTrunkRange: " .. tostring(sv.VehicleTrunkRange))
    end

    print("  DebugMode: " .. tostring(sv.DebugMode))
    print("  VehicleDebugMode: " .. tostring(sv.VehicleDebugMode))
    print("========================")
end

-- Print information about all zombies within a radius of the player
function BHZDebug.printNearbyZombies()
    if not isDebugEnabled() then
        print("[BHZDebug] Debug mode is not enabled.")
        return
    end

    local player = getPlayer()
    if not player then
        print("[BHZDebug] No player found.")
        return
    end

    local sq = player:getSquare()
    if not sq then
        print("[BHZDebug] Player has no square.")
        return
    end

    local cell = sq:getCell()
    if not cell then
        print("[BHZDebug] No cell available.")
        return
    end

    local px, py, pz = player:getX(), player:getY(), player:getZ()
    local count = 0
    local radius = 3

    print("=== Nearby Zombies (radius " .. radius .. ") ===")

    for ox = -radius, radius do
        for oy = -radius, radius do
            local sqr = cell:getGridSquare(px + ox, py + oy, pz)
            if sqr then
                local mo = sqr:getMovingObjects()
                if mo then
                    for i = 0, mo:size() - 1 do
                        local obj = mo:get(i)
                        if obj and instanceof(obj, "IsoZombie") then
                            count = count + 1
                            local hp = obj:getHealth()
                            local alive = obj:isAlive()
                            local id = obj:getOnlineID()
                            local target = obj:getThumpTarget()
                            local state = "unknown"
                            if obj.getCurrentStateName then
                                state = obj:getCurrentStateName() or "nil"
                            elseif obj.getCurrentState then
                                state = tostring(obj:getCurrentState())
                            end

                            local targetStr = "none"
                            if target then
                                if instanceof(target, "BaseVehicle") then
                                    targetStr = "Vehicle"
                                elseif instanceof(target, "IsoThumpable") then
                                    targetStr = "IsoThumpable"
                                elseif instanceof(target, "IsoBarricade") then
                                    targetStr = "IsoBarricade"
                                else
                                    targetStr = tostring(target)
                                end
                            end

                            print(string.format(
                                "  #%d: id=%d hp=%.3f alive=%s state=%s target=%s pos=(%.1f,%.1f)",
                                count, id, hp, tostring(alive), state, targetStr,
                                obj:getX(), obj:getY()
                            ))
                        end
                    end
                end
            end
        end
    end

    if count == 0 then
        print("  No zombies found nearby.")
    end
    print("Total: " .. count .. " zombies")
    print("========================")
end

-- Print information about nearby vehicles
function BHZDebug.printNearbyVehicles()
    if not isDebugEnabled() then
        print("[BHZDebug] Debug mode is not enabled.")
        return
    end

    local player = getPlayer()
    if not player then
        print("[BHZDebug] No player found.")
        return
    end

    local sq = player:getSquare()
    if not sq then
        print("[BHZDebug] Player has no square.")
        return
    end

    local cell = sq:getCell()
    if not cell then
        print("[BHZDebug] No cell available.")
        return
    end

    local vehicles = cell:getVehicles()
    if not vehicles then
        print("[BHZDebug] No vehicle list available.")
        return
    end

    local px, py = player:getX(), player:getY()
    local radius = 5
    local count = 0

    print("=== Nearby Vehicles (radius " .. radius .. ") ===")

    for i = 0, vehicles:size() - 1 do
        local v = vehicles:get(i)
        if v and instanceof(v, "BaseVehicle") and v.getX and v.getY then
            local vx, vy = v:getX(), v:getY()
            local dx = px - vx
            local dy = py - vy
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist <= radius then
                count = count + 1
                local script = v:getScript()
                local vtype = "unknown"
                if script and script.getName then
                    vtype = script:getName() or "unknown"
                end

                local angleMethod = v.getAngleZ or v.getAngle
                local angle = "N/A"
                if angleMethod then
                    local a = angleMethod(v)
                    if a then
                        angle = string.format("%.2f", a)
                    end
                end

                print(string.format(
                    "  #%d: type=%s pos=(%.1f,%.1f) angle=%s dist=%.2f",
                    count, vtype, vx, vy, angle, dist
                ))

                -- List damageable parts
                local parts = v:getParts()
                if parts then
                    local partCount = parts:size()
                    local partNames = {}
                    for j = 0, partCount - 1 do
                        local part = parts:get(j)
                        if part then
                            local pid = part:getId()
                            if pid then
                                partNames[#partNames + 1] = pid
                            end
                        end
                    end
                    if #partNames > 0 then
                        print("    Parts: " .. table.concat(partNames, ", "))
                    end
                end
            end
        end
    end

    if count == 0 then
        print("  No vehicles found nearby.")
    end
    print("Total: " .. count .. " vehicles")
    print("========================")
end

-- Print material type information for nearby thumpable objects
function BHZDebug.printMaterialInfo()
    if not isDebugEnabled() then
        print("[BHZDebug] Debug mode is not enabled.")
        return
    end

    local player = getPlayer()
    if not player then
        print("[BHZDebug] No player found.")
        return
    end

    local sq = player:getSquare()
    if not sq then
        print("[BHZDebug] Player has no square.")
        return
    end

    local cell = sq:getCell()
    if not cell then
        print("[BHZDebug] No cell available.")
        return
    end

    local px, py, pz = player:getX(), player:getY(), player:getZ()
    local radius = 2
    local count = 0

    print("=== Nearby Thumpable Materials (radius " .. radius .. ") ===")

    for ox = -radius, radius do
        for oy = -radius, radius do
            local sqr = cell:getGridSquare(px + ox, py + oy, pz)
            if sqr then
                local objects = sqr:getObjects()
                if objects then
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj then
                            local objType = "Other"
                            local material = "N/A"
                            local hasCustomMult = false
                            local customMult = nil

                            if instanceof(obj, "IsoThumpable") then
                                objType = "IsoThumpable"
                                local sprite = obj:getSprite()
                                if sprite then
                                    local props = sprite:getProperties()
                                    if props then
                                        local isMetal = props:Is("Material", "Metal")
                                        material = isMetal and "METAL" or "WOOD"
                                    else
                                        material = "WOOD (no props)"
                                    end
                                else
                                    material = "WOOD (no sprite)"
                                end

                                local md = obj:getModData()
                                if md and md.BarricadeDamageMultiplier then
                                    hasCustomMult = true
                                    customMult = md.BarricadeDamageMultiplier
                                end

                                count = count + 1
                                local line = string.format(
                                    "  #%d: %s at (%d,%d) material=%s",
                                    count, objType, px + ox, py + oy, material
                                )
                                if hasCustomMult then
                                    line = line .. " customMult=" .. tostring(customMult)
                                end
                                print(line)

                            elseif instanceof(obj, "IsoBarricade") then
                                objType = "IsoBarricade"
                                local isMetal = obj:isMetal()
                                material = isMetal and "METAL" or "WOOD"

                                count = count + 1
                                print(string.format(
                                    "  #%d: %s at (%d,%d) material=%s",
                                    count, objType, px + ox, py + oy, material
                                ))
                            end
                        end
                    end
                end
            end
        end
    end

    if count == 0 then
        print("  No thumpable objects found nearby.")
    end
    print("Total: " .. count .. " thumpable objects")
    print("========================")
end

-- Dump the cooldown table state (requires access to BHZCore internals)
-- Since the cooldown table is local to BHZCore, this provides guidance on
-- how to check it, and reports what it can observe externally.
function BHZDebug.printCooldowns()
    if not isDebugEnabled() then
        print("[BHZDebug] Debug mode is not enabled.")
        return
    end

    print("=== BHZ Cooldown Info ===")
    print("  Note: The cooldown table (zombieDamageCooldowns) is local to BHZCore.")
    print("  To inspect it directly, temporarily expose it in BHZCore.lua:")
    print("    BHZ.cooldowns = zombieDamageCooldowns")
    print("  Then call: for k,v in pairs(BHZ.cooldowns) do print(k,v) end")
    print("")
    print("  Configured cooldowns:")
    local sv = SandboxVars
    if sv and sv.BarricadesHurtZombies then
        print("    ThumpDamageCooldown: " .. tostring(sv.BarricadesHurtZombies.ThumpDamageCooldown) .. "ms")
        print("    VehicleDamageCooldown: " .. tostring(sv.BarricadesHurtZombies.VehicleDamageCooldown) .. "ms")
    else
        print("    (sandbox settings not available)")
    end
    print("  Cleanup runs every 1000 vehicle tick cycles.")
    print("  Stale entries older than 10 seconds are purged.")
    print("========================")
end

-- Initialization: runs on game load, prints a banner if debug is enabled
local function initDebug()
    if not isDebugEnabled() then return end

    print("========================================")
    print("[BHZDebug] Debug helper loaded.")
    print("[BHZDebug] Available commands:")
    print("  BHZDebug.printConfig()")
    print("  BHZDebug.printNearbyZombies()")
    print("  BHZDebug.printNearbyVehicles()")
    print("  BHZDebug.printMaterialInfo()")
    print("  BHZDebug.printCooldowns()")
    print("========================================")

    -- Auto-print config on load
    BHZDebug.printConfig()
end

Events.OnLoad.Add(initDebug)
