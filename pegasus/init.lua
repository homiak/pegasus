pegasus = {}

local path = minetest.get_modpath("pegasus")

local storage = dofile(path .. "/api/storage.lua")

pegasus.spawn_points = storage.spawn_points
pegasus.libri_font_size = storage.libri_font_size

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
pegasus.food_bear = {}

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
		if (minetest.get_item_group(name, "food_berry") > 0
		and not name:find("seed"))
		or minetest.get_item_group(name, "food_fish") > 0 then
			table.insert(pegasus.food_bear, name)
		end
	end
end)

-- Load Files

local function load_file(filepath, filename)
    if io.open(filepath .. "/" .. filename, "r") then
        dofile(filepath .. "/" .. filename)
    else
        minetest.log("action", "[Creatura] The file " .. filename .. " could not be loaded.")
    end
end

dofile(path.."/api/api.lua")
dofile(path.."/api/mob_ai.lua")
dofile(path.."/api/lasso.lua")
dofile(path.."/craftitems.lua")

pegasus.animals = {
	"pegasus:bat",
	"pegasus:song_bird",
	"pegasus:cat",
	"pegasus:chicken",
	"pegasus:cow",
	"pegasus:fox",
	"pegasus:grizzly_bear",
	"pegasus:horse",
	"pegasus:opossum",
	"pegasus:owl",
	"pegasus:pig",
	"pegasus:rat",
	"pegasus:reindeer",
	"pegasus:sheep",
	"pegasus:turkey",
	"pegasus:tropical_fish",
	"pegasus:wolf",
}

dofile(path.."/api/api.lua")

load_file(path .. "/mobs", "bat.lua")
load_file(path .. "/mobs", "bear.lua")
load_file(path .. "/mobs", "cat.lua")
load_file(path .. "/mobs", "chicken.lua")
load_file(path .. "/mobs", "cow.lua")
load_file(path .. "/mobs", "fox.lua")
load_file(path .. "/mobs", "horse.lua")
load_file(path .. "/mobs", "opossum.lua")
load_file(path .. "/mobs", "owl.lua")
load_file(path .. "/mobs", "pig.lua")
load_file(path .. "/mobs", "rat.lua")
load_file(path .. "/mobs", "reindeer.lua")
load_file(path .. "/mobs", "sheep.lua")
load_file(path .. "/mobs", "song_bird.lua")
load_file(path .. "/mobs", "turkey.lua")
load_file(path .. "/mobs", "tropical_fish.lua")
load_file(path .. "/mobs", "wolf.lua")

if minetest.settings:get_bool("spawn_mobs", true) then
	dofile(path.."/api/spawning.lua")
end

dofile(path.."/api/libri.lua")

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

local convert_mobs_redo = minetest.settings:get_bool("convert_redo_items", false)

if convert_mobs_redo then
	minetest.register_alias_force("mobs:leather", "pegasus:leather")
	minetest.register_alias_force("mobs:meat_raw", "pegasus:beef_raw")
	minetest.register_alias_force("mobs:meat", "pegasus:beef_cooked")
	minetest.register_alias_force("mobs:lasso", "pegasus:lasso")
	minetest.register_alias_force("mobs:net", "pegasus:net")
	minetest.register_alias_force("mobs:shears", "pegasus:shears")
	minetest.register_alias_force("mobs:saddles", "pegasus:saddles")
	minetest.register_alias_force("mobs:nametag", "pegasus:nametag")
end

minetest.log("action", "[MOD] pegasus [0.6] loaded")
