----------------
-- Craftitems --
----------------


local S = waterdragon.S

-- Local Math --

local function round(n, dec)
	local mult = 10 ^ (dec or 0)
	return math.floor(n * mult + 0.5) / mult
end

-- Get Craft Items --

local rare_water_block = "default:water_flowing"

minetest.register_on_mods_loaded(function()
	if minetest.registered_items[rare_water_block] then return end
	for name in pairs(minetest.registered_items) do
		if name:match(":water_flowing") and minetest.get_item_group(name, "slippery") > 0 then
			rare_water_block = name
			break
		end
	end
end)

-- Local Utilities --

local wtd_drops = {}

local function correct_name(str)
	if str then
		if str:match(":") then str = str:split(":")[2] end
		return (string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("_", " "))
	end
end

local function infotext(str, format)
	if format then
		return minetest.colorize("#bdd9ff", correct_name(str))
	end
	return minetest.colorize("#bdd9ff", str)
end

local function get_horn_desc(self)
	local info = S("Dragon Horn\n") .. minetest.colorize("#bdd9ff", correct_name(self.name))
	if self.nametag == "" then
		info = info .. "\n" .. infotext("a Nameless Dragon")
	else
		info = info .. "\n" .. infotext(self.nametag or "a Nameless Dragon")
	end
	if self.age then
		info = info .. "\n" .. infotext(self.age)
	end
	if self.color then
		info = info .. "\n" .. infotext(self.color, true)
	end
	return info
end

-----------
-- Drops --
-----------

minetest.register_craftitem("waterdragon:dragon_water_drop", {
	description = S("Drop of Dragon Water"),
	inventory_image = "waterdragon_dragon_water_drop.png",
	groups = { wtd_drops = 1 },
	on_use = function(itemstack, user, pointed_thing)

		if not user or not pointed_thing then return false end
		
		local entity
        if pointed_thing.type == "object" then
            -- If the player is pointing at an object, check if it's a mob
            local pointed_object = pointed_thing.ref
            entity = pointed_object:get_luaentity()
        end

		if entity and entity.hp and entity.hp <= 0 then
			local ent_pos = entity:get_center_pos()
			local particle = "waterdragon_particle_green.png"
			entity.hp = entity.max_health
			entity:memorize("hp", entity.hp)
			minetest.chat_send_player(user:get_player_name(), S("The animal has been revived!"))
			minetest.add_particlespawner({
				amount = 16,
				time = 0.25,
				minpos = {
					x = ent_pos.x - entity.width,
					y = ent_pos.y - entity.width,
					z = ent_pos.z - entity.width
				},
				maxpos = {
					x = ent_pos.x + entity.width,
					y = ent_pos.y + entity.width,
					z = ent_pos.z + entity.width
				},
				minacc = { x = 0, y = 0.25, z = 0 },
				maxacc = { x = 0, y = -0.25, z = 0 },
				minexptime = 0.75,
				maxexptime = 1,
				minsize = 4,
				maxsize = 4,
				texture = particle,
				glow = 16
			})

		-- Consume the item from the player's inventory
		itemstack:take_item()
		return itemstack
		else
			minetest.chat_send_player(user:get_player_name(), S("You must be pointing at a dead mob"))
		end
	end
})

table.insert(wtd_drops, "waterdragon:dragon_water_drop")

minetest.register_craftitem("waterdragon:dragon_bone", {
	description = S("Water Dragon Bone"),
	inventory_image = "waterdragon_dragon_bone.png",
	groups = { bone = 1 }
})

table.insert(wtd_drops, "waterdragon:dragon_bone")

for color, hex in pairs(waterdragon.colors_pure_water) do
	minetest.register_craftitem("waterdragon:scales_pure_water_dragon", {
		description = S("Pure Water Dragon Scales"),
		inventory_image = "waterdragon_wtd_scales.png^[multiply:#" .. hex,
		groups = { dragon_scales = 1 }
	})
	table.insert(wtd_drops, "waterdragon:scales_pure_water_dragon")
end

for color, hex in pairs(waterdragon.colors_rare_water) do
	minetest.register_craftitem("waterdragon:scales_rare_water_dragon", {
		description = S("Rare Water Dragon Scales"),
		inventory_image = "waterdragon_wtd_scales.png^[multiply:#" .. hex,
		groups = { dragon_scales = 1 }
	})
	table.insert(wtd_drops, "waterdragon:scales_rare_water_dragon")
end

---------------
-- Materials --
---------------

minetest.register_craftitem("waterdragon:draconic_steel_ingot_pure_water", {
	description = S("Pure Water-Forged Draconic Steel Ingot"),
	inventory_image = "waterdragon_draconic_steel_ingot_pure_water.png",
	stack_max = 1
})

minetest.register_craftitem("waterdragon:draconic_steel_ingot_rare_water", {
	description = S("Rare Water-Forged Draconic Steel Ingot"),
	inventory_image = "waterdragon_draconic_steel_ingot_rare_water.png",
	stack_max = 1
})

----------
-- Eggs --
----------

local function egg_rightclick(self, clicker, item)
	if not minetest.is_creative_enabled(clicker) then
		local inv = clicker:get_inventory()
		if inv:room_for_item("main", { name = item }) then
			clicker:get_inventory():add_item("main", item)
		else
			local pos = self.object:get_pos()
			if not pos then return end
			pos.y = pos.y + 0.5
			minetest.add_item(pos, { name = item })
		end
	end
	self.object:remove()
end

local dragon_eggs = {}

