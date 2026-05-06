-- V5: Create processed_tickets table
-- The idempotency cache.
-- Prevents the same ticket from being processed twice across poll cycles.
-- This is the most important safety table in the entire system.

CREATE TABLE processed_tickets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    ticket_id       VARCHAR(50) NOT NULL UNIQUE,
    -- The sys_id from SNOW.
    -- UNIQUE constraint is the actual enforcement mechanism.
    -- Even if our Java code has a bug and tries to insert the same ticket twice,
    -- the DB rejects the second insert with a constraint violation.
    -- Application-level checks are optimistic — this constraint is the guarantee.

    status          VARCHAR(30) NOT NULL
                    CHECK (status IN (
                        'ASSIGNED',
                        'CAPACITY_OVERFLOW',
                        'KEYWORD_MISMATCH',
                        'NO_CLIENT_MAPPING',
                        'DRY_RUN'
                    )),
    -- Why processing stopped for this ticket.
    -- Mirrors reason_code in assignment_audit.

    processed_at    TIMESTAMP NOT NULL DEFAULT NOW()
    -- When this ticket was processed.
    -- Used for TTL cleanup — we can delete records older than 30 days
    -- since SNOW tickets that old are closed anyway.
);

-- This index makes the idempotency check extremely fast.
-- Every poll cycle, before processing any ticket, we run:
-- SELECT 1 FROM processed_tickets WHERE ticket_id = ?
-- This index makes that lookup O(log n) instead of O(n).
CREATE INDEX idx_processed_ticket_id ON processed_tickets(ticket_id);