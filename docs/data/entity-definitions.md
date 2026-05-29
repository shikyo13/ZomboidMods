# Entity Definitions - PZ Data Map
Source: media/scripts/entities/ | media/scripts/generated/entities/ | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Script File Layout | 16-52 |
| 2 | Entity Definition Format | 53-92 |
| 3 | Component Blocks in Scripts | 93-189 |
| 4 | Entity Categories and Counts | 190-223 |
| 5 | Key Properties by Component | 224-274 |
| 6 | Entity-to-IsoObject Mapping | 275-307 |
| 7 | Building/Construction Entities | 308-361 |
| 8 | XUI Skin Overlay Files | 362-382 |

## 1. Script File Layout

Entity definitions live in two parallel directory trees under `media/scripts/`:

```
media/scripts/
  entities/                    # XUI skin overrides (184 files)
    <category>/
      entity_<name>_xuiSkin.txt
  generated/                   # Core entity definitions
    entities/                  # (228 files)
      <category>/
        workstations/
          entity_<name>.txt
        craftRecipes/
          recipes_<name>.txt
```

All files are plain-text script files parsed by `ScriptParser`. They use PZ's custom
block-and-value format - NOT JSON, NOT Lua. The parser splits on `{`, `}`, and `,` delimiters.

Every file wraps content in a `module` block (almost always `Base`):

```
module Base
{
    entity <EntityName>
    {
        component <ComponentType>
        {
            key = value,
            ...
        }
    }
}
```

## 2. Entity Definition Format

An entity definition declares a named entity with one or more component blocks.

**Script tag:** `entity` (maps to `ScriptType.Entity`)
**Template tag:** `entity` used as template (maps to `ScriptType.EntityTemplate`)

### Parsed By

`GameEntityScript.Load()` parses the body via `ScriptParser.parse()`:
1. Strips comments (`/* ... */`)
2. Tokenizes into balanced-brace blocks
3. Processes `module <Name> { ... }` wrapper via `ScriptManager.CreateFromToken()`
4. Each `entity <Name> { ... }` block becomes a `GameEntityScript` stored in `ScriptModule.entities`

### Template Inheritance

Entities can inherit from templates via the `entitytemplate` key:

```
entity MyForge
{
    entitytemplate = ForgeTemplate,
    component CraftBench
    {
        Recipes = CustomRecipes,
    }
}
```

When parsed, `GameEntityScript.Load()` calls `copyFrom(templateScript)` to pull in all
component scripts from the template, then applies local overrides. Templates are loaded
before entities because the file sort puts `template_*` files first alphabetically.

### Registry System

Each entity gets a `registryId` (short) assigned by `WorldDictionary.onLoadEntity()`.
This ID is persistent across saves and used for network synchronization. Once set, the
registry ID cannot be changed - attempting to override throws a `RuntimeException`.

## 3. Component Blocks in Scripts

Each `component <Type>` block inside an entity maps to a `ComponentType` enum value.
The block ID must exactly match a `ComponentType` name (case-sensitive via `ComponentType.valueOf()`).

### Common Components in Entity Scripts

| Component | Script Class | Purpose |
|-|-|-|
| UiConfig | UiConfigScript | Display name, XUI skin, entity style, UI toggle |
| SpriteConfig | SpriteConfigScript | Sprites per face (N/S/E/W), health, logic class |
| CraftRecipe | CraftRecipeComponentScript | Build recipe: inputs, time, skill, XP award |
| CraftBench | CraftBenchScript | Workstation recipe group binding |
| FluidContainer | FluidContainerScript | Capacity, rain factor, fluid whitelist |
| CraftLogic | CraftLogicScript | Crafting station processing logic |
| FurnaceLogic | FurnaceLogicScript | Heat-based processing (forges, kilns) |
| DryingLogic | DryingLogicScript | Time-based drying (racks) |
| MashingLogic | MashingLogicScript | Mashing/grinding processing |
| DryingCraftLogic | DryingCraftLogicScript | Combined drying + craft logic |
| Resources | ResourcesScript | Resource I/O channels (fuel, energy) |
| Parts | PartsScript | Multi-part entity configuration |
| Signals | SignalsScript | Signal/event routing between components |
| Durability | DurabilityScript | HP and damage tracking for items |
| SpriteOverlayConfig | SpriteOverlayConfigScript | Overlay sprite layers (paint, plaster) |
| WallCoveringConfig | WallCoveringConfigScript | Wall covering/painting config |
| CraftBenchSounds | CraftBenchSoundsScript | Sound effects for craft benches |
| ContextMenuConfig | ContextMenuConfigScript | Custom right-click menu entries |
| Lua | LuaComponentScript | Lua-driven component behavior |

### UiConfig Block Example

```
component UiConfig
{
    xuiSkin = default,
    entityStyle = ES_Forge_I,
    uiEnabled = true,
}
```

### SpriteConfig Block Example

