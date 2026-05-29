# Building & Construction System - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture Overview | 25-49 |
| 2 | IsoThumpable Creation | 50-108 |
| 3 | Health Values & Defaults | 109-155 |
| 4 | Barricade Mechanics | 156-228 |
| 5 | Barricade Damage Model | 229-274 |
| 6 | Door Thump/Damage Model | 275-310 |
| 7 | IsoThumpable Thump/Damage Model | 311-361 |
| 8 | Window Damage Model | 362-391 |
| 9 | Construction Properties | 392-425 |
| 10 | BuildAction (Java/Lua bridge) | 426-461 |
| 11 | Sprite Tilesets | 462-505 |
| 12 | Thump Damage Formula (Detail) | 506-561 |
| 13 | Fast-Forward Damage Multiplier | 562-606 |
| 14 | Smart Zombie Door Opening | 607-652 |
| 15 | Repair Mechanics | 653-677 |
| 16 | Reinforcement Mechanics | 678-711 |
| 17 | Window/Fence Specific Damage | 712-779 |

## 1. Architecture Overview

PZ construction is a **hybrid Java/Lua system**. The Java side provides `IsoThumpable` as the
runtime object for all player-built structures. The Lua side (IS build system) drives the UI,
material requirements, and build recipes, then instantiates `IsoThumpable` via constructors
exposed to Kahlua2.

**Class hierarchy for constructable/destructable objects:**
```
GameEntity
  IsoObject (base - implements Thumpable)
    IsoThumpable (player-built: walls, doors, floors, stairs, fences, crates)
    IsoDoor (map-placed doors)
    IsoWindow (map-placed windows)
    IsoBarricade (barricades on doors/windows/thumpables)
    IsoMovingObject
      IsoDeadBody
```

**Key interfaces for construction interaction:**
- `BarricadeAble` - can have IsoBarricade attached (IsoThumpable, IsoDoor, IsoWindow)
- `Thumpable` - can be thumped/hit (all destructable objects)
- `IHasHealth` - has health/maxHealth/setHealth (IsoThumpable, IsoDoor, IsoBarricade)
- `ILockableDoor` - lockable (IsoThumpable, IsoDoor)

## 2. IsoThumpable Creation

### Constructors (called from Lua build system)

**Constructor 1 - Door/window with open sprite:**
```java
IsoThumpable(IsoCell cell, IsoGridSquare sq, String closedSprite,
             String openSprite, boolean north, KahluaTable table)
```
Sets: `pushedStrength=2500`, `pushedMaxStrength=2500`, `outlineOnMouseover=true`

**Constructor 2 - Wall/fence with single sprite:**
```java
IsoThumpable(IsoCell cell, IsoGridSquare sq, String sprite,
             boolean north, KahluaTable table)
```
Same defaults as above.

**Constructor 3 - Minimal (no Lua table):**
```java
IsoThumpable(IsoCell cell, IsoGridSquare sq, String sprite, boolean north)
```

### Post-construction setup (called from Lua)
After construction, Lua code configures the IsoThumpable via setters:

| Setter | Purpose |
|-|-|
| setMaxHealth(int) / setHealth(int) | Set durability |
| setThumpDmg(int) | Zombies needed to damage per tick |
| setIsDoor(boolean) | Marks as openable door |
| setIsDoorFrame(boolean) | Marks as door frame |
| setIsFloor(boolean) | Marks as floor tile |
| setIsStairs(boolean) | Marks as staircase |
| setIsContainer(boolean) | Creates ItemContainer("crate") |
| setCanBarricade(boolean) | Allows barricade attachment |
| setIsDismantable(boolean) | Allows dismantle action |
| setCanBePlastered(boolean) | Allows plastering |
| setPaintable(boolean) | Allows painting |
| setIsThumpable(boolean) | Whether zombies can thump |
| setIsHoppable(boolean) | Whether players can climb over |
| setCrossSpeed(float) | Movement speed modifier |
| setCanPassThrough(boolean) | Allows pass-through |
| setBlockAllTheSquare(boolean) | Blocks entire tile |
| setBreakSound(String) | Sound on destruction |
| setThumpSound(String) | Sound when thumped |
| setClosedSprite(IsoSprite) | Visual when closed |
| setOpenSprite(IsoSprite) | Visual when open |

