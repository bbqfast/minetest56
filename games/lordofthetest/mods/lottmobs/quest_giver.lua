-- Quest Giver NPC Entity
-- Provides quests to players and tracks progress

local lf = assert(_G.lf, "global lf not initialized")

-- Quest giver dialogue
local quest_giver_dialogues = {
    greeting = "Greetings, brave adventurer! I have important quests for those willing to help our lost LTees.",
    quest_available = "I have a quest that needs your help. Many LTees have gone missing and need to be rescued!",
    quest_already_accepted = "You're already working on this quest! Keep up the good work.",
    quest_completed = "Thank you for your help! You've completed the quest successfully.",
    no_quests = "Check back later! I may have new quests available soon.",
    progress_check = "Let me check your progress..."
}

-- Quest giver NPC definition
local quest_giver_def = {
    type = "npc",
    race = "GAMEltee",
    hp_min = 20,
    hp_max = 25,
    collisionbox = {-0.3, -0.75, -0.3, 0.3, 0.7, 0.3},
    visual = "mesh",
    mesh = "character.b3d",
    textures = {{"character_Mary_LT_mt.png"}}, -- Using Mary texture as quest giver
    nametag = "Quest Giver",
    nametag_color = {r = 255, g = 215, b = 0, a = 255}, -- Gold color
    
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
        {name = "default:paper", chance = 5, min = 1, max = 3},
        {name = "default:book", chance = 10, min = 1, max = 1},
    },
    
    -- Sounds
    sounds = {
        war_cry = "mobs_yell",
        death = "default_death",
        attack = "mobs_slash_attack",
    },
    
    -- Initialize quest giver
    on_activate = function(self)
        self.dialogue_timer = 0
        self.greeting_cooldown = 0
        lf("quest_giver", "Quest Giver activated")
    end,
    
    -- Right-click interaction for quest management
    on_rightclick = function(self, clicker)
        local player_name = clicker:get_player_name()
        
        -- Check if quest UI is available
        if not lottmobs_quest_ui then
            minetest.chat_send_player(player_name, "Quest UI is not available. Please contact an administrator.")
            return
        end
        
        -- Show the quest UI
        lottmobs_quest_ui.show_available_quests(player_name)
        
        -- Show greeting message
        minetest.chat_send_player(player_name, "<Quest Giver> " .. quest_giver_dialogues.greeting)
    end,
    
    -- Custom behavior: periodic greetings
    do_custom = function(self, dtime)
        -- Update timers
        self.dialogue_timer = (self.dialogue_timer or 0) + dtime
        self.greeting_cooldown = (self.greeting_cooldown or 0) + dtime
        
        -- Greet nearby players every 30 seconds
        if self.dialogue_timer >= 30 then
            self.dialogue_timer = 0
            
            local pos = self.object:get_pos()
            if pos then
                for _, player in ipairs(minetest.get_objects_inside_radius(pos, 5)) do
                    if player:is_player() and self.greeting_cooldown >= 60 then
                        local player_name = player:get_player_name()
                        local active_quests = lottmobs_quest_api and lottmobs_quest_api.get_active_quests(player_name) or {}
                        
                        if not next(active_quests) then
                            minetest.chat_send_player(player_name, 
                                "<Quest Giver> " .. quest_giver_dialogues.greeting)
                            self.greeting_cooldown = 0
                        end
                        break
                    end
                end
            end
        end
    end,
    
    -- On death
    on_die = function(self)
        lf("quest_giver", "Quest Giver died")
    end,
}

-- Register the quest giver NPC
mobs:register_mob("lottmobs:quest_giver", quest_giver_def)

-- Register spawn egg for quest giver
mobs:register_egg("lottmobs:quest_giver", "Quest Giver", 
                 "default_gold_block.png", 0)


-- Chat command to check quest status
minetest.register_chatcommand("quest_status", {
    description = "Check your current quest status",
    func = function(name)
        if not lottmobs_quest_api then
            return false, "Quest system is not available"
        end
        
        lottmobs_quest_api.show_quest_status(name)
        return true, "Quest status displayed above"
    end,
})

