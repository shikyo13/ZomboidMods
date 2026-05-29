# Zombie Population & World Events - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | ZombiePopulationManager | 19-78 |
| 2 | Virtual Zombie System | 79-116 |
| 3 | Spawning & Materialization | 117-149 |
| 4 | Population Configuration | 150-183 |
| 5 | Zombie State Flags | 184-216 |
| 6 | Loaded Areas & Chunk Tracking | 217-247 |
| 7 | Player Spawn Protection | 248-271 |
| 8 | Horde Spawning & Sounds | 272-302 |
| 9 | RandomizedWorld Event System | 303-338 |
| 10 | Randomized Building Stories | 339-379 |
| 11 | Randomized Zone & Vehicle Stories | 380-481 |

## 1. ZombiePopulationManager

Package: `zombie.popman`

### ZombiePopulationManager [pub final]
Singleton (`instance`) managing all zombie population at the world level. The heavy lifting is done in native code (PZPopMan64.dll/PZPopMan.dylib) with Java acting as the bridge layer.

| Member | Access | Type | Description |
|-|-|-|-|
| instance | [pub static final] | ZombiePopulationManager | Singleton |
| minX, minY | [prot] | int | MetaGrid origin |
| width, height | [prot] | int | World dimensions in cells |
| stopped | [prot] | boolean | Shutdown flag |
| zombiesMinPerChunk | [priv] | float | Min density (default 0) |
| zombiesMaxPerChunk | [priv] | float | Max density (default 255) |
| realZombieCount | [priv] | short[] | Per-cell zombie counts |
| newChunks | [priv] | TIntHashSet | Newly generated chunk keys |
| loadedAreas | [priv] | LoadedAreas | Player-visible areas (chunk-based) |
| loadedServerCells | [priv] | LoadedAreas | Server loaded cells |
| playerSpawns | [priv] | PlayerSpawns | Spawn protection zones |
| spawnOrigins | [priv] | ArrayList\<SpawnOrigin\> | Map spawn origin rects |
| radarXy | [pub] | float[] | Debug radar positions |

### Native Interface
All population simulation runs in native code. Java calls native methods prefixed `n_`:

| Native Method | Purpose |
|-|-|
| n_init(client, server, minX, minY, w, h) | Initialize population grid |
| n_config(...) | Set population parameters |
| n_configFloat(name, value) | Set named float param |
| n_configInt(name, value) | Set named int param |
| n_setSpawnOrigins(int[]) | Define map spawn rectangles |
| n_setOutfitNames(String[]) | Zombie outfit pool |
| n_updateMain(multiplier, worldAgeHours) | Tick population simulation |
| n_hasDataForThread() | Check if thread work pending |
| n_updateThread() | Process on worker thread |
| n_loadChunk(wx, wy, loaded) | Notify chunk load/unload |
| n_loadedAreas(count, areas, serverCells) | Update visible areas |
| n_addZombie(x,y,z, dir, outfit, state, pathX, pathY) | Add virtual zombie |
| n_aggroTarget(id, x, y) | Set aggro target for virtual zombie |
| n_spawnHorde(sx, sy, sw, sh, tx, ty, count) | Spawn horde at location |
| n_worldSound(x, y, radius, volume) | Notify sound for virtual zombies |
| n_getAddZombieCount() | Count zombies to materialize |
| n_getAddZombieData(offset, buffer) | Read zombie data from native |
| n_realZombieCount(count, data) | Report real zombie counts to native |
| n_save() / n_stop() | Persistence and shutdown |
| n_beginSaveRealZombies / n_saveRealZombies | Save real zombie state |

### Init Process
```
1. System.loadLibrary("PZPopMan64")  -- or PZPopMan on macOS
2. n_init(isClient, isServer, minX, minY, width, height)
3. onConfigReloaded() -> n_configFloat/n_configInt for all sandbox settings
4. n_setOutfitNames(PersistentOutfits names)
5. n_setSpawnOrigins(spawn origin rectangles)
```

