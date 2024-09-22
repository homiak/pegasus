----------------
-- Craftitems --
----------------

local S = pegasus.S

local color = minetest.colorize

local function correct_name(str)
	if str then
		if str:match(":") then str = str:split(":")[2] end
		return (string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("_", " "))
	end
end

local function mob_storage_use(itemstack, player, pointed)
	local ent = pointed.ref and pointed.ref:get_luaentity()
	if ent
	and (ent.name:match("^pegasus:")
	or ent.name:match("^monstrum:")) then
		local desc = itemstack:get_short_description()
		if itemstack:get_count() > 1 then
			local name = itemstack:get_name()
			local inv = player:get_inventory()
			if inv:room_for_item("main", {name = name}) then
				itemstack:take_item(1)
				inv:add_item("main", name)
			end
			return itemstack
		end
		local plyr_name = player:get_player_name()
		local meta = itemstack:get_meta()
		local mob = meta:get_string("mob") or ""
		if mob == "" then
			pegasus.protect_from_despawn(ent)
			meta:set_string("mob", ent.name)
			meta:set_string("staticdata", ent:get_staticdata())
			local ent_name = correct_name(ent.name)
			local ent_gender = correct_name(ent.gender)
			desc = desc .. " \n" .. color("#a9a9a9", ent_name) .. "\n" .. color("#a9a9a9", ent_gender)
			if ent.trust
			and ent.trust[plyr_name] then
				desc = desc .. "\n Trust: " .. color("#a9a9a9", ent.trust[plyr_name])
			end
			meta:set_string("description", desc)
			player:set_wielded_item(itemstack)
			ent.object:remove()
			return itemstack
		else
			minetest.chat_send_player(plyr_name,
				"This " .. desc .. " already contains a " .. correct_name(mob))
		end
	end
end

-----------
-- Drops --
-----------

minetest.register_craftitem("pegasus:leather", {
	description = S("Leather"),
	inventory_image = "pegasus_leather.png",
	groups = {flammable = 2, leather = 1},
})


-- Meat --

minetest.register_craftitem("pegasus:beef_raw", {
	description = S("Raw Pegasusbeef"),
	inventory_image = "pegasus_beef_raw.png",
	on_use = minetest.item_eat(1),
	groups = {flammable = 2, meat = 1, food_meat = 1},
})

minetest.register_craftitem("pegasus:beef_cooked", {
	description = S("Steak"),
	inventory_image = "pegasus_beef_cooked.png",
	on_use = minetest.item_eat(8),
	groups = {flammable = 2, meat = 1, food_meat = 1},
})

minetest.register_craft({
	type  =  "cooking",
	recipe  = "pegasus:beef_raw",
	output = "pegasus:beef_cooked",
})

-----------
-- Tools --
-----------


local nametag = {}

local function get_rename_formspec(meta)
	local tag = meta:get_string("name") or ""
	local form = {
		"size[8,4]",
		"field[0.5,1;7.5,0;name;" .. minetest.formspec_escape("Enter name:") .. ";" .. tag .. "]",
		"button_exit[2.5,3.5;3,1;set_name;" .. minetest.formspec_escape("Set Name") .. "]"
	}
	return table.concat(form, "")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "pegasus:set_name" and fields.name then
		local name = player:get_player_name()
		if not nametag[name] then
			return
		end
		local itemstack = nametag[name]
		if string.len(fields.name) > 64 then
			fields.name = string.sub(fields.name, 1, 64)
		end
		local meta = itemstack:get_meta()
		meta:set_string("name", fields.name)
		meta:set_string("description", fields.name)
		player:set_wielded_item(itemstack)
		if fields.quit or fields.key_enter then
			nametag[name] = nil
		end
	end
end)

local function nametag_rightclick(itemstack, player, pointed_thing)
	if pointed_thing
	and pointed_thing.type == "object" then
		return
	end
	local name = player:get_player_name()
	nametag[name] = itemstack
	local meta = itemstack:get_meta()
	minetest.show_formspec(name, "pegasus:set_name", get_rename_formspec(meta))
end

minetest.register_craftitem("pegasus:nametag", {
	description = S("Nametag"),
	inventory_image = "pegasus_nametag.png",
	on_rightclick = nametag_rightclick,
	on_secondary_use = nametag_rightclick
})

