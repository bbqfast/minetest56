-- Quest System Core API and Data Structures
-- Handles quest tracking, progress, and completion

local lf = assert(_G.lf, "global lf not initialized")

-- Quest definitions database
local quest_definitions = {
    rescue_carlos = {
        id = "rescue_carlos",
        title = "Carlos Rescue Mission",
        description = "Help rescue the lost Carlos LTees and bring them back to safety!",
        story_id = "rescue_carlos",
        objectives = {
            {
                id = "rescue_carlos_count", 
                type = "rescue_ltee_count",
                target_type = "carlos",
                required = 2,
                description = "Rescue 2 Carlos LTees (0/2)",
                reward = {
                    item = "default:diamond",
                    count = 1
                }
            }
        },
        completion_reward = {
            item = "default:mese_crystal",
            count = 2
        }
    },
    rescue_mary = {
        id = "rescue_mary",
        title = "Mary Rescue Mission",
        description = "Help rescue the lost Mary LTees and bring them back to safety!",
        story_id = "rescue_mary",
        objectives = {
            {
                id = "rescue_mary_count",
                type = "rescue_ltee_count",
                target_type = "mary",
                required = 3,
                description = "Rescue 3 Mary LTees (0/3)",
                reward = {
                    item = "default:gold_ingot",
                    count = 5
                }
            }
        },
        completion_reward = {
            item = "default:mese_crystal",
            count = 3
        }
    },
    cheer_up_villagers = {
        id = "cheer_up_villagers",
        title = "Cheer Up the Villagers",
        description = "After a dark fog appeared in our village, our villagers are depressed and don't have energy to fight enemies. Give them flowers to cheer them up so they can fend off hostile enemies!",
        story_id = "cheer_up_villagers",
        objectives = {
            {
                id = "cheer_villagers_count",
                type = "cheer_villager_count",
                required = 5,
                description = "Cheer up 5 distinct villagers (0/5)",
                reward = {
                    item = "default:gold_ingot",
                    count = 5
                }
            }
        }
    }
}

-- Player quest data storage
local player_quests = {}

-- UI state management
local quest_ui_state = {}

-- Helper functions for player metadata
local function get_player_quest_data(player_name)
    if not player_quests[player_name] then
        player_quests[player_name] = {
            active = {},
            completed = {}
        }
    end
    return player_quests[player_name]
end

local function save_player_quest_data(player_name)
    local player = minetest.get_player_by_name(player_name)
    if player then
        local meta = player:get_meta()
        meta:set_string("lottmobs_quests", minetest.serialize(player_quests[player_name]))
    end
end

local function load_player_quest_data(player_name)
    local player = minetest.get_player_by_name(player_name)
    if player then
        local meta = player:get_meta()
        local quest_data = meta:get_string("lottmobs_quests")
        if quest_data and quest_data ~= "" then
            player_quests[player_name] = minetest.deserialize(quest_data) or {active = {}, completed = {}}
        else
            player_quests[player_name] = {active = {}, completed = {}}
        end
    end
    return player_quests[player_name]
end

-- Core quest API
local quest_api = {}

-- Accept a quest
function quest_api.accept_quest(player_name, quest_id)
    local quest_def = quest_definitions[quest_id]
    if not quest_def then
        lf("quest_system", "Quest not found: " .. quest_id)
        return false, "Quest not found"
    end
    
    local quest_data = get_player_quest_data(player_name)
    
    -- Check if already accepted
    if quest_data.active[quest_id] then
        return false, "Quest already accepted"
    end
    
    -- Check if already completed
    if quest_data.completed[quest_id] then
        return false, "Quest already completed"
    end
    
    -- Initialize quest progress
    quest_data.active[quest_id] = {
        rescue_counts = {},
        objectives = {}
    }
    
    -- Initialize objectives
    for _, objective in ipairs(quest_def.objectives) do
        quest_data.active[quest_id].objectives[objective.id] = {
            current = 0,
            required = objective.required,
            completed = false
        }
        
        -- Initialize rescue counts for this type
        if objective.type == "rescue_ltee_count" then
            quest_data.active[quest_id].rescue_counts[objective.target_type] = 0
        end

        -- Initialize distinct cheered villager set for this type
        if objective.type == "cheer_villager_count" then
            quest_data.active[quest_id].cheered_villagers = {}
        end
    end
    
    save_player_quest_data(player_name)
    lf("quest_system", string.format("%s accepted quest: %s", player_name, quest_def.title))
    
    return true, string.format("Quest accepted: %s", quest_def.title)
