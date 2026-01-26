--[[
    AIT Framework - Utilidades Criptográficas
    Funciones de generación de IDs, hashing y encoding

    Namespace: AIT.Utils.Crypto
    Autor: AIT Development Team
    Versión: 1.0.0

    NOTA: Estas funciones son para uso básico en el juego.
    Para seguridad real, usar librerías criptográficas apropiadas.
]]

AIT = AIT or {}
AIT.Utils = AIT.Utils or {}
AIT.Utils.Crypto = {}

local Crypto = AIT.Utils.Crypto

-- ============================================================================
-- CONSTANTES
-- ============================================================================

-- Caracteres para generación de IDs
local CARACTERES_ALFANUMERICOS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
local CARACTERES_HEXADECIMALES = "0123456789abcdef"
local CARACTERES_NUMERICOS = "0123456789"
local CARACTERES_MAYUSCULAS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local CARACTERES_MINUSCULAS = "abcdefghijklmnopqrstuvwxyz"

-- Tabla Base64 estándar
local TABLA_BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- ============================================================================
-- GENERACIÓN DE IDS
-- ============================================================================

--- Genera un ID aleatorio con caracteres específicos
--- @param longitud number Longitud del ID
--- @param caracteres string Caracteres a usar
--- @return string ID generado
function Crypto.GenerarIdConCaracteres(longitud, caracteres)
    longitud = longitud or 8
    caracteres = caracteres or CARACTERES_ALFANUMERICOS

    local resultado = {}
    local totalCaracteres = #caracteres

    for i = 1, longitud do
        local indice = math.random(1, totalCaracteres)
        resultado[i] = string.sub(caracteres, indice, indice)
    end

    return table.concat(resultado)
end

--- Genera un ID alfanumérico aleatorio
--- @param longitud number Longitud del ID (default: 8)
--- @return string ID generado
function Crypto.GenerarId(longitud)
    return Crypto.GenerarIdConCaracteres(longitud or 8, CARACTERES_ALFANUMERICOS)
end

--- Genera un ID hexadecimal aleatorio
--- @param longitud number Longitud del ID (default: 16)
--- @return string ID hexadecimal
function Crypto.GenerarIdHex(longitud)
    return Crypto.GenerarIdConCaracteres(longitud or 16, CARACTERES_HEXADECIMALES)
end

--- Genera un ID numérico aleatorio
--- @param longitud number Longitud del ID (default: 8)
--- @return string ID numérico
function Crypto.GenerarIdNumerico(longitud)
    return Crypto.GenerarIdConCaracteres(longitud or 8, CARACTERES_NUMERICOS)
end

--- Genera un ID en mayúsculas
--- @param longitud number Longitud del ID (default: 8)
--- @return string ID en mayúsculas
function Crypto.GenerarIdMayusculas(longitud)
    return Crypto.GenerarIdConCaracteres(longitud or 8, CARACTERES_MAYUSCULAS .. CARACTERES_NUMERICOS)
end

--- Genera un UUID v4 (formato estándar)
--- @return string UUID en formato xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
function Crypto.GenerarUUID()
    local plantilla = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

    return string.gsub(plantilla, "[xy]", function(c)
        local r = math.random(0, 15)
        local v = (c == "x") and r or ((r % 4) + 8)
        return string.format("%x", v)
    end)
end

--- Genera un UUID corto (sin guiones)
--- @return string UUID sin guiones
function Crypto.GenerarUUIDCorto()
    return string.gsub(Crypto.GenerarUUID(), "-", "")
end

--- Genera un ID de ciudadano estilo QBCore
--- @return string ID de ciudadano (ABC12345)
function Crypto.GenerarCitizenId()
    local letras = Crypto.GenerarIdConCaracteres(3, CARACTERES_MAYUSCULAS)
    local numeros = Crypto.GenerarIdConCaracteres(5, CARACTERES_NUMERICOS)
    return letras .. numeros
end

