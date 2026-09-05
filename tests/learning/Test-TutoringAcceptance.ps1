. "$PSScriptRoot/TestSupport.ps1"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$temp = Join-Path ([IO.Path]::GetTempPath()) "salesflow-tutoring-acceptance-$([guid]::NewGuid().ToString('N'))"

function ConvertTo-PowerShellLiteral([string]$Value) {
  "'$($Value.Replace("'", "''"))'"
}

function Invoke-ExternalPowerShell([string]$ScriptPath, [string[]]$Arguments = @()) {
  $invocation = @('&', (ConvertTo-PowerShellLiteral $ScriptPath))
  foreach ($argument in $Arguments) {
    if ($argument -match '^-[A-Za-z][A-Za-z0-9-]*$') { $invocation += $argument }
    else { $invocation += (ConvertTo-PowerShellLiteral $argument) }
  }
  $command = ($invocation -join ' ') + '; exit $LASTEXITCODE'
  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = (Get-Command powershell.exe -ErrorAction Stop).Source
  $startInfo.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "' + $command.Replace('"', '\"') + '"'
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  try {
    $null = $process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(60000)) {
      try { & taskkill.exe /PID $process.Id /T /F *> $null } catch {}
      [void]$process.WaitForExit(5000)
      throw "External PowerShell acceptance process exceeded 60000 ms: $ScriptPath"
    }
    [pscustomobject]@{
      ExitCode = $process.ExitCode
      Stdout = $stdoutTask.Result
      Stderr = $stderrTask.Result
    }
  } finally {
    $process.Dispose()
  }
}

function Invoke-Cli([string]$FixtureRoot, [string[]]$Arguments = @()) {
  Invoke-ExternalPowerShell -ScriptPath (Join-Path $FixtureRoot 'scripts/learn.ps1') -Arguments (@($Arguments) + @('-RepositoryRoot', $FixtureRoot))
}

