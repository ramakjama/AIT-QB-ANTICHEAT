--[[
    AIT Framework - Utilidades de Strings
    Funciones de manipulación de texto compartidas

    Namespace: AIT.Utils.String
    Autor: AIT Development Team
    Versión: 1.0.0
]]

AIT = AIT or {}
AIT.Utils = AIT.Utils or {}
AIT.Utils.String = {}

local String = AIT.Utils.String

-- ============================================================================
-- FUNCIONES BÁSICAS DE MANIPULACIÓN
-- ============================================================================

--- Divide una cadena por un delimitador
--- @param cadena string Cadena a dividir
--- @param delimitador string Delimitador (default: " ")
--- @return table Array con las partes
function String.Dividir(cadena, delimitador)
    if type(cadena) ~= "string" then return {} end
    delimitador = delimitador or " "

    local resultado = {}
    local patron = "([^" .. delimitador .. "]+)"

    for parte in string.gmatch(cadena, patron) do
        table.insert(resultado, parte)
    end

    return resultado
end

--- Divide una cadena por un patrón literal
--- @param cadena string Cadena a dividir
--- @param separador string Separador literal
--- @return table Array con las partes
function String.DividirPorSeparador(cadena, separador)
    if type(cadena) ~= "string" then return {} end
    if not separador or separador == "" then return {cadena} end

    local resultado = {}
    local inicio = 1

    while true do
        local posInicio, posFin = string.find(cadena, separador, inicio, true)
        if not posInicio then
            table.insert(resultado, string.sub(cadena, inicio))
            break
        end
        table.insert(resultado, string.sub(cadena, inicio, posInicio - 1))
        inicio = posFin + 1
    end

    return resultado
end

--- Elimina espacios en blanco al inicio y final
--- @param cadena string Cadena a procesar
--- @return string Cadena sin espacios al inicio/final
function String.Recortar(cadena)
    if type(cadena) ~= "string" then return "" end
    return string.match(cadena, "^%s*(.-)%s*$") or ""
end

--- Elimina espacios al inicio
--- @param cadena string Cadena a procesar
--- @return string Cadena sin espacios al inicio
function String.RecortarInicio(cadena)
    if type(cadena) ~= "string" then return "" end
    return string.match(cadena, "^%s*(.*)$") or ""
end

--- Elimina espacios al final
--- @param cadena string Cadena a procesar
--- @return string Cadena sin espacios al final
function String.RecortarFinal(cadena)
    if type(cadena) ~= "string" then return "" end
    return string.match(cadena, "^(.-)%s*$") or ""
end

--- Convierte la primera letra a mayúscula
--- @param cadena string Cadena a capitalizar
--- @return string Cadena capitalizada
function String.Capitalizar(cadena)
    if type(cadena) ~= "string" or #cadena == 0 then return "" end
    return string.upper(string.sub(cadena, 1, 1)) .. string.lower(string.sub(cadena, 2))
end

--- Capitaliza cada palabra
--- @param cadena string Cadena a procesar
--- @return string Cadena con cada palabra capitalizada
function String.CapitalizarPalabras(cadena)
    if type(cadena) ~= "string" then return "" end
    return string.gsub(cadena, "(%a)([%w_']*)", function(primera, resto)
        return string.upper(primera) .. string.lower(resto)
    end)
end

--- Convierte a mayúsculas
--- @param cadena string Cadena a convertir
--- @return string Cadena en mayúsculas
function String.Mayusculas(cadena)
    if type(cadena) ~= "string" then return "" end
    return string.upper(cadena)
end

--- Convierte a minúsculas
--- @param cadena string Cadena a convertir
--- @return string Cadena en minúsculas
function String.Minusculas(cadena)
    if type(cadena) ~= "string" then return "" end
    return string.lower(cadena)
end

-- ============================================================================
-- FUNCIONES DE FORMATO
-- ============================================================================

--- Formatea una cadena con argumentos (similar a string.format pero seguro)
--- @param plantilla string Plantilla con marcadores %s, %d, etc
--- @param ... any Argumentos para reemplazar
--- @return string Cadena formateada
function String.Formatear(plantilla, ...)
    if type(plantilla) ~= "string" then return "" end
    local exito, resultado = pcall(string.format, plantilla, ...)
    return exito and resultado or plantilla
end

--- Reemplaza marcadores {nombre} con valores de una tabla
--- @param plantilla string Plantilla con marcadores {clave}
--- @param valores table Tabla con valores para reemplazar
--- @return string Cadena con valores reemplazados
function String.FormatearConTabla(plantilla, valores)
    if type(plantilla) ~= "string" then return "" end
    if type(valores) ~= "table" then return plantilla end

    return string.gsub(plantilla, "{([%w_]+)}", function(clave)
        local valor = valores[clave]
        return valor ~= nil and tostring(valor) or "{" .. clave .. "}"
    end)
