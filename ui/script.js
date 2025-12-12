let players = [];
let selectedPlayer = null;
let selectedPreset = null;
let playerJobs = []; // All jobs for selected player from database

// Job Presets - Will be loaded from Config.lua
let jobPresets = {};

window.addEventListener('message', function(event) {
    if (event.data.type === 'show') {
        if (event.data.show) {
            // Load presets from Lua config if provided
            if (event.data.presets) {
                jobPresets = event.data.presets;
                console.log('Loaded job presets from config:', Object.keys(jobPresets));
            }
            $('#app').fadeIn();
            renderPresets();
        } else {
            $('#app').fadeOut();
        }
    } else if (event.data.type === 'updatePlayers') {
        players = event.data.players;
        renderPlayers();
        // If we have a selected player, update their info
        if (selectedPlayer) {
            const updated = players.find(p => p.cid === selectedPlayer.cid);
            if (updated) {
                selectedPlayer = updated;
                updatePlayerJobsList();
            }
        }
    } else if (event.data.type === 'updatePlayerJobs') {
        playerJobs = event.data.jobs || [];
        updatePlayerJobsList();
    } else if (event.data.type === 'updateAllJobs') {
        allJobs = event.data.jobs || [];
        updateJobFilter();
        renderAllJobs();
    }
});

function renderPlayers() {
    const search = $('#search').val().toLowerCase();
    const onlineList = $('#online-player-list');
    const offlineList = $('#offline-player-list');
    onlineList.empty();
    offlineList.empty();
    
    // Separate online and offline players
    const onlinePlayers = players.filter(p => p.isOnline).sort((a, b) => a.charName.localeCompare(b.charName));
    const offlinePlayers = players.filter(p => !p.isOnline).sort((a, b) => a.charName.localeCompare(b.charName));
    
    // Render online players
    onlinePlayers.forEach(p => {
        if (!search || p.charName.toLowerCase().includes(search)) {
            const li = $('<li>').text(p.charName);
            if (selectedPlayer && selectedPlayer.cid === p.cid) {
                li.addClass('active');
            }
            li.click(() => selectPlayer(p, li));
            onlineList.append(li);
        }
    });
    
    // Render offline players
    offlinePlayers.forEach(p => {
        if (!search || p.charName.toLowerCase().includes(search)) {
            const li = $('<li>').text(p.charName);
            if (selectedPlayer && selectedPlayer.cid === p.cid) {
                li.addClass('active');
            }
            li.click(() => selectPlayer(p, li));
            offlineList.append(li);
        }
    });
    
    // Show "No players" message if empty
    if (onlineList.children().length === 0) {
        onlineList.append('<li style="opacity: 0.5; cursor: default;">No online players</li>');
    }
    if (offlineList.children().length === 0) {
        offlineList.append('<li style="opacity: 0.5; cursor: default;">No offline players</li>');
    }
}

function selectPlayer(player, element) {
    selectedPlayer = player;
    $('#online-player-list li').removeClass('active');
    $('#offline-player-list li').removeClass('active');
    element.addClass('active');
    
    $('#player-name').val(player.charName + (player.isOnline ? ' (Online)' : ' (Offline)'));
    $('#job-id').val(player.job);
    $('#job-label').val(player.jobLabel);
    $('#job-grade').val(player.grade);
    
    // Request player's jobs from server
    fetch('https://multijob/getPlayerJobs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cid: player.cid })
    });
    
    // Show current job immediately while waiting for full list
    playerJobs = [{
        job: player.job,
        joblabel: player.jobLabel,
        jobgrade: player.grade,
        isCurrent: true
    }];
    updatePlayerJobsList();
}

