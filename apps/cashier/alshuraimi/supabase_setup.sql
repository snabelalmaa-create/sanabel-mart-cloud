-- نظام الشريمي V1.0.27 - جدول المزامنة السحابية الكامل
create extension if not exists pgcrypto;
create table if not exists public.shuraimi_app_state (
  workspace_id text primary key,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  device_id text,
  workspace_secret_hash text not null default encode(digest('55f12e62b20939d2559e79f747d097d413f1cb69991180bc','sha256'),'hex')
);
alter table public.shuraimi_app_state enable row level security;
drop policy if exists "shuraimi state select" on public.shuraimi_app_state;
drop policy if exists "shuraimi state insert" on public.shuraimi_app_state;
drop policy if exists "shuraimi state update" on public.shuraimi_app_state;
create policy "shuraimi state select" on public.shuraimi_app_state for select to anon using (workspace_secret_hash = encode(digest(coalesce((current_setting('request.headers',true)::json->>'x-workspace-key'),''),'sha256'),'hex'));
create policy "shuraimi state insert" on public.shuraimi_app_state for insert to anon with check (workspace_secret_hash = encode(digest(coalesce((current_setting('request.headers',true)::json->>'x-workspace-key'),''),'sha256'),'hex'));
create policy "shuraimi state update" on public.shuraimi_app_state for update to anon using (workspace_secret_hash = encode(digest(coalesce((current_setting('request.headers',true)::json->>'x-workspace-key'),''),'sha256'),'hex')) with check (workspace_secret_hash = encode(digest(coalesce((current_setting('request.headers',true)::json->>'x-workspace-key'),''),'sha256'),'hex'));
grant select,insert,update on public.shuraimi_app_state to anon;
