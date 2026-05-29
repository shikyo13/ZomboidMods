# Rendering & Visual System - PZ Data Map
Source: projectzomboid.jar (decompiled) | media/lua | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Architecture Overview | 20-35 |
| 2 | Isometric Rendering Pipeline | 37-79 |
| 3 | IsoSprite System | 81-131 |
| 4 | IsoSpriteManager | 133-156 |
| 5 | Texture System | 158-191 |
| 6 | FBO Render Chunk System | 193-223 |
| 7 | Tile Depth Sorting | 225-258 |
| 8 | Lighting System | 260-288 |
| 9 | Visibility / Fog of War | 290-313 |
| 10 | Shaders and Styles | 315-339 |
| 11 | Modding Custom Sprites | 341-374 |
| 12 | Lua Rendering API | 376-410 |

## 1. Architecture Overview

PZ uses LWJGL (OpenGL) with a custom isometric 2D/3D hybrid renderer. Two threads:
game thread populates draw commands, render thread executes OpenGL calls via a triple-buffered
`SpriteRenderer.ringBuffer`.

| Package | Contents |
|-|-|
| `zombie.core` | SpriteRenderer, shaders, colors, VBOs |
| `zombie.core.textures` | Texture, TextureFBO, SmartTexture, TextureDraw |
| `zombie.core.opengl` | Shader, ShaderProgram, GLState, RenderThread |
| `zombie.core.Styles` | Blend modes: Additive, Transparent, Lighting |
| `zombie.iso.sprite` | IsoSprite, IsoSpriteManager, IsoSpriteInstance |
| `zombie.iso.fboRenderChunk` | FBO chunk caching, render layers, cutaways |
| `zombie.tileDepth` | Depth textures, tile geometry, seam fixing |
| `zombie.vispoly` | VisibilityPolygon2 (fog of war) |

## 2. Isometric Rendering Pipeline

### Render Flow

1. Game thread populates `SpriteRenderState` with `TextureDraw` commands
2. `SpriteRenderer.ringBuffer` transfers state to render thread (triple-buffered)
3. Render thread processes commands via OpenGL
4. FBO chunks are cached per-chunk and composited each frame

### Coordinate System

World (x, y, z) maps to screen:
- Screen X = `(x - y) * tileWidth/2`
- Screen Y = `(x + y) * tileHeight/2 - z * tileHeight`
- `Core.tileScale` = 1 (default) or 2 (2x resolution)

### Object Render Layers (`ObjectRenderLayer` enum)

| Layer | Purpose |
|-|-|
| `Floor` | Floor tiles |
| `Vegetation` | Trees, bushes |
| `Corpse` | Dead bodies |
| `MinusFloor` / `MinusFloorSE` | Below-floor items |
| `WorldInventoryObject` | Dropped items |
| `Translucent` / `TranslucentFloor` | Semi-transparent objects |

### Wall Rendering

| Shaper Class | Purpose |
|-|-|
| `WallShaperWhole` | Full wall rendering |
| `WallShaperSliceW` | West wall cutaway slice (offset +32x, -16y) |
| `WallShaperSliceN` | North wall cutaway slice (offset -32x, -16y) |
| `CutawayAttachedModifier` | Attached sprites in cutaway zones |

### Key Constants

| Constant | Value |
|-|-|
| `IsoSprite.DEFAULT_SPRITE_ID` | 20000000 |
| `SpriteRenderer.NUM_RENDER_STATES` | 3 (triple buffer) |
| `SpriteRenderer.VERTEX_SIZE` | 36 bytes |

## 3. IsoSprite System

`zombie.iso.sprite.IsoSprite` - core sprite definition. Each tile, object, animation is one.

### Key Fields

| Field | Type | Purpose |
|-|-|-|
| `name` | String | e.g. `"floors_interior_tilesandwood_01_0"` |
| `tilesetName` | String | Parent tileset |
| `tileSheetIndex` | int | Index within tileset |
| `id` | int | Numeric ID (default 20000000) |
| `texture` | Texture | Current texture |
| `properties` | PropertyContainer | Tile flags (solid, invisible, etc.) |
| `tintMod` | ColorInfo | Base tint (r,g,b,a) |
| `currentAnim` | IsoAnim | Active animation |
| `soffX/Y` | short | Pixel offset |
| `renderLayer` | byte | RL_DEFAULT=0, RL_FLOOR=1 |
| `depthTexture` | TileDepthTexture | Depth map for 3D sorting |
| `spriteModel` | SpriteModel | Optional 3D model |
| `modelSlot` | ModelSlot | 3D model render slot |

