-- Migration: 2.60.3_add_daemon_logs_table
-- Description: Add daemon_logs table for storing daemon activity logs

CREATE TABLE IF NOT EXISTS `daemon_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `ticket_id` int DEFAULT NULL,
  `log_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'info',
  `message` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ticket_id` (`ticket_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Daemon activity logs';
