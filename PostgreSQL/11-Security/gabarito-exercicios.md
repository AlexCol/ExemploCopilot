# Gabarito - Exercícios de Security

## 🎯 Soluções Completas

---

## 🟢 Nível Básico

### Exercício 1: Hierarchy de Roles

```sql
-- Criar roles de grupo
CREATE ROLE bibliotecario;
CREATE ROLE atendente;
CREATE ROLE leitor;

-- Tabelas
CREATE TABLE livros (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(200),
    autor VARCHAR(100),
    disponivel BOOLEAN DEFAULT TRUE
);

CREATE TABLE emprestimos (
    id SERIAL PRIMARY KEY,
    livro_id INTEGER REFERENCES livros(id),
    usuario VARCHAR(50),
    data_emprestimo DATE DEFAULT CURRENT_DATE
);

-- Permissões para bibliotecario (tudo)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bibliotecario;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bibliotecario;

-- Permissões para atendente (não pode deletar)
GRANT SELECT, INSERT, UPDATE ON emprestimos TO atendente;
GRANT SELECT ON livros TO atendente;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO atendente;

-- Permissões para leitor (apenas consulta)
GRANT SELECT ON livros TO leitor;

-- Criar usuários que herdam
CREATE ROLE maria WITH LOGIN PASSWORD 'senha1' INHERIT;
CREATE ROLE joao WITH LOGIN PASSWORD 'senha2' INHERIT;
CREATE ROLE ana WITH LOGIN PASSWORD 'senha3' INHERIT;

GRANT bibliotecario TO maria;
GRANT atendente TO joao;
GRANT leitor TO ana;

-- Teste
SET ROLE maria;
DELETE FROM emprestimos WHERE id = 1;  -- ✅ Funciona

SET ROLE joao;
INSERT INTO emprestimos (livro_id, usuario) VALUES (1, 'Cliente X');  -- ✅
DELETE FROM emprestimos WHERE id = 1;  -- ❌ Permission denied

SET ROLE ana;
SELECT * FROM livros;  -- ✅
INSERT INTO emprestimos (livro_id, usuario) VALUES (1, 'X');  -- ❌

RESET ROLE;
```

---

### Exercício 2: DEFAULT PRIVILEGES

```sql
-- Criar roles
CREATE ROLE admin_role;
CREATE ROLE app_readonly;
CREATE ROLE app_writer;

-- Configurar DEFAULT PRIVILEGES
ALTER DEFAULT PRIVILEGES 
FOR ROLE admin_role
IN SCHEMA public
GRANT SELECT ON TABLES TO app_readonly;

ALTER DEFAULT PRIVILEGES 
FOR ROLE admin_role
IN SCHEMA public
GRANT INSERT, UPDATE ON TABLES TO app_writer;

-- Teste: admin cria tabela
SET ROLE admin_role;
CREATE TABLE teste_default (id INT, nome TEXT);

RESET ROLE;

-- Verificar permissões automaticamente aplicadas
SET ROLE app_readonly;
SELECT * FROM teste_default;  -- ✅ Funciona automaticamente!

SET ROLE app_writer;
INSERT INTO teste_default VALUES (1, 'Teste');  -- ✅
```

---

### Exercício 3: Auditoria de Permissões

```sql
-- Query para listar roles e memberships
SELECT 
    r.rolname AS role_name,
    r.rolsuper AS is_superuser,
    r.rolcanlogin AS can_login,
    ARRAY(
        SELECT b.rolname 
        FROM pg_catalog.pg_auth_members m
        JOIN pg_catalog.pg_roles b ON (m.roleid = b.oid)
        WHERE m.member = r.oid
    ) AS member_of
FROM pg_catalog.pg_roles r
WHERE r.rolname NOT LIKE 'pg_%'
ORDER BY r.rolname;

-- Query para permissões de tabela por role
SELECT 
    grantee,
    table_schema,
    table_name,
    STRING_AGG(privilege_type, ', ') AS privileges
FROM information_schema.table_privileges
WHERE grantee NOT LIKE 'pg_%'
  AND table_schema = 'public'
GROUP BY grantee, table_schema, table_name
ORDER BY grantee, table_name;
```

---

## 🟡 Nível Intermediário - RLS

### Exercício 4: RLS Básico

