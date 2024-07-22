-----------
-- Book --
-----------

local S = waterdragon.S
local color = minetest.colorize

local book_bg = {
	"formspec_version[3]",
	"size[16,10]",
	"background[-0.7,-0.5;17.5,11.5;waterdragon_book_bg.png]",
}

local book_drp_font_scale = "dropdown[17,0;0.75,0.5;drp_font_scale;0.25,0.5,0.75,1;1]"

local book_pages = {
	{ -- Home
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "waterdragon_book_home.txt"
		},
		{ -- Water Dragon Image
			element_type = "image",
			font_size = 24,
			offset = {x = 8.19, y = 1.19},
			size = {x = 8.5, y = 8.5},
			text = "waterdragon_book_img_water_dragon_3.png"
		},
		{ -- Next Page
			unlock_key = "waterdragons",
			element_type = "image_button",
			font_size = 24,
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_next.png;btn_next;;true;false"
		},
	},
	-- Chapter 1
	{ -- Dragons Page 1
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "waterdragon_book_dragon1.txt"
		},
		{ -- Water Dragon Image
			element_type = "image",
			font_size = 24,
			offset = {x = 8, y = 1.2},
			size = {x = 8, y = 8},
			text = "waterdragon_book_img_water_dragon.png"
		},
		{ -- Next Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_last.png;btn_last;;true;false"
		}
	},
	{ -- Dragons Page 2
		{ -- Water Dragon Image
		element_type = "image",
		font_size = 24,
		offset = {x = 0, y = 1.3},
		size = {x = 8, y = 8},
		text = "waterdragon_book_img_water_dragon_2.png"
		},
		{ -- Combat Text
			element_type = "label",
			font_size = 24,
			offset = {x = 8, y = 1.5},
			file = "waterdragon_book_dragon2.txt"
		},
		{ -- Next Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_last.png;btn_last;;true;false"
		}
	},
	{ -- Dragons Page 3
		{ -- Hatching Text
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "waterdragon_book_dragon3.txt"
		},
		{ -- Water Dragon Text
			element_type = "label",
			font_size = 24,
			offset = {x = 8, y = 1.5},
			file = "waterdragon_book_dragon4.txt"
		},
		{ -- Next Page
			element_type = "image_button",
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_last.png;btn_last;;true;false"
		},
		{ -- Last Page
			unlock_key = "draconic_steel",
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_last.png;btn_last;;true;false"
		}
	},
	
	-- Chapter 2
	{ -- Steel Page 1
		{ -- Main Page
			unlock_key = "draconic_steel",
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "waterdragon_book_steel1.txt"
		},
		{ -- Page 2
			element_type = "label",
			font_size = 24,
			offset = {x = 8, y = 1.5},
			file = "waterdragon_book_steel2.txt"
		},
		{ -- Next Page
			element_type = "image_button",
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_last.png;btn_last;;true;false"
		}
	},
{ -- Steel Page 2
		{ -- Forge Instructions
			element_type = "image",
			offset = {x = 1.5, y = 0.5},
			size = {x = 5, y = 10},
			text = "waterdragon_book_img_forge_instructions.png"
		},	
		{ -- Forge Label
			element_type = "label",
			font_size = 24,
			offset = {x = 2, y = 0.5},
			text = "Constructing a Forge:"
		},
		{ -- Page 2
			element_type = "label",
			font_size = 24,
			offset = {x = 8, y = 0.5},
			file = "waterdragon_book_steel3.txt"
		},
		{ -- Next Page
			element_type = "image_button",
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			element_type = "image_button",
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_last.png;btn_last;;true;false"
		}
	},
	{ -- Steel Page 3
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1},
			file = "waterdragon_book_steel4.txt"
		},
		{ -- Forge Label
			element_type = "label",
			font_size = 24,
			offset = {x = 11.5, y = 5.5},
			text = "Pure Water Forge:"
		},
		{ -- pure_water Forge Instructions
			element_type = "image",
			offset = {x = 10.5, y = 6.5},
			size = {x = 4.5, y = 2.5},
			text = "waterdragon_book_img_forge_demo.png"
		},
		{ -- Forge Label
			element_type = "label",
			font_size = 24,
			offset = {x = 11.5, y = 0.5},
			text = "Rare Water Forge:"
		},
		{ -- rare_water Forge Instructions
			element_type = "image",
			offset = {x = 10.5, y = 2.5},
			size = {x = 4.5, y = 2.5},
			text = "waterdragon_book_img_rare_water_forge_demo.png"
		},
		{ -- Last Page
			element_type = "image_button",
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "waterdragon_book_icon_last.png;btn_last;;true;false"
		}
	}
}

