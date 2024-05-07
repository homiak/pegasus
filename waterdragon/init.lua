--------------
-- waterdragon --
--------------

waterdragon = {
	force_storage_save = false
}

local path = minetest.get_modpath("waterdragon")

-- Global Tables --

local storage = dofile(path.."/storage.lua")

waterdragon.dragons = storage.dragons
waterdragon.bonded_dragons = storage.bonded_dragons
waterdragon.aux_key_setting = storage.aux_key_setting
waterdragon.attack_blacklist = storage.attack_blacklist
waterdragon.libri_font_size = storage.libri_font_size

waterdragon.sounds = {
    wood = {},
    stone = {},
    dirt = {}
}

if minetest.get_modpath("default") then
    if default.node_sound_wood_defaults then
        waterdragon.sounds.wood = default.node_sound_wood_defaults()
    end
    if default.node_sound_stone_defaults then
        waterdragon.sounds.stone = default.node_sound_stone_defaults()
    end
    if default.node_sound_dirt_defaults then
        waterdragon.sounds.dirt = default.node_sound_dirt_defaults()
    end
end

waterdragon.colors_pure_water = {
    ["pure_water"] = "393939",
}

waterdragon.colors_rare_water = {
    ["rare_water"] = "9df8ff"
}

waterdragon.global_nodes = {}

waterdragon.global_nodes["flame"] = "default:water_flowing"
waterdragon.global_nodes["rare_water"] = "default:water_flowing"
waterdragon.global_nodes["steel_blockj"] = "default:water_source"

minetest.register_on_mods_loaded(function()
    for name, def in pairs(minetest.registered_nodes) do
        -- Flame
        if not (waterdragon.global_nodes["flame"]
        or not minetest.registered_nodes[waterdragon.global_nodes["flame"]])
        and (name:find("flame") or name:find("pure_water"))
        and def.drawtype == "firelike" then
            waterdragon.global_nodes["flame"] = name
        end
        -- rare_water
        if not (waterdragon.global_nodes["rare_water"]
        or not minetest.registered_nodes[waterdragon.global_nodes["rare_water"]])
        and name:find(":rare_water")
        and minetest.get_item_group(name, "slippery") > 0 then
            waterdragon.global_nodes["rare_water"] = name
        end
        -- Steel Block
        if not (waterdragon.global_nodes["steel_blockj"]
        or not minetest.registered_nodes[waterdragon.global_nodes["steel_blockj"]])
        and (name:find(":steel")
        or name:find(":iron"))
        and name:find("block") then
            waterdragon.global_nodes["steel_blockj"] = name
        end
    end
end)

local clear_objects = minetest.clear_objects

function minetest.clear_objects(options)
    clear_objects(options)
    for id, dragon in pairs(waterdragon.dragons) do
        if not dragon.stored_in_item then
            waterdragon.dragons[id] = nil
            if waterdragon.bonded_dragons[id] then
                waterdragon.bonded_dragons[id] = nil
            end
        end
    end
end

-- Load Files --

dofile(path.."/api/api.lua")
dofile(path.."/api/mount.lua")
dofile(path.."/api/behaviors.lua")
dofile(path.."/mobs/rare_water_dragon.lua")
dofile(path.."/mobs/pure_water_dragon.lua")
dofile(path.."/nodes.lua")
dofile(path.."/craftitems.lua")
dofile(path.."/api/libri.lua")

if minetest.get_modpath("3d_armor") then
    dofile(path.."/armor.lua")
end

-- Spawning --

waterdragon.cold_biomes = {}
waterdragon.warm_biomes = {}

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_biomes) do
        local biome = minetest.registered_biomes[name]
		local heat = biome.heat_point or 0
		if heat < 40 then
            table.insert(waterdragon.cold_biomes, name)
        else
            table.insert(waterdragon.warm_biomes, name)
        end
	end
end)

dofile(path.."/mapgen.lua")

local simple_spawning = minetest.settings:get_bool("simple_spawning") or false

local spawn_rate = tonumber(minetest.settings:get("simple_spawn_rate")) or 80000

if simple_spawning then
    creatura.register_mob_spawn("waterdragon:rare_water_dragon", {
        chance = spawn_rate,
        min_group = 1,
        max_group = 1,
        biomes = waterdragon.cold_biomes,
        nodes = {"air"}
    })
    creatura.register_mob_spawn("waterdragon:pure_water_dragon", {
        chance = spawn_rate,
        min_group = 1,
        max_group = 1,
        biomes = waterdragon.warm_biomes,
        nodes = {"air"}
    })
end

-- Aliases --

minetest.register_alias("waterdragon:dracolily_pure_water", "air")
minetest.register_alias("waterdragon:dracolily_rare_water", "air")

minetest.register_alias("waterdragon:blood_pure_water_dragon", "")
minetest.register_alias("waterdragon:blood_rare_water_dragon", "")

minetest.register_alias("waterdragon:manuscript", "")

for color in pairs(waterdragon.colors_rare_water) do
    minetest.register_alias("waterdragon:egg_rare_water_dragon", "waterdragon:egg_rare_water")
end

for color in pairs(waterdragon.colors_pure_water) do
    minetest.register_alias("waterdragon:egg_pure_water_dragon", "waterdragon:egg_pure_water")
end

minetest.register_entity("waterdragon:rare_water_eyes", {
    on_activate = function(self)
        self.object:remove()
    end
})

minetest.register_entity("waterdragon:pure_water_eyes", {
    on_activate = function(self)
        self.object:remove()
    end
})

minetest.register_node("waterdragon:spawn_node", {
    drawtype = "airlike"
})

minetest.register_abm({
    label = "Fix Spawn Nodes",
    nodenames = {"waterdragon:spawn_node"},
    interval = 10,
    chance = 1,
    action = function(pos)
        local meta = minetest.get_meta(pos)
        local mob = meta:get_string("name")
        minetest.set_node(pos, {name = "creatura:spawn_node"})
        if mob ~= "" then
            meta:set_string("mob", mob)
        end
    end,
})

minetest.log("action", "[MOD] waterdragon [2.0] loaded")
