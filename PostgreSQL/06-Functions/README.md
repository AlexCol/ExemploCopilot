# 📚 Tópico 06 - Functions e Stored Procedures

## 🎯 Objetivo do Módulo

Dominar criação de funções, stored procedures e lógica de negócio no PostgreSQL.

## 📖 Conteúdo

### [6.1 - Funções em PL/pgSQL](./01-funcoes-plpgsql.md)
- Sintaxe básica de funções
- Variáveis e tipos
- Estruturas de controle (IF, CASE, LOOP)
- RETURN e RETURN NEXT
- Error handling
- RAISE e logging

### [6.2 - Funções em SQL Puro](./02-funcoes-sql-puro.md)
- SQL functions vs PL/pgSQL
- Quando usar SQL functions
- IMMUTABLE, STABLE, VOLATILE
- Inlining e performance
- Funções de tabela (RETURNS TABLE)

### [6.3 - Stored Procedures](./03-stored-procedures.md)
- PROCEDURE vs FUNCTION
- CALL statement
- Transaction control em procedures
- COMMIT e ROLLBACK dentro de procedures
- Quando usar procedures vs functions

### [6.4 - Aggregate Functions Customizadas](./04-aggregate-functions-customizadas.md)
- CREATE AGGREGATE
- State functions
- Final functions
- Ordered-set aggregates
- Exemplos práticos (MEDIAN, etc)

### [6.5 - Security: DEFINER vs INVOKER](./05-security-definer-invoker.md)
- SECURITY DEFINER
- SECURITY INVOKER
- Privilege escalation
- Best practices de segurança
- LEAKPROOF functions

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Criar funções em PL/pgSQL e SQL puro  
✅ Implementar stored procedures com transações  
✅ Desenvolver aggregate functions customizadas  
✅ Entender security implications  
✅ Otimizar funções para performance  
✅ Tratar erros adequadamente  

## ⏱️ Tempo Estimado

- **Leitura**: 4-5 horas
- **Prática**: 6-8 horas
- **Total**: 10-13 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: Funções PL/pgSQL →](./01-funcoes-plpgsql.md)

---

**Status**: 🔄 Conteúdo detalhado disponível sob demanda
