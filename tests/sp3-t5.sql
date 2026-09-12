\set ON_ERROR_STOP on
SET search_path=salesflow,public;

CREATE FUNCTION sp3t5_handoff(label text,pbody text,mode text)RETURNS jsonb LANGUAGE plpgsql SET search_path=salesflow,public AS $$
DECLARE r jsonb;s jsonb;old_model jsonb;BEGIN
 r:=ingest('sp3t5-runtime',jsonb_build_object('account_ref','sp3t5','provider_id',label,'contact_ref',label,'body',pbody));
 ASSERT (r->>'accepted')::bool,'seed ingest: '||r;
 IF mode<>'explicit' THEN
  PERFORM set_consent('sp3t5-runtime','sp3t5',(r->>'contact_id')::uuid,'granted','synthetic acceptance');
  IF mode='uncertain' THEN
   SELECT body INTO old_model FROM config_docs WHERE account_ref='sp3t5'AND kind='model'AND active;
   PERFORM save_config('sp3t5-operator',old_model||'{"version":"model-sp3t5-uncertain","allowedClaims":["other"]}');
   PERFORM activate_config('sp3t5-operator','sp3t5','model','model-sp3t5-uncertain',old_model->>'version');
  END IF;
  s:=complete_turn('sp3t5-runtime','sp3t5',(r->>'conversation_id')::uuid);
  ASSERT s->>'terminal'='handoff','expected handoff: '||s;
  IF mode='uncertain' THEN PERFORM activate_config('sp3t5-operator','sp3t5','model',old_model->>'version','model-sp3t5-uncertain');END IF;
 END IF;
 RETURN jsonb_build_object('conversation_id',r->>'conversation_id','source_id',r->>'inbound_id','handoff_id',(SELECT id FROM handoffs WHERE account_ref='sp3t5'AND conversation_id=(r->>'conversation_id')::uuid));
END$$;

DO $$DECLARE f jsonb;s handoff_summaries;h jsonb;before_snapshot jsonb;c uuid;w uuid;claim uuid;r jsonb;BEGIN
 FOREACH f IN ARRAY ARRAY[
   sp3t5_handoff('summary-explicit','talk to a human','explicit'),
   sp3t5_handoff('summary-qualified','qualified','qualified'),
   sp3t5_handoff('summary-uncertain','uncertain','uncertain')
 ] LOOP
  SELECT*INTO s FROM handoff_summaries WHERE(account_ref,handoff_id)=('sp3t5',(f->>'handoff_id')::uuid);
  ASSERT s.handoff_id IS NOT NULL,'summary saved';
  ASSERT s.reason IN('human_requested','qualification_threshold','grounding_invalid'),'typed reason';
  ASSERT s.deadline IS NOT NULL AND s.urgency='respond_by_deadline','deadline urgency';
  ASSERT jsonb_array_length(s.known_lead_details)=1,'one concise supported detail';
  ASSERT s.known_lead_details->0->>'messageId'=f->>'source_id','actual message reference';
  ASSERT (s.known_lead_details->0->>'sequence')::bigint>0,'actual sequence reference';
  ASSERT octet_length(s.known_lead_details->0->>'excerpt')<=512,'bounded excerpt';
  ASSERT s.remaining_unknowns='["structured_lead_profile"]'::jsonb,'unknowns explicit';
  ASSERT s.relevant_offer='none','no offer without durable message-to-offer evidence';
  ASSERT s.sales_policy_version='policy-v1','active policy snapshot';
  ASSERT s.conversation_url='/webhook/salesflow/handoff?view=conversation&conversation_id='||s.conversation_id,'credential-free stable URL';
 END LOOP;

 SELECT conversation_id INTO c FROM handoff_summaries WHERE account_ref='sp3t5'AND reason='human_requested';
 h:=read_conversation_history('sp3t5-operator','sp3t5',c);
 ASSERT (h->>'ok')::bool AND h->>'conversation_id'=c::text AND jsonb_array_length(h->'messages')=1,'same-account ordered history';
 ASSERT h#>>'{messages,0,body}'='talk to a human','persisted body returned';
 ASSERT NOT(h::text LIKE'%sp3t5-operator%'),'operator token not echoed';
 ASSERT read_conversation_history('bad','sp3t5',c)->>'reason'='unauthorized','missing token denied';
 ASSERT read_conversation_history('sp3t5-other-operator','sp3t5',c)->>'reason'='unauthorized','cross-account token denied';
 ASSERT read_conversation_history('sp3t5-operator','other',c)->>'reason'='unauthorized','cross-account request denied';
 ASSERT read_conversation_history('sp3t5-operator','sp3t5',gen_random_uuid())->>'reason'='not_found','missing conversation denied';
 ASSERT read_conversation_history_request('sp3t5-operator','bad')->>'reason'='invalid_input','malformed history identifier denied';

 SELECT handoff_id,to_jsonb(x)INTO w,before_snapshot FROM handoff_summaries x WHERE account_ref='sp3t5'AND reason='human_requested';
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;ASSERT (r->>'ok')::bool,'notification claim';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'retryable');ASSERT r->>'terminal'='pending','retryable notification';
 ASSERT EXISTS(SELECT 1 FROM handoff_notification_events WHERE account_ref='sp3t5'AND handoff_id=w AND attempt_no=1 AND outcome='retryable'AND result='retry_scheduled'),'retry evidence';
 ASSERT before_snapshot=(SELECT to_jsonb(x)FROM handoff_summaries x WHERE(account_ref,handoff_id)=('sp3t5',w)),'summary immutable across retry';
 ASSERT EXISTS(SELECT 1 FROM conversations WHERE(account_ref,id)=('sp3t5',c)AND owner='human'),'human ownership retained';
 ASSERT NOT EXISTS(SELECT 1 FROM intents WHERE account_ref='sp3t5'AND conversation_id=c AND state IN('pending','leased','retry')),'automation remains stopped';
 UPDATE handoffs SET next_attempt=clock_timestamp()-interval'1 second'WHERE(account_ref,id)=('sp3t5',w);
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'failed');ASSERT r->>'terminal'='suppressed','final notification failure';
 ASSERT EXISTS(SELECT 1 FROM handoff_notification_events WHERE account_ref='sp3t5'AND handoff_id=w AND attempt_no=2 AND outcome='failed'AND result='final_failure'),'final failure evidence';
 ASSERT EXISTS(SELECT 1 FROM handoffs WHERE(account_ref,id)=('sp3t5',w)AND next_attempt IS NULL)AND EXISTS(SELECT 1 FROM handoff_notification_events WHERE account_ref='sp3t5'AND handoff_id=w AND attempt_no=2 AND next_attempt IS NULL),'final failure clears retry schedule';
