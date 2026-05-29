# Script Parsing System - PZ Data Map
Source: projectzomboid.jar (decompiled) | zombie.scripting.* | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture Overview | 16-50 |
| 2 | ScriptManager | 51-126 |
| 3 | ScriptParser | 127-197 |
| 4 | ScriptModule | 198-239 |
| 5 | ScriptType Registry | 240-284 |
| 6 | ScriptItem (Item Class) | 285-340 |
| 7 | Mod Override and Loading Order | 341-396 |
| 8 | Lua Access to Script Data | 397-443 |

## 1. Architecture Overview

PZ's scripting system parses `.txt` definition files from `media/scripts/` into typed
script objects. This is NOT a Lua scripting system - it's a custom data definition language.

```
.txt files on disk
     |
     v
ScriptManager.Load()
     |
     v  (for each file)
ScriptParser.stripComments() -> parseTokens() -> parse()
     |
     v
ScriptManager.CreateFromToken()
     |
     v  (identifies "module <Name> { ... }")
ScriptModule.Load()
     |
     v  (for each block inside module)
ScriptBucket.loadObject()  -- routes by block type tag
     |
     v
BaseScriptObject.Load(name, body)  -- type-specific parsing
```

**Key classes:**
- `ScriptManager` - singleton, orchestrates loading, provides lookup API
- `ScriptParser` - stateless parser, tokenizer, comment stripper
- `ScriptModule` - named container (Base, farming, etc.) holding ScriptBuckets
- `ScriptBucket<T>` - typed collection per ScriptType within a module
- `ScriptBucketCollection<T>` - cross-module collection at ScriptManager level
- `BaseScriptObject` - abstract base for all parsed script objects

## 2. ScriptManager

`zombie.scripting.ScriptManager` - singleton, entry point for all script operations.

**File:** `decompiled/zombie/scripting/ScriptManager.java`

### Initialization: ScriptManager.Load()

Called once at game startup. Steps:

1. **Discover game files:** `searchFolders()` recursively finds all `.txt` files under
   `media/scripts/` from the game install
2. **Discover mod files:** For each active mod, searches `common/media/scripts/` and
   `<version>/media/scripts/` directories
3. **Map files to mod IDs:** `tempFileToModMap` tracks which mod each file belongs to.
   Vanilla files get `"pz-vanilla"` as their mod ID
4. **Sort files:** Template files (`template_*`) sort before all others, ensuring templates
   are parsed before entities that reference them
5. **Combine lists:** Game files first, then mod files (mods can override vanilla)
6. **Load each file:** `LoadFile()` for each `.txt` file:
   - Read file contents into StringBuilder
   - `ScriptParser.stripComments()` removes `/* ... */` blocks
   - `ParseScript()` tokenizes and routes to modules
7. **Post-load processing:**
   - `loadScripts(Init, allTypes)` calls `OnScriptsLoaded` on every script object
   - `WorldDictionary.ScriptsLoaded()` finalizes registry IDs
   - `RecipeManager.ScriptsLoaded()` indexes recipes
   - Translation keys validated, clothing maps built

### File Loading: LoadFile()

```java
public void LoadFile(ScriptLoadMode loadMode, String filename, boolean bLoadJar)
```

- Skips `.tmx` files (map data, just records mapPath)
- Rejects non-`.txt` files
- Reads via `IndieFileLoader.getStreamReader()` (supports both filesystem and JAR)
- Sets `currentFileName` for error reporting, `currentLoadFileMod` for mod tracking
- Calls `ParseScript()` with the full file content

### Token Routing: CreateFromToken()

Identifies the outer `module <Name> { ... }` wrapper:
1. Extracts module name
2. Creates `ScriptModule` if new, registers with all `ScriptBucketCollection`s
3. Calls `ScriptModule.Load(loadMode, name, body)` with the inner content

### Lookup API

