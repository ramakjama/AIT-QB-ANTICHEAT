--[[
    AIT Framework - Utilidades Matemáticas
    Funciones matemáticas compartidas para el framework

    Namespace: AIT.Utils.Math
    Autor: AIT Development Team
    Versión: 1.0.0
]]

AIT = AIT or {}
AIT.Utils = AIT.Utils or {}
AIT.Utils.Math = {}

local Math = AIT.Utils.Math

-- ============================================================================
-- FUNCIONES BÁSICAS
-- ============================================================================

--- Limita un valor entre un mínimo y un máximo
--- @param valor number Valor a limitar
--- @param minimo number Valor mínimo permitido
--- @param maximo number Valor máximo permitido
--- @return number Valor limitado
function Math.Clamp(valor, minimo, maximo)
    if type(valor) ~= "number" then return minimo end
    if minimo > maximo then minimo, maximo = maximo, minimo end
    return math.max(minimo, math.min(maximo, valor))
end

--- Interpola linealmente entre dos valores
--- @param inicio number Valor inicial
--- @param fin number Valor final
--- @param t number Factor de interpolación (0-1)
--- @return number Valor interpolado
function Math.Lerp(inicio, fin, t)
    t = Math.Clamp(t, 0.0, 1.0)
    return inicio + (fin - inicio) * t
end

--- Interpola linealmente sin límites en t
--- @param inicio number Valor inicial
--- @param fin number Valor final
--- @param t number Factor de interpolación
--- @return number Valor interpolado
function Math.LerpSinLimite(inicio, fin, t)
    return inicio + (fin - inicio) * t
end

--- Calcula el factor de interpolación inverso
--- @param inicio number Valor inicial
--- @param fin number Valor final
--- @param valor number Valor actual
--- @return number Factor t (0-1)
function Math.InverseLerp(inicio, fin, valor)
    if inicio == fin then return 0 end
    return Math.Clamp((valor - inicio) / (fin - inicio), 0.0, 1.0)
end

--- Redondea un número a N decimales
--- @param numero number Número a redondear
--- @param decimales number Cantidad de decimales (default: 0)
--- @return number Número redondeado
function Math.Redondear(numero, decimales)
    decimales = decimales or 0
    local multiplicador = 10 ^ decimales
    return math.floor(numero * multiplicador + 0.5) / multiplicador
end

--- Redondea hacia abajo
--- @param numero number Número a redondear
--- @param decimales number Cantidad de decimales (default: 0)
--- @return number Número redondeado hacia abajo
function Math.RedondearAbajo(numero, decimales)
    decimales = decimales or 0
    local multiplicador = 10 ^ decimales
    return math.floor(numero * multiplicador) / multiplicador
end

--- Redondea hacia arriba
--- @param numero number Número a redondear
--- @param decimales number Cantidad de decimales (default: 0)
--- @return number Número redondeado hacia arriba
function Math.RedondearArriba(numero, decimales)
    decimales = decimales or 0
    local multiplicador = 10 ^ decimales
    return math.ceil(numero * multiplicador) / multiplicador
end

-- ============================================================================
-- NÚMEROS ALEATORIOS
-- ============================================================================

--- Genera un número aleatorio entre min y max (inclusivo)
--- @param minimo number Valor mínimo
--- @param maximo number Valor máximo
--- @return number Número aleatorio
function Math.Aleatorio(minimo, maximo)
    if not minimo then return math.random() end
    if not maximo then return math.random(minimo) end
    return math.random(minimo, maximo)
end

--- Genera un número decimal aleatorio entre min y max
--- @param minimo number Valor mínimo
--- @param maximo number Valor máximo
--- @return number Número decimal aleatorio
function Math.AleatorioDecimal(minimo, maximo)
    return minimo + math.random() * (maximo - minimo)
end

--- Genera un booleano aleatorio con probabilidad configurable
--- @param probabilidad number Probabilidad de true (0-1, default: 0.5)
--- @return boolean Valor aleatorio
function Math.AleatorioBooleano(probabilidad)
    probabilidad = probabilidad or 0.5
    return math.random() < probabilidad
