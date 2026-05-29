# Combat System - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22
Cross-ref: damage-systems.md (complete damage pipelines with formulas), health-body.md, vehicles-system.md

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | CombatManager overview | 25-57 |
| 2 | Damage calculations | 58-111 |
| 3 | Hit detection and targeting | 112-155 |
| 4 | Melee weapon mechanics | 156-213 |
| 5 | Ranged weapon mechanics | 214-267 |
| 6 | Knockback and knockdown | 268-302 |
| 7 | Critical hits | 303-327 |
| 8 | Zombie damage to player | 328-363 |
| 9 | Combat enums | 364-407 |
| 10 | CombatConfigKey defaults | 408-469 |
| 11 | Zombie attack type selection | 470-538 |
| 12 | Vehicle collision damage to zombies | 539-598 |
| 13 | Vehicle damage from hitting characters | 599-620 |
| 14 | Infection chance modifiers | 621-666 |
| 15 | Full melee damage chain summary | 667-707 |
| 16 | processHitDamage modifier stack | 708-758 |

## 1. CombatManager
`zombie.CombatManager` - final singleton. Central combat processing hub.

### Access
```java
CombatManager.getInstance()  // Singleton via Holder pattern
```

### Constants
| Name | Type | Value | Note |
|-|-|-|-|
| StrengthLevelOffset | [pub static] int | 15 | Strength affects muscle strain threshold |
| StrengthLevelMuscleStrainModifier | [pub static] float | 10.0 | Strain per strength level |
| TwoHandedWeaponMuscleStrainModifier | [pub static] float | 0.5 | 2H weapon strain reduction |
| VehicleDamageScaleFactor | [static] float | 50.0 | Vehicle hit damage scale |
| PainThreshold | [static] float | 10.0 | Pain starts reducing damage |
| MinPainFactor / MaxPainFactor | [static] float | 1.0 / 30.0 | Pain clamp range |
| MinDamageSplit / MaxDamageSplit | [static] float | 0.7 / 1.0 | Stomp damage range |
| ZombieMaxDefense | [static] int | 100 | Clothing defense cap |
| AxeVsTreeBonusModifier | [static] int | 2 | Axe tree damage multiplier |
| CriticalHitSpeedMultiplier | [static] float | 1.1 | Crit attack speed boost |
| ConditionLowerChance | [static] int | 10 | Base condition loss 1/N |
| ISOCURSOR / ISORETICLE | [pub static] int | 0 / 1 | Target reticle modes |

### Key Fields
| Name | Mod | Type | Note |
|-|-|-|-|
| combatConfig | [priv final] | CombatConfig | Tunable combat parameters |
| hitInfoPool | [pub final] | ObjectPool<HitInfo> | Reusable hit info objects |
| hitOnlyTree | [priv] | boolean | Swing only hit a tree |
| treeHit | [priv] | IsoTree | Tree that was hit |
| objHit | [priv] | IsoObject | Object that was hit |

## 2. Damage Calculations

### Base Damage Formula (melee)
```
rawDamage = Rand.Next(weapon.minDamage, weapon.maxDamage)
damage = rawDamage * weapon.getDamageMod(owner) * owner.getHittingMod()
```
If using 2H weapon one-handed: `damage -= minDamage` (loses base damage floor).

### Damage Modifiers Applied (in order)
1. **Pain reduction**: arms pain > 10 for swings, legs pain > 10 for stomps
   - `damage /= clamp(pain / 10, 1.0, 30.0)`
2. **Trait modifier**: `damage *= traitDamageDealtReductionModifier`
3. **Multi-target split**: `damageSplit = damage / (splitIndex * 0.5)` per target
4. **Range falloff** (melee): `rangeDel = dist / maxRange * 2.0` (min 0.3 clamped to 1.0)
5. **Panic penalty**: `-0.1 * panicLevel` per moodle level > 1
6. **Stress penalty**: `-0.1 * stressLevel` per moodle level > 1
7. **Stomp override**: `Rand(0.7, 1.0) + Strength * 0.2`, then shoes stompPower
8. **Endurance level**: multipliers 0.5/0.2/0.1/0.05 at levels 1-4
9. **Tired level**: multipliers 0.5/0.2/0.1/0.05 at levels 1-4
10. **Hit location**: head x3.0, legs x0.05 (from CombatConfigKey)
11. **Clothing defense**: `damage * abs(1.0 - totalDefense/100)`
12. **Global multiplier**: `damage * GLOBAL_MELEE_DAMAGE_REDUCTION_MULTIPLIER` (0.15)
13. **Weapon level**: `damage * (0.3 + level * 0.1)` (BASE + level * INCREMENT)

### Stomp Damage
```java
damageSplit = Rand.Next(0.7f, 1.0f) + Strength_level * 0.2f;
if (no_shoes) damageSplit *= 0.5f;
else damageSplit *= shoes.getStompPower();
```

### Vehicle Damage
```java
damage * 50.0 * (doorDamage / 10.0) / vehicleDurability
```

