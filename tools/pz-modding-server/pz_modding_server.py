#!/usr/bin/env python3
"""
Project Zomboid Modding MCP Server
===================================
A Model Context Protocol server providing PZ-specific modding tools:
  - generate_mod: Create complete B42 mod skeletons
  - validate_lua: Check Lua code for Kahlua2 compatibility issues
  - search_events: Search PZ event reference by name or category
  - generate_sandbox: Generate sandbox-options.txt from a list of options
  - generate_translations: Generate translation files for sandbox options
  - decompile_class: Decompile a PZ Java class (requires mcp-javadc)
  - analyze_mod: Analyze an existing PZ mod's structure and report issues

Built with FastMCP for the game modding MCP toolkit.
"""

import json
import os
import re
import sys
from pathlib import Path
from typing import Optional

from fastmcp import FastMCP

# ---------------------------------------------------------------------------
# Server setup
# ---------------------------------------------------------------------------

mcp = FastMCP(
    "pz-modding",
    instructions=(
        "Project Zomboid B42 modding assistant. "
        "Provides tools for generating mods, validating Lua code against "
        "Kahlua2 limitations, searching the PZ event system, and generating "
        "sandbox options and translation files."
    ),
)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

TOOLS_DIR = Path(__file__).parent.parent / "pz-mod-generator"
EVENTS_REF = TOOLS_DIR / "PZ_EVENTS_REFERENCE.md"
KAHLUA2_REF = TOOLS_DIR / "KAHLUA2_COMPAT.md"

# Add the generator to the path so we can import it
sys.path.insert(0, str(TOOLS_DIR))

# ---------------------------------------------------------------------------
# Kahlua2 incompatibility patterns
# ---------------------------------------------------------------------------

KAHLUA2_ISSUES = [
    {
        "pattern": r"\bgoto\b\s+\w+",
        "severity": "ERROR",
        "message": "goto/labels not supported in Kahlua2 (Lua 5.2+ feature). Use if/while/repeat instead.",
    },
    {
        "pattern": r"::\w+::",
        "severity": "ERROR",
        "message": "Labels (::name::) not supported in Kahlua2. Restructure without goto/labels.",
    },
    {
        "pattern": r"[^-](?:&|>>|<<|~)\s*\d",
        "severity": "ERROR",
        "message": "Bitwise operators not supported in Kahlua2 (Lua 5.3+ feature). Use math.floor(a/b) for integer division, value % 256 for masking.",
    },
    {
        "pattern": r"\btable\.pack\b",
        "severity": "ERROR",
        "message": "table.pack() not available in Kahlua2. Use {...} instead.",
    },
    {
        "pattern": r"\btable\.unpack\b",
        "severity": "ERROR",
        "message": "table.unpack() not available in Kahlua2. Use global unpack() instead.",
    },
    {
        "pattern": r"\btable\.move\b",
        "severity": "ERROR",
        "message": "table.move() not available in Kahlua2. Use a manual loop copy.",
    },
    {
        "pattern": r"\bstring\.pack\b|\bstring\.unpack\b",
        "severity": "ERROR",
        "message": "string.pack/unpack not available in Kahlua2 (Lua 5.3+).",
    },
    {
        "pattern": r"\bio\.open\b|\bio\.read\b|\bio\.write\b",
        "severity": "ERROR",
        "message": "io library not available in Kahlua2. Use getFileReader()/getFileWriter() instead.",
    },
    {
        "pattern": r"\bos\.\w+",
        "severity": "ERROR",
        "message": "os library not available in Kahlua2. Use Java interop for OS operations.",
    },
    {
        "pattern": r"\bcoroutine\.\w+",
        "severity": "ERROR",
        "message": "coroutine library not available in Kahlua2.",
    },
    {
        "pattern": r"\bdebug\.\w+",
        "severity": "ERROR",
        "message": "debug library not available in Kahlua2.",
    },
    {
        "pattern": r"//",
        "severity": "WARNING",
        "message": "Integer division (//) not supported in Kahlua2 (Lua 5.3+). Use math.floor(a/b).",
        "context_check": "not_in_string_or_comment",
    },
    {
        "pattern": r"\btype\(\w+\)\s*==\s*[\"']Iso",
        "severity": "WARNING",
        "message": "type() returns 'userdata' for Java objects. Use instanceof(obj, 'ClassName') instead.",
    },
    {
        "pattern": r":Kill\(nil\)",
        "severity": "WARNING",
        "message": "zombie:Kill(nil) may cause issues in B42. Use zombie:Kill(zombie) for self-kill.",
    },
    {
        "pattern": r"\.Is\([\"'][^\"']+[\"']\)\s*==",
        "severity": "WARNING",
        "message": "Single-arg Is() comparison may fail. Use two-arg form: props:Is('Material', 'Metal').",
    },
    {
        "pattern": r"\bgetPlayer\(\)",
        "severity": "INFO",
        "message": "getPlayer() returns nil on dedicated servers. Use isClient() guard or getOnlinePlayers() for MP support.",
    },
    {
        "pattern": r"Events\.OnWorldSound\.Add",
        "severity": "WARNING",
        "message": "OnWorldSound is CLIENT-ONLY in multiplayer. Server never receives this event. Use OnTick with state polling for server-authoritative logic.",
    },
    {
        "pattern": r"\butf8\.\w+",
        "severity": "ERROR",
        "message": "utf8 library not available in Kahlua2 (Lua 5.3+).",
    },
]

