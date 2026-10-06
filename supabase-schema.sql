-- Sidequest private crew rooms: text-only posts, no uploaded photos, invite-code access.
-- Run in Supabase SQL Editor. Enable Anonymous Sign-Ins in Authentication settings first.
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.sq_rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null check (char_length(name) between 1 and 32),
  created_by uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.sq_rooms add column if not exists created_by uuid references auth.users(id) on delete cascade;
create table if not exists public.sq_members (
  room_id uuid not null references public.sq_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  nickname text not null check (char_length(nickname) between 1 and 18),
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);
create table if not exists public.sq_posts (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.sq_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  nickname text not null check (char_length(nickname) between 1 and 18),
  body text not null check (char_length(body) between 1 and 280 and body !~* '(https?://|www\.)'),
  created_at timestamptz not null default now()
);
create index if not exists sq_posts_room_created on public.sq_posts(room_id, created_at desc);
alter table public.sq_rooms enable row level security;
alter table public.sq_members enable row level security;
alter table public.sq_posts enable row level security;
revoke all on public.sq_rooms, public.sq_members, public.sq_posts from anon, authenticated;
grant select on public.sq_rooms, public.sq_members, public.sq_posts to authenticated;
grant insert, update, delete on public.sq_members to authenticated;
grant insert, delete on public.sq_posts to authenticated;

create or replace function public.sq_is_member(p_room uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.sq_members m where m.room_id = p_room and m.user_id = (select auth.uid()));
$$;
revoke all on function public.sq_is_member(uuid) from public;
grant execute on function public.sq_is_member(uuid) to authenticated;

drop policy if exists sq_room_member_read on public.sq_rooms;
create policy sq_room_member_read on public.sq_rooms for select to authenticated using (public.sq_is_member(id));
drop policy if exists sq_member_list on public.sq_members;
create policy sq_member_list on public.sq_members for select to authenticated using (public.sq_is_member(room_id));
drop policy if exists sq_member_self_join on public.sq_members;
create policy sq_member_self_join on public.sq_members for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists sq_member_self_update on public.sq_members;
create policy sq_member_self_update on public.sq_members for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists sq_member_self_leave on public.sq_members;
create policy sq_member_self_leave on public.sq_members for delete to authenticated using (user_id = (select auth.uid()));
drop policy if exists sq_post_read on public.sq_posts;
create policy sq_post_read on public.sq_posts for select to authenticated using (public.sq_is_member(room_id));
drop policy if exists sq_post_write on public.sq_posts;
create policy sq_post_write on public.sq_posts for insert to authenticated with check (user_id = (select auth.uid()) and public.sq_is_member(room_id));
drop policy if exists sq_post_delete on public.sq_posts;
create policy sq_post_delete on public.sq_posts for delete to authenticated using (user_id = (select auth.uid()) and public.sq_is_member(room_id));

create or replace function public.sq_limit_posts()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid());
  v_count integer;
  v_latest timestamptz;
begin
  if v_user is null or new.user_id <> v_user then raise exception 'Invalid sender'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_user::text || new.room_id::text, 0));
  select count(*), max(created_at) into v_count, v_latest
    from public.sq_posts where user_id = v_user and room_id = new.room_id and created_at > now() - interval '1 minute';
  if v_count >= 12 or (v_latest is not null and v_latest > now() - interval '2 seconds') then
    raise exception 'Message rate limit reached';
  end if;
  return new;
end; $$;
revoke all on function public.sq_limit_posts() from public;
drop trigger if exists sq_post_rate_limit on public.sq_posts;
create trigger sq_post_rate_limit before insert on public.sq_posts for each row execute function public.sq_limit_posts();

