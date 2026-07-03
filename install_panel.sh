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
    
    # Limpiar posibles caracteres ocultos (CRLF, espacios) de copiar y pegar
    INSTALL_KEY=$(echo "$INSTALL_KEY" | tr -d '\r' | tr -d '\n' | tr -d ' ')

    if [ -z "${MAIN_DOMAIN+x}" ]; then
        read -p "Introduce tu Dominio Principal (Enter para omitir): " MAIN_DOMAIN
    fi

    log_info "Verificando Key en la base de datos..."
    if ! KEY_RESPONSE=$(curl -4 -s -m 10 "${FIREBASE_URL}/keys/${INSTALL_KEY}.json"); then
        log_error "Error de conexión con Firebase. Revisa tu internet o DNS."
        exit 1
    fi
    if [ "$KEY_RESPONSE" == "null" ] || [ -z "$KEY_RESPONSE" ]; then
        log_error "Key inválida o ya ha sido usada."
        exit 1
    fi

    log_info "Key válida. Quemando Key..."
    curl -4 -s -X DELETE "${FIREBASE_URL}/keys/${INSTALL_KEY}.json" > /dev/null || true

    # Guardar el dominio inicial en config si existe
    if [ -n "$MAIN_DOMAIN" ]; then
        echo "{\"main_domain\": \"$MAIN_DOMAIN\"}" > /root/depwise_config.json
    else
        echo "{\"main_domain\": \"\"}" > /root/depwise_config.json
    fi

    log_info "Instalando dependencias base..."
    apt update -y && apt install -y curl wget || { log_error "Error al instalar dependencias base."; exit 1; }

    log_info "Descargando el binario del Panel..."
    wget -qO /usr/local/bin/menu "https://github.com/Depwisescript/Depwise-Installers/releases/latest/download/menu?t=$(date +%s)" || { log_error "Error al descargar el binario."; exit 1; }
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
