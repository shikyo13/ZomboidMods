# Weather & Climate System - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | ClimateManager Overview | 19-61 |
| 2 | Climate Float/Color/Bool System | 62-114 |
| 3 | Temperature Model | 115-174 |
| 4 | WeatherPeriod & Stages | 175-233 |
| 5 | Seasonal Weather Patterns | 234-267 |
| 6 | ThunderStorm System | 268-319 |
| 7 | Erosion System | 320-371 |
| 8 | ErosionSeason & Seasonal Cycles | 372-426 |
| 9 | Lua Events & Modding API | 427-455 |

---

## 1. ClimateManager Overview
`zombie.iso.weather.ClimateManager` - [pub] @UsedFromLua - Singleton

Central controller for all weather simulation. Drives temperature, wind, rain, fog, snow, and lighting.

### Key Fields
| Field | Type | Access | Notes |
|-|-|-|-|
| instance | ClimateManager | [static] | `getInstance()` |
| weatherPeriod | WeatherPeriod | [priv] final | Active weather event |
| thunderStorm | ThunderStorm | [priv] final | Lightning subsystem |
| season | ErosionSeason | [priv] | Current season ref from ErosionMain |
| climateForecaster | ClimateForecaster | [priv] final | Weather forecasting |
| climateHistory | ClimateHistory | [priv] final | Historical weather data |
| airMass | float | [priv] | Current air mass value (0-1) |
| airMassDaily | float | [priv] | Daily air mass average |
| airMassTemperature | float | [priv] | Temperature from air mass |
| baseTemperature | float | [priv] | Base temp before modifiers |
| snowFall | float | [priv] | Current snowfall amount |
| snowStrength | float | [priv] | Snow intensity |
| windPower | float | [priv] | Raw wind power |
| dayFogStrength | float | [priv] | Fog strength for the day |
| currentFront | AirFront | [priv] final | Active weather front |

### Constants
| Constant | Value | Notes |
|-|-|-|
| FRONT_COLD | -1 | Cold front type |
| FRONT_STATIONARY | 0 | No front movement |
| FRONT_WARM | 1 | Warm front type |
| MAX_WINDSPEED_KPH | 120.0 | Maximum wind in km/h |
| MAX_WINDSPEED_MPH | 74.5645 | Maximum wind in mph |
| AVG_FAV_AIR_TEMPERATURE | 22.0 | Comfortable room temp (C) |

### Static Flags
| Flag | Type | Purpose |
|-|-|-|
| winterIsComing | boolean | [static] "Winter is Coming" game mode active |
| theDescendingFog | boolean | [static] Heavy fog event |
| aStormIsComing | boolean | [static] Incoming storm |

---

## 2. Climate Float/Color/Bool System
ClimateManager exposes 13 float parameters, 2 color parameters, and 1 boolean via indexed arrays. These are the primary values mods can override.

### ClimateFloat IDs (0-12)
| ID | Constant | Field | Range | Purpose |
|-|-|-|-|-|
| 0 | FLOAT_DESATURATION | desaturation | 0-1 | Color desaturation |
| 1 | FLOAT_GLOBAL_LIGHT_INTENSITY | globalLightIntensity | 0-1 | Overall light brightness |
| 2 | FLOAT_NIGHT_STRENGTH | nightStrength | 0-1 | Night darkness factor |
| 3 | FLOAT_PRECIPITATION_INTENSITY | precipitationIntensity | 0-1 | Rain/snow amount |
| 4 | FLOAT_TEMPERATURE | temperature | -80 to 80 | Temperature in Celsius |
| 5 | FLOAT_FOG_INTENSITY | fogIntensity | 0-1 | Fog density |
| 6 | FLOAT_WIND_INTENSITY | windIntensity | 0-1 | Wind strength (normalized) |
| 7 | FLOAT_WIND_ANGLE_INTENSITY | windAngleIntensity | -1 to 1 | Wind direction modifier |
| 8 | FLOAT_CLOUD_INTENSITY | cloudIntensity | 0-1 | Cloud cover |
| 9 | FLOAT_AMBIENT | ambient | 0-1 | Ambient light level |
| 10 | FLOAT_VIEW_DISTANCE | viewDistance | 0-100 | Visibility range |
| 11 | FLOAT_DAYLIGHT_STRENGTH | dayLightStrength | 0-1 | Sunlight intensity |
| 12 | FLOAT_HUMIDITY | humidity | 0-1 | Air humidity |

