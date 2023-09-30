# What is PuzzleTree?

PuzzleTree is a toolkit for making 2D tile-based turn-based games in Godot. It takes significant inspiration from PuzzleScript (http://puzzlescript.net), and optionally integrates with LDTK projects (https://ldtk.io) for tileset and level design. Sounds are left up to you, but consider using GodotSfxr ([https://github.com/tomeyro/godot-sfxr](https://github.com/tomeyro/godot-sfxr)) to keep that PuzzleScript feeling!

The goal is to enable a similar design and development experience to making a game in PuzzleScript, but with the added flexibility of a full game engine. Like PuzzleScript, the tiles are the data, turns happen in response to input, and you define how the tile grid changes each turn. Unlike PuzzleScript, it does not have a pattern-based rules system. However, there are some utility classes that you can use to help automate some behaviors, like movement and camera control.

The toolkit is built as a plugin for Godot, and is made up of:

- a handful of core nodes and scripts that make up the PuzzleTree engine
- a handful of utility nodes and scripts to assist with writing your game
- a script template to kick-start your game scripts
- example projects for reference and inspiration

## Features Overview

- Sprites can be any size (unlike PuzzleScript)
- Define multiple tilemap layers. Stack multiple tiles in each cell in each layer.
- Keeps your LDTK project and game scene in sync automatically
- Supports both Keyboard and Mouse input events
- Input buffering with dynamic execution speed to keep input the queue length short
- Built-in undo & reset

Read [the wiki](https://github.com/jackkutilek/PuzzleTree/wiki) for more details.

PuzzleTree is a work in progress! I am adding to it as needed to support my current game projects.

# Quick-Start Guide

1. Download or clone PuzzleTree and copy `addons` into your godot project directory. This should place PuzzleTree at `[godot project root]/addons/PuzzleTree/`. Enable the `PuzzleTree` plugin in Godot's Plugins menu (at `project`->`project settings`->`plugins`). This will do a few things:

- load the LDTK import plugin so Godot recognizes LDTK files,
- add some autoload scripts to the project,
- and set the `script_templates` folder to the one in the plugin.

2. Select `Project` -> `Reload current project` to reload the project. Godot needs a reload to recognize custom icons for the custom classes. Not strictly necessary, but it is nice to have.
3. Create a new scene with a root `PTGame` node.
4. Draw a tileset image in your drawing program of choice, and save it in your Godot project folder. (or copy one from the examples)
5. Create an LDTK project and save it in your Godot project folder. In LDTK:

- import your tileset,
- set your default grid size in project settings,
- adjust the level size,
- set your world layout to 'horizontal',
- create a layer,
- add some wall tiles,
- and add a player tile.

6. In Godot, set the `LDTK Project Resource` property on the `PTGame` node to your LDTK project. (Drag the project file from the `Files` tab onto the property field.) This will automatically parse your LDTK project and create some child nodes under the `PTGame` node.
7. Add `PTPlayer` and `PTMovement` nodes under the `PTGame` node. On the `PTPlayer` node, specify your player tile index and player layer. You can ignore 'Extra Collision Layers' for now.
8. Play your scene. Move your player around! Undo! Reset!
9. Next, add more nodes with scripts to the scene to further define the game's behavior. (tip: use the 'PuzzleTree Node' script template)
10. Browse the examples for some more ideas on getting started.

# Exporting

Exporting to HTML5 with default settings should work without further configuration. I have not tested other builds.

# Beyond the Grid

Remember, this is still Godot. Nothing is stopping you from adding more non-grid nodes or game state - you can even update these outside of the frame steps by implementing Godot's usual `_process` callback. Just be careful to play nice with PuzzleTree Frames getting run, or getting cancelled, or the game state getting reset. You can react to these changes by handling the necessary update callbacks.

Some ideas to consider:

- one-shot animations are easy to overlay on the grid with minimal concern for the game's state changes, and they don't have to fit within the grid
- a custom player sprite with different looping idle animations for different player states
- particle effects
- shader effects
