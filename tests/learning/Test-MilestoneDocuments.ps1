param([ValidateSet('M05','M10')][string]$Through = 'M10')
. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$curriculum = Get-Content -Raw "$root/learning/curriculum.yaml" | ConvertFrom-Json
$lastIndex = [int]$Through.Substring(1)
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
      Assert-Match $stageByName['Starter ancestry'] 'git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD' 'M00 checks exact starter ancestry'
      Assert-Match $stageByName['Starter ancestry'] 'starter-ancestry-exit=' 'M00 emits ancestry evidence'
      Assert-Match $stageByName['Starter ancestry'] '\$LASTEXITCODE' 'M00 captures objective ancestry exit status'
      Assert-Match $stageByName['Starter ancestry'] '(?i)\$ancestryExit\s*=\s*\$LASTEXITCODE\b' 'M00 assigns the ancestry result from the Git exit status'
      Assert-Match $stageByName['Starter ancestry'] '(?i)if\s*\(\s*\$ancestryExit\s+-ne\s+0\s*\)\s*\{\s*(?:throw\b|exit\s+[1-9]\d*)' 'M00 fails closed when starter ancestry is not proven'
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
