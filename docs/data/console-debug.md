# Console & Debug System - PZ Data Map
Source: projectzomboid.jar (decompiled) | media/lua | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Debug Console (SP) | 19-55 |
| 2 | Server Console Commands | 56-165 |
| 3 | Command System Internals | 166-189 |
| 4 | DebugType Channels | 190-231 |
| 5 | LogSeverity Levels | 232-258 |
| 6 | DebugOptions Categories | 259-361 |
| 7 | Debug Windows (ImGui) | 362-390 |
| 8 | Logging System | 391-437 |
| 9 | Mod Integration | 438-500 |

---

## 1. Debug Console (SP)

**Class:** `zombie.ui.UIDebugConsole`

The single-player debug console is a Lua REPL available only when the game runs in debug mode (`-debug` launch flag). It is not a "command" console - it executes raw Lua code directly.

**How to open:** Press `~` (tilde) key in debug mode. The console window appears at the top of the screen. It can be resized by dragging edges.

**How it works:**
- Input text is compiled via `LuaCompiler.loadstring()` and executed in `LuaManager.env`
- All `print()` output is routed to the console via `BaseLib.setPrintCallback`
- DebugLog output is also mirrored when `UI.DebugConsole.DebugLog` option is enabled
- Command history via Up/Down arrow keys
- Tab completion uses Levenshtein distance against `LuaManager.GlobalObject` methods
- Method chaining supported with `:` separator (e.g. `getPlayer():getInventory()`)

**Built-in commands:**

| Command | Effect |
|-|-|
| `clear` / `clr` | Clear output log |
| `?` / `help` / `commands` | Show available commands list |
| `AddInvItem 'name' [count]` | Add item to player inventory |
| `SpawnZombie X,Y,Z` | Spawn zombie at map coordinates |

Any valid Lua expression works: `getPlayer():setGodMod(true)`, `print(SandboxVars.ZombieLore.Speed)`, etc.

**Console settings (DebugOptions):**

| Option | Default | Effect |
|-|-|-|
| `UI.DebugConsole.StartVisible` | true | Console visible on game start |
| `UI.DebugConsole.DebugLog` | true | Mirror DebugLog to console output |
| `UI.DebugConsole.EchoCommand` | true | Print executed commands to output |

---

## 2. Server Console Commands

**Package:** `zombie.commands.serverCommands`

Server commands use `/command` syntax in chat or the server console. Each command is a Java class with annotations defining its name, arguments, required capability, and help text.

### Complete Command List

**Player Management:**

| Command | Args | Capability | Description |
|-|-|-|-|
| `adduser` | username password | ManipulateWhitelist | Add user account |
| `kickuser` | username | KickUser | Kick player |
| `banuser` | username | BanUnbanUser | Ban by username |
| `banid` | steamID | BanUnbanUser | Ban by Steam ID |
| `banip` | IP | BanUnbanUser | Ban by IP address |
| `unbanuser` | username | BanUnbanUser | Unban username |
| `unbanid` | steamID | BanUnbanUser | Unban Steam ID |
| `unbanip` | IP | BanUnbanUser | Unban IP |
| `voiceban` | username | BanUnbanUser | Toggle voice ban |
| `grantadmin` | username | ChangeAccessLevel | Grant admin |
| `removeadmin` | username | ChangeAccessLevel | Remove admin |
| `setaccesslevel` | user level | ChangeAccessLevel | Set access level |
| `players` | - | SeePlayersConnected | List online players |
| `debugplayer` | username | ConnectWithDebug | Toggle debug for player |
| `setpassword` | password | ChangeAndReloadServerOptions | Set server password |

**Whitelist & Safehouse:**

| Command | Args | Capability | Description |
|-|-|-|-|
| `addalltowhitelist` | - | ManipulateWhitelist | Add all to whitelist (DISABLED) |
| `addusertowhitelist` | username | ManipulateWhitelist | Whitelist user |
| `removeuserfromwhitelist` | username | ManipulateWhitelist | Remove from whitelist |
| `addtosafehouse` | user safeID | CanSetupSafehouses | Add to safehouse |
| `kickfromsafehouse` | user safeID | CanSetupSafehouses | Kick from safehouse |
| `releasesafehouse` | safeID | CanSetupSafehouses | Release safehouse |
| `addsteamid` | id | ModifyNetworkUsers | Add Steam ID |
| `removesteamid` | id | ModifyNetworkUsers | Remove Steam ID |

