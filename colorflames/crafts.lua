local flint_colors = {"green", "yellow", "black", "orange", "cyan", "blue", "red", "violet", "grey"}

local function register_flint_craft(color)
    minetest.register_craft({
        type = "shapeless",
        output = "colorflames:" .. color .. "_fire_starter_tool",
        recipe = {"fire:flint_and_steel", "dye:" .. color}
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
                    minetest.set_node(pos, {
                        name = "colorflames:" .. color .. "_fire"
                    })
                end
                -- Optionally, reduce the item's wear or remove one item from the stack
                -- itemstack:take_item()
                return itemstack
            end
        end
    })
end

for _, color in pairs(flint_colors) do
    register_flint_craft(color)
end

local function register_healing_flint_craft(color)
    minetest.register_craft({
        type = "shapeless",
        output = "colorflames:healing" .. color .. "_fire_starter_tool",
        recipe = {"fire:flint_and_steel", "dye:" .. color, "ethereal:yellow_tree_sapling"}
    })

    minetest.register_craftitem("colorflames:healing" .. color .. "_fire_starter_tool", {
        description = "Healing  " .. color .. " fire starter tool", -- capital
        inventory_image = "healing" .. color .. "_fire_starter_tool.png",
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
                    minetest.set_node(pos, {
                        name = "colorflames:healing" .. color .. "_fire"
                    })
                end
                -- Optionally, reduce the item's wear or remove one item from the stack
                -- itemstack:take_item()
                return itemstack
            end
        end
    })

    minetest.register_abm({
        label = "Heal players near healing fire",
        nodenames = {"colorflames:healing" .. color .. "_fire"},
        interval = 1,  -- Check every second
        chance = 1,
        action = function(pos, node, active_object_count, active_object_count_wider)
            local objects = minetest.get_objects_inside_radius(pos, 2)  -- Adjust the radius as needed
            for _, obj in ipairs(objects) do
                if obj:is_player() then
                    local hp = obj:get_hp()
                    if hp > 0 and hp < 20 then  -- Assuming max HP is 20
                        obj:set_hp(hp + 5)  -- Heal by 1 HP; adjust as needed
                    end
                end
            end
        end,
    })
end

local flint_colors = {"green", "black", "cyan"}

for _, color in pairs(flint_colors) do
    register_healing_flint_craft(color)
end
