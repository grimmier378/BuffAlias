local mq = require('mq')
local ImGui = require 'ImGui'
local drawTimerMS = mq.gettime() -- get the current time in milliseconds
local drawTimerS = os.time()     -- get the current time in seconds
local Module = {}
local MySelf = mq.TLO.Me
Module.Name = "BuffAlias" -- Name of the module used when loading and unloaing the modules.
Module.IsRunning = false  -- Keep track of running state. if not running we can unload it.
Module.ShowGui = false    -- Show the GUI when the module is loaded.
Module.Settings = {}
Module.TempSettings = {}

-- check if the script is being loaded as a Module (externally) or as a Standalone script.
---@diagnostic disable-next-line:undefined-global
local loadedExeternally = MyUI_ScriptName ~= nil and true or false
if not loadedExeternally then
	Module.Icons      = require('mq.ICONS') -- FAWESOME ICONS
	Module.CharLoaded = MySelf.CleanName()
	Module.Utils      = require('mq.Utils')
else
	Module.Icons      = MyUI_Icons
	Module.CharLoaded = MyUI_CharLoaded
	Module.Utils      = MyUI_Utils
end
local configFile = string.format("%s/MyUI/BuffAlias/buffnames.lua", mq.configDir)
local events = {}

local defaults = {
	['kei'] = "koadic's endless intellect",
	['sow'] = "Spirit of Wolf",
	['pon'] = "Protection of Nature",
	['potg'] = "Protection of the Glades",
	['brood'] = "Spirit of the Brood",
	['grm'] = "Group Resist Magic",
	['gom'] = "Gift of Magic",
	['gob'] = "Gift of Brilliance",
	['cow'] = "Circle of Winter",
	['cos'] = "Circle of Summer",
}

--Helpers
local function loadSettings()
	if Module.Utils.File.Exists(configFile) then
		Module.Settings = dofile(configFile)
	else
		Module.Settings = defaults
		mq.pickle(configFile, defaults)
	end
end

local function CommandHandler(...)
	local args = { ..., }
	if args[1] ~= nil then
		if args[1] == 'exit' or args[1] == 'quit' then
			Module.IsRunning = false
			if Module.Utils.PrintOutput then
				Module.Utils.PrintOutput('MyUI', true, "\ay%s \awis \arExiting\aw...", Module.Name)
			else
				printf("\aw[\at%s\ax] \ay%s \awis \arExiting\aw...", Module.Name)
			end
		elseif args[1] == 'list' then
			for k, v in pairs(Module.Settings) do
				if v ~= nil then
					printf("\aw[\at%s\ax] \ay%s \ax= (\at%s\ax)", Module.Name, k, v)
				end
			end
		elseif args[1] == 'show' or args[1] == 'gui' then
			Module.ShowGui = not Module.ShowGui
		elseif args[1] == 'add' and #args >= 3 then
			local alias = args[2]
			local spellName = ''
			if #args >= 3 then
				for i = 3, #args do
					spellName = spellName .. args[i]
					if i < #args then
						spellName = spellName .. ' '
					end
				end
			end
			if alias ~= nil and spellName ~= '' then
				Module.Settings[alias] = spellName
				mq.pickle(configFile, Module.Settings)
				printf("\aw[\at%s\ax] \agAdded\aw: \ay%s \ax= (\at%s\ax)", Module.Name, alias, spellName)
			else
				printf("\aw[\at%s\ax] \arUsage: /buffalias add <name> <spell>", Module.Name)
			end
		elseif args[1] == 'remove' and args[2] ~= nil then
			local alias = args[2]
			if Module.Settings[alias] ~= nil then
				Module.Settings[alias] = nil
				mq.pickle(configFile, Module.Settings)
				printf("\aw[\at%s\ax] \arRemoved\aw: \ay%s", Module.Name, alias)
			else
				printf("\aw[\at%s\ax] \arAlias not found\aw: \ay%s", Module.Name, alias)
			end
		end
	else
		Module.PrintHelp()
	end
end

function Module.PrintHelp()
	if Module.Utils.PrintOutput then
		Module.Utils.PrintOutput('MyUI', true, "\aw[\at%s\ax] \arCommands:\aw", Module.Name)
		Module.Utils.PrintOutput('MyUI', true, "\a-w/buffalias \agadd \ax<\atname\ax> <\ayspell\ax>\aw - \aoAdd a new buff alias\aw")
		Module.Utils.PrintOutput('MyUI', true, "\a-w/buffalias \agremove \ax<\atname\ax>\aw - \aoRemove a buff alias\aw")
		Module.Utils.PrintOutput('MyUI', true, "\a-w/buffalias \agshow\aw - \aoShow the GUI\aw")
		Module.Utils.PrintOutput('MyUI', true, "\a-w/buffalias \aglist\aw - \aoList all buff aliases\aw")
		Module.Utils.PrintOutput('MyUI', true, "\a-w/buffalias \agexit\aw - \aoUnload the module\aw")
	else
		printf("\aw[\at%s\ax] \arCommands:\aw", Module.Name)
		printf("\a-w/buffalias \agadd \ax<\atname\ax> <\ayspell\ax>\aw - \aoAdd a new buff alias\aw")
		printf("\a-w/buffalias \agremove \ax<\atname\ax>\aw - \aoRemove a buff alias\aw")
		printf("\a-w/buffalias \agshow\aw - \aoShow the GUI\aw")
		printf("\a-w/buffalias \aglist\aw - \aoList all buff aliases\aw")
		printf("\a-w/buffalias \agexit\aw - \aoUnload the module\aw")
	end
