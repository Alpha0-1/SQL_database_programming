-- =====================================================
-- File: 10-data_lake_integration.sql
-- Description: Data lake integration patterns
-- Author: Alpha0-1
-- Purpose: Demonstrate SQL integration with data lakes
-- =====================================================

-- Data lakes store raw data in various formats (JSON, Parquet, CSV, etc.)
-- This file shows patterns for integrating SQL with data lake architectures

-- 1. External table pattern for data lake access
-- Create external table pointing to data lake files
CREATE SCHEMA IF NOT EXISTS data_lake;

-- External table for CSV files in data lake
CREATE FOREIGN TABLE IF NOT EXISTS data_lake.raw_events (
    event_id VARCHAR(50),
    user_id VARCHAR(50),
    event_type VARCHAR(100),
    timestamp TIMESTAMP,
    properties TEXT  -- Raw JSON string
) SERVER file_server
OPTIONS (filename '/data/lake/events/events.csv', format 'csv', header 'true');

-- External table for Parquet files (using appropriate foreign data wrapper)
-- Note: This would require parquet_fdw or similar extension
CREATE TABLE IF NOT EXISTS data_lake.parquet_data (
    id BIGINT,
    data JSONB,
    partition_date DATE,
    file_path TEXT
);

-- 2. Staging tables for data lake ingestion
CREATE TABLE IF NOT EXISTS staging_raw_data (
    id SERIAL PRIMARY KEY,
    source_system VARCHAR(100),
    file_path VARCHAR(500),
    raw_content JSONB,
    file_metadata JSONB,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE
);

-- Function to ingest JSON files from data lake
CREATE OR REPLACE FUNCTION ingest_json_file(
    p_file_path TEXT,
    p_source_system TEXT,
    p_json_content JSONB
)
RETURNS INTEGER AS $$
DECLARE
    inserted_id INTEGER;
BEGIN
    INSERT INTO staging_raw_data (source_system, file_path, raw_content, file_metadata)
    VALUES (
        p_source_system,
        p_file_path,
        p_json_content,
        json_build_object(
            'file_size', pg_column_size(p_json_content),
            'ingestion_time', CURRENT_TIMESTAMP,
            'record_count', CASE 
                WHEN jsonb_typeof(p_json_content) = 'array' 
                THEN jsonb_array_length(p_json_content) 
                ELSE 1 
            END
        )
    )
    RETURNING id INTO inserted_id;
    
    RETURN inserted_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Data processing pipeline tables
