--[[
    ╔═══════════════════════════════════════════════════════════════════════════════╗
    ║                           AIT FRAMEWORK - QBCORE BRIDGE                       ║
    ║                         Sistema de Compatibilidad QBCore                      ║
    ║                                   Versión 1.0.0                               ║
    ╚═══════════════════════════════════════════════════════════════════════════════╝

    Bridge completo para integración con QBCore Framework
    Proporciona wrapper de todas las funciones QB con namespace AIT.Bridges.QBCore

    Características:
    - Gestión completa de jugadores
    - Sistema de dinero y banco
    - Sistema de trabajos y gangs
    - Inventario y items
    - Vehículos y propiedades
    - Eventos y callbacks
--]]

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN DEL MÓDULO
-- ═══════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}
AIT.Bridges = AIT.Bridges or {}
AIT.Bridges.QBCore = {}

-- Referencia al objeto QBCore
local QBCore = nil
local esServidor = IsDuplicityVersion()

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DEL BRIDGE
-- ═══════════════════════════════════════════════════════════════════════════════

AIT.Bridges.QBCore.Config = {
    Debug = false,                          -- Modo debug
    CacheTimeout = 5000,                    -- Tiempo de caché en ms
    AutoReconnect = true,                   -- Reconexión automática
    LogLevel = 'info',                      -- Nivel de log: 'debug', 'info', 'warn', 'error'

    -- Configuración de reintentos
    MaxReintentos = 3,
    TiempoEntreReintentos = 1000,

    -- Mapeo de tipos de dinero
    TiposDinero = {
        ['efectivo'] = 'cash',
        ['banco'] = 'bank',
        ['cripto'] = 'crypto',
        ['negro'] = 'black_money'
    }
}

