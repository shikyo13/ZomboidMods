# Inventory System - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | ItemContainer | 18-67 |
| 2 | InventoryItem (base) | 68-175 |
| 3 | Food | 176-227 |
| 4 | HandWeapon | 228-329 |
| 5 | DrainableComboItem | 330-341 |
| 6 | Literature | 342-357 |
| 7 | Clothing | 358-376 |
| 8 | Key, MapItem, AlarmClock | 377-409 |
| 9 | WeaponType enum | 410-427 |
| 10 | Container types and capacities | 428-451 |

## 1. ItemContainer
`zombie.inventory.ItemContainer` - final class. Holds items for world objects, vehicles, characters, bags.

### Constants
| Name | Type | Value | Note |
|-|-|-|-|
| MAX_CAPACITY | [static] int | 100 | World containers |
| MAX_CAPACITY_BAG | [static] int | 50 | Bag/item containers |
| MAX_CAPACITY_VEHICLE | [static] int | 1000 | Vehicle parts |

### Fields
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| active | [pub] | boolean | false | Container is usable |
| dirty | [priv] | boolean | true | Needs redraw |
| isdevice | [pub] | boolean | false | Is electronic device |
| ageFactor | [pub] | float | 1.0 | Food aging speed (fridge=0.02) |
| cookingFactor | [pub] | float | 1.0 | Cooking speed (fridge=0.0) |
| capacity | [pub] | int | 50 | Weight capacity |
| containingItem | [pub] | InventoryItem | null | Bag item that owns this container |
| items | [pub] | ArrayList<InventoryItem> | [] | Active items |
| includingObsoleteItems | [pub] | ArrayList<InventoryItem> | [] | All items incl. obsolete |
| parent | [pub] | IsoObject | null | World object owner |
| sourceGrid | [pub] | IsoGridSquare | null | Grid location |
| vehiclePart | [pub] | VehiclePart | null | Vehicle part owner |
| inventoryContainer | [pub] | InventoryContainer | null | Linked InventoryContainer item |
| explored | [pub] | boolean | false | Has been searched |
| type | [pub] | String | "none" | Container type ID |
| id | [pub] | int | -1 | Unique container ID |
| weightReduction | [priv] | int | 0 | Weight reduction percent |
| onlyAcceptCategory | [priv] | String | null | Category filter |
| acceptItemFunction | [priv] | String | null | Lua function filter |
| customTemperature | [priv] | float | 0 | Override temperature |
| hasBeenLooted | [priv] | boolean | false | Ever looted |
| openSound, closeSound | [priv] | String | null | UI sounds |
| putSound, takeSound | [priv] | String | null | Item transfer sounds |
| containerPosition | [priv] | String | null | Position identifier |
| freezerPosition | [priv] | String | null | Freezer slot |

### Key Methods (all [pub])
**Capacity**: getCapacity(), setCapacity(int), getEffectiveCapacity(IsoGameCharacter) [+30% Organized/-30% Disorganized], hasRoomFor(chr, item), getFreeCapacity(chr), isFull(chr)

**Add/Remove**: AddItem(InventoryItem), AddItem(String), AddItem(String, float), AddItems(String, int), Remove(InventoryItem), RemoveAll(String, int), RemoveOneOf(String, boolean)

**Query (each has Recurse variant)**: getFirstType(String), getFirstTag(ItemTag), getFirstCategory(String), getAll(Predicate), getSome(Predicate, int, ArrayList), getCount(Predicate), getCountType(String), getCountTag(ItemTag), getBest(Predicate, Comparator), getBestCondition(String)

**Eval variants** (Lua callbacks): getFirstEval(LuaClosure), containsEvalRecurse(LuaClosure), getBestEvalArgRecurse(LuaClosure, LuaClosure, Object), etc. Pattern: `{method}{Eval|EvalArg}{Recurse}`.

**Utility**: contains(String), containsTypeRecurse(String), isItemAllowed(InventoryItem), getContentsWeight(), getCapacityWeight(), getTemprature(), FindWaterSource(), getBestWeapon(), getItemFromType(String, IsoGameCharacter, ...), save/load(ByteBuffer)

## 2. InventoryItem (base)
`zombie.inventory.InventoryItem extends GameEntity` - base class for all items.