end

-- Update rescue progress for a quest
function quest_api.update_rescue_progress(player_name, ltee_type, location)
    lf("quest_system", string.format("update_rescue_progress called: player=%s, ltee_type=%s", player_name, ltee_type))
    
    local quest_data = get_player_quest_data(player_name)
    local updated_quests = {}
    
    -- Debug: Log active quests
    local active_quest_ids = {}
    for quest_id, _ in pairs(quest_data.active) do
        table.insert(active_quest_ids, quest_id)
    end
    lf("quest_system", string.format("Active quests for %s: %s", player_name, table.concat(active_quest_ids, ", ")))
    
    -- Check all active quests for rescue objectives
    for quest_id, quest_progress in pairs(quest_data.active) do
        local quest_def = quest_definitions[quest_id]
        if not quest_def then
            goto continue
        end
        
        local quest_updated = false
        
        -- Update rescue count
        if not quest_progress.rescue_counts[ltee_type] then
            quest_progress.rescue_counts[ltee_type] = 0
        end
        quest_progress.rescue_counts[ltee_type] = quest_progress.rescue_counts[ltee_type] + 1
        
        -- Check objectives
        for _, objective in ipairs(quest_def.objectives) do
            if objective.type == "rescue_ltee_count" and objective.target_type == ltee_type then
                local obj_progress = quest_progress.objectives[objective.id]
                if obj_progress and not obj_progress.completed then
                    obj_progress.current = quest_progress.rescue_counts[ltee_type]
                    
                    -- Update description with current progress
                    obj_progress.description = string.format("Rescue %d %s LTees (%d/%d)", 
                        objective.required, 
                        ltee_type:sub(1,1):upper() .. ltee_type:sub(2),
                        obj_progress.current, 
                        objective.required)
                    
                    -- Progress was made, so set quest_updated
                    quest_updated = true
                    
                    -- Check if objective is complete
                    if obj_progress.current >= objective.required then
                        obj_progress.completed = true
                        
                        -- Give objective reward
                        if objective.reward then
                            local player = minetest.get_player_by_name(player_name)
                            if player then
                                local inv = player:get_inventory()
                                local reward_stack = ItemStack(objective.reward.item .. " " .. objective.reward.count)
                                if inv:room_for_item("main", reward_stack) then
                                    inv:add_item("main", reward_stack)
                                    minetest.chat_send_player(player_name, 
                                        string.format("Objective completed! Received: %dx %s", 
                                            objective.reward.count, objective.reward.item))
                                else
                                    minetest.chat_send_player(player_name, "Inventory full! Objective reward dropped.")
                                    minetest.add_item(player:get_pos(), reward_stack)
                                end
                            end
                        end
                        
                        minetest.chat_send_player(player_name, 
                            string.format("Objective completed: %s", obj_progress.description))
                    end
                end
            end
        end
        
        -- Check if all objectives are complete
        local all_complete = true
        for _, objective in ipairs(quest_def.objectives) do
            local obj_progress = quest_progress.objectives[objective.id]
            if not obj_progress or not obj_progress.completed then
                all_complete = false
                break
            end
        end
        
        if all_complete and not quest_updated then
            -- Quest completed!
            quest_data.completed[quest_id] = {
                completed_at = os.time(),
                completion_location = location
            }
            quest_data.active[quest_id] = nil
            
            -- Give completion reward
            if quest_def.completion_reward then
                local player = minetest.get_player_by_name(player_name)
                if player then
                    local inv = player:get_inventory()
                    local reward_stack = ItemStack(quest_def.completion_reward.item .. " " .. quest_def.completion_reward.count)
                    if inv:room_for_item("main", reward_stack) then
                        inv:add_item("main", reward_stack)
                        minetest.chat_send_player(player_name, 
                            string.format("Quest completed! Received: %dx %s", 
                                quest_def.completion_reward.count, quest_def.completion_reward.item))
                    else
                        minetest.chat_send_player(player_name, "Inventory full! Quest reward dropped.")
                        minetest.add_item(player:get_pos(), reward_stack)
                    end
                end
            end
            
            minetest.chat_send_player(player_name, 
                string.format("Quest completed: %s", quest_def.title))
            updated_quests[quest_id] = "completed"
        elseif quest_updated then
            updated_quests[quest_id] = "progress"
        end
        
        ::continue::
    end
    
    save_player_quest_data(player_name)
    
    return updated_quests