Registers a file watcher for `Trigger_Zombie.xml` debug commands (hot-reload horde spawns).

## 2. Virtual Zombie System

### Concept
Zombies exist in two forms:
- **Real zombies** (`IsoZombie`): Full Java objects with AI, rendering, physics
- **Virtual zombies**: Lightweight data in native memory (position, direction, outfit, state flags)

### Virtualization (Real -> Virtual)
When a chunk unloads, real zombies are converted to virtual:

`removeChunkFromWorld(chunk)`:
1. Iterates all grid squares in chunk
2. Skips `indoorZombie` (server) and `reanimatedPlayer` zombies
3. Captures state via `ZombieStateFlags.intFromZombie()`
4. Moving zombies (WalkToward/PathFind state): saved with `pathTargetX/Y`
5. Stationary zombies: saved with `INVALID_PATH_XY` (Integer.MIN_VALUE)
6. Calls `n_addZombie()` to store in native population

`virtualizeZombie(zombie)`:
- Direct virtualization of a single zombie
- Calls `removeFromWorld()` and `removeFromSquare()`

### Materialization (Virtual -> Real)
`updateMain()` processes native-queued zombies:
1. `n_getAddZombieCount()` returns pending materializations
2. `n_getAddZombieData()` fills ByteBuffer with zombie data:
   - float x, y, z
   - byte direction
   - int descriptorID (outfit)
   - int stateFlags
   - int pathTargetX, pathTargetY
3. Skip if in newChunk room (avoid spawning in newly generated interiors)
4. Edge-of-loaded-area zombies lose path targets (prevent walking off-map)
5. Route to `addZombieStanding()` or `addZombieMoving()`

### Real Zombie Count Sync
Every 5 seconds, Java counts real zombies per cell and reports to native via `n_realZombieCount()`. This lets native code adjust virtual population to maintain correct density.

## 3. Spawning & Materialization

### addZombieStanding(x, y, z, dir, descriptorID, state)
1. Validate grid square exists and has solid floor
2. Check player spawn protection (`playerSpawns.allowZombie()`)
3. 1/3 chance: find wall square within 3-tile radius for sitting zombie
4. Call `VirtualZombieManager.instance.createRealZombieAlways()`
5. Apply state flags:
   - `FakeDead`: health 0.5-0.8, use legs sprite
   - `Crawling`: set crawler, onFloor, fallOnFront, "ZombieWalk" variant
   - `CanCrawlUnderVehicle`: from saved state
   - `ReanimatedForGrappleOnly`: from saved state
6. If not `Initialized`: call `firstTimeLoaded()` for initial setup

### addZombieMoving(x, y, z, dir, descriptorID, state, pathX, pathY)
1. Same validation as standing
2. Create real zombie via VirtualZombieManager
3. Apply crawler state if flagged
4. If path target > 1 tile away: `pathToLocation()` with `allowRepathDelay = -1`
5. Set last heard sound to path target (maintains pursuit behavior)

### Sitting Against Walls
`sitAgainstWall(zombie, square)`:
1. Center zombie on square (x+0.5, y+0.5)
2. Read wall type bitmask: N(1), S(2), E(4), W(8)
3. Calculate valid sitting directions from wall combination:
   - Corner walls -> diagonal directions (SE, SW, NE, NW)
   - Single walls -> perpendicular direction
4. Pick random direction (deterministic on client based on square coords)
5. Set animation facing direction

`getSquareForSittingZombie()`: searches 3-tile radius for wall square with clear line-of-sight.

## 4. Population Configuration

### Sandbox Settings Applied
`onConfigReloaded()` pushes these to native:

