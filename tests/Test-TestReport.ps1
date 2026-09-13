param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'TestReport.ps1')
$catalog=Get-Content (Join-Path $PSScriptRoot 'pilot-scenarios.json') -Raw|ConvertFrom-Json
$sqlText=Get-Content (Join-Path $PSScriptRoot 'runtime.sql') -Raw
$order=@([regex]::Matches($sqlText,"INSERT INTO evidence VALUES\('(S\d\d)'\)")|ForEach-Object{$_.Groups[1].Value})
$out=Join-Path ([IO.Path]::GetTempPath()) ('salesflow-report-test-'+[guid]::NewGuid().ToString('N'))
function Check($condition,[string]$label){if(-not$condition){throw "TestReport $label"};Write-Host "PASS TestReport $label"}
function Result([string]$id){(Get-TestReportItem $id).Result}
function Details([string]$id){(Get-TestReportItem $id).Details}
function Start-Report{Initialize-TestReport -ScenarioIds $catalog.scenarios -ScenarioNames $catalog.names;foreach($id in 'P01','T04','T05','T06','R01','E01'){Enter-TestItem $id}}
function Notices([string[]]$ids){@('psql:<stdin>:9: NOTICE:  SCENARIO_SETUP_READY')+@($ids|ForEach-Object{"psql:<stdin>:80: NOTICE:  SCENARIO_PASS $_"})}
function Save([string]$cleanupFailure,[bool]$retained){Complete-TestReport -OutputDirectory $out -CleanupFailure $cleanupFailure -CleanupRan $true -StackRetained $retained}
function Pass-All{Start-Report;Set-TestScenarioProgress -ExecutionOrder $order -Output (Notices $order) -Failed $false -ExitCode 0;foreach($id in 'R02','C01','W01'){Enter-TestItem $id};Complete-TestItem}
try{
  Check ($order.Count-eq26-and@($order|Select-Object -Unique).Count-eq26-and(Compare-Object @($order) @($catalog.scenarios)).Count-eq0) 'runtime.sql execution order covers the catalog exactly'
  Check ($sqlText.IndexOf('SCENARIO_SETUP_READY')-gt0-and$sqlText.IndexOf('SCENARIO_SETUP_READY')-lt$sqlText.IndexOf("INSERT INTO evidence VALUES('")) 'runtime.sql marks setup ready before the first scenario'
  Check (@($catalog.scenarios|Where-Object{[string]::IsNullOrWhiteSpace([string]$catalog.names.$_)}).Count-eq0) 'every scenario has a plain-language name'
  $threw=$false;try{Initialize-TestReport -ScenarioIds @('S99') -ScenarioNames ([pscustomobject]@{})}catch{$threw=$_.Exception.Message-match'S99'};Check $threw 'unnamed scenario is rejected'
  $threw=$false;try{Initialize-TestReport -ScenarioIds @('S01','S01') -ScenarioNames $catalog.names}catch{$threw=$_.Exception.Message-match'Duplicate'};Check $threw 'duplicate scenario IDs are rejected'
  $evidenceLines=@(($sqlText-split"`n")|Where-Object{$_-match"INSERT INTO evidence VALUES\('S\d\d'\)"})
  Check ($evidenceLines.Count-eq26-and@($evidenceLines|Where-Object{$_-notmatch"INSERT INTO evidence VALUES\('S\d\d'\);\s*$"}).Count-eq0) 'scenario evidence is the last statement on its runtime.sql line'

  Pass-All
  New-Item $out -ItemType Directory -Force|Out-Null;$blocker=Join-Path $out 'not-a-directory';Set-Content -LiteralPath $blocker -Value 'x'
  $captured=@(& {try{$null=Complete-TestReport -OutputDirectory (Join-Path $blocker 'reports') -CleanupFailure $null -CleanupRan $true -StackRetained $false;'SAVED'}catch{'SAVE-THREW'}} 6>&1|ForEach-Object{[string]$_})
  Check ($captured-contains'SAVE-THREW'-and@($captured|Where-Object{$_-eq'VERDICT PASS'}).Count-eq1-and@($captured|Where-Object{$_-like'PASS     S26 *'}).Count-eq1) 'on-screen report survives a report save failure'

  Pass-All
  $text=Get-Content (Save $null $false) -Raw
  Check ((Get-TestReportVerdict)-eq'PASS'-and$text.Contains('**Verdict:** PASS')) 'full pass verdict'
  Check (@($script:TestReport.Items|Where-Object Result -ne 'pass').Count-eq0-and$text.Contains('| S26 |')-and$text.Contains('| X01 |')) 'every item passes and is listed'
  Check ($script:TestReport.Items.Count-eq36-and$text.Contains('36 passed, 0 failed, 0 not run')-and$text.Contains($script:TestReportScope)-and$text.Contains($script:TestReportOrderNote)) 'counts, scope, and order note saved'

  Initialize-TestReport -ScenarioIds $catalog.scenarios -ScenarioNames $catalog.names;Enter-TestItem 'P01'
  Stop-TestReport 'The Docker engine is not reachable.'
  $null=Complete-TestReport -OutputDirectory $out -CleanupFailure $null -CleanupRan $false -StackRetained $false
  Check ((Result 'P01')-eq'fail'-and(Details 'P01')-match'Docker engine') 'prerequisite failure has a reason'
  Check (@($script:TestReport.Items|Where-Object{$_.Id-notin'P01','X01'-and$_.Result-ne'not run'}).Count-eq0) 'everything after a prerequisite failure is not run'
  Check ((Result 'X01')-eq'pass'-and(Details 'X01')-match'No shared'-and(Get-TestReportVerdict)-eq'FAIL') 'cleanup is reported and the verdict fails'

  $secret='Zq9-'+[guid]::NewGuid().ToString()
  $b64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($secret))
  Start-Report;Register-TestSecret $secret
  $error1="psql:<stdin>:80: ERROR:  assertion failed token=$secret b64=$b64 | pipe <tag> ``tick``"
  $output=(Notices $order[0..2])+@($error1,"psql : $error1",'At D:\repo\tests\run.ps1:192 char:1','+ CategoryInfo : NotSpecified: (psql:<stdin>:80: ERROR: ...)','CONTEXT:  PL/pgSQL function inline_code_block line 6 at ASSERT')
  Set-TestScenarioProgress -ExecutionOrder $order -Output $output -Failed $true -ExitCode 3
  Stop-TestReport 'runtime SQL exit'
  $text=Get-Content (Save $null $false) -Raw
  Check ((@($order[0..2]|ForEach-Object{Result $_})-join',')-eq'pass,pass,pass'-and(Result 'E01')-eq'pass') 'scenarios executed before the failure pass'
  Check ((Result $order[3])-eq'fail'-and(Details $order[3])-match'assertion failed.*CONTEXT') 'failing scenario carries the database error'
  Check (([regex]::Matches((Details $order[3]),'assertion failed')).Count-eq1-and(Details $order[3])-notmatch'CategoryInfo|char:1') 'wrapped PowerShell stderr noise is removed'
  Check (@((@($order[4..25])+@('R02','C01','W01'))|ForEach-Object{Result $_}|Where-Object{$_-ne'not run'}).Count-eq0) 'later scenarios and checks are not run'
  Check (-not$text.Contains($secret)-and-not$text.Contains($b64)-and$text.Contains('[redacted]')-and$text.Contains('\| pipe')-and$text.Contains('&lt;tag&gt;')-and-not$text.Contains('`')) 'secrets are redacted and table cells stay intact'

  Start-Report
  Set-TestScenarioProgress -ExecutionOrder $order -Output @('psql:<stdin>:5: ERROR:  unrecognized configuration parameter') -Failed $true -ExitCode 3
  Stop-TestReport 'runtime SQL exit'
  Check ((Result 'E01')-eq'fail'-and(Details 'E01')-match'configuration parameter'-and(Result $order[0])-eq'not run') 'runtime.sql setup failure belongs to environment setup'

  Start-Report
  Set-TestScenarioProgress -ExecutionOrder $order -Output @() -Failed $true -ExitCode 2
  Stop-TestReport 'runtime SQL exit'
  Check ((Result 'E01')-eq'fail'-and(Details 'E01')-match'exit code 2') 'silent database failure still has a reason'

  Start-Report
  Set-TestScenarioProgress -ExecutionOrder $order -Output ((Notices @())+@('psql:<stdin>:80: ERROR:  first scenario failed')) -Failed $true -ExitCode 3
  Stop-TestReport 'runtime SQL exit'
  Check ((Result 'E01')-eq'pass'-and(Result $order[0])-eq'fail') 'failure after setup belongs to the first scenario'

  Start-Report
  Set-TestScenarioProgress -ExecutionOrder $order -Output ((Notices $order)+@('psql:<stdin>:200: ERROR:  later regression failed')) -Failed $true -ExitCode 3
  Stop-TestReport 'runtime SQL exit'
  Check (@($order|ForEach-Object{Result $_}|Where-Object{$_-ne'pass'}).Count-eq0-and(Result 'R02')-eq'fail'-and(Result 'C01')-eq'not run') 'failure after S26 belongs to the regression checks'

  Start-Report
  Set-TestScenarioProgress -ExecutionOrder $order -Output (Notices $order[1..25]) -Failed $false -ExitCode 0
  Stop-TestReport 'every S01-S26 scenario reported a pass'
  Check ((Result $order[0])-eq'fail'-and(Details $order[0])-match'without reporting'-and(Result 'R02')-eq'not run') 'scenario without a pass signal stops the run'

  Start-Report;Set-TestScenarioProgress -ExecutionOrder $order -Output ('x'*2000) -Failed $true -ExitCode 3
  $long=Get-TestReportFailureDetails @('ERROR: '+('y'*2000)) 3
  Check ($long.Length-eq($script:TestReportDetailLimit+3)) 'failure details are capped'

  Start-Report;Set-TestScenarioProgress -ExecutionOrder $order -Output (Notices $order) -Failed $false -ExitCode 0
  Stop-TestReport 'S01-S26 exact'
  Check ((Result 'R02')-eq'fail'-and(Details 'R02')-match'^Stopped between checks: S01-S26 exact') 'failure between checks is labeled'

  Start-Report;Set-TestScenarioProgress -ExecutionOrder $order -Output (Notices $order) -Failed $false -ExitCode 0;Enter-TestItem 'R02';Enter-TestItem 'C01'
  Stop-TestReport 'SP3-T3 scheduler race evidence exit'
  Check ((Result 'R02')-eq'pass'-and(Result 'C01')-eq'fail'-and(Result 'W01')-eq'not run') 'race failure stops later checks'

  Pass-All;$null=Save 'project volumes remain' $false
  Check ((Result 'X01')-eq'fail'-and(Details 'X01')-eq'project volumes remain'-and(Get-TestReportVerdict)-eq'FAIL') 'cleanup failure fails an otherwise passing run'

  Pass-All;$null=Save $null $true
  Check ((Result 'X01')-eq'pass'-and(Details 'X01')-match'KeepRunning') 'retained stack is reported'

  Initialize-TestReport -ScenarioIds $catalog.scenarios -ScenarioNames $catalog.names;foreach($id in 'P01','T04','T05','T06','R01','E01'){Enter-TestItem $id}
  Stop-TestReport 'reset failed'
  $null=Complete-TestReport -OutputDirectory $out -CleanupFailure $null -CleanupRan $false -StackRetained $false -ResetAttempted $true
  Check ((Result 'X01')-eq'fail'-and(Details 'X01')-match'did not finish') 'unfinished local reset is not reported as clean'

  Start-Report;Enter-TestItem 'R02';Enter-TestItem 'W01'
  $null=Save $null $false
  Check ((Result 'W01')-eq'fail'-and(Details 'W01')-match'interrupted') 'interrupted check fails'

  $before=@(Get-ChildItem $out -Filter 'test-report-*Z.md').Count
  Initialize-TestReport -ScenarioIds $catalog.scenarios -ScenarioNames $catalog.names;Enter-TestItem 'P01';Stop-TestReport 'Another SalesFlow harness is already running.'
  $skipped=Complete-TestReport -OutputDirectory $out -CleanupFailure $null -CleanupRan $false -StackRetained $false -SkipSave $true
  Check ($null-eq$skipped-and@(Get-ChildItem $out -Filter 'test-report-*Z.md').Count-eq$before) 'busy-lock invocation does not save a report'

  Start-Report;Register-TestSecret $secret
  $threw=$false;try{Assert-TestReportSecretFree "leak $secret"}catch{$threw=$true};Check $threw 'report self-check rejects a registered secret'
  $threw=$false;try{Assert-TestReportSecretFree ("leak "+$secret.Substring(0,10)+"`n  "+$secret.Substring(10))}catch{$threw=$true};Check $threw 'report self-check rejects a secret split by whitespace'
  Check ((Protect-TestReportText 'id 0123456789abcdef0123456789abcdef').Contains('[redacted]')-and(Protect-TestReportText 'sha1 0123456789abcdef0123456789abcdef01234567').Contains('01234567')) 'only secret-shaped hex values are masked'
  Check (@(Get-ChildItem $out -Filter 'test-report-*Z.md').Count-ge7) 'reports are saved with UTC names'
}finally{Remove-Item $out -Recurse -Force -ErrorAction SilentlyContinue}
Write-Host 'PASS TestReport all checks'
