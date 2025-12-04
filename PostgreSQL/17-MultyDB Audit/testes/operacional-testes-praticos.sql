-- ============================================
-- 99 - Testes Práticos - Sistema de Auditoria
-- ============================================
-- Descrição: Script de teste completo para validar o sistema de auditoria
--            Cria 3 tabelas, ativa auditoria em 2 delas e executa operações
-- Execução: Após executar todos os scripts de 01 a 08
-- ============================================

-- ============================================
-- ETAPA 1: CRIAR TABELAS DE TESTE
-- ============================================

-- Tabela 1: Clientes (COM auditoria)
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    telefone VARCHAR(20),
    ativo BOOLEAN DEFAULT TRUE,
    data_cadastro TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela 2: Produtos (COM auditoria)
CREATE TABLE IF NOT EXISTS produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    preco NUMERIC(10,2) NOT NULL,
    estoque INTEGER DEFAULT 0,
    categoria VARCHAR(50),
    data_cadastro TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela 3: Configurações (SEM auditoria - apenas para contraste)
CREATE TABLE IF NOT EXISTS configuracoes (
    id SERIAL PRIMARY KEY,
    chave VARCHAR(50) NOT NULL UNIQUE,
    valor TEXT,
    descricao TEXT
);

SELECT '✅ Tabelas criadas: clientes, produtos, configuracoes' as status;

-- ============================================
-- ETAPA 2: ATIVAR AUDITORIA
-- ============================================

-- Ativar auditoria em clientes e produtos
SELECT enable_audit('clientes');
SELECT enable_audit('produtos');

-- Verificar tabelas auditadas
SELECT 
    '✅ Auditoria ativada!' as status,
    tabela,
    trigger_nome
FROM tabelas_auditadas
WHERE tabela IN ('clientes', 'produtos');

-- ============================================
-- ETAPA 3: OPERAÇÕES NA TABELA CLIENTES
-- ============================================

-- INSERT: Adicionar clientes
INSERT INTO clientes (nome, email, telefone) VALUES
    ('João Silva', 'joao@email.com', '11987654321'),
    ('Maria Santos', 'maria@email.com', '11987654322'),
    ('Pedro Oliveira', 'pedro@email.com', '11987654323');

SELECT '✅ 3 clientes inseridos' as status;

-- UPDATE: Alterar dados
UPDATE clientes 
SET email = 'joao.silva@newemail.com', 
    telefone = '11999999999'
WHERE id = 1;

UPDATE clientes 
SET ativo = FALSE 
WHERE id = 3;

SELECT '✅ 2 clientes atualizados' as status;

-- DELETE: Remover um cliente
DELETE FROM clientes WHERE id = 2;

SELECT '✅ 1 cliente deletado' as status;

-- ============================================
-- ETAPA 4: OPERAÇÕES NA TABELA PRODUTOS
-- ============================================

-- INSERT: Adicionar produtos
INSERT INTO produtos (nome, descricao, preco, estoque, categoria) VALUES
    ('Mouse Gamer', 'Mouse RGB com 7 botões', 150.00, 50, 'Periféricos'),
    ('Teclado Mecânico', 'Teclado com switches blue', 450.00, 30, 'Periféricos'),
    ('Monitor 24"', 'Monitor Full HD 144Hz', 800.00, 15, 'Monitores');

SELECT '✅ 3 produtos inseridos' as status;

-- UPDATE: Ajustar preços e estoque
UPDATE produtos 
SET preco = 135.00, 
    estoque = 45 
WHERE id = 1;

UPDATE produtos 
SET estoque = estoque - 5 
WHERE categoria = 'Periféricos';

SELECT '✅ Produtos atualizados (preço e estoque)' as status;

-- DELETE: Remover produto
DELETE FROM produtos WHERE id = 2;

SELECT '✅ 1 produto deletado' as status;

-- ============================================
-- ETAPA 5: OPERAÇÕES SEM AUDITORIA (CONTRASTE)
-- ============================================

-- Inserir configurações (NÃO será auditado)
INSERT INTO configuracoes (chave, valor, descricao) VALUES
    ('max_usuarios', '1000', 'Número máximo de usuários simultâneos'),
    ('timeout_sessao', '3600', 'Timeout de sessão em segundos');

