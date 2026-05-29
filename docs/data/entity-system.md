# Entity Component System - PZ Data Map
Source: projectzomboid.jar (decompiled) | zombie.entity.* | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture Overview | 16-50 |
| 2 | GameEntity Base Class | 51-104 |
| 3 | ComponentType Registry | 105-162 |
| 4 | Component Base Class | 163-213 |
| 5 | Engine and Systems | 214-281 |
| 6 | Entity Lifecycle | 282-364 |
| 7 | Family and Bucket System | 365-406 |
| 8 | Component Catalog | 407-430 |

## 1. Architecture Overview

Build 42 uses a full Entity Component System (ECS). The architecture:

```
GameEntityManager (singleton)
  |
  +-- Engine
  |     +-- SystemManager -> [EngineSystem, EngineSystem, ...]
  |     +-- EngineEntityManager -> EntityBucketManager
  |                                  +-- EntityBucket (per Family)
  |                                  +-- EntityBucket (custom)
  |
  +-- EntitySimulation (fixed-timestep ticker, 100ms/tick)
  |
  +-- idToEntityMap (LongMap<GameEntity>)
```

**Key design choices:**
- Components are typed by a closed enum (`ComponentType`), not open registration
- Maximum 127 components per entity (stored in `ComponentContainer`)
- Components have both runtime classes and script classes (parallel hierarchies)
- Entities are grouped into `EntityBucket`s matched by `Family` bit patterns
- Systems run in priority order: update, simulation, render

**Package layout:**
- `zombie.entity` - core ECS framework (Engine, GameEntity, Component, etc.)
- `zombie.entity.components.*` - runtime component implementations
- `zombie.entity.events` - event types for inter-component communication
- `zombie.entity.system` - built-in EngineSystem subclasses
- `zombie.entity.meta` - MetaEntity for off-screen persistence
- `zombie.entity.network` - packet types for multiplayer sync
- `zombie.entity.energy` - energy system (fuel, electricity)
- `zombie.entity.util` - BitSet, ImmutableArray, LongMap utilities

## 2. GameEntity Base Class

`zombie.entity.GameEntity` - abstract base for all ECS-enabled objects.

**File:** `decompiled/zombie/entity/GameEntity.java`

### Key Fields

| Field | Type | Purpose |
|-|-|-|
| components | ComponentContainer | Holds all attached components |
| addedToWorldOrEquipped | boolean | In-world or equipped state |
| addedToEntityManager | boolean | Registered with GameEntityManager |
| addedToEngine | boolean | Registered with Engine |
| removingFromEngine | boolean | In removal process |
| scheduledForEngineRemoval | boolean | Queued for engine removal |
| scheduledForBucketUpdate | boolean | Queued for bucket re-evaluation |
| usingPlayer | IsoPlayer | Player currently interacting |

### Key Abstract Methods

| Method | Returns | Implemented By |
|-|-|-|
| getGameEntityType() | GameEntityType | IsoObject, InventoryItem, VehiclePart |
| getSquare() | IsoGridSquare | World position grid cell |
| getEntityNetID() | long | Network identity |
| getX/Y/Z() | float | World coordinates |
| isEntityValid() | boolean | Validity check |

### Concrete Subtype Chain

```
GameEntity (abstract)
  +-- IsoObject           (GameEntityType.IsoObject)
  |     +-- IsoFeedingTrough, etc.
  +-- InventoryItem       (GameEntityType.InventoryItem)
  |     +-- Food, HandWeapon, Clothing, etc.
  +-- VehiclePart         (GameEntityType.VehiclePart)
  +-- MetaEntity          (GameEntityType.MetaEntity)
```

`Item` (script class) extends `GameEntityScript`, meaning every item definition IS an
entity script. Item scripts can have components (Durability, FluidContainer, etc.).

### Convenience Accessors

```java
entity.attrib()                // -> AttributeContainer component
entity.getFluidContainer()     // -> FluidContainer component
entity.getDurabilityComponent() // -> Durability component
entity.getSpriteConfig()       // -> SpriteConfig component
entity.getEntityScript()       // -> GameEntityScript via Script component
```

## 3. ComponentType Registry

`zombie.entity.ComponentType` - enum defining all valid component types.

**File:** `decompiled/zombie/entity/ComponentType.java`

### Registered Types

