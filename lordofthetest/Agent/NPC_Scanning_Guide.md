# NPC Scanning Guide for LLM Analysis

## Overview
This guide provides patterns and keywords for accurately identifying NPC-related code in Minetest games, based on analysis of the Lord of the Test codebase.

## Primary Search Patterns

### Core NPC Registration Patterns
```
mobs:register_mob(
minetest.register_entity(
minetest.register_npc(
```

### NPC Entity Name Patterns
```
lottmobs:
npc:
mobs:
_trader
_guard
_riddler
_angel
```

### Key NPC Files/Directories
```
mods/*mobs*/
mods/*npc*
**/mobs.lua
**/npc.lua
**/trader.lua
**/riddler.lua
**/lt_people.lua  # Basic snacks NPCs
**/basic_snacks/  # Additional NPC mod
```

## Essential Keywords for NPC Identification

### NPC Type Indicators
```
"type = "npc""
"type = "animal""
"race = "
```

### NPC Behavior Keywords
```
on_rightclick
on_activate
on_step
on_punch
on_die
view_range
walk_velocity
run_velocity
collisionbox
textures
mesh
animation
```

### Trading System Keywords
```
trader
trade
shop
goods
items
price
payment
inventory
formspec
lottmobs_trader
```

### Dialog/Interaction Keywords
```
quotes
messages
riddles
question
answers
formspec
chat_send_player
```

### Combat/AI Keywords
```
attack_type
damage
armor
hp_min
hp_max
follow
hostile
peaceful
group_attack
```

## Ltee-Specific Patterns

### Ltee Race Identifiers
```
GAMEltee
ltee
LT
character_*_LT_*.png
lottmobs:ltee
```

### Ltee NPC Variants
```
ltee_riddler
ltee_trader
ltee_guard
ltangel
mary
alisa
club
liam
pat
carlos
sarah
dusk
santa
farmer
```

## Search Strategy for LLM Prompts

### Step 1: Broad NPC Discovery
```
Search for: mobs:register_mob OR minetest.register_entity
Filter for: "type = "npc"" OR race keywords
```

### Step 2: Identify Ltee NPCs
```
Search for: lottmobs:ltee OR GAMEltee OR character_*_LT_*
Include: riddler, trader, guard, angel variants
Include: snacks: entities (basic_snacks mod)
```

### Step 3: Extract NPC Features
```
For each NPC found, document:
- Entity name and registration function
- Source file and line numbers
- Event handlers (on_rightclick, on_step, etc.)
- Quotes/messages location
- Shop items (if trader)
- Special abilities (combat, following, etc.)
```

### Step 4: Cross-Reference Trading Systems
```
Search for: lottmobs_trader OR trader_goods
Map: NPC entities -> their shop definitions
```

## Common NPC Code Structures

### Basic NPC Registration
```lua
mobs:register_mob("modname:npc_name", {
    type = "npc",
    race = "RACE_NAME",
    -- properties
    on_rightclick = function(self, clicker)
        -- interaction code
    end,
})
```

### Trader NPC Pattern
```lua
on_rightclick = function(self, clicker)
    lottmobs_trader(self, clicker, entity, race_data, "background.png", "privilege")
end
```

### Dialog/Quote Pattern
```lua
local quotes = {
    "Quote 1",
    "Quote 2",
    -- more quotes
}
```

### Riddle NPC Pattern
```lua
local riddles = {
    {
        question = "Question text",
        answers = {"Answer1", "Answer2", ...},
        correct = 2
    }
}
```

## File Prioritization for NPC Analysis

### High Priority (Core NPC Files)
1. `**/mobs.lua` - Main mob definitions
2. `**/npc.lua` - NPC-specific code
3. `**/trader.lua` - Trading systems
4. `**/riddler.lua` - Dialog/riddle systems

### Medium Priority (Supporting Files)
1. `**/trader_goods.lua` - Shop item definitions
2. `**/special_mobs.lua` - Special NPC variants
3. `**/functions.lua` - Helper functions
4. `**/lt_people.lua` - Basic snacks NPCs

### Low Priority (Related Files)
1. `**/init.lua` - Mod initialization
2. `**/craftitems.lua` - NPC-related items
3. `**/spawner.lua` - NPC spawning logic

## Prompt Template for NPC Analysis

```
Analyze this Minetest game codebase for all NPC-related content. Focus on:

1. NPC Discovery:
   - Search for mobs:register_mob and minetest.register_entity calls
   - Identify entities with type="npc" or race keywords
   - Look for Ltee-specific NPCs (GAMEltee, ltee, LT patterns)
   - Check basic_snacks mod for additional NPCs (snacks: entities)

2. Feature Extraction:
   - Document all event handlers (on_rightclick, on_step, etc.)
   - Find quote/message locations and content
   - Identify shop/trading functionality
   - Note special abilities (combat, following, dialogs)

3. Cross-Reference:
   - Map NPCs to their shop goods in trader files
   - Connect form handlers to their NPC entities
   - Link chat commands to NPC spawning

4. Output Format:
   - Entity name, source file, line numbers
   - Function/event list with locations
   - Quotes location and content snippets
   - Shop items location and item lists
   - Special features and abilities

Search patterns to use: [include the patterns from this guide]
```

## Verification Checklist

### For Each NPC Found:
- [ ] Entity registration located
- [ ] All event handlers identified
- [ ] Quotes/messages extracted
- [ ] Shop items mapped (if applicable)
- [ ] Special abilities documented
- [ ] Spawn conditions noted
- [ ] Chat commands linked

### Completeness Checks:
- [ ] All mob/NPC files scanned
- [ ] Trading system cross-referenced
- [ ] Ltee-specific variants identified
- [ ] Christmas/special NPCs included
- [ ] Formspec interactions documented

This guide ensures comprehensive NPC identification by targeting the specific patterns and structures used in Minetest NPC implementations.

**Note:** For detailed NPC preview generation instructions, see `Agent\NPC_Preview_Generation_Guide.md`.
