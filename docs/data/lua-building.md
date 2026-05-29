# Building Objects - PZ Data Map
Source: media/lua/server/BuildingObjects, media/lua/client/BuildingObjects | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | ISBuildingObject base class | 17-50 |
| 2 | Fields and init defaults | 51-103 |
| 3 | Sprite and rotation system | 104-127 |
| 4 | Ghost/preview rendering | 128-150 |
| 5 | Placement validation | 151-175 |
| 6 | Material requirements | 176-198 |
| 7 | Build action integration | 199-242 |
| 8 | All building object types | 243-295 |
| 9 | Custom building object pattern | 296-390 |

## 1. ISBuildingObject Base Class

Defined in `media/lua/server/BuildingObjects/ISBuildingObject.lua`. Derives from `ISBaseObject`.

### Core Lifecycle

| Method | Purpose |
|-|-|
| new(...) | Construct instance. Call `init()`, set sprites, flags. |
| init() | Reset all fields to defaults (see section 2). |
| reset() | Reset sprite/rotation state only. Called by init(). |
| isValid(square) | Can this object be placed on `square`? Returns boolean. |
| render(x, y, z, square) | Draw ghost/preview sprite at position. |
| tryBuild(x, y, z) | Validate, walk to target, equip tools, queue ISBuildAction. |
| create(x, y, z, north, sprite) | **Override this.** Instantiate the Java object on the map. |
| walkTo(x, y, z) | Walk character to build location. Returns boolean. |
| onTimedActionStart(action) | Called by ISBuildAction:start(). Set animation/hand models. |
| onTimedActionStop(action) | Called by ISBuildAction:stop(). Cleanup. |
| onActionComplete() | Called when build finishes or is cancelled. Refresh UI. |
| onDestroy(thump, player) | Static. Called when IsoThumpable is destroyed. Drops materials. |

### Key Static Functions

| Function | Purpose |
|-|-|
| DoTileBuilding(item, isRender, x, y, z, sq) | Main render/build loop for mouse users. Bound to OnDoTileBuilding2. |
| DoTileBuildingJoyPad(item, isRender, x, y, z) | Same for controller. Bound to OnDoTileBuilding3. |

### Registered Events
- `Events.OnDoTileBuilding2` - mouse building loop
- `Events.OnDoTileBuilding3` - joypad building loop
- `Events.OnKeyPressed` - rotate building key
- `Events.OnDestroyIsoThumpable` - ISBuildingObject.onDestroy

## 2. Fields and Init Defaults

Set by `init()`:

| Field | Default | Purpose |
|-|-|-|
| canBeAlwaysPlaced | false | Skip normal placement rules (only check duplicate sprite) |
| isContainer | false | Object has storage capacity |
| canPassThrough | false | Characters can walk through it |
| canBarricade | false | Can be barricaded with planks/metal |
| thumpDmg | 8 | Damage dealt to zombies that thump this |
| isDoor | false | Object is a door |
| isDoorFrame | false | Object is a door frame |
| crossSpeed | 1.0 | Movement speed multiplier when crossing |
| blockAllTheSquare | false | Blocks entire tile |
| dismantable | false | Can be disassembled by player |
| canBePlastered | false | Can apply plaster to walls |
| hoppable | false | Can be climbed over (fences) |
| isThumpable | true | Zombies can attack this |
| isFloor | false | Object is a floor tile |
| modData | {} | Key-value data for material tracking |

Set by `reset()` (sprite state):

| Field | Default | Purpose |
|-|-|-|
| nSprite | 1 | Current rotation (1=W, 2=N, 3=E, 4=S) |
| north/south/east/west | false | Current facing booleans |
| chosenSprite | nil | Active sprite name after rotation |
| isWallLike | false | Placement uses wall-adjacent walking |
| isCorner | false | Is a corner piece |
| dragNilAfterPlace | false | Remove drag cursor after placing |
| completionSound | nil | Sound on build complete |

Additional fields set by subclass `new()`:

| Field | Purpose |
|-|-|
| sprite | West-facing sprite name |
| northSprite | North-facing sprite name |
| eastSprite | East-facing sprite name (optional, falls back to sprite) |
| southSprite | South-facing sprite name (optional, falls back to northSprite) |
| name | Display name for the object |
| player | Player index (0-3) |
| noNeedHammer | Skip hammer requirement |
| firstItem | Item type to equip in primary hand |
| secondItem | Item type to equip in secondary hand |
| buildLow | Use low build animation |
| actionAnim | Override build animation name |
| maxTime | Override build duration |
| skipBuildAction | Skip ISBuildAction, call create() directly |
| buildPanelLogic | Reference to ISBuildWindow panel |

