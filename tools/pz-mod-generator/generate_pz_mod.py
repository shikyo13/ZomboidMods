#!/usr/bin/env python3
"""
Project Zomboid Mod Generator
Generates a complete PZ mod skeleton with proper directory structure,
sandbox options, translations, and Lua boilerplate.

Based on the Build 42 mod structure used by BarricadesHurtZombies.

Usage:
    python generate_pz_mod.py                   # Interactive mode
    python generate_pz_mod.py --config mod.json  # From config file
    python generate_pz_mod.py --name "MyMod" --id "MyModB42" --author "Me"

Config file format (JSON):
{
    "mod_name": "My Cool Mod",
    "mod_id": "MyCoolModB42",
    "author": "YourName",
    "description": "A mod that does cool things.",
    "version_min": "42.0",
    "url": "",
    "has_shared_lua": true,
    "has_client_lua": false,
    "has_server_lua": false,
    "has_sandbox_options": true,
    "has_common_folder": true,
    "sandbox_options": [
        {
            "name": "Enabled",
            "type": "boolean",
            "default": true,
            "tooltip": "Enable or disable the mod"
        },
        {
            "name": "Strength",
            "type": "double",
            "default": 1.0,
            "min": 0.0,
            "max": 10.0,
            "tooltip": "How strong the effect is"
        },
        {
            "name": "Mode",
            "type": "enum",
            "num_values": 3,
            "default": 1,
            "tooltip": "Which mode to use",
            "options": ["Easy", "Normal", "Hard"]
        },
        {
            "name": "Interval",
            "type": "integer",
            "default": 100,
            "min": 10,
            "max": 1000,
            "tooltip": "Update interval in ticks"
        }
    ],
    "languages": ["EN", "CH", "DE", "ES", "FR", "JP", "KR", "RU"],
    "events_used": ["OnLoad", "OnTick"]
}
"""

import argparse
import json
import os
import sys
import textwrap
from pathlib import Path


# ============================================================================
# Constants
# ============================================================================

DEFAULT_LANGUAGES = ["EN", "CH", "DE", "ES", "FR", "JP", "KR", "RU"]

SANDBOX_TYPE_TEMPLATE = {
    "boolean": "    type = boolean,\n    default = {default},",
    "integer": "    type = integer,\n    min = {min},\n    max = {max},\n    default = {default},",
    "double": "    type = double,\n    min = {min},\n    max = {max},\n    default = {default},",
    "enum": "    type = enum,\n    numValues = {num_values},\n    default = {default},",
    "string": '    type = string,\n    default = {default},',
}


# ============================================================================
# File generators
# ============================================================================

def generate_mod_info(mod_name, mod_id, description, version_min, author, url=""):
    """Generate mod.info content."""
    lines = [
        f"name={mod_name}",
        f"id={mod_id}",
        f"description={description}",
        f"versionMin={version_min}",
        f"author={author}",
    ]
    if url:
        lines.append(f"url={url}")
    lines.append("poster=poster.png")
    return "\n".join(lines) + "\n"


def generate_sandbox_options(mod_id, options):
    """Generate sandbox-options.txt content."""
    if not options:
        return ""

    lines = ["VERSION = 3,", ""]

    for opt in options:
        name = opt["name"]
        opt_type = opt["type"]
        lines.append(f"option {mod_id}.{name}")
        lines.append("{")

        if opt_type in SANDBOX_TYPE_TEMPLATE:
            template = SANDBOX_TYPE_TEMPLATE[opt_type]
            fmt_args = {
                "default": opt.get("default", ""),
                "min": opt.get("min", 0),
                "max": opt.get("max", 100),
                "num_values": opt.get("num_values", 2),
            }
            # Format boolean defaults to lowercase
            if opt_type == "boolean":
                fmt_args["default"] = str(fmt_args["default"]).lower()
            lines.append(template.format(**fmt_args))
        else:
            lines.append(f"    type = {opt_type},")
            lines.append(f"    default = {opt.get('default', '')},")

        lines.append(f"    page = {mod_id},")
        lines.append(f"    translation = {mod_id}_{name},")
        lines.append("}")
        lines.append("")

    return "\n".join(lines)


