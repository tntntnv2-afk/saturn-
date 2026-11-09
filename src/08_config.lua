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
		if not option.NoConfig and option.Save ~= false and type(id) == "string" then
			local value = serialize(option)
			if value ~= nil then
				data[id] = value
			end
		end
	end
	S.ensureFolder(self.Folder .. "/configs")
	local count = 0
	for _ in pairs(data) do
		count += 1
	end
	local ok, err = pcall(writefile, configPath(name), HttpService:JSONEncode({ saturn = 1, options = data }))
	if not ok then
		return false, tostring(err)
	end
	if S.refreshConfigList then
		S.refreshConfigList()
	end
	self.CurrentConfig = name
	return true, name, count
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
	local count = 0
	for pass = 1, 2 do
		for id, value in pairs(options) do
			local option = self.Options[id]
			if option and not option.NoConfig and option.Save ~= false and (option.Type == "Toggle") == (pass == 2) then
				if pcall(apply, option, value) then
					count += 1
				end
			end
		end
	end
	self.CurrentConfig = name
	return true, count
end

function Library:DeleteConfig(name)
	local path = configPath(name)
	if hasFiles() and type(delfile) == "function" and isfile(path) then
		local ok, err = pcall(delfile, path)
		if S.refreshConfigList then
			S.refreshConfigList()
		end
		return ok, err
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
	local ok, err = pcall(writefile, self.Folder .. "/autoload.txt", tostring(name or ""))
	if S.refreshConfigList then
		S.refreshConfigList()
	end
	return ok, err
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

function Library:SetSilentLoad(on)
	if not hasFiles() then
		return false
	end
	S.ensureFolder(self.Folder)
	return pcall(writefile, self.Folder .. "/silent_load.txt", on and "1" or "0")
end

function Library:GetSilentLoad()
	if not hasFiles() then
		return false
	end
	local path = self.Folder .. "/silent_load.txt"
	local ok, value = pcall(function()
		return isfile(path) and readfile(path) or "0"
	end)
	return ok and value == "1"
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
		watermark = Library.WatermarkEnabled,
		keybindList = Library.KeybindListEnabled,
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

local function iconButton(parent, icon, props)
	props = props or {}
	local size = props.Size or 26
	local Button = S.create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Position = props.Position or UDim2.new(),
		Size = UDim2.fromOffset(size, size),
		LayoutOrder = props.LayoutOrder or 0,
		BackgroundTransparency = props.Filled and 0 or 1,
		ZIndex = 3,
		Theme = { BackgroundColor3 = props.Filled and "Field" or "FieldHover" },
		Parent = parent,
	}, { S.corner(7) })
	local Edge = S.stroke("BorderLight")
	Edge.Parent = Button
	Edge.Enabled = props.Filled == true
	local Glyph = Library:Icon(Button, icon, props.IconSize or 13, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 3,
		Theme = { ImageColor3 = props.Lit and "Silver" or "Muted" },
	})
	local state = { hot = false, lit = props.Lit == true, danger = false }
	local function paint()
		local T = Library.Theme
		local color = state.danger and T.Danger or ((state.lit or state.hot) and (state.hot and T.Text or T.Silver) or T.Muted)
		S.tween(Glyph, S.TweenFast, { ImageColor3 = color })
		S.Themed[Glyph] = nil
		if not props.Filled then
			S.tween(Button, S.TweenFast, { BackgroundTransparency = state.hot and 0 or 1 })
		end
	end
	S.bind(Button.MouseEnter, function()
		state.hot = true
		paint()
	end)
	S.bind(Button.MouseLeave, function()
		state.hot = false
		paint()
	end)
	return Button, function(key, value)
		state[key] = value
		paint()
	end
end
S.iconButton = iconButton

