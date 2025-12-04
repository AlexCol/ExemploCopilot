-- ============================================
-- 01 - Criar Tabela de Auditoria
-- ============================================
-- Descrição: Tabela única para armazenar todos os logs de auditoria
-- Execução: Uma vez no banco operacional
-- ============================================

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    tabela VARCHAR(50) NOT NULL,
    operacao CHAR(1) NOT NULL,  -- 'I' (INSERT), 'U' (UPDATE), 'D' (DELETE)
    usuario VARCHAR(50) NOT NULL,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    aplicacao VARCHAR(100),
    dados_antigos JSONB,  -- OLD (para UPDATE e DELETE)
    dados_novos JSONB     -- NEW (para INSERT e UPDATE)
);

-- Comentários para documentação
COMMENT ON TABLE audit_log IS 'Tabela de auditoria centralizada para todas as tabelas do sistema';
COMMENT ON COLUMN audit_log.tabela IS 'Nome da tabela que sofreu a alteração';
COMMENT ON COLUMN audit_log.operacao IS 'Tipo de operação: I (Insert), U (Update), D (Delete)';
COMMENT ON COLUMN audit_log.usuario IS 'Usuário do PostgreSQL que executou a operação';
COMMENT ON COLUMN audit_log.ip_address IS 'Endereço IP do cliente (quando disponível)';
COMMENT ON COLUMN audit_log.aplicacao IS 'Nome da aplicação conectada (application_name)';
COMMENT ON COLUMN audit_log.dados_antigos IS 'Estado anterior completo do registro (JSON)';
COMMENT ON COLUMN audit_log.dados_novos IS 'Estado novo do registro - INSERT: todos os campos | UPDATE: apenas campos que mudaram | DELETE: null';

-- Verificação
SELECT 'Tabela audit_log criada com sucesso!' as status;
