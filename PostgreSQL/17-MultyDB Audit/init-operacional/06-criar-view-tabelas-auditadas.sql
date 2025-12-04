CREATE OR REPLACE VIEW tabelas_auditadas AS
SELECT DISTINCT ON (t.event_object_table)
    t.trigger_schema as schema,
    t.event_object_table as tabela,
    t.trigger_name as trigger_nome,
    COALESCE(a.total_registros, 0) as total_registros,
    COALESCE(a.total_inserts, 0) as total_inserts,
    COALESCE(a.total_updates, 0) as total_updates,
    COALESCE(a.total_deletes, 0) as total_deletes
FROM information_schema.triggers t
LEFT JOIN (
    SELECT DISTINCT
        tabela,
        COUNT(*) as total_registros,
        COUNT(*) FILTER (WHERE operacao = 'I') as total_inserts,
        COUNT(*) FILTER (WHERE operacao = 'U') as total_updates,
        COUNT(*) FILTER (WHERE operacao = 'D') as total_deletes
    FROM audit_log
    GROUP BY tabela
) a ON t.event_object_table = a.tabela
WHERE t.trigger_name LIKE '%_audit_trigger'
  AND t.action_timing = 'AFTER'
  AND t.event_manipulation IN ('INSERT', 'UPDATE', 'DELETE')
ORDER BY t.event_object_table;