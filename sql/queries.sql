-- Долг каждого ученика
select students.name, SUM(payments.amount) as debt
from students 
join lessons on lessons.student_id=students.student_id 
join payments on payments.lesson_id=lessons.lesson_id 
where lessons.status='Проведено' and payments.status='Не оплачено'
group by students.student_id, students.name; 

-- Долг одного ученика 
select students.name, SUM(payments.amount) as debt
from students
join lessons on lessons.student_id = students.student_id
join payments on payments.lesson_id = lessons.lesson_id
where lessons.status = 'Проведено'
  and payments.status = 'Не оплачено'
  and students.student_id = 5
group by students.student_id, students.name;

-- Проведённые занятия ученика и их оплата
select lessons.start_at::date as lesson_date, lessons.duration_min,
       payments.amount, payments.status, payments.paid_at
from lessons
join payments on payments.lesson_id = lessons.lesson_id
where lessons.student_id = 5 and lessons.status = 'Проведено'
order by lessons.start_at;

-- История переносов: кто просил, с какого времени и на какое
select students.name,
       old_lesson.start_at as old_start,
       new_lesson.start_at as new_start,
       reschedules.requested_by,
       reschedules.requested_at
from reschedules
join lessons old_lesson on old_lesson.lesson_id = reschedules.lesson_id
join lessons new_lesson on new_lesson.lesson_id = reschedules.new_lesson_id
join students on students.student_id = old_lesson.student_id
order by reschedules.requested_at;

-- Расписание на 7 дней: ученик, дата и время начала, длительность
select students.name, lessons.start_at, lessons.duration_min
from students 
join lessons on lessons.student_id=students.student_id 
where lessons.start_at>='2026-10-19 00:00:00.000 + 0300' and lessons.start_at<'2026-10-26 00:00:00.000 + 0300' and lessons.status is NULL
order by lessons.start_at;

-- Ученики, которые отменяли занятие и количество отмен
select students.name, COUNT(*) as cancelled_lessons
from students
join lessons on lessons.student_id=students.student_id
where lessons.status='Отменено'
group by students.student_id,students.name
order by cancelled_lessons DESC;


-- Доход по месяцам
select date_trunc('month',paid_at)::date as month, SUM(amount) as revenue
from payments
where status='Оплачено'
group by date_trunc('month',paid_at)
order by month;


-- Родители, у которых больше одного ребенка
select parents.name, count(students.student_id) as children_count
from parents
join students on students.parent_id = parents.parent_id
group by parents.parent_id, parents.name
having count(students.student_id) > 1
order by children_count desc, parents.name;

-- Порядковый номер каждого проведённого занятия у ученика
select students.name, lessons.start_at::date as lesson_date, ROW_NUMBER() over (Partition by lessons.student_id order by lessons.start_at) as number_of_lesson
from students
join lessons on lessons.student_id=students.student_id
where lessons.status='Проведено'
order by students.name, number_of_lesson;

-- Пауза между последним и предпоследним занятием для каждого ученика
with lesson_history as (
    select student_id, start_at, row_number() over (Partition by student_id order by start_at desc) as rn,
        lag(start_at) over (Partition by student_id order by start_at) as prev_lesson
    from lessons
    where status = 'Проведено'
)
select
    students.name,
    lesson_history.start_at as last_lesson,
    lesson_history.prev_lesson,
    (lesson_history.start_at::date - lesson_history.prev_lesson::date) as gap_before_last
from lesson_history
join students on students.student_id = lesson_history.student_id
where lesson_history.rn = 1
order by students.name;

-- Ученики, у которых нет ни одного проведенного занятия
select students.name
from students 
where not exists (select 1 
				  from lessons 
				  where students.student_id=lessons.student_id and lessons.status='Проведено');

-- Ученики, у которых нет ни одного проведенного занятия (вторым способом)
select students.name 
from students 
left join lessons on lessons.student_id=students.student_id and lessons.status='Проведено'
where lessons.lesson_id is null;


-- Потери на отменах по месяцам
select date_trunc('month', lessons.start_at)::date as month, COUNT(*) as cancelled_lessons, SUM(payments.amount) as lost_revenue
from lessons
join payments on payments.lesson_id = lessons.lesson_id
where lessons.status = 'Отменено' and payments.status = 'Не оплачено'
group by date_trunc('month', lessons.start_at)
order by month;

-- Пересечения занятий по времени
select a.lesson_id as lesson_a, b.lesson_id as lesson_b, a.start_at as start_a, b.start_at as start_b
from lessons a
join lessons b on a.lesson_id < b.lesson_id
 and a.start_at < b.start_at + b.duration_min * interval '1 minute'
 and b.start_at < a.start_at + a.duration_min * interval '1 minute'
where a.status is distinct from 'Отменено' and a.status is distinct from 'Перенесено'
  and b.status is distinct from 'Отменено' and b.status is distinct from 'Перенесено';