def generate_translation_en(mod_id, mod_name, options):
    """Generate Sandbox_EN.txt translation content."""
    lines = [
        "Sandbox_EN = {",
        f'    Sandbox_{mod_id} = "{mod_name}",',
        "",
    ]

    for opt in options:
        name = opt["name"]
        display = opt.get("display_name", _to_display_name(name))
        tooltip = opt.get("tooltip", "")
        default_str = ""
        if "default" in opt:
            default_str = f" (Default: {opt['default']})"

        lines.append(f'    Sandbox_{mod_id}_{name} = "{display}{default_str}",')
        if tooltip:
            lines.append(f'    Sandbox_{mod_id}_{name}_tooltip = "{tooltip}",')

        # Enum option labels
        if opt["type"] == "enum" and "options" in opt:
            for i, label in enumerate(opt["options"], start=1):
                lines.append(f'    Sandbox_{mod_id}_{name}_option{i} = "{label}",')

        lines.append("")

    lines.append("}")
    return "\n".join(lines) + "\n"


def generate_translation_placeholder(lang_code, mod_id, mod_name, options):
    """Generate a placeholder translation file for a non-EN language."""
    lines = [
        f"Sandbox_{lang_code} = {{",
        f'    Sandbox_{mod_id} = "{mod_name}",',
        "",
    ]

    for opt in options:
        name = opt["name"]
        display = opt.get("display_name", _to_display_name(name))
        default_str = ""
        if "default" in opt:
            default_str = f" (Default: {opt['default']})"

        lines.append(f'    -- TODO: Translate to {lang_code}')
        lines.append(f'    Sandbox_{mod_id}_{name} = "{display}{default_str}",')
        tooltip = opt.get("tooltip", "")
        if tooltip:
            lines.append(f'    Sandbox_{mod_id}_{name}_tooltip = "{tooltip}",')

        if opt["type"] == "enum" and "options" in opt:
            for i, label in enumerate(opt["options"], start=1):
                lines.append(f'    Sandbox_{mod_id}_{name}_option{i} = "{label}",')

        lines.append("")

    lines.append("}")
    return "\n".join(lines) + "\n"


def generate_core_lua(mod_id, mod_name, author, options, events_used):
    """Generate the main ModNameCore.lua boilerplate."""
    prefix = _to_prefix(mod_id)
    sandbox_loader = _generate_sandbox_loader(mod_id, prefix, options)
    event_registrations = _generate_event_registrations(prefix, events_used)

    return textwrap.dedent(f"""\
--[[
    {mod_name}
    Author: {author}

    Main mod file. All shared logic goes here.

    Kahlua2 Compatibility Notes:
    - No goto/labels (Lua 5.2+ only)
    - No bitwise operators (use manual bit manipulation or lookup tables)
    - No table.pack/table.unpack (use unpack() directly)
    - Use instanceof() for Java type checks, not type()
    - String patterns work but some Lua 5.1+ extensions may be missing
    - See KAHLUA2_COMPAT.md for full details
--]]

-- ########################################################################
-- ##  LOGGING SYSTEM
-- ########################################################################

local DEBUG_MODE = false
local LOG_ENABLED = false

local LOG_LEVELS = {{ NONE = 0, ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4, TRACE = 5 }}
local currentLogLevel = LOG_LEVELS.NONE

local {prefix} = {{
    LOG_ENABLED = LOG_ENABLED,
}}

-- Cache standard print for minor speed benefit
local print = print

local function logToConsole(msg)
    if {prefix}.LOG_ENABLED then
        print(msg)
    end
end

function {prefix}.log(msg, category)
    if not {prefix}.LOG_ENABLED then return end
    local pfx = "[{prefix}"
    if category then
        pfx = pfx .. "/" .. tostring(category)
    end
    pfx = pfx .. "] "
    logToConsole(pfx .. tostring(msg))
end

local function debugPrint(msg, category, level)
    if not DEBUG_MODE then return end
    level = level or LOG_LEVELS.DEBUG
    if currentLogLevel < level then return end
    {prefix}.log(msg, category or "Debug")
end

-- ########################################################################
-- ##  SANDBOX SETTINGS
-- ########################################################################

{sandbox_loader}

-- ########################################################################
-- ##  CORE LOGIC
-- ########################################################################

-- TODO: Implement your mod logic here.
--
-- Common patterns:
--   local player = getPlayer()                    -- Get the local player (SP)
--   local onlinePlayers = getOnlinePlayers()       -- Get all players (MP)
--   local sq = player:getSquare()                  -- Get player's current tile
--   local cell = sq:getCell()                      -- Get the cell for the tile
--   instanceof(obj, "IsoZombie")                   -- Check Java type
--   SandboxVars.{mod_id}.OptionName                -- Read sandbox option
--   if isClient() then return end                  -- Skip on MP clients (server-only logic)
--   getGameSpeed()                                 -- 0 = paused, 1-4 = speed

-- ########################################################################
-- ##  EVENT REGISTRATIONS
-- ########################################################################

{event_registrations}
""")


