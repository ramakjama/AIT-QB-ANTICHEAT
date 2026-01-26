--[[
    AIT-QB: Catálogo de Vehículos
    500+ vehículos de GTA V
    Servidor Español
]]

AIT = AIT or {}
AIT.Data = AIT.Data or {}
AIT.Data.Vehicles = {}

-- Categorías de vehículos
AIT.Data.Vehicles.Categories = {
    compacts = { label = 'Compactos', icon = 'car' },
    sedans = { label = 'Sedanes', icon = 'car' },
    coupes = { label = 'Cupés', icon = 'car' },
    sports = { label = 'Deportivos', icon = 'car-side' },
    sportsclassics = { label = 'Clásicos Deportivos', icon = 'car' },
    super = { label = 'Super', icon = 'rocket' },
    muscle = { label = 'Muscle', icon = 'car' },
    offroad = { label = 'Todoterreno', icon = 'truck-monster' },
    suv = { label = 'SUV', icon = 'truck' },
    vans = { label = 'Furgonetas', icon = 'shuttle-van' },
    motorcycles = { label = 'Motocicletas', icon = 'motorcycle' },
    cycles = { label = 'Bicicletas', icon = 'bicycle' },
    boats = { label = 'Barcos', icon = 'ship' },
    helicopters = { label = 'Helicópteros', icon = 'helicopter' },
    planes = { label = 'Aviones', icon = 'plane' },
    service = { label = 'Servicio', icon = 'ambulance' },
    emergency = { label = 'Emergencias', icon = 'car-alt' },
    military = { label = 'Militar', icon = 'fighter-jet' },
    commercial = { label = 'Comercial', icon = 'truck' },
    industrial = { label = 'Industrial', icon = 'truck-loading' },
}

-- Marcas de vehículos
AIT.Data.Vehicles.Brands = {
    albany = 'Albany', annis = 'Annis', benefactor = 'Benefactor',
    bravado = 'Bravado', brute = 'Brute', buckingham = 'Buckingham',
    canis = 'Canis', chariot = 'Chariot', cheval = 'Cheval',
    coil = 'Coil', declasse = 'Declasse', dewbauchee = 'Dewbauchee',
    dinka = 'Dinka', dundreary = 'Dundreary', emperor = 'Emperor',
    enus = 'Enus', fathom = 'Fathom', gallivanter = 'Gallivanter',
    grotti = 'Grotti', hijak = 'Hijak', hvy = 'HVY',
    imponte = 'Imponte', invetero = 'Invetero', jacksheepe = 'JackSheepe',
    jobuilt = 'JoBuilt', karin = 'Karin', lampadati = 'Lampadati',
    maibatsu = 'Maibatsu', mammoth = 'Mammoth', maxwell = 'Maxwell',
    nagasaki = 'Nagasaki', obey = 'Obey', ocelot = 'Ocelot',
    overflod = 'Overflod', pegassi = 'Pegassi', pfister = 'Pfister',
    principe = 'Principe', progen = 'Progen', schyster = 'Schyster',
    shitzu = 'Shitzu', speedophile = 'Speedophile', stanley = 'Stanley',
    truffade = 'Truffade', ubermacht = 'Übermacht', vapid = 'Vapid',
    vulcar = 'Vulcar', weeny = 'Weeny', western = 'Western',
    willard = 'Willard', zirconium = 'Zirconium',
}

