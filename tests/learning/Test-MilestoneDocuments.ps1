param([ValidateSet('M05','M10')][string]$Through = 'M10')
. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$curriculum = Get-Content -Raw "$root/learning/curriculum.yaml" | ConvertFrom-Json
$lastIndex = [int]$Through.Substring(1)

function Get-OneActionPowerShellCommand([string]$StageBody) {
  $visibleBody = [regex]::Replace($StageBody, '(?s)<!--.*?(?:-->|\z)', '')
  $visibleBody = [regex]::Replace($visibleBody, '(?is)<(?<Tag>[a-z][a-z0-9-]*)\b[^>]*>.*?</\k<Tag>\s*>', '')
  $visibleLines = New-Object System.Collections.Generic.List[string]
  $insideCodeFence = $false
  $fenceCharacter = $null
  $fenceLength = 0
  foreach ($line in [regex]::Split($visibleBody, '\r?\n')) {
    if (-not $insideCodeFence -and $line -match '^[ \t]*(?<Marker>`{3,}|~{3,})') {
      $insideCodeFence = $true
      $fenceCharacter = $Matches['Marker'].Substring(0, 1)
      $fenceLength = $Matches['Marker'].Length
      continue
    }
    if ($insideCodeFence) {
      $closingFencePattern = '^[ \t]*' + [regex]::Escape($fenceCharacter) + '{' + $fenceLength + ',}[ \t]*$'
      if ($line -match $closingFencePattern) {
        $insideCodeFence = $false
        $fenceCharacter = $null
        $fenceLength = 0
      }
      continue
    }

    $visibleLines.Add($line)
  }

  $actionMatches = [regex]::Matches(($visibleLines -join "`n"), '(?m)^\*\*One action:\*\* Run `(?<Command>[^`\r\n]+)`\.$')
  if ($actionMatches.Count -ne 1) {
    return $null
  }

  return $actionMatches[0].Groups['Command'].Value
}

