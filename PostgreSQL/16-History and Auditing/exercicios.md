# Exercícios - History and Auditing

## 🎯 Objetivo

Praticar os conceitos de história, auditoria e versionamento no PostgreSQL através de exercícios progressivos.

---

## 📝 Exercício 1: Configurando .psql_history

**Nível**: Básico

Configure o psql para:
1. Manter histórico separado por database
2. Não gravar comandos que começam com espaço
3. Aumentar o tamanho do histórico para 5000 comandos

---

## 📝 Exercício 2: pg_stat_statements Básico

**Nível**: Básico

1. Instale e configure pg_stat_statements
2. Execute 10 queries diferentes na database
3. Liste as top 5 queries mais executadas

---

## 📝 Exercício 3: Identificando Queries Lentas

**Nível**: Intermediário

Use pg_stat_statements para:
1. Encontrar queries com tempo médio > 100ms
2. Encontrar queries com alta variabilidade (max_time / mean_time > 10)
3. Criar uma view `slow_queries` que mostre essas informações

---

## 📝 Exercício 4: Configurando Logs

**Nível**: Intermediário

Configure o PostgreSQL para:
1. Logar todas as conexões e desconexões
2. Logar apenas queries que levam mais de 500ms
3. Logar todos os comandos DDL (CREATE, ALTER, DROP)
4. Incluir usuário, database, aplicação e IP no log

---

## 📝 Exercício 5: Analisando Logs

**Nível**: Intermediário

Dado um arquivo de log do PostgreSQL:
1. Contar quantos erros ocorreram
2. Listar as top 5 queries mais lentas
3. Listar quantas conexões foram feitas por cada usuário

---

## 📝 Exercício 6: Audit Table Simples

**Nível**: Básico

Crie uma tabela `produtos` com colunas `id`, `nome`, `preco`.

Implemente auditoria usando o padrão de **tabela espelho**:
1. Criar `produtos_audit`
2. Criar triggers para INSERT, UPDATE, DELETE
3. Testar com operações CRUD

---

## 📝 Exercício 7: Audit Table Genérica (JSONB)

**Nível**: Intermediário

Implemente uma tabela de auditoria genérica:
1. Criar tabela `audit_log` com JSONB
2. Criar função de trigger reutilizável
3. Aplicar a 3 tabelas diferentes
4. Consultar histórico de uma tabela específica

---

## 📝 Exercício 8: Metadados de Auditoria

**Nível**: Intermediário

Modifique a função de auditoria para capturar:
1. IP do cliente (`inet_client_addr()`)
2. Application name (`current_setting('application_name')`)
3. Transaction ID (`txid_current()`)

Teste conectando de diferentes IPs e aplicações.

---

## 📝 Exercício 9: Protegendo Audit Tables

**Nível**: Intermediário

Implemente proteção para tabela de auditoria:
1. Revogar permissões UPDATE/DELETE
2. Criar trigger que bloqueia UPDATE/DELETE
3. Testar tentando modificar registros de auditoria

---

## 📝 Exercício 10: Temporal Tables Básico

**Nível**: Intermediário

Crie uma tabela `preco_produtos` com versionamento temporal:
1. Tabela principal com `id`, `produto`, `preco`
2. Tabela histórico `preco_produtos_history` com `valid_from`, `valid_to`
3. Trigger que automaticamente move versões antigas para histórico
4. View que mostra apenas versões atuais

---

## 📝 Exercício 11: Point-in-Time Queries

**Nível**: Avançado

Implemente função `get_as_of(tabela, timestamp)` que:
1. Retorna o estado da tabela em um momento específico no passado
2. Consulta a tabela histórico com `valid_from` e `valid_to`
3. Teste com várias mudanças de preço

---

## 📝 Exercício 12: Bi-Temporal Table

**Nível**: Avançado

Crie uma tabela bi-temporal para contratos:
1. `transaction_time` (quando foi registrado no banco)
2. `valid_time` (quando o contrato é válido no mundo real)
3. Implemente triggers para manter ambas as dimensões
4. Query: "Que contratos eram válidos em 2023-06-01 segundo o conhecimento de 2023-12-31?"

---

## 📝 Exercício 13: Slowly Changing Dimension (SCD Type 2)