-- CATÁLOGO COMPLETO DE VEHÍCULOS
AIT.Data.Vehicles.List = {
    -- ═══════════════════════════════════════════════════════════════
    -- COMPACTOS (30 vehículos)
    -- ═══════════════════════════════════════════════════════════════
    { model = 'asbo', label = 'Asbo', brand = 'maxwell', category = 'compacts', price = 12000, seats = 4, trunk = 15, fuel = 45, speed = 140, accel = 6.5 },
    { model = 'blista', label = 'Blista', brand = 'dinka', category = 'compacts', price = 15000, seats = 4, trunk = 20, fuel = 40, speed = 145, accel = 6.8 },
    { model = 'brioso', label = 'Brioso 300', brand = 'grotti', category = 'compacts', price = 18000, seats = 2, trunk = 10, fuel = 35, speed = 135, accel = 7.0 },
    { model = 'brioso2', label = 'Brioso 300 Widebody', brand = 'grotti', category = 'compacts', price = 22000, seats = 2, trunk = 10, fuel = 35, speed = 140, accel = 7.2 },
    { model = 'club', label = 'Club', brand = 'bravado', category = 'compacts', price = 14000, seats = 4, trunk = 18, fuel = 42, speed = 142, accel = 6.6 },
    { model = 'dilettante', label = 'Dilettante', brand = 'karin', category = 'compacts', price = 25000, seats = 4, trunk = 25, fuel = 50, speed = 130, accel = 5.5 },
    { model = 'dilettante2', label = 'Dilettante Patrulla', brand = 'karin', category = 'compacts', price = 0, seats = 4, trunk = 25, fuel = 50, speed = 130, accel = 5.5, restricted = true },
    { model = 'issi2', label = 'Issi', brand = 'weeny', category = 'compacts', price = 16000, seats = 4, trunk = 12, fuel = 38, speed = 138, accel = 6.9 },
    { model = 'issi3', label = 'Issi Clásico', brand = 'weeny', category = 'compacts', price = 35000, seats = 4, trunk = 10, fuel = 35, speed = 125, accel = 6.2 },
    { model = 'issi4', label = 'Issi Arena', brand = 'weeny', category = 'compacts', price = 85000, seats = 2, trunk = 5, fuel = 40, speed = 150, accel = 7.5 },
    { model = 'issi5', label = 'Issi Sport', brand = 'weeny', category = 'compacts', price = 45000, seats = 2, trunk = 8, fuel = 38, speed = 155, accel = 7.8 },
    { model = 'issi6', label = 'Issi Rally', brand = 'weeny', category = 'compacts', price = 48000, seats = 2, trunk = 8, fuel = 40, speed = 152, accel = 7.6 },
    { model = 'kanjo', label = 'Kanjo', brand = 'dinka', category = 'compacts', price = 28000, seats = 2, trunk = 10, fuel = 38, speed = 160, accel = 8.0 },
    { model = 'panto', label = 'Panto', brand = 'benefactor', category = 'compacts', price = 10000, seats = 2, trunk = 8, fuel = 30, speed = 120, accel = 6.0 },
    { model = 'prairie', label = 'Prairie', brand = 'bollokan', category = 'compacts', price = 13000, seats = 4, trunk = 18, fuel = 42, speed = 140, accel = 6.5 },
    { model = 'rhapsody', label = 'Rhapsody', brand = 'declasse', category = 'compacts', price = 20000, seats = 4, trunk = 15, fuel = 40, speed = 130, accel = 6.0 },

    -- ═══════════════════════════════════════════════════════════════
    -- SEDANES (40 vehículos)
    -- ═══════════════════════════════════════════════════════════════
    { model = 'asea', label = 'Asea', brand = 'declasse', category = 'sedans', price = 8000, seats = 4, trunk = 30, fuel = 50, speed = 135, accel = 5.5 },
    { model = 'asea2', label = 'Asea Nieve', brand = 'declasse', category = 'sedans', price = 8500, seats = 4, trunk = 30, fuel = 50, speed = 135, accel = 5.5 },
    { model = 'asterope', label = 'Asterope', brand = 'karin', category = 'sedans', price = 12000, seats = 4, trunk = 35, fuel = 55, speed = 140, accel = 5.8 },
    { model = 'cog55', label = 'Cognoscenti 55', brand = 'enus', category = 'sedans', price = 85000, seats = 4, trunk = 40, fuel = 70, speed = 155, accel = 6.5 },
    { model = 'cog552', label = 'Cognoscenti 55 Blindado', brand = 'enus', category = 'sedans', price = 150000, seats = 4, trunk = 35, fuel = 75, speed = 145, accel = 5.8, armor = 50 },
    { model = 'cognoscenti', label = 'Cognoscenti', brand = 'enus', category = 'sedans', price = 95000, seats = 4, trunk = 45, fuel = 75, speed = 158, accel = 6.8 },
    { model = 'cognoscenti2', label = 'Cognoscenti Blindado', brand = 'enus', category = 'sedans', price = 175000, seats = 4, trunk = 40, fuel = 80, speed = 148, accel = 6.0, armor = 60 },
    { model = 'emperor', label = 'Emperor', brand = 'albany', category = 'sedans', price = 6000, seats = 4, trunk = 35, fuel = 60, speed = 125, accel = 4.8 },
    { model = 'emperor2', label = 'Emperor Oxidado', brand = 'albany', category = 'sedans', price = 2000, seats = 4, trunk = 35, fuel = 55, speed = 115, accel = 4.2 },
    { model = 'fugitive', label = 'Fugitive', brand = 'cheval', category = 'sedans', price = 18000, seats = 4, trunk = 32, fuel = 55, speed = 150, accel = 6.2 },
    { model = 'glendale', label = 'Glendale', brand = 'benefactor', category = 'sedans', price = 22000, seats = 4, trunk = 38, fuel = 60, speed = 140, accel = 5.5 },
    { model = 'glendale2', label = 'Glendale Custom', brand = 'benefactor', category = 'sedans', price = 35000, seats = 4, trunk = 38, fuel = 60, speed = 145, accel = 5.8 },
    { model = 'ingot', label = 'Ingot', brand = 'vulcar', category = 'sedans', price = 9000, seats = 4, trunk = 40, fuel = 50, speed = 130, accel = 5.0 },
    { model = 'intruder', label = 'Intruder', brand = 'karin', category = 'sedans', price = 14000, seats = 4, trunk = 35, fuel = 55, speed = 145, accel = 5.8 },
    { model = 'premier', label = 'Premier', brand = 'declasse', category = 'sedans', price = 11000, seats = 4, trunk = 32, fuel = 52, speed = 142, accel = 5.6 },
    { model = 'primo', label = 'Primo', brand = 'albany', category = 'sedans', price = 10000, seats = 4, trunk = 34, fuel = 54, speed = 138, accel = 5.4 },
    { model = 'primo2', label = 'Primo Custom', brand = 'albany', category = 'sedans', price = 25000, seats = 4, trunk = 34, fuel = 54, speed = 145, accel = 5.8 },
    { model = 'regina', label = 'Regina', brand = 'dundreary', category = 'sedans', price = 7000, seats = 4, trunk = 50, fuel = 65, speed = 125, accel = 4.5 },
    { model = 'romero', label = 'Romero', brand = 'chariot', category = 'sedans', price = 15000, seats = 2, trunk = 80, fuel = 65, speed = 120, accel = 4.0 },
    { model = 'schafter2', label = 'Schafter', brand = 'benefactor', category = 'sedans', price = 45000, seats = 4, trunk = 30, fuel = 60, speed = 165, accel = 7.2 },
    { model = 'schafter5', label = 'Schafter V12 Blindado', brand = 'benefactor', category = 'sedans', price = 180000, seats = 4, trunk = 28, fuel = 65, speed = 155, accel = 6.5, armor = 55 },
    { model = 'schafter6', label = 'Schafter LWB Blindado', brand = 'benefactor', category = 'sedans', price = 200000, seats = 4, trunk = 32, fuel = 70, speed = 150, accel = 6.2, armor = 60 },
    { model = 'stafford', label = 'Stafford', brand = 'enus', category = 'sedans', price = 120000, seats = 4, trunk = 42, fuel = 72, speed = 155, accel = 6.5 },
    { model = 'stanier', label = 'Stanier', brand = 'vapid', category = 'sedans', price = 12000, seats = 4, trunk = 38, fuel = 58, speed = 140, accel = 5.5 },
    { model = 'stratum', label = 'Stratum', brand = 'zirconium', category = 'sedans', price = 13000, seats = 4, trunk = 45, fuel = 52, speed = 138, accel = 5.4 },
    { model = 'stretch', label = 'Stretch', brand = 'dundreary', category = 'sedans', price = 75000, seats = 6, trunk = 25, fuel = 80, speed = 135, accel = 5.0 },
    { model = 'superd', label = 'Super Diamond', brand = 'enus', category = 'sedans', price = 250000, seats = 4, trunk = 45, fuel = 85, speed = 160, accel = 6.8 },
    { model = 'surge', label = 'Surge', brand = 'cheval', category = 'sedans', price = 35000, seats = 4, trunk = 28, fuel = 45, speed = 145, accel = 6.0 },
    { model = 'tailgater', label = 'Tailgater', brand = 'obey', category = 'sedans', price = 55000, seats = 4, trunk = 30, fuel = 58, speed = 160, accel = 7.0 },
    { model = 'tailgater2', label = 'Tailgater S', brand = 'obey', category = 'sedans', price = 75000, seats = 4, trunk = 28, fuel = 55, speed = 170, accel = 7.5 },
    { model = 'warrener', label = 'Warrener', brand = 'vulcar', category = 'sedans', price = 18000, seats = 4, trunk = 35, fuel = 50, speed = 135, accel = 5.2 },
    { model = 'warrener2', label = 'Warrener HKR', brand = 'vulcar', category = 'sedans', price = 28000, seats = 4, trunk = 32, fuel = 48, speed = 145, accel = 5.8 },
    { model = 'washington', label = 'Washington', brand = 'albany', category = 'sedans', price = 15000, seats = 4, trunk = 40, fuel = 62, speed = 142, accel = 5.5 },

    -- ═══════════════════════════════════════════════════════════════
    -- CUPÉS (25 vehículos)
    -- ═══════════════════════════════════════════════════════════════
    { model = 'cogcabrio', label = 'Cognoscenti Cabrio', brand = 'enus', category = 'coupes', price = 95000, seats = 4, trunk = 25, fuel = 65, speed = 165, accel = 7.0 },
    { model = 'exemplar', label = 'Exemplar', brand = 'dewbauchee', category = 'coupes', price = 75000, seats = 4, trunk = 22, fuel = 60, speed = 170, accel = 7.2 },
    { model = 'f620', label = 'F620', brand = 'ocelot', category = 'coupes', price = 85000, seats = 4, trunk = 20, fuel = 58, speed = 175, accel = 7.5 },
    { model = 'felon', label = 'Felon', brand = 'lampadati', category = 'coupes', price = 70000, seats = 4, trunk = 24, fuel = 62, speed = 168, accel = 7.0 },
    { model = 'felon2', label = 'Felon GT', brand = 'lampadati', category = 'coupes', price = 90000, seats = 2, trunk = 18, fuel = 58, speed = 178, accel = 7.8 },
    { model = 'jackal', label = 'Jackal', brand = 'ocelot', category = 'coupes', price = 65000, seats = 4, trunk = 22, fuel = 60, speed = 165, accel = 7.0 },
    { model = 'oracle', label = 'Oracle', brand = 'ubermacht', category = 'coupes', price = 55000, seats = 4, trunk = 28, fuel = 62, speed = 160, accel = 6.5 },
    { model = 'oracle2', label = 'Oracle XS', brand = 'ubermacht', category = 'coupes', price = 72000, seats = 4, trunk = 26, fuel = 60, speed = 168, accel = 7.0 },
    { model = 'sentinel', label = 'Sentinel', brand = 'ubermacht', category = 'coupes', price = 48000, seats = 4, trunk = 20, fuel = 55, speed = 165, accel = 7.2 },
    { model = 'sentinel2', label = 'Sentinel XS', brand = 'ubermacht', category = 'coupes', price = 60000, seats = 2, trunk = 18, fuel = 52, speed = 172, accel = 7.5 },
    { model = 'sentinel3', label = 'Sentinel Clásico', brand = 'ubermacht', category = 'coupes', price = 85000, seats = 2, trunk = 16, fuel = 50, speed = 160, accel = 7.0 },
    { model = 'windsor', label = 'Windsor', brand = 'enus', category = 'coupes', price = 150000, seats = 2, trunk = 20, fuel = 70, speed = 170, accel = 7.2 },
    { model = 'windsor2', label = 'Windsor Drop', brand = 'enus', category = 'coupes', price = 180000, seats = 2, trunk = 18, fuel = 68, speed = 168, accel = 7.0 },
    { model = 'zion', label = 'Zion', brand = 'ubermacht', category = 'coupes', price = 52000, seats = 4, trunk = 22, fuel = 55, speed = 168, accel = 7.2 },
    { model = 'zion2', label = 'Zion Cabrio', brand = 'ubermacht', category = 'coupes', price = 65000, seats = 4, trunk = 18, fuel = 52, speed = 165, accel = 7.0 },
    { model = 'zion3', label = 'Zion Clásico', brand = 'ubermacht', category = 'coupes', price = 95000, seats = 2, trunk = 15, fuel = 48, speed = 162, accel = 6.8 },

    -- ═══════════════════════════════════════════════════════════════
    -- DEPORTIVOS (65 vehículos)
    -- ═══════════════════════════════════════════════════════════════
    { model = 'alpha', label = 'Alpha', brand = 'albany', category = 'sports', price = 120000, seats = 2, trunk = 12, fuel = 55, speed = 185, accel = 8.2 },
    { model = 'banshee', label = 'Banshee', brand = 'bravado', category = 'sports', price = 95000, seats = 2, trunk = 10, fuel = 52, speed = 190, accel = 8.5 },
    { model = 'banshee2', label = 'Banshee 900R', brand = 'bravado', category = 'sports', price = 180000, seats = 2, trunk = 8, fuel = 50, speed = 210, accel = 9.2 },
    { model = 'bestiagts', label = 'Bestia GTS', brand = 'grotti', category = 'sports', price = 145000, seats = 2, trunk = 10, fuel = 55, speed = 195, accel = 8.8 },
    { model = 'buffalo', label = 'Buffalo', brand = 'bravado', category = 'sports', price = 35000, seats = 4, trunk = 25, fuel = 60, speed = 170, accel = 7.5 },
    { model = 'buffalo2', label = 'Buffalo S', brand = 'bravado', category = 'sports', price = 55000, seats = 4, trunk = 22, fuel = 58, speed = 180, accel = 8.0 },
    { model = 'buffalo3', label = 'Sprunk Buffalo', brand = 'bravado', category = 'sports', price = 65000, seats = 4, trunk = 22, fuel = 58, speed = 182, accel = 8.2 },
    { model = 'buffalo4', label = 'Buffalo STX', brand = 'bravado', category = 'sports', price = 125000, seats = 4, trunk = 20, fuel = 55, speed = 195, accel = 8.8 },
    { model = 'calico', label = 'Calico GTF', brand = 'karin', category = 'sports', price = 115000, seats = 2, trunk = 12, fuel = 50, speed = 188, accel = 8.5 },
    { model = 'carbonizzare', label = 'Carbonizzare', brand = 'grotti', category = 'sports', price = 160000, seats = 2, trunk = 10, fuel = 55, speed = 195, accel = 8.8 },
    { model = 'comet2', label = 'Comet', brand = 'pfister', category = 'sports', price = 140000, seats = 2, trunk = 8, fuel = 52, speed = 192, accel = 8.6 },
    { model = 'comet3', label = 'Comet Retro', brand = 'pfister', category = 'sports', price = 175000, seats = 2, trunk = 8, fuel = 50, speed = 188, accel = 8.5 },
    { model = 'comet4', label = 'Comet Safari', brand = 'pfister', category = 'sports', price = 145000, seats = 2, trunk = 10, fuel = 55, speed = 175, accel = 8.0 },
    { model = 'comet5', label = 'Comet SR', brand = 'pfister', category = 'sports', price = 185000, seats = 2, trunk = 6, fuel = 48, speed = 200, accel = 9.0 },
    { model = 'comet6', label = 'Comet S2', brand = 'pfister', category = 'sports', price = 165000, seats = 2, trunk = 8, fuel = 50, speed = 195, accel = 8.8 },
    { model = 'coquette', label = 'Coquette', brand = 'invetero', category = 'sports', price = 130000, seats = 2, trunk = 10, fuel = 55, speed = 190, accel = 8.5 },
    { model = 'coquette4', label = 'Coquette D10', brand = 'invetero', category = 'sports', price = 185000, seats = 2, trunk = 8, fuel = 52, speed = 205, accel = 9.0 },
    { model = 'cypher', label = 'Cypher', brand = 'ubermacht', category = 'sports', price = 135000, seats = 2, trunk = 12, fuel = 52, speed = 188, accel = 8.5 },
    { model = 'drafter', label = 'Drafter 8F', brand = 'obey', category = 'sports', price = 125000, seats = 4, trunk = 15, fuel = 55, speed = 185, accel = 8.3 },
    { model = 'elegy', label = 'Elegy Retro', brand = 'annis', category = 'sports', price = 150000, seats = 2, trunk = 10, fuel = 50, speed = 188, accel = 8.5 },
    { model = 'elegy2', label = 'Elegy RH8', brand = 'annis', category = 'sports', price = 95000, seats = 2, trunk = 12, fuel = 52, speed = 185, accel = 8.2 },
    { model = 'euros', label = 'Euros', brand = 'annis', category = 'sports', price = 110000, seats = 2, trunk = 10, fuel = 48, speed = 182, accel = 8.2 },
    { model = 'feltzer2', label = 'Feltzer', brand = 'benefactor', category = 'sports', price = 125000, seats = 2, trunk = 10, fuel = 55, speed = 188, accel = 8.5 },
    { model = 'feltzer3', label = 'Stirling GT', brand = 'benefactor', category = 'sports', price = 200000, seats = 2, trunk = 8, fuel = 52, speed = 195, accel = 8.8 },
    { model = 'flashgt', label = 'Flash GT', brand = 'vapid', category = 'sports', price = 105000, seats = 2, trunk = 12, fuel = 50, speed = 180, accel = 8.0 },
    { model = 'furoregt', label = 'Furore GT', brand = 'lampadati', category = 'sports', price = 115000, seats = 2, trunk = 10, fuel = 52, speed = 185, accel = 8.3 },
    { model = 'fusilade', label = 'Fusilade', brand = 'schyster', category = 'sports', price = 85000, seats = 2, trunk = 15, fuel = 55, speed = 175, accel = 7.8 },
    { model = 'futo', label = 'Futo', brand = 'karin', category = 'sports', price = 28000, seats = 4, trunk = 18, fuel = 48, speed = 160, accel = 7.0 },
    { model = 'futo2', label = 'Futo GTX', brand = 'karin', category = 'sports', price = 45000, seats = 4, trunk = 16, fuel = 46, speed = 168, accel = 7.5 },
    { model = 'gb200', label = 'GB200', brand = 'vapid', category = 'sports', price = 135000, seats = 2, trunk = 10, fuel = 50, speed = 185, accel = 8.5 },
    { model = 'growler', label = 'Growler', brand = 'pfister', category = 'sports', price = 155000, seats = 2, trunk = 8, fuel = 52, speed = 192, accel = 8.6 },
    { model = 'hotring', label = 'Hotring Sabre', brand = 'declasse', category = 'sports', price = 180000, seats = 2, trunk = 5, fuel = 60, speed = 210, accel = 9.2 },
    { model = 'imorgon', label = 'Imorgon', brand = 'overflod', category = 'sports', price = 170000, seats = 2, trunk = 10, fuel = 45, speed = 188, accel = 8.5 },
    { model = 'issi7', label = 'Issi Sport', brand = 'weeny', category = 'sports', price = 95000, seats = 2, trunk = 8, fuel = 42, speed = 175, accel = 8.0 },
    { model = 'italigto', label = 'Itali GTO', brand = 'grotti', category = 'sports', price = 195000, seats = 2, trunk = 8, fuel = 55, speed = 205, accel = 9.0 },
    { model = 'jester', label = 'Jester', brand = 'dinka', category = 'sports', price = 130000, seats = 2, trunk = 10, fuel = 52, speed = 190, accel = 8.5 },
    { model = 'jester2', label = 'Jester Carrera', brand = 'dinka', category = 'sports', price = 175000, seats = 2, trunk = 8, fuel = 50, speed = 200, accel = 9.0 },
    { model = 'jester3', label = 'Jester Clásico', brand = 'dinka', category = 'sports', price = 165000, seats = 2, trunk = 10, fuel = 48, speed = 185, accel = 8.3 },
    { model = 'jester4', label = 'Jester RR', brand = 'dinka', category = 'sports', price = 180000, seats = 2, trunk = 8, fuel = 52, speed = 198, accel = 8.8 },
    { model = 'khamelion', label = 'Khamelion', brand = 'hijak', category = 'sports', price = 145000, seats = 2, trunk = 10, fuel = 40, speed = 180, accel = 8.0 },
    { model = 'komoda', label = 'Komoda', brand = 'lampadati', category = 'sports', price = 120000, seats = 4, trunk = 15, fuel = 55, speed = 182, accel = 8.2 },
    { model = 'kuruma', label = 'Kuruma', brand = 'karin', category = 'sports', price = 65000, seats = 4, trunk = 20, fuel = 52, speed = 175, accel = 7.8 },
    { model = 'kuruma2', label = 'Kuruma Blindado', brand = 'karin', category = 'sports', price = 525000, seats = 4, trunk = 18, fuel = 55, speed = 168, accel = 7.2, armor = 80 },
    { model = 'locust', label = 'Locust', brand = 'ocelot', category = 'sports', price = 165000, seats = 2, trunk = 6, fuel = 48, speed = 195, accel = 8.8 },
    { model = 'lynx', label = 'Lynx', brand = 'ocelot', category = 'sports', price = 155000, seats = 2, trunk = 8, fuel = 50, speed = 190, accel = 8.5 },
    { model = 'massacro', label = 'Massacro', brand = 'dewbauchee', category = 'sports', price = 145000, seats = 2, trunk = 10, fuel = 55, speed = 188, accel = 8.5 },
    { model = 'massacro2', label = 'Massacro Carrera', brand = 'dewbauchee', category = 'sports', price = 185000, seats = 2, trunk = 8, fuel = 52, speed = 198, accel = 8.8 },
    { model = 'neo', label = 'Neon', brand = 'pfister', category = 'sports', price = 175000, seats = 4, trunk = 12, fuel = 40, speed = 195, accel = 8.8 },
    { model = 'ninef', label = '9F', brand = 'obey', category = 'sports', price = 135000, seats = 2, trunk = 8, fuel = 52, speed = 188, accel = 8.5 },
    { model = 'ninef2', label = '9F Cabrio', brand = 'obey', category = 'sports', price = 150000, seats = 2, trunk = 6, fuel = 50, speed = 185, accel = 8.3 },
    { model = 'omnis', label = 'Omnis', brand = 'obey', category = 'sports', price = 95000, seats = 2, trunk = 12, fuel = 48, speed = 178, accel = 8.0 },
    { model = 'pariah', label = 'Pariah', brand = 'ocelot', category = 'sports', price = 175000, seats = 2, trunk = 8, fuel = 55, speed = 215, accel = 9.2 },
    { model = 'penumbra', label = 'Penumbra', brand = 'maibatsu', category = 'sports', price = 45000, seats = 2, trunk = 15, fuel = 50, speed = 170, accel = 7.5 },
    { model = 'penumbra2', label = 'Penumbra FF', brand = 'maibatsu', category = 'sports', price = 85000, seats = 2, trunk = 12, fuel = 48, speed = 180, accel = 8.0 },
    { model = 'rapidgt', label = 'Rapid GT', brand = 'dewbauchee', category = 'sports', price = 125000, seats = 2, trunk = 10, fuel = 55, speed = 185, accel = 8.3 },
    { model = 'rapidgt2', label = 'Rapid GT Cabrio', brand = 'dewbauchee', category = 'sports', price = 140000, seats = 2, trunk = 8, fuel = 52, speed = 182, accel = 8.0 },
    { model = 'raptor', label = 'Raptor', brand = 'bravado', category = 'sports', price = 185000, seats = 2, trunk = 5, fuel = 45, speed = 200, accel = 9.0 },
    { model = 'remus', label = 'Remus', brand = 'annis', category = 'sports', price = 105000, seats = 2, trunk = 12, fuel = 48, speed = 178, accel = 8.0 },
    { model = 'revolter', label = 'Revolter', brand = 'ubermacht', category = 'sports', price = 160000, seats = 4, trunk = 15, fuel = 58, speed = 185, accel = 8.3 },
    { model = 'ruston', label = 'Ruston', brand = 'hijak', category = 'sports', price = 145000, seats = 2, trunk = 5, fuel = 45, speed = 190, accel = 8.6 },
    { model = 'schafter3', label = 'Schafter V12', brand = 'benefactor', category = 'sports', price = 95000, seats = 4, trunk = 25, fuel = 62, speed = 178, accel = 7.8 },
    { model = 'schafter4', label = 'Schafter LWB', brand = 'benefactor', category = 'sports', price = 115000, seats = 4, trunk = 28, fuel = 65, speed = 175, accel = 7.5 },
    { model = 'schlagen', label = 'Schlagen GT', brand = 'benefactor', category = 'sports', price = 175000, seats = 2, trunk = 10, fuel = 55, speed = 195, accel = 8.8 },
    { model = 'schwarzer', label = 'Schwartzer', brand = 'benefactor', category = 'sports', price = 85000, seats = 4, trunk = 18, fuel = 58, speed = 175, accel = 7.8 },
    { model = 'specter', label = 'Specter', brand = 'dewbauchee', category = 'sports', price = 165000, seats = 2, trunk = 10, fuel = 55, speed = 192, accel = 8.6 },
    { model = 'specter2', label = 'Specter Custom', brand = 'dewbauchee', category = 'sports', price = 195000, seats = 2, trunk = 8, fuel = 52, speed = 200, accel = 9.0 },
    { model = 'sultan', label = 'Sultan', brand = 'karin', category = 'sports', price = 35000, seats = 4, trunk = 22, fuel = 55, speed = 172, accel = 7.5 },
    { model = 'sultan2', label = 'Sultan RS', brand = 'karin', category = 'sports', price = 145000, seats = 4, trunk = 18, fuel = 50, speed = 195, accel = 8.8 },
    { model = 'sultan3', label = 'Sultan Clásico', brand = 'karin', category = 'sports', price = 125000, seats = 4, trunk = 20, fuel = 52, speed = 185, accel = 8.3 },
    { model = 'surano', label = 'Surano', brand = 'benefactor', category = 'sports', price = 135000, seats = 2, trunk = 10, fuel = 52, speed = 188, accel = 8.5 },
    { model = 'tropos', label = 'Tropos Rallye', brand = 'lampadati', category = 'sports', price = 115000, seats = 2, trunk = 10, fuel = 50, speed = 175, accel = 8.0 },
    { model = 'vectre', label = 'Vectre', brand = 'emperor', category = 'sports', price = 125000, seats = 2, trunk = 12, fuel = 52, speed = 185, accel = 8.3 },
    { model = 'verlierer2', label = 'Verlierer', brand = 'bravado', category = 'sports', price = 155000, seats = 2, trunk = 8, fuel = 55, speed = 190, accel = 8.5 },
    { model = 'vstr', label = 'V-STR', brand = 'albany', category = 'sports', price = 140000, seats = 4, trunk = 18, fuel = 58, speed = 185, accel = 8.3 },
    { model = 'zr350', label = 'ZR350', brand = 'annis', category = 'sports', price = 110000, seats = 2, trunk = 10, fuel = 48, speed = 180, accel = 8.0 },

    -- ═══════════════════════════════════════════════════════════════
    -- SUPER (45 vehículos)
    -- ═══════════════════════════════════════════════════════════════
    { model = 'adder', label = 'Adder', brand = 'truffade', category = 'super', price = 1000000, seats = 2, trunk = 5, fuel = 60, speed = 220, accel = 9.5 },
    { model = 'autarch', label = 'Autarch', brand = 'overflod', category = 'super', price = 1250000, seats = 2, trunk = 5, fuel = 58, speed = 225, accel = 9.6 },
    { model = 'banshee', label = 'Banshee', brand = 'bravado', category = 'super', price = 105000, seats = 2, trunk = 8, fuel = 55, speed = 195, accel = 8.8 },
    { model = 'bullet', label = 'Bullet', brand = 'vapid', category = 'super', price = 155000, seats = 2, trunk = 5, fuel = 52, speed = 210, accel = 9.2 },
    { model = 'champion', label = 'Champion', brand = 'dewbauchee', category = 'super', price = 2500000, seats = 2, trunk = 4, fuel = 55, speed = 235, accel = 9.8 },
    { model = 'cheetah', label = 'Cheetah', brand = 'grotti', category = 'super', price = 650000, seats = 2, trunk = 5, fuel = 58, speed = 215, accel = 9.3 },
    { model = 'cheetah2', label = 'Cheetah Clásico', brand = 'grotti', category = 'super', price = 850000, seats = 2, trunk = 5, fuel = 55, speed = 205, accel = 9.0 },
    { model = 'cyclone', label = 'Cyclone', brand = 'coil', category = 'super', price = 950000, seats = 2, trunk = 5, fuel = 40, speed = 220, accel = 10.0 },
    { model = 'deveste', label = 'Deveste Eight', brand = 'principe', category = 'super', price = 1500000, seats = 2, trunk = 4, fuel = 55, speed = 235, accel = 9.8 },
    { model = 'emerus', label = 'Emerus', brand = 'progen', category = 'super', price = 1850000, seats = 2, trunk = 5, fuel = 58, speed = 230, accel = 9.7 },
    { model = 'entityxf', label = 'Entity XF', brand = 'overflod', category = 'super', price = 795000, seats = 2, trunk = 5, fuel = 55, speed = 220, accel = 9.5 },
    { model = 'entity2', label = 'Entity XXR', brand = 'overflod', category = 'super', price = 1250000, seats = 2, trunk = 5, fuel = 55, speed = 230, accel = 9.7 },
    { model = 'fmj', label = 'FMJ', brand = 'vapid', category = 'super', price = 1350000, seats = 2, trunk = 4, fuel = 58, speed = 225, accel = 9.6 },
    { model = 'furia', label = 'Furia', brand = 'grotti', category = 'super', price = 1650000, seats = 2, trunk = 5, fuel = 55, speed = 228, accel = 9.7 },
    { model = 'gp1', label = 'GP1', brand = 'progen', category = 'super', price = 1200000, seats = 2, trunk = 4, fuel = 52, speed = 222, accel = 9.5 },
    { model = 'ignus', label = 'Ignus', brand = 'pegassi', category = 'super', price = 2050000, seats = 2, trunk = 4, fuel = 58, speed = 232, accel = 9.8 },
    { model = 'infernus', label = 'Infernus', brand = 'pegassi', category = 'super', price = 440000, seats = 2, trunk = 5, fuel = 55, speed = 210, accel = 9.2 },
    { model = 'italigtb', label = 'Itali GTB', brand = 'progen', category = 'super', price = 850000, seats = 2, trunk = 5, fuel = 55, speed = 218, accel = 9.4 },
    { model = 'italigtb2', label = 'Itali GTB Custom', brand = 'progen', category = 'super', price = 1150000, seats = 2, trunk = 5, fuel = 52, speed = 225, accel = 9.6 },
    { model = 'krieger', label = 'Krieger', brand = 'benefactor', category = 'super', price = 1950000, seats = 2, trunk = 5, fuel = 60, speed = 232, accel = 9.8 },
    { model = 'le7b', label = 'RE-7B', brand = 'annis', category = 'super', price = 1550000, seats = 2, trunk = 3, fuel = 55, speed = 228, accel = 9.7 },
    { model = 'lm87', label = 'LM87', brand = 'ocelot', category = 'super', price = 1450000, seats = 2, trunk = 4, fuel = 58, speed = 225, accel = 9.6 },
    { model = 'nero', label = 'Nero', brand = 'truffade', category = 'super', price = 1150000, seats = 2, trunk = 5, fuel = 60, speed = 220, accel = 9.5 },
    { model = 'nero2', label = 'Nero Custom', brand = 'truffade', category = 'super', price = 1500000, seats = 2, trunk = 5, fuel = 58, speed = 228, accel = 9.7 },
    { model = 'osiris', label = 'Osiris', brand = 'pegassi', category = 'super', price = 950000, seats = 2, trunk = 5, fuel = 55, speed = 218, accel = 9.4 },
    { model = 'penetrator', label = 'Penetrator', brand = 'ocelot', category = 'super', price = 880000, seats = 2, trunk = 5, fuel = 55, speed = 215, accel = 9.3 },
    { model = 'pfister811', label = '811', brand = 'pfister', category = 'super', price = 1050000, seats = 2, trunk = 5, fuel = 52, speed = 225, accel = 9.6 },
    { model = 'prototipo', label = 'X80 Proto', brand = 'grotti', category = 'super', price = 2700000, seats = 2, trunk = 3, fuel = 50, speed = 240, accel = 10.0 },
    { model = 'reaper', label = 'Reaper', brand = 'pegassi', category = 'super', price = 1450000, seats = 2, trunk = 5, fuel = 55, speed = 220, accel = 9.5 },
    { model = 's80', label = 'S80RR', brand = 'annis', category = 'super', price = 1850000, seats = 2, trunk = 3, fuel = 55, speed = 230, accel = 9.7 },
    { model = 'sc1', label = 'SC1', brand = 'ubermacht', category = 'super', price = 1350000, seats = 2, trunk = 5, fuel = 58, speed = 222, accel = 9.5 },
    { model = 'scramjet', label = 'Scramjet', brand = 'declasse', category = 'super', price = 3600000, seats = 2, trunk = 5, fuel = 55, speed = 220, accel = 9.5 },
    { model = 'sheava', label = 'ETR1', brand = 'emperor', category = 'super', price = 1250000, seats = 2, trunk = 5, fuel = 58, speed = 218, accel = 9.4 },
    { model = 'sultanrs', label = 'Sultan RS', brand = 'karin', category = 'super', price = 145000, seats = 4, trunk = 15, fuel = 52, speed = 200, accel = 8.8 },
    { model = 't20', label = 'T20', brand = 'progen', category = 'super', price = 2200000, seats = 2, trunk = 4, fuel = 55, speed = 232, accel = 9.8 },
    { model = 'taipan', label = 'Taipan', brand = 'cheval', category = 'super', price = 1650000, seats = 2, trunk = 4, fuel = 55, speed = 225, accel = 9.6 },
    { model = 'tempesta', label = 'Tempesta', brand = 'pegassi', category = 'super', price = 1250000, seats = 2, trunk = 5, fuel = 55, speed = 222, accel = 9.5 },
    { model = 'tezeract', label = 'Tezeract', brand = 'pegassi', category = 'super', price = 2350000, seats = 2, trunk = 4, fuel = 38, speed = 228, accel = 10.0 },
    { model = 'thrax', label = 'Thrax', brand = 'truffade', category = 'super', price = 1850000, seats = 2, trunk = 5, fuel = 62, speed = 228, accel = 9.7 },
    { model = 'tigon', label = 'Tigon', brand = 'lampadati', category = 'super', price = 1750000, seats = 2, trunk = 4, fuel = 55, speed = 225, accel = 9.6 },
    { model = 'turismor', label = 'Turismo R', brand = 'grotti', category = 'super', price = 500000, seats = 2, trunk = 5, fuel = 55, speed = 218, accel = 9.4 },
    { model = 'tyrant', label = 'Tyrant', brand = 'overflod', category = 'super', price = 1750000, seats = 2, trunk = 5, fuel = 60, speed = 225, accel = 9.6 },
    { model = 'tyrus', label = 'Tyrus', brand = 'progen', category = 'super', price = 1850000, seats = 2, trunk = 3, fuel = 52, speed = 228, accel = 9.7 },
    { model = 'vacca', label = 'Vacca', brand = 'pegassi', category = 'super', price = 240000, seats = 2, trunk = 5, fuel = 55, speed = 205, accel = 9.0 },
    { model = 'vagner', label = 'Vagner', brand = 'dewbauchee', category = 'super', price = 1350000, seats = 2, trunk = 4, fuel = 55, speed = 225, accel = 9.6 },
    { model = 'vigilante', label = 'Vigilante', brand = 'grotti', category = 'super', price = 3750000, seats = 2, trunk = 5, fuel = 55, speed = 230, accel = 9.5 },
    { model = 'visione', label = 'Visione', brand = 'grotti', category = 'super', price = 1450000, seats = 2, trunk = 4, fuel = 55, speed = 222, accel = 9.5 },
    { model = 'voltic', label = 'Voltic', brand = 'coil', category = 'super', price = 150000, seats = 2, trunk = 5, fuel = 35, speed = 195, accel = 9.0 },
    { model = 'voltic2', label = 'Rocket Voltic', brand = 'coil', category = 'super', price = 3830000, seats = 2, trunk = 5, fuel = 35, speed = 215, accel = 9.5 },
    { model = 'xa21', label = 'XA-21', brand = 'ocelot', category = 'super', price = 1750000, seats = 2, trunk = 5, fuel = 58, speed = 228, accel = 9.7 },
    { model = 'zentorno', label = 'Zentorno', brand = 'pegassi', category = 'super', price = 725000, seats = 2, trunk = 5, fuel = 55, speed = 218, accel = 9.4 },
    { model = 'zorrusso', label = 'Zorrusso', brand = 'pegassi', category = 'super', price = 1650000, seats = 2, trunk = 4, fuel = 55, speed = 222, accel = 9.5 },

    -- ═══════════════════════════════════════════════════════════════
    -- MUSCLE (50 vehículos)
    -- ═══════════════════════════════════════════════════════════════
    { model = 'blade', label = 'Blade', brand = 'vapid', category = 'muscle', price = 32000, seats = 2, trunk = 15, fuel = 65, speed = 165, accel = 7.2 },
    { model = 'buccaneer', label = 'Buccaneer', brand = 'albany', category = 'muscle', price = 28000, seats = 2, trunk = 20, fuel = 68, speed = 160, accel = 7.0 },
    { model = 'buccaneer2', label = 'Buccaneer Custom', brand = 'albany', category = 'muscle', price = 55000, seats = 2, trunk = 18, fuel = 65, speed = 168, accel = 7.5 },
    { model = 'chino', label = 'Chino', brand = 'vapid', category = 'muscle', price = 22000, seats = 2, trunk = 22, fuel = 70, speed = 155, accel = 6.5 },
    { model = 'chino2', label = 'Chino Custom', brand = 'vapid', category = 'muscle', price = 45000, seats = 2, trunk = 20, fuel = 68, speed = 162, accel = 7.0 },
    { model = 'clique', label = 'Clique', brand = 'vapid', category = 'muscle', price = 75000, seats = 2, trunk = 15, fuel = 62, speed = 175, accel = 7.8 },
    { model = 'coquette3', label = 'Coquette BlackFin', brand = 'invetero', category = 'muscle', price = 95000, seats = 2, trunk = 12, fuel = 58, speed = 178, accel = 8.0 },
    { model = 'deviant', label = 'Deviant', brand = 'schyster', category = 'muscle', price = 85000, seats = 2, trunk = 15, fuel = 65, speed = 175, accel = 7.8 },
    { model = 'dominator', label = 'Dominator', brand = 'vapid', category = 'muscle', price = 35000, seats = 2, trunk = 18, fuel = 62, speed = 172, accel = 7.5 },
    { model = 'dominator2', label = 'Pisswasser Dominator', brand = 'vapid', category = 'muscle', price = 55000, seats = 2, trunk = 15, fuel = 60, speed = 178, accel = 7.8 },
    { model = 'dominator3', label = 'Dominator GTX', brand = 'vapid', category = 'muscle', price = 125000, seats = 2, trunk = 15, fuel = 58, speed = 185, accel = 8.2 },
    { model = 'dominator4', label = 'Dominator Arena', brand = 'vapid', category = 'muscle', price = 180000, seats = 2, trunk = 10, fuel = 60, speed = 180, accel = 8.0 },
    { model = 'dominator5', label = 'Dominator GTT', brand = 'vapid', category = 'muscle', price = 95000, seats = 2, trunk = 15, fuel = 60, speed = 178, accel = 7.8 },
    { model = 'dominator6', label = 'Dominator ASP', brand = 'vapid', category = 'muscle', price = 115000, seats = 2, trunk = 14, fuel = 58, speed = 182, accel = 8.0 },
    { model = 'dukes', label = 'Dukes', brand = 'imponte', category = 'muscle', price = 62000, seats = 2, trunk = 18, fuel = 65, speed = 175, accel = 7.8 },
    { model = 'dukes2', label = 'Duke O\'Death', brand = 'imponte', category = 'muscle', price = 125000, seats = 2, trunk = 15, fuel = 68, speed = 172, accel = 7.5, armor = 40 },
    { model = 'dukes3', label = 'Beater Dukes', brand = 'imponte', category = 'muscle', price = 35000, seats = 2, trunk = 18, fuel = 62, speed = 168, accel = 7.2 },
    { model = 'ellie', label = 'Ellie', brand = 'vapid', category = 'muscle', price = 85000, seats = 2, trunk = 15, fuel = 60, speed = 175, accel = 7.8 },
    { model = 'faction', label = 'Faction', brand = 'willard', category = 'muscle', price = 25000, seats = 2, trunk = 20, fuel = 65, speed = 158, accel = 6.8 },
    { model = 'faction2', label = 'Faction Custom', brand = 'willard', category = 'muscle', price = 50000, seats = 2, trunk = 18, fuel = 62, speed = 165, accel = 7.2 },
    { model = 'faction3', label = 'Faction Donk', brand = 'willard', category = 'muscle', price = 65000, seats = 2, trunk = 18, fuel = 60, speed = 155, accel = 6.5 },
    { model = 'gauntlet', label = 'Gauntlet', brand = 'bravado', category = 'muscle', price = 32000, seats = 2, trunk = 18, fuel = 62, speed = 172, accel = 7.5 },
    { model = 'gauntlet2', label = 'Redwood Gauntlet', brand = 'bravado', category = 'muscle', price = 45000, seats = 2, trunk = 16, fuel = 60, speed = 175, accel = 7.8 },
    { model = 'gauntlet3', label = 'Gauntlet Clásico', brand = 'bravado', category = 'muscle', price = 75000, seats = 2, trunk = 15, fuel = 58, speed = 170, accel = 7.5 },
    { model = 'gauntlet4', label = 'Gauntlet Hellfire', brand = 'bravado', category = 'muscle', price = 125000, seats = 2, trunk = 15, fuel = 60, speed = 185, accel = 8.2 },
    { model = 'gauntlet5', label = 'Gauntlet Clásico Custom', brand = 'bravado', category = 'muscle', price = 95000, seats = 2, trunk = 15, fuel = 58, speed = 178, accel = 8.0 },
    { model = 'hermes', label = 'Hermes', brand = 'albany', category = 'muscle', price = 45000, seats = 2, trunk = 22, fuel = 70, speed = 155, accel = 6.5 },
    { model = 'hotknife', label = 'Hotknife', brand = 'vapid', category = 'muscle', price = 90000, seats = 2, trunk = 5, fuel = 55, speed = 170, accel = 7.5 },
    { model = 'hustler', label = 'Hustler', brand = 'vapid', category = 'muscle', price = 75000, seats = 2, trunk = 10, fuel = 58, speed = 165, accel = 7.2 },
    { model = 'impaler', label = 'Impaler', brand = 'declasse', category = 'muscle', price = 55000, seats = 2, trunk = 18, fuel = 65, speed = 172, accel = 7.5 },
    { model = 'impaler2', label = 'Impaler Arena', brand = 'declasse', category = 'muscle', price = 150000, seats = 2, trunk = 12, fuel = 62, speed = 178, accel = 7.8 },
    { model = 'imperator', label = 'Imperator Arena', brand = 'declasse', category = 'muscle', price = 200000, seats = 2, trunk = 10, fuel = 65, speed = 175, accel = 7.5 },
    { model = 'lurcher', label = 'Lurcher', brand = 'albany', category = 'muscle', price = 35000, seats = 2, trunk = 50, fuel = 68, speed = 150, accel = 6.0 },
    { model = 'moonbeam', label = 'Moonbeam', brand = 'declasse', category = 'muscle', price = 22000, seats = 4, trunk = 35, fuel = 62, speed = 150, accel = 6.0 },
    { model = 'moonbeam2', label = 'Moonbeam Custom', brand = 'declasse', category = 'muscle', price = 45000, seats = 4, trunk = 32, fuel = 60, speed = 158, accel = 6.5 },
    { model = 'nightshade', label = 'Nightshade', brand = 'imponte', category = 'muscle', price = 72000, seats = 2, trunk = 15, fuel = 58, speed = 172, accel = 7.5 },
    { model = 'peyote2', label = 'Peyote Gasser', brand = 'vapid', category = 'muscle', price = 55000, seats = 2, trunk = 8, fuel = 55, speed = 175, accel = 8.0 },
    { model = 'phoenix', label = 'Phoenix', brand = 'imponte', category = 'muscle', price = 28000, seats = 2, trunk = 18, fuel = 60, speed = 168, accel = 7.2 },
    { model = 'picador', label = 'Picador', brand = 'cheval', category = 'muscle', price = 18000, seats = 2, trunk = 45, fuel = 65, speed = 155, accel = 6.5 },
    { model = 'ratloader', label = 'Rat-Loader', brand = 'bravado', category = 'muscle', price = 8000, seats = 2, trunk = 40, fuel = 70, speed = 135, accel = 5.5 },
    { model = 'ratloader2', label = 'Rat-Truck', brand = 'bravado', category = 'muscle', price = 15000, seats = 2, trunk = 45, fuel = 72, speed = 140, accel = 5.8 },
    { model = 'ruiner', label = 'Ruiner', brand = 'imponte', category = 'muscle', price = 35000, seats = 2, trunk = 15, fuel = 60, speed = 168, accel = 7.2 },
    { model = 'ruiner2', label = 'Ruiner 2000', brand = 'imponte', category = 'muscle', price = 4320000, seats = 2, trunk = 10, fuel = 55, speed = 185, accel = 8.5 },
    { model = 'ruiner3', label = 'Ruiner Destrozado', brand = 'imponte', category = 'muscle', price = 15000, seats = 2, trunk = 15, fuel = 58, speed = 155, accel = 6.5 },
    { model = 'sabregt', label = 'Sabre Turbo', brand = 'declasse', category = 'muscle', price = 38000, seats = 2, trunk = 15, fuel = 62, speed = 170, accel = 7.5 },
    { model = 'sabregt2', label = 'Sabre Turbo Custom', brand = 'declasse', category = 'muscle', price = 65000, seats = 2, trunk = 15, fuel = 60, speed = 178, accel = 7.8 },
    { model = 'slamvan', label = 'Slamvan', brand = 'vapid', category = 'muscle', price = 45000, seats = 2, trunk = 35, fuel = 68, speed = 152, accel = 6.2 },
    { model = 'slamvan2', label = 'Lost Slamvan', brand = 'vapid', category = 'muscle', price = 75000, seats = 2, trunk = 32, fuel = 65, speed = 158, accel = 6.5 },
    { model = 'slamvan3', label = 'Slamvan Custom', brand = 'vapid', category = 'muscle', price = 85000, seats = 2, trunk = 30, fuel = 62, speed = 162, accel = 6.8 },
    { model = 'stalion', label = 'Stallion', brand = 'declasse', category = 'muscle', price = 42000, seats = 2, trunk = 15, fuel = 60, speed = 168, accel = 7.2 },
    { model = 'stalion2', label = 'Burger Shot Stallion', brand = 'declasse', category = 'muscle', price = 55000, seats = 2, trunk = 15, fuel = 58, speed = 172, accel = 7.5 },
    { model = 'tampa', label = 'Tampa', brand = 'declasse', category = 'muscle', price = 38000, seats = 2, trunk = 15, fuel = 58, speed = 168, accel = 7.2 },
    { model = 'tampa2', label = 'Drift Tampa', brand = 'declasse', category = 'muscle', price = 95000, seats = 2, trunk = 12, fuel = 55, speed = 175, accel = 7.8 },
    { model = 'tampa3', label = 'Weaponized Tampa', brand = 'declasse', category = 'muscle', price = 1975000, seats = 2, trunk = 10, fuel = 55, speed = 178, accel = 7.8 },
    { model = 'tulip', label = 'Tulip', brand = 'declasse', category = 'muscle', price = 72000, seats = 2, trunk = 18, fuel = 62, speed = 170, accel = 7.5 },
    { model = 'vamos', label = 'Vamos', brand = 'declasse', category = 'muscle', price = 58000, seats = 2, trunk = 15, fuel = 60, speed = 172, accel = 7.5 },
    { model = 'vigero', label = 'Vigero', brand = 'declasse', category = 'muscle', price = 32000, seats = 2, trunk = 18, fuel = 62, speed = 165, accel = 7.0 },
    { model = 'vigero2', label = 'Vigero ZX', brand = 'declasse', category = 'muscle', price = 95000, seats = 2, trunk = 15, fuel = 58, speed = 182, accel = 8.0 },
    { model = 'virgo', label = 'Virgo', brand = 'albany', category = 'muscle', price = 25000, seats = 2, trunk = 22, fuel = 68, speed = 155, accel = 6.5 },
    { model = 'virgo2', label = 'Virgo Clásico Custom', brand = 'dundreary', category = 'muscle', price = 52000, seats = 2, trunk = 20, fuel = 65, speed = 162, accel = 7.0 },
    { model = 'virgo3', label = 'Virgo Clásico', brand = 'dundreary', category = 'muscle', price = 42000, seats = 2, trunk = 22, fuel = 68, speed = 158, accel = 6.8 },
    { model = 'voodoo', label = 'Voodoo', brand = 'declasse', category = 'muscle', price = 18000, seats = 2, trunk = 25, fuel = 70, speed = 148, accel = 5.8 },
    { model = 'voodoo2', label = 'Voodoo Custom', brand = 'declasse', category = 'muscle', price = 35000, seats = 2, trunk = 22, fuel = 68, speed = 155, accel = 6.2 },
    { model = 'yosemite', label = 'Yosemite', brand = 'declasse', category = 'muscle', price = 55000, seats = 2, trunk = 50, fuel = 65, speed = 162, accel = 6.8 },
    { model = 'yosemite2', label = 'Yosemite Drift', brand = 'declasse', category = 'muscle', price = 85000, seats = 2, trunk = 45, fuel = 62, speed = 170, accel = 7.5 },

    -- ═══════════════════════════════════════════════════════════════
    -- MOTOCICLETAS (55 vehículos)
    -- ═══════════════════════════════════════════════════════════════
    { model = 'akuma', label = 'Akuma', brand = 'dinka', category = 'motorcycles', price = 15000, seats = 2, trunk = 0, fuel = 18, speed = 185, accel = 9.0 },
    { model = 'avarus', label = 'Avarus', brand = 'lchallenges', category = 'motorcycles', price = 35000, seats = 2, trunk = 0, fuel = 20, speed = 165, accel = 7.5 },
    { model = 'bagger', label = 'Bagger', brand = 'western', category = 'motorcycles', price = 28000, seats = 2, trunk = 5, fuel = 22, speed = 160, accel = 7.0 },
    { model = 'bati', label = 'Bati 801', brand = 'pegassi', category = 'motorcycles', price = 25000, seats = 2, trunk = 0, fuel = 16, speed = 190, accel = 9.2 },
    { model = 'bati2', label = 'Bati 801RR', brand = 'pegassi', category = 'motorcycles', price = 32000, seats = 2, trunk = 0, fuel = 16, speed = 195, accel = 9.4 },
    { model = 'bf400', label = 'BF400', brand = 'nagasaki', category = 'motorcycles', price = 18000, seats = 2, trunk = 0, fuel = 14, speed = 165, accel = 8.0 },
    { model = 'carbonrs', label = 'Carbon RS', brand = 'nagasaki', category = 'motorcycles', price = 28000, seats = 2, trunk = 0, fuel = 15, speed = 185, accel = 9.0 },
    { model = 'chimera', label = 'Chimera', brand = 'nagasaki', category = 'motorcycles', price = 65000, seats = 2, trunk = 5, fuel = 25, speed = 155, accel = 7.0 },
    { model = 'cliffhanger', label = 'Cliffhanger', brand = 'western', category = 'motorcycles', price = 45000, seats = 2, trunk = 0, fuel = 20, speed = 168, accel = 8.2 },
    { model = 'daemon', label = 'Daemon', brand = 'western', category = 'motorcycles', price = 22000, seats = 2, trunk = 0, fuel = 20, speed = 158, accel = 7.2 },
    { model = 'daemon2', label = 'Daemon Custom', brand = 'western', category = 'motorcycles', price = 35000, seats = 2, trunk = 0, fuel = 18, speed = 165, accel = 7.8 },
    { model = 'defiler', label = 'Defiler', brand = 'shitzu', category = 'motorcycles', price = 28000, seats = 2, trunk = 0, fuel = 16, speed = 172, accel = 8.5 },
    { model = 'deathbike', label = 'Deathbike', brand = 'western', category = 'motorcycles', price = 150000, seats = 2, trunk = 0, fuel = 18, speed = 175, accel = 8.5 },
    { model = 'diablous', label = 'Diabolus', brand = 'principe', category = 'motorcycles', price = 55000, seats = 2, trunk = 0, fuel = 18, speed = 178, accel = 8.8 },
    { model = 'diablous2', label = 'Diabolus Custom', brand = 'principe', category = 'motorcycles', price = 75000, seats = 2, trunk = 0, fuel = 16, speed = 182, accel = 9.0 },
    { model = 'double', label = 'Double T', brand = 'dinka', category = 'motorcycles', price = 22000, seats = 2, trunk = 0, fuel = 17, speed = 180, accel = 8.8 },
    { model = 'enduro', label = 'Enduro', brand = 'dinka', category = 'motorcycles', price = 12000, seats = 2, trunk = 0, fuel = 14, speed = 145, accel = 7.0 },
    { model = 'esskey', label = 'Esskey', brand = 'pegassi', category = 'motorcycles', price = 18000, seats = 2, trunk = 0, fuel = 16, speed = 155, accel = 7.5 },
    { model = 'faggio', label = 'Faggio', brand = 'pegassi', category = 'motorcycles', price = 5000, seats = 2, trunk = 2, fuel = 10, speed = 100, accel = 4.5 },
    { model = 'faggio2', label = 'Faggio Sport', brand = 'pegassi', category = 'motorcycles', price = 8000, seats = 2, trunk = 2, fuel = 12, speed = 115, accel = 5.0 },
    { model = 'faggio3', label = 'Faggio Mod', brand = 'pegassi', category = 'motorcycles', price = 12000, seats = 2, trunk = 3, fuel = 12, speed = 110, accel = 4.8 },
    { model = 'fcr', label = 'FCR 1000', brand = 'pegassi', category = 'motorcycles', price = 22000, seats = 2, trunk = 0, fuel = 16, speed = 175, accel = 8.5 },
    { model = 'fcr2', label = 'FCR 1000 Custom', brand = 'pegassi', category = 'motorcycles', price = 35000, seats = 2, trunk = 0, fuel = 15, speed = 180, accel = 8.8 },
    { model = 'gargoyle', label = 'Gargoyle', brand = 'western', category = 'motorcycles', price = 45000, seats = 2, trunk = 0, fuel = 18, speed = 162, accel = 8.0 },
    { model = 'hakuchou', label = 'Hakuchou', brand = 'shitzu', category = 'motorcycles', price = 48000, seats = 2, trunk = 0, fuel = 18, speed = 195, accel = 9.2 },
    { model = 'hakuchou2', label = 'Hakuchou Drag', brand = 'shitzu', category = 'motorcycles', price = 85000, seats = 2, trunk = 0, fuel = 16, speed = 210, accel = 9.6 },
    { model = 'hexer', label = 'Hexer', brand = 'lchallenges', category = 'motorcycles', price = 32000, seats = 2, trunk = 0, fuel = 22, speed = 155, accel = 7.0 },
    { model = 'innovation', label = 'Innovation', brand = 'lchallenges', category = 'motorcycles', price = 42000, seats = 2, trunk = 0, fuel = 20, speed = 160, accel = 7.2 },
    { model = 'lectro', label = 'Lectro', brand = 'principe', category = 'motorcycles', price = 55000, seats = 2, trunk = 0, fuel = 12, speed = 175, accel = 8.8 },
    { model = 'manchez', label = 'Manchez', brand = 'maibatsu', category = 'motorcycles', price = 15000, seats = 2, trunk = 0, fuel = 14, speed = 155, accel = 7.5 },
    { model = 'manchez2', label = 'Manchez Scout', brand = 'maibatsu', category = 'motorcycles', price = 22000, seats = 2, trunk = 0, fuel = 15, speed = 160, accel = 7.8 },
    { model = 'nemesis', label = 'Nemesis', brand = 'principe', category = 'motorcycles', price = 18000, seats = 2, trunk = 0, fuel = 14, speed = 170, accel = 8.5 },
    { model = 'nightblade', label = 'Nightblade', brand = 'western', category = 'motorcycles', price = 52000, seats = 2, trunk = 0, fuel = 20, speed = 158, accel = 7.5 },
    { model = 'oppressor', label = 'Oppressor', brand = 'pegassi', category = 'motorcycles', price = 3525000, seats = 2, trunk = 0, fuel = 15, speed = 185, accel = 9.0 },
    { model = 'oppressor2', label = 'Oppressor Mk II', brand = 'pegassi', category = 'motorcycles', price = 3890000, seats = 2, trunk = 0, fuel = 12, speed = 180, accel = 8.8 },
    { model = 'pcj', label = 'PCJ 600', brand = 'shitzu', category = 'motorcycles', price = 18000, seats = 2, trunk = 0, fuel = 16, speed = 175, accel = 8.5 },
    { model = 'ratbike', label = 'Rat Bike', brand = 'western', category = 'motorcycles', price = 8000, seats = 2, trunk = 0, fuel = 18, speed = 145, accel = 6.5 },
    { model = 'reever', label = 'Reever', brand = 'western', category = 'motorcycles', price = 95000, seats = 2, trunk = 0, fuel = 16, speed = 195, accel = 9.2 },
    { model = 'rrocket', label = 'Rampant Rocket', brand = 'western', category = 'motorcycles', price = 85000, seats = 2, trunk = 0, fuel = 18, speed = 165, accel = 8.0 },
    { model = 'ruffian', label = 'Ruffian', brand = 'pegassi', category = 'motorcycles', price = 15000, seats = 2, trunk = 0, fuel = 15, speed = 168, accel = 8.2 },
    { model = 'sanchez', label = 'Sanchez', brand = 'maibatsu', category = 'motorcycles', price = 12000, seats = 2, trunk = 0, fuel = 12, speed = 150, accel = 7.5 },
    { model = 'sanchez2', label = 'Sanchez Livery', brand = 'maibatsu', category = 'motorcycles', price = 15000, seats = 2, trunk = 0, fuel = 12, speed = 152, accel = 7.8 },
    { model = 'sanctus', label = 'Sanctus', brand = 'lchallenges', category = 'motorcycles', price = 195000, seats = 2, trunk = 0, fuel = 20, speed = 155, accel = 7.0 },
    { model = 'shinobi', label = 'Shinobi', brand = 'nagasaki', category = 'motorcycles', price = 115000, seats = 2, trunk = 0, fuel = 15, speed = 200, accel = 9.4 },
    { model = 'shotaro', label = 'Shotaro', brand = 'nagasaki', category = 'motorcycles', price = 2225000, seats = 2, trunk = 0, fuel = 12, speed = 195, accel = 9.5 },
    { model = 'sovereign', label = 'Sovereign', brand = 'western', category = 'motorcycles', price = 55000, seats = 2, trunk = 5, fuel = 22, speed = 155, accel = 7.0 },
    { model = 'stryder', label = 'Stryder', brand = 'nagasaki', category = 'motorcycles', price = 65000, seats = 2, trunk = 0, fuel = 14, speed = 172, accel = 8.5 },
    { model = 'thrust', label = 'Thrust', brand = 'dinka', category = 'motorcycles', price = 35000, seats = 2, trunk = 0, fuel = 16, speed = 178, accel = 8.8 },
    { model = 'vader', label = 'Vader', brand = 'shitzu', category = 'motorcycles', price = 15000, seats = 2, trunk = 0, fuel = 15, speed = 170, accel = 8.2 },
    { model = 'vindicator', label = 'Vindicator', brand = 'dinka', category = 'motorcycles', price = 42000, seats = 2, trunk = 0, fuel = 14, speed = 175, accel = 8.8 },
    { model = 'vortex', label = 'Vortex', brand = 'pegassi', category = 'motorcycles', price = 28000, seats = 2, trunk = 0, fuel = 16, speed = 168, accel = 8.0 },
    { model = 'wolfsbane', label = 'Wolfsbane', brand = 'western', category = 'motorcycles', price = 35000, seats = 2, trunk = 0, fuel = 18, speed = 162, accel = 7.8 },
    { model = 'zombiea', label = 'Zombie Bobber', brand = 'western', category = 'motorcycles', price = 38000, seats = 2, trunk = 0, fuel = 18, speed = 158, accel = 7.5 },
    { model = 'zombieb', label = 'Zombie Chopper', brand = 'western', category = 'motorcycles', price = 42000, seats = 2, trunk = 0, fuel = 20, speed = 155, accel = 7.2 },

    -- ═══════════════════════════════════════════════════════════════
    -- EMERGENCIAS (restringidos)
    -- ═══════════════════════════════════════════════════════════════
    { model = 'ambulance', label = 'Ambulancia', brand = 'brute', category = 'emergency', price = 0, seats = 4, trunk = 50, fuel = 75, speed = 155, accel = 6.0, restricted = true, job = 'ambulance' },
    { model = 'firetruk', label = 'Camión Bomberos', brand = 'mtl', category = 'emergency', price = 0, seats = 4, trunk = 80, fuel = 100, speed = 130, accel = 4.5, restricted = true, job = 'fire' },
    { model = 'lguard', label = 'Socorrista', brand = 'declasse', category = 'emergency', price = 0, seats = 2, trunk = 20, fuel = 55, speed = 145, accel = 6.0, restricted = true, job = 'ambulance' },
    { model = 'police', label = 'Policía Patrulla', brand = 'vapid', category = 'emergency', price = 0, seats = 4, trunk = 30, fuel = 70, speed = 180, accel = 8.0, restricted = true, job = 'police' },
    { model = 'police2', label = 'Policía Buffalo', brand = 'bravado', category = 'emergency', price = 0, seats = 4, trunk = 28, fuel = 68, speed = 185, accel = 8.2, restricted = true, job = 'police' },
    { model = 'police3', label = 'Policía Interceptor', brand = 'vapid', category = 'emergency', price = 0, seats = 4, trunk = 25, fuel = 65, speed = 190, accel = 8.5, restricted = true, job = 'police' },
    { model = 'police4', label = 'Policía Sin Marcas', brand = 'vapid', category = 'emergency', price = 0, seats = 4, trunk = 28, fuel = 68, speed = 188, accel = 8.3, restricted = true, job = 'police' },
    { model = 'policeb', label = 'Moto Policía', brand = 'western', category = 'emergency', price = 0, seats = 2, trunk = 5, fuel = 20, speed = 185, accel = 9.0, restricted = true, job = 'police' },
    { model = 'policet', label = 'Camioneta Policía', brand = 'declasse', category = 'emergency', price = 0, seats = 4, trunk = 40, fuel = 80, speed = 160, accel = 6.5, restricted = true, job = 'police' },
    { model = 'polmav', label = 'Helicóptero Policía', brand = 'buckingham', category = 'helicopters', price = 0, seats = 4, trunk = 20, fuel = 120, speed = 220, accel = 7.0, restricted = true, job = 'police' },
    { model = 'predator', label = 'Lancha Policía', brand = 'nagasaki', category = 'boats', price = 0, seats = 4, trunk = 15, fuel = 80, speed = 90, accel = 7.0, restricted = true, job = 'police' },
    { model = 'riot', label = 'Antidisturbios', brand = 'brute', category = 'emergency', price = 0, seats = 8, trunk = 60, fuel = 90, speed = 140, accel = 5.0, restricted = true, job = 'police' },
    { model = 'riot2', label = 'Antidisturbios Blindado', brand = 'brute', category = 'emergency', price = 0, seats = 8, trunk = 50, fuel = 95, speed = 135, accel = 4.8, restricted = true, job = 'police', armor = 70 },
    { model = 'sheriff', label = 'Sheriff', brand = 'vapid', category = 'emergency', price = 0, seats = 4, trunk = 30, fuel = 70, speed = 178, accel = 8.0, restricted = true, job = 'sheriff' },
    { model = 'sheriff2', label = 'Sheriff SUV', brand = 'vapid', category = 'emergency', price = 0, seats = 4, trunk = 35, fuel = 75, speed = 172, accel = 7.5, restricted = true, job = 'sheriff' },
}

