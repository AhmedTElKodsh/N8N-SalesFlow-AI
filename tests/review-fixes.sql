\set ON_ERROR_STOP on
SET search_path=salesflow,public;
BEGIN;
-- Synthetic, owner-run regression fixtures. All data and credentials roll back.
INSERT INTO accounts(id)VALUES('review-a'),('review-b');
INSERT INTO auth_tokens(hash,role,account_ref,actor)VALUES
(encode(digest('review-runtime','sha256'),'hex'),'runtime','review-a','review'),
(encode(digest('review-operator','sha256'),'hex'),'operator','review-a','review'),
(encode(digest('review-scoped','sha256'),'hex'),'scheduler','review-a','review'),
(encode(digest('review-global','sha256'),'hex'),'scheduler',NULL,'review');
INSERT INTO config_docs(account_ref,kind,version,body,active)
SELECT 'review-a',kind,version,jsonb_set(body,'{accountRef}','"review-a"'),active FROM config_docs WHERE account_ref='test-account' AND active;
INSERT INTO controls VALUES('review-a','stop','{"enabled":false}');
DO $$DECLARE p jsonb;r jsonb;v uuid;c uuid;h uuid;cl uuid;other_c uuid;other_v uuid;m uuid;i uuid;f uuid;before_state jsonb;BEGIN
 ASSERT EXISTS(SELECT 1 FROM config_docs WHERE account_ref='review-a'AND kind='consent_templates'AND active),'review fixtures require bootstrapped test-account configs';
 p:=jsonb_build_object('account_ref','review-a','provider_id','review-retain','contact_ref','review-retain','body','original','received_at',clock_timestamp()-interval'5000 days');
 r:=ingest('review-runtime',p);ASSERT(r->>'created')::bool,'replay fixture ingest';
 PERFORM enforce_retention('review-operator','review-a',clock_timestamp());
 r:=ingest('review-runtime',p);ASSERT r->>'terminal'='duplicate','retained original must remain duplicate';
 r:=ingest('review-runtime',p||'{"body":"changed"}');ASSERT r->>'reason'='idempotency_conflict','retained changed body must conflict';
 r:=ingest('review-runtime',p||'{"contact_ref":"changed"}');ASSERT r->>'reason'='idempotency_conflict','retained changed sender must conflict';
 ALTER TABLE inbound_replay_identities DISABLE TRIGGER inbound_replay_immutable;
 DELETE FROM inbound_replay_identities WHERE account_ref='review-a'AND inbound_id=(SELECT id FROM inbound_messages WHERE account_ref='review-a'AND provider_id='review-retain');
 ALTER TABLE inbound_replay_identities ENABLE TRIGGER inbound_replay_immutable;
 r:=ingest('review-runtime',p);ASSERT r->>'reason'='replay_identity_unavailable','already minimized legacy replay must not be misclassified';
 p:=p||'{"provider_id":"review-delete","contact_ref":"review-delete","received_at":"2020-01-01"}';
 r:=ingest('review-runtime',p);c:=(r->>'contact_id')::uuid;ASSERT c IS NOT NULL,'deletion fixture ingest';
 PERFORM operations('review-operator','review-a',jsonb_build_object('action','delete','contact_id',c));
 r:=ingest('review-runtime',p);ASSERT r->>'terminal'='duplicate','deleted original must remain duplicate';
 r:=ingest('review-runtime',p||'{"body":"changed"}');ASSERT r->>'reason'='idempotency_conflict','deleted changed body must conflict';
 r:=ingest('review-runtime',p||'{"contact_ref":"changed"}');ASSERT r->>'reason'='idempotency_conflict','deleted changed sender must conflict';
 r:=ingest('review-runtime','{"account_ref":"review-a","provider_id":"review-handoff","contact_ref":"review-handoff","body":"human"}');v:=(r->>'conversation_id')::uuid;
 SELECT id INTO h FROM handoffs WHERE account_ref='review-a'AND conversation_id=v;ASSERT h IS NOT NULL,'handoff fixture';
 r:=claim_handoff('review-scoped','review-a',h);cl:=(r->>'claim')::uuid;ASSERT cl IS NOT NULL,'handoff claim';
 r:=recheck_handoff('review-scoped','review-a',h,cl);ASSERT(r->>'ok')::bool,'handoff start';
 UPDATE handoffs SET claim_until=clock_timestamp()-interval'1 sec'WHERE account_ref='review-a'AND id=h;
 r:=claim_handoff('review-scoped','review-a',h);ASSERT r->>'reason'='reconciliation_required','expired started handoff reconciles';
 ASSERT(SELECT state='reconciliation_required'AND claim=cl AND claim_until IS NULL FROM handoffs WHERE account_ref='review-a'AND id=h),'reconciliation persisted';
 PERFORM claim_handoff('review-scoped','review-a',h);
 ASSERT(SELECT count(*)=1 FROM operational_failures WHERE account_ref='review-a'AND work_id=h AND manual_action_required),'one operator-visible handoff failure';
 ASSERT NOT EXISTS(SELECT 1 FROM schedule_work('review-scoped')WHERE work_id=h),'handoff must leave automatic selection';
 ASSERT(SELECT owner='human'FROM conversations WHERE account_ref='review-a'AND id=v),'human ownership persists';
 r:=finish_handoff('review-scoped','review-a',h,gen_random_uuid(),'success');ASSERT r->>'reason'='claim_mismatch','foreign late claim cannot reconcile';
 r:=finish_handoff('review-scoped','review-a',h,cl,'success');ASSERT r->>'terminal'='acknowledged','exact late outcome remains reconcilable';
 ASSERT(SELECT count(*)=1 FROM handoff_notification_events WHERE account_ref='review-a'AND handoff_id=h AND outcome='success'),'late outcome is recorded once without a fabricated prior outcome';
 INSERT INTO contacts(account_ref)VALUES('review-b')RETURNING id INTO other_c;
 INSERT INTO conversations(account_ref,contact_id)VALUES('review-b',other_c)RETURNING id INTO other_v;
 INSERT INTO inbound_messages(account_ref,conversation_id,provider_id,contact_ref,body,processing_body,body_hash,received_at,seq)VALUES('review-b',other_v,'review-other','other','hello','hello',encode(digest('hello','sha256'),'hex'),clock_timestamp(),1)RETURNING id INTO m;
 INSERT INTO turns(account_ref,inbound_id,conversation_id)VALUES('review-b',m,other_v);
 INSERT INTO intents(account_ref,contact_id,conversation_id,source_id,kind,expected_version,policy_version,knowledge_version,body,provenance,state,lease,lease_until)VALUES('review-b',other_c,other_v,m,'reply',1,'p','k','synthetic','{}','provider_call_started',gen_random_uuid(),clock_timestamp()-interval'1 sec')RETURNING id INTO i;
 INSERT INTO provider_calls(account_ref,intent_id,attempt_no,lease,provider_id,release_set_version)SELECT account_ref,id,1,lease,'review-other-call','r'FROM intents WHERE id=i;
 INSERT INTO followups(account_ref,contact_id,conversation_id,due_at,expected_version)VALUES('review-b',other_c,other_v,clock_timestamp()-interval'1 day',1)RETURNING id INTO f;
 SELECT to_jsonb(x)INTO before_state FROM intents x WHERE id=i;
 ASSERT claim_dispatch('review-scoped','review-b',i)->>'reason'='wrong_account','claim scope';
 ASSERT begin_provider_call('review-scoped','review-b',i,gen_random_uuid())->>'reason'='wrong_account','start scope';
 ASSERT recheck_dispatch('review-scoped','review-b',i,gen_random_uuid())->>'reason'='wrong_account','recheck scope';
 ASSERT finish_dispatch('review-scoped','review-b',i,gen_random_uuid(),'success')->>'reason'='wrong_account','finish scope';
 ASSERT complete_turn('review-scoped','review-b',other_v)->>'reason'='wrong_account','turn scope';
 ASSERT claim_handoff('review-scoped','review-b',gen_random_uuid())->>'reason'='wrong_account','handoff claim scope';
 ASSERT recheck_handoff('review-scoped','review-b',gen_random_uuid(),gen_random_uuid())->>'reason'='wrong_account','handoff recheck scope';
 ASSERT finish_handoff('review-scoped','review-b',gen_random_uuid(),gen_random_uuid(),'success')->>'reason'='wrong_account','handoff finish scope';
 ASSERT NOT EXISTS(SELECT 1 FROM schedule_followups('review-scoped')WHERE account_ref<>'review-a'),'followup discovery scope';
 ASSERT NOT EXISTS(SELECT 1 FROM schedule_work('review-scoped')WHERE account_ref<>'review-a'),'work discovery scope';
 ASSERT(SELECT to_jsonb(x)=before_state FROM intents x WHERE id=i),'cross-account reconciliation must not mutate';
 ASSERT(SELECT state='due'FROM followups WHERE id=f),'cross-account followup unchanged';
 PERFORM schedule_work('review-global');
 ASSERT(SELECT state='reconciliation_required'FROM intents WHERE id=i),'global scheduler retains reconciliation authority';
 -- Owner/backfill writes must obey the same aggregate relationships.
 SELECT contact_id INTO c FROM conversations WHERE account_ref='review-a'AND id=v;
 INSERT INTO contacts(account_ref)VALUES('review-a')RETURNING id INTO other_c;
 INSERT INTO conversations(account_ref,contact_id)VALUES('review-a',other_c)RETURNING id INTO other_v;
 SELECT source_id INTO m FROM handoffs WHERE id=h;
 BEGIN INSERT INTO turns(account_ref,inbound_id,conversation_id)VALUES('review-a',m,other_v)ON CONFLICT(account_ref,inbound_id)DO UPDATE SET conversation_id=excluded.conversation_id;RAISE EXCEPTION 'spliced turn accepted';EXCEPTION WHEN foreign_key_violation THEN NULL;END;
 BEGIN INSERT INTO handoffs(account_ref,contact_id,conversation_id,source_id,reason,queue,deadline,evidence)VALUES('review-a',other_c,other_v,m,'human_requested','q',clock_timestamp(),'{}');RAISE EXCEPTION 'spliced handoff accepted';EXCEPTION WHEN foreign_key_violation THEN NULL;END;
 BEGIN INSERT INTO followups(account_ref,contact_id,conversation_id,due_at,expected_version)VALUES('review-a',c,other_v,clock_timestamp(),1);RAISE EXCEPTION 'spliced followup accepted';EXCEPTION WHEN foreign_key_violation THEN NULL;END;
 BEGIN INSERT INTO intents(account_ref,contact_id,conversation_id,source_id,kind,expected_version,policy_version,knowledge_version,body,provenance)VALUES('review-a',other_c,other_v,m,'reply',1,'p','k','synthetic','{}');RAISE EXCEPTION 'spliced intent accepted';EXCEPTION WHEN foreign_key_violation THEN NULL;END;
