local Saturn = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/saturn-/main/loader.lua"))()

local Options = Saturn.Options
local LocalPlayer = game:GetService("Players").LocalPlayer
Saturn:SetFolder("Saturn/showcase")

local Loading = Saturn:CreateLoader({ Title = "Saturn", Text = "Starting" })
Loading:Set(0.3, "Loading assets")

local Window = Saturn:CreateWindow({
	Title = "Saturn",
	Footer = "Saturn Hub",
	FooterRight = "build " .. Saturn.Version,
	Badge = "Premium",
	ToggleKey = "RightControl",
})
Loading:Set(0.6, "Building menu")

Window:AddSection("Main")
local Tabs = {
	Home = Window:AddTab("Home", "home"),
	Farm = Window:AddTab("Auto Farm", "farm"),
	Controls = Window:AddTab("Controls", "auto"),
	Inputs = Window:AddTab("Inputs", "keybinds"),
	Visuals = Window:AddTab("Visuals", "esp"),
}

local Welcome = Tabs.Home:AddLeftGroupbox("Welcome")
Welcome:AddLabel("Every Saturn element is on these pages.")
Welcome:AddButton({ Label = "Say hi", Text = "Notify", Func = function()
	Saturn:Notify("Saturn", "Hi!", 3, "star")
end })
Welcome:AddButton({ Label = "Eclipse mode", Text = "Collapse", Func = function()
	Saturn:Eclipse(true)
end })
Welcome:AddButton({ Label = "Search", Text = "Ctrl + F", Func = function()
	Saturn:OpenSearch()
end })
local Status = Tabs.Home:AddRightGroupbox("Status")
local StatusStats = Status:AddStats({
	{ Label = "Session", Value = "00:00:00" },
	{ Label = "Options", Value = "0", Accent = true },
	{ Label = "Tabs", Value = "7" },
})
Status:AddProgress({ Text = "Loaded", Value = 1 })

local Farming = Tabs.Farm:AddLeftGroupbox("Farming")
Farming:AddToggle("FarmEnabled", { Text = "Auto Farm", Description = "Farms the nearest mobs", Default = true }):AddKeybind("FarmKey", { Default = "F" })
Farming:AddToggle("FarmCollect", { Text = "Auto Collect", Description = "Picks up drops", Default = true })
Farming:AddToggle("FarmSkills", { Text = "Use Skills" })
Farming:AddDropdown("FarmMethod", { Text = "Method", Values = { "Behind", "Above", "Below" }, Default = "Above" })
Farming:AddSlider("FarmDistance", { Text = "Distance", Min = 2, Max = 20, Default = 8, Suffix = " studs" })
Farming:AddButton({ Label = "Nearest mob", Text = "Teleport", Func = function()
	Saturn:Notify("Saturn", "Teleported", 2, "teleport")
end })

local Session = Tabs.Farm:AddRightGroupbox("Session")
local SessionStats = Session:AddStats({
	{ Label = "Time", Value = "00:42:17" },
	{ Label = "Gold", Value = "12,480", Accent = true },
	{ Label = "Kills", Value = "312" },
})
local Level = Session:AddProgress({ Text = "Level 47", Value = 0.68 })
Session:AddButton({ Text = "Reset session", Func = function()
	SessionStats:Set("Time", "00:00:00")
	SessionStats:Set("Gold", "0")
	SessionStats:Set("Kills", "0")
	Level:SetValue(0)
end })

local Targets = Tabs.Farm:AddRightGroupbox("Targets")
Targets:AddDropdown("FarmTargets", { Text = "Mobs", Values = { "Bandit", "Wolf", "Demon", "Boss" }, Multi = true, Default = { "Bandit", "Demon" } })
Targets:AddToggle("FarmBosses", { Text = "Bosses first", Description = "Skips mobs while a boss is up" })

