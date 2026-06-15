# Rescueable LTee Implementation Documentation

## Phase 1: Core Entity Creation - COMPLETED

### Files Created/Modified
- **`mods/lottmobs/rescueable_ltee.lua`** - New rescueable LTee NPC entity
- **`mods/lottmobs/init.lua`** - Added rescueable_ltee.lua to loading sequence

### Implementation Details

#### Entity Registration (Refactored for Multiple Types)
```lua
-- Configuration table for multiple rescueable LT types
local rescueable_ltee_types = {
    mary = {
        texture = "character_Mary_LT_mt.png",
        nametag = "Rescueable Mary LTee",
        rescued_egg_name = "lottmobs:rescued_mary_ltee",
        egg_description = "Rescued Mary LTee",
        spawn_command = "spawn_rescueable_mary_ltee"
    },
    carlos = {
        texture = "character_Carlos_LT_third_LT_stolen_mt.png",
        nametag = "Rescueable Carlos LTee",
        rescued_egg_name = "lottmobs:rescued_carlos_ltee",
        egg_description = "Rescued Carlos LTee",
        spawn_command = "spawn_rescueable_carlos_ltee"
    }
}

-- Factory function creates entities for each type
local function create_rescueable_ltee(ltee_type)
    -- Returns complete mob definition based on type configuration
end

-- Auto-registration for all types
for ltee_type, _ in pairs(rescueable_ltee_types) do
    mobs:register_mob("lottmobs:rescueable_" .. ltee_type .. "_ltee", mob_def)
end
```

#### Registered Entities
- **`lottmobs:rescueable_mary_ltee`** - Mary variant using Mary texture
- **`lottmobs:rescueable_carlos_ltee`** - Carlos variant using Carlos texture

#### Vulnerable Characteristics
- **Health**: 10-15 HP (reduced to appear vulnerable)
- **Movement**: Very slow (walk_velocity = 0.5, run_velocity = 1)
- **Combat**: No attack capabilities (damage = 0, peaceful = true)
- **Armor**: Low protection (armor = 50)
- **View Range**: 8 blocks (limited awareness)

#### Help-Seeking Behavior
- **8 unique rescue quotes** that cycle automatically
- **Periodic chat messages** every 10 seconds to nearby players
- **Quote cycling system** with random starting index
- **Nil-safe initialization** to prevent loading errors

#### Rescue State Tracking
- `self.rescued = false` - Tracks if LTee has been rescued
- `self.rescue_quotes` - Array of help messages
- `self.current_quote_index` - Current quote position
- `self.quote_timer` - Timer for quote cycling
- `self.help_timer` - Timer for help message frequency
- `self.ltee_type` - Stores LT type for proper rescue logic

#### Type-Specific Rescue Logic
- Each LT stores its type (mary/carlos) in `self.ltee_type`
- Rescue creates appropriate spawn egg based on type
- Type-specific nametags and textures
- Shared behavior with individual customization

#### Chat Commands
- **`/spawn_rescueable_mary_ltee`** - Spawns Mary variant for testing
- **`/spawn_rescueable_carlos_ltee`** - Spawns Carlos variant for testing
- **`/spawn_rescueable_ltee`** - Legacy command (spawns Mary variant)
- Proper validation and error handling
- Logging integration with existing `lf()` function

#### Error Handling
- **Nil checks** for all entity variables to prevent loading errors
- **Safe initialization** in `do_custom` function
- **Proper cleanup** on entity death

---

## Phase 2: Rescue Bag Item - COMPLETED

### Files Created/Modified
- **`mods/lottmobs/rescue_bag.lua`** - New rescue bag item with inventory system
- **`mods/lottmobs/init.lua`** - Added rescue_bag.lua to loading sequence
- **`mods/lottmobs/craftitems.lua`** - Cleaned up (moved rescue bag code to separate file)

### Implementation Details

#### Item Registration
```lua
minetest.register_craftitem("lottmobs:rescue_bag", {
    description = "Rescue Bag\nUse to rescue vulnerable LTees",
    inventory_image = "lottmobs_rescue_bag.png",
    stack_max = 1,  -- Only one bag per inventory slot
})
```

#### Inventory System
- **Metadata-based storage** using item metadata for persistence
- **Serialized data storage** with `minetest.serialize()`/`minetest.deserialize()`
- **Unique ID system** for each rescued LTee using timestamps
- **Dynamic description updates** showing LTee count in bag

#### Left-Click Contents Display
- **Formspec interface** (8x9) showing rescued LTee list
- **Detailed information display**:
  - LTee name
  - Status ([Rescued] or [Released])
  - Health points
  - Rescue time
- **Release button** for non-released LTees
- **Player inventory integration** in formspec

#### Release Functionality
- **Spawn system** for released LTees near player
- **Status updates** marking LTees as released
- **Timestamp tracking** for release events
- **Proper validation** requiring bag to be held

#### Data Structure
```lua
rescued_ltees = {
    [timestamp_id] = {
        id = unique_id,
        name = "LTee Name",
        health = current_hp,
        rescue_time = "YYYY-MM-DD HH:MM:SS",
        released = false,
        release_time = nil,
    }
}
```

#### Helper Functions
- `lottmobs.add_rescued_ltee_to_bag()` - Phase 3 integration function
- **Formspec handling** with `minetest.register_on_player_receive_fields()`
- **Validation systems** for bag operations

#### Technical Features
- **Persistent storage** across game sessions
- **Error handling** for empty bags and invalid operations
- **Logging integration** with existing systems
- **Placeholder right-click** for Phase 3 implementation

