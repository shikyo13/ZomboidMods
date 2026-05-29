# Lua Global Functions (World & Gameplay) - PZ Data Map
Source: projectzomboid.jar (decompiled) + media/lua | Generated: 2026-03-22

All functions registered via `@LuaMethod(global=true)` in `zombie.Lua.LuaManager.GlobalObject`.
Availability: C = Client, S = Server, B = Both. Types are Java types exposed to Kahlua2.

See also: [lua-globals-utility.md](lua-globals-utility.md) for items, networking, I/O, input, rendering, admin, debug, and misc utilities.

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Core World Access | 26-45 |
| 2 | Player & Character | 47-72 |
| 3 | Game State & Timing | 74-98 |
| 4 | Network Environment | 100-120 |
| 5 | Zombie & Horde Spawning | 122-142 |
| 6 | Vehicle Functions | 144-166 |
| 7 | Sound & Audio | 168-191 |
| 8 | Map & Zone | 193-211 |
| 9 | Weather & Climate | 213-226 |
| 10 | Cosmetics & Outfits | 228-251 |
| 11 | Action & Transaction System | 253-276 |

---

## 1. Core World Access

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getWorld | `getWorld()` | IsoWorld | Get the world instance | B |
| getCell | `getCell()` | IsoCell | Get the current cell | B |
| getSquare | `getSquare(int x, int y, int z)` | IsoGridSquare | Get grid square at coords | B |
| getCellSizeInChunks | `getCellSizeInChunks()` | int | Cell dimension in chunks | B |
| getCellSizeInSquares | `getCellSizeInSquares()` | int | Cell dimension in squares | B |
| getChunkSizeInSquares | `getChunkSizeInSquares()` | int | Chunk dimension in squares | B |
| getMinimumWorldLevel | `getMinimumWorldLevel()` | int | Lowest Z-level | B |
| getMaximumWorldLevel | `getMaximumWorldLevel()` | int | Highest Z-level | B |
| getCellMinX | `getCellMinX()` | int | Current cell min X coord | B |
| getCellMaxX | `getCellMaxX()` | int | Current cell max X coord | B |
| getCellMinY | `getCellMinY()` | int | Current cell min Y coord | B |
| getCellMaxY | `getCellMaxY()` | int | Current cell max Y coord | B |
| getSandboxOptions | `getSandboxOptions()` | SandboxOptions | Access SandboxVars | B |
| getGameTime | `getGameTime()` | GameTime | Get GameTime singleton | B |

---

## 2. Player & Character

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getPlayer | `getPlayer()` | IsoPlayer | Get local player (splitscreen idx 0) | C |
| getSpecificPlayer | `getSpecificPlayer(int idx)` | IsoPlayer | Get splitscreen player by index | C |
| getNumActivePlayers | `getNumActivePlayers()` | int | Count active splitscreen players | C |
| getMaxActivePlayers | `getMaxActivePlayers()` | int | Max supported splitscreen players | C |
| getPlayerScreenLeft | `getPlayerScreenLeft(int idx)` | int | Splitscreen viewport left | C |
| getPlayerScreenTop | `getPlayerScreenTop(int idx)` | int | Splitscreen viewport top | C |
| getPlayerScreenWidth | `getPlayerScreenWidth(int idx)` | int | Splitscreen viewport width | C |
| getPlayerScreenHeight | `getPlayerScreenHeight(int idx)` | int | Splitscreen viewport height | C |
| getPlayerByOnlineID | `getPlayerByOnlineID(short id)` | IsoPlayer | Find player by network ID | B |
| getPlayerFromUsername | `getPlayerFromUsername(String name)` | IsoPlayer | Find player by username | S |
| getOnlinePlayers | `getOnlinePlayers()` | ArrayList | All connected players | B |
| getConnectedPlayers | `getConnectedPlayers()` | ArrayList | All connected players list | S |
| getOnlineUsername | `getOnlineUsername()` | String | Current player display name | C |
| getClientUsername | `getClientUsername()` | String | Current client username | C |
| isValidUserName | `isValidUserName(String user)` | boolean | Validate username format | S |
| setPlayerMovementActive | `setPlayerMovementActive(boolean b)` | void | Enable/disable player movement | C |
| setActivePlayer | `setActivePlayer(int idx)` | void | Set active splitscreen player | C |
| getFakeAttacker | `getFakeAttacker()` | IsoGameCharacter | Get fake zombie for hit testing | C |
| getBehaviourDebugPlayer | `getBehaviourDebugPlayer()` | IsoGameCharacter | Debug AI target (always nil) | B |
| setBehaviorStep | `setBehaviorStep(boolean b)` | void | Toggle AI step mode | B |

