# Health & Body Damage - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22
Cross-ref: damage-systems.md (complete damage pipelines), combat.md, vehicles-system.md

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | BodyPartType Enum | 21-81 |
| 2 | BodyPart Class | 82-173 |
| 3 | BodyDamage Class | 174-256 |
| 4 | Infection Mechanics | 257-285 |
| 5 | CharacterStat Registry | 286-329 |
| 6 | Stats Class | 330-358 |
| 7 | Nutrition Class | 359-407 |
| 8 | Fitness / Exercise | 408-454 |
| 9 | Moodle System | 455-507 |
| 10 | AddRandomDamageFromZombie detail | 508-584 |
| 11 | Infection mortality timeline | 585-635 |
| 12 | Vehicle impact body damage | 636-682 |

## 1. BodyPartType Enum
**Package:** zombie.characters.BodyDamage

### Values (index 0-17)

| Index | Value | Pain Mod | Damage Mod | Bleed Mod | Skin Surface | Dist to Core |
|-|-|-|-|-|-|-|
| 0 | Hand_L | 0.5 | 0.1 | 0.2 | 0.010 | 0.80 |
| 1 | Hand_R | 0.5 | 0.1 | 0.2 | 0.010 | 0.80 |
| 2 | ForeArm_L | 0.6 | 0.2 | 0.3 | 0.035 | 0.60 |
| 3 | ForeArm_R | 0.6 | 0.2 | 0.3 | 0.035 | 0.60 |
| 4 | UpperArm_L | 0.6 | 0.3 | 0.4 | 0.045 | 0.30 |
| 5 | UpperArm_R | 0.6 | 0.3 | 0.4 | 0.045 | 0.30 |
| 6 | Torso_Upper | 0.7 | 0.35 | 0.5 | 0.180 | 0.00 |
| 7 | Torso_Lower | 0.78 | 0.4 | 0.9 | 0.120 | 0.05 |
| 8 | Head | 0.8 | 0.6 | 1.0 | 0.080 | 0.05 |
| 9 | Neck | 0.8 | 0.7 | 1.5 | 0.020 | 0.02 |
| 10 | Groin | 0.7 | 0.4 | 0.5 | 0.060 | 0.30 |
| 11 | UpperLeg_L | 0.7 | 0.3 | 0.4 | 0.090 | 0.45 |
| 12 | UpperLeg_R | 0.7 | 0.3 | 0.4 | 0.090 | 0.45 |
| 13 | LowerLeg_L | 0.6 | 0.2 | 0.3 | 0.070 | 0.75 |
| 14 | LowerLeg_R | 0.6 | 0.2 | 0.3 | 0.070 | 0.75 |
| 15 | Foot_L | 0.5 | 0.2 | 0.2 | 0.020 | 1.00 |
| 16 | Foot_R | 0.5 | 0.2 | 0.2 | 0.020 | 1.00 |
| 17 | MAX | - | - | - | - | - |

### Movement/Action Penalty per Body Part

| Index | Part | Max Action Penalty | Max Movement Penalty |
|-|-|-|-|
| 0-1 | Hand L/R | 1.0 | 0.05 |
| 2-3 | ForeArm L/R | 0.6 | 0.10 |
| 4-5 | UpperArm L/R | 0.4 | 0.10 |
| 6 | Torso_Upper | 0.2 | 0.05 |
| 7 | Torso_Lower | 0.1 | 0.05 |
| 8 | Head | 0.4 | 0.25 |
| 9 | Neck | 0.05 | 0.05 |
| 10 | Groin | 0.05 | 0.15 |
| 11-12 | UpperLeg L/R | 0.1 | 0.40 |
| 13-14 | LowerLeg L/R | 0.1 | 0.60 |
| 15-16 | Foot L/R | 0.1 | 1.00 |

### Static Methods

| Return | Method | Purpose |
|-|-|-|
| BodyPartType | FromIndex(int) | Index to enum value |
| BodyPartType | FromString(String) | String to enum value |
| int | ToIndex(BodyPartType) | Enum to index |
| String | ToString(BodyPartType) | Enum to string |
| String | getDisplayName(BodyPartType) | Translated display name |
| float | getPainModifyer(int) | Pain multiplier by index |
| float | getDamageModifyer(int) | Damage multiplier by index |
| float | getBleedingTimeModifyer(int) | Bleed time multiplier by index |
| float | GetSkinSurface(BodyPartType) | Skin surface area for thermoregulation |
| float | GetDistToCore(BodyPartType) | Distance from body core (0.0-1.0) |
| float | GetMaxActionPenalty(BodyPartType) | Max action speed penalty |
| float | GetMaxMovementPenalty(BodyPartType) | Max movement speed penalty |
| float | GetUmbrellaMod(BodyPartType) | Umbrella rain protection modifier |
| BodyPartType | getRandom() | Random body part (not MAX) |