END$$;
DO $$DECLARE w uuid;c uuid;contact uuid;claim uuid;r jsonb;attempt int;original jsonb;BEGIN
 SELECT handoff_id,conversation_id,to_jsonb(s)INTO w,c,original FROM handoff_summaries s WHERE account_ref='sp3t5'AND reason='qualification_threshold';
 BEGIN UPDATE handoff_summaries SET relevant_offer='invented'WHERE(account_ref,handoff_id)=('sp3t5',w);ASSERT false,'ordinary summary update must fail';EXCEPTION WHEN OTHERS THEN ASSERT SQLERRM='handoff summary immutable','immutable failure';END;
 PERFORM save_handoff_summary('sp3t5',w,'policy-invented','invented');
 ASSERT original=(SELECT to_jsonb(s)FROM handoff_summaries s WHERE(account_ref,handoff_id)=('sp3t5',w)),'replay cannot rewrite summary';
 FOR attempt IN 1..3 LOOP
  UPDATE handoffs SET next_attempt=clock_timestamp()-interval'1 second'WHERE(account_ref,id)=('sp3t5',w);
  r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;ASSERT (r->>'ok')::bool,'exhaustion claim '||attempt;
  r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'retryable');
 END LOOP;
 ASSERT r->>'notificationResult'='retry_exhausted'AND r->>'terminal'='suppressed','retry exhaustion terminal';
 ASSERT EXISTS(SELECT 1 FROM handoff_notification_events WHERE account_ref='sp3t5'AND handoff_id=w AND attempt_no=3 AND outcome='retryable'AND result='retry_exhausted'),'exhaustion evidence';
 ASSERT EXISTS(SELECT 1 FROM handoffs WHERE(account_ref,id)=('sp3t5',w)AND next_attempt IS NULL)AND EXISTS(SELECT 1 FROM handoff_notification_events WHERE account_ref='sp3t5'AND handoff_id=w AND attempt_no=3 AND next_attempt IS NULL),'exhaustion clears retry schedule';
 ASSERT original=(SELECT to_jsonb(s)FROM handoff_summaries s WHERE(account_ref,handoff_id)=('sp3t5',w)),'exhaustion leaves summary unchanged';
 ASSERT EXISTS(SELECT 1 FROM conversations WHERE(account_ref,id)=('sp3t5',c)AND owner='human'),'exhaustion leaves human ownership';

 SELECT handoff_id,conversation_id INTO w,c FROM handoff_summaries WHERE account_ref='sp3t5'AND reason='grounding_invalid';
 SELECT contact_id INTO contact FROM conversations WHERE(account_ref,id)=('sp3t5',c);
 r:=operations('sp3t5-operator','sp3t5',jsonb_build_object('action','delete','contact_id',contact));ASSERT r->>'terminal'='deleted','privacy deletion';
 ASSERT read_conversation_history('sp3t5-operator','sp3t5',c)->>'reason'='not_found','deleted history fails closed';
 ASSERT NOT EXISTS(SELECT 1 FROM handoff_summaries s,jsonb_array_elements(s.known_lead_details)x WHERE(s.account_ref,s.handoff_id)=('sp3t5',w)AND x->>'excerpt'<>'[deleted]'),'summary excerpt minimized by deletion';
