# 1.4 - Permissões em Schemas

## 📋 O que você vai aprender

- Como funcionam as permissões em schemas
- Tipos de privilégios disponíveis
- Como conceder e revogar permissões
- Permissões padrão e boas práticas de segurança
- Cenários práticos de controle de acesso

---

## 🔐 Conceitos Fundamentais

### Níveis de Permissão no PostgreSQL

As permissões no PostgreSQL funcionam em múltiplos níveis hierárquicos:

```
Database
  └── Schema
       └── Objetos (Tabelas, Views, Funções, etc.)
```

**Importante**: Ter permissão em um schema **NÃO** significa automaticamente ter permissão nos objetos dentro dele!

---

## 🎯 Privilégios de Schema

### Tipos de Privilégios

| Privilégio | Descrição |
|------------|-----------|
| `USAGE` | Permite acessar objetos dentro do schema |
| `CREATE` | Permite criar novos objetos no schema |
| `ALL` | Todos os privilégios acima |

---

## 📝 Sintaxe Básica

### Conceder Permissões (GRANT)

```sql
-- Sintaxe geral
GRANT privilégio ON SCHEMA nome_schema TO usuário;

-- Exemplos
GRANT USAGE ON SCHEMA vendas TO usuario_leitura;
GRANT CREATE ON SCHEMA vendas TO usuario_desenvolvedor;
GRANT ALL ON SCHEMA vendas TO usuario_admin;
```

### Revogar Permissões (REVOKE)

```sql
-- Sintaxe geral
REVOKE privilégio ON SCHEMA nome_schema FROM usuário;

-- Exemplos
REVOKE CREATE ON SCHEMA vendas FROM usuario_leitura;
REVOKE ALL ON SCHEMA vendas FROM usuario_temporario;
```

---

## 👥 Cenários Práticos

### Cenário 1: Usuário Somente Leitura

```sql
-- Criar usuário
CREATE USER leitor WITH PASSWORD 'senha_segura';

-- 1. Permitir conexão ao database
GRANT CONNECT ON DATABASE meu_database TO leitor;

-- 2. Permitir acesso ao schema
GRANT USAGE ON SCHEMA vendas TO leitor;

-- 3. Permitir leitura em todas as tabelas existentes
GRANT SELECT ON ALL TABLES IN SCHEMA vendas TO leitor;

-- 4. Garantir acesso a tabelas futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT SELECT ON TABLES TO leitor;
```

### Cenário 2: Usuário com Permissão de Escrita

```sql
-- Criar usuário
CREATE USER escritor WITH PASSWORD 'senha_segura';

-- Conectar ao database
GRANT CONNECT ON DATABASE meu_database TO escritor;

-- Acesso ao schema
GRANT USAGE ON SCHEMA vendas TO escritor;

-- Permissões de leitura e escrita
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA vendas TO escritor;

-- Permissão para usar sequences (importante para SERIAL/IDENTITY)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA vendas TO escritor;

-- Permissões para tabelas futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO escritor;

ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT USAGE, SELECT ON SEQUENCES TO escritor;
```

### Cenário 3: Desenvolvedor com Acesso Total

```sql
-- Criar usuário
CREATE USER desenvolvedor WITH PASSWORD 'senha_segura';

-- Acesso completo ao schema
GRANT ALL ON SCHEMA vendas TO desenvolvedor;

-- Todas as permissões em objetos
GRANT ALL ON ALL TABLES IN SCHEMA vendas TO desenvolvedor;
GRANT ALL ON ALL SEQUENCES IN SCHEMA vendas TO desenvolvedor;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA vendas TO desenvolvedor;

-- Objetos futuros
ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT ALL ON TABLES TO desenvolvedor;

ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT ALL ON SEQUENCES TO desenvolvedor;

ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT ALL ON FUNCTIONS TO desenvolvedor;
```

### Cenário 4: Multi-tenant (Isolamento entre Clientes)