# ---------------------------------------------------------------------------
# PZ Events database (parsed from reference)
# ---------------------------------------------------------------------------

PZ_EVENTS = {
    # Game Lifecycle
    "OnLoad": {"params": "()", "fires_on": "Client and Server", "category": "lifecycle", "description": "Called when the game world has finished loading. Use for initialization and reading SandboxVars."},
    "OnGameStart": {"params": "()", "fires_on": "Client and Server", "category": "lifecycle", "description": "Called after the game has fully started and the player exists."},
    "OnPreGameStart": {"params": "()", "fires_on": "Client and Server", "category": "lifecycle", "description": "Called before the game starts, after mods are loaded."},
    "OnNewGame": {"params": "(player, square)", "fires_on": "Client and Server", "category": "lifecycle", "description": "Called when a new game is started (not loaded from save)."},
    "OnMainMenuEnter": {"params": "()", "fires_on": "Client", "category": "lifecycle", "description": "Called when returning to the main menu."},
    "OnGameBoot": {"params": "()", "fires_on": "Client", "category": "lifecycle", "description": "Called once when the game application first starts."},
    # Tick/Update
    "OnTick": {"params": "(numTicks)", "fires_on": "Client and Server", "category": "tick", "description": "Called every game tick. Fires more frequently at higher game speeds (~60/sec at speed 1)."},
    "OnTickEvenPaused": {"params": "(numTicks)", "fires_on": "Client and Server", "category": "tick", "description": "Like OnTick but continues firing when game is paused."},
    "OnPlayerUpdate": {"params": "(player)", "fires_on": "Client", "category": "tick", "description": "Called every tick for each local player."},
    "OnRenderTick": {"params": "()", "fires_on": "Client only", "category": "tick", "description": "Called every render frame. Keep extremely lightweight."},
    # Time
    "EveryOneMinute": {"params": "()", "fires_on": "Client and Server", "category": "time", "description": "Called every in-game minute."},
    "EveryTenMinutes": {"params": "()", "fires_on": "Client and Server", "category": "time", "description": "Called every 10 in-game minutes."},
    "EveryHours": {"params": "()", "fires_on": "Client and Server", "category": "time", "description": "Called every in-game hour."},
    "EveryDays": {"params": "()", "fires_on": "Client and Server", "category": "time", "description": "Called every in-game day."},
    # Player
    "OnPlayerMove": {"params": "(player)", "fires_on": "Client", "category": "player", "description": "Called when a player moves to a new position."},
    "OnPlayerDeath": {"params": "(player)", "fires_on": "Client and Server", "category": "player", "description": "Called when the player dies."},
    "OnCreatePlayer": {"params": "(playerIndex, player)", "fires_on": "Client and Server", "category": "player", "description": "Called when a player character is created."},
    "OnPlayerGetDamage": {"params": "(player, damageType, damage)", "fires_on": "Client and Server", "category": "player", "description": "Called when a player takes damage."},
    "OnEquipPrimary": {"params": "(player, item)", "fires_on": "Client", "category": "player", "description": "Called when primary weapon/item changes."},
    "OnEquipSecondary": {"params": "(player, item)", "fires_on": "Client", "category": "player", "description": "Called when secondary weapon/item changes."},
    "LevelPerk": {"params": "(player, perk, level, addedLevels)", "fires_on": "Client and Server", "category": "player", "description": "Called when a player's perk level changes."},
    # Zombie
    "OnZombieDead": {"params": "(zombie)", "fires_on": "Client and Server", "category": "zombie", "description": "Called when a zombie dies."},
    "OnZombieUpdate": {"params": "(zombie)", "fires_on": "Server (and SP)", "category": "zombie", "description": "Called each tick for each zombie being updated. VERY expensive."},
    # Vehicle
    "OnEnterVehicle": {"params": "(player)", "fires_on": "Client and Server", "category": "vehicle", "description": "Called when a player enters a vehicle."},
    "OnExitVehicle": {"params": "(player)", "fires_on": "Client and Server", "category": "vehicle", "description": "Called when a player exits a vehicle."},
    "OnUseVehicle": {"params": "(player, vehicle, pressedNotTapped)", "fires_on": "Client", "category": "vehicle", "description": "Called when a player interacts with a vehicle."},
    # Building
    "OnDoTileBuilding": {"params": "(draggingInfo, isRender, x, y, z, square)", "fires_on": "Client", "category": "building", "description": "Called during construction placement."},
    "OnObjectAdded": {"params": "(object)", "fires_on": "Client and Server", "category": "building", "description": "Called when a new object is added to the world."},
    # Inventory
    "OnFillInventoryObjectContextMenu": {"params": "(playerIndex, context, items)", "fires_on": "Client", "category": "inventory", "description": "Called when building the right-click context menu for inventory items."},
    "OnFillWorldObjectContextMenu": {"params": "(playerIndex, context, worldObjects, test)", "fires_on": "Client", "category": "inventory", "description": "Called when building right-click context menu for world objects."},
    "OnContainerUpdate": {"params": "(container)", "fires_on": "Client and Server", "category": "inventory", "description": "Called when a container's contents change."},
    # Combat
    "OnWeaponHitCharacter": {"params": "(attacker, target, weapon, damage)", "fires_on": "Client and Server", "category": "combat", "description": "Called when a weapon hits a character."},
    "OnWeaponSwing": {"params": "(player, weapon)", "fires_on": "Client", "category": "combat", "description": "Called when a player swings a weapon."},
    "OnWeaponHitXp": {"params": "(player, weapon, target, damage)", "fires_on": "Client and Server", "category": "combat", "description": "Called for XP calculation on weapon hit."},
    # Sound
    "OnWorldSound": {"params": "(x, y, z, radius, volume, source)", "fires_on": "Client only", "category": "sound", "description": "Called when a sound is emitted. CLIENT-ONLY even in MP - do NOT use for server logic."},
    # Weather
    "OnRainStart": {"params": "()", "fires_on": "Client and Server", "category": "weather", "description": "Called when rain begins."},
    "OnRainStop": {"params": "()", "fires_on": "Client and Server", "category": "weather", "description": "Called when rain stops."},
    "OnThunderEvent": {"params": "(x, y, strike)", "fires_on": "Client and Server", "category": "weather", "description": "Called during a thunder event."},
    # UI
    "OnCreateUI": {"params": "()", "fires_on": "Client", "category": "ui", "description": "Called once when the game UI is first created."},
    "OnPreUIDraw": {"params": "()", "fires_on": "Client", "category": "ui", "description": "Called before UI elements are drawn each frame."},
    "OnPostUIDraw": {"params": "()", "fires_on": "Client", "category": "ui", "description": "Called after UI elements are drawn each frame."},
    "OnKeyPressed": {"params": "(key)", "fires_on": "Client", "category": "ui", "description": "Called when a key is pressed."},
    "OnKeyStartPressed": {"params": "(key)", "fires_on": "Client", "category": "ui", "description": "Called at the start of a key press."},
    "OnMouseDown": {"params": "(x, y)", "fires_on": "Client", "category": "ui", "description": "Called on mouse button press."},
    "OnMouseUp": {"params": "(x, y)", "fires_on": "Client", "category": "ui", "description": "Called on mouse button release."},
    # Multiplayer
    "OnClientCommand": {"params": "(module, command, player, args)", "fires_on": "Server only", "category": "multiplayer", "description": "Called on server when a client sends a command."},
    "OnServerCommand": {"params": "(module, command, args)", "fires_on": "Client only", "category": "multiplayer", "description": "Called on clients when server sends a command."},
    "OnConnected": {"params": "()", "fires_on": "Client", "category": "multiplayer", "description": "Called when client connects to a server."},
    "OnDisconnect": {"params": "()", "fires_on": "Client", "category": "multiplayer", "description": "Called when disconnected from a server."},
    # Save/Load
    "OnSave": {"params": "()", "fires_on": "Client and Server", "category": "save", "description": "Called when the game saves."},
    "OnPreSave": {"params": "()", "fires_on": "Client and Server", "category": "save", "description": "Called just before a save begins."},
    "OnLoadedTileDefinitions": {"params": "(spriteManager)", "fires_on": "Client and Server", "category": "save", "description": "Called after tile definitions are loaded."},
    # Crafting
    "OnMakeItem": {"params": "(resultItem, player, recipe, ingredients)", "fires_on": "Client and Server", "category": "crafting", "description": "Called when a crafting recipe produces an item."},
}

