--[[
    AIT Framework - Enumeraciones del Sistema
    Archivo: shared/enums/init.lua

    Define todas las constantes y enumeraciones utilizadas
    a lo largo del framework para garantizar consistencia.

    Uso: AIT.Enums.TipoEnum.VALOR
]]

-- ============================================================================
-- INICIALIZACION
-- ============================================================================

AIT = AIT or {}
AIT.Enums = AIT.Enums or {}

-- ============================================================================
-- ENUMS DE ECONOMIA Y FINANZAS
-- ============================================================================

--- Tipos de cuenta monetaria
---@enum TipoCuenta
AIT.Enums.TipoCuenta = {
    EFECTIVO = 'cash',           -- Dinero en mano
    BANCO = 'bank',              -- Cuenta bancaria principal
    CRIPTO = 'crypto',           -- Criptomonedas
    NEGRO = 'black_money',       -- Dinero sucio/ilegal
    CASINO = 'casino',           -- Fichas de casino
    AHORROS = 'savings',         -- Cuenta de ahorros
    EMPRESA = 'business',        -- Cuenta empresarial
}

--- Tipos de transaccion financiera
---@enum TipoTransaccion
AIT.Enums.TipoTransaccion = {
    DEPOSITO = 'deposit',
    RETIRO = 'withdraw',
    TRANSFERENCIA = 'transfer',
    COMPRA = 'purchase',
    VENTA = 'sale',
    SALARIO = 'salary',
    FACTURA = 'invoice',
    MULTA = 'fine',
    RECOMPENSA = 'reward',
    IMPUESTO = 'tax',
    REEMBOLSO = 'refund',
}

--- Estados de transaccion
---@enum EstadoTransaccion
AIT.Enums.EstadoTransaccion = {
    PENDIENTE = 'pending',
    COMPLETADA = 'completed',
    FALLIDA = 'failed',
    CANCELADA = 'cancelled',
    REVERTIDA = 'reversed',
}

-- ============================================================================
-- ENUMS DE ITEMS E INVENTARIO
-- ============================================================================

--- Tipos de item
---@enum TipoItem
AIT.Enums.TipoItem = {
    ARMA = 'weapon',             -- Armas de fuego y cuerpo a cuerpo
    CONSUMIBLE = 'consumable',   -- Comida, bebida, medicinas
    MATERIAL = 'material',       -- Materiales de crafteo
    HERRAMIENTA = 'tool',        -- Herramientas de trabajo
    ROPA = 'clothing',           -- Prendas de vestir
    ACCESORIO = 'accessory',     -- Accesorios (relojes, joyas)
    DOCUMENTO = 'document',      -- Licencias, identificaciones
    LLAVE = 'key',               -- Llaves de vehiculos/propiedades
    ELECTRONICO = 'electronic',  -- Telefonos, tablets, radios
    ILEGAL = 'illegal',          -- Drogas, items prohibidos
    MISC = 'misc',               -- Miscelaneos
    MUNICION = 'ammo',           -- Municion para armas
    COMPONENTE = 'component',    -- Componentes de armas
    COLECCIONABLE = 'collectible', -- Items coleccionables
}

--- Rareza de items
---@enum RarezaItem
AIT.Enums.RarezaItem = {
    COMUN = 'common',
    POCO_COMUN = 'uncommon',
    RARO = 'rare',
    EPICO = 'epic',
    LEGENDARIO = 'legendary',
    UNICO = 'unique',
}

--- Estados de item
---@enum EstadoItem
AIT.Enums.EstadoItem = {
    NUEVO = 'new',
    USADO = 'used',
    DANADO = 'damaged',
    ROTO = 'broken',
}

-- ============================================================================
-- ENUMS DE VEHICULOS
-- ============================================================================

--- Estados de vehiculo
---@enum EstadoVehiculo
AIT.Enums.EstadoVehiculo = {
    GARAJE = 'garaged',          -- En el garaje
    FUERA = 'out',               -- En la calle
    DEPOSITO = 'impound',        -- En el deposito municipal
    DESTRUIDO = 'destroyed',     -- Destruido/perdido
    TRANSFERENCIA = 'transfer',  -- En proceso de transferencia
    TALLER = 'mechanic',         -- En el taller mecanico
}

