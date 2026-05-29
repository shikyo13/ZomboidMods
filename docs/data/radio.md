# Radio System - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | System Overview | 19-46 |
| 2 | ZomboidRadio Core | 47-106 |
| 3 | Device System | 107-184 |
| 4 | Channel & Frequency System | 185-239 |
| 5 | Broadcast Scripting | 240-286 |
| 6 | RadioScript & Scheduling | 287-342 |
| 7 | Media Data System | 343-401 |
| 8 | Signal & Transmission | 402-430 |
| 9 | Lua Events & Modding API | 431-474 |

---

## 1. System Overview
The radio system provides in-game radio/TV broadcasts, player-to-player voice transmission, and recorded media playback (CDs, VHS tapes). It is driven by XML-based broadcast scripts and supports full mod extensibility.

### Package Structure
| Package | Purpose |
|-|-|
| `zombie.radio` | Core radio logic, API, data loading |
| `zombie.radio.devices` | Device hardware (DeviceData, WaveSignalDevice) |
| `zombie.radio.scripting` | Broadcast scripts, channels, lines |
| `zombie.radio.media` | Recorded media (CDs, VHS) |
| `zombie.radio.StorySounds` | Story-driven ambient sounds |

### Key Classes
| Class | Role |
|-|-|
| ZomboidRadio | Singleton controller - update loop, transmission |
| RadioData | XML parser for broadcast definitions |
| RadioAPI | Lua-facing API utilities |
| DeviceData | Per-device state (frequency, volume, power) |
| WaveSignalDevice | Interface for radio-capable objects |
| RadioChannel | Broadcast channel with frequency |
| RadioScript | Timed broadcast sequence |
| RadioBroadCast | Individual broadcast segment |
| RadioLine | Single line of broadcast text |
| RecordedMedia | CD/VHS media system |

---

## 2. ZomboidRadio Core
`zombie.radio.ZomboidRadio` - [pub] @UsedFromLua - Singleton

### Key Fields
| Field | Type | Access | Purpose |
|-|-|-|-|
| instance | ZomboidRadio | [priv] [static] | Singleton |
| devices | ArrayList\<WaveSignalDevice\> | [priv] final | All registered devices |
| broadcastDevices | ArrayList\<WaveSignalDevice\> | [priv] final | Broadcasting devices |
| scriptManager | RadioScriptManager | [priv] | Manages all radio scripts |
| daysSinceStart | int | [priv] | Days since game start |
| channelNames | Map\<Integer,String\> | [priv] final | Frequency -> name mapping |
| categorizedChannels | Map\<String,Map\<Integer,String\>\> | [priv] final | Category -> freq -> name |
| knownFrequencies | List\<Integer\> | [priv] final | All registered frequencies |
| recordedMedia | RecordedMedia | [priv] [static] | CD/VHS system |
| freqlist | HashMap\<Integer,FreqListEntry\> | [priv] final | Per-update transmission cache |

### Static Flags
| Flag | Type | Purpose |
|-|-|-|
| postRadioSilence | boolean | true after day 14 - scripted broadcasts end |
| disableBroadcasting | boolean | Kill all broadcasts |
| louisvilleObfuscation | boolean | Obfuscate Louisville-related info |

### Static Sounds (Radio Static)
`staticSounds = ["<bzzt>", "<fzzt>", "<wzzt>", "<szzt>"]` - displayed as chat text when signal degrades.

### Post-Radio Silence
After 14 in-game days, `postRadioSilence` is set to true. All scripted broadcasts cease. This represents radio stations going off the air as civilization collapses.

### Update Loop
`update()` runs every tick:
1. Louisville obfuscation check
2. If day > 14 and not already silent: set `postRadioSilence`
3. Update `storySoundManager` (client/SP)
4. Update `scriptManager` (server/SP)
5. Check player spoken lines for two-way radio transmission
6. Scan equipped radios + broadcast devices for transmit capability
7. Build frequency list, transmit player voice on matching frequencies

### Channel Registration [pub]
| Method | Purpose |
|-|-|
| `addChannelName(name, freq, category)` | Register named channel |
| `addChannelName(name, freq, category, overwrite)` | With overwrite control |
| `removeChannelName(freq)` | Unregister channel |
| `getChannelName(freq)` | Get name for frequency |
| `GetChannelList(category)` | All channels in category |
| `getFullChannelList()` | All categorized channels |

### Frequency Generation [pub]
| Method | Purpose |
|-|-|
| `getRandomFrequency()` | Random unused freq in 88000-108000 |
| `getRandomFrequency(min, max)` | Random unused freq in range |

Frequencies are integers in units of 200 (e.g., 88000 = 88.0 MHz, step = 0.2 MHz).

---

## 3. Device System

### WaveSignalDevice Interface
`zombie.radio.devices.WaveSignalDevice` - [pub] @UsedFromLua

