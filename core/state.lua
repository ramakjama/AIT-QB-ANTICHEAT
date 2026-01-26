--[[
    AIT Framework - Sistema de Gestion de Estado
    State Manager reactivo para FiveM

    Caracteristicas:
    - Estado global y por jugador
    - Sistema reactivo con observers
    - Persistencia automatica
    - Snapshots y rollback
    - Historial de cambios
    - Sincronizacion cliente-servidor

    Autor: AIT Team
    Version: 1.0.0
]]

AIT = AIT or {}
AIT.State = AIT.State or {}

-- ============================================================================
-- CONSTANTES Y CONFIGURACION
-- ============================================================================

local CONFIG = {
    MAX_HISTORIAL = 50,             -- Maximo de cambios en historial
    MAX_SNAPSHOTS = 10,             -- Maximo de snapshots almacenados
    INTERVALO_PERSISTENCIA = 60000, -- Intervalo de auto-guardado (ms)
    HABILITAR_DEBUG = false         -- Modo debug
}

local TipoObserver = {
    CAMBIO = "cambio",              -- Cualquier cambio
    CREAR = "crear",                -- Cuando se crea una clave
    ACTUALIZAR = "actualizar",      -- Cuando se actualiza
    ELIMINAR = "eliminar"           -- Cuando se elimina
}

-- ============================================================================
-- ALMACENAMIENTO INTERNO
-- ============================================================================

local estadoGlobal = {}             -- Estado global compartido
local estadosPorJugador = {}        -- Estados individuales por jugador
local observers = {}                -- Observers globales
local observersPorJugador = {}      -- Observers por jugador
local observersPorRuta = {}         -- Observers por ruta especifica
local historialCambios = {}         -- Historial de todos los cambios
local snapshots = {}                -- Snapshots guardados
local snapshotsPorJugador = {}      -- Snapshots por jugador
local persistenciaActiva = false    -- Estado de persistencia automatica
local callbackPersistencia = nil    -- Callback para persistir datos
local idObserverActual = 0          -- ID autoincremental para observers

-- ============================================================================
-- FUNCIONES AUXILIARES
-- ============================================================================

--- Genera un ID unico para observers
--- @return number ID unico
local function generarIdObserver()
    idObserverActual = idObserverActual + 1
    return idObserverActual
end

--- Imprime mensaje de debug si esta habilitado
--- @param mensaje string Mensaje a imprimir
local function debug(mensaje)
    if CONFIG.HABILITAR_DEBUG then
        print(string.format("[AIT.State DEBUG] %s", mensaje))
    end
end

--- Divide una ruta en partes
--- @param ruta string Ruta separada por puntos
--- @return table Lista de partes
local function dividirRuta(ruta)
    local partes = {}
    for parte in string.gmatch(ruta, "[^%.]+") do
        table.insert(partes, parte)
    end
    return partes
end

--- Obtiene un valor anidado de una tabla
--- @param tabla table Tabla raiz
--- @param ruta string Ruta separada por puntos
--- @return any Valor encontrado o nil
local function obtenerValorAnidado(tabla, ruta)
    if not ruta or ruta == "" then
        return tabla
    end

    local partes = dividirRuta(ruta)
    local actual = tabla

    for _, parte in ipairs(partes) do
        if type(actual) ~= "table" then
            return nil
        end
        actual = actual[parte]
    end

    return actual
end