| Setting | Native Key | Description |
|-|-|-|
| populationMultiplier | PopulationMultiplier | Overall zombie density scale |
| populationStartMultiplier | PopulationStartMultiplier | Day-1 population scale |
| populationPeakMultiplier | PopulationPeakMultiplier | Peak population scale |
| populationPeakDay | PopulationPeakDay | Day population peaks |
| respawnHours | RespawnHours | Hours before respawn check |
| respawnUnseenHours | RespawnUnseenHours | Hours area must be unseen |
| respawnMultiplier | RespawnMultiplier | Respawn rate scale |
| redistributeHours | RedistributeHours | Hours before redistribution |
| followSoundDistance | FollowSoundDistance | Virtual zombie hearing range |
| (hardcoded) | MinZombiesPerChunk | From zombiesMinPerChunk field |
| (hardcoded) | MaxZombiesPerChunk | From zombiesMaxPerChunk field (255) |
| (hardcoded) | UniformZombiesPerChunk | 0.2 (uniform distribution floor) |

### Population Curve
The native code implements a population growth curve:
- Day 0: `populationStartMultiplier * populationMultiplier`
- Day `populationPeakDay`: `populationPeakMultiplier * populationMultiplier`
- Linear interpolation between start and peak
- Respawn fills depleted areas after `respawnHours` if unseen for `respawnUnseenHours`

### Sound Propagation to Virtual Zombies
`addWorldSound(sound)`:
- Filters: radius >= 50, not from zombie source, must stress zombies
- Applies hearing multiplier from sandbox `lore.hearing` setting
- Hearing values 4 and 5 treated as 2 (normal)
- Calls `n_worldSound(x, y, scaledRadius, volume)`

## 5. Zombie State Flags

Package: `zombie.popman`

### ZombieStateFlag [pub enum]
Bitmask flags for virtualizing zombie state:

| Flag | Bit | Description |
|-|-|-|
| Initialized | 1 | Has been loaded at least once |
| Crawling | 2 | Is a crawler |
| CanWalk | 4 | Crawler that can stand up |
| FakeDead | 8 | Playing dead |
| CanCrawlUnderVehicle | 16 | Can crawl under vehicles |
| ReanimatedForGrappleOnly | 32 | Only exists for grapple interaction |

### ZombieStateFlags [pub final]
Wrapper class for flag operations.

| Method | Access | Description |
|-|-|-|
| intFromZombie(IsoZombie) | [pub static] | Snapshot zombie state to int |
| fromInt(int) | [pub static] | Reconstruct from saved int |
| fromZombie(IsoZombie) | [pub static] | Create flags instance |
| checkFlag(flag) | [pub] | Test single flag |
| setFlag(flag, boolean) | [pub] | Set/clear single flag |
| isCrawling(), isFakeDead(), etc. | [pub] | Convenience accessors |

### State Preservation
When virtualizing: `intFromZombie()` captures Initialized, Crawling, CanWalk, FakeDead, CanCrawlUnderVehicle, ReanimatedForGrappleOnly.

When materializing: flags restore zombie appearance (crawler sprite, fake-dead pose, etc.) without re-rolling randomization.

## 6. Loaded Areas & Chunk Tracking

### LoadedAreas [pub final]
Tracks rectangular areas of loaded chunks for population management.

| Member | Access | Type | Description |
|-|-|-|-|
| areas | [pub] | int[256] | Packed rectangles (x,y,w,h) x64 |
| count | [pub] | int | Active area count |
| changed | [pub] | boolean | Areas changed since last tick |
| prevAreas | [pub] | int[256] | Previous tick areas |
| MAX_AREAS | [pub static final] | 64 | Maximum tracked areas |

**Area sources:**
- SP: `IsoChunkMap` per player (chunkGridWidth x chunkGridWidth)
- Server: player chunk grids + connection `connectArea` zones
- Server cells mode: `ServerMap.loadedCells`

**Edge detection:** `isOnEdge(x, y)` checks if a square coordinate falls on a chunk boundary within loaded areas. Used to strip path targets from zombies being materialized on area edges (prevents walking into unloaded chunks).

