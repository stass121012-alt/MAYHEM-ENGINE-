# MAYHEM ENGINE — Godot 4

A first playable 3D physics sandbox foundation for **Windows PC + Android**.

## Open the project
1. Download this repository with **Code → Download ZIP**.
2. Extract the ZIP.
3. Open Godot 4.3 or newer.
4. Import the extracted `project.godot`.
5. Press **F6/F5** to run.

## PC controls
- **WASD** — move
- **Mouse** — look around
- **Space** — jump
- **E** — pick up / drop a physics object
- **Q** — throw the held object
- **B** — toggle build mode
- **Left mouse** — use physics tool / place a block
- **1–4** — select material
- **F** — spawn a cube
- **Esc** — release mouse

## Included in this prototype
- First-person CharacterBody3D controller
- Physics props with collision
- Pick up, drop and throw
- Physical block placement mode
- Breakable test crate that fragments into physics pieces
- Industrial test sandbox
- On-screen action buttons and touch look/movement input

## Android export
Install matching Godot export templates, Android SDK and JDK, then configure them in **Editor Settings → Export → Android**. The project uses the Compatibility renderer for broad device support.

## Current scope
This is an early playable foundation, not a finished commercial game. Planned milestones:
1. Joint-based building (hinges, welds, ropes)
2. Improved fracture system and debris pooling
3. NPCs and ragdolls
4. Save/load sandbox
5. Mobile performance and Android export presets
