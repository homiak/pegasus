----------------
-- Craftitems --
----------------

local random = math.random

local vec_add, vec_sub = vector.add, vector.subtract

local color = minetest.colorize

local function correct_name(str)
	if str then
		if str:match(":") then str = str:split(":")[2] end
		return (string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("_", " "))
	end
end

local function register_egg(name, def)

	minetest.register_entity(def.mob .. "_egg_entity", {
		hp_max = 1,
		physical = true,
		collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
		visual = "sprite",
		visual_size = {x = 0.5, y = 0.5},
		textures = {def.inventory_image .. ".png"},
		initial_sprite_basepos = {x = 0, y = 0},
		is_visible = true,
		on_step = function(self, _, moveresult)
			local pos = self.object:get_pos()
			if not pos then return end
			if moveresult.collides then
				for _, collision in ipairs(moveresult.collisions) do
					if collision.type == "nodes" then
						minetest.add_particlespawner({
							amount = 6,
							time = 0.1,
							minpos = {x = pos.x - 7/16, y = pos.y - 5/16, z = pos.z - 7/16},
							maxpos = {x = pos.x + 7/16, y = pos.y - 5/16, z = pos.z + 7/16},
							minvel = {x = -1, y = 2, z = -1},
							maxvel = {x = 1, y = 5, z = 1},
							minacc = {x = 0, y = -9.8, z = 0},
							maxacc = {x = 0, y = -9.8, z = 0},
							collisiondetection = true,
							collision_removal = true,
							texture = "pegasus_egg_fragment.png"
						})
						break
					elseif collision.type == "object" then
						collision.object:punch(self.object, 2.0, {full_punch_interval = 0.1, damage_groups = {fleshy = 1}}, nil)
						break
					end
				end
				if random(3) < 2 then
					local object = minetest.add_entity(pos, def.mob)
					local ent = object and object:get_luaentity()
					if not ent then return end
					ent.growth_scale = 0.7
					pegasus.initialize_api(ent)
					pegasus.protect_from_despawn(ent)
				end
				self.object:remove()
			end
		end
	})

	minetest.register_craftitem(name, {
		description = def.description,
		inventory_image = def.inventory_image .. ".png",
		on_use = function(itemstack, player)
			local pos = player:get_pos()
			minetest.sound_play("default_place_node_hard", {
				pos = pos,
				gain = 1.0,
				max_hear_distance = 5,
			})
			local vel = 19
			local gravity = 9
			local object = minetest.add_entity({
				x = pos.x,
				y = pos.y + 1.5,
				z = pos.z
			}, def.mob .. "_egg_entity")
			local dir = player:get_look_dir()
			object:set_velocity({
				x = dir.x * vel,
				y = dir.y * vel,
				z = dir.z * vel
			})
			object:set_acceleration({
				x = dir.x * -3,
				y = -gravity,
				z = dir.z * -3
			})
			itemstack:take_item()
			return itemstack
		end,
		groups = {food_egg = 1, flammable = 2},
	})

	minetest.register_craftitem(name .. "_fried", {
		description = "Fried " .. def.description,
		inventory_image = def.inventory_image .. "_fried.png",
		on_use = minetest.item_eat(4),
		groups = {food_egg = 1, flammable = 2},
	})

	minetest.register_craft({
		type  =  "cooking",
		recipe  = name,
		output = name .. "_fried",
	})
end

