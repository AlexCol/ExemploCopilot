# 1.5 - Boas Práticas com Schemas

## 📋 O que você vai aprender

- Padrões de organização eficazes
- Convenções de nomenclatura
- Estratégias de deployment
- Padrões arquiteturais
- Armadilhas a evitar
- Dicas de performance

---

## 🎯 Princípios Fundamentais

### 1. **Organização Lógica Clara**

Agrupe objetos relacionados de forma que faça sentido para seu negócio.

```sql
-- ✅ BOM: Organização por domínio de negócio
CREATE SCHEMA vendas;      -- Tudo relacionado a vendas
CREATE SCHEMA estoque;     -- Controle de estoque
CREATE SCHEMA financeiro;  -- Operações financeiras
CREATE SCHEMA rh;          -- Recursos humanos

-- ❌ RUIM: Organização sem critério claro
CREATE SCHEMA dados1;
CREATE SCHEMA temp;
CREATE SCHEMA novo;
```

### 2. **Princípio do Menor Privilégio**

Conceda apenas as permissões necessárias.

```sql
-- ✅ BOM: Permissões específicas
GRANT USAGE ON SCHEMA vendas TO app_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA vendas TO app_readonly;

-- ❌ RUIM: Permissões excessivas
GRANT ALL ON SCHEMA vendas TO app_readonly;
```

### 3. **Nomenclatura Consistente**

Use convenções claras e siga-as sempre.

```sql
-- ✅ BOM: Padrão consistente
CREATE SCHEMA vendas_brasil;
CREATE SCHEMA vendas_eua;
CREATE SCHEMA vendas_europa;

-- ❌ RUIM: Sem padrão
CREATE SCHEMA vendasBrasil;
CREATE SCHEMA vendas_USA;
CREATE SCHEMA Europa_Sales;
```

---

## 📐 Padrões de Organização

### Padrão 1: Por Domínio de Negócio

Ideal para sistemas complexos com múltiplos domínios.

```sql
-- Estrutura
CREATE SCHEMA vendas;
CREATE SCHEMA compras;
CREATE SCHEMA producao;
CREATE SCHEMA logistica;
CREATE SCHEMA financeiro;

-- Exemplo de uso
CREATE TABLE vendas.pedidos (...);
CREATE TABLE vendas.clientes (...);
CREATE TABLE logistica.entregas (...);
```

**Vantagens:**
- Separação clara de responsabilidades
- Fácil de entender e navegar
- Facilita trabalho em equipe (times diferentes, schemas diferentes)

**Quando usar:** Sistemas grandes com múltiplos domínios de negócio

---

### Padrão 2: Por Ambiente

Útil para ter múltiplos ambientes no mesmo database.

```sql
-- Estrutura
CREATE SCHEMA prod;
CREATE SCHEMA staging;
CREATE SCHEMA dev;

-- Uso com search_path
-- Conexão de produção:
SET search_path TO prod, public;

-- Conexão de desenvolvimento:
SET search_path TO dev, public;
```

**Vantagens:**
- Testes sem afetar produção
- Fácil comparação entre ambientes
- Simplifica deploys e rollbacks

**Quando usar:** Ambientes de desenvolvimento compartilhados, prototipagem

**⚠️ Atenção:** Em produção real, prefira databases separados para ambientes diferentes!

---

### Padrão 3: Multi-tenant (Um Schema por Cliente)

Cada cliente tem seu próprio schema isolado.

```sql
-- Estrutura
CREATE SCHEMA cliente_acme;
CREATE SCHEMA cliente_tech;
CREATE SCHEMA cliente_global;
CREATE SCHEMA compartilhado; -- Dados comuns a todos

-- Conexão por cliente
-- Cliente ACME:
SET search_path TO cliente_acme, compartilhado, public;

-- Cliente Tech:
SET search_path TO cliente_tech, compartilhado, public;
```

**Vantagens:**
- Isolamento total de dados
- Fácil backup/restore por cliente
- Simples adicionar/remover clientes
- Estrutura pode ser diferente por cliente se necessário

**Desvantagens:**
- Queries cross-tenant mais complexas
- Migração de schema requer iteração por todos os schemas
- Pode ter muitos schemas

**Quando usar:** SaaS com poucos/médios clientes, necessidade forte de isolamento

---

### Padrão 4: Por Layer (Camada de Aplicação)

Organização baseada em arquitetura de software.

```sql
-- Estrutura
CREATE SCHEMA raw;         -- Dados brutos
CREATE SCHEMA staging;     -- Dados em transformação
CREATE SCHEMA business;    -- Lógica de negócio
CREATE SCHEMA presentation;-- Views para apresentação
CREATE SCHEMA audit;       -- Logs e auditoria
```

