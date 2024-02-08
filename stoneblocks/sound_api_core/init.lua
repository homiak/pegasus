local sound_api = {}

function sound_api.node_sound_stone_defaults(table)
    if minetest.get_modpath("default") then
        return default.node_sound_stone_defaults(table)
    elseif minetest.get_modpath("mcl_sounds") then
        return mcl_sounds.node_sound_stone_defaults(table)
    elseif minetest.get_modpath("nodes_nature") then
        return nodes_nature.node_sound_stone_defaults(table)
    elseif minetest.get_modpath("fl_stone") then
        return fl_stone.sounds.stone(table)
    elseif minetest.get_modpath("hades_sounds") then
        return hades_sounds.node_sound_stone_defaults(table)
    elseif minetest.get_modpath("rp_sounds") then
        return rp_sounds.node_sound_stone_defaults(table)
    else
        return table
    end
end

function sound_api.node_sound_glass_defaults(table)
    if minetest.get_modpath("default") then
        return default.node_sound_glass_defaults(table)
    elseif minetest.get_modpath("mcl_sounds") then
        return mcl_sounds.node_sound_glass_defaults(table)
    elseif minetest.get_modpath("nodes_nature") then
        return nodes_nature.node_sound_glass_defaults(table)
    elseif minetest.get_modpath("hades_sounds") then
        return hades_sounds.node_sound_glass_defaults(table)
    elseif minetest.get_modpath("rp_sounds") then
        return rp_sounds.node_sound_glass_defaults(table)
    else
        return table
    end
end

return sound_api