create or replace function public.sq_create_room(p_name text, p_nickname text)
returns table(room_id uuid, room_code text, room_name text)
language plpgsql security definer set search_path = '' as $$
declare v_id uuid; v_code text; v_name text;
begin
  if auth.uid() is null or coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false) then raise exception 'Sign in required'; end if;
  v_name := left(trim(coalesce(p_name,'')),32);
  if length(v_name) < 1 then raise exception 'Room name required'; end if;
  -- Random 20-character invite code to make guessing impractical.
  v_code := upper(encode(extensions.gen_random_bytes(10),'hex'));
  insert into public.sq_rooms(code,name,created_by) values (v_code,v_name,auth.uid()) returning id into v_id;
  insert into public.sq_members(room_id,user_id,nickname) values (v_id,auth.uid(),left(trim(coalesce(p_nickname,'')),18));
  return query select v_id,v_code,v_name;
end; $$;

create or replace function public.sq_join_room(p_code text, p_nickname text)
returns table(room_id uuid, room_code text, room_name text)
language plpgsql security definer set search_path = '' as $$
declare v_room public.sq_rooms%rowtype; v_nick text;
begin
  if auth.uid() is null or coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false) then raise exception 'Sign in required'; end if;
  v_nick := left(trim(coalesce(p_nickname,'')),18);
  if length(v_nick) < 1 then raise exception 'Nickname required'; end if;
  select * into v_room from public.sq_rooms where code = upper(trim(p_code));
  if not found then raise exception 'Invite not found'; end if;
  insert into public.sq_members(room_id,user_id,nickname) values(v_room.id,auth.uid(),v_nick)
    on conflict(room_id,user_id) do update set nickname=excluded.nickname;
  return query select v_room.id,v_room.code,v_room.name;
end; $$;

revoke all on function public.sq_create_room(text,text), public.sq_join_room(text,text) from public;
grant execute on function public.sq_create_room(text,text), public.sq_join_room(text,text) to authenticated;
do $$ begin
  alter publication supabase_realtime add table public.sq_posts;
exception when duplicate_object then null;
when undefined_object then raise notice 'Enable Realtime publication and add sq_posts in Supabase dashboard';
end $$;

-- Accounts, durable quest rewards and the cosmetic credit shop.
create table if not exists public.sq_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  credits integer not null default 0 check (credits >= 0),
  created_at timestamptz not null default now()
);
create table if not exists public.sq_rewardable_quests (
  quest_id text primary key,
  credits integer not null default 10 check (credits between 1 and 100)
);
insert into public.sq_rewardable_quests(quest_id) values
 ('faccia-casuale'),('recensione-panchina'),('merenda-segreta'),('outfit-colore'),
 ('copertina-album'),('cartello-passivo'),('doppiaggio'),('menu-immaginario'),
 ('monumento-mini'),('oggetto-lore'),('complimento-specifico'),('saluto-insegna')
on conflict(quest_id) do nothing;
create table if not exists public.sq_quest_rewards (
  user_id uuid not null references auth.users(id) on delete cascade,
  quest_id text not null references public.sq_rewardable_quests(quest_id),
  earned_at timestamptz not null default now(),
  primary key(user_id,quest_id)
);
create table if not exists public.sq_cosmetics (
  id text primary key,
  title text not null,
  price integer not null check (price > 0),
  theme_key text not null unique
);
insert into public.sq_cosmetics(id,title,price,theme_key) values
 ('skin-midnight','Afterhours',30,'midnight'),
 ('skin-sunset','Golden hour',50,'sunset'),
 ('skin-film','Rullino 2004',70,'film')
