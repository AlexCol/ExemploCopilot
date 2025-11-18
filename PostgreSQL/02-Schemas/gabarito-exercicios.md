# Gabarito dos Exercícios - Schemas

## ✅ Soluções Comentadas

---

## Exercício 1: Criando Schemas Básicos

```sql
-- Criar schemas
CREATE SCHEMA vendas;
CREATE SCHEMA estoque;
CREATE SCHEMA financeiro;

-- Listar schemas (excluindo sistema)
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY schema_name;

-- Alternativa usando psql
\dn

/*
RESULTADO ESPERADO:
schema_name
-------------
estoque
financeiro
public
vendas
*/
```

---

## Exercício 2: Criando Tabelas em Schemas Específicos

```sql
-- Tabelas no schema vendas
CREATE TABLE vendas.clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE vendas.pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES vendas.clientes(id),
    data_pedido TIMESTAMPTZ DEFAULT NOW(),
    total NUMERIC(10, 2)
);

-- Tabela no schema estoque
CREATE TABLE estoque.produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    quantidade INTEGER DEFAULT 0,
    preco NUMERIC(10, 2) NOT NULL
);

-- Inserir dados de exemplo
INSERT INTO vendas.clientes (nome, email) VALUES
('João Silva', 'joao@email.com'),
('Maria Santos', 'maria@email.com'),
('Pedro Oliveira', 'pedro@email.com');

INSERT INTO estoque.produtos (nome, quantidade, preco) VALUES
('Notebook Dell', 10, 3500.00),
('Mouse Logitech', 50, 89.90),
('Teclado Mecânico', 25, 450.00);

INSERT INTO vendas.pedidos (cliente_id, total) VALUES
(1, 3589.90),
(2, 450.00),
(1, 89.90);

-- Verificar
SELECT * FROM vendas.clientes;
SELECT * FROM estoque.produtos;
SELECT * FROM vendas.pedidos;
```

---

## Exercício 3: Referências Entre Schemas

```sql
-- Criar tabela com FKs cross-schema
CREATE TABLE vendas.itens_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id INTEGER REFERENCES vendas.pedidos(id) ON DELETE CASCADE,
    produto_id INTEGER REFERENCES estoque.produtos(id),
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(10, 2) NOT NULL
);

-- Inserir itens
INSERT INTO vendas.itens_pedido (pedido_id, produto_id, quantidade, preco_unitario) VALUES
(1, 1, 1, 3500.00),  -- Pedido 1: Notebook
(1, 2, 1, 89.90),    -- Pedido 1: Mouse
(2, 3, 1, 450.00),   -- Pedido 2: Teclado
(3, 2, 1, 89.90);    -- Pedido 3: Mouse

-- Verificar com JOIN cross-schema
SELECT 
    p.id AS pedido_id,
    c.nome AS cliente,
    prod.nome AS produto,
    i.quantidade,
    i.preco_unitario
FROM vendas.pedidos p
JOIN vendas.clientes c ON p.cliente_id = c.id
JOIN vendas.itens_pedido i ON i.pedido_id = p.id
JOIN estoque.produtos prod ON i.produto_id = prod.id
ORDER BY p.id;
```

---

## Exercício 4: Search Path Básico

```sql
-- a) Verificar search_path atual
SHOW search_path;
-- Resultado típico: "$user", public

-- b) Configurar novo search_path
SET search_path TO vendas, estoque, public;

-- c) Consultar clientes sem schema
SELECT * FROM clientes;  -- Usa vendas.clientes

-- d) Consultar produtos sem schema
SELECT * FROM produtos;  -- Usa estoque.produtos

-- e) Resetar ao padrão
RESET search_path;

-- Verificar novamente
SHOW search_path;

/*
OBSERVAÇÃO:
- Com search_path configurado, PostgreSQL procura primeiro em 'vendas'
- Se não encontrar, procura em 'estoque'
- Se não encontrar, procura em 'public'
- Isso funciona porque cada tabela está em schema diferente
*/
```

---

## Exercício 5: Ambiguidade de Nomes

