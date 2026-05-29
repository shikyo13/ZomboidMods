# Sandbox Options System - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture | 16-51 |
| 2 | Option Types | 52-76 |
| 3 | Top-Level Options | 77-330 |
| 4 | Inner Class Options | 331-455 |
| 5 | SandboxVars Lua Access | 456-498 |
| 6 | Presets | 499-539 |
| 7 | Custom Sandbox Options (Mods) | 540-630 |
| 8 | Persistence and Serialization | 631-677 |

## 1. Architecture

**Class**: `zombie.SandboxOptions` [pub][final]
**Singleton**: `SandboxOptions.instance`
**Lua global**: `SandboxVars` (populated by `toLua()`)

### Class Hierarchy
```
ConfigOption (abstract)
  +-- BooleanConfigOption
  +-- DoubleConfigOption
  +-- EnumConfigOption
  +-- IntegerConfigOption
  +-- StringConfigOption

SandboxOption (interface)
  +-- BooleanSandboxOption extends BooleanConfigOption
  +-- DoubleSandboxOption extends DoubleConfigOption
  +-- EnumSandboxOption extends EnumConfigOption
  +-- IntegerSandboxOption extends IntegerConfigOption
  +-- StringSandboxOption extends StringConfigOption
```

Each `SandboxOption` wraps a `ConfigOption` and adds:
- `tableName` - group prefix (null for top-level, "ZombieLore", "ZombieConfig", etc.)
- `shortName` - name without prefix
- `translation` / `pageName` - UI strings
- `fromTable(KahluaTable)` / `toTable(KahluaTable)` - Lua sync
- `custom` flag for mod-added options

### Storage
- **Binary**: `map_sand.bin` in save folder (header "SAND", version 6)
- **Lua file**: `<server>_SandboxVars.lua` in server settings folder
- **Text/INI**: `<server>_sandbox.ini` (legacy, still supported for loading)
- **Presets**: `media/lua/shared/Sandbox/<PresetName>.lua`

## 2. Option Types

### BooleanSandboxOption
Wraps `BooleanConfigOption`. Stores `boolean`. Lua value: `true`/`false`.

### IntegerSandboxOption
Wraps `IntegerConfigOption`. Stores `int` with min/max bounds.
Constructor: `newIntegerOption(name, min, max, default)`.

### DoubleSandboxOption
Wraps `DoubleConfigOption`. Stores `double` with min/max bounds.
Constructor: `newDoubleOption(name, min, max, default)`.
Note: some defaults use `float` literals (e.g., `0.65f`) which may cause precision issues.

### EnumSandboxOption
Wraps `EnumConfigOption`. Stores `int` from 1 to `numValues`.
Constructor: `newEnumOption(name, numValues, default)`.
Values are 1-indexed integers. UI labels come from translation keys:
`Sandbox_<ValueTranslation>_option<N>`.

### StringSandboxOption
Wraps `StringConfigOption`. Stores `String` with optional max length (-1 = unlimited).
Constructor: `newStringOption(name, default, maxLength)`.
Provides `getSplitCSVList()` for comma-separated parsing.

## 3. Top-Level Options

All options below are `[pub][final]` fields on `SandboxOptions.instance`.

### Zombie Population
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `zombies` | enum | 1-6 | 4 | Zombie count (6=None, 4=Normal) |
| `distribution` | enum | 1-2 | 1 | Urban focused vs uniform |
| `zombieVoronoiNoise` | bool | - | true | Randomize distribution |
| `zombieRespawn` | enum | 1-4 | 2 | Respawn frequency |
| `zombieMigrate` | bool | - | true | Zombies wander between cells |

### Time and Calendar
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `dayLength` | enum | 1-27 | 4 | 1=15min, 2=30min, 3=1h, 4=90min, 5+=hours |
| `startYear` | enum | 1-100 | 1 | Year = 1993 + value - 1 |
| `startMonth` | enum | 1-12 | 7 | July |
| `startDay` | enum | 1-31 | 23 | Day of month |
| `startTime` | enum | 1-9 | 2 | 1=7am, 2=9am, 3=noon, 4=2pm, 5=5pm, 6=9pm, 7=midnight, 8=2am, 9=5am |
| `dayNightCycle` | enum | 1-3 | 1 | Normal/always day/always night |

