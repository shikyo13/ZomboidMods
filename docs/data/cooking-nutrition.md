# Cooking & Nutrition System - PZ Data Map
Source: media/scripts/generated/items/food.txt | zombie/characters/BodyDamage/Nutrition.java | zombie/characters/CharacterStat.java | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Nutrition Class (Java) | 18-63 |
| 2 | Character Stats (Hunger/Thirst/Sickness) | 64-85 |
| 3 | Food Item Properties | 86-171 |
| 4 | Cooking Mechanics | 172-219 |
| 5 | Poison and Food Sickness | 220-260 |
| 6 | Food Freshness and Decay | 261-303 |
| 7 | Evolved Recipe Nutritional Contribution | 304-337 |
| 8 | Weight and Metabolic System | 338-395 |

---

## 1. Nutrition Class (Java)

Source: `zombie.characters.BodyDamage.Nutrition` (decompiled from projectzomboid.jar)

The Nutrition class tracks four macronutrients plus weight. It is attached to each IsoPlayer
and updated every game tick when `SandboxOptions.nutrition` is enabled.

### Macronutrient Fields

| Field | Range | Default | Decay Rate (per game-second) |
|-|-|-|-|
| calories | -2200 to 3700 | 800 | varies by activity (see below) |
| carbohydrates | -500 to 1000 | 0 | 0.0035 |
| lipids (fats) | -500 to 1000 | 0 | 0.00113 |
| proteins | -500 to 1000 | 0 | 0.00086 |

Macro decay rates are identical for male and female characters (despite named fields in code).

### Calorie Burn Rates

Calories decrease based on activity state. All rates are per game-second, scaled by
`weight / 80.0` (heavier characters burn faster):

| Activity State | Base Rate | Modifier | Effective Rate |
|-|-|-|-|
| Sleeping | 0.003 | 1.0 * coldMulti | lowest burn |
| Idle / standing | 0.016 | 1.0 * coldMulti | normal resting burn |
| Walking | 0.13 | 0.6 | moderate burn |
| Running | 0.13 | 1.0 | high burn |
| Sprinting | 0.13 | 1.3 | highest burn |
| Combat/climbing | 0.13 | 8.0 (via action modifier) | extreme burst |

The `coldMulti` factor comes from the thermoregulation system - being cold increases
calorie expenditure.

Timed actions (carpentry, cooking, etc.) set a `caloriesModifier` on their BaseAction,
which overrides the idle modifier while the action runs.

### Calorie Budget

At rest, burning 0.016/s over a 24h day (86400 game-seconds) with 80kg weight:

- Daily idle burn: ~1382 calories
- A character eating 1400+ calories/day of balanced food stays weight-neutral
- Exercise, cold weather, and heavy activity can double or triple daily needs

## 2. Character Stats (Hunger/Thirst/Sickness)

Source: `zombie.characters.CharacterStat` (decompiled)

The Stats system uses a registry of named stats with min/max/default values.
Food-relevant stats:

| Stat | Min | Max | Default | Notes |
|-|-|-|-|-|
| Hunger | 0.0 | 1.0 | 0.0 | 0 = full, 1.0 = starving |
| Thirst | 0.0 | 1.0 | 0.0 | 0 = hydrated, 1.0 = dehydrated |
| FoodSickness | 0.0 | 100.0 | 0.0 | Nausea from bad food or smoking |
| Sickness | 0.0 | 1.0 | 0.0 | General illness level |
| Poison | 0.0 | 100.0 | 0.0 | Poisoning from toxic items |
| Unhappiness | 0.0 | 100.0 | 0.0 | Affected by food quality |
| Boredom | 0.0 | 100.0 | 0.0 | Affected by repetitive eating |
| Stress | 0.0 | 1.0 | 0.0 | Smoking relieves this |
| Pain | 0.0 | 100.0 | 0.0 | Can result from food sickness |

Hunger and Thirst are 0-1 floats (inverted scale: 0 = satisfied).
Food items decrease these values via HungerChange and ThirstChange (negative = reduces hunger).

## 3. Food Item Properties

Source: `media/scripts/generated/items/food.txt` (722 food item definitions, 15504 lines)

### All Food Item Properties