```sql
-- Criar tabela
CREATE TABLE documentos (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(100),
    conteudo TEXT,
    dono VARCHAR(50) DEFAULT current_user
);

-- Habilitar RLS
ALTER TABLE documentos ENABLE ROW LEVEL SECURITY;

-- Policy para SELECT: ver apenas seus documentos
CREATE POLICY doc_select_policy ON documentos
    FOR SELECT
    USING (dono = current_user);

-- Policy para INSERT: só pode criar com seu nome
CREATE POLICY doc_insert_policy ON documentos
    FOR INSERT
    WITH CHECK (dono = current_user);

-- Criar usuários
CREATE ROLE user1 WITH LOGIN PASSWORD 'senha1';
CREATE ROLE user2 WITH LOGIN PASSWORD 'senha2';
CREATE ROLE user3 WITH LOGIN PASSWORD 'senha3';

GRANT SELECT, INSERT ON documentos TO user1, user2, user3;
GRANT USAGE ON SEQUENCE documentos_id_seq TO user1, user2, user3;

-- Teste
SET ROLE user1;
INSERT INTO documentos (titulo, conteudo) VALUES ('Doc 1', 'Conteúdo 1');
INSERT INTO documentos (titulo, conteudo) VALUES ('Doc 2', 'Conteúdo 2');

SET ROLE user2;
INSERT INTO documentos (titulo, conteudo) VALUES ('Doc 3', 'Conteúdo 3');

-- user1 vê apenas docs 1 e 2
SET ROLE user1;
SELECT * FROM documentos;
/*
 id | titulo | dono
----+--------+-------
  1 | Doc 1  | user1
  2 | Doc 2  | user1
*/

-- user2 vê apenas doc 3
SET ROLE user2;
SELECT * FROM documentos;
/*
 id | titulo | dono
----+--------+-------
  3 | Doc 3  | user2
*/

RESET ROLE;
```

---

### Exercício 5: Multi-tenancy com RLS

```sql
-- Criar tabela
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL,
    descricao TEXT,
    valor NUMERIC(10, 2)
);

-- Habilitar RLS
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;

-- Policy: isolamento por tenant
CREATE POLICY tenant_isolation_policy ON pedidos
    USING (tenant_id = current_setting('app.current_tenant')::INTEGER)
    WITH CHECK (tenant_id = current_setting('app.current_tenant')::INTEGER);

-- Função helper
CREATE FUNCTION set_tenant(p_tenant_id INTEGER) RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_tenant', p_tenant_id::TEXT, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Criar usuário
CREATE ROLE tenant_user WITH LOGIN PASSWORD 'senha';
GRANT SELECT, INSERT, UPDATE, DELETE ON pedidos TO tenant_user;
GRANT USAGE ON SEQUENCE pedidos_id_seq TO tenant_user;
GRANT EXECUTE ON FUNCTION set_tenant(INTEGER) TO tenant_user;

-- Teste
SET ROLE tenant_user;

-- Definir tenant 1
SELECT set_tenant(1);
INSERT INTO pedidos (tenant_id, descricao, valor) VALUES (1, 'Pedido A', 100.00);
SELECT * FROM pedidos;  -- Vê pedido A

-- Tentar inserir para outro tenant
INSERT INTO pedidos (tenant_id, descricao, valor) VALUES (2, 'Pedido B', 200.00);
-- ❌ ERROR: new row violates row-level security policy

-- Mudar para tenant 2
SELECT set_tenant(2);
INSERT INTO pedidos (tenant_id, descricao, valor) VALUES (2, 'Pedido C', 300.00);
SELECT * FROM pedidos;  -- Vê apenas pedido C (não vê pedido A!)

RESET ROLE;
```

---

### Exercício 6: RLS com Hierarquia