CREATE TABLE IF NOT EXISTS processed_events (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(50) UNIQUE,
    user_id VARCHAR(50),
    session_id VARCHAR(50),
    event_type VARCHAR(100),
    event_timestamp TIMESTAMP,
    event_properties JSONB,
    derived_metrics JSONB,
    processing_metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create partitioned table for time-series data from data lake
CREATE TABLE IF NOT EXISTS events_partitioned (
    id BIGSERIAL,
    event_id VARCHAR(50),
    user_id VARCHAR(50),
    event_type VARCHAR(100),
    event_timestamp TIMESTAMP,
    properties JSONB,
    partition_date DATE GENERATED ALWAYS AS (DATE(event_timestamp)) STORED
) PARTITION BY RANGE (partition_date);

-- Create partitions for different months
CREATE TABLE IF NOT EXISTS events_2024_01 PARTITION OF events_partitioned
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE IF NOT EXISTS events_2024_02 PARTITION OF events_partitioned
FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- 4. ETL processing functions
CREATE OR REPLACE FUNCTION process_raw_events()
RETURNS INTEGER AS $$
DECLARE
    rec RECORD;
    processed_count INTEGER := 0;
    event_record JSONB;
BEGIN
    -- Process unprocessed staging data
    FOR rec IN 
        SELECT id, raw_content 
        FROM staging_raw_data 
        WHERE NOT processed 
        AND source_system = 'event_tracking'
    LOOP
        -- Handle array of events
        IF jsonb_typeof(rec.raw_content) = 'array' THEN
            FOR event_record IN SELECT * FROM jsonb_array_elements(rec.raw_content)
            LOOP
                INSERT INTO processed_events (
                    event_id,
                    user_id,
                    session_id,
                    event_type,
                    event_timestamp,
                    event_properties,
                    derived_metrics,
                    processing_metadata
                ) VALUES (
                    event_record->>'event_id',
                    event_record->>'user_id',
                    event_record->>'session_id',
                    event_record->>'event_type',
                    (event_record->>'timestamp')::TIMESTAMP,
                    event_record->'properties',
                    json_build_object(
                        'hour_of_day', EXTRACT(HOUR FROM (event_record->>'timestamp')::TIMESTAMP),
                        'day_of_week', EXTRACT(DOW FROM (event_record->>'timestamp')::TIMESTAMP)
                    ),
                    json_build_object(
                        'processed_at', CURRENT_TIMESTAMP,
                        'source_file_id', rec.id
                    )
                ) ON CONFLICT (event_id) DO NOTHING;
                
                processed_count := processed_count + 1;
                            END LOOP;
            
            WHEN 'validity' THEN
                -- Check field validity
                field_value := p_data->>rule.rule_definition->>'field';
                IF field_value IS NOT NULL THEN
                    -- Add specific validation logic here
                    IF rule.rule_definition ? 'condition' THEN
                        -- Simple numeric validation example
                        IF rule.rule_definition->>'condition' = '> 0' THEN
                            is_valid := (field_value::NUMERIC > 0);
                        END IF;
                    END IF;
                END IF;
        END CASE;
        
        validation_results := validation_results || json_build_object(
            'rule_name', rule.rule_name,
            'rule_type', rule.rule_type,
            'is_valid', is_valid
        )::JSONB;
    END LOOP;
    
    RETURN validation_results;
END;
$ LANGUAGE plpgsql;

-- 8. Batch processing for data lake files
CREATE TABLE IF NOT EXISTS batch_jobs (
    id SERIAL PRIMARY KEY,
    job_name VARCHAR(200) NOT NULL,
    job_type VARCHAR(50) NOT NULL,
    source_path VARCHAR(500) NOT NULL,
    target_table VARCHAR(200),
    job_config JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    records_processed INTEGER DEFAULT 0,
    error_message TEXT
);

-- Function to process batch jobs
CREATE OR REPLACE FUNCTION process_batch_job(p_job_id INTEGER)
RETURNS BOOLEAN AS $
DECLARE
    job RECORD;
    success BOOLEAN := FALSE;
BEGIN
    SELECT * INTO job FROM batch_jobs WHERE id = p_job_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Job not found: %', p_job_id;
    END IF;
    
    -- Update job status
    UPDATE batch_jobs 
    SET status = 'running', started_at = CURRENT_TIMESTAMP 
    WHERE id = p_job_id;
    
    BEGIN
        -- Simulate batch processing
        CASE job.job_type
            WHEN 'csv_import' THEN
                -- Process CSV files from data lake
                INSERT INTO staging_raw_data (source_system, file_path, raw_content)
                SELECT 
                    job.job_config->>'source_system',
                    job.source_path,
                    json_build_object('simulated', 'csv_data')
                WHERE NOT EXISTS (
                    SELECT 1 FROM staging_raw_data 
                    WHERE file_path = job.source_path
                );
                
            WHEN 'json_import' THEN
                -- Process JSON files from data lake
                PERFORM ingest_json_file(
                    job.source_path,
                    job.job_config->>'source_system',
                    '{"simulated": "json_data"}'::JSONB
                );
        END CASE;
        
        success := TRUE;
        
        UPDATE batch_jobs 
        SET status = 'completed', 
            completed_at = CURRENT_TIMESTAMP,
            records_processed = 100  -- Simulated count
        WHERE id = p_job_id;
        
    EXCEPTION WHEN OTHERS THEN
        UPDATE batch_jobs 
        SET status = 'failed', 
            completed_at = CURRENT_TIMESTAMP,
            error_message = SQLERRM
        WHERE id = p_job_id;
        
        success := FALSE;
    END;
    
    RETURN success;
END;
$ LANGUAGE plpgsql;

-- 9. Data lake analytics aggregation
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_event_summary AS
SELECT 
    DATE(event_timestamp) as event_date,
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users,
    json_agg(DISTINCT event_properties->>'source') as sources,
    AVG(CASE WHEN event_properties ? 'duration' 
        THEN (event_properties->>'duration')::NUMERIC 
        ELSE NULL END) as avg_duration
FROM processed_events
WHERE event_timestamp >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(event_timestamp), event_type;

-- Create index on materialized view
CREATE INDEX IF NOT EXISTS idx_daily_summary_date 
ON daily_event_summary(event_date);

-- 10. Data archival strategy
CREATE TABLE IF NOT EXISTS archived_events (
    LIKE processed_events INCLUDING ALL
) PARTITION BY RANGE (event_timestamp);

-- Function to archive old data
CREATE OR REPLACE FUNCTION archive_old_events(p_cutoff_date DATE)
RETURNS INTEGER AS $
DECLARE
    archived_count INTEGER;
BEGIN
    -- Move old data to archive table
    WITH moved_events AS (
        DELETE FROM processed_events 
        WHERE DATE(event_timestamp) < p_cutoff_date
        RETURNING *
    )
    INSERT INTO archived_events SELECT * FROM moved_events;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    
    -- Update catalog with archival info
    INSERT INTO data_lake_catalog (
        dataset_name, file_path, file_format, 
        record_count, created_date, tags
    ) VALUES (
        'archived_events',
        '/data/lake/archive/' || p_cutoff_date::TEXT,
        'parquet',
        archived_count,
        CURRENT_DATE,
        ARRAY['archived', 'events']
    );
    
    RETURN archived_count;
END;
$ LANGUAGE plpgsql;

-- 11. Performance optimization for data lake queries
-- Create indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_processed_events_user_time 
ON processed_events(user_id, event_timestamp);

CREATE INDEX IF NOT EXISTS idx_processed_events_type_time 
ON processed_events(event_type, event_timestamp);

CREATE INDEX IF NOT EXISTS idx_processed_events_properties 
ON processed_events USING GIN(event_properties);

-- 12. Data lake monitoring queries
-- Monitor ingestion performance
SELECT 
    source_system,
    DATE(ingested_at) as ingestion_date,
    COUNT(*) as files_ingested,
    SUM((file_metadata->>'record_count')::INTEGER) as total_records,
    AVG(pg_column_size(raw_content)) as avg_file_size
FROM staging_raw_data
WHERE ingested_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY source_system, DATE(ingested_at)
ORDER BY ingestion_date DESC;

-- Monitor data quality
WITH quality_summary AS (
    SELECT 
        dataset_name,
        rule_name,
        COUNT(*) as total_validations,
        SUM(CASE WHEN (validation_result->>rule_name)::BOOLEAN THEN 1 ELSE 0 END) as passed_validations
    FROM (
        SELECT 
            'user_events' as dataset_name,
            validate_data_quality('user_events', raw_content) as validation_result
        FROM staging_raw_data 
        WHERE source_system = 'event_tracking'
        LIMIT 100  -- Sample for demonstration
    ) t,
    jsonb_array_elements(validation_result) as rule(rule_name)
    GROUP BY dataset_name, rule_name
)
SELECT 
    dataset_name,
    rule_name,
    total_validations,
    passed_validations,
    ROUND(100.0 * passed_validations / total_validations, 2) as pass_rate_percent
FROM quality_summary;

-- Clean up old staging data
DELETE FROM staging_raw_data 
WHERE processed = TRUE 
AND ingested_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
        ELSE
            -- Handle single event
            INSERT INTO processed_events (
                event_id,
                user_id,
                event_type,
                event_timestamp,
                event_properties,
                processing_metadata
            ) VALUES (
                rec.raw_content->>'event_id',
                rec.raw_content->>'user_id',
                rec.raw_content->>'event_type',
                (rec.raw_content->>'timestamp')::TIMESTAMP,
                rec.raw_content->'properties',
                json_build_object(
                    'processed_at', CURRENT_TIMESTAMP,
                    'source_file_id', rec.id
                )
            ) ON CONFLICT (event_id) DO NOTHING;
            
            processed_count := processed_count + 1;
        END IF;
        
        -- Mark as processed
        UPDATE staging_raw_data 
        SET processed = TRUE 
        WHERE id = rec.id;
    END LOOP;
    
    RETURN processed_count;
END;
$$ LANGUAGE plpgsql;

-- 5. Data lake metadata management
CREATE TABLE IF NOT EXISTS data_lake_catalog (
    id SERIAL PRIMARY KEY,
    dataset_name VARCHAR(200) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_format VARCHAR(50) NOT NULL,
    schema_definition JSONB,
    partition_info JSONB,
    size_bytes BIGINT,
    record_count BIGINT,
    created_date DATE,
    last_modified TIMESTAMP,
    quality_metrics JSONB,
    tags TEXT[]
);

-- Insert catalog entries
INSERT INTO data_lake_catalog (
    dataset_name, file_path, file_format, schema_definition, 
    partition_info, size_bytes, record_count, created_date, tags
) VALUES
('user_events', '/data/lake/events/2024/01/', 'parquet', 
 '{"event_id": "string", "user_id": "string", "timestamp": "timestamp", "properties": "json"}',
 '{"partition_by": "date", "partition_format": "yyyy/MM/dd"}',
 1048576, 10000, '2024-01-01', ARRAY['events', 'user_behavior']),
('transaction_logs', '/data/lake/transactions/2024/', 'json',
 '{"transaction_id": "string", "amount": "decimal", "currency": "string", "metadata": "json"}',
 '{"partition_by": "month", "partition_format": "yyyy/MM"}',
 2097152, 5000, '2024-01-01', ARRAY['transactions', 'financial']);

-- 6. Query federation example
-- Create view that combines data lake and transactional data
CREATE OR REPLACE VIEW unified_user_activity AS
SELECT 
    'database' as source,
    user_id,
    event_type,
    event_timestamp as timestamp,
    event_properties as properties
FROM processed_events
WHERE event_timestamp >= CURRENT_DATE - INTERVAL '30 days'

UNION ALL

SELECT 
    'data_lake' as source,
    user_id,
    event_type,
    timestamp,
    properties::JSONB as properties
FROM data_lake.raw_events
WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days';

-- 7. Data quality validation for data lake ingestion
CREATE TABLE IF NOT EXISTS data_quality_rules (
    id SERIAL PRIMARY KEY,
    dataset_name VARCHAR(200) NOT NULL,
    rule_name VARCHAR(200) NOT NULL,
    rule_type VARCHAR(50) NOT NULL,
    rule_definition JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- Insert quality rules
INSERT INTO data_quality_rules (dataset_name, rule_name, rule_type, rule_definition) VALUES
('user_events', 'required_fields', 'completeness', 
 '{"required_fields": ["event_id", "user_id", "timestamp"]}'),
('user_events', 'timestamp_range', 'validity',
 '{"field": "timestamp", "min_date": "2020-01-01", "max_date": "2030-12-31"}'),
('transaction_logs', 'amount_positive', 'validity',
 '{"field": "amount", "condition": "> 0"}');

-- Function to validate data quality
CREATE OR REPLACE FUNCTION validate_data_quality(
    p_dataset_name VARCHAR(200),
    p_data JSONB
)
RETURNS JSONB AS $$
DECLARE
    rule RECORD;
    validation_results JSONB := '[]'::JSONB;
    field_value TEXT;
    is_valid BOOLEAN;
BEGIN
    FOR rule IN 
        SELECT * FROM data_quality_rules 
        WHERE dataset_name = p_dataset_name AND is_active = TRUE
    LOOP
        is_valid := TRUE;
        
        CASE rule.rule_type
            WHEN 'completeness' THEN
                -- Check required fields
                FOR field_value IN 
                    SELECT jsonb_array_elements_text(rule.rule_definition->'required_fields')
                LOOP
                    IF NOT (p_data ? field_value) OR (p_data->>field_value IS NULL) THEN
                        is_valid := FALSE;
                        EXIT;
                    END IF;
                END