-- Pegasus Parade --

local wand_users = {}
local parading_pegasi = {}

minetest.register_craftitem("pegasus:parade_wand", {
    description = S("Pegasus Parade Wand"),
    inventory_image = "pegasus_parade_wand.png",
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if pointed_thing.type ~= "node" then return end

        local pos = pointed_thing.under
        if not wand_users[name] then
            wand_users[name] = {pos1 = pos}
            minetest.chat_send_player(name, S("Position 1 set to:") .. " ".. minetest.pos_to_string(pos))
        else
            wand_users[name].pos2 = pos
            minetest.chat_send_player(name, S("Position 1 set to:") .. " " .. minetest.pos_to_string(pos))
            minetest.chat_send_player(name, S("Region set. Sneak near a Pegasus, to begin the parade"))
        end
    end
})

local function start_animation(pegasus, anim)
    local ent = pegasus:get_luaentity()
    if ent and ent.animations and ent.animations[anim] then
        local start_frame = ent.animations[anim].range.x
        local end_frame = ent.animations[anim].range.y
        local speed = ent.animations[anim].speed or 15
        pegasus:set_animation({x = start_frame, y = end_frame}, speed, 0)
    end
end

local function start_pegasus_parade(pegasus, pos1, pos2)
    local parade_points = {
        pos1,
        {x=pos1.x, y=pos1.y, z=pos2.z},
        pos2,
        {x=pos2.x, y=pos2.y, z=pos1.z},
        pos1
    }
    parading_pegasi[pegasus] = {
        points = parade_points,
        current_point = 1,
        original_pos = pegasus.object:get_pos()
    }
    start_animation(pegasus.object, "walk")
end

local function stop_pegasus_parade(pegasus)
    if parading_pegasi[pegasus] then
        start_animation(pegasus.object, "stand")
        parading_pegasi[pegasus] = nil
        return true
    end
    return false
end

local function is_walkable(pos)
    local node = minetest.get_node(pos)
    local node_def = minetest.registered_nodes[node.name]
    return node_def and node_def.walkable
end

local function can_jump_over(pos)
    local above1 = {x = pos.x, y = pos.y + 1, z = pos.z}
    local above2 = {x = pos.x, y = pos.y + 2, z = pos.z}
    return not is_walkable(above1) and not is_walkable(above2)
end

local function find_path(start_pos, end_pos)
    local direction = vector.direction(start_pos, end_pos)
    local check_pos = vector.round(vector.add(start_pos, direction))
    
    if not is_walkable(check_pos) then
        return check_pos
    elseif can_jump_over(check_pos) then
        return {x = check_pos.x, y = check_pos.y + 1, z = check_pos.z}
    else

        local side_dirs = {
            {x = direction.z, y = 0, z = -direction.x},
            {x = -direction.z, y = 0, z = direction.x}
        }
        for _, side_dir in ipairs(side_dirs) do
            local side_pos = vector.add(start_pos, side_dir)
            if not is_walkable(side_pos) then
                return side_pos
            end
        end
    end
    

    local below_pos = {x = start_pos.x, y = start_pos.y - 1, z = start_pos.z}
    if not is_walkable(below_pos) then
        return below_pos
    end
    
    return start_pos
end

