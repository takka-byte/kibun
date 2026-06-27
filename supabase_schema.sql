-- ============================================================
-- Kibun (キブン) SNS - Supabase Schema
-- ============================================================

-- ユーザーテーブル
CREATE TABLE users (
  id TEXT PRIMARY KEY,                        -- ユーザーID (@handle)
  display_name TEXT NOT NULL,                 -- 表示名
  password_hash TEXT NOT NULL,                -- SHA-256 ハッシュ
  bio TEXT DEFAULT '',                        -- 自己紹介
  avatar_url TEXT DEFAULT '',                 -- アイコン画像URL
  header_url TEXT DEFAULT '',                 -- ヘッダー画像URL
  is_verified BOOLEAN DEFAULT FALSE,          -- 認証バッジ
  is_admin BOOLEAN DEFAULT FALSE,             -- 管理者
  tree_level INTEGER DEFAULT 1,               -- 木のレベル(1-10)
  tree_streak INTEGER DEFAULT 0,              -- 連続投稿日数
  tree_last_post DATE,                        -- 最終投稿日
  tree_total_posts INTEGER DEFAULT 0,         -- 累計投稿数
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 投稿テーブル
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) <= 280),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- フォローテーブル
CREATE TABLE follows (
  follower_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id)
);

-- ブロックテーブル
CREATE TABLE blocks (
  blocker_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id)
);

-- いいねテーブル
CREATE TABLE likes (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, post_id)
);

-- 通知テーブル
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,  -- 受信者
  actor_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- 送信者
  type TEXT NOT NULL CHECK (type IN ('like','follow','reply','water')),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- DMスレッドテーブル
CREATE TABLE dm_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user2_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user1_id, user2_id)
);

-- DMメッセージテーブル
CREATE TABLE dm_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES dm_threads(id) ON DELETE CASCADE,
  sender_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) <= 1000),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 水やりテーブル（友達の木に水をあげる）
CREATE TABLE tree_waters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Row Level Security (RLS)
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE tree_waters ENABLE ROW LEVEL SECURITY;

-- users: 誰でも読める、自分だけ書ける
CREATE POLICY "users_read_all" ON users FOR SELECT USING (TRUE);
CREATE POLICY "users_insert_own" ON users FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (TRUE);
CREATE POLICY "users_delete_own" ON users FOR DELETE USING (TRUE);

-- posts: 誰でも読める、誰でも書ける（アプリ側で制御）
CREATE POLICY "posts_read_all" ON posts FOR SELECT USING (TRUE);
CREATE POLICY "posts_insert_all" ON posts FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "posts_delete_all" ON posts FOR DELETE USING (TRUE);

-- follows: 誰でも読める、誰でも書ける
CREATE POLICY "follows_all" ON follows FOR ALL USING (TRUE);

-- blocks: 誰でも読める、誰でも書ける
CREATE POLICY "blocks_all" ON blocks FOR ALL USING (TRUE);

-- likes: 誰でも読める、誰でも書ける
CREATE POLICY "likes_all" ON likes FOR ALL USING (TRUE);

-- notifications: 誰でも読める、誰でも書ける
CREATE POLICY "notifications_all" ON notifications FOR ALL USING (TRUE);

-- dm_threads: 誰でも読める、誰でも書ける
CREATE POLICY "dm_threads_all" ON dm_threads FOR ALL USING (TRUE);

-- dm_messages: 誰でも読める、誰でも書ける
CREATE POLICY "dm_messages_all" ON dm_messages FOR ALL USING (TRUE);

-- tree_waters: 誰でも読める、誰でも書ける
CREATE POLICY "tree_waters_all" ON tree_waters FOR ALL USING (TRUE);

-- ============================================================
-- Storage Buckets (Supabaseダッシュボードで手動作成してください)
-- ============================================================
-- バケット名: avatars   (公開)
-- バケット名: headers   (公開)
-- ファイルサイズ上限: 5MB
-- 許可するMIMEタイプ: image/jpeg, image/png, image/gif, image/webp