END$$;

DO $$DECLARE old_policy jsonb;old_release jsonb;f jsonb;s handoff_summaries;BEGIN
 SELECT body INTO old_policy FROM config_docs WHERE account_ref='sp3t5'AND kind='sales_policy'AND active;
 SELECT body INTO old_release FROM config_docs WHERE account_ref='sp3t5'AND kind='release_set'AND active;
 PERFORM save_config('sp3t5-operator',old_policy||'{"version":"policy-sp3t5-multi","allowedOffers":["offer-1","offer-2"]}');
 PERFORM save_config('sp3t5-operator',old_release||'{"version":"release-sp3t5-multi","policyVersion":"policy-sp3t5-multi"}');
 PERFORM activate_config('sp3t5-operator','sp3t5','sales_policy','policy-sp3t5-multi',old_policy->>'version');
 PERFORM activate_config('sp3t5-operator','sp3t5','release_set','release-sp3t5-multi',old_release->>'version');
 f:=sp3t5_handoff('summary-multi-offer','qualified','qualified');SELECT*INTO s FROM handoff_summaries WHERE(account_ref,handoff_id)=('sp3t5',(f->>'handoff_id')::uuid);
 ASSERT s.relevant_offer='none','multi-offer policy must not invent relevance';
 PERFORM activate_config('sp3t5-operator','sp3t5','release_set',old_release->>'version','release-sp3t5-multi');
 PERFORM activate_config('sp3t5-operator','sp3t5','sales_policy',old_policy->>'version','policy-sp3t5-multi');
END$$;

DO $$DECLARE r jsonb;w uuid;c uuid;BEGIN
 r:=ingest('sp3t5-runtime',jsonb_build_object('account_ref','sp3t5','provider_id','summary-retention','contact_ref','summary-retention','body','talk to a human','received_at',clock_timestamp()-interval'31 days'));
 c:=(r->>'conversation_id')::uuid;SELECT handoff_id INTO w FROM handoff_summaries WHERE(account_ref,conversation_id)=('sp3t5',c);
 r:=operations('sp3t5-operator','sp3t5',jsonb_build_object('action','retention','at',clock_timestamp()));ASSERT r->>'terminal'='retention_enforced','retention command';
 ASSERT EXISTS(SELECT 1 FROM inbound_messages WHERE account_ref='sp3t5'AND provider_id='summary-retention'AND body='[deleted]'),'retention minimizes inbound';
 ASSERT NOT EXISTS(SELECT 1 FROM handoff_summaries s,jsonb_array_elements(s.known_lead_details)x WHERE(s.account_ref,s.handoff_id)=('sp3t5',w)AND x->>'excerpt'<>'[deleted]'),'retention minimizes copied summary excerpt';
END$$;

DO $$DECLARE r jsonb;c uuid;w uuid;BEGIN
 INSERT INTO accounts VALUES('sp3t5/a?b&c',true);INSERT INTO controls VALUES('sp3t5/a?b&c','stop','{"enabled":false}');PERFORM bootstrap('sp3t5-reserved-runtime','runtime','sp3t5/a?b&c','sp3t5/a?b&c');PERFORM bootstrap('sp3t5-reserved-operator','operator','sp3t5/a?b&c','sp3t5/a?b&c');
 INSERT INTO config_docs(account_ref,kind,version,body,active,created_at)SELECT'sp3t5/a?b&c',kind,version,jsonb_set(body,'{accountRef}','"sp3t5/a?b&c"'),active,created_at FROM config_docs WHERE account_ref='sp3t5'AND active;
 r:=ingest('sp3t5-reserved-runtime','{"account_ref":"sp3t5/a?b&c","provider_id":"reserved-link","contact_ref":"reserved-link","body":"talk to a human"}');c:=(r->>'conversation_id')::uuid;SELECT handoff_id INTO w FROM handoff_summaries WHERE(account_ref,conversation_id)=('sp3t5/a?b&c',c);
 ASSERT (SELECT conversation_url='/webhook/salesflow/handoff?view=conversation&conversation_id='||c FROM handoff_summaries WHERE(account_ref,handoff_id)=('sp3t5/a?b&c',w)),'reserved account is absent from URL';
 ASSERT read_conversation_history_request('sp3t5-reserved-operator',c::text)#>>'{messages,0,body}'='talk to a human','reserved-account token resolves its Conversation';
 ASSERT read_conversation_history_request('sp3t5-operator',c::text)->>'reason'='not_found','other-account operator cannot resolve reserved Conversation';
END$$;

