# Vehicle Definitions - PZ Data Map
Source: media/scripts/generated/vehicles/ | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Script Format Overview | 18-48 |
| 2 | Top-Level Vehicle Fields | 49-129 |
| 3 | Block Types | 130-310 |
| 4 | Template System | 311-363 |
| 5 | All Vehicle Types | 364-460 |
| 6 | Part Types Reference | 461-514 |
| 7 | Mechanical Stats Ranges | 515-571 |
| 8 | Annotated Example | 572-722 |

---

## 1. Script Format Overview

Vehicle definitions live in `media/scripts/generated/vehicles/`. Each `.txt` file uses PZ's custom script format (not JSON, not Lua).

### Basic Structure
```
module Base
{
    vehicle <VehicleName>
    {
        <key> = <value>,
        <block-type> <id>
        {
            <nested key> = <value>,
        }
    }
}
```

Rules:
- Module is always `Base`
- Values are comma-terminated
- Blocks use curly braces
- Comments not observed in generated files
- Wildcards in part IDs: `part Door*` matches DoorFrontLeft, DoorFrontRight, DoorRear, etc
- Template references: `template = TemplateName` or `template = TemplateName/part/PartId`
- Override template: `template! = TemplateName` (loads template body directly)
- Files ending in `_template.txt` define reusable vehicle templates
- Files ending in `_model.txt` define model-only overrides
- Per-vehicle `.txt` files define complete vehicle scripts

## 2. Top-Level Vehicle Fields

### Physics & Movement
| Field | Type | Default | Example | Notes |
|-|-|-|-|-|
| mass | float | 800 | 200-900 | Vehicle weight in kg |
| engineForce | float | 3000 | 3000-5700 | Engine power in Newtons |
| maxSpeed | float | 20 | 50-120 | Max forward speed km/h |
| maxSpeedReverse | float | 40 | - | Max reverse speed km/h |
| steeringIncrement | float | 0.04 | 0.03-0.04 | Steering response speed |
| steeringClamp | float | 0.4 | 0.3-0.4 | Max steering angle |
| rollInfluence | float | 0.1 | 0.7-1.0 | Roll stability (higher = more stable) |
| wheelFriction | float | 800 | 1.4-4.0 | Tire grip factor |
| stoppingMovementForce | float | 1.0 | 1.0-5.0 | Drag/rolling resistance |
| brakingForce | float | - | 1-70 | Brake strength (if specified) |
| offRoadEfficiency | float | 1.0 | 0.8-1.0 | Speed multiplier on dirt/grass |

### Suspension
| Field | Type | Default | Example |
|-|-|-|-|
| suspensionStiffness | float | 20.0 | 20-50 |
| suspensionCompression | float | 4.4 | 2.83-4.4 |
| suspensionDamping | float | 2.3 | 2.3-3.4 |
| suspensionRestLength | float | 0.6 | 0.2-0.6 |
| maxSuspensionTravelCm | float | 500 | 10-500 |

### Durability & Health
| Field | Type | Default | Example |
|-|-|-|-|
| frontEndDurability | int | 100 | 100-150 |
| rearEndDurability | int | 100 | 100-150 |
| engineQuality | int | 100 | 60-100 |
| engineLoudness | int | 100 | 55-100 |
| seats | int | 2 | 2-6 |

### Collision & Size
| Field | Type | Example | Notes |
|-|-|-|-|
| extents | vec3 | 0.78 0.51 2.05 | Half-extents (x=width, y=height, z=length) |
| physicsChassisShape | vec3 | (same as extents) | Physics collision box |
| centerOfMassOffset | vec3 | 0.0 0.30 0.0 | Center of mass position |
| shadowExtents | vec2 | 0.78 2.05 | Shadow size (x, z) |
| shadowOffset | vec2 | 0.0 0.0 | Shadow position offset |
| extentsOffset | vec2 | 0.5 0.5 | Collision offset factor |
| isSmallVehicle | bool | true/false | Affects AI navigation |
| useChassisPhysicsCollision | bool | true | Use chassis or custom shapes |

