------------
-- Mob AI --
------------

-- Math --

local abs = math.abs
local atan2 = math.atan2
local cos = math.cos
local min = math.min
local max = math.max
local pi = math.pi
local pi2 = pi * 2
local sin = math.sin
local rad = math.rad
local random = math.random
pegasus.ice_cooldown = {}


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
	local objects = pegasus.get_nearby_objects(self, self.name)
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
	local calc_pos = { x = pos2.x, y = center_y, z = pos2.z }
	local range = (height_half + 2)
	local offset = { x = 0, y = range, z = 0 }
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
	local steer_to = pegasus.calc_steering(self, pos2, steer_method or pegasus.get_context_small)
	pos2 = vec_add(pos, steer_to)
	local lift = pegasus.get_avoidance_lift(self, pos2, 2)
	steer_to.y = (lift ~= 0 and lift) or dir.y
	return steer_to
end

local function calc_steering_and_lift_aquatic(self, pos, pos2, dir, steer_method)
	local steer_to = pegasus.calc_steering(self, pos2, steer_method or pegasus.get_context_small_aquatic)
	local lift = pegasus.get_avoidance_lift_aquatic(self, vec_add(pos, steer_to), 2)
	steer_to.y = (lift ~= 0 and lift) or dir.y
	return steer_to
end]]

local function get_obstacle(pos, water)
	local pos2 = { x = pos.x, y = pos.y, z = pos.z }
	local n_def = pegasus.get_node_def(pos2)
	if n_def.walkable
		or (water and (n_def.groups.liquid or 0) > 0) then
		pos2.y = pos.y + 1
		n_def = pegasus.get_node_def(pos2)
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
	local steer_method = water and pegasus.get_context_small_aquatic or pegasus.get_steering_context
	local dir = pegasus.calc_steering(self, goal, steer_method)

	local lift_method = water and pegasus.get_avoidance_lift_aquatic or pegasus.get_avoidance_lift
	local lift = lift_method(self, vec_add(self.stand_pos, dir), 2)
	dir.y = (lift ~= 0 and lift) or dir.y

	return dir
end

-- Methods

