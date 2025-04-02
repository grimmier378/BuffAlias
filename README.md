# BuffAlias

Simple buff aliasing for use with MQ2BuffMe

You set up a list of aliases and their corrosponding buffname.
Will listen for buffme requests and if the alias was supplied we look up the spell name to cast.

commands: /buffalias
`/buffalias add <alias> <spell>` - Add a new buff alias
`/buffalias remove <alias>` - Remove a buff alias
`/buffalias show` - Show the GUI
`/buffalias list` - List all buff aliases
`/buffalias exit` - Unload the module

example: `/buffalias add kei koadic's endless intellect`
will setup the kei alias and if someone sends your enchanter `/tell enchanter buffme kei`
we will find the spell for the alias and have the enchanter `/buffthem requester spellname`

save file: all aliases are saved in `mq\config\myui\buffalias\buffnames.lua`

Users can ask you for a list of aliases and you will reply only with the ones for spells in your spell book.

`/tell buffer list`

https://www.youtube.com/watch?v=5_HTNoocGcA
