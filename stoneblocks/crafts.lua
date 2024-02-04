
minetest.register_craft({
	type = "shaped",
	output = "stoneblocks:sapphire_block",
	recipe = {
        {"stoneblocks:stone_with_sapphire","stoneblocks:stone_with_sapphire", "stoneblocks:stone_with_sapphire"}
}
})

minetest.register_craft({
	type = "shaped",
	output = "stoneblocks:emeraldblock",
	recipe = {
        {"stoneblocks:stone_with_emerald","stoneblocks:stone_with_emerald", "stoneblocks:stone_with_emerald"}
}
})

minetest.register_craft({
	type = "shapeless",
	output = "stoneblocks:rubyblock",
	recipe = { "stoneblocks:stone_with_ruby","stoneblocks:stone_with_ruby", "stoneblocks:stone_with_ruby" }
})

minetest.register_craft({
	type = "shaped",
	output = "stoneblocks:turquoise_block",
	recipe = {
        {"stoneblocks:stone_with_turquoise","stoneblocks:stone_with_turquoise", "stoneblocks:stone_with_turquoise"}
}
})

minetest.register_craft({
	type = "shaped",
	output = "stoneblocks:turquoise_glass_block",
	recipe = {
        {"stoneblocks:stone_with_turquoise_glass","stoneblocks:stone_with_turquoise_glass", "stoneblocks:stone_with_turquoise_glass"}
}
})

minetest.register_craft({
	type = "shaped",
	output = "stoneblocks:rubyblock_with_emerald",
	recipe = {
        {"stoneblocks:stone_with_ruby","stoneblocks:stone_with_ruby", "stoneblocks:stone_with_emerald"}
}
})

minetest.register_craft({
	type = "shaped",
	output = "stoneblocks:cats_eye",
	recipe = {
        {"stoneblocks:black_granite_block","stoneblocks:rubyblock", "stoneblocks:sapphire_block"}
}
})

minetest.register_craft({
	type = "shaped",
	output = "stoneblocks:emeraldblock_with_ruby",
	recipe = {
        {"stoneblocks:stone_with_emerald","stoneblocks:stone_with_emerald", "stoneblocks:stone_with_ruby"}
}
})

minetest.register_craft({
	type = "shaped",
	output = "stoneblocks:red_granite_turquoise_block",
	recipe = {
        {"stoneblocks:turquoise_glass_block","stoneblocks:red_granite_block", "stoneblocks:red_granite_block"}
}
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