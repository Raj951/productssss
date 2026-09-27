-- MakerMatch · sample data for local development and a test project.
--
-- DO NOT run this against production. The companies are fictional, and the two
-- logins below only work with the matching "test phone numbers" configured in
-- Supabase Auth (fixed OTP 123456, no SMS sent):
--
--   +91 90000 00001  Aditi Rao, founder of Sip Sutra Beverages (Bengaluru)
--   +91 90000 00002  Rohan Kulkarni, owner of Pinnacle Beverage Works (Pune)
--
-- Categories, certifications and states come from the reference-data migration.
-- Safe to re-run: every insert skips rows that already exist.

-- ---------------------------------------------------------------------------
-- Test logins (auth.users + phone identity). public.users rows are created by
-- the on_auth_user_created trigger.
-- ---------------------------------------------------------------------------

insert into auth.users (
  instance_id, id, aud, role, phone, phone_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  email_change_token_current, phone_change, phone_change_token, reauthentication_token,
  is_sso_user, is_anonymous
)
select
  '00000000-0000-0000-0000-000000000000', v.id, 'authenticated', 'authenticated', v.phone, now(),
  '{"provider": "phone", "providers": ["phone"]}'::jsonb, '{}'::jsonb, now(), now(),
  '', '', '', '', '', '', '', '',
  false, false
from (values
  ('a0000000-0000-4000-8000-000000000001'::uuid, '919000000001'),
  ('a0000000-0000-4000-8000-000000000002'::uuid, '919000000002')
) as v (id, phone)
on conflict (id) do nothing;

insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select
  u.id::text, u.id,
  jsonb_build_object('sub', u.id::text, 'phone', u.phone, 'email_verified', false, 'phone_verified', true),
  'phone', now(), now(), now()
from auth.users u
where u.id in ('a0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000002')
on conflict (provider_id, provider) do nothing;

update public.users set name = 'Aditi Rao', role = 'founder', email = 'aditi@sipsutra.example'
where id = 'a0000000-0000-4000-8000-000000000001' and role is null;

update public.users set name = 'Rohan Kulkarni', role = 'manufacturer'
where id = 'a0000000-0000-4000-8000-000000000002' and role is null;

-- ---------------------------------------------------------------------------
-- Sample founder
-- ---------------------------------------------------------------------------

insert into public.founder_profiles (user_id, company_name, city, state, gstin, stage) values
  ('a0000000-0000-4000-8000-000000000001', 'Sip Sutra Beverages', 'Bengaluru', 'KA', null, 'idea')
on conflict (user_id) do nothing;

-- ---------------------------------------------------------------------------
-- Sample manufacturers: four verified, one pending review (for the Phase 2
-- admin queue). Tier 1 city regions; GSTINs are fictional but checksum-valid.
-- ---------------------------------------------------------------------------

insert into public.manufacturers (
  id, legal_name, gstin, about, city, state, pincode,
  min_order_qty, monthly_capacity, offers_formulation, sample_policy,
  status, verified_at, response_rate, median_reply_hours
) values
  ('b0000000-0000-4000-8000-000000000001', 'Pinnacle Beverage Works Pvt Ltd', '27AAHCP4821K1Z6',
   'Carbonated and still beverage plant at Chakan MIDC with PET and can lines, in-house flavour lab.',
   'Pune', 'MH', '410501', 5000, 500000, true, 'paid_adjusted_on_order',
   'verified', now(), 92.50, 6.0),
  ('b0000000-0000-4000-8000-000000000002', 'Crunchwell Snacks Pvt Ltd', '24AAFCC7390M1Z9',
   'Extruded and kettle-cooked snacks, namkeen and roasted makhana. Nitrogen-flushed pouch lines.',
   'Ahmedabad', 'GJ', '382110', 10000, 800000, false, 'free',
   'verified', now(), 81.00, 18.0),
  ('b0000000-0000-4000-8000-000000000003', 'NutriForge Labs Pvt Ltd', '36AAICN5512Q1ZY',
   'Whey and plant protein powders, protein bars and gummies. Formulation and regulatory support.',
   'Hyderabad', 'TG', '502319', 1000, 200000, true, 'free',
   'verified', now(), 96.00, 4.0),
  ('b0000000-0000-4000-8000-000000000004', 'Meadowline Dairy Pvt Ltd', '33AAKCM2047R1Z1',
   'Flavoured milk, curd, paneer and ghee, plus oat and almond based alternatives. Cold-chain dispatch.',
   'Chennai', 'TN', '602105', 3000, 300000, true, 'paid',
   'verified', now(), 74.00, 30.0),
  ('b0000000-0000-4000-8000-000000000005', 'PackRight Co-Packers LLP', '06AAVFP8163L1ZD',
   'Contract filling and packing: powder sachets, stick packs, bottling and snack packing.',
   'Gurugram', 'HR', '122051', 20000, 1500000, false, 'paid',
   'pending', null, null, null)
on conflict (id) do nothing;

insert into public.manufacturer_members (manufacturer_id, user_id, role) values
  ('b0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000002', 'owner')
on conflict do nothing;

