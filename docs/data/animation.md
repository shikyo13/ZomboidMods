# Animation System - PZ Data Map
Source: projectzomboid.jar (decompiled) | media/lua | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture Overview | 25-50 |
| 2 | AnimationSet and AnimState | 52-84 |
| 3 | AnimNode - Animation Definitions | 86-125 |
| 4 | AnimCondition - State Selection | 127-168 |
| 5 | AnimTransition - Blending Between Nodes | 170-194 |
| 6 | AnimLayer - Runtime Layer Management | 196-233 |
| 7 | AdvancedAnimator - Top-Level Controller | 235-263 |
| 8 | Animation Variables | 265-306 |
| 9 | AnimEvent System | 308-327 |
| 10 | ActionContext and ActionGroup | 329-365 |
| 11 | Timed Action Animations | 367-413 |
| 12 | Combat Animations | 415-451 |
| 13 | Zombie Animation States | 453-483 |
| 14 | Lua API Reference | 485-524 |
| 15 | Modding - Adding/Overriding Animations | 526-576 |

---

## 1. Architecture Overview

The PZ animation system is a hierarchical state machine built on XML-defined data:

```
AnimationSet (e.g., "player", "zombie")
  -> AnimState (e.g., "idle", "movement", "attack")
    -> AnimNode (e.g., "idle_barehand", "idle_rifle") - selected by conditions
      -> AnimTransition - defines blending rules between nodes
      -> AnimEvent - timed callbacks during playback
```

**Key Java packages:**
- `zombie.core.skinnedmodel.advancedanimation` - core state machine (AnimState, AnimNode, AnimLayer, AdvancedAnimator)
- `zombie.core.skinnedmodel.animation` - low-level playback (AnimationPlayer, AnimationTrack, AnimationMultiTrack)
- `zombie.characters.action` - action group system (ActionContext, ActionGroup, ActionState)
- `zombie.ai.states` - AI states that drive animation transitions

**Data flow:**
1. AI State (e.g., `PlayerIdleState`) sets animation variables on the character
2. `ActionContext` evaluates transitions in the loaded `ActionGroup` XML
3. `AdvancedAnimator.setState()` picks the matching `AnimState`
4. `AnimLayer` selects the best `AnimNode` by evaluating `AnimCondition` arrays
5. `AnimationPlayer` handles the actual bone-level playback and blending

---

## 2. AnimationSet and AnimState

**AnimationSet** (`zombie.core.skinnedmodel.advancedanimation.AnimationSet`)

Loaded from `media/AnimSets/<SetName>/` directories. Each subfolder is an AnimState.

| Method | Description |
|-|-|
| `GetAnimationSet(name, reload)` | Static lookup/load by name; cached in `setMap` |
| `GetState(name)` | Get AnimState by name (case-insensitive); warns if missing |
| `Load(name)` | Scans `media/AnimSets/<name>/` for state subdirectories |
| `containsState(name)` | Check if a named state exists |

Default scaling loaded from `media/AnimSets/Defaults.xml`:
- `motionScale` (default 0.76) - scales root motion translation
- `rotationScale` (default 0.76) - scales root motion rotation

**AnimState** (`zombie.core.skinnedmodel.advancedanimation.AnimState`)

A named state containing a prioritized list of AnimNodes.

| Field | Type | Description |
|-|-|-|
| `name` | String | State name (folder name) |
| `nodes` | List\<AnimNode\> | Concrete nodes, sorted by condition priority |
| `abstractNodes` | List\<AnimNode\> | Nodes with no animation (provide events/config only) |
| `defaultIndex` | int | Fallback node index |

**Node selection:** `getAnimNodes(varSource, outList)` iterates nodes in priority order, checking `AnimCondition` arrays. The first node (or set of equal-priority nodes) whose conditions all pass is selected.

Parsed via `AnimState.Parse(name, statePath)` which scans for `*.xml` node files in the state directory.

---

## 3. AnimNode - Animation Definitions