```sql
-- Tabela
CREATE TABLE tarefas (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(100),
    responsavel VARCHAR(50),
    gerente_id INTEGER  -- Referência ao ID do gerente
);

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE
);

ALTER TABLE tarefas ENABLE ROW LEVEL SECURITY;

-- Policy 1: Ver suas próprias tarefas
CREATE POLICY tarefas_self_policy ON tarefas
    FOR ALL
    USING (responsavel = current_user);

-- Policy 2: Gerentes veem tarefas de sua equipe
CREATE POLICY tarefas_gerente_policy ON tarefas
    FOR SELECT
    USING (
        gerente_id = (SELECT id FROM usuarios WHERE username = current_user)
    );

-- Policy 3: RH vê tudo
CREATE ROLE rh_role;
CREATE POLICY tarefas_rh_policy ON tarefas
    FOR ALL
    TO rh_role
    USING (TRUE);  -- Sem restrições

-- Teste
INSERT INTO usuarios (id, username) VALUES (1, 'gerente1'), (2, 'func1'), (3, 'func2');

CREATE ROLE gerente1 WITH LOGIN PASSWORD 'senha';
CREATE ROLE func1 WITH LOGIN PASSWORD 'senha';
CREATE ROLE func2 WITH LOGIN PASSWORD 'senha';
CREATE ROLE rh_user WITH LOGIN PASSWORD 'senha';

GRANT SELECT, INSERT ON tarefas TO gerente1, func1, func2;
GRANT ALL ON tarefas TO rh_user;
GRANT rh_role TO rh_user;

INSERT INTO tarefas (titulo, responsavel, gerente_id) VALUES
('Tarefa 1', 'func1', 1),
('Tarefa 2', 'func2', 1),
('Tarefa 3', 'func1', 2);

SET ROLE func1;
SELECT * FROM tarefas;  -- Vê apenas Tarefa 1 e 3 (suas)

SET ROLE gerente1;
SELECT * FROM tarefas;  -- Vê Tarefa 1 e 2 (sua equipe)

SET ROLE rh_user;
SELECT * FROM tarefas;  -- Vê TUDO

RESET ROLE;
```

---

## 🟠 Column Security

### Exercício 7: GRANT por Coluna

```sql
CREATE TABLE funcionarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    cargo VARCHAR(50),
    salario NUMERIC(10, 2),
    cpf CHAR(11)
);

CREATE ROLE publico;
CREATE ROLE rh;
CREATE ROLE gerente;

-- Publico: apenas nome e cargo
GRANT SELECT (id, nome, cargo) ON funcionarios TO publico;

-- RH: tudo
GRANT SELECT, INSERT, UPDATE ON funcionarios TO rh;

-- Gerente: tudo exceto CPF
GRANT SELECT (id, nome, cargo, salario) ON funcionarios TO gerente;

-- Teste
CREATE ROLE user_publico WITH LOGIN PASSWORD 'senha';
CREATE ROLE user_rh WITH LOGIN PASSWORD 'senha';
CREATE ROLE user_gerente WITH LOGIN PASSWORD 'senha';

GRANT publico TO user_publico;
GRANT rh TO user_rh;
GRANT gerente TO user_gerente;

SET ROLE user_publico;
SELECT nome, cargo FROM funcionarios;  -- ✅
SELECT salario FROM funcionarios;  -- ❌ Permission denied

SET ROLE user_gerente;
SELECT nome, salario FROM funcionarios;  -- ✅
SELECT cpf FROM funcionarios;  -- ❌ Permission denied

SET ROLE user_rh;
SELECT * FROM funcionarios;  -- ✅ Tudo

RESET ROLE;
```

---

### Exercício 8: Views com Mascaramento

```sql
-- Função de mascaramento
CREATE FUNCTION mascara_cpf(cpf CHAR(11)) RETURNS TEXT AS $$
BEGIN
    RETURN '***.***.**-' || RIGHT(cpf, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION mascara_telefone(tel VARCHAR(15)) RETURNS TEXT AS $$
BEGIN
    RETURN '(**) ****-' || RIGHT(tel, 4);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION faixa_salarial(salario NUMERIC) RETURNS TEXT AS $$
BEGIN
    RETURN CASE
        WHEN salario < 3000 THEN '<3000'
        WHEN salario BETWEEN 3000 AND 6000 THEN '3000-6000'
        ELSE '>6000'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- View mascarada
CREATE VIEW funcionarios_masked AS
SELECT 
    id,
    nome,
    cargo,
    mascara_cpf(cpf) AS cpf_masked,
    faixa_salarial(salario) AS faixa_salarial,
    mascara_telefone(telefone) AS telefone_masked
FROM funcionarios;

GRANT SELECT ON funcionarios_masked TO PUBLIC;

-- Resultado
SELECT * FROM funcionarios_masked;
/*
 id | nome | cargo      | cpf_masked       | faixa_salarial | telefone_masked
----+------+------------+------------------+----------------+-----------------
  1 | João | Analista   | ***.***.**-34    | 3000-6000      | (**) ****-5678
*/
```

