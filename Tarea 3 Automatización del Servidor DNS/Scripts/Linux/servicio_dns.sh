#!/bin/bash
#========================================================================
#   Tarea 3: Automatización del Servidor DNS
#   Autor: Alberto Torres Chaparro
#   Descripción: Este script automatiza la instalación y configuración 
#   de un servidor DNS utilizando BIND9 en Oracle Linux.
#========================================================================

#Función para ver el estado del servicio DNS
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

menu_dns(){
    while true; do
        clear
        echo "========================================"
        echo "               SERVICIO DNS"
        echo "========================================"
        echo "1) Estado del servicio DNS"
        echo "2) Salir"
        echo "========================================"
        read -p "Selecciona una opción: " opcion
        case $opcion in
            1) estado_dns ;;
            2) echo "Saliendo del menú DNS..."; break ;;
            *) echo "Opción no válida. Inténtalo de nuevo." ;;
        esac
    done
}