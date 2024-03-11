
local function smoke(pos, node, clicker, enable)
	local meta = minetest.get_meta(pos)
	local handler = meta:get_int("sound")
	local particle = meta:get_int("smoke")

	if particle ~= 0 or enable ~= true then
		if handler then
			minetest.sound_stop(handler)
		end
		minetest.delete_particlespawner(particle)
		meta:set_int("smoke", 0)
		meta:set_int("sound", 0)
		return
	end

	if minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z}).name ~= "air" or particle ~= 0 then
		return
	end

	particle = minetest.add_particlespawner({
		amount = 4,
		time = 0,
		collisiondetection = true,
		minpos = {x = pos.x - 0.25, y = pos.y + 0.4, z = pos.z-0.25},
		maxpos = {x = pos.x + 0.25, y = pos.y + 5, z = pos.z + 0.25},
		minvel = {x = -0.2, y = 0.3, z = -0.2},
		maxvel = {x = 0.2, y = 1, z = 0.2},
		minacc = {x = 0, y = 0, z = 0},
		maxacc = {x = 0, y = 0.5, z = 0},
		minexptime = 1,
		maxexptime = 3,
		minsize = 4,
		maxsize = 8,
		texture = "smoke_particle.png",
	})

	handler = minetest.sound_play("fire_small", {
		pos = pos,
		max_hear_distance = 20,
		loop = true
	})

	meta:set_int("smoke", particle)
	meta:set_int("sound", handler)
end


-- flame types
local flame_types = {
	"green", "yellow", "black", "orange", "cyan", "violet", "blue", "red", "magenta", "grey", "healinggreen", "healingcyan", "healingblack"
}

for _, f in pairs(flame_types) do
	minetest.register_node("colorflames:" .. f .. "_fire", {
		inventory_image = f .. "_fire_inv.png",
		wield_image = f .. "_fire_inv.png",
		description = f .. " Fire",
		drawtype = "firelike",
		paramtype = "light",
		groups = {dig_immediate = 3, not_in_creative_inventory = 0, colorflames_fire = 1},
		sunlight_propagates = true,
		buildable_to = true,
		walkable = false,
		light_source = 14,
		waving = 1,
		drop = "",
		tiles = {{
			name = f .. "_fire_animated_orig.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1.5
			},
		}},

		on_rightclick = function (pos, node, clicker)
			smoke(pos, node, clicker, true)
		end,

		on_destruct = function (pos)
			smoke(pos, nil, nil, false)
			minetest.sound_play("fire_extinguish_flame", {
				pos = pos,
				max_hear_distance = 20,
				gain = 0.25
			})
		end,
	})
end

if minetest.features.particlespawner_tweenable then
	minetest.register_abm({
		nodenames = { "group:colorflames_fire" },
		interval = 1,
		chance = 1,
		catch_up = false,
		action = function(pos, node)
			local color = node.name:split(":")[2]:split("_")[1]
			if color=="frosted" then
				color = "white"
			end
			minetest.add_particlespawner({
				pos = { min = vector.add(pos, vector.new(-0.5, -0.5, -0.5)), max = vector.add(pos, vector.new(0.5, 0.5, 0.5)) },
				vel = { min = vector.new(-0.5, 0.5, -0.5), max = vector.new( 0.5, 0.5, 0.5) },
				acc = vector.new(0, 0.1, 0),
				time = 1,
				amount = 100,
				exptime = 1,
				collisiondetection = true,
				collision_removal = true,
				glow = 14,
				texpool = {
					{ name = "flame_spark.png^[multiply:"..color, alpha_tween = { 1, 0 },	scale_tween = { 0.5, 0 }, blend = "screen" },
					{ name = "flame_spark.png^[multiply:#c00", alpha_tween = { 1, 0 },	scale_tween = { 0.5, 0 }, blend = "screen" },
					{ name = "flame_spark.png^[multiply:#800", alpha_tween = { 1, 0 },	scale_tween = { 0.5, 0 }, blend = "screen" },
					{ name = "flame_spark.png^[multiply:#ff0", alpha_tween = { 1, 0 },	scale_tween = { 0.5, 0 }, blend = "screen" },
					{ name = "flame_spark.png^[multiply:#fc0", alpha_tween = { 1, 0 },	scale_tween = { 0.5, 0 }, blend = "screen" },
					{ name = "flame_spark.png^[multiply:#cc0", alpha_tween = { 1, 0 },	scale_tween = { 0.5, 0 }, blend = "screen" },
					{ name = "flame_spark.png^[multiply:#f80", alpha_tween = { 1, 0 },	scale_tween = { 0.5, 0 }, blend = "screen" },
				}
			})
		end
	})
end

