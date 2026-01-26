--[[
    AIT Framework - Schemas de Validacion
    Archivo: shared/schemas/init.lua

    Define los esquemas de validacion para todas las estructuras
    de datos del framework, asegurando integridad y consistencia.

    Uso: AIT.Schemas.Validar(AIT.Schemas.Jugador, datos)
]]

-- ============================================================================
-- INICIALIZACION
-- ============================================================================

AIT = AIT or {}
AIT.Schemas = AIT.Schemas or {}

-- ============================================================================
-- TIPOS DE VALIDACION
-- ============================================================================

--- Tipos de datos soportados para validacion
AIT.Schemas.Tipos = {
    STRING = 'string',
    NUMBER = 'number',
    BOOLEAN = 'boolean',
    TABLE = 'table',
    FUNCTION = 'function',
    NIL = 'nil',
    ANY = 'any',
}

-- ============================================================================
-- SCHEMA: JUGADOR
-- ============================================================================

--- Schema para datos del jugador conectado
---@class SchemaJugador
AIT.Schemas.Jugador = {
    license = { tipo = 'string', requerido = true, descripcion = 'Licencia de Rockstar/Steam' },
    steam = { tipo = 'string', requerido = false, descripcion = 'SteamID del jugador' },
    discord = { tipo = 'string', requerido = false, descripcion = 'ID de Discord' },
    ip = { tipo = 'string', requerido = false, descripcion = 'Direccion IP (servidor)' },
    nombre = { tipo = 'string', requerido = true, descripcion = 'Nombre de usuario' },
    permisos = { tipo = 'number', requerido = true, defecto = 0, descripcion = 'Nivel de permisos' },
    vip = { tipo = 'boolean', requerido = false, defecto = false, descripcion = 'Estado VIP' },
    baneado = { tipo = 'boolean', requerido = false, defecto = false, descripcion = 'Estado de ban' },
    fecha_registro = { tipo = 'number', requerido = true, descripcion = 'Timestamp de registro' },
    ultimo_acceso = { tipo = 'number', requerido = false, descripcion = 'Ultimo acceso' },
}

-- ============================================================================
-- SCHEMA: PERSONAJE
-- ============================================================================

--- Schema para datos del personaje
---@class SchemaPersonaje
AIT.Schemas.Personaje = {
    citizenid = { tipo = 'string', requerido = true, longitud = 8, descripcion = 'ID unico del ciudadano' },
    license = { tipo = 'string', requerido = true, descripcion = 'Licencia del jugador propietario' },
    nombre = { tipo = 'string', requerido = true, min = 2, max = 50, descripcion = 'Nombre del personaje' },
    apellido = { tipo = 'string', requerido = true, min = 2, max = 50, descripcion = 'Apellido del personaje' },
    fecha_nacimiento = { tipo = 'string', requerido = true, patron = '%d%d%d%d%-%d%d%-%d%d', descripcion = 'Fecha de nacimiento (YYYY-MM-DD)' },
    genero = { tipo = 'string', requerido = true, valores = {'masculino', 'femenino', 'otro'}, descripcion = 'Genero del personaje' },
    nacionalidad = { tipo = 'string', requerido = false, defecto = 'Los Santos', descripcion = 'Nacionalidad' },
    telefono = { tipo = 'string', requerido = false, longitud = 10, descripcion = 'Numero de telefono' },

    -- Cuentas monetarias
    cuentas = {
        tipo = 'table',
        requerido = true,
        schema = {
            efectivo = { tipo = 'number', requerido = true, min = 0, defecto = 500 },
            banco = { tipo = 'number', requerido = true, min = 0, defecto = 5000 },
            cripto = { tipo = 'number', requerido = false, min = 0, defecto = 0 },
            negro = { tipo = 'number', requerido = false, min = 0, defecto = 0 },
        },
        descripcion = 'Cuentas monetarias del personaje'
    },

    -- Trabajo
    trabajo = {
        tipo = 'table',
        requerido = true,
        schema = {
            nombre = { tipo = 'string', requerido = true, defecto = 'desempleado' },
            etiqueta = { tipo = 'string', requerido = true, defecto = 'Desempleado' },
            grado = { tipo = 'number', requerido = true, min = 0, defecto = 0 },
            grado_nombre = { tipo = 'string', requerido = true, defecto = 'Ninguno' },
            salario = { tipo = 'number', requerido = true, min = 0, defecto = 0 },
            en_servicio = { tipo = 'boolean', requerido = false, defecto = false },
        },
        descripcion = 'Informacion laboral'
    },

    -- Banda
    banda = {
        tipo = 'table',
        requerido = false,
        schema = {
            nombre = { tipo = 'string', requerido = false },
            etiqueta = { tipo = 'string', requerido = false },
            grado = { tipo = 'number', requerido = false, min = 0 },
            grado_nombre = { tipo = 'string', requerido = false },
        },
        descripcion = 'Informacion de banda criminal'
    },

    -- Metadata adicional
    metadata = {
        tipo = 'table',
        requerido = false,
        schema = {
            hambre = { tipo = 'number', min = 0, max = 100, defecto = 100 },
            sed = { tipo = 'number', min = 0, max = 100, defecto = 100 },
            estres = { tipo = 'number', min = 0, max = 100, defecto = 0 },
            salud = { tipo = 'number', min = 0, max = 200, defecto = 200 },
            armadura = { tipo = 'number', min = 0, max = 100, defecto = 0 },
            carcel = { tipo = 'number', min = 0, defecto = 0 },
            estado = { tipo = 'string', defecto = 'alive' },
        },
        descripcion = 'Metadatos del personaje'
    },

    -- Estado
    activo = { tipo = 'boolean', requerido = true, defecto = true, descripcion = 'Personaje activo' },
    fecha_creacion = { tipo = 'number', requerido = true, descripcion = 'Timestamp de creacion' },
    ultima_sesion = { tipo = 'number', requerido = false, descripcion = 'Ultima sesion jugada' },
}

