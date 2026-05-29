# Project Zomboid Event Reference (Build 42)

A comprehensive reference for PZ Lua events. Events are registered using:
```lua
Events.EventName.Add(handlerFunction)
```

And removed with:
```lua
Events.EventName.Remove(handlerFunction)
```

## Section Index
Use `Read` with `offset` and `limit` to load specific sections only.

| # | Section | Lines |
|-|-|-|
| 1 | Game Lifecycle Events | 20-57 |
| 2 | Tick / Update Events | 59-104 |
| 3 | Time Events | 106-145 |
| 4 | Player Events | 147-212 |
| 5 | Zombie Events | 214-236 |
| 6 | Vehicle Events | 238-267 |
| 7 | Building / Construction Events | 269-288 |
| 8 | Inventory / Item Events | 290-328 |
| 9 | Combat Events | 330-361 |
| 10 | Sound Events | 363-377 |
| 11 | Weather Events | 379-406 |
| 12 | UI Events | 408-488 |
| 13 | Multiplayer Events | 490-536 |
| 14 | Save / Load Events | 538-567 |
| 15 | Crafting Events | 569-581 |
| 16 | Known Gotchas | 583-642 |

---

## Game Lifecycle Events

### OnLoad
```lua
Events.OnLoad.Add(function()
    -- Called when the game world has finished loading.
    -- Use this to read SandboxVars and initialize your mod.
end)
```
- **Fires on:** Client and Server
- **Use for:** Initializing mod state, reading sandbox settings, setting up data structures

### OnGameStart
```lua
Events.OnGameStart.Add(function()
    -- Called after the game has fully started and the player exists.
end)
```
- **Fires on:** Client and Server
- **Use for:** Post-initialization that needs the player to exist

### OnPreGameStart
```lua
Events.OnPreGameStart.Add(function()
    -- Called before the game starts, after mods are loaded.
end)
```
- **Fires on:** Client and Server
- **Use for:** Early setup before game objects exist

### OnNewGame
```lua
Events.OnNewGame.Add(function(player, square)
    -- Called when a new game is started (not loaded from save).
end)
```
- **Parameters:** `player` (IsoPlayer), `square` (IsoGridSquare)
- **Fires on:** Client and Server
- **Use for:** First-time initialization, starter items, tutorials

### OnMainMenuEnter
```lua
Events.OnMainMenuEnter.Add(function()
    -- Called when returning to the main menu.
end)
```
- **Fires on:** Client
- **Use for:** Cleanup when leaving a game session

### OnGameBoot
```lua
Events.OnGameBoot.Add(function()
    -- Called once when the game application first starts.
end)
```
- **Fires on:** Client
- **Use for:** One-time initialization before any game is loaded

---

## Tick / Update Events

### OnTick
```lua
Events.OnTick.Add(function(numTicks)
    -- Called every game tick. Ticks increase with game speed.
    -- At speed 1: ~60 ticks/second
    -- At speed 2: ~120 ticks/second, etc.
end)
```
- **Parameters:** `numTicks` (number) - number of ticks elapsed
- **Fires on:** Client and Server
- **Use for:** Regular game logic processing
- **Performance note:** Keep this FAST. Use tick counters to throttle work.
- **Gotcha:** Fires more frequently at higher game speeds. Use `getGameSpeed()` to check.

### OnTickEvenPaused
```lua
Events.OnTickEvenPaused.Add(function(numTicks)
    -- Like OnTick but continues to fire when the game is paused.
end)
```
- **Parameters:** `numTicks` (number)
- **Fires on:** Client and Server
- **Use for:** UI updates, animations that should work while paused

### OnPlayerUpdate
```lua
Events.OnPlayerUpdate.Add(function(player)
    -- Called every tick for each local player.
end)
```
- **Parameters:** `player` (IsoPlayer)
- **Fires on:** Client
- **Use for:** Per-player per-tick logic (movement, state checks)

### OnRenderTick
```lua
Events.OnRenderTick.Add(function()
    -- Called every render frame.
end)
```
- **Fires on:** Client only
- **Use for:** Rendering overlays, visual effects
- **Performance note:** This fires at the rendering framerate, not the game tick rate. Keep extremely lightweight.

---

## Time Events

### EveryOneMinute
```lua
Events.EveryOneMinute.Add(function()
    -- Called every in-game minute.
end)
```
- **Fires on:** Client and Server
- **Use for:** Periodic checks that don't need tick precision

### EveryTenMinutes
```lua
Events.EveryTenMinutes.Add(function()
    -- Called every 10 in-game minutes.
end)
```
- **Fires on:** Client and Server
- **Use for:** Less frequent periodic tasks (resource regeneration, checks)

