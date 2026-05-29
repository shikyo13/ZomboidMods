# Map & World Generation - PZ Data Map
Source: projectzomboid.jar (decompiled) | media/maps | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Spatial Hierarchy | 19-46 |
| 2 | Cell Grid System | 47-89 |
| 3 | Map File Format | 90-135 |
| 4 | World Provinces | 136-164 |
| 5 | Zone System | 165-212 |
| 6 | Room & Building Definitions | 213-255 |
| 7 | Loot Distribution | 256-308 |
| 8 | RandomizedWorld System | 309-389 |
| 9 | World Streaming | 390-414 |
| 10 | World Generation (B42) | 415-447 |
| 11 | Map Modding | 448-499 |

## 1. Spatial Hierarchy

The world is organized in a strict hierarchy of nested spatial units.

| Unit | Size | Contains | Java Class |
|-|-|-|-|
| MetaGrid | Entire world | Grid of MetaCells | `IsoMetaGrid` |
| MetaCell (Cell) | 256x256 squares | 32x32 chunks | `IsoMetaCell` |
| MetaChunk | 8x8 squares | Zone/room metadata | `IsoMetaChunk` |
| Chunk | 8x8 squares | Up to 64 levels | `IsoChunk` |
| ChunkLevel | 8x8 squares, 1 level | 64 grid squares | `IsoChunkLevel` |
| GridSquare | 1x1 tile | Objects on one Z-level | `IsoGridSquare` |

Key constants from `IsoChunkMap` and `IsoCell`:
- `CELL_SIZE_IN_CHUNKS = 32` - chunks per cell side
- `CELL_SIZE_IN_SQUARES = 256` - tiles per cell side
- `CHUNK_SIZE_IN_SQUARES = 8` - tiles per chunk side
- `LEVELS = 64` - total Z-levels per chunk
- `GROUND_LEVEL = 32` - ground floor index (Z=0 maps to index 32)
- `TOP_LEVEL = 31` - max floors above ground
- `BOTTOM_LEVEL = -32` - max floors below ground (basements)

MetaChunks are metadata-only (1024 per cell = 32x32). Each stores:
- Zombie intensity byte (0-255)
- Zone array (map zones overlapping this 8x8 area)
- RoomDef array (rooms overlapping this 8x8 area)
- Per-chunk zombie constants: `zombiesMinPerChunk = 0.06f`, `zombiesFullPerChunk = 12.0f`

## 2. Cell Grid System

### Coordinate Mapping

World coordinates (tile X/Y) map to cells and chunks by integer division:

```
cellX = tileX / 256    (or tileX >> 8)
cellY = tileY / 256

chunkWorldX = tileX / 8    (or tileX >> 3)
chunkWorldY = tileY / 8

localChunkX = chunkWorldX - (cellX * 32)    -- 0..31 within cell
localChunkY = chunkWorldY - (cellY * 32)    -- 0..31 within cell
```

### MetaGrid Bounds
`IsoMetaGrid` tracks min/max cell coordinates. Grid is a 2D array `IsoMetaCell[][]`
indexed by `[cellX - minX][cellY - minY]`. The vanilla map spans cells
X=0..77, Y=0..62 (78 x 63 cells, roughly 19968 x 16128 tiles).

### Cell 300 System
`MapFiles` uses a secondary "cell300" grid for legacy/compatibility, dividing
world coordinates by 300 (not 256). Used by `LotHeader.getZombieIntensityForChunk()`
to look up zombie density from the underlying map data:
```
cell300X = floor((cellX * 256 + chunkX * 8) / 300.0)
cell300Y = floor((cellY * 256 + chunkY * 8) / 300.0)
```

### ChunkMap Per Player
Each player has an `IsoChunkMap` that loads a moving window of chunks around
them. The grid width defaults to `chunkGridWidth = 13` chunks (104 tiles),
loaded as a square centered on the player. `CHUNKS_PER_WIDTH = 8` controls the
old render distance. Chunks outside this window are candidates for unloading.

### World Generation Bounds
`WorldGenParams` defines procedural generation extents:
- `minXCell = -250`, `maxXCell = 250`
- `minYCell = -250`, `maxYCell = 250`
- Seed-based RNG: `getRandom(wx, wy)` produces deterministic Random per chunk

