# Exercícios - Data Types

## 🎯 Instruções

- Crie um database de teste para praticar
- Execute os exercícios em ordem
- Tente resolver sem consultar o gabarito
- Confira suas respostas em [gabarito-exercicios.md](./gabarito-exercicios.md)

```sql
-- Criar database de teste
CREATE DATABASE exercicios_datatypes;
\c exercicios_datatypes
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

---

## 📚 Exercíc

io 1: SERIAL vs UUID

Crie duas tabelas para armazenar clientes: uma usando SERIAL e outra usando UUID. Insira 3 registros em cada e compare os IDs gerados.

**Tarefas:**
a) Criar tabela `clientes_serial` com ID SERIAL  
b) Criar tabela `clientes_uuid` com ID UUID  
c) Inserir 3 clientes em cada  
d) Consultar e comparar os IDs  

---

## 📚 Exercício 2: IDENTITY

Crie uma tabela `produtos` usando `GENERATED ALWAYS AS IDENTITY` começando em 1000. Tente inserir um produto especificando o ID manualmente e observe o erro. Depois crie outra tabela usando `BY DEFAULT` e teste novamente.

---

## 📚 Exercício 3: Timestamps com Timezone

Crie uma tabela `eventos_globais` que armazene eventos com timestamp. Insira eventos em diferentes timezones e depois consulte todos convertendo para horário de Brasília.

**Exemplo de dados:**
- Evento em Nova York: 2025-11-18 10:00:00-05
- Evento em Tóquio: 2025-11-18 23:00:00+09
- Evento em Londres: 2025-11-18 15:00:00+00

---

## 📚 Exercício 4: Operações com Datas

Usando a tabela de eventos do exercício anterior:

a) Calcule quantos dias se passaram desde cada evento até hoje  
b) Liste eventos que ocorreram na última semana  
c) Extraia o dia da semana de cada evento (em português se possível)  
d) Calcule a diferença em horas entre o primeiro e o último evento  

---

## 📚 Exercício 5: INTERVAL

Crie uma tabela `tarefas` com colunas: id, titulo, prazo (TIMESTAMPTZ), tempo_estimado (INTERVAL).

a) Insira 5 tarefas com diferentes prazos e tempos estimados  
b) Calcule a data de início necessária para cada tarefa (prazo - tempo_estimado)  
c) Liste tarefas que precisam começar hoje ou já deveriam ter começado  
d) Calcule o tempo total estimado de todas as tarefas  

---

## 📚 Exercício 6: Tipos de Rede - Whitelist

Crie um sistema de controle de acesso por IP:

a) Criar tabela `whitelist` com ranges de IPs permitidos usando CIDR  
b) Inserir ranges: rede interna (10.0.0.0/8), VPN (172.16.0.0/12), escritório (192.168.1.0/24)  
c) Criar função que verifica se um IP tem acesso  
d) Testar com IPs: 10.5.1.100, 192.168.1.50, 200.1.1.1, 172.16.10.25  

---

## 📚 Exercício 7: Operadores de Rede

Usando a tabela de dispositivos:

```sql
CREATE TABLE dispositivos (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    ip INET,
    rede CIDR
);

INSERT INTO dispositivos VALUES
(1, 'Servidor Web', '192.168.1.100', '192.168.1.0/24'),
(2, 'Servidor DB', '192.168.1.200', '192.168.1.0/24'),
(3, 'Firewall', '10.0.0.1', '10.0.0.0/8'),
(4, 'Roteador Principal', '172.16.0.1', '172.16.0.0/12');
```

a) Liste dispositivos cuja rede contém o IP 192.168.1.150  
b) Encontre dispositivos na mesma sub-rede que 192.168.1.100  
c) Calcule o endereço de broadcast de cada rede  
d) Verifique se as redes 192.168.1.0/24 e 192.168.2.0/24 têm overlap  

---

## 📚 Exercício 8: MONEY vs NUMERIC

a) Crie duas tabelas idênticas: `vendas_money` (usando MONEY) e `vendas_numeric` (usando NUMERIC(10,2))  
b) Insira os mesmos 5 produtos em ambas  
c) Calcule descontos de 15% em ambas  
d) Converta valores de MONEY para NUMERIC e vice-versa  
e) Compare performance (opcional) inserindo 10.000 registros em cada  

---

## 📚 Exercício 9: BOOLEAN - Sistema de Tarefas

Crie um sistema de tarefas com múltiplos flags booleanos:

```sql
CREATE TABLE tarefas_projeto (
    id SERIAL PRIMARY KEY,
    titulo TEXT,
    concluida BOOLEAN DEFAULT FALSE,
    urgente BOOLEAN DEFAULT FALSE,
    aprovada BOOLEAN DEFAULT NULL,  -- NULL = aguardando aprovação
    arquivada BOOLEAN DEFAULT FALSE
);
```

a) Insira 10 tarefas com diferentes combinações de flags  
b) Liste tarefas pendentes (não concluídas E não arquivadas)  
c) Liste tarefas urgentes que precisam de aprovação  
d) Liste tarefas concluídas mas não aprovadas  
e) Crie uma view que classifica tarefas por status  

---

## 📚 Exercício 10: UUID em Sistemas Distribuídos

Simule um cenário de sistema distribuído:

a) Crie tabela `pedidos` com UUID e timestamp  
b) Simule inserções de 3 "servidores" diferentes (use UUIDs v4)  
c) Demonstre que não há colisão de IDs mesmo inserindo simultaneamente  
d) Compare com cenário usando SERIAL (mostre problema de conflito)  

---

## 📚 Exercício 11: Formatação de Datas

Crie uma tabela `relatorio_vendas` com vendas e datas. Gere um relatório formatado:

a) Data em formato brasileiro (DD/MM/YYYY)  
b) Nome do mês por extenso  
c) Dia da semana por extenso  
d) Trimestre do ano  
e) Semana do ano  

---

## 📚 Exercício 12: MAC Address

Crie uma tabela de dispositivos de rede com endereços MAC:

```sql
CREATE TABLE dispositivos_rede (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    mac MACADDR,
    ip INET,
    primeira_conexao TIMESTAMPTZ DEFAULT NOW()
);
```

a) Insira 5 dispositivos com MACs em diferentes formatos  
b) Padronize todos os MACs para formato com hífen  
c) Identifique o fabricante pelo OUI (primeiros 3 bytes)  
d) Liste dispositivos conectados nas últimas 24h  

---

## 📚 Exercício 13: Queries Complexas com Data/Hora

Crie uma tabela `log_acesso` e responda:

```sql
CREATE TABLE log_acesso (
    id BIGSERIAL PRIMARY KEY,
    usuario_id INT,
    acao TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

a) Insira 20 logs distribuídos ao longo de vários dias  
b) Conte acessos por hora do dia  
c) Conte acessos por dia da semana  
d) Identifique o horário de pico (hora com mais acessos)  
e) Calcule média de acessos por usuário por dia  

