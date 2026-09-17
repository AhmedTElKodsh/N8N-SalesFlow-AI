-- Invoked over local Docker stdin by Renew-LocalTokens.ps1; inputs are SHA-256 digests only.
BEGIN;
SET LOCAL search_path=salesflow,public;
SET LOCAL lock_timeout='5s';
DO $renew$
DECLARE matched integer;
BEGIN
  IF session_user NOT IN ('postgres','salesflow_owner') THEN RAISE EXCEPTION 'local owner required'; END IF;
  IF current_database()<>'salesflow' OR NOT EXISTS(SELECT 1 FROM accounts WHERE id='test-account' AND enabled) THEN
    RAISE EXCEPTION 'enabled synthetic local account required';
  END IF;
  -- Lock both rows before testing revocation; a partial renewal must never commit.
  PERFORM 1 FROM auth_tokens WHERE hash IN ('__SCHEDULER_HASH__','__INTAKE_HASH__') ORDER BY hash FOR UPDATE;
  SELECT count(*) INTO matched FROM auth_tokens WHERE revoked_at IS NULL AND (
    (hash='__SCHEDULER_HASH__' AND role='scheduler' AND account_ref IS NULL AND actor='scheduler') OR
    (hash='__INTAKE_HASH__' AND role='runtime' AND account_ref='test-account' AND actor='meta-runtime')
  );
  IF matched<>2 THEN RAISE EXCEPTION 'both original non-revoked local credentials are required'; END IF;
  UPDATE auth_tokens SET expires_at=clock_timestamp()+interval '24 hours'
  WHERE hash IN ('__SCHEDULER_HASH__','__INTAKE_HASH__');
END
$renew$;
COMMIT;