### Received Damage Modifiers
| Target | Multiplier | Config Key |
|-|-|-|
| Player | 0.4 | PLAYER_RECEIVED_DAMAGE_MULTIPLIER |
| Non-player | 1.5 | NON_PLAYER_RECEIVED_DAMAGE_MULTIPLIER |

### One-Handed Penalty (2H weapon held in 1H)
```
damage *= DAMAGE_PENALTY_ONE_HANDED_TWO_HANDED_WEAPON_MULTIPLIER (0.5)
```

### applyDamage Methods
| Signature | Note |
|-|-|
| applyDamage(IsoGameCharacter, float) | Whole-character damage (checks invulnerable) |
| applyDamage(BodyPart, float) | Body part health reduction |

## 3. Hit Detection and Targeting

### attackCollisionCheck Flow
`attackCollisionCheck(owner, weapon, swipeState, attackType)` - main entry point.

1. Check shove/grapple animation state
2. Fire `OnWeaponSwingHitPoint` Lua event
3. Handle thrown weapons (`physicsObject != null`)
4. Consume weapon uses (`useSelf`, `otherHandUse`)
5. Call `calculateHitInfoList(owner)` to find targets
6. Process weapon endurance cost
7. Iterate HitInfo list, apply damage per target
8. Process object hits (doors, windows, trees)
9. Check condition loss

### calculateHitInfoList
Populates `owner.getHitInfoList()` with valid targets sorted by priority.

### calcValidTargets(owner, weapon, targetsProne, targetsStanding)
Separates targets into prone and standing lists. Uses `BallisticsController` for firearms.

### Target Selection (calculateAttackVars)
1. Get weapon from primary hand (validate otherHandRequire)
2. Bare hands / shove override when weapon is null or at min range
3. Auto-prone targeting: if `Core.isOptionAutoProneAtk()` and no standing targets
4. Close kill: knife + 1 zombie + within minRange = jaw stab
5. Manual floor attack via `ManualFloorAtk` key binding

### Object Hit Detection (CheckObjectHit)
Direction-based check from player facing:
- Checks doors, windows, thumpables, composters, trees
- Tests line-of-sight: Clear, ClearThroughClosedDoor, ClearThroughWindow
- Can hit backside of adjacent walls when LOS is Blocked
- Trees hit via `IsoTree.WeaponHit()`

### Hit Chance (ranged)
```java
hit = Rand.Next(100) <= hitInfo.chance
```
If miss but `firearmUseDamageChance` sandbox option: damage ignored but hit registered.

### Window Between Check
`isWindowBetween(owner, target)` - detects windows in attack path, calls `smashWindowBetween()`.

## 4. Melee Weapon Mechanics

### Swing States
- `SwipeStatePlayer` - main player swing state
- Attack types: DEFAULT, OVERHEAD, UPPERCUT, CHARGE, NONE
- WeaponType determines available attacks with weighted random selection

### Melee Attack Flow
1. Weapon damage roll: `Rand(minDamage, maxDamage)`
2. Apply `getDamageMod()` and `getHittingMod()`
3. Bone collision check for floor attacks (Head, Spine, Calves, Feet)
4. Body part assignment: head hit -> Head/Neck, legs hit -> Groin-Foot, else -> Hand-Neck
5. Apply melee hit location damage with defense calculation
6. Resolve spiked armor damage reflection
7. Knife death effect (jaw stab with weapon stuck in zombie)
8. Helmet fall check on head hits

### getDamageMod(character) - Skill-Based Modifiers
Weapon parts and character skill level affect the returned multiplier. Each WeaponPart can modify damage.

### Shove Mechanics
- Shove when `doShove = true` and not stomping
- `bIgnoreDamage = true` for shoves (knockback only, no HP damage)
- Exception: shove + aimAtFloor = stomp (does damage)

### Stomp Mechanics
- Triggered by: `aimAtFloor && doShove`
- Uses leg pain instead of arm pain for reduction
- Shoe stompPower multiplier (no shoes = 0.5x)
- Strength perk adds 0.2 per level

### Jaw Stab (Close Kill)
Conditions: knife type + single zombie + within minRange
- Sets `closeKill = true`, `rangeDel *= 1000` (guaranteed kill)
- `knockbackAttackMod = 0` (no knockback)
- Knife may get stuck: `Rand(8 + (knifeLvl+1)*2)` chance
- If stuck: removed from player hands, attached to zombie jaw

### Endurance Cost Formula
```java
weight = weapon.getEffectiveWeight()
twoHandPenalty = (2H weapon held in 1H) ? weight / 1.5 / 10 : 0
enduranceLoss = (weight * 0.28 * fatigueMod * playerFatigueMod * enduranceMod * 0.3 + twoHandPenalty) * 0.04
enduranceLoss *= traitEnduranceLossModifier
```

### Melee Endurance on Hit (applyMeleeEnduranceLoss)
```java
baseLoss = (weight * BASE_SCALE * fatigueMod * playerFatigueMod * enduranceMod * WEIGHT_MOD + 2hPenalty) * FINAL_MULT
if (floor_shove) baseLoss *= FLOOR_SHOVE_MULT (2.0)
dmgModifier = min(realDmgLeft / maxDamage, 1.0)  // or CLOSE_KILL_MODIFIER (0.2)
finalLoss = baseLoss * dmgModifier
```

