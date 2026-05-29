# Vehicle Mechanics - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | VehicleScript (Code Side) | 16-80 |
| 2 | VehicleScript Inner Classes | 81-232 |
| 3 | Collision Damage to Zombies/Characters | 233-293 |
| 4 | Zombie Attack on Vehicle | 294-332 |
| 5 | Part Condition Degradation from Collision | 333-383 |
| 6 | Passenger Injury from Collision | 384-451 |

---

## 1. VehicleScript (Code Side)

`zombie.scripting.objects.VehicleScript extends BaseScriptObject implements IModelAttachmentOwner`

### Physics/Vehicle Fields
| Field | Type | Default | Script Key | Notes |
|-|-|-|-|-|
| mass | float | 800.0 | mass | Base weight (kg) |
| engineForce | float | 3000.0 | engineForce | Engine power (N) |
| engineIdleSpeed | float | 750.0 | engineIdleSpeed | Idle RPM |
| maxSpeed | float | 20.0 | maxSpeed | Max forward km/h |
| maxSpeedReverse | float | 40.0 | maxSpeedReverse | Max reverse km/h |
| steeringIncrement | float | 0.04 | steeringIncrement | Steering speed |
| steeringClamp | float | 0.4 | steeringClamp | Max steering angle |
| wheelFriction | float | 800.0 | wheelFriction | Base tire grip |
| stoppingMovementForce | float | 1.0 | stoppingMovementForce | Rolling resistance |
| rollInfluence | float | 0.1 | rollInfluence | Roll stability |
| suspensionStiffness | float | 20.0 | suspensionStiffness | Spring rate |
| suspensionDamping | float | 2.3 | suspensionDamping | Shock absorber |
| suspensionCompression | float | 4.4 | suspensionCompression | Compression damping |
| suspensionRestLength | float | 0.6 | suspensionRestLength | Natural spring length |
| maxSuspensionTravelCm | float | 500.0 | maxSuspensionTravelCm | Max suspension travel |
| offroadEfficiency | float | 1.0 | offRoadEfficiency | Offroad speed factor |
| extents | Vector3f | (0.75,0.5,2.0) | extents | Collision box half-extents |
| centerOfMassOffset | Vector3f | (0,0,0) | centerOfMassOffset | CoM position |
| isSmallVehicle | boolean | true | isSmallVehicle | Size classification |

### Health/Quality Fields
| Field | Type | Default | Script Key |
|-|-|-|-|
| frontEndHealth | int | 100 | frontEndDurability |
| rearEndHealth | int | 100 | rearEndDurability |
| engineQuality | int | 100 | engineQuality |
| engineLoudness | int | 100 | engineLoudness |
| storageCapacity | int | 100 | storageCapacity |
| seats | int | 2 | seats |
| mechanicType | int | 0 | mechanicType |
| engineRepairLevel | int | 0 | engineRepairLevel |
| playerDamageProtection | float | 0 | playerDamageProtection |

### Appearance/Sound Fields
| Field | Type | Script Key |
|-|-|-|
| forcedHue/Sat/Val | float | forcedColor (space-separated HSV) |
| engineRpmType | String | engineRPMType |
| hasSiren | boolean | hasSiren |
| textureMaskEnable | boolean | textureMaskEnable |
| carMechanicsOverlay | String | carMechanicsOverlay |
| carModelName | String | carModelName |
| hasLighter | boolean | hasLighter |
| notKillCrops | boolean | notKillCrops |
| neverSpawnKey | boolean | neverSpawnKey |

### Gear Ratios
| Field | Default | Script Key |
|-|-|-|
| gearRatioCount | 4 | gearRatioCount |
| gearRatio[0] (R) | 7.09 | gearRatioR |
| gearRatio[1] | 6.44 | gearRatio1 |
| gearRatio[2] | 4.10 | gearRatio2 |
| gearRatio[3] | 2.29 | gearRatio3 |
| gearRatio[4] | 1.47 | gearRatio4 |
| gearRatio[5] | 1.00 | gearRatio5 |
| gearRatio[6-8] | 0 | gearRatio6-8 |

