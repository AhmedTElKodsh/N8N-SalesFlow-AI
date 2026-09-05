[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^M(?:0[0-9]|10)$')]
  [string]$Milestone,

  [string]$RepositoryRoot,

  [ValidateRange(100, 1800000)]
  [int]$TimeoutMilliseconds = 900000
)

$ErrorActionPreference = 'Stop'

function Get-CanonicalPath([string]$Path) {
  [IO.Path]::GetFullPath($Path)
}

function Assert-DescendantPath([string]$Parent, [string]$Candidate) {
  $separator = [IO.Path]::DirectorySeparatorChar
  $parentPrefix = $Parent.TrimEnd([char[]]@('\', '/')) + $separator
  if (-not $Candidate.StartsWith($parentPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Checkpoint script must be a descendant of $Parent."
  }
}

function Assert-NoReparsePoint([string]$Parent, [string]$Candidate) {
  $current = $Parent
  $parentItem = Get-Item -LiteralPath $current -Force -ErrorAction Stop
  if (($parentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "Checkpoint path contains a reparse point: $current"
  }

  $relative = $Candidate.Substring($Parent.TrimEnd([char[]]@('\', '/')).Length).TrimStart([char[]]@('\', '/'))
  foreach ($segment in @($relative -split '[\\/]')) {
    if ([string]::IsNullOrWhiteSpace($segment)) { continue }
    $current = Join-Path $current $segment
    $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw "Checkpoint path contains a reparse point: $current"
    }
  }
}

function ConvertTo-NativeQuotedArgument([string]$Value) {
  if ($Value.IndexOf([char]0) -ge 0) { throw 'A native argument contains a null character.' }
  if ($Value.Contains('"')) { throw 'A native path contains an unsupported quote character.' }
  '"' + $Value + '"'
}

function Stop-CheckpointProcess([Diagnostics.Process]$Process) {
  try { & taskkill.exe /PID $Process.Id /T /F *> $null } catch {}
  if (-not $Process.WaitForExit(5000)) {
    try { $Process.Kill() } catch {}
    if (-not $Process.WaitForExit(5000)) { throw 'Checkpoint process could not be terminated within the cleanup bound.' }
  }
}

function Invoke-CheckpointProcess([string]$ScriptPath, [string]$WorkingDirectory, [int]$Timeout) {
  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = (Get-Command powershell.exe -ErrorAction Stop).Source
  $startInfo.Arguments = @(
    '-NoLogo',
    '-NoProfile',
    '-NonInteractive',
    '-ExecutionPolicy', 'Bypass',
    '-File', (ConvertTo-NativeQuotedArgument $ScriptPath)
  ) -join ' '
  $startInfo.WorkingDirectory = $WorkingDirectory
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
    if (-not $process.WaitForExit($Timeout)) {
      Stop-CheckpointProcess -Process $process
      throw "Checkpoint exceeded the $Timeout ms execution limit."
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

try {
  if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
  $root = (Resolve-Path -LiteralPath $RepositoryRoot -ErrorAction Stop).Path
  $curriculumPath = Join-Path $root 'learning/curriculum.yaml'
  if (-not (Test-Path -LiteralPath $curriculumPath -PathType Leaf)) {
    throw "Learning curriculum missing: $curriculumPath"
  }
  $curriculum = Get-Content -Raw -LiteralPath $curriculumPath | ConvertFrom-Json -ErrorAction Stop
  $milestoneEntry = @($curriculum.milestones | Where-Object { $_.id -ceq $Milestone })
  if ($milestoneEntry.Count -ne 1) { throw "Unknown learning milestone: $Milestone" }

  $checkpointPath = Join-Path $root "learning/milestones/$($milestoneEntry[0].directory)/checkpoint.yaml"
  if (-not (Test-Path -LiteralPath $checkpointPath -PathType Leaf)) {
    throw "Learning checkpoint contract missing: $checkpointPath"
  }
  $checkpoint = Get-Content -Raw -LiteralPath $checkpointPath | ConvertFrom-Json -ErrorAction Stop
  if (($checkpoint.id -isnot [string]) -or ($checkpoint.id -cne $Milestone)) {
    throw "Learning checkpoint contract id does not match $Milestone."
  }
  if (($checkpoint.testScript -isnot [string]) -or [string]::IsNullOrWhiteSpace($checkpoint.testScript)) {
    throw "Learning checkpoint $Milestone has no testScript."
  }

  $testsRoot = Get-CanonicalPath (Join-Path $root 'tests/learning/checkpoints')
  if (-not (Test-Path -LiteralPath $testsRoot -PathType Container)) {
    throw "Learning checkpoint tests root missing: $testsRoot"
  }
  $declaredPath = if ([IO.Path]::IsPathRooted($checkpoint.testScript)) {
    $checkpoint.testScript
  } else {
    Join-Path $root $checkpoint.testScript
  }
  $candidate = Get-CanonicalPath $declaredPath
  Assert-DescendantPath -Parent $testsRoot -Candidate $candidate
  if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
    throw "Learning checkpoint testScript is not a real existing file: $candidate"
  }
  $resolvedCandidate = Get-CanonicalPath ((Resolve-Path -LiteralPath $candidate -ErrorAction Stop).Path)
  Assert-DescendantPath -Parent $testsRoot -Candidate $resolvedCandidate
  Assert-NoReparsePoint -Parent $testsRoot -Candidate $resolvedCandidate

  $timer = [Diagnostics.Stopwatch]::StartNew()
  try {
    $child = Invoke-CheckpointProcess -ScriptPath $resolvedCandidate -WorkingDirectory $root -Timeout $TimeoutMilliseconds
  } catch {
    $timer.Stop()
    [Console]::Error.WriteLine($_.Exception.Message)
    Write-Output ([pscustomobject]@{
      passed = $false
      milestone = $Milestone
      evidence = @()
      durationMs = [int64]$timer.ElapsedMilliseconds
    } | ConvertTo-Json -Depth 20 -Compress)
    exit 1
  }
  $timer.Stop()

  $evidenceLines = @($child.Stdout -split "`r?`n" | Where-Object { $_ -match '^LEARNING_EVIDENCE=' })
  # Failure is authoritative even when a checkpoint cannot emit success evidence.
  # Preserve valid legacy failure evidence, but never let malformed/missing
  # evidence hide a nonzero result and leave an earlier behavior pass usable.
  if ($child.ExitCode -ne 0) {
    $failureEvidence = @()
    if ($evidenceLines.Count -eq 1) {
      try {
        Add-Type -AssemblyName System.Web.Extensions -ErrorAction Stop
        $failureSerializer = [Web.Script.Serialization.JavaScriptSerializer]::new()
        $parsedFailureEvidence = $failureSerializer.DeserializeObject($evidenceLines[0].Substring('LEARNING_EVIDENCE='.Length))
        if ($parsedFailureEvidence -is [System.Array]) { $failureEvidence = @($parsedFailureEvidence) }
      } catch { }
    }
    if ([string]::IsNullOrWhiteSpace($child.Stderr)) {
      [Console]::Error.WriteLine("Checkpoint $Milestone failed with exit code $($child.ExitCode).")
    } else {
      [Console]::Error.Write($child.Stderr)
    }
    Write-Output ([pscustomobject]@{
      passed = $false
      milestone = $Milestone
      evidence = @($failureEvidence)
      durationMs = [int64]$timer.ElapsedMilliseconds
    } | ConvertTo-Json -Depth 20 -Compress)
    exit $child.ExitCode
  }
  if ($evidenceLines.Count -ne 1) {
    throw "Checkpoint must emit exactly one LEARNING_EVIDENCE=<json-array> line on stdout; observed $($evidenceLines.Count)."
  }
  $evidenceText = $evidenceLines[0].Substring('LEARNING_EVIDENCE='.Length)
  Add-Type -AssemblyName System.Web.Extensions -ErrorAction Stop
  $serializer = [Web.Script.Serialization.JavaScriptSerializer]::new()
  try {
    $evidence = $serializer.DeserializeObject($evidenceText)
  } catch {
    throw "Checkpoint LEARNING_EVIDENCE is malformed JSON: $($_.Exception.Message)"
  }
  if (-not ($evidence -is [System.Array])) {
    throw 'Checkpoint LEARNING_EVIDENCE JSON root must be an array.'
  }

  if (($child.ExitCode -ne 0) -and [string]::IsNullOrWhiteSpace($child.Stderr)) {
    [Console]::Error.WriteLine("Checkpoint $Milestone failed with exit code $($child.ExitCode).")
  } elseif (-not [string]::IsNullOrEmpty($child.Stderr)) {
    [Console]::Error.Write($child.Stderr)
  }
  $result = [pscustomobject]@{
    passed = ($child.ExitCode -eq 0)
    milestone = $Milestone
    evidence = @($evidence)
    durationMs = [int64]$timer.ElapsedMilliseconds
  }
  Write-Output ($result | ConvertTo-Json -Depth 20 -Compress)
  exit $child.ExitCode
} catch {
  [Console]::Error.WriteLine($_.Exception.Message)
  exit 1
}
