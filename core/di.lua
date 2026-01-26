--[[
    AIT Framework - Sistema de Inyeccion de Dependencias
    Contenedor IoC completo para FiveM

    Caracteristicas:
    - Registro de servicios (singleton/transient/scoped)
    - Resolucion automatica de dependencias
    - Decoradores y middleware
    - Lazy loading
    - Ciclos de vida gestionados
    - Validacion de dependencias circulares

    Autor: AIT Team
    Version: 1.0.0
]]

AIT = AIT or {}
AIT.DI = AIT.DI or {}

-- ============================================================================
-- CONSTANTES Y CONFIGURACION
-- ============================================================================

local CicloVida = {
    SINGLETON = "singleton",    -- Una sola instancia compartida
    TRANSIENT = "transient",    -- Nueva instancia cada vez
    SCOPED = "scoped"           -- Instancia por scope/contexto
}

local EstadoServicio = {
    REGISTRADO = "registrado",
    RESOLVIENDO = "resolviendo",
    RESUELTO = "resuelto",
    ERROR = "error"
}

-- ============================================================================
-- CONTENEDOR PRINCIPAL
-- ============================================================================

local Contenedor = {}
Contenedor.__index = Contenedor

-- Almacenamiento interno
local registros = {}                -- Definiciones de servicios
local instanciasSingleton = {}      -- Cache de singletons
local scopesActivos = {}            -- Scopes activos
local decoradores = {}              -- Decoradores registrados
local interceptores = {}            -- Interceptores de resolucion
local aliasServicios = {}           -- Alias para servicios
local gruposServicios = {}          -- Grupos de servicios
local estadoResolucion = {}         -- Estado actual de resolucion (para detectar ciclos)
local historialResolucion = {}      -- Historial para debug
local serviciosLazy = {}            -- Servicios con carga diferida
local eventosContenedor = {}        -- Eventos del contenedor

-- ============================================================================
-- FUNCIONES AUXILIARES
-- ============================================================================

--- Genera un ID unico para scopes
--- @return string ID unico
local function generarIdScope()
    return string.format("scope_%s_%d", os.time(), math.random(100000, 999999))
end

--- Registra un evento en el historial
--- @param tipo string Tipo de evento
--- @param nombre string Nombre del servicio
--- @param detalles table Detalles adicionales
local function registrarHistorial(tipo, nombre, detalles)
    table.insert(historialResolucion, {
        tipo = tipo,
        nombre = nombre,
        detalles = detalles or {},
        timestamp = os.time()
    })

    -- Limitar historial a 1000 entradas
    if #historialResolucion > 1000 then
        table.remove(historialResolucion, 1)
    end
end

--- Emite un evento del contenedor
--- @param evento string Nombre del evento
--- @param datos table Datos del evento
local function emitirEvento(evento, datos)
    if eventosContenedor[evento] then
        for _, callback in ipairs(eventosContenedor[evento]) do
            local exito, err = pcall(callback, datos)
            if not exito then
                print(string.format("[AIT.DI] Error en evento '%s': %s", evento, err))
            end
        end
    end
end

--- Valida que un nombre de servicio sea valido
--- @param nombre string Nombre a validar
--- @return boolean Es valido
local function validarNombreServicio(nombre)
    if type(nombre) ~= "string" or nombre == "" then
        return false
    end
    return true
end

--- Obtiene las dependencias de una funcion factory
--- @param factory function Funcion factory
--- @return table Lista de dependencias
local function obtenerDependencias(factory)
    -- Si el factory tiene metadatos de dependencias, usarlos
    if type(factory) == "table" and factory.__dependencias then
        return factory.__dependencias
    end
    return {}
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

-- ============================================================================
-- REGISTRO DE SERVICIOS
-- ============================================================================

