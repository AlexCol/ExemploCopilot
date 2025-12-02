# 16.7 - WAL: Write-Ahead Log

## 📋 O que você vai aprender

- O que é Write-Ahead Logging (WAL)
- Estrutura e segmentos do WAL
- WAL archiving
- Point-in-Time Recovery (PITR)
- pg_waldump para análise
- Replicação baseada em WAL

---

## 🎯 O que é o WAL?

**WAL (Write-Ahead Log)** é um mecanismo de **durabilidade** onde todas as mudanças são **primeiro escritas no log** antes de serem aplicadas aos arquivos de dados.

### Princípio Fundamental

```
1. Transação faz mudança (INSERT/UPDATE/DELETE)
2. Mudança é escrita no WAL (disco)
3. Commit retorna para aplicação (RÁPIDO - só escreveu WAL)
4. Mudança é aplicada aos data files (ASSÍNCRONO - checkpoint)
```

### Por que WAL?

1. **Durabilidade**: Em caso de crash, replay do WAL recupera dados
2. **Performance**: Escritas sequenciais no WAL são mais rápidas que writes aleatórios em data files
3. **Replicação**: WAL é enviado para réplicas (streaming replication)
4. **Point-in-Time Recovery (PITR)**: Restaurar banco para um momento específico no tempo

---

## 📂 Estrutura do WAL

### Localização

```bash
# Diretório do WAL
# Linux: /var/lib/postgresql/<version>/main/pg_wal/
# Docker: /var/lib/postgresql/data/pg_wal/
# Windows: C:\Program Files\PostgreSQL\<version>\data\pg_wal\

# Ver arquivos de WAL
ls -lh /var/lib/postgresql/14/main/pg_wal/
/*
-rw------- 1 postgres postgres 16M Jan 15 10:00 000000010000000000000001
-rw------- 1 postgres postgres 16M Jan 15 10:05 000000010000000000000002
-rw------- 1 postgres postgres 16M Jan 15 10:10 000000010000000000000003
drwx------ 2 postgres postgres 4.0K Jan 15 09:00 archive_status/
*/
```

### Segmentos WAL

- **Tamanho fixo**: 16 MB por arquivo (padrão)
- **Nomenclatura**: `000000010000000000000001` (24 caracteres hexadecimais)
  - Timeline ID: `00000001`
  - Log ID: `00000000`
  - Segment ID: `00000001`
- **Reciclagem**: Arquivos antigos são renomeados e reutilizados

### Configuração

```conf
# postgresql.conf

# Tamanho dos segmentos WAL (compile-time, não pode ser alterado)
# wal_segment_size = 16MB

# Nível de WAL logging
wal_level = replica  # minimal, replica, logical

# Buffers de WAL na memória
wal_buffers = 16MB  # Padrão: -1 (auto, 1/32 de shared_buffers)

# Forçar sync imediato do WAL ao commit
synchronous_commit = on  # on, remote_write, remote_apply, local, off

# Intervalo de checkpoints
checkpoint_timeout = 5min
max_wal_size = 1GB
min_wal_size = 80MB

# Compressão de WAL (PG9.5+)
wal_compression = on  # Comprimir WAL de operações FPW (Full Page Writes)
```

---

## 📝 Conteúdo do WAL

### Tipos de Registros WAL

```sql
-- Exemplos de operações que geram WAL:
INSERT INTO clientes VALUES (1, 'João', 'joao@example.com');
-- WAL: "Insert tupla com values (1, 'João', 'joao@example.com') na página X offset Y da tabela clientes"

UPDATE clientes SET ativo = false WHERE id = 1;
-- WAL: "Update tupla na página X offset Y: set ativo=false"

DELETE FROM clientes WHERE id = 1;
-- WAL: "Delete tupla na página X offset Y"

CREATE TABLE produtos (...);
-- WAL: "Create relfilenode XXXX com schema (...)"

COMMIT;
-- WAL: "Transaction XID 12345 committed"
```

### Ver Conteúdo do WAL (pg_waldump)