### Maintenance XP
`processMaintenanceCheck()` triggers on hits to objects, zombies, vehicles, trees.
Base XP: 1.0 per trigger.

## 5. Ranged Weapon Mechanics

### Firearm Hit Chance Modifiers
All penalties/bonuses applied to base `hitChance + aimingPerkHitChanceModifier * aimLevel`:

| Modifier | Config Key | Default |
|-|-|-|
| Point blank bonus | POINT_BLANK_TO_HIT_MAXIMUM_BONUS | 40.0 |
| Point blank distance | POINT_BLANK_DISTANCE | 3.5 tiles |
| Low light penalty | LOW_LIGHT_TO_HIT_MAXIMUM_PENALTY | 50.0 |
| Moving penalty | MOVING_TO_HIT_PENALTY | 5.0 |
| Running penalty | RUNNING_TO_HIT_PENALTY | 15.0 |
| Sprinting penalty | SPRINTING_TO_HIT_PENALTY | 25.0 |
| Marksman trait bonus | MARKSMAN_TRAIT_TO_HIT_BONUS | 20.0 |
| Arm pain modifier | ARM_PAIN_TO_HIT_MODIFIER | 0.1 per pain |
| Panic penalty | PANIC_TO_HIT_BASE_PENALTY | 4.0 per level |
| Stress penalty | STRESS_TO_HIT_BASE_PENALTY | 4.0 per level |
| Tired penalty | TIRED_TO_HIT_BASE_PENALTY | 2.5 per level |
| Endurance penalty | ENDURANCE_TO_HIT_BASE_PENALTY | 2.5 per level |
| Drunk penalty | DRUNK_TO_HIT_BASE_PENALTY | 4.0 per level |
| Wind intensity | WIND_INTENSITY_TO_HIT_PENALTY | 6.0 |
| Rain/Fog | Distance-based modifiers | Variable |
| Min/Max hit chance | MINIMUM/MAXIMUM_TO_HIT_CHANCE | 5.0 / 100.0 |

### Piercing Bullets
When bullet passes through a target at same angle:
```
minDamage /= PIERCING_BULLET_DAMAGE_REDUCTION (5.0)
maxDamage /= PIERCING_BULLET_DAMAGE_REDUCTION (5.0)
```

### Ranged Hit Processing (processHit)
1. Calculate shot direction (NORTH, SOUTH, LEFT, RIGHT) from wielder/target angles
2. Determine hit reaction from targeted body part (ballistics controller)
3. Apply blood based on hit location
4. Create combat data for ragdoll system
5. Returns body part ordinal for damage application

### Sightless Shooting (no scope/sight)
```
distanceModifier = BASE_DISTANCE / (dist * (prone ? PRONE_MOD : 1.0))
aimDelayPenalty = aimDelay * DISTANCE_MODIFIER * dist
```

### Aiming Delay (post-shot)
```
aimingDelay += recoilDelay * RECOIL_MODIFIER(0.25) + aimingTime * AIMING_MODIFIER(0.05)
```

### Weapon Jam System
- Jam chance: `jamGunChance` (default 5.0%)
- Checked per shot via `checkJam(player, racking)`
- Unjam via `checkUnJam(player)` - skill-based

## 6. Knockback and Knockdown

### Knockback
| Field | Default | Note |
|-|-|-|
| pushBackMod | 1.0 | Base knockback force multiplier |
| knockBackOnNoDeath | true | Apply knockback on non-lethal hits |
| knockbackAttackMod | 1.0 | Per-attack modifier (0 for jaw stab) |

Knockback is applied via `owner.knockbackAttackMod` which is set to:
- `1.0` for normal attacks
- `0.0` for jaw stabs (close kills)

### Knockdown
| Field | Default | Note |
|-|-|-|
| knockdownMod | 1.0 | Knockdown chance modifier |
| alwaysKnockdown | false | Guaranteed knockdown |

### Hit Reactions (melee, non-ranged)
The hit reaction system determines animation response:
- `HeadLeft`, `HeadRight`, `HeadTop` - directional head hits
- `Uppercut` - upward strike
- `KnifeDeath` - jaw stab kill
- `HitSpearDeath1/2` - spear kill variants
- `Floor` - ground-level hit
- `OnKnees` - zombie eating position
- `Eating` - zombie mid-feed
- `GettingUpFront` - zombie getting up hit

### Zombie State Effects on Hits
- `ZombieOnGroundState`: +`Rand(10)` to reanimate timer
- `ZombieGetUpState`: reanimate timer set to `Rand(60) + 30`
- `isHitFromBehind`: set when dot product of directions > 0.5

## 7. Critical Hits

### Critical Chance Calculation
Base from weapon: `weapon.getCriticalChance()` (default 20.0%)