function updatePlayerJobsList() {
    const container = $('#player-jobs-list');
    container.empty();
    
    if (!selectedPlayer) {
        container.html('<p class="no-jobs">Select a player to view their jobs</p>');
        return;
    }
    
    if (playerJobs.length === 0) {
        container.html('<p class="no-jobs">No jobs found for this player</p>');
        return;
    }
    
    playerJobs.forEach((job, index) => {
        const isCurrent = job.job === selectedPlayer.job;
        const jobItem = $(`
            <div class="job-item ${isCurrent ? 'current' : ''}">
                <div class="job-item-info">
                    <div class="job-item-name">${job.joblabel || job.job} ${isCurrent ? '(ACTIVE)' : ''}</div>
                    <div class="job-item-details">Job: ${job.job} | Grade: ${job.jobgrade}</div>
                </div>
                <div class="job-item-actions">
                    ${!isCurrent ? `<button class="job-item-btn switch" data-job="${job.job}">Set Active</button>` : ''}
                    <button class="job-item-btn edit" data-index="${index}">Edit</button>
                    <button class="job-item-btn delete" data-job="${job.job}">Remove</button>
                </div>
            </div>
        `);
        container.append(jobItem);
    });
    
    // Bind events
    container.find('.job-item-btn.switch').click(function() {
        const job = $(this).data('job');
        const btn = $(this);
        btn.prop('disabled', true).text('Switching...');
        switchPlayerJob(job);
    });
    
    container.find('.job-item-btn.edit').click(function() {
        const index = $(this).data('index');
        const job = playerJobs[index];
        $('#job-id').val(job.job);
        $('#job-label').val(job.joblabel);
        $('#job-grade').val(job.jobgrade);
    });
    
    container.find('.job-item-btn.delete').click(function() {
        const job = $(this).data('job');
        const btn = $(this);
        btn.prop('disabled', true).text('Removing...');
        removePlayerJob(job);
    });
}

function switchPlayerJob(job) {
    if (!selectedPlayer) return;
    
    // Update the local selectedPlayer job to avoid race condition
    const targetCid = selectedPlayer.cid;
    selectedPlayer.job = job;
    
    fetch('https://multijob/switchPlayerJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
            cid: targetCid,
            job: job
        })
    }).then(() => {
        // Wait a bit then refresh player jobs list
        setTimeout(() => {
            fetch('https://multijob/getPlayerJobs', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ cid: targetCid })
            });
            // Also refresh player list to update their current job display
            fetch('https://multijob/refreshPlayers', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }, 300);
    }).catch(err => {
        console.error('Error switching job:', err);
    });
}

function removePlayerJob(job) {
    if (!selectedPlayer) return;
    
    const targetCid = selectedPlayer.cid;
    
    fetch('https://multijob/removePlayerJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
            cid: targetCid,
            job: job
        })
    }).then(() => {
        // Wait a bit then request updated jobs
        setTimeout(() => {
            fetch('https://multijob/getPlayerJobs', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ cid: targetCid })
            });
        }, 300);
    }).catch(err => {
        console.error('Error removing job:', err);
    });
}

