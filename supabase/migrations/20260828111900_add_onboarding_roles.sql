create table public.user_onboarding_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('customer', 'retailer')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_onboarding_roles enable row level security;

create policy "user_onboarding_roles_select_own"
on public.user_onboarding_roles for select to authenticated
using (user_id = auth.uid());

create policy "user_onboarding_roles_insert_own"
on public.user_onboarding_roles for insert to authenticated
with check (user_id = auth.uid());

create policy "user_onboarding_roles_update_own"
on public.user_onboarding_roles for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "user_onboarding_roles_delete_own"
on public.user_onboarding_roles for delete to authenticated
using (user_id = auth.uid());