## 3. Sprite and Rotation System

### getSprite() -> string
Returns the sprite name for current rotation. Sets `north/south/east/west` booleans.

| nSprite | Direction | Sprite Used |
|-|-|-|
| 1 | West | self.sprite |
| 2 | North | self.northSprite |
| 3 | East | self.eastSprite or self.sprite |
| 4 | South | self.southSprite or self.northSprite |

### Rotation Methods
- `rotateKey(key)` - increment nSprite on "Rotate building" key press
- `rotateMouse(x, y)` - set nSprite based on mouse direction relative to selected square

### Sprite Setters
```lua
obj:setSprite(sprite)        -- also sets chosenSprite
obj:setNorthSprite(sprite)
obj:setEastSprite(sprite)
obj:setSouthSprite(sprite)
```

## 4. Ghost/Preview Rendering

### render(x, y, z, square)
Draws a translucent preview of the object at the cursor position.

1. If `self.ghostSprite` is set, renders that instead (used for multi-tile objects).
2. If `self.renderFloorHelper` is true, draws a floor tile helper sprite underneath.
3. Loads sprite into `self.RENDER_SPRITE` (cached `IsoSprite`).
4. Checks `IsStackable` sprite property for vertical offset on stacked objects.
5. Calls `RenderGhostTile(x,y,z)` if valid, `RenderGhostTileRed(x,y,z)` if invalid.

### renderOpaqueObjectsInWorld(x, y, z, square)
Optional override. Called via `Events.RenderOpaqueObjectsInWorld` to draw non-transparent preview elements.

### DoTileBuilding Loop (Mouse)
Called every frame by Java while a building cursor is active:
1. Track mouse button state (`isLeftDown`)
2. On left-click hold: call `rotateMouse()` for drag-to-rotate
3. On release: set `build = true` if `canBeBuild`
4. Call `getSprite()`, then `isValid(square)` to update `canBeBuild`
5. Call `render()` to draw ghost
6. If `canBeBuild and build`: call `tryBuild()`

## 5. Placement Validation

### isValid(square) -> boolean
Base implementation checks:
1. `self.notExterior` - reject non-exterior squares
2. `self:haveMaterial(square)` - player has required materials
3. `square:isVehicleIntersecting()` - no vehicles overlapping
4. `self.canBeAlwaysPlaced` - skip further checks, only reject duplicate sprites
5. `buildUtil.canBePlace(self, square)` - utility placement rules
6. `square:isFreeOrMidair(blockedByCharacters)` - square is free

Subclasses override with additional checks:

| Type | Extra Validation |
|-|-|
| ISWoodenWall | SafeHouse check, buildUtil.canBePlace, stair blocking |
| ISWoodenFloor | No stairs below, no farming plots, no duplicate floor, connectedWithFloor |
| ISWoodenDoor | Must have door frame with matching north, no existing door |
| ISWoodenDoorFrame | buildUtil.canBePlace, stair blocking, hasFloor |
| ISWoodenStairs | Free adjacent squares for 3-tile span, hasFloor at base |
| ISSimpleFurniture | buildUtil.canBePlace, optional needToBeAgainstWall, stair blocking |
| ISWoodenContainer | Stair blocking, stackable check via ISMoveableSpriteProps |
| ISBarbedWire | No existing barbed wire on square |
| ISDoubleDoor | All 4 tiles valid, door frame checks |

## 6. Material Requirements

Materials are tracked in `self.modData` with string keys:

| Key Format | Value | Purpose |
|-|-|-|
| `need:Base.Plank` | "4" | Requires 4 planks (consumed) |
| `need:Base.Nails` | "2" | Requires 2 nails (NailsBox = 100 nails) |
| `use:Base.BlowTorch` | "5" | Requires 5 uses from blow torch (drainable) |

### haveMaterial(square) -> boolean
Checks player inventory AND ground items at the build square:
1. Iterates `modData` entries starting with `"need:"` - counts items in inventory + ground
2. Special case: `Base.Nails` also counts `Base.NailsBox * 100`
3. Iterates `"use:"` entries - counts total uses from drainable items
4. Checks for hammer (unless `self.noNeedHammer` or cheat mode)

