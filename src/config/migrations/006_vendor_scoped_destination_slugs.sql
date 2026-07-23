SET @has_global_destination_slug_unique = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'destinations'
    AND INDEX_NAME = 'slug'
    AND NON_UNIQUE = 0
);
SET @sql = IF(
  @has_global_destination_slug_unique > 0,
  'ALTER TABLE destinations DROP INDEX slug',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_destination_slug_index = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'destinations'
    AND INDEX_NAME = 'idx_destinations_slug'
);
SET @sql = IF(
  @has_destination_slug_index = 0,
  'ALTER TABLE destinations ADD INDEX idx_destinations_slug (slug)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_vendor_destination_slug_unique = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'destinations'
    AND INDEX_NAME = 'unique_vendor_destination_slug'
);
SET @sql = IF(
  @has_vendor_destination_slug_unique = 0,
  'ALTER TABLE destinations ADD UNIQUE KEY unique_vendor_destination_slug (vendor_id, slug)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