Additional bonuses from CombatConfig:
| Source | Config Key | Default |
|-|-|-|
| From behind | ADDITIONAL_CRITICAL_HIT_CHANCE_FROM_BEHIND | +30.0% |
| Default bonus | ADDITIONAL_CRITICAL_HIT_CHANCE_DEFAULT | +5.0% |

Per-perk modifier: `weapon.getAimingPerkCritModifier() * aimingLevel`

### Critical Damage
```
criticalDamageMultiplier (default 2.0x)
CriticalHitSpeedMultiplier = 1.1 (attack animation speed boost)
```

### Critical Hit Effects
- Ranged: determined per-shot via `calculateCritChance(target)`
- Blood application uses `criticalHit` flag for intensity
- Head shots: always add heavy blood to head + upper torso + both arms
- Limb shots: blood added to specific limb

## 8. Zombie Damage to Player

### Clothing Defense System
```java
totalDefense = scratchDefense(part) * 0.5 + biteDefense(part)
totalDefense *= sandboxZombiesArmorFactor
totalDefense = min(totalDefense, zombiesMaxDefense)  // cap 100
finalDamage = damageSplit * abs(1.0 - totalDefense / 100)
```

### Body Part Targeting
Melee: random from body part ranges based on hit type:
- Head hit: `Hand_L` to `Neck` range (head/neck)
- Legs hit: `Groin` to `Foot_R` range
- Normal: `Hand_L` to `Neck` range (upper body)

Ranged: mapped from `RagdollBodyPart` to `BodyPartType`:
- HEAD -> Head
- SPINE -> Torso
- PELVIS -> Pelvis
- ARM parts -> Arms
- LEG parts -> Legs

### Spiked Armor Reflection
When player shoves or knife-attacks a zombie with spiked clothing:
- Check if body part has spikes (front or behind based on facing)
- Spiked foot: damage to player's `Foot_R`
- Spiked primary hand contact: damage to `Hand_R`
- Spiked secondary hand contact: damage to `Hand_L`

### Explosion Damage
`processInstantExplosion(target, trap)`:
- Forces `SHOT_CHEST` hit reaction
- Random body part selection for ragdoll
- Creates ballistics target for physics

## 9. Combat Enums

### HitReaction (`zombie.combat.HitReaction`)
| Value | Animation | Context |
|-|-|-|
| NONE | "" | No reaction |
| SHOT | "Shot" | Generic shot |
| SHOT_HEAD_FWD | "ShotHeadFwd" | Headshot forward |
| SHOT_HEAD_FWD02 | "ShotHeadFwd02" | Headshot forward alt |
| SHOT_HEAD_BWD | "ShotHeadBwd" | Headshot backward |
| SHOT_BELLY | "ShotBelly" | Gut shot |
| SHOT_BELLY_STEP | "ShotBellyStep" | Gut shot with stagger |
| SHOT_BELLY_STEP_BEHIND | "ShotBellyStepBehind" | Gut shot from behind |
| SHOT_CHEST | "ShotChest" | Chest shot |
| SHOT_CHEST_L/R | "ShotChestL/R" | Chest left/right |
| SHOT_CHEST_STEP_L/R | "ShotChestStepL/R" | Chest stagger |
| SHOT_SHOULDER_L/R | "ShotShoulderL/R" | Shoulder |
| SHOT_SHOULDER_STEP_L/R | "ShotShoulderStepL/R" | Shoulder stagger |
| SHOT_LEG_L/R | "ShotLegL/R" | Leg shot |
| HEAD_LEFT/RIGHT/TOP | Directional | Melee head hits |
| UPPERCUT | "Uppercut" | Upward melee strike |
| KNIFE_DEATH | "KnifeDeath" | Jaw stab kill |
| HIT_SPEAR1/2 | "HitSpearDeath1/2" | Spear kill |
| ON_KNEES | "OnKnees" | Eating stance |
| EATING | "Eating" | Active eating |
| GETTING_UP_FRONT | "GettingUpFront" | Rising from prone |
| FLOOR | "Floor" | On ground |

### ShotDirection (`zombie.combat.ShotDirection`)
| Value | Angle Range |
|-|-|
| SOUTH | 0-45 deg (facing same direction) |
| RIGHT | 45-180 deg |
| LEFT | 225-315 deg |
| NORTH | 135-225 deg (facing each other) |

Calculated from cross product and dot product of wielder/target forward vectors.

### WeaponType (`zombie.inventory.types.WeaponType`)
See inventory.md section 9 for full enum.

### AttackType (referenced, from `zombie.AttackType`)
Used in weighted lists per WeaponType: NONE, DEFAULT, OVERHEAD, UPPERCUT, CHARGE.

## 10. CombatConfigKey Defaults

All values tunable at runtime via `CombatConfig`. Listed with category, default, min, max.