# ---------------------------------------------------------------------------
# Tool: generate_mod
# ---------------------------------------------------------------------------

@mcp.tool()
def generate_mod(
    mod_name: str,
    mod_id: str,
    author: str,
    description: str = "A Project Zomboid mod.",
    version_min: str = "42.0",
    output_dir: str = ".",
    has_shared_lua: bool = True,
    has_client_lua: bool = False,
    has_server_lua: bool = False,
    has_sandbox_options: bool = False,
    has_common_folder: bool = True,
    sandbox_options_json: str = "[]",
    events_used: str = "OnLoad",
) -> str:
    """Generate a complete Project Zomboid B42 mod skeleton.

    Creates the full directory structure with mod.info, sandbox options,
    translation files, and Lua boilerplate following PZ Build 42 conventions.

    Args:
        mod_name: Display name (e.g. "My Cool Mod")
        mod_id: Unique identifier (e.g. "MyCoolModB42")
        author: Author name
        description: Mod description
        version_min: Minimum PZ version (default "42.0")
        output_dir: Where to create the mod (default current directory)
        has_shared_lua: Include shared Lua module
        has_client_lua: Include client-only Lua module
        has_server_lua: Include server-only Lua module
        has_sandbox_options: Include sandbox options
        has_common_folder: Include common/ folder for B41 compat
        sandbox_options_json: JSON array of sandbox options (see example)
        events_used: Comma-separated list of PZ events to hook
    """
    try:
        from generate_pz_mod import build_mod
    except ImportError:
        return f"ERROR: Could not import generate_pz_mod from {TOOLS_DIR}. Ensure the file exists."

    try:
        options = json.loads(sandbox_options_json) if sandbox_options_json else []
    except json.JSONDecodeError as e:
        return f"ERROR: Invalid sandbox_options_json: {e}"

    config = {
        "mod_name": mod_name,
        "mod_id": mod_id,
        "author": author,
        "description": description,
        "version_min": version_min,
        "has_shared_lua": has_shared_lua,
        "has_client_lua": has_client_lua,
        "has_server_lua": has_server_lua,
        "has_sandbox_options": has_sandbox_options,
        "has_common_folder": has_common_folder,
        "sandbox_options": options,
        "languages": ["EN", "CH", "DE", "ES", "FR", "JP", "KR", "RU"],
        "events_used": [e.strip() for e in events_used.split(",") if e.strip()],
    }

    try:
        mod_root = build_mod(config, output_dir)
        return f"Mod generated successfully at: {mod_root}\n\nNext steps:\n1. Replace poster.png.txt with actual poster.png (256x256)\n2. Edit the Lua files to add your mod logic\n3. Copy to your PZ mods directory"
    except Exception as e:
        return f"ERROR generating mod: {e}"


