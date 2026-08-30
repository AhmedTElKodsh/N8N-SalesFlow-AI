param([string]$RepositoryRoot = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/CheckpointSupport.ps1"

try {
  $root = Resolve-CheckpointRepositoryRoot $RepositoryRoot
  Assert-GitRepository $root

  $git = Get-Command git.exe -ErrorAction SilentlyContinue
  if ($null -eq $git) { $git = Get-Command git -ErrorAction Stop }
  $branch = Invoke-NativeCaptured $git.Source @('branch', '--show-current') $root
  Assert-NativeSuccess $branch 'current learner branch can be identified' 'git branch --show-current'
  Assert-CheckpointInvariant (-not [string]::IsNullOrWhiteSpace($branch.Stdout) -and $branch.Stdout.Trim() -ne 'main') 'Behavioral checkpoint failure' 'work proceeds on a named learner branch rather than product main' $branch.Stdout.Trim() 'git branch --show-current'

  $starter = Invoke-NativeCaptured $git.Source @('rev-parse', '--verify', '--quiet', 'starter/salesflow-guided-v1^{commit}') $root
  Assert-CheckpointInvariant ($starter.ExitCode -eq 0) 'Environment or tooling failure' 'starter/salesflow-guided-v1 exists as a commit' "exit=$($starter.ExitCode); stderr=$($starter.Stderr.Trim())" 'git rev-parse --verify starter/salesflow-guided-v1'
  $ancestry = Invoke-NativeCaptured $git.Source @('merge-base', '--is-ancestor', 'starter/salesflow-guided-v1', 'HEAD') $root
  Assert-CheckpointInvariant ($ancestry.ExitCode -eq 0) 'Behavioral checkpoint failure' 'HEAD descends from starter/salesflow-guided-v1' "exit=$($ancestry.ExitCode); stderr=$($ancestry.Stderr.Trim())" 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD'

  foreach ($directory in @('database', 'workflows', 'learning', 'tests')) {
    $path = Resolve-CheckpointPath $root $directory 'Container'
    Assert-CheckpointInvariant (Test-Path -LiteralPath $path -PathType Container) 'Behavioral checkpoint failure' 'repository map exposes the core learning and implementation areas' "missing-directory:$directory" $path
  }

  $contract = Read-CheckpointText $root 'learning/tutor-contract.md'
  Assert-CheckpointInvariant ($contract -match '(?m)^# SalesFlow tutor contract\s*$') 'Behavioral checkpoint failure' 'tutor contract is readable and identifiable' 'title-not-found' 'learning/tutor-contract.md'
  Assert-CheckpointInvariant ($contract -match '(?i)distinguish n8n orchestration from PostgreSQL state ownership') 'Behavioral checkpoint failure' 'tutor contract states the orchestration and durable-state boundary' 'boundary-not-found' 'learning/tutor-contract.md'
  Assert-CheckpointInvariant ($contract -match '(?i)synthetic-local') 'Behavioral checkpoint failure' 'tutor contract states the synthetic-local boundary' 'boundary-not-found' 'learning/tutor-contract.md'

  $journal = Read-CheckpointText $root 'learning/journal.md'
  $m00 = [regex]::Match($journal, '(?ms)^## M00\b(?<Body>.*?)(?=^## M01\b)')
  Assert-CheckpointInvariant $m00.Success 'Behavioral checkpoint failure' 'learning journal contains an M00 section' 'M00-section-not-found' 'learning/journal.md'
  foreach ($prompt in @('Data flow', 'Design decision', 'Realistic failure mode', 'Transfer exercise evidence')) {
    Assert-CheckpointInvariant ($m00.Groups['Body'].Value -match ('(?m)^### ' + [regex]::Escape($prompt) + '\s*$')) 'Behavioral checkpoint failure' "M00 journal includes the $prompt prompt" "prompt-not-found:$prompt" 'learning/journal.md'
  }

  Write-LearningEvidence @('git-worktree-safety', 'repository-map', 'orchestration-state-boundary', 'synthetic-local-boundary')
} catch {
  Write-CheckpointFailure $_ $RepositoryRoot
  exit 1
}
