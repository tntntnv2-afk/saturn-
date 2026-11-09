S.Assets = {}
S.AssetCache = {}
S.AssetLoading = {}
S.Animated = {}
S.AnimClock = 0

local function hasFileApi()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
		and type(isfolder) == "function" and type(makefolder) == "function"
end

local function isImage(data)
	return type(data) == "string" and #data > 8 and (data:sub(2, 4) == "PNG" or data:sub(1, 2) == "\255\216")
end

function Library:DefineAsset(name, spec)
	assert(type(name) == "string" and name ~= "", "asset name expected")
	assert(type(spec) == "table", "asset spec expected")
	S.Assets[name] = spec
	S.AssetCache[name] = nil
	return spec
end

function Library:GetAssetSpec(name)
	return S.Assets[name]
end

function Library:GetAsset(name)
	local spec = S.Assets[name]
	if not spec then
		return nil
	end
	while S.AssetLoading[name] do
		task.wait()
	end
	if S.AssetCache[name] ~= nil then
		return S.AssetCache[name] or nil
	end
	S.AssetCache[name] = false
	local getAsset = getcustomasset or getsynasset
	if type(getAsset) ~= "function" or not hasFileApi() then
		S.AssetCache[name] = spec.Fallback or false
		return S.AssetCache[name] or nil
	end
	S.AssetLoading[name] = true
	local ok, id = pcall(function()
		local source = spec.Path or spec.Url or name
		local extension = source:match("%.(%w+)$") or "png"
		local base = source:match("([^/]+)%.%w+$") or name
		local folder = "Saturn/assets"
		local file = string.format("%s/%s_v%s.%s", folder, base, tostring(spec.Version or 1), extension)
		local cached = isfile(file) and readfile(file) or ""
		if not isImage(cached) then
			local data = game:HttpGet(spec.Url or (Library.Repo .. spec.Path))
			if not isImage(data) then
				return nil
			end
			S.ensureFolder(folder)
			writefile(file, data)
		end
		return getAsset(file)
	end)
	S.AssetLoading[name] = nil
	if ok and type(id) == "string" and id ~= "" then
		S.AssetCache[name] = id
	else
		S.AssetCache[name] = spec.Fallback or false
	end
	return S.AssetCache[name] or nil
end

local function sheetFrame(sheet)
	local durations = sheet.Durations
	if durations then
		if not sheet._total then
			local total = 0
			for _, ms in ipairs(durations) do
				total += ms
			end
			sheet._total = math.max(total, 1)
		end
		local at = (S.AnimClock * 1000) % sheet._total
		for index, ms in ipairs(durations) do
			if at < ms then
				return index - 1
			end
			at -= ms
		end
		return #durations - 1
	end
	return math.floor(S.AnimClock * (sheet.Fps or 20)) % sheet.Frames
end

S.loop(function(dt)
	S.AnimClock += dt or 0
	for i = #S.Animated, 1, -1 do
		local entry = S.Animated[i]
		local image, sheet = entry[1], entry[2]
		if image.Parent == nil then
			table.remove(S.Animated, i)
		elseif image.Visible then
			local frame = sheetFrame(sheet)
			local offset = Vector2.new((frame % sheet.Columns) * sheet.Width, math.floor(frame / sheet.Columns) * sheet.Height)
			if image.ImageRectOffset ~= offset then
				image.ImageRectOffset = offset
			end
		end
	end
end)

function Library:Animate(image, sheet)
	assert(sheet and sheet.Width and sheet.Height and sheet.Columns and sheet.Frames, "sprite sheet needs Width, Height, Columns, Frames")
	image.ImageRectSize = Vector2.new(sheet.Width, sheet.Height)
	image.ImageRectOffset = Vector2.zero
	table.insert(S.Animated, { image, sheet })
	return image
end

function Library:Image(parent, name, props)
	props = props or {}
	local image = S.create("ImageLabel", {
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Size = props.Size or UDim2.fromOffset(32, 32),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ImageTransparency = props.ImageTransparency or 0,
		ZIndex = props.ZIndex or 1,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = parent,
	})
	local spec = S.Assets[name]
	if spec and spec.Sheet then
		self:Animate(image, spec.Sheet)
	end
	task.spawn(function()
		local id = self:GetAsset(name)
		if image.Parent == nil then
			return
		end
		if id then
			image.Image = id
			S.safe(props.OnLoaded, image)
		else
			S.safe(props.OnFailed, image)
		end
	end)
	return image
end

S.LogoSheet = {
	Width = 160, Height = 80, Columns = 6, Frames = 60, Fps = 50,
}
Library:DefineAsset("Logo", { Path = "assets/saturn_logo_anim.png", Version = 1, Sheet = S.LogoSheet })
Library:DefineAsset("Icons", { Path = "assets/icons.png", Version = 1 })
Library:DefineAsset("Ring", { Path = "assets/orbit_ring.png", Version = 2 })
Library:DefineAsset("Glide", { Path = "assets/glide.png", Version = 2 })

S.ICON_SIZE = 64
S.ICON_COLUMNS = 8
S.ICON_NAMES = {
	"home", "combat", "farm", "auto", "player", "visuals", "esp", "teleport",
	"world", "misc", "settings", "keybinds", "webhook", "server", "stats", "shop",
	"inventory", "quests", "boss", "safety", "movement", "aim", "info", "config",
	"credits", "search", "close", "minimize", "pin", "star", "chevron", "check",
}
S.ICON_INDEX = {}
for i, name in ipairs(S.ICON_NAMES) do
	S.ICON_INDEX[name] = i - 1
end
S.ICON_ALIASES = {
	house = "home", swords = "combat", sword = "combat", sprout = "farm", eye = "visuals", user = "player",
	["map-pin"] = "teleport", globe = "world", grid = "misc", ["layout-grid"] = "misc", gear = "settings",
	keyboard = "keybinds", link = "webhook", bell = "webhook", chart = "stats", bag = "shop", box = "inventory",
	scroll = "quests", crown = "boss", skull = "boss", shield = "safety", wind = "movement", crosshair = "aim",
	target = "aim", save = "config", heart = "credits", x = "close",
}

function S.iconRect(name)
	local index = S.ICON_INDEX[name] or S.ICON_INDEX[S.ICON_ALIASES[name] or ""] or S.ICON_INDEX.misc
	return Vector2.new((index % S.ICON_COLUMNS) * S.ICON_SIZE, math.floor(index / S.ICON_COLUMNS) * S.ICON_SIZE)
end

function Library:Icon(parent, name, size, props)
	props = props or {}
	local base = {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size or 16, size or 16),
		ImageRectSize = Vector2.new(S.ICON_SIZE, S.ICON_SIZE),
		ImageRectOffset = S.iconRect(name),
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Parent = parent,
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	if not base.Theme and not props.ImageColor3 then
		base.Theme = { ImageColor3 = "Muted" }
	end
	local icon = S.create("ImageLabel", base)
	task.spawn(function()
		local id = self:GetAsset("Icons")
		if id and icon.Parent then
			icon.Image = id
		end
	end)
	return icon
end

function Library:SetIcon(icon, name)
	icon.ImageRectOffset = S.iconRect(name)
end
