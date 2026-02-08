<#
.SYNOPSIS
    Tarea 2: Automatizacion y Gestion del Servidor DHCP
    Autor:   Alberto Torres Chaparro
    Parte 2: Configuracion del servidor DHCP
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# El servicio esta instalado?
Write-Host "Comprobando estado del servicio DHCP..."

$dhcpFeature = Get-WindowsFeature -Name DHCP

if ($dhcpFeature.Installed) {
    Write-Host "El rol de Servidor DHCP ya se encuentra instalado." 
}
else {
    Write-Host "El rol DHCP NO esta instalado." 
    Write-Host "Iniciando instalacion..." -NoNewline
    
    try {
        # instalacion trabajando 
        $trabajo = Start-Job -ScriptBlock { 
            Install-WindowsFeature -Name DHCP -IncludeManagementTools 
        }
        Wait-Job $trabajo | Out-Null
        $resultado = Receive-Job $trabajo
        
        Write-Host " Hecho." 
        Write-Host "Instalacion completada con exito." 
    }
    catch {
        Write-Host "`nError: No se pudo instalar el rol DHCP." 
        exit 1
    }
}

# Verificamos servicio
$dhcpService = Get-Service -Name DHCPServer -ErrorAction SilentlyContinue
if ($dhcpService.Status -eq 'Running') {
    Write-Host "Estado: ACTIVO (Running)" 
} else {
    Write-Host "Estado: DETENIDO (Iniciando...)"
    Start-Service DHCPServer
}

# Configuracion de red
Write-Host "`n--- Configuracion de Parametros de Red ---" 

function Validar-IP ($ip) {
    if ($ip -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$") {
        try { [void][System.Net.IPAddress]::Parse($ip); return $true } catch { return $false }
    }
    return $false
}

function Solicitar-Dato ($mensaje) {
    do {
        $inputUsuario = Read-Host "$mensaje"
        if (Validar-IP $inputUsuario) { return $inputUsuario }
        Write-Host "   Error: Formato IP invalido." 
    } while ($true)
}

# --- Entrada de datos ---
Write-Host "Ingrese los datos solicitados:"

do { $NombreAmbito = Read-Host "1. Nombre del Ambito" } while ($NombreAmbito.Length -eq 0)

$RedID    = Solicitar-Dato "2. ID de Red"
$Mascara  = Solicitar-Dato "3. Mascara Subred"
$IPInicio = Solicitar-Dato "4. IP Inicial"
$IPFin    = Solicitar-Dato "5. IP Final"
$Gateway  = Solicitar-Dato "6. Gateway"
$DNS      = Solicitar-Dato "7. DNS"

# --- Menu de confirmacion ---
do {
    Clear-Host
    Write-Host "=========================================="
    Write-Host "          RESUMEN DE CONFIGURACION"
    Write-Host "=========================================="
    Write-Host "  1. Nombre:       $NombreAmbito"
    Write-Host "  2. Red ID:       $RedID"
    Write-Host "  3. Mascara:      $Mascara"
    Write-Host "  4. IP Inicial:   $IPInicio"
    Write-Host "  5. IP Final:     $IPFin"
    Write-Host "  6. Gateway:      $Gateway"
    Write-Host "  7. DNS:          $DNS"
    Write-Host "=========================================="
    
    $conf = Read-Host "Son correctos estos datos? (s/n)"
    if ($conf -match "^[sS]$") { break }
    
    Write-Host ""
    $opcion = Read-Host "Ingrese el numero de la opcion a corregir (1-7)"
    switch ($opcion) {
        "1" { $NombreAmbito = Read-Host "Nuevo Nombre" }
        "2" { $RedID    = Solicitar-Dato "Nueva Red ID" }
        "3" { $Mascara  = Solicitar-Dato "Nueva Mascara" }
        "4" { $IPInicio = Solicitar-Dato "Nueva IP Inicial" }
        "5" { $IPFin    = Solicitar-Dato "Nueva IP Final" }
        "6" { $Gateway  = Solicitar-Dato "Nuevo Gateway" }
        "7" { $DNS      = Solicitar-Dato "Nuevo DNS" }
    }
} while ($true)

