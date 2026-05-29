# Barricades Hurt Zombies - Testing Guide

This document covers manual testing procedures for the Barricades Hurt Zombies mod (Build 42).
Enable debug mode in sandbox settings for detailed log output during testing.

---

## Prerequisites

- Project Zomboid Build 42 installed
- Mod enabled in the mod manager
- A sandbox save with the mod's sandbox options accessible
- (Optional) SVU3 + KitsuneLib mods for armor part testing

---

## Build 42.18 Compatibility Checklist

- [ ] **Installed build**: Launch Project Zomboid after updating to Unstable and confirm the startup log reports Build 42.18.0.
- [ ] **BHZ version**: Confirm the startup banner or `BHZDebug.log` reports BHZ v2.2.4.
- [ ] **SP wood barricade**: In singleplayer, let a zombie thump a wood barricade. Confirm `event=ZombieThumpCondition`, `[BHZCore/Thump] CALC`, `[BHZCore/Tick] TICK`, and HP reduction.
- [ ] **SP metal barricade**: Repeat with a metal barricade. Confirm the metal multiplier is logged and damage is higher than wood.
- [ ] **SP fast-forward barricade**: Set `BaseDamage=25`, enable `LogLevel=5`, fast-forward while a zombie thumps 8 planks and a window, and confirm real structure-hit lines log `event=ZombieThumpCondition`, `cooldown=none`, `effectiveCooldown=0.0`, and `timeScale` above `1.00`. The zombie should receive BHZ damage during accelerated time instead of the barricade/window fully resolving first.
- [ ] **SP occupied vehicle**: Sit in a vehicle and let a zombie attack it. Confirm `[BHZCore/Vehicle] CALC`, `event=VehicleWindowDamage` or `event=VehiclePartDamage`, and HP reduction.
- [ ] **SP fast-forward occupied vehicle**: Repeat the occupied vehicle test while fast-forwarding and confirm real vehicle damage lines include `cooldown=none`, `effectiveCooldown=0.0`, and `timeScale`.
- [ ] **Hit-signal fail-closed check**: If the runtime logs `HIT_SIGNAL_UNAVAILABLE` or `SKIP_NO_*_HIT_SIGNAL`, confirm no BHZ damage is applied from state polling alone. This is intentional fail-closed behavior.
- [ ] **Dedicated MP client-owned zombie**: On a dedicated server, stand near a thumping zombie so it is delegated to the client. Confirm the client logs `RPC_SEND` and the server logs `RPC_APPLY` or an idempotent no-op after normal zombie sync.
- [ ] **BHZ log file**: Confirm `%USERPROFILE%\Zomboid\Lua\BHZDebug.log` is written when `DebugMode=true` and `LogLevel=5`, verifying BHZ still works after the 42.18 file-writer fix.
- [ ] **Regression check**: Confirm there is no blood-without-damage behavior, no sudden full-health zombie death, and no repeated `owner_mismatch` rejects during normal dedicated MP testing.

---

## Singleplayer Tests

### Barricade Damage

- [ ] **Wood barricade**: Build a wooden barricade on a window or door. Lure zombies to it. Confirm zombies take damage over time and eventually die.
- [ ] **Metal barricade**: Build a metal barricade. Confirm zombies take noticeably higher damage than with wood (1.25x multiplier).
- [ ] **Zombie death**: When a zombie dies from barricade damage, verify proper ragdoll animation, clothes remain on the corpse, no "ghost" zombies lingering, and no frozen/stuck zombie models.
- [ ] **Custom BarricadeDamageMultiplier mod data**: If a third-party mod sets `getModData().BarricadeDamageMultiplier` on a thumpable object, confirm the custom multiplier is applied correctly.

### Vehicle Damage

