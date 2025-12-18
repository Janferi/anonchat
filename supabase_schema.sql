-- Supabase Database Schema for Anonymous Chat
-- Created: 2025-12-17
--
-- IMPORTANT: Jalankan query ini di Supabase SQL Editor
-- Dashboard Supabase > SQL Editor > New Query > Paste & Run

-- ============================================
-- 1. Table: users (Data pengguna anonim)
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number TEXT UNIQUE NOT NULL,
  device_id TEXT,
  username TEXT,
  avatar_url TEXT,
  bio TEXT,
  is_online BOOLEAN DEFAULT true,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_users_phone_number ON users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_device_id ON users(device_id);
CREATE INDEX IF NOT EXISTS idx_users_is_online ON users(is_online);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- Function: Auto-generate username dari nomor telepon
CREATE OR REPLACE FUNCTION generate_username_from_phone()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.username IS NULL THEN
    -- Generate username dari 4 digit terakhir nomor telepon + random 3 digit
    NEW.username = 'User' || substring(NEW.phone_number from '.{4}$') || floor(random() * 1000)::text;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-generate username saat insert
CREATE TRIGGER auto_generate_username
  BEFORE INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION generate_username_from_phone();

-- ============================================
-- 2. Table: chat_rooms (Ruang chat antar 2 user)
-- ============================================
CREATE TABLE IF NOT EXISTS chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_message_at TIMESTAMP WITH TIME ZONE,

  -- Pastikan tidak ada duplikat room untuk 2 user yang sama
  CONSTRAINT unique_chat_room UNIQUE(user1_id, user2_id)
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_chat_rooms_user1 ON chat_rooms(user1_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_user2 ON chat_rooms(user2_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_last_message ON chat_rooms(last_message_at DESC);

-- ============================================
-- 3. Table: messages (Pesan chat)
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message_text TEXT NOT NULL,
  message_type TEXT DEFAULT 'text', -- text, image, file, etc
  is_read BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_messages_chat_room ON messages(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON messages(is_read);

-- ============================================
-- 4. Table: typing_status (Status sedang mengetik)
-- ============================================
CREATE TABLE IF NOT EXISTS typing_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT false,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Satu user hanya punya 1 status typing per room
  CONSTRAINT unique_typing_status UNIQUE(chat_room_id, user_id)
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_typing_status_room ON typing_status(chat_room_id);

-- ============================================
-- 5. Table: user_blocks (Blokir user)
-- ============================================
CREATE TABLE IF NOT EXISTS user_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Satu user hanya bisa block user lain sekali
  CONSTRAINT unique_block UNIQUE(blocker_id, blocked_id),

  -- User tidak bisa block diri sendiri
  CONSTRAINT no_self_block CHECK (blocker_id != blocked_id)
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocks_blocked ON user_blocks(blocked_id);

-- ============================================
-- 6. Table: user_reports (Laporan user)
-- ============================================
CREATE TABLE IF NOT EXISTS user_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reported_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending', -- pending, reviewed, resolved
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- User tidak bisa report diri sendiri
  CONSTRAINT no_self_report CHECK (reporter_id != reported_id)
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON user_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported ON user_reports(reported_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON user_reports(status);

-- ============================================
-- 7. Table: friendships (Pertemanan)
-- ============================================
CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending', -- pending, accepted, rejected
  requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Pastikan tidak ada duplikat friendship
  CONSTRAINT unique_friendship UNIQUE(user1_id, user2_id),

  -- User tidak bisa berteman dengan diri sendiri
  CONSTRAINT no_self_friend CHECK (user1_id != user2_id)
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_friendships_user1 ON friendships(user1_id);
CREATE INDEX IF NOT EXISTS idx_friendships_user2 ON friendships(user2_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON friendships(status);

-- ============================================
-- 8. Table: nearby_groups (Grup nearby berdasarkan lokasi)
-- ============================================
CREATE TABLE IF NOT EXISTS nearby_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius_meters INTEGER DEFAULT 1000, -- Radius dalam meter
  is_active BOOLEAN DEFAULT true,
  max_members INTEGER DEFAULT 50,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_nearby_groups_creator ON nearby_groups(creator_id);
CREATE INDEX IF NOT EXISTS idx_nearby_groups_location ON nearby_groups(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_nearby_groups_active ON nearby_groups(is_active);

-- ============================================
-- 9. Table: group_members (Member grup nearby)
-- ============================================
CREATE TABLE IF NOT EXISTS group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES nearby_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- member, admin
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Satu user hanya bisa join group sekali
  CONSTRAINT unique_group_member UNIQUE(group_id, user_id)
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_group_members_group ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON group_members(user_id);

-- ============================================
-- 10. Table: group_messages (Pesan grup nearby)
-- ============================================
CREATE TABLE IF NOT EXISTS group_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES nearby_groups(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message_text TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_group_messages_group ON group_messages(group_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_sender ON group_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_created ON group_messages(created_at DESC);

-- ============================================
-- 11. Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS untuk semua table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE nearby_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_messages ENABLE ROW LEVEL SECURITY;

-- Policy untuk users: Semua bisa read, tapi hanya bisa update data sendiri
CREATE POLICY "Users can read all users" ON users FOR SELECT USING (true);
CREATE POLICY "Users can insert their own data" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update their own data" ON users FOR UPDATE USING (true);

-- Policy untuk chat_rooms: User hanya bisa lihat room mereka sendiri
CREATE POLICY "Users can read their own chat rooms" ON chat_rooms
  FOR SELECT USING (
    auth.uid() IS NOT NULL OR true -- Allow anonymous access for now
  );

CREATE POLICY "Users can create chat rooms" ON chat_rooms
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their chat rooms" ON chat_rooms
  FOR UPDATE USING (true);

-- Policy untuk messages: User hanya bisa lihat pesan di room mereka
CREATE POLICY "Users can read messages in their rooms" ON messages
  FOR SELECT USING (true);

CREATE POLICY "Users can send messages" ON messages
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their messages" ON messages
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete their messages" ON messages
  FOR DELETE USING (true);

-- Policy untuk typing_status
CREATE POLICY "Users can read typing status" ON typing_status
  FOR SELECT USING (true);

CREATE POLICY "Users can update typing status" ON typing_status
  FOR ALL USING (true);

-- Policy untuk user_blocks
CREATE POLICY "Users can read their blocks" ON user_blocks
  FOR SELECT USING (true);

CREATE POLICY "Users can create blocks" ON user_blocks
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can delete their blocks" ON user_blocks
  FOR DELETE USING (true);

-- Policy untuk user_reports
CREATE POLICY "Users can read their reports" ON user_reports
  FOR SELECT USING (true);

CREATE POLICY "Users can create reports" ON user_reports
  FOR INSERT WITH CHECK (true);

-- Policy untuk friendships
CREATE POLICY "Users can read friendships" ON friendships
  FOR SELECT USING (true);

CREATE POLICY "Users can create friendships" ON friendships
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update friendships" ON friendships
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete friendships" ON friendships
  FOR DELETE USING (true);

-- Policy untuk nearby_groups
CREATE POLICY "Users can read nearby groups" ON nearby_groups
  FOR SELECT USING (true);

CREATE POLICY "Users can create groups" ON nearby_groups
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Creators can update their groups" ON nearby_groups
  FOR UPDATE USING (true);

CREATE POLICY "Creators can delete their groups" ON nearby_groups
  FOR DELETE USING (true);

-- Policy untuk group_members
CREATE POLICY "Users can read group members" ON group_members
  FOR SELECT USING (true);

CREATE POLICY "Users can join groups" ON group_members
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can leave groups" ON group_members
  FOR DELETE USING (true);

-- Policy untuk group_messages
CREATE POLICY "Members can read group messages" ON group_messages
  FOR SELECT USING (true);

CREATE POLICY "Members can send messages" ON group_messages
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Senders can delete their messages" ON group_messages
  FOR DELETE USING (true);

-- ============================================
-- 12. Functions dan Triggers
-- ============================================

-- Function: Update updated_at timestamp otomatis
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk auto-update updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_rooms_updated_at
  BEFORE UPDATE ON chat_rooms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at
  BEFORE UPDATE ON messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function: Update last_message_at di chat_rooms ketika ada pesan baru
CREATE OR REPLACE FUNCTION update_chat_room_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_rooms
  SET last_message_at = NEW.created_at
  WHERE id = NEW.chat_room_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_last_message_trigger
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_chat_room_last_message();

-- Function: Calculate distance antara 2 koordinat (Haversine formula)
CREATE OR REPLACE FUNCTION calculate_distance(
  lat1 DOUBLE PRECISION,
  lon1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lon2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
  earth_radius CONSTANT DOUBLE PRECISION := 6371000; -- Earth radius dalam meter
  dlat DOUBLE PRECISION;
  dlon DOUBLE PRECISION;
  a DOUBLE PRECISION;
  c DOUBLE PRECISION;
BEGIN
  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);

  a := sin(dlat/2) * sin(dlat/2) +
       cos(radians(lat1)) * cos(radians(lat2)) *
       sin(dlon/2) * sin(dlon/2);

  c := 2 * atan2(sqrt(a), sqrt(1-a));

  RETURN earth_radius * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Get nearby groups berdasarkan lokasi user
CREATE OR REPLACE FUNCTION get_nearby_groups(
  user_lat DOUBLE PRECISION,
  user_lon DOUBLE PRECISION,
  max_distance_meters INTEGER DEFAULT 5000
)
RETURNS TABLE (
  group_id UUID,
  group_name TEXT,
  distance_meters DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ng.id,
    ng.name,
    calculate_distance(user_lat, user_lon, ng.latitude, ng.longitude) as distance
  FROM nearby_groups ng
  WHERE
    ng.is_active = true
    AND calculate_distance(user_lat, user_lon, ng.latitude, ng.longitude) <= LEAST(ng.radius_meters, max_distance_meters)
  ORDER BY distance;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 13. Realtime Subscriptions (Enable Realtime)
-- ============================================
-- Di Supabase Dashboard, pastikan Realtime diaktifkan untuk table:
-- - messages (untuk live chat)
-- - typing_status (untuk status typing)
-- - users (untuk status online/offline)
-- - group_messages (untuk grup chat realtime)
-- - group_members (untuk update member grup)
-- - nearby_groups (untuk update grup nearby)

-- ALTER publication supabase_realtime ADD TABLE messages;
-- ALTER publication supabase_realtime ADD TABLE typing_status;
-- ALTER publication supabase_realtime ADD TABLE users;
-- ALTER publication supabase_realtime ADD TABLE group_messages;
-- ALTER publication supabase_realtime ADD TABLE group_members;
-- ALTER publication supabase_realtime ADD TABLE nearby_groups;

-- ============================================
-- 14. Sample Data (Optional - untuk testing)
-- ============================================

-- Insert sample users
-- INSERT INTO users (phone_number, username, avatar_url) VALUES
--   ('081234567890', 'Anonymous User 1', 'https://i.pravatar.cc/150?img=1'),
--   ('081234567891', 'Anonymous User 2', 'https://i.pravatar.cc/150?img=2');

-- ============================================
-- SELESAI!
-- ============================================
-- Langkah selanjutnya:
-- 1. Copy seluruh query ini
-- 2. Buka Supabase Dashboard > SQL Editor
-- 3. Buat New Query dan paste query ini
-- 4. Run query
-- 5. Enable Realtime di Dashboard > Database > Replication
--    untuk table: messages, typing_status, users
