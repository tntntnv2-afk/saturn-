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
	return UserInputService.TouchEnabled
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

Library.WatermarkEnabled = false
Library.KeybindListEnabled = false

local function popIn(frame, on)
	local scale = frame:FindFirstChildOfClass("UIScale")
	if on then
		if not frame.Visible then
			frame.Visible = true
			if scale then
				scale.Scale = Library.Scale * 0.94
				S.tween(scale, S.Tween, { Scale = Library.Scale })
			end
		end
	else
		frame.Visible = false
	end
end
S.ScaledHud = S.ScaledHud or {}

local Watermark = S.create("Frame", {
	Name = "Watermark",
	Position = UDim2.fromOffset(16, 14),
	Size = UDim2.fromOffset(0, 32),
	AutomaticSize = Enum.AutomaticSize.X,
	Visible = false,
	ZIndex = 20,
	Theme = { BackgroundColor3 = "Panel" },
	Parent = S.HudGui,
}, {
	S.corner(16),
	S.stroke("Border"),
	S.padding(0, 12, 0, 6),
	S.list(10, true, { VerticalAlignment = Enum.VerticalAlignment.Center }),
	S.create("UIScale", { Scale = 1 }),
})
S.Watermark = Watermark
table.insert(S.ScaledHud, Watermark:FindFirstChildOfClass("UIScale"))
Library:Image(Watermark, "Logo", { Size = UDim2.fromOffset(40, 20), LayoutOrder = 1, ZIndex = 21 })
local markOrder = 1
local function markText(text, token, font, mono)
	markOrder += 1
	if markOrder > 2 then
		S.create("Frame", {
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(1, 12),
			LayoutOrder = markOrder,
			ZIndex = 21,
			Theme = { BackgroundColor3 = "BorderLight" },
			Parent = Watermark,
		})
		markOrder += 1
	end
	return S.label({
		Text = text,
		FontFace = mono and S.FontMono or font or S.FontSemi,
		TextSize = mono and 11.5 or 12,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 32),
		LayoutOrder = markOrder,
		ZIndex = 21,
		Theme = { TextColor3 = token or "SubText" },
		Parent = Watermark,
	})
end
local MarkTitle = markText("Saturn", "Text", S.FontBold)
local MarkUser = markText(Players.LocalPlayer and Players.LocalPlayer.DisplayName or "", "SubText")
local MarkFps = markText("0 fps", "SubText", nil, true)
local MarkPing = markText("0 ms", "SubText", nil, true)
local MarkPlayers = markText("", "SubText")
S.draggable(Watermark, Watermark)
local function paintMark(perf)
	MarkFps.Text = perf.Fps .. " fps"
	MarkPing.Text = perf.Ping .. " ms"
	local count = #Players:GetPlayers()
	MarkPlayers.Text = count .. (count == 1 and " player" or " players")
end
paintMark(S.Perf)
table.insert(S.PerfListeners, function(perf)
	if Watermark.Visible then
		paintMark(perf)
	end
end)

function Library:SetWatermark(on, text)
	self.WatermarkEnabled = on and true or false
	if text then
		MarkTitle.Text = tostring(text)
	elseif S.Window and S.Window.TitleLabel then
		MarkTitle.Text = S.Window.TitleLabel.Text
	end
	paintMark(S.Perf)
	popIn(Watermark, self.WatermarkEnabled)
end

