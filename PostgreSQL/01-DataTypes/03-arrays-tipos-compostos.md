# 1.3 - Arrays e Tipos Compostos

## 📋 O que você vai aprender

- Arrays unidimensionais e multidimensionais
- Operações e funções com arrays
- Tipos compostos (ROW)
- Range Types (períodos e intervalos)
- Operadores de overlap e containment
- Quando usar arrays vs tabelas relacionais

---

## 📚 Arrays no PostgreSQL

### Declaração e Criação

```sql
-- Arrays podem ser de qualquer tipo
CREATE TABLE exemplo_arrays (
    id SERIAL PRIMARY KEY,
    tags TEXT[],                    -- Array de textos
    numeros INT[],                  -- Array de inteiros
    coordenadas NUMERIC[],          -- Array de decimais
    matriz INT[][],                 -- Array multidimensional
    emails VARCHAR(100)[]           -- Tamanho máximo por elemento
);

-- Inserindo dados
INSERT INTO exemplo_arrays (tags, numeros, coordenadas) VALUES
-- Sintaxe com ARRAY
(ARRAY['postgresql', 'database', 'sql'], ARRAY[1, 2, 3], ARRAY[10.5, 20.3]),

-- Sintaxe com '{}' 
('{"nodejs", "javascript"}', '{10, 20, 30}', '{1.1, 2.2, 3.3}'),

-- Array vazio
(ARRAY[]::TEXT[], ARRAY[]::INT[], ARRAY[]::NUMERIC[]);

-- Multidimensional
INSERT INTO exemplo_arrays (matriz) VALUES
('{{1,2,3},{4,5,6},{7,8,9}}');  -- Matriz 3x3
```

### Acessando Elementos

```sql
-- Arrays são 1-indexed no PostgreSQL!
SELECT 
    tags[1] AS primeira_tag,        -- Primeiro elemento
    tags[2] AS segunda_tag,
    numeros[1:2] AS slice,          -- Slice (subarray)
    array_length(tags, 1) AS tamanho,
    array_upper(tags, 1) AS indice_max,
    array_lower(tags, 1) AS indice_min
FROM exemplo_arrays;

-- Multidimensional
SELECT 
    matriz[1][1] AS elemento_1_1,   -- Linha 1, Coluna 1
    matriz[2][2] AS elemento_2_2    -- Linha 2, Coluna 2
FROM exemplo_arrays
WHERE matriz IS NOT NULL;
```

---

## 🔧 Operações com Arrays

### Operadores

```sql
-- Preparar dados de exemplo
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    categorias TEXT[]
);

INSERT INTO produtos (nome, categorias) VALUES
('Notebook', ARRAY['eletrônicos', 'informática', 'notebooks']),
('Mouse', ARRAY['eletrônicos', 'periféricos', 'acessórios']),
('Livro SQL', ARRAY['livros', 'tecnologia', 'database']),
('Teclado', ARRAY['eletrônicos', 'periféricos']);

-- @> : Contém todos os elementos
SELECT nome FROM produtos
WHERE categorias @> ARRAY['eletrônicos', 'periféricos'];
-- Resultado: Mouse, Teclado

-- <@ : Está contido em
SELECT nome FROM produtos
WHERE ARRAY['eletrônicos'] <@ categorias;
-- Resultado: Notebook, Mouse, Teclado

-- && : Overlap (tem interseção)
SELECT nome FROM produtos
WHERE categorias && ARRAY['livros', 'tecnologia'];
-- Resultado: Livro SQL

-- = : Igualdade
SELECT nome FROM produtos
WHERE categorias = ARRAY['eletrônicos', 'periféricos'];
-- Nenhum resultado (ordem e quantidade devem ser exatas)

-- || : Concatenação
SELECT 
    nome,
    categorias || ARRAY['novo'] AS categorias_atualizadas
FROM produtos
LIMIT 1;
```

### Funções de Manipulação

