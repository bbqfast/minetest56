# Bag System Documentation

## Overview

The Lord of the Test game implements a comprehensive bag system with 4 total bags: 3 regular bags of different sizes (Small, Medium, Large) and 1 designated Food Bag. The system integrates with the main armor inventory interface and uses detached inventories for bag management.

## Bag Types and Sizes

### Small Bag (`lottinventory:small`)
- **Slots**: 8 inventory slots
- **Groups**: `{bagslots=8}`
- **Crafting Recipe**:
  ```lua
  {'', 'group:stick', ''},
  {'group:wood', 'group:wood', 'group:wood'},
  {'group:wood', 'group:wood', 'group:wood'}
  ```

### Medium Bag (`lottinventory:medium`) 
- **Slots**: 16 inventory slots
- **Groups**: `{bagslots=16}`
- **Crafting Recipe**:
  ```lua
  {'', 'group:stick', ''},
  {'group:wood', 'lottinventory:small', 'group:wood'},
  {'group:wood', 'group:wood', 'group:wood'}
  ```

### Large Bag (`lottinventory:large`)
- **Slots**: 24 inventory slots
- **Groups**: `{bagslots=24, forbidden=1}`
- **Crafting Recipe**:
  ```lua
  {'', 'default:steel_ingot', ''},
  {'group:wood', 'lottinventory:medium', 'group:wood'},
  {'group:wood', 'group:wood', 'group:wood'}
  ```

### Food Bag (Bag 4)
- **Special Purpose**: Used for mob feeding mechanics
- **Integration**: NPCs/Guards can consume food directly from `bag4contents`
- **Usage**: Referenced in `lottmobs/functions.lua` for guard feeding

## System Architecture

### Inventory Structure
- **Bag Slots**: Each player has 4 bag slots: `bag1`, `bag2`, `bag3`, `bag4`
- **Detached Inventories**: Managed via `{player_name}_bags` detached inventory
- **Content Storage**: Bag contents stored in `bag{N}contents` (e.g., `bag1contents`, `bag4contents`)

### Key Files
- `mods/lottinventory/init.lua` - Bag item definitions and crafting recipes
- `mods/lottarmor/armor.lua` - Bag UI, formspec management, and inventory handling
- `mods/lottmobs/functions.lua` - Food bag consumption logic
- `mods/lottinventory/functions.lua` - Inventory helper functions

## UI Navigation Flow

### 1. Main Inventory UI with Bag Icon

**File**: `mods/lottarmor/armor.lua`, Line 102
```lua
.."image_button[7,1;1,1;bags.png;bags;]",
```

The main armor formspec includes a bag icon button at position `[7,1]` (top-right corner) using the `bags.png` texture.

### 2. Bag Icon Click Handler

**File**: `mods/lottarmor/armor.lua`, Lines 143-147
```lua
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.bags then
		inventory_plus.set_inventory_formspec(player, get_formspec(player,"bags"))
		return
	end
```

When the bag icon is clicked (`fields.bags`), the system switches to the bag selection screen.

### 3. Bag Selection Screen

**File**: `mods/lottarmor/armor.lua`, Lines 113-126
```lua
if page=="bags" then
	return "size[8,7.5]"
		.."list[current_player;main;0,3.5;8,4;]"
		.."button[0,0;2,0.5;main;Back]"
		.."button[0,2;2,0.5;bag1;Bag 1]"
		.."button[2,2;2,0.5;bag2;Bag 2]"
		.."button[4,2;2,0.5;bag3;Bag 3]"
		.."button[6,2;2,0.5;bag4;Food Bag]"
		.."list[detached:"..player:get_player_name().."_bags;bag1;0.5,1;1,1;]"
		.."list[detached:"..player:get_player_name().."_bags;bag2;2.5,1;1,1;]"
		.."list[detached:"..player:get_player_name().."_bags;bag3;4.5,1;1,1;]"
		.."list[detached:"..player:get_player_name().."_bags;bag4;6.5,1;1,1;]"
		.."background[5,5;1,1;gui_formbg.png;true]"
end
```

The bag selection screen displays:
- **Back button** to return to main inventory
- **4 bag buttons** (Bag 1, Bag 2, Bag 3, Food Bag)
- **4 bag slots** showing current bags in detached inventory

### 4. Individual Bag Screen