### Core Fields
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| scriptItem | [prot] | Item | - | Script definition ref |
| itemType | [prot] | ItemType | - | Type enum |
| container | [prot] | ItemContainer | null | Parent container |
| name | [prot] | String | - | Display name |
| type | [prot] | String | - | Short type ID |
| fullType | [prot] | String | - | Module.Type |
| module | [prot] | String | - | Module name |
| id | [pub] | int | - | Unique instance ID |

### Condition and Durability
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| condition | [prot] | int | 10 | Current condition |
| conditionMax | [prot] | int | 10 | Max condition |
| broken | [priv] | boolean | false | Is broken |
| haveBeenRepaired | [priv] | int | 0 | Repair count |

### Weight and Uses
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| weight | [prot] | float | 1.0 | Base weight |
| actualWeight | [prot] | float | 1.0 | Actual weight |
| uses | [prot] | int | 1 | Remaining uses |
| useDelta | [priv] | float | 0.03125 | Per-use drain |
| count | [priv] | int | 1 | Stack count |

### Age and Cooking
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| age | [prot] | float | 0 | Current age |
| lastAged | [prot] | float | -1.0 | Last age update time |
| isCookable | [prot] | boolean | false | Can be cooked |
| cookingTime | [prot] | float | 0 | Time cooked so far |
| minutesToCook | [prot] | float | 60.0 | Time to finish cooking |
| minutesToBurn | [prot] | float | 120.0 | Time to burn |
| cooked | [pub] | boolean | false | Is cooked |
| burnt | [prot] | boolean | false | Is burnt |
| offAge | [prot] | int | 1e9 | Age when stale |
| offAgeMax | [prot] | int | 1e9 | Age when rotten |

### Mood Effects
| Name | Mod | Type | Default |
|-|-|-|-|
| boredomChange | [prot] | float | 0 |
| unhappyChange | [prot] | float | 0 |
| stressChange | [prot] | float | 0 |
| fatigueChange | [pub] | float | 0 |
| foodSicknessChange | [prot] | int | 0 |

### Medical
| Name | Mod | Type | Default |
|-|-|-|-|
| alcoholic | [prot] | boolean | false |
| alcoholPower | [priv] | float | 0 |
| bandagePower | [priv] | float | 0 |
| reduceInfectionPower | [priv] | float | 0 |

### Visual and World
| Name | Mod | Type | Default |
|-|-|-|-|
| texture, texturerotten, textureCooked, textureBurnt | [prot] | Texture | - |
| worldTexture | [prot] | String | - |
| staticModel | [prot] | String | - |
| visual | [prot] | ItemVisual | - |
| col | [pub] | Color | white |
| colorRed/Green/Blue | [priv] | float | 1.0 |
| worldScale | [pub] | float | 1.0 |
| worldX/Y/ZRotation | [pub] | float | 0/0/-1.0 |

### Equipment and Interaction
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| requiresEquippedBothHands | [pub] | boolean | false | Needs both hands |
| canStack | [pub] | boolean | false | Stackable |
| activated, canBeActivated | [priv] | boolean | false | Toggle state |
| isTorchCone | [priv] | boolean | false | Cone-shaped light |
| lightDistance | [priv] | int | 0 | Light radius |
| lightStrength | [priv] | float | 0 | Light intensity |
| favorite | [priv] | boolean | false | Marked favorite |
| remoteController, canBeRemote | [priv] | boolean | false | Remote control flags |
| remoteControlId, remoteRange | [priv] | int | -1, 0 | Remote channel/range |
| keyId | [priv] | int | -1 | Lock key ID |
| ammoType | [priv] | AmmoType | - | Ammo compatibility |
| maxAmmo, currentAmmoCount | [priv] | int | 0 | Magazine state |
| gunType | [priv] | ArrayList<String> | - | Compatible gun types |
| attachmentType, attachedSlotType | [priv] | String | - | Attachment system |
| attachedSlot | [priv] | int | -1 | Attachment slot index |

### Vehicle Part Fields (all [priv] float, default 0)
brakeForce, durability, wheelFriction, suspensionDamping, suspensionCompression, engineLoudness, conditionLowerNormal, conditionLowerOffroad

