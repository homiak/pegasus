---------
-- API --
---------

-- Math --

local abs = math.abs
local atan2 = math.atan2
local cos = math.cos
local deg = math.deg
local min = math.min
local pi = math.pi
local pi2 = pi * 2
local rad = math.rad
local random = math.random
local sin = math.sin
local sqrt = math.sqrt


local function diff(a, b) -- Get difference between 2 angles
	return atan2(sin(b - a), cos(b - a))
end

local function interp_angle(a, b, w)
	local cs = (1 - w) * cos(a) + w * cos(b)
	local sn = (1 - w) * sin(a) + w * sin(b)
	return atan2(sn, cs)
end

local function lerp_step(a, b, dtime, rate)
	return min(dtime * rate, abs(diff(a, b)) % (pi2))
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

local vec_add, vec_dir, vec_dist, vec_divide, vec_len, vec_multi, vec_normal,
	vec_round, vec_sub = vector.add, vector.direction, vector.distance, vector.divide,
	vector.length, vector.multiply, vector.normalize, vector.round, vector.subtract

local dir2yaw = minetest.dir_to_yaw
local yaw2dir = minetest.yaw_to_dir

------------
-- Common --
------------

function pegasus.get_average_pos(vectors)
	local sum = {x = 0, y = 0, z = 0}
	for _, vec in pairs(vectors) do sum = vec_add(sum, vec) end
	return vec_divide(sum, #vectors)
end

function pegasus.correct_name(str)
	if str then
		if str:match(":") then str = str:split(":")[2] end
		return (string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("_", " "))
	end
end

---------------------
-- Local Utilities --
---------------------

local function activate_nametag(self)
    self.nametag = self:recall("nametag") or nil
    if not self.nametag then return end
    self.object:set_properties({
        nametag = self.nametag,
        nametag_color = "#d1fff7"
    })
end

pegasus.animate_player = {}

if minetest.get_modpath("default")
and minetest.get_modpath("player_api") then
	pegasus.animate_player = player_api.set_animation
elseif minetest.get_modpath("mcl_player") then
	pegasus.animate_player = mcl_player.player_set_animation
end

-----------------------
-- Dynamic Animation --
-----------------------

function pegasus.rotate_to_pitch(self)
	local rot = self.object:get_rotation()
	if self._anim == "fly" then
		local vel = vec_normal(self.object:get_velocity())
		local step = min(self.dtime * 5, abs(diff(rot.x, vel.y)) % (pi2))
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
			z = rot.z
		})
	end
end

function pegasus.move_head(self, tyaw, pitch)
	local data = self.head_data
	if not data then return end
	local yaw = self.object:get_yaw()
	local pitch_offset = data.pitch_correction or 0
	local bone = data.bone or "Head.CTRL"
	local _, rot = self.object:get_bone_position(bone)
	if not rot then return end
	local n_yaw = (tyaw ~= yaw and diff(tyaw, yaw) / 2) or 0
	if abs(deg(n_yaw)) > 45 then n_yaw = 0 end
	local dir = yaw2dir(n_yaw)
	dir.y = pitch or 0
	local n_pitch = (sqrt(dir.x^2 + dir.y^2) / dir.z)
	if abs(deg(n_pitch)) > 45 then n_pitch = 0 end
	if self.dtime then
		local yaw_w = lerp_step(rad(rot.z), tyaw, self.dtime, 3)
		n_yaw = interp_angle(rad(rot.z), n_yaw, yaw_w)
		local rad_offset = rad(pitch_offset)
		local pitch_w = lerp_step(rad(rot.x), n_pitch + rad_offset, self.dtime, 3)
		n_pitch = interp_angle(rad(rot.x), n_pitch + rad_offset, pitch_w)
	end
	local pitch_max = pitch_offset + 45
	local pitch_min = pitch_offset - 45
	self.object:set_bone_position(bone, data.offset,
		{x = clamp(deg(n_pitch), pitch_min, pitch_max), y = 0, z = clamp(deg(n_yaw), -45, 45)})
end

