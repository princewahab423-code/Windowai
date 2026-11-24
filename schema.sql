-- Window AI — Cloudflare D1 schema. Apply with:  npx wrangler d1 execute window-ai-db --remote --file=./schema.sql
CREATE TABLE IF NOT EXISTS users (
  id              TEXT PRIMARY KEY,
  google_sub      TEXT NOT NULL UNIQUE,
  email           TEXT NOT NULL,
  name            TEXT NOT NULL DEFAULT '',
  picture         TEXT NOT NULL DEFAULT '',
  username        TEXT,
  username_lower  TEXT,
  plan            TEXT NOT NULL DEFAULT 'free',
  tokens          INTEGER NOT NULL DEFAULT 0 CHECK (tokens >= 0),
  memory_enabled  INTEGER NOT NULL DEFAULT 1,
  created_at      TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS users_username_lower ON users(username_lower);
CREATE INDEX IF NOT EXISTS users_email ON users(email);

CREATE TABLE IF NOT EXISTS sessions (
  hash        TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL,
  expires_at  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_user ON sessions(user_id);

CREATE TABLE IF NOT EXISTS chats (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL,
  title       TEXT NOT NULL,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS chats_user_updated ON chats(user_id, updated_at);

CREATE TABLE IF NOT EXISTS messages (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  chat_id  TEXT NOT NULL,
  user_id  TEXT NOT NULL,
  role     TEXT NOT NULL,
  text     TEXT NOT NULL,
  at       TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS messages_chat ON messages(chat_id, id);

CREATE TABLE IF NOT EXISTS memory (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL,
  text        TEXT NOT NULL,
  created_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS memory_user ON memory(user_id, created_at);

-- Every token change (starter allocation, usage, refunds, admin grants) is recorded here.
CREATE TABLE IF NOT EXISTS ledger (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id  TEXT NOT NULL,
  delta    INTEGER NOT NULL,
  reason   TEXT NOT NULL,
  at       TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS ledger_user ON ledger(user_id, id);
