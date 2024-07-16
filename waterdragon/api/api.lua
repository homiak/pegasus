---------
-- API --
---------

-- Math --
local S = waterdragon.S

local pi = math.pi
local pi2 = pi * 2
local abs = math.abs
local deg = math.deg
local min = math.min
local random = math.random
local ceil = math.ceil
local floor = math.floor
local atan2 = math.atan2
local sin = math.sin
local sqrt = math.sqrt
local cos = math.cos
local rad = math.rad
local function diff(a, b) -- Get difference between 2 angles
	return atan2(sin(b - a), cos(b - a))
end
local function interp_angle(a, b, w)
	local cs = (1 - w) * cos(a) + w * cos(b)
	local sn = (1 - w) * sin(a) + w * sin(b)
	return atan2(sn, cs)
end

local function clamp(val, _min, _max)
	if val < _min then
		val = _min
	elseif _max < val then
		val = _max
	end
	return val
end

-- Vector Math --

local vec_dir = vector.direction
local vec_dist = vector.distance
local vec_sub = vector.subtract
local vec_add = vector.add
local vec_multi = vector.multiply
local vec_new = vector.new
local vec_normal = vector.normalize
local vec_round = vector.round

local dir2yaw = minetest.dir_to_yaw
local yaw2dir = minetest.yaw_to_dir

--------------
-- Settings --
--------------

local terrain_destruction = minetest.settings:get_bool("water_dragon_terrain_destruction", false)

---------------------
-- Local Utilities --
---------------------

local function activate_nametag(self)
	self.nametag = self:recall("nametag") or nil
	if not self.nametag then return end
	self.object:set_properties({
		nametag = self.nametag,
		nametag_color = "#bdd9ff"
	})
end

local function is_value_in_table(tbl, val)
	for _, v in pairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

local function correct_name(str)
	if str then
		if str:match(":") then str = str:split(":")[2] end
		return (string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("_", " "))
	end
end

local function get_pointed_mob(a, b)
	local steps = ceil(vec_dist(a, b))

	for i = 1, steps do
		local pos

		if steps > 0 then
			pos = {
				x = a.x + (b.x - a.x) * (i / steps),
				y = a.y + (b.y - a.y) * (i / steps),
				z = a.z + (b.z - a.z) * (i / steps)
			}
		else
			pos = a
		end
		if creatura.get_node_def(pos).walkable then
			break
		end
		local objects = minetest.get_objects_in_area(vec_sub(pos, 6), vec_add(pos, 6))
		for _, object in pairs(objects) do
			if object
				and object:get_luaentity() then
				local ent = object:get_luaentity()
				if ent.name:match("^waterdragon:") then
					return object, ent
				end
			end
		end
	end
end

------------------
-- Local Tables --
------------------

local walkable_nodes = {}

local wet_conversions = {}

local flame_node = {}

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_nodes) do
		if name ~= "air" and name ~= "ignore" then
			if def.walkable then
				table.insert(walkable_nodes, name)
				if minetest.get_item_group(name, "stone") > 0 then
					wet_conversions[name] = "waterdragon:stone_wet" -- Wet Stone
				elseif minetest.get_item_group(name, "soil") > 0 then
					wet_conversions[name] = "waterdragon:soil_wet" -- Wet Soil
				elseif minetest.get_item_group(name, "tree") > 0 then
					wet_conversions[name] = "waterdragon:log_wet" -- Wet Log
				elseif minetest.get_item_group(name, "flora") > 0
					or minetest.get_item_group(name, "leaves") > 0
					or minetest.get_item_group(name, "snowy") > 0 then
					wet_conversions[name] = "default:water_flowing"
				end
			elseif def.drawtype == "liquid"
				and minetest.get_item_group(name, "water") > 0 then
				wet_conversions[name] = waterdragon.global_nodes["rare_water"]
			end
		end
	end
end)

minetest.after(0.1, function()
	flame_node = waterdragon.global_nodes["flame"]
end)

local water_eye_textures = {
	"blue",
	"orange",
	"red",
	"yellow"
}


----------------------
-- Global Utilities --
----------------------

function waterdragon.spawn_dragon(pos, mob, mapgen, age)
	if not pos then return false end
	local wtd = minetest.add_entity(pos, mob)
	if wtd then
		local ent = wtd:get_luaentity()
		ent._mem = ent:memorize("_mem", true)
		ent.age = ent:memorize("age", age)
		ent.growth_scale = ent:memorize("growth_scale", age * 0.01)
		ent.mapgen_spawn = ent:memorize("mapgen_spawn", mapgen)
		if age <= 25 then
			ent.child = ent:memorize("child", true)
			ent.growth_stage = ent:memorize("growth_stage", 1)
		end
		if age <= 50 then
			ent.growth_stage = ent:memorize("growth_stage", 2)
		end
		if age <= 75 then
			ent.growth_stage = ent:memorize("growth_stage", 3)
		end
		if age > 75 then
			ent.growth_stage = ent:memorize("growth_stage", 4)
		end
		if random(3) < 2 then
			ent.gender = ent:memorize("gender", "male")
		else
			ent.gender = ent:memorize("gender", "female")
		end
		ent:set_scale(ent.growth_scale)
	end
end

function waterdragon.generate_id()
	local idst = ""
	for _ = 0, 5 do idst = idst .. (random(0, 9)) end
	if waterdragon.waterdragons[idst] then
		local fail_safe = 20
		while waterdragon.waterdragons[idst]
			and fail_safe > 0 do
			for _ = 0, 5 do idst = idst .. (random(0, 9)) end
			fail_safe = fail_safe - 1
		end
	end
	return idst
end

-------------------
-- Mob Functions --
-------------------

local function get_head_pos(self, pos2)
	local pos = self.object:get_pos()
	if not pos then return end
	local scale = self.growth_scale or 1
	pos.y = pos.y + 4.5 * scale
	local yaw = self.object:get_yaw()
	local dir = vec_dir(pos, pos2)
	local yaw_diff = diff(yaw, minetest.dir_to_yaw(dir))
	if yaw_diff > 1 then
		local look_dir = minetest.yaw_to_dir(yaw + 1)
		dir.x = look_dir.x
		dir.z = look_dir.z
	elseif yaw_diff < -1 then
		local look_dir = minetest.yaw_to_dir(yaw - 1)
		dir.x = look_dir.x
		dir.z = look_dir.z
	end
	local head_yaw = yaw + (yaw_diff * 0.33)
	return vec_add(pos, vec_multi(minetest.yaw_to_dir(head_yaw), (7 - abs(yaw_diff)) * scale)), dir
end

waterdragon.get_head_pos = get_head_pos

local wing_colors = {
	-- Pure Water
	pure_water = {
		"#d20000", -- Red
		"#d92e00", -- Orange
		"#edad00", -- Yellow
		"#07084f", -- Dark Blue
		"#2deded" -- Cyan
	},
	-- Rare Water
	rare_water = {
		"#d20000", -- Red
		"#d92e00", -- Orange
		"#edad00", -- Yellow
		"#07084f", -- Dark Blue
		"#2deded" -- Cyan
	},
}

