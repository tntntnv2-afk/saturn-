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
		if not option.NoConfig and type(id) == "string" then
			local value = serialize(option)
			if value ~= nil then
				data[id] = value
			end
		end
	end
	S.ensureFolder(self.Folder .. "/configs")
	local ok, err = pcall(writefile, configPath(name), HttpService:JSONEncode({ saturn = 1, options = data }))
	if not ok then
		return false, tostring(err)
	end
	return true
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
	for id, value in pairs(options) do
		local option = self.Options[id]
		if option and not option.NoConfig then
			pcall(apply, option, value)
		end
	end
	return true
end

function Library:DeleteConfig(name)
	local path = configPath(name)
	if hasFiles() and type(delfile) == "function" and isfile(path) then
		return pcall(delfile, path)
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
	return pcall(writefile, self.Folder .. "/autoload.txt", tostring(name or ""))
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

function Library:BuildSettingsTab(window, options)
	options = options or {}
	window = window or S.Window
	local saved = S.loadMenu() or {}
	local tab = window:AddTab(options.Name or "Settings", "settings")
	local Menu = tab:AddLeftGroupbox("Menu")
	local key = Menu:AddKeybind("Saturn_MenuKey", {
		Text = "Menu key",
		Default = saved.key or (self.ToggleKey and self.ToggleKey.Name) or "RightControl",
	})
	key.NoConfig = true
	local function applyKey(value)
		local code = value and value ~= "None" and S.keyCode(value)
		if code then
			self.ToggleKey = code
		end
		S.saveMenu()
	end
	key:OnChanged(applyKey)
	applyKey(key.Value)
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
	local bar = Menu:AddToggle("Saturn_OrbitBar", {
		Text = "Active orbit bar",
		Default = saved.orbitBar ~= false,
	})
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
	Menu:AddButton({ Text = "Unload Saturn", DoubleClick = true, Func = function()
		self:Unload()
	end })

	local Configs = tab:AddRightGroupbox("Configs")
	local nameBox = Configs:AddInput("Saturn_ConfigName", { Text = "Name", Placeholder = "my config" })
	nameBox.NoConfig = true
	local list = Configs:AddDropdown("Saturn_ConfigList", {
		Text = "Saved",
		Values = self:ListConfigs(),
		AllowNull = true,
	})
	list.NoConfig = true
	local auto = Configs:AddLabel("Autoload: " .. (self:GetAutoload() or "none"))
	local function refresh()
		list:SetValues(self:ListConfigs())
		auto:SetText("Autoload: " .. (self:GetAutoload() or "none"))
	end
	local function chosen()
		local name = nameBox.Value ~= "" and nameBox.Value or list.Value
		return name and tostring(name) or nil
	end
	Configs:AddButton({ Text = "Save", Func = function()
		local name = chosen()
		local ok, err = self:SaveConfig(name)
		self:Notify("Configs", ok and ("Saved " .. tostring(name)) or tostring(err), 3, "config")
		refresh()
	end })
	Configs:AddButton({ Text = "Load", Func = function()
		local name = list.Value or chosen()
		if not name then
			self:Notify("Configs", "Pick a config first", 3, "config")
			return
		end
		local ok, err = self:LoadConfig(name)
		self:Notify("Configs", ok and ("Loaded " .. name) or tostring(err), 3, "config")
	end })
	Configs:AddButton({ Text = "Set as autoload", Func = function()
		local name = list.Value or chosen()
		if not name then
			self:Notify("Configs", "Pick a config first", 3, "config")
			return
		end
		self:SetAutoload(name)
		refresh()
		self:Notify("Configs", name .. " loads automatically now", 3, "config")
	end })
	Configs:AddButton({ Text = "Delete", DoubleClick = true, Func = function()
		local name = list.Value
		if not name then
			self:Notify("Configs", "Pick a config first", 3, "config")
			return
		end
		self:DeleteConfig(name)
		if self:GetAutoload() == name then
			self:SetAutoload("")
		end
		refresh()
		self:Notify("Configs", "Deleted " .. name, 3, "config")
	end })
	Configs:AddButton({ Text = "Refresh list", Func = refresh })
	return tab
end