| Property | Type | Count | Description |
|-|-|-|-|
| ItemType | string | 722 | Always `base:food` for food items |
| Weight | float | 722 | Item weight in kg |
| HungerChange | float | 606 | Hunger reduction (negative = feeds player). Range: -60 to +10 |
| Calories | float | 596 | Calorie content added to Nutrition.calories |
| Carbohydrates | float | 596 | Carbs added to Nutrition.carbohydrates |
| Lipids | float | 596 | Fats added to Nutrition.lipids |
| Proteins | float | 596 | Protein added to Nutrition.proteins |
| DaysFresh | int | 497 | Days before food starts decaying |
| DaysTotallyRotten | int | 497 | Days until completely rotten |
| ThirstChange | float | 112 | Thirst reduction (negative = hydrates) |
| UnhappyChange | int | 292 | Unhappiness change (negative = happier, positive = sadder) |
| BoredomChange | int | 5 | Boredom change (negative = less bored) |
| StressChange | int | 11 | Stress change (negative = less stressed, smoking items) |
| FoodSicknessChange | int | 8 | Food sickness delta (positive = nauseating, negative = settling) |
| IsCookable | bool | 251 | Whether item can be placed on a heat source |
| MinutesToCook | int | 249 | Minutes of cooking until "cooked" state |
| MinutesToBurn | int | 246 | Minutes of cooking until "burnt" state |
| DangerousUncooked | bool | 81 | Eating raw causes food sickness |
| Spice | bool | 109 | Treated as seasoning in evolved recipes (doesn't count toward MaxItems) |
| GoodHot | bool | 148 | Provides happiness bonus when eaten hot |
| BadCold | bool | 61 | Provides unhappiness penalty when eaten cold |
| CantEat | bool | 96 | Cannot be eaten directly (e.g., raw grain, animal feed) |
| CantBeFrozen | bool | 51 | Item cannot be frozen |
| Packaged | bool | 129 | Item comes in packaging (affects spoilage display) |
| CannedFood | bool | 41 | Preserved canned food (does not spoil until opened) |
| PoisonPower | int | 4 | Poison strength (only on toxic insects: millipedes, caterpillars) |
| PoisonDetection | int | 0 | Difficulty to detect poison (not currently used on vanilla items) |
| FoodType | string | 362 | Food category for moodlet variety system (see below) |
| EvolvedRecipe | string | 372 | Templates and hunger values for evolved recipes |
| EvolvedRecipeName | string | 172 | Display name when shown as evolved recipe ingredient |
| ReplaceOnUse | string | 110 | Item replaced with this after eating (e.g., empty jar, pan) |
| EatType | string | 266 | Eating animation type (Plate, Popcan, Candrink, Cigarettes, etc.) |
| OnEat | callback | 19 | Java callback when eaten (e.g., RecipeCodeOnEat.consumeNicotine) |
| OnCooked | callback | 11 | Java callback when cooked |
| OnCreate | callback | 21 | Java callback when item is created |
| RemoveUnhappinessWhenCooked | bool | 36 | Cooking removes UnhappyChange penalty |
| RemoveNegativeEffectOnCooked | bool | 5 | Cooking removes all negative moodlet effects |
| BadInMicrowave | bool | 115 | Item cannot be cooked in microwave |
| CustomContextMenu | string | 33 | Override context menu text (Drink, Smoke, etc.) |
| CookingSound | string | 198 | Sound while cooking (FryingFood, BoilingFood) |
| HerbalistType | string | 18 | Herbalist skill identification category |
| FishingLure | bool | 41 | Can be used as fishing bait |
| AnimalFeedType | string | 22 | Animal husbandry feed category (Seeds, Grass, etc.) |
| UseDelta | float | ~2 | Fraction consumed per use (for multi-use items) |
| DoubleClickRecipe | string | 4 | Recipe triggered on double-click |
| OpeningRecipe | string | 18 | Recipe used to open the item (canned food) |
| ReplaceOnRotten | string | 8 | Replacement item when fully rotten |
| PourType | string | 49 | Container pouring animation type |
| IsDung | bool | 10 | Animal dung item (food system, not edible) |
| Eattime | int | 17 | Eating duration in ticks (smoking items have long values: 460-920) |

### FoodType Categories (43 unique)

FoodType controls the "variety" moodlet system - eating the same FoodType repeatedly
increases boredom/unhappiness. Top categories:

| FoodType | Count | Examples |
|-|-|-|
| Vegetables | 50 | Tomato, Potato, Cabbage, Carrots |
| NoExplicit | 49 | Condiments, mayo, butter, misc |
| Herb | 48 | Lemongrass, Rosemary, Basil |
| Candy | 25 | Chocolate bars, gummies, lollipops |
| Insect | 20 | Crickets, grasshoppers, caterpillars |
| Fruits | 17 | Apple, Orange, Banana |
| Berry | 13 | Strawberry, Blueberry, wild berries |
| Seafood | 10 | Shrimp, crawfish, crab |
| Meat | 10 | Generic meat cuts |
| Bean | 10 | Various bean types |
| Egg | 9 | Chicken egg, turkey egg, etc. |
| Poultry | 9 | Chicken, turkey cuts |
| Mushroom | 9 | Edible and poisonous mushrooms |
| Fish | 6 | Catfish, bass, trout, etc. |
| Beef | 6 | Beef cuts, ground beef |
| Sausage | 6 | Hot dogs, various sausages |
| Bread | 5 | Bread loaf, slices, baguette |
| Rice | 5 | White rice, brown rice |
| Seed | 4 | Flaxseed, sunflower seeds |

## 4. Cooking Mechanics

### Cooking State Progression

Items with `IsCookable = true` progress through states on a heat source:

```
Raw -> Cooked -> Burnt
```

| State | Trigger | Effect |
|-|-|-|
| Raw/Uncooked | Default state | DangerousUncooked items cause food sickness |
| Cooked | After MinutesToCook minutes | Full nutritional value, safe to eat |
| Burnt | After MinutesToBurn minutes | Reduced nutrition, causes unhappiness |

Typical cooking times:
- Quick items (eggs, bacon bits): 10-15 min cook, 30-35 min burn
- Standard items (meat, vegetables): 15-20 min cook, 35-50 min burn
- Slow items (large roasts): 20-30 min cook, 50+ min burn

### Cooking Effects on Food Properties

When food transitions to cooked state:

- `RemoveUnhappinessWhenCooked = true`: UnhappyChange set to 0 (e.g., raw potato has +5 unhappy, cooked has 0)
- `RemoveNegativeEffectOnCooked = true`: All negative mood effects removed
- `DangerousUncooked = true` items: raw eating causes food sickness, cooked is safe
- `GoodHot = true`: recently cooked items give a happiness bonus
- `BadCold = true`: items give unhappiness when eaten cold

### Heat Sources

Items can be cooked on:
- Oven / Stove (house appliances)
- Microwave (unless `BadInMicrowave = true`)
- Campfire
- BBQ grill
- Barrel oven (crafted)
- Simple cooking pit (entity workstation, B42)
- Antique oven

### Multi-Use Foods

Some items are consumed in portions via `UseDelta`:
- `UseDelta = 0.16` means each use consumes 16% of the item (6 uses total)
- Common on condiment jars (mayo, remoulade, peanut butter)

## 5. Poison and Food Sickness

### DangerousUncooked

81 items have `DangerousUncooked = true`. Eating these raw triggers food sickness.
Applies to all raw meats, poultry, fish, and eggs. Cooking neutralizes the danger.

### PoisonPower

Only 4 vanilla items have PoisonPower (all toxic insects):
- Millipede (PoisonPower = 1)
- Millipede variant (PoisonPower = 1)
- Monarch Caterpillar (PoisonPower = 1)
- Swallowtail Caterpillar (PoisonPower = 1)

PoisonPower adds directly to the Poison stat (0-100 range). The Herbalist trait helps
identify poisonous items before consumption.

### FoodSicknessChange

8 items modify the FoodSickness stat directly:

| Item | FoodSicknessChange | Notes |
|-|-|-|
| LemonGrass | -12 | Herb that reduces nausea |
| Comfrey (dried) | -1 | Mild anti-nausea herb |
| Cigar | +28 | Highest sickness from smoking |
| Cigarillo | +21 | High sickness |
| Pipe variants | +21 | High sickness |
| CigaretteSingle | +14 | Moderate sickness |
| CigaretteRolled | +14 | Moderate sickness |

FoodSickness stat range is 0-100. At high values, the character vomits (losing consumed
nutrition) and suffers pain/unhappiness moodlets.

### Rotten Food

Eating rotten food causes food sickness and unhappiness. The game tracks freshness
internally, and rotten food has significantly reduced (or negative) nutritional value.
Items with `AllowRottenItem` flag in recipes can accept rotten ingredients.

## 6. Food Freshness and Decay

### DaysFresh / DaysTotallyRotten

497 food items define freshness timers. The item progresses through stages:

```
Fresh -> Stale -> Rotten -> Totally Rotten
```

| Timer | Description |
|-|-|
| DaysFresh | Days at full quality (counter starts from item creation) |
| DaysTotallyRotten | Days until item is completely rotten and inedible |

The period between DaysFresh and DaysTotallyRotten is the "going bad" window where
nutritional value degrades gradually.

### Freshness Examples

| Item | DaysFresh | DaysTotallyRotten | Ratio |
|-|-|-|-|
| Potato | 28 | 280 | Root vegetables last very long |
| Canned food | N/A | N/A | Does not spoil until opened |
| Tomato | 4 | 12 | Moderate shelf life |
| Bacon | 3 | 5 | Short shelf life (meat) |
| Cabbage | 2 | 4 | Very short (leafy greens) |
| Strawberry | 2 | 5 | Short (berries) |
| Herbs (dried) | no decay | no decay | Dried items don't rot |

### Preservation Methods

- **Freezing**: Items in a powered freezer pause decay (unless `CantBeFrozen = true`)
- **Canning/Jarring**: The `MakeJar` recipe preserves vegetables with vinegar and salt (Cooking 8, learned)
- **Drying**: Herbs and grains can be dried (removes DaysFresh/DaysTotallyRotten)
- **Canned food** (`CannedFood = true`): 41 items that do not decay until opened via recipe

### Temperature Effects

Food left in hot environments decays faster. Refrigerators slow decay.
Freezers stop it entirely while powered. Items track a `FreezingTime` that determines
how long the frozen state persists after removal from a freezer.

## 7. Evolved Recipe Nutritional Contribution

When ingredients are added to an evolved recipe, their nutritional properties transfer:

### Transfer Rules

1. **Hunger**: The `EvolvedRecipe` hunger value is used (e.g., `Soup:12` provides -12 hunger change)
2. **Calories/Carbs/Lipids/Proteins**: Transferred from the ingredient item's properties
3. **Freshness**: The recipe result tracks the worst (oldest) ingredient's freshness
4. **Cooked state**: If `Cookable = true`, the mixed item must be cooked. Cooking applies
   to all ingredients simultaneously
5. **Spices**: Items with `Spice = true` can be added beyond MaxItems limit and contribute
   their nutrition as seasoning

### Nutritional Stacking

A soup with 6 ingredients stacks all their nutritional values:

Example Potato Soup (6 potatoes):
- HungerChange: 6 * -18 = -108 (from EvolvedRecipe value `Soup:18`)
- Calories: 6 * 70 = 420
- Carbohydrates: 6 * 15 = 90
- Proteins: 6 * 3 = 18
- Lipids: 6 * 0.15 = 0.9

Plus any spices added on top. Evolved recipes are the most calorie-efficient
food source in the game.

### Conditional Ingredients

The `|Cooked` suffix restricts ingredients:
- `Sandwich:4|Cooked` means bacon can only be added to a sandwich if pre-cooked
- Without the suffix, raw ingredients are accepted (for recipes that will be cooked)

## 8. Weight and Metabolic System

Source: `Nutrition.updateWeight()` (decompiled)

### Weight Range and Traits

| Weight (kg) | Trait Applied | Starting Weight |
|-|-|-|
| <= 50 | Emaciated (FATAL - takes damage) | Emaciated trait |
| 50-65 | Very Underweight | Very Underweight trait |
| 65-75 | Underweight | Underweight trait |
| 75-85 | Normal | Default: 80kg |
| 85-100 | Overweight | Overweight trait |
| >= 100 | Obese | Obese trait |

Minimum weight is 35kg - at this floor the character takes health damage
(ReduceGeneralHealth) and the "LOWWEIGHT" damage event fires.

### Weight Gain Mechanics

Weight increases when `calories > caloriesToGainWeight`:

- Base threshold: 1000 calories
- **Weight Gain trait**: threshold reduced to 700 (gains weight easier)
- **Weight Loss trait**: threshold increased to 1800 (harder to gain)
- Threshold scales with current weight: `+((weight - 80) * 40)` calories
  (heavier = harder to gain more)

Weight gain rate: **1.3e-5 per game-second** (base), multiplied by:
- 3x if carbs > 700 OR lipids > 700 (IncWeightLot)
- 2x if carbs > 400 OR lipids > 400 (IncWeightLot)
- Scaled by `calories / 4000` (capped at 1.0)

### Weight Loss Mechanics

Weight decreases when `calories < caloriesToLoseWeight`:

- Loss threshold: `(weight - 70) * 30` (only triggers below a weight-dependent calorie level)
- Characters under 70kg have a 0 or negative threshold (always losing if calories negative)
- Weight loss rate: **8.5e-6 per game-second**, scaled by `abs(calories) / 2500` (capped at 1.0)

Weight loss is ~65% the speed of weight gain at equivalent calorie deficits.

### Fitness Interaction

The `canAddFitnessXp()` method restricts Fitness skill gains:
- Fitness >= 9: blocked if any weight trouble trait active
- Fitness >= 6: blocked if Emaciated, Obese, or Very Underweight
- Below Fitness 6: always can gain XP regardless of weight

### Practical Daily Nutrition Targets

For a normal-weight (80kg) character at rest:
- **Maintain weight**: ~1400 calories/day, balanced macros
- **Gain weight**: 2000+ calories/day, keep carbs and lipids moderate to avoid rapid fat gain
- **Lose weight**: eat below ~800 calories/day (risky - can reach Emaciated)
- Evolved recipes (soup, stew) with 4-6 ingredients easily provide 300-600 calories
- 3-4 full meals of evolved recipes per day maintains a healthy weight
