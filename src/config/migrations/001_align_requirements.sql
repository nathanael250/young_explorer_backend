SET @db_name = DATABASE();

SET @has_price_per_person = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @db_name
      AND TABLE_NAME = 'packages'
      AND COLUMN_NAME = 'price_per_person'
);

SET @sql = IF(
    @has_price_per_person = 0,
    'ALTER TABLE packages ADD COLUMN price_per_person DECIMAL(10,2) DEFAULT 0.00 AFTER full_description',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_currency = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @db_name
      AND TABLE_NAME = 'packages'
      AND COLUMN_NAME = 'currency'
);

SET @sql = IF(
    @has_currency = 0,
    'ALTER TABLE packages ADD COLUMN currency VARCHAR(10) DEFAULT ''USD'' AFTER price_per_person',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_remaining_seats = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @db_name
      AND TABLE_NAME = 'package_availability'
      AND COLUMN_NAME = 'remaining_seats'
);

SET @sql = IF(
    @has_remaining_seats = 0,
    'ALTER TABLE package_availability ADD COLUMN remaining_seats INT GENERATED ALWAYS AS (total_seats - reserved_seats - confirmed_seats) STORED AFTER confirmed_seats',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

INSERT INTO package_durations (title, total_days, status)
SELECT '3 Days', 3, 'active'
WHERE NOT EXISTS (SELECT 1 FROM package_durations WHERE total_days = 3);

INSERT INTO package_durations (title, total_days, status)
SELECT '5 Days', 5, 'active'
WHERE NOT EXISTS (SELECT 1 FROM package_durations WHERE total_days = 5);

INSERT INTO package_durations (title, total_days, status)
SELECT '7 Days', 7, 'active'
WHERE NOT EXISTS (SELECT 1 FROM package_durations WHERE total_days = 7);

INSERT INTO package_durations (title, total_days, status)
SELECT '14 Days', 14, 'active'
WHERE NOT EXISTS (SELECT 1 FROM package_durations WHERE total_days = 14);
