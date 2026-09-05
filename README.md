# LysOps — Personal Operations & Executive Automation Suite

[![n8n](https://img.shields.io/badge/Orchestrator-n8n-EA4B71?logo=n8n&logoColor=white)](https://n8n.io)
[![Docker](https://img.shields.io/badge/Container-Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Google Gemini](https://img.shields.io/badge/AI-Google%20Gemini-4285F4?logo=google&logoColor=white)](https://ai.google.dev/)
[![Telegram](https://img.shields.io/badge/Channel-Telegram-26A5E4?logo=telegram&logoColor=white)](https://telegram.org/)

**LysOps** is a privacy-first, event-driven personal operations system hosted locally on Docker/WSL2. It acts as an autonomous Chief of Staff and Executive Operations Assistant—synthesizing daily schedules, prioritizing actionable emails, triaging real-time chat messages, and delivering synchronized executive briefs directly to Telegram.

---

## Architecture Overview

```mermaid
flowchart TD
    subgraph Inputs["Inbound Context & Streams"]
        GC[("Google Calendar\n(Today's Agenda)")]
        GM[("Gmail\n(Actionable / Last 24h)")]
        ZB[("Zalo Bridge\n(Local Webhook)")]
    end

    subgraph Core["LysOps Core Engine (n8n on Docker)"]
        direction TB
        
        subgraph Triage["MSG / Zalo Realtime Engine"]
            Z1["ZALO-01: Hourly Personal Triage\n- Intent classification (4 lanes)\n- Case linking & state store\n- Urgent & Human-required alerts"]
            Z2["ZALO-02: Stakeholder Router\n- MyLove realtime alerts & digest"]
        end

        subgraph Brief["OPS / Daily Synthesis Engine"]
            O1["OPS-01: Morning Operating Brief\n(Daily 07:30 Asia/Ho_Chi_Minh)\n- Context normalization\n- Google Gemini synthesis\n- Attention compression"]
        end

        subgraph Safeguards["Reliability & Observability"]
            S1["SYS-01: Global Failure Handler\n(Catches any workflow failure)"]
            T1["TEST-01: Failure Verification Test"]
        end
    end

    subgraph LLM["AI Model Layer"]
        GEM["Google Gemini 3.1 Flash Lite\n(Low-latency reasoning & synthesis)"]
    end

    subgraph Outputs["Executive Delivery"]
        TG[("Telegram (LysOpsBot)\n- Morning Brief\n- Urgent Alerts\n- Hourly Digest\n- Failure Alarms")]
    end

    GC -->|Read-only query| O1
    GM -->|Read-only query| O1
    ZB -->|Webhook POST| Z1
    ZB -->|Webhook POST| Z2
    Z1 -.->|Triage state digest| O1

    O1 <-->|Structured Prompting| GEM
    
    O1 -->|Formatted HTML Brief| TG
    Z1 -->|Immediate Alert / Hourly Digest| TG
    Z2 -->|Prioritized Route| TG
    Core -.->|On Error Trigger| S1
    S1 -->|Incident Alarm| TG
```

---

## Core Workflows

| Identifier | Workflow Name | Trigger | Primary Purpose |
| :--- | :--- | :--- | :--- |
| **`OPS-01`** | **Morning Operating Brief** | `Cron (07:30 ICT daily)` | Aggregates Calendar, actionable Gmail, and communications triage into an executive daily briefing with top 3 priorities and noise suppression metrics. |
| **`ZALO-01`** | **Hourly Personal Communications Triage** | `Webhook` & `Hourly Cron` | Classifies incoming chat streams into 4 action lanes, tracks cases, issues immediate alerts for human decisions, and compiles an hourly digest. |
| **`ZALO-02`** | **MyLove Realtime Alert & Digest Router** | `Webhook` | Specialized router ensuring high-priority visibility for critical stakeholder conversations without information loss. |
| **`SYS-01`** | **Global Workflow Failure Handler** | `Error Trigger (Instance-wide)` | Intercepts workflow failures across n8n, extracts node stack traces and execution URLs, and dispatches incident alarms to Telegram. |
| **`TEST-01`** | **Failure Handler Test** | `Manual` | Synthetic failure trigger used to verify error alerting and Telegram dispatch pipelines end-to-end. |

---

## Key Design & Safety Principles

### 1. Strictly Read-Only Operations
`OPS-01` operates under strict zero-mutation constraints:
- **No Email Writes**: Never sends, forwards, or replies to emails.
- **No Calendar Mutating**: Never creates, reschedules, or deletes calendar entries.
- **No Chat Automated Replies**: Never impersonates the user on chat channels or executes unapproved financial or approval transactions.

### 2. Four-Lane Communications Triage
Inbound messages in `ZALO-01` are dynamically routed into strict operational lanes:
- `🔴 HUMAN-REQUIRED`: Polls, approvals, agreements, and financial decisions that strictly require the user's manual action.
- `🟡 AUTO-HANDLE`: Maintenance incidents, procurement tracking, senior assignments, and worker reports tracked into persistent cases.
- `✍️ DRAFT-FOR-YOU`: Casual inquiries and questions where suggested draft responses are generated for one-click user review.
- `🔕 IGNORE-DIGEST`: Low-signal background chatter, promotional messages, and non-actionable chatter automatically filtered from immediate view.

### 3. Unified Visual & Linguistic Identity
All Telegram dispatches share a consistent executive visual standard:
- **Badge Headers**: `🌅 MORNING OPS`, `🚨 ZALO TRIAGE`, `📬 ZALO BRIEF`, `🚨 WORKFLOW FAILED`.
- **Status Pills**: Fast at-a-glance counters (`📅 X lịch • 🔴 X cần bạn • 🟡 X quyết định / theo dõi • 🔕 X lọc`).
- **Telegram HTML Formatting**: Sanitized HTML (`<b>`, `<i>`, `<code>`) avoiding Markdown parsing conflicts with email addresses (`<user@domain>`) or mathematical symbols.

---

## Repository Structure

```
LysOps/
├── README.md                                  # Project overview and system documentation
├── .gitignore                                 # Ignores credentials, runtime state, and environment files
└── workflows/
    ├── OPS-01_morning_operating_brief.json    # Morning Operating Brief workflow definition
    ├── SYS-01_global_failure_handler.json     # Global error handling workflow definition
    ├── TEST-01_failure_test.json              # Synthetic failure test workflow
    ├── ZALO-01_hourly_triage.json             # Hourly communications triage workflow
    └── ZALO-02_mylove_alerts.json             # Dedicated stakeholder alert router
```

---

## Local Development & Operations

### Prerequisites
- Docker & Docker Compose on Linux / WSL2
- n8n v1.80+ container (`n8n-dev`)
- Local chat bridge container (`zalo-bridge` on port 5680)

### Configured Credentials
- **Telegram Bot API**: `LysOpsBot` (Chat ID: `8909610365`)
- **Google Gemini API**: Configured for `models/gemini-3.1-flash-lite`
- **Google Calendar OAuth2**: Read-only scope (`https://www.googleapis.com/auth/calendar.readonly`)
- **Gmail OAuth2**: Read-only scope (`https://www.googleapis.com/auth/gmail.readonly`)

### Running Workflows via CLI
When executing workflows via the n8n CLI inside the container, isolate the Task Broker port to prevent collision with the running server instance:

```bash
docker exec -e N8N_RUNNERS_BROKER_PORT=5699 n8n-dev n8n execute --id=OPS01MORNINGv1
```