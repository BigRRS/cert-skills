#!/bin/bash

# Configuración de MultiversX
PROXY="https://devnet-api.multiversx.com"
GATEWAY="https://devnet-gateway.multiversx.com"
CONTRACT_ADDRESS="erd1qqqqqqqqqqqqqpgq2j8dl6u0e5grwhlr9zsy3g5sf9hz5frvu9wqcn2h75"
WALLET="wallet5.pem"

# Función para emitir un nuevo certificado
emitir_certificado() {
    read -p "📌 Ingresa la dirección del destinatario: " DESTINATARIO
    read -p "📌 Ingresa la skill (0-4): " SKILL
    read -p "📌 Ingresa el nivel (0-2): " NIVEL

    # Validaciones
    if [[ ! "$SKILL" =~ ^[0-4]$ ]] || [[ ! "$NIVEL" =~ ^[0-2]$ ]]; then
        echo "❌ Error: Skill debe estar entre 0-4 y Nivel entre 0-2."
        exit 1
    fi

    echo "🚀 Emisión en progreso..."
    mxpy contract call $CONTRACT_ADDRESS \
        --pem=$WALLET \
        --recall-nonce \
        --proxy=$GATEWAY \
        --chain D \
        --function issueCertificate \
        --arguments $DESTINATARIO $SKILL $NIVEL \
        --gas-limit 50000000 \
        --send
}

# Función para consultar un certificado por ID
consultar_certificado() {
    read -p "📌 Ingresa el ID del certificado: " CERT_ID

    # Ejecutar la consulta al contrato
    RESPUESTA=$(mxpy contract query $CONTRACT_ADDRESS \
        --proxy=$PROXY \
        --function getCertificate \
        --arguments $(printf "0x%016x" $CERT_ID))

    # Mostrar toda la respuesta para depuración
    echo "🔍 Respuesta del contrato: $RESPUESTA"

    FORMATO=$(echo $RESPUESTA | tr -d '[]"')

    # Extraer valores de skill, nivel, estado, usuario y emisor
    SKILL=$(echo $FORMATO | cut -c9-10)
    NIVEL=$(echo $FORMATO | cut -c11-12)
    ESTADO=$(echo $FORMATO | cut -c13-14)
    USUARIO=$(echo $FORMATO | cut -c15-78)
    EMISOR=$(echo $FORMATO | cut -c79-142)

    # Mostrar resultados con formato
    echo -e "\n📜 Certificado ID: $CERT_ID"
    echo "🎓 Skill: Skill$SKILL"

    # Mostrar nivel con formato adecuado
   case $NIVEL in
       00) NIVEL="Básico" ;;
       01) NIVEL="Intermedio" ;;
       02) NIVEL="Avanzado" ;;
       *) NIVEL="Desconocido" ;;
    esac
    
    echo "📈 Nivel: $NIVEL"

    # Mostrar estado con formato adecuado
    case $ESTADO in
        00) ESTADO="Activo" ;;
        01) ESTADO="Revocado" ;;
        *) ESTADO="Desconocido" ;;
    esac
    echo "🔄 Estado: $ESTADO"
    
    USUARIO=$(./hex_to_bech32.sh "$USUARIO")
    EMISOR=$(./hex_to_bech32.sh "$EMISOR")
    echo "👤 Usuario: $USUARIO"
    echo "🏛️ Emisor: $EMISOR"
}