```sql
-- Criar tabelas com mesmo nome em schemas diferentes
CREATE TABLE vendas.logs (
    id SERIAL PRIMARY KEY,
    acao VARCHAR(50),
    usuario VARCHAR(50),
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE estoque.logs (
    id SERIAL PRIMARY KEY,
    acao VARCHAR(50),
    produto_id INTEGER,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Inserir dados diferentes
INSERT INTO vendas.logs (acao, usuario) VALUES 
('pedido_criado', 'joao'),
('pedido_cancelado', 'maria');

INSERT INTO estoque.logs (acao, produto_id) VALUES 
('entrada_estoque', 1),
('saida_estoque', 2);

-- Testar com diferentes search_paths

-- Cenário 1: vendas primeiro
SET search_path TO vendas, estoque, public;
SELECT * FROM logs;  -- Retorna vendas.logs (acao, usuario)

-- Cenário 2: estoque primeiro
SET search_path TO estoque, vendas, public;
SELECT * FROM logs;  -- Retorna estoque.logs (acao, produto_id)

-- Cenário 3: sempre seja explícito para evitar ambiguidade
SELECT * FROM vendas.logs;
SELECT * FROM estoque.logs;

-- Resetar
RESET search_path;

/*
LIÇÃO IMPORTANTE:
✅ Sempre use schema.tabela em código crítico para evitar ambiguidade
❌ Dependência excessiva de search_path pode causar bugs difíceis de encontrar
*/
```

---

## Exercício 6: Movendo Objetos Entre Schemas

```sql
-- a) Criar schema temporário
CREATE SCHEMA temp_importacao;

-- b) Criar tabela temporária
CREATE TABLE temp_importacao.novos_produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    preco NUMERIC(10, 2)
);

-- c) Inserir produtos
INSERT INTO temp_importacao.novos_produtos (nome, preco) VALUES
('Webcam HD', 299.00),
('Headset Gamer', 450.00),
('Monitor 24"', 890.00);

-- d) Mover para schema estoque
ALTER TABLE temp_importacao.novos_produtos SET SCHEMA estoque;

-- e) Verificar
\dt estoque.*
SELECT * FROM estoque.novos_produtos;

-- Tentar acessar no schema antigo (deve dar erro)
SELECT * FROM temp_importacao.novos_produtos;  -- ERRO!

-- Limpar
DROP SCHEMA temp_importacao;  -- Agora está vazio, pode ser excluído
```

---

## Exercício 7: Renomeando Schemas

```sql
-- a) Criar schema
CREATE SCHEMA temp_vendas;

-- b) Criar tabelas
CREATE TABLE temp_vendas.teste1 (id INT);
CREATE TABLE temp_vendas.teste2 (id INT);

-- c) Renomear schema
ALTER SCHEMA temp_vendas RENAME TO vendas_backup;

-- d) Verificar acesso
\dt vendas_backup.*
SELECT * FROM vendas_backup.teste1;  -- Funciona!

-- Limpar
DROP SCHEMA vendas_backup CASCADE;

/*
IMPORTANTE:
- Renomear schema NÃO quebra tabelas dentro dele
- Mas pode quebrar referências em código de aplicação!
- Sempre faça backup antes de renomear em produção
*/
```

---

## Exercício 8: Excluindo Schemas

```sql
-- a) Criar schema
CREATE SCHEMA teste_delete;

-- b) Criar tabela
CREATE TABLE teste_delete.dados (
    id SERIAL PRIMARY KEY,
    valor TEXT
);

INSERT INTO teste_delete.dados (valor) VALUES ('teste');

-- c) Tentar excluir sem CASCADE
DROP SCHEMA teste_delete;
-- ERROR: cannot drop schema teste_delete because other objects depend on it
-- HINT: Use DROP ... CASCADE to drop the dependent objects too.

-- d) Excluir com CASCADE
DROP SCHEMA teste_delete CASCADE;
-- NOTICE: drop cascades to table teste_delete.dados

-- e) Confirmar exclusão
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'teste_delete';
-- (0 rows)

/*
⚠️ CUIDADO:
CASCADE exclui TODOS os objetos dentro do schema permanentemente!
Sempre faça backup antes de usar CASCADE em produção!
*/
```

