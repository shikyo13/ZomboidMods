# Java UI Framework - PZ Data Map
Source: projectzomboid.jar (decompiled) zombie.ui.* | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture Overview | 19-42 |
| 2 | UIManager | 43-112 |
| 3 | UIElement (Java Base) | 113-171 |
| 4 | Lua-Java Bridge | 172-218 |
| 5 | Input Handling Pipeline | 219-267 |
| 6 | Font System | 268-315 |
| 7 | Rendering Pipeline | 316-362 |
| 8 | Screen Resolution and Scaling | 363-397 |
| 9 | Z-Order and Layering | 398-421 |
| 10 | UITransition | 422-450 |
| 11 | Key Java UI Classes | 451-496 |

## 1. Architecture Overview

PZ uses a two-layer UI system: Java provides the rendering engine, input dispatch, and element tree management. Lua provides the widget logic, layout, and mod-facing API.

```
  Lua Layer (IS* classes)              Java Layer
  -------------------------            -------------------------
  ISUIElement                          UIElement
    .javaObject ----------------------> KahluaTable reference
    :prerender()                       render() dispatches to Lua
    :render()                          update() dispatches to Lua
    :onMouseDown()                     Mouse/keyboard routing
    :addChild() ----------------------> AddChild(UIElement)
                                       UIManager (static singleton)
                                         - ArrayList<UIElementInterface> UI
                                         - render loop
                                         - update loop
                                         - input dispatch
```

**Key principle:** Lua IS* classes are the "brain", Java UIElement is the "body". Each Lua widget holds a `javaObject` reference (a Java UIElement). The Java side handles coordinate transforms, stencil clipping, scroll offsets, and low-level GL rendering. The Lua side handles all widget behavior, layout decisions, and event responses.

**Entry point:** `UIManager.init()` is called on game start. It creates core UI (clock, moodles, speed controls, debug console, tooltips, progress bars) then fires `LuaEventManager.triggerEvent("OnCreateUI")` for Lua to build the rest.

## 2. UIManager

**File:** `zombie/ui/UIManager.java`
**Type:** Static singleton (all methods/fields are static)

### Core State
| Field | Type | Purpose |
|-|-|-|
| `UI` | `ArrayList<UIElementInterface>` | All top-level UI elements |
| `toAdd` | `ArrayList<UIElementInterface>` | Pending additions (applied next frame) |
| `toRemove` | `ArrayList<UIElementInterface>` | Pending removals |
| `toTop` | `ArrayList<UIElementInterface>` | Elements to bring to front |
| `clock` | `Clock` | Game clock widget |
| `toolTip` | `ObjectTooltip` | Item tooltip overlay |
| `speedControls` | `SpeedControls` | Speed control panel |
| `debugConsole` | `UIDebugConsole` | Debug console |
| `MoodleUI[4]` | `MoodlesUI` | Per-player moodle displays |
| `ProgressBar[4]` | `ActionProgressBar` | Per-player action bars |
| `modal` | `ModalDialog` | Current modal dialog |

### Element Management
| Method | Purpose |
|-|-|
| `AddUI(UIElementInterface)` | Queue element for addition. Lua: `addToUIManager()` |
| `RemoveElement(UIElementInterface)` | Queue element for removal. Lua: `removeFromUIManager()` |
| `clearArrays()` | Clear all queues and UI list |
| `init()` | Full UI initialization, fires "OnCreateUI" event |
| `resize()` | Reposition elements for screen size change |

### Render/Update Cycle
| Method | Purpose |
|-|-|
| `render()` | Main render pass - iterates UI list, calls each element's `render()` |
| `update()` | Main update pass - calls `update()` on each element, handles input |
| `renderFadeOverlay()` | Screen fade in/out effect |

### Fade System
| Method | Purpose |
|-|-|
| `FadeIn(seconds)` | Start fade-in transition |
| `FadeOut(seconds)` | Start fade-out transition |
| `fadeAlpha` | Current fade opacity (0-1) |
| `fadeBeforeUi` | If true, fade renders behind UI, else over it |

### Timing
| Field | Purpose |
|-|-|
| `uiRenderTimeMS` | Timestamp of last render |
| `uiRenderIntervalMS` | MS since last render (for animations) |
| `uiUpdateTimeMS` | Timestamp of last update |
| `uiUpdateIntervalMS` | MS since last update |

Use `UIManager.getMillisSinceLastRender()` from Lua for frame-rate-independent animation.

### FBO (Framebuffer Object)
| Field | Purpose |
|-|-|
| `useUiFbo` | Enable UI framebuffer for performance |
| `uiFbo` | TextureFBO for offscreen UI rendering |
| `uiTextureContentsValid` | Whether FBO needs redraw |

