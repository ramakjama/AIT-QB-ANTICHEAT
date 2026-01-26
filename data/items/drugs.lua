--[[
    AIT-QB Framework - Catalogo de Drogas e Items Ilegales
    Sistema de items relacionados con sustancias controladas

    Propiedades de cada item:
    - name: identificador unico (string)
    - label: nombre visible en español (string)
    - description: descripcion del item (string)
    - weight: peso en gramos (number)
    - price: precio base de compra (number)
    - sellPrice: precio de venta (number)
    - legal: legalidad del item (boolean, false = ilegal)
    - usable: si el item es consumible (boolean)
    - effects: tabla de efectos al consumir (si usable)
        - health: puntos de vida (+/-)
        - armor: puntos de armadura
        - stress: reduccion de estres (negativo = reduce)
        - stamina: puntos de estamina
        - drunk: nivel de embriaguez
        - high: nivel de colocado (0-100)
        - addiction: probabilidad de adiccion (0-100)
        - overdose: probabilidad de sobredosis (0-100)
        - duration: duracion del efecto en segundos
]]

return {
    -- ============================================================================
    -- DROGAS BASE - MARIHUANA
    -- ============================================================================
    {
        name = 'weed_brick',
        label = 'Ladrillo de Marihuana',
        description = 'Paquete compactado de marihuana sin procesar, listo para distribucion',
        weight = 500,
        price = 0,
        sellPrice = 500,
        legal = false,
        usable = false
    },
    {
        name = 'weed_bag',
        label = 'Bolsa de Marihuana',
        description = 'Bolsa de cogollos de marihuana de alta calidad',
        weight = 50,
        price = 0,
        sellPrice = 80,
        legal = false,
        usable = false
    },
    {
        name = 'weed_joint',
        label = 'Porro',
        description = 'Cigarro de marihuana listo para fumar, efecto relajante garantizado',
        weight = 5,
        price = 0,
        sellPrice = 25,
        legal = false,
        usable = true,
        effects = { stress = -40, high = 35, stamina = -10, addiction = 5, overdose = 0, duration = 180 }
    },
    {
        name = 'weed_blunt',
        label = 'Blunt',
        description = 'Puro relleno de marihuana, mas potente que un porro normal',
        weight = 10,
        price = 0,
        sellPrice = 40,
        legal = false,
        usable = true,
        effects = { stress = -50, high = 50, stamina = -15, addiction = 8, overdose = 0, duration = 240 }
    },
    {
        name = 'weed_edible',
        label = 'Brownie de Marihuana',
        description = 'Brownie de chocolate infusionado con THC, efecto tardio pero intenso',
        weight = 80,
        price = 0,
        sellPrice = 35,
        legal = false,
        usable = true,
        effects = { hunger = 15, stress = -60, high = 70, stamina = -20, addiction = 10, overdose = 2, duration = 360 }
    },

    -- ============================================================================
    -- DROGAS BASE - COCAINA
    -- ============================================================================
    {
        name = 'cocaine_brick',
        label = 'Ladrillo de Cocaina',
        description = 'Kilo de cocaina pura sin cortar, valor extremadamente alto',
        weight = 1000,
        price = 0,
        sellPrice = 5000,
        legal = false,
        usable = false
    },
    {
        name = 'cocaine_bag',
        label = 'Bolsa de Cocaina',
        description = 'Bolsa grande de cocaina lista para procesar',
        weight = 100,
        price = 0,
        sellPrice = 800,
        legal = false,
        usable = false
    },
    {
        name = 'cocaine_baggy',
        label = 'Bolsita de Cocaina',
        description = 'Pequeña bolsita de cocaina para consumo individual',
        weight = 10,
        price = 0,
        sellPrice = 150,
        legal = false,
        usable = true,
        effects = { stress = -30, high = 80, stamina = 50, health = -5, addiction = 40, overdose = 15, duration = 120 }
    },
    {
        name = 'crack_rock',
        label = 'Piedra de Crack',
        description = 'Cocaina procesada en forma de roca, altamente adictiva',
        weight = 5,
        price = 0,
        sellPrice = 100,
        legal = false,
        usable = true,
        effects = { stress = -20, high = 95, stamina = 60, health = -15, addiction = 70, overdose = 30, duration = 60 }
    },

    -- ============================================================================
    -- DROGAS BASE - METANFETAMINA
    -- ============================================================================
    {
        name = 'meth_tray',
        label = 'Bandeja de Metanfetamina',
        description = 'Bandeja con cristales de metanfetamina recien cocinados',
        weight = 200,
        price = 0,
        sellPrice = 2000,
        legal = false,
        usable = false
    },
    {
        name = 'meth_bag',
        label = 'Bolsa de Metanfetamina',
        description = 'Bolsa de cristales de metanfetamina azul de alta pureza',
        weight = 50,
        price = 0,
        sellPrice = 600,
        legal = false,
        usable = false
    },
    {
        name = 'meth_baggy',
        label = 'Bolsita de Metanfetamina',
        description = 'Pequeña bolsita de cristales de meta para consumo',
        weight = 5,
        price = 0,
        sellPrice = 120,
        legal = false,
        usable = true,
        effects = { stress = -25, high = 90, stamina = 80, health = -10, addiction = 60, overdose = 25, duration = 180 }
    },

    -- ============================================================================
    -- DROGAS BASE - HEROINA
    -- ============================================================================
    {
        name = 'heroin_brick',
        label = 'Ladrillo de Heroina',
        description = 'Paquete de heroina pura sin procesar, extremadamente peligroso',
        weight = 500,
        price = 0,
        sellPrice = 4000,
        legal = false,
        usable = false
    },
    {
        name = 'heroin_baggy',
        label = 'Bolsita de Heroina',
        description = 'Pequeña dosis de heroina lista para consumo',
        weight = 5,
        price = 0,
        sellPrice = 180,
        legal = false,
        usable = true,
        effects = { stress = -80, high = 100, stamina = -50, health = -20, addiction = 85, overdose = 40, duration = 240 }
    },

    -- ============================================================================
    -- DROGAS BASE - PASTILLAS Y SINTETICAS
    -- ============================================================================
    {
        name = 'oxy',
        label = 'Oxicodona',
        description = 'Pastillas de oxicodona, analgesico opioide de prescripcion',
        weight = 2,
        price = 0,
        sellPrice = 50,
        legal = false,
        usable = true,
        effects = { stress = -50, high = 60, health = 20, stamina = -20, addiction = 50, overdose = 20, duration = 300 }
    },
    {
        name = 'xanax',
        label = 'Xanax',
        description = 'Pastillas de alprazolam, benzodiazepina con efecto sedante',
        weight = 2,
        price = 0,
        sellPrice = 40,
        legal = false,
        usable = true,
        effects = { stress = -70, high = 40, stamina = -30, addiction = 45, overdose = 15, duration = 240 }
    },
    {
        name = 'ecstasy',
        label = 'Extasis',
        description = 'Pastillas de MDMA con diversos diseños y colores',
        weight = 3,
        price = 0,
        sellPrice = 60,
        legal = false,
        usable = true,
        effects = { stress = -60, high = 85, stamina = 40, health = -5, addiction = 35, overdose = 10, duration = 180 }
    },
    {
        name = 'lsd',
        label = 'LSD',
        description = 'Papel secante impregnado con acido lisergico, provoca alucinaciones',
        weight = 1,
        price = 0,
        sellPrice = 80,
        legal = false,
        usable = true,
        effects = { stress = -40, high = 95, stamina = 20, addiction = 15, overdose = 5, duration = 480 }
    },
    {
        name = 'shrooms',
        label = 'Hongos Alucinogenos',
        description = 'Hongos psilocybe con propiedades alucinogenas naturales',
        weight = 20,
        price = 0,
        sellPrice = 70,
        legal = false,
        usable = true,
        effects = { stress = -50, high = 80, stamina = 10, addiction = 10, overdose = 3, duration = 360 }
    },
    {
        name = 'pcp',
        label = 'PCP',
        description = 'Polvo de angel, disociativo extremadamente potente',
        weight = 5,
        price = 0,
        sellPrice = 90,
        legal = false,
        usable = true,
        effects = { stress = -30, high = 100, stamina = 100, health = -25, armor = 30, addiction = 55, overdose = 35, duration = 120 }
    },
    {
        name = 'ketamine',
        label = 'Ketamina',
        description = 'Anestesico disociativo usado como droga recreativa',
        weight = 10,
        price = 0,
        sellPrice = 75,
        legal = false,
        usable = true,
        effects = { stress = -45, high = 70, stamina = -40, health = 10, addiction = 30, overdose = 12, duration = 150 }
    },
    {
        name = 'adderall',
        label = 'Adderall',
        description = 'Anfetaminas de prescripcion, aumentan la concentracion y energia',
        weight = 2,
        price = 0,
        sellPrice = 45,
        legal = false,
        usable = true,
        effects = { stress = -20, high = 30, stamina = 60, addiction = 40, overdose = 8, duration = 240 }
    },
    {
        name = 'fentanyl',
        label = 'Fentanilo',
        description = 'Opioide sintetico extremadamente potente y mortal',
        weight = 1,
        price = 0,
        sellPrice = 200,
        legal = false,
        usable = true,
        effects = { stress = -90, high = 100, stamina = -80, health = -40, addiction = 95, overdose = 70, duration = 60 }
    },

    -- ============================================================================
    -- INGREDIENTES - CULTIVO DE MARIHUANA
    -- ============================================================================
    {
        name = 'weed_seed',
        label = 'Semilla de Marihuana',
        description = 'Semilla feminizada lista para plantar y cultivar',
        weight = 1,
        price = 50,
        sellPrice = 30,
        legal = false,
        usable = false
    },
    {
        name = 'weed_sapling',
        label = 'Plantula de Marihuana',
        description = 'Pequeña planta de marihuana en crecimiento',
        weight = 100,
        price = 0,
        sellPrice = 50,
        legal = false,
        usable = false
    },
    {
        name = 'weed_leaf',
        label = 'Hoja de Marihuana',
        description = 'Hojas frescas de marihuana recien cosechadas',
        weight = 20,
        price = 0,
        sellPrice = 15,
        legal = false,
        usable = false
    },
    {
        name = 'weed_bud',
        label = 'Cogollo de Marihuana',
        description = 'Cogollo de marihuana seco y curado, listo para procesar',
        weight = 10,
        price = 0,
        sellPrice = 40,
        legal = false,
        usable = false
    },
    {
        name = 'fertilizer',
        label = 'Fertilizante',
        description = 'Fertilizante especial para cultivo de plantas',
        weight = 500,
        price = 25,
        sellPrice = 15,
        legal = true,
        usable = false
    },
    {
        name = 'grow_light',
        label = 'Lampara de Cultivo',
        description = 'Lampara LED de espectro completo para cultivo interior',
        weight = 2000,
        price = 200,
        sellPrice = 150,
        legal = true,
        usable = false
    },

    -- ============================================================================
    -- INGREDIENTES - PRODUCCION DE COCAINA
    -- ============================================================================
    {
        name = 'coca_leaf',
        label = 'Hoja de Coca',
        description = 'Hojas de coca frescas importadas, materia prima para cocaina',
        weight = 50,
        price = 0,
        sellPrice = 25,
        legal = false,
        usable = false
    },
    {
        name = 'coca_paste',
        label = 'Pasta Base de Coca',
        description = 'Pasta de coca parcialmente procesada',
        weight = 100,
        price = 0,
        sellPrice = 200,
        legal = false,
        usable = false
    },
    {
        name = 'gasoline',
        label = 'Gasolina',
        description = 'Combustible usado en el procesamiento de coca',
        weight = 1000,
        price = 15,
        sellPrice = 10,
        legal = true,
        usable = false
    },
    {
        name = 'acetone',
        label = 'Acetona',
        description = 'Solvente quimico usado en la purificacion de drogas',
        weight = 500,
        price = 20,
        sellPrice = 12,
        legal = true,
        usable = false
    },
    {
        name = 'ether',
        label = 'Eter',
        description = 'Solvente volatil usado en la produccion de cocaina',
        weight = 500,
        price = 50,
        sellPrice = 35,
        legal = false,
        usable = false
    },
    {
        name = 'baking_soda',
        label = 'Bicarbonato de Sodio',
        description = 'Usado para convertir cocaina en crack',
        weight = 200,
        price = 5,
        sellPrice = 3,
        legal = true,
        usable = false
    },

    -- ============================================================================
    -- INGREDIENTES - PRODUCCION DE METANFETAMINA
    -- ============================================================================
    {
        name = 'pseudoephedrine',
        label = 'Pseudoefedrina',
        description = 'Descongestionante usado como precursor de metanfetamina',
        weight = 50,
        price = 30,
        sellPrice = 20,
        legal = false,
        usable = false
    },
    {
        name = 'ephedrine',
        label = 'Efedrina',
        description = 'Precursor quimico controlado para produccion de meta',
        weight = 50,
        price = 100,
        sellPrice = 80,
        legal = false,
        usable = false
    },
    {
        name = 'lithium',
        label = 'Litio',
        description = 'Metal alcalino extraido de baterias, usado en sintesis',
        weight = 100,
        price = 40,
        sellPrice = 30,
        legal = true,
        usable = false
    },
    {
        name = 'red_phosphorus',
        label = 'Fosforo Rojo',
        description = 'Compuesto quimico usado en la produccion de metanfetamina',
        weight = 100,
        price = 60,
        sellPrice = 45,
        legal = false,
        usable = false
    },
    {
        name = 'iodine',
        label = 'Yodo',
        description = 'Elemento quimico usado como catalizador en sintesis',
        weight = 100,
        price = 45,
        sellPrice = 35,
        legal = true,
        usable = false
    },
    {
        name = 'ammonia',
        label = 'Amoniaco',
        description = 'Compuesto quimico usado en varios procesos de sintesis',
        weight = 500,
        price = 15,
        sellPrice = 10,
        legal = true,
        usable = false
    },
    {
        name = 'sulfuric_acid',
        label = 'Acido Sulfurico',
        description = 'Acido corrosivo usado en procesos quimicos',
        weight = 500,
        price = 35,
        sellPrice = 25,
        legal = true,
        usable = false
    },
    {
        name = 'hydrochloric_acid',
        label = 'Acido Clorhidrico',
        description = 'Acido usado en la conversion de base a sal',
        weight = 500,
        price = 30,
        sellPrice = 20,
        legal = true,
        usable = false
    },

    -- ============================================================================
    -- INGREDIENTES - PRODUCCION DE HEROINA
    -- ============================================================================
    {
        name = 'opium_poppy',
        label = 'Amapola de Opio',
        description = 'Flores de amapola usadas para extraer opio',
        weight = 30,
        price = 0,
        sellPrice = 20,
        legal = false,
        usable = false
    },
    {
        name = 'raw_opium',
        label = 'Opio Crudo',
        description = 'Latex de amapola sin procesar',
        weight = 50,
        price = 0,
        sellPrice = 100,
        legal = false,
        usable = false
    },
    {
        name = 'morphine_base',
        label = 'Base de Morfina',
        description = 'Morfina extraida del opio, precursor de heroina',
        weight = 50,
        price = 0,
        sellPrice = 300,
        legal = false,
        usable = false
    },
    {
        name = 'acetic_anhydride',
        label = 'Anhidrido Acetico',
        description = 'Compuesto quimico necesario para producir heroina',
        weight = 500,
        price = 150,
        sellPrice = 120,
        legal = false,
        usable = false
    },

    -- ============================================================================
    -- EQUIPAMIENTO - PROCESAMIENTO Y EMPAQUETADO
    -- ============================================================================
    {
        name = 'empty_baggy',
        label = 'Bolsita Vacia',
        description = 'Pequeña bolsa de plastico con cierre hermetico',
        weight = 1,
        price = 1,
        sellPrice = 0,
        legal = true,
        usable = false
    },
    {
        name = 'empty_bag',
        label = 'Bolsa Vacia Grande',
        description = 'Bolsa de plastico grande para almacenamiento',
        weight = 5,
        price = 2,
        sellPrice = 1,
        legal = true,
        usable = false
    },
    {
        name = 'rolling_paper',
        label = 'Papel de Liar',
        description = 'Papel fino especial para liar cigarros',
        weight = 2,
        price = 3,
        sellPrice = 2,
        legal = true,
        usable = false
    },
    {
        name = 'cigar_wrap',
        label = 'Envoltura de Puro',
        description = 'Hoja de tabaco para envolver blunts',
        weight = 5,
        price = 5,
        sellPrice = 3,
        legal = true,
        usable = false
    },
    {
        name = 'grinder',
        label = 'Grinder',
        description = 'Moledor para triturar hierba finamente',
        weight = 100,
        price = 25,
        sellPrice = 15,
        legal = true,
        usable = false
    },
    {
        name = 'scale',
        label = 'Bascula de Precision',
        description = 'Bascula digital de alta precision para pesar sustancias',
        weight = 200,
        price = 80,
        sellPrice = 50,
        legal = true,
        usable = false
    },
    {
        name = 'cutting_agent',
        label = 'Agente de Corte',
        description = 'Sustancia usada para diluir drogas y aumentar volumen',
        weight = 100,
        price = 20,
        sellPrice = 15,
        legal = true,
        usable = false
    },
    {
        name = 'press_mold',
        label = 'Molde de Prensa',
        description = 'Molde para comprimir sustancias en ladrillos',
        weight = 500,
        price = 150,
        sellPrice = 100,
        legal = true,
        usable = false
    },
    {
        name = 'pill_press',
        label = 'Prensa de Pastillas',
        description = 'Maquina para fabricar pastillas con sellos personalizados',
        weight = 3000,
        price = 500,
        sellPrice = 350,
        legal = false,
        usable = false
    },

    -- ============================================================================
    -- EQUIPAMIENTO - LABORATORIO
    -- ============================================================================
    {
        name = 'lab_equipment',
        label = 'Equipo de Laboratorio',
        description = 'Set completo de cristaleria y equipo para sintesis quimica',
        weight = 5000,
        price = 1000,
        sellPrice = 700,
        legal = true,
        usable = false
    },
    {
        name = 'beaker_set',
        label = 'Set de Vasos de Precipitado',
        description = 'Conjunto de vasos de vidrio para mezclar quimicos',
        weight = 500,
        price = 100,
        sellPrice = 70,
        legal = true,
        usable = false
    },
    {
        name = 'bunsen_burner',
        label = 'Mechero Bunsen',
        description = 'Quemador de gas para calentar sustancias',
        weight = 300,
        price = 50,
        sellPrice = 35,
        legal = true,
        usable = false
    },
    {
        name = 'condenser',
        label = 'Condensador',
        description = 'Tubo refrigerante para procesos de destilacion',
        weight = 400,
        price = 80,
        sellPrice = 55,
        legal = true,
        usable = false
    },
    {
        name = 'filter_flask',
        label = 'Matraz de Filtracion',
        description = 'Matraz especial para filtrar sustancias',
        weight = 300,
        price = 60,
        sellPrice = 40,
        legal = true,
        usable = false
    },
    {
        name = 'heating_mantle',
        label = 'Manto Calefactor',
        description = 'Dispositivo electrico para calentar matraces',
        weight = 1000,
        price = 200,
        sellPrice = 140,
        legal = true,
        usable = false
    },
    {
        name = 'respirator',
        label = 'Respirador',
        description = 'Mascara con filtros para proteccion contra gases toxicos',
        weight = 300,
        price = 75,
        sellPrice = 50,
        legal = true,
        usable = false
    },
    {
        name = 'hazmat_suit',
        label = 'Traje Hazmat',
        description = 'Traje de proteccion completa contra materiales peligrosos',
        weight = 2000,
        price = 300,
        sellPrice = 200,
        legal = true,
        usable = false
    },
    {
        name = 'chemical_gloves',
        label = 'Guantes Quimicos',
        description = 'Guantes resistentes a acidos y solventes',
        weight = 100,
        price = 25,
        sellPrice = 15,
        legal = true,
        usable = false
    },

    -- ============================================================================
    -- EQUIPAMIENTO - CONSUMO
    -- ============================================================================
    {
        name = 'pipe_glass',
        label = 'Pipa de Cristal',
        description = 'Pipa de vidrio para fumar sustancias',
        weight = 50,
        price = 30,
        sellPrice = 20,
        legal = true,
        usable = false
    },
    {
        name = 'bong',
        label = 'Bong',
        description = 'Pipa de agua para filtrar el humo',
        weight = 500,
        price = 80,
        sellPrice = 55,
        legal = true,
        usable = false
    },
    {
        name = 'crack_pipe',
        label = 'Pipa de Crack',
        description = 'Pipa especial para fumar crack',
        weight = 30,
        price = 15,
        sellPrice = 10,
        legal = false,
        usable = false
    },
    {
        name = 'syringe',
        label = 'Jeringa',
        description = 'Jeringa esteril para inyeccion',
        weight = 10,
        price = 5,
        sellPrice = 2,
        legal = true,
        usable = false
    },
    {
        name = 'tourniquet',
        label = 'Torniquete',
        description = 'Banda elastica para encontrar venas',
        weight = 20,
        price = 3,
        sellPrice = 1,
        legal = true,
        usable = false
    },
    {
        name = 'spoon_cooker',
        label = 'Cuchara de Cocina',
        description = 'Cuchara metalica para calentar sustancias',
        weight = 30,
        price = 2,
        sellPrice = 1,
        legal = true,
        usable = false
    },
    {
        name = 'lighter',
        label = 'Encendedor',
        description = 'Encendedor de butano recargable',
        weight = 30,
        price = 3,
        sellPrice = 2,
        legal = true,
        usable = false
    },
    {
        name = 'razor_blade',
        label = 'Hoja de Afeitar',
        description = 'Cuchilla afilada para preparar lineas',
        weight = 5,
        price = 2,
        sellPrice = 1,
        legal = true,
        usable = false
    },
    {
        name = 'straw',
        label = 'Pajita',
        description = 'Tubo para inhalar sustancias en polvo',
        weight = 2,
        price = 1,
        sellPrice = 0,
        legal = true,
        usable = false
    },
    {
        name = 'mirror',
        label = 'Espejo Pequeño',
        description = 'Superficie reflectante para preparar lineas',
        weight = 100,
        price = 10,
        sellPrice = 5,
        legal = true,
        usable = false
    },

    -- ============================================================================
    -- ITEMS ESPECIALES - CONTRABANDO
    -- ============================================================================
    {
        name = 'drug_stash',
        label = 'Escondite de Drogas',
        description = 'Compartimento secreto para ocultar sustancias',
        weight = 500,
        price = 200,
        sellPrice = 150,
        legal = false,
        usable = false
    },
    {
        name = 'vacuum_sealer',
        label = 'Selladora al Vacio',
        description = 'Maquina para sellar bolsas hermeticamente',
        weight = 2000,
        price = 150,
        sellPrice = 100,
        legal = true,
        usable = false
    },
    {
        name = 'drug_test_kit',
        label = 'Kit de Prueba de Drogas',
        description = 'Kit para verificar la pureza de sustancias',
        weight = 100,
        price = 50,
        sellPrice = 35,
        legal = true,
        usable = false
    },
    {
        name = 'burner_phone',
        label = 'Telefono Desechable',
        description = 'Telefono prepago sin rastreo para operaciones',
        weight = 100,
        price = 50,
        sellPrice = 30,
        legal = true,
        usable = false
    },
    {
        name = 'money_counter',
        label = 'Contadora de Billetes',
        description = 'Maquina automatica para contar dinero rapidamente',
        weight = 3000,
        price = 400,
        sellPrice = 280,
        legal = true,
        usable = false
    },

    -- ============================================================================
    -- ANTIDOTOS Y TRATAMIENTO
    -- ============================================================================
    {
        name = 'narcan',
        label = 'Narcan',
        description = 'Naloxona, revierte sobredosis de opioides',
        weight = 20,
        price = 100,
        sellPrice = 80,
        legal = true,
        usable = true,
        effects = { health = 30, high = -100, overdose = -100, duration = 60 }
    },
    {
        name = 'detox_pills',
        label = 'Pastillas Desintoxicantes',
        description = 'Suplementos para limpiar el sistema de toxinas',
        weight = 30,
        price = 50,
        sellPrice = 35,
        legal = true,
        usable = true,
        effects = { health = 10, high = -50, addiction = -20, duration = 300 }
    },
    {
        name = 'activated_charcoal',
        label = 'Carbon Activado',
        description = 'Absorbente usado para tratar intoxicaciones',
        weight = 100,
        price = 20,
        sellPrice = 12,
        legal = true,
        usable = true,
        effects = { health = 5, high = -30, overdose = -30, duration = 120 }
    }
}
