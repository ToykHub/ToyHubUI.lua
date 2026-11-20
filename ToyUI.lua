local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- รัน Remote เข้าเกมทันทีเมื่อเริ่มรันสคริปต์
task.spawn(function()
	local ok, err = pcall(function()
		local chestFolder = ReplicatedStorage:WaitForChild("Chest", 15)
		local remotesFolder = chestFolder and chestFolder:WaitForChild("Remotes", 15)
		local functionsFolder = remotesFolder and remotesFolder:WaitForChild("Functions", 15)
		local etcFunction = functionsFolder and functionsFolder:WaitForChild("EtcFunction", 15)
		if etcFunction and etcFunction:IsA("RemoteFunction") then
			etcFunction:InvokeServer("EnterTheGame", {})
		end
	end)
	if not ok then
		warn("[ToyHub] EnterTheGame failed:", err)
	end
end)

if playerGui:FindFirstChild("ToyHubUI") then
	playerGui.ToyHubUI:Destroy()
end

-- ==========================================
-- ตั้งค่าข้อมูลของคุณเองตรงนี้ได้เลย
-- ==========================================
local DISCORD_LINK = "https://discord.gg/3tc2QDYaQ"
local SCRIPT_MADE_BY = {
	th = "Max",
	en = "Max",
}

local DEFAULT_ACCENT_RGB = { r = 235, g = 64, b = 78 }
local DEFAULT_ACCENT_COLOR = Color3.fromRGB(DEFAULT_ACCENT_RGB.r, DEFAULT_ACCENT_RGB.g, DEFAULT_ACCENT_RGB.b)
local DEFAULT_TEXT_COLOR = Color3.fromRGB(248, 248, 255)
local DEFAULT_SURFACE_COLOR = Color3.fromRGB(28, 28, 36)

local defaultRole = {
	th = "สมาชิก",
	en = "Member",
	color = DEFAULT_ACCENT_COLOR,
}

-- สีสำเร็จรูปในเมนู ToyHUB
local TOYHUB_PRESET_COLORS = {
	{ name = "Default (ToyHUB Red)", r = DEFAULT_ACCENT_RGB.r, g = DEFAULT_ACCENT_RGB.g, b = DEFAULT_ACCENT_RGB.b, isDefault = true },
	{ name = "Crimson Flame", r = 220, g = 38, b = 38 },
	{ name = "Cyber Cyan", r = 0, g = 210, b = 255 },
	{ name = "Neon Purple", r = 155, g = 85, b = 255 },
	{ name = "Emerald Green", r = 34, g = 197, b = 94 },
	{ name = "Sunset Orange", r = 249, g = 115, b = 22 },
	{ name = "Hot Pink", r = 236, g = 72, b = 153 },
	{ name = "Royal Blue", r = 59, g = 130, b = 246 },
}

local function detectExecutorName()
	if identifyexecutor then
		local ok, name = pcall(identifyexecutor)
		if ok and typeof(name) == "string" and name ~= "" then
			return name
		end
	end
	if getexecutorname then
		local ok, name = pcall(getexecutorname)
		if ok and typeof(name) == "string" and name ~= "" then
			return name
		end
	end
	if RunService:IsStudio() then
		return "Roblox Studio"
	end
	return "Unknown"
end

local function detectCurrentMapName()
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(game.PlaceId)
	end)
	if ok and info and typeof(info.Name) == "string" and info.Name ~= "" then
		return info.Name
	end
	return "Unknown Map (" .. tostring(game.PlaceId) .. ")"
end

local EXECUTOR_NAME = detectExecutorName()
local CURRENT_MAP_NAME = detectCurrentMapName()

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local BASE_CLOSED_WIDTH = isMobile and 0.50 or 0.30
local BASE_OPEN_WIDTH = isMobile and 0.76 or 0.44
local BASE_FRAME_HEIGHT = isMobile and 0.72 or 0.60
local TOPBAR_PX = isMobile and 54 or 50
local SIDEBAR_SCALE = isMobile and 0.32 or 0.26
local CORNER_PX = isMobile and 18 or 20
local SCREEN_MARGIN = 8

local uiScalePercent = 100
local MIN_UI_SCALE = 70
local MAX_UI_SCALE = 135

-- ==========================================
-- ระบบ Anti-AFK (ป้องกันหลุดเกมเมื่อยืนนิ่งเกิน 20 นาที)
-- ==========================================
local antiAfkEnabled = true
local antiAfkConnection = nil

local function triggerAntiAfkAction()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end)
end

local function setAntiAfkState(state)
	antiAfkEnabled = not not state
	if antiAfkEnabled then
		if not antiAfkConnection then
			antiAfkConnection = player.Idled:Connect(function()
				if antiAfkEnabled then
					triggerAntiAfkAction()
				end
			end)
		end
	else
		if antiAfkConnection then
			antiAfkConnection:Disconnect()
			antiAfkConnection = nil
		end
	end
end

setAntiAfkState(true)

-- ==========================================
-- ระบบสลับและแปลภาษาไทย <-> อังกฤษ (เริ่มต้นเป็น EN)
-- ==========================================
local currentLang = "EN"
local translatableRegistry = {}
local onLanguageChangedCallbacks = {}

