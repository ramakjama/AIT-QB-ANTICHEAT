-- =============================================================================
-- ait-qb EVENTS TYPES REGISTRY
-- Registro de tipos de eventos
-- API para crear y gestionar nuevos tipos de eventos
-- =============================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Events = AIT.Engines.Events or {}

local TiposEventos = {
    -- Registro de tipos
    registrados = {},

    -- Handlers por tipo
    handlers = {},

    -- Validadores personalizados
    validadores = {},

    -- Callbacks de ciclo de vida
    cicloVida = {},

    -- Configuración por defecto
    configDefecto = {
        duracionMin = 120,
        duracionMax = 600,
        cooldown = 1800,
        minJugadores = 2,
        maxJugadores = 50,
        recompensaBase = 5000,
        recompensaMultiplier = 1.0,
        requiereAdmin = false,
        automatico = true,
        inscripcion = 0
    }
}

-- =============================================================================
-- REGISTRO DE TIPOS
-- =============================================================================

--- Registra un nuevo tipo de evento
---@param id string Identificador único del tipo
---@param definicion table Definición del tipo de evento
---@return boolean, string|nil
function TiposEventos.Registrar(id, definicion)
    if not id or type(id) ~= 'string' then
        return false, 'ID de tipo inválido'
    end

    if TiposEventos.registrados[id] then
        return false, 'Tipo de evento ya registrado: ' .. id
    end

    -- Validar definición mínima
    if not definicion.nombre then
        return false, 'Se requiere un nombre para el tipo de evento'
    end

    -- Construir tipo con valores por defecto
    local tipo = {
        id = id,
        nombre = definicion.nombre,
        descripcion = definicion.descripcion or '',
        icono = definicion.icono,
        color = definicion.color or '#FFFFFF',

        -- Configuración de tiempo
        duracionMin = definicion.duracionMin or TiposEventos.configDefecto.duracionMin,
        duracionMax = definicion.duracionMax or TiposEventos.configDefecto.duracionMax,
        cooldown = definicion.cooldown or TiposEventos.configDefecto.cooldown,

        -- Participación
        minJugadores = definicion.minJugadores or TiposEventos.configDefecto.minJugadores,
        maxJugadores = definicion.maxJugadores or TiposEventos.configDefecto.maxJugadores,
        inscripcion = definicion.inscripcion or TiposEventos.configDefecto.inscripcion,

        -- Recompensas
        recompensaBase = definicion.recompensaBase or TiposEventos.configDefecto.recompensaBase,
        recompensaMultiplier = definicion.recompensaMultiplier or TiposEventos.configDefecto.recompensaMultiplier,

        -- Control
        requiereAdmin = definicion.requiereAdmin or false,
        automatico = definicion.automatico ~= false,
        habilitado = definicion.habilitado ~= false,

        -- Características especiales
        caracteristicas = definicion.caracteristicas or {},

        -- Zonas compatibles
        zonasCompatibles = definicion.zonasCompatibles or {},

        -- Items requeridos o recompensas
        itemsRequeridos = definicion.itemsRequeridos or {},
        itemsRecompensa = definicion.itemsRecompensa or {},

        -- Metadata
        version = definicion.version or '1.0.0',
        autor = definicion.autor,
        creadoEn = os.time()
    }

    -- Registrar el tipo
    TiposEventos.registrados[id] = tipo

    -- Inicializar handlers vacíos
    TiposEventos.handlers[id] = {}
    TiposEventos.cicloVida[id] = {}
    TiposEventos.validadores[id] = {}

    if AIT.Log then
        AIT.Log.info('EVENTS.TYPES', 'Tipo de evento registrado', {
            id = id,
            nombre = tipo.nombre
        })
    end

    -- Emitir evento de registro
    if AIT.EventBus then
        AIT.EventBus.emit('events.type.registered', {
            id = id,
            nombre = tipo.nombre
        })
    end

    return true
end

