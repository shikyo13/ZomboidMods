# Lua UI Widgets (IS* Classes) - PZ Data Map
Source: media/lua/client/ISUI/ | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Class Hierarchy | 28-52 |
| 2 | ISUIElement (base) | 53-171 |
| 3 | ISPanel | 172-186 |
| 4 | ISButton | 187-216 |
| 5 | ISTextEntryBox | 217-245 |
| 6 | ISTextBox | 246-267 |
| 7 | ISScrollBar | 268-282 |
| 8 | ISScrollingListBox | 283-317 |
| 9 | ISRichTextPanel | 318-344 |
| 10 | ISTabPanel | 345-370 |
| 11 | ISCollapsableWindow | 371-395 |
| 12 | ISWindow | 396-412 |
| 13 | ISContextMenu | 413-459 |
| 14 | ISRadialMenu | 460-479 |
| 15 | ISModalDialog | 480-496 |
| 16 | ISModalRichText | 497-512 |
| 17 | ISComboBox | 513-541 |
| 18 | ISTickBox | 542-562 |
| 19 | ISProgressBar | 563-576 |
| 20 | Widget Creation Patterns | 577-621 |

## 1. Class Hierarchy

```
ISBaseObject
  ISUIElement                      -- base for all UI
    ISPanel                        -- rectangular panel with background
      ISButton                     -- clickable button with text/image
      ISRichTextPanel              -- formatted text display (markup)
      ISTabPanel                   -- tabbed container for views
      ISCollapsableWindow          -- draggable window with title bar
      ISContextMenu                -- right-click context menu
      ISTickBox                    -- checkbox list
      ISComboBox                   -- dropdown select box
    ISWindow                       -- older window base (titlebar + resize)
    ISProgressBar                  -- fill bar with text overlay
    ISScrollBar                    -- scrollbar (vertical/horizontal)
    ISPanelJoypad                  -- ISPanel with joypad support
      ISScrollingListBox           -- scrollable item list
      ISTextEntryBox               -- single/multi-line text input
      ISTextBox                    -- text input dialog (OK/Cancel)
      ISModalDialog                -- yes/no or OK dialog
      ISModalRichText              -- rich text dialog with buttons
      ISRadialMenu                 -- circular radial selector
```

## 2. ISUIElement (Base Class)

**Derives from:** ISBaseObject
**Constructor:** `ISUIElement:new(x, y, width, height)`
**File:** ISUIElement.lua

Default fields set by `new`:
- `x, y, width, height` - position and size
- `anchorLeft=true, anchorRight=false, anchorTop=true, anchorBottom=false`
- `children={}` (after initialise)
- `javaObject` - Java UIElement bridge (created on `instantiate()`)

### Lifecycle Methods
| Method | Purpose |
|-|-|
| `initialise()` | Set up children table, assign unique ID |
| `instantiate()` | Create Java `UIElement`, set anchors, call `createChildren()` |
| `createChildren()` | Override to add child widgets after instantiation |
| `addToUIManager()` | Register with UIManager for rendering (top-level only) |
| `removeFromUIManager()` | Unregister from UIManager |

### Position and Size
| Method | Signature |
|-|-|
| `setX(x)` | Clamp to screen if keepOnScreen |
| `setY(y)` | Clamp to screen if keepOnScreen |
| `setWidth(w)` | Update width, clamp x |
| `setHeight(h)` | Update height, clamp y |
| `getX()` / `getY()` | Read from javaObject |
| `getWidth()` / `getHeight()` | Read from javaObject |
| `getAbsoluteX()` / `getAbsoluteY()` | Screen-space position |
| `getRight()` / `getBottom()` | x+width / y+height |
| `getCentreX()` / `getCentreY()` | width/2, height/2 |
| `setAnchorsTBLR(t,b,l,r)` | Set all anchors at once |
| `onResize()` | Called on parent resize, syncs lua fields from java |
| `recalcSize()` | Force resize recalculation |

