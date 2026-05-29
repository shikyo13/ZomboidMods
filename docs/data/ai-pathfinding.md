# AI & Pathfinding - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | State Machine Architecture | 22-63 |
| 2 | Zombie State Catalog | 64-200 |
| 3 | State Transitions | 201-250 |
| 4 | Pathfinding System | 251-303 |
| 5 | Group Behavior & Herding | 304-341 |
| 6 | Target Selection & Detection | 342-371 |
| 7 | Crawler vs Walker Differences | 372-398 |
| 8 | Sadistic AI Director | 399-432 |
| 9 | AI Update Loop & Performance | 433-454 |
| 10 | Sight & Hearing Ranges | 455-509 |
| 11 | Line-of-Sight Calculation | 510-574 |
| 12 | Target Priority System | 575-623 |
| 13 | Aggro Persistence | 624-687 |
| 14 | Multi-Player Target Selection | 688-732 |

## 1. State Machine Architecture

Package: `zombie.ai`

### StateMachine [pub final]
Root state + concurrent substates pattern. One root state active at a time, with optional substates running in parallel.

| Member | Access | Type | Description |
|-|-|-|-|
| currentState | [priv] | State | Active root state |
| previousState | [priv] | State | Last root state (for revert) |
| owner | [priv final] | IsoGameCharacter | Character owning this FSM |
| subStates | [priv final] | List\<SubstateSlot\> | Concurrent substates |
| isLocked | [priv] | boolean | Prevents state changes when true |
| activeStateChanged | [pub] | int | Change counter |

**Key methods:**
| Method | Access | Description |
|-|-|-|
| changeState(State, Iterable, boolean) | [pub] | Set root + substates, optionally restart |
| changeRootState(State, boolean) | [priv] | Exit old, enter new, fires `OnAIStateChange` Lua event |
| revertToPreviousState(State) | [pub] | Returns to previousState or removes substate |
| update() | [pub] | Executes currentState then all substates |
| stateAnimEvent(...) | [pub final] | Routes anim events to root + substates |

**Lua hook:** `LuaEventManager.triggerEvent("OnAIStateChange", owner, currentState, previousState)` fires on every root state change.

### State [pub abstract]
Base class for all states. Implements `IAnimEventListener`, `IStateFlagsSource`.

| Member | Access | Type | Description |
|-|-|-|-|
| isSyncOnEnter | [priv final] | boolean | MP sync flag on enter |
| isSyncOnExit | [priv final] | boolean | MP sync flag on exit |
| isSyncOnSquare | [priv final] | boolean | MP sync on square change |
| isSyncInIdle | [priv final] | boolean | MP sync during idle |
| animEventBroadcaster | [priv final] | AnimEventBroadcaster | Dispatches anim events |

**Lifecycle:** `enter(owner)` -> `execute(owner)` (each tick) -> `exit(owner)`

**Param\<T\> system:** Type-safe per-state parameters stored on character. Factory methods: `ofInt`, `ofLong`, `ofFloat`, `ofBool`, `ofString`, `of`, `ofSupplier`. Params auto-register to the declaring State subclass via stack inspection.

## 2. Zombie State Catalog

Package: `zombie.ai.states`

All zombie states are singletons (private constructor, `static instance()` method).

### Core Movement States

**ZombieIdleState** - Default resting state.
- On enter: clears sound target, resets movement, sets random wander timer
- Wander interval: `Rand.Next(400, 1000)` ticks, 1.5x longer when not raining
- Periodically picks random location within +/-4 tiles and pathfinds there
- In Last Stand mode: always paths to nearest living player
- Indoor zombies (`indoorZombie=true`) and useless zombies skip wandering

**PathFindState** - A* pathfinding in progress (async request).
- Sets `bPathfind=true`, `bMoving=false`
- Delegates to `PathFindBehavior2.update()` which returns Failed/Succeeded/InProgress
- On exit: cancels request in PolygonalMap2 or PathfindNative, resets finder progress
- Supports native code pathfinding via `PathfindNative.useNativeCode` flag

**WalkTowardState** - Direct walking toward a computed target point.
- Uses `PathFindBehavior2.getTargetX/Y()` for direction
- Applies per-zombie offset to prevent stacking: offset derived from `(zombieId % 20)`
- When colliding with object/vehicle: repath immediately with `allowRepathDelay=0`
- Walking-on-the-spot detection triggers `bMoving=false`
- On exit: clears `bMoving`, triggers network AI update

