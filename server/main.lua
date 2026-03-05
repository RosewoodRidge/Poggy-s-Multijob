local VORPcore = nil

-- Use exports for reliable core access
Citizen.CreateThread(function()
    while VORPcore == nil do
        VORPcore = exports.vorp_core:GetCore()
        if VORPcore == nil then
            if Config.Debug then print('[multijob] Waiting for VORP Core...') end
            Citizen.Wait(1000)
        end
    end
    if Config.Debug then print('[multijob] VORP Core loaded successfully') end
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

-- Appends the permanent "unemployed" pseudo-job so players can always toggle their job off.
-- It is never stored in marshal_multi_jobs; it is injected at runtime only.
local function InjectUnemployed(jobs)
    local t = {}
    for _, j in ipairs(jobs) do table.insert(t, j) end
    table.insert(t, {job = 'unemployed', jobgrade = 0, joblabel = 'Unemployed', _virtual = true})
    return t
end

-- Helper to immediately persist job change to the characters table.
-- VORP's setJob/setJobGrade/setJobLabel only update in-memory state; the
-- characters table would otherwise not be updated until the next periodic save,
-- which means vorp_crafting (and anything else reading the DB) would see stale data.
local function PersistJobToCharacters(identifier, charIdentifier, job, jobgrade, joblabel)
    if not identifier or not charIdentifier then return end
    -- Store label exactly as given; blank labels stay blank (do NOT copy the job ID)
    local safeLabel = joblabel or ''
    MySQL.update(
        'UPDATE characters SET `job` = ?, `jobgrade` = ?, `joblabel` = ? WHERE `identifier` = ? AND `charidentifier` = ?',
        {job, jobgrade, safeLabel, identifier, charIdentifier}
    )
end

-- Event to check/fetch jobs
RegisterServerEvent('multijob:checkJobs')
AddEventHandler('multijob:checkJobs', function()
    local _source = source
    local Character = GetCharacter(_source)
    if not Character then 
        if Config.Debug then print('[multijob] Character not loaded for source ' .. _source) end
        TriggerClientEvent('multijob:receiveJobs', _source, {})
        return 
    end
    
    local cid = Character.charIdentifier
    if not cid then
        if Config.Debug then print('[multijob] No charIdentifier for source ' .. _source) end
        TriggerClientEvent('multijob:receiveJobs', _source, {})
        return
    end
    
    local currentJob = Character.job
    local currentGrade = Character.jobGrade
    local currentLabel = Character.jobLabel or currentJob
    local firstname = Character.firstname
    local lastname = Character.lastname

    -- Save current job to DB first (only if valid)
    SaveJobToDB(cid, currentJob, currentGrade, currentLabel, firstname, lastname)

    -- Fetch all jobs and always append the unemployed pseudo-job
    GetPlayerJobs(cid, function(jobs)
        -- Also send current job info so client knows which is active
        TriggerClientEvent('multijob:receiveJobs', _source, InjectUnemployed(jobs), {job = currentJob, label = currentLabel, grade = currentGrade})
    end)
end)

-- Event to quick-switch job by index (callback-style: fetches fresh jobs then switches)
RegisterServerEvent('multijob:quickSwitch')
AddEventHandler('multijob:quickSwitch', function(jobIndex)
    local _source = source
    local Character = GetCharacter(_source)
    if not Character then 
        TriggerClientEvent('vorp:TipRight', _source, 'Character not loaded', 4000)
        return 
    end

    local cid = Character.charIdentifier
    if not cid then 
        TriggerClientEvent('vorp:TipRight', _source, 'Character ID not found', 4000)
        return 
    end

    local currentJob = Character.job
    local currentGrade = Character.jobGrade
    local currentLabel = Character.jobLabel or currentJob
    local firstname = Character.firstname
    local lastname = Character.lastname

    -- Save current job first
    SaveJobToDB(cid, currentJob, currentGrade, currentLabel, firstname, lastname)

    -- Fetch fresh jobs from DB, then switch by index
    GetPlayerJobs(cid, function(jobs)
        if not jobs or #jobs == 0 then
            TriggerClientEvent('vorp:TipRight', _source, Locales['no_jobs'], 4000)
            return
        end

        -- Build list of OTHER jobs (exclude current)
        local otherJobs = {}
        for _, job in ipairs(jobs) do
            if job.job ~= currentJob then
                table.insert(otherJobs, job)
            end
        end
        -- Always offer unemployed as an option unless the player is already unemployed
        if string.lower(currentJob or '') ~= 'unemployed' then
            table.insert(otherJobs, {job = 'unemployed', jobgrade = 0, joblabel = 'Unemployed'})
        end

        if #otherJobs == 0 then
            TriggerClientEvent('vorp:TipRight', _source, Locales['no_jobs'], 4000)
            return
        end

        if not jobIndex or jobIndex < 1 or jobIndex > #otherJobs then
            TriggerClientEvent('vorp:TipRight', _source, Locales['invalid_job'] .. ' (1-' .. #otherJobs .. ')', 4000)
            return
        end

        local targetJob = otherJobs[jobIndex].job
        local targetGrade = otherJobs[jobIndex].jobgrade
        local targetLabel = otherJobs[jobIndex].joblabel

        -- Set new job
        Character.setJob(targetJob)
        Character.setJobGrade(targetGrade)
        Character.setJobLabel(targetLabel)

        -- Immediately persist to characters table so other resources (e.g. vorp_crafting) see the change
        PersistJobToCharacters(Character.identifier, Character.charIdentifier, targetJob, targetGrade, targetLabel)

        TriggerClientEvent('vorp:TipRight', _source, string.format(Locales['job_switched'], targetLabel), 4000)
        TriggerClientEvent('multijob:updateCurrentJob', _source, targetJob, targetLabel, targetGrade)

        -- Refresh jobs list for client
        GetPlayerJobs(cid, function(updatedJobs)
            TriggerClientEvent('multijob:receiveJobs', _source, InjectUnemployed(updatedJobs), {job = targetJob, label = targetLabel, grade = targetGrade})
        end)
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

    -- Special case: switching to unemployed doesn't require a DB lookup
    if string.lower(targetJob or '') == 'unemployed' then
        Character.setJob('unemployed')
        Character.setJobGrade(0)
        Character.setJobLabel('Unemployed')
        PersistJobToCharacters(Character.identifier, Character.charIdentifier, 'unemployed', 0, 'Unemployed')
        TriggerClientEvent('vorp:TipRight', _source, string.format(Locales['job_switched'], 'Unemployed'), 4000)
        TriggerClientEvent('multijob:updateCurrentJob', _source, 'unemployed', 'Unemployed', 0)
        GetPlayerJobs(cid, function(jobs)
            TriggerClientEvent('multijob:receiveJobs', _source, InjectUnemployed(jobs))
        end)
        return
    end

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

            -- Immediately persist to characters table so other resources (e.g. vorp_crafting) see the change
            PersistJobToCharacters(Character.identifier, Character.charIdentifier, newJob, newGrade, newLabel)
            
            TriggerClientEvent('vorp:TipRight', _source, string.format(Locales['job_switched'], newLabel), 4000)
            TriggerClientEvent('multijob:updateCurrentJob', _source, newJob, newLabel, newGrade)
            
            -- Refresh jobs list for client
            GetPlayerJobs(cid, function(jobs)
                TriggerClientEvent('multijob:receiveJobs', _source, InjectUnemployed(jobs))
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

    -- Unemployed is a virtual always-available option; it cannot be removed
    if string.lower(jobToQuit or '') == 'unemployed' then return end
    
    local currentJob = Character.job

    if jobToQuit == currentJob then
        -- If quitting current job, set to unemployed
        Character.setJob(Config.DefaultJob)
        Character.setJobGrade(Config.DefaultGrade)
        Character.setJobLabel(Config.DefaultJobLabel)
        -- Immediately persist unemployed status to characters table
        PersistJobToCharacters(Character.identifier, Character.charIdentifier, Config.DefaultJob, Config.DefaultGrade, Config.DefaultJobLabel)
        TriggerClientEvent('vorp:TipRight', _source, Locales['job_quitted'], 4000)
    end

    RemoveJobFromDB(cid, jobToQuit)

    GetPlayerJobs(cid, function(jobs)
        TriggerClientEvent('multijob:receiveJobs', _source, InjectUnemployed(jobs))
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
    -- Immediately persist unemployed status to characters table
    PersistJobToCharacters(Character.identifier, Character.charIdentifier, Config.DefaultJob, Config.DefaultGrade, Config.DefaultJobLabel)

    -- Remove all jobs from DB
    MySQL.execute('DELETE FROM marshal_multi_jobs WHERE cid = ?', {cid})

    TriggerClientEvent('vorp:TipRight', _source, Locales['all_jobs_quitted'], 4000)
    TriggerClientEvent('multijob:receiveJobs', _source, InjectUnemployed({}))
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
