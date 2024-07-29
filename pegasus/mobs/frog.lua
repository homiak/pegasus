----------
-- Frog --
----------

local random = math.random

local function poison_effect(object)
	object:punch(object, 1.0, {
		full_punch_interval = 1.0,
		damage_groups = {fleshy = 1},
	})
end

local hitboxes = {
	{-0.25, 0, -0.25, 0.2, 0.4, 0.25},
	{-0.4, 0, -0.4, 0.4, 0.5, 0.4},
	{-0.15, 0, -0.15, 0.15, 0.3, 0.15}
}

local animations = {
	{
		stand = {range = {x = 1, y = 40}, speed = 10, frame_blend = 0.3, loop = true},
		float = {range = {x = 90, y = 90}, speed = 1, frame_blend = 0.3, loop = true},
		swim = {range = {x = 90, y = 110}, speed = 50, frame_blend = 0.3, loop = true},
		walk = {range = {x = 50, y = 80}, speed = 50, frame_blend = 0.3, loop = true},
		run = {range = {x = 50, y = 80}, speed = 60, frame_blend = 0.3, loop = true}
	},
	{
		stand = {range = {x = 1, y = 40}, speed = 10, frame_blend = 0.3, loop = true},
		walk = {range = {x = 50, y = 79}, speed = 20, frame_blend = 0.3, loop = true},
		run = {range = {x = 50, y = 79}, speed = 30, frame_blend = 0.3, loop = true},
		warn = {range = {x = 90, y = 129}, speed = 30, frame_blend = 0.3, loop = true},
		punch = {range = {x = 140, y = 160}, speed = 30, frame_blend = 0.1, loop = false},
		float = {range = {x = 170, y = 209}, speed = 10, frame_blend = 0.3, loop = true},
		swim = {range = {x = 220, y = 239}, speed = 20, frame_blend = 0.3, loop = true}
	},
	{
		stand = {range = {x = 1, y = 40}, speed = 10, frame_blend = 0.3, loop = true},
		walk = {range = {x = 50, y = 69}, speed = 30, frame_blend = 0.3, loop = true},
		run = {range = {x = 50, y = 69}, speed = 40, frame_blend = 0.3, loop = true},
		float = {range = {x = 80, y = 119}, speed = 10, frame_blend = 0.3, loop = true},
		swim = {range = {x = 130, y = 149}, speed = 20, frame_blend = 0.3, loop = true}
	}
}

local utility_stacks = {
	{ -- Tree Frog
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.swim_wander,
		pegasus.mob_ai.frog_seek_bug,
		pegasus.mob_ai.frog_breed,
		pegasus.mob_ai.basic_flee,
		pegasus.mob_ai.frog_flop,
		pegasus.mob_ai.frog_seek_water
	},
	{ -- Bull Frog
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.swim_wander,
		pegasus.mob_ai.basic_seek_food,
		pegasus.mob_ai.basic_attack,
		pegasus.mob_ai.frog_breed,
		pegasus.mob_ai.frog_flop,
		pegasus.mob_ai.frog_seek_water
	},
	{ -- Poison Dart Frog
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.swim_wander,
		pegasus.mob_ai.frog_breed,
		pegasus.mob_ai.basic_flee,
		pegasus.mob_ai.frog_flop,
		pegasus.mob_ai.frog_seek_water
	}
}

local head_data = {
	{
		offset = {x = 0, y = 0.43, z = 0},
		pitch_correction = -15,
		pivot_h = 0.3,
		pivot_v = 0.3
	},
	{
		offset = {x = 0, y = 0.50, z = 0},
		pitch_correction = -20,
		pivot_h = 0.3,
		pivot_v = 0.3
	},
	{
		offset = {x = 0, y = 0.25, z = 0},
		pitch_correction = -20,
		pivot_h = 0.3,
		pivot_v = 0.3
	}
}

local follow = {
	{
		"butterflies:butterfly_white",
		"butterflies:butterfly_violet",
		"butterflies:butterfly_red"
	},
	{
		"pegasus:rat_raw"
	},
	{}
}

