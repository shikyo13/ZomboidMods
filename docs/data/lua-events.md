# Lua Events - PZ Data Map
Source: projectzomboid.jar (decompiled) + media/lua | Generated: 2026-03-22

All events registered via `LuaEventManager.AddEvent()`. Usage: `Events.<Name>.Add(callback)`.
Avail: C = Client, S = Server, B = Both. Types are Java types as seen by Kahlua2.

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Game Lifecycle | 39-58 |
| 2 | Tick & Update | 59-75 |
| 3 | Time & Scheduling | 76-91 |
| 4 | Player | 92-118 |
| 5 | Character & Death | 119-134 |
| 6 | Zombie | 135-147 |
| 7 | Combat & Weapons | 148-162 |
| 8 | Equipment & Clothing | 163-173 |
| 9 | Vehicle | 174-185 |
| 10 | Building & Construction | 186-202 |
| 11 | Inventory & Items | 203-222 |
| 12 | Map & World | 223-242 |
| 13 | Input - Keyboard & Mouse | 243-266 |
| 14 | UI & Context Menus | 267-284 |
| 15 | Weather & Climate | 285-301 |
| 16 | Sound & Radio | 302-316 |
| 17 | Save & Load | 317-331 |
| 18 | Multiplayer Networking | 332-356 |
| 19 | Multiplayer Social | 357-380 |
| 20 | Chat System | 381-394 |
| 21 | Joypad & Gamepad | 395-410 |
| 22 | Rendering | 411-425 |
| 23 | Mod & Debug | 426-437 |
| 24 | Foraging & Animals | 438-454 |
| 25 | Crafting & Recipes | 455-463 |
| 26 | Steam Integration | 464-727 |

---

## 1. Game Lifecycle

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnGameBoot | (none) | C | Application first starts, before any game loads |
| OnPreGameStart | (none) | B | Before game starts, after mods loaded |
| OnGameStart | (none) | B | Game fully started, player exists |
| OnLoad | (none) | B | World finished loading (new or saved) |
| OnNewGame | IsoPlayer player, IsoGridSquare sq | B | New game started (not loaded from save) |
| OnMainMenuEnter | (none) | C | Returned to main menu |
| OnGameStateEnter | (none) | B | Entered a new game state |
| OnInitWorld | (none) | B | World initialization complete |
| OnPreMapLoad | (none) | B | Before map chunks start loading |
| OnPostMapLoad | IsoCell cell, int wx, int wy | B | Map cell finished loading |
| OnCreateUI | (none) | C | UI system initialized |
| OnResetLua | (none) | B | Lua VM reset (hot reload) |
| OnChallengeQuery | (none) | C | Challenge list queried |

---

## 2. Tick & Update

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnTick | double ticks | B | Every game tick (~30/sec at 1x) |
| OnTickEvenPaused | double ticks | B | Every tick, including while paused |
| OnRenderTick | (none) | C | Every render frame |
| OnRenderUpdate | (none) | C | Render update cycle |
| OnFETick | (none) | C | Front-end (menu) tick |
| OnPlayerUpdate | IsoPlayer player | B | Per-player per-tick update |
| OnZombieUpdate | IsoZombie zombie | B | Per-zombie per-tick update |
| OnNPCSurvivorUpdate | IsoSurvivor survivor | B | NPC survivor tick |
| OnClimateTick | ClimateManager climate | B | Climate system tick |
| OnClimateTickDebug | ClimateManager climate | C | Climate debug tick |

---

## 3. Time & Scheduling

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| EveryOneMinute | (none) | B | Every in-game minute |
| EveryTenMinutes | (none) | B | Every 10 in-game minutes |
| EveryHours | (none) | B | Every in-game hour |
| EveryDays | (none) | B | Every in-game day |
| OnDusk | (none) | B | Dusk begins |
| OnDawn | (none) | B | Dawn begins |
| OnGameTimeLoaded | (none) | B | GameTime object available |
| OnInitSeasons | ErosionSeason season | B | Season system initialized |
| OnSleepingTick | double tick, double hours | C | Tick while player is sleeping |

---

