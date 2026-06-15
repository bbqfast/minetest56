-- Rescueable LTee NPC - Phase 1 Implementation
-- This NPC can be rescued by players using a rescue bag
-- Refactored to support multiple LT types

local lf = assert(_G.lf, "global lf not initialized")

-- Rescueable LT type definitions
local rescueable_ltee_types = {
    mary = {
        texture = "character_Mary_LT_mt.png",
        nametag = "Rescueable Mary LTee",
        rescued_egg_name = "lottmobs:rescued_mary_ltee",
        egg_description = "Rescued Mary LTee",
        spawn_command = "spawn_rescueable_mary_ltee"
    },
    carlos = {
        texture = "character_Carlos_LT_third_LT_stolen_mt.png",
        nametag = "Rescueable Carlos LTee",
        rescued_egg_name = "lottmobs:rescued_carlos_ltee",
        egg_description = "Rescued Carlos LTee",
        spawn_command = "spawn_rescueable_carlos_ltee"
    }
}

-- Shared rescue quotes for all rescueable LTees
local rescue_quotes = {
    "Help me! I'm lost and scared!",
    "Please rescue me! I can't find my way back.",
    "I need help! There are dangerous creatures around.",
    "Save me! I got separated from my village.",
    "Please help! I'm injured and can't move well.",
    "Rescue me! I don't know where I am.",
    "Help! I need to get back to safety.",
    "Please save me! I'm all alone out here.",
}

