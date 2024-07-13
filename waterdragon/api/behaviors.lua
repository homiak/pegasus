---------------
-- Behaviors --
---------------

waterdragon.pure_water_dragon_targets = {}

waterdragon.rare_water_dragon_targets = {}


minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_entities) do
		local is_mobkit = (def.logic ~= nil or def.brainfuc ~= nil)
		local is_creatura = def._creatura_mob
		if is_mobkit
		or is_creatura
		or def._cmi_is_mob then
			if name ~= "waterdragon:pure_water_dragon" then
				table.insert(waterdragon.pure_water_dragon_targets, name)
			end
			if name ~= "waterdragon:rare_water_dragon" then
				table.insert(waterdragon.rare_water_dragon_targets, name)
			end
			local hp = def.max_health or def.max_hp or 21
		
		end
	end
end)

-- Local Math --

local abs = math.abs
local atan2 = math.atan2
local ceil = math.ceil
local cos = math.cos
local rad = math.rad
local random = math.random
local sin = math.sin

local function clamp(val, _min, _max)
	if val < _min then
		val = _min
	elseif _max < val then
		val = _max
	end
	return val
end

local function diff(a, b) -- Get difference between 2 angles
	return atan2(sin(b - a), cos(b - a))
end

local function vec_raise(v, n)
	return {x = v.x, y = v.y + n, z = v.z}
end

local vec_normal = vector.normalize
local vec_dir = vector.direction
local vec_dist = vector.distance
local vec_multi = vector.multiply
local vec_sub = vector.subtract
local vec_add = vector.add
local yaw2dir = minetest.yaw_to_dir
local dir2yaw = minetest.dir_to_yaw

---------------------
-- Local Utilities --
---------------------

local is_night = false

local function check_time()
    local time = (minetest.get_timeofday() or 0) * 24000
    is_night = time > 19500 or time < 4500
    minetest.after(10, check_time)
end

check_time()

local moveable = creatura.is_pos_moveable

local function is_target_flying(target)
	if not target or not target:get_pos() then return end
	local pos = target:get_pos()
	if not pos then return end
	local node = minetest.get_node(pos)
	if not node then return false end
	if minetest.get_item_group(node.name, "igniter") > 0
	or creatura.get_node_def(node.name).drawtype == "liquid"
	or creatura.get_node_def(vec_raise(pos, -1)).drawtype == "liquid" then return false end
	local flying = true
	for i = 1, 8 do
		local fly_pos = {
			x = pos.x,
			y = pos.y - i,
			z = pos.z
		}
		if creatura.get_node_def(fly_pos).walkable then
			flying = false
			break
		end
	end
	return flying
end

local function shared_owner(obj1, obj2)
	if not obj1 or not obj2 then return false end
	obj1 = creatura.is_valid(obj1)
	obj2 = creatura.is_valid(obj2)
	if obj1
	and obj2
	and obj1:get_luaentity()
	and obj2:get_luaentity() then
		obj1 = obj1:get_luaentity()
		obj2 = obj2:get_luaentity()
		return obj1.owner and obj2.owner and obj1.owner == obj2.owner
	end
	return false
end

local function get_target_group(target, radius)
	local pos = target:get_pos()
	local objects = minetest.get_objects_in_area(vec_sub(pos, radius or 8), vec_add(pos, radius or 8))
	local group = {}
	for _, object in ipairs(objects) do
		local ent = object and object:get_luaentity()
		if ent
		and not ent._ignore then
			table.insert(group, object)
		end
	end
	return group
end

