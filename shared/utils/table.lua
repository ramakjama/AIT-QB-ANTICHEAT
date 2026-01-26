--[[
    AIT Framework - Utilidades de Tablas
    Funciones de manipulación de tablas compartidas

    Namespace: AIT.Utils.Table
    Autor: AIT Development Team
    Versión: 1.0.0
]]

AIT = AIT or {}
AIT.Utils = AIT.Utils or {}
AIT.Utils.Table = {}

local Table = AIT.Utils.Table

-- ============================================================================
-- FUNCIONES DE COPIA
-- ============================================================================

--- Copia superficial de una tabla
--- @param original table Tabla a copiar
--- @return table Nueva tabla con los mismos valores
function Table.Copiar(original)
    if type(original) ~= "table" then return original end

    local copia = {}
    for clave, valor in pairs(original) do
        copia[clave] = valor
    end

    return copia
end

--- Copia profunda de una tabla (incluyendo tablas anidadas)
--- @param original table Tabla a copiar
--- @param vistas table Tabla interna para evitar ciclos
--- @return table Nueva tabla con copia profunda
function Table.CopiarProfundo(original, vistas)
    if type(original) ~= "table" then return original end

    vistas = vistas or {}

    -- Evitar referencias circulares
    if vistas[original] then
        return vistas[original]
    end

    local copia = {}
    vistas[original] = copia

    for clave, valor in pairs(original) do
        local claveCopiada = Table.CopiarProfundo(clave, vistas)
        local valorCopiado = Table.CopiarProfundo(valor, vistas)
        copia[claveCopiada] = valorCopiado
    end

    -- Copiar metatabla si existe
    local mt = getmetatable(original)
    if mt then
        setmetatable(copia, Table.CopiarProfundo(mt, vistas))
    end

    return copia
end

-- ============================================================================
-- FUNCIONES DE FUSIÓN
-- ============================================================================

--- Fusiona dos tablas (la segunda sobrescribe valores de la primera)
--- @param base table Tabla base
--- @param extension table Tabla con valores adicionales
--- @return table Tabla fusionada
function Table.Fusionar(base, extension)
    if type(base) ~= "table" then base = {} end
    if type(extension) ~= "table" then return Table.Copiar(base) end

    local resultado = Table.Copiar(base)

    for clave, valor in pairs(extension) do
        resultado[clave] = valor
    end

    return resultado
end

--- Fusiona profundamente dos tablas
--- @param base table Tabla base
--- @param extension table Tabla con valores adicionales
--- @return table Tabla fusionada profundamente
function Table.FusionarProfundo(base, extension)
    if type(base) ~= "table" then base = {} end
    if type(extension) ~= "table" then return Table.CopiarProfundo(base) end

    local resultado = Table.CopiarProfundo(base)

    for clave, valor in pairs(extension) do
        if type(valor) == "table" and type(resultado[clave]) == "table" then
            resultado[clave] = Table.FusionarProfundo(resultado[clave], valor)
        else
            resultado[clave] = Table.CopiarProfundo(valor)
        end
    end

    return resultado
end

--- Extiende una tabla agregando elementos de otra (para arrays)
--- @param base table Array base
--- @param extension table Array a agregar
--- @return table Array extendido
function Table.Extender(base, extension)
    if type(base) ~= "table" then base = {} end
    if type(extension) ~= "table" then return Table.Copiar(base) end

    local resultado = Table.Copiar(base)

    for _, valor in ipairs(extension) do
        table.insert(resultado, valor)
    end

    return resultado
end

-- ============================================================================
-- FUNCIONES DE BÚSQUEDA
-- ============================================================================

--- Verifica si una tabla contiene un valor
--- @param tabla table Tabla donde buscar
--- @param valorBuscado any Valor a buscar
--- @return boolean True si contiene el valor
function Table.Contiene(tabla, valorBuscado)
    if type(tabla) ~= "table" then return false end

    for _, valor in pairs(tabla) do
        if valor == valorBuscado then
            return true
        end
    end

    return false
end

--- Verifica si una tabla contiene una clave
--- @param tabla table Tabla donde buscar
--- @param claveBuscada any Clave a buscar
--- @return boolean True si contiene la clave
function Table.ContieneClave(tabla, claveBuscada)
    if type(tabla) ~= "table" then return false end
    return tabla[claveBuscada] ~= nil
end

--- Busca el índice de un valor en un array
--- @param tabla table Array donde buscar
--- @param valorBuscado any Valor a buscar
--- @return number|nil Índice del valor o nil si no se encuentra
function Table.IndiceDE(tabla, valorBuscado)
    if type(tabla) ~= "table" then return nil end

    for indice, valor in ipairs(tabla) do
        if valor == valorBuscado then
            return indice
        end
    end

    return nil
end