### Visibility and State
| Method | Signature |
|-|-|
| `setVisible(bVisible)` | Show/hide element |
| `getIsVisible()` / `isVisible()` | Check visibility |
| `isReallyVisible()` | True only if self AND all parents visible |
| `setEnabled(en)` / `isEnabled()` | Enable/disable interaction |
| `setAlwaysOnTop(b)` | Render above siblings |
| `bringToTop()` | Move to front of z-order |
| `backMost()` | Move to back of z-order |
| `setKeepOnScreen` | Prevent dragging off screen edges |

### Child Management
| Method | Signature |
|-|-|
| `addChild(element)` | Add child, set parent reference |
| `removeChild(element)` | Remove child |
| `clearChildren()` | Remove all children |
| `getChildren()` | Return children table |
| `getParent()` | Return parent element |
| `isDescendant(ui)` | Check if ui is nested inside self |

### Drawing Primitives (call inside render/prerender)
| Method | Signature |
|-|-|
| `drawRect(x,y,w,h, a,r,g,b)` | Filled rectangle |
| `drawRectBorder(x,y,w,h, a,r,g,b)` | Rectangle outline |
| `drawRectStatic(x,y,w,h, a,r,g,b)` | Filled rect, ignores scroll |
| `drawRectBorderStatic(x,y,w,h, a,r,g,b)` | Outline, ignores scroll |
| `drawText(str,x,y, r,g,b,a, font)` | Left-aligned text |
| `drawTextCentre(str,x,y, r,g,b,a, font)` | Center-aligned text |
| `drawTextRight(str,x,y, r,g,b,a, font)` | Right-aligned text |
| `drawTexture(tex,x,y, a,r,g,b)` | Draw texture at position |
| `drawTextureScaled(tex,x,y,w,h, a,r,g,b)` | Draw texture scaled to w*h |
| `drawTextureScaledAspect(tex,x,y,w,h, a,r,g,b)` | Scale preserving aspect ratio |
| `drawTextureTiled(tex,x,y,w,h, r,g,b,a)` | Tile texture across area |
| `drawLine2(x,y,x2,y2, a,r,g,b)` | Draw line between two points |
| `drawPolygon(tex,x1,y1,...x4,y4, r,g,b,a)` | Draw 4-point polygon |
| `drawProgressBar(x,y,w,h, fraction, fgColor)` | Simple inline progress bar |
| `drawItemIcon(item,x,y,a,w,h)` | Render InventoryItem icon |

### Overridable Event Handlers
| Method | When Called |
|-|-|
| `prerender()` | Before children render (draw backgrounds here) |
| `render()` | After children render (draw foreground here) |
| `update()` | Each tick (logic, animation) |
| `onMouseDown(x,y)` | Left button pressed |
| `onMouseUp(x,y)` | Left button released |
| `onMouseMove(dx,dy)` | Mouse moved while over element |
| `onMouseMoveOutside(dx,dy)` | Mouse moved while outside |
| `onMouseUpOutside(x,y)` | Left released outside |
| `onMouseDownOutside(x,y)` | Left pressed outside |
| `onMouseWheel(del)` | Scroll wheel (+1/-1), return true to consume |
| `onRightMouseDown(x,y)` | Right button pressed |
| `onRightMouseUp(x,y)` | Right button released |
| `onFocus(x,y)` | Element gains focus (bringToTop by default) |

### Scroll Support
| Method | Purpose |
|-|-|
| `addScrollBars(addHorizontal)` | Attach ISScrollBar children |
| `setScrollHeight(h)` | Set virtual content height |
| `getScrollHeight()` | Get virtual content height |
| `setYScroll(y)` / `getYScroll()` | Vertical scroll offset |
| `setXScroll(x)` / `getXScroll()` | Horizontal scroll offset |
| `getScrollAreaHeight()` | Visible height (minus scrollbar) |
| `isVScrollBarVisible()` | True if content exceeds viewport |
| `setScrollChildren(b)` | Children scroll with parent |

