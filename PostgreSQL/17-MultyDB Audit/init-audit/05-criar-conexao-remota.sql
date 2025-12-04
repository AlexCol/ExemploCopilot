CREATE SERVER IF NOT EXISTS operational_db
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'db_operacional',
    port '5432',
    dbname 'db_operacional'
);

CREATE USER MAPPING IF NOT EXISTS FOR audit_user
SERVER operational_db
OPTIONS (user 'admin', password 'admin123');

CREATE FOREIGN TABLE IF NOT EXISTS audit_log_remote (
    id BIGINT,
    tabela VARCHAR(50),
    operacao CHAR(1),
    usuario VARCHAR(50),
    data_hora TIMESTAMPTZ,
    ip_address INET,
    aplicacao VARCHAR(100),
    dados_antigos JSONB,
    dados_novos JSONB
)
SERVER operational_db
OPTIONS (schema_name 'public', table_name 'audit_log');

CREATE TABLE IF NOT EXISTS audit_sync_control (
    last_collected_id BIGINT NOT NULL DEFAULT 0,
    last_sync_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    records_collected BIGINT NOT NULL DEFAULT 0
);

INSERT INTO audit_sync_control (last_collected_id, last_sync_time, records_collected)
VALUES (0, NOW(), 0)
ON CONFLICT DO NOTHING;