**AnimNode** (`zombie.core.skinnedmodel.advancedanimation.AnimNode`) - XML root element `<animNode>`

Each node is a single `.xml` file within an AnimState directory.

| XML Element | Java Field | Type | Default | Description |
|-|-|-|-|-|
| `m_Name` | `name` | String | "" | Node identifier |
| `m_AnimName` | `animName` | String | "" | FBX animation clip name |
| `m_AlternateAnims` | `alternateAnims` | List\<String\> | [] | Random alternates |
| `m_Priority` | `priority` | int | 5 | Playback priority on the track |
| `m_ConditionPriority` | `conditionPriority` | int | 0 | Selection order (higher = checked first) |
| `m_Looped` | `isLooped` | boolean | true | Whether animation loops |
| `m_BlendTime` | `blendTime` | float | 0 | Blend-in duration (seconds) |
| `m_BlendOutTime` | `blendOutTime` | float | -1 | Blend-out duration; falls back to blendTime |
| `m_SpeedScale` | `speedScale` | String | "1.00" | Numeric literal or variable name |
| `m_SpeedScaleVariable` | `speedScaleVariable` | String | null | Variable-driven speed (parsed from speedScale) |
| `m_maxTorsoTwist` | `maxTorsoTwist` | float | 15.0 | Max degrees of torso rotation |
| `m_StopAnimOnExit` | `stopAnimOnExit` | boolean | false | Stop clip when leaving node |
| `m_isRagdoll` | `isRagdoll` | boolean | false | Triggers ragdoll physics |
| `m_chanceToRagdoll` | `chanceToRagdoll` | float | 1.0 | Probability (0-1) of ragdoll |
| `m_DeferredBoneName` | `deferredBoneName` | String | "Translation_Data" | Root motion bone |
| `m_deferredBoneAxis` | `deferredBoneAxis` | BoneAxis | Y | Root motion axis |
| `m_useDeferedRotation` | `useDeferedRotation` | boolean | false | Apply root motion rotation |
| `m_useDeferredMovement` | `useDeferredMovement` | boolean | true | Apply root motion translation |
| `m_SyncTrackingEnabled` | `syncTrackingEnabled` | boolean | true | Enable sync tracking |
| `m_AnimReverse` | `isAnimReverse` | boolean | false | Play animation backwards |
| `m_randomAdvanceFraction` | `randomAdvanceFraction` | float | 0 | Random start offset (0-1) |

**2D blend support:** Nodes can define `m_2DBlends` (directional blending) and `m_2DBlendTri` (triangle-based blend picking) for smooth transitions between directional animations.

**Bone weights:** `m_SubStateBoneWeights` defines per-bone influence for sub-state layering. Defaults:
- `Bip01_Spine1`: 0.5, `Bip01_Neck`: 1.0, `Bip01_BackPack`: 1.0, `Bip01_Prop1`: 1.0, `Bip01_Prop2`: 1.0

**Grapple system:** Nodes can specify `m_MatchingGrappledAnimNode` for paired grapple animations with offset and tween parameters.

**Random animation:** `getRandomAnim()` picks from `animName` + `alternateAnims` with equal probability.

---

## 4. AnimCondition - State Selection

**AnimCondition** (`zombie.core.skinnedmodel.advancedanimation.AnimCondition`)

Conditions are evaluated against animation variables to determine which AnimNode plays.

| Condition Type | Enum | Description |
|-|-|-|
| String equals | `STRING` | Case-insensitive string match |
| String not-equals | `STRNEQ` | Case-insensitive string non-match |
| Boolean | `BOOL` | Boolean equality |
| Float equals | `EQU` | Exact float match |
| Float not-equals | `NEQ` | Float non-match |
| Float less-than | `LESS` | value < threshold |
| Float greater-than | `GTR` | value > threshold |
| Abs less-than | `ABSLESS` | abs(value) < threshold |
| Abs greater-than | `ABSGTR` | abs(value) > threshold |
| Logical OR | `OR` | Short-circuit OR between condition groups |

