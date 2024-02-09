local sound_api = {}

local has_default_mod = minetest.get_modpath("default")
for _, sound in ipairs({"stone", "glass"}) do
    local sound_function_name = "node_sound_" .. sound .. "_defaults"
    if has_default_mod then
        sound_api[sound_function_name] = default[sound_function_name]
    else
        sound_api[sound_function_name] = function() return {} end
    end
end

return sound_api