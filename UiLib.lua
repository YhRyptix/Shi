-- Glassy Minimalistic UI Library - Part 1: Base Foundation
-- Dark theme with buttery smooth animations

local UI_LIB_VERSION = "1.0.0"

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Library = {}
Library.__index = Library
Library.Version = UI_LIB_VERSION

-- Settings persistence
local SettingsFile = "GlassyUI_Settings.json"
local HttpService = game:GetService("HttpService")

local function SaveSettings(settings)
	local success, err = pcall(function()
		writefile(SettingsFile, HttpService:JSONEncode(settings))
	end)
	if success then
		print("[UI] Settings saved successfully")
	else
		warn("[UI] Failed to save settings:", err)
	end
end

local function LoadSettings()
	if isfile and isfile(SettingsFile) then
		local success, result = pcall(function()
			return HttpService:JSONDecode(readfile(SettingsFile))
		end)
		if success then
			print("[UI] Settings loaded successfully")
			return result
		else
			warn("[UI] Failed to load settings:", result)
			return {}
		end
	end
	print("[UI] No saved settings found, using defaults")
	return {}
end

-- Animation configurations for JELLO-LIKE buttery smooth effects
local ANIM = {
	Default = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Fast = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Smooth = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Elastic = TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
}

-- Modern Glassmorphism Color Palette (Inspired by BackUp app)
local COLORS = {
	Background = Color3.fromRGB(25, 15, 45),      -- Deep purple background
	Surface = Color3.fromRGB(45, 35, 75),         -- Purple glass surface
	SurfaceLight = Color3.fromRGB(65, 50, 95),    -- Lighter glass surface
	Accent = Color3.fromRGB(140, 100, 255),       -- Bright purple accent
	AccentSecondary = Color3.fromRGB(100, 200, 255), -- Cyan blue accent
	Text = Color3.fromRGB(255, 255, 255),         -- Pure white text
	TextDim = Color3.fromRGB(200, 190, 220),      -- Dimmed purple-white
	TextMuted = Color3.fromRGB(160, 150, 180),    -- Muted text
	Border = Color3.fromRGB(80, 70, 120),         -- Purple border
	BorderLight = Color3.fromRGB(120, 100, 160),  -- Light purple border
	Success = Color3.fromRGB(100, 255, 180),      -- Mint green
	Warning = Color3.fromRGB(255, 180, 100),      -- Orange
	Error = Color3.fromRGB(255, 120, 140),        -- Pink red
	Gradient1 = Color3.fromRGB(80, 50, 140),      -- Bright purple gradient start
	Gradient2 = Color3.fromRGB(40, 20, 80)        -- Dark purple gradient end
}

-- Snapshot base palette for hue shifting
local BASE_COLORS = {}
for k, v in pairs(COLORS) do BASE_COLORS[k] = v end

local function hueShift(color, offset)
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV((h + offset) % 1, s, v)
end

local function buildShiftedColors(offset)
    local t = {}
    for k, v in pairs(BASE_COLORS) do
        if k == "Text" or k == "TextDim" then
            t[k] = v -- keep text neutral
        else
            t[k] = hueShift(v, offset or 0)
        end
    end
    return t
end

-- Helper: Create rounded corners
local function CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

-- Helper: Create glassy border stroke
local function CreateStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.Border
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

-- Helper: Create gradient background
local function CreateGradient(parent, color1, color2, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, color1 or COLORS.Gradient1),
		ColorSequenceKeypoint.new(1, color2 or COLORS.Gradient2)
	}
	gradient.Rotation = rotation or 45
	gradient.Parent = parent
	return gradient
end

-- Helper: Create glassmorphism effect
local function CreateGlass(parent, transparency, blur)
	local glass = Instance.new("Frame")
	glass.Name = "GlassEffect"
	glass.Size = UDim2.new(1, 0, 1, 0)
	glass.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	glass.BackgroundTransparency = transparency or 0.9
	glass.BorderSizePixel = 0
	glass.ZIndex = parent.ZIndex + 1
	glass.Parent = parent
	
	-- Add subtle blur effect with gradient
	local blurGradient = Instance.new("UIGradient")
	blurGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 180, 255))
	}
	blurGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.95),
		NumberSequenceKeypoint.new(1, 0.98)
	}
	blurGradient.Parent = glass
	
	return glass
end

-- Helper: Smooth animation wrapper
local function Tween(object, properties, tweenInfo)
	local tween = TweenService:Create(object, tweenInfo or ANIM.Default, properties)
	tween:Play()
	return tween
end

-- Create main window
function Library:CreateWindow(config)
	local Window = {
		Tabs = {},
		CurrentTab = nil,
		Visible = true,
		Settings = LoadSettings()
	}

	config = config or {}
	local title = config.Title or "UI Library"
	local fullscreen = config.Fullscreen == nil and false or config.Fullscreen
	local size = (fullscreen and UDim2.new(1, 0, 1, 0)) or (config.Size or UDim2.new(0, 550, 0, 400))
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
	
	-- Auto-save settings every 5 seconds
	task.spawn(function()
		while true do
			task.wait(5)
			SaveSettings(Window.Settings)
		end
	end)
	
	-- ScreenGui
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "GlassyUI"
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.DisplayOrder = 1000
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = game:GetService("CoreGui")
	
	-- Main Frame (Glassy container)
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = size
	MainFrame.Position = fullscreen and UDim2.new(0, 0, 0, 0) or UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
	MainFrame.BackgroundColor3 = COLORS.Background
	MainFrame.BackgroundTransparency = 0.1
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Active = true
	MainFrame.Parent = ScreenGui
	CreateCorner(MainFrame, fullscreen and 0 or 16)
	CreateStroke(MainFrame, COLORS.BorderLight, 1, 0.3)
	
	-- Add beautiful gradient background
	CreateGradient(MainFrame, COLORS.Gradient1, COLORS.Gradient2, 135)
	
	-- Title bar with glassmorphism
	local TitleBar = Instance.new("Frame")
	TitleBar.Name = "TitleBar"
	TitleBar.Size = UDim2.new(1, 0, 0, 50)
	TitleBar.BackgroundColor3 = COLORS.SurfaceLight
	TitleBar.BackgroundTransparency = 0.3
	TitleBar.BorderSizePixel = 0
	TitleBar.ZIndex = 3
	TitleBar.Parent = MainFrame
	CreateCorner(TitleBar, 16)
	CreateStroke(TitleBar, COLORS.BorderLight, 1, 0.5)
	CreateGradient(TitleBar, COLORS.SurfaceLight, COLORS.Surface, 90)
	
	-- Title bar bottom border
	local TitleDivider = Instance.new("Frame")
	TitleDivider.Name = "Divider"
	TitleDivider.Size = UDim2.new(1, -20, 0, 1)
	TitleDivider.Position = UDim2.new(0, 10, 1, -1)
	TitleDivider.BackgroundColor3 = COLORS.Border
	TitleDivider.BackgroundTransparency = 0.5
	TitleDivider.BorderSizePixel = 0
	TitleDivider.ZIndex = 4
	TitleDivider.Parent = TitleBar
	
	-- Title text
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Size = UDim2.new(1, -50, 1, 0)
	TitleLabel.Position = UDim2.new(0, 15, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = title
	TitleLabel.TextColor3 = COLORS.Text
	TitleLabel.TextSize = 16
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.ZIndex = 4
	TitleLabel.Parent = TitleBar
	
	-- Toggle keybind indicator
	local KeybindLabel = Instance.new("TextLabel")
	KeybindLabel.Name = "KeybindLabel"
	KeybindLabel.Size = UDim2.new(0, 100, 1, 0)
	KeybindLabel.Position = UDim2.new(1, -110, 0, 0)
	KeybindLabel.BackgroundTransparency = 1
	KeybindLabel.Text = "[" .. toggleKey.Name .. "]"
	KeybindLabel.TextColor3 = COLORS.TextDim
	KeybindLabel.TextSize = 12
	KeybindLabel.Font = Enum.Font.GothamMedium
	KeybindLabel.TextXAlignment = Enum.TextXAlignment.Right
	KeybindLabel.ZIndex = 4
	KeybindLabel.Parent = TitleBar
	
	-- Dragging functionality
	local dragging, dragInput, dragStart, startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		Tween(MainFrame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, ANIM.Fast)
	end
	
	TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	TitleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
	
	-- Toggle visibility function with debounce
	local isToggling = false
	function Window:Toggle()
		if isToggling then return end
		isToggling = true
		
		self.Visible = not self.Visible
		
		if self.Visible then
			-- Show with scale and fade animation
			MainFrame.Size = UDim2.new(0, 0, 0, 0)
			MainFrame.BackgroundTransparency = 1
			MainFrame.Visible = true
			Tween(MainFrame, {Size = size, BackgroundTransparency = 0}, ANIM.Elastic)
			task.delay(0.6, function()
				isToggling = false
				MainFrame.ClipsDescendants = true
			end)
		else
			-- Hide with smooth shrink animation (no bounce to avoid overshoot)
			local SmoothClose = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, SmoothClose)
			task.delay(0.35, function()
				MainFrame.Visible = false
				isToggling = false
			end)
		end
	end
	
	-- Initialize dynamic toggle key
	Window.ToggleKey = toggleKey

	-- Keybind listener
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == (Window.ToggleKey or toggleKey) then
			Window:Toggle()
		end
	end)
	
	-- Entrance animation
	MainFrame.Size = UDim2.new(0, 0, 0, 0)
	MainFrame.BackgroundTransparency = 1
	Tween(MainFrame, {Size = size, BackgroundTransparency = 0}, ANIM.Elastic)

	-- Theme/Window controls for runtime settings
	function Window:ApplyTheme()
		-- Apply accent to scrollbars across the UI
		for _, inst in ipairs(ScreenGui:GetDescendants()) do
			if inst:IsA("ScrollingFrame") then
				inst.ScrollBarImageColor3 = COLORS.Accent
			end
		end
		-- Apply base background colors to primary containers
		MainFrame.BackgroundColor3 = COLORS.Background
		if self.TabContainer then
			self.TabContainer.BackgroundColor3 = COLORS.Surface
		end
		-- Update tab buttons text/stroke where possible
		for _, child in ipairs(self.TabList and self.TabList:GetChildren() or {}) do
			if child:IsA("TextButton") then
				child.TextColor3 = COLORS.TextDim
			end
		end
	end


	function Window:SetAccent(color)
		if typeof(color) == "Color3" then
			COLORS.Accent = color
			self:ApplyTheme()
		end
	end

	function Window:SetBackground(color)
		if typeof(color) == "Color3" then
			COLORS.Background = color
			self:ApplyTheme()
		end
	end

	function Window:SetToggleKey(keyCode)
		if typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode then
			self.ToggleKey = keyCode
			-- Update the keybind label in the title bar
			KeybindLabel.Text = "[" .. keyCode.Name .. "]"
		end
	end

	function Window:SetHue(offset)
		offset = tonumber(offset) or 0
		if offset < 0 then offset = 0 end
		if offset > 1 then offset = 1 end
		-- Rebuild palette from base with hue shift and apply immediately
		COLORS = buildShiftedColors(offset)
		self:ApplyTheme()
		self.Settings.HueOffset = offset
	end
	
	-- Tab Container (Left side)
	local TabContainer = Instance.new("Frame")
	TabContainer.Name = "TabContainer"
	TabContainer.Size = UDim2.new(0, 140, 1, -55)
	TabContainer.Position = UDim2.new(0, 10, 0, 50)
	TabContainer.BackgroundColor3 = COLORS.SurfaceLight
	TabContainer.BackgroundTransparency = 0.25
	TabContainer.BorderSizePixel = 0
	TabContainer.ZIndex = 3
	TabContainer.Parent = MainFrame
	CreateCorner(TabContainer, 16)
	CreateStroke(TabContainer, COLORS.BorderLight, 1, 0.4)
	CreateGradient(TabContainer, COLORS.SurfaceLight, COLORS.Surface, 180)
	
	-- Tab List
	local TabList = Instance.new("ScrollingFrame")
	TabList.Name = "TabList"
	TabList.Size = UDim2.new(1, -10, 1, -10)
	TabList.Position = UDim2.new(0, 5, 0, 5)
	TabList.BackgroundTransparency = 1
	TabList.BorderSizePixel = 0
	TabList.ScrollBarThickness = 4
	TabList.ScrollBarImageColor3 = COLORS.Accent
	TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
	TabList.ZIndex = 4
	TabList.Parent = TabContainer
	
	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Padding = UDim.new(0, 6)
	TabListLayout.Parent = TabList
	
	-- Auto-resize canvas
	TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabList.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
	end)
	
	-- Content Container (Right side)
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Name = "ContentContainer"
	ContentContainer.Size = UDim2.new(1, -170, 1, -55)
	ContentContainer.Position = UDim2.new(0, 160, 0, 50)
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.BorderSizePixel = 0
	ContentContainer.ZIndex = 3
	ContentContainer.ClipsDescendants = true
	ContentContainer.Parent = MainFrame
	
	Window.ScreenGui = ScreenGui
	Window.MainFrame = MainFrame
	Window.TabContainer = TabContainer
	Window.TabList = TabList
	Window.ContentContainer = ContentContainer
	Window.KeybindLabel = KeybindLabel
	
	return setmetatable(Window, Library)