### ClimateColor IDs (0-1)
| ID | Constant | Field | Purpose |
|-|-|-|-|
| 0 | COLOR_GLOBAL_LIGHT | globalLight | Scene-wide light color (ext/int) |
| 1 | COLOR_NEW_FOG | colorNewFog | Fog tint color (ext/int) |

### ClimateBool IDs (0)
| ID | Constant | Field | Purpose |
|-|-|-|-|
| 0 | BOOL_IS_SNOW | precipitationIsSnow | true = snow, false = rain |

### Getter/Setter Methods [pub]
| Method | Returns | Notes |
|-|-|-|
| `getClimateFloat(int id)` | ClimateFloat | Access any float by ID |
| `getClimateColor(int id)` | ClimateColor | Access any color by ID |
| `getClimateBool(int id)` | ClimateBool | Access any bool by ID |
| `getTemperature()` | float | Current temp (C), finalValue of ID 4 |
| `getPrecipitationIntensity()` | float | Rain/snow intensity |
| `getFogIntensity()` | float | Fog density |
| `getWindIntensity()` | float | Normalized wind (0-1) |
| `getWindspeedKph()` | float | Wind speed in km/h |
| `getWindAngleDegrees()` | float | Wind direction in degrees |
| `getWindAngleRadians()` | float | Wind direction in radians |
| `getCloudIntensity()` | float | Cloud cover (0-1) |
| `getHumidity()` | float | Humidity (0-1) |
| `getSnowStrength()` | float | Snow accumulation strength |
| `getPrecipitationIsSnow()` | boolean | Whether precipitation is snow |
| `isRaining()` | boolean | precipitationIntensity > 0 && !isSnow |
| `isSnowing()` | boolean | precipitationIntensity > 0 && isSnow |

---

## 3. Temperature Model
`zombie.iso.weather.Temperature` - [pub] @UsedFromLua - Static utility class

### Body Temperature Constants
| Constant | Value (C) | Notes |
|-|-|-|
| homeostasisDefault | 37.0 | Normal body core temp |
| FavorableNakedTemp | 27.0 | Comfortable temp for naked character |
| FavorableRoomTemp | 22.0 | Standard indoor comfort temp |
| neutralZone | 27.0 | No thermoregulation needed |
| skinCelciusMin | 20.0 | Min survivable skin temp |
| skinCelciusFavorable | 33.0 | Ideal skin temp |
| skinCelciusMax | 42.0 | Max survivable skin temp |

### Hypothermia Thresholds (core body temp, descending severity)
| Stage | Temp (C) | Effect |
|-|-|-|
| Hypothermia_1 | 36.5 | Mild - shivering begins |
| Hypothermia_2 | 35.0 | Moderate - confusion |
| Hypothermia_3 | 30.0 | Severe - loss of shivering |
| Hypothermia_4 | 25.0 | Critical - cardiac risk |

### Hyperthermia Thresholds (core body temp, ascending severity)
| Stage | Temp (C) | Effect |
|-|-|-|
| Hyperthermia_1 | 37.5 | Mild - sweating |
| Hyperthermia_2 | 39.0 | Moderate - heat exhaustion |
| Hyperthermia_3 | 40.0 | Severe - heat stroke risk |
| Hyperthermia_4 | 41.0 | Critical - organ damage |

### Clothing Insulation
| Constant | Value | Formula |
|-|-|-|
| TrueInsulationMultiplier | 2.0 | `insulation * 2.0 + 0.5 * insulation^3` |
| TrueWindresistMultiplier | 1.0 | `windresist * 1.0 + 0.5 * windresist^2` |

### Wind Chill Formula
`WindchillCelsiusKph(t, v)`: 13.12 + 0.6215*t - 11.37*v^0.16 + 0.3965*t*v^0.16 (standard meteorological formula, result capped at air temp)

### Indoor Temperature Model
`getAirTemperatureForSquare(square, vehicle, doWindChill)`:
- **Indoors + power ON**: temp = 22.0C (thermostat-controlled)
- **Indoors + power OFF, cold**: temp += (22-temp) * (0.4 + 0.2*daylight) - partial insulation
- **Upper floors**: slightly less insulation (0.85x modifier)
- **Outdoors**: wind chill applied if `doWindChill = true`
- **Vehicles**: adds `vehicle.getInsideTemperature()` (heater/AC)
- **Heat sources**: campfires, stoves override if hotter than ambient