function Test-M00StarterAncestryCommand([string]$Command) {
  if ([string]::IsNullOrWhiteSpace($Command)) {
    return $false
  }

  $tokens = $null
  $parseErrors = $null
  $commandAst = [System.Management.Automation.Language.Parser]::ParseInput(
    $Command,
    [ref]$tokens,
    [ref]$parseErrors
  )
  if (($parseErrors.Count -ne 0) -or ($null -eq $commandAst.EndBlock)) {
    return $false
  }

  $statements = @($commandAst.EndBlock.Statements)
  if (($statements.Count -ne 4) -or ($commandAst.EndBlock.Traps.Count -ne 0)) {
    return $false
  }

  $gitPipeline = $statements[0]
  if (-not ($gitPipeline -is [System.Management.Automation.Language.PipelineAst]) -or
      ($gitPipeline.PipelineElements.Count -ne 1) -or
      -not ($gitPipeline.PipelineElements[0] -is [System.Management.Automation.Language.CommandAst])) {
    return $false
  }
  $gitCommand = $gitPipeline.PipelineElements[0]
  $gitElements = @($gitCommand.CommandElements)
  if (($gitElements.Count -ne 5) -or
      (@($gitElements | Where-Object { -not ($_ -is [System.Management.Automation.Language.StringConstantExpressionAst]) }).Count -ne 0) -or
      ((@($gitElements | ForEach-Object { $_.Value }) -join ',') -cne 'git,merge-base,--is-ancestor,starter/salesflow-guided-v1,HEAD')) {
    return $false
  }

  $assignment = $statements[1]
  $capturesLastExitCode =
    ($assignment -is [System.Management.Automation.Language.AssignmentStatementAst]) -and
    ($assignment.Left -is [System.Management.Automation.Language.VariableExpressionAst]) -and
    ($assignment.Left.VariablePath.UserPath -ieq 'ancestryExit') -and
    ($assignment.Operator -eq [System.Management.Automation.Language.TokenKind]::Equals) -and
    ($assignment.Right -is [System.Management.Automation.Language.CommandExpressionAst]) -and
    ($assignment.Right.Expression -is [System.Management.Automation.Language.VariableExpressionAst]) -and
    ($assignment.Right.Expression.VariablePath.UserPath -ieq 'LASTEXITCODE')
  if (-not $capturesLastExitCode) {
    return $false
  }

  $evidencePipeline = $statements[2]
  if (-not ($evidencePipeline -is [System.Management.Automation.Language.PipelineAst]) -or
      ($evidencePipeline.PipelineElements.Count -ne 1) -or
      -not ($evidencePipeline.PipelineElements[0] -is [System.Management.Automation.Language.CommandAst])) {
    return $false
  }
  $evidenceCommand = $evidencePipeline.PipelineElements[0]
  $evidenceElements = @($evidenceCommand.CommandElements)
  if (($evidenceCommand.GetCommandName() -ine 'Write-Output') -or
      ($evidenceElements.Count -ne 2) -or
      -not ($evidenceElements[1] -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) -or
      ($evidenceElements[1].Value -cne 'starter-ancestry-exit=$ancestryExit') -or
      ($evidenceElements[1].NestedExpressions.Count -ne 1) -or
      -not ($evidenceElements[1].NestedExpressions[0] -is [System.Management.Automation.Language.VariableExpressionAst]) -or
      ($evidenceElements[1].NestedExpressions[0].VariablePath.UserPath -ine 'ancestryExit')) {
    return $false
  }

  $guard = $statements[3]
  if (-not ($guard -is [System.Management.Automation.Language.IfStatementAst]) -or
      ($guard.Clauses.Count -ne 1) -or
      ($null -ne $guard.ElseClause)) {
    return $false
  }

  $condition = $guard.Clauses[0].Item1.GetPureExpression()
  if (($null -eq $condition) -or
      -not ($condition -is [System.Management.Automation.Language.BinaryExpressionAst]) -or
      ($condition.Operator -ne [System.Management.Automation.Language.TokenKind]::Ine)) {
    return $false
  }

  $leftIsAncestry =
    ($condition.Left -is [System.Management.Automation.Language.VariableExpressionAst]) -and
    ($condition.Left.VariablePath.UserPath -ieq 'ancestryExit')
  $rightIsAncestry =
    ($condition.Right -is [System.Management.Automation.Language.VariableExpressionAst]) -and
    ($condition.Right.VariablePath.UserPath -ieq 'ancestryExit')
  $leftIsZero =
    ($condition.Left -is [System.Management.Automation.Language.ConstantExpressionAst]) -and
    ($condition.Left.Value -eq 0)
  $rightIsZero =
    ($condition.Right -is [System.Management.Automation.Language.ConstantExpressionAst]) -and
    ($condition.Right.Value -eq 0)
  if (-not (($leftIsAncestry -and $rightIsZero) -or ($leftIsZero -and $rightIsAncestry))) {
    return $false
  }

  $guardStatements = @($guard.Clauses[0].Item2.Statements)
  if ($guardStatements.Count -ne 1) {
    return $false
  }
  if ($guardStatements[0] -is [System.Management.Automation.Language.ThrowStatementAst]) {
    $throwExpression = $guardStatements[0].Pipeline.GetPureExpression()
    return (($throwExpression -is [System.Management.Automation.Language.StringConstantExpressionAst]) -and
      ($throwExpression.Value -ceq 'starter ancestry failed'))
  }
  if ($guardStatements[0] -is [System.Management.Automation.Language.ExitStatementAst]) {
    $exitExpression = $guardStatements[0].Pipeline.GetPureExpression()
    return (($exitExpression -is [System.Management.Automation.Language.ConstantExpressionAst]) -and
      ($exitExpression.Value -is [int]) -and
      ($exitExpression.Value -ne 0))
  }

  return $false
}

