# Input System and Keybindings - PZ Data Map
Source: projectzomboid.jar (decompiled) | media/lua | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture Overview | 20-42 |
| 2 | GameKeyboard - Keyboard Input | 44-87 |
| 3 | Mouse Input | 89-144 |
| 4 | JoypadManager - Controller Support | 146-186 |
| 5 | Key Binding System (Core.KeyBinding) | 188-224 |
| 6 | Default Key Bindings Table | 226-332 |
| 7 | Input Lua Events | 334-378 |
| 8 | Adding Custom Keybindings (Mods) | 380-438 |
| 9 | Key Codes Reference | 440-528 |
| 10 | Input Blocking and Consuming | 530-575 |

---

## 1. Architecture Overview

PZ input flows through a cached state system with Lua event dispatch:

```
Hardware (LWJGL) -> StateCache (double-buffered) -> GameKeyboard/Mouse update()
  -> State comparison (pressed/released/held) -> LuaEventManager.triggerEvent()
    -> Lua event handlers (mod callbacks)
```

**Key Java classes:**
- `zombie.input.GameKeyboard` - keyboard state tracking and Lua event dispatch
- `zombie.input.Mouse` - mouse button/position tracking
- `zombie.input.JoypadManager` - controller detection, mapping, config
- `zombie.input.KeyboardState` / `KeyboardStateCache` - double-buffered keyboard state
- `zombie.input.MouseState` / `MouseStateCache` - double-buffered mouse state
- `zombie.input.ControllerState` / `ControllerStateCache` - double-buffered controller state
- `zombie.core.Core` - key binding registry (`addKeyBinding`, `getKey`, `getKeyBinding`)
- `zombie.ui.UIManager` - mouse event dispatch (converts raw input to Lua events)

**Double-buffer pattern:** Each input source uses a cache with two state slots. The render thread writes to one slot while the game thread reads from the other. `swap()` flips the buffers each frame.

---

## 2. GameKeyboard - Keyboard Input

**GameKeyboard** (`zombie.input.GameKeyboard`) - `@UsedFromLua`

Core keyboard handler. Maintains per-key state arrays for current frame and previous frame.

**State tracking:**
```java
boolean[] down      // current frame key states
boolean[] lastDown  // previous frame key states
boolean[] eatKey    // keys suppressed this frame
```

**Key state methods:**

| Method | Signature | Description |
|-|-|-|
| `isKeyDown` | `(int key)` | Key currently held (respects bindings, shift/ctrl checks) |
| `isKeyDown` | `(String keyName)` | Check by binding name (primary or alt key) |
| `isKeyPressed` | `(int key)` | Key just pressed this frame (down && !lastDown) |
| `isKeyPressed` | `(String keyName)` | Pressed check by binding name |
| `wasKeyDown` | `(int key)` | Key was held previous frame |
| `wasKeyDown` | `(String keyName)` | Previous frame check by binding name |
| `isKeyDownRaw` | `(int key)` | Raw key state (no binding/modifier checks) |
| `wasKeyDownRaw` | `(int key)` | Raw previous frame state |
| `whichKeyPressed` | `(String keyName)` | Returns which key ID triggered (primary or alt) |
| `whichKeyDown` | `(String keyName)` | Returns which bound key is currently held |
| `eatKeyPress` | `(int key)` | Suppress a key's released event this frame |
| `setDoLuaKeyPressed` | `(boolean doIt)` | Enable/disable Lua key event dispatch |

**Mouse button as keyboard key:** Keys with ID >= 10000 are mapped to mouse buttons (`Mouse.BTN_OFFSET = 10000`). `isKeyDown(10001)` checks right mouse button.

**Text entry guard:** When `Core.currentTextEntryBox` is active, `isKeyDown`/`wasKeyDown` return false to prevent game actions during text input.

**Update cycle (per frame):**
1. Copy `down[]` to `lastDown[]`
2. Read new state from `KeyboardStateCache`
3. For each key, detect transitions:
   - `!down && lastDown` (released): fire `OnKeyPressed`, `OnCustomUIKey`, `OnCustomUIKeyReleased`
   - `down && lastDown` (held): fire `OnKeyKeepPressed`
   - `down && !lastDown` (just pressed): fire `OnKeyStartPressed`, `OnCustomUIKeyPressed`
4. Events skip if: loading, doing text entry, or UI consumed the key