--- Desregistra un tipo de evento
---@param id string
---@return boolean
function TiposEventos.Desregistrar(id)
    if not TiposEventos.registrados[id] then
        return false
    end

    TiposEventos.registrados[id] = nil
    TiposEventos.handlers[id] = nil
    TiposEventos.cicloVida[id] = nil
    TiposEventos.validadores[id] = nil

    if AIT.Log then
        AIT.Log.info('EVENTS.TYPES', 'Tipo de evento desregistrado', { id = id })
    end

    return true
end

--- Obtiene un tipo de evento
---@param id string
---@return table|nil
function TiposEventos.Obtener(id)
    return TiposEventos.registrados[id]
end

--- Lista todos los tipos registrados
---@param filtro? table { habilitado, automatico, requiereAdmin }
---@return table
function TiposEventos.Listar(filtro)
    filtro = filtro or {}
    local lista = {}

    for id, tipo in pairs(TiposEventos.registrados) do
        local incluir = true

        if filtro.habilitado ~= nil and tipo.habilitado ~= filtro.habilitado then
            incluir = false
        end

        if filtro.automatico ~= nil and tipo.automatico ~= filtro.automatico then
            incluir = false
        end

        if filtro.requiereAdmin ~= nil and tipo.requiereAdmin ~= filtro.requiereAdmin then
            incluir = false
        end

        if incluir then
            table.insert(lista, {
                id = id,
                nombre = tipo.nombre,
                descripcion = tipo.descripcion,
                icono = tipo.icono,
                color = tipo.color,
                habilitado = tipo.habilitado,
                automatico = tipo.automatico,
                requiereAdmin = tipo.requiereAdmin
            })
        end
    end

    -- Ordenar alfabéticamente
    table.sort(lista, function(a, b)
        return a.nombre < b.nombre
    end)

    return lista
end

--- Verifica si un tipo existe
---@param id string
---@return boolean
function TiposEventos.Existe(id)
    return TiposEventos.registrados[id] ~= nil
end

-- =============================================================================
-- HANDLERS DE EVENTOS
-- =============================================================================

--- Registra un handler para un tipo de evento
---@param tipoId string
---@param accion string Acción (inicio, tick, checkpoint, objetivo, fin, etc.)
---@param handler function
---@param prioridad? number
---@return boolean
function TiposEventos.RegistrarHandler(tipoId, accion, handler, prioridad)
    if not TiposEventos.registrados[tipoId] then
        return false
    end

    prioridad = prioridad or 100

    if not TiposEventos.handlers[tipoId][accion] then
        TiposEventos.handlers[tipoId][accion] = {}
    end

    table.insert(TiposEventos.handlers[tipoId][accion], {
        handler = handler,
        prioridad = prioridad
    })

    -- Ordenar por prioridad
    table.sort(TiposEventos.handlers[tipoId][accion], function(a, b)
        return a.prioridad < b.prioridad
    end)

    return true
end

--- Ejecuta handlers para una acción
---@param tipoId string
---@param accion string
---@param contexto table
---@return table resultados
function TiposEventos.EjecutarHandlers(tipoId, accion, contexto)
    local resultados = {}

    if not TiposEventos.handlers[tipoId] or not TiposEventos.handlers[tipoId][accion] then
        return resultados
    end

    for _, h in ipairs(TiposEventos.handlers[tipoId][accion]) do
        local ok, resultado = pcall(h.handler, contexto)
        if ok then
            table.insert(resultados, resultado)
        else
            if AIT.Log then
                AIT.Log.error('EVENTS.TYPES', 'Error en handler', {
                    tipo = tipoId,
                    accion = accion,
                    error = tostring(resultado)
                })
            end
        end
    end

    return resultados
end

-- =============================================================================
-- CALLBACKS DE CICLO DE VIDA
-- =============================================================================