**Cheats & God Mode:**

| Command | Args | Capability | Description |
|-|-|-|-|
| `godmode` | - | ToggleGodModHimself | Toggle self god mode |
| `godmodeplayer` | username | ToggleGodModEveryone | Toggle player god mode |
| `invisible` | - | ToggleInvisibleHimself | Toggle self invisible |
| `invisibleplayer` | username | ToggleInvisibleEveryone | Toggle player invisible |
| `noclip` | - | ToggleNoclipHimself | Toggle noclip |

**Teleportation:**

| Command | Args | Capability | Description |
|-|-|-|-|
| `tp` | x,y,z | TeleportToCoordinates | Teleport self to coords |
| `tpp` | username | TeleportToPlayer | Teleport to player |
| `tpto` | user1 user2 | TeleportPlayerToAnotherPlayer | Teleport player to player |

**World & Items:**

| Command | Args | Capability | Description |
|-|-|-|-|
| `additem` | [user] module.type [qty] | AddItem | Give item |
| `removeitem` | [user] module.type | AddItem | Remove item |
| `addkey` | [user] buildingID [desc] | AddItem | Give key |
| `addvehicle` | [user] scriptName | ManipulateVehicle | Spawn vehicle |
| `addxp` | user perkName amount | AddXP | Grant XP |

**World Events & Weather:**

| Command | Args | Capability | Description |
|-|-|-|-|
| `alarm` | - | MakeEventsAlarmGunshot | Trigger alarm |
| `gunshot` | - | MakeEventsAlarmGunshot | Trigger gunshot sound |
| `chopper` | - | MakeEventsAlarmGunshot | Trigger helicopter |
| `startrain` | - | StartStopRain | Start rain |
| `stoprain` | - | StartStopRain | Stop rain |
| `startstorm` | - | StartStopRain | Start storm |
| `stopweather` | - | StartStopRain | Stop all weather |
| `thunder` | - | StartStopRain | Trigger thunder |
| `lightning` | - | StartStopRain | Trigger lightning |
| `createhorde` | count | CreateHorde | Spawn horde |
| `createhorde2` | count | CreateHorde | Spawn horde (variant 2) |
| `removezombies` | - | ManipulateZombie | Remove zombies |
| `sts` | speed | ChangeAndReloadServerOptions | Set time speed |
| `worldgen` | - | ChangeAndReloadServerOptions | Trigger world generation |

**Server Administration:**

| Command | Args | Capability | Description |
|-|-|-|-|
| `save` | - | SaveWorld | Force world save |
| `quit` | - | QuitWorld | Shutdown server |
| `servermsg` | message | DisplayServerMessage | Broadcast message |
| `showoptions` | - | SeePublicServerOptions | Show server options |
| `changeoption` | option=value | ChangeAndReloadServerOptions | Change server option |
| `reloadoptions` | - | ChangeAndReloadServerOptions | Reload server options |
| `reloadlua` | filename | ReloadLuaFiles | Reload Lua file |
| `reloadluaall` | - | ReloadLuaFiles | Reload all Lua |
| `checkModsNeedUpdate` | - | ManipulateMods | Check mod updates |
| `stats` | - | GetStatistic | Show statistics |
| `log` | type | ReadUserLog | View logs |
| `list` | - | SeePlayersConnected | List players |
| `help` | [command] | (any) | Show help |
| `clear` | - | (any) | Clear console |
| `remove` | - | (any) | Remove item under cursor |

---

## 3. Command System Internals

**Class:** `zombie.commands.CommandBase`

Commands use annotation-driven design:

```java
@CommandName(name="additem")                           // command string
@CommandArgs(required={"(.+)", "([a-zA-Z0-9.-]+)"},   // regex argument patterns
             optional="(\\d+)",                         // optional arg pattern
             argName="add item to player")              // variant name
@CommandHelp(helpText="UI_ServerOptionDesc_AddItem")   // translation key
@RequiredCapability(requiredCapability=Capability.AddItem)  // permission
@DisabledCommand                                       // marks command as disabled
```

**Argument parsing:** Uses regex patterns in `@CommandArgs.required[]`. Supports multiple argument variants via `@AltCommandArgs`. Arguments with quotes are handled (e.g. `"multi word arg"`).

