![Banner Image|690x388](upload://mLQas8fprHNId7ZDKVEdidfrnPF.jpeg)

## Overview

**Multijob System** is a complete, modernized replacement for the aging `marshal_multi_job` script. The original script hasn't been updated in nearly **4 years**, leaving server owners struggling with bugs, database errors, and missing features that modern VORP servers desperately need.

**We've completely rebuilt it from the ground up.** This free, open-source replacement eliminates the frustration that players and admins have dealt with for far too long when managing job systems on their servers.

![Example|550x500](upload://hCsyjtQF1WeWC5m4sgfpj685kwF.jpeg)

## Why Switch?

If you've used the original marshal_multi_job, you've probably experienced:

- ❌ `Column 'cid' cannot be null` database errors
- ❌ Job labels not updating properly
- ❌ Characters not seeing their jobs in the menu
- ❌ No admin panel for managing player jobs
- ❌ No way to manage offline players
- ❌ Outdated code with no support

**This replacement fixes ALL of that** and adds powerful new features that make job management actually enjoyable.

## Features

- 🎯 **Hold Multiple Jobs** - Players can work up to 5 jobs simultaneously (configurable)
- ⚡ **Quick Switch** - Instantly swap jobs with `/mj 1`, `/mj 2`, etc.
- 🖥️ **Modern NUI Interface** - Clean, responsive menu for players
- 👑 **Powerful Admin Panel** - Full control over every player's jobs
- 📊 **150+ Job Presets** - Pre-configured police, medical, government, business, and shop jobs
- 🌐 **Online & Offline Support** - Manage jobs for players even when they're not online
- 🔤 **Alphabetized Player Lists** - Find players instantly
- 🎨 **Accordion Categories** - Organized, expandable job preset browser
- 🔍 **Search & Filter** - Find any preset in seconds
- 💾 **Reliable Database** - Fixed all the NULL errors and data corruption issues
- 🔧 **Fully Configurable** - Customize everything in one config file

## Admin Panel Preview

The new admin panel gives you complete control:

- **Two-Tab Interface** - Edit jobs or browse presets
- **Online/Offline Sections** - Clearly see who's on and who's not
- **Current Job Indicator** - See which job is active at a glance
- **One-Click Actions** - Set active, edit, remove, or add jobs instantly
- **Preset Browser** - 150+ jobs organized by department with accordion navigation

## Commands

| Command | Description |
|---------|-------------|
| `/multijob` | Open the job selection menu |
| `/mj [slot]` | Quick switch to job slot (e.g., `/mj 1`) |
| `/mjadmin` | Open admin panel (admin only) |

## Installation

1. Download the latest release from GitHub
2. Place the `multijob` folder in your server's resources directory
3. Import the SQL file into your database
4. Add `ensure multijob` to your `server.cfg`
5. Restart your server

**That's it.** No complicated setup, no dependencies beyond VORP Core and oxmysql.

## Configuration

All settings in one simple `config.lua`:

```lua
Config = {}

-- Enable debug logging
Config.Debug = false

-- Menu command
Config.Command = 'multijob'

-- Quick switch command
Config.SwitchCommand = 'mj'

-- Maximum jobs per player
Config.MaxJobs = 5

-- Default job when unemployed
Config.DefaultJob = 'unemployed'
Config.DefaultGrade = 0
Config.DefaultJobLabel = 'Unemployed'

-- Admin groups
Config.AdminGroups = {
    'admin',
    'superadmin',
    'moderator'
}

-- 150+ Job Presets included!
Config.JobPresets = {
    police = { ... },
    government = { ... },
    medical = { ... },
    business = { ... },
    shops = { ... }
}
```

## Stop Fighting Your Job System

The original marshal_multi_job was great for its time, but that time was **4 years ago**. Server owners have been patching, hacking, and working around its limitations ever since.

This free replacement is:
- ✅ **Actively maintained**
- ✅ **Bug-free database operations**
- ✅ **Feature-complete admin tools**
- ✅ **Modern, clean codebase**
- ✅ **Open source and free forever**

**Your players deserve a job system that just works. Your admins deserve tools that don't fight them.**

## Dependencies

- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)
- [oxmysql](https://github.com/overextended/oxmysql)

## Download

**GitHub:** https://github.com/RosewoodRidge/Multijob

---

### My Other Scripts

> **Poggy's Admin Blips [Free]:** https://github.com/RosewoodRidge/Poggy-Admin-Blips
> **Poggy's Supply Drops:** https://rosewoodridge.tebex.io/package/6876094
> **Witnesses:** https://rosewoodridge.tebex.io/package/6836507
> **Poggy's Balloon [Free]:** https://forum.cfx.re/t/free-redm-intuitive-hot-air-balloon-flying-and-passenger-system-rosewood-ridge
> **Character Storage [Free]:** https://forum.cfx.re/t/free-redm-character-storage-for-vorp-framework-rosewood-ridge
> **VORP Crafting UI Overhaul [Free]:** https://forum.cfx.re/t/free-vorp-crafting-modern-custom-ui-overhail/5328662

| | |
|--- | ---|
|Code is accessible | Yes|
|Subscription-based | No|
|Lines (approximately) | ~800|
|Requirements | vorp_core, oxmysql|
|Support | Yes (GitHub Issues)|
