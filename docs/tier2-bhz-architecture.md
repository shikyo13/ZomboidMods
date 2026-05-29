# BHZ Architecture Reference

Read when editing the BHZ damage system. Source: `BarricadesHurtZombiesB42/.../BHZCore.lua`.

## Damage Pipeline

All damage flows through `Events.OnZombieUpdate`. The handler runs on the side that owns the zombie simulation. In B42.17 through B42.18, vanilla still uses `ThumpFrame` internally, but `ActionContext.hasEventOccurred()` is not safely Lua-callable. BHZ therefore requires Lua-visible vanilla hit results before applying damage: zombie thump condition changes for structure hits, and vehicle window or part condition decreases for vehicle hits. If those signals are unavailable, BHZ logs the failure and skips damage instead of approximating hits with timer logic.

```text
onZombieUpdate(zombie)
  -> alive and health checks
  -> shouldProcessZombie(zombie)
  -> cooldown table cleanup every 5000 calls
  -> state dispatch

ThumpState
  -> handleThumpDamage(zombie)
  -> getThumpTarget()
  -> skip BaseVehicle targets
  -> require zombie:getThumpCondition() decrease for that zombie and target
  -> DamageMode filter, unless target ModData has BarricadeDamageMultiplier
  -> getMaterialType(target)
  -> damage = THUMP_DMG * materialMultiplier * optional modData multiplier
  -> dispatchZombieDamage(...)

AttackVehicleState
  -> handleVehicleDamage(zombie)
  -> zombie:getTarget():getVehicle()
  -> getVehicleAttackTarget(vehicle, zombie, target)
  -> require vehicle window health or vehicle part condition decrease
  -> getVehicleMaterialType(vehicle, part)
  -> damage = VEHICLE_DMG * materialMultiplier
  -> dispatchZombieDamage(...)
```

## Multiplayer Authority

Project Zomboid delegates some zombies to clients. For those zombies, the owning client is the authoritative simulation side and its normal zombie packet serializes `zombie.health`.

BHZ 2.2.4 applies damage locally on the owning client before sending an RPC to the server. The RPC includes an absolute post-damage health target so the server can apply the same state idempotently. If the normal zombie sync packet arrives first, the RPC becomes a no-op for health and still preserves server-side blood feedback.

`shouldProcessZombie` rules:

| Runtime | Process |
|-|-|
| Singleplayer | Always |
| Listen server | Always |
| Dedicated server | Only zombies with no delegated owner |
| Dedicated client | Only zombies delegated to this client |

## Config System

Loaded in `onLoad()` from `SandboxVars.BarricadesHurtZombies`.

| SandboxVar | Field | Default | Purpose |
|-|-|-|-|
| BaseDamage | BHZ.THUMP_DMG | 5 percent | Base damage per thump |
| VehicleBaseDamage | BHZ.VEHICLE_DMG | 5 percent | Base damage per vehicle attack |
| DamageMode | DAMAGE_MODE, BHZ.THUMP_FUNC | 1 | 1=normal supported structures and vehicles, 2=all thump targets and vehicles, 3=disabled for thump and vehicle damage |
| MetalMultiplier | MaterialDamageMultiplier.METAL | 1.25 | Metal material scale |
| MetalHeavyMultiplier | MaterialDamageMultiplier.METAL_HEAVY | 1.4 | Heavy metal scale |
| LightSpikeMultiplier | MaterialDamageMultiplier.LIGHT_SPIKE | 1.5 | Light spike scale |
| HeavySpikeMultiplier | MaterialDamageMultiplier.HEAVY_SPIKE | 1.75 | Heavy spike scale |
| ReinforcedMultiplier | MaterialDamageMultiplier.REINFORCED | 2.0 | Reinforced scale |
| BloodEffects | BHZ.BLOOD_ENABLED | true | Blood splat visuals |
| DebugMode | DEBUG_MODE | false | Enable debug logs |
| VehicleDebugMode | DEBUG_VEHICLES | false | Extra vehicle logging |
| LogLevel | currentLogLevel | 1 | None, Error, Warn, Info, Debug, Trace |

## Material Detection

Thump targets:

- `IsoBarricade`: `isMetal()` and `isMetalBar()` decide metal versus wood.
- `IsoWindow`: treated as wood/glass baseline.
- `IsoDoor`: `getSoundPrefix()` maps known door sounds to material types.
- `IsoThumpable` doors: same door sound path.
- `IsoThumpable` non-doors: sprite `ThumpSound` property maps log walls, metal walls, chainlink fences, and garage doors.
- Fallback: sprite-name heuristic for chainlink, metal, and bars, otherwise wood.

Vehicles:

1. Vehicle script name containing `svu_armor_` maps spiked, light, reinforced, or heavy armor names.
2. Attack part ID starting with `SVU_Armor_` maps to `METAL_HEAVY`.
3. Vanilla and unknown vehicles fall back to `METAL`.

`getVehicleAttackTarget` mirrors B42's `AttackVehicleState` enough to find the passenger door or nearest bodywork part when available. Hittable vehicle windows are tracked by window health. Solid parts are tracked by part condition. Vehicle hit signals are shared per vehicle part/window so one vehicle-health decrease cannot damage every zombie in `AttackVehicleState`.

## Hit Signals And Cooldowns

- Structure hits apply when `zombie:getThumpCondition()` decreases for that zombie and current target. Target changes always prime the signal first to avoid comparing stale condition from a previous door, window, or barricade.
- Vehicle hits apply when the selected vehicle window health or vehicle part condition decreases.
- If the required hit signal is unavailable, BHZ logs `HIT_SIGNAL_UNAVAILABLE` or a `SKIP_NO_*_HIT_SIGNAL` line and skips damage.
- `zombieDamageCooldowns` maps zombie ID to last accepted server RPC timestamp from `getTimestampMs()`.
- Zombie ID uses `zombie:getOnlineID()`, falling back to `tostring(zombie)` in SP or invalid-ID cases.
- Stale cooldown and hit-signal entries older than 10 seconds are purged every 5000 `OnZombieUpdate` calls.
- Thump and vehicle sandbox cooldown settings remain in the active B42 options only as deprecated no-ops, preventing existing saves from logging unknown option errors.
- Server RPCs use a separate 250 ms minimum cooldown as an abuse guard and scale down with PZ game speed through `getGameTime():getTrueMultiplier()` when available.

## Compatibility

The runtime uses `pcall` around B42 APIs that have moved or changed across unstable builds:

- game version lookup
- sprite property access
- door, window, and vehicle part APIs
- blood splat calls
- zombie kill calls

`sandbox-options.txt` must remain only in `42/media/`, not in `common/media/`.

## Performance Notes

The hot path exits before material detection unless a zombie is alive, locally authoritative, and in `ThumpState` or `AttackVehicleState`. Material and part lookups only run after mode and hit-signal checks. The cooldown and hit-signal tables are bounded by active thumping or vehicle-attacking zombies and purged periodically.
