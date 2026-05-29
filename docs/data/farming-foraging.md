# Farming, Foraging & Survival Systems - PZ Data Map
Source: media/lua/server/Farming | media/lua/shared/Fishing | media/lua/server/Traps | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Farming System Overview | 22-59 |
| 2 | Plant Properties - All Crops | 60-102 |
| 3 | Plant Properties - Herbs & Flowers | 103-138 |
| 4 | Growth Mechanics | 139-168 |
| 5 | Disease System | 169-199 |
| 6 | Water & Health System | 200-236 |
| 7 | Foraging System Overview | 237-256 |
| 8 | Foraging Zones | 257-277 |
| 9 | Foraging Categories | 278-306 |
| 10 | Fishing System | 307-390 |
| 11 | Trapping System | 391-443 |
| 12 | Sandbox Settings | 444-455 |

---

## 1. Farming System Overview

**Server:** `SFarmingSystem` (SGlobalObjectSystem derivative, runs server-side only)
**Plant object:** `SPlantGlobalObject` per tile, stored in `gos_farming.bin`

### Plant Lifecycle
`plow` -> `seeded` (seed planted) -> grows through `nbOfGrow` stages -> `hasVegetable` (harvestable) -> `hasSeed` (seed-bearing) -> `rotten` -> `destroyed`

### Per-Plant ModData Fields
| Field | Type | Default | Purpose |
|-|-|-|-|
| state | string | "plow" | Lifecycle state |
| nbOfGrow | int | -1 | Current growth stage |
| typeOfSeed | string | "none" | Seed type key into farming_vegetableconf.props |
| health | int | 37-64 | Plant health (moon phase dependent at planting) |
| waterLvl | float | 0 | Current water level (0-100) |
| waterNeeded | float | 0 | Minimum water threshold |
| waterNeededMax | float | nil | Maximum water threshold (overwatering) |
| fertilizer | int | 0 | Fertilizer charges remaining |
| mildewLvl | int | 0 | Mildew disease (0-100) |
| aphidLvl | int | 0 | Aphid infestation (0-100) |
| fliesLvl | int | 0 | Fly infestation (0-100) |
| slugsLvl | int | 0 | Slug infestation (0-100) |
| hasWeeds | bool | false | Adjacent vegetation present |
| cursed | bool | false | Planted in risky/bad month |
| bonusYield | bool | false | Compost bonus applied |
| exterior | bool | true | Is outside |
| naturalLight | float | nil | Light level modifier |

### Initial Health (Moon Phase)
| Moon Cycle | Health Range |
|-|-|
| Ascending (4-17) | 47-53 |
| Full Moon (18-21) | 57-63 |
| Descending (others) | 37-43 |

---

## 2. Plant Properties - All Crops

**Source:** `farming_vegetableconf_vegetables.lua`