local TH_TO_EN = {
	["เมนูหลัก"] = "ToyHUB",
	["MAIN MENU"] = "ToyHUB",
	["ไทย"] = "Thai",
	["อังกฤษ"] = "English",
	["เปิด"] = "On",
	["ปิด"] = "Off",
	["สำเร็จ"] = "Success",
	["ผิดพลาด"] = "Error",
	["โปรไฟล์"] = "Profile",
	["ตั้งค่า"] = "Setting",
	["ภาษา"] = "Language",
	["ขนาด UI"] = "Size UI",
	["สี UI"] = "Color UI",
	["สีเริ่มต้น"] = "Default Color",
	["กันหลุด AFK"] = "Anti-AFK",
	["รีเซ็ตตำแหน่ง UI"] = "Reset UI Position",
	["รีเซ็ตตำแหน่งแล้ว!"] = "UI position reset!",
	["สถานะ"] = "Status",
	["กำลังออนไลน์"] = "Online",
	["แมปที่เล่นอยู่"] = "Current Map",
	["เวลา"] = "Time",
	["สร้างโดย"] = "Made By",
	["ตัวรัน"] = "Executor",
	["คัดลอกลิงก์ Discord"] = "Copy Discord Link",
	["ก๊อปปี้ลิงก์ Discord แล้ว!"] = "Discord link copied!",
	["คัดลอกแท็กชื่อ"] = "Copy Name Tag",
	["ก๊อปปี้แท็กชื่อแล้ว!"] = "Name tag copied!",
	["ก๊อปปี้แล้ว!"] = "Copied!",
	["ซ่อน"] = "Hide",
	["แสดง"] = "Show",
	["ชื่อถูกซ่อน"] = "Hidden User",
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

local function applyFontSizeForLang(guiObj, thSize, enSize)
	if not guiObj then return end
	if currentLang == "TH" then
		guiObj.TextSize = thSize or enSize
	else
		guiObj.TextSize = enSize or thSize
	end
end

local function applyLanguageToAll()
	for _, item in ipairs(translatableRegistry) do
		if item.obj and item.obj.Parent then
			local resolvedTh, resolvedEn = resolveBilingualPair(item.th, item.en)
			item.th = resolvedTh
			item.en = resolvedEn
			item.obj.Text = L(resolvedTh, resolvedEn)
			if item.thSize or item.enSize then
				applyFontSizeForLang(item.obj, item.thSize, item.enSize)
			end
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

local function registerTranslatable(guiObj, thText, enText, thSize, enSize)
	local resolvedTh, resolvedEn = resolveBilingualPair(thText, enText)
	table.insert(translatableRegistry, {
		obj = guiObj,
		th = resolvedTh,
		en = resolvedEn,
		thSize = thSize,
		enSize = enSize,
	})
	guiObj.Text = L(resolvedTh, resolvedEn)
	if thSize or enSize then
		applyFontSizeForLang(guiObj, thSize, enSize)
	end
end

-- ==========================================
-- ระบบธีม 3 ส่วน: Accent (ขอบ/เน้น), Text (ตัวหนังสือ), Surface (กล่อง/พื้นผิว ดำ-เทา)
-- ==========================================
local currentAccentColor = DEFAULT_ACCENT_COLOR
local currentTextColor = DEFAULT_TEXT_COLOR
local currentSurfaceColor = DEFAULT_SURFACE_COLOR
local themeCallbacks = {}

local function clampByte(val, fallback)
	local n = tonumber(val)
	if not n then return fallback end
	return math.clamp(math.floor(n), 0, 255)
end

local function deriveSurfaceFromAccent(accent)
	if accent == DEFAULT_ACCENT_COLOR then
		return DEFAULT_SURFACE_COLOR
	end
	local r = math.clamp(math.floor(18 + (accent.R * 26)), 14, 52)
	local g = math.clamp(math.floor(18 + (accent.G * 26)), 14, 52)
	local b = math.clamp(math.floor(24 + (accent.B * 30)), 18, 60)
	return Color3.fromRGB(r, g, b)
end

local function deriveTextFromAccent(accent)
	if accent == DEFAULT_ACCENT_COLOR then
		return DEFAULT_TEXT_COLOR
	end
	local r = math.clamp(math.floor(236 + (accent.R * 19)), 230, 255)
	local g = math.clamp(math.floor(236 + (accent.G * 19)), 230, 255)
	local b = math.clamp(math.floor(242 + (accent.B * 13)), 230, 255)
	return Color3.fromRGB(r, g, b)
end

local function registerThemeCallback(cb)
	table.insert(themeCallbacks, cb)
end

-- 1. ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ToyHubUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

screenGui.Destroying:Connect(function()
	if antiAfkConnection then
		antiAfkConnection:Disconnect()
		antiAfkConnection = nil
	end
end)

-- 2. หน้าต่างหลัก (MainFrame)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Size = UDim2.fromScale(BASE_OPEN_WIDTH, BASE_FRAME_HEIGHT)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = isMobile and Vector2.new(210, TOPBAR_PX) or Vector2.new(250, TOPBAR_PX)
sizeConstraint.MaxSize = isMobile and Vector2.new(760, 780) or Vector2.new(1120, 920)
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
mainStroke.Color = currentAccentColor
mainStroke.Thickness = 1.6
mainStroke.Transparency = 0.15
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
topLine.BackgroundColor3 = currentAccentColor
topLine.BorderSizePixel = 0
topLine.Parent = topBar

-- ปุ่มแฮมเบอร์เกอร์ (≡)
local menuBtn = Instance.new("TextButton")
menuBtn.Name = "MenuBtn"
menuBtn.AnchorPoint = Vector2.new(0, 0.5)
menuBtn.Size = UDim2.new(0, 36, 0, 36)
menuBtn.Position = UDim2.new(0, 8, 0.5, 0)
menuBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
menuBtn.BackgroundTransparency = 0.25
menuBtn.Text = "≡"
menuBtn.TextColor3 = currentTextColor
menuBtn.Font = Enum.Font.GothamBold
menuBtn.TextSize = 22
menuBtn.Parent = topBar

local menuBtnCorner = Instance.new("UICorner")
menuBtnCorner.CornerRadius = UDim.new(0, 10)
menuBtnCorner.Parent = menuBtn

local menuBtnStroke = Instance.new("UIStroke")
menuBtnStroke.Color = currentAccentColor
menuBtnStroke.Thickness = 1
menuBtnStroke.Transparency = 0.45
menuBtnStroke.Parent = menuBtn

-- ชื่อเมนูบน TopBar
local titleLabel = Instance.new("TextLabel")
titleLabel.AnchorPoint = Vector2.new(0, 0.5)
titleLabel.Size = UDim2.new(1, -136, 0.75, 0)
titleLabel.Position = UDim2.new(0, 52, 0.5, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ToyHUB"
titleLabel.TextColor3 = currentTextColor
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = isMobile and 16 or 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
titleLabel.Parent = topBar
registerTranslatable(titleLabel, "ToyHUB", "ToyHUB", isMobile and 17 or 19, isMobile and 16 or 18)

-- ปุ่มปิด (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Size = UDim2.new(0, 34, 0, 34)
closeBtn.Position = UDim2.new(1, -8, 0.5, 0)
closeBtn.BackgroundColor3 = currentAccentColor
closeBtn.BackgroundTransparency = 0.1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

-- ปุ่มย่อ (–)
local minBtn = Instance.new("TextButton")
minBtn.Name = "MinBtn"
minBtn.AnchorPoint = Vector2.new(1, 0.5)
minBtn.Size = UDim2.new(0, 34, 0, 34)
minBtn.Position = UDim2.new(1, -48, 0.5, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
minBtn.BackgroundTransparency = 0.2
minBtn.Text = "–"
minBtn.TextColor3 = currentTextColor
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
minBtn.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 10)
minCorner.Parent = minBtn

local minBtnStroke = Instance.new("UIStroke")
minBtnStroke.Color = currentAccentColor
minBtnStroke.Thickness = 1
minBtnStroke.Transparency = 0.45
minBtnStroke.Parent = minBtn

-- 4. แถบเมนูด้านซ้าย (Sidebar)
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(SIDEBAR_SCALE, 0, 1, -TOPBAR_PX)
sidebar.Position = UDim2.new(0, 0, 0, TOPBAR_PX)
sidebar.BackgroundTransparency = 1
sidebar.BorderSizePixel = 0
sidebar.ClipsDescendants = true
sidebar.Parent = mainFrame

local sideLayout = Instance.new("UIListLayout")
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0, 8)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.Parent = sidebar

local sidePadding = Instance.new("UIPadding")
sidePadding.PaddingTop = UDim.new(0, 12)
sidePadding.PaddingBottom = UDim.new(0, 16)
sidePadding.Parent = sidebar

-- 5. พื้นที่แสดงเนื้อหาหลัก (Content Area)
local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1 - SIDEBAR_SCALE, 0, 1, -TOPBAR_PX)
contentContainer.Position = UDim2.new(SIDEBAR_SCALE, 0, 0, TOPBAR_PX)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

-- ==========================================
-- 6. แคปซูล + เวลา + รูปโปรไฟล์ + วงกลมเปลี่ยนภาษา + วงกลมล็อก
-- ==========================================
local circleSize = isMobile and 54 or 50
local popCircleSize = math.round(circleSize * 1.12)
local avatarCircleSize = isMobile and 36 or 34
local langCircleSize = isMobile and 36 or 34
local lockCircleSize = isMobile and 36 or 34
local clockW = isMobile and 96 or 106
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
capsuleStroke.Color = currentAccentColor
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
circleStroke.Color = currentAccentColor
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
glowBackLabel.TextColor3 = currentAccentColor
glowBackLabel.TextTransparency = 0.25
glowBackLabel.Font = Enum.Font.FredokaOne
glowBackLabel.TextSize = isMobile and 32 or 30
glowBackLabel.ZIndex = 3
glowBackLabel.Parent = openFloatingBtn

local glowBlur = Instance.new("UIStroke")
glowBlur.Color = currentAccentColor
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
neonTLabel.TextColor3 = currentTextColor
neonTLabel.Font = Enum.Font.FredokaOne
neonTLabel.TextSize = isMobile and 30 or 28
neonTLabel.ZIndex = 4
neonTLabel.Parent = openFloatingBtn

local clockBtn = Instance.new("TextButton")
clockBtn.Name = "ClockBtn"
clockBtn.AnchorPoint = Vector2.new(0, 0.5)
clockBtn.Size = UDim2.new(0, clockW, 0, 36)
clockBtn.Position = UDim2.new(0, popCircleSize + 10, 0.5, 0)
clockBtn.BackgroundColor3 = Color3.fromRGB(36, 26, 32)
clockBtn.Text = os.date("%H:%M:%S")
clockBtn.TextColor3 = currentTextColor
clockBtn.Font = Enum.Font.GothamBold
clockBtn.TextSize = 15
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

local avatarX = popCircleSize + 10 + clockW + 8
local dockAvatarCircle = Instance.new("ImageLabel")
dockAvatarCircle.Name = "CharacterAvatarCircle"
dockAvatarCircle.AnchorPoint = Vector2.new(0, 0.5)
dockAvatarCircle.Size = UDim2.new(0, avatarCircleSize, 0, avatarCircleSize)
dockAvatarCircle.Position = UDim2.new(0, avatarX, 0.5, 0)
dockAvatarCircle.BackgroundColor3 = Color3.fromRGB(42, 30, 38)
dockAvatarCircle.BorderSizePixel = 0
dockAvatarCircle.ScaleType = Enum.ScaleType.Crop
dockAvatarCircle.ZIndex = 3
dockAvatarCircle.Parent = capsuleFrame

local dockAvatarCorner = Instance.new("UICorner")
dockAvatarCorner.CornerRadius = UDim.new(0.5, 0)
dockAvatarCorner.Parent = dockAvatarCircle

local dockAvatarStroke = Instance.new("UIStroke")
dockAvatarStroke.Color = currentAccentColor
dockAvatarStroke.Thickness = 1.6
dockAvatarStroke.Transparency = 0.2
dockAvatarStroke.Parent = dockAvatarCircle

local langX = avatarX + avatarCircleSize + 8
local langCircleBtn = Instance.new("TextButton")
langCircleBtn.Name = "LangCircleBtn"
langCircleBtn.AnchorPoint = Vector2.new(0, 0.5)
langCircleBtn.Size = UDim2.new(0, langCircleSize, 0, langCircleSize)
langCircleBtn.Position = UDim2.new(0, langX, 0.5, 0)
langCircleBtn.BackgroundColor3 = (currentLang == "EN") and currentAccentColor or Color3.fromRGB(36, 26, 32)
langCircleBtn.Text = currentLang
langCircleBtn.TextColor3 = currentTextColor
langCircleBtn.Font = Enum.Font.GothamBold
langCircleBtn.TextSize = 14
langCircleBtn.ZIndex = 4
langCircleBtn.Parent = capsuleFrame

local langCorner = Instance.new("UICorner")
langCorner.CornerRadius = UDim.new(0.5, 0)
langCorner.Parent = langCircleBtn

local langStroke = Instance.new("UIStroke")
langStroke.Color = currentAccentColor
langStroke.Thickness = 1.5
langStroke.Transparency = (currentLang == "EN") and 0 or 0.25
langStroke.Parent = langCircleBtn

local lockX = langX + langCircleSize + 8
local pinLockBtn = Instance.new("TextButton")
pinLockBtn.Name = "PinLockBtn"
pinLockBtn.AnchorPoint = Vector2.new(0, 0.5)
pinLockBtn.Size = UDim2.new(0, lockCircleSize, 0, lockCircleSize)
pinLockBtn.Position = UDim2.new(0, lockX, 0.5, 0)
pinLockBtn.BackgroundColor3 = Color3.fromRGB(36, 26, 32)
pinLockBtn.Text = "🔓"
pinLockBtn.TextColor3 = currentTextColor
pinLockBtn.Font = Enum.Font.GothamBold
pinLockBtn.TextSize = 16
pinLockBtn.ZIndex = 4
pinLockBtn.Parent = capsuleFrame

local pinCorner = Instance.new("UICorner")
pinCorner.CornerRadius = UDim.new(0.5, 0)
pinCorner.Parent = pinLockBtn

local pinStroke = Instance.new("UIStroke")
pinStroke.Color = currentAccentColor
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
			BackgroundColor3 = currentSurfaceColor
		}):Play()
		TweenService:Create(circleStroke, dockTweenInfo, {Thickness = 2.4, Transparency = 0}):Play()
		TweenService:Create(glowBlur, dockTweenInfo, {Thickness = 7.5, Transparency = 0.1}):Play()
	else
		wasExpanded = false
		TweenService:Create(openFloatingBtn, dockTweenInfo, {
			Size = UDim2.new(0, circleSize, 0, circleSize),
			Position = UDim2.new(0, circleSize * 0.5, 0.5, 0),
			BackgroundColor3 = currentSurfaceColor,
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
		or isPointInGui(mousePos, dockAvatarCircle)
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
bindHover(dockAvatarCircle)
bindHover(langCircleBtn)
bindHover(pinLockBtn)

pinLockBtn.MouseButton1Click:Connect(function()
	isPinned = not isPinned
	if isPinned then
		pinLockBtn.Text = "🔒"
		pinLockBtn.BackgroundColor3 = currentAccentColor
		pinStroke.Transparency = 0
	else
		pinLockBtn.Text = "🔓"
		pinLockBtn.BackgroundColor3 = currentSurfaceColor
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
	local size = mainFrame.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return end
	mainFrame.Position = clampPositionToScreen(mainFrame.Position.X.Scale, mainFrame.Position.Y.Scale, size.X, size.Y)
end

-- ==========================================
-- API สำหรับสร้างแท็บ ปุ่ม และอัปเดตธีม 3 ส่วน (Accent / Text / Surface)
-- ลำดับ Sidebar: Profile บนสุด -> แท็บอื่นๆ -> Setting ล่างสุดเสมอ
-- ==========================================
local pages = {}
local tabButtons = {}
local tabStrokes = {}
local activeTabName = nil
local buttonEntries = {}
local nextMiddleTabOrder = 10

local function resolveTabLayoutOrder(resolvedTh, resolvedEn, customOrder)
	if typeof(customOrder) == "number" then
		return customOrder
	end
	local lowerEn = string.lower(resolvedEn or "")
	if resolvedTh == "โปรไฟล์" or lowerEn == "profile" then
		return 1
	end
	if resolvedTh == "ตั้งค่า" or lowerEn == "setting" or lowerEn == "settings" then
		return 999999
	end
	local order = nextMiddleTabOrder
	nextMiddleTabOrder += 10
	return order
end

local function refreshTabStyles()
	for name, btn in pairs(tabButtons) do
		local st = tabStrokes[name]
		if name == activeTabName then
			btn.BackgroundColor3 = currentAccentColor
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			if st then
				st.Color = currentAccentColor
				st.Transparency = 0
			end
		else
			btn.BackgroundColor3 = currentSurfaceColor
			btn.TextColor3 = currentTextColor
			if st then
				st.Color = currentAccentColor
				st.Transparency = 0.5
			end
		end
	end
end

local function applyThemeLayers(accentCol, textCol, surfaceCol)
	currentAccentColor = accentCol
	currentTextColor = textCol or deriveTextFromAccent(accentCol)
	currentSurfaceColor = surfaceCol or deriveSurfaceFromAccent(accentCol)
	defaultRole.color = accentCol

	mainStroke.Color = currentAccentColor
	topLine.BackgroundColor3 = currentAccentColor
	closeBtn.BackgroundColor3 = currentAccentColor
	menuBtnStroke.Color = currentAccentColor
	minBtnStroke.Color = currentAccentColor
	capsuleStroke.Color = currentAccentColor
	circleStroke.Color = currentAccentColor
	glowBackLabel.TextColor3 = currentAccentColor
	glowBlur.Color = currentAccentColor
	dockAvatarStroke.Color = currentAccentColor
	langStroke.Color = currentAccentColor
	pinStroke.Color = currentAccentColor

	titleLabel.TextColor3 = currentTextColor
	menuBtn.TextColor3 = currentTextColor
	minBtn.TextColor3 = currentTextColor
	neonTLabel.TextColor3 = currentTextColor
	clockBtn.TextColor3 = currentTextColor
	langCircleBtn.TextColor3 = currentTextColor
	pinLockBtn.TextColor3 = currentTextColor

	topBar.BackgroundColor3 = currentSurfaceColor
	bottomCover.BackgroundColor3 = currentSurfaceColor
	capsuleFrame.BackgroundColor3 = currentSurfaceColor
	clockBtn.BackgroundColor3 = currentSurfaceColor
	dockAvatarCircle.BackgroundColor3 = currentSurfaceColor
	if not isPinned then
		pinLockBtn.BackgroundColor3 = currentSurfaceColor
	end
	if currentLang ~= "EN" then
		langCircleBtn.BackgroundColor3 = currentSurfaceColor
	else
		langCircleBtn.BackgroundColor3 = currentAccentColor
	end

	for _, entry in ipairs(buttonEntries) do
		if entry.btn and entry.btn.Parent then
			entry.btn.BackgroundColor3 = currentSurfaceColor
			entry.btn.TextColor3 = currentTextColor
			if entry.stroke then
				entry.stroke.Color = currentAccentColor
				entry.stroke.Transparency = 0.35
			end
		end
	end

	for _, p in pairs(pages) do
		p.ScrollBarImageColor3 = currentAccentColor
	end

	refreshTabStyles()

	for _, cb in ipairs(themeCallbacks) do
		pcall(cb, currentAccentColor, currentTextColor, currentSurfaceColor)
	end
end

local function selectTab(tabKey)
	activeTabName = tabKey
	for name, p in pairs(pages) do
		p.Visible = (name == tabKey)
	end
	refreshTabStyles()
end

local function createTab(thTabName, enTabName, customOrder)
	local resolvedTh, resolvedEn = resolveBilingualPair(thTabName, enTabName)
	local tabKey = resolvedTh ~= "" and resolvedTh or resolvedEn
	local tabOrder = resolveTabLayoutOrder(resolvedTh, resolvedEn, customOrder)

	local page = Instance.new("ScrollingFrame")
	page.Name = (resolvedEn ~= "" and resolvedEn or "Tab") .. "Page"
	page.Size = UDim2.new(1, -24, 1, -24)
	page.Position = UDim2.new(0, 12, 0, 12)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = currentAccentColor
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
	tabBtn.Name = (resolvedEn ~= "" and resolvedEn or "Tab") .. "TabBtn"
	tabBtn.LayoutOrder = tabOrder
	tabBtn.Size = UDim2.new(0.88, 0, 0, isMobile and 42 or 38)
	tabBtn.BackgroundColor3 = currentSurfaceColor
	tabBtn.Text = L(resolvedTh, resolvedEn)
	tabBtn.TextColor3 = currentTextColor
	tabBtn.Font = Enum.Font.GothamBold
	tabBtn.TextSize = 15
	tabBtn.Parent = sidebar

	registerTranslatable(tabBtn, resolvedTh, resolvedEn, 16, 15)

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 12)
	tabCorner.Parent = tabBtn

	local tabStroke = Instance.new("UIStroke")
	tabStroke.Color = currentAccentColor
	tabStroke.Thickness = 1.1
	tabStroke.Transparency = 0.5
	tabStroke.Parent = tabBtn

	tabButtons[tabKey] = tabBtn
	tabStrokes[tabKey] = tabStroke

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
	btn.Size = UDim2.new(1, 0, 0, isMobile and 50 or 46)
	btn.BackgroundColor3 = currentSurfaceColor
	btn.Text = L(resolvedTh, resolvedEn)
	btn.TextColor3 = currentTextColor
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.Parent = parentPage

	registerTranslatable(btn, resolvedTh, resolvedEn, 17, 16)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = currentAccentColor
	stroke.Thickness = 1.1
	stroke.Transparency = 0.35
	stroke.Parent = btn

	table.insert(buttonEntries, { btn = btn, stroke = stroke })

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = currentAccentColor}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = currentSurfaceColor}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		if callback then
			callback(currentLang, btn)
		end
	end)

	return btn
