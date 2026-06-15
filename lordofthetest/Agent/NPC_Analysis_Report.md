# NPC Code Analysis Report - Lord of the Test Game

## Overview
This report identifies all NPC-related code in the Lord of the Test Minetest game, with special focus on Ltee-related NPCs.

**Note:** The file `mods/basic_snacks/lt_people.lua` was missed in the initial analysis because:
1. **Location Bias:** The search focused primarily on the `lottmobs` directory as the main NPC implementation, overlooking the `basic_snacks` mod
2. **Naming Convention:** The file `lt_people.lua` didn't match the expected NPC naming patterns (mobs.lua, npc.lua, trader.lua)
3. **Entity Prefix:** NPCs in this file use the `snacks:` prefix rather than `lottmobs:`, making them appear as food items rather than NPCs
4. **Mod Directory Focus:** The basic_snacks mod name suggested food/crafting items rather than NPC content
5. **Registration Pattern:** These NPCs use a helper function `register_lt()` rather than direct `mobs:register_mob()` calls, making them harder to detect with standard pattern matching

This discovery highlights the importance of comprehensive directory scanning and not assuming NPC content based on mod names or directory structure.

## Main NPC Directories
- `mods/lottmobs/` - Primary mob/NPC implementation
- `mods/mobs/` - Base mob framework
- `mods/christmas_decor/` - Christmas-themed NPCs
- `mods/basic_snacks/` - Contains additional NPC definitions

## Ltee-Related NPCs

### 1. LT Angel (Follower NPC)
**Source File:** `mods/lottmobs/ltees.lua`
**Entity Name:** `lottmobs:ltangel`
**Function:** `minetest.register_entity("lottmobs:ltangel", {...})` (lines 556-961)

**Events:**
- `on_activate` - Initializes NPC properties and HP
- `on_punch` - Handles combat damage with custom HP system
- `on_rightclick` - Opens trader interface using `lottmobs_trader`
- `on_step` - Main AI logic for following player and combat
- `on_die` - Cleanup on death
- `on_deactivate` - Cleanup when removed

**Quotes Location:** Lines 843-852
```lua
local quotes = {
    "Hi, LT!  Welcome to Middle-Earth",
    "I'm LT angel",
    "we're newly arrived race on the middle earth",
    "We are a peaceful race here ",
    "! There are dangerous mobs around",
    "I'm here to help fight off some mobs",
    "Our village situated on red grassland",
    "Feel free to explore around",
}
```

**Shop Items:** Uses `lottmobs.ltee_angel` trader goods (lines 244-260 in trader_goods.lua)

### 2. Ltee Guard NPCs (3 Variants)
**Source File:** `mods/lottmobs/ltees.lua`
**Function:** `lottmobs.register_ltee(n, hpmin, hpmax, textures, wv, rv, damg, arm, drops, price, race_quotes)` (lines 178-294)

**Entities:**
- `lottmobs:ltee1` - Basic elf guard (line 361)
- `lottmobs:ltee2` - Full armor elf (line 412)  
- `lottmobs:ltee3` - Chestplate + powerful weapons (line 463)

**Events:**
- `on_rightclick` - Opens trader interface
- `do_custom` - HUD display with cycling quotes
- `on_die` - Cleanup with `clear_ltee_hud`

**Quotes Locations:**
- Ltee1: Lines 342-349 (`ltee_quotes_basic`)
- Ltee2: Lines 351-359 (`ltee_quotes_basic2`)

### 3. Ltee Riddler NPC
**Source File:** `mods/lottmobs/riddler.lua`
**Entity Name:** `lottmobs:ltee_riddler`
**Function:** `mobs:register_mob("lottmobs:ltee_riddler", {...})` (lines 49-124)

**Events:**
- `on_rightclick` - Opens riddle formspec interface (lines 90-123)

**Quotes Location:** Lines 3-29 - Contains 5 riddles with questions and multiple choice answers
```lua
local riddles = {
    {
        question = "What has hands but can't clap?",
        answers = {"A tree", "A clock", "A river", "A mountain", "A shadow"},
        correct = 2
    },
    -- ... 4 more riddles
}
```

**Shop Items:** None - This is a riddle NPC, not a trader

**Additional Features:**
- Formspec-based riddle interface (lines 33-45)
- Chat command: `/spawn_ltee_riddler` (lines 126-139)
- Form field handler for answers (lines 142-196)

### 4. Ltee Trader NPCs
**Source File:** `mods/lottmobs/special_mobs.lua`
**Function:** `ltee_settings(skin_file, mesh_file, ltee_goods)` (lines 211-385)

**Entities:**
- `lottmobs:ltee_trader_1` - Carlos skin, sells general goods (line 397)
- `lottmobs:ltee_trader_2` - Carla skin, sells snacks (line 399)
- `lottmobs:ltee_trader_3` - Sarah skin, sells home decor (line 403)
- `lottmobs:ltee_trader_santa` - Santa skin, sells Christmas items (line 404)

**Events:**
- `on_rightclick` - Opens trader interface

## Other NPCs

### Elf Traders
**Source File:** `mods/lottmobs/special_mobs.lua`
**Entity:** `lottmobs:elf_trader` (line 47)
**Function:** Uses `lottmobs_trader` with `lottmobs.elf` goods

### Christmas NPCs
**Source File:** `mods/christmas_decor/mobs.lua`
**Entities:**
- `christmas_decor:santa` - Santa Claus (lines 4-42)
- `christmas_decor:mrs_claus` - Mrs. Claus (lines 4-42)
- `christmas_decor:reindeer` - Reindeer (lines 44-85)
- `christmas_decor:rudolf` - Rudolf (lines 44-85)

