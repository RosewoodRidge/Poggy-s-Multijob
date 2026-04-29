local VORPcore = nil

Citizen.CreateThread(function()
    while VORPcore == nil do
        VORPcore = exports.vorp_core:GetCore()
        if VORPcore == nil then
            if Config.Debug then print('[multijob] Admin: Waiting for VORP Core...') end
            Citizen.Wait(1000)
        end
    end
    if Config.Debug then print('[multijob] Admin: VORPcore loaded') end
end)

local function IsAdmin(source)
    if not VORPcore then return false end
    local User = VORPcore.getUser(source)
    if not User then return false end
    local group = User.getGroup
    for _, adminGroup in ipairs(Config.AdminGroups) do
        if group == adminGroup then
            return true
        end
    end
    return false
end

-- Helper function to fetch and send the player list to an admin (avoids TriggerEvent source issues)
local function FetchAndSendPlayerList(adminSource)
    if not VORPcore then return end

    MySQL.query('SELECT DISTINCT cid, firstname, lastname FROM marshal_multi_jobs ORDER BY firstname, lastname', {}, function(dbResult)
        local allPlayers = {}
        local onlineCids = {}

        for _, playerId in ipairs(GetPlayers()) do
            local User = VORPcore.getUser(tonumber(playerId))
            if User then
                local Character = User.getUsedCharacter
                if Character and Character.charIdentifier then
                    local firstname = Character.firstname or 'Unknown'
                    local lastname = Character.lastname or 'Unknown'
                    onlineCids[Character.charIdentifier] = true
                    table.insert(allPlayers, {
                        source = playerId,
                        charName = firstname .. ' ' .. lastname,
                        cid = Character.charIdentifier,
                        job = Character.job or 'unemployed',
                        jobLabel = Character.jobLabel or Character.job or 'Unemployed',
                        grade = Character.jobGrade or 0,
                        isOnline = true
                    })
                end
            end
        end

        if dbResult then
            for _, row in ipairs(dbResult) do
                if not onlineCids[row.cid] then
                    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ? ORDER BY lastonline DESC LIMIT 1', {row.cid}, function(jobResult)
                        if jobResult and jobResult[1] then
                            table.insert(allPlayers, {
                                source = nil,
                                charName = (row.firstname or 'Unknown') .. ' ' .. (row.lastname or 'Unknown'),
                                cid = row.cid,
                                job = jobResult[1].job or 'unemployed',
                                jobLabel = jobResult[1].joblabel or jobResult[1].job or 'Unemployed',
                                grade = jobResult[1].jobgrade or 0,
                                isOnline = false
                            })
                        end
                    end)
                end
            end
        end

        Wait(500)
        if Config.Debug then print('[multijob] Admin: Sending ' .. #allPlayers .. ' players to admin ' .. tostring(adminSource)) end
        TriggerClientEvent('multijob:admin:receivePlayers', adminSource, allPlayers)
    end)
end

-- Helper: notify an online player that their jobs list has changed
local function NotifyTargetPlayer(targetCid)
    if not VORPcore then return end
    for _, playerId in ipairs(GetPlayers()) do
        local User = VORPcore.getUser(tonumber(playerId))
        if User then
            local Character = User.getUsedCharacter
            if Character and Character.charIdentifier == targetCid then
                TriggerClientEvent('multijob:forceCheck', tonumber(playerId))
                return
            end
        end
    end
end

RegisterServerEvent('multijob:admin:openMenu')
AddEventHandler('multijob:admin:openMenu', function()
    local _source = source
    if Config.Debug then print('[multijob] Admin: openMenu triggered by source ' .. _source) end
    if IsAdmin(_source) then
        if Config.Debug then print('[multijob] Admin: User is admin, showing menu') end
        TriggerClientEvent('multijob:admin:showMenu', _source)
    else
        if Config.Debug then print('[multijob] Admin: User is NOT admin') end
        TriggerClientEvent('vorp:TipRight', _source, Locales['not_allowed'], 4000)
    end
end)

RegisterServerEvent('multijob:admin:getPlayers')
AddEventHandler('multijob:admin:getPlayers', function()
    local _source = source
    if Config.Debug then print('[multijob] Admin: getPlayers triggered by source ' .. _source) end
    if not IsAdmin(_source) then return end
    if not VORPcore then return end

    FetchAndSendPlayerList(_source)
end)

