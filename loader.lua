local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local FILE_NAME = "LunarAimbotConfig.json"

-- == Цветовая тема (Lunar Theme) ==
local Theme = {
	Background = Color3.fromRGB(22, 22, 28),
	Panel = Color3.fromRGB(30, 30, 38),
	Accent = Color3.fromRGB(155, 109, 255),
	AccentHover = Color3.fromRGB(175, 135, 255),
	TextTitle = Color3.fromRGB(255, 255, 255),
	TextNormal = Color3.fromRGB(200, 200, 210),
	ToggleOff = Color3.fromRGB(45, 45, 55),
	ToggleCircle = Color3.fromRGB(240, 240, 245),
	DropdownBg = Color3.fromRGB(26, 26, 32)
}

-- == Переводы (Localization) ==
local Locales = {
	en = {
		Title = "L U N A R   A I M",
		EnableAim = "Enable Aimbot",
		AlwaysAim = "Always Target",
		AutoShoot = "Auto Shoot",
		TargetBone = "Aim Target",
		Smoothness = "Smoothness",
		ShowFOV = "Show FOV Circle",
		FOVRadius = "FOV Radius",
		WallCheck = "Wall Check",
		PlayerESP = "Player ESP (WH)",
		Language = "Language",
		Head = "Head", Torso = "Torso", Legs = "Legs",
		English = "English", Russian = "Русский"
	},
	ru = {
		Title = "L U N A R   A I M",
		EnableAim = "Включить Аимбот",
		AlwaysAim = "Постоянный захват",
		AutoShoot = "Авто-выстрел",
		TargetBone = "Часть тела",
		Smoothness = "Плавность наводки",
		ShowFOV = "Показывать круг FOV",
		FOVRadius = "Радиус круга FOV",
		WallCheck = "Проверка стен",
		PlayerESP = "ВХ на игроков",
		Language = "Язык меню",
		Head = "Голова", Torso = "Тело", Legs = "Ноги",
		English = "English", Russian = "Русский"
	}
}

-- == Дефолтные настройки ==
local Config = {
	Enabled = false,
	AlwaysAim = true,
	AutoShoot = false,
	ShowFOV = true,
	FOV = 150,
	WallCheck = true,
	ESPEnabled = false,
	TargetPart = "Head", -- "Head", "Torso", "Legs"
	Language = "en",      -- "en", "ru"
	Smoothness = 1,
	AimKey = Enum.UserInputType.MouseButton2,
	MenuKey = Enum.KeyCode.RightShift,
	ToggleAimKey = Enum.KeyCode.T,
	ToggleShootKey = Enum.KeyCode.G
}

local Connections = {}
local UIElements = {}
local TranslatableLabels = {}

-- == Сохранение и Загрузка ==
local function SaveConfig()
	if writefile then
		local dataToSave = {}
		for k, v in pairs(Config) do
			if typeof(v) == "EnumItem" then
				dataToSave[k] = {["Type"] = tostring(v.EnumType), ["Name"] = v.Name}
			else
				dataToSave[k] = v
			end
		end
		pcall(function() writefile(FILE_NAME, HttpService:JSONEncode(dataToSave)) end)
	end
end

local function LoadConfig()
	if readfile and isfile and isfile(FILE_NAME) then
		local success, content = pcall(function() return readfile(FILE_NAME) end)
		if success and content then
			local decodeSuccess, decoded = pcall(function() return HttpService:JSONDecode(content) end)
			if decodeSuccess and type(decoded) == "table" then
				for k, v in pairs(decoded) do
					if Config[k] ~= nil then
						if type(v) == "table" and v.Type and v.Name then
							pcall(function() Config[k] = Enum[v.Type][v.Name] end)
						else
							Config[k] = v
						end
					end
				end
			end
		end
	end
end

LoadConfig()

local IsAiming = false
local BindingKey = nil
local CurrentTarget = nil
local IsShooting = false

-- == Создание UI ==
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LunarAimbotUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Круг FOV
local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = Config.ShowFOV
FOVCircle.Parent = ScreenGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Theme.Accent
FOVStroke.Thickness = 1.2
FOVStroke.Transparency = 0.4
FOVStroke.Parent = FOVCircle

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 420)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = false -- Чтобы выпадающие меню не резались краями окна
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