### EveryHours
```lua
Events.EveryHours.Add(function()
    -- Called every in-game hour.
end)
```
- **Fires on:** Client and Server
- **Use for:** Hourly updates (weather effects, hunger, etc.)

### EveryDays
```lua
Events.EveryDays.Add(function()
    -- Called every in-game day.
end)
```
- **Fires on:** Client and Server
- **Use for:** Daily updates (population changes, decay, etc.)

---

## Player Events

### OnPlayerMove
```lua
Events.OnPlayerMove.Add(function(player)
    -- Called when a player moves to a new position.
end)
```
- **Parameters:** `player` (IsoPlayer)
- **Fires on:** Client

### OnPlayerDeath
```lua
Events.OnPlayerDeath.Add(function(player)
    -- Called when the player dies.
end)
```
- **Parameters:** `player` (IsoPlayer)
- **Fires on:** Client and Server

### OnCreatePlayer
```lua
Events.OnCreatePlayer.Add(function(playerIndex, player)
    -- Called when a player character is created.
end)
```
- **Parameters:** `playerIndex` (number), `player` (IsoPlayer)
- **Fires on:** Client and Server

### OnPlayerGetDamage
```lua
Events.OnPlayerGetDamage.Add(function(player, damageType, damage)
    -- Called when a player takes damage.
end)
```
- **Parameters:** `player` (IsoPlayer), `damageType` (string), `damage` (number)
- **Fires on:** Client and Server

### OnEquipPrimary
```lua
Events.OnEquipPrimary.Add(function(player, item)
    -- Called when primary weapon/item changes.
end)
```
- **Parameters:** `player` (IsoPlayer), `item` (InventoryItem or nil)
- **Fires on:** Client

### OnEquipSecondary
```lua
Events.OnEquipSecondary.Add(function(player, item)
    -- Called when secondary weapon/item changes.
end)
```
- **Parameters:** `player` (IsoPlayer), `item` (InventoryItem or nil)
- **Fires on:** Client

### LevelPerk
```lua
Events.LevelPerk.Add(function(player, perk, level, addedLevels)
    -- Called when a player's perk level changes.
end)
```
- **Parameters:** `player` (IsoPlayer), `perk` (PerkFactory.Perk), `level` (number), `addedLevels` (number)
- **Fires on:** Client and Server

---

## Zombie Events

### OnZombieDead
```lua
Events.OnZombieDead.Add(function(zombie)
    -- Called when a zombie dies.
end)
```
- **Parameters:** `zombie` (IsoZombie)
- **Fires on:** Client and Server
- **Use for:** Kill counting, loot drops, effects on death

### OnZombieUpdate
```lua
Events.OnZombieUpdate.Add(function(zombie)
    -- Called each tick for each zombie being updated.
end)
```
- **Parameters:** `zombie` (IsoZombie)
- **Fires on:** Server (and SP)
- **Performance note:** Fires for EVERY zombie. Use extremely sparingly.

---

## Vehicle Events

### OnEnterVehicle
```lua
Events.OnEnterVehicle.Add(function(player)
    -- Called when a player enters a vehicle.
end)
```
- **Parameters:** `player` (IsoPlayer)
- **Fires on:** Client and Server

### OnExitVehicle
```lua
Events.OnExitVehicle.Add(function(player)
    -- Called when a player exits a vehicle.
end)
```
- **Parameters:** `player` (IsoPlayer)
- **Fires on:** Client and Server

### OnUseVehicle
```lua
Events.OnUseVehicle.Add(function(player, vehicle, pressedNotTapped)
    -- Called when a player interacts with a vehicle (e.g., horn, lights).
end)
```
- **Parameters:** `player` (IsoPlayer), `vehicle` (BaseVehicle), `pressedNotTapped` (boolean)
- **Fires on:** Client

---

## Building / Construction Events

### OnDoTileBuilding
```lua
Events.OnDoTileBuilding.Add(function(draggingInfo, isRender, x, y, z, square)
    -- Called during construction placement.
end)
```
- **Fires on:** Client

### OnObjectAdded
```lua
Events.OnObjectAdded.Add(function(object)
    -- Called when a new object is added to the world.
end)
```
- **Parameters:** `object` (IsoObject)
- **Fires on:** Client and Server

---

## Inventory / Item Events

### OnFillInventoryObjectContextMenu
```lua
Events.OnFillInventoryObjectContextMenu.Add(function(playerIndex, context, items)
    -- Called when building the right-click context menu for inventory items.
end)
```
- **Parameters:** `playerIndex` (number), `context` (ISContextMenu), `items` (table)
- **Fires on:** Client
- **Use for:** Adding custom right-click options to items

