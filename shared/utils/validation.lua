--[[
    AIT Framework - Utilidades de Validación
    Funciones de validación de datos compartidas

    Namespace: AIT.Utils.Validation
    Autor: AIT Development Team
    Versión: 1.0.0
]]

AIT = AIT or {}
AIT.Utils = AIT.Utils or {}
AIT.Utils.Validation = {}

local Validation = AIT.Utils.Validation

-- ============================================================================
-- VALIDACIÓN DE TIPOS BÁSICOS
-- ============================================================================

--- Verifica si un valor es string
--- @param valor any Valor a verificar
--- @return boolean True si es string
function Validation.EsString(valor)
    return type(valor) == "string"
end

--- Verifica si un valor es número
--- @param valor any Valor a verificar
--- @return boolean True si es número
function Validation.EsNumero(valor)
    return type(valor) == "number"
end

--- Verifica si un valor es entero
--- @param valor any Valor a verificar
--- @return boolean True si es entero
function Validation.EsEntero(valor)
    if type(valor) ~= "number" then return false end
    return valor == math.floor(valor)
end

--- Verifica si un valor es decimal
--- @param valor any Valor a verificar
--- @return boolean True si es decimal
function Validation.EsDecimal(valor)
    if type(valor) ~= "number" then return false end
    return valor ~= math.floor(valor)
end

--- Verifica si un valor es booleano
--- @param valor any Valor a verificar
--- @return boolean True si es booleano
function Validation.EsBooleano(valor)
    return type(valor) == "boolean"
end

--- Verifica si un valor es tabla
--- @param valor any Valor a verificar
--- @return boolean True si es tabla
function Validation.EsTabla(valor)
    return type(valor) == "table"
end

--- Verifica si un valor es función
--- @param valor any Valor a verificar
--- @return boolean True si es función
function Validation.EsFuncion(valor)
    return type(valor) == "function"
end

--- Verifica si un valor es nil
--- @param valor any Valor a verificar
--- @return boolean True si es nil
function Validation.EsNil(valor)
    return valor == nil
end

--- Verifica si un valor es userdata (entidades de FiveM)
--- @param valor any Valor a verificar
--- @return boolean True si es userdata
function Validation.EsUserdata(valor)
    return type(valor) == "userdata"
end

-- ============================================================================
-- VALIDACIÓN DE VACÍO
-- ============================================================================

--- Verifica si un valor está vacío (nil, string vacío, tabla vacía)
--- @param valor any Valor a verificar
--- @return boolean True si está vacío
function Validation.EstaVacio(valor)
    if valor == nil then return true end
    if type(valor) == "string" then return valor == "" end
    if type(valor) == "table" then return next(valor) == nil end
    return false
end

--- Verifica si un valor NO está vacío
--- @param valor any Valor a verificar
--- @return boolean True si NO está vacío
function Validation.NoEstaVacio(valor)
    return not Validation.EstaVacio(valor)
end

--- Verifica si un string tiene contenido (no solo espacios)
--- @param valor any Valor a verificar
--- @return boolean True si tiene contenido
function Validation.TieneContenido(valor)
    if type(valor) ~= "string" then return false end
    return string.match(valor, "^%s*$") == nil
end

-- ============================================================================
-- VALIDACIÓN DE RANGOS NUMÉRICOS
-- ============================================================================

--- Verifica si un número está dentro de un rango
--- @param valor number Valor a verificar
--- @param minimo number Valor mínimo
--- @param maximo number Valor máximo
--- @return boolean True si está en rango
function Validation.EstaEnRango(valor, minimo, maximo)
    if type(valor) ~= "number" then return false end
    return valor >= minimo and valor <= maximo
end

--- Verifica si un número es positivo
--- @param valor any Valor a verificar
--- @return boolean True si es positivo
function Validation.EsPositivo(valor)
    if type(valor) ~= "number" then return false end
    return valor > 0
end

--- Verifica si un número es negativo
--- @param valor any Valor a verificar
--- @return boolean True si es negativo
function Validation.EsNegativo(valor)
    if type(valor) ~= "number" then return false end
    return valor < 0
end

