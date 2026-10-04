CREATE TABLE IF NOT EXISTS newsletter_subscribers (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  user_id BIGINT DEFAULT NULL,
  status ENUM('active', 'unsubscribed') DEFAULT 'active',
  subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  unsubscribed_at TIMESTAMP NULL DEFAULT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

SET @has_idx_newsletter_email = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'newsletter_subscribers'
    AND INDEX_NAME = 'idx_newsletter_email'
);
SET @sql = IF(
  @has_idx_newsletter_email = 0,
  'CREATE INDEX idx_newsletter_email ON newsletter_subscribers(email)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_idx_newsletter_status = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'newsletter_subscribers'
    AND INDEX_NAME = 'idx_newsletter_status'
);
SET @sql = IF(
  @has_idx_newsletter_status = 0,
  'CREATE INDEX idx_newsletter_status ON newsletter_subscribers(status)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_idx_newsletter_user = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'newsletter_subscribers'
    AND INDEX_NAME = 'idx_newsletter_user'
);
SET @sql = IF(
  @has_idx_newsletter_user = 0,
  'CREATE INDEX idx_newsletter_user ON newsletter_subscribers(user_id)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
