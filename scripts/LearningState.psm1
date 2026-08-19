function Get-LearningContext {
  param([string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot))

  $root = (Resolve-Path -LiteralPath $RepositoryRoot -ErrorAction Stop).Path
  [pscustomobject]@{
    RepositoryRoot = $root
    CurriculumPath = Join-Path $root 'learning/curriculum.yaml'
    TemplatePath = Join-Path $root 'learning/progress-template.json'
    ProgressPath = Join-Path $root '.learning/progress.json'
  }
}

function Read-LearningJson {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Description
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction Stop)) {
    throw "$Description missing: $Path"
  }
  Get-Content -Raw -LiteralPath $Path -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
}

function Test-LearningInteger {
  param($Value)

  if ($null -eq $Value) { return $false }
  $integerTypes = @(
    [TypeCode]::SByte, [TypeCode]::Byte,
    [TypeCode]::Int16, [TypeCode]::UInt16,
    [TypeCode]::Int32, [TypeCode]::UInt32,
    [TypeCode]::Int64, [TypeCode]::UInt64
  )
  $integerTypes -contains [Type]::GetTypeCode($Value.GetType())
}

function Get-RequiredLearningProperty {
  param(
    [Parameter(Mandatory = $true)]$Object,
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Description
  )

  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    throw "$Description is missing required property '$Name'."
  }
  $property.Value
}

function Assert-LearningNullableString {
  param($Value, [Parameter(Mandatory = $true)][string]$Description)

  if (($null -ne $Value) -and -not ($Value -is [string])) {
    throw "$Description must be a string or null."
  }
}