---

## 3. Game State & Timing

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getGameSpeed | `getGameSpeed()` | int | Current game speed (1-3) | B |
| setGameSpeed | `setGameSpeed(int speed)` | void | Set game speed | B |
| stepForward | `stepForward()` | void | Advance one tick while paused | B |
| isGamePaused | `isGamePaused()` | boolean | Check if game is paused | B |
| getTimestamp | `getTimestamp()` | long | System time seconds since epoch | B |
| getTimestampMs | `getTimestampMs()` | long | System time milliseconds | B |
| getGametimeTimestamp | `getGametimeTimestamp()` | long | In-game time timestamp | B |
| getTimeInMillis | `getTimeInMillis()` | long | System.currentTimeMillis() | B |
| getHourMinute | `getHourMinute()` | String | Current time as "HH:MM" | B |
| isIngameState | `isIngameState()` | boolean | True if in gameplay state | B |
| isQuitCooldown | `isQuitCooldown()` | boolean | True if quit cooldown active | C |
| getAverageFPS | `getAverageFPS()` | float | Current average FPS | C |
| getCPUTime | `getCPUTime()` | float | CPU frame time ms | C |
| getGPUTime | `getGPUTime()` | float | GPU frame time ms | C |
| getCPUWait | `getCPUWait()` | float | CPU wait time ms | C |
| getGPUWait | `getGPUWait()` | float | GPU wait time ms | C |
| getServerFPS | `getServerFPS()` | float | Server tick rate | S |
| getGameVersion | `getGameVersion()` | String | Current game version string | B |
| getBreakModGameVersion | `getBreakModGameVersion()` | String | Version that breaks mods | B |

---

## 4. Network Environment

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| isClient | `isClient()` | boolean | True if running as MP client | B |
| isServer | `isServer()` | boolean | True if running as MP server | B |
| isServerSoftReset | `isServerSoftReset()` | boolean | True during soft reset | S |
| isMultiplayer | `isMultiplayer()` | boolean | True if in any MP mode | B |
| isCoopHost | `isCoopHost()` | boolean | True if hosting co-op | B |
| isAdmin | `isAdmin()` | boolean | True if local player is admin | C |
| isAccessLevel | `isAccessLevel(String level)` | boolean | Check player access level | C |
| getAccessLevel | `getAccessLevel()` | String | Get current access level string | C |
| haveAccess | `haveAccess(String level)` | boolean | Check if player has access | C |
| canSeePlayerStats | `canSeePlayerStats()` | boolean | Can view other player stats | C |
| getServerOptions | `getServerOptions()` | ServerOptions | Access server config | S |
| getServerName | `getServerName()` | String | Current server name | B |
| getServerIP | `getServerIP()` | String | Server IP address | C |
| getServerPort | `getServerPort()` | String | Server port | C |
| getMaxPlayers | `getMaxPlayers()` | int | Max players allowed | S |

---

