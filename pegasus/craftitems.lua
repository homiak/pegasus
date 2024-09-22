----------------
-- Craftitems --
----------------

local S = pegasus.S

local color = minetest.colorize

local function correct_name(str)
	if str then
		if str:match(":") then str = str:split(":")[2] end
		return (string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("_", " "))
	end
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
	description = S("Leather"),
	inventory_image = "pegasus_leather.png",
	groups = {flammable = 2, leather = 1},
})


-- Meat --

minetest.register_craftitem("pegasus:beef_raw", {
	description = S("Raw Pegasusbeef"),
	inventory_image = "pegasus_beef_raw.png",
	on_use = minetest.item_eat(1),
	groups = {flammable = 2, meat = 1, food_meat = 1},
})

minetest.register_craftitem("pegasus:beef_cooked", {
	description = S("Steak"),
	inventory_image = "pegasus_beef_cooked.png",
	on_use = minetest.item_eat(8),
	groups = {flammable = 2, meat = 1, food_meat = 1},
})

minetest.register_craft({
	type  =  "cooking",
	recipe  = "pegasus:beef_raw",
	output = "pegasus:beef_cooked",
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
	description = S("Nametag"),
	inventory_image = "pegasus_nametag.png",
	on_rightclick = nametag_rightclick,
	on_secondary_use = nametag_rightclick
})

minetest.register_craftitem("pegasus:saddle", {
	description = S("Saddle"),
	inventory_image = "pegasus_saddle.png",
})

minetest.register_craftitem("pegasus:net", {
	description = S("Pegasus Net"),
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
					itemstack:get_meta():set_string("description", S("Pegasus Net"))
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

minetest.register_node("pegasus:crate", {
	description = S("Pegasus Crate"),
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
			nmeta:set_string("infotext", S("Contains a Pegasus"))
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
			meta:set_string("description", S("Pegasus Crate"))
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