END$$;
-- Non-fixture business IDs must flow from a sent reply into the parent and child.
INSERT INTO accounts VALUES('review-provenance',true);
INSERT INTO controls VALUES('review-provenance','stop','{"enabled":false}');
SELECT bootstrap('review-provenance-token','runtime','review','review-provenance');
INSERT INTO config_docs(account_ref,kind,version,body,active)
SELECT 'review-provenance',kind,version,replace(replace(replace(jsonb_set(body,'{accountRef}','"review-provenance"')::text,'offer-1','review-offer'),'source-1','review-source'),'service-count','review-claim')::jsonb,active
FROM config_docs WHERE account_ref='test-account'AND active;
DO $$DECLARE r jsonb;c uuid;v uuid;i uuid;l uuid;f followups;child intents;BEGIN
 r:=ingest('review-provenance-token','{"account_ref":"review-provenance","provider_id":"provenance","contact_ref":"provenance","body":"hello"}');
 c:=(r->>'contact_id')::uuid;v:=(r->>'conversation_id')::uuid;
 PERFORM set_consent('review-provenance-token','review-provenance',c,'granted','synthetic regression');
 r:=complete_turn('review-provenance-token','review-provenance',v);i:=(r->>'work_id')::uuid;
 ASSERT i IS NOT NULL,'non-fixture reply created';
 r:=claim_dispatch('review-provenance-token','review-provenance',i);l:=(r->>'lease')::uuid;
 r:=begin_provider_call('review-provenance-token','review-provenance',i,l);ASSERT(r->>'ok')::boolean,'non-fixture provider call authorized';
 r:=finish_dispatch('review-provenance-token','review-provenance',i,l,'success');ASSERT r->>'terminal'='sent','non-fixture reply sent';
 SELECT * INTO f FROM followups WHERE account_ref='review-provenance'AND source_intent_id=i;
 ASSERT f.id IS NOT NULL AND f.provenance_snapshot->>'offerId'='review-offer'AND f.provenance_snapshot->'sourceIds'?'review-source'AND f.provenance_snapshot->'claims'?'review-claim','parent snapshots actual approved business provenance';
 ASSERT followup_evidence_valid(f),'snapshot-bound request is valid';
 f.provenance_snapshot:=jsonb_set(f.provenance_snapshot,'{offerId}','"tampered"');
 ASSERT NOT followup_evidence_valid(f),'provenance mutation changes request identity';
 SELECT * INTO f FROM followups WHERE account_ref='review-provenance'AND source_intent_id=i;
 -- Advance only fixture evidence, without relying on a real twelve-hour wait.
 ALTER TABLE followups DISABLE TRIGGER followup_evidence_immutable;
 ALTER TABLE intent_transitions DISABLE TRIGGER transitions_immutable;
 UPDATE intent_transitions SET at=at-interval'13 hours' WHERE account_ref='review-provenance'AND intent_id=i AND to_state='sent';
 UPDATE followups SET due_at=due_at-interval'13 hours',scheduled_from_sent_at=scheduled_from_sent_at-interval'13 hours' WHERE account_ref='review-provenance'AND id=f.id;
 UPDATE followups x SET request_hash=encode(digest(followup_request_payload(x)::text,'sha256'),'hex') WHERE x.account_ref='review-provenance'AND x.id=f.id;
 ALTER TABLE intent_transitions ENABLE TRIGGER transitions_immutable;
 ALTER TABLE followups ENABLE TRIGGER followup_evidence_immutable;
 PERFORM schedule_followups('review-global');
 SELECT x.* INTO child FROM intents x JOIN followups p ON(p.account_ref,p.intent_id)=(x.account_ref,x.id) WHERE p.account_ref='review-provenance'AND p.id=f.id;
 SELECT * INTO f FROM followups WHERE account_ref='review-provenance'AND source_intent_id=i;
 ASSERT child.id IS NOT NULL AND followup_child_evidence_valid(child,f),'scheduler materializes non-fixture provenance';
 ASSERT child.provenance->>'offerId'='review-offer'AND child.provenance->'sourceIds'?'review-source','child preserves configured offer and sources';
END$$;
-- Runtime must not read retained replay keys/fingerprints or call internal helpers.
DO $$BEGIN
 ASSERT NOT has_table_privilege('salesflow_runtime','salesflow.inbound_replay_keys','SELECT'),'replay keys private';
 ASSERT NOT has_table_privilege('salesflow_runtime','salesflow.inbound_replay_identities','SELECT'),'replay fingerprints private';
 ASSERT NOT has_function_privilege('salesflow_runtime','salesflow.inbound_replay_matches(text,uuid,text,text)','EXECUTE'),'replay helper private';
END$$;
ROLLBACK;
SELECT 'review-fixes database regressions passed';