### Key Methods [pub] [static]
| Method | Purpose |
|-|-|
| `CelsiusToFahrenheit(float)` | C to F conversion |
| `FahrenheitToCelsius(float)` | F to C conversion |
| `getWindChillAmountForPlayer(IsoPlayer)` | Wind chill delta (0 if indoors/vehicle) |
| `getTrueInsulationValue(float)` | Actual insulation from clothing stat |
| `getTrueWindresistanceValue(float)` | Actual wind resistance from clothing stat |
| `getTemperatureString(float)` | Formatted string with unit postfix |

---

## 4. WeatherPeriod & Stages
`zombie.iso.weather.WeatherPeriod` - [pub] @UsedFromLua

Manages a complete weather event lifecycle with multiple sequential stages.

### Weather Stage IDs
| ID | Constant | Description |
|-|-|-|
| 0 | STAGE_START | Weather event beginning |
| 1 | STAGE_SHOWERS | Light rain showers |
| 2 | STAGE_HEAVY_PRECIP | Heavy rain/snow |
| 3 | STAGE_STORM | Full thunderstorm |
| 4 | STAGE_CLEARING | Weather clearing up |
| 5 | STAGE_MODERATE | Moderate sustained rain |
| 6 | STAGE_DRIZZLE | Light drizzle |
| 7 | STAGE_BLIZZARD | Blizzard (heavy snow + wind) |
| 8 | STAGE_TROPICAL_STORM | Tropical storm |
| 9 | STAGE_INTERMEZZO | Pause between stages |
| 10 | STAGE_MODDED | Custom modded stage |
| 11 | STAGE_KATEBOB_STORM | Story-driven "Kate & Bob" storm |
| 12 | STAGE_MAX | Sentinel (not a real stage) |

### Key Fields
| Field | Type | Access | Purpose |
|-|-|-|-|
| currentStage | WeatherStage | [priv] | Active stage |
| weatherStages | ArrayList | [priv] | Ordered stage sequence |
| isThunderStorm | boolean | [priv] | Storm has thunder |
| isTropicalStorm | boolean | [priv] | Is tropical storm |
| isBlizzard | boolean | [priv] | Is blizzard |
| currentStrength | float | [priv] | Overall weather strength (0-1) |
| rainThreshold | float | [priv] | Min precip for "rain" |
| temperatureInfluence | float | [priv] | Max 7.0 temp change from weather |
| windAngleDirMod | float | [priv] | Wind direction modifier |
| precipitationFinal | float | [priv] | Final computed precipitation |
| frontCache | AirFront | [priv] | Cached front data |

### Key Methods [pub]
| Method | Returns | Notes |
|-|-|-|
| `isRunning()` | boolean | Weather event active |
| `getDuration()` | double | Total hours |
| `getCurrentStageID()` | int | Stage constant |
| `getTotalProgress()` | float | 0-1 through entire event |
| `getStageProgress()` | float | 0-1 through current stage |
| `hasTropical()` | boolean | Contains tropical stage |
| `hasStorm()` | boolean | Contains storm stage |
| `hasBlizzard()` | boolean | Contains blizzard stage |
| `getWeatherStages()` | ArrayList | All stages in order |
| `stopWeatherPeriod()` | void | Force-stop, fires OnWeatherPeriodStop |

### Modded Weather API [pub]
| Method | Purpose |
|-|-|
| `startCreateModdedPeriod(warmFront, strength, angle)` | Begin creating custom weather |
| `endCreateModdedPeriod()` | Finalize and start custom weather |

---

## 5. Seasonal Weather Patterns
Weather pattern generation varies by season. From `createWeatherPattern()`:

### Storm Chances by Season
| Season | Storm % | Tropical % | Blizzard % | Rain Time Multi |
|-|-|-|-|-|
| Winter (5) | 10 | 0 | 25-95 (temp dependent) | 1.0 |
| Spring (1) | 75 | 10 | 0 | 1.25 |
| Early Summer (2) | 60 | 55 | 0 | 1.0 |
| Late Summer (3) | 75 | 80 | 0 | 1.15 |
| Autumn (4) | 100 | 25 | 0 | 1.35 |

### Blizzard Temperature Scaling (Winter)
- Below 5.5C: blizzardChance = (5.5 - temp) * 3.0 + 25, capped at 95
- Below 2.5C: +55% bonus
- Below 0.0C: +75% bonus
- "Winter is Coming" mode: 75-100% (strength dependent)

### Front Strength Thresholds
- Strength > 0.75: Tropical or Blizzard can trigger
- Strength > 0.5: Storm can trigger
- Minimum threshold: 0.1 (below = no weather event)