--- Registra un servicio en el contenedor
--- @param nombre string Nombre del servicio
--- @param factory function|table Factory o instancia del servicio
--- @param opciones table Opciones de registro
--- @return table Self para encadenamiento
function Contenedor.registrar(nombre, factory, opciones)
    if not validarNombreServicio(nombre) then
        error(string.format("[AIT.DI] Nombre de servicio invalido: %s", tostring(nombre)))
    end

    opciones = opciones or {}

    local registro = {
        nombre = nombre,
        factory = factory,
        cicloVida = opciones.cicloVida or CicloVida.TRANSIENT,
        dependencias = opciones.dependencias or {},
        tags = opciones.tags or {},
        lazy = opciones.lazy or false,
        estado = EstadoServicio.REGISTRADO,
        metadata = opciones.metadata or {},
        inicializador = opciones.inicializador,
        finalizador = opciones.finalizador,
        validador = opciones.validador
    }

    -- Si es una instancia directa, marcar como singleton ya resuelto
    if type(factory) ~= "function" then
        registro.cicloVida = CicloVida.SINGLETON
        instanciasSingleton[nombre] = factory
        registro.estado = EstadoServicio.RESUELTO
    end

    registros[nombre] = registro

    -- Registrar en grupos por tags
    for _, tag in ipairs(registro.tags) do
        gruposServicios[tag] = gruposServicios[tag] or {}
        gruposServicios[tag][nombre] = true
    end

    registrarHistorial("registro", nombre, { cicloVida = registro.cicloVida })
    emitirEvento("servicio_registrado", { nombre = nombre, registro = registro })

    print(string.format("[AIT.DI] Servicio registrado: %s (%s)", nombre, registro.cicloVida))

    return Contenedor
end

--- Registra un servicio como singleton
--- @param nombre string Nombre del servicio
--- @param factory function|table Factory o instancia
--- @param opciones table Opciones adicionales
--- @return table Self para encadenamiento
function Contenedor.singleton(nombre, factory, opciones)
    opciones = opciones or {}
    opciones.cicloVida = CicloVida.SINGLETON
    return Contenedor.registrar(nombre, factory, opciones)
end

--- Registra un servicio como transient (nueva instancia cada vez)
--- @param nombre string Nombre del servicio
--- @param factory function Factory del servicio
--- @param opciones table Opciones adicionales
--- @return table Self para encadenamiento
function Contenedor.transient(nombre, factory, opciones)
    opciones = opciones or {}
    opciones.cicloVida = CicloVida.TRANSIENT
    return Contenedor.registrar(nombre, factory, opciones)
end

--- Registra un servicio con scope
--- @param nombre string Nombre del servicio
--- @param factory function Factory del servicio
--- @param opciones table Opciones adicionales
--- @return table Self para encadenamiento
function Contenedor.scoped(nombre, factory, opciones)
    opciones = opciones or {}
    opciones.cicloVida = CicloVida.SCOPED
    return Contenedor.registrar(nombre, factory, opciones)
end

--- Registra un alias para un servicio
--- @param alias string Nombre del alias
--- @param nombreOriginal string Nombre del servicio original
--- @return table Self para encadenamiento
function Contenedor.alias(alias, nombreOriginal)
    if not validarNombreServicio(alias) then
        error("[AIT.DI] Nombre de alias invalido")
    end

    aliasServicios[alias] = nombreOriginal
    print(string.format("[AIT.DI] Alias registrado: %s -> %s", alias, nombreOriginal))

    return Contenedor
end

--- Registra un servicio con carga diferida (lazy)
--- @param nombre string Nombre del servicio
--- @param factory function Factory del servicio
--- @param opciones table Opciones adicionales
--- @return table Self para encadenamiento
function Contenedor.lazy(nombre, factory, opciones)
    opciones = opciones or {}
    opciones.lazy = true

    serviciosLazy[nombre] = {
        factory = factory,
        opciones = opciones,
        cargado = false
    }

    print(string.format("[AIT.DI] Servicio lazy registrado: %s", nombre))

    return Contenedor
end

-- ============================================================================
-- RESOLUCION DE DEPENDENCIAS
-- ============================================================================