```bash
# Instalar pg_waldump (já incluído no PostgreSQL)
# Linux: /usr/lib/postgresql/<version>/bin/pg_waldump
# Docker: disponível no PATH

# Dump de um segmento WAL
pg_waldump /var/lib/postgresql/14/main/pg_wal/000000010000000000000001

# Saída (truncada):
/*
rmgr: Heap        len (rec/tot):     59/   171, tx:        100, lsn: 0/01000028, desc: INSERT+INIT off 1, blkref #0: rel 1663/16384/16385 blk 0
rmgr: Transaction len (rec/tot):     34/    34, tx:        100, lsn: 0/010000D8, desc: COMMIT 2024-01-15 10:30:00.123456 UTC
rmgr: Heap        len (rec/tot):     60/   136, tx:        101, lsn: 0/01000100, desc: UPDATE off 1 xmax 101, blkref #0: rel 1663/16384/16385 blk 0
*/

# Filtrar por transaction ID
pg_waldump -x 100 /var/lib/postgresql/14/main/pg_wal/000000010000000000000001

# Filtrar por tabela (relfilenode)
pg_waldump -r Heap /var/lib/postgresql/14/main/pg_wal/000000010000000000000001

# Estatísticas
pg_waldump --stats /var/lib/postgresql/14/main/pg_wal/000000010000000000000001
/*
Type                                           N      (%)          Record size      (%)             FPI size      (%)        Combined size      (%)
----                                           -      ---          -----------      ---             --------      ---        -------------      ---
Heap                                         150   (45.5)               15000   (42.3)                    0    (0.0)                15000   (35.7)
Transaction                                  100   (30.3)                3400   (9.6)                     0    (0.0)                 3400    (8.1)
Btree                                         80   (24.2)               17000   (48.1)                24000  (100.0)                41000   (56.2)
                                            ----                      ------                          ------                        ------
Total                                        330                       35400                           24000                         59400
*/
```

---

## 🔄 WAL Archiving

### O que é WAL Archiving?

Copiar segmentos WAL completos para um **local seguro** (storage externo, S3, etc) para:
- **Backup contínuo**: WAL + base backup = PITR
- **Replicação**: Réplicas podem consumir WAL arquivado
- **Disaster Recovery**: Reconstruir banco após perda completa

### Configuração

```conf
# postgresql.conf

# Habilitar archiving
archive_mode = on

# Comando para copiar WAL
archive_command = 'cp %p /mnt/archive/%f'
# %p = caminho do arquivo WAL
# %f = nome do arquivo WAL

# Exemplos de archive_command:

# Copiar para diretório local
archive_command = 'test ! -f /mnt/archive/%f && cp %p /mnt/archive/%f'

# Copiar para S3 (requer aws-cli)
archive_command = 'aws s3 cp %p s3://meu-bucket/wal/%f'

# Copiar com rsync
archive_command = 'rsync -a %p usuario@backup-server:/mnt/wal-archive/%f'

# Timeout de archiving
archive_timeout = 60  # Forçar switch de WAL a cada 60s (mesmo que não esteja cheio)
```

### Verificar Archiving

```sql
-- Ver status de archiving
SELECT 
    archived_count,      -- Segmentos arquivados com sucesso
    last_archived_wal,   -- Último WAL arquivado
    last_archived_time,  -- Quando foi arquivado
    failed_count,        -- Falhas de archiving
    last_failed_wal,     -- Último WAL que falhou
    last_failed_time     -- Quando falhou
FROM pg_stat_archiver;

/*
 archived_count | last_archived_wal          | last_archived_time  | failed_count
----------------+----------------------------+---------------------+--------------
           1234 | 000000010000000000000123   | 2024-01-15 10:30:00 |            0
*/

-- Ver se há WAL pendente de archiving
SELECT 
    pg_walfile_name(pg_current_wal_lsn()) AS current_wal,
    pg_walfile_name(pg_last_wal_receive_lsn()) AS received_wal;
```

---

## ⏮️ Point-in-Time Recovery (PITR)

### Cenário

```
10:00 - Base backup (pg_basebackup)
10:30 - Usuário cria tabela importante
11:00 - Usuário DELETA tabela por engano! 😱
11:30 - Você descobre o problema

Objetivo: Restaurar banco para 10:59 (antes do DELETE)
```

