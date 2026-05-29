# Lua Global Functions (Utility & Systems) - PZ Data Map
Source: projectzomboid.jar (decompiled) + media/lua | Generated: 2026-03-22

All functions registered via `@LuaMethod(global=true)` in `zombie.Lua.LuaManager.GlobalObject`.
Availability: C = Client, S = Server, B = Both. Types are Java types exposed to Kahlua2.

See also: [lua-globals-world.md](lua-globals-world.md) for core world access, player, zombie, vehicle, sound, weather, map, and action functions.

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Client/Server Commands | 35-53 |
| 2 | Item & Inventory | 55-99 |
| 3 | Animal System (B42) | 101-126 |
| 4 | File I/O | 128-157 |
| 5 | Translation & Text | 159-180 |
| 6 | Input - Keyboard & Mouse | 182-206 |
| 7 | Input - Joypad/Controller | 208-263 |
| 8 | World Rendering & Drawing | 265-297 |
| 9 | Mod & Script Management | 299-325 |
| 10 | Save/Load System | 327-366 |
| 11 | Multiplayer Admin & Users | 368-396 |
| 12 | Role & Permission System | 398-412 |
| 13 | Safehouse & Faction | 414-433 |
| 14 | Steam Integration | 435-474 |
| 15 | Chat & Messaging | 476-493 |
| 16 | XP & Stats Sync | 495-513 |
| 17 | Debug & Development | 515-552 |
| 18 | Utility & Misc | 554-585 |
| 19 | Model & Texture Loading | 587-601 |
| 20 | Remaining Globals (Connection/UI/Misc) | 603-721 |

---

## 1. Client/Server Commands

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| sendClientCommand | `sendClientCommand(String module, String cmd, KahluaTable args)` | void | Client-to-server command (no player) | C |
| sendClientCommand | `sendClientCommand(IsoPlayer player, String module, String cmd, KahluaTable args)` | void | Client-to-server command with player | C |
| sendServerCommand | `sendServerCommand(String module, String cmd, KahluaTable args)` | void | Server-to-all-clients command | S |
| sendServerCommand | `sendServerCommand(IsoPlayer player, String module, String cmd, KahluaTable args)` | void | Server-to-specific-client command | S |
| sendServerCommandV | `sendServerCommandV(String module, String cmd, Object... values)` | void | Server command with varargs | S |
| sendClientCommandV | `sendClientCommandV(IsoPlayer player, String module, String cmd, Object... values)` | void | Client command with varargs | C |
| SendCommandToServer | `SendCommandToServer(String cmd)` | void | Raw command string to server | C |
| sendRequestInventory | `sendRequestInventory(IsoPlayer player)` | void | Request player inventory sync | C |
| sendItemsInContainer | `sendItemsInContainer(IsoObject obj, ItemContainer container)` | void | Sync container contents | S |
| sendItemListNet | `sendItemListNet(IsoPlayer sender, ArrayList items, IsoPlayer receiver, String transferID, String custom)` | boolean | Send item list between players | B |
| triggerEvent | `triggerEvent(String event, ...)` | void | Trigger a Lua event by name (0-4 params) | B |
| addVariableToSyncList | `addVariableToSyncList(String key)` | void | Register variable for network sync | B |
| convertToPZNetTable | `convertToPZNetTable(KahluaTable table)` | KahluaTable | Convert table to network-safe format | B |

---

## 2. Item & Inventory

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getAllItems | `getAllItems()` | ArrayList | All item script definitions | B |
| getItem | `getItem(String fullType)` | Item | Get item script by full type | B |
| instanceItem | `instanceItem(String type)` | InventoryItem | Create item instance from type | B |
| instanceItem | `instanceItem(String module, String type)` | InventoryItem | Create item with module prefix | B |
| createNewScriptItem | `createNewScriptItem(String fullType)` | Item | Create new script item definition | B |
| cloneItemType | `cloneItemType(String fromType, String toType)` | Item | Clone item definition | B |
| moduleDotType | `moduleDotType(String module, String type)` | String | Combine "Module.Type" | B |
| getItemNameFromFullType | `getItemNameFromFullType(String fullType)` | String | Get display name from type | B |
| getItemDisplayName | `getItemDisplayName(String fullType)` | String | Get localized display name | B |
| getItemName | `getItemName(String fullType)` | String | Get raw item name | B |
| getItemStaticModel | `getItemStaticModel(String fullType)` | String | Get 3D model name for item | B |
| isItemFood | `isItemFood(String fullType)` | boolean | Check if item is food | B |
| getItemFoodType | `getItemFoodType(String fullType)` | String | Get food category | B |
| isItemFresh | `isItemFresh(String fullType)` | boolean | Check if food item is fresh | B |
| getItemCount | `getItemCount(String fullType)` | int | Default stack count | B |
| getItemWeight | `getItemWeight(String fullType)` | float | Base weight | B |
| getItemActualWeight | `getItemActualWeight(String fullType)` | float | Actual weight with modifiers | B |
| getItemConditionMax | `getItemConditionMax(String fullType)` | int | Max condition value | B |
| getItemEvolvedRecipeName | `getItemEvolvedRecipeName(String fullType)` | String | Evolved recipe name | B |
| hasItemTag | `hasItemTag(String fullType, String tag)` | boolean | Check item tag | B |
| getItemTextureName | `getItemTextureName(String fullType)` | String | Texture path for item icon | B |
| getItemTex | `getItemTex(String fullType)` | Texture | Get loaded item icon texture | B |
| getRecipeDisplayName | `getRecipeDisplayName(String name)` | String | Get localized recipe name | B |
| getAllRecipes | `getAllRecipes()` | ArrayList | All crafting recipes | B |
| getEvolvedRecipes | `getEvolvedRecipes()` | ArrayList | All evolved recipes | B |
| sendAddItemToContainer | `sendAddItemToContainer(IsoObject obj, InventoryItem item)` | void | Sync add item to container | B |
| sendAddItemsToContainer | `sendAddItemsToContainer(IsoObject obj, ArrayList items)` | void | Sync add multiple items | B |
| sendRemoveItemFromContainer | `sendRemoveItemFromContainer(IsoObject obj, InventoryItem item)` | void | Sync remove item | B |
| sendRemoveItemsFromContainer | `sendRemoveItemsFromContainer(IsoObject obj, ArrayList items)` | void | Sync remove multiple items | B |
| sendReplaceItemInContainer | `sendReplaceItemInContainer(IsoObject obj, InventoryItem old, InventoryItem new_)` | void | Sync replace item | B |
| replaceItemInContainer | `replaceItemInContainer(IsoObject obj, InventoryItem old, InventoryItem new_)` | void | Local replace item in container | B |
| sendAttachedItem | `sendAttachedItem(IsoPlayer player, InventoryItem item)` | void | Sync hotbar/attached item | C |
| syncItemActivated | `syncItemActivated(IsoPlayer player, InventoryItem item)` | void | Sync activated item state | C |
| syncItemModData | `syncItemModData(InventoryItem item)` | void | Sync item mod data | C |
| syncItemFields | `syncItemFields(IsoPlayer player, InventoryItem item)` | void | Sync item fields | C |
| syncHandWeaponFields | `syncHandWeaponFields(IsoPlayer player, HandWeapon weapon)` | void | Sync weapon fields | C |
| InvMngGetItem | `InvMngGetItem(int itemID)` | InventoryItem | Get item by managed ID | C |
| InvMngRemoveItem | `InvMngRemoveItem(int itemID)` | void | Remove managed item | C |
| InvMngUpdateItem | `InvMngUpdateItem(int itemID)` | void | Update managed item | C |