-- ============================================================================
-- SCHEMA: VEHICULO
-- ============================================================================

--- Schema para datos de vehiculo
---@class SchemaVehiculo
AIT.Schemas.Vehiculo = {
    id = { tipo = 'number', requerido = false, descripcion = 'ID en base de datos' },
    plate = { tipo = 'string', requerido = true, min = 2, max = 8, descripcion = 'Matricula del vehiculo' },
    citizenid = { tipo = 'string', requerido = true, longitud = 8, descripcion = 'ID del propietario' },
    modelo = { tipo = 'string', requerido = true, descripcion = 'Nombre del modelo' },
    hash = { tipo = 'number', requerido = false, descripcion = 'Hash del modelo' },

    -- Garage y estado
    garaje = { tipo = 'string', requerido = true, defecto = 'legion', descripcion = 'Garaje asignado' },
    estado = { tipo = 'string', requerido = true, defecto = 'garaged', valores = {'garaged', 'out', 'impound', 'destroyed'}, descripcion = 'Estado del vehiculo' },
    deposito = { tipo = 'string', requerido = false, descripcion = 'Deposito si esta requisado' },

    -- Condicion
    combustible = { tipo = 'number', requerido = true, min = 0, max = 100, defecto = 100, descripcion = 'Nivel de combustible' },
    motor = { tipo = 'number', requerido = true, min = 0, max = 1000, defecto = 1000, descripcion = 'Estado del motor' },
    carroceria = { tipo = 'number', requerido = true, min = 0, max = 1000, defecto = 1000, descripcion = 'Estado de carroceria' },

    -- Modificaciones (JSON)
    modificaciones = {
        tipo = 'table',
        requerido = false,
        schema = {
            color_primario = { tipo = 'number' },
            color_secundario = { tipo = 'number' },
            ruedas = { tipo = 'number' },
            suspension = { tipo = 'number' },
            motor_mod = { tipo = 'number' },
            frenos = { tipo = 'number' },
            transmision = { tipo = 'number' },
            claxon = { tipo = 'number' },
            neon = { tipo = 'table' },
            extras = { tipo = 'table' },
        },
        descripcion = 'Modificaciones del vehiculo'
    },

    -- Financiamiento
    financiado = { tipo = 'boolean', requerido = false, defecto = false, descripcion = 'Vehiculo financiado' },
    pagos_restantes = { tipo = 'number', requerido = false, min = 0, descripcion = 'Pagos pendientes' },
    monto_cuota = { tipo = 'number', requerido = false, min = 0, descripcion = 'Monto de cada cuota' },

    -- Fechas
    fecha_compra = { tipo = 'number', requerido = false, descripcion = 'Timestamp de compra' },
    ultimo_uso = { tipo = 'number', requerido = false, descripcion = 'Ultimo uso del vehiculo' },
}

