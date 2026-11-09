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
