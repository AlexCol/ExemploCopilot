# 📖 Guia de Estudos PostgreSQL - Índice Principal

Bem-vindo ao **Guia Completo e Avançado de PostgreSQL**! 🐘

## 🎯 Sobre Este Guia

Este é um guia **modular, progressivo e expansível** para dominar PostgreSQL do intermediário ao avançado.

- ✅ **15 tópicos principais** organizados por complexidade
- ✅ **75 sub-tópicos** cobrindo todos os aspectos importantes
- ✅ **Exercícios práticos** com gabaritos comentados
- ✅ **Exemplos reais** de código SQL
- ✅ **Conteúdo sob demanda** - expanda o que você precisa

## 📚 Arquivos de Navegação

| Arquivo | Descrição |
|---------|-----------|
| [📄 README.md](./README.md) | Índice completo com todos os tópicos |
| [📊 _STATUS.md](./_STATUS.md) | Status de criação de cada tópico |
| [📖 _COMO_USAR.md](./_COMO_USAR.md) | Guia de como usar este material |
| [🗺️ _MAPA_VISUAL.md](./_MAPA_VISUAL.md) | Visualização gráfica da estrutura |
| [📇 _INDICE.md](./_INDICE.md) | Este arquivo (navegação rápida) |

---

## 📋 Índice Completo dos Tópicos

### 🟢 Tópicos Completos (Pode Estudar Agora)

#### 02. Schemas e Organização de Dados ✅ 100%
Navegue para: [`02-Schemas/01-introducao-schemas.md`](./02-Schemas/01-introducao-schemas.md)

**Sub-tópicos:**
1. [Introdução a Schemas](./02-Schemas/01-introducao-schemas.md)
2. [Criando e Gerenciando Schemas](./02-Schemas/02-criando-gerenciando-schemas.md)
3. [Search Path](./02-Schemas/03-search-path.md)
4. [Permissões em Schemas](./02-Schemas/04-permissoes-schemas.md)
5. [Boas Práticas com Schemas](./02-Schemas/05-boas-praticas-schemas.md)

**Por que estudar?** Base fundamental para organização, segurança e multi-tenancy

---

### 🟡 Tópicos Parcialmente Prontos

#### 01. Data Types e Extensões de Tipos 🟡 60%
Navegue para: [`01-DataTypes/01-tipos-nativos-avancados.md`](./01-DataTypes/01-tipos-nativos-avancados.md)

**Pronto:**
- ✅ [Tipos Nativos Avançados](./01-DataTypes/01-tipos-nativos-avancados.md) - UUID, SERIAL, DATE/TIME, INET
- ✅ [Exercícios (20)](./01-DataTypes/exercicios.md) - Exercícios práticos completos
- ✅ [Gabarito](./01-DataTypes/gabarito-exercicios.md) - Soluções comentadas

**Sob demanda:**
- 🔄 JSONB e Dados Semi-Estruturados
- 🔄 Arrays e Tipos Compostos
- 🔄 Tipos Customizados (ENUM, DOMAIN, COMPOSITE)
- 🔄 Full Text Search

**Por que estudar?** Escolher tipos corretos é crucial para performance e integridade

---

### 🔵 Tópicos Estruturados (Solicite Expansão)

#### 03. Índices e Performance 🔵
[Ver Estrutura](./03-Indices/README.md) • **Muito Importante!**

**Sub-tópicos planejados:**
1. Tipos de Índices (B-tree, Hash, GiST, GIN, BRIN)
2. Quando e Como Criar Índices
3. Índices Parciais e Condicionais
4. Índices em JSONB e Arrays
5. Análise e Manutenção de Índices

**Por que estudar?** Performance crítica - um dos tópicos mais importantes

---

#### 04. Views, Materialized Views e CTEs 🔵
[Ver Estrutura](./04-Views/README.md)

**Sub-tópicos planejados:**
1. Views: Conceitos e Uso
2. Updatable Views
3. Materialized Views
4. CTEs e Recursive Queries
5. Window Functions

**Por que estudar?** Abstrações poderosas e queries analíticas complexas

---

#### 05. Constraints e Integridade de Dados 🔵
[Ver Estrutura](./05-Constraints/README.md)

**Sub-tópicos planejados:**
1. Constraints Avançadas
2. Check Constraints Complexas
3. Foreign Keys e Cascading
4. Exclusion Constraints
5. Deferrable Constraints

**Por que estudar?** Garantir integridade dos dados no database layer

---

#### 06. Functions e Stored Procedures 🔵
[Ver Estrutura](./06-Functions/README.md) • **Muito Útil!**

**Sub-tópicos planejados:**
1. Funções em PL/pgSQL
2. Funções em SQL Puro
3. Stored Procedures
4. Aggregate Functions Customizadas
5. Security Definer vs Invoker

**Por que estudar?** Automação e lógica de negócio no database

---

#### 07. Triggers e Event-Driven Logic 🔵
[Ver Estrutura](./07-Triggers/README.md)

**Sub-tópicos planejados:**
1. Triggers Básicos
2. Triggers Avançados
3. Event Triggers
4. Audit Logging com Triggers
5. Performance e Boas Práticas

**Por que estudar?** Automação avançada e auditoria

---

#### 08. Particionamento de Tabelas 🔵
[Ver Estrutura](./08-Particionamento/README.md)

**Sub-tópicos planejados:**
1. Introdução ao Particionamento
2. Particionamento por Range
3. Particionamento por List
4. Particionamento por Hash
5. Gerenciamento e Manutenção

**Por que estudar?** Essencial para grandes volumes de dados

---

