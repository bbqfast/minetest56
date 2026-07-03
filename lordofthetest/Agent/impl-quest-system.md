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

do not modify above this line
--------------------------------------

## Implementation Summary

The quest system has been fully implemented with all requested features. This document explains the technical implementation details and architecture.

## Core Components

### 1. Quest System Core (`quest_system.lua`)
- **Quest Definitions Database**: Centralized quest definitions with objectives, requirements, rewards, and story IDs
- **Player Progress Tracking**: Persistent storage using player metadata for quest data
- **Real-time Event Processing**: Automatic progress updates when LTees are rescued
- **Reward Distribution**: Automatic reward giving for objectives and quest completion
- **Story UI Integration**: Story viewing interface with accept/reject functionality

### 2. Quest Stories Module (`quest_stories.lua`)
- **Story Definitions Database**: Centralized story text for each quest
- **Story Retrieval API**: Functions to fetch story data by quest ID
- **Flexible Story Content**: Multi-line story text with custom accept/reject button labels
- **Extensible Design**: Easy to add new stories for additional quests

### 3. Quest Giver NPC (`quest_giver.lua`)
- **New NPC Entity**: "Quest Giver" with unique race "QUEST_GIVER" to avoid conflicts
- **Interactive Interface**: Right-click interaction to access quest system
- **Peaceful Behavior**: Non-attackable, passive NPC that won't be targeted by other mobs
- **Story Button Integration**: Story buttons available in quest giver UI

### 4. Quest UI System (`quest_ui.lua`)
- **Formspec-based Interface**: Graphical quest management interface
- **Available Quests Display**: Lists quests with story and accept buttons
- **Progress Tracking UI**: Shows detailed quest progress with rescue counts
- **Navigation System**: Back/close buttons for easy UI navigation
- **Story Viewing UI**: Dedicated story display with accept/reject buttons

### 5. Rescue Integration (`rescueable_ltee.lua`)
- **Event Hook Integration**: Automatic quest progress updates on LTee rescue
- **Type-specific Tracking**: Separate counters for Mary and Carlos LTees
- **Real-time Notifications**: Immediate feedback when quest objectives are completed

## Technical Architecture

### Data Structures

**Quest Definitions:**
```lua
local quest_definitions = {
    rescue_carlos = {
        id = "rescue_carlos",
        title = "Carlos Rescue Mission",
        description = "Help rescue the lost Carlos LTees and bring them back to safety!",
        story_id = "rescue_carlos",
        objectives = {
            {
                id = "rescue_carlos_count", 
                type = "rescue_ltee_count",
                target_type = "carlos",
                required = 2,
                description = "Rescue 2 Carlos LTees (0/2)",
                reward = {item = "default:diamond", count = 1}
            }
        },
        completion_reward = {item = "default:mese_crystal", count = 2}
    },
    rescue_mary = {
        id = "rescue_mary",
        title = "Mary Rescue Mission",
        description = "Help rescue the lost Mary LTees and bring them back to safety!",
        story_id = "rescue_mary",
        objectives = {
            {
                id = "rescue_mary_count",
                type = "rescue_ltee_count",
                target_type = "mary",
                required = 3,
                description = "Rescue 3 Mary LTees (0/3)",
                reward = {item = "default:gold_ingot", count = 5}
            }
        },
        completion_reward = {item = "default:mese_crystal", count = 3}
    }
}
```

**Story Definitions:**
```lua
local quest_stories = {
    rescue_carlos = {
        id = "rescue_carlos",
        title = "The Tale of Carlos",
        story = [[In the peaceful lands of the LTee kingdom...]],
        accept_text = "I will rescue Carlos!",
        reject_text = "I am not ready yet."
    },
    rescue_mary = {
        id = "rescue_mary",
        title = "The Legend of Mary",
        story = [[Mary was the heart of the LTee community...]],
        accept_text = "I will rescue Mary!",
        reject_text = "I am not ready yet."
    }
}
```

**Player Progress Storage:**
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
        },
        completed = {} -- Completed quests with timestamps
    }
}
```

### Event Flow

1. **Story Viewing**: Player clicks "Story" button in Quest Book or Quest Giver UI → Story UI opens with quest narrative
2. **Quest Acceptance**: Player clicks "Accept" in Story UI → Quest API accepts quest → Returns to quest list
3. **Quest Rejection**: Player clicks "Reject" in Story UI → Returns to quest list without accepting
4. **Direct Acceptance**: Player can also accept quests directly via "Accept Quest" button
5. **Rescue Event**: Player rescues LTee with rescue bag → `on_rightclick` triggers → Quest API updates progress
6. **Progress Check**: Quest API checks objectives → Updates rescue counts → Awards objective rewards if completed
7. **Quest Completion**: All objectives complete → Awards completion reward → Marks quest as completed

### Integration Points

**Rescue Event Hook Location:**
- File: `mods/lottmobs/rescueable_ltee.lua`
- Function: `on_rightclick` (lines 174-189)
- Trigger: After successful LTee rescue and entity removal

**Quest Update Function:**
```lua
-- Hook into quest system for rescue progress tracking
if lottmobs_quest_api then
    local updated_quests = lottmobs_quest_api.update_rescue_progress(
        player_name, 
        ltee_data.ltee_type, 
        ltee_data.original_pos
    )
    
    -- Log quest updates
    for quest_id, update_type in pairs(updated_quests) do
        lf("rescueable_ltee", string.format("Quest %s %s for player %s", 
            quest_id, update_type, player_name))
    end