### Utility
| Method | Purpose |
|-|-|
| `wrapInCollapsableWindow(title, resizable)` | Wrap self in ISCollapsableWindow |
| `centerOnScreen(playerNum)` | Center on player's screen area |
| `shrinkWrap(padR, padB)` | Resize to fit children bounds |
| `stayOnSplitScreen(playerNum)` | Clamp to player's split-screen area |
| `setCapture(b)` | Capture all mouse events |
| `setStencilRect(x,y,w,h)` | Clip rendering to rectangle |
| `clearStencilRect()` | Remove clip rectangle |
| `setRenderThisPlayerOnly(num)` | Only render for specific player |

## 3. ISPanel

**Derives from:** ISUIElement
**Constructor:** `ISPanel:new(x, y, width, height)`
**File:** ISPanel.lua

Default fields: `background=true`, `backgroundColor={r=0,g=0,b=0,a=0.5}`, `borderColor={r=0.4,g=0.4,b=0.4,a=1}`, `moveWithMouse=false`

| Method | Purpose |
|-|-|
| `noBackground()` | Disable background drawing |
| `close()` | `setVisible(false)` |
| `prerender()` | Draws background rect + border if `self.background` |
| `onMouseDown/Up/Move` | Drag support when `moveWithMouse=true` |

## 4. ISButton

**Derives from:** ISPanel
**Constructor:** `ISButton:new(x, y, width, height, title, target, onclick, arg1..arg4)`
**File:** ISButton.lua

Default fields: `title`, `target`, `onclick`, `enable=true`, `displayBackground=true`, `font=UIFont.Small`, `textColor={r=1,g=1,b=1,a=1}`, `fade=UITransition.new()`

| Method | Signature |
|-|-|
| `setTitle(title)` | Change button label |
| `setImage(texture)` | Set icon texture |
| `setFont(font)` | Change text font |
| `forceImageSize(w,h)` | Override icon dimensions |
| `setOverlayText(text)` | Small overlay text (bottom-right) |
| `setEnable(b)` | Enable/disable with color change |
| `enableAcceptColor()` | Green tint (confirm action) |
| `enableCancelColor()` | Red tint (cancel action) |
| `setDisplayBackground(b)` | Show/hide button background |
| `setRepeatWhilePressed(func)` | Call func repeatedly while held |
| `setOnMouseOverFunction(fn)` | Callback on hover |
| `setOnMouseOutFunction(fn)` | Callback on mouse exit |
| `setBackgroundRGBA(r,g,b,a)` | Set normal background color |
| `setBackgroundColorMouseOverRGBA(r,g,b,a)` | Set hover color |
| `setBorderRGBA(r,g,b,a)` | Set border color |
| `forceClick()` | Programmatically trigger click |
| `setJoypadButton(texture)` | Set joypad button icon |

**Click flow:** `onMouseDown` sets `pressed=true`, `onMouseUp` calls `onclick(target, self, arg1..arg4)` if enabled.

## 5. ISTextEntryBox

**Derives from:** ISPanelJoypad
**Constructor:** `ISTextEntryBox:new(text, x, y, width, height)`
**File:** ISTextEntryBox.lua
**Java backing:** `UITextBox2`

| Method | Purpose |
|-|-|
| `getText()` / `setText(str)` | Get/set text content |
| `getInternalText()` | Raw text without display formatting |
| `setFont(font)` | Change font |
| `setEditable(b)` / `isEditable()` | Enable/disable editing |
| `setSelectable(b)` | Enable text selection |
| `setOnlyNumbers(b)` | Restrict to numeric input |
| `setOnlyText(b)` | Restrict to text input |
| `setMultipleLine(b)` | Enable multi-line mode |
| `setMaxLines(n)` | Cap line count |
| `setMaxTextLength(n)` | Cap character count |
| `setMasked(b)` | Password-style dots |
| `setPlaceholderText(str)` | Greyed hint text |
| `setClearButton(b)` | Show X button to clear |
| `setForceUpperCase(b)` | Force uppercase input |
| `focus()` / `unfocus()` | Focus control |
| `isFocused()` | Check focus state |
| `getCursorPos()` / `setCursorPos(i)` | Cursor position |
| `onTextChange()` | Override - fires on text change |
| `onCommandEntered()` | Override - fires on Enter key |

