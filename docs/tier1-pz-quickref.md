# PZ Modding Quick Reference

Read once per session. Full references: `tier3-pz-events.md`, `tier3-kahlua2.md`.
Game data library: check `data/_index.md` before decompiling. 34 reference files covering all PZ systems.

## BHZ File Dependencies

| File | Requires | Side |
|-|-|-|
| `BHZCore.lua` | SandboxVars, Events.OnLoad/OnZombieUpdate | shared (server+SP) |
| `BHZDebug.lua` | SandboxVars, Events.OnLoad | shared |
| `BarricadeContextMenu.lua` | ISBarricadeAction, ISWorldObjectContextMenu, ItemTag | client |

## B42 Mod Structure

```
ModName/
  mod.info                       # Root: name, id, description, author, poster
  42/
    mod.info                     # Build-specific: versionMin=42
    media/
      sandbox-options.txt        # VERSION=1, ONLY here, never in common/
      lua/shared/                # Server+client code
      lua/client/                # Client-only code
      lua/server/                # Server-only code
  common/
    mod.info                     # Shared across builds
    media/lua/shared/            # Translation files, shared utils
```

- sandbox-options.txt VERSION must be 1 (hardcoded in PZ Java, any other value silently breaks)
- sandbox-options.txt ONLY in `42/media/` - never duplicate in `common/media/`
- mod.info fields used by BHZ: name, id, version, description, versionMin, author, url, workshopID, poster

## Kahlua2 Gotchas (Lua 5.1 subset)

- No `goto`/labels - restructure with `if not shouldSkip then ... end`
- No bitwise ops (`&`, `|`, `~`, `<<`, `>>`) - use `% 256` and `math.floor(x / 16)`
- `string.format("%d", nil)` CRASHES - always validate args before formatting
- `table.pack()`/`table.unpack()` don't exist - use `{...}` and global `unpack()`
- No `io`/`os`/`debug` libraries - use `getFileReader()`/`getFileWriter()` for file I/O
- `#` on sparse tables (nil holes) is undefined - use `ipairs` or explicit count
- `table.wipe()` is PZ-specific - guard with `if table.wipe then`
- Lua patterns only, not regex: `%d+` not `\d+`, no `{3}` repetition counts

## Java Interop Pitfalls

- `type(javaObj)` always returns `"userdata"` - use `instanceof(obj, "ClassName")`
- Java collections are 0-indexed: `for i = 0, list:size() - 1 do list:get(i) end`
- Java methods can return nil - nil-check every step: `local sq = z:getSquare(); if sq then ...`
- Java strings may need `tostring()` conversion before Lua string ops
- Common classes: IsoZombie, IsoPlayer, IsoGameCharacter, IsoObject, IsoThumpable, IsoBarricade, IsoDoor, IsoWindow, BaseVehicle, BarricadeAble

## Event Gotchas

- `OnWorldSound` is **CLIENT-ONLY** in MP - never use for server logic. Use `OnZombieUpdate` + state polling.
- `OnTick` fires ~60/sec at speed 1, ~240/sec at speed 4 - use tick counters or `getTimestampMs()` cooldowns
- `OnZombieUpdate` fires per zombie per tick - keep handlers extremely fast
- `isClient()` returns **false** in SP. For MP zombie logic, check zombie authority before processing instead of blindly skipping every client.
- `getGameSpeed() == 0` means paused - always check in tick handlers
- Events during loading: nil-check everything in `OnLoad`/`OnGameStart` handlers
- B42 may remove/change events - defensive: `if Events.X then Events.X.Add(fn) end`

## MP Architecture

- `isClient()` / `isServer()` / `isCoopHost()` all return false in SP
- Client to server: `sendClientCommand(module, command, args)` -> `Events.OnClientCommand`
- Server to client: `sendServerCommand(module, command, args)` -> `Events.OnServerCommand`

## Performance Patterns

- Cache globals locally: `local print = print; local math_floor = math.floor`
- Reuse tables, don't allocate in loops. Use `table.wipe()` or manual clear.
- `string.format()` or `table.concat()` instead of `..` concatenation in loops
- Guard debug logging: `if DEBUG then debugPrint(...) end`
- Tick counters: process every Nth update, not every tick
- Cooldown tables: track `getTimestampMs()` per entity, purge stale entries periodically

## Version Gating Pattern

Used by BarricadeContextMenu to disable when vanilla restores the feature:
```lua
local function getBuildMinor()
    local ok, ver = pcall(function() return tostring(getCore():getVersion()) end)
    if not ok then return 0 end
    local minor = ver:match("^42%.(%d+)")
    return minor and tonumber(minor) or 0
end
if getBuildMinor() >= 14 then return end
```

## API Compatibility Pattern

Used by BHZ to survive API changes across PZ builds:
```lua
local function safePropertyCheck(props, key, value)
    if not props then return false end
    local ok, result = pcall(props.Is, props, key, value)
    return ok and result or false
end
```
