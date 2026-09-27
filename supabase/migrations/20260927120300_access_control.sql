-- MakerMatch · Phase 1 · Access control (row-level security, grants, storage)
--
-- The rules, in plain words:
--   * Everyone signed in can read reference data (states, categories, certifications).
--   * A founder sees and edits only their own profile and briefs.
--   * Verified manufacturer profiles are visible to every signed-in user; a team sees
--     its own company whatever its status; admins see everything.
--   * A manufacturer that has been sent a brief sees only a summary (brief_previews)
--     until one of its team accepts the NDA (public.accept_nda). After that it can
--     read the full brief, its attachments and the founder's company profile. If
--     the manufacturer declines, that access ends.
--   * Chat is open to both sides once the NDA is accepted.
--   * Workflow state changes (sending briefs, accept/decline, quotes, samples) go
--     through SECURITY DEFINER functions added in their phases; until then the
--     client cannot write those tables at all.
--
-- Grants are explicit and least-privilege: every table first loses all client
-- privileges, then gets back only what its policies need. New tables in later
-- migrations must grant their own privileges.

-- ---------------------------------------------------------------------------
-- Helper functions used by policies (SECURITY DEFINER so policies on one table
-- can look at another without recursive RLS checks).
-- ---------------------------------------------------------------------------

create or replace function private.current_user_role()
returns public.user_role
language sql stable security definer set search_path = ''
as $$
  select role from public.users where id = (select auth.uid());
$$;

create or replace function private.is_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.users where id = (select auth.uid()) and role = 'admin');
$$;

create or replace function private.my_manufacturer_id()
returns uuid
language sql stable security definer set search_path = ''
as $$
  select manufacturer_id from public.manufacturer_members where user_id = (select auth.uid());
$$;

create or replace function private.is_member_of(
  p_manufacturer_id uuid,
  p_roles public.member_role[] default null
)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.manufacturer_members
    where manufacturer_id = p_manufacturer_id
      and user_id = (select auth.uid())
      and (p_roles is null or role = any (p_roles))
  );
$$;

create or replace function private.owns_brief(p_brief_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.briefs where id = p_brief_id and founder_id = (select auth.uid()));
$$;

-- The brief has been sent to my company (any status). Enough to see the summary.
create or replace function private.brief_sent_to_me(p_brief_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.outreach o
    join public.manufacturer_members mm on mm.manufacturer_id = o.manufacturer_id
    where o.brief_id = p_brief_id and mm.user_id = (select auth.uid())
  );
$$;

-- The NDA gate: my company accepted the NDA for this brief and has not declined it.
create or replace function private.has_nda_access(p_brief_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.outreach o
    join public.manufacturer_members mm on mm.manufacturer_id = o.manufacturer_id
    where o.brief_id = p_brief_id
      and mm.user_id = (select auth.uid())
      and o.nda_accepted_at is not null
      and o.status <> 'declined'
  );
$$;

-- A manufacturer with NDA access to any of this founder's briefs may see who they are.
create or replace function private.founder_visible_to_me(p_founder_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.briefs b
    join public.outreach o on o.brief_id = b.id
    join public.manufacturer_members mm on mm.manufacturer_id = o.manufacturer_id
    where b.founder_id = p_founder_id
      and mm.user_id = (select auth.uid())
      and o.nda_accepted_at is not null
      and o.status <> 'declined'
  );
$$;

create or replace function private.can_view_manufacturer(p_manufacturer_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.manufacturers where id = p_manufacturer_id and status = 'verified')
      or private.is_member_of(p_manufacturer_id)
      or private.is_admin()
      -- Founders keep seeing a manufacturer they have outreach with, even if it is later paused.
      or exists (
        select 1 from public.outreach o join public.briefs b on b.id = o.brief_id
        where o.manufacturer_id = p_manufacturer_id and b.founder_id = (select auth.uid())
      );
$$;

-- Founder of the brief, or anyone on the manufacturer's team.
create or replace function private.is_outreach_participant(p_outreach_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.outreach o
    join public.briefs b on b.id = o.brief_id
    where o.id = p_outreach_id
      and (
        b.founder_id = (select auth.uid())
        or exists (
          select 1 from public.manufacturer_members mm
          where mm.manufacturer_id = o.manufacturer_id and mm.user_id = (select auth.uid())
        )
      )
  );
$$;

