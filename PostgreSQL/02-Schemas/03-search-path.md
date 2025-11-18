# 1.3 - Search Path no PostgreSQL

## 📋 O que você vai aprender

- O que é o search_path
- Como funciona a resolução de nomes
- Como configurar o search_path
- Quando e por que modificar o search_path
- Problemas comuns e soluções

---

## 🎯 O que é Search Path?

O **search_path** é uma configuração que define em quais schemas o PostgreSQL deve procurar objetos quando você não especifica o schema explicitamente.

### Analogia

É como a variável `PATH` em sistemas operacionais: quando você digita um comando sem especificar o caminho completo, o sistema procura em uma lista de diretórios predefinidos.

---

## 🔍 Search Path Padrão

Por padrão, o search_path é:

```sql
-- Ver o search_path atual
SHOW search_path;
-- Resultado típico: "$user", public
```

Isso significa:
1. **"$user"**: Procura primeiro em um schema com o nome do usuário atual (se existir)
2. **public**: Depois procura no schema `public`

---

## 📊 Como Funciona a Resolução de Nomes

### Exemplo Prático

```sql
-- Cenário
CREATE SCHEMA vendas;
CREATE SCHEMA estoque;

CREATE TABLE public.produtos (id INT, nome VARCHAR(50));
CREATE TABLE vendas.produtos (id INT, nome VARCHAR(50), preco DECIMAL);
CREATE TABLE estoque.produtos (id INT, nome VARCHAR(50), quantidade INT);

-- Consulta sem especificar schema
SELECT * FROM produtos;
-- Qual tabela será usada? Depende do search_path!
```

### Ordem de Busca

Com `search_path = "$user", public`:

```sql
SELECT * FROM produtos;
-- PostgreSQL procura nesta ordem:
-- 1. schema com nome do usuário atual (se existir)
-- 2. public.produtos ← Encontra aqui e usa esta!
-- 3. Se não encontrar, retorna erro
```

---

## ⚙️ Configurando o Search Path

### Ver o Search Path Atual

```sql
-- Método 1
SHOW search_path;

-- Método 2
SELECT current_setting('search_path');

-- Ver schema atual sendo usado
SELECT current_schema();

-- Ver todos os schemas no search_path
SELECT unnest(current_schemas(true));
```

### Modificar para a Sessão Atual

```sql
-- Definir novo search_path (temporário - apenas esta sessão)
SET search_path TO vendas, public;

-- Agora consultas sem schema usarão vendas primeiro
SELECT * FROM produtos; -- usa vendas.produtos

-- Adicionar schema ao início
SET search_path TO estoque, vendas, public;

-- Resetar ao padrão
RESET search_path;
```

### Modificar Permanentemente para um Usuário

```sql
-- Definir search_path padrão para um usuário
ALTER USER meu_usuario SET search_path TO vendas, public;

-- Definir para o usuário atual
ALTER USER CURRENT_USER SET search_path TO vendas, estoque, public;

-- Resetar ao padrão do sistema
ALTER USER meu_usuario RESET search_path;
```

### Modificar para um Database

```sql
-- Definir search_path padrão para todo um database
ALTER DATABASE meu_database SET search_path TO vendas, public;
```

---

## 🎯 Casos de Uso Práticos

### Caso 1: Aplicação Multi-tenant

```sql
-- Cada cliente tem seu schema
CREATE SCHEMA cliente_a;
CREATE SCHEMA cliente_b;
CREATE SCHEMA comum; -- schemas compartilhados

-- Ao conectar cliente A
SET search_path TO cliente_a, comum, public;

-- Ao conectar cliente B
SET search_path TO cliente_b, comum, public;

-- Agora cada cliente vê apenas seus dados
SELECT * FROM pedidos; -- cada um vê seus próprios pedidos
```

### Caso 2: Versionamento de Schema

```sql
-- Diferentes versões da aplicação
CREATE SCHEMA app_v1;
CREATE SCHEMA app_v2;
CREATE SCHEMA app_v3;

-- Aplicação antiga
SET search_path TO app_v1, public;

-- Aplicação nova
SET search_path TO app_v3, app_v2, public;
```

### Caso 3: Desenvolvimento vs Produção

```sql
-- Trabalhar em dev mas ter fallback para produção
SET search_path TO dev, prod, public;

-- Tabelas em dev são usadas primeiro
-- Se não existir em dev, usa a de prod
SELECT * FROM usuarios; -- dev.usuarios se existir, senão prod.usuarios
```

---

## ⚠️ Armadilhas e Problemas Comuns

### Problema 1: Ambiguidade de Objetos

```sql
-- Dois schemas com mesma tabela
CREATE SCHEMA vendas;
CREATE SCHEMA financeiro;

CREATE TABLE vendas.transacoes (id INT, tipo VARCHAR(20));
CREATE TABLE financeiro.transacoes (id INT, valor DECIMAL);

SET search_path TO vendas, financeiro, public;

-- Qual tabela é usada?
SELECT * FROM transacoes; -- vendas.transacoes (primeiro no search_path)

-- ✅ Solução: Seja explícito
SELECT * FROM financeiro.transacoes;
```