---

## 3. Animal System (B42)

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| addAnimal | `addAnimal(IsoCell cell, int x, int y, int z, String type, AnimalBreed breed)` | IsoAnimal | Spawn animal | B |
| addAnimal | `addAnimal(IsoCell cell, int x, int y, int z, String type, AnimalBreed breed, boolean skeleton)` | IsoAnimal | Spawn animal (skeleton variant) | B |
| removeAnimal | `removeAnimal(int id)` | void | Remove animal by ID | B |
| getAnimal | `getAnimal(int id)` | IsoAnimal | Get animal by ID | B |
| getAnimalChunk | `getAnimalChunk(int x, int y)` | AnimalChunk | Get animal chunk at coords | B |
| getAllAnimalsDefinitions | `getAllAnimalsDefinitions()` | ArrayList | All animal definitions | B |
| getHutch | `getHutch(int x, int y, int z)` | IsoHutch | Get hutch at coords | B |
| sendAnimalGenome | `sendAnimalGenome(IsoAnimal animal)` | void | Sync animal genome data | C |
| sendPickupAnimal | `sendPickupAnimal(IsoAnimal animal, IsoPlayer player)` | void | Sync pickup action | C |
| sendButcherAnimal | `sendButcherAnimal(IsoAnimal animal, IsoPlayer player)` | void | Sync butcher action | C |
| sendFeedAnimalFromHand | `sendFeedAnimalFromHand(IsoAnimal animal, IsoPlayer player)` | void | Sync feeding action | C |
| sendHutchGrabAnimal | `sendHutchGrabAnimal(IsoAnimal animal, IsoPlayer player)` | void | Sync hutch grab | C |
| sendHutchGrabCorpseAction | `sendHutchGrabCorpseAction(IsoAnimal animal, IsoPlayer player)` | void | Sync corpse grab from hutch | C |
| sendHutchRemoveAnimalAction | `sendHutchRemoveAnimalAction(IsoAnimal animal, IsoPlayer player)` | void | Sync remove from hutch | C |
| sendAddAnimalInTrailer | `sendAddAnimalInTrailer(IsoAnimal animal, IsoPlayer player, BaseVehicle vehicle)` | void | Sync add to trailer | C |
| sendAddAnimalFromHandsInTrailer | `sendAddAnimalFromHandsInTrailer(IsoAnimal animal, IsoPlayer player, BaseVehicle vehicle)` | void | Sync add from hands to trailer | S |
| sendRemoveAnimalFromTrailer | `sendRemoveAnimalFromTrailer(IsoAnimal animal, IsoPlayer player, BaseVehicle vehicle)` | void | Sync remove from trailer | C |
| sendRemoveAndGrabAnimalFromTrailer | `sendRemoveAndGrabAnimalFromTrailer(IsoAnimal animal, IsoPlayer player, BaseVehicle vehicle)` | void | Sync grab from trailer | C |
| sendCorpse | `sendCorpse(IsoAnimal animal, IsoPlayer player)` | void | Sync animal corpse | C |
| getAndFindNearestTracks | `getAndFindNearestTracks(IsoPlayer player)` | AnimalTracksManager | Find nearby animal tracks | C |

---

## 4. File I/O

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getFileReader | `getFileReader(String path, boolean createIfNull)` | BufferedReader | Open save-relative file for reading | B |
| getFileWriter | `getFileWriter(String path, boolean createIfNull, boolean append)` | LuaManager.GlobalObject.LuaFileWriter | Open save-relative file for writing | B |
| getModFileReader | `getModFileReader(String modID, String path, boolean createIfNull)` | BufferedReader | Open mod-relative file for reading | B |
| getModFileWriter | `getModFileWriter(String modID, String path, boolean createIfNull, boolean append)` | LuaManager.GlobalObject.LuaFileWriter | Open mod-relative file for writing | B |
| getSandboxFileWriter | `getSandboxFileWriter(String path, boolean createIfNull, boolean append)` | LuaManager.GlobalObject.LuaFileWriter | Open sandbox presets file | B |
| getFileOutput | `getFileOutput(String path)` | DataOutputStream | Open binary output stream | B |
| getFileInput | `getFileInput(String path)` | DataInputStream | Open binary input stream | B |
| getGameFilesInput | `getGameFilesInput(String path)` | DataInputStream | Open game media file for reading | B |
| getGameFilesTextInput | `getGameFilesTextInput(String path)` | BufferedReader | Open game media text file | B |
| endFileOutput | `endFileOutput(DataOutputStream out)` | void | Close binary output | B |
| endFileInput | `endFileInput(DataInputStream in)` | void | Close binary input | B |
| endTextFileInput | `endTextFileInput(BufferedReader reader)` | void | Close text reader | B |
| getLineNumber | `getLineNumber(BufferedReader reader)` | int | Get current line number | B |
| getFileSeparator | `getFileSeparator()` | String | OS file separator char | B |
| lineSeparator | `lineSeparator()` | String | OS line separator | B |
| fileExists | `fileExists(String path)` | boolean | Check if file exists (save dir) | B |
| serverFileExists | `serverFileExists(String path)` | boolean | Check if server file exists | S |
| cacheFileExists | `cacheFileExists(String path)` | boolean | Check if cache file exists | B |
| checkSaveFolderExists | `checkSaveFolderExists(String name)` | boolean | Check save folder | B |
| checkSaveFileExists | `checkSaveFileExists(String name)` | boolean | Check save file | B |
| checkSavePlayerExists | `checkSavePlayerExists(String save, String player)` | boolean | Check player save exists | B |
| getAbsoluteSaveFolderName | `getAbsoluteSaveFolderName(String name)` | String | Full path to save folder | B |
| listFilesInZomboidLuaDirectory | `listFilesInZomboidLuaDirectory(String path)` | ArrayList | List files in lua directory | B |
| listFilesInModDirectory | `listFilesInModDirectory(String modID, String path)` | ArrayList | List files in mod directory | B |

---

## 5. Translation & Text

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getText | `getText(String key)` | String | Get translated text | B |
| getText | `getText(String key, Object arg1)` | String | Translated text with 1 param | B |
| getText | `getText(String key, Object a1, Object a2)` | String | Translated text with 2 params | B |
| getText | `getText(String key, Object a1, Object a2, Object a3)` | String | Translated text with 3 params | B |
| getText | `getText(String key, Object a1, Object a2, Object a3, Object a4)` | String | Translated text with 4 params | B |
| getTextOrNull | `getTextOrNull(String key)` | String | Translated text or nil if missing | B |
| getTextOrNull | `getTextOrNull(String key, Object arg1)` | String | Translation or nil with 1 param | B |
| getTextOrNull | `getTextOrNull(String key, Object a1, Object a2)` | String | Translation or nil with 2 params | B |
| getTextOrNull | `getTextOrNull(String key, Object a1, Object a2, Object a3)` | String | Translation or nil with 3 params | B |
| getTextOrNull | `getTextOrNull(String key, Object a1, Object a2, Object a3, Object a4)` | String | Translation or nil with 4 params | B |
| getItemText | `getItemText(String key)` | String | Get item-specific translation | B |
| getRadioText | `getRadioText(String key)` | String | Get radio broadcast text | B |
| getTextMediaEN | `getTextMediaEN(String key)` | String | Get English media text | B |
| getTextManager | `getTextManager()` | TextManager | Access TextManager singleton | B |
| getRadioTranslators | `getRadioTranslators(Language lang)` | ArrayList | Radio translator names for lang | B |
| getTranslatorCredits | `getTranslatorCredits(Language lang)` | ArrayList | Translator credits for lang | B |

---

