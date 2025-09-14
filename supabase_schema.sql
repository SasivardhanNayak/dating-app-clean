-- Under 25 Dating App Database Schema
-- Run this in the Supabase SQL Editor to create all necessary tables

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE relationship_goal AS ENUM ('serious', 'casual', 'friendship', 'networking');
CREATE TYPE swipe_action AS ENUM ('like', 'pass', 'super_like');
CREATE TYPE report_reason AS ENUM ('inappropriate_content', 'harassment', 'fake_profile', 'spam', 'other');

-- Profiles table (extends Supabase auth.users)
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    username TEXT UNIQUE,
    full_name TEXT NOT NULL,
    bio TEXT,
    age INTEGER NOT NULL CHECK (age >= 18 AND age <= 25),
    location TEXT,
    occupation TEXT,
    education TEXT,
    relationship_goal relationship_goal,
    min_age_preference INTEGER DEFAULT 18 CHECK (min_age_preference >= 18 AND min_age_preference <= 25),
    max_age_preference INTEGER DEFAULT 25 CHECK (max_age_preference >= 18 AND max_age_preference <= 25),
    max_distance_km INTEGER DEFAULT 50,
    is_active BOOLEAN DEFAULT true,
    is_premium BOOLEAN DEFAULT false,
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Interests master table
CREATE TABLE interests (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User interests junction table
CREATE TABLE user_interests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    interest_id INTEGER REFERENCES interests(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, interest_id)
);

-- User photos table
CREATE TABLE user_photos (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    display_order INTEGER DEFAULT 1,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_primary_photo UNIQUE(user_id, is_primary) DEFERRABLE INITIALLY DEFERRED
);

-- Swipes/actions table
CREATE TABLE swipes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    swiper_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    swiped_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    action swipe_action NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(swiper_id, swiped_id)
);

-- Matches table (created when two users like each other)
CREATE TABLE matches (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user1_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    matched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    CONSTRAINT match_users_different CHECK (user1_id != user2_id),
    CONSTRAINT match_user_order CHECK (user1_id < user2_id),
    UNIQUE(user1_id, user2_id)
);

-- Conversations table (for organizing messages between matched users)
CREATE TABLE conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Blocked users table
CREATE TABLE blocked_users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    blocker_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    blocked_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id),
    CONSTRAINT block_users_different CHECK (blocker_id != blocked_id)
);

-- Reports table
CREATE TABLE reports (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    reporter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reported_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reason report_reason NOT NULL,
    description TEXT,
    is_resolved BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT report_users_different CHECK (reporter_id != reported_id)
);

-- User activity/stats table (for analytics and premium features)
CREATE TABLE user_stats (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    total_likes_given INTEGER DEFAULT 0,
    total_likes_received INTEGER DEFAULT 0,
    total_super_likes_given INTEGER DEFAULT 0,
    total_super_likes_received INTEGER DEFAULT 0,
    total_matches INTEGER DEFAULT 0,
    profile_views INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default interests
INSERT INTO interests (name, category) VALUES
    ('Art', 'Creative'),
    ('Music', 'Creative'),
    ('Photography', 'Creative'),
    ('Dancing', 'Creative'),
    ('Cooking', 'Lifestyle'),
    ('Travel', 'Lifestyle'),
    ('Coffee', 'Lifestyle'),
    ('Food', 'Lifestyle'),
    ('Fashion', 'Lifestyle'),
    ('Sports', 'Active'),
    ('Fitness', 'Active'),
    ('Gaming', 'Entertainment'),
    ('Movies', 'Entertainment'),
    ('Books', 'Learning'),
    ('Technology', 'Learning'),
    ('Nature', 'Outdoor'),
    ('Animals', 'Lifestyle'),
    ('Yoga', 'Active'),
    ('Meditation', 'Wellness'),
    ('Comedy', 'Entertainment'),
    ('Adventure', 'Outdoor'),
    ('Learning', 'Education');

-- Create indexes for better performance
CREATE INDEX idx_profiles_age ON profiles(age);
CREATE INDEX idx_profiles_location ON profiles(location);
CREATE INDEX idx_profiles_active ON profiles(is_active, last_active);
CREATE INDEX idx_swipes_swiped_action ON swipes(swiped_id, action);
CREATE INDEX idx_swipes_swiper_created ON swipes(swiper_id, created_at);
CREATE INDEX idx_matches_users ON matches(user1_id, user2_id);
CREATE INDEX idx_matches_active ON matches(is_active, matched_at);
CREATE INDEX idx_messages_conversation_created ON messages(conversation_id, created_at);
CREATE INDEX idx_messages_unread ON messages(conversation_id, is_read) WHERE is_read = false;
CREATE INDEX idx_user_photos_user_order ON user_photos(user_id, display_order);
CREATE INDEX idx_blocked_users_blocker ON blocked_users(blocker_id);

-- Functions and triggers

-- Function to automatically create user stats when profile is created
CREATE OR REPLACE FUNCTION create_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_stats (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for creating user stats
CREATE TRIGGER trigger_create_user_stats
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_user_stats();

-- Function to update last_active timestamp
CREATE OR REPLACE FUNCTION update_last_active()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating profile timestamps
CREATE TRIGGER trigger_update_profiles_timestamp
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_last_active();

-- Function to create matches when mutual likes occur
CREATE OR REPLACE FUNCTION check_for_match()
RETURNS TRIGGER AS $$
DECLARE
    mutual_like_exists BOOLEAN;
    new_match_id UUID;
    conversation_id UUID;
BEGIN
    -- Only process likes and super_likes
    IF NEW.action IN ('like', 'super_like') THEN
        -- Check if the swiped user has also liked the swiper
        SELECT EXISTS(
            SELECT 1 FROM swipes 
            WHERE swiper_id = NEW.swiped_id 
            AND swiped_id = NEW.swiper_id 
            AND action IN ('like', 'super_like')
        ) INTO mutual_like_exists;
        
        -- If mutual like exists, create a match
        IF mutual_like_exists THEN
            -- Insert match (ensuring user1_id < user2_id for consistency)
            INSERT INTO matches (user1_id, user2_id)
            VALUES (
                LEAST(NEW.swiper_id, NEW.swiped_id),
                GREATEST(NEW.swiper_id, NEW.swiped_id)
            )
            ON CONFLICT (user1_id, user2_id) DO NOTHING
            RETURNING id INTO new_match_id;
            
            -- Create conversation if match was created
            IF new_match_id IS NOT NULL THEN
                INSERT INTO conversations (match_id) VALUES (new_match_id);
                
                -- Update user stats
                UPDATE user_stats 
                SET total_matches = total_matches + 1, updated_at = NOW()
                WHERE user_id IN (NEW.swiper_id, NEW.swiped_id);
            END IF;
        END IF;
        
        -- Update stats for likes
        IF NEW.action = 'like' THEN
            UPDATE user_stats 
            SET total_likes_given = total_likes_given + 1, updated_at = NOW()
            WHERE user_id = NEW.swiper_id;
            
            UPDATE user_stats 
            SET total_likes_received = total_likes_received + 1, updated_at = NOW()
            WHERE user_id = NEW.swiped_id;
        ELSIF NEW.action = 'super_like' THEN
            UPDATE user_stats 
            SET total_super_likes_given = total_super_likes_given + 1, updated_at = NOW()
            WHERE user_id = NEW.swiper_id;
            
            UPDATE user_stats 
            SET total_super_likes_received = total_super_likes_received + 1, updated_at = NOW()
            WHERE user_id = NEW.swiped_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for checking matches
CREATE TRIGGER trigger_check_for_match
    AFTER INSERT ON swipes
    FOR EACH ROW
    EXECUTE FUNCTION check_for_match();

-- Function to update conversation last_message_at
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations 
    SET last_message_at = NEW.created_at 
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating conversation timestamp
CREATE TRIGGER trigger_update_conversation_timestamp
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_timestamp();

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view active profiles" ON profiles
    FOR SELECT USING (is_active = true);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- User interests policies
CREATE POLICY "Users can manage own interests" ON user_interests
    FOR ALL USING (auth.uid() = user_id);

-- User photos policies
CREATE POLICY "Users can view photos of active profiles" ON user_photos
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = user_photos.user_id AND is_active = true)
    );

