-------------
-- Pegasus --
-------------

local random = math.random

-- Glowing in the night

local function is_night()
    local time = minetest.get_timeofday()
    return time < 0.2 or time > 0.8
end

local function set_glowing_eyes(self)
    local props = self.object:get_properties()
    if is_night() then
        props.glow = 14
    else
        props.glow = 0
    end
    self.object:set_properties(props)
end

-- Grow crops --

local function grow_nearby_crops(self)
    local pos = self.object:get_pos()
    if not pos then
        return
    end

    local radius = 10  -- Radius around the Pegasus to check for crops
    for x = -radius, radius do
        for y = -1, 1 do  -- Check one block below and above
            for z = -radius, radius do
                local crop_pos = vector.add(pos, {x=x, y=y, z=z})
                local node = minetest.get_node(crop_pos)
                

                -- Simplified crop growth logic
                if node.name:find("farming:wheat_") and node.name ~= "farming:wheat_8" then
                    local new_stage = tonumber(node.name:sub(-1)) + 1
                    if new_stage > 8 then new_stage = 8 end
                    local new_node_name = "farming:wheat_" .. new_stage
                    minetest.set_node(crop_pos, {name = new_node_name})
				end
				if node.name:find("farming:cotton_") and node.name ~= "farming:cotton_8" then
                    local new_stage = tonumber(node.name:sub(-1)) + 1
                    if new_stage > 8 then new_stage = 8 end
                    local new_node_name = "farming:cotton_" .. new_stage
                    minetest.set_node(crop_pos, {name = new_node_name})
				end
            end
        end
    end
end

-- Pegasus Inventory

local form_obj = {}

local function create_pegasus_inventory(self)
	if not self.owner then return end
	local inv_name = "pegasus:pegasus_" .. self.owner
	local inv = minetest.create_detached_inventory(inv_name, {
		allow_move = function(_, _, _, _, _, count)
			return count
		end,
		allow_put = function(_, _, _, stack)
			return stack:get_count()
		end,
		allow_take = function(_, _, _, stack)
			return stack:get_count()
		end
	})
	inv:set_size("main", 12)
	inv:set_width("main", 4)
	return inv
end

local function serialize_pegasus_inventory(self)
	if not self.owner then return end
	local inv_name = "pegasus:pegasus_" .. self.owner
	local inv = minetest.get_inventory({ type = "detached", name = inv_name })
	if not inv then return end
	local list = inv:get_list("main")
	local stored = {}
	for k, item in ipairs(list) do
		local itemstr = item:to_string()
		if itemstr ~= "" then
			stored[k] = itemstr
		end
	end
	self._inventory = self:memorize("_inventory", minetest.serialize(stored))
end

local function get_form(self, player_name)
	local inv = create_pegasus_inventory(self)
	if inv and self._inventory then
		inv:set_list("main", minetest.deserialize(self._inventory))
	end

	local frame_range = self.animations["stand"].range
	local frame_loop = frame_range.x .. "," .. frame_range.y
	local texture = self:get_props().textures[1]
	local form = {
		"formspec_version[3]",
		"size[10.5,10.5]",
		"image[0,0;10.5,5.25;pegasus_form_pegasus_bg.png]",
		"model[0,0.5;5,3.5;mob_mesh;pegasus_pegasus.b3d;" .. texture .. ";-10,-130;false;false;" .. frame_loop .. ";15]",
		"list[detached:pegasus:pegasus_" .. player_name .. ";main;5.4,0.5;4,3;]",
		"list[current_player;main;0.4,5.4;8,4;]",
		"listring[current_player;main]",
		"button[1,4.5;2.5,0.8;follow;Follow]",
        "button[3.75,4.5;2.5,0.8;stay;Stay]",
        "button[6.5,4.5;2.5,0.8;wander;Wander]",
        "button[9.25,4.5;1.75,0.8;fire;Fire]"
	}

	return table.concat(form, "")
end

local function close_form(player)
	local name = player:get_player_name()

	if form_obj[name] then
		form_obj[name] = nil
		minetest.remove_detached_inventory("pegasus:pegasus_" .. name)
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if not form_obj[name] or not form_obj[name]:get_yaw() then
		return
	end
	local obj = form_obj[name]
	if formname == "pegasus:pegasus_forms" then
		local ent = obj and obj:get_luaentity()
		if not ent then return end

		if fields.quit or fields.key_enter then
			form_obj[name] = nil
			serialize_pegasus_inventory(ent)
			minetest.remove_detached_inventory("animlaia:pegasus_" .. name)
		end
	end

	if formname == "pegasus:pegasus_inv" then
		local ent = obj and obj:get_luaentity()
		if not ent then return end

		if fields.quit or fields.key_enter then
			form_obj[name] = nil
			serialize_pegasus_inventory(ent)
			minetest.remove_detached_inventory("pegasus:pegasus_" .. name)
		end
	end
