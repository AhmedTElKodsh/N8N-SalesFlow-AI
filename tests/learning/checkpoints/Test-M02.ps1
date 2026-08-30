param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  $location = 'workflows/01-whatsapp-ingress.json'
  $workflow = Read-CheckpointJson $root $location

  $webhooks = @(Get-WorkflowNodesByType $workflow 'n8n-nodes-base.webhook')
  $postgresNodes = @(Get-WorkflowNodesByType $workflow 'n8n-nodes-base.postgres')
  $conditionals = @(Get-WorkflowNodesByType $workflow 'n8n-nodes-base.if')
  $terminals = @(Get-WorkflowNodesByType $workflow 'n8n-nodes-base.noOp' | Where-Object { $_.name -match '(?i)typed terminal' })
  $orchestrators = @(Get-WorkflowNodesByType $workflow 'n8n-nodes-base.executeWorkflow')
  Assert-CheckpointInvariant ($webhooks.Count -eq 1 -and $postgresNodes.Count -eq 1 -and $conditionals.Count -ge 1 -and $terminals.Count -eq 1 -and $orchestrators.Count -eq 1) 'Behavioral checkpoint failure' 'workflow 01 has one webhook, ingest query, conditional, typed terminal, and orchestrator handoff' "counts=webhook:$($webhooks.Count),postgres:$($postgresNodes.Count),if:$($conditionals.Count),terminal:$($terminals.Count),orchestrator:$($orchestrators.Count)" $location

  $webhook = $webhooks[0]
  $postgres = $postgresNodes[0]
  $conditional = $conditionals[0]
  $terminal = $terminals[0]
  $orchestrator = $orchestrators[0]
  Assert-WorkflowPath $workflow $webhook.name $postgres.name $location
  Assert-WorkflowPath $workflow $postgres.name $conditional.name $location
  Assert-WorkflowPath $workflow $conditional.name $terminal.name $location
  Assert-WorkflowPath $workflow $conditional.name $orchestrator.name $location
  $acceptedTargets = @(Get-WorkflowBranchTargetNames $workflow $conditional.name 0)
  $rejectedTargets = @(Get-WorkflowBranchTargetNames $workflow $conditional.name 1)
  Assert-CheckpointInvariant ($acceptedTargets -contains $orchestrator.name -and $acceptedTargets -notcontains $terminal.name -and $rejectedTargets -contains $terminal.name -and $rejectedTargets -notcontains $orchestrator.name) 'Behavioral checkpoint failure' 'accepted and rejected conditional branches route exclusively to orchestrator and typed terminal' ("accepted=$($acceptedTargets -join ',');rejected=$($rejectedTargets -join ',')") $location
  $reachable = @(Get-WorkflowReachableNodeNames $workflow $webhook.name)
  Assert-CheckpointInvariant ($reachable -contains $terminal.name -and $reachable -contains $orchestrator.name) 'Behavioral checkpoint failure' 'parsed workflow connections carry inbound data to both conditional terminals' ("reachable=" + ($reachable -join ',')) $location

  $query = [string]$postgres.parameters.query
  $queryReplacement = [string]$postgres.parameters.options.queryReplacement
  Assert-CheckpointInvariant ($query -match '(?i)salesflow\.ingest\s*\(' -and $query -match '\$1' -and $query -match '\$2') 'Behavioral checkpoint failure' 'ingest SQL uses positional replacement parameters' $query "$location postgres.query"
  Assert-CheckpointInvariant (-not [string]::IsNullOrWhiteSpace($queryReplacement) -and $queryReplacement -match '(?i)JSON\.stringify\(\$json\.body') 'Behavioral checkpoint failure' 'request body is bound through queryReplacement' $queryReplacement "$location postgres.options.queryReplacement"
  Assert-CheckpointInvariant (-not ($query -match '(?i)\$json|\.body')) 'Behavioral checkpoint failure' 'SQL text does not interpolate request body expressions' $query "$location postgres.query"

  $sqlLocation = 'database/001-initial.sql'
  $sql = Read-CheckpointSql $root $sqlLocation
  $ingest = Get-SqlFunctionBlock $sql 'ingest' $sqlLocation
  Assert-CheckpointInvariant ($ingest -match '(?i)INSERT\s+INTO\s+inbound_messages' -and $ingest -match '(?i)RETURNING\s*\*\s*INTO\s+m') 'Behavioral checkpoint failure' 'the ingest function performs the durable write inside its function transaction' 'atomic-inbound-write-not-found' "$sqlLocation ingest"
  Assert-CheckpointInvariant ($ingest -match "'accepted'\s*,\s*true" -and $ingest -match "'eventId'\s*,\s*m\.id::text") 'Behavioral checkpoint failure' 'the committed accepted path returns accepted Boolean true and eventId string' 'accepted-boolean-or-eventId-string-not-found' "$sqlLocation ingest"
  Assert-CheckpointInvariant ($ingest -match "'accepted'\s*,\s*false") 'Behavioral checkpoint failure' 'rejected ingest paths return accepted Boolean false' 'typed-rejection-not-found' "$sqlLocation ingest"

  $runtime = Read-CheckpointText $root 'tests/runtime.sql'
  Assert-CheckpointInvariant ($runtime -match "jsonb_typeof\(r->'accepted'\)='boolean'" -and $runtime -match "jsonb_typeof\(r->'eventId'\)='string'" -and $runtime -match "length\(r->>'eventId'\)>0") 'Behavioral checkpoint failure' 'focused runtime evidence proves accepted and eventId JSON types and nonempty accepted eventId' 'typed-terminal-runtime-assertion-not-found' 'tests/runtime.sql'

  Write-LearningEvidence @('webhook-path', 'parameterized-query', 'typed-terminal')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
