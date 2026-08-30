param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  $docker = Get-Command docker.exe -ErrorAction SilentlyContinue
  if ($null -eq $docker) { $docker = Get-Command docker -ErrorAction SilentlyContinue }
  Assert-CheckpointInvariant ($null -ne $docker) 'Environment or tooling failure' 'Docker CLI is available for read-only reachability checks' 'docker-command-not-found' $root

  # Read-only environment check: docker info never starts, stops, or changes a service.
  $info = Invoke-NativeCaptured $docker.Source @('info', '--format', '{{json .ServerVersion}}') $root
  Assert-NativeSuccess $info 'Docker daemon is reachable through docker info' 'docker info'
  try { $serverVersion = $info.Stdout | ConvertFrom-Json -ErrorAction Stop } catch {
    Assert-CheckpointInvariant $false 'Environment or tooling failure' 'docker info returns a structured server version' $_.Exception.Message 'docker info'
  }
  Assert-CheckpointInvariant (-not [string]::IsNullOrWhiteSpace([string]$serverVersion)) 'Environment or tooling failure' 'Docker reports a server version' 'empty-server-version' 'docker info'

  $composePath = Resolve-CheckpointPath $root 'compose.yaml'
  $envPath = Resolve-CheckpointPath $root '.env.example'
  # Read-only model validation: docker compose config renders configuration only.
  $configResult = Invoke-NativeCaptured $docker.Source @('compose', '--file', $composePath, '--env-file', $envPath, 'config', '--format', 'json') $root
  Assert-NativeSuccess $configResult 'Docker Compose model validates without mutating state' 'docker compose config'
  try { $compose = $configResult.Stdout | ConvertFrom-Json -ErrorAction Stop } catch {
    Assert-CheckpointInvariant $false 'Syntax or integration failure' 'docker compose config emits JSON' $_.Exception.Message 'compose.yaml'
  }

  $postgres = $compose.services.PSObject.Properties['postgres'].Value
  $n8n = $compose.services.PSObject.Properties['n8n'].Value
  Assert-CheckpointInvariant ($null -ne $postgres -and $null -ne $n8n) 'Behavioral checkpoint failure' 'Compose defines PostgreSQL and n8n services' 'required-services-missing' 'compose.yaml'
  $ports = @($n8n.ports)
  $loopbackOnly = $ports.Count -eq 1 -and [string]$ports[0].host_ip -eq '127.0.0.1' -and [int]$ports[0].target -eq 5678
  Assert-CheckpointInvariant $loopbackOnly 'Behavioral checkpoint failure' 'n8n publishes port 5678 only on 127.0.0.1' ("ports=" + ($ports | ConvertTo-Json -Compress)) 'compose.yaml services.n8n.ports'
  $healthCommand = @($postgres.healthcheck.test) -join ' '
  Assert-CheckpointInvariant ($healthCommand -match '(?i)pg_isready') 'Behavioral checkpoint failure' 'PostgreSQL declares a pg_isready healthcheck' $healthCommand 'compose.yaml services.postgres.healthcheck'

  # Read-only runtime evidence: ps inspects current state and never changes it.
  $psResult = Invoke-NativeCaptured $docker.Source @('compose', '--file', $composePath, '--env-file', $envPath, 'ps', '--format', 'json') $root
  Assert-NativeSuccess $psResult 'Docker Compose can report local service readiness without mutation' 'docker compose ps'
  $serviceRows = @()
  try {
    if ($psResult.Stdout.TrimStart().StartsWith('[')) {
      $serviceRows = @($psResult.Stdout | ConvertFrom-Json -ErrorAction Stop)
    } else {
      $serviceRows = @($psResult.Stdout -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_ | ConvertFrom-Json -ErrorAction Stop })
    }
  } catch {
    Assert-CheckpointInvariant $false 'Syntax or integration failure' 'docker compose ps emits JSON service records' $_.Exception.Message 'docker compose ps'
  }
  $postgresRow = @($serviceRows | Where-Object { [string]$_.Service -eq 'postgres' })[0]
  $n8nRow = @($serviceRows | Where-Object { [string]$_.Service -eq 'n8n' })[0]
  $postgresState = if ($null -eq $postgresRow) { '<missing>' } else { [string]$postgresRow.State }
  $postgresHealth = if ($null -eq $postgresRow) { '<missing>' } else { [string]$postgresRow.Health }
  $n8nState = if ($null -eq $n8nRow) { '<missing>' } else { [string]$n8nRow.State }
  Assert-CheckpointInvariant ($null -ne $postgresRow -and $postgresState -eq 'running' -and $postgresHealth -eq 'healthy') 'Behavioral checkpoint failure' 'PostgreSQL service is running and healthy' ("state=$postgresState; health=$postgresHealth") 'docker compose ps postgres'
  Assert-CheckpointInvariant ($null -ne $n8nRow -and $n8nState -eq 'running') 'Behavioral checkpoint failure' 'n8n service container is running after its healthy PostgreSQL dependency' "state=$n8nState" 'docker compose ps n8n'
  try {
    $n8nHealth = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:5678/healthz' -TimeoutSec 5 -ErrorAction Stop
  } catch {
    Assert-CheckpointInvariant $false 'Environment or tooling failure' 'n8n health endpoint is reachable locally' $_.Exception.Message 'http://127.0.0.1:5678/healthz'
  }
  Assert-CheckpointInvariant ([int]$n8nHealth.StatusCode -eq 200) 'Behavioral checkpoint failure' 'n8n health endpoint reports HTTP 200' "status=$($n8nHealth.StatusCode)" 'http://127.0.0.1:5678/healthz'

  Write-LearningEvidence @('postgres-health', 'n8n-health', 'local-services')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