## 6. Input - Keyboard & Mouse

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| isKeyDown | `isKeyDown(int keyCode)` | boolean | Key currently held | C |
| wasKeyDown | `wasKeyDown(int keyCode)` | boolean | Key was down last frame | C |
| isKeyPressed | `isKeyPressed(int keyCode)` | boolean | Key pressed this frame | C |
| isShiftKeyDown | `isShiftKeyDown()` | boolean | Shift held | C |
| isCtrlKeyDown | `isCtrlKeyDown()` | boolean | Ctrl held | C |
| isAltKeyDown | `isAltKeyDown()` | boolean | Alt held | C |
| isMetaKeyDown | `isMetaKeyDown()` | boolean | Meta/Win held | C |
| getKeyName | `getKeyName(int keyCode)` | String | Human-readable key name | C |
| getKeyCode | `getKeyCode(String name)` | int | Key code from name | C |
| doKeyPress | `doKeyPress(boolean isDown)` | void | Simulate key press | C |
| queueCharEvent | `queueCharEvent(char c)` | void | Queue character input | C |
| queueKeyEvent | `queueKeyEvent(int keyCode, boolean down)` | void | Queue key event | C |
| getMouseX | `getMouseX()` | int | Mouse X in screen pixels | C |
| getMouseY | `getMouseY()` | int | Mouse Y in screen pixels | C |
| getMouseXScaled | `getMouseXScaled()` | int | Mouse X scaled to UI | C |
| getMouseYScaled | `getMouseYScaled()` | int | Mouse Y scaled to UI | C |
| setMouseXY | `setMouseXY(int x, int y)` | void | Set mouse position | C |
| isMouseButtonDown | `isMouseButtonDown(int button)` | boolean | Mouse button held | C |
| isMouseButtonPressed | `isMouseButtonPressed(int button)` | boolean | Mouse button pressed this frame | C |

---

## 7. Input - Joypad/Controller

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getControllerCount | `getControllerCount()` | int | Number of controllers | C |
| isControllerConnected | `isControllerConnected(int id)` | boolean | Controller plugged in | C |
| getControllerGUID | `getControllerGUID(int id)` | String | Controller GUID | C |
| getControllerName | `getControllerName(int id)` | String | Controller display name | C |
| getControllerAxisCount | `getControllerAxisCount(int id)` | int | Number of axes | C |
| getControllerAxisValue | `getControllerAxisValue(int id, int axis)` | float | Axis value (-1 to 1) | C |
| getControllerDeadZone | `getControllerDeadZone(int id, int axis)` | float | Axis dead zone | C |
| setControllerDeadZone | `setControllerDeadZone(int id, int axis, float zone)` | void | Set axis dead zone | C |
| saveControllerSettings | `saveControllerSettings()` | void | Persist controller config | C |
| getControllerButtonCount | `getControllerButtonCount(int id)` | int | Number of buttons | C |
| getControllerPovX | `getControllerPovX(int id)` | float | D-pad X value | C |
| getControllerPovY | `getControllerPovY(int id)` | float | D-pad Y value | C |
| reloadControllerConfigFiles | `reloadControllerConfigFiles()` | void | Reload controller configs | C |
| isJoypadConnected | `isJoypadConnected(int id)` | boolean | Joypad active for player | C |
| isJoypadPressed | `isJoypadPressed(int button)` | boolean | Joypad button pressed | C |
| isJoypadDown | `isJoypadDown(int button)` | boolean | Joypad button held | C |
| isJoypadUp | `isJoypadUp(int id)` | boolean | D-pad up | C |
| isJoypadLeft | `isJoypadLeft(int id)` | boolean | D-pad left | C |
| isJoypadRight | `isJoypadRight(int id)` | boolean | D-pad right | C |
| isJoypadLTPressed | `isJoypadLTPressed(int id)` | boolean | Left trigger pressed | C |
| isJoypadRTPressed | `isJoypadRTPressed(int id)` | boolean | Right trigger pressed | C |
| isJoypadLBPressed | `isJoypadLBPressed(int id)` | boolean | Left bumper pressed | C |
| isJoypadRBPressed | `isJoypadRBPressed(int id)` | boolean | Right bumper pressed | C |
| isJoypadLeftStickButtonPressed | `isJoypadLeftStickButtonPressed(int id)` | boolean | L3 pressed | C |
| isJoypadRightStickButtonPressed | `isJoypadRightStickButtonPressed(int id)` | boolean | R3 pressed | C |
| getJoypadAimingAxisX | `getJoypadAimingAxisX(int id)` | float | Right stick X | C |
| getJoypadAimingAxisY | `getJoypadAimingAxisY(int id)` | float | Right stick Y | C |
| getJoypadMovementAxisX | `getJoypadMovementAxisX(int id)` | float | Left stick X | C |
| getJoypadMovementAxisY | `getJoypadMovementAxisY(int id)` | float | Left stick Y | C |
| getJoypadAButton | `getJoypadAButton(int id)` | int | A button code | C |
| getJoypadBButton | `getJoypadBButton(int id)` | int | B button code | C |
| getJoypadXButton | `getJoypadXButton(int id)` | int | X button code | C |
| getJoypadYButton | `getJoypadYButton(int id)` | int | Y button code | C |
| getJoypadLBumper | `getJoypadLBumper(int id)` | int | LB button code | C |
| getJoypadRBumper | `getJoypadRBumper(int id)` | int | RB button code | C |
| getJoypadBackButton | `getJoypadBackButton(int id)` | int | Back/Select code | C |
| getJoypadStartButton | `getJoypadStartButton(int id)` | int | Start code | C |
| getJoypadLeftStickButton | `getJoypadLeftStickButton(int id)` | int | L3 button code | C |
| getJoypadRightStickButton | `getJoypadRightStickButton(int id)` | int | R3 button code | C |
| getButtonCount | `getButtonCount(int id)` | int | Total button count for joypad | C |
| isXBOXController | `isXBOXController(int id)` | boolean | Check if Xbox controller | C |
| isPlaystationController | `isPlaystationController(int id)` | boolean | Check if PlayStation controller | C |
| wasMouseActiveMoreRecentlyThanJoypad | `wasMouseActiveMoreRecentlyThanJoypad()` | boolean | Mouse vs joypad last input | C |
| activateJoypadOnSteamDeck | `activateJoypadOnSteamDeck()` | void | Force joypad on Steam Deck | C |
| reactivateJoypadAfterResetLua | `reactivateJoypadAfterResetLua()` | void | Re-enable joypad after Lua reset | C |
| setPlayerJoypad | `setPlayerJoypad(int playerIdx, int joypadIdx, ...)` | void | Bind joypad to player slot | C |
| setPlayerMouse | `setPlayerMouse(int playerIdx)` | void | Set player to mouse input | C |
| revertToKeyboardAndMouse | `revertToKeyboardAndMouse()` | void | Switch all to KB/M | C |
| revertToKeyboardAndMouseFromMainMenu | `revertToKeyboardAndMouseFromMainMenu()` | void | Switch to KB/M from menu | C |
| setDebugToggleControllerPluggedIn | `setDebugToggleControllerPluggedIn(boolean b)` | void | Debug controller toggle | C |

---