end

-- Update cheer villager progress for a quest
function quest_api.update_cheer_villager_progress(player_name, villager_id)
    lf("quest_system", string.format("update_cheer_villager_progress called: player=%s, villager_id=%s", player_name, tostring(villager_id)))

    local quest_data = get_player_quest_data(player_name)
    local updated_quests = {}

    -- Check all active quests for cheer villager objectives
    for quest_id, quest_progress in pairs(quest_data.active) do
        local quest_def = quest_definitions[quest_id]
        if not quest_def then
            goto continue
        end

        local quest_updated = false

        -- Check objectives
        for _, objective in ipairs(quest_def.objectives) do
            if objective.type == "cheer_villager_count" then
                if not quest_progress.cheered_villagers then
                    quest_progress.cheered_villagers = {}
                end

                -- Only count distinct villagers
                if not quest_progress.cheered_villagers[villager_id] then
                    quest_progress.cheered_villagers[villager_id] = true

                    local obj_progress = quest_progress.objectives[objective.id]
                    if obj_progress and not obj_progress.completed then
                        obj_progress.current = obj_progress.current + 1

                        -- Update description with current progress
                        obj_progress.description = string.format("Cheer up %d distinct villagers (%d/%d)",
                            objective.required,
                            obj_progress.current,
                            objective.required)

                        quest_updated = true

                        -- Check if objective is complete
                        if obj_progress.current >= objective.required then
                            obj_progress.completed = true

                            -- Give objective reward
                            if objective.reward then
                                local player = minetest.get_player_by_name(player_name)
                                if player then
                                    local inv = player:get_inventory()
                                    local reward_stack = ItemStack(objective.reward.item .. " " .. objective.reward.count)
                                    if inv:room_for_item("main", reward_stack) then
                                        inv:add_item("main", reward_stack)
                                        minetest.chat_send_player(player_name,
                                            string.format("Objective completed! Received: %dx %s",
                                                objective.reward.count, objective.reward.item))
                                    else
                                        minetest.chat_send_player(player_name, "Inventory full! Objective reward dropped.")
                                        minetest.add_item(player:get_pos(), reward_stack)
                                    end
                                end
                            end

                            minetest.chat_send_player(player_name,
                                string.format("Objective completed: %s", obj_progress.description))
                        end
                    end
                end
            end
        end

        -- Check if all objectives are complete
        local all_complete = true
        for _, objective in ipairs(quest_def.objectives) do
            local obj_progress = quest_progress.objectives[objective.id]
            if not obj_progress or not obj_progress.completed then
                all_complete = false
                break
            end
        end

        if all_complete and not quest_updated then
            -- Quest completed!
            quest_data.completed[quest_id] = {
                completed_at = os.time(),
                completion_location = nil
            }
            quest_data.active[quest_id] = nil

            minetest.chat_send_player(player_name,
                string.format("Quest completed: %s", quest_def.title))
            updated_quests[quest_id] = "completed"
        elseif quest_updated then
            updated_quests[quest_id] = "progress"
        end

        ::continue::
    end

    save_player_quest_data(player_name)

    return updated_quests
end