**XML structure:**
```xml
<m_Conditions>
  <item>
    <m_Name>Weapon</m_Name>
    <m_Type>STRING</m_Type>
    <m_Value>handgun</m_Value>
  </item>
  <item>
    <m_Name>isAiming</m_Name>
    <m_Type>BOOL</m_Type>
    <m_BoolValue>true</m_BoolValue>
  </item>
</m_Conditions>
```

**Evaluation logic** (`AnimCondition.pass()`): Conditions are AND-ed by default. An `OR` condition acts as a separator - if the group before it passed, evaluation stops (success). If it failed, a new AND group begins.

**Special variables in conditions:**
- `$this` / `$source` - replaced with the current node's name
- `$target` - replaced with the target node's name (transitions only)

---

## 5. AnimTransition - Blending Between Nodes

**AnimTransition** (`zombie.core.skinnedmodel.advancedanimation.AnimTransition`)

Defines how to blend from one AnimNode to another.

| XML Element | Field | Type | Default | Description |
|-|-|-|-|-|
| `m_Source` | `source` | String | - | Source node name |
| `m_Target` | `target` | String | - | Target node name (empty = exit transition) |
| `m_AnimName` | `animName` | String | - | Optional transition animation |
| `m_blendInTime` | `blendInTime` | float | INF | Override blend-in time |
| `m_blendOutTime` | `blendOutTime` | float | INF | Override blend-out time |
| `m_speedScale` | `speedScale` | float | INF | Override speed during transition |
| `m_SyncAdjustTime` | `syncAdjustTime` | float | 0 | Sync timing adjustment |
| `m_Conditions` | `conditions` | AnimCondition[] | [] | When to use this transition |
| `m_DeferredBoneName` | `deferredBoneName` | String | - | Override root motion bone |
| `m_useDeferedRotation` | `useDeferedRotation` | boolean | false | Root motion rotation override |
| `m_useDeferredMovement` | `useDeferredMovement` | boolean | true | Root motion translation override |

**Transition lookup:** `AnimNode.findTransitionTo(varSource, toNode)` searches the node's transition list for a matching target name where all conditions pass. If no specific transition exists, default blend times from the node are used.

**Exit transitions:** A transition with an empty `target` field serves as the default exit transition, providing `blendOutTime` for when the node is replaced.

---

## 6. AnimLayer - Runtime Layer Management

**AnimLayer** (`zombie.core.skinnedmodel.advancedanimation.AnimLayer`)

Manages the live playback state of a single animation layer. Pooled objects for memory efficiency.

**Layer hierarchy:**
- Each character has a `rootLayer` plus optional `subLayers` (for upper-body overlays, etc.)
- Sub-layers have a `parentLayer` reference and blend with bone weights from `AnimNode.subStateBoneWeights`

**Key responsibilities:**
- Maintains a list of `LiveAnimNode` instances (active animation tracks)
- Handles `AnimState` transitions via `transitionTo()`
- Dispatches animation events to the parent `AdvancedAnimator`
- Manages blend weights between outgoing and incoming animations

**Lifecycle events dispatched:**

| Event | When Fired |
|-|-|
| `ActiveAnimLooped` | Looped animation completes a cycle |
| `ActiveNonLoopedAnimFadeOut` | Non-looped animation begins fading out |
| `ActiveNonLoopedAnimFinished` | Non-looped animation fully complete |
| `ActiveAnimFinishing` | Animation is about to end (both looped/non-looped) |
| `NoAnimConditionsPass` | No AnimNode's conditions matched (sent once) |

**Key methods:**

| Method | Description |
|-|-|
| `getCurrentStateName()` | Name of active AnimState |
| `transitionTo(state)` | Begin transition to new AnimState |
| `isCurrentState(name)` | Check current state by name |
| `setParentLayer(layer)` | Reassign parent (for sub-layer management) |
| `getAnimationTrack()` | Access the underlying AnimationMultiTrack |
| `reset()` | Clear all live nodes and state |