end

-- ==========================================
-- สร้างหน้า Profile รวมอยู่ในตัว UI (อยู่บนสุดเสมอ: LayoutOrder = 1)
-- ==========================================
local profileTab = createTab("โปรไฟล์", "Profile", 1)
local hideIdentity = true

local tagCard = Instance.new("Frame")
tagCard.Name = "NameTagCard"
tagCard.Size = UDim2.new(1, 0, 0, 92)
tagCard.BackgroundColor3 = currentSurfaceColor
tagCard.BorderSizePixel = 0
tagCard.Parent = profileTab

local tagCorner = Instance.new("UICorner")
tagCorner.CornerRadius = UDim.new(0, 14)
tagCorner.Parent = tagCard

local tagStroke = Instance.new("UIStroke")
tagStroke.Color = currentAccentColor
tagStroke.Thickness = 1.3
tagStroke.Transparency = 0.25
tagStroke.Parent = tagCard

local profileAvatarCircle = Instance.new("ImageLabel")
profileAvatarCircle.Name = "AvatarCircle"
profileAvatarCircle.AnchorPoint = Vector2.new(0, 0.5)
profileAvatarCircle.Size = UDim2.new(0, 60, 0, 60)
profileAvatarCircle.Position = UDim2.new(0, 12, 0.5, 0)
profileAvatarCircle.BackgroundColor3 = Color3.fromRGB(42, 30, 38)
profileAvatarCircle.BorderSizePixel = 0
profileAvatarCircle.ScaleType = Enum.ScaleType.Crop
profileAvatarCircle.Parent = tagCard

