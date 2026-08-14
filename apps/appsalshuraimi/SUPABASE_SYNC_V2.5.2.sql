-- تهيئة مزامنة نظام الشريمي V2.5.2 على جدول alshuraimi_cloud_data
-- شغّل هذا الملف فقط إذا ظهرت رسالة صلاحيات/RLS في شريط المزامنة داخل التطبيق.
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
-- هذا المشروع مخصص لتطبيقات سنابل. مفتاح publishable ظاهر في الواجهة، لذا الحماية الأساسية هنا بنطاق workspace_id.
create policy "alshuraimi cloud select" on public.alshuraimi_cloud_data for select to anon using (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');
create policy "alshuraimi cloud insert" on public.alshuraimi_cloud_data for insert to anon with check (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');
create policy "alshuraimi cloud update" on public.alshuraimi_cloud_data for update to anon using (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6') with check (workspace_id='8b9ab303-9874-4ae7-8ffe-b4f83f7b5cd6');
grant select,insert,update on public.alshuraimi_cloud_data to anon;
