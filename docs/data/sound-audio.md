# Sound & Audio System - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture Overview | 19-35 |
| 2 | GameSound & GameSoundClip | 36-109 |
| 3 | BaseSoundEmitter | 110-162 |
| 4 | BaseSoundBank | 163-177 |
| 5 | WorldSoundManager | 178-231 |
| 6 | WorldSound & Zombie Attraction | 232-269 |
| 7 | ObjectAmbientEmitters | 270-296 |
| 8 | Music Intensity System | 297-337 |
| 9 | Lua API & Modding | 338-379 |

---

## 1. Architecture Overview
PZ audio is built on FMOD Studio. The system has two distinct layers:

**Audio layer** (`zombie.audio.*`) - Actual sound playback via FMOD:
- `GameSound` / `GameSoundClip` - Sound definitions and clips
- `BaseSoundEmitter` - Abstract 3D sound playback interface
- `BaseSoundBank` - Voice and footstep sound storage
- `ObjectAmbientEmitters` - Persistent environmental sounds

**Game logic layer** (`zombie.WorldSoundManager`) - Game events that attract zombies:
- `WorldSoundManager` / `WorldSound` - Logical sounds that affect AI
- These do NOT produce audible output directly, they alert zombies and NPCs

The two layers are independent. A gunshot creates both a `GameSound` (audible) and a `WorldSound` (zombie attraction). A stealth kill may create neither.

---

## 2. GameSound & GameSoundClip
`zombie.audio.GameSound` - [pub] @UsedFromLua

Represents a named sound definition loaded from sound scripts. Contains one or more clips.

### GameSound Fields
| Field | Type | Access | Default | Notes |
|-|-|-|-|-|
| name | String | [pub] | null | Sound identifier (e.g. "Thunder") |
| category | String | [pub] | "General" | Grouping category |
| loop | boolean | [pub] | false | Looping sound |
| is3d | boolean | [pub] | true | Positional audio |
| clips | ArrayList\<GameSoundClip\> | [pub] final | empty | All clips for this sound |
| userVolume | float | [priv] | 1.0 | Player-adjusted volume (0-2) |
| master | MasterVolume | [pub] | Primary | Volume bus routing |
| maxInstancesPerEmitter | int | [pub] | -1 | Instance limit (-1 = unlimited) |
| reloadEpoch | short | [pub] | 0 | Hot-reload tracking |

### MasterVolume Enum
| Value | Purpose |
|-|-|
| Primary | Main game sounds |
| Ambient | Environmental ambience |
| Music | Background music |
| VehicleEngine | Vehicle engine sounds |

### GameSound Methods [pub]
| Method | Returns | Notes |
|-|-|-|
| `getName()` | String | Sound identifier |
| `getCategory()` | String | Category name |
| `isLooped()` | boolean | Whether sound loops |
| `getRandomClip()` | GameSoundClip | Random clip from pool |
| `setUserVolume(float)` | void | Set gain 0-2 |
| `getUserVolume()` | float | Get user volume |
| `numClipsUsingParameter(String)` | int | Count clips with FMOD param |
| `reset()` | void | Clear all data for reload |

### GameSoundClip Fields
`zombie.audio.GameSoundClip` - [pub] @UsedFromLua

| Field | Type | Default | Notes |
|-|-|-|-|
| event | String | null | FMOD event path |
| eventDescription | FMOD_STUDIO_EVENT_DESCRIPTION | null | Resolved FMOD event |
| eventDescriptionMp | FMOD_STUDIO_EVENT_DESCRIPTION | null | MP variant |
| file | String | null | Direct file reference |
| volume | float | 1.0 | Base volume |
| pitch | float | 1.0 | Playback pitch |
| distanceMin | float | 10.0 | Min audible distance |
| distanceMax | float | 10.0 | Max audible distance |
| reverbMaxRange | float | 10.0 | Reverb distance |
| reverbFactor | float | 0.0 | Reverb amount |
| priority | int | 5 | FMOD priority (lower = more important) |

### Init Flags (bitmask)
| Flag | Value | Purpose |
|-|-|-|
| INIT_FLAG_DISTANCE_MIN | 1 | distanceMin was explicitly set |
| INIT_FLAG_DISTANCE_MAX | 2 | distanceMax was explicitly set |
| INIT_FLAG_STOP_IMMEDIATE | 4 | Stop without fade |