end

local function Init()
	-- your Init code here
	loadSettings()
	mq.bind("/buffalias", CommandHandler)
	Module.IsRunning = true
	Module.BuildEvents()
	if Module.Utils.PrintOutput then
		Module.Utils.PrintOutput('MyUI', false, "\a-w[\at%s\a-w] \agLoaded\aw!", Module.Name)
	else
		printf("\aw[\at%s\ax] \agLoaded\aw!", Module.Name)
	end
	if not loadedExeternally then
		mq.imgui.init(Module.Name, Module.RenderGUI)
		Module.LocalLoop()
	end
	Module.PrintHelp()
end

local function OnEvent(line, whoAsked, whatSpell)
	-- Called when the event is triggered
	-- line = the line that triggered the event
	-- whoAsked = the name of the person who asked for the buff
	-- whatSpell = the name of the spell to cast

	if Module.Settings[whatSpell] == nil then return end
	printf("\aw[\at%s\ax] \a-w[%s\aw] \a-gasked for \a-w[%s\aw]", Module.Name, whoAsked, whatSpell)
	mq.cmdf("/buffthem %s %s", whoAsked, Module.Settings[whatSpell])
end

function Module.BuildEvents()
	-- build the events for the module here
	mq.event('buffme', "#1# tells you, 'buffme #2#'#*#", OnEvent)
end

-- Exposed Functions
function Module.RenderGUI()
	if not Module.ShowGui then return end
	local open, show = ImGui.Begin(Module.Name, true, ImGuiWindowFlags.None)
	if show then
		ImGui.Text("Buff Alias")
		ImGui.Separator()
		Module.TempSettings.NewAlias = ImGui.InputTextWithHint("##NewAlias", "New Alias", Module.TempSettings.NewAlias)
		Module.TempSettings.NewSpell = ImGui.InputTextWithHint("##NewSpell", "New Spell", Module.TempSettings.NewSpell)
		if ImGui.Button("Add Alias") then
			if Module.TempSettings.NewAlias ~= "" and Module.TempSettings.NewSpell ~= "" then
				Module.Settings[Module.TempSettings.NewAlias] = Module.TempSettings.NewSpell
				mq.pickle(configFile, Module.Settings)
				Module.TempSettings.NewAlias = ""
				Module.TempSettings.NewSpell = ""
			end
		end

		ImGui.Separator()
		if ImGui.BeginTable("Aliases", 3, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg)) then
			ImGui.TableSetupColumn(Module.Icons.FA_TRASH, ImGuiTableColumnFlags.WidthFixed, 16)
			ImGui.TableSetupColumn("Alias", ImGuiTableColumnFlags.WidthFixed, 100)
			ImGui.TableSetupColumn("Spell", ImGuiTableColumnFlags.WidthStretch, 10)
			ImGui.TableHeadersRow()
			ImGui.TableNextRow()

			for k, v in pairs(Module.Settings) do
				ImGui.TableNextColumn()
				if ImGui.Button(Module.Icons.FA_TRASH .. "##" .. k) then
					Module.TempSettings.RemoveAlias = k
					Module.TempSettings.NeedRemove = true
				end
				ImGui.TableNextColumn()
				ImGui.Indent(5)
				ImGui.Text(k)
				ImGui.Unindent(5)
				ImGui.TableNextColumn()
				ImGui.Indent(5)
				ImGui.Text(v)
				ImGui.Unindent(5)
			end

			ImGui.EndTable()
		end
	end
	ImGui.End()
	if not open then
		Module.ShowGui = false
	end
end

function Module.Unload()
	mq.unevent('buffme')
	mq.unbind("/buffalias")
end

function Module.MainLoop()
	if loadedExeternally then
		if not MyUI_LoadModules.CheckRunning(Module.IsRunning, Module.Name) then return end
	end
	if Module.TempSettings.NeedRemove then
		if Module.Settings[Module.TempSettings.RemoveAlias] ~= nil then
			Module.Settings[Module.TempSettings.RemoveAlias] = nil
			mq.pickle(configFile, Module.Settings)
			Module.TempSettings.NeedRemove = false
			Module.TempSettings.RemoveAlias = nil
		end
	end
	if mq.gettime() - drawTimerMS < 500 then
		return
	else
		drawTimerMS = mq.gettime()
	end
	mq.doevents()
end

function Module.LocalLoop()
	while Module.IsRunning do
		Module.MainLoop()
		mq.delay(1)
	end
end

if mq.TLO.EverQuest.GameState() ~= "INGAME" then
	printf("\aw[\at%s\ax] \arNot in game, \ayTry again later...", Module.Name)
	Module.Unload()
	mq.exit()
end

Init()
return Module
