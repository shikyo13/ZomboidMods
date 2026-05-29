# IsoObject Hierarchy - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | IsoObject (base class) | 18-131 |
| 2 | IsoMovingObject | 132-175 |
| 3 | IsoThumpable (player-built) | 176-274 |
| 4 | IsoBarricade | 275-334 |
| 5 | IsoDoor | 335-397 |
| 6 | IsoWindow | 398-458 |
| 7 | IsoWorldInventoryObject | 459-489 |
| 8 | IsoDeadBody | 490-542 |
| 9 | Interfaces | 543-606 |
| 10 | Enums | 607-672 |

## 1. IsoObject (base class)
Package: `zombie.iso` | Extends: `GameEntity` | Implements: `Serializable, ILuaIsoObject, Thumpable, IsoRenderable`

### Fields
| Access | Type | Name | Default |
|-|-|-|-|
| [pub][static] | int | MAX_WALL_SPLATS | 32 |
| [pub][static] | IsoObject | lastRendered | |
| [pub][static] | float | rmod, gmod, bmod | |
| [pub] | byte | ppfHighlighted, ppfHighlightRenderOnce, ppfBlink | |
| [pub] | boolean | satChair | false |
| [pub] | int | keyId | -1 |
| [pub] | BaseSoundEmitter | emitter | |
| [pub] | float | sheetRopeHealth | 100.0f |
| [pub] | boolean | sheetRope | false |
| [pub] | boolean | neverDoneAlpha | true |
| [pub] | boolean | alphaForced | false |
| [pub] | ArrayList\<IsoSpriteInstance\> | attachedAnimSprite | |
| [pub] | ArrayList\<IsoWallBloodSplat\> | wallBloodSplats | |
| [pub] | ItemContainer | container | |
| [pub] | IsoDirections | dir | IsoDirections.N |
| [pub] | short | damage | 100 |
| [pub] | float | partialThumpDmg | |
| [pub] | boolean | noPicking, outlineOnMouseover | |
| [pub] | float | offsetX | 32 * Core.tileScale |
| [pub] | float | offsetY | 96 * Core.tileScale |
| [pub] | IsoObject | rerouteMask, rerouteCollide | |
| [pub] | IsoSprite | sprite, overlaySprite | |
| [pub] | ColorInfo | overlaySpriteColor | |
| [pub] | IsoGridSquare | square | |
| [pub] | float[] | alpha | |
| [prot] | float[] | targetAlpha | |
| [pub] | KahluaTable | table | |
| [pub] | String | name, spriteName | |
| [pub] | float | tintr, tintg, tintb | 1.0f |
| [pub] | float | sx, sy | |
| [pub] | boolean | doNotSync | |
| [prot] | ObjectRenderEffects | windRenderEffects, objectRenderEffects | |
| [prot] | IsoObject | externalWaterSource | |
| [prot] | boolean | usesExternalWaterSource | |
| [prot] | ArrayList\<IsoObject\> | children | |
| [prot] | byte | isOutlineHighlight, isOutlineHlAttached, isOutlineHlBlink | |
| [prot] | boolean | movedThumpable, animating | |
| [prot] | String | spriteModelName | |
| [prot] | SpriteModel | spriteModel | |
| [pub] | IsoGridSquare | renderSquareOverride, renderSquareOverride2 | |
| [pub] | float | renderDepthAdjust | |

### Constructors
| Signature |
|-|
| IsoObject() |
| IsoObject(IsoCell cell) |
| IsoObject(IsoCell cell, IsoGridSquare square, IsoSprite spr) |
| IsoObject(IsoCell cell, IsoGridSquare square, String gid) |
| IsoObject(IsoGridSquare square, String tile, String name) |
| IsoObject(IsoGridSquare square, String tile, String name, boolean bShareTilesWithMap) |
| IsoObject(IsoGridSquare square, String tile, boolean bShareTilesWithMap) |
| IsoObject(IsoGridSquare square, String tile) |