end

-- Create a new tab
function Library:CreateTab(name)
	local Tab = {
		Elements = {},
		Name = name
	}
	
	-- Tab Button
	local TabButton = Instance.new("TextButton")
	TabButton.Name = name
	TabButton.Size = UDim2.new(1, 0, 0, 36)
	TabButton.BackgroundColor3 = COLORS.SurfaceLight
	TabButton.BackgroundTransparency = 0.2
	TabButton.BorderSizePixel = 0
	TabButton.Text = name
	TabButton.TextColor3 = COLORS.TextDim
	TabButton.TextSize = 14
	TabButton.Font = Enum.Font.GothamMedium
	TabButton.ZIndex = 5
	TabButton.Parent = self.TabList
	CreateCorner(TabButton, 8)
	
	local TabStroke = CreateStroke(TabButton, COLORS.Border, 1, 0.8)
	
	-- Tab Content Page
	local TabPage = Instance.new("ScrollingFrame")
	TabPage.Name = name .. "Page"
	TabPage.Size = UDim2.new(1, 0, 1, 0)
	TabPage.BackgroundTransparency = 1
	TabPage.BorderSizePixel = 0
	TabPage.ScrollBarThickness = 6
	TabPage.ScrollBarImageColor3 = COLORS.Accent
	TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
	TabPage.Visible = false
	TabPage.ZIndex = 4
	TabPage.ClipsDescendants = true
	TabPage.Parent = self.ContentContainer
	
	-- 3-column container inside TabPage
	local ColumnsContainer = Instance.new("Frame")
	ColumnsContainer.Name = "ColumnsContainer"
	ColumnsContainer.BackgroundTransparency = 1
	ColumnsContainer.Size = UDim2.new(1, 0, 1, 0)
	ColumnsContainer.Parent = TabPage

	-- Vertical stacking for full-width notes and the columns block
	local TabPageLayout = Instance.new("UIListLayout")
	TabPageLayout.FillDirection = Enum.FillDirection.Vertical
	TabPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabPageLayout.Padding = UDim.new(0, 8)
	TabPageLayout.Parent = TabPage

	-- Place columns after any optional notes by default
	ColumnsContainer.LayoutOrder = 100
	

	local ColumnsPadding = Instance.new("UIPadding")
	ColumnsPadding.PaddingTop = UDim.new(0, 12)
	ColumnsPadding.PaddingBottom = UDim.new(0, 12)
	ColumnsPadding.PaddingLeft = UDim.new(0, 12)
	ColumnsPadding.PaddingRight = UDim.new(0, 12)
	ColumnsPadding.Parent = ColumnsContainer

	local ColumnsLayout = Instance.new("UIListLayout")
	ColumnsLayout.FillDirection = Enum.FillDirection.Horizontal
	ColumnsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ColumnsLayout.Padding = UDim.new(0, 16)
	ColumnsLayout.Parent = ColumnsContainer

	local function createColumn()
		local col = Instance.new("Frame")
		col.BackgroundTransparency = 1
		col.Size = UDim2.new(0.5, -8, 1, 0) -- 2 columns instead of 3
		col.Parent = ColumnsContainer
		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 10)
		list.Parent = col
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 2)
		pad.PaddingLeft = UDim.new(0, 2)
		pad.PaddingRight = UDim.new(0, 2)
		pad.Parent = col
		return col, list
	end

	local Col1, Col1Layout = createColumn()
	local Col2, Col2Layout = createColumn()
	-- Remove Col3 for 2-column layout

	local function updateCanvasSize()
		-- Calculate total height including notes and columns
		local notesHeight = 0
		for _, child in ipairs(TabPage:GetChildren()) do
			if child ~= ColumnsContainer and child:IsA("GuiObject") then
				notesHeight = notesHeight + child.AbsoluteSize.Y + 8
			end
		end
		local tallest = math.max(Col1Layout.AbsoluteContentSize.Y, Col2Layout.AbsoluteContentSize.Y)
		TabPage.CanvasSize = UDim2.new(0, 0, 0, notesHeight + tallest + 40)
	end

	Col1Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
	Col2Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
	
	-- Also update when notes are added
	TabPage.ChildAdded:Connect(updateCanvasSize)
	TabPage.ChildRemoved:Connect(updateCanvasSize)

	-- Fixed 2-column layout
	Col1.Size = UDim2.new(0.5, -8, 1, 0)
	Col2.Size = UDim2.new(0.5, -8, 1, 0)
	
	-- Tab selection logic with smooth animations
	TabButton.MouseButton1Click:Connect(function()
		-- Don't do anything if already selected
		if self.CurrentTab == Tab then return end
		
		-- Deselect all tabs
		for _, tab in pairs(self.Tabs) do
			Tween(tab.Button, {
				BackgroundColor3 = COLORS.SurfaceLight,
				BackgroundTransparency = 0.6,
				TextColor3 = COLORS.TextDim
			}, ANIM.Fast)
			Tween(tab.Stroke, {Transparency = 0.8}, ANIM.Fast)
			
			-- Hide all pages
			tab.Page.Visible = false
		end
		
		-- Select this tab
		Tween(TabButton, {
			BackgroundColor3 = COLORS.Accent,
			BackgroundTransparency = 0.2,
			TextColor3 = COLORS.Text
		}, ANIM.Smooth)
		Tween(TabStroke, {Transparency = 0.3}, ANIM.Smooth)
		
		-- Show this page with slide animation
		TabPage.Position = UDim2.new(0, 0, 0, 0)
		TabPage.BackgroundTransparency = 1
		TabPage.Visible = true
		Tween(TabPage, {BackgroundTransparency = 1}, ANIM.Smooth)
		
		self.CurrentTab = Tab
	end)
	
	-- Hover effects
	TabButton.MouseEnter:Connect(function()
		if self.CurrentTab ~= Tab then
			Tween(TabButton, {BackgroundTransparency = 0.4}, ANIM.Elastic)
		end
	end)
	
	TabButton.MouseLeave:Connect(function()
		if self.CurrentTab ~= Tab then
			Tween(TabButton, {BackgroundTransparency = 0.7}, ANIM.Elastic)
		end
	end)
	
	Tab.Button = TabButton
	Tab.Page = TabPage
	Tab.Stroke = TabStroke
	Tab.Columns = {Col1, Col2} -- Only 2 columns now
	Tab._colIndex = 1
	Tab._lockedColumnIndex = nil
	function Tab:SetColumn(index)
		if typeof(index) == "number" and index >= 1 and index <= 2 then -- Max 2 columns
			self._lockedColumnIndex = index
		end
	end
	function Tab:ClearColumn()
		self._lockedColumnIndex = nil
	end
	function Tab:GetNextParent()
		if self._lockedColumnIndex then
			return self.Columns[self._lockedColumnIndex]
		end
		local p = self.Columns[self._colIndex]
		self._colIndex = (self._colIndex % 3) + 1
		return p
	end
	table.insert(self.Tabs, Tab)
	
	-- Auto-select first tab
	if #self.Tabs == 1 then
		-- Manually select the first tab
		Tween(TabButton, {
			BackgroundColor3 = COLORS.Accent,
			BackgroundTransparency = 0.2,
			TextColor3 = COLORS.Text
		}, ANIM.Smooth)
		Tween(TabStroke, {Transparency = 0.3}, ANIM.Smooth)
		TabPage.Visible = true
		self.CurrentTab = Tab
	end
	
	Tab.Window = self
	return setmetatable(Tab, Library)
