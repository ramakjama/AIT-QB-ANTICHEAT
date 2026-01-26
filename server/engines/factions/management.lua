-- =====================================================================================
-- ait-qb ENGINE DE FACCIONES - GESTION PARA LIDERES
-- Invitar, expulsar, promover, editar rangos, ver logs
-- Namespace: AIT.Engines.Factions.Management
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Factions = AIT.Engines.Factions or {}

local Management = {
    -- Cache de invitaciones pendientes
    invitacionesPendientes = {},
    -- Cache de solicitudes pendientes
    solicitudesPendientes = {},
    -- Configuracion
    config = {
        duracionInvitacion = 86400, -- 24 horas
        maxInvitacionesPendientes = 10,
        maxSolicitudesPendientes = 50,
        cooldownExpulsion = 604800, -- 7 dias antes de poder reingresar
    }
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Management.Initialize()
    -- Registrar eventos
    Management.RegistrarEventos()

    -- Registrar comandos
    Management.RegistrarComandos()

    -- Registrar callbacks
    Management.RegistrarCallbacks()

    -- Limpiar invitaciones expiradas periodicamente
    if AIT.Scheduler then
        AIT.Scheduler.register('factions_cleanup_invites', {
            interval = 3600,
            fn = Management.LimpiarInvitacionesExpiradas
        })
    end

    if AIT.Log then
        AIT.Log.info('FACTIONS:MANAGEMENT', 'Sistema de gestion de facciones inicializado')
    end

    return true
end

-- =====================================================================================
-- INVITACIONES
-- =====================================================================================

--- Invitar a un jugador a la faccion
---@param source number Quien invita
---@param charIdInvitador number
---@param charIdInvitado number
---@param mensaje string|nil
---@return boolean, string
function Management.Invitar(source, charIdInvitador, charIdInvitado, mensaje)
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    -- Verificar que el invitador pertenece a una faccion
    local membresia = Facciones.ObtenerFaccionDePersonaje(charIdInvitador)
    if not membresia then
        return false, 'No perteneces a ninguna faccion'
    end

    -- Verificar permiso de invitar
    if not membresia.puede_reclutar then
        return false, 'No tienes permiso para invitar miembros'
    end

    local faccionId = membresia.faccion_id

    -- Verificar que el invitado no este en otra faccion
    if Facciones.EsMiembro(charIdInvitado, nil) then
        return false, 'Este jugador ya pertenece a una faccion'
    end

    -- Verificar limite de miembros
    local faccion = Facciones.Obtener(faccionId)
    if faccion.total_miembros >= faccion.max_miembros then
        return false, 'La faccion ha alcanzado el limite de miembros'
    end

    -- Verificar si ya tiene una invitacion pendiente
    local existente = MySQL.query.await([[
        SELECT invitacion_id FROM ait_faccion_invitaciones
        WHERE faccion_id = ? AND char_id = ? AND estado = 'pendiente'
    ]], { faccionId, charIdInvitado })

    if existente and #existente > 0 then
        return false, 'Este jugador ya tiene una invitacion pendiente'
    end

    -- Verificar cooldown de expulsion
    local expulsionReciente = MySQL.query.await([[
        SELECT fecha FROM ait_faccion_logs
        WHERE faccion_id = ? AND accion = 'MIEMBRO_EXPULSADO' AND objetivo_char_id = ?
        AND fecha > DATE_SUB(NOW(), INTERVAL ? SECOND)
        ORDER BY fecha DESC LIMIT 1
    ]], { faccionId, charIdInvitado, Management.config.cooldownExpulsion })

    if expulsionReciente and #expulsionReciente > 0 then
        return false, 'Este jugador fue expulsado recientemente y debe esperar antes de ser invitado'
    end

    -- Crear invitacion
    local fechaExpiracion = os.date('%Y-%m-%d %H:%M:%S', os.time() + Management.config.duracionInvitacion)

    local invitacionId = MySQL.insert.await([[
        INSERT INTO ait_faccion_invitaciones
        (faccion_id, char_id, invitado_por, mensaje, fecha_expiracion)
        VALUES (?, ?, ?, ?, ?)
    ]], { faccionId, charIdInvitado, charIdInvitador, mensaje, fechaExpiracion })

    -- Log
    Facciones.RegistrarLog(faccionId, 'INVITACION_ENVIADA', charIdInvitador, charIdInvitado, {
        mensaje = mensaje,
        expira = fechaExpiracion
    })

    -- Notificar al invitado si esta online
    local targetSource = Management.ObtenerSourceDeCharId(charIdInvitado)
    if targetSource then
        TriggerClientEvent('ait:factions:invitation', targetSource, {
            invitacion_id = invitacionId,
            faccion_nombre = faccion.nombre,
            faccion_id = faccionId,
            mensaje = mensaje,
            expira = fechaExpiracion
        })
    end

    return true, ('Invitacion enviada correctamente a %s'):format(
        Management.ObtenerNombrePersonaje(charIdInvitado) or 'el jugador'
    )
end

--- Aceptar una invitacion
---@param charId number
---@param invitacionId number
---@return boolean, string
function Management.AceptarInvitacion(charId, invitacionId)
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    -- Obtener invitacion
    local invitacion = MySQL.query.await([[
        SELECT * FROM ait_faccion_invitaciones
        WHERE invitacion_id = ? AND char_id = ? AND estado = 'pendiente'
    ]], { invitacionId, charId })

    if not invitacion or #invitacion == 0 then
        return false, 'Invitacion no encontrada o ya procesada'
    end

    invitacion = invitacion[1]

    -- Verificar expiracion
    local ahora = os.date('%Y-%m-%d %H:%M:%S')
    if invitacion.fecha_expiracion < ahora then
        MySQL.query([[
            UPDATE ait_faccion_invitaciones SET estado = 'expirada' WHERE invitacion_id = ?
        ]], { invitacionId })
        return false, 'La invitacion ha expirado'
    end

    -- Unirse a la faccion
    local success, mensaje = Facciones.Unirse(charId, invitacion.faccion_id)
    if not success then
        return false, mensaje
    end

    -- Actualizar invitacion
    MySQL.query([[
        UPDATE ait_faccion_invitaciones
        SET estado = 'aceptada', fecha_respuesta = NOW()
        WHERE invitacion_id = ?
    ]], { invitacionId })

    -- Log
    Facciones.RegistrarLog(invitacion.faccion_id, 'INVITACION_ACEPTADA', charId, invitacion.invitado_por, {
        invitacion_id = invitacionId
    })

    return true, 'Te has unido a la faccion correctamente'
end

--- Rechazar una invitacion
---@param charId number
---@param invitacionId number
---@return boolean, string
function Management.RechazarInvitacion(charId, invitacionId)
    local invitacion = MySQL.query.await([[
        SELECT * FROM ait_faccion_invitaciones
        WHERE invitacion_id = ? AND char_id = ? AND estado = 'pendiente'
    ]], { invitacionId, charId })

    if not invitacion or #invitacion == 0 then
        return false, 'Invitacion no encontrada o ya procesada'
    end

    invitacion = invitacion[1]

    MySQL.query([[
        UPDATE ait_faccion_invitaciones
        SET estado = 'rechazada', fecha_respuesta = NOW()
        WHERE invitacion_id = ?
    ]], { invitacionId })

    -- Log
    local Facciones = AIT.Engines.Factions
    if Facciones then
        Facciones.RegistrarLog(invitacion.faccion_id, 'INVITACION_RECHAZADA', charId, invitacion.invitado_por, {
            invitacion_id = invitacionId
        })
    end

    return true, 'Invitacion rechazada'
end

--- Obtener invitaciones pendientes de un jugador
---@param charId number
---@return table
function Management.ObtenerInvitacionesPendientes(charId)
    return MySQL.query.await([[
        SELECT i.*, f.nombre as faccion_nombre, f.nombre_corto, f.tipo,
               c.nombre as invitador_nombre, c.apellido as invitador_apellido
        FROM ait_faccion_invitaciones i
        JOIN ait_facciones f ON i.faccion_id = f.faccion_id
        LEFT JOIN ait_characters c ON i.invitado_por = c.char_id
        WHERE i.char_id = ? AND i.estado = 'pendiente'
        AND i.fecha_expiracion > NOW()
        ORDER BY i.fecha_invitacion DESC
    ]], { charId }) or {}
end

-- =====================================================================================
-- SOLICITUDES DE INGRESO
-- =====================================================================================

--- Enviar solicitud de ingreso
---@param charId number
---@param faccionId number
---@param mensaje string|nil
---@return boolean, string
function Management.EnviarSolicitud(charId, faccionId, mensaje)
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    -- Verificar que no este en otra faccion
    if Facciones.EsMiembro(charId, nil) then
        return false, 'Ya perteneces a una faccion'
    end

    local faccion = Facciones.Obtener(faccionId)
    if not faccion then
        return false, 'Faccion no encontrada'
    end

    if not faccion.activa then
        return false, 'Esta faccion no esta activa'
    end

    -- Verificar si la faccion requiere aprobacion
    if not faccion.requiere_aprobacion then
        -- Unirse directamente
        return Facciones.Unirse(charId, faccionId)
    end

    -- Verificar si ya tiene una solicitud pendiente
    local existente = MySQL.query.await([[
        SELECT solicitud_id FROM ait_faccion_solicitudes
        WHERE faccion_id = ? AND char_id = ? AND estado = 'pendiente'
    ]], { faccionId, charId })

    if existente and #existente > 0 then
        return false, 'Ya tienes una solicitud pendiente para esta faccion'
    end

    -- Crear solicitud
    local solicitudId = MySQL.insert.await([[
        INSERT INTO ait_faccion_solicitudes (faccion_id, char_id, mensaje)
        VALUES (?, ?, ?)
    ]], { faccionId, charId, mensaje })

    -- Notificar a la faccion
    Facciones.NotificarFaccion(faccionId, {
        tipo = 'solicitud',
        titulo = 'Nueva solicitud de ingreso',
        mensaje = ('Un jugador ha solicitado unirse a la faccion'):format(),
        prioridad = 'normal',
        rango_minimo = 3, -- Solo supervisores y jefes
    })

    -- Log
    Facciones.RegistrarLog(faccionId, 'SOLICITUD_ENVIADA', charId, nil, {
        solicitud_id = solicitudId,
        mensaje = mensaje
    })

    return true, 'Solicitud enviada correctamente'
end

--- Aprobar solicitud de ingreso
---@param source number
---@param charIdAprobador number
---@param solicitudId number
---@return boolean, string
function Management.AprobarSolicitud(source, charIdAprobador, solicitudId)
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    -- Verificar permisos
    local membresia = Facciones.ObtenerFaccionDePersonaje(charIdAprobador)
    if not membresia or not membresia.puede_reclutar then
        return false, 'No tienes permiso para aprobar solicitudes'
    end

    -- Obtener solicitud
    local solicitud = MySQL.query.await([[
        SELECT * FROM ait_faccion_solicitudes
        WHERE solicitud_id = ? AND estado = 'pendiente'
    ]], { solicitudId })

    if not solicitud or #solicitud == 0 then
        return false, 'Solicitud no encontrada o ya procesada'
    end

    solicitud = solicitud[1]

    -- Verificar que sea de la misma faccion
    if solicitud.faccion_id ~= membresia.faccion_id then
        return false, 'Esta solicitud no es para tu faccion'
    end

    -- Unir al solicitante
    local success, mensaje = Facciones.Unirse(solicitud.char_id, solicitud.faccion_id)
    if not success then
        return false, mensaje
    end

    -- Actualizar solicitud
    MySQL.query([[
        UPDATE ait_faccion_solicitudes
        SET estado = 'aprobada', revisada_por = ?, fecha_revision = NOW()
        WHERE solicitud_id = ?
    ]], { charIdAprobador, solicitudId })

    -- Log
    Facciones.RegistrarLog(solicitud.faccion_id, 'SOLICITUD_APROBADA', charIdAprobador, solicitud.char_id, {
        solicitud_id = solicitudId
    })

    -- Notificar al solicitante si esta online
    local targetSource = Management.ObtenerSourceDeCharId(solicitud.char_id)
    if targetSource then
        TriggerClientEvent('QBCore:Notify', targetSource, 'Tu solicitud ha sido aprobada!', 'success')
    end

    return true, 'Solicitud aprobada correctamente'
end

--- Rechazar solicitud de ingreso
---@param source number
---@param charIdRechazador number
---@param solicitudId number
---@param motivo string|nil
---@return boolean, string
function Management.RechazarSolicitud(source, charIdRechazador, solicitudId, motivo)
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    -- Verificar permisos
    local membresia = Facciones.ObtenerFaccionDePersonaje(charIdRechazador)
    if not membresia or not membresia.puede_reclutar then
        return false, 'No tienes permiso para rechazar solicitudes'
    end

    -- Obtener solicitud
    local solicitud = MySQL.query.await([[
        SELECT * FROM ait_faccion_solicitudes
        WHERE solicitud_id = ? AND estado = 'pendiente'
    ]], { solicitudId })

    if not solicitud or #solicitud == 0 then
        return false, 'Solicitud no encontrada o ya procesada'
    end

    solicitud = solicitud[1]

    -- Verificar que sea de la misma faccion
    if solicitud.faccion_id ~= membresia.faccion_id then
        return false, 'Esta solicitud no es para tu faccion'
    end

    -- Actualizar solicitud
    MySQL.query([[
        UPDATE ait_faccion_solicitudes
        SET estado = 'rechazada', revisada_por = ?, fecha_revision = NOW(), motivo_rechazo = ?
        WHERE solicitud_id = ?
    ]], { charIdRechazador, motivo, solicitudId })

    -- Log
    Facciones.RegistrarLog(solicitud.faccion_id, 'SOLICITUD_RECHAZADA', charIdRechazador, solicitud.char_id, {
        solicitud_id = solicitudId,
        motivo = motivo
    })

    return true, 'Solicitud rechazada'
end

--- Obtener solicitudes pendientes de una faccion
---@param faccionId number
---@return table
function Management.ObtenerSolicitudesPendientes(faccionId)
    return MySQL.query.await([[
        SELECT s.*, c.nombre as char_nombre, c.apellido as char_apellido
        FROM ait_faccion_solicitudes s
        LEFT JOIN ait_characters c ON s.char_id = c.char_id
        WHERE s.faccion_id = ? AND s.estado = 'pendiente'
        ORDER BY s.fecha_solicitud ASC
    ]], { faccionId }) or {}
end

-- =====================================================================================
-- EXPULSION
-- =====================================================================================

--- Expulsar a un miembro de la faccion
---@param source number
---@param charIdExpulsor number
---@param charIdExpulsado number
---@param motivo string|nil
---@return boolean, string
function Management.Expulsar(source, charIdExpulsor, charIdExpulsado, motivo)
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    -- Verificar permisos
    local membresiaExpulsor = Facciones.ObtenerFaccionDePersonaje(charIdExpulsor)
    if not membresiaExpulsor then
        return false, 'No perteneces a ninguna faccion'
    end

    if not membresiaExpulsor.puede_expulsar then
        return false, 'No tienes permiso para expulsar miembros'
    end

    -- Verificar que el expulsado pertenece a la misma faccion
    local membresiaExpulsado = Facciones.ObtenerFaccionDePersonaje(charIdExpulsado)
    if not membresiaExpulsado or membresiaExpulsado.faccion_id ~= membresiaExpulsor.faccion_id then
        return false, 'Este jugador no pertenece a tu faccion'
    end

    -- No se puede expulsar a alguien de mayor o igual rango
    if membresiaExpulsado.rango_nivel >= membresiaExpulsor.rango_nivel then
        return false, 'No puedes expulsar a alguien de mayor o igual rango'
    end

    -- No se puede expulsar al lider
    local faccion = Facciones.Obtener(membresiaExpulsor.faccion_id)
    if faccion and faccion.lider_char_id == charIdExpulsado then
        return false, 'No puedes expulsar al lider de la faccion'
    end

    local faccionId = membresiaExpulsor.faccion_id

    -- Forzar salida de servicio si esta activo
    local Duties = AIT.Engines.Factions.Duties
    if Duties and Duties.EstaEnServicio(charIdExpulsado) then
        local targetSource = Management.ObtenerSourceDeCharId(charIdExpulsado)
        Duties.SalirServicio(targetSource or 0, charIdExpulsado)
    end

    -- Eliminar de la faccion
    MySQL.query.await([[
        DELETE FROM ait_faccion_miembros WHERE char_id = ? AND faccion_id = ?
    ]], { charIdExpulsado, faccionId })

    -- Actualizar cache
    if Facciones.cache[faccionId] then
        Facciones.cache[faccionId].total_miembros = math.max(0, (Facciones.cache[faccionId].total_miembros or 1) - 1)
    end

    -- Remover de online
    if Facciones.miembrosOnline[faccionId] then
        Facciones.miembrosOnline[faccionId][charIdExpulsado] = nil
    end

    -- Log
    Facciones.RegistrarLog(faccionId, 'MIEMBRO_EXPULSADO', charIdExpulsor, charIdExpulsado, {
        motivo = motivo or 'Sin especificar',
        rango_expulsado = membresiaExpulsado.rango_nombre
    })

    -- Evento
    if AIT.EventBus then
        AIT.EventBus.emit('factions.member.kicked', {
            faccion_id = faccionId,
            char_id = charIdExpulsado,
            expulsado_por = charIdExpulsor,
            motivo = motivo
        })
    end

    -- Notificar al expulsado si esta online
    local targetSource = Management.ObtenerSourceDeCharId(charIdExpulsado)
    if targetSource then
        TriggerClientEvent('QBCore:Notify', targetSource, 'Has sido expulsado de la faccion', 'error')
        TriggerClientEvent('ait:factions:data', targetSource, nil) -- Limpiar datos de faccion
    end

    return true, ('Miembro expulsado correctamente'):format()
end

-- =====================================================================================
-- PROMOCION / DEGRADACION
-- =====================================================================================

--- Cambiar el rango de un miembro
---@param source number
---@param charIdPromotor number
---@param charIdObjetivo number
---@param nuevoNivel number
---@return boolean, string
function Management.CambiarRango(source, charIdPromotor, charIdObjetivo, nuevoNivel)
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    -- Verificar permisos
    local membresiaPromotor = Facciones.ObtenerFaccionDePersonaje(charIdPromotor)
    if not membresiaPromotor then
        return false, 'No perteneces a ninguna faccion'
    end

    if not membresiaPromotor.puede_promover then
        return false, 'No tienes permiso para cambiar rangos'
    end

    -- Verificar que el objetivo pertenece a la misma faccion
    local membresiaObjetivo = Facciones.ObtenerFaccionDePersonaje(charIdObjetivo)
    if not membresiaObjetivo or membresiaObjetivo.faccion_id ~= membresiaPromotor.faccion_id then
        return false, 'Este jugador no pertenece a tu faccion'
    end

    local faccionId = membresiaPromotor.faccion_id

    -- No se puede promover a alguien a un rango mayor o igual al propio (excepto lider)
    if nuevoNivel >= membresiaPromotor.rango_nivel and membresiaPromotor.rango_nivel < 5 then
        return false, 'No puedes promover a alguien a un rango mayor o igual al tuyo'
    end

    -- No se puede degradar a alguien de mayor o igual rango
    if membresiaObjetivo.rango_nivel >= membresiaPromotor.rango_nivel then
        return false, 'No puedes cambiar el rango de alguien de mayor o igual rango'
    end

    -- Obtener el nuevo rango
    local nuevoRango = MySQL.query.await([[
        SELECT * FROM ait_faccion_rangos WHERE faccion_id = ? AND nivel = ?
    ]], { faccionId, nuevoNivel })

    if not nuevoRango or #nuevoRango == 0 then
        return false, 'Rango no encontrado'
    end

    nuevoRango = nuevoRango[1]

    local esPromocion = nuevoNivel > membresiaObjetivo.rango_nivel
    local accion = esPromocion and 'MIEMBRO_PROMOVIDO' or 'MIEMBRO_DEGRADADO'

    -- Actualizar rango
    MySQL.query.await([[
        UPDATE ait_faccion_miembros SET rango_id = ? WHERE char_id = ? AND faccion_id = ?
    ]], { nuevoRango.rango_id, charIdObjetivo, faccionId })

    -- Log
    Facciones.RegistrarLog(faccionId, accion, charIdPromotor, charIdObjetivo, {
        rango_anterior = membresiaObjetivo.rango_nombre,
        rango_nuevo = nuevoRango.nombre,
        nivel_anterior = membresiaObjetivo.rango_nivel,
        nivel_nuevo = nuevoNivel
    })

    -- Notificar al objetivo si esta online
    local targetSource = Management.ObtenerSourceDeCharId(charIdObjetivo)
    if targetSource then
        local mensaje = esPromocion
            and ('Has sido promovido a %s'):format(nuevoRango.nombre)
            or ('Has sido degradado a %s'):format(nuevoRango.nombre)
        TriggerClientEvent('QBCore:Notify', targetSource, mensaje, esPromocion and 'success' or 'error')
    end

    local mensajeResultado = esPromocion
        and ('Miembro promovido a %s'):format(nuevoRango.nombre)
        or ('Miembro degradado a %s'):format(nuevoRango.nombre)

    return true, mensajeResultado
end

--- Transferir liderazgo
---@param source number
---@param charIdLiderActual number
---@param charIdNuevoLider number
---@return boolean, string
function Management.TransferirLiderazgo(source, charIdLiderActual, charIdNuevoLider)
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    local membresia = Facciones.ObtenerFaccionDePersonaje(charIdLiderActual)
    if not membresia then
        return false, 'No perteneces a ninguna faccion'
    end

    local faccionId = membresia.faccion_id
    local faccion = Facciones.Obtener(faccionId)

    -- Solo el lider puede transferir liderazgo
    if faccion.lider_char_id ~= charIdLiderActual then
        return false, 'Solo el lider puede transferir el liderazgo'
    end

    -- Verificar que el nuevo lider pertenece a la faccion
    local membresiaNuevo = Facciones.ObtenerFaccionDePersonaje(charIdNuevoLider)
    if not membresiaNuevo or membresiaNuevo.faccion_id ~= faccionId then
        return false, 'El nuevo lider debe pertenecer a la faccion'
    end

    -- Obtener rango de jefe
    local rangoJefe = MySQL.query.await([[
        SELECT * FROM ait_faccion_rangos WHERE faccion_id = ? ORDER BY nivel DESC LIMIT 1
    ]], { faccionId })

    if not rangoJefe or #rangoJefe == 0 then
        return false, 'Error al obtener rango de jefe'
    end

    rangoJefe = rangoJefe[1]

    -- Actualizar lider en faccion
    MySQL.query.await([[
        UPDATE ait_facciones SET lider_char_id = ? WHERE faccion_id = ?
    ]], { charIdNuevoLider, faccionId })

    -- Promover nuevo lider al rango maximo
    MySQL.query.await([[
        UPDATE ait_faccion_miembros SET rango_id = ? WHERE char_id = ? AND faccion_id = ?
    ]], { rangoJefe.rango_id, charIdNuevoLider, faccionId })

    -- Actualizar cache
    if Facciones.cache[faccionId] then
        Facciones.cache[faccionId].lider_char_id = charIdNuevoLider
    end

    -- Log
    Facciones.RegistrarLog(faccionId, 'LIDERAZGO_TRANSFERIDO', charIdLiderActual, charIdNuevoLider, {})

    -- Notificar a la faccion
    Facciones.NotificarFaccion(faccionId, {
        tipo = 'liderazgo',
        titulo = 'Cambio de liderazgo',
        mensaje = 'El liderazgo de la faccion ha sido transferido',
        prioridad = 'alta'
    })

    return true, 'Liderazgo transferido correctamente'
end

-- =====================================================================================
-- EDICION DE RANGOS
-- =====================================================================================

--- Crear un nuevo rango
---@param charIdCreador number
---@param datos table
---@return boolean, number|string
function Management.CrearRango(charIdCreador, datos)
    --[[
        datos = {
            nombre = 'Capitan',
            nivel = 4,
            salario_mult = 1.5,
            permisos = { 'invitar', 'expulsar' },
            color = '#FF0000',
            puede_reclutar = true,
            puede_expulsar = true,
            puede_promover = false,
            puede_tesoreria = false,
            puede_editar = false,
        }
    ]]

    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    local membresia = Facciones.ObtenerFaccionDePersonaje(charIdCreador)
    if not membresia then
        return false, 'No perteneces a ninguna faccion'
    end

    if not membresia.puede_editar then
        return false, 'No tienes permiso para editar rangos'
    end

    local faccionId = membresia.faccion_id

    -- Verificar que el nivel no exista
    local existente = MySQL.query.await([[
        SELECT rango_id FROM ait_faccion_rangos WHERE faccion_id = ? AND nivel = ?
    ]], { faccionId, datos.nivel })

    if existente and #existente > 0 then
        return false, 'Ya existe un rango con ese nivel'
    end

    -- No se puede crear un rango de nivel mayor o igual al propio
    if datos.nivel >= membresia.rango_nivel then
        return false, 'No puedes crear un rango de nivel mayor o igual al tuyo'
    end

    local rangoId = MySQL.insert.await([[
        INSERT INTO ait_faccion_rangos
        (faccion_id, nivel, nombre, salario_mult, permisos, color,
         puede_reclutar, puede_expulsar, puede_promover, puede_tesoreria, puede_editar)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        faccionId,
        datos.nivel,
        datos.nombre,
        datos.salario_mult or 1.0,
        datos.permisos and json.encode(datos.permisos) or '[]',
        datos.color or '#FFFFFF',
        datos.puede_reclutar and 1 or 0,
        datos.puede_expulsar and 1 or 0,
        datos.puede_promover and 1 or 0,
        datos.puede_tesoreria and 1 or 0,
        datos.puede_editar and 1 or 0,
    })

    -- Recargar cache de faccion
    Facciones.CargarFacciones()

    -- Log
    Facciones.RegistrarLog(faccionId, 'RANGO_CREADO', charIdCreador, nil, {
        rango_id = rangoId,
        nombre = datos.nombre,
        nivel = datos.nivel
    })

    return true, rangoId
end

--- Editar un rango existente
---@param charIdEditor number
---@param rangoId number
---@param datos table
---@return boolean, string
function Management.EditarRango(charIdEditor, rangoId, datos)
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    local membresia = Facciones.ObtenerFaccionDePersonaje(charIdEditor)
    if not membresia then
        return false, 'No perteneces a ninguna faccion'
    end

    if not membresia.puede_editar then
        return false, 'No tienes permiso para editar rangos'
    end

    -- Obtener rango a editar
    local rango = MySQL.query.await([[
        SELECT * FROM ait_faccion_rangos WHERE rango_id = ?
    ]], { rangoId })

    if not rango or #rango == 0 then
        return false, 'Rango no encontrado'
    end

    rango = rango[1]

    -- Verificar que sea de la misma faccion
    if rango.faccion_id ~= membresia.faccion_id then
        return false, 'Este rango no es de tu faccion'
    end

    -- No se puede editar un rango de nivel mayor o igual al propio
    if rango.nivel >= membresia.rango_nivel then
        return false, 'No puedes editar un rango de nivel mayor o igual al tuyo'
    end

    -- Construir query de actualizacion
    local sets = {}
    local params = {}

    if datos.nombre then
        table.insert(sets, 'nombre = ?')
        table.insert(params, datos.nombre)
    end

    if datos.salario_mult then
        table.insert(sets, 'salario_mult = ?')
        table.insert(params, datos.salario_mult)
    end

    if datos.permisos then
        table.insert(sets, 'permisos = ?')
        table.insert(params, json.encode(datos.permisos))
    end

    if datos.color then
        table.insert(sets, 'color = ?')
        table.insert(params, datos.color)
    end

    if datos.puede_reclutar ~= nil then
        table.insert(sets, 'puede_reclutar = ?')
        table.insert(params, datos.puede_reclutar and 1 or 0)
    end

    if datos.puede_expulsar ~= nil then
        table.insert(sets, 'puede_expulsar = ?')
        table.insert(params, datos.puede_expulsar and 1 or 0)
    end

    if datos.puede_promover ~= nil then
        table.insert(sets, 'puede_promover = ?')
        table.insert(params, datos.puede_promover and 1 or 0)
    end

    if datos.puede_tesoreria ~= nil then
        table.insert(sets, 'puede_tesoreria = ?')
        table.insert(params, datos.puede_tesoreria and 1 or 0)
    end

    if datos.puede_editar ~= nil then
        table.insert(sets, 'puede_editar = ?')
        table.insert(params, datos.puede_editar and 1 or 0)
    end

    if #sets == 0 then
        return false, 'No hay datos para actualizar'
    end

    table.insert(params, rangoId)

    MySQL.query.await(
        'UPDATE ait_faccion_rangos SET ' .. table.concat(sets, ', ') .. ' WHERE rango_id = ?',
        params
    )

    -- Recargar cache
    Facciones.CargarFacciones()

    -- Log
    Facciones.RegistrarLog(membresia.faccion_id, 'RANGO_EDITADO', charIdEditor, nil, {
        rango_id = rangoId,
        cambios = datos
    })

    return true, 'Rango actualizado correctamente'
end

--- Eliminar un rango
---@param charIdEliminador number
---@param rangoId number
---@return boolean, string
function Management.EliminarRango(charIdEliminador, rangoId)
    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    local membresia = Facciones.ObtenerFaccionDePersonaje(charIdEliminador)
    if not membresia then
        return false, 'No perteneces a ninguna faccion'
    end

    if not membresia.puede_editar then
        return false, 'No tienes permiso para eliminar rangos'
    end

    -- Obtener rango
    local rango = MySQL.query.await([[
        SELECT * FROM ait_faccion_rangos WHERE rango_id = ?
    ]], { rangoId })

    if not rango or #rango == 0 then
        return false, 'Rango no encontrado'
    end

    rango = rango[1]

    -- Verificar que sea de la misma faccion
    if rango.faccion_id ~= membresia.faccion_id then
        return false, 'Este rango no es de tu faccion'
    end

    -- No se puede eliminar un rango de nivel mayor o igual al propio
    if rango.nivel >= membresia.rango_nivel then
        return false, 'No puedes eliminar un rango de nivel mayor o igual al tuyo'
    end

    -- Verificar que no haya miembros con ese rango
    local miembrosConRango = MySQL.query.await([[
        SELECT COUNT(*) as total FROM ait_faccion_miembros WHERE rango_id = ?
    ]], { rangoId })

    if miembrosConRango and miembrosConRango[1] and miembrosConRango[1].total > 0 then
        return false, 'No se puede eliminar un rango con miembros asignados'
    end

    -- Eliminar rango
    MySQL.query.await('DELETE FROM ait_faccion_rangos WHERE rango_id = ?', { rangoId })

    -- Recargar cache
    Facciones.CargarFacciones()

    -- Log
    Facciones.RegistrarLog(membresia.faccion_id, 'RANGO_ELIMINADO', charIdEliminador, nil, {
        rango_id = rangoId,
        nombre = rango.nombre,
        nivel = rango.nivel
    })

    return true, 'Rango eliminado correctamente'
end

--- Obtener rangos de una faccion
---@param faccionId number
---@return table
function Management.ObtenerRangos(faccionId)
    return MySQL.query.await([[
        SELECT r.*, COUNT(m.miembro_id) as total_miembros
        FROM ait_faccion_rangos r
        LEFT JOIN ait_faccion_miembros m ON r.rango_id = m.rango_id
        WHERE r.faccion_id = ?
        GROUP BY r.rango_id
        ORDER BY r.nivel ASC
    ]], { faccionId }) or {}
end

-- =====================================================================================
-- EDICION DE FACCION
-- =====================================================================================

--- Editar informacion de la faccion
---@param charIdEditor number
---@param datos table
---@return boolean, string
function Management.EditarFaccion(charIdEditor, datos)
    --[[
        datos = {
            descripcion = 'Nueva descripcion',
            color = '#FF0000',
            logo_url = 'https://...',
            sede_coords = { x = 0, y = 0, z = 0 },
            publica = true,
            max_miembros = 60,
            salario_base = 600,
        }
    ]]

    local Facciones = AIT.Engines.Factions
    if not Facciones then
        return false, 'Sistema de facciones no disponible'
    end

    local membresia = Facciones.ObtenerFaccionDePersonaje(charIdEditor)
    if not membresia then
        return false, 'No perteneces a ninguna faccion'
    end

    if not membresia.puede_editar then
        return false, 'No tienes permiso para editar la faccion'
    end

    local faccionId = membresia.faccion_id

    -- Construir query de actualizacion
    local sets = {}
    local params = {}

    if datos.descripcion then
        table.insert(sets, 'descripcion = ?')
        table.insert(params, datos.descripcion)
    end

    if datos.color then
        table.insert(sets, 'color = ?')
        table.insert(params, datos.color)
    end

    if datos.logo_url then
        table.insert(sets, 'logo_url = ?')
        table.insert(params, datos.logo_url)
    end

    if datos.sede_coords then
        table.insert(sets, 'sede_coords = ?')
        table.insert(params, json.encode(datos.sede_coords))
    end

    if datos.publica ~= nil then
        table.insert(sets, 'publica = ?')
        table.insert(params, datos.publica and 1 or 0)
    end

    if datos.max_miembros then
        table.insert(sets, 'max_miembros = ?')
        table.insert(params, datos.max_miembros)
    end

    if datos.salario_base then
        table.insert(sets, 'salario_base = ?')
        table.insert(params, datos.salario_base)
    end

    if #sets == 0 then
        return false, 'No hay datos para actualizar'
    end

    table.insert(params, faccionId)

    MySQL.query.await(
        'UPDATE ait_facciones SET ' .. table.concat(sets, ', ') .. ' WHERE faccion_id = ?',
        params
    )

    -- Recargar cache
    Facciones.CargarFacciones()

    -- Log
    Facciones.RegistrarLog(faccionId, 'FACCION_EDITADA', charIdEditor, nil, { cambios = datos })

    return true, 'Faccion actualizada correctamente'
end

-- =====================================================================================
-- UTILIDADES
-- =====================================================================================

function Management.ObtenerSourceDeCharId(charId)
    if not AIT.QBCore then return nil end

    local players = AIT.QBCore.Functions.GetPlayers()
    for _, playerId in ipairs(players) do
        local Player = AIT.QBCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData.citizenid == charId then
            return playerId
        end
    end

    return nil
end

function Management.ObtenerNombrePersonaje(charId)
    local result = MySQL.query.await([[
        SELECT nombre, apellido FROM ait_characters WHERE char_id = ?
    ]], { charId })

    if result and result[1] then
        return ('%s %s'):format(result[1].nombre or '', result[1].apellido or '')
    end

    return nil
end

function Management.LimpiarInvitacionesExpiradas()
    MySQL.query([[
        UPDATE ait_faccion_invitaciones
        SET estado = 'expirada'
        WHERE estado = 'pendiente' AND fecha_expiracion < NOW()
    ]])

    if AIT.Log then
        AIT.Log.debug('FACTIONS:MANAGEMENT', 'Invitaciones expiradas limpiadas')
    end
end

-- =====================================================================================
-- EVENTOS Y CALLBACKS
-- =====================================================================================

function Management.RegistrarEventos()
    -- Invitar jugador
    RegisterNetEvent('ait:factions:management:invite', function(targetCharId, mensaje)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, msg = Management.Invitar(source, charId, targetCharId, mensaje)
        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end)

    -- Responder invitacion
    RegisterNetEvent('ait:factions:management:respondInvite', function(invitacionId, aceptar)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, msg

        if aceptar then
            success, msg = Management.AceptarInvitacion(charId, invitacionId)
        else
            success, msg = Management.RechazarInvitacion(charId, invitacionId)
        end

        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end)

    -- Expulsar miembro
    RegisterNetEvent('ait:factions:management:kick', function(targetCharId, motivo)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, msg = Management.Expulsar(source, charId, targetCharId, motivo)
        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end)

    -- Cambiar rango
    RegisterNetEvent('ait:factions:management:setRank', function(targetCharId, nuevoNivel)
        local source = source
        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local success, msg = Management.CambiarRango(source, charId, targetCharId, nuevoNivel)
        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end)
end

function Management.RegistrarCallbacks()
    if not AIT.QBCore then return end

    -- Obtener miembros de la faccion
    AIT.QBCore.Functions.CreateCallback('ait:factions:management:getMembers', function(source, cb)
        local Player = AIT.QBCore.Functions.GetPlayer(source)
        if not Player then
            cb(nil)
            return
        end

        local charId = Player.PlayerData.citizenid
        local Facciones = AIT.Engines.Factions
        local membresia = Facciones and Facciones.ObtenerFaccionDePersonaje(charId)

        if not membresia then
            cb(nil)
            return
        end

        cb(Facciones.ObtenerMiembros(membresia.faccion_id))
    end)

    -- Obtener rangos
    AIT.QBCore.Functions.CreateCallback('ait:factions:management:getRanks', function(source, cb)
        local Player = AIT.QBCore.Functions.GetPlayer(source)
        if not Player then
            cb(nil)
            return
        end

        local charId = Player.PlayerData.citizenid
        local Facciones = AIT.Engines.Factions
        local membresia = Facciones and Facciones.ObtenerFaccionDePersonaje(charId)

        if not membresia then
            cb(nil)
            return
        end

        cb(Management.ObtenerRangos(membresia.faccion_id))
    end)

    -- Obtener solicitudes pendientes
    AIT.QBCore.Functions.CreateCallback('ait:factions:management:getApplications', function(source, cb)
        local Player = AIT.QBCore.Functions.GetPlayer(source)
        if not Player then
            cb(nil)
            return
        end

        local charId = Player.PlayerData.citizenid
        local Facciones = AIT.Engines.Factions
        local membresia = Facciones and Facciones.ObtenerFaccionDePersonaje(charId)

        if not membresia or not membresia.puede_reclutar then
            cb(nil)
            return
        end

        cb(Management.ObtenerSolicitudesPendientes(membresia.faccion_id))
    end)

    -- Obtener logs
    AIT.QBCore.Functions.CreateCallback('ait:factions:management:getLogs', function(source, cb, opciones)
        local Player = AIT.QBCore.Functions.GetPlayer(source)
        if not Player then
            cb(nil)
            return
        end

        local charId = Player.PlayerData.citizenid
        local Facciones = AIT.Engines.Factions
        local membresia = Facciones and Facciones.ObtenerFaccionDePersonaje(charId)

        if not membresia then
            cb(nil)
            return
        end

        -- Solo supervisores y superiores pueden ver logs
        if membresia.rango_nivel < 4 then
            cb(nil)
            return
        end

        cb(Facciones.ObtenerLogs(membresia.faccion_id, opciones))
    end)
end

function Management.RegistrarComandos()
    -- Invitar jugador por ID
    RegisterCommand('finvitar', function(source, args, rawCommand)
        if source == 0 then return end

        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        if #args < 1 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Uso', '/finvitar [id_servidor]' } })
            return
        end

        local targetSource = tonumber(args[1])
        local TargetPlayer = AIT.QBCore.Functions.GetPlayer(targetSource)

        if not TargetPlayer then
            TriggerClientEvent('QBCore:Notify', source, 'Jugador no encontrado', 'error')
            return
        end

        local charId = Player.PlayerData.citizenid
        local targetCharId = TargetPlayer.PlayerData.citizenid
        local mensaje = table.concat(args, ' ', 2)

        local success, msg = Management.Invitar(source, charId, targetCharId, mensaje ~= '' and mensaje or nil)
        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end, false)

    -- Expulsar miembro
    RegisterCommand('fexpulsar', function(source, args, rawCommand)
        if source == 0 then return end

        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        if #args < 1 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Uso', '/fexpulsar [id_servidor] [motivo]' } })
            return
        end

        local targetSource = tonumber(args[1])
        local TargetPlayer = AIT.QBCore.Functions.GetPlayer(targetSource)

        if not TargetPlayer then
            TriggerClientEvent('QBCore:Notify', source, 'Jugador no encontrado', 'error')
            return
        end

        local charId = Player.PlayerData.citizenid
        local targetCharId = TargetPlayer.PlayerData.citizenid
        local motivo = table.concat(args, ' ', 2)

        local success, msg = Management.Expulsar(source, charId, targetCharId, motivo ~= '' and motivo or nil)
        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end, false)

    -- Promover/Degradar miembro
    RegisterCommand('frango', function(source, args, rawCommand)
        if source == 0 then return end

        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        if #args < 2 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Uso', '/frango [id_servidor] [nivel]' } })
            return
        end

        local targetSource = tonumber(args[1])
        local nuevoNivel = tonumber(args[2])
        local TargetPlayer = AIT.QBCore.Functions.GetPlayer(targetSource)

        if not TargetPlayer then
            TriggerClientEvent('QBCore:Notify', source, 'Jugador no encontrado', 'error')
            return
        end

        if not nuevoNivel then
            TriggerClientEvent('QBCore:Notify', source, 'Nivel invalido', 'error')
            return
        end

        local charId = Player.PlayerData.citizenid
        local targetCharId = TargetPlayer.PlayerData.citizenid

        local success, msg = Management.CambiarRango(source, charId, targetCharId, nuevoNivel)
        TriggerClientEvent('QBCore:Notify', source, msg, success and 'success' or 'error')
    end, false)

    -- Ver miembros
    RegisterCommand('fmiembros', function(source, args, rawCommand)
        if source == 0 then return end

        local Player = AIT.QBCore and AIT.QBCore.Functions.GetPlayer(source)
        if not Player then return end

        local charId = Player.PlayerData.citizenid
        local Facciones = AIT.Engines.Factions
        local membresia = Facciones and Facciones.ObtenerFaccionDePersonaje(charId)

        if not membresia then
            TriggerClientEvent('QBCore:Notify', source, 'No perteneces a ninguna faccion', 'error')
            return
        end

        local miembros = Facciones.ObtenerMiembros(membresia.faccion_id)
        local mensaje = '=== Miembros de ' .. membresia.nombre_corto .. ' ==='

        for _, m in ipairs(miembros) do
            mensaje = mensaje .. '\n' .. (m.char_nombre or 'Desconocido') .. ' ' ..
                (m.char_apellido or '') .. ' - ' .. m.rango_nombre
        end

        TriggerClientEvent('chat:addMessage', source, { args = { 'Faccion', mensaje } })
    end, false)
end

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

Management.Invite = Management.Invitar
Management.AcceptInvite = Management.AceptarInvitacion
Management.DeclineInvite = Management.RechazarInvitacion
Management.GetPendingInvites = Management.ObtenerInvitacionesPendientes
Management.Apply = Management.EnviarSolicitud
Management.ApproveApplication = Management.AprobarSolicitud
Management.RejectApplication = Management.RechazarSolicitud
Management.GetPendingApplications = Management.ObtenerSolicitudesPendientes
Management.Kick = Management.Expulsar
Management.SetRank = Management.CambiarRango
Management.TransferLeadership = Management.TransferirLiderazgo
Management.CreateRank = Management.CrearRango
Management.EditRank = Management.EditarRango
Management.DeleteRank = Management.EliminarRango
Management.GetRanks = Management.ObtenerRangos
Management.EditFaction = Management.EditarFaccion

-- =====================================================================================
-- REGISTRAR EN ENGINE
-- =====================================================================================

AIT.Engines.Factions.Management = Management

return Management
