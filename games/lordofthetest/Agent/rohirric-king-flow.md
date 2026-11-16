# Rohirric King Achievement - Call Flow

## Achievement Definition
**File:** `mods/lottachievements/init.lua` (lines 286-295)

```lua
lottachievements.register_achievement("rohirric_king", {
    title = "Rohirric King",
    description = "Equip a full set of gold armor",
    icon = "lottarmor_inv_chestplate_gold.png",
    id = 28,
    trigger = {
        type = "equip",
        item = "lottarmor:chestplate_gold",
    }
})
```

## Complete Call Flow

### 1. Player Equips Gold Armor
**Trigger:** Player places gold armor piece in armor inventory slot

**File:** `mods/lottarmor/armor.lua` (lines 424-435)

```lua
minetest.register_on_joinplayer(function(player)
    -- ... setup code ...
    local armor_inv = minetest.create_detached_inventory(name.."_armor", {
        on_put = function(inv, listname, index, stack, player)
            player:get_inventory():set_stack(listname, index, stack)
            armor:set_player_armor(player)
            armor:update_inventory(player)
            lottachievements.equip(stack, player, 1)  -- ← CALL #1
        end,
        on_take = function(inv, listname, index, stack, player)
            player:get_inventory():set_stack(listname, index, nil)
            armor:set_player_armor(player)
            armor:update_inventory(player)
            lottachievements.equip(stack, player, -1)  -- ← CALL #1 (removal)
        end,
        -- ... other callbacks ...
    })
end)
```

### 2. Achievement Equip Function Called
**File:** `mods/lottachievements/triggers.lua` (lines 475-504)

```lua
function lottachievements.equip(stack, player, count)  -- ← RECEIVES CALL #1
    if not stack or not player or not count then
        return
    end
    local data = lottachievements.players[player:get_player_name()]
    
    -- Parse item name: "lottarmor:chestplate_gold" → "lottarmor:gold"
    local name = string.split(stack:get_name(), ":")
    local name1 = name[1]  -- "lottarmor"
    local name2 = string.split(name[2], "_", false, 1)[2]  -- "gold"
    if name1 and name2 then
        name = name1 .. ":" .. name2  -- "lottarmor:gold"
    else
        return
    end

    -- Increment equip counter for "lottarmor:gold"
    if not lottachievements.increment_item_counter(data, "equip", name, count) then
        return
    end

    -- Check achievement conditions
    lottachievements.run_trigger_callbacks(player, data, "equip", function(entry)
        if entry.item then
            local titemequipped = string.split(entry.item, ":")
            local tmod = titemequipped[1]  -- "lottarmor"
            local titem = string.split(titemequipped[2], "_", false, 1)[2]  -- "gold"
            if not tmod or not titem or not data.equip[tmod] or not data.equip[tmod][titem] then
                -- table running failed!
            elseif data.equip[tmod][titem] > 3 then  -- ← CHECK: > 3 pieces equipped
                return entry.award  -- ← RETURN: "rohirric_king"
            end
        end
    end)
end
```

### 3. Trigger Callback Execution
**File:** `mods/lottachievements/api.lua` (lines 57-71)

```lua
function lottachievements.run_trigger_callbacks(player, data, trigger, table_func)  -- ← RECEIVES CALL #2
    for i = 1, #lottachievements.on[trigger] do  -- Iterate through all equip triggers
        local res = nil
        local entry = lottachievements.on[trigger][i]
        if type(entry) == "function" then
            res = entry(player, data)
        elseif type(entry) == "table" and entry.award then
            res = table_func(entry)  -- ← EXECUTES the function from step 2
        end

        if res then  -- ← res = "rohirric_king"
            lottachievements.unlock(player:get_player_name(), res)  -- ← CALL #3
        end
    end
end
```

### 4. Achievement Unlock
**File:** `mods/lottachievements/api.lua` (lines 187-338)

