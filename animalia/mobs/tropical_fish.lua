----------
-- Fish --
----------

creatura.register_mob("pegasus:tropical_fish", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	meshes = {
		"pegasus_clownfish.b3d",
		"pegasus_angelfish.b3d"
	},
	mesh_textures = {
		{
			"pegasus_clownfish.png",
			"pegasus_blue_tang.png"
		},
		{
			"pegasus_angelfish.png"
		}
	},

	-- Creatura Props
	max_health = 5,
	armor_groups = {fleshy = 150},
	damage = 0,
	max_breath = 0,
	speed = 2,
	tracking_range = 6,
	max_boids = 6,
	boid_seperation = 0.3,
	despawn_after = 200,
	max_fall = 0,
	stepheight = 1.1,
	hitbox = {
		width = 0.15,
		height = 0.3
	},
	animations = {
		swim = {range = {x = 1, y = 20}, speed = 20, frame_blend = 0.3, loop = true},
		flop = {range = {x = 30, y = 40}, speed = 20, frame_blend = 0.3, loop = true},
	},
	liquid_submergence = 1,
	liquid_drag = 0,

	-- pegasus Behaviors
	is_aquatic_mob = true,

	-- pegasus Props
	flee_puncher = false,
	catch_with_net = true,
	catch_with_lasso = false,

	-- Functions
	utility_stack = {
		pegasus.mob_ai.swim_wander
	},

	activate_func = function(self)
		pegasus.initialize_api(self)
		pegasus.initialize_lasso(self)
	end,

	step_func = function(self)
		pegasus.step_timers(self)
		pegasus.do_growth(self, 60)
		pegasus.update_lasso_effects(self)
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

creatura.register_spawn_item("pegasus:tropical_fish", {
	col1 = "e28821",
	col2 = "f6e5d2"
})

pegasus.alias_mob("pegasus:clownfish", "pegasus:tropical_fish")
pegasus.alias_mob("pegasus:blue_tang", "pegasus:tropical_fish")
pegasus.alias_mob("pegasus:angelfish", "pegasus:tropical_fish")