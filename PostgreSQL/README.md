# PostgreSQL - Guia de Estudos Avançado

Bem-vindo ao guia de estudos avançado de PostgreSQL! Este repositório contém aulas organizadas por tópicos para aprofundar seu conhecimento em PostgreSQL.

> **Pré-requisito**: Conhecimento básico de SQL (SELECT, INSERT, UPDATE, DELETE, JOINs, etc.)

## 🗺️ Roadmap de Estudos

### 📊 Fundamentos Avançados

#### **01. Data Types e Extensões de Tipos**
- [1.1 - Tipos Nativos Avançados](./01-DataTypes/01-tipos-nativos-avancados.md)
- [1.2 - JSONB e Dados Semi-Estruturados](./01-DataTypes/02-jsonb-dados-semi-estruturados.md)
- [1.3 - Arrays e Tipos Compostos](./01-DataTypes/03-arrays-tipos-compostos.md)
- [1.4 - Tipos Customizados (ENUM, DOMAIN, COMPOSITE)](./01-DataTypes/04-tipos-customizados.md)
- [1.5 - Full Text Search (tsvector, tsquery)](./01-DataTypes/05-full-text-search.md)

#### **02. Schemas e Organização de Dados**
- [2.1 - Introdução a Schemas](./02-Schemas/01-introducao-schemas.md)
- [2.2 - Criando e Gerenciando Schemas](./02-Schemas/02-criando-gerenciando-schemas.md)
- [2.3 - Search Path](./02-Schemas/03-search-path.md)
- [2.4 - Permissões em Schemas](./02-Schemas/04-permissoes-schemas.md)
- [2.5 - Boas Práticas com Schemas](./02-Schemas/05-boas-praticas-schemas.md)

#### **03. Índices e Performance**
- [3.1 - Tipos de Índices (B-tree, Hash, GiST, GIN, BRIN)](./03-Indices/01-tipos-indices.md)
- [3.2 - Quando e Como Criar Índices](./03-Indices/02-quando-como-criar-indices.md)
- [3.3 - Índices Parciais e Condicionais](./03-Indices/03-indices-parciais-condicionais.md)
- [3.4 - Índices em JSONB e Arrays](./03-Indices/04-indices-jsonb-arrays.md)
- [3.5 - Análise e Manutenção de Índices](./03-Indices/05-analise-manutencao-indices.md)

#### **04. Views, Materialized Views e CTEs**
- [4.1 - Views: Conceitos e Uso](./04-Views/01-views-conceitos-uso.md)
- [4.2 - Updatable Views](./04-Views/02-updatable-views.md)
- [4.3 - Materialized Views](./04-Views/03-materialized-views.md)
- [4.4 - CTEs e Recursive Queries](./04-Views/04-ctes-recursive-queries.md)
- [4.5 - Window Functions](./04-Views/05-window-functions.md)

### 🔧 Programabilidade e Automação

#### **05. Constraints e Integridade de Dados**
- [5.1 - Constraints Avançadas](./05-Constraints/01-constraints-avancadas.md)
- [5.2 - Check Constraints Complexas](./05-Constraints/02-check-constraints-complexas.md)
- [5.3 - Foreign Keys e Cascading](./05-Constraints/03-foreign-keys-cascading.md)
- [5.4 - Exclusion Constraints](./05-Constraints/04-exclusion-constraints.md)
- [5.5 - Deferrable Constraints](./05-Constraints/05-deferrable-constraints.md)

#### **06. Functions e Stored Procedures**
- [6.1 - Funções em PL/pgSQL](./06-Functions/01-funcoes-plpgsql.md)
- [6.2 - Funções em SQL Puro](./06-Functions/02-funcoes-sql-puro.md)
- [6.3 - Stored Procedures (CALL)](./06-Functions/03-stored-procedures.md)
- [6.4 - Aggregate Functions Customizadas](./06-Functions/04-aggregate-functions-customizadas.md)
- [6.5 - Security Definer vs Invoker](./06-Functions/05-security-definer-invoker.md)

#### **07. Triggers e Event-Driven Logic**
- [7.1 - Triggers Básicos](./07-Triggers/01-triggers-basicos.md)
- [7.2 - Triggers Avançados (Statement vs Row)](./07-Triggers/02-triggers-avancados.md)
- [7.3 - Event Triggers](./07-Triggers/03-event-triggers.md)
- [7.4 - Audit Logging com Triggers](./07-Triggers/04-audit-logging-triggers.md)
- [7.5 - Performance e Boas Práticas](./07-Triggers/05-performance-boas-praticas.md)

### 📈 Escalabilidade e Performance

#### **08. Particionamento de Tabelas**
- [8.1 - Introdução ao Particionamento](./08-Particionamento/01-introducao-particionamento.md)
- [8.2 - Particionamento por Range](./08-Particionamento/02-particionamento-range.md)
- [8.3 - Particionamento por List](./08-Particionamento/03-particionamento-list.md)
- [8.4 - Particionamento por Hash](./08-Particionamento/04-particionamento-hash.md)
- [8.5 - Gerenciamento e Manutenção](./08-Particionamento/05-gerenciamento-manutencao.md)

#### **09. Query Optimization**
- [9.1 - EXPLAIN e EXPLAIN ANALYZE](./09-QueryOptimization/01-explain-explain-analyze.md)
- [9.2 - Query Planner e Estatísticas](./09-QueryOptimization/02-query-planner-estatisticas.md)
- [9.3 - Join Optimization](./09-QueryOptimization/03-join-optimization.md)
- [9.4 - Subqueries vs JOINs vs CTEs](./09-QueryOptimization/04-subqueries-joins-ctes.md)
- [9.5 - Vacuum, Analyze e Autovacuum](./09-QueryOptimization/05-vacuum-analyze-autovacuum.md)

