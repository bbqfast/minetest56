-- Quest System Testing Module
-- Provides commands to test quest functionality

local lf = assert(_G.lf, "global lf not initialized")

-- Test command to simulate rescue events
minetest.register_chatcommand("test_quest_rescue", {
    description = "Test quest system by simulating an LTee rescue",
    params = "<ltee_type> <count>",
    func = function(name, param)
        if not lottmobs_quest_api then
            return false, "Quest system not available"
        end
        
        local ltee_type, count_str = param:match("(%w+)%s+(%d+)")
        if not ltee_type or not count_str then
            return false, "Usage: /test_quest_rescue <ltee_type> <count> (e.g., /test_quest_rescue mary 1)"
        end
        
        local count = tonumber(count_str)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        -- First accept the appropriate quest if not already accepted
        local active_quests = lottmobs_quest_api.get_active_quests(name)
        local quest_id = "rescue_" .. ltee_type
        if not active_quests[quest_id] then
            local success, message = lottmobs_quest_api.accept_quest(name, quest_id)
            if not success then
                return false, "Failed to accept quest: " .. message
            end
            minetest.chat_send_player(name, "Quest accepted for testing")
        end
        
        -- Simulate rescues
        for i = 1, count do
            local updated_quests = lottmobs_quest_api.update_rescue_progress(
                name, 
                ltee_type, 
                player:get_pos()
            )
            
            minetest.chat_send_player(name, 
                string.format("Simulated rescue %d of %s LTee", i, ltee_type))
        end
        
        -- Show final status
        lottmobs_quest_api.show_quest_status(name)
        
        return true, string.format("Simulated %d rescues of %s LTee", count, ltee_type)
    end,
})

-- Test command to reset quest progress
minetest.register_chatcommand("test_quest_reset", {
    description = "Reset quest progress for testing",
    func = function(name)
        if not lottmobs_quest_api then
            return false, "Quest system not available"
        end
        
        local player = minetest.get_player_by_name(name)
        if player then
            local meta = player:get_meta()
            meta:set_string("lottmobs_quests", "")
            -- Clear from memory
            if player_quests and player_quests[name] then
                player_quests[name] = {active = {}, completed = {}}
            end
        end
        
        return true, "Quest progress reset"
    end,
})

-- Test command to spawn test scenario
minetest.register_chatcommand("test_quest_scenario", {
    description = "Spawn a complete test scenario with quest giver and rescueable LTees",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local spawned = {}
        
        -- Spawn quest giver
        local quest_giver_pos = vector.add(pos, {x = 2, y = 0, z = 0})
        local quest_giver = minetest.add_entity(quest_giver_pos, "lottmobs:quest_giver")
        if quest_giver then
            table.insert(spawned, "Quest Giver")
        end
        
        -- Spawn rescueable Mary LTees
        for i = 1, 2 do
            local mary_pos = vector.add(pos, {x = -2 - i*2, y = 0, z = 0})
            local mary = minetest.add_entity(mary_pos, "lottmobs:rescueable_mary_ltee")
            if mary then
                table.insert(spawned, "Mary LTee " .. i)
            end
        end
        
        -- Spawn rescueable Carlos LTees
        for i = 1, 1 do
            local carlos_pos = vector.add(pos, {x = 0, y = 0, z = 2 + i*2})
            local carlos = minetest.add_entity(carlos_pos, "lottmobs:rescueable_carlos_ltee")
            if carlos then
                table.insert(spawned, "Carlos LTee " .. i)
            end
        end
        
        minetest.chat_send_player(name, "Test scenario spawned:")
        for _, entity in ipairs(spawned) do
            minetest.chat_send_player(name, "- " .. entity)
        end
        minetest.chat_send_player(name, "Use the Quest Giver or Quest Book to accept quests, then rescue LTees with rescue bag!")
        
        return true, "Test scenario spawned with " .. #spawned .. " entities"
    end,
})

-- Test command to open quest UI
minetest.register_chatcommand("test_quest_ui", {
    description = "Test the quest UI interface",
    func = function(name)
        if not lottmobs_quest_ui then
            return false, "Quest UI not available"
        end
        
        lottmobs_quest_ui.show_available_quests(name)
        return true, "Quest UI opened"
    end,
})