## 2. BodyPart Class
**Package:** zombie.characters.BodyDamage

### Fields

| Access | Type | Field | Purpose |
|-|-|-|-|
| [pub] | BodyPartType | type | Body part type |
| [priv] | float | health | Part health (0-100) |
| [priv] | boolean | bandaged | Has bandage applied |
| [priv] | boolean | bitten | Zombie bite wound |
| [priv] | boolean | bleeding | Currently bleeding |
| [priv] | boolean | isBleedingStemmed | Bleeding stemmed with pressure |
| [priv] | boolean | isCauterized | Wound cauterized |
| [priv] | boolean | scratched | Scratch wound |
| [priv] | boolean | stitched | Stitched wound |
| [priv] | boolean | deepWounded | Deep laceration |
| [priv] | boolean | isInfected | Zombie infection |
| [priv] | boolean | isFakeInfected | Fake infection (anxiety) |
| [priv] | boolean | cut | Cut wound |
| [priv] | boolean | infectedWound | Non-zombie wound infection |
| [priv] | boolean | haveGlass | Glass shard embedded |
| [priv] | boolean | haveBullet | Bullet lodged |
| [priv] | boolean | splint | Splint applied |
| [priv] | boolean | needBurnWash | Burn needs washing |
| [priv] | float | bandageLife | Bandage remaining durability |
| [priv] | boolean | alcoholicBandage | Bandage was sterilized |
| [priv] | float | scratchTime | Time since scratch |
| [priv] | float | biteTime | Time since bite |
| [priv] | float | cutTime | Time since cut |
| [priv] | float | bleedingTime | Time bleeding |
| [priv] | float | deepWoundTime | Time since deep wound |
| [priv] | float | burnTime | Time since burn |
| [priv] | float | fractureTime | Time since fracture |
| [priv] | float | stitchTime | Time since stitch |
| [priv] | float | stiffness | Exercise stiffness level |
| [priv] | float | woundInfectionLevel | Wound infection severity |
| [priv] | float | alcoholLevel | Disinfectant level |
| [priv] | float | additionalPain | Extra pain from treatment |
| [priv] | float | splintFactor | Splint effectiveness |
| [priv] | float | plantainFactor | Plantain poultice effect |
| [priv] | float | comfreyFactor | Comfrey poultice effect |
| [priv] | float | garlicFactor | Garlic poultice effect |
| [priv] | float | wetness | Part wetness level |
| [priv] | String | bandageType | Bandage item type |
| [priv] | String | splintItem | Splint item type |

### Damage Constants

| Type | Field | Value |
|-|-|-|
| Scratch | scratchDamage | 0.9375 |
| Cut | cutDamage | 1.875 |
| Bite | biteDamage | 2.1875 |
| Deep Wound | woundDamage | 3.125 |
| Bullet | bulletDamage | 3.125 |
| Fracture | fractureDamage | 3.125 |
| Burn | burnDamage | 3.75 |
| Bleed | bleedDamage | 0.2857 |

### Key Methods

