-- HABL Database Schema (MySQL 8.0+)
-- 실행 전 데이터베이스를 생성하고 선택해주세요:
--   CREATE DATABASE IF NOT EXISTS habl CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
--   USE habl;
-- 테이블 구조가 바뀌면 이미 있는 테이블에는 반영되지 않습니다 (CREATE TABLE IF NOT EXISTS).
-- 로컬 DB는 DROP DATABASE habl; 후 위 명령부터 다시 실행해주세요.

-- 1. 사용자 (users)
-- 로그인 방식: 이메일(LOCAL) + 카카오
CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NULL,
  password_hash VARCHAR(255) NULL,
  name VARCHAR(50) NOT NULL,
  birth_date DATE NULL,
  phone_number VARCHAR(20) NULL,
  role ENUM('MEMBER', 'LEADER') NOT NULL DEFAULT 'MEMBER', -- 회원: 여러 동호회 가입 / 회장: 동호회 1개 개설, 가입 불가
  provider ENUM('LOCAL', 'KAKAO') NOT NULL,
  provider_id VARCHAR(255) NULL,
  terms_agreed_at DATETIME NOT NULL,
  privacy_agreed_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  UNIQUE KEY uq_users_provider_provider_id (provider, provider_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 동호회 (clubs)
CREATE TABLE IF NOT EXISTS clubs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  category ENUM('운동', '스터디', '음악', '미술/공예', '여행', '게임', '봉사활동', '기타') NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  conditions TEXT NULL,
  image_url VARCHAR(2048) NULL,
  location_name VARCHAR(255) NOT NULL, -- 주요 활동 장소명 (예: 마포구민체육센터)
  -- 개설 폼이 아직 위치를 텍스트로만 받으므로 주소·위도·경도는 선택 (카카오맵 연동 후 필수화)
  location_address VARCHAR(500) NULL, -- 도로명 또는 지번 주소
  latitude DECIMAL(10, 7) NULL, -- 위도 (WGS84)
  longitude DECIMAL(10, 7) NULL, -- 경도 (WGS84)
  regular_meeting_info VARCHAR(255) NULL, -- 표시용 텍스트 (예: 매주 토요일 오후 2시)
  max_members SMALLINT UNSIGNED NOT NULL, -- 최대 인원 (회장 포함)
  welcome_message VARCHAR(100) NULL, -- 가입 승인 시 알림으로 보낼 메시지
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_clubs_category_latitude_longitude (category, latitude, longitude),
  CONSTRAINT chk_clubs_latitude CHECK (latitude BETWEEN -90 AND 90),
  CONSTRAINT chk_clubs_longitude CHECK (longitude BETWEEN -180 AND 180)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 동호회 회장 정보
-- 한 동호회에는 한 명의 회장, 한 회장은 하나의 동호회만 개설할 수 있다.
CREATE TABLE IF NOT EXISTS club_leaders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  leader_intro VARCHAR(40) NULL,
  activity_region VARCHAR(255) NULL,
  operation_experience ENUM('NONE', 'UNDER_ONE_YEAR', 'ONE_TO_THREE_YEARS', 'OVER_THREE_YEARS') NULL,
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_club_leaders_club_id (club_id),
  UNIQUE KEY uq_club_leaders_user_id (user_id),
  CONSTRAINT fk_club_leaders_club FOREIGN KEY (club_id) REFERENCES clubs (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_club_leaders_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_club_leaders_profile CHECK (
    TRIM(leader_intro) <> ''
    AND TRIM(activity_region) <> ''
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 동호회 회원 / 가입 신청
-- 회원 유형만 가입 신청 가능하며, 회장 유형의 신청은 백엔드에서 거절한다.
-- 회장도 개설 시 APPROVED 부원으로 등록된다 (부원 목록·인원 수에 포함).
CREATE TABLE IF NOT EXISTS club_members (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  status ENUM('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN') NOT NULL DEFAULT 'PENDING',
  introduction VARCHAR(200) NULL, -- 가입 신청 시 한마디
  applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decided_at DATETIME NULL, -- 승인 / 거절 / 탈퇴 처리 시각
  PRIMARY KEY (id),
  UNIQUE KEY uq_club_members_club_user (club_id, user_id), -- 한 행을 재사용해 거절/탈퇴 후 재신청
  KEY idx_club_members_user_status (user_id, status),
  CONSTRAINT fk_club_members_club FOREIGN KEY (club_id) REFERENCES clubs (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_club_members_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 알림 (notifications)
-- JOIN_REQUESTED: 회장에게 새 가입 신청 / JOIN_APPROVED, JOIN_REJECTED: 신청자에게 결과 / NOTICE: 부원에게 공지
CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  club_id BIGINT UNSIGNED NULL,
  type ENUM('JOIN_REQUESTED', 'JOIN_APPROVED', 'JOIN_REJECTED', 'NOTICE') NOT NULL,
  title VARCHAR(100) NOT NULL,
  content VARCHAR(500) NOT NULL,
  read_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_notifications_user_created (user_id, created_at),
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_notifications_club FOREIGN KEY (club_id) REFERENCES clubs (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. 공지 (club_notices)
-- 회장이 작성하면 승인된 부원 전원에게 NOTICE 알림을 보낸다.
CREATE TABLE IF NOT EXISTS club_notices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  author_id BIGINT UNSIGNED NOT NULL,
  content VARCHAR(500) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_club_notices_club_created (club_id, created_at),
  CONSTRAINT fk_club_notices_club FOREIGN KEY (club_id) REFERENCES clubs (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_club_notices_author FOREIGN KEY (author_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. 모임 일정 (club_meetings)
-- 회장이 날짜별로 등록한다. (clubs.regular_meeting_info 는 표시용 텍스트)
CREATE TABLE IF NOT EXISTS club_meetings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  meeting_at DATETIME NOT NULL,
  place VARCHAR(255) NULL,
  memo VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_club_meetings_club_meeting_at (club_id, meeting_at),
  CONSTRAINT fk_club_meetings_club FOREIGN KEY (club_id) REFERENCES clubs (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
