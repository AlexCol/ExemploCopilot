# 16.4 - Audit Triggers e Tabelas de Auditoria

## 📋 O que você vai aprender

- Tabelas espelho de auditoria
- Triggers para INSERT/UPDATE/DELETE
- Auditoria genérica com JSONB
- Capturar OLD vs NEW
- Metadados de auditoria
- Proteção de tabelas de audit

---

## 🎯 O que são Audit Triggers?

**Audit Triggers** são triggers de banco de dados que capturam mudanças (INSERT, UPDATE, DELETE) em tabelas e registram essas mudanças em **tabelas de auditoria** dedicadas.

### Diferenças vs Outros Mecanismos

| Característica | Audit Triggers | Logs | pg_stat_statements |
|----------------|----------------|------|-------------------|
| Granularidade | Linha por linha | Statement | Statement agregado |
| OLD/NEW values | ✅ Sim | ❌ Não | ❌ Não |
| Customização | ✅ Alta | ⚠️ Média | ❌ Baixa |
| Overhead | Alto (escrita) | Médio (I/O) | Baixo (memória) |
| Uso principal | Compliance | Debugging | Performance tuning |

### Para que servem?

1. **Compliance**: LGPD, GDPR, SOX, PCI-DSS
2. **Auditoria**: Rastrear quem mudou o quê e quando
3. **Forense**: Investigar incidentes
4. **Versionamento**: Histórico completo de mudanças
5. **Rollback**: Restaurar valores antigos

---

## 📊 Padrão 1: Tabela Espelho

Criar uma tabela de auditoria com **mesma estrutura** da tabela original, plus metadados.

### Implementação

```sql
-- Tabela principal
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100),
    ativo BOOLEAN DEFAULT TRUE
);

-- Tabela de auditoria (espelho)
CREATE TABLE clientes_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    operacao CHAR(1) NOT NULL,  -- 'I'=INSERT, 'U'=UPDATE, 'D'=DELETE
    usuario VARCHAR(50) NOT NULL,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    aplicacao VARCHAR(100),
    -- Colunas da tabela original
    id INTEGER,
    nome VARCHAR(100),
    email VARCHAR(100),
    ativo BOOLEAN
);

CREATE INDEX idx_clientes_audit_id ON clientes_audit(id);
CREATE INDEX idx_clientes_audit_data ON clientes_audit(data_hora DESC);
```

### Triggers

```sql
-- Função genérica para INSERT
CREATE OR REPLACE FUNCTION audit_clientes_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO clientes_audit (
        operacao, usuario, ip_address, aplicacao,
        id, nome, email, ativo
    ) VALUES (
        'I', 
        current_user, 
        inet_client_addr(), 
        current_setting('application_name', TRUE),
        NEW.id, NEW.nome, NEW.email, NEW.ativo
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clientes_audit_insert
AFTER INSERT ON clientes
FOR EACH ROW EXECUTE FUNCTION audit_clientes_insert();

-- Função genérica para UPDATE
CREATE OR REPLACE FUNCTION audit_clientes_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO clientes_audit (
        operacao, usuario, ip_address, aplicacao,
        id, nome, email, ativo
    ) VALUES (
        'U', 
        current_user, 
        inet_client_addr(), 
        current_setting('application_name', TRUE),
        NEW.id, NEW.nome, NEW.email, NEW.ativo
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clientes_audit_update
AFTER UPDATE ON clientes
FOR EACH ROW EXECUTE FUNCTION audit_clientes_update();

-- Função genérica para DELETE
CREATE OR REPLACE FUNCTION audit_clientes_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO clientes_audit (
        operacao, usuario, ip_address, aplicacao,
        id, nome, email, ativo
    ) VALUES (
        'D', 
        current_user, 
        inet_client_addr(), 
        current_setting('application_name', TRUE),
        OLD.id, OLD.nome, OLD.email, OLD.ativo
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clientes_audit_delete
AFTER DELETE ON clientes
FOR EACH ROW EXECUTE FUNCTION audit_clientes_delete();
```