| Crop | waterLvl | waterNeeded | timeToGrow | minVeg | maxVeg | maxAuth | harvestLvl | Sow Months | Special |
|-|-|-|-|-|-|-|-|-|-|
| Barley | 30 | 70 | 432 | 2 | 4 | 8 | 6 | Aug-Oct | coldHardy, scythe |
| BellPepper | 70 | 70 | 292 | 2 | 4 | 8 | 5 | Apr-Jun | |
| Broccoli | 70 | 70 | 292 | 2 | 4 | 8 | 5 | Feb-Jul | mothFood |
| Cabbages | 80 | 80 | 292 | 2 | 4 | 8 | 5 | Feb-Jul | coldHardy, mothFood |
| Carrots | 30 | 70 | 432 | 3 | 6 | 15 | 5 | Feb-Jul | |
| Cauliflower | 70 | 70 | 292 | 2 | 4 | 8 | 5 | Feb-Apr | mothFood |
| Corn | 30 | 70 | 432 | 2 | 4 | 8 | 5 | Mar-May | |
| Cucumber | 70 | 70 | 432 | 2 | 4 | 8 | 5 | Mar-May | |
| Flax | 30 | 70 | 432 | 2 | 4 | 8 | 6 | Aug-Oct | coldHardy, scythe |
| Garlic | 30 | 70 | 1152 | 2 | 4 | 8 | 5 | Jul-Sep | aphidsBane, slugsProof, coldHardy |
| Greenpeas | 70 | 80 | 292 | 2 | 4 | 8 | 5 | Feb-Apr | slugsProof, mothFood |
| Hemp | 30 | 70 | 960 | 2 | 4 | 8 | 6 | Aug-Oct | |
| Hops | 30 | 70 | 960 | 3 | 4 | 9 | 6 | Aug-Oct | |
| Kale | 70 | 70 | 292 | 2 | 4 | 8 | 5 | Feb-Aug | coldHardy, growBack, mothFood |
| Lettuce | 70 | 80 | 292 | 2 | 4 | 8 | 5 | Feb-Apr,Jul-Sep | |
| Onion | 30 | 70 | 432 | 2 | 4 | 8 | 5 | Feb-Mar | aphidsBane, fliesBane, slugsProof |
| Potatoes | 60 | 70 | 432 | 3 | 4 | 9 | 5 | Feb-Apr | slugsProof, mothFood |
| Pumpkin | 70 | 70 | 432 | 2 | 4 | 8 | 5 | Mar-May | |
| Radishes | 40 | 70 | 144 | 4 | 9 | 15 | 5 | Feb-Aug | slugsProof, fastest crop |
| Rye | 30 | 70 | 432 | 2 | 4 | 8 | 6 | Aug-Oct | coldHardy, scythe |
| Soybeans | 60 | 70 | 432 | 2 | 4 | 8 | 5 | Mar-May | |
| Spinach | 70 | 70 | 292 | 2 | 4 | 8 | 5 | Feb-Jul | mothFood |
| Strawberry | 80 | 80 | 360 | 4 | 6 | 14 | 6 | Feb-Apr | growBack |
| SugarBeets | 40 | 70 | 292 | 4 | 9 | 15 | 5 | Feb-Jul | mothFood |
| Sunflower | 30 | 70 | 432 | 2 | 4 | 8 | 5 | Mar-May | |
| SweetPotato | 60 | 70 | 432 | 3 | 4 | 9 | 5 | May-Jul | |
| Tobacco | 70 | 70 | 866 | 2 | 4 | 8 | 5 | Mar-Jul | mothFood, slowest non-herb |
| Tomato | 70 | 80 | 360 | 4 | 5 | 10 | 6 | Apr-Jun | slugsProof, mothFood |
| Turnip | 60 | 70 | 292 | 3 | 4 | 9 | 5 | May-Oct | |
| Watermelon | 70 | 80 | 432 | 2 | 4 | 8 | 5 | Mar-May | |
| Wheat | 30 | 70 | 432 | 2 | 4 | 8 | 6 | Aug-Oct | coldHardy, scythe |
| Zucchini | 70 | 70 | 432 | 2 | 4 | 8 | 5 | Mar-May | |

**Key:** `timeToGrow` = hours per growth stage (before sandbox multiplier). `growBack` = regrows after harvest (stage resets). `coldHardy` = survives winter. Companion plant traits: `aphidsBane`, `fliesBane`, `slugsBane`/`slugsProof`, `mothBane`, `rabbitBane`, `deerBane`.

---

## 3. Plant Properties - Herbs & Flowers

**Source:** `farming_vegetableconf_herbs.lua`

Herbs grow faster (3-4 stages vs 5-6), many have `growBack` and companion plant properties.

