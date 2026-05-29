# Damage Systems - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22
Cross-ref: combat.md, health-body.md, ai-pathfinding.md, vehicles-system.md, building-construction.md, iso-objects.md

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Zombie -> Player damage pipeline | 15-184 |
| 2 | Player -> Zombie damage pipeline | 185-331 |
| 3 | Zombie -> Structure (thump damage) | 332-450 |
| 4 | Vehicle -> Zombie (run-over) | 451-540 |
| 5 | Zombie -> Vehicle (attack) | 541-583 |
| 6 | Targeting and aggro system | 584-688 |

## 1. Zombie -> Player Damage Pipeline

### Entry Point
`AttackState.animEvent()` calls `targetChar.getBodyDamage().AddRandomDamageFromZombie(zombie, hitReaction)`.
Also called from `AttackVehicleState.animEvent()` when zombie reaches player in vehicle (hitReaction = null, defaults to "Bite").

**Source:** `zombie.characters.BodyDamage.BodyDamage.AddRandomDamageFromZombie()`

### Step 1: Base Chances
```
baseChance     = 15 + player.getMeleeCombatMod()   // chance to AVOID damage
baseBiteChance = 85                                 // chance scratch stays scratch (not bite)
baseLacerationChance = 65                           // chance scratch stays scratch (not laceration)
```
Higher baseChance = more likely to block. Higher baseBiteChance = less likely to escalate to bite.

### Step 2: Multi-zombie Penalty
```
zombiesAttacking = max(player.getSurroundingAttackingZombies(), 1)
baseChance         -= (zombiesAttacking - 1) * 10
baseBiteChance     -= (zombiesAttacking - 1) * 30
baseLacerationChance -= (zombiesAttacking - 1) * 15
```
Each additional zombie beyond the first drastically increases bite and laceration chances.

### Step 3: Drag-Down Check
```
neededZedToDragDown:
  Superhuman strength (sandbox 1) = 2 zombies
  Normal strength (sandbox 2)     = 3 zombies (default)
  Weak strength (sandbox 3)       = 6 zombies

if (dragDownZeds >= neededZedToDragDown && sandbox.zombiesDragDown == true):
  baseBiteChance = 0, baseLacerationChance = 0, baseChance = 0
  hitReaction = "EndDeath" (death spiral - guaranteed lethal)
```

### Step 4: Trait Modifiers
```
Thick Skinned: baseChance *= 1.3 (30% more likely to block)
Thin Skinned:  baseChance /= 1.3 (30% less likely to block)
```

### Step 5: Direction Modifiers
Attack direction determined by `testDotSide(zombie)`: front, behind, left, right.

| Direction | baseChance | baseBiteChance | baseLacerationChance |
|-|-|-|-|
| Front | +0 | +0 | +0 |
| Behind | -15 | -25 | -35 |
| Left/Right | -30 | -7 | -27 |

**Rear Vulnerability sandbox override:**
| Setting | Behind restore | Left/Right restore |
|-|-|-|
| Low (1) | +15/+25/+35 (full) | +30/+7/+27 (full) |
| Medium (2) | +7/+17/+23 (partial) | +15/+4/+15 (partial) |
| High (3, default) | +0/+0/+0 (no change) | +0/+0/+0 (no change) |

Behind + 3+ zombies: additional -15 bite, -15 laceration.

### Step 6: Body Part Selection

**Standing zombie** (not crawling):
```
partIndex = Rand.Next(10) == 0
  ? Rand(Hand_L..Groin)     // 10% chance: upper body + groin
  : Rand(Hand_L..Neck)      // 90% chance: upper body only
```

**Neck targeting:**
```
neckChance = 10.0 * zombiesAttacking
if (behind): neckChance += 5.0
if (leftOrRight): neckChance += 2.0
if (behind && Rand(100) < neckChance): partIndex = Neck
```

**Head/Neck reassignment** (only if head/neck was randomly selected):
```
Head/Neck redirect chance:
  Front:      30% keep (70% chance to redirect)
  Behind:     10% keep (90% chance to redirect)
  Left/Right: 20% keep (80% chance to redirect)
Redirect: random part from Hand_L..Torso_Lower (excluding Head, Neck, Groin)
```