on conflict(id) do update set title=excluded.title,price=excluded.price,theme_key=excluded.theme_key;
create table if not exists public.sq_user_cosmetics (
  user_id uuid not null references auth.users(id) on delete cascade,
  cosmetic_id text not null references public.sq_cosmetics(id),
  purchased_at timestamptz not null default now(),
  primary key(user_id,cosmetic_id)
);
alter table public.sq_profiles enable row level security;
alter table public.sq_quest_rewards enable row level security;
alter table public.sq_cosmetics enable row level security;
alter table public.sq_user_cosmetics enable row level security;
revoke all on public.sq_profiles,public.sq_quest_rewards,public.sq_cosmetics,public.sq_user_cosmetics from anon,authenticated;
grant select on public.sq_profiles,public.sq_quest_rewards,public.sq_cosmetics,public.sq_user_cosmetics to authenticated;
drop policy if exists sq_profile_read_own on public.sq_profiles;
create policy sq_profile_read_own on public.sq_profiles for select to authenticated using(user_id=(select auth.uid()));
drop policy if exists sq_rewards_read_own on public.sq_quest_rewards;
create policy sq_rewards_read_own on public.sq_quest_rewards for select to authenticated using(user_id=(select auth.uid()));
drop policy if exists sq_cosmetics_read on public.sq_cosmetics;
create policy sq_cosmetics_read on public.sq_cosmetics for select to authenticated using(true);
drop policy if exists sq_owned_cosmetics_read on public.sq_user_cosmetics;
create policy sq_owned_cosmetics_read on public.sq_user_cosmetics for select to authenticated using(user_id=(select auth.uid()));

create or replace function public.sq_create_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.sq_profiles(user_id) values(new.id) on conflict(user_id) do nothing;
  return new;
end; $$;
revoke all on function public.sq_create_profile() from public,anon,authenticated;
drop trigger if exists sq_auth_user_profile on auth.users;
create trigger sq_auth_user_profile after insert on auth.users for each row execute function public.sq_create_profile();
insert into public.sq_profiles(user_id) select id from auth.users on conflict(user_id) do nothing;

create or replace function public.sq_complete_quest(p_quest_id text)
returns table(awarded integer,balance integer)
language plpgsql security definer set search_path = '' as $$
declare v_user uuid := (select auth.uid()); v_reward integer; v_inserted integer;
begin
  if v_user is null or coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false) then raise exception 'Verified account required'; end if;
  select credits into v_reward from public.sq_rewardable_quests where quest_id=p_quest_id;
  if v_reward is null then raise exception 'Quest is not rewardable'; end if;
  insert into public.sq_quest_rewards(user_id,quest_id) values(v_user,p_quest_id) on conflict do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted=1 then update public.sq_profiles set credits=credits+v_reward where user_id=v_user; end if;
  return query select case when v_inserted=1 then v_reward else 0 end,(select p.credits from public.sq_profiles p where p.user_id=v_user);
end; $$;
revoke all on function public.sq_complete_quest(text) from public,anon;
grant execute on function public.sq_complete_quest(text) to authenticated;

create or replace function public.sq_buy_cosmetic(p_cosmetic_id text)
returns table(balance integer)
language plpgsql security definer set search_path = '' as $$
declare v_user uuid := (select auth.uid()); v_price integer; v_balance integer;
begin
  if v_user is null or coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false) then raise exception 'Verified account required'; end if;
  select price into v_price from public.sq_cosmetics where id=p_cosmetic_id;
  if v_price is null then raise exception 'Cosmetic not found'; end if;
  if exists(select 1 from public.sq_user_cosmetics where user_id=v_user and cosmetic_id=p_cosmetic_id) then raise exception 'Already owned'; end if;
  update public.sq_profiles set credits=credits-v_price where user_id=v_user and credits>=v_price returning credits into v_balance;
  if not found then raise exception 'Not enough credits'; end if;
  insert into public.sq_user_cosmetics(user_id,cosmetic_id) values(v_user,p_cosmetic_id);
  return query select v_balance;
end; $$;
revoke all on function public.sq_buy_cosmetic(text) from public,anon;
grant execute on function public.sq_buy_cosmetic(text) to authenticated;

create or replace function public.sq_delete_my_account()
returns void language plpgsql security definer set search_path = '' as $$
declare v_user uuid := (select auth.uid());
begin
  if v_user is null then raise exception 'Sign in required'; end if;
  delete from public.sq_rooms where created_by=v_user;
  delete from auth.users where id=v_user;
end; $$;
revoke all on function public.sq_delete_my_account() from public,anon;
grant execute on function public.sq_delete_my_account() to authenticated;
