param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  $schedulerLocation = 'workflows/05-follow-up-scheduler.json'
  $handoffLocation = 'workflows/06-handoff-dispatcher.json'
  $scheduler = Read-CheckpointJson $root $schedulerLocation
  $handoff = Read-CheckpointJson $root $handoffLocation

  $utcSchedule = @(Get-WorkflowNodesByType $scheduler 'n8n-nodes-base.scheduleTrigger')[0]
  $workQuery = @($scheduler.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.postgres' -and [string]$_.parameters.query -match '(?i)schedule_work' })[0]
  $outboundRoute = @($scheduler.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.executeWorkflow' -and [string]$_.parameters.workflowId.value -eq 'salesflow-wf-03' })[0]
  $handoffRoute = @($scheduler.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.executeWorkflow' -and [string]$_.parameters.workflowId.value -eq 'salesflow-wf-06' })[0]
  Assert-CheckpointInvariant ($null -ne $utcSchedule -and $null -ne $workQuery -and $null -ne $outboundRoute -and $null -ne $handoffRoute) 'Behavioral checkpoint failure' 'UTC scheduler has durable work discovery and outbound/Handoff routes' 'scheduler-stage-missing' $schedulerLocation
  Assert-CheckpointInvariant ([string]$scheduler.settings.timezone -eq 'UTC') 'Behavioral checkpoint failure' 'n8n scheduler explicitly executes in UTC' $scheduler.settings.timezone "$schedulerLocation settings.timezone"
  Assert-WorkflowPath $scheduler $utcSchedule.name $workQuery.name $schedulerLocation
  Assert-WorkflowPath $scheduler $workQuery.name $outboundRoute.name $schedulerLocation
  Assert-WorkflowPath $scheduler $workQuery.name $handoffRoute.name $schedulerLocation
  $scheduledReachable = @(Get-WorkflowReachableNodeNames $scheduler $utcSchedule.name)
  Assert-CheckpointInvariant ($scheduledReachable -contains $outboundRoute.name -and $scheduledReachable -contains $handoffRoute.name) 'Behavioral checkpoint failure' 'parsed UTC schedule dataflow reaches outbound and Handoff dispatch' ("reachable=" + ($scheduledReachable -join ',')) $schedulerLocation
  $dispatchDecision = @($scheduler.nodes | Where-Object { [string]$_.name -eq 'Dispatch Work' })[0]
  $handoffDecision = @($scheduler.nodes | Where-Object { [string]$_.name -eq 'Handoff Work' })[0]
  $dispatchTrue = @(Get-WorkflowBranchTargetNames $scheduler $dispatchDecision.name 0)
  $dispatchFalse = @(Get-WorkflowBranchTargetNames $scheduler $dispatchDecision.name 1)
  $handoffTrue = @(Get-WorkflowBranchTargetNames $scheduler $handoffDecision.name 0)
  Assert-CheckpointInvariant ($dispatchTrue -contains $outboundRoute.name -and $dispatchTrue -notcontains $handoffRoute.name -and $dispatchFalse -contains $handoffDecision.name -and $handoffTrue -contains $handoffRoute.name -and $handoffTrue -notcontains $outboundRoute.name) 'Behavioral checkpoint failure' 'scheduler branches dispatch and Handoff work by exclusive workflow identity routes' 'scheduler-exclusive-routing-not-found' $schedulerLocation

  $handoffClaim = @($handoff.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.postgres' -and [string]$_.parameters.query -match '(?i)claim_handoff' })[0]
  $handoffFinish = @($handoff.nodes | Where-Object { [string]$_.type -eq 'n8n-nodes-base.postgres' -and [string]$_.parameters.query -match '(?i)finish_handoff' })[0]
  Assert-CheckpointInvariant ($null -ne $handoffClaim -and $null -ne $handoffFinish) 'Behavioral checkpoint failure' 'Handoff workflow has claim and finish boundaries' 'handoff-claim-or-finish-missing' $handoffLocation
  Assert-WorkflowPath $handoff $handoffClaim.name $handoffFinish.name $handoffLocation

  $sqlLocation = 'database/001-initial.sql'
  $sql = Read-CheckpointSql $root $sqlLocation
  $ingest = Get-SqlFunctionBlock $sql 'ingest' $sqlLocation
  $completeTurn = Get-SqlFunctionBlock $sql 'complete_turn' $sqlLocation
  $authorization = Get-SqlFunctionBlock $sql 'authorization_reason' $sqlLocation
  $scheduleWork = Get-SqlFunctionBlock $sql 'schedule_work' $sqlLocation
  Assert-CheckpointInvariant ($ingest -match "optOutSignals" -and $ingest -match "reason='opted_out'" -and $ingest -match "(?i)UPDATE\s+intents\s+SET\s+state='suppressed'" -and $ingest -match "(?i)UPDATE\s+followups\s+SET\s+state='suppressed'") 'Behavioral checkpoint failure' 'opt-out suppresses pending outbound and Follow-Up work' 'opt-out-suppression-path-missing' "$sqlLocation ingest"
  Assert-CheckpointInvariant ($completeTurn -match "owner='human'" -and $completeTurn -match "human_owned" -and $authorization -match "v.owner<>'ai'") 'Behavioral checkpoint failure' 'Human-Owned state blocks automated turn and dispatch authorization' 'Human-Owned-lockout-missing' $sqlLocation
  Assert-CheckpointInvariant ($authorization -match 'serviceWindowHours' -and $authorization -match 'service_window_closed' -and $authorization -match 'template_window_closed' -and $authorization -match "AT TIME ZONE'UTC'" -and $authorization -match 'quietHoursUtc') 'Behavioral checkpoint failure' 'authorization enforces service/template windows and quiet hours in UTC immediately before dispatch' 'UTC-service-window-or-template-rule-missing' "$sqlLocation authorization_reason"
  Assert-CheckpointInvariant ($scheduleWork -match "salesflow-wf-03" -and $scheduleWork -match "salesflow-wf-06" -and $scheduleWork -match '(?i)claim_until\s*<=\s*n') 'Behavioral checkpoint failure' 'durable scheduler routes outbound/Handoff and recovers expired claims' 'schedule-routing-or-recovery-missing' "$sqlLocation schedule_work"

  $runtime = Read-CheckpointText $root 'tests/runtime.sql'
  $harness = Read-CheckpointText $root 'tests/run.ps1'
  Assert-CheckpointInvariant ($runtime -match "INSERT INTO evidence VALUES\('S06'\)" -and $runtime -match "INSERT INTO evidence VALUES\('S08'\)") 'Behavioral checkpoint failure' 'runtime tests assert opt-out suppression and Human-Owned Handoff' 'S06-or-S08-evidence-not-found' 'tests/runtime.sql'
  Assert-CheckpointInvariant ($runtime -match "service_window_closed" -and $runtime -match "template_window_closed" -and $runtime -match "quiet_hours") 'Behavioral checkpoint failure' 'runtime tests prove UTC service-window, template-window, and quiet-hours denials' 'service-window-runtime-evidence-not-found' 'tests/runtime.sql'
  Assert-CheckpointInvariant ($harness -match 'native UTC schedule recovers expired outbound and Handoff claims') 'Behavioral checkpoint failure' 'full harness asserts UTC scheduler recovery' 'UTC-recovery-assertion-not-found' 'tests/run.ps1'

  Write-LearningEvidence @('utc-service-window-follow-ups', 'opt-out-human-owned-lockout', 'handoff-and-scheduler-recovery')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
