# Point of Rental Assessment

Assessment workspace including database design (ERD + SQL), and refactoring exercises in PHP and JavaScript.

## Project Files

### 🛢️ `01_original_schema.sql`

- Baseline SQL script for the assessment's original (pre-normalized) model.
- Creates and seeds the `por_assessment` database with:
  - `user` + denormalized `user_skills` (`skill_name` stored as text)
  - `companies`, `users`, `jobs`, and `user_accounts` for the join-optimization scenario
- Enforces `user_skills.user_id` as `NOT NULL` with `fk_user_skills_user`.
- Includes a verification query that reproduces the expected Kim Simpson result set.

---

### 🛢️ `02_normalize_and_migrate.sql`

- Follow-up migration script (run after `01_original_schema.sql`).
- Normalizes `skill_name` into a separate `skill` lookup table and backfills `user_skills.skill_id`.
- Enforces:
  - `user_skills.user_id` and `user_skills.skill_id` as `NOT NULL`
  - `uq_user_skill` on `(user_id, skill_id)` to prevent duplicates
  - `fk_user_skills_skill` foreign key to `skill(skill_id)`
- Adds indexes and includes `EXPLAIN` verification for query optimization.

---

### 🛢️ `contact_manager_schema.sql`

- MySQL schema for a contact manager system.
- Includes tables, foreign keys, indexes, constraints, and seed data.
- Designed to generate an ERD via PHPStorm or similar tools.

---

### 🐘 `order_by_clause_builder_refactored.php`

- PHP function `generate()` that builds an SQL `ORDER BY` clause.
- Supports two input formats:
  - associative: `['Method' => 'DESC']`
  - shorthand indexed: `['CreatedDate', '-FieldValue']`
- Applies a whitelist mapping (`$included_columns`).

---

### 🐘 `order_by_clause_builder_refactored_test.php`

- Standalone CLI test runner for the PHP implementation.
- Covers:
  - mixed input formats
  - duplicate prevention
  - shorthand parsing
  - invalid criteria handling
  - empty input behavior

---

### 🟨 `listener_collection_refactored.js`

- AngularJS-style listener manager implemented using the prototype pattern.
- Supports:
  - adding/removing listeners
  - preventing duplicates
  - unsubscribe (teardown) functions
  - triggering listeners with arguments
  - Promise-based execution via `Promise.all`

---

### 🟨 `listener_collection_refactored_test.js`

- Standalone Node test runner for the listener collection implementation.
- Uses a minimal `angular` stub to simulate AngularJS behavior outside the browser.
- Covers:
  - listener registration and execution
  - duplicate prevention
  - removal (including index 0 fix)
  - teardown/unsubscribe behavior
  - clearing listeners
  - handling non-function inputs
  - argument forwarding through `trigger()`

---

## How To Run

---

### 1. SQL Assessment (Normalization + Query Optimization)

Run in order:

```bash
mysql -u root -p < 01_original_schema.sql
mysql -u root -p < 02_normalize_and_migrate.sql
```

`01_original_schema.sql` seeds `user`, `user_skills`, `companies`, `users`, `jobs`, and `user_accounts`. `02_normalize_and_migrate.sql` does not introduce new seed rows — it populates the new `skill` lookup table from distinct values already present in `user_skills` and backfills `user_skills.skill_id`.

---

### 2. Contact Manager Schema (ERD Source)

```bash
mysql -u root -p < contact_manager_schema.sql
```

Seeds `users`, `contacts`, `contact_phone_numbers`, `contact_email_addresses`, `contact_postal_addresses`, and `contact_blocks` with sample rows to make the relationships visible in the generated ERD.

Then import the `contact_manager` database into PHPStorm (or another tool that supports ERD diagramming) to auto-generate the entity-relationship diagram.

---

### 3. PHP Refactor — `ORDER BY` Clause Builder

```bash
php order_by_clause_builder_refactored_test.php
```

Requires PHP 8.0 or later (uses `str_starts_with`).

---

### 4. JavaScript Refactor — Listener Collection

```bash
node listener_collection_refactored_test.js
```

Runs standalone under Node, the test file provides a minimal `angular` stub, so no AngularJS or browser environment is required.