--- Resuelve un servicio del contenedor
--- @param nombre string Nombre del servicio
--- @param scopeId string ID del scope (opcional)
--- @return any Instancia del servicio
function Contenedor.resolver(nombre, scopeId)
    -- Resolver alias primero
    local nombreReal = aliasServicios[nombre] or nombre

    -- Verificar si es un servicio lazy no cargado
    if serviciosLazy[nombreReal] and not serviciosLazy[nombreReal].cargado then
        local lazyInfo = serviciosLazy[nombreReal]
        Contenedor.registrar(nombreReal, lazyInfo.factory, lazyInfo.opciones)
        serviciosLazy[nombreReal].cargado = true
        print(string.format("[AIT.DI] Servicio lazy cargado: %s", nombreReal))
    end

    local registro = registros[nombreReal]

    if not registro then
        error(string.format("[AIT.DI] Servicio no encontrado: %s", nombreReal))
    end

    -- Detectar dependencias circulares
    if estadoResolucion[nombreReal] == EstadoServicio.RESOLVIENDO then
        local cadena = table.concat(historialResolucion, " -> ")
        error(string.format("[AIT.DI] Dependencia circular detectada: %s. Cadena: %s", nombreReal, cadena))
    end

    -- Marcar como en resolucion
    estadoResolucion[nombreReal] = EstadoServicio.RESOLVIENDO

    local instancia

    -- Resolver segun ciclo de vida
    if registro.cicloVida == CicloVida.SINGLETON then
        instancia = Contenedor._resolverSingleton(nombreReal, registro)
    elseif registro.cicloVida == CicloVida.SCOPED then
        instancia = Contenedor._resolverScoped(nombreReal, registro, scopeId)
    else -- TRANSIENT
        instancia = Contenedor._resolverTransient(nombreReal, registro)
    end

    -- Aplicar decoradores
    instancia = Contenedor._aplicarDecoradores(nombreReal, instancia)

    -- Ejecutar interceptores
    instancia = Contenedor._ejecutarInterceptores(nombreReal, instancia)

    -- Marcar como resuelto
    estadoResolucion[nombreReal] = EstadoServicio.RESUELTO
    registro.estado = EstadoServicio.RESUELTO

    registrarHistorial("resolucion", nombreReal, { cicloVida = registro.cicloVida })
    emitirEvento("servicio_resuelto", { nombre = nombreReal, instancia = instancia })

    return instancia
end

--- Resuelve un servicio singleton
--- @param nombre string Nombre del servicio
--- @param registro table Registro del servicio
--- @return any Instancia del servicio
function Contenedor._resolverSingleton(nombre, registro)
    if instanciasSingleton[nombre] then
        return instanciasSingleton[nombre]
    end

    local instancia = Contenedor._crearInstancia(nombre, registro)
    instanciasSingleton[nombre] = instancia

    return instancia
end

--- Resuelve un servicio scoped
--- @param nombre string Nombre del servicio
--- @param registro table Registro del servicio
--- @param scopeId string ID del scope
--- @return any Instancia del servicio
function Contenedor._resolverScoped(nombre, registro, scopeId)
    if not scopeId then
        error(string.format("[AIT.DI] Se requiere scopeId para servicio scoped: %s", nombre))
    end

    local scope = scopesActivos[scopeId]
    if not scope then
        error(string.format("[AIT.DI] Scope no encontrado: %s", scopeId))
    end

    if scope.instancias[nombre] then
        return scope.instancias[nombre]
    end

    local instancia = Contenedor._crearInstancia(nombre, registro, scopeId)
    scope.instancias[nombre] = instancia

    return instancia
end

--- Resuelve un servicio transient
--- @param nombre string Nombre del servicio
--- @param registro table Registro del servicio
--- @return any Instancia del servicio
function Contenedor._resolverTransient(nombre, registro)
    return Contenedor._crearInstancia(nombre, registro)
end