## 4. Player

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnCreatePlayer | int playerIdx, IsoPlayer player | B | Player object created |
| OnCreateLivingCharacter | IsoPlayer player, SurvivorDesc desc | B | Living player character created |
| OnCreateSurvivor | IsoSurvivor survivor | B | NPC survivor created |
| OnPlayerDeath | IsoPlayer player | B | Player dies |
| OnPlayerMove | IsoPlayer player | B | Player position changes |
| OnPlayerGetDamage | IsoGameCharacter player, String type, float damage | B | Player receives damage (type: WEAPONHIT, FIRE, BLEEDING, etc.) |
| OnPlayerSetSafehouse | (none) | B | Player safehouse changed |
| OnCharacterCreateStats | (none) | C | Character creation stats phase |
| AddXP | IsoPlayer player, int perkID, float xp | B | XP awarded to player |
| LevelPerk | IsoPlayer player, int perkID, int level, boolean levelUp | B | Perk level changed |
| OnPlayerAttackFinished | IsoPlayer player, HandWeapon weapon | B | Attack animation completed |
| OnLoginState | (none) | C | Login state entered |
| OnLoginStateSuccess | (none) | C | Login succeeded |
| OnPressReloadButton | IsoPlayer player, HandWeapon weapon | C | Reload key pressed |
| OnPressRackButton | IsoPlayer player, HandWeapon weapon, boolean shift | C | Rack key pressed |
| OnPressWalkTo | int x, int y, int z | C | Walk-to key pressed |
| OnProcessAction | (none) | B | Action system processes queued action |
| OnRolesReceived | (none) | C | Server roles list received |
| OnNetworkUsersReceived | (none) | C | Network user list received |
| OnServerCustomizationDataReceived | (none) | C | Server customization data received |

---

## 5. Character & Death

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnCharacterDeath | IsoGameCharacter character | B | Any character dies (player, zombie, animal) |
| OnCharacterCollide | IsoMovingObject mover, IsoMovingObject other | B | Two characters collide |
| OnCharacterMeet | (none) | B | Characters meet (meta event) |
| OnDeadBodySpawn | IsoDeadBody body | B | Dead body spawned in world |
| OnAIStateChange | IsoGameCharacter owner, State current, State previous | B | AI state machine transition |
| OnAIStateExecute | (none) | B | AI state tick |
| OnAIStateEnter | (none) | B | AI state entered |
| OnAIStateExit | (none) | B | AI state exited |
| OnBeingHitByZombie | (none) | B | Player hit by zombie |

---

## 6. Zombie

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnZombieCreate | IsoZombie zombie | B | Zombie spawned into world |
| OnZombieDead | IsoZombie zombie | B | Zombie killed |
| OnHitZombie | IsoZombie zombie, IsoGameCharacter wielder, BodyPart bodyPart, HandWeapon weapon | B | Zombie hit by weapon |
| OnTriggerNPCEvent | (none) | B | NPC trigger event |
| OnMultiTriggerNPCEvent | (none) | B | Multi-NPC trigger event |
| OnNewSurvivorGroup | (none) | B | New survivor group formed |

---

## 7. Combat & Weapons

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnWeaponHitCharacter | IsoGameCharacter wielder, IsoGameCharacter target, HandWeapon weapon, float damage | B | Weapon hits any character |
| OnWeaponSwing | IsoPlayer player, HandWeapon weapon | B | Weapon swing initiated |
| OnWeaponHitTree | IsoGameCharacter owner, HandWeapon weapon | B | Weapon hits tree |
| OnWeaponHitXp | IsoGameCharacter owner, HandWeapon weapon, IsoObject target, float damage, int count | B | XP awarded for weapon hit |
| OnWeaponSwingHitPoint | IsoGameCharacter owner, HandWeapon weapon | B | Swing reaches hit point in animation |
| OnWeaponHitThumpable | IsoGameCharacter owner, HandWeapon weapon, IsoObject target | B | Weapon hits barricade/thumpable |
| OnThrowableExplode | IsoGridSquare sq, IsoObject thrownItem | B | Throwable item explodes |
| OnMakeItem | (none) | B | Item crafted (legacy, rarely used) |

---