local function move_pegasus(pegasus, parade_info, dtime)
    local target = parade_info.points[parade_info.current_point]
    local pos = pegasus.object:get_pos()
    local distance = vector.distance(pos, target)

    if distance < 0.5 then
        parade_info.current_point = parade_info.current_point % (#parade_info.points - 1) + 1
        target = parade_info.points[parade_info.current_point]
    end

    local next_pos = find_path(pos, target)
    local direction = vector.direction(pos, next_pos)
    local speed = 4
    local new_pos = vector.add(pos, vector.multiply(direction, dtime * speed))
    

    new_pos.x = math.floor(new_pos.x * 10) / 10
    new_pos.y = math.floor(new_pos.y * 10) / 10
    new_pos.z = math.floor(new_pos.z * 10) / 10
    
    pegasus.object:set_pos(new_pos)
    pegasus.object:set_yaw(minetest.dir_to_yaw(direction))
    

    if vector.equals(pos, new_pos) then
        start_animation(pegasus.object, "stand")
    else
        start_animation(pegasus.object, "walk")
    end
end

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        if wand_users[name] and wand_users[name].pos1 and wand_users[name].pos2 then
            if player:get_player_control().sneak then
                local player_pos = player:get_pos()
                local parade_action_taken = false
                for _, obj in ipairs(minetest.get_objects_inside_radius(player_pos, 15)) do
                    local ent = obj:get_luaentity()
                    if ent and ent.name == "pegasus:pegasus" then
                        if parading_pegasi[ent] then
                            if stop_pegasus_parade(ent) then
                                minetest.chat_send_player(name, S("Pegasus parade stopped"))
                                parade_action_taken = true
                            end
                        else
                            start_pegasus_parade(ent, wand_users[name].pos1, wand_users[name].pos2)
                            minetest.chat_send_player(name, S("Pegasus parade started"))
                            parade_action_taken = true
                        end
                        break
                    end
                end
                if parade_action_taken then
                    wand_users[name] = nil
                end
            end
        end
    end

    for pegasus, parade_info in pairs(parading_pegasi) do
        if not pegasus.object:get_pos() then
            parading_pegasi[pegasus] = nil
        else
            move_pegasus(pegasus, parade_info, dtime)
        end
    end
end)


-- Команда чата для остановки парада
minetest.register_chatcommand("stop_parade", {
    description = S("Stops the parade of the nearest Pegasus"),
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, S("Player not found") end

        local player_pos = player:get_pos()
        for pegasus, _ in pairs(parading_pegasi) do
            if vector.distance(player_pos, pegasus.object:get_pos()) < 15 then
                stop_pegasus_parade(pegasus)
                return true, S("Pegasus parade stopped")
            end
        end
        return false, S("No parading Pegasi found nearby")
    end
})

minetest.register_craftitem("pegasus:saddle", {
	description = S("Saddle"),
	inventory_image = "pegasus_saddle.png",
})

minetest.register_craftitem("pegasus:net", {
	description = S("Pegasus Net"),
	inventory_image = "pegasus_net.png",
	stack_max = 1,
	on_secondary_use = mob_storage_use,
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		if pos then
			local under = minetest.get_node(pointed_thing.under)
			local node = minetest.registered_nodes[under.name]
			if node and node.on_rightclick then
				return node.on_rightclick(pointed_thing.under, under, placer,
										  itemstack)
			end
			if pos and not minetest.is_protected(pos, placer:get_player_name()) then
				local mob = itemstack:get_meta():get_string("mob")
				local staticdata = itemstack:get_meta():get_string("staticdata")
				if mob ~= "" then
					pos.y = pos.y +
								math.abs(
									minetest.registered_entities[mob]
										.collisionbox[2])
					minetest.add_entity(pos, mob, staticdata)
					itemstack:get_meta():set_string("mob", nil)
					itemstack:get_meta():set_string("staticdata", nil)
					itemstack:get_meta():set_string("description", S("Pegasus Net"))
				end
			end
		end
		return itemstack
	end
})

-----------
-- Armor --
-----------

if minetest.get_modpath("3d_armor") then

	if armor
	and armor.attributes then
		table.insert(armor.attributes, "heavy_pelt")

		minetest.register_on_punchplayer(function(player, hitter, _, _, _, damage)
			local name = player:get_player_name()
			if name
			and (armor.def[name].heavy_pelt or 0) > 0 then
				local hit_ip = hitter:is_player()
				if hit_ip and minetest.is_protected(player:get_pos(), "") then
					return
				else
					local player_pos = player:get_pos()
					if not player_pos then return end
	
					local biome_data = minetest.get_biome_data(player_pos)
	
					if biome_data.heat < 50 then
						player:set_hp(player:get_hp() - (damage / 1.5))
						return true
					end
				end
			end
		end)
	end


-----------
-- Nodes --
-----------

