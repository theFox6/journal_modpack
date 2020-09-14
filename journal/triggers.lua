local cmp = modutil.require("check_prefix","venus")
local precord = journal.require("players").record

local triggers = {on = {}, counters={}}

triggers.count = (function()
	local file_name = minetest.get_worldpath() .. "/journal_counters"

	minetest.register_on_shutdown(function()
		local file = io.open(file_name, "w")
		for _,counter in pairs(triggers.counters) do
			counter:save()
		end
		file:write(minetest.serialize(triggers.count))
		file:close()
	end)

	local file = io.open(file_name, "r")
	if file ~= nil then
		local data = file:read("*a")
		file:close()
		return minetest.deserialize(data) or {}
	end
	return {}
end) ()

---
--@type counter
--@field #string id the counters name
--@field #string trigger the trigger should count up the counter
--@field #string target the target data that needs to match
--@field #string tool the tool data that needs to match
--@field #table value the counters value seperated by player
local counter = {}
local counter_meta = {__index = counter}
function counter.new(o)
  local n
  if type(o) == "table" then
    n = setmetatable(o,counter_meta)
  elseif o then
    error(("Bad argument \"%s\" given to create a new counter."):format(o),1)
  else
    n = setmetatable({},counter_meta)
  end
  return n
end

function counter:count(data)
  local player = data.playerName
  local ccount = 1

  if self.target then
    --get current count
    if data.current_count ~= nil then
      ccount = data.current_count
    end
  end

  if self.value[player] == nil then
    self.value[player] = ccount
  else
    self.value[player] = self.value[player] + ccount
  end
end

function counter:get_count(playerName)
  return self.value[playerName] or 0
end

function counter:save()
  triggers.count[self.id]=self.value
end

function counter:check(data)
  if self.trigger ~= data.trigger and self.trigger then
    return false
  end
  if self.target ~= data.target and self.target then
    return false
  end
  if self.tool ~= data.tool and self.tool then
    return false
  end
  return true
end

function triggers.register_counter(id,trigger,target,tool)
  local cid = cmp(id)
	triggers.counters[cid] = counter.new {
		id = cid,
		trigger = trigger,
		target = target,
		tool = tool,
		value = triggers.count[id] or {},
	}
end

function triggers.get_count(id,playerName)
	return triggers.counters[id]:get_count(playerName)
end

function triggers.register_trigger(name)
	if triggers.on[name] then
		-- trigger triggered by multiple mods
		return
	end
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
			-- id
			if def.id then
			 nDef.id = cmp(def.id)
			end
			-- call_once
			if def.call_once then
			 assert(nDef.id,"Trigger with call_once is missing an id.")
			 nDef.call_once = true
			end
			-- call_after
			if def.call_after == nil or def.call_after == false then
			  nDef.call_after = false
		  elseif type(def.call_after) == "string" then
		    nDef.call_after = {def.call_after}
	    elseif type(def.call_after) == "table" then
	      nDef.call_after = def.call_after
			end
			-- target
			if def.target == nil then
				nDef.target = false
			elseif def.target == false then
				nDef.target = false
			elseif type(def.target) == "string" then
				nDef.target = {def.target}
			elseif type(def.target) == "table" then
				nDef.target = def.target
			else
				error("Trying to register a trigger function with target string of type:"..type(def.target))
			end
			-- tool
			if def.tool == nil then
				nDef.tool = false
			elseif def.tool == false then
				nDef.tool = false
			elseif type(def.tool) == "string" then
				nDef.tool = def.tool
			else
				error("Trying to register a trigger function with tool string of type:"..type(def.tool))
			end
		else
			error("Trying to register a trigger function of type:"..type(def))
		end
		table.insert(triggers.on[name], nDef)
	end
end