for color in pairs(waterdragon.colors_pure_water) do
	minetest.register_node("waterdragon:egg_pure_water", {
		description = S("Pure Water Dragon Egg"),
		drawtype = "mesh",
		paramtype = "light",
		sunlight_propagates = true,
		mesh = "waterdragon_egg.obj",
		inventory_image = "waterdragon_pure_water_dragon_egg.png",
		tiles = { "waterdragon_pure_water_dragon_egg_mesh.png" },
		collision_box = {
			type = "fixed",
			fixed = {
				{ -0.25, -0.5, -0.25, 0.25, 0.1, 0.25 },
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{ -0.25, -0.5, -0.25, 0.25, 0.1, 0.25 },
			},
		},
		groups = { cracky = 1, level = 3 },
		sounds = waterdragon.sounds.stone,
		on_construct = function(pos)
			local timer = minetest.get_node_timer(pos)
			timer:start(6)
		end,
		on_timer = function(pos)
			local nest_n = 0
			local nest_check = {
				vector.add(pos, { x = 0, y = -1, z = 0 }),
				vector.add(pos, { x = 1, y = -1, z = 0 }),
				vector.add(pos, { x = 1, y = -1, z = 1 }),
				vector.add(pos, { x = 0, y = -1, z = 1 }),
				vector.add(pos, { x = -1, y = -1, z = 1 }),
				vector.add(pos, { x = -1, y = -1, z = 0 }),
				vector.add(pos, { x = -1, y = -1, z = -1 }),
				vector.add(pos, { x = 0, y = -1, z = -1 }),
				vector.add(pos, { x = 1, y = -1, z = -1 })
			}
			for i = 1, #nest_check do
				local node = minetest.get_node(nest_check[i])
				local name = node.name
				if name == "waterdragon:bone_pile_wet" then
					nest_n = nest_n + 1
				end
				if nest_n > 8 then
					pos.y = pos.y - 0.49
					minetest.add_entity(pos, "waterdragon:egg_pure_water_dragon")
					minetest.remove_node(pos)
					break
				end
			end
			return true
		end
	})

	table.insert(dragon_eggs, "waterdragon:egg_pure_water")

	creatura.register_mob("waterdragon:egg_pure_water_dragon", {
		-- Stats
		max_health = 30,
		armor_groups = { immortal = 1 },
		despawn_after = false,
		-- Entity Physics
		stepheight = 1.1,
		max_fall = 0,
		-- Visuals
		mesh = "waterdragon_egg.b3d",
		hitbox = {
			width = 0.25,
			height = 0.6
		},
		visual_size = { x = 10, y = 10 },
		textures = { "waterdragon_pure_water_dragon_egg_mesh.png" },
		animations = {
			idle = { range = { x = 0, y = 0 }, speed = 1, frame_blend = 0.3, loop = false },
			hatching = { range = { x = 70, y = 130 }, speed = 15, frame_blend = 0.3, loop = true },
		},
		-- Function
		activate_func = function(self)
			self.progress = self:recall("progress") or 0
			self.owner_name = self:recall("owner_name") or ""
			if color == "pure_water" then
				self.tex_no = 1
			end
		end,
		step_func = function(self, dtime)
			local pos = self.object:get_pos()
			if not pos then return end
			if not self.owner_name
				or self:timer(10) then
				for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 6)) do
					if obj and obj:is_player() then
						minetest.after(1.5, function()
							self.owner_name = self:memorize("owner_name", obj:get_player_name())
						end)
					end
				end
			end
			local name = creatura.get_node_def(pos).name
			local progress = self.progress or 0
			if minetest.get_item_group(name, "water") > 0
				or (progress > 0 and name == rare_water_block) then
				if minetest.get_item_group(name, "water") > 0 then
					minetest.set_node(pos, { name = rare_water_block })
				end
				progress = progress + dtime
				if not self.hatching then
					self.hatching = true
					self.object:set_animation({ x = 1, y = 40 }, 30, 0)
				end
				if progress >= 1000 then
					local object = minetest.add_entity(pos, "waterdragon:pure_water_dragon")
					local ent = object:get_luaentity()
					ent.age = ent:memorize("age", 1)
					ent.growth_scale = 0.03
					ent:memorize("growth_scale", 0.03)
					ent.growth_stage = ent:memorize("growth_stage", 1)
					ent.texture_no = self.tex_no
					ent:set_scale(0.03)
					if self.owner_name ~= "" then ent.owner = ent:memorize("owner", self.owner_name) end
					minetest.remove_node(pos)
					self.object:remove()
					return
				end
			else
				progress = 0
				self.hatching = false
				self.object:set_animation({ x = 0, y = 0 }, 0, 0)
			end
			self.progress = self:memorize("progress", progress)
		end,
		on_rightclick = function(self, clicker)
			egg_rightclick(self, clicker, "waterdragon:egg_pure_water")
		end
	})
end

-- Rare Water Eggs --

for color in pairs(waterdragon.colors_rare_water) do
	minetest.register_node("waterdragon:egg_rare_water", {
		description = S("Rare Water Dragon Egg"),
		drawtype = "mesh",
		paramtype = "light",
		sunlight_propagates = true,
		mesh = "waterdragon_egg.obj",
		inventory_image = "waterdragon_rare_water_dragon_egg.png",
		tiles = { "waterdragon_rare_water_dragon_egg_mesh.png" },
		collision_box = {
			type = "fixed",
			fixed = {
				{ -0.25, -0.5, -0.25, 0.25, 0.1, 0.25 },
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{ -0.25, -0.5, -0.25, 0.25, 0.1, 0.25 },
			},
		},
		groups = { cracky = 1, level = 3 },
		sounds = waterdragon.sounds.stone,
		on_construct = function(pos)
			local timer = minetest.get_node_timer(pos)
			timer:start(6)
		end,
		on_timer = function(pos)
			local nest_n = 0
			local nest_check = {
				vector.add(pos, { x = 0, y = -1, z = 0 }),
				vector.add(pos, { x = 1, y = -1, z = 0 }),
				vector.add(pos, { x = 1, y = -1, z = 1 }),
				vector.add(pos, { x = 0, y = -1, z = 1 }),
				vector.add(pos, { x = -1, y = -1, z = 1 }),
				vector.add(pos, { x = -1, y = -1, z = 0 }),
				vector.add(pos, { x = -1, y = -1, z = -1 }),
				vector.add(pos, { x = 0, y = -1, z = -1 }),
				vector.add(pos, { x = 1, y = -1, z = -1 })
			}
			for i = 1, #nest_check do
				local node = minetest.get_node(nest_check[i])
				local name = node.name
				if name == "waterdragon:bone_pile_wet" then
					nest_n = nest_n + 1
				end
				if nest_n > 8 then
					pos.y = pos.y - 0.49
					minetest.add_entity(pos, "waterdragon:egg_rare_water_dragon")
					minetest.remove_node(pos)
					break
				end
			end
			return true
		end
	})

	table.insert(dragon_eggs, "waterdragon:egg_rare_water")

	creatura.register_mob("waterdragon:egg_rare_water_dragon", {
		-- Stats
		max_health = 30,
		armor_groups = { immortal = 1 },
		despawn_after = false,
		-- Entity Physics
		stepheight = 1.1,
		max_fall = 0,
		-- Visuals
		mesh = "waterdragon_egg.b3d",
		hitbox = {
			width = 0.25,
			height = 0.6
		},
		visual_size = { x = 10, y = 10 },
		textures = { "waterdragon_rare_water_dragon_egg_mesh.png" },
		animations = {
			idle = { range = { x = 0, y = 0 }, speed = 1, frame_blend = 0.3, loop = false },
			hatching = { range = { x = 70, y = 130 }, speed = 15, frame_blend = 0.3, loop = true },
		},
		-- Function
		activate_func = function(self)
			self.progress = self:recall("progress") or 0
			self.owner_name = self:recall("owner_name") or ""
			if color == "rare_water" then
				self.tex_no = 1
			end
		end,
		step_func = function(self, dtime)
			local pos = self.object:get_pos()
			if not pos then return end
			if not self.owner_name
				or self:timer(10) then
				for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 6)) do
					if obj and obj:is_player() then
						minetest.after(1.5, function()
							self.owner_name = self:memorize("owner_name", obj:get_player_name())
						end)
					end
				end
			end
			local name = creatura.get_node_def(pos).name
			local progress = self.progress or 0
			if minetest.get_item_group(name, "water") > 0
				or (progress > 0 and name == rare_water_block) then
				if minetest.get_item_group(name, "water") > 0 then
					minetest.set_node(pos, { name = rare_water_block })
				end
				progress = progress + dtime
				if not self.hatching then
					self.hatching = true
					self.object:set_animation({ x = 1, y = 40 }, 30, 0)
				end
				if progress >= 1000 then
					local object = minetest.add_entity(pos, "waterdragon:rare_water_dragon")
					local ent = object:get_luaentity()
					ent.age = ent:memorize("age", 1)
					ent.growth_scale = 0.03
					ent:memorize("growth_scale", 0.03)
					ent.growth_stage = ent:memorize("growth_stage", 1)
					ent.texture_no = self.tex_no
					ent:set_scale(0.03)
					if self.owner_name ~= "" then ent.owner = ent:memorize("owner", self.owner_name) end
					minetest.remove_node(pos)
					self.object:remove()
					return
				end
			else
				progress = 0
				self.hatching = false
				self.object:set_animation({ x = 0, y = 0 }, 0, 0)
			end
			self.progress = self:memorize("progress", progress)
		end,
		on_rightclick = function(self, clicker)
			egg_rightclick(self, clicker, "waterdragon:egg_rare_water")
		end
	})