```
component SpriteConfig
{
    LogicClass = WoodenWall,
    health = 450,
    skillBaseHealth = 20,
    previousStage = WoodenWallFrame;MetalWallFrame,
    BreakSound = ZombieThumpWoodCollapse,
    isThumpable = false,
    face W
    {
        layer
        {
            row = walls_exterior_wooden_01_44,
        }
    }
    face N
    {
        layer
        {
            row = walls_exterior_wooden_01_45,
        }
    }
    corner = walls_exterior_wooden_01_27,
}
```

Faces define directional sprites. Each face can have multiple layers, each with a sprite row.
Multi-tile entities use multiple sprites in a single row (space-separated).

### CraftRecipe Block Example

```
component CraftRecipe
{
    timedAction = BuildWallHammer,
    time = 200,
    category = Carpentry,
    SkillRequired = Woodwork:2,
    xpAward = Woodwork:20,
    Tooltip = Tooltip_craft_NeedsWallframeDesc,
    Tags = AutoRotate,
    OnAddToMenu = woodenWallLvl1Test,
    inputs
    {
        item 1 tags[base:hammer] mode:keep flags[Prop1;MayDegradeVeryLight],
        item 2 [Base.Plank],
        item 4 [Base.Nails],
    }
}
```

Input syntax: `item <count> [<Module.Item>]` or `item <count> tags[<tag>]`
Flags: `mode:keep` (don't consume), `flags[Prop1;MayDegradeVeryLight;DontRecordInput]`

## 4. Entity Categories and Counts

### Generated Entities (media/scripts/generated/entities/)

| Category | Count | Typical Contents |
|-|-|-|
| walls | 66 | Wood/brick/metal/stone walls, doors, windows, floors, fences |
| furniture | 52 | Tables, chairs, shelves, crates, beds, bar elements |
| blacksmith | 28 | Forges, furnaces, grindstones, kilns, recipe files |
| outdoors | 24 | Skull poles, cairns, shelters, signs, stakes, lamps |
| agricultural | 17 | Cooking pits, drying racks, looms, mills, querns |
| animals | 10 | Butcher hooks, churns, hutches, troughs, spinning wheels |
| pottery | 9 | Hand press, kilns, pottery wheels, benches |
| appliances | 7 | Coffee machine, toaster, water dispenser, well |
| misc | 4 | Miscellaneous entities |
| barricades | 3 | Plank, metal bar, metal sheet barricades |
| fences_low | 3 | Low fence variants |
| stairs | 3 | Carpentry, log, welding stairs |
| admin | 1 | Piano |
| **Total** | **228** | |

### XUI Skin Files (media/scripts/entities/)

184 files across the same category structure. These define `xuiSkin` blocks that override
the UI appearance of entities defined in the generated scripts. They follow the same
module/entity format but contain `xuiSkin` blocks instead of `entity` blocks.

### Craft Recipe Files

Found inside category subdirectories under `craftRecipes/`:
- `blacksmith/craftRecipes/` - 15 recipe files (armor, tools, blades, cookware, etc.)
- `agricultural/craftRecipes/` - 2 recipe files (fiber, flax)
- `pottery/cratRecipes/` - 3 recipe files (handpress, kiln, pottery wheel)

## 5. Key Properties by Component

### SpriteConfig Properties

| Property | Type | Description |
|-|-|-|
| health | int | Base HP (e.g., 450 for wood wall lvl1, 150 for primitive forge) |
| skillBaseHealth | int | Bonus HP per skill level |
| LogicClass | String | Java logic class name (e.g., WoodenWall) |
| previousStage | String | Semicolon-separated predecessor entities for upgrades |
| BreakSound | String | Sound played when destroyed |
| isThumpable | boolean | Whether zombies can attack this entity |
| face [N/S/E/W] | block | Directional sprite configuration |
| corner | String | Corner sprite name |
| OnIsValid | String | Lua/Java callback for placement validation |
| OnCreate | String | Lua/Java callback on entity creation |

### FluidContainer Properties

| Property | Type | Description |
|-|-|-|
| ContainerName | String | Display name for the container |
| Capacity | float | Maximum fluid capacity (e.g., 10000.0 for well) |
| RainFactor | float | Rain collection multiplier (0.0-1.0) |
| FillsWithCleanWater | boolean | Whether rain water is clean |
| HiddenAmount | boolean | Hide fluid amount from UI |
| InitialPercentMin | float | Min initial fill (0.0-1.0) |
| InitialPercentMax | float | Max initial fill (0.0-1.0) |
| Fluids { fluid = Type:Amount } | block | Initial fluid contents |
| whitelist { fluid = Type } | block | Allowed fluid types |

### CraftBench Properties

| Property | Type | Description |
|-|-|-|
| Recipes | String | Recipe group name (e.g., PrimitiveForge, Kiln) |

### CraftRecipe Properties

| Property | Type | Description |
|-|-|-|
| timedAction | String | Timed action type (BuildWallHammer, Make_With_Brick_Low) |
| time | int | Action duration in ticks |
| category | String | Menu category (Carpentry, Barricades, Blacksmithing) |
| SkillRequired | String | Required skill:level |
| xpAward | String | XP granted on completion (Skill:Amount) |
| Tooltip | String | Translation key for tooltip |
| Tags | String | Comma-separated tags (AutoRotate) |
| OnAddToMenu | String | Lua callback for menu filtering |
| inputs { ... } | block | Required input items |

## 6. Entity-to-IsoObject Mapping

### How Script Definitions Become Runtime Objects

1. **Cell loading:** `GameEntityFactory.CreateIsoEntityFromCellLoading()` checks `IsoObject`
   properties for `EntityScript` flag or `IsMoveAble` + `CustomItem` properties
2. **Script lookup:** `ScriptManager.instance.getGameEntityScript(scriptKey)` finds the
   `GameEntityScript` by name
3. **Component instantiation:** `GameEntityFactory.instanceComponents()` iterates
   `script.getComponentScripts()` and calls `CreateComponentFromScript()` for each
4. **Script info:** An `EntityScriptInfo` component (type `Script`) is added to store the
   original script reference
5. **Connection:** `entity.connectComponents()` triggers `onConnectComponents()` on each component
6. **First creation:** If new (not loaded from save), `entity.onFirstCreation()` fires

### IsoObject Property Bridge

Map tiles reference entities via sprite properties:
- `EntityScript` flag - signals the tile has an entity script
- `EntityScriptName` property - the `Module.EntityName` key (e.g., `Base.WoodenWallLvl1`)
- `IsMoveAble` + `CustomItem` - alternative path for moveable furniture items

### Entity Type Hierarchy

| GameEntityType | ID | Concrete Class | Notes |
|-|-|-|-|
| IsoObject | 1 | IsoObject subclasses | World-placed objects |
| InventoryItem | 2 | InventoryItem subclasses | Carried items |
| VehiclePart | 3 | VehiclePart | Vehicle components |
| IsoMovingObject | 4 | IsoMovingObject | Moving entities |
| Template | 5 | - | Script templates only |
| MetaEntity | 5 | MetaEntity | Off-screen persistence |

## 7. Building/Construction Entities

### Wall Construction Chain

Walls follow a staged upgrade path tracked by `previousStage`:

```
WoodenPole -> WoodenWallFrame -> WoodenWallLvl1 -> WoodenWallLvl2 -> WoodenWallLvl3
                              -> MetalWallFrame  -> MetalWallLvl1  -> MetalWallLvl2
```

Each stage is a separate entity definition. The `previousStage` property links back to
valid predecessor(s), separated by semicolons.

### Wall Entity Variants (66 total)

| Material | Walls | Doors | DoorFrames | WindowFrames | Floors | Fences |
|-|-|-|-|-|-|-|
| Wood | 3 lvl | 3 lvl | 3 lvl | 3 lvl | 3 lvl | 4 (+ barbed wire) |
| Metal | 2 lvl | 2 lvl | 2 lvl | 2 lvl | 1 | 5 + gates |
| Brick | 2 lvl | - | 2 lvl | 2 lvl | 1 | 1 |
| Stone | 1 | - | 1 | 1 | - | - |
| Log | 1 | - | 1 | 1 | - | - |

Special wall entities: `entity_woodenpole.txt`, `entity_woodenwallframe.txt`,
`entity_metal_wallframe.txt` - frame/pole stages.

Overlay entities: `paint_sign.txt`, `paint_wall.txt`, `paper_wall.txt`, `plaster_wall.txt` -
applied on top of existing walls using `SpriteOverlayConfig`.

### Furniture Construction (52 total)

Split between carpentry, log, rugged, stone, and welding tiers:

| Skill Tier | Prefix | Examples |
|-|-|-|
| Carpentry | entity_carpentry_ | Tables (3 lvl), chairs (3 lvl), shelves, crates, beds |
| Log | entity_log_ | Bench, stool, table |
| Rugged | entity_rugged_ | Bookcase, stool, table |
| Stone | entity_stone_ | Cabinet |
| Welding | entity_welding_ | Counters, lockers, crates, shelves, barrel oven |

### Workstation Entities

Workstations are entities with `CraftBench` and/or processing logic components:

| Category | Workstations |
|-|-|
| Blacksmithing | 3 forge tiers, 3 furnace tiers, grindstone, bandsaw, key duplicator |
| Agricultural | Cooking pits, drying racks, looms, mills, querns, heckle/ripple combs |
| Animals | Butcher hook, butter churn, chicken hutch, feeding trough, spinning wheel |
| Pottery | Hand press, 2 kilns, pottery wheels (manual + modern), bench |
| Appliances | Coffee machine, toaster, water dispenser, well |

## 8. XUI Skin Overlay Files

The 184 files in `media/scripts/entities/` define XUI skin configurations as separate
script objects. They use the `xuiSkin` script type and reference the same entity names:

```
module Base
{
    xuiSkin ES_Forge_I
    {
        /* XUI layout and style overrides */
    }
}
```

These are loaded alongside entity definitions and linked via the `entityStyle` value in
`UiConfig` component blocks. The `xuiSkin` maps to `ScriptType.XuiSkin` and is processed
by the XUI subsystem for rendering entity interaction UIs (workstation interfaces, etc.).

Categories mirror the generated entity categories: admin, agricultural, animals, appliances,
barricades, blacksmith, fences_low, furniture, misc, outdoors, stairs, walls.