---

## 3. Mouse Input

**Mouse** (`zombie.input.Mouse`) - `@UsedFromLua`

**Button constants:**

| Constant | Value | Description |
|-|-|-|
| `Mouse.BTN_OFFSET` | 10000 | Base offset for mouse-as-keyboard mapping |
| `Mouse.LMB` / `BTN_0` | 10000 | Left mouse button |
| `Mouse.RMB` / `BTN_1` | 10001 | Right mouse button |
| `Mouse.MMB` / `BTN_2` | 10002 | Middle mouse button |
| `Mouse.BTN_3` - `BTN_7` | 10003-10007 | Extra mouse buttons |

**State arrays:**
```java
boolean[] buttonDownStates  // current frame
boolean[] buttonPrevStates  // previous frame
boolean[] uiCaptured        // button consumed by UI
int wheelDelta              // scroll wheel delta
```

**Convenience methods:**

| Method | Description |
|-|-|
| `isLeftDown()` / `isLeftPressed()` / `isLeftReleased()` / `isLeftUp()` | Left button states |
| `isRightDown()` / `isRightPressed()` / `isRightReleased()` / `isRightUp()` | Right button states |
| `isMiddleDown()` / `isMiddlePressed()` / `isMiddleReleased()` | Middle button states |
| `isButtonDown(n)` | Generic button check |
| `isButtonPressed(n)` | Just-pressed check (!prev && current) |
| `isButtonReleased(n)` | Just-released check (prev && !current) |
| `getX()` / `getY()` | Mouse position (zoom-scaled) |
| `getXA()` / `getYA()` | Mouse position (absolute/unscaled) |
| `getWheelState()` | Scroll wheel delta |
| `UIBlockButtonDown(n)` | Mark button as consumed by UI |
| `isButtonDownUICheck(n)` | Check button, respecting UI consumption |

**Right-click delay:** Right mouse button has a built-in 0.15s delay (`TIME_RIGHT_PRESSED_SECONDS`) before `isRightDelay()` returns true. This prevents accidental right-clicks during fast actions.

**Mouse events** (dispatched by `UIManager`, not `Mouse` directly):

| Event | Parameters | Trigger |
|-|-|-|
| `OnMouseDown` | `(x, y)` | Left button pressed |
| `OnMouseUp` | `(x, y)` | Left button released |
| `OnRightMouseDown` | `(x, y)` | Right button pressed |
| `OnRightMouseUp` | `(x, y)` | Right button released |
| `OnMouseMove` | `(x, y, dx, dy)` | Mouse moved |
| `OnMouseWheel` | `(delta)` | Scroll wheel rotated |
| `OnObjectLeftMouseButtonDown` | `(obj, x, y)` | Left click on world object |
| `OnObjectLeftMouseButtonUp` | `(obj, x, y)` | Left release on world object |
| `OnObjectRightMouseButtonDown` | `(obj, x, y)` | Right click on world object |
| `OnObjectRightMouseButtonUp` | `(obj, x, y)` | Right release on world object |

---

## 4. JoypadManager - Controller Support

**JoypadManager** (`zombie.input.JoypadManager`)

Manages up to 4 active gamepads (`joypads[4]`) with up to 16 physical controllers detected (`joypadsController[16]`).

**Joypad configuration** (per-controller, saved to `joypads/<guid>.config`):

| Config Key | Type | Description |
|-|-|-|
| `MovementAxisX/Y` | int | Axis indices for movement stick |
| `MovementAxisXFlipped/YFlipped` | bool | Invert movement axes |
| `MovementAxisDeadZone` | float | Movement stick dead zone |
| `AimingAxisX/Y` | int | Axis indices for aiming stick |
| `AimingAxisXFlipped/YFlipped` | bool | Invert aiming axes |
| `AimingAxisDeadZone` | float | Aiming stick dead zone |
| `AButton` / `BButton` / `XButton` / `YButton` | int | Face button indices |
| `LBumper` / `RBumper` | int | Shoulder button indices |
| `L3` / `R3` | int | Stick click button indices |
| `Back` / `Start` | int | Menu button indices |
| `DPadUp/Down/Left/Right` | int | D-pad button indices |
| `TriggerLeft` / `TriggerRight` | int | Trigger axis indices |
| `TriggersFlipped` | bool | Swap triggers |
| `Sensitivity` | float | Dead zone sensitivity |
| `Disabled` | bool | Controller disabled |

