# 16.5 - Temporal Tables e Versionamento

## 📋 O que você vai aprender

- Tabelas temporais (system-versioned tables)
- História de dados com history tables
- Consultas point-in-time (AS OF)
- Bi-temporal tables (valid time vs transaction time)
- Period types e ranges
- Slowly Changing Dimensions (SCD) tipos 1, 2, 3
- Implementação com triggers
- Particionamento de histórico
- Queries temporais avançadas

---

## 🎯 O que são Temporal Tables?

**Temporal Tables** (tabelas temporais) são tabelas que mantêm **histórico completo de mudanças**, permitindo consultar dados **como estavam em qualquer ponto no tempo**.

### Conceitos Fundamentais

```
┌─────────────────────────────────────────────────────┐
│              TABELA ATUAL (Current)                 │
│  ┌────┬──────┬───────┬────────────┬────────────┐  │
│  │ ID │ Nome │ Preço │ valid_from │ valid_to   │  │
│  ├────┼──────┼───────┼────────────┼────────────┤  │
│  │ 1  │ Prod │ 150   │ 2024-03-01 │ 9999-12-31 │  │ ← Versão atual
│  └────┴──────┴───────┴────────────┴────────────┘  │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│          TABELA DE HISTÓRICO (History)              │
│  ┌────┬──────┬───────┬────────────┬────────────┐  │
│  │ ID │ Nome │ Preço │ valid_from │ valid_to   │  │
│  ├────┼──────┼───────┼────────────┼────────────┤  │
│  │ 1  │ Prod │ 100   │ 2024-01-01 │ 2024-02-01 │  │ ← Versão antiga 1
│  │ 1  │ Prod │ 120   │ 2024-02-01 │ 2024-03-01 │  │ ← Versão antiga 2
│  └────┴──────┴───────┴────────────┴────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Casos de Uso

1. **Compliance**: LGPD, GDPR (histórico de dados pessoais)
2. **Auditoria**: Rastrear mudanças de preços, saldos, status
3. **Análise temporal**: Comparar dados entre períodos
4. **Rollback**: Restaurar dados de qualquer ponto no tempo
5. **Data Warehousing**: Slowly Changing Dimensions (SCD)

---

## 🕐 Tipos de Tempo

### 1. Transaction Time (System Time)

Quando a mudança foi **registrada no banco de dados**.

```sql
-- Controlado automaticamente pelo SGBD
transaction_time_start TIMESTAMPTZ DEFAULT NOW()
transaction_time_end TIMESTAMPTZ DEFAULT '9999-12-31'
```

### 2. Valid Time (Business Time)

Quando a mudança é **válida no mundo real**.

```sql
-- Controlado pela aplicação
valid_time_start DATE
valid_time_end DATE

-- Exemplo: Promoção válida de 01/12 a 31/12
```

### 3. Bi-Temporal Tables

Combinação de **ambos** os tempos.

| Tipo | Pergunta que responde |
|------|----------------------|
| Transaction Time | "Quando o banco soube dessa mudança?" |
| Valid Time | "Quando essa mudança é/era válida no negócio?" |
| Bi-Temporal | "O que o banco sabia sobre X em Y?" |

---

## 📊 Pattern 1: System-Versioned Table Simples

Implementação básica de tabela temporal com histórico.

### Estrutura

```sql
-- Tabela atual (current)
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco NUMERIC(10,2) NOT NULL,
    categoria VARCHAR(50),
    -- Colunas temporais
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_to TIMESTAMPTZ DEFAULT '9999-12-31 23:59:59'
);