end

-- Add Button
function Library:AddButton(config)
	config = config or {}
	local buttonText = config.Text or "Button"
	local callback = config.Callback or function() end
	
	-- Button Container
	local ButtonFrame = Instance.new("Frame")
	ButtonFrame.Name = "ButtonFrame"
	ButtonFrame.Size = UDim2.new(1, -16, 0, 40)
	ButtonFrame.BackgroundColor3 = COLORS.SurfaceLight
	ButtonFrame.BackgroundTransparency = 0.3
	ButtonFrame.BorderSizePixel = 0
	ButtonFrame.ZIndex = 5
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	ButtonFrame.Parent = __parent
	CreateCorner(ButtonFrame, 12)
	CreateStroke(ButtonFrame, COLORS.BorderLight, 1, 0.3)
	CreateGradient(ButtonFrame, COLORS.SurfaceLight, COLORS.Surface, 90)
	
	-- Button
	local Button = Instance.new("TextButton")
	Button.Name = "Button"
	Button.Size = UDim2.new(1, 0, 1, 0)
	Button.BackgroundTransparency = 1
	Button.Text = buttonText
	Button.TextColor3 = COLORS.Text
	Button.TextSize = 14
	Button.Font = Enum.Font.GothamMedium
	Button.ZIndex = 6
	Button.Parent = ButtonFrame
	
	-- Click effect
	Button.MouseButton1Click:Connect(function()
		-- Ripple effect
		Tween(ButtonFrame, {BackgroundColor3 = COLORS.Accent}, ANIM.Fast)
		Tween(ButtonFrame, {BackgroundTransparency = 0.2}, ANIM.Fast)
		task.wait(0.15)
		Tween(ButtonFrame, {BackgroundColor3 = COLORS.Surface}, ANIM.Elastic)
		Tween(ButtonFrame, {BackgroundTransparency = 0.5}, ANIM.Elastic)
		
		callback()
	end)
	
	-- Hover effect
	Button.MouseEnter:Connect(function()
		Tween(ButtonFrame, {BackgroundTransparency = 0.3}, ANIM.Elastic)
	end)
	
	Button.MouseLeave:Connect(function()
		Tween(ButtonFrame, {BackgroundTransparency = 0.5}, ANIM.Elastic)
	end)
	
	return Button
end

-- Add Toggleable Bind (like keybind but toggles a feature on/off)
function Library:AddToggleBind(config)
	config = config or {}
	local bindText = config.Text or "Toggle Bind"
	local defaultKey = config.Default or Enum.KeyCode.T
	local callback = config.Callback or function() end
	
	-- Container
	local BindFrame = Instance.new("Frame")
	BindFrame.Name = "ToggleBindFrame"
	BindFrame.Size = UDim2.new(1, -16, 0, 40)
	BindFrame.BackgroundColor3 = COLORS.SurfaceLight
	BindFrame.BackgroundTransparency = 0.3
	BindFrame.BorderSizePixel = 0
	BindFrame.ZIndex = 5
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	BindFrame.Parent = __parent
	CreateCorner(BindFrame, 12)
	CreateStroke(BindFrame, COLORS.BorderLight, 1, 0.3)
	CreateGradient(BindFrame, COLORS.SurfaceLight, COLORS.Surface, 90)
	
	-- Label
	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.new(1, -80, 0, 20)
	Label.Position = UDim2.new(0, 0, 0, 2)
	Label.BackgroundTransparency = 1
	Label.Text = bindText
	Label.TextColor3 = COLORS.Text
	Label.TextSize = 14
	Label.Font = Enum.Font.GothamMedium
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.ZIndex = 6
	Label.Parent = BindFrame
	
	-- Hint Label
	local HintLabel = Instance.new("TextLabel")
	HintLabel.Name = "HintLabel"
	HintLabel.Size = UDim2.new(1, -80, 0, 16)
	HintLabel.Position = UDim2.new(0, 0, 0, 22)
	HintLabel.BackgroundTransparency = 1
	HintLabel.Text = "CLICK TO TOGGLE"
	HintLabel.TextColor3 = COLORS.TextMuted
	HintLabel.TextSize = 10
	HintLabel.Font = Enum.Font.GothamMedium
	HintLabel.TextXAlignment = Enum.TextXAlignment.Left
	HintLabel.ZIndex = 6
	HintLabel.Parent = BindFrame
	
	-- Padding for labels
	local LabelPadding = Instance.new("UIPadding")
	LabelPadding.PaddingLeft = UDim.new(0, 12)
	LabelPadding.Parent = Label
	
	local HintPadding = Instance.new("UIPadding")
	HintPadding.PaddingLeft = UDim.new(0, 12)
	HintPadding.Parent = HintLabel
	
	-- Keybind Button
	local KeybindButton = Instance.new("TextButton")
	KeybindButton.Name = "KeybindButton"
	KeybindButton.Size = UDim2.new(0, 70, 0, 28)
	KeybindButton.Position = UDim2.new(1, -75, 0.5, -14)
	KeybindButton.BackgroundColor3 = COLORS.Surface
	KeybindButton.BackgroundTransparency = 0.2
	KeybindButton.BorderSizePixel = 0
	KeybindButton.Text = defaultKey.Name
	KeybindButton.TextColor3 = COLORS.TextDim
	KeybindButton.TextSize = 12
	KeybindButton.Font = Enum.Font.GothamMedium
	KeybindButton.ZIndex = 6
	KeybindButton.Parent = BindFrame
	CreateCorner(KeybindButton, 8)
	CreateStroke(KeybindButton, COLORS.Border, 1, 0.6)
	
	local currentKey = defaultKey
	local isEnabled = false
	local connection = nil
	
	-- Update connection when key changes
	local function updateConnection()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		
		if isEnabled then
			connection = UserInputService.InputBegan:Connect(function(input, processed)
				if processed then return end
				if input.KeyCode == currentKey then
					callback()
				end
			end)
		end
	end
	
	-- Status indicator
	local StatusIndicator = Instance.new("Frame")
	StatusIndicator.Name = "StatusIndicator"
	StatusIndicator.Size = UDim2.new(0, 10, 0, 10)
	StatusIndicator.Position = UDim2.new(1, -105, 0.5, -5)
	StatusIndicator.BackgroundColor3 = COLORS.Error
	StatusIndicator.BorderSizePixel = 0
	StatusIndicator.ZIndex = 6
	StatusIndicator.Parent = BindFrame
	CreateCorner(StatusIndicator, 5)
	
	-- Toggle function
	local function toggle()
		isEnabled = not isEnabled
		Label.TextColor3 = isEnabled and COLORS.Success or COLORS.Text
		StatusIndicator.BackgroundColor3 = isEnabled and COLORS.Success or COLORS.Error
		updateConnection()
	end
	
	-- Keybind selection
	local isBinding = false
	KeybindButton.MouseButton1Click:Connect(function()
		if isBinding then return end
		isBinding = true
		KeybindButton.Text = "..."
		
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				currentKey = input.KeyCode
				KeybindButton.Text = currentKey.Name
				updateConnection()
				conn:Disconnect()
				isBinding = false
			end
		end)
	end)
	
	-- Click label to toggle
	local ToggleButton = Instance.new("TextButton")
	ToggleButton.Size = UDim2.new(1, -80, 1, 0)
	ToggleButton.BackgroundTransparency = 1
	ToggleButton.Text = ""
	ToggleButton.ZIndex = 7
	ToggleButton.Parent = BindFrame
	
	ToggleButton.MouseButton1Click:Connect(toggle)
	
	-- Hover effects - make it SUPER obvious it's clickable
	BindFrame.MouseEnter:Connect(function()
		Tween(BindFrame, {BackgroundTransparency = 0.05}, ANIM.Fast)
		Tween(StatusIndicator, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -107, 0.5, -7)}, ANIM.Fast)
		HintLabel.TextColor3 = COLORS.Accent
	end)
	
	BindFrame.MouseLeave:Connect(function()
		Tween(BindFrame, {BackgroundTransparency = 0.3}, ANIM.Fast)
		Tween(StatusIndicator, {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -105, 0.5, -5)}, ANIM.Fast)
		HintLabel.TextColor3 = COLORS.TextMuted
	end)
	
	return BindFrame
end