When enabled, UI renders to an offscreen texture and composites to screen. This allows skipping UI re-render on frames where nothing changed.

### Lua Events Fired
| Event | When |
|-|-|
| `OnCreateUI` | After `init()`, for mods to build UI |
| `OnPreUIDraw` | Before UI render pass |
| `OnPostUIDraw` | After UI render pass |

## 3. UIElement (Java Base)

**File:** `zombie/ui/UIElement.java`
**Implements:** `UIElementInterface`

### Core Fields
| Field | Type | Default | Purpose |
|-|-|-|-|
| `x, y` | `double` | 0 | Position relative to parent |
| `width, height` | `float` | 256 | Dimensions |
| `visible` | `boolean` | true | Visibility flag |
| `parent` | `UIElement` | null | Parent element |
| `controls` | `ArrayList<UIElement>` | [] | Child elements |
| `table` | `KahluaTable` | - | Lua table reference (the IS* instance) |
| `capture` | `boolean` | false | Captures all mouse events |
| `anchorTop/Bottom/Left/Right` | `boolean` | T:true, others:false | Resize anchoring |
| `alwaysOnTop` | `boolean` | false | Render last (on top) |
| `alwaysBack` | `boolean` | false | Render first (behind) |
| `followGameWorld` | `boolean` | false | Move with game camera |
| `renderThisPlayerOnly` | `int` | -1 | Player filter (-1 = all) |
| `maxDrawHeight` | `int` | -1 | Clip height (-1 = none) |
| `scrollChildren` | `boolean` | false | Children scroll with parent |
| `scrollWithParent` | `boolean` | true | This scrolls with parent |
| `enabled` | `boolean` | true | Interaction enabled |
| `xScroll, yScroll` | `Double` | 0.0 | Scroll offsets |
| `scrollHeight` | `int` | 0 | Virtual content height |
| `consumeMouseEvents` | `boolean` | true | Prevent click-through |
| `wantKeyEvents` | `boolean` | false | Receive keyboard events |
| `wantExtraMouseEvents` | `boolean` | false | Receive extra mouse events |
| `forceCursorVisible` | `boolean` | false | Show cursor when over element |

### Child Management
| Method | Purpose |
|-|-|
| `AddChild(UIElement)` | Add to controls list, set parent |
| `RemoveChild(UIElement)` | Remove from controls list, clear parent |
| `ClearChildren()` | Remove all children |

### Coordinate Methods
| Method | Returns |
|-|-|
| `getAbsoluteX()` | Screen X (walks parent chain) |
| `getAbsoluteY()` | Screen Y (walks parent chain) |
| `isMouseOver()` | True if mouse within bounds |
| `isPointOver(screenX, screenY)` | Point-in-rect test |
| `clampToParentX(absX)` | Clamp X to parent stencil |
| `clampToParentY(absY)` | Clamp Y to parent stencil |

### Resize System
| Field | Purpose |
|-|-|
| `lastheight, lastwidth` | Previous dimensions for change detection |
| `resizeDirty` | Flags pending resize |

When parent resizes, children with anchors are repositioned. Java calls `onResize()` which dispatches to the Lua-side `onResize()` method. Anchoring rules:
- `anchorLeft + anchorRight`: width stretches with parent
- `anchorTop + anchorBottom`: height stretches with parent
- Only one side anchored: position fixed to that edge

## 4. Lua-Java Bridge

### How IS* connects to UIElement

When Lua calls `ISUIElement:instantiate()`:
```lua
self.javaObject = UIElement.new(self)  -- Java constructor receives Lua table
```
The Java UIElement stores `self` (the Lua table) in its `table` field. When Java needs to call Lua methods (prerender, render, update, mouse events), it looks up methods on this table via Kahlua.

### Event dispatch flow (mouse click example)
1. Java `UIManager.update()` iterates UI elements front-to-back
2. `UIElement` checks `isMouseOver()` for hit testing
3. If hit, Java calls Lua method `onMouseDown` on the `table` (KahluaTable)
4. Lua `ISButton:onMouseDown(x, y)` executes
5. On mouse up, Lua `ISButton:onMouseUp(x, y)` calls `self.onclick(self.target, ...)`

### Drawing dispatch
1. Java `UIManager.render()` iterates UI list
2. For each element, Java calls element's `render()` method
3. `UIElement.render()` calls Lua `prerender()`, then renders children, then calls Lua `render()`
4. Lua draw calls (e.g., `drawRect`) call back into Java via `self.javaObject:DrawTextureScaledColor(...)`
5. Java delegates to `SpriteRenderer.instance.renderi(...)` for actual GL rendering

