local modpath = minetest.get_modpath("stoneblocks")


dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/dynamic.lua")
dofile(modpath .. "/crafts.lua")

-- minetest.register_abm({
-- 	label = "Some stoneblocks blocks near water are weathered",
-- 	nodenames = {"stoneblocks:gipsum"},
-- 	neighbors = {"group:water"},
-- 	interval = 30,
-- 	chance = 20,
-- 	action = function(pos)
-- 		if minetest.find_node_near(pos, 2, "water") then
-- 			minetest.set_node(pos, {name="stoneblocks:gipsum_weathered"})
-- 		end
-- 	end,
-- })