---

## 7. AdvancedAnimator - Top-Level Controller

**AdvancedAnimator** (`zombie.core.skinnedmodel.advancedanimation.AdvancedAnimator`)

Top-level animation controller attached to each `IAnimatable` character.

**Initialization:**
- `systemInit()` registers file watchers on `media/AnimSets` and `media/actiongroups` for hot-reload
- `init(character)` creates the root AnimLayer
- `setAnimSet(aset)` assigns the AnimationSet

**Key methods:**

| Method | Description |
|-|-|
| `setState(stateName)` | Set root state by name |
| `setState(stateName, subStateNames)` | Set root + sub-layer states |
| `getCurrentStateName()` | Get active root state name |
| `containsState(name)` | Check if AnimSet has a state |
| `OnAnimDataChanged(reload)` | Refresh after data changes; resets layers |
| `OnAnimEvent(sender, track, event)` | Propagates events to all registered callbacks |
| `invokeGlobalAnimEvent(event)` | Fire an event without a specific layer source |
| `reset()` | Reset all layers |

**Debug output:** `GetDebug()` returns a formatted string showing current state, variables, weapon type, aim mode, and all animation variable key-value pairs. Useful for the in-game animation debug panel (F6).

**Hot-reload support:** File watchers detect changes to AnimSet XMLs and ActionGroup XMLs, triggering `LoadDefaults()`, `refreshAnimSets()`, and `reloadActionGroups()` - allowing animation iteration without restarting the game.

---

## 8. Animation Variables

Variables drive animation state selection. They are string, bool, float, int, or enum typed.

**Variable types** (`AnimationVariableType`):
`Void`, `String`, `Float`, `Int`, `Boolean`

**Variable slot types:**
| Slot Class | Description |
|-|-|
| `AnimationVariableSlotBool` | Static boolean value |
| `AnimationVariableSlotFloat` | Static float value |
| `AnimationVariableSlotString` | Static string value |
| `AnimationVariableSlotEnum` | Enum-backed string |
| `AnimationVariableSlotCallbackBool` | Dynamic boolean from callback |
| `AnimationVariableSlotCallbackFloat` | Dynamic float from callback |
| `AnimationVariableSlotCallbackString` | Dynamic string from callback |
| `AnimationVariableSlotCallbackEnum` | Dynamic enum from callback |

**Common animation variables used by PZ:**

| Variable | Type | Description |
|-|-|-|
| `Weapon` | String | Current weapon type (e.g., "handgun", "rifle", "barehand") |
| `aim` | String | Aim mode |
| `IsPerformingAnAction` | Boolean | True during timed actions |
| `PerformingAction` | String | Current action animation node name |
| `AttackType` | String | "bite", etc. (zombie attacks) |
| `ThumpType` | String | "Door", "DoorClaw", "DoorBang" (zombie thumping) |
| `AttackDidDamage` | Boolean | Whether an attack connected |
| `EatingStarted` | Boolean | Zombie feeding flag |
| `FootInjury` | String | Foot injury limp type |
| `canRagdoll` | Boolean | Whether ragdoll is allowed |
| `TimedActionType` | String | Type specifier for timed action anims |

**Variable resolution chain:** When the animation system queries a variable, it checks:
1. `ActionContext` variables (from ActionState) - highest priority
2. Character game variables (`IsoGameCharacter.getGameVariablesInternal()`)

**Sub-variable sources:** The `GrappledTarget` sub-source lets grapple animation conditions reference the target's variables via dotted names (e.g., `GrappledTarget.Weapon`).

---

## 9. AnimEvent System

**AnimEvent** (`zombie.core.skinnedmodel.advancedanimation.AnimEvent`)

Timed callbacks fired during animation playback.

| XML Element | Field | Type | Description |
|-|-|-|-|
| `m_EventName` | `eventName` | String | Event identifier |
| `m_Time` | `time` | AnimEventTime | When to fire: `PERCENTAGE`, `START`, `END` |
| `m_TimePc` | `timePc` | float | Percentage (0-1) for PERCENTAGE timing |
| `m_ParameterValue` | `parameterValue` | String | Event-specific parameter |

