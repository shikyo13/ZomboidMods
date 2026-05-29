param(
    [string]$CorePath = "BarricadesHurtZombiesB42/Contents/mods/BarricadesHurtZombies/42/media/lua/shared/BHZCore.lua"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CorePath)) {
    Write-Error "Missing BHZCore.lua at $CorePath"
}

$text = Get-Content -LiteralPath $CorePath -Raw
$required = @(
    "TICK side=%s",
    "CALC thump side=%s",
    "CALC vehicle side=%s",
    "event=%s",
    "hit=%s",
    "formula=%s",
    "readableFormula=(%s)",
    "base=%.4f",
    "materialMult=%.3f",
    "objectMult=%s",
    "computedDmg=%.4f",
    "actualRemoved=%.4f",
    "oldHp=%.3f",
    "newHp=%.3f",
    "hpAfter=%.3f",
    "ticksToKill=%s",
    "totalComputed=%.4f",
    "totalRemoved=%.4f",
    "cooldown=%s",
    "effectiveCooldown=%s",
    "timeScale=%s",
    "target=[%s]",
    "vehicle=[%s]",
    "part=%s",
    "ZombieLore.Toughness",
    '"Environment"',
    '"Sandbox"',
    '"Mods"',
    "activeMods=[",
    "realHitRequired=true",
    "debugMode=%s",
    "vehicleDebug=%s",
    "debugFile=%s",
    "registered onLoad=%s onZombieUpdate=%s onClientCommand=%s",
    "BHZDebug.log",
    "Lua/BHZDebug.log",
    "BHZ.logToFile(output)",
    "Format: ts=<getTimestampMs> [BHZCore/<category>] <message>"
)

$behaviorRequired = @(
    "local DAMAGE_MODE",
    "DAMAGE_MODE = mode",
    "SKIP_DISABLED side=%s",
    "SKIP_ZERO_DAMAGE side=%s",
    "getGameTimeScale",
    "getEffectiveCooldown",
    "readZombieThumpCondition",
    "shouldProcessStructureHit",
    "shouldProcessVehicleHit",
    "HIT_SIGNAL_UNAVAILABLE src=%s status=%s action=skip_damage",
    "ZombieThumpCondition",
    "VehicleWindowDamage",
    "VehiclePartDamage",
    "SKIP_NO_STRUCTURE_HIT",
    "SKIP_NO_VEHICLE_HIT",
    '"none"',
    "effectiveCooldown=%.1fms",
    "timeScale=%.2f"
)

$forbidden = @(
    "fallback=state_cooldown",
    "state-plus-cooldown behavior",
    '"fallback:"',
    "SKIP_COOLDOWN side=%s zombie=%s hp=%.3f delta=%s cooldown=%s effectiveCooldown=%.1f timeScale=%.2f target=[%s]",
    "SKIP_COOLDOWN side=%s zombie=%s hp=%.3f delta=%s cooldown=%s effectiveCooldown=%.1f timeScale=%.2f vehicle=[%s]",
    "cooldownLabel = usesHitFrame",
    "THUMP_COOLDOWN",
    "DAMAGE_COOLDOWN",
    "getActionContext",
    "hasEventOccurred",
    "THUMPFRAME_GATE_UNAVAILABLE",
    '"hitframe"'
)

$missing = @()
foreach ($needle in $required) {
    if (-not $text.Contains($needle)) {
        $missing += $needle
    }
}

foreach ($needle in $behaviorRequired) {
    if (-not $text.Contains($needle)) {
        $missing += $needle
    }
}

$presentForbidden = @()
foreach ($needle in $forbidden) {
    if ($text.Contains($needle)) {
        $presentForbidden += $needle
    }
}

if ($missing.Count -gt 0) {
    Write-Error ("Missing required diagnostic fields: " + ($missing -join ", "))
}

if ($presentForbidden.Count -gt 0) {
    Write-Error ("Forbidden fallback markers still present: " + ($presentForbidden -join ", "))
}

Write-Host "BHZ diagnostics validation passed."
