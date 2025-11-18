# Exercícios - Schemas e Organização de Dados

## 🎯 Instruções

- Crie um database de teste para praticar
- Execute os exercícios em ordem
- Tente resolver sem consultar o gabarito
- Confira suas respostas em [gabarito-exercicios.md](./gabarito-exercicios.md)

```sql
-- Criar database de teste
CREATE DATABASE exercicios_schemas;
\c exercicios_schemas
```

---

## 📚 Exercício 1: Criando Schemas Básicos

Crie três schemas para um sistema de e-commerce:
- `vendas` - para dados de vendas e clientes
- `estoque` - para controle de inventário
- `financeiro` - para dados financeiros

Depois, liste todos os schemas do database (excluindo schemas do sistema).

---

## 📚 Exercício 2: Criando Tabelas em Schemas Específicos

No schema `vendas`, crie:
- Tabela `clientes` (id, nome, email)
- Tabela `pedidos` (id, cliente_id, data_pedido, total)

No schema `estoque`, crie:
- Tabela `produtos` (id, nome, quantidade, preco)

Insira dados de exemplo em cada tabela.

---

## 📚 Exercício 3: Referências Entre Schemas

Crie a tabela `vendas.itens_pedido` que referencia:
- `vendas.pedidos` (pedido_id)
- `estoque.produtos` (produto_id)

Insira alguns itens de pedido e verifique as foreign keys funcionando.

---

## 📚 Exercício 4: Search Path Básico

a) Verifique o search_path atual  
b) Configure o search_path para: `vendas, estoque, public`  
c) Consulte a tabela `clientes` sem especificar o schema  
d) Consulte a tabela `produtos` sem especificar o schema  
e) Resete o search_path ao padrão  

---

## 📚 Exercício 5: Ambiguidade de Nomes

Crie uma tabela chamada `logs` em dois schemas diferentes:
- `vendas.logs` com colunas (id, acao, usuario)
- `estoque.logs` com colunas (id, acao, produto_id)

Configure diferentes search_paths e observe qual tabela é acessada quando você faz `SELECT * FROM logs;`

---

## 📚 Exercício 6: Movendo Objetos Entre Schemas

a) Crie um schema `temp_importacao`  
b) Crie uma tabela `temp_importacao.novos_produtos`  
c) Insira alguns produtos nela  
d) Mova a tabela para o schema `estoque`  
e) Verifique que a tabela agora está em `estoque`  

---

## 📚 Exercício 7: Renomeando Schemas

a) Crie um schema chamado `temp_vendas`  
b) Crie algumas tabelas nele  
c) Renomeie o schema para `vendas_backup`  
d) Verifique que as tabelas ainda estão acessíveis  

---

## 📚 Exercício 8: Excluindo Schemas

a) Crie um schema `teste_delete`  
b) Crie uma tabela dentro dele  
c) Tente excluir o schema sem CASCADE (deve dar erro)  
d) Exclua o schema usando CASCADE  
e) Confirme que foi excluído  

---

## 📚 Exercício 9: Permissões - Usuário Somente Leitura

Crie um usuário `relatorio_user` que pode:
- Conectar ao database
- Acessar o schema `vendas` (USAGE)
- Fazer SELECT em todas as tabelas de `vendas`
- NÃO pode inserir, atualizar ou deletar

Teste conectando como esse usuário.

---

## 📚 Exercício 10: Permissões - Usuário com Escrita

Crie um usuário `app_user` que pode:
- Conectar ao database
- Acessar schemas `vendas` e `estoque`
- SELECT, INSERT, UPDATE, DELETE em todas as tabelas
- Usar sequences (para campos SERIAL)

Teste as permissões.

---

## 📚 Exercício 11: DEFAULT PRIVILEGES

Configure DEFAULT PRIVILEGES para que todas as tabelas **futuras** criadas no schema `vendas` sejam automaticamente acessíveis (SELECT) pelo usuário `relatorio_user`.

Crie uma nova tabela e verifique que `relatorio_user` já tem acesso.

---

## 📚 Exercício 12: Multi-tenant - Schema por Cliente

Implemente um cenário multi-tenant:

a) Crie schemas: `cliente_acme`, `cliente_tech`, `cliente_global`  
b) Em cada schema, crie a mesma estrutura de tabelas:
   - `usuarios` (id, nome, email)
   - `documentos` (id, titulo, conteudo, usuario_id)  
c) Insira dados diferentes em cada cliente  
d) Crie uma view que une dados de todos os clientes (para admin)  

---

## 📚 Exercício 13: Search Path por Usuário

a) Crie usuário `usuario_vendas`  
b) Configure search_path permanente para esse usuário: `vendas, public`  
c) Conecte como esse usuário e verifique que o search_path está correto  
d) Demonstre que queries sem schema especificado usam `vendas` primeiro  

---

## 📚 Exercício 14: Consultando Metadados

Escreva queries para:

a) Listar todos os schemas não-sistema com seus donos  
b) Listar todas as tabelas no schema `vendas`  
c) Calcular o tamanho total (em MB) de todas as tabelas em `vendas`  
d) Listar todas as foreign keys que cruzam schemas  

---

## 📚 Exercício 15: Schema de Auditoria

Crie um schema `audit` separado:

a) Criar schema `audit` acessível apenas por admins  
b) Criar tabela `audit.log_alteracoes` (timestamp, usuario, schema, tabela, acao, dados_json)  
c) Criar trigger que registra INSERT/UPDATE/DELETE em `vendas.pedidos`  
d) Testar fazendo operações e verificando o log  

---