### Climate
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `climateCycle` | enum | 1-6 | 1 | Climate variation pattern |
| `fogCycle` | enum | 1-3 | 1 | Fog frequency |
| `temperature` | enum | 1-5 | 3 | 1=very cold...5=very hot |
| `rain` | enum | 1-5 | 3 | 1=very dry...5=very rainy |
| `maxFogIntensity` | enum | 1-4 | 1 | Fog cap |
| `maxRainFxIntensity` | enum | 1-3 | 1 | Rain visual cap |
| `enableSnowOnGround` | bool | - | true | Snow accumulation |

### Utilities Shutoff
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `waterShut` | enum | 1-9 | 2 | When water stops (legacy enum) |
| `elecShut` | enum | 1-9 | 2 | When power stops |
| `waterShutModifier` | int | -1 to MAX | 14 | Days until water shutoff (-1=instant) |
| `elecShutModifier` | int | -1 to MAX | 14 | Days until power shutoff |
| `alarmDecay` | enum | 1-6 | 2 | Burglar alarm decay |
| `alarmDecayModifier` | int | -1 to MAX | 14 | Days until alarm decay |

### Loot Categories (all DoubleSandboxOption, range 0.0-4.0, default 0.6)
| Field | Category |
|-|-|
| `foodLootNew` | Food |
| `literatureLootNew` | Literature |
| `skillBookLoot` | Skill books |
| `recipeResourceLoot` | Recipe resources |
| `medicalLootNew` | Medical supplies |
| `survivalGearsLootNew` | Survival gear |
| `cannedFoodLootNew` | Canned food |
| `weaponLootNew` | Melee weapons |
| `rangedWeaponLootNew` | Ranged weapons |
| `ammoLootNew` | Ammunition |
| `mechanicsLootNew` | Mechanics items |
| `otherLootNew` | Other items |
| `clothingLootNew` | Clothing |
| `containerLootNew` | Containers |
| `keyLootNew` | Keys |
| `mediaLootNew` | Media (CDs, VHS) |
| `mementoLootNew` | Mementos |
| `cookwareLootNew` | Cookware |
| `materialLootNew` | Materials |
| `farmingLootNew` | Farming items |
| `toolLootNew` | Tools |

### Loot System
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `rollsMultiplier` | double | 0.1-100 | 1.0 | Container roll count multiplier |
| `lootItemRemovalList` | string | - | "" | CSV of item types to remove |
| `removeStoryLoot` | bool | - | false | Remove story/unique loot |
| `removeZombieLoot` | bool | - | false | Remove loot from zombies |
| `zombiePopLootEffect` | int | 0-20 | 10 | Zombie pop affects loot density |
| `insaneLootFactor` | double | 0.0-0.2 | 0.05 | Insane rarity multiplier |
| `extremeLootFactor` | double | 0.05-0.6 | 0.2 | Extreme rarity multiplier |
| `rareLootFactor` | double | 0.2-1.0 | 0.6 | Rare multiplier |
| `normalLootFactor` | double | 0.6-2.0 | 1.0 | Normal multiplier |
| `commonLootFactor` | double | 1.0-3.0 | 2.0 | Common multiplier |
| `abundantLootFactor` | double | 2.0-4.0 | 3.0 | Abundant multiplier |
| `hoursForLootRespawn` | int | 0-MAX | 0 | Hours between respawns (0=off) |
| `seenHoursPreventLootRespawn` | int | 0-MAX | 0 | Recent visit prevention |
| `maxItemsForLootRespawn` | int | 0-MAX | 5 | Max items per respawn |
| `constructionPreventsLootRespawn` | bool | - | true | Player builds block respawn |
| `maximumLooted` | int | 0-200 | 50 | Max pre-looted % |
| `daysUntilMaximumLooted` | int | 0-3650 | 90 | Days to reach max looted |
| `ruralLooted` | double | 0.0-2.0 | 0.5 | Rural looting multiplier |
| `maximumDiminishedLoot` | int | 0-100 | 0 | Max loot diminishment % |
| `daysUntilMaximumDiminishedLoot` | int | 0-3650 | 3650 | Days to reach max diminished |

