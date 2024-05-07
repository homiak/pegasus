-------------
--- Armor ---
-------------
-- Ver 1.0 --

-- Pure Water-Forged Armor --

armor:register_armor("waterdragon:helmet_pure_water_draconic_steel", {
    description = "Pure Water-Forged Draconic Steel Helmet",
    inventory_image = "waterdragon_inv_helmet_pure_water_draconic_steel.png",
    groups = {armor_head=1, armor_heal=30, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_pure_water=1},
    armor_groups = {fleshy=130},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:chestplate_pure_water_draconic_steel", {
    description = "Pure Water-Forged Draconic Steel Chestplate",
    inventory_image = "waterdragon_inv_chestplate_pure_water_draconic_steel.png",
    groups = {armor_torso=1, armor_heal=30, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_pure_water=1},
    armor_groups = {fleshy=130},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:leggings_pure_water_draconic_steel", {
    description = "Pure Water-Forged Draconic Steel Leggings",
    inventory_image = "waterdragon_inv_leggings_pure_water_draconic_steel.png",
    groups = {armor_legs=1, armor_heal=30, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_pure_water=1},
    armor_groups = {fleshy=130},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:boots_pure_water_draconic_steel", {
    description = "Pure Water-Forged Draconic Steel Boots",
    inventory_image = "waterdragon_inv_boots_pure_water_draconic_steel.png",
    groups = {armor_feet=1, armor_heal=30, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_pure_water=1},
    armor_groups = {fleshy=130},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})

-- Rare Water-Forged Armor --

armor:register_armor("waterdragon:helmet_rare_water_draconic_steel", {
    description = "Rare Water-Forged Draconic Steel Helmet",
    inventory_image = "waterdragon_inv_helmet_rare_water_draconic_steel.png",
    groups = {armor_head=1, armor_heal=40, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_water=1},
    armor_groups = {fleshy=150},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:chestplate_rare_water_draconic_steel", {
    description = "Rare Water-Forged Draconic Steel Chestplate",
    inventory_image = "waterdragon_inv_chestplate_rare_water_draconic_steel.png",
    groups = {armor_torso=1, armor_heal=40, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_water=1},
    armor_groups = {fleshy=150},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:leggings_rare_water_draconic_steel", {
    description = "Rare Water-Forged Draconic Steel Leggings",
    inventory_image = "waterdragon_inv_leggings_rare_water_draconic_steel.png",
    groups = {armor_legs=1, armor_heal=40, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_water=1},
    armor_groups = {fleshy=150},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})
armor:register_armor("waterdragon:boots_rare_water_draconic_steel", {
    description = "Rare Water-Forged Draconic Steel Boots",
    inventory_image = "waterdragon_inv_boots_rare_water_draconic_steel.png",
    groups = {armor_feet=1, armor_heal=40, armor_use=100,
        physics_speed=0.5, physics_gravity=0.05, physics_jump=0.15, armor_water=1},
    armor_groups = {fleshy=150},
    damage_groups = {cracky=1, snappy=3, choppy=2, crumbly=1, level=30},
})