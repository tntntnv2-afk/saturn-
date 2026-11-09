local Env = (getgenv and getgenv()) or _G
if type(Env.SaturnLibrary) == "table" and Env.SaturnLibrary.Unloaded == false and type(Env.SaturnLibrary.Unload) == "function" then
	pcall(Env.SaturnLibrary.Unload, Env.SaturnLibrary)
end
local cloneref = (type(cloneref) == "function" and cloneref) or function(x)
	return x
end
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TextService = cloneref(game:GetService("TextService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Workspace = cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer

local Library = {
	Name = "Saturn",
	Version = "1.0.0",
	Repo = "https://raw.githubusercontent.com/tntntnv2-afk/saturn-/main/",
	Folder = "Saturn",
	Options = {},
	Toggles = {},
	Unloaded = false,
	Open = true,
	Scale = 1,
	ToggleKey = Enum.KeyCode.RightControl,
	Starfield = true,
	OrbitBarEnabled = true,
	NotifyEnabled = true,
	Theme = {
		Background = Color3.fromHex("07070a"),
		Chrome = Color3.fromHex("050507"),
		Panel = Color3.fromHex("0c0d10"),
		Field = Color3.fromHex("111215"),
		FieldHover = Color3.fromHex("16171b"),
		Border = Color3.fromHex("1b1c21"),
		BorderLight = Color3.fromHex("2a2b31"),
		Text = Color3.fromHex("eef0f3"),
		SubText = Color3.fromHex("b4b8bf"),
		Muted = Color3.fromHex("6f737c"),
		Silver = Color3.fromHex("e6e8ec"),
		SilverDim = Color3.fromHex("9ca0a8"),
		Off = Color3.fromHex("1a1b1f"),
		Knob = Color3.fromHex("5b5f67"),
		KnobOn = Color3.fromHex("0b0b0d"),
		Danger = Color3.fromHex("e5484d"),
	},
}

local S = {
	Connections = {},
	UnloadCallbacks = {},
	Themed = {},
	Loops = {},
	SearchIndex = {},
	ActiveToggles = {},
	OrbitBarHooks = {},
}
Library._internal = S

local FONT_FAMILY = "rbxasset://fonts/families/GothamSSm.json"
S.Font = Font.new(FONT_FAMILY, Enum.FontWeight.Medium)
S.FontSemi = Font.new(FONT_FAMILY, Enum.FontWeight.SemiBold)
S.FontBold = Font.new(FONT_FAMILY, Enum.FontWeight.Bold)
S.FontMono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium)

S.TweenFast = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
S.Tween = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
S.TweenSmooth = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
S.TweenGlide = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

function S.connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(S.Connections, c)
	return c
end

function S.bind(signal, fn)
	return signal:Connect(fn)
end

function S.tween(inst, info, props)
	local ok, t = pcall(TweenService.Create, TweenService, inst, info, props)
	if ok and t then
		t:Play()
		return t
	end
	for k, v in pairs(props) do
		pcall(function()
			inst[k] = v
		end)
	end
	return nil
end

function S.color(key)
	return Library.Theme[key] or key
end

local themedSincePrune = 0
local function pruneThemed()
	for inst in pairs(S.Themed) do
		if inst.Parent == nil then
			S.Themed[inst] = nil
		end
	end
end

function S.themed(inst, map)
	if S.Themed[inst] == nil then
		themedSincePrune += 1
		if themedSincePrune >= 400 then
			themedSincePrune = 0
			task.defer(pruneThemed)
		end
	end
	S.Themed[inst] = map
	for prop, key in pairs(map) do
		local value = Library.Theme[key]
		if value then
			pcall(function()
				inst[prop] = value
			end)
		end
	end
	return inst
end

function S.create(class, props, children)
	local inst = Instance.new(class)
	local theme
	if props then
		for k, v in pairs(props) do
			if k == "Theme" then
				theme = v
			elseif k ~= "Parent" then
				inst[k] = v
			end
		end
	end
	if theme then
		S.themed(inst, theme)
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function S.corner(radius)
	return S.create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function S.stroke(key, thickness, transparency)
	return S.create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		Theme = { Color = key or "Border" },
	})
end

function S.padding(t, r, b, l)
	return S.create("UIPadding", {
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or t or 0),
		PaddingBottom = UDim.new(0, b or t or 0),
		PaddingLeft = UDim.new(0, l or r or t or 0),
	})
end

function S.list(gap, horizontal, extra)
	local props = {
		Padding = UDim.new(0, gap or 0),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}
	if extra then
		for k, v in pairs(extra) do
			props[k] = v
		end
	end
	return S.create("UIListLayout", props)
end

function S.label(props)
	local base = {
		BackgroundTransparency = 1,
		FontFace = S.Font,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Theme = { TextColor3 = "Text" },
	}
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	return S.create("TextLabel", base)
end

function S.textWidth(text, size, font)
	local ok, bounds = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = tostring(text)
		params.Size = size
		params.Font = font or S.Font
		params.Width = 10000
		return TextService:GetTextBoundsAsync(params)
	end)
	if ok and typeof(bounds) == "Vector2" then
		return bounds.X
	end
	return #tostring(text) * size * 0.55
end

function S.guiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and typeof(hui) == "Instance" then
		return hui
	end
	local okCore = pcall(function()
		return CoreGui.Name
	end)
	if okCore then
		return CoreGui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

function S.screenGui(name, order)
	local gui = S.create("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 9000,
	})
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	gui.Parent = S.guiParent()
	table.insert(S.UnloadCallbacks, function()
		gui:Destroy()
	end)
	return gui
end

S.LoopErrors = setmetatable({}, { __mode = "k" })

function S.loop(fn)
	table.insert(S.Loops, fn)
	return fn
end

function S.unloop(fn)
	local i = table.find(S.Loops, fn)
	if i then
		table.remove(S.Loops, i)
	end
end

S.connect(RunService.RenderStepped, function(dt)
	for i = #S.Loops, 1, -1 do
		local fn = S.Loops[i]
		local ok, err = pcall(fn, dt)
		if not ok and not S.LoopErrors[fn] then
			S.LoopErrors[fn] = true
			task.defer(warn, "[Saturn] " .. tostring(err))
		end
	end
end)

function S.keyCode(name)
	if typeof(name) == "EnumItem" then
		return name.EnumType == Enum.KeyCode and name or nil
	end
	local ok, key = pcall(function()
		return Enum.KeyCode[tostring(name)]
	end)
	return ok and key or nil
end

function S.typing()
	if UserInputService:GetFocusedTextBox() then
		return true
	end
	local ok, focused = pcall(function()
		return game:GetService("TextChatService").ChatInputBarConfiguration.IsFocused
	end)
	return ok and focused == true
end

function S.screenPos(inst)
	local base = S.Overlay or S.Gui
	local offset = base and base.AbsolutePosition or Vector2.zero
	return inst.AbsolutePosition - offset
end

function S.safe(fn, ...)
	if type(fn) ~= "function" then
		return
	end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(fn, table.unpack(args, 1, args.n))
		if not ok then
			warn("[Saturn] callback error: " .. tostring(err))
		end
	end)
end

function S.isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function S.isMove(input, pressed)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		return pressed ~= nil and pressed.UserInputType == Enum.UserInputType.MouseButton1
	end
	return input.UserInputType == Enum.UserInputType.Touch and input == pressed
end

function S.draggable(handle, target, onMoved)
	local pressed, start, origin
	S.connect(handle.InputBegan, function(input)
		if S.isPress(input) and not pressed then
			pressed = input
			start = input.Position
			origin = target.Position
			local changed
			changed = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					pressed = nil
					changed:Disconnect()
					if onMoved then
						onMoved()
					end
				end
			end)
		end
	end)
	S.connect(UserInputService.InputChanged, function(input)
		if pressed and S.isMove(input, pressed) then
			local delta = input.Position - start
			target.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X, origin.Y.Scale, origin.Y.Offset + delta.Y)
		end
	end)
end

function Library:SetTheme(changes)
	for k, v in pairs(changes or {}) do
		self.Theme[k] = v
	end
	for inst, map in pairs(S.Themed) do
		if inst.Parent == nil then
			S.Themed[inst] = nil
			continue
		end
		for prop, key in pairs(map) do
			local value = self.Theme[key]
			if value then
				pcall(function()
					inst[prop] = value
				end)
			end
		end
	end
end

function Library:OnUnload(fn)
	table.insert(S.UnloadCallbacks, fn)
end

function Library:Unload()
	if self.Unloaded then
		return
	end
	self.Unloaded = true
	for _, fn in ipairs(S.UnloadCallbacks) do
		pcall(fn)
	end
	for _, c in ipairs(S.Connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(S.Loops)
	local env = (getgenv and getgenv()) or _G
	if env.SaturnLibrary == self then
		env.SaturnLibrary = nil
	end
end

do
	local okUser, VirtualUser = pcall(game.GetService, game, "VirtualUser")
	if LocalPlayer then
		if type(getconnections) == "function" then
			pcall(function()
				local disabled = {}
				for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
					if connection.Disable and connection.Enable then
						connection:Disable()
						table.insert(disabled, connection)
					end
				end
				table.insert(S.UnloadCallbacks, function()
					for _, connection in ipairs(disabled) do
						pcall(connection.Enable, connection)
					end
				end)
			end)
		end
		if okUser and VirtualUser then
			S.connect(LocalPlayer.Idled, function()
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end)
			end)
		end
	end
end

function S.ensureFolder(path)
	if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
		return false
	end
	local built = ""
	for part in tostring(path):gmatch("[^/]+") do
		built = built == "" and part or (built .. "/" .. part)
		if not isfolder(built) then
			pcall(makefolder, built)
		end
	end
	return isfolder(path)
end

function Library:SetFolder(folder)
	self.Folder = tostring(folder)
	S.ensureFolder(self.Folder)
	S.ensureFolder(self.Folder .. "/configs")
end
do
S.Assets = {}
S.AssetCache = {}
S.AssetLoading = {}
S.Animated = {}
S.AnimClock = 0

local function hasFileApi()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
		and type(isfolder) == "function" and type(makefolder) == "function"
end

local function isImage(data)
	return type(data) == "string" and #data > 8 and (data:sub(2, 4) == "PNG" or data:sub(1, 2) == "\255\216")
end

function Library:DefineAsset(name, spec)
	assert(type(name) == "string" and name ~= "", "asset name expected")
	assert(type(spec) == "table", "asset spec expected")
	S.Assets[name] = spec
	S.AssetCache[name] = nil
	return spec
end

function Library:GetAssetSpec(name)
	return S.Assets[name]
end

function Library:GetAsset(name)
	local spec = S.Assets[name]
	if not spec then
		return nil
	end
	while S.AssetLoading[name] do
		task.wait()
	end
	if S.AssetCache[name] ~= nil then
		return S.AssetCache[name] or nil
	end
	S.AssetCache[name] = false
	local getAsset = getcustomasset or getsynasset
	if type(getAsset) ~= "function" or not hasFileApi() then
		S.AssetCache[name] = spec.Fallback or false
		return S.AssetCache[name] or nil
	end
	S.AssetLoading[name] = true
	local ok, id = pcall(function()
		local source = spec.Path or spec.Url or name
		local extension = source:match("%.(%w+)$") or "png"
		local base = source:match("([^/]+)%.%w+$") or name
		local folder = "Saturn/assets"
		local file = string.format("%s/%s_v%s.%s", folder, base, tostring(spec.Version or 1), extension)
		local cached = isfile(file) and readfile(file) or ""
		if not isImage(cached) then
			local data = game:HttpGet(spec.Url or (Library.Repo .. spec.Path))
			if not isImage(data) then
				return nil
			end
			S.ensureFolder(folder)
			writefile(file, data)
		end
		return getAsset(file)
	end)
	S.AssetLoading[name] = nil
	if ok and type(id) == "string" and id ~= "" then
		S.AssetCache[name] = id
	else
		S.AssetCache[name] = spec.Fallback or false
	end
	return S.AssetCache[name] or nil
end

local function sheetFrame(sheet)
	local durations = sheet.Durations
	if durations then
		if not sheet._total then
			local total = 0
			for _, ms in ipairs(durations) do
				total += ms
			end
			sheet._total = math.max(total, 1)
		end
		local at = (S.AnimClock * 1000) % sheet._total
		for index, ms in ipairs(durations) do
			if at < ms then
				return index - 1
			end
			at -= ms
		end
		return #durations - 1
	end
	return math.floor(S.AnimClock * (sheet.Fps or 20)) % sheet.Frames
end

S.loop(function(dt)
	S.AnimClock += dt or 0
	for i = #S.Animated, 1, -1 do
		local entry = S.Animated[i]
		local image, sheet = entry[1], entry[2]
		if image.Parent == nil then
			table.remove(S.Animated, i)
		elseif image.Visible then
			local frame = sheetFrame(sheet)
			local offset = Vector2.new((frame % sheet.Columns) * sheet.Width, math.floor(frame / sheet.Columns) * sheet.Height)
			if image.ImageRectOffset ~= offset then
				image.ImageRectOffset = offset
			end
		end
	end
end)

function Library:Animate(image, sheet)
	assert(sheet and sheet.Width and sheet.Height and sheet.Columns and sheet.Frames, "sprite sheet needs Width, Height, Columns, Frames")
	image.ImageRectSize = Vector2.new(sheet.Width, sheet.Height)
	image.ImageRectOffset = Vector2.zero
	table.insert(S.Animated, { image, sheet })
	return image
end

function Library:Image(parent, name, props)
	props = props or {}
	local image = S.create("ImageLabel", {
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Size = props.Size or UDim2.fromOffset(32, 32),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ImageTransparency = props.ImageTransparency or 0,
		ZIndex = props.ZIndex or 1,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = parent,
	})
	local spec = S.Assets[name]
	if spec and spec.Sheet then
		self:Animate(image, spec.Sheet)
	end
	task.spawn(function()
		local id = self:GetAsset(name)
		if image.Parent == nil then
			return
		end
		if id then
			image.Image = id
			S.safe(props.OnLoaded, image)
		else
			S.safe(props.OnFailed, image)
		end
	end)
	return image
end

S.LogoSheet = {
	Width = 160, Height = 80, Columns = 6, Frames = 60, Fps = 50,
}
Library:DefineAsset("Logo", { Path = "assets/saturn_logo_anim.png", Version = 1, Sheet = S.LogoSheet })
Library:DefineAsset("Icons", { Path = "assets/icons.png", Version = 1 })
Library:DefineAsset("Ring", { Path = "assets/orbit_ring.png", Version = 2 })
Library:DefineAsset("Glide", { Path = "assets/glide.png", Version = 2 })

S.ICON_SIZE = 64
S.ICON_COLUMNS = 8
S.ICON_NAMES = {
	"home", "combat", "farm", "auto", "player", "visuals", "esp", "teleport",
	"world", "misc", "settings", "keybinds", "webhook", "server", "stats", "shop",
	"inventory", "quests", "boss", "safety", "movement", "aim", "info", "config",
	"credits", "search", "close", "minimize", "pin", "star", "chevron", "check",
}
S.ICON_INDEX = {}
for i, name in ipairs(S.ICON_NAMES) do
	S.ICON_INDEX[name] = i - 1
