# 16.1 - Histórico de Comandos (.psql_history)

## 📋 O que você vai aprender

- Arquivo .psql_history
- Configuração do histórico
- Comandos de histórico no psql
- Busca e navegação no histórico
- Histórico por database
- Considerações de segurança

---

## 🎯 O que é o .psql_history?

O `.psql_history` é um arquivo mantido pelo cliente **psql** que armazena o histórico de comandos SQL e meta-comandos executados no terminal interativo.

### Características

- **Escopo**: Apenas cliente psql (não funciona em pgAdmin, DBeaver, etc)
- **Localização**: Diretório home do usuário
- **Persistência**: Mantido entre sessões
- **Separação**: Um arquivo por database (opcional)

### Localização do Arquivo

```bash
# Linux/Mac
~/.psql_history

# Windows
%APPDATA%\postgresql\.psql_history

# Verificar localização
psql -c "SHOW data_directory"  # Não, isso é outra coisa!

# Na verdade, verificar com:
echo $HOME/.psql_history          # Linux/Mac
echo %APPDATA%\postgresql\.psql_history  # Windows
```

---

## 📖 Navegando no Histórico

### Setas do Teclado

```sql
-- Pressione ↑ (seta para cima) para navegar pelos comandos anteriores
-- Pressione ↓ (seta para baixo) para voltar

-- Exemplo de fluxo:
psql> SELECT * FROM clientes;
psql> SELECT * FROM pedidos;
psql> -- Pressiona ↑
psql> SELECT * FROM pedidos;  -- Comando anterior aparece
psql> -- Pressiona ↑ novamente
psql> SELECT * FROM clientes;  -- Comando mais antigo aparece
```

### Busca no Histórico (Ctrl+R)

```sql
-- Pressione Ctrl+R e comece a digitar
-- O psql busca no histórico por comandos que contenham o texto

-- Exemplo:
psql> (reverse-i-search)`clientes': SELECT * FROM clientes WHERE id = 123;

-- Pressione Ctrl+R novamente para ver ocorrências mais antigas
-- Pressione Enter para executar o comando
-- Pressione Esc para cancelar a busca
```

### Meta-comando \s (Show History)

```sql
-- Mostrar todo o histórico
\s

-- Salvar histórico em arquivo
\s /tmp/meu_historico.sql

-- Exemplo de saída:
/*
SELECT * FROM clientes;
UPDATE pedidos SET status = 'pago' WHERE id = 123;
CREATE INDEX idx_clientes_email ON clientes(email);
\d clientes
SELECT COUNT(*) FROM pedidos WHERE data > '2024-01-01';
*/
```

---

## ⚙️ Configuração do Histórico

### Tamanho do Histórico

O psql usa a biblioteca GNU Readline, que respeita a variável `HISTSIZE`:

```bash
# Linux/Mac - No ~/.bashrc ou ~/.zshrc
export HISTSIZE=10000  # Número de comandos no histórico

# Windows - Variável de ambiente
setx HISTSIZE 10000
```

### Histórico por Database

Por padrão, o psql mantém um único arquivo `.psql_history` para todos os databases. Você pode configurar históricos separados:

```bash
# Linux/Mac - No ~/.psqlrc
\set HISTFILE ~/.psql_history- :DBNAME

# Agora, cada database terá seu próprio arquivo:
# ~/.psql_history-mydb
# ~/.psql_history-testdb
# ~/.psql_history-proddb
```

### Desabilitar Histórico

```bash
# Opção 1: Variável de ambiente
export HISTFILE=/dev/null  # Linux/Mac
set HISTFILE=NUL           # Windows

# Opção 2: No ~/.psqlrc
\set HISTFILE /dev/null

# Opção 3: Remover arquivo após cada sessão (no ~/.psqlrc)
\set ON_EXIT 'rm ~/.psql_history'
```

### Ignorar Comandos no Histórico

```bash
# No ~/.psqlrc - Não gravar comandos que começam com espaço
\set HISTCONTROL ignorespace

