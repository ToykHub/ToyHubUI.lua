local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("ToyHubUI") then
	playerGui.ToyHubUI:Destroy()
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ขนาดแบบ Scale และพิกเซลสำคัญ
local CLOSED_WIDTH = isMobile and 0.46 or 0.28
local OPEN_WIDTH = isMobile and 0.70 or 0.40
local FRAME_HEIGHT = isMobile and 0.68 or 0.56
local TOPBAR_PX = isMobile and 50 or 46
local SIDEBAR_SCALE = isMobile and 0.30 or 0.25
local CORNER_PX = isMobile and 18 or 20
local SCREEN_MARGIN = 8

-- ==========================================
-- ระบบสลับและแปลภาษาไทย <-> อังกฤษ (เริ่มต้นเป็น EN)
-- ==========================================
local currentLang = "EN" -- "TH" หรือ "EN"
local translatableRegistry = {}
local onLanguageChangedCallbacks = {}

local TH_TO_EN = {
	["เมนูหลัก"] = "MAIN MENU",
	["ไทย"] = "Thai",
	["อังกฤษ"] = "English",
	["เปิด"] = "On",
	["ปิด"] = "Off",
	["สำเร็จ"] = "Success",
	["ผิดพลาด"] = "Error",
}

local EN_TO_TH = {}

local function rebuildReverseDict()
	table.clear(EN_TO_TH)
	for th, en in pairs(TH_TO_EN) do
		EN_TO_TH[string.lower(en)] = th
	end
end
rebuildReverseDict()

local function containsThai(str)
	for _, codepoint in utf8.codes(str) do
		if codepoint >= 0x0E00 and codepoint <= 0x0E7F then
			return true
		end
	end
	return false
end

local function L(thText, enText)
	if currentLang == "EN" then
		return enText or thText
	end
	return thText
end

-- ฟังก์ชันกลางสำหรับแปลข้อความไทย <-> อังกฤษ ไม่ว่าจะสร้างฟังก์ชันอะไรเพิ่มในอนาคต
-- targetLang: "TH" หรือ "EN" (ถ้าไม่ระบุ จะแปลไปอีกภาษาหนึ่งจากภาษาต้นฉบับ)
local function translateThEn(text, targetLang)
	if typeof(text) ~= "string" or text == "" then
		return text
	end

	local sourceIsThai = containsThai(text)
	local dest = targetLang
	if not dest then
		dest = sourceIsThai and "EN" or "TH"
	end

	if dest == "EN" then
		if not sourceIsThai then
			return text
		end
		if TH_TO_EN[text] then
			return TH_TO_EN[text]
		end
		local result = text
		for thPhrase, enPhrase in pairs(TH_TO_EN) do
			result = string.gsub(result, thPhrase, enPhrase)
		end
		return result
	else
		if sourceIsThai then
			return text
		end
		local lowerText = string.lower(text)
		if EN_TO_TH[lowerText] then
			return EN_TO_TH[lowerText]
		end
		local result = text
		for enPhrase, thPhrase in pairs(EN_TO_TH) do
			result = string.gsub(result, string.lower(enPhrase), thPhrase)
		end
		return result
	end
end

local function resolveBilingualPair(firstText, secondText)
	if firstText and secondText then
		return firstText, secondText
	end
	local single = firstText or secondText
	if not single then
		return "", ""
	end
	if containsThai(single) then
		return single, translateThEn(single, "EN")
	else
		return translateThEn(single, "TH"), single
	end
end

local function applyLanguageToAll()
	for _, item in ipairs(translatableRegistry) do
		if item.obj and item.obj.Parent then
			local resolvedTh, resolvedEn = resolveBilingualPair(item.th, item.en)
			item.th = resolvedTh
			item.en = resolvedEn
			item.obj.Text = L(resolvedTh, resolvedEn)
		end
	end
	for _, cb in ipairs(onLanguageChangedCallbacks) do
		pcall(cb, currentLang)
	end
end