-- ============================================================================
-- SCHEMA: ITEM
-- ============================================================================

--- Schema para items del inventario
---@class SchemaItem
AIT.Schemas.Item = {
    nombre = { tipo = 'string', requerido = true, descripcion = 'Nombre unico del item' },
    etiqueta = { tipo = 'string', requerido = true, descripcion = 'Nombre visible' },
    tipo = { tipo = 'string', requerido = true, descripcion = 'Tipo de item' },
    peso = { tipo = 'number', requerido = true, min = 0, defecto = 100, descripcion = 'Peso en gramos' },

    -- Stack y cantidad
    stackeable = { tipo = 'boolean', requerido = false, defecto = true, descripcion = 'Puede apilarse' },
    max_stack = { tipo = 'number', requerido = false, min = 1, defecto = 50, descripcion = 'Maximo por stack' },
    cantidad = { tipo = 'number', requerido = false, min = 1, defecto = 1, descripcion = 'Cantidad actual' },

    -- Uso y efectos
    usable = { tipo = 'boolean', requerido = false, defecto = false, descripcion = 'Puede usarse' },
    efecto = { tipo = 'string', requerido = false, descripcion = 'Efecto al usar' },
    duracion = { tipo = 'number', requerido = false, min = 0, descripcion = 'Duracion del efecto (ms)' },

    -- Comercio
    precio = { tipo = 'number', requerido = false, min = 0, descripcion = 'Precio base de venta' },
    ilegal = { tipo = 'boolean', requerido = false, defecto = false, descripcion = 'Item ilegal' },
    comerciable = { tipo = 'boolean', requerido = false, defecto = true, descripcion = 'Puede comerciarse' },

    -- Visual
    imagen = { tipo = 'string', requerido = false, descripcion = 'Ruta de imagen' },
    descripcion = { tipo = 'string', requerido = false, descripcion = 'Descripcion del item' },
    rareza = { tipo = 'string', requerido = false, defecto = 'common', descripcion = 'Rareza del item' },

    -- Metadata especifica
    metadata = { tipo = 'table', requerido = false, descripcion = 'Datos adicionales del item' },

    -- Decaimiento
    caduca = { tipo = 'boolean', requerido = false, defecto = false, descripcion = 'El item caduca' },
    tiempo_caducidad = { tipo = 'number', requerido = false, descripcion = 'Tiempo hasta caducar (s)' },
}

-- ============================================================================
-- SCHEMA: TRANSACCION
-- ============================================================================

--- Schema para transacciones financieras
---@class SchemaTransaccion
AIT.Schemas.Transaccion = {
    id = { tipo = 'string', requerido = true, descripcion = 'ID unico de transaccion' },
    tipo = { tipo = 'string', requerido = true, descripcion = 'Tipo de transaccion' },

    -- Participantes
    origen_id = { tipo = 'string', requerido = false, descripcion = 'CitizenID origen' },
    origen_cuenta = { tipo = 'string', requerido = true, descripcion = 'Cuenta origen' },
    destino_id = { tipo = 'string', requerido = false, descripcion = 'CitizenID destino' },
    destino_cuenta = { tipo = 'string', requerido = false, descripcion = 'Cuenta destino' },

    -- Montos
    monto = { tipo = 'number', requerido = true, min = 0, descripcion = 'Monto de la transaccion' },
    comision = { tipo = 'number', requerido = false, min = 0, defecto = 0, descripcion = 'Comision aplicada' },
    monto_final = { tipo = 'number', requerido = false, descripcion = 'Monto final transferido' },

    -- Estado y detalles
    estado = { tipo = 'string', requerido = true, defecto = 'pending', descripcion = 'Estado de la transaccion' },
    concepto = { tipo = 'string', requerido = false, descripcion = 'Concepto/descripcion' },
    referencia = { tipo = 'string', requerido = false, descripcion = 'Referencia externa' },

    -- Auditoria
    fecha = { tipo = 'number', requerido = true, descripcion = 'Timestamp de la transaccion' },
    ip = { tipo = 'string', requerido = false, descripcion = 'IP del ejecutor (servidor)' },
}

