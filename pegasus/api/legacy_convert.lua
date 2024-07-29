--------------------------------------
-- Convert Better Fauna to Pegasus --
--------------------------------------

for i = 1, #pegasus.mobs do
    local new_mob = pegasus.mobs[i]
    local old_mob = "better_fauna:" .. new_mob:split(":")[2]
    minetest.register_entity(":" .. old_mob, {
        on_activate = mob_core.on_activate
    })
    minetest.register_alias_force("better_fauna:spawn_" .. new_mob:split(":")[2],
		"pegasus:spawn_" .. new_mob:split(":")[2])
end

minetest.register_globalstep(function(dtime)
    local mobs = minetest.luaentities
    for _, mob in pairs(mobs) do
        if mob
        and mob.name:match("better_fauna:") then
			local pos = mob.object:get_pos()
			if not pos then return end
            if mob.name:find("lasso_fence_ent") then
                if pos then
                    minetest.add_entity(pos, "pegasus:lasso_fence_ent")
                end
                mob.object:remove()
            elseif mob.name:find("lasso_visual") then
                if pos then
                    minetest.add_entity(pos, "pegasus:lasso_visual")
                end
                mob.object:remove()
            end
            for i = 1, #pegasus.mobs do
                local ent = pegasus.mobs[i]
                local new_name = ent:split(":")[2]
                local old_name = mob.name:split(":")[2]
                if new_name == old_name then
                    if pos then
                        local new_mob = minetest.add_entity(pos, ent)
                        local mem = nil
                        if mob.memory then
                            mem = mob.memory
                        end
                        minetest.after(0.1, function()
                            if mem then
                                new_mob:get_luaentity().memory = mem
                                new_mob:get_luaentity():on_activate(new_mob, nil, dtime)
                            end
                        end)
                    end
                    mob.object:remove()
                end
            end
        end
    end
end)


-- Tools

minetest.register_alias_force("better_fauna:net", "pegasus:net")
minetest.register_alias_force("better_fauna:lasso", "pegasus:lasso")
minetest.register_alias_force("better_fauna:saddle", "pegasus:saddle")
minetest.register_alias_force("better_fauna:shears", "pegasus:shears")

-- Drops

minetest.register_alias_force("better_fauna:beef_raw", "pegasus:beef_raw")
minetest.register_alias_force("better_fauna:beef_cooked", "pegasus:beef_cooked")
minetest.register_alias_force("better_fauna:leather", "pegasus:leather")