## 8. Equipment & Clothing

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnEquipPrimary | IsoGameCharacter character, InventoryItem item | B | Primary hand item changed |
| OnEquipSecondary | IsoGameCharacter character, InventoryItem item | B | Secondary hand item changed |
| OnClothingUpdated | IsoGameCharacter character | B | Character clothing/visuals changed |
| SetDragItem | (none) | C | Drag-and-drop item set |

---

## 9. Vehicle

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnEnterVehicle | IsoPlayer player | B | Player enters a vehicle |
| OnSpawnVehicleStart | BaseVehicle vehicle | B | Vehicle spawn begins |
| OnSpawnVehicleEnd | BaseVehicle vehicle | B | Vehicle spawn finishes |
| OnVehicleDamageTexture | IsoPlayer driver | B | Vehicle damage texture updated |
| OnMechanicActionDone | IsoGameCharacter character, boolean success | B | Mechanic action completed |

---

## 10. Building & Construction

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnDoTileBuilding | (none) | B | Tile building action phase 1 |
| OnDoTileBuilding2 | (none) | B | Tile building action phase 2 |
| OnDoTileBuilding3 | (none) | B | Tile building action phase 3 |
| OnAddBuilding | int buildingID | B | Building added to world |
| OnDestroyIsoThumpable | IsoThumpable obj | B | Thumpable object destroyed |
| OnIsoThumpableLoad | IsoThumpable obj | B | Thumpable loaded from save |
| OnIsoThumpableSave | IsoThumpable obj | B | Thumpable saved |
| OnObjectAdded | IsoObject obj | B | Object placed in world |
| OnObjectAboutToBeRemoved | IsoObject obj | B | Object about to be removed from world |
| OnTileRemoved | IsoObject obj | B | Tile/object removed from square |

---

## 11. Inventory & Items

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnFillContainer | String roomType, String containerType, ItemContainer container | B | Container loot generated |
| OnRefreshInventoryWindowContainers | (none) | C | Inventory window containers refreshed |
| OnContainerUpdate | (none) | B | Container contents changed |
| OnWaterAmountChange | IsoObject obj, float oldAmount | B | Water container level changed |
| onLoadModDataFromServer | (none) | B | Mod data synced from server |
| OnPreDistributionMerge | (none) | B | Before loot distribution merge |
| OnDistributionMerge | (none) | B | During loot distribution merge |
| OnPostDistributionMerge | (none) | B | After loot distribution merge |
| OnReceiveItemListNet | (none) | C | Network item list received |
| MngInvReceiveItems | (none) | C | Managed inventory items received |
| OnProcessTransaction | (none) | B | Item transaction processed |
| onItemFall | (none) | B | Item falls to ground |
| OnItemFound | (none) | B | Foraging item found |

---

## 12. Map & World

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnLoadMapZones | (none) | B | Map zones loading |
| OnLoadedMapZones | (none) | B | Map zones finished loading |
| LoadGridsquare | IsoGridSquare sq | B | Grid square loaded |
| LoadChunk | IsoChunk chunk | B | Chunk loaded |
| ReuseGridsquare | IsoGridSquare sq | B | Grid square recycled |
| OnMapLoadCreateIsoObject | IsoObject obj | B | Object created during map load |
| OnLoadedTileDefinitions | IsoSpriteManager manager | B | Tile definitions loaded |
| OnSpawnRegionsLoaded | (none) | B | Spawn regions loaded |
| OnSeeNewRoom | RoomDef room | C | Player enters unseen room |
| OnNewFire | IsoFire fire | B | Fire started |
| OnGridBurnt | IsoGridSquare sq | B | Grid square burned |
| OnChangeWeather | (none) | B | Weather state changed |
| OnResolutionChange | (none) | C | Screen resolution changed |

---