-- Add Toggle
function Library:AddToggle(config)
	config = config or {}
	local toggleText = config.Text or "Toggle"
	local default = config.Default or false
	local callback = config.Callback or function() end
	local flag = config.Flag or toggleText
	
	-- Load saved value or use default
	local toggled = self.Window.Settings[flag]
	if toggled == nil then
		toggled = default
		self.Window.Settings[flag] = toggled
	end
	
	-- Toggle Container
	local ToggleFrame = Instance.new("Frame")
	ToggleFrame.Name = "ToggleFrame"
	ToggleFrame.Size = UDim2.new(1, -16, 0, 40)
	ToggleFrame.BackgroundColor3 = COLORS.Surface
	ToggleFrame.BackgroundTransparency = 0
	ToggleFrame.BorderSizePixel = 0
	ToggleFrame.ZIndex = 5
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	ToggleFrame.Parent = __parent
	CreateCorner(ToggleFrame, 8)
	CreateStroke(ToggleFrame, COLORS.Border, 1, 0.6)
	
	-- Label
	local ToggleLabel = Instance.new("TextLabel")
	ToggleLabel.Name = "Label"
	ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
	ToggleLabel.Position = UDim2.new(0, 12, 0, 0)
	ToggleLabel.BackgroundTransparency = 1
	ToggleLabel.Text = toggleText
	ToggleLabel.TextColor3 = COLORS.Text
	ToggleLabel.TextSize = 14
	ToggleLabel.Font = Enum.Font.GothamMedium
	ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	ToggleLabel.ZIndex = 6
	ToggleLabel.Parent = ToggleFrame
	
	-- Toggle Switch Background
	local ToggleBg = Instance.new("Frame")
	ToggleBg.Name = "ToggleBg"
	ToggleBg.Size = UDim2.new(0, 44, 0, 24)
	ToggleBg.Position = UDim2.new(1, -54, 0.5, -12)
	ToggleBg.BackgroundColor3 = COLORS.SurfaceLight
	ToggleBg.BorderSizePixel = 0
	ToggleBg.ZIndex = 6
	ToggleBg.Parent = ToggleFrame
	CreateCorner(ToggleBg, 12)
	
	-- Toggle Circle
	local ToggleCircle = Instance.new("Frame")
	ToggleCircle.Name = "Circle"
	ToggleCircle.Size = UDim2.new(0, 18, 0, 18)
	ToggleCircle.Position = UDim2.new(0, 3, 0.5, -9)
	ToggleCircle.BackgroundColor3 = COLORS.Text
	ToggleCircle.BorderSizePixel = 0
	ToggleCircle.ZIndex = 7
	ToggleCircle.Parent = ToggleBg
	CreateCorner(ToggleCircle, 9)
	
	-- Toggle Button (Invisible)
	local ToggleButton = Instance.new("TextButton")
	ToggleButton.Size = UDim2.new(1, 0, 1, 0)
	ToggleButton.BackgroundTransparency = 1
	ToggleButton.Text = ""
	ToggleButton.ZIndex = 8
	ToggleButton.Parent = ToggleFrame
	
	-- Update toggle state
	local function UpdateToggle()
		if toggled then
			Tween(ToggleBg, {BackgroundColor3 = COLORS.Accent}, ANIM.Smooth)
			Tween(ToggleCircle, {Position = UDim2.new(0, 23, 0.5, -9)}, ANIM.Elastic)
		else
			Tween(ToggleBg, {BackgroundColor3 = COLORS.SurfaceLight}, ANIM.Smooth)
			Tween(ToggleCircle, {Position = UDim2.new(0, 3, 0.5, -9)}, ANIM.Elastic)
		end
	end
	
	-- Initialize
	UpdateToggle()
	
	-- Click handler
	ToggleButton.MouseButton1Click:Connect(function()
		toggled = not toggled
		self.Window.Settings[flag] = toggled
		UpdateToggle()
		callback(toggled)
	end)
	
	-- Hover effect
	ToggleButton.MouseEnter:Connect(function()
		Tween(ToggleFrame, {BackgroundTransparency = 0.3}, ANIM.Elastic)
	end)
	
	ToggleButton.MouseLeave:Connect(function()
		Tween(ToggleFrame, {BackgroundTransparency = 0.5}, ANIM.Elastic)
	end)
	
	return {
		SetValue = function(value)
			toggled = value
			UpdateToggle()
		end
	}
end

-- Add Slider
function Library:AddSlider(config)
	config = config or {}
	local sliderText = config.Text or "Slider"
	local min = config.Min or 0
	local max = config.Max or 100
	local default = config.Default or min
	local increment = config.Increment or 1
	local callback = config.Callback or function() end
	local flag = config.Flag or sliderText
	
	-- Load saved value or use default
	local value = self.Window.Settings[flag] or default
	local dragging = false
	
	-- Slider Container
	local SliderFrame = Instance.new("Frame")
	SliderFrame.Name = "SliderFrame"
	SliderFrame.Size = UDim2.new(1, -16, 0, 50)
	SliderFrame.BackgroundColor3 = COLORS.Surface
	SliderFrame.BackgroundTransparency = 0
	SliderFrame.BorderSizePixel = 0
	SliderFrame.ZIndex = 5
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	SliderFrame.Parent = __parent
	CreateCorner(SliderFrame, 8)
	CreateStroke(SliderFrame, COLORS.Border, 1, 0.6)
	
	-- Label
	local SliderLabel = Instance.new("TextLabel")
	SliderLabel.Name = "Label"
	SliderLabel.Size = UDim2.new(1, -70, 0, 20)
	SliderLabel.Position = UDim2.new(0, 12, 0, 6)
	SliderLabel.BackgroundTransparency = 1
	SliderLabel.Text = sliderText
	SliderLabel.TextColor3 = COLORS.Text
	SliderLabel.TextSize = 14
	SliderLabel.Font = Enum.Font.GothamMedium
	SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
	SliderLabel.ZIndex = 6
	SliderLabel.Parent = SliderFrame
	
	-- Value Label
	local ValueLabel = Instance.new("TextLabel")
	ValueLabel.Name = "ValueLabel"
	ValueLabel.Size = UDim2.new(0, 60, 0, 20)
	ValueLabel.Position = UDim2.new(1, -65, 0, 6)
	ValueLabel.BackgroundTransparency = 1
	ValueLabel.Text = tostring(value)
	ValueLabel.TextColor3 = COLORS.Accent
	ValueLabel.TextSize = 14
	ValueLabel.Font = Enum.Font.GothamBold
	ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	ValueLabel.ZIndex = 6
	ValueLabel.Parent = SliderFrame
	
	-- Slider Track
	local SliderTrack = Instance.new("Frame")
	SliderTrack.Name = "Track"
	SliderTrack.Size = UDim2.new(1, -24, 0, 6)
	SliderTrack.Position = UDim2.new(0, 12, 1, -16)
	SliderTrack.BackgroundColor3 = COLORS.SurfaceLight
	SliderTrack.BorderSizePixel = 0
	SliderTrack.ZIndex = 6
	SliderTrack.Parent = SliderFrame
	CreateCorner(SliderTrack, 3)
	
	-- Invisible hitbox for easier grabbing
	local SliderHitbox = Instance.new("Frame")
	SliderHitbox.Name = "Hitbox"
	SliderHitbox.Size = UDim2.new(1, 0, 0, 20)
	SliderHitbox.Position = UDim2.new(0, 0, 0.5, -10)
	SliderHitbox.BackgroundTransparency = 1
	SliderHitbox.ZIndex = 9
	SliderHitbox.Parent = SliderTrack
	
	-- Slider Fill
	local SliderFill = Instance.new("Frame")
	SliderFill.Name = "Fill"
	SliderFill.Size = UDim2.new(0, 0, 1, 0)
	SliderFill.BackgroundColor3 = COLORS.Accent
	SliderFill.BorderSizePixel = 0
	SliderFill.ZIndex = 7
	SliderFill.Parent = SliderTrack
	CreateCorner(SliderFill, 3)
	
	-- Slider Knob
	local SliderKnob = Instance.new("Frame")
	SliderKnob.Name = "Knob"
	SliderKnob.Size = UDim2.new(0, 16, 0, 16)
	SliderKnob.Position = UDim2.new(1, 0, 0.5, 0)
	SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	SliderKnob.BackgroundColor3 = COLORS.Text
	SliderKnob.BorderSizePixel = 0
	SliderKnob.ZIndex = 8
	SliderKnob.Parent = SliderFill
	CreateCorner(SliderKnob, 8)
	CreateStroke(SliderKnob, COLORS.Accent, 2, 0)
	
	-- Update slider
	local function UpdateSlider(val)
		value = math.clamp(math.floor((val - min) / increment + 0.5) * increment + min, min, max)
		local percent = (value - min) / (max - min)
		
		self.Window.Settings[flag] = value
		Tween(SliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, ANIM.Fast)
		ValueLabel.Text = tostring(value)
		
		callback(value)
	end
	
	-- Initialize
	UpdateSlider(value)
	
	-- Dragging logic (using hitbox for easier grabbing)
	SliderHitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			Tween(SliderKnob, {Size = UDim2.new(0, 20, 0, 20)}, ANIM.Elastic)
			-- Update immediately on click
			local pos = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
			UpdateSlider(min + (max - min) * pos)
		end
	end)
	
	SliderHitbox.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			Tween(SliderKnob, {Size = UDim2.new(0, 16, 0, 16)}, ANIM.Elastic)
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local pos = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
			UpdateSlider(min + (max - min) * pos)
		end
	end)
	
	return {
		SetValue = function(val)
			UpdateSlider(val)
		end
	}
end

