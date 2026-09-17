param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'scripts/LocalTokenRenewal.psm1') -Force
function Check($condition, [string]$message) { if (-not $condition) { throw $message }; Write-Host "PASS renewal $message" }
function Reject([scriptblock]$action, [string]$message) { $rejected=$false; try { & $action | Out-Null } catch { $rejected=$true }; Check $rejected $message }
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('salesflow-renewal-test-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $fixture | Out-Null
    $envPath = Join-Path $fixture '.env'
    $scheduler = 'a' * 64
    $intake = 'b' * 64
    $values = @('POSTGRES_DB=salesflow','POSTGRES_SUPERUSER=postgres','TEST_WHATSAPP_ACCOUNT_REF=test-account',"SCHEDULER_TOKEN=$scheduler","TEST_WHATSAPP_RUNTIME_TOKEN=$intake")
    [IO.File]::WriteAllLines($envPath, $values)
    $settings = Get-LocalTokenRenewalSettings -Root $fixture
    Check ($settings.Project -match '^salesflow-[0-9a-f]{12}$') 'checkout identity is bounded'
    Check ((Get-LocalTokenRenewalSettings -Root ($fixture + [IO.Path]::DirectorySeparatorChar)).Project -eq $settings.Project) 'trailing separator does not change project scope'
    $template = Get-Content (Join-Path $root 'scripts/renew-local-tokens.sql') -Raw
    $sql = New-LocalTokenRenewalSql -Settings $settings -Template $template
    Check (-not $sql.Contains($scheduler) -and -not $sql.Contains($intake)) 'database command never contains plaintext tokens'
    Check ($sql.Contains('ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb') -and $sql.Contains('a0fab1377f49a759b57f63318262ebe89fabfc990e8e93ceac2984561482b9d4')) 'command uses independently known token digests'
    Check (-not $sql.Contains('__SCHEDULER_HASH__') -and -not $sql.Contains('__INTAKE_HASH__')) 'both template inputs resolve'
    [IO.File]::WriteAllLines($envPath, $values + 'COMPOSE_PROJECT_NAME=unrelated-project')
    Reject { Get-LocalTokenRenewalSettings -Root $fixture } 'foreign project label rejected'
    [IO.File]::WriteAllLines($envPath, $values + "SCHEDULER_TOKEN=$scheduler")
    Reject { Get-LocalTokenRenewalSettings -Root $fixture } 'duplicate environment keys rejected'
    [IO.File]::WriteAllLines($envPath, ($values -replace 'TEST_WHATSAPP_ACCOUNT_REF=test-account','TEST_WHATSAPP_ACCOUNT_REF=customer'))
    Reject { Get-LocalTokenRenewalSettings -Root $fixture } 'non-fixture account rejected'
    [IO.File]::WriteAllLines($envPath, ($values -replace 'POSTGRES_DB=salesflow','POSTGRES_DB=production'))
    Reject { Get-LocalTokenRenewalSettings -Root $fixture } 'unexpected database rejected'
    [IO.File]::WriteAllLines($envPath, ($values -replace ('SCHEDULER_TOKEN=' + $scheduler),'SCHEDULER_TOKEN=short'))
    Reject { Get-LocalTokenRenewalSettings -Root $fixture } 'unexpected token format rejected'
    foreach ($endpoint in @('npipe:////./pipe/dockerDesktopLinuxEngine','unix:///var/run/docker.sock')) { Assert-LocalDockerEndpoint $endpoint }
    foreach ($endpoint in @('ssh://server','tcp://127.0.0.1:2375','tcp://customer:2376','')) { Reject { Assert-LocalDockerEndpoint $endpoint } 'remote or ambiguous Docker transport rejected' }
} finally {
    $resolvedFixture = [IO.Path]::GetFullPath($fixture)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if ($resolvedFixture.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolvedFixture -Leaf) -like 'salesflow-renewal-test-*') { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force -ErrorAction SilentlyContinue }
}
