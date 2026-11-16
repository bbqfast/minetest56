# Rescueable LTee Implementation Documentation

## Overview

The rescueable LTee system now uses a **single generic entity** whose variant (Mary or Carlos) is determined at spawn time through `staticdata`. This avoids registering a separate mob per type and centralizes type data in one configuration table.

## Files Modified

- `mods/lottmobs/rescueable_ltee.lua`
- `mods/lottmobs/rescue_bag.lua`
- `mods/lottmobs/quest_test.lua`

## Type Configuration

`mods/lottmobs/rescueable_ltee.lua` defines `rescueable_ltee_types` and exposes it on `lottmobs.rescueable_ltee_types` so other modules can look up texture/nametag info at runtime:

```lua
local rescueable_ltee_types = {
    mary = {
        texture = "character_Mary_LT_mt.png",
        nametag = "Rescueable Mary LTee",
        spawn_command = "spawn_rescueable_mary_ltee"
    },
    carlos = {
        texture = "character_Carlos_LT_third_LT_stolen_mt.png",
        nametag = "Rescueable Carlos LTee",
        spawn_command = "spawn_rescueable_carlos_ltee"
    }
}
lottmobs.rescueable_ltee_types = rescueable_ltee_types
```

## Generic Rescueable Entity

Only one mob is registered: `lottmobs:rescueable_ltee`.

```lua
mobs:register_mob("lottmobs:rescueable_ltee", create_rescueable_ltee())
```

The `on_spawn` callback resolves `self.ltee_type` from `staticdata` (deserialized by the mobs API) and applies the correct texture and nametag:

```lua
on_spawn = function(self)
    if not self.ltee_type or not rescueable_ltee_types[self.ltee_type] then
        self.ltee_type = "mary"
    end
    local type_config = rescueable_ltee_types[self.ltee_type]

    self.textures = {type_config.texture}
    self.nametag = type_config.nametag
    self.object:set_properties({
        textures = self.textures,
        nametag = self.nametag
    })
end
```

**Important:** `textures` must be a flat table of strings (`{"texture.png"}`), not a table-of-tables. A double-nested assignment previously caused black skins.

## Spawning with staticdata

Both chat commands and `quest_test.lua` spawn the same base entity with `ltee_type` serialized as `staticdata`:

```lua
local staticdata = minetest.serialize({ltee_type = "carlos"})
minetest.add_entity(pos, "lottmobs:rescueable_ltee", staticdata)
```

## Rescued LTee Entity

`mods/lottmobs/rescue_bag.lua` registers the generic `lottmobs:rescued_ltee` mob. Its `on_spawn` reads `self.ltee_type` from `staticdata` and sets visuals:

```lua
on_spawn = function(self)
    self.rescued = true
    self.ltee_type = self.ltee_type or "mary"

    local type_config = lottmobs.rescueable_ltee_types
        and lottmobs.rescueable_ltee_types[self.ltee_type]

    if not type_config then
        type_config = {
            texture = "character_Mary_LT_mt.png",
            nametag = "Rescued Mary LTee"
        }
    end

    self.textures = {type_config.texture}
    self.nametag = "Rescued " .. self.ltee_type:gsub("^%l", string.upper) .. " LTee"
    self.object:set_properties({
        textures = self.textures,
        nametag = self.nametag
    })
end
```

Note: `mobs:register_mob` ignores `def.on_activate`; only `on_spawn` (and `after_activate`) are executed by the mobs API.

## Rescue Interaction

In `rescueable_ltee.lua`, `on_rightclick` gives the player a `lottmobs:rescued_ltee_set` egg with `ltee_type` metadata:

```lua
local rescued_egg = ItemStack("lottmobs:rescued_ltee_set")
rescued_egg:set_metadata(minetest.serialize({ltee_type = self.ltee_type}))
```

`mobs:register_egg("lottmobs:rescued_ltee", "Rescued LTee", get_preview(...), 0)` registers the base and `_set` egg items. The `_set` item's `on_place` passes `itemstack:get_metadata()` to `minetest.add_entity`, which `mob_activate` deserializes into `self.ltee_type`.

## Rescue Bag Item

`mods/lottmobs/rescue_bag.lua` registers `lottmobs:rescue_bag`:

- `stack_max = 1`
- Left-click shows instructions
- Right-click places like a normal craftitem
- Actual rescue logic lives in the rescueable LTee's `on_rightclick`

## Chat Commands

- `/spawn_rescueable_mary_ltee` - spawns `lottmobs:rescueable_ltee` with `ltee_type = "mary"`
- `/spawn_rescueable_carlos_ltee` - spawns `lottmobs:rescueable_ltee` with `ltee_type = "carlos"`
- `/spawn_rescueable_ltee` - legacy command, spawns Mary variant
- `/give_rescue_bag` - gives a rescue bag

## Quest Integration

`quest_test.lua` scenarios spawn rescueable LTees by passing `ltee_type` staticdata to `lottmobs:rescueable_ltee`.

## Known Limitations

- The `lottmobs:rescued_ltee_set` egg uses the generic `(Tamed)` suffix from `mobs:register_egg` and is not stackable (`stack_max = 1`). Per-type names and stacking require custom `minetest.register_craftitem` entries instead of `mobs:register_egg`.
- The rescued egg inventory image is the same for both Mary and Carlos because `mobs:register_egg` only supports one preview per mob.
- Natural spawning and crafting recipes are not yet implemented.

## Next Steps

- Optional: Replace the generic `mobs:register_egg` rescued egg with custom craftitems (`lottmobs:rescued_mary_ltee`, `lottmobs:rescued_carlos_ltee`) for distinct names, previews, and stacking.
- Add natural spawning rules for rescueable LTees.
- Add a crafting recipe for the rescue bag.