end
```

## Key Features Implemented

### 1. Separate Quest System
- **Individual Quests**: Separate Carlos and Mary rescue missions
- **Type-specific Tracking**: Each quest focuses on specific LTee type
- **Flexible Objectives**: Supports "rescue X of type Y" objectives
- **Persistent Storage**: Uses player metadata for quest persistence
- **Real-time Updates**: Immediate progress tracking via rescue events

### 2. Reward System
- **Objective Rewards**: Diamonds for Carlos rescues, gold ingots for Mary rescues
- **Completion Rewards**: Mese crystals for completing individual quests
- **Inventory Management**: Automatic inventory checking and reward distribution
- **Fallback Handling**: Drops rewards on ground if inventory is full

### 3. UI System (Enhancement EH1)
- **Quest List Interface**: Shows available, active, and completed quests
- **Story Buttons**: Story viewing for available quests in both Quest Book and Quest Giver UI
- **Accept Buttons**: Direct quest acceptance through UI or after reading story
- **Progress Display**: Detailed objective progress with rescue counts
- **Visual Indicators**: Color-coded progress (green for complete, yellow for in-progress)
- **Story UI**: Dedicated story viewing interface with accept/reject/back buttons

### 4. NPC Protection
- **Passive Behavior**: Quest giver and LTees are non-attackable
- **Race Isolation**: Quest giver uses unique "QUEST_GIVER" race
- **Peaceful Properties**: `peaceful = true, passive = true, attack_type = "none"`

## File Structure

```
mods/lottmobs/
├── quest_system.lua      # Core quest API and data structures
├── quest_stories.lua     # Story definitions and retrieval API
├── quest_ui.lua          # Formspec-based quest interface
├── quest_giver.lua       # Quest giver NPC entity
├── quest_test.lua        # Testing utilities and commands
├── rescueable_ltee.lua   # Modified to hook quest events
└── init.lua             # Updated to load new modules
```

## Available Commands

### Quest Management Commands
- `/accept_quest_carlos` - Accept the Carlos Rescue Mission
- `/accept_quest_mary` - Accept the Mary Rescue Mission
- `/quest_status` - Check current quest status
- `/cleanup_old_quests` - Remove old rescue_multiple quest data

### Spawn Commands for New Units
- `/spawn_quest_giver` - Spawn Quest Giver NPC
- `/spawn_rescueable_mary_ltee` - Spawn rescueable Mary LTee
- `/spawn_rescueable_carlos_ltee` - Spawn rescueable Carlos LTee
- `/spawn_rescueable_ltee` - Spawn rescueable Mary LTee (legacy command)

### Testing Commands
- `/test_quest_ui` - Test quest interface
- `/test_quest_rescue <type> <count>` - Simulate rescues (e.g., `/test_quest_rescue mary 3`)
- `/test_carlos_rescue` - Test Carlos quest acceptance and rescue tracking
- `/test_quest_reset` - Reset quest progress
- `/test_quest_scenario` - Spawn complete test scenario with quest giver and rescueable LTees

### Spawn Egg Usage
All new units also have spawn eggs that can be used:
- `lottmobs:quest_giver` - Quest Giver spawn egg
- `lottmobs:rescued_mary_ltee` - Rescued Mary LTee egg (obtained by rescuing)
- `lottmobs:rescued_carlos_ltee` - Rescued Carlos LTee egg (obtained by rescuing)

## Testing and Validation

The quest system includes comprehensive testing utilities:
- **UI Testing**: Direct interface testing with `/test_quest_ui`
- **Rescue Simulation**: Simulate rescue events for testing progress tracking
- **Scenario Testing**: Complete test scenario with quest giver and rescueable LTees
- **Progress Reset**: Ability to reset quest progress for repeated testing

## Error Handling and Fixes

### Issues Resolved:
1. **Trader Conflict**: Quest giver race changed from "GAMEltee" to "QUEST_GIVER" to prevent trader UI interference
2. **Close Button Bug**: Fixed formspec close button by returning `false` instead of `true`
3. **Nil Value Errors**: Added comprehensive nil checks in allies.lua for robust entity handling
4. **Mob Attacks**: Added `passive = true` to prevent other mobs from attacking quest giver and LTees

## Performance Considerations

- **Lazy Loading**: Quest data loaded only when needed
- **Efficient Storage**: Player metadata used for persistent storage
- **Minimal Overhead**: Event-driven updates only when rescues occur
- **Scalable Design**: Easy to add new LTee types and quest objectives

## Future Enhancements

The system is designed for extensibility:
- **New Quest Types**: Easy to add different quest objectives
- **Multiple Quest Givers**: Can support multiple quest NPCs
- **Complex Objectives**: Framework supports more complex quest logic
- **UI Enhancements**: Formspec system allows for rich interface improvements

## Conclusion

The quest system implementation provides a complete, robust, and extensible foundation for quest management in the Lord of the Test game. All original requirements have been fulfilled with additional enhancements for usability and reliability.