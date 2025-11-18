# 📚 Tópico 10 - Transactions e Concorrência

## 🎯 Objetivo do Módulo

Dominar transações, isolation levels e controle de concorrência no PostgreSQL.

## 📖 Conteúdo

### [10.1 - ACID e Transaction Isolation Levels](./01-acid-isolation-levels.md)
- Propriedades ACID
- READ UNCOMMITTED (não suportado realmente)
- READ COMMITTED (padrão)
- REPEATABLE READ
- SERIALIZABLE
- Fenômenos (dirty read, non-repeatable read, phantom read)
- Choosing isolation level

### [10.2 - MVCC (Multi-Version Concurrency Control)](./02-mvcc.md)
- Como MVCC funciona
- Transaction IDs (xid)
- Tuple visibility rules
- Snapshots
- Por que PostgreSQL não tem read locks
- Write-Write conflicts

### [10.3 - Locks e Deadlocks](./03-locks-deadlocks.md)
- Tipos de locks (row, table, advisory)
- Lock modes (ACCESS SHARE, ROW EXCLUSIVE, etc)
- Explicit locking (LOCK TABLE, FOR UPDATE)
- Deadlock detection
- pg_locks view
- Lock monitoring e troubleshooting

### [10.4 - Savepoints e Subtransactions](./04-savepoints-subtransactions.md)
- SAVEPOINT command
- ROLLBACK TO SAVEPOINT
- Nested transactions
- Exception handling em PL/pgSQL
- Performance implications

### [10.5 - Transaction ID Wraparound](./05-transaction-id-wraparound.md)
- O que é XID wraparound
- Por que é problema
- Frozen tuples
- VACUUM FREEZE
- Monitoring XID age
- Preventing wraparound

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Escolher isolation level adequado  
✅ Entender MVCC profundamente  
✅ Gerenciar locks e evitar deadlocks  
✅ Usar savepoints efetivamente  
✅ Prevenir transaction wraparound  
✅ Debugar problemas de concorrência  

## ⏱️ Tempo Estimado

- **Leitura**: 4-5 horas
- **Prática**: 5-7 horas
- **Total**: 9-12 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: ACID e Isolation →](./01-acid-isolation-levels.md)

---

**Status**: 🔄 Conteúdo detalhado disponível sob demanda
