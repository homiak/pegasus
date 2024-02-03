local modpath = minetest.get_modpath("stone")
-- local sound_api = dofile(modpath .. "/sound_api_core/init.lua")

-- Item
minetest.register_craftitem("stone:granite_black", {
	description = "Black granite stone",
	inventory_image = "black_granite_stone.png",
})

-- Nodes
minetest.register_node("stone:grey_granite", {
	description = "Grey granite stone",
	tiles = { "grey_granite_stone.png" },
	-- sounds = sound_api.node_sound_stone_defaults(),
	groups = { cracky = 2, dig_stone = 1 },
})

minetest.register_node("stone:red_granite", {
	description = "Red granite stone",
	tiles = { "red_granite_stone.png" },
	-- sounds = sound_api.node_sound_stone_defaults(),
	groups = { cracky = 1, dig_stone = 1 },
})

-- minetest.register_node("stone:plate_rusted", {
-- 	description = "Rusted stone plate",
-- 	tiles = { "stone_plate_rusted.png" },
-- 	sounds = sound_api.node_sound_stone_defaults(),
-- 	groups = { cracky = 1, choppy = 1, dig_stone = 1 },
-- })

-- minetest.register_node("stone:grate_soft", {
-- 	description = "Soft stone Grate",
-- 	drawtype = "fencelike",
-- 	tiles = { "stone_grate_soft.png" },
-- 	inventory_image = "stone_grate_soft_inventory.png",
-- 	wield_image = "stone_grate_soft_inventory.png",
-- 	paramtype = "light",
-- 	selection_box = {
-- 		type = "fixed",
-- 		fixed = { -1 / 7, -1 / 2, -1 / 7, 1 / 7, 1 / 2, 1 / 7 },
-- 	},
-- 	sounds = sound_api.node_sound_wood_defaults(),
-- 	groups = { cracky = 2, choppy = 2, dig_stone = 1 },
-- })

-- minetest.register_node("stone:grate_hard", {
-- 	description = "Hardened stone Grate",
-- 	drawtype = "fencelike",
-- 	tiles = { "stone_grate_hard.png" },
-- 	inventory_image = "stone_grate_hard_inventory.png",
-- 	wield_image = "stone_grate_hard_inventory.png",
-- 	paramtype = "light",
-- 	selection_box = {
-- 		type = "fixed",
-- 		fixed = { -1 / 7, -1 / 2, -1 / 7, 1 / 7, 1 / 2, 1 / 7 },
-- 	},
-- 	sounds = sound_api.node_sound_wood_defaults(),
-- 	groups = { cracky = 1, choppy = 1, dig_stone = 1 },
-- })

-- minetest.register_node("stone:roofing", {
-- 	description = "Corrugated stone roofing",
-- 	drawtype = "raillike",
-- 	tiles = { "stone_corrugated_stone.png" },
-- 	inventory_image = "stone_corrugated_stone.png",
-- 	wield_image = "stone_corrugated_stone.png",
-- 	paramtype = "light",
-- 	walkable = true,
-- 	selection_box = {
-- 		type = "fixed",
-- 		fixed = { -1 / 2, -1 / 2, -1 / 2, 1 / 2, -1 / 2 + 1 / 16, 1 / 2 },
-- 	},
-- 	groups = { bendy = 2, snappy = 1, dig_immediate = 2, dig_generic = 1 },
-- })


-- minetest.register_node("stone:strut_mount", {
-- 	description = "Strut with mount",
-- 	drawtype = "mesh",
-- 	mesh = "stone_cube.obj",
-- 	tiles = {
-- 		base_tex,
-- 		base_tex,
-- 		base_tex .. "^stone_strut_overlay.png",
-- 		base_tex .. "^stone_strut_overlay.png",
-- 		base_tex .. "^stone_strut_overlay.png",
-- 		base_tex .. "^stone_strut_overlay.png",
-- 	},
-- 	use_texture_alpha = "clip",
-- 	paramtype = "light",
-- 	paramtype2 = "wallmounted",
-- 	sounds = sound_api.node_sound_stone_defaults(),
-- 	groups = { choppy = 1, cracky = 1, dig_stone = 1 },
-- })
