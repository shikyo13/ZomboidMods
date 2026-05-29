# Clothing System - PZ Data Map
Source: media/scripts/generated/items/clothing.txt | media/clothing/ | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Overview | 17-29 |
| 2 | BodyLocation Enum - All Slots | 30-85 |
| 3 | Defense System | 86-124 |
| 4 | Insulation and Temperature | 125-167 |
| 5 | Condition and Degradation | 168-194 |
| 6 | Blood and Dirt Visual System | 195-219 |
| 7 | Outfit System | 220-261 |
| 8 | Fabric Types and Repair | 262-306 |
| 9 | Clothing XML Definition Format | 307-317 |

## 1. Overview

B42 clothing is defined across two systems:

1. **Script definitions** - `media/scripts/generated/items/clothing.txt` (1395 items)
   - Gameplay stats: defense, insulation, weight, body slot
2. **Clothing XML items** - `media/clothing/clothingItems/` (1795 XML files)
   - Visual data: 3D models, textures, masks, GUIDs
3. **Outfit definitions** - `media/clothing/clothing.xml`
   - 265 unique outfit names across ~409 male/female entries
4. **Decal system** - `media/clothing/clothingDecals.xml`
   - T-shirt decal groups (Spiffo, Sport, Culture, Business brands)

## 2. BodyLocation Enum - All Body Slots

Every clothing item has a `BodyLocation` property defining which slot it occupies. Items in the same slot conflict. Organized by body region:

### Head and Face (20 slots)

| Slot | Slot | Slot | Slot |
|-|-|-|-|
| hat | fullhat | jackethat | jackethat_bulky |
| sweaterhat | mask | maskeyes | maskfull |
| eyes | lefteye | righteye | ears |
| eartop | nose | scba | scbanotank |
| makeup_eyes | makeup_eyesshadow | makeup_fullface | makeup_lips |

### Neck and Upper Body (24 slots)

| Slot | Slot | Slot | Slot |
|-|-|-|-|
| neck | neck_texture | necklace | necklace_long |
| gorget | scarf | tanktop | tshirt |
| shirt | shortsleeveshirt | sweater | jersey |
| jacket | jacket_bulky | jacket_down | bathrobe |
| boilersuit | torsoextra | torsoextravest | torsoextravestbullet |
| vesttexture | cuirass | webbing | ammostrap |

### Arms and Hands (19 slots)

| Slot | Slot | Slot | Slot |
|-|-|-|-|
| leftarm | rightarm | shoulderpadleft | shoulderpadright |
| sportshoulderpad | sportshoulderpadontop | elbow_left | elbow_right |
| forearm_left | forearm_right | hands | handsleft |
| handsright | leftwrist | rightwrist | left_middlefinger |
| left_ringfinger | right_middlefinger | right_ringfinger | |

### Lower Body and Legs (23 slots)

| Slot | Slot | Slot | Slot |
|-|-|-|-|
| belt | beltextra | codpiece | bellybutton |
| underwear | underwearbottom | underweartop | underwearextra1 |
| underwearextra2 | pants | pants_skinny | pantsextra |
| shortpants | shortsshort | skirt | longskirt |
| dress | longdress | fullsuit | fullsuithead |
| fulltop | torso1legs1 | legs1 | |

### Leg Armor and Feet (12 slots)

`thigh_left`, `thigh_right`, `knee_left`, `knee_right`, `calf_left`, `calf_right`, `calf_left_texture`, `calf_right_texture`, `gaiter_left`, `gaiter_right`, `socks`, `shoes`

### Equipment and Special Slots (10 slots)

`back`, `satchel`, `fannypackfront`, `fannypackback`, `shoulderholster`, `ankleholster`, `tail`, `zeddmg`, `wound`, `bandage`

**Total: 109 unique body slots** (108 gameplay + `zeddmg` visual-only)

## 3. Defense System

Clothing provides three defense types, each an integer 0-100 representing percentage chance to block that attack type.

### Defense Properties

| Property | Description | Range |
|-|-|-|
| BiteDefense | Chance to block zombie bite | 0-100 |
| ScratchDefense | Chance to block zombie scratch | 0-100 |
| BulletDefense | Chance to block bullet damage | 0-100 |

421 clothing items have BiteDefense values. Scratch defense is typically 2x bite defense for the same item. Bullet defense is only on dedicated armor pieces.

### Defense Tiers by Material

| Tier | Bite | Scratch | Bullet | Example Items |
|-|-|-|-|-|
| Chainmail | 80 | 100 | 0 | Chainmail Gauntlets, Chainmail Coif |
| Body Armor (Ballistic) | 0-20 | 20-40 | 100 | Police Vest, Military Vest |
| Greave/Shin Guard | 40-80 | 80-100 | 100 | SWAT Greaves, Army Greaves |
| Leather Jacket | 10-20 | 20-40 | 0 | Leather Jacket, Biker Jacket |
| Leather Gloves | 15 | 30 | 0 | Leather Gloves |
| Denim | 2-4 | 4-8 | 0 | Jeans, Denim Jacket |
| Cotton | 0-2 | 2-4 | 0 | T-shirts, Dresses |
| None | 0 | 0 | 0 | Cosmetics, Makeup |

