Результаты SQL-запросов

Запросы выполнены на вымышленных тестовых данных ('sql/seed.sql'). Исходный код всех запросов лежит в 'sql/queries.sql'.

1. Долг каждого ученика
```sql
select students.name, SUM(payments.amount) as debt
from students 
join lessons on lessons.student_id=students.student_id 
join payments on payments.lesson_id=lessons.lesson_id 
where lessons.status='Проведено' and payments.status='Не оплачено'
group by students.student_id, students.name; 
```

|name|debt|
|----|----|
|Ученик Д|2000.00|
|Ученик Е|1800.00|

2. Долг одного ученика 
```sql
select students.name, SUM(payments.amount) as debt
from students
join lessons on lessons.student_id = students.student_id
join payments on payments.lesson_id = lessons.lesson_id
where lessons.status = 'Проведено'
  and payments.status = 'Не оплачено'
  and students.student_id = 5
group by students.student_id, students.name;
```

|name|debt|
|----|----|
|Ученик Д|2000.00|


3. Проведённые занятия ученика и их оплата
```sql
select lessons.start_at::date as lesson_date, lessons.duration_min,
       payments.amount, payments.status, payments.paid_at
from lessons
join payments on payments.lesson_id = lessons.lesson_id
where lessons.student_id = 5 and lessons.status = 'Проведено'
order by lessons.start_at;
```

|lesson_date|duration_min|amount|status|paid_at|
|-----------|------------|------|------|-------|
|2026-09-29|60|2000.00|Оплачено|2026-09-28|
|2026-10-01|60|2000.00|Оплачено|2026-10-01|
|2026-10-05|60|2000.00|Оплачено|2026-10-05|
|2026-10-08|60|2000.00|Не оплачено||
|2026-10-12|60|2000.00|Оплачено|2026-10-12|
|2026-10-15|60|2000.00|Оплачено|2026-10-15|

4. История переносов: кто просил, с какого времени и на какое
```sql
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
```

|name|old_start|new_start|requested_by|requested_at|
|----|---------|---------|------------|------------|
|Ученик Д|2026-09-28 18:00:00.000 +0300|2026-09-29 19:00:00.000 +0300|Родитель|2026-09-28 12:00:00.000 +0300|

5. Расписание на 7 дней: ученик, дата и время начала, длительность
```sql
select students.name, lessons.start_at, lessons.duration_min
from students 
join lessons on lessons.student_id=students.student_id 
where lessons.start_at>='2026-10-19 00:00:00.000 + 0300' and lessons.start_at<'2026-10-26 00:00:00.000 + 0300' and lessons.status is NULL
order by lessons.start_at;
```

|name|start_at|duration_min|
|----|--------|------------|
|Ученик Д|2026-10-19 18:00:00.000 +0300|60|
|Ученик В|2026-10-19 19:00:00.000 +0300|60|
|Ученик А|2026-10-20 16:00:00.000 +0300|60|
|Ученик Е|2026-10-20 18:00:00.000 +0300|60|
|Ученик Б|2026-10-21 16:30:00.000 +0300|120|
|Ученик Г|2026-10-21 19:00:00.000 +0300|60|
|Ученик Д|2026-10-22 18:00:00.000 +0300|60|
|Ученик А|2026-10-23 16:00:00.000 +0300|90|
|Ученик Е|2026-10-23 17:30:00.000 +0300|60|

6. Ученики, которые отменяли занятие и количество отмен
```sql
select students.name, COUNT(*) as cancelled_lessons
from students
join lessons on lessons.student_id=students.student_id
where lessons.status='Отменено'
group by students.student_id,students.name
order by cancelled_lessons DESC;
```

|name|cancelled_lessons|
|----|-----------------|
|Ученик А|3|
|Ученик В|2|
|Ученик Ж|2|
|Ученик Б|1|
|Ученик Г|1|
|Ученик Д|1|

7. Доход по месяцам
```sql
select date_trunc('month',paid_at)::date as month, SUM(amount) as revenue
from payments
where status='Оплачено'
group by date_trunc('month',paid_at)
order by month;
```

|month|revenue|
|-----|-------|
|2026-09-01|15150.00|
|2026-10-01|28150.00|

