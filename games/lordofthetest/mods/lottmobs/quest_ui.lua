-- Quest UI System
-- Provides formspec-based interface for quest management

local lf = assert(_G.lf, "global lf not initialized")

-- UI state management
local quest_ui_state = {}

-- Quest UI table
local quest_ui = {}

-- Helper function to get formspec background
local function get_background_formspec(width, height)
    return string.format(
        "size[%s,%s]" ..
        "bgcolor[#808080;true]",
        width, height
    )
end

-- Show story UI
local function show_story_ui(player_name, quest_id, story_data)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end
    
    -- Build story formspec
    local formspec = get_background_formspec(12, 10)
    formspec = formspec .. "label[2,0.5;" .. story_data.title .. "]"
    formspec = formspec .. "textarea[0.5,1.5;11,7;story;;" .. story_data.story .. "]"
    formspec = formspec .. string.format(
        "button[2,9;2.5,0.8;accept_quest;%s]" ..
        "button[5,9;2.5,0.8;reject_quest;%s]" ..
        "button[8,9;2,0.8;back;Back]",
        story_data.accept_text, story_data.reject_text
    )
    
    -- Store current quest for accept/reject handling
    quest_ui_state[player_name] = {
        type = "story_view",
        quest_id = quest_id
    }
    
    minetest.show_formspec(player_name, "lottmobs:quest_story", formspec)
    lf("quest_ui", "Showing story UI for quest: " .. quest_id)
end

-- Show available quests UI
function quest_ui.show_available_quests(player_name)
    if not lottmobs_quest_api then
        minetest.chat_send_player(player_name, "Quest system not available")
        return
    end
    
    local player = minetest.get_player_by_name(player_name)
    if not player then
        return
    end
    
    local active_quests = lottmobs_quest_api.get_active_quests(player_name)
    local completed_quests = lottmobs_quest_api.get_completed_quests(player_name)
    
    -- Build quest list formspec
    local formspec = get_background_formspec(10, 8)
    formspec = formspec .. "label[2,0.5;Quest Giver]"
    formspec = formspec .. "label[1,1.5;Available Quests:]"
    
    local y_offset = 2.5
    
    -- Check if rescue_carlos quest is available
    if not active_quests["rescue_carlos"] and not completed_quests["rescue_carlos"] then
        formspec = formspec .. string.format(
            "button[0.5,%s;0.8,0.7;story_rescue_carlos;Story]" ..
            "button[1.3,%s;0.9,0.7;accept_rescue_carlos;Accept]" ..
            "label[2.3,%s;Carlos Rescue Mission]" ..
            "label[2.3,%s;Rescue 2 Carlos LTees and bring them to safety!]",
            y_offset, y_offset, y_offset, y_offset + 0.6
        )
        y_offset = y_offset + 1.5
    end
    
    -- Check if rescue_mary quest is available
    if not active_quests["rescue_mary"] and not completed_quests["rescue_mary"] then
        formspec = formspec .. string.format(
            "button[0.5,%s;0.8,0.7;story_rescue_mary;Story]" ..
            "button[1.3,%s;0.9,0.7;accept_rescue_mary;Accept]" ..
            "label[2.3,%s;Mary Rescue Mission]" ..
            "label[2.3,%s;Rescue 3 Mary LTees and bring them to safety!]",
            y_offset, y_offset, y_offset, y_offset + 0.6
        )
        y_offset = y_offset + 1.5
    end

    -- Check if cheer_up_villagers quest is available
    if not active_quests["cheer_up_villagers"] and not completed_quests["cheer_up_villagers"] then
        formspec = formspec .. string.format(
            "button[0.5,%s;0.8,0.7;story_cheer_up_villagers;Story]" ..
            "button[1.3,%s;0.9,0.7;accept_cheer_up_villagers;Accept]" ..
            "label[2.3,%s;Cheer Up the Villagers]" ..
            "label[2.3,%s;Cheer up 5 villagers with flowers!]",
            y_offset, y_offset, y_offset, y_offset + 0.6
        )
        y_offset = y_offset + 1.5
    end
    
    -- Show active quests
    if next(active_quests) then
        formspec = formspec .. string.format("label[1,%s;Active Quests:]", y_offset)
        y_offset = y_offset + 0.8
        
        for quest_id, quest_data in pairs(active_quests) do
            formspec = formspec .. string.format(
                "button[1,%s;3,0.8;view_progress_%s;View Progress]" ..
                "label[4.5,%s;%s]" ..
                "label[4.5,%s;%s]",
                y_offset, quest_id, y_offset, quest_data.title, y_offset + 0.6, quest_data.description
            )
            y_offset = y_offset + 1.5
        end
    end
    
    -- Show completed quests
    if next(completed_quests) then
        formspec = formspec .. string.format("label[1,%s;Completed Quests:]", y_offset)
        y_offset = y_offset + 0.8
        
        for quest_id, quest_data in pairs(completed_quests) do
            formspec = formspec .. string.format(
                "label[2,%s;✓ %s]" ..
                "label[2,%s;Completed]",
                y_offset, quest_data.title, y_offset + 0.6
            )
            y_offset = y_offset + 1.2
        end
    end
    
    -- Close button
    formspec = formspec .. string.format("button[4,%s;2,0.8;close;Close]", y_offset + 0.5)
    
    -- Store UI state
    quest_ui_state[player_name] = {
        type = "available_quests",
        active_quests = active_quests,
        completed_quests = completed_quests
    }
    
    minetest.show_formspec(player_name, "lottmobs:quest_ui", formspec)
    lf("quest_ui", "Showing available quests UI for " .. player_name)
