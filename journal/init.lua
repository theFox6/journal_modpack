--#number the time when the loading of this mod started
local init = os.clock()
--a log message displaying this mod is loading
minetest.log("action", "["..minetest.get_current_modname().."] loading...")

journal = {
  ---#string the path to this mod folder
	modpath = minetest.get_modpath("journal")
}

if not modutil then
    dofile(journal.modpath.."/modutil/portable.lua")
end

modutil.require("local_require")(journal)
local log = journal.require("log")


--coming soon ;)
--journal.require "quests"

journal.require "triggers"
journal.require "playerdata"
local forms = journal.require "forms"

-- journal command
minetest.register_chatcommand("journal", {
	description = "opens your journal", -- full description
	func = forms.show_journal
})

-- Unified Inventory support
if minetest.get_modpath("unified_inventory") ~= nil then
	unified_inventory.register_button("journal", {
		type = "image",
		image = "default_book_written.png",
		tooltip = "journal",
		action = function(player)
			local name = player:get_player_name()
			forms.show_journal(name)
		end,
	})
end

-- sfinv support
if minetest.get_modpath("betterinv") ~= nil then
	betterinv.register_tab("journal:journal", {
		description = "journal",
		getter = function(player)
			local name = player:get_player_name()
			forms.show_journal(name)
			return betterinv.generate_formspec(player, "button[1,1;3,1;open_journal;open journal]", {x = 5, y = 3}, false, false)
		end,
		processor = function(player, _, fields)
			local name = player:get_player_name()
			if fields.open_journal then
				forms.show_journal(name)
				return true
			end
		end
	})
elseif minetest.get_modpath("sfinv_buttons") ~= nil then
	sfinv_buttons.register_button("journal", {
		image = "default_book_written.png",
		tooltip = "your personal journal keeping track of what happens",
		title = "journal",
		action = function(player)
			local name = player:get_player_name()
			forms.show_journal(name)
		end,
	})
elseif minetest.get_modpath("sfinv") ~= nil then
	sfinv.register_page("journal:journal", {
		title = "journal",
		get = function(_, player, context)
			local name = player:get_player_name()
			forms.show_journal(name)
			return sfinv.make_formspec(player, context, "button[2.5,3;3,1;open_journal;open journal]", false)
		end,
		on_player_receive_fields = function(_, player, _, fields)
			local name = player:get_player_name()
			if fields.open_journal then
				forms.show_journal(name)
				return true
			end
		end
	})
end

--#number the time needed to load this mod
local time_to_load= os.clock() - init
--a message indicating this mod finished loading
log.action("loaded in %.4f s", time_to_load)