local function callback_for(trigger,data)
  local pr = precord[data.playerName]
  if trigger.call_once then
    if pr.trig_call[trigger.id] then
      return
    end
  end
  if trigger.call_after then
    for _,bid in pairs(trigger.call_after) do
      if not pr.trig_call[bid] then
        return
      end
    end
  end
  if trigger.target then
    local found = false
    for _,v in pairs(trigger.target) do
      if data.target == v then
        found = true
        break
      end
      if data.target:find("group:")==1 then
        if minetest.get_item_group(v,data.target:sub(7))>0 then
          found = true
          break
        end
      end
    end
    if not found then return end
  end
  if trigger.tool then
    local found = false
    for _,v in pairs(trigger.tool) do
      if data.tool == v then
        found = true
        break
      end
      if data.tool:find("group:")==1 then
        if minetest.get_item_group(v,data.tool:sub(7))>0 then
          found = true
          break
        end
      end
    end
    if not found then return end
  end
  if not trigger.is_active(data.playerName) then return end
  if trigger.id then pr.trig_call[trigger.id] = true end
  trigger.call(data)
end

function triggers.run_callbacks(trigger, data)
  if trigger == nil then
    error("didn't get a trigger")
  end
	if data.playerName == nil then
		error("didn't get a playerName")
	end
	data.trigger = trigger
	for _,ct in pairs(triggers.counters) do
		if ct:check(data) then
			ct:count(data)
		end
	end
	for _,entry in pairs(triggers.on[trigger]) do
	  callback_for(entry,data)
	end
end

triggers.register_trigger("dig")
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
		playerName = name,
		tool = digger:get_wielded_item():get_name(),
	}

	--[[local node_drops = minetest.get_node_drops(oldnode.name, "")
	for _, item in pairs(node_drops) do
		if digger:get_wielded_item():get_name() == item:get_name() then
			data.tool = ""
		end
	end--]]

	triggers.run_callbacks("dig", data)
end)

triggers.register_trigger("place")
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

triggers.register_trigger("eat")
--hp_change, replace_with_item, itemstack, user, pointed_thing
minetest.register_on_item_eat(function(_, _, itemstack, user)
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

triggers.register_trigger("craft")
minetest.register_on_craft(function(itemstack, player) --itemstack, player, old_craft_grid, craft_inv
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

triggers.register_trigger("die")
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

triggers.register_trigger("join")
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

if minetest.register_on_hpchange then
	triggers.register_trigger("hpchange")
	minetest.register_on_player_hpchange(function(player, hp_change, reason)
		if not player then
			return
		end

		local name = player:get_player_name()
		if not name or name=="" then
			return
		end

		local data = {
			playerName = name,
			current_count = hp_change,
			tool = reason.type
		}

		triggers.run_callbacks("hpchange", data)
	end)
end

triggers.register_trigger("cheat")
minetest.register_on_cheat(function(player, cheat)
	if not player then
		return
	end

	local name = player:get_player_name()
	if not name or name=="" then
		return
	end

	local data = {
		playerName = name,
		tool = cheat.type
	}

	triggers.run_callbacks("cheat", data)
end)

triggers.register_trigger("chat")
minetest.register_on_chat_message(function(name, message)
	if not name then
		return
	end

	local data = {
		playerName = name,
		target = message
	}

	local idx = string.find(message,"/")
	if idx ~= nil and idx <= 1 then
		data.tool="command"
	else
		data.tool="message"
	end

	triggers.run_callbacks("chat", data)
end)

triggers.register_trigger("punchnode")
minetest.register_on_punchnode(function(pos,node,puncher)
	if not puncher or not pos or not node then
		return
	end

	local name = puncher:get_player_name()
	if not name or name == "" then
		return
	end

	local data = {
		target = node.name,
		playerName = name,
		tool = puncher:get_wielded_item():get_name(),
	}

	triggers.run_callbacks("punchnode", data)
end)

triggers.register_trigger("punchplayer")
minetest.register_on_punchplayer(function(_,puncher) --victim,puncher,dtime,punch,dist
	if not puncher then
		return
	end

	local name = puncher:get_player_name()
	if not name or name == "" then
		return
	end

	local data = {
		--target = victim:get_player_name(),
		playerName = name,
		tool = puncher:get_wielded_item():get_name(),
	}

	triggers.run_callbacks("punchplayer", data)
end)

triggers.counter = counter

journal.triggers = triggers

return triggers