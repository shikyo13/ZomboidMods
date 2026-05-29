# Timed Actions - PZ Data Map
Source: media/lua/shared/TimedActions, media/lua/client/TimedActions | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | ISBaseTimedAction fields | 14-30 |
| 2 | Lifecycle methods | 31-76 |
| 3 | Animation integration | 77-96 |
| 4 | ISTimedActionQueue | 97-135 |
| 5 | Built-in timed actions | 136-177 |
| 6 | Custom action pattern | 178-249 |

## 1. ISBaseTimedAction Fields

Defined in `media/lua/shared/TimedActions/ISBaseTimedAction.lua`. Derives from `ISBaseObject`.

| Field | Default | Purpose |
|-|-|-|
| character | (required) | IsoGameCharacter performing the action |
| maxTime | -1 | Duration in ticks (-1 = instant) |
| stopOnWalk | true | Cancel when character walks |
| stopOnRun | true | Cancel when character runs |
| stopOnAim | true | Cancel when character aims |
| caloriesModifier | 1 | Multiplier for calorie burn |
| ignoreHandsWounds | nil | Skip hand wound time penalty |
| action | nil | Java LuaTimedActionNew reference (set by :create) |
| retriggerLastAction | nil | Re-queue interrupted action after completion |
| ignoreAction | nil | If true, ISTimedActionQueue.add() silently drops it |

## 2. Lifecycle Methods

Actions follow this lifecycle: `new()` -> queue -> `begin()` -> `start()` -> `update()` (per tick) -> `perform()` or `stop()`

### begin()
Called by the queue when this action reaches the front. Calls `create()` then `character:StartAction(action)`. Do NOT override.

### create()
Calls `adjustMaxTime()` then creates `LuaTimedActionNew`. Do NOT override.

### isValidStart() -> boolean
Checked before `begin()` when action is dequeued after a previous action completes. Return `false` to cancel the entire queue. Default: `true`.

### waitToStart() -> boolean
Called each tick before the action truly starts. Return `true` to delay. Useful for facing the target square. Default: `false`.

### start()
Called once when the action begins executing. Set up animations, sounds, and hand models here. Default: empty.

### update()
Called every tick while the action runs. Use `self:getJobDelta()` (0.0-1.0) for progress. Default: empty.

### isValid() -> boolean
Called every tick. Return `false` to trigger `stop()`. **Must override** - default is empty (returns nil = falsy, will stop immediately).

### perform()
Called when action completes (jobDelta reaches 1.0). Apply results here. **Must call** `ISBaseTimedAction.perform(self)` at the end - this dequeues and triggers the next action.

### stop()
Called when action is interrupted (isValid fails, player walks, etc). Clean up here. **Must call** `ISBaseTimedAction.stop(self)` at the end - this resets the entire queue.

### forceComplete()
Immediately completes the Java action. Calls `perform()`.

### forceStop()
Immediately stops the Java action. Calls `stop()`.

### forceCancel()
Called when action is removed from queue without ever starting. Clean up resources reserved in `new()`.

### getDuration() -> number
Returns `maxTime`.

### adjustMaxTime(maxTime) -> number
Applies penalties from: unhappiness (up to +100%), drunkenness (up to +100%), hand/arm wounds (pain-based), body temperature modifier. Only applies when `maxTime > 1`.

## 3. Animation Integration

### setActionAnim(animName, displayItemModels)
Set the animation played during the action. Called in `start()`. Common anims: `CharacterActionAnims.Build`, `CharacterActionAnims.BuildLow`, `"BlowTorch"`, `"BlowTorchFloor"`, `"Loot"`.

### setOverrideHandModels(primaryHand, secondaryHand, resetModel)
Override what items display in character hands. Pass Java item objects. `resetModel` defaults to `true`.

### setOverrideHandModelsString(primaryHand, secondaryHand, resetModel)
Same as above but accepts sprite name strings.

### setAnimVariable(key, value)
Set animation state variables. Example: `action:setAnimVariable("LootPosition", "High")`.

### overrideWeaponType() / restoreWeaponType()
Temporarily override/restore the weapon type for animation purposes.

### getDeltaModifiers(deltas)
Override to modify action speed dynamically. Called by the Java side.

## 4. ISTimedActionQueue

Defined in `media/lua/client/TimedActions/ISTimedActionQueue.lua`. One queue per character, stored in `ISTimedActionQueue.queues`.

### Static API

| Function | Purpose |
|-|-|
| ISTimedActionQueue.add(action) | Add action to character's queue. Starts immediately if queue empty. |
| ISTimedActionQueue.addAfter(prevAction, action) | Insert action right after prevAction in queue. Returns queue, action or nil. |
| ISTimedActionQueue.clear(character) | Cancel all queued actions, call StopAllActionQueue. |
| ISTimedActionQueue.hasAction(action) | Check if specific action instance is in queue. |
| ISTimedActionQueue.hasActionType(character, type) | Check if any action of given Type string is queued. |
| ISTimedActionQueue.queueActions(character, func, ...) | Wrap a function that adds multiple actions into a single ISQueueActionsAction. |
| ISTimedActionQueue.addGetUpAndThen(character, action) | Queue a get-up-from-ground action, then the given action. |
| ISTimedActionQueue.isPlayerDoingAction(playerObj) | Check if player has active actions or is in a climb/window state. |
| ISTimedActionQueue.getTimedActionQueue(character) | Get or create the queue for a character. |