--- Registra un callback de ciclo de vida
---@param tipoId string
---@param fase string (creacion, inscripcion, inicio, tick, finalizacion, cancelacion)
---@param callback function
---@return boolean
function TiposEventos.RegistrarCicloVida(tipoId, fase, callback)
    if not TiposEventos.registrados[tipoId] then
        return false
    end

    local fasesValidas = {
        'creacion', 'pre_inscripcion', 'inscripcion', 'post_inscripcion',
        'pre_inicio', 'inicio', 'tick', 'pre_finalizacion',
        'finalizacion', 'cancelacion', 'limpieza'
    }

    local faseValida = false
    for _, f in ipairs(fasesValidas) do
        if f == fase then
            faseValida = true
            break
        end
    end

    if not faseValida then
        return false
    end

    if not TiposEventos.cicloVida[tipoId][fase] then
        TiposEventos.cicloVida[tipoId][fase] = {}
    end

    table.insert(TiposEventos.cicloVida[tipoId][fase], callback)

    return true
end

--- Ejecuta callbacks de una fase del ciclo de vida
---@param tipoId string
---@param fase string
---@param evento table
---@return boolean continuar
function TiposEventos.EjecutarCicloVida(tipoId, fase, evento)
    if not TiposEventos.cicloVida[tipoId] or not TiposEventos.cicloVida[tipoId][fase] then
        return true
    end

    for _, callback in ipairs(TiposEventos.cicloVida[tipoId][fase]) do
        local ok, continuar = pcall(callback, evento)
        if not ok then
            if AIT.Log then
                AIT.Log.error('EVENTS.TYPES', 'Error en ciclo de vida', {
                    tipo = tipoId,
                    fase = fase,
                    error = tostring(continuar)
                })
            end
        elseif continuar == false then
            return false
        end
    end

    return true
end

-- =============================================================================
-- VALIDADORES
-- =============================================================================

--- Registra un validador personalizado
---@param tipoId string
---@param nombre string
---@param validador function
---@return boolean
function TiposEventos.RegistrarValidador(tipoId, nombre, validador)
    if not TiposEventos.registrados[tipoId] then
        return false
    end

    TiposEventos.validadores[tipoId][nombre] = validador

    return true
end

--- Valida un evento según los validadores del tipo
---@param tipoId string
---@param evento table
---@return boolean, string|nil error
function TiposEventos.Validar(tipoId, evento)
    if not TiposEventos.validadores[tipoId] then
        return true
    end

    for nombre, validador in pairs(TiposEventos.validadores[tipoId]) do
        local ok, resultado = pcall(validador, evento)
        if not ok then
            return false, 'Error en validador: ' .. nombre
        end
        if resultado ~= true then
            return false, resultado or ('Validación fallida: ' .. nombre)
        end
    end

    return true
end

-- =============================================================================
-- CONFIGURACIÓN DE TIPOS
-- =============================================================================

--- Actualiza la configuración de un tipo
---@param tipoId string
---@param config table
---@return boolean
function TiposEventos.ActualizarConfig(tipoId, config)
    local tipo = TiposEventos.registrados[tipoId]
    if not tipo then
        return false
    end

    -- Actualizar campos permitidos
    local camposActualizables = {
        'nombre', 'descripcion', 'icono', 'color',
        'duracionMin', 'duracionMax', 'cooldown',
        'minJugadores', 'maxJugadores', 'inscripcion',
        'recompensaBase', 'recompensaMultiplier',
        'habilitado', 'automatico'
    }

    for _, campo in ipairs(camposActualizables) do
        if config[campo] ~= nil then
            tipo[campo] = config[campo]
        end
    end

    return true
end

--- Habilita un tipo de evento
---@param tipoId string
---@return boolean
function TiposEventos.Habilitar(tipoId)
    local tipo = TiposEventos.registrados[tipoId]
    if not tipo then return false end

    tipo.habilitado = true
    return true
end

--- Deshabilita un tipo de evento
---@param tipoId string
---@return boolean
function TiposEventos.Deshabilitar(tipoId)
    local tipo = TiposEventos.registrados[tipoId]
    if not tipo then return false end

    tipo.habilitado = false
    return true
