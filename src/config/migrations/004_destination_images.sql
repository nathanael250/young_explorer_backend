CREATE TABLE IF NOT EXISTS destination_images (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  destination_id BIGINT,
  image_path VARCHAR(255),
  sort_order INT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (destination_id) REFERENCES destinations(id)
);
