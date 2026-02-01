#!/bin/bash
echo "========================================"
echo "INFORMACION DEL SERVIDOR"
echo "========================================"
echo "Nombre:           $(hostname)"
echo "S.O:              $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
echo "Direccion IPv4:   $(hostname -I | awk '{print $2}')"
echo "Espacio en disco: $(df -h / | awk 'NR==2 {print $4 " libres de " $2}')"