### Passo 1: Base Backup

```bash
# Fazer backup completo
pg_basebackup -h localhost -U postgres -D /backup/base -Fp -Xs -P

# -D: Diretório de destino
# -Fp: Formato plain (arquivos)
# -Xs: Incluir WAL no backup (stream)
# -P: Mostrar progresso
```

### Passo 2: Arquivar WAL Continuamente

```conf
# postgresql.conf (já configurado acima)
archive_mode = on
archive_command = 'cp %p /backup/wal-archive/%f'
```

### Passo 3: Restaurar para Point-in-Time

```bash
# 1. Parar PostgreSQL
sudo systemctl stop postgresql

# 2. Mover data directory atual (backup de segurança)
mv /var/lib/postgresql/14/main /var/lib/postgresql/14/main.old

# 3. Restaurar base backup
cp -r /backup/base /var/lib/postgresql/14/main

# 4. Criar recovery.signal
touch /var/lib/postgresql/14/main/recovery.signal

# 5. Configurar recovery
cat > /var/lib/postgresql/14/main/postgresql.auto.conf <<EOF
restore_command = 'cp /backup/wal-archive/%f %p'
recovery_target_time = '2024-01-15 10:59:00'  # ANTES do DELETE
recovery_target_action = 'promote'  # Tornar primário após recovery
EOF

# 6. Iniciar PostgreSQL
sudo systemctl start postgresql

# PostgreSQL vai:
# 1. Replay base backup
# 2. Aplicar WAL arquivado até 10:59:00
# 3. Parar (recovery_target_time)
# 4. Promover a primário (recovery_target_action)
```

### Opções de Recovery Target

```conf
# Restaurar até timestamp específico
recovery_target_time = '2024-01-15 10:59:00'

# Restaurar até transaction ID específico
recovery_target_xid = '123456'

# Restaurar até nome de restore point
recovery_target_name = 'antes_migracao'
-- Criar restore point:
-- SELECT pg_create_restore_point('antes_migracao');

# Restaurar até o fim do WAL disponível
recovery_target = 'immediate'

# Ação após atingir target
recovery_target_action = 'pause'     # Pausar em recovery mode
recovery_target_action = 'promote'   # Promover a primário
recovery_target_action = 'shutdown'  # Desligar
```

---

## 🔁 Replicação com WAL

### Streaming Replication

```conf
# postgresql.conf (PRIMARY)

# Habilitar replicação
wal_level = replica  # Gera WAL suficiente para replicação

# Conexões de réplicas
max_wal_senders = 10  # Máximo de réplicas simultâneas

# Retenção de WAL para réplicas
wal_keep_size = 1GB  # Manter 1GB de WAL (se réplica atrasar)

# Slots de replicação (garantem retenção de WAL)
max_replication_slots = 10
```

### Criar Réplica

```bash
# 1. Criar base backup na réplica
pg_basebackup -h primary-server -U replication_user -D /var/lib/postgresql/14/replica -Xs -P -R

# -R: Criar configuração de standby automaticamente

# 2. Iniciar réplica
# PostgreSQL vai automaticamente:
# - Conectar ao primário
# - Fazer replay de WAL em tempo real
# - Ficar sincronizado
```

### Monitorar Replicação

```sql
-- No PRIMARY
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    sync_state,
    pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) AS send_lag_bytes,
    pg_wal_lsn_diff(sent_lsn, write_lsn) AS write_lag_bytes,
    pg_wal_lsn_diff(write_lsn, flush_lsn) AS flush_lag_bytes,
    pg_wal_lsn_diff(flush_lsn, replay_lsn) AS replay_lag_bytes
FROM pg_stat_replication;

/*
 pid   | application_name | client_addr | state     | sync_state | send_lag_bytes
-------+------------------+-------------+-----------+------------+----------------
 12345 | replica1         | 10.0.0.10   | streaming | async      |              0
*/
```

---

## 📊 Monitoramento de WAL

### Espaço de WAL

