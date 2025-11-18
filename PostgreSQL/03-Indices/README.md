# 📚 Tópico 03 - Índices e Performance

## 🎯 Objetivo do Módulo

Dominar o uso de índices no PostgreSQL para otimização de queries e performance do banco de dados.

## 📖 Conteúdo

### [3.1 - Tipos de Índices](./01-tipos-indices.md)
- B-tree (padrão)
- Hash
- GiST (Generalized Search Tree)
- GIN (Generalized Inverted Index)
- BRIN (Block Range Index)
- SP-GiST (Space-Partitioned GiST)
- Quando usar cada tipo

### [3.2 - Quando e Como Criar Índices](./02-quando-como-criar-indices.md)
- Análise de queries com EXPLAIN
- Identificando necessidade de índices
- Sintaxe e opções de criação
- Índices compostos (multi-column)
- Ordem das colunas em índices compostos

### [3.3 - Índices Parciais e Condicionais](./03-indices-parciais-condicionais.md)
- Partial indexes (WHERE clause)
- Unique indexes parciais
- Expression indexes
- Covering indexes (INCLUDE)

### [3.4 - Índices em JSONB e Arrays](./04-indices-jsonb-arrays.md)
- GIN indexes para JSONB
- Operadores jsonb_path_ops vs jsonb_ops
- Índices em elementos de array
- Índices em full-text search

### [3.5 - Análise e Manutenção de Índices](./05-analise-manutencao-indices.md)
- REINDEX e quando usar
- Monitoramento de uso de índices
- Índices bloated e fragmentação
- Statistics e ANALYZE
- Índices não utilizados

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

Após completar este módulo, você será capaz de:

✅ Escolher o tipo de índice adequado para cada situação  
✅ Criar índices eficientes que realmente melhoram performance  
✅ Usar EXPLAIN para analisar uso de índices  
✅ Criar índices parciais para economizar espaço  
✅ Otimizar consultas em JSONB e arrays  
✅ Manter e monitorar índices em produção  
✅ Identificar e remover índices desnecessários  

## ⏱️ Tempo Estimado

- **Leitura**: 3-4 horas
- **Prática**: 4-6 horas
- **Total**: 7-10 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: Tipos de Índices →](./01-tipos-indices.md)

---

## 💡 Dica

Índices são cruciais para performance! Este é um dos tópicos mais importantes para sistemas em produção. Dedique tempo extra aos exercícios práticos.

**Status**: 🔄 Conteúdo detalhado disponível sob demanda - solicite criação dos arquivos específicos.
