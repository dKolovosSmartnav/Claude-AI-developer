-- Migration: Add AI model selection to projects and tickets
-- Version: 2.29.0

-- Add ai_model to projects (default sonnet)
SET @exist := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_SCHEMA = DATABASE() 
               AND TABLE_NAME = 'projects' 
               AND COLUMN_NAME = 'ai_model');

SET @query := IF(@exist = 0, 
    "ALTER TABLE projects ADD COLUMN ai_model ENUM('opus', 'sonnet', 'haiku') DEFAULT 'sonnet'",
    'SELECT "Column ai_model already exists in projects"');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add ai_model to tickets (nullable - inherits from project if null)
SET @exist := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_SCHEMA = DATABASE() 
               AND TABLE_NAME = 'tickets' 
               AND COLUMN_NAME = 'ai_model');

SET @query := IF(@exist = 0, 
    "ALTER TABLE tickets ADD COLUMN ai_model ENUM('opus', 'sonnet', 'haiku') DEFAULT NULL",
    'SELECT "Column ai_model already exists in tickets"');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
