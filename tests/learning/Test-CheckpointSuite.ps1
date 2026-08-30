. "$PSScriptRoot/TestSupport.ps1"

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$checkpointRoot = Join-Path $PSScriptRoot 'checkpoints'
$checkpointScripts = 0..10 | ForEach-Object {
  Join-Path $checkpointRoot ("Test-M{0:d2}.ps1" -f $_)
}

# This is deliberately the first gate: the initial TDD run must report only the
# eleven absent milestone validators, without cascading protocol failures.
foreach ($scriptPath in $checkpointScripts) {
  Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "$([IO.Path]::GetFileName($scriptPath)) exists"
}
if ($script:FailureCount -gt 0) {
  Complete-TestFile
}

$supportPath = Join-Path $checkpointRoot 'CheckpointSupport.ps1'
Assert-True (Test-Path -LiteralPath $supportPath -PathType Leaf) 'CheckpointSupport.ps1 exists'

function Read-ScriptAst([string]$Path) {
  $tokens = $null
  $parseErrors = $null
  $ast = [Management.Automation.Language.Parser]::ParseFile(
    $Path,
    [ref]$tokens,
    [ref]$parseErrors
  )
  Assert-Equal $parseErrors.Count 0 "$([IO.Path]::GetFileName($Path)) parses as PowerShell"
  [pscustomobject]@{
    Ast = $ast
    Text = Get-Content -Raw -LiteralPath $Path
  }
}

function Get-ParameterNames($Ast) {
  if ($null -eq $Ast.ParamBlock) { return @() }
  @($Ast.ParamBlock.Parameters | ForEach-Object {
    $_.Name.VariablePath.UserPath
  })
}

function Invoke-CheckpointFailure([string]$ScriptPath, [string]$InvalidRoot) {
  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = (Get-Command powershell.exe -ErrorAction Stop).Source
  $startInfo.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' +
    $ScriptPath.Replace('"', '\"') + '" -RepositoryRoot "' +
    $InvalidRoot.Replace('"', '\"') + '"'
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

$parsed = @{}
foreach ($scriptPath in @($supportPath) + $checkpointScripts) {
  if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
    $parsed[[IO.Path]::GetFileName($scriptPath)] = Read-ScriptAst $scriptPath
  }
}

$forbiddenReference = '(?i)(?:^|[\\/])reference[\\/]salesflow-complete-v1(?:[\\/]|$)|reference/salesflow-complete-v1'
foreach ($name in $parsed.Keys) {
  Assert-True (-not ($parsed[$name].Text -match $forbiddenReference)) "$name does not inspect the completed reference"
  Assert-True (-not ($parsed[$name].Text -match '(?i)\bgit\s+(?:show|checkout|switch|worktree)\b[^\r\n]*\breference(?:[/\\]|:)')) "$name contains no Git reference-branch read"
}

$forbiddenSuccessChatter = '(?im)^\s*(?:Write-Host|Write-Output|echo)\b'
foreach ($index in 0..9) {
  $name = "Test-M{0:d2}.ps1" -f $index
  $record = $parsed[$name]
  Assert-True ((Get-ParameterNames $record.Ast) -contains 'RepositoryRoot') "$name accepts -RepositoryRoot"
  Assert-Equal ([regex]::Matches($record.Text, '(?m)^\s*Write-LearningEvidence\b').Count) 1 "$name has one success evidence emission"
  Assert-Match $record.Text '(?m)^\s*Write-CheckpointFailure\b' "$name routes failures to the classified diagnostic writer"
  Assert-True (-not ($record.Text -match $forbiddenSuccessChatter)) "$name has no direct success chatter"
}

$expectedEvidence = @{}
Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'learning/milestones') -Directory | ForEach-Object {
  $checkpointPath = Join-Path $_.FullName 'checkpoint.yaml'
  if (Test-Path -LiteralPath $checkpointPath -PathType Leaf) {
    $checkpoint = Get-Content -Raw -LiteralPath $checkpointPath | ConvertFrom-Json
    if ([string]$checkpoint.id -match '^M(?:0[0-9]|10)$') {
      $expectedEvidence[[string]$checkpoint.id] = @($checkpoint.behaviorEvidence)
    }
  }
}
foreach ($index in 0..10) {
  $milestone = 'M{0:d2}' -f $index
  $name = "Test-$milestone.ps1"
  $evidenceCall = [regex]::Match($parsed[$name].Text, '(?s)Write-LearningEvidence\s+@\((?<Items>.*?)\)')
  $literalEvidence = @([regex]::Matches($evidenceCall.Groups['Items'].Value, "'(?<Value>[^']*)'") | ForEach-Object { $_.Groups['Value'].Value })
  Assert-True ($evidenceCall.Success -and ($literalEvidence -join ',') -eq (@($expectedEvidence[$milestone]) -join ',')) "$name emits the exact declared behaviorEvidence in order"
}

$supportText = $parsed['CheckpointSupport.ps1'].Text
foreach ($indicator in @(
  'function Resolve-CheckpointRepositoryRoot',
  'function Read-CheckpointJson',
  'function Read-CheckpointSql',
  'function Get-WorkflowReachableNodeNames',
  'function Assert-CheckpointInvariant',
  'function Write-CheckpointFailure',
  'function Write-LearningEvidence',
  'ConvertFrom-Json'
)) {
  Assert-Match $supportText ([regex]::Escape($indicator)) "checkpoint support includes $indicator"
}