| Access | Return | Method | Purpose |
|-|-|-|-|
| [pub] | float | getHealth() | Get part health 0-100 |
| [pub] | void | SetHealth(float) | Set part health |
| [pub] | void | AddHealth(float) | Add health |
| [pub] | void | ReduceHealth(float) | Reduce health |
| [pub] | boolean | HasInjury() | Check for any injury |
| [pub] | float | getPain() | Get total pain (base + additional + stiffness) |
| [pub] | void | DamageUpdate() | Per-tick damage update |
| [pub] | void | RestoreToFullHealth() | Reset to 100 health, clear wounds |
| [pub] | void | SetBitten(boolean, boolean) | Set bite with optional infection |
| [pub] | void | setBleeding(boolean) | Set bleeding state |
| [pub] | void | setCut(boolean, boolean) | Set cut with optional no-infection |
| [pub] | void | setScratched(boolean, boolean) | Set scratch with optional no-infection |
| [pub] | void | setDeepWounded(boolean) | Set deep wound state |
| [pub] | void | setBandaged(boolean, float, boolean, String) | Apply bandage with params |
| [pub] | void | setStitched(boolean) | Apply/remove stitches |
| [pub] | void | setSplint(boolean, float) | Apply splint with factor |
| [pub] | void | setBurned() | Apply burn wound |
| [pub] | void | generateBleeding() | Generate bleed from wound |
| [pub] | void | generateDeepWound() | Generate deep laceration |
| [pub] | void | generateDeepShardWound() | Generate glass shard wound |
| [pub] | void | generateFracture(float) | Generate bone fracture |
| [pub] | void | generateZombieInfection(int) | Roll zombie infection chance |
| [pub] | void | damageFromFirearm(float) | Apply firearm damage |
| [pub] | void | SetInfected(boolean) | Set zombie infection |
| [pub] | void | SetFakeInfected(boolean) | Set fake infection |
| [pub] | void | DisableFakeInfection() | Remove fake infection |
| [pub] | boolean | isBandageDirty() | Check if bandage needs change |

## 3. BodyDamage Class
**Package:** zombie.characters.BodyDamage

### Fields

| Access | Type | Field | Default | Purpose |
|-|-|-|-|-|
| [priv] | ArrayList<BodyPart> | bodyParts | 17 parts | All body parts |
| [priv] | float | overallBodyHealth | 100.0 | Overall health 0-100 |
| [priv] | boolean | isInfected | false | Has zombie infection |
| [priv] | float | infectionTime | -1.0 | Infection start time (game hours) |
| [priv] | float | infectionMortalityDuration | -1.0 | Hours until death from infection |
| [priv] | float | infectionGrowthRate | 0.001 | Infection progression rate |
| [pub] | boolean | isFakeInfected | false | Anxiety-based fake infection |
| [priv] | float | standardHealthAddition | 0.002 | Normal health regen rate |
| [priv] | float | reducedHealthAddition | 0.0013 | Reduced health regen |
| [priv] | float | severlyReducedHealthAddition | 0.0008 | Severely reduced regen |
| [priv] | float | sleepingHealthAddition | 0.02 | Health regen while sleeping |
| [priv] | float | healthFromFood | 0.015 | Health regen from eating |
| [priv] | float | healthReductionFromSevereBadMoodles | 0.0165 | Health loss from bad moodles |
| [priv] | float | initialThumpPain | 14.0 | Pain from zombie thump |
| [priv] | float | initialScratchPain | 18.0 | Pain from scratch |
| [priv] | float | initialBitePain | 25.0 | Pain from bite |
| [priv] | float | initialWoundPain | 80.0 | Pain from deep wound |
| [priv] | float | painReductionFromMeds | 30.0 | Pain med effectiveness |
| [priv] | float | panicIncreaseValue | 7.0 | Panic per zombie seen |
| [priv] | float | panicReductionValue | 0.06 | Panic decay rate |
| [priv] | float | drunkIncreaseValue | 400.0 | Intoxication increase rate |
| [priv] | float | drunkReductionValue | 0.0042 | Intoxication decay rate |
| [priv] | float | coldProgressionRate | 0.0112 | Cold illness progression |
| [priv] | float | boredomDecreaseFromReading | 0.5 | Boredom reduction per read |
| [pub/static] | float | InfectionLevelToZombify | 0.001 | Min infection to turn zombie |

### Key Methods

