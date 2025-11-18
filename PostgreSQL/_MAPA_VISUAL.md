# 🗺️ Mapa Visual do Guia PostgreSQL

```
┌─────────────────────────────────────────────────────────────────────┐
│                   GUIA COMPLETO POSTGRESQL                          │
│                   15 Tópicos • 75 Sub-tópicos                       │
└─────────────────────────────────────────────────────────────────────┘

🟢 = Completo  🟡 = Parcial  🔵 = Estruturado (sob demanda)

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  FUNDAMENTOS AVANÇADOS                                            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

📦 01. DATA TYPES 🟡
    ├─ 🟢 Tipos Nativos (UUID, SERIAL, DATE/TIME, INET)
    ├─ 🔵 JSONB e Dados Semi-Estruturados  
    ├─ 🔵 Arrays e Tipos Compostos
    ├─ 🔵 Tipos Customizados (ENUM, DOMAIN)
    ├─ 🔵 Full Text Search
    └─ 🟢 20 Exercícios + Gabarito

📂 02. SCHEMAS 🟢 ⭐ COMPLETO
    ├─ 🟢 Introdução a Schemas
    ├─ 🟢 Criando e Gerenciando  
    ├─ 🟢 Search Path
    ├─ 🟢 Permissões
    └─ 🟢 Boas Práticas

📇 03. ÍNDICES 🔵
    ├─ Tipos (B-tree, GIN, GiST, BRIN, Hash)
    ├─ Quando e Como Criar
    ├─ Índices Parciais/Condicionais
    ├─ Índices JSONB/Arrays
    └─ Manutenção e Análise

👁️ 04. VIEWS & CTEs 🔵  
    ├─ Views Básicas
    ├─ Updatable Views
    ├─ Materialized Views
    ├─ CTEs e Recursive Queries
    └─ Window Functions

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  PROGRAMABILIDADE E AUTOMAÇÃO                                     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

🔒 05. CONSTRAINTS 🔵
    ├─ Constraints Avançadas
    ├─ Check Complexas
    ├─ Foreign Keys + Cascading
    ├─ Exclusion Constraints
    └─ Deferrable Constraints

⚙️ 06. FUNCTIONS 🔵
    ├─ PL/pgSQL Functions
    ├─ SQL Functions
    ├─ Stored Procedures
    ├─ Aggregate Functions
    └─ Security (DEFINER/INVOKER)

⚡ 07. TRIGGERS 🔵
    ├─ Triggers Básicos
    ├─ Triggers Avançados
    ├─ Event Triggers (DDL)
    ├─ Audit Logging
    └─ Performance & Best Practices

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ESCALABILIDADE E PERFORMANCE                                     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

📊 08. PARTICIONAMENTO 🔵
    ├─ Introdução
    ├─ Range Partitioning
    ├─ List Partitioning
    ├─ Hash Partitioning
    └─ Gerenciamento

🚀 09. QUERY OPTIMIZATION 🔵 ⭐ CRÍTICO
    ├─ EXPLAIN / EXPLAIN ANALYZE
    ├─ Query Planner
    ├─ Join Optimization
    ├─ Subqueries vs CTEs
    └─ VACUUM & Autovacuum

🔄 10. TRANSACTIONS 🔵
    ├─ ACID & Isolation Levels
    ├─ MVCC
    ├─ Locks & Deadlocks
    ├─ Savepoints
    └─ XID Wraparound

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  SEGURANÇA E ADMINISTRAÇÃO                                        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

🛡️ 11. SECURITY 🔵
    ├─ Roles & Users
    ├─ Row Level Security (RLS)
    ├─ Column Level Security
    ├─ Policies & Grants
    └─ Audit & Compliance

💾 12. BACKUP & HA 🔵
    ├─ pg_dump / pg_restore
    ├─ WAL & PITR
    ├─ Physical vs Logical Backups
    ├─ Replication
    └─ Failover & HA

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  TÓPICOS AVANÇADOS                                                ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

🧩 13. EXTENSIONS 🔵
    ├─ PostGIS (Geoespacial)
    ├─ pg_stat_statements
    ├─ Foreign Data Wrappers
    ├─ pgcrypto
    └─ TimescaleDB

📈 14. MONITORING 🔵
    ├─ System Catalogs
    ├─ pg_stat_* Views
    ├─ Logging & Analysis
    ├─ Performance Monitoring
    └─ Troubleshooting

🏗️ 15. ADVANCED PATTERNS 🔵
    ├─ Multi-tenancy Strategies
    ├─ Event Sourcing
    ├─ CQRS Pattern
    ├─ Sharding
    └─ Design Patterns

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ESTATÍSTICAS                                                     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

📊 Progresso Atual:
    • Tópicos com estrutura: 15/15 (100%) ✅
    • Tópicos completos: 1.5/15 (10%)
    • Arquivos criados: 24
    • Exercícios disponíveis: 20 (com gabarito)
    • Palavras escritas: ~25.000
    • Potencial total: ~300.000 palavras

⏱️ Tempo Total Estimado de Estudo:
    • Leitura completa: 60-75 horas
    • Prática e exercícios: 85-110 horas  
    • Total: 145-185 horas (~6 meses, 1h/dia)

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  TRILHAS DE ESTUDO RECOMENDADAS                                   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

🎯 TRILHA DESENVOLVEDOR (Básico → Intermediário)
   01 Data Types → 02 Schemas → 03 Índices → 05 Constraints
   → 06 Functions → 04 Views → 09 Query Optimization

🎯 TRILHA DBA (Administração & Performance)
   02 Schemas → 03 Índices → 09 Query Optimization 
   → 10 Transactions → 11 Security → 12 Backup/HA 
   → 14 Monitoring

🎯 TRILHA ARQUITETO (Design & Escalabilidade)
   02 Schemas → 08 Particionamento → 10 Transactions
   → 11 Security (RLS) → 15 Advanced Patterns
   → 13 Extensions (FDW, Citus)

🎯 TRILHA FULL-STACK (Completa)
   Siga a ordem 01 → 15 (145-185h de estudo)

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  COMO USAR                                                        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

1️⃣ Leia o README.md de cada tópico para ver o escopo
2️⃣ Estude os tópicos completos (Schemas está 100% pronto!)
3️⃣ Solicite expansão de tópicos conforme necessidade
4️⃣ Pratique TODOS os exercícios
5️⃣ Aplique em projetos reais

💡 Dica: Comece por SCHEMAS (02) - está completo e é fundamental!

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ARQUIVOS IMPORTANTES                                             ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

📄 README.md              → Índice geral do guia
📄 _STATUS.md             → Status de criação de cada tópico
📄 _COMO_USAR.md          → Instruções detalhadas de uso
📄 _MAPA_VISUAL.md        → Este arquivo (visão geral)

📁 XX-NomeTópico/
   └─ README.md           → Índice e descrição do tópico
   └─ 01-05.md            → Conteúdo das aulas
   └─ exercicios.md       → Exercícios práticos
   └─ gabarito-exercicios.md → Soluções comentadas

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  PRÓXIMOS PASSOS                                                  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

✅ Comece estudando: PostgreSQL/02-Schemas/01-introducao-schemas.md
✅ Depois solicite: "Crie o tópico completo de Índices"
✅ Ou: "Preciso de Query Optimization completo"

🚀 Bons estudos! 🐘
```
