# Networking System - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture Overview | 17-33 |
| 2 | GameClient | 34-89 |
| 3 | GameServer | 90-136 |
| 4 | Client/Server Command System | 137-191 |
| 5 | Packet Types | 192-318 |
| 6 | Packet Infrastructure | 319-355 |
| 7 | Sync Mechanisms | 356-392 |
| 8 | Authority Model | 393-432 |
| 9 | Key Networking Classes | 433-467 |

## 1. Architecture Overview

PZ uses a client-server model built on RakNet (UDP). Even singleplayer runs a local
server via `zombie.spnetwork` which stubs out actual networking. The architecture:

- **Transport**: `UdpEngine` wraps RakNet. Each client holds one `UdpConnection`.
  The server holds an `ArrayList<UdpConnection>` for all connected clients.
- **Packet dispatch**: All packets flow through `PacketTypes.PacketType` enum. Each enum
  value defines server handler, client handler, client-loading handler, priority,
  reliability, ordering channel, required capability, and optional anti-cheat checks.
- **Lua bridge**: `sendClientCommand`/`sendServerCommand` serialize KahluaTable args via
  `TableNetworkUtils` and dispatch through the `ClientCommand` packet type. Lua events
  `OnClientCommand` (server-side) and `OnServerCommand` (client-side) deliver payloads.
- **Singleplayer**: `zombie.spnetwork.UdpConnection` implements `IConnection` but
  sends packets directly to the local `SinglePlayerServer` via byte buffer copy.
  Most methods return null/no-op - no real network I/O occurs.

## 2. GameClient

**Class**: `zombie.network.GameClient` [pub]
**Singleton**: `GameClient.instance`

### Key Fields

| Field | Type | Access | Purpose |
|-|-|-|-|
| `client` | boolean | [pub][static] | True when running as network client |
| `connection` | UdpConnection | [pub][static] | The connection to the server |
| `udpEngine` | UdpEngine | [pub] | Network engine instance |
| `ip` | String | [pub][static] | Server IP to connect to |
| `port` | int | [pub][static] | Server port (default 16361) |
| `username` | String | [pub][static] | Current player's username |
| `serverPassword` | String | [pub][static] | Password for server auth |
| `id` | byte | [pub] | Client's assigned network ID |
| `connectedPlayers` | ArrayList\<IsoPlayer> | [pub] | All players visible to client |
| `IDToPlayerMap` | HashMap\<Short,IsoPlayer> | [pub][static] | Online ID to player map |
| `IDToZombieMap` | TShortObjectHashMap\<IsoZombie> | [pub][static] | Online ID to zombie map |
| `ingame` | boolean | [pub][static] | True once fully loaded |
| `ping` | int | [pub] | Current ping to server |
| `DEFAULT_PORT` | int = 16361 | [pub][static] | Default client port |

### Key Methods

| Method | Access | Purpose |
|-|-|-|
| `init()` | [pub] | Clears state, resets maps, calls `startClient()` |
| `startClient()` | [pub] | Creates `UdpEngine`, calls `Connect(ip, port, pwd, relay)` |
| `update()` | [pub] | Main loop - polls `MainLoopNetDataQ`, processes packets, handles disconnects |
| `Shutdown()` | [pub] | Shuts down `UdpEngine` |
| `sendClientCommand(player, module, cmd, args)` | [pub] | Sends Lua command to server (see Section 4) |
| `sendClientCommandV(player, module, cmd, ...)` | [pub] | Varargs version - builds KahluaTable from key/value pairs |
| `receiveClientCommand(bb, packetType)` | [static] | Deserializes server command, fires `OnServerCommand` event |
| `getPlayerByOnlineID(id)` | [pub] | Lookup in `IDToPlayerMap` |
| `gameLoadingDealWithNetData(data)` | [priv] | Handles packets during loading screen |

### Connection Flow
1. `ConnectionManager.serverConnect()` queues a connect request
2. `GameClient.startClient()` creates `UdpEngine` and calls `Connect()`
3. Server sends `Checksum` packet, client validates
4. Client sends `Login` packet with credentials
5. Server may queue client via `LoginQueue` then sends `LoginQueueDone`
6. Client sends `PlayerConnect`, server responds with `ConnectedPlayer`
7. Server sends `ServerCustomization`, `MetaData`, `ServerMap` chunks
8. Client enters game, `ingame` set to true