## 8. World Rendering & Drawing

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getRenderer | `getRenderer()` | WorldRenderer | Get world renderer | C |
| Render3DItem | `Render3DItem(InventoryItem item, IsoGridSquare sq, float x, float y, float z)` | void | Draw 3D item in world | C |
| renderIsoCircle | `renderIsoCircle(float x, float y, float z, float radius, int segments, float r, float g, float b, float a)` | void | Draw circle in iso space | C |
| renderIsoRect | `renderIsoRect(float x, float y, float z, float w, float h, float r, float g, float b, float a, int thickness)` | void | Draw rectangle in iso space | C |
| renderLine | `renderLine(float x1, float y1, float x2, float y2)` | void | Draw 2D line | C |
| drawOverheadMap | `drawOverheadMap()` | void | Render overhead minimap | C |
| translatePointXInOverheadMapToWindow | `translatePointXInOverheadMapToWindow(float x)` | float | Map X to screen X | C |
| translatePointYInOverheadMapToWindow | `translatePointYInOverheadMapToWindow(float y)` | float | Map Y to screen Y | C |
| translatePointXInOverheadMapToWorld | `translatePointXInOverheadMapToWindow(float x)` | float | Screen X to world X | C |
| translatePointYInOverheadMapToWorld | `translatePointYInOverheadMapToWindow(float y)` | float | Screen Y to world Y | C |
| isoToScreenX | `isoToScreenX(int playerIdx, float x, float y, float z)` | float | Iso coord to screen X | C |
| isoToScreenY | `isoToScreenY(int playerIdx, float x, float y, float z)` | float | Iso coord to screen Y | C |
| screenToIsoX | `screenToIsoX(int playerIdx, float x, float y)` | float | Screen X to iso X | C |
| screenToIsoY | `screenToIsoY(int playerIdx, float x, float y)` | float | Screen Y to iso Y | C |
| getCameraOffX | `getCameraOffX()` | float | Camera X offset | C |
| getCameraOffY | `getCameraOffY()` | float | Camera Y offset | C |
| setZoomLevels | `setZoomLevels(float[] levels)` | void | Set available zoom levels | C |
| screenZoomIn | `screenZoomIn()` | void | Zoom in one step | C |
| screenZoomOut | `screenZoomOut()` | void | Zoom out one step | C |
| useTextureFiltering | `useTextureFiltering(boolean b)` | void | Toggle texture filtering | C |
| configureLighting | `configureLighting(float ambient, float night)` | void | Set lighting params | C |
| invalidateLighting | `invalidateLighting(int x, int y, int z)` | void | Force lighting recalc at pos | C |
| addBloodSplat | `addBloodSplat(IsoGridSquare sq, float size)` | void | Add blood decal to square | B |
| addBloodSplat | `addBloodSplat(int x, int y, int z, int count)` | void | Add blood splats at coords | B |
| addAreaHighlight | `addAreaHighlight(int x, int y, int w, int h)` | void | Highlight area on map | C |
| addAreaHighlightForPlayer | `addAreaHighlightForPlayer(int playerIdx, int x, int y, int w, int h)` | void | Player-specific area highlight | C |
| configRoomFade | `configRoomFade(float f)` | void | Configure room fade distance | C |

---

## 9. Mod & Script Management

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getActivatedMods | `getActivatedMods()` | ArrayList | List of active mod IDs | B |
| isModActive | `isModActive(String modID)` | boolean | Check if mod is enabled | B |
| toggleModActive | `toggleModActive(String modID)` | void | Toggle mod active state | B |
| saveModsFile | `saveModsFile()` | void | Save mod list to disk | B |
| getModDirectoryTable | `getModDirectoryTable()` | KahluaTable | All mod directories | B |
| getModInfoByID | `getModInfoByID(String modID)` | ChooseGameInfo.Mod | Get mod info by ID | B |
| getModInfo | `getModInfo(String modDir)` | ChooseGameInfo.Mod | Get mod info by directory | B |
| getMapFoldersForMod | `getMapFoldersForMod(String modID)` | KahluaTable | Map directories for mod | B |
| spawnpointsExistsForMod | `spawnpointsExistsForMod(String modID)` | boolean | Check mod has spawn points | B |
| getScriptManager | `getScriptManager()` | ScriptManager | Access script manager | B |
| require | `require(String filename)` | void | Load Lua file (Kahlua require) | B |
| reloadLuaFile | `reloadLuaFile(String filename)` | void | Hot-reload client Lua file | C |
| reloadServerLuaFile | `reloadServerLuaFile(String filename)` | void | Hot-reload server Lua file | S |
| reloadScripts | `reloadScripts()` | void | Reload all script definitions | B |
| reloadEntityScripts | `reloadEntityScripts()` | void | Reload entity scripts | B |
| reloadEntitiesDebug | `reloadEntitiesDebug()` | void | Reload entities (debug) | B |
| reloadEntityDebug | `reloadEntityDebug(String entityName)` | void | Reload specific entity | B |
| reloadEntityFromScriptDebug | `reloadEntityFromScriptDebug(String script)` | void | Reload entity from script | B |
| reloadXui | `reloadXui()` | void | Reload XUI definitions | C |
| getServerModData | `getServerModData(String key)` | Object | Get server-synced mod data | B |
| checkModsNeedUpdate | `checkModsNeedUpdate()` | void | Check Workshop for updates | C |

---

## 10. Save/Load System

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| save | `save(boolean b)` | void | Trigger game save | B |
| saveGame | `saveGame()` | void | Trigger game save (no params) | B |
| getSaveDirectory | `getSaveDirectory(String type)` | String | Get save directory path | B |
| getSaveDirectoryTable | `getSaveDirectoryTable()` | KahluaTable | All save directories | B |
| getFullSaveDirectoryTable | `getFullSaveDirectoryTable()` | KahluaTable | Full save dir listing | B |
| getCurrentSaveName | `getCurrentSaveName()` | String | Active save slot name | B |
| getSaveInfo | `getSaveInfo(String saveName)` | KahluaTable | Save metadata table | B |
| getLastPlayedDate | `getLastPlayedDate(String saveName)` | String | Last played timestamp | B |
| getTextureFromSaveDir | `getTextureFromSaveDir(String saveName, String texName)` | Texture | Load texture from save | B |
| getLatestSave | `getLatestSave()` | KahluaTable | Most recent save info | B |
| getMapDirectoryTable | `getMapDirectoryTable()` | KahluaTable | Available map directories | B |
| deleteSave | `deleteSave(String saveName)` | void | Delete save folder | B |
| deleteAllGameModeSaves | `deleteAllGameModeSaves(String mode)` | void | Delete all saves for mode | B |
| deleteSandboxPreset | `deleteSandboxPreset(String name)` | void | Delete sandbox preset | B |
| getSandboxPresets | `getSandboxPresets()` | KahluaTable | Available sandbox presets | B |
| renameSavefile | `renameSavefile(String oldName, String newName)` | boolean | Rename save | B |
| setSavefilePlayer1 | `setSavefilePlayer1(String saveName, String username)` | void | Set player 1 for save | B |
| getServerSavedWorldVersion | `getServerSavedWorldVersion()` | int | Saved world format version | S |
| getZombieInfo | `getZombieInfo(String save)` | KahluaTable | Zombie stats for save | B |
| getPlayerInfo | `getPlayerInfo(String save)` | KahluaTable | Player stats for save | B |
| getMapInfo | `getMapInfo(String save)` | KahluaTable | Map stats for save | B |
| getVehicleInfo | `getVehicleInfo(String save)` | KahluaTable | Vehicle stats for save | B |
| manipulateSavefile | `manipulateSavefile(String save, String op)` | void | Modify save file data | B |
| doChallenge | `doChallenge(String challenge)` | void | Start challenge scenario | C |
| doTutorial | `doTutorial(boolean b)` | void | Start tutorial | C |
| createStory | `createStory(String name)` | void | Create new story save | C |
| createWorld | `createWorld(String name)` | void | Create new world | C |
| sanitizeWorldName | `sanitizeWorldName(String name)` | String | Clean world name for filesystem | B |
| deletePlayerSave | `deletePlayerSave(String save, String player)` | void | Delete player from save | B |
| deletePlayerFromDatabase | `deletePlayerFromDatabase(String player)` | void | Remove player from server DB | S |
| checkPlayerExistsInDatabase | `checkPlayerExistsInDatabase(String player)` | boolean | Check player in server DB | S |
| getLastStandPlayersDirectory | `getLastStandPlayersDirectory()` | String | Last Stand players path | B |
| getLastStandPlayerFileNames | `getLastStandPlayerFileNames()` | ArrayList | Last Stand player file list | B |
| getAllSavedPlayers | `getAllSavedPlayers()` | ArrayList | All saved player files | B |

