# 📚 Tópico 01 - Data Types (Tipos de Dados)

## 🎯 Objetivo

Dominar os tipos de dados do PostgreSQL para modelagem eficiente e uso correto em diferentes cenários.

## 📖 Conteúdo

### [1.1 - Tipos Nativos Avançados](./01-tipos-nativos-avancados.md)
- SERIAL, BIGSERIAL, IDENTITY
- UUID - Identificadores únicos globais
- DATE, TIME, TIMESTAMP, TIMESTAMPTZ, INTERVAL
- INET, CIDR, MACADDR (tipos de rede)
- MONEY vs NUMERIC
- BOOLEAN

### [1.2 - JSONB e Dados Semi-Estruturados](./02-jsonb-dados-semi-estruturados.md)
- JSON vs JSONB
- Operadores e funções JSONB
- Indexação GIN
- JSONB vs Tabelas relacionais
- HSTORE

### [1.3 - Arrays e Tipos Compostos](./03-arrays-tipos-compostos.md)
- Arrays unidimensionais e multidimensionais
- Tipos compostos (ROW)
- Range Types (INT4RANGE, TSRANGE, DATERANGE)
- Operadores e indexação

### [1.4 - Tipos Geométricos e Texto](./04-tipos-geometricos-texto.md)
- Tipos geométricos 2D (POINT, CIRCLE, POLYGON)
- TEXT vs VARCHAR vs CHAR
- Pattern matching e expressões regulares
- Full Text Search (TSVECTOR, TSQUERY)

### [1.5 - Tipos Customizados](./05-tipos-customizados.md)
- CREATE DOMAIN (tipos com constraints)
- ENUM (tipos enumerados)
- CREATE TYPE (tipos compostos)
- Quando criar tipos customizados

## 📝 Exercícios

- [Exercícios](./exercicios.md) - 20 exercícios práticos
- [Gabarito](./gabarito-exercicios.md) - Soluções comentadas

## 🔗 Navegação

⬅️ [Voltar ao Índice Geral](../README.md) | [Começar →](./01-tipos-nativos-avancados.md)