-- Tabela de histórico
CREATE TABLE produtos_history (
    history_id BIGSERIAL PRIMARY KEY,
    id INTEGER NOT NULL,
    nome VARCHAR(100) NOT NULL,
    preco NUMERIC(10,2) NOT NULL,
    categoria VARCHAR(50),
    valid_from TIMESTAMPTZ NOT NULL,
    valid_to TIMESTAMPTZ NOT NULL,
    -- Metadados
    modified_by VARCHAR(50) DEFAULT current_user,
    modified_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para consultas temporais
CREATE INDEX idx_produtos_history_id ON produtos_history(id);
CREATE INDEX idx_produtos_history_valid_from ON produtos_history(valid_from);
CREATE INDEX idx_produtos_history_valid_to ON produtos_history(valid_to);
CREATE INDEX idx_produtos_history_id_period ON produtos_history(id, valid_from, valid_to);
```

### Trigger de Versionamento

```sql
CREATE OR REPLACE FUNCTION versioning_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- No UPDATE, mover versão antiga para history
    IF (TG_OP = 'UPDATE') THEN
        -- Fechar período da versão antiga
        INSERT INTO produtos_history (
            id, nome, preco, categoria,
            valid_from, valid_to,
            modified_by, modified_at
        ) VALUES (
            OLD.id, OLD.nome, OLD.preco, OLD.categoria,
            OLD.valid_from, NOW(),
            current_user, NOW()
        );
        
        -- Atualizar valid_from da nova versão
        NEW.valid_from = NOW();
        NEW.valid_to = '9999-12-31 23:59:59';
    END IF;
    
    -- No DELETE, mover para history e remover da tabela atual
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO produtos_history (
            id, nome, preco, categoria,
            valid_from, valid_to,
            modified_by, modified_at
        ) VALUES (
            OLD.id, OLD.nome, OLD.preco, OLD.categoria,
            OLD.valid_from, NOW(),
            current_user, NOW()
        );
        
        RETURN OLD;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER produtos_versioning_trigger
BEFORE UPDATE OR DELETE ON produtos
FOR EACH ROW EXECUTE FUNCTION versioning_trigger();
```

### Teste

```sql
-- Inserir produto
INSERT INTO produtos (nome, preco, categoria) 
VALUES ('Notebook', 3000.00, 'Informática');

-- Atualizar preço (1ª mudança)
UPDATE produtos SET preco = 2800.00 WHERE id = 1;

-- Atualizar preço (2ª mudança)
UPDATE produtos SET preco = 2500.00 WHERE id = 1;

-- Ver versão atual
SELECT * FROM produtos WHERE id = 1;
/*
 id |   nome   | preco  | categoria   | valid_from          | valid_to
----+----------+--------+-------------+---------------------+------------
  1 | Notebook | 2500.00| Informática | 2024-12-02 14:30:00 | 9999-12-31
*/

-- Ver histórico completo
SELECT 
    id, nome, preco, valid_from, valid_to, modified_by
FROM produtos_history 
WHERE id = 1
ORDER BY valid_from;
/*
 id |   nome   | preco   | valid_from          | valid_to            | modified_by
----+----------+---------+---------------------+---------------------+-------------
  1 | Notebook | 3000.00 | 2024-12-02 14:00:00 | 2024-12-02 14:15:00 | app_user
  1 | Notebook | 2800.00 | 2024-12-02 14:15:00 | 2024-12-02 14:30:00 | app_user
*/
```

---

## 🔍 Queries Temporais (AS OF, BETWEEN)

### AS OF - Point-in-Time Query

Consultar dados **como estavam em um momento específico**.

```sql
-- View helper para queries AS OF
CREATE OR REPLACE FUNCTION produtos_as_of(p_timestamp TIMESTAMPTZ)
RETURNS TABLE (
    id INTEGER,
    nome VARCHAR(100),
    preco NUMERIC(10,2),
    categoria VARCHAR(50),
    valid_from TIMESTAMPTZ,
    valid_to TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    -- Versão atual (se ainda válida no timestamp solicitado)
    SELECT p.id, p.nome, p.preco, p.categoria, p.valid_from, p.valid_to
    FROM produtos p
    WHERE p.valid_from <= p_timestamp 
      AND p.valid_to > p_timestamp
    
    UNION ALL
    
    -- Versões históricas
    SELECT h.id, h.nome, h.preco, h.categoria, h.valid_from, h.valid_to
    FROM produtos_history h
    WHERE h.valid_from <= p_timestamp 
      AND h.valid_to > p_timestamp;
END;
$$ LANGUAGE plpgsql;

-- Usar AS OF
SELECT * FROM produtos_as_of('2024-12-02 14:10:00');  -- Preço era 3000.00
SELECT * FROM produtos_as_of('2024-12-02 14:20:00');  -- Preço era 2800.00
SELECT * FROM produtos_as_of('2024-12-02 14:40:00');  -- Preço é 2500.00
```

### BETWEEN - Range Query

Consultar todas as versões **dentro de um período**.

```sql
CREATE OR REPLACE FUNCTION produtos_between(
    p_start TIMESTAMPTZ,
    p_end TIMESTAMPTZ
)
RETURNS TABLE (
    id INTEGER,
    nome VARCHAR(100),
    preco NUMERIC(10,2),
    valid_from TIMESTAMPTZ,
    valid_to TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.nome, p.preco, p.valid_from, p.valid_to
    FROM produtos p
    WHERE p.valid_from < p_end 
      AND p.valid_to > p_start
    
    UNION ALL
    
    SELECT h.id, h.nome, h.preco, h.valid_from, h.valid_to
    FROM produtos_history h
    WHERE h.valid_from < p_end 
      AND h.valid_to > p_start
    
    ORDER BY valid_from;
END;
$$ LANGUAGE plpgsql;

-- Ver todas as mudanças no mês de dezembro
SELECT * FROM produtos_between('2024-12-01', '2024-12-31');
```

### ALL VERSIONS - Histórico Completo

```sql
CREATE VIEW produtos_all_versions AS
SELECT 
    id, nome, preco, categoria,
    valid_from, valid_to,
    'CURRENT' AS version_type,
    NULL::VARCHAR AS modified_by
FROM produtos

UNION ALL

SELECT 
    id, nome, preco, categoria,
    valid_from, valid_to,
    'HISTORY' AS version_type,
    modified_by
FROM produtos_history

ORDER BY id, valid_from;

-- Usar
SELECT * FROM produtos_all_versions WHERE id = 1;
```

---

## 📅 Bi-Temporal Tables

Rastrear **transaction time** (quando foi registrado) E **valid time** (quando é válido no negócio).

### Implementação

```sql
CREATE TABLE contratos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL,
    valor NUMERIC(10,2) NOT NULL,
    status VARCHAR(20),
    -- Valid Time (Business Time)
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL DEFAULT '9999-12-31',
    -- Transaction Time (System Time)
    transaction_from TIMESTAMPTZ DEFAULT NOW(),
    transaction_to TIMESTAMPTZ DEFAULT '9999-12-31 23:59:59',
    -- Constraint
    CHECK (valid_from < valid_to),
    CHECK (transaction_from < transaction_to)
);

CREATE TABLE contratos_history (
    history_id BIGSERIAL PRIMARY KEY,
    id INTEGER NOT NULL,
    cliente_id INTEGER NOT NULL,
    valor NUMERIC(10,2) NOT NULL,
    status VARCHAR(20),
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    transaction_from TIMESTAMPTZ NOT NULL,
    transaction_to TIMESTAMPTZ NOT NULL,
    modified_by VARCHAR(50) DEFAULT current_user
);

CREATE INDEX idx_contratos_history_id ON contratos_history(id);
CREATE INDEX idx_contratos_history_valid ON contratos_history(valid_from, valid_to);
CREATE INDEX idx_contratos_history_transaction ON contratos_history(transaction_from, transaction_to);
```

### Trigger Bi-Temporal

```sql
CREATE OR REPLACE FUNCTION bitemporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        -- Arquivar versão antiga
        INSERT INTO contratos_history (
            id, cliente_id, valor, status,
            valid_from, valid_to,
            transaction_from, transaction_to,
            modified_by
        ) VALUES (
            OLD.id, OLD.cliente_id, OLD.valor, OLD.status,
            OLD.valid_from, OLD.valid_to,
            OLD.transaction_from, NOW(),  -- Fechar transaction time
            current_user
        );
        
        -- Atualizar transaction time da nova versão
        NEW.transaction_from = NOW();
        NEW.transaction_to = '9999-12-31 23:59:59';
    END IF;
    
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO contratos_history (
            id, cliente_id, valor, status,
            valid_from, valid_to,
            transaction_from, transaction_to,
            modified_by
        ) VALUES (
            OLD.id, OLD.cliente_id, OLD.valor, OLD.status,
            OLD.valid_from, OLD.valid_to,
            OLD.transaction_from, NOW(),
            current_user
        );
        RETURN OLD;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contratos_bitemporal_trigger
BEFORE UPDATE OR DELETE ON contratos
FOR EACH ROW EXECUTE FUNCTION bitemporal_trigger();
```

### Queries Bi-Temporais

```sql
-- Inserir contrato com valid time futuro
INSERT INTO contratos (cliente_id, valor, status, valid_from, valid_to)
VALUES (100, 5000.00, 'ativo', '2025-01-01', '2025-12-31');
-- Registrado hoje (transaction_from = NOW()), mas válido a partir de 2025-01-01

-- Query 1: "O que está válido HOJE no negócio?"
SELECT * FROM contratos 
WHERE valid_from <= CURRENT_DATE 
  AND valid_to > CURRENT_DATE;

-- Query 2: "O que o banco sabia em 2024-11-01 sobre contratos válidos em 2025-06-01?"
SELECT * FROM contratos_history
WHERE transaction_from <= '2024-11-01'
  AND transaction_to > '2024-11-01'
  AND valid_from <= '2025-06-01'
  AND valid_to > '2025-06-01';

-- Query 3: "Qual era o valor do contrato 1 em 2024-06-01 (valid time)?"
SELECT valor 
FROM contratos
WHERE id = 1
  AND valid_from <= '2024-06-01'
  AND valid_to > '2024-06-01'
  
UNION ALL

SELECT valor 
FROM contratos_history
WHERE id = 1
  AND valid_from <= '2024-06-01'
  AND valid_to > '2024-06-01'
LIMIT 1;
```

---

## 🏢 Slowly Changing Dimensions (SCD)

Padrões de **Data Warehousing** para rastrear mudanças em dimensões.

### Comparação de Tipos

| Tipo | Histórico? | Complexidade | Uso |
|------|------------|--------------|-----|
| **SCD Type 1** | ❌ Não | Baixa | Correções, dados irrelevantes |
| **SCD Type 2** | ✅ Sim | Média | Rastrear mudanças completas |
| **SCD Type 3** | ⚠️ Parcial | Média | Rastrear apenas mudança anterior |

### SCD Type 1: Overwrite (Sem Histórico)

Simplesmente **sobrescreve** o valor antigo. Sem histórico.

```sql
CREATE TABLE clientes_scd1 (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100),
    cidade VARCHAR(50)
);

-- Mudança de cidade (perde histórico)
UPDATE clientes_scd1 SET cidade = 'Rio de Janeiro' WHERE id = 1;

-- ❌ Não é possível saber que o cliente morava em São Paulo antes
```

**Uso**: Correção de erros, dados que não precisam de histórico (ex: telefone atualizado).

### SCD Type 2: Add Row (Histórico Completo)

Adiciona **nova linha** para cada mudança. **Mais usado**.

```sql
CREATE TABLE clientes_scd2 (
    surrogate_key BIGSERIAL PRIMARY KEY,  -- Chave artificial
    cliente_id INTEGER NOT NULL,           -- Natural key (id do negócio)
    nome VARCHAR(100),
    email VARCHAR(100),
    cidade VARCHAR(50),
    -- Temporal columns
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_to TIMESTAMPTZ DEFAULT '9999-12-31 23:59:59',
    is_current BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_clientes_scd2_natural_key ON clientes_scd2(cliente_id, is_current);
```

#### Trigger SCD Type 2

```sql
CREATE OR REPLACE FUNCTION scd2_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        -- Fechar versão antiga
        UPDATE clientes_scd2
        SET valid_to = NOW(),
            is_current = FALSE
        WHERE cliente_id = OLD.cliente_id
          AND is_current = TRUE;
        
        -- Inserir nova versão
        INSERT INTO clientes_scd2 (
            cliente_id, nome, email, cidade,
            valid_from, valid_to, is_current
        ) VALUES (
            NEW.cliente_id, NEW.nome, NEW.email, NEW.cidade,
            NOW(), '9999-12-31 23:59:59', TRUE
        );
        
        -- Retornar OLD para cancelar o UPDATE original
        RETURN NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clientes_scd2_trigger
BEFORE UPDATE ON clientes_scd2
FOR EACH ROW 
WHEN (OLD.is_current = TRUE)
EXECUTE FUNCTION scd2_trigger();
```

#### Teste SCD Type 2

```sql
-- Inserir cliente
INSERT INTO clientes_scd2 (cliente_id, nome, email, cidade)
VALUES (1, 'Maria Silva', 'maria@email.com', 'São Paulo');

-- Atualizar cidade (trigger cria nova versão)
UPDATE clientes_scd2 
SET cidade = 'Rio de Janeiro'
WHERE cliente_id = 1 AND is_current = TRUE;

-- Ver histórico completo
SELECT 
    surrogate_key, cliente_id, nome, cidade,
    valid_from, valid_to, is_current
FROM clientes_scd2 
WHERE cliente_id = 1
ORDER BY valid_from;

/*
 surrogate_key | cliente_id | nome        | cidade          | valid_from          | valid_to            | is_current
---------------+------------+-------------+-----------------+---------------------+---------------------+------------
             1 |          1 | Maria Silva | São Paulo       | 2024-12-02 10:00:00 | 2024-12-02 11:00:00 | f
             2 |          1 | Maria Silva | Rio de Janeiro  | 2024-12-02 11:00:00 | 9999-12-31 23:59:59 | t
*/

-- Ver apenas versão atual
SELECT * FROM clientes_scd2 WHERE is_current = TRUE;
```

### SCD Type 3: Add Column (Mudança Anterior)

Mantém **apenas o valor anterior** em colunas adicionais.

```sql
CREATE TABLE clientes_scd3 (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100),
    cidade_atual VARCHAR(50),
    cidade_anterior VARCHAR(50),
    data_mudanca_cidade TIMESTAMPTZ
);

-- Trigger para SCD Type 3
CREATE OR REPLACE FUNCTION scd3_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND OLD.cidade_atual != NEW.cidade_atual) THEN
        NEW.cidade_anterior = OLD.cidade_atual;
        NEW.data_mudanca_cidade = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clientes_scd3_trigger
