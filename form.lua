journal.widgets={}

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
	text = linebreaker(text, linelength)
	text = minetest.formspec_escape(text)
	text = string.gsub(text, "\n", ",")
	return text
end

journal.widgets.text = function(x, y, width, height, widget_id, data)
	local baselength = TEXT_LINELENGTH
	local widget_basewidth = 10
	local linelength = math.max(20, math.floor(baselength * (width / widget_basewidth)))

	-- TODO: Wait for Minetest to provide a native widget for scrollable read-only text with automatic line breaks.
	-- Currently, all of this had to be hacked into this script manually by using/abusing the table widget
	local formstring = "tablecolumns[text]"..
	"tableoptions[color=#000000ff;background=#00000000;border=false;highlight=#00000000;highlight_text=#000000ff]"..
	"table["..tostring(x)..","..tostring(y)..";"..tostring(width)..","..tostring(height)..";"..widget_id..";"..text_for_textlist(data, linelength).."]"
	return formstring
end

function journal.widgets.journal_tabs(active)
	if active == nil then active = "1" else active = tostring(active) end
	return "tabheader[0,1;journal_header;Category list,Entry;"..active..";true;true]"
end

function journal.widgets.journal_formspec()
	return "size[9.6,11.9]"..
	"background[-0.2,-0.2;10,12.5;JournalBackground.png]"
end

function journal.widgets.journal_categories(selected)
	local formstring = "textlist[-0.2,0.7;9.8,10.8;journal_categorylist;"
	local first = true
	for id,page in pairs(journal.registered_pages) do
		if first then
			first = false
		else
			formstring = formstring .. ","
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

function journal.make_formspec(player,pageId)
	if journal.entries[player]==nil then
		journal.entries[player]={}
	end
	local formspec = journal.widgets.journal_formspec()
	if pageId==nil then
		formspec = formspec .. journal.widgets.journal_tabs(1) .. journal.widgets.journal_categories(pageId)
		journal.players[player].reading = false
	else
		formspec = formspec .. journal.widgets.journal_tabs(2)
		--formspec = formspec .. journal.widgets.text(-0.2,0.7,9.8,10.8, "entry", "no entries")
		if journal.entries[player][pageId]==nil or journal.entries[player][pageId]=="" then
			if journal.registered_pages[pageId]~=nil then
				journal.entries[player][pageId]=journal.registered_pages[pageId].first
			else
				journal.entries[player][pageId]=""
			end
		end
		formspec = formspec .. journal.widgets.text(-0.2,0.7,9.8,10.8, "entry", journal.entries[player][pageId])
		--TODO: detect not readed entrys
		if journal.players[player].message~=false then
			minetest.get_player_by_name(player):hud_remove(journal.players[player].message)
			journal.players[player].message=false
		end		

		journal.players[player].reading = pageId
	end
	formspec = formspec .. "button_exit[4,11.5;1,1;quit;exit]"
	return formspec
end

function journal.on_receive_fields(player, formname, fields)
	if not string.find(formname,"journal:journal_") then
		return false
	end

	local playername = player:get_player_name()

	--process clicks on the tab header
	if fields.journal_header ~= nil then
		local tab = tonumber(fields.journal_header)
		local formspec, subformname, contents
		local cid, eid
		if(tab==1) then
			minetest.show_formspec(playername,"journal:journal_" .. playername,journal.make_formspec(playername))
			return true
		elseif(tab==2) then
			if journal.players[playername].category == nil then
				journal.players[playername].category = journal.get_page_Id(1)
			end
			minetest.show_formspec(playername,"journal:journal_" .. playername,journal.make_formspec(playername,journal.players[playername].category))
			return true
		end
	end

	if fields.journal_categorylist then
		local event = minetest.explode_textlist_event(fields["journal_categorylist"])
		if event.type == "CHG" then
			journal.players[playername].category = journal.get_page_Id(event.index)
		elseif event.type == "DCL" then
			journal.players[playername].category = journal.get_page_Id(event.index)
			minetest.show_formspec(playername,"journal:journal_" .. playername,journal.make_formspec(playername,journal.players[playername].category))
		end
		return true
	end

	if fields.goto_category then
		if journal.players[playername].category == nil then
			journal.players[playername].category = journal.get_page_Id(1)
		end
		minetest.show_formspec(playername,"journal:journal_" .. playername,journal.make_formspec(playername,journal.players[playername].category))
		return true
	end

	if fields.quit then
		journal.players[playername].reading = false
		return true
	end
end

minetest.register_on_player_receive_fields(journal.on_receive_fields)