### Container creation
When `setIsContainer(true)` is called:
```java
this.container = new ItemContainer("crate", this.square, this);
if (sprite.getProperties().has(CONTAINER_CAPACITY)) {
    this.container.capacity = parseInt(sprite.getProperties().get(CONTAINER_CAPACITY));
}
this.container.setExplored(true);
```

## 3. Health Values & Defaults

### IsoThumpable defaults
| Property | Default |
|-|-|
| health | 500 |
| maxHealth | 500 |
| thumpDmg | 8 (zombies needed to deal 1 dmg/tick) |
| pushedStrength | 2500 (set in constructors) |
| pushedMaxStrength | 2500 |
| crossSpeed | 1.0f |
| isThumpable | true |

### IsoDoor defaults
| Property | Default |
|-|-|
| health | 500 |
| maxHealth | 500 |
| type | DoorType.WeakWooden |
| DoorType values | WeakWooden, StrongWooden |

### IsoWindow defaults
| Type | Health | MaxHealth |
|-|-|-|
| SinglePane | 50 | 50 |
| DoublePane | 100 | 100 |

### IsoBarricade health constants
| Barricade Type | Health Per Unit | Max Units |
|-|-|-|
| Wood Plank | 1000 (scales with plank condition) | 4 |
| Metal Bar | 3000 (scales with bar condition) | 1 |
| Sheet Metal | 5000 (scales with sheet condition) | 1 |
| Metal Damaged Threshold | 2500 (switches to damaged sprite) | - |

Health scaling formula for planks:
```java
plankHealth = (int)(plank.getCondition() / plank.getConditionMax() * 1000.0f);
plankHealth = (int)(plankHealth * chr.getBarricadeStrengthMod());
```

For metal/metal bars:
```java
metalHealth = (int)(metal.getCondition() / metal.getConditionMax() * 5000.0f);
metalHealth = (int)(metalHealth * chr.getMetalBarricadeStrengthMod());
```

## 4. Barricade Mechanics

### Adding barricades
Barricades are `IsoBarricade` objects placed on the same or opposite square as a `BarricadeAble` object (door/window/thumpable).

**Mutual exclusion rules:**
- Wood planks: cannot add if metal or metalBar present, max 4 planks
- Metal bar: cannot add if any planks or metal present
- Sheet metal: cannot add if any planks or metal present

```java
// canAddPlank()
return !this.isMetal() && this.getNumPlanks() < 4 && !this.isMetalBar();

// addMetalBar() - checks
if (this.getNumPlanks() > 0) return;
if (this.metalHealth > 0) return;
if (this.metalBarHealth > 0) return;

// addMetal() - checks
if (this.getNumPlanks() > 0) return;
if (this.metalHealth > 0) return;
```

### Static factory: AddBarricadeToObject
```java
// Determines barricade direction from object orientation
public static IsoBarricade AddBarricadeToObject(BarricadeAble to, boolean addOpposite)
```
- If `to.getNorth()`: barricade dir = N (same side) or S (opposite)
- If `!to.getNorth()`: barricade dir = W (same side) or E (opposite)
- Inserts barricade into square's object list before curtains of matching direction

### Character-relative placement
```java
public static IsoBarricade AddBarricadeToObject(BarricadeAble to, IsoGameCharacter chr)
```
- North objects: `addOpposite = chr.getY() < to.getSquare().getY()`
- West objects: `addOpposite = chr.getX() < to.getSquare().getX()`