function Assert-LearningProgress {
  param(
    [Parameter(Mandatory = $true)]$Progress,
    [Parameter(Mandatory = $true)]$Curriculum,
    [Parameter(Mandatory = $true)]$Template
  )

  if (-not ($Progress -is [pscustomobject])) {
    throw 'Learning progress must be a JSON object.'
  }

  $schemaVersion = Get-RequiredLearningProperty -Object $Progress -Name 'schemaVersion' -Description 'Learning progress'
  $expectedSchemaVersion = Get-RequiredLearningProperty -Object $Template -Name 'schemaVersion' -Description 'Learning progress template'
  if (-not (Test-LearningInteger $schemaVersion) -or ($schemaVersion -ne $expectedSchemaVersion)) {
    throw "Learning progress schemaVersion '$schemaVersion' is unsupported; expected '$expectedSchemaVersion'."
  }
  $curriculumVersion = Get-RequiredLearningProperty -Object $Progress -Name 'curriculumVersion' -Description 'Learning progress'
  if (-not (Test-LearningInteger $curriculumVersion) -or ($curriculumVersion -ne $Curriculum.curriculumVersion)) {
    throw "Learning progress curriculumVersion '$curriculumVersion' does not match '$($Curriculum.curriculumVersion)'."
  }

  $currentMilestone = Get-RequiredLearningProperty -Object $Progress -Name 'currentMilestone' -Description 'Learning progress'
  if (-not ($currentMilestone -is [string]) -or [string]::IsNullOrWhiteSpace($currentMilestone)) {
    throw 'Learning progress currentMilestone must be a nonblank string.'
  }
  $starterRevision = Get-RequiredLearningProperty -Object $Progress -Name 'starterRevision' -Description 'Learning progress'
  $referenceRevision = Get-RequiredLearningProperty -Object $Progress -Name 'referenceRevision' -Description 'Learning progress'
  if (($starterRevision -isnot [string]) -or ($starterRevision -cne $Curriculum.starterRef)) {
    throw 'Learning progress starterRevision does not match the curriculum starter ref.'
  }
  if (($referenceRevision -isnot [string]) -or ($referenceRevision -cne $Curriculum.referenceRef)) {
    throw 'Learning progress referenceRevision does not match the curriculum reference ref.'
  }

  $progressMilestones = Get-RequiredLearningProperty -Object $Progress -Name 'milestones' -Description 'Learning progress'
  if (-not ($progressMilestones -is [pscustomobject])) {
    throw 'Learning progress milestones must be a JSON object.'
  }
  $expectedIds = @($Curriculum.milestones | ForEach-Object { $_.id })
  $actualIds = @($progressMilestones.PSObject.Properties | ForEach-Object { $_.Name })
  if ((Compare-Object -ReferenceObject $expectedIds -DifferenceObject $actualIds).Count -ne 0) {
    throw 'Learning progress milestone structure does not match the curriculum.'
  }
  if ($expectedIds -notcontains $currentMilestone) {
    throw "Learning progress currentMilestone '$currentMilestone' is not in the curriculum."
  }

  $allowedStatuses = @('locked', 'available', 'active', 'completed')
  $activeIds = New-Object System.Collections.Generic.List[string]
  foreach ($milestoneId in $expectedIds) {
    $milestone = Get-RequiredLearningProperty -Object $progressMilestones -Name $milestoneId -Description 'Learning progress milestones'
    if (-not ($milestone -is [pscustomobject])) {
      throw "Learning milestone $milestoneId must be a JSON object."
    }
    foreach ($requiredName in @(
      'status', 'attempts', 'behaviorGate', 'understandingGate', 'highestHintLevel',
      'directSolutionRequested', 'lastCheckAt', 'lastCheckResult', 'explanation',
      'failureMode', 'transferEvidence', 'evidenceRevision', 'resumeNote'
    )) {
      $null = Get-RequiredLearningProperty -Object $milestone -Name $requiredName -Description "Learning milestone $milestoneId"
    }

    if (($milestone.status -isnot [string]) -or ($allowedStatuses -notcontains $milestone.status)) {
      throw "Learning milestone $milestoneId has invalid status '$($milestone.status)'."
    }
    if ($milestone.status -eq 'active') { $activeIds.Add($milestoneId) }
    if (-not (Test-LearningInteger $milestone.attempts) -or ([decimal]$milestone.attempts -lt 0)) {
      throw "Learning milestone $milestoneId attempts must be a nonnegative integer."
    }
    if (-not (Test-LearningInteger $milestone.highestHintLevel) -or
        ([decimal]$milestone.highestHintLevel -lt 0) -or
        ([decimal]$milestone.highestHintLevel -gt 5)) {
      throw "Learning milestone $milestoneId highestHintLevel must be an integer from 0 through 5."
    }
    foreach ($booleanName in @('behaviorGate', 'understandingGate', 'directSolutionRequested')) {
      if (-not ($milestone.$booleanName -is [bool])) {
        throw "Learning milestone $milestoneId $booleanName must be a Boolean."
      }
    }
    if (($null -ne $milestone.lastCheckResult) -and -not ($milestone.lastCheckResult -is [bool])) {
      throw "Learning milestone $milestoneId lastCheckResult must be a Boolean or null."
    }
    if (($null -ne $milestone.lastCheckResult) -and ($milestone.behaviorGate -ne $milestone.lastCheckResult)) {
      throw "Learning milestone $milestoneId behaviorGate must match lastCheckResult."
    }

    if ($null -ne $milestone.lastCheckAt) {
      if (-not ($milestone.lastCheckAt -is [string])) {
        throw "Learning milestone $milestoneId lastCheckAt must be a UTC timestamp string or null."
      }
      $parsedTimestamp = [DateTimeOffset]::MinValue
      if (-not [DateTimeOffset]::TryParse($milestone.lastCheckAt, [ref]$parsedTimestamp) -or
          ($parsedTimestamp.Offset -ne [TimeSpan]::Zero)) {
        throw "Learning milestone $milestoneId lastCheckAt must be a valid UTC timestamp."
      }
    }
    foreach ($textName in @('explanation', 'failureMode', 'transferEvidence', 'resumeNote')) {
      Assert-LearningNullableString -Value $milestone.$textName -Description "Learning milestone $milestoneId $textName"
    }
    if (($null -ne $milestone.evidenceRevision) -and -not ($milestone.evidenceRevision -is [System.Array])) {
      throw "Learning milestone $milestoneId evidenceRevision must be an array or null."
    }
    if (($milestone.status -eq 'completed') -and
        ((-not $milestone.behaviorGate) -or (-not $milestone.understandingGate))) {
      throw "Completed learning milestone $milestoneId must have both gates passed."
    }
    if (($milestone.status -ne 'completed') -and $milestone.understandingGate) {
      throw "Incomplete learning milestone $milestoneId cannot have a passed understanding gate."
    }
  }

  if (($activeIds.Count -gt 1) -or (($activeIds.Count -eq 1) -and ($activeIds[0] -ne $currentMilestone))) {
    throw 'Learning progress may have only its current milestone active.'
  }
  $currentState = $progressMilestones.PSObject.Properties[$currentMilestone].Value
  $isTerminalCompletion = ($currentMilestone -eq $expectedIds[-1]) -and ($currentState.status -eq 'completed')
  if (($currentState.status -notin @('available', 'active')) -and -not $isTerminalCompletion) {
    throw "Learning progress current milestone $currentMilestone has invalid status '$($currentState.status)'."
  }
}