function pegasus.head_tracking(self)
	if not self.head_data then return end
	-- Calculate Head Position
	local yaw = self.object:get_yaw()
	local pos = self.object:get_pos()
	if not pos then return end
	local y_dir = yaw2dir(yaw)
	local offset_h = self.head_data.pivot_h
	local offset_v = self.head_data.pivot_v
	pos = {
		x = pos.x + y_dir.x * offset_h,
		y = pos.y + offset_v,
		z = pos.z + y_dir.z * offset_h
	}
	local vel = self.object:get_velocity()
	if vec_len(vel) > 2 then
		self.head_tracking = nil
		pegasus.move_head(self, yaw, 0)
		return
	end
	local player = self.head_tracking
	local plyr_pos = player and player:get_pos()
	if plyr_pos then
		plyr_pos.y = plyr_pos.y + 1.4
		local dir = vec_dir(pos, plyr_pos)
		local tyaw = dir2yaw(dir)
		if abs(diff(yaw, tyaw)) > pi / 10
		and self._anim == "stand" then
			self:turn_to(tyaw, 1)
		end
		pegasus.move_head(self, tyaw, dir.y)
		return
	elseif self:timer(6)
	and random(4) < 2 then

		local players = pegasus.get_nearby_players(self, 6)
		self.head_tracking = #players > 0 and players[random(#players)]
	end
	pegasus.move_head(self, yaw, 0)

end

---------------
-- Utilities --
---------------

function pegasus.alias_mob(old_mob, new_mob)
	minetest.register_entity(":" .. old_mob, {
		on_activate = function(self)
			local pos = self.object:get_pos()
			minetest.add_entity(pos, new_mob)
			self.object:remove()
		end,
	})
end

------------------------
-- Environment Access --
------------------------

function pegasus.has_shared_owner(obj1, obj2)
	local ent1 = obj1 and obj1:get_luaentity()
	local ent2 = obj2 and obj2:get_luaentity()
	if ent1
	and ent2 then
		return ent1.owner and ent2.owner and ent1.owner == ent2.owner
	end
	return false
end

function pegasus.get_attack_score(entity, attack_list)
	local pos = entity.stand_pos
	if not pos then return end

	local order = entity.order or "wander"
	if order ~= "wander" then return 0 end

	local target = entity._target or (entity.attacks_players and pegasus.get_nearby_player(entity))
	local tgt_pos = target and target:get_pos()

	if not tgt_pos
	or not entity:is_pos_safe(tgt_pos)
	or (target:is_player()
	and minetest.is_creative_enabled(target:get_player_name())) then
		target = pegasus.get_nearby_object(entity, attack_list)
		tgt_pos = target and target:get_pos()
	end

	if not tgt_pos then entity._target = nil return 0 end

	if target == entity.object then entity._target = nil return 0 end

	if pegasus.has_shared_owner(entity.object, target) then entity._target = nil return 0 end

	local dist = vec_dist(pos, tgt_pos)
	local score = (entity.tracking_range - dist) / entity.tracking_range

	if entity.trust
	and target:is_player()
	and entity.trust[target:get_player_name()] then
		local trust = entity.trust[target:get_player_name()]
		local trust_score = ((entity.max_trust or 10) - trust) / (entity.max_trust or 10)

		score = score - trust_score
	end

	entity._target = target
	return score * 0.5, {entity, target}
end

function pegasus.get_nearby_mate(self)
	local pos = self.object:get_pos()
	if not pos then return end
	local objects = pegasus.get_nearby_objects(self, self.name)
	for _, object in ipairs(objects) do
		local obj_pos = object and object:get_pos()
		local ent = obj_pos and object:get_luaentity()
		if obj_pos
		and ent.growth_scale == 1
		and ent.gender ~= self.gender
		and ent.breeding then
			return object
		end
	end
end

function pegasus.find_collision(self, dir)
	local pos = self.object:get_pos()
	local pos2 = vec_add(pos, vec_multi(dir, 16))
	local ray = minetest.raycast(pos, pos2, false, false)
	for pointed_thing in ray do
		if pointed_thing.type == "node" then
			return pointed_thing.under
		end
	end
	return nil
