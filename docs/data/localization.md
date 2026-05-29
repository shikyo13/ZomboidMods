# Localization & Translation System - PZ Data Map
Source: projectzomboid.jar (decompiled) | media/lua/shared/Translate | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Translation Architecture | 20-40 |
| 2 | File Format & Structure | 41-85 |
| 3 | Translation Categories | 86-139 |
| 4 | Key Prefix Routing | 140-175 |
| 5 | String Formatting | 176-213 |
| 6 | Supported Languages | 214-249 |
| 7 | Mod Translation Guide | 250-342 |
| 8 | Sandbox Option Translation | 343-401 |
| 9 | Lua API | 402-447 |
| 10 | Debug Tools | 448-479 |

---

## 1. Translation Architecture

**Core class:** `zombie.core.Translator` (exposed to Lua via `@UsedFromLua`)

The translation system loads JSON files from `media/lua/shared/Translate/{LANG}/` into per-category `HashMap<String, String>` maps. Key lookup is prefix-based - the prefix of a translation key (e.g. `UI_`, `IGUI_`) determines which map to search.

**Loading order:**
1. Base game files: `{PZ_ROOT}/media/lua/shared/Translate/{LANG}/{Category}.json`
2. Mod files (per active mod): `{modDir}/media/lua/shared/Translate/{LANG}/{Category}.json`

**Language stack:** Languages can declare a `base` language. The system loads translations bottom-up through the inheritance chain, ending with the default language (EN). Later loads override earlier ones, so the most specific language wins.

```
Example: PTBR -> PT -> EN
Load EN first, then PT overwrites matching keys, then PTBR overwrites again.
```

**Mod translations** load after base game translations for each language in the stack, so mods can override any base game string.

---

## 2. File Format & Structure

### Directory Layout

```
media/lua/shared/Translate/
    EN/
        language.txt        # language metadata
        UI.json             # UI strings
        IG_UI.json          # In-game UI strings
        ContextMenu.json    # Context menu text
        Sandbox.json        # Sandbox option labels
        Tooltip.json        # Tooltip text
        ...                 # (see full list below)
    FR/
        language.txt
        UI.json
        ...
```

### language.txt Format

```
VERSION = 1,
text = English,
```

Two fields: `VERSION` (always 1) and `text` (display name of the language).

### JSON File Format

Standard JSON object with string keys and string values:

```json
{
    "UI_mainscreen_option": "OPTIONS",
    "UI_mainscreen_exit": "QUIT",
    "UI_coopscreen_title": "HOST GAME"
}
```

**Important:** Keys must follow the correct prefix convention for their file. The prefix determines which internal map the key routes to. A key with prefix `UI_` in `Tooltip.json` will not work - it must be in `UI.json`.

---

## 3. Translation Categories

### File-to-Map Registry

The game registers these file/map pairs in `Translator.BY_NAME` (a `LinkedHashMap` preserving insertion order):

| JSON Filename | Key Prefix | Java Map | Purpose |
|-|-|-|-|
| `Tooltip.json` | `Tooltip_` | `tooltip` | Item/world tooltips |
| `IG_UI.json` | `IGUI_` | `igui` | In-game UI elements |
| `Recipes.json` | `Recipe_` | `recipe` | Recipe names |
| `RecipeGroups.json` | `RecipeGroup_` | `recipeGroups` | Recipe group names |
| `Farming.json` | `Farming_` | `farming` | Farming UI |
| `ContextMenu.json` | `ContextMenu_` | `contextMenu` | Right-click menus |
| `SurvivalGuide.json` | `SurvivalGuide_` | `survivalGuide` | Tutorial/guide text |
| `UI.json` | `UI_` | `ui` | Main UI strings |
| `Items.json` | (special) | `items` | Legacy item names |
| `ItemName.json` | (special) | `itemName` | Module.Type item names |
| `Moodles.json` | `Moodles_` | `moodles` | Moodle descriptions |
| `Sandbox.json` | `Sandbox_` | `sandbox` | Sandbox option labels |
| `Challenge.json` | `Challenge_` | `challenge` | Challenge descriptions |
| `Stash.json` | `Stash_` | `stash` | Annotated map/stash text |
| `Moveables.json` | (special) | `moveables` | Moveable object names |
| `MakeUp.json` | `MakeUp` | `makeup` | Cosmetics names |
| `GameSound.json` | `GameSound_` | `gameSound` | Sound effect names |
| `DynamicRadio.json` | (special) | `dynamicRadio` | Radio broadcast text |
| `EvolvedRecipeName.json` | (special) | `itemEvolvedRecipeName` | Evolved recipe names |
| `Recorded_Media.json` | `RM_` | `recordedMedia` | VHS/CD media text |
| `SurvivorNames.json` | `SurvivorName_`/`SurvivorSurname_` | `survivorNames` | NPC names |
| `Attributes.json` | `Attributes_` | `attributes` | Character attributes |
| `Fluids.json` | `Fluid_` | `fluids` | Fluid names |
| `Print_Media.json` | `Print_Media_` | `printMedia` | Readable print media |
| `Print_Text.json` | `Print_Text_` | `printText` | Print text content |
| `Entity.json` | `EC_` | `entity` | Entity system text |
| `RadioData.json` | `RD_` | `radioData` | Radio data text |
| `BodyParts.json` | `BODYPART_` | `bodyParts` | Body part names |
| `MapLabel.json` | `MapLabel_` | `mapLabel` | Map label text |