end

--------------------------
-- Water Dragon Storage --
--------------------------

-- API --

local function capture(player, ent)
	if not player:is_player()
		or not player:get_inventory() then
		return false
	end
	local stack = player:get_wielded_item()
	local meta = stack:get_meta()
	if not meta:get_string("staticdata")
		or meta:get_string("staticdata") == "" then
		if not ent.wtd_id then return end
		local stored_aging = meta:get_int("stored_aging") or 0
		waterdragon.set_color_string(ent)
		meta:set_string("mob", ent.name)
		meta:set_string("wtd_id", ent.wtd_id)
		meta:set_string("staticdata", ent:get_staticdata())
		meta:set_string("nametag", ent.nametag or "a Nameless Dragon")
		meta:set_string("description", get_horn_desc(ent))
		if stored_aging > 0 then
			meta:set_int("timestamp", os.time())
		end
		player:set_wielded_item(stack)
		waterdragon.waterdragons[ent.wtd_id].stored_in_item = true
		ent.object:remove()
		waterdragon.force_storage_save = true
		return stack
	else
		minetest.chat_send_player(player:get_player_name(), S("This Dragon Horn already contains a Water Dragon"))
		return false
	end
end

local function get_wtd_by_id(wtd_id)
	for _, ent in pairs(minetest.luaentities) do
		if ent.wtd_id
			and ent.wtd_id == wtd_id then
			return ent
		end
	end
end

-- Items --

local function dragon_horn_use(itemstack, player, pointed_thing)
	local meta = itemstack:get_meta()
	local staticdata = meta:get_string("staticdata")
	if staticdata ~= "" then return end -- Skip func if Horn contains Water Dragon
	local mob = meta:get_string("mob")
	local id = meta:get_string("wtd_id")
	local stored_aging = meta:get_int("stored_aging") or 0
	if player:get_player_control().sneak then
		if stored_aging < 1 then
			meta:set_int("stored_aging", 1)
			minetest.chat_send_player(player:get_player_name(), S("Your Water Dragon will age while stored"))
		else
			meta:set_int("stored_aging", 0)
			minetest.chat_send_player(player:get_player_name(), S("Your Water Dragon will not age while stored"))
		end
		player:set_wielded_item(itemstack)
		return itemstack
	end
	if id ~= "" then -- If the Horn has a linked Water Dragon
		if not waterdragon.waterdragons[id] then -- Clear data if linked Water Dragon is dead
			meta:set_string("mob", nil)
			meta:set_string("wtd_id", nil)
			meta:set_string("staticdata", nil)
			meta:set_string("description", S("Dragon Horn"))
			player:set_wielded_item(itemstack)
			return itemstack
		end
		local ent = pointed_thing.ref and pointed_thing.ref:get_luaentity()
		if ent
			and ent.name:match("^waterdragon:")
			and ent.wtd_id
			and ent.wtd_id == id
			and not ent.rider then -- Store Water Dragon if linked to Horn
			return capture(player, ent)
		end
		-- Teleport linked Water Dragon if not pointed
		local last_pos = waterdragon.waterdragons[id].last_pos
		ent = get_wtd_by_id(id)
		if waterdragon.waterdragons[id].stored_in_item then return itemstack end
		if not ent then
			table.insert(waterdragon.waterdragons[id].removal_queue, last_pos)
			minetest.add_entity(player:get_pos(), mob, waterdragon.waterdragons[id].staticdata)
		else
			ent.object:set_pos(player:get_pos())
		end
		minetest.chat_send_player(player:get_player_name(), S("You have called your Water Dragon"))
	else -- Link Water Dragon to Horn
		local ent = pointed_thing.ref and pointed_thing.ref:get_luaentity()
		if ent
			and ent.name:match("^waterdragon:")
			and ent.wtd_id
			and ent.owner
			and ent.owner == player:get_player_name()
			and not ent.rider then
			return capture(player, ent)
		end
	end
	return itemstack
end