insert into public.manufacturer_capabilities (manufacturer_id, category_id, formats, packaging_types)
select v.manufacturer_id::uuid, c.id, v.formats, v.packaging_types
from (values
  ('b0000000-0000-4000-8000-000000000001', 'carbonated-drinks', array['carbonated', 'sugar_free', 'flavoured_soda'], array['pet_bottle', 'can', 'glass_bottle']),
  ('b0000000-0000-4000-8000-000000000001', 'juices-nectars', array['juice', 'nectar', 'concentrate'], array['pet_bottle', 'tetra_pak']),
  ('b0000000-0000-4000-8000-000000000001', 'functional-drinks', array['energy', 'electrolyte', 'botanical'], array['can', 'pet_bottle']),
  ('b0000000-0000-4000-8000-000000000001', 'beverage-bottling', array['hot_fill', 'cold_fill', 'carbonated'], array['pet_bottle', 'can']),
  ('b0000000-0000-4000-8000-000000000002', 'chips-extruded', array['fried', 'baked', 'extruded'], array['pouch', 'nitrogen_flush']),
  ('b0000000-0000-4000-8000-000000000002', 'namkeen', array['fried', 'roasted'], array['pouch', 'jar']),
  ('b0000000-0000-4000-8000-000000000002', 'nuts-seeds-makhana', array['roasted', 'flavoured'], array['pouch', 'jar', 'tin']),
  ('b0000000-0000-4000-8000-000000000003', 'protein-powders', array['powder', 'whey', 'plant_protein'], array['jar', 'pouch', 'sachet']),
  ('b0000000-0000-4000-8000-000000000003', 'nutrition-bars', array['bar', 'cold_pressed', 'baked'], array['flow_wrap', 'box']),
  ('b0000000-0000-4000-8000-000000000003', 'vitamins-supplements', array['gummy', 'tablet', 'capsule'], array['jar', 'blister']),
  ('b0000000-0000-4000-8000-000000000003', 'sports-nutrition', array['powder', 'effervescent'], array['jar', 'sachet', 'tube']),
  ('b0000000-0000-4000-8000-000000000004', 'milk-flavoured-milk', array['uht', 'pasteurised', 'flavoured'], array['tetra_pak', 'pet_bottle', 'glass_bottle']),
  ('b0000000-0000-4000-8000-000000000004', 'curd-yoghurt', array['set_curd', 'greek_yoghurt', 'buttermilk'], array['cup', 'pouch']),
  ('b0000000-0000-4000-8000-000000000004', 'paneer-cheese', array['fresh_paneer', 'processed_cheese'], array['vacuum_pack']),
  ('b0000000-0000-4000-8000-000000000004', 'ghee-butter', array['cow_ghee', 'a2_ghee', 'butter'], array['jar', 'tin', 'pouch']),
  ('b0000000-0000-4000-8000-000000000004', 'plant-based-dairy', array['oat', 'almond', 'soy'], array['tetra_pak', 'pet_bottle']),
  ('b0000000-0000-4000-8000-000000000005', 'powder-filling', array['powder', 'granules'], array['sachet', 'stick_pack', 'jar']),
  ('b0000000-0000-4000-8000-000000000005', 'beverage-bottling', array['cold_fill'], array['pet_bottle']),
  ('b0000000-0000-4000-8000-000000000005', 'snack-packing', array['repacking'], array['pouch', 'box'])
) as v (manufacturer_id, category_slug, formats, packaging_types)
join public.categories c on c.slug = v.category_slug
on conflict do nothing;

insert into public.manufacturer_certifications (manufacturer_id, certification_id, licence_no, expires_on)
select v.manufacturer_id::uuid, c.id, v.licence_no, v.expires_on::date
from (values
  ('b0000000-0000-4000-8000-000000000001', 'fssai', '11524999000101', '2028-03-31'),
  ('b0000000-0000-4000-8000-000000000001', 'iso-22000', 'ISO22K-PBW-2291', '2027-09-30'),
  ('b0000000-0000-4000-8000-000000000001', 'haccp', 'HACCP-PBW-0419', '2027-06-30'),
  ('b0000000-0000-4000-8000-000000000001', 'bis', 'CM/L-7700112233', '2027-12-31'),
  ('b0000000-0000-4000-8000-000000000002', 'fssai', '10724999000202', '2027-11-30'),
  ('b0000000-0000-4000-8000-000000000002', 'fssc-22000', 'FSSC-CWS-5512', '2028-01-31'),
  ('b0000000-0000-4000-8000-000000000002', 'halal', 'HAL-CWS-8830', '2027-04-30'),
  ('b0000000-0000-4000-8000-000000000003', 'fssai', '13624999000303', '2028-06-30'),
  ('b0000000-0000-4000-8000-000000000003', 'gmp', 'GMP-NFL-1207', '2027-08-31'),
  ('b0000000-0000-4000-8000-000000000003', 'haccp', 'HACCP-NFL-3321', '2027-08-31'),
  ('b0000000-0000-4000-8000-000000000003', 'halal', 'HAL-NFL-4410', '2027-02-28'),
  ('b0000000-0000-4000-8000-000000000003', 'us-fda', 'FFR-18800442211', null),
  ('b0000000-0000-4000-8000-000000000004', 'fssai', '12424999000404', '2028-02-29'),
  ('b0000000-0000-4000-8000-000000000004', 'iso-22000', 'ISO22K-MDL-7781', '2027-10-31'),
  ('b0000000-0000-4000-8000-000000000004', 'haccp', 'HACCP-MDL-2290', '2027-10-31'),
  ('b0000000-0000-4000-8000-000000000004', 'india-organic', 'NPOP-MDL-0098', '2027-03-31'),
  ('b0000000-0000-4000-8000-000000000005', 'fssai', '10824999000505', '2028-05-31'),
  ('b0000000-0000-4000-8000-000000000005', 'iso-22000', 'ISO22K-PRC-6612', '2027-12-31'),
  ('b0000000-0000-4000-8000-000000000005', 'gmp', 'GMP-PRC-0077', '2027-12-31')
) as v (manufacturer_id, cert_code, licence_no, expires_on)
join public.certifications c on c.code = v.cert_code
on conflict do nothing;
