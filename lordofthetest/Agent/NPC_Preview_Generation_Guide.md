# NPC Preview Generation Guide

## Overview
The `lt_people.lua` file implements a sophisticated preview generation system that creates 2D inventory icons from 3D character textures using Minetest's image manipulation commands.

## Key Components

### 1. Preview Generation Function
**Location:** `mods/basic_snacks/lt_people.lua` lines 17-70
**Function:** `get_preview(texture_file)`

### 2. Image Manipulation Commands
The system uses these Minetest texture modifiers:
- `[combine:WxH:X,Y=texture` - Extracts portions from source texture
- `^[mask:filename.png` - Applies transparency masks
- `^[transformFX` - Flips horizontally
- `^[resize:WxH` - Resizes final image

### 3. Body Part Assembly
The preview is constructed by combining these body parts:
- **Chest:** `skindb_mask_chest.png` at (-16,-12)
- **Head:** `skindb_mask_head.png` at (-4,-8)  
- **Hat:** `skindb_mask_head.png` at (-36,-8)
- **Right Arm:** `skindb_mask_rarm.png` at (-44,-12)
- **Right Leg:** `skindb_mask_rleg.png` at (0,0)
- **Left Arm:** Mirrored right arm at (-44,-12)
- **Left Leg:** Mirrored right leg at (0,0)

### 4. Format Handling
Supports both 1.5 and 1.8 skin formats:
- **1.5 format:** Standard 32x64 skins
- **1.8 format:** Enhanced 64x64 skins with separate layers

### 5. Final Processing
- Overlays added for 64x skins (lines 55-64)
- Final resize to 64x128 (line 67)
- Transform mask applied for final preview

## Generic Preview Creation Guide

### Step 1: Create Preview Function
```lua
local function create_npc_preview(texture_file, format)
    format = format or "1.5"  -- default to 1.5 format
    
    local player_skin = "("..texture_file..")"
    local preview = ""
    
    -- Assemble body parts (same as lt_people.lua)
    preview = preview .. "([combine:16x32:-16,-12=" .. player_skin .. "^[mask:skindb_mask_chest.png)^"
    preview = preview .. "([combine:16x32:-4,-8=" .. player_skin .. "^[mask:skindb_mask_head.png)^"
    -- ... continue with all body parts
    
    -- Handle format-specific mirroring
    if format == "1.8" then
        -- 1.8 format mirroring
        left_arm = "([combine:16x32:-24,-44=" .. player_skin .. "^[mask:(skindb_mask_rarm.png^[transformFX))^"
        left_leg = "([combine:16x32:-12,-32=" .. player_skin .. "^[mask:(skindb_mask_rleg.png^[transformFX))^"
    else
        -- 1.5 format mirroring
        left_arm = "([combine:16x32:-44,-12=" .. player_skin .. "^[mask:skindb_mask_rarm.png^[transformFX)^"
        left_leg = "([combine:16x32:0,0=" .. player_skin .. "^[mask:skindb_mask_rleg.png^[transformFX)^"
    end
    
    -- Add overlays and finalize
    preview = preview .. left_arm .. left_leg
    preview = "(((" .. preview .. ")^[resize:64x128)^[mask:skindb_transform.png)"
    
    return preview
end
```

### Step 2: Register NPC with Preview
```lua
-- Method A: Generate preview during registration
mobs:register_mob("modname:npc_name", {
    -- NPC properties
})

mobs:register_egg("modname:npc_name", "NPC Description", 
    create_npc_preview("character_texture.png", "1.5"), 0)

-- Method B: Pre-generate preview
local preview = create_npc_preview("character_texture.png", "1.5")
mobs:register_egg("modname:npc_name", "NPC Description", preview, 0)
```

### Step 3: Alternative Simple Preview
```lua
-- For simple cases, use direct texture manipulation
local simple_preview = "character_texture.png^[resize:32x32"
mobs:register_egg("modname:npc_name", "NPC Description", simple_preview, 0)
```

## Dependencies and Requirements

### Required Mask Files
- `skindb_mask_chest.png` - Chest area mask
- `skindb_mask_head.png` - Head area mask  
- `skindb_mask_rarm.png` - Right arm mask
- `skindb_mask_rleg.png` - Right leg mask
- `skindb_transform.png` - Final transform mask

### Texture Format Requirements
- Source textures should be standard Minetest character skins
- Supports both 32x64 (1.5) and 64x64 (1.8) formats
- Texture files must be accessible in mod's texture path

## Integration Checklist

### For New NPCs:
- [ ] Copy or create required mask files
- [ ] Add `create_npc_preview()` function to your mod
- [ ] Call preview generation in `mobs:register_egg()`
- [ ] Test preview appearance in inventory
- [ ] Verify preview scales correctly

### For Existing NPCs:
- [ ] Replace static preview with generated preview
- [ ] Update registration calls to use new preview function
- [ ] Test all affected spawn eggs

## Customization Options

### Body Part Positioning
Modify the X,Y coordinates in `[combine]` commands:
```lua
-- Move head higher
preview = preview .. "([combine:16x32:-4,-10=" .. player_skin .. "^[mask:skindb_mask_head.png)^"

-- Adjust arm position
preview = preview .. "([combine:16x32:-46,-12=" .. player_skin .. "^[mask:skindb_mask_rarm.png)^"
```

### Final Sizing
Change the resize dimensions:
```lua
-- Larger preview
preview = "(((" .. preview .. ")^[resize:96x192)^[mask:skindb_transform.png)"

-- Smaller preview  
preview = "(((" .. preview .. ")^[resize:48x96)^[mask:skindb_transform.png)"
```

## Troubleshooting

### Common Issues:
1. **Missing mask files** - Ensure all mask PNGs exist in mod textures
2. **Incorrect texture paths** - Verify texture file accessibility
3. **Wrong format detection** - Check skin format matches expected dimensions
4. **Preview too small/large** - Adjust resize parameters

### Debug Commands:
```lua
-- Test preview generation
local test_preview = create_npc_preview("test_texture.png", "1.5")
minetest.log("action", "Generated preview: " .. test_preview)

-- Check if texture exists
minetest.log("action", "Texture exists: " .. tostring(minetest.get_modpath("modname")))
```

This preview system provides professional-looking inventory icons for NPCs while maintaining consistency with the game's visual style.