BEFORE UPDATE ON clientes_scd3
FOR EACH ROW EXECUTE FUNCTION scd3_trigger();

-- Teste
INSERT INTO clientes_scd3 (nome, email, cidade_atual)
VALUES ('João', 'joao@email.com', 'São Paulo');

UPDATE clientes_scd3 SET cidade_atual = 'Curitiba' WHERE id = 1;

SELECT * FROM clientes_scd3 WHERE id = 1;
/*
 id | nome | email           | cidade_atual | cidade_anterior | data_mudanca_cidade
----+------+-----------------+--------------+-----------------+---------------------
  1 | João | joao@email.com  | Curitiba     | São Paulo       | 2024-12-02 11:00:00
*/
```

**Uso**: Quando você precisa apenas da **última mudança** (ex: "cidade anterior", "salário anterior").

---

## 🔧 Period Types com Range Types

PostgreSQL oferece **range types** nativos para trabalhar com períodos.

```sql
-- Usar tstzrange (timestamp with time zone range)
CREATE TABLE reservas (
    id SERIAL PRIMARY KEY,
    sala_id INTEGER NOT NULL,
    cliente VARCHAR(100),
    periodo TSTZRANGE NOT NULL,  -- Range type
    -- Constraint: períodos não podem sobrepor
    EXCLUDE USING GIST (sala_id WITH =, periodo WITH &&)
);

