# Kahlua2 Compatibility Guide for Project Zomboid Modding

Project Zomboid uses **Kahlua2**, a Java-based Lua interpreter. It targets **Lua 5.1** but
does not implement the full specification. This guide documents what works, what does not,
and common pitfalls to avoid.

## Section Index
Use `Read` with `offset` and `limit` to load specific sections only.

| # | Section | Lines |
|-|-|-|
| 1 | Quick Reference Table | 15-39 |
| 2 | What Does Work | 41-75 |
| 3 | Java Interop | 77-152 |
| 4 | Common Pitfalls | 154-289 |
| 5 | Performance Tips | 291-328 |
| 6 | Testing Compatibility | 330-337 |

## Quick Reference: What You Cannot Use

| Feature | Status | Workaround |
|-|-|-|
| `goto` / labels | Not supported (Lua 5.2+) | Restructure with `if/while/repeat` |
| Bitwise operators (`&`, `\|`, `~`, `<<`, `>>`) | Not supported (Lua 5.3+) | Manual bit functions or lookup tables |
| `table.pack()` | Not available | Use `{...}` |
| `table.unpack()` | Not available | Use global `unpack()` |
| `table.move()` | Not available | Manual loop copy |
| `string.pack()` / `string.unpack()` | Not available (Lua 5.3+) | Not needed for PZ modding |
| `utf8` library | Not available (Lua 5.3+) | Handle UTF-8 manually if needed |
| `//` (integer division) | Not available (Lua 5.3+) | Use `math.floor(a / b)` |
| Generalized `for` with `__close` | Not available (Lua 5.4+) | Use explicit cleanup |
| Metatables on strings | Limited | Test before relying on |
| `os` library | Not available | Use Java interop |
| `io` library | Not available | Use `getFileReader()` / `getFileWriter()` |
| `debug` library | Not available | Not applicable |
| `coroutine` library | Not available | Structure code without coroutines |

## What Does Work

