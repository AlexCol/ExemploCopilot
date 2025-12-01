# 1.5 - Tipos Customizados

## 📋 O que você vai aprender

- CREATE DOMAIN - Tipos com constraints
- ENUM - Tipos enumerados
- CREATE TYPE - Tipos compostos customizados
- Alterando e removendo tipos
- Quando criar tipos customizados
- Boas práticas e convenções de nomenclatura

---

## 🏷️ DOMAIN - Tipos com Restrições

DOMAIN permite criar tipos baseados em tipos existentes, com constraints adicionais.

### Sintaxe Básica

```sql
-- Criar domainCREATE DOMAIN nome_do_tipo tipo_base
    [ DEFAULT expressao ]
    [ CONSTRAINT nome_constraint CHECK (condicao) ];

-- Exemplos práticos
CREATE DOMAIN email AS TEXT
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

CREATE DOMAIN cpf AS CHAR(14)
    CHECK (VALUE ~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$');

CREATE DOMAIN telefone_br AS VARCHAR(15)
    CHECK (VALUE ~ '^\(\d{2}\) \d{4,5}-\d{4}$');

CREATE DOMAIN valor_positivo AS NUMERIC(10,2)
    CHECK (VALUE > 0);

CREATE DOMAIN percentual AS NUMERIC(5,2)
    CHECK (VALUE >= 0 AND VALUE <= 100);

CREATE DOMAIN url AS TEXT
    CHECK (VALUE ~* '^https?://[^\s/$.?#].[^\s]*$');
```

### Usando DOMAINs

```sql
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    email email NOT NULL UNIQUE,  -- Usa o DOMAIN
    cpf cpf UNIQUE,
    telefone telefone_br,
    salario valor_positivo
);

-- Inserção válida
INSERT INTO usuarios (nome, email, cpf, telefone, salario) VALUES
('João Silva', 
 'joao@email.com', 
 '123.456.789-00', 
 '(11) 98765-4321',
 5000.00);

-- Inserção inválida (email)
INSERT INTO usuarios (nome, email) VALUES
('Maria', 'email-invalido');
-- ERROR: value for domain email violates check constraint

-- Inserção inválida (valor negativo)
INSERT INTO usuarios (nome, email, salario) VALUES
('Pedro', 'pedro@email.com', -100);
-- ERROR: value for domain valor_positivo violates check constraint
```

### Gerenciando DOMAINs

```sql
-- Adicionar constraint a DOMAIN existente
ALTER DOMAIN email ADD CONSTRAINT email_nao_descartavel 
    CHECK (VALUE NOT ILIKE '%@tempmail.%');

-- Remover constraint
ALTER DOMAIN email DROP CONSTRAINT email_nao_descartavel;

-- Alterar valor padrão
ALTER DOMAIN valor_positivo SET DEFAULT 0.01;

-- Renomear DOMAIN
ALTER DOMAIN valor_positivo RENAME TO valor_monetario_positivo;

-- Listar DOMAINs
SELECT domain_name, data_type, character_maximum_length
FROM information_schema.domains
WHERE domain_schema = 'public';

-- Ver constraints de um DOMAIN
SELECT conname, consrc
FROM pg_constraint c
JOIN pg_type t ON t.oid = c.contypid
WHERE t.typname = 'email';

-- Remover DOMAIN
DROP DOMAIN email CASCADE;  -- CASCADE remove colunas que usam
DROP DOMAIN email RESTRICT; -- RESTRICT falha se estiver em uso
```

### Exemplo Completo: Sistema de Cadastro

```sql
-- Criar DOMAINs
CREATE DOMAIN email AS TEXT
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

CREATE DOMAIN cep AS CHAR(9)
    CHECK (VALUE ~ '^\d{5}-\d{3}$');

CREATE DOMAIN cpf AS CHAR(14)
    CHECK (VALUE ~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$');

CREATE DOMAIN telefone AS VARCHAR(15)
    CHECK (VALUE ~ '^\(\d{2}\) \d{4,5}-\d{4}$');

CREATE DOMAIN nome_pessoa AS VARCHAR(100)
    CHECK (char_length(VALUE) >= 3);

CREATE DOMAIN idade AS INT
    CHECK (VALUE >= 0 AND VALUE <= 150);

-- Usar os DOMAINs
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome nome_pessoa NOT NULL,
    email email NOT NULL UNIQUE,
    cpf cpf UNIQUE,
    idade idade,
    telefone telefone,
    cep cep,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Todas as validações são feitas automaticamente!
INSERT INTO clientes (nome, email, cpf, idade, telefone, cep) VALUES
('João Pedro Silva', 
 'joao.silva@email.com', 
 '123.456.789-00',
 30,
 '(11) 98765-4321',
 '01234-567');
```

