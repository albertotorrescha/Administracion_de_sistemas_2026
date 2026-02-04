#!/bin/bash
# Script de Diagnostico Basico para linux
# Proposito: Validar identidad, version y almacenamiento del nodo

echo "============================="
echo "     DIAGNOSTICO DE LINUX"
echo "============================="

# 1. Identificacion del Nodo
# Muestra el nombre del equipo para confirmar en que Nodo estamos
echo "Nombre: $(hostname)"

# 2. Version del sistema operativo
# Busca la linea "PRETTY_NAME" en la info del sistema
echo "S.O: $(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)"

# 3. Direccion IP (Red interna)
# host name -I de todas las IPs. Usamos awk '{print $2}' para tomar la segunda IP
# ya que la primera suele ser la NAT y la segunda es la red interna (en este caso)
echo "Direccion IPv4: $(hostname -I | awk '{print $2}')"

# 4. Revisa la particion Raiz, salta el encabezado y muestra solo el espacio libre y el total
echo "Espacio de disco: $(df -h / | awk 'NR==2 {print $4 " libres de " $2}')"