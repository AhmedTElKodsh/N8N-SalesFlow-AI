. "$PSScriptRoot/TestSupport.ps1"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$temp = Join-Path ([IO.Path]::GetTempPath()) "salesflow-learning-cli-$([guid]::NewGuid().ToString('N'))"

function ConvertTo-PowerShellLiteral([string]$Value) {
  "'$($Value.Replace("'", "''"))'"
}

function Invoke-ExternalPowerShell([string]$ScriptPath, [string[]]$Arguments = @(), [switch]$NativeFile) {
  $invocation = @('&', (ConvertTo-PowerShellLiteral $ScriptPath))
  foreach ($argument in $Arguments) {
    if ($argument -match '^-[A-Za-z][A-Za-z0-9-]*$') { $invocation += $argument }
    else { $invocation += (ConvertTo-PowerShellLiteral $argument) }
  }
  $command = ($invocation -join ' ') + '; exit $LASTEXITCODE'
  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = (Get-Command powershell.exe -ErrorAction Stop).Source
  $startInfo.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "' + $command.Replace('"', '\"') + '"'
  if ($NativeFile) {
    $nativeArguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath) + @($Arguments)
    $startInfo.Arguments = (@($nativeArguments | ForEach-Object { '"' + ($_ -replace '(\\+)$', '$1$1') + '"' }) -join ' ')
  }
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
      throw "External PowerShell test process exceeded 60000 ms: $ScriptPath"
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
  Assert-Equal $lines.Count 1 "$Message emits exactly one nonblank stdout line"
  try { $lines[0] | ConvertFrom-Json -ErrorAction Stop } catch {
    Assert-True $false "$Message emits valid JSON"
    $null
  }
}

function Read-Progress([string]$FixtureRoot) {
  Get-Content -Raw -LiteralPath (Join-Path $FixtureRoot '.learning/progress.json') | ConvertFrom-Json
}

