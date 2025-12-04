CREATE OR REPLACE FUNCTION disable_audit(target_table TEXT)
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
    
    -- Verificar se o trigger existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.triggers 
        WHERE event_object_schema = v_schema
          AND event_object_table = v_table
          AND trigger_name = v_table || '_audit_trigger'
    ) THEN
        RAISE NOTICE 'Auditoria não está ativada para tabela: %', v_full_name;
        RETURN;
    END IF;
    
    -- Remover trigger
    EXECUTE format('
        DROP TRIGGER %I_audit_trigger ON %I.%I
    ', v_table, v_schema, v_table);
    
    RAISE NOTICE '⛔ Auditoria desativada para tabela: %', v_full_name;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp;