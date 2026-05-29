# Context Menus - PZ Data Map
Source: media/lua/client/ISUI | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | ISContextMenu API | 15-67 |
| 2 | Option object fields | 68-91 |
| 3 | Submenus | 92-114 |
| 4 | World object context menu | 115-152 |
| 5 | Inventory context menu | 153-186 |
| 6 | Icons, tooltips, styling | 187-243 |
| 7 | Mod integration patterns | 244-319 |

## 1. ISContextMenu API

Defined in `media/lua/client/ISUI/ISContextMenu.lua`. Derives from `ISPanel`.

### Creating a Context Menu

| Function | Purpose |
|-|-|
| ISContextMenu.get(player, x, y) | Get/reset the root context menu for a player. Use in event handlers. |
| ISContextMenu:getNew(parentContext) | Create a submenu attached to a parent context. Returns new ISContextMenu. |

`ISContextMenu.get()` clears any existing menu, sets position with a slide animation, and returns the root menu. Player 0 = mouse user; 1-3 = split-screen/controller.

### Adding Options

| Method | Signature | Purpose |
|-|-|-|
| addOption | (name, target, onSelect, p1..p10) | Add option to bottom of menu |
| addOptionOnTop | (name, target, onSelect, p1..p10) | Add option to top of menu |
| insertOptionAfter | (prevName, name, target, onSelect, p1..p10) | Insert after named option |
| insertOptionBefore | (nextName, name, target, onSelect, p1..p10) | Insert before named option |
| addColorBoxOption | (name, target, onSelect, p1..p10) | Add option with a colored icon square |
| addDebugOption | (name, target, onSelect, p1..p10) | Debug-only option (hidden via debug setting) |
| addGetUpOption | (text, target, onSelect, p2..p10) | Option that waits for character to get up first |
| addActionsOption | (text, getActionsFunc, a1..a10) | Option that queues actions via ISTimedActionQueue.queueActions |

All `addOption` variants return the option table. The `onSelect` callback receives `(target, p1, p2, ..., p10)`.

### Removing Options

| Method | Purpose |
|-|-|
| removeLastOption() | Remove the most recently added option |
| removeOptionByName(name) | Remove option by display name |

### Query Methods

| Method | Purpose |
|-|-|
| getOptionFromName(name) | Find option by name, returns option table or nil |
| getMenuOptionNames() | Returns table `{name = optionTable, ...}` |
| isEmpty() | Returns true if menu has no options (numOptions == 1) |
| isAnyVisible() | Check if this menu or any submenu is visible |

### Lifecycle

| Method | Purpose |
|-|-|
| clear() | Remove all options, reset state |
| closeAll() | Hide this menu and all ancestors |
| setFont(font) | Set font (UIFont.Small/Medium/Large) |
| setFontFromOption() | Set font from game options |

## 2. Option Object Fields

Each option returned by `addOption()` is a table with these fields:

| Field | Type | Purpose |
|-|-|-|
| id | number | 1-based position index |
| name | string | Display text |
| onSelect | function | Callback: onSelect(target, p1..p10) |
| target | any | First arg to onSelect |
| param1..param10 | any | Additional callback args |
| subOption | number | Submenu ID (set by addSubMenu) |
| iconTexture | Texture | Icon displayed left of text |
| color | table | {r,g,b} tint for iconTexture |
| itemForTexture | InventoryItem | Render item icon instead of texture |
| toolTip | ISToolTip | Tooltip shown on hover |
| notAvailable | boolean | Show in red, not clickable |
| isDisabled | boolean | Show grayed out, not clickable |
| badColor | boolean | Render name in "bad" highlight color |
| goodColor | boolean | Render name in "good" highlight color |
| checkMark | boolean | Show tick mark icon |
| onHighlight | function | Called when option is highlighted/unhighlighted |
| onHighlightParams | table | Args unpacked into onHighlight |

## 3. Submenus

