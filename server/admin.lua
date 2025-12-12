local VORPcore = nil

Citizen.CreateThread(function()
    while VORPcore == nil do
        TriggerEvent("getCore", function(core)
            VORPcore = core
        end)
        Citizen.Wait(100)
    end
    print('[multijob] Admin: VORPcore loaded')
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

RegisterServerEvent('multijob:admin:openMenu')
AddEventHandler('multijob:admin:openMenu', function()
    local _source = source
    print('[multijob] Admin: openMenu triggered by source ' .. _source)
    if IsAdmin(_source) then
        print('[multijob] Admin: User is admin, showing menu')
        TriggerClientEvent('multijob:admin:showMenu', _source)
    else
        print('[multijob] Admin: User is NOT admin')
        TriggerClientEvent('vorp:TipRight', _source, Locales['not_allowed'], 4000)
    end
end)

RegisterServerEvent('multijob:admin:getPlayers')
AddEventHandler('multijob:admin:getPlayers', function()
    local _source = source
    print('[multijob] Admin: getPlayers triggered by source ' .. _source)
    if not IsAdmin(_source) then return end
    if not VORPcore then return end

    -- Get all characters from database who have multijobs
    MySQL.query('SELECT DISTINCT cid, firstname, lastname FROM marshal_multi_jobs ORDER BY firstname, lastname', {}, function(dbResult)
        local allPlayers = {}
        local onlineCids = {}
        
        -- First, collect all online players
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
        
        -- Then add offline players from database
        if dbResult then
            for _, row in ipairs(dbResult) do
                if not onlineCids[row.cid] then
                    -- Get their current job from the database
                    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ? ORDER BY lastonline DESC LIMIT 1', {row.cid}, function(jobResult)
                        if jobResult and jobResult[1] then
                            local firstname = row.firstname or 'Unknown'
                            local lastname = row.lastname or 'Unknown'
                            table.insert(allPlayers, {
                                source = nil,
                                charName = firstname .. ' ' .. lastname,
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
        
        -- Wait a bit for async queries to complete, then send
        Wait(500)
        print('[multijob] Admin: Sending ' .. #allPlayers .. ' players to client')
        TriggerClientEvent('multijob:admin:receivePlayers', _source, allPlayers)
    end)
end)

-- Get all jobs for a specific player (for admin panel)
RegisterServerEvent('multijob:admin:getPlayerJobs')
AddEventHandler('multijob:admin:getPlayerJobs', function(targetCid)
    local _source = source
    print('[multijob] Admin: getPlayerJobs triggered for cid ' .. tostring(targetCid))
    if not IsAdmin(_source) then return end
    
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {targetCid}, function(result)
        local jobs = result or {}
        print('[multijob] Admin: Found ' .. #jobs .. ' jobs for cid ' .. tostring(targetCid))
        TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, jobs)
    end)
end)

-- Switch a player's active job (admin action)
RegisterServerEvent('multijob:admin:switchPlayerJob')
AddEventHandler('multijob:admin:switchPlayerJob', function(targetCid, targetJob)
    local _source = source
    print('[multijob] Admin: switchPlayerJob triggered for cid ' .. tostring(targetCid) .. ' to job ' .. tostring(targetJob))
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
                        print('[multijob] Admin: Switching player to job: ' .. jobData.job)
                        Character.setJob(jobData.job)
                        Character.setJobGrade(jobData.jobgrade)
                        Character.setJobLabel(jobData.joblabel)
                        TriggerClientEvent('vorp:TipRight', tonumber(playerId), 'Your active job has been changed by an admin to: ' .. jobData.joblabel, 4000)
                        TriggerClientEvent('multijob:forceCheck', tonumber(playerId))
                        break
                    end
                end
            end
            
            TriggerClientEvent('vorp:TipRight', _source, 'Player job switched successfully', 4000)
            
            -- Refresh admin's player list
            Wait(300)
            TriggerEvent('multijob:admin:getPlayers')
            TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, result)
        else
            TriggerClientEvent('vorp:TipRight', _source, 'Job not found in database', 4000)
        end
    end)
end)

-- Remove a job from a player (admin action)
RegisterServerEvent('multijob:admin:removePlayerJob')
AddEventHandler('multijob:admin:removePlayerJob', function(targetCid, targetJob)
    local _source = source
    print('[multijob] Admin: removePlayerJob triggered for cid ' .. tostring(targetCid) .. ', job ' .. tostring(targetJob))
    if not IsAdmin(_source) then return end
    
    MySQL.execute('DELETE FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {targetCid, targetJob}, function(affectedRows)
        print('[multijob] Admin: Deleted ' .. tostring(affectedRows) .. ' job entries')
        TriggerClientEvent('vorp:TipRight', _source, 'Job removed from player', 4000)
        
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
    print('[multijob] Admin: addJob triggered')
    print('[multijob] Admin: Data - cid=' .. tostring(data.cid) .. ', job=' .. tostring(data.job) .. ', label=' .. tostring(data.jobLabel) .. ', grade=' .. tostring(data.grade))
    
    if not IsAdmin(_source) then 
        print('[multijob] Admin: User is not admin')
        return 
    end
    if not VORPcore then 
        print('[multijob] Admin: VORPcore not loaded')
        return 
    end
    
    local targetCid = data.cid
    local newJob = data.job
    local newLabel = data.jobLabel or newJob
    local newGrade = tonumber(data.grade) or 0
    
    if not targetCid or not newJob then
        print('[multijob] Admin: Missing cid or job')
        TriggerClientEvent('vorp:TipRight', _source, 'Missing job data', 4000)
        return
    end
    
    print('[multijob] Admin: Checking if job exists for cid=' .. tostring(targetCid) .. ', job=' .. tostring(newJob))
    
    -- Check if job already exists
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {targetCid, newJob}, function(result)
        print('[multijob] Admin: Query result - found ' .. tostring(result and #result or 0) .. ' existing entries')
        
        if result and result[1] then
            -- Update existing
            print('[multijob] Admin: Job exists, updating...')
            MySQL.update('UPDATE marshal_multi_jobs SET jobgrade = ?, joblabel = ?, lastonline = ? WHERE cid = ? AND job = ?', 
            {newGrade, newLabel, os.date('%Y-%m-%d %H:%M:%S'), targetCid, newJob}, function(rowsAffected)
                print('[multijob] Admin: Updated ' .. tostring(rowsAffected) .. ' rows')
                TriggerClientEvent('vorp:TipRight', _source, 'Job updated for player', 4000)
                
                -- Send updated jobs list
                MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {targetCid}, function(jobs)
                    print('[multijob] Admin: Sending ' .. tostring(jobs and #jobs or 0) .. ' jobs to client')
                    TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, jobs or {})
                end)
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
                
                print('[multijob] Admin: Inserting new job - cid=' .. tostring(targetCid) .. ', job=' .. tostring(newJob) .. ', grade=' .. tostring(newGrade) .. ', label=' .. tostring(newLabel) .. ', name=' .. firstname .. ' ' .. lastname)
                
                -- Insert new
                MySQL.insert('INSERT INTO marshal_multi_jobs (cid, job, jobgrade, joblabel, firstname, lastname, lastonline) VALUES (?, ?, ?, ?, ?, ?, ?)', 
                {targetCid, newJob, newGrade, newLabel, firstname, lastname, os.date('%Y-%m-%d %H:%M:%S')}, function(insertId)
                    print('[multijob] Admin: Inserted new job with id ' .. tostring(insertId))
                    TriggerClientEvent('vorp:TipRight', _source, 'Job added to player', 4000)
                    
                    -- Send updated jobs list
                    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {targetCid}, function(jobs)
                        print('[multijob] Admin: Sending ' .. tostring(jobs and #jobs or 0) .. ' jobs to client after insert')
                        TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, jobs or {})
                    end)
                end)
            end)
        end
    end)
end)

RegisterServerEvent('multijob:admin:updateJob')
AddEventHandler('multijob:admin:updateJob', function(data)
    local _source = source
    print('[multijob] Admin: updateJob triggered by source ' .. _source)
    print('[multijob] Admin: Data received - cid: ' .. tostring(data.cid) .. ', job: ' .. tostring(data.job) .. ', grade: ' .. tostring(data.grade))
    
    if not IsAdmin(_source) then 
        print('[multijob] Admin: User is not admin, rejecting')
        return 
    end
    if not VORPcore then 
        print('[multijob] Admin: VORPcore not loaded')
        return 
    end

    local targetCid = data.cid
    local newJob = data.job
    local newLabel = data.jobLabel or newJob
    local newGrade = tonumber(data.grade) or 0
    local oldJob = data.oldJob

    if not targetCid or not newJob then
        print('[multijob] Admin: Missing required data')
        TriggerClientEvent('vorp:TipRight', _source, Locales['admin_error'], 4000)
        return
    end

    print('[multijob] Admin: Processing job update for cid ' .. targetCid)

    -- First, check if this player has the old job in the database
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {targetCid, oldJob}, function(result)
        if result and result[1] then
            print('[multijob] Admin: Found existing job entry for old job: ' .. tostring(oldJob))
            
            if oldJob ~= newJob then
                -- Job name changed - update the entry
                print('[multijob] Admin: Job name changed from ' .. tostring(oldJob) .. ' to ' .. newJob)
                MySQL.update('UPDATE marshal_multi_jobs SET job = ?, jobgrade = ?, joblabel = ?, lastonline = ? WHERE cid = ? AND job = ?', 
                {newJob, newGrade, newLabel, os.date('%Y-%m-%d %H:%M:%S'), targetCid, oldJob}, function(affectedRows)
                    print('[multijob] Admin: Updated ' .. tostring(affectedRows) .. ' rows')
                end)
            else
                -- Same job name, just update grade/label
                print('[multijob] Admin: Updating grade/label for job: ' .. newJob)
                MySQL.update('UPDATE marshal_multi_jobs SET jobgrade = ?, joblabel = ?, lastonline = ? WHERE cid = ? AND job = ?', 
                {newGrade, newLabel, os.date('%Y-%m-%d %H:%M:%S'), targetCid, newJob}, function(affectedRows)
                    print('[multijob] Admin: Updated ' .. tostring(affectedRows) .. ' rows')
                end)
            end
        else
            -- No existing entry, insert new one
            print('[multijob] Admin: No existing entry found, inserting new job: ' .. newJob)
            MySQL.insert('INSERT INTO marshal_multi_jobs (cid, job, jobgrade, joblabel, firstname, lastname, lastonline) VALUES (?, ?, ?, ?, ?, ?, ?)', 
            {targetCid, newJob, newGrade, newLabel, 'Admin', 'Added', os.date('%Y-%m-%d %H:%M:%S')}, function(insertId)
                print('[multijob] Admin: Inserted new row with id ' .. tostring(insertId))
            end)
        end
    end)

    -- Update online player's active job if they're online
    for _, playerId in ipairs(GetPlayers()) do
        local User = VORPcore.getUser(tonumber(playerId))
        if User then
            local Character = User.getUsedCharacter
            if Character and Character.charIdentifier == targetCid then
                print('[multijob] Admin: Found online player, updating their active job')
                print('[multijob] Admin: Setting job=' .. newJob .. ', grade=' .. newGrade .. ', label=' .. newLabel)
                if not oldJob or Character.job == oldJob then
                    Character.setJob(newJob)
                    Character.setJobGrade(newGrade)
                    Character.setJobLabel(newLabel)
                    TriggerClientEvent('vorp:TipRight', tonumber(playerId), 'Your job has been updated by an admin', 4000)
                    TriggerClientEvent('multijob:forceCheck', tonumber(playerId))
                end
                break
            end
        end
    end
    
    TriggerClientEvent('vorp:TipRight', _source, Locales['admin_updated'], 4000)
    
    -- Refresh the admin's player list and jobs
    Wait(500) -- Small delay to let DB update complete
    TriggerEvent('multijob:admin:getPlayers')
    
    -- Send updated jobs list
    MySQL.query('SELECT * FROM marshal_multi_jobs WHERE cid = ?', {targetCid}, function(jobs)
        TriggerClientEvent('multijob:admin:receivePlayerJobs', _source, jobs or {})
    end)
end)

-- Get ALL jobs from database for the All Jobs tab
RegisterServerEvent('multijob:admin:getAllJobs')
AddEventHandler('multijob:admin:getAllJobs', function()
    local _source = source
    print('[multijob] Admin: getAllJobs triggered by source ' .. _source)
    if not IsAdmin(_source) then return end
    
    MySQL.query('SELECT * FROM marshal_multi_jobs ORDER BY firstname, lastname, job', {}, function(result)
        local jobs = result or {}
        print('[multijob] Admin: Found ' .. #jobs .. ' total jobs in database')
        TriggerClientEvent('multijob:admin:receiveAllJobs', _source, jobs)
    end)
end)

-- Remove a specific job entry from the database (for All Players tab)
RegisterServerEvent('multijob:admin:removeJobEntry')
AddEventHandler('multijob:admin:removeJobEntry', function(targetCid, targetJob)
    local _source = source
    print('[multijob] Admin: removeJobEntry triggered for cid=' .. tostring(targetCid) .. ', job=' .. tostring(targetJob))
    if not IsAdmin(_source) then return end
    
    -- Delete the job entry from the database
    MySQL.query('DELETE FROM marshal_multi_jobs WHERE cid = ? AND job = ?', {targetCid, targetJob}, function(result)
        local rowsDeleted = result and result.affectedRows or 0
        print('[multijob] Admin: Deleted ' .. tostring(rowsDeleted) .. ' job entries')
        
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