end

--- Rellena una cadena por la izquierda
--- @param cadena string Cadena a rellenar
--- @param longitud number Longitud deseada
--- @param caracter string Caracter de relleno (default: " ")
--- @return string Cadena rellenada
function String.RellenarIzquierda(cadena, longitud, caracter)
    cadena = tostring(cadena or "")
    caracter = caracter or " "
    local faltan = longitud - #cadena
    if faltan <= 0 then return cadena end
    return string.rep(caracter, faltan) .. cadena
end

--- Rellena una cadena por la derecha
--- @param cadena string Cadena a rellenar
--- @param longitud number Longitud deseada
--- @param caracter string Caracter de relleno (default: " ")
--- @return string Cadena rellenada
function String.RellenarDerecha(cadena, longitud, caracter)
    cadena = tostring(cadena or "")
    caracter = caracter or " "
    local faltan = longitud - #cadena
    if faltan <= 0 then return cadena end
    return cadena .. string.rep(caracter, faltan)
end

--- Centra una cadena
--- @param cadena string Cadena a centrar
--- @param longitud number Longitud total
--- @param caracter string Caracter de relleno (default: " ")
--- @return string Cadena centrada
function String.Centrar(cadena, longitud, caracter)
    cadena = tostring(cadena or "")
    caracter = caracter or " "
    local faltan = longitud - #cadena
    if faltan <= 0 then return cadena end
    local izquierda = math.floor(faltan / 2)
    local derecha = faltan - izquierda
    return string.rep(caracter, izquierda) .. cadena .. string.rep(caracter, derecha)
end

-- ============================================================================
-- FUNCIONES DE SANITIZACIÓN
-- ============================================================================

--- Elimina caracteres especiales peligrosos
--- @param cadena string Cadena a sanitizar
--- @return string Cadena sanitizada
function String.Sanitizar(cadena)
    if type(cadena) ~= "string" then return "" end
    -- Eliminar caracteres de control y caracteres peligrosos
    cadena = string.gsub(cadena, "[%c]", "")
    cadena = string.gsub(cadena, "[<>\"'&]", "")
    return String.Recortar(cadena)
end

--- Escapa caracteres especiales para SQL (básico, usar prepared statements)
--- @param cadena string Cadena a escapar
--- @return string Cadena escapada
function String.EscaparSQL(cadena)
    if type(cadena) ~= "string" then return "" end
    cadena = string.gsub(cadena, "'", "''")
    cadena = string.gsub(cadena, "\\", "\\\\")
    return cadena
end

--- Escapa caracteres HTML
--- @param cadena string Cadena a escapar
--- @return string Cadena con HTML escapado
function String.EscaparHTML(cadena)
    if type(cadena) ~= "string" then return "" end
    local reemplazos = {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&#39;"
    }
    return string.gsub(cadena, "[&<>\"']", reemplazos)
end

--- Convierte a slug (URL amigable)
--- @param cadena string Cadena a convertir
--- @return string Slug
function String.Slugificar(cadena)
    if type(cadena) ~= "string" then return "" end
    -- Convertir a minúsculas
    cadena = string.lower(cadena)
    -- Reemplazar acentos comunes
    local acentos = {
        ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u",
        ["ä"] = "a", ["ë"] = "e", ["ï"] = "i", ["ö"] = "o", ["ü"] = "u",
        ["ñ"] = "n", ["ç"] = "c"
    }
    for acento, sin_acento in pairs(acentos) do
        cadena = string.gsub(cadena, acento, sin_acento)
    end
    -- Reemplazar espacios y caracteres no válidos por guiones
    cadena = string.gsub(cadena, "[^%w%-]", "-")
    -- Eliminar guiones múltiples
    cadena = string.gsub(cadena, "%-+", "-")
    -- Eliminar guiones al inicio y final
    cadena = string.gsub(cadena, "^%-+", "")
    cadena = string.gsub(cadena, "%-+$", "")
    return cadena
end

-- ============================================================================
-- FUNCIONES DE TRUNCADO Y SUBSTRING
-- ============================================================================

--- Trunca una cadena a una longitud máxima
--- @param cadena string Cadena a truncar
--- @param longitud number Longitud máxima
--- @param sufijo string Sufijo a agregar si se trunca (default: "...")
--- @return string Cadena truncada
function String.Truncar(cadena, longitud, sufijo)
    if type(cadena) ~= "string" then return "" end
    sufijo = sufijo or "..."

    if #cadena <= longitud then
        return cadena
    end

    local longitudReal = longitud - #sufijo
    if longitudReal <= 0 then return sufijo end

    return string.sub(cadena, 1, longitudReal) .. sufijo
end

