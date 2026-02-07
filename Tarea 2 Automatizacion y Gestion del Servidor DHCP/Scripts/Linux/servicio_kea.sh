#!/bin/bash
# ============================================================
# Tarea 2:  Automatización y Gestión del Servidor DHCP
#   Autor:  Alberto Torres Chaparro
# Parte 1:  Verificar si el software de servidor DHCP esta 
#           instalado
# ============================================================

echo "Comprobando servicio..."
# Verificamos si el paquete RPM 'kea' está en el sistema
if rpm -q kea &> /dev/null; then
    echo "El servicio Kea DHCP ya se encuentra instalado."
    
    # Esta corriendo?
    if systemctl is-active --quiet kea-dhcp4; then
        echo "Estado: ACTIVO (Running)"
    else
        echo "Estado: DETENIDO (Stopped)"
    fi
else
    echo "El servicio Kea DHCP NO está instalado en este servidor."
fi