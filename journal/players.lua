local players = {}

local player_file_name = minetest.get_worldpath() .. "/journal_players"
players.record = (function()
	local file = io.open(player_file_name, "r")
	if file ~= nil then
		local data = file:read("*a")
		file:close()
		local record = minetest.deserialize(data)
		if record then
			return record
		end
	end
	return {}
end) ()
minetest.register_on_shutdown(function()
  local file = io.open(player_file_name, "w")
  for _,p in pairs(players.record) do
    p.journal_inv = nil
  end
  file:write(minetest.serialize(players.record))
  file:close()
end)

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()

	if players.record[playerName] == nil then
		players.record[playerName] = {}
	end
	local pr = players.record[playerName]
	if pr.data == nil then
		pr.data = {}
	end
	if pr.unread == nil then
		pr.unread = {}
	end
	if pr.trig_call == nil then
	 pr.trig_call = {}
	end
	pr.joined=true
	pr.message=false
	pr.reading=false
	if not pr.journal_inv then
	  local writefunc = journal.require("entries").write_personal_notes_to_book
		local inv = minetest.create_detached_inventory("journal_"..playerName, {
			on_put = function(inv, listname, _, stack, putter)
				local pname = putter:get_player_name()
				if listname == "personal_notes_book" then
					if stack:get_name():find("default:book") then
						inv:remove_item(listname, stack)
						inv:add_item(listname, writefunc(pname))
					end
				end
			end,
		})
		inv:set_size("personal_notes_book", 1)
		pr.journal_inv = inv
	end
end)

minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	players.record[playerName].joined=false
end)

function players.has_unread(playerName)
	for _,v in pairs(players.record[playerName].unread) do
		if v == true then
			return true
		end
	end
	return false
end

return players