### Key Methods
| Access | Return | Method |
|-|-|-|
| [pub][static] | IsoObject | getNew(IsoGridSquare sq, String spriteName, String name, boolean bShareTilesWithMap) |
| [pub][static] | byte | factoryGetClassID(String name) |
| [pub][static] | IsoObject | factoryFromFileInput(IsoCell cell, byte classID) |
| [pub][static] | IsoObject | factoryFromFileInput(IsoCell cell, ByteBuffer b) |
| [pub] | void | sync() / sync(int i) |
| [pub] | KahluaTable | getModData() / getTable() |
| [pub] | IsoGridSquare | getSquare() |
| [pub] | void | setSquare(IsoGridSquare square) |
| [pub] | void | update() / DirtySlice() |
| [pub] | String | getObjectName() |
| [pub] | void | load(ByteBuffer input, int worldVersion, boolean isDebugSave) |
| [pub] | void | save(ByteBuffer output, boolean isDebugSave) |
| [pub] | void | AttackObject(IsoGameCharacter owner) |
| [pub] | void | Hit(Vector2 collision, IsoObject obj, float damage) |
| [pub] | void | Damage(float amount) |
| [pub] | void | HitByVehicle(BaseVehicle vehicle, float amount) |
| [pub] | void | Collision(Vector2 collision, IsoObject object) |
| [pub] | IsoSprite | getSprite() / setSprite(IsoSprite) / setSprite(String) |
| [pub] | void | setSpriteFromName(String name) |
| [pub] | float | getAlpha() / getAlpha(int playerIndex) |
| [pub] | void | setAlpha(float) / setAlphaAndTarget(int, float) |
| [pub] | PropertyContainer | getProperties() |
| [pub] | boolean | hasProperty(IsoFlagType flag) / hasProperty(String p) |
| [pub] | float | getX() / getY() / getZ() |
| [pub] | boolean | isFloor() / isWall() / isWallN() / isWallW() |
| [pub] | boolean | isHoppable() / isTallHoppable() / isNorthHoppable() |
| [pub] | boolean | isStairsNorth() / isStairsWest() / isStairsObject() |
| [pub] | boolean | isTableSurface() / isTableTopObject() |
| [pub] | float | getSurfaceOffset() / getSurfaceNormalOffset() |
| [pub] | boolean | haveSheetRope() / canAddSheetRope() |
| [pub] | boolean | addSheetRope(IsoPlayer, String) / removeSheetRope(IsoPlayer) |
| [pub] | ItemContainer | getContainer() / setContainer(ItemContainer) |
| [pub] | int | getContainerCount() |
| [pub] | ItemContainer | getContainerByIndex(int) / getContainerByType(String) |
| [pub] | void | addToWorld() / removeFromWorld() / removeFromSquare() |
| [pub] | void | setHighlighted(int playerIndex, boolean, boolean) |
| [pub] | void | setOutlineHighlight(int playerIndex, boolean) |
| [pub] | void | sendObjectChange(IsoObjectChange change) |
| [pub] | boolean | isDestroyed() |
| [pub] | void | Thump(IsoMovingObject thumper) |
| [pub] | void | WeaponHit(IsoGameCharacter chr, HandWeapon weapon) |
| [pub] | Thumpable | getThumpableFor(IsoGameCharacter chr) |
| [pub] | float | getThumpCondition() |
| [pub] | Vector2 | getFacingPosition(Vector2 pos) |
| [pub] | boolean | hasWater() / isTaintedWater() |
| [pub] | float | getFluidAmount() / getFluidCapacity() / useFluid(float) |
| [pub] | void | addFluid(FluidType, float) / emptyFluid() |
| [pub] | InventoryItem | spawnItemToObjectSurface(String item, boolean, boolean) |
| [pub] | IsoDirections | getFacing() |
| [pub] | boolean | isTent() / isGrave() |

## 2. IsoMovingObject
Package: `zombie.iso` | Extends: `IsoObject` | Implements: `Mover`

### Fields
| Access | Type | Name | Default |
|-|-|-|-|
| [pub][static] | int | MAX_ZOMBIES_EATING | 3 |
| [pub] | boolean | noDamage | |
| [pub] | IsoGridSquare | last | |
| [pub] | Vector2 | reqMovement | new Vector2() |
| [pub] | IsoSpriteInstance | def | |
| [prot] | IsoGridSquare | current | |
| [prot] | Vector2 | hitDir | new Vector2() |
| [prot] | int | id | (auto-increment) |
| [prot] | IsoGridSquare | movingSq | |
| [prot] | boolean | solid | true |
| [prot] | float | width | 0.24f |
| [prot] | boolean | shootable | true |
| [prot] | boolean | collidable | true |
| [prot] | String | scriptModule | "none" |
| [prot] | Vector2 | movementLastFrame | new Vector2() |
| [prot] | float | weight | 1.0f |

### Key Methods
| Access | Return | Method |
|-|-|-|
| [pub] | int | getID() |
| [pub] | String | getUID() |
| [pub] | float | getX() / setX(float) / getY() / setY(float) / getZ() / setZ(float) |
| [pub] | void | setPosition(float x, float y, float z) |
| [pub] | Vector3 | getPosition(Vector3) |
| [pub] | IsoGridSquare | getSquare() / getMovingSquare() / findCurrentGridSquare() |
| [pub] | float | Hit(HandWeapon, IsoGameCharacter, float, boolean, float) |
| [pub] | void | Move(Vector2 dir) / MoveUnmodded(Vector2 dir) |
| [pub] | float | DistTo(IsoMovingObject) / DistToSquared(IsoMovingObject) |
| [pub] | IsoBuilding | getBuilding() / getCurrentBuilding() |
| [pub] | float | getWeight() / setWeight(float) |
| [pub] | Thumpable | getThumpTarget() / setThumpTarget(Thumpable) |
| [pub] | void | update() / preupdate() / postupdate() |
| [pub] | void | ensureOnTile() |
| [pub] | boolean | isCharacter() / isSolidForSeparate() / isPushableForSeparate() |
| [pub] | void | removeFromWorld() / removeFromSquare() |
| [pub] | float | getGlobalMovementMod(boolean bDoNoises) |

