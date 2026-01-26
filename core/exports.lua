--[[
    AIT Framework - Gestor de Exports
    Archivo: core/exports.lua

    Sistema centralizado de exports con:
    - Registro y versionado de API
    - Advertencias de deprecacion
    - Documentacion automatica
    - Validacion de parametros
]]

AIT = AIT or {}
AIT.Exports = AIT.Exports or {}

-- ============================================================================
-- CONFIGURACION DEL GESTOR DE EXPORTS
-- ============================================================================

local Config = {
    -- Configuracion general
    modoDebug = false,
    mostrarAdvertenciasDeprecacion = true,
    registrarUso = true,

    -- Versionado
    versionActual = "1.0.0",
    versionMinimaSoportada = "0.9.0",

    -- Documentacion
    generarDocumentacion = true,
    formatoDocumentacion = "markdown"
}

-- ============================================================================
-- ALMACENAMIENTO DE EXPORTS
-- ============================================================================

local registroExports = {
    exports = {},           -- Todos los exports registrados
    deprecados = {},        -- Exports marcados como deprecados
    estadisticas = {},      -- Estadisticas de uso
    documentacion = {},     -- Documentacion generada
    versiones = {}          -- Historial de versiones
}

-- ============================================================================
-- UTILIDADES INTERNAS
-- ============================================================================