-- Отрисовка уникального логотипа
local LogoBase = Instance.new("Frame")
LogoBase.Size = UDim2.new(0, 24, 0, 24)
LogoBase.Position = UDim2.new(0, 15, 0, 13)
LogoBase.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LogoBase.Parent = MainFrame
Instance.new("UICorner", LogoBase).CornerRadius = UDim.new(1, 0)

local LogoGradient = Instance.new("UIGradient")
LogoGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Theme.Accent),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 50, 180))
}
LogoGradient.Rotation = 45
LogoGradient.Parent = LogoBase

local LogoCutout = Instance.new("Frame")
LogoCutout.Size = UDim2.new(0, 20, 0, 20)
LogoCutout.Position = UDim2.new(0, -4, 0, -4)
LogoCutout.BackgroundColor3 = Theme.Background
LogoCutout.Parent = LogoBase
Instance.new("UICorner", LogoCutout).CornerRadius = UDim.new(1, 0)

-- Заголовок меню
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 0, 50)
Title.Position = UDim2.new(0, 50, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.TextTitle
Title.Text = Locales[Config.Language].Title
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Функция полной выгрузки
local function UnloadCheat()
	for _, conn in ipairs(Connections) do conn:Disconnect() end
	RunService:UnbindFromRenderStep("LunarAimbotRender")
	if ScreenGui then ScreenGui:Destroy() end
	if IsShooting and mouse1release then mouse1release() end
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("LunarESP") then player.Character.LunarESP:Destroy() end
	end
end

-- Кнопка закрытия (Аккуратный тонкий крестик)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -34, 0, 13)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.TextNormal
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 80, 80)}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextNormal}):Play() end)
CloseBtn.MouseButton1Click:Connect(UnloadCheat)

-- Скролл бар
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -60)
ScrollFrame.Position = UDim2.new(0, 10, 0, 50)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 2
ScrollFrame.ScrollBarImageColor3 = Theme.Accent
ScrollFrame.BorderSizePixel = 0
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.ClipsDescendants = false -- Важно для Dropdown списков
ScrollFrame.Parent = MainFrame

local ScrollPadding = Instance.new("UIPadding")
ScrollPadding.PaddingBottom = UDim.new(0, 15)
ScrollPadding.Parent = ScrollFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- == Функция смены языка "на лету" ==
local function UpdateUILanguage()
	local currentLang = Config.Language
	Title.Text = Locales[currentLang].Title
	
	for _, item in ipairs(TranslatableLabels) do
		if item.Type == "Label" then
			item.Instance.Text = Locales[currentLang][item.Key]
		elseif item.Type == "Dropdown" then
			-- Обновляем текст на кнопке дропдауна
			local activeVal = Config[item.ConfigKey]
			item.Instance.Text = Locales[currentLang][activeVal] or activeVal
		end
	end
end

-- == Конструкторы UI Элементов ==

local function AnimateToggle(circle, bg, isOn)
	local circleGoal = isOn and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	local bgColorGoal = isOn and Theme.Accent or Theme.ToggleOff
	TweenService:Create(circle, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = circleGoal}):Play()
	TweenService:Create(bg, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = bgColorGoal}):Play()
end

