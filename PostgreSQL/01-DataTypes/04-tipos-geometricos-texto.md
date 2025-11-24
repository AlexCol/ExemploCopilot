# 1.4 - Tipos Geométricos e Texto

## 📋 O que você vai aprender

- Tipos geométricos (POINT, LINE, CIRCLE, POLYGON, etc.)
- Operações e cálculos geométricos
- TEXT vs VARCHAR vs CHAR
- Pattern matching e expressões regulares
- Introdução ao Full Text Search
- Tipos de texto especializados (TSVECTOR, TSQUERY)

---

## 📐 Tipos Geométricos

PostgreSQL possui tipos nativos para geometria 2D.

### Tipos Disponíveis

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| **POINT** | Ponto (x, y) | `(1, 2)` |
| **LINE** | Linha infinita {A, B, C} | `{1, -1, 0}` |
| **LSEG** | Segmento de linha | `[(0,0), (1,1)]` |
| **BOX** | Retângulo | `((0,0), (2,2))` |
| **PATH** | Caminho (aberto/fechado) | `[(0,0), (1,1), (2,0)]` |
| **POLYGON** | Polígono fechado | `((0,0), (1,0), (1,1), (0,1))` |
| **CIRCLE** | Círculo (centro, raio) | `<(0,0), 5>` |

### Criação e Uso

```sql
CREATE TABLE localizacoes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    posicao POINT,
    area_cobertura CIRCLE,
    zona_entrega POLYGON
);

-- Inserir dados geométricos
INSERT INTO localizacoes (nome, posicao, area_cobertura, zona_entrega) VALUES
('Loja Centro', 
 POINT(0, 0),
 CIRCLE(POINT(0, 0), 5),  -- Raio 5km
 POLYGON('((−2,−2), (2,−2), (2,2), (−2,2))')
),
('Loja Norte',
 '(10, 10)',  -- Sintaxe de texto também funciona
 '<(10, 10), 3>',
 '((8,8), (12,8), (12,12), (8,12))'
);

-- Consultar
SELECT 
    nome,
    posicao[0] AS x,  -- Coordenada X
    posicao[1] AS y,  -- Coordenada Y
    area_cobertura
FROM localizacoes;
```

### Operadores Geométricos

```sql
-- Distância entre pontos
SELECT 
    '(0, 0)'::POINT <-> '(3, 4)'::POINT AS distancia;
-- Resultado: 5 (teorema de Pitágoras)

-- Ponto está dentro do círculo?
SELECT '(2, 2)'::POINT <@ '<(0, 0), 5>'::CIRCLE AS dentro;
-- Resultado: true

-- Ponto está dentro do polígono?
SELECT 
    '(1, 1)'::POINT <@ '((0,0), (2,0), (2,2), (0,2))'::POLYGON AS dentro;

-- Círculos se sobrepõem?
SELECT 
    '<(0, 0), 5>'::CIRCLE && '<(6, 0), 3>'::CIRCLE AS overlap;
-- Resultado: true (se tocam ou sobrepõem)

-- Centro do círculo
SELECT @@ '<(5, 5), 10>'::CIRCLE AS centro;
-- Resultado: (5, 5)

-- Área do círculo
SELECT area('<(0, 0), 5>'::CIRCLE) AS area;
-- Resultado: ~78.54

-- Perímetro/Comprimento
SELECT 
    length(path '[(0,0), (1,0), (1,1), (0,1), (0,0)]') AS perimetro;
```

### Exemplo Prático: Sistema de Delivery

