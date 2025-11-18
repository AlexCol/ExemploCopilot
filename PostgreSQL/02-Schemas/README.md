# 📚 Tópico 02 - Schemas e Organização de Dados

## 🎯 Objetivo do Módulo

Dominar o uso de schemas no PostgreSQL para organização eficiente de dados, controle de acesso granular e implementação de arquiteturas multi-tenant.

## 📖 Conteúdo

### [2.1 - Introdução a Schemas](./01-introducao-schemas.md)
- O que são schemas no PostgreSQL
- Por que usar schemas
- Schema padrão: `public`
- Analogias práticas e visualização
- Schemas do sistema vs schemas de usuário

### [2.2 - Criando e Gerenciando Schemas](./02-criando-gerenciando-schemas.md)
- Sintaxe de criação (CREATE SCHEMA)
- Criando objetos dentro de schemas
- Renomeando e alterando schemas
- Excluindo schemas (DROP vs DROP CASCADE)
- Movendo objetos entre schemas
- Consultando informações de schemas

### [2.3 - Search Path](./03-search-path.md)
- Como funciona o search_path
- Configurando search_path (sessão, usuário, database)
- Resolução de nomes e ordem de busca
- Problemas comuns (ambiguidade, security)
- Boas práticas de configuração

### [2.4 - Permissões em Schemas](./04-permissoes-schemas.md)
- Privilégios de schema (USAGE, CREATE)
- Permissões em objetos dentro de schemas
- GRANT e REVOKE
- DEFAULT PRIVILEGES
- Cenários práticos (readonly, readwrite, admin)
- Roles e grupos

### [2.5 - Boas Práticas com Schemas](./05-boas-praticas-schemas.md)
- Padrões de organização (domínio, ambiente, multi-tenant)
- Convenções de nomenclatura
- Estratégias de deployment
- Performance e otimização
- Segurança
- Antipadrões a evitar
- Exemplo completo de sistema e-commerce

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 25 exercícios práticos progressivos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas e explicadas

## 🎓 O que você vai aprender

Após completar este módulo, você será capaz de:

✅ Entender profundamente como schemas funcionam  
✅ Organizar databases de forma lógica e escalável  
✅ Configurar search_path adequadamente  
✅ Implementar controle de acesso granular  
✅ Aplicar padrões de organização (multi-tenant, por domínio)  
✅ Evitar armadilhas comuns de segurança  
✅ Implementar boas práticas em produção  

## ⏱️ Tempo Estimado

- **Leitura**: 3-4 horas
- **Prática**: 4-6 horas
- **Total**: 7-10 horas

## 🎯 Pré-requisitos

- Conhecimento básico de SQL
- Entendimento de databases e tabelas
- Familiaridade com conceitos de permissões

## 💡 Por que este tópico é importante?

Schemas são **fundamentais** para:
- 🏢 **Organização**: Estruturar databases complexos logicamente
- 🔒 **Segurança**: Controle de acesso granular por schema
- 🏗️ **Multi-tenancy**: Isolar dados de diferentes clientes
- 🚀 **Escalabilidade**: Facilitar crescimento e manutenção
- 👥 **Colaboração**: Permitir times trabalharem em paralelo

## 🔗 Navegação

⬅️ [Voltar ao Índice Geral](../README.md) | [Começar: Introdução a Schemas →](./01-introducao-schemas.md)

---

## 📊 Status

✅ **100% Completo** - Todos os arquivos de conteúdo criados  
✅ 5 arquivos de lições  
✅ 25 exercícios práticos  
✅ Gabarito completo com explicações  

---

## 🎯 Casos de Uso Reais

Este tópico é especialmente útil para:

1. **SaaS Multi-tenant**: Um schema por cliente
2. **E-commerce**: Schemas por domínio (vendas, estoque, financeiro)
3. **Analytics**: Separar dados brutos, staging e produção
4. **Ambientes**: Dev, staging, prod no mesmo database
5. **Microsserviços**: Schema por serviço no mesmo database

---

**Bom estudo! 🚀**