def generate_client_lua(mod_id, mod_name, author):
    """Generate ModNameClient.lua boilerplate."""
    prefix = _to_prefix(mod_id)
    return textwrap.dedent(f"""\
--[[
    {mod_name} - Client Module
    Author: {author}

    Client-side logic. This file only runs on the client in MP,
    or in singleplayer. Use this for UI, rendering, input handling,
    and client-only event hooks.

    Key client-only events:
        OnPlayerUpdate          -- Fires every tick for the local player
        OnKeyPressed            -- Keyboard input
        OnMouseDown/Up          -- Mouse input
        OnRenderTick            -- Every render frame (use sparingly)
        OnPreUIDraw/OnPostUIDraw -- UI rendering hooks
        OnCreateUI              -- When UI is first created
        OnWorldSound            -- Sound events (client-only in MP)

    Important: Do NOT put server-authoritative logic here.
    In MP, clients cannot modify zombie health, spawn items, etc.
--]]

local {prefix}Client = {{}}

-- Example: Hook into player update for client-side checks
local function onPlayerUpdate(player)
    -- TODO: Client-side per-tick logic
end

-- ########################################################################
-- ##  EVENT REGISTRATIONS
-- ########################################################################

-- Events.OnPlayerUpdate.Add(onPlayerUpdate)
""")


def generate_server_lua(mod_id, mod_name, author):
    """Generate ModNameServer.lua boilerplate."""
    prefix = _to_prefix(mod_id)
    return textwrap.dedent(f"""\
--[[
    {mod_name} - Server Module
    Author: {author}

    Server-side logic. This file only runs on the server in MP,
    or in singleplayer. Use this for authoritative game logic,
    player management, and server commands.

    Key server events:
        OnClientCommand         -- Receive commands from clients
        EveryOneMinute          -- Fires every in-game minute
        EveryTenMinutes         -- Fires every 10 in-game minutes
        EveryHours              -- Fires every in-game hour
        EveryDays               -- Fires every in-game day
        OnNewGame               -- Server starts a new game

    Important: Server modules can modify game state authoritatively.
    Use sendServerCommand() to communicate with clients.
--]]

local {prefix}Server = {{}}

-- Example: Handle commands from clients
local function onClientCommand(module, command, player, args)
    if module ~= "{mod_id}" then return end

    -- TODO: Handle client commands
    -- if command == "myAction" then
    --     -- Process action server-side
    --     sendServerCommand(player, "{mod_id}", "myResponse", {{result = true}})
    -- end
end

-- ########################################################################
-- ##  EVENT REGISTRATIONS
-- ########################################################################

-- Events.OnClientCommand.Add(onClientCommand)
""")


# ============================================================================
# Helper functions
# ============================================================================

def _to_prefix(mod_id):
    """Convert mod ID to a short Lua variable prefix.
    e.g. 'BarricadesHurtZombiesB42' -> 'BHZ'
    Takes uppercase letters, max 5 chars. Falls back to first 3 of mod_id.
    """
    uppers = "".join(c for c in mod_id if c.isupper())
    if len(uppers) >= 2:
        return uppers[:5]
    return mod_id[:3].upper()