**File**: `mods/lottarmor/armor.lua`, Lines 127-138
```lua
for i=1,4 do
	if page=="bag"..i then
		local image = player:get_inventory():get_stack("bag"..i, 1):get_definition().inventory_image
		return "size[8,8.5]"
			.."list[current_player;main;0,4.5;8,4;]"
			.."button[0,0;2,0.5;main;Main]"
			.."button[2,0;2,0.5;bags;Bags]"
			.."image[7,0;1,1;"..image.."]"
			.."list[current_player;bag"..i.."contents;0,1;8,3;]"
			.."listring[]"
			.."background[5,5;1,1;gui_formbg.png;true]"
	end
end
```

When a specific bag is clicked, it shows:
- **Main button** to return to main inventory
- **Bags button** to return to bag selection
- **Bag image** in top-right corner
- **Bag contents** in 8x3 grid (24 slots max)

### 5. Field Handlers for Navigation

**File**: `mods/lottarmor/armor.lua`, Lines 148-157
```lua
for i=1,4 do
	local page = "bag"..i
	if fields[page] then
		if player:get_inventory():get_stack(page, 1):get_definition().groups.bagslots==nil then
			page = "bags"
		end
		inventory_plus.set_inventory_formspec(player, get_formspec(player,page))
		return
	end
end
```

Each bag button click validates the bag has `bagslots` group, then navigates to the individual bag view.

## Bag Management Logic

### Detached Inventory Setup

**File**: `mods/lottarmor/armor.lua`, Lines 497-522
```lua
local bags_inv = minetest.create_detached_inventory(name.."_bags",{
	on_put = function(inv, listname, index, stack, player)
		player:get_inventory():set_stack(listname, index, stack)
		player:get_inventory():set_size(listname.."contents", stack:get_definition().groups.bagslots)
	end,
	on_take = function(inv, listname, index, stack, player)
		player:get_inventory():set_stack(listname, index, nil)
	end,
	allow_put = function(inv, listname, index, stack, player)
		if stack:get_definition().groups.bagslots then
			return 1
		else
			return 0
		end
	end,
	allow_take = function(inv, listname, index, stack, player)
		if player:get_inventory():is_empty(listname.."contents")==true then
			return stack:get_count()
		else
			return 0
		end
	end,
	allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
}, name)
```

### Bag Slot Initialization

**File**: `mods/lottarmor/armor.lua`, Lines 523-528
```lua
for i=1,4 do
	local bag = "bag"..i
	player_inv:set_size(bag, 1)
	bags_inv:set_size(bag, 1)
	bags_inv:set_stack(bag,1,player_inv:get_stack(bag,1))
end
```

## Food Bag Special Functionality

### Guard Feeding System

**File**: `mods/lottmobs/functions.lua`, Lines 300-301
```lua
local taken = food_inv:remove_item("bag4contents",
                                   ItemStack(food .. " 1"))
```

Guards and NPCs can consume food directly from the player's `bag4contents`, making the Food Bag essential for mob feeding mechanics.

## Inventory Plus Integration

### Formspec Management

**File**: `mods/lottinventory/init.lua`, Lines 9-11
```lua
inventory_plus.set_inventory_formspec = function(player, formspec)
	minetest.show_formspec(player:get_player_name(), "custom", formspec)
end
```

The `inventory_plus` system handles formspec transitions between UI screens.

## Complete Navigation Flow

1. **Main Inventory** → Click bag icon → **Bag Selection Screen**
2. **Bag Selection** → Click bag button → **Individual Bag Contents**
3. **Individual Bag** → Click "Bags" → **Bag Selection Screen**
4. **Any Screen** → Click "Main" → **Main Inventory**

## Bag Usage Rules

- **Putting bags**: Only items with `bagslots` group can be placed in bag slots
- **Removing bags**: Can only remove bags when their contents are empty
- **Content size**: Determined by bag's `bagslots` group value (8, 16, or 24)
- **Food bag**: Has special mob feeding functionality beyond regular storage

## Textures and Assets

- **Bag Icons**: `bags_small.png`, `bags_medium.png`, `bags_large.png`
- **UI Button**: `bags.png` (main inventory bag button)
- **License**: Bag textures by Amaz (CC BY-SA 3.0) and Brett O'Donnell (BSD-3-Clause)

This bag system provides a comprehensive inventory expansion solution with progressive crafting, intuitive UI navigation, and special functionality for food storage and mob feeding.