local function CreateToggle(localeKey, configKey, order, bindConfigKey)
	local Panel = Instance.new("Frame")
	Panel.Size = UDim2.new(1, -10, 0, 42)
	Panel.BackgroundColor3 = Theme.Panel
	Panel.LayoutOrder = order
	Panel.Parent = ScrollFrame
	Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0, 150, 1, 0)
	Label.Position = UDim2.new(0, 15, 0, 0)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Theme.TextNormal
	Label.Text = Locales[Config.Language][localeKey]
	Label.Font = Enum.Font.GothamSemibold
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Panel
	table.insert(TranslatableLabels, {Type = "Label", Instance = Label, Key = localeKey})

	local ToggleBg = Instance.new("TextButton")
	ToggleBg.Size = UDim2.new(0, 38, 0, 20)
	ToggleBg.Position = UDim2.new(1, -50, 0.5, -10)
	ToggleBg.BackgroundColor3 = Config[configKey] and Theme.Accent or Theme.ToggleOff
	ToggleBg.Text = ""
	ToggleBg.AutoButtonColor = false
	ToggleBg.Parent = Panel
	Instance.new("UICorner", ToggleBg).CornerRadius = UDim.new(1, 0)

	local ToggleCircle = Instance.new("Frame")
	ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
	ToggleCircle.Position = Config[configKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	ToggleCircle.BackgroundColor3 = Theme.ToggleCircle
	ToggleCircle.Parent = ToggleBg
	Instance.new("UICorner", ToggleCircle).CornerRadius = UDim.new(1, 0)

	UIElements[configKey] = {Bg = ToggleBg, Circle = ToggleCircle}

	ToggleBg.MouseButton1Click:Connect(function()
		Config[configKey] = not Config[configKey]
		AnimateToggle(ToggleCircle, ToggleBg, Config[configKey])
		if configKey == "ShowFOV" then FOVCircle.Visible = Config.ShowFOV end
		if configKey == "ESPEnabled" and not Config.ESPEnabled then
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Character and p.Character:FindFirstChild("LunarESP") then p.Character.LunarESP:Destroy() end
			end
		end
		SaveConfig()
	end)

	if bindConfigKey then
		local BindBtn = Instance.new("TextButton")
		BindBtn.Size = UDim2.new(0, 45, 0, 22)
		BindBtn.Position = UDim2.new(1, -105, 0.5, -11)
		BindBtn.BackgroundColor3 = Theme.ToggleOff
		BindBtn.TextColor3 = Theme.TextNormal
		BindBtn.Font = Enum.Font.GothamBold
		BindBtn.TextSize = 11
		BindBtn.Text = "[" .. Config[bindConfigKey].Name .. "]"
		BindBtn.Parent = Panel
		Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 6)

		BindBtn.MouseButton1Click:Connect(function()
			BindingKey = bindConfigKey
			BindBtn.Text = "[...]"
			BindBtn.TextColor3 = Theme.Accent
		end)
		UIElements[bindConfigKey] = BindBtn
	end
end

local function CreateInput(localeKey, configKey, order)
	local Panel = Instance.new("Frame")
	Panel.Size = UDim2.new(1, -10, 0, 42)
	Panel.BackgroundColor3 = Theme.Panel
	Panel.LayoutOrder = order
	Panel.Parent = ScrollFrame
	Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0, 150, 1, 0)
	Label.Position = UDim2.new(0, 15, 0, 0)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Theme.TextNormal
	Label.Text = Locales[Config.Language][localeKey]
	Label.Font = Enum.Font.GothamSemibold
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Panel
	table.insert(TranslatableLabels, {Type = "Label", Instance = Label, Key = localeKey})

	local TextBox = Instance.new("TextBox")
	TextBox.Size = UDim2.new(0, 50, 0, 24)
	TextBox.Position = UDim2.new(1, -62, 0.5, -12)
	TextBox.BackgroundColor3 = Theme.ToggleOff
	TextBox.TextColor3 = Theme.TextTitle
	TextBox.Text = tostring(Config[configKey])
	TextBox.Font = Enum.Font.GothamBold
	TextBox.TextSize = 13
	TextBox.Parent = Panel
	Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 6)

	TextBox.FocusLost:Connect(function()
		local val = tonumber(TextBox.Text)
		if val then Config[configKey] = val SaveConfig() else TextBox.Text = tostring(Config[configKey]) end
	end)
end

