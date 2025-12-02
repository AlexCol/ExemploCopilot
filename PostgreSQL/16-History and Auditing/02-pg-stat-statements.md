# 16.2 - Rastreamento de Queries (pg_stat_statements)

## 📋 O que você vai aprender

- Instalação e configuração do pg_stat_statements
- Estatísticas de execução de queries
- Identificar queries lentas e problemáticas
- Query normalization
- Análise de padrões de uso
- Resetar e manter estatísticas

---

## 🎯 O que é pg_stat_statements?

**pg_stat_statements** é uma extensão oficial do PostgreSQL que rastreia estatísticas de execução de todas as queries SQL executadas no servidor.

### Diferenças vs .psql_history

| Característica | .psql_history | pg_stat_statements |
|----------------|---------------|-------------------|
| Escopo | Cliente psql | Servidor PostgreSQL |
| Queries rastreadas | Apenas do psql | Todas (JDBC, ODBC, etc) |
| Estatísticas | Não | Sim (tempo, calls, rows) |
| Normalização | Não | Sim (valores → placeholders) |
| Persistência | Arquivo | Memória (shared memory) |
| Overhead | Zero | Baixo (~5%) |

### Para que serve?

1. **Performance Tuning**: Identificar queries lentas
2. **Otimização**: Ver quais queries consomem mais tempo total
3. **Padrões de Uso**: Entender o que a aplicação faz
4. **Debugging**: Rastrear queries problemáticas
5. **Capacity Planning**: Prever crescimento de carga

---

## 🚀 Instalação e Configuração

### 1. Instalar Extensão

```sql
-- Conectar como superuser
psql -U postgres

-- Criar extensão
CREATE EXTENSION pg_stat_statements;

-- Verificar
\dx pg_stat_statements
```

### 2. Configurar postgresql.conf

```conf
# Adicionar ao postgresql.conf

# Carregar extensão na inicialização
shared_preload_libraries = 'pg_stat_statements'

# Configurações opcionais
pg_stat_statements.max = 10000          # Número máximo de queries rastreadas
pg_stat_statements.track = all          # all, top, none
pg_stat_statements.track_utility = on   # Rastrear DDL (CREATE, DROP, etc)
pg_stat_statements.track_planning = on  # Incluir tempo de planejamento (PG13+)
pg_stat_statements.save = on            # Persistir entre reinicializações
```

### 3. Reiniciar PostgreSQL

```bash
# Linux
sudo systemctl restart postgresql

# Docker
docker restart postgres-container

# Windows
net stop postgresql-x64-14
net start postgresql-x64-14

# Verificar se carregou
psql -U postgres -c "SELECT * FROM pg_available_extensions WHERE name = 'pg_stat_statements';"
```

---

## 📊 Consultando Estatísticas

### View Principal: pg_stat_statements

```sql
-- Estrutura da view
SELECT 
    queryid,           -- Hash da query normalizada
    query,             -- Query SQL (normalizada)
    calls,             -- Número de execuções
    total_exec_time,   -- Tempo total (ms) - PG13+
    mean_exec_time,    -- Tempo médio por execução (ms)
    min_exec_time,     -- Tempo mínimo (ms)
    max_exec_time,     -- Tempo máximo (ms)
    stddev_exec_time,  -- Desvio padrão (ms)
    rows,              -- Total de linhas retornadas/afetadas
    shared_blks_hit,   -- Cache hits
    shared_blks_read,  -- Disk reads
    shared_blks_written -- Disk writes
FROM pg_stat_statements
LIMIT 5;
```

### Exemplo de Saída

```
queryid  | query                                          | calls | total_exec_time | mean_exec_time
---------+------------------------------------------------+-------+-----------------+----------------
12345678 | SELECT * FROM clientes WHERE id = $1           |  5000 |        2500.00  |      0.50
87654321 | UPDATE pedidos SET status = $1 WHERE id = $2   |  1200 |       12000.00  |     10.00
11223344 | INSERT INTO logs (mensagem, data) VALUES ($1, $2) | 50000 |        5000.00  |      0.10
```

---

## 🔍 Queries Úteis

