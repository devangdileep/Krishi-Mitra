create extension if not exists "pgcrypto";
create extension if not exists "postgis";

alter table public.users
    add column if not exists preferred_language text not null default 'en-IN',
    add column if not exists preferences jsonb not null default '{}'::jsonb,
    add column if not exists last_sync_at timestamptz,
    add column if not exists device_sync_state jsonb not null default '{}'::jsonb;

alter table public.farmlands
    add column if not exists irrigation_type text,
    add column if not exists water_source text,
    add column if not exists soil_health jsonb not null default '{}'::jsonb,
    add column if not exists sync_version bigint not null default 1,
    add column if not exists client_updated_at timestamptz,
    add column if not exists deleted_at timestamptz,
    add column if not exists geom geometry(Polygon, 4326);

create index if not exists farmlands_geom_gix on public.farmlands using gist (geom);
create index if not exists farmlands_user_sync_idx on public.farmlands(user_id, sync_version, updated_at desc);
create index if not exists farmlands_deleted_idx on public.farmlands(deleted_at) where deleted_at is not null;

create table if not exists public.crops (
    id uuid primary key default gen_random_uuid(),
    farmland_id uuid not null references public.farmlands(id) on delete cascade,
    user_id bigint not null references public.users(id) on delete cascade,
    crop_type text not null,
    variety text,
    quantity text,
    growth_stage text,
    sowing_date date,
    expected_harvest_date date,
    actual_harvest_date date,
    health_metrics jsonb not null default '{}'::jsonb,
    fertilizer_schedule jsonb not null default '[]'::jsonb,
    irrigation_schedule jsonb not null default '[]'::jsonb,
    expense_summary jsonb not null default '{}'::jsonb,
    yield_prediction jsonb not null default '{}'::jsonb,
    sync_version bigint not null default 1,
    client_updated_at timestamptz,
    deleted_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists crops_farmland_idx on public.crops(farmland_id, deleted_at);
create index if not exists crops_user_stage_idx on public.crops(user_id, growth_stage);

create table if not exists public.ai_reports (
    id uuid primary key default gen_random_uuid(),
    user_id bigint not null references public.users(id) on delete cascade,
    farmland_id uuid references public.farmlands(id) on delete cascade,
    crop_id uuid references public.crops(id) on delete set null,
    cache_key text not null,
    prompt_hash text not null,
    model_version text not null,
    model_name text,
    report_type text not null default 'farm_report',
    input_snapshot jsonb not null default '{}'::jsonb,
    response_json jsonb not null,
    expires_at timestamptz not null,
    sync_version bigint not null default 1,
    created_at timestamptz not null default now()
);

create unique index if not exists ai_reports_cache_key_uidx on public.ai_reports(cache_key);
create index if not exists ai_reports_user_farmland_idx on public.ai_reports(user_id, farmland_id, expires_at desc);
create index if not exists ai_reports_expires_idx on public.ai_reports(expires_at);

create table if not exists public.weather_cache (
    id uuid primary key default gen_random_uuid(),
    region_key text not null,
    center geography(Point, 4326),
    forecast_json jsonb not null,
    source text not null default 'open-meteo',
    fetched_at timestamptz not null default now(),
    expires_at timestamptz not null
);

create unique index if not exists weather_cache_region_uidx on public.weather_cache(region_key);
create index if not exists weather_cache_center_gix on public.weather_cache using gist(center);
create index if not exists weather_cache_expires_idx on public.weather_cache(expires_at);

create table if not exists public.farm_tasks (
    id uuid primary key default gen_random_uuid(),
    user_id bigint not null references public.users(id) on delete cascade,
    farmland_id uuid references public.farmlands(id) on delete cascade,
    crop_id uuid references public.crops(id) on delete set null,
    task_type text not null,
    title text not null,
    description text,
    due_at timestamptz,
    priority text not null default 'normal',
    status text not null default 'pending',
    source text not null default 'manual',
    sync_version bigint not null default 1,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists farm_tasks_user_due_idx on public.farm_tasks(user_id, status, due_at);

create table if not exists public.notification_queue (
    id uuid primary key default gen_random_uuid(),
    user_id bigint not null references public.users(id) on delete cascade,
    task_id uuid references public.farm_tasks(id) on delete cascade,
    title text not null,
    body text not null,
    channel text not null default 'local',
    delivery_state text not null default 'queued',
    scheduled_at timestamptz,
    delivered_at timestamptz,
    created_at timestamptz not null default now()
);

create index if not exists notification_queue_delivery_idx on public.notification_queue(delivery_state, scheduled_at);

create table if not exists public.farm_images (
    id uuid primary key default gen_random_uuid(),
    user_id bigint not null references public.users(id) on delete cascade,
    farmland_id uuid references public.farmlands(id) on delete cascade,
    crop_id uuid references public.crops(id) on delete set null,
    storage_path text,
    thumbnail_path text,
    local_client_id text,
    mime_type text,
    byte_size integer,
    width integer,
    height integer,
    upload_state text not null default 'queued',
    ai_analysis jsonb not null default '{}'::jsonb,
    captured_at timestamptz,
    created_at timestamptz not null default now()
);

create index if not exists farm_images_user_state_idx on public.farm_images(user_id, upload_state, created_at desc);

create table if not exists public.market_prices (
    id uuid primary key default gen_random_uuid(),
    crop_type text not null,
    market_name text not null,
    state text,
    district text,
    price_min numeric,
    price_max numeric,
    price_modal numeric,
    unit text not null default 'quintal',
    observed_at timestamptz not null,
    source text not null default 'manual'
);

create index if not exists market_prices_crop_market_idx on public.market_prices(crop_type, state, district, observed_at desc);

create table if not exists public.marketplace_listings (
    id uuid primary key default gen_random_uuid(),
    user_id bigint not null references public.users(id) on delete cascade,
    listing_type text not null,
    title text not null,
    description text,
    crop_type text,
    quantity text,
    price numeric,
    location geography(Point, 4326),
    status text not null default 'active',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists marketplace_location_gix on public.marketplace_listings using gist(location);
create index if not exists marketplace_type_status_idx on public.marketplace_listings(listing_type, status, created_at desc);

create table if not exists public.sync_events (
    id uuid primary key default gen_random_uuid(),
    user_id bigint references public.users(id) on delete cascade,
    device_id text,
    entity_type text not null,
    entity_id text not null,
    operation text not null,
    status text not null,
    client_version bigint,
    server_version bigint,
    error_message text,
    created_at timestamptz not null default now()
);

create index if not exists sync_events_user_created_idx on public.sync_events(user_id, created_at desc);

alter table public.crops enable row level security;
alter table public.ai_reports enable row level security;
alter table public.weather_cache enable row level security;
alter table public.farm_tasks enable row level security;
alter table public.notification_queue enable row level security;
alter table public.farm_images enable row level security;
alter table public.market_prices enable row level security;
alter table public.marketplace_listings enable row level security;
alter table public.sync_events enable row level security;

grant select, insert, update, delete on table
    public.crops,
    public.ai_reports,
    public.weather_cache,
    public.farm_tasks,
    public.notification_queue,
    public.farm_images,
    public.market_prices,
    public.marketplace_listings,
    public.sync_events
to anon, authenticated;

drop policy if exists "Demo crops access" on public.crops;
create policy "Demo crops access" on public.crops for all to anon, authenticated using (true) with check (true);

drop policy if exists "Demo ai reports access" on public.ai_reports;
create policy "Demo ai reports access" on public.ai_reports for all to anon, authenticated using (true) with check (true);

drop policy if exists "Demo weather cache read" on public.weather_cache;
create policy "Demo weather cache read" on public.weather_cache for select to anon, authenticated using (true);

drop policy if exists "Demo farm tasks access" on public.farm_tasks;
create policy "Demo farm tasks access" on public.farm_tasks for all to anon, authenticated using (true) with check (true);

drop policy if exists "Demo notification access" on public.notification_queue;
create policy "Demo notification access" on public.notification_queue for all to anon, authenticated using (true) with check (true);

drop policy if exists "Demo farm image access" on public.farm_images;
create policy "Demo farm image access" on public.farm_images for all to anon, authenticated using (true) with check (true);

drop policy if exists "Demo market prices read" on public.market_prices;
create policy "Demo market prices read" on public.market_prices for select to anon, authenticated using (true);

drop policy if exists "Demo marketplace access" on public.marketplace_listings;
create policy "Demo marketplace access" on public.marketplace_listings for all to anon, authenticated using (true) with check (true);

drop policy if exists "Demo sync events access" on public.sync_events;
create policy "Demo sync events access" on public.sync_events for all to anon, authenticated using (true) with check (true);

create or replace function public.bump_sync_version()
returns trigger
language plpgsql
as $$
begin
    new.sync_version = coalesce(old.sync_version, 0) + 1;
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists crops_bump_sync_version on public.crops;
create trigger crops_bump_sync_version
before update on public.crops
for each row execute function public.bump_sync_version();

notify pgrst, 'reload schema';
