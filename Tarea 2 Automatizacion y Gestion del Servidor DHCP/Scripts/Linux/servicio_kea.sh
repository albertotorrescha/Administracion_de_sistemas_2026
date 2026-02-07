#!/bin/bash
# ============================================================
# Tarea 2:  Automatizacion y Gestion del Servidor DHCP
#   Autor:  Alberto Torres Chaparro
# Actualizacion:  Implementacion de un menu de correccion selectiva 
#                 y monitoreo en tiempo real de los clientes conectados
# ============================================================

# --- FUNCIONES DE VALIDACION ---

# Verifica si la interfaz de red existe en el sistema (ej: enp0s8)
validar_interfaz() {
    if [ -d "/sys/class/net/$1" ]; then return 0; else return 1; fi
}

# Verifica formato IPv4 (x.x.x.x)
validar_ip() {
    if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then return 0; else return 1; fi
}

# Verifica formato CIDR (x.x.x.x/xx)
validar_subnet() {
    if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then return 0; else return 1; fi
}

# --- FUNCION DE CAPTURA DE DATOS ---
# Pide un dato hasta que sea valido segun su tipo
solicitar_dato() {
    local mensaje=$1
    local tipo=$2
    local var_ref=$3
    local input

    while true; do
        read -p "$mensaje: " input
        case $tipo in
            "interfaz")
                if validar_interfaz "$input"; then eval "$var_ref='$input'"; break; fi
                echo "Error: La interfaz '$input' no existe en este sistema." ;;
            "ip")
                if validar_ip "$input"; then eval "$var_ref='$input'"; break; fi
                echo "Error: Formato IP invalido (ej: 192.168.100.50)." ;;
            "subnet")
                if validar_subnet "$input"; then eval "$var_ref='$input'"; break; fi
                echo "Error: Formato invalido (ej: 192.168.100.0/24)." ;;
        esac
    done
}

# Muestra la tabla de configuracion actual
mostrar_resumen() {
    clear
    echo "=========================================="
    echo "          RESUMEN DE CONFIGURACION"
    echo "=========================================="
    echo "  1. Interfaz:      $INTERFAZ"
    echo "  2. Subred:        $SUBNET"
    echo "  3. IP Inicial:    $IP_START"
    echo "  4. IP Final:      $IP_END"
    echo "  5. Gateway:       $GATEWAY"
    echo "  6. DNS:           $DNS_IP"
    echo "=========================================="
}

echo "Comprobando servicio..."

# --- FASE 1 & 2: INSTALACION ---
if rpm -q kea &> /dev/null; then
    echo "El servicio Kea DHCP ya se encuentra instalado."
else
    echo "El servicio Kea DHCP NO esta instalado."
    echo "Iniciando instalacion..."
    dnf install -y kea &> /dev/null
    
    if rpm -q kea &> /dev/null; then
        echo "Instalacion completada con exito."
    else
        echo "Error Critico: No se pudo instalar Kea."
        exit 1
    fi
fi

# --- FASE 3: ENTRADA INICIAL DE DATOS ---
echo ""
echo "--- Configuracion de Parametros de Red ---"
solicitar_dato "Ingrese Interfaz (ej: enp0s8)" "interfaz" INTERFAZ
solicitar_dato "Ingrese Subred CIDR (ej: 192.168.100.0/24)" "subnet" SUBNET
solicitar_dato "Ingrese IP Inicial (ej: 192.168.100.50)" "ip" IP_START
solicitar_dato "Ingrese IP Final (ej: 192.168.100.150)" "ip" IP_END
solicitar_dato "Ingrese Gateway (ej: 192.168.100.1)" "ip" GATEWAY
solicitar_dato "Ingrese DNS (ej: 192.168.100.20)" "ip" DNS_IP

