# 📚 Tópico 16 - History and Auditing

## 🎯 Objetivo do Módulo

Compreender todos os mecanismos de histórico, rastreamento e auditoria disponíveis no PostgreSQL, desde o histórico de comandos do cliente até sistemas complexos de versionamento de dados.

## 📖 Conteúdo

### [16.1 - Histórico de Comandos (.psql_history)](./01-psql-history.md)
- Arquivo .psql_history
- Configuração do histórico
- Comandos \s (show history)
- Busca no histórico (Ctrl+R)
- Histórico por database
- Segurança e histórico

### [16.2 - Rastreamento de Queries (pg_stat_statements)](./02-pg-stat-statements.md)
- Instalação e configuração
- Estatísticas de execução
- Identificando queries lentas
- Análise de padrões de uso
- Query normalization
- Resetar estatísticas

### [16.3 - Logs do PostgreSQL](./03-logs-postgresql.md)
- Configuração de logging
- Tipos de log (connections, statements, errors)
- log_statement vs log_min_duration_statement
- Parsing e análise de logs
- pgBadger para análise
- Rotação de logs

### [16.4 - Audit Triggers e Tabelas de Auditoria](./04-audit-triggers.md)
- Tabelas espelho de auditoria
- Triggers INSERT/UPDATE/DELETE
- Auditoria genérica com JSONB
- Capturar OLD vs NEW
- Metadados de auditoria (user, timestamp, IP)
- Proteção de tabelas de audit

### [16.5 - Temporal Tables e Versionamento](./05-temporal-tables.md)
- System-versioned tables
- Tabelas de histórico
- Consultas point-in-time
- Bi-temporal tables (valid time vs transaction time)
- Period types
- Padrão slowly changing dimensions (SCD)

### [16.6 - MVCC: Versionamento Interno](./06-mvcc.md)
- Multi-Version Concurrency Control
- xmin e xmax
- Transaction IDs
- Snapshots e visibility
- VACUUM e dead tuples
- pg_visibility extension

### [16.7 - WAL: Write-Ahead Log](./07-wal.md)
- O que é o WAL
- Estrutura do WAL
- WAL archiving
- Point-in-Time Recovery (PITR)
- pg_waldump para análise
- Replicação baseada em WAL

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 15 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Gerenciar histórico de comandos do psql  
✅ Monitorar e analisar queries executadas  
✅ Configurar e interpretar logs do PostgreSQL  
✅ Implementar audit trails completos  
✅ Criar sistemas de versionamento de dados  
✅ Entender o funcionamento interno do MVCC  
✅ Utilizar WAL para recuperação e replicação  

## 🔍 Comparação dos Mecanismos

| Mecanismo | Escopo | Persistência | Overhead | Uso Principal |
|-----------|--------|--------------|----------|---------------|
| .psql_history | Cliente | Arquivo local | Nenhum | Repetir comandos |
| pg_stat_statements | Queries | Memória (reset) | Baixo | Performance tuning |
| Logs | Servidor | Arquivos | Baixo-Médio | Debugging, compliance |
| Audit Triggers | Dados | Tabelas | Médio | Compliance, investigação |
| Temporal Tables | Dados | Tabelas | Alto | Versionamento, histórico |
| MVCC | Transações | Interno | Automático | Concorrência |
| WAL | Transações | Arquivos | Automático | Recovery, replicação |

## 🎯 Casos de Uso

### Debugging e Development
- `.psql_history`: Repetir comandos rapidamente
- `pg_stat_statements`: Identificar queries problemáticas
- Logs: Rastrear erros e comportamento

### Compliance e Auditoria
- Audit Triggers: Rastrear quem mudou o quê
- Logs: Evidências de acesso
- Temporal Tables: Histórico completo de mudanças

### Recuperação de Dados
- WAL + Backups: Point-in-Time Recovery
- Temporal Tables: Restaurar versões antigas
- MVCC: Snapshots consistentes

### Performance Tuning
- `pg_stat_statements`: Identificar queries lentas
- Logs: Analisar padrões de acesso
- MVCC: Entender bloat e VACUUM

## ⏱️ Tempo Estimado

- **Leitura**: 6-7 horas
- **Prática**: 8-10 horas
- **Total**: 14-17 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: .psql_history →](./01-psql-history.md)

---

**Status**: ✅ Módulo completo disponível