## 6. ISTextBox

**Derives from:** ISPanelJoypad
**Constructor:** `ISTextBox:new(x, y, width, height, text, defaultEntryText, target, onclick, player, param1..4)`
**File:** ISTextBox.lua

A dialog with a text entry field, OK and Cancel buttons. Used for rename dialogs, etc.

| Method | Purpose |
|-|-|
| `setOnlyNumbers(b)` | Numeric-only input |
| `setMultipleLine(b)` | Multi-line entry |
| `setNumberOfLines(n)` | Visible line count |
| `setMaxLines(n)` | Max lines allowed |
| `setValidateFunction(target,func,a1,a2)` | Validation callback |
| `enableColorPicker()` | Show color picker button |
| `showErrorMessage(show, msg)` | Display error text |
| `destroy()` | Remove from UIManager |

**Fields:** `entry` (ISTextEntryBox), `yes` (ISButton), `no` (ISButton), `noEmpty`, `maxChars`.
**Callback:** `onclick(target, button, param1..4)` where `button.internal` is "OK" or "CANCEL".

## 7. ISScrollBar

**Derives from:** ISUIElement
**Constructor:** `ISScrollBar:new(parent, vertical)`
**File:** ISScrollBar.lua

Automatically created by `addScrollBars()`. Rarely interacted with directly.

| Method | Purpose |
|-|-|
| `refresh()` | Clamp scroll to valid range |
| `hitTest(x,y)` | Returns "thumb", "arrowUp", "arrowDown", "trackUp", "trackDown" |
| `onClickArrowUp/Down()` | Scroll by one step |
| `isPointOverThumb(x,y)` | Check if mouse is over thumb |

## 8. ISScrollingListBox

**Derives from:** ISPanelJoypad
**Constructor:** `ISScrollingListBox:new(x, y, width, height)`
**File:** ISScrollingListBox.lua

Default fields: `items={}`, `selected=1`, `itemheight=fontHgt+4`, `count=0`, `font=UIFont.Small`, `drawBorder=false`

### Item Management
| Method | Signature |
|-|-|
| `addItem(name, item, tooltip)` | Append item, returns item table |
| `insertItem(index, name, item)` | Insert at position |
| `addUniqueItem(name, item, tooltip)` | Add only if name not present |
| `removeItem(itemText)` | Remove by name |
| `removeItemByIndex(index)` | Remove by position |
| `removeFirst()` | Remove first item |
| `clear()` | Remove all items |
| `contains(itemText)` | Check if name exists |
| `size()` | Item count |
| `sort(comparator)` | Sort items (default: alphabetical) |

### Selection and Display
| Method | Purpose |
|-|-|
| `setOnMouseDownFunction(target, fn)` | Callback on item click |
| `setOnMouseDoubleClick(target, fn)` | Callback on double-click |
| `doDrawItem(y, item, alt)` | Override to customize item rendering |
| `rowAt(x, y)` | Get item index at coordinates |
| `topOfItem(index)` | Get Y offset of item |
| `setTextColorRGBA(r,g,b,a)` | Normal text color |
| `setSelectedTextColorRGBA(r,g,b,a)` | Selected item text color |

**Item table fields:** `{text, item, tooltip, itemindex, height}`

## 9. ISRichTextPanel

**Derives from:** ISPanel
**Constructor:** `ISRichTextPanel:new(x, y, width, height)`
**File:** ISRichTextPanel.lua

Displays formatted text using markup commands in angle brackets.

| Method | Purpose |
|-|-|
| `setText(text)` | Set markup text content |
| `paginate()` | Parse text and compute layout |

