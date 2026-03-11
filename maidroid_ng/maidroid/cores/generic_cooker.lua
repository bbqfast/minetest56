
-- Copyleft (Я) 2026 mazes-style extension
-- Maidroid core: generic cooker (rice + furnace)
------------------------------------------------------------

local S = maidroid.translator

-- Import sleep module
dofile(minetest.get_modpath("maidroid") .. "/sleep.lua")

-- Import craft module
dofile(minetest.get_modpath("maidroid") .. "/craft.lua")

local on_start, on_pause, on_resume, on_stop, on_step, is_tool
local task, to_action, to_wander, act
local get_all_required_craft_items

local wander = maidroid.cores.wander
local states = maidroid.states
local timers = maidroid.timers
local lf = maidroid.lf
local chest_reach_dist = 2.5

-- Treat chests as blocking for generic cooker movement, similar to fences,
-- so the maidroid does not walk past chests while pathing or wandering.
local function is_fence_or_chest(name)
	if maidroid.helpers.is_fence(name) then
		return true
	end
    return false
	-- return name == "default:chest" or name == "default:chest_locked"
end

-- Load cooker items configuration
local cooker_items = dofile(maidroid.modpath .. "/cores/cooker_items.lua")
local all_cookable_items = cooker_items.all_cookable_items
local all_farming_outputs = cooker_items.all_farming_outputs
local all_take_item_names = cooker_items.all_take_item_names
local all_furnace_inputs = cooker_items.all_furnace_inputs
local is_cookable_tool = cooker_items.is_cookable_tool

-- Metrics table to track items taken from chests
local chest_taken_metrics = {}
local action_taken_metrics = {}
local craft_metrics = {}
local furnace_taken_metrics = {}
-- Timer for periodic metrics logging
local metrics_log_timer = 0
local metrics_log_interval = 35 -- seconds

local all_cookable_items_short = {
    { item_name = "farming:seed_rice",  count = 5 },
    { item_name = "default:sand",       count = 5 },
    { item_name = "farming:rice_flour", count = 5 },
}

local all_take_items = {
	["farming:seed_rice"] = 5,
	["farming:wheat"] = 5,
	["farming:rice_flour"] = 5,
	["default:papyrus"] = 5,
}

-- ,,i1
local craft_outputs = {
    "farming:flour",
    "farming:rice_flour",
    "farming:bread_slice",
    "farming:rhubarb_pie",
    "farming:garlic_bread"
}

-- Configurable distance threshold for teleporting back to activation position
-- This can be set via minetest.settings or externally
local max_distance_from_activation = tonumber(minetest.settings:get("maidroid.generic_cooker.max_distance_from_activation")) or 10

-- Function to get the current distance threshold (allows external modification)
local function get_max_distance_from_activation()
	-- Check if settings value has been updated
	local settings_value = tonumber(minetest.settings:get("maidroid.generic_cooker.max_distance_from_activation"))
	if settings_value then
		max_distance_from_activation = settings_value
	end
	return maidroid.cores.generic_cooker.max_distance_from_activation or max_distance_from_activation
end

-- Function to set the distance threshold
local function set_max_distance_from_activation(distance)
	if distance and distance > 0 and distance <= 100 then
		max_distance_from_activation = distance
		maidroid.cores.generic_cooker.max_distance_from_activation = distance
		-- Also save to minetest settings for persistence
		minetest.settings:set("maidroid.generic_cooker.max_distance_from_activation", tostring(distance))
		return true
	end
	return false
end

-- Function to log chest taken metrics
local function log_chest_taken_metrics()
	-- Log chest taken metrics
    lf("chest_metrics", "**************** Metrics ****************")
	if next(chest_taken_metrics) == nil then
		lf("chest_metrics", "No items taken from chests yet.")
	else
		lf("chest_metrics", "**************** Chest Taken ")
		for item_name, count in pairs(chest_taken_metrics) do
			lf("chest_metrics", string.format("%s: %d", item_name, count))
		end
	end
	
	-- Log action taken metrics
	if next(action_taken_metrics) == nil then
		lf("action_metrics", "No actions taken yet.")
	else
		local action_parts = {}
		for action_name, count in pairs(action_taken_metrics) do
			table.insert(action_parts, string.format("%s:%d", action_name, count))
		end
		lf("action_metrics", "Action Metrics: " .. table.concat(action_parts, ", "))
	end
	
	-- Log craft metrics
	if next(craft_metrics) == nil then
		lf("craft_metrics", "No items crafted yet.")
	else
		local craft_parts = {}
		for item_name, count in pairs(craft_metrics) do
			table.insert(craft_parts, string.format("%s:%d", item_name, count))
		end
		lf("craft_metrics", "Craft Metrics: " .. table.concat(craft_parts, ", "))
	end
	
	-- Log furnace taken metrics
	if next(furnace_taken_metrics) == nil then
		lf("furnace_metrics", "No items taken from furnaces yet.")
	else
		local furnace_parts = {}
		for item_name, count in pairs(furnace_taken_metrics) do
			table.insert(furnace_parts, string.format("%s:%d", item_name, count))
		end
		lf("furnace_metrics", "Furnace Taken Metrics: " .. table.concat(furnace_parts, ", "))
	end
    lf("chest_metrics", "**************** End Metrics ****************")

end

-- Expose the function globally
-- maidroid.get_all_cookable_furnace_inputs = get_all_cookable_furnace_inputs
maidroid.get_chest_taken_metrics = function() return chest_taken_metrics end

-- Expose the take items function globally
-- Returns hash map {item_name: quantity}
maidroid.get_all_take_items = function(droid)
    if not droid then
        return all_take_items
    end
    return get_all_take_items(droid)
end

-- Create the cores table if it doesn't exist
if not maidroid.cores then
	maidroid.cores = {}
end
if not maidroid.cores.generic_cooker then
	maidroid.cores.generic_cooker = {}
end

-- Custom functions will be added after core registration to prevent overwriting

-- Encapsulated target info for a single chest interaction
local GenericCookerTarget = {}
GenericCookerTarget.__index = GenericCookerTarget




local function lfv(verbose, ...)
	if verbose then
		lf(...)
	end
end

local function log_inventory(droid, label)
	if not droid or not droid.get_inventory then
		return
	end
	local inv = droid:get_inventory()
	if not inv then
		return
	end
	local list = inv:get_list("main")
	if not list then
		return
	end
	label = label or "main"
	lf("generic_cooker", "Inventory (" .. label .. "):")
	for i, stack in ipairs(list) do
		if not stack:is_empty() then
			lf("generic_cooker", "  slot " .. i .. ": " .. stack:to_string())
		end
	end
end

local function lfv(verbose, ...)
	if verbose then
		lf(...)
	end
end

-- Crafting functions moved to craft.lua



-- craft_outputs = all_farming_outputs

