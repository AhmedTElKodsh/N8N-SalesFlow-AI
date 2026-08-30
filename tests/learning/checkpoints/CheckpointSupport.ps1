Set-StrictMode -Version 2.0

function Assert-CheckpointInvariant {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)]
    [ValidateSet(
      'Environment or tooling failure',
      'Syntax or integration failure',
      'Behavioral checkpoint failure',
      'Conceptual misunderstanding',
      'Curriculum or checkpoint defect'
    )]
    [string]$Classification,
    [Parameter(Mandatory = $true)][string]$Invariant,
    [Parameter(Mandatory = $true)][string]$Observed,
    [Parameter(Mandatory = $true)][string]$Location
  )

  if ($Condition) { return }
  $safeObserved = ($Observed -replace '[\r\n]+', ' ').Trim()
  throw [InvalidOperationException]::new(
    "$Classification`: Invariant=$Invariant; Observed=$safeObserved; Location=$Location"
  )
}

function Resolve-CheckpointRepositoryRoot {
  param([string]$RepositoryRoot = (Get-Location).Path)

  if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = (Get-Location).Path
  }
  $exists = Test-Path -LiteralPath $RepositoryRoot -PathType Container
  Assert-CheckpointInvariant $exists 'Environment or tooling failure' 'repository root exists and is a directory' "missing-or-not-directory:$RepositoryRoot" $RepositoryRoot
  (Resolve-Path -LiteralPath $RepositoryRoot -ErrorAction Stop).Path
}

function Resolve-CheckpointPath {
  param(
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [ValidateSet('Leaf', 'Container')][string]$PathType = 'Leaf'
  )

  $rootPath = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
  )
  $candidate = [IO.Path]::GetFullPath((Join-Path $rootPath $RelativePath))
  $boundary = $rootPath + [IO.Path]::DirectorySeparatorChar
  $inside = $candidate.StartsWith($boundary, [StringComparison]::OrdinalIgnoreCase)
  Assert-CheckpointInvariant $inside 'Curriculum or checkpoint defect' 'checkpoint artifact remains inside repository root' $candidate $RelativePath

  $current = $rootPath
  foreach ($segment in @($RelativePath -split '[\\/]' | Where-Object { $_ -notin @('', '.') })) {
    $current = Join-Path $current $segment
    if (-not (Test-Path -LiteralPath $current)) { break }
    $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
    $isReparsePoint = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    Assert-CheckpointInvariant (-not $isReparsePoint) 'Curriculum or checkpoint defect' 'checkpoint paths contain no reparse points' "reparse-point:$current" $RelativePath
  }

  $exists = if ($PathType -eq 'Container') {
    Test-Path -LiteralPath $candidate -PathType Container
  } else {
    Test-Path -LiteralPath $candidate -PathType Leaf
  }
  Assert-CheckpointInvariant $exists 'Syntax or integration failure' 'required checkpoint artifact exists' "missing:$RelativePath" $candidate
  $candidate
}

function Read-CheckpointText {
  param(
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [Parameter(Mandatory = $true)][string]$RelativePath
  )

  $path = Resolve-CheckpointPath $RepositoryRoot $RelativePath
  Get-Content -Raw -LiteralPath $path -ErrorAction Stop
}

function Read-CheckpointJson {
  param(
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [Parameter(Mandatory = $true)][string]$RelativePath
  )

  $path = Resolve-CheckpointPath $RepositoryRoot $RelativePath
  try {
    $value = Get-Content -Raw -LiteralPath $path -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
  } catch {
    Assert-CheckpointInvariant $false 'Syntax or integration failure' 'JSON artifact parses structurally' $_.Exception.Message $path
  }
  Assert-CheckpointInvariant ($null -ne $value) 'Syntax or integration failure' 'JSON artifact contains a value' 'parsed-null' $path
  $value
}

function Read-CheckpointSql {
  param(
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [string]$RelativePath = 'database/001-initial.sql'
  )

  Read-CheckpointText $RepositoryRoot $RelativePath
}

function Get-SqlCreateTableBlock {
  param(
    [Parameter(Mandatory = $true)][string]$Sql,
    [Parameter(Mandatory = $true)][string]$TableName,
    [string]$Location = 'database/001-initial.sql'
  )

  $pattern = '(?is)CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?' +
    [regex]::Escape($TableName) + '\s*\((?<Body>.*?)\);'
  $match = [regex]::Match($Sql, $pattern)
  Assert-CheckpointInvariant $match.Success 'Behavioral checkpoint failure' "migration declares table $TableName" 'table-definition-not-found' $Location
  $match.Groups['Body'].Value
}

function Get-SqlFunctionBlock {
  param(
    [Parameter(Mandatory = $true)][string]$Sql,
    [Parameter(Mandatory = $true)][string]$FunctionName,
    [string]$Location = 'database/001-initial.sql'
  )

  $pattern = '(?is)CREATE\s+OR\s+REPLACE\s+FUNCTION\s+' +
    [regex]::Escape($FunctionName) + '\b.*?\$\$;'
  $matches = [regex]::Matches($Sql, $pattern)
  Assert-CheckpointInvariant ($matches.Count -gt 0) 'Behavioral checkpoint failure' "migration declares function $FunctionName" 'function-definition-not-found' $Location
  $matches[$matches.Count - 1].Value
}

function Get-WorkflowNodesByType {
  param(
    [Parameter(Mandatory = $true)]$Workflow,
    [Parameter(Mandatory = $true)][string]$Type
  )

  @($Workflow.nodes | Where-Object { [string]$_.type -eq $Type })
}