-- Chat history: the founder always; the manufacturer while it has NDA access.
create or replace function private.can_read_thread(p_outreach_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.outreach o
    join public.briefs b on b.id = o.brief_id
    where o.id = p_outreach_id
      and o.nda_accepted_at is not null
      and (
        b.founder_id = (select auth.uid())
        or (
          o.status <> 'declined'
          and exists (
            select 1 from public.manufacturer_members mm
            where mm.manufacturer_id = o.manufacturer_id and mm.user_id = (select auth.uid())
          )
        )
      )
  );
$$;

-- Posting: either side, once the NDA is accepted and the outreach is still live.
create or replace function private.can_post_in_thread(p_outreach_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.outreach o
    where o.id = p_outreach_id
      and o.nda_accepted_at is not null
      and o.status <> 'declined'
  ) and private.is_outreach_participant(p_outreach_id);
$$;

-- Storage paths start with an id folder; a malformed path should deny, not error.
create or replace function private.try_uuid(p_value text)
returns uuid
language plpgsql immutable set search_path = ''
as $$
begin
  return p_value::uuid;
exception when invalid_text_representation then
  return null;
end;
$$;

create or replace function private.first_folder_id(p_object_name text)
returns uuid
language sql immutable set search_path = ''
as $$
  select private.try_uuid(split_part(p_object_name, '/', 1));
$$;

-- ---------------------------------------------------------------------------
-- Manufacturer guard triggers
-- ---------------------------------------------------------------------------

-- Team members can edit their profile, but verification and trust fields are
-- admin/system only. Admins and server-side callers (SQL editor, migrations,
-- seed, service role, SECURITY DEFINER functions) are trusted.
create or replace function private.manufacturers_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;
  if private.is_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.status := 'pending';
    new.rejection_reason := null;
    new.verified_at := null;
    new.verified_by := null;
    new.response_rate := null;
    new.median_reply_hours := null;
    new.created_by := (select auth.uid());
    return new;
  end if;

  new.status := old.status;
  new.rejection_reason := old.rejection_reason;
  new.verified_at := old.verified_at;
  new.verified_by := old.verified_by;
  new.response_rate := old.response_rate;
  new.median_reply_hours := old.median_reply_hours;
  new.created_by := old.created_by;
  new.created_at := old.created_at;

  -- Changing the legal identity of a verified company sends it back for review.
  if old.status = 'verified'
     and (new.gstin is distinct from old.gstin or new.legal_name is distinct from old.legal_name) then
    new.status := 'pending';
    new.verified_at := null;
    new.verified_by := null;
  end if;

  return new;
end;
$$;

create trigger guard before insert or update on public.manufacturers
  for each row execute function private.manufacturers_guard();

-- The person who applies becomes the company's owner.
create or replace function private.manufacturers_add_owner()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is not null
     and new.created_by = (select auth.uid())
     and private.current_user_role() = 'manufacturer' then
    insert into public.manufacturer_members (manufacturer_id, user_id, role)
    values (new.id, new.created_by, 'owner')
    on conflict do nothing;
  end if;
  return new;
end;
$$;

create trigger add_owner after insert on public.manufacturers
  for each row execute function private.manufacturers_add_owner();

-- ---------------------------------------------------------------------------
-- Enable RLS everywhere
-- ---------------------------------------------------------------------------

alter table public.indian_states enable row level security;
alter table public.categories enable row level security;
alter table public.certifications enable row level security;
alter table public.users enable row level security;
alter table public.founder_profiles enable row level security;
alter table public.manufacturers enable row level security;
alter table public.manufacturer_members enable row level security;
alter table public.manufacturer_capabilities enable row level security;
alter table public.manufacturer_certifications enable row level security;
alter table public.briefs enable row level security;
alter table public.outreach enable row level security;
alter table public.messages enable row level security;
alter table public.quotes enable row level security;
alter table public.samples enable row level security;
alter table public.match_weights enable row level security;
alter table public.reports enable row level security;

-- ---------------------------------------------------------------------------
-- Reference data: readable by anyone, editable by admins
-- ---------------------------------------------------------------------------

create policy "Anyone can read states" on public.indian_states
  for select to anon, authenticated using (true);

create policy "Anyone can read categories" on public.categories
  for select to anon, authenticated using (true);
create policy "Admins manage categories" on public.categories
  for all to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "Anyone can read certifications" on public.certifications
  for select to anon, authenticated using (true);
create policy "Admins manage certifications" on public.certifications
  for all to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------

create policy "Users read their own row" on public.users
  for select to authenticated using (id = (select auth.uid()));