---

## Exercício 9: Permissões - Usuário Somente Leitura

```sql
-- Criar usuário (precisa de privilégios de superuser)
CREATE USER relatorio_user WITH PASSWORD 'senha_segura123';

-- Permitir conexão ao database
GRANT CONNECT ON DATABASE exercicios_schemas TO relatorio_user;

-- Permitir acesso ao schema
GRANT USAGE ON SCHEMA vendas TO relatorio_user;

-- Permitir SELECT em todas as tabelas existentes
GRANT SELECT ON ALL TABLES IN SCHEMA vendas TO relatorio_user;

-- Garantir acesso a tabelas futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT SELECT ON TABLES TO relatorio_user;

-- Testar (em nova sessão ou com SET ROLE)
-- Como superuser:
SET ROLE relatorio_user;

-- Deve funcionar:
SELECT * FROM vendas.clientes;

-- Deve falhar:
INSERT INTO vendas.clientes (nome, email) VALUES ('Teste', 'teste@email.com');
-- ERROR: permission denied for table clientes

DELETE FROM vendas.clientes WHERE id = 1;
-- ERROR: permission denied for table clientes

-- Voltar ao role anterior
RESET ROLE;

/*
VERIFICAR PERMISSÕES:
*/
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'relatorio_user'
AND table_schema = 'vendas';
```

---

## Exercício 10: Permissões - Usuário com Escrita

```sql
-- Criar usuário
CREATE USER app_user WITH PASSWORD 'senha_app456';

-- Conectar ao database
GRANT CONNECT ON DATABASE exercicios_schemas TO app_user;

-- Acesso aos schemas
GRANT USAGE ON SCHEMA vendas, estoque TO app_user;

-- Permissões de leitura e escrita
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA vendas TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA estoque TO app_user;

-- Permissão para usar sequences (necessário para SERIAL)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA vendas TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA estoque TO app_user;

-- Para tabelas futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT USAGE, SELECT ON SEQUENCES TO app_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA estoque
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA estoque
    GRANT USAGE, SELECT ON SEQUENCES TO app_user;

-- Testar
SET ROLE app_user;

-- Deve funcionar:
SELECT * FROM vendas.clientes;
INSERT INTO vendas.clientes (nome, email) VALUES ('App User Test', 'apptest@email.com');
UPDATE vendas.clientes SET nome = 'App User Updated' WHERE email = 'apptest@email.com';
SELECT * FROM estoque.produtos;

-- Não deve ter acesso a financeiro
SELECT * FROM financeiro.contas;  -- ERROR (se existir)

RESET ROLE;
```

---

## Exercícios 11-25: Estrutura das Soluções

Devido ao tamanho, aqui estão os pontos principais:

### Exercício 11: DEFAULT PRIVILEGES

```sql
-- Configurar privilégios para tabelas futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA vendas
    GRANT SELECT ON TABLES TO relatorio_user;

-- Criar nova tabela
CREATE TABLE vendas.nova_tabela (id INT);

-- Verificar que relatorio_user já tem acesso
SET ROLE relatorio_user;
SELECT * FROM vendas.nova_tabela;  -- Funciona!
RESET ROLE;
```

### Exercício 12: Multi-tenant

```sql
-- Criar schemas por cliente
CREATE SCHEMA cliente_acme;
CREATE SCHEMA cliente_tech;
CREATE SCHEMA cliente_global;

-- Estrutura idêntica em cada
DO $$
DECLARE
    schema_name TEXT;
BEGIN
    FOREACH schema_name IN ARRAY ARRAY['cliente_acme', 'cliente_tech', 'cliente_global']
    LOOP
        EXECUTE format('
            CREATE TABLE %I.usuarios (
                id SERIAL PRIMARY KEY,
                nome VARCHAR(100),
                email VARCHAR(100)
            );
            CREATE TABLE %I.documentos (
                id SERIAL PRIMARY KEY,
                titulo VARCHAR(200),
                conteudo TEXT,
                usuario_id INT REFERENCES %I.usuarios(id)
            );
        ', schema_name, schema_name, schema_name);
    END LOOP;
END $$;

-- View para admin ver todos
CREATE VIEW admin.vw_todos_usuarios AS
SELECT 'ACME' AS cliente, * FROM cliente_acme.usuarios
UNION ALL
SELECT 'TECH' AS cliente, * FROM cliente_tech.usuarios
UNION ALL
SELECT 'GLOBAL' AS cliente, * FROM cliente_global.usuarios;
```