| Method | Returns | Lookup Key Format |
|-|-|-|
| getItem(name) | Item | "Module.ItemName" or "ItemName" |
| FindItem(name) | Item | Searches module, falls back to Base |
| getGameEntityScript(name) | GameEntityScript | "Module.EntityName" |
| getGameEntityTemplate(name) | GameEntityTemplate | "Module.TemplateName" |
| getRecipe(name) | Recipe | "Module.RecipeName" |
| getModule(name) | ScriptModule | Module name string |
| getAllItems() | ArrayList<Item> | - |
| getItemsTag(tag) | ArrayList<Item> | ItemTag enum |
| getItemsByType(type) | ArrayList<Item> | Item type string |
| getScriptsForType(type) | ArrayList<?> | ScriptType enum |

### Reload System

```java
public void ReloadScripts(EnumSet<ScriptType> types)
```

During reload:
1. `PreReloadScripts()` on affected buckets (clears component scripts)
2. Re-reads all `.txt` files from the stored `loadFileNames` list
3. `LoadScripts(Reload)` re-processes affected types
4. Script objects with `ResetExisting` flag get their fields cleared first
5. Objects with `NewInstanceOnReload` flag get fresh instances instead

## 3. ScriptParser

`zombie.scripting.ScriptParser` - stateless parser for the PZ script format.

**File:** `decompiled/zombie/scripting/ScriptParser.java`

### Comment Stripping

`stripComments(String)` removes all `/* ... */` blocks, handling nested comments.

### Tokenization

`parseTokens(String)` splits the content into balanced-brace tokens. Each token is a
top-level `{ ... }` block with its preceding keyword. Result: list of module-level tokens.

### Block Parsing

`parse(String)` builds a tree of `Block` and `Value` nodes:

```
Block
  .type     = "entity"      (first whitespace-delimited word before {)
  .id       = "WoodenWall"  (second word before {, if present)
  .children = [Block, ...]  (nested { } blocks)
  .values   = [Value, ...]  (comma-delimited values)
  .elements = [BlockElement, ...]  (children + values in order)
```

```
Value
  .string = "health = 450"  (raw text between commas)
  .getKey()   -> "health"   (text before first '=')
  .getValue() -> " 450"     (text after first '=')
```

### Parsing Rules

- `{` opens a child Block
- `}` closes current Block
- `,` terminates a Value
- Whitespace between `{` and preceding text becomes the Block's type/id
- Values missing `=` are still valid (key-only)
- No string quoting rules - everything between delimiters is literal text
- No escape sequences

### Example Parse Tree

Input:
```
component SpriteConfig
{
    health = 450,
    face W
    {
        layer
        {
            row = walls_01_44,
        }
    }
}
```

Produces:
```
Block(type="component", id="SpriteConfig")
  Value("health = 450")
  Block(type="face", id="W")
    Block(type="layer", id=null)
      Value("row = walls_01_44")
```

## 4. ScriptModule

`zombie.scripting.objects.ScriptModule` - named container for script objects.

**File:** `decompiled/zombie/scripting/objects/ScriptModule.java`

### Fields

| Field | Type | Purpose |
|-|-|-|
| name | String | Module name (e.g., "Base", "farming") |
| imports | ArrayList<String> | Other modules this one imports |
| disabled | boolean | Module disabled (mod unloaded) |
| scriptBucketList | ArrayList<ScriptBucket> | All buckets in order |
| scriptBucketMap | HashMap<ScriptType, ScriptBucket> | Lookup by type |

### ScriptBuckets (one per ScriptType)

Each module contains typed buckets for every `ScriptType`. Key buckets:

| Bucket | ScriptType | Contains |
|-|-|-|
| items | Item | Item definitions |
| entities | Entity | GameEntityScript definitions |
| entityTemplates | EntityTemplate | GameEntityTemplate definitions |
| recipes | Recipe | Recipe definitions |
| vehicles | Vehicle | VehicleScript definitions |
| models | Model | ModelScript definitions |
| gameSounds | Sound | GameSoundScript definitions |
| craftRecipes | CraftRecipe | Entity craft recipe definitions |
| fixings | Fixing | Item fixing definitions |
| evolvedRecipes | EvolvedRecipe | Evolved recipe definitions |
| fluidDefinitions | FluidDefinition | Fluid type definitions |
| energyDefinitions | EnergyDefinition | Energy type definitions |
| timedActions | TimedAction | Timed action definitions |