**LungeState** - Charge/lunge at close target.
- Timer: `lungeTimer = 180.0f` ticks (6 seconds at 30fps)
- Plays attack voice sound with 5-second cooldown
- Moves in `vectorToTarget` direction using `getZombieLungeSpeed()`
- If target lost: paths to `lastTargetSeenX/Y/Z`
- Sets audio state to `ParameterZombieState.State.LockTarget`

### Combat States

**AttackState** - Bite/attack a target character.
- Outcome lifecycle: `start` -> `success`/`fail`/`interrupted`/`enddeath`
- On `AttackCollisionCheck` anim event: performs hit direction test, applies `AddRandomDamageFromZombie`
- Front-facing targets with active attacks are immune (they can counter)
- Knife defense chance: `max(0, 9 - (SmallBlade+1)*2)` random check
- Speed type 1 (shambler) applies slow factor: +0.03/tick up to 0.5 cap
- On exit: if target is on floor, switches to `ZombieEatBodyState`
- Sets `target.timeSinceZombieAttack = 0` each tick

**FakeDeadAttackState** - Ambush attack from playing-dead position.
- Triggers 3x panic increase on non-DESENSITIZED players
- `AttackCollisionCheck`: cone check `isTargetInCone(1.5f, 0.9f)`, can attack vehicle passengers
- After attack animation: `setCrawler(true)` - zombie becomes crawler

**ZombieEatBodyState** - Consuming a fallen target.
- Duration: `Rand.Next(1800, 3600)` ticks (1-2 minutes)
- Spawns blood splats, giblets (type A and B) randomly
- Tracks eating zombies per body via `deadBody.getEatingZombies()`
- Audio state: `ParameterZombieState.State.Eating`

### Obstacle Interaction States

**ThumpState** - Attacking doors, windows, barricades, vehicles.
- On enter: picks random ThumpType: `DoorClaw`, `Door`, or `DoorBang`
- Damage occurs on `thumpframe` anim event
- Thump count multiplied by zombies on same square (`sq.getMovingObjects().size()`)
- `timeSinceSeenFlesh < 5.0f` resets thump timer (saw player recently)
- Sound types: Generic, Window, WindowExtra, Metal, GarageDoor, ChainlinkFence, MetalPoleFence, Wood
- After destroying target: attempts lunge through door, or paths to `lastTargetSeenX/Y/Z`
- Slides zombie away from wall edges to maintain proper positioning (0.4-0.47 tile offset)
- Fast-forward damage multiplier: `200 * (30/lockFPS) / 1.6` when players sleeping

**ClimbOverFenceState** - Climbing/vaulting over fences.
- Fence types: Wood(0), Metal(1), Sandbag(2), Gravelbag(3), Barbwire(4), Roadblock(5), MetalBars(6)
- Zombie lunge through fence: `shouldDoFenceLunge()` with angle-based targeting
- 2+ zombies climbing same fence: damages it by 7-12 hp (halved for metal)
- Sprint vault fall chance based on: Endurance, Drunk, HeavyLoad, Pain moodles + traits (Clumsy+10%, Graceful-10%, Obese+20%)
- On exit: resumes PathFindState or WalkTowardState from before climb

**ClimbThroughWindowState** - Climbing through windows.
- Zombie flop on broken glass: adds heavy blood to head/neck/torso
- Obstacle detection: `solidtrans` flag on opposite square
- Player can be knocked back by zombie during climb (`checkForFallingBack`)
- Damages player-built windows: 10-20 hp per zombie flop

**SmashWindowState, OpenWindowState, CloseWindowState** - Window interaction states (used by both players and zombies).

### Damage/Recovery States

**ZombieHitReactionState** - Response to being hit.
- Tracks `HIT_REACTION_TIMER` for animation timing
- `DoDeath` anim event: kills zombie, increments attacker's `zombieKills`
- `KnockDown` event: sets `onFloor=true`, `knockedDown=true`
- `SplatBlood` event: adds 3 blood, 10 floor splats, spawns giblets
- On exit: clears sit-against-wall, re-enables shooting, re-targets if has target

**StaggerBackState** - Staggered by hit.
- Duration: `35 * hitForce * staggerTimeMod`, clamped to 20-30 ticks
- Audio state: `ParameterZombieState.State.Pushed`

**ZombieFallDownState, ZombieFallingState** - Falling from heights.

