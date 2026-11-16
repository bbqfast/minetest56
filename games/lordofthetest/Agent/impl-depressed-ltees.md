## Implementation Summary

The Depressed LTee ("Depressed Villager") is a `GAMEltee`-race NPC implemented entirely in [depressed_villager.lua:1](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:1) (loaded via [init.lua:41](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:41)). It spawns in a sad, immobile state and asks the player for one specific random flower. Giving it the correct flower through a payment-style formspec cures it: the nametag changes to "Brave Citizen", it becomes mobile, and it fights monsters and hostile NPCs on the player's side. Each cure also feeds progress into the "Cheer Up the Villagers" quest.

## Core Components

### 1. Entity Definition ([depressed_villager.lua:154](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:154))
- **Registered mob**: `lottmobs:depressed_villager` via `mobs:register_mob` at [depressed_villager.lua:298](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:298), with a matching spawn egg via `mobs:register_egg` at [depressed_villager.lua:300](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:300)
- **Base stats**: `race = "GAMEltee"` ([depressed_villager.lua:156](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:156)), hp 20-25, `character.b3d` mesh, armor 100, damage 5, `attack_type = "dogfight"`
- **Initial flags**: `peaceful`, `passive`, `attacks_monsters`, `attack_npcs`, `walk_velocity = 0`, `run_velocity = 0` ([depressed_villager.lua:179](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:179))
- **Nametag**: "Depressed Villager" with a pale blue `nametag_color` (r=150, g=150, b=255) ([depressed_villager.lua:163](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:163))
- **Drops**: `default:gold_ingot` (chance 10, 1-2) ([depressed_villager.lua:202](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:202))

### 2. State Initialization (`on_spawn` / `on_activate`)
- **`on_spawn`** ([depressed_villager.lua:212](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:212)): sets `self.depressed = true` and rolls `self.requested_flower` from the flower pool
- **`on_activate`** ([depressed_villager.lua:218](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:218)): re-applies both defaults if nil (survives mapblock unload/reload), generates a unique random `self.id` if missing, and registers `lottmobs.depressed_villagers[self.id] = self`
- **Registry table**: `lottmobs.depressed_villagers` ([depressed_villager.lua:36](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:36)) maps entity id -> entity `self`, so detached-inventory callbacks can resolve which mob a payment belongs to

### 3. Flower Request Pool
- **`flower_list`** ([depressed_villager.lua:7](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:7)): 15 entries drawn from [desc-flowers.md:1](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/Agent/desc-flowers.md:1) — 6 `flowers:*` items (rose, tulip, both dandelions, geranium, viola) and 9 `lottplants:*` items (anemones, eglantive, elanor, iris, lissuin, mallos, niphredil, seregon, brambles_of_mordor, pilinehtar)
- **Per-mob request**: each villager independently wants one random flower; `get_random_flower()` ([depressed_villager.lua:38](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:38)) picks uniformly

### 4. Interaction & Payment UI (`on_rightclick`)
- **Already cured**: replies with the `not_depressed` dialogue and returns early ([depressed_villager.lua:240](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:240))
- **Depressed**: sends the `greeting` dialogue, then opens a formspec backed by a **detached inventory** named after `self.id` ([depressed_villager.lua:232](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:232))
- **Detached inventory** (`lottmobs.create_depressed_villager_inventory`, [depressed_villager.lua:43](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:43)):
  - `requested` list (size 1): pre-filled with the wanted flower, take/move denied so the player can only view it
  - `payment` list (size 1): the only place `allow_put` permits items
  - `on_put` on `payment` triggers `lottmobs.check_depressed_villager_payment`

### 5. Payment Resolution ([check_depressed_villager_payment](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:72))
- **Empty payment**: no-op
- **Already cured** (requested slot empty): payment is cleared and returned ([depressed_villager.lua:83](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:83))
- **Wrong item**: removed from the slot and returned to the player's inventory, or dropped at their feet if it is full; `wrong_item` dialogue is sent ([depressed_villager.lua:94](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:94))
- **Correct item, insufficient count**: waits (no action)
- **Correct item**: consumes the requested count, refunds any excess to inventory or the ground, clears both slots ([depressed_villager.lua:117](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:117)), then:
  - `self.depressed = false` ([depressed_villager.lua:140](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:140))
  - nametag updated to "Brave Citizen"
  - `thank_you` dialogue (or excess-refund variant) sent
  - `lottmobs_quest_api.update_cheer_villager_progress(player_name, self.id)` called if the quest API is loaded ([depressed_villager.lua:146](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:146))

### 6. Behavior State Machine ([do_custom](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:267))
Runs every tick and enforces the two states:
- **Depressed**: `passive = true`, `walk_velocity = 0`, `run_velocity = 0`, nametag "Depressed Villager" — the mob stands still ([depressed_villager.lua:271](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:271))
- **Cured**: `passive = false`, `walk_velocity = 2`, `run_velocity = 3.5`, `race = "GAMEltee"`, `attack_npcs = true`, `attack_monsters = true`, `attack_players = false` — the mob actively fights enemies on the player's side ([depressed_villager.lua:277](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:277))

### 7. Quest Integration
- **Quest**: "Cheer Up the Villagers" defined at [quest_system.lua:54](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/quest_system.lua:54) — story premise is a dark fog that depressed the villagers; flowers restore their will to fight
- **Progress hook**: `quest_api.update_cheer_villager_progress(player_name, villager_id)` at [quest_system.lua:294](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/quest_system.lua:294), called from the payment success path
- **Tracking key**: progress is keyed by the villager's unique `self.id`, so each distinct cured villager counts once

