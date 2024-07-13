local mod_storage = minetest.get_mod_storage()

local data = {
    waterdragons = minetest.deserialize(mod_storage:get_string("waterdragons")) or {},
    bonded_wtd = minetest.deserialize(mod_storage:get_string("bonded_wtd")) or {},
    aux_key_setting = minetest.deserialize(mod_storage:get_string("aux_key_setting")) or {},
    wtd_attack_bl = minetest.deserialize(mod_storage:get_string("wtd_attack_bl")) or {},
	book_font_size = minetest.deserialize(mod_storage:get_string("book_font_size")) or {}
}

local function save()
    mod_storage:set_string("waterdragons", minetest.serialize(data.waterdragons))
    mod_storage:set_string("bonded_wtd", minetest.serialize(data.bonded_wtd))
    mod_storage:set_string("aux_key_setting", minetest.serialize(data.aux_key_setting))
    mod_storage:set_string("wtd_attack_bl", minetest.serialize(data.wtd_attack_bl))
	mod_storage:set_string("book_font_size", minetest.serialize(data.book_font_size))
end

minetest.register_on_shutdown(save)
minetest.register_on_leaveplayer(save)

local function periodic_save()
    save()
    minetest.after(120, periodic_save)
end
minetest.after(120, periodic_save)

minetest.register_globalstep(function()
	if waterdragon.force_storage_save then
		save()
		waterdragon.force_storage_save = false
	end
end)

return data