-- =====================================================================================
-- ait-qb ENGINE DE VIVIENDAS - CONTROL DE ACCESO
-- Gestion de llaves, inquilinos, permisos y historial de visitas
-- Namespace: AIT.Engines.Housing.Access
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Housing = AIT.Engines.Housing or {}

local Acceso = {
    -- Cache de accesos por propiedad
    accesosPorPropiedad = {},
    -- Llaves temporales activas
    llavesTemporales = {},
}

-- =====================================================================================
-- NIVELES DE PERMISO
-- =====================================================================================

Acceso.NivelesPermiso = {
    [1] = {
        nombre = 'Visitante',
        descripcion = 'Puede entrar con autorizacion',
        permisos = { 'entrar' },
    },
    [2] = {
        nombre = 'Invitado',
        descripcion = 'Puede entrar y usar servicios basicos',
        permisos = { 'entrar', 'usar_servicios' },
    },
    [3] = {
        nombre = 'Huesped',
        descripcion = 'Puede entrar, usar servicios y almacen basico',
        permisos = { 'entrar', 'usar_servicios', 'almacen_basico' },
    },
    [5] = {
        nombre = 'Inquilino',
        descripcion = 'Acceso completo excepto gestion de propiedad',
        permisos = { 'entrar', 'usar_servicios', 'almacen_basico', 'almacen_completo', 'invitar_temporal' },
    },
    [7] = {
        nombre = 'Co-propietario',
        descripcion = 'Casi todos los permisos excepto venta',
        permisos = { 'entrar', 'usar_servicios', 'almacen_basico', 'almacen_completo', 'invitar_temporal',
            'invitar_permanente', 'muebles', 'expulsar' },
    },
    [10] = {
        nombre = 'Propietario',
        descripcion = 'Control total de la propiedad',
        permisos = { '*' },
    },
}

-- =====================================================================================
-- TIPOS DE ACCESO
-- =====================================================================================