$expected = @{
  M00 = @{
    Prerequisites = @(); Estimate = 5
    Evidence = @('git-worktree-safety','repository-map','orchestration-state-boundary','synthetic-local-boundary')
    Required = @('Git working-tree safety','synthetic-local success is not production proof','Make no implementation changes')
    Stages = @(
      @{ Name = 'Prediction'; Terms = @('Durable state') },
      @{ Name = 'Branch identity'; Terms = @('Branch') },
      @{ Name = 'Starter ancestry'; Terms = @('Starter ancestry') },
      @{ Name = 'Clean state'; Terms = @('Working tree') },
      @{ Name = 'Map'; Terms = @('Repository','Entry point') },
      @{ Name = 'Boundaries'; Terms = @('Orchestrator','Synthetic-local boundary') }
    )
  }
  M01 = @{
    Prerequisites = @('M00'); Estimate = 15
    Evidence = @('postgres-health','n8n-health','local-services'); Required = @()
    Stages = @(
      @{ Name = 'Prediction'; Terms = @('Health check') },
      @{ Name = 'Start'; Terms = @('Container','Service','Volume') },
      @{ Name = 'PostgreSQL evidence'; Terms = @() },
      @{ Name = 'n8n evidence'; Terms = @() }
    )
  }
  M02 = @{
    Prerequisites = @('M01'); Estimate = 20
    Evidence = @('webhook-path','parameterized-query','typed-terminal')
    Required = @('`accepted`: a Boolean','`eventId`: a string')
    Stages = @(
      @{ Name = 'Prediction'; Terms = @('Parameter') },
      @{ Name = 'Entry point'; Terms = @('Webhook') },
      @{ Name = 'Parameter binding'; Terms = @() },
      @{ Name = 'Transaction boundary'; Terms = @('Transaction') },
      @{ Name = 'Typed terminal'; Terms = @('Typed terminal') },
      @{ Name = 'Terminal evidence'; Terms = @() }
    )
  }
  M03 = @{
    Prerequisites = @('M02'); Estimate = 20
    Evidence = @('composite-account-scope','foreign-key-records','immutable-inbound-evidence')
    Required = @('composite account scope')
    Stages = @(
      @{ Name = 'Prediction'; Terms = @('Foreign key') },
      @{ Name = 'Schema location'; Terms = @('Migration') },
      @{ Name = 'Migration'; Terms = @() },
      @{ Name = 'Account'; Terms = @('Account','Primary key') },
      @{ Name = 'Contact'; Terms = @('Contact','Composite account scope') },
      @{ Name = 'Conversation'; Terms = @('Conversation') },
      @{ Name = 'Inbound message'; Terms = @('Inbound message') },
      @{ Name = 'Immutable evidence'; Terms = @('Immutable inbound evidence') },
      @{ Name = 'Evidence'; Terms = @() }
    )
  }
  M04 = @{
    Prerequisites = @('M03'); Estimate = 30
    Evidence = @('ordered-inbound-events','exactly-one-durable-effect','deterministic-replay-or-conflict')
    Required = @('exactly one durable logical effect')
    Stages = @(
      @{ Name = 'Prediction'; Terms = @('Event identity') },
      @{ Name = 'Boundary'; Terms = @('Durable effect') },
      @{ Name = 'One effect'; Terms = @('Idempotency','Uniqueness') },
      @{ Name = 'Replay result'; Terms = @('Replay result') },
      @{ Name = 'Typed conflict'; Terms = @('Typed conflict') },
      @{ Name = 'Ordering'; Terms = @('Serialization') },
      @{ Name = 'Race evidence'; Terms = @('Race check') }
    )
  }
  M05 = @{
    Prerequisites = @('M04'); Estimate = 30
    Evidence = @('typed-knowledge-policy-model-qualification','validated-provenance','invalid-evidence-handoff')
    Required = @('typed validation','model','qualification')
    Stages = @(
      @{ Name = 'Prediction'; Terms = @('Handoff') },
      @{ Name = 'Boundary'; Terms = @('Decision boundary') },
      @{ Name = 'Product Knowledge'; Terms = @('Product Knowledge','Typed validation') },
      @{ Name = 'Sales Policy'; Terms = @('Sales Policy') },
      @{ Name = 'Model'; Terms = @('Model record') },
      @{ Name = 'Qualification'; Terms = @('Qualification') },
      @{ Name = 'Provenance'; Terms = @('Provenance') },
      @{ Name = 'Synthetic decision'; Terms = @('Synthetic turn decision') },
      @{ Name = 'Handoff'; Terms = @('Fail-closed') },
      @{ Name = 'Evidence'; Terms = @('Deterministic fixture') }
    )
  }
}

