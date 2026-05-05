-- V2: Create developer_expertise table
-- This table is the solution to ticket bouncing.
-- Each row is one keyword a developer owns.
-- The assignment engine scans ticket descriptions against these keywords
-- before assigning — ensuring only the right person gets each ticket.

CREATE TABLE developer_expertise (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    dev_id      UUID NOT NULL,
    -- Foreign key to developers table.
    -- We know which developer owns this keyword.

    keyword     VARCHAR(200) NOT NULL,
    -- The actual keyword: iFlow name, package name, system identifier.
    -- Examples: "Order_Sync_CPI", "S4HANA_Finance", "RFC_ECC_Module"
    -- Case-insensitive matching will be done in Java, not SQL.

    category    VARCHAR(50) NOT NULL CHECK (category IN ('IFLOW', 'PACKAGE', 'SYSTEM', 'CLIENT')),
    -- IFLOW   = specific iFlow name they built/maintain
    -- PACKAGE = SAP package they own
    -- SYSTEM  = backend system they know (S4HANA, ECC, Salesforce)
    -- CLIENT  = client name shorthand

    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_expertise_developer
        FOREIGN KEY (dev_id)
        REFERENCES developers(id)
        ON DELETE CASCADE
    -- ON DELETE CASCADE means: if a developer is deleted,
    -- all their expertise keywords are deleted too.
    -- No orphaned keywords left behind.
);

-- Index on dev_id because we always fetch keywords BY developer.
CREATE INDEX idx_expertise_dev_id ON developer_expertise(dev_id);

-- Index on keyword for the matching query:
-- SELECT * FROM developer_expertise WHERE LOWER(keyword) = LOWER(?)
CREATE INDEX idx_expertise_keyword ON developer_expertise(keyword);