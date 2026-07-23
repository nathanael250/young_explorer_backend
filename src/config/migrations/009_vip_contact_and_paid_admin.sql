SET @has_vip_contact_name = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND COLUMN_NAME = 'vip_contact_name'
);
SET @sql = IF(
  @has_vip_contact_name = 0,
  'ALTER TABLE bookings ADD COLUMN vip_contact_name VARCHAR(150) NULL AFTER vip_request_details',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_vip_contact_email = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND COLUMN_NAME = 'vip_contact_email'
);
SET @sql = IF(
  @has_vip_contact_email = 0,
  'ALTER TABLE bookings ADD COLUMN vip_contact_email VARCHAR(150) NULL AFTER vip_contact_name',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_vip_contact_phone = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND COLUMN_NAME = 'vip_contact_phone'
);
SET @sql = IF(
  @has_vip_contact_phone = 0,
  'ALTER TABLE bookings ADD COLUMN vip_contact_phone VARCHAR(30) NULL AFTER vip_contact_email',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_vip_preferred_contact = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND COLUMN_NAME = 'vip_preferred_contact'
);
SET @sql = IF(
  @has_vip_preferred_contact = 0,
  'ALTER TABLE bookings ADD COLUMN vip_preferred_contact VARCHAR(30) NULL AFTER vip_contact_phone',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
