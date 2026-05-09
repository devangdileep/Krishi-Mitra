alter table public.farmlands
    add column if not exists boundary_points jsonb not null default '[]'::jsonb,
    add column if not exists heat_index double precision not null default 0;

update public.farmlands
set
    boundary_points = coalesce(boundary_points, '[]'::jsonb),
    heat_index = coalesce(heat_index, 0);

notify pgrst, 'reload schema';
