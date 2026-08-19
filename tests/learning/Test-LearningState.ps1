. "$PSScriptRoot/TestSupport.ps1"

$modulePath = Join-Path $PSScriptRoot '../../scripts/LearningState.psm1'
Import-Module $modulePath -Force -ErrorAction Stop

function Assert-Throws([scriptblock]$Action, [string]$Message) {
  $threw = $false
  try {
    & $Action
  } catch {
    $threw = $true
  }
  Assert-True $threw $Message
}

function Read-Progress($Context) {
  Get-Content -Raw -LiteralPath $Context.ProgressPath | ConvertFrom-Json
}

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$temp = Join-Path ([IO.Path]::GetTempPath()) ("salesflow-learning-" + [guid]::NewGuid())
New-Item -Path $temp -ItemType Directory | Out-Null

try {
  Copy-Item -LiteralPath (Join-Path $root 'learning') -Destination $temp -Recurse
  $ctx = Get-LearningContext -RepositoryRoot $temp

  Assert-Equal $ctx.RepositoryRoot ([IO.Path]::GetFullPath($temp).TrimEnd('\', '/')) 'context resolves repository root'
  Assert-Equal $ctx.CurriculumPath (Join-Path $ctx.RepositoryRoot 'learning/curriculum.yaml') 'context resolves curriculum path'
  Assert-Equal $ctx.TemplatePath (Join-Path $ctx.RepositoryRoot 'learning/progress-template.json') 'context resolves template path'
  Assert-Equal $ctx.ProgressPath (Join-Path $ctx.RepositoryRoot '.learning/progress.json') 'context resolves progress path'

  $null = Initialize-LearningProgress -Context $ctx
  $p = Read-Progress $ctx
  $curriculum = Get-Content -Raw -LiteralPath $ctx.CurriculumPath | ConvertFrom-Json
  Assert-Equal $p.currentMilestone 'M00' 'initial milestone'
  Assert-Equal $p.curriculumVersion $curriculum.curriculumVersion 'initialization records curriculum version'
  Assert-Equal $p.starterRevision $curriculum.starterRef 'initialization records starter ref'
  Assert-Equal $p.referenceRevision $curriculum.referenceRef 'initialization records reference ref'
  Assert-True (-not (Test-Path -LiteralPath "$($ctx.ProgressPath).tmp")) 'initialization removes atomic temp file'
  $bytes = [IO.File]::ReadAllBytes($ctx.ProgressPath)
  $hasUtf8Bom = ($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
  Assert-True (-not $hasUtf8Bom) 'progress is UTF-8 without BOM'

  $invalidProgressPath = Join-Path $temp '.learning/cannot-replace'
  New-Item -Path $invalidProgressPath -ItemType Directory | Out-Null
  $invalidContext = [pscustomobject]@{
    RepositoryRoot = $ctx.RepositoryRoot
    CurriculumPath = $ctx.CurriculumPath
    TemplatePath = $ctx.TemplatePath
    ProgressPath = $invalidProgressPath
  }
  Assert-Throws { Initialize-LearningProgress -Context $invalidContext } 'atomic persistence rejects a directory destination'
  Assert-True (-not (Test-Path -LiteralPath "$invalidProgressPath.tmp")) 'failed atomic persistence removes temp file'
  Assert-Equal @(Get-ChildItem -LiteralPath $invalidProgressPath -Force).Count 0 'failed atomic persistence leaves destination directory unchanged'
  Remove-Item -LiteralPath $invalidProgressPath -Recurse -Force

  $beforeRejectedStart = Get-Content -Raw -LiteralPath $ctx.ProgressPath
  Assert-Throws { Start-LearningMilestone -Context $ctx -MilestoneId M02 } 'locked milestone rejected'
  Assert-Throws { Start-LearningMilestone -Context $ctx -MilestoneId M99 } 'unknown milestone rejected'
  Assert-Throws { Record-LearningHint -Context $ctx -MilestoneId M02 -Level 1 } 'hint for inactive milestone rejected'
  Assert-Throws { Record-LearningCheck -Context $ctx -MilestoneId M02 -Passed $true -Evidence @('invalid') } 'check for inactive milestone rejected'
  Assert-Throws { Record-DirectSolutionRequest -Context $ctx -MilestoneId M02 } 'direct solution for inactive milestone rejected'
  Assert-True ((Get-Content -Raw -LiteralPath $ctx.ProgressPath) -ceq $beforeRejectedStart) 'rejected starts do not persist changes'
  Assert-True (-not (Test-Path -LiteralPath "$($ctx.ProgressPath).tmp")) 'rejected starts leave no atomic temp file'

  $null = Start-LearningMilestone -Context $ctx -MilestoneId M00
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.status 'active' 'available milestone becomes active'
  Assert-Equal $p.milestones.M00.attempts 1 'first start increments attempts'

  $null = Start-LearningMilestone -Context $ctx -MilestoneId M00
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.status 'active' 'starting same active milestone is idempotent'
  Assert-Equal $p.milestones.M00.attempts 1 'idempotent active start does not increment attempts'
  $null = Initialize-LearningProgress -Context $ctx
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.status 'active' 'reinitialization preserves durable progress'
  Assert-Equal $p.milestones.M00.attempts 1 'reinitialization preserves attempt count'

  Assert-Throws { Record-LearningHint -Context $ctx -MilestoneId M00 -Level 0 } 'hint level below one rejected'
  Assert-Throws { Record-LearningHint -Context $ctx -MilestoneId M00 -Level 6 } 'hint level above five rejected'
  Assert-Throws { Record-LearningHint -Context $ctx -MilestoneId M00 -Level 1.5 } 'fractional hint level rejected'
  $null = Record-LearningHint -Context $ctx -MilestoneId M00 -Level 3
  $null = Record-LearningHint -Context $ctx -MilestoneId M00 -Level 1
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.highestHintLevel 3 'hint recording retains maximum level'

  $null = Record-LearningCheck -Context $ctx -MilestoneId M00 -Passed $false -Evidence @('orientation-failed')
  $p = Read-Progress $ctx
  Assert-True (-not $p.milestones.M00.behaviorGate) 'failed check does not pass behavior gate'
  Assert-True (-not $p.milestones.M00.understandingGate) 'failed check does not pass understanding gate'
  Assert-Equal $p.milestones.M00.lastCheckResult $false 'failed check result recorded'
  Assert-Equal (@($p.milestones.M00.evidenceRevision) -join ',') 'orientation-failed' 'failed check evidence recorded'
  Assert-True (-not [string]::IsNullOrWhiteSpace($p.milestones.M00.lastCheckAt)) 'failed check timestamp recorded'
  Assert-Throws {
    Complete-LearningMilestone -Context $ctx -MilestoneId M00 -Explanation 'x' -FailureMode 'y' -TransferEvidence 'z'
  } 'completion rejects false behavior gate'

  $null = Record-DirectSolutionRequest -Context $ctx -MilestoneId M00
  $p = Read-Progress $ctx
  Assert-True $p.milestones.M00.directSolutionRequested 'direct-solution request recorded'
  Assert-Equal $p.milestones.M00.status 'active' 'direct-solution request does not complete milestone'
  Assert-True (-not $p.milestones.M00.behaviorGate) 'direct-solution request does not pass behavior gate'
  Assert-True (-not $p.milestones.M00.understandingGate) 'direct-solution request does not pass understanding gate'

  $null = Record-LearningCheck -Context $ctx -MilestoneId M00 -Passed $true -Evidence @('orientation-ok')
  $p = Read-Progress $ctx
  Assert-True $p.milestones.M00.behaviorGate 'passed check passes behavior gate'
  Assert-True (-not $p.milestones.M00.understandingGate) 'passed check does not pass understanding gate'
  Assert-Equal $p.milestones.M00.lastCheckResult $true 'passed check result recorded'
  Assert-Equal (@($p.milestones.M00.evidenceRevision) -join ',') 'orientation-ok' 'passed check evidence recorded'
  Assert-True (-not [string]::IsNullOrWhiteSpace($p.milestones.M00.lastCheckAt)) 'passed check timestamp recorded'

  foreach ($understanding in @(
    @{ Explanation = ' '; FailureMode = 'failure'; TransferEvidence = 'transfer'; Label = 'blank explanation' },
    @{ Explanation = 'explanation'; FailureMode = "`t"; TransferEvidence = 'transfer'; Label = 'blank failure mode' },
    @{ Explanation = 'explanation'; FailureMode = 'failure'; TransferEvidence = ''; Label = 'blank transfer evidence' }
  )) {
    Assert-Throws {
      Complete-LearningMilestone -Context $ctx -MilestoneId M00 -Explanation $understanding.Explanation -FailureMode $understanding.FailureMode -TransferEvidence $understanding.TransferEvidence
    } "completion rejects $($understanding.Label)"
  }
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.status 'active' 'rejected completion leaves milestone active'
  Assert-Equal $p.milestones.M01.status 'locked' 'rejected completion does not unlock successor'

  $explanation = 'n8n routes;  PostgreSQL owns durable state'
  $failureMode = 'Workflow succeeds but persistence fails'
  $transferEvidence = 'Mapped a second webhook without rewriting the answer'
  $null = Complete-LearningMilestone -Context $ctx -MilestoneId M00 -Explanation $explanation -FailureMode $failureMode -TransferEvidence $transferEvidence
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.status 'completed' 'M00 completed'
  Assert-True $p.milestones.M00.understandingGate 'completion passes understanding gate'
  Assert-Equal $p.milestones.M00.highestHintLevel 3 'completion preserves highest hint'
  Assert-Equal $p.milestones.M00.explanation $explanation 'completion preserves learner explanation exactly'
  Assert-Equal $p.milestones.M00.failureMode $failureMode 'completion preserves learner failure mode exactly'
  Assert-Equal $p.milestones.M00.transferEvidence $transferEvidence 'completion preserves learner transfer evidence exactly'
  Assert-Equal $p.currentMilestone 'M01' 'next milestone becomes current'
  Assert-Equal $p.milestones.M01.status 'available' 'immediate successor becomes available'
  Assert-Equal $p.milestones.M02.status 'locked' 'completion does not unlock later successors'
  Assert-True (-not (Test-Path -LiteralPath "$($ctx.ProgressPath).tmp")) 'completion removes atomic temp file'

  Assert-Throws { Start-LearningMilestone -Context $ctx -MilestoneId M00 } 'completed milestone cannot restart'
  Assert-Throws { Start-LearningMilestone -Context $ctx -MilestoneId M02 } 'still-locked later milestone rejected'
  $null = Start-LearningMilestone -Context $ctx -MilestoneId M01
  $null = Start-LearningMilestone -Context $ctx -MilestoneId M01
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M01.attempts 1 'successor active start remains idempotent'
} finally {
  Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}

Assert-True (-not (Test-Path -LiteralPath $temp)) 'temporary learning workspace removed'
Complete-TestFile