--- Verifica si un número es cero
--- @param valor any Valor a verificar
--- @return boolean True si es cero
function Validation.EsCero(valor)
    if type(valor) ~= "number" then return false end
    return valor == 0
end

--- Verifica si un número es mayor que otro
--- @param valor number Valor a verificar
--- @param referencia number Valor de referencia
--- @return boolean True si es mayor
function Validation.EsMayorQue(valor, referencia)
    if type(valor) ~= "number" or type(referencia) ~= "number" then return false end
    return valor > referencia
end

--- Verifica si un número es menor que otro
--- @param valor number Valor a verificar
--- @param referencia number Valor de referencia
--- @return boolean True si es menor
function Validation.EsMenorQue(valor, referencia)
    if type(valor) ~= "number" or type(referencia) ~= "number" then return false end
    return valor < referencia
end

-- ============================================================================
-- VALIDACIÓN DE STRINGS
-- ============================================================================

--- Verifica si un string tiene longitud mínima
--- @param valor string Valor a verificar
--- @param longitud number Longitud mínima
--- @return boolean True si cumple longitud mínima
function Validation.LongitudMinima(valor, longitud)
    if type(valor) ~= "string" then return false end
    return #valor >= longitud
end

--- Verifica si un string tiene longitud máxima
--- @param valor string Valor a verificar
--- @param longitud number Longitud máxima
--- @return boolean True si cumple longitud máxima
function Validation.LongitudMaxima(valor, longitud)
    if type(valor) ~= "string" then return false end
    return #valor <= longitud
end

--- Verifica si un string tiene longitud exacta
--- @param valor string Valor a verificar
--- @param longitud number Longitud exacta
--- @return boolean True si tiene longitud exacta
function Validation.LongitudExacta(valor, longitud)
    if type(valor) ~= "string" then return false end
    return #valor == longitud
end

--- Verifica si un string coincide con un patrón
--- @param valor string Valor a verificar
--- @param patron string Patrón Lua
--- @return boolean True si coincide
function Validation.CoincidePatron(valor, patron)
    if type(valor) ~= "string" or type(patron) ~= "string" then return false end
    return string.match(valor, patron) ~= nil
end

--- Verifica si un string contiene solo letras
--- @param valor string Valor a verificar
--- @return boolean True si solo contiene letras
function Validation.SoloLetras(valor)
    if type(valor) ~= "string" then return false end
    return string.match(valor, "^%a+$") ~= nil
end

--- Verifica si un string contiene solo números
--- @param valor string Valor a verificar
--- @return boolean True si solo contiene números
function Validation.SoloNumeros(valor)
    if type(valor) ~= "string" then return false end
    return string.match(valor, "^%d+$") ~= nil
end

--- Verifica si un string es alfanumérico
--- @param valor string Valor a verificar
--- @return boolean True si es alfanumérico
function Validation.EsAlfanumerico(valor)
    if type(valor) ~= "string" then return false end
    return string.match(valor, "^%w+$") ~= nil
end

-- ============================================================================
-- VALIDACIÓN DE FORMATOS ESPECÍFICOS
-- ============================================================================

--- Valida formato de placa de vehículo (español: 0000-XXX o formato antiguo)
--- @param placa string Placa a validar
--- @return boolean True si es válida
--- @return string|nil Mensaje de error
function Validation.ValidarPlaca(placa)
    if type(placa) ~= "string" then
        return false, "La placa debe ser un texto"
    end

    -- Eliminar espacios y convertir a mayúsculas
    placa = string.upper(string.gsub(placa, "%s", ""))

    -- Formato nuevo España: 0000XXX (4 números + 3 letras)
    if string.match(placa, "^%d%d%d%d%u%u%u$") then
        return true, nil
    end

    -- Formato antiguo España: X-0000-XX
    if string.match(placa, "^%u%-%d%d%d%d%-%u%u$") then
        return true, nil
    end

    -- Formato genérico roleplay: hasta 8 caracteres alfanuméricos
    if string.match(placa, "^%w+$") and #placa >= 2 and #placa <= 8 then
        return true, nil
    end

    return false, "Formato de placa no válido"
end