### buildUtil.consumeMaterial(self)
Called inside `create()` to actually remove materials. Returns list of consumed items.

### buildUtil.setInfo(javaObject, self)
Copies building properties to the Java IsoThumpable: name, thumpDmg, isDoor, isDoorFrame, isContainer, canBarricade, dismantable, canBePlastered, hoppable, crossSpeed, blockAllTheSquare, isThumpable, modData.

## 7. Build Action Integration

### tryBuild(x, y, z)
Called when placement is confirmed. Full flow:

1. **Create ISBuildAction** with calculated `maxTime`:
   - Base: `200 - (carpentryLevel * 5)`
   - Override: `self.maxTime` if set
   - Instant if `playerObj:isTimedActionInstant()`
2. **Build panel integration**: if `self.buildPanelLogic`, hook onComplete/onCancel callbacks
3. **Walk to target**: `self:walkTo(x, y, z)` or skip if cheat/skip flags
4. **Equip hammer**: auto-equip from inventory (unless `noNeedHammer`)
5. **Equip primary/secondary items**: `self.firstItem`, `self.secondItem`
6. **Queue action**: `ISTimedActionQueue.add(buildAction)`

### walkTo(x, y, z)
Default behavior:
- `self.isWallLike` - use `luautils.walkAdjWall(player, square, north)`
- `ISWoodenFloor` on collide edge - try walkAdj then walkAdjWall
- `self.currentMoveProps` - entity-based adjacency
- Default: `luautils.walkAdj(player, square)`

### onTimedActionStart(action)
Default selects animation based on:
- `self.actionAnim` if set
- `"BlowTorch"` / `"BlowTorchFloor"` if firstItem is blow torch
- `CharacterActionAnims.BuildLow` if `self.buildLow`
- `CharacterActionAnims.Build` otherwise

### Health Calculation
Each type has a `getHealth()` method. Pattern: `baseHP + buildUtil.getWoodHealth(self)` where `getWoodHealth` scales with carpentry level (100 per level).

| Type | Base HP | Formula |
|-|-|-|
| ISWoodenWall | 200 | 200 + carpentry * 100 (log walls: 400 + ...) |
| ISWoodenDoor | 300 | 300 + carpentry * 100 |
| ISWoodenDoorFrame | 300 | 300 + carpentry * 100 |
| ISWoodenContainer | 200 | 200 + carpentry * 100 |
| ISSimpleFurniture | 100 | 100 + carpentry * 100 |
| ISCompost | 100 | 100 + carpentry * 100 |
| ISWoodenStairs | 500 | 500 + carpentry * 100 |
| ISBarbedWire | 100 | Fixed 100 |
| ISBuildIsoEntity | varies | Script-defined or skillBaseHealth + carpentry * 100 |

## 8. All Building Object Types

All in `media/lua/server/BuildingObjects/`:

### Structural Objects

| Class | File | Purpose |
|-|-|-|
| ISWoodenWall | ISWoodenWall.lua | Walls (plank, log). Barricadable, auto-corners. |
| ISWoodenFloor | ISWoodenFloor.lua | Floor tiles. Disables erosion. |
| ISWoodenStairs | ISWoodenStairs.lua | 3-tile stairs with pillar sprites. |
| ISWoodenDoor | ISWoodenDoor.lua | Doors with open/close sprites. Key support. |
| ISWoodenDoorFrame | ISWoodenDoorFrame.lua | Door frames. Required before placing doors. |
| ISDoubleDoor | ISDoubleDoor.lua | 4-tile double doors/gates (wood and metal). |
| ISBarbedWire | ISBarbedWire.lua | Barbed wire fences. Hoppable. |
| ISNaturalFloor | ISNaturalFloor.lua | Poured dirt/gravel floors from bags. |

### Furniture and Containers

| Class | File | Purpose |
|-|-|-|
| ISSimpleFurniture | ISSimpleFurniture.lua | Generic furniture. Optional wall-adjacent. |
| ISDoubleTileFurniture | ISDoubleTileFurniture.lua | Two-tile furniture (beds, tables). |
| ISWoodenContainer | ISWoodenContainer.lua | Storage crates. Stackable. Padlock support. |
| ISLightSource | ISLightSource.lua | Torch/lamp with radius, fuel, offset. |
| ISCompost | ISCompost.lua | Compost bins (IsoCompost Java object). |
| ISButcheringHook | ISButcheringHook.lua | Butchering hook (IsoButcherHook). |
| ISHutch | ISHutch.lua | Animal hutch/coop (IsoHutch). |