local function compararVersiones(v1, v2)
    local function parsear(v)
        local partes = {}
        for num in string.gmatch(v, "%d+") do
            table.insert(partes, tonumber(num))
        end
        return partes
    end

    local p1, p2 = parsear(v1), parsear(v2)
    for i = 1, math.max(#p1, #p2) do
        local n1 = p1[i] or 0
        local n2 = p2[i] or 0
        if n1 > n2 then return 1
        elseif n1 < n2 then return -1 end
    end
    return 0
end

local function generarFirma(nombre, parametros)
    local firma = nombre .. "("
    local partes = {}
    for _, param in ipairs(parametros or {}) do
        local tipo = param.tipo or "any"
        local opcional = param.opcional and "?" or ""
        table.insert(partes, param.nombre .. opcional .. ": " .. tipo)
    end
    firma = firma .. table.concat(partes, ", ") .. ")"
    return firma
end

local function validarParametro(valor, configuracion)
    if valor == nil then
        return configuracion.opcional == true, "Parametro requerido no proporcionado"
    end

    local tipo = configuracion.tipo
    if tipo then
        local tipoActual = type(valor)
        if tipo == "number" and tipoActual ~= "number" then
            return false, "Se esperaba number, se recibio " .. tipoActual
        elseif tipo == "string" and tipoActual ~= "string" then
            return false, "Se esperaba string, se recibio " .. tipoActual
        elseif tipo == "boolean" and tipoActual ~= "boolean" then
            return false, "Se esperaba boolean, se recibio " .. tipoActual
        elseif tipo == "table" and tipoActual ~= "table" then
            return false, "Se esperaba table, se recibio " .. tipoActual
        elseif tipo == "function" and tipoActual ~= "function" then
            return false, "Se esperaba function, se recibio " .. tipoActual
        end
    end

    -- Validacion de rango para numeros
    if tipo == "number" and valor ~= nil then
        if configuracion.min and valor < configuracion.min then
            return false, string.format("Valor %d menor que minimo %d", valor, configuracion.min)
        end
        if configuracion.max and valor > configuracion.max then
            return false, string.format("Valor %d mayor que maximo %d", valor, configuracion.max)
        end
    end

    -- Validacion de valores permitidos
    if configuracion.valoresPermitidos then
        local encontrado = false
        for _, v in ipairs(configuracion.valoresPermitidos) do
            if v == valor then
                encontrado = true
                break
            end
        end
        if not encontrado then
            return false, "Valor no permitido"
        end
    end

    return true
end

-- ============================================================================
-- CLASE EXPORT
-- ============================================================================

local Export = {}
Export.__index = Export

function Export.nuevo(config)
    local self = setmetatable({}, Export)

    self.nombre = config.nombre
    self.funcion = config.funcion
    self.descripcion = config.descripcion or ""
    self.categoria = config.categoria or "general"
    self.version = config.version or Config.versionActual
    self.parametros = config.parametros or {}
    self.retorno = config.retorno or { tipo = "any", descripcion = "" }
    self.ejemplos = config.ejemplos or {}
    self.deprecado = config.deprecado or false
    self.reemplazo = config.reemplazo      -- Export que reemplaza a este (si deprecado)
    self.fechaDeprecacion = config.fechaDeprecacion
    self.privado = config.privado or false
    self.validarParametros = config.validarParametros ~= false

    return self
end

function Export:ejecutar(...)
    local args = {...}

    -- Registrar uso
    if Config.registrarUso then
        AIT.Exports.RegistrarUso(self.nombre)
    end

    -- Advertencia de deprecacion
    if self.deprecado and Config.mostrarAdvertenciasDeprecacion then
        local mensaje = string.format(
            "[AIT.Exports] ADVERTENCIA: '%s' esta deprecado",
            self.nombre
        )
        if self.reemplazo then
            mensaje = mensaje .. string.format(". Usar '%s' en su lugar", self.reemplazo)
        end
        if self.fechaDeprecacion then
            mensaje = mensaje .. string.format(". Sera eliminado en: %s", self.fechaDeprecacion)
        end
        print(mensaje)
    end

    -- Validar parametros si esta habilitado
    if self.validarParametros and #self.parametros > 0 then
        for i, paramConfig in ipairs(self.parametros) do
            local valor = args[i]
            local valido, error = validarParametro(valor, paramConfig)
            if not valido then
                local mensajeError = string.format(
                    "[AIT.Exports] Error en '%s': Parametro '%s' - %s",
                    self.nombre, paramConfig.nombre, error
                )
                if Config.modoDebug then
                    print(mensajeError)
                end
                return nil, mensajeError
            end
        end
    end

    -- Ejecutar funcion
    local exito, resultado = pcall(self.funcion, ...)
    if not exito then
        print(string.format("[AIT.Exports] Error ejecutando '%s': %s", self.nombre, tostring(resultado)))
        return nil, resultado
    end

    return resultado
end

function Export:generarDocumentacion()
    local doc = {}

    table.insert(doc, "## " .. self.nombre)
    table.insert(doc, "")

    if self.deprecado then
        table.insert(doc, "> **DEPRECADO**" .. (self.reemplazo and (": Usar `" .. self.reemplazo .. "`") or ""))
        table.insert(doc, "")
    end

    table.insert(doc, self.descripcion)
    table.insert(doc, "")

    -- Firma
    table.insert(doc, "### Firma")
    table.insert(doc, "```lua")
    table.insert(doc, generarFirma(self.nombre, self.parametros))
    table.insert(doc, "```")
    table.insert(doc, "")

    -- Parametros
    if #self.parametros > 0 then
        table.insert(doc, "### Parametros")
        for _, param in ipairs(self.parametros) do
            local linea = string.format("- **%s** (`%s`)", param.nombre, param.tipo or "any")
            if param.opcional then
                linea = linea .. " *opcional*"
            end
            if param.descripcion then
                linea = linea .. " - " .. param.descripcion
            end
            table.insert(doc, linea)
        end
        table.insert(doc, "")
    end

    -- Retorno
    if self.retorno then
        table.insert(doc, "### Retorno")
        table.insert(doc, string.format("- `%s` - %s",
            self.retorno.tipo or "any",
            self.retorno.descripcion or ""
        ))
        table.insert(doc, "")
    end

    -- Ejemplos
    if #self.ejemplos > 0 then
        table.insert(doc, "### Ejemplos")
        for _, ejemplo in ipairs(self.ejemplos) do
            table.insert(doc, "```lua")
            table.insert(doc, ejemplo)
            table.insert(doc, "```")
        end
        table.insert(doc, "")
    end

    -- Metadata
    table.insert(doc, "---")
    table.insert(doc, string.format("*Version: %s | Categoria: %s*", self.version, self.categoria))
    table.insert(doc, "")

    return table.concat(doc, "\n")
end

-- ============================================================================
-- FUNCIONES PRINCIPALES DEL GESTOR
-- ============================================================================

function AIT.Exports.Inicializar(configuracion)
    if configuracion then
        for k, v in pairs(configuracion) do
            Config[k] = v
        end
    end

    print("[AIT.Exports] Gestor de Exports inicializado")
    return true
end

function AIT.Exports.Registrar(config)
    if not config.nombre then
        return false, "Nombre de export requerido"
    end

    if not config.funcion then
        return false, "Funcion de export requerida"
    end

    -- Verificar si ya existe
    if registroExports.exports[config.nombre] then
        if Config.modoDebug then
            print(string.format("[AIT.Exports] Sobrescribiendo export: %s", config.nombre))
        end
    end

    -- Crear y registrar export
    local exportObj = Export.nuevo(config)
    registroExports.exports[config.nombre] = exportObj

    -- Marcar como deprecado si corresponde
    if config.deprecado then
        registroExports.deprecados[config.nombre] = {
            reemplazo = config.reemplazo,
            fechaDeprecacion = config.fechaDeprecacion
        }
    end

    -- Inicializar estadisticas
    registroExports.estadisticas[config.nombre] = {
        llamadas = 0,
        ultimaLlamada = nil,
        errores = 0
    }

    -- Registrar en FiveM si es posible
    if exports and not config.privado then
        local wrapper = function(...)
            return exportObj:ejecutar(...)
        end
        exports(config.nombre, wrapper)
    end

    if Config.modoDebug then
        print(string.format("[AIT.Exports] Export registrado: %s (v%s)", config.nombre, exportObj.version))
    end

    return true, config.nombre
end

function AIT.Exports.Obtener(nombre)
    return registroExports.exports[nombre]
end

function AIT.Exports.Ejecutar(nombre, ...)
    local exportObj = registroExports.exports[nombre]
    if not exportObj then
        return nil, string.format("Export no encontrado: %s", nombre)
    end

    return exportObj:ejecutar(...)
end

function AIT.Exports.Eliminar(nombre)
    if not registroExports.exports[nombre] then
        return false, "Export no encontrado"
    end

    registroExports.exports[nombre] = nil
    registroExports.deprecados[nombre] = nil
    registroExports.estadisticas[nombre] = nil

    return true
end

function AIT.Exports.Deprecar(nombre, reemplazo, fechaEliminacion)
    local exportObj = registroExports.exports[nombre]
    if not exportObj then
        return false, "Export no encontrado"
    end

    exportObj.deprecado = true
    exportObj.reemplazo = reemplazo
    exportObj.fechaDeprecacion = fechaEliminacion

    registroExports.deprecados[nombre] = {
        reemplazo = reemplazo,
        fechaDeprecacion = fechaEliminacion
    }

    print(string.format("[AIT.Exports] Export '%s' marcado como deprecado", nombre))
    return true
end

function AIT.Exports.RegistrarUso(nombre)
    if registroExports.estadisticas[nombre] then
        registroExports.estadisticas[nombre].llamadas =
            registroExports.estadisticas[nombre].llamadas + 1
        registroExports.estadisticas[nombre].ultimaLlamada = os.time()
    end
end

function AIT.Exports.RegistrarError(nombre)
    if registroExports.estadisticas[nombre] then
        registroExports.estadisticas[nombre].errores =
            registroExports.estadisticas[nombre].errores + 1
    end
end

function AIT.Exports.ObtenerEstadisticas(nombre)
    if nombre then
        return registroExports.estadisticas[nombre]
    end
    return registroExports.estadisticas
end

function AIT.Exports.Listar(filtros)
    filtros = filtros or {}
    local resultados = {}

    for nombre, exportObj in pairs(registroExports.exports) do
        local incluir = true

        -- Filtrar por categoria
        if filtros.categoria and exportObj.categoria ~= filtros.categoria then
            incluir = false
        end

        -- Filtrar deprecados
        if filtros.excluirDeprecados and exportObj.deprecado then
            incluir = false
        end

        -- Filtrar privados
        if filtros.excluirPrivados and exportObj.privado then
            incluir = false
        end

        -- Filtrar por version
        if filtros.versionMinima then
            if compararVersiones(exportObj.version, filtros.versionMinima) < 0 then
                incluir = false
            end
        end

        if incluir then
            table.insert(resultados, {
                nombre = nombre,
                descripcion = exportObj.descripcion,
                categoria = exportObj.categoria,
                version = exportObj.version,
                deprecado = exportObj.deprecado,
                firma = generarFirma(nombre, exportObj.parametros)
            })
        end
    end

    -- Ordenar por nombre
    table.sort(resultados, function(a, b) return a.nombre < b.nombre end)

    return resultados
end

function AIT.Exports.ListarDeprecados()
    local resultados = {}
    for nombre, info in pairs(registroExports.deprecados) do
        table.insert(resultados, {
            nombre = nombre,
            reemplazo = info.reemplazo,
            fechaDeprecacion = info.fechaDeprecacion
        })
    end
    return resultados
end

function AIT.Exports.GenerarDocumentacion(filtros)
    filtros = filtros or {}
    filtros.excluirPrivados = filtros.excluirPrivados ~= false

    local listaExports = AIT.Exports.Listar(filtros)
    local doc = {}

    -- Encabezado
    table.insert(doc, "# AIT Framework - Documentacion de API")
    table.insert(doc, "")
    table.insert(doc, string.format("*Version: %s*", Config.versionActual))
    table.insert(doc, string.format("*Generado: %s*", os.date("%Y-%m-%d %H:%M:%S")))
    table.insert(doc, "")
    table.insert(doc, "---")
    table.insert(doc, "")

    -- Indice
    table.insert(doc, "## Indice")
    table.insert(doc, "")

    local categorias = {}
    for _, exp in ipairs(listaExports) do
        if not categorias[exp.categoria] then
            categorias[exp.categoria] = {}
        end
        table.insert(categorias[exp.categoria], exp)
    end

    for categoria, exps in pairs(categorias) do
        table.insert(doc, string.format("### %s", categoria:upper()))
        for _, exp in ipairs(exps) do
            local marca = exp.deprecado and " *(deprecado)*" or ""
            table.insert(doc, string.format("- [%s](#%s)%s", exp.nombre, exp.nombre:lower(), marca))
        end
        table.insert(doc, "")
    end

    table.insert(doc, "---")
    table.insert(doc, "")

    -- Documentacion detallada
    table.insert(doc, "## Referencia de API")
    table.insert(doc, "")

    for _, expInfo in ipairs(listaExports) do
        local exportObj = registroExports.exports[expInfo.nombre]
        if exportObj then
            table.insert(doc, exportObj:generarDocumentacion())
        end
    end

    return table.concat(doc, "\n")
end

function AIT.Exports.VerificarCompatibilidad(versionCliente)
    if compararVersiones(versionCliente, Config.versionMinimaSoportada) < 0 then
        return false, string.format(
            "Version %s no soportada. Minima requerida: %s",
            versionCliente, Config.versionMinimaSoportada
        )
    end

    if compararVersiones(versionCliente, Config.versionActual) > 0 then
        return false, string.format(
            "Version %s es mas nueva que la del servidor (%s)",
            versionCliente, Config.versionActual
        )
    end

    return true
end

function AIT.Exports.ObtenerVersion()
    return Config.versionActual
end

function AIT.Exports.ObtenerResumen()
    local total = 0
    local deprecados = 0
    local privados = 0
    local categorias = {}

    for nombre, exportObj in pairs(registroExports.exports) do
        total = total + 1
        if exportObj.deprecado then deprecados = deprecados + 1 end
        if exportObj.privado then privados = privados + 1 end
        categorias[exportObj.categoria] = (categorias[exportObj.categoria] or 0) + 1
    end

    return {
        total = total,
        deprecados = deprecados,
        privados = privados,
        publicos = total - privados,
        categorias = categorias,
        version = Config.versionActual
    }
end

-- ============================================================================
-- REGISTRO DE EXPORTS DEL PROPIO GESTOR
-- ============================================================================

local function registrarExportsPropios()
    -- Registrar las funciones del gestor como exports
    AIT.Exports.Registrar({
        nombre = "ExportsRegistrar",
        funcion = AIT.Exports.Registrar,
        descripcion = "Registra un nuevo export en el sistema",
        categoria = "exports",
        parametros = {
            { nombre = "config", tipo = "table", descripcion = "Configuracion del export" }
        },
        retorno = { tipo = "boolean", descripcion = "true si se registro correctamente" },
        ejemplos = {
            [[exports["ait-qb"]:ExportsRegistrar({
    nombre = "MiFuncion",
    funcion = function(x) return x * 2 end,
    descripcion = "Duplica un numero"
})]]
        }
    })

    AIT.Exports.Registrar({
        nombre = "ExportsListar",
        funcion = AIT.Exports.Listar,
        descripcion = "Lista todos los exports registrados con filtros opcionales",
        categoria = "exports",
        parametros = {
            { nombre = "filtros", tipo = "table", opcional = true, descripcion = "Filtros de busqueda" }
        },
        retorno = { tipo = "table", descripcion = "Lista de exports" }
    })

    AIT.Exports.Registrar({
        nombre = "ExportsGenerarDocumentacion",
        funcion = AIT.Exports.GenerarDocumentacion,
        descripcion = "Genera documentacion en formato Markdown",
        categoria = "exports",
        parametros = {
            { nombre = "filtros", tipo = "table", opcional = true }
        },
        retorno = { tipo = "string", descripcion = "Documentacion en Markdown" }
    })

    AIT.Exports.Registrar({
        nombre = "ExportsObtenerEstadisticas",
        funcion = AIT.Exports.ObtenerEstadisticas,
        descripcion = "Obtiene estadisticas de uso de exports",
        categoria = "exports",
        parametros = {
            { nombre = "nombre", tipo = "string", opcional = true, descripcion = "Nombre del export especifico" }
        },
        retorno = { tipo = "table", descripcion = "Estadisticas de uso" }
    })

    AIT.Exports.Registrar({
        nombre = "ExportsVerificarCompatibilidad",
        funcion = AIT.Exports.VerificarCompatibilidad,
        descripcion = "Verifica si una version del cliente es compatible",
        categoria = "exports",
        parametros = {
            { nombre = "versionCliente", tipo = "string", descripcion = "Version a verificar" }
        },
        retorno = { tipo = "boolean", descripcion = "true si es compatible" }
    })

    AIT.Exports.Registrar({
        nombre = "ExportsObtenerVersion",
        funcion = AIT.Exports.ObtenerVersion,
        descripcion = "Obtiene la version actual del API",
        categoria = "exports",
        retorno = { tipo = "string", descripcion = "Version actual" }
    })
end

-- ============================================================================
-- INICIALIZACION AUTOMATICA
-- ============================================================================

CreateThread(function()
    Wait(50)
    AIT.Exports.Inicializar()
    registrarExportsPropios()
end)

print("[AIT Framework] Gestor de Exports cargado - v1.0.0")
