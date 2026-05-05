-- V1: Create developers table
-- This is the core entity of Aegis.
-- Stores every developer's profile, capacity, and current load state.

CREATE TABLE developers (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- UUID instead of auto-increment integer.
    -- Reason: UUIDs are safe to expose in APIs (no sequential guessing).
    -- gen_random_uuid() generates a new UUID automatically on insert.

    snow_user_id            VARCHAR(100) NOT NULL UNIQUE,
    -- The developer's sys_id in ServiceNow.
    -- UNIQUE because one SNOW user maps to exactly one developer profile.
    -- NOT NULL because without this we cannot write assignments back to SNOW.

    name                    VARCHAR(100) NOT NULL,
    -- Display name shown on the dashboard.

    skill_tier              INTEGER NOT NULL CHECK (skill_tier IN (1, 2, 3)),
    -- 1 = Junior, 2 = Mid, 3 = Senior.
    -- CHECK constraint enforces only valid values at the database level.
    -- Even if our Java code has a bug, the DB rejects invalid tiers.

    max_capacity            INTEGER NOT NULL DEFAULT 30,
    -- Maximum load points before overflow triggers.
    -- DEFAULT 30 means if not specified, 30 is assumed.

    load_mode               VARCHAR(20) NOT NULL DEFAULT 'NORMAL'
                            CHECK (load_mode IN ('NORMAL', 'ELEVATED', 'CRITICAL')),
    -- Self-reported by developer. Affects impl_weight multiplier.
    -- CHECK constraint same reasoning as skill_tier above.

    impl_weight             INTEGER NOT NULL DEFAULT 0,
    -- Points assigned to current implementation project.
    -- Set by manager. 0 means no active implementation project.

    impl_weight_updated_at  TIMESTAMP,
    -- When impl_weight was last updated.
    -- NULL means it was never set (new developer, no project yet).
    -- Used for confidence decay — if stale by 7+ days, flag the assignment.

    version                 INTEGER NOT NULL DEFAULT 0,
    -- JPA optimistic locking field.
    -- Every time this row is updated, version increments by 1.
    -- If two threads read version=5 and both try to update,
    -- the second one fails because version is now 6, not 5.
    -- This prevents race conditions without table-level locks.

    created_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP NOT NULL DEFAULT NOW()
    -- Standard audit timestamps. NOW() sets them automatically on insert.
);

-- Index on snow_user_id because we look up developers by their SNOW ID
-- every time we process a ticket assignment.
-- Without this index, PostgreSQL scans the entire table for every lookup.
CREATE INDEX idx_developers_snow_user_id ON developers(snow_user_id);

-- Index on skill_tier because the assignment engine filters by tier
-- on every single ticket evaluation.
CREATE INDEX idx_developers_skill_tier ON developers(skill_tier);