--- Crea una nueva instancia de un servicio
--- @param nombre string Nombre del servicio
--- @param registro table Registro del servicio
--- @param scopeId string ID del scope (opcional)
--- @return any Nueva instancia
function Contenedor._crearInstancia(nombre, registro, scopeId)
    local factory = registro.factory

    -- Resolver dependencias
    local dependenciasResueltas = {}
    for _, depNombre in ipairs(registro.dependencias) do
        dependenciasResueltas[depNombre] = Contenedor.resolver(depNombre, scopeId)
    end

    -- Crear instancia
    local instancia
    if type(factory) == "function" then
        instancia = factory(dependenciasResueltas, Contenedor)
    else
        instancia = clonarProfundo(factory)
    end

    -- Validar instancia si hay validador
    if registro.validador then
        local valido, mensaje = registro.validador(instancia)
        if not valido then
            error(string.format("[AIT.DI] Validacion fallida para '%s': %s", nombre, mensaje or "desconocido"))
        end
    end

    -- Ejecutar inicializador si existe
    if registro.inicializador and type(instancia) == "table" then
        registro.inicializador(instancia)
    end

    return instancia
end

--- Intenta resolver un servicio, retorna nil si falla
--- @param nombre string Nombre del servicio
--- @param scopeId string ID del scope (opcional)
--- @return any|nil Instancia o nil
function Contenedor.intentarResolver(nombre, scopeId)
    local exito, resultado = pcall(function()
        return Contenedor.resolver(nombre, scopeId)
    end)

    if exito then
        return resultado
    end

    print(string.format("[AIT.DI] No se pudo resolver '%s': %s", nombre, resultado))
    return nil
end

--- Verifica si un servicio esta registrado
--- @param nombre string Nombre del servicio
--- @return boolean Esta registrado
function Contenedor.existe(nombre)
    local nombreReal = aliasServicios[nombre] or nombre
    return registros[nombreReal] ~= nil or serviciosLazy[nombreReal] ~= nil
end

-- ============================================================================
-- SCOPES
-- ============================================================================

--- Crea un nuevo scope
--- @param nombre string Nombre descriptivo del scope (opcional)
--- @return string ID del scope creado
function Contenedor.crearScope(nombre)
    local scopeId = generarIdScope()

    scopesActivos[scopeId] = {
        id = scopeId,
        nombre = nombre or "scope_anonimo",
        instancias = {},
        creado = os.time(),
        padre = nil
    }

    print(string.format("[AIT.DI] Scope creado: %s (%s)", scopeId, nombre or "anonimo"))
    emitirEvento("scope_creado", { scopeId = scopeId })

    return scopeId
end

--- Crea un scope hijo
--- @param scopePadreId string ID del scope padre
--- @param nombre string Nombre descriptivo
--- @return string ID del scope hijo
function Contenedor.crearScopeHijo(scopePadreId, nombre)
    if not scopesActivos[scopePadreId] then
        error(string.format("[AIT.DI] Scope padre no encontrado: %s", scopePadreId))
    end

    local scopeId = Contenedor.crearScope(nombre)
    scopesActivos[scopeId].padre = scopePadreId

    return scopeId
end

--- Destruye un scope y libera sus recursos
--- @param scopeId string ID del scope
function Contenedor.destruirScope(scopeId)
    local scope = scopesActivos[scopeId]

    if not scope then
        print(string.format("[AIT.DI] Scope no encontrado para destruir: %s", scopeId))
        return
    end

    -- Ejecutar finalizadores de instancias del scope
    for nombre, instancia in pairs(scope.instancias) do
        local registro = registros[nombre]
        if registro and registro.finalizador then
            local exito, err = pcall(registro.finalizador, instancia)
            if not exito then
                print(string.format("[AIT.DI] Error en finalizador de '%s': %s", nombre, err))
            end
        end
    end

    scopesActivos[scopeId] = nil

    print(string.format("[AIT.DI] Scope destruido: %s", scopeId))
    emitirEvento("scope_destruido", { scopeId = scopeId })
end

--- Obtiene informacion de un scope
--- @param scopeId string ID del scope
--- @return table|nil Informacion del scope
function Contenedor.obtenerScope(scopeId)
    return scopesActivos[scopeId]
end

-- ============================================================================
-- DECORADORES
-- ============================================================================