### Coordinate translation in draw calls
All Lua draw coordinates are element-local. Java adds `getAbsoluteX() + xScroll` to translate to screen space:
```java
// UIElement.DrawText
TextManager.instance.DrawString(font,
    x + this.getAbsoluteX() + this.xScroll,
    y + this.getAbsoluteY() + this.yScroll,
    text, r, g, b, alpha);
```

### ISUIWrapper classes
**Path:** `zombie/ui/ISUIWrapper/`

Java wrappers that expose Lua IS* behavior to Java code:
| Wrapper | Purpose |
|-|-|
| `ISUIElementWrapper` | Base wrapper for Lua UIElements |
| `ISPanelWrapper` | Panel wrapper |
| `ISContextMenuWrapper` | Context menu wrapper |
| `ISScrollBarWrapper` | Scrollbar wrapper |
| `ISToolTipWrapper` | Tooltip wrapper |
| `LuaHelpers` | Utility methods for Lua-Java interop |

## 5. Input Handling Pipeline

### Mouse Events
UIManager processes mouse input in `update()`:

1. **Hit testing:** Walk UI list back-to-front (topmost first)
2. **Capture check:** If any element has `capture=true`, it gets all events
3. **Hover detection:** `isMouseOver()` checks point-in-rect on each element and its children
4. **Event dispatch:** Fire appropriate method on the topmost hit element

| Java dispatches | Lua receives |
|-|-|
| Left press | `onMouseDown(x, y)` |
| Left release | `onMouseUp(x, y)` |
| Left release outside | `onMouseUpOutside(x, y)` |
| Left press outside | `onMouseDownOutside(x, y)` |
| Right press | `onRightMouseDown(x, y)` |
| Right release | `onRightMouseUp(x, y)` |
| Mouse move over | `onMouseMove(dx, dy)` |
| Mouse move outside | `onMouseMoveOutside(dx, dy)` |
| Scroll wheel | `onMouseWheel(delta)` |
| Double-click | `onMouseDoubleClick(x, y)` |
| Focus gained | `onFocus(x, y)` |

**Coordinates:** `x, y` in mouse events are element-local (after subtracting absolute position and scroll). `dx, dy` in move events are deltas.

### Mouse Capture
`setCapture(true)` forces all mouse events to this element regardless of position. Used for:
- Drag operations (ISResizeWidget, ISScrollBar)
- Combo box popups (click outside to dismiss)
- Modal blocking

### Keyboard Events
Only elements with `wantKeyEvents=true` receive keyboard input. The focused element gets:
| Lua Method | When |
|-|-|
| `onKeyPress(key)` | Key pressed (Keyboard.KEY_*) |
| `onKeyRelease(key)` | Key released |
| `onKeyRepeat(key)` | Key held down repeat |

### Joypad Events
ISPanelJoypad adds joypad navigation. The focus system uses `joypadData.focus` to track the active element:
| Method | Purpose |
|-|-|
| `onGainJoypadFocus(joypadData)` | Element receives joypad focus |
| `onLoseJoypadFocus(joypadData)` | Element loses joypad focus |
| `onJoypadDown(button, joypadData)` | Button pressed |
| `onJoypadDirUp/Down/Left/Right(joypadData)` | D-pad navigation |

## 6. Font System

### UIFont Enum
**File:** `zombie/ui/UIFont.java`

| Font Name | Typical Use |
|-|-|
| `Small` | Default UI text, buttons, menus |
| `Medium` | Larger UI text, text entry |
| `Large` | Headers, titles |
| `Massive` | Very large display text |
| `NewSmall/NewMedium/NewLarge` | Alternate font family |
| `Code/CodeSmall/CodeMedium/CodeLarge` | Monospace for debug/console |
| `Dialogue` | In-game dialogue |
| `Handwritten` | Handwritten style (notes, journals) |
| `DebugConsole` | Debug console text |
| `MainMenu1/MainMenu2` | Main menu |
| `Cred1/Cred2` | Credits |
| `Intro` | Intro screen |
| `Title` | Title text |
| `SdfRegular/SdfBold/SdfItalic/SdfBoldItalic` | SDF rendered fonts |
| `SdfOldRegular/SdfOldBold/...` | Old-style SDF fonts |
| `AutoNormSmall/Medium/Large` | Auto-normalized sizes |

### TextManager
**File:** `zombie/ui/TextManager.java`
**Access:** `TextManager.instance` (singleton)