pegasus.register_movement_method("pegasus:fly_wide", function(self)
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
		local turn_rate = 26
		local speed = abs(_self.speed or 20) * speed_factor or 5
		steer_int = (steer_int > 0 and steer_int - _self.dtime) or 1 / max(speed, 1)
		steer_to = (steer_int <= 0 and pegasus.calc_steering(_self, goal)) or steer_to
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

pegasus.register_movement_method("pegasus:steer", function(self)
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

pegasus.register_movement_method("pegasus:steer_no_gravity", function(self)
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

pegasus.register_movement_method("pegasus:move", function(self)
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

pegasus.register_movement_method("pegasus:move_no_gravity", function(self)
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

	local function func(mob)
		local pos = mob.object:get_pos()
		if not pos then return true end

		local goal

		-- If a specific destination (pos2) is provided, use it as the goal.
		if pos2 then
			goal = pos2
			-- If we've reached the destination, stop.
			if vector.distance(pos, goal) < 2 then
				mob:halt()
				return true
			end
		else
			-- Otherwise, calculate a random wander point.
			local yaw = mob.object:get_yaw()
			if not yaw then return true end
			local dir = minetest.yaw_to_dir(yaw)
			local wander_point = vector.add(pos, vector.multiply(dir, wander_radius + 0.5))
			goal = vector.add(wander_point, vector.multiply(minetest.yaw_to_dir(random(math.pi * 2)), wander_radius))
		end

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
		local boid_dir = mob.uses_boids and pegasus.get_boid_dir(mob)
		if boid_dir then
			steer_direction = {
				x = (steer_direction.x + boid_dir.x) / 2,
				y = (steer_direction.y + boid_dir.y) / 2,
				z = (steer_direction.z + boid_dir.z) / 2
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
		local boid_dir = mob.uses_boids and pegasus.get_boid_dir(mob)
		if boid_dir then
			steer_direction = {
				x = (steer_direction.x + boid_dir.x) / 2,
				y = (steer_direction.y + boid_dir.y) / 2,
				z = (steer_direction.z + boid_dir.z) / 2
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

local latch_ceil_offset = { x = 0, y = 1, z = 0 }
local latch_wall_offset = {
	{ x = 1,  y = 0, z = 0 },
	{ x = 0,  y = 0, z = 1 },
	{ x = -1, y = 0, z = 0 },
	{ x = 0,  y = 0, z = -1 }
}


function pegasus.action_latch(self)
	local pos = self.object:get_pos()
	if not pos then return end

	local ceiling
	if self.animations["latch_ceiling"] then
		ceiling = vec_add(pos, latch_ceil_offset)

		if not pegasus.get_node_def(ceiling).walkable then
			ceiling = nil
		end
	end

	local wall
	if self.animations["latch_wall"] then
		for n = 1, 4 do
			wall = vec_add(self.stand_pos, latch_wall_offset[n])

			if pegasus.get_node_def(wall).walkable then
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
			or _self:move_to(goal, method or "pegasus:obstacle_avoidance", speed_factor or 0.5) then
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
			mob.object:add_velocity({ x = dir.x * 3, y = 2, z = dir.z * 3 })

			stage = 2
		end

		if stage == 2
			and dist < mob.width + 1 then
			mob:punch_target(target)
			local knockback = minetest.calculate_knockback(
				target, mob.object, 1.0,
				{ damage_groups = { fleshy = mob.damage } },
				dir, 2.0, mob.damage
			)
			target:add_velocity({ x = dir.x * knockback, y = dir.y * knockback, z = dir.z * knockback })

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
			mob.object:add_velocity({ x = dir.x * 3, y = 2, z = dir.z * 3 })

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

pegasus.register_utility("pegasus:die", function(self)
	local timer = 1.5
	local init = false
	local function func(_self)
		if not init then
			_self:play_sound("death")
			pegasus.action_fallover(_self)
			init = true
		end
		timer = timer - _self.dtime
		if timer <= 0 then
			local pos = _self.object:get_pos()
			if not pos then return end
			minetest.add_particlespawner({
				amount = 8,
				time = 0.25,
				minpos = { x = pos.x - 0.1, y = pos.y, z = pos.z - 0.1 },
				maxpos = { x = pos.x + 0.1, y = pos.y + 0.1, z = pos.z + 0.1 },
				minacc = { x = 0, y = 2, z = 0 },
				maxacc = { x = 0, y = 3, z = 0 },
				minvel = { x = random(-1, 1), y = -0.25, z = random(-1, 1) },
				maxvel = { x = random(-2, 2), y = -0.25, z = random(-2, 2) },
				minexptime = 0.75,
				maxexptime = 1,
				minsize = 4,
				maxsize = 4,
				texture = "pegasus_smoke_particle.png",
				animation = {
					type = 'vertical_frames',
					aspect_w = 4,
					aspect_h = 4,
					length = 1,
				},
				glow = 1
			})
			pegasus.drop_items(_self)
			_self.object:remove()
		end
	end
	self:set_utility(func)
end)



pegasus.register_utility("pegasus:basic_wander", function(self)
	local idle_max = 4
	local move_chance = 3
	local graze_chance = 16

	local range = self.tracking_range

	local center
	local function func(mob)
		local pos = mob.stand_pos

		if mob:timer(2) then
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
					pegasus.action_idle(mob, 1, "eat")
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
				local plyr = pegasus.get_nearby_player(mob)
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
				pegasus.action_idle(mob, random(idle_max), "stand")
			end
		end
	end
	self:set_utility(func)
end)

pegasus.register_utility("pegasus:basic_flee", function(self, target)
	local function func(_self)
		if not target then
			return true -- End the utility immediately if there is no target.
		end

		local pos = _self.object:get_pos()
		local target_pos = target:get_pos()

		-- Safety check: if there's no position for self or target, we can't flee.
		if not pos or not target_pos then
			return true
		end

		_self:clear_action() -- Clear any existing action before fleeing.
		_self:clear_utility() -- Clear any existing action before fleeing.
		-- Calculate the direction away from the target
		local flee_direction = vector.direction(target_pos, pos)
		-- Calculate a destination 10-15 meters away
		local flee_destination = vector.add(pos, vector.multiply(flee_direction, 10 + random(5)))
		pegasus.action_walk(_self, 10, 1, "run", flee_destination)
	end
	self:set_utility(func)
end)

pegasus.register_utility("pegasus:basic_attack", function(self, target)
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
						pegasus.action_idle(mob, 0.5, "warn")
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

pegasus.register_utility("pegasus:basic_breed", function(self)
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

pegasus.register_utility("pegasus:swim_wander", function(self)
	local move_chance = 2
	local idle_max = 4

	local function func(mob)
		if not mob:get_action() then
			if not mob.in_liquid then
				pegasus.action_idle(mob, 1, "flop")
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

pegasus.register_utility("pegasus:swim_seek_land", function(self)
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

-- Pegasus --

pegasus.register_utility("pegasus:pegasus_tame", function(self)
	-- Get the player who is riding. This is the candidate for taming.
	local player = self.rider
	if not player or not player:is_player() then return true end

	-- Initialize taming trust ON THE MOB ITSELF if it doesn't exist.
	if not self.taming_trust then
		self.taming_trust = self.taming_trust or 5 -- Starting trust value
	end

	-- Adjust player size (this part is correct)
	local player_props = player:get_properties()
	if not player_props then return true end
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
		-- Check if the player is still online and riding
		if not player or not pegasus.is_alive(player) or not _self.rider then
			_self.taming_trust = nil -- Reset trust if player disconnects or dismounts
			return true
		end

		local pos = _self.object:get_pos()
		if not pos then return true end

		-- Increase/Decrease Taming progress based on view alignment
		local yaw, plyr_yaw = _self.object:get_yaw(), player:get_look_horizontal()
		local yaw_diff = abs(diff(yaw, plyr_yaw))

		-- Update the trust value that is stored ON THE MOB
		if yaw_diff < pi / 3 then
			_self.taming_trust = _self.taming_trust + _self.dtime
		else
			_self.taming_trust = _self.taming_trust - _self.dtime * 0.5
		end

		-- Check for success or failure
		if _self.taming_trust >= 10 then -- Tame successful
			_self.owner = _self:memorize("owner", player:get_player_name())
			pegasus.protect_from_despawn(_self)
			pegasus.mount(_self, player) -- Dismount the player
			pegasus.particle_spawner(pos, "pegasus_particle_green.png", "float")
			_self.taming_trust = nil  -- Reset for the future
			return true               -- End the utility
		elseif _self.taming_trust <= 0 then -- Tame failed
			pegasus.mount(_self, player) -- Dismount the player
			pegasus.particle_spawner(pos, "pegasus_particle_blue.png", "float")
			_self.taming_trust = nil  -- Reset for the future
			return true               -- End the utility
		end

		-- Bucking actions while taming
		if not _self:get_action() then
			if random(3) < 2 then
				pegasus.action_idle(_self, 0.5, "punch_aoe")
			else
				pegasus.action_walk(_self, 2, 0.75, "run")
			end
		end

		-- Player can dismount to cancel
		if player:get_player_control().sneak then
			pegasus.mount(_self, player)
			_self.taming_trust = nil -- Reset trust
			return true
		end
	end
	self:set_utility(func)
end)

--------------------------------------
-- Define the four breath functions --
--------------------------------------

-- Fire --

minetest.register_node("pegasus:fire_animated", {
	description = "Pegasus Fire",
	drawtype = "firelike",
	tiles = {
		{
			name = "pegasus_fire_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "pegasus_fire_1.png",
	paramtype = "light",
	light_source = 14,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	floodable = true,
	damage_per_second = 4,
	groups = { igniter = 2, not_in_creative_inventory = 1 },
	drop = "",
	on_timer = function(pos, elapsed)
		-- Check for entities and damage them
		local objects = minetest.get_objects_inside_radius(pos, 1.5)
		for _, obj in ipairs(objects) do
			local ent = obj:get_luaentity()
			if obj:is_player() or (ent and ent.name ~= "waterdragon:scottish_dragon" and ent.name ~= "pegasus:pegasus" and ent.name ~= "waterdragon:rare_water_dragon" and ent.name ~= "waterdragon:pure_water_dragon" and ent.name ~= "winddragon:winddragon") then
				obj:punch(obj, 1.0, {
					full_punch_interval = 1.0,
					damage_groups = { fleshy = 4 },
				}, vector.new(0, 0, 0))
			end
		end

		-- Remove the fire after some time
		if math.random(1, 5) == 1 then -- 20% chance to remove each tick
			minetest.remove_node(pos)
			return false
		end
		return true
	end,
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(0.5) -- Check every 0.5 seconds
	end,
	on_flood = function(pos, oldnode, newnode)
		minetest.remove_node(pos)
		return false
	end,
})

function pegasus_breathe_fire(self)
	if not self.fire_breathing then return end
	if not self.fire_breath or self.fire_breath <= 0 then
		self.fire_breathing = false
		return
	end

	local pos = self.object:get_pos()
	if not pos then return end

	local yaw = self.object:get_yaw()
	local dir = vector.new(
		-math.sin(yaw),
		0,
		math.cos(yaw)
	)
	local start_pos = vector.add(pos, vector.new(0, 1.2, 0))
	local end_pos = vector.add(start_pos, vector.multiply(dir, 20))

	local particle_types = {
		{
			texture = "pegasus_fire_1.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 14
		},
		{
			texture = "pegasus_fire_2.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 14
		},
		{
			texture = "pegasus_fire_3.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 14
		},
	}

	-- Spawn particles
	for i = 1, 20 do
		local particle = particle_types[math.random(#particle_types)]

		minetest.add_particle({
			pos = vector.add(start_pos, vector.new(
				math.random(-5, 5) / 10,
				math.random(-5, 5) / 10,
				math.random(-5, 5) / 10
			)),
			velocity = vector.multiply(vector.add(dir, vector.new(
				math.random(-2, 2) / 10,
				math.random(-2, 2) / 10,
				math.random(-2, 2) / 10
			)), math.random(particle.velocity.min, particle.velocity.max)),
			acceleration = { x = 0, y = math.random(particle.acceleration.y.min, particle.acceleration.y.max), z = 0 },
			expirationtime = math.random(particle.exptime.min, particle.exptime.max),
			size = math.random(particle.size.min, particle.size.max),
			collisiondetection = true,
			collision_removal = true,
			vertical = false,
			texture = particle.texture,
			glow = particle.glow
		})
	end

	-- FIX: Replaced the entire target-checking logic with a more robust version.
	local step = 1
	local hit_this_tick = {} -- Prevents hitting the same mob multiple times

	for i = 0, 20, step do
		local check_pos = vector.add(start_pos, vector.multiply(dir, i))
		local node = minetest.get_node(check_pos)

		-- Set blocks on fire
		if node.name ~= "air" and node.name ~= "pegasus:fire_animated" then
			minetest.set_node(check_pos, { name = "pegasus:fire_animated" })
		end

		-- Check for entities at each step
		for _, obj in ipairs(minetest.get_objects_inside_radius(check_pos, 2)) do
			if not hit_this_tick[obj] then
				local ent_name = obj:is_player() and obj:get_player_name()
				local rider = self.rider
				-- Correctly check if the target is not self
				if obj ~= self.object and obj ~= rider then
					hit_this_tick[obj] = true -- Mark as hit
					local ent = obj:get_luaentity()
					local name = ent and ent.name or ""
					if name ~= "waterdragon:rare_water_dragon"
						and name ~= "waterdragon:pure_water_dragon"
						and name ~= "waterdragon:scottish_dragon"
						and name ~= "winddragon:winddragon" then
						obj:punch(self.object, 1.0, {
							full_punch_interval = 1.0,
							damage_groups = { fleshy = 8 },
						}, nil)
					end
				end
			end
		end

		-- Stop if we hit a solid block
		if node.name ~= "air" and node.name ~= "pegasus:fire_animated" then
			break
		end
	end

	-- Decrease fire charge every second
	self.fire_timer = (self.fire_timer or 0) + 0.1
	if self.fire_timer >= 1 then
		self.fire_breath = self.fire_breath - 1
		self.fire_timer = 0
		if self.fire_breath <= 0 then
			self.fire_breathing = false
			return
		end
	end

	-- Schedule the next fire breath
	minetest.after(0.1, function()
		pegasus_breathe_fire(self)
	end)
end

-- Water --

function pegasus_breathe_water(self)
	if not self.water_breathing then return end
	if not self.water_breath or self.water_breath <= 0 then
		self.water_breathing = false
		return
	end

	local pos = self.object:get_pos()
	if not pos then return end

	local yaw = self.object:get_yaw()
	local dir = vector.new(
		-math.sin(yaw),
		0,
		math.cos(yaw)
	)
	local start_pos = vector.add(pos, vector.new(0, 1.2, 0))
	local end_pos = vector.add(start_pos, vector.multiply(dir, 20))

	local particle_types = {
		{
			texture = "pegasus_water_1.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 5
		},
		{
			texture = "pegasus_water_2.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 6
		},
		{
			texture = "pegasus_water_3.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 7
		},
	}

	-- Spawn particles
	for i = 1, 50 do
		local particle = particle_types[math.random(#particle_types)]

		minetest.add_particle({
			pos = vector.add(start_pos, vector.new(
				math.random(-5, 5) / 10,
				math.random(-5, 5) / 10,
				math.random(-5, 5) / 10
			)),
			velocity = vector.multiply(vector.add(dir, vector.new(
				math.random(-2, 2) / 10,
				math.random(-2, 2) / 10,
				math.random(-2, 2) / 10
			)), math.random(particle.velocity.min, particle.velocity.max)),
			acceleration = { x = 0, y = math.random(particle.acceleration.y.min, particle.acceleration.y.max), z = 0 },
			expirationtime = math.random(particle.exptime.min, particle.exptime.max),
			size = math.random(particle.size.min, particle.size.max),
			collisiondetection = true,
			collision_removal = true,
			vertical = false,
			texture = particle.texture,
			glow = particle.glow
		})
	end

	local step = 1
	local hit_this_tick = {} -- Prevents hitting the same mob multiple times

	for i = 0, 20, step do
		local check_pos = vector.add(start_pos, vector.multiply(dir, i))
		local node = minetest.get_node(check_pos)

		-- Make blocks wet
		if node.name ~= "air" and node.name ~= "default:water_flowing" then
			minetest.set_node(check_pos, { name = "default:water_flowing" })
		end
		-- Disable fire blocks
		if node.name == "pegasus:fire_animated" then
			minetest.remove_node(check_pos)
		end
		local rider = self.rider
		-- Check for entities at each step
		for _, obj in ipairs(minetest.get_objects_inside_radius(check_pos, 2)) do
			if not hit_this_tick[obj] then
				-- Correctly check if the target is not self
				if obj ~= self.object and obj ~= rider then
					hit_this_tick[obj] = true -- Mark as hit
					local ent = obj:get_luaentity()
					local name = ent and ent.name or ""
					if name ~= "waterdragon:rare_water_dragon"
						and name ~= "waterdragon:pure_water_dragon"
						and name ~= "waterdragon:scottish_dragon"
						and name ~= "winddragon:winddragon" then
						obj:punch(self.object, 1.0, {
							full_punch_interval = 1.0,
							damage_groups = { fleshy = 4 },
						}, nil)
						obj:add_velocity(vector.multiply(dir, 5))
					end
				end
			end
		end

		-- Stop if we hit a solid block
		if node.name ~= "air" and node.name ~= "pegasus:fire_animated" then
			break
		end
	end

	-- Decrease water charge every second
	self.water_timer = (self.water_breath_timer or 0) + 0.1
	if self.water_timer >= 1 then
		self.water_breath = self.water_breath - 1
		self.water_timer = 0
		if self.water_breath <= 0 then
			self.water_breathing = false
			return
		end
	end

	-- Schedule the next water breath
	minetest.after(0.1, function()
		pegasus_breathe_water(self)
	end)
end

-- Ice --

--[[
    Ice Trap Entity
    This entity is spawned by the Ice Pegasus's breath. It traps a target mob/player
    for a few seconds, then releases them and removes itself.
]]
minetest.register_entity("pegasus:freeze_ent", {
	initial_properties = {
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		visual = "cube",
		-- FIX: Apply a texture modifier to force opacity, similar to the draconis mod.
		-- This should make the cube see-through for the trapped player.
		textures = {
			"pegasus_frozen_ent.png^[opacity:170", -- top
			"pegasus_frozen_ent.png^[opacity:170", -- bottom
			"pegasus_frozen_ent.png^[opacity:170", -- front
			"pegasus_frozen_ent.png^[opacity:170", -- back
			"pegasus_frozen_ent.png^[opacity:170", -- right
			"pegasus_frozen_ent.png^[opacity:170", -- left
		},
		visual_size = { x = 1, y = 1 },
		physical = false,
		glow = 10,
		use_texture_alpha = true, -- Keep this for good measure
		backface_culling = false, -- Still needed for a cube
	},

	child = nil,
	mob_scale = nil,
	timer = 0,

	on_activate = function(self)
		self.object:set_armor_groups({ immortal = 1 })
	end,

	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > 4 then
			if self.child and self.child:get_luaentity() then
				self.child:set_detach()
				self.child:set_properties({
					visual_size = self.mob_scale,
				})
			end
			self.object:remove()
		end
	end,
})

function pegasus_breathe_ice(self)
	if not self.ice_breathing then return end
	if not self.ice_breath or self.ice_breath <= 0 then
		self.ice_breathing = false
		return
	end

	local pos = self.object:get_pos()
	if not pos then return end

	local yaw = self.object:get_yaw()
	local dir = vector.new(
		-math.sin(yaw),
		0,
		math.cos(yaw)
	)
	local start_pos = vector.add(pos, vector.new(0, 1.2, 0))
	local end_pos = vector.add(start_pos, vector.multiply(dir, 20))

	local particle_types = {
		{
			texture = "pegasus_ice_1.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 1
		},
		{
			texture = "pegasus_ice_2.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 3
		},
		{
			texture = "pegasus_ice_3.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 2
		},
	}

	-- Spawn particles
	for i = 1, 20 do
		local particle = particle_types[math.random(#particle_types)]

		minetest.add_particle({
			pos = vector.add(start_pos, vector.new(
				math.random(-5, 5) / 10,
				math.random(-5, 5) / 10,
				math.random(-5, 5) / 10
			)),
			velocity = vector.multiply(vector.add(dir, vector.new(
				math.random(-2, 2) / 10,
				math.random(-2, 2) / 10,
				math.random(-2, 2) / 10
			)), math.random(particle.velocity.min, particle.velocity.max)),
			acceleration = { x = 0, y = math.random(particle.acceleration.y.min, particle.acceleration.y.max), z = 0 },
			expirationtime = math.random(particle.exptime.min, particle.exptime.max),
			size = math.random(particle.size.min, particle.size.max),
			collisiondetection = true,
			collision_removal = true,
			vertical = false,
			texture = particle.texture,
			glow = particle.glow
		})
	end
	local step = 1

	for i = 0, 20, step do
		local check_pos = vector.add(start_pos, vector.multiply(dir, i))
		local hit_this_tick = {} -- Track hits in this tick
		for _, obj in ipairs(minetest.get_objects_inside_radius(check_pos, 2)) do
			-- Check if we already hit this object in this breath attack
			if not hit_this_tick[obj] then
				local rider = self.rider
				if obj ~= self.object and obj ~= rider then
					if not obj:get_attach() and not pegasus.ice_cooldown[obj] then
						hit_this_tick[obj] = true -- Mark as hit to avoid hitting again

						local ent = obj:get_luaentity()
						local name = ent and ent.name or ""
						if name ~= "waterdragon:rare_water_dragon"
							and name ~= "waterdragon:pure_water_dragon"
							and name ~= "waterdragon:scottish_dragon"
							and name ~= "winddragon:winddragon" then
							obj:punch(self.object, 1.0, {
								full_punch_interval = 1.0,
								damage_groups = { fleshy = 8 },
							}, nil)
						end

						-- Apply Freeze Trap
						local target_pos = obj:get_pos()

						-- FIX: Add a safety check to ensure target_pos is not nil before proceeding.
						if target_pos then
							local ice_obj = minetest.add_entity(target_pos, "pegasus:freeze_ent")

							-- Get collisionbox safely
							local box
							local ent = obj:get_luaentity()
							if ent and ent.name and minetest.registered_entities[ent.name] then
								box = minetest.registered_entities[ent.name].collisionbox
							end
							if not box then box = { -0.5, -1, -0.5, 0.5, 1, 0.5 } end -- Default box

							if ice_obj then
								obj:set_attach(ice_obj, "", { x = 0, y = math.abs(box[2]), z = 0 },
									{ x = 0, y = 0, z = 0 })

								local obj_scale = obj:get_properties().visual_size
								local ice_scale = (box[4] or 0.5) * 2.5

								local ice_ent = ice_obj:get_luaentity()
								ice_ent.mob_scale = obj_scale
								ice_ent.child = obj

								ice_obj:set_properties({ visual_size = { x = ice_scale, y = ice_scale } })

								local obj_yaw = obj:get_yaw() or obj:get_look_horizontal() or 0
								ice_obj:set_yaw(obj_yaw)

								obj:set_properties({
									visual_size = { x = obj_scale.x / ice_scale, y = obj_scale.y / ice_scale }
								})
							end
						end
					end
				end
			end
		end

		local node = minetest.get_node(check_pos)
		if node.name ~= "air" and node.name ~= "default:ice" then
			break
		end
	end

	-- Decrease cooldowns
	for obj, time in pairs(pegasus.ice_cooldown) do
		pegasus.ice_cooldown[obj] = time - 1
		if pegasus.ice_cooldown[obj] <= 0 then
			pegasus.ice_cooldown[obj] = nil
		end
	end

	-- Decrease ice charge every second
	self.ice_timer = (self.ice_timer or 0) + 0.1
	if self.ice_timer >= 1 then
		self.ice_breath = self.ice_breath - 1
		self.ice_timer = 0
		if self.ice_breath <= 0 then
			self.ice_breathing = false
			return
		end
	end

	-- Schedule the next ice breath
	minetest.after(0.1, function()
		pegasus_breathe_ice(self)
	end)
end

-- Wind --

function pegasus_breathe_wind(self)
	if not self.wind_breathing then return end
	if not self.wind_breath or self.wind_breath <= 0 then
		self.wind_breathing = false
		return
	end

	local pos = self.object:get_pos()
	if not pos then return end

	local yaw = self.object:get_yaw()
	local dir = vector.new(
		-math.sin(yaw),
		0,
		math.cos(yaw)
	)
	local start_pos = vector.add(pos, vector.new(0, 1.2, 0))
	local end_pos = vector.add(start_pos, vector.multiply(dir, 20))

	local particle_types = {
		{
			texture = "pegasus_wind_1.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 6
		},
		{
			texture = "pegasus_wind_2.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 10
		},
		{
			texture = "pegasus_wind_3.png",
			size = { min = 2, max = 4 },
			velocity = { min = 15, max = 20 },
			acceleration = { y = { min = 2, max = 4 } },
			exptime = { min = 0.8, max = 1.2 },
			glow = 7
		},
	}

	-- Spawn particles
	for i = 1, 30 do
		local particle = particle_types[math.random(#particle_types)]

		minetest.add_particle({
			pos = vector.add(start_pos, vector.new(
				math.random(-5, 5) / 10,
				math.random(-5, 5) / 10,
				math.random(-5, 5) / 10
			)),
			velocity = vector.multiply(vector.add(dir, vector.new(
				math.random(-2, 2) / 10,
				math.random(-2, 2) / 10,
				math.random(-2, 2) / 10
			)), math.random(particle.velocity.min, particle.velocity.max)),
			acceleration = { x = 0, y = math.random(particle.acceleration.y.min, particle.acceleration.y.max), z = 0 },
			expirationtime = math.random(particle.exptime.min, particle.exptime.max),
			size = math.random(particle.size.min, particle.size.max),
			collisiondetection = true,
			collision_removal = true,
			vertical = false,
			texture = particle.texture,
			glow = particle.glow
		})
	end


	-- Check for entities and apply wind effect (knockback)
	local rider = self.rider
	local hit_this_tick = {}
	local step = 1

	for i = 0, 25, step do -- Increased range for wind
		local check_pos = vector.add(start_pos, vector.multiply(dir, i))

		for _, obj in ipairs(minetest.get_objects_inside_radius(check_pos, 2.5)) do
			if (obj:is_player() or obj:get_luaentity()) and not hit_this_tick[obj] then
				if obj ~= self.object and obj ~= rider then
					hit_this_tick[obj] = true
					local ent = obj:get_luaentity()
					local name = ent and ent.name or ""
					if name ~= "waterdragon:rare_water_dragon"
						and name ~= "waterdragon:pure_water_dragon"
						and name ~= "waterdragon:scottish_dragon"
						and name ~= "winddragon:winddragon" then
						-- No damage, but strong knockback
						obj:add_velocity(vector.multiply(dir, 12))
					end
				end
			end
		end
	end

	-- Decrease wind charge every second
	self.wind_timer = (self.wind_timer or 0) + 0.1
	if self.wind_timer >= 1 then
		self.wind_breath = self.wind_breath - 1
		self.wind_timer = 0
		if self.wind_breath <= 0 then
			self.wind_breathing = false
			return
		end
	end

	-- Schedule the next wind breath
	minetest.after(0.1, function()
		pegasus_breathe_wind(self)
	end)
end

-- Pegasus Ride --

pegasus.register_utility("pegasus:pegasus_ride", function(self, player)
	-- Initialize player size adjustment
	local player_props = player and player:get_properties()
	if not player_props then return true end
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

	-- Initialize state variables
	local fire_breath_cooldown = 0
	local is_flying = self:recall("is_flying") or false
	local fly_speed = 12 -- Base speed for flying
	local run_speed = 8 -- Base speed for running on the ground

	-- Get player-specific settings
	local player_name = player:get_player_name()

	local function func(_self)
		if not pegasus.is_alive(player) then return true end

		local anim = "stand"
		local tyaw = player:get_look_horizontal()
		local control = player:get_player_control()
		if not tyaw then return true end

		-- Dismount check
		if control.sneak or not _self.rider then
			pegasus.mount(_self, player)
			_self.is_flying = _self:memorize("is_flying", false) -- Ensure flying stops on dismount
			_self:set_gravity(-9.8)
			return true
		end

		-- Update player animation and size
		animate_player(player, "sit", 30)
		if _self:timer(1) then
			player_props = player and player:get_properties()
			if player_props and player_props.visual_size.x ~= adj_size.x then
				player:set_properties({ visual_size = adj_size })
			end
		end

		-- Breath Attacks by Player
		if control.LMB then
			-- We check if the breathing is already active to avoid re-triggering it every tick.
			if _self.texture_no == 1 and not _self.fire_breathing then
				_self.fire_breathing = true
				pegasus_breathe_fire(_self) -- Call the function to start the attack]
			elseif _self.texture_no == 2 and not _self.ice_breathing then
				_self.ice_breathing = true
				pegasus_breathe_ice(_self) -- Call the function
			elseif _self.texture_no == 3 and not _self.water_breathing then
				_self.water_breathing = true
				pegasus_breathe_water(_self) -- Call the function
			elseif _self.texture_no == 4 and not _self.wind_breathing then
				_self.wind_breathing = true
				pegasus_breathe_wind(_self) -- Call the function
			end
		else
			-- If the player releases the button, stop all breathing attacks.
			_self.fire_breathing = false
			_self.ice_breathing = false
			_self.water_breathing = false
			_self.wind_breathing = false
		end

		-- Toggle flying mode
		if control.jump and _self.touching_ground and not is_flying then
			-- Double-tap jump to take off
			if _self.jump_timer and _self.jump_timer > 0 then
				is_flying = _self:memorize("is_flying", true)
				_self:set_gravity(0)
				_self.object:add_velocity({ x = 0, y = 3, z = 0 }) -- Initial jump boost
			end
			_self.jump_timer = 1                       -- You have 1s to press jump again
		end
		if _self.jump_timer then
			_self.jump_timer = _self.jump_timer - _self.dtime
		end

		if is_flying then
			anim = "walk"
			local look_dir = player:get_look_dir()
			local target_velocity = { x = 0, y = 0, z = 0 }
			local current_speed = fly_speed
			local is_moving = false

			-- Sprinting in the air
			if control.aux1 then
				current_speed = fly_speed * 2
				anim = "run"
			end

			-- Forward movement
			if control.up then
				is_moving = true
				target_velocity = vector.multiply(player:get_look_dir(), current_speed)
				-- If vertical lock is on, ignore the Y component of the look direction
			end

			-- Vertical movement (independent of forward)
			if control.jump then
				is_moving = true
				target_velocity.y = 6
			elseif control.down then
				is_moving = true
				target_velocity.y = -6
			end

			_self.object:set_velocity(target_velocity)
			_self.object:set_acceleration({ x = 0, y = 0, z = 0 }) -- Ensure no residual acceleration
			_self.object:set_yaw(tyaw)

			-- Landing
			if _self.touching_ground and control.down then
				is_flying = _self:memorize("is_flying", false)
				_self:set_gravity(-9.8)
			end
		else
			-- Original ground movement
			local speed_x = 0
			if control.up then
				speed_x = run_speed
				anim = "walk"
				if control.aux1 then
					speed_x = run_speed * 1.75
					anim = "run"
				end
			end

			if control.jump and _self.touching_ground then
				_self.object:add_velocity({ x = 0, y = _self.jump_power * 2, z = 0 })
			end

			_self:set_forward_velocity(speed_x)
			_self.object:set_yaw(tyaw)
		end

		_self:animate(anim)
	end

	self:set_utility(func)
end)

-- Eagle --

pegasus.register_utility("pegasus:eagle_attack", function(self, target)
	local function func(mob)
		local pos = mob.object:get_pos()
		local _, is_visible, target_pos = mob:get_target(target)

		if not pos or not target_pos then return true end

		if not mob:get_action() then
			local vantage_pos = {
				x = target_pos.x,
				y = target_pos.y + 6,
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

------------
-- Mob AI --
-------------

pegasus.mob_ai = {}

pegasus.mob_ai.basic_wander = {
	utility = "pegasus:basic_wander",
	step_delay = 0.25,
	get_score = function(self)
		return 0.1, { self }
	end
}

pegasus.mob_ai.basic_flee = {
	utility = "pegasus:basic_flee",
	get_score = function(self)
		local puncher = self._puncher
		if puncher
			and puncher:get_pos() then
			return 0.6, { self, puncher }
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
			return 0.6, { self }
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
			return 0.3, { self }
		end
		return 0
	end
}
