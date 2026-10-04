DROP DATABASE IF EXISTS junior;

CREATE DATABASE junior
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE junior;

SOURCE src/config/db.sql;
SOURCE src/config/migrations/002_indexes_and_constraints.sql;
SOURCE src/config/migrations/010_newsletter_subscribers.sql;