---

### Exercício 9: Mascaramento Dinâmico por Role

```sql
CREATE ROLE vendedor_role;
CREATE ROLE financeiro_role;
CREATE ROLE marketing_role;

CREATE VIEW clientes_view AS
SELECT 
    id,
    nome,
    email,
    -- CPF: completo para financeiro, mascarado para marketing, NULL para vendedor
    CASE 
        WHEN pg_has_role(current_user, 'financeiro_role', 'MEMBER') THEN cpf
        WHEN pg_has_role(current_user, 'marketing_role', 'MEMBER') THEN mascara_cpf(cpf)
        ELSE NULL
    END AS cpf,
    -- Telefone: completo para vendedor, NULL para outros
    CASE 
        WHEN pg_has_role(current_user, 'vendedor_role', 'MEMBER') THEN telefone
        ELSE NULL
    END AS telefone
FROM clientes;

GRANT SELECT ON clientes_view TO vendedor_role, financeiro_role, marketing_role;

-- Teste
CREATE ROLE user_vendedor WITH LOGIN PASSWORD 'senha';
CREATE ROLE user_financeiro WITH LOGIN PASSWORD 'senha';
CREATE ROLE user_marketing WITH LOGIN PASSWORD 'senha';

GRANT vendedor_role TO user_vendedor;
GRANT financeiro_role TO user_financeiro;
GRANT marketing_role TO user_marketing;

SET ROLE user_vendedor;
SELECT * FROM clientes_view;
-- Vê: nome, email, telefone (CPF=NULL)

SET ROLE user_financeiro;
SELECT * FROM clientes_view;
-- Vê: nome, email, cpf completo (telefone=NULL)

SET ROLE user_marketing;
SELECT * FROM clientes_view;
-- Vê: nome, email, cpf mascarado (telefone=NULL)
```

---

## 🔴 Nível Avançado - Auditoria

### Exercício 10: Audit Table Simples

```sql
-- Tabela principal
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    preco NUMERIC(10, 2),
    estoque INTEGER
);

-- Tabela de auditoria
CREATE TABLE produtos_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    operacao CHAR(1),  -- I, U, D
    usuario VARCHAR(50),
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    -- Valores
    id INTEGER,
    nome_old VARCHAR(100),
    nome_new VARCHAR(100),
    preco_old NUMERIC(10, 2),
    preco_new NUMERIC(10, 2),
    estoque_old INTEGER,
    estoque_new INTEGER
);

-- Trigger para INSERT
CREATE FUNCTION audit_produtos_insert() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO produtos_audit (operacao, usuario, id, nome_new, preco_new, estoque_new)
    VALUES ('I', current_user, NEW.id, NEW.nome, NEW.preco, NEW.estoque);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER produtos_insert_audit
AFTER INSERT ON produtos
FOR EACH ROW EXECUTE FUNCTION audit_produtos_insert();

-- Trigger para UPDATE
CREATE FUNCTION audit_produtos_update() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO produtos_audit (
        operacao, usuario, id,
        nome_old, nome_new,
        preco_old, preco_new,
        estoque_old, estoque_new
    ) VALUES (
        'U', current_user, NEW.id,
        OLD.nome, NEW.nome,
        OLD.preco, NEW.preco,
        OLD.estoque, NEW.estoque
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER produtos_update_audit
AFTER UPDATE ON produtos
FOR EACH ROW EXECUTE FUNCTION audit_produtos_update();

-- Trigger para DELETE
CREATE FUNCTION audit_produtos_delete() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO produtos_audit (operacao, usuario, id, nome_old, preco_old, estoque_old)
    VALUES ('D', current_user, OLD.id, OLD.nome, OLD.preco, OLD.estoque);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER produtos_delete_audit
AFTER DELETE ON produtos
FOR EACH ROW EXECUTE FUNCTION audit_produtos_delete();

-- Teste
INSERT INTO produtos (nome, preco, estoque) VALUES ('Produto A', 100.00, 50);
UPDATE produtos SET preco = 120.00 WHERE id = 1;
DELETE FROM produtos WHERE id = 1;

SELECT * FROM produtos_audit;
/*
 audit_id | operacao | usuario | data_hora           | nome_old   | nome_new   | preco_old | preco_new
----------+----------+---------+---------------------+------------+------------+-----------+-----------
        1 | I        | app     | 2024-01-15 10:00:00 | NULL       | Produto A  | NULL      | 100.00
        2 | U        | app     | 2024-01-15 10:01:00 | Produto A  | Produto A  | 100.00    | 120.00
        3 | D        | app     | 2024-01-15 10:02:00 | Produto A  | NULL       | 120.00    | NULL
*/
```