### Identity & Spawning
| Field | Type | Notes |
|-|-|-|
| mechanicType | int | Mechanic skill tier (1-3) |
| engineRepairLevel | int | Min skill to repair engine (4-7) |
| playerDamageProtection | float | Crash damage reduction for driver |
| engineRPMType | string | Sound profile: "jeep","firebird","van","stepvan" |
| specialKeyRing | string | Semicolon-separated key ring item IDs |
| specialLootChance | int | % chance of special loot (default 8) |
| specialKeyRingChance | int | % chance of special key ring |
| neverSpawnKey | bool | Trailers: true |
| hasLighter | bool | Can light cigarettes (default true) |
| notKillCrops | bool | Don't destroy crops when driving over |
| forcedColor | vec3 | HSV color override |

### Textures
| Field | Example | Notes |
|-|-|-|
| textureMask | Vehicles/vehicle_van_mask | Color tinting mask |
| textureLights | Vehicles/vehicle_van_lights | Lights overlay |
| textureDamage1Overlay | Vehicles/Veh_Blood_Mask | Light blood splatter |
| textureDamage2Overlay | Vehicles/Veh_Blood_Hvy | Heavy blood splatter |
| textureDamage1Shell | Vehicles/Veh_Damage1 | Light body damage |
| textureDamage2Shell | Vehicles/Veh_Damage2 | Heavy body damage |
| textureRust | Vehicles/Veh_Rust | Rust overlay |
| textureMaskEnable | bool | Enable color mask |

### Gear Ratios
| Field | Notes |
|-|-|
| gearRatioCount | Number of forward gears (4-5 typical) |
| gearRatioR | Reverse gear ratio |
| gearRatio1..8 | Forward gear ratios (high = low gear) |

## 3. Block Types

### model
```
model
{
    file = Vehicles_PickUpTruck,
    scale = 1.82,
    offset = 0.0 0.3022 0.0,
}
```
Every vehicle has a base model. `scale = 1.82` is standard for B42 vehicles.

### skin
```
skin
{
    texture = Vehicles/vehicle_pickupshell,
}
```
Each skin block defines an alternate paint job. Multiple skins per vehicle.

### wheel
```
wheel FrontLeft
{
    front = true,
    offset = 0.3242 -0.2143 0.5879,
    radius = 0.15,
    width = 0.2,
}
```
4 wheels per vehicle (FrontLeft, FrontRight, RearLeft, RearRight). 2 for trailers.

### passenger
```
passenger FrontLeft
{
    door2 = DoorRear,
    position inside
    {
        offset = 0.1758 -0.1374 0.0659,
        rotate = 0.0 0.0 0.0,
    }
    position outside
    {
        offset = 0.5934 -0.467 0.1813,
        rotate = 0.0 0.0 0.0,
        area = SeatFrontLeft,
    }
    position outside2
    {
        offset = 0.0 -0.4725 -1.5989,
        rotate = 0.0 0.0 0.0,
    }
}
```
Fields: `door`, `door2` (alternate exit), `hasRoof`, `showPassenger`. Positions: `inside` (seated), `outside` (entry point), `outside2` (alternate exit point).

### area
```
area SeatFrontLeft
{
    xywh = 0.6703 0.1813 0.4725 0.4725,
}
```
Interactive zones. `xywh` = center x, center y, width, height in local vehicle coords.