## 13. Input - Keyboard & Mouse

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnKeyStartPressed | int keyCode | C | Key initial press (includes 10000+ mouse codes) |
| OnKeyPressed | int keyCode | C | Key pressed this frame |
| OnKeyKeepPressed | int keyCode | C | Key held down continuously |
| OnContextKey | (none) | C | Context menu key pressed |
| OnCustomUIKey | (none) | C | Custom UI key binding pressed |
| OnCustomUIKeyPressed | (none) | C | Custom UI key pressed event |
| OnCustomUIKeyReleased | (none) | C | Custom UI key released |
| OnMouseMove | double mx, double my, double mxWorld, double myWorld | C | Mouse cursor moved |
| OnMouseDown | double mx, double my | C | Left mouse button down |
| OnMouseUp | double mx, double my | C | Left mouse button up |
| OnRightMouseDown | double mx, double my | C | Right mouse button down |
| OnRightMouseUp | double mx, double my | C | Right mouse button up |
| OnMouseWheel | double delta | C | Mouse wheel scrolled |
| OnObjectLeftMouseButtonDown | IsoObject obj, double mx, double my | C | Left click on world object |
| OnObjectLeftMouseButtonUp | IsoObject obj, double mx, double my | C | Left release on world object |
| OnObjectRightMouseButtonDown | IsoObject obj, double mx, double my | C | Right click on world object |
| OnObjectRightMouseButtonUp | IsoObject obj, double mx, double my | C | Right release on world object |

---

## 14. UI & Context Menus

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnFillInventoryObjectContextMenu | int playerIdx, ISContextMenu context, ArrayList items | C | Inventory right-click menu building |
| OnPreFillInventoryObjectContextMenu | int playerIdx, ISContextMenu context, ArrayList items | C | Before inventory context menu |
| OnFillWorldObjectContextMenu | int playerIdx, ISContextMenu context, ArrayList objects, boolean test | C | World right-click menu building |
| OnPreFillWorldObjectContextMenu | int playerIdx, ISContextMenu context, ArrayList objects, boolean test | C | Before world context menu |
| OnClickedAnimalForContext | IsoPlayer player, ISContextMenu context, ArrayList animals, boolean test | C | Animal right-click context |
| DoSpecialTooltip | (none) | C | Special tooltip rendering |
| OnPreUIDraw | (none) | C | Before UI draw pass |
| OnPostUIDraw | (none) | C | After UI draw pass |
| onUpdateIcon | (none) | C | UI icon update |
| onFillSearchIconContextMenu | (none) | C | Search icon context menu |
| OnDynamicMovableRecipe | (none) | C | Moveable object recipe UI |

---

## 15. Weather & Climate

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnWeatherPeriodStart | WeatherPeriod period | B | Weather period begins |
| OnWeatherPeriodStage | WeatherPeriod period | B | Weather period stage change |
| OnWeatherPeriodComplete | WeatherPeriod period | B | Weather period ends |
| OnWeatherPeriodStop | WeatherPeriod period | B | Weather period stopped |
| OnRainStart | (none) | B | Rain begins |
| OnRainStop | (none) | B | Rain stops |
| OnThunderEvent | float x, float y, boolean strike | B | Thunder/lightning event |
| OnClimateManagerInit | ClimateManager manager | B | Climate manager initialized |
| OnInitModdedWeatherStage | (none) | B | Modded weather stage init |
| OnUpdateModdedWeatherStage | (none) | B | Modded weather stage update |

---

## 16. Sound & Radio

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnLoadSoundBanks | (none) | B | Sound banks loading |
| OnAmbientSound | String name, float x, float y | B | Ambient sound triggered |
| OnWorldSound | int x, int y, int z, int radius, int volume, Object source | B | World-audible sound emitted |
| OnDeviceText | String guid, String codes, float x, float y, float z, String line, Object device | B | Radio/TV text output |
| OnRadioInteraction | (none) | B | Player interacts with radio |
| OnLoadRadioScripts | ScriptManager manager, boolean isNew | B | Radio scripts loaded |
| OnInitRecordedMedia | RecordedMedia media | B | Recorded media initialized |
| OnTemplateTextInit | (none) | B | Template text system initialized |

---

## 17. Save & Load

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnSave | (none) | B | Game save triggered |
| OnPostSave | (none) | B | Game save completed |
| OnServerStartSaving | (none) | S | Server save begins |
| OnServerFinishSaving | (none) | S | Server save completes |
| OnInitGlobalModData | boolean isNewGame | B | Global mod data initializing |
| OnReceiveGlobalModData | (none) | B | Global mod data received from server |
| SendCustomModData | (none) | B | Custom mod data being sent |
| OnSourceWindowFileReload | (none) | C | Source file reloaded |

---