### Creating Submenus
```lua
local context = ISContextMenu.get(player, x, y)
local option = context:addOption("Category")
local subMenu = ISContextMenu:getNew(context)
context:addSubMenu(option, subMenu)
subMenu:addOption("Sub Item", target, callback, ...)
```

### Key Submenu API

| Method | Purpose |
|-|-|
| ISContextMenu:getNew(parentContext) | Allocate submenu (pooled). Sets parent reference. |
| addSubMenu(option, subMenu) | Bind submenu to an option. Sets option.subOption. |
| getSubMenu(subOptionNum) | Retrieve submenu by its ID number. |

Submenus are pooled and recycled. `getNew()` draws from `subMenuPool` or creates fresh. All submenus tracked in `instanceMap` on the root menu.

**Nesting**: Submenus can have their own submenus. Pass the submenu as `parentContext` to `getNew()`.

## 4. World Object Context Menu

Defined in `media/lua/client/ISUI/ISWorldObjectContextMenu.lua`.

### Entry Point
`ISWorldObjectContextMenu.createMenu(player, worldobjects, x, y, test)` is called by Java when the player right-clicks the world.

### Flow
1. Checks: game mode, paused state, trading UI, sleeping
2. Gets context via `ISContextMenu.get(player, x, y)`
3. Calls `ISWorldObjectContextMenuLogic.fetch()` on each clicked world object to gather data
4. Fires `OnPreFillWorldObjectContextMenu(player, context, worldobjects, test)`
5. Calls `ISWorldObjectContextMenuLogic.createMenuEntries()` to populate vanilla options
6. Fires **`OnFillWorldObjectContextMenu(player, context, worldobjects, test)`** - this is the main mod hook
7. If `test == true`, returns `ISWorldObjectContextMenu.Test` (for controller validation)

### Event Signature
```lua
Events.OnFillWorldObjectContextMenu.Add(function(player, context, worldobjects, test)
    -- player: int (player index 0-3)
    -- context: ISContextMenu (the root context menu)
    -- worldobjects: table of IsoObject
    -- test: boolean (true = controller pre-check, only call setTest())
end)
```

### Controller Support (test parameter)
When `test == true`, the engine is checking whether any context options exist before showing the menu. Mod handlers should:
```lua
if test then
    ISWorldObjectContextMenu.setTest()  -- signals "yes, we have options"
    return true
end
```

### Helper: ISWorldObjectContextMenu.setTest()
Sets `ISWorldObjectContextMenu.Test = true`. Call this inside `OnFillWorldObjectContextMenu` when `test == true` and your mod has options to add.

## 5. Inventory Context Menu

Defined in `media/lua/client/ISUI/ISInventoryPaneContextMenu.lua`.

### Entry Point
`ISInventoryPaneContextMenu.createMenu(player, isInPlayerInventory, items, x, y, origin)`

### Flow
1. Checks: game mode, paused state, dontCreateMenu flag
2. Gets context via `ISContextMenu.get(player, x, y)`
3. Iterates items, builds `tests` table of boolean flags (isAllFood, isWeapon, clothing, etc.)
4. Creates vanilla options based on test flags
5. Fires **`OnFillInventoryObjectContextMenu(player, context, items)`** - this is the main mod hook

### Event Signature
```lua
Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items)
    -- player: int (player index 0-3)
    -- context: ISContextMenu
    -- items: table of {items = {InventoryItem, ...}} or InventoryItem
    --   First entry is a duplicate - skip index 1
end)
```

### Items Parameter
The `items` table is unusual. Each entry is either:
- A raw `InventoryItem` (single item selected)
- A table with `.items` field containing a list of `InventoryItem` (stacked items)

Index 1 is a duplicate of index 2. Iterate from index 2.

### No-Items Menu
`ISInventoryPaneContextMenu.createMenuNoItems(playerNum, isLoot, x, y)` fires `OnPreFillInventoryContextMenuNoItems` for right-clicking empty inventory space.

