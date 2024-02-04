#!/usr/bin/env bash

cp -r ~/dev/minetest-mods/playmod ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/mods
mkdir -p ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/worlds/multicraftw/worldmods
cp -r ~/dev/minetest-mods/stoneblocks ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/worlds/multicraftw/worldmods/
/Applications/MultiCraft.app/Contents/MacOS/MultiCraft --info