DO $$DECLARE f jsonb;w uuid;c uuid;claim uuid;r jsonb;label text;adapter_outcome text;BEGIN
 FOR label,adapter_outcome IN SELECT*FROM(VALUES('authority-account','success'),('authority-lifecycle','retryable'),('authority-config','failed'))x(label,adapter_outcome) LOOP
  f:=sp3t5_handoff(label,'talk to a human','explicit');w:=(f->>'handoff_id')::uuid;c:=(f->>'conversation_id')::uuid;
  r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;ASSERT (r->>'ok')::bool,'authority fixture claim';r:=recheck_handoff('sp3t5-runtime','sp3t5',w,claim);ASSERT (r->>'ok')::bool,'authority fixture recheck';
  IF label='authority-account'THEN UPDATE accounts SET enabled=false WHERE id='sp3t5';
  ELSIF label='authority-lifecycle'THEN UPDATE conversations SET lifecycle='opted_out'WHERE(account_ref,id)=('sp3t5',c);
  ELSE PERFORM set_config('salesflow.config_activation','on',true);UPDATE config_docs SET active=false WHERE account_ref='sp3t5'AND kind='handoff'AND active;PERFORM set_config('salesflow.config_activation','off',true);END IF;
  r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,adapter_outcome);ASSERT r->>'terminal'='suppressed','post-recheck authority change suppresses';
  ASSERT EXISTS(SELECT 1 FROM handoff_notification_events WHERE account_ref='sp3t5'AND handoff_id=w AND attempt_no=1 AND handoff_notification_events.outcome=adapter_outcome AND result='authority_changed'AND next_attempt IS NULL),'actual adapter outcome retained after authority change';
  ASSERT EXISTS(SELECT 1 FROM conversations WHERE(account_ref,id)=('sp3t5',c)AND owner='human'),'authority change preserves human ownership';
  IF label='authority-account'THEN UPDATE accounts SET enabled=true WHERE id='sp3t5';ELSIF label='authority-lifecycle'THEN UPDATE conversations SET lifecycle='active'WHERE(account_ref,id)=('sp3t5',c);ELSE PERFORM set_config('salesflow.config_activation','on',true);UPDATE config_docs SET active=true WHERE account_ref='sp3t5'AND kind='handoff'AND version='handoff-v1';PERFORM set_config('salesflow.config_activation','off',true);END IF;
 END LOOP;
END$$;

DO $$DECLARE f jsonb;w uuid;claim uuid;r jsonb;old_handoff jsonb;BEGIN
 f:=sp3t5_handoff('contracted-retry','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'retryable');ASSERT r->>'terminal'='pending','retry scheduled before contraction';
 SELECT body INTO old_handoff FROM config_docs WHERE account_ref='sp3t5'AND kind='handoff'AND active;PERFORM save_config('sp3t5-operator',old_handoff||'{"version":"handoff-sp3t5-contracted","maxAttempts":1}');PERFORM activate_config('sp3t5-operator','sp3t5','handoff','handoff-sp3t5-contracted',old_handoff->>'version');
 UPDATE handoffs SET next_attempt=clock_timestamp()-interval'1 second'WHERE(account_ref,id)=('sp3t5',w);r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());ASSERT r->>'reason'='retry_exhausted','contracted max attempts denies before adapter';
 ASSERT EXISTS(SELECT 1 FROM handoff_notification_events WHERE account_ref='sp3t5'AND handoff_id=w AND attempt_no=2 AND outcome IS NULL AND result='retry_exhausted'AND next_attempt IS NULL),'contraction exhaustion evidence has no fabricated adapter outcome';
 ASSERT (SELECT count(*)=2 FROM handoff_notification_events WHERE account_ref='sp3t5'AND handoff_id=w),'one adapter event plus one authority exhaustion event';
 ASSERT EXISTS(SELECT 1 FROM handoffs WHERE(account_ref,id)=('sp3t5',w)AND state='suppressed'AND next_attempt IS NULL),'contraction clears stale schedule';
 PERFORM activate_config('sp3t5-operator','sp3t5','handoff',old_handoff->>'version','handoff-sp3t5-contracted');
END$$;

DO $$DECLARE f jsonb;w uuid;c uuid;claim uuid;r jsonb;BEGIN
 f:=sp3t5_handoff('retry-optout-ingest','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;c:=(f->>'conversation_id')::uuid;
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;ASSERT (r->>'ok')::bool,'retry opt-out fixture claim';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'retryable');ASSERT r->>'terminal'='pending'AND r->>'next_attempt'IS NOT NULL,'retry opt-out fixture scheduled';
 r:=ingest('sp3t5-runtime','{"account_ref":"sp3t5","provider_id":"retry-optout-ingest-stop","contact_ref":"retry-optout-ingest","body":"stop"}');ASSERT (r->>'accepted')::bool,'retry opt-out ingest accepted';
 ASSERT EXISTS(SELECT 1 FROM handoffs h WHERE(h.account_ref,h.id)=('sp3t5',w)AND h.state='suppressed'AND h.claim IS NULL AND h.claim_until IS NULL AND h.next_attempt IS NULL),'retry to opt-out ingest clears all notification scheduling state';
 ASSERT EXISTS(SELECT 1 FROM conversations WHERE(account_ref,id)=('sp3t5',c)AND lifecycle='opted_out'AND owner='human'),'retry opt-out retains terminal lifecycle and human ownership';
