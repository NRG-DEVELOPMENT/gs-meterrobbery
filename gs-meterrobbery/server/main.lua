local QBCore = nil
local ESX = nil
local currentFramework = nil

local function InitializeFramework()
    if Config.Framework == 'auto' or Config.Framework == 'qb' then
        if GetResourceState('qb-core') ~= 'missing' then
            QBCore = exports['qb-core']:GetCoreObject()
            if QBCore then
                currentFramework = 'qb'
                return true
            end
        end
    end
    
    if Config.Framework == 'auto' or Config.Framework == 'esx' then
        if GetResourceState('es_extended') ~= 'missing' then
            ESX = exports['es_extended']:getSharedObject()
            if ESX then
                currentFramework = 'esx'
                return true
            end
        end
    end
    
    print('[gs-meterrobbery] No compatible framework found. Please install QBCore or ESX.')
    return false
end

local function GetPlayer(source)
    if currentFramework == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    elseif currentFramework == 'esx' then
        return ESX.GetPlayerFromId(source)
    end
    return nil
end

local function AddMoney(source, amount, type)
    local player = GetPlayer(source)
    if not player then return false end
    
    if currentFramework == 'qb' then
        player.Functions.AddMoney(type, amount)
        return true
    elseif currentFramework == 'esx' then
        if type == 'cash' then
            player.addMoney(amount)
            return true
        elseif type == 'bank' then
            player.addAccountMoney('bank', amount)
            return true
        elseif type == 'black_money' then
            player.addAccountMoney('black_money', amount)
            return true
        end
    end
    
    return false
end

local function AddItem(source, item, amount)
    local player = GetPlayer(source)
    if not player then return false end
    
    if currentFramework == 'qb' then
        player.Functions.AddItem(item, amount)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], 'add')
        return true
    elseif currentFramework == 'esx' then
        player.addInventoryItem(item, amount)
        return true
    end
    
    return false
end

local function RemoveItem(source, item, amount)
    local player = GetPlayer(source)
    if not player then return false end
    
    if currentFramework == 'qb' then
        player.Functions.RemoveItem(item, amount)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], 'remove')
        return true
    elseif currentFramework == 'esx' then
        player.removeInventoryItem(item, amount)
        return true
    end
    
    return false
end

local function HasItem(source, item, amount)
    local player = GetPlayer(source)
    if not player then return false end
    
    if currentFramework == 'qb' then
        local hasItem = player.Functions.GetItemByName(item)
        return hasItem and hasItem.amount >= amount
    elseif currentFramework == 'esx' then
        local hasItem = player.getInventoryItem(item)
        return hasItem and hasItem.count >= amount
    end
    
    return false
end

local function GetItemLabel(item)
    if currentFramework == 'qb' then
        return QBCore.Shared.Items[item] and QBCore.Shared.Items[item].label or item
    elseif currentFramework == 'esx' then
        local itemData = ESX.GetItems()[item]
        return itemData and itemData.label or item
    end
    
    return item
end

local function GenerateRewards(source)
    local rewards = {
        money = 0,
        items = {}
    }
    
    if Config.Rewards.money.enabled then
        rewards.money = math.random(Config.Rewards.money.minAmount, Config.Rewards.money.maxAmount)
    end
    
    if Config.Rewards.items.enabled then
        for _, item in pairs(Config.Rewards.items.possible) do
            local chance = math.random(1, 100)
            if chance <= item.chance then
                local amount = math.random(item.min, item.max)
                table.insert(rewards.items, {
                    name = item.name,
                    amount = amount,
                    label = GetItemLabel(item.name)
                })
            end
        end
    end
    
    return rewards
end

local function GiveRewards(source, rewards)
    if rewards.money > 0 then
        local moneyType = Config.Rewards.money.type
        if AddMoney(source, rewards.money, moneyType) then
            TriggerClientEvent('gs-meterrobbery:client:notify', source, 'success', _U('received_money', rewards.money))
        end
    end
    
    for _, item in pairs(rewards.items) do
        if AddItem(source, item.name, item.amount) then
            TriggerClientEvent('gs-meterrobbery:client:notify', source, 'success', _U('received_item', item.amount, item.label))
        end
    end
