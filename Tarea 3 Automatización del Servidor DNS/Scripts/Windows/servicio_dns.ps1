#========================================================================
#   Tarea 3: Automatización del Servidor DNS
#   Autor: Alberto Torres Chaparro
#   Descripción: Este script automatiza la instalación y configuración 
#   del servicio DNS en Windows Server 2022.
#========================================================================

function Estado-DNS {

    Clear-Host
    Write-Host "======================================="
    Write-Host "      ESTADO DEL SERVICIO DNS"
    Write-Host "======================================="

    $servicio = Get-Service -Name DNS -ErrorAction SilentlyContinue

    if ($servicio -eq $null) {
        Write-Host "Servicio DNS no instalado." -ForegroundColor Red
        Pause
        return
    }

    Write-Host "Estado actual: $($servicio.Status)"

    Write-Host ""
    Write-Host "1) Iniciar Servicio"
    Write-Host "2) Reiniciar Servicio"
    Write-Host "3) Volver"

    $op = Read-Host "Seleccione opcion"

    switch ($op) {
        "1" { Start-Service DNS }
        "2" { Restart-Service DNS }
        default { return }
    }

    Pause
}

function Instalar-DNS {

    Clear-Host

    if ((Get-WindowsFeature -Name DNS).Installed) {
        Write-Host "DNS ya está instalado." -ForegroundColor Yellow
        Pause
        return
    }

    Write-Host "Instalando servicio DNS..."
    Install-WindowsFeature -Name DNS -IncludeManagementTools

    if ((Get-WindowsFeature -Name DNS).Installed) {

        # Iniciar servicio DNS
        Start-Service DNS

        # Cambiar red interna a Private automáticamente
        Set-NetConnectionProfile `
            -InterfaceAlias "Ethernet 2" `
            -NetworkCategory Private `
            -ErrorAction SilentlyContinue

        # Permitir tráfico DNS en firewall
        Enable-NetFirewallRule `
            -DisplayGroup "DNS Server" `
            -ErrorAction SilentlyContinue

        # Habilitar regla oficial de ICMPv4 (Ping)
        Enable-NetFirewallRule `
            -Name FPS-ICMP4-ERQ-In `
            -ErrorAction SilentlyContinue

        Write-Host "Instalacion completada y firewall configurado correctamente." -ForegroundColor Green
    }
    else {
        Write-Host "Error en instalación." -ForegroundColor Red
    }

    Pause
}

function Nuevo-Dominio {

    Clear-Host
    $dominio = Read-Host "Ingrese el nombre del dominio: "

    if ([string]::IsNullOrWhiteSpace($dominio)) {
        Write-Host "Dominio invalido." -ForegroundColor Red
        Pause
        return
    }

    # Detectar IP automáticamente (red interna)
    $ipServidor = (Get-NetIPAddress -AddressFamily IPv4 `
        | Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -ne "127.0.0.1" } `
        | Select-Object -First 1).IPAddress

    if (-not $ipServidor) {
        Write-Host "No se pudo detectar IP." -ForegroundColor Red
        Pause
        return
    }

    if (Get-DnsServerZone -Name $dominio -ErrorAction SilentlyContinue) {
        Write-Host "El dominio ya existe." -ForegroundColor Yellow
        Pause
        return
    }

    Write-Host "Creando zona DNS..."

    Add-DnsServerPrimaryZone -Name $dominio -ZoneFile "$dominio.dns"

    Add-DnsServerResourceRecordA `
        -ZoneName $dominio `
        -Name "@" `
        -IPv4Address $ipServidor

    Add-DnsServerResourceRecordA `
        -ZoneName $dominio `
        -Name "www" `
        -IPv4Address $ipServidor

    Write-Host "Dominio creado correctamente." -ForegroundColor Green
    Write-Host "IP asociada: $ipServidor"

    Pause
}

function Borrar-Dominio {

    $dominio = Read-Host "Ingrese el dominio a eliminar"

    if (Get-DnsServerZone -Name $dominio -ErrorAction SilentlyContinue) {
        Remove-DnsServerZone -Name $dominio -Force
        Write-Host "Dominio eliminado." -ForegroundColor Green
    }
    else {
        Write-Host "Dominio no existe." -ForegroundColor Red
    }

    Pause
}

function Consultar-Dominio {

    Clear-Host

    $zonas = Get-DnsServerZone | Where-Object { $_.ZoneType -eq "Primary" }

    if ($zonas.Count -eq 0) {
        Write-Host "No existen dominios configurados."
        Pause
        return
    }

    Write-Host "Dominios disponibles:"
    $i = 1
    foreach ($zona in $zonas) {
        Write-Host "$i) $($zona.ZoneName)"
        $i++
    }

    $seleccion = Read-Host "Seleccione numero"
    $dominio = $zonas[$seleccion - 1].ZoneName

    Write-Host ""
    Write-Host "Dominio seleccionado: $dominio"
    Write-Host "-----------------------------------"

    $registro = Get-DnsServerResourceRecord -ZoneName $dominio -RRType A |
                Where-Object { $_.HostName -eq "@" }

    if ($registro) {
        Write-Host "IP Asociada: $($registro.RecordData.IPv4Address)"
    }
    else {
        Write-Host "No se encontro registro A."
    }

    Pause
}

# ================= MENU =================
function Menu-DNS(){
    while ($true) {

    Clear-Host
    Write-Host "======================================="
    Write-Host "          SERVICIO DNS"
    Write-Host "======================================="
    Write-Host "1) Estado del servicio DNS"
    Write-Host "2) Instalar el servicio DNS"
    Write-Host "3) Nuevo Dominio"
    Write-Host "4) Borrar Dominio"
    Write-Host "5) Consultar Dominio"
    Write-Host "6) Salir"
    Write-Host "======================================="

    $opcion = Read-Host "Selecciona una opcion"

    switch ($opcion) {
        "1" { Estado-DNS }
        "2" { Instalar-DNS }
        "3" { Nuevo-Dominio }
        "4" { Borrar-Dominio }
        "5" { Consultar-Dominio }
        "6" { exit }
        default { Write-Host "Opcion invalida"; Start-Sleep 1 }
    }
}
}