**ZombieOnGroundState** - Lying on ground after knockdown.
- If dead/fakeDead: calls `die()` to create dead body
- If `becomeCrawler`: waits until not stepped on/under vehicle, then `setCrawler(true)`
- Reanimate timer: `Rand.Next(60) + 30` ticks (1-3 seconds)
- Standing-on check: bone collision against Spine, L_Calf, R_Calf, Head with distance thresholds
- Stepped-on zombies get timer reset, delaying reanimate

**ZombieGetUpState** - Getting up from ground.
- On exit: resumes previous pathfind/walk state
- Clears sit-against-wall, sprinter-tripped flags

**ZombieReanimateState** - Reanimation after knockdown.
- Animation-driven: `ReanimateAnimFinishing` event triggers `setReanimate(false)`

### Special States

**FakeDeadZombieState** - Playing dead.
- Enter: invisible to NPCs, non-collidable, `onFloor=true`
- If killed while fake-dead: creates IsoDeadBody
- In Last Stand mode: immediately stops playing dead

**ZombieSittingState** - Sitting against a wall.
- Delegates position to `ZombiePopulationManager.sitAgainstWall()`

**ZombieFaceTargetState** - Turning to face current target.

**CrawlingZombieTurnState** - Crawler-specific turning animation.
- Uses `TurnSome` (lerp) and `TurnComplete` (snap) anim events
- Direction calculation: ordinal difference > 4 means turn right

**ZombieGenericState** - Generic animation state (catch-all).

**BumpedState** - Bumped by another character.

**CollideWithWallState** - Hit a wall while moving.

**VehicleCollisionState, VehicleCollisionMinorStaggerState, VehicleCollisionOnGroundState** - Vehicle impact states.

## 3. State Transitions

### Primary Zombie Flow
```
[Spawn] -> ZombieIdleState
  |-> (hear sound/see player) -> PathFindState -> WalkTowardState -> LungeState -> AttackState
  |-> (wander timer) -> PathFindState -> WalkTowardState -> ZombieIdleState
  |-> (obstacle) -> ThumpState -> (destroyed) -> PathFindState or LungeState
  |-> (fence) -> ClimbOverFenceState -> (resume previous)
  |-> (window) -> ClimbThroughWindowState -> (resume previous)
```

### Attack Chain
```
AttackState -> (target alive, on floor) -> ZombieEatBodyState -> ZombieIdleState
AttackState -> (target dead) -> ZombieEatBodyState -> ZombieIdleState
AttackState -> (interrupted) -> PathFindState/WalkTowardState
```

### Damage Chain
```
(any state) -> ZombieHitReactionState -> ZombieFallDownState -> ZombieOnGroundState
ZombieOnGroundState -> (timer expired) -> ZombieGetUpState -> (previous state)
ZombieOnGroundState -> (becomeCrawler) -> ZombieReanimateState -> (crawler states)
```

### FakeDead Chain
```
FakeDeadZombieState -> (player proximity) -> FakeDeadAttackState -> (crawler) -> CrawlingZombieTurnState
```

### Thump Resolution
```
ThumpState -> (door destroyed, player visible) -> LungeState (set target, lunge through)
ThumpState -> (window destroyed, climbable) -> ClimbThroughWindowState
ThumpState -> (target lost) -> PathFindState (to lastTargetSeenX/Y/Z)
```

### Key Transition Triggers
| Trigger | From | To |
|-|-|-|
| `zombie.spotted(target)` | ZombieIdleState | PathFindState/WalkTowardState |
| `zombie.pathToLocation()` | ZombieIdleState | PathFindState |
| `target.isOnFloor()` | AttackState exit | ZombieEatBodyState |
| `timeSinceSeenFlesh < 5` | ThumpState | Resets thump timer |
| `lungeTimer <= 0` | LungeState | Repaths to target |
| `bPathfind=false, bMoving=false` | WalkTowardState | ZombieIdleState |
| Collision detected | WalkTowardState | PathFindState (repath) |
| `isBecomeCrawler()` | ZombieOnGroundState | ZombieReanimateState |

## 4. Pathfinding System

Package: `zombie.pathfind`

### Architecture
PZ uses a **polygonal navigation mesh** (PolygonalMap2) with optional native code acceleration (PZPopMan64.dll). The system has two layers:

**Low-level:** Grid-based A* (`zombie.ai.astar.AStarPathFinder`)
- Progress enum: `notrunning`, `failed`, `found`, `notyetfound`
- Used as fallback and for short paths

