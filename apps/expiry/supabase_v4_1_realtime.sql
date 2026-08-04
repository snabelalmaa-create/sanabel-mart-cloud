-- مستودع الإكسباير V4 Cloud — شغّله مرة واحدة في Supabase SQL Editor
-- جداول مستقلة وسريعة مع RLS للمفتاح العام

create table if not exists public.expiry_products (
 id text primary key,
 smart_code text,
 barcode text,
 name text not null default '',
 cost numeric not null default 0,
 category text,
 payload jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now(),
 updated_by text
);
create index if not exists expiry_products_barcode_idx on public.expiry_products(barcode);
create index if not exists expiry_products_smart_code_idx on public.expiry_products(smart_code);
create index if not exists expiry_products_name_idx on public.expiry_products using gin (to_tsvector('simple', name));

create table if not exists public.expiry_expired (
 id text primary key,
 product_id text not null,
 qty numeric not null default 0,
 remaining numeric not null default 0,
 cost numeric not null default 0,
 expiry_date date,
 created_at timestamptz not null default now(),
 payload jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now(),
 updated_by text
);
create index if not exists expiry_expired_product_idx on public.expiry_expired(product_id);

create table if not exists public.expiry_replacements (
 id text primary key,
 product_id text not null,
 qty numeric not null default 0,
 created_at timestamptz not null default now(),
 payload jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now(),
 updated_by text
);
create index if not exists expiry_replacements_product_idx on public.expiry_replacements(product_id);

create table if not exists public.expiry_purchase_receipts (
 id text primary key,
 number text,
 supplier text not null default 'مورد عام',
 purchase_date date,
 created_at timestamptz not null default now(),
 payload jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now(),
 updated_by text
);

create table if not exists public.expiry_purchase_items (
 id text primary key,
 purchase_id text not null,
 product_id text not null,
 qty numeric not null default 0,
 cost numeric not null default 0,
 payload jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now(),
 updated_by text
);
create index if not exists expiry_purchase_items_purchase_idx on public.expiry_purchase_items(purchase_id);
create index if not exists expiry_purchase_items_product_idx on public.expiry_purchase_items(product_id);

create table if not exists public.expiry_users (
 id text primary key,
 name text not null,
 pin text not null,
 role text not null default 'عامل',
 active boolean not null default true,
 payload jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now(),
 updated_by text
);

create table if not exists public.expiry_audit_log (
 id text primary key,
 action text not null default '',
 detail text,
 user_name text,
 created_at timestamptz not null default now(),
 payload jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now(),
 updated_by text
);

create table if not exists public.expiry_settings (
 id text primary key,
 payload jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now(),
 updated_by text
);

-- RLS وسياسات الوصول للتطبيق
DO $$
DECLARE t text;
BEGIN
 FOREACH t IN ARRAY ARRAY['expiry_products','expiry_expired','expiry_replacements','expiry_purchase_receipts','expiry_purchase_items','expiry_users','expiry_audit_log','expiry_settings']
 LOOP
  EXECUTE format('alter table public.%I enable row level security', t);
  EXECUTE format('drop policy if exists %I on public.%I', t||'_select', t);
  EXECUTE format('drop policy if exists %I on public.%I', t||'_insert', t);
  EXECUTE format('drop policy if exists %I on public.%I', t||'_update', t);
  EXECUTE format('drop policy if exists %I on public.%I', t||'_delete', t);
  EXECUTE format('create policy %I on public.%I for select to anon, authenticated using (true)', t||'_select', t);
  EXECUTE format('create policy %I on public.%I for insert to anon, authenticated with check (true)', t||'_insert', t);
  EXECUTE format('create policy %I on public.%I for update to anon, authenticated using (true) with check (true)', t||'_update', t);
  EXECUTE format('create policy %I on public.%I for delete to anon, authenticated using (true)', t||'_delete', t);
  EXECUTE format('grant select, insert, update, delete on public.%I to anon, authenticated', t);
 END LOOP;
END $$;

insert into public.expiry_settings(id,payload,updated_by)
values ('main','{"business":"أسواق سنابل المع المركزية","defaultSupplier":"مورد عام","defaultUnitCode":"u01","smartTax":"15%"}'::jsonb,'تهيئة')
on conflict (id) do nothing;

insert into public.expiry_users(id,name,pin,role,active,payload,updated_by)
values ('u1','أبوقصي','2580','مدير',true,'{"id":"u1","name":"أبوقصي","pin":"2580","role":"مدير","active":true}'::jsonb,'تهيئة')
on conflict (id) do nothing;


-- تفعيل Realtime للجداول المستخدمة في التطبيق
DO $$
DECLARE t text;
BEGIN
 FOREACH t IN ARRAY ARRAY[
  'expiry_products','expiry_expired','expiry_replacements',
  'expiry_purchase_receipts','expiry_purchase_items',
  'expiry_users','expiry_audit_log','expiry_settings'
 ]
 LOOP
  IF NOT EXISTS (
   SELECT 1 FROM pg_publication_tables
   WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename=t
  ) THEN
   EXECUTE format('alter publication supabase_realtime add table public.%I', t);
  END IF;
 END LOOP;
END $$;