**Joypad Lua events:**

| Event | Parameters | Description |
|-|-|-|
| `OnJoypadActivate` | `(joypadId)` | Controller activated for gameplay |
| `OnJoypadActivateUI` | `(joypadId)` | Controller activated for UI |
| `OnJoypadBeforeDeactivate` | `(joypadId)` | About to deactivate |
| `OnJoypadDeactivate` | `(joypadId)` | Controller deactivated |
| `OnJoypadBeforeReactivate` | `(joypadId)` | About to reactivate |
| `OnJoypadReactivate` | `(joypadId)` | Controller reactivated |
| `OnJoypadRenderUI` | - | Joypad UI render pass |

**Split-screen:** Each joypad maps to a player index (0-3). The `joypads[]` array tracks which controller is assigned to which player slot.

---

## 5. Key Binding System (Core.KeyBinding)

**Core.addKeyBinding** (`zombie.core.Core`)

Bindings are name-to-key mappings stored in `keyMaps` (HashMap\<String, KeyBinding\>).

```java
// Java binding registration
public void addKeyBinding(String keyName, int key, int altKey, boolean shift, boolean ctrl, boolean alt)
```

**KeyBinding record fields:**
- `keyValue` - primary key code
- `altKey` - alternate key code
- `shift` / `ctrl` / `alt` - modifier requirements

**Binding lookup methods:**

| Method | Description |
|-|-|
| `getKey(keyName)` | Get primary key code for binding name |
| `getAltKey(keyName)` | Get alt key code for binding name |
| `getKeyBinding(keyName)` | Get full KeyBinding object by name |
| `getKeyBinding(keyId)` | Get KeyBinding by key code (reverse lookup) |
| `invalidBindingShiftCtrl(keyB)` | Check if shift/ctrl modifiers conflict |

**Lua-exposed key functions:**

| Function | Signature | Description |
|-|-|-|
| `getKeyName` | `(keyCode)` -> String | Get display name for a key code |
| `Keyboard.KEY_*` | constants | LWJGL key code constants (exposed as Lua globals) |
| `Mouse.LMB` / `Mouse.RMB` / `Mouse.MMB` | constants | Mouse button constants for keybindings |
| `GameKeyboard.isKeyDown` | `(key)` -> bool | Check if key is held |
| `GameKeyboard.isKeyPressed` | `(keyName)` -> bool | Check if named binding was just pressed |

---

## 6. Default Key Bindings Table

Defined in `media/lua/shared/keyBinding.lua`. Bindings are organized into categories.

**Player Control:**

| Binding Name | Default Key | Description |
|-|-|-|
| Forward | W | Move forward |
| Backward | S | Move backward |
| Left | A | Strafe left |
| Right | D | Strafe right |
| Run | LSHIFT | Hold to run |
| Interact | E | Context interaction |
| Sprint | LMENU (Alt) / LMETA (Mac) | Sprint toggle |
| Rotate building | R | Rotate placement |
| Toggle mode | TAB | Switch modes |
| CancelAction | ESCAPE | Cancel current action |
| WalkTo | Y | Walk-to click mode |
| ReleaseRope | (None) | Release rope |

**Combat:**

| Binding Name | Default Key | Description |
|-|-|-|
| Attack/Click | Mouse.LMB | Primary attack / click |
| Crouch | C | Toggle crouch |
| Aim | LCONTROL (alt: Mouse.RMB) | Hold to aim |
| Melee | SPACE | Melee attack |
| Rack Firearm | X | Rack weapon slide |
| ReloadWeapon | R | Reload firearm |
| SharpenWeapon | R | Sharpen melee weapon |
| ManualFloorAtk | LMENU | Manual floor attack |

**Vehicle:**

| Binding Name | Default Key | Description |
|-|-|-|
| StartVehicleEngine | N | Start/stop engine |
| Brake | SPACE | Vehicle brake |
| CruiseControl | LSHIFT | Cruise control |
| ToggleVehicleHeadlights | F | Toggle headlights |
| VehicleHeater | O | Toggle heater |
| VehicleMechanics | U | Open mechanics UI |
| VehicleHorn | Q | Sound horn |
| VehicleRadialMenu | V | Vehicle radial menu |
| VehicleSwitchSeat | Z | Switch seat |

**UI:**

