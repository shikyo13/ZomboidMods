# Iso World Structure - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Coordinate System | 19-56 |
| 2 | IsoCell | 58-102 |
| 3 | IsoGridSquare | 104-158 |
| 4 | IsoChunk | 160-201 |
| 5 | IsoChunkMap | 203-233 |
| 6 | IsoMetaGrid | 235-279 |
| 7 | IsoMetaCell | 281-314 |
| 8 | IsoWorld | 316-354 |
| 9 | Zone System | 356-396 |

---

## 1. Coordinate System

PZ uses an isometric tile-based world. All coordinates are integers unless stated otherwise.

**Hierarchy (largest to smallest):**

```
IsoMetaGrid  (entire world map, grid of IsoMetaCells)
  IsoMetaCell  (300x300 cell, 32x32 IsoMetaChunks, indexed by cell coords)
    IsoMetaChunk  (room/zone metadata for one chunk)
IsoCell  (active game cell, 32x32 chunks = 256x256 squares)
  IsoChunk  (8x8 squares, unit of loading/saving)
    IsoGridSquare  (single tile at x,y,z)
```

**Coordinate conversions:**

| From | To | Formula |
|-|-|-|
| Square (x,y) | Chunk (wx,wy) | wx = x / 8, wy = y / 8 |
| Square (x,y) | Cell (cx,cy) | cx = x / 256, cy = y / 256 |
| Chunk (wx,wy) | Cell (cx,cy) | cx = wx / 32, cy = wy / 32 |
| Square (x,y) | Local-in-chunk | lx = x % 8, ly = y % 8 |
| Square (x,y) | Local-in-cell | lx = x % 256, ly = y % 256 |

**Z-axis:** Level 0 = ground. Positive = above ground (up to 31). Negative = basements (down to -32). Constants: `IsoChunkMap.GROUND_LEVEL = 32`, `IsoChunkMap.LEVELS = 64`, `IsoChunkMap.TOP_LEVEL = 31`, `IsoChunkMap.BOTTOM_LEVEL = -32`.

**Size constants:**

| Constant | Value | Source |
|-|-|-|
| CELL_SIZE_IN_CHUNKS | 32 | IsoCell |
| CELL_SIZE_IN_SQUARES | 256 | IsoCell |
| CHUNK_SIZE_IN_SQUARES | 8 | IsoChunkMap |
| maxHeight | 32 (levels) | IsoCell |
| IsoMetaCell.chunkMap size | 1024 (32x32) | IsoMetaCell |

---

## 2. IsoCell
`zombie.iso.IsoCell` - The active game cell. Singleton managing all loaded chunks, objects, and entities.

### Key Fields
| Field | Type | Access | Description |
|-|-|-|-|
| CELL_SIZE_IN_CHUNKS | int = 32 | [pub][static][final] | Chunks per cell edge |
| CELL_SIZE_IN_SQUARES | int = 256 | [pub][static][final] | Squares per cell edge |
| maxHeight | int = 32 | [pub][static] | Max vertical levels |
| chunkMap | IsoChunkMap[4] | [pub][final] | Per-player chunk maps (splitscreen) |
| buildingList | ArrayList\<IsoBuilding\> | [pub][final] | All loaded buildings |
| vehicles | ArrayList\<BaseVehicle\> | [pub][final] | All loaded vehicles |
| roomLights | ArrayList\<IsoRoomLight\> | [pub][final] | Active room lights |
| instance | IsoCell | [priv][static] | Singleton reference |
| worldX, worldY | int | [priv] | Cell world position |
| width, height | int | [priv] | Cell dimensions |
| objectList | ArrayList\<IsoMovingObject\> | [priv][final] | All moving objects |
| zombieList | ArrayList\<IsoZombie\> | [priv][final] | All loaded zombies |
| roomList | ArrayList\<IsoRoom\> | [priv][final] | All loaded rooms |
| heatSources | ArrayList\<IsoHeatSource\> | [priv][final] | Active heat sources |
| nearestVisibleZombie | IsoZombie[4] | [pub][final] | Nearest zombie per player |