-- Inserir reservas
INSERT INTO reservas (sala_id, cliente, periodo) VALUES
(1, 'Cliente A', '[2024-12-10 09:00, 2024-12-10 11:00)'),
(1, 'Cliente B', '[2024-12-10 14:00, 2024-12-10 16:00)');

-- ✅ OK: Não há conflito

-- Tentar inserir reserva que sobrepõe
INSERT INTO reservas (sala_id, cliente, periodo) VALUES
(1, 'Cliente C', '[2024-12-10 10:00, 2024-12-10 12:00)');
-- ❌ ERROR: conflicting key value violates exclusion constraint

-- Queries com range operators
-- Verificar se sala está livre em um período
SELECT * FROM reservas
WHERE sala_id = 1
  AND periodo && '[2024-12-10 13:00, 2024-12-10 15:00)'::TSTZRANGE;

-- Reservas ativas AGORA
SELECT * FROM reservas
WHERE periodo @> NOW();

-- Duração da reserva
SELECT 
    id, cliente,
    EXTRACT(EPOCH FROM (upper(periodo) - lower(periodo))) / 3600 AS horas
FROM reservas;
```

### Operators de Range

| Operator | Descrição | Exemplo |
|----------|-----------|---------|
| `&&` | Overlap (sobreposição) | `'[1,5)' && '[3,7)'` → true |
| `@>` | Contains | `'[1,10)' @> 5` → true |
| `<@` | Is contained by | `5 <@ '[1,10)'` → true |
| `<<` | Strictly left of | `'[1,5)' << '[6,10)'` → true |
| `>>` | Strictly right of | `'[6,10)' >> '[1,5)'` → true |
| `-|-` | Adjacent | `'[1,5)' -|- '[5,10)'` → true |

---

## 🗂️ Particionamento de History Tables

Para grandes volumes, particionar tabela de histórico por **valid_to** (data de término).

```sql
-- Recriar produtos_history como particionada
CREATE TABLE produtos_history (
    history_id BIGSERIAL,
    id INTEGER NOT NULL,
    nome VARCHAR(100) NOT NULL,
    preco NUMERIC(10,2) NOT NULL,
    categoria VARCHAR(50),
    valid_from TIMESTAMPTZ NOT NULL,
    valid_to TIMESTAMPTZ NOT NULL,
    modified_by VARCHAR(50),
    modified_at TIMESTAMPTZ,
    PRIMARY KEY (history_id, valid_to)
) PARTITION BY RANGE (valid_to);