### General
| Key | Default | Range | Note |
|-|-|-|-|
| BASE_WEAPON_DAMAGE_MULTIPLIER | 0.3 | 0-1 | Base mult for weapon level formula |
| WEAPON_LEVEL_DAMAGE_MULTIPLIER_INCREMENT | 0.1 | 0-1 | Per-level increment |
| PLAYER_RECEIVED_DAMAGE_MULTIPLIER | 0.4 | 0-1 | Damage players take |
| NON_PLAYER_RECEIVED_DAMAGE_MULTIPLIER | 1.5 | 0-10 | Damage NPCs/zombies take |
| HEAD_HIT_DAMAGE_SPLIT_MODIFIER | 3.0 | 0-10 | Head hit damage multiplier |
| LEG_HIT_DAMAGE_SPLIT_MODIFIER | 0.05 | 0-1 | Leg hit damage multiplier |
| ADDITIONAL_CRITICAL_HIT_CHANCE_FROM_BEHIND | 30.0 | 0-100 | Backstab crit bonus % |
| ADDITIONAL_CRITICAL_HIT_CHANCE_DEFAULT | 5.0 | 0-100 | Default crit bonus % |

### Firearm
| Key | Default | Range | Note |
|-|-|-|-|
| RECOIL_DELAY | 10.0 | 0-100 | Post-shot recoil frames |
| POINT_BLANK_DISTANCE | 3.5 | 0-10 | Point blank range (tiles) |
| LOW_LIGHT_THRESHOLD | 0.75 | 0-1 | Light level for penalty |
| LOW_LIGHT_TO_HIT_MAXIMUM_PENALTY | 50.0 | 0-100 | Max darkness penalty |
| POINT_BLANK_TO_HIT_MAXIMUM_BONUS | 40.0 | 0-100 | Close range bonus |
| POINT_BLANK_DROP_OFF_TO_HIT_PENALTY | 0.7 | 0-1 | Distance drop-off rate |
| OPTIMAL_RANGE_TO_HIT_MAXIMUM_BONUS | 15.0 | 0-100 | Optimal range bonus |
| OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY | 4.0 | 0-10 | Beyond optimal penalty |
| MINIMUM_TO_HIT_CHANCE | 5.0 | 0-100 | Floor hit % |
| MAXIMUM_START_TO_HIT_CHANCE | 95.0 | 0-100 | Cap before bonuses |
| MAXIMUM_TO_HIT_CHANCE | 100.0 | 0-100 | Absolute cap |
| MOVING_TO_HIT_PENALTY | 5.0 | 0-100 | Walking penalty |
| RUNNING_TO_HIT_PENALTY | 15.0 | 0-100 | Running penalty |
| SPRINTING_TO_HIT_PENALTY | 25.0 | 0-100 | Sprint penalty |
| MARKSMAN_TRAIT_TO_HIT_BONUS | 20.0 | 0-100 | Marksman trait bonus |
| ARM_PAIN_TO_HIT_MODIFIER | 0.1 | 0-1 | Pain per-point penalty |
| PANIC_TO_HIT_BASE_PENALTY | 4.0 | 0-10 | Per moodle level |
| STRESS_TO_HIT_BASE_PENALTY | 4.0 | 0-10 | Per moodle level |
| TIRED_TO_HIT_BASE_PENALTY | 2.5 | 0-10 | Per moodle level |
| ENDURANCE_TO_HIT_BASE_PENALTY | 2.5 | 0-10 | Per moodle level |
| DRUNK_TO_HIT_BASE_PENALTY | 4.0 | 0-10 | Per moodle level |
| WIND_INTENSITY_TO_HIT_PENALTY | 6.0 | 0-10 | Wind accuracy penalty |
| PIERCING_BULLET_DAMAGE_REDUCTION | 5.0 | 0-100 | Through-target divisor |
| FIREARM_RECOIL_MUSCLE_STRAIN_MODIFIER | 0.05 | 0-1 | Recoil strain |

### Melee
| Key | Default | Range | Note |
|-|-|-|-|
| GLOBAL_MELEE_DAMAGE_REDUCTION_MULTIPLIER | 0.15 | 0-1 | Global melee damage scale |
| DAMAGE_PENALTY_ONE_HANDED_TWO_HANDED_WEAPON_MULTIPLIER | 0.5 | 0-1 | 2H in 1H penalty |
| ENDURANCE_LOSS_TWO_HANDED_PENALTY_DIVISOR | 1.5 | 0-10 | 2H one-hand stamina div |
| ENDURANCE_LOSS_TWO_HANDED_PENALTY_SCALE | 10.0 | 0-100 | 2H one-hand stamina scale |
| ENDURANCE_LOSS_FLOOR_SHOVE_MULTIPLIER | 2.0 | 0-10 | Stomp stamina mult |
| ENDURANCE_LOSS_CLOSE_KILL_MODIFIER | 0.2 | 0-1 | Jaw stab stamina reduction |
| ENDURANCE_LOSS_BASE_SCALE | 0.28 | 0-1 | Base endurance formula scale |
| ENDURANCE_LOSS_WEIGHT_MODIFIER | 0.3 | 0-1 | Weight contribution to stamina |
| ENDURANCE_LOSS_FINAL_MULTIPLIER | 0.04 | 0-1 | Final stamina loss mult |