```sql
CREATE TABLE restaurantes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    localizacao POINT,
    raio_entrega NUMERIC  -- Em km
);

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    endereco_localizacao POINT
);

INSERT INTO restaurantes (nome, localizacao, raio_entrega) VALUES
('Pizza Express', POINT(-23.550520, -46.633308), 5),
('Burger King', POINT(-23.560520, -46.643308), 3),
('Sushi Bar', POINT(-23.540520, -46.623308), 7);

INSERT INTO clientes (nome, endereco_localizacao) VALUES
('João', POINT(-23.552, -46.635)),
('Maria', POINT(-23.570, -46.650));

-- Encontrar restaurantes que entregam para o cliente
SELECT 
    r.nome AS restaurante,
    c.nome AS cliente,
    r.localizacao <-> c.endereco_localizacao AS distancia_km
FROM restaurantes r
CROSS JOIN clientes c
WHERE r.localizacao <-> c.endereco_localizacao <= r.raio_entrega
ORDER BY cliente, distancia_km;

-- Criar índice GiST para queries espaciais rápidas
CREATE INDEX idx_restaurantes_loc 
ON restaurantes USING GIST (localizacao);
```

### ⚠️ Limitações dos Tipos Geométricos Nativos

Os tipos geométricos do PostgreSQL são **2D simples**:
- ❌ Sem suporte a coordenadas geográficas (latitude/longitude)
- ❌ Sem projeções cartográficas
- ❌ Sem cálculo de distância real na esfera terrestre

Para geolocalização real, use **PostGIS**:

```sql
-- Com PostGIS (extensão separada)
CREATE EXTENSION postgis;

CREATE TABLE lugares (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    localizacao GEOGRAPHY(POINT, 4326)  -- WGS 84
);

-- Distância real em metros
SELECT ST_Distance(
    'POINT(-46.633308 -23.550520)'::GEOGRAPHY,  -- São Paulo
    'POINT(-43.172896 -22.906847)'::GEOGRAPHY   -- Rio de Janeiro
) / 1000 AS distancia_km;
-- Resultado: ~357 km
```

---

## 📝 Tipos de Texto

### TEXT vs VARCHAR vs CHAR

```sql
CREATE TABLE comparacao_texto (
    id SERIAL PRIMARY KEY,
    texto TEXT,              -- Sem limite, recomendado
    varchar VARCHAR(50),     -- Limite de 50 chars, erro se exceder
    varchar_sem_limite VARCHAR,  -- Equivalente a TEXT
    char CHAR(10)           -- Fixo em 10, preenche com espaços
);

INSERT INTO comparacao_texto (texto, varchar, varchar_sem_limite, char) VALUES
('Um texto longo sem limite de tamanho', 
 'Texto com limite',
 'Outro texto sem limite',
 'ABC');  -- Será armazenado como 'ABC       ' (7 espaços)

-- Consultar
SELECT 
    texto,
    varchar,
    char,
    length(char) AS tamanho_char,  -- 10 (conta espaços)
    char_length(char) AS chars,    -- 10
    octet_length(char) AS bytes    -- 10
FROM comparacao_texto;

-- Comparação
SELECT 'ABC'::CHAR(10) = 'ABC       '::CHAR(10);  -- true (ignora espaços)
SELECT 'ABC'::TEXT = 'ABC       '::TEXT;          -- false
```

### 📋 Quando usar cada um?

| Tipo | Quando Usar | Evitar |
|------|-------------|--------|
| **TEXT** | ✅ Padrão para textos | Raramente há razão para não usar |
| **VARCHAR(n)** | Validação de tamanho no DB | Usar TEXT + CHECK é mais flexível |
| **VARCHAR** (sem limite) | Equivalente a TEXT | Use TEXT diretamente |
| **CHAR(n)** | Códigos fixos (ex: UF, CEP) | Textos variáveis (desperdício) |

**Recomendação**: Use **TEXT** por padrão. Performance é idêntica ao VARCHAR.

```sql
-- ✅ RECOMENDADO
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    email TEXT NOT NULL,
    biografia TEXT,
    uf CHAR(2),  -- OK: tamanho fixo
    CONSTRAINT email_valido CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- ❌ DESNECESSÁRIO
CREATE TABLE usuarios_ruim (
    nome VARCHAR(100),  -- Por que limitar?
    email VARCHAR(255),  -- Limite arbitrário
    biografia VARCHAR(1000)  -- E se precisar de mais?
);
```

---

## 🔍 Pattern Matching

### LIKE e ILIKE

