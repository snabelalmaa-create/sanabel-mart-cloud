-- نظام الشريمي V2.6.2 — تثبيت المزامنة على الجدول الأساسي الموجود
-- شغّل مرة واحدة في Supabase > SQL Editor.
-- لا يحذف أي بيانات موجودة.

create table if not exists public.alshuraimi_cloud_data (
  workspace_id text not null,
  storage_key text not null,
  payload jsonb not null default '{}'::jsonb,
  version bigint not null default 1,
  updated_by uuid null,
  updated_at timestamptz not null default now(),
  primary key (workspace_id, storage_key)
);

alter table public.alshuraimi_cloud_data enable row level security;

drop policy if exists "alshuraimi cloud select" on public.alshuraimi_cloud_data;
drop policy if exists "alshuraimi cloud insert" on public.alshuraimi_cloud_data;
drop policy if exists "alshuraimi cloud update" on public.alshuraimi_cloud_data;

create policy "alshuraimi cloud select" on public.alshuraimi_cloud_data
for select to anon
using (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');

create policy "alshuraimi cloud insert" on public.alshuraimi_cloud_data
for insert to anon
with check (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');

create policy "alshuraimi cloud update" on public.alshuraimi_cloud_data
for update to anon
using (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6')
with check (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');

grant usage on schema public to anon;
grant select,insert,update on public.alshuraimi_cloud_data to anon;

-- تشغيل Realtime على نفس الجدول الموجود. إذا كان مفعلاً مسبقاً فلن يسبب خطأ.
do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.alshuraimi_cloud_data;
    exception when duplicate_object then null;
    end;
  end if;
end $$;

notify pgrst, 'reload schema';
