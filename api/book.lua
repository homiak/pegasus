local S = pegasus.S

local function get_book_formspec()
    local formspec = {
        "formspec_version[4]",
        "size[12,10]",
        "background[-0.7,-0.5;13.5,11.5;pegasus_book_bg.png]",
        "label[0.5,0.5;Book of Pegasus]",
        "textarea[0.5,1;11,8;;",
        "The Pegasus is a majestic creature, born of myth and legend. ",
        "With its powerful wings and noble bearing, it soars through the skies, ",
        "embodying freedom and grace.\n\n",
        "Characteristics:\n",
        "- Winged horse with the ability to fly\n",
        "- Known for its wisdom and loyalty\n",
        "- Often associated with inspiration and the Muses\n\n",
        "Interacting with a Pegasus:\n",
        "1. Approach carefully, showing respect\n",
        "2. Offer it an apple or wheat as a sign of friendship\n",
        "3. Then you must mount the Pegasus, remain seated until there are green balls flying around it\n",
        "4. When flying, hold on tight and enjoy the view!\n\n",
        "Remember, a Pegasus is a companion, not a mere mount. Treat it with kindness and care.",
        ";]"
    }
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
