local modpath = minetest.get_modpath("stoneblocks")

minetest.register_node("stoneblocks:turquoise_dark_glass_block", {
    description = "Unlit turquoise glass block",
    tiles = {"turquoise_dark_glass_block.png"},
    groups = {cracky = 1, oddly_breakable_by_hand = 3},
    sounds = default.node_sound_stone_defaults(),

    -- When the player walks over it, change to the lit version
    on_construct = function(pos)
        local timer = minetest.get_node_timer(pos)
        timer:start(1) -- check every second
    end,
    on_timer = function(pos)
        local objs = minetest.get_objects_inside_radius(pos, 1) -- 1 is the radius to check for players
        for _, obj in ipairs(objs) do
            if obj:is_player() then
                minetest.swap_node(pos, {name = "stoneblocks:turquoise_lit_glass_block"})
                -- Start a timer to switch back after X seconds
                local timer = minetest.get_node_timer(pos)
                timer:start(3) -- number of seconds the block to stay lit
				minetest.log("action", "Lit Light Block constructed at " .. minetest.pos_to_string(pos))
                return false -- Stop checking once switched to lit
            end
        end
        return true -- Continue checking if not switched to lit
    end,
})

minetest.register_node("stoneblocks:turquoise_lit_glass_block", {
    description = "Lit turquoise glass block",
    tiles = {"turquoise_lit_glass_block.png"},
    light_source = 14, -- Max light
    groups = {cracky = 1, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1},
    sounds = default.node_sound_stone_defaults(),
    drop = "stoneblocks:turquoise_dark_glass_block", -- Ensure it drops the unlit version

    -- Timer to revert back to unlit after X seconds
    on_timer = function(pos)
        minetest.swap_node(pos, {name = "stoneblocks:turquoise_dark_glass_block"})
    end,

    -- TODO this is not called on swap leading to block changing once only When constructed (or swapped from unlit), start the timer
    on_construct = function(pos)
        local timer = minetest.get_node_timer(pos)
		minetest.log("action", "Unlit Light Block set at " .. minetest.pos_to_string(pos))
		timer:start(3) -- number of seconds the block stays lit
    end,
})
