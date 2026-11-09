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
	local _, _, _, setDesc = S.textBlock(Row, options.Text or tostring(id), options.Description, 170)
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
	S.register(id, dropdown, "Dropdown", options)
	function dropdown:SetDescription(value)
		setDesc(value)
	end

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
	local Popup
	local function display()
		local text, empty = summary()
		Shown.Text = text
		if multi and Popup and Popup.CountLabel then
			local n = 0
			for _ in pairs(dropdown.Value) do
				n += 1
			end
			Popup.CountLabel.Text = n .. " / " .. #dropdown.Values
		end
		S.themed(Shown, { TextColor3 = empty and "Muted" or "Text" })
	end

	Popup = { Frame = S.popupFrame() }
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
		local searchable = options.Searchable ~= false and (options.Searchable or #dropdown.Values > (options.MaxVisible or 8))
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
		if multi then
			local Bar = S.create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, top),
				Size = UDim2.new(1, -18, 0, 22),
				ZIndex = 61,
				Parent = frame,
			})
			Popup.CountLabel = S.label({
				Text = "",
				FontFace = S.FontSemi,
				TextSize = 10.5,
				Size = UDim2.new(1, -100, 1, 0),
				ZIndex = 61,
				Theme = { TextColor3 = "Muted" },
				Parent = Bar,
			})
			local Actions = S.create("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				ZIndex = 61,
				Parent = Bar,
			}, { S.list(4, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
			local function action(text, order, fn)
				local Button = S.create("TextButton", {
					Text = text,
					AutoButtonColor = false,
					FontFace = S.FontSemi,
					TextSize = 11,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 20),
					LayoutOrder = order,
					ZIndex = 62,
					Theme = { BackgroundColor3 = "Field", TextColor3 = "SubText" },
					Parent = Actions,
				}, { S.corner(5), S.stroke("BorderLight"), S.padding(0, 8, 0, 8) })
				S.connect(Button.MouseButton1Click, fn)
			end
			action("All", 1, function()
				local set = {}
				for _, v in ipairs(dropdown.Values) do
					set[v] = true
				end
				dropdown:SetValue(set)
				buildList(SearchBox and SearchBox.Text or "")
			end)
			action("Clear", 2, function()
				dropdown:SetValue({})
				buildList(SearchBox and SearchBox.Text or "")
			end)
			top += 26
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
		local count = math.min(#dropdown.Values, options.MaxVisible or 8)
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
			local same = true
			for k in pairs(set) do
				if not self.Value[k] then
					same = false
				end
			end
			for k in pairs(self.Value) do
				if not set[k] then
					same = false
				end
			end
			self.Value = set
			if same then
				display()
				return
			end
		else
			if value == nil and not self.AllowNull then
				value = self.Values[1]
			end
			if value == self.Value then
				display()
				return
			end
			self.Value = value
		end
		display()
		S.fire(self)
	end
	function dropdown:SetValues(values)
		self.Values = values or {}
		if multi then
			for k in pairs(self.Value) do
				if not table.find(self.Values, k) then
					self.Value[k] = nil
				end
			end
		else
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
local MODIFIERS = { LeftControl = true, RightControl = true, LeftAlt = true, RightAlt = true, LeftShift = true, RightShift = true }
local KEY_ALIASES = { MB1 = "MouseButton1", MB2 = "MouseButton2", MB3 = "MouseButton3", [""] = "None" }
S.KeybindList = {}
S.Picking = false
S.refreshKeybindList = function() end

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
		Hidden = options.ShowInList == false,
	}, { __index = OptionBase })
	S.register(id, bind, "KeyPicker", options)
	bind.Chip = Chip
	if type(bind.Value) ~= "string" then
		bind.Value = typeof(bind.Value) == "EnumItem" and bind.Value.Name or "None"
	end
	bind.Value = KEY_ALIASES[bind.Value] or bind.Value
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
		self.Value = KEY_ALIASES[self.Value] or self.Value
		if self.Mode == "Always" and self.Toggle and not self.Toggle.Value then
			self.Toggle:SetValue(true)
		end
		display()
		for _, fn in ipairs(self.Changed) do
			S.safe(fn, self.Value)
		end
		S.refreshKeybindList()
	end
	function bind:GetState()
		if self.Mode == "Always" then
			return true
		end
		if self.Mode == "Press" then
			return self.PulseUntil ~= nil and os.clock() < self.PulseUntil
		end
		if self.Toggle then
			return self.Toggle.Value
		end
		return self.State
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
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
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
		local modes = { "Toggle", "Hold", "Press", "Always" }
		local i = table.find(modes, bind.Mode) or 1
		bind.Mode = modes[i % #modes + 1]
		if bind.Mode == "Always" and bind.Toggle then
			bind.Toggle:SetValue(true)
		end
		Library:Notify("Keybind", bind.Text .. ": " .. bind.Mode, 2, "keybinds")
		for _, fn in ipairs(bind.Changed) do
			S.safe(fn, bind.Value)
		end
		S.refreshKeybindList()
	end)
	S.connect(UserInputService.InputBegan, function(input)
		if picking or S.Picking or bind.Value == "None" or bind.Mode == "Always" or S.typing() then
			return
		end
		if keyFromInput(input) ~= bind.Value then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and not MODIFIERS[bind.Value] then
			for _, mod in ipairs({ Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl, Enum.KeyCode.LeftAlt, Enum.KeyCode.RightAlt }) do
				if UserInputService:IsKeyDown(mod) then
					return
				end
			end
		end
		local toggle = bind.Toggle
		if bind.Mode == "Hold" then
			bind.State = true
			if toggle then
				toggle:SetValue(true)
			end
			S.safe(bind.Callback, true)
		elseif bind.Mode == "Press" and not toggle then
			bind.PulseUntil = os.clock() + 0.3
			task.delay(0.32, S.refreshKeybindList)
			S.safe(bind.Callback)
		else
			if toggle then
				toggle:SetValue(not toggle.Value)
				S.safe(bind.Callback, toggle.Value)
			else
				bind.State = not bind.State
				S.safe(bind.Callback, bind.State)
			end
		end
		S.safe(bind.Clicked)
		S.refreshKeybindList()
	end)
	S.connect(UserInputService.InputEnded, function(input)
		if bind.Mode ~= "Hold" or not bind.State or keyFromInput(input) ~= bind.Value then
			return
		end
		bind.State = false
		if bind.Toggle then
			bind.Toggle:SetValue(false)
		end
		S.safe(bind.Callback, false)
		S.refreshKeybindList()
	end)
	display()
	table.insert(S.KeybindList, bind)
	return bind