function Get-WorkflowReachableNodeNames {
  param(
    [Parameter(Mandatory = $true)]$Workflow,
    [Parameter(Mandatory = $true)][string]$StartNodeName
  )

  $nodeNames = @($Workflow.nodes | ForEach-Object { [string]$_.name })
  Assert-CheckpointInvariant ($nodeNames -contains $StartNodeName) 'Behavioral checkpoint failure' 'workflow traversal starts from an existing node' "missing-node:$StartNodeName" 'workflow.nodes'

  $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $queue = [Collections.Generic.Queue[string]]::new()
  [void]$seen.Add($StartNodeName)
  $queue.Enqueue($StartNodeName)

  while ($queue.Count -gt 0) {
    $current = $queue.Dequeue()
    $sourceProperty = $Workflow.connections.PSObject.Properties[$current]
    if ($null -eq $sourceProperty) { continue }
    foreach ($channel in $sourceProperty.Value.PSObject.Properties) {
      foreach ($branch in @($channel.Value)) {
        foreach ($edge in @($branch)) {
          if ($null -eq $edge -or $null -eq $edge.PSObject.Properties['node']) { continue }
          $target = [string]$edge.node
          if ($seen.Add($target)) { $queue.Enqueue($target) }
        }
      }
    }
  }

  @($seen | Sort-Object)
}

function Get-WorkflowBranchTargetNames {
  param(
    [Parameter(Mandatory = $true)]$Workflow,
    [Parameter(Mandatory = $true)][string]$SourceNodeName,
    [Parameter(Mandatory = $true)][int]$BranchIndex
  )

  $source = $Workflow.connections.PSObject.Properties[$SourceNodeName]
  if ($null -eq $source) { return @() }
  $main = $source.Value.PSObject.Properties['main']
  if ($null -eq $main -or $BranchIndex -ge @($main.Value).Count) { return @() }
  @(@($main.Value)[$BranchIndex] | Where-Object { $null -ne $_ } | ForEach-Object { [string]$_.node })
}

function Assert-WorkflowPath {
  param(
    [Parameter(Mandatory = $true)]$Workflow,
    [Parameter(Mandatory = $true)][string]$From,
    [Parameter(Mandatory = $true)][string]$To,
    [Parameter(Mandatory = $true)][string]$Location
  )

  $reachable = @(Get-WorkflowReachableNodeNames $Workflow $From)
  Assert-CheckpointInvariant ($reachable -contains $To) 'Behavioral checkpoint failure' "workflow dataflow reaches $To from $From" ("reachable=" + ($reachable -join ',')) $Location
}

function ConvertTo-NativeQuotedArgument {
  param([Parameter(Mandatory = $true)][string]$Value)
  $escaped = $Value -replace '(\\*)"', '$1$1\"'
  $escaped = $escaped -replace '(\\+)$', '$1$1'
  '"' + $escaped + '"'
}

function Invoke-NativeCaptured {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [string[]]$Arguments = @(),
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [int]$TimeoutMilliseconds = 600000
  )

  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $FilePath
  $startInfo.Arguments = (@($Arguments | ForEach-Object { ConvertTo-NativeQuotedArgument ([string]$_) }) -join ' ')
  $startInfo.WorkingDirectory = $WorkingDirectory
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  try {
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutMilliseconds)) {
      try { $process.Kill() } catch {}
      $process.WaitForExit()
      throw [TimeoutException]::new("native command exceeded $TimeoutMilliseconds ms: $FilePath")
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

function Assert-NativeSuccess {
  param(
    [Parameter(Mandatory = $true)]$Result,
    [Parameter(Mandatory = $true)][string]$Invariant,
    [Parameter(Mandatory = $true)][string]$Location
  )

  $observed = "exit=$($Result.ExitCode); stderr=$($Result.Stderr.Trim())"
  Assert-CheckpointInvariant ($Result.ExitCode -eq 0) 'Environment or tooling failure' $Invariant $observed $Location
}

function Assert-GitRepository {
  param([Parameter(Mandatory = $true)][string]$RepositoryRoot)

  $git = Get-Command git.exe -ErrorAction SilentlyContinue
  if ($null -eq $git) { $git = Get-Command git -ErrorAction SilentlyContinue }
  Assert-CheckpointInvariant ($null -ne $git) 'Environment or tooling failure' 'Git executable is available' 'git-command-not-found' $RepositoryRoot
  $result = Invoke-NativeCaptured $git.Source @('rev-parse', '--is-inside-work-tree') $RepositoryRoot
  Assert-NativeSuccess $result 'repository root is a Git working tree' $RepositoryRoot
  Assert-CheckpointInvariant ($result.Stdout.Trim() -eq 'true') 'Behavioral checkpoint failure' 'Git identifies the repository root as inside a working tree' $result.Stdout.Trim() $RepositoryRoot
}

function Write-CheckpointFailure {
  param(
    [Parameter(Mandatory = $true)]$ErrorRecord,
    [string]$FallbackLocation = 'checkpoint'
  )

  $message = [string]$ErrorRecord.Exception.Message
  $classified = $message -match '^(?:Environment or tooling failure|Syntax or integration failure|Behavioral checkpoint failure|Conceptual misunderstanding|Curriculum or checkpoint defect):\s+Invariant='
  if (-not $classified) {
    $message = "Syntax or integration failure: Invariant=checkpoint executes without unexpected error; Observed=$($message -replace '[\r\n]+',' '); Location=$FallbackLocation"
  }
  [Console]::Error.WriteLine($message)
}

function Write-LearningEvidence {
  param([Parameter(Mandatory = $true)][string[]]$Evidence)

  Assert-CheckpointInvariant ($Evidence.Count -gt 0) 'Curriculum or checkpoint defect' 'success evidence array is nonempty' 'empty-array' 'checkpoint evidence'
  $json = ConvertTo-Json -InputObject @($Evidence) -Compress
  Write-Output "LEARNING_EVIDENCE=$json"
}