### Exercício 14: Consultando Metadados

```sql
-- a) Schemas e donos
SELECT 
    schema_name,
    schema_owner
FROM information_schema.schemata
WHERE schema_name NOT LIKE 'pg_%' 
AND schema_name != 'information_schema';

-- b) Tabelas no schema vendas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'vendas';

-- c) Tamanho em MB
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'vendas'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- d) Foreign keys cross-schema
SELECT
    tc.table_schema,
    tc.table_name,
    kcu.column_name,
    ccu.table_schema AS foreign_schema,
    ccu.table_name AS foreign_table,
    ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema != ccu.table_schema;  -- Cross-schema only
```

### Exercício 25: Desafio Final - Sistema Escolar

```sql
-- Criar estrutura completa
CREATE SCHEMA academico;
CREATE SCHEMA financeiro;
CREATE SCHEMA biblioteca;
CREATE SCHEMA rh;
CREATE SCHEMA config;
CREATE SCHEMA audit;

-- Tabelas acadêmico
CREATE TABLE academico.alunos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    matricula VARCHAR(20) UNIQUE NOT NULL,
    data_nascimento DATE,
    email VARCHAR(100)
);

CREATE TABLE academico.turmas (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE,
    ano INTEGER,
    semestre INTEGER
);

CREATE TABLE academico.disciplinas (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE,
    nome VARCHAR(100),
    carga_horaria INTEGER
);

CREATE TABLE academico.matriculas (
    id SERIAL PRIMARY KEY,
    aluno_id INT REFERENCES academico.alunos(id),
    turma_id INT REFERENCES academico.turmas(id),
    disciplina_id INT REFERENCES academico.disciplinas(id),
    nota NUMERIC(4, 2),
    frequencia NUMERIC(5, 2)
);

-- Tabelas financeiro
CREATE TABLE financeiro.mensalidades (
    id SERIAL PRIMARY KEY,
    aluno_id INT REFERENCES academico.alunos(id),  -- Cross-schema FK
    valor NUMERIC(10, 2),
    vencimento DATE,
    status VARCHAR(20) DEFAULT 'pendente'
);

CREATE TABLE financeiro.pagamentos (
    id SERIAL PRIMARY KEY,
    mensalidade_id INT REFERENCES financeiro.mensalidades(id),
    valor_pago NUMERIC(10, 2),
    data_pagamento TIMESTAMPTZ DEFAULT NOW()
);

-- Biblioteca
CREATE TABLE biblioteca.livros (
    id SERIAL PRIMARY KEY,
    isbn VARCHAR(20),
    titulo VARCHAR(200),
    autor VARCHAR(100),
    quantidade_total INT,
    quantidade_disponivel INT
);

CREATE TABLE biblioteca.emprestimos (
    id SERIAL PRIMARY KEY,
    livro_id INT REFERENCES biblioteca.livros(id),
    aluno_id INT REFERENCES academico.alunos(id),  -- Cross-schema FK
    data_emprestimo TIMESTAMPTZ DEFAULT NOW(),
    data_devolucao_prevista DATE,
    data_devolucao_real DATE,
    status VARCHAR(20) DEFAULT 'ativo'
);

-- RH
CREATE TABLE rh.professores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    cpf VARCHAR(14) UNIQUE,
    especialidade VARCHAR(100),
    salario NUMERIC(10, 2)
);

CREATE TABLE rh.funcionarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    cargo VARCHAR(50),
    departamento VARCHAR(50),
    salario NUMERIC(10, 2)
);

-- Config
CREATE TABLE config.parametros (
    chave VARCHAR(50) PRIMARY KEY,
    valor TEXT,
    descricao TEXT
);

-- Audit
CREATE TABLE audit.log_operacoes (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    usuario VARCHAR(50),
    schema_name VARCHAR(50),
    table_name VARCHAR(50),
    operacao VARCHAR(20),
    dados_json JSONB
);

-- Views úteis
CREATE VIEW financeiro.vw_alunos_inadimplentes AS
SELECT 
    a.nome,
    a.matricula,
    COUNT(m.id) AS mensalidades_pendentes,
    SUM(m.valor) AS valor_total_devido
FROM academico.alunos a
JOIN financeiro.mensalidades m ON m.aluno_id = a.id
WHERE m.status = 'pendente'
AND m.vencimento < CURRENT_DATE
GROUP BY a.id, a.nome, a.matricula
HAVING COUNT(m.id) > 0;

CREATE VIEW biblioteca.vw_livros_disponiveis AS
SELECT 
    titulo,
    autor,
    quantidade_disponivel
FROM biblioteca.livros
WHERE quantidade_disponivel > 0
ORDER BY titulo;

-- Usuários e permissões
CREATE ROLE aluno_role;
GRANT USAGE ON SCHEMA academico, biblioteca TO aluno_role;
GRANT SELECT ON academico.disciplinas, academico.turmas TO aluno_role;
GRANT SELECT ON biblioteca.vw_livros_disponiveis TO aluno_role;

CREATE ROLE professor_role;
GRANT USAGE ON SCHEMA academico TO professor_role;
GRANT SELECT, UPDATE ON academico.matriculas TO professor_role;

CREATE ROLE admin_role;
GRANT ALL ON ALL SCHEMAS TO admin_role;
GRANT ALL ON ALL TABLES IN ALL SCHEMAS TO admin_role;

-- Inserir dados de exemplo
INSERT INTO academico.alunos (nome, matricula, email) VALUES
('Ana Silva', '2024001', 'ana@escola.com'),
('Bruno Costa', '2024002', 'bruno@escola.com'),
('Carla Souza', '2024003', 'carla@escola.com');

INSERT INTO biblioteca.livros (isbn, titulo, autor, quantidade_total, quantidade_disponivel) VALUES
('978-1234567890', 'Introdução à Programação', 'João Santos', 5, 3),
('978-0987654321', 'Banco de Dados Avançado', 'Maria Lima', 3, 2);

INSERT INTO financeiro.mensalidades (aluno_id, valor, vencimento, status) VALUES
(1, 1500.00, '2025-11-05', 'pago'),
(2, 1500.00, '2025-11-05', 'pendente'),
(3, 1500.00, '2025-10-05', 'pendente');

-- Queries de relatório
-- 1. Alunos inadimplentes
SELECT * FROM financeiro.vw_alunos_inadimplentes;

-- 2. Livros mais emprestados
SELECT 
    l.titulo,
    COUNT(e.id) AS total_emprestimos
FROM biblioteca.livros l
JOIN biblioteca.emprestimos e ON e.livro_id = l.id
GROUP BY l.id, l.titulo
ORDER BY total_emprestimos DESC
LIMIT 10;

-- 3. Desempenho por turma
SELECT 
    t.codigo AS turma,
    d.nome AS disciplina,
    AVG(m.nota) AS media,
    AVG(m.frequencia) AS frequencia_media
FROM academico.matriculas m
JOIN academico.turmas t ON m.turma_id = t.id
JOIN academico.disciplinas d ON m.disciplina_id = d.id
GROUP BY t.codigo, d.nome
ORDER BY media DESC;
```

---

## 🎓 Conclusão

Estas soluções demonstram:
- ✅ Organização eficiente com schemas
- ✅ Controle de acesso granular
- ✅ Relacionamentos cross-schema
- ✅ Arquitetura multi-tenant
- ✅ Padrões de segurança
- ✅ Consultas complexas em múltiplos schemas

---

## 🔗 Navegação

[← Voltar para Exercícios](./exercicios.md) | [Início do Módulo →](./README.md)