### OnFillWorldObjectContextMenu
```lua
Events.OnFillWorldObjectContextMenu.Add(function(playerIndex, context, worldObjects, test)
    -- Called when building the right-click context menu for world objects.
end)
```
- **Parameters:** `playerIndex` (number), `context` (ISContextMenu), `worldObjects` (table), `test` (boolean)
- **Fires on:** Client
- **Use for:** Adding custom right-click options to world objects

### OnRefreshInventoryWindowContainers
```lua
Events.OnRefreshInventoryWindowContainers.Add(function(inventoryPage, reason)
    -- Called when the inventory display refreshes.
end)
```
- **Fires on:** Client

### OnContainerUpdate
```lua
Events.OnContainerUpdate.Add(function(container)
    -- Called when a container's contents change.
end)
```
- **Parameters:** `container` (ItemContainer)
- **Fires on:** Client and Server

---

## Combat Events

### OnWeaponHitCharacter
```lua
Events.OnWeaponHitCharacter.Add(function(attacker, target, weapon, damage)
    -- Called when a weapon hits a character (zombie or player).
end)
```
- **Parameters:** `attacker` (IsoGameCharacter), `target` (IsoGameCharacter), `weapon` (HandWeapon), `damage` (number)
- **Fires on:** Client and Server
- **Use for:** Custom damage modifiers, hit effects, combat logging

### OnWeaponSwing
```lua
Events.OnWeaponSwing.Add(function(player, weapon)
    -- Called when a player swings a weapon.
end)
```
- **Parameters:** `player` (IsoPlayer), `weapon` (HandWeapon)
- **Fires on:** Client

### OnWeaponHitXp
```lua
Events.OnWeaponHitXp.Add(function(player, weapon, target, damage)
    -- Called for XP calculation on weapon hit.
end)
```
- **Parameters:** `player` (IsoPlayer), `weapon` (HandWeapon), `target` (IsoGameCharacter), `damage` (number)
- **Fires on:** Client and Server

---

## Sound Events

### OnWorldSound
```lua
Events.OnWorldSound.Add(function(x, y, z, radius, volume, source)
    -- Called when a sound is emitted in the world.
end)
```
- **Parameters:** `x` (number), `y` (number), `z` (number), `radius` (number), `volume` (number), `source` (IsoObject or nil)
- **Fires on:** **Client only** (even in MP)
- **Gotcha:** This is CLIENT-ONLY in multiplayer. Do NOT use this for server-authoritative logic.
  The BHZ mod originally used this for thump detection and it was completely broken in MP.
  Use OnTick with state polling instead.

---

## Weather Events

### OnRainStart
```lua
Events.OnRainStart.Add(function()
    -- Called when rain begins.
end)
```
- **Fires on:** Client and Server

### OnRainStop
```lua
Events.OnRainStop.Add(function()
    -- Called when rain stops.
end)
```
- **Fires on:** Client and Server

### OnThunderEvent
```lua
Events.OnThunderEvent.Add(function(x, y, strike)
    -- Called during a thunder event.
end)
```
- **Parameters:** `x` (number), `y` (number), `strike` (boolean - whether lightning actually strikes)
- **Fires on:** Client and Server

---

## UI Events

### OnCreateUI
```lua
Events.OnCreateUI.Add(function()
    -- Called once when the game UI is first created.
end)
```
- **Fires on:** Client
- **Use for:** Adding custom UI elements

### OnPreUIDraw
```lua
Events.OnPreUIDraw.Add(function()
    -- Called before UI elements are drawn each frame.
end)
```
- **Fires on:** Client

### OnPostUIDraw
```lua
Events.OnPostUIDraw.Add(function()
    -- Called after UI elements are drawn each frame.
end)
```
- **Fires on:** Client

### OnKeyPressed
```lua
Events.OnKeyPressed.Add(function(key)
    -- Called when a key is pressed.
end)
```
- **Parameters:** `key` (number - key code)
- **Fires on:** Client
- **Use for:** Custom keybinds, debug toggles

### OnKeyStartPressed
```lua
Events.OnKeyStartPressed.Add(function(key)
    -- Called at the start of a key press (before repeat).
end)
```
- **Parameters:** `key` (number)
- **Fires on:** Client

### OnMouseDown
```lua
Events.OnMouseDown.Add(function(x, y)
    -- Called when a mouse button is pressed.
end)
```
- **Parameters:** `x` (number), `y` (number)
- **Fires on:** Client

### OnMouseUp
```lua
Events.OnMouseUp.Add(function(x, y)
    -- Called when a mouse button is released.
end)
```
- **Parameters:** `x` (number), `y` (number)
- **Fires on:** Client

### OnRightMouseDown
```lua
Events.OnRightMouseDown.Add(function(x, y)
    -- Called on right mouse button press.
end)
```
- **Fires on:** Client

