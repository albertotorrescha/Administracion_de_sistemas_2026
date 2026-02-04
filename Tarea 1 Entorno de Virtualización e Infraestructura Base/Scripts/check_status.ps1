# Script de Diagnostico basico para windows
# Proposito: Validar identidad, version y almacenamiento del nodo

Write-Host "============================="
Write-Host "     DIAGNOSTICO DE WINDOWS"
Write-Host "============================="

# 1. Identificacion del Nodo
# Usa la version de entorno del sistema para mostrar el Hostname
Write-Host "Nombre: $env:COMPUTERNAME"

# 2. Version del Sistema Operativo
# Utiliza CIM para extraer el nombre comercial de la version de Windows

$os = (Get-CimInstance Win32_OperatingSystem).Caption
Write-Host "S.O: $os"

# 3. Direccion IP (filtrada)
# Busca todas las direcciones IPv4 pero filtra solo la que empieza con "192."
# Para asegurar que mostramos la IP de la red interna y no otras interfaces.

$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.*"} | Select-Object -ExpandProperty IPAddress
Write-Host "Direccion IPv4: $ip"

# 4. Calculo de Almacenamiento
# Obtiene el objeto del disco C y realiza una operacion matematica para
# convertir los bytes a Gigabytes redondeando a 2 decimales

$disk = Get-Volume -DriveLetter C
$free = [math]::Round($disk.SizeRemaining / 1GB, 2)
$total = [math]::Round($disk.Size / 1GB, 2)
Write-Host "Espacio en disco: $free GB libres de $total GB"