### Chunk Lifecycle
`addChunkToWorld(chunk)`:
- Marks new chunks in `newChunks` set (key: `wy << 16 | wx`)
- Calls `n_loadChunk(wx, wy, true)`

`removeChunkFromWorld(chunk)`:
- Virtualizes all zombies in chunk (see Section 2)
- Calls `n_loadChunk(wx, wy, false)`
- Removes from `newChunks`
- Notifies `MapCollisionData` thread

## 7. Player Spawn Protection

### PlayerSpawns [pkg-priv final]
Prevents zombies from spawning in the player's starting location.

| Member | Access | Description |
|-|-|-|
| playerSpawns | [priv] | ArrayList of spawn locations |

### Protection Levels
Controlled by `SandboxOptions.instance.lore.playerSpawnZombieRemoval`:

| Value | Level | Behavior |
|-|-|-|
| 1 | Building + Vicinity | No zombies in building or within 15 tiles of building bounds |
| 2 | Building Only | No zombies in same building |
| 3 | Room Only | No zombies in same room |
| 4 | None | All zombies allowed |

### Timing
- Protection lasts 10 seconds after spawn (`counter + 10000L > currentTimeMs`)
- `addSpawn()` records coordinate and finds building/room via MetaGrid
- `update()` removes expired spawn protections

## 8. Horde Spawning & Sounds

### Horde Creation
`createHordeFromTo(spawnX, spawnY, targetX, targetY, count)`:
- Delegates to `n_spawnHorde(sx, sy, 0, 0, tx, ty, count)`
- Spawns `count` virtual zombies at (spawnX, spawnY) heading toward (targetX, targetY)

`createHordeInAreaTo(spawnX, spawnY, spawnW, spawnH, targetX, targetY, count)`:
- Spawns across a rectangular area
- Used by debug commands and Lua API

### Trigger System
Hot-reload via `Trigger_Zombie.xml` file watcher:
- `spawnHorde` field: spawn N zombies at player location
- `debugLoggingEnabled` field: toggle verbose logging
- Parsed by `ZombieTriggerXmlFile` XML class

### World Sound Integration
Virtual zombies react to sounds via `n_worldSound()`:
- Only sounds with `radius >= 50` and `stressZombies = true`
- Zombie-sourced sounds filtered out
- Hearing multiplier from sandbox settings applied to radius
- Virtual zombies move toward sound sources in native simulation

### Debug Tools
- `radarXy`/`radarCount`: zombie position radar for debug overlay
- `n_requestRadarData()` / `n_getRadarZombieData()`: async radar fetch
- `MPDebugInfo.instance.serverUpdate()`: multiplayer debug stats
- `ZombiePopulationRenderer`: visual debug overlay
- `DebugCommands`: admin commands (via `PopmanDebugCommandPacket`)

## 9. RandomizedWorld Event System

Package: `zombie.randomizedWorld`

### RandomizedWorldBase [pub]
Base class for all randomized world events. Provides shared utilities for spawning items, zombies, vehicles, and decorating environments.

| Member | Access | Type | Description |
|-|-|-|-|
| minimumDays | [prot] | int | Earliest game day event can appear |
| maximumDays | [prot] | int | Latest game day |
| minimumRooms | [prot] | int | Min rooms in building for building events |
| unique | [prot] | boolean | One-time event |
| name | [prot] | String | Event identifier |
| debugLine | [prot] | String | Debug display text |
| isRat | [prot] | boolean | Rat-related event |
| reallyAlwaysForce | [prot] | boolean | Override day checks |

**Utility methods include:** `addVehicle()`, `addVehicleFlipped()`, `addZombiesOnSquare()`, `addZombie()`, `addItemOnGround()`, `addRandomItemsOnGround()`, `addWorldItem()`, dead body creation, clutter spawning (40+ clutter lists for different room/scenario types).

