------------
-- Turkey --
------------

creatura.register_mob("pegasus:turkey", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_turkey.b3d",
	female_textures = {"pegasus_turkey_hen.png"},
	male_textures = {"pegasus_turkey_tom.png"},
	child_textures = {"pegasus_turkey_chick.png"},
	makes_footstep_sound = true,

	-- Creatura Props
	max_health = 8,
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
			name = "pegasus_turkey",
			gain = 0.5,
			distance = 8
		},
		hurt = {
			name = "pegasus_turkey_hurt",
			gain = 0.5,
			distance = 8
		},
		death = {
			name = "pegasus_turkey_death",
			gain = 0.5,
			distance = 8
		}
	},
	hitbox = {
		width = 0.3,
		height = 0.6
	},
	animations = {
		stand = {range = {x = 0, y = 0}, speed = 1, frame_blend = 0.3, loop = true},
		walk = {range = {x = 10, y = 30}, speed = 30, frame_blend = 0.3, loop = true},
		run = {range = {x = 40, y = 60}, speed = 45, frame_blend = 0.3, loop = true},
		fall = {range = {x = 70, y = 90}, speed = 30, frame_blend = 0.3, loop = true},
	},
	follow = pegasus.food_seeds,
	drops = {
		{name = "pegasus:poultry_raw", min = 1, max = 4, chance = 1},
		{name = "pegasus:feather", min = 1, max = 3, chance = 2}
	},

	-- pegasus Props
	group_wander = true,
	flee_puncher = true,
	catch_with_net = true,
	catch_with_lasso = true,
	head_data = {
		offset = {x = 0, y = 0.15, z = 0},
		pitch_correction = 45,
		pivot_h = 0.45,
		pivot_v = 0.65
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
			pegasus.random_drop_item(self, "pegasus:turkey_egg", 10)
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

creatura.register_spawn_item("pegasus:turkey", {
	col1 = "352b22",
	col2 = "2f2721"
})