end)

minetest.register_on_leaveplayer(close_form)

-- Pattern

local patterns = {
	"pegasus_pegasus_pattern_1.png",
	"pegasus_pegasus_pattern_2.png",
	"pegasus_pegasus_pattern_3.png"
}

local avlbl_colors = {
	[1] = {
		"pegasus.png"
	},
	[2] = {
		"pegasus.png",
	},
	[3] = {
		"pegasus.png"
	},
	[4] = {
		"pegasus.png"
	},
	[5] = {
		"pegasus.png"
	}
}

local function set_pattern(self)
	local pattern_no = self:recall("pattern_no")
	if pattern_no and pattern_no < 1 then return end
	if not pattern_no then
		if random(3) < 2 then
			pattern_no = self:memorize("pattern_no", random(#patterns))
		else
			self:memorize("pattern_no", 0)
			return
		end
	end
	local colors = avlbl_colors[self.texture_no]
	local color_no = self:recall("color_no") or self:memorize("color_no", random(#colors))
	if not colors[color_no] then return end
	local pattern = "(" .. patterns[pattern_no] .. "^[mask:" .. colors[color_no] .. ")"
	local texture = self.textures[self.texture_no]
	self.object:set_properties({
		textures = { texture .. "^" .. pattern }
	})
end

-- Definition

modding.register_mob("pegasus:pegasus", {
	-- Engine Props
	visual_size = { x = 10, y = 10 },
	mesh = "pegasus_pegasus.b3d",
	textures = {
		"pegasus.png",
	},
	makes_footstep_sound = true,

	-- modding Props
	max_health = 200,
	armor_groups = { fleshy = 100 },
	damage = 40,
	speed = 200000,
	tracking_range = 16,
	max_boids = 7,
	despawn_after = false,
	max_fall = 0,
	stepheight = 1.2,
	sounds = {
		alter_child_pitch = true,
		random = {
			name = "pegasus_pegasus_idle",
			gain = 1.0,
			distance = 8
		},
		hurt = {
			name = "pegasus_pegasus_hurt",
			gain = 1.0,
			distance = 8
		},
		death = {
			name = "pegasus_pegasus_death",
			gain = 1.0,
			distance = 8
		}
	},
	hitbox = {
		width = 0.65,
		height = 1.95
	},
	animations = {
		stand = { range = { x = 1, y = 59 }, speed = 10, frame_blend = 0.3, loop = true },
		walk = { range = { x = 70, y = 89 }, speed = 20, frame_blend = 0.3, loop = true },
		run = { range = { x = 101, y = 119 }, speed = 40, frame_blend = 0.3, loop = true },
		punch_aoe = { range = { x = 170, y = 205 }, speed = 30, frame_blend = 0.2, loop = false },
		rear = { range = { x = 130, y = 160 }, speed = 20, frame_blend = 0.1, loop = false },
		eat = { range = { x = 210, y = 240 }, speed = 30, frame_blend = 0.3, loop = false }
	},
	follow = pegasus.food_wheat,
	drops = {
		{ name = "pegasus:leather",  min = 1, max = 4, chance = 2 },
		{ name = "pegasus:beef_raw", min = 1, max = 4, chance = 2 }
	},
	fancy_collide = false,

	-- Behavior Parameters
	is_grazing_mob = true,
	is_herding_mob = true,

	-- Pegasus Props
	catch_with_net = true,
	catch_with_lasso = true,
	consumable_nodes = {
		["default:dirt_with_grass"] = "default:dirt",
		["default:dry_dirt_with_dry_grass"] = "default:dry_dirt"
	},
	head_data = {
		bone = "Neck.CTRL",
		offset = { x = 0, y = 1.4, z = 0.0 },
		pitch_correction = 15,
		pivot_h = 1,
		pivot_v = 1.75
	},
	utility_stack = {
		pegasus.mob_ai.basic_wander,
		pegasus.mob_ai.swim_seek_land,
		pegasus.mob_ai.basic_breed,
		pegasus.mob_ai.basic_flee,
		{
			utility = "pegasus:pegasus_tame",
			get_score = function(self)
				local rider = not self.owner and self.rider
				if rider
					and rider:get_pos() then
					return 0.7, { self }
				end
				return 0
			end
		},
		{
			utility = "pegasus:pegasus_ride",
			get_score = function(self)
				if not self.owner then return 0 end
				local owner = self.owner and minetest.get_player_by_name(self.owner)
				local rider = owner == self.rider and self.rider
				if rider
					and rider:get_pos() then
					return 0.8, { self, rider }
				end
				return 0
			end
		},
		{
			utility = "pegasus:rescue_animal",
    get_score = function(self)
        local pos = self.object:get_pos()
        if not pos then return 0 end
        
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 100)) do
            local ent = obj:get_luaentity()
            if ent and ent.name ~= self.name then  -- Ignore owned mobs
                local health = ent.health or (ent.object and ent.object:get_hp())
                local max_health = ent.max_health or (ent.object and ent.object:get_properties().hp_max)
                if health and max_health and health < max_health * 0.5 then  -- Only rescue if health is below 50%
                    return 0.9, {self, obj, ent}
                end
            end
        end
        return 0
    end
		},
	},

	-- Functions
	set_saddle = function(self, saddle)
		if saddle then
			self.saddled = self:memorize("saddled", true)
			local texture = self.object:get_properties().textures[1]
			self.object:set_properties({
				textures = { texture .. "^pegasus_pegasus_saddle.png" }
			})
			self.drops = {
				{ name = "pegasus:leather",  chance = 2, min = 1, max = 4 },
				{ name = "pegasus:beef_raw", chance = 2, min = 1, max = 4 },
				{ name = "pegasus:saddle",   chance = 1, min = 1, max = 1 }
			}
		else
			local pos = self.object:get_pos()
			if not pos then return end
			self.saddled = self:memorize("saddled", false)
			set_pattern(self)
			self.drops = {
				{ name = "pegasus:leather",  chance = 2, min = 1, max = 4 },
				{ name = "pegasus:beef_raw", chance = 2, min = 1, max = 4 },
			}
			minetest.add_item(pos, "pegasus:saddle")
		end
	end,
	custom_name = "", -- Use a custom attribute to store the name

	on_activate = function(self, staticdata)
		if staticdata and staticdata ~= "" then
			self.custom_name = staticdata -- Load the name from staticdata
			self.object:set_nametag_attributes({
				text = self.custom_name,
				color = "#00FFFF"
			})
		end
	end,
	get_staticdata = function(self)
		return self.custom_name -- Save the name as staticdata
	end,
	add_child = function(self, mate)
		local pos = self.object:get_pos()
		if not pos then return end
		local obj = minetest.add_entity(pos, self.name)
		local ent = obj and obj:get_luaentity()
		if not ent then return end
		ent.growth_scale = 0.7
		local tex_no = self.texture_no
		local mate_ent = mate and mate:get_luaentity()
		if mate_ent
			or not mate_ent.speed
			or not mate_ent.jump_power
			or not mate_ent.max_health then
			return
		end
		if random(2) < 2 then
			tex_no = mate_ent.texture_no
		end
		ent:memorize("texture_no", tex_no)
		ent:memorize("speed", random(mate_ent.speed, self.speed))
		ent:memorize("jump_power", random(mate_ent.jump_power, self.jump_power))
		ent:memorize("max_health", random(mate_ent.max_health, self.max_health))
		ent.speed = ent:recall("speed")
		ent.jump_power = ent:recall("jump_power")
		ent.max_health = ent:recall("max_health")
		pegasus.initialize_api(ent)
		pegasus.protect_from_despawn(ent)
	end,

	activate_func = function(self)
		pegasus.initialize_api(self)
		pegasus.initialize_lasso(self)
		pegasus.eat_dropped_item(self, item)
		set_pattern(self)
		set_glowing_eyes(self)

		self.owner = self:recall("owner") or nil

		if self.owner then
			self._inventory = self:recall("_inventory")
		end

		self.rider = nil
		self.saddled = self:recall("saddled") or false
		self.max_health = self:recall("max_health") or random(30, 45)
		self.speed = self:recall("speed") or random(5, 10)
		self.jump_power = self:recall("jump_power") or random(2, 5)
		self:memorize("max_health", self.max_health)
		self:memorize("speed", self.speed)
		self:memorize("jump_power", self.jump_power)
		if self.saddled then
			self:set_saddle(true)
		end
		self.mode = self:recall("mode") or "wander"
	end,

	step_func = function(self)
		pegasus.step_timers(self)
		pegasus.head_tracking(self)
		pegasus.do_growth(self, 60)
		pegasus.update_lasso_effects(self)
		pegasus.random_sound(self)
		pegasus.eat_dropped_item(self, item)
		if self:timer(2) then  -- Check every 2 seconds to reduce performance impact
			grow_nearby_crops(self)
		end
		set_glowing_eyes(self)
		if self.rider then
			-- If there's a rider, prioritize the riding utility
			if self:get_utility() ~= "pegasus:pegasus_ride" then
				self:initiate_utility("pegasus:pegasus_ride", self, self.rider)
			end
		else
			-- If there's no rider, execute mode-specific behavior
			if self.mode == "follow" and self.owner then
				local owner = minetest.get_player_by_name(self.owner)
				local max_chase_distance = 20
				
				if owner then
					local owner_pos = owner:get_pos()
					local self_pos = self.object:get_pos()
					if self_pos and owner_pos then
						local distance = vector.distance(self_pos, owner_pos)
						if distance > 3 then
							self:animate("run")
							self:move_to(owner_pos, "modding:obstacle_avoidance", 1)
						else
							self:animate("stand")
							self.object:set_velocity({x=0, y=0, z=0})
						end
					end
				end
			elseif self.mode == "stay" then
				self:animate("stand")
				self.object:set_velocity({x=0, y=0, z=0})
				if self:get_utility() then
					self:set_utility(nil)
				end
				self.object:set_yaw(self.object:get_yaw())
			elseif self.mode == "wander" then
				if not self:get_utility() then
					self:initiate_utility("pegasus:basic_wander", self)
				end
			end
		end
		-- Danger
		local danger = check_for_danger(self)
    if danger and not self.fire_breathing and self:timer(1) then
        local danger_pos = danger:get_pos()
        local self_pos = self.object:get_pos()
        local distance = vector.distance(self_pos, danger_pos)
        local dir = vector.direction(self_pos, danger_pos)
        
        self.object:set_yaw(math.atan2(dir.z, dir.x) - math.pi/2)
        
        if distance > 8 then
            self:animate("run")
            self:move_to(danger_pos, "modding:obstacle_avoidance", 2)
        else
            if math.random() < 0.9 then
                self.fire_breathing = true
                pegasus_breathe_fire(self)
                minetest.after(2, function()
                    self.fire_breathing = false
                end)
            else
                local retreat_pos = vector.subtract(self_pos, vector.multiply(dir, 5))
                self:move_to(retreat_pos, "modding:obstacle_avoidance", 2)
            end
        end
        return
    end
	end,

	death_func = function(self)
		if self.rider then
			pegasus.mount(self, self.rider)
		end
		if self:get_utility() ~= "pegasus:die" then
			self:initiate_utility("pegasus:die", self)
		end
	end,

	on_rightclick = function(self, clicker)
		if pegasus.feed(self, clicker, false, true) then
			return
		end
		pegasus.eat_dropped_item(self, item)
		if not clicker or not clicker:is_player() then return end

		local itemstack = clicker:get_wielded_item()

		if itemstack:get_name() == "pegasus:nametag" then
			minetest.show_formspec(clicker:get_player_name(), "name_pegasus_form",
				"field[name;Enter the name for your Pegasus:;]" ..
				"button_exit[1,2;2,1;submit;Submit]")

			self.last_clicked_by = clicker:get_player_name() -- Store the player name
			return
		end

		local owner = self.owner
		local name = clicker and clicker:get_player_name()
		if owner and name ~= owner then return end

		if pegasus.set_nametag(self, clicker) then
			return
		end

		local wielded_name = clicker:get_wielded_item():get_name()

		if wielded_name == "pegasus:saddle" then
			self:set_saddle(true)
			return
		end

		if clicker:get_player_control().sneak
			and owner then
			minetest.show_formspec(name, "pegasus:pegasus_forms", get_form(self, name))
			form_obj[name] = self.object
		elseif wielded_name == "" then
			pegasus.mount(self, clicker, { rot = { x = -65, y = 180, z = 0 }, pos = { x = 0, y = 0.75, z = 0.6 } })
			if self.saddled then
				self:initiate_utility("pegasus:mount", self, clicker)
			end
		end
	end,

	on_punch = function(self, puncher, ...)
		if self.rider and puncher == self.rider then return end
		local name = puncher:is_player() and puncher:get_player_name()
		if name
			and name == self.owner
			and puncher:get_player_control().sneak then
			self:set_saddle(false)
			return
		end
		pegasus.punch(self, puncher, ...)
	end,

	on_detach_child = function(self, child)
		if child
			and self.rider == child then
			self.rider = nil
			child:set_eye_offset({ x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
			child:set_properties({ visual_size = { x = 1, y = 1 } })
			pegasus.animate_player(child, "stand", 30)
		end
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "name_pegasus_form" and fields.name then
		local pegasus_entities = minetest.get_objects_inside_radius(player:get_pos(), 5) -- Adjust radius if needed
		for _, obj in ipairs(pegasus_entities) do
			local entity = obj:get_luaentity()
			if entity and entity.name == "pegasus:pegasus" and entity.last_clicked_by == player:get_player_name() then
				-- Set the name directly as an attribute
				entity.custom_name = fields.name -- Store the name in a custom attribute
				entity.object:set_nametag_attributes({
					text = fields.name,
					color = "#9ff9fc"
				})
				break
			end
		end
	end
end)

modding.register_spawn_item("pegasus:pegasus", {
	col1 = "ebdfd8",
	col2 = "653818"
})

-- Pegasus Orders

local function set_pegasus_mode(self, mode)
	self.mode = mode
	self:memorize("mode", mode)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if formname == "pegasus:pegasus_forms" then
		local obj = form_obj[name]
		if not obj or not obj:get_luaentity() then return end

		local ent = obj:get_luaentity()

		if fields.follow then
            set_pegasus_mode(ent, "follow")
            minetest.chat_send_player(name, "Pegasus set to Follow mode")
        elseif fields.stay then
            set_pegasus_mode(ent, "stay")
            minetest.chat_send_player(name, "Pegasus set to Stay mode")
        elseif fields.wander then
            set_pegasus_mode(ent, "wander")
            minetest.chat_send_player(name, "Pegasus set to Wander mode")
        elseif fields.fire then
            ent.fire_breathing = not ent.fire_breathing
            if ent.fire_breathing then
                minetest.chat_send_player(name, "Pegasus is now breathing fire!")
                pegasus_breathe_fire(ent)
            else
                minetest.chat_send_player(name, "Pegasus stopped breathing fire.")
            end
        end

		if fields.quit or fields.key_enter then
			form_obj[name] = nil
			serialize_pegasus_inventory(ent)
			minetest.remove_detached_inventory("pegasus:pegasus_" .. name)
		else
			minetest.show_formspec(name, "pegasus:pegasus_forms", get_form(ent, name))
		end
	end
end)

-- dangerous Entities

function check_for_danger(self)
    local pos = self.object:get_pos()
    if not pos then return false end

    local objects = minetest.get_objects_inside_radius(pos, 100)
    for _, obj in ipairs(objects) do
        local ent = obj:get_luaentity()
        if ent and ent.type == "monster" then
            return obj
        end
    end
    return false
end

-- Rescue animals --

modding.register_utility("pegasus:rescue_animal", function(self, victim, victim_ent)
    local function rescue_func(_self)
        if not victim or not victim:get_pos() then
            return true
        end

        local victim_pos = victim:get_pos()
        local attacker = nil

        for _, obj in ipairs(minetest.get_objects_inside_radius(victim_pos, 5)) do
            if obj:is_player() and obj:get_player_name() ~= self.owner then
                attacker = obj
                break
            end
        end

        if attacker then
            _self:animate("rear")
            
            local function breathe_fire()
                if _self.object:get_pos() and attacker:get_pos() then
                    local attacker_pos = attacker:get_pos()
                    if _self.breathe_fire then
                        _self:breathe_fire(attacker_pos)
                    elseif pegasus_breathe_fire then
                        pegasus_breathe_fire(_self, attacker_pos)
                    end
                    
                    if _self.fire_breath_count and _self.fire_breath_count < 5 then
                        _self.fire_breath_count = _self.fire_breath_count + 1
                        minetest.after(1, breathe_fire)
                    else
                        _self.fire_breath_count = nil
                        minetest.after(1, function()
                            _self:animate("stand")
                            return true
                        end)
                    end
                end
            end

            _self.fire_breath_count = 1
            minetest.after(1, breathe_fire)
        else
            _self:animate("stand")
            return true
        end
    end
    
    self:set_utility(rescue_func)
end)