local profileAvatarCorner = Instance.new("UICorner")
profileAvatarCorner.CornerRadius = UDim.new(0.5, 0)
profileAvatarCorner.Parent = profileAvatarCircle

local profileAvatarStroke = Instance.new("UIStroke")
profileAvatarStroke.Color = currentAccentColor
profileAvatarStroke.Thickness = 1.6
profileAvatarStroke.Transparency = 0.2
profileAvatarStroke.Parent = profileAvatarCircle

task.spawn(function()
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
	end)
	if ok and content then
		if dockAvatarCircle.Parent then
			dockAvatarCircle.Image = content
		end
		if profileAvatarCircle.Parent then
			profileAvatarCircle.Image = content
		end
	end
end)

local badgePill = Instance.new("TextLabel")
badgePill.Name = "RoleBadge"
badgePill.AnchorPoint = Vector2.new(0, 0)
badgePill.Size = UDim2.new(0, 84, 0, 24)
badgePill.Position = UDim2.new(0, 82, 0, 14)
badgePill.BackgroundColor3 = currentAccentColor
badgePill.TextColor3 = Color3.fromRGB(255, 255, 255)
badgePill.Font = Enum.Font.GothamBold
badgePill.TextSize = 13
badgePill.Parent = tagCard

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0.5, 0)
badgeCorner.Parent = badgePill

local toggleHideBtn = Instance.new("TextButton")
toggleHideBtn.Name = "ToggleHideIdentityBtn"
toggleHideBtn.AnchorPoint = Vector2.new(1, 0)
toggleHideBtn.Size = UDim2.new(0, 62, 0, 24)
toggleHideBtn.Position = UDim2.new(1, -10, 0, 14)
toggleHideBtn.BackgroundColor3 = currentAccentColor
toggleHideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleHideBtn.Font = Enum.Font.GothamBold
toggleHideBtn.TextSize = 12
toggleHideBtn.Parent = tagCard

local toggleHideCorner = Instance.new("UICorner")
toggleHideCorner.CornerRadius = UDim.new(0, 8)
toggleHideCorner.Parent = toggleHideBtn

local toggleHideStroke = Instance.new("UIStroke")
toggleHideStroke.Color = currentAccentColor
toggleHideStroke.Thickness = 1.1
toggleHideStroke.Transparency = 0
toggleHideStroke.Parent = toggleHideBtn

local mainTagLabel = Instance.new("TextLabel")
mainTagLabel.Name = "MainTagText"
mainTagLabel.AnchorPoint = Vector2.new(0, 0)
mainTagLabel.Size = UDim2.new(1, -242, 0, 24)
mainTagLabel.Position = UDim2.new(0, 172, 0, 14)
mainTagLabel.BackgroundTransparency = 1
mainTagLabel.Text = "Hidden User"
mainTagLabel.TextColor3 = currentTextColor
mainTagLabel.Font = Enum.Font.GothamBold
mainTagLabel.TextSize = 16
mainTagLabel.TextXAlignment = Enum.TextXAlignment.Left
mainTagLabel.TextTruncate = Enum.TextTruncate.AtEnd
mainTagLabel.Parent = tagCard

