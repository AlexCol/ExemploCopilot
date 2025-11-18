# 11.1 - Roles vs Users no PostgreSQL

## 📋 O que você vai aprender

- Diferença entre ROLE e USER
- Atributos de roles (LOGIN, SUPERUSER, etc)
- Role membership e herança
- Role PUBLIC
- Boas práticas de gerenciamento

---

## 🎯 Conceitos Fundamentais

### ROLE vs USER: Qual a diferença?

No PostgreSQL moderno, **não há diferença técnica** entre ROLE e USER!

```sql
-- Estas duas linhas são IDÊNTICAS:
CREATE ROLE meu_usuario WITH LOGIN PASSWORD 'senha';
CREATE USER meu_usuario WITH PASSWORD 'senha';

-- USER é apenas um alias para ROLE WITH LOGIN
```

**História**: Antigamente USER e GROUP eram separados. No PostgreSQL 8.1+ foram unificados em ROLE.

---

## 👤 Anatomia de um Role

```sql
CREATE ROLE nome_do_role WITH
    LOGIN                    -- Pode fazer login
    PASSWORD 'senha_segura'  -- Senha para autenticação
    SUPERUSER               -- Acesso total (use com cuidado!)
    CREATEDB                -- Pode criar databases
    CREATEROLE              -- Pode criar outros roles
    INHERIT                 -- Herda privilégios de roles membros
    REPLICATION             -- Pode iniciar replicação
    CONNECTION LIMIT 10     -- Máximo de conexões simultâneas
    VALID UNTIL '2026-01-01'; -- Expira em determinada data
```

---

## 🔑 Atributos de Roles

### LOGIN

```sql
-- Com LOGIN (pode conectar ao database)
CREATE ROLE app_user WITH LOGIN PASSWORD 'senha123';

-- Sem LOGIN (usado como "grupo" para organizar permissões)
CREATE ROLE readonly_group;

-- Conectar ao database
psql -U app_user -d meu_database  -- Funciona!
psql -U readonly_group -d meu_database  -- ERRO! Não tem LOGIN
```

### SUPERUSER

```sql
-- Criar superuser (acesso total, bypassa todas as verificações)
CREATE ROLE admin_user WITH SUPERUSER LOGIN PASSWORD 'admin123';

-- ⚠️ CUIDADO: Superuser pode:
-- - Deletar qualquer dado
-- - Desligar o servidor
-- - Ler/modificar TODOS os dados
-- - Bypassar Row Level Security
-- - Criar/dropar databases

-- Verificar se role é superuser
SELECT rolname, rolsuper 
FROM pg_roles 
WHERE rolname = 'admin_user';
```

**Boas Práticas**:
- ✅ Use superuser apenas para administração
- ✅ Aplicações nunca devem usar superuser
- ✅ Desenvolvedores não precisam de superuser

### CREATEDB

```sql
-- Pode criar databases
CREATE ROLE db_creator WITH CREATEDB LOGIN PASSWORD 'senha';

-- Como db_creator:
CREATE DATABASE novo_database;  -- Funciona!
```

### CREATEROLE

```sql
-- Pode criar outros roles
CREATE ROLE role_manager WITH CREATEROLE LOGIN PASSWORD 'senha';

-- Como role_manager:
CREATE ROLE novo_role;  -- Funciona!

-- ⚠️ CUIDADO: 
-- Um role com CREATEROLE pode criar SUPERUSER (privilege escalation)!
-- A partir do PostgreSQL 16, isso foi modificado para ser mais seguro
```

### INHERIT

```sql
-- Com INHERIT (padrão)
CREATE ROLE developer WITH INHERIT LOGIN PASSWORD 'dev123';

-- Sem INHERIT
CREATE ROLE restricted_developer WITH NOINHERIT LOGIN PASSWORD 'dev456';

-- Exemplo de herança:
CREATE ROLE readwrite_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO readwrite_role;

GRANT readwrite_role TO developer;  -- developer herda automaticamente
GRANT readwrite_role TO restricted_developer;  -- NÃO herda automaticamente

-- restricted_developer precisa fazer:
SET ROLE readwrite_role;  -- Ativa explicitamente
```

### CONNECTION LIMIT

```sql
-- Limitar conexões simultâneas
CREATE ROLE limited_user WITH LOGIN PASSWORD 'senha' CONNECTION LIMIT 5;

-- Sem limite (padrão: -1)
CREATE ROLE unlimited_user WITH LOGIN PASSWORD 'senha' CONNECTION LIMIT -1;

-- Ver conexões atuais
SELECT COUNT(*) FROM pg_stat_activity WHERE usename = 'limited_user';
```