CREATE POLICY "Users can manage own photos" ON user_photos
    FOR ALL USING (auth.uid() = user_id);

-- Swipes policies
CREATE POLICY "Users can create swipes" ON swipes
    FOR INSERT WITH CHECK (auth.uid() = swiper_id);

CREATE POLICY "Users can view own swipes" ON swipes
    FOR SELECT USING (auth.uid() = swiper_id OR auth.uid() = swiped_id);

-- Matches policies
CREATE POLICY "Users can view own matches" ON matches
    FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Conversations policies
CREATE POLICY "Users can view own conversations" ON conversations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM matches 
            WHERE matches.id = conversations.match_id 
            AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
        )
    );

-- Messages policies
CREATE POLICY "Users can view messages in their conversations" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversations 
            JOIN matches ON conversations.match_id = matches.id
            WHERE conversations.id = messages.conversation_id 
            AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
        )
    );

CREATE POLICY "Users can send messages to their matches" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM conversations 
            JOIN matches ON conversations.match_id = matches.id
            WHERE conversations.id = conversation_id 
            AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
        )
    );

-- Blocked users policies
CREATE POLICY "Users can manage own blocked list" ON blocked_users
    FOR ALL USING (auth.uid() = blocker_id);

-- Reports policies
CREATE POLICY "Users can create reports" ON reports
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- User stats policies
CREATE POLICY "Users can view own stats" ON user_stats
    FOR SELECT USING (auth.uid() = user_id);

-- Interests table is public (read-only for users)
ALTER TABLE interests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view interests" ON interests
    FOR SELECT USING (true);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create a view for match discovery (potential matches)
CREATE OR REPLACE VIEW potential_matches AS
SELECT DISTINCT p.*
FROM profiles p
WHERE p.is_active = true
  AND p.id != auth.uid()
  -- Not already swiped on
  AND NOT EXISTS (
    SELECT 1 FROM swipes s 
    WHERE s.swiper_id = auth.uid() AND s.swiped_id = p.id
  )
  -- Not blocked
  AND NOT EXISTS (
    SELECT 1 FROM blocked_users b 
    WHERE (b.blocker_id = auth.uid() AND b.blocked_id = p.id)
       OR (b.blocker_id = p.id AND b.blocked_id = auth.uid())
  )
  -- Age preferences match
  AND EXISTS (
    SELECT 1 FROM profiles current_user 
    WHERE current_user.id = auth.uid()
      AND p.age BETWEEN current_user.min_age_preference AND current_user.max_age_preference
      AND current_user.age BETWEEN p.min_age_preference AND p.max_age_preference
  );

-- Grant access to the view
GRANT SELECT ON potential_matches TO authenticated;