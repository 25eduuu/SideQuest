$ErrorActionPreference = 'Stop'
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { throw 'Installa Python 3 per avviare il server di anteprima locale.' }
Set-Location $PSScriptRoot
Write-Host 'Sidequest è disponibile su http://localhost:8000/'
python -m http.server 8000