function Get-SuccessJson($Result, [string]$Message) {
  Assert-Equal $Result.ExitCode 0 "$Message exits zero"
  Assert-True ([string]::IsNullOrWhiteSpace($Result.Stderr)) "$Message writes no stderr (stderr=$($Result.Stderr.Trim()))"
  $lines = @($Result.Stdout -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  Assert-Equal $lines.Count 1 "$Message emits one JSON result"
  if ($lines.Count -ne 1) { return $null }
  try { $lines[0] | ConvertFrom-Json -ErrorAction Stop } catch {
    Assert-True $false "$Message emits valid JSON"
    $null
  }
}

function Get-Section([string]$Text, [string]$HeadingPattern) {
  $match = [regex]::Match($Text, "(?ms)^$HeadingPattern\s*`r?`n(.*?)(?=^##\s|\z)")
  if (-not $match.Success) { return '' }
  $match.Groups[1].Value
}

New-Item -ItemType Directory -Path $temp -Force | Out-Null
try {
  New-Item -ItemType Directory -Path (Join-Path $temp 'scripts') -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $temp 'tests/learning/checkpoints') -Force | Out-Null
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'scripts/LearningState.psm1') -Destination (Join-Path $temp 'scripts/LearningState.psm1')
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'scripts/Invoke-LearningCheckpoint.ps1') -Destination (Join-Path $temp 'scripts/Invoke-LearningCheckpoint.ps1')
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'scripts/learn.ps1') -Destination (Join-Path $temp 'scripts/learn.ps1')
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'learning') -Destination $temp -Recurse

  $fixtureCheckpoint = Join-Path $temp 'tests/learning/checkpoints/Test-M00-AcceptanceFixture.ps1'
  [IO.File]::WriteAllText(
    $fixtureCheckpoint,
    "Write-Output 'LEARNING_EVIDENCE=[`"acceptance-m00`"]'`r`nexit 0`r`n",
    [Text.UTF8Encoding]::new($false)
  )
  $fixtureContractPath = Join-Path $temp 'learning/milestones/M00-orientation/checkpoint.yaml'
  $fixtureContract = Get-Content -Raw -LiteralPath $fixtureContractPath | ConvertFrom-Json
  $fixtureContract.testScript = 'tests/learning/checkpoints/Test-M00-AcceptanceFixture.ps1'
  [IO.File]::WriteAllText($fixtureContractPath, ($fixtureContract | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))

  & git -c "safe.directory=$temp" -C $temp init -q -b main
  & git -c "safe.directory=$temp" -C $temp config user.email 'learning-tests@example.invalid'
  & git -c "safe.directory=$temp" -C $temp config user.name 'Learning Tests'
  & git -c "safe.directory=$temp" -C $temp add .
  & git -c "safe.directory=$temp" -C $temp commit -q -m starter
  & git -c "safe.directory=$temp" -C $temp branch 'starter/salesflow-guided-v1'
  & git -c "safe.directory=$temp" -C $temp switch -q -c learner/acceptance
  if ($LASTEXITCODE -ne 0) { throw 'Failed to initialize tutoring acceptance Git fixture.' }

  $status = Get-SuccessJson (Invoke-Cli $temp @('status')) 'clean initialization'
  Assert-Equal $status.currentMilestone 'M00' 'clean initialization selects M00'
  Assert-Equal $status.milestoneStatus 'available' 'clean initialization makes M00 available'

  $started = Get-SuccessJson (Invoke-Cli $temp @('start', 'M00')) 'start M00'
  Assert-Equal $started.milestoneStatus 'active' 'M00 becomes active'

  $checked = Get-SuccessJson (Invoke-Cli $temp @('check', 'M00')) 'M00 focused checkpoint dispatch'
  Assert-True $checked.passed 'M00 behavior checkpoint passes'
  Assert-Equal (@($checked.evidence) -join ',') 'acceptance-m00' 'M00 checkpoint evidence is preserved'

  $completed = Get-SuccessJson (Invoke-Cli $temp @(
    'complete', 'M00',
    '-Explanation', 'n8n coordinates while PostgreSQL owns durable state',
    '-FailureMode', 'an unreviewed branch can invalidate later evidence',
    '-TransferEvidence', 'mapped a second synthetic event to the same ownership boundary'
  )) 'complete M00 with understanding evidence'
  Assert-Equal $completed.completedMilestone 'M00' 'M00 completion is recorded'
  Assert-Equal $completed.currentMilestone 'M01' 'M00 completion advances to M01'

  $progress = Get-Content -Raw -LiteralPath (Join-Path $temp '.learning/progress.json') | ConvertFrom-Json
  Assert-True $progress.milestones.M00.behaviorGate 'M00 behavior gate remains complete'
  Assert-True $progress.milestones.M00.understandingGate 'M00 understanding gate remains complete'
  Assert-Equal $progress.milestones.M01.status 'available' 'M01 is unlocked'
  Assert-Equal $progress.milestones.M02.status 'locked' 'M02 remains locked'

  $resume = Get-SuccessJson (Invoke-Cli $temp @('resume')) 'fresh-process resume'
  Assert-Equal $resume.currentMilestone 'M01' 'fresh-process resume restores M01'
  Assert-True ($null -ne $resume.PSObject.Properties['resumeNote']) 'fresh-process resume includes resume note'

  $curriculum = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'learning/curriculum.yaml') | ConvertFrom-Json
  $checkpointRoot = [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'tests/learning/checkpoints')).TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
  for ($index = 0; $index -lt $curriculum.milestones.Count; $index++) {
    $milestone = $curriculum.milestones[$index]
    $expectedPrerequisites = if ($index -eq 0) { @() } else { @($curriculum.milestones[$index - 1].id) }
    Assert-Equal (@($milestone.prerequisites) -join ',') ($expectedPrerequisites -join ',') "$($milestone.id) curriculum links only its immediate prerequisite"

    $milestoneRoot = Join-Path $repositoryRoot "learning/milestones/$($milestone.directory)"
    $checkpoint = Get-Content -Raw -LiteralPath (Join-Path $milestoneRoot 'checkpoint.yaml') | ConvertFrom-Json
    Assert-Equal (@($checkpoint.prerequisites) -join ',') ($expectedPrerequisites -join ',') "$($milestone.id) checkpoint links only its immediate prerequisite"
    $checkpointPath = [IO.Path]::GetFullPath((Join-Path $repositoryRoot $checkpoint.testScript))
    Assert-True $checkpointPath.StartsWith($checkpointRoot, [StringComparison]::OrdinalIgnoreCase) "$($milestone.id) checkpoint path stays within tests/learning/checkpoints"
    Assert-True (Test-Path -LiteralPath $checkpointPath -PathType Leaf) "$($milestone.id) checkpoint path exists"

    $lessonText = Get-Content -Raw -LiteralPath (Join-Path $milestoneRoot 'lesson.md')
    $yourTask = Get-Section -Text $lessonText -HeadingPattern '## Your task'
    $prerequisiteIntroduction = ($yourTask -split '(?m)^### Stage ', 2)[0]
    $linkedMilestones = @([regex]::Matches($prerequisiteIntroduction, '\bM(?:0[0-9]|10)\b') | ForEach-Object Value | Select-Object -Unique)
    Assert-Equal ($linkedMilestones -join ',') ($expectedPrerequisites -join ',') "$($milestone.id) lesson links only its immediate prerequisite"

    $stages = @([regex]::Matches($lessonText, '(?ms)^### Stage .*?(?=^### Stage |^## |\z)'))
    Assert-True ($stages.Count -gt 0) "$($milestone.id) lesson has staged teaching exchanges"
    foreach ($stage in $stages) {
      $termsMatch = [regex]::Match($stage.Value, '(?ms)^\*\*New terms:\*\*\s*(.*?)(?=^\*\*One action:\*\*)')
      Assert-True $termsMatch.Success "$($milestone.id) stage declares new terms"
      if ($termsMatch.Success) {
        $termCount = @($termsMatch.Groups[1].Value -split "`r?`n" | Where-Object { $_ -match '^\s*-\s+\*\*' }).Count
        Assert-True ($termCount -le 3) "$($milestone.id) stage introduces at most three just-in-time terms"
      }
    }
  }

  $learnerText = @(
    Get-ChildItem (Join-Path $repositoryRoot 'learning'),(Join-Path $repositoryRoot 'scripts') -File -Recurse |
      ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName }
  ) -join "`n"
  $forbidden = @(
    'git show reference/',
    'git checkout reference/',
    'reference/salesflow-complete-v1:database',
    'reference/salesflow-complete-v1:workflows'
  )
  foreach ($pattern in $forbidden) {
    Assert-True (-not $learnerText.Contains($pattern)) "ordinary tutoring omits forbidden reference access: $pattern"
  }

  $developmentGuide = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'docs/development-guide.md')
  foreach ($requiredGuidance in @(
    '## Tutoring maintenance',
    'JSON-compatible YAML',
    'Test-TutorContract.ps1',
    'Test-Curriculum.ps1',
    'Test-LearningState.ps1',
    'Test-LearningCli.ps1',
    'Test-MilestoneDocuments.ps1',
    'Test-ManifestHashing.ps1',
    'Test-TutoringAcceptance.ps1',
    'reference code is unavailable to ordinary tutoring',
    'starter/salesflow-guided-v1',
    'reference/salesflow-complete-v1',
    'completed code'
  )) {
    Assert-True $developmentGuide.Contains($requiredGuidance) "development guide documents $requiredGuidance"
  }
} finally {
  Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}

Assert-True (-not (Test-Path -LiteralPath $temp)) 'temporary tutoring acceptance fixture removed'
Complete-TestFile