### 1. Top 10 Queries Mais Lentas (Tempo Total)

```sql
SELECT 
    calls,
    total_exec_time::NUMERIC(10,2) AS total_time_ms,
    mean_exec_time::NUMERIC(10,2) AS avg_time_ms,
    (total_exec_time / SUM(total_exec_time) OVER ()) * 100 AS percent_total,
    LEFT(query, 80) AS query_preview
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

/*
 calls | total_time_ms | avg_time_ms | percent_total | query_preview
-------+---------------+-------------+---------------+----------------------------------------------------------
  1200 |      12000.00 |       10.00 |         30.50 | UPDATE pedidos SET status = $1 WHERE id = $2
  5000 |       2500.00 |        0.50 |          6.35 | SELECT * FROM clientes WHERE id = $1
 50000 |       5000.00 |        0.10 |         12.70 | INSERT INTO logs (mensagem, data) VALUES ($1, $2)
*/
```

### 2. Top 10 Queries Mais Executadas

```sql
SELECT 
    calls,
    mean_exec_time::NUMERIC(10,2) AS avg_ms,
    LEFT(query, 100) AS query_preview
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;
```

### 3. Queries com Maior Tempo Médio (Mais Lentas Individualmente)

```sql
SELECT 
    calls,
    mean_exec_time::NUMERIC(10,2) AS avg_ms,
    max_exec_time::NUMERIC(10,2) AS max_ms,
    stddev_exec_time::NUMERIC(10,2) AS stddev_ms,
    LEFT(query, 80) AS query_preview
FROM pg_stat_statements
WHERE calls > 10  -- Apenas queries executadas mais de 10x
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### 4. Queries com Mais Cache Misses (Disk I/O)

```sql
SELECT 
    calls,
    shared_blks_read AS disk_reads,
    shared_blks_hit AS cache_hits,
    CASE 
        WHEN (shared_blks_hit + shared_blks_read) > 0 
        THEN (shared_blks_hit::FLOAT / (shared_blks_hit + shared_blks_read) * 100)::NUMERIC(5,2)
        ELSE 0
    END AS cache_hit_ratio,
    LEFT(query, 80) AS query_preview
FROM pg_stat_statements
WHERE shared_blks_read > 0
ORDER BY shared_blks_read DESC
LIMIT 10;

/*
 calls | disk_reads | cache_hits | cache_hit_ratio | query_preview
-------+------------+------------+-----------------+----------------------------------------------
  1200 |      50000 |     150000 |           75.00 | SELECT * FROM pedidos WHERE data > $1
   500 |      30000 |      10000 |           25.00 | SELECT * FROM logs WHERE created_at > $1
*/
```

### 5. Queries que Escrevem Mais (INSERT/UPDATE/DELETE)

```sql
SELECT 
    calls,
    shared_blks_written AS blocks_written,
    shared_blks_dirtied AS blocks_dirtied,
    LEFT(query, 80) AS query_preview
FROM pg_stat_statements
WHERE shared_blks_written > 0
ORDER BY shared_blks_written DESC
LIMIT 10;
```

### 6. Queries com Alta Variabilidade (Inconsistentes)

```sql
-- Queries onde max_time >> mean_time (possível problema de lock ou dados inconsistentes)
SELECT 
    calls,
    mean_exec_time::NUMERIC(10,2) AS avg_ms,
    max_exec_time::NUMERIC(10,2) AS max_ms,
    (max_exec_time / NULLIF(mean_exec_time, 0))::NUMERIC(10,2) AS max_vs_mean_ratio,
    stddev_exec_time::NUMERIC(10,2) AS stddev_ms,
    LEFT(query, 80) AS query_preview
FROM pg_stat_statements
WHERE calls > 10
  AND max_exec_time > mean_exec_time * 10  -- Max é 10x maior que média
ORDER BY max_exec_time / NULLIF(mean_exec_time, 0) DESC
LIMIT 10;

