-- 07-criar-continuous-aggregates.sql
CREATE MATERIALIZED VIEW IF NOT EXISTS audit_stats_daily
WITH (timescaledb.continuous) AS
SELECT 
    time_bucket('1 day', data_hora) AS dia,
    tabela,
    operacao,
    COUNT(*) as total_operacoes,
    COUNT(DISTINCT usuario) as total_usuarios
FROM audit_log
GROUP BY dia, tabela, operacao
WITH NO DATA;

CREATE MATERIALIZED VIEW IF NOT EXISTS audit_stats_monthly
WITH (timescaledb.continuous) AS
SELECT 
    time_bucket('1 month', data_hora) AS mes,
    tabela,
    operacao,
    COUNT(*) as total_operacoes,
    COUNT(DISTINCT usuario) as total_usuarios
FROM audit_log
GROUP BY mes, tabela, operacao
WITH NO DATA;