#### **10. Transactions e Concorrência**
- [10.1 - ACID e Transaction Isolation Levels](./10-Transactions/01-acid-isolation-levels.md)
- [10.2 - MVCC (Multi-Version Concurrency Control)](./10-Transactions/02-mvcc.md)
- [10.3 - Locks e Deadlocks](./10-Transactions/03-locks-deadlocks.md)
- [10.4 - Savepoints e Subtransactions](./10-Transactions/04-savepoints-subtransactions.md)
- [10.5 - Transaction ID Wraparound](./10-Transactions/05-transaction-id-wraparound.md)

### 🔐 Segurança e Administração

#### **11. Roles, Users e Permissions**
- [11.1 - Roles vs Users](./11-Security/01-roles-users.md)
- [11.2 - Row Level Security (RLS)](./11-Security/02-row-level-security.md)
- [11.3 - Column Level Security](./11-Security/03-column-level-security.md)
- [11.4 - Policies e Grant System](./11-Security/04-policies-grant-system.md)
- [11.5 - Audit e Compliance](./11-Security/05-audit-compliance.md)

#### **12. Backup, Recovery e High Availability**
- [12.1 - pg_dump e pg_restore](./12-BackupRecovery/01-pg-dump-restore.md)
- [12.2 - WAL e Point-in-Time Recovery](./12-BackupRecovery/02-wal-pitr.md)
- [12.3 - Physical vs Logical Backups](./12-BackupRecovery/03-physical-logical-backups.md)
- [12.4 - Replication (Streaming, Logical)](./12-BackupRecovery/04-replication.md)
- [12.5 - Failover e High Availability](./12-BackupRecovery/05-failover-ha.md)

### 🚀 Tópicos Avançados

#### **13. Extensions e Recursos Especiais**
- [13.1 - PostGIS (Dados Geoespaciais)](./13-Extensions/01-postgis.md)
- [13.2 - pg_stat_statements](./13-Extensions/02-pg-stat-statements.md)
- [13.3 - Foreign Data Wrappers (FDW)](./13-Extensions/03-foreign-data-wrappers.md)
- [13.4 - pgcrypto e Segurança](./13-Extensions/04-pgcrypto-seguranca.md)
- [13.5 - TimescaleDB (Time Series)](./13-Extensions/05-timescaledb.md)

#### **14. Monitoramento e Troubleshooting**
- [14.1 - System Catalogs (pg_catalog)](./14-Monitoring/01-system-catalogs.md)
- [14.2 - pg_stat_* Views](./14-Monitoring/02-pg-stat-views.md)
- [14.3 - Logging e Log Analysis](./14-Monitoring/03-logging-log-analysis.md)
- [14.4 - Performance Monitoring](./14-Monitoring/04-performance-monitoring.md)
- [14.5 - Troubleshooting Common Issues](./14-Monitoring/05-troubleshooting.md)

#### **15. Advanced Patterns e Architecture**
- [15.1 - Multi-tenancy Strategies](./15-AdvancedPatterns/01-multi-tenancy-strategies.md)
- [15.2 - Event Sourcing com PostgreSQL](./15-AdvancedPatterns/02-event-sourcing.md)
- [15.3 - CQRS Pattern](./15-AdvancedPatterns/03-cqrs-pattern.md)
- [15.4 - Sharding Strategies](./15-AdvancedPatterns/04-sharding-strategies.md)
- [15.5 - Database Design Patterns](./15-AdvancedPatterns/05-database-design-patterns.md)

## 🎯 Como usar este guia

1. **Siga a ordem recomendada** - Os tópicos são progressivos
2. **Pratique cada conceito** - Todos os arquivos têm exercícios práticos
3. **Use um ambiente de teste** - Não pratique em produção!
4. **Cada arquivo é independente** - Mas se conectam em conceitos
5. **Links de navegação** - Use para se mover entre os tópicos

## 📊 Legenda de Complexidade

- 🟢 **Fundamental** - Base para outros conceitos
- 🟡 **Intermediário** - Requer conhecimento dos fundamentos
- 🔴 **Avançado** - Para otimização e casos específicos

## 🛠️ Ferramentas Recomendadas

- **PostgreSQL 15+** (versão mais recente recomendada)
- **pgAdmin 4** ou **DBeaver** (GUI)
- **psql** (CLI - essencial para prática)
- **Docker** (para criar ambientes isolados)

## 📖 Sobre

Este material foi criado para ser um guia prático e profundo sobre PostgreSQL, focando em:
- ✅ Conceitos avançados explicados claramente
- ✅ Exemplos práticos e reais
- ✅ Exercícios hands-on
- ✅ Boas práticas e antipadrões
- ✅ Performance e otimização
- ✅ Segurança e escalabilidade

## 🎓 Pré-requisitos

Antes de começar, você deve estar confortável com:
- SQL básico (SELECT, INSERT, UPDATE, DELETE)
- JOINs (INNER, LEFT, RIGHT, FULL)
- Agregações (GROUP BY, HAVING)
- Subqueries básicas
- Conceitos de normalização de dados

---

**Comece seus estudos:**
- 🆕 Iniciante em PostgreSQL? → [Data Types e Extensões →](./01-DataTypes/01-tipos-nativos-avancados.md)
- 🎯 Conhece o básico? → [Schemas →](./02-Schemas/01-introducao-schemas.md)
- 🚀 Foco em Performance? → [Índices →](./03-Indices/01-tipos-indices.md)