local furnace_inputs = { "farming:flour_multigrain", "farming:bread_slice", "group:food_corn", "group:food_sugar", "bucket:bucket_water", "farming:pumpkin_dough", "farming:rice_flour",
    "farming:tofu", "farming:flour", "farming:cocoa_beans_raw", "default:papyrus", "group:food_potato", "farming:seed_sunflower" }

function GenericCookerTarget.new(pos, item_name, max_take, take_items)
	return setmetatable({
		pos = pos,
		item_name = item_name,
		max_take = max_take,
		-- Optional list of specs for chest interactions:
		--   { item_name = "name", quantity = N }
		-- When present, take_item_from_chest will pick a random spec.
		take_items = take_items,
	}, GenericCookerTarget)
end

maidroid.register_tool_rotation("maidroid:spatula", vector.new(-75, -90, 90))
-- maidroid.register_tool_rotation("maidroid:spatula", vector.new(-75,45,-45))

on_resume = function(droid)
	wander.on_resume(droid)
end

on_stop = function(droid)
	wander.on_stop(droid)
end

on_pause = function(droid)
	wander.on_pause(droid)
end

to_action = function(droid)
	droid:halt()
	droid.timers.action = 0
	droid.state = states.ACT
	-- Show a cooking tool instead of rice while acting at the chest
	droid:set_tool("maidroid:spatula")
	droid:set_animation(maidroid.animation.MINE)
end

-- ,,wander
to_wander = function(droid, from_caller)
	-- Clear any current job-specific intent and delegate to the wander core,
	-- similar to waffler.lua's to_wander behavior.
	droid.destination = nil
	droid.action = nil
	droid:set_tool("maidroid:spatula")
    lf("generic_cooker:to_wander", "setting state to WANDER")
	wander.to_wander(droid, from_caller or "generic_cooker:to_wander")
end

is_tool = function(stack)
	return stack:get_name() == "default:furnace"
end


