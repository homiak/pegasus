# StoneBlocks Mod for minetest based games (most functionality works in multicraft as well)

## Overview
StoneBlocks adds a variety of stone-based blocks with unique properties, including light-emitting stones and decorative blocks. Some block reacts to player proximity, creating a dynamic and immersive environment.

## Installation
- Standard installation via contentDB 

### Manual install for single player games
1. Download the StoneBlocks mod.
2. Unzip and place the `stoneblocks` folder into your Minetest `mods` directory or Multicraft <game_name>/worldmods
3. Enable the mod through the Minetest UI or add `load_mod_stoneblocks = true` to your `minetest.conf` file.

## Features
- Light-emitting blocks that activate when players are nearby.
- A range of decorative stone blocks for building and crafting.
- Customizable settings for block light emission and sound effects.

## Usage
- Place the blocks within the game world like any standard block.
- Configure the mod settings in `minetest.conf` to adjust the proximity detection range and light duration.

## Configuration
- `stoneblocks_check_player_within`: Range (in blocks) to detect player proximity. Default is 2. Valid values 1 - 20. 
- `stoneblocks_stay_lit_for`: Duration (in seconds) the blocks remain lit after activation. Default is 2. Valid range 1 - 600.

Created by Scottii & homiak
