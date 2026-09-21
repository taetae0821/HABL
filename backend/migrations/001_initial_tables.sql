-- HABL initial tables (MySQL 8.0+)
-- Create and select the database before running this file:
--   CREATE DATABASE habl CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
--   USE habl;

CREATE TABLE users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NULL,
  password_hash VARCHAR(255) NULL,
  name VARCHAR(50) NOT NULL,
  provider ENUM('LOCAL', 'KAKAO', 'GOOGLE') NOT NULL,
  provider_id VARCHAR(255) NULL,
  marketing_agreed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  UNIQUE KEY uq_users_provider_provider_id (provider, provider_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categories (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  icon_url VARCHAR(2048) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categories_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE clubs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  category_id INT UNSIGNED NOT NULL,
  owner_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  conditions TEXT NULL,
  image_url VARCHAR(2048) NULL,
  location_name VARCHAR(255) NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  regular_meeting_info VARCHAR(255) NULL,
  status ENUM('ACTIVE', 'CLOSED') NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_clubs_category_id (category_id),
  KEY idx_clubs_owner_id (owner_id),
  CONSTRAINT fk_clubs_category
    FOREIGN KEY (category_id) REFERENCES categories (id),
  CONSTRAINT fk_clubs_owner
    FOREIGN KEY (owner_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE club_members (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  role ENUM('LEADER', 'MEMBER') NOT NULL DEFAULT 'MEMBER',
  status ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
  applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  approved_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_club_members_club_user (club_id, user_id),
  KEY idx_club_members_user_id (user_id),
  CONSTRAINT fk_club_members_club
    FOREIGN KEY (club_id) REFERENCES clubs (id),
  CONSTRAINT fk_club_members_user
    FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
