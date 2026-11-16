-- ItemLtee NPC Entity
-- An NPC that requests specific items from players

local lf = assert(_G.lf, "global lf not initialized")

-- ItemLtee dialogue
local item_ltee_dialogues = {
    greeting = "Greetings! I'm looking for some specific items. Can you help me?",
    thank_you = "Thank you for your help!",
    need_more = "I still need more items. Please check the list.",
}

-- Default requested items for itemLtee
local default_requested_items = {
    {name = "default:gold_ingot", count = 3},
    {name = "lottores:silver_ingot", count = 3},
}

-- Create detached inventory for itemLtee
function lottmobs.create_item_ltee_inventory(entity_id)
    lf("item_ltee", "Creating inventory for itemLtee: " .. tostring(entity_id))
    
    local inventory = minetest.create_detached_inventory(entity_id, {
        allow_take = function(inv, listname, index, stack, player)
            -- Players cannot take items from the requested list
            return 0
        end,
        allow_put = function(inv, listname, index, stack, player)
            -- Players can put items into the payment slot
            if listname == "payment" then
                lf("item_ltee", "allow_put: Player " .. player:get_player_name() .. " attempting to put " .. stack:to_string() .. " into payment slot")
                return stack:get_count()
            end
            return 0
        end,
        allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
            -- Prevent moving items
            return 0
        end,
        on_put = function(inv, listname, index, stack, player)
            if listname == "payment" then
                lf("item_ltee", "on_put: Player " .. player:get_player_name() .. " put " .. stack:to_string() .. " into payment slot at index " .. index)
                lottmobs.check_item_ltee_payment(inv, player)
            end
        end
    })
    
    -- Set up inventory lists
    inventory:set_size("requested", 15)  -- List of requested items
    inventory:set_size("payment", 1)     -- Player payment slot
    
    -- Add default requested items
    for i, item in ipairs(default_requested_items) do
        inventory:set_stack("requested", i, ItemStack(item.name .. " " .. item.count))
    end
    
    return inventory
end