**Special event types:**
- `SetVariable` - automatically parsed into `AnimEventSetVariable`, sets an animation variable at the specified time
- `FlagWhileAlive` - parsed into `AnimEventFlagWhileAlive`, maintains a flag counter that increments when the event fires and decrements when the LiveAnimNode is released

**Event propagation:** Events flow from `AnimLayer` -> `AdvancedAnimator.OnAnimEvent()` -> all registered `IAnimEventCallback` handlers. The timed action system's `BaseAction.OnAnimEvent()` receives these for action-specific handling.

---

## 10. ActionContext and ActionGroup

**ActionGroup** (`zombie.characters.action.ActionGroup`)

XML-driven state machine that maps character state to animation states. Loaded from `media/actiongroups/<name>/`.

Structure:
```
media/actiongroups/<name>/
  actionGroup.xml          -- group config (initial state)
  <stateName>/             -- one folder per ActionState
    actionstate.xml        -- state variables + transitions
```

**ActionState** (`zombie.characters.action.ActionState`)

| Feature | Description |
|-|-|
| `transitions` | List of `ActionTransition` rules evaluated each frame |
| `tags` / `childTags` | Enable sub-state layering (upper/lower body split) |
| `stateVariables` | Variables injected when this state is active |
| `isGrapplerState` | Marks grapple-initiator states |

**ActionTransition** conditions (from `zombie.characters.action.conditions`):
| Condition Type | Description |
|-|-|
| `CharacterVariableCondition` | Check an animation variable value |
| `EventOccurred` | Check if a named event has been reported |
| `EventNotOccurred` | Check that an event has NOT been reported |
| `LuaCall` | Call a Lua function for custom logic |

**ActionContext** bridges the ActionGroup to the animation system:
- Evaluates transitions each frame to determine the current ActionState
- Exposes ActionState variables to the animation variable resolution chain
- Tracks reported events via `reportEvent(name)` and clears them after transitions

---

## 11. Timed Action Animations

Timed actions (ISBaseTimedAction subclasses) use `BaseAction` (Java) for animation control.

**Lua API for timed actions:**

```lua
-- In your ISBaseTimedAction:start() method:
function MyAction:start()
    -- Set the animation node to play
    self:setActionAnim("Craft")
    -- OR use the enum
    self:setActionAnim(CharacterActionAnims.Drink)

    -- Override held item models during the action
    self:setOverrideHandModels(primaryItem, secondaryItem)
    -- Or by model name string
    self:setOverrideHandModelsString("Hammer", nil)

    -- Report an event to the action system
    self.character:reportEvent("EventStartSomething")

    -- Set animation variables directly
    self.action:setAnimVariable("MyCustomVar", "value")

    -- For looped actions
    self.action:setLoopedAction(true)
end
```

**CharacterActionAnims enum** (valid values for `setActionAnim`):
`None`, `Drink`, `Read`, `Chop_tree`, `Disassemble`, `Paint`, `Eat`, `Reload`, `Dig`, `DigShovel`, `DigHoe`, `DigPickAxe`, `DigTrowel`, `Pour`, `Build`, `BuildLow`, `Craft`, `Bandage`, `TakePills`, `Destroy`, `Shave`, `InsertBullets`, `RemoveBullets`

**How it works internally:**
1. `setActionAnim(animNode)` calls `setAnimVariable("PerformingAction", animNode)` and sets `IsPerformingAnAction = true`
2. The ActionGroup's transitions detect these variables and switch to the appropriate ActionState
3. The ActionState sets the AnimationSet state (e.g., "performaction")
4. AnimNodes in that state check `PerformingAction` via conditions to pick the right animation