**High-level:** `zombie.pathfind.highLevel.HLAStar`
- Hierarchical A* over chunk regions
- Components: HLChunkLevel, HLChunkRegion, HLLevelTransition, HLStaircase, HLSlopedSurface
- Flood-fill for region connectivity (`FloodFill`)

### PolygonalMap2 [pub] (Main pathfinder)
Manages obstacles, vehicle clusters, path requests, and line-of-sight checks.

Key dependencies:
- Cell, Chunk, ChunkDataZ - spatial data
- Node, Edge, EdgeRing - navigation graph
- Obstacle, VehicleCluster, VehiclePoly - collision shapes
- PathFindRequest, RequestQueue - async request system
- LineClearCollide, CollideWithObstacles - collision testing
- PathFindBehavior2 - per-character behavior wrapper

### PathFindBehavior2
Per-character pathfinding wrapper. Returns `BehaviorResult`:
- `Failed` - path could not be found
- `Succeeded` - reached destination
- `InProgress` - still navigating

Tracks `walkingOnTheSpot` to detect stuck characters.

### Request Pipeline
1. Character calls `pathToLocation(x, y, z)` or `pathToCharacter(target)`
2. PathFindRequest queued in RequestQueue
3. PolygonalMap2 (or PathfindNative) processes async
4. PathFindState polls `PathFindBehavior2.update()` each tick
5. On success: transitions to WalkTowardState
6. On failure: clears pathfind variables, falls back to idle

### Line-of-Sight
`LineClearCollide` and `LineClearCollideMain` provide tile-based visibility checks used for:
- Target visibility (`zombie.isTargetLocationKnown()`)
- Sound propagation
- Thump target validation
- Group separation checks

### MapKnowledge [pub final]
Per-character memory of blocked edges (doors, windows). Tracks N and W edges per tile coordinate. Prevents zombies from repeatedly trying blocked paths.

## 5. Group Behavior & Herding

Package: `zombie.ai.ZombieGroupManager`

### ZombieGroupManager [pub final]
Singleton managing zombie rally groups. Update tick: every 30 frames (~1 second).

**Group eligibility** (`shouldBeInGroup`):
- Rally group size > 1 (sandbox option)
- `Core.isZombieGroupSound()` enabled
- Not useless, dead, fakeDead, sitting, in building, reused by VirtualZombieManager, reanimatedForGrappleOnly
- Not in Forest or DeepForest zones

**Group lifecycle:**
1. Idle zombie without group: `findNearestGroup()` by distance
2. No nearby group: create new ZombieGroup
3. Leader behavior: repels from other group leaders (separation force)
4. Members: walk toward random point near leader

### Sandbox Configuration
| Setting | Field | Used In |
|-|-|-|
| Rally Group Size | `zombieConfig.rallyGroupSize` | Max members per group |
| Rally Group Radius | `zombieConfig.rallyGroupRadius` | Member follow distance |
| Rally Group Separation | `zombieConfig.rallyGroupSeparation` | Min distance between group leaders |
| Rally Travel Distance | `zombieConfig.rallyTravelDistance` | Max join distance |

### Leader Behavior
- Calculates separation vector from nearby group leaders
- Line-clear-collide test for valid movement path (up to 10 steps)
- Spread-out cooldown: 0.083 hours (~5 minutes)
- Suppressed for first 2 hours of gameplay (non-MP)

### Member Behavior
- Picks random point within `rallyGroupRadius` of leader
- Uses `pathToLocation()` with `allowRepathDelay = 400.0f`
- Only updates when in ZombieIdleState

## 6. Target Selection & Detection

Package: `zombie.ai.GameCharacterAIBrain`

### GameCharacterAIBrain [pub final]
| Member | Access | Type | Description |
|-|-|-|-|
| spottedCharacters | [pub] | ArrayList\<IsoGameCharacter\> | Currently visible characters |
| aiTarget | [pub] | IsoMovingObject | Current AI target |
| chasingZombies | [pub] | ArrayList\<IsoZombie\> | Zombies chasing this character |
| teammateChasingZombies | [pub] | ArrayList\<IsoZombie\> | Team zombies |
| blockedMemories | [pub] | HashMap\<Vector3, ArrayList\<Vector3\>\> | Remembered blocked paths |
| aiFocusPoint | [pub] | Vector2 | Focus direction |
| nextPathTarget | [pub] | Vector3 | Next waypoint |
| isAi | [pub] | boolean | NPC or player |

