# Save & Persistence - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Save File Structure | 17-47 |
| 2 | Chunk Save/Load | 49-87 |
| 3 | MetaGrid Save/Load | 89-116 |
| 4 | ModData API | 118-158 |
| 5 | GlobalModData | 160-204 |
| 6 | GlobalObject System | 206-317 |
| 7 | Player Save Data | 319-372 |

---

## 1. Save File Structure

Save directory: `~/Zomboid/Saves/<mode>/<savename>/`

### Core Save Files
| File | Writer | Content |
|-|-|-|
| map_meta.bin | IsoMetaGrid | Room explored state, building alarm/key/loot data |
| map_zone.bin | IsoMetaGrid | All registered zones (magic: 'ZONE') |
| map_animals.bin | IsoMetaGrid | Animal zones and junctions |
| map_visited.bin | IsoMetaGrid | Visited cells data |
| global_mod_data.bin | GlobalModData | Per-tag KahluaTable mod data |
| gos_\<name\>.bin | SGlobalObjectSystem | Global object system state (magic: 'GLOS') |
| players.db | PlayerDB | SQLite database of player save data |
| vehicles.db | VehiclesDB2 | SQLite database of vehicle state |
| \<wx\>/\<wy\>.bin | IsoChunk | Per-chunk tile data |

### World Version
Current: `IsoWorld.WorldVersion = 244`. Written to every save file. On load, version is checked and older formats are migrated forward. Files from newer versions throw exceptions.

### Save Trigger Points
- Periodic autosave via `PlayerDB.saveToDbPeriod` (10s interval)
- Chunk hot-save when `IsoChunk.requiresHotSave` (checked every 1s)
- Explicit save on quit/sleep
- `ChunkSaveWorker` handles async chunk writes on streamer thread
- `IsoChunk.WriteLock` synchronizes all chunk file I/O
- Write-then-rename safety pattern: `.tmp` then copy to `.bin`
- Chunk I/O uses per-position `ChunkLock` (ReentrantReadWriteLock)
- All saves gated by `Core.getInstance().isNoSave()` and `GameClient.client`

---

## 2. Chunk Save/Load
`zombie.iso.IsoChunk` handles per-chunk persistence.

### Save Flow: IsoChunk.Save(boolean)
1. Check `isNoSave()` and client status
2. Acquire `WriteLock` (static Object monitor)
3. Run `sanityCheck.beginSave(this)`
4. Create save directory if needed
5. Serialize to `sliceBuffer` via `Save(ByteBuffer, CRC32, boolean)`
6. For MP: compare CRC to existing, only write if changed
7. For SP: always write via `SafeWrite(wx, wy, sliceBuffer)`
8. Release chunk for reuse via `WorldReuserThread`

### Load Flow: IsoChunk.LoadFromDiskOrBufferInternal(ByteBuffer)
1. Read from file or provided ByteBuffer
2. Parse header:
   - Byte 0: debug save flag
   - Bytes 1-4: world version (int)
   - Bytes 5-8: data length (int)
   - Bytes 9-16: CRC32 checksum (long)
3. Verify CRC against computed value
4. Read blending state (worldVersion >= 209)
5. Read blending modified flags (worldVersion >= 210)
6. Read attachment state (worldVersion >= 214)
7. Read min/max level (worldVersion >= 206, else 0-7)
8. Read blood splats (bounded by lifespan setting)
9. Read grid squares, objects, and state

### Chunk File Location
Resolved by `ChunkMapFilenames.instance.getFilename(wx, wy)`. Fallback: `<save_dir>/<wx>/<wy>.bin`.

### Hot Save
`flagForHotSave()` sets `requiresHotSave = true` unless `preventHotSave` is set. Hot saves are checked periodically by `IsoChunkMap` (1 second interval via `hotSaveFrequency`).

### Two-Phase Chunk Load
1. `loadInWorldStreamerThread()` - runs on streamer thread, reads file data
2. `loadInMainThread()` - finishes on main thread, connects squares, spawns entities

---

## 3. MetaGrid Save/Load
`zombie.iso.IsoMetaGrid` handles world-level persistence.

### map_meta.bin Format
| Offset | Type | Content |
|-|-|-|
| 0-3 | bytes | Magic header |
| 4-7 | int | World version |
| 8-11 | int | minX (cell coord) |
| 12-15 | int | minY |
| 16-19 | int | maxX |
| 20-23 | int | maxY |
| 24+ | per-cell | Room states, building states |

