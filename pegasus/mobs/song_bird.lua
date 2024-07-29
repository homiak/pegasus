---------------
-- Song Bird --
---------------

local random = math.random

creatura.register_mob("pegasus:song_bird", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_bird.b3d",
	textures = {
		"pegasus_cardinal.png",
		"pegasus_bluebird.png",
		"pegasus_goldfinch.png"
	},

	-- Creatura Props
	max_health = 2,
	speed = 4,
	tracking_range = 8,
	max_boids = 6,
	boid_seperation = 0.3,
	despawn_after = 200,
	max_fall = 0,
	stepheight = 1.1,
	sounds = {
		cardinal = {
			name = "pegasus_cardinal",
			gain = 0.5,
			distance = 63
		},
		eastern_blue = {
			name = "pegasus_bluebird",
			gain = 0.5,
			distance = 63
		},
		goldfinch = {
			name = "pegasus_goldfinch",
			gain = 0.5,
			distance = 63
		},
	},
	hitbox = {
		width = 0.2,
		height = 0.4
	},
	animations = {
		stand = {range = {x = 1, y = 100}, speed = 30, frame_blend = 0.3, loop = true},
		walk = {range = {x = 110, y = 130}, speed = 40, frame_blend = 0.3, loop = true},
		fly = {range = {x = 140, y = 160}, speed = 40, frame_blend = 0.3, loop = true}
	},
	--follow = {},
	drops = {
		{name = "pegasus:feather", min = 1, max = 1, chance = 2}
	},

	-- Behavior Parameters
	uses_boids = true,

	-- pegasus Props
	flee_puncher = true,
	catch_with_net = true,
	catch_with_lasso = false,
	wander_action = pegasus.action_boid_move,
	--roost_action = pegasus.action_roost,

	-- Functions
	utility_stack = {
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.fly_landing_wander,
		pegasus.mob_ai.fly_seek_land
	},

	activate_func = function(self)
		if pegasus.despawn_inactive_mob(self) then return end
		pegasus.initialize_api(self)
		pegasus.initialize_lasso(self)
		self.is_landed = (random(2) < 2 and true) or false
	end,

	step_func = function(self)
		pegasus.step_timers(self)
		pegasus.do_growth(self, 60)
		--pegasus.update_lasso_effects(self)
		pegasus.rotate_to_pitch(self)
		if self:timer(random(6, 12)) then
			if pegasus.is_day then
				if self.texture_no == 1 then
					self:play_sound("cardinal")
				elseif self.texture_no == 2 then
					self:play_sound("eastern_blue")
				else
					self:play_sound("goldfinch")
				end
			end
		end
		if not self.is_landed
		or not self.touching_ground then
			self.speed = 4
		else
			self.speed = 3
		end
	end,

	death_func = pegasus.death_func,

	on_rightclick = function(self, clicker)
		--[[if pegasus.feed(self, clicker, false, false) then
			return
		end]]
		if pegasus.set_nametag(self, clicker) then
			return
		end
	end,

	on_punch = pegasus.punch
})

creatura.register_spawn_item("pegasus:song_bird", {
	col1 = "ae2f2f",
	col2 = "f3ac1c"
})

minetest.register_entity("pegasus:bird", {
	static_save = false,
	on_activate = function(self)
		self.object:remove()
	end
})

minetest.register_abm({
	label = "pegasus:nest_cleanup",
	nodenames = "pegasus:nest_song_bird",
	interval = 900,
	action = function(pos)
		minetest.remove_node(pos)
	end
})