```sql
-- array_append: Adicionar elemento no final
UPDATE produtos
SET categorias = array_append(categorias, 'promocao')
WHERE nome = 'Mouse';

-- array_prepend: Adicionar elemento no início
UPDATE produtos
SET categorias = array_prepend('destaque', categorias)
WHERE nome = 'Notebook';

-- array_remove: Remover todas as ocorrências
UPDATE produtos
SET categorias = array_remove(categorias, 'acessórios')
WHERE nome = 'Mouse';

-- array_replace: Substituir elemento
UPDATE produtos
SET categorias = array_replace(categorias, 'eletrônicos', 'electronics')
WHERE id = 1;

-- array_cat: Concatenar arrays
SELECT array_cat(ARRAY[1,2], ARRAY[3,4]);  -- {1,2,3,4}

-- array_position: Encontrar posição (1-indexed)
SELECT array_position(ARRAY['a','b','c'], 'b');  -- 2

-- array_positions: Todas as posições
SELECT array_positions(ARRAY['a','b','a','c'], 'a');  -- {1,3}
```

### Funções de Agregação

```sql
-- array_agg: Agregar valores em array
SELECT 
    LEFT(nome, 1) AS inicial,
    array_agg(nome ORDER BY nome) AS nomes
FROM produtos
GROUP BY inicial;

-- unnest: Expandir array em linhas
SELECT unnest(ARRAY['a', 'b', 'c']);
-- Resultado:
-- a
-- b
-- c

-- Uso prático: Contar categorias mais comuns
SELECT 
    unnest(categorias) AS categoria,
    COUNT(*) AS frequencia
FROM produtos
GROUP BY categoria
ORDER BY frequencia DESC;

-- array_length: Tamanho do array
SELECT 
    nome,
    array_length(categorias, 1) AS num_categorias
FROM produtos;

-- cardinality: Total de elementos (mesmo para multidimensional)
SELECT cardinality(ARRAY[1,2,3]);  -- 3
SELECT cardinality(ARRAY[[1,2],[3,4]]);  -- 4
```

---

## 🎯 Exemplos Práticos com Arrays

### Exemplo 1: Tags em Posts

```sql
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    titulo TEXT,
    conteudo TEXT,
    tags TEXT[],
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Criar índice GIN para busca eficiente
CREATE INDEX idx_posts_tags ON posts USING GIN (tags);

INSERT INTO posts (titulo, conteudo, tags) VALUES
('PostgreSQL Tips', 'Conteúdo...', ARRAY['postgresql', 'database', 'tutorial']),
('Node.js API', 'Conteúdo...', ARRAY['nodejs', 'javascript', 'api', 'tutorial']),
('React Hooks', 'Conteúdo...', ARRAY['react', 'javascript', 'frontend']);

-- Buscar posts por tag (rápido com índice GIN)
SELECT titulo, tags FROM posts
WHERE tags @> ARRAY['tutorial'];

-- Buscar posts com qualquer uma das tags
SELECT titulo, tags FROM posts
WHERE tags && ARRAY['javascript', 'postgresql'];

-- Tags mais populares
SELECT 
    tag,
    COUNT(*) AS posts_count
FROM posts, unnest(tags) AS tag
GROUP BY tag
ORDER BY posts_count DESC;
```

### Exemplo 2: Permissões de Usuário

```sql
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100),
    permissoes TEXT[]
);

INSERT INTO usuarios (nome, email, permissoes) VALUES
('Admin', 'admin@email.com', ARRAY['read', 'write', 'delete', 'admin']),
('Editor', 'editor@email.com', ARRAY['read', 'write']),
('Viewer', 'viewer@email.com', ARRAY['read']);

-- Verificar se usuário tem permissão
CREATE FUNCTION tem_permissao(usuario_id INT, permissao_requerida TEXT)
RETURNS BOOLEAN AS $$
    SELECT permissoes @> ARRAY[permissao_requerida]
    FROM usuarios
    WHERE id = usuario_id;
$$ LANGUAGE SQL;

-- Testar
SELECT tem_permissao(1, 'admin');  -- true
SELECT tem_permissao(2, 'admin');  -- false
SELECT tem_permissao(2, 'write');  -- true

-- Adicionar permissão
UPDATE usuarios
SET permissoes = array_append(permissoes, 'export')
WHERE id = 2;

-- Remover permissão
UPDATE usuarios
SET permissoes = array_remove(permissoes, 'write')
WHERE id = 3;
```