### Update Loop
`GameClient.update()` is called from the game's main thread:
1. Polls `MainLoopNetDataQ` (thread-safe queue from network thread)
2. Processes delayed disconnects (fires Lua events like `OnDisconnect`)
3. If connection lost, handles remaining packets or shuts down
4. Iterates `MainLoopNetData`, dispatches each via `PacketType.onClientPacket()`
5. Updates safehouse timers, zombie count optimiser

## 3. GameServer

**Class**: `zombie.network.GameServer` [pub]
**Entry point**: `GameServer.main(String[] args)`

### Key Fields

| Field | Type | Access | Purpose |
|-|-|-|-|
| `server` | boolean | [pub][static] | True when running as server |
| `coop` | boolean | [pub][static] | True for host-and-play (coop) mode |
| `udpEngine` | UdpEngine | [pub][static] | Server's network engine |
| `Players` | ArrayList\<IsoPlayer> | [pub][static] | All connected players |
| `IDToPlayerMap` | HashMap\<Short,IsoPlayer> | [pub][static] | Online ID to player map |
| `IDToAddressMap` | HashMap\<Short,Long> | [pub][static] | Online ID to connection GUID |
| `PlayerToAddressMap` | HashMap\<IsoPlayer,Long> | [pub][static] | Player to connection GUID |
| `SlotToConnection` | UdpConnection[512] | [pub][static] | Slot-indexed connections |
| `MAX_PLAYERS` | int = 512 | [pub][static] | Hard max player cap |
| `defaultPort` | int = 16261 | [pub][static] | Default server port |
| `udpPort` | int = 16262 | [pub][static] | Default UDP port |
| `serverName` | String | [pub][static] | Server name from config |
| `TimeLimitForProcessPackets` | int = 70 | [pub][static] | Max ms per tick for packets |
| `PacketsUpdateRate` | int = 200 | [pub][static] | Packet processing interval ms |
| `FPS` | int = 10 | [pub][static] | Server tick rate |

### Key Methods

| Method | Access | Purpose |
|-|-|-|
| `main(args)` | [pub][static] | Entry point - parses CLI args, starts server loop |
| `sendServerCommand(module, cmd, args, conn)` | [pub][static] | Sends to specific client |
| `sendServerCommand(module, cmd, args)` | [pub][static] | Broadcasts to all clients |
| `sendServerCommandV(module, cmd, ...)` | [pub][static] | Varargs version |
| `sendServerCommand(player, module, cmd, args)` | [pub][static] | Sends to specific player's connection |
| `receiveClientCommand(bb, conn, type)` | [static] | Processes incoming Lua command, fires `OnClientCommand` |
| `getPlayerFromConnection(conn, idx)` | [pub][static] | Gets player at index from connection |
| `getPlayerByUserName(username)` | [pub][static] | Searches all connections for player |
| `getConnectionFromPlayer(player)` | [pub][static] | Reverse lookup via `PlayerToAddressMap` |

### Server Loop
The server runs at 10 FPS. Each iteration:
1. Processes console commands
2. Polls `MainLoopNetDataQ` and `MainLoopNetDataHighPriorityQ`
3. Dispatches packets via `PacketType.onServerPacket()` (max 70ms)
4. Runs game simulation tick
5. Sends periodic updates to clients

## 4. Client/Server Command System

This is the primary mechanism mods use for networked communication.

### Lua API (client-side, sending to server)
```lua
sendClientCommand(player, module, command, args)
-- player: IsoPlayer (the sending player)
-- module: string (e.g. "mymod")
-- command: string (e.g. "doSomething")
-- args: table or nil (key-value pairs)
```

### Lua API (server-side, sending to client)
```lua
sendServerCommand(module, command, args)           -- broadcast to all
sendServerCommand(player, module, command, args)   -- to specific player
```

### Wire Format (ClientCommand packet)
**Client to server**:
1. `byte` - player index (or -1)
2. `UTF` - module string
3. `UTF` - command string
4. `boolean` - hasArgs flag
5. If hasArgs: `TableNetworkUtils.save(table)` serialized KahluaTable

**Server to client** (same packet type, reverse direction):
1. `UTF` - module string
2. `UTF` - command string
3. `boolean` - hasArgs flag
4. If hasArgs: serialized KahluaTable

### TableNetworkUtils Serialization
Supports these types in KahluaTable args:
| Type Byte | Java Type | Lua Type |
|-|-|-|
| 0 | String | string |
| 1 | Double | number |
| 2 | KahluaTable | table (recursive) |
| 3 | Boolean | boolean |
| 4 | InventoryItem | userdata |
| 5 | IsoDirections | userdata |

### Event Dispatch
- **Server receives**: `GameServer.receiveClientCommand()` fires
  `LuaEventManager.triggerEvent("OnClientCommand", module, command, player, args)`
