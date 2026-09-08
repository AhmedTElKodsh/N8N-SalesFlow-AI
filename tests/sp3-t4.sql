\set ON_ERROR_STOP on
SET search_path=salesflow,public;
-- Helpers live only in the disposable test database.
CREATE FUNCTION sp3t4_seed(label text,leased boolean DEFAULT false)RETURNS jsonb LANGUAGE plpgsql SET search_path=salesflow,public AS $$
DECLARE r jsonb;s jsonb;l jsonb;BEGIN
 r:=ingest('sp3t4-runtime',jsonb_build_object('account_ref','sp3t4','provider_id',label||'-source','contact_ref',label,'body','hello'));
 ASSERT (r->>'created')::bool IS TRUE,'seed ingest';
 PERFORM set_consent('sp3t4-runtime','sp3t4',(r->>'contact_id')::uuid,'granted','synthetic acceptance');
 s:=complete_turn('sp3t4-runtime','sp3t4',(r->>'conversation_id')::uuid);
 ASSERT s->>'terminal' IS NOT DISTINCT FROM 'created','seed reply: '||s;
 IF leased THEN l:=claim_dispatch('sp3t4-runtime','sp3t4',(s->>'work_id')::uuid,clock_timestamp());ASSERT (l->>'ok')::bool IS TRUE,'seed claim: '||l;UPDATE intents SET lease_until=clock_timestamp()+interval'1 hour'WHERE id=(s->>'work_id')::uuid;END IF;
 RETURN jsonb_build_object('conv',r->>'conversation_id','contact',r->>'contact_id','work',s->>'work_id','lease',l->>'lease');
END$$;
CREATE FUNCTION sp3t4_seed_followup(label text,target_state text)RETURNS jsonb LANGUAGE plpgsql SET search_path=salesflow,public AS $$
DECLARE fixture jsonb;r jsonb;f followups;child uuid;BEGIN
 fixture:=sp3t4_seed(label,true);
 r:=begin_provider_call('sp3t4-runtime','sp3t4',(fixture->>'work')::uuid,(fixture->>'lease')::uuid);ASSERT r->>'terminal' IS NOT DISTINCT FROM 'started','follow-up seed call-start: '||r;
 r:=finish_dispatch('sp3t4-runtime','sp3t4',(fixture->>'work')::uuid,(fixture->>'lease')::uuid,'success');ASSERT r->>'terminal' IS NOT DISTINCT FROM 'sent','follow-up seed send: '||r;
 SELECT*INTO f FROM followups WHERE account_ref='sp3t4'AND source_intent_id=(fixture->>'work')::uuid;
 ASSERT f.id IS NOT NULL,'follow-up seed parent missing';
 IF target_state='claimed'THEN UPDATE followups SET state='claimed',claim=gen_random_uuid(),claim_until=clock_timestamp()+interval'1 hour'WHERE id=f.id;
 ELSIF target_state='retry'THEN UPDATE followups SET state='retry',next_attempt=clock_timestamp()+interval'1 hour'WHERE id=f.id;
 ELSIF target_state='intent_created'THEN
  INSERT INTO intents(account_ref,contact_id,conversation_id,source_id,kind,expected_version,policy_version,knowledge_version,body,template_key,provenance)
  VALUES(f.account_ref,f.contact_id,f.conversation_id,f.id,'followup',f.expected_version,f.policy_version,f.knowledge_version,'Synthetic follow-up.',f.template_key,jsonb_build_object('sourceIds',jsonb_build_array('source-1'),'offerId','offer-1','claims',jsonb_build_array('service-count'),'confidence',1.0,'context',jsonb_build_object('releaseSetVersion',f.release_set_version,'consentOccurredAt',f.consent_occurred_at,'consentEvidenceHash',f.consent_evidence_hash,'followupId',f.id,'followupCorrelationId',f.correlation_id,'campaignIdentity',f.campaign_identity,'campaignSnapshot',f.campaign_snapshot,'actionKey',f.action_key,'sourceConversationVersion',f.source_conversation_version,'templateKey',f.template_key,'requestHash',f.request_hash)))RETURNING id INTO child;
  UPDATE followups SET state='intent_created',intent_id=child WHERE id=f.id;
 END IF;
 RETURN fixture||jsonb_build_object('follow',f.id,'child',child,'target',target_state);