end

-- Show quest progress UI
function quest_ui.show_quest_progress(player_name, quest_id)
    if not lottmobs_quest_api then
        minetest.chat_send_player(player_name, "Quest system not available")
        return
    end
    
    local quest_progress = lottmobs_quest_api.get_quest_progress(player_name, quest_id)
    if not quest_progress then
        minetest.chat_send_player(player_name, "Quest not found")
        return
    end
    
    local formspec = get_background_formspec(10, 8)
    formspec = formspec .. "label[2,0.5;Quest Progress]"
    formspec = formspec .. string.format("label[1,1.5;%s]", quest_progress.title)
    formspec = formspec .. string.format("label[1,2.2;%s]", quest_progress.description)
    
    formspec = formspec .. "label[1,3.5;Objectives:]"
    local y_offset = 4.2
    
    for _, objective in ipairs(quest_progress.objectives) do
        local status_icon = objective.completed and "✓" or "○"
        local progress_color = objective.completed and "#00FF00" or "#FFFF00"
        
        formspec = formspec .. string.format(
            "label[1.5,%s;%s %s]" ..
            "label[2,%s;%s]",
            y_offset, status_icon, objective.description,
            y_offset + 0.6, string.format("(%d/%d)", objective.current, objective.required)
        )
        y_offset = y_offset + 1.2
    end
    
    -- Rescue counts summary
    if quest_progress.rescue_counts then
        formspec = formspec .. string.format("label[1,%s;Rescue Summary:]", y_offset + 0.5)
        y_offset = y_offset + 1.3
        
        for ltee_type, count in pairs(quest_progress.rescue_counts) do
            local type_name = ltee_type:sub(1,1):upper() .. ltee_type:sub(2)
            formspec = formspec .. string.format(
                "label[2,%s;%s LTees rescued: %d]",
                y_offset, type_name, count
            )
            y_offset = y_offset + 0.8
        end
    end
    
    -- Back and close buttons
    formspec = formspec .. string.format(
        "button[2,%s;2,0.8;back_to_quests;Back]" ..
        "button[5,%s;2,0.8;close;Close]",
        y_offset + 0.5, y_offset + 0.5
    )
    
    -- Store UI state
    quest_ui_state[player_name] = {
        type = "quest_progress",
        quest_id = quest_id,
        quest_progress = quest_progress
    }
    
    minetest.show_formspec(player_name, "lottmobs:quest_ui", formspec)
    lf("quest_ui", string.format("Showing quest progress UI for %s, quest %s", player_name, quest_id))
