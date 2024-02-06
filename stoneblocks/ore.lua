minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "scatter",
    ore            = "stoneblocks:stone_with_sapphire",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 16 * 10 * 8, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = 10, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -500,
})