end

function pegasus.random_drop_item(self, item, chance)
	local pos = self.object:get_pos()
	if not pos then return end
	if random(chance) < 2 then
		local object = minetest.add_item(pos, ItemStack(item))
		object:add_velocity({
			x = random(-2, 2),
			y = 1.5,
			z = random(-2, 2)
		})
	end
end

---------------
-- Particles --
---------------

function pegasus.particle_spawner(pos, texture, type, min_pos, max_pos)
	type = type or "float"
	min_pos = min_pos or vec_sub(pos, 1)
	max_pos = max_pos or vec_add(pos, 1)
	if type == "float" then
		minetest.add_particlespawner({
			amount = 16,
			time = 0.25,
			minpos = min_pos,
			maxpos = max_pos,
			minvel = {x = 0, y = 0.2, z = 0},
			maxvel = {x = 0, y = 0.25, z = 0},
			minexptime = 0.75,
			maxexptime = 1,
			minsize = 4,
			maxsize = 4,
			texture = texture,
			glow = 1,
		})
	elseif type == "splash" then
		minetest.add_particlespawner({
			amount = 6,
			time = 0.25,
			minpos = {x = pos.x - 7/16, y = pos.y + 0.6, z = pos.z - 7/16},
			maxpos = {x = pos.x + 7/16, y = pos.y + 0.6, z = pos.z + 7/16},
			minvel = {x = -1, y = 2, z = -1},
			maxvel = {x = 1, y = 5, z = 1},
			minacc = {x = 0, y = -9.81, z = 0},
			maxacc = {x = 0, y = -9.81, z = 0},
			minsize = 2,
			maxsize = 4,
			collisiondetection = true,
			texture = texture,
		})
	end
end

function pegasus.add_food_particle(self, item_name)
	local pos, yaw = self.object:get_pos(), self.object:get_yaw()
	if not pos then return end
	local head = self.head_data
	local offset_h = (head and head.pivot_h) or self.width
	local offset_v = (head and head.pivot_v) or self.height
	local head_pos = {
		x = pos.x + sin(yaw) * -offset_h,
		y = pos.y + offset_v,
		z = pos.z + cos(yaw) * offset_h
	}
	local def = minetest.registered_items[item_name]
	local image = def.inventory_image
	if def.tiles then
		image = def.tiles[1].name or def.tiles[1]
	end
	if image then
		local crop = "^[sheet:4x4:" .. random(4) .. "," .. random(4)
		minetest.add_particlespawner({
			pos = head_pos,
			time = 0.5,
			amount = 12,
			collisiondetection = true,
			collision_removal = true,
			vel = {min = {x = -1, y = 1, z = -1}, max = {x = 1, y = 2, z = 1}},
			acc = {x = 0, y = -9.8, z = 0},
			size = {min = 1, max = 2},
			texture = image .. crop
		})
	end
end

function pegasus.add_break_particle(pos)
	pos = vec_round(pos)
	local def = pegasus.get_node_def(pos)
	local texture = (def.tiles and def.tiles[1]) or def.inventory_image
	texture = texture .. "^[resize:8x8"
	minetest.add_particlespawner({
		amount = 6,
		time = 0.1,
		minpos = {
			x = pos.x,
			y = pos.y - 0.49,
			z = pos.z
		},
		maxpos = {
			x = pos.x,
			y = pos.y - 0.49,
			z = pos.z
		},
		minvel = {x=-1, y=1, z=-1},
		maxvel = {x=1, y=2, z=1},
		minacc = {x=0, y=-5, z=0},
		maxacc = {x=0, y=-9, z=0},
		minexptime = 1,
		maxexptime = 1.5,
		minsize = 1,
		maxsize = 2,
		collisiondetection = true,
		vertical = false,
		texture = texture,
	})
end

----------
-- Mobs --
----------

function pegasus.death_func(self)
	if self:get_utility() ~= "pegasus:die" then
		self:initiate_utility("pegasus:die", self)
	end
end

