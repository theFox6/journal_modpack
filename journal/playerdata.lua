local cmp = modutil.require("check_prefix")
local precord = journal.require("players").record

local playerdata = {}

function playerdata.getKey(playerName,key)
  return precord[playerName].data[key]
end

function playerdata.setKey(playerName,key,value)
  precord[playerName].data[cmp(key)] = value
end

journal.playerdata_getKey = playerdata.get_key
journal.playerdata_setKey = playerdata.setKey

return playerdata