UPDATE configuracoes SET valor = '5000' WHERE chave = 'max_usuarios';

SELECT '✅ Operações em configuracoes (SEM auditoria)' as status;

-- ============================================
-- ETAPA 6: ADICIONAR COLUNAS (TESTAR ALTER TABLE)
-- ============================================

-- Adicionar novas colunas nas tabelas auditadas
ALTER TABLE clientes ADD COLUMN cpf VARCHAR(11);
ALTER TABLE clientes ADD COLUMN data_nascimento DATE;

ALTER TABLE produtos ADD COLUMN codigo_barras VARCHAR(13);
ALTER TABLE produtos ADD COLUMN fabricante VARCHAR(100);

SELECT '✅ Colunas adicionadas via ALTER TABLE' as status;

-- Fazer UPDATE com as novas colunas (deve aparecer no log!)
UPDATE clientes 
SET cpf = '12345678901', 
    data_nascimento = '1990-05-15'
WHERE id = 1;

UPDATE produtos 
SET codigo_barras = '7891234567890',
    fabricante = 'TechCorp'
WHERE id = 1;

SELECT '✅ Novos campos atualizados (teste ALTER TABLE)' as status;

-- ============================================
-- ETAPA 7: CONSULTAR LOGS DE AUDITORIA
-- ============================================

-- Ver TODOS os logs gerados
SELECT 
    id,
    tabela,
    operacao,
    usuario,
    data_hora::TIMESTAMP(0) as quando,
    CASE 
        WHEN operacao = 'I' THEN dados_novos
        WHEN operacao = 'U' THEN jsonb_build_object(
            'antes', dados_antigos,
            'depois', dados_novos
        )
        WHEN operacao = 'D' THEN dados_antigos
    END as dados
FROM audit_log
ORDER BY data_hora DESC;

-- ============================================
-- ETAPA 8: CONSULTAS ESPECÍFICAS
-- ============================================

-- 8.1: Ver apenas logs de CLIENTES
SELECT 
    '=== LOGS DE CLIENTES ===' as titulo;

SELECT 
    id,
    operacao,
    data_hora::TIMESTAMP(0) as quando,
    dados_novos->>'nome' as nome,
    dados_novos->>'email' as email
FROM audit_log
WHERE tabela = 'clientes'
ORDER BY data_hora;

-- 8.2: Ver apenas logs de PRODUTOS
SELECT 
    '=== LOGS DE PRODUTOS ===' as titulo;

SELECT 
    id,
    operacao,
    data_hora::TIMESTAMP(0) as quando,
    dados_novos->>'nome' as produto,
    dados_novos->>'preco' as preco,
    dados_novos->>'estoque' as estoque
FROM audit_log
WHERE tabela = 'produtos'
ORDER BY data_hora;

-- 8.3: Ver evolução completa de um cliente específico
SELECT 
    '=== EVOLUÇÃO DO CLIENTE ID 1 ===' as titulo;

SELECT 
    id,
    operacao,
    data_hora::TIMESTAMP(0) as quando,
    CASE 
        WHEN operacao = 'I' THEN 'Criado'
        WHEN operacao = 'U' THEN 'Atualizado'
        WHEN operacao = 'D' THEN 'Deletado'
    END as acao,
    dados_antigos,
    dados_novos
FROM audit_log
WHERE tabela = 'clientes'
  AND (dados_novos->>'id' = '1' OR dados_antigos->>'id' = '1')
ORDER BY data_hora;

-- 8.4: Ver apenas mudanças de PREÇO
SELECT 
    '=== MUDANÇAS DE PREÇO ===' as titulo;

SELECT 
    id,
    data_hora::TIMESTAMP(0) as quando,
    dados_novos->>'nome' as produto,
    dados_antigos->>'preco' as preco_anterior,
    dados_novos->>'preco' as preco_novo
FROM audit_log
WHERE tabela = 'produtos'
  AND operacao = 'U'
  AND dados_antigos->>'preco' IS DISTINCT FROM dados_novos->>'preco'
ORDER BY data_hora;

-- 8.5: Ver apenas DELETEs
SELECT 
    '=== REGISTROS DELETADOS ===' as titulo;

