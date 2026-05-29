# Character Appearance System - PZ Data Map
Source: projectzomboid.jar (decompiled) | media/clothing | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture Overview | 20-53 |
| 2 | HumanVisual | 55-92 |
| 3 | Outfit System | 94-144 |
| 4 | ClothingItem and Layers | 146-179 |
| 5 | Hair System | 181-223 |
| 6 | Beard System | 225-244 |
| 7 | Skin and Body | 246-263 |
| 8 | CharacterMask | 265-294 |
| 9 | Blood and Dirt | 296-343 |
| 10 | Zombie Appearance | 345-365 |
| 11 | Smart Texture Compositing | 367-397 |
| 12 | Modding Custom Appearance | 399-425 |

## 1. Architecture Overview

Character appearance composites body, clothing, blood, dirt, and accessories into a
single texture at runtime using the `SmartTexture` system.

### Key Classes

| Class | Package | Role |
|-|-|-|
| `HumanVisual` | `z.core.skinnedmodel.visual` | Master visual state |
| `ItemVisual` | `z.core.skinnedmodel.visual` | Per-clothing-item visual |
| `Outfit` | `z.core.skinnedmodel.population` | Outfit definition |
| `OutfitManager` | `z.core.skinnedmodel.population` | Outfit registry singleton |
| `ClothingItem` | `z.core.skinnedmodel.population` | Clothing piece definition |
| `HairStyle` / `BeardStyle` | `z.core.skinnedmodel.population` | Hair/beard models |
| `HairStyles` / `BeardStyles` | `z.core.skinnedmodel.population` | Style registries |
| `CharacterMask` | `z.core.skinnedmodel.model` | Body part visibility |
| `CharacterSmartTexture` | `z.characterTextures` | Character texture compositor |
| `ItemSmartTexture` | `z.characterTextures` | Clothing texture compositor |
| `BloodBodyPartType` | `z.characterTextures` | Body part enum (18 parts) |
| `BloodClothingType` | `z.characterTextures` | Clothing coverage zones |
| `HairOutfitDefinitions` | `z.characters` | Hair/beard per-outfit rules |
| `ClothingWetness` | `z.characters` | Wetness tracking |

### Data Files

| File | Path |
|-|-|
| Outfits | `media/clothing/clothing.xml` (JAXB XML) |
| Hair styles | `media/hairStyles/hairStyles.xml` |
| Beard styles | `media/hairStyles/beardStyles.xml` |
| Blood masks | `media/textures/BloodTextures/*.png` |
| Patch textures | `media/textures/patches/*.png` |
| Body masks | `media/textures/Body/Masks/` |

## 2. HumanVisual

Complete visual description of a human character (player or zombie).

### Fields

| Field | Type | Purpose |
|-|-|-|
| `skinColor` | ImmutableColor | Skin tint |
| `skinTexture` | int | Index into skin texture list |
| `skinTextureName` | String | Override texture name |
| `hairColor` / `beardColor` | ImmutableColor | Hair/beard color |
| `naturalHairColor/BeardColor` | ImmutableColor | Pre-dye color |
| `hairModel` / `beardModel` | String | Style name |
| `bodyHair` | int | Body hair index (-1=none) |
| `blood[18]` | byte[] | Blood per BloodBodyPartType (0-255) |
| `dirt[18]` | byte[] | Dirt per part |
| `holes[18]` | byte[] | Clothing holes per part |
| `bodyVisuals` | ItemVisuals | All worn clothing visuals |
| `outfit` | Outfit | Current outfit |
| `zombieRotStage` | int | Decay stage (1-3, -1=unset) |
| `forceModel` | Model | Override 3D model |

### Key Methods

| Method | Purpose |
|-|-|
| `setSkinColor(ImmutableColor)` | Set skin tint |
| `getSkinTexture()` | Get texture path (gender/zombie-aware) |
| `setHairColor/setBeardColor` | Set hair/beard color |
| `setHairModel/setBeardModel` | Set style by name |
| `setBlood(BloodBodyPartType, float)` | Set blood 0-1 at body part |
| `getBlood/getDirt/getHole` | Get overlay intensity |
| `removeBlood() / removeDirt()` | Clear all overlays |
| `randomBlood() / randomDirt()` | Randomize overlays |
| `getTotalBlood()` | Sum all blood values |
| `setBodyHairIndex(int)` | Set body hair variant |
| `clear()` | Reset to defaults |

## 3. Outfit System

### Outfit

Defined in `media/clothing/clothing.xml`, loaded by `OutfitManager`.