### Key Methods
| Method | Return | Access | Description |
|-|-|-|-|
| getGridSquare(int x, int y, int z) | IsoGridSquare | [pub] | Main square lookup - iterates player chunk maps |
| getGridSquare(double, double, double) | IsoGridSquare | [pub] | Float variant, floors coords |
| getOrCreateGridSquare(double, double, double) | IsoGridSquare | [pub] | Gets or creates a new square at position |
| getChunkForGridSquare(int x, int y, int z) | IsoChunk | [pub] | Finds chunk containing square coords |
| getChunk(int wx, int wy) | IsoChunk | [pub] | Gets chunk by world chunk coords |
| getChunkMap(int playerIndex) | IsoChunkMap | [pub] | Gets chunk map for player slot |
| getFreeTile(RoomDef) | IsoGridSquare | [pub] | Random free tile in a room |
| getNearestVisibleZombie(int) | IsoZombie | [pub] | Nearest visible zombie for player |

### Square Lookup Flow
`getGridSquare(x, y, z)` on client:
1. For each player chunk map (0..numPlayers):
   - Skip if `chunkMap[n].ignore` is true
   - Convert world square to chunkmap-local: `localX = x - chunkMap.getWorldXMinTiles()`
   - Bounds check against `chunkWidthInTiles`
   - Call `chunkMap.getGridSquareDirect(localX, localY, z)`
   - Return first non-null result
2. On server: delegates to `ServerMap.instance.getGridSquare(x, y, z)`

---

## 3. IsoGridSquare
`zombie.iso.IsoGridSquare` - A single tile in the world. Contains objects, properties, room assignment.

### Key Fields
| Field | Type | Access | Description |
|-|-|-|-|
| x, y, z | int | [pub] | World tile coordinates |
| chunk | IsoChunk | [pub] | Owning chunk reference |
| room | IsoRoom | [pub] | Room this square belongs to (null if exterior) |
| roomId | long = -1 | [pub] | Room ID (-1 = no room) |
| zone | Zone | [pub] | Zone reference for this square |
| id | Integer | [pub] | Unique square ID |
| objects | PZArrayList\<IsoObject\> | [prot][final] | All IsoObjects on this tile (floor, walls, items) |
| movingObjects | ArrayList\<IsoMovingObject\> | [priv][final] | Characters/zombies on this tile |
| staticMovingObjects | ArrayList\<IsoMovingObject\> | [priv][final] | Static moving objects |
| worldObjects | ArrayList\<IsoWorldInventoryObject\> | [priv][final] | Ground items |
| specialObjects | ArrayList\<IsoObject\> | [priv][final] | Doors, windows, barricades, etc. |
| properties | PropertyContainer | [priv][final] | Tile property flags (from tileset) |
| lighting | ILighting[4] | [pub][final] | Per-player lighting data |
| collideMatrix | int | [pub] | Collision bitmask |
| pathMatrix | int | [pub] | Pathfinding bitmask |
| visionMatrix | int | [pub] | Line-of-sight bitmask |
| hasTypes | long | [pub] | Bitfield of object types present |
| haveSheetRope | boolean | [pub] | Sheet rope attached |
| haveRoof | boolean | [pub] | Has roof above |
| hourLastSeen | int | [pub] | Game hour last seen by player |
| table | KahluaTable | [priv] | ModData (lazy-init) |
| w, nw, sw, s, n, ne, se, e | IsoGridSquare | [pub] | 8-directional neighbor refs |
| u, d | IsoGridSquare | [pub] | Up/down neighbor refs |

