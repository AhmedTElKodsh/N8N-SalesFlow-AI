$originalEnv=[IO.File]::ReadAllText($envFile)
try{
# Runs inside the canonical harness after ordinary live workflow scenarios.
# Fixture outcomes are selected only by owner-controlled process configuration.

 docker compose --env-file $envFile stop n8n *> $null;Native 'isolate adapter fixture setup from scheduler'
$fixtures=@();$outcomes=[ordered]@{}
foreach($kind in 'outbox','handoff'){
 foreach($outcome in @('retryable','failed','ambiguous')){
  if($kind-eq'handoff'-and$outcome-eq'ambiguous'){continue}
  $label="review-adapter-$kind-$outcome";$body=if($kind-eq'handoff'){'human'}else{'hello'}
  $seed=ConfigJson "SELECT salesflow.ingest('$rt',jsonb_build_object('account_ref','test-account','provider_id','$label','contact_ref','$label','body','$body'))" "$label seed"
  if($kind-eq'outbox'){$null=ConfigJson "SELECT salesflow.set_consent('$rt','test-account','$($seed.contact_id)'::uuid,'granted','review adapter fixture')" "$label consent"}
  $work=ConfigJson "SELECT salesflow.complete_turn('$rt','test-account','$($seed.conversation_id)'::uuid)" "$label work"
  $id=$work.work_id;if(-not$id){throw "$label failed to persist work"};$outcomes[$id]=$outcome
  $table=if($kind-eq'outbox'){'intents'}else{'handoffs'};$null=ConfigJson "WITH parked AS(UPDATE salesflow.$table SET next_attempt=clock_timestamp()+interval'1 day'WHERE id='$id'RETURNING id)SELECT jsonb_build_object('ok',count(*)=1)FROM parked" "$label parked"
  $fixtures+=@{kind=$kind;outcome=$outcome;id=$id;conversation=$seed.conversation_id}
 }
}

# Claim/finish denial reasons outside the conversation-history sub-route must also carry a mapped HTTP status.
# Seeded and driven to their terminal fixture state via direct SQL while n8n is stopped, so the live scheduler cannot race them.
$statusMapClaimedSeed=ConfigJson "SELECT salesflow.ingest('$rt',jsonb_build_object('account_ref','test-account','provider_id','review-status-map-claimed','contact_ref','review-status-map-claimed','body','human'))" 'status-map already-claimed seed'
$statusMapClaimedId=(docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT id FROM salesflow.handoffs WHERE account_ref='test-account'AND contact_id='$($statusMapClaimedSeed.contact_id)'").Trim();Native 'status-map already-claimed handoff id query'
$null=ConfigJson "WITH claimed AS(UPDATE salesflow.handoffs SET state='claimed',claim=gen_random_uuid(),claim_until=clock_timestamp()+interval'1 hour'WHERE id='$statusMapClaimedId'RETURNING id)SELECT jsonb_build_object('ok',count(*)=1)FROM claimed" 'status-map already-claimed fixture'
$statusMapTerminalSeed=ConfigJson "SELECT salesflow.ingest('$rt',jsonb_build_object('account_ref','test-account','provider_id','review-status-map-terminal','contact_ref','review-status-map-terminal','body','human'))" 'status-map terminal seed'
$statusMapTerminalId=(docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT id FROM salesflow.handoffs WHERE account_ref='test-account'AND contact_id='$($statusMapTerminalSeed.contact_id)'").Trim();Native 'status-map terminal handoff id query'
$statusMapClaim=ConfigJson "SELECT salesflow.claim_handoff('$rt','test-account','$statusMapTerminalId'::uuid)" 'status-map terminal claim'
$null=ConfigJson "SELECT salesflow.finish_handoff('$rt','test-account','$statusMapTerminalId'::uuid,'$($statusMapClaim.claim)'::uuid,'success')" 'status-map terminal finish'

 $fixtureEnv=$originalEnv-replace'(?m)^SALESFLOW_SYNTHETIC_TEST_MODE=.*\r?\n?',''-replace'(?m)^SALESFLOW_SYNTHETIC_OUTCOMES=.*\r?\n?',''
 $fixtureEnv+="`nSALESFLOW_SYNTHETIC_TEST_MODE=review-fixtures-v1`nSALESFLOW_SYNTHETIC_OUTCOMES='"+($outcomes|ConvertTo-Json -Compress)+"'`n"
 [IO.File]::WriteAllText($envFile,$fixtureEnv,[Text.UTF8Encoding]::new($false))
 docker compose --env-file $envFile up -d --no-deps --force-recreate n8n *> $null;Native 'activate controlled synthetic adapter fixtures'
 $script:n8nBase=Resolve-N8nBaseUrl $envFile;$script:base="$n8nBase/webhook/salesflow"
 $ready=$false;for($attempt=0;$attempt-lt60;$attempt++){try{$ready=(Invoke-RestMethod "$n8nBase/healthz" -TimeoutSec 2).status-eq'ok'}catch{};if($ready){break};Start-Sleep -Milliseconds 500};Assert $ready 'fixture n8n ready'
 Assert-HandoffDenial "$base/handoff" $rh (@{work_id=$statusMapClaimedId}|ConvertTo-Json -Compress) 409 'already_claimed'
 Assert-HandoffDenial "$base/handoff" $rh (@{work_id=$statusMapTerminalId}|ConvertTo-Json -Compress) 409 'terminal_state'
 foreach($fixture in $fixtures){
  $path=if($fixture.kind-eq'outbox'){'dispatch'}else{'handoff'}
  # A contradictory public outcome must not override the server-side fixture.
  $table=if($fixture.kind-eq'outbox'){'intents'}else{'handoffs'};$null=ConfigJson "WITH ready AS(UPDATE salesflow.$table SET next_attempt=NULL WHERE id='$($fixture.id)'RETURNING id)SELECT jsonb_build_object('ok',count(*)=1)FROM ready" 'release one live adapter fixture'
  $request=@{work_id=$fixture.id;outcome='success'}|ConvertTo-Json -Compress
  $response=Invoke-RestMethod "$base/$path" -Method Post -Headers $rh -ContentType application/json -Body $request -TimeoutSec 20
  $expected=if($fixture.outcome-eq'retryable'){'pending'}elseif($fixture.outcome-eq'ambiguous'){'reconciliation_required'}elseif($fixture.kind-eq'handoff'){'suppressed'}else{'failed'}
  Assert ($response.result.terminal-eq$expected) "live $($fixture.kind) $($fixture.outcome) returns $expected"
  $table=if($fixture.kind-eq'outbox'){'intents'}else{'handoffs'}
  Wait-WorkflowState "SELECT state FROM salesflow.$table WHERE account_ref='test-account'AND id='$($fixture.id)'" $expected "live $($fixture.kind) durable $($fixture.outcome)"
  if($fixture.outcome-eq'retryable'){$null=ConfigJson "WITH parked AS(UPDATE salesflow.$table SET next_attempt=clock_timestamp()+interval'1 day'WHERE id='$($fixture.id)'RETURNING id)SELECT jsonb_build_object('ok',count(*)=1)FROM parked" 'park verified retryable fixture'}
  if($fixture.kind-eq'outbox'){
   $calls=if($fixture.outcome-eq'retryable'){'0'}else{'1'}
   Wait-WorkflowState "SELECT count(*)FROM salesflow.provider_calls WHERE account_ref='test-account'AND intent_id='$($fixture.id)'" $calls "outbox $($fixture.outcome) call boundary"
  }else{Wait-WorkflowState "SELECT owner FROM salesflow.conversations WHERE account_ref='test-account'AND id='$($fixture.conversation)'" 'human' 'Handoff failure retains Human-Owned lockout'}
 }
 # Exercise the actual terminal fallback with an owner-installed, temporary discovery fixture.
 $originalSchedule=@(docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -Atc "SELECT pg_get_functiondef('salesflow.schedule_work(text,timestamptz)'::regprocedure)")-join"`n";Native 'capture scheduler fixture restore definition'
 try{
  @'
CREATE OR REPLACE FUNCTION salesflow.schedule_work(t text,n timestamptz DEFAULT now())RETURNS TABLE(account_ref text,work_id uuid,workflow_id text)LANGUAGE plpgsql SECURITY DEFINER SET search_path=salesflow,public AS $$BEGIN RETURN QUERY SELECT 'test-account'::text,NULL::uuid,'unexpected-review-work'::text;END$$;
'@|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 *> $null;Native 'install unknown work fixture'
  $unknown=Invoke-RestMethod "$base/followups" -Method Post -Headers $sh -ContentType application/json -Body '{}' -TimeoutSec 20
  $unknownText=$unknown|ConvertTo-Json -Compress -Depth 15
  Assert ($unknown.result.reason-eq'unknown_work_type'-and$null-eq$unknown.token-and-not$unknownText.Contains($scheduler)) 'unknown work terminal strips scheduler credentials'
 }finally{$originalSchedule|docker compose --env-file $envFile exec -T postgres psql -U postgres -d salesflow -v ON_ERROR_STOP=1 *> $null;Native 'restore scheduler discovery function'}
}finally{
 [IO.File]::WriteAllText($envFile,$originalEnv,[Text.UTF8Encoding]::new($false))
 docker compose --env-file $envFile up -d --no-deps --force-recreate n8n *> $null;Native 'disable synthetic adapter fixture configuration'
 $script:n8nBase=Resolve-N8nBaseUrl $envFile;$script:base="$n8nBase/webhook/salesflow"
 $ready=$false;for($attempt=0;$attempt-lt60;$attempt++){try{$ready=(Invoke-RestMethod "$n8nBase/healthz" -TimeoutSec 2).status-eq'ok'}catch{};if($ready){break};Start-Sleep -Milliseconds 500};Assert $ready 'restored n8n ready'
}