### Removing barricades
```java
// Planks: returns plank item with scaled condition
InventoryItem removePlank(IsoGameCharacter chr)
// Condition = Math.max(conditionMax * (plankHealth/1000.0f), 1.0f)

// Metal bar: returns MetalBar item
InventoryItem removeMetalBar(IsoGameCharacter chr)

// Sheet metal: returns SheetMetal item
InventoryItem removeMetal(IsoGameCharacter chr)
```
All remove methods: if barricade becomes empty (isDestroyed), removes from square.

### Thump target resolution
When a zombie or player hits a BarricadeAble object, `getThumpableFor(chr)` resolves the actual target:

**IsoDoor/IsoThumpable:**
1. Check `getBarricadeForCharacter(chr)` - barricade on character's side
2. Check `getBarricadeOppositeCharacter(chr)` - barricade on other side
3. If no barricade and not destroyed/open, return self
4. Return null if destroyed/open

**IsoWindow:**
Same pattern but also checks barricade on opposite square.

### Vision blocking
```java
// IsoBarricade.isBlockVision()
return this.isMetal() || this.getNumPlanks() > 2;
```
Metal barricades and 3+ planks block line of sight.

## 5. Barricade Damage Model

### Zombie thump damage (IsoBarricade.Thump)
```java
this.Damage(isoZombie.strength * ThumpState.getFastForwardDamageMultiplier());
```
Direct strength-based damage, no threshold requirement.

### Player weapon damage (IsoBarricade.WeaponHit)
```java
// With weapon
this.Damage(weapon.getDoorDamage() * 5.0f);
// Without weapon (bare hands)
this.Damage(100.0f);
```

### Damage routing (IsoBarricade.Damage)
Damage is applied in priority order:
1. **Sheet metal first**: `metalHealth -= amount` (if metalHealth > 0)
2. **Metal bar second**: `metalBarHealth -= amount` (if metalBarHealth > 0)
3. **Planks last**: damages highest-index plank first (LIFO order)

```java
// Plank damage detail
for (int i = 3; i >= 0; --i) {
    if (plankHealth[i] <= 0) continue;
    plankHealth[i] -= amount;
    if (plankHealth[i] <= 0) plankHealth[i] = 0;
    chooseSprite();  // updates visual
    break;           // only damages one plank per hit
}
```

### Destruction check
```java
// IsoBarricade.isDestroyed()
return metalHealth <= 0 && getNumPlanks() <= 0 && metalBarHealth <= 0;
```

### Bypass rules (IsoBarricade.canAttackBypassIsoBarricade)
```java
if (weapon.isAimedFirearm()) return !this.isBlockVision();
// Otherwise checks weapon.canAttackPierceTransparentWall()
```
Firearms can shoot through non-vision-blocking barricades (< 3 planks, no metal).

## 6. Door Thump/Damage Model

### Smart zombie door opening
```java
// IsoDoor.Thump() - cognition 1 (smart) zombies
if (isoZombie.cognition == 1 && !this.open && !this.locked) {
    this.ToggleDoor(thumper);
    if (this.open) return; // opened successfully, no damage
}
```

### Door thump damage formula
```java
int tot = thumper.getSurroundingThumpers();
int mult = ThumpState.getFastForwardDamageMultiplier();
if (tot >= 2) {
    this.Damage(isoZombie.strength * mult);
    if (SandboxOptions.lore.strength.getValue() == 1) { // Superhuman
        this.Damage(tot * 2 * mult);  // bonus crowd damage
    }
}
// LastStand mode: always +1 damage
```
Doors require **2+ zombies thumping** to take damage (unlike barricades which take damage from 1).

### Door weapon damage
```java
// IsoDoor.WeaponHit()
Thumpable target = getThumpableFor(owner);
// If barricade present, redirects to barricade
// Otherwise delegates to Damage()
```

### Door destruction
On health <= 0: calls `destroy()`, checks `destroyDoubleDoor()` and `destroyGarageDoor()` first. Forces building awake if in building.

## 7. IsoThumpable Thump/Damage Model

### Thump gating by sandbox option
```java
if (!SandboxOptions.lore.thumpOnConstruction.getValue()) return;
```
Player-built structures can be made immune to zombie thumping via sandbox.

