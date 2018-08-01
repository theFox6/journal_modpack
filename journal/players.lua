journal.players = (function()
	local file_name = minetest.get_worldpath() .. "/journal_players"

	minetest.register_on_shutdown(function()
		local file = io.open(file_name, "w")
		file:write(minetest.serialize(journal.players))
		file:close()
	end)

	local file = io.open(file_name, "r")
	if file ~= nil then
		local data = file:read("*a")
		file:close()
		return minetest.deserialize(data)
	end
	return {}
end) ()

function journal.playerdata_getKey(playerName,key)
	return journal.players[playerName].data[key]
end

function journal.playerdata_setKey(playerName,key,value)
	journal.players[playerName].data[journal.check_modname_prefix(key)] = value
end

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()

	if journal.players[playerName] == nil then
		journal.players[playerName] = {}
	end
	if journal.players[playerName].data == nil then
		journal.players[playerName].data = {}
	end
	if journal.players[playerName].unread == nil then
		journal.players[playerName].unread = {}
	end
	journal.players[playerName].joined=true
	journal.players[playerName].message=false
	journal.players[playerName].reading=false
end)

minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	journal.players[playerName].joined=false
end)

function journal.player_has_unread(playerName)
	for _,v in pairs(journal.players[playerName].unread) do
		if v == true then
			return true
		end
	end
	return false
end