# 11.5 - Auditoria e Compliance

## 📋 O que você vai aprender

- Logging de conexões e queries
- pgAudit extension para auditoria avançada
- Tabelas de auditoria (audit tables)
- Triggers para rastreamento de mudanças
- Compliance (GDPR, LGPD, PCI-DSS, SOX)

---

## 🎯 Por que Auditar?

### Casos de Uso

1. **Segurança**: Detectar acessos não autorizados
2. **Compliance**: LGPD, GDPR, PCI-DSS, SOX, HIPAA
3. **Debug**: Rastrear origem de bugs
4. **Forense**: Investigar incidentes
5. **Analytics**: Entender padrões de uso

---

## 📝 Logging Nativo do PostgreSQL

### Configurar postgresql.conf

```conf
# Logging
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB

# O que logar
log_connections = on              # Logar conexões
log_disconnections = on           # Logar desconexões
log_duration = off                # Duração de cada statement
log_statement = 'all'             # none, ddl, mod, all
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '

# Queries lentas
log_min_duration_statement = 1000  # Log queries > 1s

# Erros
log_error_verbosity = default     # terse, default, verbose
```

### log_statement Níveis

- **none**: Não loga statements
- **ddl**: CREATE, ALTER, DROP
- **mod**: DDL + INSERT, UPDATE, DELETE, TRUNCATE
- **all**: Todos os statements (incluindo SELECT)

### Exemplo de Log

```
2024-01-15 10:30:45 [12345]: [1-1] user=app_user,db=mydb,app=psql,client=192.168.1.100 LOG:  connection authorized: user=app_user database=mydb
2024-01-15 10:30:50 [12345]: [2-1] user=app_user,db=mydb,app=psql,client=192.168.1.100 LOG:  statement: SELECT * FROM clientes WHERE id = 123;
2024-01-15 10:31:02 [12345]: [3-1] user=app_user,db=mydb,app=psql,client=192.168.1.100 LOG:  duration: 1523.456 ms  statement: UPDATE pedidos SET status = 'pago' WHERE id = 456;
```

---

## 🔍 pgAudit Extension

Extensão oficial para auditoria granular.

### Instalar pgAudit

```sql
-- Instalar extensão (precisa ser superuser)
CREATE EXTENSION pgaudit;

-- Configurar o que auditar
ALTER SYSTEM SET pgaudit.log = 'read, write, ddl';
ALTER SYSTEM SET pgaudit.log_catalog = off;  -- Não logar catálogos do sistema
ALTER SYSTEM SET pgaudit.log_parameter = on;  -- Incluir valores de parâmetros
ALTER SYSTEM SET pgaudit.log_relation = on;   -- Incluir nome de objetos

-- Recarregar config
SELECT pg_reload_conf();
```

### Opções de pgaudit.log

- **read**: SELECT, COPY FROM
- **write**: INSERT, UPDATE, DELETE, TRUNCATE, COPY TO
- **function**: Chamadas de função
- **role**: GRANT, REVOKE, CREATE/ALTER/DROP ROLE
- **ddl**: CREATE, ALTER, DROP de objetos
- **misc**: DISCARD, FETCH, CHECKPOINT, VACUUM

### Auditar por Role

```sql
-- Auditar tudo que app_user faz
ALTER ROLE app_user SET pgaudit.log = 'all';

-- Auditar apenas writes de outro role
ALTER ROLE service_account SET pgaudit.log = 'write';
```

### Exemplo de Log com pgAudit

```
2024-01-15 10:35:12 UTC [12345]: [4-1] user=app_user,db=mydb LOG:  AUDIT: SESSION,1,1,READ,SELECT,,,SELECT * FROM clientes WHERE email = 'test@example.com',<not logged>
2024-01-15 10:35:15 UTC [12345]: [5-1] user=app_user,db=mydb LOG:  AUDIT: SESSION,2,1,WRITE,UPDATE,,,UPDATE pedidos SET status = $1 WHERE id = $2,<not logged>
```

---

## 📊 Tabelas de Auditoria

Armazenar histórico de mudanças em tabelas dedicadas.

### Padrão: Tabela Espelho