## 📚 Exercício 16: Ambientes - Dev/Staging/Prod

Simule múltiplos ambientes no mesmo database:

a) Criar schemas: `dev`, `staging`, `prod`  
b) Criar mesma estrutura de tabelas em cada  
c) Popular `prod` com dados reais  
d) Copiar estrutura e dados de `prod` para `staging`  
e) Criar view que mostra qual ambiente tem mais registros  

---

## 📚 Exercício 17: Security - Isolamento Total

Configure isolamento completo entre dois schemas:

a) Criar `projeto_a` e `projeto_b`  
b) Criar usuários `user_a` e `user_b`  
c) Garantir que `user_a` só acessa `projeto_a`  
d) Garantir que `user_b` só acessa `projeto_b`  
e) Revogar acesso ao schema `public` de ambos  
f) Testar tentando acessar schema errado (deve falhar)  

---

## 📚 Exercício 18: Performance - Search Path

Compare performance:

a) Criar tabela com 100.000 registros em `vendas.teste_perf`  
b) Adicionar índice na coluna de busca  
c) Executar query COM schema qualificado: `SELECT * FROM vendas.teste_perf WHERE id = 50000`  
d) Executar query SEM schema (via search_path): `SELECT * FROM teste_perf WHERE id = 50000`  
e) Usar EXPLAIN ANALYZE para comparar  

---

## 📚 Exercício 19: Dependency Tracking

a) Crie uma view `vendas.vw_pedidos_completos` que junta `pedidos`, `clientes` e `itens_pedido`  
b) Tente excluir a tabela `vendas.pedidos` (deve falhar por dependência)  
c) Liste todas as dependências da tabela `vendas.pedidos`  
d) Exclua a view primeiro, depois a tabela  

---

## 📚 Exercício 20: Schema de Configuração Compartilhado

Crie um schema `config` para dados compartilhados:

a) Criar schema `config`  
b) Criar tabelas:
   - `config.parametros` (chave, valor, descricao)
   - `config.feriados` (data, descricao)  
c) Popular com dados  
d) Configurar permissões: todos podem ler, só admin pode escrever  
e) Adicionar `config` ao search_path de todos os usuários  

---

## 📚 Exercício 21: Migrando Schema Único para Multi-Schema

Você tem tudo no schema `public`. Migre para arquitetura organizada:

a) Criar schemas organizados por domínio  
b) Identificar tabelas e agrupá-las logicamente  
c) Mover tabelas para schemas apropriados  
d) Atualizar foreign keys se necessário  
e) Atualizar views e functions  
f) Ajustar permissões  

---

## 📚 Exercício 22: Schema Temporário para ETL

Implemente um pipeline de ETL usando schemas:

a) Criar schema `etl_staging` para dados brutos  
b) Criar schema `etl_processing` para transformações  
c) Criar schema `etl_production` para dados finais  
d) Simular importação de dados → staging  
e) Processar/limpar dados → processing  
f) Validar e mover → production  
g) Limpar staging e processing  

---

## 📚 Exercício 23: Roles e Hierarquia de Schemas

Configure hierarquia de roles:

a) Criar role `readonly_role` (apenas SELECT)  
b) Criar role `readwrite_role` que herda `readonly_role` + INSERT/UPDATE/DELETE  
c) Criar role `admin_role` que herda `readwrite_role` + CREATE  
d) Atribuir roles a usuários  
e) Testar cada nível de acesso  

---

## 📚 Exercício 24: Documentando Schema

Crie documentação estruturada do schema:

a) Usar COMMENT ON para documentar:
   - Schemas (propósito)
   - Tabelas (descrição)
   - Colunas (significado)  
b) Criar query que gera documentação HTML/Markdown  
c) Exportar estrutura completa com comentários  

---

## 📚 Exercício 25: Desafio Final - Sistema Completo

Implemente um sistema completo de gestão escolar:

**Requisitos:**
- Schema `academico` (alunos, turmas, disciplinas)
- Schema `financeiro` (mensalidades, pagamentos)
- Schema `biblioteca` (livros, empréstimos)
- Schema `rh` (professores, funcionários)
- Schema `config` (parâmetros do sistema)
- Schema `audit` (logs de todas as operações)

**Implementar:**
1. Estrutura completa de tabelas com relacionamentos
2. Pelo menos 3 foreign keys entre schemas diferentes
3. Sistema de permissões (aluno, professor, admin, financeiro)
4. Search path apropriado para cada tipo de usuário
5. 5 views úteis (ex: alunos inadimplentes, livros disponíveis)
6. Triggers de auditoria em operações críticas
7. Dados de exemplo realistas
8. Queries de relatório (3 exemplos)

---

## 🎓 Conclusão

Após completar estes exercícios, você deve estar confortável com:

✅ Criar e gerenciar schemas eficientemente  
✅ Configurar search_path adequadamente  
✅ Implementar controle de acesso granular  
✅ Organizar databases complexos  
✅ Implementar arquiteturas multi-tenant  
✅ Aplicar boas práticas de segurança  
✅ Mover e reorganizar estruturas  
✅ Usar schemas para ambientes diferentes  

---

## 🔗 Navegação

[← Voltar para Aulas](./01-introducao-schemas.md) | [Ver Gabarito →](./gabarito-exercicios.md)

---

## 💡 Dicas

- Use `\dn+` no psql para ver schemas com detalhes
- Use `\dt schema_name.*` para listar tabelas de um schema
- Use `\du` para ver roles/usuários
- Use `\dp` ou `\z` para ver permissões de tabelas
- EXPLAIN ANALYZE suas queries para verificar performance