| Herb/Flower | waterLvl | timeToGrow | Stages | Sow Months | growBack | Companion Traits |
|-|-|-|-|-|-|-|
| Basil | 80 | 484 | 3/4 | Mar-May | yes | fliesBane |
| BlackSage | 60 | 484 | 3/4 | Mar-Aug | no | - |
| BroadleafPlantain | 60 | 484 | 3/4 | Mar-Aug | no | - |
| Chamomile | 80 | 484 | 3/4 | Mar-May | yes | isFlower |
| Chives | 60 | 484 | 3/4 | Mar-Aug | yes | aphidsBane, slugsProof |
| Cilantro | 70 | 484 | 3/4 | Mar-May | yes | slugsProof |
| Comfrey | 60 | 484 | 3/4 | Mar-Aug | no | - |
| CommonMallow | 60 | 484 | 3/4 | Mar-Aug | no | - |
| Habanero | 70 | 487 | 3/4 | Apr-Jun | no | - |
| Jalapeno | 70 | 487 | 3/4 | Apr-Jun | no | - |
| Lavender | 80 | 484 | 3/4 | Mar-May | yes | isFlower |
| Leek | 70 | 1203 | 3/4 | Mar-Sep | no | aphidsBane, slugsProof, coldHardy, rabbitBane |
| LemonGrass | 70 | 484 | 3/4 | Mar-Sep | yes | aphidsBane, slugsBane, mothBane, rabbitBane, deerBane |
| Marigold | 80 | 484 | 3/4 | Mar-May | yes | aphidsBane, fliesBane, isFlower |
| Mint | 70 | 484 | 3/4 | Feb-Apr | yes | - |
| Oregano | 60 | 484 | 3/4 | Feb-Apr | yes | slugsProof, mothBane, deerBane |
| Parsley | 70 | 484 | 3/4 | Feb-Apr | yes | slugsProof |
| Poppies | 80 | 484 | 3/4 | Mar-May | yes | - |
| Rosemary | 30 | 1444 | 3/4 | Mar-Sep | yes | slugsBane, aphidsBane, mothBane, fliesBane, isFlower |
| Roses | 80 | 484 | 3/4 | Mar-May | yes | isFlower |
| Sage | 30 | 721 | 3/4 | Feb-Apr | yes | fliesBane, mothBane |
| Thyme | 30 | 484 | 3/4 | Feb-Apr | yes | aphidsBane, mothBane |
| WildGarlic | 30 | 1152 | 5/6 | Jul-Sep | no | aphidsBane, slugsProof, coldHardy, mothBane, rabbitBane |

**Best companion plants** (most pest defenses): Rosemary (4), LemonGrass (5), Garlic/WildGarlic/Onion (3+).

---

## 4. Growth Mechanics

### Growth Cycle
1. Planted seed: `nbOfGrow = 0`, state = "seeded"
2. Every tick, if `hoursElapsed >= nextGrowing`, plant advances one stage
3. `nextGrowing = currentHours + (timeToGrow / sandboxSpeed) + randomOffset(-12..+12)`
4. At `harvestLevel`: plant gains `hasVegetable = true`
5. At `fullGrown`: plant gains `hasSeed = true`
6. Past `fullGrown`: plant rots

### Harvest Yield Formula
```
baseVeg = ZombRand(minVeg + healthMod, maxVeg + healthMod + 1)
healthMod = floor((health - 50) / 10)
pestMod = floor(aphidLvl/10) + floor(slugsLvl/10)
finalVeg = baseVeg - pestMod
if bonusYield and not cursed: finalVeg = max(finalVeg, reroll)
if ZombRand(10) < farmingSkill: finalVeg += farmingSkill
finalVeg = floor(finalVeg * FarmingAmountNew)
min = 1
```

### Farming XP
On harvest: `xp = health/2 + (badCare ? -15 : +25)`, clamped 1-100. Added via `addXp(player, Perks.Farming, xp)`.

### Flowers
Harvesting flowers reduces Unhappiness, Boredom, and Stress by `numberOfVeg / 2`.

---

## 5. Disease System

Four diseases: Mildew, Aphids, Flies, Slugs. Each ranges 0-100.

### Disease Check
Every growth stage, `diseaseThis()` runs. Base chance depends on water deficit and `PlantResilience` sandbox setting. Weeds and "cursed" status increase chance.

| PlantResilience | Chance Modifier |
|-|-|
| 1 (Very High) | -8 |
| 2 (High) | -4 |
| 3 (Normal) | 0 |
| 4 (Low) | +4 |
| 5 (Very Low) | +8 |

### Disease Progression
Disease levels rise each water cycle. At level:
- <10: no growth penalty
- 10-29: adds diseaseLvl hours to next growth
- 30-59: plant stops growing
- 60+: plant dies

### Companion Planting
Adjacent plants (within 1 tile) with pest-bane traits protect neighbors after reaching growth stage 3+:
- `aphidsBane`: blocks aphid spread (Garlic, Onion, Chives, Marigold, Rosemary, Thyme, LemonGrass)
- `fliesBane`: blocks fly spread (Basil, Sage, Onion, Marigold, Rosemary)
- `slugsBane`: blocks slug spread (Rosemary, LemonGrass)
- Proof traits (e.g. `slugsProof`) make the plant itself immune, not neighbors

---

## 6. Water & Health System

### Water Drain
Every `hourForWater` hours, all plants lose water. Frequency by `PlantResilience`:

| PlantResilience | Hours Between Drain |
|-|-|
| 1 (Very High) | 12 |
| 2 (High) | 8 |
| 3 (Normal) | 5 |
| 4 (Low) | 3 |
| 5 (Very Low) | 2 |

