-- Única tabla adicional; no modifica las tablas del sistema administrativo.
CREATE TABLE IF NOT EXISTS mobile_login_attempts (
  attempt_key VARCHAR(64) PRIMARY KEY,
  attempts INT UNSIGNED NOT NULL DEFAULT 0,
  window_start DATETIME NOT NULL,
  INDEX mobile_attempt_window (window_start)
);

CREATE TABLE IF NOT EXISTS mobile_sessions (
  token_hash CHAR(64) PRIMARY KEY,
  employee_id BIGINT UNSIGNED NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL,
  INDEX mobile_session_employee (employee_id),
  INDEX mobile_session_expiry (expires_at)
);
