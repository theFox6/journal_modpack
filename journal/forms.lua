local log = journal.require "log"
local players = journal.require "players"
local entries = journal.require("entries")

local forms = {
  widgets = {}
}

-- Maximum characters per line in the text widget
local TEXT_LINELENGTH = 80

-- Inserts automatic line breaks into an entire text and preserves existing newlines
local linebreaker = function(text, linelength)
	local out = ""
	for s in string.gmatch(text, "([^\n]*)") do
		local l = minetest.wrap_text(s, linelength)
		out = out .. l
		if(string.len(l) == 0) then
			out = out .. "\n"
		end
	end
	-- Remove last newline
	if string.len(out) >= 1 then
		out = string.sub(out, 1, string.len(out) - 1)
	end
	return out
end

-- Inserts text suitable for a textlist (including automatic word-wrap)
local text_for_textlist = function(text, linelength)
	if text == nil then return "" end
	text = linebreaker(text, linelength)
	text = minetest.formspec_escape(text)
	text = string.gsub(text, "\n", ",")
	return text
end

forms.widgets.text = function(x, y, width, height, widget_id, data)
	local baselength = TEXT_LINELENGTH
	local widget_basewidth = 10
	local linelength = math.max(20, math.floor(baselength * (width / widget_basewidth)))

	-- TODO: Wait for Minetest to provide a native widget for scrollable read-only text with automatic line breaks.
	-- Currently, all of this had to be hacked into this script manually by using/abusing the table widget
	local formstring = "tablecolumns[text]"..
	"tableoptions[color=#000000ff;background=#00000000;border=false;highlight=#00000000;highlight_text=#000000ff]"..
	"table["..tostring(x)..","..tostring(y)..";"..tostring(width)..","..tostring(height)..
		";"..widget_id..";"..text_for_textlist(data, linelength).."]"
	return formstring
end

function forms.widgets.journal_tabs(active)
	if active == nil then active = "1" else active = tostring(active) end
	return "tabheader[0,1;journal_header;Category list,Entry;"..active..";true;true]"
end

function forms.widgets.journal_formspec()
	return "size[9.6,11.9]"..
	"background[-0.2,-0.2;10,12.5;JournalBackground.png]"
end

function forms.widgets.journal_categories(player,selected)
	local formstring = "textlist[-0.2,0.7;9.8,10.8;journal_categorylist;"
	local first = true
	for pageId,page in pairs(entries.registered_pages) do
		if first then
			first = false
		else
			formstring = formstring .. ","
		end
		if players.record[player].unread[pageId] then
			formstring = formstring .. "#ffff00"
		end
		formstring = formstring .. minetest.formspec_escape(page.name)
	end
	if selected == nil then
		selected = 1
	end
	formstring = formstring .. ";"..selected.."]"..
	"button[0,11.5;3,1;goto_category;Show category]"
	return formstring
end

function forms.make_formspec(player,pageId)
	if entries.list[player]==nil then
		entries.list[player]={}
	end
	local formspec = forms.widgets.journal_formspec()
	if pageId==nil then
		formspec = formspec .. forms.widgets.journal_tabs(1) .. forms.widgets.journal_categories(player,pageId)
		players.record[player].reading = false
		formspec = formspec .. "button_exit[4,11.5;1,1;quit;exit]"
	else
		formspec = formspec .. forms.widgets.journal_tabs(2)
		--formspec = formspec .. forms.widgets.text(-0.2,0.7,9.8,10.8, "entry", "no entries")
		entries.make_page(player,pageId)
		local text = ""
		for _,e in pairs(entries.list[player][pageId]) do
		  text = text .. e.text .. "\n"
		end
		formspec = formspec .. forms.widgets.text(-0.2,0.7,9.8,10.8, "entry", text)
		players.record[player].unread[pageId] = false
		if players.record[player].message~=false then
			if not players.has_unread(player) then
				minetest.get_player_by_name(player):hud_remove(players.record[player].message)
				players.record[player].message=false
			end
		end

		if pageId=="journal:personal_notes" then
			formspec = formspec ..
				"button[7.8,9.8;2,1;book;copy to book]" ..
				"box[-0.1,10.9;8.6,0.65;#000]" ..
				"field[0.2,11.1;8.8,1;note;;]" ..
				"field_close_on_enter[note;false]"..
				"button[8.8,10.8;1,1;write;write]"
		end

		players.record[player].reading = pageId
		formspec = formspec .. "button[4,11.5;1,1;show_categories;back]"
	end
	return formspec
end

function forms.book_formspec(playername)
	local formspec = "size[8,7]"
		.. "label[2,0;write personal notes to book]"
		.. "list[detached:journal_"..playername..";personal_notes_book;3.5,1;1,1;]"
		.. "list[current_player;main;0,2;8,4;]"
		.. "listring[]"
		.. "button[3.5,6;1,1;back;back]"
	return formspec
end

function forms.show_journal(player_name)
  minetest.show_formspec(player_name,"journal:journal_" .. player_name,forms.make_formspec(player_name))
end

function forms.on_receive_fields(player, formname, fields)
	if formname=="journal:book_personal_notes" then
		local playername = player:get_player_name()
		minetest.show_formspec(playername,"journal:journal_" .. playername,forms.make_formspec(playername))
	end
	if not string.find(formname,"journal:journal_") then
		return false
	end

	local playername = player:get_player_name()
	--process clicks on the tab header
	if fields.journal_header ~= nil then
		local tab = tonumber(fields.journal_header)
		if(tab==1) then
			minetest.show_formspec(playername,"journal:journal_" .. playername,forms.make_formspec(playername))
			return true
		elseif(tab==2) then
			if players.record[playername].category == nil then
				players.record[playername].category = entries.get_page_Id(1)
			end
			minetest.show_formspec(playername,"journal:journal_" .. playername,
				forms.make_formspec(playername,players.record[playername].category))
			return true
		else
			log.warning("tab not recognized: "..tab)
		end
	end
	--process clicks on the category list
	if fields.journal_categorylist then
		local event = minetest.explode_textlist_event(fields["journal_categorylist"])
		if event.type == "CHG" then
			players.record[playername].category = entries.get_page_Id(event.index)
		elseif event.type == "DCL" then
			players.record[playername].category = entries.get_page_Id(event.index)
			minetest.show_formspec(playername,"journal:journal_" .. playername,
				forms.make_formspec(playername,players.record[playername].category))
		end
		return true
	end
	--process going to a category
	if fields.goto_category then
		if players.record[playername].category == nil then
			players.record[playername].category = entries.get_page_Id(1)
		end
		minetest.show_formspec(playername,"journal:journal_" .. playername,
			forms.make_formspec(playername,players.record[playername].category))
		return true
	end
	--process writing personal notes
	if fields.write then
		entries.add_entry(playername,"journal:personal_notes",fields.note,true)
		return true
	end
	--process opening the form for writing personal notes to a book
	if fields.book then
		minetest.show_formspec(playername,"journal:book_personal_notes",forms.book_formspec(playername))
		return true
	end
	--process going back to the category list
	if fields.show_categories then
		players.record[playername].reading = false
		minetest.show_formspec(playername,"journal:journal_" .. playername,forms.make_formspec(playername))
		return true
	end
	--process exiting the journal
	if fields.quit then
		players.record[playername].reading = false
		return true
	end
	--don't process clicking on the entry
	if fields.entry then
		return true
	end
	--process writing personal notes
	if fields.note then
		entries.add_entry(playername,"journal:personal_notes",fields.note,true)
		return true
	end
end

minetest.register_on_player_receive_fields(forms.on_receive_fields)

return forms