-- ============================================================================
-- SCHEMA: PROPIEDAD
-- ============================================================================

--- Schema para propiedades inmobiliarias
---@class SchemaPropiedad
AIT.Schemas.Propiedad = {
    id = { tipo = 'number', requerido = false, descripcion = 'ID en base de datos' },
    nombre = { tipo = 'string', requerido = true, descripcion = 'Nombre identificador' },
    etiqueta = { tipo = 'string', requerido = true, descripcion = 'Nombre visible' },
    tipo = { tipo = 'string', requerido = true, descripcion = 'Tipo de propiedad' },

    -- Ubicacion
    coords = {
        tipo = 'table',
        requerido = true,
        schema = {
            x = { tipo = 'number', requerido = true },
            y = { tipo = 'number', requerido = true },
            z = { tipo = 'number', requerido = true },
            h = { tipo = 'number', requerido = false, defecto = 0.0 },
        },
        descripcion = 'Coordenadas de entrada'
    },
    interior = { tipo = 'string', requerido = false, descripcion = 'Shell/interior a usar' },

    -- Propiedad
    propietario = { tipo = 'string', requerido = false, descripcion = 'CitizenID del propietario' },
    estado = { tipo = 'string', requerido = true, defecto = 'available', descripcion = 'Estado de la propiedad' },

    -- Economia
    precio = { tipo = 'number', requerido = true, min = 0, descripcion = 'Precio de compra' },
    alquiler = { tipo = 'number', requerido = false, min = 0, descripcion = 'Precio de alquiler mensual' },
    impuestos = { tipo = 'number', requerido = false, min = 0, defecto = 0, descripcion = 'Impuestos mensuales' },

    -- Capacidad
    max_peso = { tipo = 'number', requerido = false, defecto = 100000, descripcion = 'Peso maximo almacenaje' },
    max_slots = { tipo = 'number', requerido = false, defecto = 50, descripcion = 'Slots de almacenaje' },
    max_vehiculos = { tipo = 'number', requerido = false, defecto = 0, descripcion = 'Vehiculos que puede guardar' },

    -- Acceso
    llave_maestra = { tipo = 'string', requerido = false, descripcion = 'ID de llave maestra' },
    codigo = { tipo = 'string', requerido = false, descripcion = 'Codigo de acceso' },
    accesos = { tipo = 'table', requerido = false, descripcion = 'Lista de CitizenIDs con acceso' },

    -- Fechas
    fecha_compra = { tipo = 'number', requerido = false, descripcion = 'Timestamp de compra' },
    proxima_cuota = { tipo = 'number', requerido = false, descripcion = 'Proximo pago de alquiler/impuestos' },
}

-- ============================================================================
-- SCHEMA: MISION
-- ============================================================================

--- Schema para misiones
---@class SchemaMision
AIT.Schemas.Mision = {
    id = { tipo = 'string', requerido = true, descripcion = 'ID unico de mision' },
    nombre = { tipo = 'string', requerido = true, descripcion = 'Nombre interno' },
    titulo = { tipo = 'string', requerido = true, descripcion = 'Titulo visible' },
    descripcion = { tipo = 'string', requerido = true, descripcion = 'Descripcion de la mision' },
    tipo = { tipo = 'string', requerido = true, descripcion = 'Tipo de mision' },

    -- Requisitos
    nivel_requerido = { tipo = 'number', requerido = false, min = 0, defecto = 0, descripcion = 'Nivel minimo' },
    trabajo_requerido = { tipo = 'string', requerido = false, descripcion = 'Trabajo necesario' },
    items_requeridos = { tipo = 'table', requerido = false, descripcion = 'Items necesarios' },
    misiones_previas = { tipo = 'table', requerido = false, descripcion = 'Misiones que deben completarse antes' },

    -- Objetivos
    objetivos = {
        tipo = 'table',
        requerido = true,
        descripcion = 'Lista de objetivos de la mision'
    },

    -- Recompensas
    recompensas = {
        tipo = 'table',
        requerido = true,
        schema = {
            dinero = { tipo = 'number', min = 0 },
            experiencia = { tipo = 'number', min = 0 },
            items = { tipo = 'table' },
            reputacion = { tipo = 'number' },
        },
        descripcion = 'Recompensas al completar'
    },

    -- Tiempo
    tiempo_limite = { tipo = 'number', requerido = false, min = 0, descripcion = 'Tiempo limite en segundos' },
    cooldown = { tipo = 'number', requerido = false, min = 0, descripcion = 'Cooldown para repetir' },

    -- Estado
    estado = { tipo = 'string', requerido = true, defecto = 'available', descripcion = 'Estado actual' },
    progreso = { tipo = 'number', requerido = false, min = 0, max = 100, defecto = 0, descripcion = 'Porcentaje de progreso' },
    inicio = { tipo = 'number', requerido = false, descripcion = 'Timestamp de inicio' },
    fin = { tipo = 'number', requerido = false, descripcion = 'Timestamp de finalizacion' },
}