def _to_display_name(name):
    """Convert CamelCase option name to display name.
    e.g. 'BaseDamage' -> 'Base Damage'
    """
    result = []
    for i, c in enumerate(name):
        if c.isupper() and i > 0 and not name[i-1].isupper():
            result.append(" ")
        result.append(c)
    return "".join(result)


def _generate_sandbox_loader(mod_id, prefix, options):
    """Generate the sandbox settings loader function."""
    if not options:
        return textwrap.dedent(f"""\
local function onLoad()
    debugPrint("{prefix} mod loaded (no sandbox options)")
end

Events.OnLoad.Add(onLoad)
""")

    load_lines = []
    for opt in options:
        name = opt["name"]
        opt_type = opt["type"]
        default = opt.get("default", "")

        if opt_type == "boolean":
            default_lua = "true" if default else "false"
            load_lines.append(
                f"    -- {_to_display_name(name)}")
            load_lines.append(
                f"    local {_camel_to_local(name)} = sv.{name}")
            load_lines.append(
                f"    if {_camel_to_local(name)} == nil then {_camel_to_local(name)} = {default_lua} end")
            load_lines.append(
                f'    debugPrint("{name} = " .. tostring({_camel_to_local(name)}))')
        elif opt_type in ("integer", "double"):
            load_lines.append(
                f"    -- {_to_display_name(name)}")
            load_lines.append(
                f"    local {_camel_to_local(name)} = tonumber(sv.{name}) or {default}")
            load_lines.append(
                f'    debugPrint("{name} = " .. tostring({_camel_to_local(name)}))')
        elif opt_type == "enum":
            load_lines.append(
                f"    -- {_to_display_name(name)}")
            load_lines.append(
                f"    local {_camel_to_local(name)} = sv.{name} or {default}")
            load_lines.append(
                f'    debugPrint("{name} = " .. tostring({_camel_to_local(name)}))')
        else:
            load_lines.append(
                f"    -- {_to_display_name(name)}")
            load_lines.append(
                f"    local {_camel_to_local(name)} = sv.{name}")
            load_lines.append(
                f'    debugPrint("{name} = " .. tostring({_camel_to_local(name)}))')

        load_lines.append("")

    load_body = "\n".join(load_lines)

    return textwrap.dedent(f"""\
local function onLoad()
    debugPrint("Loading {prefix} sandbox settings...")

    local SandboxVars = SandboxVars
    if SandboxVars and SandboxVars.{mod_id} then
        local sv = SandboxVars.{mod_id}

{load_body}
        -- TODO: Apply loaded settings to your mod's runtime state.
        -- Example:
        --   {prefix}.SOME_VALUE = someValue

        debugPrint("{prefix} settings loaded successfully")
    else
        debugPrint("No sandbox config found, using defaults")
        -- TODO: Set default values here if sandbox settings are missing.
    end
end

Events.OnLoad.Add(onLoad)
""")


def _camel_to_local(name):
    """Convert CamelCase to camelCase for local variable names.
    e.g. 'BaseDamage' -> 'baseDamage'
    """
    if not name:
        return name
    return name[0].lower() + name[1:]


def _generate_event_registrations(prefix, events_used):
    """Generate event registration block."""
    if not events_used:
        return textwrap.dedent("""\
-- No events specified. Common PZ events you may want to use:
-- Events.OnLoad.Add(onLoad)                 -- Game world loaded
-- Events.OnTick.Add(onTick)                 -- Every game tick
-- Events.OnPlayerUpdate.Add(onPlayerUpdate) -- Per player, per tick
-- Events.EveryOneMinute.Add(onOneMinute)    -- Every in-game minute
-- Events.EveryTenMinutes.Add(onTenMinutes)  -- Every 10 in-game minutes
-- Events.EveryHours.Add(onHour)             -- Every in-game hour
-- Events.EveryDays.Add(onDay)               -- Every in-game day
""")

    lines = []
    # OnLoad is handled by the sandbox loader, so skip it here
    for event in events_used:
        if event == "OnLoad":
            lines.append(f"-- Events.OnLoad is registered above (sandbox settings loader)")
        else:
            handler = "on" + event.replace("On", "", 1) if event.startswith("On") else event
            # Convert EveryOneMinute -> onOneMinute etc.
            if event.startswith("Every"):
                handler = "on" + event[5:]
            lines.append(f"-- Events.{event}.Add({handler})")

    return "\n".join(lines) + "\n"