**Vantagens:**
- Reflete arquitetura da aplicação
- Clara separação de responsabilidades
- Facilita governança de dados

**Quando usar:** Data warehouses, pipelines de ETL, sistemas com camadas bem definidas

---

### Padrão 5: Híbrido

Combine múltiplos padrões conforme necessário.

```sql
-- Negócio + Ambiente + Shared
CREATE SCHEMA prod_vendas;
CREATE SCHEMA prod_estoque;
CREATE SCHEMA staging_vendas;
CREATE SCHEMA staging_estoque;
CREATE SCHEMA shared_config;

-- Multi-tenant + Domínio
CREATE SCHEMA cliente_a_vendas;
CREATE SCHEMA cliente_a_financeiro;
CREATE SCHEMA cliente_b_vendas;
CREATE SCHEMA cliente_b_financeiro;
```

---

## 🏷️ Convenções de Nomenclatura

### Schemas

```sql
-- ✅ Recomendado
CREATE SCHEMA vendas;              -- minúsculas
CREATE SCHEMA recursos_humanos;    -- underscore para separar palavras
CREATE SCHEMA bi_analytics;        -- abreviações conhecidas ok
CREATE SCHEMA cliente_acme_corp;   -- identificador claro

-- ❌ Evitar
CREATE SCHEMA "Vendas & Marketing";  -- espaços e caracteres especiais
CREATE SCHEMA VendasMarketing;       -- camelCase
CREATE SCHEMA vnd;                   -- abreviações obscuras
CREATE SCHEMA schema1;               -- nomes genéricos
```

### Objetos dentro de Schemas

```sql
-- Use sempre o mesmo padrão em todo o projeto

-- Tabelas: singular ou plural (escolha um)
CREATE TABLE vendas.cliente (...);   -- singular
-- ou
CREATE TABLE vendas.clientes (...);  -- plural (mais comum)

-- Views: prefixo que indique que é view
CREATE VIEW vendas.vw_relatorio_mensal AS ...;
CREATE VIEW vendas.v_clientes_ativos AS ...;

-- Funções: verbos
CREATE FUNCTION vendas.calcular_total(...) ...;
CREATE FUNCTION vendas.obter_cliente_por_email(...) ...;

-- Sequences: sufixo _seq
CREATE SEQUENCE vendas.pedidos_id_seq;
```

---

## 🚀 Estratégias de Deployment

### Migration Scripts

Organize suas migrations considerando schemas:

```sql
-- migration_001_criar_schemas.sql
CREATE SCHEMA IF NOT EXISTS vendas;
CREATE SCHEMA IF NOT EXISTS estoque;

-- migration_002_criar_tabelas_vendas.sql
SET search_path TO vendas, public;

CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100)
);

-- migration_003_criar_tabelas_estoque.sql
SET search_path TO estoque, public;

CREATE TABLE IF NOT EXISTS produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100)
);
```

### Deploy Cross-Schema

```sql
-- Referências entre schemas devem ser explícitas
CREATE TABLE vendas.pedidos (
    id SERIAL PRIMARY KEY,
    produto_id INT REFERENCES estoque.produtos(id), -- explícito!
    cliente_id INT REFERENCES vendas.clientes(id)
);
```

### Versionamento de Schema

```sql
-- Estratégia de versionamento
CREATE SCHEMA app_v1;
CREATE SCHEMA app_v2;

-- Durante migração gradual
SET search_path TO app_v2, app_v1, public;

-- Após migração completa
DROP SCHEMA app_v1 CASCADE;
```

---

## ⚡ Performance e Otimização

### 1. Search Path Conciso

```sql
-- ✅ BOM: Apenas schemas necessários
SET search_path TO app_schema, public;

-- ❌ RUIM: Search path muito longo
SET search_path TO s1, s2, s3, s4, s5, s6, s7, public;
```

### 2. Qualificação Explícita em Queries Críticas

```sql
-- ✅ BOM: Evita lookup de schema
SELECT * FROM vendas.pedidos WHERE status = 'pendente';

-- ⚠️ Depende de search_path (mais lento)
SELECT * FROM pedidos WHERE status = 'pendente';
```

### 3. Índices e Estatísticas por Schema

```sql
-- Atualizar estatísticas de um schema específico
ANALYZE vendas.pedidos;

-- Ou todo o schema
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'vendas'
    LOOP
        EXECUTE 'ANALYZE vendas.' || r.tablename;
    END LOOP;
END $$;
```

---

## 🛡️ Segurança

### 1. Revogar Acesso Público

```sql
-- No início do seu setup
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
```

### 2. Uso de Roles

