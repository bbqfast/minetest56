# LTee Race Preservation from Definition to Spawn

## Definition Phase
1. **Static Race Assignment**: In `ltees.lua`, line 180, the `register_ltee` function hardcodes `race = "GAMEelf"` for all LTee mob definitions
2. **Entity Registration**: The race is stored in the mob definition when calling `mobs:register_mob("lottmobs:ltee" .. n, {...})`

## Spawn Phase
1. **Spawn Registration**: Line 291 calls `mobs:register_spawn("lottmobs:ltee" .. n, {"lottmapgen:ltee_grass"}, 20, 0, 18000, 3, 31000)`
2. **Race Preservation**: The mobs API preserves the race field from the original mob definition when spawning entities

## Runtime Phase (Critical Finding)
1. **Race Override Issue**: In the angel entity `on_activate` function (line 614), there's a hardcoded override: `self.race = "GAMEltee"`
2. **Inconsistent Race Assignment**: 
   - Static LTee mobs: `race = "GAMEelf"` (from definition)
   - Angel LTee followers: `race = "GAMEltee"` (from on_activate override)
   - Rescueable LTees: `race = "GAMEltee"` (from definition in rescueable_ltee.lua line 50)

## Race Usage
The race field is used throughout the system for:
- Trader interactions (determining which goods are available)
- Combat behavior (ally/enemy detection in functions.lua)
- Player privilege checks (GAMEltee vs GAMEelf)

## Key Issue
There's a race inconsistency where regular LTee mobs are defined as "GAMEelf" but angel followers override to "GAMEltee". This could cause system behavior differences between different LTee types.

## Files Referenced
- `mods/lottmobs/ltees.lua` - Main LTee definitions and angel entity
- `mods/lottmobs/rescueable_ltee.lua` - Rescueable LTee definitions
- `mods/lottmobs/functions.lua` - Race-based combat logic
- `mods/lottmobs/trader.lua` - Race-based trading logic