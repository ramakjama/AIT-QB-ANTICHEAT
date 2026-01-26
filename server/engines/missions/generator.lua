-- =====================================================================================
-- ait-qb GENERADOR PROCEDURAL DE MISIONES
-- Sistema de generacion dinamica de misiones con balanceo de dificultad
-- Namespace: AIT.Engines.Missions.Generator
-- =====================================================================================

AIT = AIT or {}
AIT.Engines = AIT.Engines or {}
AIT.Engines.Missions = AIT.Engines.Missions or {}

local Generador = {
    -- Cache de ubicaciones
    ubicaciones = {},
    -- Cache de NPCs disponibles
    npcs = {},
    -- Cache de vehiculos
    vehiculos = {},
    -- Semilla para generacion
    semilla = 0,
}

-- =====================================================================================
-- CONFIGURACION DE UBICACIONES POR ZONA
-- =====================================================================================

Generador.Zonas = {
    centro = {
        nombre = 'Centro de Los Santos',
        dificultadBase = 2,
        riesgo = 'bajo',
        densidadPolicial = 'alta',
        puntos = {
            { x = 215.0, y = -810.0, z = 30.0, nombre = 'Centro comercial' },
            { x = 147.0, y = -1035.0, z = 29.0, nombre = 'Banco Maze' },
            { x = -537.0, y = -213.0, z = 38.0, nombre = 'Centro medico' },
            { x = 428.0, y = -984.0, z = 30.0, nombre = 'Comisaria central' },
            { x = -269.0, y = -955.0, z = 31.0, nombre = 'Parking subterraneo' },
        },
    },
    aeropuerto = {
        nombre = 'Aeropuerto Internacional',
        dificultadBase = 3,
        riesgo = 'medio',
        densidadPolicial = 'alta',
        puntos = {
            { x = -1037.0, y = -2737.0, z = 20.0, nombre = 'Terminal principal' },
            { x = -1336.0, y = -3044.0, z = 14.0, nombre = 'Hangares privados' },
            { x = -979.0, y = -2997.0, z = 14.0, nombre = 'Zona de carga' },
            { x = -1240.0, y = -3389.0, z = 14.0, nombre = 'Pistas secundarias' },
        },
    },
    puerto = {
        nombre = 'Puerto de Los Santos',
        dificultadBase = 4,
        riesgo = 'alto',
        densidadPolicial = 'baja',
        puntos = {
            { x = 1215.0, y = -2882.0, z = 6.0, nombre = 'Muelle principal' },
            { x = 802.0, y = -3009.0, z = 6.0, nombre = 'Almacenes' },
            { x = 1088.0, y = -3101.0, z = 6.0, nombre = 'Contenedores' },
            { x = 459.0, y = -3169.0, z = 6.0, nombre = 'Zona industrial' },
        },
    },
    vinewood = {
        nombre = 'Vinewood Hills',
        dificultadBase = 2,
        riesgo = 'bajo',
        densidadPolicial = 'media',
        puntos = {
            { x = 611.0, y = 269.0, z = 103.0, nombre = 'Mansion exclusiva' },
            { x = -1288.0, y = 440.0, z = 97.0, nombre = 'Galeria de arte' },
            { x = -1850.0, y = 274.0, z = 88.0, nombre = 'Club privado' },
            { x = 294.0, y = 180.0, z = 104.0, nombre = 'Estudio de cine' },
        },
    },
    desierto = {
        nombre = 'Desierto de Grand Senora',
        dificultadBase = 5,
        riesgo = 'muy_alto',
        densidadPolicial = 'muy_baja',
        puntos = {
            { x = 1647.0, y = 4779.0, z = 42.0, nombre = 'Laboratorio abandonado' },
            { x = 2489.0, y = 4955.0, z = 45.0, nombre = 'Granja remota' },
            { x = 1392.0, y = 3613.0, z = 35.0, nombre = 'Deposito de chatarra' },
            { x = 2671.0, y = 3263.0, z = 55.0, nombre = 'Mina abandonada' },
        },
    },
    paleto = {
        nombre = 'Paleto Bay',
        dificultadBase = 3,
        riesgo = 'medio',
        densidadPolicial = 'baja',
        puntos = {
            { x = -312.0, y = 6228.0, z = 31.0, nombre = 'Centro del pueblo' },
            { x = 109.0, y = 6620.0, z = 32.0, nombre = 'Granja norte' },
            { x = -55.0, y = 6340.0, z = 31.0, nombre = 'Tienda local' },
            { x = -448.0, y = 6009.0, z = 32.0, nombre = 'Aserradero' },
        },
    },
    montanas = {
        nombre = 'Mount Chiliad',
        dificultadBase = 4,
        riesgo = 'alto',
        densidadPolicial = 'muy_baja',
        puntos = {
            { x = 501.0, y = 5604.0, z = 797.0, nombre = 'Cima Chiliad' },
            { x = 1102.0, y = 4270.0, z = 138.0, nombre = 'Campamento' },
            { x = -290.0, y = 4730.0, z = 137.0, nombre = 'Refugio forestal' },
            { x = 2877.0, y = 5911.0, z = 369.0, nombre = 'Antena de radio' },
        },
    },
    industrial = {
        nombre = 'Zona Industrial',
        dificultadBase = 3,
        riesgo = 'medio',
        densidadPolicial = 'media',
        puntos = {
            { x = 723.0, y = -1096.0, z = 22.0, nombre = 'Fabrica textil' },
            { x = 892.0, y = -1061.0, z = 32.0, nombre = 'Almacen logistico' },
            { x = 481.0, y = -1312.0, z = 29.0, nombre = 'Taller mecanico' },
            { x = 538.0, y = -1568.0, z = 29.0, nombre = 'Deposito de coches' },
        },
    },
}

