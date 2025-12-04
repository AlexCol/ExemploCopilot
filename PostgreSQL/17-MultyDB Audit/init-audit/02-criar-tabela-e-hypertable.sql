CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL,
    tabela VARCHAR(50) NOT NULL,
    operacao CHAR(1) NOT NULL CHECK (operacao IN ('I', 'U', 'D')),
    usuario VARCHAR(50) NOT NULL,
    data_hora TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address INET,
    aplicacao VARCHAR(100),
    dados_antigos JSONB,
    dados_novos JSONB,
    PRIMARY KEY (data_hora, id)
);

SELECT create_hypertable('audit_log', by_range('data_hora'), if_not_exists => TRUE);