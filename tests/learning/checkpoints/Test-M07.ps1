param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  $retry = Read-CheckpointJson $root 'config/retry.json'
  Assert-CheckpointInvariant ($retry.kind -eq 'retry' -and [int]$retry.maxAttempts -gt 0 -and [int]$retry.backoffSeconds -gt 0 -and [int]$retry.leaseSeconds -gt 0 -and [int]$retry.turnClaimSeconds -gt 0 -and [int]$retry.followupClaimSeconds -gt 0) 'Behavioral checkpoint failure' 'retry config declares a bounded budget, backoff, and claim durations' ($retry | ConvertTo-Json -Compress) 'config/retry.json'

  $sqlLocation = 'database/001-initial.sql'
  $sql = Read-CheckpointSql $root $sqlLocation
  $completeTurn = Get-SqlFunctionBlock $sql 'complete_turn' $sqlLocation
  $claim = Get-SqlFunctionBlock $sql 'claim_dispatch' $sqlLocation
  $finish = Get-SqlFunctionBlock $sql 'finish_dispatch' $sqlLocation
  $callback = Get-SqlFunctionBlock $sql 'callback' $sqlLocation
  $providerEvents = Get-SqlCreateTableBlock $sql 'provider_events' $sqlLocation
  Assert-CheckpointInvariant ($completeTurn -match '(?i)claim_until\s*<=\s*now\(\)' -and $completeTurn -match "retry_exhausted") 'Behavioral checkpoint failure' 'turn recovery handles expired claims and bounded retry exhaustion' 'turn-expiry-or-budget-missing' "$sqlLocation complete_turn"
  Assert-CheckpointInvariant ($claim -match "(?i)state\s*=\s*'leased'.*lease_until\s*>\s*n" -and $claim -match "backoff" -and $claim -match "retry_exhausted") 'Behavioral checkpoint failure' 'dispatch claim recovers expired leases while respecting backoff and retry budget' 'dispatch-recovery-policy-missing' "$sqlLocation claim_dispatch"
  Assert-CheckpointInvariant ($finish -match "outcome='ambiguous'" -and $finish -match "reconciliation_required" -and $finish -match "backoffSeconds") 'Behavioral checkpoint failure' 'finish records ambiguous outcomes and schedules bounded backoff' 'ambiguous-or-backoff-outcome-missing' "$sqlLocation finish_dispatch"
  Assert-CheckpointInvariant ($providerEvents -match '(?i)PRIMARY\s+KEY\s*\(account_ref\s*,\s*event_id\)' -and $callback -match 'provider_events' -and $callback -match "idempotency_conflict" -and $callback -match "array_position" -and $callback -match "rank_new") 'Behavioral checkpoint failure' 'callback is idempotent and applies monotonic provider status ranking' 'callback-idempotency-or-monotonic-rule-missing' "$sqlLocation callback"

  $runtime = Read-CheckpointText $root 'tests/runtime.sql'
  foreach ($marker in @('S15', 'S16', 'S24', 'S25')) {
    Assert-CheckpointInvariant ($runtime -match ("INSERT INTO evidence VALUES\('" + $marker + "'\)")) 'Behavioral checkpoint failure' "runtime tests include $marker recovery evidence" "marker-not-found:$marker" 'tests/runtime.sql'
  }
  $callbackEvidence = [regex]::Match($runtime, "(?m)^r:=callback.*INSERT INTO evidence VALUES\('S16'\);").Value
  $deliveredAssertions = [regex]::Matches($callbackEvidence, "status'='delivered'").Count
  Assert-CheckpointInvariant ($runtime -match "terminal'='reconciliation_required'" -and $callbackEvidence -match "status','sent'" -and $callbackEvidence -match "status','failed'" -and $deliveredAssertions -ge 3) 'Behavioral checkpoint failure' 'runtime tests assert ambiguous reconciliation and monotonic callback status' 'reconciliation-or-monotonic-assertion-missing' 'tests/runtime.sql'
  $harness = Read-CheckpointText $root 'tests/run.ps1'
  Assert-CheckpointInvariant ($harness -match 'parallel callback one event' -and $harness -match 'recovers expired outbound and Handoff claims') 'Behavioral checkpoint failure' 'concurrent callback idempotency and expired-claim recovery have harness evidence' 'callback-or-expired-claim-harness-evidence-missing' 'tests/run.ps1'

  Write-LearningEvidence @('bounded-retry-backoff', 'monotonic-provider-callback', 'expired-claim-ambiguous-reconciliation')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