### Module.Load()

The module's `Load()` method iterates the body content and routes each block to the
matching `ScriptBucket` based on the block's type tag. Each `ScriptBucket` matches its
`ScriptType.getScriptTag()` against the block keyword.

## 5. ScriptType Registry

`zombie.scripting.ScriptType` - enum of all parseable script block types.

**File:** `decompiled/zombie/scripting/ScriptType.java`

### All Script Types (35 total)

**Templates (loaded first):** VehicleTemplate (`vehicle`), EntityTemplate (`entity`)

**Dictionary-tracked (no new discovery on reload):** Item (`item`), Entity (`entity`)

**Core gameplay types:**
Recipe, UniqueRecipe, EvolvedRecipe, Fixing, CraftRecipe, TimedAction

**Asset types:**
AnimationMesh, Mannequin, Model, SpriteModel, Sound, SoundTimeline,
RuntimeAnimation, PhysicsShape, PhysicsHitReaction, Ragdoll, Clock

**Vehicle types:** Vehicle (NewInstanceOnReload), VehicleEngineRPM

**XUI types:** XuiLayout, XuiStyle, XuiDefaultStyle, XuiColor, XuiSkin (ResetOnceOnReload), XuiConfig

**Data types:** ItemConfig, ItemFilter, FluidFilter, FluidDefinition, EnergyDefinition, StringList

**Character types:** CharacterTraitDefinition, CharacterProfessionDefinition

**Internal:** EntityComponent (skipped in load order)

### Load Order Flags

| Flag | Purpose |
|-|-|
| Clear | Clear bucket before loading |
| CacheFullType | Cache "Module.Name" for fast lookup |
| ResetExisting | Reset script object fields on reload |
| RemoveLoadError | Remove objects that failed to load |
| SeekImports | Resolve cross-module imports |
| AllowNewScriptDiscoveryOnReload | Accept new objects during reload |
| ResetOnceOnReload | Reset only on first reload |
| NewInstanceOnReload | Create fresh instance instead of reusing |

Templates sort first in load order (comparator returns -1 for templates vs non-templates).
Within templates vs non-templates, alphabetical sort by type name.

## 6. ScriptItem (Item Class)

`zombie.scripting.objects.Item` - extends `GameEntityScript`, making every item definition
an entity script that can carry components.

**File:** `decompiled/zombie/scripting/objects/Item.java`

### Inheritance Chain

```
BaseScriptObject
  +-- GameEntityScript (ScriptType.Entity)
        +-- Item (ScriptType.Item)
```

This means items inherit entity component support. An item with `FluidContainer` or
`Durability` components defined in its script block will have those components instantiated
at runtime via `GameEntityFactory.CreateInventoryItemEntity()`.

### Key Item Fields (sampled)

| Field | Type | Default | Purpose |
|-|-|-|-|
| displayName | String | - | Translated item name |
| icon | String | "None" | Inventory icon |
| actualWeight | float | 1.0 | Base weight |
| weaponLength | float | 0.4 | Weapon reach |
| hidden | boolean | false | Hide from UI |
| medical | boolean | false | Medical item flag |
| cannedFood | boolean | false | Canned food flag |
| survivalGear | boolean | false | Survival gear flag |
| useWorldItem | boolean | false | Has world model |
| scaleWorldIcon | float | 1.0 | World icon scale |

### Item Type Subtypes

Items create different `InventoryItem` subclasses based on their `Type` field:

| Script Type | Runtime Class |
|-|-|
| Normal | InventoryItem |
| Food | Food |
| Weapon | HandWeapon |
| Clothing | Clothing |
| Container | InventoryContainer |
| Drainable | DrainableComboItem |
| Literature | Literature |
| Key | Key |
| Radio | Radio |
| Map | MapItem |
| Moveable | Moveable |
| AlarmClock | AlarmClock |
| WeaponPart | WeaponPart |
| Combo | ComboItem |
| Animal | AnimalInventoryItem |