end

--- Selecciona un elemento aleatorio de una tabla
--- @param tabla table Tabla con elementos
--- @return any Elemento aleatorio o nil si está vacía
function Math.AleatorioDeTabla(tabla)
    if not tabla or #tabla == 0 then return nil end
    return tabla[math.random(#tabla)]
end

-- ============================================================================
-- DISTANCIA Y ÁNGULOS
-- ============================================================================

--- Calcula la distancia entre dos puntos 2D
--- @param x1 number Coordenada X del primer punto
--- @param y1 number Coordenada Y del primer punto
--- @param x2 number Coordenada X del segundo punto
--- @param y2 number Coordenada Y del segundo punto
--- @return number Distancia entre los puntos
function Math.Distancia2D(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

--- Calcula la distancia entre dos puntos 3D
--- @param x1 number Coordenada X del primer punto
--- @param y1 number Coordenada Y del primer punto
--- @param z1 number Coordenada Z del primer punto
--- @param x2 number Coordenada X del segundo punto
--- @param y2 number Coordenada Y del segundo punto
--- @param z2 number Coordenada Z del segundo punto
--- @return number Distancia entre los puntos
function Math.Distancia3D(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- Calcula la distancia entre dos vectores (vector3 de FiveM)
--- @param vec1 vector3 Primer vector
--- @param vec2 vector3 Segundo vector
--- @return number Distancia entre vectores
function Math.DistanciaVectores(vec1, vec2)
    return Math.Distancia3D(vec1.x, vec1.y, vec1.z, vec2.x, vec2.y, vec2.z)
end

--- Calcula el ángulo entre dos puntos en grados
--- @param x1 number Coordenada X del primer punto
--- @param y1 number Coordenada Y del primer punto
--- @param x2 number Coordenada X del segundo punto
--- @param y2 number Coordenada Y del segundo punto
--- @return number Ángulo en grados
function Math.Angulo2D(x1, y1, x2, y2)
    return math.deg(math.atan2(y2 - y1, x2 - x1))
end

--- Convierte grados a radianes
--- @param grados number Ángulo en grados
--- @return number Ángulo en radianes
function Math.GradosARadianes(grados)
    return grados * (math.pi / 180)
end

--- Convierte radianes a grados
--- @param radianes number Ángulo en radianes
--- @return number Ángulo en grados
function Math.RadianesAGrados(radianes)
    return radianes * (180 / math.pi)
end

--- Normaliza un ángulo a rango 0-360
--- @param angulo number Ángulo a normalizar
--- @return number Ángulo normalizado
function Math.NormalizarAngulo(angulo)
    angulo = angulo % 360
    if angulo < 0 then angulo = angulo + 360 end
    return angulo
end

-- ============================================================================
-- OPERACIONES VECTORIALES
-- ============================================================================

--- Suma dos vectores
--- @param v1 table|vector3 Primer vector {x, y, z}
--- @param v2 table|vector3 Segundo vector {x, y, z}
--- @return table Vector resultante
function Math.SumarVectores(v1, v2)
    return {
        x = (v1.x or 0) + (v2.x or 0),
        y = (v1.y or 0) + (v2.y or 0),
        z = (v1.z or 0) + (v2.z or 0)
    }
end

--- Resta dos vectores
--- @param v1 table|vector3 Primer vector
--- @param v2 table|vector3 Vector a restar
--- @return table Vector resultante
function Math.RestarVectores(v1, v2)
    return {
        x = (v1.x or 0) - (v2.x or 0),
        y = (v1.y or 0) - (v2.y or 0),
        z = (v1.z or 0) - (v2.z or 0)
    }
end

--- Multiplica un vector por un escalar
--- @param v table|vector3 Vector
--- @param escalar number Escalar
--- @return table Vector resultante
function Math.MultiplicarVector(v, escalar)
    return {
        x = (v.x or 0) * escalar,
        y = (v.y or 0) * escalar,
        z = (v.z or 0) * escalar
    }
end

--- Calcula la magnitud de un vector
--- @param v table|vector3 Vector
--- @return number Magnitud del vector
function Math.MagnitudVector(v)
    return math.sqrt((v.x or 0)^2 + (v.y or 0)^2 + (v.z or 0)^2)
end

--- Normaliza un vector (magnitud = 1)
--- @param v table|vector3 Vector a normalizar
--- @return table Vector normalizado
function Math.NormalizarVector(v)
    local mag = Math.MagnitudVector(v)
    if mag == 0 then return {x = 0, y = 0, z = 0} end
    return Math.MultiplicarVector(v, 1 / mag)
end

--- Producto punto de dos vectores
--- @param v1 table|vector3 Primer vector
--- @param v2 table|vector3 Segundo vector
--- @return number Producto punto
function Math.ProductoPunto(v1, v2)
    return (v1.x or 0) * (v2.x or 0) + (v1.y or 0) * (v2.y or 0) + (v1.z or 0) * (v2.z or 0)
end

--- Producto cruz de dos vectores
--- @param v1 table|vector3 Primer vector
--- @param v2 table|vector3 Segundo vector
--- @return table Vector resultante
function Math.ProductoCruz(v1, v2)
    return {
        x = (v1.y or 0) * (v2.z or 0) - (v1.z or 0) * (v2.y or 0),
        y = (v1.z or 0) * (v2.x or 0) - (v1.x or 0) * (v2.z or 0),
        z = (v1.x or 0) * (v2.y or 0) - (v1.y or 0) * (v2.x or 0)
    }
end

-- ============================================================================
-- UTILIDADES ADICIONALES
-- ============================================================================

--- Verifica si un punto está dentro de un círculo
--- @param px number Coordenada X del punto
--- @param py number Coordenada Y del punto
--- @param cx number Coordenada X del centro
--- @param cy number Coordenada Y del centro
--- @param radio number Radio del círculo
--- @return boolean True si está dentro
function Math.PuntoEnCirculo(px, py, cx, cy, radio)
    return Math.Distancia2D(px, py, cx, cy) <= radio
end

--- Verifica si un punto está dentro de una esfera
--- @param px number Coordenada X del punto
--- @param py number Coordenada Y del punto
--- @param pz number Coordenada Z del punto
--- @param cx number Coordenada X del centro
--- @param cy number Coordenada Y del centro
--- @param cz number Coordenada Z del centro
--- @param radio number Radio de la esfera
--- @return boolean True si está dentro
function Math.PuntoEnEsfera(px, py, pz, cx, cy, cz, radio)
    return Math.Distancia3D(px, py, pz, cx, cy, cz) <= radio
end

--- Calcula el porcentaje
--- @param valor number Valor actual
--- @param total number Valor total
--- @return number Porcentaje (0-100)
function Math.Porcentaje(valor, total)
    if total == 0 then return 0 end
    return (valor / total) * 100
end

--- Mapea un valor de un rango a otro
--- @param valor number Valor a mapear
--- @param minEntrada number Mínimo del rango de entrada
--- @param maxEntrada number Máximo del rango de entrada
--- @param minSalida number Mínimo del rango de salida
--- @param maxSalida number Máximo del rango de salida
--- @return number Valor mapeado
function Math.Mapear(valor, minEntrada, maxEntrada, minSalida, maxSalida)
    local t = Math.InverseLerp(minEntrada, maxEntrada, valor)
    return Math.Lerp(minSalida, maxSalida, t)
end

--- Verifica si dos números son aproximadamente iguales
--- @param a number Primer número
--- @param b number Segundo número
--- @param tolerancia number Tolerancia (default: 0.0001)
--- @return boolean True si son aproximadamente iguales
function Math.AproximadamenteIgual(a, b, tolerancia)
    tolerancia = tolerancia or 0.0001
    return math.abs(a - b) <= tolerancia
end

--- Obtiene el signo de un número
--- @param numero number Número
--- @return number -1, 0 o 1
function Math.Signo(numero)
    if numero > 0 then return 1
    elseif numero < 0 then return -1
    else return 0 end
end

-- Exportar para compatibilidad
return Math
