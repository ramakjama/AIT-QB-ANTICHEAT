--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                    AIT FRAMEWORK - BRIDGE QB-INVENTORY                    ║
    ║                                                                           ║
    ║  Bridge de compatibilidad para qb-inventory                               ║
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
local QBCore = exports["qb-core"]:GetCoreObject()

-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIGURACION DEL BRIDGE
-- ═══════════════════════════════════════════════════════════════════════════

Inventario.Config = {
    -- Tipo de inventario que maneja este bridge
    Tipo = "qb-inventory",

    -- Version minima requerida de qb-inventory
    VersionMinima = "1.0.0",

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
    },

    -- Configuracion de peso del jugador
    Jugador = {
        -- Peso maximo por defecto del inventario del jugador
        PesoMaximo = 120000,
        -- Numero de slots del jugador
        Slots = 41
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

    local prefijo = "[AIT-Inventory-QB]"
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

--- Obtiene el objeto Player de QBCore
--- @param source number ID del jugador
--- @return table Player object o nil
local function ObtenerPlayer(source)
    if not ValidarJugador(source) then
        return nil
    end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        RegistrarLog("No se pudo obtener Player de QBCore: " .. tostring(source), "error")
        return nil
    end

    return Player
end

--- Valida si un item existe en la configuracion de QBCore
--- @param nombreItem string Nombre del item
--- @return boolean Verdadero si el item existe
local function ValidarItem(nombreItem)
    if not nombreItem or nombreItem == "" then
        RegistrarLog("Nombre de item vacio o nulo", "error")
        return false
    end

    local itemData = QBCore.Shared.Items[nombreItem]
    if not itemData then
        RegistrarLog("Item no encontrado en QBCore.Shared.Items: " .. nombreItem, "warn")
        return false
    end

    return true
end

--- Convierte metadatos al formato esperado por qb-inventory
--- @param metadatos table Tabla de metadatos
--- @return table Metadatos formateados
local function FormatearMetadatos(metadatos)
    if not metadatos then return nil end
    if type(metadatos) ~= "table" then return nil end

    -- qb-inventory usa 'info' para metadatos adicionales
    local resultado = {}
    for clave, valor in pairs(metadatos) do
        resultado[clave] = valor
    end

    return resultado
end

--- Calcula el peso total de los items
--- @param items table Lista de items
--- @return number Peso total
local function CalcularPesoTotal(items)
    local pesoTotal = 0

    if not items then return 0 end

    for _, item in pairs(items) do
        if item then
            local itemData = QBCore.Shared.Items[item.name]
            if itemData then
                pesoTotal = pesoTotal + (itemData.weight or 0) * (item.amount or 1)
            end
        end
    end

    return pesoTotal
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
    local Player = ObtenerPlayer(source)
    if not Player then
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

    -- Intentar agregar el item usando qb-inventory
    local exito = Player.Functions.AddItem(nombreItem, cantidad, slot, metadatosFormateados)

    if exito then
        RegistrarLog(string.format("Item agregado: %s x%d a jugador %d", nombreItem, cantidad, source), "info")

        -- Notificar al cliente para actualizar UI
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[nombreItem], "add", cantidad)

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
    local Player = ObtenerPlayer(source)
    if not Player then
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

    -- Intentar remover el item
    local exito = Player.Functions.RemoveItem(nombreItem, cantidad, slot)

    if exito then
        RegistrarLog(string.format("Item removido: %s x%d de jugador %d", nombreItem, cantidad, source), "info")

        -- Notificar al cliente para actualizar UI
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[nombreItem], "remove", cantidad)

        -- Disparar evento para otros sistemas
        TriggerEvent("ait:inventory:itemRemovido", source, nombreItem, cantidad)
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
    local Player = ObtenerPlayer(source)
    if not Player then
        return 0
    end

    local items = Player.PlayerData.items
    local cantidad = 0

    if not items then return 0 end

    for _, item in pairs(items) do
        if item and item.name == nombreItem then
            -- Si hay metadatos, verificar que coincidan
            if metadatos then
                local coincide = true
                for clave, valor in pairs(metadatos) do
                    if item.info and item.info[clave] ~= valor then
                        coincide = false
                        break
                    end
                end
                if coincide then
                    cantidad = cantidad + (item.amount or 0)
                end
            else
                cantidad = cantidad + (item.amount or 0)
            end
        end
    end

    return cantidad
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

    local itemData = QBCore.Shared.Items[nombreItem]
    if not itemData then
        return nil
    end

    return {
        nombre = itemData.name,
        etiqueta = itemData.label,
        peso = itemData.weight,
        apilable = itemData.unique ~= true,
        descripcion = itemData.description,
        esArma = itemData.type == "weapon",
        tipo = itemData.type,
        imagen = itemData.image,
        usable = itemData.useable
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE INVENTARIO COMPLETO
-- ═══════════════════════════════════════════════════════════════════════════

--- Obtiene el inventario completo de un jugador
--- @param source number ID del jugador
--- @return table Lista de items en el inventario
function Inventario.ObtenerInventario(source)
    local Player = ObtenerPlayer(source)
    if not Player then
        return {}
    end

    local items = Player.PlayerData.items
    if not items then
        return {}
    end

    -- Formatear los items al formato estandar de AIT
    local inventarioFormateado = {}
    for slot, item in pairs(items) do
        if item then
            local itemData = QBCore.Shared.Items[item.name]
            table.insert(inventarioFormateado, {
                slot = slot,
                nombre = item.name,
                etiqueta = itemData and itemData.label or item.name,
                cantidad = item.amount or 1,
                peso = itemData and itemData.weight or 0,
                metadatos = item.info,
                esArma = itemData and itemData.type == "weapon" or false,
                tipo = itemData and itemData.type or "item"
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
    local Player = ObtenerPlayer(source)
    if not Player then
        return nil
    end

    slot = tonumber(slot)
    if not slot or slot <= 0 then
        return nil
    end

    local items = Player.PlayerData.items
    if not items or not items[slot] then
        return nil
    end

    local item = items[slot]
    local itemData = QBCore.Shared.Items[item.name]

    return {
        slot = slot,
        nombre = item.name,
        etiqueta = itemData and itemData.label or item.name,
        cantidad = item.amount or 1,
        peso = itemData and itemData.weight or 0,
        metadatos = item.info,
        esArma = itemData and itemData.type == "weapon" or false
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

    -- qb-inventory no permite cambiar slots dinamicamente de forma nativa
    -- Esto requeriria modificacion del recurso o uso de eventos custom
    RegistrarLog(string.format("Advertencia: qb-inventory no soporta cambio dinamico de slots"), "warn")

    return false
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

    -- Actualizar configuracion local
    Inventario.Config.Jugador.PesoMaximo = pesoMaximo

    -- Notificar al cliente
    TriggerClientEvent("ait:inventory:pesoMaximoActualizado", source, pesoMaximo)

    RegistrarLog(string.format("Peso maximo establecido a %d para jugador %d", pesoMaximo, source), "info")

    return true
end

--- Obtiene el peso actual y maximo del inventario
--- @param source number ID del jugador
--- @return number, number Peso actual y peso maximo
function Inventario.ObtenerPeso(source)
    local Player = ObtenerPlayer(source)
    if not Player then
        return 0, 0
    end

    local items = Player.PlayerData.items
    local pesoActual = CalcularPesoTotal(items)
    local pesoMaximo = Inventario.Config.Jugador.PesoMaximo

    return pesoActual, pesoMaximo
end

--- Limpia el inventario completo de un jugador
--- @param source number ID del jugador
--- @return boolean Verdadero si se limpio correctamente
function Inventario.LimpiarInventario(source)
    local Player = ObtenerPlayer(source)
    if not Player then
        return false
    end

    -- Obtener items actuales
    local items = Player.PlayerData.items
    if not items then
        return true -- Ya esta vacio
    end

    -- Remover cada item
    for slot, item in pairs(items) do
        if item then
            Player.Functions.RemoveItem(item.name, item.amount, slot)
        end
    end

    RegistrarLog(string.format("Inventario limpiado para jugador %d", source), "info")

    TriggerEvent("ait:inventory:inventarioLimpiado", source)
    TriggerClientEvent("inventory:client:UpdatePlayerInventory", source, {})

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SISTEMA DE STASHES (ALMACENES)
-- ═══════════════════════════════════════════════════════════════════════════

-- Almacen local de stashes registrados
local StashesRegistrados = {}

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

    StashesRegistrados[idStash] = {
        id = idStash,
        etiqueta = etiqueta,
        slots = slots,
        pesoMaximo = pesoMaximo,
        propietario = propietario,
        grupos = grupos,
        items = {}
    }

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

    local stash = StashesRegistrados[idStash]
    local slots = stash and stash.slots or Inventario.Config.Stashes.SlotsDefecto

    -- Usar evento de qb-inventory para abrir stash
    TriggerClientEvent("inventory:client:OpenStash", source, idStash, slots)

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

    -- Usar export de qb-inventory si esta disponible
    local exito = exports["qb-inventory"]:AddItem(idStash, nombreItem, cantidad, nil, metadatosFormateados, "stash")

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

    -- Usar export de qb-inventory si esta disponible
    local exito = exports["qb-inventory"]:RemoveItem(idStash, nombreItem, cantidad, nil, "stash")

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

    -- Obtener items del stash mediante export
    local items = exports["qb-inventory"]:GetStashItems(idStash)
    if not items then
        return {}
    end

    local contenido = {}
    for slot, item in pairs(items) do
        if item then
            local itemData = QBCore.Shared.Items[item.name]
            table.insert(contenido, {
                slot = slot,
                nombre = item.name,
                etiqueta = itemData and itemData.label or item.name,
                cantidad = item.amount or 1,
                peso = itemData and itemData.weight or 0,
                metadatos = item.info
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

    -- Obtener items actuales y remover cada uno
    local items = exports["qb-inventory"]:GetStashItems(idStash)
    if items then
        for slot, item in pairs(items) do
            if item then
                exports["qb-inventory"]:RemoveItem(idStash, item.name, item.amount, slot, "stash")
            end
        end
    end

    RegistrarLog(string.format("Stash %s limpiado", idStash), "info")

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SISTEMA DE TIENDAS (SHOPS)
-- ═══════════════════════════════════════════════════════════════════════════

-- Almacen local de tiendas registradas
local TiendasRegistradas = {}

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

    -- Formatear items de la tienda al formato de qb-inventory
    local itemsTienda = {}
    if datosInv.items then
        for _, item in pairs(datosInv.items) do
            table.insert(itemsTienda, {
                name = item.nombre or item.name,
                price = item.precio or item.price,
                amount = item.cantidad or item.count or 50,
                info = item.metadatos or item.info or {},
                type = item.tipo or "item",
                slot = #itemsTienda + 1
            })
        end
    end

    TiendasRegistradas[idTienda] = {
        id = idTienda,
        nombre = datosInv.etiqueta or datosInv.nombre or idTienda,
        items = itemsTienda,
        ubicaciones = ubicaciones,
        grupos = datosInv.grupos
    }

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

    local tienda = TiendasRegistradas[idTienda]
    if not tienda then
        RegistrarLog(string.format("Tienda no encontrada: %s", idTienda), "warn")
        return false
    end

    -- Usar evento de qb-inventory para abrir tienda
    TriggerClientEvent("inventory:client:OpenShop", source, tienda.items, tienda.nombre)

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

    local tienda = TiendasRegistradas[idTienda]
    if not tienda then
        return {}
    end

    local items = {}
    for _, item in pairs(tienda.items) do
        table.insert(items, {
            nombre = item.name,
            precio = item.price,
            cantidad = item.amount,
            metadatos = item.info
        })
    end

    return items
end

--- Procesa una compra en una tienda
--- @param source number ID del jugador
--- @param idTienda string Identificador de la tienda
--- @param nombreItem string Nombre del item a comprar
--- @param cantidad number Cantidad a comprar
--- @return boolean, string Exito de la compra y mensaje
function Inventario.ComprarItem(source, idTienda, nombreItem, cantidad)
    local Player = ObtenerPlayer(source)
    if not Player then
        return false, "Jugador invalido"
    end

    local tienda = TiendasRegistradas[idTienda]
    if not tienda then
        return false, "Tienda no encontrada"
    end

    cantidad = tonumber(cantidad) or 1

    -- Buscar item en la tienda
    local itemTienda = nil
    for _, item in pairs(tienda.items) do
        if item.name == nombreItem then
            itemTienda = item
            break
        end
    end

    if not itemTienda then
        return false, "Item no disponible en esta tienda"
    end

    local precioTotal = itemTienda.price * cantidad

    -- Verificar dinero del jugador
    local dineroActual = Player.PlayerData.money.cash
    if dineroActual < precioTotal then
        return false, "No tienes suficiente dinero"
    end

    -- Realizar la compra
    Player.Functions.RemoveMoney("cash", precioTotal, "compra-tienda")
    local agregado = Inventario.AgregarItem(source, nombreItem, cantidad, itemTienda.info)

    if agregado then
        RegistrarLog(string.format("Compra realizada: %s x%d por $%d (jugador %d)", nombreItem, cantidad, precioTotal, source), "info")
        return true, "Compra realizada exitosamente"
    else
        -- Devolver dinero si falla la entrega del item
        Player.Functions.AddMoney("cash", precioTotal, "devolucion-compra")
        return false, "Error al agregar item al inventario"
    end
end

--- Procesa una venta de item
--- @param source number ID del jugador
--- @param nombreItem string Nombre del item a vender
--- @param cantidad number Cantidad a vender
--- @param precioUnitario number Precio por unidad
--- @return boolean, string Exito de la venta y mensaje
function Inventario.VenderItem(source, nombreItem, cantidad, precioUnitario)
    local Player = ObtenerPlayer(source)
    if not Player then
        return false, "Jugador invalido"
    end

    cantidad = tonumber(cantidad) or 1
    precioUnitario = tonumber(precioUnitario) or 0

    -- Verificar que tiene el item
    if not Inventario.TieneItem(source, nombreItem, cantidad) then
        return false, "No tienes suficientes items para vender"
    end

    local precioTotal = precioUnitario * cantidad

    -- Realizar la venta
    local removido = Inventario.RemoverItem(source, nombreItem, cantidad)
    if removido then
        Player.Functions.AddMoney("cash", precioTotal, "venta-item")
        RegistrarLog(string.format("Venta realizada: %s x%d por $%d (jugador %d)", nombreItem, cantidad, precioTotal, source), "info")
        return true, "Venta realizada exitosamente"
    else
        return false, "Error al remover item del inventario"
    end
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

--- Registra un callback para uso de items con QBCore
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

    -- Usar sistema de QBCore para items usables
    QBCore.Functions.CreateUseableItem(nombreItem, function(source, item)
        -- Convertir al formato AIT
        local itemFormateado = {
            nombre = item.name,
            etiqueta = item.label,
            cantidad = item.amount,
            slot = item.slot,
            metadatos = item.info
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
    local Player = ObtenerPlayer(source)
    if not Player then
        return false
    end

    slotOrigen = tonumber(slotOrigen)
    slotDestino = tonumber(slotDestino)

    if not slotOrigen or not slotDestino then
        RegistrarLog("Slots invalidos para mover item", "error")
        return false
    end

    local items = Player.PlayerData.items
    local itemOrigen = items[slotOrigen]

    if not itemOrigen then
        RegistrarLog("No hay item en el slot de origen", "warn")
        return false
    end

    -- Verificar si slot destino esta vacio
    local itemDestino = items[slotDestino]

    if itemDestino then
        -- Intercambiar items
        Player.PlayerData.items[slotDestino] = itemOrigen
        Player.PlayerData.items[slotOrigen] = itemDestino
    else
        -- Mover a slot vacio
        Player.PlayerData.items[slotDestino] = itemOrigen
        Player.PlayerData.items[slotOrigen] = nil
    end

    -- Actualizar cliente
    TriggerClientEvent("inventory:client:UpdatePlayerInventory", source, Player.PlayerData.items)

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
        attachments = componentes or {},
        serie = Inventario.GenerarSerialArma(),
        quality = 100
    }

    return Inventario.AgregarItem(source, nombreArma, 1, metadatos)
end

--- Genera un numero de serie aleatorio para armas
--- @return string Numero de serie
function Inventario.GenerarSerialArma()
    local caracteres = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local serial = ""

    math.randomseed(GetGameTimer())

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
        if item.esArma or item.tipo == "weapon" then
            table.insert(armas, item)
        end
    end

    return armas
end

--- Actualiza la municion de un arma especifica
--- @param source number ID del jugador
--- @param slot number Slot del arma
--- @param nuevaMunicion number Nueva cantidad de municion
--- @return boolean Verdadero si se actualizo correctamente
function Inventario.ActualizarMunicionArma(source, slot, nuevaMunicion)
    local Player = ObtenerPlayer(source)
    if not Player then
        return false
    end

    slot = tonumber(slot)
    nuevaMunicion = tonumber(nuevaMunicion) or 0

    local items = Player.PlayerData.items
    local arma = items[slot]

    if not arma then
        RegistrarLog("No hay arma en el slot especificado", "warn")
        return false
    end

    -- Actualizar municion en metadatos
    if not arma.info then
        arma.info = {}
    end
    arma.info.ammo = nuevaMunicion

    Player.PlayerData.items[slot] = arma

    -- Actualizar cliente
    TriggerClientEvent("inventory:client:UpdatePlayerInventory", source, Player.PlayerData.items)

    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCIONES DE DROP (ITEMS EN EL SUELO)
-- ═══════════════════════════════════════════════════════════════════════════

-- Contador para IDs de drops
local DropIDCounter = 0

--- Crea un drop de item en el suelo
--- @param coordenadas vector3 Coordenadas donde crear el drop
--- @param nombreItem string Nombre del item
--- @param cantidad number Cantidad del item
--- @param metadatos table Metadatos del item (opcional)
--- @return string ID del drop creado
function Inventario.CrearDrop(coordenadas, nombreItem, cantidad, metadatos)
    if not coordenadas then
        RegistrarLog("Coordenadas invalidas para crear drop", "error")
        return nil
    end

    if not ValidarItem(nombreItem) then
        return nil
    end

    cantidad = tonumber(cantidad) or 1
    DropIDCounter = DropIDCounter + 1
    local dropId = "drop_" .. DropIDCounter .. "_" .. os.time()

    -- Usar sistema de qb-inventory para drops
    TriggerEvent("qb-inventory:server:CreateDropId", dropId, coordenadas)
    exports["qb-inventory"]:AddItem(dropId, nombreItem, cantidad, nil, metadatos, "drop")

    RegistrarLog(string.format("Drop creado: %s con %s x%d", dropId, nombreItem, cantidad), "info")

    return dropId
end

--- Recoge un drop del suelo
--- @param source number ID del jugador
--- @param dropId string ID del drop
--- @return boolean Verdadero si se recogio correctamente
function Inventario.RecogerDrop(source, dropId)
    if not ValidarJugador(source) then
        return false
    end

    if not dropId or dropId == "" then
        RegistrarLog("ID de drop invalido", "error")
        return false
    end

    -- Obtener items del drop
    local items = exports["qb-inventory"]:GetDropItems(dropId)
    if not items or next(items) == nil then
        RegistrarLog("Drop vacio o no encontrado: " .. dropId, "warn")
        return false
    end

    -- Transferir items al jugador
    for slot, item in pairs(items) do
        if item then
            local agregado = Inventario.AgregarItem(source, item.name, item.amount, item.info)
            if agregado then
                exports["qb-inventory"]:RemoveItem(dropId, item.name, item.amount, slot, "drop")
            end
        end
    end

    -- Eliminar drop si esta vacio
    TriggerEvent("qb-inventory:server:RemoveDropId", dropId)

    RegistrarLog(string.format("Drop %s recogido por jugador %d", dropId, source), "info")

    return true
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
exports("ObtenerPeso", Inventario.ObtenerPeso)
exports("RegistrarStash", Inventario.RegistrarStash)
exports("AbrirStash", Inventario.AbrirStash)
exports("AgregarItemStash", Inventario.AgregarItemStash)
exports("RemoverItemStash", Inventario.RemoverItemStash)
exports("ObtenerContenidoStash", Inventario.ObtenerContenidoStash)
exports("LimpiarStash", Inventario.LimpiarStash)
exports("RegistrarTienda", Inventario.RegistrarTienda)
exports("AbrirTienda", Inventario.AbrirTienda)
exports("ObtenerItemsTienda", Inventario.ObtenerItemsTienda)
exports("ComprarItem", Inventario.ComprarItem)
exports("VenderItem", Inventario.VenderItem)
exports("RegistrarRecetaCrafteo", Inventario.RegistrarRecetaCrafteo)
exports("PuedeCraftear", Inventario.PuedeCraftear)
exports("Craftear", Inventario.Craftear)
exports("ObtenerRecetasCrafteo", Inventario.ObtenerRecetasCrafteo)
exports("TransferirItem", Inventario.TransferirItem)
exports("MoverItemSlot", Inventario.MoverItemSlot)
exports("AgregarArma", Inventario.AgregarArma)
exports("ObtenerArmas", Inventario.ObtenerArmas)
exports("ActualizarMunicionArma", Inventario.ActualizarMunicionArma)
exports("CrearDrop", Inventario.CrearDrop)
exports("RecogerDrop", Inventario.RecogerDrop)

-- ═══════════════════════════════════════════════════════════════════════════
-- INICIALIZACION
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    -- Esperar a que qb-core y qb-inventory esten listos
    while GetResourceState("qb-core") ~= "started" do
        Wait(100)
    end

    while GetResourceState("qb-inventory") ~= "started" do
        Wait(100)
    end

    -- Recargar QBCore por si no estaba listo
    QBCore = exports["qb-core"]:GetCoreObject()

    RegistrarLog("Bridge de qb-inventory inicializado correctamente", "info")

    -- Disparar evento de inicializacion
    TriggerEvent("ait:inventory:bridgeIniciado", "qb-inventory")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENTOS DE SINCRONIZACION
-- ═══════════════════════════════════════════════════════════════════════════

-- Evento para sincronizar inventario cuando el jugador carga
RegisterNetEvent("QBCore:Server:PlayerLoaded", function()
    local source = source
    Wait(1000) -- Esperar a que el inventario cargue completamente

    TriggerClientEvent("ait:inventory:inventarioCargado", source)
    RegistrarLog(string.format("Inventario cargado para jugador %d", source), "info")
end)

-- Evento para limpiar cache cuando el jugador se desconecta
AddEventHandler("playerDropped", function(reason)
    local source = source
    RegistrarLog(string.format("Jugador %d desconectado: %s", source, reason), "info")
end)

-- Retornar el modulo para uso con require
return Inventario
