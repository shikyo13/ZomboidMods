# Parent workspace: See ../CLAUDE.md for shared RE toolkit, engine docs, and modding conventions.

# ZomboidMods

## Project Layout
- BHZ mod: `BarricadesHurtZombiesB42/Contents/mods/BarricadesHurtZombies/`
- BarricadeContextMenu: `BarricadeContextMenu/Contents/mods/BarricadeContextMenu/`
- Dev install (PZ loads from here): `C:\Users\Zero\Zomboid\mods\`
- Workshop upload dir: `C:\Users\Zero\Zomboid\Workshop\`
- PZ install: `D:\SteamLibrary\steamapps\common\ProjectZomboid\`

## GitHub Repos
- BHZ: shikyo13/ZomboidMods (this repo)
- BarricadeContextMenu: shikyo13/BarricadeContextMenu (separate repo)

## Deployment
- Always sync dev → Workshop folder before uploading
- Use `diff -rq` to verify Workshop matches dev before upload
- Workshop uses `~/Zomboid/Workshop/{ModName}/` with workshop.txt, NOT `~/Zomboid/mods/`

## Attribution
- NEVER add Claude/AI attribution to commits, PRs, READMEs, or code comments
- Attribution is disabled in ~/.claude/settings.json

## PZ Modding Rules
- sandbox-options.txt VERSION must be 1 (hardcoded in PZ Java)
- sandbox-options.txt ONLY in `42/media/` — never duplicate in `common/media/`
- mod.info: only use recognized fields (name, id, description, versionMin, author, url, poster)
- Kahlua2: no goto/labels, no bitwise ops, string.format("%d", nil) crashes
- B42 folder structure: 42/ (build-specific), common/ (shared), root mod.info

## Documentation

| When | Read |
|-|-|
| Every PZ session | docs/tier1-pz-quickref.md |
| BHZ damage system, vehicle detection, config | docs/tier2-bhz-architecture.md |
| PZ event signatures, parameters, client/server | docs/tier3-pz-events.md - use section index |
| Kahlua2 limits, Java interop, pattern workarounds | docs/tier3-kahlua2.md - use section index |
| Any PZ game data, class, method, or system lookup | docs/data/_index.md - use file index |
| ⛔ BEFORE decompiling PZ Java classes | Check docs/data/_index.md first - only decompile if missing |

## Before Suggesting New Mods
- Check latest PZ patch notes (TIS Forums PZ Updates) to avoid building something vanilla just added
- PZ install may be on an older version - don't trust local files as current