**Nível**: Avançado

Implemente SCD Type 2 para tabela `clientes`:
1. Colunas: `id`, `nome`, `endereco`, `valid_from`, `valid_to`, `is_current`
2. Trigger que ao UPDATE cria nova versão (não sobrescreve)
3. View `clientes_atuais` que mostra apenas `is_current = true`
4. Função para buscar histórico de um cliente

---

## 📝 Exercício 14: Analisando MVCC

**Nível**: Intermediário

Use colunas ocultas `xmin`, `xmax`, `ctid` para:
1. Ver transaction IDs de tuplas
2. Gerar dead tuples com múltiplos UPDATEs
3. Contar dead tuples com `pg_stat_user_tables`
4. Executar VACUUM e verificar resultado

---

## 📝 Exercício 15: Monitorando Bloat

**Nível**: Avançado

Crie view `bloat_monitor` que mostra:
1. Nome da tabela
2. Tamanho total
3. Número de live tuples e dead tuples
4. Percentual de dead tuples
5. Última vez que VACUUM rodou

Identifique tabelas com >20% de dead tuples.

---

## 📝 Exercício 16: Configurando Autovacuum

**Nível**: Intermediário

Para uma tabela com muitos UPDATEs:
1. Ajustar `autovacuum_vacuum_scale_factor` para 5%
2. Ajustar `autovacuum_vacuum_threshold` para 100
3. Simular carga (1000 UPDATEs)
4. Verificar quando autovacuum rodou

---

## 📝 Exercício 17: Transaction Age

**Nível**: Intermediário

Monitore transaction age:
1. Consultar `pg_database` para ver `age(datfrozenxid)`
2. Calcular quantas transações faltam para wraparound
3. Criar alerta se age > 1.5 bilhões
4. Executar VACUUM FREEZE manualmente

---

## 📝 Exercício 18: WAL Archiving

**Nível**: Avançado

Configure WAL archiving:
1. Habilitar `archive_mode`
2. Configurar `archive_command` para copiar para `/backup/wal-archive/`
3. Verificar status com `pg_stat_archiver`
4. Gerar WAL com transações e verificar arquivamento

---

## 📝 Exercício 19: pg_waldump

**Nível**: Avançado

Use `pg_waldump` para:
1. Ver conteúdo de um segmento WAL
2. Filtrar por transaction ID específico
3. Filtrar por tipo de operação (Heap, Btree, Transaction)
4. Gerar estatísticas de uso de WAL

---

## 📝 Exercício 20: Point-in-Time Recovery (PITR)

**Nível**: Avançado

Simule PITR:
1. Fazer base backup com `pg_basebackup`
2. Executar transações (INSERT, UPDATE, DELETE)
3. Simular desastre (DROP TABLE)
4. Restaurar backup e aplicar WAL até antes do DROP
5. Verificar que tabela foi recuperada

---

## 🎓 Exercício Final: Sistema Completo de Auditoria

**Nível**: Avançado

Implemente sistema completo de auditoria para aplicação de e-commerce:

### Requisitos:

1. **Audit Triggers**:
   - Tabelas auditadas: `clientes`, `pedidos`, `produtos`, `pagamentos`
   - Capturar: usuário, timestamp, IP, application name, OLD/NEW values

2. **Temporal Tables**:
   - Versionamento de preços de produtos
   - Histórico de status de pedidos
   - Point-in-time queries

3. **Logs**:
   - Logar conexões
   - Logar queries >1s
   - Logar DDL

4. **Monitoramento**:
   - View para top queries lentas (pg_stat_statements)
   - View para bloat de tabelas (MVCC)
   - Alertas para dead tuples >20%

5. **Compliance**:
   - LGPD: Registrar acessos a dados pessoais
   - LGPD: Função para anonimizar cliente (direito ao esquecimento)
   - Proteção de audit tables (não podem ser alteradas)

6. **Backup e Recovery**:
   - WAL archiving configurado
   - Restore points antes de deployments
   - Documentar processo de PITR

---

## 🔗 Navegação

⬅️ [Voltar ao Índice: History and Auditing](./README.md) | [Ver Gabarito →](./gabarito-exercicios.md)