### part
```
part Engine
{
    mechanicArea = Engine,
    area = Engine,
    category = engine,
    mechanicRequireKey = true,
    durability = 10,
    itemType = Base.OldTire;Base.NormalTire;Base.ModernTire,
    container
    {
        capacity = 130,
        contentType = Air,
        conditionAffectsCapacity = true,
        test = Vehicles.ContainerAccess.TruckBedOpenInside,
        seat = 0,
        seatId = SeatFrontLeft,
    }
    table install
    {
        items { 1 { type = Base.Jack, count = 1, keep = true, } }
        time = 400,
        skills = Mechanics:1,
        recipes = Intermediate Mechanics,
        test = Vehicles.InstallTest.Default,
        complete = Vehicles.InstallComplete.Tire,
        requireInstalled = SuspensionFrontLeft,
    }
    table uninstall
    {
        requireUninstalled = WindshieldRear,
    }
    lua
    {
        create = Vehicles.Create.Engine,
        update = Vehicles.Update.Engine,
        init = Vehicles.Init.Tire,
        checkEngine = Vehicles.CheckEngine.Engine,
        checkOperate = Vehicles.CheckOperate.Tire,
        use = Vehicles.Use.TrunkDoor,
    }
    model InflatedTirePlusWheel
    {
        file = Vehicles_Wheel,
    }
    anim Open
    {
        sound = VehicleWindowElectricOpen,
    }
    door {}
    window { openable = true, }
    hasLightsRear = true,
}
```
Part blocks support wildcards: `part Door*` applies to all Door-prefixed parts.

### physics
```
physics box
{
    offset = 0.0 0.2148 -0.1868,
    extents = 0.6374 0.2198 0.956,
    rotate = 0.0 0.0 0.0,
}
physics sphere
{
    offset = 0.0 0.0989 0.7582,
    radius = 0.0549,
}
```
Custom collision shapes. Types: `box`, `sphere`, `mesh`. Used with `useChassisPhysicsCollision = false`.

### attachment
```
attachment trailer
{
    offset = 0.0 -0.2747 -1.1813,
    rotate = 0.0 0.0 0.0,
    zoffset = -1.0,
    canAttach = trailer,
    updateconstraint = false,
}
```
Tow hitch and other attachment points. `zoffset` controls constraint offset.

### lightbar
```
lightbar
{
    soundSiren = VehicleSiren,
    leftCol = 0;0;1,
    rightCol = 1;0;0,
}
```
Emergency vehicle lights. Colors are RGB floats separated by semicolons.

### sound
```
sound
{
    engine = VehicleEngineVan,
    engineStart = VehicleEngineStartVan,
    engineTurnOff = VehicleEngineTurnOffVan,
    horn = VehicleHornStandard,
    alarm = VehicleAlarmGeneric1 VehicleAlarmGeneric2,
    backSignal = VehicleBackSignal,
    handBrake = VehicleHandBrake,
    ignitionFail = VehicleIgnitionFailVan,
    ignitionFailNoPower = VehicleIgnitionFailNoPower,
}
```

## 4. Template System

Templates are defined in `template_*.txt` files:
```
module Base
{
    template vehicle Tire
    {
        part TireFrontLeft { ... }
        part TireRearRight { ... }
        part Tire* { ... }     // wildcard defaults
    }
}
```

Referenced in vehicles via:
- `template = Tire` - include all parts from template
- `template = Tire/part/TireFrontLeft` - include only specific part
- `template! = SoundsSportsCar` - inject template body directly into vehicle

### Available Templates
| Template | Provides |
|-|-|
| Battery | Battery part (create/update Lua) |
| Brake | BrakeFrontLeft/Right, BrakeRearLeft/Right |
| Door | DoorFrontLeft/Right, DoorRearLeft/Right |
| Engine | Engine part (create/update/checkEngine Lua) |
| EngineDoor | Hood/engine cover part |
| GasTank | Fuel tank with capacity |
| GloveBox | Glovebox storage |
| Headlight | HeadlightLeft/Right |
| Heater | Heater part |
| Lightbar | Emergency lightbar |
| Muffler | Exhaust muffler |
| PassengerCompartment | Interior climate part |
| PassengerSeat2 | 2-seat passenger layout |
| Radio | Vehicle radio |
| RadioHAM | HAM radio |
| Seat | Individual seat |
| Suspension | SuspensionFrontLeft/Right, SuspensionRearLeft/Right |
| Tire | TireFrontLeft/Right, TireRearLeft/Right with install reqs |
| Trunk | Cargo storage |
| TrunkDoor | Trunk/boot lid |
| Window | WindowFrontLeft/Right |
| WindowNoDoor | Window without door parent |
| Windshield | Windshield/WindshieldRear |