Acceso.TiposAcceso = {
    propietario = {
        nombre = 'Propietario',
        nivelDefault = 10,
        permanente = true,
        transferible = false,
    },
    inquilino = {
        nombre = 'Inquilino',
        nivelDefault = 5,
        permanente = false,
        transferible = false,
    },
    llave = {
        nombre = 'Llave',
        nivelDefault = 3,
        permanente = true,
        transferible = true,
    },
    temporal = {
        nombre = 'Acceso Temporal',
        nivelDefault = 1,
        permanente = false,
        transferible = false,
    },
    servicio = {
        nombre = 'Servicio',
        nivelDefault = 2,
        permanente = false,
        transferible = false,
    },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Acceso.Initialize()
    -- Cargar accesos en cache
    Acceso.CargarAccesosEnCache()

    -- Registrar callbacks
    Acceso.RegistrarCallbacks()

    -- Iniciar limpieza de accesos temporales
    Acceso.IniciarLimpiezaTemporal()

    if AIT.Log then
        AIT.Log.info('HOUSING:ACCESS', 'Sistema de control de acceso inicializado')
    end

    return true
end

function Acceso.CargarAccesosEnCache()
    local accesos = MySQL.query.await([[
        SELECT a.*, p.nombre as propiedad_nombre
        FROM ait_propiedad_accesos a
        JOIN ait_propiedades p ON a.propiedad_id = p.propiedad_id
        WHERE a.activo = 1 AND (a.fecha_fin IS NULL OR a.fecha_fin > NOW())
    ]])

    Acceso.accesosPorPropiedad = {}

    for _, acceso in ipairs(accesos or {}) do
        local propId = acceso.propiedad_id

        if not Acceso.accesosPorPropiedad[propId] then
            Acceso.accesosPorPropiedad[propId] = {}
        end

        acceso.metadata = acceso.metadata and json.decode(acceso.metadata) or {}
        Acceso.accesosPorPropiedad[propId][acceso.char_id] = acceso
    end
end

-- =====================================================================================
-- VERIFICACION DE ACCESO
-- =====================================================================================

--- Verificar si un personaje tiene acceso a una propiedad
---@param charId number
---@param propiedadId number
---@return boolean, number Tiene acceso, nivel de permiso
function Acceso.VerificarAcceso(charId, propiedadId)
    -- Verificar cache primero
    if Acceso.accesosPorPropiedad[propiedadId] and Acceso.accesosPorPropiedad[propiedadId][charId] then
        local acceso = Acceso.accesosPorPropiedad[propiedadId][charId]

        -- Verificar si no ha expirado
        if acceso.fecha_fin then
            local fechaFin = acceso.fecha_fin
            if type(fechaFin) == 'string' then
                -- Comparar con fecha actual
                local ahora = os.date('%Y-%m-%d %H:%M:%S')
                if fechaFin < ahora then
                    return false, 0
                end
            end
        end

        return true, acceso.nivel_permiso
    end

    -- Verificar si es propietario o inquilino directo
    local propiedad = AIT.Engines.Housing and AIT.Engines.Housing.Obtener(propiedadId)
    if propiedad then
        if propiedad.propietario_char_id == charId then
            return true, 10
        end
        if propiedad.inquilino_char_id == charId then
            return true, 5
        end
    end

    -- Buscar en BD
    local acceso = MySQL.query.await([[
        SELECT * FROM ait_propiedad_accesos
        WHERE propiedad_id = ? AND char_id = ? AND activo = 1
        AND (fecha_fin IS NULL OR fecha_fin > NOW())
        ORDER BY nivel_permiso DESC
        LIMIT 1
    ]], { propiedadId, charId })

    if acceso and acceso[1] then
        -- Actualizar cache
        if not Acceso.accesosPorPropiedad[propiedadId] then
            Acceso.accesosPorPropiedad[propiedadId] = {}
        end
        Acceso.accesosPorPropiedad[propiedadId][charId] = acceso[1]

        return true, acceso[1].nivel_permiso
    end

    return false, 0
end

--- Verificar si tiene un permiso especifico
---@param charId number
---@param propiedadId number
---@param permiso string
---@return boolean
function Acceso.TienePermiso(charId, propiedadId, permiso)
    local tieneAcceso, nivel = Acceso.VerificarAcceso(charId, propiedadId)

    if not tieneAcceso then
        return false
    end

    local nivelConfig = Acceso.NivelesPermiso[nivel]
    if not nivelConfig then
        return false
    end

    -- Nivel 10 (propietario) tiene todos los permisos
    if nivel >= 10 then
        return true
    end

    for _, p in ipairs(nivelConfig.permisos) do
        if p == '*' or p == permiso then
            return true
        end
    end

    return false
end

-- =====================================================================================
-- GESTION DE ACCESOS
-- =====================================================================================

--- Otorgar acceso a una propiedad
---@param propiedadId number
---@param charId number
---@param tipoAcceso string
---@param nivelPermiso number|nil
---@param otorgadoPor number|nil
---@param duracionHoras number|nil
---@param notas string|nil
---@return boolean, string
function Acceso.Otorgar(propiedadId, charId, tipoAcceso, nivelPermiso, otorgadoPor, duracionHoras, notas)
    -- Verificar tipo de acceso
    local tipoConfig = Acceso.TiposAcceso[tipoAcceso]
    if not tipoConfig then
        return false, 'Tipo de acceso no valido'
    end

    -- Verificar que el otorgante tiene permisos
    if otorgadoPor then
        local puedeInvitar = false
        local nivelOtorgante = 0

        local tieneAcceso, nivel = Acceso.VerificarAcceso(otorgadoPor, propiedadId)
        if tieneAcceso then
            nivelOtorgante = nivel

            -- Propietario puede todo
            if nivel >= 10 then
                puedeInvitar = true
            -- Nivel 7+ puede invitar permanente
            elseif nivel >= 7 and tipoAcceso == 'llave' then
                puedeInvitar = true
            -- Nivel 5+ puede invitar temporal
            elseif nivel >= 5 and tipoAcceso == 'temporal' then
                puedeInvitar = true
            end
        end

        if not puedeInvitar then
            return false, 'No tienes permiso para otorgar acceso'
        end

        -- No puede otorgar nivel mayor o igual al suyo (excepto propietario)
        nivelPermiso = nivelPermiso or tipoConfig.nivelDefault
        if nivelPermiso >= nivelOtorgante and nivelOtorgante < 10 then
            nivelPermiso = nivelOtorgante - 1
        end
    end

    nivelPermiso = nivelPermiso or tipoConfig.nivelDefault

    -- Calcular fecha de fin si hay duracion
    local fechaFin = nil
    if duracionHoras then
        fechaFin = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duracionHoras * 3600))
    elseif not tipoConfig.permanente then
        -- Por defecto, accesos no permanentes duran 24 horas
        fechaFin = os.date('%Y-%m-%d %H:%M:%S', os.time() + 86400)
    end

    -- Insertar o actualizar acceso
    MySQL.query.await([[
        INSERT INTO ait_propiedad_accesos
        (propiedad_id, char_id, tipo_acceso, nivel_permiso, otorgado_por, fecha_fin, notas)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            tipo_acceso = VALUES(tipo_acceso),
            nivel_permiso = VALUES(nivel_permiso),
            otorgado_por = VALUES(otorgado_por),
            fecha_inicio = NOW(),
            fecha_fin = VALUES(fecha_fin),
            activo = 1,
            notas = VALUES(notas)
    ]], { propiedadId, charId, tipoAcceso, nivelPermiso, otorgadoPor, fechaFin, notas })

    -- Actualizar cache
    if not Acceso.accesosPorPropiedad[propiedadId] then
        Acceso.accesosPorPropiedad[propiedadId] = {}
    end

    Acceso.accesosPorPropiedad[propiedadId][charId] = {
        propiedad_id = propiedadId,
        char_id = charId,
        tipo_acceso = tipoAcceso,
        nivel_permiso = nivelPermiso,
        otorgado_por = otorgadoPor,
        fecha_fin = fechaFin,
        activo = 1,
        metadata = {}
    }

    -- Log
    if AIT.Engines.Housing then
        AIT.Engines.Housing.RegistrarLog(propiedadId, 'ACCESO_OTORGADO', otorgadoPor, {
            char_id = charId,
            tipo = tipoAcceso,
            nivel = nivelPermiso,
            duracion = duracionHoras
        })
    end

    return true, ('Acceso %s otorgado correctamente'):format(tipoConfig.nombre)