end
S.ICON_ALIASES = {
	house = "home", swords = "combat", sword = "combat", sprout = "farm", eye = "visuals", user = "player",
	["map-pin"] = "teleport", globe = "world", grid = "misc", ["layout-grid"] = "misc", gear = "settings",
	keyboard = "keybinds", link = "webhook", bell = "webhook", chart = "stats", bag = "shop", box = "inventory",
	scroll = "quests", crown = "boss", skull = "boss", shield = "safety", wind = "movement", crosshair = "aim",
	target = "aim", save = "config", heart = "credits", x = "close",
}

function S.iconRect(name)
	local index = S.ICON_INDEX[name] or S.ICON_INDEX[S.ICON_ALIASES[name] or ""] or S.ICON_INDEX.misc
	return Vector2.new((index % S.ICON_COLUMNS) * S.ICON_SIZE, math.floor(index / S.ICON_COLUMNS) * S.ICON_SIZE)
end

function Library:Icon(parent, name, size, props)
	props = props or {}
	local base = {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size or 16, size or 16),
		ImageRectSize = Vector2.new(S.ICON_SIZE, S.ICON_SIZE),
		ImageRectOffset = S.iconRect(name),
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Parent = parent,
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	if not base.Theme and not props.ImageColor3 then
		base.Theme = { ImageColor3 = "Muted" }
	end
	local icon = S.create("ImageLabel", base)
	task.spawn(function()
		local id = self:GetAsset("Icons")
		if id and icon.Parent then
			icon.Image = id
		end
	end)
	return icon
end

function Library:SetIcon(icon, name)
	icon.ImageRectOffset = S.iconRect(name)
end
end
do
S.Gui = S.screenGui("Saturn", 9000)
S.Overlay = S.screenGui("SaturnOverlay", 9100)
S.HudGui = S.screenGui("SaturnHud", 8990)

local TITLE_H = 48
local RAIL_H = 44

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab
S.TabClass = Tab

local function makeStars(parent)
	local holder = S.create("Frame", {
		Name = "Starfield",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ZIndex = 0,
		Parent = parent,
	})
	local stars = {}
	local rng = Random.new(1123)
	for i = 1, 70 do
		local size = rng:NextNumber() < 0.15 and 2 or 1
		local star = S.create("Frame", {
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 0.55 + rng:NextNumber() * 0.35,
			Position = UDim2.fromScale(rng:NextNumber(), 0.03 + rng:NextNumber() * 0.94),
			ZIndex = 0,
			Theme = { BackgroundColor3 = "Silver" },
			Parent = holder,
		}, { S.corner(2) })
		stars[i] = { star, rng:NextNumber() * 0.006 + 0.002, rng:NextNumber() * math.pi * 2, star.BackgroundTransparency }
	end
	S.loop(function(dt)
		if not holder.Visible or not Library.Open then
			return
		end
		for _, entry in ipairs(stars) do
			local star, speed, phase, base = entry[1], entry[2], entry[3], entry[4]
			local p = star.Position
			local x = p.X.Scale + speed * dt
			if x > 1.02 then
				x = -0.02
			end
			star.Position = UDim2.fromScale(x, p.Y.Scale)
			local alpha = 1 - math.clamp(base + math.sin(S.AnimClock * 1.3 + phase) * 0.12, 0, 1)
			local edge = math.clamp(math.min(x, 1 - x) / 0.04, 0, 1)
			star.BackgroundTransparency = 1 - alpha * edge
		end
	end)
	return holder
end

local function windowButton(parent, icon, order)
	local button = S.create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(28, 28),
		LayoutOrder = order,
		Theme = { BackgroundColor3 = "Field" },
		Parent = parent,
	}, { S.corner(8), S.stroke("Border") })
	local glyph = Library:Icon(button, icon, 14, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Theme = { ImageColor3 = "Muted" },
	})
	S.connect(button.MouseEnter, function()
		S.tween(button, S.TweenFast, { BackgroundColor3 = Library.Theme.FieldHover })
		S.tween(glyph, S.TweenFast, { ImageColor3 = Library.Theme.Text })
	end)
	S.connect(button.MouseLeave, function()
		S.tween(button, S.TweenFast, { BackgroundColor3 = Library.Theme.Field })
		S.tween(glyph, S.TweenFast, { ImageColor3 = Library.Theme.Muted })
	end)
	return button, glyph
end

function Library:CreateWindow(options)
	options = options or {}
	if S.Window then
		return S.Window
	end
	if options.Folder then
		self:SetFolder(options.Folder)
	else
		S.ensureFolder(self.Folder)
		S.ensureFolder(self.Folder .. "/configs")
	end
	if options.ToggleKey then
		self.ToggleKey = S.keyCode(options.ToggleKey) or self.ToggleKey
	end
	local width = options.Width or 760
	local height = options.Height or 500
	local self_ = setmetatable({ Tabs = {}, Library = self }, Window)
	S.Window = self_

	local Main = S.create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		ClipsDescendants = false,
		Theme = { BackgroundColor3 = "Background" },
		Parent = S.Gui,
	}, { S.corner(14), S.stroke("Border") })
	self_.Main = Main
	local Scale = S.create("UIScale", { Scale = self.Scale, Parent = Main })
	self_.ScaleObject = Scale
	S.create("UISizeConstraint", { MinSize = Vector2.new(520, 340), Parent = Main })

	local Inner = S.create("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		Parent = Main,
	}, { S.corner(14) })
	self_.Inner = Inner
	local Stars = makeStars(Inner)
	self_.Stars = Stars
	Stars.Visible = self.Starfield

	local Title = S.create("Frame", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, TITLE_H),
		ZIndex = 2,
		Parent = Inner,
	})
	local Brand = S.create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -150, 1, 0),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = Title,
	}, { S.list(10, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local Logo = self:Image(Brand, "Logo", { Size = UDim2.fromOffset(60, 30), ZIndex = 2, LayoutOrder = 1 })
	self_.Logo = Logo
	local TitleText = S.label({
		Text = options.Title or "SATURN",
		FontFace = S.FontBold,
		TextSize = 14,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		LayoutOrder = 2,
		ZIndex = 2,
		Theme = { TextColor3 = "Text" },
		Parent = Brand,
	})
	self_.TitleLabel = TitleText
	local Sub = S.label({
		Text = tostring(options.Subtitle or ""),
		TextSize = 12,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		LayoutOrder = 3,
		ZIndex = 2,
		Theme = { TextColor3 = "Muted" },
		Parent = Brand,
	})
	self_.SubLabel = Sub
	if options.Subtitle == nil then
		task.spawn(function()
			local ok, info = pcall(function()
				return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
			end)
			if ok and type(info) == "table" and info.Name and Sub.Parent and Sub.Text == "" then
				Sub.Text = tostring(info.Name)
			end
		end)
	end

	local Buttons = S.create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(100, 28),
		ZIndex = 2,
		Parent = Title,
	}, { S.list(6, true, { HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local SearchBtn = windowButton(Buttons, "search", 1)
	local MinBtn = windowButton(Buttons, "minimize", 2)
	local CloseBtn, CloseGlyph = windowButton(Buttons, "close", 3)
	S.draggable(Title, Main)

	S.create("Frame", {
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, TITLE_H),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Border" },
		Parent = Inner,
	})

	local RailHolder = S.create("CanvasGroup", {
		Name = "Rail",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, TITLE_H + 1),
		Size = UDim2.new(1, 0, 0, RAIL_H),
		ZIndex = 2,
		Parent = Inner,
	})
	local RailFade = S.create("UIGradient", {
		Transparency = NumberSequence.new(0),
		Parent = RailHolder,
	})
	local Rail = S.create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		ZIndex = 2,
		Parent = RailHolder,
	})
	self_.Rail = Rail
	local Strip = S.create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.fromOffset(0, RAIL_H),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 2,
		Parent = Rail,
	}, {
		S.padding(0, 14, 0, 0),
		S.list(2, true, { VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	self_.Strip = Strip
	local Glide = self:Image(Rail, "Glide", {
		Size = UDim2.fromOffset(80, 10),
		ZIndex = 3,
	})
	Glide.ScaleType = Enum.ScaleType.Stretch
	Glide.ImageTransparency = 1
	S.themed(Glide, { ImageColor3 = "Silver" })
	self_.Glide = Glide
	local function updateFade()
		local overflow = Rail.AbsoluteCanvasSize.X > Rail.AbsoluteSize.X + 2
		if not overflow then
			RailFade.Transparency = NumberSequence.new(0)
			return
		end
		local left = Rail.CanvasPosition.X > 2
		local right = Rail.CanvasPosition.X + Rail.AbsoluteSize.X < Rail.AbsoluteCanvasSize.X - 2
		RailFade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, left and 1 or 0),
			NumberSequenceKeypoint.new(0.06, 0),
			NumberSequenceKeypoint.new(0.94, 0),
			NumberSequenceKeypoint.new(1, right and 1 or 0),
		})
	end
	S.connect(Rail:GetPropertyChangedSignal("CanvasPosition"), updateFade)
	S.connect(Rail:GetPropertyChangedSignal("AbsoluteCanvasSize"), updateFade)
	S.connect(Rail:GetPropertyChangedSignal("AbsoluteSize"), updateFade)
	S.connect(Rail.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local maxX = math.max(Rail.AbsoluteCanvasSize.X - Rail.AbsoluteSize.X, 0)
			Rail.CanvasPosition = Vector2.new(math.clamp(Rail.CanvasPosition.X - input.Position.Z * 60, 0, maxX), 0)
		end
	end)

	S.create("Frame", {
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, TITLE_H + 1 + RAIL_H),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Border" },
		Parent = Inner,
	})

	local Pages = S.create("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, TITLE_H + RAIL_H + 2),
		Size = UDim2.new(1, 0, 1, -(TITLE_H + RAIL_H + 2)),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = Inner,
	})
	self_.Pages = Pages

	local Grip = S.create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.fromOffset(16, 16),
		ZIndex = 5,
		Parent = Main,
	})
	for i = 0, 2 do
		S.create("Frame", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -4 - i * 3, 1, -4),
			Size = UDim2.fromOffset(2, 2 + i * 3),
			BackgroundTransparency = 0.5,
			ZIndex = 5,
			Theme = { BackgroundColor3 = "Muted" },
			Parent = Grip,
		})
	end
	do
		local resizing, startPos, startSize
		S.connect(Grip.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true
				startPos = input.Position
				startSize = Main.AbsoluteSize / math.max(Scale.Scale, 0.1)
				local changed
				changed = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						resizing = false
						changed:Disconnect()
					end
				end)
			end
		end)
		S.connect(UserInputService.InputChanged, function(input)
			if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = (input.Position - startPos) / math.max(Scale.Scale, 0.1)
				Main.Size = UDim2.fromOffset(math.max(startSize.X + delta.X * 2, 520), math.max(startSize.Y + delta.Y * 2, 340))
			end
		end)
	end

	S.connect(SearchBtn.MouseButton1Click, function()
		if S.openSearch then
			S.openSearch()
		end
	end)
	S.connect(MinBtn.MouseButton1Click, function()
		self:Eclipse(true)
	end)
	local closeArmed = 0
	S.connect(CloseBtn.MouseButton1Click, function()
		if closeArmed % 2 == 1 then
			self:Unload()
			return
		end
		closeArmed += 1
		local mine = closeArmed
		S.tween(CloseGlyph, S.TweenFast, { ImageColor3 = Library.Theme.Danger })
		self:Notify("Saturn", "Click again to unload", 2.5)
		task.delay(2.5, function()
			if closeArmed ~= mine then
				return
			end
			closeArmed += 1
			if CloseGlyph.Parent then
				S.tween(CloseGlyph, S.TweenFast, { ImageColor3 = Library.Theme.Muted })
			end
		end)
	end)

	local lastToggle = 0
	S.connect(UserInputService.InputBegan, function(input)
		if S.Picking or S.typing() then
			return
		end
		if input.KeyCode == self.ToggleKey and input.KeyCode ~= Enum.KeyCode.Unknown then
			local now = os.clock()
			if now - lastToggle < 0.32 then
				lastToggle = 0
				self:Eclipse(true)
				return
			end
			lastToggle = now
			if S.Eclipsed then
				self:Eclipse(false)
			else
				self:Toggle()
			end
		end
	end)

	S.applyScale = function()
		Scale.Scale = self.Scale
	end
	return self_
end

function Library:Toggle(state)
	if state == nil then
		state = not self.Open
	end
	self.Open = state
	local Main = S.Window and S.Window.Main
	if not Main then
		return
	end
	local Scale = S.Window.ScaleObject
	if state then
		if S.Eclipsed then
			S.Eclipsed = false
			if S.hideOrb then
				S.hideOrb()
			end
		end
		Main.Visible = true
		Scale.Scale = self.Scale * 0.96
		S.tween(Scale, S.Tween, { Scale = self.Scale })
	else
		S.tween(Scale, S.TweenFast, { Scale = self.Scale * 0.96 })
		task.delay(0.1, function()
			if not self.Open then
				Main.Visible = false
				Scale.Scale = self.Scale
			end
		end)
	end
	if S.onToggle then
		S.onToggle(state)
	end
end

function Library:SetScale(scale)
	self.Scale = math.clamp(tonumber(scale) or 1, 0.5, 2)
	if S.applyScale then
		S.applyScale()
	end
end

function Library:SetStarfield(on)
	self.Starfield = on and true or false
	if S.Window and S.Window.Stars then
		S.Window.Stars.Visible = self.Starfield
	end
end

function Library:SetGame(text)
	if S.Window then
		S.Window.SubLabel.Text = tostring(text or "")
	end
end

function Window:SetTitle(text)
	self.TitleLabel.Text = tostring(text)
end

function Window:AddSection()
	local Sep = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(13, 24),
		LayoutOrder = #self.Tabs * 2 + 1,
		Parent = self.Strip,
	})
	S.create("Frame", {
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1, 18),
		Theme = { BackgroundColor3 = "BorderLight" },
		Parent = Sep,
	})
	return Sep
end

function Window:MoveGlide(tab, instant)
	local Glide = self.Glide
	if not tab then
		Glide.ImageTransparency = 1
		return
	end
	local button = tab.Button
	local scale = math.max(self.ScaleObject.Scale, 0.1)
	local x = (button.AbsolutePosition.X - self.Strip.AbsolutePosition.X) / scale + self.Strip.Position.X.Offset
	local w = button.AbsoluteSize.X / scale
	if w <= 0 then
		return
	end
	local target = {
		Position = UDim2.fromOffset(x - 4, RAIL_H - 13),
		Size = UDim2.fromOffset(w + 8, 10),
		ImageTransparency = 0,
	}
	if instant or Glide.ImageTransparency >= 1 then
		for k, v in pairs(target) do
			Glide[k] = v
		end
	else
		S.tween(Glide, S.TweenGlide, target)
	end
	local maxX = math.max(self.Rail.AbsoluteCanvasSize.X - self.Rail.AbsoluteSize.X, 0)
	local want = self.Rail.CanvasPosition.X
	local left, right = x * scale, (x + w) * scale
	if left < want + 20 then
		want = left - 20
	elseif right > want + self.Rail.AbsoluteSize.X - 20 then
		want = right - self.Rail.AbsoluteSize.X + 20
	end
	want = math.clamp(want, 0, maxX)
	if math.abs(want - self.Rail.CanvasPosition.X) > 1 then
		S.tween(self.Rail, S.TweenSmooth, { CanvasPosition = Vector2.new(want, 0) })
	end