| Access | Return | Method | Purpose |
|-|-|-|-|
| [pub] | BodyPart | getBodyPart(BodyPartType) | Get part by type |
| [pub] | ArrayList<BodyPart> | getBodyParts() | Get all body parts |
| [pub] | float | getHealth() | Get overall health 0-100 |
| [pub] | float | getOverallBodyHealth() | Get overall body health |
| [pub] | void | AddGeneralHealth(float) | Add to overall health |
| [pub] | void | ReduceGeneralHealth(float) | Reduce overall health |
| [pub] | void | AddDamage(BodyPartType, float) | Damage specific part |
| [pub] | void | RestoreToFullHealth() | Restore all parts to full |
| [pub] | void | Update() | Main per-tick update |
| [pub] | void | calculateOverallHealth() | Recalculate from all parts |
| [pub] | boolean | AddRandomDamageFromZombie(IsoZombie, String) | Apply zombie attack damage |
| [pub] | void | DamageFromWeapon(HandWeapon, int) | Apply weapon damage to part |
| [pub] | void | applyDamageFromWeapon(int, float, int, float) | Apply raw weapon damage |
| [pub] | boolean | IsInfected() | Check zombie infection |
| [pub] | void | setInfected(boolean) | Set zombie infection |
| [pub] | float | getInfectionTime() | Get infection start time |
| [pub] | void | setInfectionTime(float) | Set infection start time |
| [pub] | float | getInfectionMortalityDuration() | Get hours until death |
| [pub] | void | setInfectionMortalityDuration(float) | Set mortality duration |
| [pub] | float | pickMortalityDuration() | Roll random mortality time |
| [pub] | float | getApparentInfectionLevel() | Get visible infection level |
| [pub] | boolean | HasInjury() | Check any injury exists |
| [pub] | int | getNumPartsBleeding() | Count bleeding parts |
| [pub] | int | getNumPartsScratched() | Count scratched parts |
| [pub] | int | getNumPartsBitten() | Count bitten parts |
| [pub] | boolean | isNeckBleeding() | Check neck bleed specifically |
| [pub] | void | IncreasePanic(int) | Increase panic from zombies |
| [pub] | void | ReducePanic() | Reduce panic over time |
| [pub] | void | JustAteFood(Food, float, boolean) | Process food consumption effects |
| [pub] | void | JustDrankBooze(Food, float) | Process alcohol consumption |
| [pub] | void | JustTookPill(InventoryItem) | Process pill consumption |
| [pub] | void | JustTookPainMeds() | Apply pain medication |
| [pub] | void | JustReadSomething(Literature) | Apply reading effects |
| [pub] | void | UpdateWetness() | Update clothing wetness |
| [pub] | void | UpdateCold() | Update cold/illness |
| [pub] | void | UpdateBoredom() | Update boredom level |
| [pub] | void | UpdateStrength() | Update strength effects |
| [pub] | void | OnFire(boolean) | Set on fire state |
| [pub] | boolean | UseBandageOnMostNeededPart() | Auto-bandage worst wound |
| [pub] | void | SetBitten(BodyPartType, boolean) | Set bite on part |
| [pub] | void | SetScratched(BodyPartType, boolean) | Set scratch on part |
| [pub] | void | SetBleeding(BodyPartType, boolean) | Set bleeding on part |
| [pub] | void | SetBandaged(int, boolean, float, boolean, String) | Apply bandage to part |
| [pub] | void | load(ByteBuffer, int) | Deserialize |
| [pub] | void | save(ByteBuffer) | Serialize |

## 4. Infection Mechanics

### Zombie Infection (Knox Virus)
- Bite: 100% chance (sandbox configurable)
- Scratch: 25% base chance (sandbox configurable)
- Cut from zombie: 25% base chance
- `infectionGrowthRate`: 0.001 per tick
- `InfectionLevelToZombify`: 0.001 threshold
- `infectionMortalityDuration`: randomized via `pickMortalityDuration()`
- Infection tracks start time (`infectionTime`) in game world hours
- Each body part tracks `isInfected` independently
- `isFakeInfected`: anxiety-based false positive, resolves on its own

### Wound Infection (Non-zombie)
- Tracked per-body-part via `infectedWound` boolean
- `woundInfectionLevel`: float progression 0.0+
- Dirty bandages increase risk
- Alcohol bandages (`alcoholicBandage`) reduce risk
- Disinfectant level tracked via `alcoholLevel` per part
- Herbal poultices: `plantainFactor`, `comfreyFactor`, `garlicFactor` reduce infection

### Damage Pipeline
1. Zombie attack calls `AddRandomDamageFromZombie(zombie, hitReaction)`
2. Selects random body part, applies scratch/bite/laceration
3. Calls `generateZombieInfection(baseChance)` on the part
4. Weapon damage calls `DamageFromWeapon(weapon, partIndex)` or `applyDamageFromWeapon()`
5. Each tick, `BodyPart.DamageUpdate()` processes ongoing damage (bleed, burn, infection)
6. `BodyDamage.Update()` aggregates and applies to overall health

## 5. CharacterStat Registry
**Package:** zombie.characters

All stats registered with (id, min, max, default):