end

--- Revocar acceso a una propiedad
---@param propiedadId number
---@param charId number
---@param revocadoPor number|nil
---@param motivo string|nil
---@return boolean, string
function Acceso.Revocar(propiedadId, charId, revocadoPor, motivo)
    -- Verificar que existe el acceso
    local tieneAcceso, nivelActual = Acceso.VerificarAcceso(charId, propiedadId)
    if not tieneAcceso then
        return false, 'El personaje no tiene acceso a esta propiedad'
    end

    -- No se puede revocar acceso al propietario
    local propiedad = AIT.Engines.Housing and AIT.Engines.Housing.Obtener(propiedadId)
    if propiedad and propiedad.propietario_char_id == charId then
        return false, 'No se puede revocar el acceso al propietario'
    end

    -- Verificar permisos del revocador
    if revocadoPor then
        local puedeRevocar, nivelRevocador = Acceso.VerificarAcceso(revocadoPor, propiedadId)

        if not puedeRevocar then
            return false, 'No tienes acceso a esta propiedad'
        end

        -- Solo puede revocar a usuarios con menor nivel
        if nivelActual >= nivelRevocador and nivelRevocador < 10 then
            return false, 'No puedes revocar acceso a alguien con nivel igual o superior'
        end

        -- Verificar permiso de expulsar
        if not Acceso.TienePermiso(revocadoPor, propiedadId, 'expulsar') then
            return false, 'No tienes permiso para revocar accesos'
        end
    end

    -- Revocar acceso
    MySQL.query.await([[
        UPDATE ait_propiedad_accesos
        SET activo = 0, metadata = JSON_SET(COALESCE(metadata, '{}'), '$.motivo_revocacion', ?, '$.revocado_por', ?)
        WHERE propiedad_id = ? AND char_id = ?
    ]], { motivo or 'Revocado', revocadoPor, propiedadId, charId })

    -- Actualizar cache
    if Acceso.accesosPorPropiedad[propiedadId] then
        Acceso.accesosPorPropiedad[propiedadId][charId] = nil
    end

    -- Si el jugador esta dentro de la propiedad, expulsarlo
    if AIT.Engines.Housing and AIT.Engines.Housing.propietariosOnline then
        local sourceId = AIT.Engines.Housing.propietariosOnline[propiedadId] and
            AIT.Engines.Housing.propietariosOnline[propiedadId][charId]

        if sourceId then
            AIT.Engines.Housing.Salir(sourceId, charId, propiedadId)
            TriggerClientEvent('QBCore:Notify', sourceId, 'Tu acceso a esta propiedad ha sido revocado', 'error')
        end
    end

    -- Log
    if AIT.Engines.Housing then
        AIT.Engines.Housing.RegistrarLog(propiedadId, 'ACCESO_REVOCADO', revocadoPor, {
            char_id = charId,
            motivo = motivo
        })
    end

    return true, 'Acceso revocado correctamente'