### getClosestChasingZombie(boolean recurse)
Priority sorting for closest threat:
1. Own chasing zombies (skip line-blocked, skip thumping, skip non-targeting)
2. If recurse and none found: check group members' chasers
3. If recurse and still none: check spotted characters' chasers
4. Distance cap: 30 tiles max
5. On-floor penalty: +2.0 distance (deprioritize downed zombies)

### Blocked Path Memory
- `AddBlockedMemory(x, y, z)`: records from-tile -> to-tile blocked edge
- `HasBlockedMemory(lx, ly, lz, x, y, z)`: checks if path was previously blocked
- Synchronized access (thread-safe for MP)
- Used by pathfinder to avoid known dead-ends

## 7. Crawler vs Walker Differences

### Behavioral Differences
| Aspect | Walker | Crawler |
|-|-|-|
| On floor | false | true (always) |
| Turn system | IsoDirections.fromAngle | CrawlingZombieTurnState (animated turn) |
| Movement | WalkTowardState (normal) | WalkTowardState (no offset, no direction snap) |
| Forward direction | Set from IsoDirections | Set via `setForwardDirection()` only if TurnDirection empty |
| Attack | AttackState (bite) | AttackState (crawl bite, 1.3f range for fakeDead) |
| FakeDead transition | FakeDeadAttackState -> crawler | Already crawler |
| Fence climb | ClimbOverFenceState | ClimbOverFenceState (ZOMBIE_ON_FLOOR=true during) |
| Vehicle interaction | Can attack | Can attack passengers via `couldCrawlerAttackPassenger` |

### Crawler Creation
Crawlers are created via:
1. Spawn with `state.isCrawling()` flag from population manager
2. `ZombieOnGroundState` with `isBecomeCrawler()` - legs destroyed by damage
3. `FakeDeadAttackState` - `ActiveAnimFinishing` event sets `setCrawler(true)`
4. Sandbox settings: crawler percentage in zombie config

### CrawlingZombieTurnState
Crawlers cannot snap-rotate. They must animate through turns:
- `TurnSome` event: lerps between current and target direction at `event.timePc`
- `TurnComplete` event: snaps to `RotLeft()` or `RotRight()` of current direction
- Direction algorithm: ordinal difference determines left vs right turn

## 8. Sadistic AI Director

Package: `zombie.ai.sadisticAIDirector`

### SleepingEvent [pub final]
Manages sleep-time events including zombie intrusions and nightmares.

**Zombie intrusion calculation:**
1. Base chance: 20% (45% on "Often" setting)
2. Building scan for attraction factors:
   - Running fridge/freezer: +3 per unit
   - Active stove: +5
   - TV on: +30
   - Radio on: +30
   - Open exterior door: +25
   - Window status: depends on curtains, barricades, lights, floor level
3. Cap at 70% total, halved for daytime sleep
4. "Often" setting multiplies by 1.5x
5. Spawn 1-3 zombies at weakest entry point (open door or weakest window)
6. Spawned zombies immediately target and path to sleeping player

**Nightmare system:**
- Base 5% chance, +5% for DESENSITIZED trait, +10% per Stress moodle level
- Wakes player with +70 panic, +0.5 stress
- Requires 3+ hours sleep time

**Sleep delay factors:**
- Insomniac trait: base 1.0 (normal 0.3)
- Pain, Stress moodles increase delay
- Bed quality: goodBedPillow x0.6, floor x1.6
- Night Owl trait: x0.5
- Sleeping tablets (>1000 effect): 0.1
- Max delay: 2.0 hours

## 9. AI Update Loop & Performance

### Update Flow (per tick)
1. `ZombieGroupManager.preupdate()` - group management (every 30 ticks)
2. Per zombie: `ZombieGroupManager.update(zombie)` - group membership/movement
3. `StateMachine.update()` - execute current state + all substates
4. State.execute() wrapped in try-catch for error resilience
5. Animation recorder logging (debug only)

### Performance Characteristics
- StateMachine locked check prevents state change during execution
- PathFindState uses async requests - does not block main thread
- Native pathfinding (PZPopMan64.dll) for population-level movement
- PolygonalMap2 for local character pathfinding
- Group manager only processes once per second (30-tick interval)
- Walking-on-the-spot detection avoids infinite pathfind loops
- `allowRepathDelay` throttles repath frequency per zombie
- `isUseless()` check skips processing for off-screen/irrelevant zombies
- State singletons (zero allocation per state change)
- Param\<T\> stored on character via IdentityHashMap (fast lookup)
- SubstateSlot pooling via `isEmpty()` check + reuse

