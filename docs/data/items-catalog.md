# Items Catalog - PZ Data Map
Source: media/scripts/generated/items/*.txt | media/items/items.xml | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Script Definition Format | 21-44 |
| 2 | Item Type Categories | 45-66 |
| 3 | Common Properties (All Items) | 67-93 |
| 4 | Normal Item Properties | 94-101 |
| 5 | Weapon (HandWeapon) Properties | 102-139 |
| 6 | Food Properties | 140-190 |
| 7 | Drainable Properties | 191-204 |
| 8 | Literature Properties | 205-227 |
| 9 | Clothing Properties | 228-269 |
| 10 | Container Properties | 270-298 |
| 11 | Other Types (Key, Map, AlarmClock, Radio, WeaponPart) | 299-331 |
| 12 | Item Counts by Category | 332-358 |
| 13 | Example Definitions | 359-433 |

## 1. Script Definition Format

B42 items are defined in `media/scripts/generated/items/` as `.txt` files, one per ItemType.
The format is a module block wrapping individual item blocks:

```
module Base
{
    item ItemName
    {
        PropertyKey = value,
        PropertyKey = value1;value2,
    }
}
```

Key syntax rules:
- Module is always `Base` for vanilla items
- Each property is `Key = Value,` (trailing comma)
- Multi-values use semicolons: `Tags = base:tag1;base:tag2`
- References use `Module.ItemName` format: `ReplaceOnUse = Base.Pan`
- `ItemType` uses namespaced format: `base:food`, `base:weapon`, etc.
- B42 also has `media/items/items.xml` - a legacy XML file mapping weapon 3D models/textures to weapon types (only ~20 entries, not the main item source)

## 2. Item Type Categories

Items are split across 15 files by their `ItemType` value:

| File | ItemType Value | Purpose |
|-|-|-|
| normal.txt | base:normal | General items, materials, tools, vehicle parts |
| weapon.txt | base:weapon | Melee weapons, firearms, explosives |
| food.txt | base:food | All edible items, cookable ingredients |
| clothing.txt | base:clothing | Wearable clothing, armor, cosmetics |
| container.txt | base:container | Bags, backpacks, pouches |
| drainable.txt | base:drainable | Items with a usage bar (fuel, sprays, water containers) |
| literature.txt | base:literature | Skill books, magazines, writable journals |
| moveable.txt | base:moveable | Furniture and placeable objects |
| radio.txt | base:radio | Walkie-talkies, radios, TVs |
| key.txt | base:key | Keys, padlocks |
| map.txt | base:map | Town maps |
| alarmclock.txt | base:alarmclock | Alarm clocks, watches |
| alarmclockclothing.txt | base:alarmclock | Wearable alarm clocks (wristwatches) |
| weaponpart.txt | base:weaponpart | Scopes, grips, choke tubes |
| animal.txt | base:animal | Animal items (minimal, 1 entry) |

## 3. Common Properties (All Items)

These properties appear across multiple or all item types:

| Property | Type | Description |
|-|-|-|
| DisplayCategory | string | UI category for inventory sorting (Food, Weapon, Tool, etc.) |
| ItemType | string | Type identifier, e.g. `base:weapon`, `base:food` |
| Weight | float | Base weight in kg |
| Icon | string | Texture name for inventory icon |
| IconsForTexture | string | Multiple icon textures (semicolon-separated) |
| IconColorMask | string | Color mask overlay for icon |
| StaticModel | string | 3D model reference (in-hand) |
| WorldStaticModel | string | 3D model when dropped in world |
| StaticModelsByIndex | string | Multiple model variants |
| WorldStaticModelsByIndex | string | Multiple world model variants |
| Tags | string | Semicolon-separated tag list (`base:tagname`) |
| Tooltip | string | Translation key for tooltip text |
| MetalValue | float | Metal content for smelting |
| ConditionMax | int | Maximum durability |
| ConditionLowerChanceOneIn | int | 1-in-N chance to lose durability per use |
| OnCreate | string | Lua function called on item creation |
| Researchablerecipes | string | Recipes unlockable via research |
| SurvivalGear | bool | Marked as survival-relevant loot |
| FireFuelRatio | float | Burn value as fire fuel |
| ColorRed/Green/Blue | int | RGB tint values |

## 4. Normal Item Properties

File: `normal.txt` - 1112 items. Catch-all for non-specialized items. Covers materials, tools, ammo, vehicle parts, medical, trapping, fishing, and misc.

Notable unique properties (beyond common): `CanStack`, `AmmoType`, `GunType`, `MaxAmmo` (for magazines), `BandagePower`, `CanBandage`, `Sharpness`, `Material`, `CanStoreWater`, `MaxCapacity`, `RainFactor`, `DigType`, `Trap`, `FishingLure`, `MechanicsItem`, `EquippedNoSprint`, `RemoteController`, `RemoteRange`, `SoundRadius`, `SoundVolume`, `Opened`, `OpeningRecipe`, `ProtectFromRainWhenEquipped`, `Wet`/`WetCooldown`.

Vehicle part properties: `VehicleType`, `VehiclePartModel`, `brakeForce`, `engineLoudness`, `suspensionCompression`, `suspensionDamping`, `wheelFriction`, `MaxHitPoints`, `ConditionLowerOffroad`, `ConditionLowerStandard`, `HeadCondition`, `HeadConditionLowerChanceMultiplier`.

## 5. Weapon (HandWeapon) Properties

File: `weapon.txt` - 409 items. Melee and ranged weapons.

### Melee Weapon Properties

**Damage**: `MinDamage`/`MaxDamage` (float), `DamageCategory` (Slash/Blunt), `DamageMakeHole` (bool), `CriticalChance` (float %), `CritDmgMultiplier` (float)

**Range/Speed**: `MinRange`/`MaxRange` (tiles), `BaseSpeed`, `Swingtime`, `MinimumSwingtime`, `SwingAmountBeforeImpact`, `MinAngle`, `HitAngleMod`

**Classification**: `Categories` (`base:blunt`, `base:blade`, etc.), `SubCategory` (Swinging/Firearm), `SwingAnim` (Bat/Spear/Knife/etc.)

**Combat effects**: `KnockdownMod`, `KnockBackOnNoDeath`, `PushBackMod`, `MaxHitcount` (max zombies per swing), `EnduranceMod`, `CloseKillMove`, `SplatBloodOnNoDeath`/`SplatNumber`/`SplatSize`

**Environment**: `DoorDamage`, `TreeDamage`, `CanBarricade`, `TwoHandWeapon`, `WeaponLength`

**Sounds**: `SwingSound`, `HitSound`, `HitFloorSound`, `DoorHitSound`, `BreakSound`, `DropSound`

**Callbacks**: `OnBreak` (Lua on weapon break), `OtherHandRequire`/`OtherHandUse`

### Ranged Weapon Properties (Firearms)

**Core**: `Ranged` (bool), `IsAimedFirearm`, `IsAimedHandWeapon`, `SubCategory = Firearm`

**Ammo**: `AmmoType`, `AmmoBox`, `MagazineType`, `ClipSize` (internal), `MaxAmmo`, `HaveChamber`

**Firing**: `FireMode` (Single/Auto), `FireModePossibilities`, `FireRange`, `Projectilecount` (pellets per shot), `ProjectileSpread`, `HitChance` (base %), `StopPower`, `PiercingBullets`, `RangeFalloff`, `AngleFalloff`

**Aiming**: `AimingMod`, `AimingPerkCritModifier`, `AimingPerkHitChanceModifier`, `AimingPerkMinAngleModifier`, `AimingPerkRangeModifier`, `Aimingtime`, `MinSightRange`/`MaxSightRange`

**Mechanics**: `Reloadtime`, `RecoilDelay`, `JamGunChance`, `WeaponReloadType`, `InsertAllBulletsReload`, `RackAfterShoot`, `ManuallyRemoveSpentRounds`

**Sound**: `SoundRadius` (zombie attraction), `SoundVolume`, `SoundGain`, `NoiseDuration`, `NoiseRange`, `NPCSoundBoost`, plus various per-action sounds (Rack, Eject, Insert, Click, Shell fall, etc.)

### Explosive Properties

`ExplosionPower`, `ExplosionRange`, `ExplosionDuration`, `ExplosionSound`, `ExplosionTimer` (fuse), `SensorRange` (motion sensor), `SmokeRange`, `CanBeRemote`, `CanBeReused`, `PlacedSprite` (trap sprite).

## 6. Food Properties

File: `food.txt` - 722 items.

| Property | Type | Description |
|-|-|-|
| HungerChange | float | Hunger reduction (negative = fills) |
| ThirstChange | float | Thirst reduction (negative = quenches) |
| Calories | float | Caloric value |
| Carbohydrates | float | Carb content |
| Proteins | float | Protein content |
| Lipids | float | Fat content |
| FoodType | string | Category (Vegetables, Meat, Berry, etc.) |
| EatType | string | Eating animation (Plate, Popcan, etc.) |
| PourType | string | Pouring type (Mug, Bottle, etc.) |
| Eattime | int | Time to consume (ticks) |
| DaysFresh | int | Days before going stale |
| DaysTotallyRotten | int | Days until completely rotten |
| IsCookable | bool | Can be cooked |
| MinutesToCook | int | Cooking time |
| MinutesToBurn | int | Time until burnt |
| GoodHot | bool | Bonus when eaten hot |
| CookingSound | string | Sound while cooking (FryingFood, BoilingFood) |
| DangerousUncooked | bool | Causes illness if eaten raw |
| CannedFood | bool | Sealed canned food |
| Packaged | bool | Sealed packaging |
| EvolvedRecipe | string | Recipes this can be added to (format: `Recipe:amount`) |
| EvolvedRecipeName | string | Display name in evolved recipes |
| UnhappyChange | int | Mood effect (negative = improves) |
| BoredomChange | int | Boredom effect |
| StressChange | int | Stress effect |
| PoisonPower | float | Poison damage if eaten |
| FoodSicknessChange | float | Food sickness contribution |
| ReplaceOnUse | string | Item left after eating |
| ReplaceOnCooked | string | Item after cooking |
| ReplaceOnRotten | string | Item when rotten |
| RemoveNegativeEffectOnCooked | bool | Cooking removes bad effects |
| RemoveUnhappinessWhenCooked | bool | Cooking removes unhappiness |
| OnCooked | string | Lua callback on cooking |
| OnEat | string | Lua callback on eating |
| HerbalistType | string | Herbalist identification type |
| BadCold | bool | Causes cold debuff |
| BadInMicrowave | bool | Dangerous in microwave |
| fluReduction | float | Flu symptom reduction |
| painReduction | float | Pain reduction |
| enduranceChange | float | Endurance effect |
| fatigueChange | float | Fatigue effect |
| ReduceInfectionPower | float | Infection treatment power |
| IsDung | bool | Animal dung (fertilizer) |
| FishingLure | bool | Usable as fishing bait |

## 7. Drainable Properties

File: `drainable.txt` - 149 items. Items with a depleting usage bar.

**Core**: `UseDelta` (float, amount per use 0.0-1.0), `UseWhileEquipped`/`UseWhileUnequipped` (bool, auto-drain), `ReplaceOnDeplete` (item when empty), `KeepOnDeplete`, `DisappearOnUse`

**Water containers**: `CanStoreWater`, `IsWaterSource`, `RainFactor`, `FillFromDispenserSound`, `FillFromTapSound`

**Light sources**: `ActivatedItem` (toggle on/off), `LightDistance`, `LightStrength`, `TorchCone`, `TorchDot`

**Other**: `ticksPerEquipUse`, `AlcoholPower`, `MakeUpType`, `MechanicsItem`, `VehicleType`, `AnimalFeedType`, `ConsolidateOption`/`cantBeConsolided`

Also inherits many food properties (HungerChange, Calories, etc.) for drinkable containers.

## 8. Literature Properties

File: `literature.txt` - 561 items.

| Property | Type | Description |
|-|-|-|
| SkillTrained | string | Skill this book trains (Carpentry, Cooking, etc.) |
| LvlSkillTrained | int | Starting skill level for XP bonus |
| NumLevelsTrained | int | Number of levels covered (usually 2) |
| NumberOfPages | int | Total pages to read |
| ReadType | string | Reading behavior type |
| LearnedRecipes | string | Recipes unlocked on reading (semicolons) |
| BoredomChange | int | Boredom reduction per read session |
| StressChange | int | Stress reduction per read session |
| UnhappyChange | int | Mood effect |
| CanBeWrite | bool | Player can write in this |
| PageToWrite | int | Pages available for writing |
| book_subject | string | Non-skill book topic |
| magazine_subject | string | Magazine topic identifier |
| OnCreate | string | Lua callback for randomization |

Skill books follow a naming pattern: `BookCarpentry1` through `BookCarpentry5`, covering skill levels 1-2, 3-4, 5-6, 7-8, 9-10. Magazines use `LearnedRecipes` to unlock crafting recipes.

## 9. Clothing Properties

File: `clothing.txt` - 1395 items. See also `clothing-catalog.md` for deep dive.

| Property | Type | Description |
|-|-|-|
| BodyLocation | string | Body slot (e.g. `base:hat`, `base:jacket`) |
| ClothingItem | string | Reference to clothing XML definition |
| BloodLocation | string | Blood splatter zones (semicolon-separated) |
| FabricType | string | Material: Cotton, Denim, Leather |
| BiteDefense | int | Bite protection percentage (0-100) |
| ScratchDefense | int | Scratch protection percentage (0-100) |
| BulletDefense | int | Bullet protection percentage (0-100) |
| Insulation | float | Warmth value (0.0-1.0+) |
| WindResistance | float | Wind chill protection (0.0-1.0) |
| WaterResistance | float | Water resistance (0.0-1.0) |
| RunSpeedModifier | float | Movement speed multiplier (< 1.0 = slower) |
| CombatSpeedModifier | float | Attack speed multiplier |
| DiscomfortModifier | float | Discomfort penalty |
| ChanceToFall | int | Chance to fall off (hats, percentage) |
| CanHaveHoles | bool | Can develop holes from damage |
| RemoveOnBroken | bool | Auto-remove when broken |
| hidden | bool | Not visible in inventory |
| WorldRender | bool | Renders on character in world |
| Cosmetic | bool | Purely visual, no stats |
| CorpseSicknessDefense | float | Corpse sickness protection |
| NeckProtectionModifier | float | Neck bite protection bonus |
| VisionModifier | float | Vision range modifier |
| HearingModifier | float | Hearing range modifier |
| ShoutMultiplier | float | Shout volume modifier |
| ShoutType | string | Shout sound type |
| StompPower | float | Stomp attack power bonus |
| VisualAid | bool | Corrective lenses flag |
| BreakSound | string | Armor break sound |
| BulletHitArmourSound | string | Bullet impact sound on armor |
| WeaponHitArmourSound | string | Melee impact sound on armor |
| ClothingExtraSubmenu | string | Extra clothing layer submenu |
| ClothingItemExtra | string | Additional clothing layer ref |
| ClothingItemExtraOption | string | Extra layer variant |
| SpawnWith | string | Item spawns paired with this |
| WithDrainable/WithoutDrainable | string | Paired drainable item states |

## 10. Container Properties

File: `container.txt` - 308 items.

| Property | Type | Description |
|-|-|-|
| Capacity | int | Storage capacity (units) |
| WeightReduction | int | Weight reduction percentage (0-100) |
| CanBeEquipped | string | Equip slot (`base:back`, etc.) |
| AcceptItemFunction | string | Lua filter for accepted items |
| MaxItemSize | int | Maximum single-item size allowed |
| AttachmentReplacement | string | Visual attachment override |
| AttachmentsProvided | string | Attachment slots provided |
| ClothingItem | string | Clothing XML ref for worn appearance |
| OpenSound/CloseSound | string | Container open/close sounds |
| PutInSound | string | Item insertion sound |
| EquipSound | string | Equip sound effect |
| SoundParameter | string | FMOD sound parameter |
| RunSpeedModifier | float | Movement speed penalty |
| CombatSpeedModifier | float | Combat speed penalty |
| DiscomfortModifier | float | Wearing discomfort |
| ContainerName | string | Internal container reference |
| Medical | bool | Medical supply container |
| SurvivalGear | bool | Survival gear flag |
| ReplaceInPrimaryHand | string | Model when in right hand |
| ReplaceInSecondHand | string | Model when in left hand |
| fluid | string | Fluid container configuration |
| InitialPercentMin/Max | float | Starting fill range |

## 11. Other Types

### Key (6 items)

| Property | Type | Description |
|-|-|-|
| Padlock | bool | This is a padlock item |
| DigitalPadlock | bool | Combination lock |
| OriginX/OriginY/originZ | int | Key origin coordinates |

### Map (15 items)

| Property | Type | Description |
|-|-|-|
| Map | string | Map region identifier (e.g. MuldraughMap, RiversideMap) |

### AlarmClock (2 items + 16 wearable)

| Property | Type | Description |
|-|-|-|
| AlarmSound | string | Alarm sound effect |
| SoundRadius | int | Alarm noise radius |

Wearable alarm clocks (wristwatches) in `alarmclockclothing.txt` combine alarm clock and clothing properties.

### Radio (17 items)

`IsPortable`, `IsTelevision`, `TwoWay`, `MinChannel`/`MaxChannel` (frequency range), `TransmitRange`, `MicRange`, `BaseVolumeRange`, `IsHighTier`, `UsesBattery`, `AcceptMediaType` (VHS/CD), `NoTransmit`

### WeaponPart (11 items)

`PartType` (Scope/Sling/Canon/RecoilPad), `MountOn` (compatible weapons), `WeightModifier`, `AimingTimeModifier`, `HitChanceModifier`, `MaxRangeModifier`, `RecoilDelayModifier`, `ReloadTimeModifier`, `ProjectileSpreadModifier`, `MinSightRange`/`MaxSightRange`, `LowLightBonus`, `CanAttach`/`CanDetach`

## 12. Item Counts by Category

### By ItemType File

| ItemType | File | Count |
|-|-|-|
| clothing | clothing.txt | 1395 |
| normal | normal.txt | 1112 |
| food | food.txt | 722 |
| literature | literature.txt | 561 |
| weapon | weapon.txt | 409 |
| moveable | moveable.txt | 381 |
| container | container.txt | 308 |
| drainable | drainable.txt | 149 |
| radio | radio.txt | 17 |
| alarmclock (clothing) | alarmclockclothing.txt | 16 |
| map | map.txt | 15 |
| weaponpart | weaponpart.txt | 11 |
| key | key.txt | 6 |
| alarmclock | alarmclock.txt | 2 |
| animal | animal.txt | 1 |
| **Total** | | **5105** |

### Top DisplayCategory Values (80+ categories total)

Food(707), Clothing(481), Material(386), Accessory(354), Furniture(337), ProtectiveGear(290), Memento(218), Literature(198), Container(162), RecipeResource(150), SkillBook(144), Gardening(137), WeaponCrafted(115), Junk(109), Bag(107), VehicleMaintenance(105), ZedDmg(74), Tool(72), AnimalPart(69), Wound(60), Cooking(54), FirstAid(53), ToolWeapon(53), Camping(45), Weapon(44), Electronics(43), and 55+ more categories.

## 13. Example Definitions

### Melee Weapon - key combat properties annotated

```
item SpadeHead {
    ItemType = base:weapon, Categories = base:blunt, SubCategory = Swinging,
    MinDamage = 0.4, MaxDamage = 0.8,     -- damage range per hit
    MinRange = 0.61, MaxRange = 1.1,       -- attack reach in tiles
    BaseSpeed = 1.2, Swingtime = 4.0,      -- attack timing
    CriticalChance = 15.0, CritDmgMultiplier = 2.0,
    MaxHitcount = 2, KnockdownMod = 2.0, PushBackMod = 0.3,
    DoorDamage = 5, TreeDamage = 5,
    ConditionMax = 10, ConditionLowerChanceOneIn = 15,
    SwingAnim = Bat, DamageCategory = Slash, DamageMakeHole = true,
}
```

### Ranged Weapon (Shotgun) - firearm-specific properties

```
item Shotgun {
    ItemType = base:weapon, Ranged = true, IsAimedFirearm = true,
    AmmoType = base:shotgun_shells, MaxAmmo = 5, FireMode = Single,
    HitChance = 65, MaxRange = 8.0, SoundRadius = 60,
    CriticalChance = 70.0, CritDmgMultiplier = 12.0,
    StopPower = 5.0, KnockdownMod = 8.0,
    Aimingtime = 40, AimingMod = 2.0, RecoilDelay = 11,
    Reloadtime = 30, JamGunChance = 2,
}
```

### Food Item - nutrition and spoilage

```
item Tomato {
    ItemType = base:food, FoodType = Vegetables,
    HungerChange = -12.0, ThirstChange = -8.0,   -- negative = fills
    Calories = 14.0, Carbohydrates = 3.5, Proteins = 1.3, Lipids = 0.2,
    DaysFresh = 4, DaysTotallyRotten = 12,
    IsCookable = true, MinutesToCook = 10, MinutesToBurn = 30, GoodHot = true,
    EvolvedRecipe = Pizza:12;Soup:12;Stew:12;Salad:6;Sandwich:6,
}
```

### Drainable - usage bar item

```
item TestWaterMug {
    ItemType = base:drainable, UseDelta = 1.0, UseWhileEquipped = false,
    CanStoreWater = true, IsWaterSource = true, RainFactor = 0.2,
    ReplaceOnDeplete = Base.TestMug,  -- returns empty mug when drained
    IsCookable = true, CookingSound = BoilingFood,
}
```

### Container - bag with weight reduction

```
item Bag_Schoolbag {
    ItemType = base:container, Capacity = 15, WeightReduction = 70,
    CanBeEquipped = base:back, RunSpeedModifier = 0.97,
    ClothingItem = Bag_SchoolBag, AttachmentReplacement = Bag,
}
```

### Skill Book - XP multiplier literature

```
item BookCarpentry1 {
    ItemType = base:literature, SkillTrained = Carpentry,
    LvlSkillTrained = 1, NumLevelsTrained = 2,  -- covers levels 1-2
    NumberOfPages = 220,
}
```