**StartTimedActionAnim / StopTimedActionAnim:**
```lua
character:StartTimedActionAnim("EventName")         -- reports event, resets model
character:StartTimedActionAnim("EventName", "type")  -- also sets TimedActionType variable
character:StopTimedActionAnim()                      -- clears TimedActionType, reports Event_TA_Exit
```

---

## 12. Combat Animations

**Player combat** (`AttackState`, `SwipeStatePlayer`)

Player attacks set variables that drive animation selection:
- Weapon type determines the AnimNode (barehand, axe, bat, handgun, rifle, etc.)
- Aim mode affects stance and swing direction

**Zombie attacks** (`AttackState` for zombies):
```java
// In AttackState.execute():
owner.setVariable("AttackType", "bite");
zombie.parameterZombieState.setState(ParameterZombieState.State.Attack);
// On hit resolution:
owner.setVariable("AttackDidDamage", bDamaged);
owner.setVariable("EatingStarted", true); // if feeding begins
```

**Zombie thumping** (`ThumpState`):
```java
// Door thumping - variable determines animation variant:
owner.setVariable("ThumpType", "DoorClaw");  // claw at door
owner.setVariable("ThumpType", "Door");       // push/thump door
owner.setVariable("ThumpType", "DoorBang");   // heavy slam
```

**Grapple system:**
- AnimNodes define `m_MatchingGrappledAnimNode` to pair attacker/victim animations
- `GrappleOffsetBehaviour` controls positioning (`GRAPPLED` vs other modes)
- Grapple offset and tween time are per-node configurable
- Sub-variable source `GrappledTarget` lets conditions reference the victim's animation state

**Hit reactions** (`ZombieHitReactionState`, `HitReactionNetworkAI`):
- `setHitReaction(type)` drives the hit reaction animation selection
- Ragdoll can trigger based on `isRagdoll` flag and `chanceToRagdoll` probability

---

## 13. Zombie Animation States

Zombie AI states (all in `zombie.ai.states`):

| State Class | Description | Key Variables |
|-|-|-|
| `ZombieIdleState` | Standing/wandering idle | - |
| `WalkTowardState` | Walking toward target | - |
| `LungeState` | Lunging at target | `ParameterZombieState.LockTarget` |
| `AttackState` | Biting/attacking | `AttackType`, `AttackDidDamage`, `EatingStarted` |
| `ThumpState` | Thumping doors/barricades | `ThumpType` |
| `ZombieEatBodyState` | Feeding on corpse | `EatingStarted` |
| `ZombieFallDownState` | Falling down (from hit) | - |
| `ZombieGetUpState` | Getting up from ground | (checks previous state) |
| `ZombieGetDownState` | Transitioning to crawl | - |
| `ZombieGetUpFromCrawlState` | Standing up from crawler | - |
| `ZombieOnGroundState` | Lying on ground | - |
| `ZombieRagdollOnGroundState` | Ragdoll on ground | - |
| `ZombieHitReactionState` | Reacting to being hit | hitReaction type |
| `ZombieFallingState` | Falling (from height) | - |
| `ZombieSittingState` | Sitting (spawn state) | - |
| `ZombieReanimateState` | Reanimating from death | - |
| `ZombieFaceTargetState` | Turning to face target | - |
| `ZombieGenericState` | Generic/scripted behavior | - |
| `FakeDeadAttackState` | Fake-dead surprise attack | - |
| `ClimbOverFenceState` | Climbing over fence | - |
| `ClimbThroughWindowState` | Climbing through window | - |

**Crawler system:** Crawlers use `ZombieGetDownState` to transition from standing to crawling, and `ZombieGetUpFromCrawlState` to stand back up. The `ZombieGetUpState` checks its previous state to determine which get-up animation to play.

---

## 14. Lua API Reference

**IsoGameCharacter animation methods (exposed to Lua):**

