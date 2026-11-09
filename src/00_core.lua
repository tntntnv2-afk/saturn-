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
