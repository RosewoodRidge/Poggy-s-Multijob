local VORPcore = nil

-- Use exports for more reliable core access
Citizen.CreateThread(function()
    while VORPcore == nil do
        TriggerEvent("getCore", function(core)
            VORPcore = core
        end)
        Citizen.Wait(100)
    end
end)

-- Helper function to safely get character
local function GetCharacter(source)
    if not VORPcore then return nil end
    local User = VORPcore.getUser(source)
    if not User then return nil end
    local Character = User.getUsedCharacter
    if not Character then return nil end
    return Character
end

-- Helper to check if job is valid (not empty/unemployed/unknown)
local function IsValidJob(job)
    if not job or job == '' then return false end
    local lowerJob = string.lower(job)
    if lowerJob == 'unemployed' or lowerJob == 'unknown' or lowerJob == 'none' or lowerJob == '' then
        return false
    end
    return true
end

-- Helper to filter jobs list
local function FilterValidJobs(jobs)
    local filtered = {}
    for _, job in ipairs(jobs) do
        if IsValidJob(job.job) then
            table.insert(filtered, job)
        end
    end
    return filtered
end

-- Helper to get jobs from DB
local function GetPlayerJobs(cid, cb)
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {cid}, function(result)
        if result then
            cb(FilterValidJobs(result))
        else
            cb({})
        end
    end)
end

-- Helper to save job to DB
local function SaveJobToDB(cid, job, grade, label, firstname, lastname)
    -- Don't save invalid jobs
    if not IsValidJob(job) then return end
    if not cid then return end
    
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {cid, job}, function(result)
        if result and result[1] then
            MySQL.update('UPDATE marshal_multi_jobs SET jobgrade = ?, joblabel = ?, lastonline = ? WHERE cid = ? AND job = ?', 
            {grade, label or job, os.date('%Y-%m-%d %H:%M:%S'), cid, job})
        else
            MySQL.insert('INSERT INTO marshal_multi_jobs (cid, job, jobgrade, joblabel, firstname, lastname, lastonline) VALUES (?, ?, ?, ?, ?, ?, ?)', 
            {cid, job, grade, label or job, firstname or 'Unknown', lastname or 'Unknown', os.date('%Y-%m-%d %H:%M:%S')})
        end
    end)
end

-- Helper to remove job from DB
local function RemoveJobFromDB(cid, job)
    if not cid or not job then return end
    MySQL.execute('DELETE FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {cid, job})
end

-- Event to check/fetch jobs
RegisterServerEvent('multijob:checkJobs')
AddEventHandler('multijob:checkJobs', function()
    local _source = source
    local Character = GetCharacter(_source)
    if not Character then 
        print('[multijob] Character not loaded for source ' .. _source)
        return 
    end
    
    local cid = Character.charIdentifier
    if not cid then
        print('[multijob] No charIdentifier for source ' .. _source)
        return
    end
    
    local currentJob = Character.job
    local currentGrade = Character.jobGrade
    local currentLabel = Character.jobLabel or currentJob
    local firstname = Character.firstname
    local lastname = Character.lastname

    -- Save current job to DB first (only if valid)
    SaveJobToDB(cid, currentJob, currentGrade, currentLabel, firstname, lastname)

    -- Fetch all jobs
    GetPlayerJobs(cid, function(jobs)
        TriggerClientEvent('multijob:receiveJobs', _source, jobs)
    end)
end)

-- Event to switch job
RegisterServerEvent('multijob:switchJob')
AddEventHandler('multijob:switchJob', function(targetJob)
    local _source = source
    local Character = GetCharacter(_source)
    if not Character then return end
    
    local cid = Character.charIdentifier
    if not cid then return end
    
    local currentJob = Character.job
    local currentGrade = Character.jobGrade
    local currentLabel = Character.jobLabel or currentJob
    local firstname = Character.firstname
    local lastname = Character.lastname

    -- 1. Save current job to DB
    SaveJobToDB(cid, currentJob, currentGrade, currentLabel, firstname, lastname)

    -- 2. Get target job details from DB
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {cid, targetJob}, function(result)
        if result and result[1] then
            local newJob = result[1].job
            local newGrade = result[1].jobgrade
            local newLabel = result[1].joblabel

            -- 3. Set new job in VORP
            Character.setJob(newJob)
            Character.setJobGrade(newGrade)
            Character.setJobLabel(newLabel)
            
            TriggerClientEvent('vorp:TipRight', _source, string.format(Locales['job_switched'], newLabel), 4000)
            TriggerClientEvent('multijob:updateCurrentJob', _source, newJob, newLabel, newGrade)
            
            -- Refresh jobs list for client
            GetPlayerJobs(cid, function(jobs)
                TriggerClientEvent('multijob:receiveJobs', _source, jobs)
            end)
        else
            TriggerClientEvent('vorp:TipRight', _source, Locales['invalid_job'], 4000)
        end
    end)
end)

-- Event to quit job
RegisterServerEvent('multijob:quitJob')
AddEventHandler('multijob:quitJob', function(jobToQuit)
    local _source = source
    local Character = GetCharacter(_source)
    if not Character then return end
    
    local cid = Character.charIdentifier
    if not cid then return end
    
    local currentJob = Character.job

    if jobToQuit == currentJob then
        -- If quitting current job, set to unemployed
        Character.setJob(Config.DefaultJob)
        Character.setJobGrade(Config.DefaultGrade)
        Character.setJobLabel(Config.DefaultJobLabel)
        TriggerClientEvent('vorp:TipRight', _source, Locales['job_quitted'], 4000)
    end

    RemoveJobFromDB(cid, jobToQuit)

    GetPlayerJobs(cid, function(jobs)
        TriggerClientEvent('multijob:receiveJobs', _source, jobs)
    end)
end)

-- Event to quit all jobs
RegisterServerEvent('multijob:quitAllJobs')
AddEventHandler('multijob:quitAllJobs', function()
    local _source = source
    local Character = GetCharacter(_source)
    if not Character then return end
    
    local cid = Character.charIdentifier
    if not cid then return end

    -- Set to unemployed
    Character.setJob(Config.DefaultJob)
    Character.setJobGrade(Config.DefaultGrade)
    Character.setJobLabel(Config.DefaultJobLabel)

    -- Remove all jobs from DB
    MySQL.execute('DELETE FROM marshal_multi_jobs WHERE cid = ?', {cid})

    TriggerClientEvent('vorp:TipRight', _source, Locales['all_jobs_quitted'], 4000)
    TriggerClientEvent('multijob:receiveJobs', _source, {})
end)

-- Save on drop
AddEventHandler('playerDropped', function(reason)
    local _source = source
    local Character = GetCharacter(_source)
    if not Character then return end
    
    local cid = Character.charIdentifier
    if not cid then return end
    
    local currentJob = Character.job
    local currentGrade = Character.jobGrade
    local currentLabel = Character.jobLabel or currentJob
    local firstname = Character.firstname
    local lastname = Character.lastname

    SaveJobToDB(cid, currentJob, currentGrade, currentLabel, firstname, lastname)
end)
