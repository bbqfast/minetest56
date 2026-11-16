-- Quest Stories Database
-- Contains story text for each quest

local lf = assert(_G.lf, "global lf not initialized")

-- Story definitions for quests
local quest_stories = {
    rescue_carlos = {
        id = "rescue_carlos",
        title = "The Tale of Carlos",
        story = [[
In the peaceful lands of the LTee kingdom, there lived a brave soul named Carlos. 
Carlos was known throughout the land for his kindness and unwavering courage.

One fateful day, dark clouds gathered over the kingdom. A terrible storm swept through, 
separating Carlos and his kin from their home. Lost and afraid, they wandered the 
wilderness, unable to find their way back.

The Quest Giver has received word of Carlos's plight. Many Carlos LTees are scattered 
across the land, waiting for a hero to rescue them.

Will you be that hero? Rescue 2 Carlos LTees and bring them back to safety. 
Your reward shall be great diamonds, fit for a true champion.
]],
        accept_text = "I will rescue Carlos!",
        reject_text = "I am not ready yet."
    },
    rescue_mary = {
        id = "rescue_mary",
        title = "The Legend of Mary",
        story = [[
Mary was the heart of the LTee community. Her wisdom and compassion touched all who knew her.
When the great darkness descended upon the land, Mary led her people to safety, but in doing so,
she became separated from them.

Now, Mary and her kin wander the wilderness, lost and alone. They need a hero to guide them 
home to safety.

The Quest Giver has heard their cries for help. Many Mary LTees are in danger, scattered 
across the unforgiving terrain.

Will you answer the call? Rescue 3 Mary LTees and return them to safety. 
Your courage shall be rewarded with gold and precious crystals.
]],
        accept_text = "I will rescue Mary!",
        reject_text = "I am not ready yet."
    },
    cheer_up_villagers = {
        id = "cheer_up_villagers",
        title = "The Dark Fog",
        story = [[
Two weeks ago, a dark fog rolled over our village. Since that day, our villagers have lost their spirit and will to fight. They sit in silence, unable to raise a hand against the hostile enemies that now threaten our home.

But there is hope! A simple gift of a flower can lift their hearts and restore their courage. Heroes, please bring flowers to our people and cheer them up, so they may once again stand strong against our foes.

Will you help us? Cheer up 5 villagers with flowers and bring hope back to our village. Your kindness shall be rewarded with gold.
]],
        accept_text = "I will help the villagers!",
        reject_text = "I am not ready yet."
    }
}

-- Get story for a quest
local function get_quest_story(quest_id)
    return quest_stories[quest_id]
end

-- Register globally
lottmobs_quest_stories = {
    get_story = get_quest_story,
    stories = quest_stories
}

lf("quest_stories", "Quest stories module loaded")
