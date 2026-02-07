#!/bin/bash
# ============================================================
# Tarea 2:  Automatización y Gestión del Servidor DHCP
#   Autor:  Alberto Torres Chaparro
# Parte 2:  Instalar el servicio DHCP
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
    # --- Actualizacion de la Parte 2
    echo "Iniciando instalación..."
    # Instalando el servicio
    dnf install -y kea &> /dev/null
    
    # Verificamos si la instalación fue exitosa
    if rpm -q kea &> /dev/null; then
        echo "Instalación completada con éxito."
    else
        echo "Error: No se pudo instalar Kea."
        exit 1
    fi
fi
echo ">>> Asegurando la ejecución del servicio..."
systemctl enable --now kea-dhcp4 &> /dev/null

# Verificación final
if systemctl is-active --quiet kea-dhcp4; then
    echo "Estado Final: ACTIVO"
else
    echo "Estado Final: FALLO AL INICIAR"
fi