---

### Exercício 11: Audit Table Genérica (JSON)

```sql
-- Tabela genérica
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    tabela VARCHAR(50) NOT NULL,
    operacao CHAR(1) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    aplicacao VARCHAR(100),
    dados_antigos JSONB,
    dados_novos JSONB
);

CREATE INDEX idx_audit_log_tabela_data ON audit_log(tabela, data_hora DESC);

-- Função genérica de auditoria
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_old_data = row_to_json(OLD)::JSONB;
        v_new_data = NULL;
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old_data = row_to_json(OLD)::JSONB;
        v_new_data = row_to_json(NEW)::JSONB;
    ELSIF (TG_OP = 'INSERT') THEN
        v_old_data = NULL;
        v_new_data = row_to_json(NEW)::JSONB;
    END IF;
    
    INSERT INTO audit_log (
        tabela, operacao, usuario, ip_address, aplicacao, 
        dados_antigos, dados_novos
    ) VALUES (
        TG_TABLE_NAME,
        LEFT(TG_OP, 1),
        current_user,
        inet_client_addr(),
        current_setting('application_name', TRUE),
        v_old_data,
        v_new_data
    );
    
    IF (TG_OP = 'DELETE') THEN RETURN OLD;
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a múltiplas tabelas
CREATE TRIGGER produtos_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON produtos
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER clientes_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Teste
UPDATE produtos SET preco = 150.00 WHERE id = 1;

SELECT 
    tabela,
    operacao,
    usuario,
    dados_antigos->>'preco' AS preco_antigo,
    dados_novos->>'preco' AS preco_novo
FROM audit_log
WHERE tabela = 'produtos'
ORDER BY id DESC
LIMIT 1;
```

---

### Exercício 12: Auditoria de Acesso (LGPD)

```sql
-- Tabela de acesso
CREATE TABLE acesso_dados_pessoais (
    id BIGSERIAL PRIMARY KEY,
    usuario_consultado_id INTEGER,
    usuario_consultor VARCHAR(50),
    finalidade TEXT,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    campos_acessados TEXT[]
);

-- Função para registrar acesso
CREATE FUNCTION log_acesso_dados_pessoais(
    p_usuario_id INT,
    p_finalidade TEXT,
    p_campos TEXT[] DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO acesso_dados_pessoais (
        usuario_consultado_id,
        usuario_consultor,
        finalidade,
        ip_address,
        campos_acessados
    ) VALUES (
        p_usuario_id,
        current_user,
        p_finalidade,
        inet_client_addr(),
        p_campos
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- View que registra acesso automaticamente
CREATE VIEW clientes_lgpd AS
SELECT 
    c.id,
    c.nome,
    c.email,
    c.cpf,
    log_acesso_dados_pessoais(c.id, 'Consulta via view', 
        ARRAY['nome', 'email', 'cpf']) AS _logged
FROM clientes c;

-- Teste
SELECT nome, cpf FROM clientes_lgpd WHERE id = 1;

-- Verificar log
SELECT 
    usuario_consultado_id,
    usuario_consultor,
    finalidade,
    data_hora,
    campos_acessados
FROM acesso_dados_pessoais
ORDER BY id DESC;
```

---

## 🔴 Compliance

### Exercício 13: Encriptação com pgcrypto

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Tabela
CREATE TABLE cartoes_credito (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER,
    numero_encriptado BYTEA NOT NULL,
    cvv_encriptado BYTEA NOT NULL,
    data_validade DATE
);

