-- 09-criar-protecao.sql
CREATE OR REPLACE FUNCTION protect_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Operação % não permitida na tabela audit_log (dados imutáveis)', TG_OP;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_protect_audit_update
BEFORE UPDATE ON audit_log
FOR EACH ROW EXECUTE FUNCTION protect_audit_log();

CREATE TRIGGER trg_protect_audit_delete
BEFORE DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION protect_audit_log();

CREATE TRIGGER trg_protect_audit_truncate
BEFORE TRUNCATE ON audit_log
FOR EACH STATEMENT EXECUTE FUNCTION protect_audit_log();

REVOKE UPDATE, DELETE, TRUNCATE ON audit_log FROM PUBLIC;
REVOKE UPDATE, DELETE, TRUNCATE ON audit_log FROM audit_user;
GRANT SELECT, INSERT ON audit_log TO audit_user;