local function mob_storage_use(itemstack, player, pointed)
	local ent = pointed.ref and pointed.ref:get_luaentity()
	if ent
	and (ent.name:match("^pegasus:")
	or ent.name:match("^monstrum:")) then
		local desc = itemstack:get_short_description()
		if itemstack:get_count() > 1 then
			local name = itemstack:get_name()
			local inv = player:get_inventory()
			if inv:room_for_item("main", {name = name}) then
				itemstack:take_item(1)
				inv:add_item("main", name)
			end
			return itemstack
		end
		local plyr_name = player:get_player_name()
		local meta = itemstack:get_meta()
		local mob = meta:get_string("mob") or ""
		if mob == "" then
			pegasus.protect_from_despawn(ent)
			meta:set_string("mob", ent.name)
			meta:set_string("staticdata", ent:get_staticdata())
			local ent_name = correct_name(ent.name)
			local ent_gender = correct_name(ent.gender)
			desc = desc .. " \n" .. color("#a9a9a9", ent_name) .. "\n" .. color("#a9a9a9", ent_gender)
			if ent.trust
			and ent.trust[plyr_name] then
				desc = desc .. "\n Trust: " .. color("#a9a9a9", ent.trust[plyr_name])
			end
			meta:set_string("description", desc)
			player:set_wielded_item(itemstack)
			ent.object:remove()
			return itemstack
		else
			minetest.chat_send_player(plyr_name,
				"This " .. desc .. " already contains a " .. correct_name(mob))
		end
	end
end

-----------
-- Drops --
-----------

minetest.register_craftitem("pegasus:leather", {
	description = "Leather",
	inventory_image = "pegasus_leather.png",
	groups = {flammable = 2, leather = 1},
})


-- Meat --

minetest.register_craftitem("pegasus:beef_raw", {
	description = "Raw Beef",
	inventory_image = "pegasus_beef_raw.png",
	on_use = minetest.item_eat(1),
	groups = {flammable = 2, meat = 1, food_meat = 1},
})

minetest.register_craftitem("pegasus:beef_cooked", {
	description = "Steak",
	inventory_image = "pegasus_beef_cooked.png",
	on_use = minetest.item_eat(8),
	groups = {flammable = 2, meat = 1, food_meat = 1},
})

minetest.register_craft({
	type  =  "cooking",
	recipe  = "pegasus:beef_raw",
	output = "pegasus:beef_cooked",
})

----------
-- Misc --
----------

minetest.register_craftitem("pegasus:bucket_guano", {
	description = "Bucket of Guano",
	inventory_image = "pegasus_guano_bucket.png",
	stack_max = 1,
	groups = {flammable = 3},
	on_place = function(itemstack, placer, pointed)
		local pos = pointed.under
		local node = minetest.get_node(pos)
		if node
		and node.on_rightclick then
			return node.on_rightclick(pos, node, placer, itemstack)
		end
		if minetest.is_protected(pos, placer:get_player_name()) then
			return
		end
		local crops = minetest.find_nodes_in_area_under_air(
			vec_sub(pos, 5),
			vec_add(pos, 5),
			{"group:grass", "group:plant", "group:flora", "group:crop"}
		) or {}
		local crops_grown = 0
		for _, crop in ipairs(crops) do
			local crop_name = minetest.get_node(crop).name
			local growth_stage = tonumber(crop_name:sub(-1)) or 1
			local new_name = crop_name:sub(1, #crop_name - 1) .. (growth_stage + 1)
			local new_def = minetest.registered_nodes[new_name]
			if new_def then
				local p2 = new_def.place_param2 or 1
				minetest.set_node(crop, {name = new_name, param2 = p2})
				crops_grown = crops_grown + 1
			end
		end
		if crops_grown < 1 then minetest.set_node(pointed.above, {name = "pegasus:guano"}) end
		local meta = itemstack:get_meta()
		local og_item = meta:get_string("original_item")
		if og_item == "" then og_item = "bucket:bucket_empty" end
		itemstack:replace(ItemStack(og_item))
		return itemstack
	end
})


-----------
-- Tools --
-----------


local nametag = {}

local function get_rename_formspec(meta)
	local tag = meta:get_string("name") or ""
	local form = {
		"size[8,4]",
		"field[0.5,1;7.5,0;name;" .. minetest.formspec_escape("Enter name:") .. ";" .. tag .. "]",
		"button_exit[2.5,3.5;3,1;set_name;" .. minetest.formspec_escape("Set Name") .. "]"
	}
	return table.concat(form, "")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "pegasus:set_name" and fields.name then
		local name = player:get_player_name()
		if not nametag[name] then
			return
		end
		local itemstack = nametag[name]
		if string.len(fields.name) > 64 then
			fields.name = string.sub(fields.name, 1, 64)
		end
		local meta = itemstack:get_meta()
		meta:set_string("name", fields.name)
		meta:set_string("description", fields.name)
		player:set_wielded_item(itemstack)
		if fields.quit or fields.key_enter then
			nametag[name] = nil
		end
	end
end)