| Field | Type | Purpose |
|-|-|-|
| `name` | String | e.g. "Farmer", "Police" |
| `top` / `pants` | boolean | Has top/pants |
| `items` | ArrayList<ClothingItemReference> | Clothing items |
| `allowPantsHue` | boolean | Random pants hue |
| `allowTopTint` / `allowPantsTint` | boolean | Random color |
| `allowTshirtDecal` | boolean | T-shirt decals |
| `modId` | String | Originating mod |

### XML Structure

```xml
<outfitManager>
  <m_MaleOutfits>
    <m_Name>Agent</m_Name>
    <m_Top>false</m_Top>
    <m_Pants>false</m_Pants>
    <m_items>
      <probability>0.3</probability>
      <itemGUID>guid-here</itemGUID>
      <subItems><itemGUID>sub-guid</itemGUID></subItems>
    </m_items>
  </m_MaleOutfits>
</outfitManager>
```

### OutfitManager

Singleton loaded from `media/clothing/clothing.xml`. Separate male/female lists.
Mod outfits with matching names override base game (logged to `DebugType.Clothing`).
Checked in both `versionDir` and `commonDir`.

### Randomization (`Outfit.Randomize()`)

| RandomData Field | Source |
|-|-|
| `hairColor` | `HairOutfitDefinitions.getRandomHaircutColor(outfit)` |
| `femaleHairName` | `HairStyles.getRandomFemaleStyle(outfit)` |
| `maleHairName` | `HairStyles.getRandomMaleStyle(outfit)` |
| `beardName` | `BeardStyles.getRandomStyle(outfit)` |
| `topTint` / `pantsTint` | `OutfitRNG.randomImmutableColor()` |
| `pantsHue` | 25% chance, range -1.0 to 1.0 |
| `hasTop` | 15/16 chance |
| `hasTshirtDecal` | 25% chance |

## 4. ClothingItem and Layers

### ClothingItem

| Field | Type | Purpose |
|-|-|-|
| `guid` | String | Unique GUID |
| `maleModel` / `femaleModel` | String | 3D model paths |
| `baseTextures` | ArrayList<String> | Base texture options |
| `masks` | ArrayList<Integer> | CharacterMask parts to hide |
| `masksFolder` | String | Default: `media/textures/Body/Masks` |
| `textureChoices` | ArrayList<String> | Random texture variants |
| `allowRandomHue/Tint` | boolean | Randomization flags |
| `decalGroup` | String | T-shirt decal group |
| `hatCategory` | String | Hat type (nobeard, nohairnobeard) |
| `spawnWith` | ArrayList<String> | Co-spawned items |

### ItemVisual (per-worn-item state)

| Field | Type | Purpose |
|-|-|-|
| `fullType` | String | Script type (e.g. "Base.Jacket") |
| `clothingItemName` | String | ClothingItem asset name |
| `hue` | float | Hue shift (POSITIVE_INFINITY=none) |
| `tint` | ImmutableColor | Color tint |
| `baseTexture` / `textureChoice` | int | Texture indices |
| `blood/dirt/holes[18]` | byte[] | Per-body-part state |
| `basicPatches/denimPatches/leatherPatches[18]` | byte[] | Patch state |

### Body Locations

`BodyLocations` manages equip slot groups. `WornItems` tracks equipped items.
`ILuaGameCharacterClothing` interface exposes:
`dressInNamedOutfit`, `getWornItems`, `setWornItem`, `removeWornItem`, `clearWornItems`.

## 5. Hair System

### HairStyle

| Field | Type | Purpose |
|-|-|-|
| `name` | String | e.g. "Bob", "Ponytail" |
| `model` | String | 3D model path |
| `texture` | String | Default "F_Hair_White" |
| `alternate` | ArrayList<Alternate> | Per-hat-category alternates |
| `level` | int | Growth level (0=shortest) |
| `trimChoices` | ArrayList<String> | Valid trim targets |
| `growReference` | boolean | Growth reference style |
| `attachedHair` | boolean | Rendered as attached model |
| `noChoose` | boolean | Hidden from player selection |

Alternates: `<alternate category="hat" style="Bob_UnderHat"/>` - hat-specific variants.

### HairStyles Registry

Loaded from `media/hairStyles/hairStyles.xml`. Separate `maleStyles`/`femaleStyles` lists.
Mods add or override by name (both `versionDir` and `commonDir` checked).

### Hair-Outfit Rules (`HairOutfitDefinitions`)

Loaded from Lua table. Two definition types:

| Type | Fields |
|-|-|
| `HaircutDefinition` | name, minWorldAge, onlyFor (outfit list) |
| `HaircutOutfitDefinition` | outfit, haircutChance, femaleHaircutChance, beardChance |

`StringChance` pairs style name with probability. Special values: `"null"` (none),
`"random"` (any valid). Hair validity checks outfit and minimum world age.

### Key Methods

| Method | Purpose |
|-|-|
| `FindMaleStyle(name)` / `FindFemaleStyle(name)` | Lookup by name |
| `getRandomMaleStyle(outfit)` | Random valid style for outfit |
| `getRandomFemaleStyle(outfit)` | Random valid female style |
| `isHaircutValid(outfit, haircut)` | Validate style for outfit |

## 6. Beard System

### BeardStyle

| Field | Type | Purpose |
|-|-|-|
| `name` | String | e.g. "Full", "Goatee" |
| `model` | String | 3D model path |
| `texture` | String | Default "F_Hair_White" |
| `level` | int | Growth level |
| `trimChoices` | ArrayList<String> | Trim targets |
| `growReference` | boolean | Growth reference |

### BeardStyles Registry

Loaded from `media/hairStyles/beardStyles.xml`. Empty style at index 0 (clean-shaven).
Mod override same as hair. `FindStyle(name)` / `getRandomStyle(outfit)`.

Beard color defaults to hair color (`getBeardColor()` falls back to `getHairColor()`).
Can be set independently. Natural colors tracked for dye system.

## 7. Skin and Body

### Skin Textures (`PopTemplateManager`)

| List | Context |
|-|-|
| `maleSkins` / `femaleSkins` | Living characters |
| `maleSkinsZombie1/2/3` | Zombie stages (fresh/decayed/heavy) |
| `femaleSkinsZombie1/2/3` | Female zombie equivalents |
| `skeletonMale/FemaleSkinsZombie` | Skeletal zombies |

`getSkinTexture()` selects based on gender, zombie status, decay stage.
Living males with `bodyHair >= 0` get `"a"` suffix on texture name.

### Skin Color

`SurvivorDesc.getRandomSkinColor()` generates random colors.
Applied via `HumanVisual.setSkinColor(ImmutableColor)`.

## 8. CharacterMask

Tracks body part visibility. Clothing hides body parts via `masks` list.

### Part Enum

| Part | Index | Subdivisions |
|-|-|-|
| `Head` | 0 | - |
| `Torso` | 1 | Chest(12), Waist(13) |
| `Pelvis` | 2 | Belt(14), Crotch(15) |
| `LeftArm` | 3 | - |
| `LeftHand` | 4 | - |
| `RightArm` | 5 | - |
| `RightHand` | 6 | - |
| `LeftLeg` | 7 | - |
| `LeftFoot` | 8 | - |
| `RightLeg` | 9 | - |
| `RightFoot` | 10 | - |
| `Dress` | 11 | - |

Setting a subdivided parent hides all subdivisions. `isPartVisible(Torso)` = true only
if both Chest and Waist visible.

### BloodBodyPartType to Mask Mapping

Hand_L/R -> LeftHand/RightHand, ForeArm/UpperArm L/R -> LeftArm/RightArm,
Torso_Upper -> Chest, Torso_Lower -> Waist, Head/Neck -> Head, Groin -> Crotch,
UpperLeg L/R -> Left/RightLeg+Pelvis, LowerLeg L/R -> Left/RightLeg,
Foot L/R -> Left/RightFoot, Back -> Torso.

## 9. Blood and Dirt

### BloodClothingType (coverage inheritance)

| Type | Covers |
|-|-|
| `ShirtNoSleeves` | Torso_Upper, Torso_Lower, Back |
| `Shirt` | ShirtNoSleeves + UpperArm_L/R |
| `ShirtLongSleeves` | Shirt + ForeArm_L/R |
| `Jacket` | ShirtLongSleeves + Neck |
| `LongJacket` | ShirtLongSleeves + Neck, Groin, UpperLeg_L/R |
| `ShortsShort` | Groin, UpperLeg_L/R |
| `Trousers` | ShortsShort + LowerLeg_L/R |
| `Shoes` | Foot_L/R |
| `FullHelmet` | Head |
| `Bag` | Back |
| `Apron` | Torso_Upper/Lower, UpperLeg_L/R |

### Application Flow

`addBlood(part, intensity, humanVisual, itemVisuals, allLayers)`:
1. If not `allLayers`, finds outermost clothing covering the body part
2. Adds to that clothing's `ItemVisual.blood[]`
3. If no clothing, adds to `HumanVisual.blood[]`
4. If `allLayers`, penetrates through all layers