-- ,,ch2,,chest
local function take_item_from_chest(droid, chest_pos, take_items)
    lf("generic_cooker", "take_item_from_chest: " .. minetest.pos_to_string(chest_pos) .. " total take items=" .. dump(take_items))
	
	-- Update action_taken_metrics
	action_taken_metrics["chest_taken"] = (action_taken_metrics["chest_taken"] or 0) + 1
	lf("action_metrics", "chest_taken called: " .. action_taken_metrics["chest_taken"])
	
	if not chest_pos then
        lf("generic_cooker", "take_item_from_chest: no chest_pos")
		return false
	end

	lf("generic_cooker", "checking chest at " .. minetest.pos_to_string(chest_pos))
	local meta = minetest.get_meta(chest_pos)
	local owner = meta:get_string("owner")
	if owner and owner ~= "" and owner ~= droid.owner then
		lf("generic_cooker", "take_item_from_chest: chest owner does not match")
		return false
	end

	local chest_inv = meta:get_inventory()
	local inv = droid:get_inventory()

	if type(take_items) ~= "table" or next(take_items) == nil then
        lf("generic_cooker", "take_item_from_chest: no take_items")
		return false
	end

	-- Log all items in the chest for debugging
	local chest_list = chest_inv:get_list("main")
	if chest_list then
		lf("generic_cooker", "take_item_from_chest: chest contents:")
		for i, stack in ipairs(chest_list) do
			if not stack:is_empty() then
				lf("generic_cooker", "  slot " .. i .. ": " .. stack:to_string())
			end
		end
	end

	-- Build a list of candidate specs by checking chest contents once
	local candidates = {}
	
	if chest_list then
		for i, stack in ipairs(chest_list) do
			if not stack:is_empty() then
				local item_name = stack:get_name()
				
				-- Direct lookup using the simplified hash map {item_name: quantity}
				local want_count = take_items[item_name]
				if want_count then
					local available_count = stack:get_count()
					if available_count >= want_count then
						candidates[#candidates + 1] = { item_name = item_name, quantity = want_count }
					end
				end
				
				-- Check for cookable tools
				if is_cookable_tool(item_name) then
					local tool_spec = { item_name = item_name, quantity = 1 }
					candidates[#candidates + 1] = tool_spec
					lf("generic_cooker", "take_item_from_chest: found cookable tool " .. item_name)
				end
			end
		end
	end

	if #candidates == 0 then
        lf("generic_cooker", "take_item_from_chest: no candidates")
		return false
	end

	local spec = candidates[math.random(#candidates)]
	local item_name = spec.item_name
	local take_count = spec.quantity or 1
	local wanted_stack = item_name .. " " .. tostring(take_count)

	if not inv:room_for_item("main", wanted_stack) then
        lf("generic_cooker", "take_item_from_chest: no room for " .. wanted_stack)
		return false
	end

	local stack = chest_inv:remove_item("main", wanted_stack)
	if stack:is_empty() then
        lf("generic_cooker", "take_item_from_chest: no stack")
		return false
	end

	lf("generic_cooker", "took " .. tostring(stack:get_count()) .. " " .. item_name .. " from chest")
	inv:add_item("main", stack)
	
	-- Update chest_taken_metrics
	chest_taken_metrics[item_name] = (chest_taken_metrics[item_name] or 0) + stack:get_count()
	lf("generic_cooker", "chest_taken_metrics updated: " .. item_name .. " = " .. chest_taken_metrics[item_name])
	
	return true
end

-- ,,ch1,chest
local function try_get_item_from_nearby_chest(droid, pos, take_items)
    lf("generic_cooker", "try_get_item_from_nearby_chest: pos=" .. minetest.pos_to_string(pos))
    local dist = 5
	local chest_pos = minetest.find_node_near(pos, dist, {"default:chest", "default:chest_locked"})
	if not chest_pos then
        lf("generic_cooker", "try_get_item_from_nearby_chest: no chest found")
		return false
	end

    droid._chest_pos = chest_pos
	-- local distance = vector.distance(pos, chest_pos)
	-- if distance <= chest_reach_dist then
	-- 	-- Already close enough: perform a short ACT with mine animation while taking from chest
	-- 	local target = vector.add(chest_pos, {x=0, y=1, z=0})
	-- 	droid._generic_cooker_target = GenericCookerTarget.new(chest_pos, nil, nil, take_items)
	-- 	droid.destination = target
	-- 	droid.action = "generic_cooker_take_item"
	-- 	to_action(droid)
	local target = vector.add(chest_pos, {x=0, y=1, z=0})
    local path = minetest.find_path(pos, target, dist + 1, 2, 2, "A*_noprefetch")

    local path, target_pos = maidroid.get_shortest_path(chest_pos, pos)

	if not path then
        lf("generic_cooker", "try_get_item_from_nearby_chest: no path found")
		return false
	end

    droid._chest_front = target_pos

	-- droid._generic_cooker_target = GenericCookerTarget.new(chest_pos, nil, nil, nil)
	-- Show bucket while walking to chest, similar to farming dump logic
	droid:set_tool("bucket:bucket_empty")
    lf("generic_cooker", "try_get_item_from_nearby_chest: path found")
	-- maidroid.cores.path.to_follow_path(droid, path, target, to_action, "generic_cooker_take_item")
	maidroid.cores.path.to_follow_path(droid, path, target_pos, to_action, "generic_cooker_take_item")
	return true
end

-- ,,furnace
-- NOTE: here 'pos' is expected to be the actual furnace position already
-- (normal or active). We no longer search again, to avoid failing when
-- the furnace is burning.
--
-- items: array of specs, each spec may be
--   { item_name = "name", count = N }
--   { name = "name", count = N }
--   { "name", N }
-- The first spec for which the maidroid has matching items and the furnace
-- has room will be fed into the correct list (fuel/src).
-- ,,fg3
local function feed_furnace_from_inventory_generic(droid, pos, items)
    lf("generic_cooker", "feed_furnace_from_inventory_generic: items=" .. dump(items))
	if not pos then
		return false
	end

	if type(items) ~= "table" then
        lf("generic_cooker:feed_furnace_from_inventory_generic", "items=" .. dump(items))
		return false
	end

	local node = minetest.get_node(pos)
	if node.name ~= "default:furnace" and node.name ~= "default:furnace_active" then
	    local furnace_pos = minetest.find_node_near(pos, 5, "default:furnace")
	    if not furnace_pos then
			lf("generic_cooker:feed_furnace_from_inventory_generic", "pos is not a furnace: " .. node.name .. " at " .. minetest.pos_to_string(pos))
			return false
		end
	    pos = furnace_pos
	end

	local meta = minetest.get_meta(pos)
	local finv = meta:get_inventory()
	local inv = droid:get_inventory()

	for _, spec in ipairs(items) do
		local name, count
		if type(spec) == "table" then
			name = spec.item_name or spec.name or spec[1]
			count = spec.count or spec[2] or 1
		elseif type(spec) == "string" then
			name = spec
			count = 99
		end
		if name and count and count > 0 then
			local listname = (name == "default:coal_lump") and "fuel" or "src"
			-- Check if maidroid has more than 5 of this item type
			local current_stack = inv:contains_item("main", name .. " 5")
			if current_stack then
				-- Try to remove up to 'count' items; if the player has fewer,
				-- remove and use whatever is available.
				local want = name .. " " .. tostring(count)
				local stack = inv:remove_item("main", want)
				if not stack:is_empty() then
					if not finv:room_for_item(listname, stack) then
						-- Not enough room; put items back and try next spec.
						inv:add_item("main", stack)
					else
						finv:add_item(listname, stack)
						lf("generic_cooker", "feed_furnace_from_inventory_generic: added " .. tostring(stack:get_count()) .. " " .. name .. " to " .. listname .. " at " .. minetest.pos_to_string(pos))
						return true
					end
				end
			else
				-- lf("generic_cooker", "feed_furnace_from_inventory_generic: skipping " .. name .. " - only have 5 or fewer")
			end
		end
	end

	lf("generic_cooker:feed_furnace_from_inventory_generic", "no matching items or no room in furnace")
	return false
end

-- More efficient version: iterate through player's inventory instead of input items
-- This avoids unnecessary iterations when maidroid has limited items
-- ,,fg4
local function feed_furnace_from_inventory_generic2(droid, pos, items)
    lf("generic_cooker", "feed_furnace_from_inventory_generic2: items=" .. dump(items))
	if not pos then
		return false
	end

	if type(items) ~= "table" then
		lf("ERROR generic_cooker:feed_furnace_from_inventory_generic", "ERROR items must be a table of specs")
        
		return false
	end

	local node = minetest.get_node(pos)
	if node.name ~= "default:furnace" and node.name ~= "default:furnace_active" then
	    local furnace_pos = minetest.find_node_near(pos, 5, "default:furnace")
	    if not furnace_pos then
			lf("generic_cooker:feed_furnace_from_inventory_generic2", "pos is not a furnace: " .. node.name .. " at " .. minetest.pos_to_string(pos))
			return false
		end
	    pos = furnace_pos
	end

	local meta = minetest.get_meta(pos)
	local finv = meta:get_inventory()
	local inv = droid:get_inventory()
	
	-- Create a lookup table for desired items for O(1) access
	local desired_items = {}
	for _, spec in ipairs(items) do
		local name, count
		if type(spec) == "table" then
			name = spec.item_name or spec.name or spec[1]
			count = spec.count or spec[2] or 1
		elseif type(spec) == "string" then
			name = spec
			count = 99
		end
		if name and count and count > 0 then
			desired_items[name] = count
		end
	end
	
	-- Get maidroid's inventory and iterate through it
	local main_list = inv:get_list("main")
	if not main_list then
		lf("generic_cooker:feed_furnace_from_inventory_generic2", "no main inventory list")
		return false
	end
	
	-- Iterate through each slot in maidroid's inventory
	for _, stack in ipairs(main_list) do
		if not stack:is_empty() then
			local item_name = stack:get_name()
			local available_count = stack:get_count()
			
			-- Check if this item is in our desired items list or is a cookable tool
			local desired_count = desired_items[item_name]
			local is_tool = is_cookable_tool(item_name)
            -- lf("generic_cooker", "ISTOOL feed_furnace_from_inventory_generic2: item_name=" .. item_name .. " desired_count=" .. tostring(desired_count) .. " available_count=" .. tostring(available_count) .. " is_tool=" .. tostring(is_tool))
			if (desired_count and available_count > 5) or is_tool then
				local listname = (item_name == "default:coal_lump") and "fuel" or "src"
				
				-- Calculate how many to take
				local take_count
				if is_tool then
					-- For tools, take all available (but keep 1 if possible)
					take_count = available_count
				else
					-- For desired items, use existing logic
					take_count = math.min(desired_count, available_count - 5)
				end
				
				if take_count > 0 then
					local want = item_name .. " " .. tostring(take_count)
					
					-- Try to remove the items
					local removed_stack = inv:remove_item("main", want)
					if not removed_stack:is_empty() then
						if not finv:room_for_item(listname, removed_stack) then
							-- Not enough room; put items back
							inv:add_item("main", removed_stack)
						else
							finv:add_item(listname, removed_stack)
							lf("generic_cooker", "feed_furnace_from_inventory_generic2: added " .. tostring(removed_stack:get_count()) .. " " .. item_name .. " to " .. listname .. " at " .. minetest.pos_to_string(pos))
							return true
						end
					end
				end
			end
		end
	end

	lf("generic_cooker:feed_furnace_from_inventory_generic2", "no matching items or no room in furnace")
	return false
end

local function add_coal_fuel_if_needed(droid, pos, finv)
	-- If fuel is less than 20, and the droid has at least 5 coal, try to add 5 coal as fuel.
	local fuel_list = finv:get_list("fuel") or {}
	local fuel_count = 0
	for _, stack in ipairs(fuel_list) do
		if not stack:is_empty() then
			fuel_count = fuel_count + stack:get_count()
		end
	end
	if fuel_count < 20 then
		local inv = droid:get_inventory()
		if inv:contains_item("main", "default:coal_lump 5")
			and finv:room_for_item("fuel", "default:coal_lump 5") then
			local coal_stack = inv:remove_item("main", "default:coal_lump 5")
			if not coal_stack:is_empty() then
				finv:add_item("fuel", coal_stack)
				lf("generic_cooker:feed_get_from_furnace__generic",
					"added 5 coal to furnace fuel at " .. minetest.pos_to_string(pos) .. " (fuel was " .. fuel_count .. ")")
			end
		end
	end
end

local function collect_finished_items_from_furnace(droid, pos, finv)
	-- First, try to collect finished items from dst if any.
	local dst = finv:get_list("dst") or {}
	local collected = {}
	for idx, stack in ipairs(dst) do
		if not stack:is_empty() then
			collected[#collected + 1] = stack
			dst[idx] = ItemStack("")
		end
	end
	if #collected > 0 then
		finv:set_list("dst", dst)
		droid:add_items_to_main(collected)
		
		-- Update furnace_taken_metrics
		for _, stack in ipairs(collected) do
			local item_name = stack:get_name()			
			furnace_taken_metrics[item_name] = (furnace_taken_metrics[item_name] or 0) + stack:get_count()
			lf("furnace_metrics", "furnace_taken_metrics updated: " .. item_name .. " = " .. furnace_taken_metrics[item_name])
		end
		
		lf("generic_cooker:feed_get_from_furnace__generic",
			"collected finished items from furnace at " .. minetest.pos_to_string(pos))
            return true
        end
        return false
    end
    
    -- Combined helper: if furnace is active, do nothing;
    -- if inactive and has finished items, collect them;
    -- otherwise, feed the specified item into the furnace.
    -- ,,fg2
local function feed_get_from_furnace__generic(droid, pos)
    lf("generic_cooker:feed_get_from_furnace__generic", "pos=" .. minetest.pos_to_string(pos))
	
	-- Update action_taken_metrics
	action_taken_metrics["furnace_action"] = (action_taken_metrics["furnace_action"] or 0) + 1
	lf("action_metrics", "furnace_action called: " .. action_taken_metrics["furnace_action"])
	
	if not pos then
        lf("generic_cooker:feed_get_from_furnace__generic", "no pos provided")
		return false
	end

	-- Resolve to an actual furnace node near pos, if needed
	local node = minetest.get_node(pos)
	if node.name ~= "default:furnace" and node.name ~= "default:furnace_active" then
		local furnace_pos = minetest.find_node_near(pos, 5, "default:furnace")
		if not furnace_pos then
			lf("generic_cooker:feed_get_from_furnace__generic",
				"no furnace found near pos=" .. minetest.pos_to_string(pos))
			return false
		end
		pos = furnace_pos
		node = minetest.get_node(pos)
	end

	-- If furnace is active, do nothing.
	if node and node.name == "default:furnace_active" then
		lf("generic_cooker:feed_get_from_furnace__generic",
			"furnace active at " .. minetest.pos_to_string(pos) .. ", skipping")
		return false
	end

	local meta = minetest.get_meta(pos)
	local finv = meta and meta:get_inventory()
    
    collect_finished_items_from_furnace(droid, pos, finv)
    
    add_coal_fuel_if_needed(droid, pos, finv)

	-- return feed_furnace_from_inventory_generic(droid, pos, all_cookable_items)
	-- return feed_furnace_from_inventory_generic(droid, pos, all_furnace_inputs)
	return feed_furnace_from_inventory_generic2(droid, pos, droid.cooklist)
end

-- ,,fg1,,fur
-- Pathfinding helper: walk to a nearby furnace and then perform the
-- combined feed/get behavior defined in feed_get_from_furnace__generic.
local function try_feed_get_from_furnace__generic(droid, pos)
    local find_dist = 12
	local furnace_pos = minetest.find_node_near(pos, find_dist, "default:furnace")
	if not furnace_pos then
		lf("generic_cooker:try_feed_get_from_furnace__generic", "furnace not found: pos=" .. minetest.pos_to_string(pos))
		return false
	end

	local target = vector.add(furnace_pos, {x=0, y=1, z=0})
	local rounded_pos = vector.round(pos)
	local path = minetest.find_path(rounded_pos, target, find_dist+1, 2, 2, "A*_noprefetch")
	if not path then
		lf("generic_cooker:try_feed_get_from_furnace__generic", "path not found")
		return false
	end

	droid._furnace_target = GenericCookerTarget.new(furnace_pos, nil, nil)
	droid:set_tool("maidroid:spatula")
	maidroid.cores.path.to_follow_path(droid, path, target, to_action, "generic_cooker_feed_get")
	return true
end

local function feed_furnace_from_inventory(droid, pos)
	local furnace_pos = minetest.find_node_near(pos, 5, "default:furnace")
	if not furnace_pos then
		return
	end

	local node = minetest.get_node(furnace_pos)
	local meta = minetest.get_meta(furnace_pos)
	local finv = meta:get_inventory()
	local inv = droid:get_inventory()

	if node and node.name ~= "default:furnace_active" then
		local dst = finv:get_list("dst") or {}
		local collected = {}
		for idx, stack in ipairs(dst) do
			if not stack:is_empty() then
				collected[#collected + 1] = stack
				dst[idx] = ItemStack("")
			end
		end
		if #collected > 0 then
			finv:set_list("dst", dst)
			droid:add_items_to_main(collected)
			
			-- Update furnace_taken_metrics
			for _, stack in ipairs(collected) do
				local item_name = stack:get_name()
				furnace_taken_metrics[item_name] = (furnace_taken_metrics[item_name] or 0) + stack:get_count()
				lf("furnace_metrics", "furnace_taken_metrics updated: " .. item_name .. " = " .. furnace_taken_metrics[item_name])
			end
			
			lf("generic_cooker", "collected finished items from furnace at " .. minetest.pos_to_string(furnace_pos))
		end
	end

	if inv:contains_item("main", "default:coal_lump 1") and finv:room_for_item("fuel", "default:coal_lump 1") then
		local coal_stack = inv:remove_item("main", "default:coal_lump 1")
		if not coal_stack:is_empty() then
			finv:add_item("fuel", coal_stack)
			lf("generic_cooker", "added coal to furnace at " .. minetest.pos_to_string(furnace_pos))
		end
	end

	if inv:contains_item("main", "farming:seed_rice 1") and finv:room_for_item("src", "farming:seed_rice 1") then
		local src_list = finv:get_list("src") or {}
		local current = 0
		for _, stack in ipairs(src_list) do
			if not stack:is_empty() then
				current = current + stack:get_count()
			end
		end
		if current < 5 then
			local need = 5 - current
			local take_spec = "farming:seed_rice " .. tostring(need)
			local rice_stack = inv:remove_item("main", take_spec)
			if not rice_stack:is_empty() then
				finv:add_item("src", rice_stack)
				lf("generic_cooker", "added seed_rice to furnace at " .. minetest.pos_to_string(furnace_pos) .. " (" .. tostring(rice_stack:get_count()) .. " seeds, total now <= 5)")
			end
		end
	end
end


local function get_replacements_for_output(output_name, verbose)
  local r = minetest.get_craft_recipe(output_name)
  if not r or not r.items then return nil, "no recipe" end

  -- Ask the engine to perform the craft so we can see what remains in the
  -- input grid (second return value). This exposes implicit replacements.
  local spec = {
    method = r.method or "normal",
    width  = r.width or 3,
    items  = r.items,
  }
  local res, decremented = minetest.get_craft_result(spec)
  lfv(verbose, "generic_cooker", "get_craft_result: spec=" .. dump(spec) .. " result=" .. dump(res) .. " decremented=" .. dump(decremented))

  -- Build a replacements list in the same shape as register_craft
  -- { { original_item, replacement_name }, ... }
  local replacements = {}
  if decremented and decremented.items then
    for idx, after in ipairs(decremented.items) do
      local before = r.items[idx]
      if before and before ~= "" and after and not after:is_empty() then
        local new_name = after:get_name()
        if new_name ~= "" then
          replacements[#replacements + 1] = { before, new_name }
          lfv(verbose, "generic_cooker", string.format(
            "get_replacements_for_recipe: before=%s -> replacement=%s",
            before, new_name))
        end
      end
    end
  end

  if #replacements == 0 then
    lfv(verbose, "generic_cooker", "get_replacements_for_recipe: no replacements detected")
    local result_str = nil
    if res and res.item and not res.item:is_empty() then
      result_str = res.item:to_string()
    end
    return nil, result_str
  end

  local result_str = nil
  if res and res.item and not res.item:is_empty() then
    result_str = res.item:to_string()
  end
  return replacements, result_str
end

-- ,,take all ingredient
function get_combined_take_items(droid)
    return all_furnace_inputs
end

-- combine short list of take items with the ingredients from player selected recipe
-- ,,combine
function get_combined_take_items2(droid, my_take_items, cooklist)
    local take_lookup = {} -- Return hash map directly: {item_name: quantity}
    
    -- Copy existing my_take_items (already a hash map)
    if my_take_items and type(my_take_items) == "table" then
        for item_name, quantity in pairs(my_take_items) do
            take_lookup[item_name] = quantity
        end
        
        local count = 0
        for _ in pairs(take_lookup) do count = count + 1 end
        lf("generic_cooker:get_combined_take_items2", "copied " .. count .. " items from my_take_items")
    else
        lf("generic_cooker:get_combined_take_items2", "no my_take_items provided")
    end
    
    -- Add ingredients from desired_craft_outputs if available
    if droid and type(droid.desired_craft_outputs) == "table" then
        lf("generic_cooker:get_combined_take_items2", "droid.desired_craft_outputs=" .. dump(droid.desired_craft_outputs))
        local required_items = maidroid.get_all_required_craft_items(droid.desired_craft_outputs, false)
        lf("generic_cooker:get_combined_take_items2", "found " .. #required_items .. " required items from desired_craft_outputs")
        
        -- Add required items to take_lookup with default quantity of 5
        for _, item_name in ipairs(required_items) do
            -- Check if this is a group item
            if string.find(item_name, "group:", 1, true) then
                -- This is a group item, get actual items from the group
                local group_items = maidroid.get_items_in_group(item_name)
                lf("generic_cooker:get_combined_take_items2", " found group item " .. item_name .. " with " .. #group_items .. " items")
                
                -- Add each item from the group to take_lookup
                for _, group_item in ipairs(group_items) do
                    if not take_lookup[group_item] then
                        take_lookup[group_item] = 5
                        lf("generic_cooker:get_combined_take_items", " added group item " .. group_item .. " with quantity 5")
                    end
                end
            else
                -- This is a regular item, add it directly
                if not take_lookup[item_name] then
                    take_lookup[item_name] = 5
                    lf("generic_cooker:get_combined_take_items", " added ingredient " .. item_name .. " with quantity 5")
                end
            end
        end
    end
    
    -- Add items from cooklist if available
    if cooklist and type(cooklist) == "table" then
        lf("generic_cooker:get_combined_take_items2", "adding items from cooklist")
        local cooklist_count = 0
        
        for _, cook_item in ipairs(cooklist) do
            if cook_item.item_name and cook_item.count then
                -- Add cooklist item to take_lookup
                if not take_lookup[cook_item.item_name] then
                    take_lookup[cook_item.item_name] = cook_item.count
                    cooklist_count = cooklist_count + 1
                    lf("generic_cooker:get_combined_take_items2", " added cooklist item " .. cook_item.item_name .. " with quantity " .. cook_item.count)
                else
                    lf("generic_cooker:get_combined_take_items2", " cooklist item " .. cook_item.item_name .. " already exists in take_lookup")
                end
            end
        end
        
        lf("generic_cooker:get_combined_take_items2", "added " .. cooklist_count .. " items from cooklist")
    else
        lf("generic_cooker:get_combined_take_items2", "no cooklist provided")
    end
    
    return take_lookup
end

-- Consumes a fixed number of rice items and adds one rice flour if possible.
local function craft_rice_flour(droid)
	local inv = droid and droid:get_inventory()
	if not inv then
		return false
	end -- if not inv

	-- Get the actual craft recipe for farming:rice_flour from registered crafts.
	local recipes = maidroid.get_craft_requirements_from_registered("farming:rice_flour")
	if not recipes or #recipes == 0 then
		lf("generic_cooker", "craft_rice_flour: no craft recipe found for farming:rice_flour")
		return false
	end -- if not all_consumables

	-- For now, use the first available recipe tuple { consumables, replacements }.
	local first = recipes[1]
	local all_consumables = first and first[1]
	local replacements = first and first[2]
	if not all_consumables then
		lf("generic_cooker", "craft_rice_flour: no consumables in first recipe for farming:rice_flour")
		return false
	end

	-- Derive tool set from replacements and groups, then split consumables/tools.
	local tool_names = {}
	for _, rep in ipairs(replacements or {}) do
		local before = rep[1]
		local after = rep[2]
		if type(before) == "string" and before ~= "" then
			tool_names[before] = true
		end
		if type(after) == "string" and after ~= "" and not after:find("^group:") then
			tool_names[after] = true
		end
	end

	local consumables = {}
	for name, count in pairs(all_consumables) do
        consumables[name] = count
	end

	local output_stack = ItemStack("farming:rice_flour")

	-- Ensure there is room for the result before consuming inputs.
	if not inv:room_for_item("main", output_stack) then
		return false
	end -- if not room_for_item

	-- Check we have all required consumable ingredients.
	for name, count in pairs(consumables or {}) do
		local needed = string.format("%s %d", name, count)
        lf("generic_cooker", "craft_rice_flour: checking for " .. needed)
		if not inv:contains_item("main", needed) then
            lf("generic_cooker", "craft_rice_flour: missing " .. needed)
			return false
		end
	end

	-- Remove ingredients, keeping a list so we can roll back on failure.
	local removed_items = {}
	for name, count in pairs(consumables or {}) do
		local needed = string.format("%s %d", name, count)
		local removed = inv:remove_item("main", needed)
		local got = removed:get_count()
		if removed:is_empty() or got < count then
			-- Roll back anything we already removed.
			for _, r in ipairs(removed_items) do
				if not r:is_empty() then
					inv:add_item("main", r)
				end
			end -- for removed_items rollback
			if not removed:is_empty() then
				inv:add_item("main", removed)
			end
			return false
		end -- if removed empty or insufficient
		removed_items[#removed_items + 1] = removed
	end -- for consumables removal

	-- Add replacement items (tools that are returned after crafting) back to inventory.
	for _, rep in ipairs(replacements or {}) do
		local replacement_name = rep[2]
		if replacement_name and replacement_name ~= "" then
			local replacement_stack = ItemStack(replacement_name)
			inv:add_item("main", replacement_stack)
			lf("generic_cooker", "craft_rice_flour: returned replacement " .. replacement_stack:to_string())
		end -- if replacement_name
	end -- for replacements

	-- Add the crafted rice flour.
	inv:add_item("main", output_stack)
	lf("generic_cooker", "craft_rice_flour: crafted " .. output_stack:to_string())
	
	-- Update craft_metrics
	local crafted_name = output_stack:get_name()
	craft_metrics[crafted_name] = (craft_metrics[crafted_name] or 0) + output_stack:get_count()
	lf("craft_metrics", "crafted " .. output_stack:to_string() .. " total: " .. craft_metrics[crafted_name])
	
	return true
end -- function craft_rice_flour

-- Sleep functionality now handled by maidroid.sleep module

-- Sleep functionality now handled by maidroid.sleep module

local function test_get_craft_requirements()
    name = "farming:pasta"
	local all = maidroid.get_craft_requirements_from_registered(name, true)
	-- local all = maidroid.get_craft_requirements_from_registered("farming:rice_flour", true)
	lf("generic_cooker", ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> test_get_recipe: name=" .. name .. ", requirements=" .. dump(all))
end

-- ,,tt
local function tests()
    -- test_get_replacement()
    -- test_get_items_in_groups()
    -- test_get_craft_requirements()
    -- local cookable_inputs = get_all_cookable_furnace_inputs()
    -- lf("tests", "cookable_inputs=" .. dump(cookable_inputs).."total=" .. #cookable_inputs)
    -- lf("tests", "")

    local cookable_items = maidroid.cores.generic_cooker.get_cookable_items()
    lf("tests", "cookable_items=" .. dump(cookable_items).."total=" .. #cookable_items)
    lf("tests", "")
    error("tests")
end



-- Helper: generic craft based on craft_outputs list.
-- Iterates craft_outputs and performs the first craftable recipe in the maidroid's inventory.

-- Sleep functionality now handled by maidroid.sleep module

-- Sleep functionality now handled by maidroid.sleep module

-- ,,act

act = function(droid, dtime)
    lf("generic_cooker:act", "act: " .. minetest.pos_to_string(vector.round(droid:get_pos())) .. " action: " .. tostring(droid.action))
	if droid.timers.action < 2 then
		droid.timers.action = droid.timers.action + dtime
		return
	end

	if droid.action == "generic_cooker_take_item" then
        lf("generic_cooker:act", "generic_cooker_take_item: " .. minetest.pos_to_string(droid:get_pos()))
		-- local target = droid._generic_cooker_target
		-- if target and target.pos then

			take_item_from_chest(
				droid,
				-- target.pos,
				droid._chest_pos,
				get_combined_take_items2(droid, all_take_items, droid.cooklist)
			)
        -- else
        --     lf("generic_cooker:act", "generic_cooker_take_item: no target")
		-- end
		-- droid._generic_cooker_target = nil
	elseif droid.action == "generic_cooker_feed_get" then
        lf("generic_cooker:act", "generic_cooker_feed_get: " .. minetest.pos_to_string(droid:get_pos()))
		local target = droid._furnace_target
		if target and target.pos  then
			feed_get_from_furnace__generic(
				droid, target.pos
			)
		end
		droid._furnace_target = nil
    elseif droid.action == "generic_cooker_craft_rice_flour" then
        lf("generic_cooker:act", "generic_cooker_craft_rice_flour: " .. minetest.pos_to_string(droid:get_pos()))
        craft_rice_flour(droid)
    elseif droid.action == "generic_cooker_sleep" then
        lf("DEBUG generic_cooker:act", "generic_cooker_sleep: " .. minetest.pos_to_string(droid:get_pos()))
        local target = droid._bed_target
        if target and target.pos then
            -- Check if beds mod is available
            if beds then
                maidroid.sleep.handle_sleep_action(droid, target.pos)
                -- DEBUG: Don't return to wander after sleep - keep maidroid in sleep state
                lf("DEBUG generic_cooker:act", "sleep action completed, staying in sleep state (no wander return)")
                return nil -- Prevent return to wander
            else
                lf("DEBUG generic_cooker:act", "beds mod not available for sleeping")
            end
        else
            lf("DEBUG generic_cooker:act", "generic_cooker_sleep: no bed target")
        end
        droid._bed_target = nil
	end

	-- Teleport back to starting position if available (skip for sleep actions)
	if droid.path_start_pos and droid.action ~= "generic_cooker_sleep" then
		droid.object:set_pos(droid.path_start_pos)
		lf("generic_cooker:act", ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Teleported back to start pos: " .. minetest.pos_to_string(vector.round(droid.path_start_pos)))
	end


	-- Action finished: return cleanly to wander behavior, like waffler.to_wander
	return to_wander(droid, "generic_cooker:act")
end

-- ,,task
task = function(droid)
    local pos = droid:get_pos()
    local inv = droid:get_inventory()

	-- : randomly pick one of four actions, with choice 1 being twice as likely as others
	-- Use math.random(4): values 1 and 2 map to choice 1, values 3 and 4 map to choices 2, 3, and 4
	local choice = math.random(3)
    choice = 3

	if choice == 1 then
		lf("DEBUG generic_cooker:task", "CHOICE=1: try_feed_get_from_furnace__generic for ")
	    	try_feed_get_from_furnace__generic(droid, pos)
    elseif choice == 2 then
        lf("DEBUG generic_cooker:task", "CHOICE=2: craft_generic")
        -- craft_rice_flour(droid)
        local myoutput = maidroid.cores.generic_cooker.get_desired_craft_outputs(droid)
        maidroid.craft_generic(droid, myoutput)
    elseif choice == 3 then
		lf("DEBUG generic_cooker:task", "CHOICE=3: try_get_item_from_nearby_chest for all_take_items count=" .. #all_take_items)
	    	-- try_get_item_from_nearby_chest(droid, pos, all_take_items)
	    	try_get_item_from_nearby_chest(droid, pos, get_combined_take_items(droid))
	elseif choice == 4 then 
		lf("DEBUG generic_cooker:task", "CHOICE=4: try_sleep_in_bed")
	    	maidroid.sleep.try_sleep_in_bed(droid, pos, {GenericCookerTarget = GenericCookerTarget, to_action = to_action, name = "generic_cooker"}, 12)
    else
        lf("ERROR generic_cooker:task", "Invalid choice: " .. choice)
	end
end

-- Check for fence detection failures
local check_fence_detection = function(droid)
	local front = droid:get_front()
	local below1 = vector.add(front, {x = 0, y = -1, z = 0})
	local below2 = vector.add(front, {x = 0, y = -2, z = 0})
	local pos_here = vector.round(droid:get_pos())
	local pos_here_below = vector.add(pos_here, {x = 0, y = -1, z = 0})
	local n_front = minetest.get_node(front).name
	local n_below1 = minetest.get_node(below1).name
	local n_below2 = minetest.get_node(below2).name
	local n_here = minetest.get_node(pos_here).name
	local n_here_below = minetest.get_node(pos_here_below).name
	local has_fence = maidroid.helpers.is_fence(n_front)
		or maidroid.helpers.is_fence(n_below1)
		or maidroid.helpers.is_fence(n_below2)
		or maidroid.helpers.is_fence(n_here)
		or maidroid.helpers.is_fence(n_here_below)
	if has_fence and not droid:is_blocked(maidroid.helpers.is_fence, true) then
		local pos = vector.round(droid:get_pos())
		minetest.log("warning",
			"[maidroid fence debug] FAILED blocked detection (farming); droid=" .. minetest.pos_to_string(pos) ..
			" front=" .. minetest.pos_to_string(front) ..
			" below1=" .. minetest.pos_to_string(below1) ..
			" below2=" .. minetest.pos_to_string(below2) ..
			" n_front=" .. n_front ..
			" n_below1=" .. n_below1 ..
			" n_below2=" .. n_below2 ..
			" n_here=" .. n_here ..
			" n_here_below=" .. n_here_below)
		if not droid.pause and droid.core and droid.core.on_pause then
			droid.core.on_pause(droid)
			droid.pause = true
		end
	end
end
-- ,,step
on_step = function(droid, dtime, moveresult)
	-- Check if maidroid is sleeping - if so, prevent all movement and processing
	if maidroid.sleep.on_step_sleep_check(droid, dtime, moveresult) then
		return -- Skip all other processing while sleeping
	end
	
	droid:pickup_item()

	-- Check if maidroid is more than max_distance_from_activation blocks away from activation position
	maidroid.check_activation_position_and_boundary(droid)
	-- if droid._activation_pos then
	-- 	local current_pos = droid:get_pos()
	-- 	local distance = vector.distance(current_pos, droid._activation_pos)
	-- 	local max_distance = get_max_distance_from_activation()
	-- 	if distance > max_distance then
	-- 		lf("generic_cooker", "Too far from activation (" .. string.format("%.1f", distance) .. " > " .. max_distance .. "), teleporting back")
	-- 		droid.object:set_pos(droid._activation_pos)
	-- 	end
	-- end
    

	-- Update metrics logging timer
	metrics_log_timer = metrics_log_timer + dtime
	if metrics_log_timer >= metrics_log_interval then
		log_chest_taken_metrics()
		metrics_log_timer = 0 -- Reset timer
	end

	if droid.state ~= maidroid.states.ACT and droid.state ~= maidroid.states.PATH then
	-- if droid.state ~= maidroid.states.ACT  then
		wander.on_step(droid, dtime, moveresult, task, is_fence_or_chest, true)
		-- Check for fence detection failures
		check_fence_detection(droid)
	end
    

    if droid.state == states.PATH then
		-- Even while following a path, still respect fences and chests by using the
		-- same is_blocked logic; this avoids unexpectedly crossing them.
		-- local isblocked = droid:is_blocked(is_fence_or_chest, true)
		-- if isblocked then
		-- 	lf("generic_cooker", "PATH blocked by fence; cancelling path")
			
		-- 	-- Update action_taken_metrics
		-- 	action_taken_metrics["path_blocked"] = (action_taken_metrics["path_blocked"] or 0) + 1
		-- 	-- lf("action_metrics", "path_blocked called: " .. awdction_taken_metrics["path_blocked"])
			
        --     			-- Stop the maidroid immediately without cancelling path targets
		-- 	droid:halt()
		-- 	droid:set_animation(maidroid.animation.STAND)
		-- 	return

		-- 	-- Cancel any pending path targets
		-- 	-- droid._generic_cooker_target = nil
		-- 	-- droid._furnace_target = nil
		-- 	-- to_wander(droid, "generic_cooker:path_blocked", 0, timers.change_dir_max)
		-- 	-- droid.timers.wander_skip = 1
		-- 	-- return
		-- end
		maidroid.cores.path.on_step(droid, dtime, moveresult)
	elseif droid.state == states.ACT then
		act(droid, dtime)
	end
end



-- Static counter to track on_start calls
local on_start_call_count = 0

-- ,,start
on_start = function(droid)
    -- on_start_call_count = on_start_call_count + 1
    -- if on_start_call_count > 1 then
    --     droid.object:remove()
    --     return
    -- end
    
    -- tests()
	-- Initialize low fence detection for farming core (only if not already set)
	if droid._use_low_fence == nil then
		droid._use_low_fence = true
	end
	if droid._is_bounded == nil then
		droid._is_bounded = true
	end
	if droid._mow_only == nil then
		droid._mow_only = true
	end

    if droid._move_radius == nil then
        droid._move_radius = 5
    end
    
    lf("generic_cooker", "------------------------------------------------on_start------------------------------------------------")
    
    -- Store activation position if not already set (retain last spawned position)
    if not droid._activation_pos then
        droid._activation_pos = droid:get_pos()
        lf("generic_cooker", "Stored activation position: " .. minetest.pos_to_string(droid._activation_pos))
    else
        lf("generic_cooker", "Using existing activation position: " .. minetest.pos_to_string(droid._activation_pos))
    end
    
    -- Initialize all_take_items as hash map {item_name: quantity}
    all_take_items = {}
    for _, item_name in ipairs(all_take_item_names) do
        all_take_items[item_name] = 5
    end

    -- lf("generic_cooker", "all_take_items=" .. dump(all_take_items))
    

    -- tests()
    lf("generic_cooker", "test")

    if not droid.desired_craft_outputs then
        droid.desired_craft_outputs = craft_outputs
    end
    
    -- Initialize cooklist with cookable_inputs from api.lua
    -- if maidroid.cookable_inputs and not droid.cooklist then
    if  not droid.cooklist then
        maidroid.cores.generic_cooker.set_cooklist(droid, maidroid.cookable_inputs)
        lf("generic_cooker", "Initialized cooklist with cookable_inputs: " .. dump(maidroid.cookable_inputs))
    else
        lf("generic_cooker", "Warning: maidroid.cookable_inputs not available or cooklist already defined")
    end
    
    log_inventory(droid)
    
   
	wander.on_start(droid)
end

maidroid.cores.basic.doc = maidroid.cores.basic.doc .. "\t"
	.. S("Generic cooker: seed_rice + coal -> cooked") .. "\n"

local doc = S("They manage a nearby furnace using rice seeds") .. "\n\n"
	.. S("Abilities") .. "\n"
	.. "\t" .. S("Take farming:seed_rice from nearby chests") .. "\n"
	.. "\t" .. S("Feed coal to default:furnace") .. "\n"
	.. "\t" .. S("Feed farming:seed_rice to default:furnace input") .. "\n"

local hat
if maidroid.settings.hat then
	hat = {
		name = "hat_cook",
		mesh = "maidroid_hat_cook.obj",
		textures = { "maidroid_hat_cook.png" },
		offset = { x=0, y=0, z=0 },
		rotation = { x=0, y=0, z=0 },
	}
end

maidroid.register_core("generic_cooker", {
	description = S("Generic cooker"),
	on_start = on_start,
	on_stop = on_stop,
	on_resume = on_resume,
	on_pause = on_pause,
	on_step = on_step,
	is_tool = is_tool,
	default_item = "maidroid:spatula",
    -- walk_max = 4.5 * timers.walk_max,
    path_max = 15,
	no_jump = true,
	hat = hat,
	can_sell = true,
	doc = doc,
})

-- Add custom functions after core registration to prevent overwriting
-- Expose the configurable distance threshold and setter function
maidroid.cores.generic_cooker.max_distance_from_activation = max_distance_from_activation
maidroid.cores.generic_cooker.set_max_distance_from_activation = set_max_distance_from_activation
maidroid.cores.generic_cooker.get_max_distance_from_activation = get_max_distance_from_activation
maidroid.cores.generic_cooker.get_items_in_group = maidroid.craft.get_items_in_group

-- Also expose directly to maidroid table as fallback
maidroid.set_max_distance_from_activation = set_max_distance_from_activation
maidroid.get_max_distance_from_activation = get_max_distance_from_activation

maidroid.cores.generic_cooker.get_craftable_outputs = function()
	if type(all_farming_outputs) == "table" and #all_farming_outputs > 0 then
        -- error("maidroid.cores.generic_cooker.get_craftable_outputs: all_farming_outputs is not a table or is empty")
		return all_farming_outputs
	end
	return {
		"farming:rhubarb_pie",
		"farming:bread",
	}
end

maidroid.cores.generic_cooker.set_desired_craft_outputs = function(droid, outputs)
	lf("generic_cooker", "set_desired_craft_outputs: " .. dump(outputs))
	droid.desired_craft_outputs = outputs
	return true
end

maidroid.cores.generic_cooker.get_desired_craft_outputs = function(droid)
	if droid and type(droid.desired_craft_outputs) == "table" then
		return droid.desired_craft_outputs
	end
	return {}
end



maidroid.cores.generic_cooker.set_cooklist = function(droid, cooklist)
	lf("generic_cooker", "set_cooklist: " .. dump(cooklist))
    -- error("test")
	droid.cooklist = {}

    for _, item_name in ipairs(cooklist) do
        table.insert(droid.cooklist, { item_name = item_name, count = 5 })
    end
end

-- Convert cooklist back to a simple list of item names
maidroid.cores.generic_cooker.get_cooklist_flat = function(droid)
    cooklist = droid.cooklist;
    if not cooklist or type(cooklist) ~= "table" then
        return {}
    end
    
    local flat_list = {}
    for _, cook_item in ipairs(cooklist) do
        if cook_item.item_name then
            table.insert(flat_list, cook_item.item_name)
        end
    end
    
    return flat_list
end



maidroid.cores.generic_cooker.get_cookable_items = function()
    
    -- Get all furnace inputs from cooker_items.lua
    local cookable_items = {}
    
    -- Filter all_furnace_inputs to exclude tools
    for _, item_name in ipairs(all_furnace_inputs) do
        -- Check if this item is NOT a tool
        if not is_cookable_tool(item_name) then
            table.insert(cookable_items, item_name)
            lf("get_cookable_items", "Added cookable item: " .. item_name)
        else
            lf("get_cookable_items", "Excluded tool item: " .. item_name)
        end
    end
    
    lf("get_cookable_items", "Total cookable items found: " .. #cookable_items)
    
    return cookable_items
end

-- Test command to verify the function works
minetest.register_chatcommand("test_cookable_inputs", {
	description = "Test the get_all_cookable_furnace_inputs function",
	privs = {server=true},
	func = function(name)
		local cookable_inputs = maidroid.craft.get_all_cookable_furnace_inputs()
        lf("test_cookable_inputs", "cookable_inputs=" .. dump(cookable_inputs))
		local output = {"Cookable furnace inputs found: " .. #cookable_inputs}
		local max_lines = 30
		for i, item_name in ipairs(cookable_inputs) do
            lf("test_cookable_inputs", "item=" .. item_name)
			if i <= max_lines then
				output[#output + 1] = string.format("%d. %s", i, item_name)
			else
				output[#output + 1] = string.format("... and %d more items", #cookable_inputs - max_lines)
				break
			end
		end
		return true, table.concat(output, "\n")
	end
})

-- Chat command to view chest taken metrics
minetest.register_chatcommand("chest_metrics", {
	description = "View chest taken metrics",
	privs = {server=true},
	func = function(name)
		local metrics = maidroid.get_chest_taken_metrics()
		local output = {"Chest Taken Metrics:"}
		
		if next(metrics) == nil then
			output[#output + 1] = "No items taken from chests yet."
		else
			for item_name, count in pairs(metrics) do
				output[#output + 1] = string.format("%s: %d", item_name, count)
			end
		end
		
		return true, table.concat(output, "\n")
	end
})

-- vim: ai:noet:ts=4:sw=4:fdm=indent:syntax=lua