-- =====================================================================================
-- CONFIGURACION DE NPCs
-- =====================================================================================

Generador.ModelosNPC = {
    civiles = {
        'a_m_m_bevhills_01', 'a_m_m_bevhills_02', 'a_m_m_business_01',
        'a_m_m_eastsa_01', 'a_m_m_farmer_01', 'a_m_m_golfer_01',
        'a_f_m_bevhills_01', 'a_f_m_bevhills_02', 'a_f_m_business_02',
        'a_f_m_downtown_01', 'a_f_m_eastsa_01', 'a_f_m_fatwhite_01',
    },
    trabajadores = {
        's_m_m_dockwork_01', 's_m_m_warehouse_01', 's_m_m_autoshop_01',
        's_m_m_autoshop_02', 's_m_m_paramedic_01', 's_m_m_pilot_01',
        's_f_m_retailstaff_01', 's_f_m_shop_high', 's_f_m_sweatshop_01',
    },
    criminales = {
        'g_m_m_armboss_01', 'g_m_m_armgoon_01', 'g_m_m_armlieut_01',
        'g_m_m_chemwork_01', 'g_m_m_chiboss_01', 'g_m_m_chicold_01',
        'g_m_m_chigoon_01', 'g_m_m_korboss_01', 'g_m_m_mexboss_01',
        'g_m_y_ballaorig_01', 'g_m_y_ballaeast_01', 'g_m_y_famca_01',
    },
    seguridad = {
        's_m_m_security_01', 's_m_m_prisguard_01', 's_m_m_armoured_01',
        's_m_m_armoured_02', 's_m_m_bouncer_01', 's_m_m_highsec_01',
    },
}

-- =====================================================================================
-- CONFIGURACION DE VEHICULOS
-- =====================================================================================

Generador.ModelosVehiculo = {
    compactos = {
        'blista', 'brioso', 'dilettante', 'issi2', 'panto', 'prairie',
    },
    sedanes = {
        'asea', 'asterope', 'emperor', 'fugitive', 'glendale', 'ingot',
        'intruder', 'premier', 'primo', 'regina', 'romero', 'schafter2',
        'stanier', 'stratum', 'surge', 'tailgater', 'warrener', 'washington',
    },
    deportivos = {
        'comet2', 'coquette', 'elegy2', 'feltzer2', 'furoregt', 'jester',
        'khamelion', 'massacro', 'ninef', 'rapidgt', 'surano', 'banshee',
    },
    todoterreno = {
        'baller', 'bjxl', 'cavalcade', 'dubsta', 'fq2', 'granger', 'gresley',
        'habanero', 'huntley', 'landstalker', 'mesa', 'patriot', 'radi',
        'rocoto', 'seminole', 'serrano', 'xls',
    },
    furgonetas = {
        'bison', 'bobcatxl', 'boxville', 'burrito', 'burrito2', 'camper',
        'gburrito', 'journey', 'minivan', 'pony', 'rumpo', 'speedo',
        'surfer', 'taco', 'youga',
    },
    camiones = {
        'benson', 'mule', 'mule2', 'mule3', 'packer', 'phantom',
        'pounder', 'stockade', 'hauler', 'flatbed', 'mixer', 'rubble',
    },
    motos = {
        'akuma', 'bagger', 'bati', 'bati2', 'carbonrs', 'daemon',
        'double', 'enduro', 'faggio2', 'hexer', 'nemesis', 'pcj',
        'ruffian', 'sanchez', 'thrust', 'vader',
    },
}

-- =====================================================================================
-- INICIALIZACION
-- =====================================================================================

function Generador.Initialize()
    -- Inicializar semilla
    Generador.semilla = os.time()
    math.randomseed(Generador.semilla)

    -- Cargar ubicaciones personalizadas de BD
    Generador.CargarUbicacionesPersonalizadas()

    -- Cargar NPCs personalizados
    Generador.CargarNPCsPersonalizados()

    if AIT.Log then
        AIT.Log.info('MISSIONS:GEN', 'Generador de misiones inicializado')
    end

    return true
