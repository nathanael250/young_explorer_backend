CREATE TABLE IF NOT EXISTS package_images (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  package_id BIGINT,
  image_path VARCHAR(255),
  sort_order INT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (package_id) REFERENCES packages(id)
);