local function addDict(thWord, enWord)
	if typeof(thWord) == "string" and thWord ~= "" and typeof(enWord) == "string" and enWord ~= "" then
		TH_TO_EN[thWord] = enWord
		rebuildReverseDict()
		applyLanguageToAll()
	end
end

local function registerTranslatable(guiObj, thText, enText)
	local resolvedTh, resolvedEn = resolveBilingualPair(thText, enText)
	table.insert(translatableRegistry, {
		obj = guiObj,
		th = resolvedTh,
		en = resolvedEn,
	})
	guiObj.Text = L(resolvedTh, resolvedEn)
end

-- 1. ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ToyHubUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- 2. หน้าต่างหลัก (MainFrame) — เปิดกาง Sidebar ไว้ตั้งแต่ต้น
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Size = UDim2.fromScale(OPEN_WIDTH, FRAME_HEIGHT)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = isMobile and Vector2.new(230, TOPBAR_PX) or Vector2.new(270, TOPBAR_PX)
sizeConstraint.MaxSize = isMobile and Vector2.new(540, 560) or Vector2.new(820, 680)
sizeConstraint.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, CORNER_PX)
mainCorner.Parent = mainFrame

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 36)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 22))
})
bgGradient.Rotation = 135
bgGradient.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(235, 64, 78)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.25
mainStroke.Parent = mainFrame

-- 3. แถบด้านบน (TopBar)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, TOPBAR_PX)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, CORNER_PX)
topCorner.Parent = topBar

local bottomCover = Instance.new("Frame")
bottomCover.Size = UDim2.new(1, 0, 0, math.max(4, TOPBAR_PX - CORNER_PX))
bottomCover.Position = UDim2.new(0, 0, 1, -math.max(4, TOPBAR_PX - CORNER_PX))
bottomCover.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
bottomCover.BorderSizePixel = 0
bottomCover.Parent = topBar

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 1)
topLine.Position = UDim2.new(0, 0, 1, -1)
topLine.BackgroundColor3 = Color3.fromRGB(52, 52, 68)
topLine.BorderSizePixel = 0
topLine.Parent = topBar

-- ปุ่มแฮมเบอร์เกอร์ (≡)
local menuBtn = Instance.new("TextButton")
menuBtn.Name = "MenuBtn"
menuBtn.AnchorPoint = Vector2.new(0, 0.5)
menuBtn.Size = UDim2.new(0, 34, 0, 34)
menuBtn.Position = UDim2.new(0, 8, 0.5, 0)
menuBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
menuBtn.BackgroundTransparency = 0.35
menuBtn.Text = "≡"
menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
menuBtn.Font = Enum.Font.GothamBold
menuBtn.TextSize = 20
menuBtn.Parent = topBar

local menuBtnCorner = Instance.new("UICorner")
menuBtnCorner.CornerRadius = UDim.new(0, 10)
menuBtnCorner.Parent = menuBtn

-- ชื่อเมนูบน TopBar
local titleLabel = Instance.new("TextLabel")
titleLabel.AnchorPoint = Vector2.new(0, 0.5)
titleLabel.Size = UDim2.new(1, -130, 0.7, 0)
titleLabel.Position = UDim2.new(0, 50, 0.5, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "MAIN MENU"
titleLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = isMobile and 13 or 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
titleLabel.Parent = topBar
registerTranslatable(titleLabel, "เมนูหลัก", "MAIN MENU")

-- ปุ่มปิด (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -8, 0.5, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(235, 64, 78)
closeBtn.BackgroundTransparency = 0.15
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

-- ปุ่มย่อ (–)
local minBtn = Instance.new("TextButton")
minBtn.Name = "MinBtn"
minBtn.AnchorPoint = Vector2.new(1, 0.5)
minBtn.Size = UDim2.new(0, 32, 0, 32)
minBtn.Position = UDim2.new(1, -46, 0.5, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
minBtn.BackgroundTransparency = 0.25
minBtn.Text = "–"
minBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 10)
minCorner.Parent = minBtn

-- 4. แถบเมนูด้านซ้าย (Sidebar) — เปิดไว้ตั้งแต่ต้น
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(SIDEBAR_SCALE, 0, 1, -TOPBAR_PX)
sidebar.Position = UDim2.new(0, 0, 0, TOPBAR_PX)
sidebar.BackgroundTransparency = 1
sidebar.BorderSizePixel = 0
sidebar.ClipsDescendants = true
sidebar.Parent = mainFrame

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 8)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.Parent = sidebar

local sidePadding = Instance.new("UIPadding")
sidePadding.PaddingTop = UDim.new(0, 12)
sidePadding.PaddingBottom = UDim.new(0, 16)
sidePadding.Parent = sidebar

-- 5. พื้นที่แสดงเนื้อหาหลัก (Content Area) — ขยับรับ Sidebar ที่เปิดอยู่ตั้งแต่ต้น
local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1 - SIDEBAR_SCALE, 0, 1, -TOPBAR_PX)
contentContainer.Position = UDim2.new(SIDEBAR_SCALE, 0, 0, TOPBAR_PX)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

