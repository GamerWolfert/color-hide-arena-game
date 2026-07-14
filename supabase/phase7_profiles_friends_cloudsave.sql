-- Color Hide Arena Phase 7 schema.
-- Run this in the Supabase SQL editor before enabling cloud features.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null default '',
  level integer not null default 1 check (level >= 1),
  xp integer not null default 0 check (xp >= 0),
  selected_skin text not null default 'neutral',
  body_materials jsonb not null default '{}'::jsonb,
  favorite_pose integer not null default 0 check (favorite_pose between 0 and 8),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.player_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.player_stats (
  user_id uuid primary key references auth.users(id) on delete cascade,
  rounds integer not null default 0,
  wins integer not null default 0,
  losses integer not null default 0,
  hider_rounds integer not null default 0,
  seeker_rounds integer not null default 0,
  successful_scans integer not null default 0,
  times_found integer not null default 0,
  xp_earned integer not null default 0,
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.friends (
  user_id uuid not null references auth.users(id) on delete cascade,
  friend_user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, friend_user_id),
  check (user_id <> friend_user_id)
);

create table if not exists public.recent_players (
  owner_id uuid not null references auth.users(id) on delete cascade,
  player_id uuid not null references auth.users(id) on delete cascade,
  last_seen timestamptz not null default timezone('utc', now()),
  encounter_count integer not null default 1 check (encounter_count >= 1),
  primary key (owner_id, player_id),
  check (owner_id <> player_id)
);

create table if not exists public.leaderboard_entries (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null default '',
  level integer not null default 1,
  xp integer not null default 0,
  wins integer not null default 0,
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username)
  values (new.id, coalesce(new.raw_user_meta_data->>'username', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute procedure public.handle_new_user_profile();

create or replace function public.protect_profile_progression()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.role() = 'authenticated' and (new.level <> old.level or new.xp <> old.xp) then
    raise exception 'profile progression is server managed';
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_progression on public.profiles;
create trigger protect_profile_progression
  before update on public.profiles
  for each row execute procedure public.protect_profile_progression();

alter table public.profiles enable row level security;
alter table public.player_saves enable row level security;
alter table public.player_stats enable row level security;
alter table public.friends enable row level security;
alter table public.recent_players enable row level security;
alter table public.leaderboard_entries enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using (auth.uid() = id);
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "player_saves_select_own" on public.player_saves;
create policy "player_saves_select_own" on public.player_saves for select to authenticated using (auth.uid() = user_id);
drop policy if exists "player_saves_insert_own" on public.player_saves;
create policy "player_saves_insert_own" on public.player_saves for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "player_saves_update_own" on public.player_saves;
create policy "player_saves_update_own" on public.player_saves for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "player_stats_select_own" on public.player_stats;
create policy "player_stats_select_own" on public.player_stats for select to authenticated using (auth.uid() = user_id);

drop policy if exists "friends_select_related" on public.friends;
create policy "friends_select_related" on public.friends for select to authenticated using (auth.uid() = user_id or auth.uid() = friend_user_id);
drop policy if exists "friends_insert_own" on public.friends;
create policy "friends_insert_own" on public.friends for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "friends_update_related" on public.friends;
create policy "friends_update_related" on public.friends for update to authenticated using (auth.uid() = user_id or auth.uid() = friend_user_id) with check (auth.uid() = user_id or auth.uid() = friend_user_id);
drop policy if exists "friends_delete_own" on public.friends;
create policy "friends_delete_own" on public.friends for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "recent_players_select_own" on public.recent_players;
create policy "recent_players_select_own" on public.recent_players for select to authenticated using (auth.uid() = owner_id);
drop policy if exists "recent_players_insert_own" on public.recent_players;
create policy "recent_players_insert_own" on public.recent_players for insert to authenticated with check (auth.uid() = owner_id);
drop policy if exists "recent_players_update_own" on public.recent_players;
create policy "recent_players_update_own" on public.recent_players for update to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "leaderboard_public_read" on public.leaderboard_entries;
create policy "leaderboard_public_read" on public.leaderboard_entries for select to anon, authenticated using (true);

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.player_saves to authenticated;
grant select on public.player_stats to authenticated;
grant select, insert, update, delete on public.friends to authenticated;
grant select, insert, update on public.recent_players to authenticated;
grant select on public.leaderboard_entries to anon, authenticated;

revoke all on function public.handle_new_user_profile() from public, anon, authenticated;
revoke all on function public.protect_profile_progression() from public, anon, authenticated;

create or replace function public.record_authoritative_stats(stat_row jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set xp = xp + greatest(coalesce((stat_row->>'xp_earned')::integer, 0), 0),
      updated_at = timezone('utc', now())
  where id = (stat_row->>'user_id')::uuid;

  insert into public.player_stats (user_id, rounds, wins, losses, hider_rounds, seeker_rounds, xp_earned, updated_at)
  values (
    (stat_row->>'user_id')::uuid,
    coalesce((stat_row->>'rounds')::integer, 0),
    coalesce((stat_row->>'wins')::integer, 0),
    coalesce((stat_row->>'losses')::integer, 0),
    coalesce((stat_row->>'hider_rounds')::integer, 0),
    coalesce((stat_row->>'seeker_rounds')::integer, 0),
    coalesce((stat_row->>'xp_earned')::integer, 0),
    timezone('utc', now())
  )
  on conflict (user_id) do update set
    rounds = public.player_stats.rounds + excluded.rounds,
    wins = public.player_stats.wins + excluded.wins,
    losses = public.player_stats.losses + excluded.losses,
    hider_rounds = public.player_stats.hider_rounds + excluded.hider_rounds,
    seeker_rounds = public.player_stats.seeker_rounds + excluded.seeker_rounds,
    xp_earned = public.player_stats.xp_earned + excluded.xp_earned,
    updated_at = timezone('utc', now());

  insert into public.leaderboard_entries (user_id, username, level, xp, wins, updated_at)
  select p.id, p.username, p.level, p.xp, s.wins, timezone('utc', now())
  from public.profiles p
  join public.player_stats s on s.user_id = p.id
  where p.id = (stat_row->>'user_id')::uuid
  on conflict (user_id) do update set
    username = excluded.username,
    level = excluded.level,
    xp = excluded.xp,
    wins = excluded.wins,
    updated_at = timezone('utc', now());
end;
$$;

revoke all on function public.record_authoritative_stats(jsonb) from public, anon, authenticated;
grant execute on function public.record_authoritative_stats(jsonb) to service_role;