--- Registra un decorador para un servicio
--- @param nombreServicio string Nombre del servicio a decorar
--- @param decorador function Funcion decoradora
--- @param prioridad number Prioridad (menor = primero)
--- @return table Self para encadenamiento
function Contenedor.decorar(nombreServicio, decorador, prioridad)
    if type(decorador) ~= "function" then
        error("[AIT.DI] El decorador debe ser una funcion")
    end

    decoradores[nombreServicio] = decoradores[nombreServicio] or {}

    table.insert(decoradores[nombreServicio], {
        funcion = decorador,
        prioridad = prioridad or 100
    })

    -- Ordenar por prioridad
    table.sort(decoradores[nombreServicio], function(a, b)
        return a.prioridad < b.prioridad
    end)

    print(string.format("[AIT.DI] Decorador registrado para: %s", nombreServicio))

    return Contenedor
end

--- Aplica los decoradores a una instancia
--- @param nombre string Nombre del servicio
--- @param instancia any Instancia a decorar
--- @return any Instancia decorada
function Contenedor._aplicarDecoradores(nombre, instancia)
    local decos = decoradores[nombre]

    if not decos or #decos == 0 then
        return instancia
    end

    local resultado = instancia

    for _, deco in ipairs(decos) do
        local exito, nuevaInstancia = pcall(deco.funcion, resultado, Contenedor)
        if exito then
            resultado = nuevaInstancia or resultado
        else
            print(string.format("[AIT.DI] Error aplicando decorador a '%s': %s", nombre, nuevaInstancia))
        end
    end

    return resultado
end

-- ============================================================================
-- INTERCEPTORES
-- ============================================================================

--- Registra un interceptor global
--- @param callback function Funcion interceptora
--- @param filtro function Funcion de filtro (opcional)
--- @return table Self para encadenamiento
function Contenedor.interceptor(callback, filtro)
    if type(callback) ~= "function" then
        error("[AIT.DI] El interceptor debe ser una funcion")
    end

    table.insert(interceptores, {
        callback = callback,
        filtro = filtro
    })

    print("[AIT.DI] Interceptor registrado")

    return Contenedor
end

--- Ejecuta los interceptores sobre una instancia
--- @param nombre string Nombre del servicio
--- @param instancia any Instancia
--- @return any Instancia procesada
function Contenedor._ejecutarInterceptores(nombre, instancia)
    local resultado = instancia

    for _, interceptor in ipairs(interceptores) do
        -- Verificar filtro
        if not interceptor.filtro or interceptor.filtro(nombre, resultado) then
            local exito, nuevaInstancia = pcall(interceptor.callback, nombre, resultado, Contenedor)
            if exito then
                resultado = nuevaInstancia or resultado
            else
                print(string.format("[AIT.DI] Error en interceptor para '%s': %s", nombre, nuevaInstancia))
            end
        end
    end

    return resultado
end

-- ============================================================================
-- EVENTOS
-- ============================================================================

--- Suscribe a un evento del contenedor
--- @param evento string Nombre del evento
--- @param callback function Callback a ejecutar
--- @return function Funcion para desuscribirse
function Contenedor.on(evento, callback)
    if type(callback) ~= "function" then
        error("[AIT.DI] El callback debe ser una funcion")
    end

    eventosContenedor[evento] = eventosContenedor[evento] or {}
    table.insert(eventosContenedor[evento], callback)

    -- Retornar funcion de desuscripcion
    return function()
        for i, cb in ipairs(eventosContenedor[evento]) do
            if cb == callback then
                table.remove(eventosContenedor[evento], i)
                break
            end
        end
    end
end

-- ============================================================================
-- GRUPOS Y TAGS
-- ============================================================================

--- Resuelve todos los servicios con un tag especifico
--- @param tag string Tag a buscar
--- @param scopeId string ID del scope (opcional)
--- @return table Lista de instancias
function Contenedor.resolverPorTag(tag, scopeId)
    local grupo = gruposServicios[tag]

    if not grupo then
        return {}
    end

    local instancias = {}

    for nombre, _ in pairs(grupo) do
        local instancia = Contenedor.intentarResolver(nombre, scopeId)
        if instancia then
            instancias[nombre] = instancia
        end
    end

    return instancias
end

