# Skills & Perks System - PZ Data Map
Source: projectzomboid.jar (decompiled) | media/lua | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | PerkFactory Architecture | 19-40 |
| 2 | Perk Enum - All Perks | 41-121 |
| 3 | XP Thresholds Per Level | 122-157 |
| 4 | XP System Internals | 158-192 |
| 5 | Professions | 193-234 |
| 6 | Foraging Skill Bonuses by Profession | 235-256 |
| 7 | Foraging Skill Bonuses by Trait | 257-279 |
| 8 | Skill Books & XP Multipliers | 280-300 |
| 9 | Custom Perks (Mod API) | 301-352 |

---

## 1. PerkFactory Architecture

**Class:** `zombie.characters.skills.PerkFactory`

Perks are static singletons in the inner `Perks` class. Each `Perk` object holds:
- `id` (String) - internal name, e.g. "Woodwork"
- `index` (int) - auto-incremented, used as array key
- `translation` (String) - key for `IGUI_perks_<translation>`
- `parent` (Perk) - category parent (e.g. Axe -> Combat)
- `passiv` (boolean) - passive skills like Fitness/Strength (different XP curve)
- `xp1..xp10` - XP required for each level (after 1.5x multiplier)

**Lookup maps:**
- `PerkById` (HashMap<String, Perk>) - lookup by id string
- `PerkByName` (HashMap<String, Perk>) - lookup by translated display name
- `PerkByIndex` (Perk[256]) - max 256 perks (vanilla + modded)
- `PerkList` (ArrayList<Perk>) - ordered list

**Global multiplier:** All raw XP values passed to `AddPerk()` are multiplied by `PERK_XP_REQ_MULTIPLIER = 1.5f`.

---

## 2. Perk Enum - All Perks

All perks defined in `PerkFactory.Perks` (inner static class), organized by category parent.

### Combat (parent: Combat)
| Perk ID | Translation Key | Notes |
|-|-|-|
| Combat | CombatMelee | Category header |
| Axe | Axe | |
| Blunt | Blunt | Two-handed blunt |
| SmallBlunt | SmallBlunt | One-handed blunt |
| LongBlade | LongBlade | |
| SmallBlade | SmallBlade | |
| Spear | Spear | |
| Maintenance | Maintenance | Weapon durability |

### Firearm (parent: Firearm)
| Perk ID | Translation Key | Notes |
|-|-|-|
| Firearm | CombatFirearms | Category header |
| Aiming | Aiming | |
| Reloading | Reloading | |

### Crafting (parent: Crafting)
| Perk ID | Translation Key | Notes |
|-|-|-|
| Crafting | Crafting | Category header |
| Woodwork | Carpentry | Display name "Carpentry" |
| Carving | Carving | B42 new |
| Cooking | Cooking | |
| Electricity | Electricity | |
| Glassmaking | Glassmaking | B42 new |
| FlintKnapping | FlintKnapping | B42 new |
| Masonry | Masonry | B42 new |
| Blacksmith | Blacksmith | B42 new |
| Mechanics | Mechanics | |
| Pottery | Pottery | B42 new |
| Tailoring | Tailoring | |
| MetalWelding | MetalWelding | |

### Survivalist (parent: Survivalist)
| Perk ID | Translation Key | Notes |
|-|-|-|
| Survivalist | Survivalist | Category header |
| Doctor | Doctor | Parent is Survivalist (not Crafting) |
| Fishing | Fishing | |
| PlantScavenging | Foraging | Display name "Foraging" |
| Tracking | Tracking | B42 new |
| Trapping | Trapping | |

### Physical (parent: PhysicalCategory)
| Perk ID | Translation Key | Notes |
|-|-|-|
| PhysicalCategory | PhysicalCategory | Category header |
| Fitness | Fitness | Passive - 10x higher XP curve |
| Strength | Strength | Passive - 10x higher XP curve |
| Lightfoot | Lightfooted | |
| Nimble | Nimble | |
| Sprinting | Sprinting | |
| Sneak | Sneaking | |