local KeyPanel = S.create("Frame", {
	Name = "Keybinds",
	Position = UDim2.new(0, 16, 0.38, 0),
	Size = UDim2.fromOffset(220, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Visible = false,
	ZIndex = 20,
	Theme = { BackgroundColor3 = "Panel" },
	Parent = S.HudGui,
}, { S.corner(12), S.stroke("Border"), S.create("UIScale", { Scale = 1 }) })
S.KeybindPanel = KeyPanel
table.insert(S.ScaledHud, KeyPanel:FindFirstChildOfClass("UIScale"))
local KeyHead = S.create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 36),
	ZIndex = 21,
	Parent = KeyPanel,
})
Library:Icon(KeyHead, "keybinds", 14, {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	ZIndex = 21,
	Theme = { ImageColor3 = "Silver" },
})
S.label({
	Text = "KEYBINDS",
	FontFace = S.FontBold,
	TextSize = 11,
	Position = UDim2.fromOffset(34, 0),
	Size = UDim2.new(1, -90, 1, 0),
	ZIndex = 21,
	Theme = { TextColor3 = "Text" },
	Parent = KeyHead,
})
local KeyCount = S.label({
	Text = "0 / 0",
	FontFace = S.FontMono,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Right,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 0),
	Size = UDim2.new(0, 60, 1, 0),
	ZIndex = 21,
	Theme = { TextColor3 = "Muted" },
	Parent = KeyHead,
})
S.create("Frame", {
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(0, 36),
	Size = UDim2.new(1, 0, 0, 1),
	ZIndex = 21,
	Theme = { BackgroundColor3 = "Border" },
	Parent = KeyPanel,
})
local KeyRows = S.create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 37),
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	ZIndex = 21,
	Parent = KeyPanel,
}, { S.list(2), S.padding(6, 6, 7, 6) })
S.draggable(KeyHead, KeyPanel)

local MODE_SHORT = { Toggle = "toggle", Hold = "hold", Press = "press", Always = "always" }
local keyRows = {}
local keyPending = false
local function renderKeybinds()
	keyPending = false
	for _, row in ipairs(keyRows) do
		row:Destroy()
	end
	table.clear(keyRows)
	local T = Library.Theme
	local on = 0
	for i, bind in ipairs(S.KeybindList) do
		if not bind.Hidden and bind.Value ~= "None" and bind.Chip and bind.Chip.Parent then
			local active = bind:GetState() == true
			if active then
				on += 1
			end
			local Row = S.create("Frame", {
				Size = UDim2.new(1, 0, 0, 26),
				LayoutOrder = i,
				BackgroundColor3 = T.Field,
				BackgroundTransparency = active and 0 or 1,
				ZIndex = 21,
				Parent = KeyRows,
			}, { S.corner(7) })
			if active then
				S.create("Frame", {
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 4, 0.5, 0),
					Size = UDim2.fromOffset(2, 12),
					BackgroundColor3 = T.Silver,
					ZIndex = 22,
					Parent = Row,
				}, { S.corner(1) })
			end
			S.label({
				Text = bind.Text,
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -110, 1, 0),
				ZIndex = 22,
				TextColor3 = active and T.Text or T.SubText,
				Parent = Row,
			})
			local Right = S.create("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				ZIndex = 22,
				Parent = Row,
			}, { S.list(6, true, { HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center }) })
			S.label({
				Text = MODE_SHORT[bind.Mode] or "",
				TextSize = 10.5,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 18),
				LayoutOrder = 1,
				ZIndex = 22,
				TextColor3 = T.Muted,
				Parent = Right,
			})
			local Chip = S.create("Frame", {
				Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = 2,
				BackgroundColor3 = T.Off,
				ZIndex = 22,
				Parent = Right,
			}, { S.corner(5), S.padding(0, 7, 0, 7) })
			local edge = S.create("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = active and T.SilverDim or T.Border,
				Parent = Chip,
			})
			edge.Thickness = 1
			S.label({
				Text = bind.Chip.Text,
				FontFace = S.FontMono,
				TextSize = 10.5,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 18),
				ZIndex = 22,
				TextColor3 = active and T.Silver or T.SubText,
				Parent = Chip,
			})
			table.insert(keyRows, Row)
		end
	end
	KeyCount.Text = on .. " / " .. #keyRows
	popIn(KeyPanel, Library.KeybindListEnabled and #keyRows > 0)
end

S.refreshKeybindList = function()
	if keyPending then
		return
	end
	keyPending = true
	task.defer(function()
		if not Library.Unloaded then
			renderKeybinds()
		end
	end)
end

table.insert(S.ThemeCallbacks, function()
	S.refreshKeybindList()
end)

function Library:SetKeybindList(on)
	self.KeybindListEnabled = on and true or false
	S.refreshKeybindList()
end
