# 📚 Tópico 09 - Query Optimization

## 🎯 Objetivo do Módulo

Dominar análise e otimização de queries para máxima performance.

## 📖 Conteúdo

### [9.1 - EXPLAIN e EXPLAIN ANALYZE](./01-explain-explain-analyze.md)
- Lendo query plans
- EXPLAIN vs EXPLAIN ANALYZE
- EXPLAIN options (BUFFERS, VERBOSE, etc)
- Nodes types (Seq Scan, Index Scan, etc)
- Cost estimation
- Actual times vs estimated

### [9.2 - Query Planner e Estatísticas](./02-query-planner-estatisticas.md)
- Como o planner funciona
- Statistics collector
- ANALYZE command
- pg_statistics
- Histogram bounds
- Most common values (MCV)
- Tuning statistics targets

### [9.3 - Join Optimization](./03-join-optimization.md)
- Nested Loop
- Hash Join
- Merge Join
- Quando cada join é usado
- Join order optimization
- Large table joins
- work_mem tuning

### [9.4 - Subqueries vs JOINs vs CTEs](./04-subqueries-joins-ctes.md)
- Rewriting subqueries
- Correlated vs uncorrelated subqueries
- Subquery vs JOIN performance
- CTE materialization
- NOT EXISTS vs LEFT JOIN
- Optimization fences

### [9.5 - Vacuum, Analyze e Autovacuum](./05-vacuum-analyze-autovacuum.md)
- O que é VACUUM
- VACUUM vs VACUUM FULL
- Dead tuples e bloat
- ANALYZE para statistics
- Autovacuum configuration
- Tuning autovacuum
- Monitoring vacuum

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Ler e interpretar query plans  
✅ Identificar gargalos de performance  
✅ Otimizar joins complexos  
✅ Reescrever queries ineficientes  
✅ Configurar vacuum e autovacuum  
✅ Usar statistics adequadamente  

## ⏱️ Tempo Estimado

- **Leitura**: 5-6 horas
- **Prática**: 7-9 horas
- **Total**: 12-15 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: EXPLAIN →](./01-explain-explain-analyze.md)

---

**Status**: 🔄 Conteúdo detalhado disponível sob demanda