-- Shared function to create rescueable LTee entity
local function create_rescueable_ltee(ltee_type)
    local type_config = rescueable_ltee_types[ltee_type]
    if not type_config then
        lf("rescueable_ltee", "Unknown LTee type: " .. tostring(ltee_type))
        return nil
    end
    
    return {
        type = "npc",
        race = "GAMEltee",
        hp_min = 10,
        hp_max = 15,
        collisionbox = {-0.3, -0.75, -0.3, 0.3, 0.7, 0.3},
        visual = "mesh",
        mesh = "character.b3d",
        textures = {{type_config.texture}},
        nametag = type_config.nametag,
        nametag_color = {r = 255, g = 255, b = 255, a = 255},
        ltee_type = ltee_type,  -- Store type for rescue logic
        
        -- Vulnerable characteristics
        view_range = 8,
        walk_velocity = 0.5,  -- Very slow movement
        run_velocity = 1,     -- Can't run well
        armor = 50,           -- Low armor
        damage = 0,           -- Can't attack
        
        -- Environmental vulnerabilities
        light_resistant = true,
        drawtype = "front",
        water_damage = 2,
        lava_damage = 10,
        light_damage = 0,
        
        -- Peaceful behavior
        peaceful = true,
        attack_type = "none",
        group_attack = false,
        step = 1,
        
        -- Standard animations
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
        
        -- Minimal drops (rescued LTees don't have valuable items)
        drops = {
            {name = "farming:string", chance = 10, min = 1, max = 2},
        },
        
        -- Sounds
        sounds = {
            war_cry = "mobs_die_yell",
            death = "default_death",
            attack = "mobs_slash_attack",
        },
        
        -- Rescue state tracking
        on_activate = function(self)
            self.rescued = false
            self.rescue_quotes = rescue_quotes
            self.current_quote_index = math.random(1, #rescue_quotes)
            self.quote_timer = 0
            self.help_timer = 0
            lf("rescueable_ltee", string.format("%s activated", type_config.nametag))
        end,
        
        -- Right-click interaction for rescue
        on_rightclick = function(self, clicker)
            local player_name = clicker:get_player_name()
            local wielded_item = clicker:get_wielded_item()
            
            -- Check if player is holding a rescue bag
            if wielded_item:get_name() ~= "lottmobs:rescue_bag" then
                minetest.chat_send_player(player_name, "You need to hold a rescue bag to rescue this LTee!")
                return
            end
            
            -- Get LTee type configuration
            local type_config = rescueable_ltee_types[self.ltee_type or "mary"]
            
            -- Prepare LTee data for rescue (Egg System - Iteration 2)
            local ltee_data = {
                name = self.nametag or "Rescueable LTee",
                health = self.object:get_hp() or 10,
                original_pos = self.object:get_pos(),
                rescue_quotes = self.rescue_quotes,
                ltee_type = self.ltee_type or "mary",
            }
            
            -- Create rescued LTee spawn egg following NPC Preview Generation Guide
            local rescued_egg = ItemStack(type_config.rescued_egg_name)
            
            -- Add to player inventory
            local inv = clicker:get_inventory()
            local success = false
            
            if inv:room_for_item("main", rescued_egg) then
                inv:add_item("main", rescued_egg)
                
                -- Send success message with rescue info
                local rescue_time = os.date("%Y-%m-%d %H:%M:%S")
                minetest.chat_send_player(player_name, 
                    string.format("Rescued %s! Spawn egg added to inventory. Rescued: %s", 
                        ltee_data.name or "LTee", rescue_time))
                
                success = true
            else
                minetest.chat_send_player(player_name, "Inventory full! Make space to rescue LTees.")
            end
            
            if success then
                -- Mark LTee as rescued and remove entity
                self.rescued = true
                
                -- Remove the LTee entity after a short delay to allow message to show
                minetest.after(0.5, function()
                    if self.object and self.object:get_pos() then
                        self.object:remove()
                    end
                end)
                
                lf("rescueable_ltee", string.format("%s rescued by %s at %s", 
                    type_config.nametag, player_name, minetest.pos_to_string(ltee_data.original_pos)))
            end
        end,
        
        -- Custom behavior: show help messages periodically
        do_custom = function(self, dtime)
            if self.rescued then
                return
            end
            
            -- Initialize variables if they're nil (can happen on entity load)
            if not self.quote_timer then
                self.quote_timer = 0
            end
            if not self.help_timer then
                self.help_timer = 0
            end
            if not self.rescue_quotes then
                self.rescue_quotes = rescue_quotes
            end
            if not self.current_quote_index then
                self.current_quote_index = math.random(1, #rescue_quotes)
            end
            
            -- Update quote timer
            self.quote_timer = self.quote_timer + dtime
            self.help_timer = self.help_timer + dtime
            
            -- Show help message every 10 seconds
            if self.help_timer >= 10 then
                self.help_timer = 0
                local pos = self.object:get_pos()
                if pos then
                    -- Find nearby players
                    for _, player in ipairs(minetest.get_objects_inside_radius(pos, 8)) do
                        if player:is_player() then
                            local quote = self.rescue_quotes[self.current_quote_index]
                            minetest.chat_send_player(player:get_player_name(), 
                                "<" .. (self.nametag or "Rescueable LTee") .. "> " .. quote)
                            
                            -- Cycle to next quote
                            self.current_quote_index = (self.current_quote_index % #self.rescue_quotes) + 1
                            break
                        end
                    end
                end
            end
        end,
        
        -- On death - cleanup
        on_die = function(self)
            lf("rescueable_ltee", string.format("%s died", type_config.nametag))
        end,
    }
end

-- Register all rescueable LTee types
for ltee_type, _ in pairs(rescueable_ltee_types) do
    local mob_def = create_rescueable_ltee(ltee_type)
    if mob_def then
        mobs:register_mob("lottmobs:rescueable_" .. ltee_type .. "_ltee", mob_def)
    end
end

-- Create preview function for rescued LTee spawn eggs according to NPC Preview Generation Guide
local function get_preview(texture_file)
    local player_skin = "("..texture_file..")"
    local skin = ""

    -- Consistent on both sizes:
    --Chest
    skin = skin .. "([combine:16x32:-16,-12=" .. player_skin .. "^[mask:skindb_mask_chest.png)^"
    --Head
    skin = skin .. "([combine:16x32:-4,-8=" .. player_skin .. "^[mask:skindb_mask_head.png)^"
    --Hat
    skin = skin .. "([combine:16x32:-36,-8=" .. player_skin .. "^[mask:skindb_mask_head.png)^"
    --Right Arm
    skin = skin .. "([combine:16x32:-44,-12=" .. player_skin .. "^[mask:skindb_mask_rarm.png)^"
    --Right Leg
    skin = skin .. "([combine:16x32:0,0=" .. player_skin .. "^[mask:skindb_mask_rleg.png)^"

    -- 64x skins have non-mirrored arms and legs
    local left_arm
    local left_leg

    local format = "1.5"  -- Mary LT is 1.5 format (32x64)
    if format == "1.8" then
        left_arm = "([combine:16x32:-24,-44=" .. player_skin .. "^[mask:(skindb_mask_rarm.png^[transformFX))^"
        left_leg = "([combine:16x32:-12,-32=" .. player_skin .. "^[mask:(skindb_mask_rleg.png^[transformFX))^"
    else
        left_arm = "([combine:16x32:-44,-12=" .. player_skin .. "^[mask:skindb_mask_rarm.png^[transformFX)^"
        left_leg = "([combine:16x32:0,0=" .. player_skin .. "^[mask:skindb_mask_rleg.png^[transformFX)^"
    end

    -- Left Arm
    skin = skin .. left_arm
    --Left Leg
    skin = skin .. left_leg

    -- Add overlays for 64x skins. these wont appear if skin is 32x because it will be cropped out
    --Chest Overlay
    skin = skin .. "([combine:16x32:-16,-28=" .. player_skin .. "^[mask:skindb_mask_chest.png)^"
    --Right Arm Overlay
    skin = skin .. "([combine:16x32:-44,-28=" .. player_skin .. "^[mask:skindb_mask_rarm.png)^"
    --Right Leg Overlay
    skin = skin .. "([combine:16x32:0,-16=" .. player_skin .. "^[mask:skindb_mask_rleg.png)^"
    --Left Arm Overlay
    skin = skin .. "([combine:16x32:-40,-44=" .. player_skin .. "^[mask:(skindb_mask_rarm.png^[transformFX))^"
    --Left Leg Overlay
    skin = skin .. "([combine:16x32:4,-32=" .. player_skin .. "^[mask:(skindb_mask_rleg.png^[transformFX))"

    -- Full Preview
    skin = "(((" .. skin .. ")^[resize:64x128)^[mask:skindb_transform.png)"

    minetest.log("warning", "yyyyyyyyy *********  Final skin string: " .. tostring(skin))
    
    return skin
end

-- Register spawn eggs for all rescued LTee types with proper previews
for ltee_type, type_config in pairs(rescueable_ltee_types) do
    mobs:register_egg(type_config.rescued_egg_name, type_config.egg_description, 
                     get_preview(type_config.texture), 0)
end

-- Chat commands for spawning rescueable LTees (for testing)
for ltee_type, type_config in pairs(rescueable_ltee_types) do
    minetest.register_chatcommand(type_config.spawn_command, {
        description = string.format("Spawns a rescueable %s NPC for testing", type_config.nametag),
        func = function(name)
            local player = minetest.get_player_by_name(name)
            if not player then 
                return false, "Player not found" 
            end
            
            local pos = vector.add(player:get_pos(), {x = 2, y = 0, z = 0})
            local obj = minetest.add_entity(pos, "lottmobs:rescueable_" .. ltee_type .. "_ltee")
            
            if obj then
                lf("rescueable_ltee", string.format("%s spawned at x=%d y=%d z=%d", 
                    type_config.nametag, pos.x, pos.y, pos.z))
                return true, string.format("%s spawned.", type_config.nametag)
            else
                return false, string.format("Failed to spawn %s.", type_config.nametag)
            end
        end,
    })
end

-- Legacy command for backward compatibility
minetest.register_chatcommand("spawn_rescueable_ltee", {
    description = "Spawns a rescueable Mary LTee NPC for testing (legacy)",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then 
            return false, "Player not found" 
        end
        
        local pos = vector.add(player:get_pos(), {x = 2, y = 0, z = 0})
        local obj = minetest.add_entity(pos, "lottmobs:rescueable_mary_ltee")
        
        if obj then
            lf("rescueable_ltee", string.format("Rescueable Mary LTee spawned at x=%d y=%d z=%d", pos.x, pos.y, pos.z))
            return true, "Rescueable Mary LTee spawned."
        else
            return false, "Failed to spawn rescueable Mary LTee."
        end
    end,
})

-- Log that the rescueable LTee module has been loaded
lf("rescueable_ltee", "Rescueable LTee module loaded")