-- Chat command to spawn quest giver (for testing/admin)
minetest.register_chatcommand("spawn_quest_giver", {
    description = "Spawns a Quest Giver NPC",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then 
            return false, "Player not found" 
        end
        
        local pos = vector.add(player:get_pos(), {x = 2, y = 0, z = 0})
        local obj = minetest.add_entity(pos, "lottmobs:quest_giver")
        
        if obj then
            lf("quest_giver", string.format("Quest Giver spawned at x=%d y=%d z=%d", pos.x, pos.y, pos.z))
            return true, "Quest Giver spawned."
        else
            return false, "Failed to spawn Quest Giver."
        end
    end,
})


-- Elias the Chief
local elias_dialogues = {
    greeting = "greetings heros, we've been waiting for you for long time, we're counting on you to restore our prosperity in our villege",
    quest_available = "I have a quest that needs your help. Many LTees have gone missing and need to be rescued!",
    quest_already_accepted = "You're already working on this quest! Keep up the good work.",
    quest_completed = "Thank you for your help! You've completed the quest successfully.",
    no_quests = "Check back later! I may have new quests available soon.",
    progress_check = "Let me check your progress..."
}

local elias_def = {}
for k, v in pairs(quest_giver_def) do
    elias_def[k] = v
end

elias_def.race = "GAMEltee"
elias_def.textures = {{"character_Mary_LT_mt.png"}}
elias_def.nametag = "Elias the Chief"
elias_def.nametag_color = {r = 139, g = 90, b = 43, a = 255}

elias_def.on_activate = function(self)
    self.dialogue_timer = 0
    self.greeting_cooldown = 0
    lf("quest_giver", "Elias the Chief activated")
end

elias_def.on_rightclick = function(self, clicker)
    local player_name = clicker:get_player_name()
    
    if not lottmobs_quest_ui then
        minetest.chat_send_player(player_name, "Quest UI is not available. Please contact an administrator.")
        return
    end
    
    lottmobs_quest_ui.show_available_quests(player_name)
    minetest.chat_send_player(player_name, "<Elias the Chief> " .. elias_dialogues.greeting)
end

elias_def.do_custom = function(self, dtime)
    self.dialogue_timer = (self.dialogue_timer or 0) + dtime
    self.greeting_cooldown = (self.greeting_cooldown or 0) + dtime
    
    if self.dialogue_timer >= 30 then
        self.dialogue_timer = 0
        
        local pos = self.object:get_pos()
        if pos then
            for _, player in ipairs(minetest.get_objects_inside_radius(pos, 5)) do
                if player:is_player() and self.greeting_cooldown >= 60 then
                    local player_name = player:get_player_name()
                    local active_quests = lottmobs_quest_api and lottmobs_quest_api.get_active_quests(player_name) or {}
                    
                    if not next(active_quests) then
                        minetest.chat_send_player(player_name, 
                            "<Elias the Chief> " .. elias_dialogues.greeting)
                        self.greeting_cooldown = 0
                    end
                    break
                end
            end
        end
    end
end

elias_def.on_die = function(self)
    lf("quest_giver", "Elias the Chief died")
end

mobs:register_mob("lottmobs:elias_the_chief", elias_def)

mobs:register_egg("lottmobs:elias_the_chief", "Elias the Chief", "default_gold_block.png", 0)

minetest.register_chatcommand("spawn_elias_the_chief", {
    description = "Spawns Elias the Chief NPC",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then 
            return false, "Player not found" 
        end
        
        local pos = vector.add(player:get_pos(), {x = 2, y = 0, z = 0})
        local obj = minetest.add_entity(pos, "lottmobs:elias_the_chief")
        
        if obj then
            lf("quest_giver", string.format("Elias the Chief spawned at x=%d y=%d z=%d", pos.x, pos.y, pos.z))
            return true, "Elias the Chief spawned."
        else
            return false, "Failed to spawn Elias the Chief."
        end
    end,
})

lf("quest_giver", "Quest giver module loaded")