## 5. Zombie & Horde Spawning

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| createZombie | `createZombie(float x, float y, float z, SurvivorDesc desc, int palette, IsoDirections dir)` | IsoZombie | Spawn single zombie | B |
| spawnHorde | `spawnHorde(int x, int y, int count)` | void | Spawn horde at location | S |
| createHordeFromTo | `createHordeFromTo(int x1, int y1, int x2, int y2)` | void | Create horde moving between points | S |
| createHordeInAreaTo | `createHordeInAreaTo(int sx, int sy, int sw, int sh, int tx, int ty)` | void | Create horde in area moving to target | S |
| addVirtualZombie | `addVirtualZombie(int x, int y)` | void | Add virtual zombie to population | S |
| addZombiesInOutfit | `addZombiesInOutfit(int x, int y, int z, int count, String outfit, ...)` | void | Spawn zombies with outfit (5 overloads) | B |
| addZombiesInOutfitArea | `addZombiesInOutfitArea(int x, int y, int z, int w, int h, int count, String outfit)` | void | Spawn zombies in area with outfit | B |
| addZombiesInBuilding | `addZombiesInBuilding(IsoBuilding building, int count, String outfit)` | void | Spawn zombies inside building | B |
| addZombieSitting | `addZombieSitting(IsoGridSquare sq, IsoDirections dir)` | IsoZombie | Spawn seated zombie | B |
| addZombiesEating | `addZombiesEating(IsoGridSquare sq, int count)` | void | Spawn eating zombie group | B |
| createRandomDeadBody | `createRandomDeadBody(int x, int y, int z)` | IsoDeadBody | Create random corpse | B |
| zpopSpawnTimeToZero | `zpopSpawnTimeToZero()` | void | Force immediate zpop spawn | B |
| zpopClearZombies | `zpopClearZombies(int x, int y)` | void | Clear zombies from zpop cell | B |
| zpopSpawnNow | `zpopSpawnNow()` | void | Force zpop to spawn immediately | B |
| setAggroTarget | `setAggroTarget(int x, int y, int z)` | void | Set zombie aggro target point | B |

---

## 6. Vehicle Functions

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| addVehicle | `addVehicle(String type, IsoDirections dir, String skin, IsoGridSquare sq)` | BaseVehicle | Spawn vehicle at square | B |
| addVehicleDebug | `addVehicleDebug(String type, IsoDirections dir, String skin, IsoGridSquare sq)` | BaseVehicle | Spawn debug vehicle | B |
| getVehicleById | `getVehicleById(int id)` | BaseVehicle | Find vehicle by ID | B |
| removeVehicle | `removeVehicle(BaseVehicle vehicle)` | void | Remove vehicle from world | B |
| removeAllVehicles | `removeAllVehicles()` | void | Remove all vehicles | B |
| addAllVehicles | `addAllVehicles()` | void | Spawn all vehicle types (debug) | B |
| addAllBurntVehicles | `addAllBurntVehicles()` | void | Spawn all burnt variants (debug) | B |
| addAllSmashedVehicles | `addAllSmashedVehicles()` | void | Spawn all smashed variants (debug) | B |
| getAllVehicles | `getAllVehicles()` | ArrayList | All vehicle script definitions | B |
| attachTrailerToPlayerVehicle | `attachTrailerToPlayerVehicle(IsoPlayer player)` | void | Attach nearby trailer | C |
| sendSwitchSeat | `sendSwitchSeat(IsoPlayer player, int seat)` | void | Request seat change | C |
| toggleVehicleRenderToTexture | `toggleVehicleRenderToTexture()` | void | Toggle vehicle render mode | C |
| reloadVehicles | `reloadVehicles()` | void | Reload all vehicle scripts | B |
| reloadVehicleTextures | `reloadVehicleTextures(String vehicleType)` | void | Reload textures for vehicle type | B |
| reloadEngineRPM | `reloadEngineRPM()` | void | Reload engine RPM configs | B |
| addCarCrash | `addCarCrash(IsoGridSquare sq, IsoDirections dir)` | void | Spawn crashed car scene | B |
| sendHitVehicle | `sendHitVehicle(IsoGameCharacter target, String dmg, boolean fromBehind, String vDmg, String vSpeed, boolean vFromBehind)` | void | Send vehicle hit packet | C |

---

