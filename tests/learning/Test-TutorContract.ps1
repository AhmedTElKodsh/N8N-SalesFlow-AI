. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$contract = Join-Path $root 'learning/tutor-contract.md'
$agents = Join-Path $root 'AGENTS.md'

Assert-True (Test-Path -LiteralPath $contract) 'canonical tutor contract exists'
Assert-True (Test-Path -LiteralPath $agents) 'root AI instructions exist'
$text = Get-Content -Raw -LiteralPath $contract
foreach ($heading in @(
  '## Session start',
  '## Just-in-time teaching limits',
  '## Hint ladder',
  '## Direct-solution mode',
  '## Completion gates',
  '## Failure classification',
  '## Session resume'
)) { Assert-Match $text ([regex]::Escape($heading)) "contract contains $heading" }

$milestones = @(
  @{ Id = 'M00'; Name = 'Repository orientation'; Capability = 'synthetic-local versus production boundary' }
  @{ Id = 'M01'; Name = 'Smallest local stack'; Capability = 'Start PostgreSQL and n8n safely' }
  @{ Id = 'M02'; Name = 'First vertical slice'; Capability = 'webhook-to-database-to-typed-response path' }
  @{ Id = 'M03'; Name = 'Durable identity'; Capability = 'accounts, contacts, conversations, inbound messages, and migrations' }
  @{ Id = 'M04'; Name = 'Safe repetition'; Capability = 'replay, conflict, ordering, and concurrent messages' }
  @{ Id = 'M05'; Name = 'Governed intelligence'; Capability = 'typed Product Knowledge, Sales Policy, model, qualification, provenance' }
  @{ Id = 'M06'; Name = 'Authorized side effects'; Capability = 'consent, persisted outbound intent, claim, immediate authorization recheck' }
  @{ Id = 'M07'; Name = 'Recovery and reconciliation'; Capability = 'bounded retry, backoff, provider callbacks, monotonic status' }
  @{ Id = 'M08'; Name = 'Time and human ownership'; Capability = 'UTC Follow-Ups, service windows, templates, opt-out precedence' }
  @{ Id = 'M09'; Name = 'Responsible operations'; Capability = 'correlation and evidence, deletion and minimization' }
  @{ Id = 'M10'; Name = 'Capstone'; Capability = 'complete suite' }
)
$previousIndex = -1
foreach ($milestone in $milestones) {
  $milestonePattern = '(?m)^- \*\*' + [regex]::Escape($milestone.Id) + '.*' + [regex]::Escape($milestone.Name) + ':\*\* .+$'
  $match = [regex]::Match($text, $milestonePattern)
  Assert-True $match.Success "contract contains approved $($milestone.Id) name"
  Assert-True ($match.Index -gt $previousIndex) "contract keeps $($milestone.Id) in approved order"
  Assert-Match $match.Value ([regex]::Escape($milestone.Capability)) "contract contains $($milestone.Id) capability"
  if ($match.Success) { $previousIndex = $match.Index }
}

Assert-Match $text 'explicit learner request' 'direct solution requires explicit request'
Assert-Match (Get-Content -Raw -LiteralPath $agents) 'learning/tutor-contract\.md' 'AGENTS points to canonical contract'
Complete-TestFile