| Method | Purpose |
|-|-|
| `DrawString(font, x, y, text, r, g, b, a)` | Render text at position |
| `DrawStringCentre(font, x, y, text, r, g, b, a)` | Center-aligned render |
| `DrawStringRight(font, x, y, text, r, g, b, a)` | Right-aligned render |
| `MeasureStringX(font, text)` | Get pixel width of text |
| `getFontHeight(font)` | Get line height in pixels |
| `getFontFromEnum(font)` | Get AngelCodeFont instance |

**Lua access:**
```lua
local tm = getTextManager()
local width = tm:MeasureStringX(UIFont.Small, "Hello")
local height = tm:getFontHeight(UIFont.Small)
local lineH = tm:getFontFromEnum(UIFont.Small):getLineHeight()
```

### Font Loading
Fonts are AngelCodeFont format (bitmap + .fnt descriptor). Loaded at startup from `media/fonts/`. The `enumToFont[]` array maps UIFont enum values to AngelCodeFont instances. SDF fonts use `SDFShader` for distance-field rendering.

## 7. Rendering Pipeline

### Frame Render Order
1. `UIManager.render()` called from game loop
2. `UITransition.UpdateAll()` - update all fade/transition animations
3. Fire `OnPreUIDraw` Lua event
4. Render fade overlay if `fadeBeforeUi`
5. Per-player fade overlays (split-screen)
6. **Main UI loop:** iterate `UI` list front-to-back:
   - Skip elements following game world or stolen by tutorial
   - Call `element.render()` which recursively renders children
7. Render tooltip on top
8. Render "Game Paused" message if applicable
9. Render fade overlay if not `fadeBeforeUi`
10. Fire `OnPostUIDraw` Lua event

### UIElement.render() (Java side)
For each element, Java performs:
1. Check visibility, maxDrawHeight clipping
2. Call Lua `prerender()` - draw backgrounds, borders
3. Iterate children, recursively render each visible child
4. Call Lua `render()` - draw foreground content

### Draw Methods (Java, called from Lua)
All draw methods on UIElement add `getAbsoluteX() + xScroll` to coordinates before passing to `SpriteRenderer`:

| Java Method | Called by Lua |
|-|-|
| `DrawTextureScaledColor(tex,x,y,w,h,r,g,b,a)` | `drawRect()`, `drawRectBorder()`, `drawRectStatic()` |
| `DrawTexture(tex,x,y,alpha)` | `drawTexture()` |
| `DrawTextureScaled(tex,x,y,w,h,alpha)` | `drawTextureScaled()` |
| `DrawTextureScaledAspect(tex,x,y,w,h,r,g,b,a)` | `drawTextureScaledAspect()` |
| `DrawText(font,str,x,y,r,g,b,a)` | `drawText()`, `drawTextCentre()`, `drawTextRight()` |
| `DrawTextureTiled(tex,x,y,w,h,r,g,b,a)` | `drawTextureTiled()` |
| `DrawPolygon(tex,x1..y4,r,g,b,a)` | `drawPolygon()` |

**Null texture trick:** Passing `nil`/`null` as texture to `DrawTextureScaledColor` draws a solid colored rectangle. This is how `drawRect` works.

### Stencil Clipping
Elements can set rectangular clip regions via stencil buffer:
```lua
self:setStencilRect(x, y, w, h)    -- enable clipping
-- draw calls here are clipped
self:clearStencilRect()              -- disable clipping
```
Java tracks `stencilLevel` for nested stencils. `suspendStencil()`/`resumeStencil()` temporarily disable clipping (used for tooltips and overlays).

## 8. Screen Resolution and Scaling

### Screen dimensions
```lua
local screenW = getCore():getScreenWidth()
local screenH = getCore():getScreenHeight()
```

### Split-screen
PZ supports up to 4 players in split-screen. Each player has a viewport:
```lua
local left = getPlayerScreenLeft(playerNum)
local top = getPlayerScreenTop(playerNum)
local width = getPlayerScreenWidth(playerNum)
local height = getPlayerScreenHeight(playerNum)
```

### Font scaling
`getCore():getOptionFontSizeReal()` returns 1-5 (small to huge). UI elements should use computed font heights rather than hardcoded pixel values:
```lua
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 6
```

### UI spacing constant
PZ uses `UI_BORDER_SPACING = 10` as the standard padding between elements.

### Resize handling
When the game window resizes:
1. Java calls `UIManager.resize()` which repositions core elements
2. Java resize system detects dimension changes on anchored elements
3. Each element's `onResize()` fires (Lua side), syncing `self.width`/`self.height`
4. Elements with `anchorLeft+anchorRight` stretch horizontally
5. Elements with `anchorTop+anchorBottom` stretch vertically

