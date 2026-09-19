set local check_function_bodies = off;

create table "public"."business_location_operating_hours" (
  "id"                   uuid                     not null default gen_random_uuid(),
  "business_location_id" uuid                     not null,
  "day_of_week"          integer                  not null,
  "is_closed"            boolean                  not null default false,
  "opening_time"         time without time zone,
  "closing_time"         time without time zone,
  "created_at"           timestamp with time zone not null default now(),
  "updated_at"           timestamp with time zone not null default now(),
  constraint "business_location_operating_hours_day_of_week_check" check (((day_of_week >= 1) AND (day_of_week <= 7))),
  constraint "business_location_operating_hours_location_day_unique" unique (business_location_id, day_of_week),
  constraint "business_location_operating_hours_pkey" primary key (id)
);

alter table "public"."business_location_operating_hours"
  enable row level security;

alter table "public"."business_images"
  add column "image_role" text not null;

create or replace function public.set_updated_at()
  returns trigger
  language plpgsql
  AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

alter table "public"."business_images"
  add constraint "business_images_image_role_check" check ((image_role = ANY (ARRAY['profile'::text, 'banner'::text])));

alter table "public"."business_location_operating_hours"
  add constraint "business_location_operating_hours_business_location_id_fkey" foreign key (business_location_id) references public.business_locations(id) on delete cascade;

create unique index business_images_business_id_image_role_key on public.business_images using btree (business_id, image_role);

create index idx_business_location_operating_hours_location on public.business_location_operating_hours using btree (business_location_id);

create policy "Authenticated users can delete business location operating hour" on "public"."business_location_operating_hours"
  for delete
  to "authenticated"
  using (true);

create policy "Authenticated users can insert business location operating hour" on "public"."business_location_operating_hours"
  for insert
  to "authenticated"
  with check (true);

create policy "Authenticated users can read business location operating hours" on "public"."business_location_operating_hours"
  for select
  to "authenticated"
  using (true);

create policy "Authenticated users can update business location operating hour" on "public"."business_location_operating_hours"
  for update
  to "authenticated"
  using (true)
  with check (true);

grant maintain, references, trigger, truncate on table "public"."business_location_operating_hours" to "anon";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."business_location_operating_hours" to "authenticated", "postgres";

grant maintain, references, trigger, truncate on table "public"."business_location_operating_hours" to "service_role";

