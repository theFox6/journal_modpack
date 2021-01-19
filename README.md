Do you want to add story to your game?  
Make your protagonist write notes into his Journal.  
# journal
![journal cover][screenshot]
[![ContentDB][contentdb badge]](https://content.minetest.net/packages/theFox/journal/)
[![luacheck][luacheck badge]][luacheck workflow]  
A minetest mod that adds a journal the player will write into.

Mods can add story into the game and the player can write his own journal.  
The journal can be accessed from the inventory and via /journal.

Check out the wiki on github to learn how to use it.

##Submodules

Currently journal only has the modutil portable submodule. It is needed to be able to run without the modutil mod.
This means you can either download the modutil mod and enable it or get the submodule:

When cloning add "--recursive" option to clone including all submodules:
```
git clone --recursive https://github.com/theFox6/factory.git
```
If one of the submodule folders is empty use:
```
git submodule update --init
```
This will clone all missing submodules.

[screenshot]: https://raw.githubusercontent.com/theFox6/journal_modpack/master/screenshot.png
[contentdb badge]: https://content.minetest.net/packages/theFox/journal/shields/title/
[luacheck badge]: https://github.com/theFox6/journal_modpack/workflows/luacheck/badge.svg
[luacheck workflow]: https://github.com/theFox6/journal_modpack/actions?query=workflow%3Aluacheck
