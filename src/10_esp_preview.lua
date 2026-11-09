local Groupbox = S.GroupboxClass

local PREVIEW_SILVER = Color3.fromHex("e6e8ec")
local RING_DOTS = 36
local HEADER_H = 38

local function previewButton(parent, props, icon)
	local base = {
		Text = "",
		AutoButtonColor = false,
		FontFace = S.FontSemi,
		TextSize = 14,
		ZIndex = 8,
		Theme = { BackgroundColor3 = "Field", TextColor3 = "Muted" },
		Parent = parent,
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	local button = S.create("TextButton", base, { S.corner(7), S.stroke("Border") })
	local glyph
	if icon then
		glyph = Library:Icon(button, icon, 14, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			ZIndex = button.ZIndex,
			Theme = { ImageColor3 = "Muted" },
		})
	end
	S.connect(button.MouseEnter, function()
		S.tween(button, S.TweenFast, { BackgroundColor3 = Library.Theme.FieldHover, TextColor3 = Library.Theme.Text })
		if glyph then
			S.tween(glyph, S.TweenFast, { ImageColor3 = Library.Theme.Text })
		end
	end)
	S.connect(button.MouseLeave, function()
		S.tween(button, S.TweenFast, { BackgroundColor3 = Library.Theme.Field, TextColor3 = Library.Theme.Muted })
		if glyph then
			S.tween(glyph, S.TweenFast, { ImageColor3 = Library.Theme.Muted })
		end
	end)
	return button, glyph
end

local function setBox(lines, style, x, y, w, h, color)
	local t = 1.5
	local spec
	if style == "Full" then
		spec = {
			{ x, y, w, t }, { x, y + h - t, w, t }, { x, y, t, h }, { x + w - t, y, t, h },
		}
	else
		local len = math.clamp(math.min(w, h) * 0.22, 4, 18)
		spec = {
			{ x, y, len, t }, { x, y, t, len },
			{ x + w - len, y, len, t }, { x + w - t, y, t, len },
			{ x, y + h - t, len, t }, { x, y + h - len, t, len },
			{ x + w - len, y + h - t, len, t }, { x + w - t, y + h - len, t, len },
		}
	end
	for i, l in ipairs(lines) do
		local s = spec[i]
		if s then
			l.Visible = true
			l.Position = UDim2.fromOffset(s[1], s[2])
			l.Size = UDim2.fromOffset(s[3], s[4])
			l.BackgroundColor3 = color
		else
			l.Visible = false
		end
	end
end

local function backdrop(Canvas)
	S.create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0.5),
		BorderSizePixel = 0,
		ZIndex = 1,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = Canvas,
	}, {
		S.create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new(1, 0),
		}),
	})
	for i = 1, 24 do
		local x = (i * 0.6180339887) % 1
		local y = (i * 0.7548776662 + i * i * 0.0131) % 1
		local size = (i % 5 == 0) and 2 or 1
		S.create("Frame", {
			BorderSizePixel = 0,
			Position = UDim2.fromScale(x, y * 0.85),
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 0.45 + (i % 4) * 0.12,
			ZIndex = 1,
			Theme = { BackgroundColor3 = "Silver" },
			Parent = Canvas,
		}, { S.corner(size) })
	end
end

local function loadAvatar(id)
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromUserId(id)
	end)
	if not ok or typeof(model) ~= "Instance" then
		ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
		end)
		if not ok or typeof(model) ~= "Instance" then
			ok, model = pcall(function()
				local character = Players.LocalPlayer and Players.LocalPlayer.Character
				if not character then
					return nil
				end
				local archivable = character.Archivable
				character.Archivable = true
				local copy = character:Clone()
				character.Archivable = archivable
				return copy
			end)
			if not ok or typeof(model) ~= "Instance" then
				return nil
			end
		end
	end
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("Script") or item:IsA("LocalScript") then
			item:Destroy()
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		pcall(function()
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end)
	end
	pcall(function()
		model:PivotTo(CFrame.new(0, 0, 0))
	end)
	return model, humanoid
end

local function playIdle(humanoid)
	pcall(function()
		if not humanoid then
			return
		end
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
		local animation = Instance.new("Animation")
		animation.AnimationId = humanoid.RigType == Enum.HumanoidRigType.R6 and "rbxassetid://180435571" or "rbxassetid://507766666"
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track:Play()
	end)
end

