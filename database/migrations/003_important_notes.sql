-- Migration: Add important_notes to conversation_extractions
-- Version: 2.28.0

-- Check if column exists before adding
SET @exist := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_SCHEMA = DATABASE() 
               AND TABLE_NAME = 'conversation_extractions' 
               AND COLUMN_NAME = 'important_notes');

SET @query := IF(@exist = 0, 
    'ALTER TABLE conversation_extractions ADD COLUMN important_notes JSON COMMENT ''User instructions, warnings, and rules to always remember''',
    'SELECT "Column important_notes already exists"');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
