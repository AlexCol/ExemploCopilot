# 📚 Tópico 08 - Particionamento de Tabelas

## 🎯 Objetivo do Módulo

Dominar particionamento para gerenciar grandes volumes de dados e melhorar performance de queries.

## 📖 Conteúdo

### [8.1 - Introdução ao Particionamento](./01-introducao-particionamento.md)
- O que é particionamento
- Por que particionar
- Declarative partitioning (PostgreSQL 10+)
- Inheritance-based partitioning (legado)
- Quando particionar vs não particionar

### [8.2 - Particionamento por Range](./02-particionamento-range.md)
- PARTITION BY RANGE
- Partições por data (mensal, anual)
- Partições por valores numéricos
- DEFAULT partition
- Criação automática de partições

### [8.3 - Particionamento por List](./03-particionamento-list.md)
- PARTITION BY LIST
- Partições por categoria
- Partições por região/país
- Multi-column partitioning
- Casos de uso

### [8.4 - Particionamento por Hash](./04-particionamento-hash.md)
- PARTITION BY HASH
- Distribuição uniforme
- Número de partições
- Quando usar hash partitioning

### [8.5 - Gerenciamento e Manutenção](./05-gerenciamento-manutencao.md)
- Attach/Detach partitions
- DROP partitions antigas
- VACUUM e ANALYZE em partições
- Índices em partitions
- Constraint exclusion
- Partition pruning
- Monitoramento

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Escolher estratégia de particionamento adequada  
✅ Implementar particionamento por range, list e hash  
✅ Gerenciar partições (criar, remover, manter)  
✅ Otimizar queries em tabelas particionadas  
✅ Automatizar criação de partições  

## ⏱️ Tempo Estimado

- **Leitura**: 4-5 horas
- **Prática**: 5-7 horas
- **Total**: 9-12 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: Introdução →](./01-introducao-particionamento.md)

---

**Status**: 🔄 Conteúdo detalhado disponível sob demanda