### Exemplo 3: Histórico de Status

```sql
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    historico_status TEXT[] DEFAULT ARRAY[]::TEXT[],
    status_atual TEXT,
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Função para atualizar status
CREATE OR REPLACE FUNCTION atualizar_status_pedido(
    pedido_id INT,
    novo_status TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE pedidos
    SET 
        historico_status = array_append(historico_status, novo_status),
        status_atual = novo_status,
        atualizado_em = NOW()
    WHERE id = pedido_id;
END;
$$ LANGUAGE plpgsql;

-- Usar
INSERT INTO pedidos (status_atual) VALUES ('pendente');
SELECT atualizar_status_pedido(1, 'processando');
SELECT atualizar_status_pedido(1, 'enviado');
SELECT atualizar_status_pedido(1, 'entregue');

-- Ver histórico
SELECT 
    id,
    status_atual,
    historico_status,
    array_length(historico_status, 1) AS num_transicoes
FROM pedidos;
```

---

## 🧩 Tipos Compostos (ROW)

Tipos compostos permitem agrupar múltiplos campos em um único valor.

```sql
-- Criar tipo composto
CREATE TYPE endereco_t AS (
    rua TEXT,
    numero INT,
    complemento TEXT,
    cidade TEXT,
    estado CHAR(2),
    cep CHAR(9)
);

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    endereco_residencial endereco_t,
    endereco_comercial endereco_t
);

-- Inserir com ROW
INSERT INTO clientes (nome, endereco_residencial, endereco_comercial) VALUES
('João Silva', 
 ROW('Rua A', 123, 'Apt 45', 'São Paulo', 'SP', '01234-567'),
 ROW('Av B', 456, 'Sala 10', 'São Paulo', 'SP', '01234-999')
);

-- Inserir com sintaxe de texto
INSERT INTO clientes (nome, endereco_residencial) VALUES
('Maria Santos', 
 '("Rua C", 789, "Casa", "Rio de Janeiro", "RJ", "22222-333")'
);

-- Acessar campos do tipo composto
SELECT 
    nome,
    (endereco_residencial).cidade AS cidade_residencial,
    (endereco_residencial).estado AS estado_residencial,
    (endereco_comercial).cidade AS cidade_comercial
FROM clientes;

-- Atualizar campo específico do composto
UPDATE clientes
SET endereco_residencial.numero = 999
WHERE nome = 'João Silva';

-- Buscar por campo do composto
SELECT nome FROM clientes
WHERE (endereco_residencial).cidade = 'São Paulo';
```

### Tipos Compostos Anônimos

```sql
-- Criar tipo composto "on-the-fly"
CREATE TABLE eventos (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    localizacao ROW(latitude NUMERIC, longitude NUMERIC),
    periodo ROW(inicio TIMESTAMPTZ, fim TIMESTAMPTZ)
);

INSERT INTO eventos (nome, localizacao, periodo) VALUES
('Conferência Tech',
 ROW(-23.550520, -46.633308),
 ROW('2025-12-01 09:00:00-03', '2025-12-03 18:00:00-03')
);

SELECT 
    nome,
    (localizacao).latitude,
    (localizacao).longitude,
    (periodo).inicio,
    (periodo).fim
FROM eventos;
```

---

## 📏 Range Types

Tipos de range representam intervalos de valores.