-- Criar partições por ano
CREATE TABLE produtos_history_2023 PARTITION OF produtos_history
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE produtos_history_2024 PARTITION OF produtos_history
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE produtos_history_2025 PARTITION OF produtos_history
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Partição para registros "ativos" (valid_to futuro)
CREATE TABLE produtos_history_future PARTITION OF produtos_history
    FOR VALUES FROM ('2026-01-01') TO ('9999-12-31');

-- Índices em cada partição são criados automaticamente
CREATE INDEX idx_produtos_history_id ON produtos_history(id);
CREATE INDEX idx_produtos_history_valid_from ON produtos_history(valid_from);
```

### Automatizar Criação de Partições

```sql
-- Usando pg_partman
CREATE EXTENSION pg_partman;

SELECT partman.create_parent(
    p_parent_table => 'public.produtos_history',
    p_control => 'valid_to',
    p_type => 'native',
    p_interval => '1 year',
    p_premake => 2,  -- Criar 2 anos de partições futuras
    p_start_partition => '2024-01-01'
);

-- Configurar manutenção automática
UPDATE partman.part_config 
SET retention_keep_table = FALSE,
    retention = '7 years'  -- Deletar partições com mais de 7 anos
WHERE parent_table = 'public.produtos_history';
```

---

## 🎯 Boas Práticas

### 1. Escolher o Padrão Certo

```sql
-- ✅ SCD Type 1: Correções
UPDATE clientes SET email = 'correto@email.com' WHERE id = 1;