# ---------------------------------------------------------------------------
# Tool: validate_lua
# ---------------------------------------------------------------------------

@mcp.tool()
def validate_lua(
    lua_code: str,
    check_mp_safety: bool = True,
) -> str:
    """Validate Lua code for Kahlua2/PZ compatibility issues.

    Checks for unsupported Lua features (goto, bitwise ops, missing libraries),
    common PZ modding mistakes (wrong Kill() args, single-arg Is(), getPlayer()
    in MP), and optionally checks for multiplayer safety.

    Args:
        lua_code: The Lua source code to validate
        check_mp_safety: Also check for MP compatibility issues
    """
    issues = []
    lines = lua_code.split("\n")

    for line_num, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("--"):
            continue

        for check in KAHLUA2_ISSUES:
            # Skip MP checks if not requested
            if not check_mp_safety and check["severity"] == "INFO":
                continue

            if re.search(check["pattern"], line):
                # Extra check for // (could be in a comment or string)
                if check.get("context_check") == "not_in_string_or_comment":
                    # Simple heuristic: skip if in a string or comment
                    before_match = line[:line.find("//")]
                    if before_match.count('"') % 2 == 1 or before_match.count("'") % 2 == 1:
                        continue
                    if "--" in before_match:
                        continue

                issues.append({
                    "line": line_num,
                    "severity": check["severity"],
                    "message": check["message"],
                    "code": stripped[:80],
                })

    if not issues:
        return "No Kahlua2 compatibility issues found. Code looks clean."

    # Format output
    result_lines = [f"Found {len(issues)} issue(s):\n"]

    errors = [i for i in issues if i["severity"] == "ERROR"]
    warnings = [i for i in issues if i["severity"] == "WARNING"]
    infos = [i for i in issues if i["severity"] == "INFO"]

    if errors:
        result_lines.append(f"## ERRORS ({len(errors)})")
        for i in errors:
            result_lines.append(f"  Line {i['line']}: {i['message']}")
            result_lines.append(f"    Code: {i['code']}")
        result_lines.append("")

    if warnings:
        result_lines.append(f"## WARNINGS ({len(warnings)})")
        for i in warnings:
            result_lines.append(f"  Line {i['line']}: {i['message']}")
            result_lines.append(f"    Code: {i['code']}")
        result_lines.append("")

    if infos:
        result_lines.append(f"## INFO ({len(infos)})")
        for i in infos:
            result_lines.append(f"  Line {i['line']}: {i['message']}")
            result_lines.append(f"    Code: {i['code']}")

    return "\n".join(result_lines)


