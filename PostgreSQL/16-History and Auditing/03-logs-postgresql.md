# 16.3 - Logs do PostgreSQL

## 📋 O que você vai aprender

- Configuração de logging
- Tipos de log (connections, statements, errors)
- log_statement vs log_min_duration_statement
- Formato e parsing de logs
- Rotação de logs
- Ferramentas de análise (pgBadger)

---

## 🎯 O que são os Logs do PostgreSQL?

Os logs do PostgreSQL registram a atividade do **servidor de banco de dados**, incluindo conexões, queries, erros e eventos do sistema.

### Diferenças vs pg_stat_statements

| Característica | Logs | pg_stat_statements |
|----------------|------|-------------------|
| Escopo | Todos os eventos | Apenas queries |
| Persistência | Arquivos no disco | Memória (shared) |
| Normalização | Não (valores literais) | Sim (placeholders) |
| Estatísticas | Não | Sim (tempo, calls) |
| Overhead | Médio (I/O) | Baixo |
| Retenção | Configurável (dias/semanas) | Apenas atual |

### Para que servem?

1. **Debugging**: Rastrear erros e comportamento inesperado
2. **Auditoria**: Compliance (LGPD, SOX, PCI-DSS)
3. **Forense**: Investigar incidentes de segurança
4. **Performance**: Identificar queries lentas
5. **Monitoramento**: Detectar problemas antes que afetem usuários

---

## ⚙️ Configuração de Logging

### Arquivo: postgresql.conf

Localização típica:
- Linux: `/etc/postgresql/<version>/main/postgresql.conf`
- Docker: `/var/lib/postgresql/data/postgresql.conf`
- Windows: `C:\Program Files\PostgreSQL\<version>\data\postgresql.conf`

### 1. Habilitar Logging

```conf
# postgresql.conf

# Habilitar logging
logging_collector = on

# Diretório dos logs (relativo ao data directory)
log_directory = 'log'

# Nome dos arquivos de log
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'

# Rotação automática
log_rotation_age = 1d        # Rotacionar a cada 1 dia
log_rotation_size = 100MB    # Rotacionar quando atingir 100MB

# Manter logs por 7 dias
log_file_mode = 0600
log_truncate_on_rotation = on  # Sobrescrever logs antigos
```

### 2. Configurar O Que Logar

```conf
# Conexões e Desconexões
log_connections = on
log_disconnections = on

# Duração de queries
log_duration = off  # on = logar duração de TODAS as queries (cuidado!)

# Logar apenas queries lentas (>1 segundo)
log_min_duration_statement = 1000  # ms (0 = todas, -1 = nenhuma)

# O que logar
log_statement = 'none'  # none, ddl, mod, all
```

### 3. Nível de Detalhe

```conf
# Formato da linha de log
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '

# Componentes:
# %t = timestamp
# %p = process ID
# %l = linha do log
# %u = usuário
# %d = database
# %a = application_name
# %h = hostname/IP do cliente

# Nível de verbosidade de erros
log_error_verbosity = default  # terse, default, verbose
```

### 4. Aplicar Configuração

```sql
-- Opção 1: Recarregar config (sem reiniciar)
SELECT pg_reload_conf();

-- Opção 2: Reiniciar PostgreSQL
-- Linux: sudo systemctl restart postgresql
-- Docker: docker restart postgres-container
```

---

## 📝 Tipos de Log

### 1. log_statement

Controla **quais tipos** de statements são logados.

```conf
# Valores possíveis:
log_statement = 'none'  # Não logar statements
log_statement = 'ddl'   # Apenas DDL (CREATE, ALTER, DROP)
log_statement = 'mod'   # DDL + DML (INSERT, UPDATE, DELETE, TRUNCATE)
log_statement = 'all'   # Tudo (incluindo SELECT)
```

#### Exemplo: DDL

```conf
log_statement = 'ddl'
```

```sql
-- Será logado:
CREATE TABLE clientes (id INT, nome VARCHAR(100));
ALTER TABLE clientes ADD COLUMN email VARCHAR(100);
DROP TABLE clientes;

-- NÃO será logado:
SELECT * FROM clientes;
INSERT INTO clientes VALUES (1, 'João', 'joao@example.com');
```

#### Exemplo: MOD

```conf
log_statement = 'mod'
```

