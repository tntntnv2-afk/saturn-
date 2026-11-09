local Search = S.create("Frame", {
	Name = "Search",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 120),
	Size = UDim2.fromOffset(420, 52),
	Visible = false,
	ZIndex = 70,
	Theme = { BackgroundColor3 = "Panel" },
	Parent = S.Overlay,
}, { S.corner(12), S.stroke("BorderLight"), S.create("UIScale", { Scale = 1 }) })
local SearchField = S.create("Frame", {
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.new(1, -16, 0, 36),
	ZIndex = 71,
	Theme = { BackgroundColor3 = "Field" },
	Parent = Search,
}, { S.corner(9), S.stroke("Border") })
Library:Icon(SearchField, "search", 15, {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 11, 0.5, 0),
	ZIndex = 71,
	Theme = { ImageColor3 = "Muted" },
})
local Box = S.create("TextBox", {
	Text = "",
	PlaceholderText = "Search every setting",
	ClearTextOnFocus = false,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(34, 0),
	Size = UDim2.new(1, -44, 1, 0),
	FontFace = S.Font,
	TextSize = 13.5,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 71,
	Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
	Parent = SearchField,
})
local Results = S.create("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(8, 50),
	Size = UDim2.new(1, -16, 1, -58),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 2,
	ZIndex = 71,
	Parent = Search,
}, { S.list(2) })
S.themed(Results, { ScrollBarImageColor3 = "BorderLight" })
local resultRows = {}
local Popup = { Frame = Search }

local function flash(target)
	local Glow = S.create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Transparency = 0,
		Theme = { Color = "Silver" },
		Parent = target,
	})
	local Round = target:FindFirstChildOfClass("UICorner") or S.create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = target })
	task.delay(1, function()
		S.tween(Glow, TweenInfo.new(0.6), { Transparency = 1 })
		task.delay(0.65, function()
			Glow:Destroy()
		end)
	end)
	return Round
end

local function jump(entry)
	S.closePopup()
	local window = S.Window
	if not window then
		return
	end
	window:SelectTab(entry.Tab)
	task.defer(function()
		local page = entry.Tab.Page
		local target = entry.Target
		if target and target.Parent then
			local offset = target.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y - 60
			S.tween(page, S.TweenSmooth, { CanvasPosition = Vector2.new(0, math.max(offset, 0)) })
			flash(target)
		end
	end)
end

local function score(entry, query)
	local text = entry.Text:lower()
	if text == query then
		return 0
	end
	local at = text:find(query, 1, true)
	if at == 1 then
		return 1
	end
	if at then
		return 2
	end
	local extra = (entry.Extra or ""):lower()
	if extra:find(query, 1, true) then
		return 3
	end
	local words = 0
	for word in query:gmatch("%S+") do
		if text:find(word, 1, true) or extra:find(word, 1, true) then
			words += 1
		else
			return nil
		end
	end
	return words > 0 and 4 or nil
end

local function render()
	for _, r in ipairs(resultRows) do
		r:Destroy()
	end
	table.clear(resultRows)
	local query = Box.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	local found = {}
	if query ~= "" then
		for _, entry in ipairs(S.SearchIndex) do
			if entry.Target and entry.Target.Parent then
				local s = score(entry, query)
				if s then
					table.insert(found, { entry, s })
				end
			end
		end
		table.sort(found, function(a, b)
			if a[2] ~= b[2] then
				return a[2] < b[2]
			end
			return a[1].Text < b[1].Text
		end)
	end
	for i = 1, math.min(#found, 40) do
		local entry = found[i][1]
		local Row = S.create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = i,
			ZIndex = 72,
			Theme = { BackgroundColor3 = "Field" },
			Parent = Results,
		}, { S.corner(8) })
		S.label({
			Text = entry.Text,
			TextSize = 13,
			FontFace = S.FontSemi,
			Position = UDim2.fromOffset(12, 4),
			Size = UDim2.new(1, -24, 0, 17),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 72,
			Theme = { TextColor3 = "Text" },
			Parent = Row,
		})
		S.label({
			Text = entry.Tab.Name .. "  ›  " .. entry.Box.Name,
			TextSize = 11.5,
			Position = UDim2.fromOffset(12, 21),
			Size = UDim2.new(1, -24, 0, 15),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 72,
			Theme = { TextColor3 = "Muted" },
			Parent = Row,
		})
		S.bind(Row.MouseEnter, function()
			S.tween(Row, S.TweenFast, { BackgroundTransparency = 0 })
		end)
		S.bind(Row.MouseLeave, function()
			S.tween(Row, S.TweenFast, { BackgroundTransparency = 1 })
		end)
		S.bind(Row.MouseButton1Click, function()
			jump(entry)
		end)
		table.insert(resultRows, Row)
	end
	local height = 52
	if query ~= "" then
		height = 58 + math.max(math.min(#found, 7), 1) * 42
		if #found == 0 then
			local Empty = S.label({
				Text = "Nothing matches \"" .. Box.Text .. "\"",
				TextSize = 12.5,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 40),
				ZIndex = 72,
				Theme = { TextColor3 = "Muted" },
				Parent = Results,
			})
			table.insert(resultRows, Empty)
		end
	end
	Search.Size = UDim2.fromOffset(420, height)
	Popup.Best = found[1] and found[1][1] or nil
end

S.connect(Box:GetPropertyChangedSignal("Text"), render)
S.connect(Box.FocusLost, function(enter)
	if enter and Popup.Best then
		jump(Popup.Best)
	end
end)

function S.openSearch()
	local window = S.Window
	if not window then
		return
	end
	S.closePopup()
	local main = window.Main
	local scale = window.ScaleObject.Scale
	Box.Text = ""
	render()
	local at = S.screenPos(main)
	local x = at.X + main.AbsoluteSize.X / 2
	local y = at.Y + 56 * scale
	Search.Position = UDim2.fromOffset(x, y)
	local popupScale = Search:FindFirstChildOfClass("UIScale")
	popupScale.Scale = scale * 0.96
	S.tween(popupScale, S.Tween, { Scale = scale })
	Search.Visible = true
	S.Blocker.Visible = true
	S.setOpenPopup(Popup)
	task.defer(function()
		Box:CaptureFocus()
	end)
end

S.connect(UserInputService.InputBegan, function(input)
	if input.KeyCode == Enum.KeyCode.F and Library.Open and not S.typing()
		and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
		S.openSearch()
	end
end)

function Library:OpenSearch()
	S.openSearch()
end