### Key Methods
| Method | Return | Access | Description |
|-|-|-|-|
| getObjects() | PZArrayList\<IsoObject\> | [pub] | All objects on square |
| getMovingObjects() | ArrayList\<IsoMovingObject\> | [pub] | Characters on square |
| getWorldObjects() | ArrayList\<IsoWorldInventoryObject\> | [pub] | Ground items |
| getSpecialObjects() | ArrayList\<IsoObject\> | [pub] | Doors, windows, etc. |
| getModData() | KahluaTable | [pub] | Per-square moddata (lazy-init KahluaTable) |
| hasModData() | boolean | [pub] | True if moddata exists and non-empty |
| getProperties() | PropertyContainer | [pub] | Tile property container |
| getRoom() | IsoRoom | [pub] | Room reference |
| getCoords() | SquareCoord | [pub] | Returns (x, y, z) as SquareCoord |
| isFree(boolean) | boolean | [pub] | True if nothing blocking |
| Is(IsoFlagType) | boolean | [pub] | Check tile property flag |
| getMatrixBit(int, byte, byte, byte) | boolean | [pub][static] | Read collision/path/vision matrix bit |
| setMatrixBit(int, byte, byte, byte, boolean) | int | [pub][static] | Set collision/path/vision matrix bit |
| playSound(String) | long | [pub] | Play sound at this square |

### Wall Type Constants
`WALL_TYPE_N = 1`, `WALL_TYPE_S = 2`, `WALL_TYPE_W = 4`, `WALL_TYPE_E = 8`

### Cutaway Flags (per-player)
`PCF_NONE = 0`, `PCF_NORTH = 1`, `PCF_WEST = 2`

---

## 4. IsoChunk
`zombie.iso.IsoChunk` - 8x8 tile chunk. Unit of world streaming, save, and load.

### Key Fields
| Field | Type | Access | Description |
|-|-|-|-|
| wx, wy | int | [pub] | World chunk coordinates |
| squares | IsoGridSquare[][] | [pub] | [level][localIndex] grid squares |
| lotheader | LotHeader | [pub] | Lot/building header for this chunk |
| maxLevel, minLevel | int | [pub] | Vertical extent of this chunk |
| loaded | boolean | [pub] | True when fully loaded |
| loadedFrame | long | [pub] | Frame number when loaded |
| vehicles | ArrayList\<BaseVehicle\> | [pub][final] | Vehicles in chunk |
| roomLights | ArrayList\<IsoRoomLight\> | [pub][final] | Room lights |
| soundList | ArrayList\<WorldSound\> | [pub][final] | Active sounds |
| refs | ArrayList\<IsoChunkMap\> | [pub][final] | Chunk maps referencing this chunk |
| floorBloodSplats | BoundedQueue\<IsoFloorBloodSplat\> | [pub][final] | Blood splats (max 1000) |
| requiresHotSave | boolean | [pub] | Needs immediate save |
| lootRespawnHour | int | [pub] | Loot respawn tracking |
| revision | long | [pub] | Save revision counter |
| levels | IsoChunkLevel[] | [priv] | Per-level data arrays |
| jobType | JobType | [pub] | Current job (None, Convert, etc.) |
| BLOCK_SIZE | int = 65536 | [pub][static][final] | Save buffer block size |

### Key Methods
| Method | Return | Access | Description |
|-|-|-|-|
| getGridSquare(int lx, int ly, int z) | IsoGridSquare | [pub] | Get square by local coords (0-7) |
| LoadFromDisk() | void | [pub] | Load chunk from disk file |
| LoadFromDiskOrBuffer(ByteBuffer) | void | [pub] | Load from disk or provided buffer |
| LoadFromDiskOrBufferInternal(ByteBuffer) | void | [pub] | Internal load, reads world version + CRC |
| Save(boolean preventReuse) | void | [pub] | Save chunk to disk |
| SafeWrite(int wx, int wy, ByteBuffer) | void | [pub][static] | Thread-safe file write |
| SafeRead(int wx, int wy, ByteBuffer) | ByteBuffer | [pub][static] | Thread-safe file read |
| flagForHotSave() | void | [pub] | Mark chunk for immediate save |
| loadInWorldStreamerThread() | void | [pub] | Async load in streamer thread |
| loadInMainThread() | void | [pub] | Finalize load on main thread |

### Chunk File Format
Save file: `<save_dir>/<wx>/<wy>.bin`. Header: debug flag (byte), world version (int), data length (int), CRC32 (long). Body: blending flags, attachment state, level range, blood splats, grid squares and objects.