### Teste

```sql
-- Inserir
INSERT INTO clientes (nome, email) VALUES ('João', 'joao@example.com');

-- Atualizar
UPDATE clientes SET ativo = FALSE WHERE id = 1;

-- Deletar
DELETE FROM clientes WHERE id = 1;

-- Ver histórico
SELECT * FROM clientes_audit ORDER BY audit_id;

/*
 audit_id | operacao | usuario  | data_hora           | id | nome | email            | ativo
----------+----------+----------+---------------------+----+------+------------------+-------
        1 | I        | app_user | 2024-01-15 10:40:00 |  1 | João | joao@example.com | t
        2 | U        | app_user | 2024-01-15 10:41:00 |  1 | João | joao@example.com | f
        3 | D        | app_user | 2024-01-15 10:42:00 |  1 | João | joao@example.com | f
*/
```

---

## 📦 Padrão 2: Auditoria Genérica com JSONB

Uma **única tabela de auditoria** para **todas as tabelas** do banco, armazenando dados como JSONB.

### Vantagens

- ✅ Não precisa criar tabela de auditoria para cada tabela
- ✅ Função de trigger reutilizável
- ✅ Flexível (adicionar colunas não requer mudança na audit table)
- ✅ Fácil consultar mudanças específicas com JSONB operators

### Implementação

```sql
-- Tabela genérica de auditoria
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    tabela VARCHAR(50) NOT NULL,
    operacao CHAR(1) NOT NULL,  -- 'I', 'U', 'D'
    usuario VARCHAR(50) NOT NULL,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    aplicacao VARCHAR(100),
    dados_antigos JSONB,  -- OLD (para UPDATE e DELETE)
    dados_novos JSONB     -- NEW (para INSERT e UPDATE)
);

CREATE INDEX idx_audit_log_tabela ON audit_log(tabela);
CREATE INDEX idx_audit_log_data ON audit_log(data_hora DESC);
CREATE INDEX idx_audit_log_dados_novos ON audit_log USING GIN(dados_novos);
CREATE INDEX idx_audit_log_dados_antigos ON audit_log USING GIN(dados_antigos);
```

### Função Genérica de Auditoria

```sql
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_old_data = row_to_json(OLD)::JSONB;
        v_new_data = NULL;
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old_data = row_to_json(OLD)::JSONB;
        v_new_data = row_to_json(NEW)::JSONB;
    ELSIF (TG_OP = 'INSERT') THEN
        v_old_data = NULL;
        v_new_data = row_to_json(NEW)::JSONB;
    END IF;
    
    INSERT INTO audit_log (
        tabela, operacao, usuario, 
        ip_address, aplicacao,
        dados_antigos, dados_novos
    ) VALUES (
        TG_TABLE_NAME::VARCHAR, 
        LEFT(TG_OP, 1),
        current_user,
        inet_client_addr(),
        current_setting('application_name', TRUE),
        v_old_data,
        v_new_data
    );
    
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### Aplicar a Múltiplas Tabelas

```sql
-- Aplicar a clientes
CREATE TRIGGER clientes_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Aplicar a pedidos
CREATE TRIGGER pedidos_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON pedidos
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Aplicar a produtos
CREATE TRIGGER produtos_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON produtos
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
```

### Consultar Auditoria

```sql
-- Ver todas as mudanças na tabela clientes
SELECT 
    id,
    operacao,
    usuario,
    data_hora,
    dados_novos->>'nome' AS nome,
    dados_novos->>'email' AS email
FROM audit_log
WHERE tabela = 'clientes'
ORDER BY id DESC;

-- Ver quem mudou o email do cliente ID 123
SELECT 
    usuario,
    data_hora,
    dados_antigos->>'email' AS email_antigo,
    dados_novos->>'email' AS email_novo
