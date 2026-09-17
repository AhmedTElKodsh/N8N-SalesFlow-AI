# Scenario-level pass/fail report for tests/run.ps1.
# The run is fail-fast: the check in progress fails and every later check stays "not run".
$script:TestReport=$null
$script:TestReportScope='Simulated local setup only: a synthetic WhatsApp adapter and a fixture AI model in disposable containers. A PASS is not evidence that live WhatsApp or AI providers work.'
$script:TestReportOrderNote='Scenarios are listed by ID but run in database order, so a not-run scenario can appear between passes.'
$script:TestReportDetailLimit=600

function New-TestReportItem([string]$Id,[string]$Name){[pscustomobject]@{Id=$Id;Name=$Name;Result='not run';Details=''}}

function Initialize-TestReport([string[]]$ScenarioIds,$ScenarioNames){
  $duplicates=@($ScenarioIds|Group-Object|Where-Object Count -gt 1|ForEach-Object Name)
  if($duplicates.Count){throw "Duplicate scenario IDs in tests/pilot-scenarios.json: $($duplicates -join ', ')."}
  $items=[Collections.Generic.List[object]]::new()
  $before=[ordered]@{P01='Prerequisites and clean-start check';T04='SP3-T4 automatic human hand-off suite';T05='SP3-T5 saved hand-off summary suite';T06='SP3-T6 activity log, emergency stop, and failure view suite';R01='Release, workflow, and database contract checks';E01='Clean environment, sample data, and database migrations'}
  $after=[ordered]@{R02='Additional database regression checks';C01='Concurrency and race-condition checks';W01='Workflow publication and live endpoint checks';X01='Cleanup of containers, data, and generated credentials'}
  foreach($entry in $before.GetEnumerator()){$items.Add((New-TestReportItem $entry.Key $entry.Value))}
  foreach($id in $ScenarioIds){
    $name=[string]$ScenarioNames.$id
    if([string]::IsNullOrWhiteSpace($name)){throw "Scenario $id has no name in tests/pilot-scenarios.json."}
    $items.Add((New-TestReportItem $id $name))
  }
  foreach($entry in $after.GetEnumerator()){$items.Add((New-TestReportItem $entry.Key $entry.Value))}
  $script:TestReport=[pscustomobject]@{Items=$items;Current=$null;PendingDetails=$null;Secrets=[Collections.Generic.List[string]]::new();StartedAt=[DateTime]::UtcNow;FinishedAt=$null}
}

function Get-TestReportItem([string]$Id){
  $item=$script:TestReport.Items|Where-Object Id -eq $Id|Select-Object -First 1
  if(-not$item){throw "Unknown test report item $Id."}
  $item
}

function Complete-TestItem{
  $report=$script:TestReport
  if($report.Current){$report.Current.Result='pass';$report.Current=$null}
}

function Enter-TestItem([string]$Id){
  $item=Get-TestReportItem $Id
  Complete-TestItem
  $item.Result='running'
  $script:TestReport.Current=$item
}

function Register-TestSecret([string]$Value){
  if([string]::IsNullOrEmpty($Value)-or$Value.Length-lt8){return}
  $secrets=$script:TestReport.Secrets
  foreach($form in @($Value,[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Value)))){if(-not$secrets.Contains($form)){$secrets.Add($form)}}
}

function Protect-TestReportText([string]$Text){
  if([string]::IsNullOrEmpty($Text)){return ''}
  $protected=$Text
  foreach($secret in @($script:TestReport.Secrets|Sort-Object Length -Descending)){$protected=$protected.Replace($secret,'[redacted]')}
  # Generated secrets are 32 or 64 hex characters; mask any of those shapes that were never registered.
  [regex]::Replace($protected,'(?i)\b(?:[0-9a-f]{64}|[0-9a-f]{32})\b','[redacted]')
}

function Get-TestReportFailureDetails([string[]]$Lines,[int]$ExitCode){
  # Windows PowerShell can prefix redirected native stderr with "psql : "; strip it so duplicates collapse.
  $relevant=@($Lines|ForEach-Object{(([string]$_).Trim())-replace'^[^:\s]+ : (?=psql:)',''}|Where-Object{$_-match'(ERROR|DETAIL|HINT|CONTEXT):'-and$_-notmatch'^(\+ |At )'}|Select-Object -Unique)
  $details=if($relevant.Count){$relevant-join' '}else{"tests/runtime.sql stopped with exit code $ExitCode."}
  # Protect complete secret values before the detail cap can cut them into unrecognizable prefixes.
  $details=Protect-TestReportText $details
  if($details.Length-gt$script:TestReportDetailLimit){$details=$details.Substring(0,$script:TestReportDetailLimit)+'...'}
  $details
}

