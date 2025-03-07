--------------
-- Spawning --
--------------

local random = math.random

local function table_contains(tbl, val)
	for _, v in pairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

local common_spawn_chance = tonumber(minetest.settings:get("pegasus_common_chance")) or 60000

local ambient_spawn_chance = tonumber(minetest.settings:get("pegasus_ambient_chance")) or 9000

local pest_spawn_chance = tonumber(minetest.settings:get("pegasus_pest_chance")) or 3000

local predator_spawn_chance = tonumber(minetest.settings:get("pegasus_predator_chance")) or 45000

-- Get Biomes --

pegasus.register_abm_spawn("pegasus:pegasus", {
	chance = common_spawn_chance,
	spawn_active = true,
	min_height = 0,
	max_height = 1024,
	min_group = 3,
	max_group = 4,
	spawn_cap = 3,
	biomes = pegasus.registered_biome_groups["grassland"].biomes,
	nodes = {"group:soil"},
	neighbors = {"air", "group:grass", "group:flora"}
})


-- World Gen Spawning

minetest.register_node("pegasus:spawner", {
	description = "???",
	drawtype = "airlike",
	walkable = false,
	pointable = false,
	sunlight_propagates = true,
	groups = {oddly_breakable_by_hand = 1, not_in_creative_inventory = 1}
})

minetest.register_decoration({
	name = "pegasus:world_gen_spawning",
	deco_type = "simple",
	place_on = {"group:stone", "group:sand", "group:soil"},
	sidelen = 1,
	fill_ratio = 0.0001, -- One node per chunk
	decoration = "pegasus:spawner"
})

local function do_on_spawn(pos, obj)
	local name = obj and obj:get_luaentity().name
	if not name then return end
	local spawn_functions = pegasus.registered_on_spawns[name] or {}

	if #spawn_functions > 0 then
		for _, func in ipairs(spawn_functions) do
			func(obj:get_luaentity(), pos)
			if not obj:get_yaw() then break end
		end
	end
end

minetest.register_abm({
	label = "[pegasus] World Gen Spawning",
	nodenames = {"pegasus:spawner"},
	interval = 10, -- TODO: Set this to 1 if world is singleplayer and just started
	chance = 16,

	action = function(pos, _, active_object_count)
		minetest.remove_node(pos)

		if active_object_count > 4 then return end

		local spawnable_mobs = {}

		local current_biome = minetest.get_biome_name(minetest.get_biome_data(pos).biome)

		local spawn_definitions = pegasus.registered_mob_spawns

		for mob, def in pairs(spawn_definitions) do
			if mob:match("^pegasus:")
			and def.biomes
			and table_contains(def.biomes, current_biome) then
				table.insert(spawnable_mobs, mob)
			end
		end

		if #spawnable_mobs > 0 then
			local mob_to_spawn = spawnable_mobs[math.random(#spawnable_mobs)]
			local spawn_definition = pegasus.registered_mob_spawns[mob_to_spawn]

			local group_size = random(spawn_definition.min_group or 1, spawn_definition.max_group or 1)
			local obj

			if group_size > 1 then
				local offset
				local spawn_pos
				for _ = 1, group_size do
					offset = group_size * 0.5
					spawn_pos = pegasus.get_ground_level({
						x = pos.x + random(-offset, offset),
						y = pos.y,
						z = pos.z + random(-offset, offset)
					}, 3)

					if not pegasus.is_pos_moveable(spawn_pos, 0.5, 0.5) then
						spawn_pos = pos
					end

					obj = minetest.add_entity(spawn_pos, mob_to_spawn)
					do_on_spawn(spawn_pos, obj)
				end
			else
				obj = minetest.add_entity(pos, mob_to_spawn)
				do_on_spawn(pos, obj)
			end
		end
	end
})