FROM audit_log
WHERE tabela = 'clientes'
  AND operacao = 'U'
  AND dados_novos->>'id' = '123'
  AND dados_antigos->>'email' != dados_novos->>'email';

-- Ver todos os DELETEs feitos por um usuário
SELECT 
    tabela,
    data_hora,
    dados_antigos
FROM audit_log
WHERE usuario = 'admin'
  AND operacao = 'D'
ORDER BY data_hora DESC;
```

---

## 🔧 Padrão 3: Extensão audit-trigger (Automático)

Para quem quer **auditoria automática sem criar triggers manualmente**, existe a extensão **`audit-trigger`** (também chamada de `audit` ou `tablelog`).

### Instalação

```bash
# Ubuntu/Debian
sudo apt-get install postgresql-contrib

# No PostgreSQL
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS audit;  -- ou tablelog, dependendo da versão
```

### Uso - EXTREMAMENTE SIMPLES

```sql
-- 1. Criar sua tabela normalmente
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 2. Ativar auditoria (UMA LINHA!)
SELECT audit.audit_table('users');

-- 3. Usar normalmente - TUDO É LOGADO AUTOMATICAMENTE!
INSERT INTO users (name, email) VALUES ('João', 'joao@mail.com');
UPDATE users SET email = 'joao.silva@mail.com' WHERE id = 1;

-- 4. Adicionar colunas - FUNCIONA AUTOMATICAMENTE!
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
ALTER TABLE users ADD COLUMN department VARCHAR(50);

UPDATE users SET phone = '47999999999', department = 'TI' WHERE id = 1;
DELETE FROM users WHERE id = 1;

-- 5. Consultar o log (tabela criada automaticamente)
SELECT 
    event_id,
    schema_name,
    table_name,
    session_user_name,
    action_tstamp_clk::timestamp(0) as quando,
    action,
    row_data,        -- Dados completos (hstore ou jsonb)
    changed_fields   -- Apenas campos que mudaram
FROM audit.logged_actions
WHERE table_name = 'users'
ORDER BY event_id DESC;
```

### Recursos Automáticos

- ✅ **Captura automática**: INSERT, UPDATE, DELETE
- ✅ **Metadados automáticos**: usuário, timestamp, IP, transaction ID
- ✅ **OLD e NEW values**: Valores antes e depois da mudança
- ✅ **Compatível com ALTER TABLE**: Adicionar colunas funciona automaticamente
- ✅ **Statement text**: SQL completo executado
- ✅ **Zero manutenção**: Não precisa atualizar triggers

### Configurações Avançadas

```sql
-- Excluir colunas específicas (ex: senha)
SELECT audit.audit_table('users', true, true, ARRAY['password']::TEXT[]);

-- Desativar auditoria de uma tabela
SELECT audit.audit_table_drop('users');

-- Reativar auditoria
SELECT audit.audit_table('users');

-- Ver todas as tabelas auditadas
SELECT * FROM audit.tableslist;
```

### Consultas Úteis

```sql
-- Ver evolução de um registro específico
SELECT 
    event_id,
    action,
    action_tstamp_clk::timestamp(0) as quando,
    session_user_name,
    row_data,
    changed_fields
FROM audit.logged_actions
WHERE table_name = 'users'
  AND (row_data->'id')::text = '1'
ORDER BY event_id;

-- Ver apenas mudanças de email
SELECT 
    event_id,
    action_tstamp_clk::timestamp(0) as quando,
    session_user_name,
    changed_fields->'email' as novo_email,
    row_data->'email' as email_completo
FROM audit.logged_actions
WHERE table_name = 'users'
  AND action = 'U'
  AND changed_fields ? 'email'  -- Apenas onde email mudou
ORDER BY event_id DESC;

-- Ver quem deletou algo
SELECT 
    session_user_name,
    action_tstamp_clk::timestamp(0) as quando,
    row_data
FROM audit.logged_actions
WHERE table_name = 'users'
  AND action = 'D'
ORDER BY event_id DESC;

