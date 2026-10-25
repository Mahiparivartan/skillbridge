-- SkillBridge starter schema for Supabase PostgreSQL.
-- Apply via Supabase SQL Editor or Supabase CLI migrations.
create extension if not exists pgcrypto;

create type public.app_role as enum ('student', 'recruiter', 'admin');
create type public.work_mode_type as enum ('remote', 'hybrid', 'onsite');
create type public.internship_status as enum ('draft', 'published', 'closed', 'expired');
create type public.application_status as enum ('applied', 'under_review', 'shortlisted', 'interview', 'selected', 'rejected', 'withdrawn');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role public.app_role not null default 'student',
  college text,
  degree text,
  graduation_year integer check (graduation_year is null or graduation_year between 2000 and 2100),
  target_role text,
  github_url text,
  linkedin_url text,
  portfolio_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  website text,
  description text,
  verification_status text not null default 'pending' check (verification_status in ('pending','verified','rejected')),
  verification_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.internships (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references auth.users(id) on delete cascade,
  company_name text not null,
  title text not null,
  description text not null,
  required_skills text[] not null default '{}',
  location text,
  work_mode public.work_mode_type not null default 'remote',
  stipend_min integer check (stipend_min is null or stipend_min >= 0),
  stipend_max integer check (stipend_max is null or stipend_max >= 0),
  duration text,
  deadline date,
  status public.internship_status not null default 'draft',
  source_url text,
  last_verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (stipend_min is null or stipend_max is null or stipend_max >= stipend_min)
);
create index internships_status_created_idx on public.internships(status, created_at desc);
create index internships_work_mode_idx on public.internships(work_mode);
create index internships_deadline_idx on public.internships(deadline);

create table public.saved_internships (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references auth.users(id) on delete cascade,
  internship_id uuid not null references public.internships(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(student_id, internship_id)
);
create index saved_internships_student_idx on public.saved_internships(student_id);

create table public.applications (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references auth.users(id) on delete cascade,
  internship_id uuid not null references public.internships(id) on delete cascade,
  status public.application_status not null default 'applied',
  cover_note text,
  recruiter_feedback text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(student_id, internship_id)
);
create index applications_student_created_idx on public.applications(student_id, created_at desc);
create index applications_internship_idx on public.applications(internship_id);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- Create a profile at signup. Requested roles from browser metadata are intentionally
-- ignored: new users always start as students. Admin/recruiter role changes require
-- a trusted administrative process.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), 'student')
  on conflict (id) do nothing;
  return new;
end;
$$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.companies enable row level security;
alter table public.internships enable row level security;
alter table public.saved_internships enable row level security;
alter table public.applications enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

-- Profiles: users can only read/update their own row. Public portfolio data should
-- use a separate explicitly-public table/view in a later phase.
create policy "profiles_select_own" on public.profiles for select to authenticated using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles for insert to authenticated with check (auth.uid() = id and role = 'student');
create policy "profiles_update_own" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Prevent users from changing their own role through the client. A trusted server-side
-- administrative process (using a protected service credential) may perform role changes.
create or replace function public.prevent_self_role_change()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is not null and new.role is distinct from old.role then
    raise exception 'Role changes must be performed by an authorized administrator';
  end if;
  return new;
end;
$$;
create trigger profiles_prevent_self_role_change
  before update on public.profiles
  for each row execute procedure public.prevent_self_role_change();

-- Companies: owners manage their own company records; verified status is not editable by owner.
create policy "companies_select_owner" on public.companies for select to authenticated using (owner_id = auth.uid());
create policy "companies_insert_owner" on public.companies for insert to authenticated with check (owner_id = auth.uid() and verification_status = 'pending');
create policy "companies_update_owner" on public.companies for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid() and verification_status = 'pending');

-- Published internships are visible to authenticated users; recruiters can manage their own.
create policy "internships_read_published_or_owner" on public.internships for select to authenticated
using (status = 'published' or company_id = auth.uid());
create policy "internships_insert_owner" on public.internships for insert to authenticated
with check (company_id = auth.uid() and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'recruiter') and status = 'draft');
create policy "internships_update_owner_draft" on public.internships for update to authenticated
using (company_id = auth.uid()) with check (company_id = auth.uid() and status in ('draft','closed'));

-- Students can manage their own saved opportunities and applications.
create policy "saved_select_own" on public.saved_internships for select to authenticated using (student_id = auth.uid());
create policy "saved_insert_own" on public.saved_internships for insert to authenticated with check (student_id = auth.uid() and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'student'));
create policy "saved_delete_own" on public.saved_internships for delete to authenticated using (student_id = auth.uid());

create policy "applications_select_student_or_listing_owner" on public.applications for select to authenticated
using (student_id = auth.uid() or exists (select 1 from public.internships i where i.id = internship_id and i.company_id = auth.uid()));
create policy "applications_insert_own" on public.applications for insert to authenticated
with check (student_id = auth.uid() and status = 'applied' and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'student') and exists (select 1 from public.internships i where i.id = internship_id and i.status = 'published' and (i.deadline is null or i.deadline >= current_date)));
-- No student update policy: official status transitions must be implemented server-side.

create policy "notifications_select_own" on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "notifications_update_own" on public.notifications for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Audit log has no client-facing insert/select policy. Use a trusted server-side function.
