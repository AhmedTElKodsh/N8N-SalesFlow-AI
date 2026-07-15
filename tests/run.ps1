$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
Set-Location $root
function Pass($m){Write-Host "PASS $m"}
function Assert($c,$m){if(!$c){throw $m};Pass $m}
function Native($m){Assert ($LASTEXITCODE-eq0) "$m exit"}
$generated=Join-Path $root '.generated'
$envFile=Join-Path $generated 'runtime.env'
$failure=$null;$cleanupFailure=$null
try {
  $manifest=Get-Content release/release-manifest.json -Raw|ConvertFrom-Json
  $workflows=@(Get-ChildItem workflows -Filter *.json|Sort-Object Name);Assert ($workflows.Count-eq7) 'seven workflows'
  $configs=@(Get-ChildItem config -Filter *.json|Sort-Object Name);Assert ((Compare-Object @($configs.Name) @($manifest.configFiles)).Count-eq0) 'exact config file set'
  Assert ((Compare-Object @($workflows.Name) @($manifest.workflowFiles)).Count-eq0) 'exact workflow file set'
  $releaseSet=Get-Content config/release-set.json -Raw|ConvertFrom-Json;Assert ($releaseSet.reviewedManifestHash-eq$manifest.activationManifestSha256-and$releaseSet.manifestVersion-eq$manifest.activationManifest.version-and$releaseSet.policyVersion-eq$manifest.activationManifest.policyVersion-and$releaseSet.knowledgeVersion-eq$manifest.activationManifest.knowledgeVersion) 'exact activation manifest binding';foreach($p in $manifest.activationManifest.inputHashes.psobject.Properties){Assert ($manifest.inputHashes.($p.Name)-eq$p.Value) "activation input $($p.Name)"}
  $types=@();foreach($f in $workflows){$w=Get-Content $f.FullName -Raw|ConvertFrom-Json;$types+=$w.nodes.type;Assert ($w.settings.saveDataSuccessExecution-eq'none'-and$w.settings.saveDataErrorExecution-eq'none'-and!$w.settings.saveManualExecutions) "$($f.Name) persistence disabled"}
  Assert ((Compare-Object @($types|Sort-Object -Unique) @($manifest.nodeTypes)).Count-eq0) 'approved native nodes exact'
  $w5=Get-Content workflows/05-follow-up-scheduler.json -Raw;Assert ($w5-match'scheduleTrigger'-and$w5-match'schedule_work'-and$w5-match'salesflow-wf-03'-and$w5-match'salesflow-wf-06') 'UTC scheduler chains durable workers'
  Assert (-not((Get-Content workflows/03-outbox-dispatcher.json,workflows/06-handoff-dispatcher.json -Raw)-match'body\.outcome')) 'internal adapter outcomes'
  foreach($p in $manifest.inputHashes.psobject.Properties){Assert ((Get-FileHash $p.Name -Algorithm SHA256).Hash.ToLower()-eq$p.Value) "manifest input $($p.Name)"}
  $ids=(Get-Content tests/pilot-scenarios.json -Raw|ConvertFrom-Json).scenarios;$sql=Get-Content tests/runtime.sql -Raw
  foreach($id in $ids){Assert ($sql-match"INSERT INTO evidence[^;]*\('$id'\)") "$id asserted before marker"}
  Remove-Item $generated -Recurse -Force -ErrorAction SilentlyContinue;New-Item $generated -ItemType Directory|Out-Null;New-Item (Join-Path $generated exported) -ItemType Directory|Out-Null
  $scheduler=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N');$encryption=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N');$super=[guid]::NewGuid().ToString('N');$owner=[guid]::NewGuid().ToString('N');$n8ndb=[guid]::NewGuid().ToString('N');$workflowdb=[guid]::NewGuid().ToString('N')
  $envText=(Get-Content .env.example -Raw)-replace'(?m)^SCHEDULER_TOKEN=.*$',"SCHEDULER_TOKEN=$scheduler"-replace'(?m)^N8N_ENCRYPTION_KEY=.*$',"N8N_ENCRYPTION_KEY=$encryption"-replace'(?m)^POSTGRES_SUPERUSER_PASSWORD=.*$',"POSTGRES_SUPERUSER_PASSWORD=$super"-replace'(?m)^MIGRATION_PASSWORD=.*$',"MIGRATION_PASSWORD=$owner"-replace'(?m)^N8N_DB_PASSWORD=.*$',"N8N_DB_PASSWORD=$n8ndb"-replace'(?m)^WORKFLOW_DB_PASSWORD=.*$',"WORKFLOW_DB_PASSWORD=$workflowdb"
  [IO.File]::WriteAllText($envFile,$envText,[Text.UTF8Encoding]::new($false))
  $ErrorActionPreference='Continue'
  docker compose --env-file $envFile down -v --remove-orphans *> $null;Native 'initial cleanup'
  docker compose --env-file $envFile up -d postgres --wait *> $null;Native 'postgres readiness'
  $migration=(Get-Content database/001-initial.sql -Raw)-replace'__MIGRATION_PASSWORD__',$owner-replace'__WORKFLOW_DB_PASSWORD__',$workflowdb-replace'__N8N_DB_PASSWORD__',$n8ndb
  1..2|%{$migration|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 *> $null;Native "migration $_"}
  $rt=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N');$rt2=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N');$op=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N');$op2=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N')
  $account=Get-Content config/account.json -Raw|ConvertFrom-Json;Assert ($account.accountRef-eq'test-account') 'account config drives fixture';$accountEnabled=if($account.enabled){'true'}else{'false'}
  @"
