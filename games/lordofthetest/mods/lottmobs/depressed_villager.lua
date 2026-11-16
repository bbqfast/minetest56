-- Depressed Villager NPC Entity
-- An NPC that requests a random flower and becomes an ally once cheered up

local lf = assert(_G.lf, "global lf not initialized")

-- Flower pool (from Agent\desc-flowers.md)
local flower_list = {
    "flowers:rose",
    "flowers:tulip",
    "flowers:dandelion_yellow",
    "flowers:dandelion_white",
    "flowers:geranium",
    "flowers:viola",
    "lottplants:anemones",
    -- "lottplants:asphodel",
    "lottplants:eglantive",
    "lottplants:elanor",
    "lottplants:iris",
    "lottplants:lissuin",
    "lottplants:mallos",
    "lottplants:niphredil",
    "lottplants:seregon",
    "lottplants:brambles_of_mordor",
    "lottplants:pilinehtar",
}

-- Dialogue messages
local dialogues = {
    greeting = "I feel so sad... Could you bring me a flower to cheer me up?",
    thank_you = "Thank you for the flower! I feel much better now.",
    not_depressed = "I feel great! Let's fight those monsters!",
    wrong_item = "That's not the flower I was hoping for.",
}

-- Map detached inventory name to entity self
lottmobs.depressed_villagers = {}

