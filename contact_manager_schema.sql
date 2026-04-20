-- =============================================================================
-- FILE: contact_manager_schema.sql
-- PURPOSE: Creates the contact manager database schema as described in the
--          Design and Planning section of the developer assessment.
--          Import into PHPStorm (Database tool) to auto-generate the ERD.
-- RUN: mysql -u root -p < contact_manager_schema.sql
-- =============================================================================

CREATE DATABASE IF NOT EXISTS contact_manager
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE contact_manager;

-- -----------------------------------------------------------------------------
-- Drop tables in reverse dependency order (safe re-run)
-- -----------------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS contact_blocks;
DROP TABLE IF EXISTS contact_postal_addresses;
DROP TABLE IF EXISTS contact_email_addresses;
DROP TABLE IF EXISTS contact_phone_numbers;
DROP TABLE IF EXISTS contacts;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- TABLE: users
-- Registered users of the system. Users can log in, manage their own contact
-- list, and appear as contacts for other users.
-- =============================================================================
CREATE TABLE users (
    user_id         INT(11)         NOT NULL AUTO_INCREMENT,
    email           VARCHAR(255)    NOT NULL,
    password_hash   VARCHAR(255)    NOT NULL,
    first_name      VARCHAR(100)    NULL,
    last_name       VARCHAR(100)    NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_users_email (email)
);

-- =============================================================================
-- TABLE: contacts
-- A contact belongs to an owner (the user who created it). If the contact is
-- a registered user of the system, linked_user_id is populated. If the contact
-- is an external non-user, linked_user_id is NULL.
-- =============================================================================
CREATE TABLE contacts (
    contact_id      INT(11)         NOT NULL AUTO_INCREMENT,
    owner_user_id   INT(11)         NOT NULL,
    linked_user_id  INT(11)         NULL,
    first_name      VARCHAR(100)    NULL,
    last_name       VARCHAR(100)    NULL,
    note            TEXT            NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (contact_id),
    CONSTRAINT fk_contacts_owner
        FOREIGN KEY (owner_user_id) REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_contacts_linked_user
        FOREIGN KEY (linked_user_id) REFERENCES users(user_id)
        ON DELETE SET NULL,
    INDEX idx_contacts_owner_user_id (owner_user_id),
    INDEX idx_contacts_linked_user_id (linked_user_id),
    UNIQUE KEY uq_contacts_owner_linked_user (owner_user_id, linked_user_id)
);

-- =============================================================================
-- TABLE: contact_phone_numbers
-- An unlimited number of phone numbers per contact, each with a type label
-- (home, cell, fax, work, etc.)
-- =============================================================================
CREATE TABLE contact_phone_numbers (
    phone_id        INT(11)         NOT NULL AUTO_INCREMENT,
    contact_id      INT(11)         NOT NULL,
    phone_type      VARCHAR(50)     NOT NULL DEFAULT 'cell',
    phone_number    VARCHAR(30)     NOT NULL,
    PRIMARY KEY (phone_id),
    CONSTRAINT fk_phone_numbers_contact
        FOREIGN KEY (contact_id) REFERENCES contacts(contact_id)
        ON DELETE CASCADE,
    INDEX idx_phone_numbers_contact_id (contact_id),
    UNIQUE KEY uq_contact_phone (contact_id, phone_type, phone_number)
);

-- =============================================================================
-- TABLE: contact_email_addresses
-- An unlimited number of email addresses per contact.
-- =============================================================================
CREATE TABLE contact_email_addresses (
    email_id        INT(11)         NOT NULL AUTO_INCREMENT,
    contact_id      INT(11)         NOT NULL,
    email_address   VARCHAR(255)    NOT NULL,
    PRIMARY KEY (email_id),
    CONSTRAINT fk_email_addresses_contact
        FOREIGN KEY (contact_id) REFERENCES contacts(contact_id)
        ON DELETE CASCADE,
    INDEX idx_email_addresses_contact_id (contact_id),
    UNIQUE KEY uq_contact_email (contact_id, email_address)
);

-- =============================================================================
-- TABLE: contact_postal_addresses
-- An unlimited number of postal addresses per contact, each with a type label
-- (home, business, billing, etc.)
-- =============================================================================
CREATE TABLE contact_postal_addresses (
    address_id      INT(11)         NOT NULL AUTO_INCREMENT,
    contact_id      INT(11)         NOT NULL,
    address_type    VARCHAR(50)     NOT NULL DEFAULT 'home',
    street_line_1   VARCHAR(255)    NULL,
    street_line_2   VARCHAR(255)    NULL,
    city            VARCHAR(100)    NULL,
    state           VARCHAR(100)    NULL,
    postal_code     VARCHAR(20)     NULL,
    country         VARCHAR(100)    NULL DEFAULT 'US',
    PRIMARY KEY (address_id),
    CONSTRAINT fk_postal_addresses_contact
        FOREIGN KEY (contact_id) REFERENCES contacts(contact_id)
        ON DELETE CASCADE,
    INDEX idx_postal_addresses_contact_id (contact_id)
);