$semanticIndicators = @{
  'Test-M00.ps1' = @('Assert-GitRepository', 'merge-base', 'starter/salesflow-guided-v1', 'learning/tutor-contract.md', 'learning/journal.md', 'M00')
  'Test-M01.ps1' = @('docker info', 'docker compose', 'ps', 'running', 'healthy', '127.0.0.1', 'healthcheck')
  'Test-M02.ps1' = @('01-whatsapp-ingress.json', 'Get-WorkflowReachableNodeNames', 'webhook', 'postgres', 'queryReplacement', 'typed terminal', 'Get-SqlFunctionBlock', 'eventId', 'jsonb_typeof')
  'Test-M03.ps1' = @('database/001-initial.sql', 'accounts', 'contacts', 'conversations', 'inbound_messages', 'FOREIGN KEY')
  'Test-M04.ps1' = @('provider_id', 'conversation_id, seq', 'idempotency_conflict', 'tests/runtime.sql', 'concurrent')
  'Test-M05.ps1' = @('product-knowledge.json', 'sales-policy.json', 'model.json', 'qualification.json', 'confidence', 'Handoff')
  'Test-M06.ps1' = @('03-outbox-dispatcher.json', 'Get-WorkflowReachableNodeNames', 'claim_dispatch', 'recheck_dispatch', 'finish_dispatch', 'provider_id', 'ambiguous', 'final denial')
  'Test-M07.ps1' = @('retry', 'backoff', 'expired', 'ambiguous', 'callback', 'monotonic')
  'Test-M08.ps1' = @('05-follow-up-scheduler.json', '06-handoff-dispatcher.json', 'Get-WorkflowReachableNodeNames', 'serviceWindowHours', 'template_window_closed', 'quiet_hours', 'opt-out', 'Human-Owned', 'UTC')
  'Test-M09.ps1' = @('audit', 'deletion', 'enforce_retention', 'secret', 'activeRelease', 'alert', 'release/release-manifest.json', 'livePromotionAllowed', 'production gate')
}
foreach ($name in $semanticIndicators.Keys) {
  foreach ($indicator in $semanticIndicators[$name]) {
    Assert-Match $parsed[$name].Text ([regex]::Escape($indicator)) "$name contains milestone behavior indicator $indicator"
  }
}

$m01Text = $parsed['Test-M01.ps1'].Text
Assert-True (-not ($m01Text -match '(?i)docker\s+(?:compose\s+)?(?:up|down|start|stop|restart|rm|remove|kill|create|run)\b')) 'M01 contains no Docker lifecycle mutation'
Assert-True (-not ($m01Text -match '(?i)(?:--volumes?|-v\b|volume\s+(?:rm|prune))')) 'M01 contains no Docker volume mutation'

$invalidRoot = Join-Path ([IO.Path]::GetTempPath()) ("salesflow-checkpoint-missing-{0}" -f [guid]::NewGuid().ToString('N'))
foreach ($index in 0..9) {
  $name = "Test-M{0:d2}.ps1" -f $index
  $result = Invoke-CheckpointFailure -ScriptPath $checkpointScripts[$index] -InvalidRoot $invalidRoot
  Assert-True ($result.ExitCode -ne 0) "$name invalid root exits nonzero"
  Assert-True (-not ($result.Stdout -match '(?m)^LEARNING_EVIDENCE=')) "$name invalid root emits no evidence"
  Assert-True ([string]::IsNullOrWhiteSpace($result.Stdout)) "$name invalid root keeps stdout empty"
  Assert-Match $result.Stderr '(?m)^(?:Environment or tooling failure|Syntax or integration failure|Behavioral checkpoint failure|Conceptual misunderstanding|Curriculum or checkpoint defect):' "$name invalid root uses a failure classification"
  Assert-Match $result.Stderr '(?i)Invariant=' "$name invalid root names the invariant"
  Assert-Match $result.Stderr '(?i)Observed=' "$name invalid root names the observed value"
  Assert-Match $result.Stderr '(?i)Location=' "$name invalid root names the diagnostic location"
}

$m10 = $parsed['Test-M10.ps1']
Assert-True ((Get-ParameterNames $m10.Ast) -contains 'RepositoryRoot') 'Test-M10.ps1 accepts -RepositoryRoot'
foreach ($indicator in @(
  '0..9',
  'expected runtime',
  'tests/run.ps1',
  'PASS FULL PASS',
  'cleanup',
  'end-to-end-scenario-trace',
  'failure-analysis-and-production-gates'
)) {
  Assert-Match $m10.Text ([regex]::Escape($indicator)) "M10 contains capstone indicator $indicator"
}
Assert-True (-not ($m10.Text -match '(?i)-(?:Reset|Keep)(?:\b|:)')) 'M10 does not pass reset or keep flags to the release harness'
$metaText = Get-Content -Raw -LiteralPath $PSCommandPath
Assert-True (-not ($metaText -match '(?im)(?:-File|&)\s+[^\r\n]*Test-M10\.ps1')) 'meta-test contains no direct M10 process or call-operator invocation'
Assert-Match $metaText '(?s)foreach\s*\(\$index\s+in\s+0\.\.9\).*?Invoke-CheckpointFailure' 'meta-test runtime failure probes are bounded to M00-M09'

Complete-TestFile