---

## 5. IsoChunkMap
`zombie.iso.IsoChunkMap` - Per-player loaded chunk grid. Manages chunk loading around a player.

### Key Fields
| Field | Type | Access | Description |
|-|-|-|-|
| LEVELS | int = 64 | [pub][static][final] | Total vertical levels |
| GROUND_LEVEL | int = 32 | [pub][static][final] | Ground level index |
| CHUNKS_PER_WIDTH | int = 8 | [pub][static][final] | Loaded chunks per axis |
| CHUNK_SIZE_IN_SQUARES | int = 8 | [pub][static][final] | Squares per chunk edge |
| chunkGridWidth | int | [pub][static] | Current chunk grid width (default 13) |
| chunkWidthInTiles | int | [pub][static] | chunkGridWidth * 8 |
| SharedChunks | HashMap\<Integer, IsoChunk\> | [pub][static][final] | Shared chunk cache |
| playerId | int | [pub] | Player index (0-3) |
| ignore | boolean | [pub] | True if this chunkmap is inactive |
| worldX, worldY | int | [pub] | Current world chunk origin |
| chunksSwapA, chunksSwapB | IsoChunk[] | [prot] | Double-buffered chunk array |
| cell | IsoCell | [priv][final] | Parent cell |
| maxHeight, minHeight | int | [pub] | Loaded height range |

### Key Methods
| Method | Return | Access | Description |
|-|-|-|-|
| getChunk(int localX, int localY) | IsoChunk | [pub] | Get chunk from local grid position |
| getGridSquareDirect(int, int, int) | IsoGridSquare | [pub] | Direct square access from local coords |
| getWorldXMinTiles() | int | [pub] | World X of leftmost loaded tile |
| getWorldYMinTiles() | int | [pub] | World Y of topmost loaded tile |
| getWorldXMin() | int | [pub] | World chunk X minimum |
| getWorldYMin() | int | [pub] | World chunk Y minimum |

---

## 6. IsoMetaGrid
`zombie.iso.IsoMetaGrid` - World-level map grid. Manages meta cells, zones, buildings.

### Key Fields
| Field | Type | Access | Description |
|-|-|-|-|
| minX, minY, maxX, maxY | int | [pub] | World bounds in cell coords |
| zones | ArrayList\<Zone\> | [pub][final] | All registered zones |
| buildings | ArrayList\<BuildingDef\> | [pub][final] | All building definitions |
| vehiclesZones | ArrayList\<VehicleZone\> | [pub][final] | Vehicle spawn zones |
| animalZoneHandler | ZoneHandler\<AnimalZone\> | [pub][final] | Animal zones |
| grid | IsoMetaCell[][] | [priv] | 2D array of meta cells |
| metaCharacters | ArrayList\<IsoGameCharacter\> | [pub][final] | Meta-game characters |
| width, height | int | [priv] | Grid dimensions |
| loaded | boolean | [priv] | True when loaded |