local function dragon_horn_place(itemstack, player, pointed_thing)
	local meta = itemstack:get_meta()
	local pos = pointed_thing.above
	local under = pointed_thing.type == "node" and pointed_thing.under
	local node_def = creatura.get_node_def(under)
	if node_def.on_rightclick then
		return node_def.on_rightclick(under, minetest.get_node(under), player, itemstack)
	end
	if pos
		and not minetest.is_protected(pos, player:get_player_name()) then
		pos.y = pos.y + 3
		local mob = meta:get_string("mob")
		local staticdata = meta:get_string("staticdata")
		local nametag = meta:get_string("nametag") or "a Nameless Dragon"
		local id = meta:get_string("wtd_id")
		if not waterdragon.waterdragons[id] then -- Clear data if linked Water Dragon is dead
			meta:set_string("mob", nil)
			meta:set_string("wtd_id", nil)
			meta:set_string("staticdata", nil)
			meta:set_string("description", S("Dragon Horn"))
			player:set_wielded_item(itemstack)
			return itemstack
		end
		if staticdata == ""
			and id ~= ""
			and waterdragon.waterdragons[id]
			and waterdragon.waterdragons[id].stored_in_item then
			staticdata = waterdragon.waterdragons[id].staticdata
		end
		if staticdata ~= "" then
			local ent = minetest.add_entity(pos, mob, staticdata)
			if id ~= ""
				and waterdragon.waterdragons[id] then
				waterdragon.waterdragons[id].stored_in_item = false
			end
			waterdragon.force_storage_save = true
			local desc = S("Dragon Horn\n") .. minetest.colorize("#bdd9ff", correct_name(mob))
			if nametag ~= "" then
				desc = desc .. "\n" .. infotext(nametag)
			end
			meta:set_string("staticdata", nil)
			meta:set_string("description", desc)
			if meta:get_int("timestamp") > 0 then
				local time = meta:get_int("timestamp")
				local diff = os.time() - time
				ent:get_luaentity().time_in_horn = diff
				meta:set_int("timestamp", os.time())
			end
			return itemstack
		end
	end
end

minetest.register_craftitem("waterdragon:dragon_horn", {
	description = S("Dragon Horn"),
	inventory_image = "waterdragon_dragon_horn.png",
	stack_max = 1,
	on_place = dragon_horn_place,
	on_secondary_use = dragon_horn_use
})

minetest.register_alias("waterdragon:dragon_horn", "waterdragon:dragon_horn")
minetest.register_alias("waterdragon:dragon_flute", "waterdragon:dragon_horn")

--------------
-- Crucible --
--------------

minetest.register_craftitem("waterdragon:dragonstone_crucible", {
	description = S("Water Dragonstone Crucible"),
	inventory_image = "waterdragon_dragonstone_crucible.png",
	stack_max = 999
})

minetest.register_craftitem("waterdragon:dragonstone_crucible_full", {
	description = S("Water Dragonstone Crucible (Full)"),
	inventory_image = "waterdragon_dragonstone_crucible_full.png",
	stack_max = 1,
	groups = { not_in_creative_inventory = 1 }
})

-----------
-- Tools --
-----------

-- Dragonhide --

