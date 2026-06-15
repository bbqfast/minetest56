------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
------------------------------------------------------------
-- Copyright (c) 2020 IFRFSX.
------------------------------------------------------------
-- Copyleft (Я) 2021-2023 mazes
-- https://gitlab.com/mazes_80/maidroid
------------------------------------------------------------

local S = maidroid.translator

local lf = maidroid.lf

local timers = maidroid.timers

local DIG_BELOW_INTERVAL = 0.5

-- Function to check if maidroid has mining guide in inventory
local function has_mining_guide(self)
	lf("digger:has_mining_guide", "Checking if maidroid has mining guide in inventory")
	
	-- Get the maidroid's inventory
	local inv = self:get_inventory()
	if not inv then
		lf("digger:has_mining_guide", "Maidroid has no inventory")
		return false
	end
	
	-- Check if mining guide exists in main inventory
	local guide_stack = inv:contains_item("main", ItemStack("maidroid:mining_guide"))
	
	if guide_stack then
		lf("digger:has_mining_guide", "Mining guide found in inventory")
		return true
	else
		lf("digger:has_mining_guide", "Mining guide not found in inventory")
		return false
	end
end

-- Function to put guide block in maidroid's inventory
-- ,,guide2
local function put_guide_in_inventory(self, pos)
	lf("digger:put_guide_in_inventory", "Attempting to pick up guide block at " .. minetest.pos_to_string(pos))
	
	if not pos then
		lf("digger:put_guide_in_inventory", "No position provided")
		return false
	end
	
	-- Teleport maidroid to guide location
	-- local current_pos = self:get_pos()
	-- if current_pos and pos then
    local gpos = self._guide_pos
    local teleport_pos = {x = gpos.x, y = gpos.y + 1, z = gpos.z} -- Position above the guide block
    self.object:set_pos(teleport_pos)
    lf("digger:put_guide_in_inventory", "Teleported to pos: " .. minetest.pos_to_string(teleport_pos))
	-- end
	
	-- Check if position is protected
	if minetest.is_protected(pos, self.owner) then
		lf("digger:put_guide_in_inventory", "Position is protected: " .. minetest.pos_to_string(pos))
		return false
	end
	
	-- Get the node at the position
	local node = minetest.get_node(pos)
	if not node then
		lf("digger:put_guide_in_inventory", "No node found at position: " .. minetest.pos_to_string(pos))
		return false
	end
	
	-- Check if it's a guide block
	if node.name ~= "maidroid:mining_guide" then
		lf("digger:put_guide_in_inventory", "Node is not a guide block: " .. node.name)
		return false
	end
	
	-- Get the maidroid's inventory
	local inv = self:get_inventory()
	if not inv then
		lf("digger:put_guide_in_inventory", "Maidroid has no inventory")
		return false
	end
	
	-- Create ItemStack for the guide block
	local guide_stack = ItemStack("maidroid:mining_guide")
	
	-- Try to add to inventory
	local leftover = inv:add_item("main", guide_stack)
	
	if leftover:is_empty() then
		-- Successfully added, remove the node
		minetest.remove_node(pos)
		lf("digger:put_guide_in_inventory", "Successfully picked up guide block and added to inventory")
		return true
	else
		-- Inventory is full
		lf("digger:put_guide_in_inventory", "Inventory is full, cannot pick up guide block")
		return false
	end
end

-- Core interface functions
local on_start, on_pause, on_resume, on_stop, on_step, is_tool

-- Core extra functions
local plant, mow, collect_papyrus, plant_papyrus, to_action
local craft_seeds, select_seed, task, task_base
local act
local dig_block_in_direction
local is_seed, is_plantable, is_papyrus, is_papyrus_soil, is_mowable, is_scythe
local is_player_has_follow_item

local wander_core =  maidroid.cores.wander
local to_wander = wander_core.to_wander
local core_path = maidroid.cores.path

local search = maidroid.helpers.search_surrounding

local mature_plants = {}
local weed_plants = {}
local seeds = {}

local farming_redo = farming and farming.mod and farming.mod == "redo"

local follow = maidroid.cores.follow.on_step
local wander = maidroid.cores.wander.on_step

-- local lottfarming_on = lottfarming

-- check if lottfarming is installed, and set a flag
local lottfarming_on = false