end

--- Modificar nivel de acceso
---@param propiedadId number
---@param charId number
---@param nuevoNivel number
---@param modificadoPor number|nil
---@return boolean, string
function Acceso.ModificarNivel(propiedadId, charId, nuevoNivel, modificadoPor)
    -- Verificar que existe el acceso
    local tieneAcceso, nivelActual = Acceso.VerificarAcceso(charId, propiedadId)
    if not tieneAcceso then
        return false, 'El personaje no tiene acceso a esta propiedad'
    end

    -- Verificar permisos del modificador
    if modificadoPor then
        local _, nivelModificador = Acceso.VerificarAcceso(modificadoPor, propiedadId)

        -- Solo propietario puede modificar niveles altos
        if nuevoNivel >= 7 and nivelModificador < 10 then
            return false, 'Solo el propietario puede otorgar niveles de co-propietario o superior'
        end

        -- No puede otorgar nivel igual o superior al suyo
        if nuevoNivel >= nivelModificador and nivelModificador < 10 then
            return false, 'No puedes otorgar un nivel igual o superior al tuyo'
        end
    end

    -- Validar nivel
    if not Acceso.NivelesPermiso[nuevoNivel] then
        return false, 'Nivel de permiso no valido'
    end

    MySQL.query.await([[
        UPDATE ait_propiedad_accesos SET nivel_permiso = ? WHERE propiedad_id = ? AND char_id = ?
    ]], { nuevoNivel, propiedadId, charId })

    -- Actualizar cache
    if Acceso.accesosPorPropiedad[propiedadId] and Acceso.accesosPorPropiedad[propiedadId][charId] then
        Acceso.accesosPorPropiedad[propiedadId][charId].nivel_permiso = nuevoNivel
    end

    -- Log
    if AIT.Engines.Housing then
        AIT.Engines.Housing.RegistrarLog(propiedadId, 'ACCESO_MODIFICADO', modificadoPor, {
            char_id = charId,
            nivel_anterior = nivelActual,
            nivel_nuevo = nuevoNivel
        })
    end

    return true, ('Nivel modificado a %s'):format(Acceso.NivelesPermiso[nuevoNivel].nombre)
end

-- =====================================================================================
-- LLAVES
-- =====================================================================================

--- Dar llave a otro jugador
---@param propiedadId number
---@param dePropietarioCharId number
---@param aCharId number
---@param nivelPermiso number|nil
---@return boolean, string
function Acceso.DarLlave(propiedadId, dePropietarioCharId, aCharId, nivelPermiso)
    -- Verificar permisos
    if not Acceso.TienePermiso(dePropietarioCharId, propiedadId, 'invitar_permanente') then
        return false, 'No tienes permiso para dar llaves'
    end

    -- Verificar que no se da llave a si mismo
    if dePropietarioCharId == aCharId then
        return false, 'No puedes darte una llave a ti mismo'
    end

    -- Otorgar acceso tipo llave
    return Acceso.Otorgar(propiedadId, aCharId, 'llave', nivelPermiso or 3, dePropietarioCharId, nil, 'Llave otorgada')
end

--- Quitar llave a un jugador
---@param propiedadId number
---@param propietarioCharId number
---@param aCharId number
---@return boolean, string
function Acceso.QuitarLlave(propiedadId, propietarioCharId, aCharId)
    return Acceso.Revocar(propiedadId, aCharId, propietarioCharId, 'Llave revocada')
end

