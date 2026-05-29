# Vehicle Core Classes - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | BaseVehicle Fields | 27-136 |
| 2 | BaseVehicle Constants | 137-153 |
| 3 | BaseVehicle Methods - Core | 154-196 |
| 4 | BaseVehicle Methods - Engine | 197-237 |
| 5 | BaseVehicle Methods - Passengers | 238-273 |
| 6 | BaseVehicle Methods - Physics/Collision | 274-326 |
| 7 | BaseVehicle Methods - Key/Hotwire/Alarm | 327-371 |
| 8 | BaseVehicle Methods - Damage | 372-395 |
| 9 | BaseVehicle Methods - Towing/Trailer | 396-419 |
| 10 | BaseVehicle Enums | 420-441 |
| 11 | VehiclePart | 442-531 |
| 12 | VehicleDoor | 532-555 |
| 13 | VehicleWindow | 556-578 |
| 14 | VehicleLight | 579-594 |
| 15 | VehicleEngineRPM / EngineRPMData | 595-612 |
| 16 | TransmissionNumber | 613-631 |
| 17 | VehicleType (Spawn System) | 632-677 |

---

## 1. BaseVehicle Fields

`zombie.vehicles.BaseVehicle extends IsoMovingObject implements Thumpable, IFMODParameterUpdater, IPositional`

### Identity & State
| Field | Type | Access | Default | Notes |
|-|-|-|-|-|
| vehicleId | short | [pub] | -1 | Unique ID assigned by VehicleIDMap |
| sqlId | int | [pub] | -1 | Database persistence ID |
| scriptName | String | [priv] | "Base.PickUpTruck" | Script reference name |
| script | VehicleScript | [prot] | null | Resolved script definition |
| type | String | [priv] | "" | Vehicle type zone name |
| skinIndex | int | [priv] | -1 | Current paint skin |
| created | boolean | [priv] | false | True after first createPhysics() |

### Parts & Components
| Field | Type | Access | Notes |
|-|-|-|-|
| parts | ArrayList\<VehiclePart\> | [prot] | All installed parts |
| battery | VehiclePart | [priv] | Cached battery reference |
| lights | ArrayList\<VehiclePart\> | [priv] | Parts with light components |
| passengers | Passenger[] | [priv] | Passenger slots (initially size 1) |

### Engine & Drivetrain
| Field | Type | Access | Default | Notes |
|-|-|-|-|-|
| engineQuality | int | [prot] | 0 | 0-100, affects start chance |
| engineLoudness | int | [prot] | 0 | Zombie attraction multiplier |
| enginePower | int | [prot] | 0 | Engine force in Newtons |
| engineSpeed | double | [pub] | 0.0 | Current engine RPM |
| engineState | engineStateTypes | [pub] | Idle | Current engine FSM state |
| throttle | float | [pub] | 0 | Current throttle input |
| transmissionNumber | TransmissionNumber | [pub] | N | Current gear |
| vehicleEngineRpm | VehicleEngineRPM | [priv] | - | RPM curve data |

### Physics & Movement
| Field | Type | Access | Default | Notes |
|-|-|-|-|-|
| physics | CarController | [prot] | null | Bullet physics controller |
| mass | float | [priv] | 0 | Current total mass |
| initialMass | float | [priv] | 0 | Mass without cargo |
| maxSpeed | float | [priv] | 0 | Max forward speed (km/h) |
| brakingForce | float | [priv] | 0 | Brake strength |
| currentSteering | float | [priv] | 0 | Current wheel angle |
| jniSpeed | float | [priv] | 0 | Speed from native physics |
| jniIsCollide | boolean | [pub] | false | Currently colliding |
| jniLinearVelocity | Vector3f | [pub] | (0,0,0) | Physics velocity |
| jniTransform | Transform | [pub] | - | Physics world transform |
| wheelInfo | WheelInfo[4] | [pub] | - | Per-wheel state |
| skidding | boolean | [pub] | false | Tires skidding |
| handBrakeActive | boolean | [priv] | false | Parking brake |

### Durability & Damage
| Field | Type | Access | Default | Notes |
|-|-|-|-|-|
| frontEndDurability | int | [pub] | 100 | Max front health |
| rearEndDurability | int | [pub] | 100 | Max rear health |
| currentFrontEndDurability | int | [pub] | 100 | Current front health |
| currentRearEndDurability | int | [pub] | 100 | Current rear health |
| rust | float | [pub] | Rand(0,2) | Rust level |
| baseQuality | float | [priv] | 0 | Spawn quality factor |

### Appearance
| Field | Type | Access | Notes |
|-|-|-|-|
| colorHue | float | [pub] | HSV hue (0-1) |
| colorSaturation | float | [pub] | HSV saturation |
| colorValue | float | [pub] | HSV brightness |
| bloodIntensity | HashMap\<String,Byte\> | [priv] | Per-area blood splatter |