## 2. VehicleScript Inner Classes

### Skin
| Field | Type | Notes |
|-|-|-|
| texture | String | Base paint texture |
| textureRust | String | Rust overlay |
| textureMask | String | Color mask |
| textureLights | String | Lights overlay |
| textureDamage1Overlay/Shell | String | Light damage textures |
| textureDamage2Overlay/Shell | String | Heavy damage textures |
| textureShadow | String | Shadow texture |

### Area
| Field | Type | Notes |
|-|-|-|
| id | String | e.g. "Engine","TruckBed","SeatFrontLeft" |
| x, y | float | Center position |
| w, h | float | Interaction zone size |

### Part
| Field | Type | Notes |
|-|-|-|
| id | String | "Engine","TireFrontLeft","DoorFrontLeft",etc |
| parent | String | Parent part ID |
| itemType | ArrayList\<String\> | Valid install items |
| container | Container | Storage definition |
| area | String | Interaction area |
| mechanicArea | String | Mechanic UI area |
| wheel | String | Linked wheel ID |
| tables | THashMap\<String,KahluaTable\> | install/uninstall requirements |
| luaFunctions | THashMap\<String,String\> | create/update/use callbacks |
| models | ArrayList\<Model\> | Visual models |
| door | Door | Door component def |
| window | Window | Window component def |
| anims | ArrayList\<Anim\> | Part animations |
| category | String | "engine","tire","nodisplay" |
| specificItem | boolean | Uses specific item (default true) |
| mechanicRequireKey | boolean | Needs key to service |
| repairMechanic | boolean | Repairable |
| hasLightsRear | boolean | Has rear lights |
| durability | float | Wear rate |

### Passenger
| Field | Type | Notes |
|-|-|-|
| id | String | "FrontLeft","FrontRight","RearLeft",etc |
| anims | ArrayList\<Anim\> | Entry/exit animations |
| switchSeats | ArrayList\<SwitchSeat\> | Seat transfer options |
| hasRoof | boolean | Covered (default true) |
| showPassenger | boolean | Render occupant |
| door/door2 | String | Primary/alternate exit door |
| area | String | Seat area |
| positions | ArrayList\<Position\> | inside/outside positions |

### SwitchSeat
| Field | Type | Notes |
|-|-|-|
| id | String | Target seat name |
| seat | int | Target seat index |
| anim | String | Animation name |
| rate | float | Animation speed (default 1.0) |
| sound | String | Sound name |

### Wheel
| Field | Type | Default | Notes |
|-|-|-|-|
| id | String | - | "FrontLeft","RearRight",etc |
| front | boolean | - | Front axle |
| offset | Vector3f | (0,0,0) | Position relative to vehicle |
| radius | float | 0.5 | Wheel radius |
| width | float | 0.4 | Wheel width |

### PhysicsShape
| Field | Type | Notes |
|-|-|-|
| type | int | 1=box, 2=sphere, 3=mesh |
| offset | Vector3f | Position |
| rotate | Vector3f | Rotation |
| extents | Vector3f | Half-extents (box) |
| radius | float | Sphere radius |

### Container
| Field | Type | Notes |
|-|-|-|
| capacity | int | Max weight units |
| seat | int | Accessible from seat (-1=none) |
| seatId | String | Seat part ID |
| luaTest | String | Access test function |
| contentType | String | "Air","Gasoline",etc |
| conditionAffectsCapacity | boolean | Degraded = less space |

### Position
| Field | Type | Notes |
|-|-|-|
| id | String | "inside","outside","outside2" |
| offset | Vector3f | World position |
| rotate | Vector3f | Facing direction |
| area | String | Linked area |