## 3. IsoThumpable (player-built structures)
Package: `zombie.iso.objects` | Extends: `IsoObject` | Implements: `BarricadeAble, Thumpable, IHasHealth, ILockableDoor`

### Fields
| Access | Type | Name | Default |
|-|-|-|-|
| [pub] | boolean | locked | false |
| [pub] | int | health | 500 |
| [pub] | int | pushedMaxStrength, pushedStrength | 0 |
| [prot] | IsoSprite | closedSprite | |
| [pub] | boolean | north | |
| [pub] | boolean | open | |
| [pub] | IsoSprite | openSprite | |
| [pub] | boolean | canPassThrough | |
| [pub] | int | keyId | -1 |
| [pub] | boolean | lockedByPadlock | |
| [pub] | int | lockedByCode | |
| [pub] | int | oldNumPlanks | |
| [pub] | String | thumpSound | SoundKey.ZOMBIE_THUMP_GENERIC |
| [pub][static] | Vector2 | tempo | new Vector2() |
| [priv] | int | maxHealth | 500 |
| [priv] | int | thumpDmg | 8 |
| [priv] | float | crossSpeed | 1.0f |
| [priv] | boolean | isDoor, isDoorFrame, isCorner, isFloor | |
| [priv] | boolean | blockAllTheSquare, canBarricade, isStairs | |
| [priv] | boolean | isContainer, dismantable, canBePlastered, paintable | |
| [priv] | boolean | isThumpable | true |
| [priv] | boolean | isHoppable | false |
| [priv] | int | lightSourceRadius | -1 |
| [priv] | int | lightSourceLife | -1 |
| [priv] | float | lifeLeft | -1.0f |
| [priv] | float | lifeDelta | |
| [priv] | boolean | haveFuel | |
| [priv] | String | lightSourceFuel | |

### Constructors
| Signature |
|-|
| IsoThumpable(IsoCell cell) |
| IsoThumpable(IsoCell cell, IsoGridSquare sq, String closedSprite, String openSprite, boolean north, KahluaTable table) |
| IsoThumpable(IsoCell cell, IsoGridSquare sq, String sprite, boolean north, KahluaTable table) |
| IsoThumpable(IsoCell cell, IsoGridSquare sq, String sprite, boolean north) |

### Key Methods
| Access | Return | Method |
|-|-|-|
| [pub] | int | getHealth() / getMaxHealth() / getThumpDmg() |
| [pub] | void | setHealth(int) / setMaxHealth(int) / setThumpDmg(Integer) |
| [pub] | boolean | isDoor() / isDoorFrame() / isCorner() / isFloor() / isStairs() |
| [pub] | void | setIsDoor(boolean) / setIsDoorFrame(boolean) / setCorner(boolean) |
| [pub] | void | setIsFloor(boolean) / setIsStairs(boolean) |
| [pub] | boolean | getCanBarricade() / setCanBarricade(boolean) |
| [pub] | void | setIsContainer(boolean) - creates ItemContainer("crate") |
| [pub] | boolean | isDismantable() / setIsDismantable(boolean) |
| [pub] | boolean | canBePlastered() / isPaintable() |
| [pub] | void | setCanBePlastered(boolean) / setPaintable(boolean) |
| [pub] | float | getCrossSpeed() / setCrossSpeed(float) |
| [pub] | boolean | isCanPassThrough() / setCanPassThrough(boolean) |
| [pub] | boolean | isBlockAllTheSquare() / setBlockAllTheSquare(boolean) |
| [pub] | boolean | isThumpable() / setIsThumpable(boolean) |
| [pub] | boolean | isHoppable() / isTallHoppable() / setHoppable(boolean) |
| [pub] | boolean | isWindowN() / isWindowW() |
| [pub] | boolean | getNorth() |
| [pub] | Vector2 | getFacingPosition(Vector2 pos) |
| [pub] | void | setClosedSprite(IsoSprite) / setOpenSprite(IsoSprite) |
| [pub] | boolean | isDestroyed() |
| [pub] | boolean | IsOpen() / IsStrengthenedByPushedItems() |
| [pub] | boolean | TestPathfindCollide(IsoMovingObject, IsoGridSquare, IsoGridSquare) |
| [pub] | boolean | TestCollide(IsoMovingObject, IsoGridSquare, IsoGridSquare) |
| [pub] | VisionResult | TestVision(IsoGridSquare, IsoGridSquare) |
| [pub] | void | Thump(IsoMovingObject thumper) |
| [pub] | void | WeaponHit(IsoGameCharacter, HandWeapon) |
| [pub] | Thumpable | getThumpableFor(IsoGameCharacter) |
| [pub] | void | ToggleDoor(IsoGameCharacter) / ToggleDoorActual(IsoGameCharacter) |
| [pub] | void | Damage(float amount) / destroy() |
| [pub] | IsoBarricade | getBarricadeOnSameSquare() / getBarricadeOnOppositeSquare() |
| [pub] | boolean | isBarricaded() / isBarricadeAllowed() |
| [pub] | IsoBarricade | getBarricadeForCharacter(IsoGameCharacter) |
| [pub] | boolean | isLocked() / setIsLocked(boolean) |
| [pub] | int | getKeyId() / setKeyId(int) |
| [pub] | boolean | isLockedByKey() / setLockedByKey(boolean) |
| [pub] | boolean | isLockedByPadlock() / setLockedByPadlock(boolean) |
| [pub] | boolean | canBeLockByPadlock() / setCanBeLockByPadlock(boolean) |
| [pub] | boolean | haveSheetRope() / canAddSheetRope() |
| [pub] | boolean | addSheetRope(IsoPlayer, String) / removeSheetRope(IsoPlayer) |
| [pub] | void | createLightSource(int radius, int offX, int offY, int offZ, int life, String fuel, InventoryItem, IsoGameCharacter) |
| [pub] | InventoryItem | insertNewFuel(InventoryItem, IsoGameCharacter) |
| [pub] | InventoryItem | removeCurrentFuel(IsoGameCharacter) |
| [pub] | int | getLightSourceRadius() / getLightSourceLife() |
| [pub] | boolean | isLightSourceOn() / toggleLightSource(boolean) |
| [pub] | float | getLifeLeft() / getLifeDelta() |
| [pub] | boolean | haveFuel() / setHaveFuel(boolean) |
| [pub] | boolean | canClimbOver(IsoGameCharacter) / canClimbThrough(IsoGameCharacter) |
| [pub] | IsoGridSquare | getOppositeSquare() / getInsideSquare() / getIndoorSquare() |
| [pub] | IsoCurtain | HasCurtains() |
| [pub] | boolean | canAddCurtain() |
| [pub] | String | getThumpSound() / setThumpSound(String) |
| [pub][static] | String | GetBreakFurnitureSound(IsoSprite) |