minetest.register_node("pegasus:crate", {
	description = S("Pegasus Crate"),
	tiles = {"pegasus_crate.png", "pegasus_crate.png", "pegasus_crate_side.png"},
	groups = {choppy = 2},
	stack_max = 1,
	on_secondary_use = mob_storage_use,
	preserve_metadata = function(_, _, oldmeta, drops)
		for _, stack in pairs(drops) do
			if stack:get_name() == "pegasus:crate" then
				local meta = stack:get_meta()
				meta:set_string("mob", oldmeta["mob"])
				meta:set_string("staticdata", oldmeta["staticdata"])
				meta:set_string("description", oldmeta["description"])
			end
		end
	end,
	after_place_node = function(pos, placer, itemstack)
		local meta = itemstack:get_meta()
		local mob = meta:get_string("mob")
		if mob ~= "" then
			local nmeta = minetest.get_meta(pos)
			nmeta:set_string("mob", mob)
			nmeta:set_string("infotext", S("Contains a Pegasus"))
			nmeta:set_string("staticdata", meta:get_string("staticdata"))
			nmeta:set_string("description", meta:get_string("description"))
			itemstack:take_item()
			placer:set_wielded_item(itemstack)
		end
	end,
	on_rightclick = function(pos, _, clicker)
		if minetest.is_protected(pos, clicker:get_player_name()) then
			return
		end
		local meta = minetest.get_meta(pos)
		local mob = meta:get_string("mob")
		local staticdata = meta:get_string("staticdata")
		if mob ~= "" then
			local above = {
				x = pos.x,
				y = pos.y + 1,
				z = pos.z
			}
			if creatura.get_node_def(above).walkable then
				return
			end
			minetest.add_entity(above, mob, staticdata)
			meta:set_string("mob", nil)
			meta:set_string("infotext", nil)
			meta:set_string("staticdata", nil)
			meta:set_string("description", S("Pegasus Crate"))
		end
	end
})

--------------
-- Crafting --
--------------

local steel_ingot = "default:steel_ingot"

minetest.register_on_mods_loaded(function()
	if minetest.registered_items[steel_ingot] then return end
	for name, _ in pairs(minetest.registered_items) do
		if name:find("ingot")
		and (name:find("steel")
		or name:find("iron")) then
			steel_ingot = name
			break
		end
	end
end)


minetest.register_craft({
	output = "pegasus:lasso",
	recipe = {
		{"", "group:thread", "group:thread"},
		{"", "group:leather", "group:thread"},
		{"group:thread", "", ""}
	}
})

minetest.register_craft({
	output = "pegasus:lasso",
	recipe = {
		{"", "farming:string", "farming:string"},
		{"", "group:leather", "farming:string"},
		{"farming:string", "", ""}
	}
})

minetest.register_craft({
	output = "pegasus:net",
	recipe = {
		{"group:thread", "", "group:thread"},
		{"group:thread", "", "group:thread"},
		{"group:stick", "group:thread", ""}
	}
})

minetest.register_craft({
	output = "pegasus:net",
	recipe = {
		{"farming:string", "", "farming:string"},
		{"farming:string", "", "farming:string"},
		{"group:stick", "farming:string", ""}
	}
})

minetest.register_craft({
	output = "pegasus:crate",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "pegasus:net", "group:wood"},
		{"group:wood", "group:wood", "group:wood"}
	}
})

minetest.register_craft({
	output = "pegasus:saddle",
	recipe = {
		{"group:leather", "group:leather", "group:leather"},
		{"group:leather", steel_ingot, "group:leather"},
		{"group:thread", "", "group:thread"}
	}
})



minetest.register_craft({
	output = "pegasus:book_pegasus",
	recipe = {
		{"pegasus:leather", "default:paper", "pegasus:leather"},
		{"pegasus:leather", "default:paper", "pegasus:leather"},
		{"pegasus:leather", "default:paper", "pegasus:leather"}
	}
})


minetest.register_on_craft(function(itemstack, _, old_craft_grid)
	if itemstack:get_name() == "pegasus:book_pegasus"
	and itemstack:get_count() > 1 then
		for _, old_book in pairs(old_craft_grid) do
			if old_book:get_meta():get_string("chapters") then
				local chapters = old_book:get_meta():get_string("chapters")
				itemstack:get_meta():set_string("chapters", chapters)
				return itemstack
			end
		end
	end
end)
end

-- Функция для поиска ближайшего Пегаса
function pegasus.find_nearest_pegasus(player)
    local player_pos = player:get_pos()
    local nearest_pegasus = nil
    local min_distance = math.huge

    for _, obj in pairs(minetest.luaentities) do
        if obj.name == "pegasus:pegasus" then
            local distance = vector.distance(player_pos, obj.object:get_pos())
            if distance < min_distance then
                min_distance = distance
                nearest_pegasus = obj
            end
        end
    end

    return nearest_pegasus