#### 09. Query Optimization 🔵
[Ver Estrutura](./09-QueryOptimization/README.md) • **Crítico para Produção!**

**Sub-tópicos planejados:**
1. EXPLAIN e EXPLAIN ANALYZE
2. Query Planner e Estatísticas
3. Join Optimization
4. Subqueries vs JOINs vs CTEs
5. Vacuum, Analyze e Autovacuum

**Por que estudar?** Performance em produção depende disso

---

#### 10. Transactions e Concorrência 🔵
[Ver Estrutura](./10-Transactions/README.md)

**Sub-tópicos planejados:**
1. ACID e Transaction Isolation Levels
2. MVCC (Multi-Version Concurrency Control)
3. Locks e Deadlocks
4. Savepoints e Subtransactions
5. Transaction ID Wraparound

**Por que estudar?** Fundamental para entender concorrência

---

#### 11. Roles, Users e Permissions 🔵
[Ver Estrutura](./11-Security/README.md)

**Sub-tópicos planejados:**
1. Roles vs Users
2. Row Level Security (RLS)
3. Column Level Security
4. Policies e Grant System
5. Audit e Compliance

**Por que estudar?** Segurança é não-negociável

---

#### 12. Backup, Recovery e High Availability 🔵
[Ver Estrutura](./12-BackupRecovery/README.md) • **Essencial para DBAs**

**Sub-tópicos planejados:**
1. pg_dump e pg_restore
2. WAL e Point-in-Time Recovery
3. Physical vs Logical Backups
4. Replication (Streaming, Logical)
5. Failover e High Availability

**Por que estudar?** Não perca dados! Disaster recovery planning

---

#### 13. Extensions e Recursos Especiais 🔵
[Ver Estrutura](./13-Extensions/README.md)

**Sub-tópicos planejados:**
1. PostGIS (Dados Geoespaciais)
2. pg_stat_statements
3. Foreign Data Wrappers (FDW)
4. pgcrypto e Segurança
5. TimescaleDB (Time Series)

**Por que estudar?** Expandir capacidades do PostgreSQL

---

#### 14. Monitoramento e Troubleshooting 🔵
[Ver Estrutura](./14-Monitoring/README.md)

**Sub-tópicos planejados:**
1. System Catalogs (pg_catalog)
2. pg_stat_* Views
3. Logging e Log Analysis
4. Performance Monitoring
5. Troubleshooting Common Issues

**Por que estudar?** Diagnosticar e resolver problemas rapidamente

---

#### 15. Advanced Patterns e Architecture 🔵
[Ver Estrutura](./15-AdvancedPatterns/README.md)

**Sub-tópicos planejados:**
1. Multi-tenancy Strategies
2. Event Sourcing com PostgreSQL
3. CQRS Pattern
4. Sharding Strategies
5. Database Design Patterns

**Por que estudar?** Arquitetura de sistemas complexos

---

## 🎯 Trilhas de Estudo Recomendadas

### 🟢 Trilha Desenvolvedor Full-Stack (40-50h)
```
02 Schemas → 01 Data Types → 03 Índices → 06 Functions 
→ 04 Views → 09 Query Optimization
```

### 🟡 Trilha DBA (60-80h)
```
02 Schemas → 03 Índices → 09 Query Optimization → 10 Transactions 
→ 11 Security → 12 Backup/HA → 14 Monitoring
```

### 🔴 Trilha Arquiteto (50-70h)
```
02 Schemas → 08 Particionamento → 11 Security (RLS) 
→ 15 Advanced Patterns → 13 Extensions (FDW)
```

### ⭐ Trilha Completa (145-185h)
```
Siga a ordem numérica: 01 → 02 → 03 → ... → 15
```

---

## 🚀 Como Começar

### Para Iniciantes no PostgreSQL Avançado:
1. Leia [`_COMO_USAR.md`](./_COMO_USAR.md)
2. Estude [`02-Schemas`](./02-Schemas/01-introducao-schemas.md) (já completo!)
3. Pratique os exercícios
4. Solicite expansão do tópico 03 (Índices)

### Para Experientes buscando tópicos específicos:
1. Consulte [`_MAPA_VISUAL.md`](./_MAPA_VISUAL.md)
2. Escolha o tópico necessário
3. Leia o README do tópico
4. Solicite expansão se necessário

---

## 📞 Solicitando Expansão de Conteúdo

Quando quiser estudar um tópico específico:

```
"Crie o tópico completo 03 - Índices"
"Preciso do conteúdo de Query Optimization"
"Expanda Functions e Triggers"
```

Você receberá:
- 5 arquivos .md detalhados
- 15-20 exercícios práticos
- Gabarito com explicações
- Exemplos de código real

---

## 📊 Estatísticas do Guia

- **Tópicos totais**: 15
- **Sub-tópicos totais**: 75
- **Tópicos completos**: 1.5 (10%)
- **Arquivos criados**: 24
- **Exercícios disponíveis**: 20
- **Conteúdo escrito**: ~25.000 palavras
- **Potencial total**: ~300.000 palavras

---

## 🎓 Certificação de Conhecimento

Após completar este guia, você terá conhecimento equivalente a:
- ✅ PostgreSQL Certified Professional
- ✅ Desenvolvedor Sênior especializado em PostgreSQL
- ✅ DBA com experiência em ambientes de produção

---

## 💡 Dica Final

**Comece por aqui:** [`02-Schemas/01-introducao-schemas.md`](./02-Schemas/01-introducao-schemas.md)

Este tópico está 100% completo e é fundamental para tudo que vem depois!

---

**Bons estudos! 🐘📚**