## 7. Sound & Audio

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getSoundManager | `getSoundManager()` | BaseSoundManager | Get sound manager | B |
| getWorldSoundManager | `getWorldSoundManager()` | WorldSoundManager | Get world sound manager | B |
| AddWorldSound | `AddWorldSound(IsoPlayer player, int radius, int volume)` | void | Emit world-audible sound | B |
| AddNoiseToken | `AddNoiseToken(IsoGridSquare sq, int radius)` | void | Add noise token to square | B |
| addSound | `addSound(IsoObject source, int x, int y, int z, int radius, int volume)` | void | Add positional sound | B |
| sendPlaySound | `sendPlaySound(IsoPlayer player, String sound, int distance)` | void | Sync sound to nearby players | C |
| playServerSound | `playServerSound(String sound, IsoGridSquare sq)` | void | Play sound from server | S |
| getBaseSoundBank | `getBaseSoundBank()` | String | Base sound bank path | B |
| getFMODSoundBank | `getFMODSoundBank()` | String | FMOD sound bank path | B |
| getFMODEventPathList | `getFMODEventPathList()` | ArrayList | All FMOD event paths | B |
| isSoundPlaying | `isSoundPlaying(long handle)` | boolean | Check if sound handle playing | B |
| stopSound | `stopSound(long handle)` | void | Stop sound by handle | B |
| pauseSoundAndMusic | `pauseSoundAndMusic()` | void | Pause all audio | C |
| resumeSoundAndMusic | `resumeSoundAndMusic()` | void | Resume all audio | C |
| testSound | `testSound(String name)` | long | Play sound for testing | C |
| reloadSoundFiles | `reloadSoundFiles()` | void | Reload all sound definitions | B |
| getAmbientStreamManager | `getAmbientStreamManager()` | AmbientStreamManager | Get ambient stream manager | C |
| getSLSoundManager | `getSLSoundManager()` | SLSoundManager | Get SL sound manager (nil) | B |

---

## 8. Map & Zone

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getZone | `getZone(int x, int y, int z)` | IsoMetaGrid.Zone | Get zone at coords | B |
| getZones | `getZones(int x, int y, int z)` | ArrayList | All zones at coords | B |
| getVehicleZoneAt | `getVehicleZoneAt(int x, int y, int z)` | IsoMetaGrid.Zone | Vehicle zone at coords | B |
| setSpawnRegion | `setSpawnRegion(int x, int y, String region)` | void | Set spawn region | S |
| getServerSpawnRegions | `getServerSpawnRegions()` | KahluaTable | Available spawn regions | S |
| createTile | `createTile(String tileName, IsoGridSquare sq)` | IsoObject | Place tile sprite on square | B |
| replaceWith | `replaceWith(IsoObject obj, String sprite)` | void | Replace object sprite | B |
| sledgeDestroy | `sledgeDestroy(IsoObject obj)` | void | Sledgehammer destroy object | B |
| resetRegionFile | `resetRegionFile(int rx, int ry)` | void | Reset region file | S |
| createRegionFile | `createRegionFile(int rx, int ry)` | void | Create new region file | S |
| getLotDirectories | `getLotDirectories()` | ArrayList | Building lot directories | B |
| NewMapBinaryFile | `NewMapBinaryFile(String path)` | Object | Create binary map file | B |
| setMinMaxZombiesPerChunk | `setMinMaxZombiesPerChunk(int min, int max)` | void | Configure zombie density | S |

---

## 9. Weather & Climate

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getClimateManager | `getClimateManager()` | ClimateManager | Access climate system | B |
| getClimateMoon | `getClimateMoon()` | ClimateMoon | Moon phase data | B |
| rainConfig | `rainConfig(float intensity, float duration)` | void | Configure rain (debug) | B |
| forceSnowCheck | `forceSnowCheck()` | void | Force snow recalculation | B |
| useStaticErosionRand | `useStaticErosionRand(boolean b)` | void | Toggle erosion randomness | B |
| getErosion | `getErosion()` | ErosionMain | Access erosion system | B |
| getPuddlesManager | `getPuddlesManager()` | IsoPuddles | Puddles manager | B |
| setPuddles | `setPuddles(float level)` | void | Set puddle level (admin) | B |

---

