# Chat Commands in Lord of the Test Project

## Complete Command List

| Mod Name | Lua File | Command | Description |
|---|---|---|---|
| **better_bookmarks** | init.lua | `/bmset` | Set a bookmark to your current position. Bookmark names may not contain "." |
| **better_bookmarks** | init.lua | `/bm` | Go to bookmark. "-" is where you were when you last successfully ran /bm |
| **better_bookmarks** | init.lua | `/bmdel` | Delete a bookmark |
| **better_bookmarks** | init.lua | `/bmls` | List all your bookmarks |
| **default** | chatcommands.lua | `/privs` | Print out privileges of player |
| **default** | chatcommands.lua | `/grant` | Give privilege to player |
| **default** | chatcommands.lua | `/grantme` | Give privilege to yourself |
| **default** | chatcommands.lua | `/revoke` | Remove privilege from player |
| **lottachievements** | chat_commands.lua | `/achievements` | Show, clear, disable or enable your achievements |
| **lottachievements** | chat_commands.lua | `/achievement-info` | Show details of an achievement |
| **lottachievements** | chat_commands.lua | `/achievement-stats` | Get the achievements statistics for the given player or yourself |
| **lottmobs** | ltees.lua | `/list_npcs` | List all NPCs near you |
| **lottmobs** | ltees.lua | `/spawn_npc` | Spawns test NPC |
| **lottmobs** | ltees.lua | `/recipe` | Check crafting recipe for an item |
| **lottmobs** | riddler.lua | `/spawn_ltee_riddler` | Spawns an LT riddler NPC |
| **lottmobs** | special_mobs.lua | `/spawn_mob` | Spawn a mob by full entity name, e.g. lottmobs:ltee_trader_1 |
| **lottmobs** | rescueable_ltee.lua | `/spawn_rescueable_ltee` | Spawns a rescueable LTee NPC for testing |
| **lottmobs** | birthdayer.lua | `/spawn_birthdayer1` | Spawns a birthdayer1 NPC |
| **stamina** | init.lua | `/stamina` | Set player stamina to specified value (0-20) |
| **stamina** | init.lua | `/stam` | Set player stamina to specified value (0-20) |
| **worldedit_commands** | safe.lua | `/y` | Confirm a pending operation |
| **worldedit_commands** | safe.lua | `/n` | Abort a pending operation |
| **lottclasses** | allies.lua | `/allies` | Change Allies |
| **lottclasses** | init.lua | `/race` | Find/change a player's race |
| **lottmapgen** | init.lua | `/list_lttypes` | List all LT building types |
| **lottmapgen** | schematics.lua | `/load_schem` | Load a schematic from schems folder at your position |
| **lottother** | credits.lua | `/credits` | Credits of LOTT |
| **lottpotion** | init.lua | `/effect` | Get effect info |

## WorldEdit Commands

Located in `worldedit_pack/worldedit_commands/` - Multiple world editing commands

### Region Operations
- `/reset` - Reset the region so that it is empty
- `/inspect` - Enable or disable node inspection
- `/mark` - Show markers at the region positions
- `/unmark` - Hide markers if currently shown
- `/pos1` - Set WorldEdit region position 1 to the player's location
- `/pos2` - Set WorldEdit region position 2 to the player's location
- `/p` - Set WorldEdit region, position 1, or position 2 by punching nodes, or display the current WorldEdit region
- `/fixedpos` - Set a WorldEdit region position to the position at (<x>, <y>, <z>)
- `/volume` - Display the volume of the current WorldEdit region

### Transformations
- `/copy` - Copy the current WorldEdit region along the given axis by <amount> nodes
- `/move` - Move the current WorldEdit region along the given axis by <amount> nodes
- `/stack` - Stack the current WorldEdit region along the given axis <count> times
- `/stack2` - Stack the current WorldEdit region <count> times by offset <x>, <y>, <z>
- `/stretch` - Scale the current WorldEdit positions and region by a factor of <stretchx>, <stretchy>, <stretchz>
- `/transpose` - Transpose the current WorldEdit region along the given axes
- `/flip` - Flip the current WorldEdit region along the given axis
- `/rotate` - Rotate the current WorldEdit region around the given axis by angle <angle> (90 degree increment)
- `/orient` - Rotate oriented nodes in the current WorldEdit region around the Y axis by angle <angle>

### Shapes
- `/hollowcube` - Add a hollow cube with dimensions <width> x <height> x <length>, composed of <node>
- `/cube` - Add a cube with dimensions <width> x <height> x <length>, composed of <node>
- `/hollowsphere` - Add hollow sphere centered at WorldEdit position 1 with radius <radius>, composed of <node>
- `/sphere` - Add sphere centered at WorldEdit position 1 with radius <radius>, composed of <node>
- `/hollowdome` - Add hollow dome centered at WorldEdit position 1 with radius <radius>, composed of <node>
- `/dome` - Add dome centered at WorldEdit position 1 with radius <radius>, composed of <node>
- `/hollowcylinder` - Add hollow cylinder at WorldEdit position 1 along the given axis with length <length>, base radius <radius1> (and top radius [radius2]), composed of <node>
- `/cylinder` - Add cylinder at WorldEdit position 1 along the given axis with length <length>, base radius <radius1> (and top radius [radius2]), composed of <node>
- `/hollowpyramid` - Add hollow pyramid centered at WorldEdit position 1 with height <height>, composed of <node>
- `/pyramid` - Add pyramid centered at WorldEdit position 1 with height <height>, composed of <node>
- `/spiral` - Add spiral at WorldEdit position 1 with side length <length>, height <height>, space between walls <space>, composed of <node>

