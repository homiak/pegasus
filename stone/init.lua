local modpath = minetest.get_modpath("stone")

dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/crafts.lua")

-- minetest.register_abm({
-- 	label = "Some stone blocks near water are weathered",
-- 	nodenames = {"stone:gipsum"},
-- 	neighbors = {"group:water"},
-- 	interval = 30,
-- 	chance = 20,
-- 	action = function(pos)
-- 		if minetest.find_node_near(pos, 2, "water") then
-- 			minetest.set_node(pos, {name="stone:gipsum_weathered"})
-- 		end
-- 	end,
-- })
