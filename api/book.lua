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
    {filename = "pegasus_intro.txt", x = 0.5, y = 1, w = 11, h = 2},
    {filename = "characteristics.txt", x = 0.5, y = 3.5, w = 5.5, h = 3},
    {filename = "interaction.txt", x = 6, y = 3.5, w = 5.5, h = 4},
}

-- Define image elements with positions and sizes
local image_elements = {
    {filename = "pegasus_image1.png", x = 0.5, y = 7, w = 2, h = 2},
    {filename = "pegasus_image2.png", x = 9.5, y = 7, w = 2, h = 2},
}

local function get_book_formspec()
    local formspec = {
        "formspec_version[4]",
        "size[12,10]",
        "background[-0.7,-0.5;13.5,11.5;pegasus_book_bg.png]",
        "label[0.5,0.5;Book of Pegasus]",
    }

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

    return table.concat(formspec, "")
end

minetest.register_craftitem("pegasus:book_pegasus", {
    description = S("Book of Pegasus"),
    inventory_image = "pegasus_book_pegasus.png",
    stack_max = 1,
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        minetest.show_formspec(player_name, "pegasus:book", get_book_formspec())
    end
})