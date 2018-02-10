journal.register_page("journal:test","ship guide","captain's log")

journal.triggers.register_on_dig({
	target = "default:tree",
	is_active = function(playerName)
		return not journal.playerdata_getKey(playerName,"journal:foundTree")
	end,
	call = function(data)
		local tool = data.tool
		if tool == "" then
			tool = "my hand"
		end
		journal.add_entry(data.playerName,"journal:test","Today I chopped some wood using:"..tool..". It's nothing but a little piece for the ship that I will build.",true)
		journal.playerdata_setKey(data.playerName,"journal:foundTree",true)
	end,
})

journal.triggers.register_counter("journal:craftedPlanksCount","craft","default:wood",false)

journal.triggers.register_on_craft({
	target = "default:wood",
	is_active = function(player)
		return (not journal.playerdata_getKey(player,"journal:craftedPlanks")) and journal.playerdata_getKey(player,"journal:foundTree")
	end,
	call = function(data)
		local count = journal.triggers.get_count("journal:craftedPlanksCount",data.playerName)
		journal.add_entry(data.playerName,"journal:test","So I have crafted ".. count .." planks, but I will need a lot more to build my ship.",true)
		journal.playerdata_setKey(data.playerName,"journal:craftedPlanks",true)
	end,
})

journal.triggers.register_on_craft({
	target = "boats:boat",
	is_active = function(player)
		return (not journal.playerdata_getKey(player,"journal:craftedBoat"))  and journal.playerdata_getKey(player,"journal:craftedPlanks")
	end,
	call = function(data)
		journal.add_entry(data.playerName,"journal:test","Well I have my ship now ...",true)
		minetest.after(10,journal.add_entry,data.playerName,"journal:test","On second thoughts, I would have expected my ship to be bigger.\nMaybe out there on the open sea are some bigger ships...",true)
		minetest.after(15,journal.add_entry,data.playerName,"journal:test","---THE END---\nI hope you liked the epic story :P",false)
		journal.playerdata_setKey(data.playerName,"journal:craftedBoat",true)
	end,
})