**Crawling zombie:** 50% chance to attack lower body, 50% chance to miss entirely.
```
if (Rand(2) == 0):
  Rand(10) == 0 ? Rand(Groin..MAX) : Rand(UpperLeg_L..MAX)
else:
  return false  // attack misses
```

### Step 7: Attack Type Cascade
Attack type is determined by cascading checks against the (modified) chances.
```
if (Rand(100) > baseChance):         // failed to block
  zombie.scratch = true               // default: scratch
  if (Rand(100) > baseLacerationChance):
    zombie.scratch = false
    zombie.laceration = true           // upgrade to laceration
  if (Rand(100) > baseBiteChance && !zombie.cantBite()):
    zombie.scratch = false
    zombie.laceration = false          // upgrade to bite
```
Result: scratch, laceration, or bite. Each checked against clothing defense.

### Step 8: Clothing Defense Check
```
scratch/laceration: defense = getBodyPartClothingDefense(part, isBite=false, isBullet=false)
bite:               defense = getBodyPartClothingDefense(part, isBite=true,  isBullet=false)

if (Rand(100) < defense):  // clothing blocked the attack
  addHoleFromZombieAttacks()  // still damages clothing
  return false                // NO wound applied
```
Each clothing item on a body part contributes its scratch/bite defense value. Defense is a percentage chance to fully block.

### Step 9: Damage Application
```
damage = Rand(1000) / 1000.0 * Rand(10, 20)    // range: ~0.01 to ~19.0 HP
```
Then applied to body part via `AddDamage(partIndex, damage)`.

**Wound effects by type:**

| Type | Sets | Pain (base * partMod) | Infection |
|-|-|-|-|
| Scratch | SetScratched(true) | 18.0 * painMod | 25% chance (sandbox transmission != 4) |
| Laceration | SetCut(true) | 18.0 * painMod | 25% chance (sandbox transmission != 4) |
| Bite | SetBitten(true) | 25.0 * painMod | 100% (sandbox transmission != 4) |
| Blocked (no wound) | none | 14.0 * painMod | None |

### Step 10: Infection Progression
**From BodyPart.SetBitten():**
- Bite always sets `isInfected = true` (unless transmission == 4, no infection)
- Generates bleeding, sets `biteTime = Rand(50, 80)` (Fast Healer: 30-50, Slow Healer: 80-150)
- If mortality == 7 (never): converts to `isFakeInfected` instead

**Mortality duration** (`pickMortalityDuration()`):
| Sandbox Setting | Duration (hours) | Trait modifier |
|-|-|-|
| 1 - Instant | 0.0 | none |
| 2 - 0-30 seconds | Rand(0, 30) / 3600 * del | del |
| 3 - 0-1 minutes | Rand(0.5, 1.0) / 60 * del | del |
| 4 - 3-12 hours | Rand(3, 12) * del | del |
| 5 - 2-3 days | Rand(2, 3) * 24 * del | del |
| 6 - 1-2 weeks | Rand(1, 2) * 168 * del | del |
| 7 - Never | -1.0 (disabled) | none |

`del`: Resilient = 1.25, Prone to Illness = 0.75, default = 1.0

**Infection health reduction:**
```
percentMortality = min((worldHours - infectionTime) / mortalityDuration, 1.0)
if (percentMortality == 1.0): ReduceGeneralHealth(110)  // instant death
else:
  healthCap = (1.0 - percentMortality^4) * 100
  if (currentHealth > healthCap): ReduceGeneralHealth(excess)
```
The quartic curve means health stays high until the final phase, then drops rapidly.

### Spiked Armor Counter-Damage
If the body part has spiked clothing on the correct side:
- 50% chance per attack: zombie takes damage to Hand_L or Hand_R
- Bite blocked by spikes: zombie takes Head damage + is killed
- Calls `zombie.spikePart(part)` to deal damage to the zombie

## 2. Player -> Zombie Damage Pipeline

### Melee Hit Chain