## 3. Map File Format

Each cell has three companion files on disk:

| File Pattern | Purpose | Format |
|-|-|-|
| `{cellX}_{cellY}.lotheader` | Cell metadata header | Text: tile lists, levels, zombie intensity |
| `world_{cellX}_{cellY}.lotpack` | Tile/object data for all 1024 chunks | Binary (indexed by chunk) |
| `chunkdata_{cellX}_{cellY}.bin` | Zone, building, room definitions | Binary |

### LotHeader
Magic bytes: `LOTH` (76, 79, 84, 72). Fields:
- `cellX`, `cellY` - cell coordinates
- `width`, `height` - cell dimensions
- `minLevel`, `maxLevel` - Z-level range
- `tilesUsed` - list of tileset names referenced
- `zombieIntensity[1024]` - per-chunk density (32x32 = 1024 values)
- `adjacentCells[8]` - boolean array for neighbor presence
- `version` (0 or 1), `fixed2x` flag

### LotPack
Magic bytes: `LOTP` (76, 79, 84, 80). Indexed binary archive:
- Header: version int (if magic present)
- Index: 1024 entries x 8 bytes (file offset per chunk)
- Chunk data: per-square object lists, read via `IsoLot.load()`
- Square layout: iterates Z from minLevel to maxLevel, then X 0..7, Y 0..7
- `squareIndex = x + y * 8 + (z - minLevel) * 64`
- Empty runs encoded as count=-1 followed by skip count

### ChunkData (zones/rooms)
Contains serialized `Zone`, `BuildingDef`, `RoomDef` objects for the cell.
Read by `IsoMetaGrid` during cell loading. Zones are stored with string maps
for name/type deduplication. Version >= 215 uses UUID zone IDs.

### Additional Cell Files
| File | Purpose |
|-|-|
| `map.info` | Title, description, fixed2x flag, zoom settings |
| `objects.lua` | Zone definitions (Lua table) |
| `regions.lua` | Region definitions for named areas |
| `spawnpoints.lua` | Per-profession spawn coordinates |
| `roomtones.lua` | Ambient audio zones per building |
| `basements.lua` | Procedural basement definitions (from TileZed .pzby export) |
| `worldmap.xml` | World map rendering data |
| `maps/biomemap_X_Y.png` | Biome map images for world gen |

## 4. World Provinces

All vanilla map data lives under one map directory: `Muldraugh, KY`
(cell range X=0..77, Y=0..62). Other province folders (Riverside, Rosewood,
West Point, Echo Creek) contain only `map.info` + `spawnpoints.lua` and
reference the main map via `lots=Muldraugh, KY`.

### Region Definitions (from regions.lua)
Regions are defined as named rectangular areas in world-tile coordinates:

| Region | Approx Tile X | Approx Tile Y | Extent |
|-|-|-|-|
| Louisville | 11600-14600 | 1000-4000 | ~3000 x 3000 |
| Jefferson | 12200-16200 | 3000-7000 | ~4000 x 4000 |
| Riverside | 3500-7500 | 5100-6800 | ~4000 x 1700 |
| Muldraugh | 9000-12000 | 8500-12000 | ~3000 x 3500 |
| March Ridge | 9400-12400 | 12000-14000 | ~3000 x 2000 |
| Rosewood | 7500-9500 | 10000-12000 | ~2000 x 2000 |
| West Point | 10500-13000 | 5500-8000 | ~2500 x 2500 |
| Echo Creek | Ref: lots=Muldraugh, KY | - | Separate spawn area |

Echo Creek is B42's new province. Its `map.info` references `lots=Muldraugh, KY`,
meaning it shares the same cell/lotpack data but provides its own spawn points.

### Spawn Points
Defined per-profession in `spawnpoints.lua`. Each entry has `posX`, `posY`, `posZ`
in world-tile coordinates. Professions include: chef, constructionworker, doctor,
fireofficer, nurse, parkranger, policeofficer, repairman, securityguard, unemployed.

## 5. Zone System

Zones are named, typed rectangular (or polygonal) areas placed by map editors.
Class: `zombie.iso.zones.Zone`. Stored per-MetaChunk in `IsoMetaChunk.zones[]`.

