# BHZ B42.17 Update Investigation

## Planned
- Review latest Workshop reports for B42.17 symptoms.
- Inspect BHZ damage and multiplayer authority code.
- Check current Project Zomboid 42.17 update notes and local PZ references.
- Identify required update scope and validate any edits with available static checks.

## Read And Checked
- Workshop comments provided in chat: dedicated server 42.17 reports blood effects but no zombie damage, another report says SP/MP worked, and one report says thumping damage is inconsistent or instant.
- `CLAUDE.md`: BHZ path, PZ mod rules, Workshop deployment rules.
- `docs/tier1-pz-quickref.md`: MP command flow and event caveats.
- `docs/tier2-bhz-architecture.md`: BHZ damage pipeline and current MP design.
- `BarricadesHurtZombiesB42/Contents/mods/BarricadesHurtZombies/42/media/lua/shared/BHZCore.lua`: authority check, damage application, RPC handler, and event registration.
- `BarricadesHurtZombiesB42/Contents/mods/BarricadesHurtZombies/42/media/lua/shared/BHZDebug.lua`: debug helper still referenced removed vehicle range options.
- `BarricadesHurtZombiesB42/workshop.txt` and `workshop-description.bbcode`: store metadata still advertised old vehicle targeting behavior and future SVU3 status.
- `BarricadesHurtZombiesB42/Contents/mods/BarricadesHurtZombies/poster.png`: packaged poster was 1024x1024 and 2,060,259 bytes.
- Project Zomboid 42.17 notes: MP zombie speed fix, zombie teleport-on-hit fix, thumpable door animation doubling fix.
- Decompiled PZ network code:
  - `IsoZombie.getOwner`, `setOwner`, `isRemoteZombie`, `isLocal`.
  - `NetworkZombieAI.set`, which serializes `zombie.health` into `ZombiePacket.health`.
  - `NetworkZombiePacker.applyZombie`, which applies received packet health on the server.
  - `NetworkZombiePacker.parseZombie`, which only accepts zombie packets from the owning client connection.

## Decisions
- Root cause hypothesis: for client-owned zombies in MP, BHZ sends a damage RPC to the server but leaves the owning client's local zombie health unchanged. The next authoritative zombie sync from that client can overwrite the server-side health reduction, producing visible blood without lasting damage.
- Required B42.17 update: mutate health on the authoritative owning client before sending RPC, and send an absolute target health value to the server so server processing is idempotent and cannot double-apply damage if packet order varies.
- The "full health while thumping, then sudden death" report is consistent with the same client-owner health sync race. It is explicitly called out in the Workshop testing request.
- Server RPCs should only be accepted for zombies the server has delegated to the sending player. Server-owned zombies should be handled by server `OnZombieUpdate`, not by client commands.
- Restore practical vehicle part awareness by passing the B42 attack part into vehicle material detection when available. This keeps the current `AttackVehicleState` design and avoids reintroducing the older debug-only angle scanner.
- Normalize `workshop.txt` to ASCII because the previous file contained invalid UTF-8 bytes and stale copy.
- Keep `preview.full.png` as the full-size source preview, but resize the packaged mod `poster.png` to 256x256 for Workshop packaging.

## Tested
- Static Kahlua compatibility scan over BHZ Lua files: `validation=ok`.
- Version consistency check over root, `42`, and `common` `mod.info`: all now `2.2.2`.
- Sandbox placement check: `42/media/sandbox-options.txt` exists and no `common/media/sandbox-options.txt` duplicate exists.
- Translation coverage check: 8 JSON languages and 8 TXT languages have matching sandbox keys.
- Poster packaging check: packaged `poster.png` is now 256x256 and 140,429 bytes.
- Workshop metadata check: `workshop.txt` and `workshop-description.bbcode` decode as UTF-8 and no longer contain old vehicle-targeting or SVU future-status claims.
- `git diff --check`: passed.
- Em dash scan over touched files: no matches.

## Built
- No compiled build system exists for this Lua Workshop mod. Static validation is used instead.

## Issues And Resolutions
- Repo is dirty and divergent before this work. Existing changes were left intact.
- `workshop.txt` is tracked with nonstandard carriage returns and invalid UTF-8 bytes. Attempted title/header edit was reverted because it made `git diff --check` fail. Clean store-page wording was updated in `workshop-description.bbcode` instead.
- `workshop.txt` was later normalized to ASCII after `apply_patch` could not read the invalid UTF-8 file. This resolves both stale upload copy and diff-check failures from invalid metadata bytes.
- Packaged poster was oversized. It was resized from 1024x1024 to 256x256 and compressed to 140,429 bytes.
- Server RPC abuse surface was narrowed by checking `zombie:getOwnerPlayer()` against the sending `player` before applying the target health.
- Added explicit Workshop-facing B42.17 testing request because live SP/dedicated MP playtesting is not available right now.
- Created `BarricadesHurtZombiesB42/workshop-reply-b4217-playtest.txt` as a ready-to-post comment asking users for PZ build, MP mode, sandbox settings, health/blood behavior, and logs.