### Smart zombie door behavior
Same as IsoDoor: cognition==1 zombies try to open unlocked thumpable doors.

### Thump damage formula (threshold-based)
```java
int totalThumpers = thumper.getSurroundingThumpers();
int max = this.thumpDmg;  // default 8
if (totalThumpers >= max) {
    // Full damage: 1 per tick
    this.setHealth(this.getHealth() - 1 * FastForwardMultiplier);
} else {
    // Partial damage: accumulates fractionally
    this.partialThumpDmg += (totalThumpers / max) * FastForwardMultiplier;
    if ((int)partialThumpDmg > 0) {
        this.setHealth(this.getHealth() - (int)partialThumpDmg);
        this.partialThumpDmg -= (int)partialThumpDmg;
    }
}
```
The `thumpDmg` field acts as a **threshold**: zombies below this count deal fractional damage.

### Weapon damage on IsoThumpable
```java
// IsoThumpable.WeaponHit()
this.Damage(weapon.getDoorDamage());  // NOTE: no 5x multiplier unlike barricades
```
Destruction condition for pushed items:
```java
if (!IsStrengthenedByPushedItems() && health <= 0
    || IsStrengthenedByPushedItems() && health <= -pushedMaxStrength)
```

### IsoThumpable.Damage
```java
public void Damage(float amount) {
    if (!this.isThumpable()) return;
    this.health = (int)(this.health - amount);
}
```

### Breakable fence handling
On destruction, checks `BrokenFences.getInstance().isBreakableObject(this)`. If true, replaces with bent/broken fence sprite instead of removing.

## 8. Window Damage Model

### Window weapon damage
```java
// IsoWindow.WeaponHit()
if (weapon != null) {
    this.damage(weapon.getDoorDamage() * 5.0f, owner);
} else {
    this.damage(100.0f, owner);
}
// Players with any weapon (not bare hands) instantly destroy: health = 0
if (player != null && weapon != owner.bareHands && !this.isInvincible()) {
    this.health = 0;
}
```

### Window smashing
`smashWindow()` sets `destroyed=true`, switches to `smashedSprite`, removes light switch, triggers alarm check, invalidates pathfinding.

### Window invincibility
```java
public boolean isInvincible() {
    return this.getProperties() != null
        && this.getProperties().has(IsoFlagType.makeWindowInvincible);
}
```

### Glass removal
Windows track `glassRemoved` state separately from `destroyed`. Glass-removed windows use `glassRemovedSprite`.

## 9. Construction Properties

### IsoThumpable configuration flags

| Flag | Effect | Relevant For |
|-|-|-|
| isDoor | Object opens/closes, smart zombies try handle | Doors |
| isDoorFrame | Frame around door | Door frames |
| isFloor | Treated as floor tile | Floors |
| isStairs | Treated as staircase | Stairs |
| isCorner | Corner piece | Wall corners |
| isContainer | Has inventory (creates "crate" container) | Crates, shelves |
| canBarricade | Can have IsoBarricade attached | Walls with window |
| isThumpable | Zombies can damage (default true) | All |
| isHoppable | Player can climb over | Low walls, fences |
| canPassThrough | Walk-through even with collide flags | Gates when open |
| blockAllTheSquare | Blocks entire tile | Solid walls |
| dismantable | Can be taken apart | Most built objects |
| canBePlastered | Can apply plaster | Wooden walls |
| paintable | Can apply paint | Plastered walls |

### Light source system
IsoThumpable can host a light source (for campfires, lamps):
```java
createLightSource(int radius, int offX, int offY, int offZ,
                  int life, String fuelType, InventoryItem base, IsoGameCharacter chr)
```
Managed fields: `lightSourceRadius`, `lightSourceLife`, `lightSourceFuel`, `lifeLeft`, `lifeDelta`, `haveFuel`, `lightSourceOn`