---

## 11. Multiplayer Admin & Users

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| requestUsers | `requestUsers()` | void | Request user list from server | C |
| getUsers | `getUsers()` | ArrayList | Get cached user list | C |
| networkUserAction | `networkUserAction(String action, String user, String arg)` | void | Admin action on user | C |
| banUnbanUserAction | `banUnbanUserAction(String action, String user, String arg)` | void | Ban/unban user | C |
| teleportUserAction | `teleportUserAction(String action, String user, String arg)` | void | Teleport user | C |
| teleportToHimUserAction | `teleportToHimUserAction(String action, String user, String arg)` | void | Teleport to user | C |
| getBannedIPs | `getBannedIPs()` | ArrayList | Server banned IPs | S |
| getBannedSteamIDs | `getBannedSteamIDs()` | ArrayList | Server banned Steam IDs | S |
| getTickets | `getTickets()` | ArrayList | Admin tickets | S |
| addTicket | `addTicket(String author, String message)` | void | Create admin ticket | C |
| viewedTicket | `viewedTicket(int ticketID)` | void | Mark ticket as viewed | S |
| removeTicket | `removeTicket(int ticketID)` | void | Delete ticket | S |
| requestUserlog | `requestUserlog(String username)` | void | Request user log from server | C |
| addUserlog | `addUserlog(String username, String type, String text)` | void | Add user log entry | S |
| removeUserlog | `removeUserlog(String username, int id)` | void | Remove user log entry | S |
| setAdmin | `setAdmin(boolean b)` | void | Toggle admin status (debug) | C |
| addWarningPoint | `addWarningPoint(String username, String reason, int amount)` | void | Add warning points to user | S |
| disconnect | `disconnect()` | void | Disconnect from server | C |
| writeLog | `writeLog(String type, String msg)` | void | Write to server log | S |
| scoreboardUpdate | `scoreboardUpdate()` | void | Force scoreboard refresh | C |
| canModifyPlayerScoreboard | `canModifyPlayerScoreboard()` | boolean | Can edit scoreboard | C |
| requestPVPEvents | `requestPVPEvents()` | void | Request PVP event log | C |
| clearPVPEvents | `clearPVPEvents()` | void | Clear PVP event log | C |

---

## 12. Role & Permission System

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| requestRoles | `requestRoles()` | void | Request role list from server | C |
| getRoles | `getRoles()` | ArrayList | Get all server roles | B |
| getCapabilities | `getCapabilities()` | ArrayList | All capability enum values | B |
| addRole | `addRole(String name)` | void | Create new role | S |
| setupRole | `setupRole(Role role, String desc, Color color, KahluaTable caps)` | void | Configure role capabilities | S |
| deleteRole | `deleteRole(String name)` | void | Delete role | S |
| setDefaultRoleFor | `setDefaultRoleFor(String defaultId, String roleName)` | void | Set default role | S |
| moveRole | `moveRole(byte dir, String roleName)` | void | Reorder role priority | S |
| checkPermissions | `checkPermissions(IsoPlayer player, Capability cap)` | boolean | Validate player capability | S |

---

## 13. Safehouse & Faction

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| sendFactionInvite | `sendFactionInvite(String faction, String player)` | void | Invite player to faction | C |
| acceptFactionInvite | `acceptFactionInvite(String faction, String player)` | void | Accept faction invite | C |
| sendSafehouseInvite | `sendSafehouseInvite(String safehouse, String player)` | void | Invite to safehouse | C |
| acceptSafehouseInvite | `acceptSafehouseInvite(String safehouse, String player)` | void | Accept safehouse invite | C |
| sendSafehouseChangeMember | `sendSafehouseChangeMember(String safehouse, String player, String action)` | void | Modify safehouse member | C |
| sendSafehouseChangeOwner | `sendSafehouseChangeOwner(String safehouse, String newOwner)` | void | Transfer ownership | C |
| sendSafehouseChangeRespawn | `sendSafehouseChangeRespawn(String safehouse, boolean b)` | void | Toggle respawn at safehouse | C |
| sendSafehouseChangeTitle | `sendSafehouseChangeTitle(String safehouse, String title)` | void | Rename safehouse | C |
| sendSafezoneClaim | `sendSafezoneClaim(int x, int y, int x2, int y2)` | void | Claim safe zone area | C |
| sendSafehouseClaim | `sendSafehouseClaim(String safehouse)` | void | Claim safehouse | C |
| sendSafehouseRelease | `sendSafehouseRelease(String safehouse)` | void | Release safehouse | C |
| getWarNearest | `getWarNearest()` | WarManager.War | Nearest war to player | C |
| getWars | `getWars()` | ArrayList | Wars relevant to player | C |
| sendWarManagerUpdate | `sendWarManagerUpdate()` | void | Sync war state | C |

---

## 14. Steam Integration

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getSteamModeActive | `getSteamModeActive()` | boolean | Steam running | B |
| getStreamModeActive | `getStreamModeActive()` | boolean | Stream mode active | B |
| getRemotePlayModeActive | `getRemotePlayModeActive()` | boolean | Remote Play active | B |
| isValidSteamID | `isValidSteamID(String id)` | boolean | Validate Steam ID format | B |
| getCurrentUserSteamID | `getCurrentUserSteamID()` | String | Local user Steam ID | C |
| getCurrentUserProfileName | `getCurrentUserProfileName()` | String | Local Steam profile name | C |
| getSteamProfileNameFromSteamID | `getSteamProfileNameFromSteamID(String id)` | String | Steam name from ID | C |
| getSteamAvatarFromSteamID | `getSteamAvatarFromSteamID(String id)` | Texture | Avatar texture from ID | C |
| getSteamIDFromUsername | `getSteamIDFromUsername(String user)` | String | Steam ID from PZ username | C |
| getSteamProfileNameFromUsername | `getSteamProfileNameFromUsername(String user)` | String | Steam name from PZ username | C |
| getSteamAvatarFromUsername | `getSteamAvatarFromUsername(String user)` | Texture | Avatar from PZ username | C |
| getSteamScoreboard | `getSteamScoreboard()` | KahluaTable | Steam leaderboard data | C |
| isSteamOverlayEnabled | `isSteamOverlayEnabled()` | boolean | Overlay available | C |
| activateSteamOverlayToWorkshop | `activateSteamOverlayToWorkshop()` | void | Open Workshop in overlay | C |
| activateSteamOverlayToWorkshopUser | `activateSteamOverlayToWorkshopUser(String id)` | void | Open user's Workshop | C |
| activateSteamOverlayToWorkshopItem | `activateSteamOverlayToWorkshopItem(String id)` | void | Open Workshop item page | C |
| activateSteamOverlayToWebPage | `activateSteamOverlayToWebPage(String url)` | void | Open URL in Steam overlay | C |
| canInviteFriends | `canInviteFriends()` | boolean | Can send game invites | C |
| inviteFriend | `inviteFriend(String steamID)` | void | Send game invite | C |
| getFriendsList | `getFriendsList()` | ArrayList | Steam friends list | C |
| getSteamWorkshopStagedItems | `getSteamWorkshopStagedItems()` | KahluaTable | Items ready for upload | C |
| getSteamWorkshopItemIDs | `getSteamWorkshopItemIDs()` | ArrayList | Subscribed Workshop IDs | C |
| getSteamWorkshopItemMods | `getSteamWorkshopItemMods()` | ArrayList | Workshop mod details | C |
| querySteamWorkshopItemDetails | `querySteamWorkshopItemDetails(String... ids)` | void | Query Workshop item info | C |
| isSteamRunningOnSteamDeck | `isSteamRunningOnSteamDeck()` | boolean | Detect Steam Deck | C |
| showSteamGamepadTextInput | `showSteamGamepadTextInput()` | void | Show Steam keyboard | C |
| showSteamFloatingGamepadTextInput | `showSteamFloatingGamepadTextInput()` | void | Show floating keyboard | C |
| isFloatingGamepadTextInputVisible | `isFloatingGamepadTextInputVisible()` | boolean | Floating keyboard visible | C |
| steamRequestInternetServersList | `steamRequestInternetServersList()` | void | Refresh server list | C |
| steamReleaseInternetServersRequest | `steamReleaseInternetServersRequest()` | void | Release server list request | C |
| steamRequestInternetServersCount | `steamRequestInternetServersCount()` | int | Server list result count | C |
| steamGetInternetServerDetails | `steamGetInternetServerDetails(int index)` | KahluaTable | Server details at index | C |
| steamRequestServerRules | `steamRequestServerRules(String ip, int port)` | void | Query server rules | C |
| steamRequestServerDetails | `steamRequestServerDetails(String ip, int port)` | void | Query server details | C |