end

function Window:SelectTab(tab)
	if type(tab) == "string" then
		for _, t in ipairs(self.Tabs) do
			if t.Name == tab then
				tab = t
				break
			end
		end
	end
	if type(tab) ~= "table" or self.Selected == tab then
		return
	end
	local previous = self.Selected
	self.Selected = tab
	for _, t in ipairs(self.Tabs) do
		local on = t == tab
		S.tween(t.Label, S.Tween, { TextColor3 = on and Library.Theme.Text or Library.Theme.Muted })
		S.tween(t.Glyph, S.Tween, { ImageColor3 = on and Library.Theme.Silver or Library.Theme.Muted })
		S.themed(t.Label, { TextColor3 = on and "Text" or "Muted" })
		S.themed(t.Glyph, { ImageColor3 = on and "Silver" or "Muted" })
	end
	if previous then
		previous.Page.Visible = false
	end
	tab.Page.Visible = true
	tab.Page.Position = UDim2.fromOffset(0, 10)
	S.tween(tab.Page, S.TweenSmooth, { Position = UDim2.new() })
	self:MoveGlide(tab)
end

function Window:AddTab(name, icon)
	local tab = setmetatable({ Name = name, Window = self, Groupboxes = {} }, Tab)
	local order = #self.Tabs * 2 + 2
	local Button = S.create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, RAIL_H),
		LayoutOrder = order,
		ZIndex = 2,
		Parent = self.Strip,
	}, {
		S.padding(0, 12, 0, 12),
		S.list(8, true, { VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	local Glyph = Library:Icon(Button, icon or "misc", 16, { LayoutOrder = 1, ZIndex = 2, Theme = { ImageColor3 = "Muted" } })
	local Label = S.label({
		Text = name,
		FontFace = S.FontSemi,
		TextSize = 13,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, RAIL_H),
		LayoutOrder = 2,
		ZIndex = 2,
		Theme = { TextColor3 = "Muted" },
		Parent = Button,
	})
	tab.Button, tab.Glyph, tab.Label = Button, Glyph, Label

	local Page = S.create("ScrollingFrame", {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.6,
		Visible = false,
		ZIndex = 2,
		Parent = self.Pages,
	}, { S.padding(14, 14, 14, 14) })
	S.themed(Page, { ScrollBarImageColor3 = "BorderLight" })
	local Columns = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
		Parent = Page,
	})
	local function column(x)
		return S.create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(x, x > 0 and 6 or 0, 0, 0),
			Size = UDim2.new(0.5, -6, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2,
			Parent = Columns,
		}, { S.list(12) })
	end
	tab.Page, tab.Left, tab.Right = Page, column(0), column(0.5)

	S.connect(Button.MouseEnter, function()
		if self.Selected ~= tab then
			S.tween(Label, S.TweenFast, { TextColor3 = Library.Theme.SubText })
			S.tween(Glyph, S.TweenFast, { ImageColor3 = Library.Theme.SubText })
		end
	end)
	S.connect(Button.MouseLeave, function()
		if self.Selected ~= tab then
			S.tween(Label, S.TweenFast, { TextColor3 = Library.Theme.Muted })
			S.tween(Glyph, S.TweenFast, { ImageColor3 = Library.Theme.Muted })
		end
	end)
	S.connect(Button.MouseButton1Click, function()
		self:SelectTab(tab)
	end)
	local function follow()
		if self.Selected == tab then
			self:MoveGlide(tab, true)
		end
	end
	S.connect(Button:GetPropertyChangedSignal("AbsoluteSize"), follow)
	S.connect(self.Strip:GetPropertyChangedSignal("AbsoluteSize"), follow)
	table.insert(self.Tabs, tab)
	if not self.Selected then
		task.defer(function()
			if not self.Selected then
				self:SelectTab(tab)
			end
		end)
	end
	return tab
end

function Tab:SetTitle(text)
	self.Name = tostring(text)
	self.Label.Text = self.Name
	if self.Window.Selected == self then
		task.defer(function()
			self.Window:MoveGlide(self, true)
		end)
	end
end

function Tab:SetIcon(icon)
	Library:SetIcon(self.Glyph, icon)
end

function Tab:Select()
	self.Window:SelectTab(self)
end
end
do
local Groupbox = {}
Groupbox.__index = Groupbox
S.GroupboxClass = Groupbox

local ROW_H = 30

local function nextOrder(box)
	box.Order += 1
	return box.Order
end

function S.makeGroupbox(tab, column, name)
	local box = setmetatable({ Tab = tab, Name = name, Order = 0 }, Groupbox)
	local Frame = S.create("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #tab.Groupboxes + 1,
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = column,
	}, { S.corner(11), S.stroke("Border"), S.padding(10, 12, 10, 12), S.list(2) })
	S.create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.15),
		}),
		Parent = Frame,
	})
	local Header = S.label({
		Text = string.upper(name),
		FontFace = S.FontSemi,
		TextSize = 11,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 0,
		ZIndex = 2,
		Theme = { TextColor3 = "SubText" },
		Parent = Frame,
	})
	pcall(function()
		Header.TextTransparency = 0.15
	end)
	box.Frame, box.Header = Frame, Header
	table.insert(tab.Groupboxes, box)
	return box
end

function S.TabClass:AddLeftGroupbox(name)
	return S.makeGroupbox(self, self.Left, name)
end

function S.TabClass:AddRightGroupbox(name)
	return S.makeGroupbox(self, self.Right, name)
end

function S.TabClass:AddGroupbox(name, side)
	return S.makeGroupbox(self, side == "Right" and self.Right or self.Left, name)
end

function S.row(box, height)
	return S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height or ROW_H),
		LayoutOrder = nextOrder(box),
		ZIndex = 2,
		Parent = box.Frame,
	})
end

function S.textBlock(parent, text, description, rightInset)
	local Holder = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(rightInset or 0), 1, 0),
		ZIndex = 2,
		Parent = parent,
	}, { S.list(1, false, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local Label = S.label({
		Text = text,
		TextSize = 13,
		Size = UDim2.new(1, 0, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		ZIndex = 2,
		Theme = { TextColor3 = "SubText" },
		Parent = Holder,
	})
	local Desc
	if description and description ~= "" then
		Desc = S.label({
			Text = description,
			TextSize = 11,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			ZIndex = 2,
			Theme = { TextColor3 = "Muted" },
			Parent = Holder,
		})
		parent.AutomaticSize = Enum.AutomaticSize.Y
		Holder.AutomaticSize = Enum.AutomaticSize.Y
		Holder:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Top
		Holder.Size = UDim2.new(1, -(rightInset or 0), 0, 0)
		parent.Size = UDim2.new(1, 0, 0, 0)
		S.create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = parent })
	end
	return Label, Desc, Holder
end

function S.register(id, option, kind)
	option.Type = kind
	option.Id = id
	option.Changed = option.Changed or {}
	if id ~= nil then
		Library.Options[id] = option
		if kind == "Toggle" then
			Library.Toggles[id] = option
		end
	end
	return option
end

function S.fire(option)
	S.safe(option.Callback, option.Value)
	for _, fn in ipairs(option.Changed) do
		S.safe(fn, option.Value)
	end
end

local OptionBase = {}
function OptionBase:OnChanged(fn)
	table.insert(self.Changed, fn)
	return self
end
S.OptionBase = OptionBase

function S.index(box, text, target, extra)
	table.insert(S.SearchIndex, {
		Text = tostring(text or ""),
		Extra = extra and tostring(extra) or "",
		Tab = box.Tab,
		Box = box,
		Target = target,
	})
end

function Groupbox:AddDivider()
	local Row = S.row(self, 9)
	S.create("Frame", {
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Border" },
		Parent = Row,
	})
	return Row
end

function Groupbox:AddLabel(text, wrap)
	local Row = S.row(self, 22)
	local Label = S.label({
		Text = tostring(text or ""),
		TextSize = 12.5,
		TextWrapped = wrap ~= false,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
		Theme = { TextColor3 = "Muted" },
		Parent = Row,
	})
	Row.Size = UDim2.new(1, 0, 0, 0)
	Row.AutomaticSize = Enum.AutomaticSize.Y
	S.create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = Row })
	local object = { Row = Row, Label = Label }
	function object:SetText(value)
		Label.Text = tostring(value)
	end
	function object:SetVisible(on)
		Row.Visible = on
	end
	return object
end

local function silverFill(parent)
	return S.create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("f4f5f7")),
			ColorSequenceKeypoint.new(0.55, Color3.fromHex("c4c7cd")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("e6e8ec")),
		}),
		Parent = parent,
	})
end
S.silverFill = silverFill

function S.button(parent, text, props)
	local base = {
		Text = text,
		AutoButtonColor = false,
		FontFace = S.FontSemi,
		TextSize = 12.5,
		Size = UDim2.new(1, 0, 0, 30),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Field", TextColor3 = "Text" },
		Parent = parent,
	}
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	local Button = S.create("TextButton", base, { S.corner(8), S.stroke("BorderLight") })
	S.create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.25),
		}),
		Parent = Button,
	})
	S.connect(Button.MouseEnter, function()
		S.tween(Button, S.TweenFast, { BackgroundColor3 = Library.Theme.FieldHover })
	end)
	S.connect(Button.MouseLeave, function()
		S.tween(Button, S.TweenFast, { BackgroundColor3 = Library.Theme.Field })
	end)
	return Button
end

function Groupbox:AddButton(a, b)
	local options = type(a) == "table" and a or { Text = a, Func = b }
	local text = options.Text or "Button"
	local func = options.Func or options.Callback
	local Row
	local Button
	if options.Label then
		Row = S.row(self, ROW_H + 2)
		local width = math.max(S.textWidth(text, 12.5, S.FontSemi) + 24, 64)
		S.textBlock(Row, options.Label, options.Description, width + 10)
		Button = S.button(Row, text, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(width, 26),
		})
		S.index(self, options.Label, Row, text)
	else
		Row = S.row(self, 36)
		Button = S.button(Row, text, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(1, 0, 0, 30),
		})
		S.index(self, text, Row)
	end
	local object = { Row = Row, Button = Button, Func = func }
	local armed = 0
	S.connect(Button.MouseButton1Click, function()
		if options.DoubleClick then
			if armed % 2 == 0 then
				armed += 1
				local mine = armed
				Button.Text = "Confirm?"
				task.delay(2, function()
					if armed == mine then
						armed += 1
						if Button.Parent then
							Button.Text = text
						end
					end
				end)
				return
			end
			armed += 1
			Button.Text = text
		end
		S.tween(Button, S.TweenFast, { BackgroundColor3 = Library.Theme.BorderLight })
		task.delay(0.12, function()
			S.tween(Button, S.Tween, { BackgroundColor3 = Library.Theme.Field })
		end)
		S.safe(object.Func)
	end)
	function object:SetText(value)
		text = tostring(value)
		Button.Text = text
	end
	function object:SetVisible(on)
		Row.Visible = on
	end
	return object
end