---

## 🎨 ENUM - Tipos Enumerados

ENUM define um tipo com conjunto fixo de valores permitidos.

### Criação e Uso

```sql
-- Criar ENUM
CREATE TYPE status_pedido AS ENUM (
    'pendente',
    'processando',
    'enviado',
    'entregue',
    'cancelado'
);

CREATE TYPE prioridade AS ENUM ('baixa', 'media', 'alta', 'critica');

CREATE TYPE dia_semana AS ENUM (
    'domingo', 'segunda', 'terca', 'quarta', 
    'quinta', 'sexta', 'sabado'
);

-- Usar ENUM
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INT,
    status status_pedido DEFAULT 'pendente',
    prioridade prioridade DEFAULT 'media',
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Inserir
INSERT INTO pedidos (cliente_id, status, prioridade) VALUES
(1, 'pendente', 'alta'),
(2, 'processando', 'media');

-- Erro se valor não existe no ENUM
INSERT INTO pedidos (cliente_id, status) VALUES (3, 'invalido');
-- ERROR: invalid input value for enum status_pedido: "invalido"

-- Comparação e ordenação (segue ordem de criação do ENUM)
SELECT * FROM pedidos 
WHERE status > 'pendente'  -- Retorna: processando, enviado, entregue
ORDER BY prioridade DESC;  -- critica > alta > media > baixa
```

### Gerenciando ENUMs

```sql
-- Adicionar valor ao final
ALTER TYPE status_pedido ADD VALUE 'em_transito';

-- Adicionar valor em posição específica
ALTER TYPE status_pedido ADD VALUE 'aguardando_pagamento' BEFORE 'processando';
ALTER TYPE status_pedido ADD VALUE 'devolvido' AFTER 'entregue';

-- ⚠️ NÃO É POSSÍVEL:
-- - Remover valores de ENUM
-- - Reordenar valores
-- - Renomear valores
-- Solução: Criar novo ENUM e migrar dados

-- Listar valores do ENUM
SELECT enumlabel, enumsortorder
FROM pg_enum e
JOIN pg_type t ON t.oid = e.enumtypid
WHERE t.typname = 'status_pedido'
ORDER BY enumsortorder;

-- Renomear ENUM
ALTER TYPE status_pedido RENAME TO status_do_pedido;

-- Remover ENUM (se não estiver em uso)
DROP TYPE status_pedido CASCADE;
```

### Migração de ENUM

```sql
-- Quando precisa alterar ENUM significativamente
-- 1. Criar novo ENUM
CREATE TYPE status_pedido_novo AS ENUM (
    'rascunho',           -- Novo valor
    'aguardando_pagamento',
    'pendente',
    'processando',
    'em_transito',        -- Novo valor
    'enviado',
    'entregue',
    'cancelado',
    'devolvido'
);

-- 2. Adicionar coluna temporária
ALTER TABLE pedidos ADD COLUMN status_novo status_pedido_novo;

-- 3. Migrar dados
UPDATE pedidos 
SET status_novo = status::TEXT::status_pedido_novo;

-- 4. Remover coluna antiga e renomear
ALTER TABLE pedidos DROP COLUMN status;
ALTER TABLE pedidos RENAME COLUMN status_novo TO status;

-- 5. Limpar
DROP TYPE status_pedido;
ALTER TYPE status_pedido_novo RENAME TO status_pedido;
```

### ENUM vs CHECK Constraint

```sql
-- ENUM
CREATE TYPE cor AS ENUM ('vermelho', 'verde', 'azul');
CREATE TABLE produtos_enum (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    cor cor
);

-- CHECK Constraint
CREATE TABLE produtos_check (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    cor TEXT CHECK (cor IN ('vermelho', 'verde', 'azul'))
);
```

| Aspecto | ENUM | CHECK |
|---------|------|-------|
| **Performance** | Mais rápido (armazenado como int) | Mais lento (texto + validação) |
| **Ordenação** | Ordem definida | Alfabética |
| **Modificação** | Difícil (não pode remover) | Fácil (ALTER TABLE) |
| **Reuso** | ✅ Pode ser reutilizado | ❌ Por tabela |
| **Clareza** | ✅ Tipo explícito | ⚠️ Constraint oculta |