```sql
-- Tabela principal
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100),
    ativo BOOLEAN DEFAULT TRUE
);

-- Tabela de auditoria
CREATE TABLE clientes_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    operacao CHAR(1) NOT NULL,  -- I=INSERT, U=UPDATE, D=DELETE
    usuario VARCHAR(50) NOT NULL,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    -- Colunas da tabela original
    id INTEGER,
    nome VARCHAR(100),
    email VARCHAR(100),
    ativo BOOLEAN
);

-- Trigger para INSERT
CREATE OR REPLACE FUNCTION audit_clientes_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO clientes_audit (operacao, usuario, id, nome, email, ativo)
    VALUES ('I', current_user, NEW.id, NEW.nome, NEW.email, NEW.ativo);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clientes_audit_insert
AFTER INSERT ON clientes
FOR EACH ROW EXECUTE FUNCTION audit_clientes_insert();

-- Trigger para UPDATE
CREATE OR REPLACE FUNCTION audit_clientes_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO clientes_audit (operacao, usuario, id, nome, email, ativo)
    VALUES ('U', current_user, NEW.id, NEW.nome, NEW.email, NEW.ativo);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clientes_audit_update
AFTER UPDATE ON clientes
FOR EACH ROW EXECUTE FUNCTION audit_clientes_update();

-- Trigger para DELETE
CREATE OR REPLACE FUNCTION audit_clientes_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO clientes_audit (operacao, usuario, id, nome, email, ativo)
    VALUES ('D', current_user, OLD.id, OLD.nome, OLD.email, OLD.ativo);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clientes_audit_delete
AFTER DELETE ON clientes
FOR EACH ROW EXECUTE FUNCTION audit_clientes_delete();

-- Teste
INSERT INTO clientes (nome, email) VALUES ('João', 'joao@example.com');
UPDATE clientes SET ativo = FALSE WHERE id = 1;
DELETE FROM clientes WHERE id = 1;

-- Ver histórico
SELECT * FROM clientes_audit ORDER BY audit_id;
/*
 audit_id | operacao | usuario  | data_hora           | id | nome | email             | ativo
----------+----------+----------+---------------------+----+------+-------------------+-------
        1 | I        | app_user | 2024-01-15 10:40:00 |  1 | João | joao@example.com  | t
        2 | U        | app_user | 2024-01-15 10:41:00 |  1 | João | joao@example.com  | f
        3 | D        | app_user | 2024-01-15 10:42:00 |  1 | João | joao@example.com  | f
*/
```

### Padrão: JSON Audit Table (Genérico)

```sql
-- Tabela genérica de auditoria (serve para qualquer tabela)
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    tabela VARCHAR(50) NOT NULL,
    operacao CHAR(1) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    dados_antigos JSONB,
    dados_novos JSONB,
    ip_address INET,
    aplicacao VARCHAR(100)
);

CREATE INDEX idx_audit_log_tabela_data ON audit_log(tabela, data_hora DESC);

-- Função genérica de auditoria
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_old_data = row_to_json(OLD)::JSONB;
        v_new_data = NULL;
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old_data = row_to_json(OLD)::JSONB;
        v_new_data = row_to_json(NEW)::JSONB;
    ELSIF (TG_OP = 'INSERT') THEN
        v_old_data = NULL;
        v_new_data = row_to_json(NEW)::JSONB;
    END IF;
    
    INSERT INTO audit_log (
        tabela, operacao, usuario, dados_antigos, dados_novos, 
        ip_address, aplicacao
    ) VALUES (
        TG_TABLE_NAME, 
        LEFT(TG_OP, 1),
        current_user,
        v_old_data,
        v_new_data,
        inet_client_addr(),
        current_setting('application_name', TRUE)
    );
    
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a qualquer tabela
CREATE TRIGGER clientes_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER pedidos_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON pedidos
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Teste
UPDATE clientes SET nome = 'João Silva' WHERE id = 1;

SELECT 
    tabela,
    operacao,
    usuario,
    data_hora,
    dados_antigos->>'nome' AS nome_antigo,
    dados_novos->>'nome' AS nome_novo
FROM audit_log
ORDER BY id DESC
LIMIT 10;
```

---

## 🛡️ Compliance

### LGPD / GDPR

**Lei Geral de Proteção de Dados** (Brasil) e **General Data Protection Regulation** (Europa).

#### Requisitos

1. **Consentimento**: Registrar quando usuário autorizou uso de dados
2. **Direito ao esquecimento**: Permitir deletar dados
3. **Portabilidade**: Exportar dados em formato legível
4. **Auditoria**: Rastrear quem acessou dados pessoais