function Read-LearningProgress {
  param([Parameter(Mandatory = $true)]$Context)

  $progress = Read-LearningJson -Path $Context.ProgressPath -Description 'Learning progress'
  $curriculum = Read-LearningJson -Path $Context.CurriculumPath -Description 'Learning curriculum'
  $template = Read-LearningJson -Path $Context.TemplatePath -Description 'Learning progress template'
  Assert-LearningProgress -Progress $progress -Curriculum $curriculum -Template $template
  $progress
}

function Get-LearningProgressLockName {
  param([Parameter(Mandatory = $true)]$Context)

  $canonicalPath = [IO.Path]::GetFullPath([string]$Context.ProgressPath).ToUpperInvariant()
  $sha256 = [Security.Cryptography.SHA256]::Create()
  try {
    $hash = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonicalPath))
  } finally {
    $sha256.Dispose()
  }
  $hex = -join @($hash | ForEach-Object { $_.ToString('x2') })
  "Local\SalesFlowLearningProgress-$hex"
}

function Get-LearningLockTimeout {
  param([Parameter(Mandatory = $true)]$Context)

  $timeout = 5000
  $property = $Context.PSObject.Properties['LockTimeoutMilliseconds']
  if ($null -ne $property) {
    if (-not (Test-LearningInteger $property.Value) -or
        ([decimal]$property.Value -lt 1) -or
        ([decimal]$property.Value -gt 60000)) {
      throw 'LockTimeoutMilliseconds must be an integer from 1 through 60000.'
    }
    $timeout = [int]$property.Value
  }
  $timeout
}

function Invoke-WithLearningProgressLock {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][scriptblock]$Action
  )

  $lockName = Get-LearningProgressLockName -Context $Context
  $timeout = Get-LearningLockTimeout -Context $Context
  $mutex = [Threading.Mutex]::new($false, $lockName)
  $acquired = $false
  try {
    try {
      $acquired = $mutex.WaitOne($timeout)
    } catch [Threading.AbandonedMutexException] {
      $acquired = $true
    }
    if (-not $acquired) {
      throw "Timed out waiting for learning progress lock after $timeout ms: $($Context.ProgressPath)"
    }
    & $Action $Context
  } finally {
    try {
      if ($acquired) { $mutex.ReleaseMutex() }
    } finally {
      $mutex.Dispose()
    }
  }
}

