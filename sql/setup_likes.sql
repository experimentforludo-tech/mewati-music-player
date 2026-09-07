-- LEGACY helper. Canonical source is setup_all.sql.
-- If this file is run AFTER setup_all.sql it must NOT recreate the
-- permissive "Users can view all likes" policy.

ALTER TABLE songs ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0;

CREATE TABLE IF NOT EXISTS likes (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  song_id UUID REFERENCES songs(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, song_id)
);

ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

drop policy if exists "Users can view all likes" on likes;
drop policy if exists "Users can insert their own likes" on likes;
drop policy if exists "Users can delete their own likes" on likes;
drop policy if exists "likes_select_own" on likes;
drop policy if exists "likes_insert_own" on likes;
drop policy if exists "likes_delete_own" on likes;

create policy "likes_select_own"
  on likes for select
  using (auth.uid() = user_id);

create policy "likes_insert_own"
  on likes for insert
  with check (auth.uid() = user_id);

create policy "likes_delete_own"
  on likes for delete
  using (auth.uid() = user_id);

-- Client must use public.toggle_like (setup_all.sql), not these.
CREATE OR REPLACE FUNCTION increment_like_count(song_id_input UUID)
RETURNS void AS $$
  UPDATE songs SET like_count = like_count + 1 WHERE id = song_id_input;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION decrement_like_count(song_id_input UUID)
RETURNS void AS $$
  UPDATE songs SET like_count = GREATEST(like_count - 1, 0) WHERE id = song_id_input;
$$ LANGUAGE sql;

revoke all on function increment_like_count(uuid) from public, anon, authenticated;
revoke all on function decrement_like_count(uuid) from public, anon, authenticated;