### World Items
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `worldItemRemovalList` | string | - | "Base.Hat,Base.Glasses,..." | CSV of items to remove from ground |
| `hoursForWorldItemRemoval` | double | 0-MAX | 24.0 | Hours before ground items removed |
| `itemRemovalListBlacklistToggle` | bool | - | false | Invert list (blacklist mode) |

### Environment and Nature
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `erosionSpeed` | enum | 1-5 | 3 | Vegetation growth speed |
| `erosionDays` | int | -1 to 36500 | 0 | Custom erosion day override |
| `farming` | enum | 1-5 | 3 | Farming speed |
| `compostTime` | enum | 1-8 | 2 | 1=1wk, 2=2wk...8=12wk |
| `natureAbundance` | enum | 1-5 | 3 | Foraging abundance |
| `plantResilience` | enum | 1-5 | 3 | Plant disease resistance |
| `plantAbundance` | enum | 1-5 | 3 | Plant yield |
| `fishAbundance` | enum | 1-5 | 3 | Fish abundance |
| `timeSinceApo` | enum | 1-13 | 1 | Months since apocalypse start |
| `fireSpread` | bool | - | true | Fire propagation |
| `farmingSpeedNew` | double | 0.1-100 | 1.0 | Fine-grained farming speed |
| `farmingAmountNew` | double | 0.1-10 | 1.0 | Fine-grained farming yield |
| `plantGrowingSeasons` | bool | - | true | Seasonal growth restrictions |
| `killInsideCrops` | bool | - | true | Zombie trampling kills crops |
| `placeDirtAboveground` | bool | - | false | Allow dirt placement above ground floor |

### Character
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `statsDecrease` | enum | 1-5 | 3 | Hunger/thirst/fatigue speed |
| `endRegen` | enum | 1-5 | 3 | Endurance regen rate |
| `nutrition` | bool | - | false | Enable nutrition system |
| `starterKit` | bool | - | false | Starting gear |
| `characterFreePoints` | int | -100 to 100 | 0 | Extra trait points |
| `constructionBonusPoints` | enum | 1-5 | 3 | Construction XP bonus |
| `boneFracture` | bool | - | true | Enable fractures |
| `injurySeverity` | enum | 1-3 | 2 | Injury severity |
| `attackBlockMovements` | bool | - | true | Attacks stop movement |
| `allClothesUnlocked` | bool | - | false | All clothing available |
| `seeNotLearntRecipe` | bool | - | true | Show unlearned recipes |
| `negativeTraitsPenalty` | enum | 1-4 | 1 | Negative trait effect scaling |

### Health and Injury
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `hoursForCorpseRemoval` | double | -1 to MAX | -1.0 | -1=never remove corpses |
| `decayingCorpseHealthImpact` | enum | 1-5 | 3 | Corpse disease impact |
| `zombieHealthImpact` | bool | - | false | Zombies spread disease |
| `bloodLevel` | enum | 1-5 | 3 | Blood splatter amount |
| `clothingDegradation` | enum | 1-4 | 3 | Clothing wear speed |
| `daysForRottenFoodRemoval` | int | -1 to MAX | -1 | -1=never |
| `foodRotSpeed` | enum | 1-5 | 3 | Food spoilage rate |
| `fridgeFactor` | enum | 1-6 | 3 | Fridge preservation |
| `bloodSplatLifespanDays` | int | 0-365 | 0 | 0=permanent |
| `muscleStrainFactor` | double | 0-10 | 1.0 | Strain multiplier |
| `discomfortFactor` | double | 0-10 | 1.0 | Discomfort multiplier |
| `woundInfectionFactor` | double | 0-10 | 0.0 | Wound infection chance |