Per-cell room data:
- int: room count
- Per room: long metaID, short flags (explored, lightsActive, doneSpawn, roofFixed)

Per-cell building data:
- int: building count
- Per building: long metaID, byte alarmed, int keyId, byte seen, byte hasBeenVisited, int lootRespawnHour, int alarmDecay (v201+)

After all cells: SafeHouse data, DesignationZone data, NonPvpZone data.

### Key MetaGrid I/O Methods
`save()` writes map_meta.bin, map_zone.bin, map_animals.bin. `load()` reads map_meta.bin via `SliceY.SliceBuffer` (shared ByteBuffer, synced via `SliceY.SliceBufferLock`). `loadZone()` / `saveZone()` handle map_zone.bin. `loadAnimalZones()` / `saveAnimalZones()` handle map_animals.bin.

---

## 4. ModData API
ModData is PZ's key-value persistence system for mods. Three levels exist.

### Per-Object ModData (IsoObject)
`zombie.iso.IsoObject` - Every world object has a lazy-init KahluaTable.

| Method | Class | Description |
|-|-|-|
| getModData() | IsoObject | Returns KahluaTable, creates if null |
| setModData(KahluaTable) | IsoObject | Replace moddata table |
| hasModData() | IsoObject | True if table exists and non-empty |

**Storage:** `IsoObject.table` (KahluaTable, initially null).
**Persistence:** Serialized with the chunk. Written during `IsoChunk.Save()`, read during `IsoChunk.LoadFromDiskOrBufferInternal()`.
**Networking:** Synced via `ReceiveModDataPacket` on object changes.

Lua usage:
```lua
local obj = square:getObjects():get(0)
obj:getModData().myModKey = "myValue"
obj:transmitModData()  -- sync to server/clients
```

### Per-Square ModData (IsoGridSquare)
`zombie.iso.IsoGridSquare` has its own moddata, separate from objects.

| Method | Class | Description |
|-|-|-|
| getModData() | IsoGridSquare | Returns KahluaTable, creates if null |
| hasModData() | IsoGridSquare | True if table exists and non-empty |

**Storage:** `IsoGridSquare.table` (KahluaTable, initially null).
**Persistence:** Serialized with the chunk alongside square data.

### Per-Player ModData (IsoPlayer / IsoGameCharacter)
Players inherit `getModData()` from IsoObject. Player moddata is saved in `players.db`.

### Vanilla ModData Keys (examples)
`waterAmount` (Double, water level), `waterMaxAmount` (Double), `canBeWaterPiped` (Boolean), `FUEL_AMOUNT` (Double, fuel), `isLit` (Boolean, campfire), `ConnectedToStairs<dir>` (Boolean, on squares), `state`/`nbOfGrow`/`health` (farming GlobalObject).

---

## 5. GlobalModData
`zombie.world.moddata.GlobalModData` - World-level mod persistence. Survives chunk unload.

### Key Fields
| Field | Type | Access | Description |
|-|-|-|-|
| instance | GlobalModData | [pub][static] | Singleton |
| modData | Map\<String, KahluaTable\> | [priv][final] | Tag-to-table store |
| SAVE_FILE | String = "global_mod_data" | [pub][static][final] | Base filename |

### Key Methods
| Method | Return | Access | Description |
|-|-|-|-|
| init() | void | [pub] | Load from disk, fire OnInitGlobalModData |
| get(String tag) | KahluaTable | [pub] | Get table by tag (null if missing) |
| getOrCreate(String tag) | KahluaTable | [pub] | Get or create table |
| create(String tag) | KahluaTable | [pub] | Create new table (null if exists) |
| create() | String | [pub] | Create with UUID tag, return tag |
| exists(String tag) | boolean | [pub] | Check if tag exists |
| remove(String tag) | KahluaTable | [pub] | Remove and return table |
| add(String tag, KahluaTable) | void | [pub] | Put table directly |
| transmit(String tag) | void | [pub] | Send table to all clients/server |
| request(String tag) | void | [pub] | Client requests table from server |
| save() | void | [pub] | Save all to global_mod_data.bin |
| load() | void | [pub] | Load from global_mod_data.bin |
| reset() | void | [pub] | Clear all data |

### global_mod_data.bin Format
| Offset | Type | Content |
|-|-|-|
| 0-3 | int | World version |
| 4-7 | int | Entry count |
| per-entry | int + string + table | Block size, tag string, KahluaTable binary |

Lua usage:
```lua
local data = ModData.getOrCreate("MyMod")
data.someValue = 42
ModData.transmit("MyMod")  -- sync to MP
```