### Standard Lua 5.1 Features
- Local/global variables, functions, closures
- Tables (arrays and dictionaries)
- Metatables and metamethods (`__index`, `__newindex`, `__tostring`, `__add`, etc.)
- `string.find()`, `string.format()`, `string.sub()`, `string.gsub()`, `string.match()`
- `string.byte()`, `string.char()`, `string.rep()`, `string.reverse()`
- `string.len()`, `string.lower()`, `string.upper()`
- `math.*` (floor, ceil, sqrt, sin, cos, atan2, random, pi, huge, etc.)
- `table.insert()`, `table.remove()`, `table.sort()`, `table.concat()`
- `tonumber()`, `tostring()`, `type()`, `pairs()`, `ipairs()`, `next()`
- `select()`, `unpack()`, `pcall()`, `xpcall()`, `error()`
- `setmetatable()`, `getmetatable()`, `rawget()`, `rawset()`, `rawequal()`
- String patterns (Lua patterns, not regex)
- Multiple return values
- Varargs (`...`)
- `require()` (with PZ's custom module path)

### PZ-Specific Globals
- `print()` - outputs to the PZ console log
- `instanceof(obj, "ClassName")` - Java type checking (see below)
- `getPlayer()` - local player in SP
- `getOnlinePlayers()` - Java ArrayList of players in MP
- `getCell()` - the current game cell
- `getWorld()` - the game world object
- `isClient()` / `isServer()` / `isCoopHost()` - MP role checks
- `getGameSpeed()` - 0 (paused), 1-4
- `getTimestampMs()` - current time in milliseconds
- `SandboxVars` - table of sandbox option values
- `getActivatedMods()` - Java ArrayList of active mod IDs
- `Events` - the event system table
- `getFileReader()` / `getFileWriter()` - file I/O
- `addBloodSplat()` - add blood decals
- `getTexture()` - load textures

## Java Interop

### Type Checking
Standard Lua `type()` returns `"userdata"` for all Java objects. Use `instanceof()` instead:

```lua
-- WRONG: This will always be "userdata"
if type(obj) == "IsoZombie" then ... end

-- CORRECT: Use instanceof()
if instanceof(obj, "IsoZombie") then ... end
```

Common class names for instanceof:
- `"IsoZombie"` - Zombie NPCs
- `"IsoPlayer"` - Player characters
- `"IsoGameCharacter"` - Base class for zombies and players
- `"IsoObject"` - Base class for world objects
- `"IsoThumpable"` - Player-built structures
- `"IsoBarricade"` - Barricades
- `"IsoDoor"` - Doors
- `"IsoWindow"` - Windows
- `"BaseVehicle"` - Vehicles
- `"IsoMovingObject"` - Anything that moves
- `"BarricadeAble"` - Objects that can be barricaded

### Java Collections
PZ exposes Java collections that use 0-based indexing and method calls:

```lua
-- Java ArrayList iteration
local list = getOnlinePlayers()
if list then
    for i = 0, list:size() - 1 do
        local player = list:get(i)
        -- process player
    end
end

-- Java HashMap
local map = obj:getModData()
-- ModData acts like a Lua table but is actually a Java HashMap
map.myKey = "myValue"
local val = map.myKey
```

**Critical: Java collections use 0-based indexing, Lua tables use 1-based indexing.**

### Calling Java Methods
Java methods are called with `:` syntax on Java objects:

```lua
local zombie = ...  -- an IsoZombie instance
local health = zombie:getHealth()
zombie:setHealth(0.5)
local x = zombie:getX()
local sq = zombie:getSquare()
local cell = sq:getCell()
```

### Nil Safety with Java Objects
Java methods can return `nil` (Java `null`). Always nil-check:

```lua
-- WRONG: Will crash if getSquare() returns nil
local cell = zombie:getSquare():getCell()

-- CORRECT: Check each step
local sq = zombie:getSquare()
if sq then
    local cell = sq:getCell()
    if cell then
        -- safe to use cell
    end
end
```

## Common Pitfalls

### 1. No `goto` for Early Returns in Loops
```lua
-- WRONG: goto is Lua 5.2+
for i = 1, 10 do
    if shouldSkip(i) then goto continue end
    doWork(i)
    ::continue::
end

-- CORRECT: Use conditional block
for i = 1, 10 do
    if not shouldSkip(i) then
        doWork(i)
    end
end
```

### 2. No Bitwise Operations
```lua
-- WRONG: Bitwise operators are Lua 5.3+
local masked = value & 0xFF
local shifted = value >> 4

-- CORRECT: Use math
local masked = value % 256
local shifted = math.floor(value / 16)

-- Or use a bit library if one is available:
-- Some PZ versions may expose bit32 or similar
```

### 3. table.pack / table.unpack
```lua
-- WRONG
local packed = table.pack(1, 2, 3)
local a, b, c = table.unpack(packed)

-- CORRECT
local packed = {1, 2, 3}
local a, b, c = unpack(packed)
```

### 4. String Patterns vs Regex
Kahlua2 uses Lua patterns, not regular expressions:

```lua
-- Lua patterns (these work):
string.find(str, "^SVU_Armor_")     -- Anchored start
string.find(str, "Engine$")          -- Anchored end
string.find(str, "%d+")             -- One or more digits
string.find(str, "[A-Z]")           -- Character class
string.gsub(str, "%s+", "")         -- Remove whitespace

-- These do NOT work (regex syntax):
-- string.find(str, "\\d+")          -- Use %d+ instead
-- string.find(str, "(?:group)")     -- No non-capturing groups
-- string.find(str, "a{3}")          -- No repetition counts
```

### 5. File I/O
```lua
-- WRONG: io library not available
local f = io.open("file.txt", "r")

-- CORRECT: Use PZ's file functions
local reader = getFileReader("MyMod/data.txt", false)
if reader then
    local line = reader:readLine()
    while line do
        -- process line
        line = reader:readLine()
    end
    reader:close()
end

local writer = getFileWriter("MyMod/data.txt", true, false)
if writer then
    writer:write("Hello world\n")
    writer:close()
end
```

### 6. table.wipe (PZ-Specific)
PZ provides `table.wipe()` as an efficient way to clear a table. It is not standard Lua:

```lua
-- PZ-specific: fast table clear
if table.wipe then
    table.wipe(myTable)
else
    -- Fallback for standard Lua
    for k in pairs(myTable) do myTable[k] = nil end
end
```

### 7. Absolute vs Relative Require
PZ's `require` uses a specific path resolution. Shared modules can be required across
client/server boundaries:

```lua
-- Require a shared module from anywhere
require("MyModCore")   -- Looks in shared/ lua path

-- Avoid relative paths; PZ resolves from the mod's lua directories
```

### 8. Semicolons Are Optional but Harmless
Kahlua2 accepts semicolons like standard Lua. They are optional:

```lua
local x = 1;   -- Works fine
local y = 2    -- Also fine
```

### 9. String Coercion from Java
When reading Java string properties, the result may be a Java String object rather than
a Lua string. Use `tostring()` to be safe:

```lua
local name = tostring(script:getName())
```

### 10. Nil in Table Sequences
Kahlua2 follows Lua 5.1 behavior where `#` operator on tables with nil holes is undefined:

```lua
-- DANGEROUS: Don't create sparse arrays
local t = {1, nil, 3}
print(#t)  -- Could be 1 or 3, behavior is undefined

-- SAFE: Use explicit count or ipairs
local count = 0
for _ in ipairs(t) do count = count + 1 end
```

## Performance Tips

1. **Cache globals and functions locally** at the top of your file:
   ```lua
   local print = print
   local math_floor = math.floor
   local instanceof = instanceof
   ```

2. **Reuse tables** instead of creating new ones each frame:
   ```lua
   local cache = {}
   local function clearTable(tbl)
       if table.wipe then table.wipe(tbl)
       else for k in pairs(tbl) do tbl[k] = nil end end
   end
   ```

3. **Avoid string concatenation in tight loops** - use `string.format()` or
   `table.concat()` instead.

4. **Guard expensive debug logging** with a check:
   ```lua
   if DEBUG_MODE then
       debugPrint(string.format("Expensive: %s", tostring(obj)))
   end
   ```

5. **Use tick counters** instead of processing every frame:
   ```lua
   local counter = 0
   local function onTick()
       counter = counter + 1
       if counter < 100 then return end
       counter = 0
       -- Do real work here
   end
   ```

## Testing Compatibility

When unsure if a feature works, test it in the PZ Lua console:
1. Start Project Zomboid
2. Open the debug console (enable debug mode in launch options)
3. Test your code snippets directly

Or create a minimal test mod that exercises the feature and check the console log for errors.