function renderPresets() {
    const container = $('#presets-list');
    container.empty();
    
    const searchTerm = $('#preset-search').val().toLowerCase();
    const categoryFilter = $('#category-filter').val();
    
    Object.keys(jobPresets).forEach(categoryKey => {
        if (categoryFilter !== 'all' && categoryFilter !== categoryKey) return;
        
        const category = jobPresets[categoryKey];
        const filteredJobs = category.jobs.filter(job => {
            if (!searchTerm) return true;
            return job.job.toLowerCase().includes(searchTerm) || 
                   job.label.toLowerCase().includes(searchTerm) ||
                   (job.category && job.category.toLowerCase().includes(searchTerm));
        });
        
        if (filteredJobs.length === 0) return;
        
        // Group by subcategory
        const subcategories = {};
        filteredJobs.forEach(job => {
            const subcat = job.category || 'Other';
            if (!subcategories[subcat]) subcategories[subcat] = [];
            subcategories[subcat].push(job);
        });
        
        const categoryDiv = $(`
            <div class="preset-category">
                <div class="preset-category-header">
                    ${category.name}
                    <span class="toggle">▼</span>
                </div>
                <div class="preset-category-items"></div>
            </div>
        `);
        
        const itemsContainer = categoryDiv.find('.preset-category-items');
        
        Object.keys(subcategories).forEach(subcat => {
            const subcatDiv = $(`
                <div class="preset-subcategory">
                    <div class="preset-subcategory-header">
                        ${subcat}
                        <span class="toggle">▶</span>
                    </div>
                    <div class="preset-subcategory-items"></div>
                </div>
            `);
            
            const subcatItems = subcatDiv.find('.preset-subcategory-items');
            
            subcategories[subcat].forEach(job => {
                const presetItem = $(`
                    <div class="preset-item" data-job='${JSON.stringify(job)}'>
                        <div class="preset-item-info">
                            <div class="preset-item-name">${job.label}</div>
                            <div class="preset-item-details">Job: ${job.job} | Grade: ${job.grade}</div>
                        </div>
                    </div>
                `);
                subcatItems.append(presetItem);
            });
            
            itemsContainer.append(subcatDiv);
        });
        
        container.append(categoryDiv);
    });
    
    // Bind click events for main category headers
    $('.preset-category-header').click(function() {
        const items = $(this).next('.preset-category-items');
        items.toggleClass('expanded');
        const toggle = $(this).find('.toggle');
        toggle.text(items.hasClass('expanded') ? '▲' : '▼');
    });
    
    // Bind click events for subcategory headers
    $('.preset-subcategory-header').click(function() {
        const items = $(this).next('.preset-subcategory-items');
        items.toggleClass('expanded');
        const toggle = $(this).find('.toggle');
        toggle.text(items.hasClass('expanded') ? '▼' : '▶');
    });
    
    // Bind click events for preset items (toggle selection)
    $('.preset-item').click(function() {
        if ($(this).hasClass('selected')) {
            // Unselect if already selected
            $(this).removeClass('selected');
            selectedPreset = null;
            $('#apply-preset-btn').prop('disabled', true);
            $('#job-id').val('');
            $('#job-label').val('');
            $('#job-grade').val(0);
        } else {
            // Select this item
            $('.preset-item').removeClass('selected');
            $(this).addClass('selected');
            selectedPreset = JSON.parse($(this).attr('data-job'));
            $('#apply-preset-btn').prop('disabled', false);
            
            // Also fill in the form fields
            $('#job-id').val(selectedPreset.job);
            $('#job-label').val(selectedPreset.label);
            $('#job-grade').val(selectedPreset.grade);
        }
    });
}

// Tab switching
$('.tab-btn').click(function() {
    const tab = $(this).data('tab');
    $('.tab-btn').removeClass('active');
    $(this).addClass('active');
    $('.tab-content').removeClass('active');
    $(`#tab-${tab}`).addClass('active');
});

$('#search').on('input', renderPlayers);
$('#preset-search').on('input', renderPresets);
$('#category-filter').on('change', renderPresets);

$('#close-btn, #close-btn-2').click(() => {
    $('#app').fadeOut();
    fetch('https://multijob/close', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

$('#save-btn').click(() => {
    if (!selectedPlayer) {
        console.log('No player selected');
        return;
    }
    
    const data = {
        cid: selectedPlayer.cid,
        job: $('#job-id').val(),
        jobLabel: $('#job-label').val(),
        grade: $('#job-grade').val(),
        oldJob: selectedPlayer.job
    };
    
    const btn = $('#save-btn');
    btn.prop('disabled', true).text('Saving...');
    
    fetch('https://multijob/updateJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(() => {
        selectedPlayer.job = data.job;
        selectedPlayer.jobLabel = data.jobLabel;
        selectedPlayer.grade = data.grade;
        
        // Refresh player jobs list
        fetch('https://multijob/getPlayerJobs', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ cid: selectedPlayer.cid })
        });
        
        // Refresh players list
        fetch('https://multijob/refreshPlayers', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }).catch(err => {
        console.error('Error saving job:', err);
    }).finally(() => {
        btn.prop('disabled', false).text('Save Job');
    });
});

