-- نظام الشريمي V2.6 — مزامنة Realtime على مستوى مفاتيح البيانات
-- شغّل الملف مرة واحدة في Supabase > SQL Editor قبل رفع V2.6.

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
create policy "alshuraimi realtime select" on public.alshuraimi_cloud_items for select to anon
  using (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');
create policy "alshuraimi realtime insert" on public.alshuraimi_cloud_items for insert to anon
  with check (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');
create policy "alshuraimi realtime update" on public.alshuraimi_cloud_items for update to anon
  using (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6')
  with check (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');
grant select,insert,update on public.alshuraimi_cloud_items to anon;

-- كتابة ذرية: كل تعديل يرفع إصدار المفتاح تلقائياً.
create or replace function public.alshuraimi_put_item(
  p_workspace_id text,
  p_storage_key text,
  p_value_text text,
  p_is_deleted boolean,
  p_updated_by text
) returns public.alshuraimi_cloud_items
language plpgsql
security definer
set search_path=public
as $$
declare r public.alshuraimi_cloud_items;
begin
  if p_workspace_id <> '8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6' then
    raise exception 'invalid workspace';
  end if;
  insert into public.alshuraimi_cloud_items(workspace_id,storage_key,value_text,is_deleted,version,updated_at,updated_by)
  values(p_workspace_id,p_storage_key,p_value_text,coalesce(p_is_deleted,false),1,now(),p_updated_by)
  on conflict (workspace_id,storage_key) do update set
    value_text=excluded.value_text,
    is_deleted=excluded.is_deleted,
    version=public.alshuraimi_cloud_items.version+1,
    updated_at=now(),
    updated_by=excluded.updated_by
  returning * into r;
  return r;
end;
$$;
grant execute on function public.alshuraimi_put_item(text,text,text,boolean,text) to anon;

-- ترحيل تلقائي من V2.5.2 إذا كان جدول الحالة القديمة موجوداً.
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

-- إضافة الجدول إلى Supabase Realtime (آمن عند إعادة تشغيل الملف).
do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.alshuraimi_cloud_items;
    exception when duplicate_object then null;
    end;
  end if;
end $$;