### Key Methods
| Method | Return | Access | Description |
|-|-|-|-|
| getCell(int x, int y) | IsoMetaCell | [pub] | Get meta cell at grid-local coords |
| getCellOrCreate(int x, int y) | IsoMetaCell | [pub] | Get or create meta cell |
| hasCell(int x, int y) | boolean | [pub] | Check if cell exists |
| getZoneAt(int x, int y, int z) | Zone | [pub] | Get zone at tile position |
| getZonesAt(int x, int y, int z) | ArrayList\<Zone\> | [pub] | Get all zones at tile |
| getZonesIntersecting(x, y, z, w, h) | ArrayList\<Zone\> | [pub] | Get zones in rectangle |
| getZoneWithBoundsAndType(x, y, z, w, h, type) | Zone | [pub] | Find zone by exact bounds + type |
| getVehicleZoneAt(int x, int y, int z) | VehicleZone | [pub] | Vehicle zone at tile |
| getBuildingAt(int x, int y) | BuildingDef | [pub] | Building at tile (2D) |
| getBuildingAt(int x, int y, int z) | BuildingDef | [pub] | Building at tile (3D, via room lookup) |
| getRoomAt(int x, int y, int z) | RoomDef | [pub] | Room definition at tile |
| getRoomDefByID(long roomID) | RoomDef | [pub] | Room by unique ID |
| getRoomByID(long roomID) | IsoRoom | [pub] | IsoRoom by ID (creates if needed) |
| registerZone(name, type, x, y, z, w, h) | Zone | [pub] | Register a new zone |
| registerZone(Zone) | Zone | [pub] | Register existing zone object |
| AddToMeta(IsoGameCharacter) | void | [pub] | Move character to meta-game |
| RemoveFromMeta(IsoPlayer) | void | [pub] | Remove character from meta-game |
| load() | void | [pub] | Load from map_meta.bin |
| load(ByteBuffer) | void | [pub] | Load meta data from buffer |
| save() | void | [pub] | Save all (meta, zones, animals) |
| loadZone(ByteBuffer, int) | void | [pub] | Load zones from map_zone.bin |
| saveZone(ByteBuffer) | void | [pub] | Save zones to buffer |
| loadAnimalZones(ByteBuffer, int) | void | [pub] | Load animal zones from map_animals.bin |
| saveAnimalZones(ByteBuffer) | void | [pub] | Save animal zones |

---

## 7. IsoMetaCell
`zombie.iso.IsoMetaCell` - Meta-level cell data. Stores room defs, building defs, zones, triggers.

### Key Fields
| Field | Type | Access | Description |
|-|-|-|-|
| wx, wy | int | [priv][final] | Cell world coordinates |
| chunkMap | IsoMetaChunk[1024] | [priv][final] | 32x32 meta chunks |
| info | LotHeader | [pub] | Lot header (building data) |
| vehicleZones | ArrayList\<VehicleZone\> | [pub][final] | Vehicle zones in cell |
| triggers | ArrayList\<Trigger\> | [pub][final] | Event triggers |
| rooms | HashMap\<Long, RoomDef\> | [pub][final] | Room defs by ID |
| roomByMetaId | TLongObjectHashMap\<RoomDef\> | [pub][final] | Rooms by meta ID |
| roomList | ArrayList\<RoomDef\> | [pub][final] | All rooms in cell |
| buildings | ArrayList\<BuildingDef\> | [pub][final] | Building defs |
| buildingByMetaId | TLongObjectHashMap\<BuildingDef\> | [pub][final] | Buildings by meta ID |
| isoRooms | HashMap\<Long, IsoRoom\> | [pub][final] | Active IsoRoom instances |
| isoBuildings | HashMap\<Long, IsoBuilding\> | [pub][final] | Active IsoBuilding instances |
| worldGenZones | ArrayList\<WorldGenZone\> | [pub] | Procedural gen zones |

### Key Methods
| Method | Return | Access | Description |
|-|-|-|-|
| getX() / getY() | int | [pub] | Cell world coords |
| getChunk(int x, int y) | IsoMetaChunk | [pub] | Meta chunk at local pos (0-31) |
| hasChunk(int x, int y) | boolean | [pub] | Check if meta chunk exists |
| addZone(Zone, int cellX, int cellY) | void | [pub] | Register zone across meta chunks |
| removeZone(Zone) | void | [pub] | Remove zone |
| addRoom(RoomDef, int cellX, int cellY) | void | [pub] | Register room def |
| addRooms(ArrayList\<RoomDef\>, cellX, cellY) | void | [pub] | Bulk add rooms |
| addTrigger(BuildingDef, range, exclRange, type) | void | [pub] | Add event trigger |
| checkTriggers() | void | [pub] | Check if player is in trigger range |

---

## 8. IsoWorld
`zombie.iso.IsoWorld` - Singleton world instance. Top-level game state.

