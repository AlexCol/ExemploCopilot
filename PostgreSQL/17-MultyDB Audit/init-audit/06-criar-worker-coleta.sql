--ASSINATURA DO METODO OBRIGATORIA PARA O CRON
CREATE OR REPLACE FUNCTION collect_audit_from_operational(job_id INT, config JSONB)
RETURNS void AS $$
DECLARE
    last_id BIGINT;
    max_id BIGINT;
    collected_count BIGINT;
BEGIN
    SELECT last_collected_id INTO last_id FROM audit_sync_control LIMIT 1;
    
    INSERT INTO audit_log (id, tabela, operacao, usuario, data_hora, ip_address, aplicacao, dados_antigos, dados_novos)
    SELECT id, tabela, operacao, usuario, data_hora, ip_address, aplicacao, dados_antigos, dados_novos
    FROM audit_log_remote
    WHERE id > last_id
    ORDER BY id
    LIMIT 10000;
    
    GET DIAGNOSTICS collected_count = ROW_COUNT;
    
    IF collected_count > 0 THEN
        SELECT MAX(id) INTO max_id FROM audit_log;
        
        DELETE FROM audit_log_remote WHERE id <= max_id;
        
        UPDATE audit_sync_control 
        SET last_collected_id = max_id,
            last_sync_time = NOW(),
            records_collected = records_collected + collected_count;
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT add_job(
  'collect_audit_from_operational', 
  INTERVAL '10 seconds');