-- ==========================================
-- 6. แคปซูล + เวลา + รูปโปรไฟล์ + วงกลมเปลี่ยนภาษา + วงกลมล็อก
-- ==========================================
local circleSize = isMobile and 52 or 48
local popCircleSize = math.round(circleSize * 1.12)
local avatarCircleSize = isMobile and 34 or 32
local langCircleSize = isMobile and 34 or 32
local lockCircleSize = isMobile and 34 or 32
local clockW = isMobile and 88 or 96
local capsuleExpandedW = popCircleSize
	+ 10
	+ clockW
	+ 8
	+ avatarCircleSize
	+ 8
	+ langCircleSize
	+ 8
	+ lockCircleSize
	+ 10

local dockContainer = Instance.new("Frame")
dockContainer.Name = "FloatingTDock"
dockContainer.AnchorPoint = Vector2.new(0.5, 0)
dockContainer.Size = UDim2.new(0, circleSize, 0, popCircleSize)
dockContainer.Position = UDim2.new(0.5, 0, 0, 14)
dockContainer.BackgroundTransparency = 1
dockContainer.Visible = false
dockContainer.Parent = screenGui

local capsuleFrame = Instance.new("Frame")
capsuleFrame.Name = "CapsuleFrame"
capsuleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
capsuleFrame.Size = UDim2.new(0, circleSize, 0, circleSize)
capsuleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
capsuleFrame.BackgroundColor3 = Color3.fromRGB(22, 16, 20)
capsuleFrame.BorderSizePixel = 0
capsuleFrame.ClipsDescendants = true
capsuleFrame.ZIndex = 1
capsuleFrame.Parent = dockContainer

local capsuleCorner = Instance.new("UICorner")
capsuleCorner.CornerRadius = UDim.new(0, popCircleSize * 0.5)
capsuleCorner.Parent = capsuleFrame

local capsuleStroke = Instance.new("UIStroke")
capsuleStroke.Color = Color3.fromRGB(255, 75, 95)
capsuleStroke.Thickness = 2
capsuleStroke.Transparency = 0.15
capsuleStroke.Parent = capsuleFrame

local openFloatingBtn = Instance.new("TextButton")
openFloatingBtn.Name = "OpenFloatingBtn"
openFloatingBtn.AnchorPoint = Vector2.new(0.5, 0.5)
openFloatingBtn.Size = UDim2.new(0, circleSize, 0, circleSize)
openFloatingBtn.Position = UDim2.new(0, circleSize * 0.5, 0.5, 0)
openFloatingBtn.BackgroundColor3 = Color3.fromRGB(32, 18, 24)
openFloatingBtn.Text = ""
openFloatingBtn.Rotation = 0
openFloatingBtn.ZIndex = 3
openFloatingBtn.Parent = capsuleFrame

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(0.5, 0)
floatCorner.Parent = openFloatingBtn

local circleStroke = Instance.new("UIStroke")
circleStroke.Color = Color3.fromRGB(255, 95, 115)
circleStroke.Thickness = 1.5
circleStroke.Transparency = 0.3
circleStroke.Parent = openFloatingBtn

