CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(30),
    password VARCHAR(255),
    role ENUM('admin','explorer','vendor') DEFAULT 'explorer',
    profile_image VARCHAR(255),
    status ENUM('active','inactive','blocked') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vendors (
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


CREATE TABLE package_durations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100),
    total_days INT,
    status ENUM('active','inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE packages (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255),
    slug VARCHAR(255),
    short_description TEXT,
    full_description LONGTEXT,
    price_per_person DECIMAL(10,2) DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'USD',
    duration_id BIGINT,
    main_image VARCHAR(255),
    meeting_point VARCHAR(255),
    emergency_contact VARCHAR(100),
    age_range VARCHAR(100),
    fitness_level VARCHAR(100),
    cancellation_policy TEXT,
    status ENUM('draft','published','archived') DEFAULT 'draft',
    created_by BIGINT,
    vendor_id BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (duration_id)
    REFERENCES package_durations(id),
    FOREIGN KEY (created_by)
    REFERENCES users(id)
);

CREATE TABLE categories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    slug VARCHAR(120) UNIQUE,
    status ENUM('active','inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE package_categories (
    package_id BIGINT,
    category_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (package_id, category_id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE package_days (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    package_id BIGINT,
    day_number INT,
    title VARCHAR(255),
    summary TEXT,
    accommodation VARCHAR(255),
    meals VARCHAR(255),
    start_time TIME,
    end_time TIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

CREATE TABLE package_images (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    package_id BIGINT,
    image_path VARCHAR(255),
    sort_order INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

CREATE TABLE destinations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    slug VARCHAR(255) UNIQUE,
    province VARCHAR(100),
    district VARCHAR(100),
    category VARCHAR(100),
    short_description TEXT,
    full_description LONGTEXT,
    best_time_to_visit VARCHAR(255),
    entry_fee DECIMAL(10,2),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    main_image VARCHAR(255),
    status ENUM('active','inactive') DEFAULT 'active',
    vendor_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(id),
    INDEX idx_destinations_slug (slug),
    UNIQUE KEY unique_vendor_destination_slug (vendor_id, slug)
);

CREATE TABLE destination_images (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    destination_id BIGINT,
    image_path VARCHAR(255),
    sort_order INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (destination_id) REFERENCES destinations(id)
);

CREATE TABLE package_day_destinations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    package_day_id BIGINT,
    destination_id BIGINT,
    visit_order INT,
    activity_title VARCHAR(255),
    activity_description TEXT,
    arrival_time TIME,
    departure_time TIME,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_day_id) REFERENCES package_days(id),
    FOREIGN KEY (destination_id) REFERENCES destinations(id)
);

CREATE TABLE package_inclusions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    package_id BIGINT,
    item VARCHAR(255),
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

CREATE TABLE package_exclusions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    package_id BIGINT,
    item VARCHAR(255),
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

CREATE TABLE package_required_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    package_id BIGINT,
    item VARCHAR(255),
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

CREATE TABLE package_not_allowed_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    package_id BIGINT,
    item VARCHAR(255),

    FOREIGN KEY (package_id) REFERENCES packages(id)
);

CREATE TABLE package_availability (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    package_id BIGINT,
    start_date DATE,
    end_date DATE,
    total_seats INT,
    reserved_seats INT DEFAULT 0,
    confirmed_seats INT DEFAULT 0,
    booking_cutoff_hours INT DEFAULT 24,
    remaining_seats INT GENERATED ALWAYS AS (
        total_seats - reserved_seats - confirmed_seats
    ) STORED,
    status ENUM(
        'available',
        'fully_booked',
        'cancelled',
        'closed'
    ) DEFAULT 'available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

CREATE TABLE bookings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    booking_reference VARCHAR(100) UNIQUE,
    user_id BIGINT,
    package_id BIGINT,
    availability_id BIGINT,
    total_people INT,
    total_amount DECIMAL(10,2),
    special_request TEXT,
    booking_type ENUM('standard','vip') DEFAULT 'standard',
    vip_request_details TEXT,
    vip_contact_name VARCHAR(150),
    vip_contact_email VARCHAR(150),
    vip_contact_phone VARCHAR(30),
    vip_preferred_contact VARCHAR(30),
    quoted_amount DECIMAL(10,2),
    quoted_currency VARCHAR(10) DEFAULT 'USD',
    booking_status ENUM(
        'quote_pending',
        'pending',
        'confirmed',
        'cancelled',
        'expired',
        'completed'
    ) DEFAULT 'pending',
    payment_status ENUM(
        'unpaid',
        'partial',
        'paid',
        'refunded'
    ) DEFAULT 'unpaid',
    booked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (availability_id) REFERENCES package_availability(id)
);

CREATE TABLE booking_participants (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    booking_id BIGINT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    gender VARCHAR(20),
    date_of_birth DATE,
    passport_number VARCHAR(100),
    nationality VARCHAR(100),
    emergency_contact VARCHAR(100),
    FOREIGN KEY (booking_id) REFERENCES bookings(id)
);

CREATE TABLE payments (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    booking_id BIGINT,
    amount DECIMAL(10,2),
    payment_method VARCHAR(100),
    transaction_reference VARCHAR(255),
    payment_proof VARCHAR(255),
    payment_status ENUM(
        'pending',
        'verified',
        'rejected'
    ) DEFAULT 'pending',
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id)
);

CREATE TABLE messages (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(255),
    email VARCHAR(150),
    subject VARCHAR(255),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE media_files (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    file_name VARCHAR(255),
    file_path VARCHAR(255),
    file_type VARCHAR(100),
    uploaded_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (uploaded_by) REFERENCES users(id)
);

INSERT INTO package_durations (title, total_days, status) VALUES
('3 Days', 3, 'active'),
('5 Days', 5, 'active'),
('7 Days', 7, 'active'),
('14 Days', 14, 'active');

INSERT INTO categories (name, slug, status) VALUES
('History', 'history', 'active'),
('Art', 'art', 'active'),
('Entertainment', 'entertainment', 'active'),
('Science', 'science', 'active'),
('Culture', 'culture', 'active'),
('Nature', 'nature', 'active'),
('Adventure', 'adventure', 'active'),
('Education', 'education', 'active');