function pegasus.get_dropped_food(self, item, radius)
	local pos = self.object:get_pos()
	if not pos then return end

	local objects = minetest.get_objects_inside_radius(pos, radius or self.tracking_range)
	for _, object in ipairs(objects) do
		local ent = object:get_luaentity()
		if ent
		and ent.name == "__builtin:item"
		and ent.itemstring
		and ((item and ent.itemstring:match(item))
		or self:follow_item(ItemStack(ent.itemstring))) then
			return object, object:get_pos()
		end
	end
end

function pegasus.eat_dropped_item(self, item)
	local pos = self.object:get_pos()
	if not pos then return end

	local food = item or pegasus.get_dropped_food(self, nil, self.width + 1)

	local food_ent = food and food:get_luaentity()
	if food_ent then
		local food_pos = food:get_pos()

		local stack = ItemStack(food_ent.itemstring)
		if stack
		and stack:get_count() > 1 then
			stack:take_item()
			food_ent.itemstring = stack:to_string()
		else
			food:remove()
		end

		self.object:set_yaw(dir2yaw(vec_dir(pos, food_pos)))
		pegasus.add_food_particle(self, stack:get_name())

		if self.on_eat_drop then
			self:on_eat_drop()
		end
		return true
	end
end

function pegasus.protect_from_despawn(self)
	self._despawn = self:memorize("_despawn", false)
	self.despawn_after = self:memorize("despawn_after", false)
end

function pegasus.despawn_inactive_mob(self)
	local os_time = os.time()
	self._last_active = self:recall("_last_active")
	if self._last_active
	and self.despawn_after then
		local last_active = self._last_active
		if os_time - last_active > self.despawn_after then
			self.object:remove()
			return true
		end
	end
end

function pegasus.set_nametag(self, clicker)
    local item = clicker and clicker:get_wielded_item()
    if not item or item:get_name() ~= "pegasus:nametag" then
        return -- Not holding a nametag, do nothing.
    end

    -- By returning true here, we tell the game:
    -- "Yes, we handled the right-click for the nametag."
    -- This prevents the player from trying to mount the pegasus,
    -- and allows the item's on_secondary_use to fire correctly.
    return true
end

