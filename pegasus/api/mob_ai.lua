------------
-- Mob AI --
------------

-- Math --

local abs = math.abs
local atan2 = math.atan2
local cos = math.cos
local min = math.min
local max = math.max
local floor = math.floor
local pi = math.pi
local pi2 = pi * 2
local sin = math.sin
local rad = math.rad
local random = math.random

local function diff(a, b) -- Get difference between 2 angles
	return atan2(sin(b - a), cos(b - a))
end

local function clamp(val, minn, maxn)
	if val < minn then
		val = minn
	elseif maxn < val then
		val = maxn
	end
	return val
end

-- Vector Math --

local vec_add, vec_dot, vec_dir, vec_dist, vec_multi, vec_normal,
	vec_round, vec_sub = vector.add, vector.dot, vector.direction, vector.distance,
	vector.multiply, vector.normalize, vector.round, vector.subtract

local dir2yaw = minetest.dir_to_yaw
local yaw2dir = minetest.yaw_to_dir

-----------------
-- Local Tools --
-----------------

local farming_enabled = minetest.get_modpath("farming") and farming.registered_plants

if farming_enabled then
	minetest.register_on_mods_loaded(function()
		for name, def in pairs(minetest.registered_nodes) do
			local item_string = name:sub(1, #name - 2)
			local item_name = item_string:split(":")[2]
			local growth_stage = tonumber(name:sub(-1)) or 1
			if farming.registered_plants[item_string]
			or farming.registered_plants[item_name] then
				def.groups.crop = growth_stage
			end
			minetest.register_node(":" .. name, def)
		end
	end)
end

local animate_player = {}

if minetest.get_modpath("default")
and minetest.get_modpath("player_api") then
	animate_player = player_api.set_animation
elseif minetest.get_modpath("mcl_player") then
	animate_player = mcl_player.player_set_animation
end

local function get_group_positions(self)
	local objects = creatura.get_nearby_objects(self, self.name)
	local group = {}
	for _, object in ipairs(objects) do
		local obj_pos = object and object:get_pos()
		if obj_pos then table.insert(group, obj_pos) end
	end
	return group
end

local function calc_altitude(self, pos2)
	local height_half = self.height * 0.5
	local center_y = pos2.y + height_half
	local calc_pos = {x = pos2.x, y = center_y, z = pos2.z}
	local range = (height_half + 2)
	local offset = {x = 0, y = range, z = 0}
	local ceil_pos, floor_pos = vec_add(calc_pos, offset), vec_sub(calc_pos, offset)
	local ray_up = minetest.raycast(calc_pos, ceil_pos, false, true):next()
	local ray_down = minetest.raycast(calc_pos, floor_pos, false, true):next()
	ceil_pos = (ray_up and ray_up.above) or ceil_pos
	floor_pos = (ray_down and ray_down.above) or floor_pos

	local dist_up = ceil_pos.y - center_y
	local dist_down = floor_pos.y - center_y

	local altitude = (dist_up + dist_down) / 2

	return ((calc_pos.y + altitude) - center_y) / range * 2
end

--[[local function calc_steering_and_lift(self, pos, pos2, dir, steer_method)
	local steer_to = creatura.calc_steering(self, pos2, steer_method or creatura.get_context_small)
	pos2 = vec_add(pos, steer_to)
	local lift = creatura.get_avoidance_lift(self, pos2, 2)
	steer_to.y = (lift ~= 0 and lift) or dir.y
	return steer_to
end

local function calc_steering_and_lift_aquatic(self, pos, pos2, dir, steer_method)
	local steer_to = creatura.calc_steering(self, pos2, steer_method or creatura.get_context_small_aquatic)
	local lift = creatura.get_avoidance_lift_aquatic(self, vec_add(pos, steer_to), 2)
	steer_to.y = (lift ~= 0 and lift) or dir.y
	return steer_to
end]]

local function get_obstacle(pos, water)
	local pos2 = {x = pos.x, y = pos.y, z = pos.z}
	local n_def = creatura.get_node_def(pos2)
	if n_def.walkable
	or (water and (n_def.groups.liquid or 0) > 0) then
		pos2.y = pos.y + 1
		n_def = creatura.get_node_def(pos2)
		local col_max = n_def.walkable or (water and (n_def.groups.liquid or 0) > 0)
		pos2.y = pos.y - 1
		local col_min = col_max and (n_def.walkable or (water and (n_def.groups.liquid or 0) > 0))
		if col_min then
			return pos
		else
			pos2.y = pos.y + 1
			return pos2
		end
	end
end

function pegasus.get_steering_context(self, goal, steer_dir, interest, danger, range)
	local pos = self.object:get_pos()
	if not pos then return end
	pos = vec_round(pos)
	local width = self.width or 0.5

	local check_pos = vec_add(pos, steer_dir)
	local collision = get_obstacle(check_pos)
	local unsafe_pos = not collision and not self:is_pos_safe(check_pos) and check_pos

	if collision
	or unsafe_pos then
		local dir2goal = vec_normal(vec_dir(pos, goal))
		local dir2col = vec_normal(vec_dir(pos, collision or unsafe_pos))
		local dist2col = vec_dist(pos, collision or unsafe_pos) - width
		local dot_score = vec_dot(dir2col, dir2goal)
		local dist_score = (range - dist2col) / range
		interest = interest - dot_score
		danger = dist_score
	end
	return interest, danger
end

--------------
-- Movement --
--------------

-- Obstacle Avoidance

function pegasus.obstacle_avoidance(self, goal, water)
	local steer_method = water and creatura.get_context_small_aquatic or pegasus.get_steering_context
	local dir = creatura.calc_steering(self, goal, steer_method)

	local lift_method = water and creatura.get_avoidance_lift_aquatic or creatura.get_avoidance_lift
	local lift = lift_method(self, vec_add(self.stand_pos, dir), 2)
	dir.y = (lift ~= 0 and lift) or dir.y

	return dir
end

-- Methods

creatura.register_movement_method("pegasus:fly_wide", function(self)
	local steer_to
	local steer_int = 0
	self:set_gravity(0)
	local function func(_self, goal, speed_factor)
		local pos = _self.object:get_pos()
		if not pos or not goal then return end
		if vec_dist(pos, goal) < clamp(self.width, 0.5, 1) then
			_self:halt()
			return true
		end
		-- Calculate Movement
		local turn_rate = 2.5
		local speed = abs(_self.speed or 2) * speed_factor or 0.5
		steer_int = (steer_int > 0 and steer_int - _self.dtime) or 1 / max(speed, 1)
		steer_to = (steer_int <= 0 and creatura.calc_steering(_self, goal)) or steer_to
		local dir = steer_to or vec_dir(pos, goal)
		local altitude = calc_altitude(self, vec_add(pos, dir))
		dir.y = (altitude ~= 0 and altitude) or dir.y

		if vec_dot(dir, yaw2dir(_self.object:get_yaw())) > 0.2 then -- Steer faster for major obstacles
			turn_rate = 5
		end
		-- Apply Movement
		_self:turn_to(dir2yaw(dir), turn_rate)
		_self:set_forward_velocity(speed)
		_self:set_vertical_velocity(speed * dir.y)
	end
	return func
end)

-- Steering Methods

creatura.register_movement_method("pegasus:steer", function(self)
	local steer_to
	local steer_int = 0

	local radius = 2 -- Arrival Radius

	self:set_gravity(-9.8)
	local function func(_self, goal, speed_factor)
		-- Vectors
		local pos = self.object:get_pos()
		if not pos or not goal then return end

		local dist = vec_dist(pos, goal)
		local dir = vec_dir(pos, goal)

		-- Movement Params
		local vel = self.speed * speed_factor
		local turn_rate = self.turn_rate
		local mag = min(radius - ((radius - dist) / 1), 1)
		vel = vel * mag

		-- Steering
		steer_int = (steer_int > 0 and steer_int - _self.dtime) or 1 / max(vel, 1)
		steer_to = steer_int <= 0 and pegasus.obstacle_avoidance(_self, goal) or steer_to

		-- Apply Movement
		_self:turn_to(minetest.dir_to_yaw(steer_to or dir), turn_rate)
		_self:set_forward_velocity(vel)
	end
	return func
end)

creatura.register_movement_method("pegasus:steer_no_gravity", function(self)
	local steer_to
	local steer_int = 0

	local radius = 2 -- Arrival Radius

	self:set_gravity(0)
	local function func(_self, goal, speed_factor)
		-- Vectors
		local pos = self.object:get_pos()
		if not pos or not goal then return end

		local dist = vec_dist(pos, goal)
		local dir = vec_dir(pos, goal)

		-- Movement Params
		local vel = self.speed * speed_factor
		local turn_rate = self.turn_rate
		local mag = min(radius - ((radius - dist) / 1), 1)
		vel = vel * mag

		-- Steering
		steer_int = (steer_int > 0 and steer_int - _self.dtime) or 1 / max(vel, 1)
		steer_to = steer_int <= 0 and pegasus.obstacle_avoidance(_self, goal, _self.max_breath == 0) or steer_to

		-- Apply Movement
		_self:turn_to(minetest.dir_to_yaw(steer_to or dir), turn_rate)
		_self:set_forward_velocity(vel)
		_self:set_vertical_velocity(dir.y * vel)
	end
	return func
end)

-- Simple Methods

creatura.register_movement_method("pegasus:move", function(self)
	local radius = 2 -- Arrival Radius

	self:set_gravity(-9.8)
	local function func(_self, goal, speed_factor)
		-- Vectors
		local pos = self.object:get_pos()
		if not pos or not goal then return end

		local dist = vec_dist(pos, goal)
		local dir = vec_dir(pos, goal)

		-- Movement Params
		local vel = self.speed * speed_factor
		local turn_rate = self.turn_rate
		local mag = min(radius - ((radius - dist) / 1), 1)
		vel = vel * mag

		-- Apply Movement
		_self:turn_to(minetest.dir_to_yaw(dir), turn_rate)
		_self:set_forward_velocity(vel)
	end
	return func
end)

creatura.register_movement_method("pegasus:move_no_gravity", function(self)
	local radius = 2 -- Arrival Radius

	self:set_gravity(0)
	local function func(_self, goal, speed_factor)
		-- Vectors
		local pos = self.object:get_pos()
		if not pos or not goal then return end

		local dist = vec_dist(pos, goal)
		local dir = vec_dir(pos, goal)

		-- Movement Params
		local vel = self.speed * speed_factor
		local turn_rate = self.turn_rate
		local mag = min(radius - ((radius - dist) / 1), 1)
		vel = vel * mag

		-- Apply Movement
		_self:turn_to(minetest.dir_to_yaw(dir), turn_rate)
		_self:set_forward_velocity(vel)
		_self:set_vertical_velocity(vel * dir.y)
	end
	return func
end)

-------------
-- Actions --
-------------

function pegasus.action_walk(self, time, speed, animation, pos2)
	local timeout = time or 3
	local speed_factor = speed or 0.5
	local anim = animation or "walk"

	local wander_radius = 2

	local dir = pos2 and vec_dir(self.stand_pos, pos2)
	local function func(mob)
		local pos, yaw = mob.object:get_pos(), mob.object:get_yaw()
		if not pos or not yaw then return true end

		dir = pos2 and vec_dir(pos, pos2) or minetest.yaw_to_dir(yaw)

		local wander_point = vec_add(pos, vec_multi(dir, wander_radius + 0.5))
		local goal = vec_add(wander_point, vec_multi(minetest.yaw_to_dir(random(pi2)), wander_radius))

		local safe = true

		if mob.max_fall then
			safe = mob:is_pos_safe(goal)
		end

		if timeout <= 0
		or not safe
		or mob:move_to(goal, "pegasus:steer", speed_factor) then
			mob:halt()
			return true
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then return true end

		mob:animate(anim)
	end
	self:set_action(func)
end

function pegasus.action_swim(self, time, speed, animation, pos2)
	local timeout = time or 3
	local speed_factor = speed or 0.5
	local anim = animation or "swim"

	local wander_radius = 2

	local function func(mob)
		local pos, yaw = mob.object:get_pos(), mob.object:get_yaw()
		if not pos or not yaw then return true end

		if not mob.in_liquid then return true end

		local steer_direction = pos2 and vec_dir(pos, pos2)

		if not steer_direction then
			local wander_point = {
				x = pos.x + -sin(yaw) * (wander_radius + 0.5),
				y = pos.y,
				z = pos.z + cos(yaw) * (wander_radius + 0.5)
			}
			local wander_angle = random(pi2)

			steer_direction = vec_dir(pos, {
				x = wander_point.x + -sin(wander_angle) * wander_radius,
				y = wander_point.y + (random(-10, 10) / 10),
				z = wander_point.z + cos(wander_angle) * wander_radius
			})
		end

		-- Boids
		local boid_dir = mob.uses_boids and creatura.get_boid_dir(mob)
		if boid_dir then
			steer_direction = {
				x = (steer_direction.x + boid_dir.x) / 2,
				y = (steer_direction.y + boid_dir.y) / 2,
				z =	(steer_direction.z + boid_dir.z) / 2
			}
		end

		local goal = vec_add(pos, vec_multi(steer_direction, mob.width + 2))

		if timeout <= 0
		or mob:move_to(goal, "pegasus:steer_no_gravity", speed_factor) then
			mob:halt()
			return true
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then return true end

		mob:animate(anim)
	end
	self:set_action(func)
end

function pegasus.action_fly(self, time, speed, animation, pos2, turn)
	local timeout = time or 3
	local speed_factor = speed or 0.5
	local anim = animation or "fly"
	local turn_rate = turn or 1.5

	local wander_radius = 2

	local function func(mob)
		local pos, yaw = mob.object:get_pos(), mob.object:get_yaw()
		if not pos or not yaw then return true end

		local steer_direction = pos2 and vec_dir(pos, pos2)

		if not steer_direction then
			local wander_point = {
				x = pos.x + -sin(yaw) * (wander_radius + turn_rate),
				y = pos.y,
				z = pos.z + cos(yaw) * (wander_radius + turn_rate)
			}
			local wander_angle = random(pi2)

			steer_direction = vec_dir(pos, {
				x = wander_point.x + -sin(wander_angle) * wander_radius,
				y = wander_point.y + (random(-10, 10) / 10) * turn_rate,
				z = wander_point.z + cos(wander_angle) * wander_radius
			})
		end

		-- Boids
		local boid_dir = mob.uses_boids and creatura.get_boid_dir(mob)
		if boid_dir then
			steer_direction = {
				x = (steer_direction.x + boid_dir.x) / 2,
				y = (steer_direction.y + boid_dir.y) / 2,
				z =	(steer_direction.z + boid_dir.z) / 2
			}
		end

		local goal = vec_add(pos, vec_multi(steer_direction, mob.width + 2))

		if timeout <= 0
		or mob:move_to(goal, "pegasus:steer_no_gravity", speed_factor) then
			mob:halt()
			return true
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then return true end

		mob:animate(anim)
	end
	self:set_action(func)
end

-- Latch to pos
--  if self.animations["latch_ceiling"] then latch to ceiling end
-- 	if self.animations["latch_wall"] then latch to wall end

local latch_ceil_offset = {x = 0, y = 1, z = 0}
local latch_wall_offset = {
	{x = 1, y = 0, z = 0},
	{x = 0, y = 0, z = 1},
	{x = -1, y = 0, z = 0},
	{x = 0, y = 0, z = -1}
}


function pegasus.action_latch(self)
	local pos = self.object:get_pos()
	if not pos then return end

	local ceiling
	if self.animations["latch_ceiling"] then
		ceiling = vec_add(pos, latch_ceil_offset)

		if not creatura.get_node_def(ceiling).walkable then
			ceiling = nil
		end
	end

	local wall
	if self.animations["latch_wall"] then
		for n = 1, 4 do
			wall = vec_add(self.stand_pos, latch_wall_offset[n])

			if creatura.get_node_def(wall).walkable then
				break
			else
				wall = nil
			end
		end
	end
	local function func(mob)
		mob:set_gravity(0)

		if ceiling then
			mob:animate("latch_ceiling")
			mob:set_vertical_velocity(1)
			mob:set_forward_velocity(0)
			return
		end

		if wall then
			mob:animate("latch_wall")
			mob.object:set_yaw(minetest.dir_to_yaw(vec_dir(pos, wall)))
			mob:set_vertical_velocity(0)
			mob:set_forward_velocity(1)
		end
	end
	self:set_action(func)
end

function pegasus.action_pursue(self, target, timeout, method, speed_factor, anim)
	local timer = timeout or 4
	local goal
	local function func(_self)
		local target_alive, line_of_sight, tgt_pos = _self:get_target(target)
		if not target_alive then
			return true
		end
		goal = goal or tgt_pos
		timer = timer - _self.dtime
		self:animate(anim or "walk")
		local safe = true
		if _self.max_fall
		and _self.max_fall > 0 then
			local pos = self.object:get_pos()
			if not pos then return end
			safe = _self:is_pos_safe(goal)
		end
		if line_of_sight
		and vec_dist(goal, tgt_pos) > 3 then
			goal = tgt_pos
		end
		if timer <= 0
		or not safe
		or _self:move_to(goal, method or "creatura:obstacle_avoidance", speed_factor or 0.5) then
			return true
		end
	end
	self:set_action(func)
end

function pegasus.action_melee(self, target)
	local stage = 1
	local is_animated = self.animations["melee"] ~= nil
	local timeout = 1

	local function func(mob)
		local target_pos = target and target:get_pos()
		if not target_pos then return true end

		local pos = mob.stand_pos
		local dist = vec_dist(pos, target_pos)
		local dir = vec_dir(pos, target_pos)

		local anim = is_animated and mob:animate("melee", "stand")

		if stage == 1 then
			mob.object:add_velocity({x = dir.x * 3, y = 2, z = dir.z * 3})

			stage = 2
		end

		if stage == 2
		and dist < mob.width + 1 then
			mob:punch_target(target)
			local knockback = minetest.calculate_knockback(
				target, mob.object, 1.0,
				{damage_groups = {fleshy = mob.damage}},
				dir, 2.0, mob.damage
			)
			target:add_velocity({x = dir.x * knockback, y = dir.y * knockback, z = dir.z * knockback})

			stage = 3
		end

		if stage == 3
		and (not is_animated
		or anim == "stand") then
			return true
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then return true end
	end
	self:set_action(func)
end

function pegasus.action_play(self, target)
	local stage = 1
	local is_animated = self.animations["play"] ~= nil
	local timeout = 1

	local function func(mob)
		local target_pos = target and target:get_pos()
		if not target_pos then return true end

		local pos = mob.stand_pos
		local dist = vec_dist(pos, target_pos)
		local dir = vec_dir(pos, target_pos)

		local anim = is_animated and mob:animate("play", "stand")

		if stage == 1 then
			mob.object:add_velocity({x = dir.x * 3, y = 2, z = dir.z * 3})

			stage = 2
		end

		if stage == 2
		and dist < mob.width + 1 then
			pegasus.add_trust(mob, target, 1)

			stage = 3
		end

		if stage == 3
		and (not is_animated
		or anim == "stand") then
			return true
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then return true end
	end
	self:set_action(func)
end

function pegasus.action_float(self, time, anim)
	local timer = time
	local function func(_self)
		_self:set_gravity(-0.14)
		_self:halt()
		_self:animate(anim or "foat")
		timer = timer - _self.dtime
		if timer <= 0 then
			return true
		end
	end
	self:set_action(func)
end

function pegasus.action_dive_attack(self, target, timeout)
	timeout = timeout or 12
	local timer = timeout
	local width = self.width or 0.5
	local punch_init = false
	local anim
	local function func(_self)
		-- Tick down timers
		timer = timer - _self.dtime
		if timer <= 0 then return true end

		-- Get positions
		local pos = _self.stand_pos
		local tgt_pos = target and target:get_pos()
		if not tgt_pos then return true end
		local dist = vec_dist(pos, tgt_pos)

		if punch_init then
			anim = _self:animate("fly_punch", "fly")
			if anim == "fly" then return true end
		else
			anim = _self:animate("fly")
		end

		if dist > width + 1 then
			local method = "pegasus:move_no_gravity"
			if dist > 4 then
				method = "pegasus:steer_no_gravity"
			end
			_self:move_to(tgt_pos, method, 1)
		elseif not punch_init then
			_self:punch_target(target)
			punch_init = true
		end
	end
	self:set_action(func)
end

-- Behaviors

creatura.register_utility("pegasus:die", function(self)
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
				texture = "creatura_smoke_particle.png",
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

-- Basic --

creatura.register_utility("pegasus:basic_idle", function(self, timeout, anim)
	local timer = timeout or 1
	local init = false
	local function func(mob)
		if not init then
			creatura.action_idle(mob, timeout, anim)
		end
		timer = timer - mob.dtime
		if timer <= 0 then
			return true
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:basic_wander", function(self)
	local idle_max = 4
	local move_chance = 3
	local graze_chance = 16

	--local iter = 1
	local range = self.tracking_range

	local center
	local function func(mob)
		local pos = mob.stand_pos

		if mob:timer(2) then
			--iter = iter < 3 and iter + 1 or 1 -- Iterate to 3, then reset to 1

			-- Grazing Behavior
			if mob.is_grazing_mob
			and random(graze_chance) < 2 then
				local yaw = mob.object:get_yaw()
				if not yaw then return true end

				local turf_pos = {
					x = pos.x + -sin(yaw) * mob.width,
					y = pos.y - 0.5,
					z = pos.z + cos(yaw) * mob.width
				}

				if pegasus.eat_turf(mob, turf_pos) then
					pegasus.add_break_particle(turf_pos)
					creatura.action_idle(mob, 1, "eat")
				end
			end

			-- Herding Behavior
			if mob.is_herding_mob then
				center = pegasus.get_average_pos(get_group_positions(mob)) or pos

				if vec_dist(pos, center) < range / 4 then
					center = false
				end
			end

			-- Skittish Behavior
			if mob.is_skittish_mob then
				local plyr = creatura.get_nearby_player(mob)
				local plyr_alive, los, plyr_pos = mob:get_target(plyr)
				if plyr_alive
				and los then
					center = vec_add(pos, vec_dir(plyr_pos, pos))
				end
			end
		end

		if not mob:get_action() then
			if random(move_chance) < 2 then
				pegasus.action_walk(mob, 3, 0.2, "walk", center)
				center = false
			else
				creatura.action_idle(mob, random(idle_max), "stand")
			end
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:basic_seek_pos", function(self, pos2, timeout)
	timeout = timeout or 3
	local function func(mob)
		local pos = mob.object:get_pos()
		if not pos or not pos2 then return true end

		if not mob:get_action() then
			local anim = (mob.animations["run"] and "run") or "walk"
			pegasus.action_walk(mob, 1, 1, anim, pos2)
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then
			return true
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:basic_seek_food", function(self)
	local timeout = 3

	local food = pegasus.get_dropped_food(self)
	local food_reached = false
	local function func(mob)
		local pos = mob.object:get_pos()
		local food_pos = food and food:get_pos()
		if not pos or not food_pos then return true, 10 end

		local dist = vec_dist(pos, food_pos)
		if dist < mob.width + 0.5
		and not food_reached then
			food_reached = true

			local anim = (mob.animations["eat"] and "eat") or "stand"
			creatura.action_idle(mob, 1, anim)
			pegasus.eat_dropped_item(mob, food)
		end

		if not mob:get_action() then
			if food_reached then return true, 10 end
			local anim = (mob.animations["run"] and "run") or "walk"
			pegasus.action_walk(mob, 1, 1, anim, food_pos)
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then
			return true
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:basic_seek_crop", function(self)
	local timeout = 12

	local crop = pegasus.find_crop(self)
	local crop_reached = false
	local function func(mob)
		local pos = mob.object:get_pos()
		if not pos or not crop then return true, 30 end

		local dist = vec_dist(pos, crop)
		if dist < mob.width + 0.5
		and not crop_reached then
			crop_reached = true

			local anim = (mob.animations["eat"] and "eat") or "stand"
			creatura.action_idle(mob, 1, anim)
			pegasus.eat_crop(mob, crop)
		end

		if not mob:get_action() then
			if crop_reached then return true, 10 end
			pegasus.action_walk(mob, 2, 0.5, "walk", crop)
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then
			return true
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:basic_flee", function(self, target)
	local function func(mob)
		local pos, target_pos = mob.object:get_pos(), target:get_pos()
		if not pos or not target_pos then return true end

		if not mob:get_action() then
			pegasus.action_walk(mob, 0.5, 1, "run", vec_add(pos, vec_dir(target_pos, pos)))
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:basic_attack", function(self, target)
	local has_attacked = false
	local has_warned = not self.warn_before_attack
	local function func(mob)
		local target_alive, _, target_pos = mob:get_target(target)
		if not target_alive then return true end

		local pos = mob.object:get_pos()
		if not pos then return true end

		if not mob:get_action() then
			if has_attacked then return true, 2 end

			local dist = vec_dist(pos, target_pos)

			if dist > mob.width + 1 then
				if not has_warned
				and dist > mob.width + 2 then
					local yaw = mob.object:get_yaw()
					local yaw_to_target = minetest.dir_to_yaw(vec_dir(pos, target_pos))

					if abs(diff(yaw, yaw_to_target)) > pi / 2 then
						pegasus.action_pursue(mob, target)
					else
						creatura.action_idle(mob, 0.5, "warn")
					end
					return
				else
					pegasus.action_pursue(mob, target, 0.5)
				end
			else
				pegasus.action_melee(mob, target)
				has_attacked = true
			end
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:basic_breed", function(self)
	local mate = pegasus.get_nearby_mate(self, self.name)

	local timer = 0
	local function func(mob)
		if not mob.breeding then return true end

		local pos, target_pos = mob.object:get_pos(), mate and mate:get_pos()
		if not pos or not target_pos then return true end

		local dist = vec_dist(pos, target_pos)
		timer = dist < mob.width + 0.5 and timer + mob.dtime or timer

		if timer > 2 then
			local mate_entity = mate:get_luaentity()

			mob.breeding = mob:memorize("breeding", false)
			mob.breeding_cooldown = mob:memorize("breeding_cooldown", 300)
			mate_entity.breeding = mate_entity:memorize("breeding", false)
			mate_entity.breeding_cooldown = mate_entity:memorize("breeding_cooldown", 300)

			pegasus.particle_spawner(pos, "heart.png", "float")

			for _ = 1, mob.birth_count or 1 do
				if mob.add_child then
					mob:add_child(mate_entity)
				else
					local object = minetest.add_entity(pos, mob.name)
					local ent = object:get_luaentity()
					ent.growth_scale = 0.7
					pegasus.initialize_api(ent)
					pegasus.protect_from_despawn(ent)
				end
			end
			return true, 60
		end

		if not mob:get_action() then
			pegasus.action_pursue(mob, mate)
		end
	end
	self:set_utility(func)
end)

-- Swim --

creatura.register_utility("pegasus:swim_wander", function(self)
	local move_chance = 2
	local idle_max = 4

	local function func(mob)
		if not mob:get_action() then
			if not mob.in_liquid then
				creatura.action_idle(mob, 1, "flop")
				return
			end

			if not mob.idle_in_water
			or random(move_chance) < 2 then
				pegasus.action_swim(mob, 0.5)
			else
				pegasus.action_float(mob, random(idle_max), "float")
			end
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:swim_seek_land", function(self)
	local land_pos

	self:set_gravity(-9.8)
	local function func(mob)
		if not land_pos then
			for i = 0, 330, 30 do
				land_pos = pegasus.find_collision(mob, yaw2dir(rad(i)))

				if land_pos then
					land_pos.y = land_pos.y + 1
					if minetest.get_node(land_pos).name == "air" then
						break
					else
						land_pos = nil
					end
				end
			end
			if not land_pos then return true end
		end

		local pos, yaw = mob.object:get_pos(), mob.object:get_yaw()
		if not yaw then return end

		local tyaw = dir2yaw(vec_dir(pos, land_pos))
		if abs(tyaw - yaw) > 0.1 then
			mob:turn_to(tyaw, 12)
		end

		mob:set_forward_velocity(mob.speed * 0.5)
		mob:animate("walk")
		if vec_dist(pos, land_pos) < 1
		or (not mob.in_liquid
		and mob.touching_ground) then
			return true
		end
	end
	self:set_utility(func)
end)

-- Fly --

creatura.register_utility("pegasus:fly_wander", function(self, turn_rate)
	local move_chance = 2
	local idle_max = 4

	local function func(mob)
		if not mob:get_action() then
			if not mob.idle_while_flying
			or random(move_chance) < 2 then
				pegasus.action_fly(mob, 1, 0.5, "fly", nil, turn_rate)
			else
				pegasus.action_hover(mob, random(idle_max), "hover")
			end
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:fly_seek_home", function(self)
	local home = self.home_position
	local roost = self.roost_action or creatura.action_idle
	local is_home = self.is_roost or function(pos, home_pos)
		if abs(pos.x - home_pos.x) < 0.5
		and abs(pos.z - home_pos.z) < 0.5
		and abs(pos.y - home_pos.y) < 0.75 then
			return true
		end
		return false
	end
	local function func(mob)
		local pos = mob.object:get_pos()
		if not pos or not home then return true end

		if not mob:get_action() then
			if is_home(pos, home) then
				roost(mob, 1)
				return
			end
			creatura.action_move(mob, home, 3, "pegasus:steer_no_gravity", 1, "fly")
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:fly_seek_land", function(self)
	local landed = false
	local function func(_self)
		if not _self:get_action() then
			if landed then return true end
			if _self.touching_ground then
				creatura.action_idle(_self, 0.5, "stand")
				landed = true
			else
				local pos2 = _self:get_wander_pos_3d(3, 6)
				if pos2 then
					local dist2floor = creatura.sensor_floor(_self, 10, true)
					pos2.y = pos2.y - dist2floor
					creatura.action_move(_self, pos2, 3, "pegasus:move_no_gravity", 0.6, "fly")
				end
			end
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:fly_seek_food", function(self)
	local timeout = 3

	local food = pegasus.get_dropped_food(self)
	local food_reached = false
	local function func(mob)
		local pos = mob.object:get_pos()
		local food_pos = food and food:get_pos()
		if not pos or not food_pos then return true, 5 end

		local dist = vec_dist(pos, food_pos)
		if dist < mob.width + 0.5
		and not food_reached then
			food_reached = true

			local anim = (mob.animations["eat"] and "eat") or "stand"
			creatura.action_idle(mob, 1, anim)
			pegasus.eat_dropped_item(mob, food)
		end

		if not mob:get_action() then
			if food_reached then return true, 10 end
			pegasus.action_fly(mob, 1, 1, "fly", food_pos, 3)
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then
			return true
		end
	end
	self:set_utility(func)
end)

-- pegasus --

creatura.register_utility("pegasus:pegasus_tame", function(self)
	local trust = 5
	local player = self.rider
	local player_props = player and player:get_properties()
	if not player_props then return end
	local player_size = player_props.visual_size
	local mob_size = self.visual_size
	local adj_size = {
		x = player_size.x / mob_size.x,
		y = player_size.y / mob_size.y
	}
	if player_size.x ~= adj_size.x then
		player:set_properties({
			visual_size = adj_size
		})
	end
	local function func(_self)
		local pos = _self.object:get_pos()
		if not pos then return end
		if not player or not creatura.is_alive(player) then return true end

		-- Increase Taming progress while Players view is aligned with the pegasuss
		local yaw, plyr_yaw = _self.object:get_yaw(), player:get_look_horizontal()
		local yaw_diff = abs(diff(yaw, plyr_yaw))

		trust = yaw_diff < pi / 3 and trust + _self.dtime or trust - _self.dtime * 0.5

		if trust >= 10 then -- Tame
			_self.owner = _self:memorize("owner", player:get_player_name())
			pegasus.protect_from_despawn(_self)
			pegasus.mount(_self, player)
			pegasus.particle_spawner(pos, "creatura_particle_green.png", "float")
		elseif trust <= 0 then -- Fail
			pegasus.mount(_self, player)
			pegasus.particle_spawner(pos, "creatura_particle_red.png", "float")
		end

		-- Actions
		if not _self:get_action() then
			if random(3) < 2 then
				creatura.action_idle(_self, 0.5, "punch_aoe")
			else
				pegasus.action_walk(_self, 2, 0.75, "run")
			end
		end

		-- Dismount
		if not player
		or player:get_player_control().sneak then
			pegasus.mount(_self, player)
			return true
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:pegasus_ride", function(self, player)
	local player_props = player and player:get_properties()
	if not player_props then return end
	local player_size = player_props.visual_size
	local mob_size = self.visual_size
	local adj_size = {
		x = player_size.x / mob_size.x,
		y = player_size.y / mob_size.y
	}
	if player_size.x ~= adj_size.x then
		player:set_properties({
			visual_size = adj_size
		})
	end

	local function func(_self)
		if not creatura.is_alive(player) then
			return true
		end
		local anim = "stand"
		local speed_x = 0
		local tyaw = player:get_look_horizontal()
		local control = player:get_player_control()
		local vel = _self.object:get_velocity()
		if not tyaw then return true end

		if control.sneak
		or not _self.rider then
			pegasus.mount(_self, player)
			return true
		end

		animate_player(player, "sit", 30)

		if _self:timer(1) then
			player_props = player and player:get_properties()
			if player_props.visual_size.x ~= adj_size.x then
				player:set_properties({
					visual_size = adj_size
				})
			end
		end

		if control.up then
			speed_x = 2
			anim = "walk"
			if control.aux1 then
				speed_x = 17
				anim = "run"
			end
		end

		-- Jump Control
		if control.jump
		and _self.touching_ground
		and vel.y < 1 then
			_self.object:add_velocity({
				x = 0,
				y = _self.jump_power * 170,
				z = 0
			})
		elseif not _self.touching_ground then
			speed_x = speed_x * 0.75
		end

		-- Rear Animation when jumping
		if not _self.touching_ground
		and not _self.in_liquid
		and vel.y > 0 then
			anim = "rear"
		end

		-- Steering
		local yaw = _self.object:get_yaw()

		_self.head_tracking = nil
		pegasus.move_head(_self, tyaw, 0)

		if speed_x > 0 and control.left then tyaw = tyaw + pi * 0.25 end
		if speed_x > 0 and control.right then tyaw = tyaw - pi * 0.25 end
		if abs(yaw - tyaw) > 0.1 then
			_self:turn_to(tyaw, _self.turn_rate)
		end

		_self:set_forward_velocity(_self.speed * speed_x)
		_self:animate(anim)
	end
	self:set_utility(func)
end)

-- Eagle --

creatura.register_utility("pegasus:eagle_attack", function(self, target)
	local function func(mob)
		local pos = mob.object:get_pos()
		local _, is_visible, target_pos = mob:get_target(target)

		if not pos or not target_pos then return true end

		if not mob:get_action() then
			local vantage_pos = {
				x = target_pos.x,
				y =  target_pos.y + 6,
				z = target_pos.z
			}
			local dist = vec_dist(pos, vantage_pos)

			if dist > 8 then
				pegasus.action_fly(mob, 1, 1, "fly", vantage_pos, 2)
			elseif not is_visible then
				pegasus.action_fly(mob, 1, 0.5, "glide", vantage_pos, 4)
			else
				pegasus.action_dive_attack(mob, target, 6)
			end
		end
	end
	self:set_utility(func)
end)


-- Opossum

local function grow_crop(crop)
	local crop_name = minetest.get_node(crop).name
	local growth_stage = tonumber(crop_name:sub(-1)) or 1
	local new_name = crop_name:sub(1, #crop_name - 1) .. (growth_stage + 1)
	local new_def = minetest.registered_nodes[new_name]

	if new_def then
		local p2 = new_def.place_param2 or 1
		minetest.set_node(crop, {name = new_name, param2 = p2})
	end
end

creatura.register_utility("pegasus:opossum_seek_crop", function(self)
	local timeout = 12

	local crop = pegasus.find_crop(self)
	local crop_reached = false
	local function func(mob)
		local pos = mob.object:get_pos()
		if not pos or not crop then return true, 30 end

		local dist = vec_dist(pos, crop)
		if dist < mob.width + 0.5
		and not crop_reached then
			crop_reached = true

			creatura.action_idle(mob, 1, "clean_crop")
			grow_crop(crop)
		end

		if not mob:get_action() then
			if crop_reached then return true, 10 end
			pegasus.action_walk(mob, 2, 0.5, "walk", crop)
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then
			return true
		end
	end
	self:set_utility(func)
end)

-- Tamed --

creatura.register_utility("pegasus:tamed_idle", function(self)
	local function func(mob)
		if not mob.owner or mob.order ~= "stay" then return true end

		if not mob:get_action() then
			creatura.action_idle(mob, 1)
		end
	end
	self:set_utility(func)
end)

creatura.register_utility("pegasus:tamed_follow_owner", function(self, player)
	local function func(mob)
		local owner = player or (mob.owner and minetest.get_player_by_name(mob.owner))
		if not owner then return true end

		local pos, target_pos = mob.object:get_pos(), owner:get_pos()
		if not pos or not target_pos then return true end

		if not mob:get_action() then
			local dist = vec_dist(pos, target_pos)

			if dist > mob.width + 1 then
				pegasus.action_pursue(mob, owner)
			else
				creatura.action_idle(mob, 1)
			end
		end
	end
	self:set_utility(func)
end)

------------
-- Mob AI --
-------------

pegasus.mob_ai = {}

pegasus.mob_ai.basic_wander = {
	utility = "pegasus:basic_wander",
	step_delay = 0.25,
	get_score = function(self)
		return 0.1, {self}
	end
}

pegasus.mob_ai.basic_flee = {
	utility = "pegasus:basic_flee",
	get_score = function(self)
		local puncher = self._puncher
		if puncher
		and puncher:get_pos() then
			return 0.6, {self, puncher}
		end
		self._puncher = nil
		return 0
	end
}

pegasus.mob_ai.basic_breed = {
	utility = "pegasus:basic_breed",
	get_score = function(self)
		if self.breeding
		and pegasus.get_nearby_mate(self, self.name) then
			return 0.6, {self}
		end
		return 0
	end
}

pegasus.mob_ai.basic_attack = {
	utility = "pegasus:basic_attack",
	get_score = function(self)
		return pegasus.get_attack_score(self, self.attack_list)
	end
}

pegasus.mob_ai.basic_seek_crop = {
	utility = "pegasus:basic_seek_crop",
	step_delay = 0.25,
	get_score = function(self)
		if random(8) < 2 then
			return 0.2, {self}
		end
		return 0
	end
}

pegasus.mob_ai.basic_seek_food = {
	utility = "pegasus:basic_seek_food",
	get_score = function(self)
		if random(1) < 8 then
			return 0.3, {self}
		end
		return 0
	end
}

-- Fly

pegasus.mob_ai.fly_wander = {
	utility = "pegasus:fly_wander",
	step_delay = 0.25,
	get_score = function(self)
		return 0.1, {self}
	end
}

pegasus.mob_ai.fly_landing_wander = {
	utility = "pegasus:fly_wander",
	get_score = function(self)
		if self.is_landed then
			local player = creatura.get_nearby_player(self)
			if player then
				self.is_landed = self:memorize("is_landed", false)
			end
		end
		if not self.is_landed
		or self.in_liquid then
			return 0.2, {self}
		end
		return 0
	end
}

pegasus.mob_ai.fly_seek_food = {
	utility = "pegasus:fly_seek_food",
	get_score = function(self)
		if random(8) < 2 then
			return 0.3, {self}
		end
		return 0
	end
}

pegasus.mob_ai.fly_seek_land = {
	utility = "pegasus:fly_seek_land",
	get_score = function(self)
		if self.is_landed
		and not self.touching_ground
		and not self.in_liquid
		and creatura.sensor_floor(self, 3, true) > 2 then
			return 0.3, {self}
		end
		return 0
	end
}

-- Swim

pegasus.mob_ai.swim_seek_land = {
	utility = "pegasus:swim_seek_land",
	step_delay = 0.25,
	get_score = function(self)
		if self.in_liquid then
			return 0.3, {self}
		end
		return 0
	end
}

pegasus.mob_ai.swim_wander = {
	utility = "pegasus:swim_wander",
	step_delay = 0.25,
	get_score = function(self)
		return 0.1, {self}
	end
}

-- Tamed

pegasus.mob_ai.tamed_follow_owner = {
	utility = "pegasus:tamed_follow_owner",
	get_score = function(self)
		if self.owner
		and self.order == "follow" then
			return 0.4, {self}
		end

		local lasso_holder = type(self._lassod_to) == "string" and minetest.get_player_by_name(self._lassod_to)
		local player = lasso_holder or creatura.get_nearby_player(self)

		if lasso_holder
		or self:follow_wielded_item(player) then
			return 0.4, {self, player}
		end
		return 0
	end
}

pegasus.mob_ai.tamed_stay = {
	utility = "pegasus:basic_idle",
	step_delay = 0.25,
	get_score = function(self)
		local order = self.order or "wander"
		if order == "sit" then
			return 0.5, {self}
		end
		return 0
	end
}


-- Eagle

pegasus.mob_ai.eagle_attack = {
	utility = "pegasus:eagle_attack",
	get_score = function(self)
		if random(12) > 1
		and (self:get_utility() or "") ~= "pegasus:eagle_attack" then
			return 0
		end

		local target = self._target or creatura.get_nearby_object(self, {"pegasus:rat", "pegasus:song_bird"})
		local tgt_pos = target and target:get_pos()
		if tgt_pos then
			return 0.4, {self, target}
		end
		return 0
	end
}

-- Fox

pegasus.mob_ai.fox_flee = {
	utility = "pegasus:basic_flee",
	get_score = function(self)
		local target = self._puncher or creatura.get_nearby_player(self)
		local pos, target_pos = self.object:get_pos(), target and target:get_pos()
		if not pos or not target_pos then self._puncher = nil return 0 end

		local dist = vec_dist(pos, target_pos)
		local score = ((self.tracking_range - dist) / self.tracking_range) * 0.5

		if target:get_player_control().sneak then score = score * 0.5 end

		self._puncher = target
		return score, {self, target}
	end
}

-- Opossum

pegasus.mob_ai.opossum_feint = {
	utility = "pegasus:basic_idle",
	get_score = function(self)
		local target = self._puncher or creatura.get_nearby_player(self)
		local pos, tgt_pos = self.object:get_pos(), target and target:get_pos()
		if not pos then return end
		if not tgt_pos then self._puncher = nil return 0 end
		local sneaking = target:get_player_control().sneak
		if not sneaking then
			local dist = vec_dist(pos, tgt_pos)
			local score = (self.tracking_range - dist) / self.tracking_range
			self._puncher = target
			return score / 3, {self, 5, "feint"}
		end
		self._puncher = nil
		return 0
	end
}

pegasus.mob_ai.opossum_seek_crop = {
	utility = "pegasus:opossum_seek_crop",
	step_delay = 0.25,
	get_score = function(self)
		if random(8) < 2 then
			return 0.4, {self}
		end
		return 0
	end
}