-- Add Dropdown
function Library:AddDropdown(config)
	config = config or {}
	local dropdownText = config.Text or "Dropdown"
	local options = config.Options or {"Option 1", "Option 2", "Option 3"}
	local default = config.Default or options[1]
	local callback = config.Callback or function() end
	local flag = config.Flag or dropdownText
	
	-- Load saved value or use default
	local selected = self.Window.Settings[flag] or default
	local isOpen = false
	
	-- Dropdown Container
	local DropdownFrame = Instance.new("Frame")
	DropdownFrame.Name = "DropdownFrame"
	DropdownFrame.Size = UDim2.new(1, -16, 0, 40)
	DropdownFrame.BackgroundColor3 = COLORS.Surface
	DropdownFrame.BackgroundTransparency = 0
	DropdownFrame.BorderSizePixel = 0
	DropdownFrame.ZIndex = 5
	DropdownFrame.ClipsDescendants = false
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	DropdownFrame.Parent = __parent
	CreateCorner(DropdownFrame, 8)
	CreateStroke(DropdownFrame, COLORS.Border, 1, 0.6)
	
	-- Reserve space for dropdown when open
	local DropdownSpacer = Instance.new("Frame")
	DropdownSpacer.Name = "Spacer"
	DropdownSpacer.Size = UDim2.new(1, 0, 0, 0)
	DropdownSpacer.BackgroundTransparency = 1
	DropdownSpacer.BorderSizePixel = 0
	DropdownSpacer.ZIndex = 1
	DropdownSpacer.Visible = false
	DropdownSpacer.Parent = DropdownFrame.Parent
	DropdownSpacer.LayoutOrder = DropdownFrame.LayoutOrder or 0
	
	-- Label
	local DropdownLabel = Instance.new("TextLabel")
	DropdownLabel.Name = "Label"
	DropdownLabel.Size = UDim2.new(1, -24, 0, 18)
	DropdownLabel.Position = UDim2.new(0, 12, 0, 3)
	DropdownLabel.BackgroundTransparency = 1
	DropdownLabel.Text = dropdownText
	DropdownLabel.TextColor3 = COLORS.TextDim
	DropdownLabel.TextSize = 12
	DropdownLabel.Font = Enum.Font.Gotham
	DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
	DropdownLabel.ZIndex = 6
	DropdownLabel.Parent = DropdownFrame
	
	-- Selected Value
	local SelectedValue = Instance.new("TextLabel")
	SelectedValue.Name = "SelectedValue"
	SelectedValue.Size = UDim2.new(1, -40, 0, 18)
	SelectedValue.Position = UDim2.new(0, 12, 1, -21)
	SelectedValue.BackgroundTransparency = 1
	SelectedValue.Text = selected
	SelectedValue.TextColor3 = COLORS.Text
	SelectedValue.TextSize = 14
	SelectedValue.Font = Enum.Font.GothamMedium
	SelectedValue.TextXAlignment = Enum.TextXAlignment.Left
	SelectedValue.ZIndex = 6
	SelectedValue.Parent = DropdownFrame
	
	-- Arrow Icon
	local Arrow = Instance.new("TextLabel")
	Arrow.Name = "Arrow"
	Arrow.Size = UDim2.new(0, 20, 0, 20)
	Arrow.Position = UDim2.new(1, -28, 0.5, -10)
	Arrow.BackgroundTransparency = 1
	Arrow.Text = "▼"
	Arrow.TextColor3 = COLORS.TextDim
	Arrow.TextSize = 10
	Arrow.Font = Enum.Font.GothamBold
	Arrow.ZIndex = 6
	Arrow.Parent = DropdownFrame
	
	-- Dropdown Button
	local DropdownButton = Instance.new("TextButton")
	DropdownButton.Size = UDim2.new(1, 0, 1, 0)
	DropdownButton.BackgroundTransparency = 1
	DropdownButton.Text = ""
	DropdownButton.ZIndex = 7
	DropdownButton.Parent = DropdownFrame
	
	-- Options Container (Scrollable)
	local OptionsContainer = Instance.new("ScrollingFrame")
	OptionsContainer.Name = "Options"
	OptionsContainer.Size = UDim2.new(1, 0, 0, 0)
	OptionsContainer.Position = UDim2.new(0, 0, 1, 5)
	OptionsContainer.BackgroundColor3 = COLORS.Surface
	OptionsContainer.BackgroundTransparency = 0.3
	OptionsContainer.BorderSizePixel = 0
	OptionsContainer.Visible = false
	OptionsContainer.ZIndex = 10
	OptionsContainer.ClipsDescendants = true
	OptionsContainer.ScrollBarThickness = 4
	OptionsContainer.ScrollBarImageColor3 = COLORS.Accent
	OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	OptionsContainer.Parent = DropdownFrame
	CreateCorner(OptionsContainer, 8)
	CreateStroke(OptionsContainer, COLORS.Accent, 1.5, 0.3)
	
	local OptionsLayout = Instance.new("UIListLayout")
	OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	OptionsLayout.Padding = UDim.new(0, 2)
	OptionsLayout.Parent = OptionsContainer
	
	local OptionsPadding = Instance.new("UIPadding")
	OptionsPadding.PaddingTop = UDim.new(0, 4)
	OptionsPadding.PaddingBottom = UDim.new(0, 4)
	OptionsPadding.PaddingLeft = UDim.new(0, 4)
	OptionsPadding.PaddingRight = UDim.new(0, 8)
	OptionsPadding.Parent = OptionsContainer
	
	-- Auto-update canvas size
	OptionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, OptionsLayout.AbsoluteContentSize.Y + 8)
	end)
	
	-- Create option buttons
	for _, option in ipairs(options) do
		local OptionButton = Instance.new("TextButton")
		OptionButton.Name = option
		OptionButton.Size = UDim2.new(1, -8, 0, 30)
		OptionButton.BackgroundColor3 = COLORS.SurfaceLight
		OptionButton.BackgroundTransparency = 0.5
		OptionButton.BorderSizePixel = 0
		OptionButton.Text = option
		OptionButton.TextColor3 = COLORS.Text
		OptionButton.TextSize = 13
		OptionButton.Font = Enum.Font.GothamMedium
		OptionButton.ZIndex = 11
		OptionButton.Parent = OptionsContainer
		CreateCorner(OptionButton, 6)
		
		-- Click handler
		OptionButton.MouseButton1Click:Connect(function()
			selected = option
			SelectedValue.Text = option
			self.Window.Settings[flag] = option
			
			-- Close dropdown
			isOpen = false
			DropdownSpacer.Visible = false
			DropdownSpacer.Size = UDim2.new(1, 0, 0, 0)
			Tween(OptionsContainer, {Size = UDim2.new(1, 0, 0, 0)}, ANIM.Smooth)
			Tween(Arrow, {Rotation = 0}, ANIM.Smooth)
			task.wait(0.3)
			OptionsContainer.Visible = false
			
			callback(option)
		end)
		
		-- Hover effect
		OptionButton.MouseEnter:Connect(function()
			Tween(OptionButton, {BackgroundColor3 = COLORS.Accent, BackgroundTransparency = 0.3}, ANIM.Elastic)
		end)
		
		OptionButton.MouseLeave:Connect(function()
			Tween(OptionButton, {BackgroundColor3 = COLORS.SurfaceLight, BackgroundTransparency = 0.5}, ANIM.Elastic)
		end)
	end
	
	-- Toggle dropdown
	DropdownButton.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		
		if isOpen then
			OptionsContainer.Visible = true
			OptionsContainer.Size = UDim2.new(1, 0, 0, 0)
			local targetSize = math.min(#options * 32 + 8, 150)
			-- Show spacer to push content down
			DropdownSpacer.Visible = true
			DropdownSpacer.Size = UDim2.new(1, 0, 0, targetSize + 5)
			Tween(OptionsContainer, {Size = UDim2.new(1, 0, 0, targetSize)}, ANIM.Smooth)
			Tween(Arrow, {Rotation = 180}, ANIM.Smooth)
		else
			-- Hide spacer
			DropdownSpacer.Visible = false
			DropdownSpacer.Size = UDim2.new(1, 0, 0, 0)
			Tween(OptionsContainer, {Size = UDim2.new(1, 0, 0, 0)}, ANIM.Smooth)
			Tween(Arrow, {Rotation = 0}, ANIM.Smooth)
			task.wait(0.3)
			OptionsContainer.Visible = false
		end
	end)
	
	-- Hover effect
	DropdownButton.MouseEnter:Connect(function()
		Tween(DropdownFrame, {BackgroundTransparency = 0.3}, ANIM.Elastic)
	end)
	
	DropdownButton.MouseLeave:Connect(function()
		Tween(DropdownFrame, {BackgroundTransparency = 0.5}, ANIM.Elastic)
	end)
	
	return {
		SetValue = function(value)
			selected = value
			SelectedValue.Text = value
		end
	}
end