## 4. IsoBarricade
Package: `zombie.iso.objects` | Extends: `IsoObject` | Implements: `Thumpable, IHasHealth`

### Constants
| Name | Value | Notes |
|-|-|-|
| MAX_PLANKS | 4 | Max wood planks per barricade |
| PLANK_HEALTH | 1000 | HP per plank (scales with condition) |
| METAL_BAR_HEALTH | 3000 | HP for metal bar barricade |
| METAL_HEALTH | 5000 | HP for sheet metal barricade |
| METAL_HEALTH_DAMAGED | 2500 | Threshold for damaged metal sprite |

### Fields
| Access | Type | Name |
|-|-|-|
| [priv] | int[4] | plankHealth |
| [priv] | int | metalHealth |
| [priv] | int | metalBarHealth |

### Constructors
| Signature |
|-|
| IsoBarricade(IsoCell cell) |
| IsoBarricade(IsoGridSquare gridSquare, IsoDirections dir) |

### Key Methods
| Access | Return | Method |
|-|-|-|
| [pub] | void | addPlank(IsoGameCharacter chr) |
| [pub] | void | addPlank(IsoGameCharacter chr, InventoryItem plank) |
| [pub] | InventoryItem | removePlank(IsoGameCharacter chr) |
| [pub] | int | getNumPlanks() |
| [pub] | boolean | canAddPlank() - false if metal or metalBar or planks>=4 |
| [pub] | void | addMetalBar(IsoGameCharacter chr, InventoryItem metalBar) |
| [pub] | InventoryItem | removeMetalBar(IsoGameCharacter chr) |
| [pub] | void | addMetal(IsoGameCharacter chr, InventoryItem metal) |
| [pub] | InventoryItem | removeMetal(IsoGameCharacter chr) |
| [pub] | boolean | isMetal() - metalHealth > 0 |
| [pub] | boolean | isMetalBar() - metalBarHealth > 0 |
| [pub] | boolean | isBlockVision() - metal or planks > 2 |
| [pub] | boolean | isDestroyed() - all health types <= 0 |
| [pub] | VisionResult | TestVision(IsoGridSquare from, IsoGridSquare to) |
| [pub] | void | Thump(IsoMovingObject thumper) |
| [pub] | void | WeaponHit(IsoGameCharacter owner, HandWeapon weapon) |
| [pub] | void | Damage(float amount) |
| [pub] | int | getHealth() / getMaxHealth() / setHealth(int) |
| [pub] | float | getThumpCondition() |
| [pub] | Vector2 | getFacingPosition(Vector2 pos) |
| [pub] | boolean | canAttackBypassIsoBarricade(IsoGameCharacter, HandWeapon) |
| [pub] | void | addFromCraftRecipe(IsoGameCharacter chr, ArrayList\<InventoryItem\> items) |
| [pub] | float | getLightTransmission() |
| [pub][static] | IsoBarricade | GetBarricadeOnSquare(IsoGridSquare, IsoDirections) |
| [pub][static] | IsoBarricade | GetBarricadeForCharacter(BarricadeAble, IsoGameCharacter) |
| [pub][static] | IsoBarricade | GetBarricadeOppositeCharacter(BarricadeAble, IsoGameCharacter) |
| [pub][static] | IsoBarricade | AddBarricadeToObject(BarricadeAble to, boolean addOpposite) |
| [pub][static] | IsoBarricade | AddBarricadeToObject(BarricadeAble to, IsoGameCharacter chr) |
| [pub][static] | void | barricadeCurrentCellWithMetalPlate() |
| [pub][static] | void | barricadeCurrentCellWithMetalBars() |
| [pub][static] | void | barricadeCurrentCellWithPlanks(int numberOfPlanks) |