### Collision Templates
Per-vehicle collision shapes: CarLightsCollision, CarLuxuryCollision, CarModernCollision, CarModern02Collision, CarNormalCollision, CarSmallCollision, CarSmall02Collision, CarSportsCollision, CarStationwagonCollision, CarTaxiCollision, OffroadCollision, PickupTruckCollision, PickupVanCollision, StepVanCollision, SuvCollision, VanCollision

### Sound Templates
SoundsJeep, SoundsSportsCar, SoundsStepVan, SoundsVan

## 5. All Vehicle Types

### Standard Cars
| Script Name | File | Seats | Notes |
|-|-|-|-|
| CarNormal | vehicle_car_normal.txt | 4 | Generic sedan |
| CarSmall | vehicle_car_small.txt | 2 | Compact car |
| CarSmall02 | vehicle_car_small02.txt | 2 | Compact variant |
| CarLuxury | vehicle_car_luxury.txt | 4 | Luxury sedan |
| CarModern | vehicle_car_modern.txt | 4 | Modern sedan |
| CarModern02 | vehicle_car_modern02.txt | 4 | Modern sedan variant |
| CarModernMartin | vehicle_car_modern_martin.txt | 4 | Martin branded |
| CarStationwagon | vehicle_car_stationwagon.txt | 4 | Station wagon |
| CarStationwagon2 | vehicle_car_stationwagon2.txt | 4 | Station wagon variant |
| Taxi | vehicle_taxi.txt | 4 | Taxi cab |
| Taxi2 | vehicle_taxi2.txt | 4 | Taxi variant |

### Sports/Performance
| Script Name | File | Seats | Notes |
|-|-|-|-|
| SportsCar | vehicle_car_sports.txt | 2 | Fast, mechType 3 |
| SportsCarEZ | vehicle_car_sports_ez.txt | 2 | Sports variant |
| ModernEZ | vehicle_car_modern_ez.txt | 4 | Modern performance |
| Racecar | vehicle_racecar.txt | 2 | Race car |
| Racecar12 | vehicle_car_racecar12.txt | 2 | #12 racer |
| Racecar34 | vehicle_car_racecar34.txt | 2 | #34 racer |
| Racecar58 | vehicle_car_racecar58.txt | 2 | #58 racer |

### Trucks & Pickups
| Script Name | File | Seats | Notes |
|-|-|-|-|
| PickUpTruck | vehicle_pickuptruck.txt | 2 | Standard pickup |
| PickUpTruckCamo | vehicle_pickuptruck_camo.txt | 2 | Camo paint |
| PickUpTruckLights | vehicle_pickuptruck_lights.txt | 2 | With lightbar |
| PickUpTruckLightsFire | vehicle_pickuptruck_lights_fire.txt | 2 | Fire dept |
| PickUpTruckLightsRanger | vehicle_pickuptruck_lights_ranger.txt | 2 | Ranger |
| PickUpVan | vehicle_pickupvan.txt | 2 | Pickup van |
| PickUpVanCamo | vehicle_pickupvan_camo.txt | 2 | Camo variant |
| PickUpVanLights | vehicle_pickupvan_lights.txt | 2 | With lightbar |
| PickUpVanLightsFire | vehicle_pickupvan_lights_fire.txt | 2 | Fire dept |
| PickUpVanLightsPolice | vehicle_pickupvan_lights_police.txt | 2 | Police |
| PickUpVanLightsRanger | vehicle_pickupvan_lights_ranger.txt | 2 | Ranger |

