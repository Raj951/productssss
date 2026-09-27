-- MakerMatch · Phase 1 · Core schema
--
-- The 13 tables from the spec's data model, plus three small supporting tables
-- the spec implies elsewhere:
--   * indian_states  - "Indian states and cities built into the data model"
--   * match_weights  - "Weights live in a config table"
--   * reports        - admin "moderate reports" (spam / no-shows)
--
-- Conventions
--   * All money is stored in paise as bigint, in columns ending in _paise.
--   * Quantities (MOQ, capacity, target_qty) are in units/packs.
--   * public.users mirrors auth.users (one row per login); see the auth migration.
--   * Row-level security and grants live in the access-control migration.

create schema if not exists private;
comment on schema private is 'Internal helpers (RLS checks, triggers). Not exposed through the Data API.';

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

create type public.user_role as enum ('founder', 'manufacturer', 'admin');
create type public.founder_stage as enum ('idea', 'launched');
create type public.manufacturer_status as enum ('pending', 'verified', 'rejected', 'paused');
create type public.member_role as enum ('owner', 'sales', 'rnd');
create type public.sample_policy as enum ('free', 'paid', 'paid_adjusted_on_order', 'not_offered');
create type public.brief_status as enum ('draft', 'open', 'closed');
create type public.brief_timeline as enum ('within_1_month', '1_to_3_months', '3_to_6_months', 'over_6_months');
create type public.outreach_status as enum ('sent', 'nda_signed', 'accepted', 'declined', 'quoted', 'sampling', 'ordered');
create type public.sample_status as enum ('requested', 'sent', 'received', 'approved', 'rejected');
create type public.report_reason as enum ('spam', 'no_show', 'misleading_profile', 'abusive', 'other');
create type public.report_status as enum ('open', 'resolved', 'dismissed');

-- ---------------------------------------------------------------------------
-- Shared functions
-- ---------------------------------------------------------------------------

-- GSTIN: 2-digit state code + PAN + entity number + 'Z' + mod-36 check character.
create or replace function public.is_valid_gstin(p_gstin text)
returns boolean
language plpgsql
immutable
strict
set search_path = ''
as $$
declare
  chars constant text := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  total int := 0;
  v int;
begin
  if p_gstin !~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$' then
    return false;
  end if;
  for i in 1..14 loop
    v := (strpos(chars, substr(p_gstin, i, 1)) - 1) * (case when i % 2 = 1 then 1 else 2 end);
    total := total + v / 36 + v % 36;
  end loop;
  return substr(chars, ((36 - total % 36) % 36) + 1, 1) = substr(p_gstin, 15, 1);
end;
$$;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Reference data
-- ---------------------------------------------------------------------------

create table public.indian_states (
  code text primary key check (code ~ '^[A-Z]{2}$'),
  gst_code text not null unique check (gst_code ~ '^[0-9]{2}$'),
  name text not null unique,
  is_union_territory boolean not null default false
);
comment on table public.indian_states is 'States and union territories with their GST state codes (first two digits of a GSTIN).';

create table public.categories (
  id bigint generated always as identity primary key,
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name text not null,
  name_hi text,
  parent_id bigint references public.categories (id) on delete restrict,
  sort_order smallint not null default 0,
  created_at timestamptz not null default now()
);
comment on table public.categories is 'Two-level product taxonomy, e.g. Beverages › Carbonated soft drinks.';
create index categories_parent_id_idx on public.categories (parent_id);

