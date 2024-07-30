-----------
-- Book --
-----------

local S = pegasus.S

local color = minetest.colorize

local book_bg = {
	"formspec_version[3]",
	"size[16,10]",
	"background[-0.7,-0.5;17.5,11.5;pegasus_book_bg.png]",
}

local book_drp_font_scale = "dropdown[17,0;0.75,0.5;drp_font_scale;0.25,0.5,0.75,1;1]"

local book_pages = {
	{ -- Home
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "pegasus_book_home.txt"
		},
		{ -- Next Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "pegasus_book_icon_next.png;btn_next;;true;false"
		},
	},
	{
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "pegasus_book_pegasus2.txt"
		},
		{ -- Last Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "pegasus_book_icon_last.png;btn_last;;true;false"
		}
	},
}
---------
-- API --
---------

function pegasus.contains_book(inventory)
    return inventory and inventory:contains_item("main", ItemStack("pegasus:book_pegasus"))
end

local function contains_item(inventory, item)
    return inventory and inventory:contains_item("main", ItemStack(item))
end

function pegasus.get_book(inventory)
    local list = inventory:get_list("main")
    for i = 1, inventory:get_size("main") do
        local stack = list[i]
        if stack:get_name()
        and stack:get_name() == "pegasus:book_pegasus" then
            return stack, i
        end
    end
end

function pegasus.add_page(inv, chapter)
    local book, list_i = pegasus.get_book(inv)
    local chapters = minetest.deserialize(book:get_meta():get_string("chapters")) or {}
    if #chapters > 0 then
        for i = 1, #chapters do
			if chapters[i] == chapter then
				return
			end
        end
    end
	table.insert(chapters, chapter)
	book:get_meta():set_string("chapters", minetest.serialize(chapters))
	inv:set_stack("main", list_i, book)
	return true
end

local function prepare_element(def, meta, playername)
	local chapters = (meta and minetest.deserialize(meta:get_string("chapters"))) or {}
	local offset_x = def.offset.x
	local offset_y = def.offset.y
	local form = ""
	-- Add Book Text
	if def.element_type == "label" then
		local font_size_x = (pegasus.book_font_size[playername] or 1)
		local font_size = (def.font_size or 16) * font_size_x
		if def.file then
			local filename = minetest.get_modpath("pegasus") .. "/book/" .. def.file
			local file = io.open(filename)
			if file then
				local full_text = ""
				for line in file:lines() do
					full_text = full_text .. line .. "\n"
				end
				local total_offset = (offset_x + (0.35 - 0.35 * font_size_x)) .. "," .. offset_y
				form = form ..
					"hypertext[" .. total_offset .. ";8,9;text;<global color=#000000 size="
						.. font_size .. " halign=center>" .. full_text .. "]"
				file:close()
			end
		else
			form = form .. "style_type[label;font_size=" .. font_size .. "]"
			local line = def.text
			form = form .. "label[" .. offset_x .. "," .. offset_y .. ";" .. color("#000000", line .. "\n") .. "]"
		end
	else
		-- Add Images/Interaction
		local render = false
		if def.unlock_key and #chapters > 0 then
			for _, chapter in ipairs(chapters) do
				if chapter
				and chapter == def.unlock_key then
					render = true
					break
				end
			end
		elseif not def.unlock_key then
			render = true
		end
		if render then
			local offset = def.offset.x .. "," .. def.offset.y
			local size = def.size.x .. "," .. def.size.y
			form = form .. def.element_type .. "[" .. offset .. ";" .. size .. ";" .. def.text .. "]"
		end
	end
	return form
end

local function getPage(key, meta, playername)
	local form = table.copy(book_bg)
	local page = book_pages[key]
	for _, element in ipairs(page) do
		if type(element) == "table" then
			local element_rendered = prepare_element(element, meta, playername)
			table.insert(form, element_rendered)
		else
			table.insert(form, element)
		end
	end
	table.insert(form, "style[drp_font_scale;noclip=true]")
	table.insert(form, book_drp_font_scale)
	table.insert(form, "style[drp_font_scale;noclip=true]")
	return table.concat(form, "")
end

---------------
-- Craftitem --
---------------

minetest.register_craftitem("pegasus:book_pegasus", {
	description = S("Book of Pegasus"),
	inventory_image = "pegasus_book_pegasus.png",
	stack_max = 1,
	on_place = function(itemstack, player)
		local meta = itemstack:get_meta()
		local desc = meta:get_string("description")
		if desc:find("Bestiary") then
			meta:set_string("description", "Book of Pegasus")
			meta:set_string("pages", nil)
		end
		local name = player:get_player_name()
		minetest.show_formspec(name, "pegasus:book_page_1", getPage(1, meta, name))
	end,
	on_secondary_use = function(itemstack, player)
		local meta = itemstack:get_meta()
		local desc = meta:get_string("description")
		if desc:find("Bestiary") then
			meta:set_string("description", "Book of Pegasus")
			meta:set_string("pages", nil)
		end
		local name = player:get_player_name()
		minetest.show_formspec(name, "pegasus:book_page_1", getPage(1, meta, name))
	end
})

--------------------
-- Receive Fields --
--------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local plyr_name = player:get_player_name()
	local meta = player:get_wielded_item():get_meta()
	local page_no
	for i = 1, #book_pages do
		if formname == "pegasus:book_page_" .. i then
			page_no = i
			if fields.btn_next
			and book_pages[i + 1] then
				minetest.show_formspec(plyr_name,
					"pegasus:book_page_" .. i + 1, getPage(i + 1, meta, plyr_name))
				return true
			elseif fields.btn_last
			and book_pages[i - 1] then
				minetest.show_formspec(plyr_name,
					"pegasus:book_page_" .. i - 1, getPage(i - 1, meta, plyr_name))
				return true
			end
		end
	end
	if fields.btn_pegasuss then
		minetest.show_formspec(plyr_name, "pegasus:book_page_" .. 2, getPage(2, meta, plyr_name))
		return true
	end
	if fields.btn_draconic_steel then
		minetest.show_formspec(plyr_name, "pegasus:book_page_" .. 5, getPage(5, meta, plyr_name))
		return true
	end
	if fields.drp_font_scale
	and page_no then
		pegasus.book_font_size[plyr_name] = fields.drp_font_scale
		minetest.show_formspec(plyr_name, "pegasus:book_page_" .. page_no, getPage(page_no, meta, plyr_name))
		return true
	end
end)

minetest.register_globalstep(function()
    for _, player in pairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local inv = minetest.get_inventory({type = "player", name = name})
        if pegasus.contains_book(inv) then
			if contains_item(inv, "pegasus:pegasus") then
				pegasus.add_page(inv, "pegasuss")
			end
        end
    end
end)

