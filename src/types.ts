export type Profile = {
  id: string
  full_name: string | null
  role: 'student' | 'recruiter' | 'admin'
  college: string | null
  degree: string | null
  graduation_year: number | null
  target_role: string | null
  github_url: string | null
  linkedin_url: string | null
  portfolio_url: string | null
}
export type Internship = {
  id: string
  company_id: string
  title: string
  company_name?: string
  description: string
  required_skills: string[]
  location: string | null
  work_mode: 'remote' | 'hybrid' | 'onsite'
  stipend_min: number | null
  stipend_max: number | null
  duration: string | null
  deadline: string | null
  status: 'draft' | 'published' | 'closed' | 'expired'
  created_at: string
}