end

-- =============================================================================
-- API BUILDER PARA CREAR TIPOS
-- =============================================================================

local TipoBuilder = {}
TipoBuilder.__index = TipoBuilder

function TiposEventos.NuevoTipo(id)
    local builder = setmetatable({
        _id = id,
        _definicion = {}
    }, TipoBuilder)
    return builder
end

function TipoBuilder:nombre(nombre)
    self._definicion.nombre = nombre
    return self
end

function TipoBuilder:descripcion(descripcion)
    self._definicion.descripcion = descripcion
    return self
end

function TipoBuilder:icono(icono)
    self._definicion.icono = icono
    return self
end

function TipoBuilder:color(color)
    self._definicion.color = color
    return self
end

function TipoBuilder:duracion(min, max)
    self._definicion.duracionMin = min
    self._definicion.duracionMax = max
    return self
end

function TipoBuilder:cooldown(segundos)
    self._definicion.cooldown = segundos
    return self
end

function TipoBuilder:jugadores(min, max)
    self._definicion.minJugadores = min
    self._definicion.maxJugadores = max
    return self
end

function TipoBuilder:recompensa(base, multiplier)
    self._definicion.recompensaBase = base
    self._definicion.recompensaMultiplier = multiplier or 1.0
    return self
end

function TipoBuilder:inscripcion(costo)
    self._definicion.inscripcion = costo
    return self
end

function TipoBuilder:requiereAdmin(valor)
    self._definicion.requiereAdmin = valor ~= false
    return self
end

function TipoBuilder:automatico(valor)
    self._definicion.automatico = valor ~= false
    return self
end

function TipoBuilder:caracteristica(nombre, valor)
    if not self._definicion.caracteristicas then
        self._definicion.caracteristicas = {}
    end
    self._definicion.caracteristicas[nombre] = valor
    return self
end

function TipoBuilder:zona(zonaId)
    if not self._definicion.zonasCompatibles then
        self._definicion.zonasCompatibles = {}
    end
    table.insert(self._definicion.zonasCompatibles, zonaId)
    return self
end

function TipoBuilder:itemRequerido(item, cantidad)
    if not self._definicion.itemsRequeridos then
        self._definicion.itemsRequeridos = {}
    end
    table.insert(self._definicion.itemsRequeridos, { item = item, cantidad = cantidad or 1 })
    return self
end

function TipoBuilder:itemRecompensa(item, cantidad, probabilidad)
    if not self._definicion.itemsRecompensa then
        self._definicion.itemsRecompensa = {}
    end
    table.insert(self._definicion.itemsRecompensa, {
        item = item,
        cantidad = cantidad or 1,
        probabilidad = probabilidad or 1.0
    })
    return self
end

function TipoBuilder:version(version)
    self._definicion.version = version
    return self
end

function TipoBuilder:autor(autor)
    self._definicion.autor = autor
    return self
end

function TipoBuilder:registrar()
    return TiposEventos.Registrar(self._id, self._definicion)
end

-- =============================================================================
-- INICIALIZACIÓN - REGISTRAR TIPOS BASE
-- =============================================================================