# ============================================================================
# Directory structure builder
# ============================================================================

def build_mod(config, output_dir):
    """Build the complete mod directory structure."""
    mod_id = config["mod_id"]
    mod_name = config["mod_name"]
    author = config.get("author", "Unknown")
    description = config.get("description", "A Project Zomboid mod.")
    version_min = config.get("version_min", "42.0")
    url = config.get("url", "")
    has_shared = config.get("has_shared_lua", True)
    has_client = config.get("has_client_lua", False)
    has_server = config.get("has_server_lua", False)
    has_sandbox = config.get("has_sandbox_options", False)
    has_common = config.get("has_common_folder", False)
    options = config.get("sandbox_options", []) if has_sandbox else []
    languages = config.get("languages", DEFAULT_LANGUAGES)
    events_used = config.get("events_used", [])

    # Derive a short name (no spaces) for file naming
    short_name = mod_id.replace(" ", "")
    prefix = _to_prefix(mod_id)

    # Root mod directory
    mod_root = Path(output_dir) / short_name
    mod_info_content = generate_mod_info(mod_name, mod_id, description, version_min, author, url)

    # --- Root level ---
    _write(mod_root / "mod.info", mod_info_content)
    _write(mod_root / "poster.png.txt",
           "Replace this file with an actual poster.png image (256x256 recommended).\n"
           "Delete this .txt file after adding the image.\n")

    # --- 42/ folder (Build 42 content) ---
    b42 = mod_root / "42"
    _write(b42 / "mod.info", mod_info_content)
    _write(b42 / "poster.png.txt",
           "Replace this file with an actual poster.png image (256x256 recommended).\n"
           "Delete this .txt file after adding the image.\n")

    # --- Sandbox options ---
    if has_sandbox and options:
        sandbox_content = generate_sandbox_options(mod_id, options)
        _write(b42 / "media" / "sandbox-options.txt", sandbox_content)

        # Translations
        translate_base = b42 / "media" / "lua" / "shared" / "Translate"
        en_content = generate_translation_en(mod_id, mod_name, options)
        _write(translate_base / "EN" / "Sandbox_EN.txt", en_content)

        for lang in languages:
            if lang == "EN":
                continue
            placeholder = generate_translation_placeholder(lang, mod_id, mod_name, options)
            _write(translate_base / lang / f"Sandbox_{lang}.txt", placeholder)

    # --- Shared Lua ---
    if has_shared:
        core_content = generate_core_lua(mod_id, mod_name, author, options, events_used)
        _write(b42 / "media" / "lua" / "shared" / f"{prefix}Core.lua", core_content)

    # --- Client Lua ---
    if has_client:
        client_content = generate_client_lua(mod_id, mod_name, author)
        _write(b42 / "media" / "lua" / "client" / f"{prefix}Client.lua", client_content)

    # --- Server Lua ---
    if has_server:
        server_content = generate_server_lua(mod_id, mod_name, author)
        _write(b42 / "media" / "lua" / "server" / f"{prefix}Server.lua", server_content)

    # --- Common folder (B41 compatibility / SVU3 pattern) ---
    if has_common:
        common = mod_root / "common"
        _write(common / "mod.info", mod_info_content)
        _write(common / "poster.png.txt",
               "Replace this file with an actual poster.png image.\n"
               "Delete this .txt file after adding the image.\n")

        if has_sandbox and options:
            _write(common / "sandbox-options.txt",
                   generate_sandbox_options(mod_id, options))

            translate_common = common / "media" / "lua" / "shared" / "Translate"
            _write(translate_common / "EN" / "Sandbox_EN.txt",
                   generate_translation_en(mod_id, mod_name, options))

            for lang in languages:
                if lang == "EN":
                    continue
                placeholder = generate_translation_placeholder(lang, mod_id, mod_name, options)
                _write(translate_common / lang / f"Sandbox_{lang}.txt", placeholder)

    # --- Workshop file ---
    _write(mod_root / "workshop.txt", textwrap.dedent(f"""\
        version=1
        id=
        title={mod_name}
        description={description}
        tags=Build 42;
        visibility=public
    """).lstrip())

    return mod_root