local function generate_texture(self, force)
	waterdragon.set_color_string(self)
	local def = minetest.registered_entities[self.name]
	local textures = {
		def.textures[self.texture_no]
	}
	self.wing_overlay = self:recall("wing_overlay") or nil
	if not self.wing_overlay then
		local color = wing_colors[self.color][random(#wing_colors[self.color])]
		self.wing_overlay = "(waterdragon_wing_fade.png^[multiply:" .. color .. ")"
		self:memorize("wing_overlay", self.wing_overlay)
	end
	if self:get_props().textures[1]:find("wing_fade") and not force then return end
	textures[1] = textures[1] .. "^" .. self.wing_overlay
	self:set_texture(1, textures)
end

waterdragon.generate_texture = generate_texture

function waterdragon.drop_items(self)
	if not creatura.is_valid(self)
		or not self.object:get_pos() then
		return
	end
	if not self.drop_queue then
		self.drop_queue = {}
		for i = 1, #self.drops do
			local drop_def = self.drops[i]
			local name = drop_def.name
			local min_amount = drop_def.min
			local max_amount = drop_def.max
			local chance = drop_def.chance
			local amount = random(min_amount, max_amount)
			if random(chance) < 2 then
				table.insert(self.drop_queue, { name = name, amount = amount })
			end
		end
		self:memorize("drop_queue", self.drop_queue)
	else
		local pos = self.object:get_pos()
		pos.y = pos.y + self.height * 0.5
		local minpos = {
			x = pos.x - 18 * self.growth_scale,
			y = pos.y,
			z = pos.z - 18 * self.growth_scale
		}
		local maxpos = {
			x = pos.x + 18 * self.growth_scale,
			y = pos.y,
			z = pos.z + 18 * self.growth_scale
		}
		minetest.add_particlespawner({
			amount = math.ceil(48 * self.growth_scale),
			time = 0.25,
			minpos = minpos,
			maxpos = maxpos,
			minacc = { x = 0, y = 2, z = 0 },
			maxacc = { x = 0, y = 3, z = 0 },
			minvel = { x = math.random(-1, 1), y = -0.25, z = math.random(-1, 1) },
			maxvel = { x = math.random(-2, 2), y = -0.25, z = math.random(-2, 2) },
			minexptime = 0.75,
			maxexptime = 1,
			minsize = 4,
			maxsize = 4,
			texture = "waterdragon_smoke_particle.png",
			animation = {
				type = 'vertical_frames',
				aspect_w = 4,
				aspect_h = 4,
				length = 1,
			},
			glow = 1
		})
		if #self.drop_queue > 0 then
			for i = #self.drop_queue, 1, -1 do
				local drop_def = self.drop_queue[i]
				if drop_def then
					local name = drop_def.name
					local amount = random(1, drop_def.amount)
					local item = minetest.add_item(pos, ItemStack(name .. " " .. amount))
					if item then
						item:add_velocity({
							x = random(-2, 2),
							y = 1.5,
							z = random(-2, 2)
						})
					end
					self.drop_queue[i].amount = drop_def.amount - amount
					if self.drop_queue[i].amount <= 0 then
						self.drop_queue[i] = nil
					end
				end
			end
			self:memorize("drop_queue", self.drop_queue)
		else
			return true
		end
	end
	return false
end

-------------
-- Visuals --
-------------

function waterdragon.set_color_string(self)
	if self.name == "waterdragon:pure_water_dragon" then
		if self.texture_no == 1 then
			self.color = "pure_water"
		end
	elseif self.name == "waterdragon:rare_water_dragon" then
		if self.texture_no == 1 then
			self.color = "rare_water"
		end
	end
end

-----------------------
-- Dynamic Animation --
-----------------------

function waterdragon.rotate_to_pitch(self, flying)
	local rot = self.object:get_rotation()
	if flying then
		local vel = vec_normal(self.object:get_velocity())
		local step = min(self.dtime * 4, abs(diff(rot.x, vel.y)) % (pi2))
		local n_rot = interp_angle(rot.x, vel.y, step)
		self.object:set_rotation({
			x = clamp(n_rot, -0.75, 0.75),
			y = rot.y,
			z = rot.z
		})
	elseif rot.x ~= 0 then
		self.object:set_rotation({
			x = 0,
			y = rot.y,
			z = 0
		})
	end
end

function waterdragon.head_tracking(self)
	if self.rider then return end
	local yaw = self.object:get_yaw()
	local pos = self.object:get_pos()
	if not pos then return end
	local anim = self._anim or "stand"
	if anim == "sleep"
		or self.hp <= 0 then
		self:move_head(yaw)
		return
	end
	-- Calculate Head Position
	local y_dir = yaw2dir(yaw)
	local scale = self.growth_scale or 1
	local offset_h, offset_v = self.width + 3 * scale, self.height + 1.5 * scale
	if anim:match("^fly_idle") then
		offset_v = self.height + 2 * scale
	end
	pos = {
		x = pos.x + y_dir.x * offset_h,
		y = pos.y + offset_v,
		z = pos.z + y_dir.z * offset_h
	}
	local player = self.head_tracking
	local plyr_pos = player and player:get_pos()
	if plyr_pos then
		plyr_pos.y = plyr_pos.y + 1.4
		local dir = vec_dir(pos, plyr_pos)
		local dist = vec_dist(pos, plyr_pos)
		if dist > 24 * scale then
			self.head_tracking = nil
			return
		end
		local tyaw = dir2yaw(dir)
		self:move_head(tyaw, dir.y)
		return
	elseif self:timer(random(4, 6)) then
		local players = creatura.get_nearby_players(self, 12 * scale)
		self.head_tracking = #players > 0 and players[random(#players)]
	end
	self:move_head(yaw, 0)
end

------------
-- Breath --
------------

local effect_cooldown = {}

minetest.register_entity("waterdragon:dragon_rare_water", {
	max_hp = 1600,
	physical = true,
	collisionbox = { -0.1, -0.1, -0.1, 0.1, 0.1, 0.1 },
	visual = "mesh",
	mesh = "waterdragon_dragon_water.obj",
	textures = {
		"waterdragon_dragon_rare_water.png^[opacity:170"
	},
	use_texture_alpha = true,
	active_time = 0,
	on_activate = function(self)
		self.object:set_armor_groups({ immortal = 1, fleshy = 0 })
		self.object:set_acceleration({ x = 0, y = -9.8, z = 0 })
	end,
	on_step = function(self, dtime)
		if self.active_time > 0
			and (not self.child
				or not self.child:get_pos()) then
			self.object:remove()
			return
		end
		self.active_time = self.active_time + dtime
		if self.active_time > 10 then
			if self.child then
				self.child:set_properties({
					visual_size = self.mob_scale,
				})
			end
			self.object:remove()
		end
	end
})

minetest.register_entity("waterdragon:dragon_pure_water", {
	max_hp = 1500,
	physical = false,
	collisionbox = { -0.1, -0.1, -0.1, 0.1, 0.1, 0.1 },
	visual = "mesh",
	mesh = "waterdragon_dragon_pure_water.obj",
	textures = {
		"waterdragon_pure_water_animated.png^[verticalframe:8:1"
	},
	glow = 12,
	active_time = 0,
	pure_water_time = 0.07,
	pure_water_frame = 1,
	on_activate = function(self)
		self.object:set_armor_groups({ immortal = 1, fleshy = 0 })
	end,
	on_step = function(self, dtime)
		if not self.child
			or not self.child:get_pos() then
			self.object:remove()
			return
		end
		local child_pos = self.child:get_pos()
		if creatura.get_node_def(child_pos).drawtype == "liquid" then
			self.object:remove()
			return
		end
		self.active_time = self.active_time + dtime
		self.pure_water_time = self.pure_water_time - dtime
		if self.pure_water_time < 0 then
			self.pure_water_time = 0.07
			self.pure_water_frame = self.pure_water_frame + 1
			if self.pure_water_frame > 6 then
				self.pure_water_frame = 1
			end
		end
		if self.active_time - math.floor(self.active_time) < 0.1
			and (self.child:get_luaentity()
				or self.child:is_player()) then
			local ent = self.child:get_luaentity()
			if ((ent and ent.hp) or 0) > 0 then
				self.child:punch(self.object, 0, { fleshy = 2 })
			end
			if ent
				and ent._creatura_mob
				and ((ent and ent.hp) or 0) <= 0
				and ent.drops then
				if #ent.drops
					and #ent.drops > 0 then
					local n_drops = table.copy(ent.drops)
					for n = 1, #n_drops do
						local name = n_drops[n].name
						if minetest.get_item_group(name, "food_meat") > 0 then
							local output = minetest.get_craft_result({
								method = "cooking",
								width = 1,
								items = { name }
							})
							if output.item
								and output.item:get_name()
								and output.item:get_name() ~= "" then
								local cooked_name = output.item:get_name()
								n_drops[n].name = cooked_name
							end
						end
					end
					self.child:get_luaentity().drops = n_drops
				end
			end
		end
		if self.active_time > 10 then
			self.object:remove()
		end
	end
})


local function do_cooldown()
	for k, v in pairs(effect_cooldown) do
		if v > 1 then
			effect_cooldown[k] = v - 1
		else
			effect_cooldown[k] = nil
		end
	end
	minetest.after(1, do_cooldown)
end

do_cooldown()

local function damage_objects(self, pos, radius)
	local objects = minetest.get_objects_inside_radius(pos, radius)
	for _, object in ipairs(objects) do
		local ent = object and object:get_luaentity()
		local damage = object:is_player()
		if (self.rider and object == self.rider)
			or (self.passenger and object == self.passenger) then
			damage = false
		elseif ent then
			local is_mob = ent.logic ~= nil or ent._creatura_mob or ent._cmi_is_mob
			damage = is_mob and (ent.hp or ent.health or 0) > 0
		end
		if damage then
			object:punch(self.object, 1.0, { damage_groups = { fleshy = math.ceil(self.damage * 0.33) } })
			self:punch_target(object, math.ceil(self.damage * 0.2))
		end
		if ent and ent.name == "__builtin:item" then
			local stack = ItemStack(ent.itemstring)
			if stack
				and stack:get_count() > 98
				and stack:get_name():match("stone")
				and minetest.get_item_group(stack:get_name(), "cracky") > 0 then
				local dragonstone_no = floor(stack:get_count() / 99)
				local leftover_no = stack:get_count() - 99 * dragonstone_no
				if self.name == "waterdragon:rare_water_dragon" then
					minetest.add_item(object:get_pos(), "waterdragon:dragonstone_block_rare_water " .. dragonstone_no)
				end
				if self.name == "waterdragon:pure_water_dragon" then
					minetest.add_item(object:get_pos(), "waterdragon:dragonstone_block_pure_water " .. dragonstone_no)
				end
				if leftover_no then
					minetest.add_item(object:get_pos(), stack:get_name() .. " " .. leftover_no)
				end
				object:remove()
			end
		end
	end
end

local function make_wet_nodes(pos, radius)
	local h_stride = radius
	local v_stride = math.ceil(radius * 0.5)
	local pos1 = {
		x = pos.x - h_stride,
		y = pos.y - v_stride,
		z = pos.z - h_stride
	}
	local pos2 = {
		x = pos.x + h_stride,
		y = pos.y + v_stride,
		z = pos.z + h_stride
	}
	local y_stride = 0
	for z = pos1.z, pos2.z do
		y_stride = y_stride + 1
		for x = pos1.x, pos2.x do
			local noise = random(5)
			if noise < 2 then
				local npos = {
					x = x,
					y = pos1.y + y_stride,
					z = z
				}
				if minetest.is_protected(npos, "") then
					return
				end
				local name = minetest.get_node(npos).name
				if name
					and not name:find("wet")
					and name ~= "air"
					and name ~= "ignore" then
					local convert_to = wet_conversions[name]
					if convert_to
						and (convert_to ~= waterdragon.global_nodes["rare_water"]
							or minetest.get_node({ x = x, y = npos.y + 1, z = z }).name == "air") then
						minetest.set_node(npos, { name = convert_to })
					end
				end
			end
		end
	end
end

local function make_nodes_wet_pure_water(pos, radius)
	local h_stride = radius
	local v_stride = math.ceil(radius * 0.5)
	local pos1 = {
		x = pos.x - h_stride,
		y = pos.y - v_stride,
		z = pos.z - h_stride
	}
	local pos2 = {
		x = pos.x + h_stride,
		y = pos.y + v_stride,
		z = pos.z + h_stride
	}
	local y_stride = 0
	for z = pos1.z, pos2.z do
		y_stride = y_stride + 1
		for x = pos1.x, pos2.x do
			local noise = random(5)
			if noise < 2 then
				local npos = {
					x = x,
					y = pos1.y + y_stride,
					z = z
				}
				if minetest.is_protected(npos, "") then
					return
				end
				local name = minetest.get_node(npos).name
				if name
					and not name:find("wet")
					and name ~= "air"
					and name ~= "ignore" then
					local convert_to = wet_conversions[name]
					if convert_to
						and (convert_to ~= waterdragon.global_nodes["pure_water"]
							or minetest.get_node({ x = x, y = npos.y + 1, z = z }).name == "air") then
						minetest.set_node(npos, { name = convert_to })
					end
				end
			end
		end
	end
end

local function do_forge(pos, node, id)
	local forge = minetest.find_nodes_in_area(vec_sub(pos, 4), vec_add(pos, 4), node)
	if forge[1] then
		local func = minetest.registered_nodes[node].on_breath
		func(forge[1], id)
	end
end

local function breath_sound(self, sound)
	self.breath_timer = (self.breath_timer or 0.1) - self.dtime
	if self.breath_timer <= 0 then
		self.breath_timer = 2
		minetest.sound_play(sound, {
			object = self.object,
			gain = 1.0,
			max_hear_distance = 64,
			loop = false,
		})
	end
end

function waterdragon.pure_water_breath(self, pos2)
	if self.attack_stamina <= 0 then
		self.attack_disabled = true
		self:memorize("attack_disabled", self.attack_disabled)
		return
	elseif self.attack_stamina > 25
		and self.attack_disabled then
		self.attack_disabled = false
		self:memorize("attack_disabled", self.attack_disabled)
	end
	breath_sound(self, "waterdragon_water_breath")
	local pos, dir = get_head_pos(self, pos2)
	dir.y = vec_dir(pos, pos2).y
	pos.y = pos.y + self.object:get_rotation().x
	local breath_delay = (self.breath_delay or 0) - 1
	if breath_delay <= 0 then
		local vel = self.object:get_velocity()
		local particle_origin = {
			x = pos.x + vel.x * 0.25,
			y = pos.y + vel.y * 0.25,
			z = pos.z + vel.z * 0.25
		}
		local scale = self.growth_scale
		if minetest.has_feature("particlespawner_tweenable") then
			minetest.add_particlespawner({
				amount = 200,
				time = 0.05,
				collisiondetection = true,
				collision_removal = true,
				pos = particle_origin,
				vel = { min = vec_multi(dir, 32), max = vec_multi(dir, 48) },
				acc = { min = vec_new(-4, -4, -4), max = vec_new(4, 4, 4) },
				size = { min = 8 * scale, max = 12 * scale },
				glow = 16,
				texture = {
					name = "waterdragon_water_particle.png",
					alpha_tween = { 0.75, 0.25 },
					blend = "alpha"
				}
			})
		else
			minetest.add_particlespawner({
				amount = 200,
				time = 0.05,
				minpos = particle_origin,
				maxpos = particle_origin,
				minvel = vec_multi(dir, 32),
				maxvel = vec_multi(dir, 48),
				minacc = { x = -4, y = -4, z = -4 },
				maxacc = { x = 4, y = 4, z = 4 },
				minexptime = 0.02 * 32,
				maxexptime = 0.04 * 32,
				minsize = 8 * scale,
				maxsize = 12 * scale,
				collisiondetection = true,
				collision_removal = true,
				vertical = false,
				glow = 16,
				texture = "waterdragon_water_particle.png"
			})
		end
		local spread = clamp(3 * scale, 1, 5)
		local breath_end = vec_add(pos, vec_multi(dir, 32))
		for i = 1, 32, floor(spread) do
			local pure_water_pos = vec_add(pos, vec_multi(dir, i))
			if random(5) < 2 then
				damage_objects(self, pure_water_pos, spread + 2)
			end
			local def = creatura.get_node_def(pure_water_pos)
			if def.walkable
				or def.drawtype == "liquid" then
				breath_end = pure_water_pos
				break
			end
		end
		do_forge(breath_end, "waterdragon:draconic_forge_pure_water", self.wtd_id)
		breath_delay = 4
	end
	self.breath_delay = breath_delay
	if self.owner then
		self.attack_stamina = self.attack_stamina - self.dtime * 4
	end
	self:memorize("attack_stamina", self.attack_stamina)
end

function waterdragon.rare_water_breath(self, pos2)
	if self.attack_stamina <= 0 then
		self.attack_disabled = true
		self:memorize("attack_disabled", self.attack_disabled)
		return
	elseif self.attack_stamina > 25
		and self.attack_disabled then
		self.attack_disabled = false
		self:memorize("attack_disabled", self.attack_disabled)
	end
	breath_sound(self, "waterdragon_water_breath")
	local pos, dir = get_head_pos(self, pos2)
	dir.y = vec_dir(pos, pos2).y
	pos.y = pos.y + self.object:get_rotation().x
	local breath_delay = (self.breath_delay or 0) - 1
	if breath_delay <= 0 then
		local vel = self.object:get_velocity()
		local particle_origin2 = {
			x = pos.x + vel.x * 0.25,
			y = pos.y + vel.y * 0.25,
			z = pos.z + vel.z * 0.25
		}
		local scale = self.growth_scale
		if minetest.has_feature("particlespawner_tweenable") then
			minetest.add_particlespawner({
				amount = 200,
				time = 0.0005,
				collisiondetection = true,
				collision_removal = true,
				pos = particle_origin2,
				vel = { min = vec_multi(dir, 32), max = vec_multi(dir, 48) },
				acc = { min = vec_new(-4, -4, -4), max = vec_new(4, 4, 4) },
				size = { min = 6 * scale, max = 8 * scale },
				glow = 16,
				texpool = {
					{ name = "waterdragon_rare_water_particle_1.png", alpha_tween = { 1, 0 }, blend = "alpha" },
					{ name = "waterdragon_rare_water_particle_2.png", alpha_tween = { 1, 0 }, blend = "alpha" },
					{ name = "waterdragon_rare_water_particle_3.png", alpha_tween = { 1, 0 }, blend = "alpha" },
				}
			})
		else
			minetest.add_particlespawner({
				amount = 200,
				time = 0.0005,
				minpos = particle_origin2,
				maxpos = particle_origin2,
				minvel = vec_multi(dir, 32),
				maxvel = vec_multi(dir, 48),
				minacc = { x = -4, y = -4, z = -4 },
				maxacc = { x = 4, y = 4, z = 4 },
				minexptime = 0.02 * 32,
				maxexptime = 0.04 * 32,
				minsize = 4 * scale,
				maxsize = 6 * scale,
				collisiondetection = true,
				collision_removal = true,
				vertical = false,
				glow = 16,
				texture = "waterdragon_rare_water_particle_" .. random(3) .. ".png"
			})
		end
		local spread = floor(clamp(2.5 * scale, 1, 4))
		local breath_end = vec_add(pos, vec_multi(dir, 32))
		for i = 1, 32, spread do
			local rare_water_pos = vec_add(pos, vec_multi(dir, i))
			make_wet_nodes(rare_water_pos, spread)
			if random(5) < 2 then
				damage_objects(self, rare_water_pos, spread + 2)
			end
			local pure_water_pos = vec_add(pos, vec_multi(dir, i))
			make_nodes_wet_pure_water(pure_water_pos, spread)
			if random(5) < 2 then
				damage_objects(self, pure_water_pos, spread + 2)
			end
			local def = creatura.get_node_def(pure_water_pos)
			if def.walkable then
				breath_end = pure_water_pos
				break
			end
			local def = creatura.get_node_def(rare_water_pos)
			if def.walkable then
				breath_end = rare_water_pos
				break
			end
		end
		do_forge(breath_end, "waterdragon:draconic_forge_rare_water", self.wtd_id)
		breath_delay = 4
	end
	self.breath_delay = breath_delay
	if self.owner then
		self.attack_stamina = self.attack_stamina - self.dtime * 4
	end
	self:memorize("attack_stamina", self.attack_stamina)
end

--------------------
-- Initialize API --
--------------------


waterdragon.dragon_api = {
	action_flight_to_land = function(self)
	minetest.log("action", "fly to land action")
        if not self:get_action() then
            creatura.action_move(self, self.object:get_pos(), 3, "waterdragon:fly_to_land", 0.6, "fly")
			minetest.log("action", "fly to landaction")
        end
        if self.touching_ground then
			minetest.log("action", "touching ground")
            waterdragon.action_land(self)
            return true
        end
        return false
    end,
	animate = function(self, anim)
		if self.animations and self.animations[anim] then
			if self._anim == anim then return end
			local old_anim = nil
			if self._anim then
				old_anim = self._anim
			end
			self._anim = anim
			local old_prty = 1
			if old_anim
				and self.animations[old_anim].prty then
				old_prty = self.animations[old_anim].prty
			end
			local prty = 1
			if self.animations[anim].prty then
				prty = self.animations[anim].prty
			end
			local aparms
			if #self.animations[anim] > 0 then
				aparms = self.animations[anim][random(#self.animations[anim])]
			else
				aparms = self.animations[anim]
			end
			aparms.frame_blend = aparms.frame_blend or 0
			if old_prty > prty then
				aparms.frame_blend = self.animations[old_anim].frame_blend or 0
			end
			self.anim_frame = -aparms.frame_blend
			self.frame_offset = 0
			self.object:set_animation(aparms.range, aparms.speed, aparms.frame_blend, aparms.loop)
		else
			self._anim = nil
		end
	end,
	increase_age = function(self)
		self.age = self:memorize("age", self.age + 1)
		local age = self.age
		if age < 150
			or (age > 150
				and age < 1.5) then -- second check ensures pre-1.2 Water Dragons grow to new limit
			self.growth_scale = self:memorize("growth_scale", self.growth_scale + 0.0099)
			self:set_scale(self.growth_scale)
			if age <= 25 then
				self.growth_stage = 1
			elseif age <= 50 then
				self.growth_stage = 2
			elseif age <= 75 then
				self.growth_stage = 3
			elseif age <= 100 then
				self.growth_stage = 4
			elseif age <= 500 then
				self.growth_stage = 5
			end
		end
		self:memorize("growth_stage", self.growth_stage)
		self:set_drops()
	end,
	do_growth = function(self)
		self.growth_timer = self.growth_timer - 1
		if self.growth_timer <= 0 then
			self:increase_age()
			self.growth_timer = self.growth_timer + 1200
		end
		if self.hp > self.max_health * self.growth_scale then
			self.hp = self.max_health * self.growth_scale
		end
		if self.hunger > (self.max_health * 0.5) * self.growth_scale then
			self.hunger = (self.max_health * 0.5) * self.growth_scale
		end
		self:memorize("growth_timer", self.growth_timer)
		self:memorize("hunger", self.hunger)
	end,
	set_drops = function(self)
		local type = "rare_water"
		if self.name == "waterdragon:pure_water_dragon" then
			type = "pure_water"
		end
		waterdragon.set_color_string(self)
		local stage = self.growth_stage
		local drops = {
			[1] = {
				{ name = "waterdragon:scales_" .. type .. "_dragon", min = 1, max = 3, chance = 2 },
				{ name = "waterdragon:dragon_horn", min = 3, max = 6,  chance = 1 },
				{ name = "waterdragon:dragon_bone", min = 1, max = 3, chance = 2 },
			},
			[2] = {
				{ name = "waterdragon:scales_" .. type .. "_dragon", min = 5, max = 16, chance = 2 },
				{ name = "waterdragon:dragon_bone", min = 1, max = 3,  chance = 3 },
				{ name = "waterdragon:dragon_horn", min = 3, max = 6,  chance = 1 },
				{ name = "waterdragon:draconic_tooth", min = 3, max = 6,  chance = 1 },
				{ name = "waterdragon:dragon_water_drop", min = 1, max = 3, chance = 2 },
			},
			[3] = {
				{ name = "waterdragon:scales_" .. type .. "_dragon", min = 5, max = 16, chance = 1 },
				{ name = "waterdragon:dragon_horn", min = 3, max = 6,  chance = 1 },
				{ name = "waterdragon:dragon_bone", min = 3, max = 8,  chance = 1 },
				{ name = "waterdragon:draconic_tooth", min = 3, max = 6,  chance = 1 },
				{ name = "waterdragon:dragon_water_drop", min = 1, max = 3, chance = 2 },
			},
			[4] = {
				{ name = "waterdragon:scales_" .. type .. "_dragon", min = 5, max = 16, chance = 1 },
				{ name = "waterdragon:dragon_bone", min = 6,  max = 10, chance = 1 },
				{ name = "waterdragon:dragon_horn", min = 3, max = 6,  chance = 1 },
				{ name = "waterdragon:draconic_tooth", min = 3, max = 6,  chance = 1 },
				{ name = "waterdragon:dragon_water_drop", min = 1, max = 3, chance = 2 },
			},
			[5] = {
				{ name = "waterdragon:dragon_water_drop", min = 1, max = 3, chance = 2 },
				{ name = "waterdragon:dragon_horn", min = 3, max = 6,  chance = 1 },
				{ name = "waterdragon:draconic_tooth", min = 3, max = 6,  chance = 1 },
				{ name = "waterdragon:dragon_bone", min = 3, max = 6,  chance = 1 },
				{ name = "waterdragon:scales_" .. type .. "_dragon", min = 5, max = 16, chance = 1 },
			},
		}
		self.drops = drops[stage]
	end,
	play_sound = function(self, sound)
		if self.time_from_last_sound < 6 then return end
		local sounds = self.sounds
		if self.age < 15 then
			sounds = self.child_sounds
		end
		local spec = sounds and sounds[sound]
		local parameters = { object = self.object }
		if type(spec) == "table" then
			local name = spec.name
			if spec.variations then
				name = name .. "_" .. random(spec.variations)
			elseif #spec
				and #spec > 1 then
				spec = sounds[sound][random(#sounds[sound])]
				name = spec.name
			end
			local pitch = 1.0
			pitch = pitch - (random(-10, 10) * 0.005)
			parameters.gain = spec.gain or 1
			parameters.max_hear_distance = spec.distance or 8
			parameters.fade = spec.fade or 4
			parameters.pitch = pitch
			self.roar_anim_length = parameters.length or 500
			self.time_from_last_sound = 0
			self.jaw_init = true
			return minetest.sound_play(name, parameters)
		end
		return minetest.sound_play(spec, parameters)
	end,
	destroy_terrain = function(self)
		local moveresult = self.moveresult
		if not terrain_destruction
			or not moveresult
			or not moveresult.collisions then
			return
		end
		local pos = self.object:get_pos()
		if not pos then return end
		for _, collision in ipairs(moveresult.collisions) do
			if collision.type == "node" then
				local n_pos = collision.node_pos
				if n_pos.y - pos.y >= 1.5 then
					local node = minetest.get_node(n_pos)
					if minetest.get_item_group(node.name, "cracky") ~= 1
						and minetest.get_item_group(node.name, "unbreakable") < 1 then
						if random(6) < 2 then
							minetest.dig_node(n_pos)
						else
							minetest.remove_node(n_pos)
						end
					end
				end
			end
		end
	end,
	-- Textures
	update_emission = function(self, force)
		local pos = self.object:get_pos()
		local level = minetest.get_node_light(pos, minetest.get_timeofday())
		if not level then return end
		local texture = self:get_props().textures[1]
		local eyes_open = string.find(texture, "eyes")
		if self._glow_level == level
			and ((self._anim ~= "sleep" and eyes_open)
				or (self._anim == "sleep" and not eyes_open))
			and not force then
			return
		end
		local def = minetest.registered_entities[self.name]
		local textures = {
			def.textures[self.texture_no]
		}
		texture = textures[1]
		if self.wing_overlay then
			texture = texture .. "^" .. self.wing_overlay
		end
		self._glow_level = level
		local color = math.ceil(level / minetest.LIGHT_MAX * 255)
		if color > 255 then
			color = 255
		end
		local modifier = ("^[multiply:#%02X%02X%02X"):format(color, color, color)
		local dragon_type = "rare_water"
		if self.name == "waterdragon:pure_water_dragon" then
			dragon_type = "pure_water"
		end
		local eyes = "waterdragon_" .. dragon_type .. "_eyes_" .. self.eye_color .. ".png"
		if self.growth_scale < 0.25 then
			eyes = "waterdragon_" .. dragon_type .. "_eyes_child_" .. self.eye_color .. ".png"
		end
		if self._anim == "sleep" then
			self.object:set_properties({
				textures = { "(" .. texture .. modifier .. ")" }
			})
		else
			self.object:set_properties({
				textures = { "(" .. texture .. modifier .. ")^" .. eyes }
			})
		end
	end,
	-- Dynamic Animation Methods
	tilt_to = function(self, tyaw, rate)
		self._tyaw = tyaw
		rate = self.dtime * (rate or 5)
		local rot = self.object:get_rotation()
		if not rot then return end
		-- Calc Yaw
		local yaw = rot.y
		local y_step = math.min(rate, abs(diff(yaw, tyaw)) % (pi2))
		local n_yaw = interp_angle(yaw, tyaw, y_step)
		-- Calc Roll
		local roll = diff(tyaw, yaw) / 2
		local r_step = math.min(rate, abs(diff(rot.z, tyaw)) % (pi2))
		local n_roll = interp_angle(rot.z, roll, r_step)
		self.object:set_rotation({ x = rot.x, y = n_yaw, z = n_roll })
	end,
	set_weighted_velocity = function(self, speed, goal)
		self._tyaw = dir2yaw(goal)
		speed = speed or self._movement_data.speed
		local current_vel = self.object:get_velocity()
		local goal_vel = vec_multi(vec_normal(goal), speed)
		local vel = current_vel
		vel.x = vel.x + (goal_vel.x - vel.x) * 0.05
		vel.y = vel.y + (goal_vel.y - vel.y) * 0.05
		vel.z = vel.z + (goal_vel.z - vel.z) * 0.05
		self.object:set_velocity(vel)
	end,
	open_jaw = function(self)
		if not self._anim then return end
		local _, rot = self.object:get_bone_position("Jaw.CTRL")
		local tgt_angle
		local open_angle = pi / 4
		if self.jaw_init then
			local end_anim = self._anim:find("pure_water") or floor(rot.x) == deg(-open_angle)
			if end_anim
				or self.roar_anim_length <= 0 then
				self.jaw_init = false
				self.roar_anim_length = 0
				local step = math.min(self.dtime * 5, abs(diff(rad(rot.x), 0)) % (pi2))
				tgt_angle = interp_angle(rad(rot.x), 0, step)
			else
				local step = math.min(self.dtime * 5, abs(diff(rad(rot.x), -open_angle)) % (pi2))
				tgt_angle = interp_angle(rad(rot.x), -open_angle, step)
				self.roar_anim_length = self.roar_anim_length - self.dtime
			end
		else
			local step = math.min(self.dtime * 5, abs(diff(rad(rot.x), 0)) % (pi2))
			tgt_angle = interp_angle(rad(rot.x), 0, step)
		end
		if tgt_angle < -45 then tgt_angle = -45 end
		if tgt_angle > 0 then tgt_angle = 0 end
		self.object:set_bone_position("Jaw.CTRL", { x = 0, y = 0.15, z = -0.29 }, { x = deg(tgt_angle), y = 0, z = 0 })
	end,
	move_tail = function(self)
		if self._anim == "stand"
			or self._anim == "stand_water" then
			self.last_yaw = self.object:get_yaw()
		end
		local anim_data = self.dynamic_anim_data
		local yaw = self.object:get_yaw()
		for seg = 1, #anim_data.tail do
			local data = anim_data.tail[seg]
			local _, rot = self.object:get_bone_position("Tail." .. seg .. ".CTRL")
			rot = rot.z
			local y_diff = diff(yaw, self.last_yaw)
			local tgt_rot = -y_diff * 10
			if self.dtime then
				tgt_rot = clamp(tgt_rot, -0.3, 0.3)
				if abs(y_diff) < 0.01 then
					y_diff = rad(rot)
					tgt_rot = 0
				end
				rot = interp_angle(rad(rot), tgt_rot, math.min(self.dtime * 3, abs(y_diff * 10) % (pi2)))
			end
			self.object:set_bone_position("Tail." .. seg .. ".CTRL", data.pos,
				{ x = data.rot.x, y = data.rot.y, z = math.deg(rot) * (data.rot.z or 1) })
		end
	end,
	move_head = function(self, tyaw, pitch)
		local yaw = self.object:get_yaw()
		local seg_no = #self.dynamic_anim_data.head
		for seg = 1, seg_no do
			-- Data
			local data = self.dynamic_anim_data.head[seg]
			local bone_name = "Neck." .. seg .. ".CTRL"
			if seg == seg_no then
				bone_name = "Head.CTRL"
			end
			if not data then return end
			-- Calculation
			local _, rot = self.object:get_bone_position(bone_name)
			if not rot then return end
			local y_diff = diff(tyaw, yaw)
			local n_yaw = (tyaw ~= yaw and y_diff / 6) or 0
			if abs(deg(n_yaw)) > 22 then n_yaw = 0 end
			local dir = yaw2dir(n_yaw)
			dir.y = pitch or 0
			local n_pitch = -(sqrt(dir.x ^ 2 + dir.y ^ 2) / dir.z) / 4
			if abs(deg(n_pitch)) > 22 then n_pitch = 0 end
			if self.dtime then
				local rate = self.dtime * 3
				if abs(y_diff) < 0.01 then
					y_diff = rad(rot.z)
					n_yaw = 0
				end
				local yaw_w = math.min(rate, abs(y_diff) % (pi2))
				n_yaw = interp_angle(rad(rot.z), n_yaw, yaw_w)
				local pitch_w = math.min(rate, abs(diff(rad(rot.x), n_pitch)) % (pi2))
				n_pitch = interp_angle(rad(rot.x), n_pitch, pitch_w)
			end
			self.object:set_bone_position(bone_name, data.pos, { x = deg(n_pitch), y = data.rot.y, z = deg(n_yaw) })
		end
	end,
	feed = function(self, player)
		local name = player:get_player_name()
		if not self.owner
			or self.owner ~= name then
			return
		end
		local item, item_name = self:follow_wielded_item(player)
		if item_name then
			if not minetest.is_creative_enabled(player) then
				item:take_item()
				player:set_wielded_item(item)
			end
			if minetest.is_creative_enabled(player) then
				item:take_item()
				player:set_wielded_item(item)
			end
			local scale = self.growth_scale or 1
			if self.hp < (self.max_health * scale) then
				self:heal(self.max_health / 5)
			end
			if self.hunger
				and self.hunger < (self.max_health * 0.4) * scale then
				self.hunger = self.hunger + 5
				self:memorize("hunger", self.hunger)
			end
			if item_name:find("cooked") then
				self.food = (self.food or 0) + 1
			end
			if self.food
				and self.food >= 20
				and self.age then
				self.food = 0
				self:increase_age()
			end
			local pos = waterdragon.get_head_pos(self, player:get_pos())
			local minppos = vec_add(pos, 0.2 * scale)
			local maxppos = vec_sub(pos, 0.2 * scale)
			local def = minetest.registered_items[item_name]
			local texture = def.inventory_image
			if not texture or texture == "" then
				texture = def.wield_image
			end
			minetest.add_particlespawner({
				amount = 3,
				time = 0.1,
				minpos = minppos,
				maxpos = maxppos,
				minvel = { x = -1, y = 1, z = -1 },
				maxvel = { x = 1, y = 2, z = 1 },
				minacc = { x = 0, y = -5, z = 0 },
				maxacc = { x = 0, y = -9, z = 0 },
				minexptime = 1,
				maxexptime = 1,
				minsize = 4 * scale,
				maxsize = 6 * scale,
				collisiondetection = true,
				vertical = false,
				texture = texture,
			})
			return true
		end
		return false
	end,
	play_wing_sound = function(self)
		local offset = self.frame_offset or 0
		if offset > 20
			and not self.flap_sound_played then
			minetest.sound_play("waterdragon_flap", {
				object = self.object,
				gain = 3.0,
				max_hear_distance = 128,
				loop = false,
			})
			self.flap_sound_played = true
		elseif offset < 10 then
			self.flap_sound_played = false
		end
	end
}


dofile(minetest.get_modpath("waterdragon") .. "/api/forms.lua")

minetest.register_on_mods_loaded(function()
	for k, v in pairs(waterdragon.dragon_api) do
		minetest.registered_entities["waterdragon:pure_water_dragon"][k] = v
		minetest.registered_entities["waterdragon:rare_water_dragon"][k] = v
	end
end)

--------------
-- Commands --
--------------

minetest.register_privilege("dragon_uisge", {
	description = "Allows Player to force Water Dragons",
	give_to_singleplayer = false,
	give_to_admin = false
})


minetest.register_chatcommand("set_wtd_owner", {
	description = "Sets owner of pointed Water Dragon",
	params = "<name>",
	privs = { dragon_uisge = true },
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		local param_name = params:match("%S+")
		if not player or not param_name then return false end
		local dir = player:get_look_dir()
		local pos = player:get_pos()
		pos.y = pos.y + player:get_properties().eye_height or 1.625
		local dest = vec_add(pos, vec_multi(dir, 40))
		local object, ent = get_pointed_mob(pos, dest)
		if object then
			local ent_pos = ent:get_center_pos()
			local particle = "waterdragon_particle_green.png"
			ent.owner = param_name
			ent:memorize("owner", ent.owner)
			minetest.chat_send_player(name, S("the Water Dragon is now owned by").." " .. param_name)
			minetest.add_particlespawner({
				amount = 16,
				time = 0.25,
				minpos = {
					x = ent_pos.x - ent.width,
					y = ent_pos.y - ent.width,
					z = ent_pos.z - ent.width
				},
				maxpos = {
					x = ent_pos.x + ent.width,
					y = ent_pos.y + ent.width,
					z = ent_pos.z + ent.width
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
		else
			minetest.chat_send_player(name, S("You must be pointing at a Water Dragon"))
		end
	end
})

minetest.register_chatcommand("wtd_blacklist_add", {
	description = "Adds player to attack blacklist of Water Dragons",
	params = "<name>",
	privs = { dragon_uisge = true },
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		local param_name = params:match("%S+")
		if not player or not param_name then return false end
		if waterdragon.wtd_attack_bl[param_name] then
			minetest.chat_send_player(name, param_name .." ".. S("is already on the Water Dragon attack blacklist"))
			return false
		end
		waterdragon.wtd_attack_bl[param_name] = true
		minetest.chat_send_player(name, param_name .." ".. S("has been added to the Water Dragon attack blacklist"))
	end
})

minetest.register_chatcommand("wtd_blacklist_remove", {
	description = "Removes player from attack blacklist of the Water Dragons",
	params = "<name>",
	privs = { dragon_uisge = true },
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		local param_name = params:match("%S+")
		if not player or not param_name then return false end
		if not waterdragon.wtd_attack_bl[param_name] then
			minetest.chat_send_player(name, param_name .." ".. S("isn't on the Water Dragon attack blacklist"))
			return false
		end
		waterdragon.wtd_attack_bl[param_name] = nil
		minetest.chat_send_player(name, param_name .." ".. S("has been removed from the Water Dragon attack blacklist"))
	end
})

----------------------
-- Target Assigning --
----------------------

local function get_wtd_by_id(wtd_id)
	for _, ent in pairs(minetest.luaentities) do
		if ent.wtd_id
			and ent.wtd_id == wtd_id then
			return ent
		end
	end
end

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_entities) do
		if (minetest.registered_entities[name].logic
				or minetest.registered_entities[name].brainfunc)
			or minetest.registered_entities[name]._cmi_is_mob
			or minetest.registered_entities[name]._creatura_mob then
			local old_punch = def.on_punch
			if not old_punch then
				old_punch = function() end
			end
			local on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
				old_punch(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
				local pos = self.object:get_pos()
				if not pos then return end
				if not puncher:is_player() then
					return
				end
				local player_name = puncher:get_player_name()
				if waterdragon.bonded_wtd[player_name]
					and #waterdragon.bonded_wtd[player_name] > 0 then
					for i = 1, #waterdragon.bonded_wtd[player_name] do
						local ent = get_wtd_by_id(waterdragon.bonded_wtd[player_name][i])
						if ent then
							ent._target = self.object
						end
					end
				end
			end
			minetest.registered_entities[name].on_punch = on_punch
		end
	end
end)
-----------------
-- On Activate --
-----------------

-- Dragon

function waterdragon.dragon_activate(self)
	local dragon_type = "rare_water"
	if self.name == "waterdragon:pure_water_dragon" then
		dragon_type = "pure_water"
	end
	generate_texture(self)
	self.eye_color = self:recall("eye_color")
	if not self.eye_color then
		self.eye_color = water_eye_textures[random(4)]
		self:memorize("eye_color", self.eye_color)
	end
	self.gender = self:recall("gender") or nil
	if not self.gender then
		local genders = { "male", "female" }
		self.gender = self:memorize("gender", genders[random(2)])
	end
	if self.growth_scale then
		self:memorize("growth_scale", self.growth_scale) -- This is for spawning children
	end
	self.growth_scale = self:recall("growth_scale") or 1
	self.growth_timer = self:recall("growth_timer") or 700
	self.age = self:recall("age") or 130
	local age = self.age
	if age <= 25 then
		self.growth_stage = 1
	elseif age <= 50 then
		self.growth_stage = 2
	elseif age <= 75 then
		self.growth_stage = 3
	else
		self.growth_stage = 4
	end
	self.hunger = self:recall("hunger") or ((self.max_health * 0.3) * self.growth_scale) * 0.3
	self:set_scale(self.growth_scale)
	self:do_growth()
	self:set_drops()
	self.drop_queue = self:recall("drop_queue") or nil
	if self.growth_scale < 0.25 then
		if not self.texture_no then
			self.texture_no = random(#self.child_textures)
		end
		self.textures = self.child_textures
		self:set_texture(self.texture_no, self.child_textures)
	end
	-- Tamed Data
	self.owner = self:recall("owner") or false
	self.stance = self:recall("stance") or "neutral"
	self.order = self:recall("order") or "wander"
	self.fly_allowed = self:recall("fly_allowed") or true
	self.aux_setting = self:recall("aux_setting") or "toggle_view"
	self.pitch_fly = self:recall("pitch_fly") or false
	self.shoulder_mounted = false
	activate_nametag(self)
	-- Movement Data
	self.is_landed = self:recall("is_landed") or false
	self.attack_stamina = self:recall("attack_stamina") or 150
	self.attack_disabled = self:recall("attack_disabled") or false
	self.flight_stamina = self:recall("flight_stamina") or 300

	-- Sound Data
	self.flap_sound_timer = 1.5
	self.flap_sound_played = false
	self.time_from_last_sound = 0
	-- World Data
	self.nest_pos = self:recall("nest_pos")
	self._path = {}
	self._ignore_obj = {}
	self.alert_timer = self:recall("alert_timer") or 0
	self._remove = self:recall("_remove") or nil
	self.wtd_id = self:recall("wtd_id") or 1
	if self.wtd_id == 1 then
		self.wtd_id = waterdragon.generate_id()
		self:memorize("wtd_id", self.wtd_id)
	end
	local global_data = waterdragon.waterdragons[self.wtd_id] or {}
	if global_data.removal_queue
		and #global_data.removal_queue > 0 then
		for i = #global_data.removal_queue, 1, -1 do
			if global_data.removal_queue[i]
				and vector.equals(vec_round(global_data.removal_queue[i]), vec_round(self.object:get_pos())) then
				waterdragon.waterdragons[self.wtd_id].removal_queue[i] = nil
				self.object:remove()
				return
			end
		end
	end
	waterdragon.waterdragons[self.wtd_id] = {
		last_pos = self.object:get_pos(),
		owner = self.owner or nil,
		staticdata = self:get_staticdata(),
		removal_queue = global_data.removal_queue or {},
		stored_in_item = global_data.stored_in_item or false
	}
	local owner = waterdragon.waterdragons[self.wtd_id].owner
	if owner
		and minetest.get_player_by_name(owner)
		and (not waterdragon.bonded_wtd[owner]
			or not is_value_in_table(waterdragon.bonded_wtd[owner], self.wtd_id)) then
		waterdragon.bonded_wtd[owner] = waterdragon.bonded_wtd[owner] or {}
		table.insert(waterdragon.bonded_wtd[owner], self.wtd_id)
	end
end

-------------
-- On Step --
-------------

-- Water Dragon

function waterdragon.dragon_step(self, dtime)
	self:update_emission()
	self:destroy_terrain()
	-- Animation Tracking
	local current_anim = self._anim
	local is_flying = current_anim and current_anim:find("fly")
	local is_firing = current_anim and current_anim:find("pure_water")
	if current_anim then
		local aparms = self.animations[current_anim]
		if self.anim_frame ~= -1 then
			self.anim_frame = self.anim_frame + dtime
			self.frame_offset = floor(self.anim_frame * aparms.speed)
			if self.frame_offset > aparms.range.y - aparms.range.x then
				self.anim_frame = 0
				self.frame_offset = 0
			end
		end
	end
	-- Dynamic Animation
	waterdragon.head_tracking(self)
	self:open_jaw()
	self:move_tail()
	waterdragon.rotate_to_pitch(self, is_flying)
	-- Shoulder Mounting
	if self.shoulder_mounted then
		self:clear_action()
		self:animate("shoulder_idle")
		local player = minetest.get_player_by_name(self.owner)
		if not player
			or player:get_player_control().sneak == true
			or self.age > 4 then
			self.object:set_detach()
			self.shoulder_mounted = self:memorize("shoulder_mounted", false)
		end
		is_flying = false
	end

if self.in_liquid then
	self.speed = 50 * 2 
end

	-- Dynamic Physics
	self.speed = 50 * clamp((self.growth_scale), 0.1, 1) -- Speed increases with size
	self.turn_rate = 6 - 3 * clamp((self.growth_scale), 0.1, 1) -- Turning radius widens with size
	if not is_flying then
		self.speed = self.speed * 0.18  -- Speed reduced when landed
		self.turn_rate = self.turn_rate * 1.5 -- Turning radius reduced when landed
	end
	-- Timers
	if self:timer(1) then
		self:do_growth()
		-- Misc
		self.time_from_last_sound = self.time_from_last_sound + 1
		if self.time_in_horn then
			self.growth_timer = self.growth_timer - self.time_in_horn / 2
			self.time_in_horn = nil
		end
		if random(16) < 2
			and not is_firing then
			self:play_sound("random")
		end
		-- Dynamic Stats
		local fly_stam = self.flight_stamina or 300
		local atk_stam = self.attack_stamina or 150
		local alert_timer = self.alert_timer or 0
		if is_flying
			and not self.in_liquid then -- Drain Stamina when flying
			fly_stam = fly_stam - 1
		else
			if fly_stam < 300 then -- Regen Stamina when landed
				fly_stam = fly_stam + self.dtime * 8
			end
		end
		if atk_stam < 100 then -- Regen Stamina constantly
			atk_stam = atk_stam + 1
		end
		if alert_timer > 0 then
			alert_timer = alert_timer - 1
		end
		self.flight_stamina = self:memorize("flight_stamina", fly_stam)
		self.attack_stamina = self:memorize("attack_stamina", atk_stam)
		self.alert_timer = self:memorize("alert_timer", alert_timer)
	end
	if self:timer(5) then
		local obj = next(self._ignore_obj)
		if obj then self._ignore_obj[obj] = nil end
	end
	if is_flying then
		self:play_wing_sound()
	end
	-- Switch Aerial/Terrestrial States
	if not self.is_landed
		and not self.fly_allowed
		and self.owner then
		self.is_landed = self:memorize("is_landed", true)
	elseif self:timer(16)
		and random(4) < 2 then
		if self.is_landed
			and self.flight_stamina > 50 then
			self.is_landed = self:memorize("is_landed", false)
		else
			self.is_landed = self:memorize("is_landed", true)
		end
	end
	-- Global Info
	if self.hp <= 0 then
		waterdragon.waterdragons[self.wtd_id] = nil
		return
	end
	local global_data = waterdragon.waterdragons[self.wtd_id] or {}
	waterdragon.waterdragons[self.wtd_id] = {
		last_pos = self.object:get_pos(),
		owner = self.owner or nil,
		name = self.nametag or nil,
		staticdata = self:get_staticdata(),
		removal_queue = global_data.removal_queue or {},
		stored_in_item = global_data.stored_in_item or false
	}
	if waterdragon.waterdragons[self.wtd_id].stored_in_item then
		self.object:remove()
	end
end

-------------------
-- On Rightclick --
-------------------

-- Dragon

function waterdragon.dragon_rightclick(self, clicker)
	local name = clicker:get_player_name()
	local inv = minetest.get_inventory({ type = "player", name = name })
	if waterdragon.contains_book(inv) then
		waterdragon.add_page(inv, "waterdragons")
	end
	if self.hp <= 0 then
		if waterdragon.drop_items(self) then
			waterdragon.waterdragons[self.wtd_id] = nil
			self.object:remove()
		end
		return
	end
	if self:feed(clicker) then
		return
	end
	local item_name = clicker:get_wielded_item():get_name() or ""
	if self.owner
		and name == self.owner
		and item_name == "" then
		if clicker:get_player_control().sneak then
			self:show_formspec(clicker)
		elseif not self.rider
			and self.age >= 35 then
			waterdragon.attach_player(self, clicker)
		elseif self.age < 5 then
			self.shoulder_mounted = self:memorize("shoulder_mounted", true)
			self.object:set_attach(clicker, "",
				{ x = 3 - self.growth_scale, y = 11.5, z = -1.5 - (self.growth_scale * 5) }, { x = 0, y = 0, z = 0 })
		end
	end
	if self.rider
		and not self.passenger
		and name ~= self.owner
		and item_name == "" then
		waterdragon.send_passenger_request(self, clicker)
	end
end