-- ============================================================================
-- SCHEMA: TRABAJO
-- ============================================================================

--- Schema para definicion de trabajos
---@class SchemaTrabajo
AIT.Schemas.Trabajo = {
    nombre = { tipo = 'string', requerido = true, descripcion = 'Nombre unico del trabajo' },
    etiqueta = { tipo = 'string', requerido = true, descripcion = 'Nombre visible' },
    tipo = { tipo = 'string', requerido = true, descripcion = 'Tipo de trabajo' },

    -- Grados
    grados = {
        tipo = 'table',
        requerido = true,
        descripcion = 'Lista de grados/rangos del trabajo'
    },

    -- Configuracion
    jefe_menu = { tipo = 'boolean', requerido = false, defecto = false, descripcion = 'Tiene menu de jefe' },
    requiere_servicio = { tipo = 'boolean', requerido = false, defecto = true, descripcion = 'Requiere fichar' },
    pago_automatico = { tipo = 'boolean', requerido = false, defecto = true, descripcion = 'Pago automatico de salario' },

    -- Ubicaciones
    ubicacion_fichar = {
        tipo = 'table',
        requerido = false,
        schema = {
            x = { tipo = 'number', requerido = true },
            y = { tipo = 'number', requerido = true },
            z = { tipo = 'number', requerido = true },
        },
        descripcion = 'Coordenadas para fichar'
    },

    -- Permisos
    permisos = { tipo = 'table', requerido = false, descripcion = 'Permisos especiales del trabajo' },
}

-- ============================================================================
-- SCHEMA: BANDA
-- ============================================================================

--- Schema para definicion de bandas
---@class SchemaBanda
AIT.Schemas.Banda = {
    nombre = { tipo = 'string', requerido = true, descripcion = 'Nombre unico de la banda' },
    etiqueta = { tipo = 'string', requerido = true, descripcion = 'Nombre visible' },
    tipo = { tipo = 'string', requerido = false, defecto = 'street', descripcion = 'Tipo de banda' },

    -- Grados
    grados = {
        tipo = 'table',
        requerido = true,
        descripcion = 'Lista de grados/rangos de la banda'
    },

    -- Territorio
    territorio = {
        tipo = 'table',
        requerido = false,
        descripcion = 'Zonas de control de la banda'
    },

    -- Configuracion
    menu_jefe = { tipo = 'boolean', requerido = false, defecto = true, descripcion = 'Tiene menu de jefe' },
    almacen = { tipo = 'boolean', requerido = false, defecto = true, descripcion = 'Tiene almacen de banda' },

    -- Estadisticas
    reputacion = { tipo = 'number', requerido = false, min = 0, defecto = 0, descripcion = 'Reputacion de la banda' },
    dinero = { tipo = 'number', requerido = false, min = 0, defecto = 0, descripcion = 'Fondos de la banda' },
}

-- ============================================================================
-- SCHEMA: EVENTO
-- ============================================================================

