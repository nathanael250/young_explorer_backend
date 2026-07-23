SET @package_vendor_fk = (
  SELECT CONSTRAINT_NAME
  FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'packages'
    AND COLUMN_NAME = 'vendor_id'
    AND REFERENCED_TABLE_NAME = 'vendors'
  LIMIT 1
);
SET @sql = IF(
  @package_vendor_fk IS NOT NULL,
  CONCAT('ALTER TABLE packages DROP FOREIGN KEY ', @package_vendor_fk),
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_package_vendor_id = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'packages'
    AND COLUMN_NAME = 'vendor_id'
);
SET @sql = IF(
  @has_package_vendor_id = 0,
  'ALTER TABLE packages ADD COLUMN vendor_id BIGINT DEFAULT 0 AFTER created_by',
  'ALTER TABLE packages MODIFY vendor_id BIGINT DEFAULT 0'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE packages
SET vendor_id = 0
WHERE vendor_id IS NULL;
