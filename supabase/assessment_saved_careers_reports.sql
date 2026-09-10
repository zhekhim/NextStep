begin;

alter table public.career_shortlists
  add column if not exists status text not null default 'Interested';
alter table public.career_shortlists
  drop constraint if exists career_shortlists_status_check;
alter table public.career_shortlists
  add constraint career_shortlists_status_check
  check (status in ('Interested', 'Considering', 'Not Interested'));
grant select, insert, update, delete on public.career_shortlists to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('assessment-reports', 'assessment-reports', false, 10485760, array['application/pdf'])
on conflict (id) do nothing;

drop policy if exists "Upload own assessment reports" on storage.objects;
create policy "Upload own assessment reports" on storage.objects
for insert to authenticated
with check (bucket_id = 'assessment-reports' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Read own assessment reports" on storage.objects;
create policy "Read own assessment reports" on storage.objects
for select to authenticated
using (bucket_id = 'assessment-reports' and (storage.foldername(name))[1] = auth.uid()::text);

commit;