### Defense Stacking

Multiple clothing layers on different body slots stack their defense. Each slot rolls independently - the game checks the relevant body part's clothing when a hit lands. If multiple items cover the same body region, each gets a chance to block.

### CorpseSicknessDefense

Some clothing provides `CorpseSicknessDefense` (float 0-1), reducing sickness from being near corpses. Present on gas masks, SCBA gear, and some face coverings.

### NeckProtectionModifier

Float modifier for neck bite protection, found on scarves, gorgets, and high-collar jackets.

## 4. Insulation and Temperature

### How Insulation Works

Each clothing item has:

| Property | Type | Description |
|-|-|-|
| Insulation | float | Base warmth value (0.0 = none, 1.0+ = very warm) |
| WindResistance | float | Protection from wind chill (0.0-1.0) |
| WaterResistance | float | Protection from rain wetness (0.0-1.0) |

The game sums insulation from all worn items to determine the character's effective temperature regulation. Wind resistance reduces the cooling effect of wind. Water resistance slows how fast clothing gets wet in rain.

### Insulation Ranges by Slot

| Body Region | Typical Range | High Example |
|-|-|-|
| Jacket (bulky) | 0.5-0.9 | Parka = 0.9 |
| Jacket (normal) | 0.3-0.6 | Leather Jacket = 0.45 |
| Sweater | 0.3-0.5 | Wool Sweater = 0.5 |
| Pants | 0.1-0.3 | Winter Pants = 0.3 |
| Shirt | 0.05-0.15 | Flannel = 0.15 |
| T-shirt | 0.05-0.1 | Standard Tee = 0.05 |
| Hat | 0.1-0.8 | Ushanka = 0.8 |
| Gloves | 0.3-0.75 | Leather Gloves = 0.75 |
| Shoes | 0.1-0.4 | Boots = 0.3 |
| Socks | 0.05-0.15 | Wool Socks = 0.15 |
| Scarf | 0.2-0.5 | Wool Scarf = 0.5 |
| Underwear | 0.0-0.05 | Long Johns = 0.05 |

### Movement Penalties

Heavy/bulky clothing reduces movement:

| Property | Description | Typical Values |
|-|-|-|
| RunSpeedModifier | Sprint speed multiplier | 0.85-1.0 (< 1 = slower) |
| CombatSpeedModifier | Attack speed multiplier | 0.95-1.0 |
| DiscomfortModifier | Discomfort penalty | 0.01-0.1 |

Long dresses/skirts notably slow the player: `RunSpeedModifier = 0.9` is common for long garments.

## 5. Condition and Degradation

### Durability Properties

| Property | Type | Description |
|-|-|-|
| ConditionMax | int | Maximum condition points (typically 10) |
| ConditionLowerChanceOneIn | int | 1-in-N chance to lose 1 condition per hit |
| CanHaveHoles | bool | Can develop holes from damage |
| RemoveOnBroken | bool | Auto-unequip at 0 condition |

### Degradation Mechanics

- Clothing condition decreases when the player is hit by zombies, bullets, or environmental damage
- Lower condition reduces defense values proportionally
- At condition 0, clothing with `RemoveOnBroken = true` is auto-removed
- `CanHaveHoles = true` (default for most clothing) means damage creates visual holes
- `CanHaveHoles = false` is set for rigid items (helmets, watches, jewelry)

### Repair System

Clothing can be repaired using matching fabric + needle/thread:
- Each repair restores some condition but reduces `ConditionMax` slightly
- Repair material must match `FabricType` (Cotton patch for Cotton, etc.)
- Tailoring skill determines repair quality and condition retention
- Some items (chainmail, body armor) cannot be conventionally repaired

## 6. Blood and Dirt Visual System

### BloodLocation Zones

The `BloodLocation` property defines which body zones show blood/dirt when the clothing is worn. Multiple zones are semicolon-separated.

**30 zones**: Head, FullHelmet, Neck, Shirt, ShirtLongSleeves, ShirtNoSleeves, Jumper, JumperNoSleeves, Jacket, LongJacket, Apron, UpperBody, UpperArms, UpperArm_L, UpperArm_R, ForeArm_L, ForeArm_R, Hands, Hand_L, Hand_R, Trousers, ShortsShort, Groin, UpperLeg_L, UpperLeg_R, LowerLeg_L, LowerLeg_R, LowerLegs, Shoes, Bag

### How Blood/Dirt Accumulates

1. **Blood** appears from combat (killing zombies, getting hit, crawling near corpses)
2. **Dirt** accumulates from activities (gardening, crawling, rain can wash some off)
3. Both are tracked per-zone and rendered using the clothing item's mask textures
4. Blood and dirt affect NPC reactions and zombie detection

### Clothing XML Masks

Masks in the clothing XML (`m_Masks` elements) define texture regions used for blood/dirt rendering:
```xml
<m_Masks>12</m_Masks>
<m_Masks>13</m_Masks>
<m_MasksFolder>media/textures/Clothes/Jacket/Masks</m_MasksFolder>
```
Each mask number maps to a body zone texture region.