### OnRightMouseUp
```lua
Events.OnRightMouseUp.Add(function(x, y)
    -- Called on right mouse button release.
end)
```
- **Fires on:** Client

---

## Multiplayer Events

### OnClientCommand
```lua
Events.OnClientCommand.Add(function(module, command, player, args)
    -- Called on the server when a client sends a command.
end)
```
- **Parameters:** `module` (string), `command` (string), `player` (IsoPlayer), `args` (table)
- **Fires on:** Server only
- **Use for:** Receiving client requests for server-authoritative actions

### OnServerCommand
```lua
Events.OnServerCommand.Add(function(module, command, args)
    -- Called on clients when the server sends a command.
end)
```
- **Parameters:** `module` (string), `command` (string), `args` (table)
- **Fires on:** Client only
- **Use for:** Receiving server responses/broadcasts

### OnConnected
```lua
Events.OnConnected.Add(function()
    -- Called when the client successfully connects to a server.
end)
```
- **Fires on:** Client

### OnDisconnect
```lua
Events.OnDisconnect.Add(function()
    -- Called when disconnected from a server.
end)
```
- **Fires on:** Client

### OnConnectionStateChanged
```lua
Events.OnConnectionStateChanged.Add(function(state, message)
    -- Called when the connection state changes.
end)
```
- **Parameters:** `state` (string), `message` (string)
- **Fires on:** Client

---

## Save / Load Events

### OnSave
```lua
Events.OnSave.Add(function()
    -- Called when the game saves.
end)
```
- **Fires on:** Client and Server
- **Use for:** Persisting mod data to ModData or files

### OnPreSave
```lua
Events.OnPreSave.Add(function()
    -- Called just before a save begins.
end)
```
- **Fires on:** Client and Server

### OnLoadedTileDefinitions
```lua
Events.OnLoadedTileDefinitions.Add(function(spriteManager)
    -- Called after tile definitions are loaded.
end)
```
- **Parameters:** `spriteManager` (IsoSpriteManager)
- **Fires on:** Client and Server
- **Use for:** Modifying tile/sprite properties

---

## Crafting Events

### OnMakeItem
```lua
Events.OnMakeItem.Add(function(resultItem, player, recipe, ingredients)
    -- Called when a crafting recipe produces an item.
end)
```
- **Parameters:** `resultItem` (InventoryItem), `player` (IsoPlayer), `recipe` (Recipe), `ingredients` (table)
- **Fires on:** Client and Server

---

## Known Gotchas

### 1. OnWorldSound is Client-Only in MP
This is the most common trap. `OnWorldSound` only fires on the client that generated or
heard the sound. In multiplayer, the server never receives this event. If you need to detect
zombie thumping server-side, poll zombie states using `OnTick` + `getCurrentStateName()`.

### 2. OnTick Fires More at Higher Game Speeds
At game speed 1, OnTick fires ~60 times/second. At speed 4, it fires ~240 times/second.
If your logic applies damage per tick, damage will effectively increase at higher speeds
unless you compensate. Options:
- Use tick counters to throttle processing
- Use time-based cooldowns with `getTimestampMs()`
- Divide by `getGameSpeed()` (but note speed 0 = paused)

### 3. OnZombieUpdate is Extremely Expensive
This fires for every zombie being updated. With hundreds of zombies, this can severely
impact performance. Prefer OnTick with manual zombie scanning using cell/grid methods.

### 4. Event Handler Order is Not Guaranteed
Multiple handlers on the same event may fire in any order. Do not depend on one mod's
handler running before another's.

### 5. Events During Loading
Some events fire during world loading before all objects are ready. Always nil-check
everything, especially in OnLoad and OnGameStart handlers.

### 6. isClient() Returns False in Singleplayer
In SP, both `isClient()` and `isServer()` return `false`. The pattern
`if isClient() then return end` is safe for server-only logic because it will not skip
in singleplayer.

### 7. getGameSpeed() == 0 Means Paused
Always check for paused state in tick handlers:
```lua
if getGameSpeed() == 0 then return end
```

### 8. MP Role Checks
```lua
isClient()    -- true only on MP clients (false in SP)
isServer()    -- true only on MP dedicated server (false in SP)
isCoopHost()  -- true only for the host in MP co-op (false in SP)
```
In singleplayer, all three return false. Your code runs in a unified context.

### 9. Removed/Changed Events in B42
Build 42 changed or removed some events from B41. Always test your event hooks on the
target build version. If an event does not exist, `Events.EventName` will be `nil` and
calling `.Add()` on it will crash.

Defensive registration:
```lua
if Events.SomeEvent then
    Events.SomeEvent.Add(myHandler)
else
    print("[MyMod] Warning: Events.SomeEvent not available in this build")
end
```