### Ballistics
| Key | Default | Range | Note |
|-|-|-|-|
| BALLISTICS_CONTROLLER_DISTANCE_THRESHOLD | 2.75 | 0-10 | Min distance for ballistics |

## 11. Zombie Attack Type Selection
Source: `zombie.characters.BodyDamage.BodyDamage.AddRandomDamageFromZombie()`

### Attack Resolution Flow
The method determines scratch vs laceration vs bite through a cascading chance system. Three base values control the outcome:

| Base Value | Starting | Purpose |
|-|-|-|
| baseChance | 15 + meleeCombatMod | Chance to AVOID any wound (higher = safer) |
| baseBiteChance | 85 | Chance to avoid bite specifically |
| baseLacerationChance | 65 | Chance to avoid laceration specifically |

### Resolution Order
1. Roll `Rand.Next(100) > baseChance` - if fails, no scratch/bite/laceration (thump damage only)
2. If wound passes: `zombie.scratch = true` (default outcome)
3. Roll `Rand.Next(100) > baseLacerationChance` - if passes, upgrade to laceration
4. Roll `Rand.Next(100) > baseBiteChance` - if passes AND `!zombie.cantBite()`, upgrade to bite
5. Clothing defense roll can block the wound entirely: `Rand.Next(100) < defense`

### Modifier: Surrounding Zombies
Each additional attacking zombie beyond the first:
- `baseChance -= 10` (more likely to wound)
- `baseBiteChance -= 30` (much more likely to bite)
- `baseLacerationChance -= 15` (more likely to lacerate)

### Modifier: Attack Direction (dotSide)
| Direction | baseChance | baseBiteChance | baseLacerationChance |
|-|-|-|-|
| Front | no change | no change | no change |
| Behind | -15 | -25 | -35 |
| Left/Right | -30 | -7 | -27 |

### Modifier: Rear Vulnerability Sandbox
| rearVulnerability value | Behind restore | Left/Right restore |
|-|-|-|
| 1 (Low) | +15 / +25 / +35 (full) | +30 / +7 / +27 (full) |
| 2 (Medium) | +7 / +17 / +23 (partial) | +15 / +4 / +15 (partial) |
| 3 (High, default) | no restore | no restore |

Additional: if behind AND >2 zombies attacking: baseBiteChance -= 15, baseLacerationChance -= 15.

### Modifier: Traits and Zombie State
| Condition | Effect |
|-|-|
| Thick Skinned trait | `baseChance *= 1.3` (30% safer) |
| Thin Skinned trait | `baseChance /= 1.3` (23% more vulnerable) |
| Inactive zombie | `baseChance += 20`, `baseBiteChance += 20`, `baseLacerationChance += 20` |

### Modifier: Zombie Strength (Drag Down)
| Strength setting | Zombies needed to drag down |
|-|-|
| 1 (Superhuman) | 2 |
| 2 (Normal, default) | 3 |
| 3 (Weak) | 6 |

When drag-down triggers: all chances set to 0 (guaranteed death), `hitReaction = "EndDeath"`.

### Body Part Targeting (from zombie)
- Standing zombie: 90% upper body (`Hand_L` to `Neck`), 10% includes down to `Groin`
- Crawler: 50% chance lower body (`UpperLeg_L` to `MAX`), 50% chance attack fails
- Neck targeting: `10 * zombiesAttacking`% base chance, +5% from behind, +2% from side
- Head/Neck reroll: 70% chance kept (90% from behind, 80% from side), otherwise rerolled to other body part

### Clothing Defense
- Scratch: `getBodyPartClothingDefense(partIndex, false, false)` - scratch defense
- Laceration: `getBodyPartClothingDefense(partIndex, false, false)` - scratch defense
- Bite: `getBodyPartClothingDefense(partIndex, true, false)` - bite defense
- If `Rand.Next(100) < defense`: attack blocked, no wound applied

## 12. Vehicle Collision Damage to Zombies
Source: `zombie.vehicles.BaseVehicle`, `zombie.characters.IsoGameCharacter`

### hitCharacter() Flow
`BaseVehicle.hitCharacter(IsoGameCharacter, Vector2, boolean)`:
1. Reject if `!chr.canBeHitByVehicle(this)` or positions too close (<0.01 on either axis)
2. Get linear velocity, cap speed at 15.0
3. Skip if speed < 0.05 (effectively stationary)
4. Calculate impulse direction (vehicle->character), normalize, scale by `3.0 * speed/15.0`
5. `hitSpeed = speed + clientForce / fudgedMass`
6. Delegates to `chr.onHitByVehicle(vehicle, hitSpeed, hitDir, impactPos, pushedBack)`

### Damage to Character (onHitByVehicleApplyDamage)
**Standing target:**
```
impactSpeedNoDamage = 3.0
impactSpeedMaxDamage = 20.0
maxDamage = 1.5
damageAlpha = (impactSpeed - 3.0) / 17.0
damage = 1.5 * EaseOutQuad(damageAlpha)
```

**Prone target (run-over):**
```
impactSpeedNoDamage = 0.2
impactSpeedMaxDamage = 10.0
maxDamage = 0.5
damageAlpha = (impactSpeed - 0.2) / 9.8
damage = 0.5 * EaseOutQuad(damageAlpha)
```