```sql
-- Tipos de range disponíveis:
-- INT4RANGE: intervalo de integers
-- INT8RANGE: intervalo de bigints
-- NUMRANGE: intervalo de numerics
-- TSRANGE: intervalo de timestamps
-- TSTZRANGE: intervalo de timestamps com timezone
-- DATERANGE: intervalo de datas

CREATE TABLE reservas (
    id SERIAL PRIMARY KEY,
    sala VARCHAR(50),
    periodo TSTZRANGE,  -- Range de timestamps
    preco_range NUMRANGE  -- Range de preços
);

-- Inserir ranges
INSERT INTO reservas (sala, periodo, preco_range) VALUES
-- Sintaxe: '[início, fim)' - inclui início, exclui fim
('Sala A', '[2025-11-18 09:00:00-03, 2025-11-18 11:00:00-03)', '[100, 200)'),
('Sala B', '[2025-11-18 10:00:00-03, 2025-11-18 12:00:00-03)', '[150, 250)'),
('Sala C', '[2025-11-18 14:00:00-03, 2025-11-18 16:00:00-03)', '[100, 200)');

-- Notações de range:
-- '[a, b]' : fechado (inclui ambos)
-- '(a, b)' : aberto (exclui ambos)
-- '[a, b)' : semi-aberto (inclui a, exclui b)
-- '(a, b]' : semi-aberto (exclui a, inclui b)

-- Verificar se momento está no range
SELECT sala FROM reservas
WHERE periodo @> '2025-11-18 10:30:00-03'::TIMESTAMPTZ;
-- Resultado: Sala A, Sala B

-- Verificar overlap (conflito)
SELECT * FROM reservas
WHERE periodo && '[2025-11-18 10:00:00-03, 2025-11-18 11:00:00-03)'::TSTZRANGE;

-- Funções de range
SELECT 
    sala,
    lower(periodo) AS inicio,              -- Limite inferior
    upper(periodo) AS fim,                 -- Limite superior
    lower_inc(periodo) AS inclui_inicio,   -- Inclui limite inferior?
    upper_inc(periodo) AS inclui_fim,      -- Inclui limite superior?
    isempty(periodo) AS vazio             -- Range vazio?
FROM reservas;
```

### Operadores de Range

```sql
-- @> : Contém elemento ou range
SELECT * FROM reservas 
WHERE periodo @> '2025-11-18 10:00:00-03'::TIMESTAMPTZ;

SELECT * FROM reservas
WHERE preco_range @> 150;  -- Contém valor 150

-- <@ : Está contido em
SELECT * FROM reservas
WHERE '2025-11-18 10:00:00-03'::TIMESTAMPTZ <@ periodo;

-- && : Overlap (sobreposição)
SELECT * FROM reservas r1
WHERE EXISTS (
    SELECT 1 FROM reservas r2
    WHERE r1.id != r2.id
      AND r1.periodo && r2.periodo
);

-- << : Estritamente à esquerda
SELECT * FROM reservas
WHERE periodo << '[2025-11-18 13:00:00-03, 2025-11-18 14:00:00-03)'::TSTZRANGE;

-- >> : Estritamente à direita
SELECT * FROM reservas
WHERE periodo >> '[2025-11-18 12:00:00-03, 2025-11-18 13:00:00-03)'::TSTZRANGE;

-- &< : Não se estende à direita de
-- &> : Não se estende à esquerda de
-- -|- : Adjacente (um termina quando o outro começa)
SELECT '[1, 2)'::INT4RANGE -|- '[2, 3)'::INT4RANGE;  -- true
```

### Exemplo Prático: Sistema de Agendamento

```sql
CREATE TABLE agendamentos (
    id SERIAL PRIMARY KEY,
    recurso VARCHAR(50),
    usuario_id INT,
    periodo TSTZRANGE,
    EXCLUDE USING GIST (recurso WITH =, periodo WITH &&)
    -- EXCLUDE: Impede overlaps no mesmo recurso
);

-- Tentar inserir agendamento
INSERT INTO agendamentos (recurso, usuario_id, periodo) VALUES
('Sala de Reunião', 1, '[2025-11-18 09:00:00-03, 2025-11-18 10:00:00-03)');

-- Sucesso!

-- Tentar agendamento conflitante
INSERT INTO agendamentos (recurso, usuario_id, periodo) VALUES
('Sala de Reunião', 2, '[2025-11-18 09:30:00-03, 2025-11-18 10:30:00-03)');

-- ERROR: conflicting key value violates exclusion constraint
-- O banco impede automaticamente!

-- Agendamento que NÃO conflita (horário diferente)
INSERT INTO agendamentos (recurso, usuario_id, periodo) VALUES
('Sala de Reunião', 2, '[2025-11-18 10:00:00-03, 2025-11-18 11:00:00-03)');
-- Sucesso! (10:00 não está incluso no range anterior '[..., 10:00)')

-- Ver horários disponíveis
WITH todos_horarios AS (
    SELECT generate_series(
        '2025-11-18 08:00:00-03'::TIMESTAMPTZ,
        '2025-11-18 18:00:00-03'::TIMESTAMPTZ,
        '1 hour'::INTERVAL
    ) AS hora
)
SELECT 
    hora,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM agendamentos 
            WHERE recurso = 'Sala de Reunião' 
              AND periodo @> hora
        )
        THEN '❌ Ocupado'
        ELSE '✅ Disponível'
    END AS status
FROM todos_horarios;
```

