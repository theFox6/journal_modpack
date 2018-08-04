journal.register_page("pirate_story:log","ship guide","captain's log")

journal.triggers.register_on_join({
	is_active = function (playerName)
		return not journal.playerdata_getKey(playerName,"pirate_story:start")
	end,
	call = function(data)
		journal.add_entry(data.playerName,"pirate_story:log","Oi? I stranded somewhere... "..
			"Where is this? Darn if only I coulda remember where I came from.",true)
		journal.playerdata_setKey(data.playerName,"pirate_story:start",true)
	end,
})

journal.triggers.register_on_dig({
	target = "default:tree",
	is_active = function(playerName)
		return not journal.playerdata_getKey(playerName,"pirate_story:foundTree")
	end,
	call = function(data)
		journal.add_entry(data.playerName,"pirate_story:log","Today I got a log. "..
			"It's nothing but a little piece for the ship that I'll build.",true)
		journal.playerdata_setKey(data.playerName,"pirate_story:foundTree",true)
	end,
})

journal.triggers.register_counter("pirate_story:craftedPlanksCount","craft","default:wood",false)

journal.triggers.register_on_craft({
	target = "default:wood",
	is_active = function(player)
		return (not journal.playerdata_getKey(player,"pirate_story:craftedPlanks"))
			and journal.playerdata_getKey(player,"pirate_story:foundTree")
	end,
	call = function(data)
		local count = journal.triggers.get_count("pirate_story:craftedPlanksCount",data.playerName)
		journal.add_entry(data.playerName,"pirate_story:log","So I crafted ".. count .." planks, "..
			"but I'll need a lota more planks to build me ship.",true)
		journal.playerdata_setKey(data.playerName,"pirate_story:craftedPlanks",true)
	end,
})

journal.triggers.register_on_craft({
	target = "boats:boat",
	is_active = function(player)
		return (not journal.playerdata_getKey(player,"pirate_story:craftedBoat")) and
			journal.playerdata_getKey(player,"pirate_story:craftedPlanks")
	end,
	call = function(data)
		journal.add_entry(data.playerName,"pirate_story:log","Well I have my ship now ...",true)
		minetest.after(10,journal.add_entry,data.playerName,"pirate_story:log",
			"On second thoughts, I woulda expected me ship to be bigger.\n"..
			"Maybe out there on the open sea are some bigger ships...",true)
		journal.playerdata_setKey(data.playerName,"pirate_story:craftedBoat",true)
	end,
})

journal.triggers.register_on_craft({
	target = "default:chest",
	is_active = function(player)
		return (not journal.playerdata_getKey(player,"pirate_story:craftedChest")) and
			journal.playerdata_getKey(player,"pirate_story:craftedPlanks")
	end,
	call = function(data)
		journal.add_entry(data.playerName,"pirate_story:log","Arr, that's one fine chest...\n"..
			"I oughta fill that one with some sorta treasure.",true)
		journal.playerdata_setKey(data.playerName,"pirate_story:craftedChest",true)
	end,
})

journal.triggers.register_on_dig({
	target = {"default:stone_with_gold", "default:stone_with_diamond"}
	is_active = function(player)
		return (not journal.playerdata_getKey(player,"pirate_story:foundTreasure")) and
			journal.playerdata_getKey(player,"pirate_story:craftedChest")
	end,
	call = function(data)
		journal.add_entry(data.playerName,"pirate_story:log","Oooh.., that's some shiny treasure!",true)
		minetest.after(10,journal.add_entry,data.playerName,"pirate_story:log",
			"Now I got something to put in me chest."
		minetest.after(5,journal.add_entry,data.playerName,"pirate_story:log",
			"Ah wait,the treasure is already mine!\n"..
			"I won't give away this treasure just to hide it somewhere!",true)
		journal.playerdata_setKey(data.playerName,"pirate_story:foundTreasure",true)
	end,
})