**Sequential hit modifiers:**
| Hit Type | Multiplier | Condition |
|-|-|-|
| First impact | 1.0 | `isFirstImpact = true` |
| Being pushed (not first, standing) | 0.01 | `pushedBack && !isFirstImpact` |
| Being crushed (not first, prone) | 0.2 | `isCrushed && !isFirstImpact` |

Sequential damage is also multiplied by `GameTime.getMultiplier()` (frame-rate adjusted).

### Knockdown from Vehicle
```java
minSpeedToPossibleKnockdown = 3.5
maxSpeedToPossibleKnockdown = 14.5
knockDownAlpha = (speed - 3.5) / 11.0
knockDownChance = EaseInQuad(knockDownAlpha) * 100
```
Guaranteed knockdown when `knockDownAlpha > 1.0` (speed > 14.5).

### HitVars (collision data structure)
| Field | Type | Note |
|-|-|-|
| vehicleSpeed | float | Speed capped at 10.0 for zombies |
| hitSpeed | float | For zombies: `vehicleSpeed + clientForce/fudgedMass` |
| hitSpeed (player) | float | Prone: `max(speed*6, 5)`, standing: `max(speed*2, 5)` |
| vehicleImpulse | float | `fudgedMass * 7.0 * speed/10.0 * abs(dot)` |
| vehicleDamage | int | Damage the vehicle takes (from calculateDamageWithCharacter) |
| isVehicleHitFromFront | boolean | `hitFromSide == Side.FRONT` |
| isTargetHitFromBehind | boolean | `hitFromSide == Side.BEHIND` |

## 13. Vehicle Damage from Hitting Characters
Source: `zombie.vehicles.BaseVehicle.calculateDamageWithCharacter()`

### Formula
```
minSpeedToDamage = 5.0 km/h
speedAtMaxDamage = 160.0 km/h
dmgMultiplier = 60.0
dmgAlpha = (currentAbsoluteSpeedKmHour - 5.0) / 155.0
dmgAlphaClamped = clamp(dmgAlpha, 0.0, 1.0)
damage = dmgMultiplier * EaseOutQuad(dmgAlphaClamped)
```

Returns 0 if speed < 5 km/h. Maximum damage = 60 at 160+ km/h.

For animals: `dmgMultiplier *= min(animalWeight / 50.0, 1.5)` (heavier animals damage vehicle more).

### Damage Application to Vehicle
`applyDamageFromHitCharacters()` accumulates front/back damage from all pedestrian hits per frame:
- Characters in front of vehicle: damage to front parts via `addDamageFrontHitAChr()`
- Characters behind vehicle: damage to rear parts via `addDamageRearHitAChr()`

## 14. Infection Chance Modifiers
Source: `zombie.characters.BodyDamage.BodyPart`, `zombie.SandboxOptions.ZombieLore`

### Transmission Sandbox Option (ZombieLore.transmission)
| Value | Name | Bite | Scratch/Laceration |
|-|-|-|-|
| 1 (default) | Everyone's Infected | Always infects | 7% scratch, 25% laceration (`generateZombieInfection`) |
| 2 | Blood + Saliva | Always infects | Never infects (forced false) |
| 3 | Saliva Only | Always infects | 7% scratch, 25% laceration |
| 4 | None | Never infects | Never infects |