### Key Methods (all [pub])
**Type checks**: IsFood(), IsWeapon(), IsDrainable(), IsLiterature(), IsClothing(), IsMap()
**State**: IsRotten(), HowRotten(), CanStack(item), isBroken(), isCooked(), isBurnt()
**Usage**: Use(), Use(boolean), UseAndSync(), update(), finishupdate()
**Serialization**: save(ByteBuffer, boolean), load(ByteBuffer, int), loadItem(ByteBuffer, int) [static], createCloneItem()
**Container**: getOutermostContainer(), isInLocalPlayerInventory(), getContainer()
**Equipment**: getEquipParent(), setEquipParent(IsoGameCharacter), getBodyLocation(), hasTag(ItemTag...)
**Properties**: isWaterSource(), canEmitLight(), isEmittingLight(), getCurrentCondition() [ratio 0-1]
**Damage system**: damageCheck(int, float, boolean, boolean, IsoGameCharacter), sharpnessCheck(int, float, boolean, boolean), getSharpness(), getMaxSharpness()
**Weight**: getContentsWeight(), getEquippedWeight(), getUnequippedWeight()

## 3. Food
`zombie.inventory.types.Food extends InventoryItem` - final class.

### Fields
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| hungChange | [prot] | float | 0 | Hunger reduction |
| thirstChange | [pub] | float | 0 | Thirst reduction |
| endChange | [prot] | float | 0 | Endurance change |
| heat | [prot] | float | 1.0 | Temperature (0.2-3.0) |
| rotten | [prot] | boolean | false | Is rotten |
| dangerousUncooked | [prot] | boolean | false | Raw is harmful |
| poison | [pub] | boolean | false | Is poisoned |
| poisonPower | [priv] | int | 0 | Poison strength |
| poisonDetectionLevel | [priv] | int | -1 | Skill to detect |
| poisonLevelForRecipe | [priv] | int | 0 | Poison in recipes |
| useForPoison | [priv] | int | 0 | Uses for poisoning |
| badCold | [prot] | boolean | false | Worse when cold |
| goodHot | [prot] | boolean | false | Better when hot |
| baseHunger | [priv] | float | 0 | Base hunger value |
| calories | [priv] | float | 0 | Calorie content |
| carbohydrates | [priv] | float | 0 | Carb content |
| lipids | [priv] | float | 0 | Fat content |
| proteins | [priv] | float | 0 | Protein content |
| foodType | [priv] | String | null | Category (Fruits, Meat, etc.) |
| isSpice | [priv] | boolean | false | Is a spice |
| spices | [pub] | ArrayList<String> | null | Applied spices |
| chef | [priv] | String | null | Who cooked it |
| onCooked | [priv] | String | null | Lua callback on cook |
| onEat | [priv] | String | null | Lua callback on eat |
| replaceOnCooked | [priv] | List<String> | null | Transform on cook |
| replaceOnRotten | [priv] | String | null | Transform on rot |
| removeNegativeEffectOnCooked | [priv] | boolean | false | Cooking removes negatives |
| customEatSound | [priv] | String | null | Override eat sound |
| herbalistType | [priv] | String | null | Herbalist identification |
| fluReduction | [priv] | int | 0 | Cold/flu healing |
| painReduction | [priv] | float | 0 | Pain relief |
| packaged | [priv] | boolean | false | In packaging |
| frozen | [priv] | boolean | false | Currently frozen |
| canBeFrozen | [priv] | boolean | true | Freezable |
| freezingTime | [priv] | float | 0 | Time to freeze |
| badInMicrowave | [priv] | boolean | false | Sparks in microwave |
| cookedInMicrowave | [priv] | boolean | false | Cooked via microwave |
| lastCookMinute | [prot] | int | 0 | Last cook timestamp |
| compostTime | [priv] | float | 0 | Composting timer |
| fertilized | [priv] | boolean | false | Egg: fertilized |
| timeToHatch | [priv] | int | 0 | Egg: hatch timer |
| animalHatch | [priv] | String | null | Egg: animal type |

### Key Methods
getHungerChange/ThirstChange/BoredomChange/UnhappyChange/StressChange/EnduranceChange() - all modified by traits/cooking state. getCarbohydrates/Lipids/Proteins/Calories(). isRotten(), isFresh(), updateAge(boolean), setAutoAge(), getHeat()/setHeat(float) [0.2-3.0], checkEggHatch(IsoHutch).