## Remaining
- Live SP and dedicated MP test on Project Zomboid 42.17.
- Sync the dev mod to the Workshop upload folder before upload, then compare directories.

## 2026-05-01 Default Damage Review

### Report
- Workshop comment from EternalAera: B42.17 works, but zombies seem to die quickly, "after like 4 thumps".

### Read And Checked
- `BarricadesHurtZombiesB42/Contents/mods/BarricadesHurtZombies/42/media/sandbox-options.txt`: defaults are `BaseDamage=5`, `VehicleBaseDamage=5`, material multipliers `WOOD=1.0`, `METAL=1.25`, `METAL_HEAVY=1.4`, `LIGHT_SPIKE=1.5`, `HEAVY_SPIKE=1.75`, `REINFORCED=2.0`, and cooldowns `500` ms.
- `BarricadesHurtZombiesB42/Contents/mods/BarricadesHurtZombies/42/media/lua/shared/BHZCore.lua`: base damage is converted to `0.05` absolute zombie health damage, then multiplied by material and optional `BarricadeDamageMultiplier` mod data.
- `decompiled/zombie/characters/IsoZombie.java`: PZ zombie health is `3.5-3.8` for Tough, `1.8-2.1` for Normal, `0.5-0.8` for Fragile, or randomized for Random toughness.

### Math
- Default wood damage is `0.05` per successful cooldown tick.
- Default normal zombies should take about `36-42` wood ticks, `29-34` metal ticks, and `18-21` reinforced ticks.
- Default fragile zombies should take about `10-16` wood ticks, `8-13` metal ticks, and `5-8` reinforced ticks.
- Because the cooldown is `500` ms and not tied to a single animation event, a visible thump animation can contain more than one damage tick. A fragile zombie against reinforced or high-multiplier material can therefore look like it dies in about 4 visible thumps.

### Current Conclusion
- Four visible thumps is not expected for default Normal zombie toughness on default wood or metal.
- Four visible thumps is plausible for Fragile toughness, random low-health zombies, reinforced or spike material, higher sandbox `BaseDamage`, a custom object with `BarricadeDamageMultiplier`, or if visible thumps are being counted while the 500 ms cooldown applies multiple ticks inside a longer thump animation.
- No code change made yet. Best next change, if tuning is desired, is either lower default base damage, increase `ThumpDamageCooldown`, or change the model from time-based cooldown ticks to one damage application per actual thump animation or target-hit event if PZ exposes a reliable event.

## 2026-05-01 Playtest Logging

### Planned
- Add detailed logging behind existing sandbox `LogLevel` so fast-kill reports can be diagnosed without changing default behavior.

### Read And Checked
- `BHZCore.lua` existing logging model: `LogLevel` maps to internal levels, `DebugMode` gates older debug helper output, `BHZ.LOG_ENABLED` allows console logging when log level is not None.
- `TESTING.md` debug section: previously only mentioned `DebugMode` and `VehicleDebugMode`.

### Built
- No compiled build exists for this Lua mod.

### Changes Made
- Added `logAt` and safe label helpers for side, player, zombie owner, targets, vehicle parts, and vehicle script names.
- Added `[BHZCore/Config]` info logs for loaded sandbox values, cooldowns, material multipliers, blood setting, log level, and runtime side.
- Added `[BHZCore/Thump] CALC` debug logs showing zombie HP, target, material, base damage, material multiplier, optional object multiplier, final damage, cooldown, and owner.
- Added `[BHZCore/Vehicle] CALC` debug logs showing vehicle script, selected part, material, base damage, multiplier, final damage, target player, and owner.
- Added `[BHZCore/Damage] DMG` info logs showing side, zombie id, HP before/after, damage, material, source, and blood flag.
- Added `[BHZCore/MP] RPC_SEND`, `RPC_APPLY`, `RPC_REJECT`, and clamp logs for client/server authority debugging.
- Added trace-only `SKIP_COOLDOWN` and `SKIP_FILTER` logs for noisy timing/filter investigation.
- Updated `TESTING.md` to tell playtesters to use `LogLevel = 5` for debug and `LogLevel = 6` only for cooldown/filter traces.

### Tested
- `git diff --check` passed for `BHZCore.lua` and `TESTING.md`.
- Kahlua compatibility grep found no banned Lua features or em dashes in `BHZCore.lua`.
- `npx --yes luaparse` parsed `BHZCore.lua` successfully.
- Copied the instrumented `BHZCore.lua` to `C:\Users\Zero\Zomboid\Workshop\BarricadesHurtZombiesB42\Contents\mods\BarricadesHurtZombies\42\media\lua\shared\BHZCore.lua`; SHA256 hash matched source.

### Remaining
- Runtime playtest with `LogLevel = 5`, then repeat with `LogLevel = 6` only if the timing still needs proof.

## 2026-05-02 Diagnostic Defaults