END$$;

DO $$DECLARE f jsonb;w uuid;c uuid;contact uuid;claim uuid;r jsonb;BEGIN
 f:=sp3t5_handoff('retry-privacy-delete','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;c:=(f->>'conversation_id')::uuid;
 SELECT contact_id INTO contact FROM conversations WHERE(account_ref,id)=('sp3t5',c);
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;ASSERT (r->>'ok')::bool,'retry deletion fixture claim';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'retryable');ASSERT r->>'terminal'='pending'AND r->>'next_attempt'IS NOT NULL,'retry deletion fixture scheduled';
 r:=operations('sp3t5-operator','sp3t5',jsonb_build_object('action','delete','contact_id',contact));ASSERT r->>'terminal'='deleted','retry privacy deletion completed';
 ASSERT EXISTS(SELECT 1 FROM handoffs h WHERE(h.account_ref,h.id)=('sp3t5',w)AND h.state='suppressed'AND h.claim IS NULL AND h.claim_until IS NULL AND h.next_attempt IS NULL),'retry to privacy deletion clears all notification scheduling state';
 ASSERT EXISTS(SELECT 1 FROM conversations WHERE(account_ref,id)=('sp3t5',c)AND lifecycle='deleted'AND owner='human'),'retry deletion retains terminal lifecycle and human ownership';
END$$;