function Save-LearningProgress {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)]$Progress
  )

  $progressDirectory = Split-Path -Parent $Context.ProgressPath
  New-Item -Path $progressDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
  $temporaryPath = "$($Context.ProgressPath).$([guid]::NewGuid().ToString('N')).tmp"
  try {
    $json = $Progress | ConvertTo-Json -Depth 20
    [IO.File]::WriteAllText($temporaryPath, $json, [Text.UTF8Encoding]::new($false))
    if (Test-Path -LiteralPath $Context.ProgressPath -PathType Container -ErrorAction Stop) {
      throw "Learning progress path is a directory: $($Context.ProgressPath)"
    }
    Move-Item -LiteralPath $temporaryPath -Destination $Context.ProgressPath -Force -ErrorAction Stop
  } catch {
    $detail = $_.Exception.Message
    $retained = Test-Path -LiteralPath $temporaryPath -PathType Leaf -ErrorAction Stop
    if ($retained) {
      throw "Failed to persist learning progress. Diagnostic temp retained at $temporaryPath. $detail"
    }
    throw "Failed to persist learning progress; no diagnostic temp was created at $temporaryPath. $detail"
  }
}

function Get-LearningMilestoneState {
  param(
    [Parameter(Mandatory = $true)]$Progress,
    [Parameter(Mandatory = $true)][string]$MilestoneId
  )

  $property = $Progress.milestones.PSObject.Properties[$MilestoneId]
  if ($null -eq $property) { throw "Unknown learning milestone: $MilestoneId" }
  $property.Value
}

function Get-ActiveLearningMilestoneState {
  param(
    [Parameter(Mandatory = $true)]$Progress,
    [Parameter(Mandatory = $true)][string]$MilestoneId
  )

  $milestone = Get-LearningMilestoneState -Progress $Progress -MilestoneId $MilestoneId
  if (($milestone.status -ne 'active') -or ($Progress.currentMilestone -ne $MilestoneId)) {
    throw "Learning milestone $MilestoneId is not the active milestone."
  }
  $milestone
}

function Initialize-LearningProgress {
  param([Parameter(Mandatory = $true)]$Context)

  Invoke-WithLearningProgressLock -Context $Context -Action {
    param($lockedContext)
    if (Test-Path -LiteralPath $lockedContext.ProgressPath -PathType Leaf -ErrorAction Stop) {
      return Read-LearningProgress -Context $lockedContext
    }
    $curriculum = Read-LearningJson -Path $lockedContext.CurriculumPath -Description 'Learning curriculum'
    $template = Read-LearningJson -Path $lockedContext.TemplatePath -Description 'Learning progress template'
    $progress = Read-LearningJson -Path $lockedContext.TemplatePath -Description 'Learning progress template'
    $progress.curriculumVersion = $curriculum.curriculumVersion
    $progress.starterRevision = $curriculum.starterRef
    $progress.referenceRevision = $curriculum.referenceRef
    Assert-LearningProgress -Progress $progress -Curriculum $curriculum -Template $template
    Save-LearningProgress -Context $lockedContext -Progress $progress
    $progress
  }
}

function Start-LearningMilestone {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][string]$MilestoneId
  )

  Invoke-WithLearningProgressLock -Context $Context -Action {
    param($lockedContext)
    $progress = Read-LearningProgress -Context $lockedContext
    $milestone = Get-LearningMilestoneState -Progress $progress -MilestoneId $MilestoneId
    if ($milestone.status -eq 'active') {
      if ($progress.currentMilestone -ne $MilestoneId) {
        throw "Learning milestone $MilestoneId is not the current active milestone."
      }
      return $progress
    }
    if ($milestone.status -ne 'available') {
      throw "Learning milestone $MilestoneId cannot start from status '$($milestone.status)'."
    }
    $milestone.status = 'active'
    $milestone.attempts = [int]$milestone.attempts + 1
    $progress.currentMilestone = $MilestoneId
    Save-LearningProgress -Context $lockedContext -Progress $progress
    $progress
  }
}

function Record-LearningHint {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][string]$MilestoneId,
    [Parameter(Mandatory = $true)]$Level
  )

  if (-not (Test-LearningInteger $Level) -or ([decimal]$Level -lt 1) -or ([decimal]$Level -gt 5)) {
    throw 'Learning hint level must be an integer from 1 through 5.'
  }
  Invoke-WithLearningProgressLock -Context $Context -Action {
    param($lockedContext)
    $progress = Read-LearningProgress -Context $lockedContext
    $milestone = Get-ActiveLearningMilestoneState -Progress $progress -MilestoneId $MilestoneId
    if ([int]$Level -gt [int]$milestone.highestHintLevel) {
      $milestone.highestHintLevel = [int]$Level
      Save-LearningProgress -Context $lockedContext -Progress $progress
    }
    $progress
  }
}