## 4. HandWeapon
`zombie.inventory.types.HandWeapon extends InventoryItem` - final class.

### Core Damage Fields
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| minDamage | [priv] | float | 0.4 | Minimum damage |
| maxDamage | [priv] | float | 1.5 | Maximum damage |
| criticalChance | [priv] | float | 20.0 | Crit % base |
| criticalDamageMultiplier | [priv] | float | 2.0 | Crit damage mult |
| extraDamage | [priv] | float | 0 | Bonus damage (explosive) |
| doorDamage | [priv] | int | 1 | Damage to doors |
| treeDamage | [priv] | int | 0 | Damage to trees |
| damageCategory | [priv] | String | null | Damage type string |
| damageMakeHole | [priv] | boolean | false | Punches holes in clothing |

### Range and Angle
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| minRange | [priv] | float | 0 | Minimum attack range |
| maxRange | [priv] | float | 1.0 | Maximum attack range |
| minAngle | [priv] | float | 0.5 | Min swing arc |
| maxAngle | [priv] | float | 1.0 | Max swing arc |
| angleFalloff | [priv] | boolean | false | Damage falloff by angle |
| rangeFalloff | [priv] | boolean | false | Damage falloff by range (shotgun) |
| hitAngleMod | [pub] | float | 0 | Hit angle modifier |
| weaponLength | [pub] | float | 0 | Physical length |

### Speed and Timing
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| swingTime | [priv] | float | 1.0 | Swing duration |
| minimumSwingTime | [priv] | float | 0.5 | Min swing time |
| baseSpeed | [priv] | float | 1.0 | Animation speed |
| doSwingBeforeImpact | [priv] | float | 0 | Pre-impact timing |
| recoilDelay | [priv] | int | 0 | Post-shot delay |

### Knockback and Hit Count
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| pushBackMod | [priv] | float | 1.0 | Knockback force |
| knockdownMod | [priv] | float | 1.0 | Knockdown modifier |
| knockBackOnNoDeath | [priv] | boolean | true | Knockback even if no kill |
| alwaysKnockdown | [priv] | boolean | false | Guaranteed knockdown |
| maxHitCount | [priv] | int | 1000 | Max targets per swing |
| splatBloodOnNoDeath | [priv] | boolean | false | Blood on non-fatal |
| splatNumber | [priv] | int | 2 | Blood splat count |
| splatSize | [pub] | float | 1.0 | Splat scale |

### Endurance and Condition
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| useEndurance | [priv] | boolean | true | Costs stamina |
| enduranceMod | [priv] | float | 1.0 | Endurance cost mult |
| shareEndurance | [priv] | boolean | true | Split endurance on multi-hit |
| cantAttackWithLowestEndurance | [priv] | boolean | false | Block at 0 stamina |
| conditionLowerChance | [priv] | int | 10 | Condition loss chance (1/N) |
| multipleHitConditionAffected | [priv] | boolean | true | Multi-hit degrades faster |

### Sound (all [priv])
| Name | Type | Default |
|-|-|-|
| swingSound | String | "BaseballBatSwing" |
| impactSound, hitSound, doorHitSound | String | "BaseballBatHit" |
| hitFloorSound | String | "BatOnFloor" |
| clickSound | String | "Stormy9mmClick" |
| rackSound | String | null |
| soundRadius, soundVolume | int | 0 |
| soundGain | float | 1.0 |
| noiseFactor | float | 0 |

### Ranged/Firearm Fields (all [priv] unless noted)
| Name | Type | Default | Note |
|-|-|-|-|
| ranged | boolean | false | Is ranged weapon |
| isAimedFirearm [pub] | boolean | false | Uses aim system |
| isAimedHandWeapon [pub] | boolean | false | Aimed melee |
| clipSize, reloadTime, aimingTime | int | 0 | Magazine/reload/aim timing |
| ammoPerShoot | int | 1 | Ammo per shot |
| magazineType, weaponReloadType | String | null/"handgun" | Magazine/reload type |
| containsClip, roundChambered | boolean | false | Chamber/magazine state |
| spentRoundChambered | boolean | false | Spent casing in chamber |
| rackAfterShoot | boolean | false | Pump/bolt action |
| haveChamber | boolean | true | Has a chamber |
| jamGunChance | float | 5.0 | Jam probability % |
| isJammed | boolean | false | Currently jammed |
| piercingBullets | boolean | false | Bullets pass through |
| projectileCount | int | 1 | Pellets per shot (shotgun) |
| projectileSpread | float | 0 | Pellet spread angle |
| hitChance | int | 0 | Base hit % |
| fireMode | String | null | Current fire mode |