DO $$DECLARE f jsonb;w uuid;claim uuid;r jsonb;active_handoff text;BEGIN
 f:=sp3t5_handoff('retried-authority-recheck','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;ASSERT (r->>'ok')::bool,'retried recheck fixture first claim';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'retryable');ASSERT r->>'terminal'='pending'AND r->>'next_attempt'IS NOT NULL,'retried recheck fixture scheduled';
 UPDATE handoffs SET next_attempt=clock_timestamp()-interval'1 second'WHERE(account_ref,id)=('sp3t5',w);
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;ASSERT (r->>'ok')::bool,'retried recheck fixture second claim';
 SELECT version INTO active_handoff FROM config_docs WHERE account_ref='sp3t5'AND kind='handoff'AND active;
 PERFORM set_config('salesflow.config_activation','on',true);UPDATE config_docs SET active=false WHERE account_ref='sp3t5'AND kind='handoff'AND active;PERFORM set_config('salesflow.config_activation','off',true);
 r:=recheck_handoff('sp3t5-runtime','sp3t5',w,claim);ASSERT r->>'reason'='missing_config','retried claim detects changed authority at recheck';
 ASSERT EXISTS(SELECT 1 FROM handoffs h WHERE(h.account_ref,h.id)=('sp3t5',w)AND h.state='suppressed'AND h.claim IS NULL AND h.claim_until IS NULL AND h.next_attempt IS NULL),'retried authority recheck clears all notification scheduling state';
 PERFORM set_config('salesflow.config_activation','on',true);UPDATE config_docs SET active=true WHERE account_ref='sp3t5'AND kind='handoff'AND version=active_handoff;PERFORM set_config('salesflow.config_activation','off',true);
END$$;

DO $$DECLARE f jsonb;w uuid;r jsonb;BEGIN
 PERFORM bootstrap('sp3t5-other-runtime','runtime','sp3t5-other-runtime','other');PERFORM bootstrap('sp3t5-other-scheduler','scheduler','sp3t5-other-scheduler','other');
 f:=sp3t5_handoff('cross-account-handoff-claim','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;
 r:=claim_handoff('sp3t5-other-runtime','sp3t5',w,clock_timestamp());
 ASSERT r->>'reason'='wrong_account'AND NOT(r ?| ARRAY['account_ref','work_id','claim','queue','deadline','summary']),'scoped runtime cross-account claim denied without summary or lease disclosure';
 ASSERT EXISTS(SELECT 1 FROM handoffs WHERE(account_ref,id)=('sp3t5',w)AND state='pending'AND attempts=0 AND claim IS NULL AND claim_until IS NULL),'runtime denial leaves target handoff unclaimed';
 r:=claim_handoff('sp3t5-other-scheduler','sp3t5',w,clock_timestamp());
 ASSERT r->>'reason'='wrong_account'AND NOT(r ?| ARRAY['account_ref','work_id','claim','queue','deadline','summary']),'scoped scheduler cross-account claim denied without summary or lease disclosure';
 ASSERT EXISTS(SELECT 1 FROM handoffs WHERE(account_ref,id)=('sp3t5',w)AND state='pending'AND attempts=0 AND claim IS NULL AND claim_until IS NULL),'scheduler denial leaves target handoff unclaimed';
END$$;

DO $$DECLARE f jsonb;w uuid;claim uuid;r jsonb;BEGIN
 f:=sp3t5_handoff('disabled-before-recheck','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;ASSERT (r->>'ok')::bool,'disabled recheck fixture claim';
 UPDATE handoffs SET next_attempt=clock_timestamp()+interval'1 hour'WHERE(account_ref,id)=('sp3t5',w);UPDATE accounts SET enabled=false WHERE id='sp3t5';
 r:=recheck_handoff('sp3t5-runtime','sp3t5',w,claim);ASSERT r->>'reason'='account_disabled','immediate recheck reports disabled account';
 ASSERT EXISTS(SELECT 1 FROM handoffs h WHERE(h.account_ref,h.id)=('sp3t5',w)AND h.state='suppressed'AND h.claim IS NULL AND h.claim_until IS NULL AND h.next_attempt IS NULL),'disabled account recheck suppresses and clears claim plus retry schedule';
 UPDATE accounts SET enabled=true WHERE id='sp3t5';
END$$;

DO $$DECLARE f jsonb;w uuid;claim uuid;r jsonb;attempt_count int;BEGIN
 f:=sp3t5_handoff('expired-claim-adapter-result','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;ASSERT (r->>'ok')::bool,'expired adapter-result fixture claim';
 r:=recheck_handoff('sp3t5-runtime','sp3t5',w,claim);ASSERT (r->>'ok')::bool,'expired adapter-result attempt durably starts before adapter';
 UPDATE handoffs SET claim_until=clock_timestamp()-interval'1 second'WHERE(account_ref,id)=('sp3t5',w);SELECT attempts INTO attempt_count FROM handoffs WHERE(account_ref,id)=('sp3t5',w);
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());
 ASSERT NOT COALESCE((r->>'ok')::bool,false)AND r->>'reason'='reconciliation_required'AND NOT(r ?| ARRAY['claim','summary']),'expired started attempt cannot be blindly reclaimed';
 ASSERT (SELECT attempts=attempt_count FROM handoffs WHERE(account_ref,id)=('sp3t5',w)),'reconciliation transition does not consume another attempt';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'success');
 ASSERT (r->>'ok')::bool AND r->>'terminal'='acknowledged'AND r->>'notificationResult'='delivered','exact late adapter result completes its reconcilable attempt';
 ASSERT EXISTS(SELECT 1 FROM handoff_notification_events WHERE account_ref='sp3t5'AND handoff_id=w AND attempt_no=attempt_count AND outcome='success'AND result='delivered'AND next_attempt IS NULL),'exact late adapter result is durable';
 ASSERT EXISTS(SELECT 1 FROM handoffs h WHERE(h.account_ref,h.id)=('sp3t5',w)AND h.state='acknowledged'AND h.claim IS NULL AND h.claim_until IS NULL AND h.next_attempt IS NULL),'late result terminalizes without stale scheduling state';
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());
 ASSERT NOT COALESCE((r->>'ok')::bool,false)AND r->>'reason'='terminal_state'AND NOT(r ?| ARRAY['claim','summary']),'completed late result cannot be blindly reclaimed';
 ASSERT (SELECT attempts=attempt_count FROM handoffs WHERE(account_ref,id)=('sp3t5',w)),'denied reconciliation claim does not consume another attempt';
END$$;

DO $$DECLARE f jsonb;w uuid;claim_id uuid;r jsonb;BEGIN
 f:=sp3t5_handoff('duplicate-recheck','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim_id:=(r->>'claim')::uuid;
 r:=recheck_handoff('sp3t5-runtime','sp3t5',w,claim_id);ASSERT (r->>'ok')::bool,'first recheck exposes one adapter attempt';
 r:=recheck_handoff('sp3t5-runtime','sp3t5',w,claim_id);ASSERT NOT COALESCE((r->>'ok')::bool,false)AND r->>'reason'='adapter_already_started','duplicate recheck cannot expose adapter twice';
 ASSERT (SELECT count(*)=1 FROM handoff_notification_attempts a WHERE(a.account_ref,a.handoff_id,a.claim)=('sp3t5',w,claim_id)),'duplicate recheck retains one start marker';
END$$;

DO $$DECLARE f jsonb;w uuid;r jsonb;BEGIN
 f:=sp3t5_handoff('unscoped-runtime-claim','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;
 r:=claim_handoff('sp3t5-unscoped-runtime','sp3t5',w,clock_timestamp());ASSERT r->>'reason'='wrong_account'AND NOT(r ?| ARRAY['account_ref','work_id','claim','summary']),'null-scoped runtime cannot claim arbitrary account';
 ASSERT EXISTS(SELECT 1 FROM handoffs WHERE(account_ref,id)=('sp3t5',w)AND state='pending'AND attempts=0),'null-scoped runtime denial does not mutate work';
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());
 ASSERT recheck_handoff('sp3t5-unscoped-runtime','sp3t5',w,(r->>'claim')::uuid)->>'reason'='wrong_account','null-scoped runtime cannot recheck';
 ASSERT finish_handoff('sp3t5-unscoped-runtime','sp3t5',w,(r->>'claim')::uuid,'success')->>'reason'='wrong_account','null-scoped runtime cannot finish';
 PERFORM bootstrap('sp3t5-global-scheduler','scheduler','global-scheduler',NULL);
 r:=recheck_handoff('sp3t5-global-scheduler','sp3t5',w,(r->>'claim')::uuid);ASSERT (r->>'ok')::bool,'global scheduler remains authorized for explicit account';
 r:=finish_handoff('sp3t5-global-scheduler','sp3t5',w,(r->>'claim')::uuid,'success');ASSERT r->>'terminal'='acknowledged','global scheduler can persist result';
END$$;

DO $$DECLARE f jsonb;w uuid;c uuid;claim uuid;r jsonb;BEGIN
 f:=sp3t5_handoff('inflight-real-optout','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;c:=(f->>'conversation_id')::uuid;
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;r:=recheck_handoff('sp3t5-runtime','sp3t5',w,claim);ASSERT (r->>'ok')::bool,'in-flight opt-out adapter started';
 r:=ingest('sp3t5-runtime','{"account_ref":"sp3t5","provider_id":"inflight-real-optout-stop","contact_ref":"inflight-real-optout","body":"stop"}');ASSERT (r->>'accepted')::bool,'real opt-out accepted while notification in flight';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'success');ASSERT (r->>'ok')::bool AND r->>'notificationResult'='authority_changed','real opt-out retains exact in-flight adapter outcome';
 ASSERT EXISTS(SELECT 1 FROM handoff_notification_events WHERE(account_ref,handoff_id,outcome,result)=('sp3t5',w,'success','authority_changed')),'real opt-out outcome durable';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'success');ASSERT (r->>'replayed')::bool,'opt-out result replay idempotent';
 ASSERT (SELECT count(*)=1 FROM handoff_notification_events WHERE(account_ref,handoff_id)=('sp3t5',w))AND EXISTS(SELECT 1 FROM handoffs WHERE(account_ref,id)=('sp3t5',w)AND state='suppressed'AND handoffs.claim IS NULL AND next_attempt IS NULL),'opt-out replay preserves suppressed state and one event';
END$$;

DO $$DECLARE f jsonb;w uuid;c uuid;contact uuid;claim uuid;r jsonb;BEGIN
 f:=sp3t5_handoff('inflight-real-delete','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;c:=(f->>'conversation_id')::uuid;SELECT contact_id INTO contact FROM conversations WHERE(account_ref,id)=('sp3t5',c);
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim:=(r->>'claim')::uuid;r:=recheck_handoff('sp3t5-runtime','sp3t5',w,claim);ASSERT (r->>'ok')::bool,'in-flight deletion adapter started';
 r:=operations('sp3t5-operator','sp3t5',jsonb_build_object('action','delete','contact_id',contact));ASSERT r->>'terminal'='deleted','real deletion accepted while notification in flight';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'failed');ASSERT (r->>'ok')::bool AND r->>'notificationResult'='authority_changed','real deletion retains exact in-flight adapter outcome';
 ASSERT EXISTS(SELECT 1 FROM handoff_notification_events WHERE(account_ref,handoff_id,outcome,result)=('sp3t5',w,'failed','authority_changed')),'real deletion outcome durable';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim,'failed');ASSERT (r->>'replayed')::bool,'deletion result replay idempotent';
 ASSERT (SELECT count(*)=1 FROM handoff_notification_events WHERE(account_ref,handoff_id)=('sp3t5',w))AND EXISTS(SELECT 1 FROM handoffs WHERE(account_ref,id)=('sp3t5',w)AND state='suppressed'AND handoffs.claim IS NULL AND next_attempt IS NULL),'deletion replay preserves suppressed state and one event';