function Groupbox:AddToggle(id, options)
	options = options or {}
	local Row = S.row(self, ROW_H)
	local Hit = S.create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = Row,
	})
	local Label, _, TextHolder = S.textBlock(Row, options.Text or tostring(id), options.Description, 48)
	local Right = S.create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 3,
		Parent = Row,
	}, { S.list(6, true, { HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center }) })
	S.connect(Right:GetPropertyChangedSignal("AbsoluteSize"), function()
		local scale = S.Window and math.max(S.Window.ScaleObject.Scale, 0.1) or 1
		local inset = math.max(Right.AbsoluteSize.X / scale, 32) + 14
		TextHolder.Size = UDim2.new(1, -inset, TextHolder.Size.Y.Scale, TextHolder.Size.Y.Offset)
	end)
	local Switch = S.create("Frame", {
		Size = UDim2.fromOffset(32, 18),
		LayoutOrder = 100,
		ZIndex = 3,
		Theme = { BackgroundColor3 = "Off" },
		Parent = Right,
	}, { S.corner(9) })
	local SwitchStroke = S.stroke("BorderLight")
	SwitchStroke.Parent = Switch
	local Fill = S.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 3,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Switch,
	}, { S.corner(9) })
	silverFill(Fill)
	local Knob = S.create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		ZIndex = 4,
		Theme = { BackgroundColor3 = "Knob" },
		Parent = Switch,
	}, { S.corner(6) })

	local toggle = setmetatable({
		Value = options.Default == true,
		Text = options.Text or tostring(id),
		Callback = options.Callback,
		Row = Row,
		Right = Right,
		Groupbox = self,
		Addons = {},
		Orbit = options.Orbit,
	}, { __index = OptionBase })
	S.register(id, toggle, "Toggle")

	local function display(instant)
		local on = toggle.Value
		local info = instant and TweenInfo.new(0) or S.Tween
		S.tween(Fill, info, { BackgroundTransparency = on and 0 or 1 })
		S.tween(Knob, info, {
			Position = on and UDim2.new(0, 17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = on and Library.Theme.KnobOn or Library.Theme.Knob,
		})
		S.tween(SwitchStroke, info, { Transparency = on and 1 or 0 })
		S.tween(Label, info, { TextColor3 = on and Library.Theme.Text or Library.Theme.SubText })
		S.Themed[Knob] = { BackgroundColor3 = on and "KnobOn" or "Knob" }
		S.Themed[Label] = { TextColor3 = on and "Text" or "SubText" }
	end

	function toggle:SetValue(value)
		value = value and true or false
		if self.Value == value then
			display(true)
			return
		end
		self.Value = value
		display(false)
		if S.orbitChanged then
			S.orbitChanged(self)
		end
		S.fire(self)
	end
	function toggle:SetText(text)
		self.Text = tostring(text)
		Label.Text = self.Text
	end
	function toggle:SetVisible(on)
		Row.Visible = on
	end
	S.connect(Hit.MouseButton1Click, function()
		toggle:SetValue(not toggle.Value)
	end)
	S.connect(Hit.MouseEnter, function()
		if not toggle.Value then
			S.tween(Label, S.TweenFast, { TextColor3 = Library.Theme.Text })
		end
	end)
	S.connect(Hit.MouseLeave, function()
		if not toggle.Value then
			S.tween(Label, S.TweenFast, { TextColor3 = Library.Theme.SubText })
		end
	end)
	display(true)
	if toggle.Value and S.orbitChanged then
		task.defer(S.orbitChanged, toggle)
	end
	function toggle:AddKeybind(keyId, keyOptions)
		keyOptions = keyOptions or {}
		keyOptions.Parent = Right
		keyOptions.Toggle = self
		keyOptions.Text = keyOptions.Text or self.Text
		local bind = S.makeKeybind(self.Groupbox, keyId, keyOptions)
		table.insert(self.Addons, bind)
		return self
	end
	function toggle:AddColorPicker(colorId, colorOptions)
		colorOptions = colorOptions or {}
		colorOptions.Parent = Right
		colorOptions.Title = colorOptions.Title or self.Text
		local picker = S.makeColorPicker(self.Groupbox, colorId, colorOptions)
		table.insert(self.Addons, picker)
		return self
	end
	S.index(self, toggle.Text, Row, options.Description)
	return toggle
end

function Groupbox:AddSlider(id, options)
	options = options or {}
	local min, max = tonumber(options.Min) or 0, tonumber(options.Max) or 100
	local rounding = tonumber(options.Rounding) or 0
	local suffix = options.Suffix or ""
	local Row = S.row(self, 44)
	local Top = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		ZIndex = 2,
		Parent = Row,
	})
	local Label = S.label({
		Text = options.Text or tostring(id),
		TextSize = 13,
		Size = UDim2.new(1, -90, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Theme = { TextColor3 = "SubText" },
		Parent = Top,
	})
	local ValueBox = S.create("TextBox", {
		Text = "",
		ClearTextOnFocus = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 86, 1, 0),
		FontFace = S.FontSemi,
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 2,
		Theme = { TextColor3 = "Text" },
		Parent = Top,
	})
	local Bar = S.create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 5),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Off" },
		Parent = Row,
	}, { S.corner(3) })
	local Fill = S.create("Frame", {
		Size = UDim2.fromScale(0, 1),
		ZIndex = 3,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Bar,
	}, { S.corner(3) })
	S.create("UIGradient", {
		Color = ColorSequence.new(Color3.fromHex("8d9199"), Color3.fromHex("f1f2f5")),
		Parent = Fill,
	})
	local Thumb = S.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(11, 11),
		ZIndex = 4,
		BackgroundTransparency = 1,
		Theme = { BackgroundColor3 = "Silver" },
		Parent = Bar,
	}, { S.corner(6) })

	local slider = setmetatable({
		Value = math.clamp(tonumber(options.Default) or min, min, max),
		Min = min,
		Max = max,
		Callback = options.Callback,
		Row = Row,
	}, { __index = OptionBase })
	S.register(id, slider, "Slider")

	local function round(v)
		if rounding <= 0 then
			return math.floor(v + 0.5)
		end
		local m = 10 ^ rounding
		return math.floor(v * m + 0.5) / m
	end
	local function display(instant)
		local alpha = (max > min) and (slider.Value - min) / (max - min) or 0
		local info = instant and TweenInfo.new(0) or S.TweenFast
		S.tween(Fill, info, { Size = UDim2.fromScale(alpha, 1) })
		S.tween(Thumb, info, { Position = UDim2.fromScale(alpha, 0.5) })
		if not ValueBox:IsFocused() then
			local text = rounding > 0 and string.format("%." .. rounding .. "f", slider.Value) or tostring(slider.Value)
			ValueBox.Text = text .. suffix
		end
	end
	function slider:SetValue(value)
		value = round(math.clamp(tonumber(value) or self.Value, self.Min, self.Max))
		if value == self.Value then
			display(true)
			return
		end
		self.Value = value
		display(false)
		S.fire(self)
	end
	function slider:SetMin(v)
		self.Min = tonumber(v) or self.Min
		min = self.Min
		self:SetValue(self.Value)
	end
	function slider:SetMax(v)
		self.Max = tonumber(v) or self.Max
		max = self.Max
		self:SetValue(self.Value)
	end
	function slider:SetText(text)
		Label.Text = tostring(text)
	end
	function slider:SetVisible(on)
		Row.Visible = on
	end
	local dragging = nil
	local function fromInput(input)
		local x = (input.Position.X - Bar.AbsolutePosition.X) / math.max(Bar.AbsoluteSize.X, 1)
		slider:SetValue(min + math.clamp(x, 0, 1) * (max - min))
	end
	S.connect(Bar.InputBegan, function(input)
		if S.isPress(input) and not dragging then
			dragging = input
			slider.Holding = true
			S.tween(Thumb, S.TweenFast, { BackgroundTransparency = 0 })
			fromInput(input)
		end
	end)
	S.connect(UserInputService.InputChanged, function(input)
		if dragging and S.isMove(input, dragging) then
			fromInput(input)
		end
	end)
	S.connect(UserInputService.InputEnded, function(input)
		if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1 and dragging.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = nil
			slider.Holding = false
			S.tween(Thumb, S.TweenFast, { BackgroundTransparency = 1 })
			if slider.OnRelease then
				S.safe(slider.OnRelease, slider.Value)
			end
		end
	end)
	S.connect(Row.MouseEnter, function()
		S.tween(Thumb, S.TweenFast, { BackgroundTransparency = 0 })
	end)
	S.connect(Row.MouseLeave, function()
		if not dragging then
			S.tween(Thumb, S.TweenFast, { BackgroundTransparency = 1 })
		end
	end)
	S.connect(ValueBox.Focused, function()
		ValueBox.Text = tostring(slider.Value)
	end)
	S.connect(ValueBox.FocusLost, function()
		local typed = tonumber((ValueBox.Text:gsub("[^%d%.%-]", "")))
		if typed then
			slider:SetValue(typed)
		end
		display(true)
	end)
	display(true)
	S.index(self, Label.Text, Row, options.Description)
	return slider
end

function Groupbox:AddInput(id, options)
	options = options or {}
	local Row = S.row(self, ROW_H + 2)
	S.textBlock(Row, options.Text or tostring(id), options.Description, 160)
	local Field = S.create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 26),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Row,
	}, { S.corner(7), S.stroke("BorderLight") })
	local Box = S.create("TextBox", {
		Text = tostring(options.Default or ""),
		PlaceholderText = options.Placeholder or "",
		ClearTextOnFocus = options.ClearTextOnFocus == true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		FontFace = S.Font,
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
		ZIndex = 2,
		Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
		Parent = Field,
	})
	local input = setmetatable({
		Value = Box.Text,
		Callback = options.Callback,
		Row = Row,
	}, { __index = OptionBase })
	S.register(id, input, "Input")
	local function accept(text)
		if options.Numeric then
			text = text:gsub("[^%d%.%-]", "")
		end
		if options.MaxLength then
			text = text:sub(1, options.MaxLength)
		end
		return text
	end
	function input:SetValue(text)
		text = accept(tostring(text or ""))
		Box.Text = text
		if text == self.Value then
			return
		end
		self.Value = text
		S.fire(self)
	end
	function input:SetVisible(on)
		Row.Visible = on
	end
	local Stroke = Field:FindFirstChildOfClass("UIStroke")
	S.connect(Box.Focused, function()
		S.tween(Stroke, S.TweenFast, { Color = Library.Theme.SilverDim })
	end)
	S.connect(Box.FocusLost, function(enter)
		S.tween(Stroke, S.TweenFast, { Color = Library.Theme.BorderLight })
		if options.Finished == false or enter or options.Finished == nil then
			input:SetValue(Box.Text)
		end
	end)
	if options.Finished == false then
		S.connect(Box:GetPropertyChangedSignal("Text"), function()
			if Box:IsFocused() then
				input:SetValue(Box.Text)
			end
		end)
	end
	S.index(self, options.Text or tostring(id), Row, options.Description)
	return input
end
end
do
local Groupbox = S.GroupboxClass
local OptionBase = S.OptionBase

local Blocker = S.create("TextButton", {
	Name = "Blocker",
	Text = "",
	AutoButtonColor = false,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 50,
	Parent = S.Overlay,
})
S.Blocker = Blocker
local openPopup

function S.closePopup()
	if openPopup then
		local popup = openPopup
		openPopup = nil
		Blocker.Visible = false
		if popup.OnClose then
			pcall(popup.OnClose)
		end
		popup.Frame.Visible = false
	end
end

S.connect(Blocker.MouseButton1Click, S.closePopup)

function S.setOpenPopup(popup)
	openPopup = popup
end

function S.openPopup(popup, anchor, width, height)
	S.closePopup()
	openPopup = popup
	local frame = popup.Frame
	local scale = S.Window and S.Window.ScaleObject.Scale or 1
	local camera = Workspace.CurrentCamera
	local view = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local pos = S.screenPos(anchor)
	local size = anchor.AbsoluteSize
	local w = (width or size.X / scale)
	local x = pos.X + size.X - w * scale
	local y = pos.Y + size.Y + 6
	if y + height * scale > view.Y - 8 then
		y = math.max(pos.Y - 6 - height * scale, 8)
	end
	x = math.clamp(x, 8, math.max(view.X - w * scale - 8, 8))
	frame.Position = UDim2.fromOffset(x, y)
	frame.Size = UDim2.fromOffset(w, height)
	local popupScale = frame:FindFirstChildOfClass("UIScale")
	if popupScale then
		popupScale.Scale = scale * 0.96
		S.tween(popupScale, S.Tween, { Scale = scale })
	end
	frame.Visible = true
	Blocker.Visible = true
end

function S.popupFrame()
	local frame = S.create("Frame", {
		Visible = false,
		ZIndex = 60,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = S.Overlay,
	}, { S.corner(10), S.stroke("BorderLight"), S.create("UIScale", { Scale = 1 }) })
	return frame
end