-- Check if player has provided the requested items
function lottmobs.check_item_ltee_payment(inv, player)
    lf("item_ltee", "=== Starting payment check for player: " .. player:get_player_name() .. " ===")
    
    local payment_stack = inv:get_stack("payment", 1)
    lf("item_ltee", "Payment stack: " .. (payment_stack:is_empty() and "EMPTY" or payment_stack:to_string()))
    
    if payment_stack:is_empty() then
        lf("item_ltee", "Payment stack is empty, returning")
        return
    end
    
    local payment_name = payment_stack:get_name()
    local payment_count = payment_stack:get_count()
    lf("item_ltee", "Payment details - Name: " .. payment_name .. ", Count: " .. payment_count)
    
    -- Check if this item is in the requested list
    local requested_list = inv:get_list("requested")
    lf("item_ltee", "Requested list has " .. #requested_list .. " slots")
    
    for i, stack in ipairs(requested_list) do
        lf("item_ltee", "Checking requested slot " .. i .. ": " .. (stack:is_empty() and "EMPTY" or stack:to_string()))
        
        if not stack:is_empty() and stack:get_name() == payment_name then
            local requested_count = stack:get_count()
            lf("item_ltee", "MATCH FOUND! Requested: " .. payment_name .. " x" .. requested_count .. ", Payment: " .. payment_name .. " x" .. payment_count)
            
            if payment_count >= requested_count then
                lf("item_ltee", "Payment sufficient (" .. payment_count .. " >= " .. requested_count .. "), taking required amount and returning excess")
                -- Item provided - remove from requested list
                inv:set_stack("requested", i, nil)
                
                -- Return excess items to player if payment exceeds requirement
                if payment_count > requested_count then
                    local excess_count = payment_count - requested_count
                    local excess_stack = ItemStack(payment_name .. " " .. excess_count)
                    local player_inv = player:get_inventory()
                    
                    if player_inv:room_for_item("main", excess_stack) then
                        player_inv:add_item("main", excess_stack)
                        lf("item_ltee", "Returned " .. excess_count .. " excess " .. payment_name .. " to player")
                        minetest.chat_send_player(player:get_player_name(), 
                            "<ItemLtee> Thank you! I took " .. requested_count .. " and returned " .. excess_count .. " to you.")
                    else
                        -- Drop excess on ground if player inventory is full
                        local pos = player:get_pos()
                        minetest.add_item(pos, excess_stack)
                        lf("item_ltee", "Dropped " .. excess_count .. " excess " .. payment_name .. " on ground (inventory full)")
                        minetest.chat_send_player(player:get_player_name(), 
                            "<ItemLtee> Thank you! I took " .. requested_count .. " and dropped " .. excess_count .. " on the ground (your inventory is full).")
                    end
                else
                    minetest.chat_send_player(player:get_player_name(), 
                        "<ItemLtee> " .. item_ltee_dialogues.thank_you)
                end
                
                -- Clear payment slot
                inv:set_stack("payment", 1, nil)
                lf("item_ltee", "Player provided " .. payment_name .. " x" .. payment_count .. ", took " .. requested_count .. ", request fulfilled")
                return
            else
                -- Accept partial payment
                lf("item_ltee", "Partial payment accepted (" .. payment_count .. " of " .. requested_count .. "), reducing required amount")
                local remaining_count = requested_count - payment_count
                inv:set_stack("requested", i, ItemStack(payment_name .. " " .. remaining_count))
                inv:set_stack("payment", 1, nil)
                minetest.chat_send_player(player:get_player_name(), 
                    "<ItemLtee> I accepted " .. payment_count .. " " .. payment_name .. ". I still need " .. remaining_count .. " more.")
                lf("item_ltee", "Reduced request from " .. requested_count .. " to " .. remaining_count .. " " .. payment_name)
                return
            end
        end
    end
    
    lf("item_ltee", "No matching request found for " .. payment_name)
    minetest.chat_send_player(player:get_player_name(), 
        "<ItemLtee> That's not what I need right now.")
    lf("item_ltee", "=== Payment check complete ===")
end

-- ItemLtee NPC definition
local item_ltee_def = {
    type = "npc",
    race = "ITEM_LTEE",
    hp_min = 20,
    hp_max = 25,
    collisionbox = {-0.3, -0.75, -0.3, 0.3, 0.7, 0.3},
    visual = "mesh",
    mesh = "character.b3d",
    textures = {{"character_Carlos_LT_third_LT_stolen_mt.png"}}, -- Using Carlos texture as itemLtee
    nametag = "ItemLtee",
    nametag_color = {r = 255, g = 165, b = 0, a = 255}, -- Orange color
    
    -- Movement and behavior
    view_range = 10,
    walk_velocity = 0,
    run_velocity = 0,
    armor = 100,
    damage = 0,
    
    -- Environmental properties
    light_resistant = true,
    drawtype = "front",
    water_damage = 0,
    lava_damage = 0,
    light_damage = 0,
    
    -- Peaceful behavior
    peaceful = true,
    passive = true,
    attack_type = "none",
    group_attack = false,
    step = 1,
    
    -- Animations
    animation = {
        speed_normal = 15,
        speed_run = 20,
        stand_start = 0,
        stand_end = 79,
        walk_start = 168,
        walk_end = 187,
        run_start = 168,
        run_end = 187,
        punch_start = 189,
        punch_end = 198,
        sit_start = 81,
        sit_end = 160,
    },
    
    -- Drops
    drops = {
        {name = "default:gold_ingot", chance = 10, min = 1, max = 2},
    },
    
    -- Sounds
    sounds = {
        war_cry = "mobs_yell",
        death = "default_death",
        attack = "mobs_slash_attack",
    },
    
    -- Initialize itemLtee
    on_activate = function(self)
        self.dialogue_timer = 0
        lf("item_ltee", "ItemLtee activated")
    end,
    
    -- Right-click interaction to show requested items
    on_rightclick = function(self, clicker)
        local player_name = clicker:get_player_name()
        
        -- Generate unique entity ID if not set
        if self.id == 0 or self.id == nil then
            self.id = (math.random(1, 1000) * math.random(1, 10000)) .. self.name .. (math.random(1, 1000) ^ 2)
        end
        
        local unique_entity_id = self.id
        lf("item_ltee", "ItemLtee ID: " .. tostring(unique_entity_id))
        
        -- Check if inventory exists, create if not
        local inventory = minetest.get_inventory({type="detached", name=unique_entity_id})
        if inventory == nil then
            inventory = lottmobs.create_item_ltee_inventory(unique_entity_id)
        end
        
        -- Show greeting message
        minetest.chat_send_player(player_name, "<ItemLtee> " .. item_ltee_dialogues.greeting)
        
        -- Show the itemLtee UI
        minetest.show_formspec(player_name, "item_ltee:" .. unique_entity_id,
            "size[8,9;]" ..
            "label[0,0;ItemLtee's Requested Items:]" ..
            "list[detached:" .. unique_entity_id .. ";requested;.5,.5;3,5;]" ..
            "label[4.5,0.5;Your Payment]" ..
            "list[detached:" .. unique_entity_id .. ";payment;4.5,1;5.5,2;]" ..
            "label[0,6;Place items in payment slot to fulfill requests]" ..
            "list[current_player;main;0,6.5;8,4;]"
        )
    end,
    
    -- Custom behavior: periodic greetings
    do_custom = function(self, dtime)
        self.dialogue_timer = (self.dialogue_timer or 0) + dtime
        
        -- Greet nearby players every 30 seconds
        if self.dialogue_timer >= 30 then
            self.dialogue_timer = 0
            
            local pos = self.object:get_pos()
            if pos then
                for _, player in ipairs(minetest.get_objects_inside_radius(pos, 5)) do
                    if player:is_player() then
                        local player_name = player:get_player_name()
                        minetest.chat_send_player(player_name, 
                            "<ItemLtee> " .. item_ltee_dialogues.greeting)
                        break
                    end
                end
            end
        end
    end,
    
    -- On death
    on_die = function(self)
        lf("item_ltee", "ItemLtee died")
    end,
}

-- Register the itemLtee NPC
mobs:register_mob("lottmobs:item_ltee", item_ltee_def)

-- Register spawn egg for itemLtee
mobs:register_egg("lottmobs:item_ltee", "ItemLtee", 
                 "default_gold_block.png", 0)

-- Chat command to spawn itemLtee (for testing/admin)
minetest.register_chatcommand("spawn_item_ltee", {
    description = "Spawns an ItemLtee NPC",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then 
            return false, "Player not found" 
        end
        
        local pos = vector.add(player:get_pos(), {x = 2, y = 0, z = 0})
        local obj = minetest.add_entity(pos, "lottmobs:item_ltee")
        
        if obj then
            lf("item_ltee", string.format("ItemLtee spawned at x=%d y=%d z=%d", pos.x, pos.y, pos.z))
            return true, "ItemLtee spawned."
        else
            return false, "Failed to spawn ItemLtee."
        end
    end,
})

lf("item_ltee", "ItemLtee module loaded")