### Key/Alarm/Hotwire
| Field | Type | Access | Notes |
|-|-|-|-|
| keyIsOnDoor | boolean | [priv] | Key visually in door |
| hotwired | boolean | [priv] | Successfully hotwired |
| hotwiredBroken | boolean | [priv] | Failed hotwire attempt |
| keysInIgnition | boolean | [priv] | Key in ignition slot |
| ignitionSwitch | ItemContainer | [pub] | Holds the key item |
| currentKey | InventoryItem | [priv] | Active key reference |
| alarmed | boolean | [priv] | Has alarm system |
| soundAlarmOn | boolean | [pub] | Alarm currently sounding |
| soundHornOn | boolean | [pub] | Horn active |
| keySpawned | byte | [pub] | Key spawn tracking |

### Lights & Sounds
| Field | Type | Access | Notes |
|-|-|-|-|
| headlightsOn | boolean | [pub] | Headlights state |
| stoplightsOn | boolean | [pub] | Brake lights state |
| windowLightsOn | boolean | [pub] | Interior lights |
| lightbarLightsMode | LightbarLightsMode | [pub] | Emergency lights pattern |
| lightbarSirenMode | LightbarSirenMode | [pub] | Siren mode |

### Towing
| Field | Type | Access | Notes |
|-|-|-|-|
| vehicleTowing | BaseVehicle | [priv] | Vehicle being towed |
| vehicleTowedBy | BaseVehicle | [priv] | Vehicle towing this one |
| constraintTowing | int | [pub] | Physics constraint ID |
| towAttachmentSelf | String | [priv] | Attachment point name |
| towAttachmentOther | String | [priv] | Other vehicle's attachment |

### Network
| Field | Type | Access | Notes |
|-|-|-|-|
| netPlayerAuthorization | Authorization | [pub] | Who simulates physics |
| netPlayerId | short | [pub] | Controlling player ID |
| isActive | boolean | [pub] | Physics active |
| isStatic | boolean | [pub] | Stationary optimization |

## 2. BaseVehicle Constants

| Constant | Type | Value | Notes |
|-|-|-|-|
| MAX_WHEELS | int | 4 | Max wheel count |
| PHYSICS_PARAM_COUNT | int | 27 | Bullet physics param slots |
| PHYSICS_Z_SCALE | float | 0.8164967 | Z-axis physics scaling |
| RADIUS | float | 0.3 | Base collision radius |
| PLUS_RADIUS | float | 0.15 | Extended collision radius |
| FADE_DISTANCE | int | 15 | Render fade distance (tiles) |
| RANDOMIZE_CONTAINER_CHANCE | int | 100 | Loot spawn chance |

### Damage Mask Constants (Bitfield Positions)
MASK1 (bodywork): FRONT=0, REAR=4, DOOR_RIGHT_FRONT=8, DOOR_RIGHT_REAR=12, DOOR_LEFT_FRONT=1, DOOR_LEFT_REAR=5, WINDOW_RIGHT_FRONT=9, WINDOW_RIGHT_REAR=13, WINDOW_LEFT_FRONT=2, WINDOW_LEFT_REAR=6, WINDOW_FRONT=10, WINDOW_REAR=14, GUARD_RIGHT_FRONT=3, GUARD_RIGHT_REAR=7, GUARD_LEFT_FRONT=11, GUARD_LEFT_REAR=15

MASK2 (accessories): ROOF=0, LIGHT_RIGHT_FRONT=4, LIGHT_LEFT_FRONT=8, LIGHT_RIGHT_REAR=12, LIGHT_LEFT_REAR=1, BRAKE_RIGHT=5, BRAKE_LEFT=9, LIGHTBAR_RIGHT=13, LIGHTBAR_LEFT=2, HOOD=6, BOOT=10

## 3. BaseVehicle Methods - Core