--- Schema para eventos del servidor
---@class SchemaEvento
AIT.Schemas.Evento = {
    id = { tipo = 'string', requerido = true, descripcion = 'ID unico del evento' },
    nombre = { tipo = 'string', requerido = true, descripcion = 'Nombre del evento' },
    descripcion = { tipo = 'string', requerido = true, descripcion = 'Descripcion del evento' },
    tipo = { tipo = 'string', requerido = true, descripcion = 'Tipo de evento' },

    -- Programacion
    inicio = { tipo = 'number', requerido = true, descripcion = 'Timestamp de inicio' },
    fin = { tipo = 'number', requerido = false, descripcion = 'Timestamp de finalizacion' },
    duracion = { tipo = 'number', requerido = false, descripcion = 'Duracion en segundos' },

    -- Participacion
    max_participantes = { tipo = 'number', requerido = false, min = 1, descripcion = 'Maximo de participantes' },
    participantes = { tipo = 'table', requerido = false, descripcion = 'Lista de participantes' },

    -- Recompensas
    recompensas = { tipo = 'table', requerido = false, descripcion = 'Recompensas del evento' },

    -- Estado
    estado = { tipo = 'string', requerido = true, defecto = 'scheduled', descripcion = 'Estado del evento' },
    repetible = { tipo = 'boolean', requerido = false, defecto = false, descripcion = 'Es repetible' },
}

-- ============================================================================
-- FUNCIONES DE VALIDACION
-- ============================================================================

--- Valida un valor contra una definicion de campo
---@param valor any El valor a validar
---@param definicion table La definicion del campo
---@param nombreCampo string Nombre del campo (para errores)
---@return boolean valido Si la validacion fue exitosa
---@return string|nil error Mensaje de error si falla
local function validarCampo(valor, definicion, nombreCampo)
    -- Si es requerido y no existe
    if definicion.requerido and valor == nil then
        return false, string.format("El campo '%s' es requerido", nombreCampo)
    end

    -- Si no es requerido y no existe, OK
    if valor == nil then
        return true, nil
    end

    -- Validar tipo (excepto 'any')
    if definicion.tipo ~= 'any' and type(valor) ~= definicion.tipo then
        return false, string.format("El campo '%s' debe ser de tipo %s, recibido %s",
            nombreCampo, definicion.tipo, type(valor))
    end

    -- Validaciones especificas para strings
    if definicion.tipo == 'string' then
        if definicion.longitud and #valor ~= definicion.longitud then
            return false, string.format("El campo '%s' debe tener exactamente %d caracteres",
                nombreCampo, definicion.longitud)
        end
        if definicion.min and #valor < definicion.min then
            return false, string.format("El campo '%s' debe tener al menos %d caracteres",
                nombreCampo, definicion.min)
        end
        if definicion.max and #valor > definicion.max then
            return false, string.format("El campo '%s' no puede tener mas de %d caracteres",
                nombreCampo, definicion.max)
        end
        if definicion.patron and not string.match(valor, definicion.patron) then
            return false, string.format("El campo '%s' no cumple con el formato requerido", nombreCampo)
        end
        if definicion.valores then
            local valido = false
            for _, v in ipairs(definicion.valores) do
                if v == valor then
                    valido = true
                    break
                end
            end
            if not valido then
                return false, string.format("El campo '%s' debe ser uno de: %s",
                    nombreCampo, table.concat(definicion.valores, ', '))
            end
        end
    end

    -- Validaciones especificas para numeros
    if definicion.tipo == 'number' then
        if definicion.min and valor < definicion.min then
            return false, string.format("El campo '%s' no puede ser menor que %d",
                nombreCampo, definicion.min)
        end
        if definicion.max and valor > definicion.max then
            return false, string.format("El campo '%s' no puede ser mayor que %d",
                nombreCampo, definicion.max)
        end
    end

    -- Validacion recursiva para tablas con schema
    if definicion.tipo == 'table' and definicion.schema then
        for campo, defCampo in pairs(definicion.schema) do
            local subValor = valor[campo]
            local valido, error = validarCampo(subValor, defCampo, nombreCampo .. '.' .. campo)
            if not valido then
                return false, error
            end
        end
    end

    return true, nil
end