Implemented by: Radio inventory items, IsoWaveSignal world objects, VehiclePart radio.

| Method | Returns | Purpose |
|-|-|-|
| `getDeviceData()` | DeviceData | Hardware state |
| `setDeviceData(DeviceData)` | void | Replace hardware state |
| `getDelta()` / `setDelta(float)` | float | Battery drain delta |
| `getSquare()` | IsoGridSquare | World position |
| `getX()` / `getY()` / `getZ()` | float | Coordinates |
| `HasPlayerInRange()` | boolean | Player nearby |
| `AddDeviceText(...)` | void | Display received text |

### DeviceData
`zombie.radio.devices.DeviceData` - [pub] @UsedFromLua

Per-device hardware configuration and runtime state.

### Core Properties
| Field | Type | Default | Purpose |
|-|-|-|-|
| deviceName | String | "WaveSignalDevice" | Display name |
| twoWay | boolean | false | Can transmit |
| transmitRange | int | 1000 | Broadcast range (tiles) |
| micRange | int | 5 | Microphone pickup range (tiles) |
| micIsMuted | boolean | false | Mic muted |
| baseVolumeRange | float | 15.0 | Speaker audible range |
| deviceVolume | float | 1.0 | Volume 0-1 |
| isPortable | boolean | false | Carried by player |
| isTelevision | boolean | false | TV device |
| isHighTier | boolean | false | Military/high-end |
| isTurnedOn | boolean | false | Power state |
| channel | int | 88000 | Current frequency |
| minChannelRange | int | 200 | Min tunable frequency |
| maxChannelRange | int | 1000000 | Max tunable frequency |

### Power System
| Field | Type | Default | Purpose |
|-|-|-|-|
| isBatteryPowered | boolean | true | Uses batteries |
| hasBattery | boolean | true | Battery installed |
| powerDelta | float | 1.0 | Battery charge (0-1) |
| useDelta | float | 0.001 | Drain rate per tick |

### Media Playback State
| Field | Type | Purpose |
|-|-|-|
| mediaIndex | short | Current media item index |
| mediaType | byte | 0 = CD, 1 = VHS |
| mediaItem | String | Item script name |
| playingMedia | MediaData | Active media data |
| isPlayingMedia | boolean | Currently playing |
| mediaLineIndex | int | Current line in media |
| lineCounter | float | Time on current line |
| currentMediaLine | String | Text being displayed |
| currentMediaColor | Color | Text color |

### Headphone Types
| Value | Meaning |
|-|-|
| -1 | No headphones |
| 0+ | Headphone type index |

When headphones are connected, the radio produces no WorldSound (silent to zombies).

### Preset System
`DeviceData.generatePresets()` auto-populates channel presets based on device type:
- **Television**: All TV channels in range
- **Regular radio**: Emergency channels (100-300/1000 chance), Radio channels (800/1000)
- **Two-way radio**: Lower chance for commercial, adds Amateur channels
- **High-tier**: 800/1000 chance for most channels, rare Military (10/1000)

---

## 4. Channel & Frequency System

### ChannelCategory Enum
`zombie.radio.ChannelCategory` - [pub] @UsedFromLua

| Value | Purpose |
|-|-|
| Undefined | No category |
| Radio | Commercial radio stations |
| Television | TV channels |
| Military | Military frequencies |
| Amateur | Ham radio |
| Bandit | Hostile/bandit channels |
| Emergency | Emergency broadcasts |
| Other | Miscellaneous |

### RadioChannel
`zombie.radio.scripting.RadioChannel` - [pub] @UsedFromLua

Represents a broadcast channel on a specific frequency.

| Field | Type | Purpose |
|-|-|-|
| guid | String | Unique identifier |
| name | String | Channel display name |
| frequency | int | Frequency value (e.g. 91600) |
| isTv | boolean | Television channel |
| category | ChannelCategory | Channel type |
| currentScript | RadioScript | Active broadcast script |
| airingBroadcast | RadioBroadCast | Current airing segment |
| lastAiredLine | String | Most recent broadcast text |
| isTimeSynced | boolean | Sync broadcasts to game time |
| louisvilleObfuscate | boolean | Censor Louisville info |
| airCounterMultiplier | float | Speed of line progression |

### Key Methods [pub]
| Method | Purpose |
|-|-|
| `GetFrequency()` | Channel frequency |
| `GetName()` | Channel name |
| `GetCategory()` | ChannelCategory |
| `setActiveScript(name, day)` | Start a script on this channel |
| `setActiveScript(name, day, loop, maxloops)` | With loop control |
| `SetPlayerIsListening(bool)` | Player tuned in |
| `GetPlayerIsListening()` | Check if player listening |
| `getLastAiredLine()` | Most recent text |
| `getAiringBroadcast()` | Current RadioBroadCast |