**Entry:** `CombatManager.attackCollisionCheck()` -> target list -> per-target processing.

### Step 1: Base Damage Roll
```java
damage = Rand.Next(weapon.minDamage, weapon.maxDamage)
if (!weapon.isRanged()):
  damage *= weapon.getDamageMod(owner) * owner.getHittingMod()
```

### Step 2: One-Handed Penalty (2H weapon in 1H)
```
if (twoHandWeapon && !isItemInBothHands):
  damage -= minDamage    // loses base damage floor
```

### Step 3: Arm Pain Reduction (melee only)
```
armsPain = sum of pain for Hand_L through UpperArm_R
if (armsPain > 10):
  damage /= clamp(armsPain / 10, 1.0, 30.0)
```

### Step 4: Trait Modifier
```
damage *= owner.traitDamageDealtReductionModifier
```

### Step 5: Multi-Target Split
```
damageSplit = damage / (splitIndex * 0.5)  // each successive target gets less
```

### Step 6: Range Falloff (melee)
```
rangeDel = dist / (maxRange * 2.0)
rangeDel = max(rangeDel, 0.3)    // minimum 30% damage
rangeDel = min(rangeDel, 1.0)    // cap at 100%
```

### Step 7: processHitDamage() Modifiers
Applied by `IsoGameCharacter.processHitDamage()`:

```java
damage *= modDelta                    // frame time adjustment
hitForce = damage * shovingMod
if (STRONG trait && melee): hitForce *= 1.4
if (WEAK trait && melee):   hitForce *= 0.6

// Endurance-based knockback reduction
endurance = stats.get(ENDURANCE) * knockbackAttackMod
if (endurance < 0.5):
  endurance = max(endurance * 1.3, 0.4)
  hitForce *= endurance

if (player && !ignoreDamage): hitForce *= 2.0

// Behind bonus (non-shove, non-ignore)
oPos = target - wielder
if (dot(oPos, forwardDir) > -0.3): damage *= 1.5
```

### Step 8: CombatManager Modifiers (applied in processHitDamage)
```
damage *= playerReceivedDamageModifier (0.4 for player targets, 1.5 for zombies)
damage *= (BASE_WEAPON_DAMAGE_MULTIPLIER + weaponLevel * WEAPON_LEVEL_DAMAGE_MULTIPLIER_INCREMENT)
       = (0.3 + level * 0.1)  // level 0 = 0.3x, level 10 = 1.3x
```

### Step 9: Floor Attack / Critical Multiplier
```
if (aimAtFloor && !isShove && !isRanged):
  damage *= max(5.0, weapon.criticalDamageMultiplier)   // stomp/floor bonus

if (criticalHit && !ignoreDamage):
  damage *= max(2.0, weapon.criticalDamageMultiplier)
```

### Step 10: One-Handed Damage Penalty
```
if (twoHandWeapon && !bothHands):
  damage *= DAMAGE_PENALTY_ONE_HANDED_TWO_HANDED_WEAPON_MULTIPLIER (0.5)
```

### Step 11: hitConsequences() - Final Application
```
damage *= GLOBAL_MELEE_DAMAGE_REDUCTION_MULTIPLIER (0.15)
CombatManager.applyDamage(target, damage)  // reduces target.health
```

### Full Formula Summary (melee, non-stomp, non-crit)
```
finalDamage = Rand(minDmg, maxDmg)
  * damageMod * hittingMod
  * traitMod
  / multiTargetSplit
  * modDelta
  * behindBonus (1.5 if behind)
  * receivedDamageMod (1.5 for zombies)
  * (0.3 + weaponLevel * 0.1)
  * oneHandedPenalty (0.5 if applicable)
  * GLOBAL_MELEE_DAMAGE_REDUCTION_MULTIPLIER (0.15)
  / painReduction (if armsPain > 10)
```

### Zombie Clothing Defense
```java
totalDefense = scratchDefense(part) * 0.5 + biteDefense(part)
totalDefense *= sandboxZombiesArmorFactor
totalDefense = min(totalDefense, zombiesMaxDefense)  // cap: 100
finalDamage *= abs(1.0 - totalDefense / 100)
```

