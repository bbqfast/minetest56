local lf = assert(_G.lf, "global lf not initialized")

-- birthdayer1 NPC that shows birthday HUD when player gets close
mobs:register_mob("lottmobs:birthdayer1", {
	type = "npc",
	race = "GAMEltee",
	hp_min = 10,
	hp_max = 20,
	collisionbox = {-0.3,-1.0,-0.3, 0.3,0.8,0.3},
	visual = "mesh",
	mesh = "character.b3d",
	textures = {"birthdayer1_mt.png"},
	view_range = 5,
	walk_velocity = 0,
	run_velocity = 0,
	jump = false,
	damage = 1,
	armor = 100,
	light_resistant = true,
	drawtype = "front",
	attack_type = "dogfight",
	peaceful = true,
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
    sounds = {
        war_cry = "mobs_die_yell",
        death = "default_death",
        attack = "mobs_slash_attack",
    },
    attacks_monsters = false,
    
    on_rightclick = function(self, clicker)
		local name = clicker and clicker:get_player_name()
		if not name then
			return
		end
		-- stop moving and face the player
		self.state = "stand"
		if self.object then
			self.object:set_velocity({x = 0, y = 0, z = 0})
		end
		if self.set_animation then
			self:set_animation("stand")
		end
		if lottmobs and lottmobs.face_pos and clicker and clicker.get_pos then
			lottmobs.face_pos(self, clicker:get_pos())
		end
		-- show birthday message
		minetest.chat_send_player(name, "Birthdayer: Happy birthday! Happy birthday to Janice!")
	end,
})

-- HUD system for birthday messages
local birthdayer_huds = {}
local hud_timer = 0

-- Music system for birthday celebration
local birthdayer_music_players = {}
local music_timer = 0
local music_cooldown = {}
local music_sequence_index = {}

-- Birthday music sequence (Happy Birthday tune: GGAGCB)
local birthday_music_sequence = {
	"G",     -- G
	"G",     -- G  
	"A",     -- A
	"G",     -- G
	"C",     -- C
	"Bb",    -- Bb (played as B in the tune)
}

local function play_birthday_music(npc_pos, player_name)
	if not music_cooldown[player_name] or music_cooldown[player_name] <= 0 then
		-- Play the Happy Birthday MIDI file
		minetest.sound_play("Happy_Birthday_MIDI", {
			pos = npc_pos,
			max_hear_distance = 15,
			gain = 1.0,
		})
		
		-- Debug output
		minetest.chat_send_player(player_name, "Playing Happy Birthday music!")
		
		-- Set longer cooldown since it's a full song (30 seconds)
		music_cooldown[player_name] = 30
	else
		-- Debug: show cooldown
		minetest.chat_send_player(player_name, "Music cooldown: " .. music_cooldown[player_name] .. " seconds")
	end
end

local function show_birthday_hud(player)
	if not player or not player:is_player() then
		return
	end
	
	local name = player:get_player_name()
	
	-- Remove existing HUD if any
	if birthdayer_huds[name] then
		player:hud_remove(birthdayer_huds[name])
	end
	
	-- Add new HUD with birthday messages
	local hud_id = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.5, y = 0.3},
		text = "Happy birthday!\nHappy birthday to Janice!",
		number = 0xFFD700, -- Gold color
		alignment = {x = 0, y = 0},
		offset = {x = 0, y = 0},
		scale = {x = 200, y = 200}, -- Larger scale for bigger text
		style = 1 -- Bold style
	})
	
	birthdayer_huds[name] = hud_id
	
	-- Remove HUD after 5 seconds
	minetest.after(5, function()
		if player and player:is_player() then
			player:hud_remove(hud_id)
			birthdayer_huds[name] = nil
		end
	end)
end

-- Check for nearby players and show HUD + play music
minetest.register_globalstep(function(dtime)
	hud_timer = hud_timer + dtime
	music_timer = music_timer + dtime
	
	-- Check every 0.5 seconds
	if hud_timer < 0.5 then
		return
	end
	hud_timer = 0
	
	-- Update music cooldowns every second
	if music_timer >= 1.0 then
		music_timer = 0
		for player_name, cooldown in pairs(music_cooldown) do
			if cooldown > 0 then
				music_cooldown[player_name] = cooldown - 1
				if music_cooldown[player_name] <= 0 then
					music_cooldown[player_name] = nil
				end
			end
		end
	end
	
	-- Get all birthdayer NPCs
	for _, obj in pairs(minetest.get_connected_players()) do
		local player_pos = obj:get_pos()
		local nearby_objects = minetest.get_objects_inside_radius(player_pos, 5)
		
		for _, nearby_obj in ipairs(nearby_objects) do
			local luaentity = nearby_obj:get_luaentity()
			if luaentity and luaentity.name == "lottmobs:birthdayer1" then
				-- Check if player is close enough
				local npc_pos = nearby_obj:get_pos()
				local distance = vector.distance(player_pos, npc_pos)
				
				if distance <= 3 then -- Show HUD and play music when very close
					local player_name = obj:get_player_name()
					show_birthday_hud(obj)
					play_birthday_music(npc_pos, player_name)
					
					-- Make NPC face the player
					if luaentity and luaentity.object and lottmobs and lottmobs.face_pos then
						lottmobs.face_pos(luaentity, player_pos)
					end
					break -- Only show once per check
				end
			end
		end
	end
end)


minetest.register_chatcommand("spawn_birthdayer1", {
	description = "Spawns a birthdayer1 NPC",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then return false, "Player not found" end
		local pos = vector.add(player:get_pos(), {x = 2, y = 0, z = 0})
		local obj = minetest.add_entity(pos, "lottmobs:birthdayer1")
		if obj then
			return true, "birthdayer1 spawned."
		else
			return false, "Failed to spawn birthdayer1."
		end
	end
})


minetest.register_craftitem("lottmobs:cake", {
	description = ("Birthday Cake"),
	inventory_image = "cake.png",
	on_use = minetest.item_eat(15),
})