local TargetCard = Saturn:CreateTargetCard()
local Fight = Tabs.Farm:AddLeftGroupbox("Target card")
TargetCard:AddSettings(Fight)
local fighting = 0
Fight:AddButton({ Label = "Training boss", Text = "Fight", Func = function()
	fighting += 1
	local id = fighting
	local hp, max = 50000, 50000
	local shield = TargetCard:GetBar("Shield") or TargetCard:AddBar("Shield", { Color = Color3.fromRGB(150, 170, 200), Height = 4 })
	shield:SetVisible(true)
	shield:Set(1)
	TargetCard:SetTarget({ Name = "Akaza", Subtitle = "Upper Moon 3", Badge = "Boss", Icon = "boss", Health = hp, MaxHealth = max })
	TargetCard:SetState("Fighting")
	task.spawn(function()
		while id == fighting and hp > 0 and not Saturn.Unloaded do
			task.wait(0.35)
			hp = math.max(0, hp - math.random(900, 2600))
			TargetCard:SetHealth(hp, max)
			shield:Set(math.max(0, hp / max - 0.5) * 2)
			if math.random() < 0.08 then
				TargetCard:SetState("Dodging")
				task.wait(0.6)
				TargetCard:SetState("Fighting")
			end
		end
		shield:SetVisible(false)
	end)
end })
Fight:AddButton({ Label = "Your character", Text = "Track", Func = function()
	fighting += 1
	if LocalPlayer.Character then
		TargetCard:SetTarget(LocalPlayer.Character)
		TargetCard:SetState("Waiting")
	end
end })

local Toggles = Tabs.Controls:AddLeftGroupbox("Toggles")
Toggles:AddToggle("DemoEnabled", { Text = "Enabled", Default = true })
Toggles:AddToggle("DemoKeyed", { Text = "With keybind" }):AddKeybind("DemoKeyedKey", { Default = "G" })
Toggles:AddToggle("DemoHold", { Text = "Hold to activate" }):AddKeybind("DemoHoldKey", { Default = "LeftShift", Mode = "Hold" })
Toggles:AddToggle("DemoTinted", { Text = "With colour" }):AddColorPicker("DemoTint", { Default = Color3.fromRGB(230, 232, 236) })
local Combo = Toggles:AddToggle("DemoCombo", { Text = "Colour and key" })
Combo:AddColorPicker("DemoComboColor", { Default = Color3.fromRGB(156, 160, 168) })
Combo:AddKeybind("DemoComboKey", { Default = "V" })

local Buttons = Tabs.Controls:AddLeftGroupbox("Buttons and labels")
local clicks = 0
local ClickLabel = Buttons:AddLabel("Clicks: 0")
Buttons:AddButton({ Text = "Click me", Func = function()
	clicks += 1
	ClickLabel:SetText("Clicks: " .. clicks)
end })
Buttons:AddButton({ Text = "Hold on, are you sure", DoubleClick = true, Func = function()
	Saturn:Notify("Saturn", "Confirmed", 2, "check")
end })
Buttons:AddDivider()
Buttons:AddButton({ Text = "Send notification", Func = function()
	Saturn:Notify("Saturn", "Notification", 4)
end })
Buttons:AddButton({ Text = "Long notification", Func = function()
	Saturn:Notify("Saturn", "A longer notification message that wraps onto a second line.", 8, "info")
end })
Buttons:AddDivider("Labels")
Buttons:AddLabel("Plain label")
Buttons:AddLabel("<b>Bold</b>  <font color=\"#9ca0a8\">Dim</font>  <i>Italic</i>")

local Sliders = Tabs.Controls:AddRightGroupbox("Sliders")
Sliders:AddSlider("DemoVolume", { Text = "Volume", Min = 0, Max = 100, Default = 72, Suffix = "%" })
Sliders:AddSlider("DemoDelay", { Text = "Delay", Min = 0, Max = 2, Default = 0.25, Rounding = 2, Suffix = "s" })
Sliders:AddSlider("DemoCount", { Text = "Items", Min = 1, Max = 10, Default = 4 })

local Dropdowns = Tabs.Controls:AddRightGroupbox("Dropdowns")
Dropdowns:AddDropdown("DemoMode", { Text = "Mode", Values = { "Legit", "Balanced", "Rage" }, Default = 2 })
Dropdowns:AddDropdown("DemoFruit", {
	Text = "Fruit",
	Values = { "Apple", "Banana", "Cherry", "Dragonfruit", "Grape", "Kiwi", "Lemon", "Mango", "Orange", "Peach", "Pear", "Plum" },
	Placeholder = "Pick a fruit",
	AllowNull = true,
})
Dropdowns:AddDropdown("DemoTargets", {
	Text = "Targets",
	Values = { "Players", "Mobs", "Bosses", "Chests", "NPCs" },
	Multi = true,
	Default = { "Mobs", "Bosses" },
})