| Binding Name | Default Key | Description |
|-|-|-|
| Toggle UI | (None) | Show/hide all UI |
| Crafting UI | B | Open crafting |
| Building UI | (None) | Open building |
| Main Menu | ESCAPE | Open main menu |
| Toggle Inventory | I | Inventory panel |
| Toggle Skill Panel | L | Skills panel |
| Toggle Health Panel | H | Health panel |
| Toggle Info Panel | J | Info panel |
| Toggle Clothing Protection Panel | P | Clothing panel |
| Toggle Moveable Panel Mode | RBRACKET (]) | Moveable mode |
| Map | M | Open map |
| AnimalRadialMenu | V | Animal radial menu |
| Take screenshot | F10 | Screenshot |
| Toggle Survival Guide | F1 | Survival guide |
| Pause | F2 | Pause game |
| Normal Speed | F3 | 1x speed |
| Fast Forward x1 | F4 | 2x speed |
| Fast Forward x2 | F5 | 4x speed |
| Fast Forward x3 | F6 | 8x speed |
| PanCamera | (None) | Pan camera mode |
| Zoom in | EQUALS (=) | Zoom in |
| Zoom out | MINUS (-) | Zoom out |

**Hotkeys:**

| Binding Name | Default Key | Description |
|-|-|-|
| Hotbar 1-8 | 1-8 | Equip hotbar slot |
| Equip/Turn On/Off Light Source | F | Toggle light source |
| DropBothHeldItems | (None) | Drop both hands |
| DropPrimaryHeldItem | (None) | Drop primary hand |
| DropSecondaryHeldItem | (None) | Drop secondary hand |
| DropWornBag | (None) | Drop worn bag |
| DropBothHeldItemsAndWornBag | (None) | Drop everything |
| GrabCorpse | (None) | Pick up corpse |

**Multiplayer / Voice / NPC / Debug:**

