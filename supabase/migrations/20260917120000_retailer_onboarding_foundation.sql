-- AUPNIX Retailer Onboarding Foundation
-- Batch 1: persistent onboarding state, provider-neutral payment authorization,
-- and duplicate-safe retailer workspace discovery/creation.

create table public.retailer_onboarding_states (
  business_id uuid not null,
  state text not null default 'WORKSPACE_CREATED',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint retailer_onboarding_states_pkey
    primary key (business_id),

  constraint retailer_onboarding_states_business_id_fkey
    foreign key (business_id)
    references public.businesses(id)
    on delete cascade,

  constraint retailer_onboarding_states_state_check
    check (
      state = any (
        array[
          'WORKSPACE_CREATED'::text,
          'BUSINESS_INFORMATION_COMPLETED'::text,
          'STORE_SETUP_COMPLETED'::text,
          'PAYMENT_AUTHORIZATION_PENDING'::text,
          'PAYMENT_AUTHORIZATION_FAILED'::text,
          'COMPLETED'::text
        ]
      )
    )
);

alter table public.retailer_onboarding_states enable row level security;

create table public.business_payment_authorizations (
  business_id uuid not null,
  status text not null default 'pending',
  provider text,
  external_reference text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint business_payment_authorizations_pkey
    primary key (business_id),

  constraint business_payment_authorizations_business_id_fkey
    foreign key (business_id)
    references public.businesses(id)
    on delete cascade,

  constraint business_payment_authorizations_status_check
    check (
      status = any (
        array[
          'pending'::text,
          'active'::text,
          'failed'::text,
          'revoked'::text
        ]
      )
    )
);

alter table public.business_payment_authorizations enable row level security;

create index retailer_onboarding_states_state_idx
  on public.retailer_onboarding_states(state);

create index business_payment_authorizations_status_idx
  on public.business_payment_authorizations(status);

create trigger set_retailer_onboarding_states_updated_at
  before update on public.retailer_onboarding_states
  for each row
  execute function public.set_updated_at();

create trigger set_business_payment_authorizations_updated_at
  before update on public.business_payment_authorizations
  for each row
  execute function public.set_updated_at();

create policy retailer_onboarding_states_select_member
  on public.retailer_onboarding_states
  for select
  to authenticated
  using (public.has_active_business_membership(business_id));

create policy retailer_onboarding_states_insert_owner
  on public.retailer_onboarding_states
  for insert
  to authenticated
  with check (public.has_active_business_owner(business_id));

create policy retailer_onboarding_states_update_owner
  on public.retailer_onboarding_states
  for update
  to authenticated
  using (public.has_active_business_owner(business_id))
  with check (public.has_active_business_owner(business_id));

create policy retailer_onboarding_states_delete_owner
  on public.retailer_onboarding_states
  for delete
  to authenticated
  using (public.has_active_business_owner(business_id));

create policy business_payment_authorizations_select_owner
  on public.business_payment_authorizations
  for select
  to authenticated
  using (public.has_active_business_owner(business_id));

create policy business_payment_authorizations_insert_owner
  on public.business_payment_authorizations
  for insert
  to authenticated
  with check (public.has_active_business_owner(business_id));

create policy business_payment_authorizations_update_owner
  on public.business_payment_authorizations
  for update
  to authenticated
  using (public.has_active_business_owner(business_id))
  with check (public.has_active_business_owner(business_id));

create policy business_payment_authorizations_delete_owner
  on public.business_payment_authorizations
  for delete
  to authenticated
  using (public.has_active_business_owner(business_id));

grant select, insert, update, delete
on table public.retailer_onboarding_states
to authenticated;

grant select, insert, update, delete
on table public.business_payment_authorizations
to authenticated;

create or replace function public.get_or_create_retailer_workspace()
returns uuid
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  current_user_id uuid;
  existing_business_id uuid;
  new_business_id uuid;
  onboarding_role text;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'authenticated user required';
  end if;

  select role
    into onboarding_role
  from public.user_onboarding_roles
  where user_id = current_user_id;

  if onboarding_role is distinct from 'retailer' then
    raise exception 'retailer onboarding role required';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      'aupnix_retailer_workspace:' || current_user_id::text,
      0
    )
  );

  select bm.business_id
    into existing_business_id
  from public.business_memberships bm
  join public.businesses b
    on b.id = bm.business_id
  where bm.user_id = current_user_id
    and bm.role = 'owner'
    and bm.status = 'active'
  order by bm.business_id
  limit 1;

  if existing_business_id is not null then
    insert into public.retailer_onboarding_states (
      business_id,
      state
    )
    values (
      existing_business_id,
      'WORKSPACE_CREATED'
    )
    on conflict (business_id) do nothing;

    return existing_business_id;
  end if;

  new_business_id := public.create_business_with_initial_owner();

  insert into public.retailer_onboarding_states (
    business_id,
    state
  )
  values (
    new_business_id,
    'WORKSPACE_CREATED'
  );

  return new_business_id;
end;
$function$;

revoke all on function public.get_or_create_retailer_workspace()
from public;

grant execute on function public.get_or_create_retailer_workspace()
to authenticated;