### Boolean Flags

| Flag | Effect |
|-|-|
| `solid` | Blocks movement |
| `invisible` | Not rendered |
| `alwaysDraw` / `forceRender` | Ignore culling |
| `moveWithWind` / `isBush` | Wind animation |
| `cutW` / `cutN` | Wall cutaway flags |
| `forceAmbient` | Force ambient lighting |
| `treatAsWallOrder` | Render in wall order |

### IsoSpriteInstance (per-object instance from pool)

| Field | Type | Default | Purpose |
|-|-|-|-|
| `tintr/g/b` | float | 1.0 | Per-instance tint |
| `alpha` / `targetAlpha` | float | 1.0 | Transparency / fade target |
| `frame` | float | 0 | Animation frame |
| `flip` | boolean | false | Horizontal flip |
| `offX/Y/Z` | float | 0 | Position offset |
| `scaleX/Y` | float | 1.0 | Scale multiplier |
| `animFrameIncrease` | float | 1.0 | Animation speed |

### Render Dispatch

`IsoSprite.render()` checks `hasActiveModel()` - if true, renders the 3D model via
`renderActiveModel()`. Otherwise calls `renderCurrentAnim()` which resolves textures,
applies lighting (unless `IsoFlagType.unlit`), and submits to `SpriteRenderer`.

## 4. IsoSpriteManager

Singleton registry (`IsoSpriteManager.instance`). Two maps:

| Map | Key | Purpose |
|-|-|-|
| `namedMap` | HashMap<String, IsoSprite> | Lookup by name |
| `intMap` | TIntObjectHashMap<IsoSprite> | Lookup by numeric ID |

### Key Methods

| Method | Purpose |
|-|-|
| `getSprite(int gid)` | Get by ID (null if missing) |
| `getSprite(String gid)` | Get by name, auto-creates via `AddSprite` if missing |
| `getOrAddSpriteCache(String)` | Get or create from texture name |
| `AddSprite(String, int)` | Create with specific ID, warns on duplicate |
| `Dispose()` | Clear all sprites and anims |

### Naming Convention

Sprites: `{tileset}_{index}` (e.g. `"walls_exterior_house_01_4"`).
`IsoSprite.getSprite(manager, name, offset)` navigates within tilesets.
`WorldConverter.tilesetConversions` handles save migration of sprite IDs.

## 5. Texture System

### Texture Class (`zombie.core.textures.Texture`)

Extends `Asset` for async loading. Key fields: `dataid` (OpenGL handle), `offsetX/Y`,
`xStart/End`, `yStart/End` (UV coords), `flip`, `bindAlways`.

### Registries

| Registry | Purpose |
|-|-|
| `textures` (HashMap) | Global path-to-texture map |
| `s_sharedTextureTable` | Shared textures for texture packs |
| `nullTextures` (HashSet) | Textures confirmed missing |

### Loading Flow

1. `Texture.getSharedTexture(path)` checks shared table
2. Creates `Asset`, queues for async load on worker thread
3. `TextureAssetManager` loads PNG, creates OpenGL texture
4. Tilesets packed into `TexturePackPage` atlas pages

### SmartTexture

Composites multiple layers via `TextureCombinerCommand` at runtime:
- `CharacterSmartTexture` - character body + clothing + blood + dirt
- `ItemSmartTexture` - individual clothing item textures
- Each layer: category ID, intensity shader param, mask texture

### FBO Types

- `TextureFBO` - single FBO (color + optional depth)
- `MultiTextureFBO2` - multiple render targets
- Used by chunk caching and visibility systems

## 6. FBO Render Chunk System

B42 uses FBO-based chunk caching (`PerformanceSettings.fboRenderChunk`).

