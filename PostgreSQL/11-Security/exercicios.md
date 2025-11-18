# Exercícios - Security (Segurança)

## 📚 Instruções

- Resolva os exercícios em ordem (começam fáceis, ficam mais complexos)
- Teste suas soluções em um banco PostgreSQL
- Respostas detalhadas no arquivo [gabarito-exercicios.md](./gabarito-exercicios.md)
- Tempo estimado: 3-4 horas

---

## 🟢 Nível Básico - Roles e Permissões

### Exercício 1: Criar Hierarchy de Roles
Crie uma estrutura de roles para um sistema de biblioteca:
- `bibliotecario`: pode fazer tudo (SELECT, INSERT, UPDATE, DELETE)
- `atendente`: pode ver e adicionar empréstimos, mas não deletar
- `leitor`: pode apenas ver o catálogo de livros

Crie usuários que herdam desses roles.

---

### Exercício 2: DEFAULT PRIVILEGES
Configure DEFAULT PRIVILEGES para que:
- Todo objeto criado pelo role `admin_role` automaticamente conceda SELECT ao role `app_readonly`
- Todo objeto criado conceda INSERT, UPDATE ao role `app_writer`

---

### Exercício 3: Auditoria de Permissões
Escreva uma query que liste:
- Todos os roles existentes
- Quais roles cada usuário pertence (membership)
- Quais permissões de tabela cada role tem

---

## 🟡 Nível Intermediário - Row Level Security

### Exercício 4: RLS Básico
Crie uma tabela `documentos` com RLS onde:
- Cada usuário vê apenas documentos onde `dono = current_user`
- Usuários só podem inserir documentos com eles mesmos como dono

Teste com 3 usuários diferentes.

---

### Exercício 5: Multi-tenancy com RLS
Implemente um sistema multi-tenant para `pedidos`:
- Use `tenant_id` para separação
- Policy deve usar `current_setting('app.current_tenant')`
- Crie função helper `set_tenant(tenant_id INT)`
- Garanta que usuários NÃO podem inserir dados de outro tenant

---

### Exercício 6: RLS com Hierarquia
Tabela `tarefas` com campos `responsavel` e `gerente_id`:
- Usuários veem suas próprias tarefas
- Gerentes veem tarefas de sua equipe
- Role `rh_role` vê todas as tarefas

---

## 🟠 Nível Intermediário-Avançado - Column Security

### Exercício 7: GRANT por Coluna
Tabela `funcionarios` com `nome`, `cargo`, `salario`, `cpf`:
- Role `publico`: vê apenas `nome` e `cargo`
- Role `rh`: vê tudo
- Role `gerente`: vê tudo exceto `cpf`

---

### Exercício 8: Views com Mascaramento
Crie view `funcionarios_masked` que:
- CPF exibido como `***.***.***-XX` (apenas últimos 2 dígitos)
- Salário exibido como faixa (`<3000`, `3000-6000`, `>6000`)
- Telefone mascarado como `(**) ****-XXXX`

---

### Exercício 9: Mascaramento Dinâmico por Role
View `clientes_view` que mostra dados diferentes baseado no role:
- `vendedor_role`: vê nome, email, telefone (sem CPF)
- `financeiro_role`: vê tudo, incluindo CPF completo
- `marketing_role`: vê nome, email (CPF mascarado, sem telefone)

---

## 🔴 Nível Avançado - Auditoria

### Exercício 10: Audit Table Simples
Crie tabela `produtos` e `produtos_audit` que registre:
- Operação (INSERT, UPDATE, DELETE)
- Usuário que executou
- Data/hora
- Valores antigos e novos (para UPDATE)

Implemente com triggers.

---

### Exercício 11: Audit Table Genérica (JSON)
Crie sistema de auditoria genérico que:
- Usa uma tabela `audit_log` com campos JSONB
- Função `audit_trigger_func()` que funciona para qualquer tabela
- Registra IP do cliente (`inet_client_addr()`)
- Pode ser aplicado a múltiplas tabelas

---

### Exercício 12: Auditoria de Acesso a Dados Sensíveis
Implemente logging de acesso para compliance LGPD:
- Tabela `acesso_dados_pessoais` que registra quando alguém consulta dados de CPF
- Trigger ou view que automaticamente registra acesso
- Include: quem acessou, quando, IP, finalidade

---

## 🔴 Nível Avançado - Compliance

### Exercício 13: Encriptação com pgcrypto
Tabela `cartoes_credito`:
- Número do cartão encriptado com `pgp_sym_encrypt`
- Função `get_card_number(card_id, senha)` para decriptar
- Sempre auditar tentativas de acesso
- Apenas role `payment_admin` pode decriptar

---

### Exercício 14: Direito ao Esquecimento (LGPD)
Implemente função `anonimizar_usuario(usuario_id)` que:
- Substitui dados pessoais por valores genéricos
- Mantém ID para integridade referencial
- Registra anonimização em tabela de audit
- NÃO pode ser revertido

---

