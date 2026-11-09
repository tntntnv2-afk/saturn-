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
	local function setDesc(value)
		value = value and tostring(value) or ""
		if Desc then
			Desc.Text = value
			Desc.Visible = value ~= ""
			return
		end
		if value == "" then
			return
		end
		Desc = S.label({
			Text = value,
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
		Holder.Size = UDim2.new(Holder.Size.X.Scale, Holder.Size.X.Offset, 0, 0)
		parent.Size = UDim2.new(1, 0, 0, 0)
		S.create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = parent })
	end
	setDesc(description)
	return Label, Desc, Holder, setDesc
end

function S.chainAddons(addon, owner)
	function addon:AddKeybind(...)
		return owner:AddKeybind(...)
	end
	function addon:AddColorPicker(...)
		return owner:AddColorPicker(...)
	end
	return addon
end

function S.register(id, option, kind, options)
	option.Type = kind
	option.Id = id
	option.Changed = option.Changed or {}
	if options and options.Save == false then
		option.Save = false
	end
	if id ~= nil then
		if Library.Options[id] then
			warn("[Saturn] duplicate option id " .. tostring(id))
		end
		Library.Options[id] = option
		if kind == "Toggle" then
			Library.Toggles[id] = option
		end
	end
	return option
end

function S.fire(option, ...)
	S.safe(option.Callback, option.Value, ...)
	for _, fn in ipairs(option.Changed) do
		S.safe(fn, option.Value, ...)
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

function Groupbox:Expand()
	return self
end

function Groupbox:SetTitle(text)
	self.Name = tostring(text)
	self.Header.Text = string.upper(self.Name)
end

function Groupbox:AddDivider(text)
	if text and text ~= "" then
		local Row = S.row(self, 26)
		local function line(left)
			local Line = S.create("Frame", {
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(left and 0 or 1, 0.5),
				Position = UDim2.fromScale(left and 0 or 1, 0.5),
				Size = UDim2.new(0.5, -(S.textWidth(text, 11, S.FontSemi) / 2 + 10), 0, 1),
				ZIndex = 2,
				Theme = { BackgroundColor3 = "BorderLight" },
				Parent = Row,
			})
			S.create("UIGradient", {
				Transparency = NumberSequence.new(left and 1 or 0, left and 0 or 1),
				Parent = Line,
			})
		end
		line(true)
		line(false)
		S.label({
			Text = string.upper(tostring(text)),
			FontFace = S.FontSemi,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
			Theme = { TextColor3 = "Muted" },
			Parent = Row,
		})
		return Row
	end
	local Row = S.row(self, 9)
	local Line = S.create("Frame", {
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "BorderLight" },
		Parent = Row,
	})
	S.create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = Line,
	})
	return Row
end

function Groupbox:AddLabel(text, wrap)
	local Row = S.row(self, 22)
	local Label = S.label({
		Text = tostring(text or ""),
		TextSize = 12.5,
		TextWrapped = wrap ~= false,
		RichText = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
		Theme = { TextColor3 = "SubText" },
		Parent = Row,
	})
	Row.Size = UDim2.new(1, 0, 0, 0)
	Row.AutomaticSize = Enum.AutomaticSize.Y
	S.create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = Row })
	local box = self
	local Right
	local object = { Row = Row, Label = Label, Text = tostring(text or "") }
	local function slots()
		if not Right then
			Right = S.create("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				ZIndex = 3,
				Parent = Row,
			}, { S.list(6, true, { HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center }) })
			S.connect(Right:GetPropertyChangedSignal("AbsoluteSize"), function()
				local scale = S.Window and math.max(S.Window.ScaleObject.Scale, 0.1) or 1
				Label.Size = UDim2.new(1, -(Right.AbsoluteSize.X / scale + 10), 0, 0)
			end)
			Label.Size = UDim2.new(1, -40, 0, 0)
		end
		return Right
	end
	function object:SetText(value)
		self.Text = tostring(value)
		Label.Text = self.Text
	end
	function object:SetVisible(on)
		Row.Visible = on
	end
	function object:AddColorPicker(id, options)
		options = options or {}
		options.Parent = slots()
		options.Title = options.Title or object.Text
		return S.chainAddons(S.makeColorPicker(box, id, options), object)
	end
	function object:AddKeybind(id, options)
		options = options or {}
		options.Parent = slots()
		options.Text = options.Text or object.Text
		return S.chainAddons(S.makeKeybind(box, id, options), object)
	end
	return object
end

function Groupbox:AddCustom(height)
	local Row = S.row(self, height or 120)
	return S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = Row,
	})
end