local function find_target(self, list)
	local owner = self.owner and minetest.get_player_by_name(self.owner)
	local targets = creatura.get_nearby_players(self)
	if #targets > 0 then -- If there are players nearby
		local target = targets[random(#targets)]
		local is_creative = target:is_player() and minetest.is_creative_enabled(target)
		local is_owner = owner and target == owner
		if is_creative or is_owner then targets = {} end
	end
	targets = (#targets < 1 and list and creatura.get_nearby_objects(self, list)) or targets
	if #targets < 1 then return end
	return targets[random(#targets)]
end

-- Movement Methods --

creatura.register_movement_method("waterdragon:fly_pathfind", function(self)
	local path = {}
	local steer_to
	local steer_timer = 0.01
	local width = self.width
	local wayp_threshold = width + (width / self.turn_rate)

	self:set_gravity(0)
	local function func(_self, goal, speed_x)
		local pos = _self.object:get_pos()
		if not pos then return end
		steer_timer = (steer_timer > 0 and steer_timer - _self.dtime) or 0.25
		if #path > 0 then steer_timer = 1 end
		steer_to = (steer_timer <= 0 and creatura.get_context_steering(self, goal, 8)) or steer_to
		-- Return true when goal is reached
		if vec_dist(pos, goal) < wayp_threshold then
			_self:halt()
			return true
		end
		-- Get movement direction
		local goal_dir = steer_to or vec_dir(pos, goal)
		if steer_to then
			if #path < 2 then
				path = creatura.find_path(_self, pos, goal, _self.width, _self.height, 200, false, true) or {}
			end
		end
		if #path > 1 then
			goal_dir = vec_dir(pos, path[2])
			if vec_dist(pos, path[1]) < _self.width then
				table.remove(path, 1)
			end
		end
		local goal_yaw = dir2yaw(goal_dir)
		local speed = (_self.speed or 24) * speed_x
		_self:tilt_to(goal_yaw, _self.turn_rate or 7)
		-- Set Velocity
		_self:set_forward_velocity(speed)
		_self:set_vertical_velocity(speed * goal_dir.y)
	end
	return func
end)

creatura.register_movement_method("waterdragon:fly_simple", function(self)
	local steer_to
	local steer_timer = 0.25
	local width = self.width
	local wayp_threshold = width + ((width / self.turn_rate or 7))
	self:set_gravity(0)
	local function func(_self, goal, speed_factor)
		local pos = _self.object:get_pos()
		if not pos then return end
		local dist = vec_dist(pos, goal)
		if dist < wayp_threshold then
			_self:halt()
			return true
		end
		-- Calculate Movement
		steer_timer = (steer_timer > 0 and steer_timer - self.dtime) or 0.25
		steer_to = (steer_timer <= 0 and creatura.get_context_steering(self, goal, 4)) or steer_to
		local speed = abs(_self.speed or 2) * speed_factor or 0.5
		local turn_rate = abs(_self.turn_rate or 7)
		-- Apply Movement
		local dir = (steer_to or vec_dir(pos, goal))
		_self:set_forward_velocity(speed)
		_self:set_vertical_velocity(speed * dir.y)
		_self:tilt_to(dir2yaw(dir), turn_rate)
	end
	return func
end)

-- Actions --

function waterdragon.action_flight_pure_water(self, target, timeout)
	local timer = timeout or 12
	local goal
	local function func(_self)
		local pos = _self.stand_pos
		if timer <= 0 then return true end
		local target_alive, los, tgt_pos = _self:get_target(target)
		if not target_alive then return true end
		self.head_tracking = target
		if not goal or _self:timer(4) then
			goal = _self:get_wander_pos_3d(6, 8, vec_dir(pos, tgt_pos))
		end
		if _self:move_to(goal, "waterdragon:fly_simple", 0.5) then
			goal = nil
		end
		if los then
			_self:breath_attack(tgt_pos)
			_self:animate("fly_pure_water")
		else
			_self:animate("fly")
		end
		timer = timer - _self.dtime
	end
	self:set_action(func)
end

function waterdragon.action_flight_attack(self, target, timeout)
	local anim = self.animations["fly_punch"]
	local anim_len = (anim.range.y - anim.range.x) / anim.speed
	local anim_time = 0
	local timer = timeout or 12
	local cooldown = 0
	local goal
	local function func(_self)
		local pos = _self.stand_pos
		if timer <= 0 then return true end
		local target_alive, _, tgt_pos = _self:get_target(target)
		if not target_alive then return true end
		local dist = vec_dist(pos, tgt_pos)

		if dist > 32 then return true end

		if anim_time > 0 then
			_self:animate("fly_punch")
			anim_time = anim_time - _self.dtime
		else
			_self:animate("fly")
		end

		if cooldown > 0 then
			goal = goal or _self:get_wander_pos_3d(3, 6, nil, 1)
			cooldown = cooldown - _self.dtime
		else
			goal = nil
			cooldown = 0
		end

		if goal
		and _self:move_to(goal, "waterdragon:fly_simple", 0.25) then
			goal = nil
		end

		if not goal
		and _self:move_to(tgt_pos, "waterdragon:fly_simple", 0.5) then
			if dist < _self.width + 4 then
				_self:punch_target(target)
				cooldown = timeout / 3
				anim_time = anim_len
			end
		end

		timer = timer - _self.dtime
	end
	self:set_action(func)
end

function waterdragon.action_pursue(self, target, timeout, method, speed_factor, anim)
	local timer = timeout or 4
	local goal
	local function func(_self)
		local target_alive, line_of_sight, tgt_pos = _self:get_target(target)
		if not target_alive then
			return true
		end
		self.head_tracking = target
		local pos = _self.object:get_pos()
		if not pos then return end
		timer = timer - _self.dtime
		if timer <= 0 then return true end
		if not goal
		or (line_of_sight
		and vec_dist(goal, tgt_pos) > 3) then
			goal = tgt_pos
		end
		if timer <= 0
		or _self:move_to(goal, method or "creatura:obstacle_avoidance", speed_factor or 0.5) then
			_self:halt()
			return true
		end
		_self:animate(anim or "walk")
	end
	self:set_action(func)
end

function waterdragon.action_fly(self, pos2, timeout, method, speed_factor, anim)
	local timer = timeout or 4
	local function func(_self)
		timer = timer - _self.dtime
		if timer <= 0
		or _self:move_to(pos2, method or "waterdragon:fly_simple", speed_factor) then
			return true
		end
		_self:animate(anim or "fly")
	end
	self:set_action(func)
end

function waterdragon.action_hover(self, time)
	local timer = time or 3
	local function func(_self)
		_self:set_gravity(0)
		_self:set_forward_velocity(0)
		_self:set_vertical_velocity(0)
		_self:animate("hover")
		timer = timer - _self.dtime
		if timer <= 0 then
			return true
		end
	end
	self:set_action(func)
end

function waterdragon.action_idle_pure_water(self, target, time)
	local timer = time
	local start_angle = rad(45)
	local end_angle = rad(-45)
	if random(2) < 2 then
		start_angle = rad(-45)
		end_angle = rad(45)
	end
	local function func(_self)
		_self.head_tracking = nil
		local pos = _self.object:get_pos()
		if not pos then return true end
		local tgt_pos = target:get_pos()
		if not tgt_pos then return true end
		local dir = vec_dir(pos, tgt_pos)
		local dist = vec_dist(pos, tgt_pos)
		local yaw = _self.object:get_yaw()
		local yaw_to_tgt = minetest.dir_to_yaw(dir) + start_angle
		start_angle = start_angle + (end_angle - start_angle) * _self.dtime
		if abs(diff(yaw, yaw_to_tgt)) > 0.5 then
			_self:turn_to(minetest.dir_to_yaw(dir), 4)
		end
		local aim_dir = yaw2dir(yaw_to_tgt)
		aim_dir.y = dir.y
		tgt_pos = vec_add(pos, vec_multi(aim_dir, dist + 10))
		_self:move_head(yaw_to_tgt, aim_dir.y)
		_self:set_gravity(-9.8)
		_self:halt()
		_self:animate("stand_water")
		_self:breath_attack(tgt_pos)
		timer = timer - _self.dtime
		if timer <= 0
		or math.abs(end_angle - start_angle) < 0.1 then
			return true
		end
	end
	self:set_action(func)
end

function waterdragon.action_hover_pure_water(self, target, time)
	local timer = time
	local start_angle = rad(45)
	local end_angle = rad(-45)
	if random(2) < 2 then
		start_angle = rad(-45)
		end_angle = rad(45)
	end
	local function func(_self)
		_self.head_tracking = nil
		local pos = _self.object:get_pos()
		if not pos then return end
		local tgt_pos = target:get_pos()
		if not tgt_pos then return true end
		local dir = vec_dir(pos, tgt_pos)
		local dist = vec_dist(pos, tgt_pos)
		local yaw = _self.object:get_yaw()
		local yaw_to_tgt = minetest.dir_to_yaw(dir) + start_angle
		start_angle = start_angle + (end_angle - start_angle) * _self.dtime
		if abs(diff(yaw, yaw_to_tgt)) > 0.5 then
			_self:turn_to(minetest.dir_to_yaw(dir), 4)
		end
		local aim_dir = yaw2dir(yaw_to_tgt)
		aim_dir.y = dir.y
		tgt_pos = vec_add(pos, vec_multi(aim_dir, dist + 10))
		_self:move_head(yaw_to_tgt, aim_dir.y)
		_self:set_gravity(0)
		_self:set_forward_velocity(-2)
		_self:set_vertical_velocity(0.5)
		_self:animate("hover_pure_water")
		_self:breath_attack(tgt_pos)
		timer = timer - _self.dtime
		if timer <= 0
		or math.abs(end_angle - start_angle) < 0.1 then
			return true
		end
	end
	self:set_action(func)
end

local function can_takeoff(self, pos)
	local height = self.height
	local pos2 = {
		x = pos.x,
		y = pos.y + height + 0.5,
		z = pos.z
	}
	if not moveable(pos2, self.width, height) then
		return false
	end
	return true
end

function waterdragon.action_takeoff(self, tgt_height)
	local init = false
	local height
	local anim = self.animations["takeoff"]
	local anim_time = (anim.range.y - anim.range.x) / anim.speed
	local timer = anim_time
	tgt_height = tgt_height or 4
	local function func(_self)
		local pos = _self.object:get_pos()
		if not pos then return end
		timer = timer - _self.dtime
		if timer <= 0 then
			_self:animate("hover")
			_self:set_vertical_velocity(0)
			return true
		end
		if not init then
			height = pos.y
			init = true
			_self:animate("takeoff")
		end
		local height_diff = pos.y - height
		if height_diff < tgt_height
		and timer < anim_time * 0.5 then
			_self:set_forward_velocity(0)
			_self:set_vertical_velocity(anim_time * tgt_height)
			_self:set_gravity(0)
		end
	end
	self:set_action(func)
end

function waterdragon.action_land(self)
	local init = false
	local anim = self.animations["land"]
	local anim_time = (anim.range.y - anim.range.x) / anim.speed
	local timer = anim_time * 0.5
	local function func(_self)
		if not init then
			-- Apply gravity
			_self:set_gravity(-9.8)
			-- Begin Animation
			_self.object:set_yaw(_self.object:get_yaw())
			_self:animate("land")
			init = true
		end
		timer = timer - _self.dtime
		if timer <= 0 then
			return true
		end
	end
	self:set_action(func)
end

-- Close-range Attacks

function waterdragon.action_slam(self)
	local anim = self.animations["slam"]
	local anim_time = (anim.range.y - anim.range.x) / anim.speed
	local timeout = anim_time
	local damage_init = false
	local scale = self.growth_scale
	self:set_gravity(-9.8)
	self:halt()
	local function func(_self)
		local yaw = _self.object:get_yaw()
		local pos = _self.object:get_pos()
		if not pos then return end
		_self:animate("slam")
		timeout = timeout - _self.dtime
		if timeout < anim_time * 0.5
		and not damage_init then
			_self.alert_timer = 15
			local terrain_dir
			local aoe_center = vec_add(pos, vec_multi(yaw2dir(yaw), _self.width))
			local affected_objs = minetest.get_objects_inside_radius(aoe_center, 8 * scale)
			for _, object in ipairs(affected_objs) do
				local tgt_pos = object and object ~= self.object and object:get_pos()
				if tgt_pos then
					local ent = object:get_luaentity()
					local is_player = object:is_player()
					if (creatura.is_alive(ent)
					and not ent._ignore)
					or is_player then
						local dir = vec_dir(pos, tgt_pos)
						terrain_dir = terrain_dir or dir
						local vel = {
							x = dir.x * _self.damage,
							y = dir.y * _self.damage * 0.5,
							z = dir.z * _self.damage
						}
						object:add_velocity(vel)
						_self:punch_target(object, _self.damage)
					end
				end
			end
			if terrain_dir then
				self:destroy_terrain(terrain_dir)
			end
			minetest.sound_play("waterdragon_slam", {
				object = _self.object,
				gain = 1.0,
				max_hear_distance = 64,
				loop = false,
			})
			damage_init = true
		end
		if timeout <= 0 then self:animate("stand") return true end
	end
	self:set_action(func)
end

function waterdragon.action_repel(self)
	local anim = self.animations["repel"]
	local anim_time = (anim.range.y - anim.range.x) / anim.speed
	local timeout = anim_time
	local damage_init = false
	local scale = self.growth_scale
	self:set_gravity(-9.8)
	self:halt()
	minetest.sound_play("waterdragon_repel", {
		object = self.object,
		gain = 1.0,
		max_hear_distance = 64,
		loop = false,
	})
	local function func(_self)
		local yaw = _self.object:get_yaw()
		local pos = _self.object:get_pos()
		if not pos then return end
		_self:animate("repel")
		timeout = timeout - _self.dtime
		if timeout < anim_time * 0.7
		and not damage_init then
			_self.alert_timer = 15
			local aoe_center = vec_add(pos, vec_multi(yaw2dir(yaw), _self.width))
			local affected_objs = minetest.get_objects_inside_radius(aoe_center, 8 * scale)
			for _, object in ipairs(affected_objs) do
				local tgt_pos = object and object ~= self.object and object:get_pos()
				if tgt_pos then
					local ent = object:get_luaentity()
					local is_player = object:is_player()
					if (creatura.is_alive(ent)
					and not ent._ignore)
					or is_player then
						local dir = vec_dir(pos, tgt_pos)
						local vel = {
							x = dir.x * _self.damage * 1.5,
							y = dir.y * _self.damage * 2,
							z = dir.z * _self.damage * 1.5
						}
						object:add_velocity(vel)
					end
				end
			end
			damage_init = true
		end
		if timeout <= 0 then self:animate("stand") return true end
	end
	self:set_action(func)
end

function waterdragon.action_punch(self)
	local anim = self.animations["bite"]
	local anim_time = (anim.range.y - anim.range.x) / anim.speed
	local timeout = anim_time
	local damage_init = false
	self:set_gravity(-9.8)
	self:halt()
	local function func(_self)
		local yaw = _self.object:get_yaw()
		local pos = _self.object:get_pos()
		if not pos then return end
		_self:animate("bite")
		timeout = timeout - _self.dtime
		if timeout < anim_time * 0.5
		and not damage_init then
			_self.alert_timer = 15
			local aoe_center = vec_add(pos, vec_multi(yaw2dir(yaw), _self.width))
			local affected_objs = minetest.get_objects_inside_radius(aoe_center, 2)
			for _, object in ipairs(affected_objs) do
				local tgt_pos = object and object ~= self.object and object:get_pos()
				if tgt_pos then
					local ent = object:get_luaentity()
					local is_player = object:is_player()
					if (creatura.is_alive(ent)
					and not ent._ignore)
					or is_player then
						_self:punch_target(object, _self.damage)
					end
				end
			end
			damage_init = true
		end
		if timeout <= 0 then self:animate("stand") return true end
	end
	self:set_action(func)
end

--------------
-- Behavior --
--------------


-- Sleep
creatura.register_utility("waterdragon:sleep", function(self)
	local function func(_self)
		if not _self:get_action() then
			_self.object:set_yaw(_self.object:get_yaw())
			creatura.action_idle(_self, 3, "sleep")
		end
	end
	self:set_utility(func)
end)

-- Wander

creatura.register_utility("waterdragon:wander", function(self)
	local center = self.object:get_pos()
	if not center then return end
	local function func(_self)
		if not _self:get_action() then
			local move = random(5) < 2
			if move then
				local pos2 = _self:get_wander_pos(3, 6)
				if vec_dist(pos2, center) > 16 then
					creatura.action_idle(_self, random(2, 5))
				else
					creatura.action_move(_self, pos2, 4, "creatura:obstacle_avoidance", 0.5)
				end
			else
				creatura.action_idle(_self, random(2, 5))
			end
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("waterdragon:die", function(self)
	local timer = 1.5
	local init = false
	local function func(_self)
		if not init then
			_self:play_sound("death")
			creatura.action_fallover(_self)
			init = true
		end
		timer = timer - _self.dtime
		if timer <= 0 then
			local pos = _self.object:get_pos()
			if not pos then return end
			minetest.add_particlespawner({
				amount = 8,
				time = 0.25,
				minpos = {x = pos.x - 0.1, y = pos.y, z = pos.z - 0.1},
				maxpos = {x = pos.x + 0.1, y = pos.y + 0.1, z = pos.z + 0.1},
				minacc = {x = 0, y = 2, z = 0},
				maxacc = {x = 0, y = 3, z = 0},
				minvel = {x = random(-1, 1), y = -0.25, z = random(-1, 1)},
				maxvel = {x = random(-2, 2), y = -0.25, z = random(-2, 2)},
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
			creatura.drop_items(_self)
			_self.object:remove()
		end
	end
	self:set_utility(func)
end)

-- Wander Flight

creatura.register_utility("waterdragon:aerial_wander", function(self, speed_x)
	local center = self.object:get_pos()
	if not center then return end
	local height_timer = 0
	local function func(_self)
		local pos = _self.object:get_pos()
		if not pos then return end
		height_timer = height_timer - self.dtime
		if height_timer <= 0 then
			local dist2floor = creatura.sensor_floor(_self, 10, true)
			center.y = center.y + (10 - dist2floor)
			height_timer = 4
		end
		if _self.nest_pos
		and vec_dist(pos, _self.nest_pos) > 128 then
			center = _self.nest_pos
		end
		if not _self:get_action() then
			local move_dir = (vec_dist(pos, center) > 56 * speed_x and vec_dir(pos, center)) or nil
			local pos2 = _self:get_wander_pos_3d(ceil(8 * speed_x), ceil(12 * speed_x), move_dir)
			creatura.action_move(_self, pos2, 3, "waterdragon:fly_simple", speed_x or 0.5, "fly")
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("waterdragon:fly_and_roost", function(self, speed_x)
	local center = self.nest_position or self.object:get_pos()
	if not center then return end
	local center_fly = {x = center.x, y = center.y + 12, z = center.z}
	local dist2floor = creatura.sensor_floor(self, 10, true)
	center.y = center.y - dist2floor
	local is_landed = true
	local landing = (dist2floor > 4 and true) or false
	local state_timer = random(10, 120)
	speed_x = speed_x or 0.75
	local function func(_self)
		local pos = self.object:get_pos()
		if not pos then return end
		state_timer = state_timer - _self.dtime
		if not self:get_action() then
			-- Change States
			if state_timer <= 0 then
				state_timer = random(10, 120)
				is_landed = not is_landed
				if is_landed then
					landing = true
				else
					waterdragon.action_takeoff(self, 3)
					return
				end
			end
			-- Land
			if landing then
				local pos2 = _self:get_wander_pos_3d(3, 6)
				if _self.touching_ground then
					waterdragon.action_land(self)
					landing = false
				else
					dist2floor = creatura.sensor_floor(_self, 10, true)
					pos2.y = pos2.y - dist2floor
					creatura.action_move(_self, pos2, 3, "waterdragon:fly_simple", 0.6, "fly")
					--_self:animate("fly")
				end
				return
			end
			-- Wander
			if is_landed then
				if random(5) < 2 then
					local pos2 = _self:get_wander_pos(3, 6)
					if vec_dist(pos2, center) > 16 then
						creatura.action_idle(_self, random(2, 5))
					else
						creatura.action_move(_self, pos2, 4, "creatura:obstacle_avoidance", 0.5)
					end
				else
					creatura.action_idle(_self, random(2, 5))
				end
			else
				local pos2 = _self:get_wander_pos_3d(ceil(8 * speed_x), ceil(12 * speed_x), vec_dir(pos, center_fly))
				creatura.action_move(_self, pos2, 3, "waterdragon:fly_simple", speed_x or 0.5, "fly")
			end
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("waterdragon:fly_to_land", function(self)
	local landed = false
	local function func(_self)
	minetest.log("action", "inside fly to land")
		if not _self:get_action() then
			if landed then return true end
			if _self.touching_ground then
				waterdragon.action_land(_self)
				landed = true
			else
				local pos2 = _self:get_wander_pos_3d(3, 6)
				if pos2 then
					local dist2floor = creatura.sensor_floor(_self, 10, true)
					pos2.y = pos2.y - dist2floor
					creatura.action_move(_self, pos2, 3, "waterdragon:fly_simple", 0.6, "fly")
					_self:animate("fly")
				end
			end
		end
	end
	self:set_utility(func)
end)


-- Attack

creatura.register_utility("waterdragon:attack", function(self, target)
	local is_landed = true
	local init = false
	local takeoff_init = false
	local land_init = false
	local fov_timer = 0
	local switch_timer = 20
	local function func(_self)
		local target_alive, _, tgt_pos = _self:get_target(target)
		if not target_alive then _self._target = nil return true end
		local pos = _self.object:get_pos()
		local yaw = _self.object:get_yaw()
		if not pos then return end
		local yaw2tgt = dir2yaw(vec_dir(pos, tgt_pos))
		if abs(diff(yaw, yaw2tgt)) > 0.3 then
			fov_timer = fov_timer + _self.dtime
		end
		switch_timer = switch_timer - _self.dtime
		if not self:get_action() then

			-- Decide to attack from ground or air
			if not init then
				local dist2floor = creatura.sensor_floor(_self, 7, true)
				if dist2floor > 6
				or is_target_flying(target) then -- Fly if too far from ground
					is_landed = false
				end
				init = true
			elseif switch_timer <= 0 then
				local switch_chance = (is_landed and 6) or 3
				is_landed = random(switch_chance) > 1
				takeoff_init = not is_landed
				land_init = is_landed
				switch_timer = 20
			end

			-- Land if flying while in landed state
			if land_init then
				if not self.touching_ground then
					local pos2 = tgt_pos
					if is_target_flying(target) then
						pos2 = {x = pos.x, y = pos.y - 7, z = pos.z}
					end
					creatura.action_move(_self, pos2, 3, "waterdragon:fly_simple", 1, "fly")
				else
					waterdragon.action_land(self)
					land_init = false
				end
				return
			end

			-- Takeoff if walking while in flying state
			if takeoff_init
			and self.touching_ground then
				waterdragon.action_takeoff(self)
				takeoff_init = false
				return
			end

			-- Choose Attack
			local dist = vec_dist(pos, tgt_pos)
			local attack_range = (is_landed and 8) or 16
			if dist <= attack_range then -- Close-range Attacks
				if is_landed then
					if fov_timer < 1
					and target:is_player() then
						waterdragon.action_repel(_self, target)
					else
						waterdragon.action_slam(_self, target)
						is_landed = false
						fov_timer = 0
					end
				else
					if random(3) < 2 then
						waterdragon.action_flight_pure_water(_self, target, 12)
					else
						waterdragon.action_hover_pure_water(_self, target, 3)
					end
				end
			else
				if is_landed then
					waterdragon.action_pursue(_self, target, 2, "creatura:obstacle_avoidance", 0.75, "walk_slow")
				else
					tgt_pos.y = tgt_pos.y + 14
					creatura.action_move(_self, tgt_pos, 5, "waterdragon:fly_simple", 1, "fly")
				end
			end
		end
	end
	self:set_utility(func)
end)

-- Tamed Behavior --

creatura.register_utility("waterdragon:stay", function(self)
	local function func(_self)
		local order = _self.order
		if not order
		or order ~= "stay" then
			return true
		end
		if not _self:get_action() then
			creatura.action_idle(_self, 2, "stand")
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("waterdragon:follow_player", function(self, player)
	local function func(_self)
		local order = _self.order
		if not order
		or order ~= "follow" then
			return true
		end
		if not player then
			return true
		end
		local scale = _self.growth_scale or 1
		local pos = _self.object:get_pos()
		if not pos then return end
		local tgt_pos = player:get_pos()
		if not tgt_pos then _self.order = "stay" return true end
		local dist = vec_dist(pos, tgt_pos)
		local dist_to_ground = creatura.sensor_floor(_self, 8, true)
		if not _self:get_action() then
			if dist < clamp(8 * scale, 2, 12) then
				if dist_to_ground > 2 then
					waterdragon.action_hover(_self, 2, "hover")
				else
					creatura.action_idle(_self, 2, "stand")
				end
			else
				local height_diff = tgt_pos.y - pos.y
				if (height_diff > 8
				or dist_to_ground > 2)
				or not self.flight_allowed then
					creatura.action_move(_self, tgt_pos, 2, "waterdragon:fly_simple", 1, "fly")
				else
					creatura.action_move(_self, tgt_pos, 3, "creatura:context_based_steering", 0.5, "walk")
				end
			end
		end
	end
	self:set_utility(func)
end)

-- Utility Stack --

waterdragon.dragon_behavior = {
	{ -- Wander
		utility = "waterdragon:fly_and_roost",
		get_score = function(self)
			return 0.1, {self}
		end
	},
	{ -- Attack
		utility = "waterdragon:attack",
		get_score = function(self)
			local pos = self.object:get_pos()
			if not pos then return end
			local stance = (self.owner and self.stance) or "aggressive"
			local skip = self.age < 20 or stance == "passive"
			if skip then return 0 end -- Young/Passive Water Dragons don't attack
			local target = self._target
			if not target then
				if stance ~= "aggressive" then return 0 end -- Neutral Water Dragons with no set target
				local target_list = waterdragon[self.name:split(":")[2] .. "_targets"]
				target = find_target(self, target_list)
				if not target or not target:get_pos() then return 0 end
				local is_far = self.nest_pos and vec_dist(target:get_pos(), self.nest_pos) > 192
				if is_far
				or self._ignore_obj[target]
				or shared_owner(self, target) then
					self._target = nil
					return 0
				end
			end
			local scale = self.growth_scale
			local dist2floor = creatura.sensor_floor(self, 3, true)
			if not self.owner
			and dist2floor < 3
			and target:get_pos()
			and vec_dist(pos, target:get_pos()) > 48 * scale
			and self.alert_timer <= 0 then
				-- Wild Dragons sleep until approached
				self._target = nil
				return 0
			end
			local name = target:is_player() and target:get_player_name()
			if name then
				local inv = minetest.get_inventory({type = "player", name = name})
				if waterdragon.contains_book(inv) then
					waterdragon.add_page(inv, "waterdragons")
				end
			end
			self._target = target
			return 0.9, {self, target}
		end
	},
	{ -- Sleep
		utility = "waterdragon:sleep",
		get_score = function(self)
			if self.owner then
				if is_night then
					return 0.2, {self}
				end
				return 0
			end
			if self.alert_timer > 0 then return 0 end
			if self.touching_ground
			and not self._target then
				return 0.7, {self}
			end
			return 0
		end
	},
	{ -- Stay (Order)
		utility = "waterdragon:stay",
		get_score = function(self)
			if not self.owner then return 0 end
			local order = self.order
			if order == "stay" then
				return 1, {self}
			end
			return 0
		end
	},
	{ -- Follow (Order)
		utility = "waterdragon:follow_player",
		get_score = function(self)
			if not self.owner then return 0 end
			local owner = minetest.get_player_by_name(self.owner)
			if not owner then return 0 end
			local order = self.order
			if order == "follow" then
				local stance = self.stance
				local score = 1
				if stance == "aggressive"
				or stance == "neutral"
				and self.owner_target then
					score = 0.8
				end
				return score, {self, owner}
			end
			return 0
		end
	},
	{ -- Mounted
		utility = "waterdragon:mount",
		get_score = function(self)
			if not self.owner
			or not self.rider
			or not self.rider:get_look_horizontal() then return 0 end
			return 1, {self}
		end
	}
}