| Method | Return | Access | Notes |
|-|-|-|-|
| BaseVehicle(IsoCell) | - | [pub] | Constructor, sets defaults |
| createPhysics() | void | [pub] | Init Bullet physics, assign ID |
| createPhysics(boolean spawnSwap) | void | [pub] | With spawn-swap flag |
| setScript(String name) | void | [pub] | Load VehicleScript by name |
| getScript() | VehicleScript | [pub] | Current script def |
| getScriptName() | String | [pub] | "Module.VehicleName" |
| scriptReloaded() | void | [pub] | Refresh after script change |
| scriptReloaded(boolean spawnSwap) | void | [pub] | With swap flag |
| addToWorld() | void | [pub] | Register in game world |
| addToWorld(boolean crashed) | void | [pub] | With crash damage |
| removeFromWorld() | void | [pub] | Unregister from world |
| permanentlyRemove() | void | [pub] | Full cleanup + DB delete |
| update() | void | [pub] | Main tick, ~3Hz |
| postupdate() | void | [pub] | Post-physics tick |
| save(ByteBuffer, boolean) | void | [pub] | Serialize to save |
| load(ByteBuffer, int, boolean) | void | [pub] | Deserialize from save |
| softReset() | void | [pub] | Reset without full recreate |
| repair() | void | [pub] | Debug/cheat full repair |
| getObjectName() | String | [pub] | Returns "Vehicle" |
| getSkinCount() | int | [pub] | Available paint skins |
| getSkinIndex() | int | [pub] | Current skin |
| setSkinIndex(int) | void | [pub] | Change paint skin |
| getSkin() | String | [pub] | Current skin texture name |
| getPartCount() | int | [pub] | Number of parts |
| getPartByIndex(int) | VehiclePart | [pub] | Part by array index |
| getPartById(String) | VehiclePart | [pub] | Part by ID string |
| getPartIndex(String) | int | [pub] | Index of named part |
| getBattery() | VehiclePart | [pub] | Battery part ref |
| getBatteryCharge() | float | [pub] | 0-1 battery level |
| getNumberOfPartsWithContainers() | int | [pub] | Storable part count |
| getTrunkPart() | VehiclePart | [pub] | Main trunk/cargo part |
| getTrunkDoorPart() | VehiclePart | [pub] | Trunk door part |
| getTrailerTrunkPart() | VehiclePart | [pub] | Trailer cargo part |
| getPartForSeatContainer(int) | VehiclePart | [pub] | Storage for seat |
| getLightCount() | int | [pub] | Number of light parts |
| getLightByIndex(int) | VehiclePart | [pub] | Light part by index |
| getVehicleType() | String | [pub] | Zone spawn type |
| setVehicleType(String) | void | [pub] | Set zone type |

## 4. BaseVehicle Methods - Engine

| Method | Return | Access | Notes |
|-|-|-|-|
| getEngineSpeed() | double | [pub] | Current RPM |
| getEnginePower() | int | [pub] | Engine force |
| getEngineQuality() | int | [pub] | Quality 0-100 |
| getEngineLoudness() | int | [pub] | Loudness factor |
| setEngineFeature(int q, int l, int f) | void | [pub] | Set quality/loudness/force |
| tryStartEngine(boolean haveKey) | void | [pub] | Attempt ignition |
| tryStartEngine() | void | [pub] | Start with key check |
| engineDoIdle() | void | [pub] | Set state: Idle |
| engineDoStarting() | void | [pub] | Set state: Starting |
| engineDoRetryingStarting() | void | [pub] | Set state: RetryingStarting |
| engineDoStartingSuccess() | void | [pub] | Transition to Running |
| engineDoStartingFailed() | void | [pub] | Failed start |
| engineDoStartingFailed(String sound) | void | [pub] | Failed with custom sound |
| engineDoStartingFailedNoPower() | void | [pub] | No battery power |
| engineDoRunning() | void | [pub] | Set state: Running |
| engineDoStalling() | void | [pub] | Set state: Stalling |
| engineDoShuttingDown() | void | [pub] | Begin shutdown |
| engineDoShuttingDown(String sound) | void | [pub] | Shutdown with sound |
| shutOff() | void | [pub] | Immediate engine off |
| shutOff(String sound) | void | [pub] | Off with sound |
| resumeRunningAfterLoad() | void | [pub] | Restore running state |
| isEngineStarted() | boolean | [pub] | Started (any running state) |
| isEngineRunning() | boolean | [pub] | Actively running |
| isEngineWorking() | boolean | [pub] | Functional engine installed |
| isOperational() | boolean | [pub] | Can potentially drive |
| isDriveable() | boolean | [pub] | Ready to drive now |
| isStarting() | boolean | [pub] | In starting sequence |
| getTransmissionNumber() | int | [pub] | Current gear index |
| getTransmissionNumberLetter() | String | [pub] | "R","N","1"-"8" |
| changeTransmission(TransmissionNumber) | void | [pub] | Shift gear |
| getForce() | float | [pub] | engineForce - brakingForce |
| getClientForce() | float | [pub] | Client-side force |
| setClientForce(float) | void | [pub] | Set client force |
| getVehicleEngineRPM() | VehicleEngineRPM | [pub] | RPM curve object |
| updateParts() | void | [pub] | Tick all part Lua updates |
| drainBatteryUpdateHack() | void | [pub] | Drain battery over time |

## 5. BaseVehicle Methods - Passengers

