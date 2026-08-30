param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  $configDirectory = Resolve-CheckpointPath $root 'config' 'Container'
  $configFiles = @(Get-ChildItem -LiteralPath $configDirectory -Filter '*.json' -File | Sort-Object Name)
  Assert-CheckpointInvariant ($configFiles.Count -gt 0) 'Syntax or integration failure' 'typed configuration directory contains JSON contracts' 'no-json-config-files' 'config'
  foreach ($configFile in $configFiles) {
    $relativePath = 'config/' + $configFile.Name
    $typedConfig = Read-CheckpointJson $root $relativePath
    Assert-CheckpointInvariant ($null -ne $typedConfig.PSObject.Properties['accountRef'] -and -not [string]::IsNullOrWhiteSpace([string]$typedConfig.accountRef) -and $null -ne $typedConfig.PSObject.Properties['version'] -and -not [string]::IsNullOrWhiteSpace([string]$typedConfig.version)) 'Behavioral checkpoint failure' 'every typed config identifies its account and version' "missing-account-or-version:$($configFile.Name)" $relativePath
  }

  $knowledge = Read-CheckpointJson $root 'config/product-knowledge.json'
  $policy = Read-CheckpointJson $root 'config/sales-policy.json'
  $model = Read-CheckpointJson $root 'config/model.json'
  $qualification = Read-CheckpointJson $root 'config/qualification.json'

  Assert-CheckpointInvariant ($knowledge.kind -eq 'product_knowledge' -and @($knowledge.sources).Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$knowledge.sources[0].id) -and @($knowledge.sources[0].claims).Count -gt 0) 'Behavioral checkpoint failure' 'Product Knowledge is a typed source and claims contract' ($knowledge | ConvertTo-Json -Compress -Depth 10) 'config/product-knowledge.json'
  Assert-CheckpointInvariant ($policy.kind -eq 'sales_policy' -and @($policy.allowedOffers).Count -gt 0 -and @($policy.allowedClaims).Count -gt 0 -and [decimal]$policy.minimumConfidence -ge 0 -and [decimal]$policy.minimumConfidence -le 1) 'Behavioral checkpoint failure' 'Sales Policy types offers, claims, and confidence' ($policy | ConvertTo-Json -Compress -Depth 10) 'config/sales-policy.json'
  Assert-CheckpointInvariant ($model.kind -eq 'model' -and $model.selection -eq 'synthetic-local' -and $model.productionEnabled -eq $false -and @($model.allowedClaims).Count -gt 0) 'Behavioral checkpoint failure' 'model config is typed and explicitly synthetic-local' ($model | ConvertTo-Json -Compress -Depth 10) 'config/model.json'
  Assert-CheckpointInvariant ($qualification.kind -eq 'qualification' -and [int]$qualification.minimumScore -le [int]$qualification.handoffScore) 'Behavioral checkpoint failure' 'qualification config has an ordered handoff threshold' ($qualification | ConvertTo-Json -Compress -Depth 10) 'config/qualification.json'

  $sqlLocation = 'database/001-initial.sql'
  $sql = Read-CheckpointSql $root $sqlLocation
  $completeTurn = Get-SqlFunctionBlock $sql 'complete_turn' $sqlLocation
  foreach ($configKind in @('sales_policy', 'product_knowledge', 'model', 'qualification')) {
    Assert-CheckpointInvariant ($completeTurn -match ("kind='" + [regex]::Escape($configKind) + "'")) 'Behavioral checkpoint failure' "turn completion loads typed $configKind configuration" "config-load-not-found:$configKind" "$sqlLocation complete_turn"
  }
  foreach ($provenanceField in @('policy_version', 'knowledge_version', 'sourceIds', 'claims', 'confidence', 'qualificationVersion', 'qualificationScore')) {
    Assert-CheckpointInvariant ($completeTurn -match [regex]::Escape($provenanceField)) 'Behavioral checkpoint failure' "turn completion records $provenanceField provenance" "provenance-not-found:$provenanceField" "$sqlLocation complete_turn"
  }
  Assert-CheckpointInvariant ($completeTurn -match '(?i)NOT\s+grounded' -and $completeTurn -match '(?i)INSERT\s+INTO\s+handoffs' -and $completeTurn -match "owner='human'") 'Behavioral checkpoint failure' 'invalid grounding fails closed to Human-Owned Handoff' 'fail-closed-Handoff-path-not-found' "$sqlLocation complete_turn"

  $runtime = Read-CheckpointText $root 'tests/runtime.sql'
  Assert-CheckpointInvariant ($runtime -match "INSERT INTO evidence VALUES\('S11'\)" -and $runtime -match "INSERT INTO evidence VALUES\('S12'\)" -and $runtime -match "provenance->>'qualificationVersion'") 'Behavioral checkpoint failure' 'runtime tests prove grounded provenance and fail-closed Handoff' 'S11-S12-provenance-evidence-not-found' 'tests/runtime.sql'

  Write-LearningEvidence @('typed-knowledge-policy-model-qualification', 'validated-provenance', 'invalid-evidence-handoff')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