**Recomendação**: Use ENUM para status/estados estáveis. Use CHECK para validações que podem mudar.

---

## 🧱 CREATE TYPE - Tipos Compostos

Tipos compostos são como "structs" ou "classes" sem métodos.

### Criação Básica

```sql
-- Tipo composto para endereço
CREATE TYPE endereco AS (
    rua TEXT,
    numero INT,
    complemento TEXT,
    bairro TEXT,
    cidade TEXT,
    estado CHAR(2),
    cep CHAR(9)
);

-- Tipo composto para dinheiro com moeda
CREATE TYPE dinheiro AS (
    valor NUMERIC(10, 2),
    moeda CHAR(3)
);

-- Tipo composto para período
CREATE TYPE periodo AS (
    inicio TIMESTAMPTZ,
    fim TIMESTAMPTZ
);

-- Usar em tabela
CREATE TABLE empresas (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    endereco_sede endereco,
    endereco_filial endereco,
    faturamento_anual dinheiro
);

-- Inserir com ROW
INSERT INTO empresas (nome, endereco_sede, faturamento_anual) VALUES
('Acme Corp',
 ROW('Av Paulista', 1000, 'Sala 100', 'Bela Vista', 'São Paulo', 'SP', '01310-100'),
 ROW(5000000.00, 'BRL')
);

-- Inserir com sintaxe de texto
INSERT INTO empresas (nome, endereco_sede) VALUES
('Tech Inc',
 '("Rua A", 123, "Andar 5", "Centro", "Rio de Janeiro", "RJ", "20000-000")'::endereco
);
```

### Acessando Campos

```sql
-- Acessar campos (use parênteses)
SELECT 
    nome,
    (endereco_sede).rua,
    (endereco_sede).cidade,
    (endereco_sede).estado,
    (faturamento_anual).valor,
    (faturamento_anual).moeda
FROM empresas;

-- Atualizar campo específico
UPDATE empresas
SET endereco_sede.numero = 2000
WHERE nome = 'Acme Corp';

-- Buscar por campo
SELECT nome FROM empresas
WHERE (endereco_sede).cidade = 'São Paulo';

-- Comparação de tipos compostos (compara todos os campos)
SELECT * FROM empresas
WHERE endereco_sede = ROW('Av Paulista', 2000, 'Sala 100', 'Bela Vista', 'São Paulo', 'SP', '01310-100')::endereco;
```

### Tipo Composto com DOMAIN

```sql
-- Combinar DOMAIN com tipo composto
CREATE DOMAIN email AS TEXT
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

CREATE TYPE contato AS (
    nome TEXT,
    email email,  -- Usa DOMAIN
    telefone TEXT
);

CREATE TABLE fornecedores (
    id SERIAL PRIMARY KEY,
    razao_social TEXT,
    contato_principal contato,
    contato_financeiro contato
);

-- Validação automática do email
INSERT INTO fornecedores (razao_social, contato_principal) VALUES
('Fornecedor XYZ',
 ROW('João Silva', 'joao@fornecedor.com', '(11) 1234-5678')::contato
);

-- Erro: email inválido
INSERT INTO fornecedores (razao_social, contato_principal) VALUES
('Fornecedor ABC',
 ROW('Maria', 'email-invalido', '(11) 8765-4321')::contato
);
-- ERROR: value for domain email violates check constraint
```

### Gerenciando Tipos Compostos

```sql
-- Adicionar campo ao tipo
ALTER TYPE endereco ADD ATTRIBUTE pais VARCHAR(50);

-- Remover campo
ALTER TYPE endereco DROP ATTRIBUTE IF EXISTS pais;

-- Renomear campo
ALTER TYPE endereco RENAME ATTRIBUTE rua TO logradouro;

-- Alterar tipo de campo
ALTER TYPE endereco ALTER ATTRIBUTE numero TYPE VARCHAR(10);

-- Renomear tipo
ALTER TYPE endereco RENAME TO endereco_completo;

-- Listar tipos compostos
SELECT 
    t.typname AS tipo,
    a.attname AS campo,
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS tipo_campo
FROM pg_type t
JOIN pg_attribute a ON a.attrelid = t.typrelid
WHERE t.typtype = 'c'  -- 'c' = composite
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY t.typname, a.attnum;

-- Remover tipo
DROP TYPE endereco CASCADE;
```

