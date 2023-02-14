# What is PuzzleTree?

PuzzleTree is a toolkit for making 2D tile-based turn-based games in Godot. It takes significant inspiration from PuzzleScript (http://puzzlescript.net), and integrates with LDTK projects (https://ldtk.io) for tileset and level design. Sounds are left up to you, but consider using GodotSfxr ([https://github.com/tomeyro/godot-sfxr](https://github.com/tomeyro/godot-sfxr)) to keep that PuzzleScript feeling!

The goal is to enable a similar design and development experience to making a game in PuzzleScript, but with the added flexibility of a full game engine and an imperative scripting language. Like PuzzleScript, the tiles are the data, turns happen in response to input, and you define how the tile grid changes each turn. Unlike PuzzleScript, it does not have a pattern-based rules system. However, there are some utility classes that you can use to help automate some behaviors, like movement and camera control.

The toolkit is built as a plugin for Godot, and is made up of:

- a handful of core nodes and scripts that make up the PuzzleTree engine
- a handful of utility nodes and scripts to assist with writing your game
- a script template to kick-start your game scripts
- example projects for reference and inspiration

There is a bug in Godot 3.5.1 that prevents custom resources from being reloaded on change (which is needed for PuzzleTree to update when the LDTK project file is changed). It works with Godot 3.5.2. I have not yet implemented support for Godot 4.

# Quick-Start Guide

1. Download or clone PuzzleTree and copy `addons` into your godot project directory. This should place PuzzleTree at `[godot project root]/addons/PuzzleTree/`. Enable the `PuzzleTree` plugin in Godot's Plugins menu (at `project`->`project settings`->`plugins`). This will do a few things:

- load the LDTK import plugin so Godot recognizes LDTK files,
- add some autoload scripts to the project,
- configure some display stretch settings,
- and set the `script_templates` folder to the one in the plugin.

2. Select `Project` -> `Reload current project` to reload the project. Godot needs a reload to recognize custom icons for the custom classes.
3. Create a new scene with a root PTGame node.
4. Draw a tileset image in your drawing program of choice, and save it in your Godot project folder. (or copy one from the examples)
5. Create an LDTK project and save it in your Godot project folder. In LDTK:

- import your tileset,
- set your default grid size in project settings,
- adjust the level size,
- set your world layout to 'horizontal',
- create a layer,
- add some wall tiles,
- and add a player tile.

6. In Godot, set the "LDTK Project Resource" property on the PTGame node to your LDTK project. (Drag the project file from the Files tab onto the property field.) This will automatically parse your LDTK project and create some child nodes under the PTGame node.
7. Add PTPlayer and PTMovement nodes under the PTGame node. On the PTPlayer node, specify your player tile index and player layer. You can ignore 'Extra Collision Layers' for now.
8. Play your scene. Move your player around! Undo! Reset!
9. Next, add more nodes with scripts to the scene to further define the game's behavior. (tip: use the 'PuzzleTree Node' script template)
10. Browse the examples for some more ideas on getting started.

# Anatomy of a Turn

Turns are a core concept in PuzzleTree. Turns update the game state. You can undo Turns.

Each key press triggers a Turn. Turns are made up of some number of Frames. Each Frame will do some processing of the game state, then render the changes to the grid layers. Processing happens in 'PuzzleTree Nodes': nodes with scripts which define special update functions. This is where you write your game logic.

Frames can request an update to happen again, which queues an 'again frame'. Among other things, this allows for some animations to happen within a single Turn (or in other words: in response to a single input).

Inputs are queued, so any input received during an again frame will fire after the again frames finish.

Key repeat is also built in. Holding a key down will fire repeated turns at a specified interval, until the key is released.

A sample turn execution:

> input -> frame updates -> render -> again? -> frame updates -> render -> again? -> finished

All nodes are updated in tree order, using a DFS traversal.

The `again interval` and `key repeat interval` can be configured on the PTGame node. You can also specify if you want Turns run on key release events in addition to key press events. Key release Turns do not save to the undo stack - their changes are treated as a continuation of the previous Turn.

# The Game State

All game state that gets tracked by the undo system is stored within three places:

- tile layers,
- entities layers,
- and the `context` dictionary object.

Tiles are the primary data, while the entities and `context` are Dictionaries which can be used to hold additional state that facilitates processing/updating/transforming/evolving/playing the tile grid. The `context` starts out blank, while entities get pre-loaded with certain properties defined in the LDTK project.

There are some reserved keys on the `context` Dictionary. They are used to communicate with the PTEngine from your scripts, and for the engine to communicate with your scripts! They will always exist as entries on the `context` Dictionary.

### Engine-set Reserved Keys

`context.frame_key`: on frame updates, this value will be the reason for the update: the pressed key, the released key, or 'again'. Compare with the constants on [Inputs](#inputs) to determine the update reason in your scripts.

`context.pressed_keys`: an array of [Directions](#directions) of keys that are pressed for the current turn.

`context.is_repeat_turn`: this is `true` when the running turn is a 'repeat turn' - triggered by a held key press.

### Script-set Reserved Keys

`context.again`: you can queue another turn with no input by setting this to `true`.

`context.cancel`: set to `true` to stop processing this turn after the current node, and cancel any queued again turns. nothing gets added to the undo history.

`context.finish_frame_early`: set to `true` to stop updating any more nodes (including late updates), and finish the frame. An again frame can still happen afterwards, before the turn ends.

`context.winning`: set to `true` when the level is considered completed. (tip: Consider making your final node be a 'win-check' node that looks for the win condition as the final late update.)

`context.checkpoint`: set to `true` to set a checkpoint at the end of this turn. This makes reset load this turn's end state instead of the state from after the level load (and initial update).

`context.force_release_keys`: an array of key [Directions](#directions) to 'force release' at the end of the frame, without running a release turn. This will also prevent key repeats, since the engine will think the key is not pressed anymore.

`context.force_release_all_keys`: set to `true` to force release all keys at the end of this frame. This is just shorthand for adding `Directions.ALL_DIRS` to `context.force_release_keys`.

`context.no_save`: set to `true` to prevent saving the results of this turn in the undo stack. Useful for turns that animate certain visual feedback (when you can't move into a wall, etc.) without polluting the undo stack with superficial state changes.

`context.again_interval`: use this to dynamically change the game's `again_interval`

`context.key_repeat_interval`: use this to dynamically change the game's `key_repeat_interval`

# Using LDTK to define a level

PuzzleTree defines an import plugin to allow LDTK files to be seen in the Godot FileSystem tab. It also will detect when the project has changed, and update the relevant nodes in your Godot scene.

## World Layouts

PuzzleTree supports all LDTK world layouts: `Free`, `GridVania`, `Horizontal`, `Vertical`.

`Free` and `GridVania` worlds have all levels loaded at once, and the engine runs updates on all levels each turn, as if it were just a single level.

`Horizontal` and `Vertical` worlds have each level loaded in sequence, moving to the next when `context.winning` is set to `true`.

## Layers

Each `Tiles` or `Auto-layer` layer in LDTK will create a PTTiles in the game. `Int-grid` layers with an embedded `Auto-layer` will also create a PTTiles, but an `Int-grid` on its own will not. Maybe in the future they will, so you can access the int-grid values in your scripts. But not currently.

Tilesets in Godot are created automatically from tileset definitions in LDTK.

Each Entities layer in LDTK will create a PTEntities node in the game.

# PuzzleTreeNode Scripts

A `PuzzleTreeNode` is not anything formal, but just a name I use for a `Node` (or any of its subclasses!) with a script that defines at least one of the [Callback](#Callbacks) methods defined below.

The PuzzleTree engine will invoke these callbacks at the relevant times in the game's execution. PuzzleTreeNodes are updated in the order they are found in the scene tree (DFS traversal). Use this fact to schedule your various nodes relative to each other.

## Callbacks

Any script on any scene node (that is a descendent of PTGame) can define one of these callbacks, and it will be called at the relevant points in the game's execution. All callbacks take the game's `context` object as a parameter.

### `init_update(context)`

Called once when a level is loaded. Useful for processing level data into a new format to be used during regular frames.

### `frame_update(context)`

Called once in each Frame. If `context.again` is set during the Frame, it will be called multiple times in a single Turn.

### `reset_update(context)`

Called when you undo or reset the game state. This is useful for synchronizing non-tile visuals with the changes to the game state caused by the undo or reset.

## Late Callbacks

All callbacks have a "late" version as well, specified by a `late_` prefix (ex: `late_frame_update`, `late_init_update`). These are called after the normal version of the event has been called on all nodes in the tree. This creates a two-phase update system, where the first phase might make some changes, and the 'late' phase reacts to those changes in ways that (ideally) don't impact the other nodes in the same frame. This helps keep similar code in the same script, even if part of it depends on changes from scripts lower in the scene tree.

I think of late frame updates as happening after the "main changes" of the turn. It's a place to tidy up and finalize decorative tile placement, or check if you should trigger an again turn, before the screen is rendered with the frame's changes.

## Realtime updates

You can implement Godot's standard `_process` callback in your PuzzleTreeNodes to get realtime updates, though you won't have access to `context`. Any changes to PTTiles or PTEntities that you make during these updates will accumulate and be saved at the start of the next turn. (Hmm, in the future I may add a `realtime_update(context)` callback, with a corresponding late variation too...)

## Script Template

PuzzleTree includes a script template: the 'PuzzleTreeNode' script template. It pre-defines some of the update callbacks, to get you writing your script faster, or simply to remind you of the available callbacks. Use it when creating a script by choosing `Puzzle Tree Node` from the template dropdown in the "Create Script" dialog.

## Accessing Data

Each update callback gets the `context` object as a parameter, providing ready access to any state you are keeping in it.

You can easily access grid data by getting a reference to any of the `PTTiles` or `PTEntities` nodes that PuzzleTree created from the LDTK project file. Get a node via `get_node("%[NodeName]")`. See the documentation for [PTTiles](#pttiles) or [PTEntities](#ptentities) for more information on how to interface with the grid data. I like to store these references in an `onready` variable in scripts that interface with them frequently. (I may even set them as entries in `context` in the future to make it even easier.)

## Organization

I think of each PuzzleTreeNode as a feature/rule/behavior/aspect of my game.

For example: The player can push crates. A `push_crates` node can be dedicated to realizing this behavior, and nothing else.

If the node needs to tell another node about something, it writes some data into the context, ready for the other node to read it later.

I often have `movement` handled in a single node, too, similar to how it works in PuzzleScript where it is a distinct phase of each turn. Other nodes will tell `movement` of movements they want to make, and `movement` will resolve collisions and move the tiles that it can. The [PTMovement](#ptmovement) node is a basic implementation of this, though you might want to write your own version of it.

# Engine Nodes

## PTGame

The root node of the game! It manages the engine and has some properties that allow you to configure the behavior of your game.

### Properties

- `Ldtk Project Resource`: a reference to the LDTK Project resource to initialize the game from
- `Reload Ldtk Project`: check this property to force a reload of the LDTK project, in case you need to do that for some reason. This _should_ happen automatically as the LDTK project is modified, so mostly it is helpful when developing the engine. It unsets itself after doing the reload.
- `Starting Level`: the level index to load at game start.
- `Clear Color`: the color to fill any letter-boxed regions of the screen
- `Run Turns On Keyup`: check this to have the game run turns on key release, in addition to the usual key press turns. Release turns do not create entries in the undo history, but can modify state to be saved before the next key press turn.
- `Key Repeat Interval`: time in seconds between repeat turns run while a key is held down.
- `Again Interval`: time in seconds between successive again frames.
- `Log Level`: increase this number to get increasingly verbose logging from the engine. Logs are currently a bit limited; what gets logged at each level will evolve in future versions of PuzzleTree.

## PTLayers

A node that manages LDTK-generated layers. It's mostly there because it is nice to organize those layers into their own subtree.

## PTTiles

A tile grid which allows multiple tiles (and multiple copies of tiles) to be stacked in each cell.

LDTK allows multiple tiles per cell in a single layer, so PuzzleTree does too.

And although LDTK doesn't support rotated tiles, PTTiles do. Any tile may be rotated to face any of the 4 directions. The default is UP; each tile is drawn facing UP in the TileSet.

It is implemented as a wrapper around the Godot TileMap. It automatically creates child TileMaps as needed, having at least as many TileMaps as the tallest stack in the layer.

PTTiles will be automatically created from Tiles or Auto-layer layers in the LDTK project. You can define additional layers in your Godot scene, too, though you will have to initialize their TileSet and grid size. To simplify this process, PTTiles have a method to copy these settings from another LDTK-generated PTTiles.

I've outlined some of the most useful PTTiles functions below. See `PuzzleTree/core/PTTiles.gd` for a complete list of available functions.

### Modifying the Layer

`stack_tile_at_cell(tile :int, cell :Vector2, dir? :Direction)`

Stacks a tile at the given cell, rotated by the given direction.

If the cell is empty, it places it in the top-level tilemap node. If a tile already exists at the cell, the tile will be placed in the lowest empty child tilemap. If none are empty (or there are no child tilemaps yet!), it will create one.

`remove_tile_at_cell(tile :int, cell :Vector2, dir? :Direction)`

Removes the lowest copy of the tile from the stack at the given cell. If dir is provided, then the lowest copy of the tile that matches the given direction will be removed.

`replace_tile_at_cell(replace :int, with :int, cell :Vector2, replace_dir? :Direction, with_dir? :Direction)`

Replaces the lowest (rotated) tile with the given (rotated) tile. This actually removes 'replace' and adds 'with' onto the cell's tile stack.

`clear_cell(cell :Vector2)`

Empties the tile stack at the given cell.

### Examining the Layer

`get_tiles_at_cell(cell :Vector2) -> int[]`

Returns an array of tile id's corresponding to the tiles in the cell's tile stack.

`get_tile_dir_at_cell(tile :int, cell :Vector2) -> Direction`

Gets the direction of the lowest instance of the tile in the cell's tile stack.

`is_empty_at_cell(cell :Vector2) -> boolean`

Returns `true` if the cell's tile stack is empty.

`has_tile_at_cell(tile :int, cell :Vector2) -> boolean`

Returns `true` if the tile is in the cell's tile stack.

`get_cells_with_tile(tile :int) -> Vector2[]`

Returns an array of all cells that have at least one instance of the given tile in their tile stack.

`get_used_cells() -> Vector2[]`

This one is actually just Godot's TileMap function! But it works for the Layer since any cell that has a tile in it will have some tile in the layer's root TileMap, and the PTTiles node _is_ the layer's root TileMap node.

### Layer Management

`copy_tilemap_settings_from(tiles: PTTiles)`

Use this to copy tileset and grid size information from LDTK-generated PTTiles into additional PTTiles that you define in your Godot scene.

## PTEntities

A layer corresponding to one of the Entities defined in the LDTK project. It maintains an array of Dictionaries, one for each Entity instance in the level/world. Entities are grid-aligned, but can be more than 1 cell wide and/or high.

`entities :Dictionary[]`

After level load, each entity's dictionary has:

- `cell :Vector2` (pivot cell)
- `width :int` (in cells)
- `height :int` (in cells)
- and any defined fields, keyed on their identifier, of the following types (single or array):
  - `:boolean`
  - `:int`
  - `:float`
  - `:string`
  - `:Vector2` (cell coordinate)

with values as defined on the entities in each level. I will implement other value types as needed.

You can add other state to the entity's dictionary in your scripts, and it will all be saved to the undo stack before each turn (alongside the context and all the other Layers' data).

Note: unlike PTTiles, PTEntities layers don't render anything. They can be useful to establish relationships between different tiles/cells, or to define regions in a level. For example, the Crate Cables example uses them to link gates with the various targets that need to be active for the gate to open.

# Utility Nodes

These helpful, predefined script classes are saved in `PuzzleTree/utils/`. You can create any of them by selecting one in the Create New Node dialog.

## PTCamera

A custom Camera2d node scripted to operate with various behaviors. It operates as any other PuzzleTreeNode, storing target pos/zoom on late update (or undo/reset) and moving towards target on each \_process update.

PuzzleTree will automatically create a PTCamera node the first time an LDTK project is loaded.

### Properties

- `Tile Size`: used to correctly position the camera within the game grid. It should match the size of tiles in your tileset
- `Mode`:
  - `auto`: fit the current level into the window
  - `scripted`: camera follows the position defined at `context.camera_pos` (cell position). other properties below further modify this behavior.
- `Target Size`: the 'zoom level' of the camera.
- `Eased Follow`: whether the camera should elastically follow the `camera_pos`, or snap there immediately
- `Camera Speed`: how quickly the camera should elastically follow the `camera pos`
- `Snap Size`: snap the camera to a sparse grid of positions, with the distance (in tiles) between positions defined by the Snap Size. This can be used to get a camera that 'flicks' between level screens that are laid out in a regular grid (using the GridVania LDTK project format, for example).

## PTPlayer

This node applies inputs as queued movements to instances of the specified tile in the specified layer.

### Properties

- `Player Layer`: the name of the PTTiles that has your player tile
- `Player Tile`: the index of a tile in the tileset associated with the Player Layer.
- `Extra Collision Layers`: a list of layer names separated by commas, which should be included in collision checks in addition to Player Layer.

## PTMovement

A script node that can track queued movements of tiles in the grid (tilemap and cell pair). During its frame_update, it will try to apply as many movements as it can, without creating overlapping tiles in the move's specified collision layers.

Currently it very basic and un-optimized, but it gets the job done and is a quick way to get a little guy moving around in your grid.

# Helper Scripts

PuzzleTree also has some helper scripts that are not nodes or script classes. They simply define some enums and helper methods which are useful when writing your scripts. PuzzleTree will configure the project to autoload these scripts as singletons, so they are ready to use in your game scripts.

## Directions

Definition of grid directions, and some helpers for working with these directions, such as:

- `Directions.UP`
- `shift_cell(cell :Vector2, dir :Direction) -> Vector2`
- `opposite(dir :Direction) -> Direction`
- `rotate_cw(dir :Direction) -> Direction`
- etc.

## Inputs

Definition of the keys set at `context.frame_key`, and some helper methods for interpreting these keys, such as:

- `Inputs.PRESS_LEFT`
- `Inputs.AGAIN`
- `is_pressed_key(key) -> boolean`
- `get_key_dir(key) -> Direction`

# Beyond the Grid

Remember, this is still Godot. Nothing is stopping you from adding more non-grid nodes or game state - you can even update these outside of the frame steps by implementing Godot's usual `_process` callback. Just be careful to play nice with PuzzleTree Frames getting run, or getting cancelled, or the game state getting reset. You can react to these changes by handling the necessary update callbacks.

Some ideas to consider:

- one-shot animations are easy to overlay on the grid with minimal concern for the game's state changes, and they don't have to fit within the grid
- a custom player sprite with different looping idle animations for different player states
- particle effects
- shader effects
