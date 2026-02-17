#!/bin/bash
#========================================================================
#   Tarea 3: Automatización del Servidor DNS
#   Autor: Alberto Torres Chaparro
#   Descripción: Este script automatiza la instalación y configuración 
#   de un servidor DNS utilizando BIND9 en Oracle Linux.
#========================================================================

# Función para ver el estado del servicio DNS
estado_dns() {
    while true; do
        clear
        echo "========================================"
        echo "        ESTADO DEL SERVICIO DNS"
        echo "========================================"

        if ! rpm -q bind &> /dev/null; then
            echo -e "${RED}[!] El paquete 'bind' no está instalado.${NC}"
            echo "Use la opción de instalar servicio primero."
            read -p "Presione Enter..."
            return
        fi

        if systemctl is-active --quiet named; then
            echo -e "Estado actual: ${GREEN}ACTIVO (Running)${NC}"
            systemctl status named --no-pager | grep Active
            echo "----------------------------------------"
            echo "1) Detener servicio"
            echo "2) Reiniciar servicio"
            echo "3) Volver al menú DNS"
        else
            echo -e "Estado actual: ${RED}INACTIVO (Stopped)${NC}"
            echo "----------------------------------------"
            echo "1) Iniciar servicio"
            echo "3) Volver al menú DNS"
        fi

        echo "----------------------------------------"
        read -p "Seleccione una opción: " opcion

        case $opcion in
            1)
                if systemctl is-active --quiet named; then
                    echo "Deteniendo servicio..."
                    systemctl stop named
                else
                    echo "Iniciando servicio..."
                    systemctl start named
                fi
                sleep 2
                ;;
            2)
                if systemctl is-active --quiet named; then
                    echo "Reiniciando servicio..."
                    systemctl restart named
                    sleep 2
                else
                    echo "El servicio está detenido. No se puede reiniciar."
                    sleep 2
                fi
                ;;
            3)
                return
                ;;
            *)
                echo "Opción no válida."
                sleep 1
                ;;
        esac
    done
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

#Función para crear un dominio
nuevo_dominio() {

    read -p "Ingrese el nombre del dominio (ej: reprobados.com): " DOMINIO

    if [ -z "$DOMINIO" ]; then
        echo "Dominio inválido."
        sleep 2
        return
    fi

    
    read -p "Ingrese la interfaz de red interna (ej: enp0s8): " INTERFAZ_DNS
    IP_SERVIDOR=$(ip -4 addr show "$INTERFAZ_DNS" | grep inet | awk '{print $2}' | cut -d/ -f1)
    ZONA_FILE="/var/named/$DOMINIO.zone"

    # Verificar si ya existe
    if grep -q "zone \"$DOMINIO\"" /etc/named.conf; then
        echo "El dominio ya existe."
        sleep 2
        return
    fi

    echo "Creando zona DNS..."

    # Agregar zona a named.conf
    cat <<EOF >> /etc/named.conf

zone "$DOMINIO" IN {
    type master;
    file "$ZONA_FILE";
};
EOF

    # Crear archivo de zona
    cat <<EOF > $ZONA_FILE
\$TTL 86400
@   IN  SOA ns1.$DOMINIO. admin.$DOMINIO. (
        2026021701
        3600
        1800
        604800
        86400 )

@       IN  NS      ns1.$DOMINIO.
ns1     IN  A       $IP_SERVIDOR
@       IN  A       $IP_SERVIDOR
www     IN  A       $IP_SERVIDOR
EOF

    chown named:named $ZONA_FILE
    chmod 640 $ZONA_FILE

    firewall-cmd --add-service=dns --permanent &> /dev/null
    firewall-cmd --reload &> /dev/null

    systemctl restart named

    if systemctl is-active --quiet named; then
        echo -e "${GREEN}[EXITO] Dominio $DOMINIO creado correctamente.${NC}"
        echo "IP asociada: $IP_SERVIDOR"
    else
        echo -e "${RED}[ERROR] named no pudo iniciar.${NC}"
    fi

    read -p "Enter..."
}

#Función para borrar un dominio
borrar_dominio() {

    read -p "Ingrese el dominio a eliminar: " DOMINIO
    ZONA_FILE="/var/named/$DOMINIO.zone"

    if ! grep -q "zone \"$DOMINIO\"" /etc/named.conf; then
        echo "El dominio no existe."
        sleep 2
        return
    fi

    # Eliminar bloque de zona
    sed -i "/zone \"$DOMINIO\"/,/};/d" /etc/named.conf

    # Eliminar archivo de zona
    rm -f $ZONA_FILE

    systemctl restart named

    echo -e "${GREEN}Dominio eliminado correctamente.${NC}"
    read -p "Enter..."
}

#Función para consultar un dominio
consultar_dominio() {

    clear
    echo "========================================"
    echo "         CONSULTAR DOMINIO"
    echo "========================================"

    # Obtener lista de dominios definidos
    DOMINIOS=($(grep -oP 'zone\s+"\K[^"]+' /etc/named.conf))

    if [ ${#DOMINIOS[@]} -eq 0 ]; then
        echo "No hay dominios configurados."
        read -p "Enter..."
        return
    fi

    echo "Dominios disponibles:"
    echo "----------------------------------------"

    # Mostrar lista numerada
    for i in "${!DOMINIOS[@]}"; do
        echo "$((i+1))) ${DOMINIOS[$i]}"
    done

    echo "----------------------------------------"
    read -p "Seleccione un dominio: " opcion

    # Validar selección
    if ! [[ "$opcion" =~ ^[0-9]+$ ]] || [ "$opcion" -lt 1 ] || [ "$opcion" -gt ${#DOMINIOS[@]} ]; then
        echo "Selección inválida."
        sleep 2
        return
    fi

    DOMINIO_SELECCIONADO=${DOMINIOS[$((opcion-1))]}

    clear
    echo "========================================"
    echo "Dominio seleccionado: $DOMINIO_SELECCIONADO"
    echo "========================================"

    # Mostrar IP asociada
    echo "Direccion IP asociada al dominio:"
    dig @localhost +short "$DOMINIO_SELECCIONADO"

    echo "----------------------------------------"
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
        echo "3) Nuevo Dominio"
        echo "4) Borrar Dominio"
        echo "5) Consultar Dominio"
        echo "6) Salir"
        echo "========================================"
        read -p "Selecciona una opción: " opcion
        case $opcion in
            1) estado_dns ;;
            2) instalar_dns ;;
            3) nuevo_dominio ;;
            4) borrar_dominio ;;
            5) consultar_dominio ;;
            6) echo "Saliendo del menú DNS..."; break ;;
            *) echo "Opción no válida. Inténtalo de nuevo." ;;
        esac
    done
}