local glowBackLabel = Instance.new("TextLabel")
glowBackLabel.Name = "GlowBack"
glowBackLabel.AnchorPoint = Vector2.new(0.5, 0.5)
glowBackLabel.Size = UDim2.fromScale(1, 1)
glowBackLabel.Position = UDim2.fromScale(0.5, 0.5)
glowBackLabel.BackgroundTransparency = 1
glowBackLabel.Text = "T"
glowBackLabel.TextColor3 = Color3.fromRGB(255, 45, 75)
glowBackLabel.TextTransparency = 0.25
glowBackLabel.Font = Enum.Font.FredokaOne
glowBackLabel.TextSize = isMobile and 30 or 28
glowBackLabel.ZIndex = 3
glowBackLabel.Parent = openFloatingBtn

local glowBlur = Instance.new("UIStroke")
glowBlur.Color = Color3.fromRGB(255, 50, 80)
glowBlur.Thickness = 4
glowBlur.Transparency = 0.45
glowBlur.Parent = glowBackLabel

local neonTLabel = Instance.new("TextLabel")
neonTLabel.Name = "NeonT"
neonTLabel.AnchorPoint = Vector2.new(0.5, 0.5)
neonTLabel.Size = UDim2.fromScale(1, 1)
neonTLabel.Position = UDim2.fromScale(0.5, 0.5)
neonTLabel.BackgroundTransparency = 1
neonTLabel.Text = "T"
neonTLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
neonTLabel.Font = Enum.Font.FredokaOne
neonTLabel.TextSize = isMobile and 28 or 26
neonTLabel.ZIndex = 4
neonTLabel.Parent = openFloatingBtn

local tGradient = Instance.new("UIGradient")
tGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 225)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 85, 105)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 35, 65))
})
tGradient.Rotation = 90
tGradient.Parent = neonTLabel

-- ป้ายบอกเวลาในแถบแคปซูล
local clockBtn = Instance.new("TextButton")
clockBtn.Name = "ClockBtn"
clockBtn.AnchorPoint = Vector2.new(0, 0.5)
clockBtn.Size = UDim2.new(0, clockW, 0, 34)
clockBtn.Position = UDim2.new(0, popCircleSize + 10, 0.5, 0)
clockBtn.BackgroundColor3 = Color3.fromRGB(36, 26, 32)
clockBtn.Text = os.date("%H:%M:%S")
clockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clockBtn.Font = Enum.Font.GothamBold
clockBtn.TextSize = 13
clockBtn.ZIndex = 2
clockBtn.Parent = capsuleFrame

local clockCorner = Instance.new("UICorner")
clockCorner.CornerRadius = UDim.new(0.5, 0)
clockCorner.Parent = clockBtn

task.spawn(function()
	while screenGui.Parent do
		clockBtn.Text = os.date("%H:%M:%S")
		task.wait(1)
	end
end)

-- วงกลมรูปโปรไฟล์ตัวละครผู้เล่นข้างในแคปซูล
local avatarX = popCircleSize + 10 + clockW + 8
local avatarCircle = Instance.new("ImageLabel")
avatarCircle.Name = "CharacterAvatarCircle"
avatarCircle.AnchorPoint = Vector2.new(0, 0.5)
avatarCircle.Size = UDim2.new(0, avatarCircleSize, 0, avatarCircleSize)
avatarCircle.Position = UDim2.new(0, avatarX, 0.5, 0)
avatarCircle.BackgroundColor3 = Color3.fromRGB(42, 30, 38)
avatarCircle.BorderSizePixel = 0
avatarCircle.ScaleType = Enum.ScaleType.Crop
avatarCircle.ZIndex = 3
avatarCircle.Parent = capsuleFrame

local avatarCircleCorner = Instance.new("UICorner")
avatarCircleCorner.CornerRadius = UDim.new(0.5, 0)
avatarCircleCorner.Parent = avatarCircle

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(255, 85, 105)
avatarStroke.Thickness = 1.6
avatarStroke.Transparency = 0.2
avatarStroke.Parent = avatarCircle