### Zone Fields
| Field | Type | Description |
|-|-|-|
| `name` | String | Zone instance name (can be empty) |
| `type` | String | Zone type identifier |
| `x, y, z` | int | Origin in world-tile coords |
| `w, h` | int | Width/height in tiles |
| `geometryType` | enum | INVALID (rectangle), Polygon, Polyline |
| `points` | TIntArrayList | Polygon/polyline vertices |
| `polylineWidth` | int | Width for polyline zones |
| `hourLastSeen` | int | Last game-hour a player was in this zone |
| `haveConstruction` | boolean | Player-built structures present |
| `zombiesTypeToSpawn` | String | Specific zombie outfit/type |

### Zone Types (from objects.lua, by frequency)
| Type | Count | Purpose |
|-|-|-|
| Vegitation | 10804 | Natural vegetation areas |
| ParkingStall | 8061 | Vehicle spawn slots |
| Nav | 6928 | Navigation/road zones |
| TownZone | 3131 | Urban areas |
| Forest | 2937 | Forest biome |
| FarmLand | 1739 | Agricultural land |
| DeepForest | 1356 | Dense forest |
| ZombiesType | 1264 | Zombie outfit override (Restaurant, Factory, etc.) |
| WaterFlow | 810 | River/stream flow |
| Basement | 508 | Basement spawn areas |
| WorldGen | 369 | Procedural world generation hints |
| Ranch | 329 | Animal ranch zones |
| ZoneStory | 217 | RandomizedZoneStory spawn areas |
| Farm | 147 | Farm buildings |
| Mannequin | 142 | Mannequin display zones |
| Animal | 122 | Animal population zones |
| RoomTone | 109 | Ambient audio assignment |
| TrailerPark | 73 | Trailer park areas |
| LootZone | 35 | Special loot areas |
| SpawnPoint | 11 | Player spawn markers |
| WaterZone | 9 | Water body markers |

### Preferred Zone Types
The engine prioritizes certain zone types when determining a square's primary zone:
`DeepForest, Farm, FarmLand, Forest, Vegitation, Nav, TownZone, TrailerPark`

## 6. Room & Building Definitions

### BuildingDef (`zombie.iso.BuildingDef`)
Represents a complete building footprint. Fields:
| Field | Type | Description |
|-|-|-|
| `rooms` | ArrayList<RoomDef> | All rooms in the building |
| `emptyoutside` | ArrayList<RoomDef> | Exterior room defs |
| `x, y, x2, y2` | int | Bounding box in world-tile coords |
| `id` | long | Unique building ID |
| `zone` | Zone | Associated zone |
| `alarmed` | boolean | Has burglar alarm |
| `alarmDecay` | int | Alarm timer countdown |
| `seen` | boolean | Player has seen this building |
| `hasBeenVisited` | boolean | Player has entered |
| `stash` | String | Annotated map stash location |
| `lootRespawnHour` | int | Hour when loot last respawned (-1 = never) |
| `food` | int | Food item count |
| `keyId` | int | Random key ID (0-99999999) |
| `minLevel, maxLevel` | int | Computed from rooms |
| `collapseRectX/Y/X2/Y2` | int | Building collapse bounding box |

### RoomDef (`zombie.iso.RoomDef`)
Represents a single room within a building. Fields:
| Field | Type | Description |
|-|-|-|
| `name` | String | Room type name (kitchen, bedroom, bathroom, etc.) |
| `level` | int | Z-level of the room |
| `building` | BuildingDef | Parent building |
| `id` | long | Unique room ID |
| `rects` | ArrayList<RoomRect> | Rectangles composing the room shape |
| `objects` | ArrayList<MetaObject> | Containers/objects in the room |
| `area` | int | Total square count |
| `explored` | boolean | Player has entered |
| `doneSpawn` | boolean | Loot has been spawned |
| `indoorZombies` | int | Indoor zombie count |
| `spawnCount` | int | Zombie spawn target (-1 = default) |
| `proceduralSpawnedContainer` | HashMap | Tracks procedural loot per container type |

Room names determine which loot tables apply. Common names include:
bathroom, bedroom, closet, garage, kitchen, laundry, livingroom, office,
warehouse, shed, storeroom, classroom, medical, bar, restaurant, factory.