### Map-specific Translation Files

Map translation files use a separate path. Each map can have its own JSON:

```
media/lua/shared/Translate/EN/Muldraugh, KY.json
media/lua/shared/Translate/EN/Riverside, KY.json
media/lua/shared/Translate/EN/West Point, KY.json
media/lua/shared/Translate/EN/Rosewood, KY.json
media/lua/shared/Translate/EN/Echo Creek, KY.json
```

These provide `title` and `description` keys read via `Translator.readMapTranslation()`.

---

## 4. Key Prefix Routing

**Method:** `Translator.getText(String desc)` / `Translator.getTextOrNull(String desc)`

The prefix of the key determines which map is searched. This is a strict `startsWith` check in order:

| Prefix | Routes to | Example Key |
|-|-|-|
| `UI_` | `ui` map | `UI_mainscreen_exit` |
| `Moodles_` | `moodles` map | `Moodles_Bleeding` |
| `SurvivalGuide_` | `survivalGuide` map | `SurvivalGuide_Chapter1` |
| `Farming_` | `farming` map | `Farming_WaterPlant` |
| `IGUI_` | `igui` map | `IGUI_invpanel_Type` |
| `ContextMenu_` | `contextMenu` map | `ContextMenu_Destroy` |
| `GameSound_` | `gameSound` map | `GameSound_Thunder` |
| `Sandbox_` | `sandbox` map | `Sandbox_ZombieCount` |
| `Tooltip_` | `tooltip` map | `Tooltip_food_Hunger` |
| `Challenge_` | `challenge` map | `Challenge_FirstWeek` |
| `MakeUp` | `makeup` map | `MakeUpCategory_Face` |
| `Stash_` | `stash` map | `Stash_AnnotedMapMuldraugh` |
| `RM_` | `recordedMedia` map | `RM_VHS_Cooking` |
| `SurvivorName_` | `survivorNames` map | `SurvivorName_Bob` |
| `SurvivorSurname_` | `survivorNames` map | `SurvivorSurname_Smith` |
| `Attributes_` | `attributes` map | `Attributes_Fitness` |
| `Fluid_` | `fluids` map | `Fluid_Water` |
| `Print_Media_` | `printMedia` map | `Print_Media_Book1` |
| `Print_Text_` | `printText` map | `Print_Text_Page1` |
| `EC_` | `entity` map | `EC_Energy_Electric` |
| `RD_` | `radioData` map | `RD_Channel1` |
| `BODYPART_` | `bodyParts` map | `BODYPART_Head` |
| `MapLabel_` | `mapLabel` map | `MapLabel_Pharmacy` |

If no prefix matches or the key is not found, `getText()` returns the raw key string and logs a `Translation.error` in debug mode. `getTextOrNull()` returns `null` instead.

---

## 5. String Formatting

### Parameter Substitution

Translation values use `%1`, `%2`, etc. as positional parameters:

```json
{
    "UI_mainscreen_version": "Version %1",
    "UI_mainscreen_seed": "Seed: %1"
}
```

