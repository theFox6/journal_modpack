# example  

enable/disable the example.lua by removing/adding "--" before the 'dofile(journal.modpath.."/example.lua")' in the init.lua  

# entries  

'journal.register_page(pageId,pageName,firstMessage)'  
register a journal category/chapter  
pageId: an identifier for the page, has to follow the same conventions as itemstrings for example: "journal:test"  
pageName: a title  
firstMessage: a first message like "this story will start when you have found your first iron" or "captains log:" can even be ""  

'journal.add_entry(player,pageId,entry,timestamp)'  
add an entry to the category/chapter  
in a new line a timestamp and the entry will appear  
player: the name of the player this entry is for  
pageId: the id of the category/chapter  
entry: well the entry ... like "today I found some gold" or "now I schould cut some trees to get wood"  
timestamp: true if you want a timestamp added  

'journal.get_page_Id(pageIndex)'  
get the id of the category/chapter (you probably won't need this)  

entries will be saved, pages won't be saved!  

# players  

'journal.playerdata_setKey(playerName,key,value)'  
save some player specific data  
playerName: the player this data is saved for  
key: the name of your data, has to follow the same conventions as itemstrings for example: "journal:test"  
value: the data you would like to save  

'journal.playerdata_getKey(playerName,key)'  
load some player specific data  
playerName: the player this data is loaded for  
key: the name of your data  

# triggers  

registered triggers: dig, place, eat, craft, die, join, chat, punchnode, punchplayer  

'journal.triggers['register_on_'..name](def)'  
for example: 'journal.triggers.register_on_place(def)'  
def: the trigger definition containing  
*call(data): the function that will be called, data contains:  
  *playerName: name of the player  
  *count: the number of times this target / trigger was triggered  
  *target: name of the node or item, for "dig", "place", etc.  
  *tool: the item the player wielded, for "dig", "punchnode", etc.  
  *current_count: the count of items as additional info to target  
*is_active(playerName): a function that returns whether this trigger is active, true or nil (not given) for always active  
*target: name of the node or item that should trigger this event, only for "dig", "place", etc., false or nil (not given) for no specific target  
*tool: name of the tool or item that should trigger this event, only for "punchplayer", "punchnode", etc., false or nil (not given) for no specific tool  

'journal.triggers.get_count(id,playerName)'  
get the number of times a counter was called  
id: name of the counter, for example: "journal:counterWood"  
playerName: the name of the player who this was counted for  

'journal.triggers.register_counter(id,trigger,target,tool)'  
register a counter for counting a triggered event  
id: name of the counter, has to follow the same conventions as itemstrings for example: "journal:test"  
trigger: name of the trigger that should be counted  
target: name of the node or item, for "dig", "place", etc., if false or nil (not given) the target will be ignored  
tool: name of the tool or item the player used, for "dig", "punchplayer", etc., if false or nil (not given) the tool will be ignored  

'journal.triggers.register_trigger(name)'  
prepare a trigger  
name: name of the trigger, for example: "craft"  

'journal.triggers.run_callbacks(trigger, data)'  
run the callbacks for a trigger (trigger the event)  
trigger: name of the trigger, for example: "die"  
data: the trigger data containing:  
  *playerName: name of the player  
  *target: name of the node or item  
  *tool: the item the player wielded  
  *current_count: the count of items as additional info to target  

# formspec  

'journal.make_formspec(player,pageId)'  
returns the formspec string of the journal (you probably won't need this)  
player: the name of the player it should be made for  
pageId: the id of the page to be shown, if it's nil (not given) it will show the category list  

'journal.on_receive_fields(player, formname, fields)'  
the field receive function for the formspec (you probably won't need this)  
player: the userdata of the player who for example clicked a button
formname: the name of the formspec for example: "journal:journal_sfinv"
fields: the fields table of the widgets that have just been used  