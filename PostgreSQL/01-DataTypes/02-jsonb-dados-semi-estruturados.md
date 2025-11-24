# 1.2 - JSONB e Dados Semi-Estruturados

## 📋 O que você vai aprender

- Diferença entre JSON e JSONB
- Quando usar dados semi-estruturados
- Operadores e funções JSON/JSONB
- Indexação de dados JSONB
- JSONB vs estrutura relacional
- Tipo HSTORE (chave-valor)

---

## 🔄 JSON vs JSONB

### Diferenças Fundamentais

| Aspecto | JSON | JSONB |
|---------|------|-------|
| **Armazenamento** | Texto puro | Binário decomposto |
| **Inserção** | Mais rápida | Mais lenta (parsing) |
| **Consulta** | Lenta (parse a cada vez) | Muito rápida |
| **Indexação** | ❌ Não suportado | ✅ GIN, GiST |
| **Espaço** | Menor | Ligeiramente maior |
| **Ordem de chaves** | Preservada | Não preservada |
| **Duplicatas** | Permitidas | Removidas |
| **Recomendação** | ❌ Raramente | ✅ **USE ESTE** |

```sql
-- JSON: armazena texto exatamente como inserido
CREATE TABLE log_json (
    id SERIAL PRIMARY KEY,
    dados JSON
);

-- JSONB: armazena binário otimizado
CREATE TABLE log_jsonb (
    id SERIAL PRIMARY KEY,
    dados JSONB
);

-- Inserir dados
INSERT INTO log_json (dados) VALUES 
('{"nome": "João", "idade": 30, "nome": "duplicado"}');

INSERT INTO log_jsonb (dados) VALUES 
('{"nome": "João", "idade": 30, "nome": "duplicado"}');

-- JSON mantém duplicata e ordem
SELECT dados FROM log_json;
-- {"nome": "João", "idade": 30, "nome": "duplicado"}

-- JSONB remove duplicata (última prevalece)
SELECT dados FROM log_jsonb;
-- {"idade": 30, "nome": "duplicado"}
```

### 🎯 Quando usar JSONB?

✅ **Use JSONB quando:**
- Dados têm estrutura variável ou desconhecida
- Precisa fazer queries complexas no JSON
- Dados semi-estruturados de APIs externas
- Metadados, configurações, telemetria
- Prototipagem rápida

❌ **Não use JSONB quando:**
- Dados são altamente estruturados e conhecidos
- Relacionamentos entre entidades são importantes
- Precisa de constraints fortes (FK, UNIQUE)
- Performance de escrita é crítica

---

## 📦 Armazenando e Consultando JSONB

### Criação e Inserção

```sql
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100),
    perfil JSONB,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Inserir JSONB
INSERT INTO usuarios (nome, email, perfil) VALUES
('João Silva', 'joao@email.com', '{
    "idade": 30,
    "cidade": "São Paulo",
    "interesses": ["programação", "música", "viagens"],
    "preferencias": {
        "tema": "dark",
        "idioma": "pt-BR",
        "notificacoes": true
    }
}'),
('Maria Santos', 'maria@email.com', '{
    "idade": 25,
    "cidade": "Rio de Janeiro",
    "interesses": ["fotografia", "design"],
    "preferencias": {
        "tema": "light",
        "idioma": "pt-BR"
    },
    "premium": true
}');
```

### Operadores JSONB

```sql
-- -> : Retorna JSON object/array
SELECT perfil -> 'idade' FROM usuarios;
-- Resultado: 30, 25 (como JSON)

-- ->> : Retorna TEXT
SELECT perfil ->> 'idade' FROM usuarios;
-- Resultado: '30', '25' (como TEXT)

-- #> : Navegar path (retorna JSON)
SELECT perfil #> '{preferencias, tema}' FROM usuarios;
-- Resultado: "dark", "light"

-- #>> : Navegar path (retorna TEXT)
SELECT perfil #>> '{preferencias, tema}' FROM usuarios;
-- Resultado: dark, light

-- @> : Contém (inclusão)
SELECT * FROM usuarios 
WHERE perfil @> '{"cidade": "São Paulo"}';

-- <@ : Está contido em
SELECT * FROM usuarios
WHERE '{"idade": 30}' <@ perfil;

-- ? : Chave existe
SELECT * FROM usuarios
WHERE perfil ? 'premium';

-- ?| : Pelo menos uma chave existe
SELECT * FROM usuarios
WHERE perfil ?| ARRAY['premium', 'vip'];

-- ?& : Todas as chaves existem
SELECT * FROM usuarios
WHERE perfil ?& ARRAY['idade', 'cidade'];
```

### Exemplos Práticos

