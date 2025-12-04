-- 08-configurar-policies-aggregates.sql
SELECT add_continuous_aggregate_policy('audit_stats_daily',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

SELECT add_continuous_aggregate_policy('audit_stats_monthly',
    start_offset => INTERVAL '90 days',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 day');