--- Tipos de vehiculo
---@enum TipoVehiculo
AIT.Enums.TipoVehiculo = {
    COCHE = 'car',
    MOTO = 'motorcycle',
    BICICLETA = 'bicycle',
    BARCO = 'boat',
    HELICOPTERO = 'helicopter',
    AVION = 'plane',
    CAMION = 'truck',
    FURGONETA = 'van',
    EMERGENCIA = 'emergency',
    MILITAR = 'military',
    TRAILER = 'trailer',
}

--- Tipos de combustible
---@enum TipoCombustible
AIT.Enums.TipoCombustible = {
    GASOLINA = 'petrol',
    DIESEL = 'diesel',
    ELECTRICO = 'electric',
    HIBRIDO = 'hybrid',
    KEROSENO = 'kerosene',
}

-- ============================================================================
-- ENUMS DE TRABAJO Y EMPLEO
-- ============================================================================

--- Tipos de trabajo
---@enum TipoTrabajo
AIT.Enums.TipoTrabajo = {
    CIVIL = 'civilian',          -- Trabajos civiles normales
    LEGAL = 'legal',             -- Empresas legales
    EMERGENCIA = 'emergency',    -- Policia, EMS, Bomberos
    GOBIERNO = 'government',     -- Trabajos gubernamentales
    ILEGAL = 'illegal',          -- Trabajos ilegales
    FREELANCE = 'freelance',     -- Trabajos autonomos
}

--- Rangos de trabajo genericos
---@enum RangoTrabajo
AIT.Enums.RangoTrabajo = {
    APRENDIZ = 0,
    NOVATO = 1,
    EMPLEADO = 2,
    SENIOR = 3,
    SUPERVISOR = 4,
    GERENTE = 5,
    DIRECTOR = 6,
    JEFE = 7,
    PROPIETARIO = 8,
}

--- Estados de servicio
---@enum EstadoServicio
AIT.Enums.EstadoServicio = {
    ACTIVO = 'on_duty',          -- En servicio
    INACTIVO = 'off_duty',       -- Fuera de servicio
    PAUSA = 'break',             -- En pausa/descanso
    FORMACION = 'training',      -- En formacion
}

-- ============================================================================
-- ENUMS DE BANDAS Y ORGANIZACIONES
-- ============================================================================

--- Tipos de banda/organizacion
---@enum TipoBanda
AIT.Enums.TipoBanda = {
    CALLE = 'street',            -- Banda callejera
    MAFIA = 'mafia',             -- Organizacion mafiosa
    CARTEL = 'cartel',           -- Cartel de drogas
    MOTORISTA = 'biker',         -- Club de moteros
    YAKUZA = 'yakuza',           -- Yakuza
    TRIADA = 'triad',            -- Triada
    FAMILIAR = 'family',         -- Familia criminal
}

--- Rangos de banda genericos
---@enum RangoBanda
AIT.Enums.RangoBanda = {
    ASPIRANTE = 0,
    INICIADO = 1,
    SOLDADO = 2,
    TENIENTE = 3,
    CAPITAN = 4,
    SUBJEFE = 5,
    JEFE = 6,
}

-- ============================================================================
-- ENUMS DE PROPIEDADES
-- ============================================================================

--- Tipos de propiedad
---@enum TipoPropiedad
AIT.Enums.TipoPropiedad = {
    CASA = 'house',              -- Casa residencial
    APARTAMENTO = 'apartment',   -- Apartamento
    GARAJE = 'garage',           -- Garaje privado
    NEGOCIO = 'business',        -- Local comercial
    OFICINA = 'office',          -- Oficina
    ALMACEN = 'warehouse',       -- Almacen
    MANSION = 'mansion',         -- Mansion de lujo
    PENTHOUSE = 'penthouse',     -- Atico de lujo
    BUNKER = 'bunker',           -- Bunker secreto
    YATE = 'yacht',              -- Yate
}

