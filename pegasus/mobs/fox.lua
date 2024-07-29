---------
-- Fox --
---------

creatura.register_mob("pegasus:fox", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_fox.b3d",
	textures = {
		"pegasus_fox_1.png"
	},
	makes_footstep_sound = false,

	-- Creatura Props
	max_health = 10,
	armor_groups = {fleshy = 100},
	damage = 2,
	speed = 4,
	tracking_range = 16,
	max_boids = 0,
	despawn_after = 500,
	stepheight = 1.1,
	sound = {},
	hitbox = {
		width = 0.35,
		height = 0.5
	},
	animations = {
		stand = {range = {x = 1, y = 39}, speed = 10, frame_blend = 0.3, loop = true},
		walk = {range = {x = 41, y = 59}, speed = 30, frame_blend = 0.3, loop = true},
		run = {range = {x = 41, y = 59}, speed = 45, frame_blend = 0.3, loop = true},
	},
	follow = {
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
		pegasus.mob_ai.fox_flee,
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

creatura.register_spawn_item("pegasus:fox", {
	col1 = "d0602d",
	col2 = "c9c9c9"
})