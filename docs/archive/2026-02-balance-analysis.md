# Game Balance & Design Analysis Report
## Barricades Hurt Zombies Mod

**Date:** February 14, 2026
**Reviewer:** Game Design Team
**Mod Version:** Build 42 Update

---

## Executive Summary

This report analyzes the damage system balance of the BHZ mod, focusing on thumps-to-kill calculations, game speed multiplier mechanics, cooldown interactions, and vehicle damage tuning. Several potential balance issues and double-scaling concerns have been identified.

---

## 1. Base Damage Analysis: Thumps-to-Kill Calculations

### Current Settings
- **Base damage per thump:** 5% (0.05)
- **Zombie health:** 100% (1.0)
- **Game speed multipliers:** {1, 2, 3, 4}

### Thumps-to-Kill by Material Type (at 1x game speed)

| Material Type | Multiplier | Damage per Thump | Thumps to Kill | Time Estimate* |
|---------------|-----------|------------------|----------------|----------------|
| Wood          | 1.0×      | 5%               | **20 thumps**  | ~10 seconds    |
| Metal         | 1.25×     | 6.25%            | **16 thumps**  | ~8 seconds     |
| Heavy Metal   | 1.4×      | 7%               | **15 thumps**  | ~7.5 seconds   |
| Light Spike   | 1.5×      | 7.5%             | **14 thumps**  | ~7 seconds     |
| Heavy Spike   | 1.75×     | 8.75%            | **12 thumps**  | ~6 seconds     |
| Reinforced    | 2.0×      | 10%              | **10 thumps**  | ~5 seconds     |

*Assuming ~500ms per thump (THUMP_COOLDOWN)

### Thumps-to-Kill at Different Game Speeds

At higher game speeds, the damage multiplier applies directly:

| Material | 1x Speed | 2x Speed | 3x Speed | 4x Speed |
|----------|----------|----------|----------|----------|
| Wood     | 20       | 10       | 7        | 5        |
| Metal    | 16       | 8        | 6        | 4        |
| Reinforced | 10     | 5        | 4        | 3        |

### Balance Assessment

**Findings:**
- At 1x speed, 20 thumps for wood seems **reasonable** - zombies should take meaningful time to break through
- At 4x speed, only **5 thumps** to kill on wood is **extremely punishing** for players who prefer fast gameplay
- The 2x multiplier at max material (Reinforced) creates a **4:1 kill ratio difference** between wood and reinforced at same game speed
- At 4x speed + Reinforced material, zombies die in **3 thumps** - this may be too extreme

**Recommendation:**
- **CRITICAL ISSUE:** The current system severely punishes fast game speed players. Consider either:
  1. Capping game speed multiplier at 2x instead of matching game speed directly
  2. Making game speed multiplier a separate configurable sandbox option (default: off)
  3. Using square root scaling: √gameSpeed instead of linear (would give {1, 1.41, 1.73, 2} instead of {1, 2, 3, 4})

---

## 2. Game Speed Multiplier Analysis: Double-Scaling Risk

### The Critical Question
**Does vehicle OnTick fire more frequently at higher game speeds?**

### Code Analysis

**Barricade System (OnWorldSound):**
- Line 765-826: Uses `Events.OnWorldSound.Add(onZombieThump)`
- OnWorldSound is a sound event that fires when zombies thump
- **CONFIRMED:** OnWorldSound fires more frequently at higher game speeds because zombies attack faster
- **Result:** Game speed multiplier is NECESSARY to compensate

**Vehicle System (OnTick):**
- Line 441-595: Uses `processVehicleDamage()` on `Events.OnTick.Add()`
- Line 452-454: Uses tick counting with `PROCESS_INTERVAL = 150` ticks
- Line 560: Applies `GAME_SPEED_MULTIPLIERS[getGameSpeed()]`

### Critical Finding: CONFIRMED DOUBLE-SCALING BUG

**The vehicle system has double-scaling:**