### Farming (parent: FarmingCategory)
| Perk ID | Translation Key | Notes |
|-|-|-|
| FarmingCategory | FarmingCategory | Category header, B42 new |
| Farming | Farming | |
| Husbandry | Husbandry | B42 new (animal care) |
| Butchering | Butchering | B42 new |

### Uncategorized / Legacy
| Perk ID | Notes |
|-|-|
| None | Null/default perk |
| Agility | Registered but only used as category in old code |
| Melee | Legacy, not registered in init() |
| Passiv | Legacy, not registered in init() |
| Melting | Defined but not registered in init() |
| MAX | Sentinel - tracks highest index |

---

## 3. XP Thresholds Per Level

Raw values passed to `AddPerk()` (before 1.5x multiplier applied):

### Standard Skills (most perks)
| Level | Raw XP | Actual (x1.5) | Cumulative |
|-|-|-|-|
| 1 | 50 | 75 | 75 |
| 2 | 100 | 150 | 225 |
| 3 | 200 | 300 | 525 |
| 4 | 500 | 750 | 1,275 |
| 5 | 1,000 | 1,500 | 2,775 |
| 6 | 2,000 | 3,000 | 5,775 |
| 7 | 3,000 | 4,500 | 10,275 |
| 8 | 4,000 | 6,000 | 16,275 |
| 9 | 5,000 | 7,500 | 23,775 |
| 10 | 6,000 | 9,000 | 32,775 |

### Passive Skills (Fitness, Strength)
| Level | Raw XP | Actual (x1.5) | Cumulative |
|-|-|-|-|
| 1 | 1,000 | 1,500 | 1,500 |
| 2 | 2,000 | 3,000 | 4,500 |
| 3 | 4,000 | 6,000 | 10,500 |
| 4 | 6,000 | 9,000 | 19,500 |
| 5 | 12,000 | 18,000 | 37,500 |
| 6 | 20,000 | 30,000 | 67,500 |
| 7 | 40,000 | 60,000 | 127,500 |
| 8 | 60,000 | 90,000 | 217,500 |
| 9 | 80,000 | 120,000 | 337,500 |
| 10 | 100,000 | 150,000 | 487,500 |

Max level is 10 for all perks. `getXpForLevel()` returns -1 for level > 10.

---

## 4. XP System Internals

**Class:** `IsoGameCharacter` (inner class `XPMultiplier`)

```java
public static class XPMultiplier {
    public float multiplier;   // XP gain multiplier
    public int minLevel;       // applies at or above this level
    public int maxLevel;       // applies at or below this level
}
```

XP multipliers are stored per-perk in `HashMap<Perk, XPMultiplier> xpMapMultiplier`.

**Sources of XP multipliers:**
- Skill books: add a multiplier for specific level ranges
- Traits: some grant starting skill levels (not multipliers)
- Professions: grant starting skill levels
- Sandbox settings: `XPMultiplier` sandbox option (global)
- Fast Learner trait: +30% XP gain (all skills)
- Slow Learner trait: -30% XP gain (all skills)

**Skill book level ranges** (from item scripts, standard pattern):
| Book Volume | Level Range | Typical Multiplier |
|-|-|-|
| Vol. 1 | 0-1 | 3x (Beginner) |
| Vol. 2 | 2-3 | 3x (Intermediate) |
| Vol. 3 | 4-5 | 3x (Advanced) |
| Vol. 4 | 6-7 | 3x (Expert) |
| Vol. 5 | 8-9 | 3x (Master) |

Books must be read to apply the multiplier. Each skill has a matching book series (Carpentry, Cooking, Electrical, Farming, First Aid, Fishing, Foraging, Mechanics, Metalwork, Tailoring, Trapping).

---

## 5. Professions

**Source:** `media/lua/server/Professions/Professions.lua`

Professions defined as Lua table entries. The `rare` field controls spawn weighting in random character generation.