-- Get all jobs for a specific player (for admin panel)
RegisterServerEvent('multijob:admin:getPlayerJobs')
AddEventHandler('multijob:admin:getPlayerJobs', function(targetCid)
    local _source = source
    if Config.Debug then print('[multijob] Admin: getPlayerJobs triggered for cid ' .. tostring(targetCid)) end
    if not IsAdmin(_source) then return end
    
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {targetCid}, function(result)
        local jobs = result or {}
        if Config.Debug then print('[multijob] Admin: Found ' .. #jobs .. ' jobs for cid ' .. tostring(targetCid)) end
        TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, jobs)
    end)
end)

-- Switch a player's active job (admin action)
RegisterServerEvent('multijob:admin:switchPlayerJob')
AddEventHandler('multijob:admin:switchPlayerJob', function(targetCid, targetJob)
    local _source = source
    if Config.Debug then print('[multijob] Admin: switchPlayerJob triggered for cid ' .. tostring(targetCid) .. ' to job ' .. tostring(targetJob)) end
    if not IsAdmin(_source) then return end
    if not VORPcore then return end
    
    -- Get job details from database
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {targetCid, targetJob}, function(result)
        if result and result[1] then
            local jobData = result[1]
            
            -- Find online player and update their job
            for _, playerId in ipairs(GetPlayers()) do
                local User = VORPcore.getUser(tonumber(playerId))
                if User then
                    local Character = User.getUsedCharacter
                    if Character and Character.charIdentifier == targetCid then
                        if Config.Debug then print('[multijob] Admin: Switching player to job: ' .. jobData.job) end
                        Character.setJob(jobData.job)
                        Character.setJobGrade(jobData.jobgrade)
                        Character.setJobLabel(jobData.joblabel)
                        PersistJobToCharacters(Character.identifier, Character.charIdentifier, jobData.job, jobData.jobgrade, jobData.joblabel)
                        TriggerClientEvent('vorp:TipRight', tonumber(playerId), 'Your active job has been changed by an admin to: ' .. jobData.joblabel, 4000)
                        TriggerClientEvent('vorp:playerJobChange', tonumber(playerId))
                        TriggerClientEvent('multijob:forceCheck', tonumber(playerId))
                        break
                    end
                end
            end
            
            TriggerClientEvent('vorp:TipRight', _source, 'Player job switched successfully', 4000)
            
            -- Refresh admin's player list and target player's jobs
            Wait(300)
            FetchAndSendPlayerList(_source)
            MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {targetCid}, function(updatedJobs)
                TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, updatedJobs or {})
            end)
        else
            TriggerClientEvent('vorp:TipRight', _source, 'Job not found in database', 4000)
        end
    end)
end)

-- Remove a job from a player (admin action)
RegisterServerEvent('multijob:admin:removePlayerJob')
AddEventHandler('multijob:admin:removePlayerJob', function(targetCid, targetJob)
    local _source = source
    if Config.Debug then print('[multijob] Admin: removePlayerJob triggered for cid ' .. tostring(targetCid) .. ', job ' .. tostring(targetJob)) end
    if not IsAdmin(_source) then return end
    
    MySQL.execute('DELETE FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {targetCid, targetJob}, function(affectedRows)
        if Config.Debug then print('[multijob] Admin: Deleted ' .. tostring(affectedRows) .. ' job entries') end
        TriggerClientEvent('vorp:TipRight', _source, 'Job removed from player', 4000)
        
        -- If the removed job was the player's current active job, set them to unemployed
        if VORPcore then
            for _, playerId in ipairs(GetPlayers()) do
                local User = VORPcore.getUser(tonumber(playerId))
                if User then
                    local Character = User.getUsedCharacter
                    if Character and Character.charIdentifier == targetCid then
                        if Character.job == targetJob then
                            Character.setJob('unemployed')
                            Character.setJobGrade(0)
                            Character.setJobLabel('Unemployed')
                            PersistJobToCharacters(Character.identifier, Character.charIdentifier, 'unemployed', 0, 'Unemployed')
                            TriggerClientEvent('vorp:TipRight', tonumber(playerId), 'Your job has been removed by an admin', 4000)
                            TriggerClientEvent('vorp:playerJobChange', tonumber(playerId))
                        end
                        TriggerClientEvent('multijob:forceCheck', tonumber(playerId))
                        break
                    end
                end
            end
        end
        
        -- Send updated jobs list
        MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {targetCid}, function(result)
            TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, result or {})
        end)
    end)