--- Obtiene todos los nombres de servicios con un tag
--- @param tag string Tag a buscar
--- @return table Lista de nombres
function Contenedor.obtenerPorTag(tag)
    local grupo = gruposServicios[tag]

    if not grupo then
        return {}
    end

    local nombres = {}
    for nombre, _ in pairs(grupo) do
        table.insert(nombres, nombre)
    end

    return nombres
end

-- ============================================================================
-- UTILIDADES
-- ============================================================================

--- Limpia todos los registros y cache
function Contenedor.limpiar()
    registros = {}
    instanciasSingleton = {}
    scopesActivos = {}
    decoradores = {}
    interceptores = {}
    aliasServicios = {}
    gruposServicios = {}
    estadoResolucion = {}
    historialResolucion = {}
    serviciosLazy = {}

    print("[AIT.DI] Contenedor limpiado completamente")
    emitirEvento("contenedor_limpiado", {})
end

--- Elimina un servicio especifico
--- @param nombre string Nombre del servicio
function Contenedor.eliminar(nombre)
    local nombreReal = aliasServicios[nombre] or nombre

    -- Ejecutar finalizador si existe
    local registro = registros[nombreReal]
    if registro and registro.finalizador and instanciasSingleton[nombreReal] then
        pcall(registro.finalizador, instanciasSingleton[nombreReal])
    end

    registros[nombreReal] = nil
    instanciasSingleton[nombreReal] = nil
    decoradores[nombreReal] = nil
    serviciosLazy[nombreReal] = nil

    -- Limpiar de grupos
    for tag, grupo in pairs(gruposServicios) do
        grupo[nombreReal] = nil
    end

    print(string.format("[AIT.DI] Servicio eliminado: %s", nombreReal))
end

--- Obtiene estadisticas del contenedor
--- @return table Estadisticas
function Contenedor.estadisticas()
    local totalServicios = 0
    local singletons = 0
    local transients = 0
    local scopeds = 0

    for _, registro in pairs(registros) do
        totalServicios = totalServicios + 1
        if registro.cicloVida == CicloVida.SINGLETON then
            singletons = singletons + 1
        elseif registro.cicloVida == CicloVida.TRANSIENT then
            transients = transients + 1
        else
            scopeds = scopeds + 1
        end
    end

    local scopesCount = 0
    for _ in pairs(scopesActivos) do
        scopesCount = scopesCount + 1
    end

    return {
        totalServicios = totalServicios,
        singletons = singletons,
        transients = transients,
        scopeds = scopeds,
        scopesActivos = scopesCount,
        decoradoresRegistrados = #decoradores,
        interceptoresRegistrados = #interceptores,
        serviciosLazy = #serviciosLazy,
        entradasHistorial = #historialResolucion
    }
end

--- Lista todos los servicios registrados
--- @return table Lista de servicios
function Contenedor.listar()
    local lista = {}

    for nombre, registro in pairs(registros) do
        table.insert(lista, {
            nombre = nombre,
            cicloVida = registro.cicloVida,
            estado = registro.estado,
            tags = registro.tags,
            dependencias = registro.dependencias
        })
    end

    return lista
end