### Vehicles
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `enableVehicles` | bool | - | true | Vehicles exist |
| `carSpawnRate` | enum | 1-5 | 4 | Vehicle density |
| `vehicleEasyUse` | bool | - | false | No keys needed |
| `initialGas` | enum | 1-6 | 3 | Starting fuel level |
| `fuelStationGasInfinite` | bool | - | false | Infinite gas station fuel |
| `fuelStationGasMin/Max` | double | 0-1 | 0.0/0.7 | Station fuel range |
| `fuelStationGasEmptyChance` | int | 0-100 | 20 | % chance station is empty |
| `lockedCar` | enum | 1-6 | 4 | Locked vehicle frequency |
| `carGasConsumption` | double | 0-100 | 1.0 | Fuel burn rate |
| `carGeneralCondition` | enum | 1-5 | 3 | Starting condition |
| `carDamageOnImpact` | enum | 1-5 | 3 | Collision damage to car |
| `damageToPlayerFromHitByACar` | enum | 1-5 | 1 | Car-to-player damage |
| `trafficJam` | bool | - | true | Traffic jam spawns |
| `carAlarm` | enum | 1-6 | 4 | Car alarm frequency |
| `playerDamageFromCrash` | bool | - | true | Crash injuries |
| `sirenShutoffHours` | double | 0-168 | 0.0 | Hours until sirens stop |
| `chanceHasGas` | enum | 1-3 | 2 | Chance car has fuel |
| `recentlySurvivorVehicles` | enum | 1-4 | 3 | Maintained vehicles |
| `sirenEffectsZombies` | bool | - | true | Sirens attract zombies |

### Combat
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `multiHitZombies` | bool | - | false | Swing hits multiple |
| `rearVulnerability` | enum | 1-3 | 3 | Back attack bonus |
| `zombieAttractionMultiplier` | double | 0-100 | 1.0 | Sound attraction multiplier |

### Firearms
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `firearmUseDamageChance` | bool | - | true | Guns can damage on use |
| `firearmNoiseMultiplier` | double | 0.2-2 | 1.0 | Gunshot noise range |
| `firearmJamMultiplier` | double | 0-10 | 0.0 | Jam chance (0=no jams) |
| `firearmMoodleMultiplier` | double | 0-10 | 1.0 | Panic/stress from guns |
| `firearmWeatherMultiplier` | double | 0-10 | 1.0 | Weather effect on guns |
| `firearmHeadGearEffect` | bool | - | true | Headgear affects hearing |

### World Events
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `helicopter` | enum | 1-4 | 2 | Helicopter event frequency |
| `metaEvent` | enum | 1-3 | 2 | Meta event (gunshots etc.) |
| `sleepingEvent` | enum | 1-3 | 1 | Events while sleeping |
| `alarm` | enum | 1-6 | 4 | House alarm frequency |
| `lockedHouses` | enum | 1-6 | 4 | Locked house frequency |
| `annotatedMapChance` | enum | 1-6 | 4 | Annotated map spawn |
| `survivorHouseChance` | enum | 1-7 | 3 | Survivor house stories |
| `vehicleStoryChance` | enum | 1-7 | 3 | Vehicle story events |
| `zoneStoryChance` | enum | 1-7 | 3 | Zone story events |
| `nightDarkness` | enum | 1-4 | 3 | Night darkness level |
| `nightLength` | enum | 1-5 | 3 | Night duration |

### Generator
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `generatorFuelConsumption` | double | 0-100 | 0.1 | Fuel burn rate |
| `generatorSpawning` | enum | 1-7 | 5 | Generator spawn frequency |
| `allowExteriorGenerator` | bool | - | true | Place generators outdoors |
| `generatorTileRange` | int | 1-100 | 20 | Horizontal power range |
| `generatorVerticalPowerRange` | int | 1-15 | 3 | Vertical power range |

### Animals (B42)
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `animalStatsModifier` | enum | 1-6 | 4 | Animal stat speed |
| `animalMetaStatsModifier` | enum | 1-6 | 4 | Meta animal stats |
| `animalPregnancyTime` | enum | 1-6 | 2 | Pregnancy duration |
| `animalAgeModifier` | enum | 1-6 | 3 | Aging speed |
| `animalMilkIncModifier` | enum | 1-6 | 3 | Milk production |
| `animalWoolIncModifier` | enum | 1-6 | 3 | Wool production |
| `animalRanchChance` | enum | 1-7 | 7 | Ranch encounter chance |
| `animalGrassRegrowTime` | int | 1-9999 | 240 | Hours for grass regrow |
| `animalMetaPredator` | bool | - | false | Meta predator spawns |
| `animalMatingSeason` | bool | - | true | Seasonal mating |
| `animalEggHatch` | enum | 1-6 | 3 | Egg hatch speed |
| `animalSoundAttractZombies` | bool | - | false | Animal sounds attract Z |
| `animalTrackChance` | enum | 1-6 | 4 | Track spawn frequency |
| `animalPathChance` | enum | 1-6 | 4 | Path spawn frequency |
| `maximumRatIndex` | int | 0-50 | 25 | Max rat infestation |
| `daysUntilMaximumRatIndex` | int | 0-365 | 90 | Days to max rats |