local function get_random_flower()
    return flower_list[math.random(1, #flower_list)]
end

-- Create detached inventory for a depressed villager
function lottmobs.create_depressed_villager_inventory(entity_id, requested_flower)
    local inventory = minetest.create_detached_inventory(entity_id, {
        allow_take = function(inv, listname, index, stack, player)
            return 0
        end,
        allow_put = function(inv, listname, index, stack, player)
            if listname == "payment" then
                return stack:get_count()
            end
            return 0
        end,
        allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
            return 0
        end,
        on_put = function(inv, listname, index, stack, player)
            if listname == "payment" then
                lottmobs.check_depressed_villager_payment(inv, player)
            end
        end,
    })

    inventory:set_size("requested", 1)
    inventory:set_size("payment", 1)
    inventory:set_stack("requested", 1, ItemStack(requested_flower .. " 1"))

    return inventory
end

-- Check if the player gave the requested flower
function lottmobs.check_depressed_villager_payment(inv, player)
    local loc = inv:get_location()
    local entity_id = loc and loc.name
    local self = entity_id and lottmobs.depressed_villagers[entity_id]

    local payment_stack = inv:get_stack("payment", 1)
    if payment_stack:is_empty() then
        return
    end

    local requested_stack = inv:get_stack("requested", 1)
    if requested_stack:is_empty() then
        -- Already recovered
        inv:set_stack("payment", 1, nil)
        return
    end

    local payment_name = payment_stack:get_name()
    local payment_count = payment_stack:get_count()
    local requested_name = requested_stack:get_name()
    local requested_count = requested_stack:get_count()

    if payment_name ~= requested_name then
        local wrong_stack = inv:get_stack("payment", 1)
        inv:set_stack("payment", 1, nil)

        local player_name = player:get_player_name()
        local player_inv = player:get_inventory()
        if player_inv:room_for_item("main", wrong_stack) then
            player_inv:add_item("main", wrong_stack)
            minetest.chat_send_player(player_name,
                "<Depressed Villager> " .. dialogues.wrong_item)
        else
            minetest.add_item(player:get_pos(), wrong_stack)
            minetest.chat_send_player(player_name,
                "<Depressed Villager> " .. dialogues.wrong_item ..
                " I dropped it on the ground (your inventory is full).")
        end
        return
    end

    if payment_count < requested_count then
        return
    end

    -- Success: take required amount and return any excess
    inv:set_stack("requested", 1, nil)
    local excess = payment_count - requested_count
    if excess > 0 then
        local excess_stack = ItemStack(requested_name .. " " .. excess)
        local player_inv = player:get_inventory()
        if player_inv:room_for_item("main", excess_stack) then
            player_inv:add_item("main", excess_stack)
            minetest.chat_send_player(player:get_player_name(),
                "<Depressed Villager> I took " .. requested_count .. " " .. requested_name .. " and returned " .. excess .. " to you.")
        else
            minetest.add_item(player:get_pos(), excess_stack)
            minetest.chat_send_player(player:get_player_name(),
                "<Depressed Villager> I took " .. requested_count .. " and dropped " .. excess .. " on the ground.")
        end
    else
        minetest.chat_send_player(player:get_player_name(),
            "<Depressed Villager> " .. dialogues.thank_you)
    end
    inv:set_stack("payment", 1, nil)

    -- Unset depressed state and let the villager fight
    if self then
        self.depressed = false
        self.nametag = "Brave Citizen"
        self.object:set_properties({nametag = "Brave Citizen"})
        lf("depressed_villager", "Villager " .. entity_id .. " is no longer depressed")

        -- Update quest progress for cheering up this villager
        if lottmobs_quest_api then
            local player_name = player:get_player_name()
            lottmobs_quest_api.update_cheer_villager_progress(player_name, self.id)
        end
    end
end

-- Depressed Villager NPC definition
local depressed_villager_def = {
    type = "npc",
    race = "GAMEltee",
    hp_min = 20,
    hp_max = 25,
    collisionbox = {-0.3, -0.75, -0.3, 0.3, 0.7, 0.3},
    visual = "mesh",
    mesh = "character.b3d",
    textures = {{"character_Carlos_LT_third_LT_stolen_mt.png"}},
    nametag = "Depressed Villager",
    nametag_color = {r = 150, g = 150, b = 255, a = 255},

    view_range = 10,
    walk_velocity = 0,
    run_velocity = 0,
    armor = 100,
    damage = 5,
    attack_type = "dogfight",

    light_resistant = true,
    drawtype = "front",
    water_damage = 0,
    lava_damage = 0,
    light_damage = 0,

    peaceful = true,
    passive = true,
    attacks_monsters = true,
    attack_npcs = true,
    attack_players = false,
    group_attack = false,
    step = 1,

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

    drops = {
        {name = "default:gold_ingot", chance = 10, min = 1, max = 2},
    },

    sounds = {
        war_cry = "mobs_yell",
        death = "default_death",
        attack = "mobs_slash_attack",
    },

    on_spawn = function(self)
        self.depressed = true
        self.requested_flower = get_random_flower()
        lf("depressed_villager", "Spawned with flower request: " .. self.requested_flower)
    end,

    on_activate = function(self, staticdata)
        if self.depressed == nil then
            self.depressed = true
        end
        if self.requested_flower == nil then
            self.requested_flower = get_random_flower()
        end
        if not self.id or self.id == 0 then
            self.id = (math.random(1, 1000) * math.random(1, 10000)) .. self.name .. (math.random(1, 1000) ^ 2)
        end
        lottmobs.depressed_villagers[self.id] = self
        lf("depressed_villager", "Activated with request: " .. self.requested_flower)
    end,

    on_rightclick = function(self, clicker)
        local player_name = clicker:get_player_name()

        if not self.id or self.id == 0 then
            self.id = (math.random(1, 1000) * math.random(1, 10000)) .. self.name .. (math.random(1, 1000) ^ 2)
        end
        lottmobs.depressed_villagers[self.id] = self

        if not self.depressed then
            minetest.chat_send_player(player_name,
                "<Depressed Villager> " .. dialogues.not_depressed)
            return
        end

        local inventory = minetest.get_inventory({type = "detached", name = self.id})
        if not inventory then
            inventory = lottmobs.create_depressed_villager_inventory(self.id, self.requested_flower)
        else
            inventory:set_stack("requested", 1, ItemStack(self.requested_flower .. " 1"))
        end

        minetest.chat_send_player(player_name,
            "<Depressed Villager> " .. dialogues.greeting)

        minetest.show_formspec(player_name, "depressed_villager:" .. self.id,
            "size[8,9;]" ..
            "label[0,0;Depressed Villager wants this flower:]" ..
            "list[detached:" .. self.id .. ";requested;.5,.5;1,1;]" ..
            "label[4.5,0.5;Your Payment]" ..
            "list[detached:" .. self.id .. ";payment;4.5,1;5.5,2;]" ..
            "label[0,6;Place the requested flower here to cheer the villager up]" ..
            "list[current_player;main;0,6.5;8,4;]"
        )
    end,

    do_custom = function(self, dtime)
        if self.depressed == nil then
            self.depressed = true
        end
        if self.depressed then
            self.nametag = "Depressed Villager"
            self.object:set_properties({nametag = self.nametag})
            self.passive = true
            self.walk_velocity = 0
            self.run_velocity = 0
        else
            self.nametag = "Brave Citizen"
            self.object:set_properties({nametag = self.nametag})
            self.passive = false
            self.walk_velocity = 2
            self.run_velocity = 3.5
            self.race = "GAMEltee"
            self.attack_npcs = true
            self.attack_players = false
            self.attack_monsters = true
        end
    end,

    on_die = function(self)
        if self.id then
            lottmobs.depressed_villagers[self.id] = nil
        end
        lf("depressed_villager", "Depressed Villager died")
    end,
}

mobs:register_mob("lottmobs:depressed_villager", depressed_villager_def)

mobs:register_egg("lottmobs:depressed_villager", "Depressed Villager",
                  "default_gold_block.png", 0)

minetest.register_chatcommand("spawn_depressed_villager", {
    description = "Spawns a Depressed Villager NPC",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end

        local pos = vector.add(player:get_pos(), {x = 2, y = 0, z = 0})
        local obj = minetest.add_entity(pos, "lottmobs:depressed_villager")

        if obj then
            lf("depressed_villager", string.format("Depressed Villager spawned at x=%d y=%d z=%d", pos.x, pos.y, pos.z))
            return true, "Depressed Villager spawned."
        else
            return false, "Failed to spawn Depressed Villager."
        end
    end,
})

lf("depressed_villager", "Depressed Villager module loaded")
