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

local activeNotes = {}

function Library:Notify(title, text, duration, icon)
	if type(title) == "table" then
		local o = title
		title, text, duration, icon = o.Title, o.Text or o.Description or o.Content, o.Time or o.Duration, o.Icon
	end
	if not self.NotifyEnabled or self.Unloaded then
		return
	end
	if text == nil or (type(text) == "number" and duration == nil) then
		duration = duration or (type(text) == "number" and text or nil)
		text, title = title, "Saturn"
	end
	duration = tonumber(duration) or 4
	while #activeNotes >= 5 do
		table.remove(activeNotes, 1).Close()
	end
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
	local note = {}
	local step
	local function close()
		if not alive then
			return
		end
		alive = false
		local i = table.find(activeNotes, note)
		if i then
			table.remove(activeNotes, i)
		end
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
	note.Close = close
	table.insert(activeNotes, note)
	return note
end