--- Estados de propiedad
---@enum EstadoPropiedad
AIT.Enums.EstadoPropiedad = {
    DISPONIBLE = 'available',    -- Disponible para comprar/alquilar
    OCUPADA = 'occupied',        -- Ocupada por propietario
    ALQUILADA = 'rented',        -- Alquilada
    EN_VENTA = 'for_sale',       -- En venta
    EMBARGADA = 'seized',        -- Embargada
    BLOQUEADA = 'locked',        -- Bloqueada temporalmente
}

--- Tipos de acceso a propiedad
---@enum TipoAccesoPropiedad
AIT.Enums.TipoAccesoPropiedad = {
    PROPIETARIO = 'owner',       -- Propietario completo
    INQUILINO = 'tenant',        -- Inquilino
    INVITADO = 'guest',          -- Invitado con acceso
    EMPLEADO = 'employee',       -- Empleado del negocio
    ADMINISTRADOR = 'admin',     -- Administrador
}

-- ============================================================================
-- ENUMS DE MISIONES Y EVENTOS
-- ============================================================================

--- Estados de mision
---@enum EstadoMision
AIT.Enums.EstadoMision = {
    DISPONIBLE = 'available',    -- Disponible para aceptar
    EN_PROGRESO = 'in_progress', -- En curso
    COMPLETADA = 'completed',    -- Completada exitosamente
    FALLIDA = 'failed',          -- Fallida
    CANCELADA = 'cancelled',     -- Cancelada
    EXPIRADA = 'expired',        -- Tiempo expirado
    PAUSADA = 'paused',          -- Pausada temporalmente
}

--- Tipos de mision
---@enum TipoMision
AIT.Enums.TipoMision = {
    HISTORIA = 'story',          -- Mision de historia principal
    SECUNDARIA = 'side',         -- Mision secundaria
    DIARIA = 'daily',            -- Mision diaria
    SEMANAL = 'weekly',          -- Mision semanal
    REPETIBLE = 'repeatable',    -- Mision repetible
    EVENTO = 'event',            -- Mision de evento especial
    CONTRATO = 'contract',       -- Contrato de trabajo
}

--- Estados de evento del servidor
---@enum EstadoEvento
AIT.Enums.EstadoEvento = {
    PROGRAMADO = 'scheduled',    -- Programado para el futuro
    ACTIVO = 'active',           -- Actualmente en curso
    PAUSADO = 'paused',          -- Pausado temporalmente
    FINALIZADO = 'ended',        -- Finalizado
    CANCELADO = 'cancelled',     -- Cancelado
}

--- Tipos de evento
---@enum TipoEvento
AIT.Enums.TipoEvento = {
    GLOBAL = 'global',           -- Evento para todo el servidor
    ZONA = 'zone',               -- Evento de zona especifica
    TRABAJO = 'job',             -- Evento relacionado con trabajo
    COMPETICION = 'competition', -- Competicion entre jugadores
    FESTIVO = 'holiday',         -- Evento festivo/temporada
}

-- ============================================================================
-- ENUMS DE INTERFAZ Y NOTIFICACIONES
-- ============================================================================

--- Tipos de notificacion
---@enum TipoNotificacion
AIT.Enums.TipoNotificacion = {
    INFO = 'info',               -- Informacion general
    EXITO = 'success',           -- Accion exitosa
    ADVERTENCIA = 'warning',     -- Advertencia
    ERROR = 'error',             -- Error
    POLICIA = 'police',          -- Notificacion policial
    BANCO = 'bank',              -- Notificacion bancaria
    TRABAJO = 'job',             -- Notificacion de trabajo
    SISTEMA = 'system',          -- Notificacion del sistema
}

--- Tipos de menu
---@enum TipoMenu
AIT.Enums.TipoMenu = {
    CONTEXTO = 'context',        -- Menu contextual
    RADIAL = 'radial',           -- Menu radial
    LISTA = 'list',              -- Menu de lista
    DIALOGO = 'dialog',          -- Dialogo/conversacion
    INVENTARIO = 'inventory',    -- Menu de inventario
    TIENDA = 'shop',             -- Menu de tienda
    GARAJE = 'garage',           -- Menu de garaje
    TELEFONO = 'phone',          -- Aplicacion de telefono
}

