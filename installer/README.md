# 🚀 Instalador AIT-QB

## ¿Qué es esto?

El instalador de AIT-QB es un sistema interactivo que te ayuda a configurar tu servidor paso a paso, **evitando crashes** por sobrecarga de módulos.

---

## 🔴 IMPORTANTE - ¿Por qué necesitas esto?

AIT-QB es un framework **MUY COMPLETO** con:
- 10 Engines del servidor
- 15 Jobs (legales e ilegales)
- 22 Apps del teléfono
- Múltiples módulos del cliente

Si cargas **TODO** al mismo tiempo sin configurar, el servidor **SE CRASHEARÁ**.

El instalador **soluciona esto** permitiéndote:
- ✅ Cargar solo lo que necesitas
- ✅ Instalar en fases
- ✅ Modo seguro si hay problemas
- ✅ Orden de carga correcto

---

## 📋 Opciones de Instalación

### 1️⃣ Instalación Completa (Recomendado)

**Para empezar rápido:**

```bash
# Windows
INSTALL.bat

# Selecciona opción 1
```

Esto instala:
- ✅ Base de datos completa
- ✅ Engines básicos (Economy, Inventory, Vehicles, Housing)
- ✅ Jobs de emergencia (Police, EMS, Mechanic)
- ✅ Todos los módulos del cliente
- ✅ Configuración predeterminada

**Ideal para:** Servidores nuevos que quieren empezar con lo esencial.

---

### 2️⃣ Instalación Personalizada

**Para configurar a tu medida:**

```bash
# Edita el archivo de configuración
installer/startup_config.json
```

**Activa/desactiva** cada módulo según tus necesidades:

```json
{
  "engines": {
    "economy": true,      // ✅ Activado
    "inventory": true,    // ✅ Activado
    "missions": false,    // ❌ Desactivado
    "ai": false          // ❌ Desactivado
  },
  "jobs": {
    "emergency": {
      "police": true,     // ✅ Activado
      "ambulance": true   // ✅ Activado
    },
    "legal": {
      "mechanic": true,   // ✅ Activado
      "taxi": false,      // ❌ Desactivado
      "trucker": false    // ❌ Desactivado
    },
    "illegal": {
      "drugs": false,     // ❌ Desactivado
      "gangs": false      // ❌ Desactivado
    }
  }
}
```

**Ideal para:** Servidores que quieren control total.

---

### 3️⃣ Solo Base de Datos

**Si ya tienes todo configurado:**

```bash
# Windows
INSTALL.bat

# Selecciona opción 3
```

Solo instala las tablas de MySQL.

**Ideal para:** Reinstalaciones o updates.

---

### 4️⃣ Verificar Instalación

**Para comprobar que todo está bien:**

```bash
# Windows
INSTALL.bat

# Selecciona opción 4
```

Verifica que todos los archivos críticos existen.

---

### 5️⃣ Modo Seguro

**Si el servidor crashea al iniciar:**

```bash
# Windows
INSTALL.bat

# Selecciona opción 5
```

**Modo Seguro carga SOLO:**
- ✅ Core Engine
- ✅ Economy + Inventory
- ✅ Cliente básico

**Sin:**
- ❌ Jobs
- ❌ Módulos extras
- ❌ Engines opcionales

**Úsalo para:** Diagnosticar problemas.

---

## 📝 Guía de Instalación Paso a Paso

### Paso 1: Requisitos Previos

Asegúrate de tener instalado:

- ✅ **FiveM Server** (última versión)
- ✅ **QBCore Framework**
- ✅ **oxmysql**
- ✅ **ox_lib**
- ✅ **MySQL/MariaDB** (con usuario y contraseña)

---

### Paso 2: Instalar AIT-QB

**Opción A - Instalación Completa (Principiantes):**

1. Ejecuta `INSTALL.bat`
2. Selecciona **opción 1**
3. Ingresa los datos de MySQL:
   - Usuario (ej: `root`)
   - Contraseña
   - Nombre de la base de datos (ej: `ait-qb`)
4. Espera a que termine
5. ¡Listo!

**Opción B - Instalación Personalizada (Avanzados):**

