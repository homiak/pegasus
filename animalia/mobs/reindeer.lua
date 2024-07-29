--------------
-- Reindeer --
--------------

creatura.register_mob("pegasus:reindeer", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_reindeer.b3d",
	textures = {"pegasus_reindeer.png"},
	child_textures = {"pegasus_reindeer_calf.png"},
	makes_footstep_sound = true,

	-- Creatura Props
	max_health = 15,
	damage = 0,
	speed = 3,
	tracking_range = 12,
	max_boids = 4,
	despawn_after = 500,
	stepheight = 1.1,
	sounds = {
		random = {
			name = "pegasus_reindeer",
			gain = 0.5,
			distance = 8
		},
		hurt = {
			name = "pegasus_reindeer_hurt",
			gain = 0.5,
			distance = 8
		},
		death = {
			name = "pegasus_reindeer_death",
			gain = 0.5,
			distance = 8
		}
	},
	hitbox = {
		width = 0.45,
		height = 0.9
	},
	animations = {
		stand = {range = {x = 1, y = 59}, speed = 10, frame_blend = 0.3, loop = true},
		walk = {range = {x = 70, y = 89}, speed = 30, frame_blend = 0.3, loop = true},
		run = {range = {x = 100, y = 119}, speed = 40, frame_blend = 0.3, loop = true},
		eat = {range = {x = 130, y = 150}, speed = 20, frame_blend = 0.3, loop = false}
	},
	follow = pegasus.food_wheat,
	drops = {
		{name = "pegasus:venison_raw", min = 1, max = 3, chance = 1},
		{name = "pegasus:leather", min = 1, max = 3, chance = 2}
	},

	-- Behavior Parameters
	is_grazing_mob = true,
	is_herding_mob = true,

	-- pegasus Props
	flee_puncher = true,
	catch_with_net = true,
	catch_with_lasso = true,
	consumable_nodes = {
		{
			name = "default:dirt_with_grass",
			replacement = "default:dirt"
		},
		{
			name = "default:dry_dirt_with_dry_grass",
			replacement = "default:dry_dirt"
		}
	},
	head_data = {
		offset = {x = 0, y = 0.55, z = 0},
		pitch_correction = -45,
		pivot_h = 1,
		pivot_v = 1
	},

	-- Functions
	utility_stack = {
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.swim_seek_land,
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
		pegasus.head_tracking(self)
		pegasus.do_growth(self, 60)
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

creatura.register_spawn_item("pegasus:reindeer", {
	col1 = "413022",
	col2 = "d5c0a3"
})