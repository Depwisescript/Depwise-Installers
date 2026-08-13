#!/bin/bash
set -euo pipefail

main() {
    # =========================================================
    # INSTALADOR SCRIPT TERMINAL DEPWISE 💎 (BINARY EDITION)
    # =========================================================

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
    log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

    if [ "$EUID" -ne 0 ]; then
      log_error "Por favor, ejecuta este script como root"
      exit 1
    fi

    # --- CONFIGURACION PRIVADA ---
    FIREBASE_URL="https://keys-depwise-default-rtdb.firebaseio.com"
    # ----------------------------------------------------------

    echo -e "${CYAN}=================================================="
    echo -e "       INSTALANDO SCRIPT DEPWISE (TERMINAL)"
    echo -e "==================================================${NC}"

    # Validación de Key de Instalación
    if [ -z "${INSTALL_KEY+x}" ]; then
        read -p "Introduce tu Key de Instalación: " INSTALL_KEY
    fi
    if [ -z "$INSTALL_KEY" ]; then
        log_error "La Key no puede estar vacía."
        exit 1
    fi
    
    # Limpiar posibles caracteres ocultos o retornos de carro al pegar
    INSTALL_KEY=$(echo "$INSTALL_KEY" | tr -d '\r' | tr -d ' ' | tr -d '\n')

    if [ -z "${MAIN_DOMAIN+x}" ]; then
        read -p "Introduce tu Dominio Principal (Enter para omitir): " MAIN_DOMAIN
    fi

    log_info "Instalando y actualizando dependencias de red..."
    apt update -y && apt install -y curl wget ca-certificates || { log_error "Error al instalar dependencias base."; exit 1; }
    update-ca-certificates || true

    log_info "Verificando Key en la base de datos..."
    KEY_RESPONSE=$(curl -k -L -4 -s -m 10 "${FIREBASE_URL}/keys/${INSTALL_KEY}.json") || true
    if [ -z "$KEY_RESPONSE" ]; then
        KEY_RESPONSE=$(curl -k -L -6 -s -m 10 "${FIREBASE_URL}/keys/${INSTALL_KEY}.json") || true
    fi
    if [ -z "$KEY_RESPONSE" ]; then
        KEY_RESPONSE=$(wget --no-check-certificate -qO- --timeout=10 "${FIREBASE_URL}/keys/${INSTALL_KEY}.json") || true
    fi
    if [ -z "$KEY_RESPONSE" ]; then
        KEY_RESPONSE=$(curl -k -L -4 -s --http1.1 --tls-max 1.2 -m 10 "${FIREBASE_URL}/keys/${INSTALL_KEY}.json") || true
    fi

    if [ -z "$KEY_RESPONSE" ]; then
        log_error "Error de conexión con Firebase. Revisa tu internet o DNS."
        exit 1
    fi
    if [ "$KEY_RESPONSE" == "null" ] || echo "$KEY_RESPONSE" | grep -q "Permission denied"; then
        log_error "Key inválida o ya ha sido usada."
        exit 1
    fi

    log_info "Key válida. Comprobando tipo de licencia..."
    
    # Check if the key is "free" or "premium"
    KEY_TYPE=$(echo "$KEY_RESPONSE" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
    if [ -z "$KEY_TYPE" ]; then
        KEY_TYPE="premium" # Default for old keys
    fi

    log_info "Quemando Key..."
    curl -4 -s -X DELETE "${FIREBASE_URL}/keys/${INSTALL_KEY}.json" > /dev/null || curl -6 -s -X DELETE "${FIREBASE_URL}/keys/${INSTALL_KEY}.json" > /dev/null || true

    # Guardar el dominio inicial en config si existe
    if [ -n "$MAIN_DOMAIN" ]; then
        echo "{\"main_domain\": \"$MAIN_DOMAIN\"}" > /root/depwise_config.json
    else
        echo "{\"main_domain\": \"\"}" > /root/depwise_config.json
    fi

    log_info "Descargando el binario del Panel ($KEY_TYPE)..."
    
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
        if [ "$KEY_TYPE" == "free" ]; then
            BIN_URL="https://github.com/Depwisescript/-SCRIPT-DEPWISE-FREE/releases/latest/download/menu-free-amd64"
        else
            BIN_URL="https://github.com/Depwisescript/Depwise-Installers/releases/latest/download/menu-amd64"
        fi
    elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ]; then
        if [ "$KEY_TYPE" == "free" ]; then
            BIN_URL="https://github.com/Depwisescript/-SCRIPT-DEPWISE-FREE/releases/latest/download/menu-free-arm64"
        else
            BIN_URL="https://github.com/Depwisescript/Depwise-Installers/releases/latest/download/menu-arm64"
        fi
    else
        log_error "Arquitectura no soportada: $ARCH"
        exit 1
    fi

    wget -qO /usr/local/bin/menu "${BIN_URL}?t=$(date +%s)" || { log_error "Error al descargar el binario."; exit 1; }
    chmod +x /usr/local/bin/menu

    echo -e "${GREEN}=================================================="
    echo -e "       INSTALACION COMPLETADA 💎"
    echo -e "=================================================="
    echo -e "Para abrir el panel, simplemente escribe el comando: ${CYAN}menu${NC}"

    # Activar Auto-Panel por defecto
    if ! grep -q "menu" /root/.bashrc; then
        echo "menu" >> /root/.bashrc
    fi
}

main "$@"