| Method | Return | Access | Notes |
|-|-|-|-|
| getMaxPassengers() | int | [pub] | Seat count from script |
| setPassenger(int, IsoGameCharacter, Vector3f) | boolean | [pub] | Put char in seat |
| clearPassenger(int) | boolean | [pub] | Remove char from seat |
| hasPassenger() | boolean | [pub] | Any seat occupied |
| getPassenger(int) | Passenger | [pub] | Passenger data |
| getCharacter(int) | IsoGameCharacter | [pub] | Character in seat |
| getSeat(IsoGameCharacter) | int | [pub] | Seat of character |
| isDriver(IsoGameCharacter) | boolean | [pub] | In seat 0 |
| getDriver() | IsoGameCharacter | [pub] | Seat 0 character |
| getDriverRegardlessOfTow() | IsoGameCharacter | [pub] | Driver of tow chain |
| isSeatOccupied(int) | boolean | [pub] | Seat has character |
| isSeatInstalled(int) | boolean | [pub] | Seat part exists |
| isSeatHoldingItems(int) | boolean | [pub] | Seat has inventory |
| getAllSeatParts() | ArrayList\<VehiclePart\> | [pub] | All seat parts |
| enter(int, IsoGameCharacter) | boolean | [pub] | Enter vehicle |
| enter(int, IsoGameCharacter, Vector3f) | boolean | [pub] | Enter with offset |
| exit(IsoGameCharacter) | boolean | [pub] | Exit vehicle |
| getBestSeat(IsoGameCharacter) | int | [pub] | Nearest available seat |
| getEnterSeatDistance(int, float, float) | float | [pub] | Distance to enter point |
| isEnterBlocked(IsoGameCharacter, int) | boolean | [pub] | Entry obstructed |
| isExitBlocked(int) | boolean | [pub] | Exit obstructed |
| isExitBlocked(IsoGameCharacter, int) | boolean | [pub] | With character check |
| hasRoof(int) | boolean | [pub] | Seat has roof |
| showPassenger(int) | boolean | [pub] | Render passenger |
| canSwitchSeat(int, int) | boolean | [pub] | Can move between seats |
| switchSeat(IsoGameCharacter, int) | void | [pub] | Move to another seat |
| getPassengerDoor(int) | VehiclePart | [pub] | Door for seat |
| getPassengerDoor2(int) | VehiclePart | [pub] | Alternate door for seat |
| getPassengerArea(int) | String | [pub] | Area ID for seat |
| getPassengerWorldPos(int, Vector3f) | Vector3f | [pub] | World position of seat |
| playPassengerAnim(int, String) | void | [pub] | Play seat animation |

## 6. BaseVehicle Methods - Physics/Collision

| Method | Return | Access | Notes |
|-|-|-|-|
| getController() | CarController | [pub] | Bullet CarController |
| getCurrentSpeedKmHour() | float | [pub] | Signed speed (neg=reverse) |
| getCurrentAbsoluteSpeedKmHour() | float | [pub] | Absolute speed |
| getSpeed2D() | float | [pub] | 2D speed magnitude |
| getMaxSpeed() | float | [pub] | Max forward km/h |
| setMaxSpeed(float) | void | [pub] | Override max speed |
| isStopped() | boolean | [pub] | Speed near zero |
| isAtRest() | boolean | [pub] | Fully stopped + no input |
| setSpeedKmHour(float) | void | [pub] | Force speed |
| getLinearVelocity(Vector3f) | Vector3f | [pub] | Physics velocity |
| getForwardVector(Vector3f) | Vector3f | [pub] | Facing direction |
| getUpVector(Vector3f) | Vector3f | [pub] | Up direction |
| getUpVectorDot() | float | [pub] | Dot with world up (flip detect) |
| getMass() | float | [pub] | Total mass |
| setMass(float) | void | [pub] | Set mass |
| getInitialMass() | float | [pub] | Base mass |
| updateTotalMass() | void | [pub] | Recalc from parts+cargo |
| getFudgedMass() | float | [pub] | Mass for damage calc |
| getBrakingForce() | float | [pub] | Brake force |
| setBrakingForce(float) | void | [pub] | Set brake force |
| isBraking() | boolean | [pub] | Brakes active |
| getCurrentSteering() | float | [pub] | Steering angle |
| addImpulse(Vector3f, Vector3f) | void | [pub] | Apply force at point |
| flipUpright() | void | [pub] | Reset to upright |
| setAngles(float, float, float) | void | [pub] | Set rotation degrees |
| getAngleX/Y/Z() | float | [pub] | Get rotation per axis |
| setPhysicsActive(boolean) | void | [pub] | Enable/disable simulation |
| isPhysicsActive() | boolean | [pub] | Simulation active |
| isDoingOffroad() | boolean | [pub] | On natural terrain |
| getOffroadEfficiency() | float | [pub] | Offroad speed multiplier |
| shouldCollideWithCharacters() | boolean | [pub] | Hit detection active |
| shouldCollideWithObjects() | boolean | [pub] | Object collision active |
| testCollisionWithCharacter(IsoGameCharacter, float, Vector2) | Vector2 | [pub] | Character hit test |
| testCollisionWithVehicle(BaseVehicle) | boolean | [pub] | Vehicle-vehicle test |
| testCollisionWithObject(IsoObject, float, Vector2) | Vector2 | [pub] | Object hit test |
| testCollisionWithProneCharacter(IsoGameCharacter, boolean, Vector2) | int | [pub] | Ground char hit |
| hitCharacter(IsoGameCharacter, Vector2, boolean) | float | [pub] | Apply char damage |
| hitCharacter(IsoAnimal) | void | [pub] | Hit animal |
| calculateDamageWithCharacter(IsoGameCharacter) | int | [pub] | Damage amount calc |
| applyImpulseFromHitObject(IsoObject, float) | void | [pub] | Object hit recoil |
| applyImpulseFromHitPedestrian(IsoGameCharacter) | void | [pub] | Pedestrian hit recoil |
| applyImpulseFromHitPlant(IsoObject, float) | void | [pub] | Plant hit recoil |
| isIntersectingSquare(int, int, int) | boolean | [pub] | Overlaps tile |
| circleIntersects(float, float, float, float) | boolean | [pub] | Circle overlap test |
| isCharacterAdjacentTo(IsoGameCharacter) | boolean | [pub] | Near vehicle check |
| getWorldTransform(Transform) | Transform | [pub] | Full physics transform |
| getPoly() | VehiclePoly | [pub] | Collision polygon |
| getPolyPlusRadius() | VehiclePoly | [pub] | Extended collision polygon |

