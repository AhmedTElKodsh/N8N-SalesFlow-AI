param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  $sqlLocation = 'database/001-initial.sql'
  $sql = Read-CheckpointSql $root $sqlLocation
  $runtime = Read-CheckpointText $root 'tests/runtime.sql'
  $harness = Read-CheckpointText $root 'tests/run.ps1'

  $inbound = Get-SqlCreateTableBlock $sql 'inbound_messages' $sqlLocation
  $ingest = Get-SqlFunctionBlock $sql 'ingest' $sqlLocation
  Assert-CheckpointInvariant ($inbound -match '(?i)UNIQUE\s*\(account_ref\s*,\s*provider_id\)') 'Behavioral checkpoint failure' 'provider replay identity is unique within an account' $inbound "$sqlLocation inbound_messages.provider_id"
  Assert-CheckpointInvariant ($inbound -match '(?i)UNIQUE\s*\(account_ref\s*,\s*conversation_id\s*,\s*seq\)') 'Behavioral checkpoint failure' 'conversation_id, seq is unique within account scope' $inbound "$sqlLocation inbound_messages.seq"
  Assert-CheckpointInvariant ($ingest -match "idempotency_conflict" -and $ingest -match "terminal','duplicate") 'Behavioral checkpoint failure' 'ingest returns typed duplicate and idempotency_conflict outcomes' 'typed-replay-outcomes-missing' "$sqlLocation ingest"
  Assert-CheckpointInvariant ($ingest -match '(?i)pg_advisory_xact_lock' -and $ingest -match '(?i)last_seq\s*=\s*last_seq\s*\+\s*1') 'Behavioral checkpoint failure' 'ingest serializes monotonic conversation sequence allocation' 'serialization-or-increment-missing' "$sqlLocation ingest"
  Assert-CheckpointInvariant ($ingest -match '(?i)EXCEPTION\s+WHEN\s+unique_violation' -and $ingest -match "concurrent_replay") 'Behavioral checkpoint failure' 'concurrent replay has a deterministic exception outcome' 'concurrent-replay-handler-missing' "$sqlLocation ingest"

  Assert-CheckpointInvariant ($runtime -match "INSERT INTO evidence VALUES\('S04'\)" -and $runtime -match "INSERT INTO evidence VALUES\('S05'\)") 'Behavioral checkpoint failure' 'tests/runtime.sql asserts replay conflict and ordered sequence behavior' 'S04-or-S05-evidence-not-found' 'tests/runtime.sql'
  foreach ($concurrentAssertion in @('parallel replay one row', 'conflicting replay rejected', 'parallel sequence unique')) {
    Assert-CheckpointInvariant ($harness -match [regex]::Escape($concurrentAssertion)) 'Behavioral checkpoint failure' "concurrent harness asserts $concurrentAssertion" "assertion-not-found:$concurrentAssertion" 'tests/run.ps1'
  }

  Write-LearningEvidence @('ordered-inbound-events', 'exactly-one-durable-effect', 'deterministic-replay-or-conflict')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
