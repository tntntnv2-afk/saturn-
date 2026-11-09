local GREEN = Color3.fromHex("8fc9a0")
local AMBER = Color3.fromHex("d6b67a")
local RED = Color3.fromHex("d98a8f")
local TARGET_STATES = {
	fighting = { "Fighting" },
	attacking = { "Attacking" },
	dodging = { "Dodging", AMBER },
	looting = { "Looting", GREEN },
	finishing = { "Finishing", GREEN },
	gripping = { "Gripping", GREEN },
	retreating = { "Retreating", RED },
	healing = { "Healing", GREEN },
	resetting = { "Resetting", AMBER },
	waiting = { "Waiting", "SilverDim" },
	defeated = { "Defeated", GREEN },
}
local COPY_STRIP = { "LuaSourceContainer", "Sound", "ParticleEmitter", "Beam", "Trail", "Light", "Fire", "Smoke",
	"Sparkles", "LayerCollector", "ProximityPrompt", "ClickDetector", "Animator", "JointInstance", "Constraint",
	"BodyMover", "Explosion", "ForceField", "Highlight", "BillboardGui", "SelectionBox" }
local LOW_TINT = Color3.fromHex("d9767c")
local WHITE = Color3.new(1, 1, 1)

local function commas(n)
	local value = tostring(math.floor(n + 0.5))
	local count
	repeat
		value, count = value:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until count == 0
	return value
end

local function shortNumber(n)
	n = math.abs(n)
	if n >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	return commas(n)
end

local function clockText(seconds)
	seconds = math.max(0, math.floor(seconds + 0.5))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function paint(inst, prop, value)
	if type(value) == "string" then
		S.themed(inst, { [prop] = value })
	else
		S.Themed[inst] = nil
		pcall(function()
			inst[prop] = value
		end)
	end
end