task.spawn(function()
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
	end)
	if ok and content and avatarCircle.Parent then
		avatarCircle.Image = content
	end
end)

-- วงกลมเปลี่ยนภาษา (TH <-> EN) ข้างรูปโปรไฟล์
local langX = avatarX + avatarCircleSize + 8
local langCircleBtn = Instance.new("TextButton")
langCircleBtn.Name = "LangCircleBtn"
langCircleBtn.AnchorPoint = Vector2.new(0, 0.5)
langCircleBtn.Size = UDim2.new(0, langCircleSize, 0, langCircleSize)
langCircleBtn.Position = UDim2.new(0, langX, 0.5, 0)
langCircleBtn.BackgroundColor3 = (currentLang == "EN") and Color3.fromRGB(235, 64, 78) or Color3.fromRGB(36, 26, 32)
langCircleBtn.Text = currentLang
langCircleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
langCircleBtn.Font = Enum.Font.GothamBold
langCircleBtn.TextSize = 12
langCircleBtn.ZIndex = 4
langCircleBtn.Parent = capsuleFrame

local langCorner = Instance.new("UICorner")
langCorner.CornerRadius = UDim.new(0.5, 0)
langCorner.Parent = langCircleBtn

local langStroke = Instance.new("UIStroke")
langStroke.Color = Color3.fromRGB(255, 85, 105)
langStroke.Thickness = 1.5
langStroke.Transparency = (currentLang == "EN") and 0 or 0.25
langStroke.Parent = langCircleBtn

langCircleBtn.MouseButton1Click:Connect(function()
	currentLang = (currentLang == "TH") and "EN" or "TH"
	langCircleBtn.Text = currentLang
	if currentLang == "EN" then
		langCircleBtn.BackgroundColor3 = Color3.fromRGB(235, 64, 78)
		langStroke.Transparency = 0
	else
		langCircleBtn.BackgroundColor3 = Color3.fromRGB(36, 26, 32)
		langStroke.Transparency = 0.25
	end
	applyLanguageToAll()
end)

-- วงกลมล็อกอยู่รวมด้านในแคปซูลถัดจากวงกลมเปลี่ยนภาษา
local lockX = langX + langCircleSize + 8
local pinLockBtn = Instance.new("TextButton")
pinLockBtn.Name = "PinLockBtn"
pinLockBtn.AnchorPoint = Vector2.new(0, 0.5)
pinLockBtn.Size = UDim2.new(0, lockCircleSize, 0, lockCircleSize)
pinLockBtn.Position = UDim2.new(0, lockX, 0.5, 0)
pinLockBtn.BackgroundColor3 = Color3.fromRGB(36, 26, 32)
pinLockBtn.Text = "🔓"
pinLockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pinLockBtn.Font = Enum.Font.GothamBold
pinLockBtn.TextSize = 15
pinLockBtn.ZIndex = 4
pinLockBtn.Parent = capsuleFrame

local pinCorner = Instance.new("UICorner")
pinCorner.CornerRadius = UDim.new(0.5, 0)
pinCorner.Parent = pinLockBtn

local pinStroke = Instance.new("UIStroke")
pinStroke.Color = Color3.fromRGB(255, 85, 105)
pinStroke.Thickness = 1.5
pinStroke.Transparency = 0.25
pinStroke.Parent = pinLockBtn

