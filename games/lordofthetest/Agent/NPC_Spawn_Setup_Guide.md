# NPC Spawn Setup Guide

## Overview
This guide provides a structured prompt template for instructing agents to set up spawning for new NPCs in the Lord of the Test game. It covers the three main spawning methods used in the codebase.

## Prompt Template

### Basic NPC Information
```
I need to create a new NPC called [NPC_NAME] with the following specifications:

**Basic Properties:**
- Entity name: lottmobs:[npc_identifier]
- Race: [GAMErace_name] (e.g., GAMEhobbit, GAMEelf, GAMEman, GAMEdwarf, GAMEltee)
- Health: [min_hp] to [max_hp]
- Size: collisionbox = {[x1, y1, z1, x2, y2, z2]}
- Visual: mesh = "[mesh_file.b3d]"
- Texture: "[texture_file.png]"
- Movement: walk_velocity = [speed], run_velocity = [speed]

**Behavior:**
- View range: [blocks]
- Peaceful: [true/false]
- Attack type: [dogfight/shoot/none]
- Special abilities: [describe any unique behaviors]

**Interaction:**
- Right-click behavior: [describe what happens when clicked]
- Custom functions: [describe any special functions like HUD, trading, etc.]

**Spawn Requirements:**
- Spawn method: [choose one or more below]
  1. Natural world spawning
  2. Spawner node placement
  3. Chat command spawning
  4. Schematic integration
- Spawn biomes: [list biome node types]
- Spawn frequency: [rare/common/dense]
- Max spawn height: [y_level]
- Min spawn height: [y_level]
```

### Implementation Instructions

#### Step 1: Create the NPC Entity
```lua
-- File: mods/lottmobs/[npc_name].lua
local lf = assert(_G.lf, "global lf not initialized")

mobs:register_mob("lottmobs:[npc_identifier]", {
    type = "npc",
    race = "[GAMErace_name]",
    hp_min = [min_hp],
    hp_max = [max_hp],
    collisionbox = {[x1, y1, z1, x2, y2, z2]},
    visual = "mesh",
    mesh = "[mesh_file.b3d]",
    textures = {"[texture_file.png]"},
    view_range = [view_range],
    walk_velocity = [walk_speed],
    run_velocity = [run_speed],
    damage = [damage_amount],
    armor = [armor_value],
    light_resistant = true,
    drawtype = "front",
    water_damage = [water_damage],
    lava_damage = [lava_damage],
    light_damage = [light_damage],
    attack_type = "[attack_type]",
    peaceful = [true/false],
    group_attack = [true/false],
    step = 1,
    animation = {
        speed_normal = 15,
        speed_run = 20,
        stand_start = 0,
        stand_end = 79,
        walk_start = 168,
        walk_end = 187,
        run_start = 168,
        run_end = 187,
        punch_start = 189,
        punch_end = 198,
    },
    sounds = {
        war_cry = "mobs_die_yell",
        death = "default_death",
        attack = "mobs_slash_attack",
    },
    attacks_monsters = [true/false],
    
    on_rightclick = function(self, clicker)
        -- [Implement right-click behavior]
    end,
    
    on_activate = function(self)
        -- [Optional: activation behavior]
    end,
    
    do_custom = function(self, dtime)
        -- [Optional: custom behavior loop]
    end,
})
```

#### Step 2: Choose Spawn Method(s)

**Option A: Natural World Spawning**
```lua
-- Add to the NPC file
mobs:register_spawn("lottmobs:[npc_identifier]", 
    {"[biome_node1]", "[biome_node2]"}, 
    [active_block_count], 
    [min_light], 
    [max_spawn_interval], 
    [max_spawn_height], 
    [min_spawn_height])
```

**Option B: Spawner Node**
```lua
-- File: mods/lottother/mob_spawners.lua
minetest.register_node("lottother:[npc_identifier]_ms", {
    description = "[NPC Name] Spawner",
    drawtype = "nodebox",
    node_box = thin_plate,
    tiles = {"default_glass.png^[colorize:#[color]:120"},
    drop = '',
    paramtype = "light",
    sunlight_propagates = true,
    is_ground_content = false,
    walkable = false,
    buildable_to = true,
    pointable = true,
    on_construct = function(pos, node)
        if trader_exists_near(pos, 1.5, "lottmobs:[npc_identifier]") then
            return
        end
        lf("[npc_identifier]_ms", string.format("at x=%d y=%d z=%d", pos.x, pos.y, pos.z))
        minetest.add_entity({x = pos.x, y = pos.y+1, z = pos.z}, "lottmobs:[npc_identifier]")
    end,
    groups = {dig_immediate=3},
})

-- Add LBM for world load respawning
minetest.register_lbm({
    name = "lottother:spawn_[npc_identifier]",
    nodenames = {"lottother:[npc_identifier]_ms"},
    run_at_every_load = true,
    action = function(pos, node)
        if trader_exists_near({x = pos.x, y = pos.y + 1, z = pos.z}, 1.5, "lottmobs:[npc_identifier]") then
            return
        end
        lf("lottmobs:spawn_[npc_identifier]",
            ("LBM spawning [npc_identifier] at (%d, %d, %d)"):format(pos.x, pos.y, pos.z))
        local obj = minetest.add_entity(
            {x = pos.x, y = pos.y + 1, z = pos.z},
            "lottmobs:[npc_identifier]"
        )
        if obj then
            minetest.remove_node(pos)
        end
    end,
})
```

