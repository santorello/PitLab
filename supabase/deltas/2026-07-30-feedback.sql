-- Feedback utenti (2026-07-30)
-- Tabella per raccogliere feedback da chiunque (guest o autenticato).
-- L'alert email al titolare verrà agganciato in un secondo momento (Edge
-- Function + servizio email tipo Resend, su insert).

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  message text not null,
  contact_email text,
  user_id uuid references auth.users(id) on delete set null,
  page text,
  user_agent text,
  created_at timestamptz not null default now()
);

alter table public.feedback enable row level security;

drop policy if exists "anyone can submit feedback" on public.feedback;
create policy "anyone can submit feedback" on public.feedback
  for insert
  to anon, authenticated
  with check (
    char_length(message) between 1 and 5000
    and (user_id is null or user_id = (select auth.uid()))
  );

drop policy if exists "admins read feedback" on public.feedback;
create policy "admins read feedback" on public.feedback
  for select to authenticated
  using (is_admin());

create index if not exists feedback_created_at_idx on public.feedback (created_at desc);