local isHovered = false
local isPinned = false
local wasExpanded = false
local hoverCheckToken = 0
local popTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local dockTweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local spinTweenInfo = TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function updateDockState()
	local shouldExpand = isHovered or isPinned

	if shouldExpand then
		if not wasExpanded then
			openFloatingBtn.Rotation = 0
			TweenService:Create(openFloatingBtn, spinTweenInfo, {Rotation = 360}):Play()
		end
		wasExpanded = true

		TweenService:Create(dockContainer, dockTweenInfo, {
			Size = UDim2.new(0, capsuleExpandedW, 0, popCircleSize)
		}):Play()
		TweenService:Create(capsuleFrame, dockTweenInfo, {
			Size = UDim2.new(0, capsuleExpandedW, 0, popCircleSize),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
		TweenService:Create(openFloatingBtn, popTweenInfo, {
			Size = UDim2.new(0, popCircleSize, 0, popCircleSize),
			Position = UDim2.new(0, popCircleSize * 0.5, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(52, 22, 32)
		}):Play()
		TweenService:Create(circleStroke, dockTweenInfo, {Thickness = 2.4, Transparency = 0}):Play()
		TweenService:Create(glowBlur, dockTweenInfo, {Thickness = 7.5, Transparency = 0.1}):Play()
	else
		wasExpanded = false
		TweenService:Create(openFloatingBtn, dockTweenInfo, {
			Size = UDim2.new(0, circleSize, 0, circleSize),
			Position = UDim2.new(0, circleSize * 0.5, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(32, 18, 24),
			Rotation = 0
		}):Play()
		TweenService:Create(dockContainer, dockTweenInfo, {
			Size = UDim2.new(0, circleSize, 0, popCircleSize)
		}):Play()
		TweenService:Create(capsuleFrame, dockTweenInfo, {
			Size = UDim2.new(0, circleSize, 0, circleSize),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
		TweenService:Create(circleStroke, dockTweenInfo, {Thickness = 1.5, Transparency = 0.3}):Play()
		TweenService:Create(glowBlur, dockTweenInfo, {Thickness = 4, Transparency = 0.45}):Play()
	end
end

local function isPointInGui(pt, guiObj)
	if not guiObj or not guiObj.Visible then return false end
	local p = guiObj.AbsolutePosition
	local s = guiObj.AbsoluteSize
	return pt.X >= p.X and pt.X <= p.X + s.X and pt.Y >= p.Y and pt.Y <= p.Y + s.Y
end

local function checkStillHoveringAny()
	local mousePos = UserInputService:GetMouseLocation()
	return isPointInGui(mousePos, openFloatingBtn)
		or isPointInGui(mousePos, capsuleFrame)
		or isPointInGui(mousePos, clockBtn)
		or isPointInGui(mousePos, avatarCircle)
		or isPointInGui(mousePos, langCircleBtn)
		or isPointInGui(mousePos, pinLockBtn)
end

local function bindHover(guiObj)
	guiObj.MouseEnter:Connect(function()
		hoverCheckToken += 1
		isHovered = true
		updateDockState()
	end)
	guiObj.MouseLeave:Connect(function()
		hoverCheckToken += 1
		local token = hoverCheckToken
		task.delay(0.1, function()
			if token ~= hoverCheckToken then return end
			isHovered = checkStillHoveringAny()
			updateDockState()
		end)
	end)
end

bindHover(openFloatingBtn)
bindHover(capsuleFrame)
bindHover(clockBtn)
bindHover(avatarCircle)
bindHover(langCircleBtn)
bindHover(pinLockBtn)

pinLockBtn.MouseButton1Click:Connect(function()
	isPinned = not isPinned
	if isPinned then
		pinLockBtn.Text = "🔒"
		pinLockBtn.BackgroundColor3 = Color3.fromRGB(235, 64, 78)
		pinStroke.Transparency = 0
	else
		pinLockBtn.Text = "🔓"
		pinLockBtn.BackgroundColor3 = Color3.fromRGB(36, 26, 32)
		pinStroke.Transparency = 0.25
		isHovered = checkStillHoveringAny()
	end
	updateDockState()
end)

-- ==========================================
-- ฟังก์ชันกัน UI ออกนอกจอ
-- ==========================================
local function getViewportSize()
	local cam = workspace.CurrentCamera
	return (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
end

local function clampPositionToScreen(targetScaleX, targetScaleY, widthPx, heightPx)
	local vp = getViewportSize()
	local halfW = (widthPx * 0.5) + SCREEN_MARGIN
	local halfH = (heightPx * 0.5) + SCREEN_MARGIN

	local minCenterX = math.min(halfW, vp.X * 0.5)
	local maxCenterX = math.max(vp.X - halfW, vp.X * 0.5)
	local minCenterY = math.min(halfH, vp.Y * 0.5)
	local maxCenterY = math.max(vp.Y - halfH, vp.Y * 0.5)

	local clampedPxX = math.clamp(targetScaleX * vp.X, minCenterX, maxCenterX)
	local clampedPxY = math.clamp(targetScaleY * vp.Y, minCenterY, maxCenterY)

	return UDim2.fromScale(clampedPxX / vp.X, clampedPxY / vp.Y)
end

local function keepMainFrameInBounds()
	local vp = getViewportSize()
	local size = mainFrame.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return end
	mainFrame.Position = clampPositionToScreen(mainFrame.Position.X.Scale, mainFrame.Position.Y.Scale, size.X, size.Y)
end

-- ==========================================
-- API สำหรับสร้างแท็บและปุ่ม (พร้อมให้เรียกเพิ่มฟังก์ชันเอง)
-- ==========================================
local pages = {}
local tabButtons = {}
local activeTabName = nil

local function selectTab(tabKey)
	activeTabName = tabKey
	for name, p in pairs(pages) do
		p.Visible = (name == tabKey)
	end
	for name, btn in pairs(tabButtons) do
		if name == tabKey then
			btn.BackgroundColor3 = Color3.fromRGB(235, 64, 78)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
			btn.TextColor3 = Color3.fromRGB(210, 210, 220)
		end
	end
end

local function createTab(thTabName, enTabName)
	local resolvedTh, resolvedEn = resolveBilingualPair(thTabName, enTabName)
	local tabKey = resolvedTh ~= "" and resolvedTh or resolvedEn

	local page = Instance.new("ScrollingFrame")
	page.Name = (resolvedEn ~= "" and resolvedEn or "Tab") .. "Page"
	page.Size = UDim2.new(1, -24, 1, -24)
	page.Position = UDim2.new(0, 12, 0, 12)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = Color3.fromRGB(235, 64, 78)
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = contentContainer

	local pageLayout = Instance.new("UIListLayout")
	pageLayout.Padding = UDim.new(0, 10)
	pageLayout.Parent = page

	local pagePad = Instance.new("UIPadding")
	pagePad.PaddingBottom = UDim.new(0, 20)
	pagePad.Parent = page

	pages[tabKey] = page

	local tabBtn = Instance.new("TextButton")
	tabBtn.Size = UDim2.new(0.86, 0, 0, isMobile and 38 or 34)
	tabBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
	tabBtn.Text = L(resolvedTh, resolvedEn)
	tabBtn.TextColor3 = Color3.fromRGB(210, 210, 220)
	tabBtn.Font = Enum.Font.GothamSemibold
	tabBtn.TextSize = 13
	tabBtn.Parent = sidebar

	registerTranslatable(tabBtn, resolvedTh, resolvedEn)

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 12)
	tabCorner.Parent = tabBtn

	tabButtons[tabKey] = tabBtn

	tabBtn.MouseButton1Click:Connect(function()
		selectTab(tabKey)
	end)

	if not activeTabName then
		selectTab(tabKey)
	end

	return page
end

local function addButton(parentPage, thText, enText, callback)
	local resolvedTh, resolvedEn = resolveBilingualPair(thText, enText)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, isMobile and 46 or 42)
	btn.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
	btn.Text = L(resolvedTh, resolvedEn)
	btn.TextColor3 = Color3.fromRGB(245, 245, 250)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 14
	btn.Parent = parentPage

	registerTranslatable(btn, resolvedTh, resolvedEn)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(62, 62, 78)
	stroke.Thickness = 1
	stroke.Transparency = 0.4
	stroke.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(48, 48, 62)}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(34, 34, 44)}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		if callback then
			callback(currentLang)
		end
	end)

	return btn
end

applyLanguageToAll()

-- ==========================================
-- แอนิเมชันเปิด/ปิด Sidebar, ย่อ (–), ปิด (X)
-- ==========================================
local sidebarOpen = true
local minimized = false
local tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

menuBtn.MouseButton1Click:Connect(function()
	if minimized then return end
	sidebarOpen = not sidebarOpen

	if sidebarOpen then
		TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.fromScale(OPEN_WIDTH, FRAME_HEIGHT)}):Play()
		TweenService:Create(sidebar, tweenInfo, {Size = UDim2.new(SIDEBAR_SCALE, 0, 1, -TOPBAR_PX)}):Play()
		TweenService:Create(contentContainer, tweenInfo, {
			Size = UDim2.new(1 - SIDEBAR_SCALE, 0, 1, -TOPBAR_PX),
			Position = UDim2.new(SIDEBAR_SCALE, 0, 0, TOPBAR_PX)
		}):Play()
	else
		TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.fromScale(CLOSED_WIDTH, FRAME_HEIGHT)}):Play()
		TweenService:Create(sidebar, tweenInfo, {Size = UDim2.new(0, 0, 1, -TOPBAR_PX)}):Play()
		TweenService:Create(contentContainer, tweenInfo, {
			Size = UDim2.new(1, 0, 1, -TOPBAR_PX),
			Position = UDim2.new(0, 0, 0, TOPBAR_PX)
		}):Play()
	end

	task.delay(0.24, keepMainFrameInBounds)
