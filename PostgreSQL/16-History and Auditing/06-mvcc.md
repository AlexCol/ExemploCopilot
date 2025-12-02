# 16.6 - MVCC: Versionamento Interno do PostgreSQL

## 📋 O que você vai aprender

- O que é Multi-Version Concurrency Control (MVCC)
- Transaction IDs (xmin, xmax)
- Snapshots e visibility de tuplas
- Dead tuples e VACUUM
- pg_visibility extension
- Impacto no performance

---

## 🎯 O que é MVCC?

**MVCC (Multi-Version Concurrency Control)** é o mecanismo interno do PostgreSQL que permite:
- **Leituras nunca bloqueiam escritas**
- **Escritas nunca bloqueiam leituras**
- **Isolamento de transações** sem locks pesados

### Como Funciona?

Ao invés de **sobrescrever** dados, o PostgreSQL:
1. **Cria uma nova versão** da tupla (row)
2. **Marca a versão antiga** como "morta" para novas transações
3. **Cada transação vê sua própria snapshot** consistente do banco

---

## 🔢 Transaction IDs

Cada transação recebe um **Transaction ID (XID)** único e sequencial.

### Colunas Ocultas: xmin e xmax

Cada tupla tem colunas ocultas que controlam visibilidade:

```sql
-- Ver colunas ocultas
SELECT 
    xmin,      -- Transaction ID que CRIOU esta tupla
    xmax,      -- Transaction ID que DELETOU/ATUALIZOU esta tupla (0 = ainda válida)
    cmin,      -- Command ID dentro da transação
    cmax,      -- Command ID da deleção/update
    ctid,      -- Physical location (página, offset)
    *
FROM clientes;

/*
 xmin | xmax | cmin | cmax | ctid  | id | nome | email
------+------+------+------+-------+----+------+------------------
  100 |    0 |    0 |    0 | (0,1) |  1 | João | joao@example.com
  100 |    0 |    0 |    0 | (0,2) |  2 | Maria| maria@example.com
  105 |    0 |    0 |    0 | (0,3) |  3 | Pedro| pedro@example.com
*/
```

### Significado dos Valores

```sql
-- xmin = 100, xmax = 0
-- → Tupla criada pela transação 100
-- → Ainda válida (nenhuma transação a deletou)

-- xmin = 100, xmax = 105
-- → Tupla criada pela transação 100
-- → Deletada/atualizada pela transação 105
-- → Visível para transações < 105
-- → Invisível para transações >= 105
```

---

## 📸 Snapshots e Visibilidade

Cada transação vê uma **snapshot** consistente do banco.

### Exemplo: Isolamento de Transações

```sql
-- Estado inicial
CREATE TABLE contas (id INT, saldo NUMERIC);
INSERT INTO contas VALUES (1, 1000);

-- Sessão 1
BEGIN;
SELECT xmin, xmax, * FROM contas WHERE id = 1;
/*
 xmin | xmax | id | saldo
------+------+----+-------
  100 |    0 |  1 |  1000
*/

-- Sessão 2 (simultaneamente)
BEGIN;
UPDATE contas SET saldo = 1500 WHERE id = 1;
-- Cria NOVA versão da tupla, não sobrescreve!

-- Sessão 1 (ainda na transação original)
SELECT xmin, xmax, * FROM contas WHERE id = 1;
/*
 xmin | xmax | id | saldo
------+------+----+-------
  100 |    0 |  1 |  1000   ← Ainda vê versão antiga!
*/

-- Sessão 2
COMMIT;  -- Agora a nova versão é visível para novas transações

-- Sessão 1
SELECT xmin, xmax, * FROM contas WHERE id = 1;
/*
 xmin | xmax | id | saldo
------+------+----+-------
  100 |    0 |  1 |  1000   ← AINDA vê versão antiga (snapshot isolada)!
*/

-- Sessão 1
COMMIT;

-- Sessão 1 (nova transação)
BEGIN;
SELECT xmin, xmax, * FROM contas WHERE id = 1;
/*
 xmin | xmax | id | saldo
------+------+----+-------
  110 |    0 |  1 |  1500   ← Agora vê nova versão!
*/

-- Onde está a versão antiga?
SELECT xmin, xmax, ctid, * FROM contas WHERE id = 1;
/*
 xmin | xmax | ctid  | id | saldo
------+------+-------+----+-------
  110 |    0 | (0,2) |  1 |  1500   ← Nova versão (ctid mudou!)
  
-- A versão antiga (ctid (0,1)) ainda existe fisicamente, mas está "morta"
*/
```