```sql
-- Criar usuários para cada cliente
CREATE USER cliente_a_user WITH PASSWORD 'senha_a';
CREATE USER cliente_b_user WITH PASSWORD 'senha_b';

-- Criar schemas
CREATE SCHEMA cliente_a AUTHORIZATION cliente_a_user;
CREATE SCHEMA cliente_b AUTHORIZATION cliente_b_user;

-- Cliente A só acessa seu schema
GRANT CONNECT ON DATABASE app_database TO cliente_a_user;
GRANT ALL ON SCHEMA cliente_a TO cliente_a_user;
GRANT ALL ON ALL TABLES IN SCHEMA cliente_a TO cliente_a_user;

-- Cliente B só acessa seu schema
GRANT CONNECT ON DATABASE app_database TO cliente_b_user;
GRANT ALL ON SCHEMA cliente_b TO cliente_b_user;
GRANT ALL ON ALL TABLES IN SCHEMA cliente_b TO cliente_b_user;

-- Revogar acesso ao schema public (segurança)
REVOKE ALL ON SCHEMA public FROM PUBLIC;
```

---

## 🔍 Consultando Permissões

### Ver Permissões de Schema

```sql
-- Método 1: Usando \dn+ no psql
\dn+ nome_schema

-- Método 2: Consulta SQL
SELECT 
    nspname AS schema_name,
    nspowner::regrole AS owner,
    nspacl AS permissions
FROM pg_namespace
WHERE nspname = 'vendas';

-- Método 3: Formato mais legível
SELECT 
    schemaname,
    schemaowner,
    CASE 
        WHEN array_position(nspacl::text[], usename) IS NOT NULL 
        THEN 'TEM ACESSO'
        ELSE 'SEM ACESSO'
    END AS acesso
FROM pg_namespace
CROSS JOIN pg_user
WHERE nspname = 'vendas';
```

### Ver Permissões de Tabelas em um Schema

```sql
SELECT 
    schemaname,
    tablename,
    tableowner,
    has_table_privilege('nome_usuario', schemaname||'.'||tablename, 'SELECT') AS pode_select,
    has_table_privilege('nome_usuario', schemaname||'.'||tablename, 'INSERT') AS pode_insert,
    has_table_privilege('nome_usuario', schemaname||'.'||tablename, 'UPDATE') AS pode_update,
    has_table_privilege('nome_usuario', schemaname||'.'||tablename, 'DELETE') AS pode_delete
FROM pg_tables
WHERE schemaname = 'vendas';
```

### Verificar Suas Próprias Permissões

```sql
-- Ver seus privilégios em um schema
SELECT has_schema_privilege('vendas', 'USAGE') AS pode_usar;
SELECT has_schema_privilege('vendas', 'CREATE') AS pode_criar;

-- Ver suas permissões em uma tabela específica
SELECT has_table_privilege('vendas.produtos', 'SELECT') AS pode_ler;
SELECT has_table_privilege('vendas.produtos', 'INSERT') AS pode_inserir;
```

---

## 🛡️ Permissões Padrão e Segurança

### Permissões Padrão do Schema PUBLIC

```sql
-- Por padrão, PUBLIC tem permissões no schema public
-- Isso pode ser um risco de segurança!

-- ✅ Boa prática: Revogar permissões públicas
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Conceder apenas a usuários específicos
GRANT USAGE ON SCHEMA public TO usuario_especifico;
```

### Configurar Permissões Padrão para Objetos Futuros

```sql
-- Para o dono do schema
ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT SELECT ON TABLES TO usuario_leitura;

-- Para um usuário específico que cria objetos
ALTER DEFAULT PRIVILEGES FOR ROLE desenvolvedor IN SCHEMA vendas
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
```

---

## ⚙️ Roles e Grupos

### Usar Roles para Gerenciamento Simplificado

```sql
-- Criar role (grupo) de leitura
CREATE ROLE role_leitura;
GRANT CONNECT ON DATABASE meu_database TO role_leitura;
GRANT USAGE ON SCHEMA vendas TO role_leitura;
GRANT SELECT ON ALL TABLES IN SCHEMA vendas TO role_leitura;

-- Criar role de escrita
CREATE ROLE role_escrita;
GRANT role_leitura TO role_escrita; -- Herda permissões de leitura
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA vendas TO role_escrita;

-- Atribuir roles a usuários
CREATE USER usuario1 WITH PASSWORD 'senha1';
GRANT role_leitura TO usuario1;

CREATE USER usuario2 WITH PASSWORD 'senha2';
GRANT role_escrita TO usuario2;
```