END$$;

DO $$DECLARE f jsonb;c uuid;contact uuid;source uuid;h jsonb;BEGIN
 f:=sp3t5_handoff('history-with-outbound','talk to a human','explicit');c:=(f->>'conversation_id')::uuid;source:=(f->>'source_id')::uuid;SELECT contact_id INTO contact FROM conversations WHERE(account_ref,id)=('sp3t5',c);
 INSERT INTO intents(account_ref,contact_id,conversation_id,source_id,kind,expected_version,policy_version,knowledge_version,body,provenance,state,provider_status,provider_time)VALUES('sp3t5',contact,c,source,'reply',1,'policy-v1','knowledge-v1','synthetic outbound answer','{}','sent','accepted',clock_timestamp());
 h:=read_conversation_history('sp3t5-operator','sp3t5',c);
 ASSERT jsonb_array_length(h->'messages')=2,'full history includes inbound and persisted outbound';
 ASSERT h#>>'{messages,0,direction}'='inbound'AND h#>>'{messages,1,direction}'='outbound'AND h#>>'{messages,1,body}'='synthetic outbound answer','full history orders outbound after its source inbound';
 UPDATE intents SET state='pending' WHERE account_ref='sp3t5'AND conversation_id=c;
 h:=read_conversation_history('sp3t5-operator','sp3t5',c);ASSERT jsonb_array_length(h->'messages')=1 AND h::text NOT LIKE '%synthetic outbound answer%','history excludes unsent draft';
 UPDATE intents SET state='sent' WHERE account_ref='sp3t5'AND conversation_id=c;
 h:=read_conversation_history('sp3t5-other-operator','sp3t5',c);ASSERT NOT COALESCE((h->>'ok')::bool,false)AND NOT(h ? 'messages'),'outbound history retains account isolation';