## 7. BaseVehicle Methods - Key/Hotwire/Alarm

| Method | Return | Access | Notes |
|-|-|-|-|
| isKeyIsOnDoor() | boolean | [pub] | Key visible in door |
| setKeyIsOnDoor(boolean) | void | [pub] | - |
| isHotwired() | boolean | [pub] | Successfully hotwired |
| setHotwired(boolean) | void | [pub] | - |
| isHotwiredBroken() | boolean | [pub] | Failed hotwire |
| setHotwiredBroken(boolean) | void | [pub] | - |
| isKeysInIgnition() | boolean | [pub] | Key inserted |
| setKeysInIgnition(boolean) | void | [pub] | - |
| tryHotwire(int electricityLevel) | void | [pub] | Attempt hotwire, skill check |
| cheatHotwire(boolean, boolean) | void | [pub] | Debug hotwire |
| putKeyInIgnition(InventoryItem, int) | void | [pub] | Insert key |
| removeKeyFromIgnition() | void | [pub] | Remove key |
| putKeyOnDoor(InventoryItem) | void | [pub] | Place key in door |
| removeKeyFromDoor() | void | [pub] | Take key from door |
| createVehicleKey() | InventoryItem | [pub] | Create matching key |
| addKeyToWorld() | void | [pub] | Spawn key in world |
| addKeyToWorld(boolean crashed) | void | [pub] | Spawn with crash bias |
| addKeyToGloveBox() | void | [pub] | Put key in glovebox |
| trySpawnKey() | void | [pub] | Roll key spawn chance |
| getKeySpawned() | boolean | [pub] | Key already spawned |
| getCurrentKey() | InventoryItem | [pub] | Active key item |
| setCurrentKey(InventoryItem) | void | [pub] | - |
| canLockDoor(VehiclePart, IsoGameCharacter) | boolean | [pub] | Can lock this door |
| canUnlockDoor(VehiclePart, IsoGameCharacter) | boolean | [pub] | Can unlock |
| canOpenDoor(VehiclePart, IsoGameCharacter) | boolean | [pub] | Can open |
| toggleLockedDoor(VehiclePart, IsoGameCharacter, boolean) | void | [pub] | Lock/unlock |
| haveOneDoorUnlocked() | boolean | [pub] | Any door unlocked |
| areAllDoorsLocked() | boolean | [pub] | Every door locked |
| isAnyDoorLocked() | boolean | [pub] | At least one locked |
| isTrunkLocked() | boolean | [pub] | Trunk locked |
| setTrunkLocked(boolean) | void | [pub] | - |
| hasAlarm() | boolean | [pub] | Alarm system installed |
| isAlarmed() | boolean | [pub] | Alarm armed |
| setAlarmed(boolean) | void | [pub] | Arm/disarm |
| triggerAlarm() | void | [pub] | Activate alarm |
| onAlarmStart() | void | [pub] | Begin alarm sound |
| onAlarmStop() | void | [pub] | End alarm sound |
| hasHorn() | boolean | [pub] | Horn available |
| onHornStart() | void | [pub] | Begin horn |
| onHornStop() | void | [pub] | End horn |

## 8. BaseVehicle Methods - Damage

| Method | Return | Access | Notes |
|-|-|-|-|
| Damage(float amount) | void | [pub] | Generic damage |
| HitByVehicle(BaseVehicle, float) | void | [pub] | Vehicle-to-vehicle |
| crash(float delta, boolean front) | void | [pub] | Crash event, damages front/rear end + parts |
| addDamageFrontHitAChr(int) | void | [pub] | Front end damage from hitting character |
| addDamageRearHitAChr(int) | void | [pub] | Rear end damage from hitting character |
| damageFromHitChr(int front, int back) | void | [pub] | Combined chr hit damage |
| damageObjects(float) | void | [pub] | Damage from hitting objects |
| breakingObjects() | void | [pub] | Break objects in path |
| damagePlayers(float) | void | [pub] | Damage passengers in crash |
| addRandomDamageFromCrash(IsoGameCharacter, float) | void | [pub] | Random body part damage to passenger |
| setGeneralPartCondition(float, float) | void | [pub] | Set all parts condition |
| doDamageOverlay() | void | [pub] | Update damage textures |
| setBloodIntensity(String, float) | void | [pub] | Per-area blood level |
| getBloodIntensity(String) | float | [pub] | Current blood level |
| processHit(IsoGameCharacter, HandWeapon, float) | boolean | [pub] | Melee attack on vehicle |
| WeaponHit(IsoGameCharacter, HandWeapon) | void | [pub] | Weapon damage handler |
| Thump(IsoMovingObject) | void | [pub] | Zombie thump handler |
| getThumpCondition() | float | [pub] | HP for thump system |
| onHitLandmine(IsoGridSquare) | void | [pub] | Landmine explosion |