### Knockback and Knockdown
- `hitForce` determines knockback distance via physics
- Knockdown checks: zombie `unbalancedLevel` threshold (cumulative from hits)
- Endurance < 0.5 reduces knockback output
- STRONG trait: 1.4x knockback, WEAK: 0.6x

### Stomp / Jaw Stab Finishers
**Stomp** (aimAtFloor + shove):
```
damageSplit = Rand(0.7, 1.0) + Strength_level * 0.2
if (no shoes): damageSplit *= 0.5
else: damageSplit *= shoes.stompPower
```
Uses leg pain instead of arm pain for reduction.

**Jaw stab** (knife + single zombie + within minRange):
- `closeKill = true`, `rangeDel *= 1000` (guaranteed lethal)
- `knockbackAttackMod = 0` (no knockback)
- Knife stuck chance: `Rand(8 + (knifeLvl+1)*2)` - higher skill = less chance

### Push (Shove) Mechanics
- `bIgnoreDamage = true` for shoves (knockback only, 0 HP damage)
- Exception: shove + aimAtFloor = stomp (does damage)
- Shove hit force halved: `hitForce = damage / 2.7 * shovingMod`

### Ranged Damage
Base damage: `Rand(minDamage, maxDamage)` (no damageMod applied for ranged).
**Piercing reduction:** if bullet passes through a prior target, `min/maxDamage /= 5.0`.
**Hit chance:** `Rand(100) <= hitInfo.chance` (see combat.md section 5 for full formula).
**Headshot:** random bone collision check for head vs body; head hits apply 3x damage split.

## 3. Zombie -> Structure (Thump Damage)

### Thump System Overview
Zombie enters `ThumpState`, calls `target.Thump(zombie)` each thump animation frame.
Target priority: barricades first (via `getThumpableFor()`), then the object itself.

### Smart Zombie Door Opening (cognition == 1)
```java
// IsoThumpable doors:
if (zombie.cognition == 1 && isDoor() && !isOpen() && !isLocked()):
  ToggleDoor(zombie)  // opens instead of thumping

// IsoDoor:
if (zombie.cognition == 1 && !open && !(locked && exterior)):
  ToggleDoor(zombie)

// IsoWindow:
if (zombie.cognition == 1 && !canClimbThrough && !invincible && !(locked && exterior)):
  ToggleWindow(zombie)
```
Cognition sandbox setting: 1 = Navigate + Use Doors, 4 = random % based on `doorOpeningPercentage`.

### Zombie Strength (thump power)
| Sandbox Setting | Value | strength |
|-|-|-|
| 1 - Superhuman | 5 | 5 damage per thump |
| 2 - Normal | 3 | 3 damage per thump |
| 3 - Weak | 1 | 1 damage per thump |
| 4 - Random | Rand(1, 5) | 1-4 damage per thump |

### IsoThumpable (player-built walls, doors, fences)
```java
// default health: 500, configurable via setMaxHealth()
totalThumpers = thumper.getSurroundingThumpers()
if (totalThumpers >= thumpDmg):
  amount = 1 * fastForwardMultiplier
  health -= amount
else:
  partialThumpDmg += totalThumpers / thumpDmg * fastForwardMultiplier
  if ((int)partialThumpDmg > 0):
    health -= (int)partialThumpDmg
    partialThumpDmg -= (int)amount  // carry fractional damage
```
`thumpDmg` acts as a threshold - fewer zombies than this deal fractional damage.

### IsoDoor (map doors)
```java
tot = thumper.getSurroundingThumpers()
mult = fastForwardMultiplier
if (tot >= 2):
  Damage(zombie.strength * mult)
  if (sandbox.strength == Superhuman):
    Damage(tot * 2 * mult)       // extra bonus for superhuman
```
Doors require at least 2 zombies thumping to take full damage. Single zombie makes no progress.

### IsoWindow
```java
mult = fastForwardMultiplier
damage(zombie.strength * mult)   // directly applied, no threshold
health -= (int)amount             // integer health reduction
if (health == 0): smashWindow()
```
Windows are simpler - each thump directly reduces health by zombie strength.

