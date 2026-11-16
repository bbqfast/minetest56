# Achievement System Documentation

## Overview
The Lord of the Test game implements a comprehensive achievement system through the `lottachievements` mod. This system tracks player actions and unlocks achievements based on various triggers and conditions.

## Core Files Structure
- `mods/lottachievements/init.lua` - Main achievement definitions and registration
- `mods/lottachievements/api.lua` - Core API functions and data management
- `mods/lottachievements/triggers.lua` - Trigger system and event handlers
- `mods/lottachievements/api_helpers.lua` - Helper functions for data management
- `mods/lottachievements/chat_commands.lua` - Chat command interface

## Achievement Registration

### Basic Structure
Achievements are registered using `lottachievements.register_achievement(name, def)` where:

```lua
lottachievements.register_achievement("achievement_name", {
    title = "Display Title",
    description = "What the player must do",
    icon = "path/to/icon.png",
    id = unique_number,
    trigger = {
        type = "trigger_type",
        item = "specific_item", -- optional
        target = required_count
    },
    requires = "previous_achievement", -- optional prerequisite
    secret = true/false -- optional, hides achievement until unlocked
})
```

### Achievement Categories

#### 1. Food/Farming Achievements
- **Smoke Rings** - Blow a smoke ring with a pipe (no trigger)
- **A Long Path to Mushrooms** - Eat 99 brown mushrooms
- **Tasty Taters** - Eat 9 cooked potatoes

#### 2. Crafting Achievements
- **Rope is useful!** - Craft 100 meters of elven rope
- **Silver Stringed Music** - Craft a dwarvern harp
- **Express Miner** - Craft a mithril pickaxe
- **Chains of Melkor** - Craft a tilkal ingot
- **Master Craftsman** - Craft a Master Book of Crafts

#### 3. Mining/Exploration Achievements
- **Dungeons Deep and Caverns Old** - Find an underground dungeon
- **Dwarvern Tomb** - Find a dwarvern tomb
- **First Truesilver** - Mine 1 mithril ore
- **Dwarven Miner** - Mine 99 mithril ore (requires First Truesilver)
- **Amassing Fortune** - Mine 500 mithril ore (requires Dwarven Miner)
- **Truly Rich** - Mine 1000 mithril ore (requires Amassing Fortune)
- **Lord of Moria** - Mine 5000 mithril ore (requires Truly Rich)

#### 4. Biome Discovery Achievements
- **In the Land of Mordor...** - Visit Mordor and mine Mordor Stone
- **The Frozen Wastes** - Visit frozen biome and collect snow
- **Iron Galore** - Visit Iron Hills and start a mine
- **The Merry Shire** - Visit the Shire and examine soil
- **Lorien the Golden** - Visit the golden forest of Lorien
- **The Corrupted Greenwood** - Chop down a tree in Mirkwood

#### 5. Combat Achievements
- **Elven Champion** - Kill 25 Mordor orcs
- **Orcish Warlord** - Kill 25 elves
- **Spider Hunter** - Kill 25 spiders
- **Durin's Bane** - Kill a Balrog
- **Begone, foul dwimmerlaik** - Kill the Witch King
- **Living Wood** - Kill an ent

#### 6. Armor Achievements
- **Foot Soldier** - Equip full set of steel armor
- **Rohirric King** - Equip full set of gold armor
- **Elven Lord** - Equip full set of galvorn armor
- **Dwarven Lord** - Equip full set of mithril armor

#### 7. Advanced Crafting Achievements
- **Abandoned Workshop** - Discover secret Elven Workshop
- **Ringsilver crafter** - Form first ringsilver ingot (requires Abandoned Workshop)
- **The Ring is Prepared...** - Make a ring ready for gem fitting
- **A pickaxe fit for a king** - Craft a gem pickaxe
- **Polisher** - Polish a gem
- **Ring Smith** - Forge a ring of power
- **Supersonic Speed** - Craft a palantir (secret achievement)

#### 8. Death Achievements (Progressive)
- **First Time for Everything** - Die once
- **Not Again!** - Die a second time
- **This is becoming a habit...** - Die 10 times
- **I'm getting good at this!** - Die 25 times
- **This is really too much...** - Die 100 times
- **King of Dying** - Die 500 times
- **So dead, I'm immortal!** - Die 1000 times

## Trigger System

### Available Trigger Types
1. **dig** - Triggered when player digs nodes
2. **place** - Triggered when player places nodes
3. **eat** - Triggered when player eats items
4. **craft** - Triggered when player crafts items
5. **kill** - Triggered when player kills mobs
6. **equip** - Triggered when player equips armor
7. **death** - Triggered when player dies
8. **chat** - Triggered when player sends chat messages
9. **join** - Triggered when player joins the game

### Trigger Implementation
Each trigger type is registered with `lottachievements.register_trigger()` and includes:
- Progress tracking functions
- Default description generation
- Event handlers that monitor player actions

### Data Storage
Player achievement data is stored in:
- File: `world/lottachievements.txt`
- Structure: Serialized Lua table containing player progress

