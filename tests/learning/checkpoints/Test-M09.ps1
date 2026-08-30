param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  $sqlLocation = 'database/001-initial.sql'
  $sql = Read-CheckpointSql $root $sqlLocation
  $runtime = Read-CheckpointText $root 'tests/runtime.sql'
  $operations = Get-SqlFunctionBlock $sql 'operations' $sqlLocation

  Assert-CheckpointInvariant ($sql -match '(?i)CREATE\s+TRIGGER\s+audit_immutable\s+BEFORE\s+UPDATE\s+OR\s+DELETE\s+ON\s+audit_events' -and $sql -match "RAISE EXCEPTION'append-only'") 'Behavioral checkpoint failure' 'audit evidence is append-only' 'audit-immutability-trigger-missing' $sqlLocation
  Assert-CheckpointInvariant ($sql -match "jsonb_build_object\('inbound_id'" -and $sql -match "jsonb_build_object\('intent_id'" -and $sql -match "'manifest_hash'") 'Behavioral checkpoint failure' 'audit facts carry PII-minimized correlation identifiers' 'correlated-audit-details-missing' $sqlLocation
  Assert-CheckpointInvariant ($operations -match "action'='delete'" -and $operations -match "body='\[deleted\]'" -and $operations -match "provenance='\{\}'" -and $operations -match "deletion_targets\s+SET\s+state='completed'") 'Behavioral checkpoint failure' 'deletion minimizes content and records completed target evidence' 'deletion-minimization-path-missing' "$sqlLocation operations"

  $retention = Read-CheckpointJson $root 'config/retention.json'
  Assert-CheckpointInvariant ($retention.kind -eq 'retention' -and [int]$retention.auditDays -gt 0 -and [int]$retention.messageDays -gt 0 -and [int]$retention.messageDays -le [int]$retention.auditDays) 'Behavioral checkpoint failure' 'retention configuration declares a valid message-within-audit boundary' ($retention | ConvertTo-Json -Compress) 'config/retention.json'
  Assert-CheckpointInvariant ($operations -match "retentionVersion" -and $operations -match "auditDays" -and $operations -match "messageDays") 'Behavioral checkpoint failure' 'operations reports retention configuration as evidence' 'retention-evidence-fields-missing' "$sqlLocation operations"
  $retentionFunctionName = @('enforce_retention', 'purge_expired') | Where-Object { $sql -match ('(?i)CREATE\s+OR\s+REPLACE\s+FUNCTION\s+' + [regex]::Escape($_) + '\b') } | Select-Object -First 1
  Assert-CheckpointInvariant (-not [string]::IsNullOrWhiteSpace($retentionFunctionName)) 'Behavioral checkpoint failure' 'retention has executable age-based purge behavior' 'enforced-retention-function-not-found' $sqlLocation
  $retentionFunction = Get-SqlFunctionBlock $sql $retentionFunctionName $sqlLocation
  Assert-CheckpointInvariant ($retentionFunction -match '(?i)DELETE\s+FROM|UPDATE\s+inbound_messages' -and $retentionFunction -match '(?i)messageDays|auditDays' -and $retentionFunction -match '(?i)now\(\)|CURRENT_TIMESTAMP' -and $retentionFunction -match '(?i)account_ref' -and $retentionFunction -match '(?i)RETURN|jsonb_build_object') 'Behavioral checkpoint failure' 'retention scopes configured age duties to an account and returns observable purge evidence' 'age-cutoff-account-scope-or-result-not-found' "$sqlLocation $retentionFunctionName"

  $manifest = Read-CheckpointJson $root 'release/release-manifest.json'
  $releaseSet = Read-CheckpointJson $root 'config/release-set.json'
  Assert-CheckpointInvariant ($manifest.livePromotionAllowed -eq $false) 'Behavioral checkpoint failure' 'release manifest keeps livePromotionAllowed false' $manifest.livePromotionAllowed 'release/release-manifest.json'
  foreach ($identity in @($releaseSet.reviewedManifestHash, $releaseSet.policyVersion, $releaseSet.knowledgeVersion, $releaseSet.manifestVersion, $manifest.activationManifestSha256, $manifest.activationManifest.policyVersion, $manifest.activationManifest.knowledgeVersion, $manifest.activationManifest.version)) {
    Assert-CheckpointInvariant (-not [string]::IsNullOrWhiteSpace([string]$identity)) 'Behavioral checkpoint failure' 'release identity fields are nonblank before comparison' 'blank-release-identity' 'config/release-set.json and release/release-manifest.json'
  }
  Assert-CheckpointInvariant ($releaseSet.reviewedManifestHash -eq $manifest.activationManifestSha256 -and $releaseSet.policyVersion -eq $manifest.activationManifest.policyVersion -and $releaseSet.knowledgeVersion -eq $manifest.activationManifest.knowledgeVersion -and $releaseSet.manifestVersion -eq $manifest.activationManifest.version) 'Behavioral checkpoint failure' 'release set is bound to reviewed manifest, policy, and knowledge identities' 'release-binding-mismatch' 'config/release-set.json'
  Assert-CheckpointInvariant ($operations -match "previous_release" -and $operations -match "release_pointers" -and $operations -match "release_activated") 'Behavioral checkpoint failure' 'release activation preserves previous release identity for rollback behavior' 'rollback-evidence-path-missing' "$sqlLocation operations"

  Assert-CheckpointInvariant ($runtime -match "INSERT INTO evidence VALUES\('S21'\)" -and $runtime -match "INSERT INTO evidence VALUES\('S22'\)" -and $runtime -match "INSERT INTO evidence VALUES\('S26'\)" -and $runtime -match "retentionVersion'='retention-v1'") 'Behavioral checkpoint failure' 'runtime tests assert deletion, immutability, retention reporting, and release rollback' 'S21-S22-S26-retention-evidence-not-found' 'tests/runtime.sql'
  Assert-CheckpointInvariant ($runtime -match '(?i)interval.*messageDays|messageDays.*interval' -and $runtime -match '(?i)ASSERT\s+NOT\s+EXISTS' -and $runtime -match '(?i)purge|enforce_retention') 'Behavioral checkpoint failure' 'runtime tests age a synthetic record, execute retention, and prove its removal' 'enforced-retention-runtime-proof-not-found' 'tests/runtime.sql'

  $harness = Read-CheckpointText $root 'tests/run.ps1'
  $gitignore = Read-CheckpointText $root '.gitignore'
  Assert-CheckpointInvariant ($gitignore -match '(?m)^\.env(?:\.\*)?\s*$' -and $harness -match 'export secret scan') 'Behavioral checkpoint failure' 'sensitive runtime values stay ignored and exported workflows are scanned' 'secret-boundary-proof-not-found' '.gitignore and tests/run.ps1'
  Assert-CheckpointInvariant ($operations -match "'activeRelease'" -and $runtime -match "activeRelease'='r2'") 'Behavioral checkpoint failure' 'operations evidence identifies the active release after rollback selection' 'active-release-runtime-proof-not-found' 'database/001-initial.sql and tests/runtime.sql'

  $operationsWorkflow = Read-CheckpointJson $root 'workflows/07-error-and-operations.json'
  $alertNodes = @($operationsWorkflow.nodes | Where-Object { [string]$_.name -match '(?i)alert' -or [string]$_.parameters.query -match '(?i)alert' })
  Assert-CheckpointInvariant ($alertNodes.Count -gt 0 -and $runtime -match '(?i)alert.*condition' -and $runtime -match '(?i)alert.*owner') 'Behavioral checkpoint failure' 'an actionable operational alert has executable condition, evidence location, and owner response proof' 'actionable-alert-proof-not-found' 'workflows/07-error-and-operations.json and tests/runtime.sql'

  $context = Read-CheckpointText $root 'docs/project-context.md'
  $readme = Read-CheckpointText $root 'README.md'
  $lesson = Read-CheckpointText $root 'learning/milestones/M09-responsible-operations/lesson.md'
  foreach ($productionGate in @('Real Meta delivery', 'production LLM', 'CRM/Handoff contract', 'managed PostgreSQL controls', 'legal/privacy approval', 'production owner')) {
    Assert-CheckpointInvariant ($context -match [regex]::Escape($productionGate)) 'Behavioral checkpoint failure' "production gate is documented: $productionGate" "production-gate-not-found:$productionGate" 'docs/project-context.md'
  }
  Assert-CheckpointInvariant ($readme -match '(?i)None of those external gates is represented as passed by the local suite') 'Behavioral checkpoint failure' 'documentation does not claim local evidence passes production gates' 'external-gate-boundary-not-found' 'README.md'
  Assert-CheckpointInvariant ($lesson -match '(?i)Every alert has a condition, evidence location, and expected owner response') 'Behavioral checkpoint failure' 'operational alert requirements are documented and assertable' 'operational-alert-requirement-not-found' 'learning/milestones/M09-responsible-operations/lesson.md'

  Write-LearningEvidence @('correlated-audit-evidence', 'deletion-minimization-enforced-retention', 'secret-release-rollback-alerts')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
