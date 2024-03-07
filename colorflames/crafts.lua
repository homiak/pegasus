minetest.register_craft({
	type = "shapeless",
	output = "colorflames:orange_fire_starter_tool",
	recipe = { "fire:flint_and_steel", "dye:orange_dye" }

})

minetest.register_craftitem("colorflames:orange_fire_starter_tool", {
    description = "Orange fire starter tool",
    inventory_image = "orange_fire_starter_tool.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            -- Get the above node position
            local pos = minetest.get_pointed_thing_position(pointed_thing, above)
            local node = minetest.get_node(pos)
            pos.y = pos.y + 1 -- Adjust the position to be above the pointed node
            local above_node = minetest.get_node(pos)
            -- Check if the position above is air
            if above_node.name == "air" then
                -- Set fire to the node, replace "colorflames:yellow_fire" with the correct fire node name in your game
                minetest.set_node(pos, { name = "colorflames:orange_fire"})
            end    
            -- Optionally, reduce the item's wear or remove one item from the stack
            -- itemstack:take_item()
            return itemstack
        end
    end,
})

minetest.register_craftitem("colorflames:blue_fire_starter_tool", {
    description = "Blue fire starter tool",
    inventory_image = "blue_fire_starter_tool.png"
})

minetest.register_craftitem("colorflames:red_fire_starter_tool", {
    description = "Red fire starter tool",
    inventory_image = "red_fire_starter_tool.png"
})

minetest.register_craftitem("colorflames:rose_fire_starter_tool", {
    description = "Rose fire starter tool",
    inventory_image = "rose_fire_starter_tool.png"
})

minetest.register_craftitem("colorflames:black_fire_starter_tool", {
    description = "Black fire starter tool",
    inventory_image = "black_fire_starter_tool.png"
})

minetest.register_craftitem("colorflames:grey_fire_starter_tool", {
    description = "Grey fire starter tool",
    inventory_image = "grey_fire_starter_tool.png"
})

minetest.register_craftitem("colorflames:green_fire_starter_tool", {
    description = "Green fire starter tool",
    inventory_image = "green_fire_starter_tool.png"
})

minetest.register_craftitem("colorflames:cyan_fire_starter_tool", {
    description = "Cyan fire starter tool",
    inventory_image = "cyan_fire_starter_tool.png"
})

minetest.register_craftitem("colorflames:yellow_fire_starter_tool", {
    description = "Yellow fire starter tool",
    inventory_image = "yellow_fire_starter_tool.png"
})