**Example: Birthdayer Spawner Implementation**
```lua
-- Birthdayer spawner (added to mods/lottother/mob_spawners.lua)
minetest.register_node("lottother:birthdayer_ms", {
    description = "Birthdayer Spawner",
    drawtype = "nodebox",
    node_box = thin_plate,    
    tiles = {"default_glass.png^[colorize:#FFD700:120"}, -- Gold color for birthday theme
    drop = '',
    paramtype = "light",
    sunlight_propagates = true,
    is_ground_content = false,
    walkable = false,
    buildable_to = true,
    pointable = true,
    on_construct = function(pos, node)
        if trader_exists_near(pos, 1.5, "lottmobs:birthdayer1") then
            return
        end
        lf("birthdayer_ms", string.format("at x=%d y=%d z=%d", pos.x, pos.y, pos.z))
        minetest.add_entity({x = pos.x, y = pos.y+1, z = pos.z}, "lottmobs:birthdayer1")
    end,
    groups = {dig_immediate=3},
})
```

**Option C: Chat Command**
```lua
-- Add to the NPC file
minetest.register_chatcommand("spawn_[npc_identifier]", {
    description = "Spawns a [NPC Name] NPC",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        local pos = vector.add(player:get_pos(), {x = 2, y = 0, z = 0})
        local obj = minetest.add_entity(pos, "lottmobs:[npc_identifier]")
        if obj then
            return true, "[NPC Name] spawned."
        else
            return false, "Failed to spawn [NPC Name]."
        end
    end,
})
```

#### Step 3: Integration Checklist

**Required Files:**
- [ ] `mods/lottmobs/[npc_name].lua` - NPC definition
- [ ] **CRITICAL: Update `mods/lottmobs/init.lua` to include the new file with `dofile(minetest.get_modpath("lottmobs").."/[npc_name].lua")`**
- [ ] Add spawner to `mods/lottother/mob_spawners.lua` (if using spawner nodes)
- [ ] Add texture files to `mods/lottmobs/textures/`
- [ ] Add model files to `mods/lottmobs/models/` (if custom)

**Dependencies:**
- [ ] Ensure `mobs` mod is loaded
- [ ] Ensure `lottother` mod is loaded (for spawners)
- [ ] Add to `mods.conf` if needed

**Testing:**
- [ ] Test chat command spawning
- [ ] Test spawner node placement
- [ ] Test natural spawning (if enabled)
- [ ] Test right-click interactions
- [ ] Test custom behaviors

## Example Prompts

### Example 1: Simple Shop NPC
```
I need to create a new shopkeeper NPC called "Baker" with the following specifications:

**Basic Properties:**
- Entity name: lottmobs:baker
- Race: GAMEhobbit
- Health: 15 to 25
- Size: collisionbox = {-0.3,-0.75,-0.3, 0.3,0.7,0.3}
- Visual: mesh = "character.b3d"
- Texture: "character_baker.png"
- Movement: walk_velocity = 0, run_velocity = 0 (stationary)

**Behavior:**
- View range: 8 blocks
- Peaceful: true
- Attack type: none
- Special abilities: Trading interface

**Interaction:**
- Right-click behavior: Opens trading GUI with bread, cakes, and pastries
- Custom functions: Trading inventory management

**Spawn Requirements:**
- Spawn method: Spawner node placement only
- Spawn biomes: hobbit villages and towns
- Spawn frequency: Common in bakery areas
```

### Example 2: Wild Creature NPC
```
I need to create a new forest creature called "Forest Sprite" with the following specifications:

**Basic Properties:**
- Entity name: lottmobs:forest_sprite
- Race: GAMEelf
- Health: 8 to 12
- Size: collisionbox = {-0.2,-0.5,-0.2, 0.2,0.3,0.2}
- Visual: mesh = "character.b3d"
- Texture: "character_sprite.png"
- Movement: walk_velocity = 2, run_velocity = 4

**Behavior:**
- View range: 12 blocks
- Peaceful: true
- Attack type: none
- Special abilities: Flees from players, emits particle effects

**Interaction:**
- Right-click behavior: Shows magical message and gives small gift
- Custom functions: Particle trail, teleportation escape

**Spawn Requirements:**
- Spawn method: Natural world spawning + chat command
- Spawn biomes: lottmapgen:lorien_grass, default:leaves
- Spawn frequency: Rare
- Max spawn height: 31000
- Min spawn height: 0
```

## Best Practices

1. **Use existing patterns** - Follow the structure of similar NPCs in the codebase
2. **Test incrementally** - Start with basic spawning, then add complex behaviors
3. **Use logging** - Include `lf()` calls for debugging spawn issues
4. **Consider performance** - Limit custom behaviors in `do_custom` to avoid lag
5. **Document thoroughly** - Add comments explaining special behaviors
6. **Use appropriate spawn methods** - Static NPCs use spawners, wildlife uses natural spawning

## Common Issues and Solutions

**Problem:** NPC doesn't spawn naturally
**Solution:** Check biome nodes, light levels, and spawn height parameters

**Problem:** Spawner node doesn't work
**Solution:** Verify `trader_exists_near()` function and LBM registration

**Problem:** Custom behaviors cause lag
**Solution:** Add timers and distance checks in `do_custom` function

**Problem:** Texture/model not loading
**Solution:** Verify file paths and ensure files exist in correct directories

**Problem:** Chat commands not available / NPC not spawning
**Solution:** **CRITICAL: Ensure the NPC file is loaded in `mods/lottmobs/init.lua` using `dofile(minetest.get_modpath("lottmobs").."/[npc_name].lua")`**