function Library:BuildSettingsTab(window, options, section)
	if type(options) ~= "table" then
		options = { Name = options, Section = section }
	end
	window = window or S.Window
	if options.Section ~= false and window.Section ~= (options.Section or "Other") then
		window:AddSection(options.Section or "Other")
	end
	local saved = S.loadMenu() or {}
	local tab = window:AddTab(options.Name or "Settings", "settings")
	local Menu = tab:AddLeftGroupbox("Menu")
	local key = Menu:AddKeybind("Saturn_MenuKey", {
		Text = "Menu key",
		Default = saved.key or (self.ToggleKey and self.ToggleKey.Name) or "RightControl",
		Mode = "Press",
		ShowInList = false,
	})
	key.NoConfig = true
	local function applyKey(value)
		local code = value and value ~= "None" and S.keyCode(value)
		if code then
			self.ToggleKey = code
		else
			local keep = self.ToggleKey or Enum.KeyCode.RightControl
			task.defer(function()
				key:SetValue(keep.Name)
			end)
			return
		end
		S.saveMenu()
	end
	key:OnChanged(applyKey)
	applyKey(key.Value)
	local keyList = Menu:AddToggle("Saturn_KeybindList", { Text = "Keybind list", Default = saved.keybindList == true })
	keyList.NoConfig, keyList.Orbit = true, false
	keyList:OnChanged(function(v)
		self:SetKeybindList(v)
		S.saveMenu()
	end)
	self:SetKeybindList(keyList.Value)
	local mark = Menu:AddToggle("Saturn_Watermark", { Text = "Watermark", Default = saved.watermark == true })
	mark.NoConfig, mark.Orbit = true, false
	mark:OnChanged(function(v)
		self:SetWatermark(v)
		S.saveMenu()
	end)
	self:SetWatermark(mark.Value)
	if hasFiles() then
		local silent = Menu:AddToggle("Saturn_SilentLoad", { Text = "Silent load", Default = self:GetSilentLoad() })
		silent.NoConfig, silent.Orbit = true, false
		silent:OnChanged(function(v)
			self:SetSilentLoad(v)
		end)
	end
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
	local bar = Menu:AddToggle("Saturn_OrbitBar", { Text = "Active orbit bar", Default = saved.orbitBar ~= false })
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
	Menu:AddDivider()
	Menu:AddButton({ Text = "Unload Saturn", DoubleClick = true, Func = function()
		self:Unload()
	end })

	local Configs = tab:AddRightGroupbox("Configs")
	if not hasFiles() then
		Configs:AddLabel("This executor can't save files.")
		return tab
	end
	local function say(message)
		self:Notify("Configs", message, 3, "config")
	end

	local NameRow = S.row(Configs, 30)
	local NameField = S.create("Frame", {
		Size = UDim2.new(1, -38, 1, 0),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Field" },
		Parent = NameRow,
	}, { S.corner(7), S.stroke("BorderLight") })
	local NameBox = S.create("TextBox", {
		Text = "",
		PlaceholderText = "New config",
		ClearTextOnFocus = false,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		FontFace = S.Font,
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
		ZIndex = 2,
		Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
		Parent = NameField,
	})
	local CreateButton = iconButton(NameRow, "plus", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = 30,
		IconSize = 15,
		Filled = true,
	})
	S.index(Configs, "Create config", NameRow)

	local Head = S.row(Configs, 24)
	local HeadText = S.label({
		Text = "",
		FontFace = S.FontSemi,
		TextSize = 10.5,
		Size = UDim2.new(1, -30, 1, 0),
		ZIndex = 2,
		Theme = { TextColor3 = "Muted" },
		Parent = Head,
	})
	local RefreshButton = iconButton(Head, "refresh-cw", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = 22,
		IconSize = 12,
	})
	local ListRow = S.row(Configs, 0)
	ListRow.AutomaticSize = Enum.AutomaticSize.Y
	local ListFrame = S.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
		Parent = ListRow,
	}, { S.list(5) })

	local rows = {}
	local refresh
	local function configRow(name, index, isAuto)
		local Row = S.create("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			LayoutOrder = index,
			ZIndex = 2,
			Theme = { BackgroundColor3 = "Field" },
			Parent = ListFrame,
		}, { S.corner(8), S.stroke(isAuto and "SilverDim" or "BorderLight") })
		Library:Icon(Row, "folder", 13, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 11, 0.5, 0),
			ZIndex = 2,
			Theme = { ImageColor3 = isAuto and "Silver" or "Muted" },
		})
		S.label({
			Text = name,
			FontFace = S.FontSemi,
			TextSize = 12.5,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(32, 0),
			Size = UDim2.new(1, -150, 1, 0),
			ZIndex = 2,
			Theme = { TextColor3 = isAuto and "Silver" or "Text" },
			Parent = Row,
		})
		local Actions = S.create("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -5, 0.5, 0),
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			ZIndex = 2,
			Parent = Row,
		}, { S.list(2, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
		local Load = iconButton(Actions, "play", { LayoutOrder = 1 })
		local Save = iconButton(Actions, "save", { LayoutOrder = 2 })
		local Star = iconButton(Actions, "star", { LayoutOrder = 3, Lit = isAuto })
		local Delete, setDelete = iconButton(Actions, "trash-2", { LayoutOrder = 4 })
		S.bind(Load.MouseButton1Click, function()
			local ok, result = self:LoadConfig(name)
			say(ok and ("Loaded " .. name .. " (" .. tostring(result) .. ")") or tostring(result))
		end)
		S.bind(Save.MouseButton1Click, function()
			local ok, result, count = self:SaveConfig(name)
			say(ok and ("Saved " .. name .. " (" .. tostring(count) .. ")") or tostring(result))
			refresh()
		end)
		S.bind(Star.MouseButton1Click, function()
			if isAuto then
				self:SetAutoload("")
				say(name .. " won't load on start")
			else
				self:SetAutoload(name)
				say(name .. " loads on start")
			end
			refresh()
		end)
		local armedUntil = 0
		S.bind(Delete.MouseButton1Click, function()
			if os.clock() > armedUntil then
				armedUntil = os.clock() + 2.5
				setDelete("danger", true)
				task.delay(2.5, function()
					if os.clock() >= armedUntil and Delete.Parent then
						setDelete("danger", false)
					end
				end)
				return
			end
			self:DeleteConfig(name)
			if isAuto then
				self:SetAutoload("")
			end
			say("Deleted " .. name)
			refresh()
		end)
		return Row
	end
	refresh = function()
		for _, row in ipairs(rows) do
			row:Destroy()
		end
		table.clear(rows)
		local names = self:ListConfigs()
		local current = self:GetAutoload()
		HeadText.Text = "SAVED CONFIGS  ·  " .. #names
		for i, name in ipairs(names) do
			table.insert(rows, configRow(name, i, name == current))
		end
		if #names == 0 then
			table.insert(rows, S.label({
				Text = "None yet",
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 34),
				ZIndex = 2,
				Theme = { TextColor3 = "Muted" },
				Parent = ListFrame,
			}))
		end
	end
	local function create()
		local name = tostring(NameBox.Text or ""):gsub("[^%w%s%-_]", ""):gsub("^%s+", ""):gsub("%s+$", "")
		if name == "" then
			say("Type a name first")
			return
		end
		local ok, result = self:SaveConfig(name)
		if not ok then
			say(tostring(result))
			return
		end
		NameBox.Text = ""
		say("Saved " .. name)
		refresh()
	end
	S.connect(CreateButton.MouseButton1Click, create)
	S.connect(NameBox.FocusLost, function(enter)
		if enter then
			create()
		end
	end)
	S.connect(RefreshButton.MouseButton1Click, refresh)
	local pending = false
	S.refreshConfigList = function()
		if pending then
			return
		end
		pending = true
		task.defer(function()
			pending = false
			if HeadText.Parent then
				refresh()
			end
		end)
	end
	refresh()
	return tab
end