### Basic Snacks NPCs (Ltee Characters)
**Source File:** `mods/basic_snacks/lt_people.lua`
**Function:** `register_lt(mob_name, mob_desc, texture_file, preview)` (lines 73-126)
**Registration Pattern:** Uses `mobs:register_mob("snacks:"..mob_name, {...})`

**Entities:**
- `snacks:mary` - Mary LT (line 130)
- `snacks:alisa` - Alisa LT (line 131)
- `snacks:club` - Club LT (line 132)
- `snacks:liam` - Liam LT (line 136)
- `snacks:pat` - Pat LT (line 137)
- `snacks:carlos` - Carlos LT (line 138)
- `snacks:sarah` - Sarah LT (line 139)
- `snacks:dusk` - Dusk (line 140)
- `snacks:santa` - Santa (line 141)
- `snacks:farmer` - Farmer (line 144)

**Events:**
- Standard mob events (inherited from mobs framework)
- No custom on_rightclick or special behaviors
- Uses spawn eggs for spawning

**Textures:**
- All use character.b3d mesh
- Custom texture files for each NPC (e.g., `character_Mary_LT_mt.png`)
- Preview generation function for inventory icons (lines 17-70)

**Features:**
- Combat-capable (attack_type = "dogfight", damage = 3)
- Drops apples on death
- Footstep sounds
- Standard character animations
- Spawn eggs registered via `mobs:register_egg()`
- **Advanced preview generation system** using `get_preview()` function

**Preview Generation System:**
**Function:** `get_preview(texture_file)` (lines 17-70)
**Purpose:** Creates 2D inventory icons from 3D character textures

**Process:**
1. **Body Part Extraction:** Uses `[combine:16x32:X,Y=texture` to extract specific areas
2. **Mask Application:** Applies `skindb_mask_*.png` files for body parts
3. **Format Handling:** Supports both 1.5 (32x64) and 1.8 (64x64) skin formats
4. **Mirroring:** Uses `^[transformFX` for left arm/leg creation
5. **Overlay System:** Adds extra layers for 64x skins
6. **Final Assembly:** Resizes to 64x128 and applies transform mask

**Body Parts Assembled:**
- Chest (mask: skindb_mask_chest.png, position: -16,-12)
- Head (mask: skindb_mask_head.png, position: -4,-8)
- Hat (mask: skindb_mask_head.png, position: -36,-8)
- Right Arm (mask: skindb_mask_rarm.png, position: -44,-12)
- Right Leg (mask: skindb_mask_rleg.png, position: 0,0)
- Left Arm/Leg (mirrored versions with transformFX)

**Usage in Registration:**
```lua
mobs:register_egg(mob_id, mob_desc, preview, 0)
```
Where `preview` is generated by `get_preview(texture_file)`

## Shop Item Definitions

### Ltee Angel Shop
**Location:** `mods/lottmobs/trader_goods.lua` lines 244-260
**Items:** Handbook, snacks, weapons, armor, plants

### Ltee1 Shop  
**Location:** `mods/lottmobs/trader_goods.lua` lines 266-283
**Items:** Computer items, mithril armor, weapons, home appliances

### Ltee2 Shop
**Location:** `mods/lottmobs/trader_goods.lua` lines 294-317
**Items:** Various snacks and desserts

### Ltee3 Shop
**Location:** `mods/lottmobs/trader_goods.lua` lines 328-345
**Items:** Home decor items, lighting, appliances

### Ltee Santa Shop
**Location:** `mods/lottmobs/trader_goods.lua` lines 353-370
**Items:** Christmas decorations, food, presents

## Key Functions

### Trader System
**Function:** `lottmobs_trader(self, clicker, entity, race, image, priv)`
**Location:** `mods/lottmobs/trader.lua` lines 191-315
**Purpose:** Handles trading interface and inventory management


### Combat System
**Location:** `mods/lottmobs/ltees.lua` lines 858-907
**Function:** Angel NPC attacks hostile mobs in radius

## HUD System
**Ltee Guard NPCs** (`lottmobs:ltee1`, `lottmobs:ltee2`, `lottmobs:ltee3`)
- **Location:** `mods/lottmobs/ltees.lua` lines 57-176
- **Function:** `handle_player_hud()` - Shows cycling quotes to nearby players
- **Features:** Per-player HUD with colored text (yellow/blue/white), 10-block range
- **Clear function:** `clear_ltee_hud()` lines 3-26

**Angel Follower NPC** (`lottmobs:ltee`)
- **Location:** `mods/lottmobs/ltees.lua` lines 130-176
- **Function:** `handle_single_player_hud()` - Shows quotes to owner only
- **Features:** Single-player HUD with white text, 3-block range
- **Clear function:** `clear_ltee_hud()` lines 3-26

## Player Events
- `minetest.register_on_joinplayer` - Auto-spawns angel for Ltee race players (lines 962-977)
- `minetest.register_on_leaveplayer` - Removes NPC on player disconnect (lines 979-992)
- `minetest.register_on_punchplayer` - Teleports angel to player when attacked (lines 995-1029)

## Chat Commands
- `/list_npcs` - Lists nearby NPCs (lines 1031-1056)
- `/spawn_npc` - Spawns test angel NPC (lines 1059-1079)
- `/spawn_ltee_riddler` - Spawns riddler NPC (lines 126-139)
- `/recipe` - Check crafting recipes (lines 1082-1107)

## Summary
The game contains a comprehensive NPC system with:
- 1 follower angel NPC per Ltee race player
- 3 guard NPC variants with cycling quotes
- 1 riddler NPC with interactive formspec interface
- 4 trader NPCs with specialized shops
- 10 basic snacks NPCs (Ltee characters) with combat abilities
- Additional elf traders and Christmas NPCs
- Full trading, combat, HUD, and formspec systems