1. Edita `installer/startup_config.json`
2. Activa/desactiva módulos según necesites
3. Ejecuta `INSTALL.bat` → opción 3 (para instalar DB)
4. Reinicia el servidor

---

### Paso 3: Configurar server.cfg

Añade a tu `server.cfg`:

```cfg
# Dependencias
ensure qb-core
ensure oxmysql
ensure ox_lib

# AIT-QB
ensure ait-qb
```

**IMPORTANTE:** Asegúrate de que `ait-qb` se carga **DESPUÉS** de las dependencias.

---

### Paso 4: Reiniciar Servidor

```bash
# Reinicia tu servidor FiveM
```

Observa la consola. Deberías ver:

```
═══════════════════════════════════════════════
  AIT-QB - Advanced Intelligence Technology
  Sistema de Arranque Seguro v1.0.0
═══════════════════════════════════════════════

[INFO] FASE 1: Core Engine
[SUCCESS] ✓ Cargado: core/bootstrap.lua
[SUCCESS] ✓ Cargado: core/di.lua
...
[SUCCESS] ✓ TODOS LOS SCRIPTS CARGADOS CORRECTAMENTE
```

---

## 🔧 Solución de Problemas

### ❌ El servidor crashea al iniciar

**Solución:**
```bash
# Activa el modo seguro
INSTALL.bat → opción 5
```

Luego activa módulos de uno en uno editando `startup_config.json`.

---

### ❌ Error: "Base de datos no conectada"

**Solución:**
1. Verifica que MySQL está corriendo
2. Verifica credenciales en `oxmysql` (server.cfg)
3. Ejecuta: `INSTALL.bat → opción 3`

---

### ❌ Error: "Script no encontrado"

**Solución:**
```bash
# Verifica la instalación
INSTALL.bat → opción 4
```

Si faltan archivos, reinstala desde GitHub.

---

### ❌ Muchos errores en consola

**Solución:**
1. Activa modo seguro (`INSTALL.bat → 5`)
2. Verifica que `qb-core`, `oxmysql` y `ox_lib` funcionan
3. Añade módulos de uno en uno

---

## 📊 Configuración Recomendada por Tipo de Servidor

### 🟢 Servidor Nuevo (Primeros pasos)

```json
{
  "engines": {
    "economy": true,
    "inventory": true,
    "vehicles": true
  },
  "jobs": {
    "emergency": {
      "police": true,
      "ambulance": true
    },
    "legal": {
      "mechanic": true
    }
  }
}
```

---

### 🟡 Servidor Mediano (Con jugadores)

```json
{
  "engines": {
    "economy": true,
    "inventory": true,
    "factions": true,
    "vehicles": true,
    "housing": true,
    "justice": true
  },
  "jobs": {
    "emergency": { "police": true, "ambulance": true },
    "legal": { "mechanic": true, "taxi": true, "trucker": true },
    "illegal": { "drugs": true, "robbery": true }
  }
}
```

---

### 🔴 Servidor Completo (Producción)

```json
{
  "mode": "normal",
  "engines": { "todo activado" },
  "jobs": { "todo activado" },
  "modules": { "todo activado" }
}
```

---

## 🆘 Comandos de Utilidad

En la consola del servidor:

```bash
# Ver reporte de carga
aitqb:report

# Recargar AIT-QB
aitqb:reload

# Activar modo seguro
aitqb:safemode
```

---

## 📞 Soporte

Si tienes problemas:

1. **Revisa la consola** - Los errores te dirán qué falla
2. **Modo seguro** - Úsalo para diagnosticar
3. **GitHub Issues** - Reporta bugs
4. **Discord** - Pide ayuda a la comunidad

---

## ✅ Checklist Final

Antes de abrir tu servidor al público:

- [ ] Base de datos instalada
- [ ] Todos los módulos críticos cargados sin errores
- [ ] Police y Ambulance funcionando
- [ ] Inventario funcional
- [ ] Vehículos guardando correctamente
- [ ] Teléfono abriendo (F1)
- [ ] Admin panel accesible (F10)
- [ ] Sin errores rojos en consola

---

¡Listo! Tu servidor AIT-QB está configurado. 🎉