### Sheet rope system
Both IsoThumpable (built walls) and IsoWindow support sheet ropes:
- `canAddSheetRope()` / `addSheetRope(IsoPlayer, String itemType)` / `removeSheetRope(IsoPlayer)`
- Uses IsoFlagType: `climbSheetN/W/E/S`, `climbSheetTopN/W/E/S`

## 10. BuildAction (Java/Lua bridge)

Package: `zombie.core`

The `BuildAction` class bridges Java's action system to Lua's IS build definitions.

### Fields
| Type | Name | Purpose |
|-|-|-|
| float | x, y, z | Build position |
| boolean | north | Orientation |
| String | spriteName | Tile sprite |
| KahluaTable | item | Lua build definition table |
| String | objectType | Lua class name (e.g. "ISWoodenWall") |

### Flow
1. Player initiates build from Lua UI
2. `BuildAction.set(player, x, y, z, north, spriteName, item)` packages request
3. `start()` creates argTable with position/sprite/item data
4. `isValid()` calls Lua `item:isValid(square)` for validation
5. `update()` sets player metabolic target to HeavyWork
6. `getDuration()` calculates time: `200 - (Woodwork * 5)`, min from instant actions, -50 for Handy trait
7. `perform()` triggers Lua `OnProcessAction("build", player, argTable)` - Lua creates IsoThumpable

### Duration formula
```java
float maxTime = 200 - player.getPerkLevel(Perks.Woodwork) * 5;
if (item.Type.equals("ISEmptyGraves")) maxTime = 150;
if (player.isTimedActionInstant()) maxTime = 1;
if (player.hasTrait(CharacterTrait.HANDY)) maxTime -= 50;
return maxTime * 20.0f;  // converts to ticks
```

### Network serialization
On multiplayer, `BuildAction` serializes the Lua table's `new()` function parameters and the table type string. Server reconstructs the Lua build object via `LuaManager.get(objectType)` and calls its `new()` function with deserialized args.

## 11. Sprite Tilesets

### Barricade sprites (IsoBarricade.chooseSprite)

**Sheet metal:**
| Direction | Sprite | Damaged (<=2500 HP) |
|-|-|-|
| W | constructedobjects_01_24 | constructedobjects_01_26 |
| N | constructedobjects_01_25 | constructedobjects_01_27 |
| E | constructedobjects_01_28 | constructedobjects_01_30 |
| S | constructedobjects_01_29 | constructedobjects_01_31 |

**Metal bars:**
| Direction | Sprite |
|-|-|
| W | constructedobjects_01_55 |
| N | constructedobjects_01_53 |
| E | constructedobjects_01_52 |
| S | constructedobjects_01_54 |

**Wood planks (carpentry_01 tileset):**
| Direction | Formula |
|-|-|
| W | carpentry_01_{8 + (numPlanks-1)*2} |
| N | carpentry_01_{9 + (numPlanks-1)*2} |
| E | carpentry_01_{0 + (numPlanks-1)*2} |
| S | carpentry_01_{1 + (numPlanks-1)*2} |

So 1 plank W = `carpentry_01_8`, 4 planks N = `carpentry_01_15`, etc.

### Relevant tile properties for construction
| Property | Type | Used By |
|-|-|-|
| OPEN_TILE_OFFSET | int | IsoDoor, IsoWindow - sprite offset for open state |
| SMASHED_TILE_OFFSET | int | IsoWindow - sprite offset for smashed state |
| GLASS_REMOVED_OFFSET | int | IsoWindow - sprite offset for glass removed |
| WINDOW_LOCKED | flag | IsoWindow - permanently locked |
| CONTAINER_CAPACITY | int | IsoThumpable - container size when isContainer |
| collideN / collideW | flag | Collision edges |
| windowN / windowW | flag | Window position flags |
| doorN / doorW | flag | Door position flags |
| HoppableN / HoppableW | flag | Climbable edges |
| makeWindowInvincible | flag | Prevents window destruction |

## 12. Thump Damage Formula (Detail)