### Regras de Visibilidade

Uma tupla é visível para uma transação se:

```
1. xmin < snapshot_xid  (tupla foi criada antes desta transação)
2. xmin committed       (transação criadora foi committed)
3. xmax == 0 OR         (tupla não foi deletada)
   xmax > snapshot_xid OR  (deletada após esta transação)
   xmax aborted        (deleção foi aborted)
```

---

## ⚰️ Dead Tuples (Tuplas Mortas)

**Dead tuples** são versões antigas de tuplas que não são mais visíveis para **nenhuma transação ativa**.

### Exemplo: Gerando Dead Tuples

```sql
-- Estado inicial
CREATE TABLE produtos (id INT, preco NUMERIC);
INSERT INTO produtos VALUES (1, 100);

SELECT xmin, xmax, ctid, * FROM produtos;
/*
 xmin | xmax | ctid  | id | preco
------+------+-------+----+-------
  100 |    0 | (0,1) |  1 |   100
*/

-- Update 1
UPDATE produtos SET preco = 150 WHERE id = 1;

SELECT xmin, xmax, ctid, * FROM produtos;
/*
 xmin | xmax | ctid  | id | preco
------+------+-------+----+-------
  101 |    0 | (0,2) |  1 |   150
  
-- Tupla antiga (ctid 0,1) agora é DEAD TUPLE
-- (xmin=100, xmax=101, não visível para ninguém)
*/

-- Update 2
UPDATE produtos SET preco = 200 WHERE id = 1;

SELECT xmin, xmax, ctid, * FROM produtos;
/*
 xmin | xmax | ctid  | id | preco
------+------+-------+----+-------
  102 |    0 | (0,3) |  1 |   200
  
-- Tuplas antigas (ctid 0,1 e 0,2) são DEAD TUPLES
*/

-- Ver estatísticas de dead tuples
SELECT 
    schemaname,
    relname,
    n_live_tup,    -- Tuplas vivas
    n_dead_tup,    -- Tuplas mortas
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'produtos';

/*
 schemaname | relname  | n_live_tup | n_dead_tup | last_vacuum | last_autovacuum
------------+----------+------------+------------+-------------+-----------------
 public     | produtos |          1 |          2 |             | 
*/
```

---

## 🧹 VACUUM: Limpeza de Dead Tuples

**VACUUM** remove dead tuples e libera espaço.

### VACUUM Manual

```sql
-- VACUUM básico (não bloqueia queries)
VACUUM produtos;

-- VACUUM VERBOSE (mostra estatísticas)
VACUUM VERBOSE produtos;
/*
INFO:  vacuuming "public.produtos"
INFO:  "produtos": found 2 removable, 1 nonremovable row versions in 1 pages
DETAIL:  0 dead row versions cannot be removed yet.
*/

-- VACUUM FULL (bloqueia tabela, reescreve inteira, libera espaço ao SO)
VACUUM FULL produtos;
```

### Autovacuum

PostgreSQL executa VACUUM automaticamente.

