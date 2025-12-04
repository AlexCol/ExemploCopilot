ALTER TABLE audit_log SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'tabela, operacao',
    timescaledb.compress_orderby = 'data_hora DESC'
);

SELECT add_compression_policy('audit_log', INTERVAL '7 days');