--- Posiciones de UI
---@enum PosicionUI
AIT.Enums.PosicionUI = {
    ARRIBA_IZQUIERDA = 'top-left',
    ARRIBA_CENTRO = 'top-center',
    ARRIBA_DERECHA = 'top-right',
    CENTRO_IZQUIERDA = 'center-left',
    CENTRO = 'center',
    CENTRO_DERECHA = 'center-right',
    ABAJO_IZQUIERDA = 'bottom-left',
    ABAJO_CENTRO = 'bottom-center',
    ABAJO_DERECHA = 'bottom-right',
}

-- ============================================================================
-- ENUMS DE PERMISOS Y ADMINISTRACION
-- ============================================================================

--- Niveles de permiso
---@enum NivelPermiso
AIT.Enums.NivelPermiso = {
    USUARIO = 0,                 -- Jugador normal
    VIP = 1,                     -- Usuario VIP
    SOPORTE = 2,                 -- Staff de soporte
    MODERADOR = 3,               -- Moderador
    ADMINISTRADOR = 4,           -- Administrador
    SUPERADMIN = 5,              -- Super administrador
    DESARROLLADOR = 6,           -- Desarrollador
    PROPIETARIO = 7,             -- Propietario del servidor
}

--- Tipos de sancion
---@enum TipoSancion
AIT.Enums.TipoSancion = {
    ADVERTENCIA = 'warning',     -- Advertencia verbal
    SILENCIO = 'mute',           -- Silenciado en chat
    EXPULSION = 'kick',          -- Expulsion del servidor
    BAN_TEMPORAL = 'tempban',    -- Ban temporal
    BAN_PERMANENTE = 'permban',  -- Ban permanente
    CARCEL = 'jail',             -- Carcel administrativa
}

-- ============================================================================
-- ENUMS DE ESTADO DEL JUGADOR
-- ============================================================================

--- Estados del personaje
---@enum EstadoPersonaje
AIT.Enums.EstadoPersonaje = {
    VIVO = 'alive',              -- Vivo y funcional
    HERIDO = 'injured',          -- Herido (puede moverse)
    ABATIDO = 'downed',          -- Abatido (necesita ayuda)
    MUERTO = 'dead',             -- Muerto (espera respawn)
    ESPOSADO = 'handcuffed',     -- Esposado
    ARRESTADO = 'arrested',      -- Bajo arresto
    HOSPITALIZADO = 'hospitalized', -- En el hospital
}

--- Estados de conexion
---@enum EstadoConexion
AIT.Enums.EstadoConexion = {
    CONECTANDO = 'connecting',   -- Conectando al servidor
    CARGANDO = 'loading',        -- Cargando datos
    SELECCION = 'selecting',     -- Seleccionando personaje
    JUGANDO = 'playing',         -- Jugando activamente
    AFK = 'afk',                 -- Ausente
    DESCONECTANDO = 'disconnecting', -- Desconectando
}

--- Licencias disponibles
---@enum TipoLicencia
AIT.Enums.TipoLicencia = {
    CONDUCIR = 'driver',         -- Licencia de conducir
    ARMAS = 'weapon',            -- Licencia de armas
    PESCA = 'fishing',           -- Licencia de pesca
    CAZA = 'hunting',            -- Licencia de caza
    PILOTO = 'pilot',            -- Licencia de piloto
    NAUTICA = 'boat',            -- Licencia nautica
    COMERCIO = 'business',       -- Licencia comercial
    MEDICA = 'medical',          -- Licencia medica
}

-- ============================================================================
-- ENUMS DE CLIMA Y TIEMPO
-- ============================================================================

--- Tipos de clima
---@enum TipoClima
AIT.Enums.TipoClima = {
    DESPEJADO = 'clear',
    NUBLADO = 'cloudy',
    LLUVIA = 'rain',
    TORMENTA = 'thunder',
    NIEVE = 'snow',
    NIEBLA = 'fog',
    VIENTO = 'wind',
    SMOG = 'smog',
}