## 5. IsoDoor
Package: `zombie.iso.objects` | Extends: `IsoObject` | Implements: `BarricadeAble, Thumpable, IHasHealth, ILockableDoor, ICurtain`

### Fields
| Access | Type | Name | Default |
|-|-|-|-|
| [pub] | int | health | 500 |
| [pub] | boolean | lockedByKey | |
| [pub] | boolean | locked | |
| [pub] | int | maxHealth | 500 |
| [pub] | int | pushedMaxStrength, pushedStrength | 0 |
| [pub] | DoorType | type | DoorType.WeakWooden |
| [pub] | boolean | north | |
| [pub] | boolean | open | |
| [pub][static] | Vector2 | tempo | new Vector2() |
| [priv] | IsoSprite | closedSprite, openSprite | |
| [priv] | boolean | destroyed, haveKey | |
| [priv] | boolean | hasCurtain, curtainInside, curtainOpen | |

### Key Methods
| Access | Return | Method |
|-|-|-|
| [pub] | boolean | isDestroyed() / IsOpen() / IsStrengthenedByPushedItems() |
| [pub] | boolean | TestPathfindCollide(IsoMovingObject, IsoGridSquare, IsoGridSquare) |
| [pub] | boolean | TestCollide(IsoMovingObject, IsoGridSquare, IsoGridSquare) |
| [pub] | VisionResult | TestVision(IsoGridSquare, IsoGridSquare) |
| [pub] | void | Thump(IsoMovingObject) |
| [pub] | void | WeaponHit(IsoGameCharacter, HandWeapon) |
| [pub] | Thumpable | getThumpableFor(IsoGameCharacter) |
| [pub] | void | destroy() |
| [pub] | void | ToggleDoor(IsoGameCharacter) / ToggleDoorActual(IsoGameCharacter) / ToggleDoorSilent() |
| [pub] | IsoGridSquare | getOtherSideOfDoor(IsoGameCharacter) / getOppositeSquare() |
| [pub] | boolean | isExteriorDoor(IsoGameCharacter) / isExterior() |
| [pub] | boolean | isHoppable() / canClimbOver(IsoGameCharacter) |
| [pub] | boolean | couldBeOpen(IsoGameCharacter) |
| [pub] | IsoBarricade | getBarricadeOnSameSquare() / getBarricadeOnOppositeSquare() |
| [pub] | boolean | isBarricaded() / isBarricadeAllowed() |
| [pub] | IsoBarricade | getBarricadeForCharacter(IsoGameCharacter) |
| [pub] | boolean | isLocked() / setLocked(boolean) |
| [pub] | boolean | getNorth() |
| [pub] | int | getHealth() / getMaxHealth() / setHealth(int) |
| [pub] | boolean | isLockedByKey() / setLockedByKey(boolean) |
| [pub] | boolean | haveKey() / setHaveKey(boolean) |
| [pub] | int | getKeyId() / setKeyId(int) / checkKeyId() |
| [pub] | void | syncDoorKey() |
| [pub] | boolean | canAddCurtain() |
| [pub] | IsoDoor | HasCurtains() |
| [pub] | boolean | isCurtainOpen() / setCurtainOpen(boolean) / toggleCurtain() |
| [pub] | void | addSheet(IsoGameCharacter) / addSheet(boolean inside, IsoGameCharacter) |
| [pub] | void | removeSheet(IsoGameCharacter) |
| [pub] | void | addRandomBarricades() |
| [pub] | boolean | isObstructed() |
| [pub][static] | boolean | isDoorObstructed(IsoObject) |
| [pub][static] | void | toggleDoubleDoor(IsoObject, boolean doSync) |
| [pub][static] | int | getDoubleDoorIndex(IsoObject) |
| [pub][static] | IsoObject | getDoubleDoorObject(IsoObject, int index) |
| [pub][static] | boolean | isDoubleDoorObstructed(IsoObject) |
| [pub][static] | boolean | destroyDoubleDoor(IsoObject) |
| [pub][static] | int | getGarageDoorIndex(IsoObject) |

