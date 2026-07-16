insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'songs',
  'songs',
  true,
  52428800,
  array[
    'audio/mpeg',
    'audio/mp4',
    'audio/wav',
    'audio/x-wav',
    'video/mp4',
    'application/octet-stream'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'covers',
  'covers',
  true,
  5242880,
  array[
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

drop policy if exists "Users read own vibe files" on storage.objects;
create policy "Users read own vibe files"
on storage.objects for select
to anon, authenticated
using (
  bucket_id in ('songs', 'covers')
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = auth.jwt() ->> 'sub'
  and auth.jwt() ->> 'aud' = 'make-your-vibe'
  and auth.jwt() ->> 'iss' = 'https://securetoken.google.com/make-your-vibe'
);

drop policy if exists "Users upload own vibe files" on storage.objects;
create policy "Users upload own vibe files"
on storage.objects for insert
to anon, authenticated
with check (
  bucket_id in ('songs', 'covers')
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = auth.jwt() ->> 'sub'
  and auth.jwt() ->> 'aud' = 'make-your-vibe'
  and auth.jwt() ->> 'iss' = 'https://securetoken.google.com/make-your-vibe'
);

drop policy if exists "Users update own vibe files" on storage.objects;
create policy "Users update own vibe files"
on storage.objects for update
to anon, authenticated
using (
  bucket_id in ('songs', 'covers')
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = auth.jwt() ->> 'sub'
  and auth.jwt() ->> 'aud' = 'make-your-vibe'
  and auth.jwt() ->> 'iss' = 'https://securetoken.google.com/make-your-vibe'
)
with check (
  bucket_id in ('songs', 'covers')
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = auth.jwt() ->> 'sub'
  and auth.jwt() ->> 'aud' = 'make-your-vibe'
  and auth.jwt() ->> 'iss' = 'https://securetoken.google.com/make-your-vibe'
);

drop policy if exists "Users delete own vibe files" on storage.objects;
create policy "Users delete own vibe files"
on storage.objects for delete
to anon, authenticated
using (
  bucket_id in ('songs', 'covers')
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = auth.jwt() ->> 'sub'
  and auth.jwt() ->> 'aud' = 'make-your-vibe'
  and auth.jwt() ->> 'iss' = 'https://securetoken.google.com/make-your-vibe'
);