-- ============================================================================
-- ENUMS DE COMUNICACION
-- ============================================================================

--- Canales de chat
---@enum CanalChat
AIT.Enums.CanalChat = {
    LOCAL = 'local',             -- Chat local (proximidad)
    GLOBAL = 'global',           -- Chat global (OOC)
    TRABAJO = 'job',             -- Chat de trabajo
    BANDA = 'gang',              -- Chat de banda
    RADIO = 'radio',             -- Radio frecuencia
    TELEFONO = 'phone',          -- Llamada telefonica
    TWITTER = 'twitter',         -- Red social
    ANUNCIO = 'announcement',    -- Anuncios del servidor
    ADMIN = 'admin',             -- Chat de administracion
}

--- Estados de llamada
---@enum EstadoLlamada
AIT.Enums.EstadoLlamada = {
    MARCANDO = 'dialing',        -- Marcando numero
    SONANDO = 'ringing',         -- Timbre sonando
    CONECTADA = 'connected',     -- Llamada en curso
    EN_ESPERA = 'hold',          -- En espera
    FINALIZADA = 'ended',        -- Llamada finalizada
    RECHAZADA = 'rejected',      -- Llamada rechazada
    OCUPADO = 'busy',            -- Linea ocupada
}

-- ============================================================================
-- FUNCIONES DE UTILIDAD
-- ============================================================================

--- Obtiene el valor de un enum por su clave
---@param enumTabla table Tabla del enum
---@param clave string Clave a buscar
---@return any|nil valor El valor del enum o nil si no existe
function AIT.Enums.ObtenerValor(enumTabla, clave)
    if type(enumTabla) ~= 'table' then
        return nil
    end
    return enumTabla[clave]
end

--- Verifica si un valor existe en un enum
---@param enumTabla table Tabla del enum
---@param valor any Valor a verificar
---@return boolean existe True si el valor existe en el enum
function AIT.Enums.ExisteValor(enumTabla, valor)
    if type(enumTabla) ~= 'table' then
        return false
    end
    for _, v in pairs(enumTabla) do
        if v == valor then
            return true
        end
    end
    return false
end

--- Obtiene la clave de un enum por su valor
---@param enumTabla table Tabla del enum
---@param valor any Valor a buscar
---@return string|nil clave La clave del enum o nil si no existe
function AIT.Enums.ObtenerClave(enumTabla, valor)
    if type(enumTabla) ~= 'table' then
        return nil
    end
    for k, v in pairs(enumTabla) do
        if v == valor then
            return k
        end
    end
    return nil
end

--- Convierte un enum a una lista de opciones (para menus)
---@param enumTabla table Tabla del enum
---@return table opciones Lista de {valor, etiqueta}
function AIT.Enums.AOpciones(enumTabla)
    local opciones = {}
    if type(enumTabla) ~= 'table' then
        return opciones
    end
    for clave, valor in pairs(enumTabla) do
        table.insert(opciones, {
            valor = valor,
            etiqueta = clave:gsub('_', ' ')
        })
    end
    return opciones
end

--- Obtiene todos los valores de un enum
---@param enumTabla table Tabla del enum
---@return table valores Lista de todos los valores
function AIT.Enums.ObtenerValores(enumTabla)
    local valores = {}
    if type(enumTabla) ~= 'table' then
        return valores
    end
    for _, v in pairs(enumTabla) do
        table.insert(valores, v)
    end
    return valores
end

--- Obtiene todas las claves de un enum
---@param enumTabla table Tabla del enum
---@return table claves Lista de todas las claves
function AIT.Enums.ObtenerClaves(enumTabla)
    local claves = {}
    if type(enumTabla) ~= 'table' then
        return claves
    end
    for k, _ in pairs(enumTabla) do
        table.insert(claves, k)
    end
    return claves
end

-- ============================================================================
-- EXPORTAR MODULO
-- ============================================================================

return AIT.Enums
