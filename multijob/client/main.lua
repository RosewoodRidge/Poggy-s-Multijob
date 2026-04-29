local jobs = {}
local currentJob = nil
local jobsReceived = false
local waitingForMenu = false

-- Request jobs on join - wait for character to fully load
Citizen.CreateThread(function()
    Citizen.Wait(8000) -- Wait for character to be fully loaded
    TriggerServerEvent('multijob:checkJobs')
end)

RegisterNetEvent('multijob:receiveJobs')
AddEventHandler('multijob:receiveJobs', function(serverJobs, serverCurrentJob)
    jobs = serverJobs or {}
    if serverCurrentJob then
        currentJob = serverCurrentJob
    end
    jobsReceived = true

    -- If menu was waiting to open, open it now
    if waitingForMenu then
        waitingForMenu = false
        OpenMultijobMenu(jobs, currentJob)
    end
end)

RegisterNetEvent('multijob:updateCurrentJob')
AddEventHandler('multijob:updateCurrentJob', function(job, label, grade)
    currentJob = {job = job, label = label, grade = grade}
end)

RegisterCommand(Config.Command, function()
    -- Request fresh jobs from server
    jobsReceived = false
    waitingForMenu = true
    TriggerServerEvent('multijob:checkJobs')

    -- Safety timeout: if server doesn't respond within 3 seconds, open with cached data
    Citizen.CreateThread(function()
        local waited = 0
        while waitingForMenu and waited < 3000 do
            Citizen.Wait(100)
            waited = waited + 100
        end
        if waitingForMenu then
            waitingForMenu = false
            if Config.Debug then print('[multijob] Server took too long, opening with cached jobs') end
            OpenMultijobMenu(jobs, currentJob)
        end
    end)
end)

RegisterCommand(Config.SwitchCommand, function(source, args)
    local jobIndex = tonumber(args[1])
    if not jobIndex then
        TriggerEvent('vorp:TipRight', 'Usage: /mj [job_number]', 4000)
        return
    end

    -- Use server-side quick switch (fetches fresh jobs and switches server-side)
    TriggerServerEvent('multijob:quickSwitch', jobIndex)
end)

-- Export to get cached jobs
exports('GetJobs', function()
    return jobs
end)

RegisterNetEvent('multijob:forceCheck')
AddEventHandler('multijob:forceCheck', function()
    TriggerServerEvent('multijob:checkJobs')
end)