# ---------------------------------------------------------------------------
# Tool: search_events
# ---------------------------------------------------------------------------

@mcp.tool()
def search_events(
    query: str = "",
    category: str = "",
    fires_on: str = "",
) -> str:
    """Search the Project Zomboid event reference.

    Find events by name, category, or where they fire. Returns matching events
    with their signatures, descriptions, and firing context.

    Args:
        query: Search term for event name or description (case-insensitive)
        category: Filter by category (lifecycle, tick, time, player, zombie,
                  vehicle, building, inventory, combat, sound, weather, ui,
                  multiplayer, save, crafting)
        fires_on: Filter by firing context ("client", "server", or "both")
    """
    results = []
    query_lower = query.lower() if query else ""
    category_lower = category.lower() if category else ""
    fires_lower = fires_on.lower() if fires_on else ""

    for name, info in PZ_EVENTS.items():
        # Filter by query
        if query_lower:
            if (query_lower not in name.lower() and
                query_lower not in info["description"].lower()):
                continue

        # Filter by category
        if category_lower and info["category"] != category_lower:
            continue

        # Filter by fires_on
        if fires_lower:
            event_fires = info["fires_on"].lower()
            if fires_lower == "server" and "server" not in event_fires:
                continue
            if fires_lower == "client" and "client" not in event_fires:
                continue
            if fires_lower == "both" and "and" not in event_fires:
                continue

        results.append((name, info))

    if not results:
        categories = sorted(set(e["category"] for e in PZ_EVENTS.values()))
        return f"No events found matching your criteria.\n\nAvailable categories: {', '.join(categories)}\nTotal events in database: {len(PZ_EVENTS)}"

    lines = [f"Found {len(results)} event(s):\n"]
    for name, info in sorted(results, key=lambda x: x[0]):
        lines.append(f"### {name}")
        lines.append(f"  Signature: Events.{name}.Add(function{info['params']} ... end)")
        lines.append(f"  Fires on: {info['fires_on']}")
        lines.append(f"  Category: {info['category']}")
        lines.append(f"  {info['description']}")
        lines.append("")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Tool: generate_sandbox