function TiposEventos.RegistrarTiposBase()
    -- Drop Zone
    TiposEventos.NuevoTipo('drop_zone')
        :nombre('Zona de Suministros')
        :descripcion('Recoge los suministros lanzados desde el aire antes que los demás')
        :icono('parachute')
        :color('#4CAF50')
        :duracion(300, 900)
        :cooldown(1800)
        :jugadores(2, 50)
        :recompensa(5000, 1.5)
        :automatico(true)
        :caracteristica('tieneZona', true)
        :caracteristica('tieneItems', true)
        :registrar()

    -- Carrera
    TiposEventos.NuevoTipo('carrera')
        :nombre('Carrera Callejera')
        :descripcion('Compite en una carrera ilegal por las calles')
        :icono('flag-checkered')
        :color('#FF5722')
        :duracion(180, 600)
        :cooldown(2400)
        :jugadores(2, 20)
        :recompensa(10000, 2.0)
        :inscripcion(2500)
        :automatico(true)
        :caracteristica('tieneCheckpoints', true)
        :caracteristica('requiereVehiculo', true)
        :registrar()

    -- Cacería
    TiposEventos.NuevoTipo('caceria')
        :nombre('Cacería de Objetivos')
        :descripcion('Elimina los objetivos marcados en el mapa')
        :icono('crosshairs')
        :color('#F44336')
        :duracion(600, 1200)
        :cooldown(3600)
        :jugadores(5, 100)
        :recompensa(15000, 2.5)
        :automatico(true)
        :caracteristica('tieneObjetivos', true)
        :caracteristica('pvpHabilitado', false)
        :registrar()

    -- Desafío
    TiposEventos.NuevoTipo('desafio')
        :nombre('Desafío del Servidor')
        :descripcion('Completa el desafío propuesto por el servidor')
        :icono('trophy')
        :color('#FFC107')
        :duracion(120, 600)
        :cooldown(1200)
        :jugadores(1, 200)
        :recompensa(2500, 1.2)
        :automatico(true)
        :caracteristica('individual', true)
        :registrar()

    -- Torneo
    TiposEventos.NuevoTipo('torneo')
        :nombre('Torneo Oficial')
        :descripcion('Participa en el torneo oficial del servidor')
        :icono('medal')
        :color('#9C27B0')
        :duracion(1800, 7200)
        :cooldown(86400)
        :jugadores(8, 64)
        :recompensa(50000, 3.0)
        :inscripcion(10000)
        :requiereAdmin(true)
        :automatico(false)
        :caracteristica('eliminatorio', true)
        :caracteristica('brackets', true)
        :registrar()

    -- Invasión
    TiposEventos.NuevoTipo('invasion')
        :nombre('Invasión')
        :descripcion('Defiende la ciudad de la invasión enemiga')
        :icono('shield-alt')
        :color('#3F51B5')
        :duracion(900, 1800)
        :cooldown(7200)
        :jugadores(10, 200)
        :recompensa(8000, 1.8)
        :automatico(true)
        :caracteristica('cooperativo', true)
        :caracteristica('oleadas', true)
        :caracteristica('jefe', true)
        :registrar()

    -- Búsqueda del Tesoro
    TiposEventos.NuevoTipo('busqueda_tesoro')
        :nombre('Búsqueda del Tesoro')
        :descripcion('Encuentra las pistas y el tesoro escondido')
        :icono('gem')
        :color('#00BCD4')
        :duracion(600, 1800)
        :cooldown(5400)
        :jugadores(3, 30)
        :recompensa(20000, 2.2)
        :automatico(true)
        :caracteristica('pistas', true)
        :caracteristica('tieneItems', true)
        :registrar()

    -- Rey de la Colina
    TiposEventos.NuevoTipo('king_of_hill')
        :nombre('Rey de la Colina')
        :descripcion('Controla el área el mayor tiempo posible')
        :icono('crown')
        :color('#FF9800')
        :duracion(300, 900)
        :cooldown(2700)
        :jugadores(4, 40)
        :recompensa(12000, 2.0)
        :automatico(true)
        :caracteristica('zonaControl', true)
        :caracteristica('pvpHabilitado', true)
        :registrar()

    if AIT.Log then
        AIT.Log.info('EVENTS.TYPES', 'Tipos de eventos base registrados', {
            cantidad = 8
        })
    end
end

-- =============================================================================
-- INICIALIZACIÓN
-- =============================================================================

function TiposEventos.Inicializar()
    -- Registrar tipos base
    TiposEventos.RegistrarTiposBase()

    if AIT.Log then
        AIT.Log.info('EVENTS.TYPES', 'Sistema de tipos de eventos inicializado')
    end

    return true
end

-- =============================================================================
-- REGISTRO
-- =============================================================================

AIT.Engines.Events.Types = TiposEventos

return TiposEventos