local subTagLabel = Instance.new("TextLabel")
subTagLabel.Name = "SubTagText"
subTagLabel.AnchorPoint = Vector2.new(0, 0)
subTagLabel.Size = UDim2.new(1, -94, 0, 22)
subTagLabel.Position = UDim2.new(0, 82, 0, 48)
subTagLabel.BackgroundTransparency = 1
subTagLabel.Text = "@Hidden  •  ID: Hidden"
subTagLabel.TextColor3 = currentTextColor
subTagLabel.TextTransparency = 0.25
subTagLabel.Font = Enum.Font.GothamBold
subTagLabel.TextSize = 14
subTagLabel.TextXAlignment = Enum.TextXAlignment.Left
subTagLabel.TextTruncate = Enum.TextTruncate.AtEnd
subTagLabel.Parent = tagCard

local detailCard = Instance.new("Frame")
detailCard.Name = "ProfileDetailCard"
detailCard.Size = UDim2.new(1, 0, 0, 162)
detailCard.BackgroundColor3 = currentSurfaceColor
detailCard.BorderSizePixel = 0
detailCard.Parent = profileTab

local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 14)
detailCorner.Parent = detailCard

local detailStroke = Instance.new("UIStroke")
detailStroke.Color = currentAccentColor
detailStroke.Thickness = 1.1
detailStroke.Transparency = 0.4
detailStroke.Parent = detailCard

local detailPad = Instance.new("UIPadding")
detailPad.PaddingTop = UDim.new(0, 12)
detailPad.PaddingBottom = UDim.new(0, 12)
detailPad.PaddingLeft = UDim.new(0, 14)
detailPad.PaddingRight = UDim.new(0, 14)
detailPad.Parent = detailCard

local detailLayout = Instance.new("UIListLayout")
detailLayout.Padding = UDim.new(0, 7)
detailLayout.Parent = detailCard

local detailRows = {}
local function createDetailRow()
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.TextColor3 = currentTextColor
	row.Font = Enum.Font.GothamBold
	row.TextSize = 14
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextTruncate = Enum.TextTruncate.AtEnd
	row.Parent = detailCard
	table.insert(detailRows, row)
	return row
end

local statusRow = createDetailRow()
local mapRow = createDetailRow()
local timeRow = createDetailRow()
local executorRow = createDetailRow()
local creatorRow = createDetailRow()

local copyToast = Instance.new("Frame")
copyToast.Name = "CopyToastBanner"
copyToast.Size = UDim2.new(1, 0, 0, 38)
copyToast.BackgroundColor3 = currentSurfaceColor
copyToast.BorderSizePixel = 0
copyToast.Visible = false
copyToast.Parent = profileTab

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 12)
toastCorner.Parent = copyToast

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = currentAccentColor
toastStroke.Thickness = 1.2
toastStroke.Parent = copyToast

