DELIMITER $$

DROP PROCEDURE IF EXISTS add_column_if_missing $$
CREATE PROCEDURE add_column_if_missing(
  IN table_name_value VARCHAR(64),
  IN column_name_value VARCHAR(64),
  IN column_definition_value TEXT
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = table_name_value
      AND COLUMN_NAME = column_name_value
  ) THEN
    SET @alter_sql = CONCAT('ALTER TABLE ', table_name_value, ' ADD COLUMN ', column_name_value, ' ', column_definition_value);
    PREPARE stmt FROM @alter_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END $$

DELIMITER ;

ALTER TABLE users
MODIFY role ENUM('admin','parent','explorer','vendor') DEFAULT 'parent';

CALL add_column_if_missing('vendors', 'business_type', 'VARCHAR(100) NULL AFTER business_address');
CALL add_column_if_missing('vendors', 'registration_number', 'VARCHAR(150) NULL AFTER business_type');
CALL add_column_if_missing('vendors', 'description', 'TEXT NULL AFTER registration_number');
CALL add_column_if_missing('vendors', 'logo', 'VARCHAR(255) NULL AFTER description');
SET @has_vendor_rdb_certificate = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'vendors'
    AND COLUMN_NAME = 'rdb_certificate'
);
SET @has_vendor_rib_certificate = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'vendors'
    AND COLUMN_NAME = 'rib_certificate'
);
SET @sql = IF(
  @has_vendor_rdb_certificate = 0 AND @has_vendor_rib_certificate > 0,
  'ALTER TABLE vendors CHANGE COLUMN rib_certificate rdb_certificate VARCHAR(255) NULL',
  IF(@has_vendor_rdb_certificate = 0, 'ALTER TABLE vendors ADD COLUMN rdb_certificate VARCHAR(255) NULL AFTER logo', 'SELECT 1')
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
ALTER TABLE vendors
MODIFY approval_status ENUM('pending','under_review','changes_requested','approved','rejected','suspended','blocked') DEFAULT 'pending';

CREATE TABLE IF NOT EXISTS children (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  age INT,
  gender VARCHAR(20),
  medical_notes TEXT,
  dietary_requirements TEXT,
  accessibility_requirements TEXT,
  status ENUM('active','inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_children_parent_status (user_id, status)
);

SET @has_child_age = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'children'
    AND COLUMN_NAME = 'age'
);
SET @has_child_date_of_birth = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'children'
    AND COLUMN_NAME = 'date_of_birth'
);
SET @sql = IF(
  @has_child_age = 0 AND @has_child_date_of_birth > 0,
  'ALTER TABLE children CHANGE COLUMN date_of_birth age INT NULL',
  IF(@has_child_age = 0, 'ALTER TABLE children ADD COLUMN age INT NULL AFTER last_name', 'SELECT 1')
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CALL add_column_if_missing('packages', 'location_name', 'VARCHAR(255) NULL AFTER meeting_point');
CALL add_column_if_missing('packages', 'location_address', 'VARCHAR(255) NULL AFTER location_name');
CALL add_column_if_missing('packages', 'minimum_age', 'INT NULL AFTER location_address');
CALL add_column_if_missing('packages', 'maximum_age', 'INT NULL AFTER minimum_age');
CALL add_column_if_missing('packages', 'minimum_participants', 'INT NULL AFTER maximum_age');
CALL add_column_if_missing('packages', 'maximum_participants', 'INT NULL AFTER minimum_participants');
CALL add_column_if_missing('packages', 'check_in_time', 'TIME NULL AFTER maximum_participants');
CALL add_column_if_missing('packages', 'start_time', 'TIME NULL AFTER check_in_time');
CALL add_column_if_missing('packages', 'end_time', 'TIME NULL AFTER start_time');
CALL add_column_if_missing('packages', 'dropoff_location', 'VARCHAR(255) NULL AFTER end_time');
CALL add_column_if_missing('packages', 'dropoff_latitude', 'DECIMAL(10,8) NULL AFTER dropoff_location');
CALL add_column_if_missing('packages', 'dropoff_longitude', 'DECIMAL(11,8) NULL AFTER dropoff_latitude');
CALL add_column_if_missing('packages', 'dropoff_time', 'TIME NULL AFTER dropoff_longitude');
CALL add_column_if_missing('packages', 'dropoff_contact_name', 'VARCHAR(150) NULL AFTER dropoff_time');
CALL add_column_if_missing('packages', 'dropoff_contact_phone', 'VARCHAR(30) NULL AFTER dropoff_contact_name');
CALL add_column_if_missing('packages', 'dropoff_instructions', 'TEXT NULL AFTER dropoff_contact_phone');
CALL add_column_if_missing('packages', 'pickup_location', 'VARCHAR(255) NULL AFTER dropoff_instructions');
CALL add_column_if_missing('packages', 'pickup_latitude', 'DECIMAL(10,8) NULL AFTER pickup_location');
CALL add_column_if_missing('packages', 'pickup_longitude', 'DECIMAL(11,8) NULL AFTER pickup_latitude');
CALL add_column_if_missing('packages', 'pickup_time', 'TIME NULL AFTER pickup_longitude');
CALL add_column_if_missing('packages', 'pickup_contact_name', 'VARCHAR(150) NULL AFTER pickup_time');
CALL add_column_if_missing('packages', 'pickup_contact_phone', 'VARCHAR(30) NULL AFTER pickup_contact_name');
CALL add_column_if_missing('packages', 'pickup_instructions', 'TEXT NULL AFTER pickup_contact_phone');
CALL add_column_if_missing('packages', 'transportation_included', 'TINYINT(1) DEFAULT 0 AFTER pickup_instructions');
CALL add_column_if_missing('packages', 'transportation_provider', 'VARCHAR(255) NULL AFTER transportation_included');
CALL add_column_if_missing('packages', 'vehicle_type', 'VARCHAR(100) NULL AFTER transportation_provider');
CALL add_column_if_missing('packages', 'departure_point', 'VARCHAR(255) NULL AFTER vehicle_type');
CALL add_column_if_missing('packages', 'departure_time', 'TIME NULL AFTER departure_point');
CALL add_column_if_missing('packages', 'return_time', 'TIME NULL AFTER departure_time');
CALL add_column_if_missing('packages', 'supervision_details', 'TEXT NULL AFTER return_time');
CALL add_column_if_missing('packages', 'safety_measures', 'TEXT NULL AFTER supervision_details');
CALL add_column_if_missing('packages', 'insurance_details', 'TEXT NULL AFTER safety_measures');
UPDATE packages
SET status = 'draft'
WHERE status IS NULL
  OR status NOT IN ('draft','published','unpublished','archived');

UPDATE packages
SET approval_status = 'approved'
WHERE approval_status IS NULL
  OR approval_status <> 'rejected';

ALTER TABLE packages
MODIFY status ENUM('draft','published','unpublished','archived') DEFAULT 'draft',
MODIFY approval_status ENUM('approved','rejected') DEFAULT 'approved';

CALL add_column_if_missing('destinations', 'description', 'LONGTEXT NULL AFTER category');
SET @has_destination_full_description = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'destinations'
    AND COLUMN_NAME = 'full_description'
);
SET @has_destination_short_description = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'destinations'
    AND COLUMN_NAME = 'short_description'
);
SET @sql = CASE
  WHEN @has_destination_full_description > 0 AND @has_destination_short_description > 0 THEN
    'UPDATE destinations SET description = COALESCE(description, full_description, short_description) WHERE description IS NULL'
  WHEN @has_destination_full_description > 0 THEN
    'UPDATE destinations SET description = COALESCE(description, full_description) WHERE description IS NULL'
  WHEN @has_destination_short_description > 0 THEN
    'UPDATE destinations SET description = COALESCE(description, short_description) WHERE description IS NULL'
  ELSE
    'SELECT 1'
