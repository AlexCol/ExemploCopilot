CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
    v_key TEXT;
BEGIN
    -- Capturar dados conforme o tipo de operação
    IF (TG_OP = 'DELETE') THEN
        v_old_data = row_to_json(OLD)::JSONB;
        v_new_data = NULL;
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old_data = row_to_json(OLD)::JSONB;
        v_new_data = row_to_json(NEW)::JSONB;
        
        -- Para UPDATE: salvar apenas os campos que mudaram
        -- Comparar OLD e NEW e manter só as diferenças
        v_new_data = (
            SELECT jsonb_object_agg(key, value)
            FROM jsonb_each(v_new_data)
            WHERE v_old_data->key IS DISTINCT FROM value
        );
    ELSIF (TG_OP = 'INSERT') THEN
        v_old_data = NULL;
        v_new_data = row_to_json(NEW)::JSONB;
    END IF;
    
    -- Inserir na tabela de auditoria
    INSERT INTO audit_log (
        tabela, 
        operacao, 
        usuario, 
        ip_address, 
        aplicacao,
        dados_antigos, 
        dados_novos
    ) VALUES (
        TG_TABLE_NAME::VARCHAR,           -- Nome da tabela
        LEFT(TG_OP, 1),                   -- Primeira letra da operação (I/U/D)
        current_user,                     -- Usuário atual do PostgreSQL
        inet_client_addr(),               -- IP do cliente (pode ser NULL)
        current_setting('application_name', TRUE),  -- Nome da aplicação
        v_old_data,
        v_new_data
    );
    
    -- Retornar o registro apropriado
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER  -- Executa com privilégios do dono da função
SET search_path = public, pg_temp;  -- Segurança contra search_path attack