---

## 15. Chat & Messaging

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| processSayMessage | `processSayMessage(String msg)` | void | Send local chat message | C |
| processGeneralMessage | `processGeneralMessage(String msg)` | void | Send general chat | C |
| processShoutMessage | `processShoutMessage(String msg)` | void | Send shout message | C |
| proceedFactionMessage | `proceedFactionMessage(String msg)` | void | Send faction chat | C |
| processSafehouseMessage | `processSafehouseMessage(String msg)` | void | Send safehouse chat | C |
| processAdminChatMessage | `processAdminChatMessage(String msg)` | void | Send admin chat | C |
| proceedPM | `proceedPM(String user, String msg)` | void | Send private message | C |
| showWrongChatTabMessage | `showWrongChatTabMessage(String msg)` | void | Show wrong-tab warning | C |
| focusOnTab | `focusOnTab(int tabID)` | void | Switch to chat tab | C |
| updateChatSettings | `updateChatSettings(KahluaTable settings)` | void | Apply chat config | C |
| checkPlayerCanUseChat | `checkPlayerCanUseChat(String msg)` | boolean | Validate chat permissions | C |
| showDebugInfoInChat | `showDebugInfoInChat(String msg)` | void | Print debug to chat | C |

---

## 16. XP & Stats Sync

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| addXp | `addXp(IsoPlayer player, int perkID, float xp)` | void | Award XP (with multiplier) | B |
| addXpNoMultiplier | `addXpNoMultiplier(IsoPlayer player, int perkID, float xp)` | void | Award XP (no multiplier) | B |
| addXpMultiplier | `addXpMultiplier(IsoPlayer player, int perkID, float mult)` | void | Set XP multiplier | B |
| getLoosingXpValue | `getLoosingXpValue(IsoPlayer player, int perkID)` | float | XP loss value | B |
| getLoosingXpTick | `getLoosingXpTick(IsoPlayer player, int perkID)` | float | XP loss rate | B |
| SyncXp | `SyncXp(IsoPlayer player)` | void | Sync XP to server | C |
| syncBodyPart | `syncBodyPart(IsoPlayer player, String bodyPart)` | void | Sync body part state | C |
| syncPlayerStats | `syncPlayerStats(IsoPlayer player)` | void | Sync all stats | C |
| sendPlayerStat | `sendPlayerStat(IsoPlayer player, String stat, String value)` | void | Sync specific stat | C |
| sendPlayerNutrition | `sendPlayerNutrition(IsoPlayer player)` | void | Sync nutrition data | C |
| sendPlayerStatsChange | `sendPlayerStatsChange(IsoPlayer player)` | void | Sync stats change | C |
| sendPlayerExtraInfo | `sendPlayerExtraInfo(IsoPlayer player)` | void | Sync extra player info | C |
| sendPersonalColor | `sendPersonalColor(IsoPlayer player)` | void | Sync player color | C |

---

## 17. Debug & Development

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getDebug | `getDebug()` | boolean | Debug mode enabled | B |
| isDebugEnabled | `isDebugEnabled()` | boolean | Debug mode check | B |
| isDemo | `isDemo()` | boolean | Demo build check | B |
| getDebugOptions | `getDebugOptions()` | DebugOptions | Access debug options | B |
| debugLuaTable | `debugLuaTable(Object table)` | void | Print table to debug log | B |
| debugLuaTable | `debugLuaTable(Object table, int depth)` | void | Print table with depth limit | B |
| displayLUATable | `displayLUATable(Object table)` | void | Display table in UI | C |
| luaDebug | `luaDebug(String msg)` | void | Print debug message | B |
| log | `log(String type, String msg)` | void | Log message | B |
| breakpoint | `breakpoint()` | void | Trigger Lua debugger breakpoint | C |
| toggleBreakpoint | `toggleBreakpoint(String file, int line)` | void | Toggle breakpoint at location | C |
| toggleBreakOnChange | `toggleBreakOnChange(String var)` | void | Break when variable changes | C |
| toggleBreakOnRead | `toggleBreakOnRead(String var)` | void | Break when variable read | C |
| hasBreakpoint | `hasBreakpoint(String file, int line)` | boolean | Check breakpoint exists | C |
| hasDataBreakpoint | `hasDataBreakpoint(String var)` | boolean | Check data breakpoint | C |
| hasDataReadBreakpoint | `hasDataReadBreakpoint(String var)` | boolean | Check read breakpoint | C |
| isCurrentExecutionPoint | `isCurrentExecutionPoint(String file, int line)` | boolean | Check current debug position | C |
| getLuaDebuggerErrorCount | `getLuaDebuggerErrorCount()` | int | Debugger error count | C |
| getLuaDebuggerErrors | `getLuaDebuggerErrors()` | ArrayList | Debugger error messages | C |
| doLuaDebuggerAction | `doLuaDebuggerAction(String action)` | void | Execute debugger command | C |
| getLuaStackTrace | `getLuaStackTrace()` | String | Get current Lua stack trace | B |
| getLoadedLuaCount | `getLoadedLuaCount()` | int | Number of loaded Lua files | B |
| getLoadedLua | `getLoadedLua(int idx)` | String | Loaded Lua file at index | B |
| debugSetRoomType | `debugSetRoomType(IsoGridSquare sq, String type)` | void | Override room type | B |
| debugFullyStreamedIn | `debugFullyStreamedIn()` | boolean | All chunks loaded | B |
| assaultPlayer | `assaultPlayer()` | void | Debug damage player | C |
| sendDebugStory | `sendDebugStory(String event)` | void | Trigger story event | B |
| testHelicopter | `testHelicopter()` | void | Spawn helicopter event | B |
| endHelicopter | `endHelicopter()` | void | End helicopter event | B |
| isoRegionsRenderer | `isoRegionsRenderer()` | void | Toggle region debug overlay | C |
| zpopNewRenderer | `zpopNewRenderer()` | void | Toggle zpop debug overlay | C |
| getIsoEntitiesDebug | `getIsoEntitiesDebug()` | KahluaTable | Get entities debug info | B |

