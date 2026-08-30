param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  $orchestratorLocation = 'workflows/02-conversation-orchestrator.json'
  $dispatcherLocation = 'workflows/03-outbox-dispatcher.json'
  $orchestrator = Read-CheckpointJson $root $orchestratorLocation
  $dispatcher = Read-CheckpointJson $root $dispatcherLocation

  $completeNode = @($orchestrator.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.postgres' -and [string]$_.parameters.query -match '(?i)complete_turn' })[0]
  $dispatchNode = @($orchestrator.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.executeWorkflow' -and [string]$_.parameters.workflowId.value -eq 'salesflow-wf-03' })[0]
  Assert-CheckpointInvariant ($null -ne $completeNode -and $null -ne $dispatchNode) 'Behavioral checkpoint failure' 'orchestrator has durable turn completion before dispatch workflow' 'turn-or-dispatch-node-missing' $orchestratorLocation
  Assert-WorkflowPath $orchestrator $completeNode.name $dispatchNode.name $orchestratorLocation

  $claimNode = @($dispatcher.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.postgres' -and [string]$_.parameters.query -match '(?i)claim_dispatch' })[0]
  $recheckNode = @($dispatcher.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.postgres' -and [string]$_.parameters.query -match '(?i)recheck_dispatch' })[0]
  $finishNode = @($dispatcher.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.postgres' -and [string]$_.parameters.query -match '(?i)finish_dispatch' })[0]
  $adapterNode = @($dispatcher.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.set' })[0]
  $denialNode = @($dispatcher.nodes | Where-Object { [string]$_.name -match '(?i)denial' })[0]
  Assert-CheckpointInvariant ($null -ne $claimNode -and $null -ne $recheckNode -and $null -ne $adapterNode -and $null -ne $finishNode -and $null -ne $denialNode) 'Behavioral checkpoint failure' 'dispatcher contains claim, recheck, adapter, finish, and final denial nodes' 'dispatcher-stage-missing' $dispatcherLocation
  Assert-WorkflowPath $dispatcher $claimNode.name $recheckNode.name $dispatcherLocation
  Assert-WorkflowPath $dispatcher $recheckNode.name $adapterNode.name $dispatcherLocation
  Assert-WorkflowPath $dispatcher $adapterNode.name $finishNode.name $dispatcherLocation
  $claimDecision = @($dispatcher.nodes | Where-Object { [string]$_.name -eq 'Claimed' })[0]
  $authorizationDecision = @($dispatcher.nodes | Where-Object { [string]$_.name -eq 'Still Authorized' })[0]
  $claimTrue = @(Get-WorkflowBranchTargetNames $dispatcher $claimDecision.name 0)
  $claimFalse = @(Get-WorkflowBranchTargetNames $dispatcher $claimDecision.name 1)
  $authorizationTrue = @(Get-WorkflowBranchTargetNames $dispatcher $authorizationDecision.name 0)
  $authorizationFalse = @(Get-WorkflowBranchTargetNames $dispatcher $authorizationDecision.name 1)
  Assert-CheckpointInvariant ($claimTrue -contains $recheckNode.name -and $claimFalse -contains $denialNode.name -and $claimTrue -notcontains $adapterNode.name -and $claimFalse -notcontains $adapterNode.name) 'Behavioral checkpoint failure' 'claim decision routes success to immediate recheck and denial away from adapter' 'claim-branch-bypass-detected' $dispatcherLocation
  Assert-CheckpointInvariant ($authorizationTrue -contains $adapterNode.name -and $authorizationFalse -contains $denialNode.name -and $authorizationFalse -notcontains $adapterNode.name) 'Behavioral checkpoint failure' 'recheck decision is the only branch that authorizes adapter execution' 'recheck-branch-bypass-detected' $dispatcherLocation
  $claimReachable = @(Get-WorkflowReachableNodeNames $dispatcher $claimNode.name)
  $recheckReachable = @(Get-WorkflowReachableNodeNames $dispatcher $recheckNode.name)
  Assert-CheckpointInvariant ($claimReachable -contains $denialNode.name -and $recheckReachable -contains $denialNode.name) 'Behavioral checkpoint failure' 'claim and immediate recheck both route final denial without adapter execution' "claim=$($claimReachable -join ',');recheck=$($recheckReachable -join ',')" $dispatcherLocation

  $sqlLocation = 'database/001-initial.sql'
  $sql = Read-CheckpointSql $root $sqlLocation
  $completeTurn = Get-SqlFunctionBlock $sql 'complete_turn' $sqlLocation
  $authorization = Get-SqlFunctionBlock $sql 'authorization_reason' $sqlLocation
  $claim = Get-SqlFunctionBlock $sql 'claim_dispatch' $sqlLocation
  $recheck = Get-SqlFunctionBlock $sql 'recheck_dispatch' $sqlLocation
  $finish = Get-SqlFunctionBlock $sql 'finish_dispatch' $sqlLocation
  Assert-CheckpointInvariant ($completeTurn -match '(?i)INSERT\s+INTO\s+intents') 'Behavioral checkpoint failure' 'turn completion persists an outbound intent before adapter dataflow begins' 'intent-persistence-not-found' "$sqlLocation complete_turn"
  Assert-CheckpointInvariant ($authorization -match "consent_missing" -and $authorization -match "human_owned" -and $authorization -match "stale_version") 'Behavioral checkpoint failure' 'authorization covers consent, ownership, and version denial paths' 'authorization-denial-path-missing' "$sqlLocation authorization_reason"
  Assert-CheckpointInvariant ($claim -match '(?i)authorization_reason' -and $recheck -match '(?i)authorization_reason' -and $finish -match '(?i)authorization_reason') 'Behavioral checkpoint failure' 'claim, recheck, and finish all apply authorization' 'authorization-call-missing' $sqlLocation
  Assert-CheckpointInvariant ($finish -match "provider_id='synthetic-'\|\|id" -and $finish -match "outcome='ambiguous'" -and $finish -match "reconciliation_required") 'Behavioral checkpoint failure' 'finish uses a durable intent-derived provider id and records ambiguous outcomes for reconciliation' 'idempotent-provider-key-or-ambiguity-path-missing' "$sqlLocation finish_dispatch"

  $runtime = Read-CheckpointText $root 'tests/runtime.sql'
  Assert-CheckpointInvariant ($runtime -match "reason'='consent_missing'.*INSERT INTO evidence VALUES\('S18'\)" -and $runtime -match "event='authorization_denied'.*details->>'phase'='recheck'") 'Behavioral checkpoint failure' 'runtime tests prove consent denial and final recheck denial evidence' 'consent-or-recheck-evidence-not-found' 'tests/runtime.sql'
  Assert-CheckpointInvariant ($runtime -match "finish_dispatch.*'ambiguous'.*terminal'='reconciliation_required'.*INSERT INTO evidence VALUES\('S15'\)" -and $runtime -match "finish_dispatch.*'success'.*terminal'='sent'") 'Behavioral checkpoint failure' 'runtime tests prove ambiguous finish and deterministic successful finish outcomes' 'finish-ambiguity-or-success-evidence-not-found' 'tests/runtime.sql'

  Write-LearningEvidence @('consent-gated-persisted-intent', 'claimed-rechecked-dispatch', 'idempotent-finish-and-ambiguity')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
