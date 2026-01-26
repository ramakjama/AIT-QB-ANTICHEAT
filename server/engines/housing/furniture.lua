-- =====================================================================================
-- ait-qb ENGINE DE VIVIENDAS - SISTEMA DE MUEBLES
-- Colocacion, movimiento, rotacion y gestion de muebles en propiedades
-- Namespace: AIT.Engines.Housing.Furniture
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Housing = AIT.Engines.Housing or {}

local Muebles = {
    -- Catalogo de muebles disponibles
    catalogo = {},
    -- Cache de muebles por propiedad
    mueblesPorPropiedad = {},
    -- Muebles en proceso de colocacion
    colocando = {},
}

-- =====================================================================================
-- CATALOGO DE MUEBLES
-- =====================================================================================

Muebles.CatalogoDefault = {
    -- SALA DE ESTAR
    sofa_pequeno = {
        nombre = 'Sofa Pequeno',
        descripcion = 'Sofa de dos plazas',
        categoria = 'sala',
        modelo = 'prop_couch_sm_06',
        precio = 500,
        peso = 50,
        dimensiones = { x = 1.5, y = 0.8, z = 0.8 },
        rotable = true,
        apilable = false,
    },
    sofa_grande = {
        nombre = 'Sofa Grande',
        descripcion = 'Sofa de tres plazas',
        categoria = 'sala',
        modelo = 'prop_couch_lg_05',
        precio = 1200,
        peso = 80,
        dimensiones = { x = 2.5, y = 1.0, z = 0.9 },
        rotable = true,
        apilable = false,
    },
    sillon = {
        nombre = 'Sillon Individual',
        descripcion = 'Sillon comodo individual',
        categoria = 'sala',
        modelo = 'prop_armchair_01',
        precio = 350,
        peso = 30,
        dimensiones = { x = 0.9, y = 0.9, z = 1.0 },
        rotable = true,
        apilable = false,
    },
    mesa_cafe = {
        nombre = 'Mesa de Cafe',
        descripcion = 'Mesa baja para sala',
        categoria = 'sala',
        modelo = 'prop_table_04',
        precio = 200,
        peso = 20,
        dimensiones = { x = 1.0, y = 0.6, z = 0.4 },
        rotable = true,
        apilable = false,
    },
    tv_pantalla = {
        nombre = 'Television',
        descripcion = 'TV de pantalla plana',
        categoria = 'sala',
        modelo = 'prop_tv_flat_01',
        precio = 800,
        peso = 15,
        dimensiones = { x = 1.2, y = 0.1, z = 0.7 },
        rotable = true,
        apilable = false,
        interactivo = true,
    },
    estanteria = {
        nombre = 'Estanteria',
        descripcion = 'Estanteria de madera',
        categoria = 'sala',
        modelo = 'prop_shelf_01',
        precio = 300,
        peso = 40,
        dimensiones = { x = 1.0, y = 0.4, z = 2.0 },
        rotable = true,
        apilable = false,
    },
    alfombra_pequena = {
        nombre = 'Alfombra Pequena',
        descripcion = 'Alfombra decorativa',
        categoria = 'sala',
        modelo = 'prop_rug_01',
        precio = 150,
        peso = 5,
        dimensiones = { x = 2.0, y = 1.5, z = 0.01 },
        rotable = true,
        apilable = true,
    },

    -- DORMITORIO
    cama_individual = {
        nombre = 'Cama Individual',
        descripcion = 'Cama de una plaza',
        categoria = 'dormitorio',
        modelo = 'v_res_msonbed',
        precio = 400,
        peso = 60,
        dimensiones = { x = 2.0, y = 1.0, z = 0.6 },
        rotable = true,
        apilable = false,
        interactivo = true,
        accion = 'dormir',
    },
    cama_doble = {
        nombre = 'Cama Doble',
        descripcion = 'Cama de dos plazas',
        categoria = 'dormitorio',
        modelo = 'v_res_d_bed',
        precio = 800,
        peso = 100,
        dimensiones = { x = 2.2, y = 1.6, z = 0.7 },
        rotable = true,
        apilable = false,
        interactivo = true,
        accion = 'dormir',
    },
    mesita_noche = {
        nombre = 'Mesita de Noche',
        descripcion = 'Mesa auxiliar para dormitorio',
        categoria = 'dormitorio',
        modelo = 'prop_bedside_01',
        precio = 100,
        peso = 15,
        dimensiones = { x = 0.5, y = 0.4, z = 0.5 },
        rotable = true,
        apilable = false,
    },
    armario_ropa = {
        nombre = 'Armario',
        descripcion = 'Armario para ropa',
        categoria = 'dormitorio',
        modelo = 'prop_wardrobe_01',
        precio = 600,
        peso = 80,
        dimensiones = { x = 1.2, y = 0.6, z = 2.0 },
        rotable = true,
        apilable = false,
        interactivo = true,
        accion = 'almacenar',
        tipoAlmacen = 'armario',
    },
    espejo_pie = {
        nombre = 'Espejo de Pie',
        descripcion = 'Espejo de cuerpo completo',
        categoria = 'dormitorio',
        modelo = 'prop_mirror_01',
        precio = 200,
        peso = 20,
        dimensiones = { x = 0.5, y = 0.1, z = 1.8 },
        rotable = true,
        apilable = false,
    },

    -- COCINA
    nevera = {
        nombre = 'Nevera',
        descripcion = 'Refrigerador grande',
        categoria = 'cocina',
        modelo = 'prop_fridge_01',
        precio = 1000,
        peso = 100,
        dimensiones = { x = 0.7, y = 0.7, z = 1.8 },
        rotable = true,
        apilable = false,
        interactivo = true,
        accion = 'almacenar',
        tipoAlmacen = 'nevera',
    },
    microondas = {
        nombre = 'Microondas',
        descripcion = 'Horno microondas',
        categoria = 'cocina',
        modelo = 'prop_micro_02',
        precio = 150,
        peso = 15,
        dimensiones = { x = 0.5, y = 0.4, z = 0.3 },
        rotable = true,
        apilable = false,
        interactivo = true,
    },
    mesa_comedor = {
        nombre = 'Mesa de Comedor',
        descripcion = 'Mesa para comedor',
        categoria = 'cocina',
        modelo = 'prop_table_03',
        precio = 400,
        peso = 50,
        dimensiones = { x = 1.5, y = 0.9, z = 0.8 },
        rotable = true,
        apilable = false,
    },
    silla_comedor = {
        nombre = 'Silla de Comedor',
        descripcion = 'Silla para mesa',
        categoria = 'cocina',
        modelo = 'prop_chair_01a',
        precio = 75,
        peso = 8,
        dimensiones = { x = 0.5, y = 0.5, z = 1.0 },
        rotable = true,
        apilable = true,
    },

    -- BANO
    inodoro = {
        nombre = 'Inodoro',
        descripcion = 'WC estandar',
        categoria = 'bano',
        modelo = 'prop_toilet_01',
        precio = 200,
        peso = 40,
        dimensiones = { x = 0.5, y = 0.7, z = 0.8 },
        rotable = true,
        apilable = false,
    },
    lavabo = {
        nombre = 'Lavabo',
        descripcion = 'Lavabo de bano',
        categoria = 'bano',
        modelo = 'prop_sink_01',
        precio = 150,
        peso = 25,
        dimensiones = { x = 0.6, y = 0.5, z = 0.9 },
        rotable = true,
        apilable = false,
    },

    -- OFICINA
    escritorio = {
        nombre = 'Escritorio',
        descripcion = 'Mesa de trabajo',
        categoria = 'oficina',
        modelo = 'prop_desk_01a',
        precio = 350,
        peso = 45,
        dimensiones = { x = 1.5, y = 0.8, z = 0.8 },
        rotable = true,
        apilable = false,
    },
    silla_oficina = {
        nombre = 'Silla de Oficina',
        descripcion = 'Silla ergonomica',
        categoria = 'oficina',
        modelo = 'prop_off_chair_01',
        precio = 250,
        peso = 15,
        dimensiones = { x = 0.6, y = 0.6, z = 1.1 },
        rotable = true,
        apilable = false,
    },
    ordenador = {
        nombre = 'Ordenador',
        descripcion = 'PC de escritorio',
        categoria = 'oficina',
        modelo = 'prop_laptop_01a',
        precio = 600,
        peso = 10,
        dimensiones = { x = 0.4, y = 0.3, z = 0.3 },
        rotable = true,
        apilable = false,
        interactivo = true,
    },
    archivador = {
        nombre = 'Archivador',
        descripcion = 'Archivador metalico',
        categoria = 'oficina',
        modelo = 'prop_filing_cab_01',
        precio = 200,
        peso = 35,
        dimensiones = { x = 0.5, y = 0.6, z = 1.3 },
        rotable = true,
        apilable = false,
        interactivo = true,
        accion = 'almacenar',
        tipoAlmacen = 'armario',
    },

    -- DECORACION
    planta_interior = {
        nombre = 'Planta Interior',
        descripcion = 'Planta decorativa',
        categoria = 'decoracion',
        modelo = 'prop_plant_int_01a',
        precio = 50,
        peso = 10,
        dimensiones = { x = 0.4, y = 0.4, z = 0.8 },
        rotable = true,
        apilable = false,
    },
    lampara_pie = {
        nombre = 'Lampara de Pie',
        descripcion = 'Lampara de suelo',
        categoria = 'decoracion',
        modelo = 'prop_floor_lamp_01',
        precio = 100,
        peso = 8,
        dimensiones = { x = 0.3, y = 0.3, z = 1.5 },
        rotable = true,
        apilable = false,
    },
    cuadro_pequeno = {
        nombre = 'Cuadro Pequeno',
        descripcion = 'Cuadro decorativo',
        categoria = 'decoracion',
        modelo = 'prop_painting_01',
        precio = 75,
        peso = 3,
        dimensiones = { x = 0.6, y = 0.05, z = 0.5 },
        rotable = true,
        apilable = false,
        pared = true,
    },
    cuadro_grande = {
        nombre = 'Cuadro Grande',
        descripcion = 'Cuadro grande de pared',
        categoria = 'decoracion',
        modelo = 'prop_painting_03',
        precio = 200,
        peso = 8,
        dimensiones = { x = 1.2, y = 0.05, z = 0.9 },
        rotable = true,
        apilable = false,
        pared = true,
    },
    reloj_pared = {
        nombre = 'Reloj de Pared',
        descripcion = 'Reloj analogico',
        categoria = 'decoracion',
        modelo = 'prop_cs_clock',
        precio = 50,
        peso = 2,
        dimensiones = { x = 0.3, y = 0.05, z = 0.3 },
        rotable = true,
        apilable = false,
        pared = true,
    },

    -- SEGURIDAD
    caja_fuerte = {
        nombre = 'Caja Fuerte',
        descripcion = 'Caja fuerte de seguridad',
        categoria = 'seguridad',
        modelo = 'prop_ld_int_safe_01',
        precio = 5000,
        peso = 200,
        dimensiones = { x = 0.6, y = 0.6, z = 0.8 },
        rotable = true,
        apilable = false,
        interactivo = true,
        accion = 'almacenar',
        tipoAlmacen = 'caja_fuerte',
        requiereCodigo = true,
    },
}

