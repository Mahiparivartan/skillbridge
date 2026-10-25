# SkillBridge — Supabase-powered web app starter

A responsive React + TypeScript application for the SkillBridge student-to-internship journey. It includes a public landing page, Supabase authentication, student dashboard, profile editing, internship discovery, save/apply actions, application tracking, a starter learning roadmap, recruiter draft listing creation, and clearly labeled admin/verification placeholders.

## Technology
- React + TypeScript + Vite
- React Router
- Supabase Auth + PostgreSQL + Row Level Security
- Supabase SQL migration
- Lucide icons and custom responsive CSS

## 1. Requirements
- Node.js 20 or newer (recommended)
- A Supabase account/project

## 2. Install and run
```bash
npm install
cp .env.example .env
npm run dev
```
On Windows PowerShell, use:
```powershell
Copy-Item .env.example .env
npm install
npm run dev
```
Then edit `.env` and set:
```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY
```
Use the publishable/anon key from your Supabase project's API settings. Never put a service-role key in `.env` variables that begin with `VITE_`, in frontend code, or in Git.

## 3. Set up Supabase database
1. Create a Supabase project.
2. Open **SQL Editor** in the Supabase dashboard.
3. Open `supabase/migrations/0001_initial_schema.sql`, copy its contents into SQL Editor, and run it.
4. In Authentication settings, configure the allowed site/redirect URLs for local development and your deployed domain.
5. Save `.env`, restart the Vite dev server, then create a student account.
6. Verify that a `profiles` row is automatically created after signup.

## 4. Important current limitations
This is a runnable MVP foundation, not a finished production platform. The following are not implemented yet:
- AI Career Coach / AI-generated skill gap analysis (requires a server-side AI provider and secret).
- Persisted assessments and server-side assessment scoring.
- Project Lab submissions and evaluation.
- Portfolio publishing and public portfolio pages.
- Recruiter applicant workflow, company verification, and admin moderation queues.
- Trusted admin role assignment and privileged moderation Edge Functions.
- Daily internship ingestion / scheduler / source verification.
- Email provider integration and notification triggers.
- Full automated test suite, security audit, and production monitoring.

The roadmap page is currently starter guidance, not personalized AI output. Admin page is an informational placeholder, not an actual privileged admin console. No sample internships are injected: internship discovery shows only real published database records.

## 5. Role and security setup — read before production
The signup form lets a user select “recruiter” for interface intent, but the database trigger deliberately assigns every new account the `student` role. This prevents self-promotion. Therefore recruiter-only listing creation will be denied until you implement a trusted server-side recruiter onboarding/approval flow and assign the role securely.

The included SQL is an MVP baseline, not a complete production security review. Review all RLS policies before deployment. The `profiles` update policy protects the role column conceptually but should be validated in a real Supabase project; for robust protection, move role changes to a server-side function and enforce immutable role updates with a database trigger. Add admin-only policies and functions before enabling any moderation actions. Public portfolio fields should be separated from private profile data.

## 6. Build
```bash
npm run build
```
If the build reports TypeScript errors, fix them before deployment. This environment did not connect a live Supabase project, so live authentication, database access, and RLS behavior have not been verified here.

## 7. Deploy
Deploy the Vite app to Vercel, Netlify, or another static frontend host. Add the same `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` variables in the host's environment settings. Configure SPA fallback/rewrite to serve `index.html` for client-side routes. Apply and verify database migrations separately in Supabase.

## Folder layout
```text
src/
  App.tsx
  main.tsx
  styles.css
  lib/supabase.ts
  types.ts
supabase/
  migrations/
    0001_initial_schema.sql
.env.example
```