### Miscellaneous
| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `metaKnowledge` | enum | 1-3 | 3 | Player meta-knowledge |
| `maximumLootedBuildingRooms` | int | 0-200 | 50 | Pre-looted room cap |
| `enablePoisoning` | enum | 1-3 | 1 | Food poisoning level |
| `maggotSpawn` | enum | 1-3 | 1 | Maggot generation |
| `lightBulbLifespan` | double | 0-1000 | 1.0 | Bulb durability mult |
| `levelForMediaXpCutoff` | int | 0-10 | 3 | TV/radio XP max level |
| `levelForDismantleXpCutoff` | int | 0-10 | 0 | Dismantle XP max level |
| `literatureCooldown` | int | 1-365 | 90 | Days between re-reads |
| `minutesPerPage` | double | 0-60 | 2.0 | Reading speed |
| `noBlackClothes` | bool | - | true | Remove black clothing |
| `easyClimbing` | bool | - | false | Easier climbing |
| `maximumFireFuelHours` | int | 1-168 | 8 | Max fire fuel duration |
| `clayLakeChance` | double | 0-1 | 0.05 | Clay at lakes |
| `clayRiverChance` | double | 0-1 | 0.05 | Clay at rivers |
| `enableTaintedWaterText` | bool | - | true | Show tainted water warning |

## 4. Inner Class Options

### Basement
**Access**: `SandboxOptions.instance.basement`
**Lua**: `SandboxVars.Basement.*`

| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `spawnFrequency` | enum | 1-7 | 4 | Basement spawn frequency |

### Map
**Access**: `SandboxOptions.instance.map`
**Lua**: `SandboxVars.Map.*`

| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `allowMiniMap` | bool | - | false | Enable mini-map |
| `allowWorldMap` | bool | - | true | Enable world map |
| `mapAllKnown` | bool | - | false | Full map revealed |
| `mapNeedsLight` | bool | - | true | Map requires light to read |

### ZombieLore
**Access**: `SandboxOptions.instance.lore`
**Lua**: `SandboxVars.ZombieLore.*`

| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `speed` | enum | 1-4 | 2 | 1=sprinters, 2=fast shamblers, 3=shamblers, 4=crawlers |
| `sprinterPercentage` | int | 0-100 | 33 | % that sprint (when speed=mixed) |
| `strength` | enum | 1-4 | 2 | Zombie strength |
| `toughness` | enum | 1-4 | 2 | Zombie toughness |
| `transmission` | enum | 1-4 | 1 | 1=blood+saliva, 2=saliva, 3=everyone, 4=none |
| `mortality` | enum | 1-7 | 5 | Time to die from infection |
| `reanimate` | enum | 1-6 | 3 | Time to reanimate |
| `cognition` | enum | 1-4 | 3 | Navigate doors, use objects |
| `doorOpeningPercentage` | int | 0-100 | 33 | % that can open doors |
| `crawlUnderVehicle` | enum | 1-7 | 5 | Crawl under vehicle behavior |
| `memory` | enum | 1-6 | 2 | How long zombies remember |
| `sight` | enum | 1-5 | 2 | Vision range |
| `hearing` | enum | 1-5 | 2 | Hearing range |
| `spottedLogic` | bool | - | true | Spotted alerting behavior |
| `thumpNoChasing` | bool | - | false | Only thump when not chasing |
| `thumpOnConstruction` | bool | - | true | Thump player constructions |
| `activeOnly` | enum | 1-3 | 1 | Active time restriction |
| `triggerHouseAlarm` | bool | - | false | Zombies trip alarms |
| `zombiesDragDown` | bool | - | true | Drag-down attacks |
| `zombiesCrawlersDragDown` | bool | - | false | Crawlers drag down |
| `zombiesFenceLunge` | bool | - | true | Lunge over fences |
| `zombiesArmorFactor` | double | 0-100 | 2.0 | Clothing armor effect |
| `zombiesMaxDefense` | int | 0-100 | 85 | Max zombie defense % |
| `chanceOfAttachedWeapon` | int | 0-100 | 6 | % with stuck weapon |
| `zombiesFallDamage` | double | 0-100 | 1.0 | Fall damage multiplier |
| `disableFakeDead` | enum | 1-3 | 1 | Fake-dead zombies |
| `playerSpawnZombieRemoval` | enum | 1-4 | 1 | Clear zombies at spawn |
| `fenceThumpersRequired` | int | -1 to 100 | 50 | Zombies needed to break fence |
| `fenceDamageMultiplier` | double | 0.01-100 | 1.0 | Fence damage scale |