$('#add-job-btn').click(() => {
    if (!selectedPlayer) {
        console.log('No player selected');
        return;
    }
    
    const jobId = $('#job-id').val().trim();
    const jobLabel = $('#job-label').val().trim() || jobId; // Default to job ID if label is empty
    const jobGrade = $('#job-grade').val() || 0;
    
    if (!jobId) {
        console.log('Missing job ID');
        return;
    }
    
    const data = {
        cid: selectedPlayer.cid,
        job: jobId,
        jobLabel: jobLabel,
        grade: jobGrade
    };
    
    console.log('Adding job:', data);
    
    const btn = $('#add-job-btn');
    btn.prop('disabled', true).text('Adding...');
    
    fetch('https://multijob/addJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(() => {
        // Small delay to let server process, then refresh player jobs list
        setTimeout(() => {
            fetch('https://multijob/getPlayerJobs', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ cid: selectedPlayer.cid })
            });
        }, 300);
    }).catch(err => {
        console.error('Error adding job:', err);
    }).finally(() => {
        btn.prop('disabled', false).text('Add as New Job');
    });
});

$('#apply-preset-btn').click(() => {
    if (!selectedPlayer || !selectedPreset) {
        console.log('No player or preset selected');
        return;
    }
    
    const data = {
        cid: selectedPlayer.cid,
        job: selectedPreset.job,
        jobLabel: selectedPreset.label,
        grade: selectedPreset.grade
    };
    
    const btn = $('#apply-preset-btn');
    btn.prop('disabled', true).text('Applying...');
    
    fetch('https://multijob/addJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(() => {
        // Switch to edit tab
        $('.tab-btn[data-tab="edit"]').click();
        
        // Refresh player jobs list
        fetch('https://multijob/getPlayerJobs', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ cid: selectedPlayer.cid })
        });
    }).catch(err => {
        console.error('Error applying preset:', err);
    }).finally(() => {
        btn.prop('disabled', false).text('Apply Selected Preset');
    });
});

// ==================== ALL PLAYERS TAB ====================
let allJobs = [];
let allJobsSort = { column: 'name', direction: 'asc' };

function loadAllJobs() {
    fetch('https://multijob/getAllJobs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function renderAllJobs() {
    const tbody = $('#alljobs-tbody');
    tbody.empty();
    
    const search = $('#alljobs-search').val().toLowerCase();
    const jobFilter = $('#alljobs-filter').val();
    
    // Filter jobs
    let filtered = allJobs.filter(job => {
        const matchesSearch = !search || 
            (job.firstname + ' ' + job.lastname).toLowerCase().includes(search) ||
            job.job.toLowerCase().includes(search) ||
            (job.joblabel && job.joblabel.toLowerCase().includes(search));
        
        const matchesFilter = jobFilter === 'all' || job.job === jobFilter;
        
        return matchesSearch && matchesFilter;
    });
    
    // Sort by selected column
    filtered.sort((a, b) => {
        let valA, valB;
        
        switch (allJobsSort.column) {
            case 'name':
                valA = (a.firstname + ' ' + a.lastname).toLowerCase();
                valB = (b.firstname + ' ' + b.lastname).toLowerCase();
                break;
            case 'job':
                valA = a.job.toLowerCase();
                valB = b.job.toLowerCase();
                break;
            case 'label':
                valA = (a.joblabel || a.job).toLowerCase();
                valB = (b.joblabel || b.job).toLowerCase();
                break;
            case 'grade':
                valA = a.jobgrade;
                valB = b.jobgrade;
                break;
            case 'lastlogin':
                valA = new Date(a.lastonline || 0).getTime();
                valB = new Date(b.lastonline || 0).getTime();
                break;
            default:
                valA = (a.firstname + ' ' + a.lastname).toLowerCase();
                valB = (b.firstname + ' ' + b.lastname).toLowerCase();
        }
        
        let result;
        if (typeof valA === 'number') {
            result = valA - valB;
        } else {
            result = valA.localeCompare(valB);
        }
        
        return allJobsSort.direction === 'asc' ? result : -result;
    });
    
    // Render rows
    filtered.forEach(job => {
        const charName = (job.firstname || 'Unknown') + ' ' + (job.lastname || 'Unknown');
        const lastLogin = job.lastonline || 'Unknown';
        const lastLoginClass = getLastLoginClass(lastLogin);
        
        const row = $(`
            <tr>
                <td class="char-name">${charName}</td>
                <td><span class="job-name">${job.job}</span></td>
                <td class="job-label">${job.joblabel || job.job}</td>
                <td class="job-grade">${job.jobgrade}</td>
                <td class="last-login ${lastLoginClass}">${formatLastLogin(lastLogin)}</td>
                <td class="actions-cell">
                    <button class="remove-job-btn" data-cid="${job.cid}" data-job="${job.job}">Remove</button>
                </td>
            </tr>
        `);
        tbody.append(row);
    });
    
    // Update count
    $('#alljobs-count').text(filtered.length + ' players found');
    
    // Bind remove buttons
    tbody.find('.remove-job-btn').click(function(e) {
        e.preventDefault();
        e.stopPropagation();
        
        const cid = $(this).data('cid');
        const jobName = $(this).data('job');
        const btn = $(this);
        
        // Disable button to prevent double-clicks
        btn.prop('disabled', true).text('Removing...');
        
        fetch('https://multijob/removeJobEntry', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ cid: cid, job: jobName })
        }).catch(err => {
            console.error('Error removing job:', err);
            btn.prop('disabled', false).text('Remove');
        });
    });
    
    // Update sort indicators
    $('.alljobs-table th.sortable').removeClass('asc desc');
    $(`.alljobs-table th.sortable[data-sort="${allJobsSort.column}"]`).addClass(allJobsSort.direction);
}

