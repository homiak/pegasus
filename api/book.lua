local S = pegasus.S
local modpath = minetest.get_modpath("pegasus")

-- Load texts from separate files
local function load_text(filename)
    local file = io.open(modpath .. "/book/" .. filename, "r")
    if not file then return "" end
    local content = file:read("*all")
    file:close()
    return content
end

-- Define all animations
local animations = {
    { name = "stand",     range = { x = 1, y = 59 },    speed = 10 },
    { name = "walk",      range = { x = 70, y = 89 },   speed = 20 },
    { name = "run",       range = { x = 101, y = 119 }, speed = 40 },
    { name = "punch_aoe", range = { x = 170, y = 205 }, speed = 30 },
    { name = "rear",      range = { x = 130, y = 160 }, speed = 20 },
    { name = "eat",       range = { x = 210, y = 240 }, speed = 30 }
}

local waterdragon_animations = {
    { name = "stand",         range = { x = 1, y = 59 },    speed = 8 },
    { name = "slam",          range = { x = 121, y = 159 }, speed = 30 },
    { name = "repel",         range = { x = 161, y = 209 }, speed = 30 },
    { name = "walk",          range = { x = 211, y = 249 }, speed = 40 },
    { name = "hover",         range = { x = 321, y = 359 }, speed = 30 },
    { name = "fly",           range = { x = 401, y = 439 }, speed = 30 },
    { name = "death",         range = { x = 571, y = 579 }, speed = 30 },
    { name = "shoulder_idle", range = { x = 581, y = 639 }, speed = 30, }
}

-- Dynamic Page Management
local page_map = {}
local total_pages = 0

local function build_page_map()
    page_map = {} -- Reset
    table.insert(page_map, { type = "pegasus", text_file = "pegasus_intro.txt" })
    if minetest.get_modpath("waterdragon") then
        table.insert(page_map, { type = "waterdragon", text_file = "pegasus_wtd_interaction.txt" })
    end
    -- The new tools page is always added last
    table.insert(page_map, { type = "tool_usage", text_file = "pegasus_tool_usage.txt" })
    total_pages = #page_map
end

-- Build the map on load
build_page_map()

-- Player-specific book state
local book_states = {}

local function get_player_state(player_name)
    if not book_states[player_name] then
        book_states[player_name] = {
            page = 1,
            anim_pegasus = 1,
            anim_waterdragon = 1,
            timer = 0,
            is_open = false
        }
    end
    return book_states[player_name]
end

local function get_book_formspec(player_name)
    local state = get_player_state(player_name)
    local page_info = page_map[state.page]
    if not page_info then return "" end

    local formspec = {
        "formspec_version[4]",
        "size[16,10]",
        "background[-0.7,-0.5;17.5,11.5;pegasus_book_bg.png]",
        "label[0.5,0.5;Book of Pegasus]",
        "style_type[label,textarea;textcolor=#34495e]",
    }

    -- Render text for the current page
    local content = load_text(page_info.text_file)
    table.insert(formspec, string.format(
        "textarea[0.5,1;7,8.5;;%s;]",
        minetest.formspec_escape(content)
    ))

    -- Render model/images based on page type
    if page_info.type == "pegasus" then
        local anim = animations[state.anim_pegasus]
        table.insert(formspec,
            string.format("model[8,1.75;8,6.5;mob_mesh;pegasus_pegasus.b3d;pegasus_1.png;-10,-120;false;true;%s,%s;30]",
                anim.range.x, anim.range.y))
        table.insert(formspec, string.format("label[10.5,0.7;Animation: %s]", anim.name))
    elseif page_info.type == "waterdragon" then
        local anim = waterdragon_animations[state.anim_waterdragon]
        local texture =
        "pegasus_rare_water_dragon.png^pegasus_baked_in_shading.png^pegasus_rare_water_eyes_orange.png^pegasus_wing_fade.png"
        table.insert(formspec,
            string.format("model[8,1.75;7,6.5;mob_mesh;waterdragon_water_dragon.b3d;%s;-10,-130;false;true;%s,%s;%d]",
                texture, anim.range.x, anim.range.y, anim.speed))
        table.insert(formspec, string.format("label[10,0.7;Animation: %s]", anim.name))
    elseif page_info.type == "tool_usage" then
        -- Swapped layout: Tools on the left, Pegasus on the right.
        -- Pegasus image is now using its correct aspect ratio (532x377 -> ~4.2x3).

        -- Tools on the left side of the page
        table.insert(formspec, "label[9.3, 2.5;Nametag]")
        table.insert(formspec, "image[9, 3; 2.5, 2.5;pegasus_nametag.png]")

        table.insert(formspec, "label[9, 6;Parade Wand]")
        table.insert(formspec, "image[8.7, 6.5; 2.5, 2.5;pegasus_parade_wand.png]")

        -- Pegasus on the right, looking left at the tools
        table.insert(formspec, "image[11.5, 3.5; 4.2, 3;pegasus_book_peg_scr.png]")
    end

    -- Navigation buttons
    if state.page < total_pages then
        table.insert(formspec, "image_button[15,9;1,1;pegasus_book_icon_next.png;btn_next;;true;false;]")
    end
    if state.page > 1 then
        -- Moved the button slightly to the right
        table.insert(formspec, "image_button[0.5,9;1,1;pegasus_book_icon_last.png;btn_prev;;true;false;]")
    end

    return table.concat(formspec, "")
end

function show_book_formspec(player)
    local player_name = player:get_player_name()
    local state = get_player_state(player_name)
    if state.is_open then
        minetest.show_formspec(player_name, "pegasus:book", get_book_formspec(player_name))
    end
end

minetest.register_globalstep(function(dtime)
    for player_name, state in pairs(book_states) do
        if state.is_open then
            state.timer = state.timer + dtime
            if state.timer >= 5 then
                state.timer = 0
                local page_info = page_map[state.page]
                if page_info.type == "pegasus" then
                    state.anim_pegasus = state.anim_pegasus % #animations + 1
                elseif page_info.type == "waterdragon" then
                    state.anim_waterdragon = state.anim_waterdragon % #waterdragon_animations + 1
                end
                local player = minetest.get_player_by_name(player_name)
                if player then
                    show_book_formspec(player)
                end
            end
        end
    end
end)

minetest.register_craftitem("pegasus:book_pegasus", {
    description = S("Book of Pegasus"),
    inventory_image = "pegasus_book_pegasus.png",
    stack_max = 1,
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        local state = get_player_state(player_name)
        state.is_open = true
        state.page = 1
        state.anim_pegasus = 1
        state.anim_waterdragon = 1
        show_book_formspec(user)
        return itemstack
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "pegasus:book" then
        local player_name = player:get_player_name()
        local state = get_player_state(player_name)
        if fields.quit then
            state.is_open = false
        elseif fields.btn_next then
            state.page = math.min(state.page + 1, total_pages)
            show_book_formspec(player)
        elseif fields.btn_prev then
            state.page = math.max(state.page - 1, 1)
            show_book_formspec(player)
        end
    end
end)

minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    if book_states[player_name] then
        book_states[player_name].is_open = false
    end
end)
