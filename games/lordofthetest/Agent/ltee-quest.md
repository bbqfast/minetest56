
refer to 
Agent\feat-quest-system.md


1a)  
create another quest giver name "Elias the Chief"

1b)
- same quest as quest giver for now
- use same texture
- only via chat command for now


use this dialogue:

- greetings heros, we've been waiting for you for long time, we're counting on you to restore our prosperity in our villege

1c) add spawn button to the /test UI


2a)
refer to :
mods\lottmobs\item_ltee.lua

create a new entity similar to itee_ltee called depressed villager


depressed villager demands a random flower 


Entity name and registration - lottmobs:depressed_villager
flower list - refer to Agent\desc-flowers.md
flower request - should be randomly chosen at spawn
UI - Should  reuse the item_ltee 
Texure - reuse item_ltee 

depressed villager has a depressed flag
when the flag is set, the villager does not fight other entities
when the flag is off, the villager fights other enemies

default state is depressed, when flower is given ,it unset the depressed state

add spawn button to /test UI also

when depressed state is off, rename it to brave citizen

2b)
create a new delete entity tool  where when it point to an entity, it deletes that entity, 
for texture, use tar knife



3a)

3b)

hook up elias the chief with depressed LT quest, 

story is:
- After a dark fog appears in our villege 2 weeks ago, our villagers are depressed and don’t have energy to fight enemies!  
Please give them flowers to cheer them up so they can fend off hostile enemies!

new quest is :
- cheer up 5 villagers (distinct villagers)

quest progress is tracked per player

reward is 5 gold (default:gold_ingot x5)
Drop on the ground if the player’s inventory is full

should reuse as much existing quest giver UI if possible




do not modify above this line
--------------------------------------

