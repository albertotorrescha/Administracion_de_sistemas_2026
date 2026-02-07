#!/bin/bash
# ============================================================
# Tarea 2:  Automatizacion y Gestion del Servidor DHCP
#   Autor:  Alberto Torres Chaparro
# actualizacion:  Mejora visual de los clientes conectados
# ============================================================

# --- FUNCIONES DE VALIDACION

#Valida que la interfaz exista en el sistema operativo
validar_interfaz() {
    if [ -d "/sys/class/net/$1" ]; then
        return 0
    else
        return 1
    fi
}

#Valida formato IP (x.x.x.x)
validar_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

#Valida formato Subred CIDR (x.x.x.x/xx)
validar_subnet() {
    local subnet=$1
    if [[ $subnet =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 0
    else
        return 1
    fi
}

#Valida las entradas del usuario
solicitar_dato() {
    local mensaje=$1
    local tipo_validacion=$2
    local variable_ref=$3
    local input_usuario

    while true; do
        read -p "$mensaje: " input_usuario
        
        # Selector de validaciones
        case $tipo_validacion in
            "interfaz")
                if validar_interfaz "$input_usuario"; then
                    eval "$variable_ref='$input_usuario'"
                    break
                else
                    echo "Error: La interfaz '$input_usuario' no existe en este sistema."
                fi
                ;;
            "ip")
                if validar_ip "$input_usuario"; then
                    eval "$variable_ref='$input_usuario'"
                    break
                else
                    echo "Error: Formato IP invalido. Use formato numerico (ej: 192.168.100.50)."
                fi
                ;;
            "subnet")
                if validar_subnet "$input_usuario"; then
                    eval "$variable_ref='$input_usuario'"
                    break
                else
                    echo "Error: Formato invalido. Debe incluir mascara (ej: 192.168.100.0/24)."
                fi
                ;;
        esac
    done
}

echo "Comprobando servicio..."

# --- FASE 1 & 2 LA INSTALACION
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

# --- FASE 3: CONFIGURACION
echo ""
echo "--- Configuracion de Parametros de Red ---"
echo "Ingrese los datos solicitados. El sistema validara cada entrada."

# aqui el script no avanza hasta tener datos validos
solicitar_dato "1. Interfaz de Red  (Ej: enp0s8)" "interfaz" INTERFAZ
solicitar_dato "2. Subred CIDR      (Ej: 192.168.100.0/24)" "subnet" SUBNET
solicitar_dato "3. IP Inicial       (Ej: 192.168.100.50)" "ip" IP_START
solicitar_dato "4. IP Final         (Ej: 192.168.100.150)" "ip" IP_END
solicitar_dato "5. Puerta de Enlace (Ej: 192.168.100.1)" "ip" GATEWAY
solicitar_dato "6. Servidor DNS     (Ej: 192.168.100.20)" "ip" DNS_IP

echo "Datos validos. Generando archivo de configuracion..."

[ -f /etc/kea/kea-dhcp4.conf ] && cp /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.bak

cat > /etc/kea/kea-dhcp4.conf <<EOF
{
"Dhcp4": {
    "interfaces-config": {
        "interfaces": [ "$INTERFAZ" ]
    },
    "lease-database": {
        "type": "memfile",
        "persist": true,
        "name": "/var/lib/kea/kea-leases4.csv",
        "lfc-interval": 3600
    },
    "valid-lifetime": 4000,
    "option-data": [
        { "name": "domain-name-servers", "data": "$DNS_IP" },
        { "name": "routers", "data": "$GATEWAY" }
    ],
    "subnet4": [
        {
            "id": 1,
            "subnet": "$SUBNET",
            "pools": [ { "pool": "$IP_START - $IP_END" } ]
        }
    ]
}
}
EOF

echo "Validando integridad del archivo JSON..."
if kea-dhcp4 -t /etc/kea/kea-dhcp4.conf &> /dev/null; then
    echo "Configuracion valida. Reiniciando servicio..."
    
    firewall-cmd --add-service=dhcp --permanent &> /dev/null
    firewall-cmd --reload &> /dev/null
    systemctl enable --now kea-dhcp4 &> /dev/null
    systemctl restart kea-dhcp4
    
    if systemctl is-active --quiet kea-dhcp4; then
        echo "Estado Final: ACTIVO"
        # --- Actualizacion visual
        echo "--- Clientes Conectados ---"
        # Verificamos si el archivo existe y tiene datos reales
        if [ -f /var/lib/kea/kea-leases4.csv ] && [ "$(wc -l < /var/lib/kea/kea-leases4.csv)" -gt 1 ]; then
            
            # Encabezados de la tabla
            printf "%-18s | %-17s | %s\n" "DIRECCION IP" "MAC ADDRESS" "HOSTNAME"
            echo "-------------------|-------------------|--------------------"
            awk -F, 'NR>1 { leases[$1] = sprintf("%-18s | %-17s | %s", $1, $2, $9) } END { for (ip in leases) print leases[ip] }' /var/lib/kea/kea-leases4.csv | sort
            
        else
            echo "   (Esperando conexiones...)"
        fi
    else
        echo "Estado Final: FALLO AL INICIAR"
        echo "Revise los logs con: journalctl -xeu kea-dhcp4"
    fi
else
    echo "Error: Kea rechazo la configuracion generada."
    exit 1
fi