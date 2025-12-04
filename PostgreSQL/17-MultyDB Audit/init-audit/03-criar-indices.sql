CREATE INDEX IF NOT EXISTS idx_audit_tabela_data 
ON audit_log (tabela, data_hora DESC);

CREATE INDEX IF NOT EXISTS idx_audit_usuario_data 
ON audit_log (usuario, data_hora DESC);

CREATE INDEX IF NOT EXISTS idx_audit_operacao_data 
ON audit_log (operacao, data_hora DESC);

CREATE INDEX IF NOT EXISTS idx_audit_dados_novos_gin 
ON audit_log USING GIN (dados_novos jsonb_path_ops);

CREATE INDEX IF NOT EXISTS idx_audit_dados_antigos_gin 
ON audit_log USING GIN (dados_antigos jsonb_path_ops);