function Groupbox:AddStats(stats)
	stats = stats or {}
	local Row = S.row(self, 52)
	local Strip = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = Row,
	}, { S.list(6, true) })
	local count = math.max(#stats, 1)
	local cells = {}
	for i, stat in ipairs(stats) do
		local Cell = S.create("Frame", {
			Size = UDim2.new(1 / count, -math.ceil(6 * (count - 1) / count), 1, 0),
			LayoutOrder = i,
			ZIndex = 2,
			Theme = { BackgroundColor3 = "Field" },
			Parent = Strip,
		}, { S.corner(8), S.stroke("BorderLight"), S.padding(7, 9, 6, 9) })
		local name = stat.Label or stat[1] or ""
		S.label({
			Text = string.upper(tostring(name)),
			FontFace = S.FontSemi,
			TextSize = 10,
			Size = UDim2.new(1, 0, 0, 13),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 2,
			Theme = { TextColor3 = "Muted" },
			Parent = Cell,
		})
		local Value = S.label({
			Text = tostring(stat.Value or stat[2] or "0"),
			FontFace = S.FontSemi,
			TextSize = 15,
			TextScaled = true,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 20),
			ZIndex = 2,
			Theme = { TextColor3 = stat.Accent and "Silver" or "Text" },
			Parent = Cell,
		})
		S.create("UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 9, Parent = Value })
		if stat.Accent then
			Value.FontFace = S.FontBold
		end
		cells[i] = Value
		cells[name] = Value
	end
	local object = { Row = Row }
	function object:Set(key, value)
		local label = cells[key]
		if label then
			label.Text = tostring(value)
		end
	end
	function object:SetVisible(on)
		Row.Visible = on
	end
	return object
end

function Groupbox:AddProgress(id, options)
	if type(id) == "table" then
		id, options = nil, id
	end
	options = options or {}
	local Row = S.row(self, 36)
	local Label = S.label({
		Text = tostring(options.Text or id or ""),
		TextSize = 13,
		Size = UDim2.new(1, -60, 0, 20),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Theme = { TextColor3 = "SubText" },
		Parent = Row,
	})
	local Percent = S.label({
		Text = "",
		FontFace = S.FontSemi,
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(60, 20),
		ZIndex = 2,
		Theme = { TextColor3 = "Text" },
		Parent = Row,
	})
	local Bar = S.create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -4),
		Size = UDim2.new(1, 0, 0, 6),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Off" },
		Parent = Row,
	}, { S.corner(3) })
	local Fill = S.create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = Bar,
	}, { S.corner(3) })
	S.silverFill(Fill)
	local object = { Value = 0, Row = Row }
	function object:SetValue(value, instant)
		value = math.clamp(tonumber(value) or 0, 0, 1)
		self.Value = value
		Percent.Text = options.Format and tostring(options.Format(value)) or (math.floor(value * 100 + 0.5) .. "%")
		if instant then
			Fill.Size = UDim2.fromScale(value, 1)
		else
			S.tween(Fill, S.TweenSmooth, { Size = UDim2.fromScale(value, 1) })
		end
	end
	function object:SetText(value)
		Label.Text = tostring(value or "")
	end
	function object:SetVisible(on)
		Row.Visible = on
	end
	object:SetValue(options.Value or options.Default or 0, true)
	S.index(self, options.Text or id or "Progress", Row)
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
	local describe
	if options.Label then
		Row = S.row(self, ROW_H + 2)
		local width = math.max(S.textWidth(text, 12.5, S.FontSemi) + 24, 64)
		local _, _, _, setDesc = S.textBlock(Row, options.Label, options.Description, width + 10)
		describe = setDesc
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
	function object:SetDescription(value)
		if describe then
			describe(value)
		end
	end
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
	local Label, _, TextHolder, setDesc = S.textBlock(Row, options.Text or tostring(id), options.Description, 48)
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
	S.register(id, toggle, "Toggle", options)

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

	function toggle:SetDescription(value)
		setDesc(value)
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
		if #self.Addons > 0 then
			S.refreshKeybindList()
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
		return S.chainAddons(bind, self)
	end
	function toggle:AddColorPicker(colorId, colorOptions)
		colorOptions = colorOptions or {}
		colorOptions.Parent = Right
		colorOptions.Title = colorOptions.Title or self.Text
		local picker = S.makeColorPicker(self.Groupbox, colorId, colorOptions)
		table.insert(self.Addons, picker)
		return S.chainAddons(picker, self)
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
	S.register(id, slider, "Slider", options)

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
	local titled = options.Text ~= nil and options.Text ~= ""
	local setDesc = function() end
	if titled then
		setDesc = select(4, S.textBlock(Row, options.Text, options.Description, 160))
	end
	local Field = S.create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = titled and UDim2.new(0.5, 0, 0, 26) or UDim2.new(1, 0, 0, 28),
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
	S.register(id, input, "Input", options)
	function input:SetDescription(value)
		setDesc(value)
	end
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
