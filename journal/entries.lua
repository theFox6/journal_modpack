journal.registered_pages = {}
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

function journal.register_page(pageId,pageName,firstMessage)
	journal.registered_pages[journal.check_modname_prefix(pageId)] = {name=pageName,first=firstMessage or ""}
end

journal.register_page("journal:personal_notes","personal notes")

function journal.get_page_Id(pageIndex)
	local i = 0
	for id,_ in pairs(journal.registered_pages) do
		i = i + 1
		if i==pageIndex then
			return id
		end
	end
	journal.log.warning("Invalid page index: "..pageIndex)
end

function journal.add_entry(player,pageId,entry,timestamp)
	if journal.entries[player]==nil then
		journal.entries[player]={}
	end
	local page = journal.check_modname_prefix(pageId)
	if journal.entries[player][page]==nil or journal.entries[player][page]=="" then
		if journal.registered_pages[page]~=nil then
			journal.entries[player][page]=journal.registered_pages[page].first
		else
			journal.entries[player][page]=""
		end
	end
	if journal.entries[player]==nil then
		journal.entries[player]={}
	end
	if journal.entries[player][page]==nil or journal.entries[player][page]=="" then
		if journal.registered_pages[page]~=nil then
			journal.entries[player][page]=journal.registered_pages[page].first
		else
			journal.entries[player][page]=""
		end
	end
	journal.entries[player][page]=journal.entries[player][page] .. "\n"
	if timestamp == true then
		local current_time = math.floor(minetest.get_timeofday() * 1440)
		local minutes = current_time % 60
		local hour = (current_time - minutes) / 60
		local days = minetest.get_day_count()
		--print(dump(days)..","..dump(hour)..":"..dump(minutes))
		journal.entries[player][page]=journal.entries[player][page] .. "day ".. days .. ", " .. hour .. ":" .. minutes
	end
	if entry ~= nil then
		journal.entries[player][page]=journal.entries[player][page] .. " " .. entry
	end

	if journal.players[player].reading == page then
		--reload page
		minetest.show_formspec(player,"journal:journal_" .. player,journal.make_formspec(player,page))
	else
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
end