| Profession | Rare | Notable Starting Skills/Effects |
|-|-|-|
| Unemployed | - | +8 trait points (most flexible) |
| PoliceOfficer | 1 | Aiming +3, Reloading +2, Nimble +1 |
| ParkRanger | 2 | Foraging +2, Trapping +1, Carpentry +1 |
| ConstructionWorker | - | Carpentry +1, Blunt +1 |
| MilitarySoldier | 2 | Aiming +3, Reloading +2, Maintenance +1 |
| MilitaryOfficer | 3 | Aiming +4, Reloading +3, Nimble +1 |
| SecurityGuard | - | Lightfoot +1, Sprinting +1 |
| FireOfficer | 1 | Fitness +1, Sprinting +1, Axe +1 |
| Farmer | - | Farming +2, Trapping +1 |
| Burglar | 1 | Lightfoot +2, Nimble +2, Sneaking +2 |
| Drugdealer | 1 | Sneaking +1, Lightfoot +1, Nimble +1 |
| Nurse | 1 | Doctor +2 |
| Doctor | 2 | Doctor +3 |
| Cook | 2 | Cooking +3 |
| Chef | 3 | Cooking +4 |
| FastFoodCook | - | Cooking +1 |
| TruckDriver | - | Mechanics +1 |
| Cashier | - | - |
| ShopClerk | - | - |
| Salesperson | - | - |
| ITWorker | - | Electricity +1 |
| OfficeWorker | - | - |
| Waiter | - | - |
| CustomerService | - | - |
| Janitor | - | - |
| Secretary | - | - |
| Bookkeeper | - | - |
| Accountant | - | - |
| Teacher | - | - |

Note: Starting skills are defined in Java `ProfessionFactory`, not in this Lua file. The Lua file only controls rarity. Actual skill grants are hardcoded in the Java character creation system.

---

## 6. Foraging Skill Bonuses by Profession

**Source:** `media/lua/shared/Foraging/forageSkills.lua`

Professions grant foraging bonuses: vision range, weather/darkness resistance, and category specialization percentages.

| Profession | Vision | Weather% | Dark% | Top Specializations |
|-|-|-|-|-|
| Park Ranger | +2.0 | 33% | 15% | MedicinalPlants 75, WildPlants 50, WildHerbs 50, Berries 20 |
| Veteran | +1.75 | 33% | 15% | Ammunition 50, MedicinalPlants 20 |
| Farmer | +1.5 | 33% | 10% | Crops 50, WildHerbs 15, Fruits/Vegetables 10 |
| Lumberjack | +1.25 | 33% | 15% | Firewood 50, Mushrooms 20 |
| Fisherman | +1.0 | 40% | 10% | Insects 50, FishBait 50 |
| Unemployed | +0.5 | 10% | 5% | JunkFood/Trash/Junk 10 |
| Chef | +0 | 0% | 0% | Mushrooms 50, WildHerbs 20, JunkFood 15 |
| Doctor | +0 | 0% | 0% | Medical 40, MedicinalPlants 10 |
| Burglar | +0 | 5% | 15% | JunkWeapons/Ammunition 10 |
| Repairman | +0 | 0% | 0% | Trash/Junk 33 |
| Carpenter | +0 | 0% | 0% | Firewood 30, Junk 10 |

---

## 7. Foraging Skill Bonuses by Trait

**Source:** `media/lua/shared/Foraging/forageSkills.lua`