-- Get quest progress for display
function quest_api.get_quest_progress(player_name, quest_id)
    local quest_data = get_player_quest_data(player_name)
    local quest_def = quest_definitions[quest_id]
    
    if not quest_def then
        return nil, "Quest not found"
    end
    
    if quest_data.completed[quest_id] then
        return {
            status = "completed",
            completed_at = quest_data.completed[quest_id].completed_at
        }
    end
    
    local active_quest = quest_data.active[quest_id]
    if not active_quest then
        return {
            status = "not_accepted"
        }
    end
    
    local objectives = {}
    for _, objective_def in ipairs(quest_def.objectives) do
        local obj_progress = active_quest.objectives[objective_def.id]
        if obj_progress then
            table.insert(objectives, {
                id = objective_def.id,
                description = obj_progress.description or objective_def.description,
                current = obj_progress.current,
                required = obj_progress.required,
                completed = obj_progress.completed
            })
        end
    end
    
    return {
        status = "active",
        title = quest_def.title,
        description = quest_def.description,
        objectives = objectives,
        rescue_counts = active_quest.rescue_counts
    }
end

-- Get all active quests for a player
function quest_api.get_active_quests(player_name)
    local quest_data = get_player_quest_data(player_name)
    local active_quests = {}
    
    for quest_id, _ in pairs(quest_data.active) do
        local progress = quest_api.get_quest_progress(player_name, quest_id)
        if progress then
            active_quests[quest_id] = progress
        end
    end
    
    return active_quests
end

-- Get all completed quests for a player
function quest_api.get_completed_quests(player_name)
    local quest_data = get_player_quest_data(player_name)
    local completed_quests = {}
    
    for quest_id, completion_data in pairs(quest_data.completed) do
        local quest_def = quest_definitions[quest_id]
        if quest_def then
            completed_quests[quest_id] = {
                title = quest_def.title,
                description = quest_def.description,
                completed_at = completion_data.completed_at
            }
        end
    end
    
    return completed_quests
end

-- Cancel a quest
function quest_api.cancel_quest(player_name, quest_id)
    local quest_data = get_player_quest_data(player_name)
    
    if not quest_data.active[quest_id] then
        return false, "Quest not found or not active"
    end
    
    -- Remove the quest from active quests
    quest_data.active[quest_id] = nil
    save_player_quest_data(player_name)
    
    local quest_def = quest_definitions[quest_id]
    local quest_title = quest_def and quest_def.title or quest_id
    
    lf("quest_system", string.format("%s cancelled quest: %s", player_name, quest_title))
    
    return true, string.format("Quest cancelled: %s", quest_title)
end

-- Show quest status to player
function quest_api.show_quest_status(player_name)
    local active_quests = quest_api.get_active_quests(player_name)
    local completed_quests = quest_api.get_completed_quests(player_name)
    
    minetest.chat_send_player(player_name, "=== Quest Status ===")
    
    if next(active_quests) then
        minetest.chat_send_player(player_name, "Active Quests:")
        for quest_id, quest_data in pairs(active_quests) do
            minetest.chat_send_player(player_name, string.format("- %s", quest_data.title))
            for _, objective in ipairs(quest_data.objectives) do
                local status = objective.completed and "✓" or "○"
                minetest.chat_send_player(player_name, string.format("  %s %s", status, objective.description))
            end
        end
    else
        minetest.chat_send_player(player_name, "No active quests")
    end
    
    if next(completed_quests) then
        minetest.chat_send_player(player_name, "Completed Quests:")
        for quest_id, quest_data in pairs(completed_quests) do
            minetest.chat_send_player(player_name, string.format("- ✓ %s", quest_data.title))
        end
    end
end

-- Register the quest API globally
lottmobs_quest_api = quest_api

-- Load quest data when player joins
minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    load_player_quest_data(player_name)
    lf("quest_system", "Loaded quest data for player: " .. player_name)
end)

-- Save quest data when player leaves
minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    save_player_quest_data(player_name)
    lf("quest_system", "Saved quest data for player: " .. player_name)
end)