1. **OnTick fires more frequently** at higher game speeds (e.g., 4x speed = 4x tick rate)
2. **PROCESS_INTERVAL is in ticks** (150 ticks), not real-time milliseconds
3. At 4x speed:
   - The interval check completes **4x faster in real-time**
   - **PLUS** each check applies a **4x damage multiplier**
   - **Total scaling: 4 × 4 = 16x damage increase**

**Example:**
- At 1x speed: damage applied every 150 ticks × base damage × 1x = baseline
- At 4x speed: damage applied every 150 ticks (but ticks happen 4x faster) × base damage × 4x = **16x baseline**

**This is a CRITICAL BALANCE BUG.**

### Recommendation: URGENT FIX REQUIRED

**Option 1: Remove game speed multiplier from vehicle damage (RECOMMENDED)**
```lua
-- Line 560-562, change from:
local speedMult = GAME_SPEED_MULTIPLIERS[getGameSpeed()] or 1
local finalDmg  = baseDmg * matMult * speedMult

-- To:
local finalDmg  = baseDmg * matMult  -- Remove speedMult entirely
```

**Rationale:** The tick rate already scales with game speed, so the multiplier is redundant and creates exponential scaling.

**Option 2: Convert PROCESS_INTERVAL to real-time tracking**
- Track last damage time using `getTimestampMs()` instead of tick counting
- This would make the interval game-speed-independent
- Then the game speed multiplier would be appropriate

---

## 3. Cooldown System Analysis

### THUMP_COOLDOWN (500ms)

**Current Behavior:**
- Line 442: `local THUMP_COOLDOWN = 500`
- Line 693: Configurable in sandbox (default 500ms, max 5000ms)
- Line 777-779: Uses `getTimestampMs()` for real-time tracking
- **CONFIRMED:** This is real-world milliseconds, NOT game-time

**Game Speed Interaction:**
At 4x game speed:
- Real-world: 500ms cooldown
- Game-time equivalent: 2000ms cooldown (4× slower relative to game time)
- **Result:** Cooldown becomes MORE restrictive at higher speeds relative to game time

**Balance Assessment:**
- At 1x speed: 500ms = ~2 thumps per second (appropriate)
- At 4x speed: 500ms real-time = 2000ms game-time = **cooldown feels 4x longer in-game**
- This partially compensates for the game speed multiplier, but creates inconsistent zombie threat

**Recommendation:**
- Current implementation is **technically correct** for preventing spam
- However, combined with game speed multiplier, creates confusing balance:
  - Damage per hit increases 4x
  - But hits are relatively less frequent (4x longer in game-time)
  - Net effect: similar overall DPS, but burstier damage
- **Consider:** Making cooldown scale with game speed (divide by game speed) to maintain consistent game-time behavior

### DAMAGE_COOLDOWN (0ms default)

**Current Behavior:**
- Line 440: `local DAMAGE_COOLDOWN = 0`
- Line 696: Configurable (0-1000ms, default 0)
- Line 541: Applied to vehicle damage only
- **Default of 0 means NO cooldown** - damage every PROCESS_INTERVAL

**Balance Assessment:**
- With PROCESS_INTERVAL of 150 ticks and no damage cooldown:
  - At 1x speed: damage every 150 ticks = ~2.5 seconds (60 ticks/sec)
  - At 4x speed: effectively every ~0.625 seconds real-time
- **CRITICAL:** Combined with the 16x double-scaling bug, this creates **massively excessive vehicle damage**

**Recommendation:**
- Set default to at least 500ms to match THUMP_COOLDOWN
- This provides consistency between barricade and vehicle systems

---

## 4. Material Multiplier Range Analysis

### Current Caps
- **Minimum:** 1.0× (sandbox min for all materials)
- **Maximum:** 2.0× (sandbox max for all materials)
- **Default range:** 1.0× (wood) to 2.0× (reinforced)

### Balance Assessment