local function nametag_rightclick(itemstack, player, pointed_thing)
	if pointed_thing
	and pointed_thing.type == "object" then
		return
	end
	local name = player:get_player_name()
	nametag[name] = itemstack
	local meta = itemstack:get_meta()
	minetest.show_formspec(name, "pegasus:set_name", get_rename_formspec(meta))
end

minetest.register_craftitem("pegasus:nametag", {
	description = "Nametag",
	inventory_image = "pegasus_nametag.png",
	on_rightclick = nametag_rightclick,
	on_secondary_use = nametag_rightclick
})

minetest.register_craftitem("pegasus:saddle", {
	description = "Saddle",
	inventory_image = "pegasus_saddle.png",
})

minetest.register_craftitem("pegasus:net", {
	description = "Animal Net",
	inventory_image = "pegasus_net.png",
	stack_max = 1,
	on_secondary_use = mob_storage_use,
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		if pos then
			local under = minetest.get_node(pointed_thing.under)
			local node = minetest.registered_nodes[under.name]
			if node and node.on_rightclick then
				return node.on_rightclick(pointed_thing.under, under, placer,
										  itemstack)
			end
			if pos and not minetest.is_protected(pos, placer:get_player_name()) then
				local mob = itemstack:get_meta():get_string("mob")
				local staticdata = itemstack:get_meta():get_string("staticdata")
				if mob ~= "" then
					pos.y = pos.y +
								math.abs(
									minetest.registered_entities[mob]
										.collisionbox[2])
					minetest.add_entity(pos, mob, staticdata)
					itemstack:get_meta():set_string("mob", nil)
					itemstack:get_meta():set_string("staticdata", nil)
					itemstack:get_meta():set_string("description", "Animal Net")
				end
			end
		end
		return itemstack
	end
})

-----------
-- Armor --
-----------

if minetest.get_modpath("3d_armor") then

	if armor
	and armor.attributes then
		table.insert(armor.attributes, "heavy_pelt")

		minetest.register_on_punchplayer(function(player, hitter, _, _, _, damage)
			local name = player:get_player_name()
			if name
			and (armor.def[name].heavy_pelt or 0) > 0 then
				local hit_ip = hitter:is_player()
				if hit_ip and minetest.is_protected(player:get_pos(), "") then
					return
				else
					local player_pos = player:get_pos()
					if not player_pos then return end
	
					local biome_data = minetest.get_biome_data(player_pos)
	
					if biome_data.heat < 50 then
						player:set_hp(player:get_hp() - (damage / 1.5))
						return true
					end
				end
			end
		end)
	end


-----------
-- Nodes --
-----------

minetest.register_node("pegasus:guano", {
	description = "Guano",
	tiles = {"pegasus_guano.png"},
	paramtype = "light",
	buildable_to = true,
	floodable = true,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
		},
	},
	groups = {crumbly = 3, falling_node = 1, not_in_creative_inventory = 1},
	on_punch = function(pos, _, player)
		local inv = player:get_inventory()
		local stack = ItemStack("pegasus:bucket_guano")
		if not inv:room_for_item("main", stack) then return end
		local item = player:get_wielded_item()
		local item_name = item:get_name()
		if item_name:match("bucket_empty") then
			item:take_item()
			stack:get_meta():set_string("original_item", item_name)
			inv:add_item("main", stack)
			player:set_wielded_item(item)
			minetest.remove_node(pos)
		end
	end
})