### Rain Watering
`waterLvl += 30 * precipitationIntensity / waterFactor` (waterFactor 2x if weeds present). Capped at 100.

### Health Changes (every 2 hours)
Health modifiers are divided or multiplied by `badMultiplier`:
- `badMultiplier` starts at 1
- Cursed: x2
- Weeds: x2
- Low natural light: divided by light value

| Condition | Health Change |
|-|-|
| Sunny + exterior + good month | +1 / badMult |
| Sunny + interior (houseplant/greenhouse) | +0.25 / badMult |
| Good water range | +0.4 / badMult |
| Temp <= 10C (not coldHardy) | -0.5 * badMult |
| Slightly under/overwatered | -0.2 * badMult |
| Severely under/overwatered | -0.5 * badMult |
| Interior + not houseplant/greenhouse | -1 * badMult |
| Winter + exterior + houseplant | -1.5 * badMult |
| Bad month + not badMonthHardy | -3 * badMult |

---

## 7. Foraging System Overview

**Source:** `media/lua/shared/Foraging/forageSystem.lua`, `forageDefinitions.lua`

The foraging system places hidden icons on the map in zones. Players search while walking to reveal items. Each item has skill requirements, zone weights, seasonal availability, and weather modifiers.

### Item Definition Fields
| Field | Purpose |
|-|-|
| skill | Minimum Foraging level to see item |
| perks | Required perk(s), default PlantScavenging |
| xp | XP reward (spotting = xp/3) |
| zones | Per-zone roll counts (NOT percent) |
| months/bonusMonths/malusMonths | Seasonal availability |
| poisonChance/poisonPowerMin/Max | Poisonous item chance |
| rainChance/snowChance/dayChance/nightChance | Weather modifiers (percent) |
| categories | Which category groups the item belongs to |

---

## 8. Foraging Zones

**Source:** `forageZones.lua`

| Zone | Density Min | Density Max | Refill%/day | Abundance Setting |
|-|-|-|-|-|
| DeepForest | 8 | 10 | 7 | NatureAbundance |
| Forest | 8 | 10 | 7 | NatureAbundance |
| OrganicForest | 8 | 10 | 5 | NatureAbundance |
| BirchForest | 6 | 8 | 5 | NatureAbundance |
| Vegitation | 6 | 8 | 5 | NatureAbundance |
| FarmLand | 5 | 7.5 | 5 | NatureAbundance |
| Farm | 5 | 7.5 | 5 | NatureAbundance |
| TownZone | 3 | 5 | 3 | NatureAbundance |
| TrailerPark | 1.5 | 5 | 3 | NatureAbundance |
| ForagingNav | 3 | 5 | 3 | NatureAbundance |

Mixed forest zones (BirchMixForest, PHMixForest, FarmMixForest, FarmForest) inherit loot tables from contained biomes at fractional weights.

---

## 9. Foraging Categories

**Source:** `forageCategories.lua`

| Category | Type | ID Level | Top Zones (roll count) |
|-|-|-|-|
| Firewood | Materials | 0 | All Forest 80, Vegitation 50 |
| Stones | Materials | 0 | ForagingNav 120, Vegitation 30 |
| Berries | Food | 3 | DeepForest/Forest 30, Vegitation 20 |
| Mushrooms | Food | 3 | OrganicForest 50, BirchForest 40, Forest 30 |
| WildPlants | Food | 4 | BirchForest/OrganicForest 35, Forest 20 |
| WildHerbs | Food | 4 | BirchForest 15, OrganicForest 12.5 |
| Insects | Animals | 4 | BirchForest/OrganicForest 35, Forest 25 |
| FishBait | Animals | 4 | OrganicForest 40, BirchForest/PH/PR 30 |
| Trash | Other | 4 | TownZone/TrailerPark 45, ForagingNav 35 |
| Animals | Animals | 5 | Vegitation 25, Forest types 15, FarmLand 20 |
| Crops | Food | 5 | FarmLand 25, Vegitation 10 |
| MedicinalPlants | Medicinal | 6 | OrganicForest 35, DeepForest 30, BirchForest 25 |
| Fruits | Food | 7 | FarmLand 25, DeepForest/Forest 15 |
| Vegetables | Food | 7 | FarmLand 15, Vegitation 15, TownZone 10 |
| ForestRarities | Other | 8 | Forest types 1 |
| CraftingMaterials | Other | 8 | TownZone/TrailerPark 20, ForagingNav 13 |
| Ammunition | Other | 8 | TownZone/TrailerPark 3, ForagingNav 2 |
| Medical | Other | 8 | TownZone/TrailerPark 3 |