Write-Host "`nAplicando configuracion..." 

# Sobrescribir un Scope
if (Get-DhcpServerv4Scope -ScopeId $RedID -ErrorAction SilentlyContinue) {
    Write-Host "ADVERTENCIA: Ya existe un ambito con el ID $RedID." -ForegroundColor Yellow
    $decision = Read-Host "   Desea SOBRESCRIBIR (borrar y crear de nuevo)? (s/n)"
    
    if ($decision -match "^[sS]$") {
        Write-Host "   Eliminando ambito anterior..." -NoNewline
        Remove-DhcpServerv4Scope -ScopeId $RedID -Force
        Start-Sleep -Seconds 2
        Write-Host " Hecho."
    } else {
        Write-Host "   Operacion cancelada. No se hicieron cambios."
        exit
    }
}

Write-Host ""
Write-Host "Creando nuevo ambito..." -NoNewline

try {
    # 1. Crear ambito 
    Add-DhcpServerv4Scope -Name $NombreAmbito -StartRange $IPInicio -EndRange $IPFin -SubnetMask $Mascara -State Active -ErrorAction Stop
    Write-Host " Hecho."

    # 2. Configurar Puerta de Enlace
    Write-Host "Configurando Gateway..." -NoNewline
    Set-DhcpServerv4OptionValue -ScopeId $RedID -OptionId 3 -Value $Gateway -ErrorAction Stop
    Write-Host " Hecho."
    
# 3. Configurar DNS
    Write-Host "Configurando DNS..." -NoNewline
    try {
        Set-DhcpServerv4OptionValue -ScopeId $RedID -OptionId 6 -Value $DNS -ErrorAction Stop
        Write-Host " Hecho."
    }
    catch {
        Write-Host ""
        Write-Host "   [AVISO] El DNS no responde." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "EXITO: Configuracion aplicada correctamente." -ForegroundColor Green
    Restart-Service -Name DHCPServer -Force
}
catch {
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" 
    exit 1
}


# --- Monitoreo en tiempo real
Write-Host ""
Write-Host "--- Iniciando Monitor ---"
Start-Sleep -Seconds 1

while ($true) {
    Clear-Host
    
    $clientes = @(Get-DhcpServerv4Lease -ScopeId $RedID -ErrorAction SilentlyContinue)
    $hora = Get-Date -Format "HH:mm:ss"
    
    # --- ENCABEZADO ---
    Write-Host "================================================================"
    Write-Host "   MONITOR DHCP SERVER  |  Actualizado: $hora"
    Write-Host "   Ambito: $RedID ($NombreAmbito)"
    Write-Host "================================================================"
    
    if ($clientes.Count -gt 0) {
        # --- TABLA DE CLIENTES ---
        # Cabecera
        Write-Host ("{0,-16} {1,-20} {2,-18} {3,-10}" -f "IP ADDRESS", "HOSTNAME", "MAC ADDRESS", "EXPIRA")
        Write-Host "----------------------------------------------------------------"

        foreach ($cliente in $clientes) {
            $expira = $cliente.LeaseExpiryTime.ToString("HH:mm:ss")
            
            # Filas de datos 
            Write-Host ("{0,-16}" -f $cliente.IPAddress) -NoNewline
            Write-Host ("{0,-20}" -f $cliente.HostName)  -NoNewline
            Write-Host ("{0,-18}" -f $cliente.ClientId)  -NoNewline
            Write-Host ("{0,-10}" -f $expira)
        }
        
        Write-Host ""
        Write-Host " [ TOTAL CLIENTES CONECTADOS: $($clientes.Count) ]"
    }
    else {
        # --- MODO ESPERA ---
        Write-Host ""
        Write-Host "    Escuchando red..."
        Write-Host ""
        Write-Host "    [!] Esperando solicitudes DHCP..."
        Write-Host ""
    }
    
    # Pie de pagina
    Write-Host ""
    Write-Host "================================================================"
    Write-Host " [CTRL+C] para detener el script."
    
    Start-Sleep -Seconds 3
}