### IsoBarricade
**Damage priority cascade:** metal sheet > metal bars > planks (from innermost to outermost).

```java
Damage(zombie.strength * fastForwardMultiplier)
```

**IsoBarricade.Damage() cascade:**
```java
if (metalHealth > 0):           // metal sheet (max 5000)
  metalHealth -= amount
  if (metalHealth <= 0): metalHealth = 0, chooseSprite()
  return
if (metalBarHealth > 0):        // metal bars (max 3000)
  metalBarHealth -= amount
  if (metalBarHealth <= 0): metalBarHealth = 0, chooseSprite()
  return
// planks (each plank: max 1000, up to 4 planks)
for each plank (lowest index first):
  plankHealth[i] -= amount
  if (plankHealth[i] <= 0): plankHealth[i] = 0
  break  // only damage one plank per thump
```

**Barricade health values:**
| Type | Health per unit | Max units | Total HP |
|-|-|-|-|
| Metal sheet | 5000 | 1 | 5000 |
| Metal bars | 3000 | 1 | 3000 |
| Plank | condition/condMax * 1000 | 4 | 4000 max |

Plank health scaled by item condition: `(plank.condition / plank.conditionMax) * 1000`.
Player carpentry skill bonus: `plankHealth *= barricadeStrengthMod`.

### Barricade from Player Weapon
```java
if (weapon != null):
  Damage(weapon.getDoorDamage() * 5.0)
else:
  Damage(100.0)  // bare hands
```

### Fast-Forward Damage Multiplier
`ThumpState.getFastForwardDamageMultiplier()`:
```java
if (allPlayersAsleep):
  return (int)(200.0 * (30.0 / lockFPS) / 1.6)   // ~3750 at 60fps
if (server && fastForward):
  return (int)(fastForwardMultiplier / deltaMinutesPerDay)
else:
  return (int)trueMultiplier   // game speed (1x/2x/3x)
```
This means sleeping accelerates structure damage enormously.

## 4. Vehicle -> Zombie (Run-Over)

### Collision Detection
`BaseVehicle.hitCharacter(IsoGameCharacter chr, Vector2 impactPos, boolean pushedBack)`

**Minimum thresholds:**
- Position check: `abs(chr.x - vehicle.x) < 0.01` = skip (overlapping)
- Speed cap: `min(velocity.length(), 15.0)`
- Minimum speed: `< 0.05` = no hit

### Damage to Zombie (calculateDamageFromVehicleImpact)

**Standing zombie:**
```
impactSpeedNoDamage  = 3.0    // below this = 0 damage
impactSpeedMaxDamage = 20.0
maxDamage            = 1.5    // zombie health is ~1.8-2.1
alpha = (impactSpeed - 3.0) / 17.0
damage = 1.5 * EaseOutQuad(alpha)
```

**Prone zombie (run-over):**
```
impactSpeedNoDamage  = 0.2
impactSpeedMaxDamage = 10.0
maxDamage            = 0.5
alpha = (impactSpeed - 0.2) / 9.8
damage = 0.5 * EaseOutQuad(alpha)
```
EaseOutQuad curve means damage increases rapidly at low speeds, then plateaus.

### Sequential Hit Modifiers
```java
isFirstImpact = !vehicle.isPersistentContact(chr)
if (!isFirstImpact):
  if (isBeingPushed):  damage *= 0.01 * gameTimeMultiplier  // pushed along
  if (isBeingCrushed): damage *= 0.2 * gameTimeMultiplier   // prone + not first hit
```

### Vehicle Knockdown
`postHitByVehicleUpdateStance(speed, knockDownAllowed)`:
```
minSpeedToPossibleKnockdown = 3.5
maxSpeedToPossibleKnockdown = 14.5
knockDownAlpha = (speed - 3.5) / 11.0
knockDownChance = EaseInQuad(knockDownAlpha) * 100
shouldKnockDown = (alpha > 1.0) || (Rand(100) <= knockDownChance)
```
At speed >= 14.5: guaranteed knockdown. At 3.5: ~0% chance.