### Key Fields
| Field | Type | Access | Description |
|-|-|-|-|
| instance | IsoWorld | [pub][static] | Global singleton |
| currentCell | IsoCell | [pub] | Active cell |
| metaGrid | IsoMetaGrid | [pub][final] | World meta grid |
| WorldVersion | int = 244 | [pub][static][final] | Current save format version |
| savedWorldVersion | int | [pub][static] | Version of loaded save |
| characters | ArrayList\<IsoGameCharacter\> | [pub][final] | All active characters |
| x, y | int | [pub] | World position |
| helicopter | Helicopter | [pub][final] | Helicopter event manager |
| totalSurvivorsDead | int | [pub] | Death counter |
| totalSurvivorNights | int | [pub] | Survival nights counter |
| survivorSurvivalRecord | int | [pub] | Best survival record |
| mapPath | String | [pub][static] | Path to map files |

### WorldVersion Constants (selected)
| Constant | Version | Feature |
|-|-|-|
| WorldVersion_VariableHeight | 206 | Multi-level chunks |
| WorldVersion_EnableWorldgen | 207 | Procedural worldgen |
| WorldVersion_ZoneIDisUUID | 215 | Zone IDs changed to UUID |
| WorldVersion_SquareSeen | 218 | Per-square visibility tracking |
| WorldVersion_InventoryItemUsesInteger | 220 | Item uses as int |
| WorldVersion_42_13 | 240 | Build 42.13 save format |
| WorldVersion_RemoveDifficulty | 244 | Current version |

### Key Methods
| Method | Return | Access | Description |
|-|-|-|-|
| getMetaGrid() | IsoMetaGrid | [pub] | Get meta grid |
| registerZone(name, type, x, y, z, w, h) | Zone | [pub] | Register zone via metaGrid |
| getFreeEmitter() | BaseSoundEmitter | [pub] | Get pooled sound emitter |
| getFreeEmitter(float x, y, z) | BaseSoundEmitter | [pub] | Get emitter at position |

---

## 9. Zone System
`zombie.iso.zones.Zone` - Rectangular or polygon zone defining an area type.

### Key Fields
| Field | Type | Access | Description |
|-|-|-|-|
| id | UUID | [pub] | Unique identifier |
| name | String | [pub] | Display name |
| type | String | [pub] | Zone type string |
| x, y, z | int | [pub] | Origin position |
| w, h | int | [pub] | Width, height in tiles |
| geometryType | ZoneGeometryType | [pub] | INVALID, Polygon, or Polyline |
| points | TIntArrayList | [pub][final] | Polygon/polyline vertices |
| polylineWidth | int | [pub] | Width for polyline zones |
| triangles | float[] | [pub] | Triangulated geometry cache |
| totalArea | float | [pub] | Total area in tiles |
| hourLastSeen | int | [pub] | Last seen by player (game hour) |
| haveConstruction | boolean | [pub] | Player has built here |
| zombiesTypeToSpawn | String | [pub] | Zombie type override |
| spawnSpecialZombies | Boolean | [pub] | Special zombie flag |
| isPreferredZoneForSquare | boolean | [pub] | Preferred for square assignment |

### Preferred Zone Types
`DeepForest`, `Farm`, `FarmLand`, `Forest`, `Vegitation`, `Nav`, `TownZone`, `TrailerPark`

### Key Methods
| Method | Return | Access | Description |
|-|-|-|-|
| load(ByteBuffer, int, Map, SharedStrings) | Zone | [pub] | Load from string-mapped buffer |
| load(ByteBuffer, int) | Zone | [pub] | Load from raw buffer |
| save(ByteBuffer, Map) | void | [pub] | Save to string-mapped buffer |
| intersects(int x, y, z, w, h) | boolean | [pub] | Bounds intersection test |
| contains(int x, int y, int z) | boolean | [pub] | Point containment test |
| getType() | String | [pub] | Zone type |

### Zone File: map_zone.bin
Magic: 'ZONE' + world version (int) + string table + zone count + serialized zones.
Per zone: name(short idx), type(short idx), x(int), y(int), z(byte), w(int), h(int), geometry, points, originalName, UUID.

### Common Zone Types
`TownZone`, `Forest`, `DeepForest`, `Farm`, `FarmLand`, `Nav`, `TrailerPark`, `Vegitation`