Intensity per sandbox `clothingDegradation`:

| Setting | Range |
|-|-|
| 2 | 0.001 - 0.01 |
| 3 | 0.05 - 0.1 |
| 4 | 0.01 - 0.05 |

### Holes and Patches

`addHole()` - finds outermost clothing, sets `holes[]` if `canHaveHoles`, reduces
condition by `condLossPerHole`. Patches: `addBasicPatch`, `setDenimPatches`, `setLeatherPatches`.

### Blood Level Calculation

`calcTotalBloodLevel(clothing)`: sums `blood[part] * 100` across all covered parts,
divides by count, stores via `clothing.setBloodLevel()`. Same for dirt.

### Wetness

`ClothingWetness` tracks per-body-part wetness. Rain hits outermost layer.
Perspiration applies from body outward. Affects thermoregulation.

## 10. Zombie Appearance

### Rot Stage Selection

`pickRandomZombieRotStage()` - linear interpolation between day 20 and day 90:

| Stage | Day 0 | Day 90+ | Day 180+ |
|-|-|-|-|
| 1 (fresh) | ~100% | ~20% | ~0% |
| 2 (decayed) | ~10% | ~30% | ~10% |
| 3 (heavy) | ~0% | ~50% | ~90% |

### Zombie Skin Textures

Each stage has separate texture lists (`maleSkinsZombie1/2/3`, `femaleSkinsZombie1/2/3`).
Skeleton zombies use `skeletonMale/FemaleSkinsZombie`.

### Outfit Assignment

Zombies get outfits via `dressInNamedOutfit()` during spawn. Randomized once, saved.
Blood/dirt/holes added randomly. Occupation outfits from population zone data.

## 11. Smart Texture Compositing

### CharacterSmartTexture Categories

| Category | Value | Layer |
|-|-|-|
| `BODY_CATEGORY` | 0 | Base body |
| `CLOTHING_BOTTOM_CATEGORY` | 1 | Lower clothing |
| `CLOTHING_TOP_CATEGORY` | 2 | Upper clothing |
| `CLOTHING_ITEM_CATEGORY` | 3 | Individual items |
| `DECAL_OVERLAY_CATEGORY` | 300+partIdx | Blood/decals |
| `DIRT_OVERLAY_CATEGORY` | 400+partIdx | Dirt overlays |

### Blood Mask Files (18 PNGs in `media/textures/BloodTextures/`)

Indexed by BloodBodyPartType ordinal: BloodMaskHandL, BloodMaskHandR,
BloodMaskLArmL/R, BloodMaskUArmL/R, BloodMaskChest, BloodMaskStomach,
BloodMaskHead, BloodMaskNeck, BloodMaskGroin, BloodMaskULegL/R,
BloodMaskLLegL/R, BloodMaskFootL/R, BloodMaskBack.

### Compositing Flow

1. `setBlood(part, intensity)` - overlay `BloodOverlay.png` masked by part mask at cat 300+idx
2. `setDirt(part, intensity)` - overlay `GrimeOverlay.png` at cat 400+idx
3. Each has `intensity` shader param (0-1), `setDirty()` triggers re-composite
4. Head blood darkens hair/beard tints (R-=0.022, G-=0.03, B-=0.03)

### ItemSmartTexture

Same compositing for clothing items. Supports blood, dirt, and patches
(basic/denim/leather via `patchesmask.png`). Fluid overlays with custom tint colors.

## 12. Modding Custom Appearance

### Custom Outfits/Hair/Beard

Place `media/clothing/clothing.xml` in mod - same-name outfits override base game.
Place `media/hairStyles/hairStyles.xml` or `beardStyles.xml` - same-name styles override,
new names are added.

### Lua API

```lua
local visual = player:getHumanVisual()
visual:setHairModel("Ponytail")
visual:setHairColor(ImmutableColor.new(0.8, 0.3, 0.1, 1.0))
visual:setBlood(BloodBodyPartType.Torso_Upper, 0.5)
player:dressInNamedOutfit("Farmer")
player:setWornItem(bodyLocation, item)
```

### Mod File Placement

| Content | Path |
|-|-|
| Outfits | `media/clothing/clothing.xml` |
| Hair/beard styles | `media/hairStyles/hairStyles.xml`, `beardStyles.xml` |
| Models / textures | `media/models_X/` (FBX), `media/textures/` (PNG) |
| Blood masks | `media/textures/BloodTextures/` |