function Record-LearningCheck {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][string]$MilestoneId,
    [Parameter(Mandatory = $true)][bool]$Passed,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Evidence
  )

  Invoke-WithLearningProgressLock -Context $Context -Action {
    param($lockedContext)
    $progress = Read-LearningProgress -Context $lockedContext
    $milestone = Get-ActiveLearningMilestoneState -Progress $progress -MilestoneId $MilestoneId
    $milestone.lastCheckResult = $Passed
    $milestone.lastCheckAt = [DateTime]::UtcNow.ToString('o')
    $milestone.evidenceRevision = @($Evidence)
    $milestone.behaviorGate = $Passed
    Save-LearningProgress -Context $lockedContext -Progress $progress
    $progress
  }
}

function Record-DirectSolutionRequest {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][string]$MilestoneId
  )

  Invoke-WithLearningProgressLock -Context $Context -Action {
    param($lockedContext)
    $progress = Read-LearningProgress -Context $lockedContext
    $milestone = Get-ActiveLearningMilestoneState -Progress $progress -MilestoneId $MilestoneId
    $milestone.directSolutionRequested = $true
    Save-LearningProgress -Context $lockedContext -Progress $progress
    $progress
  }
}

function Complete-LearningMilestone {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][string]$MilestoneId,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Explanation,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$FailureMode,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$TransferEvidence
  )

  Invoke-WithLearningProgressLock -Context $Context -Action {
    param($lockedContext)
    $progress = Read-LearningProgress -Context $lockedContext
    $milestone = Get-ActiveLearningMilestoneState -Progress $progress -MilestoneId $MilestoneId
    if ((-not ($milestone.behaviorGate -is [bool])) -or
        ($milestone.behaviorGate -ne $true) -or
        (-not ($milestone.lastCheckResult -is [bool])) -or
        ($milestone.lastCheckResult -ne $true)) {
      throw "Learning milestone $MilestoneId has not passed its latest behavior check."
    }
    if ([string]::IsNullOrWhiteSpace($Explanation)) { throw 'A learner explanation is required for completion.' }
    if ([string]::IsNullOrWhiteSpace($FailureMode)) { throw 'A learner failure mode is required for completion.' }
    if ([string]::IsNullOrWhiteSpace($TransferEvidence)) { throw 'Learner transfer evidence is required for completion.' }

    $milestone.explanation = $Explanation
    $milestone.failureMode = $FailureMode
    $milestone.transferEvidence = $TransferEvidence
    $milestone.understandingGate = $true
    $milestone.status = 'completed'
    $curriculum = Read-LearningJson -Path $lockedContext.CurriculumPath -Description 'Learning curriculum'
    $milestones = @($curriculum.milestones)
    $currentIndex = -1
    for ($index = 0; $index -lt $milestones.Count; $index++) {
      if ($milestones[$index].id -eq $MilestoneId) { $currentIndex = $index; break }
    }
    if ($currentIndex -lt 0) { throw "Learning milestone $MilestoneId is absent from the curriculum." }
    if ($currentIndex -lt ($milestones.Count - 1)) {
      $successorId = $milestones[$currentIndex + 1].id
      $successor = Get-LearningMilestoneState -Progress $progress -MilestoneId $successorId
      if ($successor.status -eq 'locked') { $successor.status = 'available' }
      $progress.currentMilestone = $successorId
    }
    Save-LearningProgress -Context $lockedContext -Progress $progress
    $progress
  }
}

Export-ModuleMember -Function @(
  'Get-LearningContext',
  'Initialize-LearningProgress',
  'Start-LearningMilestone',
  'Record-LearningCheck',
  'Record-LearningHint',
  'Record-DirectSolutionRequest',
  'Complete-LearningMilestone'
)