SET search_path=salesflow,public;INSERT INTO accounts VALUES('$($account.accountRef)',$accountEnabled),('account-b',true);
SELECT bootstrap('$rt','runtime','runtime-a','test-account');SELECT bootstrap('$rt2','runtime','runtime-b','account-b');SELECT bootstrap('$op','operator','operator-a','test-account');SELECT bootstrap('$op2','operator','operator-b','account-b');SELECT bootstrap('$scheduler','scheduler','scheduler',NULL);
INSERT INTO controls VALUES('test-account','stop','{"enabled":false}'),('account-b','stop','{"enabled":false}');
"@|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 *> $null;Native 'account bootstrap'
  foreach($f in Get-ChildItem config -Filter *.json|? Name -ne account.json){$j=Get-Content $f.FullName -Raw;$q=$j-replace"'","''";"SET search_path=salesflow,public;SELECT publish_config('$op','$q');"|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 -At|Out-Null;Native "publish $($f.Name) a";$b=$j|ConvertFrom-Json;$b.accountRef='account-b';$q=(($b|ConvertTo-Json -Compress -Depth 20)-replace"'","''");"SET search_path=salesflow,public;SELECT publish_config('$op2','$q');"|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 -At|Out-Null;Native "publish $($f.Name) b"}
  $priv=docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT has_table_privilege('salesflow_runtime','salesflow.auth_tokens','INSERT')||':'||has_table_privilege('salesflow_runtime','salesflow.audit_events','UPDATE')";Native 'privilege query';Assert ($priv.Trim()-eq'false:false') 'least privilege runtime'
  $activationJson=$manifest.activationManifest|ConvertTo-Json -Compress -Depth 30;$activationB64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($activationJson));$activationHash=$manifest.activationManifestSha256;Get-Content tests/runtime.sql -Raw|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 -v runtime_token=$rt -v runtime_token_2=$rt2 -v operator_token=$op -v scheduler_token=$scheduler -v activation_manifest_b64=$activationB64 -v activation_manifest_hash=$activationHash > (Join-Path $generated runtime.txt);Native 'runtime SQL'
  $line=Get-Content (Join-Path $generated runtime.txt)|?{$_-like'SCENARIOS=*'}|Select-Object -Last 1;Assert ((Compare-Object @($ids|Sort-Object) @(($line-replace'^SCENARIOS=','')-split','|Sort-Object)).Count-eq0) 'S01-S26 exact'
  $jobScript={param($cwd,$ef,$query)Set-Location $cwd;$out=$query|docker compose --env-file $ef exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 -At 2>&1;if($LASTEXITCODE-ne0){throw "native psql failed: $out"};$out}
  function Race($queries,$label){$jobs=@($queries|%{Start-Job -ScriptBlock $jobScript -ArgumentList $root,$envFile,$_});$jobs|Wait-Job|Out-Null;foreach($j in $jobs){Assert ($j.State-eq'Completed') "$label worker native exit"};$jobs|Receive-Job|Out-Null;$jobs|Remove-Job}
  Race @(1..6|%{"SET search_path=salesflow,public;SELECT ingest('$rt',jsonb_build_object('account_ref','test-account','provider_id','parallel-replay','contact_ref','parallel','body','hello'));"}) 'replay'
  $n=docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT count(*) FROM salesflow.inbound_messages WHERE provider_id='parallel-replay'";Native 'replay count';Assert ($n.Trim()-eq'1') 'parallel replay one row'
  Race @(1..6|%{$body=if($_%2){'one'}else{'two'};"SET search_path=salesflow,public;SELECT ingest('$rt',jsonb_build_object('account_ref','test-account','provider_id','parallel-conflict','contact_ref','parallel-conflict','body','$body'));"}) 'conflicting replay'
  $n=docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT count(*) FROM salesflow.inbound_messages WHERE provider_id='parallel-conflict'";Native 'conflicting replay count';Assert ($n.Trim()-eq'1') 'conflicting replay one row'
  $out="SET search_path=salesflow,public;SELECT ingest('$rt',jsonb_build_object('account_ref','test-account','provider_id','parallel-conflict','contact_ref','parallel-conflict','body',CASE WHEN(SELECT body FROM salesflow.inbound_messages WHERE provider_id='parallel-conflict')='one'THEN'two'ELSE'one'END))->>'reason';"|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -At;Native 'conflicting replay verdict';Assert ($out.Trim()-eq'idempotency_conflict') 'conflicting replay rejected'
  Race @(1..6|%{"SET search_path=salesflow,public;SELECT ingest('$rt',jsonb_build_object('account_ref','test-account','provider_id','parallel-seq-$_','contact_ref','parallel-seq','body','hello'));"}) 'sequence'
  $n=docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT count(*)||':'||count(DISTINCT seq) FROM salesflow.inbound_messages WHERE provider_id LIKE'parallel-seq-%'";Native 'sequence count';Assert ($n.Trim()-eq'6:6') 'parallel sequence unique'
  $credential=ConvertTo-Json -InputObject @(@{id='salesflow-postgres-local';name='SalesFlow PostgreSQL';type='postgres';data=@{host='postgres';database='salesflow';user='salesflow_runtime';password=$workflowdb;port=5432;ssl='disable'}}) -Depth 6
  [IO.File]::WriteAllText((Join-Path $generated credentials.json),$credential,[Text.UTF8Encoding]::new($false))
  docker compose --env-file $envFile up -d n8n *> $null;Native 'n8n start'
  $ready=$false;for($i=0;$i-lt60;$i++){try{$null=Invoke-WebRequest http://127.0.0.1:5678/healthz -UseBasicParsing -TimeoutSec 2;$ready=$true;break}catch{Start-Sleep 2}};Assert $ready 'bounded n8n readiness'
  docker compose --env-file $envFile exec -T n8n n8n import:credentials --input=/generated/credentials.json *> $null;Native 'credential import'
  docker compose --env-file $envFile exec -T n8n n8n import:workflow --separate --input=/repo/workflows *> $null;Native 'workflow import'
  1..7|%{docker compose --env-file $envFile exec -T n8n n8n update:workflow --id="salesflow-wf-0$_" --active=true *> $null;Native "workflow 0$_ activate";docker compose --env-file $envFile exec -T n8n n8n publish:workflow --id="salesflow-wf-0$_" *> $null;Native "workflow 0$_ publish"}
  docker compose --env-file $envFile restart n8n *> $null;Native 'n8n restart'
  $ready=$false;for($i=0;$i-lt60;$i++){try{$null=Invoke-WebRequest http://127.0.0.1:5678/healthz -UseBasicParsing -TimeoutSec 2;$ready=$true;break}catch{Start-Sleep 2}};Assert $ready 'bounded published readiness'
  @'
SET search_path=salesflow,public;
SELECT set_config('sf.rt',:'rt',false);
DO $fixture$DECLARE rt text:=current_setting('sf.rt');r jsonb;r2 jsonb;i uuid;h uuid;BEGIN
  r:=ingest(rt,'{"account_ref":"test-account","provider_id":"scheduled-recovery-out","contact_ref":"scheduled-recovery-out","body":"hello"}');PERFORM set_consent(rt,'test-account',(r->>'contact_id')::uuid,'granted','schedule-fixture');r2:=complete_turn(rt,'test-account',(r->>'conversation_id')::uuid);i:=(r2->>'work_id')::uuid;r2:=claim_dispatch(rt,'test-account',i,now());UPDATE intents SET lease_until=now()-interval'1 sec'WHERE(account_ref,id)=('test-account',i);
  r:=ingest(rt,'{"account_ref":"test-account","provider_id":"scheduled-recovery-handoff","contact_ref":"scheduled-recovery-handoff","body":"human"}');r2:=complete_turn(rt,'test-account',(r->>'conversation_id')::uuid);h:=(r2->>'work_id')::uuid;r2:=claim_handoff(rt,'test-account',h,now());UPDATE handoffs SET claim_until=now()-interval'1 sec'WHERE(account_ref,id)=('test-account',h);
END$fixture$;
'@|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 -v rt=$rt *> $null;Native 'scheduled recovery fixture'
  $scheduled=$false;for($i=0;$i-lt45;$i++){$n=docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT(SELECT count(*)FROM salesflow.intents x JOIN salesflow.contacts c ON(c.account_ref,c.id)=(x.account_ref,x.contact_id)WHERE c.external_ref='scheduled-recovery-out'AND x.state='sent')+(SELECT count(*)FROM salesflow.handoffs h JOIN salesflow.contacts c ON(c.account_ref,c.id)=(h.account_ref,h.contact_id)WHERE c.external_ref='scheduled-recovery-handoff'AND h.state='acknowledged')";Native 'scheduled recovery poll';if($n.Trim()-eq'2'){$scheduled=$true;break};Start-Sleep 2};Assert $scheduled 'native UTC schedule recovers expired outbound and Handoff claims'
  docker compose --env-file $envFile exec -T n8n n8n export:workflow --all --separate --output=/generated/exported *> $null;Native 'workflow export'
  $source=docker compose --env-file $envFile exec -T n8n node /repo/scripts/canonicalize-workflows.mjs /repo/workflows|ConvertFrom-Json;Native 'source canonicalization'
  $export=docker compose --env-file $envFile exec -T n8n node /repo/scripts/canonicalize-workflows.mjs /generated/exported|ConvertFrom-Json;Native 'export canonicalization'
  Assert ($source.combinedSha256-eq$manifest.combinedWorkflowSha256) 'source workflow identity'
  Assert ($export.count-eq7-and$export.combinedSha256-eq$source.combinedSha256) 'imported export identity'
  $exportText=(Get-ChildItem (Join-Path $generated exported)-File|Get-Content -Raw)-join'';foreach($secret in @($rt,$rt2,$op,$op2,$scheduler,$super,$owner,$n8ndb,$workflowdb)){Assert (-not$exportText.Contains($secret)) 'export secret scan'}
  $rh=@{'x-salesflow-token'=$rt};$oh=@{'x-salesflow-token'=$op};$sh=@{'x-salesflow-token'=$scheduler};$base='http://127.0.0.1:5678/webhook/salesflow'
  $rej=Invoke-RestMethod "$base/inbound" -Method Post -Headers $rh -ContentType application/json -Body '{}';Assert ($rej.result.accepted-eq$false) 'ingress rejection terminal'
  $ing=Invoke-RestMethod "$base/inbound" -Method Post -Headers $rh -ContentType application/json -Body '{"account_ref":"test-account","provider_id":"live","contact_ref":"live","body":"hello"}';Assert ($ing.result.reason-eq'consent_missing') '01 to 02 fail closed'
  $cid=docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT id FROM salesflow.contacts WHERE account_ref='test-account'AND external_ref='live'";Native 'live id';$cid=$cid.Trim()
  "SET search_path=salesflow,public;SELECT set_consent('$rt','test-account','$cid','granted','live-test');"|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 *> $null;Native 'live consent'
  $d=Invoke-RestMethod "$base/inbound" -Method Post -Headers $rh -ContentType application/json -Body '{"account_ref":"test-account","provider_id":"live-consented","contact_ref":"live","body":"hello again"}';Assert ($d.result.terminal-eq'sent') '01 to 03 automatic dispatch'
  $cb=Invoke-RestMethod "$base/status" -Method Post -Headers $rh -ContentType application/json -Body (@{account_ref='test-account';event_id='live-event';provider_id=$d.result.provider_id;status='delivered';provider_time=(Get-Date).ToUniversalTime().ToString('o')}|ConvertTo-Json);Assert ($cb.result.status-eq'delivered') '04 live callback'
  $raceTime=(Get-Date).ToUniversalTime().ToString('o');$raceBody=(@{account_ref='test-account';event_id='live-race';provider_id=$d.result.provider_id;status='read';provider_time=$raceTime}|ConvertTo-Json -Compress)-replace"'","''";Race @(1..6|%{"SET search_path=salesflow,public;SELECT callback('$rt','$raceBody'::jsonb);"}) 'callback replay';$n=docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT count(*)FROM salesflow.provider_events WHERE account_ref='test-account'AND event_id='live-race'";Native 'callback race count';Assert ($n.Trim()-eq'1') 'parallel callback one event'
  @"
SET search_path=salesflow,public;
SELECT ingest('$rt',jsonb_build_object('account_ref','test-account','provider_id','live-follow','contact_ref','live-follow','body','hello'));
SELECT set_consent('$rt','test-account',id,'granted','live')FROM contacts WHERE account_ref='test-account'AND external_ref='live-follow';
INSERT INTO followups(account_ref,contact_id,conversation_id,due_at,expected_version)SELECT v.account_ref,v.contact_id,v.id,now()-interval'1 min',v.version FROM conversations v JOIN contacts c ON(c.account_ref,c.id)=(v.account_ref,v.contact_id)WHERE c.account_ref='test-account'AND c.external_ref='live-follow';
"@|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 *> $null;Native 'live followup fixture'
  $null=Invoke-RestMethod "$base/followups" -Method Post -Headers $sh -ContentType application/json -Body '{}'
  $n=docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT count(*) FROM salesflow.intents WHERE kind='followup'AND state='sent'";Native 'followup terminal query';Assert ([int]$n.Trim()-ge1) '05 schedules and dispatches'
  $human=Invoke-RestMethod "$base/inbound" -Method Post -Headers $rh -ContentType application/json -Body '{"account_ref":"test-account","provider_id":"live-human","contact_ref":"live-human","body":"human"}';Assert ($human.result.terminal-eq'acknowledged') '01 to 06 automatic Handoff'
  $ops=Invoke-RestMethod "$base/operations" -Method Post -Headers $oh -ContentType application/json -Body '{"action":"evidence"}';Assert ($ops.result.account_ref-eq'test-account') '07 account evidence'
  Pass 'FULL PASS'
}catch{$failure=$_}
finally{
  if(Test-Path $envFile){docker compose --env-file $envFile down -v --remove-orphans *> $null;if($LASTEXITCODE-ne0){$cleanupFailure='compose cleanup exit'}}
  Remove-Item $generated -Recurse -Force -ErrorAction SilentlyContinue
  if(Test-Path $generated){$cleanupFailure='plaintext generated directory remains'}
  $volumes=@(docker volume ls --filter 'label=com.docker.compose.project=n8n-salesflow-ai' -q)
  if($LASTEXITCODE-ne0){$cleanupFailure='volume inventory exit'}elseif($volumes){docker volume rm $volumes *> $null;if($LASTEXITCODE-ne0){$cleanupFailure='project volume removal exit'}}
  $remaining=@(docker volume ls --filter 'label=com.docker.compose.project=n8n-salesflow-ai' -q)
  if($LASTEXITCODE-ne0-or$remaining){$cleanupFailure='project volumes remain'}
}
if($cleanupFailure){throw $cleanupFailure}
Pass 'plaintext credentials removed'
Pass 'container volumes removed'
if($failure){throw $failure}