**Capability system** (`zombie.characters.Capability`): Enum with ~70 values. Each `Role` (Admin, Moderator, etc.) has a set of capabilities. Commands check `playerRole.hasCapability()` before execution.

**Key capabilities:** `ToggleGodModHimself`, `ToggleGodModEveryone`, `ToggleInvisibleHimself`, `TeleportToPlayer`, `TeleportToCoordinates`, `AddItem`, `AddXP`, `CreateHorde`, `KickUser`, `BanUnbanUser`, `ManipulateWhitelist`, `ChangeAccessLevel`, `SaveWorld`, `QuitWorld`, `ReloadLuaFiles`, `ConnectWithDebug`, `DebugConsole`, `ManipulateVehicle`, `ManipulateZombie`, `SandboxOptions`

---

## 4. DebugType Channels

**Enum:** `zombie.debug.DebugType` - Each value is a log channel with its own `DebugLogStream`.

| Channel | Category | Channel | Category |
|-|-|-|-|
| `General` | Core logging | `Lua` | Lua execution |
| `Mod` | Mod loading | `Script` | Script parsing |
| `Network` | Net protocol | `Multiplayer` | MP logic |
| `Vehicle` | Vehicle system | `Zombie` | Zombie AI |
| `Animal` | Animal system | `Combat` | Combat events |
| `Sound` | Audio system | `Radio` | Radio system |
| `Animation` | Anim playback | `AnimationDetailed` | Anim detail |
| `AnimationLayers` | Anim layers | `AnimationRecorder` | Anim recording |
| `MapLoading` | Map loading | `Objects` | Iso objects |
| `Recipe` | Crafting | `CraftLogic` | Craft logic |
| `Action` | Action system | `ActionSystem` | Action internals |
| `ActionSystemEvents` | Action events | `Clothing` | Clothing system |
| `Damage` | Damage calc | `Death` | Death events |
| `Entity` | Entity system | `Sprite` | Sprite rendering |
| `Shader` | Shader system | `Asset` | Asset loading |
| `Input` | Input handling | `Voice` | VOIP |
| `IsoRegion` | Iso regions | `FileIO` | File operations |
| `Statistic` | Statistics | `Discord` | Discord integration |
| `Checksum` | Checksum verify | `ItemPicker` | Item spawning |
| `Grapple` | Grapple system | `Lightning` | Lightning |
| `ExitDebug` | Exit debugging | `BodyDamage` | Body damage |
| `Xml` | XML parsing | `Physics` | Physics engine |
| `Ballistics` | Ballistics | `Ragdoll` | Ragdoll physics |
| `PZBullet` | Bullet physics | `ModelManager` | Model loading |
| `LoadAnimation` | Anim loading | `Zone` | Zone system |
| `WorldGen` | World gen | `Foraging` | Foraging |
| `Saving` | Save system | `Fluid` | Fluid system |
| `Energy` | Energy system | `Translation` | Translation |
| `Moveable` | Moveables | `Basement` | Basements |
| `FallDamage` | Fall damage | `ImGui` | ImGui debug |
| `CharacterTrait` | Traits | `VehicleHit` | Vehicle hits |
| `Packet` | Net packets | `NetworkFileDebug` | Net file debug |
| `DetailedInfo` | Detailed info | `Fireplace` | Fireplace |

---

## 5. LogSeverity Levels

**Enum:** `zombie.debug.LogSeverity`

| Level | Prefix | Description |
|-|-|-|
| `Trace` | `TRACE: ` | Most verbose, fine-grained tracing |
| `Noise` | `NOISE: ` | Verbose noise-level output |
| `Debug` | `DEBUG: ` | Debug-level details |
| `General` | `LOG  : ` | Standard log output |
| `Warning` | `WARN : ` | Warning conditions |
| `Error` | `ERROR: ` | Error conditions |
| `Off` | `!OFF!` | Logging disabled for channel |

`LogSeverity.All` is an alias for `Trace`.

**Default severity by context:**
- Debug mode (`-debug`): `General`
- Server (non-debug): `Warning`
- Client (non-debug): `Off`

**Always-on channels** (set in `DebugLog.init()`):
- `General`, `Lua`, `Mod`, `Multiplayer` - set to `General`
- `Network` - set to `Error`

---

## 6. DebugOptions Categories

**Class:** `zombie.debug.DebugOptions` - Saved to `~/Zomboid/cache/debug-options.ini`

