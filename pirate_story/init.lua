journal.register_page("pirate_story:log","ship guide","captain's log")

journal.triggers.register_on_join({
	is_active = function (playerName)
		return not journal.playerdata_getKey(playerName,"pirate_story:start")
	end,
	call = function(data)
		journal.add_entry(data.playerName,"pirate_story:log","I stranded somewhere... "..
			"If only I could remember how I came here.",true)
		journal.playerdata_setKey(data.playerName,"pirate_story:start",true)
	end,
})

journal.triggers.register_on_dig({
	target = "default:tree",
	is_active = function(playerName)
		return not journal.playerdata_getKey(playerName,"pirate_story:foundTree")
	end,
	call = function(data)
		journal.add_entry(data.playerName,"pirate_story:log","Today I found a log. "..
			"It's nothing but a little piece for the ship that I will build.",true)
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
		journal.add_entry(data.playerName,"pirate_story:log","So I have crafted ".. count .." planks, "..
			"but I will need a lot more to build my ship.",true)
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
			"On second thoughts, I would have expected my ship to be bigger.\n"..
			"Maybe out there on the open sea are some bigger ships...",true)
		minetest.after(15,journal.add_entry,data.playerName,"pirate_story:log",
			"---THE END---\nI hope you liked the epic story :P",false)
		journal.playerdata_setKey(data.playerName,"pirate_story:craftedBoat",true)
	end,
})