### Damage to Vehicle (from hitting pedestrians)
```java
// BaseVehicle.calculateDamageWithCharacter():
minSpeedToDamage = 5.0 km/h
speedAtMaxDamage = 160.0 km/h
dmgMultiplier    = 60.0

if (speed < 5.0 km/h): return 0
alpha = (speed - 5.0) / 155.0
alpha = clamp(alpha, 0.0, 1.0)
vehicleDmg = 60 * EaseOutQuad(alpha)    // 0-60 range

// Animal collision: dmgMultiplier *= min(animal.weight / 50, 1.5)
```

Vehicle damage applied directionally: `addDamageFrontHitAChr(dmg)` or `addDamageRearHitAChr(dmg)` based on `isCharacterInFront()`.

### Player Hit by Car
`IsoPlayer.getDamageFromHitByACar(vehicleSpeed)`:
```
modifier = sandbox.damageToPlayerFromHitByACar:
  1 = 0.0 (none), 2 = 0.5, 3 = 1.0 (default), 4 = 2.0, 5 = 5.0

damage = vehicleSpeed * modifier
bodyPartsHit = (int)(2.0 + damage * 0.07)

per body part:
  realDamage = max(Rand(damage - 15, damage), 5.0)
  if (FAST_HEALER): realDamage *= 0.8
  if (SLOW_HEALER): realDamage *= 1.2
  injurySeverity: Low = *0.5, Normal = *1.0, High = *1.5
  realDamage *= 0.9  // final 10% reduction

  part.AddDamage(realDamage)
  if (realDamage > 40 && Rand(12) == 0): generateDeepWound()
  if (realDamage > 10 && Rand(100) <= 10 && boneFracture): generateFracture()
  if (realDamage > 30 && Rand(100) <= 80 && boneFracture && isHead): generateFracture()
  if (realDamage > 10 && Rand(100) <= 60 && boneFracture && isLeg): generateFracture()
```

## 5. Zombie -> Vehicle (Attack)

### AttackVehicleState
**Source:** `zombie.vehicles.AttackVehicleState`

Zombie approaches vehicle containing a player target. Two separate event handlers on animation frame:

### AttackCollisionCheck Event (damage to player inside)
```java
target.getBodyDamage().AddRandomDamageFromZombie(zombie, null)
```
Uses the same pipeline as section 1 (zombie -> player). Attacks through vehicle to damage occupant directly. This occurs when the zombie has breached windows/doors.

### ThumpFrame Event (damage to vehicle parts)

**Target selection priority:**
1. Check if zombie is in passenger door area
2. If yes: target passenger door -> find its window
3. If no: find nearest bodywork part -> find its window
4. Windows are prioritized over solid parts

**Window damage:**
```java
window.damage(zombie.strength)    // direct strength-based damage
vehicle.setBloodIntensity(part, current + 0.025)  // accumulate blood
```

**Part condition damage (no window available):**
```java
if (part.getWindow() == null && part.getCondition() > 0):
  part.setCondition(part.getCondition() - zombie.strength)
  part.doInventoryItemStats(item, 0)   // recalculate item stats
```

### Which Parts Zombies Target
- **Passenger doors** when zombie is in the door's area
- **Windows** on doors or nearest bodywork parts (preferred over solid parts)
- **Bodywork panels** when no windows are available
- Zombies pick `chooseBestAttackPosition()` to path to the optimal side

### Vehicle Parts Under Attack
Zombie only damages the part they are positioned next to. They cannot damage engine, tires, or internal parts directly. Damage is per-thump with `zombie.strength` as the base value.

## 6. Targeting and Aggro System

### Zombie Vision
**Source:** `IsoZombie.updateVisionRadius()`, `IsoZombie.getVisionRadiusAdjusted()`