END;
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CALL add_column_if_missing('package_days', 'location_name', 'VARCHAR(255) NULL AFTER meals');
CALL add_column_if_missing('package_days', 'latitude', 'DECIMAL(10,8) NULL AFTER location_name');
CALL add_column_if_missing('package_days', 'longitude', 'DECIMAL(11,8) NULL AFTER latitude');

CALL add_column_if_missing('package_day_destinations', 'location_name', 'VARCHAR(255) NULL AFTER activity_description');
CALL add_column_if_missing('package_day_destinations', 'latitude', 'DECIMAL(10,8) NULL AFTER location_name');
CALL add_column_if_missing('package_day_destinations', 'longitude', 'DECIMAL(11,8) NULL AFTER latitude');

CALL add_column_if_missing('package_availability', 'operation_status', 'ENUM(''scheduled'',''check_in_open'',''departed'',''in_progress'',''returning'',''completed'') DEFAULT ''scheduled'' AFTER remaining_seats');

CALL add_column_if_missing('bookings', 'authorized_guardian_name', 'VARCHAR(150) NULL AFTER special_request');
CALL add_column_if_missing('bookings', 'authorized_guardian_phone', 'VARCHAR(30) NULL AFTER authorized_guardian_name');
CALL add_column_if_missing('bookings', 'parent_notes', 'TEXT NULL AFTER authorized_guardian_phone');
CALL add_column_if_missing('bookings', 'terms_accepted', 'TINYINT(1) DEFAULT 0 AFTER parent_notes');
CALL add_column_if_missing('bookings', 'notification_channel', 'ENUM(''in_app'',''email'',''sms'',''whatsapp'') DEFAULT ''email'' AFTER terms_accepted');
CALL add_column_if_missing('bookings', 'ticket_number', 'VARCHAR(100) NULL AFTER booking_reference');
CALL add_column_if_missing('bookings', 'ticket_token', 'VARCHAR(128) NULL AFTER ticket_number');
CALL add_column_if_missing('bookings', 'ticket_issued_at', 'TIMESTAMP NULL AFTER ticket_token');

