# Multijob System for VORP

A modern, feature-rich multijob system for RedM VORP Framework servers. Allows players to hold multiple jobs simultaneously and switch between them seamlessly.

## Features

- 🎯 **Multiple Jobs** - Players can hold up to 5 jobs at once (configurable)
- 🔄 **Quick Switching** - Switch jobs instantly with `/mj [slot]` command
- 📋 **Intuitive Menu** - Clean NUI interface for managing jobs
- 👑 **Admin Panel** - Full-featured admin interface with `/mjadmin`
- 📊 **Job Presets** - Pre-configured job templates for quick assignment
- 🌐 **Online/Offline Support** - Manage both online and offline player jobs
- 🔧 **Fully Configurable** - Customize commands, limits, and job presets
- 💾 **Persistent Storage** - All jobs saved to MySQL database

## Dependencies

- [VORP Core](https://github.com/VORPCORE/vorp-core-lua)
- [oxmysql](https://github.com/overextended/oxmysql)

## Installation

1. **Download** the latest release from GitHub

2. **Place** the `multijob` folder in your server's `resources` directory
   ```
   resources/
   └── [jobs]/
       └── multijob/
   ```

3. **Import the SQL** file into your database:
   ```sql
   CREATE TABLE marshal_multi_jobs (
       `cid` INT(11) NOT NULL,
       `job` varchar(255) NOT NULL,
       `jobgrade` INT(11) NOT NULL,
       `joblabel` varchar(255) DEFAULT NULL,
       `firstname` varchar(255) NOT NULL,
       `lastname` varchar(255) NOT NULL,
       `lastonline` varchar(255) NOT NULL,
       PRIMARY KEY (`cid`, `job`)
   );
   ```

4. **Add to server.cfg**:
   ```
   ensure multijob
   ```

5. **Restart** your server

## Commands

| Command | Description |
|---------|-------------|
| `/multijob` | Open the multijob menu to view and switch jobs |
| `/mj [slot]` | Quick switch to a specific job slot (e.g., `/mj 1`) |
| `/mjadmin` | Open the admin panel (admin only) |

## Configuration

All configuration is done in `shared/config.lua`:

```lua
Config = {}

-- Enable debug logging
Config.Debug = false

-- Command to open the menu
Config.Command = 'multijob'
Config.CommandDescription = 'Open Multijob Menu'

-- Quick switch command
Config.SwitchCommand = 'mj'
Config.SwitchCommandDescription = 'Quick switch job (e.g. /mj 1)'

-- Maximum jobs a player can hold
Config.MaxJobs = 5

-- Default job when quitting all jobs
Config.DefaultJob = 'unemployed'
Config.DefaultGrade = 0
Config.DefaultJobLabel = 'Unemployed'

-- Discord webhook for logging (optional)
Config.Webhook = ''

-- Admin groups that can access /mjadmin
Config.AdminGroups = {
    'admin',
    'superadmin',
    'moderator'
}
```

## Admin Panel Features

The admin panel (`/mjadmin`) provides:

### Edit Job Tab
- **Player List** - View all online and offline players with jobs
- **Online/Offline Sections** - Clearly separated and alphabetically sorted
- **Current Jobs** - See all jobs a player holds and which is active
- **Set Active** - Switch which job is currently active for a player
- **Edit Jobs** - Modify job ID, label, and grade
- **Remove Jobs** - Remove specific jobs from players
- **Add Jobs** - Assign new jobs to players

### Job Presets Tab
- **Categorized Presets** - Police, Government, Medical, Business, Shops
- **Accordion Navigation** - Expandable subcategories
- **Search & Filter** - Find presets quickly
- **One-Click Assignment** - Select a preset and apply to any player

## Adding Custom Job Presets

Edit the `Config.JobPresets` section in `shared/config.lua`:

```lua
Config.JobPresets = {
    police = {
        name = "Police Departments",
        jobs = {
            { job = "sheriff", label = "Deputy", grade = 0, category = "Sheriff" },
            { job = "sheriff", label = "Sergeant", grade = 1, category = "Sheriff" },
            -- Add more jobs...
        }
    },
    -- Add more categories...
}
```

Each job preset requires:
- `job` - The job identifier (must match your jobs table)
- `label` - Display name for the job
- `grade` - Job grade/rank number
- `category` - Subcategory for organization (used in accordions)

## Localization

Edit `shared/locales.lua` to customize all text strings:

```lua
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
```

## Troubleshooting

### Jobs not saving to database
- Ensure the `marshal_multi_jobs` table exists in your database
- Check that oxmysql is properly installed and configured
- Enable `Config.Debug = true` for detailed logging

### Admin panel not opening
- Verify your character is in an admin group defined in `Config.AdminGroups`
- Check server console for permission errors

### Job labels not updating
- This version includes fixes for `setJobLabel()` - ensure you're using the latest release

## Support

For issues and feature requests, please open an issue on GitHub.

## Credits

- Original concept by Marshal
- Modernized and enhanced by Rosewood Ridge

## License

This project is open source and free to use.