function Groupbox:AddDropdown(id, options)
	options = options or {}
	local multi = options.Multi == true
	local Row = S.row(self, 32)
	S.textBlock(Row, options.Text or tostring(id), options.Description, 170)
	local Field = S.create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 26),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Row,
	}, { S.corner(7), S.stroke("BorderLight") })
	local Shown = S.label({
		Text = "",
		TextSize = 12.5,
		FontFace = S.FontSemi,
		Position = UDim2.fromOffset(9, 0),
		Size = UDim2.new(1, -30, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Theme = { TextColor3 = "Text" },
		Parent = Field,
	})
	local Chevron = Library:Icon(Field, "chevron", 12, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Rotation = 90,
		ZIndex = 2,
		Theme = { ImageColor3 = "Muted" },
	})

	local dropdown = setmetatable({
		Values = options.Values or {},
		Multi = multi,
		Callback = options.Callback,
		Row = Row,
		AllowNull = options.AllowNull == true,
	}, { __index = OptionBase })
	if multi then
		dropdown.Value = {}
		local default = options.Default
		if type(default) == "table" then
			for k, v in pairs(default) do
				if type(k) == "number" then
					dropdown.Value[v] = true
				elseif v then
					dropdown.Value[k] = true
				end
			end
		elseif default ~= nil then
			dropdown.Value[default] = true
		end
	else
		local default = options.Default
		if type(default) == "number" and dropdown.Values[default] ~= nil then
			default = dropdown.Values[default]
		end
		dropdown.Value = default
		if dropdown.Value == nil and not dropdown.AllowNull then
			dropdown.Value = dropdown.Values[1]
		end
	end
	S.register(id, dropdown, "Dropdown")

	local function summary()
		if multi then
			local picked = {}
			for _, v in ipairs(dropdown.Values) do
				if dropdown.Value[v] then
					table.insert(picked, tostring(v))
				end
			end
			if #picked == 0 then
				return "None", true
			end
			return table.concat(picked, ", "), false
		end
		if dropdown.Value == nil then
			return options.Placeholder or "None", true
		end
		return tostring(dropdown.Value), false
	end
	local function display()
		local text, empty = summary()
		Shown.Text = text
		S.themed(Shown, { TextColor3 = empty and "Muted" or "Text" })
	end

	local Popup = { Frame = S.popupFrame() }
	dropdown.Field, dropdown.Popup = Field, Popup
	local List
	local SearchBox
	local itemButtons = {}
	local function buildList(filter)
		for _, b in ipairs(itemButtons) do
			b:Destroy()
		end
		table.clear(itemButtons)
		filter = filter and filter:lower() or ""
		for index, value in ipairs(dropdown.Values) do
			local text = tostring(value)
			if filter == "" or text:lower():find(filter, 1, true) then
				local picked = multi and dropdown.Value[value] or (not multi and dropdown.Value == value)
				local Item = S.create("TextButton", {
					Text = "",
					AutoButtonColor = false,
					BackgroundTransparency = picked and 0 or 1,
					Size = UDim2.new(1, 0, 0, 28),
					LayoutOrder = index,
					ZIndex = 62,
					Theme = { BackgroundColor3 = "Field" },
					Parent = List,
				}, { S.corner(6) })
				S.label({
					Text = text,
					TextSize = 12.5,
					FontFace = picked and S.FontSemi or S.Font,
					Position = UDim2.fromOffset(10, 0),
					Size = UDim2.new(1, -36, 1, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 62,
					Theme = { TextColor3 = picked and "Text" or "SubText" },
					Parent = Item,
				})
				if picked then
					Library:Icon(Item, "check", 13, {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -9, 0.5, 0),
						ZIndex = 62,
						Theme = { ImageColor3 = "Silver" },
					})
				end
				S.bind(Item.MouseEnter, function()
					if not (multi and dropdown.Value[value] or dropdown.Value == value) then
						S.tween(Item, S.TweenFast, { BackgroundTransparency = 0.5 })
					end
				end)
				S.bind(Item.MouseLeave, function()
					if not (multi and dropdown.Value[value] or dropdown.Value == value) then
						S.tween(Item, S.TweenFast, { BackgroundTransparency = 1 })
					end
				end)
				S.bind(Item.MouseButton1Click, function()
					if multi then
						dropdown.Value[value] = not dropdown.Value[value] or nil
						display()
						buildList(SearchBox and SearchBox.Text or "")
						S.fire(dropdown)
					else
						if dropdown.Value == value and dropdown.AllowNull then
							dropdown.Value = nil
						else
							dropdown.Value = value
						end
						display()
						S.closePopup()
						S.fire(dropdown)
					end
				end)
				table.insert(itemButtons, Item)
			end
		end
	end
	do
		local frame = Popup.Frame
		local searchable = options.Searchable or #dropdown.Values > 8
		local top = 6
		if searchable then
			local SearchField = S.create("Frame", {
				Position = UDim2.fromOffset(6, 6),
				Size = UDim2.new(1, -12, 0, 28),
				ZIndex = 61,
				Theme = { BackgroundColor3 = "Field" },
				Parent = frame,
			}, { S.corner(7), S.stroke("Border") })
			Library:Icon(SearchField, "search", 13, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 9, 0.5, 0),
				ZIndex = 61,
				Theme = { ImageColor3 = "Muted" },
			})
			SearchBox = S.create("TextBox", {
				Text = "",
				PlaceholderText = "Search",
				ClearTextOnFocus = false,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(28, 0),
				Size = UDim2.new(1, -34, 1, 0),
				FontFace = S.Font,
				TextSize = 12.5,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 61,
				Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
				Parent = SearchField,
			})
			S.connect(SearchBox:GetPropertyChangedSignal("Text"), function()
				buildList(SearchBox.Text)
			end)
			top = 40
		end
		List = S.create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(6, top),
			Size = UDim2.new(1, -12, 1, -(top + 6)),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2,
			ZIndex = 61,
			Parent = frame,
		}, { S.list(2) })
		S.themed(List, { ScrollBarImageColor3 = "BorderLight" })
		Popup.Top = top
	end
	Popup.OnClose = function()
		S.tween(Chevron, S.TweenFast, { Rotation = 90 })
	end
	S.connect(Field.MouseButton1Click, function()
		if Popup.Frame.Visible then
			S.closePopup()
			return
		end
		if SearchBox then
			SearchBox.Text = ""
		end
		buildList("")
		local count = math.min(#dropdown.Values, 8)
		local height = Popup.Top + math.max(count, 1) * 30 + 6
		local scale = S.Window and S.Window.ScaleObject.Scale or 1
		S.openPopup(Popup, Field, math.max(Field.AbsoluteSize.X / scale, 180), height)
		S.tween(Chevron, S.TweenFast, { Rotation = -90 })
	end)

	function dropdown:SetValue(value)
		if multi then
			local set = {}
			if type(value) == "table" then
				for k, v in pairs(value) do
					if type(k) == "number" then
						set[v] = true
					elseif v then
						set[k] = true
					end
				end
			end
			self.Value = set
		else
			if value == nil and not self.AllowNull then
				value = self.Values[1]
			end
			self.Value = value
		end
		display()
		S.fire(self)
	end
	function dropdown:SetValues(values)
		self.Values = values or {}
		if not multi then
			if self.Value ~= nil and not table.find(self.Values, self.Value) then
				self.Value = (not self.AllowNull) and self.Values[1] or nil
			elseif self.Value == nil and not self.AllowNull then
				self.Value = self.Values[1]
			end
		end
		display()
	end
	function dropdown:AddValues(values)
		for _, v in ipairs(type(values) == "table" and values or { values }) do
			table.insert(self.Values, v)
		end
		display()
	end
	function dropdown:SetVisible(on)
		Row.Visible = on
	end
	display()
	S.index(self, options.Text or tostring(id), Row, table.concat((function()
		local t = {}
		for i, v in ipairs(dropdown.Values) do
			if i > 30 then
				break
			end
			t[i] = tostring(v)
		end
		return t
	end)(), " "))
	return dropdown
end

local KEY_NAMES = {
	MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3",
	LeftControl = "LCtrl", RightControl = "RCtrl", LeftShift = "LShift", RightShift = "RShift",
	LeftAlt = "LAlt", RightAlt = "RAlt", Return = "Enter", Backspace = "Back",
}
S.KeybindList = {}
S.Picking = false

local function keyFromInput(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return input.KeyCode.Name
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2
		or input.UserInputType == Enum.UserInputType.MouseButton3 then
		return input.UserInputType.Name
	end
	return nil
end

function S.makeKeybind(box, id, options)
	options = options or {}
	local Chip = S.create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		LayoutOrder = 10,
		FontFace = S.FontMono,
		TextSize = 11,
		ZIndex = 3,
		Theme = { BackgroundColor3 = "Field", TextColor3 = "SubText" },
		Parent = options.Parent,
	}, { S.corner(5), S.stroke("BorderLight"), S.padding(0, 7, 0, 7) })
	local bind = setmetatable({
		Value = options.Default or "None",
		Mode = options.Mode or "Toggle",
		Toggle = options.Toggle,
		Callback = options.Callback,
		Text = options.Text or tostring(id),
		Chip = Chip,
		State = false,
	}, { __index = OptionBase })
	S.register(id, bind, "KeyPicker")
	bind.Chip = Chip
	if type(bind.Value) ~= "string" then
		bind.Value = typeof(bind.Value) == "EnumItem" and bind.Value.Name or "None"
	end
	local function display()
		local name = bind.Value
		Chip.Text = name == "None" and "—" or (KEY_NAMES[name] or name)
	end
	function bind:SetValue(value)
		if typeof(value) == "EnumItem" then
			self.Value = value.Name
		elseif type(value) == "table" then
			local first = value[1]
			self.Value = typeof(first) == "EnumItem" and first.Name or tostring(first or "None")
			self.Mode = value[2] or self.Mode
		else
			self.Value = tostring(value or "None")
		end
		display()
		for _, fn in ipairs(self.Changed) do
			S.safe(fn, self.Value)
		end
		if S.refreshKeybindList then
			S.refreshKeybindList()
		end
	end
	function bind:GetState()
		if self.Mode == "Always" then
			return true
		end
		if self.Mode == "Hold" then
			if self.Value == "None" then
				return false
			end
			local ok, held = pcall(function()
				if self.Value:sub(1, 11) == "MouseButton" then
					return UserInputService:IsMouseButtonPressed(Enum.UserInputType[self.Value])
				end
				return UserInputService:IsKeyDown(Enum.KeyCode[self.Value])
			end)
			return ok and held or false
		end
		return self.Toggle and self.Toggle.Value or self.State
	end
	function bind:OnClick(fn)
		self.Clicked = fn
		return self
	end
	local picking = false
	local pickConn
	local function finishPicking(key)
		if pickConn then
			pickConn:Disconnect()
			pickConn = nil
		end
		task.defer(function()
			picking = false
			S.Picking = false
		end)
		S.tween(Chip:FindFirstChildOfClass("UIStroke"), S.TweenFast, { Color = Library.Theme.BorderLight })
		if key then
			bind:SetValue(key)
		else
			display()
		end
	end
	table.insert(S.UnloadCallbacks, function()
		if pickConn then
			pickConn:Disconnect()
			pickConn = nil
		end
		S.Picking = false
	end)
	S.connect(Chip.MouseButton1Click, function()
		if picking then
			return
		end
		picking = true
		S.Picking = true
		Chip.Text = "..."
		S.tween(Chip:FindFirstChildOfClass("UIStroke"), S.TweenFast, { Color = Library.Theme.SilverDim })
		pickConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				task.defer(function()
					if pickConn then
						finishPicking(nil)
					end
				end)
				return
			end
			local key = keyFromInput(input)
			if not key then
				return
			end
			if key == "Escape" or key == "Backspace" then
				key = "None"
			end
			finishPicking(key)
		end)
	end)
	S.connect(Chip.MouseButton2Click, function()
		local modes = { "Toggle", "Hold", "Always" }
		local i = table.find(modes, bind.Mode) or 1
		bind.Mode = modes[i % #modes + 1]
		Library:Notify("Keybind", bind.Text .. ": " .. bind.Mode .. " mode", 2)
		if S.refreshKeybindList then
			S.refreshKeybindList()
		end
	end)
	S.connect(UserInputService.InputBegan, function(input)
		if picking or S.Picking or bind.Value == "None" or S.typing() then
			return
		end
		local key = keyFromInput(input)
		if key ~= bind.Value then
			return
		end
		if bind.Mode == "Toggle" then
			if bind.Toggle then
				bind.Toggle:SetValue(not bind.Toggle.Value)
			else
				bind.State = not bind.State
			end
		elseif bind.Mode == "Hold" and bind.Toggle then
			bind.Toggle:SetValue(true)
		end
		S.safe(bind.Callback, bind:GetState())
		S.safe(bind.Clicked)
		if S.refreshKeybindList then
			S.refreshKeybindList()
		end
	end)
	S.connect(UserInputService.InputEnded, function(input)
		if bind.Mode ~= "Hold" or bind.Value == "None" then
			return
		end
		if keyFromInput(input) == bind.Value and bind.Toggle then
			bind.Toggle:SetValue(false)
			if S.refreshKeybindList then
				S.refreshKeybindList()
			end
		end
	end)
	display()
	table.insert(S.KeybindList, bind)
	return bind
end

function Groupbox:AddKeybind(id, options)
	options = options or {}
	local Row = S.row(self, 30)
	S.textBlock(Row, options.Text or tostring(id), options.Description, 90)
	local Right = S.create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 3,
		Parent = Row,
	}, { S.list(6, true, { HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center }) })
	options.Parent = Right
	local bind = S.makeKeybind(self, id, options)
	bind.Row = Row
	function bind:SetVisible(on)
		Row.Visible = on
	end
	S.index(self, options.Text or tostring(id), Row, options.Description)
	return bind
end

local function hsvToColor(h, s, v)
	return Color3.fromHSV(math.clamp(h, 0, 1), math.clamp(s, 0, 1), math.clamp(v, 0, 1))
end

function S.makeColorPicker(box, id, options)
	options = options or {}
	local Swatch = S.create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(26, 18),
		LayoutOrder = 20,
		ZIndex = 3,
		BackgroundColor3 = options.Default or Color3.new(1, 1, 1),
		Parent = options.Parent,
	}, { S.corner(5), S.stroke("BorderLight") })
	local picker = setmetatable({
		Value = options.Default or Color3.new(1, 1, 1),
		Transparency = options.Transparency or 0,
		Callback = options.Callback,
		Swatch = Swatch,
	}, { __index = OptionBase })
	S.register(id, picker, "ColorPicker")
	local h, s, v = picker.Value:ToHSV()

	local Popup = { Frame = S.popupFrame() }
	picker.Swatch, picker.Popup = Swatch, Popup
	local frame = Popup.Frame
	S.label({
		Text = options.Title or "Color",
		FontFace = S.FontSemi,
		TextSize = 12.5,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -20, 0, 20),
		ZIndex = 61,
		Theme = { TextColor3 = "Text" },
		Parent = frame,
	})
	local Square = S.create("ImageButton", {
		AutoButtonColor = false,
		Image = "",
		Position = UDim2.fromOffset(10, 32),
		Size = UDim2.new(1, -46, 0, 140),
		ZIndex = 61,
		BackgroundColor3 = hsvToColor(h, 1, 1),
		Parent = frame,
	}, { S.corner(6) })
	local White = S.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 62,
		Parent = Square,
	}, { S.corner(6) })
	S.create("UIGradient", {
		Transparency = NumberSequence.new(0, 1),
		Parent = White,
	})
	local Black = S.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		ZIndex = 63,
		Parent = Square,
	}, { S.corner(6) })
	S.create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new(1, 0),
		Parent = Black,
	})
	local Cursor = S.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		ZIndex = 64,
		Parent = Square,
	}, { S.corner(5), S.create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) })
	local Hue = S.create("ImageButton", {
		AutoButtonColor = false,
		Image = "",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 32),
		Size = UDim2.fromOffset(14, 140),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 61,
		Parent = frame,
	}, { S.corner(5) })
	local keys = {}
	for i = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
	end
	S.create("UIGradient", { Rotation = 90, Color = ColorSequence.new(keys), Parent = Hue })
	local HueCursor = S.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, h),
		Size = UDim2.new(1, 4, 0, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 62,
		Parent = Hue,
	}, { S.corner(2) })
	local HexField = S.create("Frame", {
		Position = UDim2.fromOffset(10, 180),
		Size = UDim2.new(1, -20, 0, 26),
		ZIndex = 61,
		Theme = { BackgroundColor3 = "Field" },
		Parent = frame,
	}, { S.corner(6), S.stroke("BorderLight") })
	local Hex = S.create("TextBox", {
		Text = "",
		ClearTextOnFocus = false,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -16, 1, 0),
		FontFace = S.FontMono,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 61,
		Theme = { TextColor3 = "Text" },
		Parent = HexField,
	})

	local function display()
		Swatch.BackgroundColor3 = picker.Value
		Square.BackgroundColor3 = hsvToColor(h, 1, 1)
		Cursor.Position = UDim2.fromScale(s, 1 - v)
		HueCursor.Position = UDim2.fromScale(0.5, h)
		if not Hex:IsFocused() then
			Hex.Text = "#" .. picker.Value:ToHex():upper()
		end
	end
	local function commit()
		picker.Value = hsvToColor(h, s, v)
		display()
		S.fire(picker)
	end
	function picker:SetValueRGB(color, transparency)
		self.Value = color
		if transparency then
			self.Transparency = transparency
		end
		h, s, v = color:ToHSV()
		display()
		S.fire(self)
	end
	function picker:SetValue(hsv, transparency)
		if typeof(hsv) == "Color3" then
			return self:SetValueRGB(hsv, transparency)
		end
		if type(hsv) == "table" then
			h, s, v = hsv[1] or h, hsv[2] or s, hsv[3] or v
		end
		if transparency then
			self.Transparency = transparency
		end
		commit()
	end
	local dragSquare, dragHue = nil, nil
	local function fromSquare(input)
		local rel = (Vector2.new(input.Position.X, input.Position.Y) - Square.AbsolutePosition) / Square.AbsoluteSize
		s, v = math.clamp(rel.X, 0, 1), 1 - math.clamp(rel.Y, 0, 1)
		commit()
	end
	local function fromHue(input)
		h = math.clamp((input.Position.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y, 0, 1)
		commit()
	end
	S.connect(Square.InputBegan, function(input)
		if S.isPress(input) and not dragHue then
			dragSquare = input
			fromSquare(input)
		end
	end)
	S.connect(Hue.InputBegan, function(input)
		if S.isPress(input) and not dragSquare then
			dragHue = input
			fromHue(input)
		end
	end)
	S.connect(UserInputService.InputChanged, function(input)
		if dragSquare and S.isMove(input, dragSquare) then
			fromSquare(input)
		elseif dragHue and S.isMove(input, dragHue) then
			fromHue(input)
		end
	end)
	S.connect(UserInputService.InputEnded, function(input)
		local held = dragSquare or dragHue
		if held and (input == held or input.UserInputType == Enum.UserInputType.MouseButton1 and held.UserInputType == Enum.UserInputType.MouseButton1) then
			dragSquare, dragHue = nil, nil
		end
	end)
	S.connect(Hex.FocusLost, function()
		local text = Hex.Text:gsub("#", ""):gsub("%s", "")
		local ok, color = pcall(Color3.fromHex, text)
		if ok and color then
			picker:SetValueRGB(color)
		else
			display()
		end
	end)
	S.connect(Swatch.MouseButton1Click, function()
		if frame.Visible then
			S.closePopup()
			return
		end
		display()
		S.openPopup(Popup, Swatch, 220, 216)
	end)
	display()
	return picker
end

function Groupbox:AddColorPicker(id, options)
	options = options or {}
	local Row = S.row(self, 30)
	S.textBlock(Row, options.Text or options.Title or tostring(id), options.Description, 50)
	local Right = S.create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 3,
		Parent = Row,
	}, { S.list(6, true, { HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center }) })
	options.Parent = Right
	options.Title = options.Title or options.Text
	local picker = S.makeColorPicker(self, id, options)
	picker.Row = Row
	S.index(self, options.Text or options.Title or tostring(id), Row)
	return picker