--- Genera un número de placa aleatorio
--- @param formato string Formato: "espana", "generico" (default: "espana")
--- @return string Placa generada
function Crypto.GenerarPlaca(formato)
    formato = formato or "espana"

    if formato == "espana" then
        -- Formato español nuevo: 0000XXX
        local numeros = Crypto.GenerarIdConCaracteres(4, CARACTERES_NUMERICOS)
        -- Letras permitidas en placas españolas (sin vocales ni confusas)
        local letrasPlaca = "BCDFGHJKLMNPRSTVWXYZ"
        local letras = Crypto.GenerarIdConCaracteres(3, letrasPlaca)
        return numeros .. letras
    else
        -- Formato genérico
        return Crypto.GenerarIdConCaracteres(2, CARACTERES_NUMERICOS) ..
               Crypto.GenerarIdConCaracteres(3, CARACTERES_MAYUSCULAS) ..
               Crypto.GenerarIdConCaracteres(2, CARACTERES_NUMERICOS)
    end
end

--- Genera un número de teléfono aleatorio
--- @param prefijo string Prefijo del número (default: "6")
--- @return string Número de teléfono
function Crypto.GenerarTelefono(prefijo)
    prefijo = prefijo or "6"
    local longitud = 9 - #prefijo
    return prefijo .. Crypto.GenerarIdConCaracteres(longitud, CARACTERES_NUMERICOS)
end

-- ============================================================================
-- FUNCIONES HASH
-- ============================================================================

--- Hash simple DJB2 (para uso interno, NO para seguridad)
--- @param cadena string Cadena a hashear
--- @return number Hash numérico
function Crypto.HashDJB2(cadena)
    if type(cadena) ~= "string" then return 0 end

    local hash = 5381

    for i = 1, #cadena do
        local char = string.byte(cadena, i)
        hash = ((hash * 33) + char) % 4294967296
    end

    return hash
end

--- Hash FNV-1a (para uso interno, NO para seguridad)
--- @param cadena string Cadena a hashear
--- @return number Hash numérico
function Crypto.HashFNV1a(cadena)
    if type(cadena) ~= "string" then return 0 end

    local hash = 2166136261

    for i = 1, #cadena do
        local char = string.byte(cadena, i)
        hash = (hash ~ char) % 4294967296
        hash = (hash * 16777619) % 4294967296
    end

    return hash
end

--- Hash simple que retorna string hexadecimal
--- @param cadena string Cadena a hashear
--- @return string Hash en formato hexadecimal
function Crypto.Hash(cadena)
    local hash = Crypto.HashDJB2(cadena)
    return string.format("%08x", hash)
end

--- Hash con salt
--- @param cadena string Cadena a hashear
--- @param salt string Salt a agregar
--- @return string Hash con salt
function Crypto.HashConSalt(cadena, salt)
    salt = salt or Crypto.GenerarId(8)
    local combinado = salt .. cadena .. salt
    return salt .. ":" .. Crypto.Hash(combinado)
end

--- Verifica un hash con salt
--- @param cadena string Cadena original
--- @param hashCompleto string Hash con salt (salt:hash)
--- @return boolean True si coincide
function Crypto.VerificarHashConSalt(cadena, hashCompleto)
    if type(hashCompleto) ~= "string" then return false end

    local salt, hashOriginal = string.match(hashCompleto, "^([^:]+):(.+)$")
    if not salt then return false end

    local combinado = salt .. cadena .. salt
    return Crypto.Hash(combinado) == hashOriginal
end

--- Genera un hash para contraseña (uso básico de juego)
--- @param contrasena string Contraseña
--- @param salt string Salt opcional
--- @return string Hash de la contraseña
function Crypto.HashContrasena(contrasena, salt)
    salt = salt or Crypto.GenerarId(16)

    -- Múltiples iteraciones para hacerlo más lento
    local hash = contrasena
    for i = 1, 100 do
        hash = Crypto.Hash(salt .. hash .. salt .. i)
    end

    return salt .. ":" .. hash
end

--- Verifica una contraseña contra su hash
--- @param contrasena string Contraseña a verificar
--- @param hashGuardado string Hash guardado (salt:hash)
--- @return boolean True si coincide
function Crypto.VerificarContrasena(contrasena, hashGuardado)
    if type(hashGuardado) ~= "string" then return false end

    local salt, hashOriginal = string.match(hashGuardado, "^([^:]+):(.+)$")
    if not salt then return false end

    local hash = contrasena
    for i = 1, 100 do
        hash = Crypto.Hash(salt .. hash .. salt .. i)
    end

    return hash == hashOriginal