## 18. Multiplayer Networking

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnClientCommand | String module, String command, IsoPlayer player, KahluaTable args | S | Client command received on server |
| OnServerCommand | String module, String command, KahluaTable args | C | Server command received on client |
| OnConnected | (none) | C | Connected to server |
| OnConnectFailed | (none) | C | Connection to server failed |
| OnDisconnect | (none) | C | Disconnected from server |
| OnConnectionStateChanged | String state, String msg | C | Connection state changed |
| OnServerStarted | (none) | S | Server finished starting |
| ServerPinged | (none) | C | Server ping response received |
| OnScoreboardUpdate | (none) | C | Scoreboard data updated |
| OnMiniScoreboardUpdate | (none) | C | Mini scoreboard updated |
| OnWorldMessage | (none) | B | World-level message received |
| OnAdminMessage | String msg | C | Admin broadcast received |
| OnCoopJoinFailed | int reason | C | Co-op join attempt failed |
| OnCoopServerMessage | (none) | C | Co-op server message |
| OnServerWorkshopItems | (none) | C | Server Workshop items received |
| OnAcceptInvite | (none) | C | Game invite accepted |
| OnSteamGameJoin | (none) | C | Steam join game event |
| OnServerStatisticReceived | (none) | C | Server statistics received |

---

## 19. Multiplayer Social

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| ReceiveFactionInvite | String faction, String fromPlayer | C | Faction invite received |
| AcceptedFactionInvite | String faction, String player | C | Faction invite accepted |
| SyncFaction | (none) | C | Faction data synced |
| ReceiveSafehouseInvite | String safehouse, String fromPlayer | C | Safehouse invite received |
| AcceptedSafehouseInvite | String safehouse, String player | C | Safehouse invite accepted |
| OnSafehousesChanged | (none) | B | Safehouse data modified |
| OnWarUpdate | (none) | B | War state updated |
| RefreshCheats | (none) | C | Cheat detection refreshed |
| RequestTrade | IsoPlayer fromPlayer | C | Trade request received |
| AcceptedTrade | IsoPlayer fromPlayer | C | Trade request accepted |
| TradingUIAddItem | InventoryItem item | C | Item added to trade window |
| TradingUIRemoveItem | InventoryItem item | C | Item removed from trade window |
| TradingUIUpdateState | int state | C | Trade state changed |
| OnReceiveUserlog | (none) | C | User log data received |
| ViewTickets | (none) | C | Admin tickets viewed |
| ViewBannedIPs | (none) | C | Banned IPs list viewed |
| ViewBannedSteamIDs | (none) | C | Banned Steam IDs viewed |

---

## 20. Chat System

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnChatWindowInit | (none) | C | Chat system initialized |
| OnAddMessage | ChatMessage msg, short tabID | C | Chat message added |
| OnAlertMessage | ChatMessage msg, short tabID | C | Alert message received |
| OnTabAdded | String title, short tabID | C | Chat tab created |
| OnTabRemoved | String title, short tabID | C | Chat tab removed |
| OnSetDefaultTab | String title | C | Default chat tab set |
| SwitchChatStream | (none) | C | Chat stream changed |

---

## 21. Joypad & Gamepad

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnGamepadConnect | int controllerID | C | Gamepad physically connected |
| OnGamepadDisconnect | int controllerID | C | Gamepad physically disconnected |
| OnJoypadActivate | int joypadID | C | Joypad activated for gameplay |
| OnJoypadActivateUI | int joypadID | C | Joypad activated for UI |
| OnJoypadBeforeDeactivate | int joypadID | C | Before joypad deactivation |
| OnJoypadDeactivate | int joypadID | C | Joypad deactivated |
| OnJoypadBeforeReactivate | int joypadID | C | Before joypad reactivation |
| OnJoypadReactivate | int joypadID | C | Joypad reactivated |
| OnJoypadRenderUI | int joypadID | C | Joypad UI render |

---

## 22. Rendering

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnPostRender | (none) | C | After main render pass |
| OnPostFloorSquareDraw | IsoGridSquare sq | C | After floor square drawn |
| OnPostFloorLayerDraw | int z | B | After floor layer drawn |
| OnPostTilesSquareDraw | IsoGridSquare sq | C | After tiles on square drawn |
| OnPostTileDraw | IsoObject tile | C | After individual tile drawn |
| OnPostWallSquareDraw | IsoGridSquare sq | C | After walls on square drawn |
| OnPostCharactersSquareDraw | IsoGridSquare sq | C | After characters on square drawn |
| RenderOpaqueObjectsInWorld | (none) | C | Opaque object render pass |