### Anim
| Field | Type | Default | Notes |
|-|-|-|-|
| id | String | - | "Open","Close","Enter",etc |
| anim | String | - | Animation asset name |
| rate | float | 1.0 | Playback speed |
| animate | boolean | true | Play animation |
| loop | boolean | false | Loop animation |
| reverse | boolean | false | Play backwards |
| sound | String | null | Sound to play |

### Model
| Field | Type | Notes |
|-|-|-|
| id | String | Model identifier |
| file | String | Model asset file |
| scale | float | Size multiplier (default 1.0) |
| offset | Vector3f | Position offset |
| rotate | Vector3f | Rotation |
| attachmentNameParent/Self | String | Bone attachment names |

### LightBar
| Field | Type | Notes |
|-|-|-|
| enable | boolean | Has lightbar |
| soundSiren0/1/2 | String | Yelp/Wall/Alarm sounds |

### Sounds
| Field | Type | Notes |
|-|-|-|
| alarmEnable | Boolean | Has alarm |
| alarm | ArrayList\<String\> | Alarm sound names |
| alarmLoop | ArrayList\<String\> | Looping alarm sounds |
| hornEnable | boolean | Has horn |
| horn | String | Horn sound |
| backSignalEnable | boolean | Has reverse beep |
| backSignal | String | Reverse beep sound |
| engine | String | Engine loop sound |
| engineStart | String | Ignition sound |
| engineTurnOff | String | Shutdown sound |
| handBrake | String | Handbrake sound |
| ignitionFail | String | Failed start sound |
| ignitionFailNoPower | String | Dead battery sound |

### Door (inner)
Empty class - existence indicates the part has a door component.

### Window (inner)
| Field | Type | Notes |
|-|-|-|
| openable | boolean | Can be rolled down |

## 3. Collision Damage to Zombies/Characters

### hitCharacter flow (BaseVehicle)
```java
public float hitCharacter(IsoGameCharacter chr, Vector2 impactPosOnVehicle, boolean pushedBack)
```
1. `canBeHitByVehicle(this)` check - skip if immune
2. Speed capped at 15.0 physics units: `speed = Math.min(velocity.length(), 15.0f)`
3. Minimum speed threshold: `speed < 0.05f` returns 0 damage
4. Compute `hitSpeed = speed + physics.clientForce / fudgedMass`
5. Delegates to `chr.onHitByVehicle()` which calls `onHitByVehicleApplyDamage()`

### Damage to vehicle from hitting character (calculateDamageWithCharacter)
```java
float minSpeedToDamage = 5.0f;
float speedAtMaxDamage = 160.0f;
float dmgMultiplier = 60.0f;
float dmgAlpha = (currentAbsoluteSpeedKmHour - 5.0f) / 155.0f;
float dmgAlphaClamped = PZMath.clamp(dmgAlpha, 0.0f, 1.0f);
float dmg = dmgMultiplier * PZMath.lerpFunc_EaseOutQuad(dmgAlphaClamped);
return PZMath.roundToInt(dmg);
```
- Below 5 km/h: 0 damage to vehicle
- At 160+ km/h: 60 damage to vehicle (capped)
- Curve: EaseOutQuad (fast ramp, slow approach to max)
- Animals scale multiplier: `dmgMultiplier *= min(weight / 50.0, 1.5)` (max 90 for large animals)

### Damage to character on impact (calculateDamageFromVehicleImpact)

**Standing target:**
```java
impactSpeedNoDamage = 3.0f;   // physics speed units
impactSpeedMaxDamage = 20.0f;
maxDamage = 1.5f;  // 1.5 = 150% of max health = instakill
impactDamageAlpha = (impactSpeed - 3.0) / 17.0;
damage = 1.5 * EaseOutQuad(impactDamageAlpha);
```

**Prone target (run-over):**
```java
impactSpeedNoDamage = 0.2f;
impactSpeedMaxDamage = 10.0f;
maxDamage = 0.5f;  // 50% max health per tick
impactDamageAlpha = (impactSpeed - 0.2) / 9.8;
damage = 0.5 * EaseOutQuad(impactDamageAlpha);
```