-- Story UI
local function show_story_ui(player_name, quest_id)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end
    
    local quest_def = quest_definitions[quest_id]
    if not quest_def then
        minetest.chat_send_player(player_name, "Quest not found")
        return
    end
    
    -- Get story data
    local story_data = nil
    if lottmobs_quest_stories then
        story_data = lottmobs_quest_stories.get_story(quest_def.story_id)
    end
    
    if not story_data then
        minetest.chat_send_player(player_name, "Story not found for this quest")
        return
    end
    
    -- Build story formspec
    local formspec = "size[12,10]" ..
        "label[0,0;" .. story_data.title .. "]" ..
        "textarea[0.5,1;11,7.5;story;;" .. story_data.story .. "]" ..
        "button[2,9;2.5,0.8;accept_quest;" .. story_data.accept_text .. "]" ..
        "button[5,9;2.5,0.8;reject_quest;" .. story_data.reject_text .. "]" ..
        "button[8,9;2,0.8;back;Back]"
    
    -- Store current quest for accept/reject handling
    quest_ui_state[player_name] = {
        type = "story_view",
        quest_id = quest_id
    }
    
    minetest.show_formspec(player_name, "lottmobs:quest_story", formspec)
    lf("quest_system", "Showing story UI for quest: " .. quest_id)
end

-- Quest Book UI
local function show_quest_book_ui(player_name)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end
    
    local active_quests = quest_api.get_active_quests(player_name)
    local completed_quests = quest_api.get_completed_quests(player_name)
    
    -- Build formspec content
    local formspec = "size[10,8]" ..
        "label[0,0;Quest Book]" ..
        "label[0,0.5;Active Quests:]"
    
    local y_offset = 1
    local quest_buttons = {}
    
    -- Display active quests
    if next(active_quests) then
        for quest_id, quest_data in pairs(active_quests) do
            local quest_text = string.format("%s", quest_data.title)
            formspec = formspec .. string.format("button[0,%s;6,0.8;quest_%s;%s]", 
                y_offset, quest_id, quest_text)
            
            -- Show objectives
            local obj_y = y_offset + 0.8
            for _, objective in ipairs(quest_data.objectives) do
                local status = objective.completed and "✓" or "○"
                local obj_text = string.format("  %s %s", status, objective.description)
                formspec = formspec .. string.format("label[0.2,%s;%s]", obj_y, obj_text)
                obj_y = obj_y + 0.4
            end
            
            -- Cancel quest button
            formspec = formspec .. string.format("button[6,%s;1.5,0.8;cancel_%s;Cancel]", 
                y_offset, quest_id)
            
            y_offset = obj_y + 0.2
            quest_buttons[quest_id] = y_offset
        end
    else
        formspec = formspec .. "label[0,1;No active quests]"
        y_offset = 2
    end
    
    -- Display available quests with story buttons
    formspec = formspec .. string.format("label[0,%s;Available Quests:]", y_offset + 0.5)
    y_offset = y_offset + 1
    
    local available_count = 0
    for quest_id, quest_def in pairs(quest_definitions) do
        if not active_quests[quest_id] and not completed_quests[quest_id] then
            formspec = formspec .. string.format(
                "button[0,%s;4,0.8;story_%s;Read Story]" ..
                "label[4.5,%s;%s]",
                y_offset, quest_id, y_offset, quest_def.title
            )
            y_offset = y_offset + 1
            available_count = available_count + 1
        end
    end
    
    if available_count == 0 then
        formspec = formspec .. string.format("label[0,%s;No available quests]", y_offset)
        y_offset = y_offset + 0.5
    end
    
    -- Display completed quests
    formspec = formspec .. string.format("label[0,%s;Completed Quests:]", y_offset + 0.5)
    y_offset = y_offset + 1
    
    if next(completed_quests) then
        for quest_id, quest_data in pairs(completed_quests) do
            local completed_text = string.format("✓ %s", quest_data.title)
            formspec = formspec .. string.format("label[0,%s;%s]", y_offset, completed_text)
            y_offset = y_offset + 0.4
        end
    else
        formspec = formspec .. string.format("label[0,%s;No completed quests]", y_offset)
    end
    
    -- Close button
    formspec = formspec .. "button[4,7.5;2,0.8;close;Close]"
    
    minetest.show_formspec(player_name, "lottmobs:quest_book", formspec)
