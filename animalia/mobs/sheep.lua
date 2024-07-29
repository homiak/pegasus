-----------
-- Sheep --
-----------

local random = math.random

local palette  = {
	black = {"Black", "#000000b0"},
	blue = {"Blue", "#015dbb70"},
	brown = {"Brown", "#663300a0"},
	cyan = {"Cyan", "#01ffd870"},
	dark_green = {"Dark Green", "#005b0770"},
	dark_grey = {"Dark Grey",  "#303030b0"},
	green = {"Green", "#61ff0170"},
	grey = {"Grey", "#5b5b5bb0"},
	magenta = {"Magenta", "#ff05bb70"},
	orange = {"Orange", "#ff840170"},
	pink = {"Pink", "#ff65b570"},
	red = {"Red", "#ff0000a0"},
	violet = {"Violet", "#2000c970"},
	white = {"White", "#ababab00"},
	yellow = {"Yellow", "#e3ff0070"},
}

creatura.register_mob("pegasus:sheep", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	mesh = "pegasus_sheep.b3d",
	textures = {
		"pegasus_sheep.png^pegasus_sheep_wool.png"
	},
	child_textures = {
		"pegasus_sheep.png"
	},
	makes_footstep_sound = true,

	-- Creatura Props
	max_health = 15,
	armor_groups = {fleshy = 100},
	damage = 0,
	speed = 3,
	tracking_range = 12,
	max_boids = 4,
	despawn_after = 500,
	stepheight = 1.1,
	sounds = {
		random = {
			name = "pegasus_sheep",
			gain = 1.0,
			distance = 8
		},
		hurt = {
			name = "pegasus_sheep_hurt",
			gain = 1.0,
			distance = 8
		},
		death = {
			name = "pegasus_sheep_death",
			gain = 1.0,
			distance = 8
		}
	},
	hitbox = {
		width = 0.4,
		height = 0.8
	},
	animations = {
		stand = {range = {x = 1, y = 59}, speed = 10, frame_blend = 0.3, loop = true},
		walk = {range = {x = 70, y = 89}, speed = 20, frame_blend = 0.3, loop = true},
		run = {range = {x = 100, y = 119}, speed = 30, frame_blend = 0.3, loop = true},
		eat = {range = {x = 130, y = 150}, speed = 20, frame_blend = 0.3, loop = false}
	},
	follow = pegasus.food_wheat,
	drops = {
		{name = "pegasus:mutton_raw", min = 1, max = 3, chance = 1},
		minetest.get_modpath("wool") and {name = "wool:white", min = 1, max = 3, chance = 2} or nil
	},

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
		offset = {x = 0, y = 0.41, z = 0},
		pitch_correction = -45,
		pivot_h = 0.75,
		pivot_v = 0.85
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

		self.collected = self:recall("collected") or false
		self.dye_color = self:recall("dye_color") or "white"
		if self.collected then
			self.object:set_properties({
				textures = {"pegasus_sheep.png"},
			})
		elseif self.dye_color ~= "white" then
			self.object:set_properties({
				textures = {"pegasus_sheep.png^(pegasus_sheep_wool.png^[multiply:" .. palette[self.dye_color][2] .. ")"},
			})
		end
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
		if self.collected
		or self.growth_scale < 1 then
			return
		end

		local tool = clicker:get_wielded_item()
		local tool_name = tool:get_name()
		local creative = minetest.is_creative_enabled(clicker:get_player_name())

		if tool_name == "pegasus:shears" then
			if not minetest.get_modpath("wool") then
				return
			end

			minetest.add_item(
				self.object:get_pos(),
				ItemStack("wool:" .. self.dye_color .. " " .. random(1, 3))
			)

			self.collected = self:memorize("collected", true)
			self.dye_color = self:memorize("dye_color", "white")

			self.object:set_properties({
				textures = {"pegasus_sheep.png"},
			})

			if not creative then
				tool:add_wear(650)
				clicker:set_wielded_item(tool)
			end
		end

		if tool_name:match("^dye:") then
			local dye_color = tool_name:split(":")[2]
			if palette[dye_color] then
				self.dye_color = self:memorize("dye_color", dye_color)
				self.drops = {
					{name = "pegasus:mutton_raw", chance = 1, min = 1, max = 4},
					{name = "wool:" .. dye_color, chance = 2, min = 1, max = 2},
				}
				self.object:set_properties({
					textures = {"pegasus_sheep.png^(pegasus_sheep_wool.png^[multiply:" .. palette[dye_color][2] .. ")"},
				})
				if not creative then
					tool:take_item()
					clicker:set_wielded_item(tool)
				end
			end
		end
	end,

	on_punch = pegasus.punch
})

creatura.register_spawn_item("pegasus:sheep", {
	col1 = "f4e6cf",
	col2 = "e1ca9b"
})