create policy "Admins read all users" on public.users
  for select to authenticated using ((select private.is_admin()));
-- Column grants below limit this to name and email; role changes go through set_my_role().
create policy "Users update their own row" on public.users
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- founder_profiles
-- ---------------------------------------------------------------------------

create policy "Founders read their own profile" on public.founder_profiles
  for select to authenticated using (user_id = (select auth.uid()));
create policy "Manufacturers with NDA access read the founder" on public.founder_profiles
  for select to authenticated using (private.founder_visible_to_me(user_id));
create policy "Admins read founder profiles" on public.founder_profiles
  for select to authenticated using ((select private.is_admin()));
create policy "Founders create their own profile" on public.founder_profiles
  for insert to authenticated
  with check (user_id = (select auth.uid()) and (select private.current_user_role()) = 'founder');
create policy "Founders update their own profile" on public.founder_profiles
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- manufacturers and their team, capabilities, certifications
-- ---------------------------------------------------------------------------

-- created_by lets an applicant read back the row it just inserted (INSERT ... RETURNING
-- is checked before the trigger that makes them owner runs). The guard trigger sets
-- created_by from the session, so it can't be spoofed.
create policy "Read verified, own, or related manufacturers" on public.manufacturers
  for select to authenticated
  using (
    status = 'verified'
    or created_by = (select auth.uid())
    or private.can_view_manufacturer(id)
  );
create policy "Manufacturer users apply once" on public.manufacturers
  for insert to authenticated
  with check (
    (select private.current_user_role()) = 'manufacturer'
    and (select private.my_manufacturer_id()) is null
  );
create policy "Admins create manufacturers" on public.manufacturers
  for insert to authenticated with check ((select private.is_admin()));
create policy "Owners and admins update manufacturers" on public.manufacturers
  for update to authenticated
  using (private.is_member_of(id, array['owner']::public.member_role[]) or (select private.is_admin()))
  with check (private.is_member_of(id, array['owner']::public.member_role[]) or (select private.is_admin()));
create policy "Admins delete manufacturers" on public.manufacturers
  for delete to authenticated using ((select private.is_admin()));

create policy "Team members see their team" on public.manufacturer_members
  for select to authenticated
  using (private.is_member_of(manufacturer_id) or (select private.is_admin()));
-- Inviting team members arrives in Phase 2 (by phone number, via a function).
create policy "Admins manage team members" on public.manufacturer_members
  for all to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "Read capabilities of visible manufacturers" on public.manufacturer_capabilities
  for select to authenticated using (private.can_view_manufacturer(manufacturer_id));
create policy "Owners and admins manage capabilities" on public.manufacturer_capabilities
  for all to authenticated
  using (private.is_member_of(manufacturer_id, array['owner']::public.member_role[]) or (select private.is_admin()))
  with check (private.is_member_of(manufacturer_id, array['owner']::public.member_role[]) or (select private.is_admin()));

create policy "Read certifications of visible manufacturers" on public.manufacturer_certifications
  for select to authenticated using (private.can_view_manufacturer(manufacturer_id));
create policy "Owners and admins manage certifications" on public.manufacturer_certifications
  for all to authenticated
  using (private.is_member_of(manufacturer_id, array['owner']::public.member_role[]) or (select private.is_admin()))
  with check (private.is_member_of(manufacturer_id, array['owner']::public.member_role[]) or (select private.is_admin()));

-- ---------------------------------------------------------------------------
-- briefs (full details) and brief_previews (summary before NDA)
-- ---------------------------------------------------------------------------

create policy "Founders read their own briefs" on public.briefs
  for select to authenticated using (founder_id = (select auth.uid()));
create policy "Manufacturers read full briefs after accepting the NDA" on public.briefs
  for select to authenticated using (private.has_nda_access(id));
create policy "Admins read briefs" on public.briefs
  for select to authenticated using ((select private.is_admin()));
create policy "Founders create briefs" on public.briefs
  for insert to authenticated
  with check (founder_id = (select auth.uid()) and (select private.current_user_role()) = 'founder');
create policy "Founders update their own briefs" on public.briefs
  for update to authenticated
  using (founder_id = (select auth.uid())) with check (founder_id = (select auth.uid()));
create policy "Founders delete their own drafts" on public.briefs
  for delete to authenticated
  using (founder_id = (select auth.uid()) and status = 'draft');