| Enum Name | ID | Runtime Class | Script Class | Flags |
|-|-|-|-|-|
| Attributes | 1 | AttributeContainer | AttributesScript | 0 |
| FluidContainer | 2 | FluidContainer | FluidContainerScript | 2 (RunInMeta) |
| SpriteConfig | 3 | SpriteConfig | SpriteConfigScript | 0 |
| Lua | 6 | LuaComponent | LuaComponentScript | 0 |
| Parts | 7 | Parts | PartsScript | 0 |
| Signals | 8 | Signals | SignalsScript | 0 |
| Script | 9 | EntityScriptInfo | null | 0 |
| UiConfig | 11 | UiConfig | UiConfigScript | 0 |
| CraftLogic | 12 | CraftLogic | CraftLogicScript | 3 (AddToEngine+RunInMeta) |
| FurnaceLogic | 13 | FurnaceLogic | FurnaceLogicScript | 3 |
| TestComponent | 14 | TestComponent | TestComponentScript | 0 |
| MashingLogic | 15 | MashingLogic | MashingLogicScript | 3 |
| DryingLogic | 16 | DryingLogic | DryingLogicScript | 3 |
| MetaTag | 17 | MetaTagComponent | null | 0 |
| Resources | 18 | Resources | ResourcesScript | 3 |
| CraftBench | 19 | CraftBench | CraftBenchScript | 0 |
| CraftRecipe | 20 | CraftRecipeComponent | CraftRecipeComponentScript | 0 |
| Durability | 21 | Durability | DurabilityScript | 0 |
| DryingCraftLogic | 22 | DryingCraftLogic | DryingCraftLogicScript | 3 |
| ContextMenuConfig | 23 | ContextMenuConfig | ContextMenuConfigScript | 0 |
| SpriteOverlayConfig | 24 | SpriteOverlayConfig | SpriteOverlayConfigScript | 0 |
| CraftBenchSounds | 25 | CraftBenchSounds | CraftBenchSoundsScript | 0 |
| WallCoveringConfig | 26 | WallCoveringConfig | WallCoveringConfigScript | 0 |
| Undefined | 0 | null | null | 0 |

### Flag Bits

| Bit | Name | Meaning |
|-|-|-|
| 1 | AddToEngine | Component triggers entity addition to Engine buckets |
| 2 | RunInMeta | Component stays active in MetaEntity (off-screen) |
| 4 | RenderLast | Component participates in late render pass |

### Entity Type Restrictions

Some components restrict which `GameEntityType` can own them:
- `FluidContainer`, `SpriteConfig`: IsoObject, MetaEntity only
- `CraftLogic`, `FurnaceLogic`, `MashingLogic`, `DryingLogic`: IsoObject, MetaEntity only
- `Resources`, `DryingCraftLogic`, `SpriteOverlayConfig`: IsoObject, MetaEntity only
- `MetaTag`: IsoObject, MetaEntity only
- All others: valid for any entity type

### Component Factory

`ComponentType.CreateComponent()` uses `ComponentFactory` (object pool pattern).
`ComponentType.ReleaseComponent()` returns components to the pool.
`ComponentType.CreateComponentFromScript()` creates + calls `readFromScript()`.

## 4. Component Base Class

`zombie.entity.Component` - abstract base for all components.

**File:** `decompiled/zombie/entity/Component.java`

### Lifecycle Hooks

| Method | When Called | Purpose |
|-|-|-|
| readFromScript(T script) | Factory creation from script | Load script data into runtime state |
| onAddedToOwner() | After addComponent() | Initialize, link to owner |
| onRemovedFromOwner() | After removeComponent() | Cleanup, unlink |
| onConnectComponents() | After all components added | Cross-component wiring |
| onFirstCreation() | New entity (not loaded from save) | One-time initialization |
| onComponentEvent(event) | Another component broadcasts | React to sibling events |
| onEntityEvent(event) | Entity broadcasts | React to entity-level events |
| reset() | Entity being recycled | Clear all state |

### Event System

Components communicate via two event channels:

**ComponentEvent** (`ComponentEventType`):
- `OnContentsChanged` - fluid/inventory contents modified

**EntityEvent** (`EntityEventType`):
- `AddedToWorld` - entity placed in the world

Events are pooled objects (`Alloc`/`release` pattern). When a component sends an event,
all sibling components (except the sender) receive it.