### Emergency/Lights Vehicles
| Script Name | File | Seats | Notes |
|-|-|-|-|
| CarLights | vehicle_car_lights.txt | 4 | Generic lights car |
| CarLightsPolice | vehicle_car_lights_police.txt | 4 | Police car |
| CarLightsRanger | vehicle_car_lights_ranger.txt | 4 | Park ranger |

### Vans & Large Vehicles
| Script Name | File | Seats | Notes |
|-|-|-|-|
| Van | vehicle_van.txt | 2 | Cargo van |
| VanAmbulance | vehicle_van_ambulance.txt | 2 | Ambulance |
| VanMail | vehicle_van_mail.txt | 2 | Mail van |
| VanSeats | vehicle_van_seats.txt | 6 | Passenger van |
| VanSeatsCreature | vehicle_van_seats_creature.txt | 6 | Creature paint |
| VanSeatsLadyDelighter | vehicle_van_seats_ladydelighter.txt | 6 | Custom paint |
| VanSeatsMural | vehicle_van_seats_mural.txt | 6 | Mural paint |
| VanSeatsPrison | vehicle_van_seats_prison.txt | 6 | Prison transport |
| VanSeatsSpace | vehicle_van_seats_space.txt | 6 | Space paint |
| VanSeatsTrippy | vehicle_van_seats_trippy.txt | 6 | Psychedelic paint |
| VanSeatsValkyrie | vehicle_van_seats_valkyrie.txt | 6 | Valkyrie paint |

### Step Vans & Service Vehicles
| Script Name | File | Seats | Notes |
|-|-|-|-|
| StepVan | vehicle_stepvan.txt | 2 | Box truck |
| StepVanMail | vehicle_stepvan_mail.txt | 2 | Mail truck |

Plus ~20 profession step vans (branded liveries): Airport Catering, Blacksmith, Butchers, Cereal, Citr8, CompleteRepairShop, Florist, GenuineBeer, Glass, Heralds, HuangsLaundry, Jorgensen, KentuckyLumber, LouisvilleMotorShop, MarineBites, Masonry, Mechanic, MobileLibrary, Plonkies, Propane, RandisPlants, Scarlet, SmartKut, SoutheasternHosp, SoutheasternPaint, USL, Zippee

### SUV & Offroad
| Script Name | File | Seats | Notes |
|-|-|-|-|
| SUV | vehicle_suv.txt | 4 | Sport utility vehicle |
| Offroad | vehicle_offroad.txt | 2 | Off-road vehicle |

### Trailers
| Script Name | File | Notes |
|-|-|-|
| Trailer | vehicle_trailer.txt | Utility trailer, 2 wheels |
| TrailerAdvert | vehicle_trailer_advert.txt | Advertising trailer |
| TrailerCover | vehicle_trailer_cover.txt | Covered trailer |
| TrailerHorsebox | vehicle_trailer_horsebox.txt | Horse transport |
| TrailerLivestock | vehicle_trailer_livestock.txt | Livestock transport |

### Burnt & Smashed (Non-Driveable)
Located in `burntAndSmashedVehicles/`. Generated for most base vehicles. Used as world decoration and obstacles. Not player-driveable.

### Regional Police Variants
Located in `regionalPoliceVehicles/`. Model overrides for police cars per map region (e.g. Westpoint).

### Profession Vehicles (Branded)
Located in `professionVehicles/` and `professionVehicles_General/`. Mostly step vans and pickup vans with company liveries for fossoil, carpenter, etc.

## 6. Part Types Reference