#### Implementação

```sql
-- Tabela de consentimento
CREATE TABLE consentimentos (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuarios(id),
    tipo_consentimento VARCHAR(50), -- 'marketing', 'cookies', etc
    consentido BOOLEAN,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET
);

-- Tabela de acesso a dados sensíveis
CREATE TABLE acesso_dados_pessoais (
    id BIGSERIAL PRIMARY KEY,
    usuario_consultado_id INTEGER,
    usuario_consultor VARCHAR(50),
    finalidade TEXT,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET
);

-- Função para registrar acesso
CREATE FUNCTION registrar_acesso_dados_pessoais(
    p_usuario_id INT,
    p_finalidade TEXT
) RETURNS VOID AS $$
BEGIN
    INSERT INTO acesso_dados_pessoais (
        usuario_consultado_id, usuario_consultor, finalidade, ip_address
    ) VALUES (
        p_usuario_id, current_user, p_finalidade, inet_client_addr()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- View que registra acesso automaticamente
CREATE VIEW usuarios_lgpd AS
SELECT 
    u.id,
    u.nome,
    u.email,
    registrar_acesso_dados_pessoais(u.id, 'Visualização de dados') AS _log
FROM usuarios u;

-- Uso: ao invés de SELECT direto, usar view
SELECT nome, email FROM usuarios_lgpd WHERE id = 123;
-- Automaticamente registrado em acesso_dados_pessoais!

-- Direito ao esquecimento
CREATE FUNCTION anonimizar_usuario(p_usuario_id INT) RETURNS VOID AS $$
BEGIN
    UPDATE usuarios SET
        nome = 'Usuário Removido',
        email = 'removido_' || p_usuario_id || '@anonimizado.com',
        cpf = NULL,
        telefone = NULL,
        endereco = NULL
    WHERE id = p_usuario_id;
    
    -- Registrar anonimização
    INSERT INTO audit_log (tabela, operacao, usuario, dados_novos)
    VALUES ('usuarios', 'A', current_user, 
            jsonb_build_object('usuario_id', p_usuario_id, 
                               'motivo', 'Direito ao esquecimento'));
END;
$$ LANGUAGE plpgsql;
```

### PCI-DSS (Dados de Cartão)

**Payment Card Industry Data Security Standard**.

#### Requisitos

1. Encriptar dados de cartão
2. Auditar todos os acessos
3. Manter logs por pelo menos 1 ano
4. Restringir acesso a dados de cartão

#### Implementação

```sql
-- Dados de cartão encriptados
CREATE TABLE pagamentos (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER,
    cartao_encriptado BYTEA NOT NULL,  -- Número encriptado
    ultimos_4_digitos CHAR(4),  -- Pode armazenar plain
    data_validade_encriptada BYTEA,
    nome_titular TEXT
);

-- Audit table específica para PCI-DSS
CREATE TABLE audit_pci (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50),
    acao VARCHAR(100),
    dados_acessados TEXT,
    resultado VARCHAR(20),  -- 'sucesso', 'negado'
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET
);

-- Função para acessar dados de cartão (SEMPRE auditar)
CREATE FUNCTION get_cartao_info(p_pagamento_id INT, p_senha TEXT)
RETURNS TABLE (
    numero_cartao TEXT,
    data_validade TEXT
) AS $$
DECLARE
    v_resultado VARCHAR(20);
BEGIN
    -- Tentar decriptar
    BEGIN
        RETURN QUERY
        SELECT 
            pgp_sym_decrypt(cartao_encriptado, p_senha)::TEXT,
            pgp_sym_decrypt(data_validade_encriptada, p_senha)::TEXT
        FROM pagamentos
        WHERE id = p_pagamento_id;
        
        v_resultado := 'sucesso';
    EXCEPTION WHEN OTHERS THEN
        v_resultado := 'negado';
    END;
    
    -- SEMPRE auditar tentativa de acesso
    INSERT INTO audit_pci (usuario, acao, dados_acessados, resultado, ip_address)
    VALUES (
        current_user,
        'ACESSO_CARTAO',
        'pagamento_id=' || p_pagamento_id,
        v_resultado,
        inet_client_addr()
    );
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Uso: acesso ao cartão SEMPRE auditado
SELECT * FROM get_cartao_info(123, 'senha_secreta');
```

