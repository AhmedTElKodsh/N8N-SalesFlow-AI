param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  $sqlLocation = 'database/001-initial.sql'
  $sql = Read-CheckpointSql $root $sqlLocation
  $runtime = Read-CheckpointText $root 'tests/runtime.sql'

  $accounts = Get-SqlCreateTableBlock $sql 'accounts' $sqlLocation
  $contacts = Get-SqlCreateTableBlock $sql 'contacts' $sqlLocation
  $conversations = Get-SqlCreateTableBlock $sql 'conversations' $sqlLocation
  $inboundMessages = Get-SqlCreateTableBlock $sql 'inbound_messages' $sqlLocation

  Assert-CheckpointInvariant ($accounts -match '(?i)\bid\s+text\s+PRIMARY\s+KEY') 'Behavioral checkpoint failure' 'accounts owns the account key' $accounts "$sqlLocation accounts"
  Assert-CheckpointInvariant ($contacts -match '(?i)account_ref\s+text\s+NOT\s+NULL\s+REFERENCES\s+accounts\s*\(id\)' -and $contacts -match '(?i)PRIMARY\s+KEY\s*\(account_ref\s*,\s*id\)' -and $contacts -match '(?i)UNIQUE\s*\(account_ref\s*,\s*external_ref\)') 'Behavioral checkpoint failure' 'contacts is owned and uniquely scoped by account' $contacts "$sqlLocation contacts"
  Assert-CheckpointInvariant ($conversations -match '(?i)PRIMARY\s+KEY\s*\(account_ref\s*,\s*id\)' -and $conversations -match '(?i)FOREIGN KEY\s*\(account_ref\s*,\s*contact_id\)\s*REFERENCES\s+contacts\s*\(account_ref\s*,\s*id\)') 'Behavioral checkpoint failure' 'conversations preserves the composite account/contact FOREIGN KEY boundary' $conversations "$sqlLocation conversations"
  Assert-CheckpointInvariant ($inboundMessages -match '(?i)PRIMARY\s+KEY\s*\(account_ref\s*,\s*id\)' -and $inboundMessages -match '(?i)FOREIGN KEY\s*\(account_ref\s*,\s*conversation_id\)\s*REFERENCES\s+conversations\s*\(account_ref\s*,\s*id\)') 'Behavioral checkpoint failure' 'inbound_messages preserves the composite account/conversation FOREIGN KEY boundary' $inboundMessages "$sqlLocation inbound_messages"
  Assert-CheckpointInvariant ($inboundMessages -match '(?i)body_hash\s+text\s+NOT\s+NULL' -and $inboundMessages -match '(?i)received_at\s+timestamptz\s+NOT\s+NULL') 'Behavioral checkpoint failure' 'inbound messages retain immutable content and receipt evidence fields' $inboundMessages "$sqlLocation inbound_messages"
  Assert-CheckpointInvariant ($sql -match '(?i)CREATE\s+TRIGGER\s+inbound_messages_immutable\s+BEFORE\s+UPDATE\s+OR\s+DELETE\s+ON\s+inbound_messages') 'Behavioral checkpoint failure' 'inbound evidence rejects ordinary update and delete operations' 'inbound-immutability-trigger-not-found' $sqlLocation
  Assert-CheckpointInvariant ($runtime -match "INSERT INTO evidence VALUES\('S01'\)" -and $runtime -match "reason'='wrong_account'.*INSERT INTO evidence VALUES\('S02'\)") 'Behavioral checkpoint failure' 'runtime tests exercise durable inbound creation and cross-account rejection' 'S01-or-S02-evidence-not-found' 'tests/runtime.sql'
  Assert-CheckpointInvariant ($runtime -match '(?is)BEGIN\s+UPDATE\s+inbound_messages.*EXCEPTION\s+WHEN.*INSERT INTO evidence') 'Behavioral checkpoint failure' 'runtime tests prove ordinary inbound evidence mutation is rejected' 'inbound-immutability-runtime-proof-not-found' 'tests/runtime.sql'

  Write-LearningEvidence @('composite-account-scope', 'foreign-key-records', 'immutable-inbound-evidence')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
