-- Brain Dump — Supabase schema
-- Run this in the Supabase SQL editor: https://pugddmfdichgghiocoym.supabase.co

-- Notes table
-- IDs are client-generated UUIDs so the same ID is used in localStorage and Supabase.
create table if not exists notes (
  id          uuid        primary key,
  user_id     uuid        not null references auth.users on delete cascade,
  text        text        not null,
  ts          timestamptz not null,                    -- when the note was captured
  device_type text        not null check (device_type in ('mobile', 'desktop')),
  synced_at   timestamptz default now(),               -- when it first reached Supabase
  deleted_at  timestamptz                              -- soft-delete; null = live
);

-- Index for common query pattern
create index if not exists notes_user_deleted on notes (user_id, deleted_at);

-- Row-level security: each user can only touch their own rows
alter table notes enable row level security;

drop policy if exists "owner_all" on notes;
create policy "owner_all" on notes
  for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Grant table access to authenticated users
grant all on public.notes to authenticated;

-- Settings table (one row per user, stores synced API key)
create table if not exists settings (
  user_id       uuid primary key references auth.users on delete cascade,
  anthropic_key text
);

alter table settings enable row level security;

drop policy if exists "owner_all" on settings;
create policy "owner_all" on settings
  for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant all on public.settings to authenticated;
