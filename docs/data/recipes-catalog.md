# Crafting Recipes - PZ Data Map
Source: media/scripts/generated/recipes/ | media/scripts/generated/evolvedrecipes.txt | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Recipe System Overview | 17-33 |
| 2 | craftRecipe Format and Properties | 34-108 |
| 3 | Input/Output Specification | 109-190 |
| 4 | Recipe Categories and Counts | 191-224 |
| 5 | Evolved Recipes | 225-295 |
| 6 | Annotated Examples | 296-377 |
| 7 | Modding: Adding Custom Recipes | 378-447 |

---

## 1. Recipe System Overview

PZ B42 uses a script-based crafting system. Recipes are defined in `.txt` files under
`media/scripts/generated/recipes/` (standard recipes) and `media/scripts/generated/entities/*/craftRecipes/`
(workstation-bound recipes). All files are wrapped in a `module Base { }` block.

Two recipe types exist:

- **craftRecipe** - explicit recipes with defined inputs/outputs, crafted from the crafting menu
- **evolvedrecipe** - freeform ingredient-adding recipes (soups, stews, sandwiches, etc.)

**Total recipe counts (B42):**
- craftRecipe (standard): ~595 across 42 recipe files
- craftRecipe (workstation/entity): ~320 across 23 entity recipe files
- evolvedrecipe: 62 definitions using 24 templates
- **Grand total: ~977 recipe definitions**

## 2. craftRecipe Format and Properties

### Basic Structure

```
module Base
{
    craftRecipe RecipeName
    {
        property = value,
        inputs
        {
            item <count> [Item.List] flags[...] mode:keep,
            -fluid <amount> [FluidType],
        }
        outputs
        {
            item <count> Module.ItemType,
        }
        itemMapper mapperName
        {
            OutputItem = InputItem,
        }
    }
}
```

### All craftRecipe Properties

| Property | Type | Description |
|-|-|-|
| timedAction | string | Animation/action played during crafting (e.g., Making, SliceFood_Surface, MixingBowl) |
| time | int | Crafting time in game ticks (roughly: ticks / 40 = seconds at 1x speed) |
| Tags | string | Semicolon-separated tags controlling craft location and behavior (see below) |
| category | string | UI category in crafting menu (Cooking, Weaponry, Carpentry, etc.) |
| NeedToBeLearn | bool | If true, recipe must be learned from a book or auto-learned |
| SkillRequired | string | Skill:Level prerequisite (e.g., Cooking:7, Maintenance:3) |
| xpAward | string | XP granted on completion (e.g., Cooking:10, Carving:30) |
| AutoLearnAll | string | Auto-learn when ALL listed skills reach level (Maintenance:3;SmallBlunt:1) |
| AutoLearnAny | string | Auto-learn when ANY listed skill reaches level (Cooking:7) |
| OnCreate | callback | Java callback on completion (RecipeCodeOnCreate.methodName) |
| OnTest | callback | Java test callback for availability (RecipeCodeOnTest.methodName) |
| Tooltip | string | Tooltip key shown in crafting UI |
| Icon | string | Override icon for the recipe in the crafting menu |

### Recipe Tags

Tags are semicolon-separated and control where/how the recipe can be performed:

| Tag | Effect |
|-|-|
| InHandCraft | Can be crafted in hand (no surface needed) |
| AnySurfaceCraft | Requires a nearby surface (table, counter) |
| CanBeDoneInDark | Can craft without light |
| CanBeDoneFromFloor | Can be done when items are on the ground |
| RightClickOnly | Only appears in right-click context menu, not crafting panel |
| RemoveResultItems | Output items are handled by OnCreate callback instead |
| CanBeDoneUnfocused | Can be crafted while doing other actions |
| CannotBeResearched | Cannot appear in research/discovery system |
| CanAlwaysBeResearched | Always available for research |
| Cooking | Tagged as a cooking recipe (affects UI filtering) |
| Farming | Tagged as farming recipe |
| Electrical | Tagged as electrical recipe |
| Health | Tagged as medical recipe |
| Survivalist | Tagged as survivalist recipe |
| Fishing | Tagged as fishing recipe |
| Packing | Tagged as packing recipe |
| Welding | Tagged as welding recipe |
| Carpentry | Tagged as carpentry recipe |
| Trapper | Tagged as trapping recipe |
| Engineer | Tagged as engineering recipe |
| Glassmaking | Tagged as glassmaking recipe |
| Pottery | Tagged as pottery recipe |
| Grindstone | Requires a grindstone workstation |

## 3. Input/Output Specification

### Input Line Format

