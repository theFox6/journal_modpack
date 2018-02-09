journal.register_page("journal:test","ship guide","captain's log")

minetest.register_on_dignode(function(pos, oldnode, digger)
	if not digger or not pos or not oldnode then
		return
	end

	local name = digger:get_player_name()
	if oldnode.name == "default:tree" then
		if not journal.playerdata_getKey(name,"journal:foundLog") then
			journal.add_entry(name,"journal:test","Today I found a log. It's nothing but a little piece for the ship that I will build.",true)
			journal.playerdata_setKey(name,"journal:foundLog",true)
		end
	end
end)

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if not player or not itemstack then
		return
	end

	if itemstack:get_name() == "default:wood" then
		local name = player:get_player_name()
		if not journal.playerdata_getKey(name,"journal:craftedPlanks") then
			journal.add_entry(name,"journal:test","So I have some planks, but I will need a lot more to build my ship.",true)
			journal.playerdata_setKey(name,"journal:craftedPlanks",true)
		end
	elseif itemstack:get_name() == "boats:boat" then
		local name = player:get_player_name()
		if not journal.playerdata_getKey(name,"journal:craftedBoat") then
			journal.add_entry(name,"journal:test","Well I have my ship now ...",true)
			journal.playerdata_setKey(name,"journal:craftedBoat",true)
			minetest.after(10,journal.add_entry,name,"journal:test","On second thoughts, I would have expected my ship to be bigger.\nMaybe out there on the open sea are some bigger ships...",true)
			minetest.after(12,journal.add_entry,name,"journal:test","---THE END---\nI hope you liked the epic story :P",false)
		end
	end
end)