## 7. Loot Distribution

### System Overview
Loot spawns when a player first enters a room (`RoomDef.doneSpawn = false`).
The `ItemPickerJava` class drives all container filling.

### Three Distribution Tables
| Table | Lua Global | Java Map | Description |
|-|-|-|-|
| SuburbsDistributions | `SuburbsDistributions` | `ItemPickerJava.containers` | Room-type to container mappings |
| ProceduralDistributions | `ProceduralDistributions` | `ItemPickerJava.ProceduralDistributions` | Named loot lists (procedural) |
| VehicleDistributions | `VehicleDistributions` | `ItemPickerJava.VehicleDistributions` | Vehicle-specific loot |

### Loot Category Modifiers
Sandbox options apply per-category multipliers to spawn chances:

| Category | Modifier Field | Lua Type String |
|-|-|-|
| Food | `foodLootModifier` | Food |
| Canned Food | `cannedFoodLootModifier` | CannedFood |
| Weapons | `weaponLootModifier` | Weapon |
| Ranged Weapons | `rangedWeaponLootModifier` | RangedWeapon |
| Ammo | `ammoLootModifier` | Ammo |
| Literature | `literatureLootModifier` | Literature |
| Survival Gear | `survivalGearsLootModifier` | SurvivalGears |
| Medical | `medicalLootModifier` | Medical |
| Mechanics | `mechanicsLootModifier` | Mechanics |
| Clothing | `clothingLootModifier` | Clothing |
| Containers (bags) | `containerLootModifier` | Container |
| Keys | `keyLootModifier` | Key |
| Media | `mediaLootModifier` | Media |
| Mementos | `mementoLootModifier` | Memento |
| Cookware | `cookwareLootModifier` | Cookware |
| Materials | `materialLootModifier` | Material |
| Farming | `farmingLootModifier` | Farming |
| Tools | `toolLootModifier` | Tool |
| Skill Books | `skillBookLootModifier` | SkillBook |
| Recipe Resources | `recipeResourceLootModifier` | RecipeResource |

### Spawn Flow
1. Chunk loads, rooms resolve via `RoomDef.doneSpawn` check
2. `ItemPickerJava` looks up room name in `SuburbsDistributions`
3. Each container in the room matches a procedural distribution name
4. `ProceduralDistributions` table provides: rolls count, item list with weights
5. Per-item spawn chance multiplied by category modifier and sandbox rarity
6. `WeaponUpgrades` table can add attachments to spawned weapons
7. `NoContainerFillRooms` list skips certain room types entirely

### Loot Respawn
`BuildingDef.lootRespawnHour` tracks when loot was last refreshed. Controlled
by sandbox option `LootRespawn`. The `LootRespawn` class handles the timer and
re-triggers `ItemPickerJava` for containers in the building.

## 8. RandomizedWorld System

Story events are generated procedurally when chunks load. Four categories:

### RandomizedBuilding (34 stories)
Triggered per-building when first loaded. Base class: `RandomizedBuildingBase`.
| Story | Description |
|-|-|
| RBBar | Bar scene with drinks/bodies |
| RBBarn | Barn with farm supplies |
| RBBurnt / RBBurntCorpse / RBBurntFireman | Fire aftermath scenes |
| RBCafe / RBPileOCrepe / RBPizzaWhirled / RBSpiffo | Restaurant-specific scenes |
| RBClinic | Medical facility setup |
| RBDorm | Dormitory scene |
| RBGunstore / RBGunstoreSiege | Gun shop scenarios |
| RBKateAndBaldspot | Tutorial house (fixed at 10744, 9409) |
| RBLooted / RBShopLooted / RBTrashed | Looted building variants |
| RBOffice | Office building |
| RBPoliceSiege | Police station siege |
| RBSafehouse | Pre-made survivor safehouse |
| RBSchool | School setup |
| TableStories (9 sub-types) | Breakfast, dinner, sewing, electronics on tables |