local function CreateSlider(localeKey, configKey, min, max, order)
	local Panel = Instance.new("Frame")
	Panel.Size = UDim2.new(1, -10, 0, 50)
	Panel.BackgroundColor3 = Theme.Panel
	Panel.LayoutOrder = order
	Panel.Parent = ScrollFrame
	Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.5, 0, 0, 25)
	Label.Position = UDim2.new(0, 15, 0, 2)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Theme.TextNormal
	Label.Text = Locales[Config.Language][localeKey]
	Label.Font = Enum.Font.GothamSemibold
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Panel
	table.insert(TranslatableLabels, {Type = "Label", Instance = Label, Key = localeKey})

	local ValueLabel = Instance.new("TextLabel")
	ValueLabel.Size = UDim2.new(0, 50, 0, 25)
	ValueLabel.Position = UDim2.new(1, -65, 0, 2)
	ValueLabel.BackgroundTransparency = 1
	ValueLabel.TextColor3 = Theme.Accent
	ValueLabel.Font = Enum.Font.GothamBold
	ValueLabel.TextSize = 13
	ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	ValueLabel.Text = string.format("%.2f", Config[configKey])
	ValueLabel.Parent = Panel

	local SliderTrack = Instance.new("TextButton")
	SliderTrack.Size = UDim2.new(1, -30, 0, 6)
	SliderTrack.Position = UDim2.new(0, 15, 1, -15)
	SliderTrack.BackgroundColor3 = Theme.ToggleOff
	SliderTrack.Text = ""
	SliderTrack.AutoButtonColor = false
	SliderTrack.Parent = Panel
	Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(1, 0)

	local SliderFill = Instance.new("Frame")
	local percent = (Config[configKey] - min) / (max - min)
	SliderFill.Size = UDim2.new(percent, 0, 1, 0)
	SliderFill.BackgroundColor3 = Theme.Accent
	SliderFill.BorderSizePixel = 0
	SliderFill.Parent = SliderTrack
	Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

	local SliderKnob = Instance.new("Frame")
	SliderKnob.Size = UDim2.new(0, 12, 0, 12)
	SliderKnob.Position = UDim2.new(percent, -6, 0.5, -6)
	SliderKnob.BackgroundColor3 = Theme.ToggleCircle
	SliderKnob.Parent = SliderTrack
	Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

	local dragging = false
	local function updateSlider(input)
		local absPos = SliderTrack.AbsolutePosition.X
		local absSize = SliderTrack.AbsoluteSize.X
		local mouseX = input.Position.X
		local newPercent = math.clamp((mouseX - absPos) / absSize, 0, 1)
		SliderFill.Size = UDim2.new(newPercent, 0, 1, 0)
		SliderKnob.Position = UDim2.new(newPercent, -6, 0.5, -6)
		local val = min + (max - min) * newPercent
		val = math.round(val * 100) / 100
		Config[configKey] = val
		ValueLabel.Text = string.format("%.2f", val)
	end

	SliderTrack.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true updateSlider(input) end end)
	UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end end)
	UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then dragging = false SaveConfig() end end)
end