-- Add Info Label
function Library:AddLabel(config)
	config = config or {}
	local labelText = config.Text or "Label"
	local color = config.Color or COLORS.Text
	
	-- Label Container
	local LabelFrame = Instance.new("Frame")
	LabelFrame.Name = "LabelFrame"
	LabelFrame.Size = UDim2.new(1, -16, 0, 32)
	LabelFrame.BackgroundColor3 = COLORS.Surface
	LabelFrame.BackgroundTransparency = 0
	LabelFrame.BorderSizePixel = 0
	LabelFrame.ZIndex = 5
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	LabelFrame.Parent = __parent
	CreateCorner(LabelFrame, 8)
	CreateStroke(LabelFrame, COLORS.Border, 1, 0.7)
	
	-- Label Text
	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.new(1, -16, 1, 0)
	Label.Position = UDim2.new(0, 8, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = labelText
	Label.TextColor3 = color
	Label.TextSize = 13
	Label.Font = Enum.Font.Gotham
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextWrapped = true
	Label.ZIndex = 6
	Label.Parent = LabelFrame
	
	return {
		SetText = function(self, text)
			Label.Text = tostring(text)
		end,
		SetColor = function(self, newColor)
			Label.TextColor3 = newColor
		end
	}
end

-- Add Wide Label (spans both columns, simpler than notes, respects position)
function Library:AddLabelWide(config)
	config = config or {}
	local text = config.Text or "Wide Label"
	local color = config.Color or COLORS.Text
	
	-- Initialize counter if it doesn't exist
	if not self.Page._wideLabelCounter then
		self.Page._wideLabelCounter = 200 -- Start after columns (100) and notes (50)
	end
	self.Page._wideLabelCounter = self.Page._wideLabelCounter + 1
	
	-- Wide label container - spans full width like notes but simpler
	local WideLabel = Instance.new("Frame")
	WideLabel.Name = "WideLabel"
	WideLabel.Size = UDim2.new(1, -16, 0, 32)
	WideLabel.BackgroundColor3 = COLORS.Surface
	WideLabel.BackgroundTransparency = 0.4
	WideLabel.BorderSizePixel = 0
	WideLabel.ZIndex = 4
	WideLabel.LayoutOrder = self.Page._wideLabelCounter
	WideLabel.Parent = self.Page
	CreateCorner(WideLabel, 8)
	CreateStroke(WideLabel, COLORS.Border, 1, 0.7)
	
	-- Text label
	local TextLabel = Instance.new("TextLabel")
	TextLabel.Name = "Text"
	TextLabel.Size = UDim2.new(1, 0, 1, 0)
	TextLabel.BackgroundTransparency = 1
	TextLabel.Text = text
	TextLabel.TextColor3 = color
	TextLabel.TextSize = 14
	TextLabel.Font = Enum.Font.GothamMedium
	TextLabel.TextXAlignment = Enum.TextXAlignment.Center
	TextLabel.ZIndex = 5
	TextLabel.Parent = WideLabel
	
	-- Padding
	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 8)
	Padding.Parent = TextLabel
	
	return {
		SetText = function(self, text)
			TextLabel.Text = tostring(text)
		end,
		SetColor = function(self, newColor)
			TextLabel.TextColor3 = newColor
		end
	}
end

-- Add Color Picker
function Library:AddNoteWide(config)
    config = config or {}
    local text = config.Text or ""
    local color = config.Color or COLORS.Text
    local bg = config.BackgroundColor or COLORS.Surface
    local height = config.Height or 38
    local order = config.LayoutOrder or 50 -- shown before columns (columns at 100)

    -- Full width banner on the TabPage, spanning all columns
    local Banner = Instance.new("Frame")
    Banner.Name = "NoteWide"
    Banner.Size = UDim2.new(1, -16, 0, height)
    Banner.BackgroundColor3 = bg
    Banner.BackgroundTransparency = 0
    Banner.BorderSizePixel = 0
    Banner.ZIndex = 4
    Banner.LayoutOrder = order
    Banner.Parent = self.Page
    CreateCorner(Banner, 8)
    CreateStroke(Banner, COLORS.Border, 1, 0.6)

    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.PaddingRight = UDim.new(0, 10)
    Padding.Parent = Banner

    local Label = Instance.new("TextLabel")
    Label.Name = "Text"
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = color
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Center
    Label.TextYAlignment = Enum.TextYAlignment.Center
    Label.TextWrapped = true
    Label.ZIndex = 5
    Label.Parent = Banner

    return {
        SetText = function(_, t)
            Label.Text = tostring(t)
        end,
        SetColor = function(_, c)
            Label.TextColor3 = c
        end,
        SetBackground = function(_, c)
            Banner.BackgroundColor3 = c
        end,
        SetOrder = function(_, o)
            Banner.LayoutOrder = o
        end
    }
end
function Library:AddColorPicker(config)
	config = config or {}
	local pickerText = config.Text or "Color Picker"
	local default = config.Default or Color3.fromRGB(255, 255, 255)
	local callback = config.Callback or function() end
	local flag = config.Flag or pickerText
	
	-- Load saved color
	local savedColor = self.Window.Settings[flag]
	local currentColor = savedColor and Color3.fromRGB(savedColor.r, savedColor.g, savedColor.b) or default
	
	-- Color Picker Container
	local PickerFrame = Instance.new("Frame")
	PickerFrame.Name = "ColorPickerFrame"
	PickerFrame.Size = UDim2.new(1, -16, 0, 200)
	PickerFrame.BackgroundColor3 = COLORS.Surface
	PickerFrame.BackgroundTransparency = 0
	PickerFrame.BorderSizePixel = 0
	PickerFrame.ZIndex = 5
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	PickerFrame.Parent = __parent
	CreateCorner(PickerFrame, 8)
	CreateStroke(PickerFrame, COLORS.Border, 1, 0.6)
	
	-- Label
	local PickerLabel = Instance.new("TextLabel")
	PickerLabel.Name = "Label"
	PickerLabel.Size = UDim2.new(1, -60, 0, 25)
	PickerLabel.Position = UDim2.new(0, 10, 0, 5)
	PickerLabel.BackgroundTransparency = 1
	PickerLabel.Text = pickerText
	PickerLabel.TextColor3 = COLORS.Text
	PickerLabel.TextSize = 14
	PickerLabel.Font = Enum.Font.GothamMedium
	PickerLabel.TextXAlignment = Enum.TextXAlignment.Left
	PickerLabel.ZIndex = 6
	PickerLabel.Parent = PickerFrame
	
	-- Color Preview
	local ColorPreview = Instance.new("Frame")
	ColorPreview.Name = "Preview"
	ColorPreview.Size = UDim2.new(0, 45, 0, 25)
	ColorPreview.Position = UDim2.new(1, -55, 0, 5)
	ColorPreview.BackgroundColor3 = currentColor
	ColorPreview.BorderSizePixel = 0
	ColorPreview.ZIndex = 6
	ColorPreview.Parent = PickerFrame
	CreateCorner(ColorPreview, 6)
	CreateStroke(ColorPreview, COLORS.Border, 2, 0.4)
	
	-- RGB Sliders
	local function createColorSlider(name, colorIndex, yPos, defaultVal)
		local sliderLabel = Instance.new("TextLabel")
		sliderLabel.Size = UDim2.new(0, 30, 0, 20)
		sliderLabel.Position = UDim2.new(0, 10, 0, yPos)
		sliderLabel.BackgroundTransparency = 1
		sliderLabel.Text = name
		sliderLabel.TextColor3 = COLORS.Text
		sliderLabel.TextSize = 13
		sliderLabel.Font = Enum.Font.GothamBold
		sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
		sliderLabel.ZIndex = 6
		sliderLabel.Parent = PickerFrame
		
		local sliderValue = Instance.new("TextLabel")
		sliderValue.Size = UDim2.new(0, 35, 0, 20)
		sliderValue.Position = UDim2.new(1, -45, 0, yPos)
		sliderValue.BackgroundTransparency = 1
		sliderValue.Text = tostring(math.floor(defaultVal))
		sliderValue.TextColor3 = COLORS.Accent
		sliderValue.TextSize = 12
		sliderValue.Font = Enum.Font.GothamBold
		sliderValue.TextXAlignment = Enum.TextXAlignment.Right
		sliderValue.ZIndex = 6
		sliderValue.Parent = PickerFrame
		
		local sliderBar = Instance.new("Frame")
		sliderBar.Position = UDim2.new(0, 45, 0, yPos + 5)
		sliderBar.Size = UDim2.new(1, -100, 0, 10)
		sliderBar.BackgroundColor3 = COLORS.SurfaceLight
		sliderBar.BorderSizePixel = 0
		sliderBar.ZIndex = 6
		sliderBar.Parent = PickerFrame
		CreateCorner(sliderBar, 5)
		
		local sliderFill = Instance.new("Frame")
		sliderFill.Size = UDim2.new(defaultVal / 255, 0, 1, 0)
		sliderFill.BackgroundColor3 = colorIndex == 1 and Color3.fromRGB(255, 0, 0) or (colorIndex == 2 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 255))
		sliderFill.BorderSizePixel = 0
		sliderFill.ZIndex = 7
		sliderFill.Parent = sliderBar
		CreateCorner(sliderFill, 5)
		
		local sliderKnob = Instance.new("Frame")
		sliderKnob.Size = UDim2.new(0, 16, 0, 16)
		sliderKnob.Position = UDim2.new(1, 0, 0.5, 0)
		sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
		sliderKnob.BackgroundColor3 = COLORS.Text
		sliderKnob.BorderSizePixel = 0
		sliderKnob.ZIndex = 8
		sliderKnob.Parent = sliderFill
		CreateCorner(sliderKnob, 8)
		CreateStroke(sliderKnob, COLORS.Accent, 2, 0)
		
		local sliderButton = Instance.new("TextButton")
		sliderButton.Size = UDim2.new(1, 20, 0, 30)
		sliderButton.Position = UDim2.new(0, -10, 0, -10)
		sliderButton.BackgroundTransparency = 1
		sliderButton.Text = ""
		sliderButton.ZIndex = 9
		sliderButton.Parent = sliderBar
		
		local dragging = false
		
		local function updateSlider(x)
			local relativeX = x - sliderBar.AbsolutePosition.X
			local percentage = math.clamp(relativeX / sliderBar.AbsoluteSize.X, 0, 1)
			local value = math.floor(percentage * 255)
			
			sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
			sliderValue.Text = tostring(value)
			
			-- Update color
			local r = currentColor.R * 255
			local g = currentColor.G * 255
			local b = currentColor.B * 255
			
			if colorIndex == 1 then r = value
			elseif colorIndex == 2 then g = value
			else b = value end
			
			currentColor = Color3.fromRGB(r, g, b)
			ColorPreview.BackgroundColor3 = currentColor
			
			self.Window.Settings[flag] = {r = r, g = g, b = b}
			callback(currentColor)
		end
		
		sliderButton.MouseButton1Down:Connect(function()
			dragging = true
			Tween(sliderKnob, {Size = UDim2.new(0, 20, 0, 20)}, ANIM.Elastic)
		end)
		
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
				Tween(sliderKnob, {Size = UDim2.new(0, 16, 0, 16)}, ANIM.Elastic)
			end
		end)
		
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
				updateSlider(input.Position.X)
			end
		end)
		
		sliderButton.MouseButton1Click:Connect(function()
			updateSlider(UserInputService:GetMouseLocation().X)
		end)
	end
	
	-- Create RGB sliders
	createColorSlider("R:", 1, 40, currentColor.R * 255)
	createColorSlider("G:", 2, 75, currentColor.G * 255)
	createColorSlider("B:", 3, 110, currentColor.B * 255)
	
	-- Preset colors
	local presetY = 150
	local presetColors = {
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(0, 255, 0),
		Color3.fromRGB(0, 0, 255),
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(255, 0, 255),
		Color3.fromRGB(0, 255, 255),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(0, 0, 0)
	}
	
	for i, presetColor in ipairs(presetColors) do
		local presetBtn = Instance.new("TextButton")
		presetBtn.Size = UDim2.new(0, 30, 0, 30)
		presetBtn.Position = UDim2.new(0, 10 + (i - 1) * 35, 0, presetY)
		presetBtn.BackgroundColor3 = presetColor
		presetBtn.BorderSizePixel = 0
		presetBtn.Text = ""
		presetBtn.ZIndex = 6
		presetBtn.Parent = PickerFrame
		CreateCorner(presetBtn, 6)
		CreateStroke(presetBtn, COLORS.Border, 2, 0.4)
		
		presetBtn.MouseButton1Click:Connect(function()
			currentColor = presetColor
			ColorPreview.BackgroundColor3 = currentColor
			self.Window.Settings[flag] = {r = presetColor.R * 255, g = presetColor.G * 255, b = presetColor.B * 255}
			callback(currentColor)
			
			-- Update sliders visually (would need references to update properly)
			Tween(presetBtn, {Size = UDim2.new(0, 35, 0, 35)}, ANIM.Fast)
			task.wait(0.1)
			Tween(presetBtn, {Size = UDim2.new(0, 30, 0, 30)}, ANIM.Elastic)
		end)
		
		presetBtn.MouseEnter:Connect(function()
			Tween(presetBtn, {Size = UDim2.new(0, 33, 0, 33)}, ANIM.Fast)
		end)
		
		presetBtn.MouseLeave:Connect(function()
			Tween(presetBtn, {Size = UDim2.new(0, 30, 0, 30)}, ANIM.Fast)
		end)
	end
	
	return {
		SetColor = function(self, color)
			currentColor = color
			ColorPreview.BackgroundColor3 = color
		end,
		GetColor = function(self)
			return currentColor
		end
	}
