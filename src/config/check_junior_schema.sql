USE junior;

SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND (
    (TABLE_NAME = 'packages' AND COLUMN_NAME IN ('location_name','location_address','minimum_age','maximum_age','pickup_location','dropoff_location'))
    OR (TABLE_NAME = 'destinations' AND COLUMN_NAME = 'description')
    OR (TABLE_NAME = 'bookings' AND COLUMN_NAME IN ('ticket_number','ticket_token','ticket_issued_at'))
  )
ORDER BY TABLE_NAME, COLUMN_NAME;
