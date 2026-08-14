-- نظام الشريمي V2.6.1 — إصلاح مزامنة Realtime الآمنة
-- شغّل هذا الملف مرة واحدة في Supabase > SQL Editor.
-- لا يحذف alshuraimi_cloud_data ولا بيانات V2.5.2 القديمة.

create table if not exists public.alshuraimi_cloud_items (
  workspace_id text not null,
  storage_key text not null,
  value_text text null,
  is_deleted boolean not null default false,
  version bigint not null default 1,
  updated_at timestamptz not null default now(),
  updated_by text null,
  primary key (workspace_id, storage_key)
);

create index if not exists alshuraimi_cloud_items_updated_idx
  on public.alshuraimi_cloud_items (workspace_id, updated_at desc);

alter table public.alshuraimi_cloud_items enable row level security;
drop policy if exists "alshuraimi realtime select" on public.alshuraimi_cloud_items;
drop policy if exists "alshuraimi realtime insert" on public.alshuraimi_cloud_items;
drop policy if exists "alshuraimi realtime update" on public.alshuraimi_cloud_items;

create policy "alshuraimi realtime select" on public.alshuraimi_cloud_items
for select to anon using (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');

create policy "alshuraimi realtime insert" on public.alshuraimi_cloud_items
for insert to anon with check (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');

create policy "alshuraimi realtime update" on public.alshuraimi_cloud_items
for update to anon
using (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6')
with check (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');

grant usage on schema public to anon;
grant select,insert,update on public.alshuraimi_cloud_items to anon;

-- ترحيل نسخة V2.5.2 القديمة إن كانت موجودة. لا يحذف أو يعدل الجدول القديم.
do $$
begin
  if to_regclass('public.alshuraimi_cloud_data') is not null then
    insert into public.alshuraimi_cloud_items(workspace_id,storage_key,value_text,is_deleted,version,updated_at,updated_by)
    select d.workspace_id,e.key,e.value #>> '{}',false,greatest(1,d.version),d.updated_at,'migration-v252'
    from public.alshuraimi_cloud_data d
    cross join lateral jsonb_each(d.payload) e
    where d.workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6'
      and d.storage_key='full_state_v1'
    on conflict (workspace_id,storage_key) do nothing;
  end if;
end $$;

-- Realtime
do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.alshuraimi_cloud_items;
    exception when duplicate_object then null;
    end;
  end if;
end $$;

-- تحديث مخطط PostgREST فوراً بعد التغييرات.
notify pgrst, 'reload schema';