### Changes Made
- Set `DebugMode` default to `true` in `42/media/sandbox-options.txt`.
- Set `VehicleDebugMode` default to `true` in `42/media/sandbox-options.txt`.
- Set `LogLevel` default to `5` in `42/media/sandbox-options.txt`.
- Left all damage values unchanged so the fast-kill behavior can still be measured against current defaults.
- Copied updated `sandbox-options.txt` to `C:\Users\Zero\Zomboid\Workshop\BarricadesHurtZombiesB42\Contents\mods\BarricadesHurtZombies\42\media\sandbox-options.txt`; SHA256 hash matched source.

### Caveat
- These are sandbox defaults. Existing saves or servers may retain previously persisted values. Confirm by checking the `[BHZCore/Config]` line after load.

## 2026-05-02 Runtime Log Review

### Read And Checked
- `C:\Users\Zero\Zomboid\console.txt`: last write `2026-05-02 20:37:39`, contains active BHZ diagnostic output.
- `C:\Users\Zero\Zomboid\Logs\2026-05-02_20-28_DebugLog.txt`: contains timestamped BHZ diagnostic output.

### Findings
- The loaded code is the instrumented diagnostic build. Logs contain `[BHZCore/Thump] CALC`, `[BHZCore/Vehicle] CALC`, `[BHZCore/Damage] DMG`, and trace `SKIP_COOLDOWN` lines.
- Startup/version/config lines were not present in the available logs; both log files appear to start after BHZ had already initialized.
- Runtime side was singleplayer: all BHZ damage lines show `side=sp`; no `[BHZCore/MP]` lines were present.
- Door/window thump damage was `WOOD`, `base=0.0500`, `materialMult=1.000`, `damage=0.0500`, `cooldown=500`.
- StepVan vehicle damage was `METAL`, `base=0.0500`, `materialMult=1.250`, `damage=0.0625`, `cooldown=500`.
- Damage cadence was generally about `0.50-0.64` seconds per applied hit, matching the cooldown model.
- Several zombies had high HP: examples include `3.698`, `3.404`, `3.199`, and `2.895`, which is consistent with Tough or Random zombie toughness rather than Normal-only toughness.
- Door/window zombies died after many hits, not 3-4 hits: examples include 74, 64, 58, 39, 34, 30, and 26 thump hits.
- Vehicle zombies with low starting HP died after 8-12 vehicle hits; other vehicle targets survived 15 hits.

### Current Conclusion
- This playtest did not reproduce the fast-kill report. It showed the opposite behavior: current defaults are slow against high-HP zombies.
- The Workshop reports may be from Fragile or Random low-health zombies, different sandbox damage values, different target materials, or users counting visible thumps differently than BHZ cooldown ticks.
- Need a fresh load where `[BHZCore/Config]` appears to confirm actual zombie lore and BHZ sandbox values, or use the game sandbox UI/server config to confirm zombie Toughness.

## 2026-05-02 Focused Logging Adjustment

### Issue
- Runtime logs were too noisy because `VehicleDebugMode=true` promoted `currentLogLevel` to TRACE. That produced thousands of `SKIP_COOLDOWN` lines even when the intended diagnostic level was `LogLevel=5`.

### Changes Made
- Changed `BHZCore.lua` so `DebugMode` or `VehicleDebugMode` only guarantee DEBUG-level logging.
- TRACE-level cooldown and filter skip logs now require explicitly setting `LogLevel=6`.
- Updated `TESTING.md` to document that `VehicleDebugMode` no longer forces trace output.
- Copied updated `BHZCore.lua` to `C:\Users\Zero\Zomboid\Workshop\BarricadesHurtZombiesB42\Contents\mods\BarricadesHurtZombies\42\media\lua\shared\BHZCore.lua`; SHA256 hash matched source.

### Tested
- `git diff --check` passed for `BHZCore.lua` and `TESTING.md`.
- Em dash and banned Lua feature scan found no matches in touched files.
- `npx --yes luaparse` parsed `BHZCore.lua` successfully.

## 2026-05-02 Dev Title Marker

### Change Made
- Added ` - Dev` to the `name=` field in all three BHZ `mod.info` files so the loaded local test build is obvious in the in-game mod list.
- Left `id`, `version`, and Workshop-facing metadata unchanged.

### Upload Note
- Remove the ` - Dev` suffix from all three `mod.info` files before publishing the Workshop update.

## 2026-05-02 Vehicle Debug Default

### Decision
- Set `VehicleDebugMode` default back to `false` for focused playtest logging.
- Kept `LogLevel` default at `5` so structured `[BHZCore/Vehicle] CALC` diagnostics still appear without older vehicle debug chatter.

## 2026-05-02 Enhanced Tick Diagnostics

### Planned
- Make user-submitted logs self-contained enough to diagnose fast-kill reports without manually pairing calc and damage lines.

