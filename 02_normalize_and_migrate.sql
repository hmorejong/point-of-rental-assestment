-- =============================================================================
-- FILE: 02_normalize_and_migrate.sql
-- PURPOSE: Normalizes the user_skills table by extracting skill_name into its
--          own 'skill' table, migrating existing data, and adding indexes to
--          optimize the Q3 JOIN query.
-- RUN: mysql -u root -p < 02_normalize_and_migrate.sql
--      (Run AFTER 01_original_schema.sql)
-- =============================================================================

USE por_assessment;

-- =============================================================================
-- STEP 1: Create the new normalized skill table
-- =============================================================================
CREATE TABLE IF NOT EXISTS skill (
    skill_id    INT(11)      NOT NULL AUTO_INCREMENT,
    skill_name  VARCHAR(255) NOT NULL,
    PRIMARY KEY (skill_id),
    UNIQUE KEY uq_skill_name (skill_name)
);

-- =============================================================================
-- STEP 2: Populate skill table from distinct values in user_skills
-- Deduplicates automatically via INSERT IGNORE + UNIQUE constraint
-- =============================================================================
INSERT IGNORE INTO skill (skill_name)
SELECT DISTINCT skill_name
FROM user_skills
WHERE skill_name IS NOT NULL
ORDER BY skill_name;

-- Verify — should show all unique skills
SELECT * FROM skill;

-- =============================================================================
-- STEP 3: Add skill_id foreign key column to user_skills
-- =============================================================================
ALTER TABLE user_skills
    ADD COLUMN skill_id INT(11) NULL AFTER user_id;

-- =============================================================================
-- STEP 4: Backfill skill_id from the new skill table
-- =============================================================================
UPDATE user_skills us
JOIN skill s ON s.skill_name = us.skill_name
SET us.skill_id = s.skill_id;

-- =============================================================================
-- STEP 5: Enforce NOT NULL and add the foreign key constraint
-- =============================================================================
ALTER TABLE user_skills
    MODIFY COLUMN skill_id INT(11) NOT NULL,
    ADD CONSTRAINT fk_user_skills_skill
        FOREIGN KEY (skill_id) REFERENCES skill(skill_id);

-- =============================================================================
-- STEP 6: Drop the now-redundant skill_name column
-- All data is preserved in the skill table via skill_id
-- =============================================================================
ALTER TABLE user_skills
    DROP COLUMN skill_name;

-- =============================================================================
-- STEP 7: Verify migration — result should still match the original 10-row
--         result set from the assessment
-- =============================================================================
SELECT
    u.user_firstname,
    u.user_lastname,
    s.skill_name
FROM user u
JOIN user_skills us ON u.user_id  = us.user_id
JOIN skill s       ON us.skill_id = s.skill_id
WHERE u.user_firstname = 'Kim'
  AND u.user_lastname  = 'Simpson';

-- =============================================================================
-- STEP 8: Optimizations for the Q3 JOIN query
--
-- Original query:
--   SELECT c.* FROM companies AS c
--   JOIN users AS u USING(companyid)
--   JOIN jobs AS j USING(userid)
--   JOIN user_accounts AS ua USING(userid)
--   WHERE j.jobid = 123;
-- =============================================================================

-- Index on users.companyid — speeds up the companies -> users JOIN
ALTER TABLE users
    ADD INDEX idx_users_companyid (companyid);

-- Index on jobs.userid — speeds up the users -> jobs JOIN
ALTER TABLE jobs
    ADD INDEX idx_jobs_userid (userid);

-- Index on jobs.jobid — speeds up the WHERE j.jobid = 123 filter
ALTER TABLE jobs
    ADD INDEX idx_jobs_jobid (jobid);

-- Index on user_accounts.userid — speeds up the users -> user_accounts JOIN
ALTER TABLE user_accounts
    ADD INDEX idx_user_accounts_userid (userid);

-- =============================================================================
-- STEP 9: Verify optimized Q3 query plan
-- EXPLAIN shows whether the new indexes are being picked up
-- =============================================================================
EXPLAIN
SELECT c.*
FROM jobs AS j
JOIN users AS u         ON u.userid    = j.userid
JOIN user_accounts AS ua ON ua.userid   = j.userid
JOIN companies AS c     ON c.companyid = u.companyid
WHERE j.jobid = 1;

-- =============================================================================
-- FINAL STATE SUMMARY
-- =============================================================================
-- Tables:
--   user              — unchanged
--   skill             — NEW: normalized skill name lookup
--   user_skills        — MODIFIED: skill_name replaced by skill_id (FK)
--   companies         — MODIFIED: indexes added
--   users             — MODIFIED: indexes added
--   jobs              — MODIFIED: indexes added
--   user_accounts      — MODIFIED: indexes added
-- =============================================================================