end
end
do
function S.dotRing(parent, size, count, dot, props)
	local holder = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		ZIndex = props and props.ZIndex or 2,
		Parent = parent,
	})
	for k, v in pairs(props or {}) do
		if k ~= "ZIndex" then
			holder[k] = v
		end
	end
	local dots = {}
	local radius = size / 2 - dot / 2
	for i = 1, count do
		local angle = (i - 1) / count * math.pi * 2 - math.pi / 2
		dots[i] = S.create("Frame", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius),
			Size = UDim2.fromOffset(dot, dot),
			ZIndex = holder.ZIndex,
			Theme = { BackgroundColor3 = "Silver" },
			Parent = holder,
		}, { S.corner(dot) })
	end
	local ring = { Frame = holder, Dots = dots, Value = 1 }
	function ring:Set(alpha, dim)
		alpha = math.clamp(alpha, 0, 1)
		self.Value = alpha
		local lit = alpha * count
		for i, d in ipairs(dots) do
			local amount = math.clamp(lit - (i - 1), 0, 1)
			d.BackgroundTransparency = amount > 0 and (1 - amount) * 0.8 or (dim or 0.86)
		end
	end
	ring:Set(1)
	return ring
end

local Stack = S.create("Frame", {
	Name = "Notifications",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -18, 1, -18),
	Size = UDim2.fromOffset(310, 600),
	ZIndex = 80,
	Parent = S.Overlay,
}, { S.list(8, false, { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
S.NotifyStack = Stack
local notifyOrder = 0

function Library:Notify(title, text, duration, icon)
	if type(title) == "table" then
		local o = title
		title, text, duration, icon = o.Title, o.Text or o.Description or o.Content, o.Time or o.Duration, o.Icon
	end
	if not self.NotifyEnabled or self.Unloaded then
		return
	end
	if text == nil then
		text, title = title, "Saturn"
	end
	duration = tonumber(duration) or 4
	notifyOrder += 1
	local Slot = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(310, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = notifyOrder,
		ZIndex = 80,
		Parent = Stack,
	})
	local Card = S.create("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(40, 0),
		GroupTransparency = 1,
		ZIndex = 80,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = Slot,
	}, { S.corner(12), S.stroke("BorderLight"), S.padding(12, 14, 12, 12) })
	local IconHolder = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(34, 34),
		ZIndex = 81,
		Parent = Card,
	})
	Library:Icon(IconHolder, icon or "info", 15, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 82,
		Theme = { ImageColor3 = "Silver" },
	})
	local ring = S.dotRing(IconHolder, 34, 28, 2, { ZIndex = 81 })
	local TextHolder = S.create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(46, 0),
		Size = UDim2.new(1, -46, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 81,
		Parent = Card,
	}, { S.list(2) })
	S.label({
		Text = tostring(title or "Saturn"),
		FontFace = S.FontSemi,
		TextSize = 13,
		Size = UDim2.new(1, 0, 0, 17),
		LayoutOrder = 1,
		ZIndex = 81,
		Theme = { TextColor3 = "Text" },
		Parent = TextHolder,
	})
	S.label({
		Text = tostring(text or ""),
		TextSize = 12,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		ZIndex = 81,
		Theme = { TextColor3 = "Muted" },
		Parent = TextHolder,
	})
	S.tween(Card, S.TweenSmooth, { Position = UDim2.new(), GroupTransparency = 0 })
	local started = os.clock()
	local alive = true
	local step
	local function close()
		if not alive then
			return
		end
		alive = false
		S.unloop(step)
		S.tween(Card, S.Tween, { Position = UDim2.fromOffset(40, 0), GroupTransparency = 1 })
		task.delay(0.2, function()
			Slot:Destroy()
		end)
	end
	step = S.loop(function()
		if not alive then
			return
		end
		local left = 1 - (os.clock() - started) / duration
		ring:Set(left)
		if left <= 0 then
			close()
		end
	end)
	local Hit = S.create("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 90,
		Parent = Slot,
	})
	S.bind(Hit.MouseButton1Click, close)
	return { Close = close }
end
end
do
local Bar = S.create("Frame", {
	Name = "OrbitBar",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.fromOffset(0, 34),
	AutomaticSize = Enum.AutomaticSize.X,
	Visible = false,
	ZIndex = 20,
	Theme = { BackgroundColor3 = "Panel" },
	Parent = S.HudGui,
}, {
	S.corner(17),
	S.stroke("BorderLight"),
	S.padding(0, 8, 0, 8),
	S.list(6, true, { VerticalAlignment = Enum.VerticalAlignment.Center }),
})
pcall(function()
	Bar.BackgroundTransparency = 0.08
end)
local BarLogo = Library:Image(Bar, "Logo", { Size = UDim2.fromOffset(38, 19), ZIndex = 21, LayoutOrder = 0 })
S.draggable(Bar, Bar)
local chips = {}

local function chip(toggle, order)
	local Chip = S.create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		LayoutOrder = order,
		ZIndex = 21,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Bar,
	}, {
		S.corner(11),
		S.stroke("BorderLight"),
		S.padding(0, 10, 0, 8),
		S.list(6, true, { VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	S.create("Frame", {
		Size = UDim2.fromOffset(6, 6),
		LayoutOrder = 1,
		ZIndex = 22,
		Theme = { BackgroundColor3 = "Silver" },
		Parent = Chip,
	}, { S.corner(3) })
	S.label({
		Text = toggle.Text,
		TextSize = 11.5,
		FontFace = S.FontSemi,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		LayoutOrder = 2,
		ZIndex = 22,
		Theme = { TextColor3 = "Text" },
		Parent = Chip,
	})
	S.bind(Chip.MouseButton1Click, function()
		toggle:SetValue(false)
	end)
	S.bind(Chip.MouseEnter, function()
		S.tween(Chip, S.TweenFast, { BackgroundColor3 = Library.Theme.FieldHover })
	end)
	S.bind(Chip.MouseLeave, function()
		S.tween(Chip, S.TweenFast, { BackgroundColor3 = Library.Theme.Field })
	end)
	return Chip
end

local MAX_CHIPS = 6
function S.refreshOrbitBar()
	for _, c in ipairs(chips) do
		c:Destroy()
	end
	table.clear(chips)
	local shown = 0
	for _, toggle in ipairs(S.ActiveToggles) do
		if shown >= MAX_CHIPS then
			break
		end
		shown += 1
		table.insert(chips, chip(toggle, shown))
	end
	local extra = #S.ActiveToggles - shown
	if extra > 0 then
		table.insert(chips, S.label({
			Text = "+" .. extra,
			TextSize = 11.5,
			FontFace = S.FontSemi,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 22),
			LayoutOrder = 99,
			ZIndex = 21,
			Theme = { TextColor3 = "Muted" },
			Parent = Bar,
		}))
	end
	Bar.Visible = Library.OrbitBarEnabled and #S.ActiveToggles > 0 and not Library.Unloaded
	if S.updateOrbCount then
		S.updateOrbCount()
	end
end

function S.orbitChanged(toggle)
	if toggle.Orbit == false then
		return
	end
	local i = table.find(S.ActiveToggles, toggle)
	if toggle.Value and not i then
		table.insert(S.ActiveToggles, toggle)
	elseif not toggle.Value and i then
		table.remove(S.ActiveToggles, i)
	end
	S.refreshOrbitBar()
end

function Library:SetOrbitBar(on)
	self.OrbitBarEnabled = on and true or false
	S.refreshOrbitBar()
end

local Orb = S.create("TextButton", {
	Name = "Eclipse",
	Text = "",
	AutoButtonColor = false,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 70, 0.5, 0),
	Size = UDim2.fromOffset(96, 96),
	Visible = false,
	ZIndex = 30,
	Parent = S.HudGui,
})
local OrbScale = S.create("UIScale", { Scale = 1, Parent = Orb })
local OrbRing = Library:Image(Orb, "Ring", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(92, 30),
	ImageTransparency = 0.45,
	ZIndex = 30,
})
OrbRing.ScaleType = Enum.ScaleType.Stretch
OrbRing.Rotation = -18
S.themed(OrbRing, { ImageColor3 = "Silver" })
local Planet = S.create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(56, 56),
	ZIndex = 31,
	Theme = { BackgroundColor3 = "Panel" },
	Parent = Orb,
}, { S.corner(28), S.stroke("BorderLight") })
Library:Image(Planet, "Logo", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(46, 23),
	ZIndex = 32,
})
local Moon = S.create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(6, 6),
	ZIndex = 33,
	Theme = { BackgroundColor3 = "Silver" },
	Parent = Orb,
}, { S.corner(3) })
local OrbTip = S.label({
	Text = "",
	TextSize = 11.5,
	FontFace = S.FontSemi,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, -4, 0.5, 0),
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 24),
	BackgroundTransparency = 0,
	Visible = false,
	ZIndex = 34,
	Theme = { TextColor3 = "Text", BackgroundColor3 = "Field" },
	Parent = Orb,
}, nil)
S.create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = OrbTip })
S.create("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = OrbTip })
local tipStroke = S.stroke("BorderLight")
tipStroke.Parent = OrbTip

function S.updateOrbCount()
	local n = #S.ActiveToggles
	OrbTip.Text = n == 1 and "1 feature on" or (n .. " features on")
end

S.loop(function()
	if not Orb.Visible then
		return
	end
	local t = S.AnimClock * 1.6
	local a, b = 46, 15
	local x, y = math.cos(t) * a, math.sin(t) * b
	local r = math.rad(-18)
	local rx, ry = x * math.cos(r) - y * math.sin(r), x * math.sin(r) + y * math.cos(r)
	Moon.Position = UDim2.new(0.5, rx, 0.5, ry)
	Moon.ZIndex = math.sin(t) < 0 and 30 or 33
end)

do
	local pressed, moved, start, origin
	S.connect(Orb.InputBegan, function(input)
		if S.isPress(input) and not pressed then
			pressed, moved, start, origin = input, false, input.Position, Orb.Position
		end
	end)
	S.connect(UserInputService.InputChanged, function(input)
		if pressed and S.isMove(input, pressed) then
			local delta = input.Position - start
			if delta.Magnitude > 6 then
				moved = true
			end
			if moved then
				Orb.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X, origin.Y.Scale, origin.Y.Offset + delta.Y)
			end
		end
	end)
	S.connect(UserInputService.InputEnded, function(input)
		if pressed and (input == pressed or input.UserInputType == Enum.UserInputType.MouseButton1 and pressed.UserInputType == Enum.UserInputType.MouseButton1) then
			pressed = nil
			if not moved then
				Library:Eclipse(false)
			end
		end
	end)
	S.connect(Orb.MouseEnter, function()
		S.updateOrbCount()
		OrbTip.Visible = true
		S.tween(OrbScale, S.TweenFast, { Scale = 1.06 })
	end)
	S.connect(Orb.MouseLeave, function()
		OrbTip.Visible = false
		S.tween(OrbScale, S.TweenFast, { Scale = 1 })
	end)
end

function S.showOrb()
	S.updateOrbCount()
	Orb.Visible = true
	OrbScale.Scale = 0.6
	S.tween(OrbScale, S.TweenSmooth, { Scale = 1 })
end

function S.hideOrb()
	Orb.Visible = false
end

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Library:Eclipse(on)
	local Main = S.Window and S.Window.Main
	if not Main then
		return
	end
	if on then
		if S.Eclipsed then
			return
		end
		S.Eclipsed = true
		local center = S.screenPos(Main) + Vector2.new(24, 24)
		local scale = S.Window.ScaleObject
		S.tween(scale, S.TweenFast, { Scale = self.Scale * 0.9 })
		task.delay(0.1, function()
			if S.Eclipsed then
				Main.Visible = false
				scale.Scale = self.Scale
			end
		end)
		self.Open = false
		S.closePopup()
		if not S.OrbPlaced then
			S.OrbPlaced = true
			Orb.Position = UDim2.fromOffset(center.X + 24, center.Y + 24)
		end
		S.showOrb()
	else
		if not S.Eclipsed then
			return
		end
		S.Eclipsed = false
		S.hideOrb()
		self:Toggle(true)
	end
end

S.onToggle = function(state)
	if not state then
		S.closePopup()
		if isMobile() and not S.Eclipsed then
			S.Eclipsed = true
			S.showOrb()
		end
	end
end

function Library:CreateLoader(options)
	options = options or {}
	local Gui = S.screenGui("SaturnLoader", 9500)
	local Back = S.create("CanvasGroup", {
		Name = "Loading",
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		BackgroundColor3 = Color3.new(0, 0, 0),
		ZIndex = 100,
		Parent = Gui,
	})
	pcall(function()
		Back.BackgroundTransparency = 0.35
	end)
	local Center = S.create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(260, 230),
		ZIndex = 101,
		Parent = Back,
	})
	local ring = S.dotRing(Center, 160, 64, 3, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		ZIndex = 101,
	})
	Library:Image(ring.Frame, "Logo", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(116, 58),
		ZIndex = 102,
	})
	local Title = S.label({
		Text = options.Title or "SATURN",
		FontFace = S.FontBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 172),
		Size = UDim2.new(1, 0, 0, 20),
		ZIndex = 101,
		Theme = { TextColor3 = "Text" },
		Parent = Center,
	})
	local Status = S.label({
		Text = options.Text or "Loading",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 196),
		Size = UDim2.new(1, 0, 0, 18),
		ZIndex = 101,
		Theme = { TextColor3 = "Muted" },
		Parent = Center,
	})
	S.tween(Back, S.Tween, { GroupTransparency = 0 })
	local loader = { Value = 0, Gui = Back }
	local shown = 0
	local step = S.loop(function(dt)
		shown += (loader.Value - shown) * math.min(dt * 8, 1)
		ring:Set(shown, 0.88)
	end)
	ring:Set(0, 0.88)
	local lastText = options.Text or "Loading"
	function loader:Set(progress, text)
		self.Value = math.clamp(tonumber(progress) or self.Value, 0, 1)
		if text then
			lastText = tostring(text)
		end
		Status.Text = lastText .. "  ·  " .. math.floor(self.Value * 100 + 0.5) .. "%"
	end
	function loader:SetTitle(text)
		Title.Text = tostring(text)
	end
	function loader:Done()
		self:Set(1, options.DoneText or "Ready")
		task.delay(0.35, function()
			S.tween(Back, S.Tween, { GroupTransparency = 1 })
			task.delay(0.25, function()
				S.unloop(step)
				Gui:Destroy()
			end)
		end)
	end
	return loader
end
end
do
local Search = S.create("Frame", {
	Name = "Search",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 120),
	Size = UDim2.fromOffset(420, 52),
	Visible = false,
	ZIndex = 70,
	Theme = { BackgroundColor3 = "Panel" },
	Parent = S.Overlay,
}, { S.corner(12), S.stroke("BorderLight"), S.create("UIScale", { Scale = 1 }) })
local SearchField = S.create("Frame", {
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.new(1, -16, 0, 36),
	ZIndex = 71,
	Theme = { BackgroundColor3 = "Field" },
	Parent = Search,
}, { S.corner(9), S.stroke("Border") })
Library:Icon(SearchField, "search", 15, {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 11, 0.5, 0),
	ZIndex = 71,
	Theme = { ImageColor3 = "Muted" },
})
local Box = S.create("TextBox", {
	Text = "",
	PlaceholderText = "Search every setting",
	ClearTextOnFocus = false,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(34, 0),
	Size = UDim2.new(1, -44, 1, 0),
	FontFace = S.Font,
	TextSize = 13.5,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 71,
	Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
	Parent = SearchField,
})
local Results = S.create("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(8, 50),
	Size = UDim2.new(1, -16, 1, -58),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 2,
	ZIndex = 71,
	Parent = Search,
}, { S.list(2) })
S.themed(Results, { ScrollBarImageColor3 = "BorderLight" })
local resultRows = {}
local Popup = { Frame = Search }

