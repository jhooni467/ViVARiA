# ViVARiA

Create your world and experiment.

ViVARiA is a native Android-first 2D ecosystem sandbox made with Godot 4.7.2.

## Artistic direction

A colorful, flat 2D illustrated world with layered landscapes, organic silhouettes, soft lighting and distinct biome palettes.

## First prototype

The initial prototype establishes the native Godot project, a sample illustrated landscape, and camera navigation.

- Drag with one finger to move around the world.
- Pinch with two fingers to zoom.
- On desktop, drag with the left mouse button and use the mouse wheel to zoom.

This is a foundation build. Terrain painting, water editing, vegetation placement, creatures, ecosystem simulation, procedural world generation and save/load are not implemented yet.

## Technology

- Godot 4.7.2
- GDScript
- 2D renderer: Compatibility
- Android export: arm64 APK
- GitHub Actions for validation and APK artifacts

## Build

Push to the `main` branch or run the **ViVARiA Android APK** workflow manually. A successful run uploads an artifact named `ViVARiA-Android-APK`.

The APK is a debug build intended for device testing, not a Play Store release.