## 10. Sight & Hearing Ranges
Source: `zombie.characters.IsoZombie` - `updateVisionRadius()`, `DoZombieStats()`, `RespondToSound()`

### Vision Radius Calculation
Base vision radius: **20.0 tiles**, clamped to [10.0, 20.0] after adjustments.

```
visionRadius = 20.0 - max(darknessPenalty, rainPenalty + fogPenalty)
```

**Environmental penalties:**
| Factor | Formula | Max Penalty |
|-|-|-|
| Darkness | `(1.0 - lightLevel) * 5.0` | 5.0 tiles |
| Rain | `rainIntensity * 2.5` | 2.5 tiles |
| Fog | `fogIntensity * 7.0` | 7.0 tiles |

Uses the worse of darkness alone or (rain + fog) combined. Light level comes from the target player's square lighting or ambient daylight.

### Sight Sandbox Multiplier
| Sandbox sight value | Meaning | Vision multiplier |
|-|-|-|
| 1 | Eagle | x1.75 |
| 2 (default) | Normal | x1.0 |
| 3 | Poor | x0.35 |
| 4 | Random | Rand(1-3) per zombie |
| 5 | Random (Normal/Poor) | Rand(2-3) per zombie |

Assigned per-zombie at spawn via `DoZombieStats()`. The `sight` field is stored on each zombie.

### Additional Vision Modifiers
| Condition | Multiplier |
|-|-|
| Eating a body | x0.5 |
| Worn items (masks, etc.) | `/getWornItemsVisionModifier()` |

### Hearing Sandbox Settings
| Sandbox hearing value | Meaning | Sound offset |
|-|-|-|
| 1 | Pinpoint | -2 tiles (more accurate) |
| 2 (default) | Normal | base offset |
| 3 | Poor | +2 tiles (less accurate) |
| 4 | Random | Rand(1-3) per zombie |
| 5 | Random (Normal/Poor) | Rand(2-3) per zombie |

### Sound Response System (`RespondToSound`)
- Only processes when `timeSinceSeenFlesh > 240.0` AND `timeSinceRespondToSound > 5.0`
- Sound attract value determined by `WorldSoundManager.getSoundAttract()`
- Sound location is jittered by `Rand(-dist/2.5, dist/2.5)` based on zombie-to-sound distance
- Rain intensifies hearing inaccuracy: offset clamped [2, 10], rain > 0.5 adds +3 base offset
- Repeating sounds within 5 tiles with clear LOS are ignored (zombie already close enough)
- Sound reaction delay: `Rand(0, 16)` ticks before responding
- `allowRepathDelay = 120.0` set after responding to a sound
- Will stop thumping to respond to a sound if: source is not zombie, radius >= 10, sound is behind the zombie

## 11. Line-of-Sight Calculation
Source: `zombie.characters.IsoZombie.spottedNew()`, `zombie.iso.LosUtil`

### Spotting Chance - Angular FOV
At distances > 0.5 tiles, the dot product between the zombie's forward direction and the direction to the target determines a multiplier on the base spot chance:

| cosAngle range | Multiplier | Approximate angle |
|-|-|-|
| < -0.4 | x0.0 (cannot see) | > ~113 deg off-center |
| -0.4 to -0.2 | /8.0 | ~101-113 deg |
| -0.2 to 0.0 | /4.0 | ~90-101 deg |
| 0.0 to 0.2 | /2.0 | ~78-90 deg |
| 0.2 to 0.4 | x2.0 | ~66-78 deg |
| 0.4 to 0.6 | x8.0 | ~53-66 deg |
| 0.6 to 0.8 | x16.0 | ~37-53 deg |
| > 0.8 | x32.0 | < ~37 deg (directly ahead) |

### Light-Based Detection
```java
lightData = (r + g + b) / 3.0  // from target's square lighting
chance *= lightData  // 0.0 in full dark, 1.0 in full light
```

### Elevation Penalty
Different Z-levels: `chance /= (abs(zDiff) * 5 + 1)`.

### Vehicle Obstruction
Ray test from target to zombie checks all vehicles in the cell. If a vehicle intersects the ray:
- Target in a vehicle: still visible (ignored)
- Target on foot, distance > 1.5 tiles: `chance *= 0.0` (completely hidden)
- Target on foot, distance <= 1.5 tiles: `chance *= 0.5` (partially hidden)