# ---------------------------------------------------------------------------

@mcp.tool()
def generate_sandbox(
    mod_id: str,
    options_json: str,
    version: int = 3,
) -> str:
    """Generate a PZ sandbox-options.txt file from a JSON spec.

    Args:
        mod_id: The mod's unique identifier
        options_json: JSON array of option objects. Each needs: name, type
                      (boolean/integer/double/enum/string), default, and
                      optionally min, max, num_values, tooltip.
        version: Sandbox options version number (default 3)
    """
    try:
        options = json.loads(options_json)
    except json.JSONDecodeError as e:
        return f"ERROR: Invalid JSON: {e}"

    if not options:
        return "ERROR: No options provided."

    type_templates = {
        "boolean": "    type = boolean,\n    default = {default},",
        "integer": "    type = integer,\n    min = {min},\n    max = {max},\n    default = {default},",
        "double": "    type = double,\n    min = {min},\n    max = {max},\n    default = {default},",
        "enum": "    type = enum,\n    numValues = {num_values},\n    default = {default},",
        "string": '    type = string,\n    default = {default},',
    }

    lines = [f"VERSION = {version},", ""]

    for opt in options:
        name = opt.get("name", "UnnamedOption")
        opt_type = opt.get("type", "boolean")

        lines.append(f"option {mod_id}.{name}")
        lines.append("{")

        if opt_type in type_templates:
            template = type_templates[opt_type]
            fmt_args = {
                "default": str(opt.get("default", "")).lower() if opt_type == "boolean" else opt.get("default", ""),
                "min": opt.get("min", 0),
                "max": opt.get("max", 100),
                "num_values": opt.get("num_values", 2),
            }
            lines.append(template.format(**fmt_args))
        else:
            lines.append(f"    type = {opt_type},")
            lines.append(f"    default = {opt.get('default', '')},")

        lines.append(f"    page = {mod_id},")
        lines.append(f"    translation = {mod_id}_{name},")
        lines.append("}")
        lines.append("")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Tool: generate_translations
# ---------------------------------------------------------------------------

