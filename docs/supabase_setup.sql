-- Make Your Vibe Supabase setup.
-- Run this in Supabase SQL Editor after enabling Firebase Third-party Auth.
--
-- Dashboard checklist:
-- 1. Authentication > Third-party Auth > Firebase: enable project make-your-vibe.
-- 2. These policies also work when Firebase ID tokens do not include a
--    custom role claim; issuer/audience/sub checks still protect the data.
-- 3. Flutter run args may override SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY
--    or SUPABASE_ANON_KEY.

create extension if not exists "pgcrypto";

create or replace function public.current_firebase_uid()
returns text
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'sub', '')
$$;

create or replace function public.is_make_your_vibe_jwt()
returns boolean
language sql
stable
as $$
  select
    coalesce(auth.jwt() ->> 'iss', '') =
      'https://securetoken.google.com/make-your-vibe'
    and coalesce(auth.jwt() ->> 'aud', '') = 'make-your-vibe'
    and public.current_firebase_uid() is not null
$$;

create or replace function public.is_owner_storage_path(object_name text)
returns boolean
language sql
stable
as $$
  select
    (storage.foldername(object_name))[1] = 'users'
    and (storage.foldername(object_name))[2] = public.current_firebase_uid()
$$;

create table if not exists public.albums (
  id uuid primary key default gen_random_uuid(),
  owner_id text not null,
  title text not null,
  subtitle text not null default '',
  cover_path text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.songs (
  id uuid primary key default gen_random_uuid(),
  owner_id text not null,
  title text not null,
  artist text not null default '',
  album text not null default '',
  duration_seconds int not null default 0 check (duration_seconds >= 0),
  audio_path text not null,
  cover_path text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.album_songs (
  album_id uuid not null references public.albums(id) on delete cascade,
  song_id uuid not null references public.songs(id) on delete cascade,
  position int not null default 0,
  created_at timestamptz not null default now(),
  primary key (album_id, song_id)
);

create index if not exists albums_owner_created_idx
  on public.albums(owner_id, created_at desc);

create index if not exists songs_owner_created_idx
  on public.songs(owner_id, created_at desc);

create index if not exists album_songs_album_position_idx
  on public.album_songs(album_id, position);

alter table public.albums enable row level security;
alter table public.songs enable row level security;
alter table public.album_songs enable row level security;

drop policy if exists albums_select_own on public.albums;
drop policy if exists albums_insert_own on public.albums;
drop policy if exists albums_update_own on public.albums;
drop policy if exists albums_delete_own on public.albums;

create policy albums_select_own on public.albums
for select to anon, authenticated
using (
  public.is_make_your_vibe_jwt()
  and owner_id = public.current_firebase_uid()
);

create policy albums_insert_own on public.albums
for insert to anon, authenticated
with check (
  public.is_make_your_vibe_jwt()
  and owner_id = public.current_firebase_uid()
);

create policy albums_update_own on public.albums
for update to anon, authenticated
using (
  public.is_make_your_vibe_jwt()
  and owner_id = public.current_firebase_uid()
)
with check (
  public.is_make_your_vibe_jwt()
  and owner_id = public.current_firebase_uid()
);

create policy albums_delete_own on public.albums
for delete to anon, authenticated
using (
  public.is_make_your_vibe_jwt()
  and owner_id = public.current_firebase_uid()
);

drop policy if exists songs_select_own on public.songs;
drop policy if exists songs_insert_own on public.songs;
drop policy if exists songs_update_own on public.songs;
drop policy if exists songs_delete_own on public.songs;

create policy songs_select_own on public.songs
for select to anon, authenticated
using (
  public.is_make_your_vibe_jwt()
  and owner_id = public.current_firebase_uid()
);

create policy songs_insert_own on public.songs
for insert to anon, authenticated
with check (
  public.is_make_your_vibe_jwt()
  and owner_id = public.current_firebase_uid()
);

create policy songs_update_own on public.songs
for update to anon, authenticated
using (
  public.is_make_your_vibe_jwt()
  and owner_id = public.current_firebase_uid()
)
with check (
  public.is_make_your_vibe_jwt()
  and owner_id = public.current_firebase_uid()
);

create policy songs_delete_own on public.songs
for delete to anon, authenticated
using (
  public.is_make_your_vibe_jwt()
  and owner_id = public.current_firebase_uid()
);

drop policy if exists album_songs_select_own on public.album_songs;
drop policy if exists album_songs_insert_own on public.album_songs;
drop policy if exists album_songs_update_own on public.album_songs;
drop policy if exists album_songs_delete_own on public.album_songs;

create policy album_songs_select_own on public.album_songs
for select to anon, authenticated
using (
  public.is_make_your_vibe_jwt()
  and exists (
    select 1
    from public.albums
    where albums.id = album_songs.album_id
      and albums.owner_id = public.current_firebase_uid()
  )
);

create policy album_songs_insert_own on public.album_songs
for insert to anon, authenticated
with check (
  public.is_make_your_vibe_jwt()
  and exists (
    select 1
    from public.albums
    where albums.id = album_songs.album_id
      and albums.owner_id = public.current_firebase_uid()
  )
  and exists (
    select 1
    from public.songs
    where songs.id = album_songs.song_id
      and songs.owner_id = public.current_firebase_uid()
  )
);

create policy album_songs_update_own on public.album_songs
for update to anon, authenticated
using (
  public.is_make_your_vibe_jwt()
  and exists (
    select 1
    from public.albums
    where albums.id = album_songs.album_id
      and albums.owner_id = public.current_firebase_uid()
  )
)
with check (
  public.is_make_your_vibe_jwt()
  and exists (
    select 1
    from public.albums
    where albums.id = album_songs.album_id
      and albums.owner_id = public.current_firebase_uid()
  )
  and exists (
    select 1
    from public.songs
    where songs.id = album_songs.song_id
      and songs.owner_id = public.current_firebase_uid()
  )
);

create policy album_songs_delete_own on public.album_songs
for delete to anon, authenticated
using (
  public.is_make_your_vibe_jwt()
  and exists (
    select 1
    from public.albums
    where albums.id = album_songs.album_id
      and albums.owner_id = public.current_firebase_uid()
  )
);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'songs',
  'songs',
  false,
  104857600,
  array[
    'audio/aac',
    'audio/flac',
    'audio/mpeg',
    'audio/mp4',
    'audio/ogg',
    'audio/wav',
    'audio/webm',
    'audio/x-m4a',
    'audio/x-wav',
    'application/octet-stream'
  ]
), (
  'covers',
  'covers',
  false,
  10485760,
  array[
    'image/avif',
    'image/gif',
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/octet-stream'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "songs_owner_select" on storage.objects;
drop policy if exists "songs_owner_insert" on storage.objects;
drop policy if exists "songs_owner_update" on storage.objects;
drop policy if exists "songs_owner_delete" on storage.objects;
drop policy if exists "covers_owner_select" on storage.objects;
drop policy if exists "covers_owner_insert" on storage.objects;
drop policy if exists "covers_owner_update" on storage.objects;
drop policy if exists "covers_owner_delete" on storage.objects;

create policy "songs_owner_select" on storage.objects
for select to anon, authenticated
using (
  bucket_id = 'songs'
  and public.is_make_your_vibe_jwt()
  and public.is_owner_storage_path(name)
);

create policy "songs_owner_insert" on storage.objects
for insert to anon, authenticated
with check (
  bucket_id = 'songs'
  and public.is_make_your_vibe_jwt()
  and public.is_owner_storage_path(name)
);

create policy "songs_owner_update" on storage.objects
for update to anon, authenticated
using (
  bucket_id = 'songs'
  and public.is_make_your_vibe_jwt()
  and public.is_owner_storage_path(name)
)
with check (
  bucket_id = 'songs'
  and public.is_make_your_vibe_jwt()
  and public.is_owner_storage_path(name)
);

create policy "songs_owner_delete" on storage.objects
for delete to anon, authenticated
using (
  bucket_id = 'songs'
  and public.is_make_your_vibe_jwt()
  and public.is_owner_storage_path(name)
);

create policy "covers_owner_select" on storage.objects
for select to anon, authenticated
using (
  bucket_id = 'covers'
  and public.is_make_your_vibe_jwt()
  and public.is_owner_storage_path(name)
);

create policy "covers_owner_insert" on storage.objects
for insert to anon, authenticated
with check (
  bucket_id = 'covers'
  and public.is_make_your_vibe_jwt()
  and public.is_owner_storage_path(name)
);

create policy "covers_owner_update" on storage.objects
for update to anon, authenticated
using (
  bucket_id = 'covers'
  and public.is_make_your_vibe_jwt()
  and public.is_owner_storage_path(name)
)
with check (
  bucket_id = 'covers'
  and public.is_make_your_vibe_jwt()
  and public.is_owner_storage_path(name)
);

create policy "covers_owner_delete" on storage.objects
for delete to anon, authenticated
using (
  bucket_id = 'covers'
  and public.is_make_your_vibe_jwt()
  and public.is_owner_storage_path(name)
);
