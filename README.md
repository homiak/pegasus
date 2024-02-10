## Minetest - copy mods to mods directory 

```cp -r ~/dev/minetest-mods/playmod ~/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/mods```


## Multicraft - copy mods to mods directory inside the world 

```cp -r ~/dev/minetest-mods/stoneblocks /Users/peter/Library/Containers/mobi.MultiCraft/Data/Library/Application\ Support/multicraft/worlds/multicraftw/worldmods/```

where `multicraftw` is the name of the world

### Run multicraft 

```/Applications/MultiCraft.app/Contents/MacOS/MultiCraft --info```


### Convert m4a to ogg 
ffmpeg -i hit_glass.m4a -c:a libvorbis stoneblocks_hit_glass.ogg