end

local function RemoveRequiredItems(source, isFailed)
    if not Config.RequiredItems.enabled then return end
    
    for _, item in pairs(Config.RequiredItems.items) do
        if item.remove then
            local removeChance = item.chance or 100
            local chance = math.random(1, 100)
            
            if isFailed then
                removeChance = removeChance + 20
            end
            
            if chance <= removeChance then
                RemoveItem(source, item.name, item.amount)
            end
        end
    end
end

local function CountPoliceOnline()
    local policeCount = 0
    
    if currentFramework == 'qb' then
        for _, jobName in ipairs(Config.Meters.police.jobs) do
            for _, player in pairs(QBCore.Functions.GetPlayers()) do
                local Player = QBCore.Functions.GetPlayer(player)
                if Player and Player.PlayerData.job.name == jobName and Player.PlayerData.job.onduty then
                    policeCount = policeCount + 1
                end
            end
        end
    elseif currentFramework == 'esx' then
        for _, jobName in ipairs(Config.Meters.police.jobs) do
            local players = ESX.GetExtendedPlayers('job', jobName)
            policeCount = policeCount + #players
        end
    end
    
    return policeCount
end

CreateThread(function()
    if not InitializeFramework() then return end
    
    if Config.Debug then
        print('[gs-meterrobbery] Server initialized with framework: ' .. currentFramework)
    end
end)

RegisterNetEvent('gs-meterrobbery:server:giveRewards', function()
    local source = source
    local rewards = GenerateRewards(source)
    GiveRewards(source, rewards)
end)

RegisterNetEvent('gs-meterrobbery:server:checkPoliceCount', function()
    local source = source
    local policeCount = CountPoliceOnline()
    TriggerClientEvent('gs-meterrobbery:client:receivePoliceCount', source, policeCount)
end)

RegisterNetEvent('gs-meterrobbery:server:removeItems', function(isFailed)
    local source = source
    RemoveRequiredItems(source, isFailed)
end)

RegisterNetEvent('gs-meterrobbery:server:notifyPolice', function(coords)
    local players = GetPlayers()
    for _, player in ipairs(players) do
        local playerSource = tonumber(player)
        local playerObj = GetPlayer(playerSource)
        
        if playerObj then
            local isPolice = false
            
            if currentFramework == 'qb' then
                isPolice = playerObj.PlayerData.job.name == 'police'
            elseif currentFramework == 'esx' then
                isPolice = playerObj.job.name == 'police'
            end
            
            if isPolice then
                TriggerClientEvent('gs-meterrobbery:client:policeAlert', playerSource, coords)
            end
        end
    end
end)

RegisterNetEvent('gs-meterrobbery:client:notify', function(type, message)
    if lib then
        lib.notify({
            title = _U('meter_robbery'),
            description = message,
            type = type
        })
    else
        if currentFramework == 'qb' then
            TriggerClientEvent('QBCore:Notify', source, message, type)
        elseif currentFramework == 'esx' then
            TriggerClientEvent('esx:showNotification', source, message)
        end
    end
end)

RegisterNetEvent('gs-meterrobbery:client:policeAlert', function(coords)
    if lib then
        lib.notify({
            title = _U('dispatch_title'),
            description = _U('dispatch_desc'),
            type = 'inform'
        })
    else
        if currentFramework == 'qb' then
            TriggerEvent('QBCore:Notify', _U('dispatch_desc'), 'inform')
        elseif currentFramework == 'esx' then
            TriggerEvent('esx:showNotification', _U('dispatch_desc'))
        end
    end
    
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 47)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(_U('meter_robbery'))
    EndTextCommandSetBlipName(blip)
    
    SetTimeout(60000, function()
        RemoveBlip(blip)
    end)
end)

CreateThread(function()
    Wait(5000)
    local resourceName = GetCurrentResourceName()
end)