---

## 18. Utility & Misc

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| instanceof | `instanceof(Object obj, String className)` | boolean | Java instanceof check | B |
| istype | `istype(Object obj, String className)` | boolean | Type check for exposed types | B |
| getClassSimpleName | `getClassSimpleName(Object obj)` | String | Java class simple name | B |
| toInt | `toInt(double d)` | int | Convert double to integer | B |
| ZombRand | `ZombRand(int max)` | int | Random int [0, max) | B |
| ZombRand | `ZombRand(int min, int max)` | int | Random int [min, max) | B |
| ZombRandBetween | `ZombRandBetween(int min, int max)` | int | Random int [min, max) | B |
| ZombRandFloat | `ZombRandFloat(float min, float max)` | float | Random float [min, max) | B |
| fastfloor | `fastfloor(float f)` | float | Fast floor operation | B |
| getRandomUUID | `getRandomUUID()` | String | Generate UUID string | B |
| checkStringPattern | `checkStringPattern(String s, String pattern)` | boolean | Regex pattern match | B |
| splitString | `splitString(String s, String delim)` | ArrayList | Split string by delimiter | B |
| getTwoLetters | `getTwoLetters(String s)` | String | First two chars | B |
| getShortenedFilename | `getShortenedFilename(String path)` | String | Truncate filename | B |
| copyTable | `copyTable(KahluaTable src)` | KahluaTable | Deep copy Lua table | B |
| copyTable | `copyTable(KahluaTable src, KahluaTable dst)` | void | Copy table into existing table | B |
| tabToX | `tabToX(int x)` | int | Convert tab pos to X | B |
| timSort | `timSort(ArrayList list, KahluaTable comparator)` | void | Stable sort with Lua comparator | B |
| javaListRemoveAt | `javaListRemoveAt(ArrayList list, int index)` | void | Remove from Java list by index | B |
| sortBrowserList | `sortBrowserList(KahluaTable list)` | void | Sort server browser entries | C |
| detectBadWords | `detectBadWords(String text)` | boolean | Profanity detection | B |
| profanityFilterCheck | `profanityFilterCheck(String text)` | String | Filter profanity from text | B |
| getDirectionTo | `getDirectionTo(float x1, float y1, float x2, float y2)` | IsoDirections | Direction between two points | B |
| callLua | `callLua(String func, Object... args)` | void | Call Lua function by name | B |
| callLuaReturn | `callLuaReturn(String func, Object... args)` | Object | Call Lua function, get return | B |
| callLuaBool | `callLuaBool(String func, Object... args)` | boolean | Call Lua function, get boolean | B |

---

## 19. Model & Texture Loading

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| loadVehicleModel | `loadVehicleModel(String name, String mesh, String tex)` | Model | Load vehicle 3D model | C |
| loadStaticZomboidModel | `loadStaticZomboidModel(String name, String mesh, String tex)` | Model | Load static model | C |
| loadSkinnedZomboidModel | `loadSkinnedZomboidModel(String name, String mesh, String tex)` | Model | Load skinned/animated model | C |
| loadZomboidModel | `loadZomboidModel(String name, String mesh, String tex, String shader, boolean bStatic)` | Model | Load model with full params | C |
| setModelMetaData | `setModelMetaData(String name, String mesh, String tex, String shader, boolean bStatic)` | void | Register model metadata | C |
| reloadModelsMatching | `reloadModelsMatching(String meshName)` | void | Reload models by mesh name | C |
| getTexture | `getTexture(String path)` | Texture | Load/get texture by path | B |
| tryGetTexture | `tryGetTexture(String path)` | Texture | Get texture or nil | B |
| getVideo | `getVideo(String path)` | Object | Load video file | C |

---

## 20. Remaining Globals (Connection/UI/Misc)

