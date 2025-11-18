# 11.3 - Column Level Security

## 📋 O que você vai aprender

- Controle de acesso em nível de coluna
- GRANT/REVOKE específico por coluna
- Views para esconder dados sensíveis
- Mascaramento de dados
- Encriptação de colunas

---

## 🎯 O que é Column Level Security?

Enquanto **RLS** controla quais **linhas** um usuário vê, **Column Level Security** controla quais **colunas** ele pode acessar.

### Exemplo Real

Em uma tabela de funcionários, diferentes roles precisam de diferentes níveis de acesso:

- **RH**: vê tudo (salário, CPF, endereço)
- **Gerentes**: vê dados profissionais (cargo, departamento) mas não financeiros
- **Colegas**: vê apenas informações públicas (nome, email corporativo)

---

## 🚀 GRANT/REVOKE por Coluna

### Exemplo Básico

```sql
-- Criar tabela
CREATE TABLE funcionarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    cpf CHAR(11),
    salario NUMERIC(10, 2),
    cargo VARCHAR(50),
    departamento VARCHAR(50),
    data_admissao DATE
);

-- Criar roles
CREATE ROLE rh_role;
CREATE ROLE gerente_role;
CREATE ROLE funcionario_role;

-- RH: acesso total
GRANT SELECT, INSERT, UPDATE ON funcionarios TO rh_role;

-- Gerentes: veem dados profissionais, não financeiros
GRANT SELECT (id, nome, email, cargo, departamento, data_admissao) 
    ON funcionarios TO gerente_role;

-- Funcionários: apenas dados públicos
GRANT SELECT (id, nome, email, cargo) 
    ON funcionarios TO funcionario_role;

-- Teste
SET ROLE gerente_role;

SELECT nome, cargo FROM funcionarios;  -- ✅ Funciona

SELECT nome, salario FROM funcionarios;  
-- ❌ ERROR: permission denied for column "salario"

RESET ROLE;
```

---

## 🔐 Estratégia com Views

Views são poderosas para criar "versões filtradas" de tabelas com colunas diferentes.

### View para Diferentes Níveis de Acesso

```sql
-- Tabela original (somente RH tem acesso)
CREATE TABLE funcionarios_full (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100),
    cpf CHAR(11),
    salario NUMERIC(10, 2),
    conta_bancaria VARCHAR(20),
    cargo VARCHAR(50),
    departamento VARCHAR(50),
    telefone_pessoal VARCHAR(15)
);

-- Permissões estritas na tabela original
REVOKE ALL ON funcionarios_full FROM PUBLIC;
GRANT ALL ON funcionarios_full TO rh_role;

-- View pública: apenas dados não-sensíveis
CREATE VIEW funcionarios_public AS
SELECT id, nome, email, cargo, departamento
FROM funcionarios_full;

GRANT SELECT ON funcionarios_public TO PUBLIC;

-- View para gerentes: + telefone
CREATE VIEW funcionarios_gerentes AS
SELECT id, nome, email, cargo, departamento, telefone_pessoal
FROM funcionarios_full;

GRANT SELECT ON funcionarios_gerentes TO gerente_role;

-- Teste
SET ROLE funcionario_role;
SELECT * FROM funcionarios_public;  -- ✅ Vê 5 colunas
SELECT * FROM funcionarios_full;    -- ❌ Permission denied

SET ROLE gerente_role;
SELECT * FROM funcionarios_gerentes;  -- ✅ Vê 6 colunas

RESET ROLE;
```

---

## 🎭 Mascaramento de Dados

Mostrar dados parcialmente (ex: CPF mascarado como `***.***.***-12`).

### Usando Views com Funções

```sql
-- Função para mascarar CPF
CREATE FUNCTION mascara_cpf(cpf CHAR(11)) RETURNS TEXT AS $$
BEGIN
    IF cpf IS NULL THEN RETURN NULL; END IF;
    RETURN '***.***.***-' || RIGHT(cpf, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- View com dados mascarados
CREATE VIEW funcionarios_masked AS
SELECT 
    id,
    nome,
    email,
    mascara_cpf(cpf) AS cpf_masked,
    '***' AS salario_hidden,  -- Completamente oculto
    cargo,
    departamento
FROM funcionarios_full;

GRANT SELECT ON funcionarios_masked TO funcionario_role;

-- Teste
SET ROLE funcionario_role;
SELECT * FROM funcionarios_masked;
/*
 id |   nome   | cpf_masked      | salario_hidden
----+----------+-----------------+----------------
  1 | João     | ***.***.***.34  | ***
*/
```

### Mascaramento Dinâmico por Role