### VALID UNTIL

```sql
-- Role temporário
CREATE ROLE temp_user 
    WITH LOGIN PASSWORD 'temp123' 
    VALID UNTIL '2025-12-31 23:59:59';

-- Após 31/12/2025, não poderá mais fazer login

-- Remover expiração
ALTER ROLE temp_user VALID UNTIL 'infinity';
```

---

## 👥 Role Membership (Grupos)

Roles podem ser membros de outros roles, criando hierarquia de permissões.

### Conceito de "Grupos"

```sql
-- Criar "grupos" (roles sem LOGIN)
CREATE ROLE readonly_role;
CREATE ROLE readwrite_role;
CREATE ROLE admin_role;

-- Configurar permissões nos grupos
GRANT USAGE ON SCHEMA public TO readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_role;

GRANT readonly_role TO readwrite_role;  -- readwrite herda readonly
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO readwrite_role;

GRANT readwrite_role TO admin_role;  -- admin herda readwrite
GRANT ALL ON ALL TABLES IN SCHEMA public TO admin_role;

-- Criar usuários e adicionar aos grupos
CREATE ROLE user_leitor WITH LOGIN PASSWORD 'senha1';
CREATE ROLE user_escritor WITH LOGIN PASSWORD 'senha2';
CREATE ROLE user_admin WITH LOGIN PASSWORD 'senha3';

GRANT readonly_role TO user_leitor;
GRANT readwrite_role TO user_escritor;
GRANT admin_role TO user_admin;
```

**Hierarquia criada:**
```
admin_role
  └─ readwrite_role
       └─ readonly_role

user_admin → admin_role (tem tudo)
user_escritor → readwrite_role (read + write)
user_leitor → readonly_role (apenas read)
```

### WITH ADMIN OPTION

```sql
-- Conceder role com capacidade de conceder a outros
GRANT readwrite_role TO user_manager WITH ADMIN OPTION;

-- Agora user_manager pode fazer:
GRANT readwrite_role TO outro_usuario;
```

### REVOKE Membership

```sql
-- Remover usuário do grupo
REVOKE readwrite_role FROM user_escritor;

-- Remover capacidade de conceder
REVOKE ADMIN OPTION FOR readwrite_role FROM user_manager;
```

---

## 🌐 Role PUBLIC

`PUBLIC` é um role especial que representa **todos os roles**.

```sql
-- Por padrão, PUBLIC tem algumas permissões
SELECT has_schema_privilege('PUBLIC', 'public', 'USAGE');  -- true
SELECT has_schema_privilege('PUBLIC', 'public', 'CREATE');  -- true (!!!)

-- ⚠️ PROBLEMA DE SEGURANÇA:
-- Qualquer usuário pode criar objetos no schema public!

-- ✅ BOA PRÁTICA: Revogar permissões de PUBLIC
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Agora conceda explicitamente a quem precisa
GRANT USAGE ON SCHEMA public TO app_user;
```

---

## 🔍 Consultando Roles

### Ver todos os roles

```sql
-- Método 1: pg_roles (view)
SELECT 
    rolname,
    rolsuper,
    rolinherit,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin,
    rolconnlimit,
    rolvaliduntil
FROM pg_roles
ORDER BY rolname;

-- Método 2: psql
\du
\du+  -- Com descrições
```

### Ver membros de um role

```sql
-- Quem é membro de 'readwrite_role'?
SELECT 
    r.rolname AS member,
    m.rolname AS member_of
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.member
JOIN pg_roles m ON m.oid = am.roleid
WHERE m.rolname = 'readwrite_role';
```

### Ver roles de um usuário

```sql
-- Quais roles 'user_escritor' possui?
SELECT 
    m.rolname AS role_name
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.member
JOIN pg_roles m ON m.oid = am.roleid
WHERE r.rolname = 'user_escritor';
```

---

## ⚙️ Modificando Roles

```sql
-- Alterar senha
ALTER ROLE app_user WITH PASSWORD 'nova_senha_segura';

-- Adicionar atributo
ALTER ROLE app_user WITH CREATEDB;

-- Remover atributo
ALTER ROLE app_user WITH NOCREATEDB;

-- Alterar nome
ALTER ROLE app_user RENAME TO application_user;

-- Alterar dono de objetos
REASSIGN OWNED BY old_user TO new_user;

-- Excluir role
DROP ROLE IF EXISTS app_user;

-- Excluir role e seus objetos
DROP OWNED BY app_user;  -- Primeiro remove objetos
DROP ROLE app_user;       -- Depois remove role
```

