# 11.4 - Sistema de Policies e GRANT Avançado

## 📋 O que você vai aprender

- Entendimento profundo de GRANT/REVOKE
- DEFAULT PRIVILEGES
- Hierarquia de roles com INHERIT
- Padrões de segurança escaláveis
- Auditoria de permissões

---

## 🎯 GRANT/REVOKE: Fundamentos

### Sintaxe Básica

```sql
-- Conceder permissões
GRANT privilege [, ...]
ON object
TO role [, ...];

-- Revogar permissões
REVOKE privilege [, ...]
ON object
FROM role [, ...];
```

### Tipos de Privilégios

```sql
-- Tabelas
GRANT SELECT, INSERT, UPDATE, DELETE ON tabela TO role;
GRANT ALL PRIVILEGES ON tabela TO role;

-- Sequences
GRANT USAGE, SELECT ON SEQUENCE seq TO role;

-- Schemas
GRANT USAGE ON SCHEMA public TO role;
GRANT CREATE ON SCHEMA public TO role;

-- Databases
GRANT CONNECT ON DATABASE mydb TO role;
GRANT CREATE ON DATABASE mydb TO role;

-- Functions
GRANT EXECUTE ON FUNCTION minha_func(INT) TO role;

-- ALL: todas as permissões disponíveis para o tipo de objeto
GRANT ALL ON ALL TABLES IN SCHEMA public TO admin_role;
```

---

## 🚀 DEFAULT PRIVILEGES

Define permissões para objetos **futuros** criados por um role.

### Problema Comum

```sql
-- Admin cria role e concede permissões
CREATE ROLE app_user;
GRANT SELECT ON tabela1 TO app_user;

-- Mais tarde, admin cria nova tabela
CREATE TABLE tabela2 (...);

-- app_user NÃO tem acesso automático a tabela2! ❌
SET ROLE app_user;
SELECT * FROM tabela2;  -- ERROR: permission denied
```

### Solução: DEFAULT PRIVILEGES

```sql
-- Definir permissões padrão para TABELAS criadas por admin_role
ALTER DEFAULT PRIVILEGES 
FOR ROLE admin_role
IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;

-- Agora, toda tabela criada por admin_role automaticamente dá acesso a app_user!
SET ROLE admin_role;
CREATE TABLE tabela3 (id INT);

SET ROLE app_user;
SELECT * FROM tabela3;  -- ✅ Funciona!

RESET ROLE;
```

### Padrão para Diferentes Objetos

```sql
-- Sequences
ALTER DEFAULT PRIVILEGES 
FOR ROLE admin_role
GRANT USAGE, SELECT ON SEQUENCES TO app_user;

-- Functions
ALTER DEFAULT PRIVILEGES 
FOR ROLE admin_role
GRANT EXECUTE ON FUNCTIONS TO app_user;

-- Types
ALTER DEFAULT PRIVILEGES 
FOR ROLE admin_role
GRANT USAGE ON TYPES TO app_user;

-- Para TODOS os roles (não recomendado)
ALTER DEFAULT PRIVILEGES 
GRANT SELECT ON TABLES TO PUBLIC;
```

---

## 👥 Hierarquia de Roles com INHERIT

Roles podem herdar permissões de outros roles.

### Criando Hierarquia

```sql
-- Roles base (grupos)
CREATE ROLE readonly;
CREATE ROLE readwrite;
CREATE ROLE admin;

-- Permissões dos grupos
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO readwrite;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;

-- Usuários concretos que HERDAM de grupos
CREATE ROLE usuario1 WITH LOGIN PASSWORD 'senha1' INHERIT;
CREATE ROLE usuario2 WITH LOGIN PASSWORD 'senha2' INHERIT;

-- Adicionar usuários aos grupos
GRANT readonly TO usuario1;
GRANT readwrite TO usuario2;

-- usuario1 AUTOMATICAMENTE tem SELECT (herda de readonly)
-- usuario2 AUTOMATICAMENTE tem SELECT, INSERT, UPDATE, DELETE (herda de readwrite)
```

### INHERIT vs NOINHERIT

```sql
-- Com INHERIT (padrão): permissões automáticas
CREATE ROLE user1 WITH LOGIN INHERIT;
GRANT readonly TO user1;

SET ROLE user1;
SELECT * FROM tabela;  -- ✅ Funciona (herda permissão)

RESET ROLE;

-- Com NOINHERIT: precisa SET ROLE manualmente
CREATE ROLE user2 WITH LOGIN NOINHERIT;
GRANT readonly TO user2;

SET ROLE user2;
SELECT * FROM tabela;  -- ❌ ERROR: permission denied

SET ROLE readonly;  -- Precisa "ativar" o role manualmente
SELECT * FROM tabela;  -- ✅ Agora funciona

RESET ROLE;
```

