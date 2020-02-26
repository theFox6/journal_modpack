local triggers = journal.require "triggers"
triggers.register_trigger("rightclick")
local rightclickfuncs = {}

function triggers.handle_rightclick(pos, node, clicker, itemstack, pointed_thing)
	local ret = rightclickfuncs[node.name](pos, node, clicker, itemstack, pointed_thing)

	if not clicker or not pos or not node then
		return ret
	end

	local name = clicker:get_player_name()
	if not name or name == "" then
		return ret
	end

	local data = {
		target = node.name,
		playerName = name,
		tool = clicker:get_wielded_item():get_name(),
	}

	triggers.run_callbacks("rightclick", data)
	return ret
end

minetest.after(3, function()
	for name, def in pairs(minetest.registered_items) do
		if def.on_rightclick then
			rightclickfuncs[name] = def.on_rightclick
		end
	end
	for name, _ in pairs(rightclickfuncs) do
		minetest.override_item(name,{on_rightclick=triggers.handle_rightclick})
	end
end)

triggers.register_trigger("pickup")
local old_punch = minetest.registered_entities["__builtin:item"].on_punch
rawset(minetest.registered_entities["__builtin:item"], "on_punch", function(self, hitter)
	old_punch(self, hitter)
	if not hitter or not self then
		return
	end

	local name = hitter:get_player_name()
	if not name or name == "" then
		return
	end

	local data = {
		target = self.itemstring,
		playerName = name,
		--tool = hitter:get_wielded_item():get_name(),
	}

	triggers.run_callbacks("pickup", data)
	return
end)