```sql
-- Buscar por valor específico
SELECT nome, perfil ->> 'cidade' AS cidade
FROM usuarios
WHERE perfil @> '{"cidade": "São Paulo"}';

-- Buscar em arrays
SELECT nome, perfil -> 'interesses' AS interesses
FROM usuarios
WHERE perfil -> 'interesses' @> '["programação"]';

-- Buscar por valor numérico
SELECT nome, (perfil ->> 'idade')::INT AS idade
FROM usuarios
WHERE (perfil ->> 'idade')::INT > 25;

-- Verificar existência de chave
SELECT nome, perfil ? 'premium' AS eh_premium
FROM usuarios;

-- Buscar em objetos aninhados
SELECT nome, perfil #>> '{preferencias, tema}' AS tema
FROM usuarios
WHERE perfil #>> '{preferencias, tema}' = 'dark';
```

---

## 🔧 Funções JSONB

### Funções de Construção

```sql
-- jsonb_build_object: Construir objeto
SELECT jsonb_build_object(
    'nome', 'Pedro',
    'idade', 35,
    'ativo', true
);
-- {"nome": "Pedro", "idade": 35, "ativo": true}

-- jsonb_build_array: Construir array
SELECT jsonb_build_array(1, 2, 'texto', true, NULL);
-- [1, 2, "texto", true, null]

-- jsonb_object: De arrays de chaves/valores
SELECT jsonb_object(
    ARRAY['nome', 'idade'],
    ARRAY['Ana', '28']
);
-- {"nome": "Ana", "idade": "28"}

-- row_to_json: Converter linha em JSON
SELECT row_to_json(u) FROM usuarios u LIMIT 1;
```

### Funções de Manipulação

```sql
-- jsonb_set: Modificar valor
UPDATE usuarios
SET perfil = jsonb_set(
    perfil,
    '{preferencias, tema}',
    '"dark"'
)
WHERE nome = 'Maria Santos';

-- jsonb_insert: Inserir valor
UPDATE usuarios
SET perfil = jsonb_insert(
    perfil,
    '{tags}',
    '["novo", "tag"]'
)
WHERE nome = 'João Silva';

-- || : Concatenar/Merge (operador)
UPDATE usuarios
SET perfil = perfil || '{"verificado": true}'
WHERE nome = 'João Silva';

-- - : Remover chave (operador)
UPDATE usuarios
SET perfil = perfil - 'premium'
WHERE nome = 'Maria Santos';

-- #- : Remover por path
UPDATE usuarios
SET perfil = perfil #- '{preferencias, notificacoes}'
WHERE nome = 'João Silva';
```

### Funções de Extração

```sql
-- jsonb_each: Expandir objeto em linhas (chave, valor JSON)
SELECT * FROM jsonb_each('{"a": 1, "b": 2}'::JSONB);
--  key | value
-- -----|-------
--  a   | 1
--  b   | 2

-- jsonb_each_text: Expandir em TEXT
SELECT * FROM jsonb_each_text('{"a": 1, "b": "texto"}'::JSONB);

-- jsonb_array_elements: Expandir array
SELECT * FROM jsonb_array_elements('["a", "b", "c"]'::JSONB);
-- value
-- -------
-- "a"
-- "b"
-- "c"

-- jsonb_object_keys: Listar chaves
SELECT jsonb_object_keys(perfil) FROM usuarios;

-- jsonb_array_length: Tamanho do array
SELECT nome, jsonb_array_length(perfil -> 'interesses') AS num_interesses
FROM usuarios;
```

---

## 🔍 Queries Complexas

### Exemplo 1: Buscar em Arrays de Objetos

```sql
-- Tabela de produtos com variantes
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    variantes JSONB
);

INSERT INTO produtos (nome, variantes) VALUES
('Camiseta', '[
    {"cor": "azul", "tamanho": "M", "estoque": 10},
    {"cor": "vermelho", "tamanho": "G", "estoque": 5},
    {"cor": "azul", "tamanho": "G", "estoque": 0}
]'),
('Calça', '[
    {"cor": "preto", "tamanho": "42", "estoque": 15},
    {"cor": "azul", "tamanho": "44", "estoque": 8}
]');

-- Buscar produtos com variante específica em estoque
SELECT 
    nome,
    v.value AS variante
FROM produtos,
LATERAL jsonb_array_elements(variantes) AS v
WHERE (v.value ->> 'cor') = 'azul'
  AND (v.value ->> 'estoque')::INT > 0;
```

### Exemplo 2: Agregações com JSONB