end)

-- Add a new job to a player (admin action)
RegisterServerEvent('multijob:admin:addJob')
AddEventHandler('multijob:admin:addJob', function(data)
    local _source = source
    if Config.Debug then print('[multijob] Admin: addJob triggered') end
    if Config.Debug then print('[multijob] Admin: Data - cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job) .. ', label=' .. tostring(data.jobLabel) .. ', grade=' .. tostring(data.grade)) end
    if not IsAdmin(_source) then 
        if Config.Debug then print('[multijob] Admin: User is not admin') end
        return 
    end
    if not VORPcore then 
        if Config.Debug then print('[multijob] Admin: VORPcore not loaded') end
        return 
    end
    
    local targetCid = data.cid
    local newJob = data.job
    -- Preserve blank labels as empty string; do NOT fall back to the job ID
    local newLabel = (data.jobLabel ~= nil) and data.jobLabel or ''
    local newGrade = tonumber(data.grade) or 0
    
    if not targetCid or not newJob then
        if Config.Debug then print('[multijob] Admin: Missing cid or job') end
        TriggerClientEvent('vorp:TipRight', _source, 'Missing job data', 4000)
        return
    end
    
    if Config.Debug then print('[multijob] Admin: Checking if job exists for cid=' .. tostring(targetCid) .. ', job=' .. tostring(newJob)) end
    -- Check if job already exists
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {targetCid, newJob}, function(result)
        if Config.Debug then print('[multijob] Admin: Query result - found ' .. tostring(result and #result or 0) .. ' existing entries') end
        if result and result[1] then
            -- Update existing
            if Config.Debug then print('[multijob] Admin: Job exists, updating...') end
            MySQL.update('UPDATE marshal_multi_jobs SET jobgrade = ?, joblabel = ?, lastonline = ? WHERE cid = ? AND job = ?', 
            {newGrade, newLabel, os.date('%Y-%m-%d %H:%M:%S'), targetCid, newJob}, function(rowsAffected)
                if Config.Debug then print('[multijob] Admin: Updated ' .. tostring(rowsAffected) .. ' rows') end
                TriggerClientEvent('vorp:TipRight', _source, 'Job updated for player', 4000)
                
                -- Send updated jobs list
                MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {targetCid}, function(jobs)
                    if Config.Debug then print('[multijob] Admin: Sending ' .. tostring(jobs and #jobs or 0) .. ' jobs to client') end
                    TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, jobs or {})
                end)
                -- Notify target player so their cached jobs update
                NotifyTargetPlayer(targetCid)
            end)
        else
            -- Get player name for new entry
            local firstname = 'Unknown'
            local lastname = 'Player'
            
            -- First try to get name from existing database entries for this cid
            MySQL.query('SELECT firstname, lastname FROM marshal_multi_jobs WHERE cid = ? LIMIT 1', {targetCid}, function(nameResult)
                if nameResult and nameResult[1] then
                    firstname = nameResult[1].firstname or 'Unknown'
                    lastname = nameResult[1].lastname or 'Player'
                else
                    -- Try to get actual name from online player
                    for _, playerId in ipairs(GetPlayers()) do
                        local User = VORPcore.getUser(tonumber(playerId))
                        if User then
                            local Character = User.getUsedCharacter
                            if Character and Character.charIdentifier == targetCid then
                                firstname = Character.firstname or 'Unknown'
                                lastname = Character.lastname or 'Player'
                                break
                            end
                        end
                    end
                end
                
                if Config.Debug then print('[multijob] Admin: Inserting new job - cid=' .. tostring(targetCid) .. ', job=' .. tostring(newJob) .. ', grade=' .. tostring(newGrade) .. ', label=' .. tostring(newLabel) .. ', name=' .. firstname .. ' ' .. lastname) end
                -- Insert new
                MySQL.insert('INSERT INTO marshal_multi_jobs (cid, job, jobgrade, joblabel, firstname, lastname, lastonline) VALUES (?, ?, ?, ?, ?, ?, ?)', 
                {targetCid, newJob, newGrade, newLabel, firstname, lastname, os.date('%Y-%m-%d %H:%M:%S')}, function(insertId)
                    if Config.Debug then print('[multijob] Admin: Inserted new job with id ' .. tostring(insertId)) end
                    TriggerClientEvent('vorp:TipRight', _source, 'Job added to player', 4000)
                    
                    -- Send updated jobs list
                    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {targetCid}, function(jobs)
                        if Config.Debug then print('[multijob] Admin: Sending ' .. tostring(jobs and #jobs or 0) .. ' jobs to client after insert') end
                        TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, jobs or {})
                    end)
                    -- Notify target player so their cached jobs update
                    NotifyTargetPlayer(targetCid)
                end)
            end)
        end
    end)
end)

RegisterServerEvent('multijob:admin:updateJob')
AddEventHandler('multijob:admin:updateJob', function(data)
    local _source = source
    if Config.Debug then print('[multijob] Admin: updateJob triggered by source ' .. _source) end
    if Config.Debug then print('[multijob] Admin: Data received - cid: ' .. tostring(data.cid) .. ', job: ' .. tostring(data.job) .. ', grade: ' .. tostring(data.grade)) end
    if not IsAdmin(_source) then 
        if Config.Debug then print('[multijob] Admin: User is not admin, rejecting') end
        return 
    end
    if not VORPcore then 
        if Config.Debug then print('[multijob] Admin: VORPcore not loaded') end
        return 
    end

    local targetCid = data.cid
    local newJob = data.job
    -- Preserve blank labels as empty string; do NOT fall back to the job ID
    local newLabel = (data.jobLabel ~= nil) and data.jobLabel or ''
    local newGrade = tonumber(data.grade) or 0
    local oldJob = data.oldJob or newJob -- Default oldJob to newJob if not provided

    if not targetCid or not newJob then
        if Config.Debug then print('[multijob] Admin: Missing required data') end
        TriggerClientEvent('vorp:TipRight', _source, Locales['admin_error'], 4000)
        return
    end

    if Config.Debug then print('[multijob] Admin: Processing job update for cid ' .. targetCid) end
    -- First, check if this player has the old job in the database
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {targetCid, oldJob}, function(result)
        if result and result[1] then
            if Config.Debug then print('[multijob] Admin: Found existing job entry for old job: ' .. tostring(oldJob)) end
            if oldJob ~= newJob then
                -- Job name changed - update the entry
                if Config.Debug then print('[multijob] Admin: Job name changed from ' .. tostring(oldJob) .. ' to ' .. newJob) end
                MySQL.update('UPDATE marshal_multi_jobs SET job = ?, jobgrade = ?, joblabel = ?, lastonline = ? WHERE cid = ? AND job = ?', 
                {newJob, newGrade, newLabel, os.date('%Y-%m-%d %H:%M:%S'), targetCid, oldJob}, function(affectedRows)
                    if Config.Debug then print('[multijob] Admin: Updated ' .. tostring(affectedRows) .. ' rows') end
                end)
            else
                -- Same job name, just update grade/label
                if Config.Debug then print('[multijob] Admin: Updating grade/label for job: ' .. newJob) end
                MySQL.update('UPDATE marshal_multi_jobs SET jobgrade = ?, joblabel = ?, lastonline = ? WHERE cid = ? AND job = ?', 
                {newGrade, newLabel, os.date('%Y-%m-%d %H:%M:%S'), targetCid, newJob}, function(affectedRows)
                    if Config.Debug then print('[multijob] Admin: Updated ' .. tostring(affectedRows) .. ' rows') end
                end)
            end
        else
            -- No existing entry found for oldJob, check if the new job already exists (avoid duplicate key)
            MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {targetCid, newJob}, function(existingResult)
                if existingResult and existingResult[1] then
                    -- Job already exists under the new name, just update it
                    if Config.Debug then print('[multijob] Admin: Job already exists under new name, updating: ' .. newJob) end
                    MySQL.update('UPDATE marshal_multi_jobs SET jobgrade = ?, joblabel = ?, lastonline = ? WHERE cid = ? AND job = ?', 
                    {newGrade, newLabel, os.date('%Y-%m-%d %H:%M:%S'), targetCid, newJob}, function(affectedRows)
                        if Config.Debug then print('[multijob] Admin: Updated ' .. tostring(affectedRows) .. ' rows') end
                    end)
                else
                    -- Truly new entry, safe to insert
                    if Config.Debug then print('[multijob] Admin: No existing entry found, inserting new job: ' .. newJob) end
                    MySQL.insert('INSERT INTO marshal_multi_jobs (cid, job, jobgrade, joblabel, firstname, lastname, lastonline) VALUES (?, ?, ?, ?, ?, ?, ?)', 
                    {targetCid, newJob, newGrade, newLabel, 'Admin', 'Added', os.date('%Y-%m-%d %H:%M:%S')}, function(insertId)
                        if Config.Debug then print('[multijob] Admin: Inserted new row with id ' .. tostring(insertId)) end
                    end)
                end
            end)
        end
    end)

    -- Update online player's active job if they're online
    for _, playerId in ipairs(GetPlayers()) do
        local User = VORPcore.getUser(tonumber(playerId))
        if User then
            local Character = User.getUsedCharacter
            if Character and Character.charIdentifier == targetCid then
                if Config.Debug then print('[multijob] Admin: Found online player, updating their active job') end
                if Config.Debug then print('[multijob] Admin: Setting job=' .. newJob .. ', grade=' .. newGrade .. ', label=' .. newLabel) end
                if not oldJob or Character.job == oldJob then
                    Character.setJob(newJob)
                    Character.setJobGrade(newGrade)
                    Character.setJobLabel(newLabel)
                    PersistJobToCharacters(Character.identifier, Character.charIdentifier, newJob, newGrade, newLabel)
                    TriggerClientEvent('vorp:TipRight', tonumber(playerId), 'Your job has been updated by an admin', 4000)
                    TriggerClientEvent('vorp:playerJobChange', tonumber(playerId))
                    TriggerClientEvent('multijob:forceCheck', tonumber(playerId))
                end
                break
            end
        end
    end
    
    TriggerClientEvent('vorp:TipRight', _source, Locales['admin_updated'], 4000)
    
    -- Refresh the admin's player list and jobs
    Wait(500) -- Small delay to let DB update complete
    FetchAndSendPlayerList(_source)
    
    -- Send updated jobs list
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {targetCid}, function(jobs)
        TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, jobs or {})
    end)