## 9. BaseVehicle Methods - Towing/Trailer

| Method | Return | Access | Notes |
|-|-|-|-|
| getVehicleTowing() | BaseVehicle | [pub] | Towed vehicle |
| getVehicleTowedBy() | BaseVehicle | [pub] | Towing vehicle |
| setVehicleTowing(BaseVehicle, String, String) | void | [pub] | Attach trailer |
| setVehicleTowedBy(BaseVehicle, String, String) | void | [pub] | Set towed-by ref |
| addPointConstraint(IsoPlayer, BaseVehicle, String, String) | void | [pub] | Create physics joint |
| breakConstraint(boolean, boolean) | void | [pub] | Detach trailer |
| canAttachTrailer(BaseVehicle, String, String) | boolean | [pub] | Can connect |
| canAttachTrailer(BaseVehicle, String, String, boolean) | boolean | [pub] | With reconnect flag |
| positionTrailer(BaseVehicle) | void | [pub] | Snap trailer position |
| attachmentExist(String) | boolean | [pub] | Has named attachment |
| getAttachmentWorldPos(String, Vector3f) | Vector3f | [pub] | Attachment world pos |
| getAttachmentLocalPos(String, Vector3f) | Vector3f | [pub] | Attachment local pos |
| getTowAttachmentSelf() | String | [pub] | Own tow point name |
| getTowAttachmentOther() | String | [pub] | Other tow point name |
| getAnimalTrailerSize() | float | [pub] | Animal capacity |
| getAnimals() | ArrayList\<IsoAnimal\> | [pub] | Animals in trailer |
| addAnimalInTrailer(IsoAnimal) | void | [pub] | Load animal |
| removeAnimalFromTrailer(IsoAnimal) | IsoObject | [pub] | Unload animal |
| canAddAnimalInTrailer(IsoAnimal) | boolean | [pub] | Space check |

## 10. BaseVehicle Enums

### Authorization
```
Server, Local, LocalCollide, Remote
```
Determines which machine simulates this vehicle's physics. Server = dedicated server controls. Local = this client controls. LocalCollide = local but with collision authority. Remote = another client controls.

### engineStateTypes
```
Idle, Starting, StartingSuccess, StartingFailed, RetryingStarting,
Running, Stalling, ShuttingDown, RetryStartFromStalling
```
Finite state machine for engine lifecycle. `Values` array provides indexed access.

### WheelInfo (inner class)
| Field | Type | Notes |
|-|-|-|
| steering | float | Current steer angle |
| rotation | float | Current spin rotation |
| skidInfo | float | Skid amount |

## 11. VehiclePart

`zombie.vehicles.VehiclePart extends GameEntity implements ChatElementOwner, WaveSignalDevice`

### Fields
| Field | Type | Access | Notes |
|-|-|-|-|
| vehicle | BaseVehicle | [prot] | Owner vehicle |
| partId | String | [prot] | Fallback ID |
| scriptPart | VehicleScript.Part | [prot] | Script definition |
| container | ItemContainer | [prot] | Inventory container |
| item | InventoryItem | [prot] | Installed item |
| modData | KahluaTable | [priv] | Lua mod data |
| parent | VehiclePart | [prot] | Parent part |
| children | ArrayList\<VehiclePart\> | [prot] | Child parts |
| door | VehicleDoor | [prot] | Door component |
| window | VehicleWindow | [prot] | Window component |
| light | VehicleLight | [prot] | Light component |
| condition | int | [prot] | 0-100 health |
| category | String | [prot] | "engine","tire","nodisplay",etc |
| specificItem | boolean | [prot] | Uses specific item type |
| wheelFriction | float | [priv] | Tire grip |
| mechanicSkillInstaller | int | [priv] | Installer's skill level |
| suspensionDamping | float | [priv] | Suspension damping |
| suspensionCompression | float | [priv] | Suspension compression |
| engineLoudness | float | [priv] | Engine noise from this part |
| durability | float | [priv] | Wear rate multiplier |
| deviceData | DeviceData | [prot] | Radio device data |

