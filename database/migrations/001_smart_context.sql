-- ═══════════════════════════════════════════════════════════════════════════════
-- MIGRATION 001: Smart Context Management System
-- Date: 2025-01-10
-- ═══════════════════════════════════════════════════════════════════════════════

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                           LEVEL 1: USER                                      │
-- └─────────────────────────────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS user_preferences (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(50) NOT NULL,

    -- Communication Style
    language VARCHAR(10) DEFAULT 'el',
    response_style ENUM('concise', 'detailed', 'explain_first') DEFAULT 'detailed',
    ask_before_changes BOOLEAN DEFAULT TRUE,
    show_reasoning BOOLEAN DEFAULT TRUE,

    -- Programming Philosophy
    programming_style JSON,
    code_verbosity ENUM('minimal', 'balanced', 'verbose') DEFAULT 'balanced',
    comment_style JSON,
    error_handling JSON,
    type_hints ENUM('always', 'public_only', 'never') DEFAULT 'always',

    -- Tool Preferences
    preferred_tools JSON,
    git_style JSON,
    editor_config JSON,

    -- Work Style
    review_before_commit BOOLEAN DEFAULT TRUE,
    test_after_changes BOOLEAN DEFAULT TRUE,
    explain_complex_code BOOLEAN DEFAULT TRUE,
    prefer_small_commits BOOLEAN DEFAULT TRUE,

    -- Learning & Teaching
    skill_level ENUM('junior', 'mid', 'senior', 'expert') DEFAULT 'mid',
    teach_mode BOOLEAN DEFAULT FALSE,
    show_alternatives BOOLEAN DEFAULT FALSE,

    -- Personal Instructions
    custom_instructions TEXT,
    learned_quirks JSON,
    topics_of_interest JSON,
    things_to_avoid JSON,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                         LEVEL 2: PROJECT                                     │
-- └─────────────────────────────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS project_maps (
    id INT PRIMARY KEY AUTO_INCREMENT,
    project_id INT NOT NULL,

    -- Project Structure
    structure_summary TEXT,
    entry_points JSON,
    key_files JSON,

    -- Tech Stack
    tech_stack JSON,
    dependencies JSON,

    -- Architecture
    architecture_type VARCHAR(100),
    design_patterns JSON,

    -- Project Stats
    file_count INT DEFAULT 0,
    total_size_kb INT DEFAULT 0,
    primary_language VARCHAR(50),

    -- Metadata
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    generation_tokens_used INT DEFAULT 0,

    UNIQUE KEY uk_project (project_id),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS project_knowledge (
    id INT PRIMARY KEY AUTO_INCREMENT,
    project_id INT NOT NULL,

    -- Coding Standards
    coding_patterns JSON,
    naming_conventions JSON,
    file_organization JSON,

    -- Common Gotchas
    known_gotchas JSON,
    error_solutions JSON,
    performance_notes JSON,

    -- Architecture Decisions
    architecture_decisions JSON,
    api_conventions JSON,

    -- Testing & Deploy
    testing_patterns JSON,
    ci_cd_notes JSON,
    environment_notes JSON,

    -- Security Notes
    security_considerations JSON,
    sensitive_files JSON,

    -- Metadata
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    learned_from_tickets JSON,
    knowledge_version INT DEFAULT 1,

    UNIQUE KEY uk_project (project_id),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                          LEVEL 3: TICKET                                     │
-- └─────────────────────────────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS conversation_extractions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ticket_id INT NOT NULL,

    -- Core Knowledge
    decisions JSON,
    problems_solved JSON,
    files_modified JSON,
    current_status TEXT,

    -- Blocking & Dependencies
    blocking_issues JSON,
    waiting_for_user JSON,
    external_dependencies JSON,

    -- Code Context
    key_code_snippets JSON,
    important_variables JSON,

    -- Testing Status
    tests_status JSON,

    -- Error Patterns
    error_patterns JSON,

    -- Important Notes (user instructions, warnings, rules to always remember)
    important_notes JSON,

    -- Coverage Metadata
    covers_msg_from_id INT,
    covers_msg_to_id INT,
    messages_summarized INT DEFAULT 0,
    tokens_before INT DEFAULT 0,
    tokens_after INT DEFAULT 0,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    extraction_model VARCHAR(50),

    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    INDEX idx_ticket (ticket_id),
    INDEX idx_coverage (ticket_id, covers_msg_to_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                    MODIFICATIONS TO EXISTING TABLES                          │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- Add columns to conversation_messages (check if exists first)
SET @dbname = DATABASE();

-- Add token_count column
SELECT COUNT(*) INTO @col_exists
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = @dbname
AND TABLE_NAME = 'conversation_messages'
AND COLUMN_NAME = 'token_count';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE conversation_messages ADD COLUMN token_count INT DEFAULT 0',
    'SELECT "token_count already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add is_summarized column
SELECT COUNT(*) INTO @col_exists
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = @dbname
AND TABLE_NAME = 'conversation_messages'
AND COLUMN_NAME = 'is_summarized';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE conversation_messages ADD COLUMN is_summarized BOOLEAN DEFAULT FALSE',
    'SELECT "is_summarized already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add map_generated_at to projects
SELECT COUNT(*) INTO @col_exists
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = @dbname
AND TABLE_NAME = 'projects'
AND COLUMN_NAME = 'map_generated_at';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE projects ADD COLUMN map_generated_at TIMESTAMP NULL',
    'SELECT "map_generated_at already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add knowledge_updated_at to projects
SELECT COUNT(*) INTO @col_exists
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = @dbname
AND TABLE_NAME = 'projects'
AND COLUMN_NAME = 'knowledge_updated_at';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE projects ADD COLUMN knowledge_updated_at TIMESTAMP NULL',
    'SELECT "knowledge_updated_at already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                              INDEXES                                         │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- Create indexes (will be skipped if already exist via separate commands)


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                         HELPER VIEWS                                         │
-- └─────────────────────────────────────────────────────────────────────────────┘

CREATE OR REPLACE VIEW v_ticket_context AS
SELECT
    t.id AS ticket_id,
    t.ticket_number,
    t.title,
    t.project_id,
    p.name AS project_name,
    COALESCE(p.web_path, p.app_path) AS project_path,
    (SELECT SUM(token_count) FROM conversation_messages WHERE ticket_id = t.id) AS total_message_tokens,
    (SELECT COUNT(*) FROM conversation_messages WHERE ticket_id = t.id) AS message_count,
    (SELECT MAX(covers_msg_to_id) FROM conversation_extractions WHERE ticket_id = t.id) AS extracted_until_msg_id,
    (SELECT id FROM project_maps WHERE project_id = t.project_id) IS NOT NULL AS has_project_map,
    (SELECT id FROM project_knowledge WHERE project_id = t.project_id) IS NOT NULL AS has_project_knowledge
FROM tickets t
JOIN projects p ON t.project_id = p.id;


CREATE OR REPLACE VIEW v_tickets_needing_extraction AS
SELECT
    t.id AS ticket_id,
    t.ticket_number,
    COUNT(cm.id) AS total_messages,
    COALESCE(SUM(cm.token_count), 0) AS total_tokens,
    SUM(CASE WHEN cm.is_summarized = FALSE THEN 1 ELSE 0 END) AS unsummarized_messages,
    COALESCE(SUM(CASE WHEN cm.is_summarized = FALSE THEN cm.token_count ELSE 0 END), 0) AS unsummarized_tokens
FROM tickets t
LEFT JOIN conversation_messages cm ON cm.ticket_id = t.id
WHERE t.status NOT IN ('closed', 'completed', 'archived')
GROUP BY t.id, t.ticket_number
HAVING unsummarized_tokens > 50000;


CREATE OR REPLACE VIEW v_projects_needing_map AS
SELECT
    p.id AS project_id,
    p.name,
    COALESCE(p.web_path, p.app_path) AS project_path,
    pm.generated_at,
    pm.expires_at,
    CASE
        WHEN pm.id IS NULL THEN 'missing'
        WHEN pm.expires_at < NOW() THEN 'expired'
        ELSE 'ok'
    END AS map_status
FROM projects p
LEFT JOIN project_maps pm ON p.id = pm.project_id
WHERE pm.id IS NULL OR pm.expires_at < NOW();


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                         INITIAL DATA                                         │
-- └─────────────────────────────────────────────────────────────────────────────┘

INSERT INTO user_preferences (
    user_id,
    language,
    response_style,
    programming_style,
    custom_instructions
) VALUES (
    '_default',
    'en',
    'detailed',
    '["pragmatic"]',
    'Default preferences template'
)
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;


-- ═══════════════════════════════════════════════════════════════════════════════
-- MIGRATION COMPLETE
-- ═══════════════════════════════════════════════════════════════════════════════
SELECT 'Migration 001_smart_context completed successfully' AS status;
