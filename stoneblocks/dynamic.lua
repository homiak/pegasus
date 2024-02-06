local modpath = minetest.get_modpath("stoneblocks")
local sound_api = dofile(modpath .. "/sound_api_core/init.lua")

local stoneblocks_check_player_within = tonumber(minetest.settings:get('stoneblocks_check_player_within')) or 2
local stoneblocks_stay_lit_for = tonumber(minetest.settings:get('stoneblocks_stay_lit_for')) or 2

if stoneblocks_check_player_within < 1 or stoneblocks_check_player_within > 20 then
    minetest.log("INFO", "incorrect settings for stoneblocks_check_player_within using default")
    stoneblocks_check_player_within = 2
end
if stoneblocks_stay_lit_for < 1 or stoneblocks_stay_lit_for > 600 then
    minetest.log("INFO", "incorrect settings for stoneblocks_stay_lit_for using default")
    stoneblocks_stay_lit_for = 2
end

local function initialize_dark_block(pos)
    local timer = minetest.get_node_timer(pos)
    timer:start(0.5) -- check half second for players
    minetest.log("action", "Dark Glass Block initialized at " .. minetest.pos_to_string(pos))
end

-- Define your "unlit" block with the on_construct callback
minetest.register_node("stoneblocks:turquoise_dark_glass_block", {
    description = "Unlit turquoise glass block",
    tiles = {"turquoise_dark_glass_block.png"},
    groups = {stone = 1,  cracky = 2, dig_stoneblocks = 0},
    sounds = sound_api.node_sound_stone_defaults(),
    on_construct = initialize_dark_block,
    on_timer = function(pos)
        local objs = minetest.get_objects_inside_radius(pos, stoneblocks_check_player_within) -- is the radius to check for players
        for _, obj in ipairs(objs) do
            if obj:is_player() then
                minetest.swap_node(pos, {name = "stoneblocks:turquoise_lit_glass_block"})
                -- Start a timer to switch back after X seconds
                local timer = minetest.get_node_timer(pos)
                timer:start(stoneblocks_stay_lit_for) -- number of seconds the block to stay lit
				minetest.log("action", "Lit Light Block constructed at " .. minetest.pos_to_string(pos))
                return false -- Stop checking once switched to lit
            end
        end
        return true -- Continue checking if not switched to lit
    end,
})

-- Define your "lit" block
minetest.register_node("stoneblocks:turquoise_lit_glass_block", {
    description = "Lit turquoise glass block",
    tiles = {"turquoise_lit_glass_block.png"},
    light_source = 14, -- Max light
    groups = {stone = 1,  cracky = 2, dig_stoneblocks = 0, not_in_creative_inventory = 1},
    sounds = sound_api.node_sound_stone_defaults(),
    drop = "stoneblocks:turquoise_dark_glass_block", -- Ensure it drops the unlit version

-- When constructed or swapped from unlit, start the timer
on_construct = function(pos)
    local timer = minetest.get_node_timer(pos)
    timer:start(1) -- Start checking immediately
end,

-- Define on_timer to handle reversion or continuous check
on_timer = function(pos)
    local objs = minetest.get_objects_inside_radius(pos, stoneblocks_check_player_within) -- radius for player detection
    local player_nearby = false
    for _, obj in ipairs(objs) do
        if obj:is_player() then
            player_nearby = true
            break
        end
    end

    if player_nearby then
        -- If a player is still nearby, reset the timer to check again
        local timer = minetest.get_node_timer(pos)
        timer:start(1) -- Continue checking for player presence
    else
        -- If no players are nearby, switch back to the unlit version and reinitialize
        minetest.swap_node(pos, {name = "stoneblocks:turquoise_dark_glass_block"})
        initialize_dark_block(pos)
    end
end,
})
