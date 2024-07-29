---------
-- Pig --
---------

creatura.register_mob("pegasus:pig", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_pig.b3d",
	female_textures = {
		"pegasus_pig_1.png",
		"pegasus_pig_2.png",
		"pegasus_pig_3.png"
	},
	male_textures = {
		"pegasus_pig_1.png^pegasus_pig_tusks.png",
		"pegasus_pig_2.png^pegasus_pig_tusks.png",
		"pegasus_pig_3.png^pegasus_pig_tusks.png"
	},
	child_textures = {
		"pegasus_pig_1.png",
		"pegasus_pig_2.png",
		"pegasus_pig_3.png"
	},
	makes_footstep_sound = true,

	-- Creatura Props
	max_health = 20,
	damage = 2,
	speed = 3,
	tracking_range = 12,
	despawn_after = 500,
	stepheight = 1.1,
	sounds = {
		random = {
			name = "pegasus_pig",
			gain = 1.0,
			distance = 8
		},
		hurt = {
			name = "pegasus_pig_hurt",
			gain = 1.0,
			distance = 8
		},
		death = {
			name = "pegasus_pig_death",
			gain = 1.0,
			distance = 8
		}
	},
	hitbox = {
		width = 0.35,
		height = 0.7
	},
	animations = {
		stand = {range = {x = 1, y = 60}, speed = 20, frame_blend = 0.3, loop = true},
		walk = {range = {x = 70, y = 89}, speed = 30, frame_blend = 0.3, loop = true},
		run = {range = {x = 100, y = 119}, speed = 40, frame_blend = 0.3, loop = true},
	},
	follow = pegasus.food_crops,
	drops = {
		{name = "pegasus:porkchop_raw", min = 1, max = 3, chance = 1}
	},

	-- Behavior Parameters
	is_herding_mob = true,

	-- pegasus Props
	flee_puncher = true,
	catch_with_net = true,
	catch_with_lasso = true,
	birth_count = 2,
	head_data = {
		offset = {x = 0, y = 0.7, z = 0},
		pitch_correction = 0,
		pivot_h = 0.5,
		pivot_v = 0.3
	},

	-- Functions
	utility_stack = {
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.swim_seek_land,
		pegasus.mob_ai.basic_seek_crop,
		pegasus.mob_ai.tamed_follow_owner,
		pegasus.mob_ai.basic_breed,
		pegasus.mob_ai.basic_flee
	},

	activate_func = function(self)
		pegasus.initialize_api(self)
		pegasus.initialize_lasso(self)
	end,

	step_func = function(self)
		pegasus.step_timers(self)
		pegasus.do_growth(self, 60)
		pegasus.head_tracking(self)
		pegasus.update_lasso_effects(self)
		pegasus.random_sound(self)
	end,

	death_func = pegasus.death_func,

	on_rightclick = function(self, clicker)
		if pegasus.feed(self, clicker, false, true) then
			return
		end
		if pegasus.set_nametag(self, clicker) then
			return
		end
	end,

	on_punch = pegasus.punch
})

creatura.register_spawn_item("pegasus:pig", {
	col1 = "e0b1a7",
	col2 = "cc9485"
})