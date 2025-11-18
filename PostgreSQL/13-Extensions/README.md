# 📚 Tópico 13 - Extensions e Recursos Especiais

## 🎯 Objetivo do Módulo

Explorar extensions poderosas do PostgreSQL para casos de uso especializados.

## 📖 Conteúdo

### [13.1 - PostGIS (Dados Geoespaciais)](./01-postgis.md)
- Instalação do PostGIS
- Geometry vs Geography types
- Spatial indexes (GiST)
- Queries espaciais (ST_Distance, ST_Within, etc)
- Casos de uso (proximidade, áreas, rotas)

### [13.2 - pg_stat_statements](./02-pg-stat-statements.md)
- Instalação e configuração
- Tracking query execution
- Identificando queries lentas
- Query normalization
- Statistics reset
- Integration com monitoring tools

### [13.3 - Foreign Data Wrappers (FDW)](./03-foreign-data-wrappers.md)
- O que são FDWs
- postgres_fdw (outros PostgreSQL)
- file_fdw (CSV, files)
- mysql_fdw, oracle_fdw
- Sharding com FDW
- Performance considerations

### [13.4 - pgcrypto e Segurança](./04-pgcrypto-seguranca.md)
- Hashing (MD5, SHA256, etc)
- Encryption/Decryption
- PGP encryption
- Random data generation
- Password hashing (crypt, bcrypt)

### [13.5 - TimescaleDB (Time Series)](./05-timescaledb.md)
- Instalação do TimescaleDB
- Hypertables
- Continuous aggregates
- Data retention policies
- Compression
- Use cases (IoT, metrics, logs)

## 📝 Exercícios Práticos

- [Exercícios do Módulo](./exercicios.md) - 20 exercícios práticos
- [Gabarito Comentado](./gabarito-exercicios.md) - Soluções detalhadas

## 🎓 O que você vai aprender

✅ Trabalhar com dados geoespaciais (PostGIS)  
✅ Monitorar queries com pg_stat_statements  
✅ Conectar databases externos com FDW  
✅ Implementar encryption com pgcrypto  
✅ Gerenciar time-series com TimescaleDB  

## ⏱️ Tempo Estimado

- **Leitura**: 5-6 horas
- **Prática**: 7-9 horas
- **Total**: 12-15 horas

## 🔗 Navegação

⬅️ [Voltar ao Índice](../README.md) | [Começar: PostGIS →](./01-postgis.md)

---

**Status**: 🔄 Conteúdo detalhado disponível sob demanda
