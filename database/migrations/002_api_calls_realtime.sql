-- Migration: Add api_calls to execution_sessions for real-time tracking
-- Version: 2.28.0

-- Check if column exists before adding
SET @exist := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_SCHEMA = DATABASE() 
               AND TABLE_NAME = 'execution_sessions' 
               AND COLUMN_NAME = 'api_calls');

SET @query := IF(@exist = 0, 
    'ALTER TABLE execution_sessions ADD COLUMN api_calls INT DEFAULT 0',
    'SELECT "Column api_calls already exists"');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