### Standard Parts (from templates)
| Part ID Pattern | Category | Notes |
|-|-|-|
| Engine | engine | Core drivetrain, mechanicRequireKey |
| Battery | engine | Power source |
| GasTank | - | Fuel container |
| Muffler | - | Exhaust, affects loudness |
| EngineDoor | - | Hood/bonnet |
| Heater | engine | Cabin heating |
| PassengerCompartment | nodisplay | Temperature system |
| Radio | - | Entertainment/emergency radio |
| GloveBox | - | Small storage |
| TruckBed / TrailerTrunk | - | Main cargo container |
| TrunkDoor | - | Boot/trunk lid |
| SeatFrontLeft/Right | - | Front seats |
| SeatRearLeft/Right | - | Rear seats (4-seat vehicles) |
| DoorFrontLeft/Right | - | Front doors |
| DoorRearLeft/Right | - | Rear doors |
| DoorRear | - | Van/SUV rear door |
| WindowFrontLeft/Right | - | Front windows |
| WindowRearLeft/Right | - | Rear windows |
| Windshield | - | Front windshield |
| WindshieldRear | - | Rear windshield |
| TireFrontLeft/Right | tire | Front tires |
| TireRearLeft/Right | tire | Rear tires |
| BrakeFrontLeft/Right | - | Front brakes |
| BrakeRearLeft/Right | - | Rear brakes |
| SuspensionFrontLeft/Right | - | Front suspension |
| SuspensionRearLeft/Right | - | Rear suspension |
| HeadlightLeft/Right | - | Front lights |
| Lightbar | - | Emergency lights (police/fire) |

### Install/Uninstall Table Fields
| Field | Notes |
|-|-|
| items | Required tools (type, count, keep, equip, tags) |
| time | Ticks to complete |
| skills | Required skill (e.g. "Mechanics:4") |
| recipes | Required recipe book |
| test | Lua test function |
| complete | Lua completion callback |
| requireInstalled | Parts that must be present |
| requireUninstalled | Parts that must be absent |

### Part Categories
| Category | Display Behavior |
|-|-|
| engine | Shown in engine section |
| tire | Shown in tire section |
| nodisplay | Hidden from mechanic UI |
| (none) | Default display |

## 7. Mechanical Stats Ranges

Gathered from reading vehicle definitions across all base vehicle types.

### Engine Power & Speed
| Vehicle | mass | engineForce | maxSpeed | wheelFriction |
|-|-|-|-|-|
| Trailer | 200 | 3600 | 70 | 4.0 |
| CarSmall | ~600 | ~3000 | ~70 | ~1.6 |
| CarNormal | ~700 | ~3500 | ~80 | ~1.6 |
| PickUpTruck | ~800 | ~3600 | ~70 | ~1.6 |
| Van | 816 | 3700 | 65 | 1.4 |
| SUV | ~900 | ~4000 | ~80 | ~1.6 |
| SportsCar | 800 | 5700 | 120 | 1.8 |
| StepVan | ~900 | ~3200 | ~55 | ~1.4 |

### Speed Tiers
| Tier | maxSpeed | Vehicles |
|-|-|-|
| Slow | 50-65 | StepVan, Van |
| Normal | 65-85 | PickUp, CarNormal, SUV, Offroad |
| Fast | 85-120 | SportsCar, Racecar, ModernEZ |

### Suspension Ranges
| Param | Min | Max | Notes |
|-|-|-|-|
| suspensionStiffness | 20 | 50 | Low=soft, High=sport |
| suspensionDamping | 2.3 | 3.4 | |
| suspensionCompression | 2.83 | 4.4 | |
| suspensionRestLength | 0.2 | 0.6 | |
| maxSuspensionTravelCm | 10 | 500 | Trailers/vans = low |

### Durability Ranges
| Param | Min | Max | Notes |
|-|-|-|-|
| frontEndHealth | 100 | 150 | Larger vehicles = 150 |
| rearEndHealth | 100 | 150 | |
| engineQuality | 60 | 100 | Trailers low, sports high |
| engineLoudness | 55 | 100 | Trailers quiet |