--- Busca la clave de un valor
--- @param tabla table Tabla donde buscar
--- @param valorBuscado any Valor a buscar
--- @return any|nil Clave del valor o nil si no se encuentra
function Table.ClaveDe(tabla, valorBuscado)
    if type(tabla) ~= "table" then return nil end

    for clave, valor in pairs(tabla) do
        if valor == valorBuscado then
            return clave
        end
    end

    return nil
end

--- Encuentra el primer elemento que cumple una condición
--- @param tabla table Tabla donde buscar
--- @param predicado function Función que recibe (valor, clave) y retorna boolean
--- @return any|nil Elemento encontrado o nil
function Table.Encontrar(tabla, predicado)
    if type(tabla) ~= "table" or type(predicado) ~= "function" then return nil end

    for clave, valor in pairs(tabla) do
        if predicado(valor, clave) then
            return valor
        end
    end

    return nil
end

--- Encuentra el índice del primer elemento que cumple una condición
--- @param tabla table Array donde buscar
--- @param predicado function Función que recibe (valor, indice) y retorna boolean
--- @return number|nil Índice encontrado o nil
function Table.EncontrarIndice(tabla, predicado)
    if type(tabla) ~= "table" or type(predicado) ~= "function" then return nil end

    for indice, valor in ipairs(tabla) do
        if predicado(valor, indice) then
            return indice
        end
    end

    return nil
end

-- ============================================================================
-- FUNCIONES DE EXTRACCIÓN
-- ============================================================================

--- Obtiene todas las claves de una tabla
--- @param tabla table Tabla original
--- @return table Array con las claves
function Table.Claves(tabla)
    if type(tabla) ~= "table" then return {} end

    local claves = {}
    for clave, _ in pairs(tabla) do
        table.insert(claves, clave)
    end

    return claves
end

--- Obtiene todos los valores de una tabla
--- @param tabla table Tabla original
--- @return table Array con los valores
function Table.Valores(tabla)
    if type(tabla) ~= "table" then return {} end

    local valores = {}
    for _, valor in pairs(tabla) do
        table.insert(valores, valor)
    end

    return valores
end

--- Obtiene las entradas de una tabla como pares [clave, valor]
--- @param tabla table Tabla original
--- @return table Array de arrays [clave, valor]
function Table.Entradas(tabla)
    if type(tabla) ~= "table" then return {} end

    local entradas = {}
    for clave, valor in pairs(tabla) do
        table.insert(entradas, {clave, valor})
    end

    return entradas
end

--- Crea una tabla a partir de arrays de claves y valores
--- @param claves table Array de claves
--- @param valores table Array de valores
--- @return table Tabla con pares clave-valor
function Table.DesdePares(claves, valores)
    if type(claves) ~= "table" then return {} end
    valores = valores or {}

    local tabla = {}
    for i, clave in ipairs(claves) do
        tabla[clave] = valores[i]
    end

    return tabla
end

-- ============================================================================
-- FUNCIONES DE TRANSFORMACIÓN
-- ============================================================================

--- Aplica una función a cada elemento y retorna nueva tabla
--- @param tabla table Tabla original
--- @param transformador function Función que recibe (valor, clave) y retorna nuevo valor
--- @return table Nueva tabla con valores transformados
function Table.Mapear(tabla, transformador)
    if type(tabla) ~= "table" or type(transformador) ~= "function" then return {} end

    local resultado = {}
    for clave, valor in pairs(tabla) do
        resultado[clave] = transformador(valor, clave)
    end

    return resultado
end

--- Aplica una función a cada elemento de un array
--- @param tabla table Array original
--- @param transformador function Función que recibe (valor, indice) y retorna nuevo valor
--- @return table Nuevo array con valores transformados
function Table.MapearArray(tabla, transformador)
    if type(tabla) ~= "table" or type(transformador) ~= "function" then return {} end

    local resultado = {}
    for indice, valor in ipairs(tabla) do
        resultado[indice] = transformador(valor, indice)
    end

    return resultado
end

--- Filtra elementos que cumplen una condición
--- @param tabla table Tabla original
--- @param predicado function Función que recibe (valor, clave) y retorna boolean
--- @return table Nueva tabla con elementos filtrados
function Table.Filtrar(tabla, predicado)
    if type(tabla) ~= "table" or type(predicado) ~= "function" then return {} end

    local resultado = {}
    for clave, valor in pairs(tabla) do
        if predicado(valor, clave) then
            resultado[clave] = valor
        end
    end

    return resultado
end

--- Filtra elementos de un array que cumplen una condición
--- @param tabla table Array original
--- @param predicado function Función que recibe (valor, indice) y retorna boolean
--- @return table Nuevo array con elementos filtrados
function Table.FiltrarArray(tabla, predicado)
    if type(tabla) ~= "table" or type(predicado) ~= "function" then return {} end

    local resultado = {}
    for indice, valor in ipairs(tabla) do
        if predicado(valor, indice) then
            table.insert(resultado, valor)
        end
    end

    return resultado