--- Establece un valor anidado en una tabla
--- @param tabla table Tabla raiz
--- @param ruta string Ruta separada por puntos
--- @param valor any Valor a establecer
--- @return boolean Exito
local function establecerValorAnidado(tabla, ruta, valor)
    if not ruta or ruta == "" then
        return false
    end

    local partes = dividirRuta(ruta)
    local actual = tabla

    -- Navegar hasta el penultimo nivel
    for i = 1, #partes - 1 do
        local parte = partes[i]
        if type(actual[parte]) ~= "table" then
            actual[parte] = {}
        end
        actual = actual[parte]
    end

    -- Establecer el valor final
    actual[partes[#partes]] = valor
    return true
end

--- Elimina un valor anidado de una tabla
--- @param tabla table Tabla raiz
--- @param ruta string Ruta separada por puntos
--- @return boolean Exito
local function eliminarValorAnidado(tabla, ruta)
    if not ruta or ruta == "" then
        return false
    end

    local partes = dividirRuta(ruta)
    local actual = tabla

    -- Navegar hasta el penultimo nivel
    for i = 1, #partes - 1 do
        local parte = partes[i]
        if type(actual[parte]) ~= "table" then
            return false
        end
        actual = actual[parte]
    end

    -- Eliminar el valor final
    actual[partes[#partes]] = nil
    return true
end

--- Clona una tabla de forma profunda
--- @param original table Tabla original
--- @return table Tabla clonada
local function clonarProfundo(original)
    if type(original) ~= "table" then
        return original
    end

    local copia = {}
    for clave, valor in pairs(original) do
        copia[clonarProfundo(clave)] = clonarProfundo(valor)
    end

    return setmetatable(copia, getmetatable(original))
end

--- Compara dos valores para detectar cambios
--- @param valor1 any Primer valor
--- @param valor2 any Segundo valor
--- @return boolean Son diferentes
local function sonDiferentes(valor1, valor2)
    if type(valor1) ~= type(valor2) then
        return true
    end

    if type(valor1) == "table" then
        for k, v in pairs(valor1) do
            if sonDiferentes(v, valor2[k]) then
                return true
            end
        end
        for k, v in pairs(valor2) do
            if valor1[k] == nil then
                return true
            end
        end
        return false
    end

    return valor1 ~= valor2
end

-- ============================================================================
-- GESTION DE HISTORIAL
-- ============================================================================

--- Registra un cambio en el historial
--- @param tipo string Tipo de cambio
--- @param ruta string Ruta afectada
--- @param valorAnterior any Valor anterior
--- @param valorNuevo any Valor nuevo
--- @param jugadorId string|nil ID del jugador (opcional)
local function registrarCambio(tipo, ruta, valorAnterior, valorNuevo, jugadorId)
    local entrada = {
        tipo = tipo,
        ruta = ruta,
        valorAnterior = clonarProfundo(valorAnterior),
        valorNuevo = clonarProfundo(valorNuevo),
        jugadorId = jugadorId,
        timestamp = os.time(),
        timestampMs = GetGameTimer and GetGameTimer() or 0
    }

    table.insert(historialCambios, entrada)

    -- Limitar tamano del historial
    while #historialCambios > CONFIG.MAX_HISTORIAL do
        table.remove(historialCambios, 1)
    end

    debug(string.format("Cambio registrado: %s en %s", tipo, ruta))
end

-- ============================================================================
-- SISTEMA DE OBSERVERS
-- ============================================================================

--- Notifica a los observers de un cambio
--- @param ruta string Ruta afectada
--- @param valorAnterior any Valor anterior
--- @param valorNuevo any Valor nuevo
--- @param tipo string Tipo de cambio
--- @param jugadorId string|nil ID del jugador
local function notificarObservers(ruta, valorAnterior, valorNuevo, tipo, jugadorId)
    local observersANotificar = {}

    -- Observers globales
    for id, observer in pairs(observers) do
        if not observer.tipo or observer.tipo == tipo then
            table.insert(observersANotificar, observer)
        end
    end

    -- Observers por ruta
    if observersPorRuta[ruta] then
        for id, observer in pairs(observersPorRuta[ruta]) do
            if not observer.tipo or observer.tipo == tipo then
                table.insert(observersANotificar, observer)
            end
        end
    end

    -- Observers por jugador
    if jugadorId and observersPorJugador[jugadorId] then
        for id, observer in pairs(observersPorJugador[jugadorId]) do
            if not observer.tipo or observer.tipo == tipo then
                table.insert(observersANotificar, observer)
            end
        end
    end

    -- Ejecutar callbacks
    for _, observer in ipairs(observersANotificar) do
        local exito, err = pcall(observer.callback, {
            ruta = ruta,
            valorAnterior = valorAnterior,
            valorNuevo = valorNuevo,
            tipo = tipo,
            jugadorId = jugadorId,
            timestamp = os.time()
        })

        if not exito then
            print(string.format("[AIT.State] Error en observer: %s", err))
        end
    end

    debug(string.format("Notificados %d observers para: %s", #observersANotificar, ruta))
end

-- ============================================================================
-- API DE ESTADO GLOBAL
-- ============================================================================

local StateManager = {}

--- Obtiene un valor del estado global
--- @param ruta string Ruta del valor
--- @param valorDefecto any Valor por defecto si no existe
--- @return any Valor encontrado o defecto
function StateManager.obtener(ruta, valorDefecto)
    local valor = obtenerValorAnidado(estadoGlobal, ruta)

    if valor == nil then
        return valorDefecto
    end

    return clonarProfundo(valor)
end

--- Establece un valor en el estado global
--- @param ruta string Ruta del valor
--- @param valor any Valor a establecer
--- @return boolean Exito
function StateManager.establecer(ruta, valor)
    local valorAnterior = obtenerValorAnidado(estadoGlobal, ruta)
    local tipo = valorAnterior == nil and TipoObserver.CREAR or TipoObserver.ACTUALIZAR

    -- Verificar si realmente hay un cambio
    if not sonDiferentes(valorAnterior, valor) then
        debug(string.format("Sin cambios para: %s", ruta))
        return false
    end

    local exito = establecerValorAnidado(estadoGlobal, ruta, clonarProfundo(valor))

    if exito then
        registrarCambio(tipo, ruta, valorAnterior, valor, nil)
        notificarObservers(ruta, valorAnterior, valor, tipo, nil)
        print(string.format("[AIT.State] Estado actualizado: %s", ruta))
    end

    return exito
end

--- Elimina un valor del estado global
--- @param ruta string Ruta del valor
--- @return boolean Exito
function StateManager.eliminar(ruta)
    local valorAnterior = obtenerValorAnidado(estadoGlobal, ruta)

    if valorAnterior == nil then
        return false
    end

    local exito = eliminarValorAnidado(estadoGlobal, ruta)

    if exito then
        registrarCambio(TipoObserver.ELIMINAR, ruta, valorAnterior, nil, nil)
        notificarObservers(ruta, valorAnterior, nil, TipoObserver.ELIMINAR, nil)
        print(string.format("[AIT.State] Estado eliminado: %s", ruta))
    end

    return exito
end

--- Verifica si existe un valor en el estado global
--- @param ruta string Ruta del valor
--- @return boolean Existe
function StateManager.existe(ruta)
    return obtenerValorAnidado(estadoGlobal, ruta) ~= nil
end

--- Actualiza parcialmente un objeto en el estado
--- @param ruta string Ruta del objeto
--- @param actualizaciones table Campos a actualizar
--- @return boolean Exito
function StateManager.actualizar(ruta, actualizaciones)
    local valorActual = obtenerValorAnidado(estadoGlobal, ruta)

    if type(valorActual) ~= "table" then
        valorActual = {}
    end

    local nuevoValor = clonarProfundo(valorActual)

    for clave, valor in pairs(actualizaciones) do
        nuevoValor[clave] = valor
    end

    return StateManager.establecer(ruta, nuevoValor)
end

--- Incrementa un valor numerico
--- @param ruta string Ruta del valor
--- @param cantidad number Cantidad a incrementar
--- @return number Nuevo valor
function StateManager.incrementar(ruta, cantidad)
    cantidad = cantidad or 1
    local valorActual = StateManager.obtener(ruta, 0)

    if type(valorActual) ~= "number" then
        valorActual = 0
    end

    local nuevoValor = valorActual + cantidad
    StateManager.establecer(ruta, nuevoValor)

    return nuevoValor
end

--- Decrementa un valor numerico
--- @param ruta string Ruta del valor
--- @param cantidad number Cantidad a decrementar
--- @return number Nuevo valor
function StateManager.decrementar(ruta, cantidad)
    return StateManager.incrementar(ruta, -(cantidad or 1))
end

--- Agrega un elemento a un array
--- @param ruta string Ruta del array
--- @param elemento any Elemento a agregar
--- @return number Nuevo tamano del array
function StateManager.agregar(ruta, elemento)
    local array = StateManager.obtener(ruta, {})

    if type(array) ~= "table" then
        array = {}
    end

    table.insert(array, elemento)
    StateManager.establecer(ruta, array)

    return #array
end

--- Elimina un elemento de un array por indice
--- @param ruta string Ruta del array
--- @param indice number Indice a eliminar
--- @return any Elemento eliminado
function StateManager.remover(ruta, indice)
    local array = StateManager.obtener(ruta, {})

    if type(array) ~= "table" or not array[indice] then
        return nil
    end

    local eliminado = table.remove(array, indice)
    StateManager.establecer(ruta, array)

    return eliminado
end

-- ============================================================================
-- API DE ESTADO POR JUGADOR
-- ============================================================================

--- Obtiene el estado de un jugador
--- @param jugadorId string ID del jugador
--- @param ruta string Ruta del valor (opcional)
--- @param valorDefecto any Valor por defecto
--- @return any Valor encontrado
function StateManager.obtenerJugador(jugadorId, ruta, valorDefecto)
    if not estadosPorJugador[jugadorId] then
        return valorDefecto
    end

    if not ruta or ruta == "" then
        return clonarProfundo(estadosPorJugador[jugadorId])
    end

    local valor = obtenerValorAnidado(estadosPorJugador[jugadorId], ruta)

    if valor == nil then
        return valorDefecto
    end

    return clonarProfundo(valor)
end

--- Establece un valor en el estado del jugador
--- @param jugadorId string ID del jugador
--- @param ruta string Ruta del valor
--- @param valor any Valor a establecer
--- @return boolean Exito
function StateManager.establecerJugador(jugadorId, ruta, valor)
    if not estadosPorJugador[jugadorId] then
        estadosPorJugador[jugadorId] = {}
    end

    local valorAnterior = obtenerValorAnidado(estadosPorJugador[jugadorId], ruta)
    local tipo = valorAnterior == nil and TipoObserver.CREAR or TipoObserver.ACTUALIZAR

    if not sonDiferentes(valorAnterior, valor) then
        return false
    end

    local exito = establecerValorAnidado(estadosPorJugador[jugadorId], ruta, clonarProfundo(valor))

    if exito then
        registrarCambio(tipo, ruta, valorAnterior, valor, jugadorId)
        notificarObservers(ruta, valorAnterior, valor, tipo, jugadorId)
        print(string.format("[AIT.State] Estado de jugador %s actualizado: %s", jugadorId, ruta))
    end

    return exito
end

--- Elimina el estado de un jugador
--- @param jugadorId string ID del jugador
--- @param ruta string Ruta a eliminar (opcional, si no se especifica elimina todo)
--- @return boolean Exito
function StateManager.eliminarJugador(jugadorId, ruta)
    if not estadosPorJugador[jugadorId] then
        return false
    end

    if not ruta or ruta == "" then
        estadosPorJugador[jugadorId] = nil
        print(string.format("[AIT.State] Estado completo del jugador %s eliminado", jugadorId))
        return true
    end

    local valorAnterior = obtenerValorAnidado(estadosPorJugador[jugadorId], ruta)

    if valorAnterior == nil then
        return false
    end

    local exito = eliminarValorAnidado(estadosPorJugador[jugadorId], ruta)

    if exito then
        registrarCambio(TipoObserver.ELIMINAR, ruta, valorAnterior, nil, jugadorId)
        notificarObservers(ruta, valorAnterior, nil, TipoObserver.ELIMINAR, jugadorId)
    end

    return exito
end

--- Inicializa el estado de un jugador
--- @param jugadorId string ID del jugador
--- @param estadoInicial table Estado inicial
function StateManager.inicializarJugador(jugadorId, estadoInicial)
    estadosPorJugador[jugadorId] = clonarProfundo(estadoInicial or {})
    print(string.format("[AIT.State] Estado inicializado para jugador: %s", jugadorId))
end

-- ============================================================================
-- API DE OBSERVERS
-- ============================================================================

--- Suscribe un observer global
--- @param callback function Callback a ejecutar
--- @param opciones table Opciones (tipo, ruta)
--- @return number ID del observer
function StateManager.observar(callback, opciones)
    opciones = opciones or {}

    local id = generarIdObserver()
    local observer = {
        id = id,
        callback = callback,
        tipo = opciones.tipo
    }

    if opciones.ruta then
        observersPorRuta[opciones.ruta] = observersPorRuta[opciones.ruta] or {}
        observersPorRuta[opciones.ruta][id] = observer
    else
        observers[id] = observer
    end

    debug(string.format("Observer registrado: %d", id))

    return id
end

--- Suscribe un observer para un jugador especifico
--- @param jugadorId string ID del jugador
--- @param callback function Callback a ejecutar
--- @param opciones table Opciones adicionales
--- @return number ID del observer
function StateManager.observarJugador(jugadorId, callback, opciones)
    opciones = opciones or {}

    local id = generarIdObserver()
    local observer = {
        id = id,
        callback = callback,
        tipo = opciones.tipo
    }

    observersPorJugador[jugadorId] = observersPorJugador[jugadorId] or {}
    observersPorJugador[jugadorId][id] = observer

    debug(string.format("Observer de jugador registrado: %d para %s", id, jugadorId))

    return id
end

--- Elimina un observer
--- @param observerId number ID del observer
function StateManager.dejarDeObservar(observerId)
    -- Buscar en observers globales
    if observers[observerId] then
        observers[observerId] = nil
        debug(string.format("Observer eliminado: %d", observerId))
        return
    end

    -- Buscar en observers por ruta
    for ruta, obsRuta in pairs(observersPorRuta) do
        if obsRuta[observerId] then
            obsRuta[observerId] = nil
            debug(string.format("Observer de ruta eliminado: %d", observerId))
            return
        end
    end

    -- Buscar en observers por jugador
    for jugadorId, obsJugador in pairs(observersPorJugador) do
        if obsJugador[observerId] then
            obsJugador[observerId] = nil
            debug(string.format("Observer de jugador eliminado: %d", observerId))
            return
        end
    end
end

--- Observa cambios en una ruta especifica (shorthand)
--- @param ruta string Ruta a observar
--- @param callback function Callback
--- @return number ID del observer
function StateManager.cuando(ruta, callback)
    return StateManager.observar(callback, { ruta = ruta })
end

-- ============================================================================
-- SNAPSHOTS Y ROLLBACK
-- ============================================================================

--- Crea un snapshot del estado actual
--- @param nombre string Nombre del snapshot
--- @return string ID del snapshot
function StateManager.crearSnapshot(nombre)
    local id = string.format("snap_%s_%d", nombre or "auto", os.time())

    local snapshot = {
        id = id,
        nombre = nombre or "auto",
        estadoGlobal = clonarProfundo(estadoGlobal),
        timestamp = os.time()
    }

    table.insert(snapshots, snapshot)

    -- Limitar numero de snapshots
    while #snapshots > CONFIG.MAX_SNAPSHOTS do
        table.remove(snapshots, 1)
    end

    print(string.format("[AIT.State] Snapshot creado: %s", id))

    return id
end

--- Crea un snapshot del estado de un jugador
--- @param jugadorId string ID del jugador
--- @param nombre string Nombre del snapshot
--- @return string ID del snapshot
function StateManager.crearSnapshotJugador(jugadorId, nombre)
    if not estadosPorJugador[jugadorId] then
        return nil
    end

    local id = string.format("snap_%s_%s_%d", jugadorId, nombre or "auto", os.time())

    snapshotsPorJugador[jugadorId] = snapshotsPorJugador[jugadorId] or {}

    local snapshot = {
        id = id,
        nombre = nombre or "auto",
        estado = clonarProfundo(estadosPorJugador[jugadorId]),
        timestamp = os.time()
    }

    table.insert(snapshotsPorJugador[jugadorId], snapshot)

    -- Limitar snapshots por jugador
    while #snapshotsPorJugador[jugadorId] > CONFIG.MAX_SNAPSHOTS do
        table.remove(snapshotsPorJugador[jugadorId], 1)
    end

    print(string.format("[AIT.State] Snapshot de jugador creado: %s", id))

    return id
end

--- Restaura un snapshot del estado global
--- @param snapshotId string ID del snapshot
--- @return boolean Exito
function StateManager.restaurarSnapshot(snapshotId)
    for _, snapshot in ipairs(snapshots) do
        if snapshot.id == snapshotId then
            estadoGlobal = clonarProfundo(snapshot.estadoGlobal)
            print(string.format("[AIT.State] Snapshot restaurado: %s", snapshotId))
            return true
        end
    end

    print(string.format("[AIT.State] Snapshot no encontrado: %s", snapshotId))
    return false
end

--- Restaura un snapshot de un jugador
--- @param jugadorId string ID del jugador
--- @param snapshotId string ID del snapshot
--- @return boolean Exito
function StateManager.restaurarSnapshotJugador(jugadorId, snapshotId)
    if not snapshotsPorJugador[jugadorId] then
        return false
    end

    for _, snapshot in ipairs(snapshotsPorJugador[jugadorId]) do
        if snapshot.id == snapshotId then
            estadosPorJugador[jugadorId] = clonarProfundo(snapshot.estado)
            print(string.format("[AIT.State] Snapshot de jugador restaurado: %s", snapshotId))
            return true
        end
    end

    return false
end

--- Lista los snapshots disponibles
--- @return table Lista de snapshots
function StateManager.listarSnapshots()
    local lista = {}

    for _, snap in ipairs(snapshots) do
        table.insert(lista, {
            id = snap.id,
            nombre = snap.nombre,
            timestamp = snap.timestamp
        })
    end

    return lista
end

--- Deshace el ultimo cambio (rollback simple)
--- @return boolean Exito
function StateManager.deshacer()
    if #historialCambios == 0 then
        print("[AIT.State] No hay cambios para deshacer")
        return false
    end

    local ultimoCambio = historialCambios[#historialCambios]

    if ultimoCambio.jugadorId then
        if ultimoCambio.tipo == TipoObserver.ELIMINAR then
            establecerValorAnidado(
                estadosPorJugador[ultimoCambio.jugadorId],
                ultimoCambio.ruta,
                ultimoCambio.valorAnterior
            )
        elseif ultimoCambio.tipo == TipoObserver.CREAR then
            eliminarValorAnidado(estadosPorJugador[ultimoCambio.jugadorId], ultimoCambio.ruta)
        else
            establecerValorAnidado(
                estadosPorJugador[ultimoCambio.jugadorId],
                ultimoCambio.ruta,
                ultimoCambio.valorAnterior
            )
        end
    else
        if ultimoCambio.tipo == TipoObserver.ELIMINAR then
            establecerValorAnidado(estadoGlobal, ultimoCambio.ruta, ultimoCambio.valorAnterior)
        elseif ultimoCambio.tipo == TipoObserver.CREAR then
            eliminarValorAnidado(estadoGlobal, ultimoCambio.ruta)
        else
            establecerValorAnidado(estadoGlobal, ultimoCambio.ruta, ultimoCambio.valorAnterior)
        end
    end

    table.remove(historialCambios)
    print(string.format("[AIT.State] Cambio deshecho en: %s", ultimoCambio.ruta))

    return true
end

-- ============================================================================
-- PERSISTENCIA
-- ============================================================================

--- Configura la funcion de persistencia
--- @param callback function Funcion que recibe los datos a persistir
function StateManager.configurarPersistencia(callback)
    callbackPersistencia = callback
    print("[AIT.State] Callback de persistencia configurado")
end

--- Persiste el estado actual
--- @return boolean Exito
function StateManager.persistir()
    if not callbackPersistencia then
        print("[AIT.State] No hay callback de persistencia configurado")
        return false
    end

    local datos = {
        global = clonarProfundo(estadoGlobal),
        jugadores = clonarProfundo(estadosPorJugador),
        timestamp = os.time()
    }

    local exito, err = pcall(callbackPersistencia, datos)

    if exito then
        print("[AIT.State] Estado persistido correctamente")
        return true
    else
        print(string.format("[AIT.State] Error al persistir: %s", err))
        return false
    end
end

--- Carga el estado desde datos persistidos
--- @param datos table Datos a cargar
function StateManager.cargar(datos)
    if not datos then
        return
    end

    if datos.global then
        estadoGlobal = clonarProfundo(datos.global)
    end

    if datos.jugadores then
        estadosPorJugador = clonarProfundo(datos.jugadores)
    end

    print("[AIT.State] Estado cargado desde persistencia")
end

--- Activa la persistencia automatica
--- @param intervalo number Intervalo en milisegundos
function StateManager.activarAutoPersistencia(intervalo)
    intervalo = intervalo or CONFIG.INTERVALO_PERSISTENCIA
    persistenciaActiva = true

    -- Crear timer para persistencia (usando Citizen si esta disponible)
    if Citizen and Citizen.CreateThread then
        Citizen.CreateThread(function()
            while persistenciaActiva do
                Citizen.Wait(intervalo)
                if persistenciaActiva then
                    StateManager.persistir()
                end
            end
        end)
    end

    print(string.format("[AIT.State] Auto-persistencia activada cada %d ms", intervalo))
end

--- Desactiva la persistencia automatica
function StateManager.desactivarAutoPersistencia()
    persistenciaActiva = false
    print("[AIT.State] Auto-persistencia desactivada")
end

-- ============================================================================
-- UTILIDADES
-- ============================================================================

--- Obtiene el estado global completo
--- @return table Estado global
function StateManager.obtenerTodo()
    return clonarProfundo(estadoGlobal)
end

--- Obtiene todos los estados de jugadores
--- @return table Estados de jugadores
function StateManager.obtenerTodosJugadores()
    return clonarProfundo(estadosPorJugador)
end

--- Limpia todo el estado
function StateManager.limpiar()
    estadoGlobal = {}
    estadosPorJugador = {}
    historialCambios = {}
    snapshots = {}
    snapshotsPorJugador = {}

    print("[AIT.State] Estado limpiado completamente")
end

--- Limpia el estado de un jugador
--- @param jugadorId string ID del jugador
function StateManager.limpiarJugador(jugadorId)
    estadosPorJugador[jugadorId] = nil
    observersPorJugador[jugadorId] = nil
    snapshotsPorJugador[jugadorId] = nil

    print(string.format("[AIT.State] Estado del jugador %s limpiado", jugadorId))
end

--- Obtiene el historial de cambios
--- @param limite number Limite de entradas
--- @return table Historial
function StateManager.obtenerHistorial(limite)
    limite = limite or CONFIG.MAX_HISTORIAL

    local resultado = {}
    local inicio = math.max(1, #historialCambios - limite + 1)

    for i = inicio, #historialCambios do
        table.insert(resultado, historialCambios[i])
    end

    return resultado
end

--- Obtiene estadisticas del sistema de estado
--- @return table Estadisticas
function StateManager.estadisticas()
    local numJugadores = 0
    for _ in pairs(estadosPorJugador) do
        numJugadores = numJugadores + 1
    end

    local numObservers = 0
    for _ in pairs(observers) do
        numObservers = numObservers + 1
    end

    local numObserversRuta = 0
    for _, obs in pairs(observersPorRuta) do
        for _ in pairs(obs) do
            numObserversRuta = numObserversRuta + 1
        end
    end

    return {
        jugadoresConEstado = numJugadores,
        observersGlobales = numObservers,
        observersPorRuta = numObserversRuta,
        entradasHistorial = #historialCambios,
        snapshotsGlobales = #snapshots,
        persistenciaActiva = persistenciaActiva
    }
end

--- Habilita o deshabilita el modo debug
--- @param habilitado boolean Estado del debug
function StateManager.setDebug(habilitado)
    CONFIG.HABILITAR_DEBUG = habilitado
    print(string.format("[AIT.State] Modo debug: %s", habilitado and "activado" or "desactivado"))
end

-- ============================================================================
-- EXPORTAR CONSTANTES
-- ============================================================================

StateManager.TipoObserver = TipoObserver
StateManager.CONFIG = CONFIG

-- ============================================================================
-- ASIGNAR AL NAMESPACE GLOBAL
-- ============================================================================

AIT.State = StateManager

-- ============================================================================
-- EJEMPLOS DE USO (COMENTADOS)
-- ============================================================================

--[[
-- Establecer valores globales
AIT.State.establecer("servidor.nombre", "Mi Servidor RP")
AIT.State.establecer("servidor.jugadoresMax", 64)
AIT.State.establecer("economia.tasaImpuesto", 0.15)

-- Obtener valores
local nombreServidor = AIT.State.obtener("servidor.nombre")
local impuesto = AIT.State.obtener("economia.tasaImpuesto", 0.10)

-- Estado de jugador
AIT.State.inicializarJugador("player_123", {
    dinero = 5000,
    trabajo = "policia",
    inventario = {}
})

AIT.State.establecerJugador("player_123", "dinero", 6000)
local dinero = AIT.State.obtenerJugador("player_123", "dinero")

-- Observers
local observerId = AIT.State.observar(function(cambio)
    print("Cambio detectado:", cambio.ruta, cambio.valorNuevo)
end)

-- Observer para ruta especifica
AIT.State.cuando("economia.tasaImpuesto", function(cambio)
    print("Nuevo impuesto:", cambio.valorNuevo)
end)

-- Snapshots
local snapId = AIT.State.crearSnapshot("antes_evento")
-- ... cambios ...
AIT.State.restaurarSnapshot(snapId)

-- Rollback
AIT.State.deshacer() -- Deshace el ultimo cambio

-- Persistencia
AIT.State.configurarPersistencia(function(datos)
    -- Guardar en base de datos o archivo
    exports['oxmysql']:execute('UPDATE state SET data = ?', { json.encode(datos) })
end)

AIT.State.activarAutoPersistencia(60000) -- Cada 60 segundos
]]

return AIT.State