-- The summary a manufacturer sees before signing the NDA: no title, specs, budget,
-- attachments or founder identity. It runs with the view owner's rights (that is
-- what lets it show a subset of columns), so its WHERE clause is the access check,
-- and security_barrier stops user filters from seeing rows before that check.
-- Supabase's Security Advisor flags this as a "security definer view"; that is
-- expected here.
create view public.brief_previews
with (security_invoker = false, security_barrier = true)
as
select
  b.id,
  b.category_id,
  b.product_type,
  b.target_qty,
  b.timeline,
  b.needs_formulation,
  b.required_cert_ids,
  b.status,
  b.created_at,
  fp.city as founder_city,
  fp.state as founder_state
from public.briefs b
left join public.founder_profiles fp on fp.user_id = b.founder_id
where b.status <> 'draft'
  and (private.owns_brief(b.id) or private.brief_sent_to_me(b.id) or private.is_admin());

comment on view public.brief_previews is
  'Brief summary for manufacturers before they accept the NDA. Full details are in briefs, gated by accept_nda().';

-- ---------------------------------------------------------------------------
-- outreach, messages, quotes, samples
-- ---------------------------------------------------------------------------

create policy "Participants read outreach" on public.outreach
  for select to authenticated
  using (
    private.owns_brief(brief_id)
    or private.is_member_of(manufacturer_id)
    or (select private.is_admin())
  );

create policy "Participants read the thread" on public.messages
  for select to authenticated
  using (private.can_read_thread(outreach_id) or (select private.is_admin()));
create policy "Participants post in the thread" on public.messages
  for insert to authenticated
  with check (sender_id = (select auth.uid()) and private.can_post_in_thread(outreach_id));

create policy "Participants read quotes" on public.quotes
  for select to authenticated
  using (private.is_outreach_participant(outreach_id) or (select private.is_admin()));

create policy "Participants read samples" on public.samples
  for select to authenticated
  using (private.is_outreach_participant(outreach_id) or (select private.is_admin()));

-- ---------------------------------------------------------------------------
-- match_weights, reports
-- ---------------------------------------------------------------------------

create policy "Admins read match weights" on public.match_weights
  for select to authenticated using ((select private.is_admin()));
create policy "Admins update match weights" on public.match_weights
  for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));

create policy "Users file reports" on public.reports
  for insert to authenticated
  with check (reporter_id = (select auth.uid()) and status = 'open' and resolved_by is null);
create policy "Users read their own reports" on public.reports
  for select to authenticated using (reporter_id = (select auth.uid()));
create policy "Admins read reports" on public.reports
  for select to authenticated using ((select private.is_admin()));
create policy "Admins resolve reports" on public.reports
  for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));

-- ---------------------------------------------------------------------------
-- NDA acceptance
-- ---------------------------------------------------------------------------

create or replace function public.accept_nda(p_outreach_id uuid, p_nda_version text default 'v1')
returns public.outreach
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_outreach public.outreach;
begin
  if (select auth.uid()) is null then
    raise exception 'You need to be signed in' using errcode = '42501';
  end if;
  if nullif(btrim(p_nda_version), '') is null then
    raise exception 'NDA version is required' using errcode = '22023';
  end if;

  select * into v_outreach from public.outreach where id = p_outreach_id for update;
  if not found or not private.is_member_of(v_outreach.manufacturer_id) then
    raise exception 'Brief not found' using errcode = 'P0002';
  end if;
  if v_outreach.status = 'declined' then
    raise exception 'This brief has been declined' using errcode = 'P0001';
  end if;
  if v_outreach.nda_accepted_at is not null then
    return v_outreach;
  end if;
  if (select status from public.briefs where id = v_outreach.brief_id) <> 'open' then
    raise exception 'This brief is no longer open' using errcode = 'P0001';
  end if;

  update public.outreach
  set status = 'nda_signed',
      nda_accepted_at = now(),
      nda_accepted_by = (select auth.uid()),
      nda_version = btrim(p_nda_version)
  where id = p_outreach_id
  returning * into v_outreach;

  return v_outreach;
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants (least privilege; RLS still applies on top)
-- ---------------------------------------------------------------------------

revoke all on all tables in schema public from anon, authenticated;
grant all on all tables in schema public to service_role;
grant usage on schema public to anon, authenticated;

grant select on public.indian_states, public.categories, public.certifications to anon, authenticated;
grant insert, update, delete on public.categories, public.certifications to authenticated;

grant select on public.users to authenticated;
grant update (name, email) on public.users to authenticated;