-- =====================================================================================
-- CATEGORIAS
-- =====================================================================================

Muebles.Categorias = {
    sala = { nombre = 'Sala de Estar', icono = 'couch', orden = 1 },
    dormitorio = { nombre = 'Dormitorio', icono = 'bed', orden = 2 },
    cocina = { nombre = 'Cocina', icono = 'utensils', orden = 3 },
    bano = { nombre = 'Bano', icono = 'bath', orden = 4 },
    oficina = { nombre = 'Oficina', icono = 'briefcase', orden = 5 },
    decoracion = { nombre = 'Decoracion', icono = 'paint-brush', orden = 6 },
    seguridad = { nombre = 'Seguridad', icono = 'shield', orden = 7 },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Muebles.Initialize()
    -- Cargar catalogo
    Muebles.CargarCatalogo()

    -- Cargar muebles existentes en cache
    Muebles.CargarMueblesEnCache()

    -- Registrar callbacks
    Muebles.RegistrarCallbacks()

    if AIT.Log then
        AIT.Log.info('HOUSING:FURNITURE', 'Sistema de muebles inicializado')
    end

    return true
end

function Muebles.CargarCatalogo()
    -- Copiar catalogo por defecto
    Muebles.catalogo = {}
    for id, config in pairs(Muebles.CatalogoDefault) do
        Muebles.catalogo[id] = {}
        for k, v in pairs(config) do
            Muebles.catalogo[id][k] = v
        end
        Muebles.catalogo[id].id = id
    end

    -- Cargar desde BD si hay personalizaciones
    local customMuebles = MySQL.query.await([[
        SELECT * FROM ait_muebles_catalogo WHERE activo = 1
    ]])

    if customMuebles then
        for _, mueble in ipairs(customMuebles) do
            Muebles.catalogo[mueble.catalogo_id] = {
                id = mueble.catalogo_id,
                nombre = mueble.nombre,
                descripcion = mueble.descripcion,
                categoria = mueble.categoria,
                modelo = mueble.modelo,
                precio = mueble.precio,
                peso = mueble.peso,
                dimensiones = mueble.dimensiones and json.decode(mueble.dimensiones) or { x = 1, y = 1, z = 1 },
                rotable = mueble.rotable == 1,
                apilable = mueble.apilable == 1,
                interactivo = mueble.interactivo == 1,
                pared = mueble.pared == 1,
            }
        end
    end
end

function Muebles.CargarMueblesEnCache()
    local muebles = MySQL.query.await([[
        SELECT m.*, p.propiedad_id
        FROM ait_propiedad_muebles m
        JOIN ait_propiedades p ON m.propiedad_id = p.propiedad_id
        WHERE p.estado != 'embargada'
    ]])

    Muebles.mueblesPorPropiedad = {}

    for _, mueble in ipairs(muebles or {}) do
        local propId = mueble.propiedad_id

        if not Muebles.mueblesPorPropiedad[propId] then
            Muebles.mueblesPorPropiedad[propId] = {}
        end

        mueble.posicion = mueble.posicion and json.decode(mueble.posicion) or nil
        mueble.rotacion = mueble.rotacion and json.decode(mueble.rotacion) or nil
        mueble.escala = mueble.escala and json.decode(mueble.escala) or nil
        mueble.metadata = mueble.metadata and json.decode(mueble.metadata) or {}

        table.insert(Muebles.mueblesPorPropiedad[propId], mueble)
    end
end

-- =====================================================================================
-- GESTION DE MUEBLES
-- =====================================================================================

--- Obtener catalogo de muebles
---@param categoria string|nil
---@return table
function Muebles.ObtenerCatalogo(categoria)
    if not categoria then
        return Muebles.catalogo
    end

    local resultado = {}
    for id, mueble in pairs(Muebles.catalogo) do
        if mueble.categoria == categoria then
            resultado[id] = mueble
        end
    end

    return resultado
end

--- Obtener mueble del catalogo
---@param catalogoId string
---@return table|nil
function Muebles.ObtenerDelCatalogo(catalogoId)
    return Muebles.catalogo[catalogoId]
end

--- Obtener muebles de una propiedad
---@param propiedadId number
---@return table
function Muebles.ObtenerMueblesPropiedad(propiedadId)
    if Muebles.mueblesPorPropiedad[propiedadId] then
        return Muebles.mueblesPorPropiedad[propiedadId]
    end

    -- Cargar de BD si no esta en cache
    local muebles = MySQL.query.await([[
        SELECT * FROM ait_propiedad_muebles WHERE propiedad_id = ?
    ]], { propiedadId })

    local resultado = {}
    for _, mueble in ipairs(muebles or {}) do
        mueble.posicion = mueble.posicion and json.decode(mueble.posicion) or nil
        mueble.rotacion = mueble.rotacion and json.decode(mueble.rotacion) or nil
        mueble.escala = mueble.escala and json.decode(mueble.escala) or nil
        mueble.metadata = mueble.metadata and json.decode(mueble.metadata) or {}
        table.insert(resultado, mueble)
    end

    Muebles.mueblesPorPropiedad[propiedadId] = resultado
    return resultado
end

--- Contar muebles en una propiedad
---@param propiedadId number
---@return number
function Muebles.ContarMuebles(propiedadId)
    local muebles = Muebles.ObtenerMueblesPropiedad(propiedadId)
    return #muebles
end

-- =====================================================================================
-- COLOCAR MUEBLES
-- =====================================================================================

--- Iniciar colocacion de mueble
---@param source number
---@param charId number
---@param propiedadId number
---@param catalogoId string
---@return boolean, string
function Muebles.IniciarColocacion(source, charId, propiedadId, catalogoId)
    -- Verificar que el mueble existe en el catalogo
    local catalogoMueble = Muebles.ObtenerDelCatalogo(catalogoId)
    if not catalogoMueble then
        return false, 'Mueble no encontrado en el catalogo'
    end

    -- Verificar propiedad
    local propiedad = AIT.Engines.Housing and AIT.Engines.Housing.Obtener(propiedadId)
    if not propiedad then
        return false, 'Propiedad no encontrada'
    end

    -- Verificar acceso (solo propietario puede colocar muebles)
    if propiedad.propietario_char_id ~= charId then
        return false, 'Solo el propietario puede colocar muebles'
    end

    -- Verificar limite de muebles
    local mueblesActuales = Muebles.ContarMuebles(propiedadId)
    local maxMuebles = propiedad.max_muebles or 30

    if mueblesActuales >= maxMuebles then
        return false, ('Limite de muebles alcanzado (%d/%d)'):format(mueblesActuales, maxMuebles)
    end

    -- Verificar fondos
    if AIT.Engines and AIT.Engines.economy then
        local balance = AIT.Engines.economy.GetBalance('char', charId, 'bank')
        if balance < catalogoMueble.precio then
            return false, ('Fondos insuficientes. El mueble cuesta $%d'):format(catalogoMueble.precio)
        end
    end

    -- Marcar como colocando
    Muebles.colocando[source] = {
        propiedadId = propiedadId,
        catalogoId = catalogoId,
        charId = charId,
        iniciado = os.time()
    }

    -- Enviar al cliente para iniciar modo colocacion
    TriggerClientEvent('ait:housing:furniture:startPlacement', source, {
        catalogo_id = catalogoId,
        modelo = catalogoMueble.modelo,
        dimensiones = catalogoMueble.dimensiones,
        rotable = catalogoMueble.rotable,
        pared = catalogoMueble.pared,
    })

    return true, 'Modo de colocacion iniciado. Usa el mouse para posicionar el mueble.'
end

--- Confirmar colocacion de mueble
---@param source number
---@param posicion table
---@param rotacion table
---@return boolean, string
function Muebles.ConfirmarColocacion(source, posicion, rotacion)
    local datos = Muebles.colocando[source]
    if not datos then
        return false, 'No hay colocacion en progreso'
    end

    local catalogoMueble = Muebles.ObtenerDelCatalogo(datos.catalogoId)
    if not catalogoMueble then
        Muebles.colocando[source] = nil
        return false, 'Mueble no encontrado'
    end

    -- Cobrar el mueble
    if AIT.Engines and AIT.Engines.economy then
        local success, err = AIT.Engines.economy.RemoveMoney(source, datos.charId, catalogoMueble.precio, 'bank',
            'purchase', 'Mueble: ' .. catalogoMueble.nombre)

        if not success then
            Muebles.colocando[source] = nil
            return false, 'Error al procesar el pago'
        end
    end

    -- Insertar mueble en BD
    local muebleId = MySQL.insert.await([[
        INSERT INTO ait_propiedad_muebles
        (propiedad_id, catalogo_id, posicion, rotacion, colocado_por)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        datos.propiedadId,
        datos.catalogoId,
        json.encode(posicion),
        json.encode(rotacion),
        datos.charId
    })

    -- Actualizar cache
    if not Muebles.mueblesPorPropiedad[datos.propiedadId] then
        Muebles.mueblesPorPropiedad[datos.propiedadId] = {}
    end

    local nuevoMueble = {
        mueble_id = muebleId,
        propiedad_id = datos.propiedadId,
        catalogo_id = datos.catalogoId,
        posicion = posicion,
        rotacion = rotacion,
        colocado_por = datos.charId,
        metadata = {}
    }
    table.insert(Muebles.mueblesPorPropiedad[datos.propiedadId], nuevoMueble)

    -- Limpiar estado de colocacion
    Muebles.colocando[source] = nil

    -- Notificar a todos en la propiedad
    Muebles.NotificarCambioMueble(datos.propiedadId, 'colocado', nuevoMueble)

    -- Log
    if AIT.Engines.Housing then
        AIT.Engines.Housing.RegistrarLog(datos.propiedadId, 'MUEBLE_COLOCADO', datos.charId, {
            mueble_id = muebleId,
            catalogo_id = datos.catalogoId,
            precio = catalogoMueble.precio
        })
    end

    return true, 'Mueble colocado correctamente'
end

--- Cancelar colocacion de mueble
---@param source number
---@return boolean
function Muebles.CancelarColocacion(source)
    if Muebles.colocando[source] then
        Muebles.colocando[source] = nil
        TriggerClientEvent('ait:housing:furniture:cancelPlacement', source)
        return true
    end
    return false
end

-- =====================================================================================
-- MOVER Y ROTAR MUEBLES
-- =====================================================================================

--- Iniciar movimiento de mueble
---@param source number
---@param charId number
---@param muebleId number
---@return boolean, string
function Muebles.IniciarMovimiento(source, charId, muebleId)
    -- Obtener mueble
    local mueble = MySQL.query.await([[
        SELECT m.*, p.propietario_char_id
        FROM ait_propiedad_muebles m
        JOIN ait_propiedades p ON m.propiedad_id = p.propiedad_id
        WHERE m.mueble_id = ?
    ]], { muebleId })

    if not mueble or #mueble == 0 then
        return false, 'Mueble no encontrado'
    end

    mueble = mueble[1]

    -- Verificar permisos
    if mueble.propietario_char_id ~= charId then
        return false, 'Solo el propietario puede mover muebles'
    end

    local catalogoMueble = Muebles.ObtenerDelCatalogo(mueble.catalogo_id)
    if not catalogoMueble then
        return false, 'Mueble no encontrado en catalogo'
    end

    -- Marcar como moviendo
    Muebles.colocando[source] = {
        tipo = 'mover',
        muebleId = muebleId,
        propiedadId = mueble.propiedad_id,
        catalogoId = mueble.catalogo_id,
        charId = charId,
        iniciado = os.time()
    }

    -- Enviar al cliente
    TriggerClientEvent('ait:housing:furniture:startMove', source, {
        mueble_id = muebleId,
        catalogo_id = mueble.catalogo_id,
        modelo = catalogoMueble.modelo,
        posicion = mueble.posicion and json.decode(mueble.posicion) or nil,
        rotacion = mueble.rotacion and json.decode(mueble.rotacion) or nil,
        dimensiones = catalogoMueble.dimensiones,
        rotable = catalogoMueble.rotable,
    })

    return true, 'Modo de movimiento iniciado'
end

--- Confirmar movimiento de mueble
---@param source number
---@param posicion table
---@param rotacion table
---@return boolean, string
function Muebles.ConfirmarMovimiento(source, posicion, rotacion)
    local datos = Muebles.colocando[source]
    if not datos or datos.tipo ~= 'mover' then
        return false, 'No hay movimiento en progreso'
    end

    -- Actualizar en BD
    MySQL.query.await([[
        UPDATE ait_propiedad_muebles
        SET posicion = ?, rotacion = ?
        WHERE mueble_id = ?
    ]], {
        json.encode(posicion),
        json.encode(rotacion),
        datos.muebleId
    })

    -- Actualizar cache
    if Muebles.mueblesPorPropiedad[datos.propiedadId] then
        for i, m in ipairs(Muebles.mueblesPorPropiedad[datos.propiedadId]) do
            if m.mueble_id == datos.muebleId then
                Muebles.mueblesPorPropiedad[datos.propiedadId][i].posicion = posicion
                Muebles.mueblesPorPropiedad[datos.propiedadId][i].rotacion = rotacion
                break
            end
        end
    end

    -- Limpiar estado
    Muebles.colocando[source] = nil

    -- Notificar cambio
    Muebles.NotificarCambioMueble(datos.propiedadId, 'movido', {
        mueble_id = datos.muebleId,
        posicion = posicion,
        rotacion = rotacion
    })

    return true, 'Mueble movido correctamente'
end

--- Rotar mueble rapidamente
---@param source number
---@param charId number
---@param muebleId number
---@param angulo number
---@return boolean, string
function Muebles.Rotar(source, charId, muebleId, angulo)
    -- Obtener mueble
    local mueble = MySQL.query.await([[
        SELECT m.*, p.propietario_char_id
        FROM ait_propiedad_muebles m
        JOIN ait_propiedades p ON m.propiedad_id = p.propiedad_id
        WHERE m.mueble_id = ?
    ]], { muebleId })

    if not mueble or #mueble == 0 then
        return false, 'Mueble no encontrado'
    end

    mueble = mueble[1]

    if mueble.propietario_char_id ~= charId then
        return false, 'Solo el propietario puede rotar muebles'
    end

    local catalogoMueble = Muebles.ObtenerDelCatalogo(mueble.catalogo_id)
    if not catalogoMueble or not catalogoMueble.rotable then
        return false, 'Este mueble no se puede rotar'
    end

    -- Calcular nueva rotacion
    local rotacionActual = mueble.rotacion and json.decode(mueble.rotacion) or { x = 0, y = 0, z = 0 }
    rotacionActual.z = (rotacionActual.z + angulo) % 360

    -- Actualizar en BD
    MySQL.query.await([[
        UPDATE ait_propiedad_muebles SET rotacion = ? WHERE mueble_id = ?
    ]], { json.encode(rotacionActual), muebleId })

    -- Actualizar cache
    if Muebles.mueblesPorPropiedad[mueble.propiedad_id] then
        for i, m in ipairs(Muebles.mueblesPorPropiedad[mueble.propiedad_id]) do
            if m.mueble_id == muebleId then
                Muebles.mueblesPorPropiedad[mueble.propiedad_id][i].rotacion = rotacionActual
                break
            end
        end
    end

    -- Notificar
    Muebles.NotificarCambioMueble(mueble.propiedad_id, 'rotado', {
        mueble_id = muebleId,
        rotacion = rotacionActual
    })

    return true, 'Mueble rotado'
end

-- =====================================================================================
-- ELIMINAR MUEBLES
-- =====================================================================================

--- Eliminar un mueble
---@param source number
---@param charId number
---@param muebleId number
---@param devolucion boolean Si devolver parte del dinero
---@return boolean, string
function Muebles.Eliminar(source, charId, muebleId, devolucion)
    -- Obtener mueble
    local mueble = MySQL.query.await([[
        SELECT m.*, p.propietario_char_id, p.propiedad_id
        FROM ait_propiedad_muebles m
        JOIN ait_propiedades p ON m.propiedad_id = p.propiedad_id
        WHERE m.mueble_id = ?
    ]], { muebleId })

    if not mueble or #mueble == 0 then
        return false, 'Mueble no encontrado'
    end

    mueble = mueble[1]

    if mueble.propietario_char_id ~= charId then
        return false, 'Solo el propietario puede eliminar muebles'
    end

    local catalogoMueble = Muebles.ObtenerDelCatalogo(mueble.catalogo_id)

    -- Devolucion parcial (50% del valor)
    if devolucion and catalogoMueble and AIT.Engines and AIT.Engines.economy then
        local devolucionMonto = math.floor(catalogoMueble.precio * 0.5)
        AIT.Engines.economy.AddMoney(source, charId, devolucionMonto, 'bank', 'trade',
            'Devolucion mueble: ' .. (catalogoMueble.nombre or 'Desconocido'))
    end

    -- Eliminar de BD
    MySQL.query.await([[
        DELETE FROM ait_propiedad_muebles WHERE mueble_id = ?
    ]], { muebleId })

    -- Si tenia almacenamiento asociado, eliminarlo
    if catalogoMueble and catalogoMueble.tipoAlmacen then
        MySQL.query([[
            DELETE FROM ait_propiedad_almacenamiento
            WHERE propiedad_id = ? AND tipo = ? AND metadata LIKE ?
        ]], { mueble.propiedad_id, catalogoMueble.tipoAlmacen, '%"mueble_id":' .. muebleId .. '%' })
    end

    -- Actualizar cache
    if Muebles.mueblesPorPropiedad[mueble.propiedad_id] then
        for i, m in ipairs(Muebles.mueblesPorPropiedad[mueble.propiedad_id]) do
            if m.mueble_id == muebleId then
                table.remove(Muebles.mueblesPorPropiedad[mueble.propiedad_id], i)
                break
            end
        end
    end

    -- Notificar
    Muebles.NotificarCambioMueble(mueble.propiedad_id, 'eliminado', { mueble_id = muebleId })

    -- Log
    if AIT.Engines.Housing then
        AIT.Engines.Housing.RegistrarLog(mueble.propiedad_id, 'MUEBLE_ELIMINADO', charId, {
            mueble_id = muebleId,
            catalogo_id = mueble.catalogo_id
        })
    end

    return true, 'Mueble eliminado' .. (devolucion and ' (devolucion procesada)' or '')
end

-- =====================================================================================
-- NOTIFICACIONES
-- =====================================================================================

function Muebles.NotificarCambioMueble(propiedadId, tipo, datos)
    -- Notificar a todos los jugadores en la propiedad
    if AIT.Engines.Housing and AIT.Engines.Housing.propietariosOnline then
        local jugadores = AIT.Engines.Housing.propietariosOnline[propiedadId] or {}

        for charId, sourceId in pairs(jugadores) do
            TriggerClientEvent('ait:housing:furniture:update', sourceId, {
                tipo = tipo,
                datos = datos
            })
        end
    end
end

-- =====================================================================================
-- CALLBACKS
-- =====================================================================================

function Muebles.RegistrarCallbacks()
    if not AIT.Callbacks then return end

    -- Obtener catalogo
    AIT.Callbacks.Register('housing:furniture:getCatalogo', function(source, cb, categoria)
        local catalogo = Muebles.ObtenerCatalogo(categoria)
        cb(catalogo)
    end)

    -- Obtener muebles de propiedad
    AIT.Callbacks.Register('housing:furniture:getMuebles', function(source, cb, propiedadId)
        local muebles = Muebles.ObtenerMueblesPropiedad(propiedadId)
        cb(muebles)
    end)

    -- Obtener categorias
    AIT.Callbacks.Register('housing:furniture:getCategorias', function(source, cb)
        cb(Muebles.Categorias)
    end)
end

-- =====================================================================================
-- EVENTOS DEL SERVIDOR
-- =====================================================================================

-- Confirmar colocacion desde cliente
RegisterNetEvent('ait:housing:furniture:confirmPlacement', function(posicion, rotacion)
    local source = source
    local success, msg = Muebles.ConfirmarColocacion(source, posicion, rotacion)

    if success then
        TriggerClientEvent('QBCore:Notify', source, msg, 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, msg, 'error')
    end

    TriggerClientEvent('ait:housing:furniture:endPlacement', source, success)
end)

-- Cancelar colocacion desde cliente
RegisterNetEvent('ait:housing:furniture:cancelPlacement', function()
    local source = source
    Muebles.CancelarColocacion(source)
end)

-- Confirmar movimiento desde cliente
RegisterNetEvent('ait:housing:furniture:confirmMove', function(posicion, rotacion)
    local source = source
    local success, msg = Muebles.ConfirmarMovimiento(source, posicion, rotacion)

    if success then
        TriggerClientEvent('QBCore:Notify', source, msg, 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, msg, 'error')
    end

    TriggerClientEvent('ait:housing:furniture:endMove', source, success)
end)

-- =====================================================================================
-- EXPORTS
-- =====================================================================================

-- Getters
Muebles.GetCatalog = Muebles.ObtenerCatalogo
Muebles.GetFromCatalog = Muebles.ObtenerDelCatalogo
Muebles.GetPropertyFurniture = Muebles.ObtenerMueblesPropiedad
Muebles.GetFurnitureCount = Muebles.ContarMuebles

-- Actions
Muebles.StartPlacement = Muebles.IniciarColocacion
Muebles.ConfirmPlacement = Muebles.ConfirmarColocacion
Muebles.CancelPlacement = Muebles.CancelarColocacion
Muebles.StartMove = Muebles.IniciarMovimiento
Muebles.ConfirmMove = Muebles.ConfirmarMovimiento
Muebles.Rotate = Muebles.Rotar
Muebles.Remove = Muebles.Eliminar

-- =====================================================================================
-- REGISTRAR SUBMODULO
-- =====================================================================================

AIT.Engines.Housing.Furniture = Muebles

return Muebles
