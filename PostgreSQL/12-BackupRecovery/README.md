# 📚 Tópico 12 - Backup, Recovery e High Availability

## 🎯 Objetivo do Módulo

Dominar estratégias de backup, recuperação e alta disponibilidade no PostgreSQL.

## 📖 Conteúdo

### [12.1 - pg_dump e pg_restore](./01-pg-dump-restore.md)
- Logical backups com pg_dump
- Formatos de backup (plain, custom, directory, tar)
- pg_restore options
- Selective restore
- pg_dumpall para cluster completo
- Backup automation

### [12.2 - WAL e Point-in-Time Recovery (PITR)](./02-wal-pitr.md)
- Write-Ahead Logging (WAL)
- WAL archiving
- Base backup com pg_basebackup
- recovery.conf (versões antigas) vs recovery.signal
- Point-in-Time Recovery
- Timeline history

### [12.3 - Physical vs Logical Backups](./03-physical-logical-backups.md)
- Diferenças entre physical e logical
- Quando usar cada tipo
- pg_basebackup (physical)
- Backup incremental
- Backup paralelo
- Cloud backup strategies

### [12.4 - Replication (Streaming, Logical)](./04-replication.md)
- Streaming replication
- Synchronous vs asynchronous replication
- Standby servers (hot, warm)
- Logical replication (PostgreSQL 10+)
- Publications e subscriptions
- Monitoring replication lag

### [12.5 - Failover e High Availability](./05-failover-ha.md)
- Automatic failover
- pg_auto_failover
- Patroni
- Replication slots
- Connection pooling (PgBouncer, PgPool)
- Load balancing
- Disaster recovery planning

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Implementar backups robustos  
✅ Configurar PITR para recovery  
✅ Setup streaming replication  
✅ Implementar logical replication  
✅ Configurar alta disponibilidade  
✅ Planejar disaster recovery  

## ⏱️ Tempo Estimado

- **Leitura**: 5-6 horas
- **Prática**: 7-9 horas
- **Total**: 12-15 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: pg_dump →](./01-pg-dump-restore.md)

---

**Status**: 🔄 Conteúdo detalhado disponível sob demanda