```sql
-- Contar interesses mais comuns
SELECT 
    interesse,
    COUNT(*) AS usuarios
FROM usuarios,
LATERAL jsonb_array_elements_text(perfil -> 'interesses') AS interesse
GROUP BY interesse
ORDER BY usuarios DESC;

-- Média de idade por cidade
SELECT 
    perfil ->> 'cidade' AS cidade,
    AVG((perfil ->> 'idade')::INT) AS idade_media
FROM usuarios
GROUP BY cidade;
```

### Exemplo 3: Atualização Condicional

```sql
-- Adicionar badge para usuários premium
UPDATE usuarios
SET perfil = jsonb_set(
    perfil,
    '{badges}',
    COALESCE(perfil -> 'badges', '[]'::JSONB) || '["premium"]'::JSONB
)
WHERE perfil @> '{"premium": true}';

-- Incrementar contador
UPDATE usuarios
SET perfil = jsonb_set(
    perfil,
    '{visitas}',
    to_jsonb(COALESCE((perfil ->> 'visitas')::INT, 0) + 1)
)
WHERE id = 1;
```

---

## 🚀 Indexação de JSONB

### GIN Index (Generalized Inverted Index)

```sql
-- Índice para operadores de contenção (@>, ?, ?|, ?&)
CREATE INDEX idx_usuarios_perfil_gin 
ON usuarios USING GIN (perfil);

-- Agora queries rápidas:
EXPLAIN ANALYZE
SELECT * FROM usuarios 
WHERE perfil @> '{"cidade": "São Paulo"}';
-- Usa: Bitmap Index Scan on idx_usuarios_perfil_gin

-- Índice em path específico
CREATE INDEX idx_usuarios_cidade 
ON usuarios USING GIN ((perfil -> 'cidade'));

-- Índice em array
CREATE INDEX idx_usuarios_interesses 
ON usuarios USING GIN ((perfil -> 'interesses'));
```

### GIN com jsonb_path_ops

```sql
-- Mais eficiente para @> (contenção)
-- Não suporta outros operadores
CREATE INDEX idx_usuarios_perfil_path_ops
ON usuarios USING GIN (perfil jsonb_path_ops);

-- Comparação de tamanho e performance:
-- GIN padrão: Mais espaço, mais operadores
-- GIN path_ops: Menos espaço, mais rápido para @>, só suporta @>
```

### B-tree para valores específicos

```sql
-- Para queries frequentes em campos específicos
CREATE INDEX idx_usuarios_idade 
ON usuarios ((perfil ->> 'idade')::INT);

CREATE INDEX idx_usuarios_cidade 
ON usuarios ((perfil ->> 'cidade'));

-- Agora rápido:
SELECT * FROM usuarios 
WHERE (perfil ->> 'idade')::INT > 25;
```

---

## 🆚 JSONB vs Tabelas Relacionais

### Quando usar cada abordagem?

```sql
-- ❌ MAU uso de JSONB: Dados estruturados com relacionamentos
CREATE TABLE pedidos_ruim (
    id SERIAL PRIMARY KEY,
    dados JSONB  -- Contém cliente, endereço, itens, tudo!
);
-- Problemas: Sem FKs, difícil de fazer JOINs, sem normalização

-- ✅ BOM uso: Híbrido
CREATE TABLE pedidos_bom (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id),
    endereco_id INT REFERENCES enderecos(id),
    status VARCHAR(20),
    total NUMERIC(10,2),
    criado_em TIMESTAMPTZ,
    -- JSONB para dados flexíveis/opcionais
    metadados JSONB,  -- Cupom, origem, UTM params, etc
    configuracoes JSONB  -- Preferências de entrega, embalagem, etc
);

-- ✅ ÓTIMO para: Dados de APIs externas
CREATE TABLE webhooks (
    id SERIAL PRIMARY KEY,
    origem VARCHAR(50),
    evento VARCHAR(50),
    recebido_em TIMESTAMPTZ DEFAULT NOW(),
    payload JSONB  -- Estrutura varia por origem/evento
);

-- ✅ ÓTIMO para: Logs e telemetria
CREATE TABLE logs_aplicacao (
    id BIGSERIAL PRIMARY KEY,
    nivel VARCHAR(10),
    mensagem TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    contexto JSONB  -- User agent, IP, request headers, etc
);
```

### Exemplo Completo: Sistema de Configurações