end)

minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	local vp = getViewportSize()
	local targetWidth = sidebarOpen and OPEN_WIDTH or CLOSED_WIDTH
	local minScaleY = TOPBAR_PX / vp.Y

	if minimized then
		contentContainer.Visible = false
		sidebar.Visible = false
		bottomCover.Visible = false
		topLine.Visible = false
		TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.fromScale(targetWidth, minScaleY)}):Play()
		minBtn.Text = "+"
	else
		TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.fromScale(targetWidth, FRAME_HEIGHT)}):Play()
		task.delay(0.1, function()
			if not minimized then
				contentContainer.Visible = true
				sidebar.Visible = true
				bottomCover.Visible = true
				topLine.Visible = true
			end
		end)
		minBtn.Text = "–"
	end

	task.delay(0.24, keepMainFrameInBounds)
end)

local function reopenMainMenu()
	mainFrame.Visible = true
	dockContainer.Visible = false
	isHovered = false
	wasExpanded = false
	keepMainFrameInBounds()
end

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	dockContainer.Visible = true
	updateDockState()
end)

openFloatingBtn.MouseButton1Click:Connect(reopenMainMenu)
clockBtn.MouseButton1Click:Connect(reopenMainMenu)

-- ==========================================
-- ระบบลากย้ายที่ TopBar แบบกันออกนอกจอ
-- ==========================================
local dragging, dragInput, dragStart, startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

topBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local vp = getViewportSize()
		local delta = input.Position - dragStart
		local nextScaleX = startPos.X.Scale + (delta.X / vp.X)
		local nextScaleY = startPos.Y.Scale + (delta.Y / vp.Y)
		local size = mainFrame.AbsoluteSize
		mainFrame.Position = clampPositionToScreen(nextScaleX, nextScaleY, size.X, size.Y)
	end
end)

mainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(keepMainFrameInBounds)

-- ส่งออก API เผื่อเอาไปต่อยอดในสคริปต์แยกหรือเรียกใช้ผ่าน _G / shared
getgenv().ToyHubAPI = {
	createTab = createTab,
	addButton = addButton,
	selectTab = selectTab,
	L = L,
	translateThEn = translateThEn,
	registerTranslatable = registerTranslatable,
	addDict = addDict,
	setLanguage = function(lang)
		if lang == "TH" or lang == "EN" then
			currentLang = lang
			langCircleBtn.Text = currentLang
			langCircleBtn.BackgroundColor3 = (currentLang == "EN") and Color3.fromRGB(235, 64, 78) or Color3.fromRGB(36, 26, 32)
			langStroke.Transparency = (currentLang == "EN") and 0 or 0.25
			applyLanguageToAll()
		end
	end,
	getLanguage = function()
		return currentLang
	end,
}