local function flash(target)
	local Glow = S.create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Transparency = 0,
		Theme = { Color = "Silver" },
		Parent = target,
	})
	local Round = target:FindFirstChildOfClass("UICorner") or S.create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = target })
	task.delay(1, function()
		S.tween(Glow, TweenInfo.new(0.6), { Transparency = 1 })
		task.delay(0.65, function()
			Glow:Destroy()
		end)
	end)
	return Round
end

local function jump(entry)
	S.closePopup()
	local window = S.Window
	if not window then
		return
	end
	window:SelectTab(entry.Tab)
	task.defer(function()
		local page = entry.Tab.Page
		local target = entry.Target
		if target and target.Parent then
			local offset = target.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y - 60
			S.tween(page, S.TweenSmooth, { CanvasPosition = Vector2.new(0, math.max(offset, 0)) })
			flash(target)
		end
	end)
end

local function score(entry, query)
	local text = entry.Text:lower()
	if text == query then
		return 0
	end
	local at = text:find(query, 1, true)
	if at == 1 then
		return 1
	end
	if at then
		return 2
	end
	local extra = (entry.Extra or ""):lower()
	if extra:find(query, 1, true) then
		return 3
	end
	local words = 0
	for word in query:gmatch("%S+") do
		if text:find(word, 1, true) or extra:find(word, 1, true) then
			words += 1
		else
			return nil
		end
	end
	return words > 0 and 4 or nil
end

local function render()
	for _, r in ipairs(resultRows) do
		r:Destroy()
	end
	table.clear(resultRows)
	local query = Box.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	local found = {}
	if query ~= "" then
		for _, entry in ipairs(S.SearchIndex) do
			if entry.Target and entry.Target.Parent then
				local s = score(entry, query)
				if s then
					table.insert(found, { entry, s })
				end
			end
		end
		table.sort(found, function(a, b)
			if a[2] ~= b[2] then
				return a[2] < b[2]
			end
			return a[1].Text < b[1].Text
		end)
	end
	for i = 1, math.min(#found, 40) do
		local entry = found[i][1]
		local Row = S.create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = i,
			ZIndex = 72,
			Theme = { BackgroundColor3 = "Field" },
			Parent = Results,
		}, { S.corner(8) })
		S.label({
			Text = entry.Text,
			TextSize = 13,
			FontFace = S.FontSemi,
			Position = UDim2.fromOffset(12, 4),
			Size = UDim2.new(1, -24, 0, 17),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 72,
			Theme = { TextColor3 = "Text" },
			Parent = Row,
		})
		S.label({
			Text = entry.Tab.Name .. "  ›  " .. entry.Box.Name,
			TextSize = 11.5,
			Position = UDim2.fromOffset(12, 21),
			Size = UDim2.new(1, -24, 0, 15),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 72,
			Theme = { TextColor3 = "Muted" },
			Parent = Row,
		})
		S.bind(Row.MouseEnter, function()
			S.tween(Row, S.TweenFast, { BackgroundTransparency = 0 })
		end)
		S.bind(Row.MouseLeave, function()
			S.tween(Row, S.TweenFast, { BackgroundTransparency = 1 })
		end)
		S.bind(Row.MouseButton1Click, function()
			jump(entry)
		end)
		table.insert(resultRows, Row)
	end
	local height = 52
	if query ~= "" then
		height = 58 + math.max(math.min(#found, 7), 1) * 42
		if #found == 0 then
			local Empty = S.label({
				Text = "Nothing matches \"" .. Box.Text .. "\"",
				TextSize = 12.5,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 40),
				ZIndex = 72,
				Theme = { TextColor3 = "Muted" },
				Parent = Results,
			})
			table.insert(resultRows, Empty)
		end
	end
	Search.Size = UDim2.fromOffset(420, height)
	Popup.Best = found[1] and found[1][1] or nil
end

S.connect(Box:GetPropertyChangedSignal("Text"), render)
S.connect(Box.FocusLost, function(enter)
	if enter and Popup.Best then
		jump(Popup.Best)
	end
end)

function S.openSearch()
	local window = S.Window
	if not window then
		return
	end
	S.closePopup()
	local main = window.Main
	local scale = window.ScaleObject.Scale
	Box.Text = ""
	render()
	local at = S.screenPos(main)
	local x = at.X + main.AbsoluteSize.X / 2
	local y = at.Y + 56 * scale
	Search.Position = UDim2.fromOffset(x, y)
	local popupScale = Search:FindFirstChildOfClass("UIScale")
	popupScale.Scale = scale * 0.96
	S.tween(popupScale, S.Tween, { Scale = scale })
	Search.Visible = true
	S.Blocker.Visible = true
	S.setOpenPopup(Popup)
	task.defer(function()
		Box:CaptureFocus()
	end)
end

S.connect(UserInputService.InputBegan, function(input)
	if input.KeyCode == Enum.KeyCode.F and Library.Open and not S.typing()
		and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
		S.openSearch()
	end
end)

function Library:OpenSearch()
	S.openSearch()
end
end
do
local function hasFiles()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function configPath(name)
	return Library.Folder .. "/configs/" .. tostring(name) .. ".json"
end

local function serialize(option)
	local kind = option.Type
	if kind == "Toggle" or kind == "Slider" or kind == "Input" then
		return option.Value
	elseif kind == "Dropdown" then
		if option.Multi then
			local list = {}
			for k, v in pairs(option.Value) do
				if v then
					table.insert(list, k)
				end
			end
			return list
		end
		if option.Value == nil then
			return false
		end
		return option.Value
	elseif kind == "KeyPicker" then
		return { option.Value, option.Mode }
	elseif kind == "ColorPicker" then
		return { option.Value:ToHex(), option.Transparency or 0 }
	end
	return nil
end

local function apply(option, value)
	local kind = option.Type
	if kind == "ColorPicker" then
		if type(value) == "table" and type(value[1]) == "string" then
			local ok, color = pcall(Color3.fromHex, value[1])
			if ok then
				option:SetValueRGB(color, value[2])
			end
		end
	elseif kind == "KeyPicker" then
		option:SetValue(value)
	elseif kind == "Dropdown" and option.Multi then
		option:SetValue(type(value) == "table" and value or {})
	elseif kind == "Dropdown" and value == false then
		option:SetValue(nil)
	else
		option:SetValue(value)
	end
end

function Library:SaveConfig(name)
	name = tostring(name or ""):gsub("[^%w%s%-_]", "")
	if name == "" then
		return false, "Give the config a name"
	end
	if not hasFiles() then
		return false, "This executor can't save files"
	end
	local data = {}
	for id, option in pairs(self.Options) do
		if not option.NoConfig and type(id) == "string" then
			local value = serialize(option)
			if value ~= nil then
				data[id] = value
			end
		end
	end
	S.ensureFolder(self.Folder .. "/configs")
	local ok, err = pcall(writefile, configPath(name), HttpService:JSONEncode({ saturn = 1, options = data }))
	if not ok then
		return false, tostring(err)
	end
	return true
end

function Library:LoadConfig(name)
	if not hasFiles() then
		return false, "This executor can't read files"
	end
	local path = configPath(name)
	if not isfile(path) then
		return false, "No config called " .. tostring(name)
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok or type(decoded) ~= "table" then
		return false, "That config file is broken"
	end
	local options = decoded.options or decoded
	for id, value in pairs(options) do
		local option = self.Options[id]
		if option and not option.NoConfig then
			pcall(apply, option, value)
		end
	end
	return true
end

function Library:DeleteConfig(name)
	local path = configPath(name)
	if hasFiles() and type(delfile) == "function" and isfile(path) then
		return pcall(delfile, path)
	end
	return false
end

function Library:ListConfigs()
	local list = {}
	if type(listfiles) ~= "function" then
		return list
	end
	local ok, files = pcall(listfiles, self.Folder .. "/configs")
	if not ok then
		return list
	end
	for _, file in ipairs(files) do
		local name = tostring(file):gsub("\\", "/"):match("([^/]+)%.json$")
		if name then
			table.insert(list, name)
		end
	end
	table.sort(list)
	return list
end

function Library:SetAutoload(name)
	if not hasFiles() then
		return false
	end
	S.ensureFolder(self.Folder)
	return pcall(writefile, self.Folder .. "/autoload.txt", tostring(name or ""))
end

function Library:GetAutoload()
	if not hasFiles() then
		return nil
	end
	local path = self.Folder .. "/autoload.txt"
	if not isfile(path) then
		return nil
	end
	local ok, name = pcall(readfile, path)
	if ok and name and name ~= "" then
		return name
	end
	return nil
end

function Library:LoadAutoload()
	local name = self:GetAutoload()
	if name then
		local ok, err = self:LoadConfig(name)
		if ok then
			self:Notify("Configs", "Loaded " .. name, 3, "config")
		else
			self:Notify("Configs", "Couldn't load " .. name .. ": " .. tostring(err), 5, "config")
		end
		return ok
	end
	return false
end

local menuFile = function()
	return Library.Folder .. "/menu.json"
end

function S.saveMenu()
	if not hasFiles() then
		return
	end
	local data = {
		scale = Library.Scale,
		starfield = Library.Starfield,
		orbitBar = Library.OrbitBarEnabled,
		notify = Library.NotifyEnabled,
		key = Library.ToggleKey and Library.ToggleKey.Name or "RightControl",
	}
	S.ensureFolder(Library.Folder)
	pcall(writefile, menuFile(), HttpService:JSONEncode(data))
end

function S.loadMenu()
	if not hasFiles() or not isfile(menuFile()) then
		return nil
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(menuFile()))
	end)
	return ok and type(data) == "table" and data or nil
end

function Library:BuildSettingsTab(window, options)
	options = options or {}
	window = window or S.Window
	local saved = S.loadMenu() or {}
	local tab = window:AddTab(options.Name or "Settings", "settings")
	local Menu = tab:AddLeftGroupbox("Menu")
	local key = Menu:AddKeybind("Saturn_MenuKey", {
		Text = "Menu key",
		Default = saved.key or (self.ToggleKey and self.ToggleKey.Name) or "RightControl",
	})
	key.NoConfig = true
	local function applyKey(value)
		local code = value and value ~= "None" and S.keyCode(value)
		if code then
			self.ToggleKey = code
		end
		S.saveMenu()
	end
	key:OnChanged(applyKey)
	applyKey(key.Value)
	local scale = Menu:AddSlider("Saturn_Scale", {
		Text = "Menu size",
		Min = 70,
		Max = 150,
		Default = math.floor((tonumber(saved.scale) or self.Scale) * 100 + 0.5),
		Suffix = "%",
	})
	scale.NoConfig = true
	local function applyScale(v)
		self:SetScale(v / 100)
		S.saveMenu()
	end
	scale:OnChanged(function(v)
		if not scale.Holding then
			applyScale(v)
		end
	end)
	scale.OnRelease = applyScale
	self:SetScale(scale.Value / 100)
	local stars = Menu:AddToggle("Saturn_Starfield", { Text = "Starfield", Default = saved.starfield ~= false })
	stars.NoConfig, stars.Orbit = true, false
	stars:OnChanged(function(v)
		self:SetStarfield(v)
		S.saveMenu()
	end)
	self:SetStarfield(stars.Value)
	local bar = Menu:AddToggle("Saturn_OrbitBar", {
		Text = "Active orbit bar",
		Default = saved.orbitBar ~= false,
	})
	bar.NoConfig, bar.Orbit = true, false
	bar:OnChanged(function(v)
		self:SetOrbitBar(v)
		S.saveMenu()
	end)
	self:SetOrbitBar(bar.Value)
	local notify = Menu:AddToggle("Saturn_Notify", { Text = "Notifications", Default = saved.notify ~= false })
	notify.NoConfig, notify.Orbit = true, false
	notify:OnChanged(function(v)
		self.NotifyEnabled = v
		S.saveMenu()
	end)
	self.NotifyEnabled = notify.Value
	Menu:AddButton({ Text = "Unload Saturn", DoubleClick = true, Func = function()
		self:Unload()
	end })

	local Configs = tab:AddRightGroupbox("Configs")
	local nameBox = Configs:AddInput("Saturn_ConfigName", { Text = "Name", Placeholder = "my config" })
	nameBox.NoConfig = true
	local list = Configs:AddDropdown("Saturn_ConfigList", {
		Text = "Saved",
		Values = self:ListConfigs(),
		AllowNull = true,
	})
	list.NoConfig = true
	local auto = Configs:AddLabel("Autoload: " .. (self:GetAutoload() or "none"))
	local function refresh()
		list:SetValues(self:ListConfigs())
		auto:SetText("Autoload: " .. (self:GetAutoload() or "none"))
	end
	local function chosen()
		local name = nameBox.Value ~= "" and nameBox.Value or list.Value
		return name and tostring(name) or nil
	end
	Configs:AddButton({ Text = "Save", Func = function()
		local name = chosen()
		local ok, err = self:SaveConfig(name)
		self:Notify("Configs", ok and ("Saved " .. tostring(name)) or tostring(err), 3, "config")
		refresh()
	end })
	Configs:AddButton({ Text = "Load", Func = function()
		local name = list.Value or chosen()
		if not name then
			self:Notify("Configs", "Pick a config first", 3, "config")
			return
		end
		local ok, err = self:LoadConfig(name)
		self:Notify("Configs", ok and ("Loaded " .. name) or tostring(err), 3, "config")
	end })
	Configs:AddButton({ Text = "Set as autoload", Func = function()
		local name = list.Value or chosen()
		if not name then
			self:Notify("Configs", "Pick a config first", 3, "config")
			return
		end
		self:SetAutoload(name)
		refresh()
		self:Notify("Configs", name .. " loads automatically now", 3, "config")
	end })
	Configs:AddButton({ Text = "Delete", DoubleClick = true, Func = function()
		local name = list.Value
		if not name then
			self:Notify("Configs", "Pick a config first", 3, "config")
			return
		end
		self:DeleteConfig(name)
		if self:GetAutoload() == name then
			self:SetAutoload("")
		end
		refresh()
		self:Notify("Configs", "Deleted " .. name, 3, "config")
	end })
	Configs:AddButton({ Text = "Refresh list", Func = refresh })
	return tab
end
end
do
local ESP = {
	Enabled = false,
	Settings = {
		Boxes = true,
		Rings = true,
		Names = true,
		Distance = true,
		Health = true,
		Arrows = true,
		TeamCheck = false,
		MaxDistance = 1500,
		FadeStart = 600,
		Color = Color3.fromHex("e6e8ec"),
	},
	Targets = {},
}
Library.ESP = ESP

