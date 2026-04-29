RegisterCommand('mjadmin', function()
    if Config.Debug then print('[multijob] Admin command triggered') end
    TriggerServerEvent('multijob:admin:openMenu')
end)

RegisterNetEvent('multijob:admin:showMenu')
AddEventHandler('multijob:admin:showMenu', function()
    if Config.Debug then print('[multijob] Showing admin menu') end
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'show',
        show = true,
        presets = Config.JobPresets
    })
    TriggerServerEvent('multijob:admin:getPlayers')
end)

RegisterNetEvent('multijob:admin:receivePlayers')
AddEventHandler('multijob:admin:receivePlayers', function(players)
    if Config.Debug then print('[multijob] Received ' .. #players .. ' players') end
    SendNUIMessage({
        type = 'updatePlayers',
        players = players
    })
end)

RegisterNetEvent('multijob:admin:receivePlayerJobs')
AddEventHandler('multijob:admin:receivePlayerJobs', function(jobs)
    if Config.Debug then print('[multijob] Received ' .. #jobs .. ' jobs for player') end
    SendNUIMessage({
        type = 'updatePlayerJobs',
        jobs = jobs
    })
end)

RegisterNUICallback('close', function(data, cb)
    if Config.Debug then print('[multijob] NUI close callback received') end
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'show',
        show = false
    })
    cb({ok = true})
end)

RegisterNUICallback('getPlayerJobs', function(data, cb)
    if Config.Debug then print('[multijob] NUI getPlayerJobs callback received for cid: ' .. tostring(data.cid)) end
    TriggerServerEvent('multijob:admin:getPlayerJobs', data.cid)
    cb({ok = true})
end)

RegisterNUICallback('refreshPlayers', function(data, cb)
    if Config.Debug then print('[multijob] NUI refreshPlayers callback received') end
    TriggerServerEvent('multijob:admin:getPlayers')
    cb({ok = true})
end)

RegisterNUICallback('switchPlayerJob', function(data, cb)
    if Config.Debug then print('[multijob] NUI switchPlayerJob callback received') end
    if Config.Debug then print('[multijob] Data: cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job)) end
    TriggerServerEvent('multijob:admin:switchPlayerJob', data.cid, data.job)
    cb({ok = true})
end)

RegisterNUICallback('removePlayerJob', function(data, cb)
    if Config.Debug then print('[multijob] NUI removePlayerJob callback received') end
    if Config.Debug then print('[multijob] Data: cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job)) end
    TriggerServerEvent('multijob:admin:removePlayerJob', data.cid, data.job)
    cb({ok = true})
end)

RegisterNUICallback('addJob', function(data, cb)
    if Config.Debug then print('[multijob] NUI addJob callback received') end
    if Config.Debug then print('[multijob] Data: cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job) .. ', label=' .. tostring(data.jobLabel) .. ', grade=' .. tostring(data.grade)) end
    TriggerServerEvent('multijob:admin:addJob', {
        cid = data.cid,
        job = data.job,
        jobLabel = data.jobLabel,
        grade = data.grade
    })
    cb({ok = true})
end)

RegisterNUICallback('updateJob', function(data, cb)
    if Config.Debug then print('[multijob] NUI updateJob callback received') end
    if Config.Debug then print('[multijob] Data: cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job) .. ', grade=' .. tostring(data.grade)) end
    if not data.cid or not data.job then
        if Config.Debug then print('[multijob] ERROR: Missing required data') end
        cb({ok = false, error = 'Missing data'})
        return
    end
    
    TriggerServerEvent('multijob:admin:updateJob', {
        cid = data.cid,
        job = data.job,
        jobLabel = data.jobLabel,
        grade = data.grade,
        oldJob = data.oldJob
    })
    
    cb({ok = true})
end)

-- All Jobs tab callbacks
RegisterNUICallback('getAllJobs', function(data, cb)
    if Config.Debug then print('[multijob] NUI getAllJobs callback received') end
    TriggerServerEvent('multijob:admin:getAllJobs')
    cb({ok = true})
end)

RegisterNUICallback('removeJobEntry', function(data, cb)
    if Config.Debug then print('[multijob] NUI removeJobEntry callback received') end
    if Config.Debug then print('[multijob] Data: cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job)) end
    TriggerServerEvent('multijob:admin:removeJobEntry', data.cid, data.job)
    cb({ok = true})
end)

RegisterNetEvent('multijob:admin:receiveAllJobs')
AddEventHandler('multijob:admin:receiveAllJobs', function(jobs)
    if Config.Debug then print('[multijob] Received ' .. #jobs .. ' total jobs for All Jobs tab') end
    SendNUIMessage({
        type = 'updateAllJobs',
        jobs = jobs
    })
end)

-- Add this near the top or when opening the UI
local resourceName = GetCurrentResourceName()

-- When opening/showing the NUI, send the resource name:
SendNUIMessage({
    action = "setResourceName",
    resourceName = resourceName
})
