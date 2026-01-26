--[[
    AIT-QB | Catálogo de Materiales
    Materiales de crafteo, metales, componentes electrónicos y recursos
    Todos los items en español
]]

return {
    -- ============================================================================
    -- METALES
    -- Materiales metálicos básicos y procesados
    -- ============================================================================
    {
        name = 'iron',
        label = 'Hierro',
        description = 'Lingote de hierro puro, material básico para la fabricación',
        weight = 500,
        price = 50,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'steel',
        label = 'Acero',
        description = 'Aleación de hierro y carbono, resistente y versátil',
        weight = 600,
        price = 120,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'copper',
        label = 'Cobre',
        description = 'Metal conductor de electricidad, de color rojizo',
        weight = 400,
        price = 80,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'aluminum',
        label = 'Aluminio',
        description = 'Metal ligero y resistente a la corrosión',
        weight = 200,
        price = 70,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'gold',
        label = 'Oro',
        description = 'Metal precioso de alta conductividad',
        weight = 800,
        price = 2500,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'silver',
        label = 'Plata',
        description = 'Metal precioso con propiedades antimicrobianas',
        weight = 500,
        price = 1200,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'titanium',
        label = 'Titanio',
        description = 'Metal extremadamente resistente y ligero',
        weight = 300,
        price = 3000,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'platinum',
        label = 'Platino',
        description = 'Metal noble de gran valor y resistencia',
        weight = 900,
        price = 5000,
        stackable = true,
        rarity = 'epic'
    },
    {
        name = 'lead',
        label = 'Plomo',
        description = 'Metal pesado utilizado en protección contra radiación',
        weight = 1000,
        price = 40,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'zinc',
        label = 'Zinc',
        description = 'Metal utilizado en galvanización y aleaciones',
        weight = 400,
        price = 60,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'tin',
        label = 'Estaño',
        description = 'Metal blando utilizado en soldaduras',
        weight = 350,
        price = 55,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'bronze',
        label = 'Bronce',
        description = 'Aleación de cobre y estaño, resistente a la corrosión',
        weight = 550,
        price = 100,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'tungsten',
        label = 'Tungsteno',
        description = 'Metal con el punto de fusión más alto conocido',
        weight = 800,
        price = 2000,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'nickel',
        label = 'Níquel',
        description = 'Metal plateado utilizado en aleaciones especiales',
        weight = 450,
        price = 90,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'chromium',
        label = 'Cromo',
        description = 'Metal brillante usado para revestimientos protectores',
        weight = 400,
        price = 150,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'scrap_metal',
        label = 'Chatarra',
        description = 'Restos de metal reciclable de diversas fuentes',
        weight = 300,
        price = 15,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'metal_sheet',
        label = 'Lámina de Metal',
        description = 'Plancha de metal lista para moldear',
        weight = 400,
        price = 80,
        stackable = true,
        rarity = 'common'
    },

    -- ============================================================================
    -- COMPONENTES ELECTRÓNICOS
    -- Piezas y componentes para fabricación de dispositivos
    -- ============================================================================
    {
        name = 'electronics',
        label = 'Electrónica',
        description = 'Componentes electrónicos variados para fabricación',
        weight = 100,
        price = 200,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'circuit_board',
        label = 'Placa de Circuito',
        description = 'PCB con circuitos integrados y componentes',
        weight = 50,
        price = 350,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'wires',
        label = 'Cables',
        description = 'Cables de cobre aislados para conexiones eléctricas',
        weight = 100,
        price = 30,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'capacitor',
        label = 'Condensador',
        description = 'Componente que almacena carga eléctrica',
        weight = 20,
        price = 50,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'resistor',
        label = 'Resistencia',
        description = 'Componente que limita el flujo de corriente',
        weight = 10,
        price = 20,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'transistor',
        label = 'Transistor',
        description = 'Semiconductor para amplificación de señales',
        weight = 10,
        price = 45,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'microchip',
        label = 'Microchip',
        description = 'Circuito integrado miniaturizado de alta tecnología',
        weight = 5,
        price = 500,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'processor',
        label = 'Procesador',
        description = 'Unidad de procesamiento central de computadora',
        weight = 30,
        price = 1500,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'memory_chip',
        label = 'Chip de Memoria',
        description = 'Módulo de memoria RAM para almacenamiento temporal',
        weight = 20,
        price = 400,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'antenna',
        label = 'Antena',
        description = 'Dispositivo para transmisión y recepción de señales',
        weight = 150,
        price = 250,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'battery_cell',
        label = 'Celda de Batería',
        description = 'Celda individual de litio para baterías',
        weight = 100,
        price = 120,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'led',
        label = 'LED',
        description = 'Diodo emisor de luz de bajo consumo',
        weight = 5,
        price = 15,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'sensor',
        label = 'Sensor',
        description = 'Dispositivo de detección electrónica multiusos',
        weight = 50,
        price = 300,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'motor_small',
        label = 'Motor Pequeño',
        description = 'Motor eléctrico compacto de baja potencia',
        weight = 200,
        price = 180,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'relay',
        label = 'Relé',
        description = 'Interruptor electromagnético controlado eléctricamente',
        weight = 30,
        price = 40,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'transformer',
        label = 'Transformador',
        description = 'Dispositivo para cambiar el voltaje de corriente alterna',
        weight = 500,
        price = 150,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'solar_cell',
        label = 'Celda Solar',
        description = 'Panel fotovoltaico que convierte luz en electricidad',
        weight = 100,
        price = 600,
        stackable = true,
        rarity = 'uncommon'
    },

    -- ============================================================================
    -- MATERIALES DE CRAFTEO
    -- Recursos básicos para fabricación de objetos
    -- ============================================================================
    {
        name = 'cloth',
        label = 'Tela',
        description = 'Tejido de algodón para confección',
        weight = 50,
        price = 25,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'leather',
        label = 'Cuero',
        description = 'Piel curtida de alta calidad',
        weight = 150,
        price = 80,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'rubber',
        label = 'Goma',
        description = 'Material elástico e impermeable',
        weight = 100,
        price = 40,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'glass',
        label = 'Vidrio',
        description = 'Material transparente y frágil',
        weight = 200,
        price = 35,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'plastic',
        label = 'Plástico',
        description = 'Polímero sintético moldeable',
        weight = 80,
        price = 20,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'wood',
        label = 'Madera',
        description = 'Tablón de madera tratada',
        weight = 300,
        price = 30,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'carbon_fiber',
        label = 'Fibra de Carbono',
        description = 'Material compuesto ultraligero y resistente',
        weight = 50,
        price = 800,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'kevlar',
        label = 'Kevlar',
        description = 'Fibra sintética de alta resistencia balística',
        weight = 100,
        price = 1000,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'ceramic',
        label = 'Cerámica',
        description = 'Material cerámico de alta dureza',
        weight = 250,
        price = 150,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'concrete',
        label = 'Cemento',
        description = 'Mezcla de cemento lista para usar',
        weight = 1000,
        price = 25,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'fiberglass',
        label = 'Fibra de Vidrio',
        description = 'Material compuesto resistente y ligero',
        weight = 150,
        price = 200,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'resin',
        label = 'Resina',
        description = 'Compuesto orgánico para moldes y sellados',
        weight = 200,
        price = 100,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'adhesive',
        label = 'Adhesivo',
        description = 'Pegamento industrial de alta resistencia',
        weight = 100,
        price = 45,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'foam',
        label = 'Espuma',
        description = 'Material acolchado para protección',
        weight = 30,
        price = 20,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'rope',
        label = 'Cuerda',
        description = 'Cuerda resistente de nylon trenzado',
        weight = 150,
        price = 35,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'tape',
        label = 'Cinta Adhesiva',
        description = 'Cinta multiusos de alta adherencia',
        weight = 50,
        price = 15,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'fabric_synthetic',
        label = 'Tela Sintética',
        description = 'Tejido de fibras sintéticas resistentes',
        weight = 60,
        price = 50,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'velcro',
        label = 'Velcro',
        description = 'Sistema de cierre de gancho y bucle',
        weight = 20,
        price = 25,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'paint',
        label = 'Pintura',
        description = 'Bote de pintura de secado rápido',
        weight = 300,
        price = 40,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'oil',
        label = 'Aceite Lubricante',
        description = 'Lubricante industrial multiusos',
        weight = 250,
        price = 35,
        stackable = true,
        rarity = 'common'
    },

    -- ============================================================================
    -- QUÍMICOS Y COMPUESTOS
    -- Sustancias químicas para procesos industriales
    -- ============================================================================
    {
        name = 'acid',
        label = 'Ácido',
        description = 'Compuesto ácido para procesos químicos',
        weight = 200,
        price = 150,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'sulfur',
        label = 'Azufre',
        description = 'Elemento químico utilizado en fabricación',
        weight = 150,
        price = 80,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'charcoal',
        label = 'Carbón Vegetal',
        description = 'Carbón para filtración y combustión',
        weight = 100,
        price = 25,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'gunpowder',
        label = 'Pólvora',
        description = 'Mezcla explosiva para munición',
        weight = 50,
        price = 200,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'thermite',
        label = 'Termita',
        description = 'Mezcla pirotécnica de alta temperatura',
        weight = 100,
        price = 500,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'fertilizer',
        label = 'Fertilizante',
        description = 'Compuesto químico para agricultura',
        weight = 500,
        price = 30,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'solvent',
        label = 'Disolvente',
        description = 'Líquido para disolver sustancias',
        weight = 200,
        price = 60,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'epoxy',
        label = 'Epoxi',
        description = 'Resina epoxi de dos componentes',
        weight = 150,
        price = 120,
        stackable = true,
        rarity = 'common'
    },

    -- ============================================================================
    -- MATERIALES ESPECIALES
    -- Recursos raros y de alta tecnología
    -- ============================================================================
    {
        name = 'quantum_core',
        label = 'Núcleo Cuántico',
        description = 'Componente de tecnología cuántica experimental',
        weight = 50,
        price = 15000,
        stackable = true,
        rarity = 'legendary'
    },
    {
        name = 'nanofiber',
        label = 'Nanofibra',
        description = 'Material de nanotecnología avanzada',
        weight = 10,
        price = 5000,
        stackable = true,
        rarity = 'epic'
    },
    {
        name = 'superconductor',
        label = 'Superconductor',
        description = 'Material de conductividad perfecta',
        weight = 100,
        price = 8000,
        stackable = true,
        rarity = 'epic'
    },
    {
        name = 'graphene',
        label = 'Grafeno',
        description = 'Lámina de carbono de un átomo de espesor',
        weight = 5,
        price = 3000,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'biocomposite',
        label = 'Biocompuesto',
        description = 'Material orgánico-sintético biodegradable',
        weight = 80,
        price = 1200,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'rare_earth',
        label = 'Tierra Rara',
        description = 'Elementos de tierras raras para electrónica',
        weight = 50,
        price = 2000,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'uranium',
        label = 'Uranio',
        description = 'Material radiactivo de uso restringido',
        weight = 1000,
        price = 25000,
        stackable = true,
        rarity = 'legendary'
    },
    {
        name = 'lithium',
        label = 'Litio',
        description = 'Metal alcalino para baterías de alta capacidad',
        weight = 100,
        price = 500,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'cobalt',
        label = 'Cobalto',
        description = 'Metal para aleaciones magnéticas y baterías',
        weight = 200,
        price = 800,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'neodymium',
        label = 'Neodimio',
        description = 'Metal para imanes permanentes de alta potencia',
        weight = 150,
        price = 1500,
        stackable = true,
        rarity = 'rare'
    },

    -- ============================================================================
    -- PIEZAS DE VEHÍCULOS
    -- Componentes para reparación y modificación de vehículos
    -- ============================================================================
    {
        name = 'engine_part',
        label = 'Pieza de Motor',
        description = 'Componente genérico para motores de vehículos',
        weight = 500,
        price = 300,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'transmission_part',
        label = 'Pieza de Transmisión',
        description = 'Componente para cajas de cambios',
        weight = 400,
        price = 250,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'brake_pad',
        label = 'Pastilla de Freno',
        description = 'Pastilla de freno de alto rendimiento',
        weight = 100,
        price = 80,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'spark_plug',
        label = 'Bujía',
        description = 'Bujía de encendido para motores',
        weight = 50,
        price = 40,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'air_filter',
        label = 'Filtro de Aire',
        description = 'Filtro para sistema de admisión',
        weight = 100,
        price = 50,
        stackable = true,
        rarity = 'common'
    },
    {
        name = 'fuel_pump',
        label = 'Bomba de Combustible',
        description = 'Bomba eléctrica para suministro de gasolina',
        weight = 300,
        price = 200,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'radiator',
        label = 'Radiador',
        description = 'Sistema de refrigeración para motor',
        weight = 800,
        price = 350,
        stackable = true,
        rarity = 'uncommon'
    },
    {
        name = 'turbo',
        label = 'Turbo',
        description = 'Turbocompresor para aumento de potencia',
        weight = 600,
        price = 2500,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'nitrous_tank',
        label = 'Tanque de Nitroso',
        description = 'Botella de óxido nitroso para boost',
        weight = 1000,
        price = 1500,
        stackable = true,
        rarity = 'rare'
    },
    {
        name = 'exhaust_pipe',
        label = 'Tubo de Escape',
        description = 'Sistema de escape de alto flujo',
        weight = 400,
        price = 180,
        stackable = true,
        rarity = 'common'
    }
}