### Sequential hit modifiers
After first impact, damage is reduced for sustained contact:
- **Being pushed** (standing, not first hit): `damage *= 0.01` (99% reduction)
- **Being crushed** (prone, not first hit): `damage *= 0.2` (80% reduction)
- Both modifiers also scale by `GameTime.getMultiplier()` (game speed)

### Knockdown thresholds
```java
minSpeedToPossibleKnockdown = 3.5f;
maxSpeedToPossibleKnockdown = 14.5f;
knockDownRandAlpha = (speed - 3.5) / 11.0;
// 100% knockdown at speed >= 14.5, probabilistic below
```

## 4. Zombie Attack on Vehicle

### Thump method (BaseVehicle)
Zombie thumping targets the vehicle's **lightbar** part specifically:
```java
public void Thump(IsoMovingObject thumper) {
    VehiclePart lightbar = this.getPartById("lightbar");
    if (lightbar == null) return;
    if (lightbar.getCondition() <= 0) {
        thumper.setThumpTarget(null);  // stop thumping if lightbar destroyed
    }
    VehiclePart part = this.getUseablePart((IsoGameCharacter)thumper);
    if (part != null) {
        part.setCondition(part.getCondition() - Rand.Next(1, 5));
    }
    lightbar.setCondition(lightbar.getCondition() - Rand.Next(1, 5));
}
```

**Key details:**
- Zombies can only thump vehicles that have a `lightbar` part (emergency vehicles)
- `getThumpableFor()` returns null - zombies cannot select arbitrary vehicle parts to thump
- Each thump: lightbar loses 1-4 condition, plus nearest useable part loses 1-4 condition
- Once lightbar reaches 0, zombie clears thump target and wanders away
- `WeaponHit()` is empty - players cannot weapon-attack vehicles through this system

### Bodywork damage from zombies (getNearestBodyworkPart)
```java
for (VehiclePart part : this.parts) {
    if (!"door".equals(part.getCategory()) && !"bodywork".equals(part.getCategory())) continue;
    if (!this.isInArea(part.getArea(), chr)) continue;
    if (part.getCondition() <= 0) continue;
    return part;
}
```
Only parts with category "door" or "bodywork" in the zombie's area are targetable.
Parts at condition 0 are skipped. Window parts with condition < 15 count as broken glass
sources for passenger injury calculations.

## 5. Part Condition Degradation from Collision

### Front collision (addDamageFront)
Called with `(int)(abs(delta) / modifier)` where modifier is from sandbox `carDamageOnImpact`:

| Sandbox Setting | Modifier |
|-|-|
| 1 (Very High) | 1.9 |
| 2 (High) | 1.6 |
| 3 (Normal) | 1.3 |
| 4 (Low) | 1.1 |
| 5 (Very Low) | 0.9 |

```java
currentFrontEndDurability -= dmg;
```
Then cascading part damage:
- **EngineDoor**: `Rand.Next(max(1, dmg-5), dmg+5)`
- **Engine** (if EngineDoor destroyed or condition < 25): `Rand.Next(max(1, dmg-3), dmg+3)`
- **Windshield**: `Rand.Next(max(1, dmg-5), dmg+5)`
- **Front doors** (25% chance): `Rand.Next(max(1, dmg-5), dmg+5)`
- **Front windows** (25% chance, follows door): `Rand.Next(max(1, dmg-5), dmg+5)`

### Rear collision (addDamageRear)
```java
currentRearEndDurability -= dmg;
```
- **TruckBed**: `Rand.Next(max(1, dmg-5), dmg+5)`
- **DoorRear/TrunkDoor**: `Rand.Next(max(1, dmg-5), dmg+5)`
- **WindshieldRear** (if dmg > 12): full dmg
- **GasTank** (probability-based): `Rand.Next(1, 3)`