| Class | Role |
|-|-|
| `FBORenderChunkManager` | Pool management, chunk lifecycle |
| `FBORenderChunk` | Single cached chunk FBO |
| `FBORenderCell` | Cell-level render orchestration |
| `FBORenderLevels` | Per-z-level FBO management |

### Specialized Renderers

| Renderer | Purpose |
|-|-|
| `FBORenderShadows` | Shadow pass |
| `FBORenderOcclusion` | Occlusion culling |
| `FBORenderCutaways` | Wall/roof cutaway |
| `FBORenderTrees` | Tree rendering |
| `FBORenderSnow` | Snow overlay |
| `FBORenderCorpses` | Dead body rendering |
| `FBORenderItems` | World inventory items |
| `FBORenderObjectPicker` | Mouse picking |
| `FBORenderObjectHighlight` | Ghost tile/highlight |
| `FBORenderObjectOutline` | Selection outlines |
| `FBORenderTracerEffects` | Bullet tracers |

### Lifecycle

Chunks allocated from size-indexed pool, dirty chunks re-rendered on change.
Supports 1.0x and 0.5x scale levels (distant chunks). Recycled via stack.

## 7. Tile Depth Sorting

### Depth Textures

Per-tile float arrays for per-pixel depth testing during rendering.

| Class | Role |
|-|-|
| `TileDepthTexture` | Individual tile depth map |
| `TilesetDepthTexture` | Full tileset depth atlas |
| `TileDepthTextureManager` | Load/cache depth textures |
| `TileDepthMapManager` | Preset depth maps |

### Depth Presets (`TileDepthMapManager.TileDepthPreset`)

| Preset | Index | Usage |
|-|-|-|
| `Floor` | 0 | Flat floor tiles |
| `WDoorFrame` / `NDoorFrame` | 2 / 3 | Door frames |
| `WWall` / `NWall` | 4 / 5 | Walls |
| `NWWall` / `SEWall` | 6 / 7 | Corner walls |

### Depth Flags (`IsoSprite.depthFlags`)

| Flag | Value | Meaning |
|-|-|-|
| `SDF_USE_OBJECT_DEPTH_TEXTURE` | 1 | Use sprite's own depth texture |
| `SDF_TRANSLUCENT` | 2 | Translucent depth handling |
| `SDF_OPAQUE_PIXELS_ONLY` | 4 | Depth write for opaque pixels only |

### Tile Geometry

`TileGeometry` reads 3D polygon shapes from `tileGeometry.txt`. Properties assignable
per-tile. `TileSeamManager`/`TileSeamModifier` fixes seams between adjacent tiles.

## 8. Lighting System

### IsoLightSource

| Field | Type | Purpose |
|-|-|-|
| `x, y, z` | int | World position |
| `r, g, b` | float | Light color (0-1) |
| `radius` | int | Radius in tiles |
| `active` | boolean | Currently emitting |
| `life` | int | Remaining ticks (-1 = infinite) |
| `localToBuilding` | IsoBuilding | Indoor association |
| `hydroPowered` | boolean | Needs hydro power |
| `switches` | ArrayList | Connected light switches |

### LightingJNI

JNI-accelerated per-square lighting. Key limits: `MAX_LIGHTS_PER_PLAYER=4`,
`MAX_LIGHTS_PER_VEHICLE=10`, `ROOM_SPAWN_DIST=50`.

### Flow

1. Collects all active `IsoLightSource` objects
2. Gathers player torches/flashlights from equipped items
3. Adds vehicle lights (`VehicleLight`)
4. JNI computes per-square `ColorInfo` (r,g,b,a)
5. Ambient from `ClimateManager` time-of-day
6. `IsoRoomLight` manages indoor rooms; curtains/barricades affect light penetration
7. Sprites with `IsoFlagType.unlit` bypass lighting (r/g/b forced to 1.0)

## 9. Visibility / Fog of War

### VisibilityPolygon2

Singleton. `drawers[4][3]` - per-player (up to 4), per-render-state (triple-buffered).

| Drawer Field | Type | Purpose |
|-|-|-|
| `px, py, pz` | float | Player position |
| `visionCone` | float | Cone angle |
| `lookAngleRadians` | float | Direction facing |
| `circleRadius` | float | Default 40.0 tiles |
| `partitions[8]` | Partition[] | Spatial partitioning |

### Flow