end

-- Add TextBox
function Library:AddTextBox(config)
	config = config or {}
	local textboxText = config.Text or "TextBox"
	local placeholder = config.Placeholder or "Enter text..."
	local default = config.Default or ""
	local callback = config.Callback or function() end
	local flag = config.Flag or textboxText
	
	-- Load saved value or use default
	local currentText = self.Window.Settings[flag] or default
	
	-- TextBox Container
	local TextBoxFrame = Instance.new("Frame")
	TextBoxFrame.Name = "TextBoxFrame"
	TextBoxFrame.Size = UDim2.new(1, -16, 0, 70)
	TextBoxFrame.BackgroundColor3 = COLORS.Surface
	TextBoxFrame.BackgroundTransparency = 0
	TextBoxFrame.BorderSizePixel = 0
	TextBoxFrame.ZIndex = 5
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	TextBoxFrame.Parent = __parent
	CreateCorner(TextBoxFrame, 8)
	CreateStroke(TextBoxFrame, COLORS.Border, 1, 0.6)
	
	-- Label
	local TextBoxLabel = Instance.new("TextLabel")
	TextBoxLabel.Name = "Label"
	TextBoxLabel.Size = UDim2.new(1, -20, 0, 20)
	TextBoxLabel.Position = UDim2.new(0, 10, 0, 5)
	TextBoxLabel.BackgroundTransparency = 1
	TextBoxLabel.Text = textboxText
	TextBoxLabel.TextColor3 = COLORS.Text
	TextBoxLabel.TextSize = 14
	TextBoxLabel.Font = Enum.Font.GothamMedium
	TextBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
	TextBoxLabel.ZIndex = 6
	TextBoxLabel.Parent = TextBoxFrame
	
	-- TextBox Input
	local TextBoxInput = Instance.new("TextBox")
	TextBoxInput.Name = "Input"
	TextBoxInput.Size = UDim2.new(1, -20, 0, 35)
	TextBoxInput.Position = UDim2.new(0, 10, 0, 30)
	TextBoxInput.BackgroundColor3 = COLORS.SurfaceLight
	TextBoxInput.BackgroundTransparency = 0
	TextBoxInput.BorderSizePixel = 0
	TextBoxInput.Text = currentText
	TextBoxInput.PlaceholderText = placeholder
	TextBoxInput.TextColor3 = COLORS.Text
	TextBoxInput.PlaceholderColor3 = COLORS.TextDim
	TextBoxInput.TextSize = 13
	TextBoxInput.Font = Enum.Font.Gotham
	TextBoxInput.ClearTextOnFocus = false
	TextBoxInput.ZIndex = 7
	TextBoxInput.Parent = TextBoxFrame
	CreateCorner(TextBoxInput, 6)
	CreateStroke(TextBoxInput, COLORS.Accent, 1, 0.5)
	
	-- Update on text change
	TextBoxInput.FocusLost:Connect(function(enterPressed)
		currentText = TextBoxInput.Text
		self.Window.Settings[flag] = currentText
		callback(currentText, enterPressed)
	end)
	
	-- Hover effect
	TextBoxInput.MouseEnter:Connect(function()
		Tween(TextBoxFrame, {BackgroundTransparency = 0.3}, ANIM.Elastic)
	end)
	
	TextBoxInput.MouseLeave:Connect(function()
		Tween(TextBoxFrame, {BackgroundTransparency = 0.5}, ANIM.Elastic)
	end)
	
	return {
		SetText = function(self, text)
			TextBoxInput.Text = text
			currentText = text
		end,
		GetText = function(self)
			return currentText
		end
	}
end

-- Add Potion List with Favorites
function Library:AddPotionList(config)
	config = config or {}
	local potions = config.Potions or {}
	local favorites = config.Favorites or {}
	local onSelect = config.OnSelect or function() end
	local onFavorite = config.OnFavorite or function() end
	local height = config.Height or 250
	
	-- Container
	local ListFrame = Instance.new("ScrollingFrame")
	ListFrame.Name = "PotionListFrame"
	ListFrame.Size = UDim2.new(1, -16, 0, height)
	ListFrame.BackgroundColor3 = COLORS.Surface
	ListFrame.BackgroundTransparency = 0
	ListFrame.BorderSizePixel = 0
	ListFrame.ScrollBarThickness = 6
	ListFrame.ScrollBarImageColor3 = COLORS.Accent
	ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ListFrame.ZIndex = 5
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	ListFrame.Parent = __parent
	CreateCorner(ListFrame, 8)
	CreateStroke(ListFrame, COLORS.Border, 1, 0.6)
	
	local ListLayout = Instance.new("UIListLayout")
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Padding = UDim.new(0, 4)
	ListLayout.Parent = ListFrame
	
	local ListPadding = Instance.new("UIPadding")
	ListPadding.PaddingTop = UDim.new(0, 6)
	ListPadding.PaddingBottom = UDim.new(0, 6)
	ListPadding.PaddingLeft = UDim.new(0, 6)
	ListPadding.PaddingRight = UDim.new(0, 6)
	ListPadding.Parent = ListFrame
	
	local selectedButton = nil
	local buttons = {}
	
	local function getLayoutOrder(potionName)
		local isFavorited = favorites[potionName] or false
		local baseOrder = 0
		for i = 1, #potionName do
			baseOrder = baseOrder + potionName:byte(i)
		end
		return isFavorited and baseOrder or (10000 + baseOrder)
	end
	
	local function createPotionButton(potionName)
		local btn = Instance.new("TextButton")
		btn.Name = potionName
		btn.Size = UDim2.new(1, -8, 0, 38)
		btn.BackgroundColor3 = COLORS.SurfaceLight
		btn.BackgroundTransparency = 0.3
		btn.BorderSizePixel = 0
		btn.Text = "  " .. potionName
		btn.TextColor3 = COLORS.Text
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 13
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.ZIndex = 6
		btn.LayoutOrder = getLayoutOrder(potionName)
		btn.Parent = ListFrame
		CreateCorner(btn, 6)
		CreateStroke(btn, COLORS.Border, 1, 0.7)
		
		-- Star button
		local starBtn = Instance.new("TextButton")
		starBtn.Name = "StarButton"
		starBtn.Size = UDim2.new(0, 35, 1, 0)
		starBtn.Position = UDim2.new(1, -35, 0, 0)
		starBtn.BackgroundTransparency = 1
		starBtn.Text = favorites[potionName] and "★" or "☆"
		starBtn.TextColor3 = favorites[potionName] and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(100, 100, 100)
		starBtn.Font = Enum.Font.GothamBold
		starBtn.TextSize = 18
		starBtn.ZIndex = 7
		starBtn.Parent = btn
		
		starBtn.MouseButton1Click:Connect(function()
			favorites[potionName] = not favorites[potionName]
			starBtn.Text = favorites[potionName] and "★" or "☆"
			Tween(starBtn, {TextColor3 = favorites[potionName] and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(100, 100, 100)}, ANIM.Fast)
			btn.LayoutOrder = getLayoutOrder(potionName)
			onFavorite(potionName, favorites[potionName])
		end)
		
		-- Hover effects
		btn.MouseEnter:Connect(function()
			if btn ~= selectedButton then
				Tween(btn, {BackgroundTransparency = 0.15}, ANIM.Fast)
			end
		end)
		
		btn.MouseLeave:Connect(function()
			if btn ~= selectedButton then
				Tween(btn, {BackgroundTransparency = 0.3}, ANIM.Fast)
			end
		end)
		
		btn.MouseButton1Click:Connect(function()
			if selectedButton then
				Tween(selectedButton, {BackgroundColor3 = COLORS.SurfaceLight, BackgroundTransparency = 0.3}, ANIM.Fast)
			end
			selectedButton = btn
			Tween(btn, {BackgroundColor3 = COLORS.Accent, BackgroundTransparency = 0.2}, ANIM.Fast)
			onSelect(potionName)
		end)
		
		buttons[potionName] = btn
	end
	
	for potionName in pairs(potions) do
		createPotionButton(potionName)
	end
	
	return {
		Refresh = function()
			for potionName, btn in pairs(buttons) do
				btn.LayoutOrder = getLayoutOrder(potionName)
			end
		end,
		GetSelected = function()
			return selectedButton and selectedButton.Name or nil
		end
	}