-- Cache local para optimización
local Cache = {
    Jugadores = {},
    Trabajos = {},
    Gangs = {},
    Items = {},
    UltimaActualizacion = 0
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE UTILIDAD INTERNA
-- ═══════════════════════════════════════════════════════════════════════════════

--- Registra un mensaje en consola con formato AIT
---@param nivel string Nivel del log
---@param mensaje string Mensaje a registrar
---@param ... any Parámetros adicionales
local function Log(nivel, mensaje, ...)
    local niveles = { debug = 1, info = 2, warn = 3, error = 4 }
    local nivelConfig = niveles[AIT.Bridges.QBCore.Config.LogLevel] or 2
    local nivelMensaje = niveles[nivel] or 2

    if nivelMensaje >= nivelConfig then
        local prefijo = string.format('[AIT-QBCore][%s]', string.upper(nivel))
        local mensajeFormateado = string.format(mensaje, ...)
        print(string.format('%s %s', prefijo, mensajeFormateado))
    end
end

--- Valida si QBCore está disponible
---@return boolean
local function ValidarQBCore()
    if not QBCore then
        Log('error', 'QBCore no está inicializado')
        return false
    end
    return true
end

--- Convierte tipo de dinero de español a inglés
---@param tipo string Tipo en español
---@return string Tipo en inglés
local function ConvertirTipoDinero(tipo)
    return AIT.Bridges.QBCore.Config.TiposDinero[string.lower(tipo)] or tipo
end

--- Limpia la caché si ha expirado
local function LimpiarCache()
    local ahora = GetGameTimer()
    if ahora - Cache.UltimaActualizacion > AIT.Bridges.QBCore.Config.CacheTimeout then
        Cache.Jugadores = {}
        Cache.UltimaActualizacion = ahora
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN DE QBCORE
-- ═══════════════════════════════════════════════════════════════════════════════

--- Inicializa la conexión con QBCore
---@return boolean Éxito de la inicialización
function AIT.Bridges.QBCore.Inicializar()
    local intentos = 0
    local maxIntentos = AIT.Bridges.QBCore.Config.MaxReintentos

    while intentos < maxIntentos do
        if esServidor then
            QBCore = exports['qb-core']:GetCoreObject()
        else
            QBCore = exports['qb-core']:GetCoreObject()
        end

        if QBCore then
            Log('info', 'QBCore inicializado correctamente')
            return true
        end

        intentos = intentos + 1
        Log('warn', 'Intento %d/%d de conexión con QBCore fallido', intentos, maxIntentos)
        Citizen.Wait(AIT.Bridges.QBCore.Config.TiempoEntreReintentos)
    end

    Log('error', 'No se pudo inicializar QBCore después de %d intentos', maxIntentos)
    return false
end

--- Obtiene el objeto QBCore directamente
---@return table|nil Objeto QBCore
function AIT.Bridges.QBCore.ObtenerCore()
    if not QBCore then
        AIT.Bridges.QBCore.Inicializar()
    end
    return QBCore
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GESTIÓN DE JUGADORES - SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════

--- Obtiene un jugador por su source/id de servidor
---@param source number ID del jugador
---@return table|nil Objeto jugador con métodos AIT
function AIT.Bridges.QBCore.ObtenerJugador(source)
    if not ValidarQBCore() then return nil end
    if not esServidor then
        Log('error', 'ObtenerJugador solo puede usarse en servidor')
        return nil
    end

    LimpiarCache()

    -- Verificar caché
    if Cache.Jugadores[source] then
        return Cache.Jugadores[source]
    end

    local jugadorQB = QBCore.Functions.GetPlayer(source)
    if not jugadorQB then
        Log('warn', 'Jugador con source %d no encontrado', source)
        return nil
    end

    -- Crear wrapper AIT
    local jugador = {
        _qbPlayer = jugadorQB,
        source = source,

        -- Datos básicos
        ObtenerNombre = function(self)
            return self._qbPlayer.PlayerData.charinfo.firstname .. ' ' .. self._qbPlayer.PlayerData.charinfo.lastname
        end,

        ObtenerPrimerNombre = function(self)
            return self._qbPlayer.PlayerData.charinfo.firstname
        end,

        ObtenerApellido = function(self)
            return self._qbPlayer.PlayerData.charinfo.lastname
        end,

        ObtenerCiudadanoId = function(self)
            return self._qbPlayer.PlayerData.citizenid
        end,

        ObtenerLicencia = function(self)
            return self._qbPlayer.PlayerData.license
        end,

        ObtenerGenero = function(self)
            local genero = self._qbPlayer.PlayerData.charinfo.gender
            return genero == 0 and 'masculino' or 'femenino'
        end,

        ObtenerFechaNacimiento = function(self)
            return self._qbPlayer.PlayerData.charinfo.birthdate
        end,

        ObtenerNacionalidad = function(self)
            return self._qbPlayer.PlayerData.charinfo.nationality
        end,

        ObtenerTelefono = function(self)
            return self._qbPlayer.PlayerData.charinfo.phone
        end,

        -- Métodos de dinero
        ObtenerDinero = function(self, tipo)
            tipo = ConvertirTipoDinero(tipo or 'efectivo')
            return self._qbPlayer.PlayerData.money[tipo] or 0
        end,

        ObtenerEfectivo = function(self)
            return self:ObtenerDinero('efectivo')
        end,

        ObtenerBanco = function(self)
            return self:ObtenerDinero('banco')
        end,

        ObtenerCripto = function(self)
            return self:ObtenerDinero('cripto')
        end,

        AgregarDinero = function(self, tipo, cantidad, razon)
            tipo = ConvertirTipoDinero(tipo or 'efectivo')
            razon = razon or 'Sin especificar'
            return self._qbPlayer.Functions.AddMoney(tipo, cantidad, razon)
        end,

        QuitarDinero = function(self, tipo, cantidad, razon)
            tipo = ConvertirTipoDinero(tipo or 'efectivo')
            razon = razon or 'Sin especificar'
            return self._qbPlayer.Functions.RemoveMoney(tipo, cantidad, razon)
        end,

        EstablecerDinero = function(self, tipo, cantidad, razon)
            tipo = ConvertirTipoDinero(tipo or 'efectivo')
            razon = razon or 'Sin especificar'
            return self._qbPlayer.Functions.SetMoney(tipo, cantidad, razon)
        end,

        TieneDinero = function(self, tipo, cantidad)
            return self:ObtenerDinero(tipo) >= cantidad
        end,

        -- Métodos de trabajo
        ObtenerTrabajo = function(self)
            return self._qbPlayer.PlayerData.job
        end,

        ObtenerNombreTrabajo = function(self)
            return self._qbPlayer.PlayerData.job.name
        end,

        ObtenerEtiquetaTrabajo = function(self)
            return self._qbPlayer.PlayerData.job.label
        end,

        ObtenerGradoTrabajo = function(self)
            return self._qbPlayer.PlayerData.job.grade
        end,

        ObtenerSalario = function(self)
            return self._qbPlayer.PlayerData.job.payment
        end,

        EstaEnServicio = function(self)
            return self._qbPlayer.PlayerData.job.onduty
        end,

        EstablecerServicio = function(self, enServicio)
            self._qbPlayer.Functions.SetJobDuty(enServicio)
        end,

        EstablecerTrabajo = function(self, nombreTrabajo, grado)
            grado = grado or 0
            return self._qbPlayer.Functions.SetJob(nombreTrabajo, grado)
        end,

        TieneTrabajo = function(self, nombreTrabajo)
            if type(nombreTrabajo) == 'table' then
                for _, trabajo in ipairs(nombreTrabajo) do
                    if self._qbPlayer.PlayerData.job.name == trabajo then
                        return true
                    end
                end
                return false
            end
            return self._qbPlayer.PlayerData.job.name == nombreTrabajo
        end,

        -- Métodos de gang
        ObtenerGang = function(self)
            return self._qbPlayer.PlayerData.gang
        end,

        ObtenerNombreGang = function(self)
            return self._qbPlayer.PlayerData.gang.name
        end,

        ObtenerEtiquetaGang = function(self)
            return self._qbPlayer.PlayerData.gang.label
        end,

        ObtenerGradoGang = function(self)
            return self._qbPlayer.PlayerData.gang.grade
        end,

        EstablecerGang = function(self, nombreGang, grado)
            grado = grado or 0
            return self._qbPlayer.Functions.SetGang(nombreGang, grado)
        end,

        TieneGang = function(self, nombreGang)
            if type(nombreGang) == 'table' then
                for _, gang in ipairs(nombreGang) do
                    if self._qbPlayer.PlayerData.gang.name == gang then
                        return true
                    end
                end
                return false
            end
            return self._qbPlayer.PlayerData.gang.name == nombreGang
        end,

        -- Métodos de inventario
        ObtenerInventario = function(self)
            return self._qbPlayer.PlayerData.items
        end,

        ObtenerItem = function(self, nombreItem)
            return self._qbPlayer.Functions.GetItemByName(nombreItem)
        end,

        ObtenerItemPorSlot = function(self, slot)
            return self._qbPlayer.Functions.GetItemBySlot(slot)
        end,

        ObtenerItemsPorNombre = function(self, nombreItem)
            return self._qbPlayer.Functions.GetItemsByName(nombreItem)
        end,

        TieneItem = function(self, nombreItem, cantidad)
            cantidad = cantidad or 1
            local item = self:ObtenerItem(nombreItem)
            return item and item.amount >= cantidad
        end,

        CantidadItem = function(self, nombreItem)
            local item = self:ObtenerItem(nombreItem)
            return item and item.amount or 0
        end,

        AgregarItem = function(self, nombreItem, cantidad, slot, info)
            cantidad = cantidad or 1
            return self._qbPlayer.Functions.AddItem(nombreItem, cantidad, slot, info)
        end,

        QuitarItem = function(self, nombreItem, cantidad, slot)
            cantidad = cantidad or 1
            return self._qbPlayer.Functions.RemoveItem(nombreItem, cantidad, slot)
        end,

        LimpiarInventario = function(self, soloItems)
            return self._qbPlayer.Functions.ClearInventory(soloItems)
        end,

        EstablecerInventario = function(self, items, ignorarPesoMax)
            return self._qbPlayer.Functions.SetInventory(items, ignorarPesoMax)
        end,

        -- Métodos de metadata
        ObtenerMetadata = function(self, clave)
            if clave then
                return self._qbPlayer.PlayerData.metadata[clave]
            end
            return self._qbPlayer.PlayerData.metadata
        end,

        EstablecerMetadata = function(self, clave, valor)
            return self._qbPlayer.Functions.SetMetaData(clave, valor)
        end,

        -- Hambre y sed
        ObtenerHambre = function(self)
            return self._qbPlayer.PlayerData.metadata.hunger or 100
        end,

        ObtenerSed = function(self)
            return self._qbPlayer.PlayerData.metadata.thirst or 100
        end,

        EstablecerHambre = function(self, valor)
            return self:EstablecerMetadata('hunger', valor)
        end,

        EstablecerSed = function(self, valor)
            return self:EstablecerMetadata('thirst', valor)
        end,

        -- Estrés
        ObtenerEstres = function(self)
            return self._qbPlayer.PlayerData.metadata.stress or 0
        end,

        EstablecerEstres = function(self, valor)
            return self:EstablecerMetadata('stress', valor)
        end,

        AgregarEstres = function(self, cantidad)
            local estresActual = self:ObtenerEstres()
            local nuevoEstres = math.min(100, estresActual + cantidad)
            return self:EstablecerEstres(nuevoEstres)
        end,

        QuitarEstres = function(self, cantidad)
            local estresActual = self:ObtenerEstres()
            local nuevoEstres = math.max(0, estresActual - cantidad)
            return self:EstablecerEstres(nuevoEstres)
        end,

        -- Estado del jugador
        EstaVivo = function(self)
            return not self._qbPlayer.PlayerData.metadata.isdead
        end,

        EstaEsposado = function(self)
            return self._qbPlayer.PlayerData.metadata.ishandcuffed or false
        end,

        EstaEnCarcel = function(self)
            return self._qbPlayer.PlayerData.metadata.injail and self._qbPlayer.PlayerData.metadata.injail > 0
        end,

        ObtenerTiempoCarcel = function(self)
            return self._qbPlayer.PlayerData.metadata.injail or 0
        end,

        -- Licencias
        ObtenerLicencias = function(self)
            return self._qbPlayer.PlayerData.metadata.licences or {}
        end,

        TieneLicencia = function(self, nombreLicencia)
            local licencias = self:ObtenerLicencias()
            return licencias[nombreLicencia] == true
        end,

        DarLicencia = function(self, nombreLicencia)
            local licencias = self:ObtenerLicencias()
            licencias[nombreLicencia] = true
            return self:EstablecerMetadata('licences', licencias)
        end,

        QuitarLicencia = function(self, nombreLicencia)
            local licencias = self:ObtenerLicencias()
            licencias[nombreLicencia] = false
            return self:EstablecerMetadata('licences', licencias)
        end,

        -- Guardar jugador
        Guardar = function(self)
            self._qbPlayer.Functions.Save()
        end,

        -- Datos crudos
        ObtenerDatosCrudos = function(self)
            return self._qbPlayer.PlayerData
        end
    }

    -- Guardar en caché
    Cache.Jugadores[source] = jugador

    return jugador
end

--- Obtiene un jugador por su Citizen ID
---@param citizenId string ID de ciudadano
---@return table|nil Objeto jugador
function AIT.Bridges.QBCore.ObtenerJugadorPorCiudadanoId(citizenId)
    if not ValidarQBCore() then return nil end
    if not esServidor then return nil end

    local jugadorQB = QBCore.Functions.GetPlayerByCitizenId(citizenId)
    if jugadorQB then
        return AIT.Bridges.QBCore.ObtenerJugador(jugadorQB.PlayerData.source)
    end
    return nil
end

--- Obtiene un jugador por su número de teléfono
---@param telefono string Número de teléfono
---@return table|nil Objeto jugador
function AIT.Bridges.QBCore.ObtenerJugadorPorTelefono(telefono)
    if not ValidarQBCore() then return nil end
    if not esServidor then return nil end

    local jugadorQB = QBCore.Functions.GetPlayerByPhone(telefono)
    if jugadorQB then
        return AIT.Bridges.QBCore.ObtenerJugador(jugadorQB.PlayerData.source)
    end
    return nil
end

--- Obtiene todos los jugadores conectados
---@return table Lista de jugadores
function AIT.Bridges.QBCore.ObtenerTodosLosJugadores()
    if not ValidarQBCore() then return {} end
    if not esServidor then return {} end

    local jugadores = {}
    local jugadoresQB = QBCore.Functions.GetQBPlayers()

    for source, _ in pairs(jugadoresQB) do
        local jugador = AIT.Bridges.QBCore.ObtenerJugador(source)
        if jugador then
            table.insert(jugadores, jugador)
        end
    end

    return jugadores
end

--- Obtiene jugadores por trabajo
---@param nombreTrabajo string Nombre del trabajo
---@param enServicio boolean|nil Solo los que están en servicio
---@return table Lista de jugadores
function AIT.Bridges.QBCore.ObtenerJugadoresPorTrabajo(nombreTrabajo, enServicio)
    local jugadores = AIT.Bridges.QBCore.ObtenerTodosLosJugadores()
    local resultado = {}

    for _, jugador in ipairs(jugadores) do
        if jugador:TieneTrabajo(nombreTrabajo) then
            if enServicio == nil or jugador:EstaEnServicio() == enServicio then
                table.insert(resultado, jugador)
            end
        end
    end

    return resultado
end

--- Obtiene jugadores por gang
---@param nombreGang string Nombre del gang
---@return table Lista de jugadores
function AIT.Bridges.QBCore.ObtenerJugadoresPorGang(nombreGang)
    local jugadores = AIT.Bridges.QBCore.ObtenerTodosLosJugadores()
    local resultado = {}

    for _, jugador in ipairs(jugadores) do
        if jugador:TieneGang(nombreGang) then
            table.insert(resultado, jugador)
        end
    end

    return resultado
end

--- Cuenta jugadores conectados
---@return number Cantidad de jugadores
function AIT.Bridges.QBCore.ContarJugadores()
    if not ValidarQBCore() then return 0 end
    if not esServidor then return 0 end

    local cantidad = 0
    for _ in pairs(QBCore.Functions.GetQBPlayers()) do
        cantidad = cantidad + 1
    end
    return cantidad
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GESTIÓN DE TRABAJOS
-- ═══════════════════════════════════════════════════════════════════════════════

--- Obtiene información de un trabajo
---@param nombreTrabajo string Nombre del trabajo
---@return table|nil Información del trabajo
function AIT.Bridges.QBCore.ObtenerTrabajo(nombreTrabajo)
    if not ValidarQBCore() then return nil end

    local trabajos = QBCore.Shared.Jobs
    return trabajos[nombreTrabajo]
end

--- Obtiene todos los trabajos disponibles
---@return table Tabla de trabajos
function AIT.Bridges.QBCore.ObtenerTodosLosTrabjos()
    if not ValidarQBCore() then return {} end
    return QBCore.Shared.Jobs or {}
end

--- Verifica si un trabajo existe
---@param nombreTrabajo string Nombre del trabajo
---@return boolean
function AIT.Bridges.QBCore.ExisteTrabajo(nombreTrabajo)
    return AIT.Bridges.QBCore.ObtenerTrabajo(nombreTrabajo) ~= nil
end

--- Obtiene los grados de un trabajo
---@param nombreTrabajo string Nombre del trabajo
---@return table Grados del trabajo
function AIT.Bridges.QBCore.ObtenerGradosTrabajo(nombreTrabajo)
    local trabajo = AIT.Bridges.QBCore.ObtenerTrabajo(nombreTrabajo)
    return trabajo and trabajo.grades or {}
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GESTIÓN DE GANGS
-- ═══════════════════════════════════════════════════════════════════════════════

--- Obtiene información de un gang
---@param nombreGang string Nombre del gang
---@return table|nil Información del gang
function AIT.Bridges.QBCore.ObtenerGang(nombreGang)
    if not ValidarQBCore() then return nil end

    local gangs = QBCore.Shared.Gangs
    return gangs[nombreGang]
end

--- Obtiene todos los gangs
---@return table Tabla de gangs
function AIT.Bridges.QBCore.ObtenerTodosLosGangs()
    if not ValidarQBCore() then return {} end
    return QBCore.Shared.Gangs or {}
end

--- Verifica si un gang existe
---@param nombreGang string Nombre del gang
---@return boolean
function AIT.Bridges.QBCore.ExisteGang(nombreGang)
    return AIT.Bridges.QBCore.ObtenerGang(nombreGang) ~= nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GESTIÓN DE ITEMS
-- ═══════════════════════════════════════════════════════════════════════════════

--- Obtiene información de un item
---@param nombreItem string Nombre del item
---@return table|nil Información del item
function AIT.Bridges.QBCore.ObtenerItem(nombreItem)
    if not ValidarQBCore() then return nil end
    return QBCore.Shared.Items[nombreItem]
end

--- Obtiene todos los items
---@return table Tabla de items
function AIT.Bridges.QBCore.ObtenerTodosLosItems()
    if not ValidarQBCore() then return {} end
    return QBCore.Shared.Items or {}
end

--- Verifica si un item existe
---@param nombreItem string Nombre del item
---@return boolean
function AIT.Bridges.QBCore.ExisteItem(nombreItem)
    return AIT.Bridges.QBCore.ObtenerItem(nombreItem) ~= nil
end

--- Crea un item usable (servidor)
---@param nombreItem string Nombre del item
---@param callback function Función a ejecutar al usar
function AIT.Bridges.QBCore.CrearItemUsable(nombreItem, callback)
    if not ValidarQBCore() then return end
    if not esServidor then
        Log('error', 'CrearItemUsable solo puede usarse en servidor')
        return
    end

    QBCore.Functions.CreateUseableItem(nombreItem, callback)
    Log('info', 'Item usable creado: %s', nombreItem)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GESTIÓN DE VEHÍCULOS
-- ═══════════════════════════════════════════════════════════════════════════════

--- Obtiene información de un vehículo por modelo
---@param modelo string Modelo del vehículo
---@return table|nil Información del vehículo
function AIT.Bridges.QBCore.ObtenerVehiculo(modelo)
    if not ValidarQBCore() then return nil end
    return QBCore.Shared.Vehicles[modelo]
end

--- Obtiene todos los vehículos
---@return table Tabla de vehículos
function AIT.Bridges.QBCore.ObtenerTodosLosVehiculos()
    if not ValidarQBCore() then return {} end
    return QBCore.Shared.Vehicles or {}
end

--- Obtiene vehículos por categoría
---@param categoria string Categoría del vehículo
---@return table Lista de vehículos
function AIT.Bridges.QBCore.ObtenerVehiculosPorCategoria(categoria)
    local vehiculos = AIT.Bridges.QBCore.ObtenerTodosLosVehiculos()
    local resultado = {}

    for modelo, datos in pairs(vehiculos) do
        if datos.category == categoria then
            resultado[modelo] = datos
        end
    end

    return resultado
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALLBACKS - SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════════

--- Registra un callback de servidor
---@param nombre string Nombre del callback
---@param callback function Función del callback
function AIT.Bridges.QBCore.RegistrarCallback(nombre, callback)
    if not ValidarQBCore() then return end
    if not esServidor then
        Log('error', 'RegistrarCallback solo puede usarse en servidor')
        return
    end

    QBCore.Functions.CreateCallback(nombre, function(source, cb, ...)
        local jugador = AIT.Bridges.QBCore.ObtenerJugador(source)
        callback(jugador, cb, ...)
    end)

    Log('debug', 'Callback registrado: %s', nombre)
end

--- Dispara un callback desde cliente
---@param nombre string Nombre del callback
---@param callback function Función de respuesta
---@param ... any Parámetros adicionales
function AIT.Bridges.QBCore.DispararCallback(nombre, callback, ...)
    if not ValidarQBCore() then return end
    if esServidor then
        Log('error', 'DispararCallback solo puede usarse en cliente')
        return
    end

    QBCore.Functions.TriggerCallback(nombre, callback, ...)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE CLIENTE
-- ═══════════════════════════════════════════════════════════════════════════════

--- Obtiene los datos del jugador local (cliente)
---@return table|nil Datos del jugador
function AIT.Bridges.QBCore.ObtenerDatosJugador()
    if not ValidarQBCore() then return nil end
    if esServidor then
        Log('error', 'ObtenerDatosJugador solo puede usarse en cliente')
        return nil
    end

    return QBCore.Functions.GetPlayerData()
end

--- Obtiene un dato específico del jugador local
---@param clave string Clave del dato
---@return any Valor del dato
function AIT.Bridges.QBCore.ObtenerDatoJugador(clave)
    local datos = AIT.Bridges.QBCore.ObtenerDatosJugador()
    if not datos then return nil end
    return datos[clave]
end

--- Verifica si el jugador está logueado
---@return boolean
function AIT.Bridges.QBCore.EstaLogueado()
    if esServidor then return true end
    return LocalPlayer.state.isLoggedIn or false
end

--- Obtiene el trabajo del jugador local
---@return table|nil Trabajo del jugador
function AIT.Bridges.QBCore.ObtenerMiTrabajo()
    return AIT.Bridges.QBCore.ObtenerDatoJugador('job')
end

--- Obtiene el gang del jugador local
---@return table|nil Gang del jugador
function AIT.Bridges.QBCore.ObtenerMiGang()
    return AIT.Bridges.QBCore.ObtenerDatoJugador('gang')
end

--- Obtiene el dinero del jugador local
---@param tipo string Tipo de dinero
---@return number Cantidad
function AIT.Bridges.QBCore.ObtenerMiDinero(tipo)
    tipo = ConvertirTipoDinero(tipo or 'efectivo')
    local dinero = AIT.Bridges.QBCore.ObtenerDatoJugador('money')
    return dinero and dinero[tipo] or 0
end

--- Verifica si tengo un item (cliente)
---@param nombreItem string Nombre del item
---@param cantidad number|nil Cantidad mínima
---@return boolean
function AIT.Bridges.QBCore.TengoItem(nombreItem, cantidad)
    cantidad = cantidad or 1
    local items = AIT.Bridges.QBCore.ObtenerDatoJugador('items')

    if not items then return false end

    for _, item in pairs(items) do
        if item.name == nombreItem and item.amount >= cantidad then
            return true
        end
    end

    return false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════════════

--- Envía una notificación
---@param source number|nil Source del jugador (nil para cliente local)
---@param mensaje string Mensaje de la notificación
---@param tipo string Tipo: 'success', 'error', 'primary', 'warning'
---@param duracion number|nil Duración en ms
function AIT.Bridges.QBCore.Notificar(source, mensaje, tipo, duracion)
    if not ValidarQBCore() then return end

    tipo = tipo or 'primary'
    duracion = duracion or 5000

    -- Mapeo de tipos
    local mapeoTipos = {
        ['exito'] = 'success',
        ['error'] = 'error',
        ['info'] = 'primary',
        ['advertencia'] = 'warning',
        ['aviso'] = 'warning'
    }
    tipo = mapeoTipos[tipo] or tipo

    if esServidor then
        TriggerClientEvent('QBCore:Notify', source, mensaje, tipo, duracion)
    else
        QBCore.Functions.Notify(mensaje, tipo, duracion)
    end
end

--- Envía notificación de éxito
---@param source number|nil Source
---@param mensaje string Mensaje
function AIT.Bridges.QBCore.NotificarExito(source, mensaje)
    AIT.Bridges.QBCore.Notificar(source, mensaje, 'success')
end

--- Envía notificación de error
---@param source number|nil Source
---@param mensaje string Mensaje
function AIT.Bridges.QBCore.NotificarError(source, mensaje)
    AIT.Bridges.QBCore.Notificar(source, mensaje, 'error')
end

--- Envía notificación de información
---@param source number|nil Source
---@param mensaje string Mensaje
function AIT.Bridges.QBCore.NotificarInfo(source, mensaje)
    AIT.Bridges.QBCore.Notificar(source, mensaje, 'primary')
end

--- Envía notificación de advertencia
---@param source number|nil Source
---@param mensaje string Mensaje
function AIT.Bridges.QBCore.NotificarAdvertencia(source, mensaje)
    AIT.Bridges.QBCore.Notificar(source, mensaje, 'warning')
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════

--- Registra un evento cuando un jugador carga
---@param callback function Función a ejecutar
function AIT.Bridges.QBCore.AlCargarJugador(callback)
    if esServidor then
        RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
            local source = source
            local jugador = AIT.Bridges.QBCore.ObtenerJugador(source)
            callback(jugador)
        end)
    else
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            local datos = AIT.Bridges.QBCore.ObtenerDatosJugador()
            callback(datos)
        end)
    end