- [ ] **Basic vehicle damage**: Park a vehicle near zombies. Let zombies attack the vehicle. Confirm they take damage and eventually die.
- [ ] **Vehicle attack state**: Confirm damage only applies while the zombie is in `AttackVehicleState` against a player inside a vehicle.
- [ ] **Vehicle part awareness**: With debug logging enabled, confirm passenger door or nearest bodywork parts can be detected when B42 exposes one for the attack.
- [ ] **Window hit signal**: If the zombie is hitting a hittable vehicle window, confirm the mod logs `event=VehicleWindowDamage` and applies damage without errors.
- [ ] **Vehicle driven away while zombie attacks**: Drive the vehicle away mid-attack. Confirm no errors or crashes in the console.

### Game Speed And Hit Signals

- [ ] **Speed 1x**: Baseline damage. Confirm each structure damage line is tied to `event=ZombieThumpCondition`.
- [ ] **Speed 2x**: Confirm damage continues to occur through real hit-signal lines, not `SKIP_COOLDOWN` timer behavior.
- [ ] **Speed 3x**: Confirm `timeScale` reports above `1.00` and each damage line still uses `cooldown=none`.
- [ ] **Speed 4x**: Confirm fast-forward does not bypass BHZ damage while vanilla object damage advances.
- [ ] **Pause**: Verify no damage is applied while the game is paused.

### Blood Effects

- [ ] **Blood effects ON** (`BloodEffects = true`): Blood splats appear on the zombie's tile when damage is dealt.
- [ ] **Blood effects OFF** (`BloodEffects = false`): No blood splats appear.

### Damage Modes

- [ ] **DamageMode 1 (Normal)**: Supported structure targets (`IsoThumpable`, `IsoBarricade`, `IsoDoor`, `IsoWindow`) and occupied vehicle attacks damage zombies. Map-placed doors and windows are intentionally included.
- [ ] **DamageMode 2 (All)**: Any non-vehicle thump target can damage zombies, plus occupied vehicle attacks.
- [ ] **DamageMode 3 (Disabled)**: No thump or vehicle damage, no blood-only zero-damage ticks, and no health reduction.
- [ ] **Attraction loop check**: With a mod that makes thumping doors or windows attract nearby zombies, confirm corpses near world doors/windows match configured per-hit damage and real `ZombieThumpCondition` cadence.

### Material Detection

- [ ] **IsoThumpable with Metal sprite property**: Build a metal barricade. In debug logs, confirm `IsoThumpable => isMetal=true` and the METAL multiplier is used.
- [ ] **IsoBarricade metal detection**: Place a metal barricade via barricade mechanics. Confirm `IsoBarricade => isMetal=true` in debug logs.
- [ ] **Wood fallback**: Any object without a Metal sprite property should default to WOOD (1.0x multiplier).

### Sandbox Option Changes

- [ ] **Modify BaseDamage mid-game**: Change `BaseDamage` in sandbox settings, then reload the save. Verify the new value takes effect (check debug config printout on load).
- [ ] **All sandbox options at minimum values**: Set every numeric option to its minimum. Confirm the mod loads without errors, zero damage settings do not create blood-only ticks, and `DamageMode=Disabled` suppresses both structure and vehicle damage.
- [ ] **All sandbox options at maximum values**: Set every numeric option to its maximum. Confirm no overflow, no instant kills, and damage scales as expected.

---

## Multiplayer Tests

### Multiplayer Authority

- [ ] **Dedicated server - server-owned zombie**: With no delegated owner, confirm barricade and vehicle damage is applied on the server and zombie health decreases.
- [ ] **Dedicated server - client-owned zombie**: With a player near the zombie, confirm the owning client applies health locally, sends the `BHZ.applyDamage` RPC, and the server health does not get overwritten back to full.
- [ ] **Blood without damage regression**: Set `BaseDamage` or `VehicleBaseDamage` to 100% and confirm a thumping zombie dies instead of only showing blood effects.

### Multi-Player Scenarios

- [ ] **Multiple players near same zombies**: Two or more players near the same barricade/vehicle with zombies attacking. Verify no double-damage and no crashes.
- [ ] **Player disconnect/reconnect**: A player disconnects while zombies are thumping nearby. Reconnect and confirm no stale cooldown entries cause issues.

### Stress

- [ ] **High zombie density**: 50+ zombies attacking barricades simultaneously on a dedicated server. Check for errors in the server log and confirm damage is applied correctly.

