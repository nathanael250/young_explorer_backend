ALTER TABLE users
MODIFY role ENUM('admin','explorer','vendor') DEFAULT 'explorer';

CREATE TABLE IF NOT EXISTS vendors (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNIQUE,
  business_name VARCHAR(255),
  business_phone VARCHAR(30),
  business_email VARCHAR(150),
  business_address VARCHAR(255),
  rib_certificate VARCHAR(255),
  approval_status ENUM('pending','approved','rejected','blocked') DEFAULT 'pending',
  review_notes TEXT,
  reviewed_by BIGINT,
  reviewed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (reviewed_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS categories (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  slug VARCHAR(120) UNIQUE,
  status ENUM('active','inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS package_categories (
  package_id BIGINT,
  category_id BIGINT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (package_id, category_id),
  FOREIGN KEY (package_id) REFERENCES packages(id),
  FOREIGN KEY (category_id) REFERENCES categories(id)
);

SET @has_package_vendor_id = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'packages'
    AND COLUMN_NAME = 'vendor_id'
);
SET @sql = IF(
  @has_package_vendor_id = 0,
  'ALTER TABLE packages ADD COLUMN vendor_id BIGINT NULL AFTER created_by',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_destination_vendor_id = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'destinations'
    AND COLUMN_NAME = 'vendor_id'
);
SET @sql = IF(
  @has_destination_vendor_id = 0,
  'ALTER TABLE destinations ADD COLUMN vendor_id BIGINT NULL AFTER status',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_booking_cutoff_hours = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'package_availability'
    AND COLUMN_NAME = 'booking_cutoff_hours'
);
SET @sql = IF(
  @has_booking_cutoff_hours = 0,
  'ALTER TABLE package_availability ADD COLUMN booking_cutoff_hours INT DEFAULT 24 AFTER confirmed_seats',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_special_request = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND COLUMN_NAME = 'special_request'
);
SET @sql = IF(
  @has_special_request = 0,
  'ALTER TABLE bookings ADD COLUMN special_request TEXT AFTER total_amount',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

INSERT INTO categories (name, slug, status)
SELECT 'History', 'history', 'active'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE slug = 'history');

INSERT INTO categories (name, slug, status)
SELECT 'Art', 'art', 'active'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE slug = 'art');

INSERT INTO categories (name, slug, status)
SELECT 'Entertainment', 'entertainment', 'active'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE slug = 'entertainment');

INSERT INTO categories (name, slug, status)
SELECT 'Science', 'science', 'active'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE slug = 'science');

INSERT INTO categories (name, slug, status)
SELECT 'Culture', 'culture', 'active'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE slug = 'culture');

INSERT INTO categories (name, slug, status)
SELECT 'Nature', 'nature', 'active'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE slug = 'nature');

INSERT INTO categories (name, slug, status)
SELECT 'Adventure', 'adventure', 'active'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE slug = 'adventure');

INSERT INTO categories (name, slug, status)
SELECT 'Education', 'education', 'active'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE slug = 'education');
