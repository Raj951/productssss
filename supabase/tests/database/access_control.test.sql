-- Row-level security tests. Run with: npx supabase test db
--
-- Everything runs inside one transaction that is rolled back, so the fixtures
-- below never touch real or seed data.

begin;
create extension if not exists pgtap with schema extensions;

select plan(64);

-- ---------------------------------------------------------------------------
-- Fixtures (as postgres)
-- ---------------------------------------------------------------------------

insert into auth.users (id, aud, role, phone) values
  ('10000000-0000-4000-8000-00000000000a', 'authenticated', 'authenticated', '919100000001'), -- founder A
  ('10000000-0000-4000-8000-00000000000b', 'authenticated', 'authenticated', '919100000002'), -- founder B
  ('20000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '919200000001'), -- owner, M1
  ('20000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '919200000002'), -- owner, M2
  ('20000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '919200000003'), -- owner, M3 (pending)
  ('20000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', '919200000004'), -- sales, M1
  ('20000000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', '919200000005'), -- applicant, no company yet
  ('30000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '919300000001'), -- admin
  ('40000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '919400000001'); -- newcomer

update public.users set role = 'founder'
  where id in ('10000000-0000-4000-8000-00000000000a', '10000000-0000-4000-8000-00000000000b');
update public.users set role = 'manufacturer' where id::text like '20000000-%';
update public.users set role = 'admin' where id = '30000000-0000-4000-8000-000000000001';

insert into public.founder_profiles (user_id, company_name, city, state) values
  ('10000000-0000-4000-8000-00000000000a', 'Founder A Foods', 'Mumbai', 'MH'),
  ('10000000-0000-4000-8000-00000000000b', 'Founder B Drinks', 'Bengaluru', 'KA');

insert into public.manufacturers (id, legal_name, gstin, city, state, pincode, min_order_qty, monthly_capacity, status) values
  ('c0000000-0000-4000-8000-000000000001', 'Test Maker One', '27AAACT1111A1Z9', 'Pune', 'MH', '411001', 1000, 100000, 'verified'),
  ('c0000000-0000-4000-8000-000000000002', 'Test Maker Two', '27AAACT2222B1Z1', 'Mumbai', 'MH', '400001', 1000, 100000, 'verified'),
  ('c0000000-0000-4000-8000-000000000003', 'Test Maker Three', '29AAACT3333C1ZP', 'Bengaluru', 'KA', '560001', 1000, 100000, 'pending');

insert into public.manufacturer_members (manufacturer_id, user_id, role) values
  ('c0000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'owner'),
  ('c0000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', 'owner'),
  ('c0000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000003', 'owner'),
  ('c0000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000004', 'sales');

insert into public.briefs (id, founder_id, title, category_id, product_type, target_qty, timeline, status, budget_min_paise, budget_max_paise) values
  ('d0000000-0000-4000-8000-0000000000a1', '10000000-0000-4000-8000-00000000000a', 'Secret sugar-free cola',
    (select id from public.categories where slug = 'carbonated-drinks'), 'Cola', 5000, '1_to_3_months', 'open', 50000000, 150000000),
  ('d0000000-0000-4000-8000-0000000000b1', '10000000-0000-4000-8000-00000000000b', 'Founder B kombucha',
    (select id from public.categories where slug = 'functional-drinks'), 'Kombucha', 2000, 'within_1_month', 'open', null, null);
insert into public.briefs (id, founder_id, title, status) values
  ('d0000000-0000-4000-8000-0000000000a2', '10000000-0000-4000-8000-00000000000a', 'Half-written draft', 'draft');

insert into public.outreach (id, brief_id, manufacturer_id, match_score) values
  ('e0000000-0000-4000-8000-000000000001', 'd0000000-0000-4000-8000-0000000000a1', 'c0000000-0000-4000-8000-000000000001', 88),
  ('e0000000-0000-4000-8000-000000000002', 'd0000000-0000-4000-8000-0000000000a1', 'c0000000-0000-4000-8000-000000000002', 71),
  ('e0000000-0000-4000-8000-000000000003', 'd0000000-0000-4000-8000-0000000000b1', 'c0000000-0000-4000-8000-000000000002', 64);

insert into storage.objects (bucket_id, name) values
  ('brief-attachments', 'd0000000-0000-4000-8000-0000000000a1/formula.pdf');

-- ---------------------------------------------------------------------------
-- Founders see only their own briefs
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims', '{"sub": "10000000-0000-4000-8000-00000000000a", "role": "authenticated"}', true);
set local role authenticated;

select results_eq(
  $$ select id from public.briefs order by id $$,
  $$ values ('d0000000-0000-4000-8000-0000000000a1'::uuid), ('d0000000-0000-4000-8000-0000000000a2'::uuid) $$,
  'Founder A sees exactly their own two briefs (open and draft)'
);
select throws_ok(
  $$ insert into public.briefs (founder_id, title) values ('10000000-0000-4000-8000-00000000000b', 'Impersonation') $$,
  '42501', null,
  'Founder A cannot create a brief as founder B'
);
with changed as (
  update public.briefs set title = 'hijacked' where id = 'd0000000-0000-4000-8000-0000000000b1' returning 1
)
select is(count(*)::int, 0, 'Founder A cannot edit founder B''s brief') from changed;
select results_eq(
  $$ select id from public.outreach order by id $$,
  $$ values ('e0000000-0000-4000-8000-000000000001'::uuid), ('e0000000-0000-4000-8000-000000000002'::uuid) $$,
  'Founder A sees the outreach for their own brief only'
);
select is(
  (select count(*)::int from public.founder_profiles), 1,
  'Founder A sees only their own founder profile'
);
select is((select count(*)::int from public.users), 1, 'Founder A sees only their own user row');
select results_eq(
  $$ select id from public.manufacturers where legal_name like 'Test Maker%' order by id $$,
  $$ values ('c0000000-0000-4000-8000-000000000001'::uuid), ('c0000000-0000-4000-8000-000000000002'::uuid) $$,
  'Founders see verified manufacturers but not pending ones'
);
select throws_ok(
  $$ insert into public.messages (outreach_id, body) values ('e0000000-0000-4000-8000-000000000001', 'hello?') $$,
  '42501', null,
  'Founder cannot open the chat before the manufacturer accepts the NDA'
);
select throws_ok(
  $$ update public.users set role = 'admin' where id = '10000000-0000-4000-8000-00000000000a' $$,
  '42501', null,
  'Users cannot change their own role'
);
select throws_ok(
  $$ insert into public.outreach (brief_id, manufacturer_id) values ('d0000000-0000-4000-8000-0000000000a1', 'c0000000-0000-4000-8000-000000000003') $$,
  '42501', null,
  'Clients cannot write outreach directly (sending comes via a function in Phase 4)'
);

reset role;
select set_config('request.jwt.claims', '{"sub": "10000000-0000-4000-8000-00000000000b", "role": "authenticated"}', true);
set local role authenticated;

select results_eq(
  $$ select id from public.briefs $$,
  $$ values ('d0000000-0000-4000-8000-0000000000b1'::uuid) $$,
  'Founder B sees only their own brief'
);
select results_eq(
  $$ select id from public.outreach $$,
  $$ values ('e0000000-0000-4000-8000-000000000003'::uuid) $$,
  'Founder B sees only the outreach for their brief'
);

-- ---------------------------------------------------------------------------
-- Manufacturers before the NDA: summary only
-- ---------------------------------------------------------------------------

reset role;
select set_config('request.jwt.claims', '{"sub": "20000000-0000-4000-8000-000000000001", "role": "authenticated"}', true);
set local role authenticated;

select is((select count(*)::int from public.briefs), 0, 'Before the NDA, M1 cannot read any full brief');
select results_eq(
  $$ select id, product_type, target_qty, founder_city from public.brief_previews $$,
  $$ values ('d0000000-0000-4000-8000-0000000000a1'::uuid, 'Cola'::text, 5000, 'Mumbai'::text) $$,
  'Before the NDA, M1 sees the summary of the brief sent to it, and nothing else'
);
select results_eq(
  $$ select id from public.outreach $$,
  $$ values ('e0000000-0000-4000-8000-000000000001'::uuid) $$,
  'M1 sees only its own outreach row'
);
select is((select count(*)::int from public.founder_profiles), 0, 'Before the NDA, M1 cannot see who the founder is');
select is(
  (select count(*)::int from storage.objects where bucket_id = 'brief-attachments'), 0,
  'Before the NDA, M1 cannot read the brief''s attachments'
);
select throws_ok(
  $$ insert into public.messages (outreach_id, body) values ('e0000000-0000-4000-8000-000000000001', 'Interested!') $$,
  '42501', null,
  'M1 cannot message before accepting the NDA'
);
select throws_ok(
  $$ insert into public.briefs (founder_id, title) values ('20000000-0000-4000-8000-000000000001', 'Not a founder') $$,
  '42501', null,
  'Manufacturer accounts cannot create briefs'
);

reset role;
select hasnt_column('public', 'brief_previews', 'title', 'The pre-NDA summary has no title');
select hasnt_column('public', 'brief_previews', 'specs', 'The pre-NDA summary has no specs');
select hasnt_column('public', 'brief_previews', 'budget_max_paise', 'The pre-NDA summary has no budget');
select hasnt_column('public', 'brief_previews', 'attachments', 'The pre-NDA summary has no attachments');

-- ---------------------------------------------------------------------------
-- Accepting the NDA unlocks the full brief for that manufacturer only
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims', '{"sub": "20000000-0000-4000-8000-000000000002", "role": "authenticated"}', true);
set local role authenticated;

select throws_ok(
  $$ select public.accept_nda('e0000000-0000-4000-8000-000000000001') $$,
  'P0002', null,
  'M2 cannot accept the NDA on M1''s outreach'
);

reset role;
-- The sales member of M1 accepts on the company's behalf.
select set_config('request.jwt.claims', '{"sub": "20000000-0000-4000-8000-000000000004", "role": "authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$ select public.accept_nda('e0000000-0000-4000-8000-000000000001', 'v1') $$,
  'A member of M1 accepts the NDA'
);
select is(
  (select status::text from public.outreach where id = 'e0000000-0000-4000-8000-000000000001'), 'nda_signed',
  'Outreach moves to nda_signed'
);

reset role;
select set_config('request.jwt.claims', '{"sub": "20000000-0000-4000-8000-000000000001", "role": "authenticated"}', true);
set local role authenticated;

select results_eq(
  $$ select id, title, budget_max_paise from public.briefs $$,
  $$ values ('d0000000-0000-4000-8000-0000000000a1'::uuid, 'Secret sugar-free cola'::text, 150000000::bigint) $$,
  'After the NDA, every M1 team member reads the full brief, and only that brief'
);
select results_eq(
  $$ select company_name from public.founder_profiles $$,
  $$ values ('Founder A Foods'::text) $$,
  'After the NDA, M1 can see the founder''s company'
);
select is(
  (select count(*)::int from storage.objects where bucket_id = 'brief-attachments'), 1,
  'After the NDA, M1 can read the brief''s attachments'
);
select lives_ok(
  $$ insert into public.messages (outreach_id, body) values ('e0000000-0000-4000-8000-000000000001', 'We can do this.') $$,
  'After the NDA, M1 can message the founder'
);
select lives_ok(
  $$ select public.accept_nda('e0000000-0000-4000-8000-000000000001') $$,
  'Accepting the NDA again is harmless'
);

reset role;
select set_config('request.jwt.claims', '{"sub": "10000000-0000-4000-8000-00000000000a", "role": "authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$ insert into public.messages (outreach_id, body) values ('e0000000-0000-4000-8000-000000000001', 'Great, sending specs.') $$,
  'After the NDA, the founder can reply'
);
select is((select count(*)::int from public.messages), 2, 'Founder sees the whole thread');

reset role;
select set_config('request.jwt.claims', '{"sub": "20000000-0000-4000-8000-000000000002", "role": "authenticated"}', true);
set local role authenticated;

select is((select count(*)::int from public.briefs), 0, 'M2, which has not accepted, still sees no full brief');
select is((select count(*)::int from public.brief_previews), 2, 'M2 sees summaries of the two briefs sent to it');
select is((select count(*)::int from public.messages), 0, 'M2 cannot read M1''s chat with the founder');
select throws_ok(
  $$ insert into public.messages (outreach_id, body) values ('e0000000-0000-4000-8000-000000000001', 'Pick us instead') $$,
  '42501', null,
  'M2 cannot post in M1''s thread'
);

-- ---------------------------------------------------------------------------
-- Declining ends the manufacturer's access
-- ---------------------------------------------------------------------------

reset role;
update public.outreach set status = 'declined', decline_reason = 'Line is full this quarter'
  where id = 'e0000000-0000-4000-8000-000000000001';

select set_config('request.jwt.claims', '{"sub": "20000000-0000-4000-8000-000000000001", "role": "authenticated"}', true);
set local role authenticated;

select is((select count(*)::int from public.briefs), 0, 'After declining, M1 loses the full brief');
select is((select count(*)::int from public.messages), 0, 'After declining, M1 loses the chat history');
select is(
  (select count(*)::int from storage.objects where bucket_id = 'brief-attachments'), 0,
  'After declining, M1 loses the attachments'
);

reset role;
select set_config('request.jwt.claims', '{"sub": "10000000-0000-4000-8000-00000000000a", "role": "authenticated"}', true);
set local role authenticated;
select is((select count(*)::int from public.messages), 2, 'The founder keeps the chat history');

-- ---------------------------------------------------------------------------
-- Manufacturer profiles: verification fields are admin-only
-- ---------------------------------------------------------------------------

reset role;
select set_config('request.jwt.claims', '{"sub": "20000000-0000-4000-8000-000000000003", "role": "authenticated"}', true);
set local role authenticated;

select is(
  (select count(*)::int from public.manufacturers where id = 'c0000000-0000-4000-8000-000000000003'), 1,
  'A pending manufacturer''s team can see its own profile'
);
update public.manufacturers set status = 'verified', monthly_capacity = 120000
  where id = 'c0000000-0000-4000-8000-000000000003';
select results_eq(
  $$ select status::text, monthly_capacity from public.manufacturers where id = 'c0000000-0000-4000-8000-000000000003' $$,
  $$ values ('pending'::text, 120000) $$,
  'Owners can edit their profile but cannot verify themselves'
);
with changed as (
  update public.manufacturers set about = 'hijacked' where id = 'c0000000-0000-4000-8000-000000000001' returning 1
)
select is(count(*)::int, 0, 'Owners cannot edit another manufacturer') from changed;

reset role;
select set_config('request.jwt.claims', '{"sub": "20000000-0000-4000-8000-000000000001", "role": "authenticated"}', true);
set local role authenticated;
update public.manufacturers set legal_name = 'Test Maker One Renamed Pvt Ltd'
  where id = 'c0000000-0000-4000-8000-000000000001';
select is(
  (select status::text from public.manufacturers where id = 'c0000000-0000-4000-8000-000000000001'), 'pending',
  'Changing a verified company''s legal name sends it back for review'
);

-- ---------------------------------------------------------------------------
-- Applying as a manufacturer
-- ---------------------------------------------------------------------------

reset role;
select set_config('request.jwt.claims', '{"sub": "20000000-0000-4000-8000-000000000005", "role": "authenticated"}', true);
set local role authenticated;

select results_eq(
  $$ insert into public.manufacturers (legal_name, gstin, city, state, pincode, min_order_qty, monthly_capacity, status)
     values ('Applicant Foods Pvt Ltd', '27AAACA5555E1ZW', 'Pune', 'MH', '411001', 500, 50000, 'verified')
     returning status::text $$,
  $$ values ('pending'::text) $$,
  'A manufacturer account can apply (and read it back); a claimed "verified" status is forced to pending'
);
select results_eq(
  $$ select mm.role::text from public.manufacturer_members mm
     join public.manufacturers m on m.id = mm.manufacturer_id where m.gstin = '27AAACA5555E1ZW' $$,
  $$ values ('owner'::text) $$,
  'The applicant becomes the company owner'
);
select throws_ok(
  $$ insert into public.manufacturers (legal_name, gstin, city, state, pincode, min_order_qty, monthly_capacity)
     values ('Second Company Pvt Ltd', '27AAACA6666F1ZO', 'Pune', 'MH', '411001', 500, 50000) $$,
  '42501', null,
  'A person can apply for only one company'
);

reset role;
select set_config('request.jwt.claims', '{"sub": "10000000-0000-4000-8000-00000000000a", "role": "authenticated"}', true);
set local role authenticated;
select throws_ok(
  $$ insert into public.manufacturers (legal_name, gstin, city, state, pincode, min_order_qty, monthly_capacity)
     values ('Founder Posing As Maker', '27AAACA6666F1ZO', 'Pune', 'MH', '411001', 500, 50000) $$,
  '42501', null,
  'Founder accounts cannot create manufacturers'
);
select is(
  (select count(*)::int from public.manufacturers where gstin = '27AAACA5555E1ZW'), 0,
  'Founders cannot see a pending application'
);
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('brief-attachments', 'd0000000-0000-4000-8000-0000000000b1/sneaky.pdf') $$,
  '42501', null,
  'A founder cannot upload into another founder''s brief folder'
);

-- ---------------------------------------------------------------------------
-- Storage: licence documents
-- ---------------------------------------------------------------------------

reset role;
select set_config('request.jwt.claims', '{"sub": "20000000-0000-4000-8000-000000000003", "role": "authenticated"}', true);
set local role authenticated;
select lives_ok(
  $$ insert into storage.objects (bucket_id, name) values ('manufacturer-docs', 'c0000000-0000-4000-8000-000000000003/gst-certificate.pdf') $$,
  'Owners can upload their own licence documents'
);
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('manufacturer-docs', 'c0000000-0000-4000-8000-000000000001/forged.pdf') $$,
  '42501', null,
  'Owners cannot upload into another manufacturer''s folder'
);
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('manufacturer-docs', 'not-a-uuid/file.pdf') $$,
  '42501', null,
  'A malformed storage path is denied, not an error'
);

reset role;
select set_config('request.jwt.claims', '{"sub": "10000000-0000-4000-8000-00000000000a", "role": "authenticated"}', true);
set local role authenticated;
select is(
  (select count(*)::int from storage.objects where bucket_id = 'manufacturer-docs'), 0,
  'Founders cannot read manufacturers'' licence documents'
);

-- ---------------------------------------------------------------------------
-- Role pick
-- ---------------------------------------------------------------------------

reset role;
select set_config('request.jwt.claims', '{"sub": "40000000-0000-4000-8000-000000000001", "role": "authenticated"}', true);
set local role authenticated;

select is((select role::text from public.users), null, 'A new login has no role yet');
select is((public.set_my_role('founder')).role::text, 'founder', 'set_my_role assigns founder');
select throws_ok(
  $$ select public.set_my_role('manufacturer') $$,
  'P0001', null,
  'An account cannot switch from founder to manufacturer'
);
select throws_ok(
  $$ select public.set_my_role('admin') $$,
  '22023', null,
  'Nobody can make themselves admin'
);

-- ---------------------------------------------------------------------------
-- Admins and anonymous visitors
-- ---------------------------------------------------------------------------

reset role;
select set_config('request.jwt.claims', '{"sub": "30000000-0000-4000-8000-000000000001", "role": "authenticated"}', true);
set local role authenticated;
select is(
  (select count(*)::int from public.briefs where id::text like 'd0000000-%'), 3,
  'Admins can read every brief, drafts included'
);

reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;
select ok((select count(*) from public.categories) > 0, 'Anonymous visitors can read categories');
select throws_ok(
  $$ select count(*) from public.manufacturers $$,
  '42501', null,
  'Anonymous visitors cannot read manufacturers'
);

-- ---------------------------------------------------------------------------
-- Data rules
-- ---------------------------------------------------------------------------

reset role;
select throws_ok(
  $$ insert into public.manufacturers (legal_name, gstin, city, state, pincode, min_order_qty, monthly_capacity)
     values ('Bad GST Co', '27AAACT1111A1Z0', 'Pune', 'MH', '411001', 10, 100) $$,
  '23514', null,
  'A GSTIN with a wrong check digit is rejected'
);

-- Fill brief B1 up to 10 live outreach rows (it has 1), then try an 11th.
insert into public.manufacturers (legal_name, gstin, city, state, pincode, min_order_qty, monthly_capacity, status)
select
  'Bulk Maker ' || n,
  (select p || c
   from (select '27AAACB' || lpad(n::text, 4, '0') || 'Z1Z' as p) as prefix,
        unnest(string_to_array('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', null)) as c
   where public.is_valid_gstin(p || c)),
  'Pune', 'MH', '411001', 10, 1000, 'verified'
from generate_series(1, 10) as n;

insert into public.outreach (brief_id, manufacturer_id)
select 'd0000000-0000-4000-8000-0000000000b1', id
from public.manufacturers where legal_name like 'Bulk Maker %' and legal_name <> 'Bulk Maker 10';

select throws_ok(
  $$ insert into public.outreach (brief_id, manufacturer_id)
     select 'd0000000-0000-4000-8000-0000000000b1', id from public.manufacturers where legal_name = 'Bulk Maker 10' $$,
  'P0001', null,
  'A brief can be with at most 10 manufacturers at a time'
);

select * from finish();
rollback;