### Script Transition
When a script exhausts all broadcasts, `getNextScript()` is called:
- If `currentScriptLoop < currentScriptMaxLoops`: loop the same script
- Otherwise: roll `ExitOption` list (weighted random) to pick next script

---

## 5. Broadcast Scripting

### RadioBroadCast
`zombie.radio.scripting.RadioBroadCast` - [pub] @UsedFromLua

A time-bounded segment within a RadioScript containing dialogue lines.

| Field | Type | Purpose |
|-|-|-|
| id | String | Broadcast identifier |
| startStamp | int | Start time (day*24*60 + hour*60 + min) |
| endStamp | int | End time |
| lines | ArrayList\<RadioLine\> | Dialogue lines |
| preSegment | RadioBroadCast | Intro segment (played first) |
| postSegment | RadioBroadCast | Outro segment (played after) |

### Playback Flow
1. Pre-segment plays if set (intro/jingle)
2. Pause line ("~") inserted between segments
3. Main lines play sequentially
4. Post-segment plays if set (outro/ad)

### Key Methods [pub]
| Method | Purpose |
|-|-|
| `getNextLine()` | Advance and return next RadioLine |
| `getCurrentLine()` | Current line without advancing |
| `PeekNextLineText()` | Preview next line text |
| `AddRadioLine(RadioLine)` | Add dialogue line |
| `setPreSegment(RadioBroadCast)` | Set intro segment |
| `setPostSegment(RadioBroadCast)` | Set outro segment |
| `resetLineCounter()` | Reset to beginning |
| `setCurrentLineNumber(int)` | Jump to specific line |
| `getStartStamp()` / `getEndStamp()` | Time window |

### RadioLine
`zombie.radio.scripting.RadioLine` - [pub] @UsedFromLua

| Field | Type | Purpose |
|-|-|-|
| text | String | Spoken text (default: "\<!text missing!\>") |
| r, g, b | float | Text color (RGB 0-1) |
| effects | String | Effect codes string |
| airTime | float | Custom display duration (-1 = auto) |

---

## 6. RadioScript & Scheduling

### RadioScript
`zombie.radio.scripting.RadioScript` - [pub] @UsedFromLua

A named script containing timed broadcasts, with loop and exit control.

| Field | Type | Purpose |
|-|-|-|
| name | String | Script identifier |
| guid | String | UUID |
| broadcasts | ArrayList\<RadioBroadCast\> | Timed segments |
| exitOptions | ArrayList\<ExitOption\> | Transition options |
| startDay | int | Day script was activated |
| startDayStamp | int | `startDay * 24 * 60` |
| loopMin / loopMax | int | Loop count range |
| currentBroadcast | RadioBroadCast | Active segment |

### Time Stamp System
Timestamps are minutes from start: `days * 24 * 60 + hours * 60 + minutes`

RadioAPI utility methods:
| Method | Purpose |
|-|-|
| `timeToTimeStamp(days, hours, minutes)` | Convert to timestamp |
| `timeStampToDays(stamp)` | Extract days |
| `timeStampToHours(stamp)` | Extract hours |
| `timeStampToMinutes(stamp)` | Extract minutes |

### Script Update Flow
`UpdateScript(timeStamp)`:
1. Compute internal stamp: `timeStamp - startDayStamp`
2. Find broadcast where `startStamp <= internalStamp < endStamp`
3. Return true if a broadcast is active

### ExitOption
| Field | Type | Purpose |
|-|-|-|
| scriptname | String | Next script to activate |
| chance | int | Percent chance (0-100, must total <= 100) |
| startDelay | int | Days to wait before starting next |

### RadioData XML Loading
`zombie.radio.RadioData` - [pub] @UsedFromLua

Loads from `media/radio/*.xml` files. Supports translations via `.txt` files.

Search order:
1. Vanilla: `media/radio/` in game install
2. Mod common: `{mod}/common/media/radio/`
3. Mod versioned: `{mod}/{version}/media/radio/`

Translation tokens use `${t:key}` syntax, resolved from translation files.

---

## 7. Media Data System

### RecordedMedia
`zombie.radio.media.RecordedMedia` - [pub] @UsedFromLua

Manages all CD and VHS content. CDs provide music/audio, VHS provides video content.

### Spawn Rarities
| ID | Constant | Purpose |
|-|-|-|
| 0 | SPAWN_COMMON | Standard loot tables |
| 1 | SPAWN_RARE | Reduced spawn chance |
| 2 | SPAWN_EXCEPTIONAL | Very rare |

### Key Methods [pub]
| Method | Purpose |
|-|-|
| `register(category, id, displayName, spawning)` | Register new media |
| `getCategories()` | All category names |
| `getAllMediaForType(byte)` | All media by type (0=CD, 1=VHS) |
| `getAllMediaForCategory(String)` | All media in category |