@mcp.tool()
def generate_translations(
    mod_id: str,
    mod_name: str,
    options_json: str,
    language: str = "EN",
) -> str:
    """Generate a PZ Sandbox translation file for the given language.

    Args:
        mod_id: The mod's unique identifier
        mod_name: Display name of the mod
        options_json: JSON array of option objects with name, type, default,
                      tooltip, and optionally display_name and options (for enums)
        language: Language code (EN, CH, DE, ES, FR, JP, KR, RU)
    """
    try:
        options = json.loads(options_json)
    except json.JSONDecodeError as e:
        return f"ERROR: Invalid JSON: {e}"

    lang = language.upper()
    lines = [
        f"Sandbox_{lang} = {{",
        f'    Sandbox_{mod_id} = "{mod_name}",',
        "",
    ]

    for opt in options:
        name = opt.get("name", "Option")
        display = opt.get("display_name", _to_display_name(name))
        tooltip = opt.get("tooltip", "")
        default_str = ""
        if "default" in opt:
            default_str = f" (Default: {opt['default']})"

        if lang != "EN":
            lines.append(f"    -- TODO: Translate to {lang}")

        lines.append(f'    Sandbox_{mod_id}_{name} = "{display}{default_str}",')
        if tooltip:
            lines.append(f'    Sandbox_{mod_id}_{name}_tooltip = "{tooltip}",')

        if opt.get("type") == "enum" and "options" in opt:
            for i, label in enumerate(opt["options"], start=1):
                lines.append(f'    Sandbox_{mod_id}_{name}_option{i} = "{label}",')

        lines.append("")

    lines.append("}")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Tool: analyze_mod
# ---------------------------------------------------------------------------

@mcp.tool()
def analyze_mod(mod_path: str) -> str:
    """Analyze an existing PZ mod's directory structure and report issues.

    Checks for: missing mod.info, missing poster, sandbox options without
    translations, Lua files without proper event registrations, and
    Kahlua2 compatibility issues in all Lua files.

    Args:
        mod_path: Path to the mod's root directory
    """
    mod_dir = Path(mod_path)
    if not mod_dir.exists():
        return f"ERROR: Path does not exist: {mod_path}"

    issues = []
    info_lines = []

    # Check mod.info
    mod_info = mod_dir / "mod.info"
    if mod_info.exists():
        content = mod_info.read_text(encoding="utf-8", errors="replace")
        info_lines.append(f"mod.info found: {_parse_mod_info(content)}")

        if "versionMin=42" not in content:
            issues.append("WARNING: mod.info does not specify versionMin=42.x")
    else:
        issues.append("ERROR: No mod.info found at root level")

    # Check for B42 folder
    b42_dir = mod_dir / "42"
    if b42_dir.exists():
        info_lines.append("B42 folder: Present")
        b42_info = b42_dir / "mod.info"
        if not b42_info.exists():
            issues.append("WARNING: No mod.info in 42/ folder")
    else:
        issues.append("INFO: No 42/ folder (B42-specific content)")

    # Check for common folder
    common_dir = mod_dir / "common"
    if common_dir.exists():
        info_lines.append("Common folder: Present")

    # Check poster
    has_poster = False
    for d in [mod_dir, b42_dir, common_dir]:
        if d.exists() and (d / "poster.png").exists():
            has_poster = True
            break
    if not has_poster:
        issues.append("WARNING: No poster.png found")

    # Check sandbox options
    sandbox_files = list(mod_dir.rglob("sandbox-options.txt"))
    if sandbox_files:
        info_lines.append(f"Sandbox options: {len(sandbox_files)} file(s)")
        for sf in sandbox_files:
            content = sf.read_text(encoding="utf-8", errors="replace")
            if "VERSION" not in content:
                issues.append(f"WARNING: {sf.relative_to(mod_dir)} missing VERSION header")
    else:
        info_lines.append("Sandbox options: None")

    # Check translations
    translate_dirs = list(mod_dir.rglob("Translate"))
    if translate_dirs:
        for td in translate_dirs:
            en_dir = td / "EN"
            if not en_dir.exists():
                issues.append(f"ERROR: Missing EN translation in {td.relative_to(mod_dir)}")
    elif sandbox_files:
        issues.append("WARNING: Sandbox options exist but no Translate/ directory found")

    # Find and validate Lua files
    lua_files = list(mod_dir.rglob("*.lua"))
    info_lines.append(f"Lua files: {len(lua_files)}")

    lua_issues_count = 0
    for lf in lua_files:
        try:
            content = lf.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue

        for line_num, line in enumerate(content.split("\n"), 1):
            stripped = line.strip()
            if stripped.startswith("--"):
                continue
            for check in KAHLUA2_ISSUES:
                if check["severity"] != "ERROR":
                    continue
                if re.search(check["pattern"], line):
                    rel_path = lf.relative_to(mod_dir)
                    issues.append(f"ERROR: {rel_path}:{line_num} - {check['message']}")
                    lua_issues_count += 1
                    if lua_issues_count > 20:
                        issues.append("... (truncated, too many Lua issues)")
                        break
            if lua_issues_count > 20:
                break
        if lua_issues_count > 20:
            break

    # Format result
    result = ["# Mod Analysis Report", ""]
    result.append("## Structure")
    result.extend(f"- {line}" for line in info_lines)
    result.append("")

    if issues:
        errors = [i for i in issues if i.startswith("ERROR")]
        warnings = [i for i in issues if i.startswith("WARNING")]
        infos = [i for i in issues if i.startswith("INFO")]

        result.append(f"## Issues Found ({len(issues)} total)")
        if errors:
            result.append(f"\n### Errors ({len(errors)})")
            result.extend(f"- {i}" for i in errors)
        if warnings:
            result.append(f"\n### Warnings ({len(warnings)})")
            result.extend(f"- {i}" for i in warnings)
        if infos:
            result.append(f"\n### Info ({len(infos)})")
            result.extend(f"- {i}" for i in infos)
    else:
        result.append("## No Issues Found")
        result.append("Mod structure looks good!")

    return "\n".join(result)