-- Продвинутый Dropdown (Фиолетовая подсветка выбранного + Анимация раскрытия)
local function CreateDropdown(localeKey, configKey, options, order)
	local Panel = Instance.new("Frame")
	Panel.Size = UDim2.new(1, -10, 0, 42)
	Panel.BackgroundColor3 = Theme.Panel
	Panel.LayoutOrder = order
	Panel.ZIndex = 10 - order -- Чтобы верхние списки перекрывали нижние элементы при раскрытии
	Panel.Parent = ScrollFrame
	Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0, 140, 1, 0)
	Label.Position = UDim2.new(0, 15, 0, 0)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Theme.TextNormal
	Label.Text = Locales[Config.Language][localeKey]
	Label.Font = Enum.Font.GothamSemibold
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Panel
	table.insert(TranslatableLabels, {Type = "Label", Instance = Label, Key = localeKey})

	local MainBtn = Instance.new("TextButton")
	MainBtn.Size = UDim2.new(0, 95, 0, 24)
	MainBtn.Position = UDim2.new(1, -110, 0.5, -12)
	MainBtn.BackgroundColor3 = Theme.ToggleOff
	MainBtn.TextColor3 = Theme.TextTitle
	MainBtn.Font = Enum.Font.GothamBold
	MainBtn.TextSize = 12
	local currentVal = Config[configKey]
	MainBtn.Text = Locales[Config.Language][currentVal] or currentVal
	MainBtn.Parent = Panel
	Instance.new("UICorner", MainBtn).CornerRadius = UDim.new(0, 6)
	table.insert(TranslatableLabels, {Type = "Dropdown", Instance = MainBtn, ConfigKey = configKey})

	-- Контейнер самого списка
	local ListContainer = Instance.new("Frame")
	ListContainer.Size = UDim2.new(1, 0, 0, 0)
	ListContainer.Position = UDim2.new(0, 0, 1, 2)
	ListContainer.BackgroundColor3 = Theme.DropdownBg
	ListContainer.Visible = false
	ListContainer.ZIndex = 100
	ListContainer.Parent = MainBtn
	Instance.new("UICorner", ListContainer).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", ListContainer).Color = Theme.Panel

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.Parent = ListContainer
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local isOpen = false
	local optionButtons = {}

	-- Функция обновления фиолетовой подсветки кнопок в списке
	local function UpdateVisuals()
		for opt, btn in pairs(optionButtons) do
			if Config[configKey] == opt then
				btn.TextColor3 = Theme.Accent -- Фиолетовое свечение текста
				btn.BackgroundColor3 = Color3.fromRGB(38, 34, 50) -- Фиолетовый оттенок фона кнопки
			else
				btn.TextColor3 = Theme.TextNormal
				btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				btn.BackgroundTransparency = 1
			end
		end
	end

	-- Генерация кнопок
	for idx, opt in ipairs(options) do
		local OptBtn = Instance.new("TextButton")
		OptBtn.Size = UDim2.new(1, 0, 0, 26)
		OptBtn.BackgroundTransparency = 0
		OptBtn.Font = Enum.Font.GothamMedium
		OptBtn.TextSize = 11
		OptBtn.Text = Locales[Config.Language][opt] or opt
		OptBtn.LayoutOrder = idx
		OptBtn.ZIndex = 101
		OptBtn.Parent = ListContainer
		Instance.new("UICorner", OptBtn).CornerRadius = UDim.new(0, 4)
		
		optionButtons[opt] = OptBtn
		table.insert(TranslatableLabels, {Type = "Dropdown", Instance = OptBtn, ConfigKey = configKey, SpecialOpt = opt})

		OptBtn.MouseButton1Click:Connect(function()
			Config[configKey] = opt
			MainBtn.Text = Locales[Config.Language][opt] or opt
			isOpen = false
			ListContainer.Visible = false
			ListContainer.Size = UDim2.new(1, 0, 0, 0)
			UpdateVisuals()
			
			if configKey == "Language" then
				UpdateUILanguage()
			end
			SaveConfig()
		end)
	end

	MainBtn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			UpdateVisuals()
			ListContainer.Visible = true
			TweenService:Create(ListContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, #options * 26)}):Play()
		else
			ListContainer.Visible = false
			ListContainer.Size = UDim2.new(1, 0, 0, 0)
		end
	end)
end

-- Сборка структуры меню
CreateToggle("EnableAim", "Enabled", 1, "ToggleAimKey")
CreateToggle("AlwaysAim", "AlwaysAim", 2)
CreateToggle("AutoShoot", "AutoShoot", 3, "ToggleShootKey")
CreateDropdown("TargetBone", "TargetPart", {"Head", "Torso", "Legs"}, 4)
CreateSlider("Smoothness", "Smoothness", 0.05, 1.00, 5)
CreateToggle("ShowFOV", "ShowFOV", 6)
CreateInput("FOVRadius", "FOV", 7)
CreateToggle("WallCheck", "WallCheck", 8)
CreateToggle("PlayerESP", "ESPEnabled", 9)
CreateDropdown("Language", "Language", {"en", "ru"}, 10) -- Выбор Языка в самом низу

-- Первоначальный перевод
UpdateUILanguage()

-- == Обработка ввода и горячих клавиш ==
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if BindingKey then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			Config[BindingKey] = input.KeyCode
			UIElements[BindingKey].Text = "[" .. input.KeyCode.Name .. "]"
			UIElements[BindingKey].TextColor3 = Theme.TextNormal
			BindingKey = nil
			SaveConfig()
		end
		return
	end

	if gameProcessed then return end

	if input.KeyCode == Config.ToggleAimKey then
		Config.Enabled = not Config.Enabled
		if UIElements["Enabled"] then AnimateToggle(UIElements["Enabled"].Circle, UIElements["Enabled"].Bg, Config.Enabled) end
		SaveConfig()
	end

	if input.KeyCode == Config.ToggleShootKey then
		Config.AutoShoot = not Config.AutoShoot
		if UIElements["AutoShoot"] then AnimateToggle(UIElements["AutoShoot"].Circle, UIElements["AutoShoot"].Bg, Config.AutoShoot) end
		SaveConfig()
	end

	if input.KeyCode == Config.MenuKey then
		MainFrame.Visible = not MainFrame.Visible
		if MainFrame.Visible then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
	end

	if input.UserInputType == Config.AimKey then IsAiming = true end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Config.AimKey then
		IsAiming = false
		if not Config.AlwaysAim then CurrentTarget = nil end
	end