1. `renderMain(playerIndex)` called per player per frame
2. `calculateVisibilityPolygon()` casts rays from player
3. `VisibilityWall` objects block rays
4. Trees reduce visibility (`insideTree` flag)
5. `Clipper` library does polygon boolean ops
6. Result rendered as stencil mask
7. `dirtyObstacleCounter` triggers recalc when chunks load
8. `LosUtil.lineClear()` provides per-square LOS for both rendering and AI

## 10. Shaders and Styles

### Blend Styles

| Style | Blend Function | Use |
|-|-|-|
| `TransparentStyle` | SrcAlpha, OneMinusSrcAlpha | Default sprites |
| `AdditiveStyle` | SrcAlpha, One | Glow, fire |
| `LightingStyle` | Zero, SrcColor | Light maps |
| `UIFBOStyle` | One, OneMinusSrcAlpha | UI FBO composite |

### Shader Classes

| Class | Purpose |
|-|-|
| `DefaultShader` | Standard sprite shader |
| `DepthShader` | Depth-only pass |
| `TileDepthShader` | Per-pixel tile depth test |
| `TileSeamShader` | Seam fixing between tiles |
| `CutawayAttachedShader` | Cutaway attached sprites |
| `FogShader` | Fog rendering |
| `SDFShader` | SDF text rendering |
| `SmartShader` | Auto-reloading with file watch |

`SceneShaderStore` manages per-frame scene uniforms (time, weather, camera).

## 11. Modding Custom Sprites

### Custom Tilesets

Place tileset PNGs in `media/texturepacks/`. Name: `{tilesetName}_{page}.png`.
Create `.pack` file for tile dimensions. Tiles auto-register in `IsoSpriteManager`.

### Lua Sprite Access

```lua
local sprite = IsoSpriteManager.instance:getSprite("mymod_tiles_0")
local spr = IsoSpriteManager.instance:AddSprite("mymod_customtile")
local props = sprite:getProperties()
local isSolid = props:Is(IsoFlagType.solid)
```

### Custom Textures

Place PNGs in mod `media/textures/`. Mod paths checked before base game.

```lua
local tex = getTexture("media/textures/myimage.png")
```

### Sprite Properties (set in TileZed, accessible via PropertyContainer)

| Property | Type | Purpose |
|-|-|-|
| `IsoFlagType.solid` | flag | Blocks movement |
| `IsoFlagType.trans` | flag | Transparent |
| `IsoFlagType.invisible` | flag | Not rendered |
| `IsoFlagType.container` | flag | Has inventory |
| `IsoFlagType.canBeRemoved` | flag | Player can disassemble |
| `IsoPropertyType.waterAmount` | value | Water content |

## 12. Lua Rendering API

### SpriteRenderer Methods

| Method | Purpose |
|-|-|
| `render(tex, x, y, w, h, r, g, b, a)` | Draw texture |
| `renderflipped(tex, x, y, w, h, r, g, b, a)` | Draw flipped |
| `renderi(tex, x, y, w, h, r, g, b, a)` | Integer-position render |
| `renderline(tex, x1, y1, x2, y2, r, g, b, a)` | Draw line |
| `renderRect(x, y, w, h, r, g, b, a)` | Draw rectangle |
| `renderPoly(tex, x1..x4, y1..y4, r, g, b, a)` | Textured quad |
| `drawModel(modelSlot)` | Render 3D model |
| `drawWater/drawPuddles/drawParticles` | Specialized draws |
| `glDepthMask(b)` | Toggle depth writing |

### IsoSprite Lua Methods

| Method | Purpose |
|-|-|
| `getProperties()` | Get PropertyContainer |
| `hasProperty(type)` | Check property |
| `RenderGhostTile(x,y,z)` | Preview placement |
| `RenderGhostTileColor(x,y,z,r,g,b,a)` | Colored preview |
| `renderBloodSplat(x,y,z,info)` | Blood overlay |
| `newInstance()` | Create IsoSpriteInstance |

### IsoLightSource Lua Access

```lua
local light = IsoLightSource.new(x, y, z, r, g, b, radius, life)
light.active = true
light.r = 1.0; light.g = 0.8; light.b = 0.4
light.radius = 10
```