function Set-CheckpointScript([string]$FixtureRoot, [string]$RelativePath) {
  $path = Join-Path $FixtureRoot 'learning/milestones/M00-orientation/checkpoint.yaml'
  $checkpoint = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
  $checkpoint.testScript = $RelativePath
  [IO.File]::WriteAllText($path, ($checkpoint | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
}

function Set-TestScript([string]$FixtureRoot, [string]$Content, [string]$Name = 'Test-M00.ps1') {
  $path = Join-Path $FixtureRoot "tests/learning/checkpoints/$Name"
  $directory = Split-Path -Parent $path
  New-Item -ItemType Directory -Path $directory -Force | Out-Null
  [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
  Set-CheckpointScript -FixtureRoot $FixtureRoot -RelativePath "tests/learning/checkpoints/$Name"
  $path
}

function New-CliFixture([string]$Name) {
  $fixtureRoot = Join-Path $temp $Name
  New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'scripts') -Force | Out-Null
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'scripts/LearningState.psm1') -Destination (Join-Path $fixtureRoot 'scripts/LearningState.psm1')
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'scripts/Invoke-LearningCheckpoint.ps1') -Destination (Join-Path $fixtureRoot 'scripts/Invoke-LearningCheckpoint.ps1')
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'scripts/learn.ps1') -Destination (Join-Path $fixtureRoot 'scripts/learn.ps1')
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'learning') -Destination $fixtureRoot -Recurse
  $null = Set-TestScript -FixtureRoot $fixtureRoot -Content "Write-Output 'LEARNING_EVIDENCE=[`"fixture-pass`"]'`r`nexit 0`r`n"
  & git -c "safe.directory=$fixtureRoot" -C $fixtureRoot init -q -b main
  & git -c "safe.directory=$fixtureRoot" -C $fixtureRoot config user.email 'learning-tests@example.invalid'
  & git -c "safe.directory=$fixtureRoot" -C $fixtureRoot config user.name 'Learning Tests'
  & git -c "safe.directory=$fixtureRoot" -C $fixtureRoot add .
  & git -c "safe.directory=$fixtureRoot" -C $fixtureRoot commit -q -m starter
  & git -c "safe.directory=$fixtureRoot" -C $fixtureRoot branch 'starter/salesflow-guided-v1'
  & git -c "safe.directory=$fixtureRoot" -C $fixtureRoot switch -q -c learner/test
  if ($LASTEXITCODE -ne 0) { throw "Failed to initialize Git learning fixture: $fixtureRoot" }
  $fixtureRoot
}

function Assert-ProtocolFailureDoesNotMutate([string]$FixtureRoot, [string]$Script, [string]$Message) {
  $null = Set-TestScript -FixtureRoot $FixtureRoot -Content $Script
  $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $FixtureRoot '.learning/progress.json')))
  $result = Invoke-Cli $FixtureRoot @('check')
  Assert-True ($result.ExitCode -ne 0) "$Message exits nonzero"
  Assert-True (-not [string]::IsNullOrWhiteSpace($result.Stderr)) "$Message uses stderr"
  Assert-True ([string]::IsNullOrWhiteSpace($result.Stdout)) "$Message emits no success JSON"
  $after = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $FixtureRoot '.learning/progress.json')))
  Assert-True ($after -ceq $before) "$Message leaves progress byte-for-byte unchanged"
}

New-Item -ItemType Directory -Path $temp -Force | Out-Null
try {
  $fixture = New-CliFixture 'happy-path'

  $status = Get-SuccessJson (Invoke-Cli $fixture @('status')) 'status'
  Assert-Equal $status.currentMilestone 'M00' 'status initializes current milestone'
  Assert-Equal $status.milestoneStatus 'available' 'status initializes M00 as available'

  $started = Get-SuccessJson (Invoke-Cli $fixture @('start', 'M00')) 'start M00'
  Assert-Equal $started.milestoneStatus 'active' 'start activates M00'

  $hint = Get-SuccessJson (Invoke-Cli $fixture @('record-hint', 'M00', '-Level', '2')) 'record hint'
  Assert-Equal $hint.highestHintLevel 2 'record hint stores level two'
  $solution = Get-SuccessJson (Invoke-Cli $fixture @('request-solution', 'M00')) 'request solution'
  Assert-True $solution.directSolutionRequested 'request solution records direct mode'
  $status = Get-SuccessJson (Invoke-Cli $fixture @('status')) 'status after metadata'
  Assert-Equal $status.highestHintLevel 2 'status reports highest hint'
  Assert-True $status.directSolutionRequested 'status reports direct solution state'

  $checked = Get-SuccessJson (Invoke-Cli $fixture @('check')) 'passing check'
  Assert-True $checked.passed 'check reports pass'
  Assert-Equal (@($checked.evidence) -join ',') 'fixture-pass' 'check reports typed evidence array'
  $progress = Read-Progress $fixture
  Assert-True $progress.milestones.M00.behaviorGate 'passing check records behavior gate'

  $beforeBlank = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $fixture '.learning/progress.json')))
  $blank = Invoke-Cli $fixture @('complete', 'M00', '-Explanation', ' ', '-FailureMode', 'failure', '-TransferEvidence', 'transfer')
  Assert-True ($blank.ExitCode -ne 0) 'blank understanding field exits nonzero'
  Assert-True (-not [string]::IsNullOrWhiteSpace($blank.Stderr)) 'blank understanding field uses stderr'
  Assert-True ([string]::IsNullOrWhiteSpace($blank.Stdout)) 'blank understanding field emits no success JSON'
  Assert-True (([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $fixture '.learning/progress.json')))) -ceq $beforeBlank) 'blank completion does not mutate progress'

  $missingDirectTransfer = Invoke-Cli $fixture @('complete', 'M00', '-Explanation', 'PostgreSQL owns durable state', '-FailureMode', 'The workflow can fail after dispatch', '-TransferEvidence', 'Mapped another synthetic webhook')
  Assert-True ($missingDirectTransfer.ExitCode -ne 0) 'direct solution completion requires extra transfer evidence'
  $completed = Get-SuccessJson (Invoke-Cli $fixture @('complete', 'M00', '-Explanation', 'PostgreSQL owns durable state', '-FailureMode', 'The workflow can fail after dispatch', '-TransferEvidence', 'Mapped another synthetic webhook', '-DirectSolutionTransferEvidence', 'Rebuilt the behavior from a fresh input')) 'complete M00'
  Assert-Equal $completed.completedMilestone 'M00' 'completion reports completed milestone'
  Assert-Equal $completed.currentMilestone 'M01' 'completion advances current milestone'

  $resume = Get-SuccessJson (Invoke-Cli $fixture @('resume')) 'resume'
  foreach ($name in @('branch', 'currentMilestone', 'workingTreeState', 'behaviorGate', 'highestHintLevel', 'directSolutionRequested', 'resumeNote')) {
    Assert-True ($null -ne $resume.PSObject.Properties[$name]) "resume reports $name"
  }

  $sequenceFixture = New-CliFixture 'sequence'
  $m00Sentinel = Join-Path $sequenceFixture 'm00-checkpoint-ran'
  $null = Set-TestScript $sequenceFixture "[IO.File]::WriteAllText((Join-Path `$PWD 'm00-checkpoint-ran'), 'ran')`r`nWrite-Output 'LEARNING_EVIDENCE=[]'`r`nexit 0`r`n"
  $null = Get-SuccessJson (Invoke-Cli $sequenceFixture @('status')) 'sequence fixture status'
  $beforeInactiveCheck = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $sequenceFixture '.learning/progress.json')))
  $inactiveCheck = Invoke-Cli $sequenceFixture @('check')
  Assert-True ($inactiveCheck.ExitCode -ne 0) 'check before start exits nonzero'
  Assert-True (-not [string]::IsNullOrWhiteSpace($inactiveCheck.Stderr)) 'check before start uses stderr'
  Assert-True ([string]::IsNullOrWhiteSpace($inactiveCheck.Stdout)) 'check before start emits no result JSON'
  Assert-True (-not (Test-Path -LiteralPath $m00Sentinel)) 'check before start does not launch checkpoint'
  Assert-True (([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $sequenceFixture '.learning/progress.json')))) -ceq $beforeInactiveCheck) 'check before start leaves progress unchanged'

  $null = Get-SuccessJson (Invoke-Cli $sequenceFixture @('start', 'M00')) 'sequence fixture start'
  $m01Script = Join-Path $sequenceFixture 'tests/learning/checkpoints/Test-M01.ps1'
  [IO.File]::WriteAllText($m01Script, "[IO.File]::WriteAllText((Join-Path `$PWD 'm01-checkpoint-ran'), 'ran')`r`nWrite-Output 'LEARNING_EVIDENCE=[]'`r`nexit 0`r`n", [Text.UTF8Encoding]::new($false))
  $beforeWrongCheck = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $sequenceFixture '.learning/progress.json')))
  $wrongCheck = Invoke-Cli $sequenceFixture @('check', 'M01')
  Assert-True ($wrongCheck.ExitCode -ne 0) 'locked wrong-milestone check exits nonzero'
  Assert-True (-not [string]::IsNullOrWhiteSpace($wrongCheck.Stderr)) 'locked wrong-milestone check uses stderr'
  Assert-True ([string]::IsNullOrWhiteSpace($wrongCheck.Stdout)) 'locked wrong-milestone check emits no result JSON'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $sequenceFixture 'm01-checkpoint-ran'))) 'locked wrong-milestone check does not launch checkpoint'
  Assert-True (([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $sequenceFixture '.learning/progress.json')))) -ceq $beforeWrongCheck) 'locked wrong-milestone check leaves progress unchanged'

  $protocolFixture = New-CliFixture 'protocol'
  $null = Get-SuccessJson (Invoke-Cli $protocolFixture @('start', 'M00')) 'protocol fixture start'
  Assert-ProtocolFailureDoesNotMutate $protocolFixture "Write-Output 'ordinary output'`r`nexit 0`r`n" 'missing evidence'
  Assert-ProtocolFailureDoesNotMutate $protocolFixture "Write-Output 'LEARNING_EVIDENCE=[]'`r`nWrite-Output 'LEARNING_EVIDENCE=[]'`r`nexit 0`r`n" 'duplicate evidence'
  Assert-ProtocolFailureDoesNotMutate $protocolFixture "Write-Output 'LEARNING_EVIDENCE=not-json'`r`nexit 0`r`n" 'malformed evidence'
  Assert-ProtocolFailureDoesNotMutate $protocolFixture "Write-Output 'LEARNING_EVIDENCE={`"ok`":true}'`r`nexit 0`r`n" 'object evidence'
  Assert-ProtocolFailureDoesNotMutate $protocolFixture "[Console]::Error.WriteLine('LEARNING_EVIDENCE=[`"stderr-only`"]')`r`nexit 0`r`n" 'stderr evidence'

  $null = Set-TestScript $protocolFixture "Write-Output 'LEARNING_EVIDENCE=[`"failed-check`"]'`r`n[Console]::Error.WriteLine('child diagnostic')`r`nexit 7`r`n"
  $failedCheck = Invoke-Cli $protocolFixture @('check')
  Assert-Equal $failedCheck.ExitCode 7 'failed child exit code propagates exactly'
  Assert-Match $failedCheck.Stderr 'child diagnostic' 'failed child stderr remains on stderr'
  $failedLines = @($failedCheck.Stdout -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  Assert-Equal $failedLines.Count 1 'failed check emits one JSON result line'
  $failedJson = $failedLines[0] | ConvertFrom-Json
  Assert-True (-not $failedJson.passed) 'failed check JSON reports false'
  $progress = Read-Progress $protocolFixture
  Assert-Equal $progress.milestones.M00.lastCheckResult $false 'failed check is recorded where required'
  Assert-Equal (@($progress.milestones.M00.evidenceRevision) -join ',') 'failed-check' 'failed check evidence is recorded'

  $null = Set-TestScript $protocolFixture "Write-Output 'LEARNING_EVIDENCE=[`"silent-failure`"]'`r`nexit 7`r`n"
  $silentFailure = Invoke-Cli $protocolFixture @('check')
  Assert-Equal $silentFailure.ExitCode 7 'silent failed child exit code propagates exactly'
  Assert-Match $silentFailure.Stderr 'Checkpoint M00 failed with exit code 7' 'silent failed child gets synthesized stderr diagnostic'
  $silentLines = @($silentFailure.Stdout -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  Assert-Equal $silentLines.Count 1 'silent failed check emits one JSON result line'
  $silentJson = $silentLines[0] | ConvertFrom-Json
  Assert-True (-not $silentJson.passed) 'silent failed check JSON reports false'
  $progress = Read-Progress $protocolFixture
  Assert-Equal $progress.milestones.M00.lastCheckResult $false 'silent failed check is recorded'
  Assert-Equal (@($progress.milestones.M00.evidenceRevision) -join ',') 'silent-failure' 'silent failed check evidence is recorded'

  $realFailureFixture = New-CliFixture 'real-failure'
  $null = Get-SuccessJson (Invoke-Cli $realFailureFixture @('start', 'M00')) 'real failure fixture start'
  $null = Get-SuccessJson (Invoke-Cli $realFailureFixture @('check')) 'real failure fixture initial pass'
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'tests/learning/checkpoints/Test-M00.ps1') -Destination (Join-Path $realFailureFixture 'tests/learning/checkpoints/Test-M00.ps1') -Force
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'tests/learning/checkpoints/CheckpointSupport.ps1') -Destination (Join-Path $realFailureFixture 'tests/learning/checkpoints/CheckpointSupport.ps1')
  # The real M00 checkpoint fails because this CLI fixture has no database directory.
  $realFailure = Invoke-Cli $realFailureFixture @('check')
  Assert-Equal $realFailure.ExitCode 1 'real no-evidence checkpoint fails'
  Assert-Match $realFailure.Stderr 'Syntax or integration failure: Invariant=required checkpoint artifact exists; Observed=missing:database;' 'real classified diagnostic survives the runner'
  $realFailureJson = $realFailure.Stdout | ConvertFrom-Json
  Assert-True (-not $realFailureJson.passed) 'real failure emits failed result'
  Assert-Equal @($realFailureJson.evidence).Count 0 'real failure needs no success evidence'
  $progress = Read-Progress $realFailureFixture
  Assert-True (-not $progress.milestones.M00.behaviorGate -and -not $progress.milestones.M00.lastCheckResult) 'real failure invalidates the previous behavior pass'
  $staleCompletion = Invoke-Cli $realFailureFixture @('complete', '-Explanation', 'flow', '-FailureMode', 'failure', '-TransferEvidence', 'transfer')
  Assert-True ($staleCompletion.ExitCode -ne 0) 'completion rejects the stale pass after real checkpoint failure'
  Assert-Equal (Read-Progress $realFailureFixture).milestones.M01.status 'locked' 'failed behavior leaves successor locked'

  $nativeFixture = New-CliFixture 'native-defaults'
  $nativeStatus = Invoke-ExternalPowerShell -ScriptPath (Join-Path $nativeFixture 'scripts/learn.ps1') -Arguments @('status') -NativeFile
  $null = Get-SuccessJson $nativeStatus 'native -File CLI resolves its default repository root'
  $nativeRunner = Invoke-ExternalPowerShell -ScriptPath (Join-Path $nativeFixture 'scripts/Invoke-LearningCheckpoint.ps1') -Arguments @('-Milestone', 'M00') -NativeFile
  $null = Get-SuccessJson $nativeRunner 'native -File runner resolves its default repository root'

  $boundaryFixture = New-CliFixture 'boundary'
  $null = Get-SuccessJson (Invoke-Cli $boundaryFixture @('start', 'M00')) 'boundary fixture start'
  $evilDirectory = Join-Path $boundaryFixture 'tests/learning/checkpoints-evil'
  New-Item -ItemType Directory -Path $evilDirectory -Force | Out-Null
  [IO.File]::WriteAllText((Join-Path $evilDirectory 'escape.ps1'), "Write-Output 'LEARNING_EVIDENCE=[]'", [Text.UTF8Encoding]::new($false))
  Set-CheckpointScript $boundaryFixture 'tests/learning/checkpoints-evil/escape.ps1'
  $beforeBoundary = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $boundaryFixture '.learning/progress.json')))
  $prefixEscape = Invoke-Cli $boundaryFixture @('check')
  Assert-True ($prefixEscape.ExitCode -ne 0) 'sibling prefix escape rejected'
  Assert-True (([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $boundaryFixture '.learning/progress.json')))) -ceq $beforeBoundary) 'sibling prefix rejection leaves progress unchanged'

  $outsideDirectory = Join-Path $boundaryFixture 'outside'
  New-Item -ItemType Directory -Path $outsideDirectory -Force | Out-Null
  [IO.File]::WriteAllText((Join-Path $outsideDirectory 'escape.ps1'), "Write-Output 'LEARNING_EVIDENCE=[]'", [Text.UTF8Encoding]::new($false))
  Set-CheckpointScript $boundaryFixture 'tests/learning/checkpoints/../../../outside/escape.ps1'
  $traversal = Invoke-Cli $boundaryFixture @('check')
  Assert-True ($traversal.ExitCode -ne 0) 'traversal escape rejected'
  Assert-True (([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $boundaryFixture '.learning/progress.json')))) -ceq $beforeBoundary) 'traversal rejection leaves progress unchanged'

  Set-CheckpointScript $boundaryFixture 'tests/learning/checkpoints/missing.ps1'
  $missing = Invoke-Cli $boundaryFixture @('check')
  Assert-True ($missing.ExitCode -ne 0) 'missing checkpoint rejected'

  $junctionOutside = Join-Path $boundaryFixture 'junction-target'
  New-Item -ItemType Directory -Path $junctionOutside -Force | Out-Null
  [IO.File]::WriteAllText((Join-Path $junctionOutside 'escape.ps1'), "Write-Output 'LEARNING_EVIDENCE=[]'", [Text.UTF8Encoding]::new($false))
  $linkPath = Join-Path $boundaryFixture 'tests/learning/checkpoints/link'
  $junction = New-Item -ItemType Junction -Path $linkPath -Target $junctionOutside -ErrorAction Stop
  Set-CheckpointScript $boundaryFixture 'tests/learning/checkpoints/link/escape.ps1'
  $reparse = Invoke-Cli $boundaryFixture @('check')
  Assert-True ($reparse.ExitCode -ne 0) 'reparse-point escape rejected'
  Assert-True (([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $boundaryFixture '.learning/progress.json')))) -ceq $beforeBoundary) 'reparse rejection leaves progress unchanged'

  $invalidCommand = Invoke-Cli $boundaryFixture @('not-a-command')
  Assert-True ($invalidCommand.ExitCode -ne 0) 'validated command errors exit nonzero when invoked with call operator'
  Assert-True (-not [string]::IsNullOrWhiteSpace($invalidCommand.Stderr)) 'validated command error uses stderr'

  $lineageFixture = New-CliFixture 'lineage'
  & git -c "safe.directory=$lineageFixture" -C $lineageFixture switch -q main
  $mainLineage = Invoke-Cli $lineageFixture @('status')
  Assert-True ($mainLineage.ExitCode -ne 0) 'learning CLI rejects main branch'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $lineageFixture '.learning/progress.json'))) 'first-use main rejection creates no progress'
  & git -c "safe.directory=$lineageFixture" -C $lineageFixture switch -q learner/test
  & git -c "safe.directory=$lineageFixture" -C $lineageFixture branch -D 'starter/salesflow-guided-v1' | Out-Null
  $missingStarter = Invoke-Cli $lineageFixture @('status')
  Assert-True ($missingStarter.ExitCode -ne 0) 'learning CLI rejects a missing starter ref'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $lineageFixture '.learning/progress.json'))) 'first-use missing starter rejection creates no progress'
  & git -c "safe.directory=$lineageFixture" -C $lineageFixture branch 'starter/salesflow-guided-v1' HEAD
  & git -c "safe.directory=$lineageFixture" -C $lineageFixture checkout -q --detach HEAD
  $detachedLineage = Invoke-Cli $lineageFixture @('status')
  Assert-True ($detachedLineage.ExitCode -ne 0) 'learning CLI rejects detached HEAD'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $lineageFixture '.learning/progress.json'))) 'first-use detached rejection creates no progress'

  $timeoutFixture = New-CliFixture 'timeout'
  $null = Set-TestScript -FixtureRoot $timeoutFixture -Content "Start-Sleep -Seconds 5`r`nWrite-Output 'LEARNING_EVIDENCE=[]'`r`n"
  $timeoutResult = Invoke-ExternalPowerShell -ScriptPath (Join-Path $timeoutFixture 'scripts/Invoke-LearningCheckpoint.ps1') -Arguments @('-Milestone','M00','-RepositoryRoot',$timeoutFixture,'-TimeoutMilliseconds','200')
  Assert-True ($timeoutResult.ExitCode -ne 0) 'checkpoint runner terminates an over-time child'
  Assert-Match $timeoutResult.Stderr 'execution limit' 'checkpoint timeout returns a typed diagnostic'
  $null = Set-TestScript -FixtureRoot $timeoutFixture -Content "Write-Output 'LEARNING_EVIDENCE=[`"initial-pass`"]'`r`n"
  $null = Get-SuccessJson (Invoke-Cli $timeoutFixture @('start', 'M00')) 'timeout fixture start'
  $null = Get-SuccessJson (Invoke-Cli $timeoutFixture @('check')) 'timeout fixture initial behavior pass'
  $fixtureRunnerPath = Join-Path $timeoutFixture 'scripts/Invoke-LearningCheckpoint.ps1'
  $fixtureRunner = (Get-Content -Raw -LiteralPath $fixtureRunnerPath).Replace('[int]$TimeoutMilliseconds = 900000', '[int]$TimeoutMilliseconds = 500')
  [IO.File]::WriteAllText($fixtureRunnerPath, $fixtureRunner, [Text.UTF8Encoding]::new($false))
  $null = Set-TestScript -FixtureRoot $timeoutFixture -Content "Start-Sleep -Seconds 5`r`nWrite-Output 'LEARNING_EVIDENCE=[]'`r`n"
  $timedOutCheck = Invoke-Cli $timeoutFixture @('check')
  Assert-Equal $timedOutCheck.ExitCode 1 'timed-out check exits nonzero through CLI'
  Assert-Match $timedOutCheck.Stderr 'execution limit' 'timed-out CLI check preserves diagnostic'
  $timeoutJson = $timedOutCheck.Stdout | ConvertFrom-Json
  Assert-True (-not $timeoutJson.passed) 'timed-out check returns failed result'
  $timeoutProgress = Read-Progress $timeoutFixture
  Assert-True (-not $timeoutProgress.milestones.M00.behaviorGate -and -not $timeoutProgress.milestones.M00.lastCheckResult) 'timeout invalidates prior behavior pass'
  $timeoutCompletion = Invoke-Cli $timeoutFixture @('complete', '-Explanation', 'flow', '-FailureMode', 'failure', '-TransferEvidence', 'transfer')
  Assert-True ($timeoutCompletion.ExitCode -ne 0) 'completion rejects stale pass after timeout'
  Assert-Equal (Read-Progress $timeoutFixture).milestones.M01.status 'locked' 'timeout leaves successor locked'
} finally {
  Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}

Assert-True (-not (Test-Path -LiteralPath $temp)) 'temporary CLI fixtures removed'
Complete-TestFile