**Internal conversion:** When JSON is loaded, `%` is first escaped to `%%`, then `%%N` is converted to `%N$s` for Java's `String.formatted()`:
```
"Version %1" -> "Version %%1" -> "Version %1$s"
```

Call with arguments: `Translator.getText("UI_mainscreen_version", "42.0.1")` produces `"Version 42.0.1"`.

**Lua usage:** `getText("UI_mainscreen_version", version)` - arguments are passed as additional parameters.

### Line Breaks

Use `<br>` or `<BR>` tags for newlines in translation values. They are converted to `\n` at runtime.

The `\\n` escape also works in some contexts (e.g. `"Line1\\nLine2"` in JSON).

The `<LINE>` tag is used in some strings for UI line breaks (handled by the UI renderer, not Translator).

### Special Characters

- Double quotes within JSON values must be escaped: `\"`
- Backslash: `\\`
- Percent sign (literal): appears as `%%` after the internal conversion, so use `%` in JSON and it will be double-escaped automatically

---

## 6. Supported Languages

27 languages with folder codes:

| Code | Language | Code | Language |
|-|-|-|-|
| `AR` | Arabic | `NL` | Dutch |
| `CA` | Catalan | `NO` | Norwegian |
| `CH` | Traditional Chinese | `PH` | Filipino |
| `CN` | Simplified Chinese | `PL` | Polish |
| `CS` | Czech | `PT` | Portuguese |
| `DA` | Danish | `PTBR` | Brazilian Portuguese |
| `DE` | German | `RO` | Romanian |
| `EN` | English (default) | `RU` | Russian |
| `ES` | Spanish | `TH` | Thai |
| `FI` | Finnish | `TR` | Turkish |
| `FR` | French | `UA` | Ukrainian |
| `HU` | Hungarian | | |
| `ID` | Indonesian | | |
| `IT` | Italian | | |
| `JP` | Japanese | | |
| `KO` | Korean | | |