### ZombieConfig
**Access**: `SandboxOptions.instance.zombieConfig`
**Lua**: `SandboxVars.ZombieConfig.*`

| Field | Type | Range | Default | Notes |
|-|-|-|-|-|
| `populationMultiplier` | double | 0-4 | 0.65 | Population scale |
| `populationStartMultiplier` | double | 0-4 | 1.0 | Day-1 population |
| `populationPeakMultiplier` | double | 0-4 | 1.5 | Peak population |
| `populationPeakDay` | int | 1-365 | 28 | Day population peaks |
| `respawnHours` | double | 0-8760 | 72.0 | Hours between respawns |
| `respawnUnseenHours` | double | 0-8760 | 16.0 | Unseen hours before respawn |
| `respawnMultiplier` | double | 0-1 | 0.1 | Respawn % of original |
| `redistributeHours` | double | 0-8760 | 12.0 | Migration interval |
| `followSoundDistance` | int | 10-1000 | 100 | Sound follow range (tiles) |
| `rallyGroupSize` | int | 0-1000 | 20 | Migration group size |
| `rallyGroupSizeVariance` | int | 0-100 | 50 | Group size variance % |
| `rallyTravelDistance` | int | 5-50 | 20 | Migration distance |
| `rallyGroupSeparation` | int | 5-25 | 15 | Min distance between groups |
| `rallyGroupRadius` | int | 1-10 | 3 | Group spread radius |
| `zombiesCountBeforeDeletion` | int | 10-500 | 300 | Zombie cap before culling |

### MultiplierConfig
**Access**: `SandboxOptions.instance.multipliersConfig`
**Lua**: `SandboxVars.MultiplierConfig.*`

All XP multipliers are `DoubleSandboxOption` with range 0.0-1000.0, default 1.0.

| Field | Skill |
|-|-|
| `xpMultiplierGlobal` (as `Global`) | Global multiplier |
| `xpMultiplierGlobalToggle` (as `GlobalToggle`) | Enable global (bool, default true) |
| `xpMultiplierFitness` | Fitness |
| `xpMultiplierStrength` | Strength |
| `xpMultiplierSprinting` | Sprinting |
| `xpMultiplierLightfoot` | Lightfoot |
| `xpMultiplierNimble` | Nimble |
| `xpMultiplierSneak` | Sneak |
| `xpMultiplierAxe` | Axe |
| `xpMultiplierBlunt` | Blunt |
| `xpMultiplierSmallBlunt` | Small Blunt |
| `xpMultiplierLongBlade` | Long Blade |
| `xpMultiplierSmallBlade` | Small Blade |
| `xpMultiplierSpear` | Spear |
| `xpMultiplierMaintenance` | Maintenance |
| `xpMultiplierWoodwork` | Woodwork |
| `xpMultiplierCooking` | Cooking |
| `xpMultiplierFarming` | Farming |
| `xpMultiplierDoctor` | Doctor |
| `xpMultiplierElectricity` | Electricity |
| `xpMultiplierMetalWelding` | Metal Welding |
| `xpMultiplierMechanics` | Mechanics |
| `xpMultiplierTailoring` | Tailoring |
| `xpMultiplierAiming` | Aiming |
| `xpMultiplierReloading` | Reloading |
| `xpMultiplierFishing` | Fishing |
| `xpMultiplierTrapping` | Trapping |
| `xpMultiplierPlantScavenging` | Plant Scavenging |
| `xpMultiplierFlintKnapping` | Flint Knapping |
| `xpMultiplierMasonry` | Masonry |
| `xpMultiplierPottery` | Pottery |
| `xpMultiplierCarving` | Carving |
| `xpMultiplierHusbandry` | Husbandry |
| `xpMultiplierTracking` | Tracking |
| `xpMultiplierBlacksmith` | Blacksmith |
| `xpMultiplierButchering` | Butchering |
| `xpMultiplierGlassmaking` | Glassmaking |