### Movement Detection Modifiers
| Target state | Modifier |
|-|-|
| Stationary (movement = 0) | x0.8 |
| Walking (movement = 0.5) | x1.0 |
| Running (movement = 1.0) | x1.5 |
| Sprinting (movement = 1.5) | x2.0 |
| Close (<5 tiles) and running | additional x3.0 |

### Sneaking & Trait Modifiers
| Condition | Effect |
|-|-|
| Sneaking | `chance *= getSneakSpotMod()` (perk-based) |
| Not sneaking | `sneakingMod = 1.0` |
| Inconspicuous trait | x0.8 |
| Conspicuous trait | x1.2 |
| Inactive zombie | x0.25 |
| bonusSpotTime active | x5.0 |
| Eating a body | x0.5 |

### Shelter (Cover) Modifier
When sneaking and on different squares, the obstacle between zombie and target is checked. Obstacles (furniture providing cover) along the approach direction reduce spot chance.

### Final Probability Calculation
```java
chance = min(chance, 400.0)
chance /= 400.0  // normalize to 0-1
chance = max(0.0, min(1.0, chance))
chance = 1.0 - pow(1.0 - chance, gameMultiplier)  // frame-rate correction
chance *= 100.0
success = Rand.Next(10000) / 100.0 < chance
```

## 12. Target Priority System
Source: `zombie.characters.IsoZombie.spottedNew()`, `zombie.ai.GameCharacterAIBrain`

### Current Target Distance Comparison
Before processing a new target, zombies compare distances:
```java
if (target != other && target != null) {
    distOther = DistanceManhatten(self, other)
    distCurrent = DistanceManhatten(self, currentTarget)
    if (distOther > distCurrent) return;  // ignore farther target
}
```
New targets are only considered if they are closer than the current target (Manhattan distance).

### Lunge Distance Threshold
When target is within range and on same Z-level:
- Standard: 3.5 tiles
- Target in vehicle: 4.0 tiles
- Must pass `lineClearCollide` test (no obstacles between zombie and target)

If within lunge range, zombie transitions directly to LungeState.

### Forced Spotting
`bForced = true` sets `chance = 1000000.0` (guaranteed spot). Triggered by:
- `bonusSpotTime > 0.0` (set to 720.0 ticks = ~24 seconds on first successful spot)
- Internal force-spot calls

### Recently Spotted Target
If `spottedLast == other && timeSinceSeenFlesh < 120.0`: previous spottedNew had an empty block (no additional processing needed, zombie already tracking). The old spotted logic (`spottedOld`) sets `chance = 1000.0` (near-guaranteed re-spot).

### getClosestChasingZombie Priority
`GameCharacterAIBrain.getClosestChasingZombie(recurse)`:
1. Scan own `chasingZombies` list - skip line-blocked, thumping, non-targeting
2. If recurse and none found: check group members' chasers
3. If recurse and still none: check spotted characters' chasers
4. Distance cap: 30 tiles max
5. Downed zombie penalty: +2.0 to distance (deprioritized)
6. Returns closest valid threat

### Target Types
Zombies primarily target `IsoGameCharacter` instances. The spotted() method rejects:
- Dead characters
- Ghost-mode players
- Disconnected network players
- Reanimated-for-grapple-only zombies
- Characters on smoke squares

Zombies attack structures (doors, windows, barricades) via ThumpState when a character target is behind them, not as a primary target selection.

## 13. Aggro Persistence
Source: `zombie.characters.IsoZombie` - `Aggro` inner class, `memory` field

### Memory Duration (sandbox-driven)
The `memory` field controls how many ticks a zombie remembers its target after losing sight:

| Sandbox memory value | Meaning | Ticks | Approx. real time |
|-|-|-|-|
| 1 | Long | 1250 | ~42 seconds |
| 2 (default) | Normal | 800 | ~27 seconds |
| 3 | Short | 500 | ~17 seconds |
| 4 | None | 25 | ~0.8 seconds |
| 5 | Random (all) | Rand(0-3) maps to 1250/800/500/25 | varies |
| 6 | Random (Normal-None) | Rand(1-3) maps to 800/500/25 | varies |

Target is cleared when `timeSinceSeenFlesh > memory`. The `timeSinceSeenFlesh` counter increments by `GameTime.getMultiplier()` each tick.

