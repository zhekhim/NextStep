-- The app stores dimension totals calculated from assessment_questions.dimension.
-- No question-count columns are required.
begin;

alter table public.assessment_profiles
  drop constraint if exists realistic_score_check,
  drop constraint if exists investigative_score_check,
  drop constraint if exists artistic_score_check,
  drop constraint if exists social_score_check,
  drop constraint if exists enterprising_score_check,
  drop constraint if exists conventional_score_check;

alter table public.assessment_profiles
  add constraint realistic_score_check check (realistic between 1 and 240),
  add constraint investigative_score_check check (investigative between 1 and 240),
  add constraint artistic_score_check check (artistic between 1 and 240),
  add constraint social_score_check check (social between 1 and 240),
  add constraint enterprising_score_check check (enterprising between 1 and 240),
  add constraint conventional_score_check check (conventional between 1 and 240);

commit;
