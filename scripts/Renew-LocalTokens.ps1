param()
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'LocalTokenRenewal.psm1') -Force
$root = Split-Path -Parent $PSScriptRoot
$settings = Get-LocalTokenRenewalSettings -Root $root
$manifest = Get-Content -LiteralPath (Join-Path $root 'release/release-manifest.json') -Raw | ConvertFrom-Json
if ($manifest.livePromotionAllowed -ne $false) { throw 'Local renewal is disabled for a promotion-enabled manifest.' }
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker is required to renew the retained local credentials.' }
# Refuse remote engines, including an explicit DOCKER_HOST override.
if ($env:DOCKER_HOST) { Assert-LocalDockerEndpoint $env:DOCKER_HOST }
$contextOutput = @(docker context inspect --format '{{json .Endpoints.docker.Host}}' 2>$null)
if ($LASTEXITCODE -ne 0 -or $contextOutput.Count -ne 1) { throw 'Could not verify the local Docker endpoint.' }
Assert-LocalDockerEndpoint ($contextOutput[0] | ConvertFrom-Json)
$composeArgs = @('compose','--project-directory',$settings.Root,'--env-file',$settings.EnvironmentFile,'-p',$settings.Project)
$container = @(docker @composeArgs ps --status running -q postgres 2>$null)
if ($LASTEXITCODE -ne 0 -or $container.Count -ne 1 -or $container[0] -notmatch '^[0-9a-f]{12,64}$') { throw 'The checkout PostgreSQL service must be running before renewal.' }
$labelsOutput = @(docker inspect --format '{{json .Config.Labels}}' $container[0] 2>$null)
if ($LASTEXITCODE -ne 0 -or $labelsOutput.Count -ne 1) { throw 'Could not verify the local database container identity.' }
$labels = $labelsOutput[0] | ConvertFrom-Json
if ($labels.'com.docker.compose.project' -ne $settings.Project -or $labels.'com.docker.compose.service' -ne 'postgres') { throw 'The database container does not match this checkout.' }
$sql = New-LocalTokenRenewalSql -Settings $settings -Template (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'renew-local-tokens.sql') -Raw)
# Neither raw tokens nor their digests appear in output or process arguments.
$priorPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $sql | docker exec -i $container[0] psql -X -U postgres -d salesflow -v ON_ERROR_STOP=1 *> $null
    $renewExitCode = $LASTEXITCODE
} finally { $ErrorActionPreference = $priorPreference }
if ($renewExitCode -ne 0) { throw 'Renewal failed. Both original credentials must exist, be unrevoked, and retain their original local role/account bindings. No partial renewal was committed.' }
Write-Host 'Renewed the retained synthetic scheduler and intake credentials for 24 hours. No data was reset and no credentials were displayed.'