### Changes Made
- Added `[BHZCore/Tick] TICK` log lines for every applied BHZ damage tick.
- Each tick line includes side, zombie id, hit count, source, formula, base damage, material, material multiplier, object multiplier, computed damage, actual HP removed, old HP, new HP, cumulative computed damage, cumulative removed HP, cooldown, target, vehicle, part, and blood flag.
- Added `ZombieLore.Toughness` to config logging.
- Added `tools/validate-bhz-diagnostics.ps1` to statically verify the required diagnostic fields remain present.
- Updated `TESTING.md`, `CHANGELOG.bbcode`, and the Workshop reply draft with debug logging instructions and GitHub issue instructions.

### Validation Plan
- Run the diagnostics validation script before upload.
- Parse `BHZCore.lua` with `luaparse`.
- Copy the updated Lua and docs needed for upload staging.

### Tested
- `tools/validate-bhz-diagnostics.ps1` passed.
- `npx --yes luaparse` parsed `BHZCore.lua` successfully.
- `git diff --check` passed for touched Lua, docs, campaign, reply, and validation script files.
- Em dash scan found no matches in touched files.
- Copied updated `BHZCore.lua` to `C:\Users\Zero\Zomboid\Workshop\BarricadesHurtZombiesB42\Contents\mods\BarricadesHurtZombies\42\media\lua\shared\BHZCore.lua`; SHA256 hash matched source.

## 2026-05-02 Upload Defaults Reset

### Changes Made
- Removed ` - Dev` from all three BHZ `mod.info` titles for upload.
- Set `DebugMode` default back to `false`.
- Kept `VehicleDebugMode` default at `false`.
- Set `LogLevel` default back to `1` so enhanced logging is available but opt-in.

### Tested
- Copied updated `mod.info` files and `sandbox-options.txt` to the Workshop staging folder; SHA256 hashes matched source.
- Verified source and staged debug option blocks: `DebugMode=false`, `VehicleDebugMode=false`, `LogLevel=1`.
- Verified no ` - Dev` markers remain in source or staged `mod.info` files.
- `tools/validate-bhz-diagnostics.ps1` still passed.
- `git diff --check` passed for the upload default reset files.
- Em dash scan found no matches in touched files.

## 2026-05-02 Tick Counter Consistency Fix

### Read And Checked
- `C:\Users\Zero\Zomboid\Logs\2026-05-02_21-15_DebugLog.txt` had 314 `[BHZCore/Tick]` lines, 314 `[BHZCore/Damage]` lines, and 314 CALC lines.

## 2026-05-06 B42.17 ThumpFrame Gate

### Planned
- Change default thump and vehicle cooldowns to 750 ms without changing damage values.
- Verify whether B42.17 exposes actual zombie thump hit-frame data to Lua.

### Read And Checked
- Decompiled targeted B42.17 classes from `projectzomboid.jar`: `ThumpState`, `AttackVehicleState`, `IsoZombie`, `IsoGameCharacter`, `AdvancedAnimator`, and `ActionContext`.
- Animation XML contains `ThumpFrame` events for zombie structure thumps, crawler door thumps, and vehicle thumps.
- `IsoGameCharacter.OnAnimEvent()` reports animation events into `ActionContext`.
- `ActionContext.hasEventOccurred()` and `clearEvent()` are public Java methods and case-insensitive.
- `IsoZombie.updateInternal()` fires `OnZombieUpdate` before `super.update()`.
- `ThumpState.execute()` consumes `actionContext.hasEventOccurred("thumpframe")`, calls `target.Thump(zombie)`, then clears the event.
- `AttackVehicleState.animEvent()` consumes `ThumpFrame` directly for vehicle part/window damage, while the event remains visible until the next `ActionContext.update()`.

### Decisions
- Implement guarded hit-frame gating: if `zombie:getActionContext():hasEventOccurred("thumpframe")` is available, BHZ applies damage only on that pending hit frame.
- Keep the 750 ms cooldown as a safety throttle.
- If the ActionContext API is missing or errors on a setup, log `THUMPFRAME_GATE_UNAVAILABLE` once and fall back to the prior state-plus-cooldown behavior.

### Changes Made
- Set root cooldown fallbacks, sandbox defaults, and translations to 750 ms.
- Bumped BHZ version metadata to 2.2.3.
- Added `event=ThumpFrame` or fallback status to CALC, TICK, and RPC diagnostic detail.
- Updated Workshop text, changelog, and architecture docs for v2.2.3.

### Tested
- `tools/validate-bhz-diagnostics.ps1` passed.
- `npx --yes luaparse` parsed `BHZCore.lua`.
- `git diff --check` passed for touched Lua, Workshop/docs, and validation files.
- Em dash scan found no matches in touched files.
- Synced `Contents` and `workshop.txt` to `C:\Users\Zero\Zomboid\Workshop\BarricadesHurtZombiesB42`; SHA256 checks matched for `BHZCore.lua`, `sandbox-options.txt`, all three `mod.info` files, and `workshop.txt`.

### Remaining
- Runtime SP and MP playtest to confirm Lua sees pending `ThumpFrame` exactly as decompiled control flow indicates.
- Per-tick math was consistent: each tick's `actualRemoved` matched `oldHp - newHp`, formulas matched computed damage, and no actual damage exceeded computed damage.
- Zombie ID 49 showed two diagnostic counter resets while still alive after idle gaps longer than the 10 second cooldown cleanup window.

