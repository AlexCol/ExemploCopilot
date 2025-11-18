# 🗺️ Mapa Visual - Data Types

```
┌─────────────────────────────────────────────────────────────────────┐
│                    📚 MÓDULO: DATA TYPES                            │
│                 PostgreSQL - Tipos de Dados                          │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     🎯 ESTRUTURA DO MÓDULO                          │
└─────────────────────────────────────────────────────────────────────┘

    📖 1.1 - TIPOS NATIVOS AVANÇADOS
    ├─ 🔢 Numéricos Especiais
    │  ├─ SERIAL / BIGSERIAL
    │  ├─ IDENTITY (ALWAYS / BY DEFAULT)
    │  └─ NUMERIC vs MONEY
    │
    ├─ 🆔 UUID
    │  ├─ uuid_generate_v4()
    │  ├─ UUID vs SERIAL
    │  └─ Uso em sistemas distribuídos
    │
    ├─ 📅 Data/Hora
    │  ├─ DATE, TIME, TIMESTAMP
    │  ├─ ⭐ TIMESTAMPTZ (recomendado)
    │  ├─ INTERVAL (durações)
    │  └─ Funções: AGE, EXTRACT, TO_CHAR
    │
    ├─ 🌐 Tipos de Rede
    │  ├─ INET (IP com/sem máscara)
    │  ├─ CIDR (range de rede)
    │  ├─ MACADDR (endereço MAC)
    │  └─ Operadores: <<, >>, &&
    │
    └─ ✅ BOOLEAN
       └─ TRUE, FALSE, NULL

    ────────────────────────────────────────────────

    📖 1.2 - JSONB E DADOS SEMI-ESTRUTURADOS
    ├─ 🔄 JSON vs JSONB
    │  ├─ JSON: texto puro
    │  └─ ⭐ JSONB: binário (recomendado)
    │
    ├─ 🔧 Operadores JSONB
    │  ├─ -> / ->> (acesso)
    │  ├─ #> / #>> (path)
    │  ├─ @> / <@ (contenção)
    │  ├─ ? / ?| / ?& (existência)
    │  └─ || (merge)
    │
    ├─ 📦 Funções
    │  ├─ jsonb_set
    │  ├─ jsonb_build_object
    │  ├─ jsonb_array_elements
    │  └─ jsonb_each
    │
    ├─ 🚀 Indexação
    │  ├─ GIN (padrão)
    │  └─ GIN jsonb_path_ops
    │
    └─ 🗂️ HSTORE (legado)
       └─ Chave-valor simples

    ────────────────────────────────────────────────

    📖 1.3 - ARRAYS E TIPOS COMPOSTOS
    ├─ 📚 Arrays
    │  ├─ Declaração: TEXT[], INT[]
    │  ├─ Acesso: arr[1] (1-indexed!)
    │  ├─ Operadores: @>, &&, ||
    │  ├─ Funções: array_agg, unnest
    │  └─ Índice: GIN
    │
    ├─ 🧩 Tipos Compostos (ROW)
    │  ├─ CREATE TYPE ... AS (...)
    │  ├─ Acesso: (campo).subcampo
    │  └─ Uso em funções
    │
    └─ 📏 Range Types
       ├─ INT4RANGE, NUMRANGE
       ├─ TSRANGE, TSTZRANGE
       ├─ DATERANGE
       ├─ Operadores: @>, &&, <<, >>
       └─ EXCLUDE constraints

    ────────────────────────────────────────────────

    📖 1.4 - TIPOS GEOMÉTRICOS E TEXTO
    ├─ 📐 Geometria 2D
    │  ├─ POINT, CIRCLE
    │  ├─ LINE, LSEG
    │  ├─ BOX, POLYGON
    │  ├─ Operadores: <->, <@, &&
    │  └─ ⚠️ Para geolocalização: use PostGIS
    │
    ├─ 📝 Tipos de Texto
    │  ├─ ⭐ TEXT (recomendado)
    │  ├─ VARCHAR(n) (limite)
    │  ├─ VARCHAR (sem limite = TEXT)
    │  └─ CHAR(n) (fixo, apenas códigos)
    │
    ├─ 🔍 Pattern Matching
    │  ├─ LIKE / ILIKE
    │  ├─ ~ / ~* (regex)
    │  ├─ regexp_match
    │  └─ regexp_replace
    │
    └─ 🔎 Full Text Search
       ├─ TSVECTOR (documento)
       ├─ TSQUERY (busca)
       ├─ @@ (operador)
       ├─ ts_rank (relevância)
       └─ Índice: GIN

    ────────────────────────────────────────────────

    📖 1.5 - TIPOS CUSTOMIZADOS
    ├─ 🏷️ DOMAIN
    │  ├─ Tipo base + constraints
    │  ├─ Validações reutilizáveis
    │  └─ Ex: email, cpf, telefone
    │
    ├─ 🎨 ENUM
    │  ├─ Conjunto fixo de valores
    │  ├─ Ordenação preservada
    │  ├─ Performance (armazenado como int)
    │  └─ ⚠️ Difícil de alterar
    │
    └─ 🧱 CREATE TYPE (Composto)
       ├─ Estruturas customizadas
       ├─ Múltiplos campos
       └─ Ex: endereco, contato

┌─────────────────────────────────────────────────────────────────────┐
│                    🎯 DECISÕES-CHAVE                                │
└─────────────────────────────────────────────────────────────────────┘

    UUID vs SERIAL?
    ├─ UUID: Sistemas distribuídos, APIs públicas
    └─ SERIAL: Sistema único, performance crítica

    JSON vs JSONB?
    └─ ⭐ JSONB sempre (indexável, rápido)

    Array vs Tabela Relacional?
    ├─ Array: Valores simples, poucos, sem relacionamento
    └─ Tabela: Entidades complexas, muitos, JOINs

    TEXT vs VARCHAR?
    └─ ⭐ TEXT sempre (performance idêntica)

    MONEY vs NUMERIC?
    └─ ⭐ NUMERIC (portável, sem dependência de locale)

    ENUM vs CHECK?
    ├─ ENUM: Valores estáveis, performance, ordenação
    └─ CHECK: Valores podem mudar, flexibilidade

┌─────────────────────────────────────────────────────────────────────┐
│                    🚀 INDEXAÇÃO POR TIPO                            │
└─────────────────────────────────────────────────────────────────────┘

    B-tree (padrão)
    ├─ Tipos numéricos
    ├─ TEXT, VARCHAR
    ├─ DATE, TIMESTAMP
    └─ UUID

    GIN (Generalized Inverted)
    ├─ ⭐ JSONB
    ├─ ⭐ Arrays
    ├─ ⭐ TSVECTOR (full-text)
    └─ HSTORE

    GiST (Generalized Search Tree)
    ├─ ⭐ Range Types
    ├─ Tipos geométricos
    └─ JSONB (alternativa)

    BRIN (Block Range Index)
    └─ Dados sequenciais grandes

┌─────────────────────────────────────────────────────────────────────┐
│                    📊 COMPARAÇÃO DE TAMANHOS                        │
└─────────────────────────────────────────────────────────────────────┘

    Tipo              Tamanho       Observação
    ─────────────────────────────────────────────────
    SMALLINT          2 bytes       -32K a +32K
    INTEGER           4 bytes       -2B a +2B
    BIGINT            8 bytes       -9 quintilhões...
    SERIAL            4 bytes       = INTEGER
    BIGSERIAL         8 bytes       = BIGINT
    UUID              16 bytes      Único globalmente
    ─────────────────────────────────────────────────
    NUMERIC(p,s)      Variável      Preciso
    REAL              4 bytes       Impreciso
    DOUBLE            8 bytes       Impreciso
    MONEY             8 bytes       ⚠️ Depende locale
    ─────────────────────────────────────────────────
    DATE              4 bytes       Apenas data
    TIME              8 bytes       Apenas hora
    TIMESTAMP         8 bytes       ⚠️ Sem timezone
    TIMESTAMPTZ       8 bytes       ⭐ Com timezone
    INTERVAL          16 bytes      Duração
    ─────────────────────────────────────────────────
    CHAR(n)           n bytes       Fixo, preenche
    VARCHAR(n)        Variável      + 1-4 bytes overhead
    TEXT              Variável      + 1-4 bytes overhead
    ─────────────────────────────────────────────────
    BOOLEAN           1 byte        TRUE/FALSE/NULL
    ─────────────────────────────────────────────────
    JSON              Variável      Texto puro
    JSONB             Variável      Binário otimizado
    ─────────────────────────────────────────────────
    Arrays            Variável      Overhead pequeno
    Compostos         Soma campos   + overhead mínimo

┌─────────────────────────────────────────────────────────────────────┐
│                    🎓 FLUXO DE APRENDIZADO                          │
└─────────────────────────────────────────────────────────────────────┘

    Iniciante
    └─ 1.1 Tipos Nativos
       └─ Exercícios 1-5

    Intermediário
    ├─ 1.2 JSONB
    ├─ 1.3 Arrays
    └─ Exercícios 6-13

    Avançado
    ├─ 1.4 Texto/Geometria
    ├─ 1.5 Tipos Customizados
    └─ Exercícios 14-20

┌─────────────────────────────────────────────────────────────────────┐
│                    ⚡ DICAS RÁPIDAS                                 │
└─────────────────────────────────────────────────────────────────────┘

    ✅ SEMPRE FAÇA:
    • Use TIMESTAMPTZ, nunca TIMESTAMP
    • Use JSONB, nunca JSON
    • Use TEXT, raramente VARCHAR
    • Use NUMERIC para dinheiro, nunca MONEY
    • Crie índices GIN para JSONB/Arrays
    • Valide dados com DOMAINs quando possível

    ❌ EVITE:
    • SERIAL em sistemas distribuídos
    • Arrays grandes (> 100 elementos)
    • ENUM para dados que mudam frequentemente
    • CHAR para textos variáveis
    • Tipos geométricos para lat/lon (use PostGIS)
    • Over-engineering com tipos customizados

    🎯 PERFORMANCE:
    • UUID: 16 bytes vs INT: 4 bytes
    • JSONB: Rápido com GIN index
    • Arrays: GIN index para contenção (@>)
    • Ranges: GiST index + EXCLUDE constraints
    • Text: GIN index + tsvector para busca

┌─────────────────────────────────────────────────────────────────────┐
│                    🔗 NAVEGAÇÃO                                     │
└─────────────────────────────────────────────────────────────────────┘

    ⬅️  Voltar ao Índice Geral: ../README.md
    📚 Índice Detalhado: ./_INDICE.md
    📊 Status do Módulo: ./_STATUS.md
    📖 Como Usar: ./_COMO_USAR.md
```
