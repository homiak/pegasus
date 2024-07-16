-------------
--- Armour ---
-------------

-- Ver 1.0 --

local S = waterdragon.S

-- Pure Water-Forged Armour --

armor:register_armor("waterdragon:helmet_pure_water_draconic_steel", {
    description = S("Pure Water-Forged Draconic Steel Helmet"),
    inventory_image = "waterdragon_inv_helmet_pure_water_draconic_steel.png",
    groups = {armor_head=1, armor_heal=30, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=130},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:chestplate_pure_water_draconic_steel", {
    description = S("Pure Water-Forged Draconic Steel Chestplate"),
    inventory_image = "waterdragon_inv_chestplate_pure_water_draconic_steel.png",
    groups = {armor_torso=1, armor_heal=30, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=130},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:leggings_pure_water_draconic_steel", {
    description = S("Pure Water-Forged Draconic Steel Leggings"),
    inventory_image = "waterdragon_inv_leggings_pure_water_draconic_steel.png",
    groups = {armor_legs=1, armor_heal=30, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=130},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:boots_pure_water_draconic_steel", {
    description = S("Pure Water-Forged Draconic Steel Boots"),
    inventory_image = "waterdragon_inv_boots_pure_water_draconic_steel.png",
    groups = {armor_feet=1, armor_heal=30, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=130},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})

-- Rare Water-Forged Armour --

armor:register_armor("waterdragon:helmet_rare_water_draconic_steel", {
    description = S("Rare Water-Forged Draconic Steel Helmet"),
    inventory_image = "waterdragon_inv_helmet_rare_water_draconic_steel.png",
    groups = {armor_head=1, armor_heal=40, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=150},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:chestplate_rare_water_draconic_steel", {
    description = S("Rare Water-Forged Draconic Steel Chestplate"),
    inventory_image = "waterdragon_inv_chestplate_rare_water_draconic_steel.png",
    groups = {armor_torso=1, armor_heal=40, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=150},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:leggings_rare_water_draconic_steel", {
    description = S("Rare Water-Forged Draconic Steel Leggings"),
    inventory_image = "waterdragon_inv_leggings_rare_water_draconic_steel.png",
    groups = {armor_legs=1, armor_heal=40, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=150},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:boots_rare_water_draconic_steel", {
    description = S("Rare Water-Forged Draconic Steel Boots"),
    inventory_image = "waterdragon_inv_boots_rare_water_draconic_steel.png",
    groups = {armor_feet=1, armor_heal=40, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=150},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})

-- Pure Water Draconic Scale Armour

armor:register_armor("waterdragon:leggings_pure_water_draconic", {
    description = S("Pure Water Draconic Scale Leggings"),
    inventory_image = "waterdragon_leggings_pure_water_draconic_inv.png",
    groups = {armor_legs=1, armor_heal=20, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=80},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=10},
})

armor:register_armor("waterdragon:chestplate_pure_water_draconic", {
    description = S("Pure Water Draconic Scale Chestplate"),
    inventory_image = "waterdragon_chestplate_pure_water_draconic_inv.png",
    groups = {armor_torso=1, armor_heal=20, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=80},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=10},
})

armor:register_armor("waterdragon:helmet_pure_water_draconic", {
    description = S("Pure Water Draconic Scale Helmet"),
    inventory_image = "waterdragon_helmet_pure_water_draconic_inv.png",
    groups = {armor_head=1, armor_heal=20, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=70},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=10},
})

armor:register_armor("waterdragon:boots_pure_water_draconic", {
    description = S("Pure Water Draconic Scale Boots"),
    inventory_image = "waterdragon_boots_pure_water_draconic_inv.png",
    groups = {armor_feet=1, armor_heal=20, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=65},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=10},
})

-- Rare Water Draconic Scale Armour 

armor:register_armor("waterdragon:chestplate_rare_water_draconic", {
    description = S("Rare Water Draconic Scale Chestplate"),
    inventory_image = "waterdragon_chestplate_rare_water_draconic_inv.png",
    groups = {armor_torso=1, armor_heal=20, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=90},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=15},
})

armor:register_armor("waterdragon:helmet_rare_water_draconic", {
    description = S("Rare Water Draconic Scale Helmet"),
    inventory_image = "waterdragon_helmet_rare_water_draconic_inv.png",
    groups = {armor_head=1, armor_heal=20, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=80},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=15},
})

armor:register_armor("waterdragon:leggings_rare_water_draconic", {
    description = S("Rare Water Draconic Scale Leggings"),
    inventory_image = "waterdragon_leggings_rare_water_draconic_inv.png",
    groups = {armor_legs=1, armor_heal=20, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=85},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=15},
})

armor:register_armor("waterdragon:boots_rare_water_draconic", {
    description = S("Rare Water Draconic Scale Boots"),
    inventory_image = "waterdragon_boots_rare_water_draconic_inv.png",
    groups = {armor_feet=1, armor_heal=20, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_fire=1},
    armor_groups = {fleshy=75},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=15},
})