if minetest.get_modpath("lottfarming") then
    lottfarming_on=true
end

local ld = function(msg, dest)
	if (dest ~= nil) then
		local destnode = minetest.get_node(dest)
		-- ll(msg.." "..destnode.name)
	end
	
end

local except_nodes2 = { ["default:lava_source"] = true, ["default:lava_flowing"] = true }

local except_nodes1 = {
	["default:stone"] = true,
	["default:cobble"] = true,
	["default:obsidian"] = true,
	["default:dirt"] = true,
	["lottmapgen:shire_grass"] = true,
	["lottmapgen:lorien_grass"] = true,
	["default:sand"] = true,
}

local skip_storage_nodes = {
	["default:cobble"] = true,
	["default:dirt"] = true,
	["default:sandstone"] = true,
	["lottores:limestone"] = true,
	["default:sand"] = true,
}

-- Calculate distance from maidroid to player
local function distance_from_player(self)
	local player = minetest.get_player_by_name(self.owner)
	if not player then
		return nil
	end
	
	local pos = self:get_pos()
	local player_pos = player:get_pos()
	
	if not pos or not player_pos then
		return nil
	end
	
	return vector.distance(pos, player_pos)
end

local function extract_before_underscore(str)
    -- return str:match("([^_]*)")
    return str:match("(.*)_[0-9]+")
end

-- Check if player has follow item (pick_stone or goldpick)
local function is_player_has_follow_item(self)
	local player = minetest.get_player_by_name(self.owner)
	if not player then
		return false
	end
	
	local wielded_item = player:get_wielded_item():get_name()
	-- return wielded_item == "default:pick_stone" or wielded_item == "lottores:goldpick"
	return  wielded_item == "lottores:goldpick"
end

-- ,,tpm
local function handle_teleport_to_maidroid(self, player)
	local inv = self:get_inventory()
	local first_stack = inv and inv:get_stack("main", 1)
    local dist_from_maidroid = 3
	if first_stack and player:get_wielded_item():get_name() == first_stack:get_name() then
		local self_pos = self:get_pos()
		if self_pos then
			player:set_pos({x = self_pos.x, y = self_pos.y + dist_from_maidroid, z = self_pos.z})
			-- minetest.chat_send_player(player:get_player_name(), "Teleported to your maidroid!")
			return true
		end
	end

	return false
end

-- ,,light
local function handle_helper_light(self, pos, player)
    -- lf("digger:handle_helper_light", "handle_helper_light: " .. minetest.pos_to_string(pos))
	local light_pos = {
		x = math.floor(pos.x + 0.5),
		y = math.floor(pos.y + 0.5),
		z = math.floor(pos.z + 0.5),
	}

	-- local should_light = self._helper_light_enabled == true
	local should_light = true
	-- local now = minetest.get_gametime()
	-- if player then
	-- 	local ppos = player:get_pos()
	-- 	if ppos then
	-- 		self._helper_light_last_player_time = now
	-- 		local dist = vector.distance(ppos, pos)
	-- 		if should_light then
	-- 			if dist >= 17 then
	-- 				should_light = false
	-- 			end
	-- 		else
	-- 			if dist <= 15 then
	-- 				should_light = true
	-- 			end
	-- 		end
	-- 	end
	-- else
	-- 	local last = self._helper_light_last_player_time
	-- 	if last and (now - last) <= 2 then
	-- 		should_light = true
	-- 	else
	-- 		should_light = false
	-- 	end
	-- end

	self._helper_light_enabled = should_light

	local target_node = minetest.get_node(light_pos)

	if not should_light then
		if self._last_light_pos then
			local old = minetest.get_node(self._last_light_pos)
			if old and old.name == "maidroid:helper_light" then
				lf("digger:handle_helper_light", "Removing helper_light at " .. minetest.pos_to_string(self._last_light_pos))
				minetest.remove_node(self._last_light_pos)
			end
		end
		self._last_light_pos = nil
		self._last_light_node = nil
		return
	end

	local is_same_pos = self._last_light_pos and vector.equals(light_pos, self._last_light_pos)
	if is_same_pos then
		if target_node and target_node.name ~= "maidroid:helper_light" then
			if target_node.name == "air" or target_node.name == "ignore" then
				minetest.set_node(light_pos, {name = "maidroid:helper_light"})
			end
		end
		return
	end

	if self._last_light_pos then
		local old = minetest.get_node(self._last_light_pos)
		if old and old.name == "maidroid:helper_light" then
			minetest.remove_node(self._last_light_pos)
		end
	end

	if target_node and (target_node.name == "air" or target_node.name == "ignore") then
		minetest.set_node(light_pos, {name = "maidroid:helper_light"})
		self._last_light_pos = vector.new(light_pos)
		self._last_light_node = target_node and target_node.name or nil
	else
		self._last_light_pos = vector.new(light_pos)
		self._last_light_node = target_node and target_node.name or nil
	end