foreach ($m in @($curriculum.milestones)[0..$lastIndex]) {
  $dir = Join-Path $root "learning/milestones/$($m.directory)"
  foreach ($name in @('lesson.md','checkpoint.yaml','hints.md')) {
    Assert-True (Test-Path -LiteralPath (Join-Path $dir $name)) "$($m.id) has $name"
  }

  if (Test-Path "$dir/checkpoint.yaml") {
    $checkpoint = Get-Content -Raw "$dir/checkpoint.yaml" | ConvertFrom-Json
    Assert-Equal $checkpoint.id $m.id "$($m.id) checkpoint identity"
    Assert-Equal $checkpoint.testScript "tests/learning/checkpoints/Test-$($m.id).ps1" "$($m.id) exact test path"
    Assert-True ((@($checkpoint.understandingPrompts) -join ',') -eq 'dataFlow,designDecision,failureMode') "$($m.id) has exact understanding prompts"
    if ($expected.ContainsKey($m.id)) {
      $rule = $expected[$m.id]
      Assert-True ((@($checkpoint.prerequisites) -join ',') -eq ($rule.Prerequisites -join ',')) "$($m.id) exact prerequisites"
      Assert-Equal $checkpoint.estimatedSeconds $rule.Estimate "$($m.id) exact estimate"
      Assert-True ((@($checkpoint.behaviorEvidence) -join ',') -eq ($rule.Evidence -join ',')) "$($m.id) exact behavior evidence"
    }
  }

  if ((Test-Path "$dir/lesson.md") -and $expected.ContainsKey($m.id)) {
    $lesson = Get-Content -Raw "$dir/lesson.md"
    $rule = $expected[$m.id]
    foreach ($heading in @('Outcome','Why now','Mental model','New terms','Your task','Constraints','Check','Explain','Transfer')) {
      Assert-Match $lesson "(?m)^## $([regex]::Escape($heading))$" "$($m.id) has $heading heading"
    }
    Assert-True (([regex]::Matches($lesson, '(?m)^## Mental model$')).Count -eq 1) "$($m.id) has one Mental model heading"
    Assert-Match $lesson '(?ms)^## Mental model\r?\n\r?\nEach stage contains exactly one mental model for that teaching exchange\.\r?\n' "$($m.id) defers mental models to teaching stages"
    Assert-Match $lesson '(?ms)^## New terms\r?\n\r?\nNew terms are defined in the stage that first uses them\.\r?\n' "$($m.id) introduces terms just in time"
    Assert-Match $lesson '(?ms)## Your task.*?Do not reveal a later stage until the learner supplies evidence from this stage\.' "$($m.id) keeps later actions gated"

    $stages = [regex]::Matches($lesson, '(?ms)^### Stage (?<Number>\d+) — (?<Name>[^\r\n]+)\r?\n(?<Body>.*?)(?=^### Stage |^## |\z)')
    Assert-Equal $stages.Count $rule.Stages.Count "$($m.id) has every required stage"
    Assert-True ((@($stages | ForEach-Object { $_.Groups['Number'].Value }) -join ',') -eq ((1..$rule.Stages.Count) -join ',')) "$($m.id) stage numbers are consecutive"
    Assert-True ((@($stages | ForEach-Object { $_.Groups['Name'].Value }) -join ',') -eq (@($rule.Stages | ForEach-Object { $_.Name }) -join ',')) "$($m.id) stage order is exact"

    $stageByName = @{}
    $pairedStageCount = [Math]::Min($stages.Count, $rule.Stages.Count)
    for ($stageIndex = 0; $stageIndex -lt $pairedStageCount; $stageIndex++) {
      $stage = $stages[$stageIndex]
      $stageRule = $rule.Stages[$stageIndex]
      $body = $stage.Groups['Body'].Value
      $stageByName[$stage.Groups['Name'].Value] = $body

      $mentalModels = [regex]::Matches($body, '(?m)^\*\*Mental model:\*\* \S.+$')
      $newTermMarkers = [regex]::Matches($body, '(?m)^\*\*New terms:\*\*(?: None\.)?$')
      $actions = [regex]::Matches($body, '(?m)^\*\*One action:\*\* \S.+$')
      $waits = [regex]::Matches($body, '(?m)^\*\*Wait:\*\* \S.+$')
      Assert-Equal $mentalModels.Count 1 "$($m.id) $($stageRule.Name) has exactly one mental model"
      Assert-Equal $newTermMarkers.Count 1 "$($m.id) $($stageRule.Name) declares new terms"
      Assert-Equal $actions.Count 1 "$($m.id) $($stageRule.Name) has exactly one learner action"
      Assert-Equal $waits.Count 1 "$($m.id) $($stageRule.Name) has exactly one wait"
      if (($mentalModels.Count -eq 1) -and ($newTermMarkers.Count -eq 1) -and ($actions.Count -eq 1) -and ($waits.Count -eq 1)) {
        Assert-True (($mentalModels[0].Index -lt $newTermMarkers[0].Index) -and ($newTermMarkers[0].Index -lt $actions[0].Index) -and ($actions[0].Index -lt $waits[0].Index)) "$($m.id) $($stageRule.Name) teaches, acts, then waits"
        Assert-Match $waits[0].Value '(?i)\b(Stop|Wait)\b.*\b(inspect|confirm|classify|review|check|evidence|result|prediction|output|diff|location)\b' "$($m.id) $($stageRule.Name) wait checks learner evidence"
        $actionProse = $actions[0].Value -replace '`[^`]*`', '<command>'
        Assert-True (-not ($actionProse -match '(?i)\b(?:then|and)\s+(?:run|make|create|collect|identify|state|write|start|add|capture|share|explain|change)\b')) "$($m.id) $($stageRule.Name) action is not a bundled action list"
        $afterWait = $body.Substring($waits[0].Index + $waits[0].Length).Trim()
        Assert-Equal $afterWait '' "$($m.id) $($stageRule.Name) waits before the next stage"
      }

      $termMatches = [regex]::Matches($body, '(?m)^- \*\*(?<Term>[^*:]+):\*\* (?<Definition>\S.*)$')
      Assert-True ($termMatches.Count -le 3) "$($m.id) $($stageRule.Name) has at most three new terms"
      Assert-True ((@($termMatches | ForEach-Object { $_.Groups['Term'].Value }) -join ',') -eq (@($stageRule.Terms) -join ',')) "$($m.id) $($stageRule.Name) introduces only its approved terms"
      if ($termMatches.Count -eq 0) {
        Assert-Match $body '(?m)^\*\*New terms:\*\* None\.$' "$($m.id) $($stageRule.Name) explicitly declares no new terms"
      } else {
        Assert-Match $body '(?m)^\*\*New terms:\*\*$' "$($m.id) $($stageRule.Name) defines introduced terms"
      }
      $usageText = $body -replace '(?ms)^\*\*New terms:\*\*.*?(?=^\*\*One action:\*\*)', ''
      foreach ($termMatch in $termMatches) {
        $term = $termMatch.Groups['Term'].Value
        $outcomeIndex = $lesson.IndexOf('## Outcome')
        $preStageText = $lesson.Substring($outcomeIndex, $stage.Index - $outcomeIndex)
        Assert-True (-not ($preStageText -match "(?i)$([regex]::Escape($term))")) "$($m.id) $($stageRule.Name) does not expose $term before its teaching stage"
        Assert-True ($usageText -match "(?i)$([regex]::Escape($term))") "$($m.id) $($stageRule.Name) uses introduced term $term"
      }
    }

    foreach ($required in $rule.Required) {
      Assert-Match $lesson ([regex]::Escape($required)) "$($m.id) states required curriculum boundary"
    }
    if ($m.id -eq 'M00') {
      Assert-Match $stageByName['Branch identity'] '(?m)^\*\*One action:\*\* Run `git branch --show-current`\.$' 'M00 branch identity is observable'
      $starterActionCommand = Get-OneActionPowerShellCommand $stageByName['Starter ancestry']
      Assert-True ($null -ne $starterActionCommand) 'M00 isolates one executable Starter ancestry action command'
      if ($null -ne $starterActionCommand) {
        Assert-Match $starterActionCommand '^git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD(?:;|$)' 'M00 action checks exact starter ancestry'
        Assert-True (Test-M00StarterAncestryCommand $starterActionCommand) 'M00 action preserves exact Git capture, evidence, and nonzero-guard data flow'
      }

      $hardCodedZeroCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = 0; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }'
      Assert-True (-not (Test-M00StarterAncestryCommand $hardCodedZeroCommand)) 'M00 validator rejects a hard-coded ancestry result'

      $proseDecoyStage = @'
Expected relationship: `$ancestryExit = $LASTEXITCODE`.
**One action:** Run `git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = 0; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }`.
'@
      Assert-True (-not (Test-M00StarterAncestryCommand (Get-OneActionPowerShellCommand $proseDecoyStage))) 'M00 validator rejects an assignment present only in prose'

      $commentDecoyCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = 0 <# $ancestryExit = $LASTEXITCODE #>; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }'
      Assert-True (-not (Test-M00StarterAncestryCommand $commentDecoyCommand)) 'M00 validator rejects an assignment present only in a comment'

      $stringDecoyCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = 0; ''$ancestryExit = $LASTEXITCODE''; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }'
      Assert-True (-not (Test-M00StarterAncestryCommand $stringDecoyCommand)) 'M00 validator rejects an assignment present only in a string'

      $crossLineDecoyStage = @'
**One action:** Run `git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit
= $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }`.
'@
      Assert-True (-not (Test-M00StarterAncestryCommand (Get-OneActionPowerShellCommand $crossLineDecoyStage))) 'M00 validator rejects cross-line assignment tokens'

      $clobberedLastExitCodeCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; cmd /c exit 0; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }'
      Assert-True (-not (Test-M00StarterAncestryCommand $clobberedLastExitCodeCommand)) 'M00 validator rejects an intervening LASTEXITCODE clobber'

      $overwrittenAncestryCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = $LASTEXITCODE; Set-Variable -Name ancestryExit -Value 0; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }'
      Assert-True (-not (Test-M00StarterAncestryCommand $overwrittenAncestryCommand)) 'M00 validator rejects an ancestryExit overwrite before the guard'

      $unreachableThrowCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { exit 0; throw "starter ancestry failed" }'
      Assert-True (-not (Test-M00StarterAncestryCommand $unreachableThrowCommand)) 'M00 validator rejects an unreachable fail-closed statement'

      $exitingThrowOperandCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw $(exit 0) }'
      Assert-True (-not (Test-M00StarterAncestryCommand $exitingThrowOperandCommand)) 'M00 validator rejects a successful exit inside the throw operand'

      $trappedThrowOperandCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw $(trap { exit 0 }; throw "inner") }'
      Assert-True (-not (Test-M00StarterAncestryCommand $trappedThrowOperandCommand)) 'M00 validator rejects a trap inside the throw operand'

      $trappedThrowCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; trap { continue }; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }'
      Assert-True (-not (Test-M00StarterAncestryCommand $trappedThrowCommand)) 'M00 validator rejects a trap that swallows the ancestry failure'

      $wrongHeadCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD~1; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }'
      Assert-True (-not (Test-M00StarterAncestryCommand $wrongHeadCommand)) 'M00 validator rejects a different ancestry target'

      $commentEvidenceCommand = 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = $LASTEXITCODE; <# starter-ancestry-exit=$ancestryExit #>; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }'
      Assert-True (-not (Test-M00StarterAncestryCommand $commentEvidenceCommand)) 'M00 validator rejects evidence text present only in a comment'

      $hiddenActionStage = @'
