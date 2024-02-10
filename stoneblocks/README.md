# StoneBlocks Mod for minetest based games (most functionality works in multicraft as well)

## Overview
StoneBlocks adds a variety of stone-based blocks with unique properties, including light-emitting stones and decorative blocks. Some block reacts to player proximity, creating a dynamic and immersive environment.

## List of blocks
### Blocks That Emit Light (Lit Blocks)

- Ruby Block with Emerald: stoneblocks:rubyblock_with_emerald
- Stone with Turquoise Glass: stoneblocks:stone_with_turquoise_glass
- Emeraldblock with Ruby: stoneblocks:emeraldblock_with_ruby
- Mixed Stone Block: stoneblocks:mixed_stone_block
- Red Granite Turquoise Block: stoneblocks:red_granite_turquoise_block
- Turquoise Glass Stone: stoneblocks:turquoise_glass

### Sensitive Lanterns (lit when player is close)

- Sensitive Glass Block: stoneblocks:sensitive_glass_block
- Yellow Stone Lantern: stoneblocks:lantern_yellow
- Blue Stone Lantern: stoneblocks:lantern_blue
- Green Stone Lantern: stoneblocks:lantern_green
- Red and Green with Yellow Stone Lantern: stoneblocks:lantern_red_green_yellow
- Red Stone Lantern: stoneblocks:lantern_red

### Blocks Without Light
- Black Granite Stone: stoneblocks:black_granite_block
- Grey Granite Stone: stoneblocks:grey_granite
- Ruby Block: stoneblocks:rubyblock
- Cat's Eye: stoneblocks:cats_eye
- Stone with Ruby: stoneblocks:stone_with_ruby
- Stone with Emerald: stoneblocks:stone_with_emerald
- Granite Stone: stoneblocks:granite_block
- Red Granite Stone: stoneblocks:red_granite_block
- Rose Granite Stone: stoneblocks:rose_granite_block
- Emerald Block: stoneblocks:emeraldblock
- Stone with Turquoise: stoneblocks:stone_with_turquoise
- Sapphire Stone: stoneblocks:sapphire_block
- Stone with Sapphire: stoneblocks:stone_with_sapphire
- Turquoise Stone: stoneblocks:turquoise_block


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