end

function Generador.CargarUbicacionesPersonalizadas()
    local result = MySQL.query.await([[
        SELECT * FROM ait_misiones_ubicaciones WHERE activa = 1
    ]])

    for _, ub in ipairs(result or {}) do
        local zona = ub.zona
        if not Generador.ubicaciones[zona] then
            Generador.ubicaciones[zona] = {}
        end

        table.insert(Generador.ubicaciones[zona], {
            x = ub.coord_x,
            y = ub.coord_y,
            z = ub.coord_z,
            nombre = ub.nombre,
            tipo = ub.tipo,
            metadata = ub.metadata and json.decode(ub.metadata) or {},
        })
    end
end

function Generador.CargarNPCsPersonalizados()
    local result = MySQL.query.await([[
        SELECT * FROM ait_misiones_npcs WHERE activo = 1
    ]])

    for _, npc in ipairs(result or {}) do
        local categoria = npc.categoria or 'civiles'
        if not Generador.npcs[categoria] then
            Generador.npcs[categoria] = {}
        end

        table.insert(Generador.npcs[categoria], {
            modelo = npc.modelo,
            nombre = npc.nombre,
            dialogo = npc.dialogo and json.decode(npc.dialogo) or {},
            metadata = npc.metadata and json.decode(npc.metadata) or {},
        })
    end
end

-- =====================================================================================
-- GENERACION PRINCIPAL
-- =====================================================================================

--- Generar una mision proceduralmente
---@param plantilla table Plantilla de la mision
---@param dificultad number Nivel de dificultad (1-6)
---@return table Mision generada
function Generador.Generar(plantilla, dificultad)
    local nivelDificultad = AIT.Engines.Missions.NivelesDificultad[dificultad]
    if not nivelDificultad then
        nivelDificultad = AIT.Engines.Missions.NivelesDificultad[3]
    end

    local misionGenerada = {
        objetivos = {},
        objetivos_totales = 0,
        progreso = {},
        checkpoints = {},
        npcs = {},
        vehiculos = {},
        ubicaciones = {},
        metadata = {
            dificultad = dificultad,
            generado_en = os.time(),
            semilla = Generador.semilla,
        },
    }

    -- Generar segun tipo de mision
    local tipo = plantilla.tipo

    if tipo == 'delivery' then
        misionGenerada = Generador.GenerarDelivery(plantilla, dificultad, nivelDificultad, misionGenerada)
    elseif tipo == 'collect' then
        misionGenerada = Generador.GenerarCollect(plantilla, dificultad, nivelDificultad, misionGenerada)
    elseif tipo == 'hunt' then
        misionGenerada = Generador.GenerarHunt(plantilla, dificultad, nivelDificultad, misionGenerada)
    elseif tipo == 'escort' then
        misionGenerada = Generador.GenerarEscort(plantilla, dificultad, nivelDificultad, misionGenerada)
    elseif tipo == 'race' then
        misionGenerada = Generador.GenerarRace(plantilla, dificultad, nivelDificultad, misionGenerada)
    else
        -- Generacion generica
        misionGenerada = Generador.GenerarGenerica(plantilla, dificultad, nivelDificultad, misionGenerada)
    end

    -- Calcular objetivos totales
    misionGenerada.objetivos_totales = #misionGenerada.objetivos

    -- Inicializar progreso
    for i, objetivo in ipairs(misionGenerada.objetivos) do
        misionGenerada.progreso[i] = {
            completado = false,
            progreso_actual = 0,
            progreso_requerido = objetivo.cantidad or 1,
        }
    end

    return misionGenerada
end

-- =====================================================================================
-- GENERADORES POR TIPO
-- =====================================================================================

--- Generar mision de entrega
function Generador.GenerarDelivery(plantilla, dificultad, nivelDificultad, mision)
    local numEntregas = math.min(2 + dificultad, nivelDificultad.checkpointsMax)

    -- Seleccionar zona de origen
    local zonaOrigen = Generador.SeleccionarZona(dificultad, 'origen')
    local puntoOrigen = Generador.SeleccionarPuntoEnZona(zonaOrigen)

    -- Generar puntos de entrega
    local puntosEntrega = {}
    for i = 1, numEntregas do
        local zonaDestino = Generador.SeleccionarZona(dificultad, 'destino', zonaOrigen)
        local puntoDestino = Generador.SeleccionarPuntoEnZona(zonaDestino)

        table.insert(puntosEntrega, {
            zona = zonaDestino,
            punto = puntoDestino,
            orden = i,
        })
    end

    -- Generar vehiculo si es necesario
    local vehiculo = nil
    if plantilla.requiereVehiculo or AIT.Engines.Missions.Tipos.delivery.requiereVehiculo then
        vehiculo = Generador.SeleccionarVehiculo('furgonetas', dificultad)
    end

    -- Crear objetivos
    table.insert(mision.objetivos, {
        tipo = 'ir_a',
        descripcion = ('Ir a %s para recoger el paquete'):format(puntoOrigen.nombre),
        ubicacion = puntoOrigen,
        cantidad = 1,
        orden = 1,
    })

    for i, entrega in ipairs(puntosEntrega) do
        table.insert(mision.objetivos, {
            tipo = 'entregar',
            descripcion = ('Entregar paquete en %s'):format(entrega.punto.nombre),
            ubicacion = entrega.punto,
            cantidad = 1,
            orden = i + 1,
        })

        table.insert(mision.checkpoints, {
            x = entrega.punto.x,
            y = entrega.punto.y,
            z = entrega.punto.z,
            tipo = 'entrega',
            radio = 3.0,
            orden = i + 1,
        })
    end

    -- Guardar datos generados
    mision.ubicaciones = {
        origen = puntoOrigen,
        destinos = puntosEntrega,
    }

    if vehiculo then
        mision.vehiculos = { vehiculo }
    end

    mision.metadata.tipo_generado = 'delivery'
    mision.metadata.num_entregas = numEntregas

    return mision
