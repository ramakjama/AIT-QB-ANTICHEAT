-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ait-qb LOCALIZATION - ESPAÑOL
-- ═══════════════════════════════════════════════════════════════════════════════════════

return {
    -- ───────────────────────────────────────────────────────────────────────────────────
    -- GENERAL
    -- ───────────────────────────────────────────────────────────────────────────────────
    general = {
        yes = 'Sí',
        no = 'No',
        ok = 'Aceptar',
        cancel = 'Cancelar',
        confirm = 'Confirmar',
        close = 'Cerrar',
        save = 'Guardar',
        delete = 'Eliminar',
        edit = 'Editar',
        create = 'Crear',
        search = 'Buscar',
        loading = 'Cargando...',
        error = 'Error',
        success = 'Éxito',
        warning = 'Advertencia',
        info = 'Información',
        back = 'Volver',
        next = 'Siguiente',
        previous = 'Anterior',
        none = 'Ninguno',
        all = 'Todos',
        select = 'Seleccionar',
        required = 'Requerido',
        optional = 'Opcional',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ERRORES
    -- ───────────────────────────────────────────────────────────────────────────────────
    errors = {
        generic = 'Ha ocurrido un error',
        not_found = 'No encontrado',
        unauthorized = 'No autorizado',
        forbidden = 'Acceso denegado',
        invalid_input = 'Entrada inválida',
        insufficient_funds = 'Fondos insuficientes',
        inventory_full = 'Inventario lleno',
        too_heavy = 'Demasiado peso',
        not_enough_items = 'No tienes suficientes items',
        already_exists = 'Ya existe',
        cooldown = 'Debes esperar antes de hacer esto de nuevo',
        rate_limited = 'Has hecho demasiadas peticiones, espera un momento',
        server_error = 'Error del servidor',
        connection_error = 'Error de conexión',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- IDENTIDAD
    -- ───────────────────────────────────────────────────────────────────────────────────
    identity = {
        create_character = 'Crear Personaje',
        select_character = 'Seleccionar Personaje',
        delete_character = 'Eliminar Personaje',
        first_name = 'Nombre',
        last_name = 'Apellido',
        date_of_birth = 'Fecha de Nacimiento',
        gender = 'Género',
        male = 'Masculino',
        female = 'Femenino',
        nationality = 'Nacionalidad',
        slot = 'Ranura',
        new_character = 'Nuevo Personaje',
        confirm_delete = '¿Estás seguro de que quieres eliminar este personaje?',
        character_deleted = 'Personaje eliminado',
        character_created = 'Personaje creado',
        welcome_back = 'Bienvenido de nuevo, %s',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ECONOMÍA
    -- ───────────────────────────────────────────────────────────────────────────────────
    economy = {
        cash = 'Efectivo',
        bank = 'Banco',
        crypto = 'Crypto',
        balance = 'Saldo',
        transfer = 'Transferir',
        deposit = 'Depositar',
        withdraw = 'Retirar',
        amount = 'Cantidad',
        recipient = 'Destinatario',
        transfer_success = 'Transferencia realizada: $%s',
        deposit_success = 'Depositados: $%s',
        withdraw_success = 'Retirados: $%s',
        received = 'Has recibido: $%s de %s',
        tax_applied = 'Impuesto aplicado: $%s',
        transaction_history = 'Historial de Transacciones',
        no_transactions = 'No hay transacciones',
        atm = 'Cajero Automático',
        bank_account = 'Cuenta Bancaria',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- INVENTARIO
    -- ───────────────────────────────────────────────────────────────────────────────────
    inventory = {
        title = 'Inventario',
        weight = 'Peso',
        use = 'Usar',
        give = 'Dar',
        drop = 'Tirar',
        split = 'Dividir',
        item_used = 'Has usado %s',
        item_given = 'Has dado %s x%d a %s',
        item_received = 'Has recibido %s x%d de %s',
        item_dropped = 'Has tirado %s x%d',
        crafting = 'Fabricación',
        craft = 'Fabricar',
        recipe = 'Receta',
        materials = 'Materiales',
        result = 'Resultado',
        crafting_success = 'Has fabricado %s',
        crafting_failed = 'Fabricación fallida',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- VEHÍCULOS
    -- ───────────────────────────────────────────────────────────────────────────────────
    vehicles = {
        garage = 'Garaje',
        impound = 'Depósito',
        parking = 'Aparcamiento',
        spawn = 'Sacar Vehículo',
        store = 'Guardar Vehículo',
        retrieve = 'Recuperar Vehículo',
        fuel = 'Combustible',
        engine = 'Motor',
        body = 'Carrocería',
        keys = 'Llaves',
        lock = 'Cerrar',
        unlock = 'Abrir',
        locked = 'Cerrado',
        unlocked = 'Abierto',
        no_keys = 'No tienes las llaves',
        vehicle_impounded = 'Tu vehículo ha sido llevado al depósito',
        impound_fee = 'Tarifa de depósito: $%s',
        insurance = 'Seguro',
        repair = 'Reparar',
        tuning = 'Tuning',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- FACCIONES
    -- ───────────────────────────────────────────────────────────────────────────────────
    factions = {
        faction = 'Facción',
        members = 'Miembros',
        rank = 'Rango',
        invite = 'Invitar',
        kick = 'Expulsar',
        promote = 'Ascender',
        demote = 'Degradar',
        leave = 'Abandonar',
        territory = 'Territorio',
        stash = 'Almacén',
        funds = 'Fondos',
        deposit_funds = 'Depositar Fondos',
        withdraw_funds = 'Retirar Fondos',
        invited = 'Has sido invitado a %s',
        joined = 'Te has unido a %s',
        left = 'Has abandonado %s',
        kicked = 'Has sido expulsado de %s',
        promoted = 'Has sido ascendido a %s',
        demoted = 'Has sido degradado a %s',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- MISIONES
    -- ───────────────────────────────────────────────────────────────────────────────────
    missions = {
        mission = 'Misión',
        objective = 'Objetivo',
        reward = 'Recompensa',
        accept = 'Aceptar',
        abandon = 'Abandonar',
        complete = 'Completar',
        failed = 'Fallida',
        in_progress = 'En Progreso',
        new_mission = 'Nueva Misión Disponible',
        mission_complete = '¡Misión Completada!',
        mission_failed = 'Misión Fallida',
        time_remaining = 'Tiempo Restante',
        checkpoint = 'Punto de Control',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- TIENDA
    -- ───────────────────────────────────────────────────────────────────────────────────
    shop = {
        store = 'Tienda',
        buy = 'Comprar',
        sell = 'Vender',
        price = 'Precio',
        quantity = 'Cantidad',
        cart = 'Carrito',
        checkout = 'Pagar',
        add_to_cart = 'Añadir al Carrito',
        remove_from_cart = 'Quitar del Carrito',
        empty_cart = 'Vaciar Carrito',
        total = 'Total',
        purchase_success = 'Compra realizada',
        purchase_failed = 'Compra fallida',
        not_enough_stock = 'No hay suficiente stock',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- HUD
    -- ───────────────────────────────────────────────────────────────────────────────────
    hud = {
        health = 'Salud',
        armor = 'Armadura',
        hunger = 'Hambre',
        thirst = 'Sed',
        stress = 'Estrés',
        stamina = 'Resistencia',
        oxygen = 'Oxígeno',
        voice = 'Voz',
        microphone = 'Micrófono',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- ADMIN
    -- ───────────────────────────────────────────────────────────────────────────────────
    admin = {
        panel = 'Panel de Administración',
        players = 'Jugadores',
        reports = 'Reportes',
        logs = 'Registros',
        kick = 'Expulsar',
        ban = 'Banear',
        teleport = 'Teletransportar',
        spectate = 'Observar',
        freeze = 'Congelar',
        unfreeze = 'Descongelar',
        give_item = 'Dar Item',
        set_money = 'Establecer Dinero',
        reason = 'Motivo',
        duration = 'Duración',
        permanent = 'Permanente',
        action_success = 'Acción realizada',
        action_failed = 'Acción fallida',
    },

    -- ───────────────────────────────────────────────────────────────────────────────────
    -- TIEMPOS
    -- ───────────────────────────────────────────────────────────────────────────────────
    time = {
        seconds = 'segundos',
        minutes = 'minutos',
        hours = 'horas',
        days = 'días',
        weeks = 'semanas',
        months = 'meses',
        years = 'años',
        ago = 'hace',
        in_time = 'en',
        just_now = 'ahora mismo',
    },
}
