
minetest.register_craft({
	type = "shaped",
	output = "stoneblocks:sapphire_block",
	recipe = {
        {"stoneblocks:stone_with_sapphire","stoneblocks:stone_with_sapphire", "stoneblocks:stone_with_sapphire"}
}
})

minetest.register_craft({
	type = "shapeless",
	output = "stoneblocks:rubyblock",
	recipe = {"stoneblocks:stone_with_ruby","stoneblocks:stone_with_ruby", "stoneblocks:stone_with_ruby"}
})


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