### Queue Behavior
- Actions execute sequentially (FIFO).
- When an action calls `perform()`, `onCompleted()` dequeues it and calls `begin()` on the next action.
- If `isValidStart()` fails for the next action, the entire queue resets.
- `stop()` on any action resets the entire queue.
- The `_isAddingActions` / `_numAddedActions` mechanism lets a `perform()` method queue follow-up actions that insert right after the current action.
- `onTick` monitors all queues for stalled actions and resets game speed when all actions complete.

### Action Chaining from perform()
```lua
function MyAction:perform()
    self:beginAddingActions()
    ISTimedActionQueue.add(ISAnotherAction:new(self.character, ...))
    self:endAddingActions()
    ISBaseTimedAction.perform(self)
end
```

### Retriggering
Some actions set `retriggerLastAction = true` (e.g., eating interrupted by opening a door). The queue saves the interrupted action via `character:setTimedActionToRetrigger()` and re-queues it after the interrupting action completes, resuming from the saved jobDelta.

## 5. Built-in Timed Actions

All in `media/lua/client/TimedActions/`:

| File | Purpose |
|-|-|
| ISInventoryTransferAction | Transfer items between inventories |
| ISGrabItemAction | Pick up world items |
| ISClimbThroughWindow | Climb through windows |
| ISClimbOverFence | Climb over fences |
| ISClimbSheetRopeAction | Climb up/down sheet ropes |
| ISOpenContainerTimedAction | Open containers with lids/locks |
| ISDetachItemHotbar | Detach items from hotbar |
| ISMedicalCheckAction | Medical examination |
| ISExtendedPlacementAction | Place items in world (3D placement) |
| ISGeneratorInfoAction | Interact with generators |
| ISCampingInfoAction | Camping/tent info |
| ISBBQInfoAction | BBQ grill info |
| ISOvenUITimedAction | Oven interaction |
| ISOpenButcherHookUI | Butchering hook interaction |
| ISReadWorldMap | Read map items |
| ISDigStairsAction | Dig stairs |
| WalkToTimedAction | Walk to location (queued movement) |
| WalkToTimedActionF | Walk to location (facing variant) |
| ISQueueActionsAction | Wrapper for deferred action batches |
| ISContextualActions | Context-dependent action dispatch |

**Animal subdirectory** (`TimedActions/Animal/`):

| File | Purpose |
|-|-|
| ISInspectAnimalTrackAction | Inspect animal tracks |
| ISGetHutchInfo | Get hutch/coop info |
| ISCheckAnimalInsideTrailer | Check for animals in trailers |
| ISOpenAnimalInfo | Open animal info panel |

**Build action** (`BuildingObjects/TimedActions/`):

| File | Purpose |
|-|-|
| ISBuildAction | Timed action for all building/construction |

## 6. Custom Timed Action Pattern

```lua
require "TimedActions/ISBaseTimedAction"

ISMyAction = ISBaseTimedAction:derive("ISMyAction")

function ISMyAction:isValid()
    -- Return false to cancel. Called every tick.
    return self.character:getInventory():contains(self.item)
end

function ISMyAction:waitToStart()
    -- Optional: delay start until character faces target
    self.character:faceThisObject(self.targetObj)
    return self.character:shouldBeTurning()
end

function ISMyAction:start()
    -- Set animation and hand models
    self:setActionAnim(CharacterActionAnims.Build)
    self:setOverrideHandModels(self.item, nil, false)
    -- Play sound
    self.sound = self.character:getEmitter():playSound("MySound")
end

function ISMyAction:update()
    -- Called every tick. getJobDelta() returns 0.0 to 1.0
    -- Optionally update progress display
end

function ISMyAction:stop()
    -- Cleanup on interruption
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
    end
    ISBaseTimedAction.stop(self)  -- REQUIRED: resets queue
end

function ISMyAction:perform()
    -- Apply results
    self.character:getXp():AddXP(Perks.Woodwork, 5)
    -- Cleanup
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
    end
    ISBaseTimedAction.perform(self)  -- REQUIRED: dequeues and triggers next
end

function ISMyAction:new(character, item, targetObj, time)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.targetObj = targetObj
    o.maxTime = time
    -- Optional overrides:
    -- o.stopOnWalk = false
    -- o.stopOnRun = false
    -- o.stopOnAim = false
    -- o.ignoreHandsWounds = true
    return o
end

-- Usage from context menu callback:
-- ISTimedActionQueue.add(ISMyAction:new(playerObj, item, target, 200))
```

### Key rules
- `ISBaseTimedAction.perform(self)` and `ISBaseTimedAction.stop(self)` **must** be called at the end of their respective overrides.
- `isValid()` **must** be overridden to return a truthy value, otherwise the action stops immediately.
- `maxTime = -1` means instant (no animation ticks). Set to positive value for duration.
- Use `self:setTime(newTime)` to change duration before `begin()`.
- Use `self:setCurrentTime(time)` to jump to a specific point during execution.
