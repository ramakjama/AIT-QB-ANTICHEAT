/* ═══════════════════════════════════════════════════════════════════════════════
   AIT-QB ANTICHEAT PANEL - JAVASCRIPT
   ═══════════════════════════════════════════════════════════════════════════════ */

let currentAction = null;
let selectedPlayer = null;
let players = [];
let logs = [];

// ═══════════════════════════════════════════════════════════════════════════════
// INICIALIZACIÓN Y EVENTOS NUI
// ═══════════════════════════════════════════════════════════════════════════════

window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'openPanel':
            openPanel(data);
            break;
        case 'closePanel':
            closePanel();
            break;
        case 'updatePlayers':
            updatePlayers(data.players);
            break;
        case 'updateLogs':
            updateLogs(data.logs);
            break;
        case 'updateStats':
            updateStats(data.stats);
            break;
        case 'updateModules':
            updateModules(data.modules);
            break;
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closePanel();
        closeModal();
        hideContextMenu();
    }
});

document.addEventListener('click', function(event) {
    hideContextMenu();
});

// ═══════════════════════════════════════════════════════════════════════════════
// PANEL FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

function openPanel(data) {
    const panel = document.getElementById('anticheat-panel');
    panel.classList.remove('hidden');

    if (data.players) {
        updatePlayers(data.players);
    }
    if (data.logs) {
        updateLogs(data.logs);
    }
    if (data.stats) {
        updateStats(data.stats);
    }
    if (data.modules) {
        updateModules(data.modules);
    }

    // Request initial data
    fetch(`https://${GetParentResourceName()}/requestData`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function closePanel() {
    const panel = document.getElementById('anticheat-panel');
    panel.classList.add('hidden');

    fetch(`https://${GetParentResourceName()}/closePanel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab').forEach(tab => {
        tab.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(`tab-${tabName}`).classList.add('active');
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLAYERS FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

function updatePlayers(playerList) {
    players = playerList || [];
    renderPlayers();
}

function renderPlayers() {
    const container = document.getElementById('players-list');
    const searchTerm = document.getElementById('player-search').value.toLowerCase();

    const filteredPlayers = players.filter(p =>
        p.name.toLowerCase().includes(searchTerm) ||
        p.id.toString().includes(searchTerm)
    );

    if (filteredPlayers.length === 0) {
        container.innerHTML = `
            <div class="loading">
                <i class="fas fa-users-slash"></i>
                <span>No se encontraron jugadores</span>
            </div>
        `;
        return;
    }

    container.innerHTML = filteredPlayers.map(player => `
        <div class="player-item" onclick="selectPlayer(${player.id})" oncontextmenu="showPlayerContext(event, ${player.id})">
            <div class="player-info">
                <div class="player-avatar">${player.name.charAt(0).toUpperCase()}</div>
                <div class="player-details">
                    <h4>${player.name}</h4>
                    <span>ID: ${player.id} | ${player.identifier ? player.identifier.substring(0, 20) + '...' : 'N/A'}</span>
                </div>
            </div>
            <div class="player-status">
                <span class="suspicion-badge ${getSuspicionClass(player.suspicion)}">${player.suspicion || 0} Sospecha</span>
            </div>
        </div>
    `).join('');
}

function getSuspicionClass(score) {
    if (score >= 75) return 'high';
    if (score >= 40) return 'medium';
    return 'low';
}

function filterPlayers() {
    renderPlayers();
}

function selectPlayer(playerId) {
    selectedPlayer = players.find(p => p.id === playerId);
}

function showPlayerContext(event, playerId) {
    event.preventDefault();
    selectedPlayer = players.find(p => p.id === playerId);

    const menu = document.getElementById('player-context-menu');
    menu.style.left = event.clientX + 'px';
    menu.style.top = event.clientY + 'px';
    menu.classList.remove('hidden');
}

function hideContextMenu() {
    document.getElementById('player-context-menu').classList.add('hidden');
}

function contextAction(action) {
    if (!selectedPlayer) return;

    switch(action) {
        case 'check':
            executeAction('check', { playerId: selectedPlayer.id });
            break;
        case 'freeze':
            executeAction('freeze', { playerId: selectedPlayer.id });
            break;
        case 'screenshot':
            executeAction('screenshot', { playerId: selectedPlayer.id });
            break;
        case 'spectate':
            executeAction('spectate', { playerId: selectedPlayer.id });
            break;
        case 'kick':
            showActionModal('kick');
            break;
        case 'ban':
            showActionModal('ban');
            break;
    }

    hideContextMenu();
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGS FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

function updateLogs(logList) {
    logs = logList || [];
    renderLogs();
}

function renderLogs() {
    const container = document.getElementById('logs-list');
    const typeFilter = document.getElementById('log-type-filter').value;

    const filteredLogs = typeFilter === 'all'
        ? logs
        : logs.filter(l => l.type === typeFilter);

    if (filteredLogs.length === 0) {
        container.innerHTML = `
            <div class="loading">
                <i class="fas fa-clipboard-list"></i>
                <span>No hay logs</span>
            </div>
        `;
        return;
    }

    container.innerHTML = filteredLogs.map(log => `
        <div class="log-item ${log.severity || 'medium'}">
            <span class="log-time">${log.time || 'N/A'}</span>
            <span class="log-type">${log.type}</span>
            <span class="log-player">${log.player}</span>
            <span class="log-details">${log.details}</span>
        </div>
    `).join('');
}

function filterLogs() {
    renderLogs();
}

function refreshLogs() {
    fetch(`https://${GetParentResourceName()}/requestLogs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATS FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

function updateStats(stats) {
    if (stats.players !== undefined) {
        document.getElementById('stat-players').textContent = stats.players;
    }
    if (stats.bans !== undefined) {
        document.getElementById('stat-bans').textContent = stats.bans;
    }
    if (stats.detections !== undefined) {
        document.getElementById('stat-detections').textContent = stats.detections;
    }
    if (stats.kicks !== undefined) {
        document.getElementById('stat-kicks').textContent = stats.kicks;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULES/SETTINGS FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

function updateModules(modules) {
    Object.keys(modules).forEach(key => {
        const toggle = document.getElementById(`toggle-${key}`);
        if (toggle) {
            toggle.checked = modules[key];
        }
    });
}

function toggleModule(moduleName) {
    const toggle = document.getElementById(`toggle-${moduleName}`);
    const enabled = toggle.checked;

    fetch(`https://${GetParentResourceName()}/toggleModule`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ module: moduleName, enabled: enabled })
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODAL FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

function showActionModal(actionType) {
    currentAction = actionType;
    const modal = document.getElementById('action-modal');
    const title = document.getElementById('modal-title');
    const body = document.getElementById('modal-body');
    const confirmBtn = document.getElementById('modal-confirm');

    let html = '';

    switch(actionType) {
        case 'ban':
            title.textContent = 'Banear Jugador';
            confirmBtn.className = 'btn btn-danger';
            confirmBtn.textContent = 'Banear';
            html = `
                <div class="form-group">
                    <label>ID del Jugador</label>
                    <input type="number" id="action-player-id" placeholder="ID" value="${selectedPlayer ? selectedPlayer.id : ''}">
                </div>
                <div class="form-group">
                    <label>Razón</label>
                    <textarea id="action-reason" rows="3" placeholder="Razón del ban..."></textarea>
                </div>
                <div class="form-group">
                    <label>Duración</label>
                    <select id="action-duration">
                        <option value="0">Permanente</option>
                        <option value="3600">1 Hora</option>
                        <option value="86400">1 Día</option>
                        <option value="604800">1 Semana</option>
                        <option value="2592000">1 Mes</option>
                    </select>
                </div>
            `;
            break;

        case 'kick':
            title.textContent = 'Expulsar Jugador';
            confirmBtn.className = 'btn btn-primary';
            confirmBtn.textContent = 'Expulsar';
            html = `
                <div class="form-group">
                    <label>ID del Jugador</label>
                    <input type="number" id="action-player-id" placeholder="ID" value="${selectedPlayer ? selectedPlayer.id : ''}">
                </div>
                <div class="form-group">
                    <label>Razón</label>
                    <textarea id="action-reason" rows="3" placeholder="Razón de la expulsión..."></textarea>
                </div>
            `;
            break;

        case 'freeze':
            title.textContent = 'Congelar Jugador';
            confirmBtn.className = 'btn btn-primary';
            confirmBtn.textContent = 'Congelar';
            html = `
                <div class="form-group">
                    <label>ID del Jugador</label>
                    <input type="number" id="action-player-id" placeholder="ID" value="${selectedPlayer ? selectedPlayer.id : ''}">
                </div>
            `;
            break;

        case 'screenshot':
            title.textContent = 'Capturar Pantalla';
            confirmBtn.className = 'btn btn-primary';
            confirmBtn.textContent = 'Capturar';
            html = `
                <div class="form-group">
                    <label>ID del Jugador</label>
                    <input type="number" id="action-player-id" placeholder="ID" value="${selectedPlayer ? selectedPlayer.id : ''}">
                </div>
            `;
            break;

        case 'spectate':
            title.textContent = 'Modo Espectador';
            confirmBtn.className = 'btn btn-primary';
            confirmBtn.textContent = 'Espectar';
            html = `
                <div class="form-group">
                    <label>ID del Jugador</label>
                    <input type="number" id="action-player-id" placeholder="ID" value="${selectedPlayer ? selectedPlayer.id : ''}">
                </div>
            `;
            break;

        case 'whitelist':
            title.textContent = 'Gestionar Whitelist';
            confirmBtn.className = 'btn btn-primary';
            confirmBtn.textContent = 'Añadir';
            html = `
                <div class="form-group">
                    <label>Acción</label>
                    <select id="action-whitelist-action">
                        <option value="add">Añadir a Whitelist</option>
                        <option value="remove">Quitar de Whitelist</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Identifier</label>
                    <input type="text" id="action-identifier" placeholder="license:xxxxx o steam:xxxxx">
                </div>
            `;
            break;

        case 'unban':
            title.textContent = 'Desbanear Jugador';
            confirmBtn.className = 'btn btn-primary';
            confirmBtn.textContent = 'Desbanear';
            html = `
                <div class="form-group">
                    <label>Identifier o Ban ID</label>
                    <input type="text" id="action-identifier" placeholder="license:xxxxx o BAN-XXXXXXXX">
                </div>
            `;
            break;

        case 'suspect':
            title.textContent = 'Marcar como Sospechoso';
            confirmBtn.className = 'btn btn-primary';
            confirmBtn.textContent = 'Marcar';
            html = `
                <div class="form-group">
                    <label>ID del Jugador</label>
                    <input type="number" id="action-player-id" placeholder="ID" value="${selectedPlayer ? selectedPlayer.id : ''}">
                </div>
                <div class="form-group">
                    <label>Razón</label>
                    <textarea id="action-reason" rows="3" placeholder="Razón de la sospecha..."></textarea>
                </div>
            `;
            break;
    }

    body.innerHTML = html;
    modal.classList.remove('hidden');
}

function closeModal() {
    document.getElementById('action-modal').classList.add('hidden');
    currentAction = null;
}

function confirmAction() {
    const playerId = document.getElementById('action-player-id')?.value;
    const reason = document.getElementById('action-reason')?.value;
    const duration = document.getElementById('action-duration')?.value;
    const identifier = document.getElementById('action-identifier')?.value;
    const whitelistAction = document.getElementById('action-whitelist-action')?.value;

    let actionData = {
        action: currentAction,
        playerId: parseInt(playerId) || null,
        reason: reason || null,
        duration: parseInt(duration) || null,
        identifier: identifier || null,
        whitelistAction: whitelistAction || null
    };

    executeAction(currentAction, actionData);
    closeModal();
}

function executeAction(action, data) {
    fetch(`https://${GetParentResourceName()}/executeAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: action, data: data })
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// UTILITY FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

function GetParentResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'ait-qb';
}