### Key Methods
| Method | Return | Access | Notes |
|-|-|-|-|
| getId() | String | [pub] | Part identifier |
| getIndex() | int | [pub] | Index in parts array |
| getVehicle() | BaseVehicle | [pub] | Owner reference |
| getArea() | String | [pub] | Interaction area ID |
| getItemType() | ArrayList\<String\> | [pub] | Valid item types for install |
| getInventoryItem() | T | [pub] | Installed item (generic) |
| setInventoryItem(InventoryItem, int) | void | [pub] | Install with mechanic skill |
| setInventoryItem(InventoryItem) | void | [pub] | Install (skill=0) |
| isInventoryItemUninstalled() | boolean | [pub] | Should have item but doesn't |
| getItemContainer() | ItemContainer | [pub] | Storage container |
| setItemContainer(ItemContainer) | void | [pub] | Set container |
| isContainer() | boolean | [pub] | Has container def |
| getContainerCapacity() | int | [pub] | Max capacity |
| getContainerCapacity(IsoGameCharacter) | int | [pub] | Effective capacity for char |
| getContainerContentType() | String | [pub] | "Air","Gasoline",etc |
| getContainerContentAmount() | float | [pub] | Current fill level |
| setContainerContentAmount(float) | void | [pub] | Set fill level |
| getContainerSeatNumber() | int | [pub] | Seat that accesses this |
| isSeat() | boolean | [pub] | Is a seating part |
| isVehicleTrunk() | boolean | [pub] | ID contains "TruckBed" |
| getCondition() | int | [pub] | 0-100 health |
| setCondition(int) | void | [pub] | Set health, fires damage events |
| damage(int) | void | [pub] | Reduce condition |
| setRandomCondition(InventoryItem) | void | [pub] | Randomize based on spawn |
| setGeneralCondition(InventoryItem, float, float) | void | [pub] | Set based on quality/damage chance |
| getParent() | VehiclePart | [pub] | Parent part |
| addChild(VehiclePart) | void | [pub] | Add child |
| getChildCount() | int | [pub] | Number of children |
| getChild(int) | VehiclePart | [pub] | Child by index |
| getDoor() | VehicleDoor | [pub] | Door component |
| getEnclosingDoor() | VehicleDoor | [pub] | Walk up to find door |
| getWindow() | VehicleWindow | [pub] | Window component |
| getChildWindow() | VehiclePart | [pub] | First child with window |
| findWindow() | VehicleWindow | [pub] | Window from child |
| getLight() | VehicleLight | [pub] | Light component |
| getLightDistance() | float | [pub] | Condition-scaled distance |
| getLightIntensity() | float | [pub] | Condition-scaled intensity |
| createSpotLight(float,float,float,float,float,int) | void | [pub] | Create light |
| createSpotLightColor(...) | void | [pub] | Create colored light |
| setLightActive(boolean) | void | [pub] | Toggle light |
| getWheelIndex() | int | [pub] | Wheel index or -1 |
| getWheelFriction() | float | [pub] | Tire friction value |
| getSuspensionDamping() | float | [pub] | Damping value |
| getSuspensionCompression() | float | [pub] | Compression value |
| getEngineLoudness() | float | [pub] | Loudness value |
| getDurability() | float | [pub] | Wear multiplier |
| getMechanicSkillInstaller() | int | [pub] | Installer skill |
| getCategory() | String | [pub] | Part category |
| repair() | void | [pub] | Full repair this part |
| getLuaFunction(String) | String | [pub] | Named Lua callback |
| getTable(String) | KahluaTable | [pub] | Named table (install/uninstall) |
| getModData() | KahluaTable | [pub] | Lua mod data |
| hasModData() | boolean | [pub] | Has non-empty mod data |
| getDeviceData() | DeviceData | [pub] | Radio data |
| createSignalDevice() | DeviceData | [pub] | Create radio |
| hasDevicePower() | boolean | [pub] | Battery > 0 |
| getNumberByCondition(float,float,float) | float | [static] | Scale value by condition |

## 12. VehicleDoor

`zombie.vehicles.VehicleDoor`

| Field | Type | Access | Notes |
|-|-|-|-|
| part | VehiclePart | [prot] | Owner part |
| open | boolean | [prot] | Open state |
| locked | boolean | [prot] | Locked state |
| lockBroken | boolean | [prot] | Lock damaged |

| Method | Return | Access |
|-|-|-|
| VehicleDoor(VehiclePart) | - | [pub] |
| init(VehicleScript.Door) | void | [pub] |
| isOpen() | boolean | [pub] |
| setOpen(boolean) | void | [pub] |
| isLocked() | boolean | [pub] |
| setLocked(boolean) | void | [pub] |
| isLockBroken() | boolean | [pub] |
| setLockBroken(boolean) | void | [pub] |
| save(ByteBuffer) | void | [pub] |
| load(ByteBuffer, int) | void | [pub] |

## 13. VehicleWindow

`zombie.vehicles.VehicleWindow`

| Field | Type | Access | Notes |
|-|-|-|-|
| part | VehiclePart | [prot] | Owner part |
| openable | boolean | [prot] | Can be opened |
| open | boolean | [prot] | Open state |
| openDelta | float | [priv] | Animation progress 0-1 |