end))

-- == Внутренняя Логика Аима ==
local function GetTargetBone(character)
	if Config.TargetPart == "Head" then
		return character:FindFirstChild("Head")
	elseif Config.TargetPart == "Torso" then
		return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	elseif Config.TargetPart == "Legs" then
		return character:FindFirstChild("LeftLowerLeg") or character:FindFirstChild("LeftLeg") or character:FindFirstChild("RightLowerLeg") or character:FindFirstChild("HumanoidRootPart")
	end
	return character:FindFirstChild("Head")
end

local function IsVisible(targetPart)
	if not Config.WallCheck then return true end
	local rayOrigin = Camera.CFrame.Position
	local rayDirection = (targetPart.Position - rayOrigin)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result and result.Instance then return result.Instance:IsDescendantOf(targetPart.Parent) end
	return true 
end

local function IsTargetValid(targetPart)
	if not targetPart or not targetPart.Parent then return false end
	local humanoid = targetPart.Parent:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	return IsVisible(targetPart)
end

local function GetClosestTarget()
	local mousePos = UserInputService:GetMouseLocation()
	local closestDistance = Config.FOV
	local closestPart = nil

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
			local targetPart = GetTargetBone(player.Character)
			if targetPart then
				local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
				if onScreen and screenPoint.Z > 0 then
					local screenPos = Vector2.new(screenPoint.X, screenPoint.Y)
					local distance = (mousePos - screenPos).Magnitude
					if distance <= closestDistance and IsVisible(targetPart) then
						closestDistance = distance
						closestPart = targetPart
					end
				end
			end
		end
	end
	return closestPart
end

-- Цикл рендера
RunService:BindToRenderStep("LunarAimbotRender", Enum.RenderPriority.Camera.Value + 1, function()
	local mouseLoc = UserInputService:GetMouseLocation()
	
	if Config.ShowFOV then
		FOVCircle.Size = UDim2.new(0, Config.FOV * 2, 0, Config.FOV * 2)
		FOVCircle.Position = UDim2.new(0, mouseLoc.X, 0, mouseLoc.Y)
	end

	if Config.ESPEnabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
				local char = player.Character
				local highlight = char:FindFirstChild("LunarESP")
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "LunarESP"
					highlight.FillColor = Theme.Accent
					highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
					highlight.FillTransparency = 0.6
					highlight.OutlineTransparency = 0.2
					highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					highlight.Parent = char
				end
			end
		end
	end

	local shouldAim = Config.Enabled and (Config.AlwaysAim or IsAiming)

	if shouldAim then
		if CurrentTarget then
			local currentBoneName = GetTargetBone(CurrentTarget.Parent).Name
			if CurrentTarget.Name ~= currentBoneName or not IsTargetValid(CurrentTarget) then
				CurrentTarget = GetClosestTarget()
			end
		else
			CurrentTarget = GetClosestTarget()
		end
		
		if CurrentTarget then
			local currentCFrame = Camera.CFrame
			local targetCFrame = CFrame.new(currentCFrame.Position, CurrentTarget.Position)
			
			if Config.Smoothness >= 0.99 then
				Camera.CFrame = targetCFrame
			else
				Camera.CFrame = currentCFrame:Lerp(targetCFrame, math.clamp(Config.Smoothness, 0.01, 1))
			end
			
			if Config.AutoShoot and not IsShooting and mouse1press then
				IsShooting = true
				mouse1press()
			end
		else
			if IsShooting and mouse1release then IsShooting = false mouse1release() end
		end
	else
		CurrentTarget = nil
		if IsShooting and mouse1release then IsShooting = false mouse1release() end
	end
end)