# Uso:
psql> SELECT * FROM clientes;  -- Gravado no histórico
psql>  SELECT * FROM clientes;  -- NÃO gravado (começa com espaço)
```

---

## 🔒 Segurança do .psql_history

### ⚠️ Risco: Senhas em Texto Plano

```sql
-- PERIGO: Senha ficará no histórico!
CREATE USER john WITH PASSWORD 'senha123';

-- Aparecerá em ~/.psql_history:
-- CREATE USER john WITH PASSWORD 'senha123';

-- Qualquer usuário com acesso ao arquivo pode ver a senha!
```

### ✅ Boas Práticas

#### 1. Usar Variáveis de Ambiente

```bash
# Definir senha em variável de ambiente
export PGPASSWORD=senha123

# No psql
CREATE USER john WITH PASSWORD :'PGPASSWORD';

-- No histórico aparecerá:
-- CREATE USER john WITH PASSWORD :'PGPASSWORD';  -- Seguro!
```

#### 2. Usar pgpass File

```bash
# Criar arquivo ~/.pgpass (Linux/Mac) ou %APPDATA%\postgresql\pgpass.conf (Windows)
echo "localhost:5432:*:john:senha123" >> ~/.pgpass
chmod 600 ~/.pgpass  # Permissões restritas!

# Conectar sem senha
psql -U john -d mydb  # Senha lida de ~/.pgpass
```

#### 3. Limpar Histórico Após Comandos Sensíveis

```bash
# Remover histórico manualmente
rm ~/.psql_history

# Ou editar e remover linha específica
nano ~/.psql_history
```

#### 4. Usar \prompt

```sql
-- Solicitar senha interativamente (não aparece no histórico)
\prompt 'Digite a senha: ' senha
CREATE USER john WITH PASSWORD :'senha';

-- No histórico:
-- \prompt 'Digite a senha: ' senha
-- CREATE USER john WITH PASSWORD :'senha';  -- Valor não exposto
```

### Permissões do Arquivo

```bash
# Verificar permissões
ls -l ~/.psql_history

# Deveria ser:
# -rw-------  1 usuario  grupo  12345 Jan 15 10:00 .psql_history
#  ^ somente o dono pode ler/escrever

# Corrigir permissões se necessário
chmod 600 ~/.psql_history
```

---

## 🛠️ Comandos Úteis

### Ver Últimos N Comandos

```bash
# Ver últimos 10 comandos (Linux/Mac)
tail -n 10 ~/.psql_history

# Windows
powershell -Command "Get-Content $env:APPDATA\postgresql\.psql_history | Select-Object -Last 10"
```

### Buscar Comandos Específicos

```bash
# Buscar comandos que contêm "CREATE INDEX"
grep "CREATE INDEX" ~/.psql_history

# Contar quantas vezes executou SELECT
grep -c "^SELECT" ~/.psql_history
```

### Remover Duplicatas

```bash
# Remover comandos duplicados consecutivos (Linux/Mac)
cat ~/.psql_history | uniq > ~/.psql_history.tmp
mv ~/.psql_history.tmp ~/.psql_history
```

### Editar Histórico

```bash
# Abrir em editor
nano ~/.psql_history

# Remover linhas indesejadas, salvar e sair
```

---

## 🎯 Casos de Uso Práticos

### 1. Repetir Comandos Complexos

```sql
-- Você executou ontem:
WITH stats AS (
    SELECT 
        date_trunc('day', created_at) AS dia,
        COUNT(*) AS total,
        AVG(valor) AS media
    FROM pedidos
    WHERE status = 'pago'
    GROUP BY dia
)
SELECT * FROM stats ORDER BY dia DESC LIMIT 30;

-- Hoje, basta pressionar Ctrl+R e digitar "WITH stats"
-- O comando completo aparecerá!
```

### 2. Reutilizar Queries de Debug

```sql
-- Após encontrar um bug, você executou:
SELECT 
    id, 
    status, 
    created_at,
    updated_at
FROM pedidos
WHERE id IN (123, 456, 789)
ORDER BY created_at;

-- Dias depois, para debug similar:
-- Ctrl+R "pedidos WHERE id IN"
-- Ajustar os IDs e executar
```

### 3. Documentar Processo

```sql
-- Salvar histórico de migração
\s /tmp/migracao_2024-01-15.sql