end

--- Generar mision de recoleccion
function Generador.GenerarCollect(plantilla, dificultad, nivelDificultad, mision)
    local numItems = math.min(3 + dificultad, nivelDificultad.checkpointsMax)

    -- Seleccionar zona principal
    local zonaPrincipal = Generador.SeleccionarZona(dificultad, 'recoleccion')

    -- Generar puntos de recoleccion
    local puntosRecoleccion = {}
    local zonasUsadas = { [zonaPrincipal] = true }

    for i = 1, numItems do
        local zona = zonaPrincipal
        -- Variar zonas para dificultades altas
        if dificultad >= 4 and i > 2 then
            zona = Generador.SeleccionarZona(dificultad, 'recoleccion', zonaPrincipal)
            zonasUsadas[zona] = true
        end

        local punto = Generador.SeleccionarPuntoEnZona(zona)
        table.insert(puntosRecoleccion, {
            zona = zona,
            punto = punto,
            item = Generador.GenerarItem(plantilla, dificultad),
            orden = i,
        })
    end

    -- Generar punto de entrega final
    local zonaEntrega = Generador.SeleccionarZona(dificultad, 'destino')
    local puntoEntrega = Generador.SeleccionarPuntoEnZona(zonaEntrega)

    -- Crear objetivos de recoleccion
    for i, recoleccion in ipairs(puntosRecoleccion) do
        table.insert(mision.objetivos, {
            tipo = 'recoger',
            descripcion = ('Recoger %s en %s'):format(recoleccion.item.nombre, recoleccion.punto.nombre),
            ubicacion = recoleccion.punto,
            item = recoleccion.item,
            cantidad = 1,
            orden = i,
        })

        table.insert(mision.checkpoints, {
            x = recoleccion.punto.x,
            y = recoleccion.punto.y,
            z = recoleccion.punto.z,
            tipo = 'recoleccion',
            radio = 2.0,
            orden = i,
        })
    end

    -- Objetivo de entrega final
    table.insert(mision.objetivos, {
        tipo = 'entregar_todos',
        descripcion = ('Entregar todos los items en %s'):format(puntoEntrega.nombre),
        ubicacion = puntoEntrega,
        cantidad = 1,
        orden = numItems + 1,
    })

    table.insert(mision.checkpoints, {
        x = puntoEntrega.x,
        y = puntoEntrega.y,
        z = puntoEntrega.z,
        tipo = 'entrega_final',
        radio = 3.0,
        orden = numItems + 1,
    })

    mision.ubicaciones = {
        puntos_recoleccion = puntosRecoleccion,
        entrega = puntoEntrega,
    }

    mision.metadata.tipo_generado = 'collect'
    mision.metadata.num_items = numItems

    return mision
end