```sql
-- View que mascara baseado no role do usuário
CREATE VIEW funcionarios_smart AS
SELECT 
    id,
    nome,
    email,
    CASE 
        WHEN pg_has_role(current_user, 'rh_role', 'MEMBER') THEN cpf
        ELSE mascara_cpf(cpf)
    END AS cpf,
    CASE
        WHEN pg_has_role(current_user, 'rh_role', 'MEMBER') THEN salario
        ELSE NULL
    END AS salario,
    cargo,
    departamento
FROM funcionarios_full;

-- RH vê tudo, outros veem mascarado
GRANT SELECT ON funcionarios_smart TO rh_role, gerente_role, funcionario_role;

-- Teste
SET ROLE rh_role;
SELECT cpf, salario FROM funcionarios_smart;
-- cpf: 12345678901, salario: 5000.00

SET ROLE funcionario_role;
SELECT cpf, salario FROM funcionarios_smart;
-- cpf: ***.***.***.01, salario: NULL
```

---

## 🔒 Encriptação de Colunas

Para dados ultra-sensíveis, encripte no banco.

### pgcrypto Extension

```sql
-- Habilitar extensão
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Tabela com coluna encriptada
CREATE TABLE cartoes (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER,
    numero_cartao BYTEA,  -- Armazenado encriptado
    cvv_encriptado BYTEA,
    data_validade DATE
);

-- Inserir com encriptação
INSERT INTO cartoes (usuario_id, numero_cartao, cvv_encriptado)
VALUES (
    1,
    pgp_sym_encrypt('1234567812345678', 'senha_secreta_app'),
    pgp_sym_encrypt('123', 'senha_secreta_app')
);

-- Consultar com decriptação (somente quem sabe a senha)
SELECT 
    id,
    usuario_id,
    pgp_sym_decrypt(numero_cartao, 'senha_secreta_app') AS numero,
    pgp_sym_decrypt(cvv_encriptado, 'senha_secreta_app') AS cvv
FROM cartoes
WHERE usuario_id = 1;
```

### View com Decriptação Controlada

```sql
-- Função para decriptar (somente admins)
CREATE FUNCTION decripta_cartao(cartao BYTEA) 
RETURNS TEXT AS $$
BEGIN
    -- Apenas role específico pode decriptar
    IF NOT pg_has_role(current_user, 'finance_admin', 'MEMBER') THEN
        RETURN '****-****-****-' || RIGHT(
            pgp_sym_decrypt(cartao, current_setting('app.crypto_key'))::TEXT, 
            4
        );
    END IF;
    
    RETURN pgp_sym_decrypt(cartao, current_setting('app.crypto_key'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- View com mascaramento automático
CREATE VIEW cartoes_view AS
SELECT 
    id,
    usuario_id,
    decripta_cartao(numero_cartao) AS numero_cartao
FROM cartoes;

GRANT SELECT ON cartoes_view TO app_user;

-- Uso
SET app.crypto_key = 'senha_secreta_app';

SET ROLE app_user;
SELECT * FROM cartoes_view;
-- Vê: ****-****-****-5678

SET ROLE finance_admin;
SELECT * FROM cartoes_view;
-- Vê: 1234567812345678
```

---

## 🎨 Padrões Avançados

### Generated Columns com Mascaramento

```sql
-- Coluna gerada automaticamente mascarada
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    cpf CHAR(11),
    cpf_masked TEXT GENERATED ALWAYS AS (
        '***.***.***-' || RIGHT(cpf, 2)
    ) STORED
);

-- View pública usa coluna mascarada
CREATE VIEW clientes_public AS
SELECT id, nome, cpf_masked AS cpf
FROM clientes;

GRANT SELECT ON clientes_public TO PUBLIC;
```

### Row Level + Column Level Security

Combine RLS e column security para controle granular.

```sql
-- Tabela multi-tenant com dados sensíveis
CREATE TABLE pacientes (
    id SERIAL PRIMARY KEY,
    clinica_id INTEGER,  -- Tenant
    nome VARCHAR(100),
    cpf CHAR(11),
    diagnostico TEXT,
    historico_medico TEXT
);

-- RLS: cada clínica vê apenas seus pacientes
ALTER TABLE pacientes ENABLE ROW LEVEL SECURITY;

CREATE POLICY clinica_isolation ON pacientes
    USING (clinica_id = current_setting('app.clinica_id')::INT);

-- Column security: recepcionistas não veem diagnósticos
CREATE ROLE medico_role;
CREATE ROLE recepcionista_role;

GRANT SELECT ON pacientes TO medico_role;  -- Vê tudo

GRANT SELECT (id, nome, cpf) ON pacientes TO recepcionista_role;  
-- Não vê diagnostico, historico_medico

-- Recepcionista X da Clínica A:
SET app.clinica_id = 1;
SET ROLE recepcionista_role;

SELECT * FROM pacientes;  
-- Vê apenas: id, nome, cpf dos pacientes da clínica 1
-- RLS + Column Security trabalhando juntos!
```

---

## ⚠️ Limitações e Armadilhas

### 1. Column GRANT e INSERT/UPDATE