-- ✅ SCD Type 2: Mudanças que precisam de histórico
-- (preços, endereços, status)

-- ✅ SCD Type 3: Apenas mudança anterior
-- (cargo anterior, departamento anterior)
```

### 2. Índices para Performance

```sql
-- ✅ Índice composto para queries temporais
CREATE INDEX idx_history_id_period 
ON produtos_history(id, valid_from, valid_to);

-- ✅ Índice para queries "current"
CREATE INDEX idx_history_current 
ON produtos_history(id) 
WHERE valid_to = '9999-12-31 23:59:59';

-- ✅ BRIN para tabelas grandes ordenadas por tempo
CREATE INDEX idx_history_brin 
ON produtos_history USING BRIN(valid_to);
```

### 3. Views para Simplificar Queries

```sql
-- View para sempre retornar versão atual
CREATE VIEW produtos_current AS
SELECT id, nome, preco, categoria
FROM produtos
WHERE valid_to = '9999-12-31 23:59:59';

-- View para histórico completo
CREATE VIEW produtos_all AS
SELECT * FROM produtos
UNION ALL
SELECT * FROM produtos_history;

-- Usar
SELECT * FROM produtos_current;
SELECT * FROM produtos_all WHERE id = 1 ORDER BY valid_from;
```

### 4. Constraints de Integridade

```sql
-- ✅ Garantir que períodos sejam válidos
ALTER TABLE produtos ADD CONSTRAINT check_period 
    CHECK (valid_from < valid_to);

