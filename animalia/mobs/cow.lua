---------
-- Cow --
---------

creatura.register_mob("pegasus:cow", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_cow.b3d",
	female_textures = {
		"pegasus_cow_1.png^pegasus_cow_udder.png",
		"pegasus_cow_2.png^pegasus_cow_udder.png",
		"pegasus_cow_3.png^pegasus_cow_udder.png",
		"pegasus_cow_4.png^pegasus_cow_udder.png",
		"pegasus_cow_5.png^pegasus_cow_udder.png"
	},
	male_textures = {
		"pegasus_cow_1.png",
		"pegasus_cow_2.png",
		"pegasus_cow_3.png",
		"pegasus_cow_4.png",
		"pegasus_cow_5.png"
	},
	child_textures = {
		"pegasus_cow_1.png",
		"pegasus_cow_2.png",
		"pegasus_cow_3.png",
		"pegasus_cow_4.png",
		"pegasus_cow_5.png"
	},
	makes_footstep_sound = true,

	-- Creatura Props
	max_health = 20,
	armor_groups = {fleshy = 100},
	damage = 0,
	speed = 2,
	tracking_range = 10,
	max_boids = 0,
	despawn_after = 500,
	max_fall = 3,
	stepheight = 1.1,
	sounds = {
		random = {
			name = "pegasus_cow",
			gain = 0.5,
			distance = 8
		},
		hurt = {
			name = "pegasus_cow_hurt",
			gain = 0.5,
			distance = 8
		},
		death = {
			name = "pegasus_cow_death",
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
		walk = {range = {x = 71, y = 89}, speed = 15, frame_blend = 0.3, loop = true},
		run = {range = {x = 71, y = 89}, speed = 30, frame_blend = 0.3, loop = true},
	},
	follow = pegasus.food_wheat,
	drops = {
		{name = "pegasus:beef_raw", min = 1, max = 3, chance = 1},
		{name = "pegasus:leather", min = 1, max = 3, chance = 2}
	},
	fancy_collide = false,

	-- Behavior Parameters
	is_grazing_mob = true,
	is_herding_mob = true,

	-- pegasus Props
	flee_puncher = true,
	catch_with_net = true,
	catch_with_lasso = true,
	consumable_nodes = {
		["default:dirt_with_grass"] = "default:dirt",
		["default:dry_dirt_with_dry_grass"] = "default:dry_dirt"
	},
	head_data = {
		offset = {x = 0, y = 0.5, z = 0.0},
		pitch_correction = -40,
		pivot_h = 0.75,
		pivot_v = 1
	},
	wander_action = pegasus.action_boid_move,

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
		self.collected = self:recall("collected") or false
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

	on_rightclick = function(self, clicker)
		if pegasus.feed(self, clicker, false, true)
		or pegasus.set_nametag(self, clicker) then
			return
		end

		local tool = clicker:get_wielded_item()
		local name = clicker:get_player_name()

		if tool:get_name() == "bucket:bucket_empty" then

			if self.growth_scale < 1 then
				return
			end

			if self.collected then
				minetest.chat_send_player(name, "This Cow has already been milked.")
				return
			end

			local inv = clicker:get_inventory()

			tool:take_item()
			clicker:set_wielded_item(tool)

			if inv:room_for_item("main", {name = "pegasus:bucket_milk"}) then
				clicker:get_inventory():add_item("main", "pegasus:bucket_milk")
			else
				local pos = self.object:get_pos()
				pos.y = pos.y + 0.5
				minetest.add_item(pos, {name = "pegasus:bucket_milk"})
			end

			self.collected = self:memorize("collected", true)
			return
		end
	end,

	on_punch = pegasus.punch
})

creatura.register_spawn_item("pegasus:cow", {
	col1 = "cac3a1",
	col2 = "464438"
})
