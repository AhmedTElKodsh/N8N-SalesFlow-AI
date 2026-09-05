[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Command = 'status',

  [Parameter(Position = 1)]
  [string]$Milestone,

  [string]$Level,

  [AllowEmptyString()]
  [string]$Explanation,

  [AllowEmptyString()]
  [string]$FailureMode,

  [AllowEmptyString()]
  [string]$TransferEvidence,

  [AllowEmptyString()]
  [string]$DirectSolutionTransferEvidence,

  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

function Write-JsonResult($Value) {
  Write-Output ($Value | ConvertTo-Json -Depth 20 -Compress)
}

function Get-MilestoneState($Progress, [string]$MilestoneId) {
  $property = $Progress.milestones.PSObject.Properties[$MilestoneId]
  if ($null -eq $property) { throw "Unknown learning milestone: $MilestoneId" }
  $property.Value
}

function Resolve-Milestone($Progress, [string]$RequestedMilestone) {
  if ([string]::IsNullOrWhiteSpace($RequestedMilestone)) { return [string]$Progress.currentMilestone }
  $RequestedMilestone
}

function Get-GitSnapshot([string]$Root) {
  $branch = $null
  $workingTreeState = 'unavailable'
  try {
    $branchOutput = @(& git -c "safe.directory=$Root" -C $Root branch --show-current 2>$null)
    $branchExit = $LASTEXITCODE
    if ($branchExit -eq 0) {
      $branchText = ($branchOutput -join "`n").Trim()
      if (-not [string]::IsNullOrWhiteSpace($branchText)) { $branch = $branchText }
      $statusOutput = @(& git -c "safe.directory=$Root" -C $Root status --porcelain 2>$null)
      if ($LASTEXITCODE -eq 0) {
        $workingTreeState = if ($statusOutput.Count -eq 0) { 'clean' } else { 'dirty' }
      }
    }
  } catch {
    $branch = $null
    $workingTreeState = 'unavailable'
  }
  [pscustomobject]@{ branch = $branch; workingTreeState = $workingTreeState }
}

function Assert-LearningLineage([string]$Root, $Progress) {
  $git = Get-Command git.exe -ErrorAction SilentlyContinue
  if ($null -eq $git) { $git = Get-Command git -ErrorAction SilentlyContinue }
  if ($null -eq $git) { throw 'Git is required for learning commands.' }
  $inside = @(& $git.Source -c "safe.directory=$Root" -C $Root rev-parse --is-inside-work-tree 2>$null)
  if (($LASTEXITCODE -ne 0) -or (($inside -join '').Trim() -cne 'true')) { throw 'Learning repository root must be a Git working tree.' }
  $top = @(& $git.Source -c "safe.directory=$Root" -C $Root rev-parse --show-toplevel 2>$null)
  if (($LASTEXITCODE -ne 0) -or ([IO.Path]::GetFullPath(($top -join '').Trim()).TrimEnd('\','/') -cne [IO.Path]::GetFullPath($Root).TrimEnd('\','/'))) {
    throw 'Learning commands must run at the Git worktree root.'
  }
  $branch = (@(& $git.Source -c "safe.directory=$Root" -C $Root branch --show-current 2>$null) -join '').Trim()
  if (($LASTEXITCODE -ne 0) -or [string]::IsNullOrWhiteSpace($branch)) { throw 'Learning commands require a named learner branch.' }
  if ($branch -ceq 'main') { throw 'Learning commands cannot run on main; create a learner branch from the starter ref.' }
  & $git.Source -c "safe.directory=$Root" -C $Root rev-parse --verify --quiet "$($Progress.starterRevision)^{commit}" *> $null
  if ($LASTEXITCODE -ne 0) { throw "Learning starter ref '$($Progress.starterRevision)' does not resolve to a commit." }
  & $git.Source -c "safe.directory=$Root" -C $Root merge-base --is-ancestor $Progress.starterRevision HEAD *> $null
  if ($LASTEXITCODE -ne 0) { throw 'The learner branch is not descended from the configured starter ref.' }
}

function Invoke-RunnerProcess([string]$RunnerPath, [string]$Root, [string]$MilestoneId, [int]$TimeoutMilliseconds = 930000) {
  function Quote-Native([string]$Value) {
    if ($Value.Contains('"')) { throw 'A native path contains an unsupported quote character.' }
    '"' + $Value + '"'
  }

  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = (Get-Command powershell.exe -ErrorAction Stop).Source
  $startInfo.Arguments = @(
    '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
    '-File', (Quote-Native $RunnerPath),
    '-Milestone', (Quote-Native $MilestoneId),
    '-RepositoryRoot', (Quote-Native $Root)
  ) -join ' '
  $startInfo.WorkingDirectory = $Root
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
    if (-not $process.WaitForExit($TimeoutMilliseconds)) {
      try { & taskkill.exe /PID $process.Id /T /F *> $null } catch {}
      if (-not $process.WaitForExit(5000)) { try { $process.Kill() } catch {} }
      throw "Learning checkpoint runner exceeded the $TimeoutMilliseconds ms execution limit."
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

function Convert-RunnerResult($Runner, [string]$ExpectedMilestone) {
  $lines = @($Runner.Stdout -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($lines.Count -eq 0) { return $null }
  if ($lines.Count -ne 1) { throw "Learning checkpoint runner emitted $($lines.Count) nonblank stdout lines; expected exactly one JSON object." }
  try {
    $result = $lines[0] | ConvertFrom-Json -ErrorAction Stop
  } catch {
    throw "Learning checkpoint runner emitted malformed JSON: $($_.Exception.Message)"
  }
  if (-not ($result -is [pscustomobject])) { throw 'Learning checkpoint runner JSON root must be an object.' }
  foreach ($name in @('passed', 'milestone', 'evidence', 'durationMs')) {
    if ($null -eq $result.PSObject.Properties[$name]) { throw "Learning checkpoint runner result is missing '$name'." }
  }
  if (-not ($result.passed -is [bool])) { throw "Learning checkpoint runner result 'passed' must be Boolean." }
  if (($result.milestone -isnot [string]) -or ($result.milestone -cne $ExpectedMilestone)) {
    throw 'Learning checkpoint runner result milestone does not match the requested milestone.'
  }
  if (($Runner.ExitCode -eq 0) -ne $result.passed) {
    throw 'Learning checkpoint runner exit code and passed result disagree.'
  }
  $result
}

try {
  $allowedCommands = @('status', 'start', 'check', 'complete', 'resume', 'record-hint', 'request-solution')
  if ($allowedCommands -cnotcontains $Command) {
    throw "Unknown learning command '$Command'. Allowed commands: $($allowedCommands -join ', ')."
  }
  if ((-not [string]::IsNullOrWhiteSpace($Milestone)) -and ($Milestone -cnotmatch '^M(?:0[0-9]|10)$')) {
    throw "Invalid learning milestone '$Milestone'. Expected M00 through M10."
  }
  $parsedLevel = 0
  $hasLevel = -not [string]::IsNullOrWhiteSpace($Level)
  if ($hasLevel -and ((-not [int]::TryParse($Level, [ref]$parsedLevel)) -or ($parsedLevel -lt 1) -or ($parsedLevel -gt 5))) {
    throw 'Level must be an integer from 1 through 5.'
  }

  $modulePath = Join-Path $PSScriptRoot 'LearningState.psm1'
  Import-Module $modulePath -Force -DisableNameChecking -ErrorAction Stop
  if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
  $context = Get-LearningContext -RepositoryRoot $RepositoryRoot
  $curriculum = Get-Content -Raw -LiteralPath $context.CurriculumPath | ConvertFrom-Json -ErrorAction Stop
  Assert-LearningLineage -Root $context.RepositoryRoot -Progress ([pscustomobject]@{ starterRevision = $curriculum.starterRef })
  $progress = Initialize-LearningProgress -Context $context
  $milestoneId = Resolve-Milestone -Progress $progress -RequestedMilestone $Milestone

  switch ($Command) {
    'status' {
      $state = Get-MilestoneState -Progress $progress -MilestoneId $milestoneId
      $git = Get-GitSnapshot -Root $context.RepositoryRoot
      Write-JsonResult ([pscustomobject]@{
        command = 'status'
        branch = $git.branch
        currentMilestone = $progress.currentMilestone
        milestone = $milestoneId
        milestoneStatus = $state.status
        workingTreeState = $git.workingTreeState
        behaviorGate = $state.behaviorGate
        understandingGate = $state.understandingGate
        highestHintLevel = $state.highestHintLevel
        directSolutionRequested = $state.directSolutionRequested
        availableAction = if ($state.status -eq 'available') { 'start' } elseif ($state.status -eq 'active') { 'check' } else { 'status' }
      })
    }
    'start' {
      $progress = Start-LearningMilestone -Context $context -MilestoneId $milestoneId
      $state = Get-MilestoneState -Progress $progress -MilestoneId $milestoneId
      Write-JsonResult ([pscustomobject]@{
        command = 'start'
        currentMilestone = $progress.currentMilestone
        milestone = $milestoneId
        milestoneStatus = $state.status
        attempts = $state.attempts
      })
    }
    'record-hint' {
      if (-not $hasLevel) { throw 'Level is required for record-hint.' }
      $progress = Record-LearningHint -Context $context -MilestoneId $milestoneId -Level $parsedLevel
      $state = Get-MilestoneState -Progress $progress -MilestoneId $milestoneId
      Write-JsonResult ([pscustomobject]@{
        command = 'record-hint'
        milestone = $milestoneId
        highestHintLevel = $state.highestHintLevel
      })
    }
    'request-solution' {
      $progress = Record-DirectSolutionRequest -Context $context -MilestoneId $milestoneId
      $state = Get-MilestoneState -Progress $progress -MilestoneId $milestoneId
      Write-JsonResult ([pscustomobject]@{
        command = 'request-solution'
        milestone = $milestoneId
        directSolutionRequested = $state.directSolutionRequested
      })
    }
    'check' {
      $state = Get-MilestoneState -Progress $progress -MilestoneId $milestoneId
      if (($progress.currentMilestone -cne $milestoneId) -or ($state.status -cne 'active')) {
        throw "Learning milestone $milestoneId is not the active current milestone."
      }
      $runnerPath = Join-Path $PSScriptRoot 'Invoke-LearningCheckpoint.ps1'
      $runner = Invoke-RunnerProcess -RunnerPath $runnerPath -Root $context.RepositoryRoot -MilestoneId $milestoneId
      $result = Convert-RunnerResult -Runner $runner -ExpectedMilestone $milestoneId
      if ($null -eq $result) {
        $detail = $runner.Stderr.Trim()
        if ([string]::IsNullOrWhiteSpace($detail)) { $detail = 'Checkpoint runner failed without a diagnostic.' }
        throw $detail
      }
      $progress = Record-LearningCheck -Context $context -MilestoneId $milestoneId -Passed $result.passed -Evidence @($result.evidence)
      if (($runner.ExitCode -ne 0) -and [string]::IsNullOrWhiteSpace($runner.Stderr)) {
        [Console]::Error.WriteLine("Checkpoint $milestoneId failed with exit code $($runner.ExitCode).")
      } elseif (-not [string]::IsNullOrEmpty($runner.Stderr)) {
        [Console]::Error.Write($runner.Stderr)
      }
      Write-JsonResult $result
      if ($runner.ExitCode -ne 0) { exit $runner.ExitCode }
    }
    'complete' {
      $progress = Complete-LearningMilestone -Context $context -MilestoneId $milestoneId -Explanation $Explanation -FailureMode $FailureMode -TransferEvidence $TransferEvidence -DirectSolutionTransferEvidence $DirectSolutionTransferEvidence
      Write-JsonResult ([pscustomobject]@{
        command = 'complete'
        completedMilestone = $milestoneId
        currentMilestone = $progress.currentMilestone
        milestoneStatus = (Get-MilestoneState -Progress $progress -MilestoneId $milestoneId).status
      })
    }
    'resume' {
      $state = Get-MilestoneState -Progress $progress -MilestoneId $progress.currentMilestone
      $git = Get-GitSnapshot -Root $context.RepositoryRoot
      Write-JsonResult ([pscustomobject]@{
        command = 'resume'
        branch = $git.branch
        currentMilestone = $progress.currentMilestone
        workingTreeState = $git.workingTreeState
        behaviorGate = $state.behaviorGate
        highestHintLevel = $state.highestHintLevel
        directSolutionRequested = $state.directSolutionRequested
        resumeNote = $state.resumeNote
      })
    }
  }
  exit 0
} catch {
  [Console]::Error.WriteLine($_.Exception.Message)
  exit 1
}
