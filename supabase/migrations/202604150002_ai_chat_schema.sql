create extension if not exists pgcrypto with schema extensions;

create table if not exists public.ai_chat_threads (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Cuộc trò chuyện mới',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  last_message_preview text
);

create table if not exists public.ai_chat_messages (
  id uuid primary key default extensions.gen_random_uuid(),
  thread_id uuid not null references public.ai_chat_threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default timezone('utc', now()),
  metadata_json jsonb
);

create index if not exists ai_chat_threads_user_id_updated_idx
  on public.ai_chat_threads(user_id, updated_at desc);

create index if not exists ai_chat_messages_thread_created_idx
  on public.ai_chat_messages(thread_id, created_at);

create index if not exists ai_chat_messages_user_id_idx
  on public.ai_chat_messages(user_id);

grant select, insert, update, delete on table public.ai_chat_threads to authenticated;
grant select, insert, update, delete on table public.ai_chat_messages to authenticated;

alter table public.ai_chat_threads enable row level security;
alter table public.ai_chat_messages enable row level security;

drop policy if exists "ai_chat_threads_select_own" on public.ai_chat_threads;
create policy "ai_chat_threads_select_own"
on public.ai_chat_threads
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "ai_chat_threads_insert_own" on public.ai_chat_threads;
create policy "ai_chat_threads_insert_own"
on public.ai_chat_threads
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "ai_chat_threads_update_own" on public.ai_chat_threads;
create policy "ai_chat_threads_update_own"
on public.ai_chat_threads
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "ai_chat_threads_delete_own" on public.ai_chat_threads;
create policy "ai_chat_threads_delete_own"
on public.ai_chat_threads
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "ai_chat_messages_select_own" on public.ai_chat_messages;
create policy "ai_chat_messages_select_own"
on public.ai_chat_messages
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "ai_chat_messages_insert_own" on public.ai_chat_messages;
create policy "ai_chat_messages_insert_own"
on public.ai_chat_messages
for insert
to authenticated
with check (
  auth.uid() = user_id and
  exists (
    select 1
    from public.ai_chat_threads threads
    where threads.id = thread_id
      and threads.user_id = auth.uid()
  )
);

drop policy if exists "ai_chat_messages_update_own" on public.ai_chat_messages;
create policy "ai_chat_messages_update_own"
on public.ai_chat_messages
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "ai_chat_messages_delete_own" on public.ai_chat_messages;
create policy "ai_chat_messages_delete_own"
on public.ai_chat_messages
for delete
to authenticated
using (auth.uid() = user_id);

create or replace function public.set_ai_chat_thread_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.sync_ai_chat_thread_after_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.ai_chat_threads
  set
    updated_at = timezone('utc', now()),
    last_message_preview = left(new.content, 160),
    title = case
      when (trim(coalesce(title, '')) = '' or title = 'Cuộc trò chuyện mới')
           and new.role = 'user'
        then left(regexp_replace(trim(new.content), '\s+', ' ', 'g'), 80)
      else title
    end
  where id = new.thread_id
    and user_id = new.user_id;

  return new;
end;
$$;

drop trigger if exists ai_chat_threads_set_updated_at on public.ai_chat_threads;
create trigger ai_chat_threads_set_updated_at
before update on public.ai_chat_threads
for each row
execute function public.set_ai_chat_thread_updated_at();

drop trigger if exists ai_chat_messages_sync_thread on public.ai_chat_messages;
create trigger ai_chat_messages_sync_thread
after insert or update on public.ai_chat_messages
for each row
execute function public.sync_ai_chat_thread_after_message();

notify pgrst, 'reload schema';