**The 2.0× cap is APPROPRIATE:**
- Provides meaningful differentiation (2:1 ratio between min/max)
- At default settings, creates 10-20 thump range (manageable)
- Higher cap (e.g., 3.0×) would create extreme outliers:
  - 3.0× at 4x speed = 12x base damage = kill in 1-2 thumps
  - This would trivialize zombie threat entirely

**The 1.0× minimum is RESTRICTIVE:**
- No ability to make materials MORE forgiving than wood baseline
- Players seeking easier difficulty can't reduce material multipliers below 1.0

**Recommendation:**
- Keep maximum at 2.0× (well-balanced)
- **Consider:** Lowering minimum to 0.5× for easier gameplay options
- Alternatively: allow base damage to go below 5% (currently min is 0%)

---

## 5. Vehicle vs Barricade Damage Separation

### Current Implementation
Both systems use the **same base damage:**
- Line 55: `THUMP_DMG = 0.05` (5%)
- Line 557: Vehicle damage uses `BHZ.THUMP_DMG`
- Line 786: Barricade damage uses `BHZ.THUMP_DMG`

### Balance Considerations

**Arguments FOR shared damage:**
- Consistency: players understand one damage model
- Simplicity: fewer variables to balance
- Thematic: same zombie, same strength

**Arguments AGAINST shared damage:**
- Vehicles are mobile defenses vs static barricades
- Players invest much more in vehicle preparation
- Vehicle combat is active (driving) vs passive (base defense)
- Metal vehicles getting same multiplier as metal barricades seems odd

**Current Material Mapping:**
- Barricades: Wood (1.0×) or Metal (1.25×)
- Vehicles: All mapped to Metal (1.25×) or SVU variants (1.4-2.0×)
- **Imbalance:** Standard cars have same damage resistance as metal barricades, which may feel too weak

### Recommendation

**IMPLEMENT SEPARATE VEHICLE TUNING:**

1. Add new sandbox option: `VehicleBaseDamage` (default: 2.5%, half of barricade damage)
   - Rationale: Vehicles are valuable resources, should be more durable

2. Add vehicle-specific material multipliers in sandbox:
   - `VehicleMetalMultiplier` (default: 1.0× instead of 1.25×)
   - Keep SVU advanced materials at current values

