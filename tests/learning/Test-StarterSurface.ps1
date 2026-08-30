$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/TestSupport.ps1"

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

foreach ($relativePath in @(
  'database/001-initial.sql',
  'release/release-manifest.json',
  'tests/runtime.sql',
  'tests/pilot-scenarios.json'
)) {
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $root $relativePath))) "starter omits completed artifact $relativePath"
}

$workflowExports = @(Get-ChildItem -LiteralPath (Join-Path $root 'workflows') -Filter '*.json' -File -ErrorAction SilentlyContinue)
$productionConfigs = @(Get-ChildItem -LiteralPath (Join-Path $root 'config') -Filter '*.json' -File -ErrorAction SilentlyContinue)
Assert-Equal $workflowExports.Count 0 'starter omits completed workflow exports'
Assert-Equal $productionConfigs.Count 0 'starter omits production-shaped configuration fixtures'

foreach ($relativePath in @('database', 'workflows', 'config', 'release')) {
  Assert-True (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Container) "starter preserves learner-owned directory $relativePath"
}

foreach ($relativePath in @(
  'learning/README.md',
  'learning/curriculum.yaml',
  'learning/tutor-contract.md',
  'scripts/learn.ps1',
  'scripts/LearningState.psm1',
  'scripts/Invoke-LearningCheckpoint.ps1',
  'tests/learning/Test-CheckpointSuite.ps1',
  '.env.example',
  'compose.yaml'
)) {
  Assert-True (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf) "starter preserves $relativePath"
}

$learnerSurface = @('database', 'workflows', 'config') | ForEach-Object {
  Get-ChildItem -LiteralPath (Join-Path $root $_) -File -Recurse -ErrorAction SilentlyContinue
} | ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName }
Assert-True (-not (($learnerSurface -join "`n").Contains('Synthetic Plan includes one service'))) 'starter surface contains no completed synthetic solution text'

Complete-TestFile
