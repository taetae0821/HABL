-- HABL Database Schema (MySQL 8.0+)
-- 실행 전 데이터베이스를 생성하고 선택해주세요:
--   CREATE DATABASE IF NOT EXISTS habl CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
--   USE habl;

-- 1. 사용자 (users)
CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NULL,
  password_hash VARCHAR(255) NULL,
  name VARCHAR(50) NOT NULL,
  phone_number VARCHAR(20) NULL,
  role ENUM('MEMBER', 'LEADER') NOT NULL DEFAULT 'MEMBER',
  provider ENUM('LOCAL', 'KAKAO', 'GOOGLE') NOT NULL DEFAULT 'LOCAL',
  provider_id VARCHAR(255) NULL,
  terms_agreed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  privacy_agreed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  marketing_agreed BOOLEAN NOT NULL DEFAULT FALSE,
  marketing_agreed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  UNIQUE KEY uq_users_provider_provider_id (provider, provider_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 동호회 카테고리 / 종목 (categories)
CREATE TABLE IF NOT EXISTS categories (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  icon_url VARCHAR(2048) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categories_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 동호회 (clubs)
CREATE TABLE IF NOT EXISTS clubs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  category_id INT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  conditions TEXT NULL,
  image_url VARCHAR(2048) NULL,
  location_name VARCHAR(255) NOT NULL, -- 주요 활동 장소명 (예: 마포구민체육센터)
  location_address VARCHAR(500) NOT NULL, -- 도로명 또는 지번 주소
  latitude DECIMAL(10, 7) NOT NULL, -- 위도 (WGS84)
  longitude DECIMAL(10, 7) NOT NULL, -- 경도 (WGS84)
  regular_meeting_info VARCHAR(255) NULL,
  status ENUM('ACTIVE', 'CLOSED') NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_clubs_category_status (category_id, status),
  KEY idx_clubs_latitude_longitude (latitude, longitude),
  CONSTRAINT fk_clubs_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 동호회 회장 / 개설자 정보
-- 한 동호회에는 한 명의 회장, 한 회장은 하나의 동호회만 개설할 수 있다.
CREATE TABLE IF NOT EXISTS club_leaders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  contact_number VARCHAR(20) NULL,
  appointment_type ENUM('CREATOR', 'DELEGATED') NOT NULL DEFAULT 'CREATOR',
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_club_leaders_club_id (club_id),
  UNIQUE KEY uq_club_leaders_user_id (user_id),
  CONSTRAINT fk_club_leaders_club FOREIGN KEY (club_id) REFERENCES clubs (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_club_leaders_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 동호회 회원 / 가입 신청
-- 회원 유형만 가입 신청 가능하며, 회장 유형의 신청은 백엔드에서 거절한다.
CREATE TABLE IF NOT EXISTS club_members (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  status ENUM('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN') NOT NULL DEFAULT 'PENDING',
  applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  approved_at DATETIME NULL,
  rejected_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_club_members_club_user (club_id, user_id), -- 동일 동호회 중복 신청 방지
  CONSTRAINT fk_club_members_club FOREIGN KEY (club_id) REFERENCES clubs (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_club_members_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. 알림 (notifications)
-- 가입 신청의 승인 또는 거절 결과를 신청자에게 전달한다.
CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  club_id BIGINT UNSIGNED NULL,
  type ENUM('JOIN_APPROVED', 'JOIN_REJECTED') NOT NULL,
  title VARCHAR(100) NOT NULL,
  content VARCHAR(500) NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_notifications_user_read_created (user_id, is_read, created_at),
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_notifications_club FOREIGN KEY (club_id) REFERENCES clubs (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