3. This allows independent tuning:
   - Barricades: Fast zombie kills (they're meant to be dangerous)
   - Vehicles: Slower zombie kills (they're mobile fortresses)

**Example after fix:**
- Vehicle attacked at 1x speed, base metal:
  - Current: 5% × 1.25 = 6.25% per hit = 16 thumps
  - Proposed: 2.5% × 1.0 = 2.5% per hit = **40 thumps** (much more durable)

---

## 6. PROCESS_INTERVAL Analysis

### Current Settings
- Line 441: `local PROCESS_INTERVAL = 150`
- Line 697: Configurable (50-500 ticks, default 150)
- Line 452-454: Tick counting system

### Real-Time Calculation

**Project Zomboid tick rate:** ~60 ticks per second (standard)

**Real-time intervals:**
- 150 ticks ÷ 60 ticks/sec = **2.5 seconds at 1x speed**
- At 4x speed: ticks happen 4x faster = **0.625 seconds real-time**

**At different game speeds:**
| Setting | 1x Speed | 2x Speed | 3x Speed | 4x Speed |
|---------|----------|----------|----------|----------|
| 50 ticks | 0.83s   | 0.42s    | 0.28s    | 0.21s    |
| 150 ticks | 2.5s   | 1.25s    | 0.83s    | 0.625s   |
| 500 ticks | 8.33s  | 4.17s    | 2.78s    | 2.08s    |

### Balance Assessment

**Current 150 ticks is APPROPRIATE for 1x speed:**
- 2.5 second check interval prevents performance issues
- Provides smooth damage application
- Not too fast (spam) or too slow (unresponsive)

**BECOMES TOO FAST at higher game speeds:**
- At 4x speed: 0.625s checks combined with 4x multiplier = extreme damage rate
- This compounds the double-scaling issue

**Recommendation:**
- Keep 150 ticks as default
- **AFTER fixing double-scaling bug**, this interval will be balanced
- If players want more responsive vehicle damage, they can lower to 100 ticks
- Max of 500 provides ceiling for performance concerns

---

## 7. Blood Intensity Scaling

### Current Implementation
- Line 582-587: Blood effects applied in vehicle system
- Line 585: `addBloodSplat(zSq, matMult)` - intensity scales with material multiplier
- Line 821-824: Blood effects applied in barricade system
- Line 823: `addBloodSplat(square, blood_intensity)` where intensity = 1 × matMult

### Visual Logic Assessment

**Does higher material multiplier = more blood make sense?**

**Arguments FOR current system:**
- More damage = more blood (intuitive)
- Visual feedback for damage effectiveness
- Reinforced spikes should be bloodier than wood

**Arguments AGAINST:**
- Material type shouldn't affect blood volume
- Zombie takes same physical damage regardless of what kills it
- Metal barricades shouldn't produce 25% more blood than wood
- Blood should scale with damage DEALT, not material type

### Current Behavior Example
- Wood barricade (1.0×): normal blood
- Reinforced spikes (2.0×): **double blood intensity**
- This suggests the zombie is "more injured" by spikes, which is correct

### Recommendation

**CURRENT IMPLEMENTATION IS ACCEPTABLE** with one caveat:

The blood scaling makes thematic sense (spikes are messier than smooth surfaces), but should cap at reasonable levels:

```lua
-- Line 585 and 823, consider capping:
local bloodIntensity = math.min(matMult, 1.5)  -- Cap at 1.5x even if material is 2.0x
addBloodSplat(square, bloodIntensity)
```

**Rationale:** Blood at 2.0× intensity might look excessive/unrealistic. A 50% cap maintains visual feedback without being cartoonish.

---

## 8. Summary of Critical Issues

### Priority 1: CRITICAL BUGS
1. **Double-scaling in vehicle damage system**
   - OnTick fires more frequently AND applies game speed multiplier
   - Results in 16x damage at 4x game speed (should be 4x)
   - **FIX:** Remove game speed multiplier from vehicle damage calculation

### Priority 2: MAJOR BALANCE CONCERNS
2. **Game speed multiplier too aggressive**
   - 4x damage at 4x speed may be excessive
   - Punishes players who prefer faster gameplay
   - **FIX:** Consider square root scaling or make it configurable

3. **Vehicle damage should be separate from barricades**
   - Same base damage makes vehicles too fragile
   - No independent tuning for different gameplay contexts
   - **FIX:** Add separate vehicle base damage sandbox option

### Priority 3: MINOR TUNING
4. **DAMAGE_COOLDOWN default should match THUMP_COOLDOWN**
   - Current: 0ms (no cooldown) allows damage spam
   - **FIX:** Set default to 500ms for consistency

5. **Material multiplier minimum too restrictive**
   - Can't make materials easier than wood baseline
   - **FIX:** Allow minimum of 0.5× instead of 1.0×

---

## 9. Recommended Sandbox Option Changes

### New Options to Add
```
option BarricadesHurtZombies.VehicleBaseDamage
{
    type = double,
    min = 0,
    max = 100,
    default = 2.5,
    page = BarricadesHurtZombies,
    translation = BarricadesHurtZombies_VehicleBaseDamage,
}

option BarricadesHurtZombies.UseGameSpeedMultiplier
{
    type = boolean,
    default = false,  // Disable by default due to double-scaling
    page = BarricadesHurtZombies,
    translation = BarricadesHurtZombies_UseGameSpeedMultiplier,
}

option BarricadesHurtZombies.GameSpeedScaling
{
    type = enum,
    numValues = 3,  // Linear, Square Root, None
    default = 2,    // Square Root
    page = BarricadesHurtZombies,
    translation = BarricadesHurtZombies_GameSpeedScaling,
}
```

### Options to Modify
```
// Lower minimum to allow easier gameplay
option BarricadesHurtZombies.MetalMultiplier
{
    min = 0.5,  // Changed from 1.0
    max = 2.0,
    default = 1.25,
}

// Increase default to prevent spam
option BarricadesHurtZombies.VehicleDamageCooldown
{
    default = 500,  // Changed from 0
}
```

---

## 10. Proposed Code Changes

### Fix #1: Remove Double-Scaling (CRITICAL)

**File:** BHZCore.lua, Line 556-562

```lua
-- CURRENT CODE:
local baseDmg   = BHZ.THUMP_DMG
local matType   = getVehicleMaterialType(vehicle, part)
local matMult   = MaterialDamageMultiplier[matType] or 1.0
local speedMult = GAME_SPEED_MULTIPLIERS[getGameSpeed()] or 1
local finalDmg  = baseDmg * matMult * speedMult

-- FIXED CODE:
local baseDmg   = BHZ.THUMP_DMG
local matType   = getVehicleMaterialType(vehicle, part)
local matMult   = MaterialDamageMultiplier[matType] or 1.0
-- Game speed multiplier removed - tick rate already scales with speed
local finalDmg  = baseDmg * matMult
```

### Fix #2: Separate Vehicle Base Damage

**File:** BHZCore.lua, Line 54-59

```lua
-- CURRENT CODE:
local BHZ = {
    THUMP_DMG       = 0.05,
    THUMP_FUNC      = nil,
    BLOOD_ENABLED   = true,
    LOG_ENABLED     = LOG_ENABLED,
}

-- ENHANCED CODE:
local BHZ = {
    THUMP_DMG           = 0.05,   -- Barricade damage
    VEHICLE_THUMP_DMG   = 0.025,  -- Vehicle damage (separate)
    THUMP_FUNC          = nil,
    BLOOD_ENABLED       = true,
    LOG_ENABLED         = LOG_ENABLED,
}
```

**File:** BHZCore.lua, Line 556

```lua
-- Change from:
local baseDmg   = BHZ.THUMP_DMG

-- To:
local baseDmg   = BHZ.VEHICLE_THUMP_DMG  -- Use vehicle-specific damage
```

### Fix #3: Add Sandbox Loading for New Options

**File:** BHZCore.lua, Line 658-665

```lua
-- Add after loading BaseDamage:
local vehicleBaseDamage = tonumber(SandboxVars.BarricadesHurtZombies.VehicleBaseDamage) or 2.5
if vehicleBaseDamage < 0   then vehicleBaseDamage = 0   end
if vehicleBaseDamage > 100 then vehicleBaseDamage = 100 end
BHZ.VEHICLE_THUMP_DMG = vehicleBaseDamage / 100
debugPrint("VehicleBaseDamage=" .. vehicleBaseDamage .. "% => VEHICLE_THUMP_DMG=" .. BHZ.VEHICLE_THUMP_DMG)
```

---

## 11. Final Recommendations Summary

### Immediate Actions Required
1. **Remove game speed multiplier from vehicle damage** - Fixes critical double-scaling bug
2. **Increase DAMAGE_COOLDOWN default to 500ms** - Prevents damage spam
3. **Add separate vehicle base damage option** - Allows independent vehicle tuning

### Suggested Enhancements
4. **Make game speed multiplier optional/configurable** - Player choice for difficulty scaling
5. **Lower material multiplier minimums to 0.5×** - Allows easier difficulty options
6. **Consider capping blood intensity at 1.5×** - Prevents visual excess

### Balance is Generally Good
- Base 5% damage is well-tuned for 1x speed gameplay
- Material multiplier range (1.0-2.0×) creates meaningful choices
- PROCESS_INTERVAL of 150 ticks provides good responsiveness
- Material detection system is comprehensive

### Core Issue
The **only critical flaw** is the vehicle damage double-scaling bug. Once fixed, the system will be well-balanced. The other recommendations are quality-of-life improvements and player choice enhancements.

---

**Report compiled by:** Game Design Analysis Team
**Next Review:** After implementing fixes
**Testing Required:** Multiplayer testing at 4x game speed with vehicles