| Stat ID | Min | Max | Default | Purpose |
|-|-|-|-|-|
| Anger | 0.0 | 1.0 | 0.0 | Anger level |
| Boredom | 0.0 | 100.0 | 0.0 | Boredom level |
| Discomfort | 0.0 | 100.0 | 0.0 | Clothing discomfort |
| Endurance | 0.0 | 1.0 | 1.0 | Stamina (1.0 = full) |
| Fatigue | 0.0 | 1.0 | 0.0 | Tiredness |
| Fitness | -1.0 | 1.0 | 0.0 | Fitness modifier |
| FoodSickness | 0.0 | 100.0 | 0.0 | Food poisoning |
| Hunger | 0.0 | 1.0 | 0.0 | Hunger (1.0 = starving) |
| Idleness | 0.0 | 1.0 | 0.0 | Idle time tracker |
| Intoxication | 0.0 | 100.0 | 0.0 | Drunkenness |
| Morale | 0.0 | 1.0 | 1.0 | Morale (1.0 = high) |
| NicotineWithdrawal | 0.0 | 0.51 | 0.0 | Smoker withdrawal |
| Pain | 0.0 | 100.0 | 0.0 | Total pain |
| Panic | 0.0 | 100.0 | 0.0 | Panic level |
| Poison | 0.0 | 100.0 | 0.0 | Poison level |
| Sanity | 0.0 | 1.0 | 1.0 | Mental state |
| Sickness | 0.0 | 1.0 | 0.0 | General sickness |
| Stress | 0.0 | 1.0 | 0.0 | Stress level |
| Temperature | 20.0 | 40.0 | 37.0 | Body temp (Celsius) |
| Thirst | 0.0 | 1.0 | 0.0 | Thirst (1.0 = dehydrated) |
| Unhappiness | 0.0 | 100.0 | 0.0 | Depression level |
| Wetness | 0.0 | 100.0 | 0.0 | Body wetness |
| ZombieFever | 0.0 | 100.0 | 0.0 | Knox infection fever |
| ZombieInfection | 0.0 | 100.0 | 0.0 | Knox infection level |

### CharacterStat Methods

| Return | Method | Purpose |
|-|-|-|
| float | get(CharacterStat) | Get stat value |
| boolean | set(CharacterStat, float) | Set stat (returns true if changed) |
| boolean | add(CharacterStat, float) | Add to stat |
| boolean | remove(CharacterStat, float) | Subtract from stat |
| boolean | reset(CharacterStat) | Reset to default |
| boolean | isAtMinimum(CharacterStat) | Check if at min |
| boolean | isAtMaximum(CharacterStat) | Check if at max |

## 6. Stats Class
**Package:** zombie.characters

Wrapper around CharacterStat map. Stored on `IsoGameCharacter.stats`.

### Fields

| Access | Type | Field | Purpose |
|-|-|-|-|
| [pub] | int | numVisibleZombies | Currently visible zombies |
| [pub] | int | numChasingZombies | Zombies chasing player |
| [pub] | int | lastVeryCloseZombies | Very close zombie count |
| [pub/static] | int | numCloseZombies | Close zombie count (global) |
| [priv] | boolean | tripping | Is tripping |
| [priv] | float | trippingRotAngle | Trip rotation |

### Methods

| Return | Method | Purpose |
|-|-|-|
| float | get(CharacterStat) | Get stat value |
| boolean | set(CharacterStat, float) | Set stat value |
| boolean | add(CharacterStat, float) | Add to stat |
| boolean | remove(CharacterStat, float) | Subtract from stat |
| void | resetStats() | Reset all stats to defaults |
| float | getNicotineStress() | Get combined stress + nicotine |
| int | getNumVisibleZombies() | Get visible zombie count |
| int | getNumChasingZombies() | Get chasing zombie count |

## 7. Nutrition Class
**Package:** zombie.characters.BodyDamage

### Fields

| Access | Type | Field | Default | Purpose |
|-|-|-|-|-|
| [priv] | float | calories | 800.0 | Caloric balance (-2200 to 3700) |
| [priv] | float | carbohydrates | 0.0 | Carb level (-500 to 1000) |
| [priv] | float | lipids | 0.0 | Fat level (-500 to 1000) |
| [priv] | float | proteins | 0.0 | Protein level (-500 to 1000) |
| [priv] | double | weight | 80.0 | Body weight kg (min 35) |

