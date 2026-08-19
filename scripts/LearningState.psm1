function Get-LearningContext {
  param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
  )

  $root = (Resolve-Path -LiteralPath $RepositoryRoot -ErrorAction Stop).Path.TrimEnd('\', '/')
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

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "$Description missing: $Path"
  }
  Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Read-LearningProgress {
  param([Parameter(Mandatory = $true)]$Context)

  Read-LearningJson -Path $Context.ProgressPath -Description 'Learning progress'
}

function Save-LearningProgress {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)]$Progress
  )

  $progressDirectory = Split-Path -Parent $Context.ProgressPath
  New-Item -Path $progressDirectory -ItemType Directory -Force | Out-Null
  $temporaryPath = "$($Context.ProgressPath).tmp"
  try {
    $json = $Progress | ConvertTo-Json -Depth 20
    [IO.File]::WriteAllText($temporaryPath, $json, [Text.UTF8Encoding]::new($false))
    if (Test-Path -LiteralPath $Context.ProgressPath -PathType Container) {
      throw "Learning progress path is a directory: $($Context.ProgressPath)"
    }
    Move-Item -LiteralPath $temporaryPath -Destination $Context.ProgressPath -Force
  } finally {
    if (Test-Path -LiteralPath $temporaryPath) {
      Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
    }
  }
}

function Get-LearningMilestoneState {
  param(
    [Parameter(Mandatory = $true)]$Progress,
    [Parameter(Mandatory = $true)][string]$MilestoneId
  )

  $property = $Progress.milestones.PSObject.Properties[$MilestoneId]
  if ($null -eq $property) {
    throw "Unknown learning milestone: $MilestoneId"
  }
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

  if (Test-Path -LiteralPath $Context.ProgressPath -PathType Leaf) {
    return Read-LearningProgress -Context $Context
  }

  $curriculum = Read-LearningJson -Path $Context.CurriculumPath -Description 'Learning curriculum'
  $progress = Read-LearningJson -Path $Context.TemplatePath -Description 'Learning progress template'
  $progress.curriculumVersion = $curriculum.curriculumVersion
  $progress.starterRevision = $curriculum.starterRef
  $progress.referenceRevision = $curriculum.referenceRef
  Save-LearningProgress -Context $Context -Progress $progress
  $progress
}

function Start-LearningMilestone {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][string]$MilestoneId
  )

  $progress = Read-LearningProgress -Context $Context
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
  Save-LearningProgress -Context $Context -Progress $progress
  $progress
}

function Record-LearningHint {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][string]$MilestoneId,
    [Parameter(Mandatory = $true)]$Level
  )

  $integerTypes = @(
    [TypeCode]::SByte, [TypeCode]::Byte,
    [TypeCode]::Int16, [TypeCode]::UInt16,
    [TypeCode]::Int32, [TypeCode]::UInt32,
    [TypeCode]::Int64, [TypeCode]::UInt64
  )
  $levelType = if ($null -eq $Level) { [TypeCode]::Empty } else { [Type]::GetTypeCode($Level.GetType()) }
  if (($integerTypes -notcontains $levelType) -or ([decimal]$Level -lt 1) -or ([decimal]$Level -gt 5)) {
    throw 'Learning hint level must be an integer from 1 through 5.'
  }

  $progress = Read-LearningProgress -Context $Context
  $milestone = Get-ActiveLearningMilestoneState -Progress $progress -MilestoneId $MilestoneId
  if ([int]$Level -gt [int]$milestone.highestHintLevel) {
    $milestone.highestHintLevel = [int]$Level
    Save-LearningProgress -Context $Context -Progress $progress
  }
  $progress
}

function Record-LearningCheck {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][string]$MilestoneId,
    [Parameter(Mandatory = $true)][bool]$Passed,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Evidence
  )

  $progress = Read-LearningProgress -Context $Context
  $milestone = Get-ActiveLearningMilestoneState -Progress $progress -MilestoneId $MilestoneId
  $milestone.lastCheckResult = $Passed
  $milestone.lastCheckAt = [DateTime]::UtcNow.ToString('o')
  $milestone.evidenceRevision = @($Evidence)
  if ($Passed) {
    $milestone.behaviorGate = $true
  }
  Save-LearningProgress -Context $Context -Progress $progress
  $progress
}

function Record-DirectSolutionRequest {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][string]$MilestoneId
  )

  $progress = Read-LearningProgress -Context $Context
  $milestone = Get-ActiveLearningMilestoneState -Progress $progress -MilestoneId $MilestoneId
  $milestone.directSolutionRequested = $true
  Save-LearningProgress -Context $Context -Progress $progress
  $progress
}

function Complete-LearningMilestone {
  param(
    [Parameter(Mandatory = $true)]$Context,
    [Parameter(Mandatory = $true)][string]$MilestoneId,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Explanation,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$FailureMode,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$TransferEvidence
  )

  $progress = Read-LearningProgress -Context $Context
  $milestone = Get-ActiveLearningMilestoneState -Progress $progress -MilestoneId $MilestoneId
  if (-not $milestone.behaviorGate) {
    throw "Learning milestone $MilestoneId has not passed its behavior gate."
  }
  if ([string]::IsNullOrWhiteSpace($Explanation)) {
    throw 'A learner explanation is required for completion.'
  }
  if ([string]::IsNullOrWhiteSpace($FailureMode)) {
    throw 'A learner failure mode is required for completion.'
  }
  if ([string]::IsNullOrWhiteSpace($TransferEvidence)) {
    throw 'Learner transfer evidence is required for completion.'
  }

  $milestone.explanation = $Explanation
  $milestone.failureMode = $FailureMode
  $milestone.transferEvidence = $TransferEvidence
  $milestone.understandingGate = $true
  $milestone.status = 'completed'

  $curriculum = Read-LearningJson -Path $Context.CurriculumPath -Description 'Learning curriculum'
  $milestones = @($curriculum.milestones)
  $currentIndex = -1
  for ($index = 0; $index -lt $milestones.Count; $index++) {
    if ($milestones[$index].id -eq $MilestoneId) {
      $currentIndex = $index
      break
    }
  }
  if ($currentIndex -lt 0) {
    throw "Learning milestone $MilestoneId is absent from the curriculum."
  }
  if ($currentIndex -lt ($milestones.Count - 1)) {
    $successorId = $milestones[$currentIndex + 1].id
    $successor = Get-LearningMilestoneState -Progress $progress -MilestoneId $successorId
    if ($successor.status -eq 'locked') {
      $successor.status = 'available'
    }
    $progress.currentMilestone = $successorId
  }

  Save-LearningProgress -Context $Context -Progress $progress
  $progress
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