def _write(path, content):
    """Write content to a file, creating directories as needed."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print(f"  Created: {path}")


# ============================================================================
# Interactive mode
# ============================================================================

def interactive_mode():
    """Guide the user through mod creation interactively."""
    print("=" * 60)
    print("  Project Zomboid Mod Generator (Build 42)")
    print("=" * 60)
    print()

    config = {}

    config["mod_name"] = input("Mod display name (e.g. 'My Cool Mod'): ").strip()
    if not config["mod_name"]:
        print("Error: Mod name is required.")
        sys.exit(1)

    default_id = config["mod_name"].replace(" ", "") + "B42"
    config["mod_id"] = input(f"Mod ID [{default_id}]: ").strip() or default_id
    config["author"] = input("Author name: ").strip() or "Unknown"
    config["description"] = input("Description: ").strip() or "A Project Zomboid mod."
    config["version_min"] = input("Minimum version [42.0]: ").strip() or "42.0"
    config["url"] = input("URL (optional): ").strip()

    config["has_shared_lua"] = _ask_bool("Include shared Lua?", True)
    config["has_client_lua"] = _ask_bool("Include client Lua?", False)
    config["has_server_lua"] = _ask_bool("Include server Lua?", False)
    config["has_sandbox_options"] = _ask_bool("Include sandbox options?", True)
    config["has_common_folder"] = _ask_bool("Include common/ folder (B41 compat)?", True)

    config["sandbox_options"] = []
    if config["has_sandbox_options"]:
        print("\nDefine sandbox options (press Enter with empty name to finish):")
        while True:
            name = input("  Option name (CamelCase, e.g. 'BaseDamage'): ").strip()
            if not name:
                break
            opt = {"name": name}
            opt["type"] = input("  Type [boolean/integer/double/enum]: ").strip() or "boolean"
            if opt["type"] in ("integer", "double"):
                opt["default"] = float(input("  Default value: ").strip() or "0")
                opt["min"] = float(input("  Min value: ").strip() or "0")
                opt["max"] = float(input("  Max value: ").strip() or "100")
                if opt["type"] == "integer":
                    opt["default"] = int(opt["default"])
                    opt["min"] = int(opt["min"])
                    opt["max"] = int(opt["max"])
            elif opt["type"] == "boolean":
                opt["default"] = _ask_bool("  Default value?", True)
            elif opt["type"] == "enum":
                opt["num_values"] = int(input("  Number of values: ").strip() or "2")
                opt["default"] = int(input("  Default (1-based index): ").strip() or "1")
                opt["options"] = []
                for i in range(opt["num_values"]):
                    label = input(f"  Label for option {i+1}: ").strip() or f"Option {i+1}"
                    opt["options"].append(label)
            opt["tooltip"] = input("  Tooltip text: ").strip()
            config["sandbox_options"].append(opt)
            print()

    config["languages"] = DEFAULT_LANGUAGES

    events_input = input("\nEvents to hook (comma-separated, e.g. 'OnLoad,OnTick'): ").strip()
    if events_input:
        config["events_used"] = [e.strip() for e in events_input.split(",") if e.strip()]
    else:
        config["events_used"] = ["OnLoad"]

    return config


def _ask_bool(prompt, default=True):
    """Ask a yes/no question."""
    suffix = " [Y/n]: " if default else " [y/N]: "
    answer = input(prompt + suffix).strip().lower()
    if not answer:
        return default
    return answer in ("y", "yes", "1", "true")


# ============================================================================
# Config file generation
# ============================================================================

def generate_example_config(output_path):
    """Write an example config file to the given path."""
    example = {
        "mod_name": "My Cool Mod",
        "mod_id": "MyCoolModB42",
        "author": "YourName",
        "description": "A Project Zomboid mod that does cool things.",
        "version_min": "42.0",
        "url": "",
        "has_shared_lua": True,
        "has_client_lua": False,
        "has_server_lua": False,
        "has_sandbox_options": True,
        "has_common_folder": True,
        "sandbox_options": [
            {
                "name": "Enabled",
                "type": "boolean",
                "default": True,
                "tooltip": "Enable or disable the mod"
            },
            {
                "name": "Strength",
                "type": "double",
                "default": 1.0,
                "min": 0.0,
                "max": 10.0,
                "tooltip": "How strong the effect is"
            },
            {
                "name": "Mode",
                "type": "enum",
                "num_values": 3,
                "default": 1,
                "tooltip": "Which mode to use",
                "options": ["Easy", "Normal", "Hard"]
            },
            {
                "name": "UpdateInterval",
                "type": "integer",
                "default": 100,
                "min": 10,
                "max": 1000,
                "tooltip": "How often to run updates (in ticks)"
            }
        ],
        "languages": DEFAULT_LANGUAGES,
        "events_used": ["OnLoad", "OnTick"]
    }

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(example, f, indent=4)
    print(f"Example config written to: {output_path}")


# ============================================================================
# Main
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Project Zomboid Mod Generator - Creates complete B42 mod skeletons",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent("""\
            Examples:
              python generate_pz_mod.py                          # Interactive mode
              python generate_pz_mod.py --config my_mod.json     # From config file
              python generate_pz_mod.py --example-config          # Generate example config
              python generate_pz_mod.py --name "My Mod" --id "MyModB42" --author "Me"
        """)
    )

    parser.add_argument("--config", "-c", help="Path to JSON config file")
    parser.add_argument("--output", "-o", default=".", help="Output directory (default: current dir)")
    parser.add_argument("--name", help="Mod display name")
    parser.add_argument("--id", help="Mod ID")
    parser.add_argument("--author", help="Author name")
    parser.add_argument("--description", help="Mod description")
    parser.add_argument("--version-min", default="42.0", help="Minimum PZ version")
    parser.add_argument("--example-config", action="store_true",
                        help="Generate an example config file and exit")

    args = parser.parse_args()

    # Generate example config
    if args.example_config:
        generate_example_config(os.path.join(args.output, "example_mod_config.json"))
        return

    # Load config from file
    if args.config:
        with open(args.config, "r", encoding="utf-8") as f:
            config = json.load(f)
        print(f"Loaded config from: {args.config}")

    # Build config from CLI args
    elif args.name and args.id:
        config = {
            "mod_name": args.name,
            "mod_id": args.id,
            "author": args.author or "Unknown",
            "description": args.description or "A Project Zomboid mod.",
            "version_min": args.version_min,
            "has_shared_lua": True,
            "has_client_lua": False,
            "has_server_lua": False,
            "has_sandbox_options": False,
            "has_common_folder": True,
            "sandbox_options": [],
            "languages": DEFAULT_LANGUAGES,
            "events_used": ["OnLoad"],
        }

    # Interactive mode
    else:
        config = interactive_mode()

    # Build the mod
    print(f"\nGenerating mod: {config['mod_name']} ({config['mod_id']})")
    print(f"Output directory: {os.path.abspath(args.output)}")
    print("-" * 40)

    mod_root = build_mod(config, args.output)

    print("-" * 40)
    print(f"\nMod generated successfully at: {mod_root}")
    print("\nNext steps:")
    print(f"  1. Replace poster.png.txt files with actual poster.png images (256x256)")
    print(f"  2. Edit the generated Lua files to add your mod logic")
    if config.get("has_sandbox_options"):
        print(f"  3. Translate sandbox option strings in the Translate/ folders")
    print(f"  4. Copy the mod folder into your PZ mods directory or use a symlink for development")
    print(f"     Typical path: C:\\Users\\<you>\\Zomboid\\mods\\{config['mod_id']}\\")


if __name__ == "__main__":
    main()
