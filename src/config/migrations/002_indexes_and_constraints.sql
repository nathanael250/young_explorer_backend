ALTER TABLE package_days
ADD UNIQUE KEY unique_package_day_number (package_id, day_number);

ALTER TABLE package_day_destinations
ADD UNIQUE KEY unique_day_destination_order (package_day_id, visit_order);

ALTER TABLE package_availability
ADD INDEX idx_availability_package_start (package_id, start_date),
ADD INDEX idx_availability_status_start (status, start_date);

ALTER TABLE bookings
ADD INDEX idx_bookings_user_status (user_id, booking_status),
ADD INDEX idx_bookings_availability_status (availability_id, booking_status);

ALTER TABLE payments
ADD INDEX idx_payments_booking_status (booking_id, payment_status),
ADD INDEX idx_payments_transaction_reference (transaction_reference);