### Cloud Colors by Season
| Season | Primary Color | Secondary |
|-|-|-|
| Winter | Purplish (45%) | Blueish (55%) |
| Spring | Greenish (75%) | Blueish (25%) |
| Early Summer | Greenish (25%) | Reddish (75%) |
| Late Summer | Reddish (100%) | - |
| Autumn | Reddish/Purplish/Blueish | Weighted split |

---

## 6. ThunderStorm System
`zombie.iso.weather.ThunderStorm` - [pub] @UsedFromLua

### Architecture
- 3 concurrent ThunderCloud slots (moving cloud entities)
- 30 ThunderEvent slots (individual lightning/thunder)
- 4 PlayerLightningInfo slots (per-player visual effects)

### ThunderCloud Properties
| Field | Type | Purpose |
|-|-|-|
| currentX/Y | int | Current map position |
| startX/Y, endX/Y | int | Travel path endpoints |
| strength | float | 0-1 intensity |
| radius | float | Affect radius, max 20000 |
| eventFrequency | float | How often events fire |
| thunderRatio | float | 0-1 chance of thunder vs rumble |
| duration | double | Lifetime in game hours |

### Thunder Event Flow
1. Cloud's `suspendTimer` expires
2. Next event delay: `3.5 - 3.0*strength` to `24.0 - 20.0*strength` seconds
3. Strike radius chosen: 60% = 1/3 cloud radius, 30% = 3/4, 10% = full
4. Roll thunderRatio: success = thunder strike, fail = distant rumble
5. `triggerThunderEvent(x, y, doStrike, doLightning, doRumble)`

### Lightning Visual System
- Distance-based intensity: `1.0 - distance/7500.0` (max 7500 tile range)
- Duration: `20 + 80 * lightningStrength` ticks
- Modifies: dayLightStrength, ambient, desaturation, globalLight
- Flash fades via lerp from white to current scene lighting

### Sound System
- Sound delay = `distance / 300 * 60` ticks (simulates speed of sound)
- Thunder: `GameSounds.getSound("Thunder")` - 3D positioned at strike (z=100)
- Rumble: `GameSounds.getSound("RumbleThunder")` - 3D positioned at strike (z=200)
- Max audible distance: 10000 tiles

### Key Methods [pub]
| Method | Purpose |
|-|-|
| `startThunderCloud(str, angle, radius, freq, ratio, dur, targetPlayer)` | Spawn cloud |
| `triggerThunderEvent(x, y, doStrike, doLightning, doRumble)` | Manual event |
| `stopAllClouds()` | Kill all active clouds |
| `HasActiveThunderClouds()` | Any clouds active |
| `getClouds()` | ArrayList of ThunderCloud |

### Lua Event
`OnThunderEvent(x, y, doStrike, doLightning, doRumble)` - fired for every thunder event

---

## 7. Erosion System
`zombie.erosion.ErosionMain` - [pub] @UsedFromLua - Singleton

Manages world degradation over time: vegetation growth, structure decay, cracks, vines.

### Core Fields
| Field | Type | Purpose |
|-|-|-|
| cfg | ErosionConfig | Persistent configuration |
| eTicks | int | Erosion tick counter (progress metric) |
| ticks | int | Raw tick counter |
| epoch | int | Day counter (increments per day change) |
| tickUnit | int | 144 - ticks per erosion unit (default) |
| noiseMain | Noise2D | Primary terrain noise |
| noiseMoisture | Noise2D | Moisture distribution |
| noiseMinerals | Noise2D | Mineral distribution |
| noiseKudzu | Noise2D | Kudzu growth pattern |
| snowFrac | int | Current snow coverage fraction |

### Erosion Tick Calculation
- `erosionDays` sandbox option controls speed
- If erosionDays < 0: eTicks frozen at 0 (disabled)
- If erosionDays > 0: `eTicks = ticks / 144 / erosionDays * 100`
- If erosionDays == 0: `eTicks++` every 144 ticks (default rate)

### Erosion Categories
| Class | Effect |
|-|-|
| NatureTrees | Tree growth and spread |
| NatureBush | Bush growth |
| NaturePlants | Grass, flowers, weeds |
| Flowerbed | Garden bed overgrowth |
| StreetCracks | Road and pavement cracking |
| WallCracks | Building wall deterioration |
| WallVines | Vine growth on structures |
| NatureGeneric | Misc natural encroachment |

