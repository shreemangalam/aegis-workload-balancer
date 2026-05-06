-- V4: Create assignment_audit table
-- Immutable record of every decision Aegis makes.
-- "Immutable" means: once written, never updated.
-- This is the append-only log — same pattern used in financial ledgers.

CREATE TABLE assignment_audit (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    ticket_id               VARCHAR(50) NOT NULL,
    -- The INC number from SNOW. Example: INC0012345

    assigned_to             UUID,
    -- Developer who received the ticket.
    -- NULL if no eligible developer was found (CAPACITY_OVERFLOW).
    -- Foreign key but nullable — not every audit record has an assignment.

    ticket_score            INTEGER NOT NULL,
    -- T_s at the time of this decision.
    -- Preserved permanently — even if scoring weights change later,
    -- we know exactly what score was used for this specific assignment.

    dev_load_at_assignment  INTEGER,
    -- D_L of the selected developer at the moment of assignment.
    -- Snapshot in time — shows how loaded they were when they got the ticket.

    reason_code             VARCHAR(50) NOT NULL
                            CHECK (reason_code IN (
                                'ASSIGNED',
                                'CAPACITY_OVERFLOW',
                                'KEYWORD_MISMATCH',
                                'NO_CLIENT_MAPPING',
                                'DRY_RUN'
                            )),
    -- Why did this outcome happen?
    -- ASSIGNED          = successful assignment
    -- CAPACITY_OVERFLOW = all candidates exceeded max_capacity
    -- KEYWORD_MISMATCH  = no candidate had matching keywords
    -- NO_CLIENT_MAPPING = ticket's client not found in our DB
    -- DRY_RUN           = dry run mode, no actual assignment made

    evaluated_devs          JSONB,
    -- The full decision snapshot.
    -- Array of every developer evaluated with:
    -- { "dev_id": "...", "name": "...", "dl": 22, "passed": false, "eliminated_by": "CAPACITY" }
    -- JSONB = binary JSON in PostgreSQL. Queryable, indexable, flexible.
    -- We use JSONB instead of separate audit_detail rows because
    -- the evaluation snapshot is a single atomic record — not relational data.

    stale_data_warning      BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE if impl_weight_updated_at was older than 7 days at assignment time.
    -- Flags assignments made with potentially outdated capacity data.

    created_at              TIMESTAMP NOT NULL DEFAULT NOW()
    -- No updated_at — audit records are NEVER modified.
    -- If we need to correct something, we write a NEW record.
    -- The old one stays forever. This is auditability by design.
);

-- Index on ticket_id — most common query is "show me the audit for INC0012345"
CREATE INDEX idx_audit_ticket_id ON assignment_audit(ticket_id);

-- Index on assigned_to — "show me all tickets assigned to this developer"
CREATE INDEX idx_audit_assigned_to ON assignment_audit(assigned_to);

-- Index on created_at — for date range queries in the dashboard
CREATE INDEX idx_audit_created_at ON assignment_audit(created_at);