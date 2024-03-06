minetest.register_craft({
	type = "shapeless",
	output = "colorflames:orange_fire_starter_tool",
	recipe = { "fire:flint_and_steel", "dye:orange_dye" }
})

minetest.register_craftitem("colorflames:orange_fire_starter_tool", {
    description = "Orange fire starter tool",
    inventory_image = "orange_fire_starter_tool.png"
})