### Depletion Rates (per game-world second)

| Nutrient | Rate |
|-|-|
| Carbohydrates | 0.0035 |
| Lipids | 0.00113 |
| Proteins | 0.00086 |
| Calories (normal) | 0.016 |
| Calories (exercise) | 0.13 |
| Calories (sleeping) | 0.003 |

### Weight Thresholds

| Weight Range | Trait Applied |
|-|-|
| <= 50 | Emaciated |
| 50-65 | Very Underweight |
| 65-75 | Underweight |
| 85-100 | Overweight |
| >= 100 | Obese |

### Key Methods

| Return | Method | Purpose |
|-|-|-|
| float | getCalories() | Get caloric balance |
| void | setCalories(float) | Set calories (clamped -2200 to 3700) |
| float | getCarbohydrates() | Get carb level |
| float | getLipids() | Get fat level |
| float | getProteins() | Get protein level |
| double | getWeight() | Get body weight kg |
| void | setWeight(double) | Set weight (min 35, damages at floor) |
| void | update() | Per-tick nutrition update |
| void | applyTraitFromWeight() | Apply weight-based traits |
| boolean | canAddFitnessXp() | Check if weight allows fitness XP |

## 8. Fitness / Exercise System
**Package:** zombie.characters.BodyDamage

### Constants

| Field | Value | Purpose |
|-|-|-|
| HOURS_FOR_STIFFNESS | 12 | Hours before stiffness kicks in |
| BASE_STIFFNESS_INC | 0.5 | Stiffness gain per exercise tick |
| BASE_ENDURANCE_RED | 0.015 | Endurance reduction per rep |
| BASE_REGULARITY_INC | 0.08 | Regularity gain per rep |
| BASE_REGULARITY_DEC | 0.002 | Regularity decay per day |
| BASE_PAIN_INC | 2.5 | Stiffness pain per affected part |

### FitnessExercise (inner class)

| Field | Type | Purpose |
|-|-|-|
| type | String | Exercise identifier |
| metabolics | Metabolics | FitnessLight or FitnessHeavy |
| stiffnessInc | ArrayList<String> | Body regions affected ("arms","legs","chest","abs") |
| xpModifier | float | XP multiplier (default 1.0) |

### XP from Exercise

| Body Region | Strength XP | Fitness XP |
|-|-|-|
| arms | +4.0 | 0 |
| chest | +2.0 | 0 |
| legs | 0 | +4.0 |
| abs | 0 | +2.0 |

### Key Methods

| Return | Method | Purpose |
|-|-|-|
| void | update() | Per-tick stiffness/regularity update |
| void | exerciseRepeat() | Called each exercise rep |
| void | incRegularity() | Increase exercise regularity |
| void | reduceEndurance() | Drain endurance from exercise |
| void | incFutureStiffness() | Queue future stiffness |
| void | incStats() | Award Str/Fit XP |
| float | getRegularity(String) | Get regularity for exercise type |
| boolean | onGoingStiffness() | Check if stiffness active |
| void | resetValues() | Clear all fitness data |
| void | init() | Initialize from Lua FitnessExercises table |

## 9. Moodle System
**Package:** zombie.characters.Moodles / zombie.scripting.objects

### MoodleType Values (registered)

| MoodleType | Category |
|-|-|
| ENDURANCE | Bad - stamina depletion |
| TIRED | Bad - fatigue |
| HUNGRY | Bad - hunger |
| PANIC | Bad - panic from zombies |
| SICK | Bad - illness/nausea |
| BORED | Bad - boredom |
| UNHAPPY | Bad - depression |
| BLEEDING | Bad - active bleeding |
| WET | Bad - wetness/rain |
| HAS_A_COLD | Bad - common cold |
| ANGRY | Bad - anger |
| STRESS | Bad - stress |
| THIRST | Bad - dehydration |
| INJURED | Bad - has injuries |
| PAIN | Bad - pain level |
| HEAVY_LOAD | Bad - encumbered |
| DRUNK | Bad - intoxicated |
| DEAD | Bad - dead |
| ZOMBIE | Bad - zombified |
| HYPERTHERMIA | Bad - overheating |
| HYPOTHERMIA | Bad - freezing |
| WINDCHILL | Bad - wind exposure |
| CANT_SPRINT | Bad - too exhausted to sprint |
| UNCOMFORTABLE | Bad - clothing discomfort |
| NOXIOUS_SMELL | Bad - nearby corpses |
| FOOD_EATEN | Good - recently ate |

