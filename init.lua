pegasus = {}

pegasus.S = nil

if(minetest.get_translator ~= nil) then
    pegasus.S = minetest.get_translator(minetest.get_current_modname())
else
	pegasus.S = function ( s ) return s end
end



local path = minetest.get_modpath("pegasus")
local storage = dofile(path .. "/api/storage.lua")

pegasus.spawn_points = storage.spawn_points
pegasus.book_font_size = storage.book_font_size

pegasus.pets = {}

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	pegasus.pets[name] = {}
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	pegasus.pets[name] = nil
end)

-- Daytime Tracking

pegasus.is_day = true

local function is_day()
	local time = (minetest.get_timeofday() or 0) * 24000
	pegasus.is_day = time < 19500 and time > 4500
	minetest.after(10, is_day)
end

is_day()

-- Player Effects

pegasus.player_effects = {}

local function player_effect_step()
	for player, data in pairs(pegasus.player_effects) do
		if player then
			local timer = data.timer - 1
			pegasus.player_effects[player].timer = timer
			local func = data.func
			func(minetest.get_player_by_name(player))
			if timer <= 0 then
				pegasus.player_effects[player] = nil
			end
		end
	end
	minetest.after(1, player_effect_step)
end

player_effect_step()

function pegasus.set_player_effect(player_name, effect, timer)
	pegasus.player_effects[player_name] = {
		func = effect,
		timer = timer or 5
	}
end

-- Create lists of items for reuse

pegasus.food_wheat = {}
pegasus.food_seeds = {}
pegasus.food_crops = {}

minetest.register_on_mods_loaded(function()
	if minetest.get_modpath("farming")
	and farming.registered_plants then
		for _, def in pairs(farming.registered_plants) do
			if def.crop then
				table.insert(pegasus.food_crops, def.crop)
			end
		end
	end
	for name in pairs(minetest.registered_items) do
		if (name:match(":wheat")
		or minetest.get_item_group(name, "food_wheat") > 0)
		and not name:find("seed") then
			table.insert(pegasus.food_wheat, name)
		end
		if name:match(":seed_")
		or name:match("_seed") then
			table.insert(pegasus.food_seeds, name)
		end
	end
end)

-- Load Files

local function load_file(filepath, filename)
    if io.open(filepath .. "/" .. filename, "r") then
        dofile(filepath .. "/" .. filename)
    end
end

dofile(path.."/library/mob_meta.lua")
dofile(path.."/library/api.lua") 
dofile(path.."/library/methods.lua")

dofile(path.."/library/pathfinding.lua")
dofile(path.."/library/boids.lua")
dofile(path.."/library/spawning.lua")

dofile(path.."/api/api.lua")
dofile(path.."/api/mob_ai.lua")
dofile(path.."/api/lasso.lua")
dofile(path.."/craftitems.lua")

pegasus.animals = {
	"pegasus:pegasus",
}

dofile(path.."/api/api.lua")

load_file(path .. "/mobs", "pegasus.lua")

if minetest.settings:get_bool("spawn_mobs", true) then
	dofile(path.."/api/spawning.lua")
end

dofile(path.."/api/book.lua")

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_entities) do
		if def.logic
		or def.brainfunc
		or def.bh_tree
		or def._cmi_is_mob then
			local old_punch = def.on_punch
			if not old_punch then
				old_punch = function() end
			end
			local on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
				old_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
				local pos = self.object:get_pos()
				if not pos then return end
				local plyr_name = puncher:is_player() and puncher:get_player_name()
				local pets = (plyr_name and pegasus.pets[plyr_name]) or {}
				for _, obj in ipairs(pets) do
					local ent = obj and obj:get_luaentity()
					if ent
					and ent.assist_owner then
						ent.owner_target = self
					end
				end
			end
			def.on_punch = on_punch
			minetest.register_entity(":" .. name, def)
		end
	end
end)



