# 📚 Índice Completo - Data Types

## 🎯 Visão Geral

Este módulo cobre todos os tipos de dados do PostgreSQL, desde os nativos até tipos customizados.

---

## 📑 Estrutura do Módulo

### [README.md](./README.md)
Visão geral do módulo, objetivos e roadmap de aprendizado.

---

## 📖 Lições

### [1.1 - Tipos Nativos Avançados](./01-tipos-nativos-avancados.md)
**Tempo estimado:** 1h 30min

**Tópicos:**
- Tipos numéricos especiais (SERIAL, BIGSERIAL, IDENTITY)
- UUID - Identificadores únicos globais
- Tipos de data e hora (DATE, TIME, TIMESTAMP, TIMESTAMPTZ, INTERVAL)
- Tipos de rede (INET, CIDR, MACADDR)
- Tipo MONEY vs NUMERIC
- Tipo BOOLEAN

**Conceitos-chave:**
- Quando usar UUID vs SERIAL
- TIMESTAMPTZ sempre com timezone
- Operações com INTERVAL
- Operadores de rede (<<, &&, etc)

---

### [1.2 - JSONB e Dados Semi-Estruturados](./02-jsonb-dados-semi-estruturados.md)
**Tempo estimado:** 1h 30min

**Tópicos:**
- JSON vs JSONB (diferenças críticas)
- Operadores JSONB (@>, ->, ->>, etc)
- Funções de manipulação (jsonb_set, jsonb_build_object)
- Indexação GIN e jsonb_path_ops
- JSONB vs estrutura relacional
- Tipo HSTORE (legado)

**Conceitos-chave:**
- JSONB > JSON (sempre)
- Índices GIN para performance
- Quando usar JSONB vs relacional
- Queries em documentos JSON

---

### [1.3 - Arrays e Tipos Compostos](./03-arrays-tipos-compostos.md)
**Tempo estimado:** 1h 30min

**Tópicos:**
- Arrays unidimensionais e multidimensionais
- Operadores de array (@>, &&, ||, etc)
- Funções array_agg, unnest, array_append
- Tipos compostos (ROW)
- Range Types (INT4RANGE, TSRANGE, DATERANGE)
- EXCLUDE constraints com ranges

**Conceitos-chave:**
- Arrays são 1-indexed
- GIN index para arrays
- GiST index para ranges
- Quando usar array vs tabela relacional

---

### [1.4 - Tipos Geométricos e Texto](./04-tipos-geometricos-texto.md)
**Tempo estimado:** 1h 30min

**Tópicos:**
- Tipos geométricos 2D (POINT, CIRCLE, POLYGON, etc)
- TEXT vs VARCHAR vs CHAR
- Pattern matching (LIKE, ILIKE)
- Expressões regulares (~, ~*, regexp_match)
- Full Text Search (TSVECTOR, TSQUERY)
- Indexação de texto (GIN)

**Conceitos-chave:**
- PostGIS para geolocalização real
- TEXT é o padrão recomendado
- CHAR apenas para códigos fixos
- tsvector + GIN para busca de texto

---

### [1.5 - Tipos Customizados](./05-tipos-customizados.md)
**Tempo estimado:** 1h 30min

**Tópicos:**
- CREATE DOMAIN (tipos com constraints)
- ENUM (tipos enumerados)
- CREATE TYPE (tipos compostos)
- Gerenciamento de tipos (ALTER, DROP)
- Quando criar tipos customizados
- Boas práticas e convenções

**Conceitos-chave:**
- DOMAIN para validações reutilizáveis
- ENUM para conjuntos fixos
- Tipos compostos para estruturas
- ENUM é difícil de alterar

---

## 📝 Prática

### [Exercícios](./exercicios.md)
**20 exercícios progressivos** cobrindo todos os tópicos:

- Ex 1-2: SERIAL vs UUID, IDENTITY
- Ex 3-5: Timestamps, datas, INTERVAL
- Ex 6-7: Tipos de rede (INET, CIDR)
- Ex 8: MONEY vs NUMERIC
- Ex 9: BOOLEAN (sistema de tarefas)
- Ex 10: UUID em sistemas distribuídos
- Ex 11: Formatação de datas
- Ex 12: MAC Address
- Ex 13: Queries complexas com data/hora
- Ex 14: DOMAIN customizado
- Ex 15: IPv6
- Ex 16: Comparação de performance
- Ex 17: INTERVAL avançado
- Ex 18: Migração de tipos
- Ex 19: Sistema de logs (JSONB)
- Ex 20: Desafio final (sistema completo)

### [Gabarito](./gabarito-exercicios.md)
**Soluções comentadas** de todos os exercícios com explicações detalhadas.

---

## 🗺️ Mapas de Aprendizado

### Ordem Recomendada (Linear)
```
1. Tipos Nativos Avançados
   ↓
2. JSONB e Dados Semi-Estruturados
   ↓
3. Arrays e Tipos Compostos
   ↓
4. Tipos Geométricos e Texto
   ↓
5. Tipos Customizados
   ↓
6. Exercícios
```

### Trilhas por Interesse

**🚀 Backend/API Development:**
1. Tipos Nativos (UUID, TIMESTAMPTZ)
2. JSONB (API payloads)
3. Tipos Customizados (DOMAIN, ENUM)

**📊 Data Analytics:**
1. Tipos Nativos (TIMESTAMPTZ, INTERVAL)
2. Arrays (agregações)
3. Range Types (períodos)

**🛡️ DevOps/Infraestrutura:**
1. Tipos de Rede (INET, CIDR, MACADDR)
2. JSONB (configurações, logs)
3. Tipos Geométricos (monitoramento)

**🔍 Full-Stack:**
Todos os tópicos em ordem linear

---

## 🎯 Checklist de Domínio

Use esta checklist para verificar seu progresso:

### Tipos Nativos
- [ ] Entendo diferença entre SERIAL, BIGSERIAL e IDENTITY
- [ ] Sei quando usar UUID vs SERIAL
- [ ] Sempre uso TIMESTAMPTZ (não TIMESTAMP)
- [ ] Domino operações com INTERVAL
- [ ] Sei usar tipos de rede (INET, CIDR)
- [ ] Entendo por que evitar MONEY

### JSONB
- [ ] Sei diferença entre JSON e JSONB
- [ ] Domino operadores JSONB (@>, ->, ->>)
- [ ] Sei criar índices GIN para JSONB
- [ ] Entendo quando usar JSONB vs relacional
- [ ] Consigo fazer queries complexas em JSON

### Arrays e Ranges
- [ ] Sei declarar e manipular arrays
- [ ] Conheço operadores de array (@>, &&)
- [ ] Entendo quando usar array vs tabela
- [ ] Domino Range Types
- [ ] Sei usar EXCLUDE constraints

### Texto e Geometria
- [ ] Sei diferença entre TEXT, VARCHAR, CHAR
- [ ] Domino pattern matching (LIKE, regex)
- [ ] Entendo Full Text Search básico
- [ ] Conheço limitações de tipos geométricos
- [ ] Sei quando usar PostGIS

### Tipos Customizados
- [ ] Sei criar DOMAINs com constraints
- [ ] Entendo quando usar ENUM
- [ ] Consigo criar tipos compostos
- [ ] Conheço limitações de cada tipo customizado
- [ ] Sei gerenciar tipos (ALTER, DROP)

---

## 📚 Recursos Complementares

### Documentação Oficial
- [PostgreSQL Data Types](https://www.postgresql.org/docs/current/datatype.html)
- [JSON Functions](https://www.postgresql.org/docs/current/functions-json.html)
- [Array Functions](https://www.postgresql.org/docs/current/functions-array.html)
- [Pattern Matching](https://www.postgresql.org/docs/current/functions-matching.html)

### Extensões Relacionadas
- **PostGIS**: Geolocalização e GIS
- **hstore**: Chave-valor (legado)
- **uuid-ossp**: Geração de UUIDs
- **pg_trgm**: Busca de texto similar

---

## 🔗 Navegação

⬅️ [Voltar ao Índice Geral](../README.md) | [Ver Status →](./_STATUS.md) | [Como Usar →](./_COMO_USAR.md)

---

**Última atualização:** Novembro 2025  
**Status:** ✅ Completo (100%)
