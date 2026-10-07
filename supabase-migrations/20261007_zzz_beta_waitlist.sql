-- Beta access requests: private by default; writes come only from the Pages Function.
create table if not exists public.sq_beta_signups (
  id uuid primary key default gen_random_uuid(),
  email text not null unique check (length(email) between 3 and 254),
  platform text not null check (platform in ('android', 'ios')),
  telegram_username text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'invited', 'declined')),
  privacy_consent boolean not null check (privacy_consent),
  age_confirmed boolean not null check (age_confirmed),
  consent_version text not null,
  consent_at timestamptz not null,
  created_at timestamptz not null default now(),
  constraint sq_beta_android_telegram check (platform <> 'android' or telegram_username is not null),
  constraint sq_beta_telegram_shape check (telegram_username is null or telegram_username ~ '^@[A-Za-z0-9_]{5,32}$')
);
alter table public.sq_beta_signups enable row level security;
revoke all on table public.sq_beta_signups from public, anon, authenticated;
grant all on table public.sq_beta_signups to service_role;
comment on table public.sq_beta_signups is 'Private beta applications. Review and update status only through trusted Supabase admin tools.';
alter table public.sq_beta_signups drop column if exists device_model;