### GameSoundClip Methods [pub]
| Method | Returns | Notes |
|-|-|-|
| `getEffectiveVolume()` | float | `volume * gameSound.getUserVolume()` |
| `hasMinDistance()` | boolean | Flag check |
| `hasMaxDistance()` | boolean | Flag check |
| `isStopImmediate()` | boolean | Flag check |
| `hasSustainPoints()` | boolean | FMOD sustain point support |
| `checkReloaded()` | GameSoundClip | Handle hot-reload, return valid clip |

---

## 3. BaseSoundEmitter
`zombie.audio.BaseSoundEmitter` - [pub] abstract @UsedFromLua

Abstract interface for all sound playback in PZ. All methods return `long` sound handles.

### Playback Methods [pub] [abstract]
| Method | Signature | Notes |
|-|-|-|
| `playSound` | `(String name)` -> long | Play by name, returns handle |
| `playSound` | `(String, IsoGameCharacter)` -> long | Play attached to character |
| `playSound` | `(String, int x, int y, int z)` -> long | Play at world position |
| `playSound` | `(String, IsoGridSquare)` -> long | Play at grid square |
| `playSound` | `(String, IsoObject)` -> long | Play attached to object |
| `playSoundLooped` | `(String name)` -> long | Play looping sound |
| `playClip` | `(GameSoundClip, IsoObject)` -> long | Play specific clip |
| `playAmbientSound` | `(String name)` -> long | Play ambient sound |
| `playAmbientLoopedImpl` | `(String name)` -> long | Looped ambient |

### Control Methods [pub] [abstract]
| Method | Signature | Notes |
|-|-|-|
| `stopSound` | `(long handle)` -> int | Stop with fade |
| `stopSoundDelayRelease` | `(long handle)` -> int | Delayed stop |
| `stopSoundLocal` | `(long handle)` -> void | Stop local only |
| `stopSoundByName` | `(String name)` -> int | Stop all by name |
| `stopOrTriggerSound` | `(long handle)` -> void | Stop or trigger cue |
| `stopAll` | `()` -> void | Stop everything |
| `setVolume` | `(long, float)` -> void | Set instance volume |
| `setPitch` | `(long, float)` -> void | Set instance pitch |
| `setPos` | `(float x, float y, float z)` -> void | Update 3D position |
| `set3D` | `(long, boolean)` -> void | Toggle 3D mode |

### Parameter Methods [pub] [abstract]
| Method | Purpose |
|-|-|
| `setParameterValue(long, FMOD_PARAM_DESC, float)` | Set FMOD parameter |
| `setParameterValueByName(long, String, float)` | Set parameter by name |
| `isUsingParameter(long, String)` | Check if instance uses param |
| `setTimelinePosition(long, String)` | Jump to timeline marker |
| `triggerCue(long)` | Trigger sustain point cue |
| `hasSustainPoints(long)` | Check for sustain points |

### Query Methods [pub] [abstract]
| Method | Returns | Notes |
|-|-|-|
| `isPlaying(long)` | boolean | Check by handle |
| `isPlaying(String)` | boolean | Check by name |
| `isEmpty()` | boolean | No active sounds |
| `hasSoundsToStart()` | boolean | Pending sounds queued |
| `restart(long)` | boolean | Restart sound instance |

---

## 4. BaseSoundBank
`zombie.audio.BaseSoundBank` - [pub] abstract

Stores voice and footstep sound mappings. Singleton via `instance` field.

### Methods [pub] [abstract]
| Method | Signature | Purpose |
|-|-|-|
| `addVoice` | `(String id, String event, float vol)` | Register voice sound |
| `addFootstep` | `(String id, String walk, String run, String sneak, String sprint)` | Register footstep set |
| `getVoice` | `(String id)` -> FMODVoice | Retrieve voice |
| `getFootstep` | `(String id)` -> FMODFootstep | Retrieve footstep |

---

## 5. WorldSoundManager
`zombie.WorldSoundManager` - [pub] @UsedFromLua - Singleton

Manages "world sounds" - logical sound events that attract zombies, stress humans, and alert animals. These are NOT audible sounds, they are game mechanic events.

