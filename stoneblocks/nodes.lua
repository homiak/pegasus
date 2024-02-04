local modpath = minetest.get_modpath("stoneblocks")
local sound_api = dofile(modpath .. "/sound_api_core/init.lua")

minetest.register_node("stoneblocks:black_granite", {
	description = "Black granite stone",
	tiles = { "black_granite_block.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { cracky = 2, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:grey_granite", {
	description = "Grey granite stone",
	tiles = { "stone_grey_granite.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = {  cracky = 2, dig_stoneblocks = 1, },
})

minetest.register_node("stoneblocks:granite_block", {
	description = "Granite stone",
	tiles = { "granite_block.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = {  cracky = 1, dig_stoneblocks = 1, },
})

minetest.register_node("stoneblocks:red_granite", {
	description = "Red granite stone",
	tiles = { "red_granite_block.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { cracky = 2, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:rose_granite", {
	description = "Rose granite stone",
	tiles = { "rose_granite_block.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { cracky = 2, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:stone_with_turquoise_glass", {
	description = "Stone with turquoise glass",
	tiles = { "stone_with_turquoise_glass.png" },
	sunlight_propagates = true,
	light_source = 10, -- This node emits light
	-- sounds = sound_api.node_sound_stoneblocks_defaults(),
	groups = { cracky = 1, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:emeraldblock", {
	description = "Emeraldblock",
	tiles = { "emeraldblock.png" },
	-- sounds = sound_api.node_sound_stoneblocks_defaults(),
	groups = { cracky = 1, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:stone_with_turquoise", {
	description = "Stone with turquoise",
	tiles = { "stone_with_turquoise.png" },
	-- sounds = sound_api.node_sound_stoneblocks_defaults(),
	groups = { cracky = 1, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:sapphire_block", {
	description = "Sapphire stone",
	tiles = { "sapphire_block.png" },
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { cracky = 2, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:stone_with_sapphire", {
	description = "Stone with sapphire",
	tiles = { "stone_with_sapphire.png" },
	-- sounds = sound_api.node_sound_stoneblocks_defaults(),
	groups = { cracky = 1, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:turquoise_block", {
	description = "Turquoise stone",
	tiles = { "turquoise_block.png" },
drawtype = "glasslike",
	sounds = sound_api.node_sound_stone_defaults(),
	groups = { cracky = 2, dig_stoneblocks = 1 },
})

minetest.register_node("stoneblocks:red_granite_turquoise_block", {
	description = "Red turquoise stone",
	tiles = { "red_granite_turquoise_block.png" },
	sunlight_propagates = true,
	light_source = 15, -- This node emits light
	-- sounds = sound_api.node_sound_stoneblocks_defaults(),
	groups = { cracky = 1, dig_stoneblocks = 0 },
})

minetest.register_node("stoneblocks:turquoise_glass", {
	description = "Turquoise glass stone",
	tiles = { "turquoise_glass_block.png" },
	sunlight_propagates = true,
	light_source = 50, -- This node emits light
	-- sounds = sound_api.node_sound_stoneblocks_defaults(),
	groups = { cracky = 2, dig_stoneblocks = 0 },
})

-- minetest.register_node("stoneblocks:plate_rusted", {
-- 	description = "Rusted stoneblocks plate",
-- 	tiles = { "stoneblocks_plate_rusted.png" },
-- 	sounds = sound_api.node_sound_stoneblocks_defaults(),
-- 	groups = { cracky = 1, choppy = 1, dig_stoneblocks = 1 },
-- })

-- minetest.register_node("stoneblocks:grate_soft", {
-- 	description = "Soft stoneblocks Grate",
-- 	drawtype = "fencelike",
-- 	tiles = { "stoneblocks_grate_soft.png" },
-- 	inventory_image = "stoneblocks_grate_soft_inventory.png",
-- 	wield_image = "stoneblocks_grate_soft_inventory.png",
-- 	paramtype = "light",
-- 	selection_box = {
-- 		type = "fixed",
-- 		fixed = { -1 / 7, -1 / 2, -1 / 7, 1 / 7, 1 / 2, 1 / 7 },
-- 	},
-- 	sounds = sound_api.node_sound_wood_defaults(),
-- 	groups = { cracky = 2, choppy = 2, dig_stoneblocks = 1 },
-- })

-- minetest.register_node("stoneblocks:grate_hard", {
-- 	description = "Hardened stoneblocks Grate",
-- 	drawtype = "fencelike",
-- 	tiles = { "stoneblocks_grate_hard.png" },
-- 	inventory_image = "stoneblocks_grate_hard_inventory.png",
-- 	wield_image = "stoneblocks_grate_hard_inventory.png",
-- 	paramtype = "light",
-- 	selection_box = {
-- 		type = "fixed",
-- 		fixed = { -1 / 7, -1 / 2, -1 / 7, 1 / 7, 1 / 2, 1 / 7 },
-- 	},
-- 	sounds = sound_api.node_sound_wood_defaults(),
-- 	groups = { cracky = 1, choppy = 1, dig_stoneblocks = 1 },
-- })

-- minetest.register_node("stoneblocks:roofing", {
-- 	description = "Corrugated stoneblocks roofing",
-- 	drawtype = "raillike",
-- 	tiles = { "stoneblocks_corrugated_stoneblocks.png" },
-- 	inventory_image = "stoneblocks_corrugated_stoneblocks.png",
-- 	wield_image = "stoneblocks_corrugated_stoneblocks.png",
-- 	paramtype = "light",
-- 	walkable = true,
-- 	selection_box = {
-- 		type = "fixed",
-- 		fixed = { -1 / 2, -1 / 2, -1 / 2, 1 / 2, -1 / 2 + 1 / 16, 1 / 2 },
-- 	},
-- 	groups = { bendy = 2, snappy = 1, dig_immediate = 2, dig_generic = 1 },
-- })


-- minetest.register_node("stoneblocks:strut_mount", {
-- 	description = "Strut with mount",
-- 	drawtype = "mesh",
-- 	mesh = "stoneblocks_cube.obj",
-- 	tiles = {
-- 		base_tex,
-- 		base_tex,
-- 		base_tex .. "^stoneblocks_strut_overlay.png",
-- 		base_tex .. "^stoneblocks_strut_overlay.png",
-- 		base_tex .. "^stoneblocks_strut_overlay.png",
-- 		base_tex .. "^stoneblocks_strut_overlay.png",
-- 	},
-- 	use_texture_alpha = "clip",
-- 	paramtype = "light",
-- 	paramtype2 = "wallmounted",
-- 	sounds = sound_api.node_sound_stoneblocks_defaults(),
-- 	groups = { choppy = 1, cracky = 1, dig_stoneblocks = 1 },
-- })
