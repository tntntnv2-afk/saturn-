# Saturn

Black and silver UI library with a horizontal orbit tab rail.

## Load

```lua
local Saturn = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/saturn-/main/loader.lua"))()
```

The loader always grabs the newest build and keeps a copy in `Saturn/library_cache.lua`, which it uses if GitHub can't be reached.

## Window and tabs

```lua
local Window = Saturn:CreateWindow({
	Title = "Saturn",
	Footer = "Saturn Hub",
	FooterRight = "build 1",
	Badge = "Premium",
	ToggleKey = "RightControl",
})
Window:AddSection("Main")
local Main = Window:AddTab("Main", "farm")
Window:AddSection("Other")
Saturn:BuildSettingsTab(Window)
```

`CreateWindow` options, all optional:

- `Title`, `Subtitle` or `Game` (text next to the title; left out shows the place name, `false` hides it)
- `Footer`, `FooterRight` (status bar text; fps and ping are always shown), `Badge`, `User = false` hides your avatar and name
- `Width`, `Height` (760 x 500), `ToggleKey`, `Folder`
- `AutoShow = false` starts hidden. Players can also turn on Silent load in Settings.

Later: `Saturn:SetGame`, `SetSubtitle`, `SetFooter`, `SetFooterRight`, `SetBadge`, `SetToggleKey`, `Window:SetTitle`, `Tab:SetTitle`, `Tab:SetIcon`, `Tab:Select`.

Saturn icons: home, combat, farm, auto, player, visuals, esp, teleport, world, misc, settings, keybinds, webhook, server, stats, shop, inventory, quests, boss, safety, movement, aim, info, config, credits, search, close, minimize, pin, star, chevron, check. Any [Lucide](https://lucide.dev) name from the DexUI set also works (`swords`, `skull`, `trash-2`, `sliders-horizontal` and so on); `Saturn:HasIcon(name)` checks one.

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

More rows:

```lua
local Stats = Box:AddStats({ { Label = "Time", Value = "00:00" }, { Label = "Gold", Value = "0", Accent = true } })
Stats:Set("Gold", "1,200")
local Level = Box:AddProgress({ Text = "Level 47", Value = 0.68 })
Box:AddDivider("Labels")
Box:AddLabel("Enemy"):AddColorPicker("EnemyColor", { Default = Color3.fromRGB(229, 72, 77) })
Box:AddColorPicker("Glass", { Text = "Glass", Default = Color3.new(1, 1, 1), Transparency = 0.3 })
Box:AddKeybind("Dash", { Text = "Dash", Default = "Q", Mode = "Press", Callback = function() end })
local Canvas = Box:AddCustom(60)
```

Keybind modes are Toggle, Hold, Press and Always. Right click a key chip to change it. `ShowInList = false` hides a bind from the keybind list. `:SetDescription(text)` works on toggles, inputs, dropdowns, keybinds, colour pickers and labelled buttons.

Read values with `Saturn.Toggles.AutoFarm.Value` and `Saturn.Options.Range.Value`. Every option has `:SetValue(v)` and `:OnChanged(fn)`.

## Extras

- `Saturn:Notify(title, text, seconds, icon)`
- `Saturn:CreateLoader({ Title, Text })` returns `:Set(progress, text)` and `:Done()`
- `Saturn:Eclipse(true)` collapses the menu into the orbiting planet. Double tapping the menu key does the same.
- `Saturn:OpenSearch()` or Ctrl+F searches every setting
- `Saturn:SetOrbitBar(on)` top bar showing what's switched on
- `Saturn:SetStarfield(on)`, `Saturn:SetScale(1.1)`, `Saturn:SetTheme({ Silver = Color3.fromRGB(...) })`
- `Saturn:SetWatermark(on)` and `Saturn:SetKeybindList(on)`
- `Saturn:SetSilentLoad(on)`, `Saturn:GetSilentLoad()`
- `Saturn:Unload()`, `Saturn:OnUnload(fn)`

## Target card

```lua
local Card = Saturn:CreateTargetCard()
Card:AddSettings(SomeGroupbox)
Card:SetTarget(bossModel)
Card:SetTarget({ Model = bossModel, Name = "Akaza", Subtitle = "Upper Moon 3", Badge = "Boss" })
Card:SetState("Fighting")
Card:SetHealth(hp, max)
local Shield = Card:AddBar("Shield", { Color = Color3.fromRGB(150, 170, 200) })
Shield:Set(0.5)
```

Same API as the DexUI card: `SetEnabled`, `SetScale`, `ResetPosition`, `ResetKills`, `GetBar`, `Destroy`, `Card.Kills`.

## ESP preview

```lua
local Preview = Box:AddESPPreview({ Tabs = { "Enemy", "Team" }, Height = 260 })
Preview:GetTab("Enemy"):SetColour(Color3.fromRGB(229, 72, 77))
Preview:GetTab("Enemy"):Set({ Name = true, Distance = true, HealthBg = true, Tracer = false })
Preview:OnTabChanged(function(name, tab) end)
Preview:SetUser(1)
```

## ESP

```lua
local Box = Visuals:AddLeftGroupbox("Player ESP")
Saturn.ESP:AddSettings(Box, "PlayerESP")
Saturn.ESP:AddPlayers()
Saturn.ESP:Add(workspace.Boss, { Name = "Boss", Color = Color3.fromRGB(255, 90, 90) })
```

## Configs

Saved to `<folder>/configs/<name>.json`. In the Settings tab, type a name and press + to save; each saved config has load, overwrite, autoload and delete buttons. Call `Saturn:LoadAutoload()` after building the menu.

## Building

Edit files in `src/`, then run `python build.py` to make `Saturn.lua` and `python tools/check.py` to check it.