-- Audit de acesso
CREATE TABLE audit_acesso_cartao (
    id BIGSERIAL PRIMARY KEY,
    cartao_id INTEGER,
    usuario VARCHAR(50),
    resultado VARCHAR(20),  -- 'sucesso' ou 'negado'
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET
);

-- Função para acessar cartão (SEMPRE audita)
CREATE FUNCTION get_card_number(p_card_id INT, p_senha TEXT)
RETURNS TABLE (numero_cartao TEXT, cvv TEXT) AS $$
DECLARE
    v_resultado VARCHAR(20);
BEGIN
    BEGIN
        RETURN QUERY
        SELECT 
            pgp_sym_decrypt(numero_encriptado, p_senha)::TEXT,
            pgp_sym_decrypt(cvv_encriptado, p_senha)::TEXT
        FROM cartoes_credito
        WHERE id = p_card_id;
        
        v_resultado := 'sucesso';
    EXCEPTION WHEN OTHERS THEN
        v_resultado := 'negado';
    END;
    
    -- SEMPRE auditar
    INSERT INTO audit_acesso_cartao (cartao_id, usuario, resultado, ip_address)
    VALUES (p_card_id, current_user, v_resultado, inet_client_addr());
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Restringir acesso
CREATE ROLE payment_admin;
REVOKE ALL ON FUNCTION get_card_number FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_card_number TO payment_admin;

-- Teste
INSERT INTO cartoes_credito (usuario_id, numero_encriptado, cvv_encriptado)
VALUES (
    1,
    pgp_sym_encrypt('4111111111111111', 'chave_secreta'),
    pgp_sym_encrypt('123', 'chave_secreta')
);

CREATE ROLE admin WITH LOGIN PASSWORD 'senha';
GRANT payment_admin TO admin;

SET ROLE admin;
SELECT * FROM get_card_number(1, 'chave_secreta');

-- Ver audit
SELECT * FROM audit_acesso_cartao;
```

---

### Exercício 14: Direito ao Esquecimento (LGPD)

```sql
-- Função de anonimização
CREATE FUNCTION anonimizar_usuario(p_usuario_id INT) 
RETURNS VOID AS $$
DECLARE
    v_old_data JSONB;
BEGIN
    -- Capturar dados antes de anonimizar
    SELECT row_to_json(u)::JSONB INTO v_old_data
    FROM clientes u
    WHERE id = p_usuario_id;
    
    -- Anonimizar
    UPDATE clientes SET
        nome = 'Usuário Removido',
        email = 'removido_' || p_usuario_id || '@anonimizado.com',
        cpf = NULL,
        telefone = NULL,
        endereco = NULL,
        data_nascimento = NULL
    WHERE id = p_usuario_id;
    
    -- Registrar anonimização
    INSERT INTO audit_log (
        tabela, operacao, usuario, dados_antigos, dados_novos
    ) VALUES (
        'clientes',
        'A',  -- Anonimização
        current_user,
        v_old_data,
        jsonb_build_object(
            'id', p_usuario_id,
            'acao', 'Anonimização LGPD - Direito ao Esquecimento'
        )
    );
    
    RAISE NOTICE 'Usuário % anonimizado com sucesso', p_usuario_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Teste
SELECT anonimizar_usuario(1);

SELECT nome, email, cpf FROM clientes WHERE id = 1;
/*
 nome             | email                         | cpf
------------------+-------------------------------+------
 Usuário Removido | removido_1@anonimizado.com    | NULL
*/
```

---

### Exercício 15: Event Trigger para DDL Audit (SOX)

```sql
-- Tabela de audit DDL
CREATE TABLE ddl_audit (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50),
    comando VARCHAR(50),
    objeto TEXT,
    query TEXT,
    data_hora TIMESTAMPTZ DEFAULT NOW()
);

-- Função de audit DDL
CREATE OR REPLACE FUNCTION audit_ddl_func()
RETURNS event_trigger AS $$
DECLARE
    obj RECORD;