Weather modifiers: Mushrooms +20% rain +50% after-rain; MedicinalPlants +50% rain; Insects +100% night; FishBait +50% rain +100% night.

---

## 10. Fishing System

**Source:** `media/lua/shared/Fishing/`

### Fish Species
| Species | Item Type | Max Length (cm) | Max Weight (kg) | River | Lake | Predator |
|-|-|-|-|-|-|-|
| Largemouth Bass | Base.LargemouthBass | 51 | 2.8 | yes | yes | no |
| Smallmouth Bass | Base.SmallmouthBass | 41 | 2.3 | yes | yes | no |
| White Bass | Base.WhiteBass | 38 | 1.5 | yes | yes | no |
| Spotted Bass | Base.SpottedBass | 38 | 1.8 | yes | yes | no |
| Striped Bass | Base.StripedBass | 76 | 9.0 | yes | yes | no |
| Bluegill | Base.Bluegill | 20 | 1.4 | yes | yes | no |
| White Crappie | Base.WhiteCrappie | 30 | 1.0 | yes | yes | no |
| Black Crappie | Base.BlackCrappie | 25 | 1.0 | yes | yes | no |
| Redear Sunfish | Base.RedearSunfish | 20 | 1.4 | yes | yes | no |
| Yellow Perch | Base.YellowPerch | 30 | 1.0 | yes | yes | no |
| Sauger | Base.Sauger | 45 | 1.9 | yes | yes | no |
| Green Sunfish | Base.GreenSunfish | 20 | 1.4 | yes | yes | no |
| Walleye | Base.Walleye | 80 | 9.0 | yes | yes | no |
| Freshwater Drum | Base.FreshwaterDrum | 76 | 4.5 | yes | yes | no |
| Blue Catfish | Base.BlueCatfish | - | - | yes | yes | no |
| Channel Catfish | Base.ChannelCatfish | - | - | yes | yes | no |
| Flathead Catfish | Base.FlatheadCatfish | - | - | yes | yes | no |
| Muskellunge | Base.Muskellunge | - | - | yes | yes | yes |
| Alligator Gar | Base.AligatorGar | - | - | yes | yes | yes |
| Paddlefish | Base.Paddlefish | - | - | yes | yes | no |
| Bait Fish | Base.BaitFish | - | - | yes | yes | no |

### Skill Size Limits (max catchable weight in kg by level)
| Level | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|-|-|-|-|-|-|-|-|-|-|-|-|
| MaxKG | 1.4 | 1.5 | 1.9 | 2.2 | 2.3 | 2.8 | 4.5 | 9 | 27 | 32 | 45 |

### Fish Size Chances (Small/Medium/Big %)
| Level | Small | Medium | Big |
|-|-|-|-|
| 0 | 95 | 5 | 0 |
| 3 | 70 | 25 | 5 |
| 5 | 48 | 40 | 12 |
| 7 | 25 | 45 | 30 |
| 10 | 10 | 40 | 50 |

Near shore: small chance increased, medium/big halved.

### Legendary Fish
At Fishing level 8+, Big fish have a 1/20 chance to become Legendary (exceeds max weight/length via trophy values).

### Trash Reduction by Skill
| Fishing Level | Trash Factor |
|-|-|
| 0-4 | 100% (full) |
| 5-6 | 80% |
| 7-8 | 60% |
| 9+ | 20% |

### Lure Categories
| Category | Example Items | Best For |
|-|-|-|
| Insect | Cricket, Grasshopper, Caterpillars | Panfish (Bluegill, Sunfish) |
| Worms | Worm, Maggots | Bass, Perch |
| Minnows | BaitFish, Tadpole | Bass, Crappie |
| Leeches | Leech, Snail, Slug | Bass, Walleye |
| Flesh | Crayfish, Shrimp, FishFillet | Catfish, large predators |
| Plant | Cheese, Bread, Dough, Corn | Bait Fish |
| Artificial | JigLure, MinnowLure | General (never consumed) |