end

-- Quest Book Item
minetest.register_craftitem("lottmobs:quest_book", {
    description = "Quest Book",
    inventory_image = "default_book.png",
    groups = {book = 1},
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        show_quest_book_ui(player_name)
        return itemstack
    end,
})

-- Handle quest book formspec responses
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "lottmobs:quest_book" then return false end
    
    local player_name = player:get_player_name()
    
    -- Handle story buttons
    for field_name, _ in pairs(fields) do
        if string.match(field_name, "^story_") then
            local quest_id = string.sub(field_name, 7) -- Remove "story_" prefix
            if quest_id then
                show_story_ui(player_name, quest_id)
                return true
            end
        end
    end
    
    -- Handle cancel quest buttons
    for field_name, _ in pairs(fields) do
        if string.match(field_name, "^cancel_") then
            local quest_id = string.sub(field_name, 8) -- Remove "cancel_" prefix
            if quest_id then
                -- Show confirmation dialog
                local quest_data = quest_api.get_quest_progress(player_name, quest_id)
                if quest_data and quest_data.status == "active" then
                    local confirm_formspec = "size[6,3]" ..
                        "label[0,0;Cancel Quest?]" ..
                        string.format("label[0,0.5;Are you sure you want to cancel: %s?]", quest_data.title) ..
                        "label[0,1;All progress will be lost!]" ..
                        "button[1,2;1.5,0.8;confirm_cancel_" .. quest_id .. ";Yes]" ..
                        "button[3.5,2;1.5,0.8;no_cancel;No]"
                    
                    minetest.show_formspec(player_name, "lottmobs:quest_cancel_confirm", confirm_formspec)
                end
            end
        elseif field_name == "close" then
            -- Close the formspec
            minetest.close_formspec(player_name, "lottmobs:quest_book")
        end
    end
    
    return true
end)

-- Handle quest cancellation confirmation
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "lottmobs:quest_cancel_confirm" then return false end
    
    local player_name = player:get_player_name()
    
    for field_name, _ in pairs(fields) do
        if string.match(field_name, "^confirm_cancel_") then
            local quest_id = string.sub(field_name, 16) -- Remove "confirm_cancel_" prefix
            if quest_id then
                -- Cancel the quest using the API
                local success, message = quest_api.cancel_quest(player_name, quest_id)
                if success then
                    minetest.chat_send_player(player_name, message)
                    
                    -- Reopen the quest book to show updated state
                    show_quest_book_ui(player_name)
                else
                    minetest.chat_send_player(player_name, message)
                end
            end
        elseif field_name == "no_cancel" then
            -- Return to quest book
            show_quest_book_ui(player_name)
        end
    end
    
    return true
end)

-- Handle story UI formspec responses
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "lottmobs:quest_story" then return false end
    
    local player_name = player:get_player_name()
    local ui_state = quest_ui_state[player_name]
    
    if not ui_state or ui_state.type ~= "story_view" then
        return false
    end
    
    local quest_id = ui_state.quest_id
    
    -- Handle accept quest
    if fields.accept_quest then
        local success, message = quest_api.accept_quest(player_name, quest_id)
        if success then
            minetest.chat_send_player(player_name, message)
            show_quest_book_ui(player_name)
        else
            minetest.chat_send_player(player_name, message)
        end
        return true
    end
    
    -- Handle reject quest
    if fields.reject_quest then
        minetest.chat_send_player(player_name, "Quest rejected.")
        show_quest_book_ui(player_name)
        return true
    end
    
    -- Handle back button
    if fields.back then
        show_quest_book_ui(player_name)
        return true
    end
    
    return false
end)

-- Quest Book Crafting Recipe
minetest.register_craft({
    output = "lottmobs:quest_book",
    recipe = {
        {"default:paper", "default:paper", "default:paper"},
        {"default:paper", "default:book", "default:paper"},
        {"default:paper", "default:paper", "default:paper"}
    }
})

lf("quest_system", "Quest system module loaded")
