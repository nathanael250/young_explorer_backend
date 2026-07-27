ALTER TABLE packages
MODIFY approval_status ENUM('pending','approved','rejected') DEFAULT 'approved';

UPDATE packages
SET approval_status = 'approved'
WHERE approval_status = 'pending';
