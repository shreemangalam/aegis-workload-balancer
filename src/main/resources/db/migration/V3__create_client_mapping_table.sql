-- V3: Create client_mapping table
-- Maps clients to their primary and secondary developers.
-- Also captures the environment (DEV/QA/PROD) because the same client
-- can have different owners per environment.

CREATE TABLE client_mapping (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    client_name         VARCHAR(200) NOT NULL,
    -- Must match exactly the company name field in SNOW incidents.
    -- This is how Aegis connects a ticket to a developer.

    environment         VARCHAR(20) NOT NULL DEFAULT 'PROD'
                        CHECK (environment IN ('DEV', 'QA', 'PROD')),
    -- Same client can have different owners per environment.
    -- A junior dev might own DEV, senior owns PROD.

    primary_dev_id      UUID NOT NULL,
    -- First developer evaluated for this client's tickets.

    secondary_dev_id    UUID,
    -- Optional fallback developer.
    -- NULL means no secondary — goes straight to overflow if primary is unavailable.
    -- Notice: NO foreign key constraint here intentionally.
    -- Reason: secondary is optional. A FK with NULL allowed is fine technically,
    -- but we keep it simple and validate in Java instead.

    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_client_primary_dev
        FOREIGN KEY (primary_dev_id)
        REFERENCES developers(id),

    CONSTRAINT uq_client_environment
        UNIQUE (client_name, environment)
    -- A client+environment combination can only have ONE mapping.
    -- Prevents duplicate entries for the same client in the same environment.
    -- The DB enforces this — not just our Java code.
);

CREATE INDEX idx_client_mapping_name ON client_mapping(client_name);
CREATE INDEX idx_client_mapping_primary ON client_mapping(primary_dev_id);