/*
 calls | avg_ms | max_ms | max_vs_mean_ratio | stddev_ms | query_preview
-------+--------+--------+-------------------+-----------+----------------------------------------
   100 |   5.00 | 500.00 |            100.00 |     50.00 | UPDATE pedidos SET status = $1 WHERE id = $2
    50 |   2.00 | 100.00 |             50.00 |     15.00 | SELECT * FROM clientes WHERE email = $1

-- Indica que essas queries às vezes são muito lentas (possível lock, cache miss, etc)
*/
```

---

## 🎯 Normalização de Queries

O pg_stat_statements **normaliza** queries, substituindo valores literais por placeholders (`$1`, `$2`, etc).

### Exemplo de Normalização

```sql
-- Queries executadas pela aplicação:
SELECT * FROM clientes WHERE id = 123;
SELECT * FROM clientes WHERE id = 456;
SELECT * FROM clientes WHERE id = 789;

-- São agrupadas como UMA ÚNICA query no pg_stat_statements:
SELECT * FROM clientes WHERE id = $1;
-- calls = 3
```

### Por que normalizar?

- **Agregação**: Ver estatísticas do padrão de query, não de cada execução individual
- **Memória**: Evitar explodir o limite de `pg_stat_statements.max`
- **Análise**: Identificar padrões de uso

### Limitação: Queries Dinâmicas

```sql
-- Problema: Queries geradas dinamicamente podem NÃO ser agrupadas

-- Aplicação gera:
SELECT * FROM clientes WHERE id = 123;
SELECT * FROM clientes WHERE id = 456 AND nome LIKE 'João%';
SELECT * FROM clientes WHERE id = 789 AND ativo = true;

-- São 3 queries diferentes no pg_stat_statements:
-- SELECT * FROM clientes WHERE id = $1;
-- SELECT * FROM clientes WHERE id = $1 AND nome LIKE $2;
-- SELECT * FROM clientes WHERE id = $1 AND ativo = $2;
```

**Solução**: Usar prepared statements na aplicação para forçar agrupamento.

---

## 🔄 Resetar Estatísticas

### Resetar Todas as Estatísticas

```sql
-- Limpar todos os dados
SELECT pg_stat_statements_reset();

-- Verificar (deve estar vazio ou com poucas queries recentes)
SELECT COUNT(*) FROM pg_stat_statements;
```

### Resetar Estatísticas de Uma Query Específica

```sql
-- Resetar query com queryid específico (PG13+)
SELECT pg_stat_statements_reset(queryid => 12345678);

-- Resetar todas as queries de um database específico
SELECT pg_stat_statements_reset(userid => NULL, dbid => (SELECT oid FROM pg_database WHERE datname = 'mydb'));
```

### Quando Resetar?

- **Após deploy**: Para medir impacto de mudanças
- **Troubleshooting**: Para isolar queries de um período específico
- **Periodicamente**: Se atingir limite de `pg_stat_statements.max`

---

## 🛠️ Ferramentas de Análise

### 1. pgBadger

Analisa logs do PostgreSQL e pode integrar com pg_stat_statements.

```bash
# Instalar
apt-get install pgbadger  # Debian/Ubuntu
brew install pgbadger     # macOS

# Gerar relatório
pgbadger /var/log/postgresql/postgresql-*.log -o report.html

# Abrir report.html no navegador
```

### 2. pg_stat_monitor

Extensão melhorada (alternativa ao pg_stat_statements) com histogramas e mais detalhes.

```sql
CREATE EXTENSION pg_stat_monitor;

-- Mostra histogramas de tempo de execução
SELECT * FROM pg_stat_monitor;
```

### 3. DataDog / New Relic / AppDynamics

Integram com pg_stat_statements para monitoramento em tempo real.

---

## 🎓 Boas Práticas

### 1. Configurar Corretamente o Limite

```sql
-- Ver quantas queries estão sendo rastreadas
SELECT COUNT(*) FROM pg_stat_statements;

-- Ver limite configurado
SHOW pg_stat_statements.max;

-- Se COUNT(*) está próximo de max, aumentar o limite:
-- No postgresql.conf:
-- pg_stat_statements.max = 20000  (padrão: 5000)
```

### 2. Monitorar Overhead

```sql
-- Verificar overhead de pg_stat_statements (deve ser <5%)
SELECT 
    total_exec_time AS total_time_sec