### Root Cause
- Cooldown cleanup removed `zombieDamageStats` entries with expired cooldown entries. That made `hit`, `totalComputed`, and `totalRemoved` restart even though the zombie's health had not reset.

### Changes Made
- Cooldown cleanup now only removes cooldown entries, not cumulative diagnostic stats.
- Cooldown table size logging now requires Trace level so normal Debug reports are less noisy.

## 2026-05-02 Dedicated BHZ Debug Log

### Planned
- Create a BHZ-only diagnostic file so playtest reports do not require filtering through unrelated console noise.

### Changes Made
- Added `%USERPROFILE%\Zomboid\Lua\BHZDebug.log` output through the existing `BHZ.log` path.
- The file is rewritten once per loaded session when BHZ logging is enabled, then appends only BHZ lines with `getTimestampMs()` timestamps.
- Existing defaults remain quiet: `DebugMode=false`, `VehicleDebugMode=false`, `LogLevel=1`.
- Enabling `DebugMode=true` and `LogLevel=5` captures Config, Tick, Damage, Thump, Vehicle, MP, Kill, and startup diagnostics in the BHZ-only file.
- Config diagnostics now include debug toggles and the debug file name.
- Event diagnostics now include OnLoad, OnZombieUpdate, and OnClientCommand registration status.
- Kept file writes guarded with `pcall` so logging failures cannot break gameplay.
- Updated `TESTING.md`, `CHANGELOG.bbcode`, the Workshop reply draft, and `tools/validate-bhz-diagnostics.ps1` for the new log file.

### Validation Plan
- Run the diagnostics validation script.
- Parse `BHZCore.lua` with `luaparse`.
- Run `git diff --check` and the em dash scan on touched files.
- Copy updated upload-facing files to Workshop staging and verify hashes.

### Tested
- `tools/validate-bhz-diagnostics.ps1` passed.
- `npx --yes luaparse` parsed `BHZCore.lua` successfully.
- `git diff --check` passed for touched Lua, docs, Workshop text, reply draft, campaign, and validation script files.
- Em dash scan found no matches in touched files.
- Copied updated `BHZCore.lua` and `workshop.txt` to `C:\Users\Zero\Zomboid\Workshop\BarricadesHurtZombiesB42`; SHA256 hashes matched source.

## 2026-05-02 Human Readable Damage Diagnostics

### Planned
- Make BHZ calc and tick lines easier to read directly in `BHZDebug.log` without losing parser-friendly key fields.

### Changes Made
- Added helper formatting for expected post-hit HP, expected ticks to kill from current HP, and readable damage formulas.
- Changed `[BHZCore/Thump] CALC` to start with the source, target, current HP, expected HP after the hit, expected ticks to kill, per-hit damage, and readable formula.
- Changed `[BHZCore/Vehicle] CALC` to the same style, including vehicle, part, and target player.
- Changed `[BHZCore/Tick] TICK` to show `hp old -> new`, per-hit damage, actual removed HP, cumulative totals, and readable formula before the detailed key fields.
- Updated `tools/validate-bhz-diagnostics.ps1` to require the new human-readable diagnostic fields.

### Validation Plan
- Run the diagnostics validation script.
- Parse `BHZCore.lua` with `luaparse`.
- Run `git diff --check` and em dash scan on touched files.
- Copy updated `BHZCore.lua` to Workshop staging and verify hash.

### Tested
- `tools/validate-bhz-diagnostics.ps1` passed.
- `npx --yes luaparse` parsed `BHZCore.lua` successfully.
- `git diff --check` passed for touched Lua, campaign, and validation script files.
- Em dash scan found no matches in touched files.
- Copied updated `BHZCore.lua` to Workshop staging; SHA256 hash matched source.

## 2026-05-02 BHZ Debug Log Path Correction

### Read And Checked
- User reported that `BHZDebug.log` was not generated.
- Verified the file exists at `C:\Users\Zero\Zomboid\Lua\BHZDebug.log`, length `1162484`, last write `2026-05-02 22:16:42`.
- Read the first lines and confirmed it contains the BHZ session header, config line, event registration line, and diagnostics.

### Root Cause
- Project Zomboid `getFileWriter("BHZDebug.log")` writes relative to the Zomboid `Lua` folder, not directly under `%USERPROFILE%\Zomboid`.
- The code worked, but our documented path was wrong.

### Changes Made
- Updated runtime debug file label to `Lua/BHZDebug.log`.
- Updated `TESTING.md`, `CHANGELOG.bbcode`, Workshop description, Workshop upload text, Workshop reply draft, validation script, and campaign notes to use `%USERPROFILE%\Zomboid\Lua\BHZDebug.log`.

### Validation Plan
- Run diagnostics validation.
- Parse `BHZCore.lua` with `luaparse`.
- Run `git diff --check` and em dash scan.
- Copy updated `BHZCore.lua` and `workshop.txt` to Workshop staging and verify hashes.

