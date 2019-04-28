journal.log = {}

---
--Create a logging function that preformats the log messages.
--The log messages will contain the name of this mod.
--
--@function [parent=#log] make_logger
--@param #string level the log level the messages will have
function journal.log.make_logger(level)
	return function(text, ...)
		minetest.log(level, "[journal] "..text:format(...))
	end
end

---
--A loging function for warnings from journal.
--Made using ${#log.make_logger}
--
--@function [parent=#log] warning
--@param #string text the text written to the log
--@param ... the arguments passed to the format performed on the text
journal.log.warning = journal.log.make_logger("warning")
---
--A loging function for actions from journal.
--Made using ${#log.make_logger}
--
--@function [parent=#log] action
--@param #string text the text written to the log
--@param ... the arguments passed to the format performed on the text
journal.log.action = journal.log.make_logger("action")

---
--A function to check if the prefix matches the modname.
--This function is also found in minetests builtin functions (local tho).
--
--@function [parent=#journal] check_modname_prefix
--@param #string name the id that needs a modname prefix
--@return #string the cleaned id
function journal.check_modname_prefix(name)
	if name:sub(1,1) == ":" then
		-- If the name starts with a colon, we can skip the modname prefix
		-- mechanism.
		return name:sub(2)
	else
		-- Enforce that the name starts with the correct mod name.
		local modname = minetest.get_current_modname()
		if modname == nil then
			--journal.log.info("current_modname is nil")
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