## 10. Cosmetics & Outfits

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getAllOutfits | `getAllOutfits()` | ArrayList | All outfit definitions | B |
| getAllHairStyles | `getAllHairStyles(boolean female)` | ArrayList | Hair styles for gender | B |
| getHairStylesInstance | `getHairStylesInstance()` | HairStyles | Hair styles manager | B |
| getAllBeardStyles | `getAllBeardStyles()` | ArrayList | All beard styles | B |
| getBeardStylesInstance | `getBeardStylesInstance()` | BeardStyles | Beard styles manager | B |
| getAllVoiceStyles | `getAllVoiceStyles(boolean female)` | ArrayList | Voice styles for gender | B |
| getVoiceStylesInstance | `getVoiceStylesInstance()` | VoiceStyles | Voice styles manager | B |
| getAllItemsForBodyLocation | `getAllItemsForBodyLocation(String loc)` | ArrayList | Clothing items for body slot | B |
| getAllDecalNamesForItem | `getAllDecalNamesForItem(String fullType)` | ArrayList | Decal options for clothing | B |
| sendVisual | `sendVisual(IsoPlayer player)` | void | Sync character visuals | C |
| sendClothing | `sendClothing(IsoPlayer player)` | void | Sync clothing state | C |
| sendHumanVisual | `sendHumanVisual(IsoPlayer player)` | void | Sync human visual data | C |
| sendSyncPlayerFields | `sendSyncPlayerFields(IsoPlayer player)` | void | Sync all player fields | C |
| syncVisuals | `syncVisuals(IsoPlayer player)` | void | Full visual sync | C |
| sendEquip | `sendEquip(IsoPlayer player)` | void | Sync equipped items | C |
| sendDamage | `sendDamage(IsoPlayer player)` | void | Sync damage state | C |
| sendPlayerEffects | `sendPlayerEffects(IsoPlayer player)` | void | Sync player effects | C |
| sendItemStats | `sendItemStats(IsoPlayer player)` | void | Sync held item stats | C |

---

## 11. Action & Transaction System

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| createItemTransaction | `createItemTransaction(IsoPlayer player, String type, ItemContainer container)` | int | Start item transaction, returns ID | B |
| createItemTransactionWithPosData | `createItemTransactionWithPosData(IsoPlayer player, String type, ItemContainer container, float x, float y, float z)` | int | Transaction with position | B |
| changeItemTypeTransaction | `changeItemTypeTransaction(IsoPlayer player, InventoryItem item, String newType)` | int | Change item type transaction | B |
| removeItemTransaction | `removeItemTransaction(IsoPlayer player, InventoryItem item)` | int | Remove item transaction | B |
| isItemTransactionConsistent | `isItemTransactionConsistent(int id)` | boolean | Check transaction consistency | B |
| isItemTransactionDone | `isItemTransactionDone(int id)` | boolean | Check transaction complete | B |
| isItemTransactionRejected | `isItemTransactionRejected(int id)` | boolean | Check transaction rejected | B |
| getItemTransactionDuration | `getItemTransactionDuration(int id)` | float | Transaction elapsed time | B |
| createBuildAction | `createBuildAction(IsoPlayer player, String actionName)` | int | Start build action | B |
| isActionDone | `isActionDone(int id)` | boolean | Build action complete | B |
| isActionRejected | `isActionRejected(int id)` | boolean | Build action rejected | B |
| getActionDuration | `getActionDuration(int id)` | float | Build action elapsed time | B |
| removeAction | `removeAction(int id)` | void | Cancel action | B |
| startFishingAction | `startFishingAction(IsoPlayer player, InventoryItem rod)` | void | Begin fishing | B |
| getPickedUpFish | `getPickedUpFish(IsoPlayer player)` | InventoryItem | Get caught fish item | B |
| emulateAnimEvent | `emulateAnimEvent(IsoGameCharacter chr, String event)` | void | Fire animation event | B |
| emulateAnimEventOnce | `emulateAnimEventOnce(IsoGameCharacter chr, String event)` | void | Fire one-shot anim event | B |
| getSearchMode | `getSearchMode()` | SearchMode | Get foraging search mode | B |
| transmitBigWaterSplash | `transmitBigWaterSplash(IsoPlayer player, float x, float y)` | void | Broadcast splash effect | C |
| addPhysicsObject | `addPhysicsObject(IsoGridSquare sq, String sprite)` | void | Add physics-enabled object | B |