--- Valida formato de teléfono (español)
--- @param telefono string Teléfono a validar
--- @return boolean True si es válido
--- @return string|nil Mensaje de error
function Validation.ValidarTelefono(telefono)
    if type(telefono) ~= "string" then
        return false, "El teléfono debe ser un texto"
    end

    -- Eliminar espacios, guiones y paréntesis
    telefono = string.gsub(telefono, "[%s%-%(%)]", "")

    -- Formato español: +34XXXXXXXXX o 6XXXXXXXX/7XXXXXXXX/9XXXXXXXX
    if string.match(telefono, "^%+34%d%d%d%d%d%d%d%d%d$") then
        return true, nil
    end

    -- Móvil español (6XX o 7XX)
    if string.match(telefono, "^[67]%d%d%d%d%d%d%d%d$") then
        return true, nil
    end

    -- Fijo español (9XX)
    if string.match(telefono, "^9%d%d%d%d%d%d%d%d$") then
        return true, nil
    end

    -- Formato roleplay genérico: 3-10 dígitos
    if string.match(telefono, "^%d+$") and #telefono >= 3 and #telefono <= 10 then
        return true, nil
    end

    return false, "Formato de teléfono no válido"
end

--- Valida formato de DNI/NIE español
--- @param documento string Documento a validar
--- @return boolean True si es válido
--- @return string|nil Mensaje de error
function Validation.ValidarDocumentoIdentidad(documento)
    if type(documento) ~= "string" then
        return false, "El documento debe ser un texto"
    end

    -- Eliminar espacios y guiones
    documento = string.upper(string.gsub(documento, "[%s%-]", ""))

    -- DNI: 8 números + 1 letra
    if string.match(documento, "^%d%d%d%d%d%d%d%d%u$") then
        local numeros = tonumber(string.sub(documento, 1, 8))
        local letra = string.sub(documento, 9, 9)
        local letras = "TRWAGMYFPDXBNJZSQVHLCKE"
        local letraCorrecta = string.sub(letras, (numeros % 23) + 1, (numeros % 23) + 1)

        if letra == letraCorrecta then
            return true, nil
        else
            return false, "Letra del DNI incorrecta"
        end
    end

    -- NIE: X/Y/Z + 7 números + 1 letra
    if string.match(documento, "^[XYZ]%d%d%d%d%d%d%d%u$") then
        local primeraLetra = string.sub(documento, 1, 1)
        local numeroStr = ""

        if primeraLetra == "X" then numeroStr = "0"
        elseif primeraLetra == "Y" then numeroStr = "1"
        elseif primeraLetra == "Z" then numeroStr = "2" end

        numeroStr = numeroStr .. string.sub(documento, 2, 8)
        local numeros = tonumber(numeroStr)
        local letra = string.sub(documento, 9, 9)
        local letras = "TRWAGMYFPDXBNJZSQVHLCKE"
        local letraCorrecta = string.sub(letras, (numeros % 23) + 1, (numeros % 23) + 1)

        if letra == letraCorrecta then
            return true, nil
        else
            return false, "Letra del NIE incorrecta"
        end
    end

    return false, "Formato de documento no válido (DNI: 00000000X, NIE: X0000000X)"
end

--- Alias para ValidarDocumentoIdentidad
--- @param citizenId string ID ciudadano
--- @return boolean True si es válido
--- @return string|nil Mensaje de error
function Validation.ValidarCitizenId(citizenId)
    if type(citizenId) ~= "string" then
        return false, "El ID de ciudadano debe ser un texto"
    end

    -- Formato QBCore estándar: ABC12345 (3 letras + 5 números)
    if string.match(citizenId, "^%u%u%u%d%d%d%d%d$") then
        return true, nil
    end

    -- Formato alfanumérico genérico (5-10 caracteres)
    if string.match(citizenId, "^%w+$") and #citizenId >= 5 and #citizenId <= 10 then
        return true, nil
    end

    -- Validar como documento de identidad español
    return Validation.ValidarDocumentoIdentidad(citizenId)
end

--- Valida formato de email
--- @param email string Email a validar
--- @return boolean True si es válido
--- @return string|nil Mensaje de error
function Validation.ValidarEmail(email)
    if type(email) ~= "string" then
        return false, "El email debe ser un texto"
    end

    -- Patrón básico de email
    local patron = "^[%w%._%-%+]+@[%w%.%-]+%.%w+$"

    if string.match(email, patron) then
        return true, nil
    end

    return false, "Formato de email no válido"
