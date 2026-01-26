# 🎮 AIT-QB - Advanced Intelligence Technology

<div align="center">

![AIT-QB Logo](https://img.shields.io/badge/AIT--QB-Framework-purple?style=for-the-badge&logo=lua&logoColor=white)
![Version](https://img.shields.io/badge/Version-1.0.0-blue?style=for-the-badge)
![FiveM](https://img.shields.io/badge/FiveM-Compatible-orange?style=for-the-badge)
![QBCore](https://img.shields.io/badge/QBCore-Framework-green?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-blue?style=for-the-badge&logo=lua)

**Framework completo de servidor FiveM Roleplay para 2048 slots**

[📖 Documentación](#-documentación) •
[🚀 Instalación](#-instalación) •
[⚙️ Configuración](#️-configuración) •
[📝 Características](#-características)

</div>

---

## 📝 Características

### 🏗️ Core Engine
- ✅ **Dependency Injection (DI)** - Sistema de inyección de dependencias
- ✅ **Event Bus** - Sistema de eventos desacoplado
- ✅ **State Management** - Gestión de estado centralizada
- ✅ **Cache System** - Sistema de caché con TTL
- ✅ **RBAC** - Control de acceso basado en roles
- ✅ **Rate Limiting** - Protección contra spam
- ✅ **Audit Logging** - Registro de acciones

### 💼 10 Engines Completos
| Engine | Descripción |
|--------|-------------|
| 💰 **Economy** | Sistema de dinero, bancos, transacciones |
| 📦 **Inventory** | Inventario con drag & drop, stashes |
| 👥 **Factions** | Sistema de facciones y gestión |
| 🎯 **Missions** | Misiones dinámicas y procedurales |
| 🎉 **Events** | Eventos del servidor programables |
| 🚗 **Vehicles** | Garajes, llaves, combustible |
| 🏠 **Housing** | Propiedades, alquileres, muebles |
| ⚔️ **Combat** | Sistema de combate y muerte |
| 🤖 **AI** | NPCs inteligentes y comportamiento |
| ⚖️ **Justice** | Sistema de multas, cárcel, wanted |

### 💼 15 Jobs (9 Legales + 6 Ilegales)

#### Jobs Legales
| Job | Descripción |
|-----|-------------|
| 👮 Police | Policía completa con MDT, esposas, multas |
| 🚑 Ambulance | EMS con revivir, camilla, farmacia |
| 🔧 Mechanic | Taller de reparación y tuning |
| 🚕 Taxi | Sistema de taxímetro y carreras |
| 🚛 Trucker | Transporte de mercancías |
| 🗑️ Garbage | Recolección de basura |
| 🎣 Fishing | Pesca con niveles y zonas |
| ⛏️ Mining | Minería y refinería |
| 🪓 Lumberjack | Tala de árboles |
| 🦌 Hunting | Caza de animales |
| 📦 Delivery | Sistema de paquetería |

#### Jobs Ilegales
| Job | Descripción |
|-----|-------------|
| 💊 Drugs | Weed, Cocaína, Metanfetamina |
| 🔓 Robbery | Tiendas, casas, bancos, joyería |
| 🚗 ChopShop | Desguace de vehículos |
| 🔫 Weapons | Tráfico y fabricación de armas |
| 💸 Laundering | Lavado de dinero |
| 👥 Gangs | Bandas con territorios y guerras |

### 📱 Sistemas Adicionales
- ✅ **Teléfono** - 22 apps (llamadas, SMS, banco, GPS, Twitter, crypto...)
- ✅ **Propiedades** - Compra, venta, alquiler, muebles
- ✅ **Admin Panel** - Comandos completos y menú
- ✅ **Scoreboard** - Lista de jugadores (TAB)
- ✅ **Loading Screen** - Pantalla de carga personalizada
- ✅ **Anticheat** - Protección básica

---

## 🚀 Instalación

### Requisitos
- FiveM Server (última versión)
- QBCore Framework
- oxmysql
- ox_lib
- MySQL/MariaDB

### Pasos

1. **Clonar el repositorio**
```bash
git clone https://github.com/ramakjama/AIT-QB.git
cd AIT-QB
```

2. **Copiar a resources**
```bash
cp -r ait-qb [tu-servidor]/resources/[qb]/
```

3. **Importar base de datos**
```bash
mysql -u root -p tu_base_de_datos < install.sql
```

4. **Añadir a server.cfg**
```cfg
ensure qb-core
ensure oxmysql
ensure ox_lib
ensure ait-qb
```

5. **Reiniciar servidor**
```bash
./run.sh +exec server.cfg
```

---

## ⚙️ Configuración

### Archivos de configuración principales

```
shared/config/
├── main.lua        # Configuración general
├── economy.lua     # Economía y precios
├── jobs.lua        # Configuración de trabajos
├── vehicles.lua    # Configuración de vehículos
├── security.lua    # Configuración de seguridad
└── anticheat.lua   # Configuración de anticheat
```

### Ejemplo de configuración

```lua
-- shared/config/main.lua
Config = {}

Config.ServerName = "AIT-QB Roleplay"
Config.MaxPlayers = 2048
Config.DefaultLanguage = "es"

Config.StartingMoney = {
    cash = 5000,
    bank = 10000,
}

Config.Spawn = {
    x = -269.4,
    y = -955.3,
    z = 31.2,
    heading = 205.0,
}
```

---

## 📁 Estructura de archivos

```
ait-qb/
├── admin/                    # Sistema de administración
├── bridges/                  # Bridges para compatibilidad
├── client/                   # Scripts del cliente
│   └── modules/
│       ├── admin/            # Menú admin cliente
│       ├── anticheat/        # Anticheat cliente
│       ├── character/        # Selección de personaje
│       ├── housing/          # Sistema de propiedades
│       ├── hud/              # HUD del jugador
│       ├── interactions/     # Sistema de interacciones
│       ├── inventory/        # Inventario UI
│       ├── phone/            # Sistema de teléfono
│       ├── scoreboard/       # Lista de jugadores
│       └── vehicles/         # Sistema de vehículos
├── core/                     # Core engine
├── data/                     # Datos estáticos
│   ├── items/                # Definición de items
│   ├── jobs/                 # Catálogo de trabajos
│   ├── loot/                 # Tablas de loot
│   └── vehicles/             # Catálogo de vehículos
├── modules/
│   └── jobs/                 # Todos los jobs
│       ├── ambulance/
│       ├── chopshop/
│       ├── delivery/
│       ├── drugs/
│       ├── fishing/
│       ├── gangs/
│       ├── garbage/
│       ├── hunting/
│       ├── laundering/
│       ├── lumberjack/
│       ├── mechanic/
│       ├── mining/
│       ├── police/
│       ├── robbery/
│       ├── taxi/
│       ├── trucker/
│       └── weapons/
├── server/                   # Scripts del servidor
│   ├── db/                   # Repositorios de DB
│   ├── engines/              # 10 engines del servidor
│   └── handlers/             # Handlers de eventos
├── shared/                   # Compartido cliente/servidor
│   ├── config/               # Configuraciones
│   ├── enums/                # Enumeraciones
│   ├── locales/              # Traducciones
│   ├── schemas/              # Schemas de validación
│   └── utils/                # Utilidades
├── ui/                       # NUI (HTML/CSS/JS)
│   ├── index.html            # UI principal
│   ├── app.js                # JavaScript
│   └── loading.html          # Pantalla de carga
├── fxmanifest.lua            # Manifest del recurso
├── install.sql               # Script de instalación DB
└── README.md                 # Este archivo
```

---

## 🔧 Comandos de Admin

| Comando | Permiso | Descripción |
|---------|---------|-------------|
| `/admin` | Helper+ | Abrir menú admin |
| `/kick [id] [razón]` | Mod+ | Expulsar jugador |
| `/ban [id] [duración] [razón]` | Admin+ | Banear jugador |
| `/unban [citizenid]` | Admin+ | Desbanear jugador |
| `/warn [id] [razón]` | Helper+ | Advertir jugador |
| `/tp [id]` | Mod+ | Teleportarse a jugador |
| `/bring [id]` | Mod+ | Traer jugador |
| `/tpcoords [x] [y] [z]` | Mod+ | Teleport a coords |
| `/tpwaypoint` | Mod+ | Teleport a waypoint |
| `/heal [id]` | Helper+ | Curar jugador |
| `/revive [id]` | Helper+ | Revivir jugador |
| `/noclip` | Mod+ | Activar noclip |
| `/god` | Admin+ | Modo dios |
| `/invisible` | Mod+ | Hacerse invisible |
| `/car [modelo]` | Admin+ | Spawnear vehículo |
| `/dv` | Mod+ | Eliminar vehículo |
| `/fix` | Mod+ | Reparar vehículo |
| `/givemoney [id] [tipo] [cantidad]` | Admin+ | Dar dinero |
| `/giveitem [id] [item] [cantidad]` | Admin+ | Dar item |
| `/setjob [id] [job] [grade]` | Admin+ | Establecer trabajo |
| `/announce [mensaje]` | Mod+ | Anuncio del servidor |
| `/tiempo [hora]` | Admin+ | Cambiar hora |
| `/clima [tipo]` | Admin+ | Cambiar clima |

---

## 📊 Estadísticas del Proyecto

| Métrica | Valor |
|---------|-------|
| **Archivos de código** | 120+ |
| **Líneas de código** | 90,000+ |
| **Jobs implementados** | 15 |
| **Engines del servidor** | 10 |
| **Apps del teléfono** | 22 |
| **Propiedades** | 16 |
| **Idiomas** | ES, EN |

---

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

---

## 📞 Soporte

- **Discord**: [discord.gg/tu-servidor](https://discord.gg/)
- **Issues**: [GitHub Issues](https://github.com/ramakjama/AIT-QB/issues)

---

<div align="center">

**Hecho con ❤️ por el equipo de AIT-QB**

![Made with Lua](https://img.shields.io/badge/Made%20with-Lua-blue?style=flat-square&logo=lua)
![FiveM](https://img.shields.io/badge/FiveM-Server-orange?style=flat-square)

</div>
