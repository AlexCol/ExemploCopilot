# 1.1 - Introdução a Schemas no PostgreSQL

## 📋 O que você vai aprender

- O que são schemas no PostgreSQL
- Por que usar schemas
- Conceitos fundamentais
- Analogias práticas

---

## 🎯 O que são Schemas?

Um **schema** no PostgreSQL é um namespace (espaço de nomes) que contém objetos de banco de dados como tabelas, views, índices, funções, e outros elementos.

### Analogia Prática

Pense em um schema como:
- **Uma pasta em um sistema de arquivos**: assim como você organiza documentos em pastas diferentes, schemas organizam objetos do banco de dados
- **Departamentos em uma empresa**: cada departamento (schema) tem seus próprios recursos (tabelas) mas todos fazem parte da mesma organização (database)

```
Database: minha_empresa
│
├── Schema: vendas
│   ├── Table: clientes
│   ├── Table: pedidos
│   └── Table: produtos
│
├── Schema: rh
│   ├── Table: funcionarios
│   ├── Table: departamentos
│   └── Table: salarios
│
└── Schema: financeiro
    ├── Table: contas
    ├── Table: transacoes
    └── Table: orcamentos
```

---

## ✅ Por que usar Schemas?

### 1. **Organização Lógica**
Agrupe objetos relacionados de forma lógica e intuitiva.

### 2. **Isolamento de Ambientes**
Separe dados de desenvolvimento, testes e produção no mesmo banco.

```sql
-- Exemplo de estrutura multi-ambiente
production_schema
staging_schema
development_schema
```

### 3. **Segurança**
Controle de acesso granular por schema, permitindo que diferentes usuários acessem apenas seus schemas específicos.

### 4. **Evitar Conflitos de Nomes**
Você pode ter tabelas com o mesmo nome em schemas diferentes:

```sql
vendas.produtos     -- Produtos do departamento de vendas
estoque.produtos    -- Produtos do controle de estoque
```

### 5. **Multi-tenancy**
Cada cliente/tenant pode ter seu próprio schema, compartilhando a mesma infraestrutura de banco de dados.

```sql
cliente_a.usuarios
cliente_b.usuarios
cliente_c.usuarios
```

---

## 🔍 Schema Padrão: `public`

Quando você cria um banco de dados PostgreSQL, ele vem com um schema padrão chamado `public`. Se você não especificar um schema ao criar uma tabela, ela será criada no schema `public`.

```sql
-- Estas duas instruções são equivalentes:
CREATE TABLE usuarios (id INT, nome VARCHAR(100));
CREATE TABLE public.usuarios (id INT, nome VARCHAR(100));
```

---

## 📊 Visualizando Schemas Existentes

Para ver todos os schemas no seu banco de dados:

```sql
-- Listar todos os schemas
SELECT schema_name 
FROM information_schema.schemata;

-- Usando comando PostgreSQL
\dn
```

**Schemas do Sistema** (não devem ser modificados):
- `pg_catalog`: contém as tabelas do sistema e funções built-in
- `information_schema`: contém views com metadados do banco
- `pg_toast`: armazena dados grandes de forma otimizada

---

## 💡 Exemplo Prático Inicial

```sql
-- Verificar schema atual
SELECT current_schema();

-- Listar objetos em um schema específico
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

---

## 🎓 Conceitos-Chave para Lembrar

1. **Schema ≠ Database**: Um database contém múltiplos schemas
2. **Schema = Namespace**: Organiza e agrupa objetos relacionados
3. **Schema padrão**: `public` é criado automaticamente
4. **Qualificação completa**: `schema.objeto` evita ambiguidades

---

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Próximo: Criando e Gerenciando Schemas →](./02-criando-gerenciando-schemas.md)

---

## 📝 Exercício Prático

Antes de avançar, execute estes comandos no seu PostgreSQL:

```sql
-- 1. Ver o schema atual
SELECT current_schema();

-- 2. Listar todos os schemas
\dn

-- 3. Ver tabelas no schema public
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
```

**Dica**: Anote os resultados para referência futura!
