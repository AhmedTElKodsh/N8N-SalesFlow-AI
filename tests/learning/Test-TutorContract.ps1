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
Assert-Match $text 'explicit learner request' 'direct solution requires explicit request'
Assert-Match (Get-Content -Raw -LiteralPath $agents) 'learning/tutor-contract\.md' 'AGENTS points to canonical contract'
Complete-TestFile
