-- Сервис учёта занятий репетитора 

create table parents (
  parent_id integer generated always as identity primary key,
  name text not null,
  contact text not null
);

-- Оказываемые услуги
create table services (
  service_id integer generated always as identity primary key,
  name text not null unique
);

create table students (
  student_id integer generated always as identity primary key,
  name text not null,
  contact text,
  parent_id integer references parents(parent_id),
  service_id integer not null references services(service_id),
  cost_per_hour numeric(10,2) not null check (cost_per_hour > 0),
  is_active boolean not null default true
);

create table lessons (
  lesson_id integer generated always as identity primary key,
  student_id integer not null references students(student_id),
  start_at timestamptz not null,
  duration_min smallint not null check (duration_min between 60 and 120),
  status text check (status in ('Проведено','Перенесено','Отменено'))
  -- status is null занятие ещё не состоялось
);

-- Только состоявшиеся переносы заносятся в таблицу
create table reschedules (
  reschedule_id integer generated always as identity primary key,
  lesson_id integer not null references lessons(lesson_id),            -- id старого занятия
  new_lesson_id integer not null unique references lessons(lesson_id),     -- id нового занятия
  requested_by text not null check (requested_by in ('Ученик','Родитель','Репетитор')),
  proposed_start_at timestamptz not null,
  requested_at timestamptz not null default now()
);

-- Запись создаётся, когда занятию поставлен итоговый статус (у перенесённого записи нет).
-- У отменённого занятия amount — сумма, которую заплатили бы при проведении (по ней считаются потери).
create table payments (
  payment_id integer generated always as identity primary key,
  lesson_id  integer not null unique references lessons(lesson_id),
  amount numeric(10,2) not null check (amount >= 0),
  status text not null default 'Не оплачено' check (status in ('Не оплачено','Оплачено')),
  paid_at date,
  check ((status = 'Оплачено') = (paid_at is not null))
);