### IsoThumpable - threshold-based accumulation
The `thumpDmg` field (default 8) is a zombie count threshold. Damage depends on how many
zombies are thumping simultaneously (from `thumper.getSurroundingThumpers()`).

**When totalThumpers >= thumpDmg (at or above threshold):**
```java
int amount = 1 * ThumpState.getFastForwardDamageMultiplier();
this.setHealth(this.getHealth() - amount);
```
Deals exactly 1 HP per thump tick (times fast-forward multiplier). No zombie strength factor.

**When totalThumpers < thumpDmg (below threshold):**
```java
this.partialThumpDmg += (float)totalThumpers / (float)max * (float)ThumpState.getFastForwardDamageMultiplier();
if ((int)this.partialThumpDmg > 0) {
    int amount = (int)this.partialThumpDmg;
    this.setHealth(this.getHealth() - amount);
    this.partialThumpDmg -= (float)amount;
}
```
Fractional damage accumulates in `partialThumpDmg` (a float). Integer part is subtracted from
health each tick, remainder carries over. Example: 4 zombies vs thumpDmg=8 gives 0.5/tick,
so 1 HP every 2 ticks. The cast to `(int)` truncates (floors), not rounds.

**Key difference from doors/barricades:** IsoThumpable does NOT use zombie strength. Damage is
purely ratio-based. One zombie vs thumpDmg=8 gives 0.125/tick = 1 HP every 8 ticks.

### IsoDoor - strength-based with crowd threshold
Doors require **2+ thumping zombies** to take any damage:
```java
int tot = thumper.getSurroundingThumpers();
if (tot >= 2) {
    this.Damage(isoZombie.strength * mult);
    if (SandboxOptions.instance.lore.strength.getValue() == 1) { // Superhuman
        this.Damage(tot * 2 * mult);  // bonus crowd damage
    }
}
```
- Base damage = `zombie.strength * fastForwardMultiplier`
- Superhuman sandbox adds `totalThumpers * 2 * fastForwardMultiplier` bonus
- LastStand mode always adds 1 damage regardless of thumper count

### IsoBarricade - direct strength, no threshold
```java
this.Damage(isoZombie.strength * ThumpState.getFastForwardDamageMultiplier());
```
A single zombie damages barricades immediately using its strength value.

### IsoWindow - direct strength, no threshold
```java
this.damage(isoZombie.strength * mult, thumper);
```
Same as barricade: single zombie deals `strength * fastForwardMultiplier` per tick.

## 13. Fast-Forward Damage Multiplier

Source: `zombie.ai.states.ThumpState.getFastForwardDamageMultiplier()`

This multiplier scales thump damage during accelerated time:

```java
public static int getFastForwardDamageMultiplier() {
    GameTime gt = GameTime.getInstance();
    if (GameServer.server) {
        return (int)(GameServer.fastForward
            ? ServerOptions.instance.fastForwardMultiplier.getValue() / (double)gt.getDeltaMinutesPerDay()
            : 1);
    }
    if (GameClient.client) {
        return (int)(GameClient.fastForward
            ? ServerOptions.instance.fastForwardMultiplier.getValue() / (double)gt.getDeltaMinutesPerDay()
            : 1);
    }
    if (IsoPlayer.allPlayersAsleep()) {
        return (int)(200.0f * (30.0f / (float)PerformanceSettings.getLockFPS()) / 1.6f);
    }
    return (int)gt.getTrueMultiplier();
}
```

**Sleep formula breakdown:** `(int)(200 * 30 / FPS / 1.6)`

| FPS Lock | Multiplier |
|-|-|
| 30 | 187 |
| 60 | 93 |
| 120 | 46 |
| 144 | 41 |
| Uncapped (240) | 25 |

At 60 FPS, a structure with 500 HP facing enough zombies to do 1 dmg/tick would break in
~5.4 seconds of real sleep time (500/93 ticks). The cast to `(int)` means the result is
truncated, so at high FPS the multiplier can be surprisingly low.