## 7. Outfit System

### Overview

Outfits are predefined clothing combinations assigned to NPCs and zombie spawns. Defined in `media/clothing/clothing.xml`.

- **265 unique outfit names** across 409 male/female entries
- Separate `m_FemaleOutfits` and `m_MaleOutfits` sections
- Each outfit references clothing items by GUID

### Outfit XML Structure

Each outfit is a `m_FemaleOutfits` or `m_MaleOutfits` block containing: `m_Name`, `m_Guid`, boolean flags (`m_Top`, `m_Pants`, `m_AllowPantsHue`, `m_AllowTopTint`, `m_AllowTShirtDecal`), and a list of `m_items`. Each item references a clothing piece by `itemGUID`, with optional `probability` (0-1, default 1.0) and `subItems` for variant alternatives.

### Sample Outfit Categories

| Category | Example Names |
|-|-|
| Civilian | Bob, Bathrobe, Bedroom, Classy, ClubGoer |
| Military | ArmyCamoDesert, ArmyCamoGreen, ArmyInstructor |
| Emergency | AmbulanceDriver, Firefighter, Police |
| Work | ConstructionWorker, Cook_Generic, Chef |
| Sports | BaseballPlayer_KY, BoxingBlue, Bowling |
| Costume | CostumeBeastMom, CostumeChunk, CostumeBloodFirst |
| Bandit | Bandit, Bandit_Early, Bandit_Mid, Bandit_Late |
| Testing | ArmorTest_Bone, ArmorTest_Metal, 1RJTest |

### T-Shirt Decal System

Decals are defined in `media/clothing/clothingDecals.xml` as named groups:

| Group | Decals |
|-|-|
| TShirtSpiffo | 6 Spiffo variants |
| TShirtSport | Baseball, Basketball, team logos |
| TShirtCulture | I Love KY, Rock, USA flag, Wolf, Shamrock |
| TShirtFossoil | Fossoil gas station branding |
| TShirtMcCoys | McCoy's branding |
| TShirtAll | Meta-group combining multiple groups |

Outfits with `m_AllowTShirtDecal = true` randomly select from applicable decal groups.

## 8. Fabric Types and Repair

### FabricType Values

| FabricType | Item Count | Properties |
|-|-|-|
| Cotton | 298 | Low defense, low insulation, lightweight, easily ripped |
| Leather | 77 | Medium defense, good insulation, water resistant |
| Denim | 42 | Low-medium defense, moderate insulation, durable |

Items without FabricType (armor, accessories, cosmetics) are typically unrepairable via the standard tailoring system.

### Repair Materials

| Fabric | Repair Item | Source |
|-|-|-|
| Cotton | Ripped Sheets / Cotton Patches | Ripping cotton clothing |
| Denim | Denim Strips / Denim Patches | Ripping denim clothing |
| Leather | Leather Strips | Ripping leather clothing, animal hides |

### Tailoring Skill Integration

- **Level 0-1**: Can patch holes (low quality)
- **Level 2-3**: Basic repairs, can add padding
- **Level 4-5**: Improved repair quality
- **Level 6-7**: Can reinforce clothing (add defense to non-armored items)
- **Level 8-10**: Maximum repair efficiency, minimal ConditionMax loss

### Crafted Clothing Tags

Tags indicate clothing crafting/repair capability:
- `base:ripclothingcotton` - Can be ripped for cotton strips
- `base:ripclothingleather` - Can be ripped for leather strips
- `base:canbedyed` - Can be color-dyed
- `base:noragdoll` - Exempt from ragdoll physics clipping

### B42 Crafted Armor

B42 added extensive armor crafting via blacksmithing and tailoring:
- **Chainmail** - Crafted at forge, highest bite/scratch defense (80/100)
- **Plate armor** (cuirass, greaves) - Body armor pieces, high bullet defense
- **Hide clothing** - From animal hides, leather-tier defense
- **Tire armor** - Forearm/shin guards from tires, moderate defense
- **Crafted leather** - From tanning hides, full clothing line

## 9. Clothing XML Definition Format

Each clothing item has a visual definition in `media/clothing/clothingItems/ItemName.xml`.

### XML Properties

Each `<clothingItem>` XML contains: `m_MaleModel`/`m_FemaleModel` (3D mesh paths), `m_GUID` (unique ID for outfit references), `m_Static` (non-skinned flag), `m_AllowRandomHue`/`m_AllowRandomTint` (spawn variation), `m_AttachBone` (attachment point for static items), `m_Masks` (body zone mask indices for blood/dirt, multiple elements), `m_MasksFolder`/`m_UnderlayMasksFolder` (mask texture paths), and `textureChoices` (available texture variants, one selected at spawn).

### Linking Script to XML

The script property `ClothingItem = Jacket_Fireman` maps to `media/clothing/clothingItems/Jacket_Fireman.xml`, linking gameplay stats to visual data. 1795 XML files exist (vs 1395 script entries) because some are only used by the outfit system as sub-items.