# Scenario IDs are attributed from notices raised by tests/runtime.sql: SCENARIO_SETUP_READY after its preamble,
# then SCENARIO_PASS <id> as each evidence row is recorded, in execution order.
function Set-TestScenarioProgress([string[]]$ExecutionOrder,[string[]]$Output,[bool]$Failed,[int]$ExitCode){
  $report=$script:TestReport
  $lines=@($Output|ForEach-Object{[string]$_})
  $scenarioItems=@(foreach($id in $ExecutionOrder){Get-TestReportItem $id})
  $setupReady=@($lines|Where-Object{$_-match'SCENARIO_SETUP_READY'}).Count-gt0
  $passed=@(foreach($line in $lines){$match=[regex]::Match($line,'SCENARIO_PASS (S\d\d)');if($match.Success){$match.Groups[1].Value}})
  if($Failed-and-not$setupReady){
    # The preamble failed; the environment setup check in progress owns the failure.
    $report.PendingDetails=Get-TestReportFailureDetails $lines $ExitCode
    return
  }
  Complete-TestItem
  $unfinished=$null
  foreach($item in $scenarioItems){if($passed-contains$item.Id){$item.Result='pass'}elseif(-not$unfinished){$unfinished=$item}}
  if($Failed){
    if(-not$unfinished){$unfinished=Get-TestReportItem 'R02'}
    $report.PendingDetails=Get-TestReportFailureDetails $lines $ExitCode
  }elseif($unfinished){
    $report.PendingDetails='The scenario finished without reporting a pass.'
  }
  if($unfinished){$unfinished.Result='running';$report.Current=$unfinished}
}

function Stop-TestReport([string]$Message){
  $report=$script:TestReport
  $item=$report.Current
  $details=if($report.PendingDetails){$report.PendingDetails}else{$Message}
  if(-not$item){
    $item=$report.Items|Where-Object Result -eq 'not run'|Select-Object -First 1
    $details="Stopped between checks: $details"
  }
  $item.Result='fail'
  $item.Details=Protect-TestReportText $details
  $report.Current=$null
  $report.PendingDetails=$null
}

function Get-TestReportVerdict{if(@($script:TestReport.Items|Where-Object Result -ne 'pass').Count-eq0){'PASS'}else{'FAIL'}}

function ConvertTo-TestReportCell([string]$Text){(((($Text-replace'\r?\n',' ')-replace'\|','\|')-replace'`',"'")-replace'<','&lt;'-replace'>','&gt;').Trim()}

function Format-TestReport{
  $report=$script:TestReport
  $items=@($report.Items)
  $passed=@($items|Where-Object Result -eq 'pass').Count
  $failed=@($items|Where-Object Result -eq 'fail').Count
  $notRun=@($items|Where-Object Result -eq 'not run').Count
  $lines=[Collections.Generic.List[string]]::new()
  $lines.Add('# SalesFlow one-click test report')
  $lines.Add('')
  $lines.Add("- **Verdict:** $(Get-TestReportVerdict)")
  $lines.Add("- **Started (UTC):** $($report.StartedAt.ToString('yyyy-MM-dd HH:mm:ss'))")
  $lines.Add("- **Finished (UTC):** $($report.FinishedAt.ToString('yyyy-MM-dd HH:mm:ss'))")
  $lines.Add("- **Results:** $passed passed, $failed failed, $notRun not run")
  $lines.Add("- **Scope:** $script:TestReportScope")
  $lines.Add("- **Order:** $script:TestReportOrderNote")
  $lines.Add('')
  $lines.Add('| ID | Test | Result | Details |')
  $lines.Add('|----|------|--------|---------|')
  foreach($item in $items){$lines.Add("| $($item.Id) | $(ConvertTo-TestReportCell $item.Name) | $($item.Result) | $(ConvertTo-TestReportCell $item.Details) |")}
  ($lines-join"`n")+"`n"
}

function Assert-TestReportSecretFree([string]$Text){
  $compact=[regex]::Replace($Text,'\s','')
  foreach($secret in $script:TestReport.Secrets){if($Text.Contains($secret)-or$compact.Contains($secret)){throw 'The test report contained a generated secret and was not saved.'}}
}

function Complete-TestReport([string]$OutputDirectory,[string]$CleanupFailure,[bool]$CleanupRan,[bool]$StackRetained,[bool]$ResetAttempted,[bool]$SkipSave){
  $report=$script:TestReport
  if($report.Current){$report.Current.Result='fail';$report.Current.Details='The run was interrupted before this check finished.';$report.Current=$null}
  $cleanup=Get-TestReportItem 'X01'
  if($CleanupFailure){$cleanup.Result='fail';$cleanup.Details=Protect-TestReportText $CleanupFailure}
  elseif($ResetAttempted-and-not$CleanupRan){$cleanup.Result='fail';$cleanup.Details='Resetting the existing local stack did not finish; inspect its containers, volumes, and .env before running again.'}
  else{
    $cleanup.Result='pass'
    $cleanup.Details=if($StackRetained){'Local stack kept running because -KeepRunning was requested.'}elseif($CleanupRan){'Containers, volumes, and generated credentials were removed.'}else{'No shared test environment was created.'}
  }
  $report.FinishedAt=[DateTime]::UtcNow
  $text=Format-TestReport
  Assert-TestReportSecretFree $text
  # Print the on-screen report before saving, so a filesystem failure cannot hide the results.
  Write-Host ''
  Write-Host 'TEST REPORT'
  foreach($item in $report.Items){
    $line="$($item.Result.ToUpperInvariant().PadRight(8)) $($item.Id)  $($item.Name)"
    if($item.Result-ne'pass'-and$item.Details){$line+=" -- $($item.Details)"}
    Write-Host $line
  }
  Write-Host "VERDICT $(Get-TestReportVerdict)"
  Write-Host "SCOPE $script:TestReportScope"
  if($SkipSave){Write-Host 'REPORT not saved: this invocation did not run the suite.';return $null}
  New-Item $OutputDirectory -ItemType Directory -Force|Out-Null
  $path=Join-Path $OutputDirectory ('test-report-'+$report.FinishedAt.ToString('yyyyMMdd-HHmmss-fff')+'Z.md')
  [IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false))
  Write-Host "REPORT $path"
  $path
}