### Storage Capacity (from part container definitions)
| Vehicle Type | Trunk Capacity | Notes |
|-|-|-|
| SportsCar | SmallTrunk item | Smallest |
| CarSmall | ~40-60 | |
| CarNormal | ~60-80 | |
| Van | 130 | Largest non-trailer |
| Trailer | 80-100 | Condition-scaled |
| StepVan | ~100 | Large box truck |

### Mechanic Types
| mechanicType | Vehicles | Skill Tier |
|-|-|-|
| 1 | Trailers, basic | Standard Mechanics |
| 2 | Vans, trucks, normal cars | Intermediate Mechanics |
| 3 | Sports cars, modern cars | Advanced Mechanics |

## 8. Annotated Example

Complete SportsCar definition with annotations:

```
module Base
{
    vehicle SportsCar
    {
        # --- Identity ---
        mechanicType = 3,                    # Advanced Mechanics required
        offRoadEfficiency = 0.8,             # 80% speed off-road
        engineRepairLevel = 6,               # Mechanics 6 to repair engine
        playerDamageProtection = 0.8,        # 80% crash damage to driver
        engineRPMType = firebird,            # Sound profile
        specialKeyRing = Base.KeyRing_Clover;Base.KeyRing_EagleFlag;...,
        specialKeyRingChance = 40,

        # --- Model ---
        model
        {
            file = Vehicles_SportsCar,       # 3D model asset
            scale = 1.82,                    # Standard B42 scale
            offset = 0.0 0.2473 0.0,        # Vertical offset
        }

        # --- Skin (paint job) ---
        skin
        {
            texture = Vehicles/vehicle_sportscarshell,
        }

        # --- Textures ---
        textureMask = Vehicles/vehicle_sportscar_mask,      # Color mask
        textureLights = Vehicles/vehicle_sportscar_lights,
        textureDamage1Overlay = Vehicles/Veh_Blood_Mask,     # Shared blood
        textureDamage2Overlay = Vehicles/Veh_Blood_Hvy,
        textureDamage1Shell = Vehicles/Veh_Damage1,          # Shared damage
        textureDamage2Shell = Vehicles/Veh_Damage2,
        textureRust = Vehicles/Veh_Rust,

        # --- Collision Box ---
        extents = 0.7802 0.5055 2.0549,     # Half-size: ~1.56m wide, 1.01m tall, 4.11m long
        mass = 800,                          # 800 kg
        physicsChassisShape = 0.7802 0.5055 2.0549,
        centerOfMassOffset = 0.0 0.2473 0.0,
        shadowExtents = 0.7802 2.0549,
        shadowOffset = 0.0 0.0,

        # --- Performance ---
        engineForce = 5700,                  # Highest of any base vehicle
        engineLoudness = 90,
        engineQuality = 90,
        maxSpeed = 120.0,                    # Fastest base vehicle
        gearRatioCount = 5,                  # 5-speed manual
        gearRatioR = 3.5,
        gearRatio1 = 4.11,                  # Low gear (high torque)
        gearRatio2 = 2.5,
        gearRatio3 = 1.65,
        gearRatio4 = 1.25,
        gearRatio5 = 0.6,                   # Overdrive

        # --- Handling ---
        stoppingMovementForce = 2.0,
        rollInfluence = 0.7,                 # Good stability
        steeringIncrement = 0.04,
        steeringClamp = 0.3,                # Tight steering angle
        suspensionStiffness = 50.0,          # Very stiff (sport)
        suspensionCompression = 4.1,
        suspensionDamping = 3.4,
        maxSuspensionTravelCm = 20.0,        # Low travel (sporty)
        suspensionRestLength = 0.2,           # Low ride height
        wheelFriction = 1.8,                  # High grip

        # --- Health ---
        frontEndHealth = 150,
        rearEndHealth = 150,
        seats = 2,                            # 2-seater

        # --- Wheels (4 corners) ---
        wheel FrontLeft  { front = true,  offset = 0.3242 -0.2143 0.5879, radius = 0.15, width = 0.2, }
        wheel FrontRight { front = true,  offset = -0.3242 -0.2143 0.5879, radius = 0.15, width = 0.2, }
        wheel RearLeft   { front = false, offset = 0.3352 -0.2143 -0.5659, radius = 0.15, width = 0.2, }
        wheel RearRight  { front = false, offset = -0.3352 -0.2143 -0.5659, radius = 0.15, width = 0.2, }

        # --- Templates (bulk part definitions) ---
        template = PassengerSeat2,            # 2-seat passenger config
        template = TrunkDoor,
        template = Trunk/part/TruckBed,       # Specific part from Trunk template
        template = Seat/part/SeatFrontLeft,
        template = Seat/part/SeatFrontRight,
        template = GloveBox,
        template = GasTank,
        template = Battery,
        template = Engine,
        template = Muffler,
        template = EngineDoor,
        template = Heater,
        template = Windshield/part/Windshield,
        template = Windshield/part/WindshieldRear,
        template = Window/part/WindowFrontLeft,
        template = Window/part/WindowFrontRight,
        template = Door/part/DoorFrontLeft,
        template = Door/part/DoorFrontRight,
        template = Tire,
        template = Brake,
        template = Suspension,
        template = Radio,
        template = Headlight,
        template = CarSportsCollision,        # Vehicle-specific collision

        # --- Passenger positions ---
        passenger FrontLeft
        {
            position inside  { offset = 0.1484 -0.1209 -0.1703, rotate = 0.0 0.0 0.0, }
            position outside { offset = 0.5549 -0.3022 -0.1429, rotate = 0.0 0.0 0.0, area = SeatFrontLeft, }
        }
        passenger FrontRight
        {
            position inside  { offset = -0.1484 -0.1209 -0.1703, rotate = 0.0 0.0 0.0, }
            position outside { offset = -0.5549 -0.3022 -0.1429, rotate = 0.0 0.0 0.0, area = SeatFrontRight, }
        }

        # --- Interaction areas ---
        area Engine         { xywh = 0.0 1.2637 0.7912 0.4725, }
        area TruckBed       { xywh = 0.0 -1.2637 0.7912 0.4725, }
        area SeatFrontLeft  { xywh = 0.6264 -0.1429 0.4725 0.4725, }
        area SeatFrontRight { xywh = -0.6264 -0.1429 0.4725 0.4725, }
        area GasTank        { xywh = -0.0008 -1.2637 0.4725 0.4725, }
        area TireFrontLeft  { xywh = 0.6264 0.5989 0.4725 0.4725, }
        area TireFrontRight { xywh = -0.6264 0.5989 0.4725 0.4725, }
        area TireRearLeft   { xywh = 0.6264 -0.5659 0.4725 0.4725, }
        area TireRearRight  { xywh = -0.6264 -0.5659 0.4725 0.4725, }

        # --- Part overrides (extend template defaults) ---
        part TruckBed       { itemType = Base.SmallTrunk, }   # Sports car = small trunk
        part Seat*           { table install { skills = Mechanics:2, recipes = Advanced Mechanics, } ... }
        part GasTank         { table install { skills = Mechanics:7, recipes = Advanced Mechanics, } ... }
        part Window*         { anim Open { sound = VehicleWindowElectricOpen, } ... }  # Power windows
        part Brake*          { table install { skills = Mechanics:7, ... } }
        part Suspension*     { table install { skills = Mechanics:7, ... } }

        # --- Sound template ---
        template! = SoundsSportsCar,          # Injects full sound block

        # --- Tow attachments ---
        attachment trailer      { offset = 0.0 -0.2747 -1.1264, rotate = 0.0 0.0 0.0, zoffset = -1.0, }
        attachment trailerfront { offset = 0.0 -0.2747 1.0769,  rotate = 0.0 0.0 0.0, zoffset = 1.0, }
    }
}
```
