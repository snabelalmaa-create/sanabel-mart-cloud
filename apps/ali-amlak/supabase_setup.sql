-- نفّذ هذا الملف مرة واحدة من Supabase > SQL Editor
create table if not exists public.ali_amlak_store (
  id text primary key,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.ali_amlak_store enable row level security;

drop policy if exists "ali_amlak_read" on public.ali_amlak_store;
drop policy if exists "ali_amlak_insert" on public.ali_amlak_store;
drop policy if exists "ali_amlak_update" on public.ali_amlak_store;

create policy "ali_amlak_read"
on public.ali_amlak_store for select
to anon
using (id = 'main');

create policy "ali_amlak_insert"
on public.ali_amlak_store for insert
to anon
with check (id = 'main');

create policy "ali_amlak_update"
on public.ali_amlak_store for update
to anon
using (id = 'main')
with check (id = 'main');

insert into public.ali_amlak_store (id, payload)
values ('main', '{}'::jsonb)
on conflict (id) do nothing;