local Text = Tabs.Inputs:AddLeftGroupbox("Text input")
Text:AddInput("DemoName", { Text = "Name", Placeholder = "Name", Finished = true })
Text:AddInput("DemoAmount", { Text = "Amount", Placeholder = "0", Numeric = true })
Text:AddInput("DemoPlain", { Placeholder = "No title" })

local Live = Tabs.Inputs:AddLeftGroupbox("Live values")
local LiveLabel = Live:AddLabel("")
local function refreshLive()
	local targets = {}
	for name in pairs(Options.DemoTargets.Value) do
		table.insert(targets, name)
	end
	table.sort(targets)
	LiveLabel:SetText(table.concat({
		"Enabled: " .. tostring(Options.DemoEnabled.Value),
		"Volume: " .. tostring(Options.DemoVolume.Value) .. "%",
		"Mode: " .. tostring(Options.DemoMode.Value),
		"Fruit: " .. tostring(Options.DemoFruit.Value or "none"),
		"Targets: " .. (#targets > 0 and table.concat(targets, ", ") or "none"),
		"Name: " .. (Options.DemoName.Value ~= "" and Options.DemoName.Value or "(empty)"),
		"Accent: #" .. Options.DemoAccentPreview.Value:ToHex():upper(),
	}, "\n"))
end

local Keys = Tabs.Inputs:AddRightGroupbox("Keybinds")
local KeyLabel = Keys:AddLabel("Keys: J, K, L")
Keys:AddKeybind("DemoToggleKey", {
	Text = "Toggle mode",
	Default = "J",
	Mode = "Toggle",
	Callback = function(state)
		KeyLabel:SetText("Toggle: " .. (state and "on" or "off"))
	end,
})
Keys:AddKeybind("DemoHoldKey2", {
	Text = "Hold mode",
	Default = "K",
	Mode = "Hold",
	Callback = function(held)
		KeyLabel:SetText(held and "Hold: held" or "Hold: released")
	end,
})
Keys:AddKeybind("DemoPressKey", {
	Text = "Press mode",
	Default = "L",
	Mode = "Press",
	Callback = function()
		Saturn:Notify("Saturn", "L pressed", 3, "keybinds")
	end,
})

local Colors = Tabs.Inputs:AddRightGroupbox("Colour pickers")
Colors:AddColorPicker("DemoAccentPreview", { Text = "Accent preview", Default = Saturn.Theme.Silver })
Colors:AddColorPicker("DemoGlass", { Text = "With transparency", Default = Color3.fromRGB(200, 205, 215), Transparency = 0.3 })
Colors:AddLabel("Enemy"):AddColorPicker("DemoEnemyColor", { Default = Color3.fromRGB(229, 72, 77), Title = "Enemy colour" })
Colors:AddLabel("Team"):AddColorPicker("DemoTeamColor", { Default = Color3.fromRGB(120, 170, 230), Title = "Team colour" })
Colors:AddButton({ Text = "Use preview as UI accent", Func = function()
	Saturn:SetTheme({ Silver = Options.DemoAccentPreview.Value })
end })

for _, id in ipairs({ "DemoEnabled", "DemoVolume", "DemoMode", "DemoFruit", "DemoTargets", "DemoName", "DemoAccentPreview" }) do
	Options[id]:OnChanged(refreshLive)
end
refreshLive()

local EspBox = Tabs.Visuals:AddLeftGroupbox("ESP preview")
local Preview = EspBox:AddESPPreview({ Tabs = { "Enemy", "Team" }, Height = 260 })
Preview:Set("Enemy", { Colour = Color3.fromRGB(229, 72, 77) })
Preview:Set("Team", { Colour = Color3.fromRGB(120, 170, 230) })

local EspOptions = Tabs.Visuals:AddRightGroupbox("ESP options")
EspOptions:AddDropdown("DemoEspTab", { Text = "Editing", Values = { "Enemy", "Team" }, Default = "Enemy" })
local shown = { Enemy = {}, Team = {} }
local function editing()
	return Preview:GetTab(Options.DemoEspTab.Value or "Enemy")
end
Options.DemoEspTab:OnChanged(function(name)
	local tab = Preview:GetTab(name or "Enemy")
	if tab then
		tab:Select()
	end
end)
EspOptions:AddToggle("DemoEspOutline", { Text = "Outline", Default = true, Orbit = false }):AddColorPicker("DemoEspOutlineColor", {
	Default = Color3.fromRGB(229, 72, 77),
	Title = "Outline colour",
	Callback = function(color)
		editing():SetColour(color)
	end,
})
Options.DemoEspOutline:OnChanged(function(on)
	shown[Options.DemoEspTab.Value or "Enemy"].Outline = on
	editing():SetOutline(on)
end)
for _, part in ipairs({ { "Name", "Name" }, { "Distance", "Distance" }, { "HealthBg", "Health bar" }, { "Tracer", "Tracer" } }) do
	EspOptions:AddToggle("DemoEsp" .. part[1], {
		Text = part[2],
		Default = part[1] ~= "Tracer",
		Orbit = false,
		Callback = function(on)
			shown[Options.DemoEspTab.Value or "Enemy"][part[1]] = on
			editing():Set({ [part[1]] = on })
		end,
	})
end
Preview:OnTabChanged(function(name, tab)
	Options.DemoEspTab:SetValue(name)
	local state = shown[name] or {}
	Options.DemoEspOutline:SetValue(state.Outline ~= false)
	Options.DemoEspOutlineColor:SetValue(tab.Colour)
	for _, part in ipairs({ "Name", "Distance", "HealthBg", "Tracer" }) do
		local default = part ~= "Tracer"
		local value = state[part]
		if value == nil then
			value = default
		end
		Options["DemoEsp" .. part]:SetValue(value)
	end
end)
EspOptions:AddSlider("DemoEspHealth", {
	Text = "Health",
	Min = 0,
	Max = 100,
	Default = 72,
	Suffix = "%",
	Callback = function(value)
		editing():SetHealth(value / 100)
	end,
})
EspOptions:AddInput("DemoEspTag", {
	Text = "Name tag",
	Placeholder = "Player name",
	Callback = function(value)
		editing():SetText("Name", value ~= "" and value or "Player")
	end,
})
EspOptions:AddInput("DemoEspUser", {
	Text = "Avatar user id",
	Placeholder = "UserId",
	Numeric = true,
	Finished = true,
	Callback = function(value)
		if tonumber(value) then
			Preview:SetUser(tonumber(value))
		end
	end,
})

local LiveEsp = Tabs.Visuals:AddRightGroupbox("Live ESP")
Saturn.ESP:AddSettings(LiveEsp, "SaturnESP")
Saturn.ESP:AddPlayers()

local Custom = Tabs.Visuals:AddLeftGroupbox("Custom row")
local Canvas = Custom:AddCustom(54)
local Strip = Instance.new("Frame")
Strip.Size = UDim2.fromScale(1, 1)
Strip.BackgroundColor3 = Color3.new(1, 1, 1)
Strip.BorderSizePixel = 0
Strip.Parent = Canvas
local StripCorner = Instance.new("UICorner")
StripCorner.CornerRadius = UDim.new(0, 8)
StripCorner.Parent = Strip
local StripGradient = Instance.new("UIGradient")
StripGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 31, 36)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(196, 199, 205)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 31, 36)),
})
StripGradient.Parent = Strip
local StripText = Instance.new("TextLabel")
StripText.BackgroundTransparency = 1
StripText.Size = UDim2.fromScale(1, 1)
StripText.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
StripText.TextSize = 15
StripText.TextColor3 = Color3.fromRGB(7, 7, 10)
StripText.Text = "Custom row"
StripText.Parent = Strip

Window:AddSection("Other")
Saturn:BuildSettingsTab(Window)
local Credits = Window:AddTab("Credits", "credits"):AddLeftGroupbox("Credits")
Credits:AddLabel("Saturn UI. Extra icons by Lucide (ISC licence).")

Tabs.Home:Select()
Loading:Done()
Saturn:LoadAutoload()

local started = os.clock()
task.spawn(function()
	while not Saturn.Unloaded do
		local t = math.floor(os.clock() - started)
		local count = 0
		for _ in pairs(Options) do
			count += 1
		end
		StatusStats:Set("Session", string.format("%02d:%02d:%02d", t // 3600, t // 60 % 60, t % 60))
		StatusStats:Set("Options", tostring(count))
		task.wait(1)
	end
end)

Saturn:Notify("Saturn", "Loaded. Right Control toggles the menu.", 5, "info")