**Language record fields** (`zombie.core.Language`):
- `name` - folder code (e.g. `"EN"`)
- `text` - display name (e.g. `"English"`)
- `base` - parent language for fallback (e.g. PTBR's base is PT)
- `azerty` - true for AZERTY keyboard layout languages (FR)

**Language detection order:**
1. User setting (`Core.getInstance().getOptionLanguageName()`)
2. System locale (`user.language` property, uppercased)
3. Default (`EN`)

---

## 7. Mod Translation Guide

### Adding Translations for a Mod

Place JSON files in the mod's Translate directory. Files can go in either `common/` or version-specific (`42/`) media directories:

```
MyMod/
    Contents/mods/MyMod/
        common/
            media/lua/shared/Translate/
                EN/
                    UI.json           # English UI strings
                    IG_UI.json        # English IGUI strings
                    Sandbox.json      # Sandbox option translations
                FR/
                    UI.json           # French translations
                    IG_UI.json
                    Sandbox.json
        42/
            media/lua/shared/Translate/
                EN/
                    UI.json           # B42-specific overrides (if needed)
```

### Mod Name/Description Translation

Create a `Mod.json` file in the Translate directory:

```json
{
    "name": "My Cool Mod",
    "description": "This mod does cool things."
}
```

Loaded via `Translator.readModTranslation()`. Only uses `name` and `description` keys.

### Key Naming Conventions

Follow existing patterns to ensure proper prefix routing:

```json
// UI.json - for main UI elements
{
    "UI_MyMod_SettingsTitle": "My Mod Settings",
    "UI_MyMod_EnableFeature": "Enable Feature"
}

// IG_UI.json - for in-game UI
{
    "IGUI_MyMod_StatusLabel": "Status: Active",
    "IGUI_MyMod_ContainerTitle": "Custom Container"
}

// ContextMenu.json - for right-click menus
{
    "ContextMenu_MyMod_DoAction": "Do Custom Action",
    "ContextMenu_MyMod_Configure": "Configure..."
}

// Tooltip.json - for item tooltips
{
    "Tooltip_MyMod_CustomInfo": "Custom tooltip information"
}
```

### Overriding Base Game Translations

Mods can override any base game string by using the same key. Mod translations load after base game translations, so the mod value wins:

```json
// In your mod's EN/ContextMenu.json
{
    "ContextMenu_Destroy": "Demolish"
}
```

### ItemName Translation

Item display names use the `ItemName.json` file with `module.type` as the key:

```json
{
    "Base.Hammer": "Hammer",
    "MyMod.CustomTool": "Custom Tool"
}
```

Looked up via `Translator.getItemNameFromFullType("MyMod.CustomTool")`. Falls back to the item's `DisplayName` script property if no translation exists.

---

## 8. Sandbox Option Translation

Sandbox options use a structured key naming convention in `Sandbox.json`:

### Key Pattern

```
Sandbox_{OptionName}              - Option display label
Sandbox_{OptionName}_tooltip      - Tooltip/description text
Sandbox_{OptionName}_option{N}    - Enum option labels (1-indexed)
```

### Example

For a sandbox option `ZombieCount`:

```json
{
    "Sandbox_ZombieCount": "Zombie Count",
    "Sandbox_ZombieCount_tooltip": "Controls how many zombies spawn.",
    "Sandbox_ZombieCount_option1": "Insane",
    "Sandbox_ZombieCount_option2": "Very High",
    "Sandbox_ZombieCount_option3": "High",
    "Sandbox_ZombieCount_option4": "Normal",
    "Sandbox_ZombieCount_option5": "Low",
    "Sandbox_ZombieCount_option6": "None"
}
```

### Mod Sandbox Options

When a mod defines sandbox options in `sandbox-options.txt`, it needs matching entries in `Sandbox.json`. The option name in the translation key must match the option name in `sandbox-options.txt`:

```
-- sandbox-options.txt
option MyMod.DamageMultiplier = 1.0 [setting:MyMod_DamageMultiplier]

-- Translate/EN/Sandbox.json
{
    "Sandbox_MyMod_DamageMultiplier": "Damage Multiplier",
    "Sandbox_MyMod_DamageMultiplier_tooltip": "Multiplier for all damage dealt."
}
```

### Category/Section Headers

Sandbox option group headers also use `Sandbox_` prefix keys:

```json
{
    "Sandbox_PopulationOptions": "Population",
    "Sandbox_ZombieOptions": "ZOMBIE OPTIONS",
    "Sandbox_TimeOptions": "Time",
    "Sandbox_Advanced": "Advanced"
}
```

---

## 9. Lua API

### Core Functions

```lua
-- Get translated text (returns key if not found)
getText("UI_mainscreen_exit")                    --> "QUIT"
getText("UI_mainscreen_version", "42.0")         --> "Version 42.0"

-- Get translated text (returns nil if not found)
getTextOrNull("UI_nonexistent")                  --> nil

-- Item display names
getItemNameFromFullType("Base.Hammer")           --> "Hammer"

-- Moveable object names
getMoveableDisplayName("Large Oak Table")        --> translated name

-- Recipe names
getRecipeName("Make Metal Sheet")                --> translated name

-- Context menu text
getText("ContextMenu_Destroy")                   --> "Destroy"

-- Entity text
getEntityText("EC_Energy_Electric")              --> "Electric"

-- Fluid text
getFluidText("Fluid_Water")                      --> "Water"
```

### Language Info

```lua
-- Get current language
Translator.getLanguage()                         --> Language object

-- Get available languages
Translator.getAvailableLanguage()                --> list of Language

-- Force reload
Translator.loadFiles()
```

---

## 10. Debug Tools

### Translation Debug Mode

Set `Translator.debug = true` to enable:
- Missing translation errors written to `~/Zomboid/cache/translationProblems.txt`
- Debug reports for missing item names, recipe names, evolved recipe names

### Translation Prefix Option

`DebugOptions` key: `Translation.Prefix` (default: false)

When enabled in debug mode, translated strings get prefixed:
- `*` prefix: translation found successfully
- `!` prefix: translation key was missing (returned raw key)

This makes it easy to visually identify untranslated strings in the UI.

### Translation Log Channel

`DebugType.Translation` logs translation errors:
```
ERROR: Translation  f:100, t:1711100000> ERROR: Missing translation "UI_nonexistent"
```

### Verifying Mod Translations

1. Enable `-debug` launch flag
2. Set `Translation.Prefix` to true in debug options
3. Set `DebugLog.Translation` severity to `Debug` or lower in `debuglog.ini`
4. Look for `!`-prefixed strings in UI (missing translations)
5. Check `translationProblems.txt` for full missing key list