function formatLastLogin(dateStr) {
    if (!dateStr || dateStr === 'Unknown') return 'Unknown';
    
    // Try to parse the date
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return dateStr;
    
    const now = new Date();
    const diff = now - date;
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    
    if (days === 0) return 'Today';
    if (days === 1) return 'Yesterday';
    if (days < 7) return days + ' days ago';
    if (days < 30) return Math.floor(days / 7) + ' weeks ago';
    if (days < 365) return Math.floor(days / 30) + ' months ago';
    return Math.floor(days / 365) + ' years ago';
}

function getLastLoginClass(dateStr) {
    if (!dateStr || dateStr === 'Unknown') return '';
    
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return '';
    
    const now = new Date();
    const diff = now - date;
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    
    if (days <= 7) return 'recent';
    if (days > 30) return 'old';
    return '';
}

function updateJobFilter() {
    const select = $('#alljobs-filter');
    const currentValue = select.val();
    
    // Get unique job names
    const uniqueJobs = [...new Set(allJobs.map(j => j.job))].sort();
    
    // Clear and rebuild options
    select.empty();
    select.append('<option value="all">All Jobs</option>');
    uniqueJobs.forEach(job => {
        select.append(`<option value="${job}">${job}</option>`);
    });
    
    // Restore selection if still valid
    if (uniqueJobs.includes(currentValue)) {
        select.val(currentValue);
    }
}

// All Players tab event handlers
$('#alljobs-search').on('input', renderAllJobs);
$('#alljobs-filter').on('change', renderAllJobs);
$('#refresh-alljobs-btn').click(loadAllJobs);

// Sortable column headers
$(document).on('click', '.alljobs-table th.sortable', function() {
    const column = $(this).data('sort');
    
    if (allJobsSort.column === column) {
        // Toggle direction
        allJobsSort.direction = allJobsSort.direction === 'asc' ? 'desc' : 'asc';
    } else {
        // New column, default to ascending
        allJobsSort.column = column;
        allJobsSort.direction = 'asc';
    }
    
    renderAllJobs();
});

$('#close-btn-3').click(() => {
    $('#app').fadeOut();
    fetch('https://multijob/close', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// Load all jobs when switching to the tab
$('.tab-btn[data-tab="alljobs"]').click(function() {
    loadAllJobs();
});

// Handle ESC key to close
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        $('#app').fadeOut();
        fetch('https://multijob/close', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});