### IsoDoor.DoorType enum
`WeakWooden`, `StrongWooden`

## 6. IsoWindow
Package: `zombie.iso.objects` | Extends: `IsoObject` | Implements: `BarricadeAble, Thumpable`

### Constants
| Name | Value |
|-|-|
| SinglePaneWindowMaxHealth | 50 |
| DoublePaneWindowMaxHealth | 100 |
| WeaponDoorDamageModifier | 5.0f |
| NoWeaponDoorDamage | 100.0f |

### Fields
| Access | Type | Name | Default |
|-|-|-|-|
| [priv] | WindowType | type | WindowType.SinglePane |
| [priv] | int | health | 50 |
| [priv] | int | maxHealth | 50 |
| [priv] | boolean | north, locked, permaLocked | |
| [priv] | boolean | open, destroyed, glassRemoved | |
| [priv] | IsoSprite | openSprite, closedSprite, smashedSprite, glassRemovedSprite | |

### Key Methods
| Access | Return | Method |
|-|-|-|
| [pub] | IsoCurtain | HasCurtains() |
| [pub] | IsoGridSquare | getIndoorSquare() / getInsideSquare() / getOppositeSquare() |
| [pub] | boolean | isExterior() |
| [pub] | void | WeaponHit(IsoGameCharacter, HandWeapon) |
| [pub] | void | smashWindow() / smashWindow(boolean bRemote) / smashWindow(boolean, boolean doAlarm) |
| [pub] | void | addBrokenGlass(IsoMovingObject) / addBrokenGlass(boolean onOpposite) |
| [pub] | boolean | isDestroyed() / isSmashed() / isInvincible() |
| [pub] | boolean | isGlassRemoved() / setGlassRemoved(boolean) |
| [pub] | void | removeBrokenGlass() |
| [pub] | void | Thump(IsoMovingObject) |
| [pub] | void | Damage(float amount) |
| [pub] | void | ToggleWindow(IsoGameCharacter) |
| [pub] | void | openCloseCurtain(IsoGameCharacter) |
| [pub] | void | addSheet(IsoGameCharacter) / removeSheet(IsoGameCharacter) |
| [pub] | IsoBarricade | getBarricadeOnSameSquare() / getBarricadeOnOppositeSquare() |
| [pub] | boolean | isBarricaded() / isBarricadeAllowed() |
| [pub] | IsoBarricade | getBarricadeForCharacter(IsoGameCharacter) |
| [pub] | boolean | getNorth() / isLocked() / isPermaLocked() |
| [pub] | int | getHealth() / IsOpen() |
| [pub] | boolean | haveSheetRope() / canAddSheetRope() |
| [pub] | boolean | addSheetRope(IsoPlayer, String) / removeSheetRope(IsoPlayer) |
| [pub] | boolean | canClimbThrough(IsoGameCharacter) |
| [pub] | IsoGameCharacter | getFirstCharacterClimbingThrough() |
| [pub] | void | addRandomBarricades() |
| [pub] | boolean | canAttackBypassIsoBarricade(IsoGameCharacter, HandWeapon) |
| [pub][static] | boolean | isTopOfSheetRopeHere(IsoGridSquare) |
| [pub][static] | boolean | isSheetRopeHere(IsoGridSquare) |
| [pub][static] | boolean | canClimbHere(IsoGridSquare) |
| [pub][static] | int | countAddSheetRope(IsoGridSquare, boolean north) |

### IsoWindow.WindowType enum
`SinglePane`, `DoublePane`

### IsoWindow.LockedHouseFrequency enum
`Never(0,0)`, `ExtremelyRare(1,5)`, `Rare(2,10)`, `Sometimes(3,50)`, `Often(4,60)`, `VeryOften(5,70)`
Fields: `value` (int), `lockChance` (int)

## 7. IsoWorldInventoryObject
Package: `zombie.iso.objects` | Extends: `IsoObject` | Implements: `IItemProvider`

### Fields
| Access | Type | Name | Default |
|-|-|-|-|
| [pub] | InventoryItem | item | |
| [pub] | float | xoff, yoff, zoff | |
| [pub] | boolean | removeProcess | |
| [pub] | double | dropTime | -1.0 |
| [pub] | boolean | ignoreRemoveSandbox | |
| [priv] | boolean | extendedPlacement | |

### Key Methods
| Access | Return | Method |
|-|-|-|
| [pub] | void | swapItem(InventoryItem newItem) |
| [pub] | InventoryItem | getItem() |
| [pub] | void | updateSprite() |
| [pub] | boolean | hasWater() / isPureWater(boolean) |
| [pub] | float | getFluidAmount() / getFluidCapacity() |
| [pub] | void | emptyFluid() / addFluid(FluidType, float) |
| [pub] | float | useFluid(float) |
| [pub] | void | addToWorld() / removeFromWorld() / removeFromSquare() |
| [pub] | float | getScreenPosX(int) / getScreenPosY(int) |
| [pub] | float | getWorldPosX() / getWorldPosY() / getWorldPosZ() |
| [pub] | void | setOffset(float x, float y, float z) |
| [pub] | void | setExtendedPlacement(boolean) |
| [pub] | String | getCustomMenuOption() |
| [pub][static] | float | getSurfaceAlpha(IsoGridSquare, float zoff) |

