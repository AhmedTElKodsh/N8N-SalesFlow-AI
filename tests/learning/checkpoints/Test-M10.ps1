param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  $powershell = (Get-Command powershell.exe -ErrorAction Stop).Source

  foreach ($index in 0..9) {
    $milestone = 'M{0:d2}' -f $index
    $checkpoint = Resolve-CheckpointPath $root ("tests/learning/checkpoints/Test-M{0:d2}.ps1" -f $index)
    $preflight = Invoke-NativeCaptured $powershell @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $checkpoint, '-RepositoryRoot', $root) $root
    Assert-CheckpointInvariant ($preflight.ExitCode -eq 0) 'Behavioral checkpoint failure' "$milestone preflight exits zero" "exit=$($preflight.ExitCode);stderr=$($preflight.Stderr.Trim())" $checkpoint
    Assert-CheckpointInvariant ([string]::IsNullOrWhiteSpace($preflight.Stderr)) 'Curriculum or checkpoint defect' "$milestone preflight keeps stderr empty on success" $preflight.Stderr $checkpoint
    $lines = @($preflight.Stdout -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    Assert-CheckpointInvariant ($lines.Count -eq 1 -and $lines[0] -match '^LEARNING_EVIDENCE=\[.*\]$') 'Curriculum or checkpoint defect' "$milestone preflight emits one evidence array" ("stdout=" + ($lines -join '|')) $checkpoint
    try { $evidence = ($lines[0] -replace '^LEARNING_EVIDENCE=', '') | ConvertFrom-Json -ErrorAction Stop } catch {
      Assert-CheckpointInvariant $false 'Curriculum or checkpoint defect' "$milestone preflight evidence parses" $_.Exception.Message $checkpoint
    }
    $contractRoot = Resolve-CheckpointPath $root 'learning/milestones' 'Container'
    $checkpointContractPath = Get-ChildItem -LiteralPath $contractRoot -Directory | ForEach-Object { Join-Path $_.FullName 'checkpoint.yaml' } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Where-Object { [string](Get-Content -Raw -LiteralPath $_ | ConvertFrom-Json).id -eq $milestone } | Select-Object -First 1
    Assert-CheckpointInvariant (-not [string]::IsNullOrWhiteSpace($checkpointContractPath)) 'Curriculum or checkpoint defect' "$milestone checkpoint contract exists" 'contract-not-found' 'learning/milestones'
    $expectedEvidence = @((Get-Content -Raw -LiteralPath $checkpointContractPath | ConvertFrom-Json).behaviorEvidence)
    Assert-CheckpointInvariant ((@($evidence) -join ',') -eq ($expectedEvidence -join ',')) 'Curriculum or checkpoint defect' "$milestone preflight emits exact declared behaviorEvidence" ("actual=$(@($evidence) -join ',');expected=$($expectedEvidence -join ',')") $checkpoint
  }

  Write-Host 'M10 expected runtime: approximately 4 minutes for the disposable full release harness.'
  $harness = Resolve-CheckpointPath $root 'tests/run.ps1'
  $harnessText = Get-Content -Raw -LiteralPath $harness
  Assert-CheckpointInvariant ($harnessText -match '01 to 03 automatic dispatch' -and $harnessText -match '07 account evidence' -and $harnessText -match 'S01-S26 exact') 'Behavioral checkpoint failure' 'full harness traces a synthetic event through ingress, dispatch, operational evidence, and exact scenarios' 'end-to-end-trace-assertions-not-found' 'tests/run.ps1'
  $context = Read-CheckpointText $root 'docs/project-context.md'
  $lesson = Read-CheckpointText $root 'learning/milestones/M10-capstone/lesson.md'
  Assert-CheckpointInvariant ($context -match 'Real Meta delivery' -and $context -match 'production LLM' -and $context -match 'managed PostgreSQL controls' -and $context -match 'production owner' -and $lesson -match '(?i)failure mode' -and $lesson -match '(?i)production gate') 'Behavioral checkpoint failure' 'capstone materials require failure analysis and enumerate external production gates' 'failure-analysis-or-production-gate-inventory-not-found' 'docs/project-context.md and learning/milestones/M10-capstone/lesson.md'
  $full = Invoke-NativeCaptured $powershell @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $harness) $root
  Assert-CheckpointInvariant ($full.ExitCode -eq 0) 'Behavioral checkpoint failure' 'tests/run.ps1 exits zero' "exit=$($full.ExitCode);stderr=$($full.Stderr.Trim())" 'tests/run.ps1'
  Assert-CheckpointInvariant ($full.Stdout -match '(?m)^PASS FULL PASS\s*$') 'Behavioral checkpoint failure' 'full harness reports PASS FULL PASS' 'full-pass-marker-not-found' 'tests/run.ps1 output'
  Assert-CheckpointInvariant ($full.Stdout -match '(?m)^PASS plaintext generated credentials removed\s*$' -and $full.Stdout -match '(?m)^PASS container volumes removed\s*$') 'Behavioral checkpoint failure' 'full harness reports cleanup evidence for plaintext and disposable volumes' 'cleanup-evidence-not-found' 'tests/run.ps1 output'

  Write-LearningEvidence @('complete-release-harness-exit-zero', 'complete-release-harness-full-pass-marker', 'complete-release-harness-cleanup-evidence', 'end-to-end-scenario-trace', 'failure-analysis-and-production-gates')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