Options come in two types: `newOption()` (available always) and `newDebugOnlyOption()` (requires `-debug` flag). All are boolean toggles.

### Top-Level Options

| Option Key | Default | Debug-Only |
|-|-|-|
| `DebugScenario.ForceLaunch` | false | no |
| `Mechanics.Render.Hitbox` | false | no |
| `Tooltip.Info` | false | no |
| `Tooltip.Attributes` | false | yes |
| `Tooltip.ModName` | false | yes |
| `Translation.Prefix` | false | no |
| `UI.Render.Outline` | false | no |
| `UI.HideDebugContextMenuOptions` | false | no |
| `GameProfiler.Enabled` | false | no |
| `GameTime.Speed.Half` | false | no |
| `GameTime.Speed.Quarter` | false | no |
| `GameTime.Speed.Eighth` | false | no |
| `GameTime.TimeOfDay.Freeze` | false | no |

### Pathfinding Debug

| Option Key | Default |
|-|-|
| `Pathfind.PathToMouse.Enable` | false |
| `Pathfind.PathToMouse.AllowCrawl` | false |
| `Pathfind.PathToMouse.AllowThump` | false |
| `Pathfind.PathToMouse.IgnoreCrawlCost` | false |
| `Pathfind.PathToMouse.RenderSuccessors` | false |
| `Pathfind.Render.ChunkRegions` | false |
| `Pathfind.Render.Path` | false |
| `Pathfind.Render.Waiting` | false |

### Vehicle Debug (debug-only)

| Option Key | Default |
|-|-|
| `Vehicle.CycleColor` | false |
| `Vehicle.Render.Blood0/50/100` | false |
| `Vehicle.Render.Damage0/1/2` | false |
| `Vehicle.Render.Rust0/50/100` | false |
| `Vehicle.Render.TrailerPositions` | false |
| `Vehicle.Spawn.Everywhere` | false |

### Cheat Group (`DebugOptions.cheat`)

| Option Key | Default |
|-|-|
| `Cheat.Clock.Visible` | false |
| `Cheat.Door.Unlock` | false |
| `Cheat.Player.StartInvisible` | false |
| `Cheat.Player.InvisibleSprint` | false |
| `Cheat.Player.SeeEveryone` | false |
| `Cheat.Player.UnlimitedCondition` | false |
| `Cheat.Player.FastLooseXp` | false |
| `Cheat.TimedAction.Instant` | false |
| `Cheat.Vehicle.MechanicsAnywhere` | false |
| `Cheat.Vehicle.StartWithoutKey` | false |
| `Cheat.Window.Unlock` | false |
| `Cheat.Farming.FastGrow` | false |

### Model Rendering

| Option Key | Default | Debug-Only |
|-|-|-|
| `Model.Render.Attachments` | false | no |
| `Model.Render.Axis` | false | no |
| `Model.Render.Bones` | false | no |
| `Model.Render.Bounds` | false | no |
| `Model.Render.Wireframe` | false | no |
| `Model.Render.Lights` | false | no |
| `Model.Render.WeaponHitPoint` | false | no |
| `Model.Render.ForceAlphaOne` | false | yes |
| `Model.Force.Skeleton` | false | no |

### Animation Group

| Option Key | Default |
|-|-|
| `Animation.DancingDoors` | false |
| `Animation.Debug` | false |
| `Animation.DisableRagdolls` | false |
| `Animation.AllowEarlyTransitionOut` | true |
| `Animation.Render.Picker` | false |
| `Animation.AnimLayer.Debug.LogStateChanges` | false |
| `Animation.SharedSkeles.Enabled` | true |

### Weather Group

| Option Key | Default |
|-|-|
| `Weather.Fog` | true |
| `Weather.Fx` | true |
| `Weather.Snow` | true |
| `Weather.ShowUsablePuddles` | false |
| `Weather.WaterPuddles` | true |

---

## 7. Debug Windows (ImGui)

**Package:** `zombie.debug.debugWindows` - Available in debug mode via the ImGui system.