creatura.register_mob("pegasus:frog", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	meshes = {
		"pegasus_frog.b3d",
		"pegasus_bull_frog.b3d",
		"pegasus_dart_frog.b3d"
	},
	child_mesh = "pegasus_tadpole.b3d",
	mesh_textures = {
		{
			"pegasus_tree_frog.png"
		},
		{
			"pegasus_bull_frog.png"
		},
		{
			"pegasus_dart_frog_1.png",
			"pegasus_dart_frog_2.png",
			"pegasus_dart_frog_3.png"
		}
	},
	child_textures = {
		"pegasus_tadpole.png"
	},
	makes_footstep_sound = true,

	-- Creatura Props
	max_health = 5,
	armor_groups = {fleshy = 100},
	damage = 2,
	max_breath = 0,
	speed = 2,
	tracking_range = 8,
	max_boids = 0,
	despawn_after = 300,
	max_fall = 0,
	stepheight = 1.1,
	sound = {},
	hitbox = {
		width = 0.15,
		height = 0.3
	},
	animations = {},
	follow = {},
	drops = {},
	fancy_collide = false,
	bouyancy_multiplier = 0,
	hydrodynamics_multiplier = 0.3,

	-- pegasus Props
	flee_puncher = true,
	catch_with_net = true,
	catch_with_lasso = false,
	head_data = {},

	-- Functions
	utility_stack = {},

	on_grown = function(self)
		local mesh_no = self.mesh_no
		self.animations = animations[mesh_no]
		self.utility_stack = utility_stacks[mesh_no]
		self.head_data = head_data[mesh_no]
		self.object:set_properties({
			collisionbox = hitboxes[mesh_no]
		})
	end,

	activate_func = function(self)
		pegasus.initialize_api(self)
		self.trust = self:recall("trust") or {}

		local mesh_no = self.mesh_no

		-- Set Species Properties
		if self.growth_scale >= 0.8 then
			self.animations = animations[mesh_no]
			self.utility_stack = utility_stacks[mesh_no]
			self.object:set_properties({
				collisionbox = hitboxes[mesh_no]
			})
		else
			self.animations = {
				swim = {range = {x = 1, y = 19}, speed = 20, frame_blend = 0.1, loop = true}
			}
			self.utility_stack = utility_stacks[1]
		end

		self.head_data = head_data[mesh_no]

		if mesh_no == 1 then
			for i = 1, 15 do
				local frame = 120 + i
				local anim = {range = {x = frame, y = frame}, speed = 1, frame_blend = 0.3, loop = false}
				self.animations["tongue_" .. i] = anim
			end
		elseif mesh_no == 2 then
			self.object:set_armor_groups({fleshy = 50})
			self.warn_before_attack = true
		end
	end,

	step_func = function(self)
		pegasus.step_timers(self)
		pegasus.head_tracking(self, 0.2, 0.2)
		pegasus.do_growth(self, 60)
		if self:timer(random(5, 15)) then
			self:play_sound("random")
		end

		if not self.mesh_vars_set then
			self.follow = follow[self.mesh_no]
		end
	end,

	death_func = function(self)
		if self:get_utility() ~= "pegasus:die" then
			self:initiate_utility("pegasus:die", self)
		end
	end,

	on_rightclick = function(self, clicker)
		if self.mesh_no ~= 2 then return end
		if pegasus.feed(self, clicker, false, true) then
			pegasus.add_trust(self, clicker, 1)
			return
		end
		if pegasus.set_nametag(self, clicker) then
			return
		end
	end,

	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
		creatura.basic_punch_func(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
		local name = puncher:is_player() and puncher:get_player_name()
		if name then
			self.trust[name] = 0
			self:memorize("trust", self.trust)
			if self.mesh_no == 3 then
				pegasus.set_player_effect(name, poison_effect, 3)
			end
		end
	end
})

creatura.register_spawn_item("pegasus:frog", {
	col1 = "67942e",
	col2 = "294811"
})