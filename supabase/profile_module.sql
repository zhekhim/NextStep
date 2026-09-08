create table if not exists public.certifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  issuer text not null default '',
  file_name text not null,
  file_url text not null,
  file_type text not null,
  issued_date timestamptz,
  created_at timestamptz not null default now()
);

alter table public.certifications enable row level security;

create policy "Users can view their certifications"
on public.certifications for select
using (auth.uid() = user_id);

create policy "Users can create their certifications"
on public.certifications for insert
with check (auth.uid() = user_id);

create policy "Users can delete their certifications"
on public.certifications for delete
using (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('certificates', 'certificates', true)
on conflict (id) do nothing;

create policy "Users can upload their certificates"
on storage.objects for insert
with check (bucket_id = 'certificates' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can delete their certificates"
on storage.objects for delete
using (bucket_id = 'certificates' and auth.uid()::text = (storage.foldername(name))[1]);