-- Mudanças nas últimas 24h
SELECT 
    table_name,
    action,
    session_user_name,
    COUNT(*) as total
FROM audit.logged_actions
WHERE action_tstamp_clk > NOW() - INTERVAL '24 hours'
GROUP BY table_name, action, session_user_name
ORDER BY total DESC;

-- Ver quem fez mais mudanças
SELECT 
    session_user_name,
    COUNT(*) as total_mudancas,
    COUNT(*) FILTER (WHERE action = 'I') as inserts,
    COUNT(*) FILTER (WHERE action = 'U') as updates,
    COUNT(*) FILTER (WHERE action = 'D') as deletes
FROM audit.logged_actions
GROUP BY session_user_name
ORDER BY total_mudancas DESC;
```

### Estrutura da Tabela `audit.logged_actions`

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `event_id` | BIGSERIAL | ID único do evento |
| `schema_name` | TEXT | Schema da tabela |
| `table_name` | TEXT | Nome da tabela |
| `relid` | OID | Object ID da tabela |
| `session_user_name` | TEXT | Usuário da sessão |
| `action_tstamp_tx` | TIMESTAMPTZ | Timestamp da transação |
| `action_tstamp_stm` | TIMESTAMPTZ | Timestamp do statement |
| `action_tstamp_clk` | TIMESTAMPTZ | Timestamp do relógio |
| `transaction_id` | BIGINT | ID da transação |
| `application_name` | TEXT | Nome da aplicação |
| `client_addr` | INET | IP do cliente |
| `client_port` | INTEGER | Porta do cliente |
| `client_query` | TEXT | Query executada |
| `action` | TEXT | 'I' (INSERT), 'U' (UPDATE), 'D' (DELETE), 'T' (TRUNCATE) |
| `row_data` | HSTORE/JSONB | Dados completos da linha |
| `changed_fields` | HSTORE/JSONB | Apenas campos alterados |
| `statement_only` | BOOLEAN | Se é statement-level trigger |

### Alternativa: Função Wrapper para Simular a Extensão

Se a extensão `audit` não estiver disponível, você pode criar funções wrapper que simulam o comportamento:

```sql
-- Reutilizar a função audit_trigger_func() do Padrão 2 acima