### Event Categories
| Package | Base Class | Count | Description |
|-|-|-|-|
| randomizedBuilding | RandomizedBuildingBase | 35+ | Interior building stories |
| randomizedDeadSurvivor | RandomizedDeadSurvivorBase | 32+ | Dead survivor scenarios |
| randomizedVehicleStory | RandomizedVehicleStoryBase | 24+ | Road/vehicle events |
| randomizedZoneStory | RandomizedZoneStoryBase | 44+ | Outdoor zone events |
| randomizedRanch | RandomizedRanchBase | 1 | Ranch/farm definitions |

### Clutter System
40+ static ArrayLists pre-populated with item type names (sprites) for decorating scenes. Examples:
- `barnClutter`, `bathroomSinkClutter`, `bedClutter`
- `footballNightDrinks`, `footballNightSnacks`
- `murderSceneClutter`, `survivalistCampsiteClutter`
- `pokerNightClutter`, `housePartyClutter`

## 10. Randomized Building Stories

Package: `zombie.randomizedWorld.randomizedBuilding`

### Notable Building Events
| Class | Description |
|-|-|
| RBBar | Bar scene with drinks and patrons |
| RBBarn | Farm barn with equipment |
| RBBurnt / RBBurntCorpse / RBBurntFireman | Fire aftermath scenarios |
| RBCafe | Cafe with food prep |
| RBClinic | Medical clinic with supplies |
| RBDorm | Dormitory room scenes |
| RBGunstore / RBGunstoreSiege | Gun store, possibly under siege |
| RBHairSalon | Hair salon decoration |
| RBKateAndBaldspot | Easter egg - tutorial characters |
| RBLooted / RBShopLooted | Already-looted buildings |
| RBMayorWestPoint | West Point mayor's office |
| RBOffice | Office building setup |
| RBPizzaWhirled / RBPileOCrepe / RBSpiffo | Restaurant chains |
| RBPoliceSiege | Police station under zombie attack |
| RBSafehouse | Pre-built survivor safehouse |
| RBSchool | School interior |
| RBTrashed | Vandalized/ransacked building |

### Table Stories (Sub-events)
Package: `randomizedBuilding.TableStories`

Small-scale surface decoration events:
| Class | Description |
|-|-|
| RBTSBreakfast | Breakfast setting on table |
| RBTSButcher | Butchering scene |
| RBTSDinner | Dinner table setup |
| RBTSDrink | Drinking scene |
| RBTSElectronics | Electronics repair/hobby |
| RBTSFoodPreparation | Cooking prep scene |
| RBTSSandwich | Sandwich making |
| RBTSSewing | Sewing/tailoring scene |
| RBTSSoup | Soup preparation |

## 11. Randomized Zone & Vehicle Stories

### Vehicle Stories
Package: `zombie.randomizedWorld.randomizedVehicleStory`

Spawned along roads and intersections:
| Class | Description |
|-|-|
| RVSAmbulanceCrash | Ambulance crash with medical supplies |
| RVSAnimalOnRoad / RVSAnimalTrailerOnRoad | Animal-related road events |
| RVSBanditRoad | Bandit roadblock |
| RVSBurntCar | Burned-out vehicle |
| RVSCarCrash / RVSCarCrashCorpse / RVSCarCrashDeer | Vehicle collision variants |
| RVSChangingTire | Tire change in progress |
| RVSConstructionSite | Road construction |
| RVSCrashHorde | Crash site with zombie horde |
| RVSDeadEnd | Dead-end road barricade |
| RVSFlippedCrash | Flipped vehicle |
| RVSHerdOnRoad | Animal herd blocking road |
| RVSPoliceBlockade / RVSPoliceBlockadeShooting | Police roadblocks |
| RVSRegionalProfessionVehicle | Profession-specific vehicle |
| RVSRichJerk | Luxury car with supplies |
| RVSRoadKill / RVSRoadKillSmall | Roadkill scenes |
| RVSTrailerCrash | Trailer accident |
| RVSUtilityVehicle | Work/utility vehicle |