--- Obtiene una subcadena de forma segura
--- @param cadena string Cadena original
--- @param inicio number Posición inicial (1-indexed)
--- @param fin number Posición final (opcional)
--- @return string Subcadena
function String.Subcadena(cadena, inicio, fin)
    if type(cadena) ~= "string" then return "" end
    return string.sub(cadena, inicio, fin) or ""
end

--- Invierte una cadena
--- @param cadena string Cadena a invertir
--- @return string Cadena invertida
function String.Invertir(cadena)
    if type(cadena) ~= "string" then return "" end
    return string.reverse(cadena)
end

-- ============================================================================
-- FUNCIONES DE BÚSQUEDA Y VALIDACIÓN
-- ============================================================================

--- Verifica si una cadena contiene otra
--- @param cadena string Cadena donde buscar
--- @param buscar string Subcadena a buscar
--- @param ignorarMayusculas boolean Ignorar mayúsculas/minúsculas
--- @return boolean True si contiene la subcadena
function String.Contiene(cadena, buscar, ignorarMayusculas)
    if type(cadena) ~= "string" or type(buscar) ~= "string" then return false end
    if ignorarMayusculas then
        cadena = string.lower(cadena)
        buscar = string.lower(buscar)
    end
    return string.find(cadena, buscar, 1, true) ~= nil
end

--- Verifica si una cadena empieza con otra
--- @param cadena string Cadena a verificar
--- @param prefijo string Prefijo esperado
--- @return boolean True si empieza con el prefijo
function String.EmpiezaCon(cadena, prefijo)
    if type(cadena) ~= "string" or type(prefijo) ~= "string" then return false end
    return string.sub(cadena, 1, #prefijo) == prefijo
end

--- Verifica si una cadena termina con otra
--- @param cadena string Cadena a verificar
--- @param sufijo string Sufijo esperado
--- @return boolean True si termina con el sufijo
function String.TerminaCon(cadena, sufijo)
    if type(cadena) ~= "string" or type(sufijo) ~= "string" then return false end
    return sufijo == "" or string.sub(cadena, -#sufijo) == sufijo
end

--- Cuenta las ocurrencias de una subcadena
--- @param cadena string Cadena donde buscar
--- @param buscar string Subcadena a contar
--- @return number Número de ocurrencias
function String.ContarOcurrencias(cadena, buscar)
    if type(cadena) ~= "string" or type(buscar) ~= "string" then return 0 end
    if buscar == "" then return 0 end

    local contador = 0
    local posicion = 1

    while true do
        local encontrado = string.find(cadena, buscar, posicion, true)
        if not encontrado then break end
        contador = contador + 1
        posicion = encontrado + 1
    end

    return contador
end

--- Reemplaza todas las ocurrencias de una subcadena
--- @param cadena string Cadena original
--- @param buscar string Subcadena a buscar
--- @param reemplazo string Cadena de reemplazo
--- @return string Cadena con reemplazos
function String.Reemplazar(cadena, buscar, reemplazo)
    if type(cadena) ~= "string" then return "" end
    if type(buscar) ~= "string" or buscar == "" then return cadena end
    reemplazo = reemplazo or ""

    -- Escapar caracteres especiales de patrones Lua
    local buscarEscapado = string.gsub(buscar, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    return string.gsub(cadena, buscarEscapado, reemplazo)
end

--- Verifica si una cadena está vacía o solo tiene espacios
--- @param cadena string Cadena a verificar
--- @return boolean True si está vacía
function String.EstaVacia(cadena)
    if type(cadena) ~= "string" then return true end
    return String.Recortar(cadena) == ""
end

--- Obtiene la longitud de una cadena
--- @param cadena string Cadena
--- @return number Longitud
function String.Longitud(cadena)
    if type(cadena) ~= "string" then return 0 end
    return #cadena
end

-- ============================================================================
-- FUNCIONES DE UNIÓN
-- ============================================================================

--- Une elementos de una tabla con un separador
--- @param tabla table Tabla con elementos
--- @param separador string Separador (default: ", ")
--- @return string Cadena unida
function String.Unir(tabla, separador)
    if type(tabla) ~= "table" then return "" end
    separador = separador or ", "

    local partes = {}
    for i, v in ipairs(tabla) do
        partes[i] = tostring(v)
    end

    return table.concat(partes, separador)
end

--- Repite una cadena N veces
--- @param cadena string Cadena a repetir
--- @param veces number Número de repeticiones
--- @param separador string Separador entre repeticiones (default: "")
--- @return string Cadena repetida
function String.Repetir(cadena, veces, separador)
    if type(cadena) ~= "string" or veces <= 0 then return "" end
    separador = separador or ""

    if separador == "" then
        return string.rep(cadena, veces)
    end

    local partes = {}
    for i = 1, veces do
        partes[i] = cadena
    end
    return table.concat(partes, separador)
end

-- Exportar para compatibilidad
return String
