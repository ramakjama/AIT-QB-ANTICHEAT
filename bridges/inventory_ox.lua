--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     AIT FRAMEWORK - BRIDGE OX_INVENTORY                   ║
    ║                                                                           ║
    ║  Bridge de compatibilidad para ox_inventory                               ║
    ║  Proporciona una capa de abstraccion para el manejo de inventarios        ║
    ║                                                                           ║
    ║  Namespace: AIT.Bridges.Inventory                                         ║
    ║  Version: 1.0.0                                                           ║
    ║  Autor: AIT Framework Team                                                ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]--

-- ═══════════════════════════════════════════════════════════════════════════
-- INICIALIZACION DEL NAMESPACE
-- ═══════════════════════════════════════════════════════════════════════════

AIT = AIT or {}
AIT.Bridges = AIT.Bridges or {}
AIT.Bridges.Inventory = AIT.Bridges.Inventory or {}

local Inventario = AIT.Bridges.Inventory
local ox_inventory = exports.ox_inventory

-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIGURACION DEL BRIDGE
-- ═══════════════════════════════════════════════════════════════════════════

Inventario.Config = {
    -- Tipo de inventario que maneja este bridge
    Tipo = "ox_inventory",

    -- Version minima requerida de ox_inventory
    VersionMinima = "2.0.0",

    -- Habilitar logs de depuracion
    Debug = false,

    -- Configuracion de stashes
    Stashes = {
        -- Slots por defecto para stashes
        SlotsDefecto = 50,
        -- Peso maximo por defecto (en gramos)
        PesoMaximoDefecto = 100000,
    },

    -- Configuracion de tiendas
    Tiendas = {
        -- Permitir reabastecimiento automatico
        ReabastecimientoAuto = true,
        -- Intervalo de reabastecimiento (en minutos)
        IntervaloReabastecimiento = 30,
    },

    -- Configuracion de crafteo
    Crafteo = {
        -- Habilitar sistema de crafteo
        Habilitado = true,
        -- Tiempo base de crafteo (en milisegundos)
        TiempoBase = 5000,
    }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- UTILIDADES INTERNAS
-- ═══════════════════════════════════════════════════════════════════════════

--- Funcion interna para registrar mensajes de depuracion
--- @param mensaje string Mensaje a registrar
--- @param nivel string Nivel del log (info, warn, error)
local function RegistrarLog(mensaje, nivel)
    if not Inventario.Config.Debug and nivel ~= "error" then return end

    local prefijo = "[AIT-Inventory-OX]"
    local nivelFormateado = string.upper(nivel or "INFO")

    print(string.format("%s [%s] %s", prefijo, nivelFormateado, mensaje))
end

--- Valida si un jugador existe y esta conectado
--- @param source number ID del jugador
--- @return boolean Verdadero si el jugador es valido
local function ValidarJugador(source)
    if not source or source <= 0 then
        RegistrarLog("ID de jugador invalido: " .. tostring(source), "error")
        return false
    end

    local jugador = GetPlayerPed(source)
    if not jugador or jugador == 0 then
        RegistrarLog("Jugador no encontrado: " .. tostring(source), "error")
        return false
    end

    return true
end

--- Valida si un item existe en la configuracion de ox_inventory
--- @param nombreItem string Nombre del item
--- @return boolean Verdadero si el item existe
local function ValidarItem(nombreItem)
    if not nombreItem or nombreItem == "" then
        RegistrarLog("Nombre de item vacio o nulo", "error")
        return false
    end

    local itemData = ox_inventory:Items(nombreItem)
    if not itemData then
        RegistrarLog("Item no encontrado en ox_inventory: " .. nombreItem, "warn")
        return false
    end

    return true
end

--- Convierte metadatos al formato esperado por ox_inventory
--- @param metadatos table Tabla de metadatos
--- @return table Metadatos formateados
local function FormatearMetadatos(metadatos)
    if not metadatos then return nil end
    if type(metadatos) ~= "table" then return nil end

    -- ox_inventory espera metadatos como tabla simple
    local resultado = {}
    for clave, valor in pairs(metadatos) do
        resultado[clave] = valor
    end

    return resultado
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCIONES PRINCIPALES DE ITEMS
-- ═══════════════════════════════════════════════════════════════════════════

--- Agrega un item al inventario de un jugador
--- @param source number ID del jugador
--- @param nombreItem string Nombre del item a agregar
--- @param cantidad number Cantidad a agregar
--- @param metadatos table Metadatos opcionales del item
--- @param slot number Slot especifico (opcional)
--- @return boolean Verdadero si se agrego correctamente
function Inventario.AgregarItem(source, nombreItem, cantidad, metadatos, slot)
    -- Validaciones iniciales
    if not ValidarJugador(source) then
        return false
    end

    if not ValidarItem(nombreItem) then
        return false
    end

    cantidad = tonumber(cantidad) or 1
    if cantidad <= 0 then
        RegistrarLog("Cantidad invalida para agregar: " .. tostring(cantidad), "error")
        return false
    end

    -- Formatear metadatos si existen
    local metadatosFormateados = FormatearMetadatos(metadatos)

    -- Intentar agregar el item
    local exito = ox_inventory:AddItem(source, nombreItem, cantidad, metadatosFormateados, slot)

    if exito then
        RegistrarLog(string.format("Item agregado: %s x%d a jugador %d", nombreItem, cantidad, source), "info")

        -- Disparar evento para otros sistemas
        TriggerEvent("ait:inventory:itemAgregado", source, nombreItem, cantidad, metadatosFormateados)
    else
        RegistrarLog(string.format("Error al agregar item: %s x%d a jugador %d", nombreItem, cantidad, source), "error")
    end

    return exito
end

--- Remueve un item del inventario de un jugador
--- @param source number ID del jugador
--- @param nombreItem string Nombre del item a remover
--- @param cantidad number Cantidad a remover
--- @param metadatos table Metadatos para identificar item especifico (opcional)
--- @param slot number Slot especifico (opcional)
--- @return boolean Verdadero si se removio correctamente
function Inventario.RemoverItem(source, nombreItem, cantidad, metadatos, slot)
    -- Validaciones iniciales
    if not ValidarJugador(source) then
        return false
    end

    cantidad = tonumber(cantidad) or 1
    if cantidad <= 0 then
        RegistrarLog("Cantidad invalida para remover: " .. tostring(cantidad), "error")
        return false
    end

    -- Verificar que el jugador tiene suficiente cantidad
    local cantidadActual = Inventario.ObtenerCantidadItem(source, nombreItem, metadatos)
    if cantidadActual < cantidad then
        RegistrarLog(string.format("Cantidad insuficiente: tiene %d, requiere %d", cantidadActual, cantidad), "warn")
        return false
    end

    -- Formatear metadatos si existen
    local metadatosFormateados = FormatearMetadatos(metadatos)

    -- Intentar remover el item
    local exito = ox_inventory:RemoveItem(source, nombreItem, cantidad, metadatosFormateados, slot)

    if exito then
        RegistrarLog(string.format("Item removido: %s x%d de jugador %d", nombreItem, cantidad, source), "info")

        -- Disparar evento para otros sistemas
        TriggerEvent("ait:inventory:itemRemovido", source, nombreItem, cantidad, metadatosFormateados)
    else
        RegistrarLog(string.format("Error al remover item: %s x%d de jugador %d", nombreItem, cantidad, source), "error")
    end

    return exito
end

--- Obtiene la cantidad de un item en el inventario del jugador
--- @param source number ID del jugador
--- @param nombreItem string Nombre del item
--- @param metadatos table Metadatos para filtrar (opcional)
--- @return number Cantidad del item
function Inventario.ObtenerCantidadItem(source, nombreItem, metadatos)
    if not ValidarJugador(source) then
        return 0
    end

    local metadatosFormateados = FormatearMetadatos(metadatos)
    local cantidad = ox_inventory:GetItemCount(source, nombreItem, metadatosFormateados)

    return cantidad or 0
end

--- Verifica si el jugador tiene un item especifico
--- @param source number ID del jugador
--- @param nombreItem string Nombre del item
--- @param cantidadRequerida number Cantidad minima requerida (por defecto 1)
--- @param metadatos table Metadatos para filtrar (opcional)
--- @return boolean Verdadero si tiene el item
function Inventario.TieneItem(source, nombreItem, cantidadRequerida, metadatos)
    cantidadRequerida = tonumber(cantidadRequerida) or 1
    local cantidadActual = Inventario.ObtenerCantidadItem(source, nombreItem, metadatos)

    return cantidadActual >= cantidadRequerida
end

--- Obtiene informacion de un item especifico
--- @param nombreItem string Nombre del item
--- @return table Informacion del item o nil si no existe
function Inventario.ObtenerInfoItem(nombreItem)
    if not nombreItem or nombreItem == "" then
        return nil
    end

    local itemData = ox_inventory:Items(nombreItem)
    if not itemData then
        return nil
    end

    return {
        nombre = itemData.name,
        etiqueta = itemData.label,
        peso = itemData.weight,
        apilable = itemData.stack,
        descripcion = itemData.description,
        esArma = itemData.weapon or false,
        metadatos = itemData.metadata
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE INVENTARIO COMPLETO
-- ═══════════════════════════════════════════════════════════════════════════

--- Obtiene el inventario completo de un jugador
--- @param source number ID del jugador
--- @return table Lista de items en el inventario
function Inventario.ObtenerInventario(source)
    if not ValidarJugador(source) then
        return {}
    end

    local items = ox_inventory:GetInventoryItems(source)
    if not items then
        return {}
    end

    -- Formatear los items al formato estandar de AIT
    local inventarioFormateado = {}
    for slot, item in pairs(items) do
        if item then
            table.insert(inventarioFormateado, {
                slot = slot,
                nombre = item.name,
                etiqueta = item.label,
                cantidad = item.count,
                peso = item.weight,
                metadatos = item.metadata,
                esArma = item.weapon or false
            })
        end
    end

    return inventarioFormateado
end

--- Obtiene un item especifico por slot
--- @param source number ID del jugador
--- @param slot number Numero de slot
--- @return table Informacion del item o nil
function Inventario.ObtenerItemPorSlot(source, slot)
    if not ValidarJugador(source) then
        return nil
    end

    slot = tonumber(slot)
    if not slot or slot <= 0 then
        return nil
    end

    local item = ox_inventory:GetSlot(source, slot)
    if not item then
        return nil
    end

    return {
        slot = slot,
        nombre = item.name,
        etiqueta = item.label,
        cantidad = item.count,
        peso = item.weight,
        metadatos = item.metadata,
        esArma = item.weapon or false
    }
end

--- Establece los slots maximos del inventario de un jugador
--- @param source number ID del jugador
--- @param slots number Numero de slots
--- @return boolean Verdadero si se establecio correctamente
function Inventario.EstablecerSlots(source, slots)
    if not ValidarJugador(source) then
        return false
    end

    slots = tonumber(slots)
    if not slots or slots <= 0 then
        RegistrarLog("Numero de slots invalido: " .. tostring(slots), "error")
        return false
    end

    ox_inventory:SetMaxWeight(source, nil, slots)
    RegistrarLog(string.format("Slots establecidos a %d para jugador %d", slots, source), "info")

    return true
end

--- Establece el peso maximo del inventario de un jugador
--- @param source number ID del jugador
--- @param pesoMaximo number Peso maximo en gramos
--- @return boolean Verdadero si se establecio correctamente
function Inventario.EstablecerPesoMaximo(source, pesoMaximo)
    if not ValidarJugador(source) then
        return false
    end

    pesoMaximo = tonumber(pesoMaximo)
    if not pesoMaximo or pesoMaximo <= 0 then
        RegistrarLog("Peso maximo invalido: " .. tostring(pesoMaximo), "error")
        return false
    end

    ox_inventory:SetMaxWeight(source, pesoMaximo)
    RegistrarLog(string.format("Peso maximo establecido a %d para jugador %d", pesoMaximo, source), "info")

    return true
end

--- Obtiene el peso actual y maximo del inventario
--- @param source number ID del jugador
--- @return number, number Peso actual y peso maximo
function Inventario.ObtenerPeso(source)
    if not ValidarJugador(source) then
        return 0, 0
    end

    local pesoActual = ox_inventory:GetInventoryWeight(source) or 0
    -- ox_inventory no tiene funcion directa para peso maximo, usar config
    local pesoMaximo = Inventario.Config.Stashes.PesoMaximoDefecto

    return pesoActual, pesoMaximo
end

--- Limpia el inventario completo de un jugador
--- @param source number ID del jugador
--- @return boolean Verdadero si se limpio correctamente
function Inventario.LimpiarInventario(source)
    if not ValidarJugador(source) then
        return false
    end

    ox_inventory:ClearInventory(source)
    RegistrarLog(string.format("Inventario limpiado para jugador %d", source), "info")

    TriggerEvent("ait:inventory:inventarioLimpiado", source)

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SISTEMA DE STASHES (ALMACENES)
-- ═══════════════════════════════════════════════════════════════════════════

--- Registra un nuevo stash
--- @param idStash string Identificador unico del stash
--- @param etiqueta string Nombre visible del stash
--- @param slots number Numero de slots (opcional)
--- @param pesoMaximo number Peso maximo (opcional)
--- @param propietario string Propietario del stash (opcional)
--- @param grupos table Grupos con acceso (opcional)
--- @return boolean Verdadero si se registro correctamente
function Inventario.RegistrarStash(idStash, etiqueta, slots, pesoMaximo, propietario, grupos)
    if not idStash or idStash == "" then
        RegistrarLog("ID de stash invalido", "error")
        return false
    end

    etiqueta = etiqueta or idStash
    slots = tonumber(slots) or Inventario.Config.Stashes.SlotsDefecto
    pesoMaximo = tonumber(pesoMaximo) or Inventario.Config.Stashes.PesoMaximoDefecto

    local datosStash = {
        id = idStash,
        label = etiqueta,
        slots = slots,
        weight = pesoMaximo,
        owner = propietario,
        groups = grupos
    }

    ox_inventory:RegisterStash(idStash, etiqueta, slots, pesoMaximo, propietario, grupos)

    RegistrarLog(string.format("Stash registrado: %s (%s)", idStash, etiqueta), "info")

    return true
end

--- Abre un stash para un jugador
--- @param source number ID del jugador
--- @param idStash string Identificador del stash
--- @return boolean Verdadero si se abrio correctamente
function Inventario.AbrirStash(source, idStash)
    if not ValidarJugador(source) then
        return false
    end

    if not idStash or idStash == "" then
        RegistrarLog("ID de stash invalido para abrir", "error")
        return false
    end

    ox_inventory:forceOpenInventory(source, "stash", idStash)

    RegistrarLog(string.format("Stash %s abierto para jugador %d", idStash, source), "info")

    return true
end

--- Agrega un item a un stash
--- @param idStash string Identificador del stash
--- @param nombreItem string Nombre del item
--- @param cantidad number Cantidad a agregar
--- @param metadatos table Metadatos del item (opcional)
--- @return boolean Verdadero si se agrego correctamente
function Inventario.AgregarItemStash(idStash, nombreItem, cantidad, metadatos)
    if not idStash or idStash == "" then
        RegistrarLog("ID de stash invalido", "error")
        return false
    end

    if not ValidarItem(nombreItem) then
        return false
    end

    cantidad = tonumber(cantidad) or 1
    local metadatosFormateados = FormatearMetadatos(metadatos)

    local exito = ox_inventory:AddItem("stash:" .. idStash, nombreItem, cantidad, metadatosFormateados)

    if exito then
        RegistrarLog(string.format("Item %s x%d agregado a stash %s", nombreItem, cantidad, idStash), "info")
    end

    return exito or false
end

--- Remueve un item de un stash
--- @param idStash string Identificador del stash
--- @param nombreItem string Nombre del item
--- @param cantidad number Cantidad a remover
--- @param metadatos table Metadatos del item (opcional)
--- @return boolean Verdadero si se removio correctamente
function Inventario.RemoverItemStash(idStash, nombreItem, cantidad, metadatos)
    if not idStash or idStash == "" then
        RegistrarLog("ID de stash invalido", "error")
        return false
    end

    cantidad = tonumber(cantidad) or 1
    local metadatosFormateados = FormatearMetadatos(metadatos)

    local exito = ox_inventory:RemoveItem("stash:" .. idStash, nombreItem, cantidad, metadatosFormateados)

    if exito then
        RegistrarLog(string.format("Item %s x%d removido de stash %s", nombreItem, cantidad, idStash), "info")
    end

    return exito or false
end

--- Obtiene el contenido de un stash
--- @param idStash string Identificador del stash
--- @return table Lista de items en el stash
function Inventario.ObtenerContenidoStash(idStash)
    if not idStash or idStash == "" then
        return {}
    end

    local items = ox_inventory:GetInventoryItems("stash:" .. idStash)
    if not items then
        return {}
    end

    local contenido = {}
    for slot, item in pairs(items) do
        if item then
            table.insert(contenido, {
                slot = slot,
                nombre = item.name,
                etiqueta = item.label,
                cantidad = item.count,
                peso = item.weight,
                metadatos = item.metadata
            })
        end
    end

    return contenido
end

--- Limpia el contenido de un stash
--- @param idStash string Identificador del stash
--- @return boolean Verdadero si se limpio correctamente
function Inventario.LimpiarStash(idStash)
    if not idStash or idStash == "" then
        RegistrarLog("ID de stash invalido para limpiar", "error")
        return false
    end

    ox_inventory:ClearInventory("stash:" .. idStash)

    RegistrarLog(string.format("Stash %s limpiado", idStash), "info")

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SISTEMA DE TIENDAS (SHOPS)
-- ═══════════════════════════════════════════════════════════════════════════

--- Registra una nueva tienda
--- @param idTienda string Identificador unico de la tienda
--- @param datosInv table Configuracion del inventario
--- @param ubicaciones table Lista de ubicaciones (coordenadas)
--- @return boolean Verdadero si se registro correctamente
function Inventario.RegistrarTienda(idTienda, datosInv, ubicaciones)
    if not idTienda or idTienda == "" then
        RegistrarLog("ID de tienda invalido", "error")
        return false
    end

    if not datosInv or type(datosInv) ~= "table" then
        RegistrarLog("Datos de inventario invalidos para tienda", "error")
        return false
    end

    -- Formatear items de la tienda al formato de ox_inventory
    local itemsTienda = {}
    if datosInv.items then
        for _, item in pairs(datosInv.items) do
            table.insert(itemsTienda, {
                name = item.nombre or item.name,
                price = item.precio or item.price,
                count = item.cantidad or item.count,
                currency = item.moneda or item.currency or "money",
                metadata = item.metadatos or item.metadata
            })
        end
    end

    local configTienda = {
        name = datosInv.etiqueta or datosInv.nombre or idTienda,
        inventory = itemsTienda,
        locations = ubicaciones,
        groups = datosInv.grupos
    }

    -- ox_inventory requiere registro en archivo de configuracion
    -- Esta funcion prepara los datos para uso dinamico
    exports.ox_inventory:RegisterShop(idTienda, configTienda)

    RegistrarLog(string.format("Tienda registrada: %s", idTienda), "info")

    return true
end

--- Abre una tienda para un jugador
--- @param source number ID del jugador
--- @param idTienda string Identificador de la tienda
--- @return boolean Verdadero si se abrio correctamente
function Inventario.AbrirTienda(source, idTienda)
    if not ValidarJugador(source) then
        return false
    end

    if not idTienda or idTienda == "" then
        RegistrarLog("ID de tienda invalido para abrir", "error")
        return false
    end

    ox_inventory:openInventory(source, "shop", { type = idTienda })

    RegistrarLog(string.format("Tienda %s abierta para jugador %d", idTienda, source), "info")

    return true
end

--- Obtiene los items disponibles en una tienda
--- @param idTienda string Identificador de la tienda
--- @return table Lista de items de la tienda
function Inventario.ObtenerItemsTienda(idTienda)
    if not idTienda or idTienda == "" then
        return {}
    end

    -- Esta informacion normalmente viene del archivo de configuracion
    -- Retornamos estructura vacia ya que ox_inventory maneja esto internamente
    RegistrarLog(string.format("Consultando items de tienda: %s", idTienda), "info")

    return {}
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SISTEMA DE CRAFTEO
-- ═══════════════════════════════════════════════════════════════════════════

-- Almacen local de recetas de crafteo
local RecetasCrafteo = {}

--- Registra una nueva receta de crafteo
--- @param idReceta string Identificador unico de la receta
--- @param datosReceta table Datos de la receta
--- @return boolean Verdadero si se registro correctamente
function Inventario.RegistrarRecetaCrafteo(idReceta, datosReceta)
    if not Inventario.Config.Crafteo.Habilitado then
        RegistrarLog("Sistema de crafteo deshabilitado", "warn")
        return false
    end

    if not idReceta or idReceta == "" then
        RegistrarLog("ID de receta invalido", "error")
        return false
    end

    if not datosReceta or type(datosReceta) ~= "table" then
        RegistrarLog("Datos de receta invalidos", "error")
        return false
    end

    -- Validar que tiene ingredientes y resultado
    if not datosReceta.ingredientes or #datosReceta.ingredientes == 0 then
        RegistrarLog("Receta sin ingredientes", "error")
        return false
    end

    if not datosReceta.resultado then
        RegistrarLog("Receta sin resultado", "error")
        return false
    end

    RecetasCrafteo[idReceta] = {
        id = idReceta,
        nombre = datosReceta.nombre or idReceta,
        ingredientes = datosReceta.ingredientes,
        resultado = datosReceta.resultado,
        cantidadResultado = datosReceta.cantidadResultado or 1,
        tiempo = datosReceta.tiempo or Inventario.Config.Crafteo.TiempoBase,
        nivel = datosReceta.nivel or 0,
        profesion = datosReceta.profesion,
        metadatosResultado = datosReceta.metadatosResultado
    }

    RegistrarLog(string.format("Receta de crafteo registrada: %s", idReceta), "info")

    return true
end

--- Verifica si un jugador puede craftear una receta
--- @param source number ID del jugador
--- @param idReceta string Identificador de la receta
--- @return boolean, string Puede craftear y mensaje
function Inventario.PuedeCraftear(source, idReceta)
    if not ValidarJugador(source) then
        return false, "Jugador invalido"
    end

    local receta = RecetasCrafteo[idReceta]
    if not receta then
        return false, "Receta no encontrada"
    end

    -- Verificar ingredientes
    for _, ingrediente in pairs(receta.ingredientes) do
        local cantidad = Inventario.ObtenerCantidadItem(source, ingrediente.nombre, ingrediente.metadatos)
        if cantidad < (ingrediente.cantidad or 1) then
            return false, string.format("Falta %s (tienes %d, necesitas %d)",
                ingrediente.nombre, cantidad, ingrediente.cantidad or 1)
        end
    end

    -- Verificar espacio en inventario
    local pesoActual, pesoMaximo = Inventario.ObtenerPeso(source)
    local itemResultado = Inventario.ObtenerInfoItem(receta.resultado)
    if itemResultado then
        local pesoNecesario = (itemResultado.peso or 0) * (receta.cantidadResultado or 1)
        if pesoActual + pesoNecesario > pesoMaximo then
            return false, "No tienes espacio suficiente en el inventario"
        end
    end

    return true, "Puedes craftear este item"
end

--- Ejecuta el crafteo de una receta
--- @param source number ID del jugador
--- @param idReceta string Identificador de la receta
--- @return boolean, string Exito del crafteo y mensaje
function Inventario.Craftear(source, idReceta)
    local puedeCraftear, mensaje = Inventario.PuedeCraftear(source, idReceta)
    if not puedeCraftear then
        return false, mensaje
    end

    local receta = RecetasCrafteo[idReceta]

    -- Remover ingredientes
    for _, ingrediente in pairs(receta.ingredientes) do
        local removido = Inventario.RemoverItem(source, ingrediente.nombre, ingrediente.cantidad or 1, ingrediente.metadatos)
        if not removido then
            -- Revertir cambios si algo falla (no implementado para simplicidad)
            return false, "Error al consumir ingredientes"
        end
    end

    -- Agregar resultado
    local agregado = Inventario.AgregarItem(
        source,
        receta.resultado,
        receta.cantidadResultado or 1,
        receta.metadatosResultado
    )

    if not agregado then
        return false, "Error al crear el item resultante"
    end

    RegistrarLog(string.format("Crafteo exitoso: %s por jugador %d", idReceta, source), "info")

    -- Disparar evento de crafteo completado
    TriggerEvent("ait:inventory:crafteoCompletado", source, idReceta, receta.resultado)
    TriggerClientEvent("ait:inventory:crafteoCompletado", source, idReceta, receta.resultado)

    return true, "Crafteo exitoso"
end

--- Obtiene todas las recetas de crafteo disponibles
--- @return table Lista de recetas
function Inventario.ObtenerRecetasCrafteo()
    local recetas = {}
    for id, receta in pairs(RecetasCrafteo) do
        table.insert(recetas, {
            id = receta.id,
            nombre = receta.nombre,
            ingredientes = receta.ingredientes,
            resultado = receta.resultado,
            cantidadResultado = receta.cantidadResultado,
            tiempo = receta.tiempo,
            nivel = receta.nivel,
            profesion = receta.profesion
        })
    end
    return recetas
end

--- Obtiene una receta especifica por ID
--- @param idReceta string Identificador de la receta
--- @return table Datos de la receta o nil
function Inventario.ObtenerRecetaCrafteo(idReceta)
    return RecetasCrafteo[idReceta]
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HOOKS Y CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════

--- Registra un hook para cuando se agrega un item
--- @param callback function Funcion a ejecutar
function Inventario.HookItemAgregado(callback)
    if type(callback) ~= "function" then
        RegistrarLog("Callback invalido para HookItemAgregado", "error")
        return
    end

    AddEventHandler("ait:inventory:itemAgregado", callback)
end

--- Registra un hook para cuando se remueve un item
--- @param callback function Funcion a ejecutar
function Inventario.HookItemRemovido(callback)
    if type(callback) ~= "function" then
        RegistrarLog("Callback invalido para HookItemRemovido", "error")
        return
    end

    AddEventHandler("ait:inventory:itemRemovido", callback)
end

--- Registra un hook para cuando se completa un crafteo
--- @param callback function Funcion a ejecutar
function Inventario.HookCrafteoCompletado(callback)
    if type(callback) ~= "function" then
        RegistrarLog("Callback invalido para HookCrafteoCompletado", "error")
        return
    end

    AddEventHandler("ait:inventory:crafteoCompletado", callback)
end

--- Hook nativo de ox_inventory para uso de items
--- @param nombreItem string Nombre del item
--- @param callback function Funcion a ejecutar al usar el item
function Inventario.RegistrarUsoItem(nombreItem, callback)
    if not nombreItem or nombreItem == "" then
        RegistrarLog("Nombre de item invalido para registrar uso", "error")
        return
    end

    if type(callback) ~= "function" then
        RegistrarLog("Callback invalido para RegistrarUsoItem", "error")
        return
    end

    exports.ox_inventory:useItem(nombreItem, function(source, item, inventory)
        -- Convertir al formato AIT
        local itemFormateado = {
            nombre = item.name,
            etiqueta = item.label,
            cantidad = item.count,
            slot = item.slot,
            metadatos = item.metadata
        }

        callback(source, itemFormateado)
    end)

    RegistrarLog(string.format("Uso de item registrado: %s", nombreItem), "info")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE TRANSFERENCIA
-- ═══════════════════════════════════════════════════════════════════════════

--- Transfiere un item entre jugadores
--- @param sourceOrigen number ID del jugador origen
--- @param sourceDestino number ID del jugador destino
--- @param nombreItem string Nombre del item
--- @param cantidad number Cantidad a transferir
--- @param metadatos table Metadatos del item (opcional)
--- @return boolean Verdadero si se transfirio correctamente
function Inventario.TransferirItem(sourceOrigen, sourceDestino, nombreItem, cantidad, metadatos)
    if not ValidarJugador(sourceOrigen) or not ValidarJugador(sourceDestino) then
        return false
    end

    cantidad = tonumber(cantidad) or 1

    -- Verificar que el origen tiene el item
    if not Inventario.TieneItem(sourceOrigen, nombreItem, cantidad, metadatos) then
        RegistrarLog("Jugador origen no tiene suficientes items para transferir", "warn")
        return false
    end

    -- Remover del origen
    local removido = Inventario.RemoverItem(sourceOrigen, nombreItem, cantidad, metadatos)
    if not removido then
        return false
    end

    -- Agregar al destino
    local agregado = Inventario.AgregarItem(sourceDestino, nombreItem, cantidad, metadatos)
    if not agregado then
        -- Revertir: devolver al origen
        Inventario.AgregarItem(sourceOrigen, nombreItem, cantidad, metadatos)
        return false
    end

    RegistrarLog(string.format("Item %s x%d transferido de %d a %d", nombreItem, cantidad, sourceOrigen, sourceDestino), "info")

    TriggerEvent("ait:inventory:itemTransferido", sourceOrigen, sourceDestino, nombreItem, cantidad)

    return true
end

--- Mueve un item a un slot especifico
--- @param source number ID del jugador
--- @param slotOrigen number Slot de origen
--- @param slotDestino number Slot de destino
--- @return boolean Verdadero si se movio correctamente
function Inventario.MoverItemSlot(source, slotOrigen, slotDestino)
    if not ValidarJugador(source) then
        return false
    end

    slotOrigen = tonumber(slotOrigen)
    slotDestino = tonumber(slotDestino)

    if not slotOrigen or not slotDestino then
        RegistrarLog("Slots invalidos para mover item", "error")
        return false
    end

    -- ox_inventory maneja el movimiento internamente a traves del UI
    -- Esta funcion sirve para movimientos programaticos
    local itemOrigen = Inventario.ObtenerItemPorSlot(source, slotOrigen)
    if not itemOrigen then
        RegistrarLog("No hay item en el slot de origen", "warn")
        return false
    end

    -- Usar SetSlot para mover
    ox_inventory:SetSlot(source, slotDestino, {
        name = itemOrigen.nombre,
        count = itemOrigen.cantidad,
        metadata = itemOrigen.metadatos
    })

    -- Limpiar slot origen
    ox_inventory:SetSlot(source, slotOrigen, nil)

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE ARMAS
-- ═══════════════════════════════════════════════════════════════════════════

--- Agrega un arma al inventario con municion
--- @param source number ID del jugador
--- @param nombreArma string Nombre del arma
--- @param municion number Cantidad de municion (opcional)
--- @param componentes table Lista de componentes (opcional)
--- @return boolean Verdadero si se agrego correctamente
function Inventario.AgregarArma(source, nombreArma, municion, componentes)
    if not ValidarJugador(source) then
        return false
    end

    local metadatos = {
        ammo = municion or 0,
        components = componentes or {},
        serial = Inventario.GenerarSerialArma()
    }

    return Inventario.AgregarItem(source, nombreArma, 1, metadatos)
end

--- Genera un numero de serie aleatorio para armas
--- @return string Numero de serie
function Inventario.GenerarSerialArma()
    local caracteres = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local serial = ""

    for i = 1, 10 do
        local indice = math.random(1, #caracteres)
        serial = serial .. string.sub(caracteres, indice, indice)
    end

    return serial
end

--- Obtiene las armas en el inventario del jugador
--- @param source number ID del jugador
--- @return table Lista de armas
function Inventario.ObtenerArmas(source)
    local inventario = Inventario.ObtenerInventario(source)
    local armas = {}

    for _, item in pairs(inventario) do
        if item.esArma then
            table.insert(armas, item)
        end
    end

    return armas
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTACIONES
-- ═══════════════════════════════════════════════════════════════════════════

-- Exportar todas las funciones para uso externo
exports("AgregarItem", Inventario.AgregarItem)
exports("RemoverItem", Inventario.RemoverItem)
exports("ObtenerCantidadItem", Inventario.ObtenerCantidadItem)
exports("TieneItem", Inventario.TieneItem)
exports("ObtenerInfoItem", Inventario.ObtenerInfoItem)
exports("ObtenerInventario", Inventario.ObtenerInventario)
exports("ObtenerItemPorSlot", Inventario.ObtenerItemPorSlot)
exports("LimpiarInventario", Inventario.LimpiarInventario)
exports("RegistrarStash", Inventario.RegistrarStash)
exports("AbrirStash", Inventario.AbrirStash)
exports("AgregarItemStash", Inventario.AgregarItemStash)
exports("RemoverItemStash", Inventario.RemoverItemStash)
exports("ObtenerContenidoStash", Inventario.ObtenerContenidoStash)
exports("LimpiarStash", Inventario.LimpiarStash)
exports("RegistrarTienda", Inventario.RegistrarTienda)
exports("AbrirTienda", Inventario.AbrirTienda)
exports("RegistrarRecetaCrafteo", Inventario.RegistrarRecetaCrafteo)
exports("PuedeCraftear", Inventario.PuedeCraftear)
exports("Craftear", Inventario.Craftear)
exports("TransferirItem", Inventario.TransferirItem)
exports("AgregarArma", Inventario.AgregarArma)

-- ═══════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    -- Esperar a que ox_inventory este listo
    while GetResourceState("ox_inventory") ~= "started" do
        Wait(100)
    end

    RegistrarLog("Bridge de ox_inventory inicializado correctamente", "info")

    -- Disparar evento de inicializacion
    TriggerEvent("ait:inventory:bridgeIniciado", "ox_inventory")
end)

-- Retornar el modulo para uso con require
return Inventario