## 9. Z-Order and Layering

### UI list order
`UIManager.UI` is an ordered list. Elements render front-to-back (index 0 first), so later elements appear on top.

### Ordering controls
| Mechanism | Effect |
|-|-|
| `bringToTop()` | Move to end of UI list (renders last, appears on top) |
| `backMost()` | Set `alwaysBack=true`, rendered first |
| `setAlwaysOnTop(true)` | Rendered after all normal elements |
| `addToUIManager()` order | Initial position in list |

### Render order within a single element
1. Parent `prerender()` (background)
2. Children render (in controls list order)
3. Parent `render()` (foreground)

### Focus and overlap
`onFocus()` default calls `bringToTop()` for root elements. Context menus, tooltips, and modals use `setAlwaysOnTop(true)` to stay above everything.

### Input z-order
Input hit-testing walks the UI list back-to-front (topmost first). The first element that contains the mouse point and has `consumeMouseEvents=true` receives the event. Children are tested before parents.

## 10. UITransition

**File:** `zombie/ui/UITransition.java`
**Lua access:** `UITransition.new()`

Used for smooth fade animations on buttons, combo boxes, and tab panels.

| Method | Purpose |
|-|-|
| `setFadeIn(bool)` | Start fade-in (100ms) or fade-out (200ms) |
| `update()` | Advance animation by elapsed time |
| `fraction()` | Current value 0.0-1.0 (respects direction) |
| `reset()` | Reset elapsed to 0 |
| `init(duration, fadeOut)` | Manual init with custom duration |

**Typical usage in Lua:**
```lua
-- In new():
o.fade = UITransition.new()

-- In prerender():
self.fade:setFadeIn(self:isMouseOver())
self.fade:update()
local f = self.fade:fraction()  -- 0.0 (not hovered) to 1.0 (hovered)
-- Interpolate colors using f
```

**Global update:** `UITransition.UpdateAll()` is called once per frame by `UIManager.render()`. It computes elapsed time delta used by all transitions.

## 11. Key Java UI Classes

### zombie.ui package
| Class | Purpose |
|-|-|
| `UIElement` | Base class, rendering, coordinates, children |
| `UIManager` | Static singleton, manages UI list, render/update loop |
| `UIFont` | Enum of all available fonts |
| `UITransition` | Smooth animation interpolation |
| `TextManager` | Font rendering and measurement |
| `TextBox` | Legacy Java text input |
| `UITextBox2` | Java backing for ISTextEntryBox |
| `ObjectTooltip` | Item/object tooltip rendering |
| `RadialMenu` | Java backing for ISRadialMenu (pie menu geometry) |
| `ActionProgressBar` | Per-player action progress display |
| `Clock` | Game time clock display |
| `SpeedControls` | Game speed buttons |
| `MoodlesUI` | Player moodle icons |
| `ModalDialog` | Java-side modal (rarely used, prefer ISModalDialog) |
| `ScrollBar` | Java-side scrollbar (ISScrollBar uses UIElement) |
| `UIDebugConsole` | Debug console window |
| `ScreenFader` | Screen fade transitions |
| `UIEventHandler` | Interface: DoubleClick, ModalClick, Selected |
| `UIElementInterface` | Interface implemented by UIElement |
| `UINineGrid` | 9-slice texture rendering |
| `UI3DModel` | 3D model rendering in UI |

### zombie.ui.ISUIWrapper package
| Class | Purpose |
|-|-|
| `ISUIElementWrapper` | Wraps Lua ISUIElement for Java consumption |
| `ISPanelWrapper` | Wraps Lua ISPanel |
| `ISContextMenuWrapper` | Wraps Lua ISContextMenu |
| `ISScrollBarWrapper` | Wraps Lua ISScrollBar |
| `ISToolTipWrapper` | Wraps Lua ISToolTip |
| `LuaHelpers` | Static utility methods for Lua-Java bridge |

### Related packages
| Package | Key Classes |
|-|-|
| `zombie.core.textures` | `Texture`, `TextureFBO` - texture loading and FBO |
| `zombie.core.SpriteRenderer` | Low-level OpenGL quad rendering |
| `zombie.core.fonts` | `AngelCodeFont` - bitmap font renderer |
| `zombie.input` | `Mouse`, `GameKeyboard` - raw input |
| `zombie.IndieGL` | OpenGL wrapper (blend, stencil, depth) |
| `zombie.Lua.LuaEventManager` | Event dispatch to Lua |
