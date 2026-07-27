SET @has_package_approval_status = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'packages'
    AND COLUMN_NAME = 'approval_status'
);
SET @sql = IF(
  @has_package_approval_status = 0,
  'ALTER TABLE packages ADD COLUMN approval_status ENUM(''pending'',''approved'',''rejected'') DEFAULT ''pending'' AFTER status',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_package_approval_notes = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'packages'
    AND COLUMN_NAME = 'approval_notes'
);
SET @sql = IF(
  @has_package_approval_notes = 0,
  'ALTER TABLE packages ADD COLUMN approval_notes TEXT AFTER approval_status',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_package_approved_by = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'packages'
    AND COLUMN_NAME = 'approved_by'
);
SET @sql = IF(
  @has_package_approved_by = 0,
  'ALTER TABLE packages ADD COLUMN approved_by BIGINT NULL AFTER approval_notes',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_package_approved_at = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'packages'
    AND COLUMN_NAME = 'approved_at'
);
SET @sql = IF(
  @has_package_approved_at = 0,
  'ALTER TABLE packages ADD COLUMN approved_at TIMESTAMP NULL AFTER approved_by',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE packages
SET approval_status = 'approved'
WHERE COALESCE(vendor_id, 0) = 0
  AND approval_status = 'pending';