end

local move_up_one = function(self)
end


local function is_liquid(node)
	isliquid = node and (
		minetest.get_item_group(node.name, "water") > 0
		or minetest.get_item_group(node.name, "lava") > 0
		or node.name == "default:water_source"
		or node.name == "default:water_flowing"
		or node.name == "default:river_water_source"
		or node.name == "default:river_water_flowing"
		or node.name == "default:lava_source"
		or node.name == "default:lava_flowing"
	)

    -- if not isliquid then
    --     lf("digger:is_liquid", "is_liquid: not liquid: " .. node.name)
    --     return false
    -- end

    return isliquid
end

local function is_liquid2(node1, node2)
	return is_liquid(node1) or is_liquid(node2)
end

local function is_liquid3(node1, node2, node3)
	return is_liquid(node1) or is_liquid(node2) or is_liquid(node3)
end

-- Function to find path to mining_guide and walk to it
-- ,,guide1
local function find_and_walk_to_mining_guide(self)
	lf("digger:find_and_walk_to_mining_guide", "Starting mining guide search")
	local pos = self:get_pos()
	
	-- Find mining guide within range
	local search_range = 50 -- Adjust range as needed
	lf("digger:find_and_walk_to_mining_guide", "Searching for mining guide within " .. search_range .. " blocks")
	local mining_guide_pos = minetest.find_node_near(pos, search_range, {"maidroid:mining_guide"})
	
	if not mining_guide_pos then
		lf("digger", "No mining guide found within range")
		return false
	end
	
    self._guide_pos = mining_guide_pos

	-- Save mining guide position
	self._mining_guide_pos = mining_guide_pos
	lf("digger", "Found mining guide at " .. minetest.pos_to_string(mining_guide_pos))
	lf("digger:find_and_walk_to_mining_guide", "Checking if mining guide location is safe")
	
    -- Calculate distance to mining guide
    local distance = vector.distance(pos, mining_guide_pos)
    lf("digger:find_and_walk_to_mining_guide", "Distance to mining guide: " .. string.format("%.2f", distance))
    
    -- If already close to mining guide, just stand there
    -- if distance < 3 then
    --     lf("digger", "Already near mining guide, standing by")
    --     lf("digger:find_and_walk_to_mining_guide", "Already at destination")
    --     self.destination = mining_guide_pos
    --     self.action = "stand_by"
    --     return to_action(self)
    -- end    

    	-- Find shortest path to mining guide using standable positions
	lf("digger:find_and_walk_to_mining_guide", "Finding shortest path to mining guide from " .. minetest.pos_to_string(pos) .. " to " .. minetest.pos_to_string(mining_guide_pos))
	local path, target_pos = maidroid.get_shortest_path(mining_guide_pos, pos)
	
	if path ~= nil then
		lf("digger", "Shortest path found to mining guide with " .. #path .. " nodes to position " .. minetest.pos_to_string(target_pos))
		lf("digger:find_and_walk_to_mining_guide", "Path found successfully, setting up movement")
		self._mining_guide_front = target_pos
		self:set_yaw({self:get_pos(), target_pos})
		
		-- Set up action to stand by when arriving at mining guide
		lf("digger:find_and_walk_to_mining_guide", "Setting destination and action for mining guide")
		self.destination = mining_guide_pos
		self.action = "stand_by"
		core_path.to_follow_path(self, path, target_pos, to_action, "stand_by")
		return true
	else
		lf("digger", "No path found to mining guide")
		return false
	end
end

-- Function to find first non-solid vertically
local find_first_non_solid_vertically = function(pos, max_up)
	if not pos then
		return nil
	end
	local p = vector.round(pos)
	local limit = max_up or 60
	for dy = 0, limit do
		local check_pos = {x = p.x, y = p.y + dy, z = p.z}
		local node = minetest.get_node(check_pos)
		if node and node.name ~= "ignore" and not is_liquid(node) then
			if node.name == "air" then
				return vector.new(check_pos)
			end
			local def = minetest.registered_nodes[node.name]
			if def and def.buildable_to == true then
				return vector.new(check_pos)
			end
		end
	end
	return nil
end

local move_up_to_closest_air = function(self)
	local pos = self:get_pos()
	if not pos or not self.object then
        lf("digger:move_up_to_closest_air", "move_up_to_closest_air: pos or object is nil")
		return
	end

	local p = vector.round(pos)

	local max_up = 30
	for dy = 0, max_up do
		local check_pos = {x = p.x, y = p.y + dy, z = p.z}
		local node = minetest.get_node(check_pos)
		if node and node.name ~= "ignore" and not is_liquid(node) then
			lf("digger:move_up_to_closest_air", "Moving up by " .. dy .. " nodes from " .. minetest.pos_to_string(pos) .. " to: " .. minetest.pos_to_string(check_pos))

			self.object:set_pos({x = pos.x, y = check_pos.y , z = pos.z})
			return
		end
	end
    lf("digger:move_up_to_closest_air", "move_up_to_closest_air: could not find air")
end


local function restore_gravity_and_accel(self, pos)
	lf("digger:on_step", "Not in liquid: " .. minetest.pos_to_string(pos))
	if self._digger_saved_gravity ~= nil then
		self.object:set_properties({gravity = self._digger_saved_gravity})
		self._digger_saved_gravity = nil
	end
	if self._digger_saved_accel then
		self.object:set_acceleration(self._digger_saved_accel)
		self._digger_saved_accel = nil
	end
end

-- ,,x1
-- ,,water
local function handle_water_below(self, below)
	local node_below = minetest.get_node(below)
	if node_below and (
		node_below.name == "default:water_source"
		or node_below.name == "default:river_water_source"
		or node_below.name == "default:water_flowing"
		or node_below.name == "default:river_water_flowing"
		or minetest.get_item_group(node_below.name, "water") > 0
	) then
		for dx = -1, 1 do
			for dz = -1, 1 do
				local pos_to_set = {x = below.x + dx, y = below.y, z = below.z + dz}
				local n = minetest.get_node(pos_to_set)
				if n and (
					n.name == "default:water_source"
					or n.name == "default:river_water_source"
					or n.name == "default:water_flowing"
					or n.name == "default:river_water_flowing"
					or minetest.get_item_group(n.name, "water") > 0
				) then
					minetest.set_node(pos_to_set, {name = "default:dirt"})
					lf("digger:handle_water_below", "setting to dirt: " .. n.name .. " at " .. minetest.pos_to_string(pos_to_set))
				end
			end
		end
		-- self.timers.dig_below = -2
		move_up_to_closest_air(self)
		return true
	end

	local pos = self:get_pos()
	if pos then
		local here = vector.round(pos)
		local node_here = minetest.get_node(here)
		if node_here and (
			minetest.get_item_group(node_here.name, "water") > 0
			or node_here.name == "default:lava_source"
			or node_here.name == "default:lava_flowing"
			or node_here.name == "default:water_flowing"
			or node_here.name == "default:water_source"
			or minetest.get_item_group(node_here.name, "lava") > 0
		) then
            lf("digger:handle_water_below", "IN WATER Moving up to closest air from " .. minetest.pos_to_string(pos) .. " to: " .. minetest.pos_to_string(here))
			move_up_to_closest_air(self)
			return true
		end
	end

	return false
end

local spawn_dig_particles = function(target_pos, node_name)
	minetest.add_particlespawner({
		amount = 12,
		time = 0.2,
		minpos = vector.subtract(target_pos, 0.3),
		maxpos = vector.add(target_pos, 0.3),
		minvel = {x = -0.5, y = 0.5, z = -0.5},
		maxvel = {x = 0.5, y = 1.5, z = 0.5},
		minacc = {x = 0, y = -9.8, z = 0},
		maxacc = {x = 0, y = -9.8, z = 0},
		minexptime = 0.3,
		maxexptime = 0.7,
		minsize = 1,
		maxsize = 2,
		texture = minetest.registered_nodes[node_name] and
			(minetest.registered_nodes[node_name].tiles[1] or "default_dirt.png") or "default_dirt.png",
		glow = 0,
	})
end

-- ,,start
on_start = function(self)
	lf("digger:on_start", "initialized digger core")

	self.path = nil
	-- wander_core.on_start(self)
	self.state = maidroid.states.IDLE
	self.timers.walk = 0
	self.timers.change_dir = 0
	self.timers.place_torch = 0
	self.timers.dig_below = 0
	self.is_placing = false
    self.dig_ready = false
	self:halt()
	self:set_animation(maidroid.animation.STAND)	
	self._old_accel = self.object:get_acceleration()
	self.object:set_acceleration({x = 0, y = -3, z = 0})  -- tweak -3 → -2/-4 as you like
    self.is_dig_all_dir = false
	self.onstep_timer_default = 0.1
	self._onstep_timer = self.onstep_timer_default
end

on_resume = function(self)
	self.path = nil
	-- wander_core.on_resume(self)
	self._onstep_timer = self.onstep_timer_default or 0.2
end

on_stop = function(self)
	self.path = nil
	-- wander_core.on_stop(self)
	
end

on_pause = function(self)
	wander_core.on_pause(self)
end


task_base = function(self, action, destination)
	if not destination then return end

	local pos = self:get_pos()
	-- Is this droid able to make an action
	if position_ok(pos, destination) then
		self.destination = destination
		self.action = action
		to_action(self)
		return true
	end

	-- Or does the droid have to follow a path
	local path = minetest.find_path(pos, destination, 8, 1, 1, "A*_noprefetch")
	if path ~= nil then
		core_path.to_follow_path(self, path, destination, to_action, action)
		return true
	end
end


to_action = function(self)
    lf("digger:to_action", "to_action")
    lf("digger:to_action", "to_action")
	self.state = maidroid.states.ACT
	self.timers.action = 0
	self.timers.walk = 0
end

-- ,,db,,dig
local dig_block_in_direction = function(self, direction, except_nodes)
    

    -- if not self.dig_ready then
    if not has_mining_guide(self) then
        return
    end

	-- lf("digger:dig_block_in_direction", "direction: " .. minetest.pos_to_string(direction))
	local pos = self:get_pos()

	if not pos then
		lf("digger:dig_block_in_direction", "No position available for maidroid.")
		return
	end
	if not direction then
		lf("digger:dig_block_in_direction", "No direction given.")
		return
	end

	local target_pos = vector.add(pos, direction)
	-- lf("digger:dig_block_in_direction", "Current pos: " .. minetest.pos_to_string(pos) .. ", Target pos: " .. minetest.pos_to_string(target_pos))

	if minetest.is_protected(target_pos, self.owner) then
		lf("digger:dig_block_in_direction", "Target position is protected: " .. minetest.pos_to_string(target_pos))
		return
	end

	local node = minetest.get_node(target_pos)
	if not node then
		lf("digger:dig_block_in_direction", "No node at target position: " .. minetest.pos_to_string(target_pos))
		return
	end

	-- lf("digger:dig_block_in_direction", "Node to dig: " .. tostring(node.name))

	if node.name == "air" then
		lf("digger:dig_block_in_direction", "Node at target position is air.")
		return
	end

	if except_nodes and except_nodes[node.name] then
		lf("digger:dig_block_in_direction", "Skipping node in except_nodes: " .. node.name)
		return
	end

	local drops = minetest.get_node_drops(node.name)
	minetest.remove_node(target_pos)
	spawn_dig_particles(target_pos, node.name)


	move_up_one(self)
	local skip_add = false
	if not drops or #drops == 0 then
		return
	end

	local stacks = {}
	for _, item in ipairs(drops) do
		local stack = ItemStack(item)
		local name = stack:get_name()
		if not skip_storage_nodes[name] then
			table.insert(stacks, stack)
		end
	end

	if self.get_inventory then
		local inv = self:get_inventory()
		for idx, stack in ipairs(stacks) do
			lf("digger:dig_block_in_direction", "Processing stack index: " .. idx)
			local name = stack:get_name()
			lf("digger:dig_block_in_direction", "Checking add: " .. name)
			local count = 0
			for i, inv_stack in ipairs(inv:get_list("main")) do
				if inv_stack:get_name() == name then
					count = math.max(count, inv_stack:get_count())
				end
			end
			if count >= 99 then
				lf("digger:dig_block_in_direction", "Skipping add: " .. name .. " (count=" .. count .. ")")
				skip_add = true
				break
			end
		end
	end

	if #stacks > 0 and self.add_items_to_main and not skip_add then
		self:add_items_to_main(stacks)
	end
end

local dig_all_direction = function(self)
	dig_block_in_direction(self, {x = 1, y = 0, z = 0}, except_nodes1)
	dig_block_in_direction(self, {x = -1, y = 0, z = 0}, except_nodes1)
	dig_block_in_direction(self, {x = 0, y = 0, z = -1}, except_nodes1)
	dig_block_in_direction(self, {x = 0, y = 0, z = 1}, except_nodes1)
	dig_block_in_direction(self, {x = 0, y = -1, z = 0}, except_nodes2)
end


-- ,,act
act = function(self, dtime)
	self.timers.action = 0
	lf("digger:act", "act: pos=" .. minetest.pos_to_string(vector.round(self:get_pos())) .. " action=" .. tostring(self.action))

    -- self.action = "none"
	if self.action == "digger_dig_y_neg" then
		dig_block_in_direction(self, {x = 0, y = -1, z = 0}, except_nodes2)
    elseif self.action == "digger_dig_x_pos" then
		dig_block_in_direction(self, {x = 1, y = 0, z = 0}, except_nodes1)
	elseif self.action == "digger_dig_x_neg" then
		dig_block_in_direction(self, {x = -1, y = 0, z = 0}, except_nodes1)
	elseif self.action == "digger_dig_z_neg" then
		dig_block_in_direction(self, {x = 0, y = 0, z = -1}, except_nodes1)
	elseif self.action == "digger_dig_z_pos" then
		dig_block_in_direction(self, {x = 0, y = 0, z = 1}, except_nodes1)
    elseif self.action == "digger_all_direction" then
        dig_all_direction(self)
    elseif self.action == "stand_by" then
        lf("digger:act", "Standing by at mining guide location")
        -- error("")
        put_guide_in_inventory(self, self._guide_pos)
        -- Just stand still, no action needed
	end

	self.action = nil
	self.state = maidroid.states.IDLE
end

-- ,,task
task = function(self)
	-- Add random chance to search for mining guide
	local choice = math.random(6) -- 1-5 for digging, 6 for mining guide
	
	if choice == 6 then
		lf("digger:task", "CHOICE=6: find_and_walk_to_mining_guide")
		lf("digger:task", "Calling find_and_walk_to_mining_guide function")
		find_and_walk_to_mining_guide(self)
		return
	end
	
	if self.is_dig_all_dir == true then
		self.action = "digger_all_direction"
		lf("digger:task", "selected action=" .. tostring(self.action))
		-- local now = minetest.get_gametime()
		-- local last = self._digger_last_task_gametime
		-- if last then
		-- 	lf("digger:task", "task interval=" .. tostring(now - last) .. "s")
		-- end
		-- self._digger_last_task_gametime = now
		return to_action(self)
	end

	self._digger_dig_action_idx = (self._digger_dig_action_idx or 0) + 1
	if self._digger_dig_action_idx > 5 then
		self._digger_dig_action_idx = 1
	end

	local idx = self._digger_dig_action_idx
	if idx == 1 then
		self.action = "digger_dig_x_pos"
	elseif idx == 2 then
		self.action = "digger_dig_x_neg"
	elseif idx == 3 then
		self.action = "digger_dig_z_neg"
	elseif idx == 4 then
		self.action = "digger_dig_z_pos"
	else
		self.action = "digger_dig_y_neg"
	end

	lf("digger:task", "selected idx=" .. tostring(idx) .. " action=" .. tostring(self.action))
	-- local now = minetest.get_gametime()
	-- local last = self._digger_last_task_gametime
	-- if last then
	-- 	lf("digger:task", "task interval=" .. tostring(now - last) .. "s")
	-- end
	-- self._digger_last_task_gametime = now

	return to_action(self)
end



-- ,,step
on_step = function(self, dtime, moveresult)
    self._digger_step_timer = (self._digger_step_timer or 0) + dtime
    if self._digger_step_timer < self._onstep_timer then
        return
    end
    lf("digger:on_step", "digger step timer=" .. tostring(self._digger_step_timer))
    self._digger_step_timer = 0

    -- Handle PATH state by delegating to path core
    if self.state == maidroid.states.PATH then
        lf("digger:on_step", "In PATH state, delegating to path core")
        maidroid.cores.path.on_step(self, dtime, moveresult)
        return
    end

    -- Check if action is stand_by, if yes, take the action then return
    if self.action == "stand_by" then
        lf("digger:on_step", "Taking stand_by action")
        act(self, dtime)
        return
    end

    local pos = self:get_pos()
	-- lf("digger:on_step", "Position: " .. (pos and minetest.pos_to_string(pos) or "nil"))

    -- reset velocity to offset gravity acceleration
	-- if self.object and self.object:get_velocity().y < -1 then
	-- 	local vel = self.object:get_velocity()
	-- 	self.object:set_velocity({x = vel.x, y = math.max(vel.y, -1), z = vel.z})
	-- end

    local vel = self.object:get_velocity()
    self.object:set_velocity({x = vel.x, y = -1, z = vel.z})
    self._onstep_timer = self.onstep_timer_default
	-- get owner safely
	local player = minetest.get_player_by_name(self.owner)




    -- handle_water_below(self, below)     
	-- Check for lava and move up if necessary
	pos = self:get_pos()
    local below = vector.add(pos, { x = 0, y = -1, z = 0 })
    local node_below = minetest.get_node(below)

	if pos and self.object then
		local here = vector.round(pos)
		local here_node = minetest.get_node(here)
		local above = vector.add(here, {x = 0, y = 1, z = 0})
		local node_above = minetest.get_node(above)
		-- local in_liquid = is_liquid(here_node)
		local in_liquid = is_liquid3(here_node, node_below, node_above)
		if in_liquid then
			minetest.log("action", "[maidroid:digger] Emergency escape at " .. minetest.pos_to_string(pos))
			if self._digger_saved_gravity == nil then
				local props = self.object:get_properties()
				self._digger_saved_gravity = props and props.gravity or 1
			end
			if not self._digger_saved_accel then
				self._digger_saved_accel = self.object:get_acceleration()
			end
			move_up_to_closest_air(self)
			minetest.log("action", "[maidroid:digger] Current gravity: " .. tostring(self._digger_saved_gravity))
			minetest.log("action", "[maidroid:digger] Current acceleration: " .. tostring(self._digger_saved_accel))
			-- self.object:set_velocity({x = 0, y = 0, z = 0})
			-- self.object:set_properties({gravity = 0})
			-- self.object:set_acceleration({x = 0, y = 0, z = 0})
		else
            -- restore_gravity_and_accel(self, pos)
		end
	end

    lf("digger:on_step", "After not in liquid")

    -- light need to go below current node detection otherwised will detected current node as light source
    -- and hiding the water
	if pos then
		handle_helper_light(self, pos, player)
	end    

	if not self._digger_accum then
		self._digger_accum = 0
	end
	self._digger_accum = self._digger_accum + dtime
	-- if self._digger_accum < 0.2 then
    --     lf("digger:on_step", "Skipping action: time less " .. tostring(self._digger_accum))
	-- 	return
	-- end
	dtime = self._digger_accum
	self._digger_accum = 0

	player = minetest.get_player_by_name(self.owner)
	-- lf("digger:on_step", "Checking teleport: player=" .. tostring(player and player:get_player_name() or "nil") ..
	-- 	", wielded=" .. tostring(player and player:get_wielded_item():get_name() or "nil"))
    handle_teleport_to_maidroid(self, player)

	local func_name = "digger:on_step"
    -- ,,follow
	if player and is_player_has_follow_item(self) then
		local player_pos = player:get_pos()
        local y = find_first_non_solid_vertically(player_pos)
		-- self.object:set_pos({x = player_pos.x, y = player_pos.y - 1, z = player_pos.z})
        if y then
		self.object:set_pos({x = player_pos.x, y = y.y, z = player_pos.z})
        end
        lf("digger:on_step", "Following player: " .. minetest.pos_to_string(player_pos))
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
		self._digger_step_timer = 0
		self._onstep_timer = 2
		return
	end

	if maidroid.settings.farming_offline == false
		and not minetest.get_player_by_name(self.owner) then
        lf("digger:on_step", "maidroid.settings.farming_offline == false")
		return
	end

	self:pickup_item()

	pos = self:get_pos()
	local min_y = math.floor(pos.y) - 1
	local found = false
	local target_x, target_y
	for y = min_y, min_y - 10, -1 do
		local check_pos = {x = math.floor(pos.x + 0.5), y = y, z = math.floor(pos.z + 0.5)}
		local node = minetest.get_node(check_pos)
		if node and node.name ~= "air" and node.name ~= "ignore" then
			target_x, target_y = check_pos.x, check_pos.y
			found = true
			break
		end
	end
	if not found then
		target_x, target_y = math.floor(pos.x + 0.5), min_y
	end

	if found and self.object and pos then
		self.object:set_pos({x = target_x, y = pos.y, z = math.floor(pos.z + 0.5)})
	end

    	lf("digger:on_step", "Before dig")
	self:set_animation(maidroid.animation.MINE)
	local pos = self:get_pos()
	local p = vector.round(pos)
	local below = vector.add(p, { x = 0, y = -1, z = 0 })

	local node_below = minetest.get_node(below)
	local dist = distance_from_player(self)
	-- ,,lava
	lf("digger:on_step", "node_below: " .. node_below.name .. ", distance from player: " .. tostring(dist or "unknown"))
	if node_below and (node_below.name == "default:lava_source" or node_below.name == "default:lava_flowing") then
		self.object:set_pos({x = pos.x, y = pos.y + 1, z = pos.z})
		minetest.set_node(below, {name = "default:water_source"})
        lf("digger:on_step", "set node to water from lava")
        -- self.timers.dig_below = -2
        -- move_up_one(self)
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
        self._onstep_timer = 5
        move_up_to_closest_air(self)
        return
    	end

	-- ,,m1
	handle_water_below(self, below) 

	node_below = minetest.get_node(below)
	lf("digger:on_step", "after handle_water_below: " .. node_below.name .. ", dig_below: " .. tostring(self.timers.dig_below))
	if node_below and node_below.name == "air" then
		-- self.timers.dig_below = self.timers.dig_below - dtime + 2
		local below2 = vector.add(below, {x = 0, y = -1, z = 0})
		local node_below2 = minetest.get_node(below2)
		self._digger_step_timer = 0
		if node_below2 and node_below2.name == "air" then
			self._onstep_timer = 2
		else
			self._onstep_timer = 0.2
		end
        lf("digger:on_step", "Skipping dig_below: " .. node_below.name .. ", dig_below: " .. tostring(self.timers.dig_below))
        return
    end

    	-- ,,db (cycle one direction per step)
	if self.is_dig_all_dir == true then
		dig_all_direction(self)
		return
	end
	if self.state == maidroid.states.ACT and self.action then
		act(self, dtime)
	else
		task(self)
	end

end


is_tool = function(stack)
	local name = stack:get_name()
	lf("digger:is_tool", "stack  "..name)

	local istool = name == "default:pick_stone" or name == "default:pick_gold" or name == "lottores:goldpick"
	-- local istool = minetest.get_item_group(name, "pickaxe") > 0

	lf("digger:is_tool", "is_tool: "..tostring(istool))
	return istool
	-- return true
end

maidroid.cores.basic.doc = maidroid.cores.basic.doc .. "\t"
	.. S("Digger: pickaxes") .. "\n"


maidroid.register_core("digger", {
	description	= S("a digger"),
	on_start	= on_start,
	on_stop		= on_stop,
	on_resume	= on_resume,
	on_pause	= on_pause,
	on_step		= on_step,
	is_tool		= is_tool,
	alt_tool	= select_seed,
	toggle_jump = true,
	walk_max = 2.5 * timers.walk_max,
	hat = hat,
	can_sell = true,
	doc = doc,
})
-- maidroid.new_state("ACT")

minetest.register_node("maidroid:helper_light", {
    description = "Maidroid Helper Light (Invisible)",
    drawtype = "airlike",
    tiles = {"invisible.png"},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = false,
    light_source = 14,  -- same as torch
    groups = {not_in_creative_inventory = 1},
    selection_box = {
        type = "regular",
    },
})