---

## 23. Mod & Debug

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnModsModified | (none) | B | Mod list changed |
| OnCGlobalObjectSystemInit | (none) | C | Client global object system ready |
| OnSGlobalObjectSystemInit | (none) | S | Server global object system ready |
| OnQRReceived | (none) | C | QR code received (2FA) |
| OnGoogleAuthRequest | (none) | C | Google auth requested |

---

## 24. Foraging & Animals

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| preAddForageDefs | (none) | B | Before forage definitions added |
| preAddSkillDefs | (none) | B | Before skill definitions added |
| preAddZoneDefs | (none) | B | Before zone definitions added |
| preAddCatDefs | (none) | B | Before category definitions added |
| preAddItemDefs | (none) | B | Before item definitions added |
| onAddForageDefs | (none) | B | Forage definitions added |
| OnOverrideSearchManager | (none) | B | Search manager override hook |
| OnAnimalTracks | (none) | B | Animal tracks detected |
| OnMovingObjectCrop | (none) | B | Moving object crop event |
| OnFishingActionMPUpdate | KahluaTable data | B | Fishing action MP sync |

---

## 25. Crafting & Recipes

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnMakeItem | (none) | B | Item crafted (legacy) |
| OnDynamicMovableRecipe | (none) | B | Dynamic moveable recipe triggered |

---

## 26. Steam Integration

| Event | Parameters | Fires On | Purpose |
|-|-|-|-|
| OnSteamServerResponded | (none) | C | Steam server responded to query |
| OnSteamServerResponded2 | (none) | C | Steam server responded (v2) |
| OnSteamServerFailedToRespond2 | (none) | C | Steam server failed to respond (v2) |
| OnSteamRulesRefreshComplete | (none) | C | Server rules query complete |
| OnSteamRefreshInternetServers | (none) | C | Internet server list refreshed |

---

## Quick Reference: All 254 Events (Alphabetical)