## 6. Icons, Tooltips, Styling

### Setting Option Icons
```lua
local option = context:addOption("My Option", ...)

-- Texture icon
option.iconTexture = getTexture("media/textures/myIcon.png")

-- Colored box
option.iconTexture = Texture.getWhite()
option.color = {r=0.2, g=0.8, b=0.2}

-- Item icon (renders the item's inventory sprite)
option.itemForTexture = someInventoryItem
```

### Tooltips
```lua
local option = context:addOption("My Option", ...)
local tooltip = ISToolTip:new()
tooltip:initialise()
tooltip:setVisible(false)
tooltip:setName("Title")
tooltip.description = "Line 1 <BR> Line 2"
tooltip.maxLineWidth = 300
option.toolTip = tooltip
```

Rich text in `description` supports `<BR>` for line breaks, `<RGB:r,g,b>` for color, `<LINE>` for horizontal rule.

### Styling Options
```lua
option.notAvailable = true   -- red text, not clickable
option.isDisabled = true     -- gray text, not clickable
option.badColor = true       -- "bad" highlight color (red-ish)
option.goodColor = true      -- "good" highlight color (green-ish)
```

### Check Marks
```lua
context:setOptionChecked(option, true)   -- sets option.checkMark
```

### Highlight Callback
```lua
option.onHighlight = function(self, contextMenu, isHighlighted, ...)
    -- called when cursor enters/leaves this option
end
option.onHighlightParams = {arg1, arg2}
```

### Blinking Options
```lua
context.blinkOption = "Option Name"  -- makes this option blink
```

## 7. Mod Integration Patterns

### World Context Menu (most common)
```lua
local function onFillWorldContext(player, context, worldobjects, test)
    if test then return true end  -- or call setTest() if adding options

    local playerObj = getSpecificPlayer(player)

    for _, obj in ipairs(worldobjects) do
        if instanceof(obj, "IsoThumpable") and obj:getName() == "My Object" then
            local option = context:addOption(
                getText("ContextMenu_MyAction"),
                playerObj,
                onMyAction,
                obj
            )
            -- Add tooltip
            local tooltip = ISToolTip:new()
            tooltip:initialise()
            tooltip:setVisible(false)
            tooltip.description = "Does the thing"
            option.toolTip = tooltip

            -- Disable if conditions not met
            if not playerObj:getInventory():containsType("RequiredItem") then
                option.notAvailable = true
                tooltip.description = tooltip.description .. " <BR> <RGB:1,0,0> Missing: Required Item"
            end
        end
    end
end
Events.OnFillWorldObjectContextMenu.Add(onFillWorldContext)
```

### Inventory Context Menu
```lua
local function onFillInvContext(player, context, items)
    local playerObj = getSpecificPlayer(player)

    -- Normalize items list (skip duplicate at index 1)
    for i = 2, #items do
        local itemOrStack = items[i]
        local item = itemOrStack
        if type(itemOrStack) == "table" then
            item = itemOrStack.items[1]
        end
        if item:getFullType() == "MyMod.MyItem" then
            context:addOption("Use My Item", playerObj, onUseMyItem, item)
        end
    end
end
Events.OnFillInventoryObjectContextMenu.Add(onFillInvContext)
```

### Submenu with Icons
```lua
local option = context:addOption("Category")
local sub = ISContextMenu:getNew(context)
context:addSubMenu(option, sub)

sub:addOption("Red Thing", target, callback)
sub:addOption("Blue Thing", target, callback2)

-- Set icon on sub-option
local subOpt = sub:getOptionFromName("Red Thing")
subOpt.iconTexture = getTexture("media/textures/redIcon.png")
```

### Pre-fill Hook (modify vanilla options)
```lua
Events.OnPreFillWorldObjectContextMenu.Add(function(player, context, worldobjects, test)
    -- Fires BEFORE vanilla options are added
    -- Use to set flags that affect vanilla menu building
end)
```