-- ✅ Garantir que não haja gaps/overlaps
CREATE EXTENSION btree_gist;

ALTER TABLE produtos ADD CONSTRAINT no_overlap
    EXCLUDE USING GIST (id WITH =, tstzrange(valid_from, valid_to) WITH &&);
```

### 5. Retenção de Dados

```sql
-- Política de retenção: manter apenas últimos 5 anos
-- (executar periodicamente via cron/pg_cron)
DELETE FROM produtos_history 
WHERE valid_to < NOW() - INTERVAL '5 years';

-- Ou arquivar em tabela separada
INSERT INTO produtos_history_archive
SELECT * FROM produtos_history
WHERE valid_to < NOW() - INTERVAL '5 years';

DELETE FROM produtos_history 
WHERE valid_to < NOW() - INTERVAL '5 years';
```

---

## 📊 Exemplo Completo: Sistema de Preços

```sql
-- 1. Criar tabelas
CREATE TABLE precos (
    id SERIAL PRIMARY KEY,
    produto_id INTEGER NOT NULL,
    preco NUMERIC(10,2) NOT NULL,
    moeda CHAR(3) DEFAULT 'BRL',
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_to TIMESTAMPTZ DEFAULT '9999-12-31 23:59:59',
    CONSTRAINT check_periodo CHECK (valid_from < valid_to)
);

CREATE TABLE precos_history (
    history_id BIGSERIAL PRIMARY KEY,
    id INTEGER NOT NULL,
    produto_id INTEGER NOT NULL,
    preco NUMERIC(10,2) NOT NULL,
    moeda CHAR(3),
    valid_from TIMESTAMPTZ NOT NULL,
    valid_to TIMESTAMPTZ NOT NULL,
    modified_by VARCHAR(50),
    modified_at TIMESTAMPTZ
);

-- 2. Trigger de versionamento
CREATE OR REPLACE FUNCTION versioning_precos()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO precos_history 
        SELECT id, produto_id, preco, moeda, valid_from, NOW(), current_user, NOW()
        FROM precos 
        WHERE id = OLD.id;
        
        NEW.valid_from = NOW();
        NEW.valid_to = '9999-12-31 23:59:59';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER precos_versioning
BEFORE UPDATE ON precos
FOR EACH ROW EXECUTE FUNCTION versioning_precos();

-- 3. Function para consulta AS OF
CREATE OR REPLACE FUNCTION preco_em(p_produto_id INTEGER, p_data TIMESTAMPTZ)
RETURNS NUMERIC AS $$
DECLARE
    v_preco NUMERIC;
BEGIN
    SELECT preco INTO v_preco
    FROM precos
    WHERE produto_id = p_produto_id
      AND valid_from <= p_data
      AND valid_to > p_data
    UNION ALL
    SELECT preco
    FROM precos_history
    WHERE produto_id = p_produto_id
      AND valid_from <= p_data
      AND valid_to > p_data
    LIMIT 1;
    
    RETURN v_preco;
