
local flint_colors = {
	"green", "yellow", "black", "orange", "cyan", "blue", "red"
}

local function register_flint_craft(color) 
    minetest.register_craft({
        type = "shapeless",
        output = "colorflames:".. color .. "_fire_starter_tool",
        recipe = { "fire:flint_and_steel", "dye:" .. color }    
    })

    minetest.register_craftitem("colorflames:" .. color .. "_fire_starter_tool", {
        description = color .. " fire starter tool", -- capital
        inventory_image = color .. "_fire_starter_tool.png",
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
                    minetest.set_node(pos, { name = "colorflames:".. color .."_fire"})
                end    
                -- Optionally, reduce the item's wear or remove one item from the stack
                -- itemstack:take_item()
                return itemstack
            end
        end,
    })
end

for _, color in pairs(flint_colors) do
    register_flint_craft(color)
end
