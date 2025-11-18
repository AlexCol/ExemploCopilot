# 📚 Tópico 07 - Triggers e Event-Driven Logic

## 🎯 Objetivo do Módulo

Dominar triggers para automação, auditoria e manutenção de integridade de dados.

## 📖 Conteúdo

### [7.1 - Triggers Básicos](./01-triggers-basicos.md)
- O que são triggers
- BEFORE vs AFTER
- INSERT, UPDATE, DELETE triggers
- Trigger functions em PL/pgSQL
- OLD e NEW records
- TG_OP e outras variáveis especiais

### [7.2 - Triggers Avançados](./02-triggers-avancados.md)
- Statement-level vs Row-level triggers
- FOR EACH ROW vs FOR EACH STATEMENT
- WHEN conditions
- Trigger ordering
- Returning NULL vs returning NEW/OLD
- Cascading triggers

### [7.3 - Event Triggers](./03-event-triggers.md)
- DDL triggers
- ddl_command_start, ddl_command_end
- sql_drop
- table_rewrite
- Casos de uso (audit DDL, prevent DROP, etc)

### [7.4 - Audit Logging com Triggers](./04-audit-logging-triggers.md)
- Audit trail pattern
- Capturando changes (INSERT/UPDATE/DELETE)
- Histórico de alterações
- Who, What, When logging
- JSONB para armazenar OLD/NEW values

### [7.5 - Performance e Boas Práticas](./05-performance-boas-praticas.md)
- Impact em performance
- Quando NÃO usar triggers
- Alternativas (constraints, views, etc)
- Debugging triggers
- Common pitfalls
- Trigger recursion

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Criar triggers para automação  
✅ Implementar audit logging robusto  
✅ Usar event triggers para DDL control  
✅ Otimizar triggers para performance  
✅ Evitar armadilhas comuns  
✅ Debugar problemas com triggers  

## ⏱️ Tempo Estimado

- **Leitura**: 3-4 horas
- **Prática**: 5-6 horas
- **Total**: 8-10 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: Triggers Básicos →](./01-triggers-basicos.md)

---

**Status**: 🔄 Conteúdo detalhado disponível sob demanda
