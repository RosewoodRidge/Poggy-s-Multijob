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
        if (confirm(`Remove job "${job}" from this player?`)) {
            removePlayerJob(job);
        }
    });
}

function switchPlayerJob(job) {
    if (!selectedPlayer) return;
    
    fetch('https://multijob/switchPlayerJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
            cid: selectedPlayer.cid,
            job: job
        })
    }).then(() => {
        // Refresh player list
        fetch('https://multijob/refreshPlayers', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    });
}

function removePlayerJob(job) {
    if (!selectedPlayer) return;
    
    fetch('https://multijob/removePlayerJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
            cid: selectedPlayer.cid,
            job: job
        })
    }).then(() => {
        // Request updated jobs
        fetch('https://multijob/getPlayerJobs', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ cid: selectedPlayer.cid })
        });
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
        alert('Please select a player first');
        return;
    }
    
    const data = {
        cid: selectedPlayer.cid,
        job: $('#job-id').val(),
        jobLabel: $('#job-label').val(),
        grade: $('#job-grade').val(),
        oldJob: selectedPlayer.job
    };
    
    fetch('https://multijob/updateJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(response => {
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
    });
});

$('#add-job-btn').click(() => {
    if (!selectedPlayer) {
        alert('Please select a player first');
        return;
    }
    
    const data = {
        cid: selectedPlayer.cid,
        job: $('#job-id').val(),
        jobLabel: $('#job-label').val(),
        grade: $('#job-grade').val()
    };
    
    if (!data.job || !data.jobLabel) {
        alert('Please fill in job ID and label');
        return;
    }
    
    fetch('https://multijob/addJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(() => {
        // Refresh player jobs list
        fetch('https://multijob/getPlayerJobs', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ cid: selectedPlayer.cid })
        });
    });
});

$('#apply-preset-btn').click(() => {
    if (!selectedPlayer || !selectedPreset) {
        alert('Please select a player and a preset');
        return;
    }
    
    const data = {
        cid: selectedPlayer.cid,
        job: selectedPreset.job,
        jobLabel: selectedPreset.label,
        grade: selectedPreset.grade
    };
    
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
    });
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