# Función para consultar todos los certificados de un usuario
consultar_certificados_usuario() {
    read -p "📌 Ingresa la dirección del usuario: " USER_ADDRESS

    echo "🔍 Consultando certificados..."
    
    # Obtener la respuesta del contrato
    RESPUESTA=$(mxpy contract query $CONTRACT_ADDRESS \
        --proxy=$PROXY \
        --function getUserCertificates \
        --arguments $USER_ADDRESS)

    # Verificar si hay respuesta
    if [ -z "$RESPUESTA" ]; then
        echo "❌ No se encontraron certificados para este usuario"
        return
    fi

    # Eliminar corchetes, comillas y espacios
    FORMATO=$(echo $RESPUESTA | tr -d '[]" ' | tr ',' '\n')
    
    # Si la respuesta está vacía después de limpiarla
    if [ -z "$FORMATO" ]; then
        echo "❌ No se encontraron certificados para este usuario"
        return
    fi

    echo -e "\n📜 Certificados encontrados:"
    echo "═══════════════════════════════════════════"
    
    # Contador para enumerar los certificados
    CONTADOR=1

    # Procesar cada certificado
    while IFS= read -r CERTIFICADO; do
        # Solo procesar si el certificado no está vacío
        if [ ! -z "$CERTIFICADO" ]; then
            # Extraer los componentes usando índices específicos
            ID=${CERTIFICADO:0:8}
            # Convertir ID de hex a decimal, manejo de error incluido
            if [[ $ID =~ ^[0-9A-Fa-f]+$ ]]; then
                ID=$((16#$ID))
            else
                ID=0
            fi

            SKILL=${CERTIFICADO:8:2}
            NIVEL=${CERTIFICADO:10:2}
            ESTADO=${CERTIFICADO:12:2}
            USUARIO=${CERTIFICADO:14:64}
            EMISOR=${CERTIFICADO:78:64}

            # Formatear nivel
            case $NIVEL in
                00) NIVEL_TEXT="Básico" ;;
                01) NIVEL_TEXT="Intermedio" ;;
                02) NIVEL_TEXT="Avanzado" ;;
                *) NIVEL_TEXT="Desconocido" ;;
            esac

            # Formatear estado
            case $ESTADO in
                00) ESTADO_TEXT="✅ Activo" ;;
                01) ESTADO_TEXT="❌ Revocado" ;;
                *) ESTADO_TEXT="❓ Desconocido" ;;
            esac

            # Convertir skill a número decimal
            if [[ $SKILL =~ ^[0-9A-Fa-f]+$ ]]; then
                SKILL_NUM=$((16#$SKILL))
            else
                SKILL_NUM=0
            fi

            # Intentar convertir el emisor a bech32 solo si es una cadena hex válida
            EMISOR_BECH32=""
            if [[ $EMISOR =~ ^[0-9A-Fa-f]{64}$ ]]; then
                EMISOR_BECH32=$(./hex_to_bech32.sh "$EMISOR" 2>/dev/null)
                if [ $? -ne 0 ]; then
                    EMISOR_BECH32="dirección inválida"
                fi
            else
                EMISOR_BECH32="dirección inválida"
            fi

            # Mostrar la información del certificado
            echo "🔖 Certificado #$CONTADOR (ID: $ID)"
            echo "───────────────────────────────────────────"
            echo "🎓 Skill: Skill$SKILL_NUM"
            echo "📈 Nivel: $NIVEL_TEXT"
            echo "🔄 Estado: $ESTADO_TEXT"
            if [ "$EMISOR_BECH32" != "dirección inválida" ]; then
                echo "🏛️ Emisor: ${EMISOR_BECH32:0:12}...${EMISOR_BECH32: -8}"
            else
                echo "🏛️ Emisor: dirección inválida"
            fi
            echo "═══════════════════════════════════════════"

            CONTADOR=$((CONTADOR + 1))
        fi
    done <<< "$FORMATO"
}

# Función para consultar certificados emitidos por un emisor
consultar_certificados_emisor() {
    read -p "📌 Ingresa la dirección del emisor: " ISSUER_ADDRESS

    mxpy contract query $CONTRACT_ADDRESS \
        --proxy=$PROXY \
        --function getIssuerCertificates \
        --arguments $ISSUER_ADDRESS
}

# Función para revocar un certificado
revocar_certificado() {
    read -p "📌 Ingresa el ID del certificado a revocar: " CERT_ID

    # Convertir el ID a formato hexadecimal con 16 dígitos (8 bytes)
    ID_HEX=$(printf "0x%016x" "$CERT_ID")

    echo "🔄 Revocando el certificado ID: $CERT_ID (hex: $ID_HEX)..."
    
    # Ejecutar la transacción de revocación
    mxpy contract call $CONTRACT_ADDRESS \
        --pem=$WALLET \
        --recall-nonce \
        --proxy=$PROXY \
        --function revokeCertificate \
        --arguments $ID_HEX \
        --gas-limit 50000000 \
        --send

    # Verificar el resultado
    if [ $? -eq 0 ]; then
        echo "✅ Certificado revocado correctamente"
    else
        echo "❌ Error al revocar el certificado"
    fi
}

# Menú interactivo actualizado
while true; do
    echo -e "\n🌟 Gestión de Certificados MultiversX"
    echo "1️⃣ Emitir nuevo certificado"
    echo "2️⃣ Consultar un certificado por ID"
    echo "3️⃣ Consultar certificados de un usuario"
    echo "4️⃣ Consultar certificados emitidos por un emisor"
    echo "5️⃣ Revocar certificado"
    echo "6️⃣ Salir"
    read -p "👉 Selecciona una opción: " OPCION

    case $OPCION in
        1) emitir_certificado ;;
        2) consultar_certificado ;;
        3) consultar_certificados_usuario ;;
        4) consultar_certificados_emisor ;;
        5) revocar_certificado ;;
        6) echo "👋 Saliendo..."; exit 0 ;;
        *) echo "❌ Opción inválida";;
    esac
done