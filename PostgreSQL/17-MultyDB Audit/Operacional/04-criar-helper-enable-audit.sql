-- ============================================
-- 04 - Criar Função Helper: enable_audit()
-- ============================================
-- Descrição: Função para ativar auditoria em qualquer tabela com 1 linha
-- Uso: SELECT enable_audit('nome_da_tabela');
-- Execução: Uma vez no banco operacional
-- ============================================

CREATE OR REPLACE FUNCTION enable_audit(target_table TEXT)
RETURNS VOID AS $$
DECLARE
    v_schema TEXT;
    v_table TEXT;
    v_full_name TEXT;
BEGIN
    -- Separar schema e tabela se fornecido (ex: 'public.users')
    IF target_table LIKE '%.%' THEN
        v_schema := split_part(target_table, '.', 1);
        v_table := split_part(target_table, '.', 2);
    ELSE
        v_schema := 'public';
        v_table := target_table;
    END IF;
    
    v_full_name := v_schema || '.' || v_table;
    
    -- Verificar se a tabela existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = v_schema 
          AND table_name = v_table
    ) THEN
        RAISE EXCEPTION 'Tabela % não existe!', v_full_name;
    END IF;
    
    -- Verificar se o trigger já existe
    IF EXISTS (
        SELECT 1 
        FROM information_schema.triggers 
        WHERE event_object_schema = v_schema
          AND event_object_table = v_table
          AND trigger_name = v_table || '_audit_trigger'
    ) THEN
        RAISE NOTICE 'Auditoria já está ativada para tabela: %', v_full_name;
        RETURN;
    END IF;
    
    -- Criar trigger
    EXECUTE format('
        CREATE TRIGGER %I_audit_trigger
        AFTER INSERT OR UPDATE OR DELETE ON %I.%I
        FOR EACH ROW EXECUTE FUNCTION audit_trigger_func()
    ', v_table, v_schema, v_table);
    
    RAISE NOTICE '✅ Auditoria ativada para tabela: %', v_full_name;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp;

-- Comentário
COMMENT ON FUNCTION enable_audit(TEXT) IS 
'Ativa auditoria automática em uma tabela. Uso: SELECT enable_audit(''nome_tabela'')';

-- Teste de verificação
SELECT 'Função enable_audit() criada com sucesso!' as status;

-- Exemplo de uso (comentado):
-- SELECT enable_audit('users');
-- SELECT enable_audit('pedidos');
-- SELECT enable_audit('produtos');
