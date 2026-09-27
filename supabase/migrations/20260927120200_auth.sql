-- MakerMatch · Phase 1 · Auth: mirror logins into public.users, and the role pick
--
-- Supabase Auth owns auth.users. Every new login (phone OTP) gets a public.users
-- row with role = null; the app then asks "founder or manufacturer?" and calls
-- public.set_my_role(). Admins are never self-assigned: set them with SQL.

create or replace function private.normalise_phone(p_phone text)
returns text
language sql
immutable
set search_path = ''
as $$
  -- Supabase Auth stores phones without the leading '+', e.g. 919876543210.
  select case when nullif(btrim(p_phone), '') is null then null
              else '+' || ltrim(btrim(p_phone), '+') end;
$$;

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.users (id, phone)
  values (new.id, private.normalise_phone(new.phone))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_auth_user();

create or replace function private.handle_auth_user_phone_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.users set phone = private.normalise_phone(new.phone) where id = new.id;
  return new;
end;
$$;

create trigger on_auth_user_phone_changed
  after update of phone on auth.users
  for each row
  when (old.phone is distinct from new.phone)
  execute function private.handle_auth_user_phone_change();

-- Called once after the first login. Idempotent for the same role; refuses to
-- switch an account between founder and manufacturer, and never grants admin.
create or replace function public.set_my_role(p_role public.user_role)
returns public.users
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_user public.users;
begin
  if v_uid is null then
    raise exception 'You need to be signed in' using errcode = '42501';
  end if;
  if p_role is null or p_role not in ('founder', 'manufacturer') then
    raise exception 'Choose founder or manufacturer' using errcode = '22023';
  end if;

  -- The auth trigger normally created this row already; this covers accounts
  -- that existed before the trigger did.
  insert into public.users (id, phone)
  select u.id, private.normalise_phone(u.phone) from auth.users u where u.id = v_uid
  on conflict (id) do nothing;

  update public.users set role = p_role
  where id = v_uid and role is null
  returning * into v_user;

  if not found then
    select * into v_user from public.users where id = v_uid;
    if v_user.role is distinct from p_role then
      raise exception 'This phone number is already registered as a %', v_user.role
        using errcode = 'P0001';
    end if;
  end if;

  return v_user;
end;
$$;

revoke execute on function public.set_my_role(public.user_role) from public, anon;
grant execute on function public.set_my_role(public.user_role) to authenticated;
