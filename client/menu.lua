local MenuData = {}

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    TriggerEvent("vorp_menu:getData", function(cb)
        MenuData = cb
    end)
end)

-- Helper to check if job is valid for display
local function IsValidJobForDisplay(job)
    if not job or not job.job or job.job == '' then return false end
    local lowerJob = string.lower(job.job)
    if lowerJob == 'unemployed' or lowerJob == 'unknown' or lowerJob == 'none' or lowerJob == '' then
        return false
    end
    return true
end

function OpenMultijobMenu(jobs, currentJob)
    if not MenuData or not MenuData.Open then
        print("VORP Menu not loaded")
        return
    end

    MenuData.CloseAll()
    local elements = {}
    local displayIndex = 1

    for i, job in ipairs(jobs) do
        -- Only show valid jobs
        if IsValidJobForDisplay(job) then
            local label = string.format("%d. %s (Grade: %s)", displayIndex, job.joblabel or job.job, job.jobgrade or 0)
            if currentJob and currentJob.job == job.job then
                label = label .. " [CURRENT]"
            end
            
            table.insert(elements, {
                label = label,
                value = job.job,
                desc = string.format(Locales['switch_job'], job.joblabel or job.job)
            })
            displayIndex = displayIndex + 1
        end
    end

    -- Only show quit options if there are valid jobs
    if #elements > 0 then
        table.insert(elements, {
            label = Locales['quit_job'], 
            value = 'quit_current', 
            desc = Locales['quit_job']
        })

        table.insert(elements, {
            label = Locales['quit_all'], 
            value = 'quit_all', 
            desc = Locales['quit_all']
        })
    else
        table.insert(elements, {
            label = 'No jobs available',
            value = 'none',
            desc = 'You have no jobs to switch to'
        })
    end

    MenuData.Open('default', GetCurrentResourceName(), 'multijob_menu', {
        title = Locales['menu_title'],
        subtext = Locales['menu_subtitle'],
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value == 'none' then
            menu.close()
        elseif data.current.value == 'quit_all' then
            TriggerServerEvent('multijob:quitAllJobs')
            menu.close()
        elseif data.current.value == 'quit_current' then
            if currentJob then
                TriggerServerEvent('multijob:quitJob', currentJob.job)
            else
                TriggerEvent('vorp:TipRight', Locales['no_jobs'], 4000)
            end
            menu.close()
        else
            TriggerServerEvent('multijob:switchJob', data.current.value)
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end
