# 📚 Tópico 01 - Data Types (Tipos de Dados)

## 🎯 Objetivo do Módulo

Dominar os tipos de dados do PostgreSQL, desde os nativos avançados até tipos customizados, possibilitando modelagem eficiente e uso correto de cada tipo em diferentes cenários.

## 📖 Conteúdo

### [1.1 - Tipos Nativos Avançados](./01-tipos-nativos-avancados.md)
- Tipos numéricos especiais (SERIAL, BIGSERIAL, IDENTITY)
- UUID - Identificadores únicos globais
- Tipos de data e hora (DATE, TIME, TIMESTAMP, TIMESTAMPTZ, INTERVAL)
- Tipos de rede (INET, CIDR, MACADDR)
- Tipo MONEY e suas peculiaridades
- Tipo BOOLEAN

### [1.2 - JSONB e Dados Semi-Estruturados](./02-jsonb-dados-semi-estruturados.md)
- Diferença entre JSON e JSONB
- Armazenamento e indexação de JSON
- Operadores e funções JSON
- Query em documentos JSON
- JSONB vs Tabelas relacionais
- Tipo HSTORE (chave-valor)

### [1.3 - Arrays e Tipos Compostos](./03-arrays-tipos-compostos.md)
- Arrays unidimensionais e multidimensionais
- Operações com arrays
- Tipos compostos (ROW)
- Range Types (INT4RANGE, TSRANGE, DATERANGE)
- Operadores de range e overlap

### [1.4 - Tipos Geométricos e Texto](./04-tipos-geometricos-texto.md)
- Tipos geométricos (POINT, LINE, CIRCLE, POLYGON)
- TEXT vs VARCHAR vs CHAR
- Pattern matching e expressões regulares
- Full Text Search básico
- Tipos de texto especializados

### [1.5 - Tipos Customizados](./05-tipos-customizados.md)
- CREATE DOMAIN - Tipos com constraints
- ENUM - Tipos enumerados
- CREATE TYPE - Tipos compostos customizados
- Quando criar tipos customizados
- Boas práticas e convenções

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos progressivos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas e explicadas

## 🎓 O que você vai aprender

Após completar este módulo, você será capaz de:

✅ Escolher o tipo de dado apropriado para cada situação  
✅ Trabalhar com UUID e SERIAL/IDENTITY eficientemente  
✅ Manipular datas, horas e timezones corretamente  
✅ Usar tipos de rede para endereços IP e MAC  
✅ Armazenar e consultar dados JSON/JSONB  
✅ Trabalhar com arrays e tipos compostos  
✅ Criar tipos customizados quando necessário  
✅ Otimizar performance através da escolha correta de tipos  

## ⏱️ Tempo Estimado

- **Leitura**: 4-5 horas
- **Prática**: 5-7 horas
- **Total**: 9-12 horas

## 🎯 Pré-requisitos

- Conhecimento básico de SQL
- Entendimento de databases e tabelas
- Familiaridade com tipos de dados básicos (INTEGER, VARCHAR)

## 💡 Por que este tópico é importante?

Tipos de dados são **fundamentais** para:
- 🎯 **Performance**: Tipos corretos melhoram velocidade e uso de memória
- 💾 **Armazenamento**: Economia de espaço em disco
- 🔒 **Integridade**: Validação de dados no nível do database
- 🚀 **Escalabilidade**: Facilitar crescimento do sistema
- 🛡️ **Segurança**: Prevenção de injeção e validação de entrada

## 🔗 Navegação

⬅️ [Voltar ao Índice Geral](../README.md) | [Começar: Tipos Nativos Avançados →](./01-tipos-nativos-avancados.md)

---

## 📊 Status

✅ **60% Completo**  
✅ Tipos Nativos Avançados - 100%  
🔄 JSONB e Dados Semi-Estruturados - Em criação  
🔄 Arrays e Tipos Compostos - Em criação  
🔄 Tipos Geométricos e Texto - Em criação  
🔄 Tipos Customizados - Em criação  
✅ Exercícios - 100%  
🔄 Gabarito - 50%  

---

## 🎯 Casos de Uso Reais

Este tópico é especialmente útil para:

1. **APIs REST**: Escolher entre UUID e SERIAL para IDs públicos
2. **E-commerce**: Valores monetários com NUMERIC, não MONEY
3. **Logs e Auditoria**: TIMESTAMPTZ para timestamps globais
4. **IoT**: Tipos de rede para dispositivos, JSONB para telemetria
5. **Multi-tenant**: UUID para dados distribuídos
6. **Analytics**: Arrays para dados agregados, JSONB para dados flexíveis

---

## 📈 Mapa de Conceitos

```
Data Types
│
├─── Tipos Nativos
│    ├─── Numéricos (SERIAL, UUID, NUMERIC)
│    ├─── Data/Hora (TIMESTAMPTZ, INTERVAL)
│    └─── Rede (INET, CIDR, MACADDR)
│
├─── Dados Semi-Estruturados
│    ├─── JSONB (recomendado)
│    ├─── JSON
│    └─── HSTORE
│
├─── Coleções
│    ├─── Arrays
│    ├─── Ranges
│    └─── Tipos Compostos
│
├─── Texto
│    ├─── TEXT/VARCHAR/CHAR
│    ├─── Pattern Matching
│    └─── Full Text Search
│
└─── Tipos Customizados
     ├─── DOMAIN
     ├─── ENUM
     └─── CREATE TYPE
```

---

**Bom estudo! 🚀**