- **Client receives**: `GameClient.receiveClientCommand()` fires
  `LuaEventManager.triggerEvent("OnServerCommand", module, command, args)`

### CC Filtering
Server can filter client commands via `CCFilter` map. Filters use `+module.command` (allow)
or `-module.command` (deny) patterns. The `vehicle.remove` command is hardcoded to require
either debug mode, `GeneralCheats` capability, or AI dismantle allowance.

## 5. Packet Types

**Class**: `zombie.network.PacketTypes` [pub]
**Enum**: `PacketTypes.PacketType`

Each packet has: priority, reliability, ordering channel, required Capability, handling type
bitmask (Server=1, Client=2, ClientLoading=4), optional AntiCheat array.

### Ordering Channels
| Constant | Value | Purpose |
|-|-|-|
| `PacketOrdering_General` | 0 | Default channel |
| `PacketOrdering_Items` | 1 | Inventory operations |
| `PacketOrdering_ServerCustomization` | 2 | Server setup data |
| `PacketOrdering_Object` | 3 | World object changes |
| `PacketOrdering_Map` | 4 | Map/chunk data |
| `PacketOrdering_Player` | 5 | Player state |
| `PacketOrdering_Animal` | 7 | Animal updates |
| `PacketOrdering_Vehicle` | 8 | Vehicle updates |

### Connection Packets
| Packet | Purpose |
|-|-|
| `Checksum` | File integrity validation |
| `Validate` | Recipe validation |
| `Login` | Authentication credentials |
| `LoginQueueRequest` / `LoginQueueDone` | Queue management |
| `LoadPlayerProfile` | Load saved character |
| `CreatePlayer` | New character creation |
| `PlayerConnect` / `ConnectedPlayer` | Connection handshake |
| `ConnectCoop` / `ConnectedCoop` | Coop-specific handshake |
| `GoogleAuth*` | 2FA authentication |
| `ServerCustomization` | Server settings to client |
| `MetaData` | World metadata |
| `AccessDenied` | Rejection with reason |
| `Kicked` | Kick notification |

### Player Packets
| Packet | Purpose |
|-|-|
| `PlayerUpdateReliable` | Guaranteed player state (health, stats) |
| `PlayerUpdateUnreliable` | Position/animation (can be dropped) |
| `PlayerDataRequest` | Request another player's data |
| `PlayerDeath` | Death notification |
| `PlayerDamage` / `PlayerHealth` / `PlayerInjuries` | Damage system |
| `PlayerStats` / `PlayerEffects` / `PlayerXp` | Character progression |
| `SyncPlayerStats` / `SyncPlayerFields` | Field synchronization |
| `HumanVisual` / `SyncClothing` / `SyncVisuals` | Appearance |
| `Equip` | Equipment changes |
| `BodyDamageUpdate` / `BodyPartSync` | Injury details |
| `ClothingWetness` | Wetness state |

### Zombie Packets
| Packet | Purpose |
|-|-|
| `ZombieList` | Bulk zombie data |
| `ZombieSimulationUnreliable/Reliable` | AI simulation sync |
| `ZombieSynchronizationUnreliable/Reliable` | State sync |
| `ZombieDelete` / `ZombieDeleteOnClient` | Removal |
| `ZombieRequest` | Client requests zombie data |
| `ZombieDeath` | Death notification |
| `ZombieControl` | Ownership transfer |
| `Thump` | Zombie attacking objects |
| `SlowFactor` | Movement modifiers |

### Animal Packets
| Packet | Purpose |
|-|-|
| `AnimalPacket` / `AnimalCommand` / `AnimalOwnership` | Animal management |
| `AnimalUpdateReliable/Unreliable` | Animal state sync |
| `AnimalEvent` / `AnimalDeath` | Events and death |
| `AnimalTracks` / `AddTrack` | Tracking system |

### Vehicle Packets
| Packet | Purpose |
|-|-|
| `VehicleRequest` / `VehicleFullUpdate` / `VehicleUpdate` | Vehicle state |
| `VehiclePhysicsReliable/Unreliable` | Physics simulation |
| `VehicleTowingAttach/Detach/State` | Towing system |
| `VehicleRemove` / `VehicleCollide` | Removal and collision |
| `VehiclePassengerPosition/Request/Response` | Seat management |
| `VehicleEnter` / `VehicleExit` / `VehicleSwitchSeat` | Occupancy |