### Categories
Vanilla categories include: "CDs", "Retail-VHS", "Home-VHS"

Home VHS spawns are tracked per-save via `homeVhsSpawned` (HashSet of short indexes) to prevent duplicate home videos.

### MediaData
`zombie.radio.media.MediaData` - [pub] @UsedFromLua

Individual CD or VHS tape content.

| Field | Type | Purpose |
|-|-|-|
| id | String | Unique identifier |
| itemDisplayName | String | Translation key for display |
| title | String | Media title (translation key) |
| subtitle | String | Subtitle (translation key) |
| author | String | Author/artist (translation key) |
| extra | String | Extra info (translation key) |
| category | String | Category (e.g. "CDs") |
| spawning | int | Rarity (0=common, 1=rare, 2=exceptional) |
| lines | ArrayList\<MediaLineData\> | Content lines |
| index | short | Numeric index in save system |

### Key Methods [pub]
| Method | Purpose |
|-|-|
| `addLine(text, r, g, b, codes)` | Add content line |
| `getLineCount()` | Number of lines |
| `getTranslatedTitle()` | Localized title |
| `getTranslatedItemDisplayName()` | Localized item name |
| `getMediaType()` | 0 = CD, 1 = VHS |

### Lua Event
`OnInitRecordedMedia(RecordedMedia)` - Fired after media system loads. Mods use this to register custom CDs/VHS tapes.

---

## 8. Signal & Transmission

### Transmission Flow
`ZomboidRadio.SendTransmission(sourceX, sourceY, channel, msg, guid, codes, r, g, b, signalStrength, isTV)`:
1. For each registered device matching the channel frequency
2. Check if device is in range: `distance < signalStrength`
3. Apply range distortion if signal is weak
4. Deliver text via `WaveSignalDevice.AddDeviceText()`
5. Device triggers WorldSound if `doTriggerWorldSound` (attracts zombies)

### Range Distortion
When signal degrades, text is corrupted with static sounds from `staticSounds[]`. The `doDeviceRangeDistortion()` method inserts `<bzzt>`, `<fzzt>`, etc. based on distance/signalStrength ratio.

### Two-Way Radio Transmission
Player speech is captured when:
1. Player has equipped radio with `isTwoWay = true`, `isTurnedOn = true`, `!micIsMuted`
2. Player speaks (chat line detected)
3. System builds frequency list from all nearby active two-way devices
4. Transmission sent on each matching frequency
5. All devices tuned to that frequency receive the message

### Signal Interference
Weather affects radio reception via `ClimateManager` integration. The `hasAppliedInterference` flag tracks weather-based signal degradation.

### Louisville Obfuscation
Channels marked with `louisvilleObfuscate` will garble Louisville-specific location references until the player reaches Louisville.

---

## 9. Lua Events & Modding API

### Lua Events
| Event | Args | When |
|-|-|-|
| `OnInitRecordedMedia` | RecordedMedia | Media system initialized |
| `OnDeviceText` | guid, codes, x, y, z, line, device | Text received on device |

### RadioAPI [pub] @UsedFromLua - Singleton
| Method | Purpose |
|-|-|
| `getInstance()` | Get API singleton |
| `getChannels(category)` | KahluaTable of freq -> name |
| `timeToTimeStamp(d, h, m)` | Convert time to stamp |
| `timeStampToDays(stamp)` | Extract days from stamp |
| `timeStampToHours(stamp)` | Extract hours from stamp |
| `timeStampToMinutes(stamp)` | Extract minutes from stamp |

### Adding Custom Radio Content (Modding)
1. Create XML file in `{mod}/common/media/radio/your_channel.xml`
2. Define `<RadioChannel>` with frequency and category
3. Add `<RadioScript>` with `<RadioBroadCast>` entries
4. Each broadcast has time window and `<RadioLine>` entries
5. Add translation `.txt` files for localization

### Custom Media (CDs/VHS)
Register via `OnInitRecordedMedia` event:
```lua
Events.OnInitRecordedMedia.Add(function(recordedMedia)
    local mediaData = recordedMedia:register("CDs", "MyMod_CD1", "IGUI_MyCD", 0)
    mediaData:setTitle("IGUI_MyCD_Title")
    mediaData:addLine("Song lyrics here...", 0.8, 0.8, 0.8, "")
end)
```

### Device Volume and World Sound
Radio/TV volume directly creates WorldSounds that attract zombies:
- `baseVolumeRange` (default 15.0) scales with `deviceVolume` (0-1)
- Effective range: `baseVolumeRange * deviceVolume`
- Headphones (headphoneType >= 0) suppress WorldSound creation
- Turned-off devices produce no sound

### StorySounds System
`zombie.radio.StorySounds.SLSoundManager` - Manages story-driven ambient sounds that play at specific game days/times. Used for atmosphere during the early game timeline.