---

## 🏢 Padrão de Organização

### Estrutura Recomendada

```sql
-- 1. Criar roles de "nível de acesso" (sem LOGIN)
CREATE ROLE nivel_leitura;
CREATE ROLE nivel_escrita;
CREATE ROLE nivel_admin;

-- 2. Configurar permissões nos níveis
GRANT USAGE ON SCHEMA public TO nivel_leitura;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO nivel_leitura;

GRANT nivel_leitura TO nivel_escrita;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO nivel_escrita;

GRANT nivel_escrita TO nivel_admin;
GRANT ALL ON SCHEMA public TO nivel_admin;

-- 3. Criar roles de "função" (sem LOGIN)
CREATE ROLE vendedor;
CREATE ROLE gerente;
CREATE ROLE administrador;

GRANT nivel_escrita TO vendedor;
GRANT nivel_escrita TO gerente;
GRANT nivel_admin TO administrador;

-- 4. Criar usuários reais (com LOGIN)
CREATE ROLE joao WITH LOGIN PASSWORD 'senha_joao';
CREATE ROLE maria WITH LOGIN PASSWORD 'senha_maria';
CREATE ROLE pedro WITH LOGIN PASSWORD 'senha_pedro';

-- 5. Atribuir funções aos usuários
GRANT vendedor TO joao;
GRANT gerente TO maria;
GRANT administrador TO pedro;
```

**Vantagens**:
- ✅ Fácil adicionar novos usuários (só atribuir função)
- ✅ Fácil mudar permissões de uma função inteira
- ✅ Clara separação de responsabilidades
- ✅ Auditável

---

## 🛡️ Boas Práticas

### 1. Use roles como grupos

```sql
-- ❌ Ruim: Conceder permissões diretamente
GRANT SELECT ON tabela TO usuario1;
GRANT SELECT ON tabela TO usuario2;
GRANT SELECT ON tabela TO usuario3;

-- ✅ Bom: Usar role como grupo
CREATE ROLE grupo_leitura;
GRANT SELECT ON tabela TO grupo_leitura;
GRANT grupo_leitura TO usuario1, usuario2, usuario3;
```

### 2. Mínimo privilégio necessário

```sql
-- ❌ Ruim: Dar SUPERUSER para aplicação
CREATE ROLE app WITH SUPERUSER LOGIN;

-- ✅ Bom: Apenas as permissões necessárias
CREATE ROLE app WITH LOGIN;
GRANT USAGE ON SCHEMA public TO app;
GRANT SELECT, INSERT, UPDATE, DELETE ON specific_tables TO app;
```

### 3. Senhas fortes e rotação

```sql
-- ✅ Senha forte
CREATE ROLE app WITH LOGIN PASSWORD 'aB3$xK9#mP2@vL7!qW5';

-- ✅ Expiração regular
ALTER ROLE app VALID UNTIL '2026-01-01';

-- ✅ Usar autenticação externa (LDAP, SAML) quando possível
```

### 4. Limitar conexões

```sql
-- Aplicação com pool de conexões
CREATE ROLE app WITH LOGIN PASSWORD 'senha' CONNECTION LIMIT 20;

-- Usuários individuais
CREATE ROLE joao WITH LOGIN PASSWORD 'senha' CONNECTION LIMIT 5;
```

### 5. Documentar roles

```sql
-- Usar COMMENT para documentar
COMMENT ON ROLE readonly_role IS 'Grupo com permissão apenas de leitura em todas as tabelas';
COMMENT ON ROLE app_user IS 'Usuário usado pela aplicação web em produção';
```

---

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Próximo: Row Level Security →](./02-row-level-security.md)

---

## 📝 Resumo Rápido

```sql
-- Criar role/user
CREATE ROLE nome WITH LOGIN PASSWORD 'senha';
CREATE USER nome WITH PASSWORD 'senha';  -- Idêntico ao acima

-- Atributos
ALTER ROLE nome WITH SUPERUSER CREATEDB CREATEROLE;

-- Grupos
GRANT role_grupo TO role_usuario;
REVOKE role_grupo FROM role_usuario;

-- Consultar
\du
SELECT * FROM pg_roles;

-- Excluir
DROP ROLE nome;
```