## 5. SandboxVars Lua Access

### How Options Map to SandboxVars

`SandboxOptions.toLua()` iterates all options and calls `option.toTable(SandboxVars)`.

**Top-level options** (tableName == null):
```lua
SandboxVars.Zombies         -- enum value (integer)
SandboxVars.DayLength       -- enum value
SandboxVars.FireSpread      -- boolean
SandboxVars.FoodLootNew     -- double
```

**Grouped options** (tableName != null):
```lua
SandboxVars.ZombieLore.Speed          -- enum
SandboxVars.ZombieLore.Transmission   -- enum
SandboxVars.ZombieConfig.PopulationMultiplier  -- double
SandboxVars.Map.AllowMiniMap          -- boolean
SandboxVars.MultiplierConfig.Global   -- double
SandboxVars.Basement.SpawnFrequency   -- enum
```

### Reading in Lua
```lua
local speed = SandboxVars.ZombieLore.Speed  -- returns integer (1-4)
local fire = SandboxVars.FireSpread          -- returns boolean
local loot = SandboxVars.FoodLootNew         -- returns number
```

### Writing from Lua
Sandbox options are read-only at runtime. Modifications go through:
- `SandboxOptions.instance:set(name, value)` from Java
- The settings UI which calls `updateFromLua()` after changes
- Server reload via `ReloadOptions` packet

### Sync Flow
1. Server loads options from `_SandboxVars.lua` or `map_sand.bin`
2. `toLua()` populates the `SandboxVars` global table
3. `SandboxOptions` packet sends binary to clients on connect
4. Clients call `load()` then `toLua()` to populate their `SandboxVars`

## 6. Presets

### Built-in Presets
Located at `media/lua/shared/Sandbox/<Name>.lua`. The constructor loads `Apocalypse`
as the base, then `setDefaultsToCurrentValues()`.

| Preset | File | Description |
|-|-|-|
| Apocalypse | Apocalypse.lua | Default/hardest official preset |
| Survivor | Survivor.lua | Balanced survival |
| Builder | Builder.lua | Easier building/crafting focus |
| SandboxPreset | (custom) | User-created presets |

### Preset File Format
```lua
return {
    VERSION = 6,
    Zombies = 4,
    DayLength = 4,
    FireSpread = true,
    ZombieLore = {
        Speed = 2,
        Transmission = 1,
    },
    ZombieConfig = {
        PopulationMultiplier = 0.65,
    },
    MultiplierConfig = {
        Global = 1.0,
    },
}
```

### Version Upgrades
`SandboxOptions` handles version migration in `upgradeOptionName()` and
`upgradeOptionValue()`. Current version is 6. Notable upgrades:
- v3: `DayLength` values 8,9 remapped to 14,26
- v4: `CarSpawnRate` values shifted by +1
- v5: Loot category values shifted by +2; `RecentlySurvivorVehicles` by +1
- v6: `DayLength` values >3 shifted by +1 (90min slot added)

## 7. Custom Sandbox Options (Mods)

### sandbox-options.txt Format
Place in `<mod>/42/media/sandbox-options.txt` or `<mod>/common/media/sandbox-options.txt`.

**CRITICAL**: `VERSION` must be `1` (hardcoded validation in Java).