### Exercício 15: Event Trigger para DDL Audit (SOX)
Crie auditoria de mudanças de schema:
- Tabela `ddl_audit` que registra CREATE, ALTER, DROP
- Event trigger que captura todos os comandos DDL
- Include: usuário, comando, objeto, timestamp
- Impedir alteração/deleção de registros de audit

---

## 🟣 Nível Expert - Integração Completa

### Exercício 16: Sistema Multi-tenant Completo
Sistema SaaS com 3 schemas (`tenant_a`, `tenant_b`, `tenant_c`):
- Cada tenant tem tabelas `users`, `orders`, `products`
- RLS para isolamento de dados
- Roles: `tenant_admin`, `tenant_user`, `tenant_readonly`
- DEFAULT PRIVILEGES configurados
- Função para provisionar novo tenant

---

### Exercício 17: Segurança em Camadas
Tabela `transacoes_financeiras` com múltiplas camadas:
1. RLS: usuários veem apenas transações de seu departamento
2. Column security: campo `valor` visível apenas para `financeiro_role`
3. Row security + Column: gerentes veem valores de sua equipe
4. Auditoria: logar todos os acessos
5. Encriptação: campo `conta_bancaria` encriptado

---

### Exercício 18: Policy Complexa com Hierarquia
Tabela `projetos` com campos:
- `dono_id`, `departamento_id`, `confidencial BOOLEAN`
- Policies:
  - Donos veem seus projetos
  - Membros do departamento veem projetos não-confidenciais
  - Diretores veem todos os projetos de seu departamento
  - C-level vê tudo
- Implemente com múltiplas policies combinadas

---

### Exercício 19: Audit com Retenção e Arquivamento
Sistema de auditoria enterprise:
- Tabela `audit_log` particionada por mês
- Trigger que automaticamente cria novas partições
- Função para arquivar partições antigas (>1 ano) para tabela `audit_archive`
- View `audit_recent` que mostra apenas últimos 90 dias
- Impedir UPDATE/DELETE em audit tables

---

### Exercício 20: Alerta de Segurança em Tempo Real
Sistema de detecção de anomalias:
- Tabela `alertas_seguranca`
- Trigger que detecta:
  - Múltiplas tentativas de acesso negado (>5 em 1 minuto)
  - Acesso fora do horário (22h-6h)
  - Queries que retornam muito dados (>1000 rows)
  - Usuário acessando dados de outro tenant
- Usar `pg_notify` para alertas em tempo real

---

## 🎯 Projeto Final: Sistema Bancário Seguro

Implemente um mini-sistema bancário com **máxima segurança**:

### Requisitos:

1. **Estrutura**:
   - Tabelas: `clientes`, `contas`, `transacoes`, `cartoes`
   - Schemas separados: `producao`, `auditoria`, `compliance`

2. **Roles**:
   - `gerente_agencia`: CRUD em clientes e contas
   - `caixa`: registra transações, consulta saldos
   - `auditoria_interna`: leitura de tudo + audit logs
   - `compliance_officer`: acesso a dados de compliance

3. **Segurança**:
   - RLS: caixas veem apenas clientes de sua agência (`agencia_id`)
   - Column security: `cpf`, `renda_mensal` apenas para gerentes
   - Encriptação: número do cartão e CVV encriptados
   - Mascaramento: views para call center mostram dados parciais

4. **Auditoria**:
   - Todas as transações auditadas (quem, quando, quanto)
   - Acesso a dados de cartão sempre registrado
   - DDL audit para mudanças de schema
   - Logs retidos por 7 anos

5. **Compliance**:
   - LGPD: consentimentos registrados, direito ao esquecimento
   - PCI-DSS: cartões encriptados, acesso controlado
   - Função `anonimizar_cliente(cliente_id)`
   - Relatório de acessos a dados pessoais

6. **Alertas**:
   - Transação acima de R$ 50.000
   - Múltiplas tentativas de acesso a cartões
   - Acesso fora do horário bancário

### Entregáveis:
- Script DDL completo
- Funções e triggers
- Policies
- Views de segurança
- Testes demonstrando isolamento

---

## 📝 Checklist de Conclusão

Ao terminar, você deve ser capaz de:

- [ ] Criar hierarquias de roles com INHERIT
- [ ] Configurar DEFAULT PRIVILEGES
- [ ] Implementar RLS para multi-tenancy
- [ ] Aplicar GRANT em nível de coluna
- [ ] Criar views com mascaramento de dados
- [ ] Encriptar dados sensíveis com pgcrypto
- [ ] Implementar audit tables com triggers
- [ ] Criar sistema genérico de auditoria
- [ ] Implementar compliance LGPD/GDPR
- [ ] Configurar event triggers para DDL audit
- [ ] Combinar RLS + Column Security
- [ ] Particionar tabelas de audit
- [ ] Criar alertas de segurança automáticos
- [ ] Desenhar arquitetura de segurança completa

---

**Próximo passo**: Confira as soluções detalhadas no [gabarito-exercicios.md](./gabarito-exercicios.md)!

⬅️ [Voltar ao README do módulo](./README.md)