### Lua Events
- `OnInitGlobalModData(boolean isNewGame)` - fired after load, use to initialize defaults

---

## 6. GlobalObject System
`zombie.globalObjects` - Server-authoritative object tracking across chunks.

### Architecture

```
SGlobalObjects (static registry)
  SGlobalObjectSystem (named system, e.g. "farming", "campfire")
    GlobalObject (single tracked object at x,y,z)
      modData (KahluaTable)
    GlobalObjectLookup (spatial index: cell -> chunk -> objects)
```

### SGlobalObjects (Registry)
`zombie.globalObjects.SGlobalObjects` - Static manager for all systems.

| Method | Return | Access | Description |
|-|-|-|-|
| registerSystem(String name) | SGlobalObjectSystem | [pub][static] | Get or create system |
| newSystem(String name) | SGlobalObjectSystem | [pub][static] | Create new (throws if exists) |
| getSystemByName(String name) | SGlobalObjectSystem | [pub][static] | Lookup by name |
| getSystemByIndex(int) | SGlobalObjectSystem | [pub][static] | Lookup by index |
| getSystemCount() | int | [pub][static] | Number of systems |
| update() | void | [pub][static] | Tick all systems |
| chunkLoaded(int wx, int wy) | void | [pub][static] | Notify all systems of chunk load |
| initSystems() | void | [pub][static] | Fire OnSGlobalObjectSystemInit event |
| save() | void | [pub][static] | Save all systems |
| Reset() | void | [pub][static] | Clear all systems |
| saveInitialStateForClient(ByteBufferWriter) | void | [pub][static] | Serialize for new client |
| receiveClientCommand(system, cmd, player, args) | boolean | [pub][static] | Route client command |

### SGlobalObjectSystem (Per-System)
`zombie.globalObjects.SGlobalObjectSystem extends GlobalObjectSystem`

| Field | Type | Access | Description |
|-|-|-|-|
| name | String | [prot][final] | System name |
| modData | KahluaTable | [prot][final] | System-level moddata |
| objects | ArrayList\<GlobalObject\> | [prot][final] | All objects in system |
| lookup | GlobalObjectLookup | [prot][final] | Spatial index |
| modDataKeys | HashSet\<String\> | [prot][final] | Keys to persist in system moddata |
| objectModDataKeys | HashSet\<String\> | [prot][final] | Keys to persist per object |
| objectSyncKeys | HashSet\<String\> | [prot][final] | Keys to sync to clients |
| loadedWorldVersion | int | [prot] | Version of loaded save |

| Method | Return | Access | Description |
|-|-|-|-|
| newObject(int x, y, z) | GlobalObject | [pub][final] | Create object (throws if exists at pos) |
| removeObject(GlobalObject) | void | [pub][final] | Remove and reset object |
| getObjectAt(int x, y, z) | GlobalObject | [pub][final] | Lookup by position |
| getObjectAt(IsoGridSquare) | GlobalObject | [pub][final] | Lookup by square |
| hasObjectsInChunk(int wx, wy) | boolean | [pub][final] | Check chunk has objects |
| getObjectsInChunk(int wx, wy) | ArrayList\<GlobalObject\> | [pub][final] | Get all in chunk |
| getObjectsAdjacentTo(x, y, z) | ArrayList\<GlobalObject\> | [pub][final] | Get neighbors |
| getObjectCount() | int | [pub][final] | Total objects |
| getObjectByIndex(int) | GlobalObject | [pub][final] | By index |
| setModDataKeys(KahluaTable) | void | [pub] | Set persistent system keys |
| setObjectModDataKeys(KahluaTable) | void | [pub] | Set persistent object keys |
| setObjectSyncKeys(KahluaTable) | void | [pub] | Set client-sync keys |
| chunkLoaded(int wx, wy) | void | [pub] | Calls Lua OnChunkLoaded |
| sendCommand(String, KahluaTable) | void | [pub] | Send to server |
| receiveClientCommand(cmd, player, args) | void | [pub] | Handle client command via Lua |
| getInitialStateForClient() | KahluaTable | [pub] | Lua callback for client init |
| load() | void | [pub] | Load from gos_\<name\>.bin |
| save() | void | [pub] | Save to gos_\<name\>.bin |
| getName() | String | [pub][final] | System name |
| getModData() | KahluaTable | [pub][final] | System moddata |