### RandomizedDeadSurvivor (32 stories)
Dead bodies with environmental storytelling. Extends `RandomizedBuildingBase`.
Skips spawn buildings and stash buildings.
| Story | Description |
|-|-|
| RDSBanditRaid | Raided house with bodies |
| RDSBleach / RDSSuicidePact | Suicide scenes |
| RDSCorpsePsycho / RDSHockeyPsycho / RDSSkeletonPsycho | Serial killer scenes |
| RDSFootballNight / RDSPokerNight / RDSRPGNight | Game night gone wrong |
| RDSGunmanInBathroom / RDSGunslinger | Armed survivor deaths |
| RDSHenDo / RDSStagDo / RDSHouseParty / RDSStudentNight | Party scenes |
| RDSRatInfested / RDSRatKing / RDSRatWar / RDSDevouredByRats | Rat infestation |
| RDSZombieLockedBathroom / RDSZombiesEating | Zombie encounter scenes |
| RDSSpecificProfession | Profession-themed death |
| RDSResourceGarage | Garage with useful supplies |

### RandomizedVehicleStory (26 stories)
Triggered per-Nav zone chunk. Base class: `RandomizedVehicleStoryBase`.
Sandbox chance: `vehicleStoryChance` (1=never, 2=rare, 3-5=increasing).
| Story | Description |
|-|-|
| RVSCarCrash / RVSCarCrashCorpse / RVSCarCrashDeer | Vehicle accidents |
| RVSFlippedCrash / RVSTrailerCrash | Severe crashes |
| RVSPoliceBlockade / RVSPoliceBlockadeShooting | Police roadblocks |
| RVSAmbulanceCrash | Ambulance with medical loot |
| RVSBanditRoad | Bandit ambush scene |
| RVSBurntCar | Burnt out vehicle |
| RVSChangingTire | Stranded driver |
| RVSConstructionSite | Roadwork vehicles |
| RVSCrashHorde / RVSHerdOnRoad | Zombie crowd on road |
| RVSDeadEnd | Dead-end blockade |
| RVSAnimalOnRoad / RVSAnimalTrailerOnRoad | Animal-related road events |
| RVSRegionalProfessionVehicle | Profession-specific vehicle |
| RVSRichJerk | Luxury vehicle scene |

Properties: `needsPavement`, `needsDirt`, `needsFarmland`, `needsRuralVegetation`,
`notTown` - filter which zone/terrain types a story can appear in.

### RandomizedZoneStory (41 stories)
Triggered on `ZoneStory` typed zones in the open world.
Base class: `RandomizedZoneStoryBase`. Chance system: `baseChance = 15`.
| Story | Description |
|-|-|
| RZSCampsite / RZSForestCamp / RZSForestCampEaten | Wilderness camps |
| RZSHermitCamp / RZSSurvivalistCamp / RZSTrapperCamp | Survivor camps |
| RZSBBQParty / RZSBeachParty / RZSHillbillyHoedown | Outdoor party scenes |
| RZSMusicFest / RZSMusicFestStage / RZSRockerParty | Music events |
| RZSMurderScene / RZSOccultActivity | Crime scenes |
| RZSFishingTrip / RZSHunterCamp | Outdoor activity scenes |
| RZSBurntWreck / RZSWasteDump | Environmental hazards |
| RZSVanCamp / RZSSadCamp / RZSBuryingCamp | Somber scenes |
| RZSWaterPump | Water source scene |
| RZSEscapedAnimal / RZSEscapedHerd / RZSOrphanedFawn | Animal events |
| RZSCharcoalBurner / RZSOldFirepit / RZSOldShelter | Abandoned structures |

Story validity checks: zone must not have been seen (`hourLastSeen == 0`),
no player construction (`haveConstruction == false`), and no water squares.

## 9. World Streaming

### WorldStreamer (`zombie.iso.WorldStreamer`)
Singleton that manages async chunk loading on a dedicated thread.

**Loading flow:**
1. `IsoChunkMap.update()` detects player movement, calculates needed chunks
2. New chunk requests queued to `WorldStreamer.jobQueue`
3. WorldStreamer thread reads `IsoLot` data from `.lotpack` files
4. `CellLoader.DoTileObjectCreation()` instantiates objects per grid square
5. Chunk marked as loaded, lighting recalculated, Lua event `OnLoadedChunk` fired
6. RandomizedWorld stories triggered for newly loaded buildings/zones

