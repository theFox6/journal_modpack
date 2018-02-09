local triggers = {on = {}, counters={}}

triggers.count = (function()
	local file_name = minetest.get_worldpath() .. "/journal_counters"

	minetest.register_on_shutdown(function()
		local file = io.open(file_name, "w")
		file:write(minetest.serialize(journal.triggers.count))
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

function triggers.register_counter(name,needsTarget)
	if needsTarget then
		triggers.counters[name] = function(name,data)
			local player = data.playerName
			if triggers.count[player] == nil then
				triggers.count[player]={}
			end
			if triggers.count[player][name] == nil then
				triggers.count[player][name] = {}
			end
			local counter = triggers.count[player][name]
			local target = data.target
			if target == nil then
				error("didn't get a target")
			end
			local ccount = data.current_count
			if ccount == nil then
				ccount = 1
			end
			if counter[target] == nil then
				counter[target] = ccount
			else
				counter[target] = counter[target] + ccount
			end
			return counter[target]
		end
	else
		triggers.counters[name] = function(name,data)
			local player = data.playerName
			if triggers.count[player] == nil then
				triggers.count[player]={}
			end
			local counter = triggers.count[player]
			if counter[name] == nil then
				counter[name] = 1
			else
				counter[name]=counter[name]+1
			end
			return counter[name]
		end
	end
end

function triggers.get_count(name,data)
	local player = data.playerName
	if triggers.count[player] == nil then
		return 0
	end
	local counter = triggers.count[player]
	if counter[name] == nil then
		return 0
	end
	counter = triggers.count[player][name]
	if type(counter) == "table" then
		if counter[data.target] == nil then
			return 0
		end
		return counter[data.target]
	else
		return counter
	end
end

function triggers.register_trigger(name,hasTarget)
	triggers.on[name] = {}
	triggers['register_on_'..name] = function(def)
		local nDef = {}
		if type(def) == "function" then
			nDef.call = def
			nDef.is_active = function() return true end
			nDef.target = false
		elseif type(def) == "table" then
			-- call(data)
			if type(def.call) == "function" then
				nDef.call = def.call
			else
				error("expected call function got:"..type(def.call))
			end
			-- is_active(playerName)
			if def.is_active == nil then
				nDef.is_active = function() return true end
			elseif def.is_active == true then
				nDef.is_active = function() return true end
			elseif type(def.is_active) == "function" then
				nDef.is_active = def.is_active
			else
				error("Trying to register a trigger function with is_active function of type:"..type(def.is_active))
			end
			-- target
			if def.target == nil then
				nDef.target = false
			elseif def.target == false then
				nDef.target = false
			elseif type(def.target) == "string" then
				nDef.target = def.target
			else
				error("Trying to register a trigger function with target string of type:"..type(def.target))
			end
		else
			error("Trying to register a trigger function of type:"..type(def))
		end
		table.insert(triggers.on[name], nDef)
	end
	if type(hasTarget)~="boolean" then
		error("hasTarget should be boolean")
	end
	triggers.register_counter(name,hasTarget)
end

function triggers.run_callbacks(trigger, data)
	if data.playerName == nil then
		error("didn't get a playerName")
	end
	data.count = triggers.counters[trigger](trigger,data)
	for id,entry in pairs(triggers.on[trigger]) do
		local active = entry.is_active(data.playerName)
		if active == true then
			if entry.target == false or entry.target == data.target then
				entry.call(data)
			end
		end
	end
end

triggers.register_trigger("dig",true)
minetest.register_on_dignode(function(pos, oldnode, digger)
	if not digger or not pos or not oldnode then
		return
	end
	
	local name = digger:get_player_name()
	if not name or name == "" then
		return
	end

	local data = {
		target = oldnode.name,
		playerName = name
	}

	triggers.run_callbacks("dig", data)
end)

triggers.register_trigger("place",true)
minetest.register_on_placenode(function(pos, node, placer)
	if not placer or not pos or not node then
		return
	end

	local name = placer:get_player_name()
	if not name or name == "" then
		return
	end

	local data = {
		target = node.name,
		playerName = name
	}

	triggers.run_callbacks("place", data)
end)

triggers.register_trigger("eat",true)
minetest.register_on_item_eat(function(hp_change, replace_with_item, itemstack, user, pointed_thing)
	if not user or not itemstack then
		return
	end

	local name = user:get_player_name()
	if not name or name == "" then
		return
	end

	local data = {
		target = itemstack:get_name(),
		playerName = name,
		current_count = itemstack:get_count()
	}

	triggers.run_callbacks("eat", data)
end)

triggers.register_trigger("craft",true)
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if not player or not itemstack then
		return
	end

	local name = player:get_player_name()
	if not name or name == "" then
		return
	end

	local data = {
		target = itemstack:get_name(),
		playerName = name,
		current_count = itemstack:get_count()
	}

	triggers.run_callbacks("craft", data)
end)

triggers.register_trigger("die",false)
minetest.register_on_dieplayer(function(player)
	if not player then
		return
	end

	local name = player:get_player_name()
	if not name or name=="" then
		return
	end

	local data = {
		playerName = name,
	}

	triggers.run_callbacks("die", data)
end)

triggers.register_trigger("join",false)
minetest.register_on_joinplayer(function(player)
	if not player then
		return
	end

	local name = player:get_player_name()
	if not name or name=="" then
		return
	end

	local data = {
		playerName = name,
	}

	triggers.run_callbacks("join", data)
end)

triggers.register_trigger("chat",true)
minetest.register_on_chat_message(function(name, message)
	if not name then
		return
	end

	local data = {
		playerName = name,
	}

	local idx = string.find(message,"/")
	if idx ~= nil and idx <= 1 then
		data.target="command"
	else
		data.target="message"
	end

	triggers.run_callbacks("chat", data)
end)

-- write to journal
journal.triggers = triggers