Locales = {
    ['menu_title'] = 'Multijob Menu',
    ['menu_subtitle'] = 'Select a job to switch to',
    ['current_job'] = 'Current Job: %s - %s',
    ['switch_job'] = 'Switch to %s',
    ['quit_job'] = 'Quit Job',
    ['quit_all'] = 'Quit All Jobs',
    ['job_switched'] = 'You have switched to %s',
    ['job_quitted'] = 'You have quit your job',
    ['all_jobs_quitted'] = 'You have quit all jobs',
    ['max_jobs_reached'] = 'You cannot have more than %s jobs',
    ['job_already_has'] = 'You already have this job',
    ['invalid_job'] = 'Invalid job selection',
    ['no_jobs'] = 'You have no other jobs',
    ['admin_menu_title'] = 'Multijob Admin',
    ['admin_updated'] = 'Player job updated successfully',
    ['admin_error'] = 'Error updating player job',
    ['not_allowed'] = 'You do not have permission to use this command'
}

function _U(str, ...)
    if Locales[str] then
        return string.format(Locales[str], ...)
    else
        return 'Locale [' .. str .. '] does not exist'
    end
end