-- Função para ativar auditoria automaticamente em qualquer tabela
CREATE OR REPLACE FUNCTION enable_audit(target_table TEXT)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('
        CREATE TRIGGER %I_audit_trigger
        AFTER INSERT OR UPDATE OR DELETE ON %I
        FOR EACH ROW EXECUTE FUNCTION audit_trigger_func()
    ', target_table, target_table);
    
    RAISE NOTICE 'Auditoria ativada para tabela: %', target_table;
END;
$$ LANGUAGE plpgsql;

-- Função para desativar auditoria
CREATE OR REPLACE FUNCTION disable_audit(target_table TEXT)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('DROP TRIGGER IF EXISTS %I_audit_trigger ON %I', 
                   target_table, target_table);
    RAISE NOTICE 'Auditoria desativada para tabela: %', target_table;
END;
$$ LANGUAGE plpgsql;

-- Usar assim (simples como a extensão):
SELECT enable_audit('users');
SELECT enable_audit('pedidos');
SELECT enable_audit('produtos');

-- Desativar:
SELECT disable_audit('users');

-- Ver tabelas auditadas (criar view helper)
CREATE OR REPLACE VIEW tabelas_auditadas AS
SELECT DISTINCT 
    tabela,
    COUNT(*) as total_registros,
    MIN(data_hora) as primeira_auditoria,
    MAX(data_hora) as ultima_auditoria
FROM audit_log
GROUP BY tabela
ORDER BY tabela;

SELECT * FROM tabelas_auditadas;
```

### Comparação: Extensão vs Manual vs Wrapper

| Aspecto | audit Extension | Triggers Manuais | Função Wrapper |
|---------|----------------|------------------|----------------|
| **Setup** | 1 linha | ~50 linhas/tabela | 1 linha |
| **Manutenção** | Zero | Alta | Baixa |
| **Metadados** | Completos | Customizável | Customizável |
| **ALTER TABLE** | Automático | Pode quebrar | Automático (JSONB) |
| **Performance** | Otimizado | Variável | Boa |
| **Portabilidade** | Requer extensão | Total | Total |
| **Customização** | Limitada | Total | Média |
| **Instalação** | Precisa instalar | Não precisa | Não precisa |

### Quando Usar Cada Abordagem?

#### Use a extensão `audit` se:
- ✅ Quer setup rápido e zero manutenção
- ✅ Precisa de metadados completos automaticamente (client_query, ports, etc)
- ✅ Não precisa customizar o formato dos logs
- ✅ Está em ambiente controlado (pode instalar extensões)
- ✅ Quer usar HSTORE para dados (mais compacto que JSONB)

#### Use a função wrapper (enable_audit) se:
- ✅ Quer simplicidade similar à extensão
- ✅ **NÃO pode instalar extensões** no servidor
- ✅ Prefere JSONB em vez de HSTORE
- ✅ Quer customizar metadados capturados
- ✅ Precisa de portabilidade entre servidores

#### Use triggers manuais (Padrão 1) se:
- ✅ Precisa de **formato específico** de auditoria
- ✅ Quer controle total sobre o que é logado
- ✅ Precisa de **lógica de negócio** customizada
- ✅ Quer tabelas espelho (mesma estrutura)
- ✅ Precisa de **performance otimizada** para tabelas específicas

---

## 🎯 Capturando Metadados Adicionais

### IP do Cliente

```sql
-- Já implementado acima
inet_client_addr()  -- IP do cliente conectado

-- Exemplo de uso:
SELECT 
    usuario,
    ip_address,
    COUNT(*) AS mudancas
FROM audit_log
WHERE data_hora > NOW() - INTERVAL '24 hours'
GROUP BY usuario, ip_address
ORDER BY mudancas DESC;
```

### Application Name

```sql
-- Configurar na conexão (exemplo com psycopg2 - Python)
import psycopg2
conn = psycopg2.connect(
    host="localhost",
    database="mydb",
    user="app_user",
    password="senha",
    application_name="MyApp v1.0"
)

-- No trigger, capturar com:
current_setting('application_name', TRUE)
```

### Transaction ID

```sql
-- Adicionar coluna à audit_log
ALTER TABLE audit_log ADD COLUMN transaction_id BIGINT;

-- Capturar no trigger
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    -- ... (código anterior)
    
    INSERT INTO audit_log (
        -- ... (colunas anteriores)
        transaction_id
    ) VALUES (
        -- ... (valores anteriores)
        txid_current()  -- Transaction ID
    );
    
    -- ...
END;
$$ LANGUAGE plpgsql;

-- Uso: ver todas as mudanças de uma transação
SELECT * FROM audit_log WHERE transaction_id = 123456;
```

---

## 🔒 Proteger Tabelas de Auditoria

Garantir que registros de auditoria **nunca sejam alterados ou deletados**.

### 1. Revogar Permissões

```sql
-- Apenas INSERT e SELECT
REVOKE UPDATE, DELETE, TRUNCATE ON audit_log FROM PUBLIC;
GRANT INSERT, SELECT ON audit_log TO app_user;
```

### 2. Trigger de Proteção

```sql
-- Bloquear UPDATE e DELETE
CREATE OR REPLACE FUNCTION protect_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Registros de auditoria não podem ser alterados!';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER protect_audit_log_trigger
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION protect_audit_log();

-- Teste (deve falhar)
DELETE FROM audit_log WHERE id = 1;
-- ERROR:  Registros de auditoria não podem ser alterados!
```

### 3. Row-Level Security (RLS)

```sql
-- Habilitar RLS
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Permitir apenas INSERT e SELECT
CREATE POLICY audit_log_insert_policy ON audit_log
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY audit_log_select_policy ON audit_log
    FOR SELECT
    USING (true);

-- Nenhuma policy para UPDATE/DELETE = bloqueado implicitamente
```

---

## 🗂️ Particionamento de Tabelas de Auditoria

Para grandes volumes de dados, particionar por data.

```sql
-- Recriar audit_log como particionada
CREATE TABLE audit_log (
    id BIGSERIAL,
    tabela VARCHAR(50) NOT NULL,
    operacao CHAR(1) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    data_hora TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    dados_antigos JSONB,
    dados_novos JSONB,
    PRIMARY KEY (id, data_hora)
) PARTITION BY RANGE (data_hora);

-- Criar partições mensais
CREATE TABLE audit_log_2024_01 PARTITION OF audit_log
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE audit_log_2024_02 PARTITION OF audit_log
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE audit_log_2024_03 PARTITION OF audit_log
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

-- Automatizar criação de partições (extensão pg_partman)
CREATE EXTENSION pg_partman;

SELECT partman.create_parent(
    p_parent_table => 'audit_log',
    p_control => 'data_hora',
    p_type => 'native',
    p_interval => '1 month',
    p_premake => 3  -- Criar 3 partições futuras
);
```

---

## 🎓 Boas Práticas

### 1. Auditar Apenas o Necessário

```sql
-- ❌ MAU: Auditar tabelas de lookup/cache
CREATE TRIGGER cache_audit_trigger ...  -- Overhead desnecessário

-- ✅ BOM: Auditar apenas tabelas sensíveis
CREATE TRIGGER clientes_audit_trigger ...
CREATE TRIGGER pedidos_audit_trigger ...
CREATE TRIGGER pagamentos_audit_trigger ...
```

### 2. Usar JSONB para Flexibilidade

```sql
-- ✅ BOM: JSONB permite queries poderosas
SELECT * FROM audit_log WHERE dados_novos @> '{"ativo": false}';

-- Encontrar todas as mudanças onde email contém "@gmail"
SELECT * FROM audit_log WHERE dados_novos->>'email' LIKE '%@gmail.com%';
```

### 3. Retenção de Dados

```sql
-- Deletar auditoria antiga (exemplo: >2 anos)
-- (apenas se compliance permitir!)
DELETE FROM audit_log WHERE data_hora < NOW() - INTERVAL '2 years';

-- Ou arquivar em tabela separada
INSERT INTO audit_log_archive 
SELECT * FROM audit_log WHERE data_hora < NOW() - INTERVAL '1 year';

DELETE FROM audit_log WHERE data_hora < NOW() - INTERVAL '1 year';
```

---

## 📊 Exemplo Completo: Sistema de Auditoria

Veja o módulo **[11-Security/05-audit-compliance.md](../11-Security/05-audit-compliance.md)** para:
- pgAudit extension
- Compliance (LGPD, GDPR, PCI-DSS, SOX)
- Alertas automáticos
- Integração com sistemas de monitoramento

---

## 🔗 Navegação

⬅️ [Anterior: Logs do PostgreSQL](./03-logs-postgresql.md) | [Voltar ao Índice: History and Auditing](./README.md) | [Próximo: Temporal Tables →](./05-temporal-tables.md)

---

## 📝 Resumo Rápido

```sql
-- Tabela genérica de auditoria
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    tabela VARCHAR(50) NOT NULL,
    operacao CHAR(1) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    dados_antigos JSONB,
    dados_novos JSONB
);

-- Função genérica
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (tabela, operacao, usuario, dados_antigos, dados_novos)
    VALUES (
        TG_TABLE_NAME::VARCHAR, 
        LEFT(TG_OP, 1),
        current_user,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN row_to_json(OLD)::JSONB END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW)::JSONB END
    );
    
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a tabela
CREATE TRIGGER minha_tabela_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON minha_tabela
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Proteger audit table
CREATE TRIGGER protect_audit_trigger
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION protect_audit_log();
```