end)

-- Get ALL jobs from database for the All Jobs tab
RegisterServerEvent('multijob:admin:getAllJobs')
AddEventHandler('multijob:admin:getAllJobs', function()
    local _source = source
    if Config.Debug then print('[multijob] Admin: getAllJobs triggered by source ' .. _source) end
    if not IsAdmin(_source) then return end
    
    MySQL.query('SELECT * FROM marshal_multi_jobs ORDER BY firstname, lastname, job', {}, function(result)
        local jobs = result or {}
        if Config.Debug then print('[multijob] Admin: Found ' .. #jobs .. ' total jobs in database') end
        TriggerClientEvent('multijob:admin:receiveAllJobs', _source, jobs)
    end)
end)

-- Remove a specific job entry from the database (for All Players tab)
RegisterServerEvent('multijob:admin:removeJobEntry')
AddEventHandler('multijob:admin:removeJobEntry', function(targetCid, targetJob)
    local _source = source
    if Config.Debug then print('[multijob] Admin: removeJobEntry triggered for cid=' .. tostring(targetCid) .. ', job=' .. tostring(targetJob)) end
    if not IsAdmin(_source) then return end
    
    -- Delete the job entry from the database
    MySQL.query('DELETE FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {targetCid, targetJob}, function(result)
        local rowsDeleted = result and result.affectedRows or 0
        if Config.Debug then print('[multijob] Admin: Deleted ' .. tostring(rowsDeleted) .. ' job entries') end
        -- Update online player if applicable - set them to unemployed if this was their active job
        for _, playerId in ipairs(GetPlayers()) do
            local User = VORPcore.getUser(tonumber(playerId))
            if User then
                local Character = User.getUsedCharacter
                if Character and Character.charIdentifier == targetCid and Character.job == targetJob then
                    Character.setJob('unemployed')
                    Character.setJobGrade(0)
                    Character.setJobLabel('Unemployed')
                    TriggerClientEvent('vorp:TipRight', tonumber(playerId), 'Your job has been removed by an admin', 4000)
                    TriggerClientEvent('vorp:playerJobChange', tonumber(playerId))
                    TriggerClientEvent('multijob:forceCheck', tonumber(playerId))
                    break
                end
            end
        end
        
        TriggerClientEvent('vorp:TipRight', _source, 'Job removed successfully', 4000)
        
        -- Refresh the all jobs list by querying and sending back to client
        MySQL.query('SELECT * FROM marshal_multi_jobs ORDER BY firstname, lastname, job', {}, function(refreshResult)
            local refreshedJobs = refreshResult or {}
            TriggerClientEvent('multijob:admin:receiveAllJobs', _source, refreshedJobs)
        end)
    end)
end)
