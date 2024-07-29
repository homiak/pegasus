-------------
-- Chicken --
-------------

creatura.register_mob("pegasus:chicken", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_chicken.b3d",
	female_textures = {
		"pegasus_chicken_1.png",
		"pegasus_chicken_2.png",
		"pegasus_chicken_3.png"
	},
	male_textures = {
		"pegasus_rooster_1.png",
		"pegasus_rooster_2.png",
		"pegasus_rooster_3.png"
	},
	child_textures = {"pegasus_chicken_child.png"},
	makes_footstep_sound = true,

	-- Creatura Props
	max_health = 5,
	armor_groups = {fleshy = 100},
	damage = 0,
	speed = 2,
	tracking_range = 8,
	max_boids = 3,
	despawn_after = 500,
	max_fall = 0,
	stepheight = 1.1,
	sounds = {
		random = {
			name = "pegasus_chicken",
			gain = 0.5,
			distance = 8
		},
		hurt = {
			name = "pegasus_chicken_hurt",
			gain = 0.5,
			distance = 8
		},
		death = {
			name = "pegasus_chicken_death",
			gain = 0.5,
			distance = 8
		}
	},
	hitbox = {
		width = 0.25,
		height = 0.5
	},
	animations = {
		stand = {range = {x = 1, y = 39}, speed = 20, frame_blend = 0.3, loop = true},
		walk = {range = {x = 41, y = 59}, speed = 30, frame_blend = 0.3, loop = true},
		run = {range = {x = 41, y = 59}, speed = 45, frame_blend = 0.3, loop = true},
		eat = {range = {x = 61, y = 89}, speed = 45, frame_blend = 0.3, loop = true},
		fall = {range = {x = 91, y = 99}, speed = 70, frame_blend = 0.3, loop = true}
	},
	follow = pegasus.food_seeds,
	drops = {
		{name = "pegasus:poultry_raw", min = 1, max = 3, chance = 1},
		{name = "pegasus:feather", min = 1, max = 3, chance = 2}
	},

	-- Behavior Parameters
	is_herding_mob = true,

	-- pegasus Props
	flee_puncher = true,
	catch_with_net = true,
	catch_with_lasso = true,
	head_data = {
		offset = {x = 0, y = 0.45, z = 0},
		pitch_correction = 40,
		pivot_h = 0.25,
		pivot_v = 0.55
	},
	move_chance = 2,
	idle_time = 1,

	-- Functions
	utility_stack = {
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.swim_seek_land,
		pegasus.mob_ai.tamed_follow_owner,
		pegasus.mob_ai.basic_breed,
		pegasus.mob_ai.basic_flee
	},

	add_child = function(self)
		local pos = self.object:get_pos()
		if not pos then return end
		pegasus.particle_spawner(pos, "pegasus_egg_fragment.png", "splash", pos, pos)
		local object = minetest.add_entity(pos, self.name)
		local ent = object:get_luaentity()
		ent.growth_scale = 0.7
		pegasus.initialize_api(ent)
		pegasus.protect_from_despawn(ent)
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
		if self.fall_start then
			self:set_gravity(-4.9)
			self:animate("fall")
		end
		if (self.growth_scale or 1) > 0.8
		and self.gender == "female"
		and self:timer(60) then
			pegasus.random_drop_item(self, "pegasus:chicken_egg", 10)
		end
	end,

	death_func = function(self)
		if self:get_utility() ~= "pegasus:die" then
			self:initiate_utility("pegasus:die", self)
		end
	end,

	on_rightclick = function(self, clicker)
		if pegasus.feed(self, clicker, false, true) then
			return
		end
		pegasus.set_nametag(self, clicker)
	end,

	on_punch = pegasus.punch
})

creatura.register_spawn_item("pegasus:chicken", {
	col1 = "c6c6c6",
	col2 = "d22222"
})
