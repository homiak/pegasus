-------------
-- Opossum --
-------------

creatura.register_mob("pegasus:opossum", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_opossum.b3d",
	textures = {
		"pegasus_opossum.png"
	},
	makes_footstep_sound = false,

	-- Creatura Props
	max_health = 5,
	armor_groups = {fleshy = 100},
	damage = 2,
	speed = 4,
	tracking_range = 16,
	max_boids = 0,
	despawn_after = 500,
	stepheight = 1.1,
	max_fall = 8,
	sound = {},
	hitbox = {
		width = 0.25,
		height = 0.4
	},
	animations = {
		stand = {range = {x = 1, y = 59}, speed = 10, frame_blend = 0.3, loop = true},
		walk = {range = {x = 70, y = 89}, speed = 30, frame_blend = 0.3, loop = true},
		run = {range = {x = 100, y = 119}, speed = 45, frame_blend = 0.3, loop = true},
		feint = {range = {x = 130, y = 130}, speed = 45, frame_blend = 0.3, loop = false},
		clean_crop = {range = {x = 171, y = 200}, speed = 15, frame_blend = 0.2, loop = false}
	},
	follow = {
		"pegasus:song_bird_egg",
		"pegasus:mutton_raw",
		"pegasus:beef_raw",
		"pegasus:porkchop_raw",
		"pegasus:poultry_raw"
	},


	-- pegasus Props
	flee_puncher = true,
	catch_with_net = true,
	catch_with_lasso = true,
	head_data = {
		offset = {x = 0, y = 0.18, z = 0},
		pitch_correction = -67,
		pivot_h = 0.65,
		pivot_v = 0.65
	},

	-- Functions
	utility_stack = {
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.swim_seek_land,
		pegasus.mob_ai.basic_attack,
		pegasus.mob_ai.opossum_feint,
		pegasus.mob_ai.opossum_seek_crop,
		pegasus.mob_ai.basic_seek_food,
		pegasus.mob_ai.tamed_follow_owner,
		pegasus.mob_ai.basic_breed
	},

	on_eat_drop = function(self)
		pegasus.protect_from_despawn(self)
	end,

	activate_func = function(self)
		pegasus.initialize_api(self)
		pegasus.initialize_lasso(self)
	end,

	step_func = function(self)
		pegasus.step_timers(self)
		pegasus.head_tracking(self, 0.5, 0.75)
		pegasus.do_growth(self, 60)
		pegasus.update_lasso_effects(self)
	end,

	death_func = pegasus.death_func,

	on_rightclick = function(self, clicker)
		if pegasus.feed(self, clicker, true, true) then
			return
		end
		if pegasus.set_nametag(self, clicker) then
			return
		end
	end,

	on_punch = pegasus.punch
})

creatura.register_spawn_item("pegasus:opossum", {
	col1 = "75665f",
	col2 = "ccbfb8"
})