### Chunk Initialization
Each chunk receives noise-based soil quality from moisture + minerals lookup:
- Moisture: `noiseMoisture.layeredNoise(x/5, y/5)` - 10 levels
- Minerals: `noiseMinerals.layeredNoise(x/5, y/5)` - 10 levels
- Soil type: 10x10 lookup table `soilTable[moisture][minerals]`

### ErosionConfig Persistence
Saved to `erosion.ini` in save folder:
- `seeds.*` - 12 noise seeds (main, moisture, minerals, kudzu x3 each)
- `time.tickunit`, `time.ticks`, `time.eticks`, `time.epoch`
- `season.*` - latitude, temp range, monthly rain averages
- `debug.*` - debug flags

---

## 8. ErosionSeason & Seasonal Cycles
`zombie.erosion.season.ErosionSeason` - [pub] @UsedFromLua

### Season IDs
| ID | Constant | Name |
|-|-|-|
| 0 | SEASON_DEFAULT | Default (no specific season) |
| 1 | SEASON_SPRING | Spring |
| 2 | SEASON_SUMMER | Early Summer |
| 3 | SEASON_SUMMER2 | Late Summer |
| 4 | SEASON_AUTUMN | Autumn |
| 5 | SEASON_WINTER | Winter |

### Climate Parameters
| Field | Default | Purpose |
|-|-|-|
| lat | 38 | Latitude (Kentucky ~38N) |
| tempMax | 25 | Summer peak temp (C) |
| tempMin | 0 | Winter low temp (C) |
| tempDiff | 7 | Daily temp variation |
| highNoon | 12.5 | Solar noon hour |
| seasonLag | 31 | Days between solstice and temp peak |

### Daylight Calculation
Uses real astronomical formula based on latitude:
- Summer solstice daylight: `2 * acos(-tan(lat) * tan(23.44)) / 15` hours
- Winter solstice daylight: `2 * acos(tan(lat) * tan(23.44)) / 15` hours
- At lat 38: approximately 14.5h summer, 9.8h winter

### Noise-Based Weather Variation
3-layer Perlin noise generates daily variation:
- Layer 1: seed A, scale 8, weight 2
- Layer 2: seed B, scale 6, weight 4
- Layer 3: seed C, scale 4, weight 6

### Monthly Rain Configuration
Set via `setRain(jan..dec)` - float values per month. `rainYearAverage` computed as yearly projected rain days.

### Key Methods [pub]
| Method | Returns | Purpose |
|-|-|-|
| `getSeason()` | int | Current season ID |
| `getSeasonName()` | String | English name |
| `getDayMeanTemperature()` | float | Mean temp for current day (C) |
| `getDayTemperature()` | float | Actual temp for current day |
| `getDusk()` | float | Dusk hour (e.g. 19.5) |
| `getDawn()` | float | Dawn hour (e.g. 6.0) |
| `getDaylight()` | float | Hours of daylight |
| `getSeasonProgression()` | float | 0-1 through current season |
| `getSeasonStrength()` | float | Season intensity |
| `isRainDay()` | boolean | Scheduled rain today |
| `isThunderDay()` | boolean | Thunder scheduled today |

---

## 9. Lua Events & Modding API

### Climate Lua Events
| Event | Args | When |
|-|-|-|
| `OnClimateManagerInit` | ClimateManager | Climate system initialized |
| `OnWeatherPeriodStart` | WeatherPeriod | Weather event begins |
| `OnWeatherPeriodStop` | WeatherPeriod | Weather event ends |
| `OnThunderEvent` | x, y, doStrike, doLightning, doRumble | Lightning/thunder event |

### Network Packet Types
| Byte | Constant | Purpose |
|-|-|-|
| 0 | PacketUpdateClimateVars | Sync climate float/color/bool values |
| 1 | PacketWeatherUpdate | Sync weather period state |
| 2 | PacketThunderEvent | Broadcast thunder event |
| 3 | PacketFlare | Signal flare event |
| 4 | PacketAdminVarsUpdate | Admin override sync |

### Simulation Control [pub]
| Method | Purpose |
|-|-|
| `setEnabledSimulation(bool)` | Enable/disable weather sim (SP only) |
| `setEnabledFxUpdate(bool)` | Enable/disable visual FX (SP only) |
| `setEnabledWeatherGeneration(bool)` | Enable/disable new weather generation |
| `stopWeatherAndThunder()` | Immediately halt all weather |

### Key Lua-Accessible Getters (via @UsedFromLua)
All ClimateManager getters for temperature, wind, fog, rain, snow, season, daylight, and time-of-day values are Lua-callable. Use `ClimateManager.getInstance()` in Lua, then call any getter documented above.
