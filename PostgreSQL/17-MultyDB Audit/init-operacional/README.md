# 🗄️ Banco Operacional - Setup de Auditoria

Scripts para configurar o sistema de auditoria no **banco operacional** (onde rodam as transações do dia a dia).

## 📋 Ordem de Execução

Execute os scripts na ordem numérica:

### 1️⃣ Componentes Básicos

| # | Script | Descrição | Tempo |
|---|--------|-----------|-------|
| 01 | `01-criar-tabela-audit-log.sql` | Cria tabela centralizada de auditoria | ~1s |
| 02 | `02-criar-indices.sql` | Cria índices para performance | ~2s |
| 03 | `03-criar-funcao-trigger.sql` | Função que captura INSERT/UPDATE/DELETE | ~1s |

### 2️⃣ Helpers (Facilita o Uso)

| # | Script | Descrição | Tempo |
|---|--------|-----------|-------|
| 04 | `04-criar-helper-enable-audit.sql` | Função para ativar auditoria com 1 linha | ~1s |
| 05 | `05-criar-helper-disable-audit.sql` | Função para desativar auditoria | ~1s |
| 06 | `06-criar-view-tabelas-auditadas.sql` | View que mostra tabelas auditadas | ~1s |

### 3️⃣ Segurança

| # | Script | Descrição | Tempo |
|---|--------|-----------|-------|
| 07 | `07-criar-permissoes-restritivas.sql` | Configura permissões (apenas INSERT/SELECT) | ~1s |
| 08 | `08-criar-trigger-protecao.sql` | Bloqueia UPDATE/DELETE na auditoria | ~1s |

## 🚀 Setup Rápido (Executar Tudo)

```bash
# No terminal (Linux/Mac)
for file in *.sql; do
    echo "Executando $file..."
    psql -d seu_banco -f "$file"
done

# No Windows PowerShell
Get-ChildItem *.sql | ForEach-Object {
    Write-Host "Executando $($_.Name)..."
    psql -d seu_banco -f $_.FullName
}

# Ou manualmente no psql
\i 01-criar-tabela-audit-log.sql
\i 02-criar-indices.sql
\i 03-criar-funcao-trigger.sql
\i 04-criar-helper-enable-audit.sql
\i 05-criar-helper-disable-audit.sql
\i 06-criar-view-tabelas-auditadas.sql
\i 07-criar-permissoes-restritivas.sql
\i 08-criar-trigger-protecao.sql
```

## 📖 Como Usar Após o Setup

### Ativar Auditoria em Uma Tabela

```sql
-- Ativar auditoria (1 LINHA!)
SELECT enable_audit('users');
SELECT enable_audit('pedidos');
SELECT enable_audit('produtos');
```

### Verificar Tabelas Auditadas

```sql
-- Ver todas as tabelas com auditoria ativa
SELECT * FROM tabelas_auditadas;
```

### Consultar Logs

```sql
-- Ver últimas mudanças
SELECT 
    id,
    tabela,
    operacao,
    usuario,
    data_hora,
    dados_novos
FROM audit_log
ORDER BY data_hora DESC
LIMIT 100;

-- Ver mudanças de uma tabela específica
SELECT * FROM audit_log 
WHERE tabela = 'users'
ORDER BY data_hora DESC;
```

### Desativar Auditoria (Se Necessário)

```sql
-- Desativar auditoria de uma tabela
SELECT disable_audit('users');
```

## ⚠️ Ajustes Necessários

### Script 07 - Permissões

Edite o arquivo `07-criar-permissoes-restritivas.sql` e ajuste os **roles** conforme seu ambiente:

```sql
-- Descobrir seus roles
SELECT rolname FROM pg_roles WHERE rolcanlogin ORDER BY rolname;

-- Ajustar os GRANTs no script 07
GRANT INSERT ON audit_log TO seu_app_user;
GRANT SELECT ON audit_log TO seu_auditor_role;
```

## 🧪 Teste Completo

```sql
-- 1. Criar tabela de teste
CREATE TABLE teste_audit (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    valor NUMERIC(10,2)
);

-- 2. Ativar auditoria
SELECT enable_audit('teste_audit');

-- 3. Fazer operações
INSERT INTO teste_audit (nome, valor) VALUES ('Item 1', 100.00);
UPDATE teste_audit SET valor = 150.00 WHERE id = 1;
DELETE FROM teste_audit WHERE id = 1;

-- 4. Verificar logs
SELECT 
    operacao,
    dados_antigos,
    dados_novos
FROM audit_log 
WHERE tabela = 'teste_audit'
ORDER BY data_hora;

-- 5. Verificar proteção (deve falhar)
UPDATE audit_log SET operacao = 'X' WHERE id = 1;  -- ❌ Erro esperado!
```

## 📊 Monitoramento

```sql
-- Estatísticas por tabela
SELECT * FROM tabelas_auditadas;

-- Total de logs por tabela
SELECT 
    tabela,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE operacao = 'I') as inserts,
    COUNT(*) FILTER (WHERE operacao = 'U') as updates,
    COUNT(*) FILTER (WHERE operacao = 'D') as deletes
FROM audit_log
GROUP BY tabela
ORDER BY total DESC;

-- Tamanho da tabela de auditoria
SELECT 
    pg_size_pretty(pg_total_relation_size('audit_log')) as tamanho_total,
    pg_size_pretty(pg_relation_size('audit_log')) as tamanho_tabela,
    pg_size_pretty(pg_indexes_size('audit_log')) as tamanho_indices;
```

## 🎯 Próximos Passos

Após configurar o banco operacional, você pode:

1. **Manter tudo local**: Os logs ficam no mesmo banco (simples)
2. **Migrar para TimescaleDB**: Adicionar compressão para retenção longa
3. **Separar banco de auditoria**: Usar fila assíncrona para alto volume

Veja a pasta `../Audit/` para scripts de setup do banco de auditoria separado.

## 📝 Notas

- ✅ **Compatível com ALTER TABLE**: Adicionar colunas funciona automaticamente
- ✅ **Zero overhead de manutenção**: Basta ativar com `enable_audit()`
- ✅ **Imutável**: Logs não podem ser alterados/deletados
- ✅ **Portável**: SQL puro, funciona em qualquer PostgreSQL 12+

## 🆘 Troubleshooting

### Erro: "relation audit_log does not exist"
Execute o script `01-criar-tabela-audit-log.sql` primeiro.

### Erro: "function audit_trigger_func() does not exist"
Execute o script `03-criar-funcao-trigger.sql`.

### Erro de permissão ao ativar auditoria
Você precisa de privilégios para criar triggers. Use um usuário com permissões adequadas.

### Logs não aparecem
Verifique se o trigger foi criado:
```sql
SELECT * FROM tabelas_auditadas;
```
