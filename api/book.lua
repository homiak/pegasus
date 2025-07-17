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

-- Define text elements with positions and sizes
local text_elements = {
    {filename = "pegasus_intro.txt", x = 0.5, y = 1, w = 11, h = 20, page = 1},
    {filename = "pegasus_wtd_interaction.txt", x = 0.5, y = 1, w = 11, h = 20, page = 2},
}

local image_elements = {
}

-- Define all animations
local animations = {
    { name = "stand",     range = { x = 1, y = 59 } },
    { name = "walk",      range = { x = 70, y = 89 } },
    { name = "run",       range = { x = 101, y = 119 } },
    { name = "punch_aoe", range = { x = 170, y = 205 } },
    { name = "rear",      range = { x = 130, y = 160 } },
    { name = "eat",       range = { x = 210, y = 240 } }
}


local waterdragon_animations = {
    {name = "stand", range = {x = 1, y = 59}, speed = 8},
    {name = "stand_water", range = {x = 61, y = 119}, speed = 20},
    {name = "slam", range = {x = 121, y = 159}, speed = 30},
    {name = "repel", range = {x = 161, y = 209}, speed = 30},
    {name = "walk", range = {x = 211, y = 249}, speed = 40},
    {name = "walk_slow", range = {x = 211, y = 249}, speed = 15},
    {name = "walk_water", range = {x = 251, y = 289}, speed = 30},
    {name = "takeoff", range = {x = 291, y = 319}, speed = 30},
    {name = "hover", range = {x = 321, y = 359}, speed = 30},
    {name = "hover_water", range = {x = 361, y = 399}, speed = 30},
    {name = "fly", range = {x = 401, y = 439}, speed = 30},
    {name = "fly_water", range = {x = 441, y = 479}, speed = 30},
    {name = "land", range = {x = 481, y = 509}, speed = 30},
    {name = "sleep", range = {x = 511, y = 569.5}, speed = 6},
    {name = "death", range = {x = 571, y = 579}, speed = 30},
    {name = "shoulder_idle", range = {x = 581, y = 639}, speed = 30}
}

local current_animation = 1
local current_waterdragon_animation = 1

local current_page = 1
local total_pages = 2

local function get_book_formspec()
    local formspec = {
        "formspec_version[4]",
        "size[16,10]",
        "background[-0.7,-0.5;17.5,11.5;pegasus_book_bg.png]",
        "label[0.5,0.5;Book of Pegasus]",
        "style_type[label,textarea;textcolor=#34495e]",
    }
    
    -- Iterate over the text elements and only render the ones for the current page
    for _, element in ipairs(text_elements) do
        if element.page == current_page then  -- Check if this text element is for the current page
            local content = load_text(element.filename)
            table.insert(formspec, string.format(
                "textarea[%f,%f;%f,%f;;%s;]",
                element.x, element.y, element.w, element.h, minetest.formspec_escape(content)
            ))
        end
    end
    
    -- Iterate over image elements (no page filtering necessary since they are not linked to specific pages)
    for _, element in ipairs(image_elements) do
        table.insert(formspec, string.format(
            "image[%f,%f;%f,%f;%s]",
            element.x, element.y, element.w, element.h, element.filename
        ))
    end

    -- Add Pegasus model with current animation on page 1
    if current_page == 1 then
        local texture = "pegasus_1.png"
        local anim = animations[current_animation]
        local frame_loop = anim.range.x .. "," .. anim.range.y
        table.insert(formspec, string.format(
            "model[8,1.75;8,6.5;mob_mesh;pegasus_pegasus.b3d;%s;-10,-120;false;true;%s;30]",
            texture, frame_loop
        ))

        -- Add label to show current animation name at the top
        table.insert(formspec, string.format(
            "label[10.5,0.7;Current Animation: %s]", anim.name
        ))
    elseif current_page == 2 and minetest.get_modpath("waterdragon") then
        -- Water Dragon model and animation for page 2
        local waterdragon_texture = "pegasus_rare_water_dragon.png^pegasus_baked_in_shading.png^pegasus_rare_water_eyes_orange.png^pegasus_wing_fade.png"
        local waterdragon_anim = waterdragon_animations[current_waterdragon_animation]
        local waterdragon_frame_loop = waterdragon_anim.range.x .. "," .. waterdragon_anim.range.y
        table.insert(formspec, string.format(
            "model[8,1.75;7,6.5;mob_mesh;pegasus_water_dragon.b3d;%s;-10,-130;false;true;%s;%d]",
            waterdragon_texture, waterdragon_frame_loop, waterdragon_anim.speed
        ))
        table.insert(formspec, string.format(
            "label[10,0.7;Water Dragon Animation: %s]", waterdragon_anim.name
        ))
    end
    
    -- Add navigation buttons
    if current_page < total_pages then
        table.insert(formspec, string.format(
            "image_button[15,9;1,1;pegasus_book_icon_next.png;btn_next;;true;false;]"
        ))
    end
    if current_page > 1 then
        table.insert(formspec, string.format(
            "image_button[0,9;1,1;pegasus_book_icon_last.png;btn_prev;;true;false;]"
        ))
    end
    
    return table.concat(formspec, "")
end


local animation_timer = 0
minetest.register_globalstep(function(dtime)
    animation_timer = animation_timer + dtime
    if animation_timer >= 5 then  -- Change animation every 5 seconds
        animation_timer = 0
        if current_page == 1 then
            current_animation = current_animation % #animations + 1
        else
            current_waterdragon_animation = current_waterdragon_animation % #waterdragon_animations + 1
        end
        for _, player in ipairs(minetest.get_connected_players()) do
            if player:get_inventory():contains_item("main", "pegasus:book_pegasus") then
                show_book_formspec(player)
            end
        end
    end
end)

local book_open = {}

local function update_animations()
    if current_page == 1 then
        current_animation = current_animation % #animations + 1
    else
        current_waterdragon_animation = current_waterdragon_animation % #waterdragon_animations + 1
    end
end

function show_book_formspec(player)
    local player_name = player:get_player_name()
    if book_open[player_name] then
        minetest.show_formspec(player_name, "pegasus:book", get_book_formspec())
    end
end

minetest.register_globalstep(function(dtime)
    animation_timer = animation_timer + dtime
    if animation_timer >= 5 then
        animation_timer = 0
        update_animations()
        for _, player in ipairs(minetest.get_connected_players()) do
            if book_open[player:get_player_name()] then
                show_book_formspec(player)
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
        book_open[player_name] = true
        current_animation = 1
        current_waterdragon_animation = 1
        show_book_formspec(user)
        return itemstack
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "pegasus:book" then
        local player_name = player:get_player_name()
        if fields.quit then
            book_open[player_name] = nil
        elseif fields.btn_next then
            current_page = math.min(current_page + 1, total_pages)
            if current_page == 1 then
                current_animation = 1
            else
                current_waterdragon_animation = 1
            end
            show_book_formspec(player)
        elseif fields.btn_prev then
            current_page = math.max(current_page - 1, 1)
            if current_page == 1 then
                current_animation = 1
            else
                current_waterdragon_animation = 1
            end
            show_book_formspec(player)
        end
    end
end)

minetest.register_on_leaveplayer(function(player)
    book_open[player:get_player_name()] = nil
end)        

