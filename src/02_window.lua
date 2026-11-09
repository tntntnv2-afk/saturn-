S.Gui = S.screenGui("Saturn", 9000)
S.Overlay = S.screenGui("SaturnOverlay", 9100)
S.HudGui = S.screenGui("SaturnHud", 8990)

local TITLE_H = 48
local RAIL_H = 44
local FOOT_H = 28

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
	local view = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local fit = math.max(self.Scale, 0.1)
	local width = math.floor(math.min(options.Width or 760, (view.X - 24) / fit))
	local height = math.floor(math.min(options.Height or 500, (view.Y - 24) / fit))
	local self_ = setmetatable({ Tabs = {}, Library = self, TabIcons = options.TabIcons }, Window)
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
	S.create("UISizeConstraint", { MinSize = Vector2.new(math.min(520, width), math.min(340, height)), Parent = Main })

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
	local gameText = options.Subtitle
	if gameText == nil then
		gameText = options.Game
	end
	local Sub = S.label({
		Text = gameText and tostring(gameText) or "",
		TextSize = 12,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		LayoutOrder = 3,
		ZIndex = 2,
		Theme = { TextColor3 = "Muted" },
		Parent = Brand,
	})
	self_.SubLabel = Sub
	if gameText == nil then
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
		Size = UDim2.new(1, 0, 1, -(TITLE_H + RAIL_H + 3 + FOOT_H)),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = Inner,
	})
	self_.Pages = Pages

	S.create("Frame", {
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -FOOT_H),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Border" },
		Parent = Inner,
	})
	local Foot = S.create("Frame", {
		Name = "Status",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, FOOT_H),
		ZIndex = 2,
		Parent = Inner,
	})
	S.create("Frame", {
		BackgroundTransparency = 0.35,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Theme = { BackgroundColor3 = "Chrome" },
		Parent = Foot,
	}, { S.corner(14) })
	S.create("Frame", {
		BorderSizePixel = 0,
		BackgroundTransparency = 0.35,
		Size = UDim2.new(1, 0, 0, 14),
		ZIndex = 1,
		Theme = { BackgroundColor3 = "Chrome" },
		Parent = Foot,
	})
	local FootLeft = S.create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.6, -12, 1, 0),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = Foot,
	}, { S.list(8, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local function footText(parent, text, order, token, font)
		return S.label({
			Text = text or "",
			TextSize = 11.5,
			FontFace = font or S.Font,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, FOOT_H),
			LayoutOrder = order,
			ZIndex = 2,
			Theme = { TextColor3 = token or "Muted" },
			Parent = parent,
		})
	end
	local LocalPlayer = Players.LocalPlayer
	if options.User ~= false and LocalPlayer then
		local Avatar = S.create("ImageLabel", {
			Size = UDim2.fromOffset(18, 18),
			LayoutOrder = 1,
			ZIndex = 2,
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=48&h=48",
			Theme = { BackgroundColor3 = "Field" },
			Parent = FootLeft,
		}, { S.corner(9), S.stroke("BorderLight") })
		self_.Avatar = Avatar
		footText(FootLeft, LocalPlayer.DisplayName, 2, "Text", S.FontSemi)
		if options.Badge then
			local Badge = S.create("Frame", {
				Size = UDim2.fromOffset(0, 16),
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = 3,
				ZIndex = 2,
				Theme = { BackgroundColor3 = "Field" },
				Parent = FootLeft,
			}, { S.corner(8), S.stroke("BorderLight"), S.padding(0, 7, 0, 7) })
			local BadgeText = S.label({
				Text = string.upper(tostring(options.Badge)),
				FontFace = S.FontBold,
				TextSize = 9.5,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 16),
				ZIndex = 2,
				Theme = { TextColor3 = "Silver" },
				Parent = Badge,
			})
			self_.BadgeLabel = BadgeText
		else
			footText(FootLeft, "@" .. tostring(LocalPlayer.Name), 3)
		end
	end
	local FooterDot = footText(FootLeft, "·", 4)
	local FooterText = footText(FootLeft, options.Footer or "", 5)
	FooterDot.Visible = (options.Footer or "") ~= "" and options.User ~= false
	self_.FooterLabel, self_.FooterDot = FooterText, FooterDot
	local FootRight = S.create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -22, 0, 0),
		Size = UDim2.new(0.4, -22, 1, 0),
		ZIndex = 2,
		Parent = Foot,
	}, { S.list(10, true, { HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local FooterRight = footText(FootRight, options.FooterRight or "", 1)
	FooterRight.Visible = (options.FooterRight or "") ~= ""
	self_.FooterRightLabel = FooterRight
	local FpsText = footText(FootRight, "0 fps", 2, "SubText", S.FontMono)
	local PingText = footText(FootRight, "0 ms", 3, "SubText", S.FontMono)
	table.insert(S.PerfListeners, function(perf)
		FpsText.Text = perf.Fps .. " fps"
		PingText.Text = perf.Ping .. " ms"
	end)

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
				local screen = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
				local fit = math.max(Scale.Scale, 0.1)
				Main.Size = UDim2.fromOffset(
					math.clamp(startSize.X + delta.X * 2, math.min(520, width), math.max((screen.X - 24) / fit, 520)),
					math.clamp(startSize.Y + delta.Y * 2, math.min(340, height), math.max((screen.Y - 24) / fit, 340))
				)
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
	if options.AutoShow == false or (self.GetSilentLoad and self:GetSilentLoad()) then
		self.Open = false
		Main.Visible = false
		task.defer(function()
			if S.onToggle and not self.Open then
				S.onToggle(false)
			end
		end)
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
	for _, hud in ipairs(S.ScaledHud or {}) do
		hud.Scale = self.Scale
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

function Library:SetSubtitle(text)
	self:SetGame(text)
end

function Library:SetFooter(text)
	local w = S.Window
	if w then
		w.FooterLabel.Text = tostring(text or "")
		w.FooterDot.Visible = w.FooterLabel.Text ~= "" and w.Avatar ~= nil
	end
end

function Library:SetFooterRight(text)
	local w = S.Window
	if w then
		w.FooterRightLabel.Text = tostring(text or "")
		w.FooterRightLabel.Visible = w.FooterRightLabel.Text ~= ""
	end
end

function Library:SetBadge(text)
	local w = S.Window
	if w and w.BadgeLabel then
		w.BadgeLabel.Text = string.upper(tostring(text or ""))
	end
end

function Library:SetToggleKey(key)
	local code = S.keyCode(key)
	if code then
		self.ToggleKey = code
		if S.saveMenu then
			S.saveMenu()
		end
	end
	return code ~= nil
end

function Window:Toggle(state)
	Library:Toggle(state)
end

function Window:GetTab(name)
	for _, tab in ipairs(self.Tabs) do
		if tab.Name == name then
			return tab
		end
	end
	return nil
end

function Window:SetTitle(text)
	self.TitleLabel.Text = tostring(text)
end

function Window:AddSection(name)
	self.SectionCount = (self.SectionCount or 0) + 1
	local order = #self.Tabs * 2 + 1
	local Holder = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = order,
		Parent = self.Strip,
	}, { S.list(8, true, { VerticalAlignment = Enum.VerticalAlignment.Center }), S.padding(0, 4, 0, #self.Tabs > 0 and 4 or 2) })
	if #self.Tabs > 0 then
		S.create("Frame", {
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(1, 18),
			LayoutOrder = 1,
			Theme = { BackgroundColor3 = "BorderLight" },
			Parent = Holder,
		})
	end
	if name and name ~= "" then
		S.label({
			Text = string.upper(tostring(name)),
			FontFace = S.FontBold,
			TextSize = 9.5,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 24),
			LayoutOrder = 2,
			ZIndex = 2,
			Theme = { TextColor3 = "Muted" },
			Parent = Holder,
		})
	end
	self.Section = name
	return Holder
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
	if type(icon) == "table" then
		icon = icon.Icon
	end
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
	Glyph.Visible = self.TabIcons ~= false and icon ~= false
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

	local Page = S.create("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 2,
		Parent = self.Pages,
	})
	local function column(left)
		local Scroller = S.create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = left and UDim2.fromOffset(12, 0) or UDim2.new(0.5, 4, 0, 0),
			Size = UDim2.new(0.5, -16, 1, 0),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 2,
			ScrollBarImageTransparency = 0.5,
			VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
			ZIndex = 2,
			Parent = Page,
		})
		S.themed(Scroller, { ScrollBarImageColor3 = "BorderLight" })
		local Holder = S.create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(2, 12),
			Size = UDim2.new(1, -4, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2,
			Parent = Scroller,
		}, { S.list(12) })
		S.create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(1, 0),
			LayoutOrder = 1000000,
			Parent = Holder,
		})
		return Holder, Scroller
	end
	local Left, LeftScroll = column(true)
	local Right, RightScroll = column(false)
	tab.Page, tab.Left, tab.Right = Page, Left, Right
	tab.LeftScroll, tab.RightScroll = LeftScroll, RightScroll

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
