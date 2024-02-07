minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "scatter",
    ore            = "stoneblocks:stone_with_sapphire",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 16 * 10 * 8, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = -15, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -500,
})

minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "sheet",
    ore            = "stoneblocks:stone_with_ruby",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 15 * 9 * 7, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = -10, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -600,
})

minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "vein",
    ore            = "stoneblocks:stone_with_emerald",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 17 * 11 * 9, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = -20, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -500,
})

minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "vein",
    ore            = "stoneblocks:stone_with_turquoise_glass",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 14 * 18 * 6, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = -40, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -600,
})

minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "scatter",
    ore            = "stoneblocks:stone_with_turquoise",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 13 * 17 * 5, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = -25, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -600,
})

minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "blob",
    ore            = "stoneblocks:red_granite_block",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 13 * 7 * 5, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = 100, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -700,
})

minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "scatter",
    ore            = "stoneblocks:black_granite_block",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 13 * 7 * 5, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = 100, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -700,
})

minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "scatter",
    ore            = "stoneblocks:grey_granite",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 13 * 7 * 5, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = 100, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -700,
})

minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "scatter",
    ore            = "stoneblocks:rose_granite_block",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 13 * 7 * 5, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = 100, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -700,
})

minetest.register_ore({ -- https://api.minetest.net/ores/
    ore_type       = "scatter",
    ore            = "stoneblocks:granite_block",
    wherein        = "default:stone", --  Node in which the ore generates.
    clust_scarcity = 13 * 7 * 5, --  How rare each cluster is; lower values = more common.  Means one ore per 512 nodes on average, which is relatively scarce
    clust_num_ores = 8, --  Number of ores in a cluster.
    clust_size     = 3,
    y_max          = 100, --  Maximum and minimum Y-coordinates for the ore's generation.
    y_min          = -700,
})