RegisterCommand('mjadmin', function()
    print('[multijob] Admin command triggered')
    TriggerServerEvent('multijob:admin:openMenu')
end)

RegisterNetEvent('multijob:admin:showMenu')
AddEventHandler('multijob:admin:showMenu', function()
    print('[multijob] Showing admin menu')
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
    print('[multijob] Received ' .. #players .. ' players')
    SendNUIMessage({
        type = 'updatePlayers',
        players = players
    })
end)

RegisterNetEvent('multijob:admin:receivePlayerJobs')
AddEventHandler('multijob:admin:receivePlayerJobs', function(jobs)
    print('[multijob] Received ' .. #jobs .. ' jobs for player')
    SendNUIMessage({
        type = 'updatePlayerJobs',
        jobs = jobs
    })
end)

RegisterNUICallback('close', function(data, cb)
    print('[multijob] NUI close callback received')
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'show',
        show = false
    })
    cb({ok = true})
end)

RegisterNUICallback('getPlayerJobs', function(data, cb)
    print('[multijob] NUI getPlayerJobs callback received for cid: ' .. tostring(data.cid))
    TriggerServerEvent('multijob:admin:getPlayerJobs', data.cid)
    cb({ok = true})
end)

RegisterNUICallback('refreshPlayers', function(data, cb)
    print('[multijob] NUI refreshPlayers callback received')
    TriggerServerEvent('multijob:admin:getPlayers')
    cb({ok = true})
end)

RegisterNUICallback('switchPlayerJob', function(data, cb)
    print('[multijob] NUI switchPlayerJob callback received')
    print('[multijob] Data: cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job))
    TriggerServerEvent('multijob:admin:switchPlayerJob', data.cid, data.job)
    cb({ok = true})
end)

RegisterNUICallback('removePlayerJob', function(data, cb)
    print('[multijob] NUI removePlayerJob callback received')
    print('[multijob] Data: cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job))
    TriggerServerEvent('multijob:admin:removePlayerJob', data.cid, data.job)
    cb({ok = true})
end)

RegisterNUICallback('addJob', function(data, cb)
    print('[multijob] NUI addJob callback received')
    print('[multijob] Data: cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job) .. ', label=' .. tostring(data.jobLabel) .. ', grade=' .. tostring(data.grade))
    TriggerServerEvent('multijob:admin:addJob', {
        cid = data.cid,
        job = data.job,
        jobLabel = data.jobLabel,
        grade = data.grade
    })
    cb({ok = true})
end)

RegisterNUICallback('updateJob', function(data, cb)
    print('[multijob] NUI updateJob callback received')
    print('[multijob] Data: cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job) .. ', grade=' .. tostring(data.grade))
    
    if not data.cid or not data.job then
        print('[multijob] ERROR: Missing required data')
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