-- Command to clean up old rescue_multiple quest data
minetest.register_chatcommand("cleanup_old_quests", {
    description = "Remove old rescue_multiple quest data and migrate to new quests",
    func = function(name)
        if not lottmobs_quest_api then
            return false, "Quest system not available"
        end
        
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        -- Get player's meta to directly modify quest data
        local meta = player:get_meta()
        local quest_data_str = meta:get_string("lottmobs_quests")
        
        if quest_data_str and quest_data_str ~= "" then
            local quest_data = minetest.deserialize(quest_data_str)
            if quest_data then
                local removed_old = false
                
                -- Remove old rescue_multiple quest from active quests
                if quest_data.active and quest_data.active["rescue_multiple"] then
                    quest_data.active["rescue_multiple"] = nil
                    removed_old = true
                    minetest.chat_send_player(name, "Removed old rescue_multiple quest")
                end
                
                -- Remove old rescue_multiple quest from completed quests
                if quest_data.completed and quest_data.completed["rescue_multiple"] then
                    quest_data.completed["rescue_multiple"] = nil
                    removed_old = true
                    minetest.chat_send_player(name, "Removed old rescue_multiple quest from completed")
                end
                
                if removed_old then
                    -- Save the cleaned quest data
                    meta:set_string("lottmobs_quests", minetest.serialize(quest_data))
                    minetest.chat_send_player(name, "Old quest data cleaned up successfully!")
                else
                    minetest.chat_send_player(name, "No old rescue_multiple quest found to clean up")
                end
                
                -- Show current active quests
                local active_quests = lottmobs_quest_api.get_active_quests(name)
                if next(active_quests) then
                    minetest.chat_send_player(name, "Current active quests:")
                    for quest_id, _ in pairs(active_quests) do
                        minetest.chat_send_player(name, "- " .. quest_id)
                    end
                else
                    minetest.chat_send_player(name, "No active quests")
                end
                
                return true, "Quest cleanup completed"
            end
        end
        
        return false, "No quest data found"
    end,
})

-- Main test UI command
minetest.register_chatcommand("test", {
    description = "Open the test UI with all available test commands",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local formspec = {
            "formspec_version[4]",
            "size[16,14]",
            "label[0.5,0.5;Test Command Interface]",
            "label[0.5,1;Quest System Tests]",
            "button[0.5,1.5;5,0.8;test_quest_reset;Reset Quest Progress]",
            "button[0.5,3.5;5,0.8;cleanup_old_quests;Cleanup Old Quests]",
            "button[0.5,4.5;5,0.8;quest_status;Check Quest Status]",
            "label[0.5,5.5;Spawn Commands]",
            "button[0.5,6;5,0.8;spawn_quest_giver;Spawn Quest Giver]",
            "button[0.5,7;5,0.8;spawn_rescueable_mary;Spawn Mary LTee]",
            "button[0.5,8;5,0.8;spawn_rescueable_carlos;Spawn Carlos LTee]",
            "label[6.5,1;Scenario Tests]",
            "button[6.5,1.5;5,0.8;test_quest_scenario;Spawn Test Scenario]",
            "label[6.5,2.5;Custom Rescue Test]",
            "field[6.5,3.5;2,0.8;rescue_type;Type;mary]",
            "field[9,3.5;2,0.8;rescue_count;Count;1]",
            "button[6.5,4;5,0.8;test_custom_rescue;Simulate Rescue]",
            "label[6.5,5;Rescueable LTee System]",
            "button[6.5,5.5;5,0.8;spawn_rescueable_ltee;Spawn Mary (Legacy)]",
            "label[6.5,6.5;Instructions]",
            "textarea[6.5,7;5,4;;Click buttons to execute test commands. Custom rescue test requires type (mary/carlos) and count. Press ESC to close.]"
        }
        
        minetest.show_formspec(name, "lottmobs:test_ui", table.concat(formspec, ""))
        return true, "Test UI opened"
    end,
})

-- Handle formspec responses
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "lottmobs:test_ui" then
        return false
    end
    
    local name = player:get_player_name()
    local should_reopen = false
    
    -- Quest UI tests
    if fields.test_quest_reset then
        minetest.chatcommands["test_quest_reset"].func(name, "")
        should_reopen = true
    elseif fields.cleanup_old_quests then
        minetest.chatcommands["cleanup_old_quests"].func(name, "")
        should_reopen = true
    elseif fields.quest_status then
        minetest.chatcommands["quest_status"].func(name, "")
        should_reopen = true
    -- Spawn commands
    elseif fields.spawn_quest_giver then
        minetest.chatcommands["spawn_quest_giver"].func(name, "")
        should_reopen = true
    elseif fields.spawn_rescueable_mary then
        minetest.chatcommands["spawn_rescueable_mary_ltee"].func(name, "")
        should_reopen = true
    elseif fields.spawn_rescueable_carlos then
        minetest.chatcommands["spawn_rescueable_carlos_ltee"].func(name, "")
        should_reopen = true
    elseif fields.spawn_rescueable_ltee then
        minetest.chatcommands["spawn_rescueable_ltee"].func(name, "")
        should_reopen = true
    -- Scenario tests
    elseif fields.test_quest_scenario then
        minetest.chatcommands["test_quest_scenario"].func(name, "")
        should_reopen = true
    -- Custom rescue test
    elseif fields.test_custom_rescue then
        local ltee_type = fields.rescue_type or "mary"
        local count = tonumber(fields.rescue_count) or 1
        minetest.chatcommands["test_quest_rescue"].func(name, ltee_type .. " " .. count)
        should_reopen = true
    end
    
    -- Only reopen if a test button was clicked
    if should_reopen then
        minetest.after(0.1, function()
            local p = minetest.get_player_by_name(name)
            if p then
                minetest.chatcommands["test"].func(name, "")
            end
        end)
        return true
    end
    
    return true
end)

lf("quest_test", "Quest testing module loaded")
