# 📚 Tópico 15 - Advanced Patterns e Architecture

## 🎯 Objetivo do Módulo

Dominar padrões arquiteturais avançados e design patterns para PostgreSQL.

## 📖 Conteúdo

### [15.1 - Multi-tenancy Strategies](./01-multi-tenancy-strategies.md)
- Schema per tenant
- Database per tenant
- Shared schema com RLS
- Hybrid approaches
- Pros e cons de cada estratégia
- Migration entre estratégias

### [15.2 - Event Sourcing com PostgreSQL](./02-event-sourcing.md)
- Conceitos de Event Sourcing
- Event store design
- Projections
- Snapshots
- CQRS integration
- Event replay

### [15.3 - CQRS Pattern](./03-cqrs-pattern.md)
- Command Query Responsibility Segregation
- Separate read/write models
- Materialized views para read model
- Logical replication para sync
- Consistency guarantees

### [15.4 - Sharding Strategies](./04-sharding-strategies.md)
- Horizontal sharding
- Vertical sharding
- Hash-based sharding
- Range-based sharding
- Foreign Data Wrappers para sharding
- Citus extension
- Application-level sharding

### [15.5 - Database Design Patterns](./05-database-design-patterns.md)
- Soft delete pattern
- Audit trail pattern
- Versioning pattern (temporal tables)
- Polymorphic associations
- EAV (Entity-Attribute-Value) quando apropriado
- Star schema para analytics
- Denormalization strategies

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Implementar multi-tenancy eficientemente  
✅ Aplicar Event Sourcing e CQRS  
✅ Design sharding strategies  
✅ Usar design patterns avançados  
✅ Arquitetar sistemas escaláveis  

## ⏱️ Tempo Estimado

- **Leitura**: 5-6 horas
- **Prática**: 8-10 horas
- **Total**: 13-16 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: Multi-tenancy →](./01-multi-tenancy-strategies.md)

---

**Status**: 🔄 Conteúdo detalhado disponível sob demanda
