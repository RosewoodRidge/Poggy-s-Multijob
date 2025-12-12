local jobs = {}
local currentJob = nil

-- Request jobs on join - increased wait for character to fully load
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Increased from 2000 to 5000
    TriggerServerEvent('multijob:checkJobs')
end)

RegisterNetEvent('multijob:receiveJobs')
AddEventHandler('multijob:receiveJobs', function(serverJobs)
    jobs = serverJobs
    -- If menu is open, refresh it (optional, requires menu state tracking)
end)

RegisterNetEvent('multijob:updateCurrentJob')
AddEventHandler('multijob:updateCurrentJob', function(job, label, grade)
    currentJob = {job = job, label = label, grade = grade}
end)

RegisterCommand(Config.Command, function()
    TriggerServerEvent('multijob:checkJobs')
    -- Small delay to allow jobs to fetch, though ideally we'd use a callback or event
    Citizen.Wait(200) 
    OpenMultijobMenu(jobs, currentJob)
end)

RegisterCommand(Config.SwitchCommand, function(source, args)
    local jobIndex = tonumber(args[1])
    if not jobIndex then
        TriggerEvent('vorp:TipRight', 'Usage: /mj [job_number]', 4000)
        return
    end
    
    if jobs and #jobs > 0 then
        if jobs[jobIndex] then
            TriggerServerEvent('multijob:switchJob', jobs[jobIndex].job)
        else
            TriggerEvent('vorp:TipRight', Locales['invalid_job'], 4000)
        end
    else
        TriggerEvent('vorp:TipRight', Locales['no_jobs'], 4000)
    end
end)

-- Export to get cached jobs
exports('GetJobs', function()
    return jobs
end)

RegisterNetEvent('multijob:forceCheck')
AddEventHandler('multijob:forceCheck', function()
    TriggerServerEvent('multijob:checkJobs')
end)
