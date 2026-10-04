ALTER TABLE packages
MODIFY approval_status ENUM('approved','rejected') DEFAULT 'approved';

UPDATE packages
SET approval_status = 'approved'
WHERE approval_status <> 'rejected';
