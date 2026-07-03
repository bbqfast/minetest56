


1.  Quest giver

- new NPC quest giver


- quest tracking system
- reward after a quest complete
- track quest progress


UI
- show accepted quest
- show quest progress




- everytime a rescuable LTee is rescued, update quest tracker
- 

2a. Quest book
- create a new item called "quest book"
- right click to open quest book
- show all active quests
- show quest progress
- show quest rewards
- have a button to cancel the active quest
- reuse existing book as texture


2b. revisit quest system, have 2 quests instead of one, 
one quest rescue carlos LTee
one quest rescue mary Ltee


This file captures the latest implementation details, only update when code change is made
C:\Minetest\v5.6\games\lordofthetest\Agent\impl-quest-system.md


2c.
update quest system, to add a story component that:
- story is defined in a separate txt or lua file
- add story button to the quest book
- add story button to quest giver
- when story button is clicked, should open a new UI that shows the story, with accept/reject button


3a.
- create a special test ui open by /test
- add buttons that runs the test commands from the follow files
C:\Minetest\v5.6\games\lordofthetest\Agent\impl-quest-system.md
C:\Minetest\v5.6\games\lordofthetest\Agent\Impl-rescueable-ltee.md

3b.
- remove the following tests command and UI
- accept carlos quest
- accept mary quest
- test carlos rescue
- test mary rescue

3c.
- remove Test Quest UI button

3d. [COMPLETED]
- the close button does not work, remove it
- Removed close button from test UI formspec and handler code (quest_test.lua)


do not modify above this line
--------------------------------------

## Implementation Findings

### Data Structure for Rescue Count Tracking

**Quest Definition Structure:**
```lua
local quest_definitions = {
    rescue_multiple = {
        id = "rescue_multiple",
        title = "Great Rescue Mission",
        objectives = {
            {
                id = "rescue_mary_count",
                type = "rescue_ltee_count",
                target_type = "mary",
                required = 3,
                description = "Rescue 3 Mary LTees (0/3)"
            },
            {
                id = "rescue_carlos_count", 
                type = "rescue_ltee_count",
                target_type = "carlos",
                required = 2,
                description = "Rescue 2 Carlos LTees (0/2)"
            }
        }
    }
}
```

**Player Progress Tracking:**
```lua
player_quests = {
    ["player_name"] = {
        active = {
            ["rescue_multiple"] = {
                rescue_counts = {
                    mary = 2,        -- Current Mary rescues
                    carlos = 1,      -- Current Carlos rescues
                    total = 3        -- Total LTees rescued
                },
                objectives = {
                    ["rescue_mary_count"] = {
                        current = 2,
                        required = 3,
                        completed = false
                    }
                }
            }
        }
    }
}
```

### Integration Points

**Rescue Event Hook Location:**
- File: `mods/lottmobs/rescueable_ltee.lua`
- Lines: 160-173 (successful rescue section)
- Trigger: After LTee entity removal

**Event Handler Function:**
```lua
local function on_ltee_rescued(player_name, ltee_type, location)
    -- Update rescue counts
    -- Update quest objectives  
    -- Check completion status
    -- Notify player of progress
end
```

### File Structure Plan
```
mods/lottmobs/
├── quest_system.lua      # Core quest API and data structures
├── quest_giver.lua       # Quest giver NPC entity
├── rescueable_ltee.lua   # Modified to hook quest events
└── init.lua             # Updated to load new modules
```

### Key Features
- **Type-specific tracking**: Separate counters for mary, carlos, etc.
- **Flexible objectives**: Supports "rescue X of type Y" and "rescue X total"
- **Real-time updates**: Immediate progress tracking via rescue events
- **Persistent storage**: Uses player metadata for quest data
- **Scalable design**: Easy to add new LTee types and objectives




### Enhancement EH1
- Quest giver UI:
- list all the available quest with an accept button
- when a quest is accepted, show quest progress, if you need to recue multiple people list how many rescued
- right click on quest giver to check progress
- Do NOT use chat as UI, should be a separate forspec