# ---------------------------------------------------------------------------
# Tool: get_kahlua2_reference
# ---------------------------------------------------------------------------

@mcp.tool()
def get_kahlua2_reference(topic: str = "") -> str:
    """Get Kahlua2/PZ Lua compatibility information.

    Returns information about what Lua features work in PZ's Kahlua2 runtime,
    common pitfalls, Java interop patterns, and performance tips.

    Args:
        topic: Optional filter - "features", "pitfalls", "interop", "performance",
               or empty for full reference
    """
    if KAHLUA2_REF.exists():
        content = KAHLUA2_REF.read_text(encoding="utf-8")
        if topic:
            topic_lower = topic.lower()
            sections = content.split("\n## ")
            matching = []
            for section in sections:
                if topic_lower in section.lower():
                    matching.append("## " + section if not section.startswith("#") else section)
            if matching:
                return "\n".join(matching)
            return f"No section matching '{topic}' found. Available sections: Quick Reference, What Does Work, Java Interop, Common Pitfalls, Performance Tips, Testing Compatibility"
        return content
    return "Kahlua2 reference file not found. Key points: No goto/labels, no bitwise ops, no io/os/debug/coroutine libraries, use instanceof() for Java types, Java collections are 0-based."


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _to_display_name(name: str) -> str:
    """CamelCase -> 'Display Name'."""
    result = []
    for i, c in enumerate(name):
        if c.isupper() and i > 0 and not name[i - 1].isupper():
            result.append(" ")
        result.append(c)
    return "".join(result)


def _parse_mod_info(content: str) -> dict:
    """Parse mod.info into a dict."""
    info = {}
    for line in content.strip().split("\n"):
        if "=" in line:
            key, _, value = line.partition("=")
            info[key.strip()] = value.strip()
    return info


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