END$$;
DO $$DECLARE f jsonb;w uuid;claim_id uuid;r jsonb;BEGIN
 f:=sp3t5_handoff('restored-authority','talk to a human','explicit');w:=(f->>'handoff_id')::uuid;
 r:=claim_handoff('sp3t5-runtime','sp3t5',w,clock_timestamp());claim_id:=(r->>'claim')::uuid;
 r:=recheck_handoff('sp3t5-runtime','sp3t5',w,claim_id);ASSERT (r->>'ok')::bool,'restored authority starts adapter';
 r:=set_account_enabled('sp3t5-operator','sp3t5',false);
 r:=recheck_handoff('sp3t5-runtime','sp3t5',w,claim_id);ASSERT r->>'reason'='account_disabled','disabled recheck suppresses';
 r:=set_account_enabled('sp3t5-operator','sp3t5',true);
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim_id,'retryable');ASSERT (r->>'ok')::bool AND r->>'notificationResult'='authority_changed'AND r->>'terminal'='suppressed','restored authority preserves exact result without retry';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim_id,'retryable');ASSERT (r->>'replayed')::bool,'restored authority result replay';
 r:=finish_handoff('sp3t5-runtime','sp3t5',w,claim_id,'success');ASSERT r->>'reason'='outcome_conflict','restored authority conflicting result denied';
 ASSERT (SELECT count(*)=1 AND bool_and(failure_reason='account_disabled')FROM handoff_notification_events WHERE(account_ref,handoff_id)=('sp3t5',w))AND EXISTS(SELECT 1 FROM handoffs WHERE(account_ref,id)=('sp3t5',w)AND state='suppressed'AND suppression_reason='account_disabled'AND claim IS NULL AND next_attempt IS NULL),'restored authority retains its suppression reason exactly once';
END$$;
DO $$DECLARE r jsonb;c uuid;ct uuid;src uuid;reply_id uuid;job_id uuid;h jsonb;BEGIN
 r:=ingest('sp3t5-runtime','{"account_ref":"sp3t5","provider_id":"full-followup-start","contact_ref":"full-followup","body":"hello"}');c:=(r->>'conversation_id')::uuid;ct:=(r->>'contact_id')::uuid;src:=(r->>'inbound_id')::uuid;
 INSERT INTO intents(account_ref,contact_id,conversation_id,source_id,kind,expected_version,policy_version,knowledge_version,body,provenance,state,provider_time)VALUES('sp3t5',ct,c,src,'reply',1,'policy-v1','knowledge-v1','sent reply','{}','sent',clock_timestamp())RETURNING id INTO reply_id;
 INSERT INTO followups(account_ref,contact_id,conversation_id,due_at,expected_version,source_intent_id,state)VALUES('sp3t5',ct,c,clock_timestamp(),1,reply_id,'sent')RETURNING id INTO job_id;
 INSERT INTO intents(account_ref,contact_id,conversation_id,source_id,kind,expected_version,policy_version,knowledge_version,body,provenance,state,provider_time)VALUES('sp3t5',ct,c,job_id,'followup',1,'policy-v1','knowledge-v1','sent followup','{}','sent',clock_timestamp());
 r:=ingest('sp3t5-runtime','{"account_ref":"sp3t5","provider_id":"full-followup-human","contact_ref":"full-followup","body":"talk to a human"}');
 h:=read_conversation_history('sp3t5-operator','sp3t5',c);ASSERT jsonb_array_length(h->'messages')=4 AND h#>>'{messages,2,body}'='sent followup'AND h#>>'{messages,3,direction}'='inbound','full history retains sent followup before human request';
 INSERT INTO followups(account_ref,contact_id,conversation_id,due_at,expected_version,state)VALUES('sp3t5',ct,c,clock_timestamp(),1,'sent')RETURNING id INTO job_id;
 INSERT INTO intents(account_ref,contact_id,conversation_id,source_id,kind,expected_version,policy_version,knowledge_version,body,provenance,state)VALUES('sp3t5',ct,c,job_id,'followup',1,'policy-v1','knowledge-v1','legacy sent followup','{}','sent');
 h:=read_conversation_history('sp3t5-operator','sp3t5',c);ASSERT jsonb_array_length(h->'messages')=5 AND h#>>'{messages,4,body}'='legacy sent followup'AND h#>>'{messages,4,sequence}'='unknown'AND h#>>'{messages,4,receivedAt}'='unknown','missing followup source retains sent message with unknown metadata';
 h:=read_conversation_history('sp3t5-other-operator','sp3t5',c);ASSERT NOT(h ? 'messages'),'followup history account isolation';
END$$;
SELECT 'PASS SP3-T5 summaries, history authorization, notification recovery and lockout';