| Window | Class | Purpose |
|-|-|-|
| Console | `Console` | Debug console (ImGui variant) |
| Scene Panel | `ScenePanel` | Scene inspection |
| Registries Viewer | `RegistriesViewer` | Browse game registries |
| Java Inspector | `JavaInspector` | Inspect Java objects |
| Lua Panel | `LuaPanel` | Lua environment |
| Firearm Panel | `FirearmPanel` | Firearm stats |
| Range Weapon Panel | `RangeWeaponPanel` | Ranged weapon tuning |
| Ballistics Target | `BallisticsTargetPanel` | Ballistics targets |
| Target Hit Info | `TargetHitInfoPanel` | Hit info display |
| Aim Plotter | `AimPlotter` | Aim visualization |
| Combat Manager | `CombatManagerEditor` | Combat system editor |
| Physics Hit Reactions | `PhysicsHitReactionsPanel` | Hit reaction tuning |
| Ragdoll Debug | `RagdollDebugWindow` | Ragdoll physics debug |
| Tracer Effects | `TracerEffectsDebugWindow` | Tracer FX debug |
| Statistics | `StatisticsPanel` | Performance stats |
| Achievement Panel | `AchievementPanel` | Achievement debugging |
| UI Panel | `UIPanel` | UI inspection |
| Text Editor | `TextEditor` | Text/script editor |
| Viewport | `Viewport` | Viewport control |
| Plotter | `Plotter` | Data plotting |

---

## 8. Logging System

### Log Format

```
LOG  : General      f:12345, t:1711100000000> Message text here
WARN : Vehicle      f:12345, t:1711100000000, st:500> Warning message
```

Format: `{severity} {channel} f:{frameNo}, t:{timeMs}[, st:{serverTime}]> {message}`

### Log Files

| File | Location | Purpose |
|-|-|-|
| `DebugLog.txt` | `~/Zomboid/` | Client debug log |
| `DebugLog-server.txt` | `~/Zomboid/` | Server debug log |
| `debug-options.ini` | `~/Zomboid/cache/` | Debug option state |
| `debuglog.ini` | `~/Zomboid/cache/` | Per-channel severity config |
| `debuglog.cfg` | `~/Zomboid/cache/` | Advanced debug config profiles |

### debuglog.cfg Format

```ini
# Profile definitions
= MyProfile          # active profile selection (= prefix)
$alias = Profile1 + Profile2    # alias definition ($ prefix)

MyProfile
{
+Network Debug       # enable channel at severity (+)
-Sound               # disable channel (-)
+all General         # enable all channels
}
```

Supports profile composition with `+` (e.g. `Profile1 + Profile2`). File is hot-reloaded on changes.

### Loki Integration

PZ supports Grafana Loki log shipping via JVM system properties:
- `-DlokiUrl=http://host:3100/loki/api/v1/push`
- `-DlokiUser=username`
- `-DlokiPass=password`

---

## 9. Mod Integration

### Using print() for Output

In debug mode, `print()` output goes to:
1. stdout (terminal)
2. `DebugLog.txt` (via `DebugLog.General`)
3. Debug console window (if `UI.DebugConsole.DebugLog` enabled)

In non-debug mode, `print()` still writes to stdout and log file but the debug console is unavailable.

### Structured Logging from Lua

Mods can use the Java `DebugLog` API directly:

```lua
-- Access DebugType channels
DebugLog.log(DebugType.Mod, "My mod message")

-- Check if logging is enabled
if DebugLog.isEnabled(DebugType.Mod) then
    -- expensive string building
end
```

### Custom Console Commands (Server)

Mods cannot add server commands via the Java annotation system (requires JAR modification). Instead, use Lua event hooks:

```lua
-- Server-side: handle custom chat commands
Events.OnServerCommand.Add(function(module, command, player, args)
    -- process custom commands sent via sendClientCommand
end)

-- Client-side: send commands to server
sendClientCommand(player, "MyMod", "myCommand", {arg1 = "value"})
```

### Reading DebugOptions from Lua

```lua
-- DebugOptions is exposed to Lua
local opts = DebugOptions.instance
if opts:getBoolean("Tooltip.Info") then
    -- show tooltip info
end

-- Set options
opts:setBoolean("Tooltip.Info", true)
opts:save()
```

### CSV Export Tools

Debug-only CSV export classes for data analysis:

| Class | Export Target |
|-|-|
| `DebugCSVExport` | Base export functionality |
| `DebugCSVExportFirearms` | Firearm stats export |
| `DebugCSVExportFluidContainers` | Fluid container data |
| `DebugCSVExportMoveableTiles` | Moveable tile data |