local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(1, -16, 1, 0)
toastLabel.Position = UDim2.new(0, 8, 0, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.Text = ""
toastLabel.TextColor3 = currentTextColor
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 14
toastLabel.TextTruncate = Enum.TextTruncate.AtEnd
toastLabel.Parent = copyToast

local toastToken = 0

local function showCopiedFeedback(btnObj, thMsg, enMsg)
	toastToken += 1
	local currentToken = toastToken
	local msg = L(thMsg, enMsg)

	copyToast.Visible = true
	applyFontSizeForLang(toastLabel, 15, 14)
	toastLabel.Text = "✓ " .. msg
	TweenService:Create(copyToast, TweenInfo.new(0.15), { BackgroundColor3 = currentSurfaceColor }):Play()

	local oldBtnText = btnObj and btnObj.Text
	if btnObj then
		applyFontSizeForLang(btnObj, 17, 16)
		btnObj.Text = "✓ " .. L("ก๊อปปี้แล้ว!", "Copied!")
		btnObj.BackgroundColor3 = currentAccentColor
	end

	print(msg)

	task.delay(1.6, function()
		if currentToken ~= toastToken then
			return
		end
		if btnObj and btnObj.Parent and oldBtnText then
			btnObj.Text = oldBtnText
			btnObj.BackgroundColor3 = currentSurfaceColor
		end
		if copyToast and copyToast.Parent then
			copyToast.Visible = false
		end
	end)
end

local function refreshProfileUI()
	applyFontSizeForLang(badgePill, 14, 13)
	badgePill.Text = L(defaultRole.th, defaultRole.en)
	badgePill.BackgroundColor3 = currentAccentColor
	tagStroke.Color = currentAccentColor

	applyFontSizeForLang(toggleHideBtn, 13, 12)
	if hideIdentity then
		mainTagLabel.Text = L("ชื่อถูกซ่อน", "Hidden User")
		subTagLabel.Text = "@" .. L("ซ่อน", "Hidden") .. "  •  ID: " .. L("ซ่อน", "Hidden")
		toggleHideBtn.Text = L("แสดง", "Show")
		toggleHideBtn.BackgroundColor3 = currentAccentColor
		toggleHideStroke.Transparency = 0
	else
		mainTagLabel.Text = player.DisplayName
		subTagLabel.Text = "@" .. player.Name .. "  •  ID: " .. tostring(player.UserId)
		toggleHideBtn.Text = L("ซ่อน", "Hide")
		toggleHideBtn.BackgroundColor3 = currentSurfaceColor
		toggleHideStroke.Transparency = 0.35
	end

	for _, r in ipairs({ statusRow, mapRow, timeRow, executorRow, creatorRow }) do
		applyFontSizeForLang(r, 15, 14)
	end

	statusRow.Text = L("สถานะ", "Status") .. ": " .. L("กำลังออนไลน์", "Online")
	mapRow.Text = L("แมปที่เล่นอยู่", "Current Map") .. ": " .. CURRENT_MAP_NAME
	timeRow.Text = L("เวลา", "Time") .. ": " .. os.date("%H:%M:%S")
	executorRow.Text = L("ตัวรัน", "Executor") .. ": " .. EXECUTOR_NAME
	creatorRow.Text = L("สร้างโดย", "Made By") .. ": " .. L(SCRIPT_MADE_BY.th, SCRIPT_MADE_BY.en)
end

toggleHideBtn.MouseButton1Click:Connect(function()
	hideIdentity = not hideIdentity
	refreshProfileUI()
end)

refreshProfileUI()

task.spawn(function()
	while profileTab.Parent do
		applyFontSizeForLang(timeRow, 15, 14)
		timeRow.Text = L("เวลา", "Time") .. ": " .. os.date("%H:%M:%S")
		task.wait(1)
	end
end)

local copyDiscordBtn = addButton(profileTab, "คัดลอกลิงก์ Discord", "Copy Discord Link", function(lang, btn)
	if setclipboard then
		pcall(setclipboard, DISCORD_LINK)
	end
	showCopiedFeedback(btn or copyDiscordBtn, "ก๊อปปี้ลิงก์ Discord แล้ว!", "Discord link copied!")
end)

local copyNameTagBtn = addButton(profileTab, "คัดลอกแท็กชื่อ", "Copy Name Tag", function(lang, btn)
	local displayNameText = hideIdentity and L("ชื่อถูกซ่อน", "Hidden User") or player.DisplayName
	local userText = hideIdentity and L("ซ่อน", "Hidden") or player.Name
	local formatted = "[" .. L(defaultRole.th, defaultRole.en) .. "] " .. displayNameText .. " (@" .. userText .. ")"
	if setclipboard then
		pcall(setclipboard, formatted)
	end
	showCopiedFeedback(btn or copyNameTagBtn, "ก๊อปปี้แท็กชื่อแล้ว!", "Name tag copied!")
end)

-- ==========================================
-- สร้างแท็บ Setting / ตั้งค่า (อยู่ล่างสุดเสมอ: LayoutOrder = 999999)
-- ==========================================
local settingTab = createTab("ตั้งค่า", "Setting", 999999)
local sidebarOpen = true
local minimized = false
local tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function getCurrentTargetSize()
	local factor = uiScalePercent / 100
	if minimized then
		local vp = getViewportSize()
		local w = (sidebarOpen and BASE_OPEN_WIDTH or BASE_CLOSED_WIDTH) * factor
		return UDim2.fromScale(w, TOPBAR_PX / vp.Y)
	end
	local w = (sidebarOpen and BASE_OPEN_WIDTH or BASE_CLOSED_WIDTH) * factor
	local h = BASE_FRAME_HEIGHT * factor
	return UDim2.fromScale(w, h)
end

local function applyUiScale(newPercent, animate)
	local clamped = math.clamp(math.floor(tonumber(newPercent) or 100), MIN_UI_SCALE, MAX_UI_SCALE)
	uiScalePercent = clamped
	local targetSize = getCurrentTargetSize()
	if animate then
		TweenService:Create(mainFrame, tweenInfo, { Size = targetSize }):Play()
		task.delay(0.24, keepMainFrameInBounds)
	else
		mainFrame.Size = targetSize
		keepMainFrameInBounds()
	end
end

-- การ์ด Color UI (ตั้งค่าเริ่มต้นเป็นสี ToyHUB และมีปุ่ม Default Color)
local COLOR_CARD_COLLAPSED_H = 56
local colorCard = Instance.new("Frame")
colorCard.Name = "ColorUICard"
colorCard.Size = UDim2.new(1, 0, 0, COLOR_CARD_COLLAPSED_H)
colorCard.BackgroundColor3 = currentSurfaceColor
colorCard.BorderSizePixel = 0
colorCard.ClipsDescendants = true
colorCard.Parent = settingTab

local colorCardCorner = Instance.new("UICorner")
colorCardCorner.CornerRadius = UDim.new(0, 14)
colorCardCorner.Parent = colorCard

local colorCardStroke = Instance.new("UIStroke")
colorCardStroke.Color = currentAccentColor
colorCardStroke.Thickness = 1.2
colorCardStroke.Transparency = 0.35
colorCardStroke.Parent = colorCard

local colorTitleLabel = Instance.new("TextLabel")
colorTitleLabel.AnchorPoint = Vector2.new(0, 0.5)
colorTitleLabel.Size = UDim2.new(0.36, 0, 0, 28)
colorTitleLabel.Position = UDim2.new(0, 14, 0, 28)
colorTitleLabel.BackgroundTransparency = 1
colorTitleLabel.TextColor3 = currentTextColor
colorTitleLabel.Font = Enum.Font.GothamBold
colorTitleLabel.TextSize = 15
colorTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
colorTitleLabel.Parent = colorCard
registerTranslatable(colorTitleLabel, "สี UI", "Color UI", 16, 15)

local resetDefaultColorBtn = Instance.new("TextButton")
resetDefaultColorBtn.Name = "ResetDefaultColorBtn"
resetDefaultColorBtn.AnchorPoint = Vector2.new(1, 0.5)
resetDefaultColorBtn.Size = UDim2.new(0.28, 0, 0, 32)
resetDefaultColorBtn.Position = UDim2.new(0.64, -6, 0, 28)
resetDefaultColorBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
resetDefaultColorBtn.TextColor3 = currentTextColor
resetDefaultColorBtn.Font = Enum.Font.GothamBold
resetDefaultColorBtn.TextSize = 11
resetDefaultColorBtn.TextTruncate = Enum.TextTruncate.AtEnd
resetDefaultColorBtn.Parent = colorCard
registerTranslatable(resetDefaultColorBtn, "สีเริ่มต้น", "Default Color", 12, 11)

local resetDefaultCorner = Instance.new("UICorner")
resetDefaultCorner.CornerRadius = UDim.new(0, 8)
resetDefaultCorner.Parent = resetDefaultColorBtn

local resetDefaultStroke = Instance.new("UIStroke")
resetDefaultStroke.Color = currentAccentColor
resetDefaultStroke.Thickness = 1
resetDefaultStroke.Transparency = 0.35
resetDefaultStroke.Parent = resetDefaultColorBtn

local toyHubDropdownBtn = Instance.new("TextButton")
toyHubDropdownBtn.Name = "ToyHubPresetToggleBtn"
toyHubDropdownBtn.AnchorPoint = Vector2.new(1, 0.5)
toyHubDropdownBtn.Size = UDim2.new(0.31, 0, 0, 34)
toyHubDropdownBtn.Position = UDim2.new(1, -14, 0, 28)
toyHubDropdownBtn.BackgroundColor3 = currentAccentColor
toyHubDropdownBtn.Text = "ToyHUB ▾"
toyHubDropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toyHubDropdownBtn.Font = Enum.Font.GothamBold
toyHubDropdownBtn.TextSize = 13
toyHubDropdownBtn.TextTruncate = Enum.TextTruncate.AtEnd
toyHubDropdownBtn.Parent = colorCard

local toyHubCorner = Instance.new("UICorner")
toyHubCorner.CornerRadius = UDim.new(0, 8)
toyHubCorner.Parent = toyHubDropdownBtn

local toyHubDropdownStroke = Instance.new("UIStroke")
toyHubDropdownStroke.Color = currentAccentColor
toyHubDropdownStroke.Thickness = 1.2
toyHubDropdownStroke.Transparency = 0.15
toyHubDropdownStroke.Parent = toyHubDropdownBtn

local presetListFrame = Instance.new("Frame")
presetListFrame.Name = "ToyHubPresetList"
presetListFrame.Size = UDim2.new(1, -28, 0, (#TOYHUB_PRESET_COLORS * 30) + 8)
presetListFrame.Position = UDim2.new(0, 14, 0, 54)
presetListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
presetListFrame.BorderSizePixel = 0
presetListFrame.Visible = false
presetListFrame.Parent = colorCard

local presetListCorner = Instance.new("UICorner")
presetListCorner.CornerRadius = UDim.new(0, 10)
presetListCorner.Parent = presetListFrame

local presetListStroke = Instance.new("UIStroke")
presetListStroke.Color = currentAccentColor
presetListStroke.Thickness = 1.1
presetListStroke.Transparency = 0.25
presetListStroke.Parent = presetListFrame

local presetLayout = Instance.new("UIListLayout")
presetLayout.Padding = UDim.new(0, 4)
presetLayout.Parent = presetListFrame

local presetPad = Instance.new("UIPadding")
presetPad.PaddingTop = UDim.new(0, 4)
presetPad.PaddingBottom = UDim.new(0, 4)
presetPad.PaddingLeft = UDim.new(0, 6)
presetPad.PaddingRight = UDim.new(0, 6)
presetPad.Parent = presetListFrame

local presetListOpen = false

local function rgbToHex(r, g, b)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function applyExactRgbColor(rVal, gVal, bVal)
	local r = clampByte(rVal, DEFAULT_ACCENT_RGB.r)
	local g = clampByte(gVal, DEFAULT_ACCENT_RGB.g)
	local b = clampByte(bVal, DEFAULT_ACCENT_RGB.b)

	local isDefault = (r == DEFAULT_ACCENT_RGB.r and g == DEFAULT_ACCENT_RGB.g and b == DEFAULT_ACCENT_RGB.b)
	local accent = isDefault and DEFAULT_ACCENT_COLOR or Color3.fromRGB(r, g, b)
	local surface = isDefault and DEFAULT_SURFACE_COLOR or deriveSurfaceFromAccent(accent)
	local textCol = isDefault and DEFAULT_TEXT_COLOR or deriveTextFromAccent(accent)

	applyThemeLayers(accent, textCol, surface)
end

local function applyToyHubDefaultColor()
	applyThemeLayers(DEFAULT_ACCENT_COLOR, DEFAULT_TEXT_COLOR, DEFAULT_SURFACE_COLOR)
end

local function setPresetDropdownOpen(openState)
	presetListOpen = not not openState
	presetListFrame.Visible = presetListOpen
	toyHubDropdownBtn.Text = presetListOpen and "ToyHUB ▴" or "ToyHUB ▾"

	local targetH = COLOR_CARD_COLLAPSED_H
	if presetListOpen then
		targetH = 54 + (#TOYHUB_PRESET_COLORS * 30) + 16
	end
	TweenService:Create(colorCard, tweenInfo, { Size = UDim2.new(1, 0, 0, targetH) }):Play()
end

local presetRowBtns = {}
for _, item in ipairs(TOYHUB_PRESET_COLORS) do
	local rowBtn = Instance.new("TextButton")
	rowBtn.Size = UDim2.new(1, 0, 0, 26)
	rowBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 46)
	rowBtn.Text = "●  " .. item.name .. "  (" .. rgbToHex(item.r, item.g, item.b) .. ")"
	rowBtn.TextColor3 = Color3.fromRGB(item.r, item.g, item.b)
	rowBtn.Font = Enum.Font.GothamBold
	rowBtn.TextSize = 12
	rowBtn.TextXAlignment = Enum.TextXAlignment.Left
	rowBtn.TextTruncate = Enum.TextTruncate.AtEnd
	rowBtn.Parent = presetListFrame
	table.insert(presetRowBtns, rowBtn)

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent = rowBtn

	local rowPad = Instance.new("UIPadding")
	rowPad.PaddingLeft = UDim.new(0, 8)
	rowPad.Parent = rowBtn

	rowBtn.MouseButton1Click:Connect(function()
		if item.isDefault then
			applyToyHubDefaultColor()
		else
			applyExactRgbColor(item.r, item.g, item.b)
		end
	end)
end

resetDefaultColorBtn.MouseButton1Click:Connect(applyToyHubDefaultColor)

toyHubDropdownBtn.MouseButton1Click:Connect(function()
	setPresetDropdownOpen(not presetListOpen)
end)

-- การ์ด Size UI
local sizeCard = Instance.new("Frame")
sizeCard.Name = "SizeUICard"
sizeCard.Size = UDim2.new(1, 0, 0, 96)
sizeCard.BackgroundColor3 = currentSurfaceColor
sizeCard.BorderSizePixel = 0
sizeCard.Parent = settingTab

local sizeCardCorner = Instance.new("UICorner")
sizeCardCorner.CornerRadius = UDim.new(0, 14)
sizeCardCorner.Parent = sizeCard

local sizeCardStroke = Instance.new("UIStroke")
sizeCardStroke.Color = currentAccentColor
sizeCardStroke.Thickness = 1.2
sizeCardStroke.Transparency = 0.35
sizeCardStroke.Parent = sizeCard

local sizeTitleLabel = Instance.new("TextLabel")
sizeTitleLabel.Size = UDim2.new(0.65, 0, 0, 24)
sizeTitleLabel.Position = UDim2.new(0, 14, 0, 10)
sizeTitleLabel.BackgroundTransparency = 1
sizeTitleLabel.TextColor3 = currentTextColor
sizeTitleLabel.Font = Enum.Font.GothamBold
sizeTitleLabel.TextSize = 15
sizeTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeTitleLabel.Parent = sizeCard
registerTranslatable(sizeTitleLabel, "ขนาด UI", "Size UI", 16, 15)

local sizeValueAboveLabel = Instance.new("TextLabel")
sizeValueAboveLabel.Size = UDim2.new(0, 68, 0, 20)
sizeValueAboveLabel.Position = UDim2.new(1, -82, 0, 10)
sizeValueAboveLabel.BackgroundTransparency = 1
sizeValueAboveLabel.Text = tostring(uiScalePercent)
sizeValueAboveLabel.TextColor3 = currentAccentColor
sizeValueAboveLabel.Font = Enum.Font.GothamBold
sizeValueAboveLabel.TextSize = 14
sizeValueAboveLabel.TextXAlignment = Enum.TextXAlignment.Center
sizeValueAboveLabel.Parent = sizeCard

local sizeInputBox = Instance.new("TextBox")
sizeInputBox.Name = "SizeValueInput"
sizeInputBox.Size = UDim2.new(0, 68, 0, 32)
sizeInputBox.Position = UDim2.new(1, -82, 0, 44)
sizeInputBox.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
sizeInputBox.Text = tostring(uiScalePercent)
sizeInputBox.TextColor3 = currentTextColor
sizeInputBox.Font = Enum.Font.GothamBold
sizeInputBox.TextSize = 15
sizeInputBox.ClearTextOnFocus = false
sizeInputBox.Parent = sizeCard

local sizeInputCorner = Instance.new("UICorner")
sizeInputCorner.CornerRadius = UDim.new(0, 8)
sizeInputCorner.Parent = sizeInputBox

local sizeInputStroke = Instance.new("UIStroke")
sizeInputStroke.Color = currentAccentColor
sizeInputStroke.Thickness = 1.2
sizeInputStroke.Transparency = 0.25
sizeInputStroke.Parent = sizeInputBox

local sliderTrack = Instance.new("Frame")
sliderTrack.Name = "SizeSliderTrack"
sliderTrack.AnchorPoint = Vector2.new(0, 0.5)
sliderTrack.Size = UDim2.new(1, -108, 0, 5)
sliderTrack.Position = UDim2.new(0, 14, 0, 60)
sliderTrack.BackgroundColor3 = Color3.fromRGB(58, 58, 74)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = sizeCard

local sliderTrackCorner = Instance.new("UICorner")
sliderTrackCorner.CornerRadius = UDim.new(0.5, 0)
sliderTrackCorner.Parent = sliderTrack

local sliderFill = Instance.new("Frame")
sliderFill.Name = "SizeSliderFill"
sliderFill.Size = UDim2.new(1, 0, 1, 0)
sliderFill.BackgroundColor3 = currentAccentColor
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(0.5, 0)
sliderFillCorner.Parent = sliderFill

local sliderKnob = Instance.new("TextButton")
sliderKnob.Name = "SizeSliderKnob"
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Size = UDim2.new(0, 18, 0, 18)
sliderKnob.Position = UDim2.new(1, 0, 0.5, 0)
sliderKnob.BackgroundColor3 = currentTextColor
sliderKnob.Text = ""
sliderKnob.Parent = sliderTrack

local sliderKnobCorner = Instance.new("UICorner")
sliderKnobCorner.CornerRadius = UDim.new(0.5, 0)
sliderKnobCorner.Parent = sliderKnob

local sliderKnobStroke = Instance.new("UIStroke")
sliderKnobStroke.Color = currentAccentColor
sliderKnobStroke.Thickness = 2.5
sliderKnobStroke.Parent = sliderKnob

local function syncSizeControls(percentVal, animateFrame)
	local pct = math.clamp(math.floor(tonumber(percentVal) or 100), MIN_UI_SCALE, MAX_UI_SCALE)
	local ratio = (pct - MIN_UI_SCALE) / (MAX_UI_SCALE - MIN_UI_SCALE)
	sizeValueAboveLabel.Text = tostring(pct)
	sizeInputBox.Text = tostring(pct)
	sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
	sliderKnob.Position = UDim2.new(ratio, 0, 0.5, 0)
	applyUiScale(pct, animateFrame)
end

local slidingSize = false

local function updateSizeFromPointerX(pointerX)
	local absPos = sliderTrack.AbsolutePosition.X
	local absW = sliderTrack.AbsoluteSize.X
	if absW <= 0 then return end
	local alpha = math.clamp((pointerX - absPos) / absW, 0, 1)
	local pct = math.round(MIN_UI_SCALE + (alpha * (MAX_UI_SCALE - MIN_UI_SCALE)))
	syncSizeControls(pct, false)
end

sliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		slidingSize = true
		updateSizeFromPointerX(input.Position.X)
	end
end)

sliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		slidingSize = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		slidingSize = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if slidingSize and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateSizeFromPointerX(input.Position.X)
	end
end)

sizeInputBox.FocusLost:Connect(function()
	syncSizeControls(sizeInputBox.Text, true)
end)

-- ลงทะเบียนอัปเดตทุกองค์ประกอบเมื่อเปลี่ยนธีม 3 ส่วน (Accent / Text / Surface)
registerThemeCallback(function(accentCol, textCol, surfaceCol)
	tagCard.BackgroundColor3 = surfaceCol
	tagStroke.Color = accentCol
	profileAvatarStroke.Color = accentCol
	badgePill.BackgroundColor3 = accentCol
	mainTagLabel.TextColor3 = textCol
	subTagLabel.TextColor3 = textCol
	toggleHideBtn.BackgroundColor3 = hideIdentity and accentCol or surfaceCol
	toggleHideStroke.Color = accentCol
	detailCard.BackgroundColor3 = surfaceCol
	detailStroke.Color = accentCol
	for _, r in ipairs(detailRows) do
		r.TextColor3 = textCol
	end
	copyToast.BackgroundColor3 = surfaceCol
	toastStroke.Color = accentCol
	toastLabel.TextColor3 = textCol

	colorCard.BackgroundColor3 = surfaceCol
	colorCardStroke.Color = accentCol
	colorTitleLabel.TextColor3 = textCol
	resetDefaultColorBtn.BackgroundColor3 = Color3.fromRGB(
		math.clamp(math.floor(surfaceCol.R * 255) + 12, 0, 255),
		math.clamp(math.floor(surfaceCol.G * 255) + 12, 0, 255),
		math.clamp(math.floor(surfaceCol.B * 255) + 16, 0, 255)
	)
	resetDefaultColorBtn.TextColor3 = textCol
	resetDefaultStroke.Color = accentCol
	toyHubDropdownBtn.BackgroundColor3 = accentCol
	toyHubDropdownStroke.Color = accentCol
	presetListFrame.BackgroundColor3 = surfaceCol
	presetListStroke.Color = accentCol
	for _, rowBtn in ipairs(presetRowBtns) do
		rowBtn.BackgroundColor3 = Color3.fromRGB(
			math.clamp(math.floor(surfaceCol.R * 255) + 8, 0, 255),
			math.clamp(math.floor(surfaceCol.G * 255) + 8, 0, 255),
			math.clamp(math.floor(surfaceCol.B * 255) + 12, 0, 255)
		)
	end

	sizeCard.BackgroundColor3 = surfaceCol
	sizeCardStroke.Color = accentCol
	sizeTitleLabel.TextColor3 = textCol
	sizeValueAboveLabel.TextColor3 = accentCol
	sizeInputBox.BackgroundColor3 = Color3.fromRGB(
		math.clamp(math.floor(surfaceCol.R * 255) + 10, 0, 255),
		math.clamp(math.floor(surfaceCol.G * 255) + 10, 0, 255),
		math.clamp(math.floor(surfaceCol.B * 255) + 14, 0, 255)
	)
	sizeInputBox.TextColor3 = textCol
	sizeInputStroke.Color = accentCol
	sliderFill.BackgroundColor3 = accentCol
	sliderKnob.BackgroundColor3 = textCol
	sliderKnobStroke.Color = accentCol
end)

local function applyLanguageState(lang)
	if lang ~= "TH" and lang ~= "EN" then return end
	currentLang = lang
	langCircleBtn.Text = currentLang
	if currentLang == "EN" then
		langCircleBtn.BackgroundColor3 = currentAccentColor
		langStroke.Transparency = 0
	else
		langCircleBtn.BackgroundColor3 = currentSurfaceColor
		langStroke.Transparency = 0.25
	end
	applyLanguageToAll()
end

-- ปุ่มเปิด/ปิด Anti-AFK ในแท็บ Setting
local antiAfkBtn = addButton(settingTab, "กันหลุด AFK", "Anti-AFK", function()
	setAntiAfkState(not antiAfkEnabled)
	applyFontSizeForLang(antiAfkBtn, 17, 16)
	antiAfkBtn.Text = L("กันหลุด AFK", "Anti-AFK") .. ": " .. (antiAfkEnabled and L("เปิด", "On") or L("ปิด", "Off"))
end)

local langSettingBtn = addButton(settingTab, "ภาษา", "Language", function()
	applyLanguageState(currentLang == "EN" and "TH" or "EN")
end)

local resetPosBtn = addButton(settingTab, "รีเซ็ตตำแหน่ง UI", "Reset UI Position", function(lang, btn)
	local size = mainFrame.AbsoluteSize
	mainFrame.Position = clampPositionToScreen(0.5, 0.5, size.X > 0 and size.X or 400, size.Y > 0 and size.Y or 350)
	if btn then
		local oldText = btn.Text
		btn.Text = "✓ " .. L("รีเซ็ตตำแหน่งแล้ว!", "UI position reset!")
		btn.BackgroundColor3 = currentAccentColor
		task.delay(1.4, function()
			if btn and btn.Parent then
				btn.Text = oldText
				btn.BackgroundColor3 = currentSurfaceColor
			end
		end)
	end
end)

local function refreshSettingButtons()
	applyFontSizeForLang(antiAfkBtn, 17, 16)
	antiAfkBtn.Text = L("กันหลุด AFK", "Anti-AFK") .. ": " .. (antiAfkEnabled and L("เปิด", "On") or L("ปิด", "Off"))

	applyFontSizeForLang(langSettingBtn, 17, 16)
	langSettingBtn.Text = L("ภาษา", "Language") .. ": " .. currentLang
end

table.insert(onLanguageChangedCallbacks, refreshProfileUI)
table.insert(onLanguageChangedCallbacks, refreshSettingButtons)

langCircleBtn.MouseButton1Click:Connect(function()
	applyLanguageState(currentLang == "EN" and "TH" or "EN")
end)

applyLanguageToAll()
refreshSettingButtons()

-- ==========================================
-- แอนิเมชันเปิด/ปิด Sidebar, ย่อ (–), ปิด (X)
-- ==========================================
menuBtn.MouseButton1Click:Connect(function()
	if minimized then return end
	sidebarOpen = not sidebarOpen
	local factor = uiScalePercent / 100

	if sidebarOpen then
		TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.fromScale(BASE_OPEN_WIDTH * factor, BASE_FRAME_HEIGHT * factor)}):Play()
		TweenService:Create(sidebar, tweenInfo, {Size = UDim2.new(SIDEBAR_SCALE, 0, 1, -TOPBAR_PX)}):Play()
		TweenService:Create(contentContainer, tweenInfo, {
			Size = UDim2.new(1 - SIDEBAR_SCALE, 0, 1, -TOPBAR_PX),
			Position = UDim2.new(SIDEBAR_SCALE, 0, 0, TOPBAR_PX)
		}):Play()
	else
		TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.fromScale(BASE_CLOSED_WIDTH * factor, BASE_FRAME_HEIGHT * factor)}):Play()
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
	local factor = uiScalePercent / 100
	local targetWidth = (sidebarOpen and BASE_OPEN_WIDTH or BASE_CLOSED_WIDTH) * factor
	local minScaleY = TOPBAR_PX / vp.Y

	if minimized then
		contentContainer.Visible = false
		sidebar.Visible = false
		bottomCover.Visible = false
		topLine.Visible = false
		TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.fromScale(targetWidth, minScaleY)}):Play()
		minBtn.Text = "+"
	else
		TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.fromScale(targetWidth, BASE_FRAME_HEIGHT * factor)}):Play()
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

getgenv().ToyHubAPI = {
	createTab = createTab,
	addButton = addButton,
	selectTab = selectTab,
	L = L,
	translateThEn = translateThEn,
	registerTranslatable = registerTranslatable,
	addDict = addDict,
	setLanguage = applyLanguageState,
	getLanguage = function()
		return currentLang
	end,
	setUiScale = function(pct)
		syncSizeControls(pct, true)
	end,
	setUiColor = applyExactRgbColor,
	resetUiColor = applyToyHubDefaultColor,
	setAntiAfk = function(enabled)
		setAntiAfkState(enabled)
		refreshSettingButtons()
	end,
	getAntiAfk = function()
		return antiAfkEnabled
	end,
}