---------
-- API --
---------

function waterdragon.contains_book(inventory)
    return inventory and inventory:contains_item("main", ItemStack("waterdragon:book_waterdragon"))
end

local function contains_item(inventory, item)
    return inventory and inventory:contains_item("main", ItemStack(item))
end

function waterdragon.get_book(inventory)
    local list = inventory:get_list("main")
    for i = 1, inventory:get_size("main") do
        local stack = list[i]
        if stack:get_name()
        and stack:get_name() == "waterdragon:book_waterdragon" then
            return stack, i
        end
    end
end

function waterdragon.add_page(inv, chapter)
    local book, list_i = waterdragon.get_book(inv)
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
		local font_size_x = (waterdragon.book_font_size[playername] or 1)
		local font_size = (def.font_size or 16) * font_size_x
		if def.file then
			local filename = minetest.get_modpath("waterdragon") .. "/book_of_wtd/" .. def.file
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

minetest.register_craftitem("waterdragon:book_waterdragon", {
	description = S("Book about Water Dragons"),
	inventory_image = "waterdragon_book_waterdragon.png",
	stack_max = 1,
	on_place = function(itemstack, player)
		local meta = itemstack:get_meta()
		local desc = meta:get_string("description")
		if desc:find("Bestiary") then
			meta:set_string("description", S("Book about Water Dragons"))
			meta:set_string("pages", nil)
		end
		local name = player:get_player_name()
		minetest.show_formspec(name, "waterdragon:book_page_1", getPage(1, meta, name))
	end,
	on_secondary_use = function(itemstack, player)
		local meta = itemstack:get_meta()
		local desc = meta:get_string("description")
		if desc:find("Bestiary") then
			meta:set_string("description", S("Book about Water Dragons"))
			meta:set_string("pages", nil)
		end
		local name = player:get_player_name()
		minetest.show_formspec(name, "waterdragon:book_page_1", getPage(1, meta, name))
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
		if formname == "waterdragon:book_page_" .. i then
			page_no = i
			if fields.btn_next
			and book_pages[i + 1] then
				minetest.show_formspec(plyr_name,
					"waterdragon:book_page_" .. i + 1, getPage(i + 1, meta, plyr_name))
				return true
			elseif fields.btn_last
			and book_pages[i - 1] then
				minetest.show_formspec(plyr_name,
					"waterdragon:book_page_" .. i - 1, getPage(i - 1, meta, plyr_name))
				return true
			end
		end
	end
	if fields.btn_waterdragons then
		minetest.show_formspec(plyr_name, "waterdragon:book_page_" .. 2, getPage(2, meta, plyr_name))
		return true
	end
	if fields.btn_draconic_steel then
		minetest.show_formspec(plyr_name, "waterdragon:book_page_" .. 5, getPage(5, meta, plyr_name))
		return true
	end
	if fields.drp_font_scale
	and page_no then
		waterdragon.book_font_size[plyr_name] = fields.drp_font_scale
		minetest.show_formspec(plyr_name, "waterdragon:book_page_" .. page_no, getPage(page_no, meta, plyr_name))
		return true
	end
end)

minetest.register_globalstep(function()
    for _, player in pairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local inv = minetest.get_inventory({type = "player", name = name})
        if waterdragon.contains_book(inv) then
			if contains_item(inv, "waterdragon:dragonstone_block_pure_water")
			or contains_item(inv, "waterdragon:dragonstone_block_rare_water") then
				waterdragon.add_page(inv, "draconic_steel")
			end
        end
    end
end)


-- To Do

-- Flight Stamina
