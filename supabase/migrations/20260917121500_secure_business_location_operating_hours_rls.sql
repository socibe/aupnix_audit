-- AUPNIX Retailer Onboarding Foundation
-- Corrective RLS for business-scoped operating hours.

drop policy if exists "Authenticated users can delete business location operating hour"
  on public.business_location_operating_hours;

drop policy if exists "Authenticated users can insert business location operating hour"
  on public.business_location_operating_hours;

drop policy if exists "Authenticated users can read business location operating hours"
  on public.business_location_operating_hours;

drop policy if exists "Authenticated users can update business location operating hour"
  on public.business_location_operating_hours;

create policy business_location_operating_hours_select_member
  on public.business_location_operating_hours
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.business_locations
      where business_locations.id =
        business_location_operating_hours.business_location_id
        and public.has_active_business_membership(
          business_locations.business_id
        )
    )
  );

create policy business_location_operating_hours_insert_owner
  on public.business_location_operating_hours
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.business_locations
      where business_locations.id =
        business_location_operating_hours.business_location_id
        and public.has_active_business_owner(
          business_locations.business_id
        )
    )
  );

create policy business_location_operating_hours_update_owner
  on public.business_location_operating_hours
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.business_locations
      where business_locations.id =
        business_location_operating_hours.business_location_id
        and public.has_active_business_owner(
          business_locations.business_id
        )
    )
  )
  with check (
    exists (
      select 1
      from public.business_locations
      where business_locations.id =
        business_location_operating_hours.business_location_id
        and public.has_active_business_owner(
          business_locations.business_id
        )
    )
  );

create policy business_location_operating_hours_delete_owner
  on public.business_location_operating_hours
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.business_locations
      where business_locations.id =
        business_location_operating_hours.business_location_id
        and public.has_active_business_owner(
          business_locations.business_id
        )
    )
  );

revoke all on table public.business_location_operating_hours
from anon;

grant select, insert, update, delete
on table public.business_location_operating_hours
to authenticated;