| Trait | Vision | Weather% | Dark% | Top Specializations |
|-|-|-|-|-|
| EagleEyed | +1.0 | 0% | 0% | (general vision only) |
| Formerscout | +0.7 | 13% | 3% | Trash 10, MedicinalPlants 5 |
| Hiker | +0.7 | 13% | 3% | Berries/Mushrooms/Medicinal 3 |
| Marksman | +0.5 | 0% | 0% | Ammunition 3 |
| Hunter | +0.5 | 13% | 5% | Animals 5, Berries/Mushrooms/Medicinal 3 |
| Outdoorsman | +0.4 | 13% | 5% | Animals/Berries/Mushrooms/Medicinal/WildPlants/WildHerbs 5 |
| WildernessKnowledge | +0.4 | 13% | 5% | Same as Outdoorsman + Firewood/Stones 5 |
| NightVision | +0.4 | 0% | 0% | (built-in ambient light bonus) |
| Gardener | +0.4 | 13% | 0% | Crops/Fruits/Vegetables 5, MedicinalPlants 3 |
| Herbalist | +0.2 | 0% | 0% | MedicinalPlants 15, WildPlants/WildHerbs/Berries/Mushrooms 5 |
| Cook/Cook2 | +0.2 | 0% | 0% | Animals/Berries/Mushrooms/JunkFood/WildPlants/WildHerbs 5 |
| Nutritionist | +0.2 | 0% | 0% | JunkFood/MedicinalPlants/WildPlants/WildHerbs 5 |
| ShortSighted | -2.0 | 0% | 0% | (penalty, reduced if wearing glasses) |
| Agoraphobic | -1.5 | 0% | 0% | (penalty) |

---

## 8. Skill Books & XP Multipliers

Skill books are read-to-use items that apply an `XPMultiplier` to a specific perk for a level range. The multiplier persists until the character exceeds the book's max level.

**Standard book series exist for these skills:**
Carpentry, Cooking, Electrical, Farming, First Aid, Fishing, Foraging, Mechanics, Metalwork, Tailoring, Trapping

**Book structure:**
- Each skill has 5 volumes
- Volume N covers levels `(N-1)*2` through `(N-1)*2 + 1`
- All volumes provide a 3x multiplier by default
- Reading takes several in-game hours (varies by book)
- Fast Reader trait reduces reading time by 30%

**How XP multipliers stack:**
- Multiple multipliers for the same perk are stored in a list
- The system picks the highest applicable multiplier for the character's current level
- Sandbox `XPMultiplier` setting is applied on top

---

## 9. Custom Perks (Mod API)

**Classes:** `CustomPerks`, `CustomPerk`

Mods add custom perks via `media/perks.txt` in their mod folder (build-specific or common).

### perks.txt Format
```
VERSION = 1

perk MyCustomPerk {
    parent = Crafting
    translation = MyCustomPerk
    passive = false
    xp1 = 50
    xp2 = 100
    xp3 = 200
    xp4 = 500
    xp5 = 1000
    xp6 = 2000
    xp7 = 3000
    xp8 = 4000
    xp9 = 5000
    xp10 = 6000
}
```

### Processing Order
1. `CustomPerks.init()` scans all active mods for `perks.txt`
2. First pass: creates `PerkFactory.Perk` objects with `setCustom()` flag
3. Second pass: resolves parent references and calls `PerkFactory.AddPerk()`
4. `CustomPerks.initLua()` injects custom perks into the Lua `Perks` table

### Constraints
- Max 256 total perks (vanilla + custom) due to `PerkByIndex` array size
- Custom perks are cleared on `PerkFactory.Reset()` (world reload)
- XP values in perks.txt are raw (before 1.5x multiplier)
- Parent must be an existing perk ID (or defaults to None)
- Translation key maps to `IGUI_perks_<translation>` in translation files

### Adding Professions/Traits via Lua
Professions and traits are added via the Java `ProfessionFactory` and `TraitFactory` APIs, exposed to Lua:
```lua
-- Add profession
local prof = ProfessionFactory.addProfession("MyProfession", "UI_prof_myprofession", "Item_MyIcon")
prof:addXPBoost(Perks.Woodwork, 2)

-- Add trait
local trait = TraitFactory.addTrait("MyTrait", "UI_trait_mytrait", 4, "UI_trait_mytrait_desc", false)
trait:addXPBoost(Perks.Cooking, 1)
-- cost > 0 = positive trait (costs points), cost < 0 = negative trait (gives points)
```