### Hit/Combat Packets
| Packet | Purpose |
|-|-|
| `PlayerHitSquare/Object/Vehicle/Zombie/Player/Animal` | Player attacks |
| `ZombieHitPlayer/Thumpable` | Zombie attacks |
| `AnimalHitPlayer/Animal/Thumpable` | Animal attacks |
| `VehicleHitZombie/Player/Animal` | Vehicle collisions |
| `AttackCollisionCheckPacket` | Hit validation |

### World/Object Packets
| Packet | Purpose |
|-|-|
| `ServerMap` / `RequestLargeAreaZip` / `SentChunk` | Map streaming |
| `RequestZipList` / `NotRequiredInZip` | Chunk management |
| `ObjectChange` / `ObjectModData` | World object mutations |
| `AddItemToMap` / `RemoveItemFromSquare` | World items |
| `StartFire` / `StopFire` | Fire system |
| `SyncThumpable` / `SyncNonPvpZone` | Object state |
| `GlobalObjects` | Global object system |
| `SledgehammerDestroy` | Destruction |

### Inventory Packets
| Packet | Purpose |
|-|-|
| `AddInventoryItemToContainer` | Add item to container |
| `RemoveInventoryItemFromContainer` | Remove item |
| `ReplaceInventoryItemInContainer` | Replace item |
| `SyncItemDelete/Fields/ModData` | Item state sync |
| `RequestItemsForContainer` | Request container contents |
| `ItemTransaction` | Atomic item operations |
| `ItemStats` / `AddItemInInventory` | Item metadata |

### Service/Admin Packets
| Packet | Purpose |
|-|-|
| `TimeSync` / `SyncClock` | Time synchronization |
| `StartPause` / `StopPause` | Server pause |
| `SandboxOptions` | Sandbox settings sync |
| `Statistics` / `ScoreboardUpdate` | Server stats |
| `Weather` / `ClimateManagerPacket` | Weather sync |
| `ClientCommand` | Lua mod command system |
| `ReceiveModData` / `GlobalModData*` | Mod data sync |
| `GameEntity` / `SyncEntityResource` | B42 entity system |

## 6. Packet Infrastructure

### INetworkPacket Interface
All typed packets implement `INetworkPacket` with:
- `parseServer(bb, connection)` - deserialize on server
- `parseClient(bb, connection)` - deserialize on client
- `processServer(type, connection)` - execute server logic
- `processClient(connection)` - execute client logic
- `isConsistent(connection)` - validate packet integrity
- `isPostponed()` / `postpone()` - deferred processing
- `sync(type, connection)` - send corrective state on validation failure
- `getDescription()` - debug string

### PacketSetting Annotation
`@PacketSetting` on INetworkPacket classes defines:
- `priority()` - RakNet send priority (0-2)
- `reliability()` - delivery guarantee (0=unreliable, 2=reliable ordered)
- `ordering()` - channel byte for ordered delivery
- `requiredCapability()` - `Capability` enum for authorization
- `handlingType()` - bitmask: Server=1, Client=2, ClientLoading=4, All=7
- `anticheats()` - array of `AntiCheat` checks

### Packet Dispatch Flow (Server)
1. `UdpEngine` receives raw bytes, creates `ZomboidNetData`
2. Queued to `MainLoopNetDataQ` (thread-safe)
3. Server main loop polls queue
4. `PacketType.onServerPacket()`: checks authorization via `PacketAuthorization`,
   invokes handler's `parseServer()`, runs `isConsistent()`, checks anti-cheats,
   then calls `processServer()`

### Packet Dispatch Flow (Client)
1. `UdpEngine` receives raw bytes on network thread
2. Queued to `MainLoopNetDataQ`
3. `GameClient.update()` polls queue on main thread
4. `PacketType.onClientPacket()`: calls `parseClient()`, checks `isConsistent()`,
   handles postponement or calls `processClient()`

## 7. Sync Mechanisms

### Object Sync
- `ObjectChange` packet carries world object mutations (door state, etc.)
- `ObjectModData` syncs per-object mod data tables
- `SyncIsoObject` sends full object state
- `ChunkObjectState` syncs objects within chunks
- Server is authoritative for world object state

### Player Sync
- `PlayerUpdateReliable` - guaranteed delivery for stats, health, perks
- `PlayerUpdateUnreliable` - position, animation, facing (dropped if stale)
- `BodyDamageSync` handles detailed injury state
- `SyncPlayerStats` / `SyncPlayerFields` for periodic full syncs

### Zombie Sync
- Server owns zombie simulation. Clients get `ZombieSimulation*` packets.
- `ZombieControl` transfers simulation authority to nearby clients
- `ZombieSynchronization*` keeps remote zombies in sync
- Unreliable variants for position, reliable for state changes

