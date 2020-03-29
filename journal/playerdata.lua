local log = journal.require("log")
local cmp = modutil.require("check_prefix")
local precord = journal.require("players").record

local playerdata = {}

function playerdata.getKey(playerName,key)
  local pr = precord[playerName]
  if not pr then
    return
  end
  return pr.data[key]
end

function playerdata.setKey(playerName,key,value)
  local pr = precord[playerName]
  if not pr then
    log.warning("The player %q doesn't seem to have joined the game yet.",playerName)
    precord[playerName] = {data = {}}
  end
  pr.data[cmp(key)] = value
end

journal.playerdata_getKey = playerdata.get_key
journal.playerdata_setKey = playerdata.setKey

return playerdata