---

## 📚 Exercício 14: Tipo DOMAIN Customizado

Crie tipos DOMAIN customizados:

a) `email` - VARCHAR com validação de formato  
b) `telefone_br` - VARCHAR com formato (XX) XXXXX-XXXX  
c) `cpf` - CHAR(11) apenas dígitos  
d) `valor_positivo` - NUMERIC que não aceita negativos  

Use esses tipos em uma tabela `clientes_validados`.

---

## 📚 Exercício 15: IPv6

Crie uma tabela que trabalhe com endereços IPv6:

a) Inserir dispositivos com IPv6  
b) Verificar se um IPv6 está em determinada rede  
c) Converter entre notações (completa e abreviada)  
d) Identificar tipo de endereço (link-local, global, etc)  

---

## 📚 Exercício 16: Comparação de Performance

Compare performance entre tipos:

a) Crie 3 tabelas idênticas: uma com INT, outra com BIGINT, outra com UUID como PK  
b) Insira 100.000 registros em cada (use generate_series)  
c) Compare tamanho em disco (pg_total_relation_size)  
d) Compare tempo de SELECT por PK  
e) Compare tempo de JOIN  

---

## 📚 Exercício 17: Operações Avançadas com INTERVAL

a) Calcule sua idade exata em anos, meses e dias  
b) Crie função que retorna há quanto tempo algo aconteceu em linguagem natural ("há 2 dias", "há 3 semanas")  
c) Calcule o próximo feriado (assumindo lista de feriados em tabela)  
d) Determine se data está em horário de verão  

---

## 📚 Exercício 18: Migração de Tipos

Você tem uma tabela legada:

```sql
CREATE TABLE legado (
    id INT,
    data_criacao VARCHAR(20),  -- formato: 'DD/MM/YYYY HH24:MI'
    valor VARCHAR(20),         -- formato: 'R$ 1.234,56'
    ip_cliente VARCHAR(50)
);
```

a) Migre para tipos adequados (TIMESTAMPTZ, NUMERIC, INET)  
b) Crie script de migração tratando erros  
c) Valide dados antes da conversão  

---

## 📚 Exercício 19: Sistema de Logs com Todos os Tipos

Crie um sistema completo de auditoria usando vários tipos:

```sql
CREATE TABLE auditoria_sistema (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    usuario_id INT,
    ip_origem INET,
    acao TEXT,
    sucesso BOOLEAN,
    tempo_execucao INTERVAL,
    dados_anteriores JSONB,  -- Veremos JSONB no próximo arquivo
    metadados JSONB
);
```

a) Insira 15 registros de auditoria variados  
b) Consulte logs da última hora  
c) Encontre ações que falharam  
d) Calcule tempo médio de execução por tipo de ação  
e) Liste IPs suspeitos (muitas falhas)  

---

## 📚 Exercício 20: Desafio Final - Sistema Completo

Crie um mini-sistema de e-commerce com tipos apropriados:

```sql
-- Tabelas: clientes, produtos, pedidos, itens_pedido, log_acessos

-- Requisitos:
-- 1. Use UUID para IDs expostos externamente (clientes, pedidos)
-- 2. Use SERIAL para IDs internos (produtos, itens)
-- 3. Use TIMESTAMPTZ para todos os timestamps
-- 4. Armazene IPs de acesso com INET
-- 5. Use NUMERIC para valores monetários
-- 6. Use BOOLEAN para flags (ativo, concluído, etc)
-- 7. Crie pelo menos 2 tipos DOMAIN customizados
```

Depois:
- Insira dados realistas (pelo menos 10 de cada)
- Crie 5 queries analíticas complexas
- Demonstre uso de cada tipo especial

---

## 🎓 Conclusão

Após completar estes exercícios, você deve estar confortável com:

✅ Escolher tipos apropriados para cada situação  
✅ Trabalhar com UUID e SERIAL  
✅ Manipular datas, horas e timezones  
✅ Usar tipos de rede (INET, CIDR, MACADDR)  
✅ Decidir entre MONEY e NUMERIC  
✅ Operações avançadas com INTERVAL  

---

## 🔗 Navegação

[← Voltar](./README.md) | [Gabarito →](./gabarito-exercicios.md)