```sql
CREATE TABLE tenant_config (
    tenant_id INT PRIMARY KEY,
    nome VARCHAR(100),
    ativo BOOLEAN DEFAULT TRUE,
    -- Configurações flexíveis em JSONB
    configuracoes JSONB DEFAULT '{
        "limites": {
            "usuarios": 100,
            "armazenamento_gb": 10,
            "requests_por_hora": 1000
        },
        "features": {
            "api_enabled": true,
            "webhooks_enabled": false,
            "advanced_analytics": false
        },
        "integracao": {
            "smtp": null,
            "s3": null,
            "payment_gateway": null
        }
    }'::JSONB
);

-- Inserir tenant
INSERT INTO tenant_config (tenant_id, nome) VALUES (1, 'Acme Corp');

-- Ativar feature
UPDATE tenant_config
SET configuracoes = jsonb_set(
    configuracoes,
    '{features, advanced_analytics}',
    'true'
)
WHERE tenant_id = 1;

-- Atualizar limite
UPDATE tenant_config
SET configuracoes = jsonb_set(
    configuracoes,
    '{limites, usuarios}',
    '500'
)
WHERE tenant_id = 1;

-- Query tenants com analytics ativo
SELECT tenant_id, nome
FROM tenant_config
WHERE configuracoes @> '{"features": {"advanced_analytics": true}}';
```

---

## 🗂️ HSTORE - Chave-Valor Simples

Tipo legado para pares chave-valor simples (apenas strings).

```sql
-- Habilitar extensão
CREATE EXTENSION IF NOT EXISTS hstore;

CREATE TABLE configuracoes_simples (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    opcoes HSTORE
);

-- Inserir
INSERT INTO configuracoes_simples (nome, opcoes) VALUES
('App Mobile', 'tema => dark, idioma => pt-BR, versao => 2.1.0'),
('App Web', '"theme" => "light", "language" => "en-US"');

-- Consultar
SELECT opcoes -> 'tema' AS tema FROM configuracoes_simples;

-- Verificar chave
SELECT * FROM configuracoes_simples WHERE opcoes ? 'versao';

-- Atualizar
UPDATE configuracoes_simples
SET opcoes = opcoes || '"notificacoes" => "enabled"'
WHERE id = 1;
```

### HSTORE vs JSONB

| Aspecto | HSTORE | JSONB |
|---------|--------|-------|
| **Estrutura** | Apenas chave-valor plano | Aninhamento, arrays |
| **Tipos** | Apenas strings | Qualquer tipo JSON |
| **Performance** | Levemente mais rápida | Muito boa |
| **Recomendação** | ⚠️ Legado | ✅ **Use JSONB** |

**Recomendação**: Use JSONB para novos projetos. HSTORE é mantido por compatibilidade.

---

## 🎓 Resumo e Boas Práticas

### ✅ Faça

- Use **JSONB** (não JSON) para dados semi-estruturados
- Crie **índices GIN** para queries frequentes
- Use **jsonb_path_ops** para queries de contenção (@>)
- **Misture** relacional + JSONB conforme necessário
- **Valide** dados JSONB na aplicação (ou use constraints CHECK)

### ❌ Evite

- Usar JSON em vez de JSONB
- Armazenar TUDO em JSONB (perca de relacionamentos)
- Não indexar JSONB consultado frequentemente
- Duplicar dados que poderiam ser normalizados
- Usar HSTORE em novos projetos

### 📋 Checklist de Decisão

```
JSONB é apropriado quando:
□ Estrutura varia entre registros
□ Dados vêm de fontes externas (APIs)
□ Schema está evoluindo rapidamente
□ Metadados/configurações opcionais
□ Performance de consulta é aceitável

Use tabelas relacionais quando:
□ Estrutura é conhecida e estável
□ Relacionamentos entre entidades
□ Constraints fortes necessárias (FK, UNIQUE)
□ Performance de escrita é crítica
□ Dados são altamente normalizados
```

---

## 🔗 Navegação

⬅️ [Voltar: Tipos Nativos](./01-tipos-nativos-avancados.md) | [Índice](./README.md) | [Próximo: Arrays →](./03-arrays-tipos-compostos.md)

---

## 📝 Teste Rápido

```sql
-- Crie esta tabela e pratique
CREATE TABLE eventos (
    id SERIAL PRIMARY KEY,
    tipo VARCHAR(50),
    dados JSONB,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Insira alguns eventos
INSERT INTO eventos (tipo, dados) VALUES
('login', '{"usuario_id": 123, "ip": "192.168.1.1", "device": "mobile"}'),
('compra', '{"usuario_id": 123, "produto_id": 456, "valor": 99.90, "metodo": "cartao"}'),
('logout', '{"usuario_id": 123, "duracao_sessao": 3600}');

-- Tente estas queries:
-- 1. Listar eventos do usuario_id 123
-- 2. Buscar compras acima de 50 reais
-- 3. Adicionar campo "processado": true em todos os eventos
-- 4. Criar índice GIN nos dados
```

📚 **Exercícios completos no final do módulo**: [Exercícios](./exercicios.md)
