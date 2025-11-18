# 11.2 - Row Level Security (RLS)

## 📋 O que você vai aprender

- O que é Row Level Security
- Quando e por que usar RLS
- Criando e gerenciando policies
- USING vs WITH CHECK
- Implementações práticas (multi-tenancy, hierarquias)
- Performance considerations

---

## 🎯 O que é Row Level Security?

**Row Level Security (RLS)** permite controlar quais **linhas** de uma tabela um usuário pode ver ou modificar, complementando permissões tradicionais que operam no nível de tabela.

### Analogia

- **Permissões tradicionais**: "Você pode entrar nesta sala" (tabela inteira)
- **RLS**: "Você pode entrar nesta sala, mas só pode ver/tocar seus próprios objetos" (linhas específicas)

---

## 🚀 Exemplo Básico

```sql
-- Criar tabela
CREATE TABLE documentos (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(100),
    conteudo TEXT,
    dono VARCHAR(50)  -- Quem criou o documento
);

-- Inserir dados
INSERT INTO documentos (titulo, conteudo, dono) VALUES
('Doc 1', 'Conteúdo do João', 'joao'),
('Doc 2', 'Conteúdo da Maria', 'maria'),
('Doc 3', 'Outro doc do João', 'joao');

-- SEM RLS: Todos veem tudo
CREATE ROLE joao WITH LOGIN PASSWORD 'senha1';
CREATE ROLE maria WITH LOGIN PASSWORD 'senha2';

GRANT SELECT ON documentos TO joao, maria;

-- Conectar como joao
SET ROLE joao;
SELECT * FROM documentos;  -- Vê TODOS os documentos! ❌

RESET ROLE;

-- ATIVAR RLS
ALTER TABLE documentos ENABLE ROW LEVEL SECURITY;

-- Criar policy: usuários só veem seus documentos
CREATE POLICY documentos_visi_policy ON documentos
    FOR SELECT
    USING (dono = current_user);

-- Conceder permissões
GRANT SELECT ON documentos TO joao, maria;

-- Testar novamente
SET ROLE joao;
SELECT * FROM documentos;  -- Vê apenas documentos do João! ✅

SET ROLE maria;
SELECT * FROM documentos;  -- Vê apenas documentos da Maria! ✅

RESET ROLE;
```

---

## 📐 Estrutura de uma Policy

```sql
CREATE POLICY policy_name ON table_name
    [FOR {ALL | SELECT | INSERT | UPDATE | DELETE}]
    [TO {role_name | PUBLIC | CURRENT_USER}]
    [USING (condition)]         -- Quais linhas são visíveis
    [WITH CHECK (condition)];   -- Quais linhas podem ser modificadas
```

### Componentes:

1. **FOR**: Tipo de operação (SELECT, INSERT, UPDATE, DELETE, ALL)
2. **TO**: Quais roles a policy se aplica
3. **USING**: Condição para ver/modificar linhas existentes
4. **WITH CHECK**: Condição para novas linhas (INSERT/UPDATE)

---

## 🔍 USING vs WITH CHECK

### USING

Define quais linhas **existentes** são visíveis/acessíveis.

```sql
-- USING: Para SELECT, UPDATE, DELETE
CREATE POLICY doc_select ON documentos
    FOR SELECT
    USING (dono = current_user);

-- Usuário só VÊ suas linhas
-- Não pode UPDATE/DELETE linhas que não vê
```

### WITH CHECK

Define quais linhas **novas** podem ser criadas/modificadas.

```sql
-- WITH CHECK: Para INSERT, UPDATE
CREATE POLICY doc_insert ON documentos
    FOR INSERT
    WITH CHECK (dono = current_user);

-- Usuário só pode INSERIR com seu nome como dono
```

### Exemplo Completo