--- Obtiene el historial de resolucion
--- @param limite number Numero maximo de entradas
--- @return table Historial
function Contenedor.obtenerHistorial(limite)
    limite = limite or 100
    local inicio = math.max(1, #historialResolucion - limite + 1)
    local resultado = {}

    for i = inicio, #historialResolucion do
        table.insert(resultado, historialResolucion[i])
    end

    return resultado
end

--- Valida las dependencias de todos los servicios
--- @return boolean, table Valido y lista de errores
function Contenedor.validarDependencias()
    local errores = {}

    for nombre, registro in pairs(registros) do
        for _, dep in ipairs(registro.dependencias) do
            if not Contenedor.existe(dep) then
                table.insert(errores, {
                    servicio = nombre,
                    dependencia = dep,
                    error = "Dependencia no encontrada"
                })
            end
        end
    end

    return #errores == 0, errores
end

-- ============================================================================
-- BUILDER PATTERN
-- ============================================================================

local ServiceBuilder = {}
ServiceBuilder.__index = ServiceBuilder

--- Crea un nuevo builder para un servicio
--- @param nombre string Nombre del servicio
--- @return table Builder
function Contenedor.crear(nombre)
    local builder = setmetatable({
        _nombre = nombre,
        _factory = nil,
        _cicloVida = CicloVida.TRANSIENT,
        _dependencias = {},
        _tags = {},
        _lazy = false,
        _metadata = {},
        _inicializador = nil,
        _finalizador = nil,
        _validador = nil
    }, ServiceBuilder)

    return builder
end

function ServiceBuilder:conFactory(factory)
    self._factory = factory
    return self
end

function ServiceBuilder:comoSingleton()
    self._cicloVida = CicloVida.SINGLETON
    return self
end

function ServiceBuilder:comoTransient()
    self._cicloVida = CicloVida.TRANSIENT
    return self
end

function ServiceBuilder:comoScoped()
    self._cicloVida = CicloVida.SCOPED
    return self
end

function ServiceBuilder:conDependencias(...)
    for _, dep in ipairs({...}) do
        table.insert(self._dependencias, dep)
    end
    return self
end

function ServiceBuilder:conTags(...)
    for _, tag in ipairs({...}) do
        table.insert(self._tags, tag)
    end
    return self
end

function ServiceBuilder:lazy()
    self._lazy = true
    return self
end

function ServiceBuilder:conMetadata(key, valor)
    self._metadata[key] = valor
    return self
end

function ServiceBuilder:conInicializador(fn)
    self._inicializador = fn
    return self
end

function ServiceBuilder:conFinalizador(fn)
    self._finalizador = fn
    return self
end

function ServiceBuilder:conValidador(fn)
    self._validador = fn
    return self
end

function ServiceBuilder:construir()
    if not self._factory then
        error(string.format("[AIT.DI] Factory requerido para servicio: %s", self._nombre))
    end

    return Contenedor.registrar(self._nombre, self._factory, {
        cicloVida = self._cicloVida,
        dependencias = self._dependencias,
        tags = self._tags,
        lazy = self._lazy,
        metadata = self._metadata,
        inicializador = self._inicializador,
        finalizador = self._finalizador,
        validador = self._validador
    })
end

-- ============================================================================
-- EXPORTAR CONSTANTES
-- ============================================================================

Contenedor.CicloVida = CicloVida
Contenedor.EstadoServicio = EstadoServicio

-- ============================================================================
-- ASIGNAR AL NAMESPACE GLOBAL
-- ============================================================================

AIT.DI = Contenedor

-- ============================================================================
-- EJEMPLOS DE USO (COMENTADOS)
-- ============================================================================

--[[
-- Registro basico de singleton
AIT.DI.singleton("Logger", function()
    return {
        info = function(msg) print("[INFO] " .. msg) end,
        error = function(msg) print("[ERROR] " .. msg) end
    }
end)

-- Registro con dependencias
AIT.DI.singleton("ServicioJugador", function(deps)
    local logger = deps.Logger
    return {
        obtenerJugador = function(id)
            logger.info("Obteniendo jugador: " .. id)
            return { id = id, nombre = "Jugador " .. id }
        end
    }
end, {
    dependencias = { "Logger" }
})

-- Uso del builder
AIT.DI.crear("ServicioVehiculos")
    :conFactory(function(deps)
        return {
            spawneaVehiculo = function(modelo)
                deps.Logger.info("Spawneando: " .. modelo)
            end
        }
    end)
    :comoSingleton()
    :conDependencias("Logger")
    :conTags("vehiculos", "core")
    :construir()

-- Resolver servicios
local logger = AIT.DI.resolver("Logger")
local jugadorService = AIT.DI.resolver("ServicioJugador")

-- Scopes
local scopeId = AIT.DI.crearScope("sesion_jugador_1")
local servicio = AIT.DI.resolver("ServicioScoped", scopeId)
AIT.DI.destruirScope(scopeId)

-- Decoradores
AIT.DI.decorar("Logger", function(instancia)
    local infoOriginal = instancia.info
    instancia.info = function(msg)
        infoOriginal("[" .. os.date() .. "] " .. msg)
    end
    return instancia
end)
]]

return AIT.DI