end

--- Valida formato de fecha (DD/MM/YYYY o YYYY-MM-DD)
--- @param fecha string Fecha a validar
--- @return boolean True si es válida
--- @return string|nil Mensaje de error
function Validation.ValidarFecha(fecha)
    if type(fecha) ~= "string" then
        return false, "La fecha debe ser un texto"
    end

    local dia, mes, ano

    -- Formato DD/MM/YYYY
    dia, mes, ano = string.match(fecha, "^(%d%d)/(%d%d)/(%d%d%d%d)$")

    -- Formato YYYY-MM-DD
    if not dia then
        ano, mes, dia = string.match(fecha, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    end

    if not dia then
        return false, "Formato de fecha no válido (DD/MM/YYYY o YYYY-MM-DD)"
    end

    dia = tonumber(dia)
    mes = tonumber(mes)
    ano = tonumber(ano)

    -- Validar rangos básicos
    if mes < 1 or mes > 12 then
        return false, "Mes no válido"
    end

    if ano < 1900 or ano > 2100 then
        return false, "Año no válido"
    end

    local diasPorMes = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

    -- Año bisiesto
    if (ano % 4 == 0 and ano % 100 ~= 0) or (ano % 400 == 0) then
        diasPorMes[2] = 29
    end

    if dia < 1 or dia > diasPorMes[mes] then
        return false, "Día no válido para el mes indicado"
    end

    return true, nil
end

--- Valida formato de hora (HH:MM o HH:MM:SS)
--- @param hora string Hora a validar
--- @return boolean True si es válida
--- @return string|nil Mensaje de error
function Validation.ValidarHora(hora)
    if type(hora) ~= "string" then
        return false, "La hora debe ser un texto"
    end

    local horas, minutos, segundos

    -- Formato HH:MM:SS
    horas, minutos, segundos = string.match(hora, "^(%d%d):(%d%d):(%d%d)$")

    -- Formato HH:MM
    if not horas then
        horas, minutos = string.match(hora, "^(%d%d):(%d%d)$")
        segundos = "00"
    end

    if not horas then
        return false, "Formato de hora no válido (HH:MM o HH:MM:SS)"
    end

    horas = tonumber(horas)
    minutos = tonumber(minutos)
    segundos = tonumber(segundos)

    if horas < 0 or horas > 23 then
        return false, "Hora no válida (0-23)"
    end

    if minutos < 0 or minutos > 59 then
        return false, "Minutos no válidos (0-59)"
    end

    if segundos < 0 or segundos > 59 then
        return false, "Segundos no válidos (0-59)"
    end

    return true, nil
end

-- ============================================================================
-- VALIDACIÓN DE DATOS DE JUEGO
-- ============================================================================

--- Valida un identificador de servidor (license, steam, discord, etc)
--- @param identificador string Identificador a validar
--- @return boolean True si es válido
--- @return string|nil Tipo de identificador
function Validation.ValidarIdentificador(identificador)
    if type(identificador) ~= "string" then
        return false, nil
    end

    -- License
    if string.match(identificador, "^license:%x+$") then
        return true, "license"
    end

    -- Steam
    if string.match(identificador, "^steam:%x+$") then
        return true, "steam"
    end

    -- Discord
    if string.match(identificador, "^discord:%d+$") then
        return true, "discord"
    end

    -- IP
    if string.match(identificador, "^ip:%d+%.%d+%.%d+%.%d+$") then
        return true, "ip"
    end

    -- Live (Xbox)
    if string.match(identificador, "^live:%d+$") then
        return true, "live"
    end

    -- XBL
    if string.match(identificador, "^xbl:%d+$") then
        return true, "xbl"
    end

    -- FiveM
    if string.match(identificador, "^fivem:%d+$") then
        return true, "fivem"
    end

    return false, nil
end

--- Valida coordenadas de GTA V
--- @param x number Coordenada X
--- @param y number Coordenada Y
--- @param z number Coordenada Z (opcional)
--- @return boolean True si son válidas
--- @return string|nil Mensaje de error
function Validation.ValidarCoordenadas(x, y, z)
    if type(x) ~= "number" or type(y) ~= "number" then
        return false, "Las coordenadas X e Y deben ser números"
    end

    -- Límites aproximados del mapa de GTA V
    local limiteMin = -10000
    local limiteMax = 10000

    if x < limiteMin or x > limiteMax then
        return false, "Coordenada X fuera de límites"
    end

    if y < limiteMin or y > limiteMax then
        return false, "Coordenada Y fuera de límites"
    end

    if z ~= nil then
        if type(z) ~= "number" then
            return false, "La coordenada Z debe ser un número"
        end

        if z < -500 or z > 2000 then
            return false, "Coordenada Z fuera de límites"
        end
    end

    return true, nil
end

--- Valida un modelo de vehículo/ped/objeto
--- @param modelo string|number Modelo a validar
--- @return boolean True si el formato es válido
function Validation.ValidarModelo(modelo)
    if type(modelo) == "number" then
        return modelo > 0
    end

    if type(modelo) == "string" and #modelo > 0 then
        return true
    end

    return false
end

-- ============================================================================
-- VALIDADOR DE ESQUEMAS
-- ============================================================================

--- Valida un objeto contra un esquema definido
--- @param datos table Datos a validar
--- @param esquema table Esquema de validación
--- @return boolean True si es válido
--- @return table Lista de errores
function Validation.ValidarEsquema(datos, esquema)
    if type(datos) ~= "table" then
        return false, {"Los datos deben ser una tabla"}
    end

    if type(esquema) ~= "table" then
        return false, {"El esquema debe ser una tabla"}
    end

    local errores = {}

    for campo, reglas in pairs(esquema) do
        local valor = datos[campo]
        local nombreCampo = reglas.nombre or campo

        -- Campo requerido
        if reglas.requerido and Validation.EstaVacio(valor) then
            table.insert(errores, nombreCampo .. " es requerido")
            goto continuar
        end

        -- Si el campo está vacío y no es requerido, saltar validaciones
        if Validation.EstaVacio(valor) then
            goto continuar
        end

        -- Validar tipo
        if reglas.tipo then
            local tipoValor = type(valor)
            if tipoValor ~= reglas.tipo then
                table.insert(errores, nombreCampo .. " debe ser de tipo " .. reglas.tipo)
                goto continuar
            end
        end

        -- Validaciones para strings
        if type(valor) == "string" then
            if reglas.longitudMinima and #valor < reglas.longitudMinima then
                table.insert(errores, nombreCampo .. " debe tener al menos " .. reglas.longitudMinima .. " caracteres")
            end

            if reglas.longitudMaxima and #valor > reglas.longitudMaxima then
                table.insert(errores, nombreCampo .. " no puede tener más de " .. reglas.longitudMaxima .. " caracteres")
            end

            if reglas.patron and not string.match(valor, reglas.patron) then
                table.insert(errores, nombreCampo .. " tiene un formato no válido")
            end
        end

        -- Validaciones para números
        if type(valor) == "number" then
            if reglas.minimo and valor < reglas.minimo then
                table.insert(errores, nombreCampo .. " debe ser mayor o igual a " .. reglas.minimo)
            end

            if reglas.maximo and valor > reglas.maximo then
                table.insert(errores, nombreCampo .. " debe ser menor o igual a " .. reglas.maximo)
            end
        end

        -- Validación personalizada
        if reglas.validador and type(reglas.validador) == "function" then
            local valido, mensaje = reglas.validador(valor)
            if not valido then
                table.insert(errores, mensaje or (nombreCampo .. " no es válido"))
            end
        end

        -- Valores permitidos
        if reglas.valoresPermitidos then
            local encontrado = false
            for _, permitido in ipairs(reglas.valoresPermitidos) do
                if valor == permitido then
                    encontrado = true
                    break
                end
            end
            if not encontrado then
                table.insert(errores, nombreCampo .. " tiene un valor no permitido")
            end
        end

        ::continuar::
    end

    return #errores == 0, errores
end

-- Exportar para compatibilidad
return Validation
