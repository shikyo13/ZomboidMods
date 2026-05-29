# PZ Data Library
Source: projectzomboid.jar (Build 42) + media/lua + media/scripts
Generated: 2026-03-22 | 43 files | 21,732 lines

## How to Use
Read this index to find the right file. Use `Read` with offset/limit on individual files via their section indexes.

## Fallback: Data Not in Library
If the data you need isn't covered here:
1. Decompile from projectzomboid.jar or read from media/lua
2. Document findings in the appropriate file or create a new one
3. Update this index
4. Update the Generated date

## Core Java Systems

| File | Category | Lines | Generated |
|-|-|-|-|
| [characters.md](characters.md) | IsoPlayer, IsoZombie, IsoGameCharacter hierarchy, state enums | 416 | 2026-03-22 |
| [iso-objects.md](iso-objects.md) | IsoObject hierarchy: IsoThumpable, IsoBarricade, IsoDoor, IsoWindow | 672 | 2026-03-22 |
| [iso-world.md](iso-world.md) | IsoCell, IsoGridSquare, IsoChunk, IsoMetaGrid, coordinate system | 396 | 2026-03-22 |
| [inventory.md](inventory.md) | ItemContainer, InventoryItem subtypes (Food, HandWeapon, Clothing, etc.) | 451 | 2026-03-22 |
| [combat.md](combat.md) | Damage formulas, hit detection, melee/ranged mechanics, CombatConfigKeys | 758 | 2026-03-22 |
| [damage-systems.md](damage-systems.md) | All 6 damage pipelines: Z->P, P->Z, Z->struct, V->Z, Z->V, targeting/aggro | 688 | 2026-03-22 |
| [vehicles-core.md](vehicles-core.md) | BaseVehicle, VehiclePart, VehicleDoor/Window/Light, spawn system | 677 | 2026-03-22 |
| [vehicles-mechanics.md](vehicles-mechanics.md) | VehicleScript, physics, collision damage, zombie attacks, passenger injury | 451 | 2026-03-22 |
| [ai-pathfinding.md](ai-pathfinding.md) | Zombie state machine (30+ states), pathfinding, group behavior | 448 | 2026-03-22 |
| [network.md](network.md) | GameClient/GameServer, ~140 packet types, command system, authority model | 467 | 2026-03-22 |
| [sandbox.md](sandbox.md) | Every sandbox option with type/default/range, presets, mod custom options | 677 | 2026-03-22 |
| [save-persistence.md](save-persistence.md) | Save/load, ModData API, GlobalObjects, PlayerDB | 372 | 2026-03-22 |
| [sound-audio.md](sound-audio.md) | GameSound, WorldSoundManager, zombie attraction formula, music system | 379 | 2026-03-22 |
| [weather-climate.md](weather-climate.md) | ClimateManager, temperature model, erosion, seasonal cycles | 455 | 2026-03-22 |
| [health-body.md](health-body.md) | BodyPartType (18 parts), BodyDamage, infection, Nutrition, 26 MoodleTypes | 682 | 2026-03-22 |
| [skills-perks.md](skills-perks.md) | 44 perks, XP system, professions, traits, skill books | 352 | 2026-03-22 |
| [building-construction.md](building-construction.md) | Construction system, barricade mechanics, health values, build stages | 498 | 2026-03-22 |
| [radio.md](radio.md) | Radio frequencies, broadcast scripting, signal transmission, media system | 474 | 2026-03-22 |
| [entity-system.md](entity-system.md) | B42 ECS: Engine, 22 ComponentTypes, SystemManager, MetaEntity | 430 | 2026-03-22 |
| [scripting.md](scripting.md) | ScriptManager load pipeline, ScriptParser, 35 ScriptTypes, mod overrides | 443 | 2026-03-22 |
| [ui-framework.md](ui-framework.md) | Java UIManager, UIElement, rendering pipeline, input handling, fonts | 496 | 2026-03-22 |
| [animation.md](animation.md) | AnimationSet/AnimState/AnimNode, layers, variables, combat/zombie anims | 576 | 2026-03-22 |
| [input-keybindings.md](input-keybindings.md) | GameKeyboard, Mouse, Joypad, Core.KeyBinding, LWJGL key codes | 575 | 2026-03-22 |
| [rendering.md](rendering.md) | Isometric pipeline, IsoSprite, textures, lighting, fog of war, shaders | 410 | 2026-03-22 |
| [character-appearance.md](character-appearance.md) | HumanVisual, outfits, hair/beard, clothing layers, zombie variation | 425 | 2026-03-22 |
| [console-debug.md](console-debug.md) | Debug console, 65+ server commands, DebugOptions, logging system | 500 | 2026-03-22 |
| [localization.md](localization.md) | Translator, JSON format, 27 categories, 27 languages, mod translations | 479 | 2026-03-22 |