## 7. Mod Override and Loading Order

### File Discovery Order

1. **Vanilla scripts:** `<PZ install>/media/scripts/` (recursively)
2. **Mod common scripts:** `<mod>/common/media/scripts/`
3. **Mod version scripts:** `<mod>/42/media/scripts/`

Within each group, files are sorted alphabetically with `template_*` files first.
Game files load before mod files, so mods always override vanilla.

### How Mods Override Script Definitions

Mod files are appended to the game file list. When a mod defines a `module Base` block
with an `item` or `entity` that has the same name as a vanilla definition:

**For dictionary-tracked types (Item, Entity):**
- `AllowNewScriptDiscoveryOnReload` is DISABLED
- Existing scripts get `ResetExisting` treatment - fields are cleared, then the new
  definition is loaded on top
- Registry IDs are preserved (WorldDictionary constraint)
- This means mods CAN override vanilla item/entity properties

**For non-dictionary types (Recipe, Sound, etc.):**
- `AllowNewScriptDiscoveryOnReload` is enabled
- New definitions are accepted alongside existing ones
- Mod recipes with the same name replace vanilla recipes

### Module System

If a mod creates a new module (e.g., `module MyMod`), it is isolated from Base.
To reference Base items from MyMod, use `imports` or fully qualified names (`Base.Plank`).

The `getModule(name, defaultToBase)` method resolves module names:
1. Check for exact module name match
2. Check `moduleAliases` map
3. If name contains `.`, extract prefix as module name
4. If `defaultToBase` is true and nothing found, return `Base` module

### Conflict Resolution

- Last-loaded file wins for same-name definitions within the same module
- Mod files always load after vanilla (guaranteed override)
- Template files always load before non-templates (guaranteed availability)
- `ScriptBucketCollection` handles cross-module deduplication via `hasFullType()` check
- `WorldDictionary` prevents registry ID conflicts - duplicate IDs throw RuntimeException

### Checksum Verification

On multiplayer, all loaded script files are checksummed:
```java
NetChecksum.checksummer.addFile(filename, absPath)
this.checksum = NetChecksum.checksummer.checksumToString()
```
Client and server checksums must match - mismatched mods cause connection failure.

## 8. Lua Access to Script Data

All `@UsedFromLua` methods are accessible from Lua via the Kahlua2 bridge.

### ScriptManager Access

```lua
local sm = ScriptManager.instance
sm:getItem("Base.Axe")                         -- Item by full type
sm:FindItem("Axe")                              -- defaults to Base module
sm:getAllItems()                                 -- ArrayList<Item>
sm:getGameEntityScript("Base.WoodenWallLvl1")   -- GameEntityScript
sm:getGameEntityTemplate("Base.ForgeTemplate")  -- GameEntityTemplate
sm:getRecipe("Base.MakeAxe")                    -- Recipe
sm:getModule("Base")                            -- ScriptModule
sm:getItemsTag(ItemTag.Hammer)                  -- items with tag
sm:getItemsByType("Weapon")                     -- items by type string
```

### Item/Entity Script Fields

```lua
local item = ScriptManager.instance:getItem("Base.Axe")
item:getDisplayName()           -- translated name
item:getScriptObjectFullType()  -- "Base.Axe"
item:getModID()                 -- "pz-vanilla" or mod ID
item.actualWeight               -- direct field access
```

### Runtime Entity Access

```lua
-- IsoObject and InventoryItem ARE GameEntity - direct component access
entity:hasComponent(ComponentType.FluidContainer)
entity:getFluidContainer()     -- FluidContainer component
entity:getSpriteConfig()       -- SpriteConfig component
entity:attrib()                -- AttributeContainer component
entity:getDurabilityComponent() -- Durability component
```

### GameEntityFactory

```lua
GameEntityFactory.AddComponent(entity, component)
GameEntityFactory.RemoveComponentType(entity, ComponentType.CraftBench)
GameEntityFactory.TransferComponents(source, target)
```
