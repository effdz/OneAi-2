-- PocketBase Collections Setup SQL
-- Jalankan script ini di PocketBase admin panel atau via API

-- 1. Users Collection
-- Buat collection 'users' dengan fields:
-- username (text, required, min: 3, max: 50)
-- email (email, required, unique)
-- password_hash (text, required, max: 255)
-- avatar_url (url, optional)
-- is_active (bool, optional, default: true)
-- last_login (date, optional)

-- Indexes untuk users:
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users (is_active);

-- 2. Conversations Collection
-- Buat collection 'conversations' dengan fields:
-- user_id (relation to users, required, cascade delete)
-- chatbot_id (text, required, min: 1, max: 100)
-- title (text, required, min: 1, max: 255)
-- is_archived (bool, optional, default: false)

-- Indexes untuk conversations:
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations (user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_chatbot_id ON conversations (chatbot_id);
CREATE INDEX IF NOT EXISTS idx_conversations_is_archived ON conversations (is_archived);
CREATE INDEX IF NOT EXISTS idx_conversations_created ON conversations (created);
CREATE INDEX IF NOT EXISTS idx_conversations_updated ON conversations (updated);

-- 3. Messages Collection
-- Buat collection 'messages' dengan fields:
-- conversation_id (relation to conversations, required, cascade delete)
-- message_id (text, optional, max: 100)
-- content (text, required, min: 1, max: 10000)
-- is_user (bool, required)
-- token_count (number, optional, min: 0)

-- Indexes untuk messages:
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages (conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_is_user ON messages (is_user);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages (created);

-- 4. Usage Analytics Collection
-- Buat collection 'usage_analytics' dengan fields:
-- user_id (relation to users, required, cascade delete)
-- chatbot_id (text, required, min: 1, max: 100)
-- message_count (number, required, min: 0)
-- token_usage (number, required, min: 0)
-- date (date, required)

-- Indexes untuk usage_analytics:
CREATE INDEX IF NOT EXISTS idx_usage_user_id ON usage_analytics (user_id);
CREATE INDEX IF NOT EXISTS idx_usage_chatbot_id ON usage_analytics (chatbot_id);
CREATE INDEX IF NOT EXISTS idx_usage_date ON usage_analytics (date);
CREATE INDEX IF NOT EXISTS idx_usage_user_date ON usage_analytics (user_id, date);