SELECT 
    id,
    tabela,
    data_hora::TIMESTAMP(0) as quando,
    usuario,
    dados_antigos as dados_deletados
FROM audit_log
WHERE operacao = 'D'
ORDER BY data_hora;

-- 8.6: Estatísticas por tabela
SELECT 
    '=== ESTATÍSTICAS POR TABELA ===' as titulo;

SELECT 
    tabela,
    COUNT(*) as total_operacoes,
    COUNT(*) FILTER (WHERE operacao = 'I') as inserts,
    COUNT(*) FILTER (WHERE operacao = 'U') as updates,
    COUNT(*) FILTER (WHERE operacao = 'D') as deletes,
    MIN(data_hora)::TIMESTAMP(0) as primeira_operacao,
    MAX(data_hora)::TIMESTAMP(0) as ultima_operacao
FROM audit_log
GROUP BY tabela
ORDER BY total_operacoes DESC;

-- 8.7: Verificar que configuracoes NÃO tem logs
SELECT 
    '=== VERIFICAR CONFIGURACOES (DEVE ESTAR VAZIO) ===' as titulo;

SELECT 
    COUNT(*) as total_logs_configuracoes,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Correto! Configuracoes não está sendo auditado'
        ELSE '❌ Erro! Configuracoes não deveria estar sendo auditado'
    END as resultado
FROM audit_log
WHERE tabela = 'configuracoes';

-- ============================================
-- ETAPA 9: TESTAR PROTEÇÃO (DEVE FALHAR)
-- ============================================

SELECT 
    '=== TESTANDO PROTEÇÃO DOS LOGS ===' as titulo;

-- Tentar UPDATE (deve retornar erro)
DO $$
BEGIN
    UPDATE audit_log SET operacao = 'X' WHERE id = 1;
    RAISE EXCEPTION 'ERRO: UPDATE deveria ter sido bloqueado!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '✅ UPDATE bloqueado corretamente: %', SQLERRM;
END $$;

-- Tentar DELETE (deve retornar erro)
DO $$
BEGIN
    DELETE FROM audit_log WHERE id = 1;
    RAISE EXCEPTION 'ERRO: DELETE deveria ter sido bloqueado!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '✅ DELETE bloqueado corretamente: %', SQLERRM;
END $$;

-- ============================================
-- ETAPA 10: RESUMO FINAL
-- ============================================

SELECT 
    '===========================================' as separador;
    
SELECT 
    '✅ TESTE COMPLETO FINALIZADO!' as status;

SELECT 
    '===========================================' as separador;

-- Resumo das tabelas auditadas
SELECT * FROM tabelas_auditadas;

SELECT 
    '===========================================' as separador;

-- Total de logs gerados
SELECT 
    COUNT(*) as total_logs_gerados,
    pg_size_pretty(pg_total_relation_size('audit_log')) as tamanho_tabela_auditoria
FROM audit_log;

SELECT 
    '===========================================' as separador;
    
SELECT 
    '📊 Para ver todos os logs: SELECT * FROM audit_log ORDER BY data_hora DESC;' as dica;

/*
============================================
LIMPEZA (DESCOMENTE SE QUISER REMOVER OS TESTES)
============================================

-- Desativar auditoria
SELECT disable_audit('clientes');
SELECT disable_audit('produtos');

-- Remover tabelas de teste
DROP TABLE IF EXISTS clientes CASCADE;
DROP TABLE IF EXISTS produtos CASCADE;
DROP TABLE IF EXISTS configuracoes CASCADE;

-- ATENÇÃO: Isso NÃO remove os logs! 
-- Os logs ficam preservados em audit_log (imutáveis)
-- Se quiser limpar os logs de teste (CUIDADO!):
-- Primeiro você precisa TEMPORARIAMENTE desabilitar a proteção:

-- DROP TRIGGER audit_log_protect_trigger ON audit_log;
-- DROP TRIGGER audit_log_protect_truncate_trigger ON audit_log;
-- DELETE FROM audit_log WHERE tabela IN ('clientes', 'produtos', 'configuracoes');
-- -- Recriar proteção rodando novamente: 08-criar-trigger-protecao.sql

*/
