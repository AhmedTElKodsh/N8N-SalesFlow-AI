Set-StrictMode -Version Latest

function Get-LocalTokenRenewalSettings {
    param([Parameter(Mandatory=$true)][string]$Root)
    $path = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
    $environmentFile = Join-Path $path '.env'
    if (-not (Test-Path -LiteralPath $environmentFile -PathType Leaf)) { throw 'No retained local .env exists. Create a verified local stack with tests/run.ps1 -KeepRunning first.' }
    $values = @{}
    foreach ($line in [IO.File]::ReadAllLines($environmentFile)) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) { continue }
        if ($line -notmatch '^([A-Z][A-Z0-9_]*)=(.*)$') { throw 'The retained environment contains an unsupported entry.' }
        $key = $Matches[1]
        if ($values.ContainsKey($key)) { throw 'The retained environment contains duplicate entries.' }
        $values[$key] = $Matches[2]
    }
    if ($values.POSTGRES_DB -ne 'salesflow' -or $values.POSTGRES_SUPERUSER -ne 'postgres' -or $values.TEST_WHATSAPP_ACCOUNT_REF -ne 'test-account') { throw 'Renewal is restricted to the harness-created synthetic local database and account.' }
    foreach ($key in @('SCHEDULER_TOKEN','TEST_WHATSAPP_RUNTIME_TOKEN')) {
        if (-not $values.ContainsKey($key) -or $values[$key] -cnotmatch '^[0-9a-f]{64}$') { throw 'The retained environment does not contain the expected generated local credentials.' }
    }
    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        $identity = ([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($path.ToLowerInvariant())))).Replace('-','').ToLowerInvariant().Substring(0,12)
        $schedulerHash = ([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($values.SCHEDULER_TOKEN)))).Replace('-','').ToLowerInvariant()
        $intakeHash = ([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($values.TEST_WHATSAPP_RUNTIME_TOKEN)))).Replace('-','').ToLowerInvariant()
    } finally { $hasher.Dispose() }
    $project = 'salesflow-' + $identity
    if ($values.ContainsKey('COMPOSE_PROJECT_NAME') -and $values.COMPOSE_PROJECT_NAME -ne $project) { throw 'The retained environment belongs to a different checkout Compose project.' }
    [pscustomobject]@{ Root=$path; EnvironmentFile=$environmentFile; Project=$project; SchedulerHash=$schedulerHash; IntakeHash=$intakeHash }
}

function New-LocalTokenRenewalSql {
    param([Parameter(Mandatory=$true)]$Settings, [Parameter(Mandatory=$true)][string]$Template)
    if ($Settings.SchedulerHash -cnotmatch '^[0-9a-f]{64}$' -or $Settings.IntakeHash -cnotmatch '^[0-9a-f]{64}$') { throw 'Invalid local credential digests.' }
    $Template.Replace('__SCHEDULER_HASH__',$Settings.SchedulerHash).Replace('__INTAKE_HASH__',$Settings.IntakeHash)
}

function Assert-LocalDockerEndpoint {
    param([AllowEmptyString()][string]$Endpoint)
    if ($Endpoint -notmatch '^(npipe:////\./pipe/[^\s]+|unix:///[^\s]+)$') { throw 'Renewal requires a local Docker named pipe or Unix socket; remote transports are refused.' }
}

Export-ModuleMember -Function Get-LocalTokenRenewalSettings,New-LocalTokenRenewalSql,Assert-LocalDockerEndpoint
