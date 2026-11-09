local Saturn = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/saturn-/main/loader.lua"))()

local Loading = Saturn:CreateLoader({ Title = "Saturn", Text = "Getting ready" })
Loading:Set(0.35, "Loading assets")
task.wait(0.4)
Loading:Set(0.8, "Building menu")

local Window = Saturn:CreateWindow({
	Title = "Saturn",
	Subtitle = "Showcase",
	Width = 760,
	Height = 500,
})

local Home = Window:AddTab("Home", "home")
local Combat = Window:AddTab("Combat", "combat")
local Farm = Window:AddTab("Farm", "farm")
local Visuals = Window:AddTab("Visuals", "esp")
Window:AddSection()
local Teleport = Window:AddTab("Teleport", "teleport")
local Misc = Window:AddTab("Misc", "misc")

local Welcome = Home:AddLeftGroupbox("Welcome")
Welcome:AddButton({
	Text = "Say hi",
	Func = function()
		Saturn:Notify("Saturn", "Hello from the showcase", 4, "star")
	end,
})
Welcome:AddButton({ Text = "Eclipse mode", Func = function()
	Saturn:Eclipse(true)
end })

local Main = Home:AddRightGroupbox("Main")
Main:AddToggle("AutoFarm", {
	Text = "Auto farm",
	Default = true,
}):AddKeybind("AutoFarmKey", { Default = "F", Mode = "Toggle" })
Main:AddToggle("AutoQuest", { Text = "Auto quest", Default = true })
Main:AddToggle("AutoCollect", { Text = "Auto collect", Default = false })
Main:AddSlider("FarmRange", { Text = "Range", Min = 10, Max = 300, Default = 120, Rounding = 0, Suffix = " studs" })
Main:AddDropdown("FarmTarget", { Text = "Target", Values = { "Closest", "Weakest", "Strongest", "Random" }, Default = "Closest" })

local Attack = Combat:AddLeftGroupbox("Attack")
Attack:AddToggle("AutoSwing", { Text = "Auto swing", Default = false })
Attack:AddSlider("SwingSpeed", { Text = "Swing delay", Min = 0, Max = 1, Default = 0.25, Rounding = 2, Suffix = "s" })
Attack:AddDropdown("Skills", {
	Text = "Skills",
	Multi = true,
	Values = { "Skill 1", "Skill 2", "Skill 3", "Ultimate" },
	Default = { "Skill 1", "Ultimate" },
})

local Defense = Combat:AddRightGroupbox("Defense")
Defense:AddToggle("AutoBlock", { Text = "Auto block", Default = false })
Defense:AddInput("HealAt", { Text = "Heal below", Numeric = true, Default = "40", Placeholder = "percent" })

local Farming = Farm:AddLeftGroupbox("Farming")
for i = 1, 6 do
	Farming:AddToggle("FarmSpot" .. i, { Text = "Spot " .. i, Default = i == 2 })
end
local Selling = Farm:AddRightGroupbox("Selling")
Selling:AddToggle("AutoSell", { Text = "Auto sell", Default = false })
Selling:AddDropdown("SellRarity", {
	Text = "Sell up to",
	Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine", "Celestial" },
	Default = "Rare",
})

local EspBox = Visuals:AddLeftGroupbox("Player ESP")
Saturn.ESP:AddSettings(EspBox, "PlayerESP")
local World = Visuals:AddRightGroupbox("World")
World:AddToggle("Fullbright", { Text = "Fullbright", Default = false }):AddColorPicker("AmbientColor", {
	Default = Color3.fromRGB(230, 232, 236),
})
World:AddSlider("Fov", { Text = "Field of view", Min = 70, Max = 120, Default = 90, Rounding = 0 })

local Places = Teleport:AddLeftGroupbox("Places")
for _, place in ipairs({ "Spawn", "Shop", "Arena", "Boss room" }) do
	Places:AddButton({ Text = place, Func = function()
		Saturn:Notify("Teleport", "Going to " .. place, 3, "teleport")
	end })
end

local Server = Misc:AddLeftGroupbox("Server")
Server:AddButton({ Text = "Rejoin", DoubleClick = true, Func = function() end })
Server:AddButton({ Text = "Server hop", Func = function() end })

Saturn:BuildSettingsTab(Window)
Home:Select()

Loading:Done()
Saturn:LoadAutoload()
Saturn:Notify("Saturn", "Loaded. Press Right Ctrl to hide the menu.", 5, "info")