## 2026-05-13 B42.18 Compatibility Release

### Planned
- Implement BHZ v2.2.4 as a Build 42.18 compatibility, docs, and Workshop metadata update.
- Do not change gameplay behavior unless runtime evidence proves a regression.
- Preserve release defaults: `DebugMode=false`, `VehicleDebugMode=false`, `LogLevel=1`.

### Read And Checked
- Local Steam install is on the Project Zomboid `unstable` beta and has `projectzomboid.jar` from the May 11 update.
- Decompiled targeted 42.18 classes into a temp folder and checked `ThumpState`, `AttackVehicleState`, `IsoZombie`, `NetworkZombieAI`, and `ActionContext`.
- 42.18 still exposes the BHZ assumptions from 42.17: `OnZombieUpdate` before `super.update()`, pending `thumpframe`, `AttackVehicleState` `ThumpFrame`, `getOwnerPlayer()`, and zombie health in `ZombiePacket.health`.

### Changes Made
- Bumped BHZ runtime and all three `mod.info` files from `2.2.3` to `2.2.4`.
- Updated Workshop description and upload text from B42.17-oriented compatibility language to B42.18 verified language.
- Added v2.2.4 changelog text noting installed 42.18 file verification and no gameplay tuning changes.
- Added a focused Build 42.18 compatibility checklist to `TESTING.md`.
- Updated `docs/tier2-bhz-architecture.md` to describe the verified B42.17 through B42.18 internals.
- Updated the Workshop reply draft support text from current B42.17 code to current B42.18 verified code.
- Synced `Contents` and `workshop.txt` to `C:\Users\Zero\Zomboid\Workshop\BarricadesHurtZombiesB42`.

### Tested
- `tools/validate-bhz-diagnostics.ps1` passed.
- `npx --yes luaparse` parsed `BHZCore.lua` successfully.
- `git diff --check` passed for touched Lua, metadata, docs, Workshop text, reply draft, and campaign files.
- Em dash scan found no matches in touched files.
- Corrected an overly strict release-default assertion that looked for `default=false` instead of the real `default = false` sandbox format. The corrected block assertion passed for `DebugMode=false`, `VehicleDebugMode=false`, and `LogLevel=1`.
- Confirmed `BHZCore.VERSION` and all three `mod.info` files report `2.2.4`.
- Confirmed no stale `B42.17+`, `B42.17 Testing Needed`, `Updated for B42.17`, or `Current B42.17` release text remains.
- Confirmed `sandbox-options.txt` exists under `42/media` and not under `common/media`.
- SHA256 hashes matched source and staging for `BHZCore.lua`, `sandbox-options.txt`, all three `mod.info` files, and `workshop.txt`.

### Remaining
- Launch Project Zomboid after the Steam update and confirm the runtime log reports Build 42.18.0. Existing `version.txt` and old console logs still reflect the previous launch until this happens.
- Run the SP 42.18 checklist for wood barricades, metal barricades, and occupied vehicles with `DebugMode=true`, `VehicleDebugMode=false`, and `LogLevel=5`.
- Run the dedicated MP checklist for server-owned and client-owned zombies.
- Do not upload to Workshop until runtime checks pass or the release is explicitly accepted as a static-verified compatibility upload.

## 2026-05-13 Pre-Upload Damage Timing Review

### Trigger
- Workshop report from IndicaBunny said three users saw zombies dying around windows, doors, and cars, and damage settings did not seem to change anything.

### Read And Checked
- Reviewed `BHZCore.lua` damage flow for sandbox loading, `DamageMode`, zero damage values, `ThumpFrame` gating, thump cooldowns, vehicle cooldowns, and MP RPC application.
- Confirmed `ThumpFrame` gating remains in place for both thump and vehicle damage.
- Confirmed default behavior intentionally includes map-placed `IsoDoor` and `IsoWindow` targets in Normal mode, matching the Workshop title, but `TESTING.md` incorrectly claimed world objects were excluded.
- Found a real settings edge case: `DamageMode=Disabled` only disabled thump targets through `BHZ.THUMP_FUNC`; vehicle damage still ran through `AttackVehicleState`.
- Found another settings edge case: `BaseDamage=0` or `VehicleBaseDamage=0` could still enter the damage path and create blood-only ticks or cooldown state.

### Changes Made
- Added `DAMAGE_MODE` as a shared sandbox mode value.
- Added explicit `DamageMode=Disabled` guards to both thump and vehicle handlers.
- Added zero-damage guards so zero base damage skips application, blood, cooldown, and RPC dispatch.
- Normalized numeric sandbox reads through `clampNumber()` for damage, multipliers, cooldowns, damage mode, and log level.
- Renamed the misleading `isPlayerBuiltOrMoved` helper to `checkNormalDamageSources` without changing Normal-mode target coverage.
- Updated `TESTING.md`, changelog, Workshop description, Workshop upload text, and tier 2 architecture notes to reflect the actual behavior and the hardening.
- Updated `tools\validate-bhz-diagnostics.ps1` to require the damage mode and zero-damage guard markers.
- Synced `Contents` and `workshop.txt` to `C:\Users\Zero\Zomboid\Workshop\BarricadesHurtZombiesB42`.