grant select, insert, update on public.founder_profiles to authenticated;
grant select, insert, update, delete on public.manufacturers to authenticated;
grant select, insert, update, delete on public.manufacturer_members to authenticated;
grant select, insert, update, delete on public.manufacturer_capabilities to authenticated;
grant select, insert, update, delete on public.manufacturer_certifications to authenticated;
grant select, insert, update, delete on public.briefs to authenticated;
grant select on public.brief_previews to authenticated;
grant select on public.outreach to authenticated;
grant select, insert on public.messages to authenticated;
grant select on public.quotes to authenticated;
grant select on public.samples to authenticated;
grant select, update on public.match_weights to authenticated;
grant select, insert, update on public.reports to authenticated;

-- Policies call the private helpers, so signed-in users need to execute them.
-- The private schema is not exposed through the Data API, so they are not RPCs.
grant usage on schema private to authenticated, service_role;
revoke execute on all functions in schema private from public, anon;
grant execute on all functions in schema private to authenticated, service_role;

revoke execute on function public.accept_nda(uuid, text) from public, anon;
grant execute on function public.accept_nda(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Storage: buckets and object policies. Every object path starts with the id it
-- belongs to, e.g. brief-attachments/<brief_id>/spec-sheet.pdf.
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('manufacturer-docs', 'manufacturer-docs', false, 10485760,
    array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']),
  ('manufacturer-photos', 'manufacturer-photos', true, 5242880,
    array['image/jpeg', 'image/png', 'image/webp']),
  ('brief-attachments', 'brief-attachments', false, 20971520, null),
  ('message-attachments', 'message-attachments', false, 20971520, null)
on conflict (id) do nothing;

-- manufacturer-docs/<manufacturer_id>/...: licences and GST certificates (private).
create policy "Manufacturer docs: team and admins read" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'manufacturer-docs'
    and (private.is_member_of(private.first_folder_id(name)) or (select private.is_admin()))
  );
create policy "Manufacturer docs: owners upload" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'manufacturer-docs'
    and private.is_member_of(private.first_folder_id(name), array['owner']::public.member_role[])
  );
create policy "Manufacturer docs: owners replace" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'manufacturer-docs'
    and private.is_member_of(private.first_folder_id(name), array['owner']::public.member_role[])
  );
create policy "Manufacturer docs: owners delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'manufacturer-docs'
    and private.is_member_of(private.first_folder_id(name), array['owner']::public.member_role[])
  );

-- manufacturer-photos/<manufacturer_id>/...: facility photos (public URLs).
create policy "Manufacturer photos: list for visible manufacturers" on storage.objects
  for select to authenticated
  using (bucket_id = 'manufacturer-photos' and private.can_view_manufacturer(private.first_folder_id(name)));
create policy "Manufacturer photos: owners upload" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'manufacturer-photos'
    and private.is_member_of(private.first_folder_id(name), array['owner']::public.member_role[])
  );
create policy "Manufacturer photos: owners replace" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'manufacturer-photos'
    and private.is_member_of(private.first_folder_id(name), array['owner']::public.member_role[])
  );
create policy "Manufacturer photos: owners delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'manufacturer-photos'
    and private.is_member_of(private.first_folder_id(name), array['owner']::public.member_role[])
  );

-- brief-attachments/<brief_id>/...: same NDA gate as the brief itself.
create policy "Brief attachments: founder, NDA holders and admins read" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'brief-attachments'
    and (
      private.owns_brief(private.first_folder_id(name))
      or private.has_nda_access(private.first_folder_id(name))
      or (select private.is_admin())
    )
  );
create policy "Brief attachments: founder uploads" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'brief-attachments' and private.owns_brief(private.first_folder_id(name)));
create policy "Brief attachments: founder replaces" on storage.objects
  for update to authenticated
  using (bucket_id = 'brief-attachments' and private.owns_brief(private.first_folder_id(name)));
create policy "Brief attachments: founder deletes" on storage.objects
  for delete to authenticated
  using (bucket_id = 'brief-attachments' and private.owns_brief(private.first_folder_id(name)));

-- message-attachments/<outreach_id>/...: same rules as the chat thread.
create policy "Message attachments: thread readers read" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'message-attachments'
    and (private.can_read_thread(private.first_folder_id(name)) or (select private.is_admin()))
  );
create policy "Message attachments: participants upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'message-attachments' and private.can_post_in_thread(private.first_folder_id(name)));