### Problema 2: Segurança - Search Path Injection

```sql
-- ⚠️ PERIGO: Usuário malicioso cria função no schema público
CREATE FUNCTION public.funcao_segura() RETURNS TEXT AS $$
BEGIN
    -- código malicioso
    RETURN 'comprometido';
END;
$$ LANGUAGE plpgsql;

-- ✅ Solução 1: Remover public do search_path
SET search_path TO seu_schema;

-- ✅ Solução 2: Sempre usar schema.objeto em funções críticas
CREATE FUNCTION meu_schema.processar_pagamento() AS $$
BEGIN
    -- Use sempre: meu_schema.funcao_interna()
    -- Não use: funcao_interna() sem schema
END;
$$ LANGUAGE plpgsql;
```

### Problema 3: Performance

```sql
-- Search path muito longo pode afetar performance
SET search_path TO s1, s2, s3, s4, s5, s6, s7, s8, public;

-- ✅ Solução: Mantenha search_path conciso
SET search_path TO seu_schema_principal, public;
```

---

## 🛡️ Boas Práticas

### 1. Seja Explícito em Código Crítico

```sql
-- ❌ Evitar em produção
SELECT * FROM usuarios;

-- ✅ Preferir
SELECT * FROM vendas.usuarios;
```

### 2. Configure por Usuário, não por Sessão

```sql
-- ✅ Configuração permanente
ALTER USER app_user SET search_path TO app_schema, public;

-- ❌ Ter que fazer isso em toda conexão
SET search_path TO app_schema, public;
```

### 3. Documente o Search Path Esperado

```sql
-- No início dos seus scripts
-- Este script assume: search_path = 'vendas, public'
SET search_path TO vendas, public;

-- Seu código aqui...
```

### 4. Use Schema Qualificado em Funções

```sql
-- ✅ Boa prática
CREATE FUNCTION vendas.processar_pedido(pedido_id INT) RETURNS VOID AS $$
BEGIN
    -- Use schema.tabela
    UPDATE vendas.pedidos SET status = 'processado' 
    WHERE id = pedido_id;
END;
$$ LANGUAGE plpgsql;
```

---

## 💡 Comandos Úteis para Debug

```sql
-- Ver search_path atual
SHOW search_path;

-- Ver schema sendo usado atualmente
SELECT current_schema();

-- Ver todos schemas no search_path (incluindo implícitos)
SELECT unnest(current_schemas(true));

-- Ver todos schemas no search_path (excluindo implícitos)
SELECT unnest(current_schemas(false));

-- Testar qual schema seria usado para um objeto
SELECT 
    n.nspname AS schema_name
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relname = 'nome_da_tabela'
AND n.nspname = ANY(current_schemas(false))
ORDER BY array_position(current_schemas(false), n.nspname)
LIMIT 1;
```

---

## 🎓 Resumo

| Comando | Descrição |
|---------|-----------|
| `SHOW search_path;` | Ver search_path atual |
| `SET search_path TO s1, s2;` | Modificar para sessão |
| `ALTER USER u SET search_path TO s1;` | Modificar permanente para usuário |
| `RESET search_path;` | Voltar ao padrão |
| `SELECT current_schema();` | Ver schema atual |
| `SELECT current_schemas(true);` | Ver todos schemas no path |

---

## 🔗 Navegação

⬅️ [Anterior: Criando e Gerenciando Schemas](./02-criando-gerenciando-schemas.md) | [Próximo: Permissões em Schemas →](./04-permissoes-schemas.md)

---

## 📝 Exercícios Práticos

```sql
-- 1. Ver seu search_path atual
SHOW search_path;

-- 2. Criar schemas de teste
CREATE SCHEMA teste_a;
CREATE SCHEMA teste_b;

-- 3. Criar tabelas com mesmo nome
CREATE TABLE teste_a.dados (id INT, origem VARCHAR(10) DEFAULT 'schema_a');
CREATE TABLE teste_b.dados (id INT, origem VARCHAR(10) DEFAULT 'schema_b');

INSERT INTO teste_a.dados (id) VALUES (1);
INSERT INTO teste_b.dados (id) VALUES (2);

-- 4. Testar search_path
SET search_path TO teste_a, teste_b, public;
SELECT * FROM dados; -- Qual resultado?

SET search_path TO teste_b, teste_a, public;
SELECT * FROM dados; -- E agora?

-- 5. Ser explícito
SELECT * FROM teste_a.dados;
SELECT * FROM teste_b.dados;

-- 6. Limpar
DROP SCHEMA teste_a CASCADE;
DROP SCHEMA teste_b CASCADE;
RESET search_path;
```
