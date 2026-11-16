-- Rescue Bag Item - Phase 2 Implementation (Egg System - Iteration 2)
local lf = assert(_G.lf, "global lf not initialized")

-- Create proper preview for rescued LTee spawn egg following NPC Preview Generation Guide (2c)
local function create_rescued_ltee_preview(texture_file)
    -- Use simple preview that works reliably
    -- Extract head area and resize for egg preview
    local preview = "(" .. texture_file .. "^[combine:16x16:8,8=" .. texture_file .. ":8,8)^[resize:32x32"
    return preview
end

-- Generate the preview for Mary LT spawn egg
local mary_ltee_face = create_rescued_ltee_preview("character_Mary_LT_mt.png")

-- Register rescued LTee mob (for spawn eggs)
mobs:register_mob("lottmobs:rescued_ltee", {
    type = "npc",
    race = "GAMEltee",
    hp_min = 15,
    hp_max = 20,
    collisionbox = {-0.3, -0.75, -0.3, 0.3, 0.7, 0.3},
    visual = "mesh",
    mesh = "character.b3d",
    textures = {
        {"character_Mary_LT_mt.png"},  -- Use Mary LT texture
    },
    nametag = "Rescued LTee",
    nametag_color = {r = 255, g = 255, b = 255, a = 255},
    
    -- Rescued characteristics (slightly better than rescueable)
    view_range = 10,
    walk_velocity = 1,  -- Normal movement
    run_velocity = 2,     -- Can run normally
    armor = 80,           -- Better armor
    damage = 0,           -- Still peaceful
    peaceful = true,
    attack_type = "none",
    group_attack = false,
    step = 1,
    
    -- Environmental resistances
    light_resistant = true,
    drawtype = "front",
    water_damage = 1,
    lava_damage = 5,
    light_damage = 0,
    
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
    
    -- No drops (rescued LTees don't carry items)
    drops = {},
    
    -- Sounds
    sounds = {
        war_cry = "mobs_die_yell",
        death = "default_death",
        attack = "mobs_slash_attack",
    },
    
    -- Rescue state tracking
    on_spawn = function(self)
        self.rescued = true
        self.ltee_type = self.ltee_type or "mary"

        local type_config = lottmobs.rescueable_ltee_types
            and lottmobs.rescueable_ltee_types[self.ltee_type]

        if not type_config then
            type_config = {
                texture = "character_Mary_LT_mt.png",
                nametag = "Rescued Mary LTee"
            }
        end

        self.textures = {type_config.texture}
        self.nametag = "Rescued " .. self.ltee_type:gsub("^%l", string.upper) .. " LTee"
        self.object:set_properties({
            textures = self.textures,
            nametag = self.nametag
        })

        lf("rescued_ltee", string.format("Rescued %s LTee activated", self.ltee_type))
    end,

    -- Right-click interaction (no special behavior)
    on_rightclick = function(self, clicker)
        minetest.chat_send_player(clicker:get_player_name(), "This LTee has been rescued and is now safe!")
    end,
    
    -- On death - cleanup
    on_die = function(self)
        lf("rescued_ltee", "Rescued LTee died")
    end,
})


-- Register the rescue bag item (Simplified - Iteration 2)
minetest.register_craftitem("lottmobs:rescue_bag", {
    description = "Rescue Bag\nRight-click rescueable LTees to rescue them",
    inventory_image = "bags_medium.png",  -- Use existing medium bag texture (2a)
    stack_max = 1,  -- Only one bag per inventory slot
    
    -- Left-click: Show simple message
    on_use = function(itemstack, user, pointed_thing)
        minetest.chat_send_player(user:get_player_name(), 
            "Hold the rescue bag and right-click on rescueable LTees to rescue them!")
        return itemstack
    end,
    
    -- Right-click: Standard placement (rescue logic is in LTee entity)
    on_place = function(itemstack, placer, pointed_thing)
        return minetest.item_place(itemstack, placer, pointed_thing)
    end,
})


-- Chat command for giving rescue bags (for testing)
minetest.register_chatcommand("give_rescue_bag", {
    description = "Gives a rescue bag for testing",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then 
            return false, "Player not found" 
        end
        
        local inv = player:get_inventory()
        local rescue_bag = ItemStack("lottmobs:rescue_bag")
        
        if inv:room_for_item("main", rescue_bag) then
            inv:add_item("main", rescue_bag)
            lf("rescue_bag", string.format("Rescue bag given to %s", name))
            return true, "Rescue bag added to your inventory."
        else
            return false, "Inventory full! Make space for the rescue bag."
        end
    end,
})

-- Log that the rescue bag module has been loaded
lf("rescue_bag", "Rescue bag module loaded")