```
VERSION = 1

option MyMod.OptionName
{
    type = boolean,
    default = true,
    page = MyModPage,
    translation = MyModOptionName,
}

option MyMod.DamageMultiplier
{
    type = double,
    min = 0.0,
    max = 10.0,
    default = 1.0,
    page = MyModPage,
    translation = MyModDamage,
}

option MyMod.Difficulty
{
    type = enum,
    numValues = 3,
    default = 2,
    page = MyModPage,
    translation = MyModDifficulty,
    valueTranslation = MyModDifficultyValues,
}

option MyMod.MaxItems
{
    type = integer,
    min = 0,
    max = 100,
    default = 10,
    page = MyModPage,
}

option MyMod.Message
{
    type = string,
    default = Hello,
    page = MyModPage,
}
```

### Supported Types
| Type | Required Fields | Optional Fields |
|-|-|-|
| `boolean` | `default` | `page`, `translation` |
| `integer` | `min`, `max`, `default` | `page`, `translation` |
| `double` | `min`, `max`, `default` | `page`, `translation` |
| `enum` | `numValues`, `default` | `page`, `translation`, `valueTranslation` |
| `string` | `default` | `page`, `translation` |

### Loading Mechanism
1. `CustomSandboxOptions.init()` iterates all active mod IDs
2. For each mod, checks `<versionDir>/media/sandbox-options.txt` first,
   then falls back to `<commonDir>/media/sandbox-options.txt`
3. File parsed via `ScriptParser` (strip comments, parse blocks)
4. Each `option` block creates a `Custom*SandboxOption` subclass
5. `CustomSandboxOptions.initInstance(SandboxOptions)` calls `newCustomOption()`
   for each, creating corresponding `*SandboxOption` wrappers with `custom=true`
6. Custom options join the main options list and are accessible via `SandboxVars`

### Accessing Custom Options in Lua
```lua
-- The option "MyMod.DamageMultiplier" becomes:
local dmg = SandboxVars.MyMod.DamageMultiplier  -- double value

-- Boolean option:
local enabled = SandboxVars.MyMod.OptionName  -- true/false

-- Enum option (1-indexed integer):
local diff = SandboxVars.MyMod.Difficulty  -- 1, 2, or 3
```

### Translation Keys
For option name: `Sandbox_<translation>` (or `Sandbox_<shortName>` if no translation set)
For tooltip: `Sandbox_<translation>_tooltip`
For enum values: `Sandbox_<valueTranslation>_option1`, `_option2`, etc.

## 8. Persistence and Serialization

### Binary Format (map_sand.bin)
```
Header: "SAND" (4 bytes)
Format version: int (244 magic + version 6)
Option count: int
For each option:
    Name: String (via GameWindow.WriteString)
    Value: String (via GameWindow.WriteString)
Preset name: String
```

### Lua File Format (_SandboxVars.lua)
Written by `writeLuaFile()`:
```lua
SandboxVars = {
    VERSION = 6,
    -- tooltip comment
    OptionName = value,
    GroupName = {
        -- tooltip comment
        SubOption = value,
    },
}
```

### INI Format (_sandbox.ini)
Legacy `ConfigFile` format. Still loadable but new saves use Lua format.

### Key Methods
| Method | Purpose |
|-|-|
| `save(ByteBuffer)` | Binary serialize to buffer |
| `load(ByteBuffer)` | Binary deserialize from buffer |
| `loadServerTextFile(name)` | Load `_sandbox.ini` |
| `loadServerLuaFile(name)` | Load `_SandboxVars.lua` |
| `saveServerLuaFile(name)` | Save `_SandboxVars.lua` |
| `loadPresetFile(name)` | Load from preset cache |
| `savePresetFile(name)` | Save to preset cache |
| `loadGameFile(name)` | Load built-in preset from `media/lua/shared/Sandbox/` |
| `toLua()` | Push all options to `SandboxVars` global |
| `updateFromLua()` | Pull values from `SandboxVars` back to Java |
| `initSandboxVars()` | Bidirectional sync (fromTable then toTable) |
| `resetToDefault()` | Reset all to defaults |
| `copyValuesFrom(other)` | Copy from another instance |
| `sendToServer()` | Send via network (admin only) |
