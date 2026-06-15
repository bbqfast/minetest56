


New entities
1.
- LTee NPC that can be rescued
- a rescue bag
- player right click on the rescuable LT will create a spawn egg in player inventory



implementation plan:

## Phase 1: Core Entity Creation
**File**: `mods/lottmobs/rescueable_ltee.lua`

Create a new LTee NPC variant with:
- Entity name: `lottmobs:rescueable_ltee`
- Reduced health (10-15 HP) to appear vulnerable
- No combat abilities (peaceful = true)
- Custom textures showing distressed/appearance
- Immobilized or very slow movement
- Help-seeking quotes and behaviors
- Rescue state tracking (`self.rescued = false`)

## Phase 2: Rescue Bag Item
**File**: `mods/lottmobs/rescue_bag.lua`

Create `lottmobs:rescue_bag` with:
- Tool for rescuing LTees (no inventory capability)
- Right-click functionality to rescue LTees
- Left-click functionality to show usage instructions
- Custom texture and description
- Creates spawn eggs directly in player inventory

## Phase 3: Rescue Interaction Logic
Implement the core rescue mechanic:
- Right-click detection on rescueable LTee
- Validation (holding rescue bag, correct NPC type)
- Create spawn egg directly in player inventory
- Remove original NPC entity
- Rescue completion feedback with timestamp

## Phase 4: Spawn System
**Options**:
- Natural spawning in dangerous areas
- Spawner nodes in dungeons/caves  
- Chat command: `/spawn_rescueable_ltee` (implemented)
- Integration with existing spawn systems

## Phase 5: Crafting Recipe
Add recipe for rescue bag:
- Materials: leather, string, maybe special components
- Crafting station: workbench or special crafting
- Recipe balance considerations

## Phase 6: Rescue Completion
When player uses rescued LTee spawn egg:
- Spawn rescued LTee with improved stats
- Rescued LTee has better health and movement
- No reward system (simplified implementation)

## Technical Approach

### Entity Structure
```lua
mobs:register_mob("lottmobs:rescueable_ltee", {
    type = "npc",
    race = "GAMEltee",
    hp_min = 10,
    hp_max = 15,
    -- Vulnerable appearance
    -- Rescue-specific behaviors
    on_rightclick = rescue_interaction,
})
```

### Bag Item Structure
```lua
minetest.register_craftitem("lottmobs:rescue_bag", {
    description = "Rescue Bag\nRight-click rescueable LTees to rescue them",
    inventory_image = "bags_medium.png",
    on_use = function(itemstack, user, pointed_thing)
        -- Left-click: show usage instructions
    end,
    on_place = function(itemstack, placer, pointed_thing)
        -- Right-click: standard placement
    end,
})
```

### Rescued LTee Spawn Egg Structure
```lua
mobs:register_egg("lottmobs:rescued_ltee", "Rescued LTee", preview_texture, 0)
```

### Integration Points
- **Existing LTee systems**: Leverage quotes, textures, models from `ltees.lua`
- **Trading system**: Potential integration with rescued LTee becoming traders
- **HUD system**: Show rescue status and progress
- **Spawn systems**: Use existing spawner patterns from `mob_spawners.lua`

## File Structure
```
mods/lottmobs/
├── rescueable_ltee.lua     # Rescueable NPC entity and spawn egg
├── rescue_bag.lua          # Rescue bag item
├── init.lua               # Include new files
└── textures/
    ├── character_Mary_LT_mt.png  # Rescued LTee texture
    ├── bags_medium.png           # Rescue bag texture
    ├── skindb_mask_*.png         # Preview generation masks
    └── skindb_transform.png      # Preview transform mask
```

## Key Features Summary
- **Rescueable LTee NPC**: Vulnerable LTee that can be rescued
- **Rescue Bag**: Tool for rescuing LTees (no inventory)
- **Right-click Rescue**: Creates spawn egg in player inventory
- **Spawn Egg System**: Rescued LTee spawn eggs with professional previews
- **Rescued LTee Mob**: Improved stats when spawned from egg
- **Spawn System**: Chat command implemented for testing
- **Crafting Recipe**: Create rescue bags from materials
- **Preview System**: Professional spawn egg previews using mask system



Iteration 1:
- Implement phase 1 (COMPLETED)



Iteration 2:
- simplify implementation of (COMPLETED)
- rescue bag doesn't hold items (COMPLETED)
- when rescue with Ltee with rescue bag will directly put the rescued LTee in your player inventory as spawn egg (COMPLETED)

2a:
use existing bag for rescue bag image for now (COMPLETED)
refer to C:\Minetest\v5.6\games\lordofthetest\Agent\desc-bag-system.md

2b: 
use this image for rescuable Ltee image (COMPLETED)
C:\Minetest\v5.6\games\lordofthetest\mods\lottmobs\lt_skins\character_Mary_LT_mt.png

2c:
use the face for captured LTee for image in inventory after captured (COMPLETED)
refer to:
C:\Minetest\v5.6\games\lordofthetest\Agent\NPC_Preview_Generation_Guide.md

## Current Status
- ✅ Phase 1: Core Entity Creation (COMPLETED)
- ✅ Phase 2: Rescue Bag Item (COMPLETED)
- ✅ Phase 3: Rescue Interaction Logic (COMPLETED)
- ✅ Phase 4: Spawn System (PARTIAL - chat command implemented)
- ❌ Phase 5: Crafting Recipe (PENDING)
- ❌ Phase 6: Rescue Completion (SIMPLIFIED - no reward system)


2d:
✅ COMPLETED - create another rescuable LT using this skin
"C:\Minetest\v5.6\games\lordofthetest\mods\lottmobs\lt_skins\character_Carlos_LT_third_LT_stolen_mt.png"

✅ COMPLETED - refactor to reuse code as much as possible

## New Features Added:
- **Rescueable Carlos LTee**: New variant using Carlos texture
- **Code Refactoring**: Shared functionality for all rescuable LT types
- **Separate Spawn Eggs**: `lottmobs:rescued_mary_ltee` and `lottmobs:rescued_carlos_ltee`
- **New Chat Commands**: 
  - `/spawn_rescueable_mary_ltee` - Spawn Mary variant
  - `/spawn_rescueable_carlos_ltee` - Spawn Carlos variant
  - `/spawn_rescueable_ltee` - Legacy command (spawns Mary)

## Technical Improvements:
- **Modular Design**: `rescueable_ltee_types` configuration table
- **Shared Functions**: `create_rescueable_ltee()` factory function
- **Type Tracking**: Each LT stores its type for proper rescue logic
- **Backward Compatibility**: Legacy command still works


Appendix (AD1):s
Implementation details
Agent\Impl-rescueable-ltee.md