| Binding Name | Default Key | Description |
|-|-|-|
| Toggle Safety | G | Toggle PvP safety |
| Toggle chat | T | Open chat |
| Alt toggle chat | RETURN | Alt chat open |
| Switch chat stream | TAB | Switch chat channel |
| Enable voice transmit | LMENU | Push-to-talk |
| Shout | Q | Shout to attract |
| Emote | Q | Open emote wheel |
| Toggle Music | (None) | Toggle music |
| Toggle Lua Debugger | F11 | Lua debugger |
| ToggleLuaConsole | GRAVE (`) | Lua console |
| ToggleGodModeInvisible | N | God mode (debug) |
| ToggleModelsEnabled | F3 | Toggle models (debug) |
| ToggleAnimationText | F6 | Anim debug text (debug) |

---

## 7. Input Lua Events

All input events registered in `LuaEventManager`:

**Keyboard events:**

| Event | Parameters | When Fired |
|-|-|-|
| `OnKeyStartPressed` | `(keyCode)` | Key just pressed this frame |
| `OnKeyPressed` | `(keyCode)` | Key released (confusing name, but it fires on release) |
| `OnKeyKeepPressed` | `(keyCode)` | Key held down (fires every frame) |
| `OnCustomUIKey` | `(keyCode)` | Key released (fires regardless of doLuaKeyPressed) |
| `OnCustomUIKeyPressed` | `(keyCode)` | Key just pressed (fires regardless of doLuaKeyPressed) |
| `OnCustomUIKeyReleased` | `(keyCode)` | Key released (fires regardless of doLuaKeyPressed) |

**Important:** `OnKeyPressed` fires on key RELEASE, not press. Use `OnKeyStartPressed` for the actual press event.

**Mouse events:**

| Event | Parameters | When Fired |
|-|-|-|
| `OnMouseDown` | `(x, y)` | Left button pressed |
| `OnMouseUp` | `(x, y)` | Left button released |
| `OnRightMouseDown` | `(x, y)` | Right button pressed |
| `OnRightMouseUp` | `(x, y)` | Right button released |
| `OnMouseMove` | `(x, y, dx, dy)` | Mouse moved |
| `OnMouseWheel` | `(delta)` | Scroll wheel |
| `OnObjectLeftMouseButtonDown` | `(object, x, y)` | Left click on ISO object |
| `OnObjectLeftMouseButtonUp` | `(object, x, y)` | Left release on ISO object |
| `OnObjectRightMouseButtonDown` | `(object, x, y)` | Right click on ISO object |
| `OnObjectRightMouseButtonUp` | `(object, x, y)` | Right release on ISO object |

**Controller events:**

| Event | Parameters | When Fired |
|-|-|-|
| `OnJoypadActivate` | `(joypadId)` | Controller assigned to player |
| `OnJoypadActivateUI` | `(joypadId)` | Controller activated for UI nav |
| `OnJoypadDeactivate` | `(joypadId)` | Controller removed |
| `OnJoypadReactivate` | `(joypadId)` | Controller re-assigned |
| `OnJoypadBeforeDeactivate` | `(joypadId)` | Pre-deactivation hook |
| `OnJoypadBeforeReactivate` | `(joypadId)` | Pre-reactivation hook |
| `OnJoypadRenderUI` | - | Controller UI render pass |

---

## 8. Adding Custom Keybindings (Mods)

**Method 1: keyBinding.lua extension**

Create a file loaded after the base `keyBinding.lua`:

```lua
-- media/lua/shared/mymod_keybindings.lua
local bind = {}
bind.value = "[My Mod]"
table.insert(keyBinding, bind)

bind = {}
bind.value = "MyModAction"
bind.key = Keyboard.KEY_G
table.insert(keyBinding, bind)

bind = {}
bind.value = "MyModAltAction"
bind.key = Keyboard.KEY_NONE  -- unbound by default
table.insert(keyBinding, bind)
```

Entries with `[brackets]` in the value become category headers in the options UI.

**Method 2: Responding to key events**

```lua
local function onKeyStartPressed(key)
    if key == getCore():getKey("MyModAction") then
        -- handle key press
    end
end
Events.OnKeyStartPressed.Add(onKeyStartPressed)
```

**Method 3: Polling in OnTick**

```lua
local function onTick()
    if GameKeyboard.isKeyDown(getCore():getKey("MyModAction")) then
        -- action while held
    end
    if GameKeyboard.isKeyPressed("MyModAction") then
        -- action on press (checks both primary and alt key)
    end
end
Events.OnTick.Add(onTick)
```

**Best practices for mod keybindings:**
- Default to `Keyboard.KEY_NONE` for optional bindings to avoid conflicts
- Use `bind.alt = Keyboard.KEY_*` for alternate key support
- Category headers `[My Mod]` group your bindings in the options menu
- Always use named binding lookups (`getCore():getKey("Name")`) instead of hardcoded key codes
- Check `isKeyPressed` (press edge) vs `isKeyDown` (held) based on your needs
- The binding name (bind.value) is what players see in Options > Key Bindings

---

## 9. Key Codes Reference

PZ uses LWJGL key codes (exposed as `Keyboard.KEY_*` in Lua). Common codes:

**Letters:**

| Constant | Value | Constant | Value |
|-|-|-|-|
| `KEY_A` | 30 | `KEY_N` | 49 |
| `KEY_B` | 48 | `KEY_O` | 24 |
| `KEY_C` | 46 | `KEY_P` | 25 |
| `KEY_D` | 32 | `KEY_Q` | 16 |
| `KEY_E` | 18 | `KEY_R` | 19 |
| `KEY_F` | 33 | `KEY_S` | 31 |
| `KEY_G` | 34 | `KEY_T` | 20 |
| `KEY_H` | 35 | `KEY_U` | 22 |
| `KEY_I` | 23 | `KEY_V` | 47 |
| `KEY_J` | 36 | `KEY_W` | 17 |
| `KEY_K` | 37 | `KEY_X` | 45 |
| `KEY_L` | 38 | `KEY_Y` | 21 |
| `KEY_M` | 50 | `KEY_Z` | 44 |

**Numbers:**

| Constant | Value | Constant | Value |
|-|-|-|-|
| `KEY_1` | 2 | `KEY_6` | 7 |
| `KEY_2` | 3 | `KEY_7` | 8 |
| `KEY_3` | 4 | `KEY_8` | 9 |
| `KEY_4` | 5 | `KEY_9` | 10 |
| `KEY_5` | 6 | `KEY_0` | 11 |

**Function keys:**

| Constant | Value | Constant | Value |
|-|-|-|-|
| `KEY_F1` | 59 | `KEY_F7` | 65 |
| `KEY_F2` | 60 | `KEY_F8` | 66 |
| `KEY_F3` | 61 | `KEY_F9` | 67 |
| `KEY_F4` | 62 | `KEY_F10` | 68 |
| `KEY_F5` | 63 | `KEY_F11` | 87 |
| `KEY_F6` | 64 | `KEY_F12` | 88 |

**Modifiers and special keys:**

| Constant | Value | Description |
|-|-|-|
| `KEY_LSHIFT` | 42 | Left Shift |
| `KEY_RSHIFT` | 54 | Right Shift |
| `KEY_LCONTROL` | 29 | Left Control |
| `KEY_RCONTROL` | 157 | Right Control |
| `KEY_LMENU` | 56 | Left Alt |
| `KEY_RMENU` | 184 | Right Alt |
| `KEY_LMETA` | 219 | Left Windows/Command |
| `KEY_SPACE` | 57 | Spacebar |
| `KEY_RETURN` | 28 | Enter |
| `KEY_ESCAPE` | 1 | Escape |
| `KEY_TAB` | 15 | Tab |
| `KEY_BACK` | 14 | Backspace |
| `KEY_DELETE` | 211 | Delete |
| `KEY_INSERT` | 210 | Insert |
| `KEY_HOME` | 199 | Home |
| `KEY_END` | 207 | End |
| `KEY_GRAVE` | 41 | Backtick/Tilde |
| `KEY_MINUS` | 12 | Minus |
| `KEY_EQUALS` | 13 | Equals |
| `KEY_LBRACKET` | 26 | Left bracket |
| `KEY_RBRACKET` | 27 | Right bracket |
| `KEY_NONE` | 0 | No key (unbound) |

**Arrow keys:**

| Constant | Value |
|-|-|
| `KEY_UP` | 200 |
| `KEY_DOWN` | 208 |
| `KEY_LEFT` | 203 |
| `KEY_RIGHT` | 205 |

**Mouse button codes (for keybindings):**

| Constant | Value | Description |
|-|-|-|
| `Mouse.LMB` / `Mouse.BTN_0` | 10000 | Left mouse |
| `Mouse.RMB` / `Mouse.BTN_1` | 10001 | Right mouse |
| `Mouse.MMB` / `Mouse.BTN_2` | 10002 | Middle mouse |
| `Mouse.BTN_3` - `Mouse.BTN_7` | 10003-10007 | Extra buttons |

---

## 10. Input Blocking and Consuming

**Keyboard blocking:**

| Mechanism | Description |
|-|-|
| `GameKeyboard.eatKeyPress(key)` | Suppress the release event for a key this frame |
| `GameKeyboard.setDoLuaKeyPressed(false)` | Disable `OnKeyPressed`/`OnKeyStartPressed`/`OnKeyKeepPressed` events globally |
| Text entry active | All `isKeyDown`/`wasKeyDown` return false when a text box is focused |
| `UIManager.onKeyPress(key)` | UI system consumes the key first; if handled, no Lua event fires |

**Mouse blocking:**

| Mechanism | Description |
|-|-|
| `Mouse.UIBlockButtonDown(button)` | Mark a button as consumed by UI |
| `Mouse.isButtonDownUICheck(button)` | Returns false if UI consumed the button |
| `Mouse.uiCaptured[]` | Per-button UI capture state; auto-resets when button released |

**Event dispatch order:**
1. UI system gets first look (`UIManager.onKeyPress` / `UIManager.onMouseDown`)
2. If UI handles it, no Lua event fires
3. If UI passes, Lua events fire (`OnKeyStartPressed`, etc.)
4. `OnCustomUIKey*` events fire regardless of `doLuaKeyPressed` flag (always active)

**Practical blocking patterns for mods:**

```lua
-- Consume a key so other handlers don't see it
local function onKeyStartPressed(key)
    if key == getCore():getKey("MyAction") then
        doMyThing()
        GameKeyboard.eatKeyPress(key)  -- prevent OnKeyPressed from firing
    end
end
Events.OnKeyStartPressed.Add(onKeyStartPressed)

-- Check for UI focus before handling input
local function onTick()
    if UIManager.getUI() == nil then return end  -- no UI active
    if getCore():isTextEntryActive() then return end  -- typing in a box
    -- safe to handle game input here
end
```

**Guard against text entry:** Always check `Core.currentTextEntryBox` state or use the binding system (which handles this automatically) rather than raw key checks when processing gameplay input.