minetest.register_node("pegasus:crate", {
	description = "Animal Crate",
	tiles = {"pegasus_crate.png", "pegasus_crate.png", "pegasus_crate_side.png"},
	groups = {choppy = 2},
	stack_max = 1,
	on_secondary_use = mob_storage_use,
	preserve_metadata = function(_, _, oldmeta, drops)
		for _, stack in pairs(drops) do
			if stack:get_name() == "pegasus:crate" then
				local meta = stack:get_meta()
				meta:set_string("mob", oldmeta["mob"])
				meta:set_string("staticdata", oldmeta["staticdata"])
				meta:set_string("description", oldmeta["description"])
			end
		end
	end,
	after_place_node = function(pos, placer, itemstack)
		local meta = itemstack:get_meta()
		local mob = meta:get_string("mob")
		if mob ~= "" then
			local nmeta = minetest.get_meta(pos)
			nmeta:set_string("mob", mob)
			nmeta:set_string("infotext", "Contains a " .. correct_name((mob)))
			nmeta:set_string("staticdata", meta:get_string("staticdata"))
			nmeta:set_string("description", meta:get_string("description"))
			itemstack:take_item()
			placer:set_wielded_item(itemstack)
		end
	end,
	on_rightclick = function(pos, _, clicker)
		if minetest.is_protected(pos, clicker:get_player_name()) then
			return
		end
		local meta = minetest.get_meta(pos)
		local mob = meta:get_string("mob")
		local staticdata = meta:get_string("staticdata")
		if mob ~= "" then
			local above = {
				x = pos.x,
				y = pos.y + 1,
				z = pos.z
			}
			if creatura.get_node_def(above).walkable then
				return
			end
			minetest.add_entity(above, mob, staticdata)
			meta:set_string("mob", nil)
			meta:set_string("infotext", nil)
			meta:set_string("staticdata", nil)
			meta:set_string("description", "Animal Crate")
		end
	end
})

--------------
-- Crafting --
--------------

local steel_ingot = "default:steel_ingot"

minetest.register_on_mods_loaded(function()
	if minetest.registered_items[steel_ingot] then return end
	for name, _ in pairs(minetest.registered_items) do
		if name:find("ingot")
		and (name:find("steel")
		or name:find("iron")) then
			steel_ingot = name
			break
		end
	end
end)


minetest.register_craft({
	output = "pegasus:lasso",
	recipe = {
		{"", "group:thread", "group:thread"},
		{"", "group:leather", "group:thread"},
		{"group:thread", "", ""}
	}
})

minetest.register_craft({
	output = "pegasus:lasso",
	recipe = {
		{"", "farming:string", "farming:string"},
		{"", "group:leather", "farming:string"},
		{"farming:string", "", ""}
	}
})

minetest.register_craft({
	output = "pegasus:net",
	recipe = {
		{"group:thread", "", "group:thread"},
		{"group:thread", "", "group:thread"},
		{"group:stick", "group:thread", ""}
	}
})

minetest.register_craft({
	output = "pegasus:net",
	recipe = {
		{"farming:string", "", "farming:string"},
		{"farming:string", "", "farming:string"},
		{"group:stick", "farming:string", ""}
	}
})

minetest.register_craft({
	output = "pegasus:crate",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "pegasus:net", "group:wood"},
		{"group:wood", "group:wood", "group:wood"}
	}
})

minetest.register_craft({
	output = "pegasus:saddle",
	recipe = {
		{"group:leather", "group:leather", "group:leather"},
		{"group:leather", steel_ingot, "group:leather"},
		{"group:thread", "", "group:thread"}
	}
})



minetest.register_craft({
	output = "pegasus:book_pegasus",
	recipe = {
		{"pegasus:leather", "default:paper", "pegasus:leather"},
		{"pegasus:leather", "default:paper", "pegasus:leather"},
		{"pegasus:leather", "default:paper", "pegasus:leather"}
	}
})


minetest.register_on_craft(function(itemstack, _, old_craft_grid)
	if itemstack:get_name() == "pegasus:book_pegasus"
	and itemstack:get_count() > 1 then
		for _, old_book in pairs(old_craft_grid) do
			if old_book:get_meta():get_string("chapters") then
				local chapters = old_book:get_meta():get_string("chapters")
				itemstack:get_meta():set_string("chapters", chapters)
				return itemstack
			end
		end
	end
end)
end