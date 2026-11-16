# Mapgen Feature Investigation

## Files Involved

**Core mapgen files:**
- `mods/lottmapgen/init.lua` - Main map generation logic with biome system
- `mods/lottmapgen/functions.lua` - Tree/plant generation functions and biome selection algorithm
- `mods/lottmapgen/nodes.lua` - Custom node definitions (grasses, water types, stones)
- `mods/lottmapgen/schematics.lua` - Building placement queue system using WorldEdit schematics
- `mods/lottmapgen/deco.lua` - Dungeon modifications and abandoned structure decorations
- `mods/lottmapgen/chests.lua` - Chest spawner nodes with faction-specific loot tables
- `mods/lottmapgen/worldedit.lua` - Isolated WorldEdit functions for schematic deserialization
- `mods/lottmapgen/mod.conf` - Mod dependencies and configuration

**Schematic files:**
- `mods/lottmapgen/schems/` - Contains `.we` WorldEdit schematic files for buildings (forts, houses, shops)

## Algorithm Uses

### Biome Generation System
- Uses 3D Perlin noise maps for temperature, humidity, and randomness
- Biome selection via `lottmapgen_biomes()` function using threshold comparisons:
  - Temperature thresholds: `HITET = 0.4`, `LOTET = -0.4`, `ICETET = -0.8`
  - Humidity thresholds: `HIHUT = 0.4`, `LOHUT = -0.4`
  - Randomness thresholds: `HIRAN = 0.4`, `LORAN = -0.4`
- 14 biomes: Angmar, Snowplains, Trollshaws, Dunland, Gondor, Ithilien, Lorien, Mordor, Fangorn, Mirkwood, Iron Hills, Rohan, Shire, LT (custom)

### Terrain Generation
- Uses VoxelManip API for efficient chunk-based generation
- Processes 80×80×80 node chunks
- Column-based scanning from top to bottom for surface detection
- Biome blending option via `biome_blend` setting for smoother transitions

### Structure Placement
- Queue-based building system to handle async chunk generation
- Buildings enqueued during mapgen, placed via `register_globalstep`
- Checks if all required chunks are generated before placement
- Optional area protection via `areas` mod integration

### Vegetation System
- Rarity-based tree/plant spawning (constants `TREE1` through `TREE10`, `PLANT1` through `PLANT16`)
- Biome-specific vegetation (mallorn trees in Lorien, burned trees in Mordor, etc.)
- Custom tree generation functions for each tree type

## Configuration

### Minetest Settings
- `biome_blend` (bool) - Enable smoother biome transitions
- `protect_structures` (bool) - Auto-protect generated buildings with areas mod
- `water_level` - From mapgen settings, affects sand lines and ice formation

### Code-level Configuration (in `init.lua`)
- **Temperature/Humidity thresholds** (lines 19-25): Adjust biome distribution
- **Rarity constants** (lines 30-60): Control tree/plant spawn rates
- **Noise parameters** (lines 64-91): Modify biome noise characteristics (spread, seed, octaves, persistence)

### Building Configuration (in `schematics.lua`)
- Building list with schematic filenames, area owners, and center points
- Bounding boxes auto-calculated from schematic files
- Add new buildings by extending `lottmapgen_list` table

### Chest Loot Configuration (in `chests.lua`)
- Faction-specific chest spawners with unique loot tables
- Modify `items_available` arrays to adjust loot contents
- ABM interval/chance controls spawn timing

### Chat Commands
- `/list_lttypes` - Lists all available building types
- `/load_schem <name>` - Manually place a schematic at player position