---

## 🎯 Quando Criar Tipos Customizados?

### ✅ Crie DOMAINs quando:
- Validações são reutilizadas em múltiplas tabelas
- Quer centralizar regras de negócio no banco
- Tipos nativos são muito genéricos (email, CPF, CEP)
- Documentação ímplicita (tipo explica propósito)

### ✅ Crie ENUMs quando:
- Conjunto de valores é pequeno e estável
- Ordenação específica é importante
- Performance é crítica (vs TEXT + CHECK)
- Estados/status do sistema

### ✅ Crie Tipos Compostos quando:
- Estrutura se repete em múltiplas tabelas
- Dados são logicamente agrupados (endereço, contato)
- Quer passar estruturas em funções
- Reduzir duplicação de definições

### ❌ Evite criar tipos quando:
- Usado em apenas um lugar (use coluna normal)
- Vai mudar frequentemente (ENUM é difícil de alterar)
- Relacionamentos entre entidades (use FK em vez de composto)
- Over-engineering (KISS - Keep It Simple)

---

## 📋 Boas Práticas

### Convenções de Nomenclatura

```sql
-- DOMAINs: snake_case, descritivo
CREATE DOMAIN email_valido AS TEXT CHECK (...);
CREATE DOMAIN cpf_brasileiro AS CHAR(14) CHECK (...);
CREATE DOMAIN valor_monetario_positivo AS NUMERIC(10,2) CHECK (...);

-- ENUMs: snake_case, plural implícito
CREATE TYPE status_pedido AS ENUM (...);
CREATE TYPE nivel_acesso AS ENUM (...);
CREATE TYPE tipo_documento AS ENUM (...);

-- Tipos Compostos: snake_case, singular
CREATE TYPE endereco AS (...);
CREATE TYPE contato AS (...);
CREATE TYPE periodo_temporal AS (...);

-- ❌ Evite
CREATE TYPE t1 AS ...;  -- Nome não descritivo
CREATE TYPE PedidoStatus AS ENUM ...;  -- CamelCase
CREATE TYPE ENDERECO AS ...;  -- UPPERCASE
```

### Documentação

```sql
-- Usar COMMENT para documentar
COMMENT ON DOMAIN email IS 
    'Email validado por regex. Formato: usuario@dominio.ext';

COMMENT ON TYPE status_pedido IS 
    'Estados possíveis de um pedido no sistema. Ordenação representa workflow.';

COMMENT ON TYPE endereco IS 
    'Estrutura completa de endereço brasileiro';

-- Ver comentários
SELECT 
    obj_description('email'::regtype) AS descricao;
```

### Migrations e Versionamento

```sql
-- Sempre versione alterações de tipos
-- migration_001_create_domains.sql
CREATE DOMAIN email AS TEXT
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- migration_002_add_status_enum.sql
CREATE TYPE status_pedido AS ENUM ('pendente', 'processando', 'concluido');

-- migration_003_alter_status_enum.sql
-- Não pode apenas ADD VALUE em produção (pode bloquear)
-- Usar transação separada:
BEGIN;
ALTER TYPE status_pedido ADD VALUE 'cancelado';
COMMIT;
```

---

## 🎓 Resumo

| Tipo | Caso de Uso | Vantagens | Desvantagens |
|------|-------------|-----------|--------------|
| **DOMAIN** | Validações reutilizáveis | Centralização, clareza | Mais difícil de alterar |
| **ENUM** | Conjuntos fixos de valores | Performance, ordenação | Difícil modificar |
| **TYPE (composto)** | Estruturas agrupadas | Reuso, organização | Overhead para casos simples |

---

## 🔗 Navegação

⬅️ [Voltar: Texto](./04-tipos-geometricos-texto.md) | [Índice](./README.md) | [Exercícios →](./exercicios.md)

---

## 📝 Teste Rápido

```sql
-- Crie estes tipos customizados
CREATE DOMAIN slug AS TEXT
    CHECK (VALUE ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$');

CREATE TYPE visibilidade AS ENUM ('privado', 'publico', 'amigos');

CREATE TYPE autor AS (
    nome TEXT,
    email TEXT,
    biografia TEXT
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    slug slug UNIQUE,
    titulo TEXT,
    autor autor,
    visibilidade visibilidade DEFAULT 'privado'
);

-- Teste inserções válidas e inválidas
```

📚 **Exercícios completos**: [Exercícios](./exercicios.md)
