-- ============================================================
--  NeedLink — Initial Schema
--  Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================


-- ── Enums ───────────────────────────────────────────────────

create type public.user_role       as enum ('donor', 'ngo_admin');
create type public.item_category   as enum ('food', 'clothing', 'medicine', 'supplies');
create type public.urgency_level   as enum ('normal', 'urgent');
create type public.need_status     as enum ('open', 'matched', 'closed');
create type public.pledge_status   as enum ('pending', 'confirmed', 'rejected');


-- ── Helper: auto-update updated_at ──────────────────────────

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


-- ── profiles ────────────────────────────────────────────────
-- Mirrors auth.users; created automatically on sign-up via trigger.

create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text        not null,
  role        public.user_role not null default 'donor',
  phone       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create a minimal profile row whenever a user signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'donor')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ── ngos ────────────────────────────────────────────────────

create table public.ngos (
  id                  uuid primary key default gen_random_uuid(),
  admin_id            uuid        not null references public.profiles(id) on delete cascade,
  name                text        not null,
  location            text        not null,
  registration_number text,
  contact_email       text        not null,
  verified            boolean     not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  unique (admin_id)  -- one NGO per admin
);

create index ngos_admin_id_idx on public.ngos(admin_id);

create trigger ngos_updated_at
  before update on public.ngos
  for each row execute function public.set_updated_at();


-- ── donation_needs ───────────────────────────────────────────

create table public.donation_needs (
  id               uuid primary key default gen_random_uuid(),
  ngo_id           uuid                   not null references public.ngos(id) on delete cascade,
  item_name        text                   not null,
  category         public.item_category   not null,
  quantity_needed  integer                not null check (quantity_needed > 0),
  quantity_pledged integer                not null default 0 check (quantity_pledged >= 0),
  urgency          public.urgency_level   not null default 'normal',
  status           public.need_status     not null default 'open',
  deadline         date                   not null,
  description      text,
  created_at       timestamptz            not null default now(),
  updated_at       timestamptz            not null default now()
);

create index donation_needs_ngo_id_idx    on public.donation_needs(ngo_id);
create index donation_needs_status_idx    on public.donation_needs(status);
create index donation_needs_category_idx  on public.donation_needs(category);
create index donation_needs_deadline_idx  on public.donation_needs(deadline);

create trigger donation_needs_updated_at
  before update on public.donation_needs
  for each row execute function public.set_updated_at();


-- ── pledges ──────────────────────────────────────────────────

create table public.pledges (
  id            uuid primary key default gen_random_uuid(),
  need_id       uuid                 not null references public.donation_needs(id) on delete cascade,
  donor_id      uuid                 not null references public.profiles(id) on delete cascade,
  quantity      integer              not null check (quantity > 0),
  delivery_date date                 not null,
  notes         text,
  status        public.pledge_status not null default 'pending',
  created_at    timestamptz          not null default now(),
  updated_at    timestamptz          not null default now()
);

create index pledges_need_id_idx   on public.pledges(need_id);
create index pledges_donor_id_idx  on public.pledges(donor_id);
create index pledges_status_idx    on public.pledges(status);

create trigger pledges_updated_at
  before update on public.pledges
  for each row execute function public.set_updated_at();


-- ── deliveries ───────────────────────────────────────────────

create table public.deliveries (
  id           uuid primary key default gen_random_uuid(),
  pledge_id    uuid        not null references public.pledges(id) on delete cascade,
  confirmed_by uuid        not null references public.profiles(id),
  notes        text,
  confirmed_at timestamptz not null default now(),

  unique (pledge_id)  -- one delivery record per pledge
);

create index deliveries_pledge_id_idx on public.deliveries(pledge_id);


-- ============================================================
--  Row-Level Security
-- ============================================================

alter table public.profiles       enable row level security;
alter table public.ngos           enable row level security;
alter table public.donation_needs enable row level security;
alter table public.pledges        enable row level security;
alter table public.deliveries     enable row level security;


-- ── profiles RLS ────────────────────────────────────────────

-- Anyone authenticated can read any profile (donors need to see their own, NGOs need donor info)
create policy "profiles: authenticated read"
  on public.profiles for select
  to authenticated
  using (true);

-- Users can only update their own profile
create policy "profiles: own update"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);


-- ── ngos RLS ────────────────────────────────────────────────

-- Public read (donors browse NGOs on landing page without logging in)
create policy "ngos: public read"
  on public.ngos for select
  using (true);

-- Only the NGO admin can insert their own NGO
create policy "ngos: own insert"
  on public.ngos for insert
  to authenticated
  with check (auth.uid() = admin_id);

-- Only the NGO admin can update their own NGO
create policy "ngos: own update"
  on public.ngos for update
  to authenticated
  using (auth.uid() = admin_id)
  with check (auth.uid() = admin_id);


-- ── donation_needs RLS ───────────────────────────────────────

-- Public read (donors browse needs on landing page and donor home)
create policy "donation_needs: public read"
  on public.donation_needs for select
  using (true);

-- NGO admin can create needs only for their own NGO
create policy "donation_needs: ngo insert"
  on public.donation_needs for insert
  to authenticated
  with check (
    exists (
      select 1 from public.ngos
      where id = ngo_id and admin_id = auth.uid()
    )
  );

-- NGO admin can update/close their own needs
create policy "donation_needs: ngo update"
  on public.donation_needs for update
  to authenticated
  using (
    exists (
      select 1 from public.ngos
      where id = ngo_id and admin_id = auth.uid()
    )
  );

-- NGO admin can delete their own needs
create policy "donation_needs: ngo delete"
  on public.donation_needs for delete
  to authenticated
  using (
    exists (
      select 1 from public.ngos
      where id = ngo_id and admin_id = auth.uid()
    )
  );


-- ── pledges RLS ──────────────────────────────────────────────

-- Donors can read their own pledges
create policy "pledges: donor read own"
  on public.pledges for select
  to authenticated
  using (donor_id = auth.uid());

-- NGO admins can read pledges for their needs
create policy "pledges: ngo read own needs"
  on public.pledges for select
  to authenticated
  using (
    exists (
      select 1 from public.donation_needs dn
      join public.ngos n on n.id = dn.ngo_id
      where dn.id = need_id and n.admin_id = auth.uid()
    )
  );

-- Donors can create pledges (only for open needs)
create policy "pledges: donor insert"
  on public.pledges for insert
  to authenticated
  with check (
    donor_id = auth.uid()
    and exists (
      select 1 from public.donation_needs
      where id = need_id and status = 'open'
    )
  );

-- NGO admins can update pledge status (confirm / reject)
create policy "pledges: ngo update status"
  on public.pledges for update
  to authenticated
  using (
    exists (
      select 1 from public.donation_needs dn
      join public.ngos n on n.id = dn.ngo_id
      where dn.id = need_id and n.admin_id = auth.uid()
    )
  );


-- ── deliveries RLS ───────────────────────────────────────────

-- Authenticated users can read deliveries
create policy "deliveries: authenticated read"
  on public.deliveries for select
  to authenticated
  using (true);

-- NGO admins can insert delivery records
create policy "deliveries: ngo insert"
  on public.deliveries for insert
  to authenticated
  with check (confirmed_by = auth.uid());
