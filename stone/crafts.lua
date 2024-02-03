-- local stone_item = "default:stone_block"

-- minetest.register_craft({
-- 	type = "cooking",
-- 	output = "stone:black_granite",
-- 	recipe = "stone:bazalt",
-- })
-- minetest.register_craft({
-- 	output = "stone:pink_granite",
-- 	recipe = {{"stone:red_granite"}}
-- })


-- minetest.register_craft({
-- 	type = "cooking",
-- 	output = "stone:grate_hard",
-- 	recipe = "stone:grate_soft",
-- })

-- if minetest.get_modpath("default") then
-- 	minetest.register_craft({
-- 		output = "stone:plate_soft 2",
-- 		recipe = {
-- 			{stone_item, stone_item},
-- 			{stone_item, stone_item},
-- 		}
-- 	})

-- 	minetest.register_craft({
-- 		output = "stone:grate_soft 3",
-- 		recipe = {
-- 			{stone_item, "", stone_item},
-- 			{stone_item, "", stone_item},
-- 		}
-- 	})

-- 	minetest.register_craft({
-- 		output = "stone:roofing 6",
-- 		recipe = {{stone_item, stone_item, stone_item}}
-- 	})

-- 	minetest.register_craft({
-- 		output = "stone:strut_mount",
-- 		recipe = {{"stone:strut", stone_item}}
-- 	})

-- 	minetest.register_craft({
-- 		output = "stone:strut_mount",
-- 		recipe = {{"streets:stone_support", stone_item}}
-- 	})

-- 	minetest.register_craft({
-- 		output = "default:iron_lump",
-- 		recipe = {{"stone:scrap", "stone:scrap"}}
-- 	})
-- end

-- if not minetest.get_modpath("streets") or not minetest.get_modpath("stonesupport") then
-- 	minetest.register_craft({
-- 		output = "stone:strut 5",
-- 		recipe = {
-- 			{"", stone_item, ""},
-- 			{stone_item, stone_item, stone_item},
-- 			{"", stone_item, ""},
-- 		}
-- 	})
-- end