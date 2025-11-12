-- Seed databases and extensions for the Sprinkler stack.
-- The script runs automatically when the container initialises for the first time.

CREATE DATABASE sprinkler_web;

\connect sprinkler_web
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