**Multiplayer:** Uses `ServerOptions.fastForwardMultiplier / deltaMinutesPerDay` when
fast-forward is active, otherwise returns 1.

**Normal gameplay:** Returns `gt.getTrueMultiplier()` which is the game speed setting (1x/2x/3x).

## 14. Smart Zombie Door Opening

Zombies with `cognition == 1` (smart/navigator zombies) attempt to open doors before breaking them.

### IsoThumpable (player-built doors)
```java
if (isoZombie.cognition == 1 && this.isDoor() && !this.IsOpen() && !this.isLocked()) {
    this.ToggleDoor((IsoGameCharacter)thumper);
    return;  // opened successfully, no damage dealt
}
```
Smart zombies open unlocked player-built doors without any damage.

### IsoDoor (map doors)
```java
if (!(isoZombie.cognition != 1 || this.open
    || this.locked && (thumper.getCurrentSquare() == null
    || thumper.getCurrentSquare().has(IsoFlagType.exterior)))) {
    this.ToggleDoor((IsoGameCharacter)thumper);
    if (this.open) return;
}
```
Condition (de-Morganed): `cognition == 1 AND !open AND !(locked AND zombie_is_outside)`.
Smart zombies open unlocked doors. Locked doors are opened only if the zombie is **inside**
(not on an exterior tile). If the door is locked and the zombie is outside, it falls through
to normal thumping.

### IsoWindow (map windows)
```java
if (!(isoZombie.cognition != 1 || this.canClimbThrough(isoZombie) || this.isInvincible()
    || this.locked && (thumper.getCurrentSquare() == null
    || thumper.getCurrentSquare().has(IsoFlagType.exterior)))) {
    this.ToggleWindow((IsoGameCharacter)thumper);
    if (this.canClimbThrough(isoZombie)) return;
}
```
Smart zombies open windows if: not already climbable, not invincible, and not locked from
outside. After toggling, if the zombie can climb through, it stops thumping.

### Cognition values
| Value | Meaning | Door Behavior |
|-|-|-|
| 0 | Default | Always thump |
| 1 | Smart/Navigator | Try to open first |
| -1 | Random (legacy) | Always thump |

## 15. Repair Mechanics

Structure repair is handled entirely in **Lua** (ISBuildingObject system), not in Java.
Java only provides the `setHealth(int)` setter that Lua calls after repair validation.

### Java-side API
```java
// IsoThumpable
public void setHealth(int health) { this.health = health; }
public int getHealth() { return this.health; }
public int getMaxHealth() { return this.maxHealth; }
```

### Lua repair flow (ISRepairAction)
1. Player selects damaged structure via context menu
2. Lua checks material requirements (nails, planks, etc.) based on structure type
3. `ISRepairAction:perform()` calculates repair amount from Carpentry perk level
4. Calls `object:setHealth(math.min(object:getHealth() + repairAmount, object:getMaxHealth()))`

### Key constraints
- Health cannot exceed `maxHealth` (capped in Lua)
- Repair materials match original construction recipe (reduced quantity)
- Higher Carpentry skill restores more HP per repair action
- Barricades (`IsoBarricade`) have no Java repair method - must be removed and re-added

## 16. Reinforcement Mechanics

### Pushed furniture reinforcement (IsStrengthenedByPushedItems)

The `IsStrengthenedByPushedItems()` method in IsoThumpable always returns `false`:
```java
public boolean IsStrengthenedByPushedItems() {
    return false;
}
```
This is a **placeholder/override point**. Despite the fields `pushedStrength` and
`pushedMaxStrength` being set to 2500 in constructors, the reinforcement check never
activates for IsoThumpable.

### Effect on destruction (WeaponHit)
The destruction check in `WeaponHit()` has two paths:
```java
if (!this.IsStrengthenedByPushedItems() && this.health <= 0
    || this.IsStrengthenedByPushedItems() && this.health <= -this.pushedMaxStrength)
```
- Without reinforcement (current): destroys at health <= 0
- With reinforcement (if overridden): would require health <= -2500 (needs 2500 extra damage)