--- Valida un objeto contra un schema completo
---@param schema table El schema a usar para validar
---@param datos table Los datos a validar
---@return boolean valido Si todos los campos son validos
---@return table errores Lista de errores encontrados
---@return table datosValidados Datos con valores por defecto aplicados
function AIT.Schemas.Validar(schema, datos)
    local errores = {}
    local datosValidados = {}

    if type(schema) ~= 'table' then
        return false, {'Schema invalido'}, {}
    end

    if type(datos) ~= 'table' then
        return false, {'Los datos deben ser una tabla'}, {}
    end

    -- Validar cada campo del schema
    for nombreCampo, definicion in pairs(schema) do
        local valor = datos[nombreCampo]
        local valido, error = validarCampo(valor, definicion, nombreCampo)

        if not valido then
            table.insert(errores, error)
        else
            -- Aplicar valor por defecto si no existe
            if valor == nil and definicion.defecto ~= nil then
                datosValidados[nombreCampo] = definicion.defecto
            else
                datosValidados[nombreCampo] = valor
            end
        end
    end

    return #errores == 0, errores, datosValidados
end

--- Valida un solo campo contra su definicion
---@param schema table El schema completo
---@param nombreCampo string Nombre del campo a validar
---@param valor any Valor del campo
---@return boolean valido Si el campo es valido
---@return string|nil error Mensaje de error si falla
function AIT.Schemas.ValidarCampo(schema, nombreCampo, valor)
    local definicion = schema[nombreCampo]
    if not definicion then
        return false, string.format("El campo '%s' no existe en el schema", nombreCampo)
    end
    return validarCampo(valor, definicion, nombreCampo)
end

--- Aplica valores por defecto a datos incompletos
---@param schema table El schema a usar
---@param datos table Los datos parciales
---@return table datosCompletos Datos con valores por defecto
function AIT.Schemas.AplicarDefectos(schema, datos)
    local resultado = {}
    datos = datos or {}

    for nombreCampo, definicion in pairs(schema) do
        if datos[nombreCampo] ~= nil then
            resultado[nombreCampo] = datos[nombreCampo]
        elseif definicion.defecto ~= nil then
            resultado[nombreCampo] = definicion.defecto
        elseif definicion.tipo == 'table' and definicion.schema then
            resultado[nombreCampo] = AIT.Schemas.AplicarDefectos(definicion.schema, {})
        end
    end

    return resultado
end

--- Obtiene la descripcion de todos los campos de un schema
---@param schema table El schema a describir
---@return table descripciones Tabla de {campo = descripcion}
function AIT.Schemas.ObtenerDescripciones(schema)
    local descripciones = {}
    for nombreCampo, definicion in pairs(schema) do
        descripciones[nombreCampo] = definicion.descripcion or 'Sin descripcion'
    end
    return descripciones
end

--- Obtiene los campos requeridos de un schema
---@param schema table El schema a analizar
---@return table requeridos Lista de nombres de campos requeridos
function AIT.Schemas.ObtenerRequeridos(schema)
    local requeridos = {}
    for nombreCampo, definicion in pairs(schema) do
        if definicion.requerido then
            table.insert(requeridos, nombreCampo)
        end
    end
    return requeridos
end

--- Crea un objeto vacio basado en un schema (con defectos)
---@param schema table El schema a usar como plantilla
---@return table objeto Objeto con estructura del schema y valores por defecto
function AIT.Schemas.CrearVacio(schema)
    return AIT.Schemas.AplicarDefectos(schema, {})
end

--- Verifica si un objeto cumple parcialmente con un schema
---@param schema table El schema a usar
---@param datos table Los datos a verificar
---@return boolean cumple Si cumple parcialmente
---@return number porcentaje Porcentaje de campos validos
function AIT.Schemas.ValidarParcial(schema, datos)
    local totalCampos = 0
    local camposValidos = 0

    for nombreCampo, definicion in pairs(schema) do
        totalCampos = totalCampos + 1
        local valor = datos[nombreCampo]
        local valido, _ = validarCampo(valor, definicion, nombreCampo)
        if valido then
            camposValidos = camposValidos + 1
        end
    end

    local porcentaje = totalCampos > 0 and (camposValidos / totalCampos * 100) or 0
    return porcentaje == 100, porcentaje
end

-- ============================================================================
-- EXPORTAR MODULO
-- ============================================================================

return AIT.Schemas