---

## Performance Tests

- [ ] **Normal gameplay**: With the mod enabled and a few zombies nearby, confirm no noticeable FPS impact compared to mod disabled.
- [ ] **Mega horde (100+ zombies)**: Spawn a large horde near barricades/vehicles. Measure FPS with the mod enabled vs. disabled. Document any difference.
- [ ] **Long session (2+ hours)**: Play for an extended period with ongoing zombie activity. Monitor memory usage and confirm the cooldown and hit-signal tables stay small (stale entries are cleaned up every 5000 zombie updates).
- [ ] **Debug mode ON**: Enable `DebugMode` and `VehicleDebugMode`. Confirm logs appear and performance remains acceptable even with logging overhead.
- [ ] **Debug mode OFF**: Disable both debug flags. Confirm zero log spam in the console and minimal CPU overhead.

---

## Edge Cases

- [ ] **Zombie killed by player while thumping**: A player kills a zombie mid-thump. Confirm no crash, no double-kill, and the cooldown entry is cleaned up.
- [ ] **Barricade destroyed while zombie thumps**: Destroy or break the barricade while zombies are attacking it. Confirm no nil reference errors.
- [ ] **Vehicle driven away while zombie attacks**: Drive the vehicle out of range during an attack cycle. Confirm graceful handling (no crash, damage stops).
- [ ] **SVU3 mod active**: With SVU3 and KitsuneLib enabled, confirm SVU armor parts (`SVU_Armor_Front`, `SVU_Armor_Left`, etc.) are detected and the correct material type is returned.
- [ ] **SVU3 mod not active**: Without SVU3, confirm standard vehicle part detection works and no errors from missing SVU parts.

---

## Console Commands and Techniques for Testing

### Enabling Debug Mode

In your sandbox settings (before starting the game or via the sandbox options menu):

```
BarricadesHurtZombies.DebugMode = true
BarricadesHurtZombies.VehicleDebugMode = false
BarricadesHurtZombies.LogLevel = 5
```

This enables `[BHZCore/Config]`, `[BHZCore/Tick]`, `[BHZCore/Damage]`, `[BHZCore/Thump]`, `[BHZCore/Vehicle]`, and `[BHZCore/MP]` log output in the game console and in `%USERPROFILE%\Zomboid\Lua\BHZDebug.log`. PZ's `getFileWriter()` writes relative to the Zomboid `Lua` folder. Keep `VehicleDebugMode = false` for normal diagnostics. It only enables older vehicle material chatter. Use `LogLevel = 6` only when you need cooldown and filter skip logs, because it is much noisier.

For existing saves or servers, defaults may already be persisted. Open the sandbox options UI or server sandbox file and confirm:

```
DebugMode = true
VehicleDebugMode = false
LogLevel = 5
```

For the fast-kill report, capture the first several lines containing:

```
[BHZCore/Config]
[BHZCore/Tick] TICK
[BHZCore/Thump] CALC
[BHZCore/Vehicle] CALC
[BHZCore/Damage] DMG
[BHZCore/MP] RPC_
```

Those lines show the loaded environment, PZ build, side/client authority, active mods, BHZ sandbox values, ZombieLore values, material multiplier, object multiplier, fixed health damage formula, computed damage, actual health removed, zombie HP before and after damage, cumulative per-zombie totals, and server RPC handling.

### User Log Pull Instructions

1. Close Project Zomboid after reproducing the issue.
2. Open `%USERPROFILE%\Zomboid\Lua\BHZDebug.log`.
3. Copy the full file if possible. It contains only BHZ diagnostic lines for that session.
4. If `BHZDebug.log` is missing, confirm `DebugMode=true` and `LogLevel=5`, then fall back to `%USERPROFILE%\Zomboid\console.txt` and search for `[BHZCore]`.
5. For multiplayer, include both client and server `BHZDebug.log` files if available.
6. Open an issue at `https://github.com/shikyo13/ZomboidMods/issues` and include what looked wrong in-game. The log should already include PZ build, SP/hosted MP/dedicated side, zombie lore, BHZ sandbox settings, active mods, and damage math.

