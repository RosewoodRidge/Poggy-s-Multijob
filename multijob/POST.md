![Banner Image|690x388](upload://mLQas8fprHNId7ZDKVEdidfrnPF.jpeg)

---

## Changelog

### v1.2.5 — RRRP Server Patch

> Baseline: `v1.1.1` (GitHub `Poggy-s-Multijob-main`)
> Changes documented below are relative to the upstream release.

---

#### `server/main.lua` — Major Additions & Fixes

**New: `PersistJobToCharacters()` helper**
VORP's `setJob / setJobGrade / setJobLabel` only update the in-memory character object and state bags — they never immediately write to the `characters` database table. The characters table is only saved on periodic tick or player disconnect. Resources that read the DB directly (e.g. `vorp_crafting`) would see the old job until the next save cycle.

`PersistJobToCharacters(identifier, charIdentifier, job, jobgrade, joblabel)` is now called immediately after every job switch in all four handlers (`switchJob`, `quickSwitch`, `quitJob`, `quitAllJobs`), executing:
```sql
UPDATE characters SET job = ?, jobgrade = ?, joblabel = ? WHERE identifier = ? AND charidentifier = ?
```
This ensures every external resource sees the correct job instantly.

**New: `InjectUnemployed()` helper**
Returns a copy of the provided jobs list with a virtual `{job='unemployed', jobgrade=0, joblabel='Unemployed', _virtual=true}` entry appended. This entry is never stored in `marshal_multi_jobs`; it is injected at runtime only, ensuring players always have access to a "go unemployed" option regardless of their DB state. All `GetPlayerJobs` callbacks and job list responses now pass through `InjectUnemployed()`.

**New: `multijob:quickSwitch` event**
New server event backing the `/mj [slot]` command. Fetches a fresh jobs list from DB on every invocation (rather than relying on the client-side cache), builds a list of jobs excluding the current one, always appends unemployed if not already unemployed, then switches by 1-based index. Calls `PersistJobToCharacters` after switching.

**Changed: VORPcore initialisation**
Switched from `TriggerEvent("getCore", ...)` to `exports.vorp_core:GetCore()` for more reliable core access on resource restart.

**Changed: `multijob:switchJob`**
- Added unemployed special-case: if `targetJob` is `"unemployed"` the DB lookup is skipped entirely; job is set directly and `PersistJobToCharacters` is called.
- Calls `PersistJobToCharacters` after every successful switch.
- All `GetPlayerJobs` responses wrapped with `InjectUnemployed()`.

**Changed: `multijob:checkJobs`**
Now also sends current job info (`{job, label, grade}`) as a second argument alongside the jobs list to the client event so the client always knows which job is active without a separate round-trip.

**Changed: `multijob:quitJob`**
Added early-return guard: if `jobToQuit` is `"unemployed"` the function returns immediately (unemployed is a virtual entry and cannot be removed). Also calls `PersistJobToCharacters` after setting the player to the default job.

**Changed: `multijob:quitAllJobs`**
Calls `PersistJobToCharacters` after setting the player to the default unemployed state.

**Changed: `SaveJobToDB` label fallback**
Label is now stored exactly as supplied. A blank label remains blank (`joblabel or ''`). Previously labels would fall back to the job ID string (`label or job`), which caused the job ID to appear as the display label in some cases.

**Changed: All `print()` calls**
Every `print(...)` in this file is now wrapped: `if Config.Debug then print(...) end`.

---

#### `server/admin.lua` — Bug Fixes

**Fixed: Blank `joblabel` preservation in `addJob` and `updateJob`**
Previously both handlers used `data.jobLabel or newJob` as a fallback, meaning a deliberately blank label would be silently replaced with the job ID string. Changed to:
```lua
local newLabel = (data.jobLabel ~= nil) and data.jobLabel or ''
```
Blank labels now remain blank as intended.

**Changed: All `print()` calls**
Every `print(...)` is now wrapped: `if Config.Debug then print(...) end`.

---

#### `client/menu.lua` — Feature Change

**Changed: `IsValidJobForDisplay` — unemployed no longer filtered**
The previous filter explicitly excluded `'unemployed'` from the VORP native menu, making it impossible for players to switch to unemployed via `/multijob`. The filter now only excludes `'unknown'`, `'none'`, and empty strings. `'unemployed'` displays as a normal menu entry, labelled **"Unemployed"**, allowing players to toggle their active job off.

**Changed: All `print()` calls**
Every `print(...)` is now wrapped with the Config.Debug guard.

---

#### `client/main.lua` — Debug Gating

**Changed: All `print()` calls**
Every `print(...)` is now wrapped: `if Config.Debug then print(...) end`.

---

#### `client/nui.lua` — Debug Gating

**Changed: All `print()` calls**
Every `print(...)` is now wrapped: `if Config.Debug then print(...) end`.

---

#### `shared/config.lua` — Default Change

**Changed: `Config.Debug` default**
`Config.Debug` is now `false` by default (was `true`). Set to `true` to re-enable all server and client console output for debugging purposes.

---

#### Summary Table

| File | GitHub v1.1.1 | Live v1.1.2 | Key Changes |
|---|---|---|---|
| `server/main.lua` | 218 lines | ~400 lines | PersistJobToCharacters, InjectUnemployed, quickSwitch event, unemployed special-case, VORPcore export init, Debug gating |
| `server/admin.lua` | 410 lines | 401 lines | Blank joblabel fix (addJob + updateJob), Debug gating |
| `client/menu.lua` | 93 lines | 86 lines | Unemployed visible in menu, Debug gating |
| `client/main.lua` | 54 lines | 62 lines | Debug gating |
| `client/nui.lua` | 135 lines | 119 lines | Debug gating |
| `shared/config.lua` | 190 lines | 198 lines | Config.Debug = false |

---

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
