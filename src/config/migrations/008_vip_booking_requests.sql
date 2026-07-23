ALTER TABLE bookings
MODIFY booking_status ENUM('quote_pending','pending','confirmed','cancelled','expired','completed') DEFAULT 'pending';

SET @has_booking_type = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND COLUMN_NAME = 'booking_type'
);
SET @sql = IF(
  @has_booking_type = 0,
  'ALTER TABLE bookings ADD COLUMN booking_type ENUM(''standard'',''vip'') DEFAULT ''standard'' AFTER special_request',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_vip_request_details = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND COLUMN_NAME = 'vip_request_details'
);
SET @sql = IF(
  @has_vip_request_details = 0,
  'ALTER TABLE bookings ADD COLUMN vip_request_details TEXT AFTER booking_type',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_quoted_amount = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND COLUMN_NAME = 'quoted_amount'
);
SET @sql = IF(
  @has_quoted_amount = 0,
  'ALTER TABLE bookings ADD COLUMN quoted_amount DECIMAL(10,2) NULL AFTER vip_request_details',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_quoted_currency = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND COLUMN_NAME = 'quoted_currency'
);
SET @sql = IF(
  @has_quoted_currency = 0,
  'ALTER TABLE bookings ADD COLUMN quoted_currency VARCHAR(10) DEFAULT ''USD'' AFTER quoted_amount',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