end

--- Reduce una tabla a un solo valor
--- @param tabla table Tabla original
--- @param reductor function Función que recibe (acumulador, valor, clave)
--- @param valorInicial any Valor inicial del acumulador
--- @return any Valor reducido
function Table.Reducir(tabla, reductor, valorInicial)
    if type(tabla) ~= "table" or type(reductor) ~= "function" then return valorInicial end

    local acumulador = valorInicial
    for clave, valor in pairs(tabla) do
        acumulador = reductor(acumulador, valor, clave)
    end

    return acumulador
end

--- Reduce un array a un solo valor
--- @param tabla table Array original
--- @param reductor function Función que recibe (acumulador, valor, indice)
--- @param valorInicial any Valor inicial del acumulador
--- @return any Valor reducido
function Table.ReducirArray(tabla, reductor, valorInicial)
    if type(tabla) ~= "table" or type(reductor) ~= "function" then return valorInicial end

    local acumulador = valorInicial
    for indice, valor in ipairs(tabla) do
        acumulador = reductor(acumulador, valor, indice)
    end

    return acumulador
end

--- Ejecuta una función para cada elemento
--- @param tabla table Tabla original
--- @param funcion function Función que recibe (valor, clave)
function Table.ParaCada(tabla, funcion)
    if type(tabla) ~= "table" or type(funcion) ~= "function" then return end

    for clave, valor in pairs(tabla) do
        funcion(valor, clave)
    end
end

--- Verifica si todos los elementos cumplen una condición
--- @param tabla table Tabla original
--- @param predicado function Función que recibe (valor, clave) y retorna boolean
--- @return boolean True si todos cumplen
function Table.Todos(tabla, predicado)
    if type(tabla) ~= "table" or type(predicado) ~= "function" then return false end

    for clave, valor in pairs(tabla) do
        if not predicado(valor, clave) then
            return false
        end
    end

    return true
end

--- Verifica si algún elemento cumple una condición
--- @param tabla table Tabla original
--- @param predicado function Función que recibe (valor, clave) y retorna boolean
--- @return boolean True si alguno cumple
function Table.Alguno(tabla, predicado)
    if type(tabla) ~= "table" or type(predicado) ~= "function" then return false end

    for clave, valor in pairs(tabla) do
        if predicado(valor, clave) then
            return true
        end
    end

    return false
end

-- ============================================================================
-- FUNCIONES DE ORDENAMIENTO
-- ============================================================================

--- Ordena un array (retorna nueva tabla)
--- @param tabla table Array a ordenar
--- @param comparador function Función de comparación (opcional)
--- @return table Nuevo array ordenado
function Table.Ordenar(tabla, comparador)
    if type(tabla) ~= "table" then return {} end

    local resultado = Table.Copiar(tabla)
    table.sort(resultado, comparador)

    return resultado
end

--- Ordena un array de tablas por una clave específica
--- @param tabla table Array de tablas
--- @param clave string Clave por la cual ordenar
--- @param descendente boolean True para orden descendente
--- @return table Nuevo array ordenado
function Table.OrdenarPor(tabla, clave, descendente)
    if type(tabla) ~= "table" then return {} end

    local resultado = Table.Copiar(tabla)

    table.sort(resultado, function(a, b)
        local valorA = type(a) == "table" and a[clave] or nil
        local valorB = type(b) == "table" and b[clave] or nil

        if valorA == nil and valorB == nil then return false end
        if valorA == nil then return not descendente end
        if valorB == nil then return descendente end

        if descendente then
            return valorA > valorB
        else
            return valorA < valorB
        end
    end)

    return resultado
end

--- Invierte el orden de un array
--- @param tabla table Array a invertir
--- @return table Nuevo array invertido
function Table.Invertir(tabla)
    if type(tabla) ~= "table" then return {} end

    local resultado = {}
    local longitud = #tabla

    for i = longitud, 1, -1 do
        table.insert(resultado, tabla[i])
    end

    return resultado
end

--- Mezcla aleatoriamente un array (Fisher-Yates)
--- @param tabla table Array a mezclar
--- @return table Nuevo array mezclado
function Table.Mezclar(tabla)
    if type(tabla) ~= "table" then return {} end

    local resultado = Table.Copiar(tabla)
    local n = #resultado

    for i = n, 2, -1 do
        local j = math.random(i)
        resultado[i], resultado[j] = resultado[j], resultado[i]
    end

    return resultado
end

-- ============================================================================
-- FUNCIONES DE INFORMACIÓN
-- ============================================================================

