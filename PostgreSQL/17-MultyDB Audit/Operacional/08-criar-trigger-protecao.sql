-- ============================================
-- 08 - Criar Trigger de Proteção da Auditoria
-- ============================================
-- Descrição: Bloqueia UPDATE e DELETE na tabela audit_log
--            Garante imutabilidade dos logs de auditoria
-- Execução: Uma vez no banco operacional
-- ============================================

-- Função que bloqueia alterações
CREATE OR REPLACE FUNCTION protect_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    -- Bloquear UPDATE
    IF (TG_OP = 'UPDATE') THEN
        RAISE EXCEPTION 'UPDATE não é permitido na tabela de auditoria! (Registro ID: %)', OLD.id;
    END IF;
    
    -- Bloquear DELETE
    IF (TG_OP = 'DELETE') THEN
        RAISE EXCEPTION 'DELETE não é permitido na tabela de auditoria! (Registro ID: %)', OLD.id;
    END IF;
    
    -- Bloquear TRUNCATE (caso seja suportado)
    IF (TG_OP = 'TRUNCATE') THEN
        RAISE EXCEPTION 'TRUNCATE não é permitido na tabela de auditoria!';
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp;

-- Comentário
COMMENT ON FUNCTION protect_audit_log() IS 
'Função de proteção que impede UPDATE, DELETE e TRUNCATE na tabela audit_log';

-- Criar trigger BEFORE para UPDATE e DELETE
CREATE TRIGGER audit_log_protect_trigger
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION protect_audit_log();

-- Criar trigger para TRUNCATE (statement level)
CREATE TRIGGER audit_log_protect_truncate_trigger
BEFORE TRUNCATE ON audit_log
FOR EACH STATEMENT EXECUTE FUNCTION protect_audit_log();

-- Verificação
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    'Trigger de proteção criado com sucesso!' as status
FROM information_schema.triggers
WHERE event_object_table = 'audit_log'
  AND trigger_name LIKE '%protect%'
ORDER BY trigger_name;

SELECT '🔒 Tabela audit_log agora é IMUTÁVEL!' as resultado;

/*
TESTE DE PROTEÇÃO (descomente para testar):

-- Tentar UPDATE (deve falhar)
-- UPDATE audit_log SET operacao = 'X' WHERE id = 1;

-- Tentar DELETE (deve falhar)
-- DELETE FROM audit_log WHERE id = 1;

-- Tentar TRUNCATE (deve falhar)
-- TRUNCATE audit_log;

Todos devem retornar erro com a mensagem de proteção.
*/
