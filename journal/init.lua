local init = os.clock()
if minetest.settings:get_bool("log_mods") then
  minetest.log("action", "[MOD] "..minetest.get_current_modname()..": loading")
else
  print("[MOD] "..minetest.get_current_modname()..": loading")
end

journal = {
	modpath = minetest.get_modpath("journal")
}

function journal.check_modname_prefix(name)
	if name:sub(1,1) == ":" then
		-- If the name starts with a colon, we can skip the modname prefix
		-- mechanism.
		return name:sub(2)
	else
		-- Enforce that the name starts with the correct mod name.
		local modname = minetest.get_current_modname()
		if modname == nil then
			minetest.log("warning","current_modname is nil")
			modname=name:split(":")[1]
		end
		local expected_prefix = modname .. ":"
		if name:sub(1, #expected_prefix) ~= expected_prefix then
			error("Name " .. name .. " does not follow naming conventions: " ..
				"\"" .. expected_prefix .. "\" or \":\" prefix required")
		end

		-- Enforce that the name only contains letters, numbers and underscores.
		local subname = name:sub(#expected_prefix+1)
		if subname:find("[^%w_]") then
			error("Name " .. name .. " does not follow naming conventions: " ..
				"contains unallowed characters")
		end

		return name
	end
end

dofile(journal.modpath.."/players.lua")
dofile(journal.modpath.."/entries.lua")
dofile(journal.modpath.."/triggers.lua")
dofile(journal.modpath.."/form.lua")

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
		get = function(_, player, context)
			local name = player:get_player_name()
			minetest.show_formspec(name,"journal:journal_" .. name,journal.make_formspec(name))
			--TODO: single button specially for opening
			return sfinv.make_formspec(player, context, "button[2.5,3;3,1;goto_category;open journal]", false)
		end,
		on_player_receive_fields = function(_, player, _, fields)
			local name = player:get_player_name()
			--TODO: only handle the button here
			return journal.on_receive_fields(player, "journal:journal_"..name, fields)
		end
	})
end

--ready
local time_to_load= os.clock() - init
if minetest.settings:get_bool("log_mods") then
  minetest.log("action", string.format("[MOD] "..minetest.get_current_modname()..": loaded in %.4f s", time_to_load))
else
  print(string.format("[MOD] "..minetest.get_current_modname()..": loaded in %.4f s", time_to_load))
end