### Hitting a character (addDamageFrontHitAChr)
Lighter damage than wall collisions:
- Skipped entirely if `dmg < 4` (with 1/7 random chance)
- **EngineDoor**: `Rand.Next(max(1, dmg-10), dmg+3)`
- **Engine** (only if EngineDoor destroyed, 25% chance): `Rand.Next(2, 4)`
- **Windshield** (only if dmg > 12): `Rand.Next(max(1, dmg-10), dmg+3)`
- **Front tires** (probability-based): `Rand.Next(1, 3)`
- **Headlights** (probability-based): `Rand.Next(1, 4)`
- Adds blood intensity to "Front" area

### Engine stalling from condition
```java
if (this.engineState == engineStateTypes.Running
    && engine != null && engine.getCondition() < 50
    && Rand.Next(Rand.AdjustForFramerate(engine.getCondition() * 12)) == 0)
```
Engine randomly stalls when condition < 50. Lower condition = more frequent stalls.
At condition 1: stalls roughly every 12 frames. At condition 49: roughly every 588 frames.

## 6. Passenger Injury from Collision

### Trigger
```java
public void damagePlayers(float damage) {
    if (!SandboxOptions.instance.playerDamageFromCrash.getValue()) return;
    for (Passenger p : this.passengers) {
        if (p.character == null || p.character.isGodMod()) continue;
        this.addRandomDamageFromCrash(p.character, damage);
    }
}
```
Gated by sandbox option `playerDamageFromCrash`. Applies to ALL passengers, not just driver.
Raw crash delta (before sandbox modifier) is passed as the damage parameter.

### Body part selection
```java
int bodyPart = Rand.Next(BodyPartType.ToIndex(BodyPartType.Hand_L), BodyPartType.ToIndex(BodyPartType.MAX));
```
Random body part from Hand_L through all remaining parts. This means hands, arms, legs, feet
are disproportionately targeted (head/torso are lower indices, excluded from the range).

### Damage scaling per body part
```java
float realDamage = Math.max(Rand.Next(damage - 15.0f, damage), 5.0f);
```
Randomized in range `[damage-15, damage]`, minimum 5. Then modified:

| Modifier | Effect |
|-|-|
| Fast Healer trait | realDamage *= 0.8 |
| Slow Healer trait | realDamage *= 1.2 |
| Injury Severity = Low | realDamage *= 0.5 |
| Injury Severity = High | realDamage *= 1.5 |
| Vehicle script playerDamageProtection | realDamage *= protection value |
| Final multiplier | realDamage *= 0.9 (flat 10% reduction) |

### Number of injured body parts
| Crash Damage | Body Parts Hit |
|-|-|
| <= 40 | 1 |
| 40-70 | Rand(1, 3) |
| > 70 | Rand(2, 4) |

### Severe injury generation
- **Deep wound**: if `realDamage > 40` with 1/12 chance
- **Bone fracture**: if `realDamage > 50` with 1/10 chance (requires sandbox `boneFracture`).
  Neck/Groin get deep wound instead of fracture.
  Fracture severity: `Rand(Rand(10, realDmg+10), Rand(realDmg+20, realDmg+30))`

### Broken glass laceration
Counts vehicle window parts with condition < 15 as `brokenGlass`. Then:
```java
if (realDamage > 30 && Rand.Next(12 - brokenGlass) == 0) {
    part = chr.getBodyDamage().setScratchedWindow();
    if (Rand.Next(5) == 0) {
        part.generateDeepWound();
        part.setHaveGlass(true);  // embedded glass
    }
}
```
More broken windows = higher chance of glass cuts. At 4 broken windows, base chance is 1/8.

### Seatbelt mechanics
Seatbelts are NOT checked in `damagePlayers()` or `addRandomDamageFromCrash()`. The crash
damage system applies uniformly to all passengers regardless of seatbelt state. Seatbelts
affect ejection during crashes (handled separately in the character update loop), not the
damage amount from the collision itself.
