-- Hostile mobs spawner UI
local lf = assert(_G.lf, "global lf not initialized")

local hostile_mobs_list = {
    "lottmobs:orc",
    "lottmobs:raiding_orc",
    "lottmobs:battle_troll",
    "lottmobs:half_troll",
    "lottmobs:nazgul",
    "lottmobs:witch_king",
    "lottmobs:balrog",
    "lottmobs:dead_men",
    "lottmobs:troll",
    "lottmobs:spider",
    "lottmobs:ent",
    "lottmobs:uruk_hai",
    "lottmobs:warg",
    "lottmobs:dunlending",
}

local hostile_mob_offsets = {}

minetest.register_chatcommand("hostile", {
    description = "Open the hostile mob spawner UI",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end

        local formspec = {
            "formspec_version[4]",
            "size[14,10]",
            "label[0.5,0.5;Hostile Mobs Spawner]",
        }

        for i, mob in ipairs(hostile_mobs_list) do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local x = 0.5 + col * 4.5
            local y = 1.2 + row * 1.2
            local label = mob:sub(#'lottmobs:' + 1):gsub('_', ' '):gsub('^%l', string.upper)
            table.insert(formspec, string.format(
                "button[%f,%f;4,0.8;mob_%d;Spawn %s]",
                x, y, i, minetest.formspec_escape(label)
            ))
        end

        minetest.show_formspec(name, "lottmobs:hostile_mobs_ui", table.concat(formspec, ""))
        return true, "Hostile mobs UI opened"
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "lottmobs:hostile_mobs_ui" then
        return false
    end

    local name = player:get_player_name()
    local should_reopen = false

    for i, mob in ipairs(hostile_mobs_list) do
        if fields["mob_" .. i] then
            local ppos = player:get_pos()
            hostile_mob_offsets[name] = (hostile_mob_offsets[name] or 0) + 1
            local idx = hostile_mob_offsets[name]
            local angle = (idx - 1) * (math.pi / 4)
            local dist = 3 + (idx % 3)
            local pos = vector.add(ppos, {
                x = math.cos(angle) * dist,
                y = 1,
                z = math.sin(angle) * dist,
            })
            local obj = minetest.add_entity(pos, mob)
            if obj then
                minetest.chat_send_player(name, "Spawned " .. mob)
                lf("hostile_mobs_ui", name .. " spawned " .. mob)
            else
                minetest.chat_send_player(name, "Failed to spawn " .. mob)
            end
            should_reopen = true
            break
        end
    end

    if should_reopen then
        minetest.after(0.1, function()
            local p = minetest.get_player_by_name(name)
            if p then
                minetest.chatcommands["hostile"].func(name, "")
            end
        end)
        return true
    end

    return true
end)

lf("hostile_mobs", "Hostile mobs UI module loaded")