```sql
-- Criar roles por nível de acesso
CREATE ROLE app_readonly;
CREATE ROLE app_readwrite;
CREATE ROLE app_admin;

-- Configurar permissões nas roles
GRANT USAGE ON SCHEMA vendas TO app_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA vendas TO app_readonly;

-- Atribuir roles a usuários
GRANT app_readonly TO user_report;
GRANT app_readwrite TO user_app;
```

### 3. Audit Schema

```sql
-- Schema separado para auditoria
CREATE SCHEMA audit;

-- Tabela de log
CREATE TABLE audit.login_log (
    id SERIAL PRIMARY KEY,
    usuario VARCHAR(100),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    acao TEXT
);

-- Apenas admin tem acesso
GRANT ALL ON SCHEMA audit TO admin_role;
```

---

## ❌ Antipadrões - O que NÃO fazer

### 1. Schema por Tipo de Objeto

```sql
-- ❌ RUIM: Não organize por tipo de objeto
CREATE SCHEMA tabelas;
CREATE SCHEMA views;
CREATE SCHEMA funcoes;

-- Isso quebra coesão do domínio de negócio
```

### 2. Dependência Excessiva de search_path

```sql
-- ❌ RUIM: Código que depende de search_path específico
CREATE FUNCTION processar_pedido() AS $$
BEGIN
    -- Assume que 'pedidos' está no search_path
    UPDATE pedidos SET status = 'processado';
END;
$$ LANGUAGE plpgsql;

-- ✅ BOM: Seja explícito
CREATE FUNCTION vendas.processar_pedido() AS $$
BEGIN
    UPDATE vendas.pedidos SET status = 'processado';
END;
$$ LANGUAGE plpgsql;
```

### 3. Schemas Muito Granulares

```sql
-- ❌ RUIM: Excesso de schemas
CREATE SCHEMA vendas_pedidos;
CREATE SCHEMA vendas_clientes;
CREATE SCHEMA vendas_produtos;
CREATE SCHEMA vendas_pagamentos;

-- ✅ BOM: Agrupe relacionados
CREATE SCHEMA vendas; -- contém pedidos, clientes, produtos, pagamentos
```

### 4. Misturar Dados e Lógica sem Critério

```sql
-- ❌ RUIM: Schemas misturados
-- vendas.clientes (tabela)
-- vendas.calcular_frete (função que usa dados de estoque)
-- estoque.produtos (tabela)
-- estoque.validar_pedido (função que usa dados de vendas)

-- ✅ BOM: Separe claramente ou use schema compartilhado
-- vendas.clientes
-- vendas.pedidos
-- estoque.produtos
-- business_logic.calcular_frete
-- business_logic.validar_pedido
```

---

## 📋 Checklist de Boas Práticas

### Setup Inicial
- [ ] Definir estratégia de organização (domínio, ambiente, multi-tenant, etc.)
- [ ] Estabelecer convenção de nomenclatura
- [ ] Documentar estrutura de schemas
- [ ] Revogar permissões do schema `public`

### Desenvolvimento
- [ ] Criar schemas antes de objetos
- [ ] Usar qualificação explícita em código crítico
- [ ] Documentar dependências cross-schema
- [ ] Versionar scripts de migration
- [ ] Testar search_path da aplicação

### Segurança
- [ ] Usar roles em vez de usuários individuais
- [ ] Aplicar princípio do menor privilégio
- [ ] Configurar DEFAULT PRIVILEGES
- [ ] Schema separado para dados sensíveis/audit

### Performance
- [ ] Search_path conciso
- [ ] Qualificação explícita em queries frequentes
- [ ] Índices apropriados em todas as tabelas
- [ ] Monitorar crescimento de schemas

### Manutenção
- [ ] Backup strategy considera schemas
- [ ] Documentação atualizada
- [ ] Revisão periódica de permissões
- [ ] Plano para depreciar schemas antigos

---

## 📚 Exemplo Completo: Sistema E-commerce