Supporting classes:
- `VehicleStorySpawnData`: spawn parameters per story
- `VehicleStorySpawner`: manages vehicle story placement

### Zone Stories
Package: `zombie.randomizedWorld.randomizedZoneStory`

Outdoor area events, typically in forests, fields, and clearings:
| Class | Description |
|-|-|
| RZSBaseball | Baseball game remnants |
| RZSBBQParty / RZSBeachParty | Party scenes |
| RZSBurntWreck | Burned wreckage |
| RZSBuryingCamp | Burial site |
| RZSCampsite / RZSForestCamp / RZSForestCampEaten | Camping scenarios |
| RZSCharcoalBurner | Charcoal production site |
| RZSFishingTrip | Fishing spot |
| RZSHermitCamp | Isolated hermit camp |
| RZSHillbillyHoedown | Rural party scene |
| RZSHogWild | Pig farm event |
| RZSHunterCamp / RZSTrapperCamp | Hunting/trapping camps |
| RZSMurderScene | Crime scene |
| RZSMusicFest / RZSMusicFestStage | Music festival |
| RZSOccultActivity | Occult/ritual scene |
| RZSRockerParty | Rock party |
| RZSSurvivalistCamp | Survivalist outpost |
| RZSTragicPicnic | Picnic gone wrong |
| RZSVanCamp | Van-based camp |
| RZSWasteDump | Illegal waste dumping |
| RZSWaterPump | Water pump installation |

### Named Character Events
| Class | Character | Description |
|-|-|-|
| RZSDean | Dean | Named survivor story |
| RZSDuke | Duke | Named survivor story |
| RZSFrankHemingway | Frank Hemingway | Writer's camp |
| RZSKirstyKormick | Kirsty Kormick | Named survivor |
| RZSRangerSmith | Ranger Smith | Park ranger station |
| RZSSirTwiggy | Sir Twiggy | Twiggy mascot reference |
| RZSJackieJaye / RBJackieJaye | Jackie Jaye | Cross-building/zone story |
| RBJoanHartford | Joan Hartford | Named building story |
| RBNolans | Nolans | Named building story |
| RBReverend | Reverend | Church story |

### Dead Survivor Scenarios
Package: `zombie.randomizedWorld.randomizedDeadSurvivor`

Found inside buildings as environmental storytelling:
| Class | Description |
|-|-|
| RDSBanditRaid | Bandit attack aftermath |
| RDSBandPractice | Music practice gone wrong |
| RDSBathroomZed / RDSBedroomZed | Zombie in bathroom/bedroom |
| RDSBleach | Bleach drinking suicide |
| RDSCorpsePsycho / RDSHockeyPsycho / RDSSkeletonPsycho | Serial killer scenarios |
| RDSDeadDrunk | Died while drinking |
| RDSDevouredByRats | Rat attack |
| RDSFootballNight | Football watch party |
| RDSGunmanInBathroom / RDSGunslinger | Armed survivor deaths |
| RDSHenDo / RDSStagDo | Party scenarios |
| RDSHouseParty / RDSStudentNight | Social gathering aftermath |
| RDSPokerNight / RDSRPGNight | Game night scenarios |
| RDSPoliceAtHouse | Police raid scene |
| RDSPrisonEscape / RDSPrisonEscapeWithPolice | Prison break scenarios |
| RDSRatInfested / RDSRatKing / RDSRatWar | Rat-related scenarios |
| RDSResourceGarage | Well-stocked garage |
| RDSSpecificProfession | Profession-themed death |
| RDSSuicidePact | Group suicide |
| RDSTinFoilHat | Conspiracy theorist |
| RDSZombieLockedBathroom / RDSZombiesEating | Zombie scenarios |

### Ranch System
Package: `zombie.randomizedWorld.randomizedRanch`
- `RandomizedRanchBase`: base class for ranch/farm events
- `RanchZoneDefinitions`: zone type definitions for ranch areas