end

function Groupbox:AddKeybind(id, options)
	options = options or {}
	local Row = S.row(self, 30)
	local _, _, _, setDesc = S.textBlock(Row, options.Text or tostring(id), options.Description, 90)
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
	function bind:SetDescription(value)
		setDesc(value)
	end
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
	S.register(id, picker, "ColorPicker", options)
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
	local hasAlpha = options.Transparency ~= nil
	local Alpha, AlphaFill, AlphaCursor
	if hasAlpha then
		Alpha = S.create("ImageButton", {
			AutoButtonColor = false,
			Image = "",
			Position = UDim2.fromOffset(10, 180),
			Size = UDim2.new(1, -20, 0, 12),
			ZIndex = 61,
			Theme = { BackgroundColor3 = "Field" },
			Parent = frame,
		}, { S.corner(5), S.stroke("BorderLight") })
		AlphaFill = S.create("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = picker.Value,
			ZIndex = 62,
			Parent = Alpha,
		}, { S.corner(5) })
		S.create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = AlphaFill })
		AlphaCursor = S.create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(picker.Transparency, 0.5),
			Size = UDim2.new(0, 4, 1, 4),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 63,
			Parent = Alpha,
		}, { S.corner(2) })
	end
	local HexField = S.create("Frame", {
		Position = UDim2.fromOffset(10, hasAlpha and 200 or 180),
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
		Swatch.BackgroundTransparency = math.clamp(picker.Transparency or 0, 0, 0.85)
		if hasAlpha then
			AlphaFill.BackgroundColor3 = picker.Value
			AlphaCursor.Position = UDim2.fromScale(picker.Transparency or 0, 0.5)
		end
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
		S.fire(picker, picker.Transparency)
	end
	function picker:SetValueRGB(color, transparency)
		self.Value = color
		if transparency then
			self.Transparency = transparency
		end
		h, s, v = color:ToHSV()
		display()
		S.fire(self, self.Transparency)
	end
	function picker:SetValue(hsv, transparency)
		if typeof(hsv) == "Color3" then
			return self:SetValueRGB(hsv, transparency)
		end
		if type(hsv) == "string" then
			local ok, color = pcall(Color3.fromHex, (hsv:gsub("#", "")))
			if ok then
				return self:SetValueRGB(color, transparency)
			end
			return
		end
		if type(hsv) == "table" then
			local hex = hsv.hex or hsv.Hex
			if hex then
				return self:SetValue(hex, transparency or hsv.transparency or hsv.Transparency)
			end
			local r, g, b = hsv.R or hsv.r, hsv.G or hsv.g, hsv.B or hsv.b
			if not r and ((tonumber(hsv[1]) or 0) > 1 or (tonumber(hsv[2]) or 0) > 1 or (tonumber(hsv[3]) or 0) > 1) then
				r, g, b = hsv[1], hsv[2], hsv[3]
			end
			if r and g and b then
				local scale = (r > 1 or g > 1 or b > 1) and 255 or 1
				return self:SetValueRGB(Color3.new(r / scale, g / scale, b / scale), transparency)
			end
			h, s, v = hsv[1] or h, hsv[2] or s, hsv[3] or v
		end
		if transparency then
			self.Transparency = transparency
		end
		commit()
	end
	local dragSquare, dragHue, dragAlpha = nil, nil, nil
	local function fromAlpha(input)
		picker.Transparency = math.clamp((input.Position.X - Alpha.AbsolutePosition.X) / math.max(Alpha.AbsoluteSize.X, 1), 0, 1)
		picker.Transparency = math.floor(picker.Transparency * 100 + 0.5) / 100
		display()
		S.fire(picker, picker.Transparency)
	end
	if hasAlpha then
		S.connect(Alpha.InputBegan, function(input)
			if S.isPress(input) and not dragSquare and not dragHue then
				dragAlpha = input
				fromAlpha(input)
			end
		end)
	end
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
		elseif dragAlpha and S.isMove(input, dragAlpha) then
			fromAlpha(input)
		end
	end)
	S.connect(UserInputService.InputEnded, function(input)
		local held = dragSquare or dragHue or dragAlpha
		if held and (input == held or input.UserInputType == Enum.UserInputType.MouseButton1 and held.UserInputType == Enum.UserInputType.MouseButton1) then
			dragSquare, dragHue, dragAlpha = nil, nil, nil
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
		S.openPopup(Popup, Swatch, 220, hasAlpha and 236 or 216)
	end)
	display()
	return picker
end

function Groupbox:AddColorPicker(id, options)
	options = options or {}
	local Row = S.row(self, 30)
	local _, _, _, setDesc = S.textBlock(Row, options.Text or options.Title or tostring(id), options.Description, 50)
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
	function picker:SetDescription(value)
		setDesc(value)
	end
	S.index(self, options.Text or options.Title or tostring(id), Row)
	return picker
end
