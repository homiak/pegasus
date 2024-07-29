----------
-- Mice --
----------

creatura.register_mob("pegasus:rat", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_rat.b3d",
	textures = {
		"pegasus_rat_1.png",
		"pegasus_rat_2.png",
		"pegasus_rat_3.png"
	},

	-- Creatura Props
	max_health = 5,
	damage = 0,
	speed = 1,
	tracking_range = 8,
	despawn_after = 200,
	stepheight = 1.1,
	--sound = {},
	hitbox = {
		width = 0.15,
		height = 0.3
	},
	animations = {
		stand = {range = {x = 1, y = 39}, speed = 20, frame_blend = 0.3, loop = true},
		walk = {range = {x = 51, y = 69}, speed = 20, frame_blend = 0.3, loop = true},
		run = {range = {x = 81, y = 99}, speed = 45, frame_blend = 0.3, loop = true},
		eat = {range = {x = 111, y = 119}, speed = 20, frame_blend = 0.1, loop = false}
	},
	drops = {
		{name = "pegasus:rat_raw", min = 1, max = 1, chance = 1}
	},

	-- Behavior Parameters
	is_skittish_mob = true,

	-- pegasus Props
	flee_puncher = true,
	catch_with_net = true,
	catch_with_lasso = false,

	-- Functions
	utility_stack = {
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.swim_seek_land,
		pegasus.mob_ai.basic_seek_crop,
		pegasus.mob_ai.rat_seek_chest,
		pegasus.mob_ai.basic_flee
	},

	activate_func = function(self)
		pegasus.initialize_api(self)
		pegasus.initialize_lasso(self)
	end,

	step_func = function(self)
		pegasus.step_timers(self)
		pegasus.do_growth(self, 60)
	end,

	death_func = function(self)
		if self:get_utility() ~= "pegasus:die" then
			self:initiate_utility("pegasus:die", self)
		end
	end,

	on_rightclick = function(self, clicker)
		if pegasus.set_nametag(self, clicker) then
			return
		end
	end,

	on_punch = pegasus.punch
})

creatura.register_spawn_item("pegasus:rat", {
	col1 = "605a55",
	col2 = "ff936f"
})