| Function | Signature | Return | Purpose | Avail |
|-|-|-|-|-|
| getCore | `getCore()` | Core | Engine Core singleton | B |
| initUISystem | `initUISystem()` | void | Initialize UI framework | C |
| forceChangeState | `forceChangeState(String state)` | void | Force game state transition | B |
| setProgressBarValue | `setProgressBarValue(float val, String msg)` | void | Update loading bar | C |
| getPerformance | `getPerformance()` | PerformanceSettings | Performance settings | B |
| getSpriteManager | `getSpriteManager()` | IsoSpriteManager | Sprite cache manager | B |
| getSprite | `getSprite(String name)` | IsoSprite | Get sprite by name | B |
| getContainerOverlays | `getContainerOverlays()` | ContainerOverlays | Container icon overlays | B |
| getTileOverlays | `getTileOverlays()` | TileOverlays | Tile overlay system | B |
| getWorldMarkers | `getWorldMarkers()` | WorldMarkers | Map marker system | B |
| getIsoMarkers | `getIsoMarkers()` | IsoMarkers | Iso-space markers | B |
| openUrl | `openUrl(String url)` | void | Open URL in system browser | C |
| isDesktopOpenSupported | `isDesktopOpenSupported()` | boolean | Can open desktop files | C |
| showFolderInDesktop | `showFolderInDesktop(String path)` | void | Open folder in file manager | C |
| isSystemLinux | `isSystemLinux()` | boolean | Running on Linux | B |
| isSystemMacOS | `isSystemMacOS()` | boolean | Running on macOS | B |
| isSystemWindows | `isSystemWindows()` | boolean | Running on Windows | B |
| getMyDocumentFolder | `getMyDocumentFolder()` | String | User documents path | B |
| getCurrentCoroutine | `getCurrentCoroutine()` | Object | Active Lua coroutine | B |
| getServerListFile | `getServerListFile()` | String | Server list file path | C |
| getServerList | `getServerList()` | KahluaTable | Saved server list | C |
| addServerToAccountList | `addServerToAccountList(KahluaTable info)` | void | Save server to list | C |
| updateServerToAccountList | `updateServerToAccountList(KahluaTable info)` | void | Update saved server | C |
| deleteServerToAccountList | `deleteServerToAccountList(KahluaTable info)` | void | Remove saved server | C |
| addAccountToAccountList | `addAccountToAccountList(KahluaTable info)` | void | Save account info | C |
| updateAccountToAccountList | `updateAccountToAccountList(KahluaTable info)` | void | Update account info | C |
| deleteAccountToAccountList | `deleteAccountToAccountList(KahluaTable info)` | void | Remove account info | C |
| getPublicServersList | `getPublicServersList()` | KahluaTable | Public server listing | C |
| ping | `ping(String ip, int port)` | void | Ping server | C |
| stopPing | `stopPing()` | void | Stop ping request | C |
| getHostByName | `getHostByName(String hostname)` | String | DNS resolve | C |
| getCustomizationData | `getCustomizationData()` | Object | Server customization data | C |
| getCombatConfig | `getCombatConfig()` | Object | Combat configuration | B |
| serverConnect | `serverConnect(String user, String pass, String ip, String localIP, String port, String serverPass, String name, boolean steam, boolean hash, int auth, String key)` | void | Connect to server | C |
| serverConnectCoop | `serverConnectCoop(String steamID)` | void | Connect to co-op host | C |
| sendPing | `sendPing()` | void | Send network ping | C |
| connectionManagerLog | `connectionManagerLog(String event, String msg)` | void | Log connection event | C |
| forceDisconnect | `forceDisconnect()` | void | Force disconnect | C |
| backToSinglePlayer | `backToSinglePlayer()` | void | Leave MP, return to SP | C |
| canConnect | `canConnect()` | boolean | Ready to connect | C |
| getReconnectCountdownTimer | `getReconnectCountdownTimer()` | String | Reconnect timer display | C |
| connectToServerStateCallback | `connectToServerStateCallback(String state, KahluaTable data)` | void | Connection state callback | C |
| isPublicServerListAllowed | `isPublicServerListAllowed()` | boolean | Public servers available | C |
| isSteamServerBrowserEnabled | `isSteamServerBrowserEnabled()` | boolean | Steam browser available | C |
| getServerAddressFromArgs | `getServerAddressFromArgs()` | String | Server from launch args | C |
| getServerPasswordFromArgs | `getServerPasswordFromArgs()` | String | Password from launch args | C |
| isShowConnectionInfo | `isShowConnectionInfo()` | boolean | Connection info visible | C |
| setShowConnectionInfo | `setShowConnectionInfo(boolean b)` | void | Toggle connection info | C |
| isShowServerInfo | `isShowServerInfo()` | boolean | Server info visible | C |
| setShowServerInfo | `setShowServerInfo(boolean b)` | void | Toggle server info | C |
| setShowPausedMessage | `setShowPausedMessage(boolean b)` | void | Toggle pause message | C |
| getPerformanceLocal | `getPerformanceLocal()` | KahluaTable | Local perf stats | C |
| getNetworkLocal | `getNetworkLocal()` | KahluaTable | Local network stats | C |
| getGameLocal | `getGameLocal()` | KahluaTable | Local game stats | C |
| getPerformanceRemote | `getPerformanceRemote()` | KahluaTable | Remote perf stats | C |
| getNetworkRemote | `getNetworkRemote()` | KahluaTable | Remote network stats | C |
| getGameRemote | `getGameRemote()` | KahluaTable | Remote game stats | C |
| getMPStatus | `getMPStatus()` | KahluaTable | MP status dashboard | C |
| getGameClient | `getGameClient()` | GameClient | Client network instance | C |
| getServerSettingsManager | `getServerSettingsManager()` | ServerSettingsManager | Server settings UI | S |
| sendHitPlayer | `sendHitPlayer(IsoPlayer target, String damage, String range)` | void | Debug hit player | C |
| stopFire | `stopFire(IsoGridSquare sq)` | void | Extinguish fire at square | B |
| updateFire | `updateFire()` | void | Tick fire system | B |
| getSleepingEvent | `getSleepingEvent()` | Object | Active sleeping event | B |
| transformIntoKahluaTable | `transformIntoKahluaTable(HashMap map)` | KahluaTable | Convert Java map to Lua table | B |
| getZomboidRadio | `getZomboidRadio()` | ZomboidRadio | Radio system singleton | B |
| getRadioAPI | `getRadioAPI()` | RadioAPI | Radio API interface | B |
| getNumClassFunctions | `getNumClassFunctions(Object obj)` | int | Count methods on object | B |
| getClassFunction | `getClassFunction(Object obj, int idx)` | String | Get method name at index | B |
| getNumClassFields | `getNumClassFields(Object obj)` | int | Count fields on object | B |
| getClassField | `getClassField(Object obj, int idx)` | String | Get field name at index | B |
| getClassFieldVal | `getClassFieldVal(Object obj, String field)` | Object | Read field value by name | B |
| getMethodParameter | `getMethodParameter(Object obj, int methodIdx, int paramIdx)` | String | Method param type name | B |
| getMethodParameterCount | `getMethodParameterCount(Object obj, int methodIdx)` | int | Count method params | B |
| getFilenameOfCallframe | `getFilenameOfCallframe(int depth)` | String | Lua source file at stack depth | B |
| getFilenameOfClosure | `getFilenameOfClosure(Object closure)` | String | Source file of closure | B |
| getFirstLineOfClosure | `getFirstLineOfClosure(Object closure)` | int | First line of closure | B |
| getLocalVarCount | `getLocalVarCount(int depth)` | int | Local var count at depth | B |
| getLocalVarName | `getLocalVarName(int depth, int idx)` | String | Local var name | B |
| getLocalVarStack | `getLocalVarStack(int depth, int idx)` | Object | Local var value | B |
| getLocalVarStackIndex | `getLocalVarStackIndex(int depth, int idx)` | int | Local var stack index | B |
| localVarName | `localVarName(int depth, int idx)` | String | Alias for getLocalVarName | B |
| getCallframeTop | `getCallframeTop(int depth)` | int | Stack frame top | B |
| getCoroutineTop | `getCoroutineTop()` | int | Coroutine stack top | B |
| getCoroutineObjStack | `getCoroutineObjStack(int idx)` | Object | Coroutine object at index | B |
| getCoroutineObjStackWithBase | `getCoroutineObjStackWithBase(int base, int idx)` | Object | Object at base+index | B |
| getCoroutineCallframeStack | `getCoroutineCallframeStack(int idx)` | Object | Call frame at index | B |
| timersShowMean | `timersShowMean()` | void | Show timer mean values | B |
| timersShowTotal | `timersShowTotal()` | void | Show timer totals | B |
| timersReset | `timersReset()` | void | Reset timers | B |
| timerGetKept | `timerGetKept()` | int | Timer kept count | B |
| sendIconFound | `sendIconFound(IsoPlayer player, String icon, float x, float y, float z)` | void | Sync foraging icon found | C |
| showAnimationViewer | `showAnimationViewer()` | void | Open animation viewer | C |
| showAttachmentEditor | `showAttachmentEditor()` | void | Open attachment editor | C |
| showChunkDebugger | `showChunkDebugger()` | void | Open chunk debugger | C |
| showGlobalObjectDebugger | `showGlobalObjectDebugger()` | void | Open global object debugger | C |
| showSeamEditor | `showSeamEditor()` | void | Open seam editor | C |
| showSpriteModelEditor | `showSpriteModelEditor()` | void | Open sprite model editor | C |
| showVehicleEditor | `showVehicleEditor()` | void | Open vehicle editor | C |
| showWorldMapEditor | `showWorldMapEditor()` | void | Open world map editor | C |
| getAnimationViewerState | `getAnimationViewerState()` | Object | Animation viewer state | C |
| getAttachmentEditorState | `getAttachmentEditorState()` | Object | Attachment editor state | C |
| getEditVehicleState | `getEditVehicleState()` | Object | Vehicle editor state | C |
| getSpriteModelEditorState | `getSpriteModelEditorState()` | Object | Sprite model editor state | C |
| getTileGeometryState | `getTileGeometryState()` | Object | Tile geometry state | C |
| getSeamEditorState | `getSeamEditorState()` | Object | Seam editor state | C |
| checkServerName | `checkServerName(String name)` | boolean | Validate server name | B |
| takeScreenshot | `takeScreenshot()` | void | Capture screenshot | C |
| takeScreenshot | `takeScreenshot(String path)` | void | Screenshot to path | C |
| teleportPlayers | `teleportPlayers(ArrayList players, float x, float y, float z)` | void | Mass teleport | S |
| requestTrading | `requestTrading(IsoPlayer other)` | void | Request trade with player | C |
| acceptTrading | `acceptTrading(IsoPlayer other)` | void | Accept trade request | C |
| tradingUISendAddItem | `tradingUISendAddItem(InventoryItem item)` | void | Add item to trade | C |
| tradingUISendRemoveItem | `tradingUISendRemoveItem(InventoryItem item)` | void | Remove item from trade | C |
| tradingUISendUpdateState | `tradingUISendUpdateState(int state)` | void | Update trade state | C |