### timeSinceSeenFlesh Lifecycle
- Reset to 0.0 on successful `spotted()` call (target seen)
- Increments each tick: `timeSinceSeenFlesh += GameTime.getMultiplier()`
- `isTargetLocationKnown()` returns true when `timeSinceSeenFlesh < 1.0` or `bonusSpotTime > 0.0`
- At `> 240.0`: zombie starts responding to sounds instead
- At `> 2000.0` AND `timeSinceRespondToSound > 2000.0`: joins group wandering
- Saved/loaded in zombie serialization

### bonusSpotTime
Set to 720.0 on successful first spot (non-forced). Decrements by `GameTime.getMultiplier()` each tick. While > 0.0:
- `spotted()` is called each tick with `bForced = true`
- `isTargetLocationKnown()` returns true
- Effectively provides ~24 seconds of guaranteed tracking after first detection

### targetSeenTime
Tracks continuous seconds the zombie has been looking at its target:
- Reset to 0.0 when target changes
- Incremented by `getRealworldSecondsSinceLastUpdate()` while target is visible
- Reset to 0.0 when `canSeeTarget` becomes false
- Used as animation variable `targetSeenTime` for lunge/attack timing

### Aggro List System (MP)
`IsoZombie.aggroList` - array of 4 `Aggro` entries for multi-target tracking (primarily used on servers).

**Aggro decay formula:**
```java
dt = currentTimeMillis - lastDamage
aggro = clamp((10000.0 - dt) / 5000.0, 0.0, 1.0)
aggro = clamp(aggro * damage * 0.5, 0.0, 1.0)
```
- Aggro decays from full to zero over ~10 seconds after last damage
- Damage accumulates via `addDamage()`
- Entries removed when `getAggro() <= 0.0`

### isLeadAggro Logic
`isLeadAggro(other)` determines if `other` is the highest-aggro target:
- Scans all 4 entries for highest aggro value
- Returns true if `other == lead && leadAggro == 1.0`
- If two entries both have aggro >= 1.0: returns false (ambiguous, no clear leader)

### Last Target Seen Position
When a zombie spots a target, it records the tile position:
- `lastTargetSeenX/Y/Z = PZMath.fastfloor(other.getX/Y/Z())`
- Used by ThumpState to path toward last known position when target escapes
- Used by LungeState to continue movement when target is lost
- Checked via `isTargetLocationKnown()` which requires `timeSinceSeenFlesh < 1.0`

## 14. Multi-Player Target Selection
Source: `zombie.characters.IsoZombie.spottedNew()`, `spottedOld()`

### Selection Mechanism
PZ does not have a dedicated multi-player target selection algorithm. Instead, the `spotted()` method is called for each visible player, and the zombie locks onto targets through the standard spotting system.

### spottedNew vs spottedOld
Controlled by `SandboxOptions.lore.spottedLogic` (default: true = spottedNew):

**spottedNew** (default, B42+):
- Uses `updateVisionRadius()` for distance cutoff (10-20 tiles based on conditions)
- Angular FOV with graduated multipliers (see section 11)
- More granular distance-based detection with triple `distAlpha` falloff
- Movement modifiers: stationary x0.5, sneaking x0.4, aiming x0.75, moving x2.4
- Torch light: x3.0
- Inconspicuous: x0.5, Conspicuous: x2.0
- Shelter detection checks adjacent walls/furniture for cover

**spottedOld** (legacy):
- Uses `GameTime.getViewDist()` for distance cutoff
- Same angular FOV system
- Simpler movement modifiers: 0.8/1.0/1.5/2.0
- Inconspicuous: x0.8, Conspicuous: x1.2
- No torch bonus, simpler shelter check

### Distance-Based Switching
Both methods prevent switching to a farther target:
```java
if (target != other && target != null) {
    if (DistanceManhatten(self, other) > DistanceManhatten(self, currentTarget))
        return;  // keep current closer target
}
```

### Last Stand Mode
In Last Stand: idle zombies with `timeSinceSeenFlesh > 120.0` randomly (1/36000 chance per tick) path to the nearest living player regardless of distance or LOS.

### Network MP Gating
`NetworkZombieManager.canSpotted(zombie)` gates spotting on client/server. If false and `other != current target`: spotting is blocked. Prevents desynced target assignments.

### Sneak XP Award
When a zombie fails to spot a sneaking player (`!success`):
- If chance was > 20%: `player.couldBeSeenThisFrame = true` (close call)
- XP award: `Rand(1100 * invMultiplier) == 0` chance for Sneak and Lightfoot XP
- Server: `GameServer.addXp()`, client single-player: `player.getXp().AddXP()`