### Markup Commands
| Tag | Effect |
|-|-|
| `<H1>`, `<H2>`, `<TEXT>` | Heading/body style |
| `<LINE>`, `<BR>` | Line break / paragraph break |
| `<CENTRE>`, `<LEFT>`, `<RIGHT>` | Text alignment |
| `<RGB:r,g,b>` | Set text color (0-1 floats) |
| `<PUSHRGB:r,g,b>` / `<POPRGB>` | Push/pop color stack |
| `<RED>`, `<GREEN>`, `<ORANGE>` | Preset colors |
| `<GHC>`, `<BHC>` | Good/bad highlight colors |
| `<SIZE:small/medium/large>` | Font size |
| `<IMAGE:path>` or `<IMAGE:path,w,h>` | Inline image |
| `<IMAGECENTRE:path>` | Centered image |

## 10. ISTabPanel

**Derives from:** ISPanel
**Constructor:** `ISTabPanel:new(x, y, width, height)`
**File:** ISTabPanel.lua

Default fields: `viewList={}`, `tabHeight=fontHgt+6`, `tabPadX=20`, `equalTabWidth=true`, `centerTabs=false`, `allowDraggingTabs=false`, `allowTornOffTabs=false`

| Method | Purpose |
|-|-|
| `addView(name, view)` | Add a panel as a tab |
| `removeView(view)` | Remove tab by view reference |
| `activateView(viewName)` | Switch to named tab |
| `getView(viewName)` | Get view panel by tab name |
| `getActiveView()` | Current view panel |
| `getActiveViewIndex()` | Current tab index |
| `setEqualTabWidth(b)` | All tabs same width vs auto-size |
| `setCenterTabs(b)` | Center tab bar |
| `setTabsTransparency(a)` | Tab bar alpha |
| `setTextTransparency(a)` | Tab text alpha |
| `ensureVisible(index)` | Scroll tab bar to show tab |
| `setOnTabTornOff(target, fn)` | Callback when tab dragged out |
| `getWidthOfAllTabs()` | Total width of tab bar |

**Tab drag:** When `allowDraggingTabs=true`, tabs can be reordered. When `allowTornOffTabs=true`, tabs can be dragged out into ISCollapsableWindow.

## 11. ISCollapsableWindow

**Derives from:** ISPanel
**Constructor:** `ISCollapsableWindow:new(x, y, width, height)`
**File:** ISCollapsableWindow.lua

Default fields: `pin=true`, `isCollapsed=false`, `resizable=true`, `drawFrame=true`, `title=nil`, `titleBarFont=UIFont.Small`

| Method | Purpose |
|-|-|
| `setTitle(title)` / `getTitle()` | Window title text |
| `close()` | Hide window |
| `collapse()` | Minimize to title bar |
| `pin()` | Prevent auto-collapse |
| `setResizable(b)` | Enable/disable resize handles |
| `setInfo(text)` | Set info popup rich text |
| `setDrawFrame(b)` | Show/hide title bar and border |
| `addView(view)` | Add child view below title bar |
| `titleBarHeight()` | Computed title bar height |
| `minTitleBarWidth()` | Min width to fit all buttons + title |
| `RestoreLayout(name, layout)` | Restore saved position/size |
| `SaveLayout(name, layout)` | Save position/size |

**Auto-created children:** `closeButton`, `infoButton`, `pinButton`, `collapseButton`, `resizeWidget`

## 12. ISWindow

**Derives from:** ISUIElement
**Constructor:** `ISWindow:new(title, x, y, width, height)`
**File:** ISWindow.lua

Older, simpler window class with fixed margins. Less commonly used than ISCollapsableWindow.

| Method | Purpose |
|-|-|
| `getClientLeft/Right/Top/Bottom()` | Content area bounds |
| `getClientWidth()` / `getClientHeight()` | Content area size |
| `addToolbar(toolbar, height)` | Add toolbar below title |
| `removeToolbar(toolbar)` | Remove toolbar |

**Constants:** `TitleBarHeight=19`, `SideMargin=12`, `BottomMargin=12`

## 13. ISContextMenu

**Derives from:** ISPanel
**File:** ISContextMenu.lua

The right-click context menu system. Uses a pooled instance model per player.

