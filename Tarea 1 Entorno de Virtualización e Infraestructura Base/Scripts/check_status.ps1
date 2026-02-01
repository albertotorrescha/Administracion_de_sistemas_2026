Clear-Host
Write-Host "========================================"
Write-Host "       INFORMACION DEL SERVIDOR"
Write-Host "========================================"
Write-Host "Nombre: $env:COMPUTERNAME"
$os = (Get-CimInstance Win32_OperatingSystem).Caption
Write-Host "S.O: $os"
$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.*"} | Select-Object -ExpandProperty IPAddress
Write-Host "Direccion IPv4: $ip"
$disk = Get-Volume -DriveLetter C
$free = [math]::Round($disk.SizeRemaining / 1GB, 2)
$total = [math]::Round($disk.Size / 1GB, 2)
Write-Host "Espacio en disco: $free GB libres de $total GB"
Write-Host "========================================"