local log = journal.require "log"
local cmp = modutil.require "check_prefix"
local precord = journal.require("players").record

local entries = {registered_pages = {}}

local entry_file_name = minetest.get_worldpath() .. "/journal_entries"
entries.list = (function()
	local file = io.open(entry_file_name, "r")
	if file ~= nil then
		local data = file:read("*a")
		file:close()
		return minetest.deserialize(data)
	end
	return {}
end) ()
minetest.register_on_shutdown(function()
  local file = io.open(entry_file_name, "w")
  file:write(minetest.serialize(entries.list))
  file:close()
end)

function entries.register_page(pageId,pageName,firstMessage)
  local first = {text = firstMessage or "", id = 1}
  entries.registered_pages[cmp(pageId)] = {name=pageName,first=first,page_type="text"}
end

entries.register_page("journal:personal_notes","personal notes")

function entries.get_page_Id(pageIndex)
  local i = 0
  for id,_ in pairs(entries.registered_pages) do
    i = i + 1
    if i==pageIndex then
      return id
    end
  end
  log.warning("Invalid page index: "..pageIndex)
end

function entries.make_page(player,page)
  if entries.list[player]==nil then
    entries.list[player]={}
  end
  if entries.list[player][page]==nil or entries.list[player][page]=="" then
    if entries.registered_pages[page]~=nil then
      entries.list[player][page]={entries.registered_pages[page].first}
    else
      entries.list[player][page]={}
    end
  end
  --print(type(entries.list[player][page]))
  if type(entries.list[player][page]) == "string" then
    log.action("updating old journal page")
    local text = entries.list[player][page]
    entries.list[player][page]= {{ text = text }}
  end
end

local newEntryHud = {
  hud_elem_type = "image",
  position = {x=1,y=0},
  scale = {x=1,y=1},
  text = "NewJournalEntry.png",
  alignment = {x=-1,y=1},
}

function entries.add_entry(player,pageId,text,entryId)
  local page = cmp(pageId)
  entries.make_page(player,page)
	local entry = { text = "" }
	if entryId == true then
		local current_time = math.floor(minetest.get_timeofday() * 1440)
		local minutes = current_time % 60
		local hour = (current_time - minutes) / 60
		local days = minetest.get_day_count()
		--print(dump(days)..","..dump(hour)..":"..dump(minutes))
		--entry.text = "day ".. days .. ", " .. hour .. ":" .. minutes .. " " ..entry.text
		entry.text = ("day %d, %d:%d %s"):format(days,hour,minutes,entry.text)
	elseif entryId then
	 entry.id = entryId
	end
	if text ~= nil then
	 if entry.text ~= "" then
		entry.text = entry.text .. " "
	 end
	 entry.text = entry.text .. text
	end
	table.insert(entries.list[player][page],entry)

	if precord[player].reading == page then
		--reload page
		minetest.show_formspec(player,"journal:journal_" .. player,journal.require("forms").make_formspec(player,page))
	else
		--show entry notification to player
		precord[player].unread[page] = true
		if precord[player].message==false then
			precord[player].message = minetest.get_player_by_name(player):hud_add(newEntryHud)
		end
	end
end

function entries.edit_entry(player,pageId,entryId,text)
  local page = cmp(pageId)
  entries.make_page(player, page)
  for _,e in pairs(entries.list[player][page]) do
    if e.id == entryId then
      e.text = text
    end
  end
end

function entries.write_personal_notes_to_book(pname)
	local lpp = 14;
	local new_stack = ItemStack("default:book_written")
	local data = {
		title = "personal notes",
		text = entries.list[pname]["journal:personal_notes"],
		page = 1,
		owner = pname,
	}
	data.text_len = #data.text
	data.page_max = math.ceil((#data.text:gsub("[^\n]", "") + 1) / lpp)

	local data_str = minetest.serialize(data)

	new_stack:set_metadata(data_str);
	return new_stack;
end

journal.register_page = entries.register_page
journal.add_entry = entries.add_entry
journal.edit_entry = entries.edit_entry

return entries