create table public.certifications (
  id bigint generated always as identity primary key,
  code text not null unique check (code ~ '^[a-z0-9-]+$'),
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------------

create table public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  phone text unique check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  email text check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  name text check (char_length(name) <= 120),
  role public.user_role,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on column public.users.role is 'Null until the person picks founder or manufacturer. Admin is set only by SQL.';
comment on column public.users.email is 'Work email (founders). Verification comes in a later phase.';

create table public.founder_profiles (
  user_id uuid primary key references public.users (id) on delete cascade,
  company_name text not null check (char_length(company_name) between 2 and 200),
  city text not null check (char_length(city) between 2 and 100),
  state text not null references public.indian_states (code),
  gstin text check (public.is_valid_gstin(gstin)),
  stage public.founder_stage not null default 'idea',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Manufacturers
-- ---------------------------------------------------------------------------

create table public.manufacturers (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null check (char_length(legal_name) between 2 and 200),
  gstin text not null unique check (public.is_valid_gstin(gstin)),
  about text check (char_length(about) <= 2000),
  city text not null check (char_length(city) between 2 and 100),
  state text not null references public.indian_states (code),
  pincode text not null check (pincode ~ '^[1-9][0-9]{5}$'),
  min_order_qty integer not null check (min_order_qty > 0),
  monthly_capacity integer not null check (monthly_capacity > 0),
  offers_formulation boolean not null default false,
  sample_policy public.sample_policy not null default 'paid',
  photo_paths text[] not null default '{}',
  status public.manufacturer_status not null default 'pending',
  rejection_reason text check (char_length(rejection_reason) <= 1000),
  verified_at timestamptz,
  verified_by uuid references public.users (id) on delete set null,
  response_rate numeric(5, 2) check (response_rate between 0 and 100),
  median_reply_hours numeric(6, 1) check (median_reply_hours >= 0),
  created_by uuid default auth.uid() references public.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on column public.manufacturers.photo_paths is 'Object paths in the manufacturer-photos storage bucket.';
comment on column public.manufacturers.response_rate is 'Percent of briefs answered within 48h over the last 90 days. System-maintained.';
create index manufacturers_status_idx on public.manufacturers (status);
create index manufacturers_state_idx on public.manufacturers (state);

create table public.manufacturer_members (
  manufacturer_id uuid not null references public.manufacturers (id) on delete cascade,
  user_id uuid not null unique references public.users (id) on delete cascade,
  role public.member_role not null default 'sales',
  created_at timestamptz not null default now(),
  primary key (manufacturer_id, user_id)
);
comment on table public.manufacturer_members is 'Team members sharing one company profile. A person belongs to at most one manufacturer.';

create table public.manufacturer_capabilities (
  manufacturer_id uuid not null references public.manufacturers (id) on delete cascade,
  category_id bigint not null references public.categories (id) on delete restrict,
  formats text[] not null default '{}',
  packaging_types text[] not null default '{}',
  primary key (manufacturer_id, category_id)
);
create index manufacturer_capabilities_category_id_idx on public.manufacturer_capabilities (category_id);

create table public.manufacturer_certifications (
  manufacturer_id uuid not null references public.manufacturers (id) on delete cascade,
  certification_id bigint not null references public.certifications (id) on delete restrict,
  licence_no text check (char_length(licence_no) <= 100),
  document_path text,
  expires_on date,
  created_at timestamptz not null default now(),
  primary key (manufacturer_id, certification_id)
);
comment on column public.manufacturer_certifications.document_path is 'Object path in the private manufacturer-docs bucket (served via signed URLs).';
create index manufacturer_certifications_certification_id_idx on public.manufacturer_certifications (certification_id);

-- ---------------------------------------------------------------------------
-- Briefs and everything that hangs off an outreach
-- ---------------------------------------------------------------------------

create table public.briefs (
  id uuid primary key default gen_random_uuid(),
  founder_id uuid not null default auth.uid() references public.users (id) on delete cascade,
  title text check (char_length(title) <= 150),
  category_id bigint references public.categories (id) on delete restrict,
  product_type text check (char_length(product_type) <= 150),
  specs jsonb not null default '{}'::jsonb check (jsonb_typeof(specs) = 'object'),
  target_qty integer check (target_qty > 0),
  budget_min_paise bigint check (budget_min_paise >= 0),
  budget_max_paise bigint check (budget_max_paise >= 0),
  timeline public.brief_timeline,
  needs_formulation boolean not null default false,
  required_cert_ids bigint[] not null default '{}',
  status public.brief_status not null default 'draft',
  attachments text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint briefs_budget_range check (
    budget_min_paise is null or budget_max_paise is null or budget_min_paise <= budget_max_paise
  ),
  constraint briefs_complete_unless_draft check (
    status = 'draft'
    or (title is not null and category_id is not null and product_type is not null
        and target_qty is not null and timeline is not null)
  )
);
comment on column public.briefs.specs is 'Structured specs: format, packaging, process, flavour, shelf life, etc.';
comment on column public.briefs.attachments is 'Object paths in the private brief-attachments bucket, under <brief_id>/.';
comment on column public.briefs.budget_min_paise is 'Budget range for the first production run, in paise.';
create index briefs_founder_id_idx on public.briefs (founder_id);
create index briefs_category_id_idx on public.briefs (category_id);

create table public.outreach (
  id uuid primary key default gen_random_uuid(),
  brief_id uuid not null references public.briefs (id) on delete cascade,
  manufacturer_id uuid not null references public.manufacturers (id) on delete cascade,
  match_score smallint check (match_score between 0 and 100),
  match_reason text check (char_length(match_reason) <= 300),
  status public.outreach_status not null default 'sent',
  decline_reason text check (char_length(decline_reason) <= 500),
  sent_at timestamptz not null default now(),
  nda_version text,
  nda_accepted_at timestamptz,
  nda_accepted_by uuid references public.users (id) on delete set null,
  responded_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (brief_id, manufacturer_id),
  constraint outreach_nda_before_progress check (status in ('sent', 'declined') or nda_accepted_at is not null),
  constraint outreach_decline_has_reason check (status <> 'declined' or decline_reason is not null)
);
comment on table public.outreach is 'A brief sent to one manufacturer. NDA, chat, quotes and samples hang off this row.';
comment on column public.outreach.nda_accepted_at is 'Set by public.accept_nda(). Gates access to the full brief.';
create index outreach_manufacturer_id_idx on public.outreach (manufacturer_id);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  outreach_id uuid not null references public.outreach (id) on delete cascade,
  sender_id uuid default auth.uid() references public.users (id) on delete set null,
  body text check (char_length(body) <= 4000),
  attachments text[] not null default '{}',
  created_at timestamptz not null default now(),
  constraint messages_not_empty check (char_length(btrim(coalesce(body, ''))) > 0 or cardinality(attachments) > 0)
);
create index messages_outreach_id_created_at_idx on public.messages (outreach_id, created_at);

create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  outreach_id uuid not null references public.outreach (id) on delete cascade,
  unit_price_paise bigint not null check (unit_price_paise > 0),
  moq integer not null check (moq > 0),
  lead_time_days integer not null check (lead_time_days between 1 and 730),
  notes text check (char_length(notes) <= 2000),
  valid_until date not null,
  created_by uuid default auth.uid() references public.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index quotes_outreach_id_idx on public.quotes (outreach_id);

create table public.samples (
  id uuid primary key default gen_random_uuid(),
  outreach_id uuid not null references public.outreach (id) on delete cascade,
  status public.sample_status not null default 'requested',
  feedback text check (char_length(feedback) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index samples_outreach_id_idx on public.samples (outreach_id);

-- ---------------------------------------------------------------------------
-- Admin and config
-- ---------------------------------------------------------------------------

create table public.match_weights (
  factor text primary key check (factor in ('capability', 'capacity', 'responsiveness', 'distance', 'formulation')),
  weight smallint not null check (weight between 0 and 100),
  description text not null,
  updated_at timestamptz not null default now()
);
comment on table public.match_weights is 'Matching score weights (out of 100). Tune here without a code change.';

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid default auth.uid() references public.users (id) on delete set null,
  manufacturer_id uuid references public.manufacturers (id) on delete cascade,
  reported_user_id uuid references public.users (id) on delete cascade,
  outreach_id uuid references public.outreach (id) on delete set null,
  reason public.report_reason not null,
  details text check (char_length(details) <= 2000),
  status public.report_status not null default 'open',
  resolution_note text check (char_length(resolution_note) <= 2000),
  resolved_by uuid references public.users (id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  constraint reports_has_subject check (manufacturer_id is not null or reported_user_id is not null)
);
create index reports_status_idx on public.reports (status);

-- ---------------------------------------------------------------------------
-- Triggers: updated_at
-- ---------------------------------------------------------------------------

create trigger set_updated_at before update on public.users
  for each row execute function private.set_updated_at();
create trigger set_updated_at before update on public.founder_profiles
  for each row execute function private.set_updated_at();
create trigger set_updated_at before update on public.manufacturers
  for each row execute function private.set_updated_at();
create trigger set_updated_at before update on public.briefs
  for each row execute function private.set_updated_at();
create trigger set_updated_at before update on public.outreach
  for each row execute function private.set_updated_at();
create trigger set_updated_at before update on public.samples
  for each row execute function private.set_updated_at();
create trigger set_updated_at before update on public.match_weights
  for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------------
-- Triggers: data integrity
-- ---------------------------------------------------------------------------

-- required_cert_ids is an array (per the spec), so check it against certifications
-- by hand and keep it sorted and de-duplicated for the matching filter.
create or replace function private.briefs_validate_certs()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
    from unnest(new.required_cert_ids) as r (id)
    where not exists (select 1 from public.certifications c where c.id = r.id)
  ) then
    raise exception 'required_cert_ids contains an unknown certification'
      using errcode = '23503';
  end if;
  new.required_cert_ids := array(select distinct unnest(new.required_cert_ids) order by 1);
  return new;
end;
$$;

create trigger validate_certs before insert or update of required_cert_ids on public.briefs
  for each row execute function private.briefs_validate_certs();

-- "Send brief to up to 10 manufacturers at once": at most 10 outreach rows per
-- brief that have not been declined. A declined one frees a slot so the founder
-- can pick another match.
create or replace function private.outreach_enforce_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Serialise concurrent sends for the same brief.
  perform 1 from public.briefs where id = new.brief_id for update;
  if (
    select count(*) from public.outreach
    where brief_id = new.brief_id and status <> 'declined'
  ) >= 10 then
    raise exception 'A brief can be with at most 10 manufacturers at a time'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger enforce_limit before insert on public.outreach
  for each row execute function private.outreach_enforce_limit();