-- =============================================================================
-- TABLE: contact_blocks
-- Controls who can add a given user as a contact.
--
-- Two modes:
--   blocker_user_id IS NULL     → the user has blocked ALL other users
--   blocker_user_id IS NOT NULL → the user has blocked only that specific user
--
-- Example:
--   blocked_user_id=5, blocker_user_id=NULL   → user 5 blocks everyone
--   blocked_user_id=5, blocker_user_id=12     → user 5 blocks only user 12
-- =============================================================================
CREATE TABLE contact_blocks (
    block_id            INT(11)     NOT NULL AUTO_INCREMENT,
    blocked_user_id     INT(11)     NOT NULL,
    blocker_user_id     INT(11)     NULL,
    created_at          DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (block_id),
    CONSTRAINT fk_blocks_blocked_user
        FOREIGN KEY (blocked_user_id) REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_blocks_blocker_user
        FOREIGN KEY (blocker_user_id) REFERENCES users(user_id)
        ON DELETE CASCADE,
    UNIQUE KEY uq_block (blocked_user_id, blocker_user_id),
    INDEX idx_blocks_blocked_user_id (blocked_user_id),
    INDEX idx_blocks_blocker_user_id (blocker_user_id)
);

-- =============================================================================
-- SEED DATA: a few users and contacts to verify relationships in the ERD
-- =============================================================================

INSERT INTO users (email, password_hash, first_name, last_name) VALUES
    ('alice@example.com', 'hashed_pw_1', 'Alice', 'Johnson'),
    ('bob@example.com',   'hashed_pw_2', 'Bob',   'Smith'),
    ('carol@example.com', 'hashed_pw_3', 'Carol', 'Williams');

-- Alice adds Bob (a registered user) and an external contact
INSERT INTO contacts (owner_user_id, linked_user_id, first_name, last_name, note) VALUES
    (1, 2, 'Bob',   'Smith',    'Met at conference 2024'),
    (1, NULL, 'Jane', 'Doe',   'External supplier contact');

-- Bob adds Alice
INSERT INTO contacts (owner_user_id, linked_user_id, first_name, last_name, note) VALUES
    (2, 1, 'Alice', 'Johnson', 'Project collaborator');

-- Phone numbers
INSERT INTO contact_phone_numbers (contact_id, phone_type, phone_number) VALUES
    (1, 'cell', '(786) 342-9173'),
    (1, 'work', '(305) 814-6227'),
    (1, 'fax',  '(305) 921-4855'),
    (2, 'home', '(954) 673-0481'),
    (2, 'fax',  '(954) 512-3076'),
    (3, 'fax',  '(239) 748-6193');

-- Email addresses
INSERT INTO contact_email_addresses (contact_id, email_address) VALUES
    (1, 'bob@example.com'),
    (1, 'bob.work@company.com'),
    (2, 'jane.doe@supplier.com');

-- Postal addresses
INSERT INTO contact_postal_addresses (
    contact_id,
    address_type,
    street_line_1,
    street_line_2,
    city,
    state,
    postal_code,
    country
) VALUES
    (1, 'home',     '123 Main St',    NULL, 'Cape Coral', 'FL', '33904', 'US'),
    (2, 'business', '456 Market Ave', NULL, 'Miami',      'FL', '33101', 'US');

-- Carol blocks Alice from adding her as a contact
INSERT INTO contact_blocks (blocked_user_id, blocker_user_id) VALUES
    (3, 1);

-- Bob blocks all users from adding him
INSERT INTO contact_blocks (blocked_user_id, blocker_user_id) VALUES
    (2, NULL);

-- =============================================================================
-- VERIFY: Show all contacts with their owner and linked user info
-- =============================================================================
SELECT
    u.email                         AS owner_email,
    c.first_name,
    c.last_name,
    lu.email                        AS linked_user_email,
    c.note
FROM contacts c
JOIN users u            ON u.user_id  = c.owner_user_id
LEFT JOIN users lu      ON lu.user_id = c.linked_user_id
ORDER BY c.owner_user_id, c.contact_id;