for color in pairs(waterdragon.colors_pure_water) do
	-- Pick
	minetest.register_tool("waterdragon:pick_dragonhide_pure_water", {
		description = S("Pure Water Dragonhide Pickaxe"),
		inventory_image = "waterdragon_dragonhide_pick_pure_water.png",
		wield_scale = { x = 1.5, y = 1.5, z = 1 },
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 3,
			groupcaps = {
				cracky = {
					times = { [1] = 1.2, [2] = 0.8, [3] = 0.6 },
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 4 }
		},
		sound = { breaks = "default_tool_breaks" },
		groups = { pickaxe = 1 }
	})

	-- Shovel
	minetest.register_tool("waterdragon:shovel_dragonhide_pure_water", {
		description = S("Pure Water Dragonhide Shovel"),
		inventory_image = "waterdragon_dragonhide_shovel_pure_water.png",
		wield_scale = { x = 1.5, y = 1.5, z = 1 },
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 1,
			groupcaps = {
				crumbly = {
					times = { [1] = 0.8, [2] = 0.6, [3] = 0.4 },
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 4 }
		},
		sound = { breaks = "default_tool_breaks" },
		groups = { shovel = 1 }
	})
	
	-- Axe
	minetest.register_tool("waterdragon:axe_dragonhide_pure_water", {
		description = S("Pure Water Dragonhide Axe"),
		inventory_image = "waterdragon_dragonhide_axe_pure_water.png",
		wield_scale = { x = 1.5, y = 1.5, z = 1 },
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 1,
			groupcaps = {
				choppy = {
					times = { [1] = 1.2, [2] = 0.8, [3] = 0.6 },
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 6 }
		},
		sound = { breaks = "default_tool_breaks" },
		groups = { axe = 1 }
	})
	
	-- Sword
	minetest.register_tool("waterdragon:sword_dragonhide_pure_water", {
		description = S("Pure Water Dragonhide Sword"),
		inventory_image = "waterdragon_dragonhide_sword_pure_water.png",
		wield_scale = { x = 1.5, y = 1.5, z = 1 },
		tool_capabilities = {
			full_punch_interval = 0.1,
			max_drop_level = 1,
			groupcaps = {
				snappy = {
					times = { [1] = 0.4, [2] = 0.2, [3] = 0.1 },
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 12 }
		},
		range = 6,
		sound = { breaks = "default_tool_breaks" },
		groups = { sword = 1 }
	})
end

for color in pairs(waterdragon.colors_rare_water) do
	-- Pickaxe
	minetest.register_tool("waterdragon:pick_dragonhide_rare_water", {
		description = S("Rare Water Dragonhide Pickaxe"),
		inventory_image = "waterdragon_dragonhide_pick_rare_water.png",
		wield_scale = { x = 1.5, y = 1.5, z = 1 },
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 3,
			groupcaps = {
				cracky = {
					times = { [1] = 1.2, [2] = 0.8, [3] = 0.6 },
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 4 }
		},
		sound = { breaks = "default_tool_breaks" },
		groups = { pickaxe = 1 }
	})

	-- Shovel
	minetest.register_tool("waterdragon:shovel_dragonhide_rare_water", {
		description = S("Rare Water Dragonhide Shovel"),
		inventory_image = "waterdragon_dragonhide_shovel_rare_water.png",
		wield_scale = { x = 1.5, y = 1.5, z = 1 },
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 1,
			groupcaps = {
				crumbly = {
					times = { [1] = 0.8, [2] = 0.6, [3] = 0.4 },
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 4 }
		},
		sound = { breaks = "default_tool_breaks" },
		groups = { shovel = 1 }
	})
	
	-- Axe
	minetest.register_tool("waterdragon:axe_dragonhide_rare_water", {
		description = S("Rare Water Dragonhide Axe"),
		inventory_image = "waterdragon_dragonhide_axe_rare_water.png",
		wield_scale = { x = 1.5, y = 1.5, z = 1 },
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 1,
			groupcaps = {
				choppy = {
					times = { [1] = 1.2, [2] = 0.8, [3] = 0.6 },
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 6 }
		},
		sound = { breaks = "default_tool_breaks" },
		groups = { axe = 1 }
	})
	
	-- Sword
	minetest.register_tool("waterdragon:sword_dragonhide_rare_water", {
		description = S("Rare Water Dragonhide Sword"),
		inventory_image = "waterdragon_dragonhide_sword_rare_water.png",
		wield_scale = { x = 1.5, y = 1.5, z = 1 },
		tool_capabilities = {
			full_punch_interval = 0.1,
			max_drop_level = 1,
			groupcaps = {
				snappy = {
					times = { [1] = 0.4, [2] = 0.2, [3] = 0.1 },
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 12 }
		},
		range = 6,
		sound = { breaks = "default_tool_breaks" },
		groups = { sword = 1 }
	})
end

minetest.register_alias("waterdragon:pick_dragonbone", "waterdragon:pick_dragonhide_pure_water_black")
minetest.register_alias("waterdragon:shovel_dragonbone", "waterdragon:shovel_dragonhide_pure_water_black")
minetest.register_alias("waterdragon:axe_dragonbone", "waterdragon:axe_dragonhide_pure_water_black")
minetest.register_alias("waterdragon:sword_dragonbone", "waterdragon:sword_dragonhide_pure_water_black")

-- Draconic Steel --

local function draconic_step(itemstack, player, pointed_thing)
	local meta = itemstack:get_meta()
	local name = itemstack:get_name()
	local wtd_id = meta:get_string("wtd_id")
	local def = minetest.registered_tools[name]
	local toolcaps = table.copy(def.tool_capabilities)
	local current_caps = itemstack:get_tool_capabilities()
	-- Play Swing
	if name:find("sword") then
		minetest.sound_play(
			{ name = "waterdragon_draconic_steel_swing", pitch = math.random(-3, 3) * 0.1 },
			{ pos = player:get_pos(), gain = 1.0, max_hear_distance = 12 }
		)
		if pointed_thing.under then
			local node = minetest.get_node(pointed_thing.under)
			if minetest.get_item_group(node.name, "snappy") > 0 then
				minetest.dig_node(pointed_thing.under)
			end
		end
	end
	-- Destroy Tool if Water Dragon is not alive
	if wtd_id ~= ""
		and not waterdragon.waterdragons[wtd_id] then
		itemstack:set_wear(65536)
		minetest.sound_play(
			{ name = "waterdragon_draconic_steel_shatter", pitch = math.random(-5, 5) * 0.1 },
			{ pos = player:get_pos(), gain = 1.0, max_hear_distance = 48 }
		)
		return itemstack
	end
	-- Get distance to Water Dragon
	local dragon_data = waterdragon.waterdragons[wtd_id]
	local pos = player:get_pos()
	local dist2dragon
	if wtd_id ~= ""
		and not dragon_data.stored_in_item then
		local dragon_pos = dragon_data.last_pos
		dist2dragon = vector.distance(pos, dragon_pos)
	else
		dist2dragon = 200
	end
	-- Adjust Power Level based on distance
	local speed_offset = dist2dragon * 0.01
	local damage_offset = dist2dragon * 0.015
	local update = false
	if dist2dragon > 200 then
		speed_offset = 2
	elseif dist2dragon < 25 then
		speed_offset = 0
	end
	speed_offset = round(speed_offset, 0.1)
	for k, v in pairs(toolcaps.groupcaps) do
		for i = 1, 3 do
			local def_time = v.times[i]
			local current_time = round(current_caps.groupcaps[k].times[i], 0.1)
			local time_diff = math.abs((def_time + speed_offset) - current_time)
			if time_diff > 0.1 then
				update = true
			end
			v.times[i] = def_time + speed_offset
		end
	end
	if toolcaps.damage_groups then
		toolcaps.damage_groups.fleshy = toolcaps.damage_groups.fleshy - damage_offset
	end
	if pointed_thing.ref then
		pointed_thing.ref:punch(player, nil, toolcaps)
		if dist2dragon < 30 then
		end
	end
	if update then
		meta:set_tool_capabilities(toolcaps)
		return itemstack
	end
end

local elements = { "rare_water", "pure_water" }

for _, element in pairs(elements) do
	minetest.register_tool("waterdragon:pick_" .. element .. "_draconic_steel", {
		description = S(correct_name(element) .. "-Forged Draconic Steel Pickaxe"),
		inventory_image = "waterdragon_" .. element .. "_draconic_steel_pick.png",
		wield_scale = { x = 2, y = 2, z = 1 },
		tool_capabilities = {
			full_punch_interval = 4,
			max_drop_level = 3,
			groupcaps = {
				cracky = {
					times = { [1] = 0.3, [2] = 0.15, [3] = 0.075 },
					uses = 0,
					maxlevel = 3
				},
				crumbly = {
					times = { [1] = 0.5, [2] = 0.25, [3] = 0.2 },
					uses = 0,
					maxlevel = 3
				},
			},
			damage_groups = { fleshy = 35 }
		},
		range = 6,
		sound = { breaks = "default_tool_breaks" },
		groups = { pickaxe = 1 },
		after_use = draconic_step
	})

	minetest.register_tool("waterdragon:shovel_" .. element .. "_draconic_steel", {
		description = S(correct_name(element) .. "-Forged Draconic Steel Shovel"),
		inventory_image = "waterdragon_" .. element .. "_draconic_steel_shovel.png",
		wield_scale = { x = 2, y = 2, z = 1 },
		tool_capabilities = {
			full_punch_interval = 5.5,
			max_drop_level = 1,
			groupcaps = {
				crumbly = {
					times = { [1] = 0.4, [2] = 0.2, [3] = 0.1 },
					uses = 0,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 30 }
		},
		range = 6,
		sound = { breaks = "default_tool_breaks" },
		groups = { shovel = 1 },
		after_use = draconic_step
	})

	minetest.register_tool("waterdragon:axe_" .. element .. "_draconic_steel", {
		description = S(correct_name(element) .. "-Forged Draconic Steel Axe"),
		inventory_image = "waterdragon_" .. element .. "_draconic_steel_axe.png",
		wield_scale = { x = 2, y = 2, z = 1 },
		tool_capabilities = {
			full_punch_interval = 3,
			max_drop_level = 1,
			groupcaps = {
				choppy = {
					times = { [1] = 0.3, [2] = 0.15, [3] = 0.075 },
					uses = 0,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 100 }
		},
		range = 6,
		sound = { breaks = "default_tool_breaks" },
		groups = { axe = 1 },
		after_use = draconic_step
	})

	minetest.register_tool("waterdragon:sword_" .. element .. "_draconic_steel", {
		description = S(correct_name(element) .. "-Forged Draconic Steel Sword"),
		inventory_image = "waterdragon_" .. element .. "_draconic_steel_sword.png",
		wield_scale = { x = 2, y = 2, z = 1 },
		tool_capabilities = {
			full_punch_interval = 1.2,
			max_drop_level = 1,
			groupcaps = {
				snappy = {
					times = { [1] = 0.05, [2] = 0.025, [3] = 0.01 },
					uses = 0,
					maxlevel = 3
				}
			},
			damage_groups = { fleshy = 100 }
		},
		range = 6,
		sound = { breaks = "default_tool_breaks" },
		groups = { sword = 1 },
		on_use = draconic_step
	})
end

--------------
-- Crafting --
--------------

minetest.register_alias_force("waterdragon:bestiary", "waterdragon:book_waterdragon")
minetest.register_alias_force("waterdragon:lectern", "waterdragon:log_wet") -- I do a little trolling

-- Get Craft Items --

local pure_water_block = "default:water_flowing"
local rare_water_block = "default:water_flowing"

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_items) do
		if name:find("gold") and name:find("block") then
			pure_water_block = name
		end
		if (name:find("steel") or name:find("iron")) and name:find("block") then
			rare_water_block = name
		end
	end
end)

-------------
-- Recipes --
-------------

minetest.register_craft({
	output = "waterdragon:dragonstone_block_rare_water",
	recipe = {
		{ "",                      "waterdragon:wet_stone", "" },
		{ "waterdragon:wet_stone", "waterdragon:wet_stone", "waterdragon:wet_stone" },
		{ "",                      "waterdragon:wet_stone", "" },
	}
})

minetest.register_craft({
	output = "waterdragon:dragonstone_block_pure_water",
	recipe = {
		{ "", "waterdragon:wet_soil", "" },
		{ "waterdragon:wet_soil", "waterdragon:wet_soil", "waterdragon:wet_soil" },
		{ "", "waterdragon:wet_soil", "" },
	}
})

minetest.register_craft({
	output = "waterdragon:book_waterdragon",
	recipe = {
		{ "group:wtd_scales", "default:paper", "group:wtd_scales" },
		{ "group:wtd_scales", "default:paper", "group:wtd_scales" },
		{ "group:wtd_scales", "default:paper", "group:wtd_scales" },
	}
})


minetest.register_craft({
	output = "waterdragon:wood_planks_wet",
	recipe = {
		{ "waterdragon:log_wet" }
	}
})

minetest.register_craft({
	output = "waterdragon:draconic_steel_forge_rare_water",
	recipe = {
		{ "waterdragon:dragonstone_block_rare_water", "waterdragon:dragonstone_block_rare_water", "waterdragon:dragonstone_block_rare_water" },
		{ "waterdragon:dragonstone_block_rare_water", "default:furnace", "waterdragon:dragonstone_block_rare_water" },
		{ "waterdragon:dragonstone_block_rare_water", "waterdragon:dragonstone_block_rare_water", "waterdragon:dragonstone_block_rare_water" },
	}
})

minetest.register_craft({
	output = "waterdragon:draconic_steel_forge_pure_water",
	recipe = {
		{ "waterdragon:dragonstone_block_pure_water", "waterdragon:dragonstone_block_pure_water", "waterdragon:dragonstone_block_pure_water" },
		{ "waterdragon:dragonstone_block_pure_water", "default:furnace", "waterdragon:dragonstone_block_pure_water" },
		{ "waterdragon:dragonstone_block_pure_water", "waterdragon:dragonstone_block_pure_water", "waterdragon:dragonstone_block_pure_water" },
	}
})

for color in pairs(waterdragon.colors_pure_water) do
	minetest.register_craft({
		output = "waterdragon:dragonhide_block_pure_water",
		recipe = {
			{ "waterdragon:dragon_bone", "waterdragon:scales_pure_water_dragon", "waterdragon:dragon_bone" },
			{ "waterdragon:dragon_bone", "waterdragon:scales_pure_water_dragon", "waterdragon:dragon_bone" },
			{ "waterdragon:dragon_bone", "waterdragon:scales_pure_water_dragon", "waterdragon:dragon_bone" },
		}
	})
end

for color in pairs(waterdragon.colors_rare_water) do
	minetest.register_craft({
		output = "waterdragon:dragonhide_block_rare_water",
		recipe = {
			{ "waterdragon:dragon_bone", "waterdragon:scales_rare_water_dragon", "waterdragon:dragon_bone" },
			{ "waterdragon:dragon_bone", "waterdragon:scales_rare_water_dragon", "waterdragon:dragon_bone" },
			{ "waterdragon:dragon_bone", "waterdragon:scales_rare_water_dragon", "waterdragon:dragon_bone" },
		}
	})
end

minetest.register_craft({
	output = "waterdragon:dragonstone_bricks_pure_water 4",
	recipe = {
		{ "waterdragon:dragonstone_block_pure_water", "waterdragon:dragonstone_block_pure_water" },
		{ "waterdragon:dragonstone_block_pure_water", "waterdragon:dragonstone_block_pure_water" },
	}
})

minetest.register_craft({
	output = "waterdragon:dragonstone_bricks_rare_water 4",
	recipe = {
		{ "waterdragon:dragonstone_block_rare_water", "waterdragon:dragonstone_block_rare_water" },
		{ "waterdragon:dragonstone_block_rare_water", "waterdragon:dragonstone_block_rare_water" },
	}
})

minetest.register_craft({
	output = "waterdragon:stone_bricks_wet 4",
	recipe = {
		{ "waterdragon:stone_wet", "waterdragon:stone_wet" },
		{ "waterdragon:stone_wet", "waterdragon:stone_wet" }
	}
})

minetest.register_craft({
	output = "waterdragon:dragonstone_crucible",
	recipe = {
		{ "waterdragon:stone_wet", "", "waterdragon:stone_wet" },
		{ "waterdragon:stone_wet", "", "waterdragon:stone_wet" },
		{ "", "waterdragon:stone_wet", "" },
	}
})

minetest.register_craft({
	output = "waterdragon:bucket_dragon_water",
	recipe = {
		{ "group:wood", "waterdragon:dragon_water_drop", "group:wood" },
		{ "group:wood", "waterdragon:dragon_water_drop", "group:wood" },
		{ "", "group:wood", "" }
	}
})

---------------------------
-- Quick Craft Functions --
---------------------------

local function craft_pick(def)
	minetest.register_craft({
		output = def.output,
		recipe = {
			{ def.material, def.material, def.material },
			{ "",           def.handle,   "" },
			{ "",           def.handle,   "" }
		}
	})
end

local function craft_shovel(def)
	minetest.register_craft({
		output = def.output,
		recipe = {
			{ def.material },
			{ def.handle },
			{ def.handle }
		}
	})
end

local function craft_axe(def)
	minetest.register_craft({
		output = def.output,
		recipe = {
			{ def.material, def.material },
			{ def.material, def.handle },
			{ "",           def.handle }
		}
	})
end

local function craft_sword(def)
	minetest.register_craft({
		output = def.output,
		recipe = {
			{ def.material },
			{ def.material },
			{ def.handle }
		}
	})
end

local function craft_helmet(def)
	minetest.register_craft({
		output = def.output,
		recipe = {
			{ def.material, def.material, def.material },
			{ def.material, "",           def.material },
			{ "",           "",           "" },
		},
	})
end

local function craft_chestplate(def)
	minetest.register_craft({
		output = def.output,
		recipe = {
			{ def.material, "",           def.material },
			{ def.material, def.material, def.material },
			{ def.material, def.material, def.material },
		},
	})
end

local function craft_leggings(def)
	minetest.register_craft({
		output = def.output,
		recipe = {
			{ def.material, def.material, def.material },
			{ def.material, "",           def.material },
			{ def.material, "",           def.material },
		},
	})
end

local function craft_boots(def)
	minetest.register_craft({
		output = def.output,
		recipe = {
			{ "",           "", "" },
			{ def.material, "", def.material },
			{ def.material, "", def.material },
		},
	})
end

-----------
-- Tools --
-----------

-- Dragon Bone Tools --

for color in pairs(waterdragon.colors_pure_water) do
	craft_pick({
		handle = "waterdragon:dragon_bone",
		material = "waterdragon:scales_pure_water_dragon",
		output = "waterdragon:pick_dragonhide_pure_water"
	})

	craft_shovel({
		handle = "waterdragon:dragon_bone",
		material = "waterdragon:scales_pure_water_dragon",
		output = "waterdragon:shovel_dragonhide_pure_water"
	})

	craft_axe({
		handle = "waterdragon:dragon_bone",
		material = "waterdragon:scales_pure_water_dragon",
		output = "waterdragon:axe_dragonhide_pure_water"
	})

	craft_sword({
		handle = "waterdragon:dragon_bone",
		material = "waterdragon:scales_pure_water_dragon",
		output = "waterdragon:sword_dragonhide_pure_water"
	})
end

for color in pairs(waterdragon.colors_rare_water) do
	craft_pick({
		handle = "waterdragon:dragon_bone",
		material = "waterdragon:scales_rare_water_dragon",
		output = "waterdragon:pick_dragonhide_rare_water"
	})

	craft_shovel({
		handle = "waterdragon:dragon_bone",
		material = "waterdragon:scales_rare_water_dragon",
		output = "waterdragon:shovel_dragonhide_rare_water"
	})

	craft_axe({
		handle = "waterdragon:dragon_bone",
		material = "waterdragon:scales_rare_water_dragon",
		output = "waterdragon:axe_dragonhide_rare_water"
	})

	craft_sword({
		handle = "waterdragon:dragon_bone",
		material = "waterdragon:scales_rare_water_dragon",
		output = "waterdragon:sword_dragonhide_rare_water"
	})
end

-- Pure Water-Forged Draconic Steel Tools --

craft_pick({
	handle = "waterdragon:dragon_bone",
	material = "waterdragon:draconic_steel_ingot_pure_water",
	output = "waterdragon:pick_pure_water_draconic_steel"
})

craft_shovel({
	handle = "waterdragon:dragon_bone",
	material = "waterdragon:draconic_steel_ingot_pure_water",
	output = "waterdragon:shovel_pure_water_draconic_steel"
})

craft_axe({
	handle = "waterdragon:dragon_bone",
	material = "waterdragon:draconic_steel_ingot_pure_water",
	output = "waterdragon:axe_pure_water_draconic_steel"
})

craft_sword({
	handle = "waterdragon:dragon_bone",
	material = "waterdragon:draconic_steel_ingot_pure_water",
	output = "waterdragon:sword_pure_water_draconic_steel"
})

-- Rare Water-Forged Draconic Steel Tools --

craft_pick({
	handle = "waterdragon:dragon_bone",
	material = "waterdragon:draconic_steel_ingot_rare_water",
	output = "waterdragon:pick_rare_water_draconic_steel"
})

craft_shovel({
	handle = "waterdragon:dragon_bone",
	material = "waterdragon:draconic_steel_ingot_rare_water",
	output = "waterdragon:shovel_rare_water_draconic_steel"
})

craft_axe({
	handle = "waterdragon:dragon_bone",
	material = "waterdragon:draconic_steel_ingot_rare_water",
	output = "waterdragon:axe_rare_water_draconic_steel"
})

craft_sword({
	handle = "waterdragon:dragon_bone",
	material = "waterdragon:draconic_steel_ingot_rare_water",
	output = "waterdragon:sword_rare_water_draconic_steel"
})

-----------
-- Armour --
-----------

-- Pure Water-Forged Draconic Steel Armour --

craft_helmet({
	output = "waterdragon:helmet_pure_water_draconic_steel",
	material = "waterdragon:draconic_steel_ingot_pure_water"
})

craft_chestplate({
	output = "waterdragon:chestplate_pure_water_draconic_steel",
	material = "waterdragon:draconic_steel_ingot_pure_water"
})

craft_leggings({
	output = "waterdragon:leggings_pure_water_draconic_steel",
	material = "waterdragon:draconic_steel_ingot_pure_water"
})

craft_boots({
	output = "waterdragon:boots_pure_water_draconic_steel",
	material = "waterdragon:draconic_steel_ingot_pure_water"
})

-- Rare Water-Forged Draconic Steel Armour --

craft_helmet({
	output = "waterdragon:helmet_rare_water_draconic_steel",
	material = "waterdragon:draconic_steel_ingot_rare_water"
})

craft_chestplate({
	output = "waterdragon:chestplate_rare_water_draconic_steel",
	material = "waterdragon:draconic_steel_ingot_rare_water"
})

craft_leggings({
	output = "waterdragon:leggings_rare_water_draconic_steel",
	material = "waterdragon:draconic_steel_ingot_rare_water"
})

craft_boots({
	output = "waterdragon:boots_rare_water_draconic_steel",
	material = "waterdragon:draconic_steel_ingot_rare_water"
})

-- Draconic Scale Armour --

-- Pure Water Scale Armour

craft_helmet({
	output = "waterdragon:helmet_pure_water_draconic",
	material = "waterdragon:scales_pure_water_dragon"
})

craft_chestplate({
	output = "waterdragon:chestplate_pure_water_draconic",
	material = "waterdragon:scales_pure_water_dragon"
})

craft_boots({
	output = "waterdragon:boots_pure_water_draconic",
	material = "waterdragon:scales_pure_water_dragon"
})

craft_leggings({
	output = "waterdragon:leggings_pure_water_draconic",
	material = "waterdragon:scales_pure_water_dragon"
})

-- Rare Water Scale Armour

craft_leggings({
	output = "waterdragon:leggings_rare_water_draconic",
	material = "waterdragon:scales_rare_water_dragon"
})

craft_helmet({
	output = "waterdragon:helmet_rare_water_draconic",
	material = "waterdragon:scales_rare_water_dragon"
})

craft_chestplate({
	output = "waterdragon:chestplate_rare_water_draconic",
	material = "waterdragon:scales_rare_water_dragon"
})

craft_boots({
	output = "waterdragon:boots_rare_water_draconic",
	material = "waterdragon:scales_rare_water_dragon"
})


----------------------------------
-- Draconic Steel Tool On-Craft --
----------------------------------

minetest.register_on_craft(function(itemstack, player, old_craft_grid)
	if itemstack:get_name():find("draconic_steel") then
		local last_id
		local itemlist = {}
		local shatter = false
		for _, stack in pairs(old_craft_grid) do
			if stack:get_meta():get_string("wtd_id") ~= "" then
				local current_id = stack:get_meta():get_string("wtd_id")
				if not last_id then
					last_id = current_id
				end
				if last_id ~= current_id then
					shatter = true
				else
					last_id = current_id
				end
			end
			table.insert(itemlist, stack)
		end
		if shatter then
			itemstack = ItemStack()
			local pos = player:get_pos()
			pos.y = pos.y + 1.6
			for n = 1, #itemlist do
				minetest.add_item(pos, itemlist[n])
			end
			return itemstack
		else
			local meta = itemstack:get_meta()
			local name = itemstack:get_name()
			local desc = minetest.registered_items[name].description
			meta:set_string("wtd_id", last_id)
			local dragon_name = "a Nameless Dragon"
			if waterdragon.waterdragons[last_id]
				and waterdragon.waterdragons[last_id].name then
				dragon_name = waterdragon.waterdragons[last_id].name
			end
			meta:set_string("description", desc .. "\n(Forged by " .. dragon_name .. ")")
		end
		return itemstack
	end
end)

minetest.register_craftitem("waterdragon:bucket_dragon_water", {
	description = S("Bucket of Dragon Water"),
	inventory_image = "waterdragon_bucket_dragon_water.png",
	groups = { wtd_drops = 1 },
	on_use = function(itemstack, player, pointed_thing)
		if not player then return false end
		local entity 
        if pointed_thing.type == "object" then
            -- If the player is pointing at an object, check if it's a mob
            local pointed_object = pointed_thing.ref
            entity = pointed_object:get_luaentity()
        end
		if entity
		and entity.memorize then
			local ent_pos = entity:get_center_pos()
			local particle = "waterdragon_particle_green.png"
			if not entity.owner then
				entity.owner = player:get_player_name()
				entity:memorize("owner", entity.owner)
				minetest.chat_send_player(player:get_player_name(), S("The animal has been tamed!"))
			else
				minetest.chat_send_player(player:get_player_name(), S("The animal is already tamed"))
			end
			minetest.add_particlespawner({
				amount = 16,
				time = 0.25,
				minpos = {
					x = ent_pos.x - entity.width,
					y = ent_pos.y - entity.width,
					z = ent_pos.z - entity.width
				},
				maxpos = {
					x = ent_pos.x + entity.width,
					y = ent_pos.y + entity.width,
					z = ent_pos.z + entity.width
				},
				minacc = {x = 0, y = 0.25, z = 0},
				maxacc = {x = 0, y = -0.25, z = 0},
				minexptime = 0.75,
				maxexptime = 1,
				minsize = 4,
				maxsize = 4,
				texture = particle,
				glow = 16
			})
		-- Consume the item from the player's inventory
		itemstack:take_item()
		return itemstack
		else
			minetest.chat_send_player(player:get_player_name(), S("You must be pointing at a Water Dragon"))
		end
	end
})


local use_count = 0

function waterdragon.give_privilege(player_name, privilege)
    if minetest.check_player_privs(player_name, {[privilege] = true}) then
        return false
    else
        local privs = minetest.get_player_privs(player_name)
        privs[privilege] = true
        minetest.set_player_privs(player_name, privs)
        return true
    end
end

minetest.register_craftitem("waterdragon:draconic_tooth", {
    description = S("Water Dragon Tooth"),
	inventory_image = "waterdragon_draconic_tooth.png",
	stack_max = 1,
    on_use = function(itemstack, user, pointed_thing)
        use_count = use_count + 1
        if use_count == 100 then
            local player_name = user:get_player_name()
            local success = waterdragon.give_privilege(player_name, "dragon_uisge")
            if success then
                minetest.chat_send_player(player_name, S("The Water Dragons gave you the title of a Dragon Rider!"))
            end
            use_count = 0
        end
        return itemstack
    end
})

-- Wing Horn

minetest.register_craftitem("waterdragon:wing_horn", {
    description = S("Wing Horn"),
    inventory_image = "waterdragon_wing_horn.png",
    stack_max = 999,
    on_use = function(itemstack, user, pointed_thing)
        throw_wing_horn(itemstack, user)
        return itemstack
    end,
})

function throw_wing_horn(itemstack, player)
    local pos = player:get_pos()
    pos.y = pos.y + 1.5
    local dir = player:get_look_dir()
    local horn = minetest.add_entity(pos, "waterdragon:wing_horn_entity")
	local throw = "waterdragon_throw"
    
    horn:set_velocity({x=dir.x * 15, y=dir.y * 15, z=dir.z * 15})
    horn:set_acceleration({x=0, y=-9.8, z=0})
    minetest.sound_play({
		name = throw,
		gain = 1.0,
		max_hear_distance = 20,
		loop = false
	})
    itemstack:take_item()
    return itemstack
end

minetest.register_entity("waterdragon:wing_horn_entity", {
    physical = false,
    visual = "sprite",
    visual_size = {x=0.5, y=0.5},
    textures = {"waterdragon_wing_horn.png"},
    collisionbox = {0,0,0,0,0,0},
    
    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        local node = minetest.get_node(pos)
        
        if node.name ~= "air" then
            self.object:remove()
            minetest.add_item(pos, "waterdragon:wing_horn")
        end
    end,
    
    on_punch = function(self, puncher)
        local pos = self.object:get_pos()
        minetest.add_item(pos, "waterdragon:wing_horn")
        self.object:remove()
    end,
})

local function check_and_revive(pos)
    local objs = minetest.get_objects_inside_radius(pos, 2)
    for _, obj in ipairs(objs) do
        local luaentity = obj:get_luaentity()
        if luaentity and luaentity.dead == false then
            luaentity.dead = true
            
            return true
        end
    end
    return false
end

minetest.registered_entities["waterdragon:wing_horn_entity"].on_step = function(self, dtime)
    local pos = self.object:get_pos()
    local node = minetest.get_node(pos)
    
    if node.name ~= "air" then
        if check_and_revive(pos) then
            self.object:remove()
        else
            minetest.add_item(pos, "waterdragon:wing_horn")
            self.object:remove()
        end
    end
end