-- Función para obtener vehículo por modelo
function AIT.Data.Vehicles.GetByModel(model)
    for _, vehicle in ipairs(AIT.Data.Vehicles.List) do
        if vehicle.model == model then
            return vehicle
        end
    end
    return nil
end

-- Función para obtener vehículos por categoría
function AIT.Data.Vehicles.GetByCategory(category)
    local vehicles = {}
    for _, vehicle in ipairs(AIT.Data.Vehicles.List) do
        if vehicle.category == category then
            table.insert(vehicles, vehicle)
        end
    end
    return vehicles
end

-- Función para obtener vehículos por marca
function AIT.Data.Vehicles.GetByBrand(brand)
    local vehicles = {}
    for _, vehicle in ipairs(AIT.Data.Vehicles.List) do
        if vehicle.brand == brand then
            table.insert(vehicles, vehicle)
        end
    end
    return vehicles
end

-- Función para obtener vehículos no restringidos
function AIT.Data.Vehicles.GetPublic()
    local vehicles = {}
    for _, vehicle in ipairs(AIT.Data.Vehicles.List) do
        if not vehicle.restricted then
            table.insert(vehicles, vehicle)
        end
    end
    return vehicles
end

-- Función para obtener vehículos por rango de precio
function AIT.Data.Vehicles.GetByPriceRange(minPrice, maxPrice)
    local vehicles = {}
    for _, vehicle in ipairs(AIT.Data.Vehicles.List) do
        if vehicle.price >= minPrice and vehicle.price <= maxPrice and not vehicle.restricted then
            table.insert(vehicles, vehicle)
        end
    end
    return vehicles
end

return AIT.Data.Vehicles
