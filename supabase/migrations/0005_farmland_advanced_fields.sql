alter table public.farmlands
    add column if not exists irrigation_type text,
    add column if not exists water_source text,
    add column if not exists terrain_type text,
    add column if not exists elevation numeric,
    add column if not exists farming_practice text,
    add column if not exists previous_crop text,
    add column if not exists soil_ph numeric,
    add column if not exists land_ownership text,
    add column if not exists nearest_market text,
    add column if not exists farm_age integer;

notify pgrst, 'reload schema';