--- Generar mision de caza/combate
function Generador.GenerarHunt(plantilla, dificultad, nivelDificultad, mision)
    local numObjetivos = math.min(2 + math.floor(dificultad * 1.5), nivelDificultad.enemigosMax)
    local numOleadas = math.min(1 + math.floor(dificultad / 2), 4)

    -- Seleccionar zona de combate (preferir zonas de alto riesgo)
    local zonaCombate = Generador.SeleccionarZona(dificultad, 'combate')
    local puntoCombate = Generador.SeleccionarPuntoEnZona(zonaCombate)

    -- Generar enemigos
    local enemigos = {}
    local categoriaEnemigos = dificultad >= 4 and 'criminales' or 'seguridad'

    for i = 1, numObjetivos do
        local modeloEnemigo = Generador.SeleccionarNPC(categoriaEnemigos)
        local offset = Generador.GenerarOffsetAleatorio(15)

        table.insert(enemigos, {
            modelo = modeloEnemigo,
            posicion = {
                x = puntoCombate.x + offset.x,
                y = puntoCombate.y + offset.y,
                z = puntoCombate.z,
            },
            oleada = math.ceil(i / (numObjetivos / numOleadas)),
            armado = dificultad >= 2,
            precision = 0.3 + (dificultad * 0.1),
            salud = 100 + (dificultad * 50),
        })
    end

    -- Crear objetivos
    table.insert(mision.objetivos, {
        tipo = 'ir_a_zona',
        descripcion = ('Dirigirse a %s'):format(puntoCombate.nombre),
        ubicacion = puntoCombate,
        cantidad = 1,
        orden = 1,
    })

    for oleada = 1, numOleadas do
        local enemigosOleada = 0
        for _, enemigo in ipairs(enemigos) do
            if enemigo.oleada == oleada then
                enemigosOleada = enemigosOleada + 1
            end
        end

        table.insert(mision.objetivos, {
            tipo = 'eliminar',
            descripcion = ('Eliminar oleada %d (%d enemigos)'):format(oleada, enemigosOleada),
            cantidad = enemigosOleada,
            oleada = oleada,
            orden = oleada + 1,
        })
    end

    table.insert(mision.checkpoints, {
        x = puntoCombate.x,
        y = puntoCombate.y,
        z = puntoCombate.z,
        tipo = 'zona_combate',
        radio = 30.0,
        orden = 1,
    })

    mision.npcs = enemigos
    mision.ubicaciones = {
        zona_combate = puntoCombate,
    }

    mision.metadata.tipo_generado = 'hunt'
    mision.metadata.num_enemigos = numObjetivos
    mision.metadata.num_oleadas = numOleadas

    return mision
end

--- Generar mision de escolta
function Generador.GenerarEscort(plantilla, dificultad, nivelDificultad, mision)
    local numCheckpoints = math.min(3 + dificultad, nivelDificultad.checkpointsMax)
    local numEmboscadas = math.min(math.floor(dificultad / 2), 3)

    -- Generar ruta
    local zonaOrigen = Generador.SeleccionarZona(dificultad, 'origen')
    local puntoOrigen = Generador.SeleccionarPuntoEnZona(zonaOrigen)

    local zonaDestino = Generador.SeleccionarZona(dificultad, 'destino', zonaOrigen)
    local puntoDestino = Generador.SeleccionarPuntoEnZona(zonaDestino)

    -- Generar checkpoints intermedios
    local rutaCheckpoints = Generador.GenerarRuta(puntoOrigen, puntoDestino, numCheckpoints)

    -- Generar NPC a escoltar
    local npcEscolta = {
        modelo = Generador.SeleccionarNPC('civiles'),
        nombre = Generador.GenerarNombreNPC(),
        posicion = puntoOrigen,
        esObjetivo = true,
        salud = 150 + (dificultad * 25),
    }

    -- Generar emboscadas
    local emboscadas = {}
    if numEmboscadas > 0 then
        local puntosEmboscada = Generador.SeleccionarPuntosEmboscada(rutaCheckpoints, numEmboscadas)

        for i, punto in ipairs(puntosEmboscada) do
            local numEnemigos = 2 + dificultad
            local enemigos = {}

            for j = 1, numEnemigos do
                local offset = Generador.GenerarOffsetAleatorio(20)
                table.insert(enemigos, {
                    modelo = Generador.SeleccionarNPC('criminales'),
                    posicion = {
                        x = punto.x + offset.x,
                        y = punto.y + offset.y,
                        z = punto.z,
                    },
                    armado = true,
                })
            end

            table.insert(emboscadas, {
                punto = punto,
                enemigos = enemigos,
                activada = false,
            })
        end
    end

    -- Generar vehiculo de escolta
    local vehiculo = Generador.SeleccionarVehiculo('sedanes', dificultad)

    -- Crear objetivos
    table.insert(mision.objetivos, {
        tipo = 'encontrar_objetivo',
        descripcion = ('Encontrar a %s'):format(npcEscolta.nombre),
        ubicacion = puntoOrigen,
        cantidad = 1,
        orden = 1,
    })

    for i, checkpoint in ipairs(rutaCheckpoints) do
        table.insert(mision.objetivos, {
            tipo = 'escoltar_a',
            descripcion = ('Escoltar a checkpoint %d'):format(i),
            ubicacion = checkpoint,
            cantidad = 1,
            orden = i + 1,
        })

        table.insert(mision.checkpoints, {
            x = checkpoint.x,
            y = checkpoint.y,
            z = checkpoint.z,
            tipo = 'checkpoint_escolta',
            radio = 5.0,
            orden = i + 1,
        })
    end

    table.insert(mision.objetivos, {
        tipo = 'entregar_objetivo',
        descripcion = ('Llevar a %s a destino seguro'):format(npcEscolta.nombre),
        ubicacion = puntoDestino,
        cantidad = 1,
        orden = #rutaCheckpoints + 2,
    })

    -- Objetivos de emboscadas
    for i, emboscada in ipairs(emboscadas) do
        table.insert(mision.objetivos, {
            tipo = 'sobrevivir_emboscada',
            descripcion = ('Sobrevivir emboscada %d'):format(i),
            cantidad = #emboscada.enemigos,
            opcional = false,
            orden = 100 + i, -- Orden alto para que sea dinamico
        })
    end

    mision.npcs = { npcEscolta }
    mision.vehiculos = { vehiculo }
    mision.ubicaciones = {
        origen = puntoOrigen,
        destino = puntoDestino,
        ruta = rutaCheckpoints,
        emboscadas = emboscadas,
    }

    mision.metadata.tipo_generado = 'escort'
    mision.metadata.num_emboscadas = numEmboscadas

    return mision