| Event | Category |
|-|-|
| AcceptedFactionInvite | Social |
| AcceptedSafehouseInvite | Social |
| AcceptedTrade | Social |
| AddXP | Player |
| DoSpecialTooltip | UI |
| EveryDays | Time |
| EveryHours | Time |
| EveryOneMinute | Time |
| EveryTenMinutes | Time |
| LevelPerk | Player |
| LoadChunk | Map |
| LoadGridsquare | Map |
| MngInvReceiveItems | Inventory |
| OnAIStateChange | Character |
| OnAIStateEnter | Character |
| OnAIStateExecute | Character |
| OnAIStateExit | Character |
| OnAcceptInvite | Network |
| OnAddBuilding | Building |
| OnAddMessage | Chat |
| OnAdminMessage | Network |
| OnAlertMessage | Chat |
| OnAmbientSound | Sound |
| OnAnimalTracks | Foraging |
| OnBeingHitByZombie | Combat |
| OnCGlobalObjectSystemInit | Mod |
| OnChallengeQuery | Lifecycle |
| OnChangeWeather | Weather |
| OnCharacterCollide | Character |
| OnCharacterCreateStats | Player |
| OnCharacterDeath | Character |
| OnCharacterMeet | Character |
| OnChatWindowInit | Chat |
| OnClickedAnimalForContext | UI |
| OnClimateTick | Tick |
| OnClimateTickDebug | Tick |
| OnClimateManagerInit | Weather |
| OnClothingUpdated | Equipment |
| OnConnectFailed | Network |
| OnConnected | Network |
| OnConnectionStateChanged | Network |
| OnContainerUpdate | Inventory |
| OnContextKey | Input |
| OnCoopJoinFailed | Network |
| OnCoopServerMessage | Network |
| OnCreateLivingCharacter | Player |
| OnCreatePlayer | Player |
| OnCreateSurvivor | Player |
| OnCreateUI | Lifecycle |
| OnCustomUIKey | Input |
| OnCustomUIKeyPressed | Input |
| OnCustomUIKeyReleased | Input |
| OnDawn | Time |
| OnDeadBodySpawn | Character |
| OnDestroyIsoThumpable | Building |
| OnDeviceText | Sound |
| OnDisconnect | Network |
| OnDistributionMerge | Inventory |
| OnDoTileBuilding | Building |
| OnDoTileBuilding2 | Building |
| OnDoTileBuilding3 | Building |
| OnDusk | Time |
| OnDynamicMovableRecipe | Crafting |
| OnEquipPrimary | Equipment |
| OnEquipSecondary | Equipment |
| OnFETick | Tick |
| OnFillContainer | Inventory |
| OnFillInventoryObjectContextMenu | UI |
| OnFillWorldObjectContextMenu | UI |
| OnFishingActionMPUpdate | Foraging |
| OnGameBoot | Lifecycle |
| OnGameStart | Lifecycle |
| OnGameStateEnter | Lifecycle |
| OnGameTimeLoaded | Time |
| OnGamepadConnect | Joypad |
| OnGamepadDisconnect | Joypad |
| OnGoogleAuthRequest | Mod |
| OnGridBurnt | Map |
| OnHitZombie | Zombie |
| OnInitGlobalModData | Save |
| OnInitModdedWeatherStage | Weather |
| OnInitRecordedMedia | Sound |
| OnInitSeasons | Time |
| OnInitWorld | Lifecycle |
| OnIsoThumpableLoad | Building |
| OnIsoThumpableSave | Building |
| OnItemFound | Foraging |
| OnJoypadActivate | Joypad |
| OnJoypadActivateUI | Joypad |
| OnJoypadBeforeDeactivate | Joypad |
| OnJoypadBeforeReactivate | Joypad |
| OnJoypadDeactivate | Joypad |
| OnJoypadReactivate | Joypad |
| OnJoypadRenderUI | Joypad |
| OnKeyKeepPressed | Input |
| OnKeyPressed | Input |
| OnKeyStartPressed | Input |
| OnLoad | Lifecycle |
| OnLoadMapZones | Map |
| OnLoadRadioScripts | Sound |
| OnLoadSoundBanks | Sound |
| OnLoadedMapZones | Map |
| OnLoadedTileDefinitions | Map |
| OnLoginState | Player |
| OnLoginStateSuccess | Player |
| OnMainMenuEnter | Lifecycle |
| OnMakeItem | Crafting |
| OnMapLoadCreateIsoObject | Map |
| OnMechanicActionDone | Vehicle |
| OnMiniScoreboardUpdate | Network |
| OnModsModified | Mod |
| OnMouseDown | Input |
| OnMouseMove | Input |
| OnMouseUp | Input |
| OnMouseWheel | Input |
| OnMovingObjectCrop | Foraging |
| OnMultiTriggerNPCEvent | Zombie |
| OnNPCSurvivorUpdate | Tick |
| OnNewFire | Map |
| OnNewGame | Lifecycle |
| OnNewSurvivorGroup | Zombie |
| OnObjectAboutToBeRemoved | Building |
| OnObjectAdded | Building |
| OnObjectCollide | Character |
| OnObjectLeftMouseButtonDown | Input |
| OnObjectLeftMouseButtonUp | Input |
| OnObjectRightMouseButtonDown | Input |
| OnObjectRightMouseButtonUp | Input |
| OnOverrideSearchManager | Foraging |
| OnPlayerAttackFinished | Player |
| OnPlayerDeath | Player |
| OnPlayerGetDamage | Player |
| OnPlayerMove | Player |
| OnPlayerSetSafehouse | Player |
| OnPlayerUpdate | Tick |
| OnPostCharactersSquareDraw | Rendering |
| OnPostDistributionMerge | Inventory |
| OnPostFloorLayerDraw | Rendering |
| OnPostFloorSquareDraw | Rendering |
| OnPostMapLoad | Map |
| OnPostRender | Rendering |
| OnPostSave | Save |
| OnPostTileDraw | Rendering |
| OnPostTilesSquareDraw | Rendering |
| OnPostUIDraw | UI |
| OnPostWallSquareDraw | Rendering |
| OnPreDistributionMerge | Inventory |
| OnPreFillInventoryObjectContextMenu | UI |
| OnPreFillWorldObjectContextMenu | UI |
| OnPreGameStart | Lifecycle |
| OnPreMapLoad | Lifecycle |
| OnPreUIDraw | UI |
| OnPressRackButton | Player |
| OnPressReloadButton | Player |
| OnPressWalkTo | Player |
| OnProcessAction | Player |
| OnProcessTransaction | Inventory |
| OnQRReceived | Mod |
| OnRadioInteraction | Sound |
| OnRainStart | Weather |
| OnRainStop | Weather |
| OnReceiveGlobalModData | Save |
| OnReceiveItemListNet | Inventory |
| OnReceiveUserlog | Social |
| OnRenderTick | Tick |
| OnRenderUpdate | Tick |
| OnResetLua | Lifecycle |
| OnResolutionChange | Map |
| OnRightMouseDown | Input |
| OnRightMouseUp | Input |
| OnRolesReceived | Player |
| OnNetworkUsersReceived | Player |
| OnSGlobalObjectSystemInit | Mod |
| OnSafehousesChanged | Social |
| OnSave | Save |
| OnScoreboardUpdate | Network |
| OnSeeNewRoom | Map |
| OnServerCommand | Network |
| OnServerCustomizationDataReceived | Player |
| OnServerFinishSaving | Save |
| OnServerStartSaving | Save |
| OnServerStarted | Network |
| OnServerStatisticReceived | Network |
| OnServerWorkshopItems | Network |
| OnSleepingTick | Time |
| OnSourceWindowFileReload | Save |
| OnSpawnRegionsLoaded | Map |
| OnSpawnVehicleEnd | Vehicle |
| OnSpawnVehicleStart | Vehicle |
| OnSteamGameJoin | Steam |
| OnSteamRefreshInternetServers | Steam |
| OnSteamRulesRefreshComplete | Steam |
| OnSteamServerFailedToRespond2 | Steam |
| OnSteamServerResponded | Steam |
| OnSteamServerResponded2 | Steam |
| OnTemplateTextInit | Sound |
| OnThrowableExplode | Combat |
| OnThunderEvent | Weather |
| OnTick | Tick |
| OnTickEvenPaused | Tick |
| OnTileRemoved | Building |
| OnTriggerNPCEvent | Zombie |
| OnUpdateModdedWeatherStage | Weather |
| OnVehicleDamageTexture | Vehicle |
| OnWarUpdate | Social |
| OnWaterAmountChange | Inventory |
| OnWeaponHitCharacter | Combat |
| OnWeaponHitThumpable | Combat |
| OnWeaponHitTree | Combat |
| OnWeaponHitXp | Combat |
| OnWeaponSwing | Combat |
| OnWeaponSwingHitPoint | Combat |
| OnWeatherPeriodComplete | Weather |
| OnWeatherPeriodStage | Weather |
| OnWeatherPeriodStart | Weather |
| OnWeatherPeriodStop | Weather |
| OnWorldMessage | Network |
| OnWorldSound | Sound |
| OnZombieCreate | Zombie |
| OnZombieDead | Zombie |
| OnZombieUpdate | Tick |
| ReceiveFactionInvite | Social |
| ReceiveSafehouseInvite | Social |
| RefreshCheats | Social |
| RenderOpaqueObjectsInWorld | Rendering |
| RequestTrade | Social |
| ReuseGridsquare | Map |
| SendCustomModData | Save |
| ServerPinged | Network |
| SetDragItem | Equipment |
| SwitchChatStream | Chat |
| SyncFaction | Social |
| TradingUIAddItem | Social |
| TradingUIRemoveItem | Social |
| TradingUIUpdateState | Social |
| ViewBannedIPs | Social |
| ViewBannedSteamIDs | Social |
| ViewTickets | Social |
| onAddForageDefs | Foraging |
| onFillSearchIconContextMenu | Foraging |
| onItemFall | Inventory |
| onLoadModDataFromServer | Inventory |
| onUpdateIcon | UI |
| preAddCatDefs | Foraging |
| preAddForageDefs | Foraging |
| preAddItemDefs | Foraging |
| preAddSkillDefs | Foraging |
| preAddZoneDefs | Foraging |
