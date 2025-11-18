# 📚 Tópico 14 - Monitoramento e Troubleshooting

## 🎯 Objetivo do Módulo

Dominar monitoramento, diagnóstico e resolução de problemas no PostgreSQL.

## 📖 Conteúdo

### [14.1 - System Catalogs (pg_catalog)](./01-system-catalogs.md)
- O que são system catalogs
- pg_class, pg_attribute, pg_index
- pg_namespace, pg_proc
- Metadata queries úteis
- Information_schema vs pg_catalog

### [14.2 - pg_stat_* Views](./02-pg-stat-views.md)
- pg_stat_activity (conexões ativas)
- pg_stat_database
- pg_stat_user_tables
- pg_stat_user_indexes
- pg_statio_* views (I/O stats)
- Resetting statistics

### [14.3 - Logging e Log Analysis](./03-logging-log-analysis.md)
- Configuração de logging
- log_statement, log_duration
- Log file formats
- pgBadger para análise
- Structured logging (JSON)
- Syslog integration

### [14.4 - Performance Monitoring](./04-performance-monitoring.md)
- Key metrics para monitorar
- Cache hit ratio
- Connection pooling stats
- Index usage statistics
- Table bloat detection
- Tools (pgAdmin, Prometheus, Grafana)

### [14.5 - Troubleshooting Common Issues](./05-troubleshooting.md)
- High CPU usage
- Memory issues
- Disk space problems
- Connection limits
- Long-running queries
- Lock contention
- Replication lag

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Navegar system catalogs  
✅ Monitorar performance com pg_stat views  
✅ Configurar e analisar logs  
✅ Identificar métricas importantes  
✅ Diagnosticar problemas comuns  
✅ Resolver gargalos de performance  

## ⏱️ Tempo Estimado

- **Leitura**: 4-5 horas
- **Prática**: 6-8 horas
- **Total**: 10-13 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: System Catalogs →](./01-system-catalogs.md)

---

**Status**: 🔄 Conteúdo detalhado disponível sob demanda