### Using the BHZDebug Helper

If the `BHZDebug.lua` file is installed, the following utilities are available when `DebugMode` is enabled. Access them from the Lua debug console (Main Menu > Debug > Lua Console, or press the tilde key in debug builds):

```lua
-- Print current BHZ configuration
BHZDebug.printConfig()

-- List all zombies within 3 tiles of the player with their health, state, and target
BHZDebug.printNearbyZombies()

-- List all vehicles within 5 tiles of the player with position and parts
BHZDebug.printNearbyVehicles()

-- Show the material type that would be detected for a given thump target
BHZDebug.printMaterialInfo()

-- Dump the current cooldown table size and entries
BHZDebug.printCooldowns()
```

### Spawning Zombies (Debug Mode)

With Project Zomboid's debug mode enabled (add `-debug` launch option):

1. Open the debug menu (press the debug key, usually `~` or via the menu).
2. Use the **Spawn Zombie** panel to place zombies at specific locations.
3. Alternatively, use the Lua console:

```lua
-- Spawn a zombie at the player's location
local player = getPlayer()
local sq = player:getSquare()
addZombiesInOutfit(sq:getX(), sq:getY(), sq:getZ(), 1, "ZombieRandom", nil)
```

### Building Barricades Quickly

Use debug mode's item spawner or the Lua console:

```lua
-- Give the player planks and nails for barricading
local player = getPlayer()
local inv = player:getInventory()
inv:AddItem("Base.Plank")
inv:AddItem("Base.Plank")
inv:AddItem("Base.Plank")
inv:AddItem("Base.Plank")
inv:AddItem("Base.Nails")
inv:AddItem("Base.Hammer")
```

Then right-click a window or door to barricade it.

### Spawning Vehicles

```lua
-- Spawn a vehicle at the player's position
local player = getPlayer()
local sq = player:getSquare()
addVehicleDebug("Base.VanAmbulance", IsoDirections.N, nil, sq)
```

Common vehicle script names:
- `Base.VanAmbulance`
- `Base.PickUpTruck`
- `Base.SportsCar`
- `Base.StepVan`

### Checking Zombie Health

```lua
-- Print health of all nearby zombies
local player = getPlayer()
local cell = player:getCell()
local sq = player:getSquare()
for ox = -3, 3 do
    for oy = -3, 3 do
        local s = cell:getGridSquare(sq:getX() + ox, sq:getY() + oy, sq:getZ())
        if s then
            local mo = s:getMovingObjects()
            for i = 0, mo:size() - 1 do
                local obj = mo:get(i)
                if instanceof(obj, "IsoZombie") then
                    print("Zombie ID=" .. obj:getOnlineID() .. " HP=" .. obj:getHealth())
                end
            end
        end
    end
end
```

### Monitoring Log Output

- **In-game console**: Press `~` (tilde) in debug builds to open the Lua console. BHZ debug messages appear here with `[BHZCore/...]` prefixes.
- **BHZ log file**: Check `%USERPROFILE%\Zomboid\Lua\BHZDebug.log` for BHZ-only output from the current session.
- **Server logs**: For multiplayer, check the server's `BHZDebug.log` in the server's Zomboid user directory.

### Verifying Sandbox Option Values at Runtime

```lua
-- Check current sandbox settings
local sv = SandboxVars.BarricadesHurtZombies
print("BaseDamage: " .. tostring(sv.BaseDamage))
print("DamageMode: " .. tostring(sv.DamageMode))
print("MetalMultiplier: " .. tostring(sv.MetalMultiplier))
print("BloodEffects: " .. tostring(sv.BloodEffects))
print("DebugMode: " .. tostring(sv.DebugMode))
print("LogLevel: " .. tostring(sv.LogLevel))
```

---

## Test Result Tracking

When running through this checklist, record:

1. **PZ Version**: e.g., Build 42.13.2
2. **Mod Version**: from mod.info or git commit hash
3. **Test Date**: when the test was performed
4. **Pass/Fail**: check or uncheck each box above
5. **Notes**: any unexpected behavior, error messages, or performance numbers
