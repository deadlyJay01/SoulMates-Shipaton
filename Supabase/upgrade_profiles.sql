-- Safe upgrade for a profiles table that already exists.
-- Run this in Supabase Dashboard → SQL Editor, then run the profile query again.
-- It adds only missing columns and does not delete existing data.

alter table public.profiles
  add column if not exists user_name text not null default '',
  add column if not exists user_gender integer not null default 0,
  add column if not exists user_phone text not null default '',
  add column if not exists relationship_type integer not null default 0,
  add column if not exists anniversary_date_timestamp double precision not null default 0,
  add column if not exists total_days_together integer not null default 0,
  add column if not exists has_profile_image boolean not null default false,
  add column if not exists profile_image_path text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();
