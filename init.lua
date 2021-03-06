-- morestairs mod with corners
-- The code is taken from: Minetest 0.4 mod: stairs and modified by Xanthin
-- idea for corners from Xanadu Server (https://forum.minetest.net/viewtopic.php?f=10&t=8494&sid=fc7fc4079a0dd155b60a44bf5a5e8a6c)

stairs = {}

-- Boilerplate to support localized strings if intllib mod is installed.
local S
if intllib then
	S = intllib.Getter()
else
	S = function(s) return s end
end

-- Node will be called stairs:stair_<subname>
function stairs.register_stair(subname, recipeitem, groups, images, description, sounds)
	minetest.register_node(":stairs:stair_" .. subname, {
		description = S(description),
		drawtype = "nodebox",
		tiles = images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = groups,
		sounds = sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- for replace ABM
	minetest.register_node(":stairs:stair_" .. subname.."upside_down", {
		replace_name = "stairs:stair_" .. subname,
		groups = {slabs_replace=1},
	})

	minetest.register_craft({
		output = 'stairs:stair_' .. subname .. ' 4',
		recipe = {
			{recipeitem, "", ""},
			{recipeitem, recipeitem, ""},
			{recipeitem, recipeitem, recipeitem},
		},
	})

	-- Flipped recipe for the silly minecrafters
	minetest.register_craft({
		output = 'stairs:stair_' .. subname .. ' 4',
		recipe = {
			{"", "", recipeitem},
			{"", recipeitem, recipeitem},
			{recipeitem, recipeitem, recipeitem},
		},
	})
end

-- Node will be called stairs:slab_<subname>
function stairs.register_slab(subname, recipeitem, groups, images, description, sounds)
	minetest.register_node(":stairs:slab_" .. subname, {
		description = S(description),
		drawtype = "nodebox",
		tiles = images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = groups,
		sounds = sounds,
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			-- If it's being placed on an another similar one, replace it with
			-- a full block
			local slabpos = nil
			local slabnode = nil
			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local n0 = minetest.get_node(p0)
			local n1 = minetest.get_node(p1)
			local param2 = 0

			local n0_is_upside_down = (n0.name == "stairs:slab_" .. subname and
					n0.param2 >= 20)

			if n0.name == "stairs:slab_" .. subname and not n0_is_upside_down and p0.y+1 == p1.y then
				slabpos = p0
				slabnode = n0
			elseif n1.name == "stairs:slab_" .. subname then
				slabpos = p1
				slabnode = n1
			end
			if slabpos then
				-- Remove the slab at slabpos
				minetest.remove_node(slabpos)
				-- Make a fake stack of a single item and try to place it
				local fakestack = ItemStack(recipeitem)
				fakestack:set_count(itemstack:get_count())

				pointed_thing.above = slabpos
				local success
				fakestack, success = minetest.item_place(fakestack, placer, pointed_thing)
				-- If the item was taken from the fake stack, decrement original
				if success then
					itemstack:set_count(fakestack:get_count())
				-- Else put old node back
				else
					minetest.set_node(slabpos, slabnode)
				end
				return itemstack
			end
			
			-- Upside down slabs
			if p0.y-1 == p1.y then
				-- Turn into full block if pointing at a existing slab
				if n0_is_upside_down  then
					-- Remove the slab at the position of the slab
					minetest.remove_node(p0)
					-- Make a fake stack of a single item and try to place it
					local fakestack = ItemStack(recipeitem)
					fakestack:set_count(itemstack:get_count())

					pointed_thing.above = p0
					local success
					fakestack, success = minetest.item_place(fakestack, placer, pointed_thing)
					-- If the item was taken from the fake stack, decrement original
					if success then
						itemstack:set_count(fakestack:get_count())
					-- Else put old node back
					else
						minetest.set_node(p0, n0)
					end
					return itemstack
				end

				-- Place upside down slab
				param2 = 20
			end

			-- If pointing at the side of a upside down slab
			if n0_is_upside_down and p0.y+1 ~= p1.y then
				param2 = 20
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- for replace ABM
	minetest.register_node(":stairs:slab_" .. subname.."upside_down", {
		replace_name = "stairs:slab_"..subname,
		groups = {slabs_replace=1},
	})

	minetest.register_craft({
		output = 'stairs:slab_' .. subname .. ' 6',
		recipe = {
			{recipeitem, recipeitem, recipeitem},
		},
	})
end

-- Replace old "upside_down" nodes with new param2 versions
minetest.register_abm({
	nodenames = {"group:slabs_replace"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		node.name = minetest.registered_nodes[node.name].replace_name
		node.param2 = node.param2 + 20
		if node.param2 == 21 then
			node.param2 = 23
		elseif node.param2 == 23 then
			node.param2 = 21
		end
		minetest.set_node(pos, node)
	end,
})

-- Node will be called stairs:corner_<subname>
function stairs.register_corner(subname, recipeitem, groups, images, description, sounds)
	minetest.register_node(":stairs:corner_" .. subname, {
		description = S(description),
		drawtype = "nodebox",
		tiles = images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = groups,
		sounds = sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0, 0.5, 0.5},
			},
		},
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y-1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
	})

	-- for replace ABM
	minetest.register_node(":stairs:corner_" .. subname.."upside_down", {
		replace_name = "stairs:corner_" .. subname,
		groups = {slabs_replace=1},
	})

	minetest.register_craft({
		output = 'stairs:corner_' .. subname .. ' 4',
		recipe = {
			{ "", "", ""},
			{ "", recipeitem, ""},
			{recipeitem, recipeitem, recipeitem},
		},
	})
end

-- Nodes will be called stairs:{stair,slab,corner}_<subname>
function stairs.register_stair_and_slab_and_corner(subname, recipeitem, groups, images, desc_stair, desc_slab, desc_corner, sounds)
	stairs.register_stair(subname, recipeitem, groups, images, desc_stair, sounds)
	stairs.register_slab(subname, recipeitem, groups, images, desc_slab, sounds)
	stairs.register_corner(subname, recipeitem, groups, images, desc_corner, sounds)
end

stairs.register_stair_and_slab_and_corner("wood", "default:wood",
		{snappy=2,choppy=2,oddly_breakable_by_hand=2,flammable=3},
		{"default_wood.png"},
		"Wooden Stair",
		"Wooden Slab",
		"Wooden Corner",
		default.node_sound_wood_defaults())

stairs.register_stair_and_slab_and_corner("stone", "default:stone",
		{cracky=3},
		{"default_stone.png"},
		"Stone Stair",
		"Stone Slab",
		"Stone Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("cobble", "default:cobble",
		{cracky=3},
		{"default_cobble.png"},
		"Cobblestone Stair",
		"Cobblestone Slab",
		"Cobblestone Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("desert_stone", "default:desert_stone",
		{cracky=3},
		{"default_desert_stone.png"},
		"Desertstone Stair",
		"Desertstone Slab",
		"Desertstone Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("desert_cobble", "default:desert_cobble",
		{cracky=3},
		{"default_desert_cobble.png"},
		"Desert Cobblestone Stair",
		"Desert Cobblestone Slab",
		"Desert Cobblestone Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("desert_stonebrick", "default:desert_stonebrick",
		{cracky=3},
		{"default_desert_stone_brick.png"},
		"Desert Stone Brick Stair",
		"Desert Stone Brick Slab",
		"Desert Stone Brick Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("brick", "default:brick",
		{cracky=3},
		{"default_brick.png"},
		"Brick Stair",
		"Brick Slab",
		"Brick Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("sandstone", "default:sandstone",
		{crumbly=2,cracky=2},
		{"default_sandstone.png"},
		"Sandstone Stair",
		"Sandstone Slab",
		"Sandstone Corner",
		default.node_sound_stone_defaults())
		
stairs.register_stair_and_slab_and_corner("sandstonebrick", "default:sandstonebrick",
		{crumbly=2,cracky=2},
		{"default_sandstone_brick.png"},
		"Sandstone Brick Stair",
		"Sandstone Brick Slab",
		"Sandstone Brick Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("junglewood", "default:junglewood",
		{snappy=2,choppy=2,oddly_breakable_by_hand=2,flammable=3},
		{"default_junglewood.png"},
		"Junglewood Stair",
		"Junglewood Slab",
		"Junglewood Corner",
		default.node_sound_wood_defaults())

stairs.register_stair_and_slab_and_corner("stonebrick", "default:stonebrick",
		{cracky=3},
		{"default_stone_brick.png"},
		"Stone Brick Stair",
		"Stone Brick Slab",
		"Stone Brick Corner",
		default.node_sound_stone_defaults())

--- Now the new blocks I added for stairs and slabs and corners

stairs.register_stair_and_slab_and_corner("desert_stone", "default:desert_stone",
		{cracky=3, stone=1},
		{"default_desert_stone.png"},
		"Desert Stone Stair",
		"Desert Stone Slab",
		"Desert Stone Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("desert_stonebrick", "default:desert_stonebrick",
		{cracky=2, stone=1},
		{"default_desert_stone_brick.png"},
		"Desert Stone Brick Stair",
		"Desert Stone Brick Slab",
		"Desert Stone Brick Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("dirt", "default:dirt",
		{crumbly=3,soil=1},
		{"default_dirt.png"},
		"Dirt Stair",
		"Dirt Slab",
		"Dirt Corner",
		default.node_sound_dirt_defaults())

stairs.register_stair_and_slab_and_corner("gravel", "default:gravel",
		{crumbly=2, falling_node=1},
		{"default_gravel.png"},
		"Gravel Stair",
		"Gravel Slab",
		"Gravel Corner",
		default.node_sound_dirt_defaults({
		footstep = {name="default_gravel_footstep", gain=0.5},
		dug = {name="default_gravel_footstep", gain=1.0},
	}))

stairs.register_stair_and_slab_and_corner("sandstonebrick", "default:sandstonebrick",
		{cracky=2},
		{"default_sandstone_brick.png"},
		"Sandstone Brick Stair",
		"Sandstone Brick Slab",
		"Sandstone Brick Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("tree", "default:tree",
		{choppy=2,oddly_breakable_by_hand=1,flammable=2},
		{"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
		"Tree Stair",
		"Tree Slab",
		"Tree Corner",
		default.node_sound_wood_defaults())

stairs.register_stair_and_slab_and_corner("jungletree", "default:jungletree",
		{choppy=2,oddly_breakable_by_hand=1,flammable=2},
		{"default_jungletree_top.png", "default_jungletree_top.png", "default_jungletree.png"},
		"Jungle Tree Stair",
		"Jungle Tree Slab",
		"Jungle Tree Corner",
		default.node_sound_wood_defaults())

stairs.register_stair_and_slab_and_corner("glass", "default:glass",
		{cracky=3,oddly_breakable_by_hand=3},
		{"default_glass.png"},
		"Glass Stair",
		"Glass Slab",
		"Glass Corner",
		default.node_sound_glass_defaults())

stairs.register_stair_and_slab_and_corner("mossycobble", "default:mossycobble",
		{cracky=3},
		{"default_mossycobble.png"},
		"Mossy Cobblestone Stair",
		"Mossy Cobblestone Slab",
		"Mossy Cobblestone Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("coalblock", "default:coalblock",
		{cracky=3},
		{"default_coal_block.png"},
		"Coal Block Stair",
		"Coal Block Slab",
		"Coal Block Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("steelblock", "default:steelblock",
		{cracky=1,level=2},
		{"default_steel_block.png"},
		"Steel Block Stair",
		"Steel Block Slab",
		"Steel Block Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("copperblock", "default:copperblock",
		{cracky=1,level=2},
		{"default_copper_block.png"},
		"Copper Block Stair",
		"Copper Block Slab",
		"Copper Block Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("bronzeblock", "default:bronzeblock",
		{cracky=1,level=2},
		{"default_bronze_block.png"},
		"Bronze Block Stair",
		"Bronze Block Slab",
		"Bronze Block Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("mese", "default:mese",
		{cracky=1,level=2},
		{"default_mese_block.png"},
		"Mese Block Stair",
		"Mese Block Slab",
		"Mese Block Corner",
		default.node_sound_stone_defaults())
minetest.register_alias("default:mese_block", "default:mese")

stairs.register_stair_and_slab_and_corner("goldblock", "default:goldblock",
		{cracky=1},
		{"default_gold_block.png"},
		"Gold Block Stair",
		"Gold Block Slab",
		"Gold Block Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("diamondblock", "default:diamondblock",
		{cracky=1,level=3},
		{"default_diamond_block.png"},
		"Diamond Stair",
		"Diamond Slab",
		"Diamond Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("obsidian_glass", "default:obsidian_glass",
		{cracky=3,oddly_breakable_by_hand=3},
		{"default_obsidian_glass.png"},
		"Obsidian Glass Stair",
		"Obsidian Glass Slab",
		"Obsidian Glass Corner",
		default.node_sound_glass_defaults())

stairs.register_stair_and_slab_and_corner("nyancat_rainbow", "default:nyancat_rainbow",
		{cracky=2},
		{"default_nc_rb.png"},
		"Nyan Cat Rainbow Stair",
		"Nyan Cat Rainbow Slab",
		"Nyan Cat Rainbow Corner",
		default.node_sound_stone_defaults())

stairs.register_stair_and_slab_and_corner("ice", "default:ice",
		{cracky=3, melts=1},
		{"default_ice.png"},
		"Ice Stair",
		"Ice Slab",
		"Ice Corner",
		default.node_sound_glass_defaults())

stairs.register_stair_and_slab_and_corner("snowblock", "default:snowblock",
		{crumbly=3, melts=1},
		{"default_snow.png"},
		"Snow Block Stair",
		"Snow Block Slab",
		"Snow Block Corner",
		default.node_sound_dirt_defaults({
		footstep = {name="default_snow_footstep", gain=0.25},
		dug = {name="default_snow_footstep", gain=0.75},
	}))
