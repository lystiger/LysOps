-- LysOps Operational State: Canonical Events Schema
-- Migration 001: Initial operational_events table and indexes

CREATE TABLE IF NOT EXISTS operational_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id TEXT NOT NULL UNIQUE,
    occurred_at TEXT NOT NULL,
    ingested_at TEXT NOT NULL,

    source TEXT NOT NULL,
    event_type TEXT NOT NULL,

    category TEXT,
    priority REAL,
    summary TEXT NOT NULL,

    status TEXT NOT NULL DEFAULT 'OPEN',

    source_ref TEXT,
    correlation_id TEXT,

    metadata_json TEXT,

    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_operational_events_occurred
ON operational_events(occurred_at);

CREATE INDEX IF NOT EXISTS idx_operational_events_source
ON operational_events(source);

CREATE INDEX IF NOT EXISTS idx_operational_events_category
ON operational_events(category);

CREATE INDEX IF NOT EXISTS idx_operational_events_status
ON operational_events(status);