### Static Creation
| Method | Purpose |
|-|-|
| `ISContextMenu.get(player, x, y)` | Get/create root menu for player at position |
| `ISContextMenu:getNew(parentContext)` | Create sub-menu from parent |
| `ISContextMenu:getSubMenu(num)` | Get sub-menu by option number |

### Adding Options
| Method | Signature |
|-|-|
| `addOption(name, target, onSelect, p1..p10)` | Add menu item, returns option table |
| `addOptionOnTop(name, target, ...)` | Insert at top |
| `insertOptionAfter(prevName, name, ...)` | Insert after named option |
| `insertOptionBefore(nextName, name, ...)` | Insert before named option |
| `addActionsOption(text, getActionsFn, ...)` | Option that queues timed actions |
| `addColorBoxOption(name, ...)` | Option with color swatch icon |

### Option Table Fields
```lua
option.name              -- display text
option.target            -- callback self
option.onSelect          -- callback function(target, p1..p10)
option.subOption         -- sub-menu number (set via option.subOption = submenu.subOptionNums)
option.notAvailable      -- grey out (shown in red)
option.isDisabled        -- grey out (dimmed)
option.toolTip           -- ISToolTip to show on hover
option.iconTexture       -- icon texture
option.color             -- icon color {r,g,b}
option.onHighlight       -- function(option, menu, isHighlighted, ...)
```

### Sub-menu Pattern
```lua
local context = ISContextMenu.get(player, x, y)
local opt = context:addOption("Parent")
local sub = ISContextMenu:getNew(context)
context:addSubMenu(opt, sub)
sub:addOption("Child", target, callback)
```

## 14. ISRadialMenu

**Derives from:** ISPanelJoypad
**Constructor:** `ISRadialMenu:new(x, y, innerRadius, outerRadius, playerNum)`
**File:** ISRadialMenu.lua
**Java backing:** `RadialMenu`

| Method | Purpose |
|-|-|
| `addSlice(text, texture, command, arg1..6)` | Add pie slice |
| `setSliceText(index, text)` | Change slice label |
| `setSliceTexture(index, tex)` | Change slice icon |
| `clear()` | Remove all slices |
| `isEmpty()` | Check if menu has no slices |
| `center()` | Center on player screen |
| `undisplay()` | Remove from UI |
| `setHideWhenButtonReleased(button)` | Auto-hide on joypad release |

**Command format:** `{function, arg1, arg2, ...}` stored per slice.

## 15. ISModalDialog

**Derives from:** ISPanelJoypad
**Constructor:** `ISModalDialog:new(x, y, width, height, text, yesno, target, onclick, player, param1, param2)`
**File:** ISModalDialog.lua

Simple modal with text and OK or Yes/No buttons. Auto-sizes to fit text.

| Method | Purpose |
|-|-|
| `destroy()` | Remove and restore game state |
| `onClick(button)` | Internal - calls `onclick(target, button, p1, p2)` |
| `CalcSize(width, height, text)` | Static - compute needed dimensions |

**Usage:** `yesno=true` for Yes/No, `false` for OK only.
**Callback:** `button.internal` is "YES", "NO", or "OK".

## 16. ISModalRichText

**Derives from:** ISPanelJoypad
**Constructor:** `ISModalRichText:new(x, y, width, height, text, yesno, target, onclick, player, param1, param2)`
**File:** ISModalRichText.lua

Like ISModalDialog but the text body is an ISRichTextPanel with markup support.

| Method | Purpose |
|-|-|
| `destroy()` | Remove and restore state |
| `setHeightToContents()` | Auto-size to fit rich text content |
| `updateButtons()` | Reposition buttons after height change |

**Fields:** `chatText` (ISRichTextPanel), `destroyOnClick=true`, `alwaysOnTop`.

## 17. ISComboBox

**Derives from:** ISPanel
**Constructor:** `ISComboBox:new(x, y, width, height, target, onChange, arg1, arg2)`
**File:** ISComboBox.lua
**Related:** ISComboBoxPopup (ISScrollingListBox), ISComboBoxEditor (ISTextEntryBox)