```sql
CREATE TABLE tarefas (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(100),
    status VARCHAR(20),
    responsavel VARCHAR(50),
    departamento VARCHAR(50)
);

ALTER TABLE tarefas ENABLE ROW LEVEL SECURITY;

-- Policy para SELECT: ver tarefas do seu departamento
CREATE POLICY tarefas_select ON tarefas
    FOR SELECT
    USING (departamento = current_setting('app.current_department', TRUE));

-- Policy para INSERT: só pode criar tarefas pro seu departamento
CREATE POLICY tarefas_insert ON tarefas
    FOR INSERT
    WITH CHECK (
        responsavel = current_user 
        AND departamento = current_setting('app.current_department', TRUE)
    );

-- Policy para UPDATE: só pode modificar suas próprias tarefas
CREATE POLICY tarefas_update ON tarefas
    FOR UPDATE
    USING (responsavel = current_user)
    WITH CHECK (responsavel = current_user);  -- Não pode mudar dono

-- Policy para DELETE: só pode deletar suas tarefas concluídas
CREATE POLICY tarefas_delete ON tarefas
    FOR DELETE
    USING (responsavel = current_user AND status = 'concluida');
```

---

## 🏢 Caso de Uso: Multi-tenancy com RLS

Sistema SaaS onde cada cliente (tenant) vê apenas seus dados.

```sql
-- Tabela multi-tenant
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL,
    descricao TEXT,
    valor NUMERIC(10, 2),
    data_criacao TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;

-- Policy: usuários só acessam dados do seu tenant
CREATE POLICY tenant_isolation ON pedidos
    USING (tenant_id = current_setting('app.current_tenant')::INTEGER);

-- Uso na aplicação
-- Ao conectar, definir tenant do usuário:
SET app.current_tenant = '123';  -- ID do tenant

-- Todas as queries são automaticamente filtradas!
SELECT * FROM pedidos;  -- Vê apenas pedidos do tenant 123
INSERT INTO pedidos (tenant_id, descricao, valor) 
VALUES (123, 'Novo pedido', 1000.00);  -- Funciona

INSERT INTO pedidos (tenant_id, descricao, valor) 
VALUES (456, 'Pedido outro tenant', 500.00);  -- RLS BLOQUEIA! ❌

-- Função helper
CREATE FUNCTION set_current_tenant(tenant_id INTEGER) RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_tenant', tenant_id::TEXT, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Uso:
SELECT set_current_tenant(123);
```

---

## 👥 Caso de Uso: Hierarquia Organizacional

Gerentes veem dados de sua equipe.

```sql
CREATE TABLE funcionarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    salario NUMERIC(10, 2),
    gerente_id INTEGER REFERENCES funcionarios(id)
);

ALTER TABLE funcionarios ENABLE ROW LEVEL SECURITY;

-- Policy: usuários veem a si mesmos
CREATE POLICY func_self ON funcionarios
    FOR ALL
    USING (nome = current_user);

-- Policy: gerentes veem sua equipe
CREATE POLICY func_gerente ON funcionarios
    FOR SELECT
    USING (
        gerente_id IN (
            SELECT id FROM funcionarios WHERE nome = current_user
        )
    );

-- Policy: RH vê todos (role específico)
CREATE POLICY func_rh ON funcionarios
    FOR ALL
    TO rh_role
    USING (TRUE);  -- Sem restrições para RH
```

---

## 🔓 Bypassando RLS

### BYPASSRLS Attribute

```sql
-- Criar role que ignora RLS
CREATE ROLE admin WITH LOGIN PASSWORD 'admin123' BYPASSRLS;

-- Ou alterar role existente
ALTER ROLE app_admin WITH BYPASSRLS;

-- ⚠️ CUIDADO: BYPASSRLS ignora TODAS as policies!
-- Use apenas para:
-- - Usuários administrativos
-- - Processos de backup
-- - Manutenção do sistema
```

### SECURITY DEFINER Functions

Functions com `SECURITY DEFINER` executam com privilégios do criador, não do chamador.

```sql
-- Função para admin inserir dados em qualquer tenant
CREATE FUNCTION admin_inserir_pedido(
    p_tenant_id INT,
    p_descricao TEXT,
    p_valor NUMERIC
) RETURNS INT AS $$
DECLARE
    novo_id INT;
BEGIN
    INSERT INTO pedidos (tenant_id, descricao, valor)
    VALUES (p_tenant_id, p_descricao, p_valor)
    RETURNING id INTO novo_id;
    
    RETURN novo_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Somente admins podem executar
REVOKE ALL ON FUNCTION admin_inserir_pedido FROM PUBLIC;
GRANT EXECUTE ON FUNCTION admin_inserir_pedido TO admin_role;
```

---

## ⚠️ Armadilhas Comuns

### 1. Esquecer de habilitar RLS