END$$;
DO $$DECLARE r jsonb;s jsonb;fixture jsonb;label text;conv uuid;old_model jsonb;BEGIN
 r:=ingest('sp3t4-runtime',jsonb_build_object('account_ref','sp3t4','provider_id','explicit','contact_ref','explicit','body',E' \tTalk  to a HUMAN\r\n '));conv:=(r->>'conversation_id')::uuid;
 ASSERT EXISTS(SELECT 1 FROM conversations WHERE id=conv AND owner='human'),'normalized talk to a human must transfer ownership';
 ASSERT (SELECT count(*)=1 FROM handoffs WHERE conversation_id=conv AND reason='human_requested'),'explicit reason';
 PERFORM ingest('sp3t4-runtime','{"account_ref":"sp3t4","provider_id":"explicit-2","contact_ref":"explicit","body":"human"}');
 PERFORM ingest('sp3t4-runtime','{"account_ref":"sp3t4","provider_id":"explicit-2","contact_ref":"explicit","body":"human"}');
 ASSERT (SELECT count(*)=1 FROM handoffs WHERE conversation_id=conv),'distinct repeated requests deduplicate';
 FOREACH label IN ARRAY ARRAY['talk to a human later','not qualified','hello']LOOP
  r:=ingest('sp3t4-runtime',jsonb_build_object('account_ref','sp3t4','provider_id',label,'contact_ref',label,'body',label));
  PERFORM set_consent('sp3t4-runtime','sp3t4',(r->>'contact_id')::uuid,'granted','negative fixture');
  s:=complete_turn('sp3t4-runtime','sp3t4',(r->>'conversation_id')::uuid);
  ASSERT s->>'terminal' IS NOT DISTINCT FROM 'created','near miss stays automated: '||label;
 END LOOP;
 FOREACH label IN ARRAY ARRAY['qualified','uncertain']LOOP
  IF label='uncertain'THEN SELECT body INTO old_model FROM config_docs WHERE account_ref='sp3t4'AND kind='model'AND active;PERFORM save_config('sp3t4-operator',old_model||'{"version":"model-no-grounding","allowedClaims":["other"]}');PERFORM activate_config('sp3t4-operator','sp3t4','model','model-no-grounding',old_model->>'version');END IF;
  r:=ingest('sp3t4-runtime',jsonb_build_object('account_ref','sp3t4','provider_id',label,'contact_ref',label,'body',label));
  PERFORM set_consent('sp3t4-runtime','sp3t4',(r->>'contact_id')::uuid,'granted','trigger fixture');s:=complete_turn('sp3t4-runtime','sp3t4',(r->>'conversation_id')::uuid);
  ASSERT s->>'terminal' IS NOT DISTINCT FROM 'handoff','threshold or grounding handoff';
  ASSERT s->>'reason' IS NOT DISTINCT FROM CASE WHEN label='qualified'THEN'qualification_threshold'ELSE'grounding_invalid'END,'trigger reason';
  ASSERT EXISTS(SELECT 1 FROM handoffs WHERE conversation_id=(r->>'conversation_id')::uuid AND reason=s->>'reason' AND evidence->>'qualificationScore'=CASE WHEN label='qualified'THEN evidence->>'handoffScore'ELSE'1'END),'exact durable trigger evidence';
  ASSERT NOT EXISTS(SELECT 1 FROM intents WHERE conversation_id=(r->>'conversation_id')::uuid),'handoff trigger creates no customer reply';
  IF label='uncertain'THEN PERFORM activate_config('sp3t4-operator','sp3t4','model',old_model->>'version','model-no-grounding');END IF;
 END LOOP;
 FOREACH label IN ARRAY ARRAY['pending','leased','retry','ack']LOOP
  fixture:=sp3t4_seed(label,label IN('leased','retry','ack'));
  IF label='ack'THEN INSERT INTO intents(account_ref,contact_id,conversation_id,source_id,kind,expected_version,policy_version,knowledge_version,body,provenance,state,lease,lease_until,attempts)SELECT account_ref,contact_id,conversation_id,source_id,'handoff_ack',expected_version,policy_version,knowledge_version,body,provenance,state,lease,lease_until,attempts FROM intents WHERE id=(fixture->>'work')::uuid RETURNING jsonb_set(fixture,'{work}',to_jsonb(id::text))INTO fixture;END IF;
  IF label='retry'THEN s:=finish_dispatch('sp3t4-runtime','sp3t4',(fixture->>'work')::uuid,(fixture->>'lease')::uuid,'retryable');ASSERT s->>'terminal' IS NOT DISTINCT FROM 'pending','retry fixture';UPDATE intents SET state='retry',reason='synthetic_retry_fixture'WHERE id=(fixture->>'work')::uuid;END IF;
  PERFORM ingest('sp3t4-runtime',jsonb_build_object('account_ref','sp3t4','provider_id',label||'-human','contact_ref',label,'body','human'));
  ASSERT EXISTS(SELECT 1 FROM intents WHERE id=(fixture->>'work')::uuid AND state='suppressed'AND reason='human_owned'),'handoff durably suppresses '||label;
  ASSERT EXISTS(SELECT 1 FROM intent_transitions WHERE intent_id=(fixture->>'work')::uuid AND to_state='suppressed'AND reason='human_owned'),'suppression transition '||label;
  IF label='retry'THEN ASSERT EXISTS(SELECT 1 FROM intent_transitions WHERE intent_id=(fixture->>'work')::uuid AND from_state='retry'AND to_state='suppressed'AND reason='human_owned'),'actual retry branch suppression transition';END IF;
  s:=begin_provider_call('sp3t4-runtime','sp3t4',(fixture->>'work')::uuid,(fixture->>'lease')::uuid);ASSERT (s->>'ok')::bool IS FALSE,'old lease cannot start';
  ASSERT NOT EXISTS(SELECT 1 FROM provider_calls WHERE intent_id=(fixture->>'work')::uuid),'no blocked customer call';
  END LOOP;

  fixture:=sp3t4_seed('reconciliation-takeover',true);
  s:=begin_provider_call('sp3t4-runtime','sp3t4',(fixture->>'work')::uuid,(fixture->>'lease')::uuid);ASSERT s->>'terminal' IS NOT DISTINCT FROM 'started','reconciliation fixture starts exactly one call';
  s:=finish_dispatch('sp3t4-runtime','sp3t4',(fixture->>'work')::uuid,(fixture->>'lease')::uuid,'ambiguous');ASSERT s->>'terminal' IS NOT DISTINCT FROM 'reconciliation_required','ambiguous outcome requires reconciliation';
  PERFORM ingest('sp3t4-runtime',jsonb_build_object('account_ref','sp3t4','provider_id','reconciliation-takeover-human','contact_ref','reconciliation-takeover','body','human'));
  ASSERT EXISTS(SELECT 1 FROM intents WHERE id=(fixture->>'work')::uuid AND state='reconciliation_required'AND reason='ambiguous'),'handoff preserves reconciliation work';
  s:=claim_dispatch('sp3t4-runtime','sp3t4',(fixture->>'work')::uuid,clock_timestamp());ASSERT s->>'terminal' IS NOT DISTINCT FROM 'reconciliation_required','reconciliation work cannot be claimed again';
  s:=begin_provider_call('sp3t4-runtime','sp3t4',(fixture->>'work')::uuid,(fixture->>'lease')::uuid);ASSERT s->>'terminal' IS NOT DISTINCT FROM 'already_started','reconciliation work reuses durable provider-call evidence';
  ASSERT (SELECT count(*)=1 FROM provider_calls WHERE intent_id=(fixture->>'work')::uuid),'handoff cannot create a second call for reconciliation work';
 ASSERT ingest('sp3t4-runtime','{"account_ref":"other","provider_id":"x","contact_ref":"x","body":"human"}')->>'reason' IS NOT DISTINCT FROM 'wrong_account','account isolation';
 r:=ingest('sp3t4-runtime','{"account_ref":"sp3t4","provider_id":"stop","contact_ref":"stop","body":"stop"}');
 PERFORM ingest('sp3t4-runtime','{"account_ref":"sp3t4","provider_id":"stop-human","contact_ref":"stop","body":"human"}');
 ASSERT NOT EXISTS(SELECT 1 FROM handoffs WHERE conversation_id=(r->>'conversation_id')::uuid),'optout precedence';

 fixture:=sp3t4_seed('operator-optout-human',true);
 s:=set_conversation_state('sp3t4-operator','sp3t4',(fixture->>'conv')::uuid,'opted_out','human',NULL);
 ASSERT (s->>'ok')::bool IS TRUE AND s->>'lifecycle' IS NOT DISTINCT FROM 'opted_out'AND s->>'owner' IS NOT DISTINCT FROM 'human','combined operator state change';
 ASSERT EXISTS(SELECT 1 FROM intents WHERE id=(fixture->>'work')::uuid AND state='suppressed'AND reason='opted_out'),'combined operator takeover suppresses customer work with lifecycle precedence';
 ASSERT EXISTS(SELECT 1 FROM intent_transitions WHERE intent_id=(fixture->>'work')::uuid AND to_state='suppressed'AND reason='opted_out'),'combined operator takeover records transition evidence';

 FOREACH label IN ARRAY ARRAY['due','claimed','retry','intent_created']LOOP
  fixture:=sp3t4_seed_followup('cancel-'||label,label);
  PERFORM ingest('sp3t4-runtime',jsonb_build_object('account_ref','sp3t4','provider_id','cancel-'||label||'-human','contact_ref','cancel-'||label,'body','human'));
  ASSERT EXISTS(SELECT 1 FROM followups WHERE id=(fixture->>'follow')::uuid AND state='cancelled'AND reason='human_owned'),'handoff cancels follow-up parent '||label;
  ASSERT EXISTS(SELECT 1 FROM followup_transitions WHERE followup_id=(fixture->>'follow')::uuid AND to_state='cancelled'AND reason='human_owned'),'handoff records follow-up transition '||label;
  IF label='intent_created'THEN ASSERT EXISTS(SELECT 1 FROM intents WHERE id=(fixture->>'child')::uuid AND state='suppressed'AND reason='human_owned'),'handoff suppresses follow-up child';END IF;
 END LOOP;

 INSERT INTO accounts VALUES('sp3t4-missing',true);INSERT INTO controls VALUES('sp3t4-missing','stop','{"enabled":false}');
 PERFORM bootstrap('sp3t4-missing-runtime','runtime','sp3t4-missing','sp3t4-missing');
 INSERT INTO config_docs(account_ref,kind,version,body,active,created_at)SELECT'sp3t4-missing',kind,version,jsonb_set(body,'{accountRef}','"sp3t4-missing"'),active,created_at FROM config_docs WHERE account_ref='sp3t4'AND active AND kind<>'handoff';
 r:=ingest('sp3t4-missing-runtime','{"account_ref":"sp3t4-missing","provider_id":"missing-handoff","contact_ref":"missing-handoff","body":"talk to a human"}');
 ASSERT r->>'reason' IS NOT DISTINCT FROM 'missing_handoff_config','missing handoff configuration is typed';
 ASSERT NOT EXISTS(SELECT 1 FROM inbound_messages WHERE account_ref='sp3t4-missing')AND NOT EXISTS(SELECT 1 FROM handoffs WHERE account_ref='sp3t4-missing')AND NOT EXISTS(SELECT 1 FROM conversations WHERE account_ref='sp3t4-missing'AND owner='human'),'missing handoff configuration cannot partially transfer or act';

 FOREACH label IN ARRAY ARRAY['pending','leased','retry','ack']LOOP
  fixture:=sp3t4_seed('upgrade-'||label,label IN('leased','retry','ack'));
  IF label='retry'THEN PERFORM finish_dispatch('sp3t4-runtime','sp3t4',(fixture->>'work')::uuid,(fixture->>'lease')::uuid,'retryable');UPDATE intents SET state='retry',reason='synthetic_upgrade_retry_fixture'WHERE id=(fixture->>'work')::uuid;END IF;
  IF label='ack'THEN INSERT INTO intents(account_ref,contact_id,conversation_id,source_id,kind,expected_version,policy_version,knowledge_version,body,provenance,state,lease,lease_until,attempts)SELECT account_ref,contact_id,conversation_id,source_id,'handoff_ack',expected_version,policy_version,knowledge_version,'SP3-T4 upgrade ack',provenance,state,lease,lease_until,attempts FROM intents WHERE id=(fixture->>'work')::uuid RETURNING jsonb_set(fixture,'{work}',to_jsonb(id::text))INTO fixture;END IF;
  UPDATE conversations SET owner='human'WHERE id=(fixture->>'conv')::uuid;
 END LOOP;
 fixture:=sp3t4_seed_followup('upgrade-followup','due');UPDATE conversations SET owner='human'WHERE id=(fixture->>'conv')::uuid;
END$$;
SELECT 'PASS SP3-T4 triggers, negatives, duplicate requests, pending work, retries, ack, follow-up states, account, optout, operator precedence, missing config and upgrade fixtures';