```sql
-- Será logado:
CREATE TABLE clientes (...);
INSERT INTO clientes VALUES (...);
UPDATE clientes SET ativo = false WHERE id = 1;
DELETE FROM clientes WHERE id = 2;

-- NÃO será logado:
SELECT * FROM clientes;
```

#### Exemplo: ALL

```conf
log_statement = 'all'
```

```sql
-- TUDO será logado (cuidado com overhead!)
SELECT * FROM clientes;
INSERT INTO clientes VALUES (...);
CREATE INDEX idx_clientes_email ON clientes(email);
```

### 2. log_min_duration_statement

Loga apenas queries **mais lentas** que o threshold.

```conf
# Logar queries que levam >1 segundo
log_min_duration_statement = 1000  # ms

# Valores especiais:
# -1  = Não logar nenhuma query
#  0  = Logar TODAS as queries (similar a log_statement = 'all')
# >0  = Logar apenas queries mais lentas que o valor
```

#### Exemplo: Queries Lentas

```conf
log_min_duration_statement = 1000  # 1 segundo
```

```sql
-- Esta query leva 0.5s → NÃO será logada
SELECT * FROM clientes WHERE id = 123;

-- Esta query leva 2.3s → SERÁ logada
SELECT * FROM pedidos WHERE data > '2020-01-01' ORDER BY id;
```

#### Log Gerado

```
2024-01-15 10:30:45 PST [12345]: [1-1] user=app_user,db=mydb LOG:  duration: 2345.678 ms  statement: SELECT * FROM pedidos WHERE data > '2020-01-01' ORDER BY id;
```

### 3. log_connections e log_disconnections

```conf
log_connections = on
log_disconnections = on
```

#### Exemplo de Log

```
2024-01-15 10:30:00 PST [12345]: [1-1] user=app_user,db=mydb,host=192.168.1.100 LOG:  connection authorized: user=app_user database=mydb
2024-01-15 10:35:00 PST [12345]: [2-1] user=app_user,db=mydb LOG:  disconnection: session time: 0:05:00.123 user=app_user database=mydb host=192.168.1.100
```

---

## 📄 Formato do Log

### Exemplo de Linha de Log

```
2024-01-15 10:30:45.123 PST [12345]: [1-1] user=app_user,db=mydb,app=psql,client=192.168.1.100 LOG:  statement: SELECT * FROM clientes WHERE id = 123;
```

### Componentes

```
2024-01-15 10:30:45.123   → Timestamp
PST                       → Timezone
[12345]                   → Process ID (PID)
[1-1]                     → Linha do log
user=app_user             → Usuário do PostgreSQL
db=mydb                   → Database
app=psql                  → Application name
client=192.168.1.100      → IP do cliente
LOG                       → Log level
statement: SELECT...      → Mensagem
```

### Log Levels

```
DEBUG1-5: Informações de debug (muito verboso)
LOG:      Informações gerais
INFO:     Informações para o usuário
NOTICE:   Avisos úteis
WARNING:  Avisos de problemas potenciais
ERROR:    Erro que impede execução do comando
FATAL:    Erro que força desconexão da sessão
PANIC:    Erro crítico que força shutdown do servidor
```

---

## 🔍 Analisando Logs

### 1. Buscar Erros

```bash
# Linux/Mac
grep "ERROR" /var/log/postgresql/postgresql-*.log

# Ver erros das últimas 24 horas
grep "ERROR" /var/log/postgresql/postgresql-$(date +%Y-%m-%d)*.log

# Contar erros por tipo
grep "ERROR" /var/log/postgresql/postgresql-*.log | cut -d: -f5- | sort | uniq -c | sort -rn

# Saída:
#  45 ERROR:  relation "tabela_inexistente" does not exist
#  12 ERROR:  duplicate key value violates unique constraint
#   5 ERROR:  deadlock detected
```

### 2. Buscar Queries Lentas

```bash
# Queries que levaram >5 segundos
awk '$0 ~ /duration: [0-9]+/ {if ($7 > 5000) print}' /var/log/postgresql/postgresql-*.log

# Top 10 queries mais lentas
grep "duration:" /var/log/postgresql/postgresql-*.log | \
    awk '{print $7, $0}' | \
    sort -rn | \
    head -10
```

### 3. Buscar Acessos de IP Específico