```
item <count> [ItemList] tags[taglist] mode:<mode> flags[flaglist] mappers[mapperName]
-fluid <amount> [FluidType] categories[CategoryName] mode:mixture
```

### Input Modes

| Mode | Behavior |
|-|-|
| (default) | Item is consumed |
| mode:keep | Item is not consumed (tool usage) |
| mode:destroy | Item container is destroyed (e.g., bowl is destroyed, contents used) |
| mode:mixture | Fluid mixing mode |

### Input Item Selectors

- `[Base.ItemA;Base.ItemB]` - specific item list (semicolon-separated)
- `tags[base:tagname;base:tag2]` - match items by tag
- `[*]` - wildcard, matches any valid item
- `[25:Base.Thread_Sinew]` - count override for specific item in a list
- `-fluid <amount> [FluidType]` - fluid input (Water, CowMilk, etc.)
- `-fluid <amount> categories[Water]` - fluid by category

### Input Flags

| Flag | Purpose |
|-|-|
| Prop1 / Prop2 | Assign item to hand slot 1 or 2 for animation |
| ItemCount | Enforce exact item count |
| MayDegrade / MayDegradeLight / MayDegradeVeryLight | Tool loses condition |
| IsNotDull | Tool must not be dull (sharpness check) |
| SharpnessCheck | Check tool sharpness level |
| AllowRottenItem | Accepts rotten food items |
| AllowFrozenItem | Accepts frozen food items |
| InheritFood | Output inherits food properties (freshness, cooked state) |
| InheritFoodAge | Output inherits food age only |
| InheritCooked | Output inherits cooked state |
| InheritCondition | Output inherits item condition |
| InheritColor | Output inherits item color |
| InheritWeight | Output inherits item weight |
| InheritAmmunition | Output inherits loaded ammo |
| InheritEquipped | Output inherits equipped state |
| InheritFavorite | Output inherits favorite flag |
| InheritFreezingTime | Output inherits freezing timer |
| AllowFavorite | Allow favorited items as input |
| IsCookedFoodItem | Input must be cooked |
| IsUncookedFoodItem | Input must be uncooked |
| NotFull | Container must not be full |
| NotEmpty | Container must have contents |
| IsEmpty | Container must be empty |
| DontPutBack | Don't return item to inventory after use |
| AllowDestroyedItem | Allow items at 0 condition |
| IsNotWorn | Item must not be currently worn |
| IsExclusive | Only one item from the list can be used |
| DontInheritCondition | Explicitly prevent condition inheritance |

### Item Mappers

Mappers allow dynamic output selection based on input:

```
itemMapper mapperName
{
    OutputItem = InputItem,
    default = FallbackItem,
}
```

The `mappers[mapperName]` flag on an input links it to a mapper. The output uses
`item 1 mapper:mapperName` to select the result dynamically.

### Output Line Format

```
item <count> Module.ItemType
item <count> mapper:mapperName
```

## 4. Recipe Categories and Counts

Recipes are grouped into UI categories. Count of craftRecipe definitions by category
across all recipe files (standard + workstation):

| Category | Count | Primary Files |
|-|-|-|
| Tailoring | 183 | recipes_tailoring*.txt, recipes_bone.txt |
| Cooking | 86 | recipes_cooking.txt, recipes_baking.txt, recipes_cannedFood.txt |
| Blacksmithing | 66 | recipes_blacksmith_*.txt |
| Metalworking | 58 | recipes_metalWelding*.txt |
| Weaponry | 57 | recipes_improvised_weapons.txt, recipes_bone.txt, recipes_spears.txt |
| Tools | 52 | recipes_blacksmith_tools.txt |
| Miscellaneous | 48 | recipes.txt, recipes_bone.txt, recipes_camping.txt |
| Carving | 47 | recipes_carving.txt, recipes_bone.txt |
| Pottery | 44 | craftrecipe_potterywheel.txt, craftrecipe_kiln.txt, craftrecipe_handpress.txt |
| Packing | 32 | recipes_packing.txt |
| Farming | 30 | recipes_farming.txt |
| Electrical | 29 | recipes_electrical.txt |
| Carpentry | 29 | recipes_carpentry.txt, recipes_buckets.txt |
| Cookware | 17 | recipes_blacksmith_cookware.txt |
| Blade | 17 | recipes_blacksmith_blades.txt |
| Assembly | 16 | recipes_assembly.txt |
| Armor | 16 | recipes_blacksmith_armor.txt |
| Repair | 14 | recipes_fixing.txt |
| Masonry | 11 | recipes_buckets.txt, recipes_stonemasonry_i.txt |
| Knapping | 11 | recipes_knapping.txt |
| Glassmaking | 10 | recipes_glassmaking.txt |
| Medical | 8 | recipes_medical.txt |
| Fishing | 6 | recipes_fishing.txt |
| (uncategorized) | ~102 | recipes.txt, recipes_fluids.txt, etc. |