<!-- **One action:** Run `git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }`. -->
'@
      Assert-True ($null -eq (Get-OneActionPowerShellCommand $hiddenActionStage)) 'M00 extractor ignores an action hidden in an HTML comment'

      $fencedActionStage = @'
```powershell
**One action:** Run `git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }`.
```
'@
      Assert-True ($null -eq (Get-OneActionPowerShellCommand $fencedActionStage)) 'M00 extractor ignores an action hidden in a fenced example'

      $mixedFenceStage = @'
```text
~~~
**One action:** Run `git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }`.
```
'@
      Assert-True ($null -eq (Get-OneActionPowerShellCommand $mixedFenceStage)) 'M00 extractor keeps mixed fence markers inside the opening fence'

      $hiddenHtmlStage = @'
<div hidden>
**One action:** Run `git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }`.
</div>
'@
      Assert-True ($null -eq (Get-OneActionPowerShellCommand $hiddenHtmlStage)) 'M00 extractor ignores an action hidden in a raw HTML block'
      Assert-Match $stageByName['Clean state'] '(?m)^\*\*One action:\*\* Run `git status --short`\.$' 'M00 working-tree state is observable'
      Assert-True (-not ($lesson -match '(?i)\bworktree\b')) 'M00 uses Working tree rather than the ambiguous worktree synonym'
    }
    if ($m.id -eq 'M05') {
      $typedStages = @{ 'Sales Policy' = 'Sales Policy'; 'Model' = 'Model record'; 'Qualification' = 'Qualification' }
      foreach ($typedStage in $typedStages.Keys) {
        $typedRecord = [regex]::Escape($typedStages[$typedStage])
        Assert-Match $stageByName[$typedStage] "(?mi)^\*\*One action:\*\* [^\r\n]*\btyped validation\b[^\r\n]*\b$typedRecord\b[^\r\n]*before acceptance\.$" "M05 $typedStage action requires typed validation of its record"
      }
    }
  }

  if (Test-Path "$dir/hints.md") {
    $hints = Get-Content -Raw "$dir/hints.md"
    foreach ($level in 1..5) {
      Assert-Match $hints "(?m)^## Hint $level .+$" "$($m.id) has anchored hint $level"
    }
    $hintHeadings = [regex]::Matches($hints, '(?m)^## Hint (\d) .+$')
    Assert-Equal $hintHeadings.Count 5 "$($m.id) has exactly five unique hint headings"
    Assert-True ((@($hintHeadings | ForEach-Object { $_.Groups[1].Value }) -join ',') -eq '1,2,3,4,5') "$($m.id) keeps hint headings ordered"
    Assert-True (-not ($hints -match 'Direct solution')) "$($m.id) hints do not contain direct solution"
    Assert-True (-not ($hints -match '(?i)importable workflow JSON|executable SQL')) "$($m.id) hints avoid executable artifacts"
    $hintFive = [regex]::Match($hints, '(?ms)^## Hint 5 .+?\r?\n(?<Body>.*?)(?=^## Hint |\z)')
    Assert-True $hintFive.Success "$($m.id) isolates hint 5"
    if ($hintFive.Success) {
      Assert-Match $hintFive.Groups['Body'].Value '\[[^\]]*____[^\]]*\]' "$($m.id) hint 5 is incomplete"
    }
  }
}
Complete-TestFile
