local modpath = minetest.get_modpath("stoneblocks")
local sound_api = dofile(modpath .. "/sound_api/init.lua")

minetest.register_node("stoneblocks:black_granite_block", {
	description = "Black granite stone",
	tiles = { "stoneblocks_black_granite_block.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 2, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:grey_granite", {
	description = "Grey granite stone",
	tiles = { "stoneblocks_stone_grey_granite.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 2, dig_stoneblocks = 1, },
})

minetest.register_node("stoneblocks:rubyblock_with_emerald", {
	description = "Rubyblock with emerald",
	tiles = { "stoneblocks_rubyblock_with_emerald.png" },
	sunlight_propagates = true,
	light_source = 15, -- This node emits light
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 3, dig_stoneblocks = 1, },
})

minetest.register_node("stoneblocks:rubyblock", {
	description = "Rubyblock",
	tiles = { "stoneblocks_rubyblock.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 1, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:cats_eye", {
	description = "Cats eye",
	tiles = { "stoneblocks_cats_eye.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 2, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:stone_with_ruby", {
	description = "Stone with ruby",
	tiles = { "stoneblocks_stone_with_ruby.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 3, dig_stoneblocks = 1, },
})

minetest.register_node("stoneblocks:stone_with_emerald", {
	description = "Stone with emerald",
	tiles = { "stoneblocks_stone_with_emerald.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 3, dig_stoneblocks = 1, },
})

minetest.register_node("stoneblocks:emeraldblock_with_ruby", {
	description = "Emeraldblock with ruby",
	tiles = { "stoneblocks_emeraldblock_with_ruby.png" },
	sunlight_propagates = true,
	light_source = 15,
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 2, dig_stoneblocks = 1, },
})

minetest.register_node("stoneblocks:granite_block", {
	description = "Granite stone",
	tiles = { "stoneblocks_granite_block.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 1, dig_stoneblocks = 1, },
})

minetest.register_node("stoneblocks:red_granite_block", {
	description = "Red granite stone",
	tiles = { "stoneblocks_red_granite_block.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 2, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:rose_granite_block", {
	description = "Rose granite stone",
	tiles = { "stoneblocks_rose_granite_block.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 2, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:stone_with_turquoise_glass", {
	description = "Stone with turquoise glass",
	tiles = { "stoneblocks_stone_with_turquoise_glass.png" },
	sunlight_propagates = true,
	light_source = 10, -- This node emits light
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 1, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:emeraldblock", {
	description = "Emerald block",
	tiles = { "stoneblocks_emeraldblock.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 1, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:mixed_stone_block", {
	description = "Mixed stone block",
	tiles = { "stoneblocks_mixed_stone_block.png" },
	sunlight_propagates = true,
	light_source = 15, -- This node emits light
	sounds = sound_api.node_sound_stone_defaults(),
	glasslike = 1, -- glasslike_framed
	groups = { stone = 1, cracky = 1, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:stone_with_turquoise", {
	description = "Stone with turquoise",
	tiles = { "stoneblocks_stone_with_turquoise.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 3, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:sapphire_block", {
	description = "Sapphire stone",
	tiles = { "stoneblocks_sapphire_block.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 1, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:stone_with_sapphire", {
	description = "Stone with sapphire",
	tiles = { "stoneblocks_stone_with_sapphire.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 3, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:turquoise_block", {
	description = "Turquoise stone",
	tiles = { "stoneblocks_turquoise_block.png" },
	drawtype = "glasslike",
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 2, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:red_granite_turquoise_block", {
	description = "Red turquoise stone",
	tiles = { "stoneblocks_red_granite_turquoise_block.png" },
	sunlight_propagates = true,
	light_source = 15, -- This node emits light
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { stone = 1, cracky = 2, dig_stoneblocks = 0 },
})

minetest.register_node("stoneblocks:turquoise_glass", {
	description = "Turquoise glass stone",
	tiles = { "stoneblocks_turquoise_glass_block.png" },
	sunlight_propagates = true,
	light_source = 15, -- This node emits light
	sounds = sound_api.node_sound_stone_defaults(),
	glasslike = 1, -- glasslike_framed
	groups = { stone = 1, cracky = 2, dig_stoneblocks = 0 },
})
