-- Copyleft (Я) 2026 mazes-style extension
-- Maidroid crafting functions
-- Extracted from generic_cooker.lua for better organization
------------------------------------------------------------

local S = maidroid.translator
local lf = maidroid.lf

local function lfv(verbose, ...)
	if verbose then
		lf(...)
	end
end

-- Helper: given a group spec like "group:food_bread", return a list of
-- all registered item names that belong to that group.
local function get_items_in_group(group_spec)
	if type(group_spec) ~= "string" then
		return {}
	end

	-- Accept either "group:name" or just "name" as input.
	local groupname = group_spec
	local prefix = "group:"
	if groupname:sub(1, #prefix) == prefix then
		groupname = groupname:sub(#prefix + 1)
	end
	if groupname == "" then
		return {}
	end

	local result = {}
	for name, def in pairs(minetest.registered_items) do
		-- Skip non-craftable or hidden entries if desired in the future.
		if minetest.get_item_group(name, groupname) and
			minetest.get_item_group(name, groupname) > 0 then
			result[#result + 1] = name
		end
	end

	return result
end

-- Helper function to check if all required items are available
local function check_required_items(inv, consumables, output_name)
    -- ,,x2
    local missing = false
    for name, count in pairs(consumables or {}) do
        local needed = string.format("%s %d", name, count)
        lf("generic_cooker", "craft_generic(" .. output_name .. "): checking for " .. needed)
        if not inv:contains_item("main", needed) then
            lf("generic_cooker", "craft_generic(" .. output_name .. "): missing " .. needed)
            missing = true
            break
        end
    end
    return missing
end

-- Helper function to check required items with group expansion
local function check_required_items_with_group(inv, consumables, output_name)
    -- ,,x1
    local missing = false
    local matching_items = {} -- Store the actual items that will be used (list of {name, count})
    
    for name, count in pairs(consumables or {}) do
        -- Check if this is a group item
        if string.find(name, "group:", 1, true) == 1 then
            -- This is a group, get all items in this group
            local group_name = string.sub(name, 7) -- Remove "group:" prefix
            local group_items = get_items_in_group("group:" .. group_name)
            
            lf("generic_cooker", "craft_generic(" .. output_name .. "): checking group " .. group_name .. " with items: " .. dump(group_items))
            
            -- Check if any item in the group is available
            local found_item = false
            for _, item_name in ipairs(group_items or {}) do
                -- local needed = string.format("%s %d", item_name, count)
                local needed = string.format("%s %d", item_name, count)
                lf("generic_cooker", "craft_generic(" .. output_name .. "): checking for " .. needed)
                if inv:contains_item("main", needed) then
                    lf("generic_cooker", "craft_generic(" .. output_name .. "): found group item " .. needed)
                    table.insert(matching_items, {name = item_name, count = count}) -- Store the actual item that matches the group
                    found_item = true
                    break
                end
            end
            
            if not found_item then
                lf("generic_cooker", "craft_generic(" .. output_name .. "): missing any item from group " .. group_name)
                missing = true
                break
            end
        else
            -- This is a regular item, check normally
            local needed = string.format("%s %d", name, count)
            lf("generic_cooker", "craft_generic(" .. output_name .. "): checking for " .. needed)
            if inv:contains_item("main", needed) then
                table.insert(matching_items, {name = name, count = count}) -- Store the regular item
            else
                lf("generic_cooker", "craft_generic(" .. output_name .. "): missing " .. needed)
                missing = true
                break
            end
        end
    end
    return missing, matching_items
end

local function try_remove_item_for_craft(inv, consumables)
    local removed_items = {}
    for name, count in pairs(consumables or {}) do
        local needed = string.format("%s %d", name, count)
        local removed = inv:remove_item("main", needed)
        local got = removed:get_count()
        if removed:is_empty() or got < count then
            for _, r in ipairs(removed_items) do
                if not r:is_empty() then
                    inv:add_item("main", r)
                end
            end
            if not removed:is_empty() then
                inv:add_item("main", removed)
            end
            return nil
        end
        removed_items[#removed_items + 1] = removed
    end
    return removed_items
end

-- Similar to get_replacements_for_output, but operates on an explicit
-- list of recipe items (such as recipe.items returned by
-- minetest.get_all_craft_recipes) instead of an output item name.
--
-- Params:
--   items  : array of item strings (recipe grid, row-major)
--   method : optional craft method (defaults to "normal")
--   width  : optional craft width (defaults to 3)
--   verbose: optional boolean for debug logging
--
-- Returns:
--   replacements table in the same shape as register_craft
--   (or nil if none were detected), and the crafted result item stack
--   (or nil on failure).
-- ,,repl
local function get_replacements_for_recipe(items, method, width, verbose)
  if not items or #items == 0 then
    return {}
  end

  verbose = not not verbose

  local spec = {
    method = method or "normal",
    width  = width or 3,
    items  = items,
  }

  local _, decremented = minetest.get_craft_result(spec)
  lfv(verbose, "generic_cooker", "get_replacements_for_recipe: input=" .. dump(spec) .. " decremented=" .. dump(decremented))

  local replacements = {}
  if decremented and decremented.items then
    for _, after in ipairs(decremented.items) do
      if after and not after:is_empty() then
        local name = after:get_name()
        if name ~= "" then
          replacements[#replacements + 1] = name
          lfv(verbose, "generic_cooker", "get_replacements_for_recipe(items): replacement=" .. name)
        end
      end
    end
  end

  if #replacements == 0 then
    lfv(verbose, "generic_cooker", "get_replacements_for_recipe(items): no replacements detected")
  end

  return replacements
end

-- Helper: return required inputs for a craft output name, split into
-- consumables and replacements.
-- First return value is { [item_name] = total_count, ... } built from
-- the normalized recipe items. Second return value is the replacements
-- list returned (or inferred) by get_replacements_for_recipe, or nil.
-- When no recipe is found, both return values are nil.
-- ,,craft,,req
local function get_craft_requirements_from_registered(output_name, verbose)
	if not output_name or output_name == "" then
		return nil
	end

	local recipes = minetest.get_all_craft_recipes(output_name)
	lfv(verbose, "generic_cooker", "get_craft_requirements_from_registered: ALLrecipes=" .. dump(recipes))
	if not recipes or #recipes == 0 then
		return nil
	end

	local all = {}

	for _, recipe in ipairs(recipes) do
		if recipe.items and #recipe.items > 0 then
			local consumables = {}
			for _, item in ipairs(recipe.items) do
				if item ~= "" then
					local stack = ItemStack(item)
					local name = stack:get_name()
					local count = stack:get_count()
					if name ~= "" and count > 0 then
						consumables[name] = (consumables[name] or 0) + count
					end
				end
			end
			if next(consumables) ~= nil then
				local replacements = get_replacements_for_recipe(recipe.items, recipe.method, recipe.width, verbose)
				if replacements then
					lfv(verbose, "generic_cooker", "get_craft_requirements_from_registered: replacements=" .. dump(replacements))
				end
				-- Each entry is a tuple: { consumables, replacements }
				all[#all + 1] = { consumables, replacements }
			end
		end
	end

	if #all == 0 then
		return nil
	end

    lfv(verbose, "generic_cooker", ">>>>>>>>>>>>>>>>>>> get_craft_requirements_from_registered: all=" .. dump(all))
	return all
end

-- Helper: given a list of output specs (e.g. all_farming_outputs),
-- return a flat list of unique required craft input item names across
-- all of them. The list is expected to contain strings acceptable to
-- ItemStack, such as "farming:bread_slice" or "farming:bread_slice 5".
-- The return value is an array-like table of item names, e.g.:
--   { "farming:flour", "bucket:bucket_water", ... }
-- ,,req
local function get_all_required_craft_items(outputs, verbose)
	if type(outputs) ~= "table" then
		return {}
	end

	local seen = {}
	local list = {}

	for _, spec in ipairs(outputs) do
		if type(spec) == "string" and spec ~= "" then
			local stack = ItemStack(spec)
			local out_name = stack:get_name()
			if out_name ~= "" then
				local recipes = get_craft_requirements_from_registered(out_name, verbose)
				if recipes then
					for _, tuple in ipairs(recipes) do
						local consumables = tuple[1]
				if consumables then
					for in_name, _ in pairs(consumables) do
						if in_name ~= "" and not seen[in_name] then
							seen[in_name] = true
							list[#list + 1] = in_name
						end
					end
				end
			end
		end
	end
		end
	end

	return list
end

-- Main crafting function
-- ,,cg,,craft
local function craft_generic(droid, craft_outputs)
    -- lf("craft_generic", "craft_generic called: craft_ouputs="..dump(craft_outputs))

    lf("action_metrics", "craft_generic called")

    local inv = droid and droid:get_inventory()
    if not inv then
        return false
    end -- if not inv

    local best_output_stack = nil
    local best_output_name = nil
    local best_consumables = nil
    local best_replacements = nil
    local best_ingredient_count = -1

    for _, spec in ipairs(craft_outputs or {}) do
        local output_stack = ItemStack(spec)
        local output_name = output_stack:get_name()
        if output_name ~= "" then
            local recipe_options = get_craft_requirements_from_registered(output_name)
            if recipe_options then
                -- Ensure there is room for the result before consuming inputs.
                if inv:room_for_item("main", output_stack) then
                    -- Try each recipe option and select the craftable one with the most ingredients.
                    for _, recipe_tuple in ipairs(recipe_options) do
                        local consumables = recipe_tuple[1]
                        local replacements = recipe_tuple[2]

                        local missing, matching_items = check_required_items_with_group(inv, consumables, output_name)

                        if not missing then
                            -- Convert matching_items list back to consumables table format
                            local new_consumables = {}
                            for _, item in ipairs(matching_items) do
                                new_consumables[item.name] = item.count
                            end

                            local ingredient_count = 0
                            for _, count in pairs(new_consumables) do
                                ingredient_count = ingredient_count + (count or 0)
                            end

                            if ingredient_count > best_ingredient_count then
                                best_output_stack = output_stack
                                best_output_name = output_name
                                best_consumables = new_consumables
                                best_replacements = replacements
                                best_ingredient_count = ingredient_count
                            end
                        end
                    end -- for recipe_options loop
                end
            end -- if recipe_options
        end -- if output
    end

    if best_consumables and best_output_stack then
        local removed_items = try_remove_item_for_craft(inv, best_consumables)
        if removed_items then
            for _, rep in ipairs(best_replacements or {}) do
                lf("generic_cooker", "craft_generic(" .. best_output_name .. "): replacement " .. dump(rep))
                local replacement_name = rep
                if replacement_name and replacement_name ~= "" then
                    local replacement_stack = ItemStack(replacement_name)
                    inv:add_item("main", replacement_stack)
                    lf("generic_cooker", "craft_generic(" .. best_output_name .. "): returned replacement " .. replacement_stack:to_string())
                end
            end

            inv:add_item("main", best_output_stack)
            lf("generic_cooker", "craft_generic: crafted " .. best_output_stack:to_string())

            return true
        end
    end

    return false
end

-- Helper function for verbose logging
local function lfv(verbose, ...)
	if verbose then
		lf(...)
	end
end

-- Export functions to maidroid namespace
maidroid.craft = {
    craft_generic = craft_generic,
    get_craft_requirements_from_registered = get_craft_requirements_from_registered,
    get_all_required_craft_items = get_all_required_craft_items,
    check_required_items = check_required_items,
    check_required_items_with_group = check_required_items_with_group,
    try_remove_item_for_craft = try_remove_item_for_craft,
    get_replacements_for_recipe = get_replacements_for_recipe,
    get_items_in_group = get_items_in_group,
}

-- Also export individual functions for backward compatibility
maidroid.craft_generic = craft_generic
maidroid.get_craft_requirements_from_registered = get_craft_requirements_from_registered
maidroid.get_all_required_craft_items = get_all_required_craft_items
maidroid.check_required_items = check_required_items
maidroid.check_required_items_with_group = check_required_items_with_group
maidroid.try_remove_item_for_craft = try_remove_item_for_craft
maidroid.get_replacements_for_recipe = get_replacements_for_recipe
maidroid.get_items_in_group = get_items_in_group