### Moodle Levels
- Level 0: no moodle (inactive)
- Level 1: mild
- Level 2: moderate
- Level 3: severe
- Level 4: extreme (MaxMoodleLevel)

### Moodles Class Methods

| Return | Method | Purpose |
|-|-|-|
| int | getMoodleLevel(MoodleType) | Get level 0-4 |
| boolean | isMaxMoodleLevel(MoodleType) | Check if at level 4 |
| String | getMoodleDisplayString(MoodleType) | Translated display name |
| String | getMoodleDescriptionString(MoodleType) | Translated description |
| int | getGoodBadNeutral(MoodleType) | 0=neutral, 1=good, 2=bad |
| void | Update() | Update all moodle levels |
| boolean | UI_RefreshNeeded() | Check if UI needs redraw |

## 10. AddRandomDamageFromZombie - Detailed Flow
Source: `zombie.characters.BodyDamage.BodyDamage.AddRandomDamageFromZombie(IsoZombie, String)`
See damage-systems.md section 1 for the full pipeline with all constants.

### Parameters
- `zombie`: attacking zombie (provides `scratch`, `laceration`, `crawling`, `inactive`, `cantBite()`)
- `hitReaction`: animation reaction string (defaults to "Bite" if null/empty)

### Base Chance Constants
```
baseChance          = 15 + player.getMeleeCombatMod()  // dodge chance (higher = better)
baseBiteChance      = 85    // chance attack stays scratch (higher = safer)
baseLacerationChance = 65   // chance attack stays scratch (higher = safer)
```

### Modifier Cascade (applied in order)
1. **Multi-zombie penalty**: each extra zombie: -10 base, -30 bite, -15 laceration
2. **Drag-down check**: enough zombies = guaranteed death (EndDeath reaction)
3. **Thick/Thin Skinned traits**: base * 1.3 or base / 1.3
4. **Direction**: behind = -15/-25/-35, side = -30/-7/-27 (before rear vulnerability)
5. **Rear Vulnerability sandbox**: restores some/all direction penalties
6. **Behind + 3+ zombies**: additional -15 bite, -15 laceration
7. **Inactive zombie bonus**: +20 to all three chances

### Body Part Selection Rules

**Standing zombie target range:**
```
90%: Hand_L (0) to Neck (9)     // upper body
10%: Hand_L (0) to Groin (10)   // includes groin

Neck forced if: behind && Rand(100) < (10 * zombieCount + 5_behind + 2_side)
Head/Neck redirect: front 70%, behind 90%, side 80% chance to reassign away
```

**Crawling zombie:**
```
50%: miss entirely (return false)
50%: 90% UpperLeg_L to MAX, 10% Groin to MAX
```

### Damage Roll
```
damage = Rand(1000) / 1000.0 * Rand(10, 20)
// Effective range: 0 to ~19 HP of body part damage
```

### Wound Type Resolution
```
if Rand(100) > baseChance:       // player failed to dodge
  type = SCRATCH
  if Rand(100) > baseLacerationChance: type = LACERATION
  if Rand(100) > baseBiteChance:       type = BITE (if zombie can bite)

  defense = getBodyPartClothingDefense(part, type==BITE, false)
  if Rand(100) < defense:
    // clothing blocked - add hole to clothing but NO wound
    return false

  // Apply wound:
  AddDamage(partIndex, damage)
  if SCRATCH: SetScratched(part, true)  // 25% infection chance
  if LACERATION: SetCut(part, true)     // 25% infection chance
  if BITE: SetBitten(part, true)        // 100% infection

else:
  // player dodged - thump pain only (14.0 * partPainMod)
```

### Pain Values (base * BodyPartType.painModifier)
| Wound Type | Base Pain |
|-|-|
| Thump (dodged) | 14.0 |
| Scratch | 18.0 |
| Laceration | 18.0 |
| Bite | 25.0 |

## 11. Infection Mortality Timeline
Source: `zombie.characters.BodyDamage.BodyDamage.Update()`, `pickMortalityDuration()`

### Infection Detection
Each `BodyDamage.Update()` tick scans all 17 body parts:
- If any part has `isInfected == true`: sets `BodyDamage.isInfected = true`
- If fake-infected part found while real-infected: converts to real, clears fever