---

## 🏗️ Padrão de Segurança Escalável

Arquitetura recomendada para aplicações reais.

### Estrutura de Roles

```sql
-- 1. Roles de grupo (sem LOGIN)
CREATE ROLE db_owner;      -- Donos do schema, podem criar objetos
CREATE ROLE db_writer;     -- Leitura e escrita
CREATE ROLE db_reader;     -- Apenas leitura
CREATE ROLE db_executor;   -- Apenas executar functions

-- 2. Permissões dos grupos
-- db_owner
GRANT ALL PRIVILEGES ON SCHEMA public TO db_owner;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_owner;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO db_owner;
ALTER DEFAULT PRIVILEGES FOR ROLE db_owner 
    GRANT ALL ON TABLES TO db_owner;

-- db_writer
GRANT USAGE ON SCHEMA public TO db_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO db_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO db_writer;
ALTER DEFAULT PRIVILEGES FOR ROLE db_owner 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO db_writer;

-- db_reader
GRANT USAGE ON SCHEMA public TO db_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO db_reader;
ALTER DEFAULT PRIVILEGES FOR ROLE db_owner 
    GRANT SELECT ON TABLES TO db_reader;

-- db_executor
GRANT USAGE ON SCHEMA public TO db_executor;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO db_executor;
ALTER DEFAULT PRIVILEGES FOR ROLE db_owner 
    GRANT EXECUTE ON FUNCTIONS TO db_executor;

-- 3. Usuários concretos (com LOGIN)
CREATE ROLE app_admin WITH LOGIN PASSWORD 'xxx' INHERIT;
CREATE ROLE app_service WITH LOGIN PASSWORD 'yyy' INHERIT;
CREATE ROLE app_readonly WITH LOGIN PASSWORD 'zzz' INHERIT;

-- 4. Atribuir grupos aos usuários
GRANT db_owner TO app_admin;
GRANT db_writer, db_executor TO app_service;
GRANT db_reader TO app_readonly;
```

### Multi-schema com Segurança

```sql
-- Schemas separados por domínio
CREATE SCHEMA vendas;
CREATE SCHEMA financeiro;
CREATE SCHEMA rh;

-- Roles específicos por schema
CREATE ROLE vendas_team;
CREATE ROLE financeiro_team;
CREATE ROLE rh_team;

-- Permissões isoladas
GRANT USAGE ON SCHEMA vendas TO vendas_team;
GRANT ALL ON ALL TABLES IN SCHEMA vendas TO vendas_team;

GRANT USAGE ON SCHEMA financeiro TO financeiro_team;
GRANT ALL ON ALL TABLES IN SCHEMA financeiro TO financeiro_team;

GRANT USAGE ON SCHEMA rh TO rh_team;
GRANT ALL ON ALL TABLES IN SCHEMA rh TO rh_team;

-- DEFAULT PRIVILEGES por schema
ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO vendas_team;

ALTER DEFAULT PRIVILEGES IN SCHEMA financeiro
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO financeiro_team;

-- Usuários
CREATE ROLE vendedor1 WITH LOGIN PASSWORD 'xxx';
CREATE ROLE contador1 WITH LOGIN PASSWORD 'yyy';

GRANT vendas_team TO vendedor1;
GRANT financeiro_team TO contador1;

-- vendedor1: acessa schema vendas, NÃO acessa financeiro ✅
-- contador1: acessa schema financeiro, NÃO acessa vendas ✅
```

---

## 🔍 Auditoria de Permissões

### Ver Permissões de um Role

```sql
-- Permissões de tabelas
SELECT 
    schemaname,
    tablename,
    tableowner,
    has_table_privilege('app_user', schemaname||'.'||tablename, 'SELECT') AS can_select,
    has_table_privilege('app_user', schemaname||'.'||tablename, 'INSERT') AS can_insert,
    has_table_privilege('app_user', schemaname||'.'||tablename, 'UPDATE') AS can_update,
    has_table_privilege('app_user', schemaname||'.'||tablename, 'DELETE') AS can_delete
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema');

-- Membership de roles
SELECT 
    r.rolname AS member,
    r_group.rolname AS member_of
FROM pg_roles r
JOIN pg_auth_members m ON r.oid = m.member
JOIN pg_roles r_group ON m.roleid = r_group.oid
WHERE r.rolname = 'app_user';

-- Ver DEFAULT PRIVILEGES
SELECT 
    defaclnamespace::regnamespace AS schema,
    defaclrole::regrole AS grantor,
    defaclobjtype AS object_type,
    defaclacl AS privileges
FROM pg_default_acl;
```