function Groupbox:AddESPPreview(options)
	options = options or {}
	local tabNames = options.Tabs or { "Enemy", "Team" }
	local height = math.max(tonumber(options.Height) or 250, 140)
	local userId = tonumber(options.UserId) or (LocalPlayer and LocalPlayer.UserId > 0 and LocalPlayer.UserId) or 1
	local baseColour = options.Colour or options.Color or PREVIEW_SILVER
	local defaultName = options.Name or (LocalPlayer and LocalPlayer.DisplayName) or "Player"

	local Row = S.row(self, height + HEADER_H)
	local Body = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height + HEADER_H),
		ZIndex = 2,
		Parent = Row,
	})
	local Switch = S.create("Frame", {
		Size = UDim2.fromOffset(6, 28),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Body,
	}, { S.corner(8), S.stroke("BorderLight") })
	local Indicator = S.create("Frame", {
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(0, 22),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = Switch,
	}, { S.corner(6) })
	S.silverFill(Indicator)
	local PinButton = previewButton(Body, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(28, 28),
		ZIndex = 2,
	}, "pin")

	local Canvas = S.create("Frame", {
		Position = UDim2.fromOffset(0, HEADER_H),
		Size = UDim2.new(1, 0, 0, height),
		ClipsDescendants = true,
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Body,
	}, { S.corner(10), S.stroke("Border") })
	backdrop(Canvas)

	local View = S.create("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(168, 170, 176),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-0.4, -1, -0.7),
		ZIndex = 3,
		Parent = Canvas,
	})
	local World = S.create("WorldModel", { Parent = View })
	local Camera = S.create("Camera", { FieldOfView = 34, Parent = View })
	View.CurrentCamera = Camera
	local Probe = S.create("Frame", {
		Size = UDim2.fromOffset(100, 100),
		BackgroundTransparency = 1,
		Visible = true,
		ZIndex = 1,
		Parent = Canvas,
	})

	local dummy
	local center, extent = Vector3.new(0, 0, 0), Vector3.new(4, 5.5, 2)
	local yaw, distance = math.rad(24), 13

	local loadId = 0
	local function loadUser(id)
		loadId += 1
		local mine = loadId
		task.spawn(function()
			local model, humanoid = loadAvatar(id)
			if not model then
				return
			end
			if mine ~= loadId or Library.Unloaded then
				pcall(function()
					model:Destroy()
				end)
				return
			end
			if dummy then
				pcall(function()
					dummy:Destroy()
				end)
			end
			model.Parent = World
			dummy = model
			local ok, cf, size = pcall(function()
				return model:GetBoundingBox()
			end)
			if ok and typeof(size) == "Vector3" then
				center = cf.Position
				extent = size.Y >= 2 and size or Vector3.new(4, 5.5, 2)
			end
			playIdle(humanoid)
		end)
	end
	loadUser(userId)

	local Sink = S.create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		CanvasSize = UDim2.fromScale(0, 3),
		CanvasPosition = Vector2.new(0, 1),
		Active = true,
		ZIndex = 6,
		Parent = Canvas,
	})
	local spinning, lastX = nil, 0
	S.connect(Sink.InputBegan, function(input)
		if S.isPress(input) and not spinning then
			spinning, lastX = input, input.Position.X
		end
	end)
	S.connect(Sink.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			distance = math.clamp(distance - input.Position.Z * 1.2, 6, 22)
		end
	end)
	S.connect(Sink:GetPropertyChangedSignal("CanvasPosition"), function()
		local middle = math.max(0, (Sink.AbsoluteCanvasSize.Y - Sink.AbsoluteSize.Y) * 0.5)
		if math.abs(Sink.CanvasPosition.Y - middle) > 0.5 then
			Sink.CanvasPosition = Vector2.new(0, middle)
		end
	end)
	S.connect(UserInputService.InputChanged, function(input)
		if spinning and S.isMove(input, spinning) then
			yaw += (input.Position.X - lastX) * 0.012
			lastX = input.Position.X
		end
	end)
	S.connect(UserInputService.InputEnded, function(input)
		if spinning and (input == spinning or input.UserInputType == Enum.UserInputType.MouseButton1 and spinning.UserInputType == Enum.UserInputType.MouseButton1) then
			spinning = nil
		end
	end)

	for index, spec in ipairs({ { "+", -1.5 }, { "-", 1.5 } }) do
		local Zoom = previewButton(Canvas, {
			Text = spec[1],
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -8, 1, -8 - (2 - index) * 26),
			Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 0.1,
		})
		S.connect(Zoom.MouseButton1Click, function()
			distance = math.clamp(distance + spec[2], 6, 22)
		end)
	end

	local preview = { Frame = Row, Canvas = Canvas, View = View, Tabs = {}, Active = nil, Changed = {} }

	function preview:OnTabChanged(fn)
		table.insert(self.Changed, fn)
		return self
	end

	local function canvasScale()
		return math.max(Probe.AbsoluteSize.X / 100, 0.01)
	end

	local function project(point, scale)
		local rel = Camera.CFrame:PointToObjectSpace(point)
		if rel.Z > -0.05 then
			return nil
		end
		local size = Canvas.AbsoluteSize
		if size.X < 1 or size.Y < 1 then
			return nil
		end
		local tanHalf = math.tan(math.rad(Camera.FieldOfView) * 0.5)
		local px = (rel.X / -rel.Z) / (tanHalf * (size.X / size.Y))
		local py = (rel.Y / -rel.Z) / tanHalf
		return Vector2.new((px * 0.5 + 0.5) * size.X / scale, (0.5 - py * 0.5) * size.Y / scale)
	end

	local switchX = 3
	for index, name in ipairs(tabNames) do
		name = tostring(name)
		local Back = S.create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			ZIndex = 2,
			Parent = Canvas,
		})
		local Page = S.create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			ZIndex = 4,
			Parent = Canvas,
		})
		local dots = {}
		for i = 1, RING_DOTS do
			dots[i] = S.create("Frame", {
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(3, 3),
				BackgroundColor3 = baseColour,
				ZIndex = 2,
				Parent = Back,
			}, { S.corner(2) })
		end
		local Tracer = S.create("Frame", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(1.5, 0),
			BackgroundColor3 = baseColour,
			BackgroundTransparency = 0.25,
			Visible = false,
			ZIndex = 4,
			Parent = Page,
		})
		local BoxFrame = S.create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
			Parent = Page,
		})
		local lines = {}
		for i = 1, 8 do
			lines[i] = S.create("Frame", {
				BorderSizePixel = 0,
				BackgroundColor3 = baseColour,
				ZIndex = 5,
				Parent = BoxFrame,
			})
		end
		local HealthBack = S.create("Frame", {
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromHex("1b1c20"),
			ZIndex = 5,
			Parent = Page,
		}, { S.corner(2) })
		local HealthFill = S.create("Frame", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromScale(1, 0.72),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 6,
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
			ZIndex = 6,
			Parent = Page,
		}, {
			S.corner(11),
			S.create("UIStroke", { Color = Color3.fromHex("2a2b30"), Thickness = 1 }),
			S.padding(0, 10, 0, 10),
			S.list(6, true, { VerticalAlignment = Enum.VerticalAlignment.Center }),
		})
		local NameLabel = S.label({
			Text = defaultName,
			FontFace = S.FontSemi,
			TextSize = 12,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 22),
			LayoutOrder = 1,
			TextColor3 = Color3.fromHex("eef0f3"),
			ZIndex = 6,
			Theme = {},
			Parent = Pill,
		})
		local DistanceLabel = S.label({
			Text = "",
			TextSize = 11,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 22),
			LayoutOrder = 2,
			TextColor3 = Color3.fromHex("8b8f97"),
			ZIndex = 6,
			Theme = {},
			Parent = Pill,
		})

		local tab = {
			Name = name,
			Page = Page,
			Back = Back,
			Colour = baseColour,
			Health = 0.72,
			BoxStyle = "Corner",
			Parts = {
				Name = NameLabel,
				Distance = DistanceLabel,
				HealthBg = HealthBack,
				Health = HealthFill,
				Tracer = Tracer,
				Card = Pill,
				Box = BoxFrame,
				Ring = Back,
			},
			_show = { Name = true, Distance = true, HealthBg = true, Tracer = false, Outline = true, Ring = true },
			_ringColour = nil,
			_distanceText = nil,
		}
		tab.Color = tab.Colour

		function tab:_layout(scale)
			scale = scale or canvasScale()
			local show = self._show
			local ground = center - Vector3.new(0, extent.Y * 0.5, 0)
			local top = project(ground + Vector3.new(0, extent.Y + 0.3, 0), scale)
			local bottom = project(ground, scale)
			if not top or not bottom then
				Page.Visible = false
				Back.Visible = false
				return
			end
			Page.Visible = true
			Back.Visible = show.Ring
			local tall = math.clamp(extent.Y, 2, 80)
			local wide = math.clamp(math.max(extent.X, extent.Z), 1, 80)
			local h = math.max(bottom.Y - top.Y, 6)
			local w = math.max(h * (wide / tall) * 1.05, 6)
			local x = (top.X + bottom.X) / 2 - w / 2
			local y = top.Y

			BoxFrame.Visible = show.Outline
			if show.Outline then
				setBox(lines, self.BoxStyle, x, y, w, h, self.Colour)
			end

			HealthBack.Visible = show.HealthBg
			if show.HealthBg then
				HealthBack.Position = UDim2.fromOffset(x - 7, y)
				HealthBack.Size = UDim2.fromOffset(3, h)
			end

			Pill.Visible = show.Name or show.Distance
			if Pill.Visible then
				Pill.Position = UDim2.fromOffset(x + w / 2, y - 6)
				NameLabel.Visible = show.Name
				DistanceLabel.Visible = show.Distance
				if not self._distanceText then
					local camPos = Camera.CFrame.Position
					DistanceLabel.Text = math.floor((center - camPos).Magnitude + 0.5) .. "m"
				end
			end

			Tracer.Visible = show.Tracer
			if show.Tracer then
				local size = Canvas.AbsoluteSize / scale
				local from = Vector2.new(size.X * 0.5, size.Y)
				local to = Vector2.new(x + w / 2, y + h)
				local delta = to - from
				local mid = (from + to) / 2
				Tracer.Position = UDim2.fromOffset(mid.X, mid.Y)
				Tracer.Size = UDim2.fromOffset(1.5, delta.Magnitude)
				Tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X)) + 90
			end

			if show.Ring then
				local radius = math.clamp(wide * 0.6, 1.6, 30)
				local spin = S.AnimClock * 1.4
				local arc = math.rad(250)
				local ringColour = self._ringColour or self.Colour
				for i, dot in ipairs(dots) do
					local angle = (i - 1) / RING_DOTS * math.pi * 2
					local point = project(ground + Vector3.new(math.cos(angle) * radius, 0.05, math.sin(angle) * radius), scale)
					if point then
						dot.Visible = true
						dot.Position = UDim2.fromOffset(point.X, point.Y)
						dot.BackgroundColor3 = ringColour
						local rel = (angle - spin) % (math.pi * 2)
						dot.BackgroundTransparency = rel < arc and (0.1 + rel / arc * 0.55) or 0.8
					else
						dot.Visible = false
					end
				end
			end
		end

		function tab:SetColour(color)
			if typeof(color) ~= "Color3" then
				return
			end
			self.Colour = color
			self.Color = color
			Tracer.BackgroundColor3 = color
			for _, l in ipairs(lines) do
				l.BackgroundColor3 = color
			end
		end
		tab.SetColor = tab.SetColour

		function tab:SetOutline(on)
			self._show.Outline = on and true or false
			BoxFrame.Visible = self._show.Outline
		end
		tab.SetBox = tab.SetOutline

		function tab:SetBoxStyle(style)
			style = tostring(style or "Corner")
			self.BoxStyle = (style == "Full" or style == "Box" or style == "Square" or style == "2D") and "Full" or "Corner"
		end

		function tab:SetText(which, value)
			if which == "Name" then
				NameLabel.Text = tostring(value)
			elseif which == "Distance" then
				if value == nil or value == "" then
					self._distanceText = nil
				else
					self._distanceText = tostring(value)
					DistanceLabel.Text = self._distanceText
				end
			end
		end

		function tab:SetHealth(fraction)
			fraction = math.clamp(tonumber(fraction) or 1, 0, 1)
			self.Health = fraction
			S.tween(HealthFill, S.TweenFast, { Size = UDim2.fromScale(1, fraction) })
		end

		function tab:Set(settings)
			for key, value in pairs(settings or {}) do
				local kind = typeof(value)
				if kind == "boolean" then
					if key == "Box" or key == "Outline" or key == "Highlight" then
						self:SetOutline(value)
					elseif key == "Health" then
						self._show.HealthBg = value
					elseif self.Parts[key] then
						self._show[key] = value
					end
				elseif kind == "Color3" then
					if key == "Box" or key == "Outline" or key == "Highlight" or key == "Colour" or key == "Color" then
						self:SetColour(value)
					elseif key == "Name" then
						NameLabel.TextColor3 = value
					elseif key == "Distance" then
						DistanceLabel.TextColor3 = value
					elseif key == "Tracer" then
						Tracer.BackgroundColor3 = value
					elseif key == "Ring" then
						self._ringColour = value
					elseif key == "Health" or key == "HealthBg" then
						HealthFill.BackgroundColor3 = value
					end
				elseif kind == "number" then
					if key == "Health" then
						self:SetHealth(value)
					end
				elseif kind == "string" then
					if key == "Name" or key == "Distance" then
						self:SetText(key, value)
					elseif key == "BoxStyle" then
						self:SetBoxStyle(value)
					end
				end
			end
			if Page.Visible then
				self:_layout()
			end
		end

		local width = math.floor(S.textWidth(name, 12, S.FontSemi) + 22)
		local offset = switchX
		switchX += width
		local Button = S.create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(offset, 3),
			Size = UDim2.fromOffset(width, 22),
			ZIndex = 4,
			Parent = Switch,
		})
		local ButtonLabel = S.label({
			Text = name,
			FontFace = S.FontSemi,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 4,
			Theme = { TextColor3 = "SubText" },
			Parent = Button,
		})
		tab._label, tab._button, tab._offset, tab._width = ButtonLabel, Button, offset, width

		function tab:Select()
			local changed = preview.Active ~= self
			for _, other in ipairs(preview.Tabs) do
				if other ~= self then
					other.Page.Visible = false
					other.Back.Visible = false
					S.Themed[other._label] = { TextColor3 = "SubText" }
					S.tween(other._label, S.TweenFast, { TextColor3 = Library.Theme.SubText })
				end
			end
			preview.Active = self
			S.Themed[ButtonLabel] = { TextColor3 = "KnobOn" }
			S.tween(ButtonLabel, S.TweenFast, { TextColor3 = Library.Theme.KnobOn })
			local target = { Position = UDim2.fromOffset(self._offset, 3), Size = UDim2.fromOffset(self._width, 22) }
			if Indicator.Size.X.Offset <= 0 then
				Indicator.Position, Indicator.Size = target.Position, target.Size
			else
				S.tween(Indicator, S.Tween, target)
			end
			self:_layout()
			if changed then
				for _, fn in ipairs(preview.Changed) do
					S.safe(fn, self.Name, self)
				end
			end
		end

		S.connect(Button.MouseEnter, function()
			if preview.Active ~= tab then
				S.tween(ButtonLabel, S.TweenFast, { TextColor3 = Library.Theme.Text })
			end
		end)
		S.connect(Button.MouseLeave, function()
			if preview.Active ~= tab then
				S.tween(ButtonLabel, S.TweenFast, { TextColor3 = Library.Theme.SubText })
			end
		end)
		S.connect(Button.MouseButton1Click, function()
			tab:Select()
		end)
		table.insert(preview.Tabs, tab)
	end
	Switch.Size = UDim2.fromOffset(switchX + 3, 28)

	local floating
	local rowVisible = true

	local function shown()
		local node = Canvas
		while node and node:IsA("GuiObject") do
			if not node.Visible then
				return false
			end
			node = node.Parent
		end
		if node and node:IsA("ScreenGui") then
			return node.Enabled ~= false
		end
		return false
	end

	S.loop(function()
		if floating then
			local main = S.Window and S.Window.Main
			floating.Frame.Visible = main == nil or main.Visible
			if S.Window then
				floating.Scale.Scale = S.Window.ScaleObject.Scale
			end
		end
		if not shown() then
			return
		end
		local target = center + Vector3.new(0, 0.3, 0)
		Camera.CFrame = CFrame.new(target + Vector3.new(math.sin(yaw) * distance, distance * 0.12, math.cos(yaw) * distance), target)
		local active = preview.Active
		if active then
			active:_layout(canvasScale())
		end
	end)

	local function dock()
		if not floating then
			return
		end
		for _, c in ipairs(floating.Connections) do
			c:Disconnect()
		end
		Body.Parent = Row
		Body.Position = UDim2.new()
		Body.Size = UDim2.new(1, 0, 0, height + HEADER_H)
		Canvas.Size = UDim2.new(1, 0, 0, height)
		PinButton.Visible = true
		Row.Visible = rowVisible
		floating.Frame:Destroy()
		floating = nil
	end

	local function float()
		if floating then
			return
		end
		local scale = S.Window and S.Window.ScaleObject.Scale or 1
		local width = math.max(Row.AbsoluteSize.X / math.max(canvasScale(), 0.01), 300) + 24
		local tall = height + HEADER_H + 64
		local camera = Workspace.CurrentCamera
		local view = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local Float = S.create("Frame", {
			Name = "ESPPreview",
			Size = UDim2.fromOffset(width, tall),
			Active = true,
			ZIndex = 40,
			Theme = { BackgroundColor3 = "Background" },
			Parent = S.Overlay,
		}, { S.corner(14), S.stroke("Border") })
		local FloatScale = S.create("UIScale", { Scale = scale, Parent = Float })
		local x = (view.X - width * scale) / 2
		local y = (view.Y - tall * scale) / 2
		local main = S.Window and S.Window.Main
		if main then
			local right = main.AbsolutePosition.X + main.AbsoluteSize.X + 16
			if right + width * scale <= view.X - 8 then
				x, y = right, math.clamp(main.AbsolutePosition.Y, 8, math.max(view.Y - tall * scale - 8, 8))
			end
		end
		Float.Position = UDim2.fromOffset(x, y)
		local Header = S.create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 44),
			Active = true,
			ZIndex = 40,
			Parent = Float,
		})
		S.label({
			Text = string.upper(tostring(options.Title or self.Name or "ESP preview")),
			FontFace = S.FontSemi,
			TextSize = 11,
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -60, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 40,
			Theme = { TextColor3 = "SubText" },
			Parent = Header,
		})
		local Close = previewButton(Header, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(26, 26),
			ZIndex = 41,
		}, "close")
		S.create("Frame", {
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 44),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 40,
			Theme = { BackgroundColor3 = "Border" },
			Parent = Float,
		})
		Body.Parent = Float
		Body.Position = UDim2.fromOffset(12, 56)
		Body.Size = UDim2.new(1, -24, 1, -68)
		Canvas.Size = UDim2.new(1, 0, 1, -HEADER_H)
		PinButton.Visible = false
		Row.Visible = false

		local connections = {}
		local pressed, start, origin
		table.insert(connections, S.bind(Header.InputBegan, function(input)
			if S.isPress(input) and not pressed then
				pressed, start, origin = input, input.Position, Float.Position
			end
		end))
		table.insert(connections, S.connect(UserInputService.InputChanged, function(input)
			if pressed and S.isMove(input, pressed) then
				local delta = input.Position - start
				Float.Position = UDim2.fromOffset(origin.X.Offset + delta.X, origin.Y.Offset + delta.Y)
			end
		end))
		table.insert(connections, S.connect(UserInputService.InputEnded, function(input)
			if pressed and (input == pressed or input.UserInputType == Enum.UserInputType.MouseButton1 and pressed.UserInputType == Enum.UserInputType.MouseButton1) then
				pressed = nil
			end
		end))
		table.insert(connections, S.bind(Close.MouseButton1Click, dock))
		floating = { Frame = Float, Scale = FloatScale, Connections = connections }
		FloatScale.Scale = scale * 0.96
		S.tween(FloatScale, S.Tween, { Scale = scale })
	end

	S.connect(PinButton.MouseButton1Click, float)

	function preview:GetTab(name)
		for _, tab in ipairs(self.Tabs) do
			if tab.Name == name then
				return tab
			end
		end
		return nil
	end
	function preview:Select(name)
		local tab = self:GetTab(name)
		if tab then
			tab:Select()
		end
		return tab
	end
	function preview:Set(name, settings)
		local tab = self:GetTab(name)
		if tab then
			tab:Set(settings)
		end
		return tab
	end
	function preview:SetUser(id)
		loadUser(tonumber(id) or userId)
	end
	function preview:SetFloating(on)
		if on then
			float()
		else
			dock()
		end
	end
	function preview:SetVisible(on)
		rowVisible = on and true or false
		Row.Visible = rowVisible and not floating
	end

	if preview.Tabs[1] then
		preview.Tabs[1]:Select()
	end
	S.index(self, options.Text or "ESP preview", Row)
	return preview
end
