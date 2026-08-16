param([ValidateSet('M05','M10')][string]$Through = 'M10')
. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$curriculum = Get-Content -Raw "$root/learning/curriculum.yaml" | ConvertFrom-Json
$lastIndex = [int]$Through.Substring(1)
foreach ($m in @($curriculum.milestones)[0..$lastIndex]) {
  $dir = Join-Path $root "learning/milestones/$($m.directory)"
  foreach ($name in @('lesson.md','checkpoint.yaml','hints.md')) {
    Assert-True (Test-Path -LiteralPath (Join-Path $dir $name)) "$($m.id) has $name"
  }
  if (Test-Path "$dir/checkpoint.yaml") {
    $checkpoint = Get-Content -Raw "$dir/checkpoint.yaml" | ConvertFrom-Json
    Assert-Equal $checkpoint.id $m.id "$($m.id) checkpoint identity"
    Assert-True ($checkpoint.testScript -match '^tests/learning/checkpoints/Test-M\d\d\.ps1$') "$($m.id) safe test path"
    Assert-True (@($checkpoint.understandingPrompts).Count -eq 3) "$($m.id) has three understanding prompts"
  }
  if (Test-Path "$dir/hints.md") {
    $hints = Get-Content -Raw "$dir/hints.md"
    foreach ($level in 1..5) { Assert-Match $hints "## Hint $level" "$($m.id) has hint $level" }
    Assert-True (-not ($hints -match 'Direct solution')) "$($m.id) hints do not contain direct solution"
  }
}
Complete-TestFile