### SOX (Sarbanes-Oxley)

Compliance financeiro (EUA).

#### Requisitos

1. Separação de deveres (DBA não pode ser desenvolvedor)
2. Rastreabilidade de mudanças em produção
3. Logs imutáveis

#### Implementação

```sql
-- Registrar TODAS as mudanças de schema
CREATE TABLE sox_ddl_audit (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50),
    comando TEXT,
    objeto TEXT,
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    aprovacao_ticket VARCHAR(50)  -- Número de ticket de mudança
);

-- Event trigger para capturar DDL
CREATE OR REPLACE FUNCTION audit_ddl()
RETURNS event_trigger AS $$
DECLARE
    obj RECORD;
BEGIN
    FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        INSERT INTO sox_ddl_audit (usuario, comando, objeto)
        VALUES (
            current_user,
            obj.command_tag,
            obj.object_identity
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE EVENT TRIGGER audit_ddl_trigger
ON ddl_command_end
EXECUTE FUNCTION audit_ddl();

-- Teste
CREATE TABLE teste_sox (id INT);
DROP TABLE teste_sox;

SELECT * FROM sox_ddl_audit;
/*
 usuario  | comando      | objeto           | data_hora
----------+--------------+------------------+---------------------
 app_user | CREATE TABLE | public.teste_sox | 2024-01-15 11:00:00
 app_user | DROP TABLE   | public.teste_sox | 2024-01-15 11:00:05
*/
```

---

## 🎯 Boas Práticas

### 1. Retenção de Logs

```sql
-- Particionar tabela de audit por data
CREATE TABLE audit_log (
    id BIGSERIAL,
    ...
    data_hora TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (data_hora);

-- Partições mensais
CREATE TABLE audit_log_2024_01 PARTITION OF audit_log
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE audit_log_2024_02 PARTITION OF audit_log
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Arquivar/deletar partições antigas
DROP TABLE audit_log_2023_01;  -- Depois de 1 ano
```

### 2. Proteger Tabelas de Auditoria

```sql
-- Audit tables: apenas INSERT, nunca UPDATE/DELETE
REVOKE UPDATE, DELETE, TRUNCATE ON audit_log FROM PUBLIC;
GRANT INSERT, SELECT ON audit_log TO app_user;

-- Ou: usar trigger para bloquear
CREATE FUNCTION protect_audit() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Registros de auditoria não podem ser alterados';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER protect_audit_trigger
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION protect_audit();
```

### 3. Alertas Automáticos

```sql
-- Função para detectar acessos suspeitos
CREATE FUNCTION alerta_acesso_suspeito()
RETURNS TRIGGER AS $$
BEGIN
    -- Se mais de 100 selects em 1 minuto pelo mesmo usuário
    IF (
        SELECT COUNT(*) 
        FROM audit_log 
        WHERE usuario = NEW.usuario 
          AND operacao = 'S'
          AND data_hora > NOW() - INTERVAL '1 minute'
    ) > 100 THEN
        -- Enviar alerta (pode usar pg_notify ou tabela de alertas)
        INSERT INTO alertas_seguranca (tipo, mensagem, usuario)
        VALUES (
            'ACESSO_SUSPEITO',
            'Usuário executou mais de 100 SELECTs em 1 minuto',
            NEW.usuario
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER alerta_trigger
AFTER INSERT ON audit_log
FOR EACH ROW EXECUTE FUNCTION alerta_acesso_suspeito();
```

---

## 🔗 Navegação

⬅️ [Anterior: Policies e GRANT System](./04-policies-grant-system.md) | [Voltar ao Índice: Security →](./README.md)

---

## 📝 Resumo Rápido

```sql
-- Logging nativo
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_connections = on;

-- pgAudit
CREATE EXTENSION pgaudit;
ALTER SYSTEM SET pgaudit.log = 'read, write, ddl';

-- Tabela de auditoria
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    operacao CHAR(1),
    usuario VARCHAR(50),
    data_hora TIMESTAMPTZ DEFAULT NOW(),
    dados_antigos JSONB,
    dados_novos JSONB
);

-- Trigger de auditoria
CREATE TRIGGER audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON tabela
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- LGPD: Anonimização
UPDATE usuarios SET 
    nome = 'Removido', 
    email = NULL, 
    cpf = NULL 
WHERE id = 123;
```
