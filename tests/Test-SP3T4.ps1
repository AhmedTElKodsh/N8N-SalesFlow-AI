param()
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$container='salesflow-sp3t4-'+[guid]::NewGuid().ToString('N')
$jobs=@();$launched=$false
function Query([string]$sql){
  $output=$sql|docker exec -i -e PGOPTIONS=-cclient_min_messages=error $container psql -U postgres -v ON_ERROR_STOP=1 -qAt 2>&1
  if($LASTEXITCODE-ne0){throw "SP3-T4 SQL failed: $($output -join [Environment]::NewLine)"}
  $output
}
function Check($condition,[string]$label){if(-not$condition){throw "SP3-T4 $label"};Write-Host "PASS SP3-T4 $label"}
try{
  $manifest=Get-Content (Join-Path $root 'release/release-manifest.json') -Raw|ConvertFrom-Json
  $image=[string]$manifest.images[0]
  Check ($image-match'^postgres@sha256:[a-f0-9]{64}$') 'pinned PostgreSQL image'
  $password=[guid]::NewGuid().ToString('N')

  # A generated container is the complete isolation boundary; no host ports or volumes.
  docker run --detach --rm --name $container --network none -e "POSTGRES_PASSWORD=$password" $image *> $null
  Check ($LASTEXITCODE-eq0) 'disposable PostgreSQL started'
  $launched=$true
  $ready=$false
  for($n=0;$n-lt60;$n++){docker exec $container pg_isready -U postgres *> $null;if($LASTEXITCODE-eq0){$ready=$true;break};Start-Sleep -Milliseconds 250}
  Check $ready 'database ready'
  $migration=Get-Content (Join-Path $root 'database/001-initial.sql') -Raw
  $encoded=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($password))
  foreach($placeholder in @('__MIGRATION_PASSWORD_B64__','__WORKFLOW_DB_PASSWORD_B64__','__N8N_DB_PASSWORD_B64__')){$migration=$migration.Replace($placeholder,$encoded)}
  Query $migration|Out-Null;Write-Host 'PASS SP3-T4 migration 1'
  Query "SET search_path=salesflow,public;INSERT INTO accounts VALUES('sp3t4',true);INSERT INTO controls VALUES('sp3t4','stop','{`"enabled`":false}');SELECT bootstrap('sp3t4-runtime','runtime','sp3t4','sp3t4');SELECT bootstrap('sp3t4-operator','operator','sp3t4','sp3t4');"|Out-Null
  foreach($file in Get-ChildItem (Join-Path $root 'config') -Filter *.json|Where-Object Name -ne 'account.json'){
    $doc=Get-Content $file.FullName -Raw|ConvertFrom-Json;$doc.accountRef='sp3t4'
    $json=($doc|ConvertTo-Json -Compress -Depth 30).Replace("'","''")
    $result=Query "SELECT salesflow.save_config('sp3t4-operator','$json');"|ConvertFrom-Json
    Check $result.created "save $($file.Name)"
    $result=Query "SELECT salesflow.activate_config('sp3t4-operator','sp3t4','$($doc.kind)','$($doc.version)',NULL);"|ConvertFrom-Json
    Check $result.activated "activate $($file.Name)"
  }
  Query (Get-Content (Join-Path $PSScriptRoot 'sp3-t4.sql') -Raw)|ForEach-Object{Write-Host $_}
  2..3|ForEach-Object{Query $migration|Out-Null;Write-Host "PASS SP3-T4 migration $_"}
  $upgrade=Query "SET search_path=salesflow,public;WITH upgrade_conversations AS(SELECT v.id FROM conversations v JOIN contact_identifiers ci ON(ci.account_ref,ci.contact_id)=(v.account_ref,v.contact_id)WHERE v.account_ref='sp3t4'AND ci.external_ref LIKE 'upgrade-%')SELECT count(*)FILTER(WHERE state='suppressed'AND reason='human_owned')||':'||(SELECT count(*)FROM intent_transitions it WHERE it.account_ref='sp3t4'AND it.reason='human_owned'AND it.to_state='suppressed'AND it.intent_id IN(SELECT id FROM intents WHERE conversation_id IN(SELECT id FROM upgrade_conversations)))||':'||(SELECT count(*)FROM followups WHERE account_ref='sp3t4'AND conversation_id IN(SELECT id FROM upgrade_conversations)AND state='cancelled'AND reason='human_owned')||':'||(SELECT count(*)FROM followup_transitions WHERE account_ref='sp3t4'AND reason='human_owned'AND to_state='cancelled'AND followup_id IN(SELECT id FROM followups WHERE conversation_id IN(SELECT id FROM upgrade_conversations)))||':'||(SELECT count(*)FROM intent_transitions it JOIN intents i ON(i.account_ref,i.id)=(it.account_ref,it.intent_id)JOIN conversations v ON(v.account_ref,v.id)=(i.account_ref,i.conversation_id)JOIN contact_identifiers ci ON(ci.account_ref,ci.contact_id)=(v.account_ref,v.contact_id)WHERE it.account_ref='sp3t4'AND ci.external_ref='upgrade-retry'AND it.from_state='retry'AND it.to_state='suppressed'AND it.reason='human_owned')FROM intents WHERE account_ref='sp3t4'AND conversation_id IN(SELECT id FROM upgrade_conversations)AND kind<>'followup';"
  Check ($upgrade.Trim()-eq'5:5:1:1:1') "migration backfills existing Human-Owned automation, including retry, exactly once: $($upgrade.Trim())"
  $worker={param($name,$sql)$out=$sql|docker exec -i -e PGOPTIONS=-cclient_min_messages=error $name psql -U postgres -v ON_ERROR_STOP=1 -qAt 2>&1;if($LASTEXITCODE-ne0){throw "SP3-T4 worker SQL failed: $out"};$out}
  foreach($order in @('human-first','call-first')){
    $fixture=Query "SELECT salesflow.sp3t4_seed('$order',true);"|ConvertFrom-Json
    $start="SELECT salesflow.begin_provider_call('sp3t4-runtime','sp3t4','$($fixture.work)'::uuid,'$($fixture.lease)'::uuid);"
    $human="SELECT salesflow.ingest('sp3t4-runtime',jsonb_build_object('account_ref','sp3t4','provider_id','$order-human','contact_ref','$order','body','talk to a human'));"
    $first=if($order-eq'human-first'){$human}else{$start}
    $job=Start-Job -ScriptBlock $worker -ArgumentList $container,"SET search_path=salesflow,public;BEGIN;$first SELECT pg_advisory_xact_lock(hashtextextended('$order-ready',0));SELECT pg_sleep(4);COMMIT;"
    $jobs+= $job;$ready=$false
    for($n=0;$n-lt40;$n++){if((Query "SELECT NOT pg_try_advisory_xact_lock(hashtextextended('$order-ready',0));").Trim()-eq't'){$ready=$true;break};Start-Sleep -Milliseconds 100}
    Check $ready "$order barrier observed"
    if($order-eq'human-first'){$r=Query $start|ConvertFrom-Json;Check ($r.reason-eq'busy') 'handoff transaction excludes concurrent call'}else{$r=Query $human|ConvertFrom-Json;Check $r.accepted 'human ingest waits for started call'}
    $null=$job|Wait-Job -Timeout 20;Check ($job.State-eq'Completed') "$order worker completed";$job|Receive-Job|Out-Null
    if($order-eq'human-first'){$r=Query $start|ConvertFrom-Json;Check (-not$r.ok) 'committed handoff blocks retained lease'}else{$r=Query "SELECT salesflow.finish_dispatch('sp3t4-runtime','sp3t4','$($fixture.work)'::uuid,'$($fixture.lease)'::uuid,'success');"|ConvertFrom-Json;Check ($r.terminal-eq'sent') 'already started call completes'}
    $expected=if($order-eq'human-first'){'0:human:1:0'}else{'1:human:1:0'}
    $actual=Query "SELECT (SELECT count(*)FROM salesflow.provider_calls WHERE intent_id='$($fixture.work)')||':'||(SELECT owner FROM salesflow.conversations WHERE id='$($fixture.conv)')||':'||(SELECT count(*)FROM salesflow.handoffs WHERE conversation_id='$($fixture.conv)')||':'||(SELECT count(*)FROM salesflow.followups WHERE conversation_id='$($fixture.conv)'AND state IN('due','claimed','retry','intent_created'));"
    Check ($actual.Trim()-eq$expected) "$order durable outcome"
  }
  Write-Host 'PASS SP3-T4 FULL PASS'
}finally{
  foreach($job in $jobs){if($job.State-eq'Running'){$job|Stop-Job};$job|Remove-Job -Force -ErrorAction SilentlyContinue}
  if($launched){docker rm --force --volumes $container *> $null;Check ($LASTEXITCODE-eq0) 'disposable container and volumes removed'}


}