---

## Phase 3: Rescue Interaction Logic - COMPLETED

### Implementation Details

#### Right-Click Rescue System
- **Validation**: Checks if player holds rescue bag (`lottmobs:rescue_bag`)
- **Type Detection**: Reads `self.ltee_type` from rescued LTee
- **Spawn Egg Creation**: Generates type-specific spawn egg:
  - Mary → `lottmobs:rescued_mary_ltee`
  - Carlos → `lottmobs:rescued_carlos_ltee`
- **Inventory Transfer**: Adds spawn egg directly to player inventory
- **Entity Removal**: Removes original LTee entity after successful rescue
- **Feedback Messages**: Success/failure chat messages with timestamps

#### Spawn Egg System
- **Professional Previews**: Uses NPC Preview Generation Guide with mask system
- **Type-Specific Textures**: Each egg shows correct LT face preview
- **Separate Registration**: `mobs:register_egg()` for each LT type
- **Inventory Integration**: Standard spawn egg behavior

#### Rescue Data Structure
```lua
local ltee_data = {
    name = self.nametag or "Rescueable LTee",
    health = self.object:get_hp() or 10,
    original_pos = self.object:get_pos(),
    rescue_quotes = self.rescue_quotes,
    ltee_type = self.ltee_type or "mary",  -- Critical for type tracking
}
```

#### Error Handling
- **Inventory Full Check**: Prevents rescue if no space available
- **Bag Validation**: Ensures player holds correct rescue bag
- **Type Safety**: Fallback to "mary" if type is nil
- **Entity Cleanup**: Safe removal with delay for message display

#### Logging Integration
- **Rescue Events**: Logs successful rescues with player name and location
- **Type Tracking**: Logs which LT type was rescued
- **Timestamp**: Records rescue time for debugging

---

## Phase 2d: Multi-Type System & Carlos Variant - COMPLETED

### Files Modified
- **`mods/lottmobs/rescueable_ltee.lua`** - Complete refactoring for multiple types

### Implementation Details

#### Code Refactoring
- **Configuration Table**: `rescueable_ltee_types` for easy type management
- **Factory Function**: `create_rescueable_ltee()` generates entities dynamically
- **Auto-Registration**: Loop registers all configured types automatically
- **Shared Logic**: All rescue behavior, animations, and quotes are shared
- **Type Storage**: Each entity stores its type in `self.ltee_type`

#### Carlos LTee Variant
- **Texture**: `character_Carlos_LT_third_LT_stolen_mt.png`
- **Entity**: `lottmobs:rescueable_carlos_ltee`
- **Nametag**: "Rescueable Carlos LTee"
- **Spawn Egg**: `lottmobs:rescued_carlos_ltee`
- **Chat Command**: `/spawn_rescueable_carlos_ltee`

#### Backward Compatibility
- **Legacy Command**: `/spawn_rescueable_ltee` still works (spawns Mary)
- **Existing Functionality**: All original rescue mechanics preserved
- **Migration**: No breaking changes to existing saves

#### Extensibility
- **Easy Addition**: New LT types only require configuration table entry
- **Zero Code Duplication**: Shared functions handle all types
- **Consistent Behavior**: All variants follow same rescue pattern

---

## Current Status

### Completed Features
✅ **Phase 1**: Rescueable LTee NPC entity with help-seeking behavior (Multi-type support)
✅ **Phase 2**: Rescue bag item with inventory and contents display system
✅ **Phase 3**: Rescue interaction logic with type-specific spawn eggs
✅ **Phase 2d**: Multi-type system with Carlos variant and code refactoring

### Current Implementation
- **Two Rescueable LT Types**: Mary and Carlos variants
- **Refactored Code**: Shared functionality with type-specific customization
- **Complete Rescue System**: Right-click rescue → spawn egg → rescued LT
- **Professional Previews**: Texture-based spawn egg previews
- **Multiple Chat Commands**: Type-specific spawning commands
- **Backward Compatibility**: Legacy commands still functional

### Testing Commands
- **`/spawn_rescueable_mary_ltee`** - Spawn Mary variant for testing
- **`/spawn_rescueable_carlos_ltee`** - Spawn Carlos variant for testing
- **`/spawn_rescueable_ltee`** - Legacy command (spawns Mary variant)
- Rescue bag can be obtained via creative mode (crafting recipe pending Phase 6)

### Integration Points
- **Existing LTee systems**: Leverages textures, models, and patterns from `ltees.lua`
- **Logging system**: Uses `lf()` function for debugging
- **Formspec system**: Standard Minetest GUI implementation
- **Entity system**: Follows existing mob registration patterns
- **Preview System**: Uses NPC Preview Generation Guide for professional spawn eggs

### Known Issues
- **Texture placeholder**: Uses existing meat texture as placeholder (`lottmobs_rescue_bag.png`)
- **Crafting recipe**: Not yet implemented (Phase 6)
- **Natural spawning**: Not yet implemented (Phase 5)

---

## Next Steps

### Phase 5: Spawn System (Optional)
- Natural spawning in dangerous areas
- Spawner nodes in dungeons/caves
- Integration with existing spawn systems

### Phase 6: Crafting Recipe
- Add recipe for rescue bag
- Materials: leather, string, maybe special components
- Crafting station: workbench or special crafting

### Dependencies for Future Phases
- All core rescue functionality is complete and operational
- Multi-type system is ready for additional variants
- Spawn egg system supports unlimited LT types