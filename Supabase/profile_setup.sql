-- Run this once in Supabase Dashboard → SQL Editor.
-- The iOS app writes only the signed-in user's row and image folder.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  user_name text not null default '',
  user_gender integer not null default 0 check (user_gender between 0 and 3),
  user_phone text not null unique,
  relationship_type integer not null default 0 check (relationship_type between 0 and 2),
  anniversary_date_timestamp double precision not null default 0,
  total_days_together integer not null default 0,
  has_profile_image boolean not null default false,
  profile_image_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can read their own profile"
on public.profiles for select to authenticated
using ((select auth.uid()) = id);

create policy "Users can create their own profile"
on public.profiles for insert to authenticated
with check ((select auth.uid()) = id);

create policy "Users can update their own profile"
on public.profiles for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

insert into storage.buckets (id, name, public)
values ('profile-images', 'profile-images', false)
on conflict (id) do nothing;

create policy "Users can read their own profile image"
on storage.objects for select to authenticated
using (bucket_id = 'profile-images' and (storage.foldername(name))[1] = (select auth.uid()::text));

create policy "Users can upload their own profile image"
on storage.objects for insert to authenticated
with check (bucket_id = 'profile-images' and (storage.foldername(name))[1] = (select auth.uid()::text));

create policy "Users can update their own profile image"
on storage.objects for update to authenticated
using (bucket_id = 'profile-images' and (storage.foldername(name))[1] = (select auth.uid()::text))
with check (bucket_id = 'profile-images' and (storage.foldername(name))[1] = (select auth.uid()::text));