```lua
function lottachievements.unlock(name, award)  -- ← RECEIVES CALL #3 (award="rohirric_king")
    -- Access Player Data
    local data  = lottachievements.players[name]
    local awdef = lottachievements.def[award]  -- ← Gets Rohirric King definition

    -- Perform checks
    if not data or not awdef or data.disabled then
        return
    end
    lottachievements.tbv(data,"unlocked")

    -- Check if already unlocked
    if data.unlocked[award] and data.unlocked[award] == award then
        return
    end

    -- Unlock Achievement
    minetest.log("action", name.." has unlocked award "..name)
    data.unlocked[award] = award  -- ← Add to unlocked list
    lottachievements.save()  -- ← Save to file

    -- Give Prizes (none for this achievement)
    if awdef and awdef.prizes then
        -- ... prize handling ...
    end

    -- Run callbacks
    if awdef.on_unlock and awdef.on_unlock(name, awdef) then
        return
    end
    for _, callback in pairs(lottachievements.on_unlock) do
        if callback(name, awdef) then
            return
        end
    end

    -- Display Notification
    local title = awdef.title or award  -- "Rohirric King"
    local desc = awdef.description or ""  -- "Equip a full set of gold armor"
    local icon = awdef.icon or "lottachievements_unknown.png"  -- "lottarmor_inv_chestplate_gold.png"
    local sound = awdef.sound or {name="lottachievements_got_generic", gain=0.25}

    -- Show HUD notification (default mode)
    local player = minetest.get_player_by_name(name)
    local one = player:hud_add({
        hud_elem_type = "image",
        name = "award_bg",
        -- ... HUD background setup ...
    })
    local two = player:hud_add({
        hud_elem_type = "text",
        name = "award_au",
        text = "Achievement Unlocked!",
        -- ... HUD title setup ...
    })
    local three = player:hud_add({
        hud_elem_type = "text",
        name = "award_title",
        text = title,  -- "Rohirric King"
        -- ... HUD title setup ...
    })
    local four = player:hud_add({
        hud_elem_type = "image",
        name = "award_icon",
        text = icon,  -- "lottarmor_inv_chestplate_gold.png"
        -- ... HUD icon setup ...
    })
    
    -- Remove HUD after 4 seconds
    minetest.after(4, function()
        player:hud_remove(one)
        player:hud_remove(two)
        player:hud_remove(three)
        player:hud_remove(four)
    end)
end
```

## Trigger Registration (Setup Phase)
**File:** `mods/lottachievements/triggers.lua` (lines 233-251)

```lua
lottachievements.register_trigger("equip", function(def)  -- ← Called during mod init
    local tmp = {
        award  = def.name,  -- "rohirric_king"
        item = def.trigger.item,  -- "lottarmor:chestplate_gold"
    }
    table.insert(lottachievements.on.equip, tmp)  -- ← Stores for later callback
    -- ... other setup ...
end)
```

## Key Logic Points

### 1. Armor Piece Detection
- System parses item names: `"lottarmor:chestplate_gold"` → `"lottarmor:gold"`
- All gold armor pieces (helmet, chestplate, leggings, boots) map to same category

### 2. Full Set Detection
- Achievement triggers when `data.equip["lottarmor"]["gold"] > 3`
- This means 4+ pieces (0-based indexing: 0=1 piece, 1=2 pieces, 2=3 pieces, 3=4 pieces)
- Full set = helmet + chestplate + leggings + boots

### 3. Increment/Decrement
- `on_put` calls with `count = 1` (equipping)
- `on_take` calls with `count = -1` (removing)
- Counter tracks current equipped pieces

### 4. Data Structure
```lua
data.equip["lottarmor"]["gold"] = number  -- 0-4 (pieces currently equipped)
data.unlocked["rohirric_king"] = "rohirric_king"  -- achievement status
```

## Summary Flow
1. **Player equips gold armor** → Armor inventory callback
2. **lottachievements.equip()** → Increments counter, checks condition
3. **run_trigger_callbacks()** → Iterates triggers, calls condition function
4. **Condition check** → `data.equip["lottarmor"]["gold"] > 3` (full set)
5. **lottachievements.unlock()** → Awards achievement, shows notification
6. **Save data** → Persists achievement status to file

The achievement unlocks when the player equips a complete set of 4 gold armor pieces (helmet, chestplate, leggings, boots).