## 8. IsoDeadBody
Package: `zombie.iso.objects` | Extends: `IsoMovingObject` | Implements: `Talker, IAnimalVisual, IHumanVisual, IIdentifiable, IGrappleableWrapper, IItemProvider, IPositional`

### Constants
| Name | Value |
|-|-|
| MAX_ROT_STAGES | 3 |
| MAX_ROT_STAGES_ANIMALS | 4 |

### Fields (selected)
| Access | Type | Name |
|-|-|-|
| [pub] | float | weight |
| [pub] | String | corpseItem, customName, invIcon, animalAnimSet |
| [pub] | boolean | speaking, ragdollFall |
| [pub] | String | sayLine, rottenTexture, skelInvIcon |
| [priv] | boolean | female, wasZombie, fakeDead, crawling |
| [priv] | SurvivorDesc | desc |
| [priv] | BaseVisual | baseVisual |
| [priv] | String | animalType |
| [priv] | float | deathTime, reanimateTime | -1.0f |
| [priv] | WornItems | wornItems |
| [priv] | AttachedItems | attachedItems |
| [priv] | InventoryItem | primaryHandItem, secondaryHandItem |
| [priv] | float | angle, animalSize |

### Key Methods
| Access | Return | Method |
|-|-|-|
| [pub] | BaseVisual | getVisual() |
| [pub] | HumanVisual | getHumanVisual() |
| [pub] | AnimalVisual | getAnimalVisual() |
| [pub] | boolean | isFemale() / isZombie() / isCrawling() / isFakeDead() / isSkeleton() |
| [pub] | void | setCrawling(boolean) / setFakeDead(boolean) |
| [pub] | WornItems | getWornItems() / setWornItems(WornItems) |
| [pub] | AttachedItems | getAttachedItems() / setAttachedItems(AttachedItems) |
| [pub] | boolean | isEquipped(InventoryItem) / isEquippedClothing(InventoryItem) |
| [pub] | float | getInventoryWeight() |
| [pub] | InventoryItem | getItem() |
| [pub] | float | getDeathTime() / setDeathTime(float) |
| [pub] | float | getReanimateTime() / setReanimateTime(float) |
| [pub] | void | reanimateLater() / reanimateNow() |
| [pub] | IsoGameCharacter | reanimate() |
| [pub] | void | Burn() |
| [pub] | void | changeRotStage(int newStage) |
| [pub] | InventoryItem | getPrimaryHandItem() / getSecondaryHandItem() |
| [pub] | void | setPrimaryHandItem(InventoryItem) / setSecondaryHandItem(InventoryItem) |
| [pub] | float | getAngle() / getAnimalSize() |
| [pub] | String | getAnimalType() / getOutfitName() / getDescription() |
| [pub] | boolean | isFallOnFront() / isKilledByFall() |
| [pub] | void | Say(String line) / IsSpeaking() |
| [pub][static] | void | updateBodies() / Reset() |

## 9. Interfaces

### BarricadeAble
Package: `zombie.iso.objects.interfaces`

| Return | Method |
|-|-|
| boolean | isBarricaded() |
| boolean | isBarricadeAllowed() |
| IsoBarricade | getBarricadeOnSameSquare() |
| IsoBarricade | getBarricadeOnOppositeSquare() |
| IsoBarricade | getBarricadeForCharacter(IsoGameCharacter) |
| IsoBarricade | getBarricadeOppositeCharacter(IsoGameCharacter) |
| IsoGridSquare | getSquare() |
| IsoGridSquare | getOppositeSquare() |
| boolean | getNorth() |
| [default] IsoBarricade | addBarricadesFromCraftRecipe(IsoGameCharacter, ArrayList\<InventoryItem\>, CraftRecipeData, boolean opposite) |

Implemented by: `IsoThumpable`, `IsoDoor`, `IsoWindow`

### Thumpable
Package: `zombie.iso.objects.interfaces`

| Return | Method |
|-|-|
| boolean | isDestroyed() |
| void | Thump(IsoMovingObject) |
| void | WeaponHit(IsoGameCharacter, HandWeapon) |
| Thumpable | getThumpableFor(IsoGameCharacter) |
| float | getThumpCondition() |

Implemented by: `IsoObject` (base), `IsoThumpable`, `IsoDoor`, `IsoWindow`, `IsoBarricade`

### IHasHealth
Package: `zombie.iso`

| Return | Method |
|-|-|
| int | getHealth() |
| int | getMaxHealth() |
| void | setHealth(int) |