--- Generar codigo de acceso temporal
---@param propiedadId number
---@param generadoPor number
---@param duracionMinutos number
---@param usosMaximos number|nil
---@return boolean, string Exito, codigo o error
function Acceso.GenerarCodigoTemporal(propiedadId, generadoPor, duracionMinutos, usosMaximos)
    if not Acceso.TienePermiso(generadoPor, propiedadId, 'invitar_temporal') then
        return false, 'No tienes permiso para generar codigos de acceso'
    end

    duracionMinutos = duracionMinutos or 30
    usosMaximos = usosMaximos or 1

    -- Generar codigo alfanumerico
    local chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    local codigo = ''
    for i = 1, 6 do
        local idx = math.random(1, #chars)
        codigo = codigo .. string.sub(chars, idx, idx)
    end

    local expiracion = os.time() + (duracionMinutos * 60)

    Acceso.llavesTemporales[codigo] = {
        propiedad_id = propiedadId,
        generado_por = generadoPor,
        expiracion = expiracion,
        usos_restantes = usosMaximos,
        usado_por = {}
    }

    -- Log
    if AIT.Engines.Housing then
        AIT.Engines.Housing.RegistrarLog(propiedadId, 'CODIGO_GENERADO', generadoPor, {
            codigo = codigo,
            duracion = duracionMinutos,
            usos = usosMaximos
        })
    end

    return true, codigo
end

--- Usar codigo de acceso temporal
---@param codigo string
---@param charId number
---@return boolean, number|string Exito, propiedadId o error
function Acceso.UsarCodigo(codigo, charId)
    local llaveTemp = Acceso.llavesTemporales[codigo]

    if not llaveTemp then
        return false, 'Codigo no valido'
    end

    if os.time() > llaveTemp.expiracion then
        Acceso.llavesTemporales[codigo] = nil
        return false, 'Codigo expirado'
    end

    if llaveTemp.usos_restantes <= 0 then
        return false, 'Codigo sin usos disponibles'
    end

    -- Verificar si ya lo uso
    for _, usadoPor in ipairs(llaveTemp.usado_por) do
        if usadoPor == charId then
            return false, 'Ya has usado este codigo'
        end
    end

    -- Otorgar acceso temporal
    local duracionRestante = math.ceil((llaveTemp.expiracion - os.time()) / 3600)
    if duracionRestante < 1 then duracionRestante = 1 end

    local success, msg = Acceso.Otorgar(
        llaveTemp.propiedad_id,
        charId,
        'temporal',
        1,
        llaveTemp.generado_por,
        duracionRestante,
        'Acceso por codigo temporal'
    )

    if success then
        llaveTemp.usos_restantes = llaveTemp.usos_restantes - 1
        table.insert(llaveTemp.usado_por, charId)

        if llaveTemp.usos_restantes <= 0 then
            Acceso.llavesTemporales[codigo] = nil
        end

        return true, llaveTemp.propiedad_id
    end

    return false, msg
end

-- =====================================================================================
-- HISTORIAL DE VISITAS
-- =====================================================================================

--- Obtener historial de visitas
---@param propiedadId number
---@param opciones table|nil
---@return table
function Acceso.ObtenerHistorialVisitas(propiedadId, opciones)
    opciones = opciones or {}

    local query = [[
        SELECT v.*, c.nombre as char_nombre, c.apellido as char_apellido
        FROM ait_propiedad_visitas v
        LEFT JOIN ait_characters c ON v.char_id = c.char_id
        WHERE v.propiedad_id = ?
    ]]
    local params = { propiedadId }

    if opciones.tipo then
        query = query .. ' AND v.tipo_visita = ?'
        table.insert(params, opciones.tipo)
    end

    if opciones.char_id then
        query = query .. ' AND v.char_id = ?'
        table.insert(params, opciones.char_id)
    end

    if opciones.desde then
        query = query .. ' AND v.fecha >= ?'
        table.insert(params, opciones.desde)
    end

    query = query .. ' ORDER BY v.fecha DESC LIMIT ?'
    table.insert(params, opciones.limite or 100)

    return MySQL.query.await(query, params) or {}
end

--- Obtener accesos actuales de una propiedad
---@param propiedadId number
---@return table
function Acceso.ObtenerAccesosPropiedad(propiedadId)
    local accesos = MySQL.query.await([[
        SELECT a.*, c.nombre as char_nombre, c.apellido as char_apellido,
               o.nombre as otorgado_nombre, o.apellido as otorgado_apellido
        FROM ait_propiedad_accesos a
        LEFT JOIN ait_characters c ON a.char_id = c.char_id
        LEFT JOIN ait_characters o ON a.otorgado_por = o.char_id
        WHERE a.propiedad_id = ? AND a.activo = 1
        AND (a.fecha_fin IS NULL OR a.fecha_fin > NOW())
        ORDER BY a.nivel_permiso DESC, a.fecha_inicio ASC
    ]], { propiedadId })

    return accesos or {}
end

--- Obtener propiedades a las que tiene acceso un personaje
---@param charId number
---@return table
function Acceso.ObtenerPropiedadesConAcceso(charId)
    local propiedades = MySQL.query.await([[
        SELECT p.*, a.tipo_acceso, a.nivel_permiso, a.fecha_fin
        FROM ait_propiedad_accesos a
        JOIN ait_propiedades p ON a.propiedad_id = p.propiedad_id
        WHERE a.char_id = ? AND a.activo = 1
        AND (a.fecha_fin IS NULL OR a.fecha_fin > NOW())
        ORDER BY a.nivel_permiso DESC
    ]], { charId })

    for i, p in ipairs(propiedades or {}) do
        p.entrada_coords = p.entrada_coords and json.decode(p.entrada_coords) or nil
        propiedades[i] = p
    end

    return propiedades or {}
end

-- =====================================================================================
-- LIMPIEZA Y MANTENIMIENTO
-- =====================================================================================

function Acceso.IniciarLimpiezaTemporal()
    CreateThread(function()
        while true do
            Wait(60000) -- Cada minuto

            -- Limpiar codigos temporales expirados
            local ahora = os.time()
            for codigo, datos in pairs(Acceso.llavesTemporales) do
                if ahora > datos.expiracion then
                    Acceso.llavesTemporales[codigo] = nil
                end
            end
        end
    end)

    -- Tarea programada para limpiar accesos expirados en BD
    if AIT.Scheduler then
        AIT.Scheduler.register('housing_access_cleanup', {
            interval = 3600,
            fn = function()
                MySQL.query([[
                    UPDATE ait_propiedad_accesos
                    SET activo = 0
                    WHERE activo = 1 AND fecha_fin IS NOT NULL AND fecha_fin < NOW()
                ]])

                -- Recargar cache
                Acceso.CargarAccesosEnCache()
            end
        })
    end
end

-- =====================================================================================
-- CALLBACKS
-- =====================================================================================

function Acceso.RegistrarCallbacks()
    if not AIT.Callbacks then return end

    -- Verificar acceso
    AIT.Callbacks.Register('housing:access:verificar', function(source, cb, propiedadId)
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then
            cb(false, 0)
            return
        end

        local charId = Player.PlayerData.citizenid
        local tieneAcceso, nivel = Acceso.VerificarAcceso(charId, propiedadId)
        cb(tieneAcceso, nivel)
    end)

    -- Obtener accesos de propiedad
    AIT.Callbacks.Register('housing:access:getAccesos', function(source, cb, propiedadId)
        local accesos = Acceso.ObtenerAccesosPropiedad(propiedadId)
        cb(accesos)
    end)

    -- Obtener historial
    AIT.Callbacks.Register('housing:access:getHistorial', function(source, cb, propiedadId, opciones)
        local historial = Acceso.ObtenerHistorialVisitas(propiedadId, opciones)
        cb(historial)
    end)

    -- Obtener niveles de permiso
    AIT.Callbacks.Register('housing:access:getNiveles', function(source, cb)
        cb(Acceso.NivelesPermiso)
    end)
end

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

-- Verificacion
Acceso.Check = Acceso.VerificarAcceso
Acceso.HasPermission = Acceso.TienePermiso

-- Gestion
Acceso.Grant = Acceso.Otorgar
Acceso.Revoke = Acceso.Revocar
Acceso.ModifyLevel = Acceso.ModificarNivel

-- Llaves
Acceso.GiveKey = Acceso.DarLlave
Acceso.TakeKey = Acceso.QuitarLlave
Acceso.GenerateCode = Acceso.GenerarCodigoTemporal
Acceso.UseCode = Acceso.UsarCodigo

-- Consultas
Acceso.GetPropertyAccess = Acceso.ObtenerAccesosPropiedad
Acceso.GetAccessibleProperties = Acceso.ObtenerPropiedadesConAcceso
Acceso.GetVisitHistory = Acceso.ObtenerHistorialVisitas

-- =====================================================================================
-- REGISTRAR SUBMODULO
-- =====================================================================================

AIT.Engines.Housing.Access = Acceso

return Acceso
