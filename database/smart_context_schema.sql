-- ═══════════════════════════════════════════════════════════════════════════════
-- SMART CONTEXT MANAGEMENT SYSTEM - Complete Database Schema
-- Version: 1.0
-- Date: 2025-01-10
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- This schema implements a 3-level context management system:
--   Level 1: USER       - Personal preferences across all projects
--   Level 2: PROJECT    - Project structure + learned knowledge
--   Level 3: TICKET     - Conversation extraction for long tickets
--
-- Purpose: Enable Claude to work effectively on large projects by:
--   - Remembering user preferences and coding style
--   - Understanding project structure without reading all files
--   - Compressing old conversation while retaining key knowledge
--   - Learning from past work to avoid repeating mistakes
--
-- ═══════════════════════════════════════════════════════════════════════════════


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                           LEVEL 1: USER                                      │
-- │                  (Follows the developer everywhere)                          │
-- └─────────────────────────────────────────────────────────────────────────────┘

CREATE TABLE IF NOT EXISTS user_preferences (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(50) NOT NULL,

    -- ═══ Communication Style ═══
    language VARCHAR(10) DEFAULT 'el' COMMENT 'el, en, etc',
    response_style ENUM('concise', 'detailed', 'explain_first') DEFAULT 'detailed',
    ask_before_changes BOOLEAN DEFAULT TRUE COMMENT 'Ask confirmation before making changes',
    show_reasoning BOOLEAN DEFAULT TRUE COMMENT 'Explain the logic behind decisions',

    -- ═══ Programming Philosophy ═══
    programming_style JSON COMMENT '["functional", "OOP", "pragmatic", "clean_code"]',
    code_verbosity ENUM('minimal', 'balanced', 'verbose') DEFAULT 'balanced',
    comment_style JSON COMMENT '["docstrings", "inline", "minimal", "jsdoc"]',
    error_handling JSON COMMENT '["defensive", "fail_fast", "graceful", "log_everything"]',
    type_hints ENUM('always', 'public_only', 'never') DEFAULT 'always',

    -- ═══ Tool Preferences ═══
    preferred_tools JSON COMMENT '{
        "testing": "pytest",
        "linting": "ruff",
        "formatting": "black",
        "package_manager": "pip",
        "db_client": "mysql"
    }',
    git_style JSON COMMENT '{
        "commit_style": "conventional",
        "commit_language": "en",
        "branch_naming": "feature/xxx",
        "always_review_diff": true
    }',
    editor_config JSON COMMENT '{
        "indent_size": 4,
        "indent_style": "spaces",
        "line_length": 100,
        "trailing_newline": true
    }',

    -- ═══ Work Style ═══
    review_before_commit BOOLEAN DEFAULT TRUE,
    test_after_changes BOOLEAN DEFAULT TRUE,
    explain_complex_code BOOLEAN DEFAULT TRUE,
    prefer_small_commits BOOLEAN DEFAULT TRUE,

    -- ═══ Learning & Teaching ═══
    skill_level ENUM('junior', 'mid', 'senior', 'expert') DEFAULT 'mid',
    teach_mode BOOLEAN DEFAULT FALSE COMMENT 'Explain like teaching',
    show_alternatives BOOLEAN DEFAULT FALSE COMMENT 'Show alternative solutions',

    -- ═══ Personal Instructions ═══
    custom_instructions TEXT COMMENT 'Free text instructions from user',
    learned_quirks JSON COMMENT 'Things learned about this user over time',
    topics_of_interest JSON COMMENT '["performance", "security", "clean_code"]',
    things_to_avoid JSON COMMENT '["over_engineering", "premature_optimization"]',

    -- ═══ Metadata ═══
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='User-level preferences that apply across all projects';


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                         LEVEL 2: PROJECT                                     │
-- │                    (Specific to each project)                                │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- ─────────────────────────────────────────────────────────────────────────────
-- PROJECT MAP: Structure and static information about the project
-- Generated once, refreshed periodically (every 7 days or on demand)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS project_maps (
    id INT PRIMARY KEY AUTO_INCREMENT,
    project_id INT NOT NULL,

    -- ═══ Project Structure ═══
    structure_summary TEXT COMMENT 'Folder structure with descriptions',
    entry_points JSON COMMENT '[{"file": "app.py", "purpose": "Main entry"}]',
    key_files JSON COMMENT '[{"file": "auth.py", "purpose": "Authentication"}]',

    -- ═══ Tech Stack ═══
    tech_stack JSON COMMENT '["Python 3.11", "Flask", "SQLAlchemy", "MySQL"]',
    dependencies JSON COMMENT 'Key dependencies with versions',

    -- ═══ Architecture ═══
    architecture_type VARCHAR(100) COMMENT 'MVC, microservices, monolith, etc',
    design_patterns JSON COMMENT '["repository", "factory", "singleton"]',

    -- ═══ Project Stats ═══
    file_count INT DEFAULT 0,
    total_size_kb INT DEFAULT 0,
    primary_language VARCHAR(50),

    -- ═══ Metadata ═══
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP COMMENT 'Auto-refresh after this',
    generation_tokens_used INT DEFAULT 0,

    UNIQUE KEY uk_project (project_id),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Static project structure map - generated once, refreshed periodically';


-- ─────────────────────────────────────────────────────────────────────────────
-- PROJECT KNOWLEDGE: Learned knowledge from working on the project
-- Grows over time as more tickets are completed
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS project_knowledge (
    id INT PRIMARY KEY AUTO_INCREMENT,
    project_id INT NOT NULL,

    -- ═══ Coding Standards (learned from work) ═══
    coding_patterns JSON COMMENT '["Always use async/await", "Type hints required"]',
    naming_conventions JSON COMMENT '{"functions": "snake_case", "classes": "PascalCase"}',
    file_organization JSON COMMENT '{"tests": "tests/", "models": "src/models/"}',

    -- ═══ Common Gotchas (mistakes not to repeat) ═══
    known_gotchas JSON COMMENT '["MySQL drops connection after 30s idle"]',
    error_solutions JSON COMMENT '[{"error": "JWT decode", "solution": "Use HS256"}]',
    performance_notes JSON COMMENT '["Cache user queries", "Avoid N+1 in orders"]',

    -- ═══ Architecture Decisions (apply everywhere) ═══
    architecture_decisions JSON COMMENT '[{"decision": "Use events", "reason": "Decoupling"}]',
    api_conventions JSON COMMENT '{"versioning": "/v1/", "auth": "Bearer token"}',

    -- ═══ Testing & Deploy ═══
    testing_patterns JSON COMMENT '{"framework": "pytest", "fixtures": true, "mocking": "unittest.mock"}',
    ci_cd_notes JSON COMMENT '["Run migrations first", "Clear cache after deploy"]',
    environment_notes JSON COMMENT '{"dev": "sqlite", "prod": "mysql"}',

    -- ═══ Security Notes ═══
    security_considerations JSON COMMENT '["Sanitize all inputs", "Rate limit auth endpoints"]',
    sensitive_files JSON COMMENT '[".env", "secrets.yaml"]',

    -- ═══ Metadata ═══
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    learned_from_tickets JSON COMMENT '[1, 5, 12] - ticket IDs we learned from',
    knowledge_version INT DEFAULT 1 COMMENT 'Increment on major updates',

    UNIQUE KEY uk_project (project_id),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Learned knowledge from working on the project - grows over time';


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                          LEVEL 3: TICKET                                     │
-- │                    (Specific to each task)                                   │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- ─────────────────────────────────────────────────────────────────────────────
-- CONVERSATION EXTRACTIONS: Compressed knowledge from old messages
-- Created when conversation exceeds 50k tokens
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS conversation_extractions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ticket_id INT NOT NULL,

    -- ═══ Core Knowledge ═══
    decisions JSON COMMENT '[{"decision": "Use JWT", "reason": "Stateless auth"}]',
    problems_solved JSON COMMENT '[{"problem": "Race condition", "solution": "Added lock"}]',
    files_modified JSON COMMENT '["auth.py", "models/user.py", "tests/test_auth.py"]',
    current_status TEXT COMMENT 'Brief summary of where we left off',
    important_notes JSON COMMENT '["Never delete without confirm", "Rate limit 100/min"]',

    -- ═══ Blocking & Dependencies ═══
    blocking_issues JSON COMMENT '["Waiting for API key", "Need DB access"]',
    waiting_for_user JSON COMMENT '["Clarification on requirements", "Approval to proceed"]',
    external_dependencies JSON COMMENT '["Third-party API", "Database migration"]',

    -- ═══ Code Context ═══
    key_code_snippets JSON COMMENT '[{"file": "auth.py", "function": "login", "code": "..."}]',
    important_variables JSON COMMENT '{"JWT_SECRET": "from env", "TOKEN_EXPIRY": "24h"}',

    -- ═══ Testing Status ═══
    tests_status JSON COMMENT '{
        "files": ["test_auth.py"],
        "total": 15,
        "passing": 13,
        "failing": 2,
        "failing_tests": ["test_timeout", "test_refresh"]
    }',

    -- ═══ Error Patterns ═══
    error_patterns JSON COMMENT '[
        {"error": "ConnectionTimeout", "context": "Cold start", "solution": "Retry logic"},
        {"error": "JWT invalid", "context": "RS256", "solution": "Switch to HS256"}
    ]',

    -- ═══ Coverage Metadata ═══
    covers_msg_from_id INT COMMENT 'First message ID covered by this extraction',
    covers_msg_to_id INT COMMENT 'Last message ID covered by this extraction',
    messages_summarized INT DEFAULT 0 COMMENT 'Number of messages compressed',
    tokens_before INT DEFAULT 0 COMMENT 'Tokens in original messages',
    tokens_after INT DEFAULT 0 COMMENT 'Tokens in extraction',
    compression_ratio DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE WHEN tokens_before > 0 THEN (1 - tokens_after/tokens_before) * 100 ELSE 0 END
    ) STORED COMMENT 'Percentage of tokens saved',

    -- ═══ Metadata ═══
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    extraction_model VARCHAR(50) COMMENT 'Model used for extraction',

    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    INDEX idx_ticket (ticket_id),
    INDEX idx_coverage (ticket_id, covers_msg_to_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Extracted knowledge from older conversation messages';


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                    MODIFICATIONS TO EXISTING TABLES                          │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- ─────────────────────────────────────────────────────────────────────────────
-- CONVERSATION MESSAGES: Add token counting and summarization tracking
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE conversation_messages
    ADD COLUMN IF NOT EXISTS token_count INT DEFAULT 0
    COMMENT 'Cached token count for this message';

ALTER TABLE conversation_messages
    ADD COLUMN IF NOT EXISTS is_summarized BOOLEAN DEFAULT FALSE
    COMMENT 'True if this message has been included in an extraction';

ALTER TABLE conversation_messages
    ADD INDEX IF NOT EXISTS idx_ticket_created (ticket_id, created_at);

ALTER TABLE conversation_messages
    ADD INDEX IF NOT EXISTS idx_ticket_summarized (ticket_id, is_summarized);


-- ─────────────────────────────────────────────────────────────────────────────
-- PROJECTS: Add timestamps for map and knowledge generation
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE projects
    ADD COLUMN IF NOT EXISTS map_generated_at TIMESTAMP NULL
    COMMENT 'When project map was last generated';

ALTER TABLE projects
    ADD COLUMN IF NOT EXISTS knowledge_updated_at TIMESTAMP NULL
    COMMENT 'When project knowledge was last updated';


-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │                         HELPER VIEWS                                         │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- ─────────────────────────────────────────────────────────────────────────────
-- View: Full context info for a ticket (useful for debugging/monitoring)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_ticket_context AS
SELECT
    t.id AS ticket_id,
    t.ticket_number,
    t.title,
    t.project_id,
    p.name AS project_name,
    p.path AS project_path,

    -- Token counts
    (SELECT SUM(token_count) FROM conversation_messages WHERE ticket_id = t.id) AS total_message_tokens,
    (SELECT COUNT(*) FROM conversation_messages WHERE ticket_id = t.id) AS message_count,

    -- Extraction status
    (SELECT MAX(covers_msg_to_id) FROM conversation_extractions WHERE ticket_id = t.id) AS extracted_until_msg_id,
    (SELECT tokens_before - tokens_after FROM conversation_extractions WHERE ticket_id = t.id ORDER BY created_at DESC LIMIT 1) AS tokens_saved,

    -- Project context status
    (SELECT id FROM project_maps WHERE project_id = t.project_id) IS NOT NULL AS has_project_map,
    (SELECT id FROM project_knowledge WHERE project_id = t.project_id) IS NOT NULL AS has_project_knowledge

FROM tickets t
JOIN projects p ON t.project_id = p.id;


-- ─────────────────────────────────────────────────────────────────────────────
-- View: Tickets that need extraction (> 50k unsummarized tokens)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_tickets_needing_extraction AS
SELECT
    t.id AS ticket_id,
    t.ticket_number,
    COUNT(cm.id) AS total_messages,
    SUM(cm.token_count) AS total_tokens,
    SUM(CASE WHEN cm.is_summarized = FALSE THEN 1 ELSE 0 END) AS unsummarized_messages,
    SUM(CASE WHEN cm.is_summarized = FALSE THEN cm.token_count ELSE 0 END) AS unsummarized_tokens
FROM tickets t
JOIN conversation_messages cm ON cm.ticket_id = t.id
WHERE t.status IN ('open', 'in_progress', 'pending')
GROUP BY t.id, t.ticket_number
HAVING unsummarized_tokens > 50000;


-- ─────────────────────────────────────────────────────────────────────────────
-- View: Projects that need map refresh (expired or missing)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_projects_needing_map AS
SELECT
    p.id AS project_id,
    p.name,
    p.path,
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

-- Default user preferences template (can be cloned for new users)
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
    'Default preferences template - clone for new users'
)
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SCHEMA SUMMARY
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- NEW TABLES:
--   • user_preferences         : User-level settings (1 per user)
--   • project_maps             : Project structure (1 per project)
--   • project_knowledge        : Learned knowledge (1 per project)
--   • conversation_extractions : Compressed conversations (N per ticket)
--
-- MODIFIED TABLES:
--   • conversation_messages    : +token_count, +is_summarized
--   • projects                 : +map_generated_at, +knowledge_updated_at
--
-- VIEWS:
--   • v_ticket_context             : Full context info for debugging
--   • v_tickets_needing_extraction : Find tickets needing compression
--   • v_projects_needing_map       : Find projects needing map refresh
--
-- TOKEN BUDGET (200k context):
--   • System prompt:        2,000 tokens (fixed)
--   • User preferences:     2,000 tokens (fixed)
--   • Project map:          5,000 tokens (cached)
--   • Project knowledge:    5,000 tokens (cached)
--   • Ticket description:   2,000 tokens (fixed)
--   • Extraction:          30,000 tokens (compressed)
--   • Recent messages:     50,000 tokens (full)
--   • Output buffer:       10,000 tokens (reserved)
--   • Safety margin:       94,000 tokens (~47%)
--
-- ═══════════════════════════════════════════════════════════════════════════════