```sql
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    descricao TEXT
);

INSERT INTO produtos (nome, descricao) VALUES
('Notebook Dell', 'Notebook para programação'),
('Mouse Logitech', 'Mouse wireless'),
('Teclado Mecânico', 'Teclado para gamers'),
('Mousepad Gamer', 'Mousepad RGB');

-- LIKE: case-sensitive
SELECT nome FROM produtos WHERE nome LIKE '%Mouse%';
-- Resultado: Mouse Logitech

-- ILIKE: case-insensitive
SELECT nome FROM produtos WHERE nome ILIKE '%mouse%';
-- Resultado: Mouse Logitech, Mousepad Gamer

-- Wildcards:
-- % : Qualquer sequência de caracteres
-- _ : Um caractere único
SELECT nome FROM produtos WHERE nome LIKE '_____pad%';
-- Resultado: Mousepad Gamer (5 caracteres + 'pad')

-- Índices para LIKE
CREATE INDEX idx_produtos_nome_pattern 
ON produtos (nome text_pattern_ops);
-- Acelera queries: WHERE nome LIKE 'texto%' (apenas prefixo)
```

### Expressões Regulares (REGEX)

```sql
-- ~ : Regex case-sensitive
-- ~* : Regex case-insensitive
-- !~ : NOT regex case-sensitive
-- !~* : NOT regex case-insensitive

-- Encontrar emails válidos
SELECT * FROM usuarios 
WHERE email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$';

-- Extrair padrões
SELECT 
    nome,
    (SELECT regexp_match(nome, '\d+'))[1] AS numero_extraido
FROM produtos;

-- Substituir com regex
SELECT regexp_replace('Olá, mundo!', 'mundo', 'PostgreSQL', 'gi');
-- Resultado: Olá, PostgreSQL!

-- Split com regex
SELECT regexp_split_to_array('um,dois;três', '[,;]');
-- Resultado: {um, dois, três}

-- Matches múltiplos
SELECT regexp_matches('abc123def456', '\d+', 'g');
-- Retorna cada match como linha separada
```

### Exemplo Prático: Validação de Dados

```sql
CREATE TABLE cadastros (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    cpf TEXT,
    telefone TEXT,
    email TEXT,
    CONSTRAINT cpf_formato CHECK (cpf ~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$'),
    CONSTRAINT telefone_formato CHECK (telefone ~ '^\(\d{2}\) \d{4,5}-\d{4}$'),
    CONSTRAINT email_formato CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Inserção válida
INSERT INTO cadastros (nome, cpf, telefone, email) VALUES
('João Silva', '123.456.789-00', '(11) 98765-4321', 'joao@email.com');

-- Inserção inválida
INSERT INTO cadastros (nome, cpf, telefone, email) VALUES
('Maria', '12345678900', '11987654321', 'email-invalido');
-- ERROR: new row violates check constraint
```

---

## 🔎 Full Text Search (Básico)

Para busca de texto completa eficiente.

### Tipos TSVECTOR e TSQUERY

```sql
CREATE TABLE artigos (
    id SERIAL PRIMARY KEY,
    titulo TEXT,
    conteudo TEXT,
    conteudo_tsv TSVECTOR  -- Versão indexável do texto
);

-- Inserir e gerar tsvector
INSERT INTO artigos (titulo, conteudo, conteudo_tsv) VALUES
('PostgreSQL Tips', 
 'PostgreSQL é um banco de dados relacional poderoso',
 to_tsvector('portuguese', 'PostgreSQL é um banco de dados relacional poderoso')
);

-- Buscar com tsquery
SELECT titulo FROM artigos
WHERE conteudo_tsv @@ to_tsquery('portuguese', 'postgresql & dados');
-- Busca por "postgresql" E "dados" (em português)

-- Ranking de relevância
SELECT 
    titulo,
    ts_rank(conteudo_tsv, to_tsquery('portuguese', 'postgresql')) AS relevancia
FROM artigos
ORDER BY relevancia DESC;
```

### Geração Automática com Trigger

