/**
 * AIT-QB: UI Principal
 * JavaScript para la interfaz NUI
 * Servidor Español
 */

// ═══════════════════════════════════════════════════════════════
// ESTADO GLOBAL
// ═══════════════════════════════════════════════════════════════

const state = {
    hudVisible: false,
    phoneOpen: false,
    inventoryOpen: false,
    isDead: false,
    deathTimer: 300,
    playerData: null,
};

// ═══════════════════════════════════════════════════════════════
// COMUNICACIÓN CON LUA
// ═══════════════════════════════════════════════════════════════

function post(event, data = {}) {
    return fetch(`https://ait-qb/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).catch(() => {});
}

// Escuchar mensajes de Lua
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        // HUD
        case 'showHUD':
            showHUD();
            break;
        case 'hideHUD':
            hideHUD();
            break;
        case 'updateHUD':
            updateHUD(data.data);
            break;

        // Notificaciones
        case 'notification':
            showNotification(data.message, data.type, data.duration);
            break;

        // Progress Bar
        case 'progressStart':
            showProgress(data.label, data.duration);
            break;
        case 'progressStop':
            hideProgress();
            break;

        // Menú de interacción
        case 'showInteractionMenu':
            showInteractionMenu(data.title, data.options);
            break;
        case 'hideInteractionMenu':
            hideInteractionMenu();
            break;

        // Personajes
        case 'showCharacterSelection':
            showCharacterSelection(data.characters);
            break;
        case 'showCharacterCreation':
            showCharacterCreation();
            break;

        // Muerte
        case 'showDeathScreen':
            showDeathScreen(data.timer);
            break;
        case 'hideDeathScreen':
            hideDeathScreen();
            break;
        case 'updateDeathTimer':
            updateDeathTimer(data.time);
            break;

        // Inventario
        case 'showInventory':
            showInventory(data.inventory, data.secondary);
            break;
        case 'hideInventory':
            hideInventory();
            break;

        // Teléfono
        case 'showPhone':
            showPhone();
            break;
        case 'hidePhone':
            hidePhone();
            break;

        // Player Data
        case 'setPlayerData':
            state.playerData = data.data;
            break;
    }
});

// ═══════════════════════════════════════════════════════════════
// HUD
// ═══════════════════════════════════════════════════════════════

function showHUD() {
    document.getElementById('hud').classList.remove('hidden');
    state.hudVisible = true;
}

function hideHUD() {
    document.getElementById('hud').classList.add('hidden');
    state.hudVisible = false;
}

function updateHUD(data) {
    if (!data) return;

    // Barras de estado
    if (data.health !== undefined) {
        document.getElementById('hud-health').style.width = `${Math.max(0, data.health)}%`;
    }
    if (data.armor !== undefined) {
        document.getElementById('hud-armor').style.width = `${data.armor}%`;
    }
    if (data.hunger !== undefined) {
        document.getElementById('hud-hunger').style.width = `${data.hunger}%`;
    }
    if (data.thirst !== undefined) {
        document.getElementById('hud-thirst').style.width = `${data.thirst}%`;
    }

    // Dinero
    if (data.cash !== undefined) {
        document.getElementById('hud-cash').textContent = formatMoney(data.cash);
    }
    if (data.bank !== undefined) {
        document.getElementById('hud-bank').textContent = formatMoney(data.bank);
    }

    // Vehículo
    if (data.isInVehicle) {
        document.getElementById('hud-vehicle').classList.remove('hidden');

        if (data.speed !== undefined) {
            document.getElementById('hud-speed').textContent = Math.floor(data.speed);
        }
        if (data.fuel !== undefined) {
            document.getElementById('hud-fuel').style.width = `${data.fuel}%`;
        }

        // Cinturón
        const seatbeltEl = document.getElementById('hud-seatbelt');
        if (data.seatbelt) {
            seatbeltEl.classList.remove('bg-red-500/20');
            seatbeltEl.classList.add('bg-green-500/20');
            seatbeltEl.querySelector('svg').classList.remove('text-red-500');
            seatbeltEl.querySelector('svg').classList.add('text-green-500');
        } else {
            seatbeltEl.classList.remove('bg-green-500/20');
            seatbeltEl.classList.add('bg-red-500/20');
            seatbeltEl.querySelector('svg').classList.remove('text-green-500');
            seatbeltEl.querySelector('svg').classList.add('text-red-500');
        }
    } else {
        document.getElementById('hud-vehicle').classList.add('hidden');
    }
}

// ═══════════════════════════════════════════════════════════════
// NOTIFICACIONES
// ═══════════════════════════════════════════════════════════════

function showNotification(message, type = 'info', duration = 5000) {
    const container = document.getElementById('notifications');

    const colors = {
        success: 'from-green-600 to-green-500',
        error: 'from-red-600 to-red-500',
        warning: 'from-yellow-600 to-yellow-500',
        info: 'from-blue-600 to-blue-500',
    };

    const icons = {
        success: '<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>',
        error: '<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>',
        warning: '<path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>',
        info: '<path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>',
    };

    const notification = document.createElement('div');
    notification.className = `flex items-center gap-3 px-4 py-3 rounded-lg bg-gradient-to-r ${colors[type]} text-white shadow-lg animate-slide-in pointer-events-auto`;

    notification.innerHTML = `
        <svg class="w-5 h-5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
            ${icons[type]}
        </svg>
        <span class="text-sm font-medium">${message}</span>
    `;

    container.appendChild(notification);

    setTimeout(() => {
        notification.classList.remove('animate-slide-in');
        notification.classList.add('animate-slide-out');
        setTimeout(() => notification.remove(), 300);
    }, duration);
}

// ═══════════════════════════════════════════════════════════════
// PROGRESS BAR
// ═══════════════════════════════════════════════════════════════

let progressInterval = null;

function showProgress(label, duration) {
    const container = document.getElementById('progress-container');
    const bar = document.getElementById('progress-bar');
    const labelEl = document.getElementById('progress-label');
    const percentEl = document.getElementById('progress-percent');

    container.classList.remove('hidden');
    labelEl.textContent = label;
    bar.style.width = '0%';
    percentEl.textContent = '0%';

    let elapsed = 0;
    const interval = 50;

    progressInterval = setInterval(() => {
        elapsed += interval;
        const percent = Math.min(100, (elapsed / duration) * 100);

        bar.style.width = `${percent}%`;
        percentEl.textContent = `${Math.floor(percent)}%`;

        if (elapsed >= duration) {
            hideProgress();
        }
    }, interval);
}

function hideProgress() {
    if (progressInterval) {
        clearInterval(progressInterval);
        progressInterval = null;
    }
    document.getElementById('progress-container').classList.add('hidden');
}

// ═══════════════════════════════════════════════════════════════
// MENÚ DE INTERACCIÓN
// ═══════════════════════════════════════════════════════════════

function showInteractionMenu(title, options) {
    const container = document.getElementById('interaction-menu');
    const titleEl = document.getElementById('interaction-title');
    const optionsEl = document.getElementById('interaction-options');

    titleEl.textContent = title;
    optionsEl.innerHTML = '';

    options.forEach((opt, index) => {
        const btn = document.createElement('button');
        btn.className = 'w-full flex items-center gap-3 px-4 py-3 rounded-lg bg-white/5 hover:bg-white/10 text-white text-left transition';
        btn.innerHTML = `
            <span class="text-sm font-medium">${opt.title}</span>
        `;
        btn.onclick = () => {
            post('interactionSelect', { index: index });
            hideInteractionMenu();
        };
        optionsEl.appendChild(btn);
    });

    container.classList.remove('hidden');
}

function hideInteractionMenu() {
    document.getElementById('interaction-menu').classList.add('hidden');
    post('closeInteraction');
}

// ═══════════════════════════════════════════════════════════════
// SELECCIÓN DE PERSONAJE
// ═══════════════════════════════════════════════════════════════

function showCharacterSelection(characters) {
    const container = document.getElementById('character-selection');
    const list = document.getElementById('character-list');

    list.innerHTML = '';

    characters.forEach(char => {
        const card = document.createElement('div');
        card.className = 'glass rounded-xl p-4 cursor-pointer hover:bg-white/10 transition';
        card.innerHTML = `
            <div class="flex items-center gap-4">
                <div class="w-16 h-16 bg-gray-700 rounded-full flex items-center justify-center">
                    <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                    </svg>
                </div>
                <div class="flex-1">
                    <h3 class="text-white font-semibold">${char.first_name} ${char.last_name}</h3>
                    <p class="text-gray-400 text-sm">${char.job?.label || 'Desempleado'}</p>
                    <p class="text-green-400 text-sm">$${formatMoney(char.bank || 0)}</p>
                </div>
            </div>
        `;
        card.onclick = () => selectCharacter(char.id);
        list.appendChild(card);
    });

    container.classList.remove('hidden');
}

function selectCharacter(id) {
    post('selectCharacter', { characterId: id });
    document.getElementById('character-selection').classList.add('hidden');
}

function createNewCharacter() {
    document.getElementById('character-selection').classList.add('hidden');
    showCharacterCreation();
}

// ═══════════════════════════════════════════════════════════════
// CREACIÓN DE PERSONAJE
// ═══════════════════════════════════════════════════════════════

function showCharacterCreation() {
    document.getElementById('character-creation').classList.remove('hidden');
}

function closeCharacterCreation() {
    document.getElementById('character-creation').classList.add('hidden');
    post('closeCharacterCreation');
}

document.getElementById('character-form')?.addEventListener('submit', (e) => {
    e.preventDefault();

    const data = {
        firstName: document.getElementById('char-firstname').value,
        lastName: document.getElementById('char-lastname').value,
        dateOfBirth: document.getElementById('char-dob').value,
        gender: document.querySelector('input[name="gender"]:checked').value,
        nationality: document.getElementById('char-nationality').value,
    };

    post('createCharacter', data);
});

// ═══════════════════════════════════════════════════════════════
// PANTALLA DE MUERTE
// ═══════════════════════════════════════════════════════════════

let deathInterval = null;

function showDeathScreen(timer = 300) {
    state.isDead = true;
    state.deathTimer = timer;

    document.getElementById('death-screen').classList.remove('hidden');
    document.getElementById('respawn-btn').disabled = true;

    updateDeathTimer(timer);

    deathInterval = setInterval(() => {
        state.deathTimer--;
        updateDeathTimer(state.deathTimer);

        if (state.deathTimer <= 0) {
            clearInterval(deathInterval);
            document.getElementById('respawn-btn').disabled = false;
            document.getElementById('respawn-btn').className = 'px-6 py-3 bg-red-600 text-white rounded-lg font-semibold hover:bg-red-500 transition cursor-pointer';
        }
    }, 1000);
}

function hideDeathScreen() {
    state.isDead = false;
    document.getElementById('death-screen').classList.add('hidden');

    if (deathInterval) {
        clearInterval(deathInterval);
        deathInterval = null;
    }
}

function updateDeathTimer(seconds) {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    document.getElementById('death-timer').textContent =
        `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

function callEMS() {
    post('callEMS');
    showNotification('Llamando a los servicios de emergencia...', 'info');
}

function respawn() {
    post('respawn');
    hideDeathScreen();
}

// ═══════════════════════════════════════════════════════════════
// INVENTARIO
// ═══════════════════════════════════════════════════════════════

function showInventory(inventory, secondary = null) {
    const container = document.getElementById('inventory');
    const slotsEl = document.getElementById('inventory-slots');
    const secondaryContainer = document.getElementById('secondary-inventory');

    // Generar slots del inventario principal
    slotsEl.innerHTML = '';
    for (let i = 0; i < 50; i++) {
        const item = inventory?.items?.[i];
        const slot = createInventorySlot(i, item);
        slotsEl.appendChild(slot);
    }

    // Inventario secundario
    if (secondary) {
        document.getElementById('secondary-title').textContent = secondary.label || 'Contenedor';
        const secondarySlotsEl = document.getElementById('secondary-slots');
        secondarySlotsEl.innerHTML = '';

        for (let i = 0; i < (secondary.slots || 50); i++) {
            const item = secondary.items?.[i];
            const slot = createInventorySlot(i, item, true);
            secondarySlotsEl.appendChild(slot);
        }

        secondaryContainer.classList.remove('hidden');
    } else {
        secondaryContainer.classList.add('hidden');
    }

    container.classList.remove('hidden');
    state.inventoryOpen = true;
}

function hideInventory() {
    document.getElementById('inventory').classList.add('hidden');
    state.inventoryOpen = false;
    post('closeInventory');
}

function createInventorySlot(index, item, isSecondary = false) {
    const slot = document.createElement('div');
    slot.className = 'w-14 h-14 bg-gray-800/50 rounded-lg border border-gray-700 flex items-center justify-center relative cursor-pointer hover:border-blue-500 transition';
    slot.dataset.slot = index;
    slot.dataset.secondary = isSecondary;

    if (item) {
        slot.innerHTML = `
            <div class="text-center">
                <div class="text-xl">${item.icon || '📦'}</div>
                <div class="absolute bottom-0.5 right-1 text-[10px] text-white font-bold">${item.amount || 1}</div>
            </div>
        `;
        slot.title = item.label || item.name;
    }

    slot.onclick = () => {
        if (item) {
            post('inventorySlotClick', { slot: index, isSecondary: isSecondary });
        }
    };

    return slot;
}

// ═══════════════════════════════════════════════════════════════
// TELÉFONO
// ═══════════════════════════════════════════════════════════════

function showPhone() {
    document.getElementById('phone').classList.remove('hidden');
    state.phoneOpen = true;
    updatePhoneTime();
}

function hidePhone() {
    document.getElementById('phone').classList.add('hidden');
    state.phoneOpen = false;
    post('closePhone');
}

function updatePhoneTime() {
    const now = new Date();
    document.getElementById('phone-time').textContent =
        `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
}

function openPhoneApp(app) {
    post('phoneAppOpen', { app: app });
}

// Actualizar hora del teléfono cada minuto
setInterval(updatePhoneTime, 60000);

// ═══════════════════════════════════════════════════════════════
// UTILIDADES
// ═══════════════════════════════════════════════════════════════

function formatMoney(amount) {
    return new Intl.NumberFormat('es-ES').format(amount);
}

// ═══════════════════════════════════════════════════════════════
// TECLAS
// ═══════════════════════════════════════════════════════════════

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (state.inventoryOpen) {
            hideInventory();
        } else if (state.phoneOpen) {
            hidePhone();
        } else if (document.getElementById('interaction-menu').classList.contains('hidden') === false) {
            hideInteractionMenu();
        }
    }
});

// ═══════════════════════════════════════════════════════════════
// INICIALIZACIÓN
// ═══════════════════════════════════════════════════════════════

console.log('[AIT-QB] UI cargada correctamente');
