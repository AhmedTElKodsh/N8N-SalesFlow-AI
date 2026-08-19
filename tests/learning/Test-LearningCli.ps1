. "$PSScriptRoot/TestSupport.ps1"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$temp = Join-Path ([IO.Path]::GetTempPath()) "salesflow-learning-cli-$([guid]::NewGuid().ToString('N'))"

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
  $startInfo.Arguments = '-NoLogo -NoProfile -NonInteractive -Command "' + $command.Replace('"', '\"') + '"'
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
    $process.WaitForExit()
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

  $completed = Get-SuccessJson (Invoke-Cli $fixture @('complete', 'M00', '-Explanation', 'PostgreSQL owns durable state', '-FailureMode', 'The workflow can fail after dispatch', '-TransferEvidence', 'Mapped another synthetic webhook')) 'complete M00'
  Assert-Equal $completed.completedMilestone 'M00' 'completion reports completed milestone'
  Assert-Equal $completed.currentMilestone 'M01' 'completion advances current milestone'

  $resume = Get-SuccessJson (Invoke-Cli $fixture @('resume')) 'resume'
  foreach ($name in @('branch', 'currentMilestone', 'workingTreeState', 'behaviorGate', 'highestHintLevel', 'directSolutionRequested', 'resumeNote')) {
    Assert-True ($null -ne $resume.PSObject.Properties[$name]) "resume reports $name"
  }

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
} finally {
  Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}

Assert-True (-not (Test-Path -LiteralPath $temp)) 'temporary CLI fixtures removed'
Complete-TestFile