### ILockableDoor
Package: `zombie.iso`

| Return | Method |
|-|-|
| boolean | isLockedByKey() |
| boolean | IsOpen() |
| int | getKeyId() |
| void | setKeyId(int) |
| void | setLockedByKey(boolean) |
| ICurtain | HasCurtains() |
| boolean | canAddCurtain() |
| boolean | canClimbOver(IsoGameCharacter) |
| boolean | couldBeOpen(IsoGameCharacter) |

### ICurtain
Package: `zombie.iso`

| Return | Method |
|-|-|
| boolean | isCurtainOpen() |

## 10. Enums

### IsoObjectType
Package: `zombie.iso.SpriteDetails`

| Name | Index | Notes |
|-|-|-|
| normal | 0 | Default object |
| jukebox | 1 | |
| wall | 2 | |
| stairsTW | 3 | Stairs top west |
| stairsTN | 4 | Stairs top north |
| stairsMW | 5 | Stairs mid west |
| stairsMN | 6 | Stairs mid north |
| stairsBW | 7 | Stairs bottom west |
| stairsBN | 8 | Stairs bottom north |
| doorW | 11 | Door facing west |
| doorN | 12 | Door facing north |
| lightswitch | 13 | |
| radio | 14 | |
| curtainN | 15 | Curtain north side |
| curtainS | 16 | Curtain south side |
| curtainW | 17 | Curtain west side |
| curtainE | 18 | Curtain east side |
| doorFrW | 19 | Door frame west |
| doorFrN | 20 | Door frame north |
| tree | 21 | |
| windowFN | 22 | Window frame north |
| windowFW | 23 | Window frame west |
| WestRoofB | 25 | West roof bottom |
| WestRoofM | 26 | West roof middle |
| WestRoofT | 27 | West roof top |
| isMoveAbleObject | 28 | Moveable furniture |
| MAX | 29 | Sentinel |

### IsoFlagType
Package: `zombie.iso.SpriteDetails` - Tile property flags (113 values)

**Collision/structure:** collideW(0), collideN(1), solidfloor(2), solid(32), solidtrans(35), halfheight(29)

**Walls:** WallW(92), WallN(93), WallNW(94), WallSE(77), WallWTrans(86), WallNTrans(88), DoorWallW(90), DoorWallN(91)

**Windows/doors:** windowW(4), windowN(5), WindowN(78), WindowW(79), doorW(9), doorN(10), DoubleDoor1(106), DoubleDoor2(107)

**Transparency:** transparentW(11), transparentN(12), transparentFloor(43), trans(33), invisible(36)

**Navigation:** noStart(3), HoppableN(51), HoppableW(52), TallHoppableW(85), TallHoppableN(87), CantClimb(82), canPathW(55), canPathN(56)

**Tables/surfaces:** tableN(21), tableNW(22), tableW(23), tableSW(24), tableS(25), tableSE(26), tableE(27), tableNE(28), ontable(42), shelfS(39), shelfE(40)

**Sheet ropes:** climbSheetW(44), climbSheetN(45), climbSheetE(58), climbSheetS(59), climbSheetTopN(46), climbSheetTopW(47), climbSheetTopE(60), climbSheetTopS(61), sheetCurtains(49)

**Rendering:** hidewalls(6), exterior(7), NoWallLighting(8), WallOverlay(13), FloorOverlay(14), alwaysDraw(41), blocksight(57), cutW(19), cutN(20), NeverCutaway(105), forceRender(96)

**Attachments:** attachedN(68), attachedS(69), attachedE(70), attachedW(71), attachedFloor(72), attachedSurface(73), attachedCeiling(74), attachedNW(75), attachedSE(84), IsFloorAttached(108), FloorAttachmentN-W(109-112)

**Water:** waterPiped(50), water(63), taintedWater(66)

**Other:** vegitation(15), burning(16), burntOut(17), unflamable(18), bed(53), blueprint(54), pushable(34), container(89), canBeCut(64), canBeRemoved(65), smoke(67), ForceAmbient(76), makeWindowInvincible(62), open(97), SpriteConfig(98), BlockRain(99), EntityScript(100), isEave(101), openAir(102), HasLightOnSprite(103), unlit(104), SpearOnlyAttackThrough(95)

**Floor height:** FloorHeightOneThird(80), FloorHeightTwoThirds(81), floorS(37), floorE(38), diamondFloor(83)

### MaterialType
Package: `zombie.iso.enums`

`Default`, `Flesh`, `Flesh_Hollow`, `Concrete`, `Plaster`, `Stone`, `Wood`, `Wood_Solid`, `Brick`, `Metal`, `Metal_Large`, `Metal_Light`, `Metal_Solid`, `Glass`, `Glass_Light`, `Glass_Solid`, `Cinderblock`, `Plastic`, `Ceramic`, `Rubber`, `Fabric`, `Carpet`, `Dirt`, `Grass`, `Gravel`, `Sand`, `Snow`
