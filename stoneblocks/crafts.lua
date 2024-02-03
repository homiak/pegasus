-- local stoneblocks_item = "default:stoneblocks_block"

-- minetest.register_craft({
-- 	type = "cooking",
-- 	output = "stoneblocks:black_granite",
-- 	recipe = "stoneblocks:bazalt",
-- })
-- minetest.register_craft({
-- 	output = "stoneblocks:pink_granite",
-- 	recipe = {{"stoneblocks:red_granite"}}
-- })


-- minetest.register_craft({
-- 	type = "cooking",
-- 	output = "stoneblocks:grate_hard",
-- 	recipe = "stoneblocks:grate_soft",
-- })

-- if minetest.get_modpath("default") then
-- 	minetest.register_craft({
-- 		output = "stoneblocks:plate_soft 2",
-- 		recipe = {
-- 			{stoneblocks_item, stoneblocks_item},
-- 			{stoneblocks_item, stoneblocks_item},
-- 		}
-- 	})

-- 	minetest.register_craft({
-- 		output = "stoneblocks:grate_soft 3",
-- 		recipe = {
-- 			{stoneblocks_item, "", stoneblocks_item},
-- 			{stoneblocks_item, "", stoneblocks_item},
-- 		}
-- 	})

-- 	minetest.register_craft({
-- 		output = "stoneblocks:roofing 6",
-- 		recipe = {{stoneblocks_item, stoneblocks_item, stoneblocks_item}}
-- 	})

-- 	minetest.register_craft({
-- 		output = "stoneblocks:strut_mount",
-- 		recipe = {{"stoneblocks:strut", stoneblocks_item}}
-- 	})

-- 	minetest.register_craft({
-- 		output = "stoneblocks:strut_mount",
-- 		recipe = {{"streets:stoneblocks_support", stoneblocks_item}}
-- 	})

-- 	minetest.register_craft({
-- 		output = "default:iron_lump",
-- 		recipe = {{"stoneblocks:scrap", "stoneblocks:scrap"}}
-- 	})
-- end

-- if not minetest.get_modpath("streets") or not minetest.get_modpath("stoneblockssupport") then
-- 	minetest.register_craft({
-- 		output = "stoneblocks:strut 5",
-- 		recipe = {
-- 			{"", stoneblocks_item, ""},
-- 			{stoneblocks_item, stoneblocks_item, stoneblocks_item},
-- 			{"", stoneblocks_item, ""},
-- 		}
-- 	})
-- end