| Method | Signature | Description |
|-|-|-|
| `setVariable` | `(key, value)` | Set string/bool/float animation variable |
| `getVariableString` | `(key)` | Get string variable value |
| `getVariableBoolean` | `(key)` | Get boolean variable value |
| `getVariableFloat` | `(key, default)` | Get float variable value with fallback |
| `clearVariable` | `(key)` | Remove a variable |
| `clearVariables` | `()` | Remove all variables |
| `reportEvent` | `(name)` | Report an event to ActionContext |
| `StartTimedActionAnim` | `(event, type?)` | Start timed action animation |
| `StopTimedActionAnim` | `()` | Stop timed action animation |
| `getAnimationPlayer` | `()` | Get the AnimationPlayer instance |
| `getAdvancedAnimator` | `()` | Get the AdvancedAnimator |
| `resetModel` | `()` | Force model rebuild |
| `resetModelNextFrame` | `()` | Schedule model rebuild next frame |
| `setHitReaction` | `(type)` | Set hit reaction animation type |
| `getCurrentStateName` | `()` | Get AI state machine current state name |

**BaseAction (timed action) methods:**

| Method | Signature | Description |
|-|-|-|
| `setActionAnim` | `(anim)` | Set PerformingAction variable |
| `setAnimVariable` | `(key, val)` | Set variable, tracked for auto-cleanup |
| `setOverrideHandModels` | `(primary, secondary)` | Override held items during action |
| `setOverrideHandModelsString` | `(primary, secondary)` | Override by model name |
| `overrideWeaponType` | `()` | Recalculate Weapon variable from overrides |
| `restoreWeaponType` | `()` | Restore Weapon variable from equipped items |
| `setLoopedAction` | `(bool)` | Set whether the action loops |
| `OnAnimEvent` | `(event)` | Override to handle animation events |

**Global Lua functions:**
- `refreshAnimSets(reload)` - reload all AnimationSets
- `reloadActionGroups()` - reload all ActionGroups

---

## 15. Modding - Adding/Overriding Animations

**Adding AnimSet overrides:**

Mods can override or add AnimNodes by placing XML files in the same directory structure:
```
MyMod/Contents/mods/MyMod/42/media/AnimSets/<SetName>/<StateName>/mynode.xml
```

The file system resolves files from mods first (via `ZomboidFileSystem.resolveAllFiles()`), so mod files with the **same name** override vanilla nodes, and **new files** add additional nodes.

**Adding ActionGroup overrides:**

Same principle for ActionGroups:
```
MyMod/Contents/mods/MyMod/42/media/actiongroups/<GroupName>/<StateName>/actionstate.xml
```

**Hot-reload:** Both AnimSets and ActionGroups support hot-reload via file watchers when running with debug mode. Changes to XML files trigger automatic refresh.

**Mod detection:** `AdvancedAnimator.isAnimSetFilePath()` checks both vanilla paths and mod paths using `ZomboidFileSystem.getModIDs()` and `ChooseGameInfo.Mod.animSetsFile`.

**Adding custom animations (FBX):**
1. Create `.x` or `.fbx` animation files
2. Place them in `42/media/AnimSets/<SetName>/<StateName>/`
3. Create an AnimNode XML referencing the clip name in `m_AnimName`
4. Add appropriate `m_Conditions` to control when the animation plays

**Variable-driven animation selection example:**
```xml
<animNode>
  <m_Name>idle_customweapon</m_Name>
  <m_AnimName>Bob_Idle_CustomWeapon</m_AnimName>
  <m_Looped>true</m_Looped>
  <m_ConditionPriority>10</m_ConditionPriority>
  <m_Conditions>
    <item>
      <m_Name>Weapon</m_Name>
      <m_Type>STRING</m_Type>
      <m_Value>customweapon</m_Value>
    </item>
  </m_Conditions>
</animNode>
```

**Key modding patterns:**
- Set `conditionPriority` higher than vanilla nodes to ensure your node is checked first
- Use `alternateAnims` for variety without duplicating node XMLs
- Use `m_SpeedScaleVariable` to drive animation speed from a character variable
- Override `BaseAction:OnAnimEvent()` in Lua to react to animation timing
- Use `reportEvent()` to trigger ActionGroup transitions from Lua code
