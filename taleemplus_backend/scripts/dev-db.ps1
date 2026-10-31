param(
    [ValidateSet('start', 'stop', 'status')]
    [string]$Action = 'start'
)

$ErrorActionPreference = 'Stop'

$dataDir = Join-Path (Split-Path -Parent $PSScriptRoot) '.pgdata'
$logFile = Join-Path $env:TEMP 'taleemplus-pg.log'

function Resolve-PgCtl {
    if ($env:PG_CTL) { return $env:PG_CTL }

    $onPath = Get-Command pg_ctl.exe -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }

    $candidate = Get-ChildItem 'C:\Program Files\PostgreSQL\*\bin\pg_ctl.exe' -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if ($candidate) { return $candidate.FullName }

    throw 'pg_ctl.exe not found. Install PostgreSQL or set the PG_CTL environment variable.'
}

if (-not (Test-Path -LiteralPath $dataDir)) {
    throw "Local PostgreSQL data directory not found at $dataDir. Create it with initdb or point DATABASE_URL at an existing database."
}

$pgCtl = Resolve-PgCtl

switch ($Action) {
    'start' { & $pgCtl -D $dataDir -l $logFile start }
    'stop' { & $pgCtl -D $dataDir stop -m fast }
    'status' { & $pgCtl -D $dataDir status }
}

exit $LASTEXITCODE
