----------
-- Bear --
----------

creatura.register_mob("pegasus:grizzly_bear", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_bear.b3d",
	textures = {
		"pegasus_bear_grizzly.png"
	},
	makes_footstep_sound = true,

	-- Creatura Props
	max_health = 20,
	armor_groups = {fleshy = 100},
	damage = 6,
	speed = 4,
	tracking_range = 10,
	despawn_after = 1000,
	max_fall = 3,
	stepheight = 1.1,
	sounds = {
		random = {
			name = "pegasus_bear",
			gain = 0.5,
			distance = 8
		},
		hurt = {
			name = "pegasus_bear_hurt",
			gain = 0.5,
			distance = 8
		},
		death = {
			name = "pegasus_bear_death",
			gain = 0.5,
			distance = 8
		}
	},
	hitbox = {
		width = 0.5,
		height = 1
	},
	animations = {
		stand = {range = {x = 1, y = 59}, speed = 10, frame_blend = 0.3, loop = true},
		walk = {range = {x = 61, y = 79}, speed = 10, frame_blend = 0.3, loop = true},
		run = {range = {x = 81, y = 99}, speed = 20, frame_blend = 0.3, loop = true},
		melee = {range = {x = 101, y = 120}, speed = 30, frame_blend = 0.3, loop = false}
	},
	follow = pegasus.food_bear,
	drops = {
		{name = "pegasus:pelt_bear", min = 1, max = 3, chance = 1}
	},
	fancy_collide = false,

	-- Behavior Parameters
	attacks_players = true,

	-- pegasus Parameters
	catch_with_net = true,
	catch_with_lasso = true,
	head_data = {
		offset = {x = 0, y = 0.35, z = 0.0},
		pitch_correction = -45,
		pivot_h = 0.75,
		pivot_v = 1
	},

	-- Functions
	utility_stack = {
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.swim_seek_land,
		pegasus.mob_ai.basic_seek_food,
		pegasus.mob_ai.basic_attack,
		pegasus.mob_ai.basic_breed
	},

	on_eat_drop = function(self)
		local feed_no = (self.feed_no or 0) + 1

		if feed_no >= 5 then
			feed_no = 0

			if self.breeding then return false end
            if self.breeding_cooldown <= 0 then
                 self.breeding = true
                self.breeding_cooldown = 60
                pegasus.particle_spawner(self.stand_pos, "heart.png", "float")
			end

			self._despawn = self:memorize("_despawn", false)
			self.despawn_after = self:memorize("despawn_after", false)
		end
		self.feed_no = feed_no
	end,

	activate_func = function(self)
		pegasus.initialize_api(self)
		pegasus.initialize_lasso(self)
	end,

	step_func = function(self)
		pegasus.step_timers(self)
		pegasus.head_tracking(self, 0.75, 0.75)
		pegasus.do_growth(self, 60)
		pegasus.update_lasso_effects(self)
		pegasus.random_sound(self)
	end,

	death_func = function(self)
		if self:get_utility() ~= "pegasus:die" then
			self:initiate_utility("pegasus:die", self)
		end
	end,

	on_punch = pegasus.punch
})

creatura.register_spawn_item("pegasus:grizzly_bear", {
	col1 = "64361d",
	col2 = "2c0d03"
})
