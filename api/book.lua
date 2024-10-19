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
    {filename = "pegasus_intro.txt", x = 0.5, y = 1, w = 11, h = 20},
    {filename = "characteristics.txt", x = 0.5, y = 3.5, w = 5.5, h = 3},
    {filename = "interaction.txt", x = 6, y = 3.5, w = 5.5, h = 4},
}

-- Define image elements with positions and sizes
local image_elements = {
    {filename = "pegasus_image2.png", x = 9.5, y = 7, w = 2, h = 2},
}

-- Define all animations
local animations = {
    {name = "stand", range = {x = 1, y = 59}},
    {name = "walk", range = {x = 70, y = 89}},
    {name = "run", range = {x = 101, y = 119}},
    {name = "punch_aoe", range = {x = 170, y = 205}},
    {name = "rear", range = {x = 130, y = 160}},
    {name = "eat", range = {x = 210, y = 240}}
}

local current_animation = 1

local function get_book_formspec()
    local formspec = {
        "formspec_version[4]",
        "size[16,10]",
        "background[-0.7,-0.5;17.5,11.5;pegasus_book_bg.png]",
        "label[0.5,0.5;Book of Pegasus]",
    }
    
    -- Add label to show current animation name at the top
    local anim = animations[current_animation]
    table.insert(formspec, string.format(
        "label[8,0.5;Current Animation: %s]", anim.name
    ))
    
    -- Add text elements
    for _, element in ipairs(text_elements) do
        local content = load_text(element.filename)
        table.insert(formspec, string.format(
            "textarea[%f,%f;%f,%f;;%s;]",
            element.x, element.y, element.w, element.h, minetest.formspec_escape(content)
        ))
    end
    
    -- Add image elements
    for _, element in ipairs(image_elements) do
        table.insert(formspec, string.format(
            "image[%f,%f;%f,%f;%s]",
            element.x, element.y, element.w, element.h, element.filename
        ))
    end

    -- Add Pegasus model with current animation
local texture = "pegasus.png"
local anim = animations[current_animation]
local frame_loop = anim.range.x .. "," .. anim.range.y
table.insert(formspec, string.format(
    "model[8,1.75;8,6.5;mob_mesh;pegasus_pegasus.b3d;%s;-10,-120;false;true;%s;30]",
    texture, frame_loop
))
    
    return table.concat(formspec, "")
end

local function show_book_formspec(player)
    minetest.show_formspec(player:get_player_name(), "pegasus:book", get_book_formspec())
end

local animation_timer = 0
minetest.register_globalstep(function(dtime)
    animation_timer = animation_timer + dtime
    if animation_timer >= 3.5 then  -- Change animation every 3/5 seconds
        animation_timer = 0
        current_animation = current_animation + 1
        if current_animation > #animations then
            current_animation = 1
        end
        for _, player in ipairs(minetest.get_connected_players()) do
            if player:get_inventory():contains_item("main", "pegasus:book_pegasus") then
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
        current_animation = 1
        animation_timer = 0
        show_book_formspec(user)
        return itemstack
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "pegasus:book" and fields.quit then
        -- Book closed, stop updating for this player
    end
end)