### Explosive Fields (all [priv], default 0/false)
int: explosionRange, explosionPower, explosionTimer, explosionDuration, triggerExplosionTimer, fireRange, fireStartingEnergy, fireStartingChance, smokeRange, noiseRange, sensorRange.
boolean: canBePlaced, canBeReused, isExplosive (false), isMelee (true).

### Key Methods
**Skill-scaled getters** (all take IsoGameCharacter): getDamageMod, getRangeMod, getFatigueMod, getKnockbackMod, getSpeedMod, getToHitMod, muscleStrainMod.
**Skill info**: getWeaponSkill(chr), getPerk(), getMaxRange(chr).
**Firearm**: isReloadable(chr), checkJam(IsoPlayer, boolean), checkUnJam(IsoPlayer).
**Attachments**: attachWeaponPart(chr, part), detachWeaponPart(chr, part), getWeaponPart(String), clearAllWeaponParts(), getAllWeaponParts().

## 5. DrainableComboItem
`zombie.inventory.types.DrainableComboItem extends InventoryItem` - final. Items with partial uses (gas cans, lighters, etc.).

### Fields
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| replaceOnCooked | [pub] | List<String> | null | Transform on cook |
| (inherits useDelta, uses from InventoryItem) | | | | |

### Key Methods
getMaxUses() [1/useDelta], getCurrentUses()/setCurrentUses(int), getCurrentUsesFloat(), getUseDelta()/setUsedDelta(float), getWeightEmpty()/setWeightEmpty(float), isUseWhileEquiped(), getTicksPerEquipUse(), getReplaceOnDeplete(), canConsolidate(), getHeat()/setHeat(float), isEnergy(), isFullUses()/isEmptyUses(), randomizeUses().

## 6. Literature
`zombie.inventory.types.Literature extends InventoryItem` - final. Books, magazines, maps with recipes.

### Fields
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| alreadyRead | [pub] | boolean | false | Fully read |
| requireInHandOrInventory | [pub] | String | null | Required companion item |
| useOnConsume | [pub] | String | null | Item given on finish |

### Key Methods
**Pages**: getNumberOfPages(), getAlreadyReadPages()/set, canBeWrite(), getCustomPages(), addPage(Integer, String), seePage(Integer).
**Skill training**: getSkillTrained()/set, getLvlSkillTrained()/set, getNumLevelsTrained()/set, getMaxLevelTrained() [lvl + num].
**Recipes**: getLearnedRecipes(), hasRecipe(String), containsKnownRecipe(chr), getKnownRecipes(chr), containsCraftRecipe(), containsBuildRecipe().
**Other**: getBookName()/set, getLockedBy()/set, getReadType().

## 7. Clothing
`zombie.inventory.types.Clothing extends InventoryItem` - non-final.

### Fields
| Name | Mod | Type | Default | Note |
|-|-|-|-|-|
| spriteName | [prot] | String | - | Visual sprite |
| palette | [prot] | String | - | Color palette |
| bloodLevel | [pub] | float | 0 | Blood coverage |
| CONDITION_PER_HOLES | [static] | int | 3 | Condition lost per hole |

### Properties (all via getters/setters)
**Defense** (float): biteDefense, scratchDefense, bulletDefense, neckProtectionModifier, windresistance, waterResistance, insulation.
**State** (float): temperature, dirtiness, bloodlevel, wetness, weightWet. (int): holesNumber, patchesNumber, conditionLowerChance.
**Behavior**: stompPower (float, shoe stomp mult), runSpeedModifier (float), combatSpeedModifier (float), isRemoveOnBroken (Boolean), getCanHaveHoles (Boolean), isCosmetic (boolean), chanceToFall (int).