### Key Fields
| Field | Type | Access | Notes |
|-|-|-|-|
| instance | WorldSoundManager | [pub] [static] final | Singleton |
| soundList | ArrayList\<WorldSound\> | [pub] final | All active world sounds |
| freeSounds | Stack\<WorldSound\> | [priv] final | Object pool |

### addSound Overloads [pub]
The primary method signature:
```
addSound(Object source, int x, int y, int z, int radius, int volume,
         float zombieIgnoreDist, float stressMod,
         boolean sourceIsZombie, boolean doSend, boolean remote,
         boolean repeating, short flags)
```

Convenience overloads reduce params. The `flags` bitmask:
| Bit | Value | Flag |
|-|-|-|
| 0 | 1 | stressAnimals |
| 1 | 2 | stressHumans |
| 2 | 4 | stressZombies (default ON) |

### addSound Flow
1. Create WorldSound from pool
2. If not server: calculate `radiusMax` with hearing multiplier
3. Register sound in affected chunks (spatial partitioning)
4. Notify `ZombiePopulationManager.addWorldSound()`
5. If `doSend`: transmit to other clients/server
6. Returns WorldSound handle

### Hearing Multiplier Table
| Hearing Level | Multiplier | Sandbox Setting |
|-|-|-|
| 1 (Pinpoint) | 3.0x | Greatly increased range |
| 2 (Normal) | 1.0x | Default |
| 3 (Poor) | 0.45x | Reduced range |

Note: Zombie hearing also modifies: `getHearingMultiplier(zombie.hearing) * wornItemsMultiplier * weatherMultiplier`

### Sound Retrieval for Zombies [pub]
| Method | Purpose |
|-|-|
| `getSoundZomb(IsoZombie)` | Get zombie's target sound |
| `getSoundAnimal(IsoAnimal)` | Get animal's target sound |
| `getBiggestSoundZomb(x, y, z, ignoreSameType, zom)` | Loudest sound for zombie |

---

## 6. WorldSound & Zombie Attraction
`WorldSoundManager.WorldSound` - [pub] [static] inner class

### WorldSound Fields
| Field | Type | Default | Purpose |
|-|-|-|-|
| source | Object | null | What made the sound |
| x, y, z | int | 0 | World position |
| radius | int | 0 | Base attraction radius (tiles) |
| volume | int | 0 | Sound loudness for AI |
| life | int | 16 | Ticks until expired |
| stresshumans | boolean | false | Affects human NPCs |
| stressZombies | boolean | true | Attracts zombies |
| stressAnimals | boolean | false | Scares animals |
| zombieIgnoreDist | float | 0 | Radius around source zombies ignore |
| stressMod | float | 1.0 | Multiplier on stress effect |
| sourceIsZombie | boolean | false | Sound from zombie (zombies ignore) |
| sourceIsPlayer | boolean | false | Sound from player |
| sourceIsPlayerBase | boolean | false | From player-owned object |
| repeating | boolean | false | Persistent sound source |

### Player Base Sound Sources
Automatically flagged as `sourceIsPlayerBase`:
IsoGenerator, IsoJukebox, IsoTelevision, IsoRadio, IsoStove, IsoClothingWasher, IsoClothingDryer, IsoCombinationWasherDryer

### Zombie Sound Perception Formula
From `getBiggestSoundZomb()`:
1. Effective radius = `sound.radius * hearingMultiplier(zombie)`
2. Distance check: `dist <= effectiveRadius^2`
3. Ignore if within `zombieIgnoreDist` on same Z-level
4. Ignore if source is zombie and `ignoreBySameType` is true
5. Room wall penalty: different room = 1.2x distance, outside/inside = 1.4x extra
6. Final delta: `1.0 - (dist / effectiveRadius^2)`, must be > 0
7. Sound score: `volume * delta`
8. Zombie attracted to highest-scoring sound

---

## 7. ObjectAmbientEmitters
`zombie.audio.ObjectAmbientEmitters` - [pub] - Singleton

Manages persistent environmental sound emitters tied to world objects. 16 concurrent slots sorted by distance to player.