end

--- Registra un evento cuando un jugador se desconecta
---@param callback function Función a ejecutar
function AIT.Bridges.QBCore.AlDesconectarJugador(callback)
    if not esServidor then return end

    RegisterNetEvent('QBCore:Server:OnPlayerUnload', function()
        local source = source
        callback(source)
    end)
end

--- Registra un evento cuando cambia el trabajo
---@param callback function Función a ejecutar
function AIT.Bridges.QBCore.AlCambiarTrabajo(callback)
    if esServidor then
        RegisterNetEvent('QBCore:Server:OnJobUpdate', function(source, trabajo)
            local jugador = AIT.Bridges.QBCore.ObtenerJugador(source)
            callback(jugador, trabajo)
        end)
    else
        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(trabajo)
            callback(trabajo)
        end)
    end
end

--- Registra un evento cuando cambia el gang
---@param callback function Función a ejecutar
function AIT.Bridges.QBCore.AlCambiarGang(callback)
    if esServidor then
        RegisterNetEvent('QBCore:Server:OnGangUpdate', function(source, gang)
            local jugador = AIT.Bridges.QBCore.ObtenerJugador(source)
            callback(jugador, gang)
        end)
    else
        RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
            callback(gang)
        end)
    end
end

--- Registra un evento cuando cambia el dinero
---@param callback function Función a ejecutar
function AIT.Bridges.QBCore.AlCambiarDinero(callback)
    RegisterNetEvent('QBCore:Client:OnMoneyChange', function(tipo, cantidad, accion, razon)
        -- Convertir tipo a español
        local tiposEspanol = {
            ['cash'] = 'efectivo',
            ['bank'] = 'banco',
            ['crypto'] = 'cripto'
        }
        callback(tiposEspanol[tipo] or tipo, cantidad, accion, razon)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════════════

--- Obtiene la lista de localizaciones compartidas
---@return table
function AIT.Bridges.QBCore.ObtenerLocalizaciones()
    if not ValidarQBCore() then return {} end
    return QBCore.Shared.Locations or {}
end

--- Formatea dinero con separadores
---@param cantidad number Cantidad a formatear
---@return string Cantidad formateada
function AIT.Bridges.QBCore.FormatearDinero(cantidad)
    return ('$%s'):format(tostring(cantidad):reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', ''))
end

--- Genera un ID único
---@return string ID único
function AIT.Bridges.QBCore.GenerarId()
    if not ValidarQBCore() then
        return tostring(math.random(100000, 999999))
    end

    if esServidor then
        return QBCore.Functions.GetRandomNumber(8)
    else
        return tostring(math.random(10000000, 99999999))
    end
end

--- Obtiene la distancia entre dos puntos
---@param coords1 vector3 Coordenadas 1
---@param coords2 vector3 Coordenadas 2
---@return number Distancia
function AIT.Bridges.QBCore.ObtenerDistancia(coords1, coords2)
    return #(coords1 - coords2)
end

--- Verifica si el jugador está cerca de un punto
---@param coords vector3 Coordenadas del punto
---@param distancia number Distancia máxima
---@return boolean
function AIT.Bridges.QBCore.EstaCerca(coords, distancia)
    if esServidor then return false end
    local miPosicion = GetEntityCoords(PlayerPedId())
    return AIT.Bridges.QBCore.ObtenerDistancia(miPosicion, coords) <= distancia
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMANDOS Y PERMISOS
-- ═══════════════════════════════════════════════════════════════════════════════

--- Registra un comando con permisos
---@param nombre string Nombre del comando
---@param permiso string Permiso requerido
---@param callback function Función del comando
---@param ayuda string|nil Texto de ayuda
function AIT.Bridges.QBCore.RegistrarComando(nombre, permiso, callback, ayuda)
    if not ValidarQBCore() then return end
    if not esServidor then return end

    QBCore.Commands.Add(nombre, ayuda or '', {}, false, function(source, args)
        local jugador = AIT.Bridges.QBCore.ObtenerJugador(source)
        callback(jugador, args)
    end, permiso)

    Log('debug', 'Comando registrado: %s con permiso %s', nombre, permiso)
end

--- Verifica si un jugador tiene un permiso
---@param source number Source del jugador
---@param permiso string Permiso a verificar
---@return boolean
function AIT.Bridges.QBCore.TienePermiso(source, permiso)
    if not ValidarQBCore() then return false end
    if not esServidor then return false end

    return QBCore.Functions.HasPermission(source, permiso)
end

--- Verifica si un jugador es admin
---@param source number Source del jugador
---@return boolean
function AIT.Bridges.QBCore.EsAdmin(source)
    return AIT.Bridges.QBCore.TienePermiso(source, 'admin')
end

--- Verifica si un jugador es dios (god)
---@param source number Source del jugador
---@return boolean
function AIT.Bridges.QBCore.EsDios(source)
    return AIT.Bridges.QBCore.TienePermiso(source, 'god')
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN AUTOMÁTICA
-- ═══════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    AIT.Bridges.QBCore.Inicializar()
end)

-- Exportar el módulo
exports('GetQBCoreBridge', function()
    return AIT.Bridges.QBCore
end)

Log('info', 'Bridge QBCore cargado correctamente')

return AIT.Bridges.QBCore