-- Agora você tem documentação automática do que fez:
/*
BEGIN;
ALTER TABLE clientes ADD COLUMN telefone VARCHAR(20);
UPDATE clientes SET telefone = '(11) 0000-0000' WHERE telefone IS NULL;
ALTER TABLE clientes ALTER COLUMN telefone SET NOT NULL;
COMMIT;
*/
```

### 4. Análise de Uso

```bash
# Ver quais tabelas você mais consulta
grep "FROM " ~/.psql_history | awk '{print $NF}' | sort | uniq -c | sort -rn

# Saída exemplo:
#  45 clientes;
#  32 pedidos;
#  18 produtos;
#  12 usuarios;
```

---

## 🔍 Limitações

### ❌ Não é um Sistema de Auditoria

```sql
-- O histórico NÃO registra:
- Comandos executados por outras ferramentas (pgAdmin, DBeaver)
- Comandos executados via JDBC/ODBC/libpq
- Comandos executados por outros usuários
- Data/hora de execução
- Resultado dos comandos

-- Para auditoria real, use:
- pg_stat_statements (queries executadas)
- Logs do PostgreSQL (atividade do servidor)
- Audit triggers (mudanças nos dados)
```

### ❌ Multiline Commands

```sql
-- Comandos multi-linha são salvos como uma única linha:
psql> SELECT *
psql> FROM clientes
psql> WHERE id = 123;

-- No .psql_history aparece:
-- SELECT * FROM clientes WHERE id = 123;
-- (Quebras de linha são removidas)
```

---

## 🎓 Atalhos do psql Úteis

```text
Ctrl+R          Busca reversa no histórico
Ctrl+A          Ir para início da linha
Ctrl+E          Ir para fim da linha
Ctrl+K          Deletar até fim da linha
Ctrl+U          Deletar linha inteira
Ctrl+L          Limpar tela (ou \! clear)
Ctrl+C          Cancelar comando atual
Ctrl+D          Sair do psql (ou \q)

↑ / ↓           Navegar histórico
Alt+<           Ir para primeiro comando do histórico
Alt+>           Ir para último comando do histórico
```

---

## 📝 Arquivo .psqlrc

Configurações personalizadas do psql (similar a ~/.bashrc):

```sql
-- Criar ~/.psqlrc

-- Histórico separado por database
\set HISTFILE ~/.psql_history- :DBNAME

-- Histórico maior
\set HISTSIZE 10000

-- Não gravar comandos duplicados
\set HISTCONTROL ignoredups

-- Não gravar comandos que começam com espaço
\set HISTCONTROL ignorespace

-- Prompt customizado mostrando database e user
\set PROMPT1 '%n@%/%R%# '

-- Timing automático de queries
\timing

-- Formato de saída melhorado
\pset border 2
\pset format wrapped

-- Pager automático
\pset pager always

-- Mensagem de boas-vindas
\echo 'Bem-vindo ao PostgreSQL! Histórico habilitado.'
```

---

## 🔗 Navegação

⬅️ [Voltar ao Índice: History and Auditing](./README.md) | [Próximo: pg_stat_statements →](./02-pg-stat-statements.md)

---

## 📝 Resumo Rápido

```bash
# Localização
~/.psql_history  # Linux/Mac
%APPDATA%\postgresql\.psql_history  # Windows

# Comandos úteis
\s                           # Mostrar histórico
\s /tmp/historico.sql        # Salvar histórico
Ctrl+R                       # Buscar no histórico
↑ / ↓                        # Navegar histórico

# Segurança
chmod 600 ~/.psql_history    # Permissões restritas
\set HISTFILE /dev/null      # Desabilitar histórico
\prompt 'Senha: ' senha      # Senha sem expor no histórico

# Configuração (~/.psqlrc)
\set HISTFILE ~/.psql_history- :DBNAME   # Histórico por DB
\set HISTSIZE 10000                       # Tamanho do histórico
\set HISTCONTROL ignoredups               # Ignorar duplicatas
```
