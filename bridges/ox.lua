--[[
    ╔═══════════════════════════════════════════════════════════════════════════════╗
    ║                           AIT FRAMEWORK - OX_LIB BRIDGE                       ║
    ║                        Sistema de Compatibilidad ox_lib                       ║
    ║                                   Versión 1.0.0                               ║
    ╚═══════════════════════════════════════════════════════════════════════════════╝

    Bridge completo para integración con ox_lib
    Proporciona wrapper de todas las funciones ox con namespace AIT.Bridges.Ox

    Características:
    - Sistema de notificaciones
    - Menús contextuales
    - Barras de progreso
    - Diálogos de entrada
    - Sistema de skillcheck
    - Alertas y confirmaciones
    - Zonas y puntos
--]]

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN DEL MÓDULO
-- ═══════════════════════════════════════════════════════════════════════════════

AIT = AIT or {}
AIT.Bridges = AIT.Bridges or {}
AIT.Bridges.Ox = {}

-- Verificar si estamos en servidor o cliente
local esServidor = IsDuplicityVersion()

-- Referencia a ox_lib
local lib = lib

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DEL BRIDGE
-- ═══════════════════════════════════════════════════════════════════════════════

AIT.Bridges.Ox.Config = {
    Debug = false,

    -- Configuración de notificaciones por defecto
    Notificaciones = {
        Posicion = 'top-right',          -- top, top-right, top-left, bottom, bottom-right, bottom-left
        Duracion = 5000,                  -- Duración en ms
        IconoExito = 'check',
        IconoError = 'xmark',
        IconoInfo = 'info',
        IconoAdvertencia = 'triangle-exclamation'
    },

    -- Configuración de progreso por defecto
    Progreso = {
        Posicion = 'bottom',
        UsarMini = false,
        DeshabilitarMovimiento = true,
        DeshabilitarCombate = true,
        DeshabilitarVehiculo = false
    },

    -- Configuración de menús
    Menus = {
        Posicion = 'top-left',
        DeshabilitarMovimiento = false
    }
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE UTILIDAD INTERNA
-- ═══════════════════════════════════════════════════════════════════════════════

--- Registra un mensaje en consola
---@param nivel string Nivel del log
---@param mensaje string Mensaje a registrar
---@param ... any Parámetros adicionales
local function Log(nivel, mensaje, ...)
    if not AIT.Bridges.Ox.Config.Debug and nivel == 'debug' then return end
    local prefijo = string.format('[AIT-Ox][%s]', string.upper(nivel))
    local mensajeFormateado = string.format(mensaje, ...)
    print(string.format('%s %s', prefijo, mensajeFormateado))
end

--- Valida si ox_lib está disponible
---@return boolean
local function ValidarOx()
    if not lib then
        Log('error', 'ox_lib no está disponible')
        return false
    end
    return true
end

--- Convierte posición de español a inglés
---@param posicion string Posición en español
---@return string Posición en inglés
local function ConvertirPosicion(posicion)
    local mapeo = {
        ['arriba'] = 'top',
        ['arriba-derecha'] = 'top-right',
        ['arriba-izquierda'] = 'top-left',
        ['abajo'] = 'bottom',
        ['abajo-derecha'] = 'bottom-right',
        ['abajo-izquierda'] = 'bottom-left',
        ['centro'] = 'center',
        ['centro-derecha'] = 'center-right',
        ['centro-izquierda'] = 'center-left'
    }
    return mapeo[posicion] or posicion
end

--- Convierte tipo de notificación
---@param tipo string Tipo en español
---@return string Tipo en inglés
local function ConvertirTipoNotificacion(tipo)
    local mapeo = {
        ['exito'] = 'success',
        ['error'] = 'error',
        ['info'] = 'inform',
        ['advertencia'] = 'warning',
        ['aviso'] = 'warning'
    }
    return mapeo[tipo] or tipo
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════════════

--- Muestra una notificación
---@param opciones table Opciones de la notificación
function AIT.Bridges.Ox.Notificar(opciones)
    if not ValidarOx() then return end
    if esServidor then
        Log('error', 'Las notificaciones solo funcionan en cliente')
        return
    end

    local config = AIT.Bridges.Ox.Config.Notificaciones

    lib.notify({
        id = opciones.id,
        title = opciones.titulo,
        description = opciones.descripcion or opciones.mensaje,
        duration = opciones.duracion or config.Duracion,
        position = ConvertirPosicion(opciones.posicion or config.Posicion),
        type = ConvertirTipoNotificacion(opciones.tipo or 'info'),
        style = opciones.estilo,
        icon = opciones.icono,
        iconColor = opciones.colorIcono
    })
end

--- Muestra notificación de éxito
---@param titulo string Título
---@param mensaje string Mensaje
---@param duracion number|nil Duración
function AIT.Bridges.Ox.NotificarExito(titulo, mensaje, duracion)
    AIT.Bridges.Ox.Notificar({
        titulo = titulo,
        mensaje = mensaje,
        tipo = 'exito',
        duracion = duracion,
        icono = AIT.Bridges.Ox.Config.Notificaciones.IconoExito
    })
end

--- Muestra notificación de error
---@param titulo string Título
---@param mensaje string Mensaje
---@param duracion number|nil Duración
function AIT.Bridges.Ox.NotificarError(titulo, mensaje, duracion)
    AIT.Bridges.Ox.Notificar({
        titulo = titulo,
        mensaje = mensaje,
        tipo = 'error',
        duracion = duracion,
        icono = AIT.Bridges.Ox.Config.Notificaciones.IconoError
    })
end

--- Muestra notificación de información
---@param titulo string Título
---@param mensaje string Mensaje
---@param duracion number|nil Duración
function AIT.Bridges.Ox.NotificarInfo(titulo, mensaje, duracion)
    AIT.Bridges.Ox.Notificar({
        titulo = titulo,
        mensaje = mensaje,
        tipo = 'info',
        duracion = duracion,
        icono = AIT.Bridges.Ox.Config.Notificaciones.IconoInfo
    })
end

--- Muestra notificación de advertencia
---@param titulo string Título
---@param mensaje string Mensaje
---@param duracion number|nil Duración
function AIT.Bridges.Ox.NotificarAdvertencia(titulo, mensaje, duracion)
    AIT.Bridges.Ox.Notificar({
        titulo = titulo,
        mensaje = mensaje,
        tipo = 'advertencia',
        duracion = duracion,
        icono = AIT.Bridges.Ox.Config.Notificaciones.IconoAdvertencia
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE MENÚS CONTEXTUALES
-- ═══════════════════════════════════════════════════════════════════════════════

--- Registra un menú contextual
---@param id string ID del menú
---@param opciones table Opciones del menú
function AIT.Bridges.Ox.RegistrarMenu(id, opciones)
    if not ValidarOx() then return end
    if esServidor then return end

    local opcionesConvertidas = {}

    for i, opcion in ipairs(opciones.opciones or opciones.options or {}) do
        local opcionConvertida = {
            title = opcion.titulo or opcion.title,
            description = opcion.descripcion or opcion.description,
            icon = opcion.icono or opcion.icon,
            iconColor = opcion.colorIcono or opcion.iconColor,
            arrow = opcion.flecha or opcion.arrow,
            progress = opcion.progreso or opcion.progress,
            colorScheme = opcion.esquemaColor or opcion.colorScheme,
            disabled = opcion.deshabilitado or opcion.disabled,
            readOnly = opcion.soloLectura or opcion.readOnly,
            metadata = opcion.metadata,
            event = opcion.evento or opcion.event,
            serverEvent = opcion.eventoServidor or opcion.serverEvent,
            args = opcion.argumentos or opcion.args,
            onSelect = opcion.alSeleccionar or opcion.onSelect
        }
        table.insert(opcionesConvertidas, opcionConvertida)
    end

    lib.registerContext({
        id = id,
        title = opciones.titulo or opciones.title,
        menu = opciones.menuPadre or opciones.menu,
        onExit = opciones.alSalir or opciones.onExit,
        onBack = opciones.alVolver or opciones.onBack,
        options = opcionesConvertidas
    })

    Log('debug', 'Menú contextual registrado: %s', id)
end

--- Muestra un menú contextual
---@param id string ID del menú
function AIT.Bridges.Ox.MostrarMenu(id)
    if not ValidarOx() then return end
    if esServidor then return end

    lib.showContext(id)
end

--- Oculta el menú contextual actual
function AIT.Bridges.Ox.OcultarMenu()
    if not ValidarOx() then return end
    if esServidor then return end

    lib.hideContext()
end

--- Obtiene el menú contextual activo
---@return string|nil ID del menú activo
function AIT.Bridges.Ox.ObtenerMenuActivo()
    if not ValidarOx() then return nil end
    if esServidor then return nil end

    return lib.getOpenContextMenu()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE BARRAS DE PROGRESO
-- ═══════════════════════════════════════════════════════════════════════════════

--- Muestra una barra de progreso
---@param opciones table Opciones del progreso
---@return boolean Completado exitosamente
function AIT.Bridges.Ox.Progreso(opciones)
    if not ValidarOx() then return false end
    if esServidor then return false end

    local config = AIT.Bridges.Ox.Config.Progreso

    local resultado = lib.progressBar({
        duration = opciones.duracion or opciones.duration or 5000,
        label = opciones.etiqueta or opciones.label or 'Procesando...',
        useWhileDead = opciones.usarMuerto or opciones.useWhileDead or false,
        allowRagdoll = opciones.permitirRagdoll or opciones.allowRagdoll or false,
        allowCuffed = opciones.permitirEsposado or opciones.allowCuffed or false,
        allowFalling = opciones.permitirCaida or opciones.allowFalling or false,
        canCancel = opciones.cancelable or opciones.canCancel or true,
        position = ConvertirPosicion(opciones.posicion or config.Posicion),
        anim = opciones.animacion and {
            dict = opciones.animacion.diccionario or opciones.animacion.dict,
            clip = opciones.animacion.clip,
            flag = opciones.animacion.bandera or opciones.animacion.flag or 49
        } or nil,
        prop = opciones.prop and {
            model = opciones.prop.modelo or opciones.prop.model,
            bone = opciones.prop.hueso or opciones.prop.bone,
            pos = opciones.prop.posicion or opciones.prop.pos,
            rot = opciones.prop.rotacion or opciones.prop.rot
        } or nil,
        disable = {
            move = opciones.deshabilitar and opciones.deshabilitar.movimiento or config.DeshabilitarMovimiento,
            car = opciones.deshabilitar and opciones.deshabilitar.vehiculo or config.DeshabilitarVehiculo,
            combat = opciones.deshabilitar and opciones.deshabilitar.combate or config.DeshabilitarCombate,
            mouse = opciones.deshabilitar and opciones.deshabilitar.raton or false
        }
    })

    return resultado
end

--- Muestra una barra de progreso circular (mini)
---@param opciones table Opciones del progreso
---@return boolean Completado exitosamente
function AIT.Bridges.Ox.ProgresoCircular(opciones)
    if not ValidarOx() then return false end
    if esServidor then return false end

    local resultado = lib.progressCircle({
        duration = opciones.duracion or opciones.duration or 5000,
        label = opciones.etiqueta or opciones.label,
        position = ConvertirPosicion(opciones.posicion or 'bottom'),
        useWhileDead = opciones.usarMuerto or false,
        allowRagdoll = opciones.permitirRagdoll or false,
        allowCuffed = opciones.permitirEsposado or false,
        allowFalling = opciones.permitirCaida or false,
        canCancel = opciones.cancelable or true,
        anim = opciones.animacion,
        prop = opciones.prop,
        disable = opciones.deshabilitar
    })

    return resultado
end

--- Cancela la barra de progreso activa
function AIT.Bridges.Ox.CancelarProgreso()
    if not ValidarOx() then return end
    if esServidor then return end

    lib.cancelProgress()
end

--- Verifica si hay un progreso activo
---@return boolean
function AIT.Bridges.Ox.ProgresoActivo()
    if not ValidarOx() then return false end
    if esServidor then return false end

    return lib.progressActive()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE DIÁLOGOS DE ENTRADA
-- ═══════════════════════════════════════════════════════════════════════════════

--- Muestra un diálogo de entrada
---@param titulo string Título del diálogo
---@param campos table Campos del formulario
---@return table|nil Valores ingresados
function AIT.Bridges.Ox.DialogoEntrada(titulo, campos)
    if not ValidarOx() then return nil end
    if esServidor then return nil end

    local camposConvertidos = {}

    for i, campo in ipairs(campos) do
        local campoConvertido = {
            type = campo.tipo or campo.type or 'input',
            label = campo.etiqueta or campo.label,
            description = campo.descripcion or campo.description,
            placeholder = campo.placeholder,
            icon = campo.icono or campo.icon,
            required = campo.requerido or campo.required or false,
            disabled = campo.deshabilitado or campo.disabled or false,
            default = campo.defecto or campo.default,
            password = campo.contrasena or campo.password or false,
            min = campo.minimo or campo.min,
            max = campo.maximo or campo.max,
            step = campo.paso or campo.step,
            options = campo.opciones or campo.options,
            format = campo.formato or campo.format,
            returnString = campo.retornarString or campo.returnString,
            clearable = campo.limpiable or campo.clearable,
            autosize = campo.autoajustar or campo.autosize
        }
        table.insert(camposConvertidos, campoConvertido)
    end

    local resultado = lib.inputDialog(titulo, camposConvertidos)

    if resultado then
        Log('debug', 'Diálogo completado: %s', titulo)
    else
        Log('debug', 'Diálogo cancelado: %s', titulo)
    end

    return resultado
end

--- Muestra un diálogo de texto simple
---@param titulo string Título
---@param etiqueta string Etiqueta del campo
---@param placeholder string|nil Placeholder
---@return string|nil Texto ingresado
function AIT.Bridges.Ox.DialogoTexto(titulo, etiqueta, placeholder)
    local resultado = AIT.Bridges.Ox.DialogoEntrada(titulo, {
        { tipo = 'input', etiqueta = etiqueta, placeholder = placeholder }
    })
    return resultado and resultado[1] or nil
end

--- Muestra un diálogo numérico
---@param titulo string Título
---@param etiqueta string Etiqueta del campo
---@param minimo number|nil Valor mínimo
---@param maximo number|nil Valor máximo
---@return number|nil Número ingresado
function AIT.Bridges.Ox.DialogoNumero(titulo, etiqueta, minimo, maximo)
    local resultado = AIT.Bridges.Ox.DialogoEntrada(titulo, {
        { tipo = 'number', etiqueta = etiqueta, minimo = minimo, maximo = maximo }
    })
    return resultado and resultado[1] or nil
end

--- Muestra un diálogo de selección
---@param titulo string Título
---@param etiqueta string Etiqueta
---@param opciones table Opciones disponibles
---@return string|nil Opción seleccionada
function AIT.Bridges.Ox.DialogoSeleccion(titulo, etiqueta, opciones)
    local opcionesFormateadas = {}

    for _, opcion in ipairs(opciones) do
        if type(opcion) == 'table' then
            table.insert(opcionesFormateadas, {
                value = opcion.valor or opcion.value,
                label = opcion.etiqueta or opcion.label or opcion.valor or opcion.value
            })
        else
            table.insert(opcionesFormateadas, {
                value = opcion,
                label = opcion
            })
        end
    end

    local resultado = AIT.Bridges.Ox.DialogoEntrada(titulo, {
        { tipo = 'select', etiqueta = etiqueta, opciones = opcionesFormateadas }
    })

    return resultado and resultado[1] or nil
end

--- Cierra el diálogo de entrada activo
function AIT.Bridges.Ox.CerrarDialogo()
    if not ValidarOx() then return end
    if esServidor then return end

    lib.closeInputDialog()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE SKILLCHECK
-- ═══════════════════════════════════════════════════════════════════════════════

--- Ejecuta un skillcheck
---@param dificultad string|table Dificultad o lista de dificultades
---@param teclas string|table|nil Teclas permitidas
---@return boolean Éxito del skillcheck
function AIT.Bridges.Ox.Skillcheck(dificultad, teclas)
    if not ValidarOx() then return false end
    if esServidor then return false end

    -- Mapeo de dificultades en español
    local mapeoDificultad = {
        ['facil'] = 'easy',
        ['normal'] = 'medium',
        ['dificil'] = 'hard',
        ['muydificil'] = 'legendary'
    }

    -- Convertir dificultad
    local dificultadConvertida
    if type(dificultad) == 'table' then
        dificultadConvertida = {}
        for _, d in ipairs(dificultad) do
            table.insert(dificultadConvertida, mapeoDificultad[d] or d)
        end
    else
        dificultadConvertida = mapeoDificultad[dificultad] or dificultad
    end

    local resultado = lib.skillCheck(dificultadConvertida, teclas)

    Log('debug', 'Skillcheck resultado: %s', tostring(resultado))

    return resultado
end

--- Ejecuta un skillcheck fácil
---@return boolean
function AIT.Bridges.Ox.SkillcheckFacil()
    return AIT.Bridges.Ox.Skillcheck('facil')
end

--- Ejecuta un skillcheck normal
---@return boolean
function AIT.Bridges.Ox.SkillcheckNormal()
    return AIT.Bridges.Ox.Skillcheck('normal')
end

--- Ejecuta un skillcheck difícil
---@return boolean
function AIT.Bridges.Ox.SkillcheckDificil()
    return AIT.Bridges.Ox.Skillcheck('dificil')
end

--- Ejecuta un skillcheck muy difícil
---@return boolean
function AIT.Bridges.Ox.SkillcheckMuyDificil()
    return AIT.Bridges.Ox.Skillcheck('muydificil')
end

--- Ejecuta un skillcheck múltiple
---@param cantidad number Cantidad de skillchecks
---@param dificultad string Dificultad
---@return boolean Todos exitosos
function AIT.Bridges.Ox.SkillcheckMultiple(cantidad, dificultad)
    for i = 1, cantidad do
        if not AIT.Bridges.Ox.Skillcheck(dificultad) then
            return false
        end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE ALERTAS Y CONFIRMACIONES
-- ═══════════════════════════════════════════════════════════════════════════════

--- Muestra un diálogo de alerta
---@param opciones table Opciones de la alerta
---@return string Botón presionado
function AIT.Bridges.Ox.Alerta(opciones)
    if not ValidarOx() then return 'cancel' end
    if esServidor then return 'cancel' end

    local resultado = lib.alertDialog({
        header = opciones.titulo or opciones.header,
        content = opciones.contenido or opciones.content,
        centered = opciones.centrado or opciones.centered or true,
        cancel = opciones.cancelar or opciones.cancel or true,
        size = opciones.tamano or opciones.size,
        overflow = opciones.overflow,
        labels = {
            cancel = opciones.etiquetaCancelar or 'Cancelar',
            confirm = opciones.etiquetaConfirmar or 'Confirmar'
        }
    })

    return resultado
end

--- Muestra un diálogo de confirmación
---@param titulo string Título
---@param mensaje string Mensaje
---@return boolean Confirmado
function AIT.Bridges.Ox.Confirmar(titulo, mensaje)
    local resultado = AIT.Bridges.Ox.Alerta({
        titulo = titulo,
        contenido = mensaje,
        cancelar = true
    })

    return resultado == 'confirm'
end

--- Muestra un diálogo de información
---@param titulo string Título
---@param mensaje string Mensaje
function AIT.Bridges.Ox.MostrarInfo(titulo, mensaje)
    AIT.Bridges.Ox.Alerta({
        titulo = titulo,
        contenido = mensaje,
        cancelar = false
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE ZONAS Y PUNTOS
-- ═══════════════════════════════════════════════════════════════════════════════

--- Crea una zona de caja
---@param opciones table Opciones de la zona
---@return table Objeto zona
function AIT.Bridges.Ox.CrearZonaCaja(opciones)
    if not ValidarOx() then return nil end
    if esServidor then return nil end

    local zona = lib.zones.box({
        coords = opciones.coordenadas or opciones.coords,
        size = opciones.tamano or opciones.size,
        rotation = opciones.rotacion or opciones.rotation or 0,
        debug = opciones.debug or AIT.Bridges.Ox.Config.Debug,
        inside = opciones.dentroCallback or opciones.inside,
        onEnter = opciones.alEntrar or opciones.onEnter,
        onExit = opciones.alSalir or opciones.onExit
    })

    Log('debug', 'Zona caja creada')

    return zona
end

--- Crea una zona esférica
---@param opciones table Opciones de la zona
---@return table Objeto zona
function AIT.Bridges.Ox.CrearZonaEsfera(opciones)
    if not ValidarOx() then return nil end
    if esServidor then return nil end

    local zona = lib.zones.sphere({
        coords = opciones.coordenadas or opciones.coords,
        radius = opciones.radio or opciones.radius,
        debug = opciones.debug or AIT.Bridges.Ox.Config.Debug,
        inside = opciones.dentroCallback or opciones.inside,
        onEnter = opciones.alEntrar or opciones.onEnter,
        onExit = opciones.alSalir or opciones.onExit
    })

    Log('debug', 'Zona esfera creada con radio %d', opciones.radio or opciones.radius)

    return zona
end

--- Crea una zona poligonal
---@param opciones table Opciones de la zona
---@return table Objeto zona
function AIT.Bridges.Ox.CrearZonaPoligono(opciones)
    if not ValidarOx() then return nil end
    if esServidor then return nil end

    local zona = lib.zones.poly({
        points = opciones.puntos or opciones.points,
        thickness = opciones.grosor or opciones.thickness,
        debug = opciones.debug or AIT.Bridges.Ox.Config.Debug,
        inside = opciones.dentroCallback or opciones.inside,
        onEnter = opciones.alEntrar or opciones.onEnter,
        onExit = opciones.alSalir or opciones.onExit
    })

    Log('debug', 'Zona polígono creada')

    return zona
end

--- Crea un punto de interés
---@param opciones table Opciones del punto
---@return table Objeto punto
function AIT.Bridges.Ox.CrearPunto(opciones)
    if not ValidarOx() then return nil end
    if esServidor then return nil end

    local punto = lib.points.new({
        coords = opciones.coordenadas or opciones.coords,
        distance = opciones.distancia or opciones.distance,
        onEnter = opciones.alEntrar or opciones.onEnter,
        onExit = opciones.alSalir or opciones.onExit,
        nearby = opciones.cercaCallback or opciones.nearby
    })

    Log('debug', 'Punto creado')

    return punto
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE TEXTO DE AYUDA
-- ═══════════════════════════════════════════════════════════════════════════════

--- Muestra texto de ayuda
---@param texto string Texto a mostrar
---@param posicion string|nil Posición
function AIT.Bridges.Ox.MostrarTextoAyuda(texto, posicion)
    if not ValidarOx() then return end
    if esServidor then return end

    lib.showTextUI(texto, {
        position = ConvertirPosicion(posicion or 'right-center'),
        icon = 'circle-info'
    })
end

--- Oculta el texto de ayuda
function AIT.Bridges.Ox.OcultarTextoAyuda()
    if not ValidarOx() then return end
    if esServidor then return end

    lib.hideTextUI()
end

--- Verifica si el texto de ayuda está visible
---@return boolean
function AIT.Bridges.Ox.TextoAyudaVisible()
    if not ValidarOx() then return false end
    if esServidor then return false end

    return lib.isTextUIOpen()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════════

--- Registra un callback
---@param nombre string Nombre del callback
---@param callback function Función del callback
function AIT.Bridges.Ox.RegistrarCallback(nombre, callback)
    if not ValidarOx() then return end

    lib.callback.register(nombre, callback)
    Log('debug', 'Callback registrado: %s', nombre)
end

--- Llama a un callback del servidor (desde cliente)
---@param nombre string Nombre del callback
---@param ... any Argumentos
---@return any Resultado
function AIT.Bridges.Ox.LlamarCallback(nombre, ...)
    if not ValidarOx() then return nil end
    if esServidor then
        Log('error', 'LlamarCallback es para cliente')
        return nil
    end

    return lib.callback.await(nombre, false, ...)
end

--- Llama a un callback de forma síncrona
---@param nombre string Nombre del callback
---@param ... any Argumentos
---@return any Resultado
function AIT.Bridges.Ox.CallbackSincrono(nombre, ...)
    if not ValidarOx() then return nil end

    return lib.callback.await(nombre, false, ...)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE STREAMING
-- ═══════════════════════════════════════════════════════════════════════════════

--- Solicita un modelo
---@param modelo string|number Modelo a cargar
---@param timeout number|nil Tiempo máximo en ms
---@return boolean Éxito
function AIT.Bridges.Ox.SolicitarModelo(modelo, timeout)
    if not ValidarOx() then return false end

    return lib.requestModel(modelo, timeout or 5000)
end

--- Solicita un diccionario de animaciones
---@param diccionario string Diccionario a cargar
---@param timeout number|nil Tiempo máximo en ms
---@return boolean Éxito
function AIT.Bridges.Ox.SolicitarAnimacion(diccionario, timeout)
    if not ValidarOx() then return false end

    return lib.requestAnimDict(diccionario, timeout or 5000)
end

--- Solicita un set de animaciones
---@param setAnim string Set de animaciones
---@param timeout number|nil Tiempo máximo en ms
---@return boolean Éxito
function AIT.Bridges.Ox.SolicitarSetAnimacion(setAnim, timeout)
    if not ValidarOx() then return false end

    return lib.requestAnimSet(setAnim, timeout or 5000)
end

--- Solicita un asset de partículas
---@param diccionario string Diccionario de partículas
---@param timeout number|nil Tiempo máximo en ms
---@return boolean Éxito
function AIT.Bridges.Ox.SolicitarParticulas(diccionario, timeout)
    if not ValidarOx() then return false end

    return lib.requestNamedPtfxAsset(diccionario, timeout or 5000)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE RADIAL MENU
-- ═══════════════════════════════════════════════════════════════════════════════

--- Registra un item del menú radial
---@param opciones table Opciones del item
function AIT.Bridges.Ox.RegistrarItemRadial(opciones)
    if not ValidarOx() then return end
    if esServidor then return end

    lib.addRadialItem({
        id = opciones.id,
        icon = opciones.icono or opciones.icon,
        label = opciones.etiqueta or opciones.label,
        menu = opciones.submenu or opciones.menu,
        onSelect = opciones.alSeleccionar or opciones.onSelect
    })

    Log('debug', 'Item radial registrado: %s', opciones.id)
end

--- Elimina un item del menú radial
---@param id string ID del item
function AIT.Bridges.Ox.EliminarItemRadial(id)
    if not ValidarOx() then return end
    if esServidor then return end

    lib.removeRadialItem(id)
    Log('debug', 'Item radial eliminado: %s', id)
end

--- Limpia todos los items del menú radial
function AIT.Bridges.Ox.LimpiarMenuRadial()
    if not ValidarOx() then return end
    if esServidor then return end

    lib.clearRadialItems()
end

--- Muestra/oculta el menú radial
---@param mostrar boolean|nil Mostrar u ocultar
function AIT.Bridges.Ox.AlternarMenuRadial(mostrar)
    if not ValidarOx() then return end
    if esServidor then return end

    if mostrar then
        lib.showRadial()
    else
        lib.hideRadial()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- UTILIDADES ADICIONALES
-- ═══════════════════════════════════════════════════════════════════════════════

--- Espera una condición
---@param condicion function Función que retorna boolean
---@param mensaje string|nil Mensaje de error
---@param timeout number|nil Tiempo máximo
---@return boolean Condición cumplida
function AIT.Bridges.Ox.EsperarCondicion(condicion, mensaje, timeout)
    if not ValidarOx() then return false end

    return lib.waitFor(condicion, mensaje, timeout or 5000)
end

--- Imprime una tabla formateada
---@param tabla table Tabla a imprimir
function AIT.Bridges.Ox.ImprimirTabla(tabla)
    if not ValidarOx() then return end

    lib.print.table(tabla)
end

--- Obtiene el tiempo de juego
---@return number Tiempo en ms
function AIT.Bridges.Ox.ObtenerTiempoJuego()
    return GetGameTimer()
end

--- Genera un UUID
---@return string UUID generado
function AIT.Bridges.Ox.GenerarUUID()
    if not ValidarOx() then
        return string.format('%s-%s-%s-%s-%s',
            string.format('%04x', math.random(0, 0xffff)),
            string.format('%04x', math.random(0, 0xffff)),
            string.format('%04x', math.random(0, 0x0fff) + 0x4000),
            string.format('%04x', math.random(0, 0x3fff) + 0x8000),
            string.format('%06x', math.random(0, 0xffffff)) .. string.format('%06x', math.random(0, 0xffffff))
        )
    end

    return lib.uuid()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EXPORTAR MÓDULO
-- ═══════════════════════════════════════════════════════════════════════════════

exports('GetOxBridge', function()
    return AIT.Bridges.Ox
end)

Log('info', 'Bridge Ox cargado correctamente')

return AIT.Bridges.Ox