function pegasus.initialize_api(self)
	-- Set Gender
	self.gender = self:recall("gender") or nil
	if not self.gender then
		local genders = {"male", "female"}
		self.gender = self:memorize("gender", genders[random(2)])
		-- Reset Texture ID
		self.texture_no = nil
	end

	-- Taming/Breeding
	self.food = self:recall("food") or 0
	self.gotten = self:recall("gotten") or false
	self.breeding = false
	self.breeding_cooldown = self:recall("breeding_cooldown") or 0

	-- Textures/Scale
	if self.growth_scale then
		self:memorize("growth_scale", self.growth_scale) -- This is for spawning children
	end
	self.growth_scale = self:recall("growth_scale") or 1
	self:set_scale(self.growth_scale)
	local child_textures = self.growth_scale < 0.8 and self.child_textures
	local textures = (not child_textures and self[self.gender .. "_textures"]) or self.textures
	if child_textures then
		if not self.texture_no
		or self.texture_no > #child_textures then
			self.texture_no = random(#child_textures)
		end
		self:set_texture(self.texture_no, child_textures)
	elseif textures then
		if not self.texture_no then
			self.texture_no = random(#textures)
		end
		self:set_texture(self.texture_no, textures)
	end
	if self.growth_scale < 0.8
	and self.child_mesh then
		self.object:set_properties({
			mesh = self.child_mesh
		})
	end
	activate_nametag(self)
end

function pegasus.step_timers(self)
	local breed_cd = self.breeding_cooldown or 30
	local trust_cd = self.trust_cooldown or 0
	self.breeding_cooldown = (breed_cd > 0 and breed_cd - self.dtime) or 0
	self.trust_cooldown = (trust_cd > 0 and trust_cd - self.dtime) or 0
	if self.breeding
	and self.breeding_cooldown <= 30 then
		self.breeding = false
	end
	self:memorize("breeding_cooldown", self.breeding_cooldown)
	self:memorize("trust_cooldown", self.trust_cooldown)
	self:memorize("_last_active", os.time())
end

function pegasus.do_growth(self, interval)
	if self.growth_scale
	and self.growth_scale < 0.9 then
		if self:timer(interval) then
			self.growth_scale = self.growth_scale + 0.1
			self:set_scale(self.growth_scale)
			if self.growth_scale < 0.8
			and self.child_textures then
				local tex_no = self.texture_no
				if not self.child_textures[tex_no] then
					tex_no = 1
				end
				self:set_texture(tex_no, self.child_textures)
			elseif self.growth_scale == 0.8 then
				if self.child_mesh then self:set_mesh() end
				if self.male_textures
				and self.female_textures then
					if #self.child_textures == 1 then
						self.texture_no = random(#self[self.gender .. "_textures"])
					end
					self:set_texture(self.texture_no, self[self.gender .. "_textures"])
				else
					if #self.child_textures == 1 then
						self.texture_no = random(#self.textures)
					end
					self:set_texture(self.texture_no, self.textures)
				end
				if self.on_grown then
					self:on_grown()
				end
			end
			self:memorize("growth_scale", self.growth_scale)
		end
	end
end

function pegasus.random_sound(self)
	if self:timer(8)
	and random(4) < 2 then
		self:play_sound("random")
	end
end

function pegasus.add_trust(self, player, amount)
	if self.trust_cooldown > 0 then return end
	self.trust_cooldown = 60
	local plyr_name = player:get_player_name()
	local trust = self.trust[plyr_name] or 0
	if trust > 4 then return end
	self.trust[plyr_name] = trust + (amount or 1)
	self:memorize("trust", self.trust)
end

function pegasus.feed(self, clicker, tame, breed)
	local yaw = self.object:get_yaw()
	local pos = self.object:get_pos()
	if not pos then return end
	local name = clicker:is_player() and clicker:get_player_name()
	local item, item_name = self:follow_wielded_item(clicker)
	if item_name then
		-- Eat Animation
		local head = self.head_data
		local offset_h = (head and head.pivot_h) or 0.5
		local offset_v = (head and head.pivot_v) or 0.5
		local head_pos = {
			x = pos.x + sin(yaw) * -offset_h,
			y = pos.y + offset_v,
			z = pos.z + cos(yaw) * offset_h
		}
		local def = minetest.registered_items[item_name]
		if def.inventory_image then
			minetest.add_particlespawner({
				pos = head_pos,
				time = 0.1,
				amount = 3,
				collisiondetection = true,
				collision_removal = true,
				vel = {min = {x = -1, y = 3, z = -1}, max = {x = 1, y = 4, z = 1}},
				acc = {x = 0, y = -9.8, z = 0},
				size = {min = 2, max = 4},
				texture = def.inventory_image
			})
		end
		-- Increase Health
		local feed_no = (self.feed_no or 0) + 1
		local max_hp = self.max_health
		local hp = self.hp
		hp = hp + (max_hp / 5)
		if hp > max_hp then hp = max_hp end
		self.hp = hp
		-- Tame/Breed
		if feed_no >= 5 then
			feed_no = 0
			if tame then
				self.owner = self:memorize("owner", name)
				minetest.add_particlespawner({
					pos = {min = vec_sub(pos, self.width), max = vec_add(pos, self.width)},
					time = 0.1,
					amount = 12,
					vel = {min = {x = 0, y = 3, z = 0}, max = {x = 0, y = 4, z = 0}},
					size = {min = 4, max = 6},
					glow = 16,
					texture = "pegasus_particle_green.png"
				})
			end
			if breed then
				if self.breeding then return false end
                if self.breeding_cooldown <= 0 then
                    self.breeding = true
                    self.breeding_cooldown = 60
                    pegasus.particle_spawner(pos, "heart.png", "float")
                end
			end
			self._despawn = self:memorize("_despawn", false)
			self.despawn_after = self:memorize("despawn_after", false)
		end
		self.feed_no = feed_no
		-- Take item
		if not minetest.is_creative_enabled(name) then
			item:take_item()
			clicker:set_wielded_item(item)
		end
		return true
	end
end

function pegasus.mount(self, player, params)
	if not pegasus.is_alive(player)
	or (player:get_attach()
	and player:get_attach() ~= self.object) then
		return
	end
	local plyr_name = player:get_player_name()
	if (player:get_attach()
	and player:get_attach() == self.object)
	or not params then
		player:set_detach()
		player:set_properties({
			visual_size = {
				x = 1,
				y = 1
			}
		})
		player:set_eye_offset()
		if minetest.get_modpath("player_api") then
			pegasus.animate_player(player, "stand", 30)
			if player_api.player_attached then
				player_api.player_attached[plyr_name] = false
			end
		end
		return
	end
	if minetest.get_modpath("player_api") then
		player_api.player_attached[plyr_name] = true
	end
	self.rider = player
	player:set_attach(self.object, "Torso", params.pos, params.rot)
	player:set_eye_offset({x = 0, y = 20, z = 5}, {x = 0, y = 20, z = 15})
	self:clear_utility()
	minetest.after(0.4, function()
		pegasus.animate_player(player, "sit" , 30)
	end)
end

function pegasus.punch(self, puncher, ...)
	if self.hp <= 0 then return end
	pegasus.basic_punch_func(self, puncher, ...)
	self._puncher = puncher
	if self.flee_puncher
	and (self:get_utility() or "") ~= "pegasus:flee_from_target" then
		self:clear_utility()
	end
end

function pegasus.find_crop(self)
	local pos = self.object:get_pos()
	if not pos then return end

	local nodes = minetest.find_nodes_in_area(vec_sub(pos, 6), vec_add(pos, 6), "group:crop") or {}
	if #nodes < 1 then return end
	return nodes[math.random(#nodes)]
end

function pegasus.eat_crop(self, pos)
	local node_name = minetest.get_node(pos).name
	local new_name = node_name:sub(1, #node_name - 1) .. (tonumber(node_name:sub(-1)) or 2) - 1
	local new_def = minetest.registered_nodes[new_name]
	if not new_def then return false end
	local p2 = new_def.place_param2 or 1
	minetest.set_node(pos, {name = new_name, param2 = p2})
	pegasus.add_food_particle(self, new_name)
	return true
end

function pegasus.eat_turf(mob, pos)
	for name, sub_name in pairs(mob.consumable_nodes) do
		if minetest.get_node(pos).name == name then
			--add_break_particle(turf_pos)
			minetest.set_node(pos, {name = sub_name})
			mob.collected = mob:memorize("collected", false)
			--pegasus.action_idle(mob, 1, "eat")
			return true
		end
	end
end

--------------
-- Spawning --
--------------

pegasus.registered_biome_groups = {}

function pegasus.register_biome_group(name, def)
	pegasus.registered_biome_groups[name] = def
	pegasus.registered_biome_groups[name].biomes = {}
end

local function assign_biome_group(name)
	local def = minetest.registered_biomes[name]
	local turf = def.node_top
	local heat = def.heat_point or 0
	local humidity = def.humidity_point or 50
	local y_min = def.y_min
	local y_max = def.y_max
	for group, params in pairs(pegasus.registered_biome_groups) do -- k, v in pairs
		if name:find(params.name_kw or "")
		and turf and turf:find(params.turf_kw or "")
		and heat >= params.min_heat
		and heat <= params.max_heat
		and humidity >= params.min_humidity
		and humidity <= params.max_humidity
		and (not params.min_height or y_min >= params.min_height)
		and (not params.max_height or y_max <= params.max_height) then
			table.insert(pegasus.registered_biome_groups[group].biomes, name)
		end
	end
end

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_biomes) do
		assign_biome_group(name)
	end
end)

pegasus.register_biome_group("grassland", {
	name_kw = "",
	turf_kw = "grass",
	min_heat = 45,
	max_heat = 90,
	min_humidity = 0,
	max_humidity = 80
})

