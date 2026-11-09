# Saturn

Black and silver UI library with a horizontal orbit tab rail.

## Load

```lua
local Saturn = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/saturn-/main/loader.lua"))()
```

The loader keeps a copy in `Saturn/library_cache.lua` so the menu opens instantly next time, then refreshes it in the background.

## Window and tabs

```lua
local Window = Saturn:CreateWindow({ Title = "Saturn", Subtitle = "Game name", Width = 760, Height = 500 })
local Main = Window:AddTab("Main", "farm")
Window:AddSection()
local Misc = Window:AddTab("Misc", "misc")
Saturn:BuildSettingsTab(Window)
```

Icons: home, combat, farm, auto, player, visuals, esp, teleport, world, misc, settings, keybinds, webhook, server, stats, shop, inventory, quests, boss, safety, movement, aim, info, config, credits, search, close, minimize, pin, star, chevron, check.

## Elements

```lua
local Box = Main:AddLeftGroupbox("Farming")

Box:AddToggle("AutoFarm", { Text = "Auto farm", Default = false, Description = "Optional second line", Callback = function(on) end })
	:AddKeybind("AutoFarmKey", { Default = "F", Mode = "Toggle" })

Box:AddSlider("Range", { Text = "Range", Min = 0, Max = 300, Default = 100, Rounding = 0, Suffix = " studs" })
Box:AddDropdown("Target", { Text = "Target", Values = { "Closest", "Weakest" }, Default = "Closest" })
Box:AddDropdown("Skills", { Text = "Skills", Values = { "Q", "E", "R" }, Multi = true, Default = { "Q" } })
Box:AddInput("Webhook", { Text = "Webhook", Placeholder = "https://", Finished = true })
Box:AddButton({ Text = "Rejoin", DoubleClick = true, Func = function() end })
Box:AddLabel("Some text")
Box:AddDivider()
Box:AddToggle("Glow", { Text = "Glow" }):AddColorPicker("GlowColor", { Default = Color3.fromRGB(230, 232, 236) })
```

Read values with `Saturn.Toggles.AutoFarm.Value` and `Saturn.Options.Range.Value`. Every option has `:SetValue(v)` and `:OnChanged(fn)`.

## Extras

- `Saturn:Notify(title, text, seconds, icon)`
- `Saturn:CreateLoader({ Title, Text })` returns `:Set(progress, text)` and `:Done()`
- `Saturn:Eclipse(true)` collapses the menu into the orbiting planet. Double tapping the menu key does the same.
- `Saturn:OpenSearch()` or Ctrl+F searches every setting
- `Saturn:SetOrbitBar(on)` top bar showing what's switched on
- `Saturn:SetStarfield(on)`, `Saturn:SetScale(1.1)`, `Saturn:SetTheme({ Silver = Color3.fromRGB(...) })`
- `Saturn:Unload()`, `Saturn:OnUnload(fn)`

## ESP

```lua
local Box = Visuals:AddLeftGroupbox("Player ESP")
Saturn.ESP:AddSettings(Box, "PlayerESP")
Saturn.ESP:AddPlayers()
Saturn.ESP:Add(workspace.Boss, { Name = "Boss", Color = Color3.fromRGB(255, 90, 90) })
```

## Configs

Saved to `Saturn/configs/<name>.json`. The Settings tab has save, load, delete and autoload. Call `Saturn:LoadAutoload()` after building the menu.

## Building

Edit files in `src/`, then run `python build.py` to make `Saturn.lua` and `python tools/check.py` to check it.
