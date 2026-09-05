# LysOps Architecture: STATE-01 Shared Operational State

## Overview
**STATE-01** provides a lightweight, local, privacy-conscious operational event store for the LysOps automation suite.
It establishes a single storage contract and decoupled communication bridge between ingest/triage workflows (`MSG-01`, `FIN-01`, `LEARN-01`, etc.) and executive synthesis/presentation workflows (`OPS-01`, `Elysia`).

```
MSG-01 (Zalo)  ─────┐
OPS-01 (Brief) ─────┤
FIN-01 (Future) ────┤
LEARN-01 (Future) ──┼──→ STATE-01 (Upsert Operational Event)
UNI-01 (Future) ────┘         ↓
                     /data/lysops/lysops.db (SQLite)
                              ↓
                      OPS-01 (Daily Query)
                              ↓
                         Telegram / Elysia
```

## Storage Engine & Topology
- **Engine**: SQLite via Node.js native built-in `node:sqlite` (`DatabaseSync`).
- **Location**: `/data/lysops/lysops.db` in Docker container, mounted persistently from host `~/n8n-dev/data/lysops/lysops.db`.
- **Isolation**: Strictly isolated from n8n's internal workflow database (`database.sqlite`).
- **Zero-Dependency**: No external database containers (Postgres, Redis, Kafka) required.

## Canonical Schema
```sql
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
```

### Supported Categories
- `ACTION_REQUIRED`: High-priority operational tasks requiring direct intervention.
- `DECISION_REQUIRED`: Items requiring human approval, financial decisions, or voting.
- `WAITING`: Tasks pending third-party action, delivery, or resolution.
- `FYI`: Informational updates, shift logs, and context.
- `IGNORE`: Suppressed noise, automated bots, and casual banter.

### Lifecycle Statuses
- `OPEN`: Active, unaddressed operational event.
- `RESOLVED`: Handled or action completed.
- `DISMISSED`: Explicitly ignored or overridden by user.

## Idempotency Strategy
- Upstream producers provide a deterministic `event_id` (e.g. `zalo:<message_id>`, `gmail:<id>`, `calendar:<event_id>`).
- Database applies a `UNIQUE` constraint on `event_id`.
- Upsert logic uses:
  ```sql
  INSERT INTO operational_events (...)
  VALUES (...)
  ON CONFLICT(event_id) DO UPDATE SET
    category = excluded.category,
    priority = excluded.priority,
    summary = excluded.summary,
    status = excluded.status,
    source_ref = excluded.source_ref,
    correlation_id = excluded.correlation_id,
    metadata_json = excluded.metadata_json;
  ```
- Re-processing the same message/event updates the existing record without generating duplicate entries.

## Privacy & Security Guardrails
1. **Concise Summaries**: Only normalized executive summaries are stored.
2. **Zero Secrets**: Credentials, OAuth tokens, and authorization headers are never persisted.
3. **No Unprocessed Communications Dumps**: Message bodies are stripped and clipped before persistence.
4. **Git Safety**: `lysops.db` and runtime artifacts are ignored via `.gitignore`.