end

--- Generar mision de carrera
function Generador.GenerarRace(plantilla, dificultad, nivelDificultad, mision)
    local numCheckpoints = math.min(5 + (dificultad * 2), nivelDificultad.checkpointsMax)

    -- Seleccionar tipo de carrera
    local tiposCarrera = { 'circuito', 'punto_a_punto', 'sprint' }
    local tipoCarrera = tiposCarrera[math.random(1, #tiposCarrera)]

    -- Generar ruta segun tipo
    local checkpoints = {}
    local zonaCarrera = Generador.SeleccionarZona(dificultad, 'carrera')

    if tipoCarrera == 'circuito' then
        -- Circuito cerrado
        local puntoInicio = Generador.SeleccionarPuntoEnZona(zonaCarrera)
        checkpoints = Generador.GenerarCircuito(puntoInicio, numCheckpoints, nivelDificultad.distanciaMax)
    elseif tipoCarrera == 'punto_a_punto' then
        -- De un punto a otro
        local zonaFin = Generador.SeleccionarZona(dificultad, 'destino', zonaCarrera)
        local puntoInicio = Generador.SeleccionarPuntoEnZona(zonaCarrera)
        local puntoFin = Generador.SeleccionarPuntoEnZona(zonaFin)
        checkpoints = Generador.GenerarRuta(puntoInicio, puntoFin, numCheckpoints)
    else
        -- Sprint corto
        local puntoInicio = Generador.SeleccionarPuntoEnZona(zonaCarrera)
        checkpoints = Generador.GenerarSprint(puntoInicio, math.min(numCheckpoints, 5))
    end

    -- Generar vehiculo
    local categoriaVehiculo = dificultad >= 4 and 'deportivos' or 'sedanes'
    local vehiculo = Generador.SeleccionarVehiculo(categoriaVehiculo, dificultad)

    -- Calcular tiempo limite basado en distancia
    local distanciaTotal = Generador.CalcularDistanciaRuta(checkpoints)
    local velocidadPromedio = 80 + (dificultad * 10) -- km/h estimado
    local tiempoBase = (distanciaTotal / 1000) / (velocidadPromedio / 3600) -- segundos
    local tiempoLimite = math.floor(tiempoBase * (2 - (dificultad * 0.15)))

    -- Crear objetivos
    table.insert(mision.objetivos, {
        tipo = 'obtener_vehiculo',
        descripcion = 'Obtener vehiculo de carrera',
        cantidad = 1,
        orden = 1,
    })

    for i, checkpoint in ipairs(checkpoints) do
        table.insert(mision.objetivos, {
            tipo = 'pasar_checkpoint',
            descripcion = ('Pasar checkpoint %d/%d'):format(i, #checkpoints),
            ubicacion = checkpoint,
            cantidad = 1,
            orden = i + 1,
        })

        table.insert(mision.checkpoints, {
            x = checkpoint.x,
            y = checkpoint.y,
            z = checkpoint.z,
            tipo = 'checkpoint_carrera',
            radio = 8.0,
            orden = i,
        })
    end

    mision.vehiculos = { vehiculo }
    mision.ubicaciones = {
        checkpoints = checkpoints,
        inicio = checkpoints[1],
        fin = checkpoints[#checkpoints],
    }

    mision.metadata.tipo_generado = 'race'
    mision.metadata.tipo_carrera = tipoCarrera
    mision.metadata.distancia_total = distanciaTotal
    mision.metadata.tiempo_objetivo = tiempoLimite

    return mision
end

--- Generador generico para tipos no especificos
function Generador.GenerarGenerica(plantilla, dificultad, nivelDificultad, mision)
    local numObjetivos = #plantilla.objetivos

    if numObjetivos == 0 then
        numObjetivos = math.min(2 + dificultad, nivelDificultad.checkpointsMax)
    end

    -- Usar ubicaciones de la plantilla o generar nuevas
    local ubicaciones = {}
    if plantilla.ubicaciones and #plantilla.ubicaciones > 0 then
        ubicaciones = plantilla.ubicaciones
    else
        local zona = Generador.SeleccionarZona(dificultad, 'general')
        for i = 1, numObjetivos do
            table.insert(ubicaciones, Generador.SeleccionarPuntoEnZona(zona))
        end
    end

    -- Crear objetivos desde plantilla o genericos
    if plantilla.objetivos and #plantilla.objetivos > 0 then
        for i, obj in ipairs(plantilla.objetivos) do
            local ubicacion = ubicaciones[i] or ubicaciones[1]
            table.insert(mision.objetivos, {
                tipo = obj.tipo or 'ir_a',
                descripcion = obj.descripcion or ('Completar objetivo %d'):format(i),
                ubicacion = ubicacion,
                cantidad = obj.cantidad or 1,
                orden = i,
            })

            if ubicacion then
                table.insert(mision.checkpoints, {
                    x = ubicacion.x,
                    y = ubicacion.y,
                    z = ubicacion.z,
                    tipo = 'objetivo',
                    radio = 3.0,
                    orden = i,
                })
            end
        end
    else
        for i = 1, numObjetivos do
            local ubicacion = ubicaciones[i]
            table.insert(mision.objetivos, {
                tipo = 'ir_a',
                descripcion = ('Ir a ubicacion %d'):format(i),
                ubicacion = ubicacion,
                cantidad = 1,
                orden = i,
            })

            table.insert(mision.checkpoints, {
                x = ubicacion.x,
                y = ubicacion.y,
                z = ubicacion.z,
                tipo = 'objetivo',
                radio = 3.0,
                orden = i,
            })
        end
    end

    mision.ubicaciones = {
        puntos = ubicaciones,
    }

    mision.metadata.tipo_generado = 'generica'

    return mision
end

-- =====================================================================================
-- FUNCIONES DE SELECCION
-- =====================================================================================

--- Seleccionar una zona segun dificultad y proposito
function Generador.SeleccionarZona(dificultad, proposito, zonaExcluir)
    local zonasValidas = {}

    for nombreZona, zona in pairs(Generador.Zonas) do
        if nombreZona ~= zonaExcluir then
            -- Filtrar por dificultad
            local dificultadZona = zona.dificultadBase
            local diferencia = math.abs(dificultadZona - dificultad)

            if diferencia <= 2 then
                local peso = 100 - (diferencia * 20)

                -- Ajustar peso segun proposito
                if proposito == 'combate' and zona.riesgo == 'alto' then
                    peso = peso + 30
                elseif proposito == 'carrera' and zona.densidadPolicial == 'baja' then
                    peso = peso + 20
                elseif proposito == 'origen' and zona.riesgo == 'bajo' then
                    peso = peso + 25
                end

                table.insert(zonasValidas, { nombre = nombreZona, peso = peso })
            end
        end
    end

    if #zonasValidas == 0 then
        -- Fallback: cualquier zona
        for nombreZona, _ in pairs(Generador.Zonas) do
            if nombreZona ~= zonaExcluir then
                table.insert(zonasValidas, { nombre = nombreZona, peso = 50 })
            end
        end
    end

    return Generador.SeleccionarPorPeso(zonasValidas)
end

--- Seleccionar un punto dentro de una zona
function Generador.SeleccionarPuntoEnZona(nombreZona)
    local zona = Generador.Zonas[nombreZona]
    if not zona or not zona.puntos or #zona.puntos == 0 then
        -- Punto por defecto en el centro
        return { x = 0, y = 0, z = 0, nombre = 'Ubicacion desconocida' }
    end

    local punto = zona.puntos[math.random(1, #zona.puntos)]
    return punto
end

--- Seleccionar un vehiculo por categoria
function Generador.SeleccionarVehiculo(categoria, dificultad)
    local modelos = Generador.ModelosVehiculo[categoria]
    if not modelos or #modelos == 0 then
        modelos = Generador.ModelosVehiculo.sedanes
    end

    local modelo = modelos[math.random(1, #modelos)]

    return {
        modelo = modelo,
        color_primario = math.random(0, 159),
        color_secundario = math.random(0, 159),
        tuning = dificultad >= 4,
    }
end

--- Seleccionar un NPC por categoria
function Generador.SeleccionarNPC(categoria)
    local modelos = Generador.ModelosNPC[categoria]
    if not modelos or #modelos == 0 then
        modelos = Generador.ModelosNPC.civiles
    end

    return modelos[math.random(1, #modelos)]
end

--- Seleccionar elemento por peso
function Generador.SeleccionarPorPeso(elementos)
    local pesoTotal = 0
    for _, elem in ipairs(elementos) do
        pesoTotal = pesoTotal + (elem.peso or 1)
    end

    local random = math.random() * pesoTotal
    local acumulado = 0

    for _, elem in ipairs(elementos) do
        acumulado = acumulado + (elem.peso or 1)
        if random <= acumulado then
            return elem.nombre or elem
        end
    end

    return elementos[1].nombre or elementos[1]
end

-- =====================================================================================
-- FUNCIONES DE GENERACION AUXILIARES
-- =====================================================================================

--- Generar un item aleatorio para recoleccion
function Generador.GenerarItem(plantilla, dificultad)
    local items = {
        { nombre = 'Paquete sellado', icono = 'fa-box', valor = 100 * dificultad },
        { nombre = 'Documento confidencial', icono = 'fa-file-alt', valor = 150 * dificultad },
        { nombre = 'Componente electronico', icono = 'fa-microchip', valor = 200 * dificultad },
        { nombre = 'Muestra biologica', icono = 'fa-vial', valor = 250 * dificultad },
        { nombre = 'Prototipo', icono = 'fa-cube', valor = 300 * dificultad },
    }

    return items[math.random(1, #items)]
end

--- Generar nombre aleatorio para NPC
function Generador.GenerarNombreNPC()
    local nombres = {
        'Carlos', 'Miguel', 'Antonio', 'Luis', 'Pedro',
        'Maria', 'Ana', 'Carmen', 'Isabel', 'Rosa',
    }
    local apellidos = {
        'Garcia', 'Rodriguez', 'Martinez', 'Lopez', 'Gonzalez',
        'Hernandez', 'Perez', 'Sanchez', 'Ramirez', 'Torres',
    }

    return nombres[math.random(1, #nombres)] .. ' ' .. apellidos[math.random(1, #apellidos)]
end

--- Generar offset aleatorio
function Generador.GenerarOffsetAleatorio(radio)
    local angulo = math.random() * 2 * math.pi
    local distancia = math.random() * radio

    return {
        x = math.cos(angulo) * distancia,
        y = math.sin(angulo) * distancia,
    }
end

--- Generar ruta entre dos puntos
function Generador.GenerarRuta(origen, destino, numPuntos)
    local ruta = {}

    for i = 1, numPuntos do
        local t = i / (numPuntos + 1)

        -- Interpolacion lineal con variacion aleatoria
        local variacion = Generador.GenerarOffsetAleatorio(50)

        table.insert(ruta, {
            x = origen.x + (destino.x - origen.x) * t + variacion.x,
            y = origen.y + (destino.y - origen.y) * t + variacion.y,
            z = origen.z + (destino.z - origen.z) * t,
            nombre = ('Checkpoint %d'):format(i),
        })
    end

    return ruta
end

--- Generar circuito cerrado
function Generador.GenerarCircuito(centro, numPuntos, radioMax)
    local circuito = {}
    local radio = radioMax * 0.5

    for i = 1, numPuntos do
        local angulo = (i - 1) * (2 * math.pi / numPuntos)
        local radioVariado = radio * (0.8 + math.random() * 0.4)

        table.insert(circuito, {
            x = centro.x + math.cos(angulo) * radioVariado,
            y = centro.y + math.sin(angulo) * radioVariado,
            z = centro.z,
            nombre = ('Curva %d'):format(i),
        })
    end

    return circuito
end

--- Generar sprint corto
function Generador.GenerarSprint(inicio, numPuntos)
    local sprint = { inicio }
    local direccion = math.random() * 2 * math.pi
    local distanciaPorPunto = 100

    for i = 2, numPuntos do
        -- Variar ligeramente la direccion
        direccion = direccion + (math.random() - 0.5) * 0.5

        local ultimo = sprint[#sprint]
        table.insert(sprint, {
            x = ultimo.x + math.cos(direccion) * distanciaPorPunto,
            y = ultimo.y + math.sin(direccion) * distanciaPorPunto,
            z = ultimo.z,
            nombre = ('Sprint %d'):format(i),
        })
    end

    return sprint
end

--- Seleccionar puntos para emboscadas en una ruta
function Generador.SeleccionarPuntosEmboscada(ruta, cantidad)
    local puntos = {}
    local indices = {}

    -- Seleccionar indices aleatorios (evitando inicio y fin)
    while #indices < cantidad and #indices < #ruta - 2 do
        local idx = math.random(2, #ruta - 1)
        local yaExiste = false

        for _, existente in ipairs(indices) do
            if existente == idx then
                yaExiste = true
                break
            end
        end

        if not yaExiste then
            table.insert(indices, idx)
        end
    end

    for _, idx in ipairs(indices) do
        table.insert(puntos, ruta[idx])
    end

    return puntos
end

--- Calcular distancia total de una ruta
function Generador.CalcularDistanciaRuta(ruta)
    local distancia = 0

    for i = 2, #ruta do
        local dx = ruta[i].x - ruta[i-1].x
        local dy = ruta[i].y - ruta[i-1].y
        local dz = ruta[i].z - ruta[i-1].z

        distancia = distancia + math.sqrt(dx*dx + dy*dy + dz*dz)
    end

    return distancia
end

-- =====================================================================================
-- REGISTRAR SUBMODULO
-- =====================================================================================

AIT.Engines.Missions.Generator = Generador

return Generador
