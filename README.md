# ViVARiA

**Create your world and experiment.**

ViVARiA is a native Android-first 2D sandbox made with Godot 4.7.2. It focuses on relaxed world creation with a colorful, illustrated look.

## Current playable slice

The first editor prototype includes:

- A layered, illustrated meadow world.
- A Tierra brush for adding organic soil patches.
- An Agua brush for creating small pools.
- A Plantas brush that places flowers, bushes, and young trees.
- A Borrar tool for removing placed edits.
- Adjustable brush size.
- Touch-first controls: one finger to paint, two fingers to pan and zoom.
- Desktop controls: left mouse button to paint, middle/right mouse button to pan, and mouse wheel to zoom.

Edits currently live only in the running session. Saving/loading, terrain sculpting, procedural world generation, creatures, climate systems, and active ecosystem simulation are not implemented yet.

## Artistic direction

A colorful, flat 2D illustrated world with layered landscapes, organic silhouettes, soft lighting, and distinct biome palettes. The camera stays flat: the world can be moved and zoomed, but it is not a 3D scene.

## Technology

- Godot 4.7.2
- GDScript
- 2D renderer: Compatibility
- Android export: arm64 debug APK
- GitHub Actions validation and APK artifacts

## Build

Push to the main branch or run the ViVARiA Android APK workflow manually. A successful run uploads an artifact named ViVARiA-Android-APK.

The APK is a debug build intended for device testing, not a Play Store release.