---

## 🆚 Arrays vs Tabelas Relacionais

### Quando usar Arrays?

✅ **Use Arrays quando:**
- Ordem importa
- Valores são simples e não relacionados
- Número de elementos é pequeno/fixo
- Não precisa fazer JOIN nos elementos
- Performance de leitura é crítica

```sql
-- ✅ BOM: Tags, permissões, flags
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    titulo TEXT,
    tags TEXT[]  -- Simples, poucos, sem relacionamento
);
```

❌ **Use Tabela Relacional quando:**
- Elementos são entidades complexas
- Precisa fazer JOIN
- Muitos elementos
- Relacionamentos N:N
- Integridade referencial (FK)

```sql
-- ✅ MELHOR: Usar tabela relacionalcaso complexo
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    titulo TEXT
);

CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nome TEXT UNIQUE
);

CREATE TABLE posts_categorias (
    post_id INT REFERENCES posts(id),
    categoria_id INT REFERENCES categorias(id),
    PRIMARY KEY (post_id, categoria_id)
);
```

---

## 🎓 Resumo e Boas Práticas

### ✅ Faça

- Use arrays para listas simples (tags, permissões)
- Crie índices **GIN** para arrays consultados frequentemente
- Use **range types** para intervalos (datas, preços)
- Use **EXCLUDE constraints** para prevenir overlaps
- Considere tipos compostos para agrupar dados relacionados

### ❌ Evite

- Arrays grandes (> 100 elementos)
- Arrays de tipos complexos
- Substituir tabelas relacionais por arrays
- Arrays sem índices em queries frequentes
- Multidimensional quando pode usar tipo composto

### 📋 Performance

```sql
-- ✅ Índice GIN para arrays
CREATE INDEX idx_tags ON posts USING GIN (tags);

-- ✅ Índice GiST para ranges
CREATE INDEX idx_periodo ON reservas USING GIST (periodo);

-- ✅ EXCLUDE constraint com GiST para ranges
ALTER TABLE agendamentos 
ADD EXCLUDE USING GIST (recurso WITH =, periodo WITH &&);
```

---

## 🔗 Navegação

⬅️ [Voltar: JSONB](./02-jsonb-dados-semi-estruturados.md) | [Índice](./README.md) | [Próximo: Tipos Geométricos e Texto →](./04-tipos-geometricos-texto.md)

---

## 📝 Teste Rápido

```sql
-- Pratique com estes exemplos
CREATE TABLE pratica_arrays (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    habilidades TEXT[],
    faixa_salarial NUMRANGE
);

INSERT INTO pratica_arrays (nome, habilidades, faixa_salarial) VALUES
('João', ARRAY['PostgreSQL', 'Python', 'Docker'], '[5000, 8000)'),
('Maria', ARRAY['JavaScript', 'React', 'Node.js'], '[6000, 10000)');

-- Tente:
-- 1. Buscar pessoas com habilidade 'Python'
-- 2. Adicionar nova habilidade para João
-- 3. Listar pessoas com salário possível de 7000
-- 4. Verificar se há overlap de faixas salariais
```

📚 **Exercícios completos no final do módulo**: [Exercícios](./exercicios.md)