```sql
-- Ver configuração de autovacuum
SHOW autovacuum;  -- on

-- Parâmetros de autovacuum
SHOW autovacuum_vacuum_threshold;        -- 50 (dead tuples mínimas)
SHOW autovacuum_vacuum_scale_factor;     -- 0.2 (20% de dead tuples)

-- Autovacuum roda quando:
-- dead_tuples > threshold + (scale_factor * total_tuples)
-- Exemplo: tabela com 1000 tuplas → autovacuum roda em 50 + (0.2 * 1000) = 250 dead tuples
```

### Monitorar Autovacuum

```sql
-- Ver quando autovacuum rodou
SELECT 
    schemaname,
    relname,
    last_vacuum,
    last_autovacuum,
    n_dead_tup
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- Ver autovacuum em execução
SELECT 
    pid,
    age(clock_timestamp(), query_start) AS duration,
    query
FROM pg_stat_activity
WHERE query LIKE '%autovacuum%'
  AND query NOT LIKE '%pg_stat_activity%';
```

---

## 🔍 Analisando MVCC com pg_visibility

### Instalar Extensão

```sql
CREATE EXTENSION pg_visibility;
```

### Ver Dead Tuples por Página

```sql
-- Ver estatísticas de visibility por página
SELECT * FROM pg_visibility_map('produtos');
/*
 blkno | all_visible | all_frozen
-------+-------------+------------
     0 | f           | f
     1 | t           | t
*/

-- Ver tuplas mortas em páginas específicas
SELECT * FROM pg_check_visible('produtos');
/*
 tid   | all_visible
-------+-------------
 (0,1) | f           ← Dead tuple
 (0,2) | f           ← Dead tuple
 (0,3) | t           ← Live tuple
*/
```

---

## 🎯 Transaction ID Wraparound

XIDs são inteiros de 32 bits (0 a ~4 bilhões). Após ~4 bilhões de transações, ocorre **wraparound**.

### Problema

```sql
-- Transação 1000 cria tupla
-- xmin = 1000

-- Após wraparound, transação 1000 (nova) vê tupla com xmin=1000
-- MVCC pensa que tupla foi criada "no futuro" → INVISÍVEL!
-- PERDA DE DADOS!
```

### Solução: FREEZE

```sql
-- VACUUM FREEZE marca tuplas antigas como "sempre visíveis"
VACUUM FREEZE produtos;

-- Após freeze:
SELECT xmin, xmax, * FROM produtos;
/*
 xmin | xmax | id | preco
------+------+----+-------
    2 |    0 |  1 |   200   ← xmin = 2 (FrozenTransactionId)
*/
```

### Monitorar Transaction Age

```sql
-- Ver idade (em transações) de cada database
SELECT 
    datname,
    age(datfrozenxid) AS xid_age,
    2147483647 - age(datfrozenxid) AS xids_remaining
FROM pg_database
ORDER BY xid_age DESC;

/*
 datname | xid_age | xids_remaining
---------+---------+----------------
 mydb    |  500000 |     2147483147
 testdb  |   10000 |     2147483637
 
-- Se xid_age > 2 bilhões → PERIGO (autovacuum freeze forçado)
*/

-- Ver tabelas com maior idade
SELECT 
    schemaname,
    relname,
    age(relfrozenxid) AS xid_age
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
ORDER BY xid_age DESC;
```

---

## 📊 Impacto no Performance

### Bloat (Inchaço da Tabela)

```sql
-- Ver tamanho da tabela
SELECT 
    pg_size_pretty(pg_table_size('produtos')) AS table_size,
    pg_size_pretty(pg_indexes_size('produtos')) AS indexes_size,
    pg_size_pretty(pg_total_relation_size('produtos')) AS total_size;

-- Detectar bloat
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_dead_tup,
    ROUND(100 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_ratio
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;

/*
 schemaname | tablename | size  | n_dead_tup | dead_ratio
------------+-----------+-------+------------+------------
 public     | logs      | 50 MB |     500000 |      45.00  ← 45% dead tuples!
 public     | pedidos   | 10 MB |      50000 |      10.00
*/
```