| Method | Purpose |
|-|-|
| `addOption(option)` | Add text option (string) |
| `addOptionWithData(text, data)` | Add option with associated data |
| `clear()` | Remove all options |
| `getOptionCount()` | Number of options |
| `getOptionText(index)` | Text of option at index |
| `getOptionData(index)` | Data attached to option |
| `getSelectedText()` | Currently selected text |
| `getSelected()` / `setSelected(i)` | Selected index |
| `select(optionText)` | Select by text match |
| `selectData(data)` | Select by data match |
| `contains(text)` | Check if option exists |
| `setWidthToOptions(minWidth)` | Auto-size to widest option |
| `setEnabled(b)` / `isEnabled()` | Enable/disable |
| `setEditable(b)` | Allow typing to filter |
| `setToolTipMap(map)` | Per-option tooltips |
| `showPopup()` / `hidePopup()` | Manually toggle dropdown |

**Callback:** `onChange(target, comboBox, arg1, arg2)` fires on selection change.
**Shared popup:** All combo boxes share a single popup instance (`ISComboBox.SharedPopup`).

## 18. ISTickBox

**Derives from:** ISPanel
**Constructor:** `ISTickBox:new(x, y, width, height, name, changeTarget, changeMethod, arg1, arg2)`
**File:** ISTickBox.lua

| Method | Purpose |
|-|-|
| `addOption(name, data, texture)` | Add checkbox option |
| `clearOptions()` | Remove all options |
| `getOptionCount()` | Number of options |
| `getOptionData(index)` | Data for option at index |
| `setSelected(index, b)` | Set checked state |
| `isSelected(index)` | Get checked state |
| `disableOption(name, b)` | Grey out specific option |
| `setFont(font)` | Change text font |
| `setWidthToFit()` | Auto-size width to widest option |

**Fields:** `onlyOnePossibility` (radio-button mode), `choicesColor`, `leftMargin=0`, `boxSize=16`, `textGap=5`.
**Callback:** `changeMethod(target, index, isSelected, arg1, arg2, tickBox)`

## 19. ISProgressBar

**Derives from:** ISUIElement
**Constructor:** `ISProgressBar:new(x, y, width, height, text, font)`
**File:** ISProgressBar.lua

| Method | Purpose |
|-|-|
| `setProgress(f)` | Set fill (0.0-1.0, clamped) |
| `setText(text)` | Centered overlay text |
| `noBackground()` | Hide background |

**Fields:** `progressColor={r=0.2,g=1,b=0.2,a=1}`, `textColor`, `isVertical=false`, `doRenderTexture=false`, `paddingTop/Bottom/Left/Right=2`.

## 20. Widget Creation Patterns

### Standard widget lifecycle
```lua
local panel = ISPanel:new(x, y, w, h)
panel:initialise()
panel:instantiate()
panel:addToUIManager()      -- only for top-level
panel:setVisible(true)
```

### Adding children
```lua
local btn = ISButton:new(10, 10, 100, 25, "Click", self, MyClass.onBtnClick)
btn:initialise()
btn:instantiate()
parent:addChild(btn)
```

### Wrap in window
```lua
local panel = ISPanel:new(100, 100, 400, 300)
panel:initialise()
local window = panel:wrapInCollapsableWindow("My Window")
window:addToUIManager()
window:setVisible(true)
```

### Context menu from event
```lua
Events.OnFillWorldObjectContextMenu.Add(function(player, context, ...)
    context:addOption("My Option", nil, function() print("clicked") end)
    local sub = ISContextMenu:getNew(context)
    local opt = context:addOption("Submenu")
    context:addSubMenu(opt, sub)
    sub:addOption("Sub Item", nil, callback)
end)
```

### Modal dialog
```lua
local modal = ISModalDialog:new(0, 0, 250, 100, "Are you sure?", true, self, MyClass.onConfirm)
modal:initialise()
modal:addToUIManager()
```
