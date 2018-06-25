journal.log = {}

function journal.log.make_logger(level)
	return function(text, ...)
		minetest.log(level, "[journal] "..text:format(...))
	end
end

journal.log.warning = journal.log.make_logger("warning")
journal.log.action = journal.log.make_logger("action")

function journal.check_modname_prefix(name)
	if name:sub(1,1) == ":" then
		-- If the name starts with a colon, we can skip the modname prefix
		-- mechanism.
		return name:sub(2)
	else
		-- Enforce that the name starts with the correct mod name.
		local modname = minetest.get_current_modname()
		if modname == nil then
			journal.log.warning("current_modname is nil")
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