local EspGui = S.screenGui("SaturnESP", 8000)
local AdornFolder = Instance.new("Folder")
AdornFolder.Name = "SaturnRings"
pcall(function()
	AdornFolder.Parent = S.guiParent()
end)
table.insert(S.UnloadCallbacks, function()
	AdornFolder:Destroy()
end)

local function line(parent)
	return S.create("Frame", {
		BorderSizePixel = 0,
		BackgroundColor3 = ESP.Settings.Color,
		Parent = parent,
	})
end

local function build(target)
	local holder = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = EspGui,
	})
	local corners = {}
	for i = 1, 8 do
		corners[i] = line(holder)
	end
	local HealthBack = S.create("Frame", {
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromHex("1b1c20"),
		Parent = holder,
	}, { S.corner(2) })
	local HealthFill = S.create("Frame", {
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = HealthBack,
	}, { S.corner(2) })
	S.create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromHex("f4f5f7"), Color3.fromHex("9da1a9")),
		Parent = HealthFill,
	})
	local Pill = S.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		BackgroundColor3 = Color3.fromHex("0a0a0c"),
		BackgroundTransparency = 0.22,
		Parent = holder,
	}, {
		S.corner(11),
		S.create("UIStroke", { Color = Color3.fromHex("2a2b30"), Thickness = 1 }),
		S.padding(0, 10, 0, 10),
		S.list(6, true, { VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	local Name = S.label({
		Text = target.Name,
		FontFace = S.FontSemi,
		TextSize = 12,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		LayoutOrder = 1,
		TextColor3 = Color3.fromHex("eef0f3"),
		Theme = {},
		Parent = Pill,
	})
	local Dist = S.label({
		Text = "",
		TextSize = 11,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		LayoutOrder = 2,
		TextColor3 = Color3.fromHex("8b8f97"),
		Theme = {},
		Parent = Pill,
	})
	local Arrow = S.create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		Visible = false,
		Parent = EspGui,
	})
	local ArrowGlyph = Library:Icon(Arrow, "chevron", 18, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ImageColor3 = ESP.Settings.Color,
		Theme = {},
	})
	local ArrowText = S.label({
		Text = "",
		TextSize = 11.5,
		AutomaticSize = Enum.AutomaticSize.X,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 4, 0.5, 0),
		Size = UDim2.fromOffset(0, 16),
		TextColor3 = Color3.fromHex("c9ccd2"),
		TextStrokeTransparency = 0.6,
		Theme = {},
		Parent = Arrow,
	})
	local Ring, Arc
	pcall(function()
		Ring = Instance.new("CylinderHandleAdornment")
		Ring.Radius = 2.6
		Ring.Height = 0.04
		Ring.AlwaysOnTop = true
		Ring.ZIndex = 1
		Ring.Transparency = 0.7
		Ring.Color3 = ESP.Settings.Color
		pcall(function()
			Ring.InnerRadius = 2.5
		end)
		Ring.Parent = AdornFolder
		Arc = Instance.new("CylinderHandleAdornment")
		Arc.Radius = 2.15
		Arc.Height = 0.05
		Arc.AlwaysOnTop = true
		Arc.ZIndex = 2
		Arc.Transparency = 0.1
		Arc.Color3 = ESP.Settings.Color
		pcall(function()
			Arc.InnerRadius = 2.02
			Arc.Angle = 250
		end)
		Arc.Parent = AdornFolder
	end)
	target.Gui = {
		Holder = holder, Corners = corners, HealthBack = HealthBack, HealthFill = HealthFill,
		Pill = Pill, Name = Name, Dist = Dist, Arrow = Arrow, ArrowGlyph = ArrowGlyph, ArrowText = ArrowText,
		Ring = Ring, Arc = Arc,
	}
end

local function destroy(target)
	local gui = target.Gui
	if not gui then
		return
	end
	gui.Holder:Destroy()
	gui.Arrow:Destroy()
	if gui.Ring then
		gui.Ring:Destroy()
	end
	if gui.Arc then
		gui.Arc:Destroy()
	end
	target.Gui = nil
end

function ESP:Add(model, options)
	options = options or {}
	if not model or self.Targets[model] then
		return self.Targets[model]
	end
	local target = {
		Model = model,
		Name = options.Name or model.Name,
		Player = options.Player,
		Color = options.Color,
		Health = options.Health,
	}
	self.Targets[model] = target
	build(target)
	target.Removing = model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			ESP:Remove(model)
		end
	end)
	return target
end

function ESP:Remove(model)
	local target = self.Targets[model]
	if not target then
		return
	end
	self.Targets[model] = nil
	if target.Removing then
		target.Removing:Disconnect()
	end
	destroy(target)
end

function ESP:Clear()
	for model in pairs(self.Targets) do
		self:Remove(model)
	end
end

local playerConns = {}
function ESP:AddPlayers()
	local function track(player)
		if player == LocalPlayer then
			return
		end
		local function onCharacter(character)
			ESP:Add(character, { Name = player.DisplayName ~= player.Name and player.DisplayName or player.Name, Player = player })
		end
		if player.Character then
			onCharacter(player.Character)
		end
		table.insert(playerConns, player.CharacterAdded:Connect(onCharacter))
	end
	for _, player in ipairs(Players:GetPlayers()) do
		track(player)
	end
	table.insert(playerConns, Players.PlayerAdded:Connect(track))
	return self
end

function ESP:SetEnabled(on)
	self.Enabled = on and true or false
	if not self.Enabled then
		for _, target in pairs(self.Targets) do
			if target.Gui then
				target.Gui.Holder.Visible = false
				target.Gui.Arrow.Visible = false
				if target.Gui.Ring then
					target.Gui.Ring.Adornee = nil
					target.Gui.Arc.Adornee = nil
				end
			end
		end
	end
end

function ESP:SetColor(color)
	self.Settings.Color = color
	for _, target in pairs(self.Targets) do
		local gui = target.Gui
		if gui then
			local c = target.Color or color
			for _, l in ipairs(gui.Corners) do
				l.BackgroundColor3 = c
			end
			gui.ArrowGlyph.ImageColor3 = c
			if gui.Ring then
				gui.Ring.Color3 = c
				gui.Arc.Color3 = c
			end
		end
	end
end

table.insert(S.UnloadCallbacks, function()
	for _, c in ipairs(playerConns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	ESP:Clear()
end)

local function partsOf(model)
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return root, humanoid
end

local function extents(target)
	local now = os.clock()
	if not target.ExtentAt or now - target.ExtentAt > 2 then
		target.ExtentAt = now
		local ok, size = pcall(function()
			return target.Model:GetExtentsSize()
		end)
		target.Extent = ok and size or Vector3.new(4, 5.5, 2)
	end
	return target.Extent
end

local function groundOffset(root, humanoid, height)
	if humanoid then
		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			return 3
		end
		return humanoid.HipHeight + root.Size.Y / 2
	end
	return height / 2
end

local function setCorners(corners, x, y, w, h, color, alpha)
	local len = math.clamp(math.min(w, h) * 0.22, 4, 18)
	local t = 1.5
	local spec = {
		{ x, y, len, t }, { x, y, t, len },
		{ x + w - len, y, len, t }, { x + w - t, y, t, len },
		{ x, y + h - t, len, t }, { x, y + h - len, t, len },
		{ x + w - len, y + h - t, len, t }, { x + w - t, y + h - len, t, len },
	}
	for i, s in ipairs(spec) do
		local l = corners[i]
		l.Position = UDim2.fromOffset(s[1], s[2])
		l.Size = UDim2.fromOffset(s[3], s[4])
		l.BackgroundColor3 = color
		l.BackgroundTransparency = alpha
	end
end

S.loop(function()
	if not ESP.Enabled then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local settings = ESP.Settings
	local view = camera.ViewportSize
	local center = view / 2
	local camPos = camera.CFrame.Position
	local spin = S.AnimClock * 1.4
	for model, target in pairs(ESP.Targets) do
		local gui = target.Gui
		if gui then
			local root, humanoid = partsOf(model)
			local show = root ~= nil and model.Parent ~= nil
			if show and humanoid and humanoid.Health <= 0 then
				show = false
			end
			if show and settings.TeamCheck and target.Player and target.Player.Team ~= nil and target.Player.Team == LocalPlayer.Team then
				show = false
			end
			local distance = show and (root.Position - camPos).Magnitude or 0
			if show and distance > settings.MaxDistance then
				show = false
			end
			if not show then
				gui.Holder.Visible = false
				gui.Arrow.Visible = false
				if gui.Ring then
					gui.Ring.Adornee = nil
					gui.Arc.Adornee = nil
				end
			else
				local color = target.Color or settings.Color
				local fade = 0
				if distance > settings.FadeStart then
					fade = math.clamp((distance - settings.FadeStart) / math.max(settings.MaxDistance - settings.FadeStart, 1), 0, 1) * 0.75
				end
				local size = extents(target)
				local height = math.clamp(size.Y, 2, 80)
				local width = math.clamp(math.max(size.X, size.Z), 1, 80)
				local ground = root.Position - Vector3.new(0, groundOffset(root, humanoid, height), 0)
				local top = ground + Vector3.new(0, height + 0.3, 0)
				local topScreen, topOn = camera:WorldToViewportPoint(top)
				local bottomScreen, bottomOn = camera:WorldToViewportPoint(ground)
				local onScreen = (topOn or bottomOn) and topScreen.Z > 0 and bottomScreen.Z > 0
				if gui.Ring then
					if settings.Rings then
						local radius = math.clamp(width * 0.75, 2, 30)
						gui.Ring.Radius = radius
						gui.Arc.Radius = radius * 0.83
						pcall(function()
							gui.Ring.InnerRadius = radius - 0.1
							gui.Arc.InnerRadius = radius * 0.83 - 0.13
						end)
						local offset = CFrame.new(ground - root.Position + Vector3.new(0, 0.12, 0))
						local flat = CFrame.Angles(math.rad(90), 0, 0)
						gui.Ring.CFrame = offset * flat
						gui.Arc.CFrame = offset * flat * CFrame.Angles(0, 0, spin)
						gui.Ring.Transparency = 0.7 + fade * 0.3
						gui.Arc.Transparency = 0.1 + fade
						gui.Ring.Color3 = color
						gui.Arc.Color3 = color
						gui.Ring.Adornee = root
						gui.Arc.Adornee = root
					else
						gui.Ring.Adornee = nil
						gui.Arc.Adornee = nil
					end
				end
				if onScreen then
					gui.Arrow.Visible = false
					gui.Holder.Visible = true
					local h = math.max(bottomScreen.Y - topScreen.Y, 6)
					local w = math.max(h * (width / height) * 1.05, 6)
					local x = (topScreen.X + bottomScreen.X) / 2 - w / 2
					local y = topScreen.Y
					for _, l in ipairs(gui.Corners) do
						l.Visible = settings.Boxes
					end
					if settings.Boxes then
						setCorners(gui.Corners, x, y, w, h, color, fade)
					end
					local hp, maxHp = 1, 1
					if target.Health then
						local ok, a, b = pcall(target.Health, model)
						if ok then
							hp, maxHp = tonumber(a) or 1, tonumber(b) or 1
						end
					elseif humanoid then
						hp, maxHp = humanoid.Health, humanoid.MaxHealth
					end
					gui.HealthBack.Visible = settings.Health
					if settings.Health then
						gui.HealthBack.Position = UDim2.fromOffset(x - 7, y)
						gui.HealthBack.Size = UDim2.fromOffset(3, h)
						gui.HealthBack.BackgroundTransparency = fade
						local ratio = math.clamp(hp / math.max(maxHp, 1), 0, 1)
						gui.HealthFill.Position = UDim2.fromScale(0, 1)
						gui.HealthFill.Size = UDim2.fromScale(1, ratio)
						gui.HealthFill.BackgroundTransparency = fade
					end
					gui.Pill.Visible = settings.Names or settings.Distance
					if gui.Pill.Visible then
						gui.Pill.Position = UDim2.fromOffset(x + w / 2, y - 6)
						gui.Name.Visible = settings.Names
						gui.Name.Text = target.Name
						gui.Dist.Visible = settings.Distance
						gui.Dist.Text = math.floor(distance + 0.5) .. "m"
						gui.Pill.BackgroundTransparency = 0.22 + fade * 0.7
						gui.Name.TextTransparency = fade
						gui.Dist.TextTransparency = fade
					end
				else
					gui.Holder.Visible = false
					if settings.Arrows then
						local rel = camera.CFrame:PointToObjectSpace(root.Position)
						local dir = Vector2.new(rel.X, -rel.Y)
						if rel.Z > 0 and dir.Magnitude < 1e-3 then
							dir = Vector2.new(0, 1)
						end
						if dir.Magnitude < 1e-3 then
							dir = Vector2.new(1, 0)
						end
						dir = dir.Unit
						local radius = math.min(view.X, view.Y) / 2 - 46
						local pos = center + dir * radius
						gui.Arrow.Position = UDim2.fromOffset(pos.X, pos.Y)
						gui.ArrowGlyph.Rotation = math.deg(math.atan2(dir.Y, dir.X))
						gui.ArrowGlyph.ImageColor3 = color
						gui.ArrowGlyph.ImageTransparency = fade
						gui.ArrowText.Text = target.Name .. " · " .. math.floor(distance + 0.5) .. "m"
						gui.ArrowText.Position = dir.X < 0 and UDim2.new(1, 4, 0.5, 0) or UDim2.new(0, -4, 0.5, 0)
						gui.ArrowText.AnchorPoint = dir.X < 0 and Vector2.new(0, 0.5) or Vector2.new(1, 0.5)
						gui.ArrowText.TextTransparency = fade
						gui.Arrow.Visible = true
					else
						gui.Arrow.Visible = false
					end
				end
			end
		end
	end
end)

function ESP:AddSettings(box, prefix)
	prefix = prefix or "SaturnESP"
	local master = box:AddToggle(prefix .. "_Enabled", { Text = "ESP", Default = self.Enabled })
	master:OnChanged(function(v)
		self:SetEnabled(v)
	end)
	master:AddColorPicker(prefix .. "_Color", { Default = self.Settings.Color, Title = "ESP color", Callback = function(c)
		self:SetColor(c)
	end })
	local function flag(key, text)
		local t = box:AddToggle(prefix .. "_" .. key, { Text = text, Default = self.Settings[key], Orbit = false })
		t:OnChanged(function(v)
			self.Settings[key] = v
		end)
		return t
	end
	flag("Rings", "Orbit rings")
	flag("Boxes", "Boxes")
	flag("Health", "Health bar")
	flag("Names", "Names")
	flag("Distance", "Distance")
	flag("Arrows", "Off-screen arrows")
	flag("TeamCheck", "Skip teammates")
	local maxDist = box:AddSlider(prefix .. "_MaxDistance", { Text = "Max distance", Min = 50, Max = 5000, Default = self.Settings.MaxDistance, Suffix = "m" })
	local fadeBase = self.Settings.FadeStart
	maxDist:OnChanged(function(v)
		self.Settings.MaxDistance = v
		self.Settings.FadeStart = math.min(fadeBase, v * 0.6)
	end)
	return master
end
end
Env.SaturnLibrary = Library
return Library
