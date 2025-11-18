# 📚 Tópico 11 - Security: Roles, Users e Permissions

## 🎯 Objetivo do Módulo

Dominar segurança avançada no PostgreSQL, incluindo Row Level Security e políticas de acesso.

## 📖 Conteúdo

### [11.1 - Roles vs Users](./01-roles-users.md)
- Roles e Users no PostgreSQL
- CREATE ROLE vs CREATE USER
- Role attributes (LOGIN, SUPERUSER, etc)
- Role membership e herança
- PUBLIC role
- Best practices

### [11.2 - Row Level Security (RLS)](./02-row-level-security.md)
- O que é RLS
- ENABLE ROW LEVEL SECURITY
- CREATE POLICY
- USING vs WITH CHECK
- Policy commands (SELECT, INSERT, UPDATE, DELETE)
- Multi-tenancy com RLS
- Performance implications

### [11.3 - Column Level Security](./03-column-level-security.md)
- GRANT SELECT on specific columns
- REVOKE column privileges
- Views para esconder colunas
- Funções SECURITY DEFINER
- Encryption at column level

### [11.4 - Policies e Grant System](./04-policies-grant-system.md)
- GRANT e REVOKE detalhado
- Default privileges
- Schema-level permissions
- Database-level permissions
- Function execution permissions
- SECURITY DEFINER functions

### [11.5 - Audit e Compliance](./05-audit-compliance.md)
- pgAudit extension
- Logging connections e statements
- Tracking privilege changes
- Audit tables com triggers
- Compliance requirements (PCI-DSS, GDPR, etc)

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Gerenciar roles e permissions adequadamente  
✅ Implementar Row Level Security  
✅ Criar políticas de acesso granulares  
✅ Configurar audit logging  
✅ Atender requisitos de compliance  

## ⏱️ Tempo Estimado

- **Leitura**: 4-5 horas
- **Prática**: 5-7 horas
- **Total**: 9-12 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: Roles e Users →](./01-roles-users.md)

---

**Status**: 🔄 Conteúdo detalhado disponível sob demanda
