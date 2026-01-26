--[[
    AIT-QB Framework - Catalogo de Consumibles
    Sistema de items consumibles: comida, bebidas y medicinas

    Propiedades de cada item:
    - name: identificador unico (string)
    - label: nombre visible en español (string)
    - description: descripcion del item (string)
    - weight: peso en gramos (number)
    - price: precio base en dolares (number)
    - usable: si el item es usable (boolean)
    - effects: tabla de efectos al consumir
        - hunger: puntos de hambre restaurados (0-100)
        - thirst: puntos de sed restaurados (0-100)
        - health: puntos de vida restaurados (0-100)
        - armor: puntos de armadura añadidos (0-100)
        - stress: puntos de estres reducidos (negativo) o añadidos (positivo)
        - stamina: puntos de estamina restaurados (0-100)
        - drunk: nivel de embriaguez añadido (0-100)
]]

return {
    -- ============================================================================
    -- COMIDA - COMIDA RAPIDA
    -- ============================================================================
    {
        name = 'burger',
        label = 'Hamburguesa',
        description = 'Una jugosa hamburguesa con carne, lechuga, tomate y queso',
        weight = 220,
        price = 8,
        usable = true,
        effects = { hunger = 30, thirst = -5, stress = -3 }
    },
    {
        name = 'cheese_burger',
        label = 'Hamburguesa con Queso',
        description = 'Hamburguesa con doble queso derretido',
        weight = 250,
        price = 10,
        usable = true,
        effects = { hunger = 35, thirst = -5, stress = -4 }
    },
    {
        name = 'double_burger',
        label = 'Hamburguesa Doble',
        description = 'Hamburguesa con doble carne para los mas hambrientos',
        weight = 350,
        price = 14,
        usable = true,
        effects = { hunger = 50, thirst = -8, stress = -5 }
    },
    {
        name = 'pizza_slice',
        label = 'Porcion de Pizza',
        description = 'Una deliciosa porcion de pizza con queso y pepperoni',
        weight = 150,
        price = 5,
        usable = true,
        effects = { hunger = 20, thirst = -3, stress = -2 }
    },
    {
        name = 'pizza',
        label = 'Pizza Completa',
        description = 'Pizza entera recien horneada con tus ingredientes favoritos',
        weight = 800,
        price = 18,
        usable = true,
        effects = { hunger = 70, thirst = -10, stress = -8 }
    },
    {
        name = 'hotdog',
        label = 'Perrito Caliente',
        description = 'Clasico perrito caliente con mostaza y ketchup',
        weight = 180,
        price = 4,
        usable = true,
        effects = { hunger = 22, thirst = -4, stress = -2 }
    },
    {
        name = 'taco',
        label = 'Taco',
        description = 'Autentico taco mexicano con carne, cebolla y cilantro',
        weight = 120,
        price = 4,
        usable = true,
        effects = { hunger = 18, thirst = -3, stress = -2 }
    },
    {
        name = 'burrito',
        label = 'Burrito',
        description = 'Burrito grande relleno de carne, frijoles, arroz y queso',
        weight = 350,
        price = 9,
        usable = true,
        effects = { hunger = 45, thirst = -6, stress = -4 }
    },
    {
        name = 'nachos',
        label = 'Nachos',
        description = 'Nachos crujientes con queso, jalapeños y guacamole',
        weight = 200,
        price = 6,
        usable = true,
        effects = { hunger = 25, thirst = -8, stress = -3 }
    },
    {
        name = 'quesadilla',
        label = 'Quesadilla',
        description = 'Tortilla de harina rellena de queso fundido',
        weight = 180,
        price = 5,
        usable = true,
        effects = { hunger = 22, thirst = -4, stress = -2 }
    },
    {
        name = 'sandwich',
        label = 'Sandwich',
        description = 'Sandwich fresco con jamon, queso, lechuga y tomate',
        weight = 200,
        price = 6,
        usable = true,
        effects = { hunger = 28, thirst = -3, stress = -2 }
    },
    {
        name = 'club_sandwich',
        label = 'Club Sandwich',
        description = 'Sandwich de tres pisos con pollo, bacon y huevo',
        weight = 280,
        price = 10,
        usable = true,
        effects = { hunger = 40, thirst = -5, stress = -4 }
    },
    {
        name = 'wrap',
        label = 'Wrap',
        description = 'Tortilla enrollada con pollo a la plancha y verduras',
        weight = 220,
        price = 7,
        usable = true,
        effects = { hunger = 30, thirst = -3, stress = -3 }
    },
    {
        name = 'chicken_nuggets',
        label = 'Nuggets de Pollo',
        description = 'Crujientes nuggets de pollo empanizados',
        weight = 150,
        price = 5,
        usable = true,
        effects = { hunger = 20, thirst = -5, stress = -2 }
    },
    {
        name = 'french_fries',
        label = 'Papas Fritas',
        description = 'Papas fritas doradas y crujientes con sal',
        weight = 120,
        price = 3,
        usable = true,
        effects = { hunger = 15, thirst = -8, stress = -1 }
    },
    {
        name = 'onion_rings',
        label = 'Aros de Cebolla',
        description = 'Aros de cebolla empanizados y fritos',
        weight = 130,
        price = 4,
        usable = true,
        effects = { hunger = 15, thirst = -6, stress = -1 }
    },
    {
        name = 'fried_chicken',
        label = 'Pollo Frito',
        description = 'Crujiente pieza de pollo frito estilo sureño',
        weight = 250,
        price = 8,
        usable = true,
        effects = { hunger = 35, thirst = -6, stress = -4 }
    },
    {
        name = 'chicken_wings',
        label = 'Alitas de Pollo',
        description = 'Alitas de pollo picantes con salsa buffalo',
        weight = 200,
        price = 7,
        usable = true,
        effects = { hunger = 25, thirst = -10, stress = -3 }
    },
    {
        name = 'kebab',
        label = 'Kebab',
        description = 'Delicioso kebab con carne, verduras y salsa especial',
        weight = 300,
        price = 8,
        usable = true,
        effects = { hunger = 40, thirst = -5, stress = -4 }
    },
    {
        name = 'gyros',
        label = 'Gyros',
        description = 'Gyros griego con carne de cordero y salsa tzatziki',
        weight = 280,
        price = 9,
        usable = true,
        effects = { hunger = 38, thirst = -4, stress = -4 }
    },

    -- ============================================================================
    -- COMIDA - COMIDA CASERA Y RESTAURANTE
    -- ============================================================================
    {
        name = 'steak',
        label = 'Filete de Carne',
        description = 'Jugoso filete de res cocinado al punto perfecto',
        weight = 300,
        price = 25,
        usable = true,
        effects = { hunger = 55, thirst = -5, stress = -8, health = 5 }
    },
    {
        name = 'grilled_chicken',
        label = 'Pollo a la Plancha',
        description = 'Pechuga de pollo a la plancha con hierbas aromaticas',
        weight = 250,
        price = 15,
        usable = true,
        effects = { hunger = 45, thirst = -3, stress = -5, health = 3 }
    },
    {
        name = 'fish_fillet',
        label = 'Filete de Pescado',
        description = 'Filete de pescado fresco a la plancha con limon',
        weight = 220,
        price = 18,
        usable = true,
        effects = { hunger = 40, thirst = -2, stress = -6, health = 5 }
    },
    {
        name = 'spaghetti',
        label = 'Espaguetis',
        description = 'Espaguetis con salsa de tomate casera y albahaca',
        weight = 300,
        price = 12,
        usable = true,
        effects = { hunger = 45, thirst = -5, stress = -5 }
    },
    {
        name = 'lasagna',
        label = 'Lasaña',
        description = 'Lasaña tradicional con carne, bechamel y queso gratinado',
        weight = 350,
        price = 16,
        usable = true,
        effects = { hunger = 55, thirst = -6, stress = -6 }
    },
    {
        name = 'risotto',
        label = 'Risotto',
        description = 'Cremoso risotto italiano con champiñones',
        weight = 280,
        price = 14,
        usable = true,
        effects = { hunger = 42, thirst = -4, stress = -5 }
    },
    {
        name = 'paella',
        label = 'Paella',
        description = 'Autentica paella española con mariscos y azafran',
        weight = 400,
        price = 22,
        usable = true,
        effects = { hunger = 60, thirst = -8, stress = -7 }
    },
    {
        name = 'ramen',
        label = 'Ramen',
        description = 'Ramen japones con caldo de cerdo, huevo y nori',
        weight = 450,
        price = 14,
        usable = true,
        effects = { hunger = 50, thirst = 15, stress = -6 }
    },
    {
        name = 'sushi_roll',
        label = 'Roll de Sushi',
        description = 'Roll de sushi fresco con salmon y aguacate',
        weight = 180,
        price = 12,
        usable = true,
        effects = { hunger = 25, thirst = -2, stress = -4, health = 3 }
    },
    {
        name = 'sushi_platter',
        label = 'Bandeja de Sushi',
        description = 'Variedad de sushi y sashimi para compartir',
        weight = 400,
        price = 35,
        usable = true,
        effects = { hunger = 60, thirst = -5, stress = -10, health = 8 }
    },
    {
        name = 'fried_rice',
        label = 'Arroz Frito',
        description = 'Arroz frito al estilo asiatico con verduras y huevo',
        weight = 300,
        price = 8,
        usable = true,
        effects = { hunger = 40, thirst = -5, stress = -3 }
    },
    {
        name = 'noodles',
        label = 'Fideos Salteados',
        description = 'Fideos salteados con verduras y salsa de soja',
        weight = 280,
        price = 9,
        usable = true,
        effects = { hunger = 38, thirst = -4, stress = -3 }
    },
    {
        name = 'curry',
        label = 'Curry',
        description = 'Curry cremoso con pollo y arroz basmati',
        weight = 350,
        price = 13,
        usable = true,
        effects = { hunger = 48, thirst = -10, stress = -5 }
    },
    {
        name = 'soup',
        label = 'Sopa',
        description = 'Reconfortante sopa de verduras casera',
        weight = 300,
        price = 6,
        usable = true,
        effects = { hunger = 25, thirst = 20, stress = -4, health = 5 }
    },
    {
        name = 'chicken_soup',
        label = 'Sopa de Pollo',
        description = 'Sopa de pollo con fideos, perfecta para recuperarse',
        weight = 350,
        price = 8,
        usable = true,
        effects = { hunger = 30, thirst = 25, stress = -5, health = 10 }
    },
    {
        name = 'salad',
        label = 'Ensalada',
        description = 'Ensalada fresca con lechuga, tomate y aderezo',
        weight = 180,
        price = 7,
        usable = true,
        effects = { hunger = 15, thirst = 5, stress = -2, health = 5 }
    },
    {
        name = 'caesar_salad',
        label = 'Ensalada Cesar',
        description = 'Ensalada cesar con pollo, crutones y parmesano',
        weight = 250,
        price = 12,
        usable = true,
        effects = { hunger = 28, thirst = 3, stress = -4, health = 8 }
    },
    {
        name = 'omelette',
        label = 'Tortilla Francesa',
        description = 'Esponjosa tortilla francesa con queso y jamon',
        weight = 200,
        price = 8,
        usable = true,
        effects = { hunger = 30, thirst = -2, stress = -3 }
    },
    {
        name = 'scrambled_eggs',
        label = 'Huevos Revueltos',
        description = 'Cremosos huevos revueltos con mantequilla',
        weight = 150,
        price = 5,
        usable = true,
        effects = { hunger = 22, thirst = -2, stress = -2 }
    },
    {
        name = 'bacon_eggs',
        label = 'Bacon con Huevos',
        description = 'Clasico desayuno americano con bacon crujiente',
        weight = 220,
        price = 10,
        usable = true,
        effects = { hunger = 38, thirst = -5, stress = -4 }
    },
    {
        name = 'pancakes',
        label = 'Tortitas',
        description = 'Esponjosas tortitas con sirope de arce y mantequilla',
        weight = 200,
        price = 8,
        usable = true,
        effects = { hunger = 32, thirst = -8, stress = -5 }
    },
    {
        name = 'waffles',
        label = 'Gofres',
        description = 'Crujientes gofres belgas con nata y fresas',
        weight = 220,
        price = 10,
        usable = true,
        effects = { hunger = 35, thirst = -6, stress = -6 }
    },
    {
        name = 'french_toast',
        label = 'Tostadas Francesas',
        description = 'Tostadas francesas con canela y azucar glas',
        weight = 180,
        price = 9,
        usable = true,
        effects = { hunger = 28, thirst = -5, stress = -4 }
    },
    {
        name = 'cereal',
        label = 'Cereales',
        description = 'Tazon de cereales crujientes con leche fria',
        weight = 150,
        price = 4,
        usable = true,
        effects = { hunger = 20, thirst = 10, stress = -1 }
    },

    -- ============================================================================
    -- COMIDA - SNACKS Y DULCES
    -- ============================================================================
    {
        name = 'donut',
        label = 'Rosquilla',
        description = 'Dulce rosquilla glaseada con azucar',
        weight = 80,
        price = 2,
        usable = true,
        effects = { hunger = 10, stress = -3 }
    },
    {
        name = 'chocolate_donut',
        label = 'Rosquilla de Chocolate',
        description = 'Rosquilla cubierta de chocolate con virutas',
        weight = 85,
        price = 3,
        usable = true,
        effects = { hunger = 12, stress = -4 }
    },
    {
        name = 'croissant',
        label = 'Cruasan',
        description = 'Cruasan de mantequilla recien horneado',
        weight = 70,
        price = 3,
        usable = true,
        effects = { hunger = 15, thirst = -3, stress = -2 }
    },
    {
        name = 'muffin',
        label = 'Muffin',
        description = 'Esponjoso muffin de arandanos',
        weight = 90,
        price = 3,
        usable = true,
        effects = { hunger = 14, stress = -3 }
    },
    {
        name = 'chocolate_muffin',
        label = 'Muffin de Chocolate',
        description = 'Muffin de chocolate con chips de chocolate',
        weight = 95,
        price = 4,
        usable = true,
        effects = { hunger = 16, stress = -4 }
    },
    {
        name = 'cookie',
        label = 'Galleta',
        description = 'Galleta crujiente con chips de chocolate',
        weight = 30,
        price = 1,
        usable = true,
        effects = { hunger = 5, stress = -2 }
    },
    {
        name = 'brownie',
        label = 'Brownie',
        description = 'Brownie de chocolate denso y jugoso',
        weight = 80,
        price = 4,
        usable = true,
        effects = { hunger = 12, stress = -5 }
    },
    {
        name = 'cake_slice',
        label = 'Porcion de Pastel',
        description = 'Porcion de pastel de chocolate con crema',
        weight = 120,
        price = 5,
        usable = true,
        effects = { hunger = 18, stress = -6 }
    },
    {
        name = 'cheesecake',
        label = 'Tarta de Queso',
        description = 'Cremosa tarta de queso con base de galleta',
        weight = 130,
        price = 6,
        usable = true,
        effects = { hunger = 20, stress = -7 }
    },
    {
        name = 'ice_cream',
        label = 'Helado',
        description = 'Delicioso helado de vainilla con chocolate',
        weight = 100,
        price = 4,
        usable = true,
        effects = { hunger = 10, thirst = 5, stress = -5 }
    },
    {
        name = 'popsicle',
        label = 'Polo de Hielo',
        description = 'Refrescante polo de frutas',
        weight = 80,
        price = 2,
        usable = true,
        effects = { hunger = 5, thirst = 15, stress = -3 }
    },
    {
        name = 'chocolate_bar',
        label = 'Tableta de Chocolate',
        description = 'Tableta de chocolate con leche',
        weight = 100,
        price = 3,
        usable = true,
        effects = { hunger = 10, stress = -4 }
    },
    {
        name = 'candy',
        label = 'Caramelos',
        description = 'Bolsa de caramelos surtidos',
        weight = 50,
        price = 2,
        usable = true,
        effects = { hunger = 5, stress = -2 }
    },
    {
        name = 'gummy_bears',
        label = 'Ositos de Goma',
        description = 'Bolsa de ositos de goma de colores',
        weight = 80,
        price = 2,
        usable = true,
        effects = { hunger = 8, stress = -3 }
    },
    {
        name = 'lollipop',
        label = 'Piruleta',
        description = 'Piruleta de fresa con palo',
        weight = 30,
        price = 1,
        usable = true,
        effects = { hunger = 3, stress = -2 }
    },
    {
        name = 'chips',
        label = 'Patatas Fritas de Bolsa',
        description = 'Crujientes patatas fritas sabor clasico',
        weight = 100,
        price = 2,
        usable = true,
        effects = { hunger = 12, thirst = -10, stress = -1 }
    },
    {
        name = 'doritos',
        label = 'Doritos',
        description = 'Nachos de maiz sabor queso',
        weight = 100,
        price = 3,
        usable = true,
        effects = { hunger = 12, thirst = -12, stress = -1 }
    },
    {
        name = 'popcorn',
        label = 'Palomitas',
        description = 'Palomitas de maiz con mantequilla',
        weight = 80,
        price = 3,
        usable = true,
        effects = { hunger = 10, thirst = -8, stress = -2 }
    },
    {
        name = 'pretzel',
        label = 'Pretzel',
        description = 'Pretzel salado crujiente',
        weight = 60,
        price = 2,
        usable = true,
        effects = { hunger = 8, thirst = -6, stress = -1 }
    },
    {
        name = 'granola_bar',
        label = 'Barrita de Cereales',
        description = 'Barrita de cereales con miel y frutos secos',
        weight = 40,
        price = 2,
        usable = true,
        effects = { hunger = 12, stress = -1, stamina = 10 }
    },
    {
        name = 'protein_bar',
        label = 'Barrita Proteica',
        description = 'Barrita energetica alta en proteinas',
        weight = 60,
        price = 4,
        usable = true,
        effects = { hunger = 15, health = 3, stamina = 20 }
    },

    -- ============================================================================
    -- COMIDA - FRUTAS Y VERDURAS
    -- ============================================================================
    {
        name = 'apple',
        label = 'Manzana',
        description = 'Manzana roja fresca y crujiente',
        weight = 150,
        price = 1,
        usable = true,
        effects = { hunger = 10, thirst = 5, health = 2 }
    },
    {
        name = 'banana',
        label = 'Platano',
        description = 'Platano maduro rico en potasio',
        weight = 120,
        price = 1,
        usable = true,
        effects = { hunger = 12, health = 2, stamina = 5 }
    },
    {
        name = 'orange',
        label = 'Naranja',
        description = 'Naranja jugosa llena de vitamina C',
        weight = 180,
        price = 1,
        usable = true,
        effects = { hunger = 8, thirst = 10, health = 3 }
    },
    {
        name = 'grapes',
        label = 'Uvas',
        description = 'Racimo de uvas dulces sin semillas',
        weight = 200,
        price = 3,
        usable = true,
        effects = { hunger = 10, thirst = 8, health = 2 }
    },
    {
        name = 'strawberries',
        label = 'Fresas',
        description = 'Fresas frescas de temporada',
        weight = 150,
        price = 4,
        usable = true,
        effects = { hunger = 8, thirst = 5, health = 3, stress = -2 }
    },
    {
        name = 'watermelon_slice',
        label = 'Porcion de Sandia',
        description = 'Refrescante porcion de sandia',
        weight = 250,
        price = 3,
        usable = true,
        effects = { hunger = 12, thirst = 25, health = 2 }
    },
    {
        name = 'pineapple',
        label = 'Piña',
        description = 'Rodajas de piña tropical dulce',
        weight = 200,
        price = 4,
        usable = true,
        effects = { hunger = 10, thirst = 12, health = 3 }
    },
    {
        name = 'mango',
        label = 'Mango',
        description = 'Mango maduro tropical',
        weight = 180,
        price = 3,
        usable = true,
        effects = { hunger = 12, thirst = 8, health = 3 }
    },
    {
        name = 'peach',
        label = 'Melocoton',
        description = 'Melocoton jugoso de temporada',
        weight = 150,
        price = 2,
        usable = true,
        effects = { hunger = 10, thirst = 6, health = 2 }
    },
    {
        name = 'cherry',
        label = 'Cerezas',
        description = 'Puñado de cerezas rojas',
        weight = 100,
        price = 3,
        usable = true,
        effects = { hunger = 6, thirst = 4, health = 2 }
    },
    {
        name = 'carrot',
        label = 'Zanahoria',
        description = 'Zanahoria crujiente rica en vitaminas',
        weight = 80,
        price = 1,
        usable = true,
        effects = { hunger = 6, health = 3 }
    },
    {
        name = 'cucumber',
        label = 'Pepino',
        description = 'Pepino fresco y refrescante',
        weight = 120,
        price = 1,
        usable = true,
        effects = { hunger = 5, thirst = 8, health = 2 }
    },
    {
        name = 'tomato',
        label = 'Tomate',
        description = 'Tomate maduro de huerta',
        weight = 100,
        price = 1,
        usable = true,
        effects = { hunger = 5, thirst = 5, health = 2 }
    },

    -- ============================================================================
    -- BEBIDAS - AGUA Y REFRESCOS
    -- ============================================================================
    {
        name = 'water',
        label = 'Botella de Agua',
        description = 'Botella de agua mineral fresca',
        weight = 500,
        price = 2,
        usable = true,
        effects = { thirst = 35, health = 2 }
    },
    {
        name = 'water_glass',
        label = 'Vaso de Agua',
        description = 'Vaso de agua fresca del grifo',
        weight = 250,
        price = 0,
        usable = true,
        effects = { thirst = 20, health = 1 }
    },
    {
        name = 'sparkling_water',
        label = 'Agua con Gas',
        description = 'Botella de agua mineral con gas',
        weight = 500,
        price = 3,
        usable = true,
        effects = { thirst = 32, health = 2 }
    },
    {
        name = 'cola',
        label = 'Cola',
        description = 'Refrescante refresco de cola',
        weight = 350,
        price = 3,
        usable = true,
        effects = { thirst = 30, hunger = 3, stress = -2, stamina = 5 }
    },
    {
        name = 'diet_cola',
        label = 'Cola Light',
        description = 'Refresco de cola sin azucar',
        weight = 350,
        price = 3,
        usable = true,
        effects = { thirst = 28, stress = -1, stamina = 3 }
    },
    {
        name = 'lemonade',
        label = 'Limonada',
        description = 'Limonada casera bien fria',
        weight = 400,
        price = 4,
        usable = true,
        effects = { thirst = 35, hunger = 2, stress = -3 }
    },
    {
        name = 'orange_juice',
        label = 'Zumo de Naranja',
        description = 'Zumo de naranja natural recien exprimido',
        weight = 350,
        price = 4,
        usable = true,
        effects = { thirst = 30, hunger = 5, health = 5 }
    },
    {
        name = 'apple_juice',
        label = 'Zumo de Manzana',
        description = 'Zumo de manzana 100% natural',
        weight = 350,
        price = 4,
        usable = true,
        effects = { thirst = 30, hunger = 5, health = 4 }
    },
    {
        name = 'grape_juice',
        label = 'Zumo de Uva',
        description = 'Zumo de uva morada natural',
        weight = 350,
        price = 4,
        usable = true,
        effects = { thirst = 30, hunger = 5, health = 4 }
    },
    {
        name = 'smoothie',
        label = 'Batido de Frutas',
        description = 'Batido de frutas tropicales con yogur',
        weight = 400,
        price = 6,
        usable = true,
        effects = { thirst = 25, hunger = 15, health = 8, stress = -4 }
    },
    {
        name = 'milkshake',
        label = 'Batido de Leche',
        description = 'Cremoso batido de vainilla con nata',
        weight = 400,
        price = 5,
        usable = true,
        effects = { thirst = 20, hunger = 18, stress = -5 }
    },
    {
        name = 'chocolate_milk',
        label = 'Leche con Chocolate',
        description = 'Leche fria con cacao',
        weight = 350,
        price = 3,
        usable = true,
        effects = { thirst = 25, hunger = 10, stress = -3 }
    },
    {
        name = 'iced_tea',
        label = 'Te Helado',
        description = 'Te frio con limon y hielo',
        weight = 400,
        price = 3,
        usable = true,
        effects = { thirst = 32, stress = -2 }
    },
    {
        name = 'sprite',
        label = 'Refresco de Lima-Limon',
        description = 'Refresco burbujeante de lima y limon',
        weight = 350,
        price = 3,
        usable = true,
        effects = { thirst = 30, stress = -2, stamina = 3 }
    },
    {
        name = 'fanta',
        label = 'Refresco de Naranja',
        description = 'Refresco de naranja bien frio',
        weight = 350,
        price = 3,
        usable = true,
        effects = { thirst = 30, hunger = 2, stress = -2 }
    },
    {
        name = 'root_beer',
        label = 'Cerveza de Raiz',
        description = 'Clasica cerveza de raiz americana sin alcohol',
        weight = 350,
        price = 3,
        usable = true,
        effects = { thirst = 28, stress = -2 }
    },
    {
        name = 'coconut_water',
        label = 'Agua de Coco',
        description = 'Agua de coco natural hidratante',
        weight = 350,
        price = 5,
        usable = true,
        effects = { thirst = 40, health = 5, stamina = 10 }
    },

    -- ============================================================================
    -- BEBIDAS - CAFE Y TE
    -- ============================================================================
    {
        name = 'coffee',
        label = 'Cafe',
        description = 'Taza de cafe negro recien hecho',
        weight = 200,
        price = 3,
        usable = true,
        effects = { thirst = 10, stress = -5, stamina = 25 }
    },
    {
        name = 'espresso',
        label = 'Espresso',
        description = 'Cafe espresso italiano bien cargado',
        weight = 50,
        price = 3,
        usable = true,
        effects = { thirst = 5, stress = -3, stamina = 35 }
    },
    {
        name = 'americano',
        label = 'Cafe Americano',
        description = 'Espresso diluido con agua caliente',
        weight = 250,
        price = 4,
        usable = true,
        effects = { thirst = 12, stress = -4, stamina = 28 }
    },
    {
        name = 'latte',
        label = 'Cafe con Leche',
        description = 'Espresso con leche cremosa',
        weight = 300,
        price = 5,
        usable = true,
        effects = { thirst = 15, hunger = 5, stress = -5, stamina = 20 }
    },
    {
        name = 'cappuccino',
        label = 'Capuchino',
        description = 'Espresso con leche espumada y cacao',
        weight = 280,
        price = 5,
        usable = true,
        effects = { thirst = 14, hunger = 4, stress = -6, stamina = 22 }
    },
    {
        name = 'mocha',
        label = 'Moca',
        description = 'Cafe con chocolate y nata montada',
        weight = 350,
        price = 6,
        usable = true,
        effects = { thirst = 15, hunger = 8, stress = -7, stamina = 18 }
    },
    {
        name = 'macchiato',
        label = 'Macchiato',
        description = 'Espresso manchado con espuma de leche',
        weight = 100,
        price = 4,
        usable = true,
        effects = { thirst = 8, stress = -4, stamina = 30 }
    },
    {
        name = 'iced_coffee',
        label = 'Cafe Helado',
        description = 'Cafe frio con hielo perfecto para el verano',
        weight = 350,
        price = 5,
        usable = true,
        effects = { thirst = 25, stress = -5, stamina = 22 }
    },
    {
        name = 'tea',
        label = 'Te',
        description = 'Taza de te caliente relajante',
        weight = 250,
        price = 2,
        usable = true,
        effects = { thirst = 20, stress = -8, health = 2 }
    },
    {
        name = 'green_tea',
        label = 'Te Verde',
        description = 'Te verde japones rico en antioxidantes',
        weight = 250,
        price = 3,
        usable = true,
        effects = { thirst = 22, stress = -10, health = 5, stamina = 8 }
    },
    {
        name = 'chamomile_tea',
        label = 'Te de Manzanilla',
        description = 'Infusion de manzanilla calmante',
        weight = 250,
        price = 3,
        usable = true,
        effects = { thirst = 20, stress = -15, health = 3 }
    },
    {
        name = 'hot_chocolate',
        label = 'Chocolate Caliente',
        description = 'Cremoso chocolate caliente con nata',
        weight = 300,
        price = 4,
        usable = true,
        effects = { thirst = 15, hunger = 10, stress = -10 }
    },

    -- ============================================================================
    -- BEBIDAS - ALCOHOLICAS
    -- ============================================================================
    {
        name = 'beer',
        label = 'Cerveza',
        description = 'Cerveza rubia bien fria',
        weight = 350,
        price = 4,
        usable = true,
        effects = { thirst = 20, stress = -8, drunk = 10 }
    },
    {
        name = 'beer_bottle',
        label = 'Botellin de Cerveza',
        description = 'Botellin de cerveza premium',
        weight = 330,
        price = 5,
        usable = true,
        effects = { thirst = 18, stress = -10, drunk = 12 }
    },
    {
        name = 'dark_beer',
        label = 'Cerveza Negra',
        description = 'Cerveza negra con sabor intenso',
        weight = 350,
        price = 6,
        usable = true,
        effects = { thirst = 18, hunger = 3, stress = -10, drunk = 15 }
    },
    {
        name = 'craft_beer',
        label = 'Cerveza Artesanal',
        description = 'Cerveza artesanal de microcerveceria local',
        weight = 350,
        price = 8,
        usable = true,
        effects = { thirst = 20, stress = -12, drunk = 14 }
    },
    {
        name = 'wine_glass',
        label = 'Copa de Vino',
        description = 'Copa de vino tinto reserva',
        weight = 150,
        price = 8,
        usable = true,
        effects = { thirst = 10, stress = -12, drunk = 15 }
    },
    {
        name = 'wine_bottle',
        label = 'Botella de Vino',
        description = 'Botella de vino tinto de buena cosecha',
        weight = 750,
        price = 35,
        usable = true,
        effects = { thirst = 30, stress = -25, drunk = 50 }
    },
    {
        name = 'white_wine',
        label = 'Vino Blanco',
        description = 'Copa de vino blanco fresco y afrutado',
        weight = 150,
        price = 7,
        usable = true,
        effects = { thirst = 12, stress = -10, drunk = 12 }
    },
    {
        name = 'champagne',
        label = 'Champan',
        description = 'Copa de champan para celebrar',
        weight = 150,
        price = 15,
        usable = true,
        effects = { thirst = 10, stress = -15, drunk = 18 }
    },
    {
        name = 'champagne_bottle',
        label = 'Botella de Champan',
        description = 'Botella de champan frances premium',
        weight = 750,
        price = 120,
        usable = true,
        effects = { thirst = 30, stress = -30, drunk = 60 }
    },
    {
        name = 'whiskey',
        label = 'Whisky',
        description = 'Vaso de whisky escoces añejo',
        weight = 50,
        price = 12,
        usable = true,
        effects = { thirst = 5, stress = -15, drunk = 25 }
    },
    {
        name = 'whiskey_bottle',
        label = 'Botella de Whisky',
        description = 'Botella de whisky premium 12 años',
        weight = 700,
        price = 80,
        usable = true,
        effects = { thirst = 15, stress = -40, drunk = 90 }
    },
    {
        name = 'vodka',
        label = 'Vodka',
        description = 'Chupito de vodka ruso',
        weight = 40,
        price = 8,
        usable = true,
        effects = { thirst = 3, stress = -10, drunk = 22 }
    },
    {
        name = 'vodka_bottle',
        label = 'Botella de Vodka',
        description = 'Botella de vodka premium importado',
        weight = 700,
        price = 50,
        usable = true,
        effects = { thirst = 10, stress = -35, drunk = 85 }
    },
    {
        name = 'rum',
        label = 'Ron',
        description = 'Vaso de ron caribeño dorado',
        weight = 50,
        price = 10,
        usable = true,
        effects = { thirst = 4, stress = -12, drunk = 23 }
    },
    {
        name = 'rum_bottle',
        label = 'Botella de Ron',
        description = 'Botella de ron añejo del Caribe',
        weight = 700,
        price = 60,
        usable = true,
        effects = { thirst = 12, stress = -35, drunk = 88 }
    },
    {
        name = 'tequila',
        label = 'Tequila',
        description = 'Chupito de tequila con sal y limon',
        weight = 40,
        price = 10,
        usable = true,
        effects = { thirst = 2, stress = -12, drunk = 25 }
    },
    {
        name = 'tequila_bottle',
        label = 'Botella de Tequila',
        description = 'Botella de tequila reposado mexicano',
        weight = 700,
        price = 55,
        usable = true,
        effects = { thirst = 8, stress = -38, drunk = 92 }
    },
    {
        name = 'gin',
        label = 'Ginebra',
        description = 'Copa de ginebra con botanicos',
        weight = 50,
        price = 10,
        usable = true,
        effects = { thirst = 4, stress = -10, drunk = 20 }
    },
    {
        name = 'gin_tonic',
        label = 'Gin Tonic',
        description = 'Clasico gin tonic con pepino y enebro',
        weight = 300,
        price = 12,
        usable = true,
        effects = { thirst = 20, stress = -15, drunk = 18 }
    },
    {
        name = 'mojito',
        label = 'Mojito',
        description = 'Refrescante mojito con menta y lima',
        weight = 300,
        price = 10,
        usable = true,
        effects = { thirst = 25, stress = -15, drunk = 15 }
    },
    {
        name = 'margarita',
        label = 'Margarita',
        description = 'Coctel margarita con borde de sal',
        weight = 250,
        price = 12,
        usable = true,
        effects = { thirst = 18, stress = -14, drunk = 20 }
    },
    {
        name = 'pina_colada',
        label = 'Piña Colada',
        description = 'Coctel tropical de coco y piña',
        weight = 350,
        price = 12,
        usable = true,
        effects = { thirst = 22, hunger = 8, stress = -16, drunk = 18 }
    },
    {
        name = 'sangria',
        label = 'Sangria',
        description = 'Refrescante sangria con frutas',
        weight = 300,
        price = 8,
        usable = true,
        effects = { thirst = 25, hunger = 5, stress = -12, drunk = 15 }
    },
    {
        name = 'daiquiri',
        label = 'Daiquiri',
        description = 'Daiquiri de fresa congelado',
        weight = 280,
        price = 11,
        usable = true,
        effects = { thirst = 20, stress = -14, drunk = 16 }
    },
    {
        name = 'martini',
        label = 'Martini',
        description = 'Martini seco con aceituna',
        weight = 100,
        price = 14,
        usable = true,
        effects = { thirst = 8, stress = -15, drunk = 22 }
    },
    {
        name = 'cosmopolitan',
        label = 'Cosmopolitan',
        description = 'Elegante coctel de vodka y arandanos',
        weight = 150,
        price = 13,
        usable = true,
        effects = { thirst = 12, stress = -14, drunk = 18 }
    },

    -- ============================================================================
    -- BEBIDAS - ENERGETICAS Y DEPORTIVAS
    -- ============================================================================
    {
        name = 'energy_drink',
        label = 'Bebida Energetica',
        description = 'Bebida energetica con cafeina y taurina',
        weight = 250,
        price = 4,
        usable = true,
        effects = { thirst = 15, stress = 5, stamina = 50, health = -2 }
    },
    {
        name = 'energy_drink_large',
        label = 'Bebida Energetica Grande',
        description = 'Lata grande de bebida energetica extra fuerte',
        weight = 500,
        price = 6,
        usable = true,
        effects = { thirst = 25, stress = 8, stamina = 80, health = -5 }
    },
    {
        name = 'sports_drink',
        label = 'Bebida Isotonica',
        description = 'Bebida isotonica para deportistas',
        weight = 500,
        price = 4,
        usable = true,
        effects = { thirst = 40, stamina = 30, health = 3 }
    },
    {
        name = 'protein_shake',
        label = 'Batido de Proteinas',
        description = 'Batido de proteinas para recuperacion muscular',
        weight = 400,
        price = 8,
        usable = true,
        effects = { thirst = 20, hunger = 25, health = 10, stamina = 25 }
    },

    -- ============================================================================
    -- MEDICINAS - BASICAS
    -- ============================================================================
    {
        name = 'bandage',
        label = 'Vendaje',
        description = 'Vendaje basico para curar heridas leves',
        weight = 50,
        price = 15,
        usable = true,
        effects = { health = 15 }
    },
    {
        name = 'bandage_pack',
        label = 'Pack de Vendajes',
        description = 'Pack de vendajes esteriles',
        weight = 150,
        price = 40,
        usable = true,
        effects = { health = 40 }
    },
    {
        name = 'gauze',
        label = 'Gasa',
        description = 'Gasa esteril para limpiar heridas',
        weight = 30,
        price = 8,
        usable = true,
        effects = { health = 8 }
    },
    {
        name = 'band_aid',
        label = 'Tiritas',
        description = 'Caja de tiritas para pequeños cortes',
        weight = 20,
        price = 5,
        usable = true,
        effects = { health = 5 }
    },
    {
        name = 'antiseptic',
        label = 'Antiseptico',
        description = 'Solucion antiseptica para desinfectar heridas',
        weight = 100,
        price = 12,
        usable = true,
        effects = { health = 10 }
    },
    {
        name = 'alcohol_swab',
        label = 'Toallitas de Alcohol',
        description = 'Toallitas con alcohol para desinfeccion',
        weight = 10,
        price = 3,
        usable = true,
        effects = { health = 3 }
    },
    {
        name = 'firstaid',
        label = 'Botiquin',
        description = 'Botiquin de primeros auxilios completo',
        weight = 500,
        price = 150,
        usable = true,
        effects = { health = 50 }
    },
    {
        name = 'medkit',
        label = 'Kit Medico Avanzado',
        description = 'Kit medico profesional con suministros avanzados',
        weight = 800,
        price = 350,
        usable = true,
        effects = { health = 80 }
    },
    {
        name = 'trauma_kit',
        label = 'Kit de Trauma',
        description = 'Kit especializado para heridas graves',
        weight = 1000,
        price = 500,
        usable = true,
        effects = { health = 100 }
    },

    -- ============================================================================
    -- MEDICINAS - PASTILLAS Y FARMACOS
    -- ============================================================================
    {
        name = 'painkillers',
        label = 'Analgesicos',
        description = 'Pastillas para aliviar el dolor',
        weight = 20,
        price = 25,
        usable = true,
        effects = { health = 20, stress = -10 }
    },
    {
        name = 'strong_painkillers',
        label = 'Analgesicos Fuertes',
        description = 'Analgesicos de prescripcion medica',
        weight = 20,
        price = 80,
        usable = true,
        effects = { health = 35, stress = -20 }
    },
    {
        name = 'aspirin',
        label = 'Aspirina',
        description = 'Aspirinas para dolores leves y fiebre',
        weight = 10,
        price = 8,
        usable = true,
        effects = { health = 8, stress = -3 }
    },
    {
        name = 'ibuprofen',
        label = 'Ibuprofeno',
        description = 'Antiinflamatorio para dolores musculares',
        weight = 15,
        price = 12,
        usable = true,
        effects = { health = 12, stress = -5 }
    },
    {
        name = 'paracetamol',
        label = 'Paracetamol',
        description = 'Analgesico y antipiretico comun',
        weight = 10,
        price = 10,
        usable = true,
        effects = { health = 10, stress = -4 }
    },
    {
        name = 'antibiotic',
        label = 'Antibioticos',
        description = 'Tratamiento antibiotico de amplio espectro',
        weight = 30,
        price = 60,
        usable = true,
        effects = { health = 30 }
    },
    {
        name = 'vitamins',
        label = 'Vitaminas',
        description = 'Complejo vitaminico para fortalecer el sistema inmune',
        weight = 30,
        price = 20,
        usable = true,
        effects = { health = 15, stamina = 15 }
    },
    {
        name = 'antacid',
        label = 'Antiacido',
        description = 'Pastillas para la acidez estomacal',
        weight = 20,
        price = 8,
        usable = true,
        effects = { health = 5, hunger = 5 }
    },
    {
        name = 'anti_nausea',
        label = 'Antiemetico',
        description = 'Medicamento contra las nauseas',
        weight = 15,
        price = 15,
        usable = true,
        effects = { health = 10, drunk = -20 }
    },
    {
        name = 'sleeping_pills',
        label = 'Pastillas para Dormir',
        description = 'Medicamento para conciliar el sueño',
        weight = 15,
        price = 30,
        usable = true,
        effects = { stress = -30 }
    },
    {
        name = 'antidepressants',
        label = 'Antidepresivos',
        description = 'Medicamento para estabilizar el animo',
        weight = 20,
        price = 50,
        usable = true,
        effects = { stress = -40 }
    },
    {
        name = 'anxiety_meds',
        label = 'Ansioliticos',
        description = 'Medicamento para reducir la ansiedad',
        weight = 15,
        price = 45,
        usable = true,
        effects = { stress = -35 }
    },
    {
        name = 'allergy_pills',
        label = 'Antihistaminicos',
        description = 'Pastillas para alergias y resfriados',
        weight = 15,
        price = 12,
        usable = true,
        effects = { health = 8 }
    },
    {
        name = 'cold_medicine',
        label = 'Antigripal',
        description = 'Medicamento para sintomas del resfriado',
        weight = 50,
        price = 18,
        usable = true,
        effects = { health = 15, thirst = 5 }
    },
    {
        name = 'cough_syrup',
        label = 'Jarabe para la Tos',
        description = 'Jarabe expectorante para la tos',
        weight = 150,
        price = 15,
        usable = true,
        effects = { health = 12, thirst = 3 }
    },

    -- ============================================================================
    -- MEDICINAS - TRATAMIENTOS ESPECIALES
    -- ============================================================================
    {
        name = 'adrenaline',
        label = 'Adrenalina',
        description = 'Inyeccion de adrenalina para emergencias',
        weight = 50,
        price = 200,
        usable = true,
        effects = { health = 25, stamina = 100, stress = 15 }
    },
    {
        name = 'morphine',
        label = 'Morfina',
        description = 'Potente analgesico para dolor extremo',
        weight = 50,
        price = 300,
        usable = true,
        effects = { health = 50, stress = -50 }
    },
    {
        name = 'blood_bag',
        label = 'Bolsa de Sangre',
        description = 'Bolsa de sangre para transfusiones',
        weight = 500,
        price = 400,
        usable = true,
        effects = { health = 60 }
    },
    {
        name = 'iv_bag',
        label = 'Suero Intravenoso',
        description = 'Bolsa de suero para hidratacion intravenosa',
        weight = 500,
        price = 150,
        usable = true,
        effects = { health = 30, thirst = 50 }
    },
    {
        name = 'epinephrine',
        label = 'Epinefrina',
        description = 'Autoinyector de epinefrina para reacciones alergicas',
        weight = 30,
        price = 180,
        usable = true,
        effects = { health = 20, stamina = 60 }
    },
    {
        name = 'antidote',
        label = 'Antidoto',
        description = 'Antidoto universal contra venenos',
        weight = 100,
        price = 250,
        usable = true,
        effects = { health = 40 }
    },
    {
        name = 'splint',
        label = 'Ferula',
        description = 'Ferula para inmovilizar fracturas',
        weight = 200,
        price = 50,
        usable = true,
        effects = { health = 25 }
    },
    {
        name = 'tourniquet',
        label = 'Torniquete',
        description = 'Torniquete para detener hemorragias graves',
        weight = 80,
        price = 35,
        usable = true,
        effects = { health = 20 }
    },
    {
        name = 'burn_cream',
        label = 'Crema para Quemaduras',
        description = 'Crema especial para tratar quemaduras',
        weight = 100,
        price = 25,
        usable = true,
        effects = { health = 15 }
    },
    {
        name = 'eye_drops',
        label = 'Colirio',
        description = 'Gotas oftalmicas para irritacion ocular',
        weight = 30,
        price = 15,
        usable = true,
        effects = { health = 5 }
    },
    {
        name = 'inhaler',
        label = 'Inhalador',
        description = 'Inhalador para asma y dificultades respiratorias',
        weight = 50,
        price = 80,
        usable = true,
        effects = { health = 15, stamina = 40 }
    },
    {
        name = 'insulin',
        label = 'Insulina',
        description = 'Inyeccion de insulina para diabeticos',
        weight = 50,
        price = 100,
        usable = true,
        effects = { health = 20 }
    },
    {
        name = 'naloxone',
        label = 'Naloxona',
        description = 'Antidoto para sobredosis de opioides',
        weight = 30,
        price = 150,
        usable = true,
        effects = { health = 35, drunk = -50 }
    },

    -- ============================================================================
    -- MEDICINAS - SUPLEMENTOS Y POTENCIADORES
    -- ============================================================================
    {
        name = 'caffeine_pills',
        label = 'Pastillas de Cafeina',
        description = 'Suplemento de cafeina para mantenerse despierto',
        weight = 10,
        price = 10,
        usable = true,
        effects = { stamina = 40, stress = 5 }
    },
    {
        name = 'melatonin',
        label = 'Melatonina',
        description = 'Suplemento natural para regular el sueño',
        weight = 15,
        price = 15,
        usable = true,
        effects = { stress = -20 }
    },
    {
        name = 'electrolytes',
        label = 'Electrolitos',
        description = 'Suplemento de electrolitos para hidratacion',
        weight = 30,
        price = 8,
        usable = true,
        effects = { thirst = 20, stamina = 15, health = 5 }
    },
    {
        name = 'creatine',
        label = 'Creatina',
        description = 'Suplemento deportivo para rendimiento',
        weight = 50,
        price = 25,
        usable = true,
        effects = { stamina = 35, health = 5 }
    },
    {
        name = 'preworkout',
        label = 'Pre-Entreno',
        description = 'Suplemento pre-entrenamiento energizante',
        weight = 30,
        price = 20,
        usable = true,
        effects = { stamina = 60, stress = 10, health = -3 }
    },
    {
        name = 'bcaa',
        label = 'Aminoacidos BCAA',
        description = 'Suplemento de aminoacidos ramificados',
        weight = 40,
        price = 22,
        usable = true,
        effects = { stamina = 25, health = 8 }
    },
    {
        name = 'omega3',
        label = 'Omega 3',
        description = 'Capsulas de aceite de pescado omega 3',
        weight = 30,
        price = 18,
        usable = true,
        effects = { health = 10, stress = -5 }
    },
    {
        name = 'magnesium',
        label = 'Magnesio',
        description = 'Suplemento de magnesio para relajacion muscular',
        weight = 20,
        price = 12,
        usable = true,
        effects = { stress = -12, stamina = 10 }
    },
    {
        name = 'zinc',
        label = 'Zinc',
        description = 'Suplemento de zinc para el sistema inmune',
        weight = 15,
        price = 10,
        usable = true,
        effects = { health = 8 }
    },
    {
        name = 'iron_supplement',
        label = 'Hierro',
        description = 'Suplemento de hierro para la sangre',
        weight = 20,
        price = 12,
        usable = true,
        effects = { health = 10, stamina = 8 }
    },

    -- ============================================================================
    -- ITEMS ESPECIALES - ARMADURA Y PROTECCION
    -- ============================================================================
    {
        name = 'armor_vest',
        label = 'Chaleco Antibalas',
        description = 'Chaleco de proteccion balistica nivel III',
        weight = 3000,
        price = 5000,
        usable = true,
        effects = { armor = 50 }
    },
    {
        name = 'heavy_armor',
        label = 'Armadura Pesada',
        description = 'Armadura tactica de proteccion completa',
        weight = 8000,
        price = 15000,
        usable = true,
        effects = { armor = 100 }
    },
    {
        name = 'helmet',
        label = 'Casco Tactico',
        description = 'Casco de proteccion tactica',
        weight = 1500,
        price = 2000,
        usable = true,
        effects = { armor = 20 }
    },

    -- ============================================================================
    -- ITEMS ESPECIALES - SUPERVIVENCIA
    -- ============================================================================
    {
        name = 'mre',
        label = 'Racion Militar',
        description = 'Racion de combate lista para comer',
        weight = 400,
        price = 15,
        usable = true,
        effects = { hunger = 60, thirst = 10, health = 5 }
    },
    {
        name = 'survival_ration',
        label = 'Racion de Supervivencia',
        description = 'Racion compacta de alta energia para emergencias',
        weight = 200,
        price = 25,
        usable = true,
        effects = { hunger = 40, thirst = 5, stamina = 20 }
    },
    {
        name = 'canned_food',
        label = 'Comida Enlatada',
        description = 'Lata de conservas variadas',
        weight = 350,
        price = 5,
        usable = true,
        effects = { hunger = 35, thirst = -5 }
    },
    {
        name = 'canned_beans',
        label = 'Frijoles Enlatados',
        description = 'Lata de frijoles cocidos',
        weight = 400,
        price = 4,
        usable = true,
        effects = { hunger = 30, thirst = -3 }
    },
    {
        name = 'canned_tuna',
        label = 'Atun Enlatado',
        description = 'Lata de atun en aceite',
        weight = 200,
        price = 6,
        usable = true,
        effects = { hunger = 25, thirst = -5, health = 3 }
    },
    {
        name = 'beef_jerky',
        label = 'Cecina',
        description = 'Carne seca conservada rica en proteinas',
        weight = 100,
        price = 8,
        usable = true,
        effects = { hunger = 20, thirst = -10, stamina = 10 }
    },
    {
        name = 'trail_mix',
        label = 'Mix de Frutos Secos',
        description = 'Mezcla de frutos secos y semillas',
        weight = 150,
        price = 6,
        usable = true,
        effects = { hunger = 18, health = 5, stamina = 15 }
    },
    {
        name = 'dried_fruit',
        label = 'Fruta Deshidratada',
        description = 'Mezcla de frutas deshidratadas',
        weight = 100,
        price = 5,
        usable = true,
        effects = { hunger = 12, thirst = -3, health = 3 }
    },
    {
        name = 'crackers',
        label = 'Galletas Saladas',
        description = 'Paquete de galletas saladas',
        weight = 80,
        price = 2,
        usable = true,
        effects = { hunger = 10, thirst = -8 }
    },
    {
        name = 'peanut_butter',
        label = 'Mantequilla de Cacahuete',
        description = 'Tarro de mantequilla de cacahuete',
        weight = 300,
        price = 6,
        usable = true,
        effects = { hunger = 25, thirst = -10 }
    },
    {
        name = 'honey',
        label = 'Miel',
        description = 'Tarro de miel natural pura',
        weight = 350,
        price = 10,
        usable = true,
        effects = { hunger = 15, health = 8 }
    },

    -- ============================================================================
    -- ITEMS ESPECIALES - CIGARRILLOS Y TABACO
    -- ============================================================================
    {
        name = 'cigarette',
        label = 'Cigarrillo',
        description = 'Un cigarrillo de tabaco',
        weight = 5,
        price = 1,
        usable = true,
        effects = { stress = -15, health = -2 }
    },
    {
        name = 'cigarette_pack',
        label = 'Cajetilla de Cigarrillos',
        description = 'Cajetilla de 20 cigarrillos',
        weight = 50,
        price = 12,
        usable = true,
        effects = { stress = -20, health = -3 }
    },
    {
        name = 'cigar',
        label = 'Puro',
        description = 'Puro cubano de calidad premium',
        weight = 30,
        price = 25,
        usable = true,
        effects = { stress = -25, health = -5 }
    },
    {
        name = 'vape',
        label = 'Vaporizador',
        description = 'Cigarrillo electronico con liquido de nicotina',
        weight = 100,
        price = 30,
        usable = true,
        effects = { stress = -12, health = -1 }
    },
    {
        name = 'lighter',
        label = 'Mechero',
        description = 'Mechero desechable',
        weight = 20,
        price = 2,
        usable = true,
        effects = {}
    },
    {
        name = 'matches',
        label = 'Cerillas',
        description = 'Caja de cerillas de madera',
        weight = 15,
        price = 1,
        usable = true,
        effects = {}
    }
}
