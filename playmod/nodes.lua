minetest.register_abm({
	label = "playmod:test",
	nodenames = {'default:dry_grass','default:dry_grass_1','default:dry_grass_2','default:dry_grass_3','default:dry_grass_4','default:dry_grass_5'},
	-- neibours = {'default:dry_dirt_with_dry_grass'},
	interval = 1,
	chance = 100,
	action = function(pos) 
		pos.y = pos.y + 1,
		minetest.add_node(pos, {name = 'default:diamondblock'})
	end,
})