**Base vision radius:** 20 tiles
```java
visionRadius = 20.0 - max(darknessPenalty, rainPenalty + fogPenalty)

darknessPenalty = (1.0 - lightLevel) * 5.0     // 0-5 tiles
rainPenalty     = rainIntensity * 2.5           // 0-2.5 tiles
fogPenalty      = fogIntensity * 7.0            // 0-7 tiles

// Sandbox sight modifiers:
Eagle-eyed (1): visionRadius *= 1.75
Normal (2):     no change
Poor (3):       visionRadius *= 0.35

// Clamped to 10-20 tiles after all modifiers
visionRadius = clamp(visionRadius, 10.0, 20.0)

// Additional modifiers:
if (eating): visionRadius *= 0.5
visionRadius /= wornItemsVisionModifier   // helmet/mask penalty to zombie
```

### Sandbox Sight Settings
| Value | Name | Multiplier |
|-|-|-|
| 1 | Eagle | 1.75x |
| 2 | Normal | 1.0x |
| 3 | Poor | 0.35x |
| 4 | Random (all) | Rand(1,3) per zombie |
| 5 | Random (Normal/Eagle) | Rand(2,3) per zombie |

### Zombie Hearing
**Source:** `IsoZombie.respondToSound()`

When LOS to sound source is blocked, hearing offset is applied:
```java
offsetHearing = 2                          // base inaccuracy
if (rainIntensity > 0.5): offsetHearing = 5
if (sandbox.hearing == 1): offsetHearing -= 2  // Pinpoint
if (sandbox.hearing == 3): offsetHearing += 2  // Poor
offsetHearing = clamp(offsetHearing, 2, 10)

heardX = soundX + Rand(-offset, offset)
heardY = soundY + Rand(-offset, offset)
```
If LOS is clear: zombie paths directly to exact sound location.
Cooldown: `timeSinceRespondToSound` must be > 60 before responding again.
Repath delay: 120 ticks after responding to sound.

### Sandbox Hearing Settings
| Value | Name | Offset Modifier |
|-|-|-|
| 1 | Pinpoint | -2 tiles |
| 2 | Normal | +0 |
| 3 | Poor | +2 tiles |
| 4 | Random (all) | Rand(1,3) per zombie |
| 5 | Random (Normal/Pinpoint) | Rand(2,3) per zombie |

### Spotting Chance Modifiers

**Standing target (in line of sight):**

| Factor | Modifier | Note |
|-|-|-|
| Eagle-eyed sight (1) | chance *= 2.5 | Per-zombie stat |
| Poor sight (3) | chance *= 0.45 | Per-zombie stat |
| Inactive zombie | chance *= 0.25 | Lying down / fake dead |
| Inconspicuous trait | chance *= 0.8 | Player trait |
| Conspicuous trait | chance *= 1.2 | Player trait |
| bonusSpotTime > 0 | chance *= 5.0 | Recently alerted |
| Sneaking behind cover | chance *= shelterMod | Obstacle-based reduction |

**Already-seen target persistence:**
```
if (spottedLast == target && timeSinceSeenFlesh < 120):
  // maintains current target (no re-spot needed)
```

### Target Priority
- Zombies compare Manhattan distance: `distOther > distCurrent` = ignore new target
- Closer targets always take priority over farther ones
- `timeSinceSeenFlesh` timer: resets on seeing any player, decays over time
- Force-spotted targets (sounds, events) bypass distance check

### Zombie Memory
| Sandbox Setting | Value (ticks) | Approx Duration |
|-|-|-|
| 1 - Long | 1250 | ~21 minutes |
| 2 - Normal | 800 | ~13 minutes |
| 3 - Short | 500 | ~8 minutes |
| 4 - None | 25 | ~0.4 seconds |
| 5 - Random (all) | Rand(0,3) | Per zombie |
| 6 - Random (Short-Long) | Rand(1,3) | Per zombie |

Memory determines how long a zombie pursues a target after losing sight.

### Target Switching
- Zombies won't switch to a farther target unless force-spotted
- `shouldStopThumpingToRespondToSound()`: requires sound radius >= 10, and target not visible in forward direction
- Eating zombies: reduced vision (0.5x) but maintain target if `timeSinceSeenFlesh < 5`
- Vehicle occupants: zombie enters `AttackVehicleState` and stays until target dies or vehicle moves away
