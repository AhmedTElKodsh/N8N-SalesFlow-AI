param([Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_.-]+$')][string]$Container)
$ErrorActionPreference='Stop'
function Query([string]$Sql, [switch]$ExpectFailure) {
    $prior=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        $output=@($Sql | docker exec -i $Container psql -X -U postgres -d postgres -v ON_ERROR_STOP=1 -qAt 2>&1)
        $code=$LASTEXITCODE
    } finally { $ErrorActionPreference=$prior }
    if ($ExpectFailure) { if ($code -eq 0) { throw 'Invalid renewal unexpectedly succeeded.' }; return }
    if ($code -ne 0) { throw 'Renewal integration query failed.' }
    ($output -join "`n").Trim()
}
# Run the exact SQL template in its required database, rather than weakening its database guard.
$exists=Query "SELECT count(*) FROM pg_database WHERE datname='salesflow';"
if ($exists -ne '0') { throw 'Renewal regression requires its dedicated fresh test container.' }
Query 'CREATE DATABASE salesflow;' | Out-Null
$template=Get-Content (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/renew-local-tokens.sql') -Raw
$schedulerHash='ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb'
$intakeHash='a0fab1377f49a759b57f63318262ebe89fabfc990e8e93ceac2984561482b9d4'
$sql=$template.Replace('__SCHEDULER_HASH__',$schedulerHash).Replace('__INTAKE_HASH__',$intakeHash)
function RenewalQuery([string]$Statement, [switch]$ExpectFailure) {
    Query ("\connect salesflow`n" + $Statement) -ExpectFailure:$ExpectFailure
}
# Apply the real migration in the dedicated database before exercising the owner command.
$migration=Get-Content (Join-Path (Split-Path -Parent $PSScriptRoot) 'database/001-initial.sql') -Raw
$encoded=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([guid]::NewGuid().ToString('N')))
foreach($placeholder in @('__MIGRATION_PASSWORD_B64__','__WORKFLOW_DB_PASSWORD_B64__','__N8N_DB_PASSWORD_B64__')){$migration=$migration.Replace($placeholder,$encoded)}
RenewalQuery $migration | Out-Null
RenewalQuery @"
INSERT INTO salesflow.accounts VALUES('test-account',true);
INSERT INTO salesflow.accounts VALUES('other-account',true);
INSERT INTO salesflow.auth_tokens(hash,role,account_ref,actor,expires_at,revoked_at) VALUES
('$schedulerHash','scheduler',NULL,'scheduler',now()-interval '1 day',NULL),
('$intakeHash','runtime','test-account','meta-runtime',now()-interval '1 day',NULL),
('untouched','operator','test-account','operator-a',now()-interval '1 day',NULL);
"@ | Out-Null
RenewalQuery $sql | Out-Null
RenewalQuery ("SET SESSION AUTHORIZATION salesflow_runtime;`n"+$sql) -ExpectFailure
$actual=RenewalQuery "SELECT count(*) FROM salesflow.auth_tokens WHERE expires_at>now()+interval '23 hours';"
if ($actual -ne '2') { throw 'Renewal did not extend exactly the two persisted credentials.' }
$actual=RenewalQuery "SELECT expires_at<now() FROM salesflow.auth_tokens WHERE hash='untouched';"
if ($actual -ne 't') { throw 'Renewal changed an unrelated credential.' }
Write-Host 'PASS renewal database exact identities renewed; unrelated credential unchanged'
RenewalQuery "UPDATE salesflow.auth_tokens SET expires_at=now()-interval '1 day'; UPDATE salesflow.auth_tokens SET revoked_at=now() WHERE hash='$intakeHash';" | Out-Null
RenewalQuery $sql -ExpectFailure
$actual=RenewalQuery "SELECT count(*) FROM salesflow.auth_tokens WHERE expires_at>now();"
if ($actual -ne '0') { throw 'Revoked credential produced partial renewal.' }
Write-Host 'PASS renewal database revoked credential rejected atomically'
RenewalQuery "UPDATE salesflow.auth_tokens SET revoked_at=NULL,account_ref='other-account' WHERE hash='$intakeHash';" | Out-Null
RenewalQuery $sql -ExpectFailure
RenewalQuery "UPDATE salesflow.auth_tokens SET account_ref='test-account',actor='different-actor' WHERE hash='$intakeHash';" | Out-Null
RenewalQuery $sql -ExpectFailure
RenewalQuery "UPDATE salesflow.auth_tokens SET actor='meta-runtime',role='operator' WHERE hash='$intakeHash';" | Out-Null
RenewalQuery $sql -ExpectFailure
RenewalQuery "UPDATE salesflow.auth_tokens SET role='runtime' WHERE hash='$intakeHash'; UPDATE salesflow.accounts SET enabled=false;" | Out-Null
RenewalQuery $sql -ExpectFailure
Write-Host 'PASS renewal database changed scope, actor, role, and disabled account rejected'
