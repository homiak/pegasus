#!/usr/bin/env bash

sudo cp -r ~/dev/minetest-mods/stoneblocks ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/mods
sudo mkdir -p ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/worlds/multicraftw/worldmods
sudo cp -r ~/dev/minetest-mods/stoneblocks ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/worlds/multicraftw/worldmods/
sudo cp -r ~/dev/minetest-mods/stoneblocks ~/Library/Containers/mobi.MultiCraft/Data/.cache/multicraft/games/kawaii/mods/

sudo cp -r ~/dev/minetest-mods/colorflames ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/mods
sudo mkdir -p ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/worlds/multicraftw/worldmods
sudo cp -r ~/dev/minetest-mods/colorflames ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/worlds/multicraftw/worldmods/
sudo mkdir -p ~/dev/minetest-mods/waterdragon ~/Library/Application\ Support/minetest/mods/
sudo cp -r ~/dev/minetest-mods/colorflames ~/Library/Containers/mobi.MultiCraft/Data/.cache/multicraft/games/kawaii/mods/
sudo cp -r ~/dev/minetest-mods/waterdragon ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/worlds/multicraftw/worldmods/
sudo cp -r ~/dev/minetest-mods/waterdragon ~/Library/Application\ Support/minetest/mods/
sudo cp -r ~/dev/minetest-mods/waterdragon ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/mods
sudo cp -r ~/dev/stoneblocks ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/mods
sudo cp -r ~/dev/colorflames ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/mods
/Applications/MultiCraft.app/Contents/MacOS/MultiCraft --info