end

-- Add Ingredient Display (Scrollable)
function Library:AddIngredientDisplay(config)
	config = config or {}
	local height = config.Height or 150
	
	-- Container
	local DisplayFrame = Instance.new("ScrollingFrame")
	DisplayFrame.Name = "IngredientDisplay"
	DisplayFrame.Size = UDim2.new(1, -16, 0, height)
	DisplayFrame.BackgroundColor3 = COLORS.Surface
	DisplayFrame.BackgroundTransparency = 0
	DisplayFrame.BorderSizePixel = 0
	DisplayFrame.ScrollBarThickness = 6
	DisplayFrame.ScrollBarImageColor3 = COLORS.Accent
	DisplayFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	DisplayFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	DisplayFrame.ZIndex = 5
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	DisplayFrame.Parent = __parent
	CreateCorner(DisplayFrame, 8)
	CreateStroke(DisplayFrame, COLORS.Border, 1, 0.6)
	
	local DisplayLayout = Instance.new("UIListLayout")
	DisplayLayout.SortOrder = Enum.SortOrder.LayoutOrder
	DisplayLayout.Padding = UDim.new(0, 4)
	DisplayLayout.Parent = DisplayFrame
	
	local DisplayPadding = Instance.new("UIPadding")
	DisplayPadding.PaddingTop = UDim.new(0, 8)
	DisplayPadding.PaddingBottom = UDim.new(0, 8)
	DisplayPadding.PaddingLeft = UDim.new(0, 8)
	DisplayPadding.PaddingRight = UDim.new(0, 8)
	DisplayPadding.Parent = DisplayFrame
	
	return {
		Clear = function()
			for _, child in ipairs(DisplayFrame:GetChildren()) do
				if child:IsA("TextLabel") then
					child:Destroy()
				end
			end
		end,
		AddLine = function(text, color)
			local line = Instance.new("TextLabel")
			line.Size = UDim2.new(1, -8, 0, 20)
			line.BackgroundTransparency = 1
			line.Text = text
			line.TextColor3 = color or COLORS.Text
			line.Font = Enum.Font.Gotham
			line.TextSize = 13
			line.TextXAlignment = Enum.TextXAlignment.Left
			line.ZIndex = 6
			line.Parent = DisplayFrame
		end,
		SetEmpty = function(text)
			for _, child in ipairs(DisplayFrame:GetChildren()) do
				if child:IsA("TextLabel") then
					child:Destroy()
				end
			end
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, -8, 1, -16)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = text or "No data"
			emptyLabel.TextColor3 = COLORS.TextDim
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.TextSize = 13
			emptyLabel.ZIndex = 6
			emptyLabel.Parent = DisplayFrame
		end
	}
end

-- Add Keybind
function Library:AddKeybind(config)
	config = config or {}
	local keybindText = config.Text or "Keybind"
	local default = config.Default or Enum.KeyCode.E
	local callback = config.Callback or function() end
	local flag = config.Flag or keybindText
	
	-- Load saved keybind
	local savedKey = self.Window.Settings[flag]
	local currentKey = savedKey and Enum.KeyCode[savedKey] or default
	local isBinding = false
	
	-- Keybind Container
	local KeybindFrame = Instance.new("Frame")
	KeybindFrame.Name = "KeybindFrame"
	KeybindFrame.Size = UDim2.new(1, -16, 0, 40)
	KeybindFrame.BackgroundColor3 = COLORS.Surface
	KeybindFrame.BackgroundTransparency = 0
	KeybindFrame.BorderSizePixel = 0
	KeybindFrame.ZIndex = 5
	local __parent = (self.GetNextParent and self:GetNextParent() or self.Page)
	KeybindFrame.Parent = __parent
	CreateCorner(KeybindFrame, 8)
	CreateStroke(KeybindFrame, COLORS.Border, 1, 0.6)
	
	-- Label
	local KeybindLabel = Instance.new("TextLabel")
	KeybindLabel.Name = "Label"
	KeybindLabel.Size = UDim2.new(1, -110, 1, 0)
	KeybindLabel.Position = UDim2.new(0, 12, 0, 0)
	KeybindLabel.BackgroundTransparency = 1
	KeybindLabel.Text = keybindText
	KeybindLabel.TextColor3 = COLORS.Text
	KeybindLabel.TextSize = 14
	KeybindLabel.Font = Enum.Font.GothamMedium
	KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
	KeybindLabel.ZIndex = 6
	KeybindLabel.Parent = KeybindFrame
	
	-- Key Display
	local KeyDisplay = Instance.new("TextLabel")
	KeyDisplay.Name = "KeyDisplay"
	KeyDisplay.Size = UDim2.new(0, 90, 0, 28)
	KeyDisplay.Position = UDim2.new(1, -100, 0.5, -14)
	KeyDisplay.BackgroundColor3 = COLORS.SurfaceLight
	KeyDisplay.BackgroundTransparency = 0.3
	KeyDisplay.BorderSizePixel = 0
	KeyDisplay.Text = "[" .. currentKey.Name .. "]"
	KeyDisplay.TextColor3 = COLORS.Accent
	KeyDisplay.TextSize = 13
	KeyDisplay.Font = Enum.Font.GothamBold
	KeyDisplay.ZIndex = 7
	KeyDisplay.Parent = KeybindFrame
	CreateCorner(KeyDisplay, 6)
	CreateStroke(KeyDisplay, COLORS.Accent, 1, 0.5)
	
	-- Keybind Button
	local KeybindButton = Instance.new("TextButton")
	KeybindButton.Size = UDim2.new(1, 0, 1, 0)
	KeybindButton.BackgroundTransparency = 1
	KeybindButton.Text = ""
	KeybindButton.ZIndex = 8
	KeybindButton.Parent = KeybindFrame
	
	-- Update key display
	local function UpdateKey(key)
		currentKey = key
		self.Window.Settings[flag] = key.Name
		KeyDisplay.Text = "[" .. key.Name .. "]"
	end
	
	-- Click to rebind
	KeybindButton.MouseButton1Click:Connect(function()
		if isBinding then return end
		isBinding = true
		KeyDisplay.Text = "[...]"
		Tween(KeyDisplay, {BackgroundColor3 = COLORS.Accent, BackgroundTransparency = 0.2}, ANIM.Elastic)
		Tween(KeybindFrame, {BackgroundColor3 = COLORS.Accent, BackgroundTransparency = 0.4}, ANIM.Elastic)
	end)
	
	-- Listen for key press
	local bindConnection
	bindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if isBinding and input.UserInputType == Enum.UserInputType.Keyboard then
			isBinding = false
			UpdateKey(input.KeyCode)
			Tween(KeyDisplay, {BackgroundColor3 = COLORS.SurfaceLight, BackgroundTransparency = 0.3}, ANIM.Elastic)
			Tween(KeybindFrame, {BackgroundColor3 = COLORS.Surface, BackgroundTransparency = 0.5}, ANIM.Elastic)
			return
		end
		
		-- Execute callback when key is pressed (not while binding)
		if not gameProcessed and not isBinding and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
			Tween(KeyDisplay, {BackgroundTransparency = 0}, ANIM.Fast)
			task.spawn(function()
				callback()
			end)
			task.wait(0.15)
			Tween(KeyDisplay, {BackgroundTransparency = 0.3}, ANIM.Fast)
		end
	end)
	
	-- Hover effect
	KeybindButton.MouseEnter:Connect(function()
		if not isBinding then
			Tween(KeybindFrame, {BackgroundTransparency = 0.3}, ANIM.Elastic)
		end
	end)
	
	KeybindButton.MouseLeave:Connect(function()
		if not isBinding then
			Tween(KeybindFrame, {BackgroundTransparency = 0.5}, ANIM.Elastic)
		end
	end)
	
	return {
		SetKey = function(self, key)
			UpdateKey(key)
		end
	}
end

return Library