8. Родители, у которых больше одного ребенка
```sql
select parents.name, count(students.student_id) as children_count
from parents
join students on students.parent_id = parents.parent_id
group by parents.parent_id, parents.name
having count(students.student_id) > 1
order by children_count desc, parents.name;
```

|name|children_count|
|----|--------------|
|Родитель Г|3|
|Родитель Б|2|

9. Порядковый номер каждого проведённого занятия у ученика
```sql
select students.name, lessons.start_at::date as lesson_date, ROW_NUMBER() over (Partition by lessons.student_id order by lessons.start_at) as number_of_lesson
from students
join lessons on lessons.student_id=students.student_id
where lessons.status='Проведено'
order by students.name, number_of_lesson;
```

|name|lesson_date|number_of_lesson|
|----|-----------|----------------|
|Ученик А|2026-09-15|1|
|Ученик А|2026-09-18|2|
|Ученик А|2026-10-06|3|
|Ученик А|2026-10-09|4|
|Ученик Б|2026-09-30|1|
|Ученик Б|2026-10-07|2|
|Ученик Б|2026-10-14|3|
|Ученик В|2026-09-21|1|
|Ученик Г|2026-09-23|1|
|Ученик Г|2026-09-30|2|
|Ученик Г|2026-10-14|3|
|Ученик Д|2026-09-29|1|
|Ученик Д|2026-10-01|2|
|Ученик Д|2026-10-05|3|
|Ученик Д|2026-10-08|4|
|Ученик Д|2026-10-12|5|
|Ученик Д|2026-10-15|6|
|Ученик Е|2026-10-02|1|
|Ученик Е|2026-10-06|2|
|Ученик Е|2026-10-09|3|
|Ученик Е|2026-10-13|4|
|Ученик Е|2026-10-16|5|

10. Пауза между последним и предпоследним занятием для каждого ученика
```sql
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
```

|name|last_lesson|prev_lesson|gap_before_last|
|----|-----------|-----------|---------------|
|Ученик А|2026-10-09 16:00:00.000 +0300|2026-10-06 16:00:00.000 +0300|3|
|Ученик Б|2026-10-14 16:30:00.000 +0300|2026-10-07 16:30:00.000 +0300|7|
|Ученик В|2026-09-21 19:00:00.000 +0300|||
|Ученик Г|2026-10-14 19:00:00.000 +0300|2026-09-30 19:00:00.000 +0300|14|
|Ученик Д|2026-10-15 18:00:00.000 +0300|2026-10-12 18:00:00.000 +0300|3|
|Ученик Е|2026-10-16 17:30:00.000 +0300|2026-10-13 18:00:00.000 +0300|3|

11. Ученики, у которых нет ни одного проведенного занятия
```sql
select students.name
from students 
where not exists (select 1 
				  from lessons 
				  where students.student_id=lessons.student_id and lessons.status='Проведено');
```

|name|
|----|
|Ученик Ж|
|Ученик З|

12. Ученики, у которых нет ни одного проведенного занятия (вторым способом)
```sql
select students.name 
from students 
left join lessons on lessons.student_id=students.student_id and lessons.status='Проведено'
where lessons.lesson_id is null;
```

|name|
|----|
|Ученик Ж|
|Ученик З|

13. Потери на отменах по месяцам
```sql
select date_trunc('month', lessons.start_at)::date as month, COUNT(*) as cancelled_lessons, SUM(payments.amount) as lost_revenue
from lessons
join payments on payments.lesson_id = lessons.lesson_id
where lessons.status = 'Отменено' and payments.status = 'Не оплачено'
group by date_trunc('month', lessons.start_at)
order by month;
```

|month|cancelled_lessons|lost_revenue|
|-----|-----------------|------------|
|2026-09-01|2|5600.00|
|2026-10-01|8|15200.00|

14. Пересечения занятий по времени
```sql
select a.lesson_id as lesson_a, b.lesson_id as lesson_b, a.start_at as start_a, b.start_at as start_b
from lessons a
join lessons b on a.lesson_id < b.lesson_id
 and a.start_at < b.start_at + b.duration_min * interval '1 minute'
 and b.start_at < a.start_at + a.duration_min * interval '1 minute'
where a.status is distinct from 'Отменено' and a.status is distinct from 'Перенесено'
  and b.status is distinct from 'Отменено' and b.status is distinct from 'Перенесено';
```

Запрос не вернул ни одной строки: пересечений занятий по времени нет.