```sql
-- ========================================
-- E-COMMERCE DATABASE STRUCTURE
-- ========================================

-- 1. SCHEMAS DE DOMÍNIO
-- ========================================

-- Catálogo de produtos
CREATE SCHEMA catalogo;

-- Vendas e pedidos
CREATE SCHEMA vendas;

-- Gerenciamento de estoque
CREATE SCHEMA estoque;

-- Clientes e usuários
CREATE SCHEMA usuarios;

-- Pagamentos e financeiro
CREATE SCHEMA financeiro;

-- Dados compartilhados e configurações
CREATE SCHEMA config;

-- Logs e auditoria
CREATE SCHEMA audit;

-- ========================================
-- 2. ROLES E PERMISSÕES
-- ========================================

-- Role de leitura
CREATE ROLE ecommerce_readonly;
GRANT CONNECT ON DATABASE ecommerce TO ecommerce_readonly;
GRANT USAGE ON SCHEMA catalogo, vendas, usuarios TO ecommerce_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA catalogo, vendas, usuarios TO ecommerce_readonly;

-- Role de aplicação (read/write)
CREATE ROLE ecommerce_app;
GRANT ecommerce_readonly TO ecommerce_app;
GRANT USAGE ON SCHEMA estoque, financeiro TO ecommerce_app;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA vendas, estoque TO ecommerce_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA vendas, estoque TO ecommerce_app;

-- Role de admin
CREATE ROLE ecommerce_admin;
GRANT ALL ON SCHEMA catalogo, vendas, estoque, usuarios, financeiro, config TO ecommerce_admin;

-- Role de auditoria
CREATE ROLE ecommerce_auditor;
GRANT USAGE ON SCHEMA audit TO ecommerce_auditor;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO ecommerce_auditor;

-- ========================================
-- 3. TABELAS EXEMPLO
-- ========================================

-- Catálogo
CREATE TABLE catalogo.produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10,2) NOT NULL
);

CREATE TABLE catalogo.categorias (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

-- Usuários
CREATE TABLE usuarios.clientes (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    nome VARCHAR(100) NOT NULL,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Vendas
CREATE TABLE vendas.pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES usuarios.clientes(id),
    status VARCHAR(20) NOT NULL,
    total DECIMAL(10,2),
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE vendas.itens_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id INT REFERENCES vendas.pedidos(id),
    produto_id INT REFERENCES catalogo.produtos(id),
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL
);

-- Estoque
CREATE TABLE estoque.inventario (
    produto_id INT PRIMARY KEY REFERENCES catalogo.produtos(id),
    quantidade INT NOT NULL DEFAULT 0,
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Auditoria
CREATE TABLE audit.log_pedidos (
    id SERIAL PRIMARY KEY,
    pedido_id INT,
    usuario VARCHAR(100),
    acao VARCHAR(50),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    detalhes JSONB
);

-- ========================================
-- 4. PERMISSÕES PARA OBJETOS FUTUROS
-- ========================================

ALTER DEFAULT PRIVILEGES IN SCHEMA catalogo, vendas, usuarios
    GRANT SELECT ON TABLES TO ecommerce_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA vendas, estoque
    GRANT SELECT, INSERT, UPDATE ON TABLES TO ecommerce_app;

-- ========================================
-- 5. SEARCH PATH PADRÃO
-- ========================================

-- Para aplicação
ALTER ROLE ecommerce_app SET search_path TO vendas, catalogo, estoque, config, public;

-- Para relatórios
ALTER ROLE ecommerce_readonly SET search_path TO vendas, catalogo, usuarios, public;

-- ========================================
-- 6. VIEWS CROSS-SCHEMA
-- ========================================

CREATE VIEW vendas.vw_pedidos_completos AS
SELECT 
    p.id,
    p.criado_em,
    c.nome AS cliente_nome,
    c.email AS cliente_email,
    p.status,
    p.total
FROM vendas.pedidos p
JOIN usuarios.clientes c ON p.cliente_id = c.id;

-- Permissões na view
GRANT SELECT ON vendas.vw_pedidos_completos TO ecommerce_readonly;
```

---

## 🎓 Resumo Final

| Princípio | Descrição |
|-----------|-----------|
| **Organização** | Agrupe por domínio de negócio ou arquitetura clara |
| **Nomenclatura** | Use padrão consistente, minúsculas, underscores |
| **Segurança** | Menor privilégio, use roles, revogue public |
| **Performance** | Search_path conciso, qualificação explícita |
| **Manutenção** | Documente, versione, monitore |
| **Deployment** | Scripts de migration, referências explícitas |

---

## 🔗 Navegação

⬅️ [Anterior: Permissões em Schemas](./04-permissoes-schemas.md) | [Voltar ao Índice](../README.md)

---

## 🎉 Parabéns!

Você completou o módulo sobre Schemas no PostgreSQL! Agora você tem conhecimento sólido sobre:

✅ O que são schemas e por que usá-los  
✅ Como criar e gerenciar schemas  
✅ Como funciona o search_path  
✅ Como configurar permissões adequadamente  
✅ Boas práticas para projetos reais  

### 📚 Próximos Passos Sugeridos

- Pratique criando uma estrutura de schemas para um projeto real
- Explore outros tópicos de PostgreSQL (índices, particionamento, replicação)
- Implemente um projeto multi-tenant usando schemas
- Estude performance tuning em bancos com múltiplos schemas

---

**Continue estudando PostgreSQL!** 🐘