```sql
-- ❌ Policy criada mas RLS não habilitado = não funciona!
CREATE POLICY minha_policy ON tabela USING (condicao);
-- RLS ainda desabilitado!

-- ✅ Sempre habilitar RLS
ALTER TABLE tabela ENABLE ROW LEVEL SECURITY;
```

### 2. Permissões de tabela

```sql
-- RLS não substitui permissões de tabela!
-- Usuário ainda precisa de GRANT

ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_policy ON pedidos USING (tenant_id = 123);

-- ❌ Falta GRANT
SET ROLE app_user;
SELECT * FROM pedidos;  -- ERROR: permission denied

RESET ROLE;

-- ✅ Precisa de ambos: GRANT + RLS
GRANT SELECT ON pedidos TO app_user;
```

### 3. Performance com queries complexas

```sql
-- ❌ Pode ser lento se subquery for complexa
CREATE POLICY slow_policy ON tabela
    USING (
        id IN (
            SELECT tabela_id 
            FROM outra_tabela 
            JOIN mais_uma ON ...  -- Query pesada!
            WHERE ...
        )
    );

-- ✅ Melhor: usar função com cache ou configuração de sessão
CREATE POLICY fast_policy ON tabela
    USING (tenant_id = current_setting('app.tenant_id')::INT);
```

---

## 📊 Gerenciando Policies

```sql
-- Listar policies
SELECT schemaname, tablename, policyname, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'minha_tabela';

-- Ou no psql
\d+ minha_tabela

-- Desabilitar RLS temporariamente
ALTER TABLE minha_tabela DISABLE ROW LEVEL SECURITY;

-- Reabilitar
ALTER TABLE minha_tabela ENABLE ROW LEVEL SECURITY;

-- Forçar RLS para donos de tabela também (padrão: donos bypassam RLS)
ALTER TABLE minha_tabela FORCE ROW LEVEL SECURITY;

-- Remover policy
DROP POLICY policy_name ON minha_tabela;

-- Alterar policy (precisa recriar)
DROP POLICY old_policy ON tabela;
CREATE POLICY new_policy ON tabela USING (nova_condicao);
```

---

## 🎯 Boas Práticas

### 1. Use configurações de sessão para contexto

```sql
-- Definir contexto no início da sessão
SET app.current_tenant = '123';
SET app.current_user_role = 'manager';

-- Usar nas policies
CREATE POLICY tenant_policy ON tabela
    USING (tenant_id = current_setting('app.current_tenant')::INT);
```

### 2. Nomeie policies claramente

```sql
-- ❌ Ruim
CREATE POLICY p1 ON tabela ...
CREATE POLICY policy2 ON tabela ...

-- ✅ Bom
CREATE POLICY tenant_isolation_select ON tabela FOR SELECT ...
CREATE POLICY tenant_isolation_insert ON tabela FOR INSERT ...
CREATE POLICY manager_view_team ON tabela FOR SELECT ...
```

### 3. Teste com diferentes roles

```sql
-- Sempre teste policies
SET ROLE user_comum;
SELECT * FROM tabela;  -- O que vejo?
INSERT INTO tabela VALUES (...);  -- Funciona?

SET ROLE gerente;
SELECT * FROM tabela;  -- Vejo mais coisas?

SET ROLE admin;
SELECT * FROM tabela;  -- Vejo tudo?

RESET ROLE;
```

### 4. Documente policies

```sql
COMMENT ON POLICY tenant_isolation ON pedidos IS 
    'Garante que usuários apenas vejam pedidos do seu tenant';
```

---

## 🔗 Navegação

⬅️ [Anterior: Roles e Users](./01-roles-users.md) | [Próximo: Column Level Security →](./03-column-level-security.md)

---

## 📝 Resumo Rápido

```sql
-- Habilitar RLS
ALTER TABLE tabela ENABLE ROW LEVEL SECURITY;

-- Criar policy
CREATE POLICY nome ON tabela
    FOR SELECT
    USING (condicao);

-- Policy completa
CREATE POLICY nome ON tabela
    FOR ALL
    TO role_name
    USING (condicao_ver)
    WITH CHECK (condicao_inserir);

-- Bypass RLS
ALTER ROLE admin WITH BYPASSRLS;

-- Listar policies
SELECT * FROM pg_policies WHERE tablename = 'tabela';
```
