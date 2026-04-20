-- =============================================================================
-- FILE: 01_original_schema.sql
-- PURPOSE: Creates the original (pre-normalization) schema and seeds it with
--          the sample data from the assessment result set.
-- RUN: mysql -u root -p < 01_original_schema.sql
-- =============================================================================

CREATE DATABASE IF NOT EXISTS por_assessment;
USE por_assessment;

-- -----------------------------------------------------------------------------
-- Drop tables if they exist (safe re-run)
-- Disable FK checks temporarily so tables can be dropped in any order
-- -----------------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS user_skills;
DROP TABLE IF EXISTS user;
DROP TABLE IF EXISTS companies;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS jobs;
DROP TABLE IF EXISTS user_accounts;
SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- TABLE: user
-- Assumed structure based on the result set returning user_firstname / user_lastname
-- -----------------------------------------------------------------------------
CREATE TABLE user (
    user_id         INT(11)      NOT NULL AUTO_INCREMENT,
    user_firstname  VARCHAR(255) NULL,
    user_lastname   VARCHAR(255) NULL,
    email           VARCHAR(255) NULL,
    created_at      DATETIME     NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id)
);

-- -----------------------------------------------------------------------------
-- TABLE: user_skills (original — skill_name stored as raw string, denormalized)
-- -----------------------------------------------------------------------------
CREATE TABLE user_skills (
    user_skill_id            INT(11)      NOT NULL AUTO_INCREMENT,
    user_skill_last_modified TIMESTAMP    NULL,
    user_skill_date_created  DATETIME     NULL DEFAULT CURRENT_TIMESTAMP,
    user_id                  INT(11)      NULL,
    skill_name               CHAR(255)    NULL,
    skill_level              CHAR(255)    NULL,
    skill_usage              CHAR(255)    NULL,
    skill_last_used          CHAR(255)    NULL,
    user_skill_endorsed      TINYINT(1)   NULL DEFAULT 0,
    PRIMARY KEY (user_skill_id),
    CONSTRAINT fk_user_skills_user FOREIGN KEY (user_id) REFERENCES user(user_id)
);

-- -----------------------------------------------------------------------------
-- TABLE: companies (referenced by MySQL Q3 optimization query)
-- -----------------------------------------------------------------------------
CREATE TABLE companies (
    companyid       INT(11)      NOT NULL AUTO_INCREMENT,
    company_name    VARCHAR(255) NULL,
    company_email   VARCHAR(255) NULL,
    PRIMARY KEY (companyid)
);

-- -----------------------------------------------------------------------------
-- TABLE: users (referenced by MySQL Q3 optimization query — note: different
--         from the 'user' table above; the assessment query uses 'users')
-- -----------------------------------------------------------------------------
CREATE TABLE users (
    userid          INT(11)      NOT NULL AUTO_INCREMENT,
    companyid       INT(11)      NULL,
    username        VARCHAR(255) NULL,
    PRIMARY KEY (userid),
    CONSTRAINT fk_users_company FOREIGN KEY (companyid) REFERENCES companies(companyid)
);

-- -----------------------------------------------------------------------------
-- TABLE: jobs (referenced by MySQL Q3 optimization query)
-- -----------------------------------------------------------------------------
CREATE TABLE jobs (
    jobid           INT(11)      NOT NULL AUTO_INCREMENT,
    userid          INT(11)      NULL,
    job_title       VARCHAR(255) NULL,
    PRIMARY KEY (jobid),
    CONSTRAINT fk_jobs_user FOREIGN KEY (userid) REFERENCES users(userid)
);

-- -----------------------------------------------------------------------------
-- TABLE: user_accounts (referenced by MySQL Q3 optimization query)
-- -----------------------------------------------------------------------------
CREATE TABLE user_accounts (
    accountid       INT(11)      NOT NULL AUTO_INCREMENT,
    userid          INT(11)      NULL,
    account_type    VARCHAR(100) NULL,
    PRIMARY KEY (accountid),
    CONSTRAINT fk_user_accounts_user FOREIGN KEY (userid) REFERENCES users(userid)
);

-- -----------------------------------------------------------------------------
-- SEED DATA: user
-- -----------------------------------------------------------------------------
INSERT INTO user (user_firstname, user_lastname, email) VALUES
    ('Kim', 'Simpson', 'kim.simpson@example.com');

-- -----------------------------------------------------------------------------
-- SEED DATA: user_skills
-- Matches the 10-row result set from the assessment exactly
-- -----------------------------------------------------------------------------
INSERT INTO user_skills (user_id, skill_name, skill_level, skill_usage, skill_last_used, user_skill_endorsed)
SELECT
    u.user_id,
    s.skill_name,
    'Intermediate',
    'Regular',
    '2025',
    0
FROM user u
CROSS JOIN (
    SELECT 'PHP 7.1'           AS skill_name UNION ALL
    SELECT 'AWS Lambda'                       UNION ALL
    SELECT 'AngularJS'                        UNION ALL
    SELECT 'Angular'                          UNION ALL
    SELECT 'Accounting/Billing'               UNION ALL
    SELECT 'Python'                           UNION ALL
    SELECT 'SQL'                              UNION ALL
    SELECT 'Typescript'                       UNION ALL
    SELECT 'OO Programming'                   UNION ALL
    SELECT 'SCSS'
) s
WHERE u.user_firstname = 'Kim' AND u.user_lastname = 'Simpson';

-- -----------------------------------------------------------------------------
-- SEED DATA: companies, users, jobs, user_accounts (for Q3 optimization query)
-- -----------------------------------------------------------------------------
INSERT INTO companies (company_name, company_email) VALUES
    ('Acme Corp', 'contact@acme.com'),
    ('Globex Inc', 'contact@globex.com');

INSERT INTO users (companyid, username) VALUES
    (1, 'jdoe'),
    (2, 'jsmith');

INSERT INTO jobs (userid, job_title) VALUES
    (1, 'Software Engineer'),
    (1, 'Tech Lead'),
    (2, 'Product Manager');

INSERT INTO user_accounts (userid, account_type) VALUES
    (1, 'standard'),
    (2, 'premium');

-- -----------------------------------------------------------------------------
-- VERIFY: Should return 10 rows matching the assessment result set
-- -----------------------------------------------------------------------------
SELECT
    u.user_firstname,
    u.user_lastname,
    us.skill_name
FROM user u
JOIN user_skills us ON u.user_id = us.user_id
WHERE u.user_firstname = 'Kim'
  AND u.user_lastname  = 'Simpson';