journal = {
	modpath = minetest.get_modpath("journal"),
	registered_pages = {},
	example_enabled = true -- enable the example.lua
}
dofile(journal.modpath.."/form.lua")

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
journal.entries = (function()
	local file_name = minetest.get_worldpath() .. "/journal_entries"

	minetest.register_on_shutdown(function()
		local file = io.open(file_name, "w")
		file:write(minetest.serialize(journal.entries))
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

local page_uid = 0

function journal.register_page(pageName,firstMessage)
	page_uid = page_uid + 1
	journal.registered_pages[page_uid] = {name=pageName,first=firstMessage}
	return page_uid
end

function journal.get_page_id(pageName)
	for id,page in pairs(journal.registered_pages) do
		if page.name==pageName then
			return id
		end
	end
	return journal.register_page(pageName,"This page was not registered!")
end

function journal.add_entry(player,pageName,entry)
	if journal.entries[player]==nil then
		journal.entries[player]={}
	end
	local page = journal.get_page_id(pageName)
	if journal.entries[player][page]==nil or journal.entries[player][page]=="" then
		if journal.registered_pages[page]~=nil then
			journal.entries[player][page]=journal.registered_pages[page].first
		else
			journal.entries[player][page]=""
		end
	end
	local current_time = math.floor(core.get_timeofday() * 1440)
	local minutes = current_time % 60
	local hour = (current_time - minutes) / 60
	local days = core.get_day_count()
	--print(dump(days)..","..dump(hour)..":"..dump(minutes))
	journal.entries[player][page]=journal.entries[player][page] .. "\nday ".. days .. ", " .. hour .. ":" .. minutes
	if entry ~= nil then
		journal.entries[player][page]=journal.entries[player][page] .. " " .. entry
	end
	--show entry notification to player
	if journal.players[player].message==false then
		journal.players[player].message = minetest.get_player_by_name(player):hud_add({
			hud_elem_type = "image",
			position = {x=1,y=0},
			scale = {x=1,y=1},
			text = "NewJournalEntry.png",
			alignment = {x=-1,y=1},
		})
	end
end

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()

	if journal.players[playerName] == nil then
		journal.players[playerName] = {data={}}
	end
	journal.players[playerName].joined=true
	journal.players[playerName].message=false
end)
minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	journal.players[playerName].joined=false
end)

function journal.playerdata_getKey(playerName,key)
	return journal.players[playerName].data[key]
end

function journal.playerdata_setKey(playerName,key,value)
	journal.players[playerName].data[key] = value
end

minetest.register_on_player_receive_fields(journal.on_receive_fields)

-- Unified Inventory
if minetest.get_modpath("unified_inventory") ~= nil then
	unified_inventory.register_button("journal", {
		type = "image",
		image = "default_book_written.png",
		tooltip = "journal",
		action = function(player)
			local name = player:get_player_name()
			minetest.show_formspec(name,"journal:journal_" .. name,journal.make_formspec(name))
		end,
	})
end

-- sfinv_buttons
if minetest.get_modpath("sfinv_buttons") ~= nil then
	sfinv_buttons.register_button("journal", {
		image = "default_book_written.png",
		tooltip = "a journal to write story in",
		title = "journal",
		action = function(player)
			local name = player:get_player_name()
			minetest.show_formspec(name,"journal:journal_" .. name,journal.make_formspec(name))
		end,
	})
elseif minetest.get_modpath("sfinv") ~= nil then
	sfinv.register_page("journal:journal", {
		title = "journal",
		get = function(self, player, context)
			local name = player:get_player_name()
			minetest.show_formspec(name,"journal:journal_" .. name,journal.make_formspec(name))
			return sfinv.make_formspec(player, context, "button[2.5,3;3,1;journal_button_goto_category;open journal]", false)
		end,
		on_player_receive_fields = function(self, player, context, fields)
			local name = player:get_player_name()
			--TODO: handle sfinv events here
			return journal.on_receive_fields(player, "journal:journal_"..name, fields)
		end
	})
end

if journal.example_enabled then
	dofile(journal.modpath.."/example.lua")
end