END;
$$ LANGUAGE plpgsql;

-- 4. View de histórico completo
CREATE VIEW precos_timeline AS
SELECT 
    produto_id,
    preco,
    valid_from,
    valid_to,
    EXTRACT(DAYS FROM (valid_to - valid_from)) AS dias_vigencia,
    'CURRENT' AS status
FROM precos
UNION ALL
SELECT 
    produto_id,
    preco,
    valid_from,
    valid_to,
    EXTRACT(DAYS FROM (valid_to - valid_from)) AS dias_vigencia,
    'HISTORY' AS status
FROM precos_history
ORDER BY produto_id, valid_from;

-- 5. Testes
INSERT INTO precos (produto_id, preco) VALUES (100, 50.00);
UPDATE precos SET preco = 55.00 WHERE produto_id = 100;
UPDATE precos SET preco = 48.00 WHERE produto_id = 100;

-- Ver timeline completa
SELECT * FROM precos_timeline WHERE produto_id = 100;

-- Preço em uma data específica
SELECT preco_em(100, '2024-12-02 10:00:00');

-- Variação de preço
SELECT 
    produto_id,
    MIN(preco) AS preco_minimo,
    MAX(preco) AS preco_maximo,
    AVG(preco) AS preco_medio,
    COUNT(*) AS num_mudancas
FROM precos_timeline
WHERE produto_id = 100
GROUP BY produto_id;
```

---

## 🔗 Navegação

⬅️ [Anterior: Audit Triggers](./04-audit-triggers.md) | [Voltar ao Índice: History and Auditing](./README.md) | [Próximo: MVCC →](./06-mvcc.md)

---

## 📝 Resumo Rápido

```sql
-- ========================================
-- 1. TEMPORAL TABLE BÁSICA
-- ========================================
CREATE TABLE mytable (
    id SERIAL PRIMARY KEY,
    data VARCHAR(100),
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_to TIMESTAMPTZ DEFAULT '9999-12-31'
);

CREATE TABLE mytable_history (
    history_id BIGSERIAL PRIMARY KEY,
    id INTEGER,
    data VARCHAR(100),
    valid_from TIMESTAMPTZ,
    valid_to TIMESTAMPTZ
);

-- Trigger de versionamento
CREATE OR REPLACE FUNCTION versioning_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO mytable_history 
        SELECT id, data, valid_from, NOW() FROM mytable WHERE id = OLD.id;
        NEW.valid_from = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER mytable_versioning
BEFORE UPDATE ON mytable
FOR EACH ROW EXECUTE FUNCTION versioning_trigger();

-- ========================================
-- 2. SCD TYPE 2 (Mais comum)
-- ========================================
CREATE TABLE dim_cliente (
    surrogate_key BIGSERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL,
    nome VARCHAR(100),
    cidade VARCHAR(50),
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_to TIMESTAMPTZ DEFAULT '9999-12-31',
    is_current BOOLEAN DEFAULT TRUE
);

-- ========================================
-- 3. QUERIES TEMPORAIS
-- ========================================

-- AS OF (point-in-time)
SELECT * FROM mytable 
WHERE valid_from <= '2024-01-15' AND valid_to > '2024-01-15'
UNION ALL
SELECT * FROM mytable_history
WHERE valid_from <= '2024-01-15' AND valid_to > '2024-01-15';

-- BETWEEN (range)
SELECT * FROM mytable
WHERE valid_from < '2024-12-31' AND valid_to > '2024-01-01'
UNION ALL
SELECT * FROM mytable_history
WHERE valid_from < '2024-12-31' AND valid_to > '2024-01-01';

-- ========================================
-- 4. RANGE TYPES
-- ========================================
CREATE TABLE eventos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    periodo TSTZRANGE,
    EXCLUDE USING GIST (periodo WITH &&)  -- Não permitir overlap
);

-- Queries
SELECT * FROM eventos WHERE periodo @> NOW();  -- Ativos agora
SELECT * FROM eventos WHERE periodo && '[2024-12-01, 2024-12-31)'::TSTZRANGE;
```