### Tested
- `tools\validate-bhz-diagnostics.ps1` passed.
- `npx --yes luaparse` parsed `BHZCore.lua` successfully.
- `git diff --check` passed for touched Lua, docs, Workshop text, and validation script files.
- Em dash scan found no matches in touched files.
- Static guard assertion passed for `DAMAGE_MODE`, `SKIP_DISABLED`, `SKIP_ZERO_DAMAGE`, and removal of the stale helper name.
- SHA256 hashes matched source and staging for `BHZCore.lua`, `sandbox-options.txt`, all three `mod.info` files, and `workshop.txt`.

### Remaining
- Runtime test with `DamageMode=Disabled` should verify no window, door, or occupied vehicle damage.
- Runtime test with `BaseDamage=0` and `VehicleBaseDamage=0` should verify no blood-only ticks.
- A report of corpses near map doors/windows can still be normal configured behavior, especially with mods that attract nearby zombies to thump sounds. Logs are still required to separate expected accumulation from a timing regression.

## 2026-05-20 Fast-Forward Hit-Frame Review

### Trigger
- Workshop report from KmartSecurity said `BaseDamage=25` kills zombies after 3 to 4 seconds at normal speed, but fast-forward lets zombies destroy 8 planks and the window without any dying.
- User clarified the intended design should be per hit, with no cooldown on real hits.

### Evidence
- Reviewed installed Build 42.18 `projectzomboid.jar` with `javap`.
- `ThumpState` uses `getFastForwardDamageMultiplier()` based on `GameTime.getTrueMultiplier()` for vanilla object damage during fast-forward.
- `AttackVehicleState` still uses animation event names `AttackCollisionCheck` and `ThumpFrame`, with `ThumpFrame` driving vehicle thump damage.
- Existing BHZ v2.2.4 code already gated damage on pending `ThumpFrame` when available, but still applied the configured cooldown to real hit-frame events.

### Decision
- Real `ThumpFrame` damage should be one BHZ tick per observed hit frame.
- The gameplay path should fail closed if the hit-frame API is unavailable. No state-plus-timer damage approximation.
- The server RPC safety cooldown should remain because it is an MP abuse/desync guard, not gameplay timing.

### Changes Made
- Added `getGameTimeScale()` and `getEffectiveCooldown()` helpers.
- Changed thump and vehicle handlers so `event=ThumpFrame` uses `cooldown=hitframe`, `effectiveCooldown=0.0`, and no configured cooldown gate.
- Removed state-plus-timer fallback damage. If the hit-frame API is unavailable or errors, BHZ logs `THUMPFRAME_GATE_UNAVAILABLE` and skips damage.
- Kept the server RPC safety cooldown, but scaled it by game time multiplier as an abuse guard.
- Added `effectiveCooldown` and `timeScale` to CALC, TICK, and RPC diagnostic detail.
- Updated `TESTING.md`, changelog, Workshop description, Workshop upload text, architecture notes, and diagnostics validation to document the new timing model.

### Validation Plan
- Run diagnostics validation.
- Parse `BHZCore.lua` with `luaparse`.
- Run `git diff --check` and em dash scan on touched files.
- Sync source to Workshop staging and verify SHA256 hashes for upload-critical files.

### Tested
- `tools\validate-bhz-diagnostics.ps1` passed.
- `npx --yes luaparse` parsed `BHZCore.lua` successfully.
- `git diff --check` passed for touched Lua, docs, Workshop text, validation script, and campaign files.
- Em dash scan found no matches in touched files.
- Static hit-frame timing marker assertion passed for `cooldown=hitframe`, fail-closed `THUMPFRAME_GATE_UNAVAILABLE`, server effective cooldown, and timing diagnostics.
- Synced `Contents` and `workshop.txt` to `C:\Users\Zero\Zomboid\Workshop\BarricadesHurtZombiesB42`.
- SHA256 hashes matched source and staging for `BHZCore.lua`, `sandbox-options.txt`, all three `mod.info` files, and `workshop.txt`.

### Remaining
- Runtime SP fast-forward test should confirm real `ThumpFrame` lines show `cooldown=hitframe`, `effectiveCooldown=0.0`, and `timeScale > 1.00`.
- Runtime dedicated MP should confirm client-owned zombies still send `RPC_SEND` and the server path accepts or safely no-ops without double damage.

### Runtime Prep
- Rotated old `%USERPROFILE%\Zomboid\Lua\BHZDebug.log` to `BHZDebug.pre-hitframe-20260520-072645.log`.
- Synced updated source mod files to `C:\Users\Zero\Zomboid\mods\BarricadesHurtZombiesB42` for local SP runtime testing.
- Verified the local runtime copy matches source hashes for `BHZCore.lua`, `sandbox-options.txt`, and all three `mod.info` files.