```sql
-- Ver tamanho atual de WAL
SELECT pg_size_pretty(
    SUM(size)
) AS wal_size
FROM pg_ls_waldir();

-- Ver segmentos de WAL
SELECT 
    name,
    pg_size_pretty(size) AS size,
    modification AS modified
FROM pg_ls_waldir()
ORDER BY modification DESC
LIMIT 10;
```

### Taxa de Geração de WAL

```sql
-- Ver LSN (Log Sequence Number) atual
SELECT pg_current_wal_lsn();
-- 0/1B000000

-- Esperar 1 minuto, ver novamente
SELECT pg_current_wal_lsn();
-- 0/1C000000

-- Calcular taxa
SELECT pg_wal_lsn_diff('0/1C000000', '0/1B000000') AS bytes_per_minute;
-- 16777216 (16 MB/min)

-- View para monitorar
CREATE VIEW wal_rate AS
SELECT 
    pg_current_wal_lsn() AS current_lsn,
    NOW() AS timestamp;

-- Consultar periodicamente e calcular taxa
```

### Alertar WAL Alto

```sql
-- Detectar geração excessiva de WAL
DO $$
DECLARE
    v_wal_size BIGINT;
BEGIN
    SELECT SUM(size) INTO v_wal_size FROM pg_ls_waldir();
    
    IF v_wal_size > 5 * 1024 * 1024 * 1024 THEN  -- 5 GB
        RAISE WARNING 'WAL directory muito grande: %', pg_size_pretty(v_wal_size);
    END IF;
END $$;
```

---

## 🎯 Boas Práticas

### 1. Sempre Habilitar WAL Archiving em Produção

```conf
archive_mode = on
archive_command = 'aws s3 cp %p s3://backup-bucket/wal/%f'
```

### 2. Testar PITR Regularmente

```bash
# Agenda mensal: restaurar backup de produção em ambiente de teste
# Verificar se consegue fazer PITR com sucesso
```

### 3. Monitorar Retenção de WAL

```sql
-- Ver quantos segmentos WAL estão sendo mantidos
SELECT COUNT(*) FROM pg_ls_waldir();

-- Se muito alto (>100), investigar:
-- - Réplicas atrasadas?
-- - Archiving falhando?
-- - max_wal_size muito alto?
```

### 4. Usar Slots de Replicação

```sql
-- Criar slot (garante que WAL não seja removido se réplica atrasar)
SELECT pg_create_physical_replication_slot('replica1_slot');

-- Na réplica, usar slot:
-- primary_slot_name = 'replica1_slot'
```

### 5. Comprimir WAL Arquivado

```bash
# archive_command com compressão
archive_command = 'gzip < %p > /backup/wal-archive/%f.gz'

# restore_command correspondente
restore_command = 'gunzip < /backup/wal-archive/%f.gz > %p'
```

---

## 🔗 Navegação

⬅️ [Anterior: MVCC](./06-mvcc.md) | [Voltar ao Índice: History and Auditing](./README.md)

---

## 📝 Resumo Rápido

```conf
# postgresql.conf - WAL básico

# Nível de logging
wal_level = replica

# Archiving
archive_mode = on
archive_command = 'cp %p /backup/wal-archive/%f'
archive_timeout = 60

# Checkpoints
checkpoint_timeout = 5min
max_wal_size = 1GB
min_wal_size = 80MB

# Replicação
max_wal_senders = 10
wal_keep_size = 1GB
max_replication_slots = 10
```

```sql
-- Monitorar WAL
SELECT pg_size_pretty(SUM(size)) FROM pg_ls_waldir();

-- Monitorar archiving
SELECT * FROM pg_stat_archiver;

-- Monitorar replicação
SELECT * FROM pg_stat_replication;

-- Criar restore point (para PITR)
SELECT pg_create_restore_point('antes_deploy');
```

```bash
# PITR - Restaurar
restore_command = 'cp /backup/wal-archive/%f %p'
recovery_target_time = '2024-01-15 10:59:00'
recovery_target_action = 'promote'

# Base backup
pg_basebackup -h localhost -U postgres -D /backup/base -Fp -Xs -P

# pg_waldump (analisar WAL)
pg_waldump /var/lib/postgresql/14/main/pg_wal/000000010000000000000001
```
