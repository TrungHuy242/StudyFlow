create table if not exists public.semesters (
  id bigserial primary key,
  name text not null,
  start_date date not null,
  end_date date not null,
  is_active boolean not null default false
);

create table if not exists public.subjects (
  id bigserial primary key,
  semester_id bigint references public.semesters(id) on delete set null,
  name text not null,
  code text,
  color text,
  credits integer,
  teacher text,
  room text,
  note text
);

create table if not exists public.schedules (
  id bigserial primary key,
  subject_id bigint references public.subjects(id) on delete cascade,
  weekday integer not null,
  start_time time not null,
  end_time time not null,
  room text,
  type text
);

create table if not exists public.deadlines (
  id bigserial primary key,
  subject_id bigint references public.subjects(id) on delete set null,
  title text not null,
  description text,
  due_date date not null,
  due_time time,
  priority text,
  status text,
  progress integer not null default 0
);

create table if not exists public.study_plans (
  id bigserial primary key,
  subject_id bigint references public.subjects(id) on delete set null,
  title text not null,
  plan_date date not null,
  start_time time,
  end_time time,
  duration integer,
  topic text,
  status text
);

create table if not exists public.pomodoro_sessions (
  id bigserial primary key,
  subject_id bigint references public.subjects(id) on delete set null,
  session_date date not null,
  duration integer not null,
  type text,
  completed_at timestamptz
);

create table if not exists public.notes (
  id bigserial primary key,
  subject_id bigint references public.subjects(id) on delete set null,
  title text not null,
  content text,
  color text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.notifications (
  id bigserial primary key,
  type text,
  title text not null,
  message text,
  scheduled_at timestamptz,
  is_read boolean not null default false,
  related_id bigint
);

create table if not exists public.user_settings (
  id bigint primary key,
  display_name text,
  email text,
  avatar text,
  dark_mode boolean not null default false,
  notifications_enabled boolean not null default true,
  onboarding_done boolean not null default false,
  local_password text,
  is_logged_in boolean not null default false,
  focus_duration integer not null default 25,
  short_break_duration integer not null default 5,
  long_break_duration integer not null default 15,
  study_goal_minutes integer not null default 120
);

insert into public.user_settings (
  id,
  display_name,
  email,
  avatar,
  dark_mode,
  notifications_enabled,
  onboarding_done,
  local_password,
  is_logged_in,
  focus_duration,
  short_break_duration,
  long_break_duration,
  study_goal_minutes
)
values (
  1,
  'Student',
  '',
  null,
  false,
  true,
  false,
  null,
  false,
  25,
  5,
  15,
  120
)
on conflict (id) do nothing;

create or replace function public.reset_studyflow_sequences()
returns void
language plpgsql
security definer
as $$
begin
  perform setval(pg_get_serial_sequence('public.semesters', 'id'), coalesce((select max(id) from public.semesters), 0) + 1, false);
  perform setval(pg_get_serial_sequence('public.subjects', 'id'), coalesce((select max(id) from public.subjects), 0) + 1, false);
  perform setval(pg_get_serial_sequence('public.schedules', 'id'), coalesce((select max(id) from public.schedules), 0) + 1, false);
  perform setval(pg_get_serial_sequence('public.deadlines', 'id'), coalesce((select max(id) from public.deadlines), 0) + 1, false);
  perform setval(pg_get_serial_sequence('public.study_plans', 'id'), coalesce((select max(id) from public.study_plans), 0) + 1, false);
  perform setval(pg_get_serial_sequence('public.pomodoro_sessions', 'id'), coalesce((select max(id) from public.pomodoro_sessions), 0) + 1, false);
  perform setval(pg_get_serial_sequence('public.notes', 'id'), coalesce((select max(id) from public.notes), 0) + 1, false);
  perform setval(pg_get_serial_sequence('public.notifications', 'id'), coalesce((select max(id) from public.notifications), 0) + 1, false);
end;
$$;

grant select, insert, update, delete on table public.semesters to anon, authenticated;
grant select, insert, update, delete on table public.subjects to anon, authenticated;
grant select, insert, update, delete on table public.schedules to anon, authenticated;
grant select, insert, update, delete on table public.deadlines to anon, authenticated;
grant select, insert, update, delete on table public.study_plans to anon, authenticated;
grant select, insert, update, delete on table public.pomodoro_sessions to anon, authenticated;
grant select, insert, update, delete on table public.notes to anon, authenticated;
grant select, insert, update, delete on table public.notifications to anon, authenticated;
grant select, insert, update, delete on table public.user_settings to anon, authenticated;

grant usage on schema public to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;
grant execute on function public.reset_studyflow_sequences() to anon, authenticated;

alter table public.semesters disable row level security;
alter table public.subjects disable row level security;
alter table public.schedules disable row level security;
alter table public.deadlines disable row level security;
alter table public.study_plans disable row level security;
alter table public.pomodoro_sessions disable row level security;
alter table public.notes disable row level security;
alter table public.notifications disable row level security;
alter table public.user_settings disable row level security;

notify pgrst, 'reload schema';
