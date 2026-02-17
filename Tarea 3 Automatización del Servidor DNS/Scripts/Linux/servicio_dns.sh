#!/bin/bash
#========================================================================
#   Tarea 3: Automatización del Servidor DNS
#   Autor: Alberto Torres Chaparro
#   Descripción: Este script automatiza la instalación y configuración 
#   de un servidor DNS utilizando BIND9 en Oracle Linux.
#========================================================================

# Función para ver el estado del servicio DNS
estado_dns() {
    clear
    echo "========================================"
    echo "        ESTADO DEL SERVICIO DNS"
    echo "========================================"

    if systemctl is-active --quiet named; then
        echo -e "Estado: ${GREEN}ACTIVO${NC}"
    else
        echo -e "Estado: ${RED}INACTIVO${NC}"
    fi

    systemctl status named --no-pager | grep Active
    read -p "Enter..."
}
# Función para instalar el servicio DNS
instalar_dns() {

    if rpm -q bind &> /dev/null; then
        echo "El servicio DNS ya está instalado."
        read -p "Enter..."
        return
    fi

    echo "Instalando BIND..."
    dnf install -y bind bind-utils &> /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[EXITO] Instalación completada.${NC}"
        systemctl enable named &> /dev/null
        systemctl start named
    else
        echo -e "${RED}[ERROR] Falló la instalación.${NC}"
    fi

    read -p "Enter..."
}
menu_dns(){
    while true; do
        clear
        echo "========================================"
        echo "               SERVICIO DNS"
        echo "========================================"
        echo "1) Estado del servicio DNS"
        echo "2) Instalar el servicio DNS"
        echo "3) Salir"
        echo "========================================"
        read -p "Selecciona una opción: " opcion
        case $opcion in
            1) estado_dns ;;
            2) instalar_dns ;;
            3) echo "Saliendo del menú DNS..."; break ;;
            *) echo "Opción no válida. Inténtalo de nuevo." ;;
        esac
    done
}