### Rods & Lines
| Rod | Coefficient | Break Replacement |
|-|-|-|
| CraftedFishingRod | 0.8 | WoodenStick |
| FishingRod | 1.0 | FishingRodBreak |

| Line | Damage Rate |
|-|-|
| Twine | 0.3/15 = 0.020 |
| FishingLine | 0.2/15 = 0.013 |
| PremiumFishingLine | 0.1/15 = 0.007 |

### Fish Nets
Passive catching (placed in water): BaitFish, Frog, Mussels, Seaweed, Crayfish, Tadpole. With bait: adds BlueCatfish, ChannelCatfish, FlatheadCatfish.

---

## 11. Trapping System

**Source:** `media/lua/server/Traps/TrapDefinition.lua`, `media/lua/shared/Traps/TrapSystem.lua`

### Trap Types
| Trap | Item Type | Strength | Targets |
|-|-|-|-|
| Trap Crate | Base.TrapCrate | 15 | Rabbit, Squirrel, Raccoon |
| Trap Box | Base.TrapBox | 15 | Rabbit, Squirrel, Raccoon |
| Cage Trap | Base.TrapCage | 20 | Rabbit, Squirrel, Raccoon |
| Snare Trap | Base.TrapSnare | 10 | Rabbit, Squirrel, Raccoon |
| Stick Trap | Base.TrapStick | 15 | Bird only |
| Mouse Trap | Base.TrapMouse | 50 | Mouse, Rat only |

### Animals
| Animal | Item | Size Range | Active Hours | Escape Strength |
|-|-|-|-|-|
| Rabbit | Base.DeadRabbit | 30-100 | 19:00-05:00 | 24h |
| Squirrel | Base.DeadSquirrel | 10-60 | 19:00-05:00 | 20h |
| Bird | Base.DeadBird | 2-32 | All hours | - |
| Mouse | Base.DeadMouse | 1-10 | All hours | - |
| Rat | Base.DeadRat | 5-25 | All hours | - |
| Raccoon | Base.DeadRabbit* | 30-100 | 19:00-05:00 | 24h |

*Raccoon uses rabbit item (TODO placeholder in code).

Rabbit, Mouse, Rat, and Raccoon can be caught alive (for animal husbandry).

### Zone Chances (per animal, higher = better)
| Zone | Rabbit | Squirrel | Bird | Mouse | Rat | Raccoon |
|-|-|-|-|-|-|-|
| DeepForest | 15 | 15 | 20 | 10 | 10 | 15 |
| Forest | 12 | 12 | 20 | 10 | 10 | 12 |
| Vegitation | 10 | 10 | 30 | 20 | 20 | 10 |
| Farm/FarmLand | - | - | 35 | 60 | 50 | - |
| TownZone | 2 | 2 | 30 | 50 | 30 | 2 |
| TrailerPark | 2 | 2 | 20 | 60 | 40 | 2 |

### Best Baits (highest chance value)
| Animal | Best Bait (chance) |
|-|-|
| Rabbit | Carrots (45), Lettuce/BellPepper/Cabbage (40) |
| Squirrel | PeanutButter/Cereal (45), Orange/Peanuts/Apple/Corn (40) |
| Bird | Insects/Bread/Worm (50), Cereal/Corn (45) |
| Mouse | Cheese (60), ProcessedCheese (55), PeanutButter (40) |
| Rat | Cheese (60), ProcessedCheese (55), PeanutButter (40) |
| Raccoon | Carrots (45), Lettuce/BellPepper/Cabbage (40) |

### Trapping Skill Effect
Player's Trapping skill is stored in `modData.trappingSkill` at trap placement time. Higher skill increases catch rate (checked server-side in trap update logic).

---

## 12. Sandbox Settings

| Setting | Affects | Values |
|-|-|-|
| PlantResilience | Water drain frequency, disease chance | 1=VeryHigh, 2=High, 3=Normal, 4=Low, 5=VeryLow |
| PlantGrowingSeasons | Whether bad months kill crops | true/false |
| KillInsideCrops | Interior plants die (unless houseplant/greenhouse) | true/false |
| FarmingSpeedNew | Growth time divisor | float (higher = faster) |
| FarmingAmountNew | Harvest yield multiplier | float |
| NatureAbundance | Foraging icon density in natural zones | sandbox multiplier |
| OtherLoot | Foraging density in urban zones | sandbox multiplier |
| XPMultiplier | Global XP gain multiplier | float |