```bash
# Ver tudo que o IP 192.168.1.100 fez
grep "192.168.1.100" /var/log/postgresql/postgresql-*.log
```

### 4. Buscar Deadlocks

```bash
grep "deadlock" /var/log/postgresql/postgresql-*.log

# Exemplo de log de deadlock:
# ERROR:  deadlock detected
# DETAIL:  Process 12345 waits for ShareLock on transaction 678; blocked by process 12346.
# Process 12346 waits for ShareLock on transaction 679; blocked by process 12345.
```

---

## 🔄 Rotação de Logs

### Rotação Automática (Configurada no PostgreSQL)

```conf
# postgresql.conf

# Rotacionar a cada 1 dia
log_rotation_age = 1d

# Rotacionar quando atingir 10MB
log_rotation_size = 10MB

# Sobrescrever logs antigos quando rotacionar
log_truncate_on_rotation = on
```

### Rotação Manual (logrotate)

```bash
# /etc/logrotate.d/postgresql

/var/log/postgresql/*.log {
    daily                # Rotacionar diariamente
    rotate 30            # Manter últimos 30 arquivos
    compress             # Comprimir logs antigos (.gz)
    delaycompress        # Não comprimir o último log
    missingok            # Não gerar erro se arquivo não existir
    notifempty           # Não rotacionar se vazio
    create 0640 postgres postgres  # Permissões do novo arquivo
    sharedscripts
    postrotate
        /usr/bin/pg_ctl reload -D /var/lib/postgresql/data > /dev/null
    endscript
}
```

---

## 🛠️ Ferramentas de Análise

### 1. pgBadger

Analisador de logs mais popular para PostgreSQL.

#### Instalação

```bash
# Debian/Ubuntu
apt-get install pgbadger

# Red Hat/CentOS
yum install pgbadger

# macOS
brew install pgbadger

# Manual
git clone https://github.com/darold/pgbadger.git
cd pgbadger
perl Makefile.PL
make && sudo make install
```

#### Uso

```bash
# Analisar log único
pgbadger /var/log/postgresql/postgresql-2024-01-15.log

# Analisar múltiplos logs
pgbadger /var/log/postgresql/postgresql-*.log -o report.html

# Incremental (analisar apenas novos logs)
pgbadger --last-parsed .pgbadger_last_state /var/log/postgresql/postgresql-*.log -o report.html

# Filtrar por database
pgbadger -d mydb /var/log/postgresql/postgresql-*.log -o report_mydb.html

# Abrir relatório
firefox report.html  # Linux
open report.html     # macOS
start report.html    # Windows
```

#### O que pgBadger mostra?

- Top 10 queries mais lentas
- Queries mais executadas
- Distribuição de tempo de execução
- Conexões por hora/dia
- Erros mais comuns
- Locks e deadlocks
- Distribuição de tráfego por usuário/database
- Gráficos de performance

### 2. pg_view

Monitoramento em tempo real (similar ao `top` do Linux).

```bash
# Instalar
pip install pg-view

# Executar
pg_view -h localhost -U postgres -d mydb

# Mostra:
# - Queries ativas
# - CPU e memória
# - Locks
# - Replicação
```

### 3. grep e awk (análise manual)

```bash
# Top 10 queries mais lentas
grep "duration:" /var/log/postgresql/postgresql-*.log | \
    awk '{print $7, $9, $10, $11, $12, $13, $14, $15}' | \
    sort -rn | \
    head -10

# Erros por hora
grep "ERROR" /var/log/postgresql/postgresql-*.log | \
    awk '{print $1, $2}' | \
    cut -d: -f1 | \
    uniq -c

# Conexões por usuário
grep "connection authorized" /var/log/postgresql/postgresql-*.log | \
    awk -F'user=' '{print $2}' | \
    awk '{print $1}' | \
    sort | \
    uniq -c | \
    sort -rn
```

---

## 🎯 Boas Práticas

### 1. Não Logar Tudo em Produção

```conf
# ❌ MAU (overhead alto)
log_statement = 'all'

# ✅ BOM (apenas queries lentas e mudanças)
log_statement = 'mod'  # DDL + DML
log_min_duration_statement = 1000  # Queries >1s
```

### 2. Usar log_line_prefix Rico