### Entity-Based Building

| Class | File | Purpose |
|-|-|-|
| ISBuildIsoEntity | ISBuildIsoEntity.lua | Build from EntityScript + SpriteConfig components. B42 system. |

### Cursor Objects (not ISBuildingObject subclasses)
Specialized cursors for non-construction interactions. All in the same directory.

ISBuildCursorMouse, ISSelectCursor, ISChopTreeCursor, ISDestroyCursor, ISMoveableCursor, ISPaintCursor, ISPaperCursor, ISCleanBloodCursor, ISCleanGraffitiCursor, ISRemovePlantCursor, ISShovelGroundCursor, ISBuildRampCursor, ISBrushToolTileCursor, ISPickCharacterCursor, ISAnimalPickMateCursor, ISWalkToCursor, ISPlace3DItemCursor, PaintingReference.

### Build Menus (ISUI)

| File | Path | Purpose |
|-|-|-|
| ISBuildMenu.lua | client/BuildingObjects/ISUI/ | Build menu categories and recipes |
| ISInventoryBuildMenu.lua | client/BuildingObjects/ISUI/ | Inventory-driven build menu |

### Build Utilities

| File | Purpose |
|-|-|
| ISBuildUtil.lua | Shared helpers: canBePlace, consumeMaterial, getWoodHealth, stairIsBlockingPlacement, checkCorner, getMaterialOnGround |

## 9. Custom Building Object Pattern

```lua
require "BuildingObjects/ISBuildingObject"

ISMyObject = ISBuildingObject:derive("ISMyObject")

function ISMyObject:create(x, y, z, north, sprite)
    local cell = getWorld():getCell()
    local sq = cell:getGridSquare(x, y, z)

    -- Create the Java object
    self.javaObject = IsoThumpable.new(cell, sq, sprite, north, self)

    -- Apply standard properties from init flags
    buildUtil.setInfo(self.javaObject, self)

    -- Consume materials from player inventory
    buildUtil.consumeMaterial(self)

    -- Set health
    self.javaObject:setMaxHealth(self:getHealth())
    self.javaObject:setHealth(self.javaObject:getMaxHealth())

    -- Set break sound
    self.javaObject:setBreakSound("BreakObject")

    -- Add to the world
    sq:AddSpecialObject(self.javaObject)

    -- Sync to clients (multiplayer)
    self.javaObject:transmitCompleteItemToClients()
end

function ISMyObject:new(sprite, northSprite)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    o:setSprite(sprite)
    o:setNorthSprite(northSprite)
    o.name = "My Object"
    o.canBarricade = false
    o.dismantable = true
    o.isWallLike = false
    o.blockAllTheSquare = true
    -- Material requirements
    o.modData["need:Base.Plank"] = "4"
    o.modData["need:Base.Nails"] = "2"
    return o
end

function ISMyObject:getHealth()
    return 200 + buildUtil.getWoodHealth(self)
end

function ISMyObject:isValid(square)
    if not self:haveMaterial(square) then return false end
    if not buildUtil.canBePlace(self, square) then return false end
    if buildUtil.stairIsBlockingPlacement(square, true) then return false end
    return square:isFreeOrMidair(true)
end

function ISMyObject:render(x, y, z, square)
    ISBuildingObject.render(self, x, y, z, square)
end
```

### Adding to Build Menu
Objects are registered through `ISBuildMenu.lua` which creates them and sets them as the cell drag:
```lua
-- In your build menu hook or recipe:
local obj = ISMyObject:new("mymod_sprite_0", "mymod_sprite_1")
obj.modData["need:Base.Plank"] = "4"
obj.modData["need:Base.Nails"] = "2"
obj.player = playerNum
obj.character = getSpecificPlayer(playerNum)
getCell():setDrag(obj, playerNum)
```

### Multi-tile Objects
For objects spanning multiple tiles (like stairs or double doors):
1. In `create()`, call helper methods for each additional tile
2. Each tile gets its own `IsoThumpable` with its own sprite
3. Use offset coordinates based on `north` flag
4. Only consume materials once (on the primary tile)

### Key Java Types Used in create()
| Java Type | Usage |
|-|-|
| IsoThumpable | Standard player-built object (walls, doors, furniture) |
| IsoCompost | Compost bin with decay mechanics |
| IsoHutch | Animal hutch with capacity |
| IsoButcherHook | Butchering station |
| IsoGridSquare | World tile reference |