### Vehicle Sync
- `VehiclePhysicsUnreliable` - position/velocity at high frequency
- `VehiclePhysicsReliable` - damage, part state
- `VehicleFullUpdate` - complete vehicle state on first load
- Driver's client is semi-authoritative for physics

### ModData Sync
- `ReceiveModData` / `GetModData` - per-object mod data
- `GlobalModData` / `GlobalModDataRequest` - global shared tables
- `SyncItemModData` - per-item mod data

### Time Sync
- `TimeSync` aligns game clock between server and clients
- `SyncClock` provides authoritative time state
- `serverPredictedAhead` on client compensates for latency

## 8. Authority Model

### Server-Authoritative
| System | Details |
|-|-|
| Zombie spawning/deletion | Server controls population via `ZombiePopulationManager` |
| World object state | All `ObjectChange` validated server-side |
| Inventory transactions | `ItemTransaction` with server validation |
| Weather/climate | Server sends `Weather`/`ClimateManagerPacket` |
| Safehouse ownership | Server validates all claims |
| Sandbox options | Server holds authoritative settings |
| Bans/kicks | Server-only via `BanSystem` |
| Time progression | Server-authoritative, synced via `TimeSync` |
| Login/auth | Server validates via `ServerWorldDatabase` |

### Client-Authoritative (with anti-cheat)
| System | Details |
|-|-|
| Player movement | Client sends position, server validates speed via `AntiCheatSpeed` |
| Player combat | Client reports hits, server validates via `AntiCheatHit*` checks |
| Player health/stats | Client sends changes, some server validation |

### Delegated Authority
| System | Details |
|-|-|
| Zombie simulation | Server delegates to nearby clients via `ZombieControl` |
| Vehicle physics | Driver's client simulates, sends state to server |
| Animal simulation | Similar delegation model to zombies |

### Anti-Cheat System
`zombie.network.anticheats` package provides validation:
- `AntiCheatSpeed` - movement speed limits
- `AntiCheatNoClip` - collision/terrain checks
- `AntiCheatHitDamage/LongDistance/ShortDistance` - combat validation
- `AntiCheatHitWeaponAmmo/Range/Rate` - weapon checks
- `AntiCheatFire/Smoke` - fire exploit prevention
- `AntiCheatXP/Transaction/Recipe` - economy validation
- `AntiCheatChecksum` - file integrity
- `PacketValidator` - per-connection rate limiting

## 9. Key Networking Classes

| Class | Package | Purpose |
|-|-|-|
| `GameClient` | network | Client-side network manager (singleton) |
| `GameServer` | network | Server-side network manager, entry point |
| `PacketTypes` | network | All packet type definitions and dispatch |
| `PacketSetting` | network | Annotation for packet configuration |
| `IConnection` | network | Connection interface (MP and SP) |
| `INetworkPacket` | network.packets | Base interface for typed packets |
| `ConnectionManager` | network | Client connection request queue |
| `TableNetworkUtils` | network | KahluaTable serialization for commands |
| `NetworkVariables` | network | Enums: ZombieState, ThumpType, WalkType |
| `NetworkAIParams` | network | AI parameter sync |
| `ServerWorldDatabase` | network | Player accounts, bans, world DB |
| `ServerOptions` | network | Server configuration (INI-based) |
| `ServerLOS` | network | Server-side line of sight |
| `ServerMap` | network | Server-side map management |
| `ServerChunkLoader` | network | Chunk streaming to clients |
| `PlayerDownloadServer` | network | Large data transfer to clients |
| `LoginQueue` | network | Connection queue management |
| `BanSystem` | network | IP and Steam ID bans |
| `BodyDamageSync` | network | Injury synchronization |
| `ClientServerMap` | network | Client's loaded cell tracking |
| `UdpConnection` (spnetwork) | spnetwork | Singleplayer connection stub |
| `SinglePlayerClient` | spnetwork | SP client stub |
| `SinglePlayerServer` | spnetwork | SP server stub |
| `UdpEngine` (spnetwork) | spnetwork | SP network engine stub |
| `CoopMaster` | network | Host-side coop management |
| `CoopSlave` | network | Server-side coop management |
| `ChatServer` | network.chat | Server-side chat handling |
| `RCONServer/Client` | network | Remote console protocol |
| `FakeClientManager` | network | Bot/test client management |
| `StatisticManager` | network.statistics | Network stats collection |
| `PingManager` | network.statistics | Ping measurement |