```sql
-- Problema: GRANT SELECT de colunas específicas, mas INSERT precisa de todas

GRANT SELECT (id, nome) ON funcionarios TO app_role;
GRANT INSERT ON funcionarios TO app_role;

SET ROLE app_role;

INSERT INTO funcionarios (nome, salario) VALUES ('Ana', 5000);
-- ❌ ERROR: permission denied for column "salario"

-- Solução: usar default values ou trigger
ALTER TABLE funcionarios ALTER COLUMN salario SET DEFAULT 0;

-- Ou: usar função SECURITY DEFINER
CREATE FUNCTION inserir_funcionario(p_nome TEXT) RETURNS INT AS $$
    INSERT INTO funcionarios (nome, salario) 
    VALUES (p_nome, 0)  -- Salário definido depois pelo RH
    RETURNING id;
$$ LANGUAGE SQL SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION inserir_funcionario TO app_role;
```

### 2. Views Atualizáveis

```sql
-- View simples é atualizável automaticamente
CREATE VIEW func_simples AS
SELECT id, nome FROM funcionarios;

GRANT UPDATE ON func_simples TO app_role;

SET ROLE app_role;
UPDATE func_simples SET nome = 'Novo Nome' WHERE id = 1;  -- ✅ Funciona

-- View complexa NÃO é atualizável
CREATE VIEW func_complexa AS
SELECT id, nome, UPPER(cargo) AS cargo_upper
FROM funcionarios;

UPDATE func_complexa SET nome = 'X' WHERE id = 1;
-- ❌ ERROR: cannot update view "func_complexa"

-- Solução: INSTEAD OF trigger
CREATE FUNCTION func_complexa_update() RETURNS TRIGGER AS $$
BEGIN
    UPDATE funcionarios 
    SET nome = NEW.nome 
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER func_complexa_update_trigger
INSTEAD OF UPDATE ON func_complexa
FOR EACH ROW EXECUTE FUNCTION func_complexa_update();
```

---

## 📊 Auditando Permissões de Coluna

```sql
-- Ver permissões de coluna
SELECT 
    table_schema,
    table_name,
    column_name,
    privilege_type
FROM information_schema.column_privileges
WHERE grantee = 'gerente_role';

-- Ou query mais detalhada
SELECT 
    n.nspname AS schema,
    c.relname AS table,
    a.attname AS column,
    r.rolname AS role,
    CASE 
        WHEN a.attacl IS NULL THEN 'default'
        ELSE a.attacl::TEXT
    END AS privileges
FROM pg_attribute a
JOIN pg_class c ON a.attrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
CROSS JOIN pg_roles r
WHERE a.attnum > 0 
  AND NOT a.attisdropped
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND r.rolname = 'gerente_role';
```

---

## 🎯 Boas Práticas

### 1. Prefira Views para Complexidade

```sql
-- ❌ Ruim: gerenciar GRANT de 50 colunas manualmente
GRANT SELECT (col1, col2, ..., col50) ON tabela TO role;

-- ✅ Bom: criar views semânticas
CREATE VIEW tabela_dados_publicos AS SELECT col1, col2, col5 FROM tabela;
CREATE VIEW tabela_dados_sensiveis AS SELECT * FROM tabela;

GRANT SELECT ON tabela_dados_publicos TO PUBLIC;
GRANT SELECT ON tabela_dados_sensiveis TO admin_role;
```

### 2. Documente Mascaramento

```sql
COMMENT ON VIEW funcionarios_masked IS 
    'View pública: CPF e salário mascarados para proteção de dados pessoais (LGPD)';
```

### 3. Teste Permissões

```sql
-- Script de teste
DO $$
BEGIN
    SET ROLE funcionario_role;
    
    -- Deve funcionar
    PERFORM * FROM funcionarios_public;
    
    -- Deve falhar
    BEGIN
        PERFORM salario FROM funcionarios_full;
        RAISE EXCEPTION 'TESTE FALHOU: funcionario_role viu salário!';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE 'OK: Permission negada como esperado';
    END;
    
    RESET ROLE;
END $$;
```

---

## 🔗 Navegação

⬅️ [Anterior: Row Level Security](./02-row-level-security.md) | [Próximo: Policies e GRANT System →](./04-policies-grant-system.md)

---

## 📝 Resumo Rápido

```sql
-- GRANT específico de coluna
GRANT SELECT (col1, col2) ON tabela TO role;

-- View para esconder colunas
CREATE VIEW tabela_public AS 
SELECT col1, col2 FROM tabela_full;
GRANT SELECT ON tabela_public TO PUBLIC;

-- Mascaramento
CREATE FUNCTION mascara(valor TEXT) RETURNS TEXT AS $$
    RETURN '***' || RIGHT(valor, 2);
$$ LANGUAGE SQL;

-- Encriptação (pgcrypto)
INSERT INTO tabela (col_secreta) 
VALUES (pgp_sym_encrypt('dado', 'senha'));

SELECT pgp_sym_decrypt(col_secreta, 'senha') FROM tabela;
```