Recipes without an explicit `category` property appear under a default/general heading in the UI.

## 5. Evolved Recipes

Evolved recipes let players add ingredients to a base container (pot, bowl, pan, bread, etc.)
in a freeform fashion. They are the backbone of PZ's cooking system.

### evolvedrecipe Properties

| Property | Type | Description |
|-|-|-|
| BaseItem | string | Container item to start the recipe (Base.Pot, Base.Bowl, Base.BreadSlices) |
| MaxItems | int | Maximum number of ingredient slots (0 = only spices) |
| ResultItem | string | Item produced when recipe is prepared |
| Cookable | bool | If true, result must be cooked on a heat source |
| Name | string | Display name in the context menu |
| Template | string | Template name - determines which items can be added as ingredients |
| CanAddSpicesEmpty | bool | If true, spices can be added even with no other ingredients |
| AddIngredientIfCooked | bool | If true, ingredients are auto-cooked when added |
| AddIngredientSound | string | Sound effect when adding ingredients |
| MinimumWater | float | Minimum water level required in the container (0.0-1.0) |

### Templates (24 unique)

Items declare which evolved recipes they can be added to via their `EvolvedRecipe` property:

```
EvolvedRecipe = Soup:12;Stew:12;Stir fry:12;Sandwich:6;Burger:6;Salad:6
```

Format: `TemplateName:hungerValue` with optional `|Cooked` suffix requiring pre-cooking.

| Template | Base Containers | Cookable | Max Items | Variants |
|-|-|-|-|-|
| Soup | Pot, Bucket, PotForged | yes | 4-6 | 5 |
| Stew | Pot, Bucket, PotForged | yes | 4-6 | 4 |
| Stir fry | Pan, GridlePan, PanForged, RoastingPan | yes | 4-6 | 4 |
| Sandwich | BreadSlices, Baguette | no | 4 | 2 |
| Burger | BunsHamburger | no | 2-4 | 2 |
| Salad | Bowl, ClayBowl | no | 6 | 2 |
| FruitSalad | Bowl, ClayBowl | no | 6 | 2 |
| Pasta | Saucepan/Pot (with water+pasta) | yes | 4-5 | 4 |
| Rice | Saucepan/Pot (with water+rice) | yes | 4-5 | 4 |
| HotDrink | Mugs (11 variants) | yes | 3 | 11 |
| Pizza | PizzaRecipe | yes | 6 | 2 |
| Pie | PiePrep | yes | 4 | 1 |
| PieSweet | PiePrep | yes | 4 | 1 |
| Cake | CakePrep | yes | 4 | 1 |
| Omelette | OmeletteRecipe | yes | 3 | 2 |
| Pancakes | Pancakes, Waffles | no | 3 | 2 |
| Taco | TacoShell | no | 2-5 | 2 |
| Burrito | Tortilla | no | 0-5 | 2 |
| Toast | Toast, Bagels (3 types) | varies | 3 | 4 |
| Oatmeal | Oatmeal | yes | 3 | 1 |
| Muffin | BakingTray_Muffin | yes | 1 | 1 |
| ConeIcecream | ConeIcecream | no | 3 | 1 |
| Bread | BreadDough | yes | 2 | 1 |
| Hotdog | Hotdog | no | 2 | 1 |
| AddBaitToChum | Chum | no | 10 | 1 (fishing) |

### How Ingredient Contribution Works

Each food item declares its evolved recipe eligibility and hunger contribution:

```
EvolvedRecipe = Soup:12;Stew:12;Stir fry:12;Sandwich:6;Burger:6;Salad:6
```

The number after the colon is the hunger reduction this ingredient contributes to the
evolved recipe. Items with `|Cooked` suffix (e.g., `Sandwich:4|Cooked`) can only be added
after being cooked first. Items marked `Spice = true` can be added in addition to the
MaxItems limit as seasoning.

## 6. Annotated Examples

### Standard craftRecipe - Sawn-off Shotgun