---

## 🚨 Problemas Comuns e Soluções

### Problema 1: "permission denied for schema"

```sql
-- Erro comum
SELECT * FROM vendas.produtos;
-- ERROR: permission denied for schema vendas

-- ✅ Solução
GRANT USAGE ON SCHEMA vendas TO seu_usuario;
```

### Problema 2: "permission denied for table"

```sql
-- Você tem USAGE no schema mas não acesso à tabela
SELECT * FROM vendas.produtos;
-- ERROR: permission denied for table produtos

-- ✅ Solução
GRANT SELECT ON vendas.produtos TO seu_usuario;
-- ou para todas as tabelas:
GRANT SELECT ON ALL TABLES IN SCHEMA vendas TO seu_usuario;
```

### Problema 3: Não consegue usar SERIAL/IDENTITY

```sql
-- INSERT falha em campo SERIAL
INSERT INTO vendas.produtos (nome) VALUES ('Produto A');
-- ERROR: permission denied for sequence produtos_id_seq

-- ✅ Solução
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA vendas TO seu_usuario;
```

### Problema 4: Tabelas novas não têm permissões

```sql
-- Usuário tinha acesso, mas nova tabela não funciona
-- ✅ Solução: Configurar permissões padrão
ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT SELECT ON TABLES TO usuario_leitura;
```

---

## 📋 Checklist de Segurança

- [ ] Revogar permissões do schema `public` para usuários comuns
- [ ] Usar roles/groups em vez de conceder permissões individualmente
- [ ] Configurar `ALTER DEFAULT PRIVILEGES` para objetos futuros
- [ ] Princípio do menor privilégio: conceder apenas o necessário
- [ ] Documentar quais usuários/roles têm quais permissões
- [ ] Auditar permissões regularmente
- [ ] Usar senhas fortes para todos os usuários
- [ ] Considerar uso de SECURITY DEFINER em funções sensíveis

---

## 🎓 Resumo de Comandos

```sql
-- Conceder acesso ao schema
GRANT USAGE ON SCHEMA nome TO usuario;

-- Conceder criação no schema
GRANT CREATE ON SCHEMA nome TO usuario;

-- Conceder acesso a tabelas
GRANT SELECT ON ALL TABLES IN SCHEMA nome TO usuario;

-- Permissões para objetos futuros
ALTER DEFAULT PRIVILEGES IN SCHEMA nome
    GRANT SELECT ON TABLES TO usuario;

-- Revogar permissões
REVOKE CREATE ON SCHEMA nome FROM usuario;

-- Verificar permissões
SELECT has_schema_privilege('nome', 'USAGE');
```

---

## 🔗 Navegação

⬅️ [Anterior: Search Path](./03-search-path.md) | [Próximo: Boas Práticas com Schemas →](./05-boas-praticas-schemas.md)

---

## 📝 Exercício Prático

```sql
-- 1. Criar schema de teste
CREATE SCHEMA teste_permissoes;

-- 2. Criar uma tabela
CREATE TABLE teste_permissoes.dados (
    id SERIAL PRIMARY KEY,
    informacao TEXT
);

-- 3. Criar usuário de teste (se tiver permissão)
-- CREATE USER teste_user WITH PASSWORD 'senha123';

-- 4. Tentar acessar sem permissões (como teste_user)
-- SET ROLE teste_user;
-- SELECT * FROM teste_permissoes.dados; -- ERRO esperado

-- 5. Conceder permissões
-- RESET ROLE;
-- GRANT USAGE ON SCHEMA teste_permissoes TO teste_user;
-- GRANT SELECT ON teste_permissoes.dados TO teste_user;

-- 6. Testar novamente
-- SET ROLE teste_user;
-- SELECT * FROM teste_permissoes.dados; -- Deve funcionar

-- 7. Limpar
-- RESET ROLE;
-- DROP SCHEMA teste_permissoes CASCADE;
-- DROP USER IF EXISTS teste_user;
```