SET @has_unique_booking_ticket_number = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND INDEX_NAME = 'unique_booking_ticket_number'
);
SET @sql = IF(
  @has_unique_booking_ticket_number = 0,
  'ALTER TABLE bookings ADD UNIQUE KEY unique_booking_ticket_number (ticket_number)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_unique_booking_ticket_token = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bookings'
    AND INDEX_NAME = 'unique_booking_ticket_token'
);
SET @sql = IF(
  @has_unique_booking_ticket_token = 0,
  'ALTER TABLE bookings ADD UNIQUE KEY unique_booking_ticket_token (ticket_token)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CALL add_column_if_missing('booking_participants', 'child_id', 'BIGINT NULL AFTER booking_id');
CALL add_column_if_missing('booking_participants', 'age', 'INT NULL AFTER gender');
CALL add_column_if_missing('booking_participants', 'emergency_contact_name', 'VARCHAR(150) NULL AFTER emergency_contact');
CALL add_column_if_missing('booking_participants', 'emergency_contact_relationship', 'VARCHAR(100) NULL AFTER emergency_contact_name');
CALL add_column_if_missing('booking_participants', 'medical_notes', 'TEXT NULL AFTER emergency_contact_relationship');
CALL add_column_if_missing('booking_participants', 'dietary_requirements', 'TEXT NULL AFTER medical_notes');
CALL add_column_if_missing('booking_participants', 'accessibility_requirements', 'TEXT NULL AFTER dietary_requirements');
CALL add_column_if_missing('booking_participants', 'special_instructions', 'TEXT NULL AFTER accessibility_requirements');

CREATE TABLE IF NOT EXISTS booking_updates (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  booking_id BIGINT,
  availability_id BIGINT,
  package_id BIGINT,
  user_id BIGINT,
  update_type ENUM('confirmation','reminder','check_in','departure','arrival','returning','pickup','completed','general') DEFAULT 'general',
  title VARCHAR(255),
  message TEXT,
  sent_channel ENUM('in_app','email','sms','whatsapp') DEFAULT 'in_app',
  created_by BIGINT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id),
  FOREIGN KEY (availability_id) REFERENCES package_availability(id),
  FOREIGN KEY (package_id) REFERENCES packages(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id),
  INDEX idx_booking_updates_user_created (user_id, created_at),
  INDEX idx_booking_updates_occurrence (availability_id, created_at)
);

DROP PROCEDURE IF EXISTS add_column_if_missing;
