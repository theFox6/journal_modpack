journal.widgets={}

-- Maximum characters per line in the text widget
local TEXT_LINELENGTH = 80

-- Inserts line breaks into a single paragraph and collapses all whitespace (including newlines)
-- into spaces
local linebreaker_single = function(text, linelength)
	if linelength == nil then
		linelength = TEXT_LINELENGTH
	end
	local remain = linelength
	local res = {}
	local line = {}
	local split = function(s)
		local res = {}
		for w in string.gmatch(s, "%S+") do
			res[#res+1] = w
		end
		return res
	end

	for _, word in ipairs(split(text)) do
		if string.len(word) + 1 > remain then
			table.insert(res, table.concat(line, " "))
			line = { word }
			remain = linelength - string.len(word)
		else
			table.insert(line, word)
			remain = remain - (string.len(word) + 1)
		end
	end

	table.insert(res, table.concat(line, " "))
	return table.concat(res, "\n")
end

-- Inserts automatic line breaks into an entire text and preserves existing newlines
local linebreaker = function(text, linelength)
	local out = ""
	for s in string.gmatch(text, "([^\n]*)") do
		local l = linebreaker_single(s, linelength)
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
	for id,page in pairs(journal.registered_pages) do
		formstring = formstring .. minetest.formspec_escape(page.name) .. ","
	end
	--print(formstring:slice(formstring:len()-1,1)) --TODO:remove last ","
	if selected == nil then
		selected = 1
	end
	formstring = formstring .. ";"..selected.."]"..
	"button[0,11.5;3,1;journal_button_goto_category;Show category]"
	return formstring
end

function journal.make_formspec(player,page)
	if journal.entries[player]==nil then
		journal.entries[player]={}
	end
	local formspec = journal.widgets.journal_formspec()
	if page==nil then
		formspec = formspec .. journal.widgets.journal_tabs(1) .. journal.widgets.journal_categories(page)
	else
		formspec = formspec .. journal.widgets.journal_tabs(2)
		if (#journal.registered_pages==0 or journal.registered_pages[page]==nil) and page==1 then
			formspec = formspec .. journal.widgets.text(-0.2,0.7,9.8,10.8, "entry", "no entries")
		else
			if journal.entries[player][page]==nil or journal.entries[player][page]=="" then
				if journal.registered_pages[page]~=nil then
					journal.entries[player][page]=journal.registered_pages[page].first
				else
					journal.entries[player][page]=""
				end
			end
			formspec = formspec .. journal.widgets.text(-0.2,0.7,9.8,10.8, "entry", journal.entries[player][page])
		end
		--TODO: detect not readed entrys
		minetest.get_player_by_name(player):hud_remove(journal.players[player].message)
		journal.players[player].message=false
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
				journal.players[playername].category = 1
			end
			minetest.show_formspec(playername,"journal:journal_" .. playername,journal.make_formspec(playername,journal.players[playername].category))
			return true
		end
	end

	if fields.journal_categorylist then
		local event = minetest.explode_textlist_event(fields["journal_categorylist"])
		if event.type == "CHG" then
			journal.players[playername].category = event.index
		elseif event.type == "DCL" then
			journal.players[playername].category = event.index
			minetest.show_formspec(playername,"journal:journal_" .. playername,journal.make_formspec(playername,journal.players[playername].category))
		end
		return true
	end

	if fields.journal_button_goto_category then
		if journal.players[playername].category == nil then
			journal.players[playername].category = 1
		end
		minetest.show_formspec(playername,"journal:journal_" .. playername,journal.make_formspec(playername,journal.players[playername].category))
		return true
	end

	if fields.quit then
		return true
	end
end