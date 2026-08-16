param([ValidateSet('M05','M10')][string]$Through = 'M10')
. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$curriculum = Get-Content -Raw "$root/learning/curriculum.yaml" | ConvertFrom-Json
$lastIndex = [int]$Through.Substring(1)
$expected = @{
  M00 = @{ Prerequisites = @(); Estimate = 5; Evidence = @('git-worktree-safety','repository-map','orchestration-state-boundary','synthetic-local-boundary'); Required = @('Git/worktree safety','synthetic-local success is not production proof','git branch --show-current','git merge-base --is-ancestor','Make no implementation changes') ; Stages = @('Prediction','Branch identity','Starter ancestry','Clean state','Map','Boundaries') }
  M01 = @{ Prerequisites = @('M00'); Estimate = 15; Evidence = @('postgres-health','n8n-health','local-services'); Required = @(); Stages = @('Prediction','Start','PostgreSQL evidence','n8n evidence') }
  M02 = @{ Prerequisites = @('M01'); Estimate = 20; Evidence = @('webhook-path','parameterized-query','typed-terminal'); Required = @('`accepted`: a Boolean','`eventId`: a string'); Stages = @('Prediction','Entry point','Parameter binding','Transaction boundary','Typed terminal','Terminal evidence') }
  M03 = @{ Prerequisites = @('M02'); Estimate = 20; Evidence = @('composite-account-scope','foreign-key-records','immutable-inbound-evidence'); Required = @('composite account scope'); Stages = @('Prediction','Schema location','Account','Contact','Conversation','Inbound message','Immutable evidence','Evidence') }
  M04 = @{ Prerequisites = @('M03'); Estimate = 30; Evidence = @('ordered-inbound-events','exactly-one-durable-effect','deterministic-replay-or-conflict'); Required = @('exactly one durable logical effect'); Stages = @('Prediction','Boundary','One effect','Replay result','Typed conflict','Ordering','Race evidence') }
  M05 = @{ Prerequisites = @('M04'); Estimate = 30; Evidence = @('typed-knowledge-policy-model-qualification','validated-provenance','invalid-evidence-handoff'); Required = @('typed validation','model','qualification'); Stages = @('Prediction','Boundary','Product Knowledge','Sales Policy','Model','Qualification','Provenance','Handoff','Evidence') }
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
    foreach ($heading in @('Outcome','Why now','Mental model','New terms','Your task','Constraints','Check','Explain','Transfer')) {
      Assert-Match $lesson "(?m)^## $([regex]::Escape($heading))$" "$($m.id) has $heading heading"
    }
    Assert-True (([regex]::Matches($lesson, '(?m)^## Mental model$')).Count -eq 1) "$($m.id) has one initial mental model"
    Assert-True (([regex]::Matches($lesson, '(?m)^- \*\*[^*]+:\*\*')).Count -le 3) "$($m.id) has at most three initial terms"
    Assert-Match $lesson '(?ms)### Stage 1 — Prediction.*?\*\*Wait:\*\*' "$($m.id) starts with one prediction action and wait"
    Assert-Match $lesson '(?ms)## Your task.*?Do not reveal a later stage until the learner supplies evidence from this stage\.' "$($m.id) keeps later actions gated"
    Assert-Match $lesson 'At each stage, begin the teaching exchange with one mental model and at most three new terms\.' "$($m.id) keeps the per-stage term budget"
    $stages = [regex]::Matches($lesson, '(?ms)^### Stage .+?(?=^### Stage |\z)')
    Assert-True ($stages.Count -ge 1) "$($m.id) has staged actions"
    foreach ($stage in $stages) {
      Assert-Equal ([regex]::Matches($stage.Value, '\*\*One action:\*\*')).Count 1 "$($m.id) stage has one learner action"
      Assert-Equal ([regex]::Matches($stage.Value, '\*\*Wait:\*\*')).Count 1 "$($m.id) stage waits for evidence"
      Assert-Equal ([regex]::Matches($stage.Value, '\*\*Mental model:\*\*')).Count 1 "$($m.id) stage has one mental model"
      Assert-True (([regex]::Matches($stage.Value, '(?m)^- \*\*[^*]+:\*\*')).Count -le 3) "$($m.id) stage has at most three new terms"
    }
    Assert-True ((@($stages | ForEach-Object { [regex]::Match($_.Value, '^### Stage (\d+) .+$', 'Multiline').Groups[1].Value }) -join ',') -eq ((1..$expected[$m.id].Stages.Count) -join ',')) "$($m.id) stage numbers are consecutive"
    Assert-True ((@($stages | ForEach-Object { [regex]::Match($_.Value, '^### Stage \d+ .+$', 'Multiline').Value -replace '^### Stage \d+ .+?— ' }) -join ',') -eq ($expected[$m.id].Stages -join ',')) "$($m.id) stage order is exact"
    foreach ($required in $expected[$m.id].Required) { Assert-Match $lesson ([regex]::Escape($required)) "$($m.id) states required curriculum boundary" }
  }
  if (Test-Path "$dir/hints.md") {
    $hints = Get-Content -Raw "$dir/hints.md"
    foreach ($level in 1..5) { Assert-Match $hints "(?m)^## Hint $level .+$" "$($m.id) has anchored hint $level" }
    $hintHeadings = [regex]::Matches($hints, '(?m)^## Hint (\d) .+$')
    Assert-Equal $hintHeadings.Count 5 "$($m.id) has exactly five unique hint headings"
    Assert-True ((@($hintHeadings | ForEach-Object { $_.Groups[1].Value }) -join ',') -eq '1,2,3,4,5') "$($m.id) keeps hint headings ordered"
    Assert-True (-not ($hints -match 'Direct solution')) "$($m.id) hints do not contain direct solution"
    Assert-True (-not ($hints -match '(?i)importable workflow JSON|executable SQL')) "$($m.id) hints avoid executable artifacts"
    Assert-Match $hints '\[[^\]]*____[^\]]*\]' "$($m.id) hint 5 is incomplete"
  }
}
Complete-TestFile