```conf
# Incluir PID, timestamp, usuário, database, aplicação, IP
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '

# Com isso, você pode:
# - Rastrear queries de um usuário específico
# - Identificar qual aplicação gerou uma query
# - Correlacionar com logs da aplicação via PID
```

### 3. Monitorar Tamanho dos Logs

```bash
# Ver tamanho total dos logs
du -sh /var/log/postgresql/

# Configurar alerta se >10GB
if [ $(du -s /var/log/postgresql/ | cut -f1) -gt 10485760 ]; then
    echo "ALERTA: Logs PostgreSQL >10GB"
fi
```

### 4. Integrar com Ferramentas de Monitoramento

```bash
# Enviar logs para syslog
log_destination = 'syslog'

# Ou enviar para arquivo + syslog
log_destination = 'stderr,syslog'

# Prefixo do syslog
syslog_ident = 'postgres'
syslog_facility = 'LOCAL0'

# Com isso, pode integrar com:
# - Splunk
# - ELK Stack (Elasticsearch, Logstash, Kibana)
# - Datadog
# - New Relic
```

---

## 🔒 Segurança dos Logs

### ⚠️ Logs Podem Expor Dados Sensíveis

```sql
-- MAU: Senha em texto plano no log!
CREATE USER john WITH PASSWORD 'senha123';

-- Aparece no log:
-- LOG:  statement: CREATE USER john WITH PASSWORD 'senha123';
```

### ✅ Evitar Exposição

#### 1. Não Logar Passwords

```conf
# postgresql.conf
log_statement = 'ddl'  # CREATE USER não será logado com 'mod'
```

#### 2. Usar Variáveis

```sql
\set senha 'senha123'
CREATE USER john WITH PASSWORD :'senha';

-- No log:
-- CREATE USER john WITH PASSWORD :'senha';  -- Valor não exposto
```

#### 3. Proteger Arquivos de Log

```bash
# Permissões restritas (apenas postgres pode ler)
chmod 600 /var/log/postgresql/*.log
chown postgres:postgres /var/log/postgresql/*.log
```

---

## 📊 Exemplo Prático: Debugging

### Problema: Aplicação Lenta

#### 1. Habilitar Logging de Queries Lentas

```conf
# postgresql.conf
log_min_duration_statement = 100  # 100ms
```

#### 2. Recarregar Config

```sql
SELECT pg_reload_conf();
```

#### 3. Usar Aplicação Normalmente

#### 4. Analisar Logs

```bash
# Ver queries >1s
grep "duration: [0-9][0-9][0-9][0-9]" /var/log/postgresql/postgresql-*.log

# Saída:
# 2024-01-15 10:30:45 LOG:  duration: 2345.678 ms  statement: SELECT * FROM pedidos WHERE data > '2020-01-01' ORDER BY id;
```

#### 5. Otimizar Query

```sql
-- Identificar query problemática
EXPLAIN ANALYZE SELECT * FROM pedidos WHERE data > '2020-01-01' ORDER BY id;

-- Criar índice
CREATE INDEX idx_pedidos_data ON pedidos(data);
```

#### 6. Verificar Melhoria

```bash
# Queries agora devem ser mais rápidas
grep "SELECT \* FROM pedidos WHERE data" /var/log/postgresql/postgresql-*.log | grep "duration:"

# Antes: duration: 2345.678 ms
# Depois: duration: 45.123 ms  ✅
```

---

## 🔗 Navegação

⬅️ [Anterior: pg_stat_statements](./02-pg-stat-statements.md) | [Voltar ao Índice: History and Auditing](./README.md) | [Próximo: Audit Triggers →](./04-audit-triggers.md)

---

## 📝 Resumo Rápido

```conf
# postgresql.conf - Configuração básica

# Habilitar logging
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'

# O que logar
log_connections = on
log_disconnections = on
log_statement = 'mod'  # DDL + DML
log_min_duration_statement = 1000  # Queries >1s

# Formato
log_line_prefix = '%t [%p]: user=%u,db=%d,app=%a,client=%h '

# Rotação
log_rotation_age = 1d
log_rotation_size = 100MB
```

```bash
# Análise manual
grep "ERROR" /var/log/postgresql/postgresql-*.log
grep "duration:" /var/log/postgresql/postgresql-*.log | sort -rn | head -10

# Análise automática
pgbadger /var/log/postgresql/postgresql-*.log -o report.html
```
