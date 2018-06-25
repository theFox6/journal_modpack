local init = os.clock()
minetest.log("action", "["..minetest.get_current_modname().."] loading...")

journal = {
	modpath = minetest.get_modpath("journal")
}

dofile(journal.modpath.."/util.lua")
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
journal.log.action("loaded in %.4f s", time_to_load)
