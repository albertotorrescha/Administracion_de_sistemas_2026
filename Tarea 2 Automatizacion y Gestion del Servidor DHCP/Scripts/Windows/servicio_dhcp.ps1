<#
.SYNOPSIS
    Tarea 2: Automatización y Gestión del Servidor DHCP
    Autor:   Alberto Torres Chaparro
    Parte 1: Verificación e Instalación del Rol DHCP
#>

# Corrección de acentos para la consola
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "Comprobando estado del servicio DHCP..."

# 1. Verificamos si el servicio está instalado
$dhcpFeature = Get-WindowsFeature -Name DHCP

if ($dhcpFeature.Installed) {
    Write-Host "El rol de Servidor DHCP ya se encuentra instalado." 
}
else {
    Write-Host "El rol DHCP NO está instalado." 
    Write-Host "Iniciando instalación..." -NoNewline
    
    try {
        $ProgressPreference = 'SilentlyContinue'
        Install-WindowsFeature -Name DHCP -IncludeManagementTools -ErrorAction Stop | Out-Null
        
        Write-Host " Hecho." 
        Write-Host "Instalación completada con éxito." 
    }
    catch {
        Write-Host ""
        Write-Host "Error: No se pudo instalar el rol DHCP." 
        Write-Host $_.Exception.Message
        exit 1
    }
}

# 2. Verificamos el estado del servicio
$dhcpService = Get-Service -Name DHCPServer -ErrorAction SilentlyContinue

if ($dhcpService.Status -eq 'Running') {
    Write-Host "Estado: ACTIVO (Running)" 
}
else {
    Write-Host "Estado: DETENIDO"
}