## Lua Modding API

| File | Category | Lines | Generated |
|-|-|-|-|
| [lua-globals-world.md](lua-globals-world.md) | Global Lua functions: world, player, game state, zombies, vehicles, sound | 276 | 2026-03-22 |
| [lua-globals-utility.md](lua-globals-utility.md) | Global Lua functions: items, networking, file I/O, rendering, admin, debug | 721 | 2026-03-22 |
| [lua-events.md](lua-events.md) | 254 events across 26 categories with parameter types | 727 | 2026-03-22 |
| [lua-ui-widgets.md](lua-ui-widgets.md) | 19 IS* widget classes: hierarchy, constructors, methods | 621 | 2026-03-22 |
| [lua-timed-actions.md](lua-timed-actions.md) | ISBaseTimedAction lifecycle, 25 built-in actions, custom action patterns | 249 | 2026-03-22 |
| [lua-context-menus.md](lua-context-menus.md) | ISContextMenu API, world/inventory context menu hooks | 319 | 2026-03-22 |
| [lua-building.md](lua-building.md) | ISBuildingObject hierarchy, 17 subtypes, material requirements | 390 | 2026-03-22 |

## Game Data

| File | Category | Lines | Generated |
|-|-|-|-|
| [items-catalog.md](items-catalog.md) | 5,105 items across 15 categories, all property fields | 433 | 2026-03-22 |
| [recipes-catalog.md](recipes-catalog.md) | ~915 recipes, 23 categories, 62 evolved recipes | 447 | 2026-03-22 |
| [vehicle-definitions.md](vehicle-definitions.md) | ~80 vehicle types, parts, templates, mechanical stats | 722 | 2026-03-22 |
| [entity-definitions.md](entity-definitions.md) | 228 entity scripts across 13 categories, component format | 382 | 2026-03-22 |
| [clothing-catalog.md](clothing-catalog.md) | 109 body slots, defense values, insulation, 265 outfits | 317 | 2026-03-22 |

## Cross-Cutting Systems

| File | Category | Lines | Generated |
|-|-|-|-|
| [farming-foraging.md](farming-foraging.md) | 33 crops, 24 herbs, 21 fish, 6 traps, foraging zones | 455 | 2026-03-22 |
| [cooking-nutrition.md](cooking-nutrition.md) | Nutrition system, 722 foods, cooking mechanics, freshness/decay | 395 | 2026-03-22 |
| [zombie-population.md](zombie-population.md) | Population manager, virtual zombies, 135+ RandomizedWorld events | 481 | 2026-03-22 |
| [map-world-gen.md](map-world-gen.md) | Cell grid, 5 provinces, room/building defs, loot distribution | 499 | 2026-03-22 |

## Cross-References
- Item IDs used across recipes, vehicles, clothing -> master list in items-catalog.md
- BodyPartType enum referenced by health, clothing, combat -> defined in health-body.md
- Perk enum referenced by recipes, building, farming -> defined in skills-perks.md
- SandboxVars referenced everywhere -> defined in sandbox.md
- IsoObject hierarchy (IsoThumpable, IsoDoor, etc.) -> defined in iso-objects.md
- Zombie state names (ThumpState, AttackVehicleState, etc.) -> defined in ai-pathfinding.md
- ComponentType IDs -> defined in entity-system.md
- ScriptType enum -> defined in scripting.md
- Damage formulas cross all combat files -> unified in damage-systems.md
- Animation variables referenced by combat, timed actions -> defined in animation.md
- Key codes referenced by input events -> defined in input-keybindings.md
- Translation keys referenced by items, UI, sandbox -> format in localization.md

## Freshness
Source: projectzomboid.jar (PZ Build 42)
If PZ updates to a new build, re-extract affected data files.
Lua/script data may change with any PZ update.
Decompiled source at: ZomboidMods/decompiled/ (gitignored, re-run CFR after updates)
