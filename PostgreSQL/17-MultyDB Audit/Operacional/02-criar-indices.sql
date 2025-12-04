-- ============================================
-- 02 - Criar Índices para Performance
-- ============================================
-- Descrição: Índices otimizados para consultas comuns de auditoria
-- Execução: Uma vez, após criar a tabela audit_log
-- ============================================

-- Índice por tabela e data (consulta mais comum)
CREATE INDEX IF NOT EXISTS idx_audit_log_tabela_data 
ON audit_log(tabela, data_hora DESC);

-- Índice por data (para consultas temporais)
CREATE INDEX IF NOT EXISTS idx_audit_log_data 
ON audit_log(data_hora DESC);

-- Índice por usuário (para rastreamento de ações por usuário)
CREATE INDEX IF NOT EXISTS idx_audit_log_usuario 
ON audit_log(usuario, data_hora DESC);

-- Índice GIN para buscas em JSONB (dados_novos)
CREATE INDEX IF NOT EXISTS idx_audit_log_dados_novos 
ON audit_log USING GIN(dados_novos);

-- Índice GIN para buscas em JSONB (dados_antigos)
CREATE INDEX IF NOT EXISTS idx_audit_log_dados_antigos 
ON audit_log USING GIN(dados_antigos);

-- Índice composto para queries de auditoria específicas
CREATE INDEX IF NOT EXISTS idx_audit_log_tabela_operacao 
ON audit_log(tabela, operacao, data_hora DESC);

-- Verificação dos índices criados
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'audit_log'
ORDER BY indexname;

SELECT 'Índices criados com sucesso!' as status;
