-- Sidequest private crew rooms: text-only posts, no uploaded photos, invite-code access.
-- Run in Supabase SQL Editor. Enable Anonymous Sign-Ins in Authentication settings first.
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.sq_rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null check (char_length(name) between 1 and 32),
  created_at timestamptz not null default now()
);
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
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  v_name := left(trim(coalesce(p_name,'')),32);
  if length(v_name) < 1 then raise exception 'Room name required'; end if;
  -- Random 20-character invite code to make guessing impractical.
  v_code := upper(encode(extensions.gen_random_bytes(10),'hex'));
  insert into public.sq_rooms(code,name) values (v_code,v_name) returning id into v_id;
  insert into public.sq_members(room_id,user_id,nickname) values (v_id,auth.uid(),left(trim(coalesce(p_nickname,'')),18));
  return query select v_id,v_code,v_name;
end; $$;

create or replace function public.sq_join_room(p_code text, p_nickname text)
returns table(room_id uuid, room_code text, room_name text)
language plpgsql security definer set search_path = '' as $$
declare v_room public.sq_rooms%rowtype; v_nick text;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
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