## Combat Targets

Once cured, `do_custom` sets `attack_npcs = true`, `attack_monsters = true`, `attack_players = false` ([depressed_villager.lua:277](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:277)). Target selection runs through `npc_attack` ([functions.lua:108](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/functions.lua:108)) filtered by the `lottclasses.allies` table ([allies.lua:41](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottclasses/allies.lua:41)) and the generic scan in [api.lua:1899](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/mobs/api.lua:1899).

### Attacked
- **All `type = "monster"` mobs** (gated by `self.attacks_monsters`, [functions.lua:212](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/functions.lua:212)):
  - `lottmobs:spider` — [init.lua:152](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:152)
  - `lottmobs:nazgul` — [init.lua:1141](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:1141)
  - `lottmobs:witch_king` — [init.lua:1222](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:1222)
  - `lottmobs:balrog` — [init.lua:1303](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:1303)
  - `lottmobs:dead_men` — [init.lua:1420](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:1420)
- **`GAMEorc`-race NPCs** — the only non-ally race for `GAMEltee` ([allies.lua:44](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottclasses/allies.lua:44)):
  - `lottmobs:warg` — [warg.lua:33](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/warg.lua:33)
  - `lottmobs:dunlending` — [init.lua:550](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:550)
  - `lottmobs:orc` — [init.lua:664](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:664)
  - `lottmobs:raiding_orc` — [init.lua:767](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:767)
  - `lottmobs:uruk_hai` — [init.lua:870](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:870)
  - `lottmobs:battle_troll` — [init.lua:970](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:970)
  - `lottmobs:half_troll` — [init.lua:1049](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:1049)
  - `lottmobs:troll` — [init.lua:1468](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/init.lua:1468)

### Ignored
- **Same race**: other `GAMEltee` NPCs (ltees, rescueable ltees, other cured villagers)
- **Allied races**: `GAMEelf`, `GAMEman`, `GAMEhobbit`, `GAMEdwarf` NPCs
- **Ents**: `race = "ents"` NPCs explicitly excluded ([functions.lua:206](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/functions.lua:206))
- **Animals**: `attack_animals` unset, defaults `false` ([api.lua:1900](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/mobs/api.lua:1900))
- **Players**: `attack_players = false` strips players from the target list ([api.lua:1887](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/mobs/api.lua:1887))

### Caveats
- **Weak fighter**: damage 5, hp 20-25, `view_range` 10 — effective against orcs, outmatched against a balrog
- **Player race quirk**: the player branch in `npc_attack` ([functions.lua:181](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/functions.lua:181)) checks `player_same_race_or_ally` rather than `attack_players`, so a `GAMEorc`-race player could be flagged as a target if that path runs for this mob

## Spawning

- **`/spawn_depressed_villager` chatcommand** ([depressed_villager.lua:303](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:303)): spawns the entity 2 nodes east of the invoking player
- **Test UI**: "Spawn Depressed Villager" button at [quest_test.lua:229](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/quest_test.lua:229) invokes the same chatcommand
- **Spawn egg**: "Depressed Villager" egg registered with `default_gold_block.png` inventory image ([depressed_villager.lua:300](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:300))

## Technical Architecture

### Entity <-> Inventory Bridging
The formspec operates on a detached inventory, which has no direct reference to the entity. The bridge is two-fold:
1. The inventory is named with `self.id`
2. `lottmobs.depressed_villagers[self.id]` holds the entity `self`, looked up inside `check_depressed_villager_payment` via `inv:get_location().name` ([depressed_villager.lua:73](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:73))

### Persistence Strategy
`on_activate` ([depressed_villager.lua:218](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:218)) defensively re-initializes `depressed`, `requested_flower`, and `id` whenever they are nil, so the mob always has valid state after mapblock reload even if staticdata fields were lost. mobs_redo serializes `self.*` fields into staticdata automatically.

### Edge-Case Handling
- **Double-cure guard**: empty `requested` stack causes the payment to be cleared without side effects ([depressed_villager.lua:83](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:83))
- **Inventory full**: wrong items and excess refunds fall back to `minetest.add_item` at the player's position ([depressed_villager.lua:105](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:105))
- **Excess payment**: only `requested_count` is consumed; the remainder is returned ([depressed_villager.lua:119](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:119))
- **Death cleanup**: `on_die` removes the entry from `lottmobs.depressed_villagers` ([depressed_villager.lua:290](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:290))
- **Id uniqueness**: `self.id` is a random string (`rand * rand .. name .. rand^2`), generated in `on_activate` ([depressed_villager.lua:226](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:226)) and lazily again in `on_rightclick` if still missing

### Dialogue Table
All player-facing strings live in the `dialogues` table (`greeting`, `thank_you`, `not_depressed`, `wrong_item`) at [depressed_villager.lua:28](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:28), sent via `minetest.chat_send_player` with a `<Depressed Villager>` prefix.

### Logging
The module logs through the global `lf` helper (asserted at load time, [depressed_villager.lua:4](windsurf://file/c:/Minetest/v5.6/games/lordofthetest/mods/lottmobs/depressed_villager.lua:4)) under the `depressed_villager` tag for spawn, activation, cure, and death events.
