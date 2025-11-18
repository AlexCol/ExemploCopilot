# 1.2 - Criando e Gerenciando Schemas

## 📋 O que você vai aprender

- Como criar schemas
- Como renomear schemas
- Como excluir schemas
- Como mover objetos entre schemas
- Boas práticas de nomenclatura

---

## 🎯 Criando Schemas

### Sintaxe Básica

```sql
CREATE SCHEMA nome_do_schema;
```

### Exemplos Práticos

```sql
-- Criar schema simples
CREATE SCHEMA vendas;

-- Criar schema com dono específico
CREATE SCHEMA rh AUTHORIZATION usuario_rh;

-- Criar schema apenas se não existir
CREATE SCHEMA IF NOT EXISTS financeiro;

-- Criar schema e objetos simultaneamente
CREATE SCHEMA marketing
    CREATE TABLE campanhas (
        id SERIAL PRIMARY KEY,
        nome VARCHAR(100),
        data_inicio DATE
    )
    CREATE TABLE leads (
        id SERIAL PRIMARY KEY,
        email VARCHAR(100),
        origem VARCHAR(50)
    );
```

---

## 📝 Criando Objetos dentro de um Schema

### Especificando o Schema Explicitamente

```sql
-- Criar tabela em schema específico
CREATE TABLE vendas.produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10, 2),
    estoque INT DEFAULT 0
);

-- Criar view em schema específico
CREATE VIEW vendas.produtos_em_estoque AS
SELECT nome, preco, estoque
FROM vendas.produtos
WHERE estoque > 0;

-- Criar função em schema específico
CREATE FUNCTION vendas.calcular_total(quantidade INT, preco DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
    RETURN quantidade * preco;
END;
$$ LANGUAGE plpgsql;
```

---

## 🔄 Renomeando Schemas

```sql
-- Renomear um schema
ALTER SCHEMA vendas RENAME TO comercial;

-- Alterar o dono de um schema
ALTER SCHEMA comercial OWNER TO novo_usuario;
```

**⚠️ Atenção**: Renomear um schema não atualiza automaticamente referências em código de aplicação!

---

## 🗑️ Excluindo Schemas

### Exclusão Simples

```sql
-- Excluir schema vazio
DROP SCHEMA nome_schema;

-- Excluir apenas se existir
DROP SCHEMA IF EXISTS nome_schema;
```

### Exclusão em Cascata

```sql
-- Excluir schema e TODOS os objetos dentro dele
DROP SCHEMA nome_schema CASCADE;
```

**⚠️ CUIDADO**: `CASCADE` remove permanentemente todas as tabelas, views, funções, etc. dentro do schema!

### Exemplo Prático

```sql
-- Criar schema de teste
CREATE SCHEMA temp_teste;

-- Criar alguns objetos
CREATE TABLE temp_teste.tabela1 (id INT);
CREATE TABLE temp_teste.tabela2 (id INT);

-- Tentar excluir (vai dar erro se não estiver vazio)
DROP SCHEMA temp_teste; -- ERRO!

-- Excluir com CASCADE
DROP SCHEMA temp_teste CASCADE; -- Sucesso!
```

---

## 🔀 Movendo Objetos Entre Schemas

### Mover Tabelas

```sql
-- Sintaxe
ALTER TABLE schema_origem.tabela SET SCHEMA schema_destino;

-- Exemplo
ALTER TABLE public.clientes SET SCHEMA vendas;
```

### Mover Outros Objetos

```sql
-- Mover função
ALTER FUNCTION public.calcular_desconto(DECIMAL) SET SCHEMA vendas;

-- Mover view
ALTER VIEW public.relatorio_vendas SET SCHEMA vendas;

-- Mover sequência
ALTER SEQUENCE public.seq_pedidos SET SCHEMA vendas;

-- Mover tipo customizado
ALTER TYPE public.status_pedido SET SCHEMA vendas;
```

---

## 📊 Consultando Informações sobre Schemas

### Ver Schemas Existentes

```sql
-- Listar schemas e seus donos
SELECT 
    schema_name,
    schema_owner
FROM information_schema.schemata
WHERE schema_name NOT IN ('pg_catalog', 'information_schema')
ORDER BY schema_name;

-- Comando PostgreSQL
\dn+
```

### Ver Objetos em um Schema

```sql
-- Tabelas em um schema
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'vendas';

-- Todas as funções em um schema
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'vendas';
```

### Tamanho de um Schema

```sql
-- Ver tamanho de todas as tabelas em um schema
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'vendas'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## 📏 Boas Práticas de Nomenclatura

### ✅ Recomendado

```sql
-- Usar minúsculas e underscores
CREATE SCHEMA vendas_online;
CREATE SCHEMA recursos_humanos;
CREATE SCHEMA bi_analytics;

-- Nomes descritivos e claros
CREATE SCHEMA cliente_acme;
CREATE SCHEMA ambiente_dev;
```

### ❌ Evitar

```sql
-- Evitar caracteres especiais ou espaços
CREATE SCHEMA "Vendas & Marketing";  -- Problemático

-- Evitar nomes muito genéricos
CREATE SCHEMA dados;  -- Pouco descritivo
CREATE SCHEMA temp;   -- Pode causar confusão
```

---

## 💡 Exemplo Completo: Estrutura Multi-Ambiente

```sql
-- Criar estrutura para diferentes ambientes
CREATE SCHEMA IF NOT EXISTS prod;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dev;

-- Criar mesma estrutura em cada ambiente
CREATE TABLE prod.usuarios (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    nome VARCHAR(100)
);

CREATE TABLE staging.usuarios (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    nome VARCHAR(100)
);

CREATE TABLE dev.usuarios (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    nome VARCHAR(100)
);

-- Listar todos
SELECT schemaname, tablename 
FROM pg_tables 
WHERE schemaname IN ('prod', 'staging', 'dev')
ORDER BY schemaname, tablename;
```

---

## 🎓 Resumo dos Comandos

| Operação | Comando |
|----------|---------|
| Criar schema | `CREATE SCHEMA nome;` |
| Criar se não existir | `CREATE SCHEMA IF NOT EXISTS nome;` |
| Renomear | `ALTER SCHEMA velho RENAME TO novo;` |
| Excluir vazio | `DROP SCHEMA nome;` |
| Excluir com conteúdo | `DROP SCHEMA nome CASCADE;` |
| Mover tabela | `ALTER TABLE schema1.tab SET SCHEMA schema2;` |
| Listar schemas | `\dn` ou `SELECT * FROM information_schema.schemata;` |

---

## 🔗 Navegação

⬅️ [Anterior: Introdução a Schemas](./01-introducao-schemas.md) | [Próximo: Search Path →](./03-search-path.md)

---

## 📝 Exercícios Práticos

Execute estes comandos para praticar:

```sql
-- 1. Criar um schema de teste
CREATE SCHEMA loja_teste;

-- 2. Criar uma tabela neste schema
CREATE TABLE loja_teste.produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100)
);

-- 3. Inserir alguns dados
INSERT INTO loja_teste.produtos (nome) VALUES ('Produto A'), ('Produto B');

-- 4. Consultar
SELECT * FROM loja_teste.produtos;

-- 5. Mover para outro schema
CREATE SCHEMA loja_novo;
ALTER TABLE loja_teste.produtos SET SCHEMA loja_novo;

-- 6. Verificar
SELECT * FROM loja_novo.produtos;

-- 7. Limpar
DROP SCHEMA loja_teste;
DROP SCHEMA loja_novo CASCADE;
```