function Library:CreateTargetCard(opts)
	opts = opts or {}
	local card = {
		Enabled = opts.Enabled ~= false,
		Kills = 0,
		Target = nil,
		AutoHide = opts.AutoHide ~= false,
		Scale = math.clamp(tonumber(opts.Scale) or 1, 0.3, 3),
		ShowDistance = opts.ShowDistance ~= false,
		DamageNumbers = opts.DamageNumbers ~= false,
		Dragged = false,
		Offset = 0,
	}
	local WIDTH = math.max(tonumber(opts.Width) or 330, 240)
	local RING = 68
	local FACE = 54
	local INFO_X = 12 + RING + 12
	local CENTER = 12 + RING / 2

	local Holder = S.create("Frame", {
		Name = "TargetCard",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(WIDTH, 140),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 15,
		Parent = S.HudGui,
	})
	local CardScale = S.create("UIScale", { Scale = card.Scale, Parent = Holder })
	local Body = S.create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		ZIndex = 15,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = Holder,
	}, { S.corner(14), S.stroke("BorderLight") })
	pcall(function()
		Body.BackgroundTransparency = 0.04
	end)

	local ring = S.dotRing(Body, RING, 44, 2.5, { Position = UDim2.fromOffset(12, 12), ZIndex = 16 })
	local Face = S.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(CENTER, CENTER),
		Size = UDim2.fromOffset(FACE, FACE),
		ZIndex = 16,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Body,
	}, { S.corner(FACE / 2), S.stroke("BorderLight") })
	local FaceIcon = Library:Icon(Face, opts.Icon or "boss", 22, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 17,
		Theme = { ImageColor3 = "SilverDim" },
	})
	local View = S.create("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(CENTER, CENTER),
		Size = UDim2.fromOffset(FACE - 2, FACE - 2),
		BackgroundTransparency = 1,
		ImageTransparency = 1,
		ImageColor3 = Color3.fromRGB(226, 228, 234),
		Ambient = Color3.fromRGB(150, 152, 160),
		LightColor = Color3.fromRGB(242, 244, 250),
		LightDirection = Vector3.new(0.45, -0.7, 1),
		ZIndex = 17,
		Parent = Holder,
	}, { S.corner((FACE - 2) / 2) })
	local Camera = S.create("Camera", { FieldOfView = 34, Parent = View })
	View.CurrentCamera = Camera

	local Badge = S.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(CENTER, 12 + RING + 1),
		Size = UDim2.fromOffset(0, 15),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		ZIndex = 18,
		BackgroundColor3 = WHITE,
		Parent = Body,
	}, { S.corner(5), S.padding(0, 6, 0, 6) })
	S.silverFill(Badge)
	local BadgeText = S.label({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 15),
		FontFace = S.FontBold,
		TextSize = 9.5,
		ZIndex = 19,
		Theme = { TextColor3 = "KnobOn" },
		Parent = Badge,
	})

	local Info = S.create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(INFO_X, 12),
		Size = UDim2.new(1, -(INFO_X + 12), 0, 77),
		ZIndex = 16,
		Parent = Body,
	})
	local NameText = S.label({
		Size = UDim2.new(1, 0, 0, 18),
		FontFace = S.FontBold,
		TextSize = 14.5,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 16,
		Theme = { TextColor3 = "Text" },
		Parent = Info,
	})
	local Subtitle = S.label({
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 0, 14),
		TextSize = 11.5,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 16,
		Theme = { TextColor3 = "Muted" },
		Parent = Info,
	})
	local Chip = S.create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0.9,
		Visible = false,
		ZIndex = 17,
		Parent = Info,
	}, { S.corner(9), S.padding(0, 8, 0, 7), S.list(5, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local ChipStroke = S.create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Transparency = 0.7,
		Parent = Chip,
	})
	local ChipDot = S.create("Frame", {
		Size = UDim2.fromOffset(5, 5),
		LayoutOrder = 1,
		ZIndex = 18,
		Parent = Chip,
	}, { S.corner(3) })
	local ChipText = S.label({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18),
		FontFace = S.FontSemi,
		TextSize = 10.5,
		LayoutOrder = 2,
		ZIndex = 18,
		Parent = Chip,
	})

	local Bars = S.create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 16,
		Parent = Info,
	}, { S.list(5) })
	local Track = S.create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		LayoutOrder = 1,
		ClipsDescendants = true,
		ZIndex = 16,
		Theme = { BackgroundColor3 = "Off" },
		Parent = Bars,
	}, { S.corner(5), S.stroke("Border") })
	local Lag = S.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.35,
		ZIndex = 17,
		Theme = { BackgroundColor3 = "Danger" },
		Parent = Track,
	}, { S.corner(5) })
	local Fill = S.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		ZIndex = 18,
		BackgroundColor3 = WHITE,
		Parent = Track,
	}, { S.corner(5) })
	S.silverFill(Fill)
	local Gloss = S.create("Frame", {
		Size = UDim2.new(1, 0, 0.5, 0),
		BackgroundTransparency = 1,
		BackgroundColor3 = WHITE,
		ZIndex = 19,
		Parent = Fill,
	}, { S.corner(5) })
	local HpText = S.label({
		Position = UDim2.fromOffset(0, 57),
		Size = UDim2.new(1, -50, 0, 14),
		FontFace = S.FontSemi,
		TextSize = 11.5,
		RichText = true,
		ZIndex = 16,
		Theme = { TextColor3 = "Text" },
		Parent = Info,
	})
	local PctText = S.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 57),
		Size = UDim2.fromOffset(50, 14),
		FontFace = S.FontSemi,
		TextSize = 11.5,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 16,
		Theme = { TextColor3 = "SubText" },
		Parent = Info,
	})

	local Rule = S.create("Frame", {
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 98),
		Size = UDim2.new(1, -24, 0, 1),
		ZIndex = 16,
		Theme = { BackgroundColor3 = "Border" },
		Parent = Body,
	})
	local Stats = S.create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 99),
		Size = UDim2.new(1, -24, 0, 38),
		ZIndex = 16,
		Parent = Body,
	}, { S.list(0, true) })
	local function stat(order, caption)
		local Cell = S.create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.25, 0, 1, 0),
			LayoutOrder = order,
			ZIndex = 16,
			Parent = Stats,
		})
		if order > 1 then
			S.create("Frame", {
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(1, 18),
				ZIndex = 16,
				Theme = { BackgroundColor3 = "Border" },
				Parent = Cell,
			})
		end
		S.label({
			Text = caption,
			Position = UDim2.fromOffset(0, 6),
			Size = UDim2.new(1, 0, 0, 11),
			FontFace = S.FontSemi,
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 16,
			Theme = { TextColor3 = "Muted" },
			Parent = Cell,
		})
		return S.label({
			Text = "--",
			Position = UDim2.fromOffset(0, 18),
			Size = UDim2.new(1, 0, 0, 16),
			FontFace = S.FontSemi,
			TextSize = 12.5,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 16,
			Theme = { TextColor3 = "Text" },
			Parent = Cell,
		})
	end
	local TimeValue = stat(1, "TIME")
	local DpsValue = stat(2, "DPS")
	local EtaValue = stat(3, "ETA")
	local KillValue = stat(4, "KILLS")

	local Pops = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
		Parent = Holder,
	})

	local extra = {}
	local function layout()
		local barsHeight = 10
		for _, bar in pairs(extra) do
			if bar.Frame.Visible then
				barsHeight += 5 + bar.Frame.Size.Y.Offset
			end
		end
		local hpY = 40 + barsHeight + 7
		HpText.Position = UDim2.fromOffset(0, hpY)
		PctText.Position = UDim2.new(1, 0, 0, hpY)
		local infoHeight = math.max(RING + 9, hpY + 14)
		Info.Size = UDim2.new(1, -(INFO_X + 12), 0, infoHeight)
		Rule.Position = UDim2.fromOffset(12, 12 + infoHeight + 9)
		Stats.Position = UDim2.fromOffset(12, 12 + infoHeight + 10)
		Holder.Size = UDim2.fromOffset(WIDTH, 12 + infoHeight + 10 + 38 + 3)
	end
	layout()

	local function fitName()
		local inset = 0
		if Chip.Visible then
			inset = Chip.AbsoluteSize.X / math.max(CardScale.Scale, 0.01) + 8
		end
		NameText.Size = UDim2.new(1, -math.floor(inset + 0.5), 0, 18)
	end

	function card:AddBar(name, barOpts)
		if extra[name] then
			return extra[name]
		end
		barOpts = barOpts or {}
		local Frame = S.create("Frame", {
			Name = tostring(name),
			Size = UDim2.new(1, 0, 0, barOpts.Height or 4),
			LayoutOrder = 10 + #Bars:GetChildren(),
			ClipsDescendants = true,
			Visible = barOpts.Visible ~= false,
			ZIndex = 16,
			Theme = { BackgroundColor3 = "Off" },
			Parent = Bars,
		}, { S.corner(3) })
		local BarFill = S.create("Frame", {
			Size = UDim2.fromScale(math.clamp(tonumber(barOpts.Value) or 0, 0, 1), 1),
			ZIndex = 17,
			Parent = Frame,
		}, { S.corner(3) })
		paint(BarFill, "BackgroundColor3", barOpts.Color or "SilverDim")
		local bar = { Name = name, Frame = Frame, Fill = BarFill, Value = tonumber(barOpts.Value) or 0 }
		function bar:Set(value, max)
			value = tonumber(value) or 0
			max = tonumber(max)
			local ratio = (max and max > 0) and value / max or value
			self.Value = math.clamp(ratio, 0, 1)
			S.tween(BarFill, S.Tween, { Size = UDim2.fromScale(self.Value, 1) })
		end
		function bar:SetVisible(state)
			Frame.Visible = state == true
			layout()
		end
		function bar:SetColor(color)
			paint(BarFill, "BackgroundColor3", color or "SilverDim")
		end
		extra[name] = bar
		layout()
		return bar
	end

	function card:GetBar(name)
		return extra[name]
	end

	local copy, source, sourceRoot, partPairs, head, focus = nil, nil, nil, {}, nil, nil
	local function clearCopy()
		if copy then
			pcall(copy.Destroy, copy)
		end
		copy, source, sourceRoot, partPairs, head, focus = nil, nil, nil, {}, nil, nil
		FaceIcon.Visible = true
	end
	local function buildCopy(model, root)
		clearCopy()
		source, sourceRoot = model, root
		if not (model and root) or opts.Portrait == false then
			return
		end
		local flipped = {}
		local ok, clone = pcall(function()
			for _, object in ipairs(model:GetDescendants()) do
				if not object.Archivable then
					object.Archivable = true
					table.insert(flipped, object)
				end
			end
			local was = model.Archivable
			model.Archivable = true
			local result = model:Clone()
			model.Archivable = was
			return result
		end)
		for _, object in ipairs(flipped) do
			pcall(function()
				object.Archivable = false
			end)
		end
		if not (ok and clone) then
			return
		end
		pcall(function()
			local sourceParts, cloneParts = {}, {}
			for _, object in ipairs(model:GetDescendants()) do
				if object:IsA("BasePart") then
					table.insert(sourceParts, object)
				end
			end
			for _, object in ipairs(clone:GetDescendants()) do
				if object:IsA("BasePart") then
					table.insert(cloneParts, object)
				end
			end
			for index, part in ipairs(sourceParts) do
				local twin = cloneParts[index]
				if twin and twin.Name == part.Name then
					twin.Anchored = true
					twin.CanCollide = false
					table.insert(partPairs, { part, twin })
				end
			end
			for _, object in ipairs(clone:GetDescendants()) do
				for _, className in ipairs(COPY_STRIP) do
					if object:IsA(className) then
						object:Destroy()
						break
					end
				end
			end
			local humanoid = clone:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			end
		end)
		local headPart = model:FindFirstChild("Head", true)
		head = (headPart and headPart:IsA("BasePart")) and headPart or nil
		copy = clone
		copy.Parent = View
		FaceIcon.Visible = false
	end
	local function pose()
		if not (copy and sourceRoot and sourceRoot.Parent) then
			return
		end
		local base = sourceRoot.CFrame
		for _, pair in ipairs(partPairs) do
			local original, twin = pair[1], pair[2]
			if original.Parent then
				twin.CFrame = base:ToObjectSpace(original.CFrame)
				twin.Transparency = original.Transparency
			end
		end
		local target, size
		if head and head.Parent then
			target, size = base:ToObjectSpace(head.CFrame).Position, head.Size.Magnitude
		else
			local ok, boxCFrame, boxSize = pcall(source.GetBoundingBox, source)
			if not ok then
				return
			end
			target = base:ToObjectSpace(boxCFrame).Position + Vector3.new(0, boxSize.Y * 0.4, 0)
			size = math.max(boxSize.X, boxSize.Z) * 0.45
		end
		focus = focus and focus:Lerp(target, 0.25) or target
		local distance = size * 1.15 / math.tan(math.rad(Camera.FieldOfView / 2))
		Camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, size * 0.12, -distance), focus)
	end

	local shown, fadeId = false, 0
	local function setShown(state)
		if state == shown then
			return
		end
		shown = state
		fadeId += 1
		local id = fadeId
		if state then
			Holder.Visible = true
			CardScale.Scale = card.Scale * 0.94
			S.tween(CardScale, S.TweenSmooth, { Scale = card.Scale })
			S.tween(Body, S.Tween, { GroupTransparency = 0 })
			S.tween(View, S.Tween, { ImageTransparency = 0 })
		else
			S.tween(CardScale, S.Tween, { Scale = card.Scale * 0.96 })
			S.tween(Body, S.Tween, { GroupTransparency = 1 })
			S.tween(View, S.Tween, { ImageTransparency = 1 })
			task.delay(0.22, function()
				if fadeId ~= id or Holder.Parent == nil then
					return
				end
				Holder.Visible = false
				CardScale.Scale = card.Scale
				if not card.Target then
					clearCopy()
				end
			end)
		end
	end

	local stateKey, stateColor
	local function paintState(label, color)
		color = color or "Silver"
		ChipText.Text = label or ""
		paint(ChipText, "TextColor3", color)
		paint(ChipDot, "BackgroundColor3", color)
		paint(Chip, "BackgroundColor3", color)
		paint(ChipStroke, "Color", color)
		Chip.Visible = label ~= nil and label ~= ""
		fitName()
	end
	function card:SetState(value, color)
		stateKey, stateColor = value, color
		local known = type(value) == "string" and TARGET_STATES[string.lower(value)]
		if known then
			paintState(known[1], color or known[2])
		else
			paintState(value ~= nil and tostring(value) or nil, color)
		end
	end
	local function isDefeatedState()
		return type(stateKey) == "string" and string.lower(stateKey) == "defeated"
	end

	local health, maxHealth, shownHealth = 0, 1, 0
	local ratioNow, lagRatio, lastDrop = 1, 1, 0
	local engagedAt, samples, lastSample = os.clock(), {}, 0
	local pendingDamage, pendingSince = 0, 0
	local defeatedAt, defeatedModel, defeatedName, lastKillTime = nil, nil, nil, nil
	local pulse = 0
	local shownY = 14
	local autoPos = Holder.Position

	local function damagePop(amount)
		local s = math.max(CardScale.Scale, 0.01)
		local left = (Track.AbsolutePosition.X - Holder.AbsolutePosition.X) / s
		local top = (Track.AbsolutePosition.Y - Holder.AbsolutePosition.Y) / s
		local x = left + Track.AbsoluteSize.X / s * math.clamp(ratioNow, 0.08, 0.92)
		local big = amount >= maxHealth * 0.08
		local Pop = S.label({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromOffset(x, top - 2),
			Size = UDim2.fromOffset(80, 16),
			FontFace = S.FontBold,
			TextSize = big and 15 or 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextStrokeTransparency = 0.6,
			TextStrokeColor3 = Color3.new(0, 0, 0),
			Text = "-" .. shortNumber(amount),
			ZIndex = 21,
			Theme = { TextColor3 = big and "Silver" or "SubText" },
			Parent = Pops,
		})
		local PopScale = S.create("UIScale", { Scale = 0.6, Parent = Pop })
		S.tween(PopScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		S.tween(Pop, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = Pop.Position - UDim2.fromOffset(0, 18) })
		task.delay(0.35, function()
			if Pop.Parent then
				S.tween(Pop, TweenInfo.new(0.45), { TextTransparency = 1, TextStrokeTransparency = 1 })
			end
		end)
		task.delay(0.85, function()
			Pop:Destroy()
		end)
	end

	local function resetStats()
		engagedAt, samples, lastSample = os.clock(), {}, 0
		pendingDamage, pendingSince = 0, 0
		lagRatio, defeatedAt = 1, nil
		shownHealth = health
	end

	local function readTarget(target)
		local humanoid = target.Humanoid
		if humanoid then
			if humanoid.Parent then
				health = math.max(humanoid.Health, 0)
				maxHealth = math.max(humanoid.MaxHealth, 1)
			else
				health = 0
			end
		end
		if target.Model and not target.Model.Parent then
			health = 0
		end
	end

	local function autoY()
		local y = 14
		local base = S.HudGui.AbsolutePosition
		local center = S.HudGui.AbsoluteSize.X / 2
		local half = WIDTH * card.Scale / 2
		for _, name in ipairs({ "OrbitBar", "Watermark" }) do
			local bar = S.HudGui:FindFirstChild(name)
			if bar and bar.Visible then
				local top = bar.AbsolutePosition.Y - base.Y
				local left = bar.AbsolutePosition.X - base.X
				local right = left + bar.AbsoluteSize.X
				if top < 160 and right > center - half and left < center + half then
					y = math.max(y, top + bar.AbsoluteSize.Y + 10)
				end
			end
		end
		return y
	end

	local pressing = false
	S.connect(Body.InputBegan, function(input)
		if S.isPress(input) then
			pressing = true
		end
	end)
	local stopDrag = S.draggable(Body, Holder, function()
		pressing = false
		if Holder.Position ~= autoPos then
			card.Dragged = true
		end
	end)

	local step
	step = function(dt)
		local target = card.Target
		if not target or not Holder.Visible then
			return
		end
		dt = math.min(dt or 0, 0.1)
		readTarget(target)
		pcall(pose)
		local now = os.clock()
		local T = Library.Theme

		if not card.Dragged and not pressing then
			local goal = autoY()
			shownY = dt > 0 and shownY + (goal - shownY) * (1 - math.exp(-dt * 14)) or goal
			if math.abs(shownY - goal) < 0.5 then
				shownY = goal
			end
			autoPos = UDim2.new(0.5, 0, 0, math.floor(shownY + 0.5) + card.Offset)
			Holder.Position = autoPos
		end
		fitName()

		local ratio = math.clamp(health / maxHealth, 0, 1)
		if ratio < ratioNow - 0.0005 then
			if lagRatio - ratioNow < 0.002 then
				lastDrop = now
			end
			pendingDamage += (ratioNow - ratio) * maxHealth
			if pendingSince == 0 then
				pendingSince = now
			end
		end
		if ratio > lagRatio then
			lagRatio = ratio
		end
		ratioNow += (ratio - ratioNow) * (1 - math.exp(-dt * 16))
		if math.abs(ratioNow - ratio) < 0.0005 then
			ratioNow = ratio
		end
		if now - lastDrop > 0.35 then
			lagRatio = math.max(ratioNow, lagRatio - dt * 0.7)
		end
		if pendingDamage > 0 and now - pendingSince > 0.14 then
			if card.DamageNumbers then
				damagePop(pendingDamage)
			end
			pendingDamage, pendingSince = 0, 0
		end
		Fill.Size = UDim2.fromScale(ratioNow, 1)
		Lag.Size = UDim2.fromScale(math.max(lagRatio, ratioNow), 1)
		Lag.Visible = lagRatio - ratioNow > 0.002
		ring:Set(ratioNow, 0.88)
		if ratio <= 0.25 and ratio > 0 then
			pulse += dt * 6
			Fill.BackgroundColor3 = WHITE:Lerp(LOW_TINT, math.clamp((0.25 - ratio) / 0.2, 0, 1) * 0.85)
			Gloss.BackgroundTransparency = 0.88 - 0.14 * (0.5 + 0.5 * math.sin(pulse))
		else
			Fill.BackgroundColor3 = WHITE
			Gloss.BackgroundTransparency = 1
		end

		shownHealth += (health - shownHealth) * (1 - math.exp(-dt * 12))
		if math.abs(shownHealth - health) < 1 then
			shownHealth = health
		end
		HpText.Text = string.format('<font color="#%s">%s</font><font color="#%s"> / %s</font>', T.Text:ToHex(), commas(math.ceil(shownHealth)), T.Muted:ToHex(), commas(math.floor(maxHealth)))
		PctText.Text = string.format("%d%%", math.floor(ratio * 100 + 0.5))

		local subtitle = target.Subtitle and tostring(target.Subtitle) or ""
		if card.ShowDistance and target.Root and target.Root.Parent then
			local character = LocalPlayer and LocalPlayer.Character
			local mine = character and character:FindFirstChild("HumanoidRootPart")
			if mine then
				local meters = math.floor((mine.Position - target.Root.Position).Magnitude + 0.5)
				subtitle = subtitle ~= "" and (subtitle .. "  ·  " .. meters .. "m") or (meters .. "m")
			end
		end
		Subtitle.Text = subtitle

		if health <= 0 and not defeatedAt then
			defeatedAt = now
			defeatedModel = target.Model
			defeatedName = target.Model == nil and target.Name or nil
			card.Kills += 1
			lastKillTime = now - engagedAt
			card:SetState("Defeated")
			S.safe(opts.OnDefeated, target, lastKillTime)
		elseif health > 0 and defeatedAt then
			defeatedAt = nil
			if isDefeatedState() then
				card:SetState(nil)
			end
		end
		if defeatedAt and card.AutoHide and now - defeatedAt > (tonumber(opts.HideDelay) or 1.6) then
			card.Target = nil
			setShown(false)
			return
		end

		if now - lastSample >= 0.2 and not defeatedAt then
			lastSample = now
			table.insert(samples, { t = now, hp = health })
			while #samples > 2 and now - samples[1].t > 6 do
				table.remove(samples, 1)
			end
		end
		local dps
		local first = samples[1]
		if first and now - first.t >= 1 then
			local lost = first.hp - health
			dps = lost > 0 and lost / (now - first.t) or 0
		end
		TimeValue.Text = defeatedAt and clockText(lastKillTime or 0) or clockText(now - engagedAt)
		DpsValue.Text = dps and shortNumber(dps) or "--"
		EtaValue.Text = defeatedAt and "0:00" or ((dps and dps > 0) and clockText(health / dps) or "--")
		KillValue.Text = tostring(card.Kills)
	end
	S.loop(step)
	card._step = step

	function card:SetTarget(target)
		if typeof(target) == "Instance" then
			local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
			target = { Model = model or target }
		end
		if type(target) ~= "table" then
			self.Target = nil
			if self.AutoHide then
				setShown(false)
			end
			return
		end
		local model = target.Model
		if model and model == defeatedModel and not self.Target then
			local humanoid = target.Humanoid or model:FindFirstChildOfClass("Humanoid")
			if not model.Parent or not humanoid or humanoid.Health <= 0 then
				return
			end
		elseif not model and not self.Target and defeatedName ~= nil and target.Name == defeatedName and tonumber(target.Health) and tonumber(target.Health) <= 0 then
			return
		end
		target.Humanoid = target.Humanoid or (model and model:FindFirstChildOfClass("Humanoid"))
		target.Root = target.Root or (model and (model:FindFirstChild("HumanoidRootPart") or (model:IsA("Model") and model.PrimaryPart) or (model:IsA("BasePart") and model) or model:FindFirstChildWhichIsA("BasePart")))
		target.Name = target.Name or (model and model.Name) or "Target"
		local same = self.Target ~= nil and model ~= nil and self.Target.Model == model
		if not same and self.Target and model == nil and self.Target.Model == nil and self.Target.Name == target.Name and defeatedAt == nil then
			same = true
		end
		self.Target = target
		if target.Health then
			health = math.max(tonumber(target.Health) or 0, 0)
		end
		if target.MaxHealth then
			maxHealth = math.max(tonumber(target.MaxHealth) or 1, 1)
		end
		readTarget(target)
		if not same then
			buildCopy(model, target.Root)
			resetStats()
			ratioNow = math.clamp(health / maxHealth, 0, 1)
			lagRatio = ratioNow
			if isDefeatedState() then
				self:SetState(nil)
			end
		end
		NameText.Text = tostring(target.Name)
		Badge.Visible = target.Badge ~= nil
		BadgeText.Text = target.Badge and string.upper(tostring(target.Badge)) or ""
		FaceIcon.Visible = copy == nil
		Library:SetIcon(FaceIcon, target.Icon or opts.Icon or "boss")
		if self.Enabled then
			setShown(true)
		end
		if not same then
			shownHealth = health
			if not card.Dragged then
				shownY = autoY()
			end
			step(0)
		end
	end

	function card:SetHealth(value, max)
		health = math.max(tonumber(value) or 0, 0)
		if max then
			maxHealth = math.max(tonumber(max) or 1, 1)
		end
	end

	function card:SetEnabled(state)
		self.Enabled = state ~= false
		setShown(self.Enabled and self.Target ~= nil)
	end

	function card:SetScale(scale)
		self.Scale = math.clamp(tonumber(scale) or 1, 0.3, 3)
		CardScale.Scale = self.Scale
	end

	function card:ResetPosition()
		self.Dragged = false
		shownY = autoY()
		autoPos = UDim2.new(0.5, 0, 0, math.floor(shownY + 0.5) + self.Offset)
		Holder.Position = autoPos
	end

	function card:ResetKills()
		self.Kills = 0
		KillValue.Text = "0"
	end

	function card:Destroy()
		S.unloop(step)
		stopDrag()
		self.Target = nil
		clearCopy()
		Holder:Destroy()
		if Library.TargetCard == self then
			Library.TargetCard = nil
		end
	end

	function card:AddSettings(group, prefix)
		prefix = prefix or "TargetCard"
		local toggle = group:AddToggle(prefix, {
			Text = opts.Title or "Target card",
			Default = card.Enabled,
			Orbit = false,
			Callback = function(enabled)
				card:SetEnabled(enabled)
			end,
		})
		group:AddToggle(prefix .. "Damage", {
			Text = "Damage numbers",
			Default = card.DamageNumbers,
			Orbit = false,
			Callback = function(enabled)
				card.DamageNumbers = enabled
			end,
		})
		group:AddSlider(prefix .. "Scale", {
			Text = "Card scale",
			Min = 50,
			Max = 200,
			Default = math.floor(card.Scale * 100 + 0.5),
			Suffix = "%",
			Callback = function(value)
				card:SetScale(value / 100)
			end,
		})
		group:AddButton({
			Label = "Card position",
			Text = "Reset",
			Func = function()
				card:ResetPosition()
			end,
		})
		return toggle
	end

	card:SetState(opts.State)
	TimeValue.Text = "0:00"
	KillValue.Text = "0"
	card.Frame = Holder
	self.TargetCard = card
	table.insert(S.UnloadCallbacks, clearCopy)
	return card
end