| Method | Return | Access | Notes |
|-|-|-|-|
| getHealth() | int | [pub] | Delegates to part.getCondition() |
| isDestroyed() | boolean | [pub] | Health == 0 |
| isOpenable() | boolean | [pub] | Can roll down |
| isOpen() | boolean | [pub] | Currently open |
| setOpen(boolean) | void | [pub] | Open/close |
| isHittable() | boolean | [pub] | Can be damaged |
| hit(IsoGameCharacter) | void | [pub] | Full destroy |
| damage(int) | void | [pub] | Reduce health, break at 0 |
| getPart() | VehiclePart | [pub] | Owner part |

## 14. VehicleLight

`zombie.vehicles.VehicleLight`

| Field | Type | Access | Default | Notes |
|-|-|-|-|-|
| active | boolean | [pub] | false | Light on/off |
| offset | Vector3f | [pub] | (0,0,0) | Position offset |
| dist | float | [pub] | 16.0 | Light distance |
| intensity | float | [pub] | 1.0 | Brightness |
| dot | float | [pub] | 0.96 | Cone angle (dot product) |
| focusing | int | [pub] | 0 | Focus level (deprecated) |
| r | float | [pub] | 1.0 | Red channel |
| g | float | [pub] | 0.824 | Green channel |
| b | float | [pub] | 0.706 | Blue channel |

## 15. VehicleEngineRPM / EngineRPMData

`zombie.vehicles.VehicleEngineRPM extends BaseScriptObject`

Max 8 gear data slots. Loaded from `vehicleEngineRPM` script blocks.

| Field | Type | Notes |
|-|-|-|
| MAX_GEARS | int (static) | 8 |
| name | String | RPM type name |
| rpmData | EngineRPMData[8] | Per-gear RPM data |

**EngineRPMData** fields:
| Field | Type | Notes |
|-|-|-|
| gearChange | float | RPM to shift up |
| afterGearChange | float | RPM after shifting |

## 16. TransmissionNumber

`zombie.vehicles.TransmissionNumber` (enum)

| Value | Index | String |
|-|-|-|
| R | -1 | "R" |
| N | 0 | "N" |
| Speed1 | 1 | "1" |
| Speed2 | 2 | "2" |
| Speed3 | 3 | "3" |
| Speed4 | 4 | "4" |
| Speed5 | 5 | "5" |
| Speed6 | 6 | "6" |
| Speed7 | 7 | "7" |
| Speed8 | 8 | "8" |

Methods: `fromIndex(int)`, `getNext(int gearCount)`, `getPrev(int gearCount)`, `getString()`, `getIndex()`

## 17. VehicleType (Spawn System)

`zombie.vehicles.VehicleType` - Controls vehicle spawn distribution per zone.

### Fields
| Field | Type | Access | Default | Notes |
|-|-|-|-|-|
| name | String | [pub] | - | Zone name (e.g. "parkingstall") |
| vehiclesDefinition | ArrayList\<VehicleTypeDefinition\> | [pub] | - | Vehicles + spawn chances |
| chanceToSpawnNormal | int | [pub] | 80 | % for normal spawn |
| chanceToSpawnBurnt | int | [pub] | 0 | % for burnt variant |
| spawnRate | int | [pub] | 16 | Density |
| chanceOfOverCar | int | [pub] | 0 | Stacked car % |
| randomAngle | boolean | [pub] | false | Random rotation |
| baseVehicleQuality | float | [pub] | 1.0 | Part condition mult |
| chanceToSpawnKey | int | [priv] | 70 | % key present |
| chanceToPartDamage | int | [pub] | 0 | Extra damage % |
| isSpecialCar | boolean | [pub] | false | Emergency/rare |
| isBurntCar | boolean | [pub] | false | Burnt variant pool |
| chanceToSpawnSpecial | int | [pub] | 5 | % special override |
| forceSpawn | boolean | [pub] | false | Always spawn |

### Static Collections
| Field | Type | Notes |
|-|-|-|
| vehicles | HashMap\<String, VehicleType\> | [static] All zone types |
| specialVehicles | ArrayList\<VehicleType\> | [static] Special pool |

### Key Methods
| Method | Return | Access | Notes |
|-|-|-|-|
| init() | void | [static] | Load from VehicleZoneDistribution Lua |
| hasTypeForZone(String) | boolean | [static] | Zone has vehicle config |
| getRandomVehicleType(String) | VehicleType | [static] | Pick zone type |
| getRandomVehicleType(String, Boolean) | VehicleType | [static] | With normal fallback |
| getTypeFromName(String) | VehicleType | [static] | Direct lookup |
| getBaseVehicleQuality() | float | [pub] | Quality factor |
| getRandomBaseVehicleQuality() | float | [pub] | Quality +/- 0.1 |
| getChanceToSpawnKey() | int | [pub] | Key chance |

### VehicleTypeDefinition (inner class)
| Field | Type | Notes |
|-|-|-|
| vehicleType | String | Script name (e.g. "Base.PickUpTruck") |
| index | int | Sort order |
| spawnChance | float | Normalized % within zone |