BEGIN
    FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        INSERT INTO ddl_audit (usuario, comando, objeto, query)
        VALUES (
            current_user,
            obj.command_tag,
            obj.object_identity,
            current_query()
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Event trigger
CREATE EVENT TRIGGER audit_ddl_trigger
ON ddl_command_end
EXECUTE FUNCTION audit_ddl_func();

-- Proteger audit table de modificações
CREATE FUNCTION protect_ddl_audit() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Registros de auditoria não podem ser alterados (SOX compliance)';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER protect_ddl_audit_trigger
BEFORE UPDATE OR DELETE ON ddl_audit
FOR EACH ROW EXECUTE FUNCTION protect_ddl_audit();

-- Teste
CREATE TABLE teste_sox (id INT);
ALTER TABLE teste_sox ADD COLUMN nome TEXT;
DROP TABLE teste_sox;

SELECT * FROM ddl_audit ORDER BY id DESC;

-- Tentar modificar audit
DELETE FROM ddl_audit WHERE id = 1;
-- ERROR: Registros de auditoria não podem ser alterados
```

---

## 🟣 Nível Expert

### Exercício 16: Sistema Multi-tenant Completo

```sql
-- Criar schemas por tenant
CREATE SCHEMA tenant_a;
CREATE SCHEMA tenant_b;
CREATE SCHEMA tenant_c;

-- Função para provisionar novo tenant
CREATE FUNCTION provision_tenant(p_tenant_schema TEXT)
RETURNS VOID AS $$
BEGIN
    -- Criar schema
    EXECUTE 'CREATE SCHEMA IF NOT EXISTS ' || p_tenant_schema;
    
    -- Criar tabelas
    EXECUTE 'CREATE TABLE ' || p_tenant_schema || '.users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50),
        email VARCHAR(100)
    )';
    
    EXECUTE 'CREATE TABLE ' || p_tenant_schema || '.orders (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES ' || p_tenant_schema || '.users(id),
        total NUMERIC(10, 2)
    )';
    
    EXECUTE 'CREATE TABLE ' || p_tenant_schema || '.products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100),
        price NUMERIC(10, 2)
    )';
    
    -- Criar roles
    EXECUTE 'CREATE ROLE ' || p_tenant_schema || '_admin';
    EXECUTE 'CREATE ROLE ' || p_tenant_schema || '_user';
    EXECUTE 'CREATE ROLE ' || p_tenant_schema || '_readonly';
    
    -- DEFAULT PRIVILEGES
    EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA ' || p_tenant_schema || 
            ' GRANT ALL ON TABLES TO ' || p_tenant_schema || '_admin';
    EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA ' || p_tenant_schema || 
            ' GRANT SELECT, INSERT, UPDATE ON TABLES TO ' || p_tenant_schema || '_user';
    EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA ' || p_tenant_schema || 
            ' GRANT SELECT ON TABLES TO ' || p_tenant_schema || '_readonly';
    
    -- Permissões
    EXECUTE 'GRANT USAGE ON SCHEMA ' || p_tenant_schema || ' TO ' || 
            p_tenant_schema || '_admin, ' || 
            p_tenant_schema || '_user, ' || 
            p_tenant_schema || '_readonly';
            
    RAISE NOTICE 'Tenant % provisionado com sucesso', p_tenant_schema;
END;
$$ LANGUAGE plpgsql;

-- Provisionar tenants
SELECT provision_tenant('tenant_a');
SELECT provision_tenant('tenant_b');
SELECT provision_tenant('tenant_c');

-- RLS para isolamento (caso tabelas compartilhadas)
-- (Já está isolado por schema, mas pode combinar ambos para extra segurança)
```

---

## 📝 Resumo Final

Este gabarito cobre:
- ✅ Hierarquia de roles com INHERIT
- ✅ DEFAULT PRIVILEGES
- ✅ RLS básico e multi-tenancy
- ✅ GRANT por coluna
- ✅ Views com mascaramento
- ✅ Encriptação com pgcrypto
- ✅ Audit tables (simples e genérica)
- ✅ Compliance LGPD/GDPR
- ✅ Event triggers para DDL
- ✅ Sistema multi-tenant completo

**Próximos passos:**
1. Implementar projeto final (Sistema Bancário)
2. Explorar outros tópicos: Índices, Particionamento, Query Optimization
3. Estudar pgAudit em detalhes

⬅️ [Voltar aos Exercícios](./exercicios.md) | [Voltar ao README](./README.md)
