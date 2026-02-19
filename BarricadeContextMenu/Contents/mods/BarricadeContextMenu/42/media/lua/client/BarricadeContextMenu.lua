--
-- BarricadeContextMenu.lua
-- Restores right-click barricade/unbarricade options for windows and doors in Build 42.
-- Calls existing vanilla handlers with a fix for ISBarricadeAction.
--
-- B42 moved barricading to the build recipe system, leaving ISBarricadeAction as dead code
-- with a bug: isValid() uses ItemType.HAMMER (nil) instead of ItemTag.HAMMER, causing the
-- action to always fail. We patch isValid() to fix this.
--

require "TimedActions/ISBarricadeAction"

-----------------------------------------------------------
-- Fix vanilla ISBarricadeAction.isValid() bug:
-- Line 31 uses ItemType.HAMMER (nil) instead of ItemTag.HAMMER
-----------------------------------------------------------
function ISBarricadeAction:isValid()
    if not instanceof(self.item, "BarricadeAble") or self.item:getObjectIndex() == -1 then
        return false
    end
    local barricade = self.item:getBarricadeForCharacter(self.character)
    if self.isMetal then
        if barricade then
            return false
        end
        if not self.character:hasEquipped("BlowTorch") or not self.character:hasEquipped("SheetMetal") then
            return false
        end
    elseif self.isMetalBar then
        if barricade then
            return false
        end
        if not self.character:hasEquipped("BlowTorch") or not self.character:hasEquipped("MetalBar") then
            return false
        end
        if self.character:getInventory():getItemCount("Base.MetalBar", true) < 3 then
            return false
        end
    else
        if barricade and not barricade:canAddPlank() then
            return false
        end
        -- FIX: vanilla uses ItemType.HAMMER (nil), should be ItemTag.HAMMER
        if not self.character:hasEquippedTag(ItemTag.HAMMER) then
            return false
        end
        if not self.character:hasEquipped("Plank") then
            return false
        end
        if self.character:getInventory():getItemCount("Base.Nails", true) < 2 then
            return false
        end
    end
    if self.isStarted then
        if instanceof(self.item, "IsoDoor") or (instanceof(self.item, "IsoThumpable") and self.item:isDoor()) then
            if self.item:IsOpen() then
                return false
            end
        end
    end
    return true
end

-----------------------------------------------------------
-- Context menu hook
-----------------------------------------------------------

-- Local predicates (vanilla ones are file-local, inaccessible from mods)
local function predicateNotBroken(item)
    return not item:isBroken()
end

local function isBarricadeableObject(obj)
    if instanceof(obj, "IsoWindow") or instanceof(obj, "IsoDoor") then
        return true
    end
    if instanceof(obj, "IsoThumpable") then
        return obj:isDoor() or obj:isWindow()
    end
    if instanceof(obj, "IsoWindowFrame") then
        return true
    end
    return false
end

local function addBarricadeOptions(obj, playerObj, playerInv, context, worldobjects, player, test)
    if not isBarricadeableObject(obj) then return false end
    if not obj:isBarricadeAllowed() then return false end

    local addedOption = false

    -- Already barricaded: show removal options
    if obj:isBarricaded() then
        local barricade = obj:getBarricadeForCharacter(playerObj)
        if barricade then
            if barricade:isMetal() then
                if playerInv:containsTypeRecurse("BlowTorch") then
                    if test then return true end
                    context:addOption(
                        getText("ContextMenu_Unbarricade"),
                        worldobjects, ISWorldObjectContextMenu.onUnbarricadeMetal, obj, player
                    )
                    addedOption = true
                end
            elseif barricade:isMetalBar() then
                if playerInv:containsTypeRecurse("BlowTorch") then
                    if test then return true end
                    context:addOption(
                        getText("ContextMenu_Unbarricade"),
                        worldobjects, ISWorldObjectContextMenu.onUnbarricadeMetalBar, obj, player
                    )
                    addedOption = true
                end
            else
                if playerInv:getFirstTagEvalRecurse(ItemTag.REMOVE_BARRICADE, predicateNotBroken) then
                    if test then return true end
                    context:addOption(
                        getText("ContextMenu_Unbarricade"),
                        worldobjects, ISWorldObjectContextMenu.onUnbarricade, obj, player
                    )
                    addedOption = true
                end
            end
        end
    end

    -- Barricade options (wood planks)
    local hammer = playerInv:getFirstTagEvalRecurse(ItemTag.HAMMER, predicateNotBroken)
    if hammer and playerInv:containsTypeRecurse("Plank")
       and playerInv:getItemCountRecurse("Base.Nails") >= 2 then
        if test then return true end
        context:addOption(
            getText("ContextMenu_Barricade"),
            worldobjects, ISWorldObjectContextMenu.onBarricade, obj, player
        )
        addedOption = true
    end

    -- Barricade options (metal sheet)
    if playerInv:containsTypeRecurse("BlowTorch")
       and playerInv:containsTypeRecurse("SheetMetal") then
        if test then return true end
        context:addOption(
            getText("ContextMenu_MetalBarricade"),
            worldobjects, ISWorldObjectContextMenu.onMetalBarricade, obj, player
        )
        addedOption = true
    end

    -- Barricade options (metal bars)
    if playerInv:containsTypeRecurse("BlowTorch")
       and playerInv:getItemCountRecurse("Base.MetalBar") >= 3 then
        if test then return true end
        context:addOption(
            getText("ContextMenu_MetalBarBarricade"),
            worldobjects, ISWorldObjectContextMenu.onMetalBarBarricade, obj, player
        )
        addedOption = true
    end

    return addedOption
end

local function onFillBarricadeMenu(player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    local playerInv = playerObj:getInventory()

    -- Track processed objects to avoid duplicates
    local seen = {}
    for i = 1, #worldobjects do
        local obj = worldobjects[i]
        if not seen[obj] then
            seen[obj] = true
            if addBarricadeOptions(obj, playerObj, playerInv, context, worldobjects, player, test) then
                if test then return true end
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillBarricadeMenu)