# --- FASE 4: CONFIRMACION Y EDICION SELECTIVA ---
# Bucle que permite corregir datos especificos antes de continuar
while true; do
    mostrar_resumen
    read -p "¿Son correctos estos datos? (s/n): " CONFIRMACION
    
    if [[ "$CONFIRMACION" =~ ^[sS]$ ]]; then
        break
    else
        echo ""
        read -p "Ingrese el numero de la opcion que desea corregir (1-6): " OPCION
        case $OPCION in
            1) solicitar_dato "Nueva Interfaz" "interfaz" INTERFAZ ;;
            2) solicitar_dato "Nueva Subred" "subnet" SUBNET ;;
            3) solicitar_dato "Nueva IP Inicial" "ip" IP_START ;;
            4) solicitar_dato "Nueva IP Final" "ip" IP_END ;;
            5) solicitar_dato "Nuevo Gateway" "ip" GATEWAY ;;
            6) solicitar_dato "Nuevo DNS" "ip" DNS_IP ;;
            *) echo "Opcion invalida." ; sleep 1 ;;
        esac
    fi
done

echo ""
echo "Generando archivo de configuracion..."

# Respaldo de seguridad
[ -f /etc/kea/kea-dhcp4.conf ] && cp /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.bak

# Generacion del JSON de configuracion
cat > /etc/kea/kea-dhcp4.conf <<EOF
{
"Dhcp4": {
    "interfaces-config": { "interfaces": [ "$INTERFAZ" ] },
    "lease-database": {
        "type": "memfile", "persist": true,
        "name": "/var/lib/kea/kea-leases4.csv", "lfc-interval": 3600
    },
    "valid-lifetime": 4000,
    "option-data": [
        { "name": "domain-name-servers", "data": "$DNS_IP" },
        { "name": "routers", "data": "$GATEWAY" }
    ],
    "subnet4": [
        {
            "id": 1, "subnet": "$SUBNET",
            "pools": [ { "pool": "$IP_START - $IP_END" } ]
        }
    ]
}
}
EOF

# --- Fase 5: Validacion
echo "Validando sintaxis..."

# Validamos la configuracion generada antes de reiniciar
if kea-dhcp4 -t /etc/kea/kea-dhcp4.conf &> /dev/null; then
    echo "Configuracion valida. Aplicando cambios..."
    
    firewall-cmd --add-service=dhcp --permanent &> /dev/null
    firewall-cmd --reload &> /dev/null
    systemctl enable --now kea-dhcp4 &> /dev/null
    systemctl restart kea-dhcp4
    
    if systemctl is-active --quiet kea-dhcp4; then
        echo "Estado Final: ACTIVO"
        echo ""
        echo ">>> Iniciando Monitor en Tiempo Real..."
        sleep 2

        # Bucle de monitoreo
        while true; do
            clear
            echo "================================================================"
            echo "   MONITOR DHCP KEA - $(date '+%H:%M:%S')"
            echo "   (Presione Ctrl+C para salir)"
            echo "================================================================"
            
            if [ -f /var/lib/kea/kea-leases4.csv ] && [ "$(wc -l < /var/lib/kea/kea-leases4.csv)" -gt 1 ]; then
                printf "%-18s | %-17s | %s\n" "DIRECCION IP" "MAC ADDRESS" "HOSTNAME"
                echo "-------------------|-------------------|--------------------"
                awk -F, 'NR>1 { leases[$1] = sprintf("%-18s | %-17s | %s", $1, $2, $9) } END { for (ip in leases) print leases[ip] }' /var/lib/kea/kea-leases4.csv | sort
            else
                echo "   (Esperando clientes... Conecte un dispositivo)"
            fi
            # Actualiza cada 3 segundos
            sleep 3
        done
    else
        echo "Estado Final: FALLO AL INICIAR"
        echo "Revise logs: journalctl -xeu kea-dhcp4"
    fi
else
    echo "Error Critico: Kea rechazo la configuracion generada."
    echo "Revise que la Subred coincida con el rango de IPs."
    exit 1
fi