### Player Data Structure
```lua
lottachievements.players[player_name] = {
    unlocked = {
        achievement_name = achievement_name,
        -- ... unlocked achievements
    },
    count = {
        mod_name = {
            item_name = count,
            -- ... dug items
        }
    },
    place = {
        mod_name = {
            item_name = count,
            -- ... placed items
        }
    },
    craft = {
        mod_name = {
            item_name = count,
            -- ... crafted items
        }
    },
    eat = {
        mod_name = {
            item_name = count,
            -- ... eaten items
        }
    },
    kill = {
        mod_name = {
            mob_name = count,
            -- ... killed mobs
        }
    },
    deaths = number,
    joins = number,
    chats = number
}
```

## Achievement Unlocking Process

### Unlock Conditions
1. Player meets trigger requirements
2. Prerequisite achievements (if any) are completed
3. Achievement hasn't been previously unlocked
4. Player hasn't disabled achievements

### Unlock Effects
- Achievement added to player's unlocked list
- Data saved to file
- Optional prize items awarded
- Notification displayed (HUD, chat, or formspec)
- Sound played (with 1-second delay to prevent spam)
- Custom callbacks executed

### Notification Modes
- **hud** - Default, shows visual notification on screen
- **formspec** - Shows popup window
- **chat** - Shows text in chat

## User Interface

### Achievement Book
- Item: `lottachievements:achievement_book`
- Use/Place to open achievement interface
- Shows all achievements with progress indicators

### Chat Commands
- `/achievements` - View achievements
- `/achievements enable/disable` - Toggle achievement system
- `/achievements list [player]` - List achievements in chat

### Formspec Interface
**File:** `mods/lottachievements/api.lua`

**Main Functions:**
- `lottachievements.getFormspec(name, to, sid)` - Generates the achievement list formspec (lines 351-468)
- `lottachievements.show_to(name, to, sid, text)` - Shows formspec to player (lines 471-514)
- `minetest.register_on_player_receive_fields()` - Handles formspec interactions (lines 517-533)

**Formspec Features:**
- Displays achievement list with color coding:
  - Green: Completed achievements
  - Gray: Secret achievements (not unlocked)
  - Light Gray: Hidden achievements (prerequisites not met)
- Progress bars for incomplete achievements
- Detailed descriptions and icons
- Interactive textlist for achievement selection
- Sidebar view showing selected achievement details

**Formspec Structure:**
```lua
-- Main formspec call (line 509)
minetest.show_formspec(to,"lottachievements:lottachievements",
    "size[11,6]" ..
    "background[5,5;1,1;gui_formbg.png;true]" ..
    lottachievements.getFormspec(name, to, sid))

-- Field handler (lines 517-533)
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "lottachievements:lottachievements" then
        return false
    end
    if fields.quit then
        return true
    end
    local name = player:get_player_name()
    if fields.lottachievements then
        local event = minetest.explode_textlist_event(fields.lottachievements)
        if event.type == "CHG" then
            lottachievements.show_to(name, name, event.index, false)
        end
    end
    return true
end)
```

## API Functions

### Registration
- `lottachievements.register_achievement(name, def)` - Register new achievement
- `lottachievements.register_trigger(name, func)` - Register trigger type

### Player Management
- `lottachievements.unlock(name, award)` - Manually unlock achievement
- `lottachievements.enable(name)` - Enable achievements for player
- `lottachievements.disable(name)` - Disable achievements for player
- `lottachievements.clear_player(name)` - Reset player's achievements

### Data Access
- `lottachievements.player(name)` - Get player data
- `lottachievements.completed_achievements(name)` - Get completed achievements
- `lottachievements.show_to(name, to, sid, text)` - Show achievement interface

### Progress Tracking
- `lottachievements.get_item_count(data, field, itemname)` - Get specific item count
- `lottachievements.get_total_item_count(data, field)` - Get total count for field
- `lottachievements.increment_item_counter(data, field, itemname, count)` - Increment counter

## Integration Points

### Mob Integration
- `lottachievements.kill(mob_name, player)` - Call when mob is killed
- Used by lottmobs mod for combat achievements

### Armor Integration
- `lottachievements.equip(stack, player, count)` - Call when armor is equipped
- Used by lottarmor mod for armor achievements

### Custom Callbacks
- `lottachievements.register_on_unlock(func)` - Register unlock callback
- Achievement-specific `on_unlock` functions

## Special Features

### Secret Achievements
- Hidden until unlocked
- Show as "(Secret Achievement)" in interface
- Example: "Supersonic Speed" (craft palantir)

### Progressive Achievements
- Chain of achievements with prerequisites
- Example: Mithril mining achievements (1 → 99 → 500 → 1000 → 5000)

### Prerequisites
- `requires` field creates dependency chains
- Achievements hidden until prerequisites met
- Example: Advanced crafting achievements require workshop discovery

### Progress Tracking
- Real-time progress bars in achievement interface
- Percentage completion and current/total counts
- Automatic progress calculation for trigger-based achievements

## Technical Notes

### Performance
- Data saved on shutdown and achievement unlock
- Incremental counters prevent excessive calculations
- Sound delay prevents notification spam

### Compatibility
- Backwards compatibility functions provided
- Supports internationalization via intllib
- Modular design allows easy extension

### Error Handling
- Null checks for player and data validity
- Graceful handling of missing items/nodes
- Logging for debugging purposes

This achievement system provides a comprehensive framework for tracking player progression and rewarding various gameplay activities in the Lord of the Test game world.