### Bite Infection Logic (`SetBitten`)
- `transmission != 4`: `isInfected = true` (guaranteed)
- `transmission == 4`: `isInfected = false`, `isFakeInfected = false`
- If `mortality == 7` (Non-Lethal): `isInfected = false`, `isFakeInfected = true` (shows infected but won't kill)

### Scratch Infection Logic (`generateZombieInfection`)
- Scratch base chance: 7% (`Rand.Next(100) < 7`)
- Laceration base chance: 25% (`Rand.Next(100) < 25`)
- `transmission == 2` (Blood+Saliva) OR `transmission == 4` (None): forced `isInfected = false`
- `mortality == 7` (Non-Lethal): converts to `isFakeInfected = true`

### Mortality Sandbox Option (ZombieLore.mortality)
| Value | Name | Default |
|-|-|-|
| 1-6 | Various time-to-death | Controls how fast infection kills |
| 5 | 2-3 Days (default) | Standard mortality |
| 7 | Non-Lethal | Infection never kills, shows fake infection |

### Clothing Defense Against Infection
Clothing defense is checked BEFORE infection is applied:
- `getBodyPartClothingDefense(part, isBite, false)` returns defense value
- `totalDefense = scratchDefense * armorFactor` (scratch/laceration)
- `totalDefense = biteDefense * armorFactor` (bite)
- `zombiesArmorFactor`: sandbox multiplier (default 2.0)
- `zombiesMaxDefense`: sandbox cap (default 85)
- If defense roll succeeds, no wound and no infection chance

### Other Sandbox Options Affecting Wounds
| Option | Default | Effect |
|-|-|-|
| rearVulnerability | 3 (High) | Modifies base chances from behind/side (see section 11) |
| zombiesArmorFactor | 2.0 | Multiplier for clothing defense values |
| zombiesMaxDefense | 85 | Cap on total clothing defense |
| injurySeverity | 2 (Normal) | Affects wound healing time: 0.5x (Low), 1.0x (Normal), 1.5x (High) |

## 15. Full Melee Damage Chain Summary
See damage-systems.md section 2 for the complete step-by-step pipeline with all constants.

### Condensed Formula (melee hit vs zombie, single target, no crit, no stomp)
```
rawDmg = Rand(minDmg, maxDmg) * damageMod * hittingMod
if (2H in 1H): rawDmg -= minDmg
if (armsPain > 10): rawDmg /= clamp(armsPain/10, 1, 30)
rawDmg *= traitDamageDealtReductionModifier
damageSplit = rawDmg / (targetIndex * 0.5)    // 1st target = /0.5, 2nd = /1.0, etc.
damageSplit *= modDelta * rangeFalloff
```

Then in `processHitDamage()`:
```
if (behind && !shove): damageSplit *= 1.5
damageSplit *= receivedDamageMod                   // 1.5 for zombies
damageSplit *= (0.3 + weaponLevel * 0.1)           // weapon skill scaling
if (aimAtFloor && !shove): damageSplit *= max(5.0, critMult)  // stomp bonus
if (crit): damageSplit *= max(2.0, critMult)
if (2H in 1H): damageSplit *= 0.5                  // one-handed penalty
```

Then in `hitConsequences()`:
```
damageSplit *= GLOBAL_MELEE_DAMAGE_REDUCTION_MULTIPLIER (0.15)
target.health -= damageSplit                        // via CombatManager.applyDamage()
```

### Effective Damage Examples (weapon level 5, normal zombie)
| Weapon | MinDmg | MaxDmg | ~Effective vs Zombie |
|-|-|-|-|
| Bare hands / shove | 0.0 | 0.0 | 0 (knockback only) |
| Kitchen knife | 0.2 | 0.4 | ~0.03 per hit |
| Baseball bat | 0.8 | 1.1 | ~0.10 per hit |
| Axe (2H proper) | 1.0 | 2.5 | ~0.19 per hit |
| Jaw stab (knife) | rangeDel*1000 | - | instant kill |
| Stomp (boots) | 0.7-1.0+str | - | ~0.3-0.5 per stomp |

Note: zombie health is 1.8 + Rand(0, 0.3) = 1.8-2.1 HP.

## 16. processHitDamage Modifier Stack
Source: `IsoGameCharacter.processHitDamage()` - applied per-target after base damage roll.

### Hit Force (knockback strength)
```java
hitForce = (damage * modDelta) * shovingMod
if (bIgnoreDamage): hitForce = (damage * modDelta / 2.7) * shovingMod
if (STRONG && melee): hitForce *= 1.4
if (WEAK && melee):   hitForce *= 0.6

endurance = stats.ENDURANCE * knockbackAttackMod
if (endurance < 0.5):
  endurance = max(endurance * 1.3, 0.4)
  hitForce *= endurance

if (player && !ignoreDamage): hitForce *= 2.0
```

### Behind Damage Bonus
```java
oPos = (target.pos - wielder.pos).normalize()
dir = wielder.forwardDirection
if (dot(oPos, dir) > -0.3):   // not directly facing the wielder
  damage *= 1.5
```
Only applies to players (not NPCs), non-shove, non-ignoreDamage attacks.

### CombatManager Multiplier Application Order
1. `applyPlayerReceivedDamageModifier()`: 0.4x for player targets, 1.5x for zombies
2. `applyWeaponLevelDamageModifier()`: `(0.3 + level * 0.1)` multiplier
3. Floor attack bonus: `max(5.0, weapon.criticalDamageMultiplier)` (aimAtFloor && !shove)
4. Critical hit bonus: `max(2.0, weapon.criticalDamageMultiplier)`
5. `applyOneHandedDamagePenalty()`: 0.5x if 2H weapon held in 1H

### Critical Hit Chance
```java
// From CombatConfigKey defaults:
ADDITIONAL_CRITICAL_HIT_CHANCE_FROM_BEHIND = 30.0%
ADDITIONAL_CRITICAL_HIT_CHANCE_DEFAULT     = 5.0%
```
Behind check: `isBehind(target)` adds 30% crit chance on top of base 5%.

### Endurance Cost on Hit
```java
enduranceLoss = (weight * 0.28 * fatigueMod * playerFatigueMod * enduranceMod * 0.3 + twoHandPenalty) * 0.04
twoHandPenalty = (2H in 1H) ? weight / 1.5 / 10.0 : 0.0
if (aimAtFloor && doShove): enduranceLoss *= 2.0    // stomp costs double
dmgEnduranceModifier = min(realDmgDealt / maxDamage, 1.0)  // less cost on overkill
if (closeKill): dmgEnduranceModifier = 0.2           // jaw stab costs 80% less
enduranceLoss *= dmgEnduranceModifier
```