### Power Policies
| Sound Name | Policy | Notes |
|-|-|-|
| FactoryMachineAmbiance | InteriorHydro | Needs power, indoors |
| HotdogMachineAmbiance | InteriorHydro | Needs power, indoors |
| PayPhoneAmbiance | ExteriorOK | Outdoors, needs power |
| StreetLightAmbiance | StreetLight | Special streetlight logic |
| NeonLightAmbiance | ExteriorOK | Outdoors, needs power |
| NeonSignAmbiance | ExteriorOK | Outdoors, needs power |
| JukeboxAmbiance | InteriorHydro | Needs power, indoors |
| ControlStationAmbiance | InteriorHydro | Needs power, indoors |
| ClockAmbiance | InteriorHydro | Needs power, indoors |
| GasPumpAmbiance | ExteriorOK | Outdoors, needs power |
| LightBulbAmbiance | ExteriorOK | Outdoors, needs power |
| ArcadeMachineAmbiance | InteriorHydro | Needs power, indoors |
| PylonTowerAmbience | ExteriorOK | Outdoors, always active |

### TreeSoundManager
`zombie.audio.TreeSoundManager` - Handles wind-through-trees ambient sounds.

---

## 8. Music Intensity System
`zombie.audio.MusicIntensityConfig` - [pub] @UsedFromLua - Singleton

Dynamic music system that reacts to gameplay events. Configured via Lua tables, drives FMOD parameters.

### Event Configuration
Each event has:
| Property | Type | Purpose |
|-|-|-|
| id | String | Event identifier |
| intensity | float | Music intensity boost (0-1) |
| duration | int | Duration in ticks |
| multiple | boolean | Can stack with itself |

### Built-in Triggers
| Trigger | When |
|-|-|
| `HealthPanel_SeeBite` | Player opens health panel and sees bite wound |
| Various combat events | Via `triggerMusicIntensityEvent()` on IsoPlayer |

### Key Methods [pub]
| Method | Purpose |
|-|-|
| `getInstance()` | Get singleton |
| `initEvents(KahluaTableImpl)` | Load event config from Lua |
| `triggerEvent(String id, MusicIntensityEvents mie)` | Fire a music event |
| `checkHealthPanelVisible(IsoGameCharacter)` | Auto-check bite discovery |

### MusicThreatConfig / MusicThreatStatus
`zombie.audio.MusicThreatConfig` / `MusicThreatStatus` / `MusicThreatStatuses`
Separate threat-based music system tracking zombie proximity and danger level.

### SoundInstanceLimiter
`zombie.audio.SoundInstanceLimiter` - Prevents too many instances of the same sound playing simultaneously.

| Field | Purpose |
|-|-|
| SoundLimiterParams | Per-sound instance limits and cooldowns |

---

## 9. Lua API & Modding

### Playing Sounds from Lua
```lua
-- Get a character's emitter
local emitter = character:getEmitter()
local handle = emitter:playSound("SoundName")
emitter:stopSound(handle)
emitter:setVolume(handle, 0.5)

-- Play at world position
getSoundManager():PlayWorldSound("SoundName", square, 0, 10, 1.0, false)
```

### Creating World Sounds (Zombie Attraction) from Lua
```lua
-- WorldSoundManager.instance accessible as getWorldSoundManager()
local wsm = getWorldSoundManager()
wsm:addSound(source, x, y, z, radius, volume, stressHumans)
wsm:addSoundRepeating(source, x, y, z, radius, volume, stressHumans)
```

### Key Lua-Accessible Singletons
| Global Function | Returns | Purpose |
|-|-|-|
| `getSoundManager()` | BaseSoundManager | Audio playback |
| `getWorldSoundManager()` | WorldSoundManager | Zombie attraction |

### Sound Script Files
Sound definitions loaded from `media/sound/` as `.txt` script files:
- Define `GameSound` entries with name, category, loop, is3D
- Each sound has clips with FMOD event paths, volume, pitch, distance
- Mods can add/override via `media/sound/` in mod folder

### FMOD Parameters (from zombie.audio.parameters)
| Class | Parameter |
|-|-|
| ParameterCurrentZone | Zone type the player is in |
| ParameterInside | Whether player is indoors |
| ParameterDeviceVolume | Radio/TV device volume |

These are automatically updated by the engine and affect FMOD snapshots and bus routing.
