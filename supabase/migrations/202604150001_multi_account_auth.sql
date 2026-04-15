create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Student',
  email text not null default '',
  avatar text,
  student_code text,
  joined_at timestamptz not null default timezone('utc', now()),
  dark_mode boolean not null default false,
  notifications_enabled boolean not null default true,
  onboarding_done boolean not null default false,
  focus_duration integer not null default 25,
  short_break_duration integer not null default 5,
  long_break_duration integer not null default 15,
  study_goal_minutes integer not null default 120,
  legacy_migrated_at timestamptz
);

grant select, insert, update, delete on table public.profiles to authenticated;

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

alter table public.semesters add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.subjects add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.schedules add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.deadlines add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.study_plans add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.pomodoro_sessions add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.notes add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.notifications add column if not exists user_id uuid references auth.users(id) on delete cascade;

create index if not exists semesters_user_id_idx on public.semesters(user_id);
create index if not exists subjects_user_id_idx on public.subjects(user_id);
create index if not exists schedules_user_id_idx on public.schedules(user_id);
create index if not exists deadlines_user_id_idx on public.deadlines(user_id);
create index if not exists study_plans_user_id_idx on public.study_plans(user_id);
create index if not exists pomodoro_sessions_user_id_idx on public.pomodoro_sessions(user_id);
create index if not exists notes_user_id_idx on public.notes(user_id);
create index if not exists notifications_user_id_idx on public.notifications(user_id);

alter table public.semesters enable row level security;
alter table public.subjects enable row level security;
alter table public.schedules enable row level security;
alter table public.deadlines enable row level security;
alter table public.study_plans enable row level security;
alter table public.pomodoro_sessions enable row level security;
alter table public.notes enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "semesters_owner_all" on public.semesters;
create policy "semesters_owner_all"
on public.semesters
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "subjects_owner_all" on public.subjects;
create policy "subjects_owner_all"
on public.subjects
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "schedules_owner_all" on public.schedules;
create policy "schedules_owner_all"
on public.schedules
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "deadlines_owner_all" on public.deadlines;
create policy "deadlines_owner_all"
on public.deadlines
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "study_plans_owner_all" on public.study_plans;
create policy "study_plans_owner_all"
on public.study_plans
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "pomodoro_sessions_owner_all" on public.pomodoro_sessions;
create policy "pomodoro_sessions_owner_all"
on public.pomodoro_sessions
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "notes_owner_all" on public.notes;
create policy "notes_owner_all"
on public.notes
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "notifications_owner_all" on public.notifications;
create policy "notifications_owner_all"
on public.notifications
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

revoke all on table public.user_settings from anon, authenticated;
alter table public.user_settings enable row level security;

notify pgrst, 'reload schema';