```
craftRecipe SawOffShotgun
{
    timedAction = SawOffShotgun,       -- animation to play
    time = 200,                         -- crafting duration (ticks)
    OnCreate = RecipeCodeOnCreate.shotgunSawnoff,  -- Java callback on completion
    Tooltip = Tooltip_Recipe_NeedSawMetal,         -- hover hint
    Tags = InHandCraft,                 -- can be done in hand
    category = Weaponry,                -- UI category
    inputs
    {
        -- mode:keep = tool not consumed, MayDegrade = tool loses condition
        item 1 tags[base:metalsaw;base:smallsaw] mode:keep flags[Prop1;MayDegrade],
        -- mappers[shotgunType] links this input to the itemMapper below
        item 1 [Base.Shotgun;Base.DoubleBarrelShotgun]
            flags[Prop2;InheritCondition;InheritAmmunition] mappers[shotgunType],
    }
    outputs
    {
        item 1 mapper:shotgunType,      -- output depends on which shotgun was input
    }
    itemMapper shotgunType              -- maps input -> output
    {
        Base.ShotgunSawnoff = Base.Shotgun,
        Base.DoubleBarrelShotgunSawnoff = Base.DoubleBarrelShotgun,
    }
}
```

### Learned Recipe with Skill Requirements - Cake Batter

```
craftRecipe MakeCakeBatter
{
    timedAction = MixingBowl,
    time = 50,
    NeedToBeLearn = true,               -- must learn from book or auto-learn
    Tooltip = Tooltip_Recipe_RequireWholeEggs,
    category = Cooking,
    Tags = AnySurfaceCraft;Cooking,     -- needs a surface, tagged as cooking
    xpAward = Cooking:10,               -- grants 10 Cooking XP
    AutoLearnAny = Cooking:7,           -- auto-learned at Cooking level 7
    inputs
    {
        item 1 tags[base:mixingutensil] mode:keep flags[MayDegradeVeryLight],
        item 1 [Base.Bowl;Base.ClayBowl] flags[ItemCount],
        item 2 tags[base:flour],
        item 1 tags[base:bakingfat],
        item 2 tags[base:sugar],
        item 2 tags[base:egg] flags[IsUncookedFoodItem;InheritFoodAge;ItemCount],
        item 1 [Base.Yeast],
        item 1 [*],                     -- wildcard: any extra item
        -fluid 1.0 [CowMilk],          -- requires 1.0 units of cow milk fluid
    }
    outputs
    {
        item 1 Base.CakeBatter,
    }
}
```

### Evolved Recipe - Soup

```
evolvedrecipe Soup
{
    BaseItem = Base.Pot,                -- start with a pot
    MaxItems = 6,                       -- up to 6 ingredients
    ResultItem = Base.PotOfSoupRecipe,  -- becomes this item
    Cookable = true,                    -- must be cooked after preparation
    Name = Prepare Soup,               -- context menu text
    Template = Soup,                    -- items with EvolvedRecipe containing "Soup" can be added
    MinimumWater = 0.9,                -- pot must be at least 90% full of water
}
```

A tomato with `EvolvedRecipe = Soup:12` adds 12 hunger reduction when placed in this soup.

## 7. Modding: Adding Custom Recipes

### Adding a craftRecipe

Create a `.txt` file in your mod's `media/scripts/` directory:

```
module MyMod
{
    craftRecipe MyCustomRecipe
    {
        timedAction = Making,
        time = 100,
        Tags = AnySurfaceCraft,
        category = Cooking,
        inputs
        {
            item 2 [Base.Tomato] flags[ItemCount],
            item 1 tags[base:sharpknife] mode:keep flags[MayDegradeLight],
        }
        outputs
        {
            item 1 Base.TomatoSliced,
        }
    }
}
```

### Adding Evolved Recipe Ingredients

To make a custom food item usable in evolved recipes, add the `EvolvedRecipe` property
to your item definition:

```
item MyCustomFood
{
    ItemType = base:food,
    EvolvedRecipe = Soup:10;Stew:10;Salad:5,
    EvolvedRecipeName = My Custom Food,
    -- ... other food properties
}
```

### Adding a New Evolved Recipe Type

Define the evolved recipe container, then add the template name to food items:

```
evolvedrecipe MyStew
{
    BaseItem = Base.Pot,
    MaxItems = 5,
    ResultItem = Base.MyCustomStew,
    Cookable = true,
    Name = Prepare My Stew,
    Template = MyStew,
}
```

Then on items: `EvolvedRecipe = MyStew:8`

### Key Modding Notes

- Recipe file names don't matter - PZ loads all `.txt` files from `media/scripts/`
- Use `module Base` to add recipes using vanilla items
- Use your own module name for fully custom item chains
- Tags determine crafting location requirements - always specify at least InHandCraft or AnySurfaceCraft
- NeedToBeLearn recipes require either a book or AutoLearn thresholds to become available
- OnCreate/OnTest callbacks reference Java classes - Lua mods cannot define new ones directly
  but can use Lua event hooks for post-craft logic