### Função Helper para Debug

```sql
CREATE FUNCTION check_permissions(p_role TEXT, p_table TEXT) 
RETURNS TABLE (
    privilege TEXT,
    has_permission BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        priv,
        has_table_privilege(p_role, p_table, priv)
    FROM (VALUES 
        ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'), 
        ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
    ) AS t(priv);
END;
$$ LANGUAGE plpgsql;

-- Uso
SELECT * FROM check_permissions('app_user', 'clientes');
/*
 privilege  | has_permission
------------+----------------
 SELECT     | t
 INSERT     | t
 UPDATE     | f
 DELETE     | f
*/
```

---

## ⚠️ Armadilhas Comuns

### 1. Esquecer USAGE no Schema

```sql
-- ❌ GRANT na tabela, mas esquece schema
GRANT SELECT ON public.tabela TO role;

SET ROLE role;
SELECT * FROM public.tabela;  
-- ERROR: permission denied for schema "public"

RESET ROLE;

-- ✅ Precisa de USAGE no schema primeiro
GRANT USAGE ON SCHEMA public TO role;
GRANT SELECT ON public.tabela TO role;
```

### 2. REVOKE Não Remove Permissões Herdadas

```sql
CREATE ROLE grupo;
CREATE ROLE usuario WITH LOGIN INHERIT;
GRANT SELECT ON tabela TO grupo;
GRANT grupo TO usuario;

-- Tentar revogar do usuário não funciona
REVOKE SELECT ON tabela FROM usuario;  
-- Não tem efeito! usuario ainda tem SELECT via grupo

-- ✅ Precisa revogar do grupo ou remover membership
REVOKE SELECT ON tabela FROM grupo;
-- Ou
REVOKE grupo FROM usuario;
```

### 3. PUBLIC Role

```sql
-- PUBLIC é um role especial = TODOS os roles

-- ⚠️ Cuidado: isso dá acesso a QUALQUER usuário!
GRANT SELECT ON tabela_sensivel TO PUBLIC;

-- ✅ Melhor: revocar PUBLIC e conceder explicitamente
REVOKE ALL ON tabela_sensivel FROM PUBLIC;
GRANT SELECT ON tabela_sensivel TO app_role;
```

---

## 🎯 Boas Práticas

### 1. Princípio do Menor Privilégio

```sql
-- ❌ Ruim: dar mais permissões que necessário
GRANT ALL PRIVILEGES ON DATABASE mydb TO app_user;

-- ✅ Bom: apenas o necessário
GRANT CONNECT ON DATABASE mydb TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE ON specific_tables TO app_user;
```

### 2. Separe Roles de Grupo e Usuários

```sql
-- ❌ Ruim: conceder permissões individualmente
GRANT SELECT ON tabela TO user1, user2, user3, ...;

-- ✅ Bom: usar roles de grupo
CREATE ROLE leitores;
GRANT SELECT ON tabela TO leitores;
GRANT leitores TO user1, user2, user3;
```

### 3. Use DEFAULT PRIVILEGES desde o Início

```sql
-- No início do projeto
ALTER DEFAULT PRIVILEGES 
FOR ROLE admin_role
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_role;

-- Agora todo CREATE TABLE automaticamente dá acesso
```

### 4. Documente Roles

```sql
COMMENT ON ROLE app_readonly IS 
    'Role para aplicação em modo leitura - usado por dashboards';
    
COMMENT ON ROLE db_owner IS 
    'Grupo com permissões de DDL - usado por migrations';
```

---

## 🔗 Navegação

⬅️ [Anterior: Column Level Security](./03-column-level-security.md) | [Próximo: Audit e Compliance →](./05-audit-compliance.md)

---

## 📝 Resumo Rápido

```sql
-- GRANT básico
GRANT SELECT, INSERT ON tabela TO role;

-- DEFAULT PRIVILEGES
ALTER DEFAULT PRIVILEGES 
FOR ROLE creator_role
GRANT SELECT ON TABLES TO user_role;

-- Hierarquia de roles
CREATE ROLE grupo;
GRANT SELECT ON tabela TO grupo;

CREATE ROLE usuario WITH LOGIN INHERIT;
GRANT grupo TO usuario;  -- usuario herda permissões

-- Auditar permissões
SELECT * FROM pg_roles WHERE rolname = 'app_user';
SELECT grantee, privilege_type 
FROM information_schema.table_privileges
WHERE table_name = 'tabela';
```