```sql
-- Função para atualizar tsvector
CREATE FUNCTION artigos_tsvector_trigger() RETURNS TRIGGER AS $$
BEGIN
    NEW.conteudo_tsv := 
        setweight(to_tsvector('portuguese', COALESCE(NEW.titulo, '')), 'A') ||
        setweight(to_tsvector('portuguese', COALESCE(NEW.conteudo, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER tsvector_update 
BEFORE INSERT OR UPDATE ON artigos
FOR EACH ROW 
EXECUTE FUNCTION artigos_tsvector_trigger();

-- Agora é automático!
INSERT INTO artigos (titulo, conteudo) VALUES
('Node.js Tutorial', 'Aprenda Node.js do zero');

-- Buscar
SELECT titulo FROM artigos
WHERE conteudo_tsv @@ to_tsquery('portuguese', 'node');

-- Criar índice GIN para busca rápida
CREATE INDEX idx_artigos_tsv ON artigos USING GIN (conteudo_tsv);
```

### Operadores de TSQUERY

```sql
-- & : E (AND)
SELECT * FROM artigos 
WHERE conteudo_tsv @@ to_tsquery('postgresql & dados');

-- | : OU (OR)
SELECT * FROM artigos 
WHERE conteudo_tsv @@ to_tsquery('postgresql | mysql');

-- ! : NÃO (NOT)
SELECT * FROM artigos 
WHERE conteudo_tsv @@ to_tsquery('postgresql & !mysql');

-- <-> : Seguido de (distância 1)
SELECT * FROM artigos 
WHERE conteudo_tsv @@ to_tsquery('banco <-> dados');
-- Encontra "banco de dados" mas não "banco dados"

-- <N> : Distância N
SELECT * FROM artigos 
WHERE conteudo_tsv @@ to_tsquery('banco <2> relacional');
-- "banco de dados relacional" (distância 2)
```

### Highlight de Resultados

```sql
-- Destacar termos encontrados
SELECT 
    titulo,
    ts_headline('portuguese', conteudo, 
                to_tsquery('postgresql'),
                'MaxWords=20, MinWords=10') AS snippet
FROM artigos
WHERE conteudo_tsv @@ to_tsquery('postgresql');

-- Resultado com <b>...</b> ao redor dos termos
```

---

## 🎓 Resumo e Boas Práticas

### Tipos Geométricos

✅ **Use quando:**
- Geometria 2D simples
- Cálculos matemáticos puros
- Não precisa de coordenadas geográficas

✅ **Use PostGIS para:**
- Geolocalização real (lat/lon)
- Cálculo de distâncias geográficas
- Mapas e GIS

### Tipos de Texto

✅ **Faça:**
- Use **TEXT** como padrão
- Use **CHAR(n)** apenas para códigos fixos
- Validações com **CHECK + regex**
- Índices **text_pattern_ops** para LIKE

❌ **Evite:**
- VARCHAR com limites arbitrários
- CHAR para textos variáveis
- LIKE sem índices em tabelas grandes

### Full Text Search

✅ **Faça:**
- Use **tsvector** para busca de texto
- Crie índices **GIN**
- Trigger para atualização automática
- **setweight** para priorizar campos

❌ **Evite:**
- to_tsvector em queries (lento)
- Buscar sem índices
- Ignorar idioma (afeta stemming)

---

## 🔗 Navegação

⬅️ [Voltar: Arrays](./03-arrays-tipos-compostos.md) | [Índice](./README.md) | [Próximo: Tipos Customizados →](./05-tipos-customizados.md)

---

## 📝 Teste Rápido

```sql
-- Pratique com estes exemplos
CREATE TABLE documentos (
    id SERIAL PRIMARY KEY,
    titulo TEXT,
    conteudo TEXT,
    conteudo_tsv TSVECTOR,
    localizacao POINT
);

-- Insira alguns documentos
-- Crie busca full-text
-- Teste operadores geométricos
-- Valide emails com regex
```

📚 **Exercícios completos no final do módulo**: [Exercícios](./exercicios.md)
