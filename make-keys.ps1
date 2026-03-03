# Liest API Keys aus config.txt und erstellt keys.json

$lines = Get-Content "config.txt"
$google = $lines[0].Trim()
$groq = ""
$publicBaseUrl = ""

foreach ($line in $lines) {
    if ($line -match "^OPENAI_KEY=(.+)$") {
        $groq = $matches[1].Trim()
    }
    if ($line -match "^PUBLIC_URL=(.+)$") {
        $publicBaseUrl = $matches[1].Trim()
    }
}

# Lokale IP ermitteln (WLAN/Ethernet bevorzugt, VirtualBox etc. ignorieren)
$ip = Get-NetIPAddress -AddressFamily IPv4 `
    | Where-Object {
        $_.IPAddress -notmatch "^127\." -and
        $_.IPAddress -notmatch "^169\.254" -and
        $_.InterfaceAlias -notmatch "VirtualBox|VMware|Hyper-V|vEthernet|Loopback|Bluetooth"
    } `
    | Sort-Object {
        switch -Wildcard ($_.InterfaceAlias) {
            "Wi-Fi*"      { 1 }
            "WLAN*"       { 1 }
            "Ethernet*"   { 2 }
            "LAN*"        { 2 }
            default       { 9 }
        }
    } `
    | Select-Object -First 1 -ExpandProperty IPAddress

if (-not $ip) { $ip = "localhost" }

# Ausgabe
Write-Host "  Google Key: $($google.Substring(0, [Math]::Min(8,$google.Length)))..."
if ($groq.Length -gt 0) {
    Write-Host "  Groq Key:   $($groq.Substring(0, [Math]::Min(8,$groq.Length)))..."
} else {
    Write-Host "  Groq Key:   NICHT GEFUNDEN"
}
Write-Host "  Lokale IP:  $ip"
if ($publicBaseUrl.Length -gt 0) {
    Write-Host "  Public URL: $publicBaseUrl"
} else {
    Write-Host "  Public URL: (nicht gesetzt - nur lokales Netz)"
}
Write-Host ""
Write-Host "  Lokale Gast-URL: http://$ip`:3000/live-translator-google.html"
if ($publicBaseUrl.Length -gt 0) {
    Write-Host "  Externe Gast-URL: $publicBaseUrl (Raum-Code wird nach Erstellen angezeigt)"
}

# keys.json schreiben
$json = @{
    googleKey     = $google
    groqKey       = $groq
    localIp       = $ip
    publicBaseUrl = $publicBaseUrl
} | ConvertTo-Json

Set-Content "keys.json" $json