end

-- ============================================================================
-- ENCODING BASE64
-- ============================================================================

--- Codifica una cadena en Base64
--- @param datos string Datos a codificar
--- @return string Datos codificados en Base64
function Crypto.CodificarBase64(datos)
    if type(datos) ~= "string" then return "" end

    local resultado = {}
    local padding = ""

    -- Agregar padding si es necesario
    local resto = #datos % 3
    if resto > 0 then
        padding = string.rep("=", 3 - resto)
        datos = datos .. string.rep("\0", 3 - resto)
    end

    -- Procesar en bloques de 3 bytes
    for i = 1, #datos, 3 do
        local b1 = string.byte(datos, i)
        local b2 = string.byte(datos, i + 1) or 0
        local b3 = string.byte(datos, i + 2) or 0

        -- Convertir 3 bytes a 4 caracteres Base64
        local n = b1 * 65536 + b2 * 256 + b3

        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64

        resultado[#resultado + 1] = string.sub(TABLA_BASE64, c1 + 1, c1 + 1)
        resultado[#resultado + 1] = string.sub(TABLA_BASE64, c2 + 1, c2 + 1)
        resultado[#resultado + 1] = string.sub(TABLA_BASE64, c3 + 1, c3 + 1)
        resultado[#resultado + 1] = string.sub(TABLA_BASE64, c4 + 1, c4 + 1)
    end

    -- Reemplazar caracteres finales con padding
    local resultadoStr = table.concat(resultado)
    if #padding > 0 then
        resultadoStr = string.sub(resultadoStr, 1, -(#padding + 1)) .. padding
    end

    return resultadoStr
end

--- Decodifica una cadena Base64
--- @param datos string Datos en Base64
--- @return string Datos decodificados
function Crypto.DecodificarBase64(datos)
    if type(datos) ~= "string" then return "" end

    -- Crear tabla de decodificación
    local decode = {}
    for i = 1, #TABLA_BASE64 do
        decode[string.sub(TABLA_BASE64, i, i)] = i - 1
    end

    -- Eliminar padding y contar
    local padding = 0
    if string.sub(datos, -2) == "==" then
        padding = 2
        datos = string.sub(datos, 1, -3) .. "AA"
    elseif string.sub(datos, -1) == "=" then
        padding = 1
        datos = string.sub(datos, 1, -2) .. "A"
    end

    local resultado = {}

    -- Procesar en bloques de 4 caracteres
    for i = 1, #datos, 4 do
        local c1 = decode[string.sub(datos, i, i)] or 0
        local c2 = decode[string.sub(datos, i + 1, i + 1)] or 0
        local c3 = decode[string.sub(datos, i + 2, i + 2)] or 0
        local c4 = decode[string.sub(datos, i + 3, i + 3)] or 0

        local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4

        resultado[#resultado + 1] = string.char(math.floor(n / 65536) % 256)
        resultado[#resultado + 1] = string.char(math.floor(n / 256) % 256)
        resultado[#resultado + 1] = string.char(n % 256)
    end

    -- Eliminar bytes de padding
    local resultadoStr = table.concat(resultado)
    if padding > 0 then
        resultadoStr = string.sub(resultadoStr, 1, -padding - 1)
    end

    return resultadoStr
end

-- ============================================================================
-- ENCODING HEXADECIMAL
-- ============================================================================

--- Codifica una cadena en hexadecimal
--- @param datos string Datos a codificar
--- @return string Datos en hexadecimal
function Crypto.CodificarHex(datos)
    if type(datos) ~= "string" then return "" end

    local resultado = {}
    for i = 1, #datos do
        resultado[i] = string.format("%02x", string.byte(datos, i))
    end

    return table.concat(resultado)
end

--- Decodifica una cadena hexadecimal
--- @param datos string Datos en hexadecimal
--- @return string Datos decodificados
function Crypto.DecodificarHex(datos)
    if type(datos) ~= "string" then return "" end
    if #datos % 2 ~= 0 then return "" end

    local resultado = {}
    for i = 1, #datos, 2 do
        local hex = string.sub(datos, i, i + 1)
        local numero = tonumber(hex, 16)
        if numero then
            resultado[#resultado + 1] = string.char(numero)
        end
    end

    return table.concat(resultado)
end

-- ============================================================================
-- XOR ENCODING (OFUSCACIÓN SIMPLE)
-- ============================================================================

--- Codifica/decodifica una cadena usando XOR (simétrico)
--- @param datos string Datos a procesar
--- @param clave string Clave de XOR
--- @return string Datos procesados
function Crypto.XOR(datos, clave)
    if type(datos) ~= "string" or type(clave) ~= "string" then return "" end
    if #clave == 0 then return datos end

    local resultado = {}
    local longitudClave = #clave

    for i = 1, #datos do
        local indiceClave = ((i - 1) % longitudClave) + 1
        local byteOriginal = string.byte(datos, i)
        local byteClave = string.byte(clave, indiceClave)
        resultado[i] = string.char(byteOriginal ~ byteClave)
    end

    return table.concat(resultado)
end

--- Codifica con XOR y retorna en Base64
--- @param datos string Datos a codificar
--- @param clave string Clave de XOR
--- @return string Datos codificados en Base64
function Crypto.CodificarXORBase64(datos, clave)
    local xored = Crypto.XOR(datos, clave)
    return Crypto.CodificarBase64(xored)
end

--- Decodifica de Base64 y aplica XOR
--- @param datos string Datos en Base64
--- @param clave string Clave de XOR
--- @return string Datos decodificados
function Crypto.DecodificarXORBase64(datos, clave)
    local decoded = Crypto.DecodificarBase64(datos)
    return Crypto.XOR(decoded, clave)
end

-- ============================================================================
-- UTILIDADES DE TIEMPO
-- ============================================================================

--- Genera un timestamp único con componente aleatorio
--- @return string Timestamp único
function Crypto.GenerarTimestampUnico()
    local tiempo = os.time()
    local aleatorio = Crypto.GenerarIdConCaracteres(4, CARACTERES_HEXADECIMALES)
    return string.format("%x%s", tiempo, aleatorio)
end

--- Genera un ID ordenable por tiempo (similar a ULID simplificado)
--- @return string ID ordenable
function Crypto.GenerarIdOrdenable()
    local tiempo = os.time()
    -- Convertir tiempo a base32 simplificada (6 caracteres)
    local tiempoStr = string.format("%010x", tiempo)
    -- Agregar componente aleatorio
    local aleatorio = Crypto.GenerarId(10)
    return tiempoStr .. aleatorio
end

-- ============================================================================
-- CHECKSUM
-- ============================================================================

--- Calcula un checksum simple (suma de bytes)
--- @param datos string Datos para calcular checksum
--- @return number Checksum
function Crypto.Checksum(datos)
    if type(datos) ~= "string" then return 0 end

    local suma = 0
    for i = 1, #datos do
        suma = (suma + string.byte(datos, i)) % 65536
    end

    return suma
end

--- Calcula checksum y lo agrega a los datos
--- @param datos string Datos originales
--- @return string Datos con checksum
function Crypto.AgregarChecksum(datos)
    local checksum = Crypto.Checksum(datos)
    return datos .. string.format("%04x", checksum)
end

--- Verifica y extrae datos con checksum
--- @param datos string Datos con checksum
--- @return string|nil Datos sin checksum o nil si es inválido
--- @return boolean True si checksum válido
function Crypto.VerificarChecksum(datos)
    if type(datos) ~= "string" or #datos < 4 then
        return nil, false
    end

    local contenido = string.sub(datos, 1, -5)
    local checksumGuardado = string.sub(datos, -4)
    local checksumCalculado = string.format("%04x", Crypto.Checksum(contenido))

    if checksumGuardado == checksumCalculado then
        return contenido, true
    end

    return nil, false
end

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================

-- Inicializar semilla aleatoria
math.randomseed(os.time() + (os.clock() * 1000))

-- Descartar primeros valores (mejor aleatoriedad)
for i = 1, 10 do
    math.random()
end

-- Exportar para compatibilidad
return Crypto