### gos_\<name\>.bin Format
| Offset | Type | Content |
|-|-|-|
| 0-3 | bytes | Magic: 'GLOS' (0x47, 0x4C, 0x4F, 0x53) |
| 4-7 | int | World version |
| 8 | byte | Has system moddata (0/1) |
| 9+ | KahluaTable | System moddata (if present, filtered by modDataKeys) |
| varies | int | Object count |
| per-object | int, int, byte, table | x, y, z, object moddata |

### GlobalObject (Base)
`zombie.globalObjects.GlobalObject` (abstract)

| Field | Type | Access | Description |
|-|-|-|-|
| system | GlobalObjectSystem | [prot] | Owning system |
| x, y, z | int | [prot] | World position |
| modData | KahluaTable | [prot][final] | Object-level data |

| Method | Return | Access | Description |
|-|-|-|-|
| getSquare() | IsoGridSquare | [pub] | Get world square (may be null if unloaded) |
| getIsoObject() | IsoObject | [pub] | Find matching IsoObject on square |
| isValidIsoObject(IsoObject) | boolean | [pub] | Validate object matches system |
| getModData() | KahluaTable | [pub] | Object moddata table |
| destroyThisObject() | void | [pub] | Destroy with system-specific cleanup |
| Reset() | void | [pub] | Clear state |

### GlobalObjectLookup (Spatial Index)
Cell -> Chunk -> Object list. Uses `IsoMetaGrid.minX/minY` for coordinate mapping. Chunk size = 8 squares.

### Lua Setup Pattern (in OnSGlobalObjectSystemInit)
```lua
local system = SGlobalObjects.registerSystem("MySystem")
local sd = system:getModData()
sd.OnChunkLoaded = MySystem.OnChunkLoaded
sd.OnClientCommand = MySystem.OnClientCommand
sd.getInitialStateForClient = MySystem.getInitialStateForClient
system:setModDataKeys({"key1"})
system:setObjectModDataKeys({"objKey1"})
system:setObjectSyncKeys({"objKey1"})
```

---

## 7. Player Save Data
`zombie.savefile.PlayerDB` - SQLite-backed player persistence.

### Key Fields
| Field | Type | Access | Description |
|-|-|-|-|
| instance | PlayerDB | [priv][static] | Singleton |
| store | IPlayerStore | [priv][final] | SQLite backend (SQLPlayerStore) |
| usedIds | TIntHashSet | [priv][final] | Allocated player SQL IDs |
| canSavePlayers | boolean | [pub] | Save gate flag |
| saveToDbPeriod | UpdateLimit(10000) | [priv][final] | 10-second save interval |
| toThread | ConcurrentLinkedQueue\<PlayerData\> | [priv][final] | Save queue (main -> streamer) |
| fromThread | ConcurrentLinkedQueue\<PlayerData\> | [priv][final] | Recycle pool (streamer -> main) |

### Key Methods
| Method | Return | Access | Description |
|-|-|-|-|
| getInstance() | PlayerDB | [pub][static] | Get singleton (creates if allowed) |
| setAllow(boolean) | void | [pub][static] | Enable/disable creation |
| isAvailable() | boolean | [pub][static] | True if instance exists |
| updateMain() | void | [pub] | Called on main thread, triggers periodic save |
| updateWorldStreamer() | void | [pub] | Process save queue on streamer thread |
| savePlayers() | void | [pub] | Request save on next update |
| saveLocalPlayersForce() | void | [pub] | Immediate save |
| close() | void | [pub] | Shutdown, flush queue |

### Save Flow
1. `updateMain()` checks `saveToDbPeriod` (10s) or `forceSavePlayers`
2. For each `IsoPlayer.players[i]`:
   - Allocate `sqlId` if -1 (new player)
   - Create `PlayerData` snapshot via `playerData.set(player)`
   - Enqueue to `toThread`
3. `WorldStreamer` thread calls `updateWorldStreamer()`
4. Dequeue and write via `store.save(playerData)` (SQLite INSERT/UPDATE)

### PlayerData Contents
The `PlayerData.set(IsoPlayer)` method serializes:
- SQL ID, player name
- World position (wx, wy, x, y, z)
- World version at save time
- Full player state as byte[] (serialized via ByteBuffer)
- Death flag

### Database: players.db
SQLite database in save directory. Table schema managed by `PlayerDBHelper`.

### Server Player DB
`ServerPlayerDB` extends the system for multiplayer:
- Per-connection player tracking
- Account-based player lookup
- Separate from single-player `PlayerDB`

### Client Player DB
`ClientPlayerDB` handles client-side player data caching for MP reconnection.