### Key Methods
getDefForPart(BloodBodyPartType, boolean bite, boolean bullet). addPatch(chr, part, fabric), removePatch(part), fullyRestore(). getCoveredParts(), getNbrOfCoveredParts(). addRandomHole/Dirt/Blood(), randomizeCondition(wet%, dirt%, blood%, hole%). updateWetness(boolean), isDirty()/isBloody()/isWorn(). [static] getBiteDefenseFromItem(chr, fabric), getScratchDefenseFromItem(chr, fabric).

## 8. Key, MapItem, AlarmClock

### Key (`zombie.inventory.types.Key extends InventoryItem`)
| Member | Type | Note |
|-|-|-|
| getKeyId() / setKeyId(int) | int | Lock ID match |
| isPadlock() / setPadlock(boolean) | boolean | Padlock key |
| isDigitalPadlock() / setDigitalPadlock(boolean) | boolean | Digital padlock |
| getNumberOfKey() / setNumberOfKey(int) | int | Copies of key |
| takeKeyId() | void | Generate new key ID |
| setHighlightDoors(int, InventoryItem) | [static] void | Highlight matching doors |

### MapItem (`zombie.inventory.types.MapItem extends InventoryItem`)
| Member | Type | Note |
|-|-|-|
| getMapID() / setMapID(String) | String | Map identifier |
| getSymbols() | WorldMapSymbols | Map annotations |
| worldMapInstance | [static] MapItem | Singleton world map |
| SaveWorldMap() / LoadWorldMap() | [static] void | Persistence |

### AlarmClock (`zombie.inventory.types.AlarmClock extends InventoryItem`)
| Member | Type | Note |
|-|-|-|
| getHour() / setHour(int) | int | Alarm hour |
| getMinute() / setMinute(int) | int | Alarm minute |
| isAlarmSet() / setAlarmSet(boolean) | boolean | Alarm enabled |
| isRinging() | boolean | Currently ringing |
| isDigital() | boolean | Digital clock |
| stopRinging() | void | Silence alarm |
| syncAlarmClock() | void | Network sync |
| getAlarmSound() / setAlarmSound(String) | String | Ring sound |
| getSoundRadius() / setSoundRadius(int) | int | Noise radius |

## 9. WeaponType Enum
`zombie.inventory.types.WeaponType` - determines animation set and attack types.

| Value | AnimType | Attacks | CanMiss | Ranged |
|-|-|-|-|-|
| UNARMED | "" | NONE | yes | no |
| ONE_HANDED | "1handed" | DEFAULT, OVERHEAD, UPPERCUT | yes | no |
| TWO_HANDED | "2handed" | DEFAULT, OVERHEAD, UPPERCUT | yes | no |
| HEAVY | "heavy" | DEFAULT, OVERHEAD | yes | no |
| KNIFE | "knife" | DEFAULT, OVERHEAD, UPPERCUT | yes | no |
| SPEAR | "spear" | DEFAULT | yes | no |
| HANDGUN | "handgun" | NONE | no | yes |
| FIREARM | "firearm" | NONE | no | yes |
| THROWING | "throwing" | NONE | no | yes |
| CHAINSAW | "chainsaw" | DEFAULT | yes | no |

Resolution: SwingAnim -> Stab=KNIFE, Heavy=HEAVY, Throw=THROWING, Spear=SPEAR, Chainsaw=CHAINSAW, ranged+2h=FIREARM, ranged+1h=HANDGUN, 2h=TWO_HANDED, else=ONE_HANDED, fallback=UNARMED.

## 10. Container Types and Capacities

### Capacity Limits
| Context | Max Capacity | Note |
|-|-|-|
| World container | 100 | Shelves, crates, etc. |
| Bag/item container | 50 | Backpacks, bags |
| Vehicle container | 1000 | Trunks, gloveboxes |
| Vehicle occupied seat | capacity/4 | Reduced when occupied |
| Floor weight limit | 50.0 | Max weight on one tile |

### Special Container Types (from constructor)
| Type String | ageFactor | cookingFactor | Note |
|-|-|-|-|
| "fridge" | 0.02 | 0.0 | Refrigerator |
| "none" (default) | 1.0 | 1.0 | Standard container |
| "floor" | 1.0 | 1.0 | Ground tile |
| "clothingrack" | 1.0 | 1.0 | Only accepts Clothing |

### Trait Modifiers
| Trait | Effect |
|-|-|
| Organized | +30% effective capacity |
| Disorganized | -30% effective capacity |