### 2026-05-20 SP Lua Error Follow-Up
- New SP run produced `console.txt` but no `Lua\BHZDebug.log`.
- Console confirmed BHZ v2.2.4 loaded on PZ 42.18.0, but sandbox settings were still `DebugMode=false`, `VehicleDebugMode=false`, and `LogLevel=1`.
- Runtime error was `attempted index: hasEventOccurred of non-table: zombie.characters.action.ActionContext`.
- Root cause: `getPendingThumpFrameEvent()` checked `actionContext.hasEventOccurred` as a Lua table field before calling it. Build 42.18 exposes this as a Java object that must be called inside `pcall`.
- Fixed `getPendingThumpFrameEvent()` to call both `zombie:getActionContext()` and `actionContext:hasEventOccurred("thumpframe")` through protected call wrappers, with fallback status if either call fails.
- Updated diagnostics validation to require the protected ActionContext call pattern.
- Revalidated diagnostics, parsed `BHZCore.lua` with `luaparse`, and synced the corrected source to both local runtime mod and Workshop staging.

### 2026-05-20 Fail-Closed Hit-Frame Contract
- User rejected gameplay fallback because it simulated the intended per-hit behavior through state polling.
- Changed `shouldProcessPendingThumpFrame()` so only a real `ThumpFrame` returns true.
- If `zombie:getActionContext()` or `actionContext:hasEventOccurred("thumpframe")` is unavailable or errors, BHZ now logs `THUMPFRAME_GATE_UNAVAILABLE status=<reason> action=skip_damage` and applies no damage.
- Removed state-plus-timer fallback damage and removed active thump and vehicle cooldown sandbox options from `42/media/sandbox-options.txt`.
- Updated config logging to report `hitFrameRequired=true` instead of gameplay cooldown values.
- Kept the separate server RPC safety cooldown because it protects MP command handling after a real client hit and is not a replacement gameplay model.
- Updated `TESTING.md`, changelog, Workshop description, Workshop upload text, architecture notes, and diagnostics validation to match the fail-closed contract.
- Revalidated diagnostics, parsed `BHZCore.lua`, verified no timer fallback markers remain in `BHZCore.lua`, verified cooldown options are removed from active B42 sandbox options, synced local runtime and Workshop staging, and verified source/staging hashes.

### 2026-05-20 ActionContext Lua Interop Failure
- New runtime screenshot showed Lua debugger breaking at `actionContext:hasEventOccurred("thumpframe")` inside `pcall`.
- Console evidence showed `attempted index: hasEventOccurred of non-table: zombie.characters.action.ActionContext`.
- Root cause: `ActionContext.hasEventOccurred()` is public Java but not safely Lua-callable in this runtime. Wrapping it in `pcall` still surfaces a PZ Lua error, so this path cannot ship.
- Replaced Lua ActionContext hit gating with Lua-visible vanilla hit results:
  - Structure hits require `zombie:getThumpCondition()` to decrease for that zombie and target.
  - Vehicle hits require selected vehicle window health or vehicle part condition to decrease.
  - Vehicle signals are shared per vehicle part/window so one vehicle-health decrease cannot damage every zombie currently in `AttackVehicleState`.
- Added a per-zombie current-target guard so switching from one thump target to another primes the structure signal instead of comparing stale condition from a previous target.
- Kept fail-closed behavior: if a required hit signal is unavailable, BHZ logs and applies no damage.
- Restored `ThumpDamageCooldown` and `VehicleDamageCooldown` sandbox options as deprecated no-ops so existing saves do not emit unknown SandboxOption errors. Gameplay code does not read them.
- Updated `BHZDebug.lua`, translations, docs, changelog, testing checklist, Workshop text, and diagnostics validation for the hit-signal model.

## 2026-05-02 Self-Contained Debug Header

### Decision
- The BHZ log should collect everything the mod can know automatically. Users should not have to manually restate PZ build, SP/MP side, zombie lore, BHZ settings, or active mods when they provide `BHZDebug.log`.

### Changes Made
- Added `[BHZCore/Environment]` header logging with PZ build, BHZ version, side, `isClient`, `isServer`, and debug file path.
- Added `[BHZCore/Sandbox]` header logging for all simple `SandboxVars.BarricadesHurtZombies` values.
- Added `[BHZCore/Sandbox]` header logging for all simple `SandboxVars.ZombieLore` values.
- Added `[BHZCore/Mods]` header logging with active mod count and active mod IDs, plus name/version/workshop fields when PZ exposes them.
- Updated the Workshop reply and Workshop description to ask users to enable logging and share the BHZ log, plus a short note about what looked wrong in-game.
- Updated docs and changelog to describe the self-contained log header.

### Validation Plan
- Run diagnostics validation.
- Parse `BHZCore.lua` with `luaparse`.
- Run `git diff --check` and em dash scan.
- Copy updated `BHZCore.lua` and `workshop.txt` to Workshop staging and verify hashes.