### Serialization

| Method | Purpose |
|-|-|
| save(ByteBuffer) | Persist to world save |
| load(ByteBuffer, worldVersion) | Restore from save |
| saveSyncData(ByteBuffer) | Multiplayer state sync (server -> client) |
| loadSyncData(ByteBuffer) | Receive multiplayer sync |

Save format: each entity writes component count, then for each component:
`[ByteBlock header] [componentTypeID: short] [component data] [ByteBlock end]`

### Network

Components can send packets via:
- `sendClientPacket(data)` - client to server
- `sendServerPacket(data, ignoreConn)` - server to all clients
- `sendServerPacketTo(player, data)` - server to specific client

## 5. Engine and Systems

### Engine

`zombie.entity.Engine` - processes all registered systems and manages entity buckets.

**File:** `decompiled/zombie/entity/Engine.java`

Three processing phases per frame, each iterating registered `EngineSystem` instances:

| Phase | Method | Systems Iterated |
|-|-|-|
| Update | engine.update() | All systems where `isUpdater() == true` |
| Simulation | engine.updateSimulation() | All systems where `isSimulationUpdater() == true` |
| Render | engine.renderLast() | All systems where `isRenderer() == true` |

### EngineSystem Base

`zombie.entity.EngineSystem` - abstract base for all systems.

| Constructor Param | Type | Purpose |
|-|-|-|
| updater | boolean | Runs during update phase |
| simulationUpdater | boolean | Runs during simulation phase |
| updatePriority | int | Lower = earlier execution |
| renderer | boolean | Runs during render phase |
| renderLastPriority | int | Render order priority |

### Registered Systems (initialization order)

Registered in `GameEntityManager.Init()`:

| Priority | System Class | Update | Sim | Render |
|-|-|-|-|-|
| 0 | UsingPlayerUpdateSystem | yes | - | - |
| 1 | InventoryItemSystem | yes | - | - |
| 2 | FluidContainerUpdateSystem | yes | - | - |
| 3 | LogisticsSystem | yes | - | - |
| 4 | CraftLogicSystem | yes | - | - |
| 5 | FurnaceLogicSystem | yes | - | - |
| 6 | MashingLogicSystem | yes | - | - |
| 7 | MetaEntitySystem | yes | - | - |
| 8 | ResourceUpdateSystem | yes | - | - |
| 0 | RenderLastSystem | - | - | yes |

### EntitySimulation

Fixed-timestep simulation running at 100ms per tick (10 ticks/second).
`getGameSecondsPerTick()` returns 2.4 (game time runs 24x faster than real time).
Simulation ticks are skipped on the client (server-authoritative).

```java
EntitySimulation.update()  // Called each frame
// Calculates how many 100ms ticks elapsed since last frame
// GameEntityManager runs engine.updateSimulation() that many times
```

### Update Loop

```
GameEntityManager.Update():
  1. engine.update()           // per-frame systems
  2. EntitySimulation.update() // calculate simulation ticks
  3. for each tick:
       engine.updateSimulation()  // fixed-step systems (server only)
  4. Release delayed MetaEntities
```

## 6. Entity Lifecycle

### Creation (from script)

```
GameEntityFactory.createEntity(entity, script):
  1. instanceComponents(entity, script)
     - For each ComponentScript in script:
       - componentType.CreateComponentFromScript(script)  // alloc + readFromScript
       - entity.addComponent(component)
     - SpriteConfig is added first for IsoObjects (multi-square master logic)
  2. Add EntityScriptInfo component (stores original script reference)
  3. entity.connectComponents()  // cross-wire
  4. entity.onFirstCreation()    // if new (not from save)
```

### World Entry

```
entity.addToWorld():
  1. GameEntityManager.RegisterEntity(this)
     - Add to idToEntityMap
     - If has AddToEngine components -> Engine.addEntity()
       - EntityBucketManager evaluates Family matches
       - Entity added to matching buckets
  2. addedToWorldOrEquipped = true
  3. sendEntityEvent(AddedToWorld)
```

### Save/Load