end

-- Улучшенная функция "Небесный вихрь"
local function smooth_sky_whirl(self)
    local start_pos = self.object:get_pos()
    local radius = 5
    local height = 10
    local duration = 5  -- секунды
    local steps = 150   -- увеличенное количество шагов для большей плавности
    local current_step = 0


    local function move_step()
        current_step = current_step + 1
        if current_step <= steps then
            local progress = current_step / steps
            local angle = progress * math.pi * 4  -- Два полных оборота
            local vertical_progress = math.sin(progress * math.pi)  -- Плавный подъем и спуск
            
            local new_pos = {
                x = start_pos.x + radius * math.cos(angle),
                y = start_pos.y + height * vertical_progress,
                z = start_pos.z + radius * math.sin(angle)
            }
            
            self.object:move_to(new_pos)
            
            -- Эффект притяжения для ближайших объектов
            for _, obj in pairs(minetest.get_objects_inside_radius(new_pos, radius * 2)) do
                if obj ~= self.object and obj:get_luaentity() and obj:get_luaentity().name ~= "pegasus:pegasus" then
                    local entity_pos = obj:get_pos()
                    local dir = vector.direction(entity_pos, new_pos)
                    obj:add_velocity(vector.multiply(dir, 0.2))  -- Уменьшенная сила притяжения
                end
            end
            
            minetest.after(duration / steps, move_step)
        end
    end

    move_step()
end

-- Добавляем случайную активацию способности в шаг Пегаса
local old_pegasus_step = pegasus.step_func
pegasus.step_func = function(self, dtime)
    if old_pegasus_step then
        old_pegasus_step(self, dtime)
    end

    -- Шанс активации "Небесного вихря" примерно раз в 5 минут
    if math.random(1, 18000) == 1 then  -- при 60 FPS
        smooth_sky_whirl(self)
    end
end

-- Функция для поиска ближайшего Пегаса
function pegasus.find_nearest_pegasus(player)
    local player_pos = player:get_pos()
    local nearest_pegasus = nil
    local min_distance = math.huge

    for _, obj in pairs(minetest.luaentities) do
        if obj.name == "pegasus:pegasus" then
            local distance = vector.distance(player_pos, obj.object:get_pos())
            if distance < min_distance then
                min_distance = distance
                nearest_pegasus = obj
            end
        end
    end

    return nearest_pegasus
end

-- Функция "Звездный след"
local function star_trail(self)
    local duration = 10  -- секунды
    local interval = 0.5 -- интервал между звездами
    local star_lifetime = 5 -- время жизни каждой звезды


    local function place_star()
        local pos = self.object:get_pos()
        if pos then
            -- Создаем временную звезду
            local star_pos = {x = pos.x, y = pos.y - 0.5, z = pos.z}
            minetest.set_node(star_pos, {name = "pegasus:star_node"})
            
            -- Удаляем звезду через некоторое время
            minetest.after(star_lifetime, function()
                minetest.remove_node(star_pos)
            end)
        end
    end

    -- Запускаем создание звезд
    local star_timer = 0
    minetest.register_globalstep(function(dtime)
        star_timer = star_timer + dtime
        if star_timer > duration then
            return true -- Останавливаем глобальный шаг
        end
        
        if star_timer % interval < dtime then
            place_star()
        end
    end)
end

-- Регистрируем новый узел для звезды
minetest.register_node("pegasus:star_node", {
    description = "Star",
    tiles = {"pegasus_star.png"},
    light_source = 14,
    walkable = false,
    buildable_to = true,
    sunlight_propagates = true,
    groups = {cracky = 3, not_in_creative_inventory = 1},
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(5)
    end,
    on_timer = function(pos, elapsed)
        minetest.remove_node(pos)
        return false
    end,
})

-- Добавляем случайную активацию способности в шаг Пегаса
local old_pegasus_step = pegasus.step_func
pegasus.step_func = function(self, dtime)
    if old_pegasus_step then
        old_pegasus_step(self, dtime)
    end

    -- Шанс активации "Звездного следа" примерно раз в 5 минут
    if math.random(1, 18000) == 1 then  -- при 60 FPS
        star_trail(self)
    end
end