### Pushed item strength fields
| Field | Default | Purpose |
|-|-|-|
| pushedStrength | 2500 | Current reinforcement HP (unused) |
| pushedMaxStrength | 2500 | Maximum reinforcement HP (used in destruction threshold) |

The system is wired but disabled - a mod could override `IsStrengthenedByPushedItems()` to
return true and gain 2500 extra effective HP against weapon attacks.

**Note:** Zombie thump (`Thump()`) does NOT check reinforcement. Only `WeaponHit()` does.

## 17. Window/Fence Specific Damage

### Window invincibility
```java
// IsoWindow.isInvincible()
public boolean isInvincible() {
    if (this.square == null || !this.square.has(IsoFlagType.makeWindowInvincible)) {
        return false;
    }
    // Checks that another object on the same square has the matching cut flag
    // AND the makeWindowInvincible flag
    for (IsoObject obj : this.square.getObjects()) {
        if (obj == this) continue;
        if (obj.getProperties().has(this.getNorth() ? IsoFlagType.cutN : IsoFlagType.cutW)
            && obj.getProperties().has(IsoFlagType.makeWindowInvincible))
            return true;
    }
    return false;
}
```
A window is invincible when another object on the same tile (typically a wall) has both
`makeWindowInvincible` and the matching directional cut flag. Used for reinforced/special
map windows that should never break.

**Invincibility blocks:**
- Zombie thumping (checked in `Thump()` for smart zombie opening)
- Player weapon damage (checked in `WeaponHit()` before setting health to 0)
- The `damage()` private method returns early if invincible
- Tutorial mode (`"Tutorial".equals(Core.gameMode)`) also makes all windows invincible

### Window damage model (from Thump)
Windows take `isoZombie.strength * fastForwardMultiplier` per tick with no threshold.
Unlike doors (need 2+ zombies) and IsoThumpable (threshold-based), a single zombie breaks
windows. Health is cast to int and clamped to 0. On reaching 0, `smashWindow()` fires:
- Sets `destroyed = true`
- Swaps sprite to `smashedSprite`
- Invalidates pathfinding
- Adds broken glass to square
- Triggers alarm check (unless zombie-caused with alarm disabled in sandbox)

### Glass removal
Windows track `glassRemoved` separately from `destroyed`. A glass-removed window uses
`glassRemovedSprite` and can be climbed through, but is not "smashed" (no broken glass,
no alarm trigger).

### Fence breaking system
When `BrokenFences.getInstance().isBreakableObject(this)` returns true for an IsoThumpable:
```java
IsoDirections dirBreak = props.has(IsoFlagType.collideN) && props.has(IsoFlagType.collideW)
    ? (thumper.getY() >= this.getY() ? IsoDirections.N : IsoDirections.S)
    : (props.has(IsoFlagType.collideN)
        ? (thumper.getY() >= this.getY() ? IsoDirections.N : IsoDirections.S)
        : (thumper.getX() >= this.getX() ? IsoDirections.W : IsoDirections.E));
BrokenFences.getInstance().destroyFence(this, dirBreak);
```
Breakable fences are replaced with a directional bent/broken sprite instead of being removed.
The break direction is determined by the zombie's position relative to the fence. Crawling
zombies can thump breakable fences and hoppable objects even if `isThumpable` is false.

### Sheet rope system
IsoWindow provides static sheet rope methods used by both windows and IsoThumpable:
- `canAddSheetRope(IsoGridSquare sq, boolean north)` - checks if rope can descend
- `addSheetRope(IsoPlayer, IsoGridSquare, boolean north, String itemType)` - places rope objects
- `removeSheetRope(IsoPlayer, IsoGridSquare, boolean north)` - removes rope objects

Sheet ropes are not health-tracked objects. They are plain `IsoObject` instances with
`sheetRope = true` placed on successive squares downward. The first segment requires 1 nail.
Ropes can only be added to windows/thumpables that `canClimbThrough()` returns true for.