```
entity.saveEntity(output):
  1. Write component count (byte)
  2. For each component:
     - ByteBlock start
     - Write componentTypeID (short)
     - component.save(output)
     - ByteBlock end

entity.loadEntity(input, worldVersion):
  1. Read component count
  2. For each:
     - ByteBlock start
     - Read componentTypeID -> ComponentType
     - Get existing component or create new
     - component.load(input, worldVersion)
     - Add to entity if new
     - ByteBlock end (auto-skip on corruption)
  3. connectComponents()
```

### MetaEntity (off-screen persistence)

When an IsoObject's chunk is unloaded, entities with `RunInMeta` components (flag bit 2)
are converted to `MetaEntity` instances:

```
MetaEntity.alloc(entity):
  1. Pool allocation (object pooling via ConcurrentLinkedQueue)
  2. Copy position, entityNetId, entityType
  3. Transfer RunInMeta components from IsoObject to MetaEntity
  4. MetaEntity continues processing in MetaEntitySystem
```

When the chunk reloads, components transfer back to the IsoObject.
This keeps fluid containers, crafting logic, and resources ticking off-screen.

### Destruction

```
entity.removeFromWorld():
  1. GameEntityManager.UnregisterEntity(this)
     - Remove from Engine (deferred if processing)
     - Remove from idToEntityMap
  2. addedToWorldOrEquipped = false

entity.reset():
  1. Verify not in Engine or Manager
  2. Clear all flags
  3. Release ComponentContainer (returns components to pool)
```

## 7. Family and Bucket System

### Family

`zombie.entity.Family` - defines a component bit-pattern for entity grouping.

**File:** `decompiled/zombie/entity/Family.java`

Families use three bit sets to match entities:
- `all` - entity must have ALL of these component types
- `one` - entity must have at least ONE of these
- `exclude` - entity must have NONE of these

```java
Family craftFamily = Family.all(ComponentType.CraftLogic, ComponentType.CraftBench)
                           .exclude(ComponentType.TestComponent)
                           .get();
```

Families are cached by hash - identical queries return the same Family instance.

### EntityBucket

Entities are sorted into buckets by Family match. The `EntityBucketManager` maintains:

| Bucket | Purpose |
|-|-|
| IsoObjectBucket | All IsoObject-type entities |
| InventoryItemBucket | All InventoryItem-type entities |
| VehiclePartBucket | All VehiclePart-type entities |
| RendererBucket | Entities with RenderLast components |
| Custom buckets | Registered via `Engine.registerCustomBucket()` |

When an entity's components change, `scheduledForBucketUpdate` is set, and the
`EntityBucketManager` re-evaluates which buckets the entity belongs to.

### CustomBuckets

`CustomBuckets.initializeCustomBuckets(engine)` registers additional application-specific
buckets beyond the default type-based ones. Systems query buckets to get their working
set of entities.

## 8. Component Catalog

All runtime components live under `zombie.entity.components.*`:

| Package | Key Classes | Purpose |
|-|-|-|
| crafting | CraftBench, CraftLogic, CraftRecipeComponent | Recipe group binding, craft processing |
| crafting | FurnaceLogic, DryingLogic, MashingLogic | Specialized processing (heat, time, grinding) |
| crafting | CraftLogicSystem, FurnaceLogicSystem, etc. | EngineSystem tickers for each logic type |
| crafting.recipe | CraftRecipeManager, CraftRecipeData | Global recipe registry and data |
| fluids | FluidContainer, Fluid, FluidCategory | Fluid storage, types, rain collection |
| fluids | FluidContainerUpdateSystem | Ticks fluid containers |
| resources | Resources, ResourceEnergy/Fluid/Item | Resource channels (fuel, power, items) |
| resources | LogisticsSystem, ResourceUpdateSystem | Routes and ticks resources |
| attributes | AttributeContainer, Attribute, AttributeType | Generic key-value property bag |
| spriteconfig | SpriteConfig, SpriteOverlayConfig | Per-face sprites, overlays (paint/plaster) |
| ui | UiConfig | XUI skin, entity style, display name |
| combat | Durability, DurabilityScript | HP tracking and damage |
| parts | Parts | Multi-part entity config |
| signals | Signals | Event routing between components |
| lua | LuaComponent | Lua-scriptable component behavior |
| sounds | CraftBenchSounds | Workstation sound effects |
| contextmenuconfig | ContextMenuConfig | Custom right-click menu entries |
| script | EntityScriptInfo | Stores reference to originating GameEntityScript |