### Solução: VACUUM Mais Frequente

```sql
-- Opção 1: VACUUM manual
VACUUM logs;

-- Opção 2: Ajustar autovacuum para tabela específica
ALTER TABLE logs SET (
    autovacuum_vacuum_scale_factor = 0.05,  -- Rodar com 5% dead tuples (padrão: 20%)
    autovacuum_vacuum_threshold = 100       -- Rodar com mínimo de 100 dead tuples
);

-- Opção 3: VACUUM FULL (bloqueia tabela, reescreve completamente)
VACUUM FULL logs;
```

---

## 🎓 Boas Práticas

### 1. Monitorar Dead Tuples

```sql
-- View para monitorar bloat
CREATE VIEW bloat_monitor AS
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_live_tup,
    n_dead_tup,
    ROUND(100 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_ratio,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY dead_ratio DESC;

-- Consultar diariamente
SELECT * FROM bloat_monitor WHERE dead_ratio > 20;
```

### 2. Ajustar Autovacuum para Tabelas Hot

```sql
-- Tabelas com muitos UPDATEs/DELETEs
ALTER TABLE pedidos SET (
    autovacuum_vacuum_scale_factor = 0.02,  -- 2%
    autovacuum_vacuum_cost_delay = 10,      -- Menos delay entre limpezas
    autovacuum_vacuum_cost_limit = 2000     -- Mais "orçamento" para limpeza
);
```

### 3. Evitar Long-Running Transactions

```sql
-- Long transactions impedem VACUUM de remover dead tuples!

-- Ver transações longas
SELECT 
    pid,
    age(clock_timestamp(), xact_start) AS xact_duration,
    age(clock_timestamp(), query_start) AS query_duration,
    state,
    LEFT(query, 50) AS query
FROM pg_stat_activity
WHERE state != 'idle'
  AND age(clock_timestamp(), xact_start) > INTERVAL '1 hour'
ORDER BY xact_start;

-- Matar transação longa (cuidado!)
SELECT pg_terminate_backend(12345);  -- PID da transação
```

### 4. Monitorar Transaction Age

```sql
-- Alertar se database age > 1.5 bilhões
DO $$
DECLARE
    v_age INT;
BEGIN
    SELECT age(datfrozenxid) INTO v_age
    FROM pg_database
    WHERE datname = current_database();
    
    IF v_age > 1500000000 THEN
        RAISE WARNING 'Database age muito alto: % (risco de wraparound!)', v_age;
    END IF;
END $$;
```

---

## 🔗 Navegação

⬅️ [Anterior: Temporal Tables](./05-temporal-tables.md) | [Voltar ao Índice: História e Auditoria](./README.md) | [Próximo: WAL →](./07-wal.md)

---

## 📝 Resumo Rápido

```sql
-- Ver colunas ocultas (xmin, xmax)
SELECT xmin, xmax, ctid, * FROM minha_tabela;

-- Ver dead tuples
SELECT 
    relname,
    n_live_tup,
    n_dead_tup,
    ROUND(100 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_ratio
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- VACUUM manual
VACUUM VERBOSE minha_tabela;

-- VACUUM FULL (bloqueia tabela)
VACUUM FULL minha_tabela;

-- Ajustar autovacuum para tabela específica
ALTER TABLE minha_tabela SET (
    autovacuum_vacuum_scale_factor = 0.05,  -- 5% dead tuples
    autovacuum_vacuum_threshold = 100
);

-- Monitorar transaction age
SELECT 
    datname,
    age(datfrozenxid) AS xid_age,
    2147483647 - age(datfrozenxid) AS xids_remaining
FROM pg_database
ORDER BY xid_age DESC;

-- Ver transações longas
SELECT pid, age(clock_timestamp(), xact_start) AS duration, query
FROM pg_stat_activity
WHERE state != 'idle'
  AND age(clock_timestamp(), xact_start) > INTERVAL '1 hour';
```