FROM pg_stat_statements
WHERE query LIKE '%pg_stat_statements%';

-- Se overhead > 10%, considerar:
-- - Reduzir pg_stat_statements.max
-- - Desabilitar track_planning (PG13+)
-- - Desabilitar track_utility
```

### 3. Automatizar Análise

```sql
-- Criar view para top queries lentas
CREATE VIEW top_slow_queries AS
SELECT 
    calls,
    total_exec_time::NUMERIC(10,2) AS total_ms,
    mean_exec_time::NUMERIC(10,2) AS avg_ms,
    (total_exec_time / SUM(total_exec_time) OVER ()) * 100 AS percent_total,
    LEFT(query, 100) AS query_preview
FROM pg_stat_statements
WHERE calls > 10
ORDER BY total_exec_time DESC
LIMIT 20;

-- Consultar facilmente
SELECT * FROM top_slow_queries;
```

### 4. Alertas Automáticos

```sql
-- Detectar queries que consomem >50% do tempo total
DO $$
DECLARE
    v_query RECORD;
BEGIN
    FOR v_query IN 
        SELECT 
            LEFT(query, 100) AS query_preview,
            (total_exec_time / SUM(total_exec_time) OVER ()) * 100 AS percent
        FROM pg_stat_statements
        WHERE (total_exec_time / SUM(total_exec_time) OVER ()) * 100 > 50
    LOOP
        RAISE WARNING 'Query consome >50%% do tempo: %', v_query.query_preview;
    END LOOP;
END $$;
```

---

## 📈 Exemplo Prático: Antes e Depois da Otimização

### Antes

```sql
-- Ver query problemática
SELECT 
    calls,
    total_exec_time::NUMERIC(10,2) AS total_ms,
    mean_exec_time::NUMERIC(10,2) AS avg_ms,
    query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 1;

/*
 calls | total_ms  | avg_ms | query
-------+-----------+--------+-----------------------------------------------------
  5000 | 250000.00 |  50.00 | SELECT * FROM pedidos WHERE data > $1 ORDER BY id
*/
```

### Otimização

```sql
-- Criar índice
CREATE INDEX idx_pedidos_data ON pedidos(data);
```

### Depois

```sql
-- Resetar estatísticas para medir impacto
SELECT pg_stat_statements_reset();

-- Executar queries novamente (aplicação normal)
-- ...

-- Ver melhoria
SELECT 
    calls,
    total_exec_time::NUMERIC(10,2) AS total_ms,
    mean_exec_time::NUMERIC(10,2) AS avg_ms,
    query
FROM pg_stat_statements
WHERE query LIKE '%pedidos%data%'
ORDER BY total_exec_time DESC
LIMIT 1;

/*
 calls | total_ms | avg_ms | query
-------+----------+--------+-----------------------------------------------------
  5000 |  5000.00 |   1.00 | SELECT * FROM pedidos WHERE data > $1 ORDER BY id

-- Redução de 50ms → 1ms (50x mais rápido!)
*/
```

---

## 🔗 Navegação

⬅️ [Anterior: .psql_history](./01-psql-history.md) | [Voltar ao Índice: History and Auditing](./README.md) | [Próximo: Logs do PostgreSQL →](./03-logs-postgresql.md)

---

## 📝 Resumo Rápido

```sql
-- Instalar
CREATE EXTENSION pg_stat_statements;

-- Top 10 queries mais lentas (tempo total)
SELECT calls, total_exec_time, mean_exec_time, LEFT(query, 80)
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Top 10 queries mais executadas
SELECT calls, mean_exec_time, LEFT(query, 80)
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;

-- Queries com alta variabilidade
SELECT calls, mean_exec_time, max_exec_time, 
       (max_exec_time / NULLIF(mean_exec_time, 0)) AS max_vs_mean
FROM pg_stat_statements
WHERE calls > 10 AND max_exec_time > mean_exec_time * 10
ORDER BY max_exec_time / NULLIF(mean_exec_time, 0) DESC
LIMIT 10;

-- Resetar estatísticas
SELECT pg_stat_statements_reset();

-- Configuração (postgresql.conf)
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
```
