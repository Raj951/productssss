# MakerMatch

Free, India-only app that matches founders with verified tier 1 food, beverage and nutrition
manufacturers. One Expo codebase for Android, iOS and web; Supabase (Mumbai) for the database,
phone OTP login, storage and security.

**Status: Phase 1 (Foundation) done.** Expo project, full database schema with row-level security,
phone OTP login, role pick, seed data. Phase 2 (manufacturer side) is next.

---

## 1. What you need to set up yourself

| What                                                                            | Why                                                         | Cost                                    |
| ------------------------------------------------------------------------------- | ----------------------------------------------------------- | --------------------------------------- |
| [Supabase](https://supabase.com) account + a project in **South Asia (Mumbai)** | Database, login, file storage                               | Free tier is enough for now             |
| [Expo Go](https://expo.dev/go) app on your phone (latest version, SDK 57)       | Run the app on your phone during development                | Free                                    |
| Node.js 20+ and Git on your computer                                            | Run the dev server and the Supabase CLI                     | Free                                    |
| An SMS provider (not needed yet)                                                | Send real OTPs to real numbers. Until then use test numbers | See [SMS](#6-real-sms-when-youre-ready) |
| Docker Desktop (optional)                                                       | Only if you want a local copy of Supabase on your computer  | Free                                    |

No keys are committed. The only values the app needs are your Supabase **Project URL** and
**publishable key**; both are safe to ship in an app. Never put the `service_role` / secret key or
the database password in the app or in git.

## 2. One-time setup

```bash
git clone <this repo> && cd productssss
npm install
```

### 2a. Create the Supabase project

1. In the Supabase dashboard: **New project** → name `makermatch` → region **South Asia (Mumbai)**
   → set a strong database password and save it in your password manager.
2. **Project Settings → API Keys**: copy the **Project URL** and the **Publishable key**
   (`sb_publishable_…`). (Older projects show an `anon` key instead; that works too.)
3. Create your local env file and paste them in:
   ```bash
   cp .env.example .env.local
   ```

### 2b. Load the database (schema, security rules, sample data)

```bash
npx supabase login                               # opens the browser once
npx supabase link --project-ref <your-ref>       # the ref is in your project URL; asks for the DB password
npx supabase db push --include-seed              # applies supabase/migrations + supabase/seed.sql
```

`--include-seed` loads the sample manufacturers and test logins. Use it for your test project only.
For production later, run `npx supabase db push` without it.

### 2c. Turn on phone login with test numbers (no SMS needed)

Dashboard → **Authentication → Sign In / Providers → Phone**:

1. Enable **Phone** sign-in.
2. **SMS provider**: Supabase only enables phone login when a provider is filled in, even for test
   numbers. Until you pick a real one, choose **Twilio** and enter placeholder values
   (e.g. Account SID `AC00000000000000000000000000000000`, Auth token `placeholder`,
   Message Service SID `MG00000000000000000000000000000000`). Test numbers never send an SMS.
3. **Test Phone Numbers and OTPs**:
   ```
   919000000001=123456,919000000002=123456,919000000009=123456
   ```
4. Set **Test OTPs Valid Until** to a date a few months out (they stop working after it).
5. Save.

## 3. Run it

```bash
npx expo start          # press w for web, or scan the QR code with Expo Go
```

## 4. Test it on your phone

1. Install **Expo Go** from the Play Store / App Store.
2. Put your phone on the same Wi-Fi as your computer and run `npx expo start`.
3. Android: open Expo Go → **Scan QR code**. iPhone: scan the QR code with the Camera app.
   (If it can't connect, e.g. office Wi-Fi, run `npx expo start --tunnel` instead.)
4. Try these paths:

| Try                 | Number          | Code   | You should see                                                                                     |
| ------------------- | --------------- | ------ | -------------------------------------------------------------------------------------------------- |
| Seeded founder      | 90000 00001     | 123456 | "Hi Aditi", company _Sip Sutra Beverages_, brief counts                                            |
| Seeded manufacturer | 90000 00002     | 123456 | "Hi Rohan", _Pinnacle Beverage Works_, **Verified**, Owner                                         |
| New sign-up         | 90000 00009     | 123456 | Pick founder or manufacturer on the welcome screen, land in that area                              |
| Role pick fallback  | 90000 00009     | 123456 | Tap **Log in** instead of a role (after deleting the user, below) → "How will you use MakerMatch?" |
| Wrong code          | any test number | 000000 | "That code is wrong or has expired…"                                                               |
| Sign out            |                 |        | Settings (gear icon) → Sign out → back to welcome                                                  |

To reuse `90000 00009` as a brand-new person, delete it in **Authentication → Users**. To try the
admin area, run this in the SQL editor, then log in with that number on **web**:

```sql
update public.users set role = 'admin' where phone = '+919000000009';
```

Your own real number works once a real SMS provider is set up (section 6).

## 5. Run everything locally (optional, needs Docker)

```bash
npx supabase start       # local Postgres, Auth, Storage, API; prints URL + PUBLISHABLE_KEY
npx supabase db reset    # re-apply migrations + seed at any time
npx supabase test db     # 64 row-level-security tests (pgTAP)
```

Point `.env.local` at `http://127.0.0.1:54321` and the printed publishable key. The local config
(`supabase/config.toml`) already has phone login and the three test numbers set up. To use the
local stack from your phone, use your computer's LAN IP instead of `127.0.0.1`.

Other checks: `npm run typecheck`, `npm run lint`, `npm run format:check`.
After changing the schema: `npm run gen:types` regenerates `src/types/database.ts`.

## 6. Real SMS when you're ready

Indian numbers need a DLT-registered sender ID and template (TRAI rules) with whichever provider
you use. Two routes:

- **Twilio Verify**: built into Supabase (pick it in the Phone provider settings). Quickest to switch on.
- **MSG91**: cheaper for Indian numbers and handles DLT, but Supabase doesn't support it natively.
  It plugs in through Supabase's **Send SMS hook** (a small Edge Function). When you have an MSG91
  account, sender ID and approved OTP template, that function can be added. It's a small, separate task.

Before launch: remove the test phone numbers and never run `seed.sql` on production.

---

## What's in the repo

```
src/
  app/                      Expo Router screens (every file is a route)
    _layout.tsx             Auth gate: decides which area each person can reach
    (auth)/                 Welcome & role pick, phone number, OTP
    choose-role.tsx         Role pick for a signed-in account without a role
    founder/                Founder area   (home placeholder; briefs arrive in Phase 3)
    manufacturer/           Manufacturer area (home placeholder; application in Phase 2)
    admin/                  Admin area, web only (placeholder; queue + CSV import in Phase 2)
    settings.tsx            Account details, sign out
  providers/auth-provider.tsx  Session, profile, OTP, role pick
  lib/                      Supabase client, phone parsing, error messages
  components/               Shared UI (NativeWind / Tailwind classes)
  types/database.ts         Generated from the database schema
supabase/
  migrations/               Schema, reference data, auth, access control (RLS + storage)
  seed.sql                  5 sample manufacturers, 1 sample founder, 2 test logins
  tests/database/           Row-level-security tests
  config.toml               Local Supabase settings (phone login + test numbers)
```

### Data model

The 13 tables from the spec: `users`, `founder_profiles`, `manufacturers`,
`manufacturer_members`, `categories`, `manufacturer_capabilities`, `certifications`,
`manufacturer_certifications`, `briefs`, `outreach`, `messages`, `quotes`, `samples`. Three small
additions the spec calls for elsewhere: `indian_states` (with GST state codes), `match_weights`
("weights live in a config table") and `reports` (admin moderation).

- Money is stored in paise as integers, in columns named `*_paise`.
- GSTINs are checked in the database, including the check digit.
- `public.users.role` stays empty until the role pick; admin can only be set with SQL.

### Who can see what (row-level security)

- Founders see and edit only their own profile and briefs.
- Every signed-in user sees **verified** manufacturers; a team sees its own company in any status.
- A manufacturer that has been sent a brief sees only a **summary** (`brief_previews`: category,
  product type, quantity, timeline, certifications needed, formulation help, founder's city). The
  title, specs, budget, attachments and founder's identity are hidden.
- After a team member accepts the NDA (`accept_nda()`), that company can read the full brief, its
  attachments and the founder's company, and chat opens. If it declines, that access ends.
- Team members can edit their profile but can't verify themselves; changing the legal name or GSTIN
  of a verified company sends it back for review.
- Sending briefs, accept/decline, quotes and sample updates go through database functions added in
  Phases 4–5. Until then, the app can't write those tables at all.

All of this is covered by `supabase/tests/database/access_control.test.sql`.

## Build plan

1. **Foundation**: done
2. Manufacturer side: application form, document upload, admin approval, profile editing, CSV import
3. Founder briefs: 4-step brief form, my briefs, brief detail
4. Matching and outreach: matching function, ranked matches, send to shortlist, NDA, inbox
5. Conversation: real-time chat, quotes and comparison, samples, push and email
6. Launch prep: Hindi labels, analytics, error tracking, real manufacturers, store builds, web deploy