**Unloading flow:**
1. `WorldReuserThread` monitors chunks outside player's `chunkGridWidth`
2. Chunks saved via `ChunkSaveWorker` (async, batched)
3. Objects returned to `ObjectCache` pools for reuse
4. `IsoChunkMap.chunkStore` recycles IsoChunk instances

**Multiplayer:**
- `WorldStreamer` sends `ChunkRequest` packets to server
- Server responds with compressed chunk data (`Inflater` decompression)
- `ChunkChecksum` (CRC32) validates data integrity
- `pendingRequests` queue manages request flow (max 20 concurrent for large areas)

## 10. World Generation (B42)

Build 42 added procedural world generation for areas beyond the hand-crafted map.

### Biome System (`zombie.iso.worldgen.biomes`)
| Enum | Values |
|-|-|
| Landscape | LIGHT_FOREST, FOREST, PLAIN, NONE |
| Plant | FLOWER, GRASS, NONE |
| Bush | DRY, REGULAR, FAT, NONE |
| Temperature | COLD, MEDIUM, HOT, NONE |
| Hygrometry | FLOODING, RAIN, DRY, NONE |
| OreLevel | VERY_LOW, LOW, MEDIUM, HIGH, VERY_HIGH, NONE |

Biomes are defined in `BiomeRegistry` and painted via `biomemap_X_Y.png` images
in the maps directory. `BiomeMap` + `BiomeMapEntry` resolve pixel colors to biome
assignments.

### WorldGenChunk
Generates a single chunk procedurally using:
- `WorldGenSimplexGenerator` for noise-based terrain
- `BiomeType` enums for terrain classification
- `Veins` / `OreVein` for underground resource placement
- `RoadGenerator` + `RoadConfig` for procedural roads
- `PrefabStructure` for pre-made building placement
- `StaticModule` for fixed map features
- `WorldGenZone` extends Zone with `rocks` property for stone spawning

### WorldGenParams
Stored in save file with magic `WGEN` (87, 71, 69, 78).
Seed string hashed to int. Per-chunk RNG: `seed + wx * wxRnd ^ wy * wyRnd`.
Default cell range: -250 to 250 in both axes (501 x 501 cells max).

## 11. Map Modding

### File Structure for Mod Maps
```
ModFolder/
  mod.info
  media/
    maps/
      MyMap/
        map.info                 -- title, lots, fixed2x, zoom
        objects.lua              -- zone definitions
        spawnpoints.lua          -- spawn locations
        {cellX}_{cellY}.lotheader
        world_{cellX}_{cellY}.lotpack
        chunkdata_{cellX}_{cellY}.bin
```

### map.info Fields
| Field | Description |
|-|-|
| `title` | Display name (or translation reference) |
| `lots` | Parent map to inherit data from (e.g., "Muldraugh, KY") |
| `fixed2x` | true for 8x8 chunk/256x256 cell system |
| `description` | Map description text |
| `zoomX, zoomY, zoomS` | World map camera position and zoom |
| `demoVideo` | Loading screen video file |

### MapFiles Priority System
Maps load in priority order. Lower priority = loaded first (base map). Higher
priority = overlays on top. `MapFiles.priority` determines which `.lotpack` data
takes precedence when multiple maps cover the same cell. Mod maps overlay the
base map.

### TileZed Workflow
1. Create buildings in **BuildingEd** (room layout, tile placement)
2. Place buildings on cells in **WorldEd** (lot placement, zone painting)
3. WorldEd exports: `.lotheader`, `.lotpack`, `chunkdata_*.bin`
4. Zone painting in WorldEd creates `objects.lua` entries
5. Basements exported as `.pzby` files, referenced in `basements.lua`
6. `NewMapBinaryFile` class reads `.pzby` format (magic: none, uses `pot=true`
   for 8x8 chunks or `pot=false` for legacy 10x10 chunks)

### Legacy vs POT (Power of Two) Format
| Property | Legacy | POT (current) |
|-|-|-|
| Chunk size | 10x10 | 8x8 |
| Chunks per cell | 30x30 | 32x32 |
| Cell size | 300x300 | 256x256 |
| `fixed2x` in map.info | false/absent | true |

All modern maps use POT format. The `NewMapBinaryFile` constructor takes
`boolean pot` - when true: `chunkDim=8, chunksPerCell=32, cellDim=256`.