### Schematics
- `/save` - Save the current WorldEdit region to "(world folder)/schems/<file>.we"
- `/allocate` - Set the region defined by nodes from "(world folder)/schems/<file>.we" as the current WorldEdit region
- `/load` - Load nodes from "(world folder)/schems/<file>[.we[m]]" with position 1 of the current WorldEdit region as the origin
- `/mtschemcreate` - Save the current WorldEdit region using the Minetest Schematic format to "(world folder)/schems/<filename>.mts"
- `/mtschemplace` - Load nodes from "(world folder)/schems/<file>.mts" with position 1 of the current WorldEdit region as the origin
- `/mtschemprob` - Begins node probability entry for Minetest schematics, gets the nodes that have probabilities set, or ends node probability entry

### Other
- `/about` - Get information about the WorldEdit mod
- `/help` - Get help for WorldEdit commands
- `/lua` - Execute Lua code
- `/luatransform` - Execute Lua transformation code
- `/clearobjects` - Remove all objects in the current WorldEdit region
- `/hide` - Hide all nodes in the current WorldEdit region
- `/suppress` - Suppress all nodes in the current WorldEdit region
- `/highlight` - Highlight all nodes in the current WorldEdit region
- `/restore` - Restore all nodes hidden in the current WorldEdit region

## WorldEdit Short Commands

Located in `worldedit_pack/worldedit_shortcommands/init.lua` - Short aliases for WorldEdit commands

| Alias | Full Command |
|---|---|
| `/i` | `/inspect` |
| `/rst` | `/reset` |
| `/mk` | `/mark` |
| `/umk` | `/unmark` |
| `/1` | `/pos1` |
| `/2` | `/pos2` |
| `/fp` | `/fixedpos` |
| `/v` | `/volume` |
| `/s` | `/set` |
| `/r` | `/replace` |
| `/ri` | `/replaceinverse` |
| `/hcube` | `/hollowcube` |
| `/hspr` | `/hollowsphere` |
| `/spr` | `/sphere` |
| `/hdo` | `/hollowdome` |
| `/do` | `/dome` |
| `/hcyl` | `/hollowcylinder` |
| `/cyl` | `/cylinder` |
| `/hpyr` | `/hollowpyramid` |
| `/pyr` | `/pyramid` |
| `/spl` | `/spiral` |
| `/m` | `/move` |
| `/c` | `/copy` |
| `/stk` | `/stack` |
| `/sch` | `/stretch` |
| `/tps` | `/transpose` |
| `/fl` | `/flip` |
| `/rot` | `/rotate` |
| `/ort` | `/orient` |
| `/hi` | `/hide` |
| `/sup` | `/suppress` |
| `/hlt` | `/highlight` |
| `/rsr` | `/restore` |
| `/l` | `/lua` |
| `/lt` | `/luatransform` |
| `/clro` | `/clearobjects` |

## Summary

- **32 basic chat commands** across **17 mods**
- **4 bookmark commands** (better_bookmarks)
- **4 privilege commands** (default)
- **3 achievement commands** (lottachievements)
- **6 NPC/recipe commands** (lottmobs)
- **2 stamina commands** (stamina)
- **2 confirmation commands** (worldedit_commands/safe.lua)
- **1 command each** in: lottclasses, lottmapgen, lottother, lottpotion
- **30+ WorldEdit commands** for world editing
- **33 WorldEdit short aliases** for quick access

## Command Categories

### Player Management
- `/privs`, `/grant`, `/grantme`, `/revoke`, `/race`, `/allies`

### Navigation
- `/bmset`, `/bm`, `/bmdel`, `/bmls`

### Game Info
- `/achievements`, `/achievement-info`, `/achievement-stats`, `/credits`, `/list_lttypes`, `/effect`

### NPC Management
- `/list_npcs`, `/spawn_npc`, `/spawn_ltee_riddler`, `/spawn_mob`, `/spawn_rescueable_ltee`, `/spawn_birthdayer1`

### World Building
- `/load_schem`, WorldEdit commands (30+)

### Game Mechanics
- `/stamina`, `/stam`, `/recipe`

### WorldEdit Operations
- Region operations, transformations, shapes, schematics, and more

## Usage Notes

- All commands are prefixed with `/` when used in chat
- Some commands require specific privileges (e.g., worldedit, server)
- WorldEdit commands require the `worldedit` privilege
- Use `/help` in-game to get help for available commands
- Use `/help all` to see all available commands with descriptions