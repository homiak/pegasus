local modpath = minetest.get_modpath("stoneblocks")

dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/dynamic.lua")
dofile(modpath .. "/ore.lua")

if minetest.get_modpath("default") then
    dofile(modpath .. "/crafts.lua")
end
