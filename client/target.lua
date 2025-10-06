local targetInitialized = false
local meterModels = {}

local function InitializeTarget()
    local attempts = 0
    local maxAttempts = 100
    
    while attempts < maxAttempts do
        local models = exports['gs-meterrobbery']:GetMeterModels()
        if models and #models > 0 then
            meterModels = models
            break
        end
        Wait(100)
        attempts = attempts + 1
    end
    
    if #meterModels == 0 then
        print('[gs-meterrobbery] Failed to get meter models after ' .. maxAttempts .. ' attempts')
        return false
    end
    
    if Config.Target == 'ox' then
        InitializeOxTarget()
    elseif Config.Target == 'qb' then
        InitializeQBTarget()
    else
        print('[gs-meterrobbery] No compatible target system found.')
        return false
    end
    
    return true
end

function InitializeOxTarget()
    if GetResourceState('ox_target') == 'missing' then
        print('[gs-meterrobbery] ox_target not found.')
        return false
    end
    
    exports.ox_target:addModel(meterModels, {
        {
            name = 'gs_meter_robbery',
            icon = 'fas fa-coins',
            label = _U('rob_meter'),
            canInteract = function(entity, distance, coords, name, bone)
                if not IsEnoughPoliceOnline() then return false end
                
                return true
            end,
            onSelect = function(data)
                exports['gs-meterrobbery']:ProcessMeterRobbery(data.entity)
            end
        }
    })
    
    if Config.Debug then
        print('[gs-meterrobbery] ox_target initialized successfully.')
    end
    
    return true
end

function InitializeQBTarget()
    if GetResourceState('qb-target') == 'missing' then
        print('[gs-meterrobbery] qb-target not found.')
        return false
    end
    
    local modelHashes = {}
    for _, model in pairs(Config.Meters.models) do
        table.insert(modelHashes, model)
    end
    
    exports['qb-target']:AddTargetModel(modelHashes, {
        options = {
            {
                type = "client",
                icon = "fas fa-coins",
                label = _U('rob_meter'),
                action = function(entity)
                    exports['gs-meterrobbery']:ProcessMeterRobbery(entity)
                end,
                canInteract = function(entity, distance, data)
                    if not IsEnoughPoliceOnline() then return false end
                    
                    return true
                end,
            }
        },
        distance = Config.Meters.interactionDistance
    })
    
    if Config.Debug then
        print('[gs-meterrobbery] qb-target initialized successfully.')
    end
    
    return true
end

function IsEnoughPoliceOnline()
    return true
end

CreateThread(function()
    Wait(1000)
    
    targetInitialized = InitializeTarget()
    
    if Config.Debug and targetInitialized then
        print('[gs-meterrobbery] Target system initialized successfully.')
    end
end)