### Mortality Duration (hours)
| Sandbox Value | Setting Name | Duration Formula |
|-|-|-|
| 1 | Instant | 0.0 hours |
| 2 | 0-30 Seconds | Rand(0, 30) / 3600 * traitDel |
| 3 | 0-1 Minutes | Rand(0.5, 1.0) / 60 * traitDel |
| 4 | 3-12 Hours | Rand(3, 12) * traitDel |
| 5 | 2-3 Days (default) | Rand(2, 3) * 24 * traitDel |
| 6 | 1-2 Weeks | Rand(1, 2) * 168 * traitDel |
| 7 | Never | -1.0 (infection becomes fake) |

`traitDel`: Resilient = 1.25, Prone to Illness = 0.75, default = 1.0.

### Health Degradation Curve
```java
percentMortality = min((currentHours - infectionTime) / mortalityDuration, 1.0)
ZOMBIE_INFECTION stat = percentMortality * 100   // 0-100 display value

if (percentMortality == 1.0):
  ReduceGeneralHealth(110)    // instant death (overkill)
else:
  p = percentMortality^4      // quartic curve - health stable until late
  healthCap = (1.0 - p) * 100
  if (overallHealth > healthCap):
    ReduceGeneralHealth(overallHealth - healthCap)
```

**Timeline example (2.5-day mortality):**
| Time | percentMortality | healthCap | Notes |
|-|-|-|-|
| 0h | 0.0 | 100 | Infection starts |
| 15h | 0.25 | 99.6 | Nearly full health |
| 30h | 0.50 | 93.75 | Mild symptoms |
| 45h | 0.75 | 68.4 | Rapid decline begins |
| 55h | 0.92 | 28.4 | Severely ill |
| 60h | 1.00 | 0 | Death (ReduceGeneralHealth(110)) |

### Fake Infection
- Triggers when `isFakeInfected` is set on any body part
- Shows same ZOMBIE_FEVER symptoms but resolves naturally
- Reduction rate: `infectionGrowthRate * gameMultiplier * 2.0`
- Can be overridden by real infection from another wound

## 12. Vehicle Impact Body Damage
Source: `IsoPlayer.getDamageFromHitByACar()`, `IsoGameCharacter.onHitByVehicleApplyDamage()`
See damage-systems.md section 4 for the complete vehicle damage pipeline.

### Player-Specific Vehicle Damage
```
modifier = sandbox.damageToPlayerFromHitByACar:
  1 = 0.0 (none), 2 = 0.5, 3 = 1.0, 4 = 2.0, 5 = 5.0

damage = vehicleSpeed * modifier
numPartsHit = (int)(2.0 + damage * 0.07)   // more speed = more parts injured
```

### Per-Body-Part Damage
```
bodyPart = Rand(Hand_L, MAX)     // random part, full range
realDamage = max(Rand(damage-15, damage), 5.0)   // min 5.0

Trait modifiers:
  FAST_HEALER:  realDamage *= 0.8
  SLOW_HEALER:  realDamage *= 1.2

Injury severity sandbox:
  Low (1):    realDamage *= 0.5
  Normal (2): no change
  High (3):   realDamage *= 1.5

realDamage *= 0.9   // final 10% reduction always applied
part.AddDamage(realDamage)
```

### Secondary Injury Generation
| Condition | Injury Type | Chance |
|-|-|-|
| realDamage > 40 | Deep wound | 1 in 12 (8.3%) |
| realDamage > 10, any part | Fracture | 10% |
| realDamage > 30, head | Fracture | 80% |
| realDamage > 10, legs (below groin) | Fracture | 60% |

Fracture severity: `Rand(Rand(10, realDmg+10), Rand(realDmg+20, realDmg+30))`

### Zombie Vehicle Damage (non-player)
Zombies use a simpler system via `IsoGameCharacter.calculateDamageFromVehicleImpact()`:
- Standing: `damage = 1.5 * EaseOutQuad((speed - 3.0) / 17.0)` - max 1.5 at speed 20
- Prone: `damage = 0.5 * EaseOutQuad((speed - 0.2) / 9.8)` - max 0.5 at speed 10
- Applied via `CombatManager.applyDamage()` which reduces `health` directly
- Zombie health: 1.8 + Rand(0, 0.3) = instakill at speed ~15+ for standing