--- Cuenta los elementos de una tabla
--- @param tabla table Tabla a contar
--- @return number Número de elementos
function Table.Contar(tabla)
    if type(tabla) ~= "table" then return 0 end

    local contador = 0
    for _ in pairs(tabla) do
        contador = contador + 1
    end

    return contador
end

--- Verifica si una tabla está vacía
--- @param tabla table Tabla a verificar
--- @return boolean True si está vacía
function Table.EstaVacia(tabla)
    if type(tabla) ~= "table" then return true end
    return next(tabla) == nil
end

--- Verifica si es un array (índices numéricos secuenciales)
--- @param tabla table Tabla a verificar
--- @return boolean True si es un array
function Table.EsArray(tabla)
    if type(tabla) ~= "table" then return false end

    local contador = 0
    for _ in pairs(tabla) do
        contador = contador + 1
    end

    return contador == #tabla
end

--- Obtiene la longitud de un array
--- @param tabla table Array
--- @return number Longitud del array
function Table.Longitud(tabla)
    if type(tabla) ~= "table" then return 0 end
    return #tabla
end

-- ============================================================================
-- FUNCIONES DE SLICING
-- ============================================================================

--- Obtiene una porción de un array
--- @param tabla table Array original
--- @param inicio number Índice inicial (inclusivo, default: 1)
--- @param fin number Índice final (inclusivo, default: longitud)
--- @return table Nuevo array con la porción
function Table.Porcion(tabla, inicio, fin)
    if type(tabla) ~= "table" then return {} end

    inicio = inicio or 1
    fin = fin or #tabla

    if inicio < 0 then inicio = #tabla + inicio + 1 end
    if fin < 0 then fin = #tabla + fin + 1 end

    local resultado = {}
    for i = inicio, fin do
        if tabla[i] ~= nil then
            table.insert(resultado, tabla[i])
        end
    end

    return resultado
end

--- Obtiene los primeros N elementos
--- @param tabla table Array original
--- @param n number Cantidad de elementos
--- @return table Nuevo array con los primeros N elementos
function Table.Primeros(tabla, n)
    return Table.Porcion(tabla, 1, n)
end

--- Obtiene los últimos N elementos
--- @param tabla table Array original
--- @param n number Cantidad de elementos
--- @return table Nuevo array con los últimos N elementos
function Table.Ultimos(tabla, n)
    if type(tabla) ~= "table" then return {} end
    local longitud = #tabla
    return Table.Porcion(tabla, longitud - n + 1, longitud)
end

-- ============================================================================
-- FUNCIONES DE CONJUNTOS
-- ============================================================================

--- Obtiene elementos únicos de un array
--- @param tabla table Array original
--- @return table Nuevo array sin duplicados
function Table.Unicos(tabla)
    if type(tabla) ~= "table" then return {} end

    local vistos = {}
    local resultado = {}

    for _, valor in ipairs(tabla) do
        if not vistos[valor] then
            vistos[valor] = true
            table.insert(resultado, valor)
        end
    end

    return resultado
end

--- Obtiene la unión de dos arrays
--- @param tabla1 table Primer array
--- @param tabla2 table Segundo array
--- @return table Array con la unión (sin duplicados)
function Table.Union(tabla1, tabla2)
    local combinado = Table.Extender(tabla1 or {}, tabla2 or {})
    return Table.Unicos(combinado)
end

--- Obtiene la intersección de dos arrays
--- @param tabla1 table Primer array
--- @param tabla2 table Segundo array
--- @return table Array con elementos comunes
function Table.Interseccion(tabla1, tabla2)
    if type(tabla1) ~= "table" or type(tabla2) ~= "table" then return {} end

    local conjunto2 = {}
    for _, v in ipairs(tabla2) do
        conjunto2[v] = true
    end

    local resultado = {}
    local vistos = {}

    for _, v in ipairs(tabla1) do
        if conjunto2[v] and not vistos[v] then
            vistos[v] = true
            table.insert(resultado, v)
        end
    end

    return resultado
end

--- Obtiene la diferencia entre dos arrays
--- @param tabla1 table Primer array
--- @param tabla2 table Segundo array
--- @return table Array con elementos de tabla1 que no están en tabla2
function Table.Diferencia(tabla1, tabla2)
    if type(tabla1) ~= "table" then return {} end
    if type(tabla2) ~= "table" then return Table.Copiar(tabla1) end

    local conjunto2 = {}
    for _, v in ipairs(tabla2) do
        conjunto2[v] = true
    end

    local resultado = {}
    local vistos = {}

    for _, v in ipairs(tabla1) do
        if not conjunto2[v] and not vistos[v] then
            vistos[v] = true
            table.insert(resultado, v)
        end
    end

    return resultado
end

-- Exportar para compatibilidad
return Table