end

-- Handle formspec responses
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "lottmobs:quest_ui" then
        return false
    end
    
    local player_name = player:get_player_name()
    
    -- Debug: Log all received fields
    lf("quest_ui", string.format("Received fields from %s: %s", player_name, minetest.serialize(fields)))
    
    -- Handle close button
    if fields.close then
        quest_ui_state[player_name] = nil
        minetest.close_formspec(player_name, "lottmobs:quest_ui")
        return true
    end
    
    -- Handle back button
    if fields.back_to_quests then
        quest_ui.show_available_quests(player_name)
        return true
    end
    
    -- Handle story buttons
    if fields.story_rescue_carlos then
        if lottmobs_quest_stories then
            local story_data = lottmobs_quest_stories.get_story("rescue_carlos")
            if story_data then
                show_story_ui(player_name, "rescue_carlos", story_data)
            end
        end
        return true
    end
    
    if fields.story_rescue_mary then
        if lottmobs_quest_stories then
            local story_data = lottmobs_quest_stories.get_story("rescue_mary")
            if story_data then
                show_story_ui(player_name, "rescue_mary", story_data)
            end
        end
        return true
    end

    if fields.story_cheer_up_villagers then
        if lottmobs_quest_stories then
            local story_data = lottmobs_quest_stories.get_story("cheer_up_villagers")
            if story_data then
                show_story_ui(player_name, "cheer_up_villagers", story_data)
            end
        end
        return true
    end
    
    -- Handle quest acceptance
    if fields.accept_rescue_carlos then
        if lottmobs_quest_api then
            local success, message = lottmobs_quest_api.accept_quest(player_name, "rescue_carlos")
            if success then
                minetest.chat_send_player(player_name, message)
                quest_ui.show_available_quests(player_name) -- Refresh UI
            else
                minetest.chat_send_player(player_name, message)
            end
        end
        return true
    end
    
    if fields.accept_rescue_mary then
        if lottmobs_quest_api then
            local success, message = lottmobs_quest_api.accept_quest(player_name, "rescue_mary")
            if success then
                minetest.chat_send_player(player_name, message)
                quest_ui.show_available_quests(player_name) -- Refresh UI
            else
                minetest.chat_send_player(player_name, message)
            end
        end
        return true
    end

    if fields.accept_cheer_up_villagers then
        if lottmobs_quest_api then
            local success, message = lottmobs_quest_api.accept_quest(player_name, "cheer_up_villagers")
            if success then
                minetest.chat_send_player(player_name, message)
                quest_ui.show_available_quests(player_name) -- Refresh UI
            else
                minetest.chat_send_player(player_name, message)
            end
        end
        return true
    end
    
    -- Handle progress view buttons
    for field_name, _ in pairs(fields) do
        if field_name:match("^view_progress_") then
            local quest_id = field_name:gsub("^view_progress_", "", 1) -- Remove prefix
            lf("quest_ui", string.format("View progress clicked for quest: %s", quest_id))
            quest_ui.show_quest_progress(player_name, quest_id)
            return true
        end
    end
    
    return false
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
        if lottmobs_quest_api then
            local success, message = lottmobs_quest_api.accept_quest(player_name, quest_id)
            if success then
                minetest.chat_send_player(player_name, message)
                quest_ui.show_available_quests(player_name)
            else
                minetest.chat_send_player(player_name, message)
            end
        end
        return true
    end
    
    -- Handle reject quest
    if fields.reject_quest then
        minetest.chat_send_player(player_name, "Quest rejected.")
        quest_ui.show_available_quests(player_name)
        return true
    end
    
    -- Handle back button
    if fields.back then
        quest_ui.show_available_quests(player_name)
        return true
    end
    
    return false
end)

-- Register globally
lottmobs_quest_ui = quest_ui

lf("quest_ui", "Quest UI module loaded")
