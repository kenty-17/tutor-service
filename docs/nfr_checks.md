Проверка нефункциональных требований, описанных в 'docs/requirements.md'

NFR-1: Расписание на неделю выводится не дольше 2 секунд при 500 записях

В отдельной тестовой схеме nfr_test созданы таблицы и тестовые данные ('sql/schema.sql', 'sql/seed.sql'), добавлено ещё 500 занятий и выполнен запрос расписания с explain analyze. 

Добавление 500 занятий:

```sql
insert into lessons (student_id, start_at, duration_min)
select 1 + (n % 8),
    timestamptz '2026-11-01 08:00:00+03' + n * interval '2 hours',
    60
  from generate_series(1, 500) as n;
```

Запрос расписания на 7 дней с замером времени выполнения:

```sql
explain analyze
select students.name, lessons.start_at, lessons.duration_min
from students
join lessons on lessons.student_id = students.student_id
where lessons.status is null
  and lessons.start_at >= '2026-11-10 00:00:00+03'
  and lessons.start_at <  '2026-11-17 00:00:00+03'
order by lessons.start_at;
```

Результат выполнения:

| Показатель | Значение |
|---|---|
| Занятий в таблице 'lessons' | 542 |
| Занятий в выбранной неделе | 84 |
| Planning Time | 2,451 мс |
| Execution Time | 0,394 мс |

Время выполнения запроса составило 0,394 мс, требование выполняется.

NFR-2: Персональные данные хранятся в минимальном объёме (псевдоним и контакт)

Выведен список столбцов всех таблиц и проверено, нет ли среди них лишних персональных данных (фамилия, адрес и т.д.).

```sql
select table_name,
       string_agg(column_name, ', ' order by ordinal_position) as columns
from information_schema.columns
where table_schema = 'public'
group by table_name
order by table_name;
```

Результат:

| table_name | columns |
|---|---|
| lessons | lesson_id, student_id, start_at, duration_min, status |
| parents | parent_id, name, contact |
| payments | payment_id, lesson_id, amount, status, paid_at |
| reschedules | reschedule_id, lesson_id, new_lesson_id, requested_by, proposed_start_at, requested_at |
| services | service_id, name |
| students | student_id, name, contact, parent_id, service_id, cost_per_hour, is_active |

Персональные данные есть только в двух таблицах ('students' и 'parents') в виде 'name' (псевдоним) и 'contact' (вымышленный номер телефона). Других персональных данных нет, требование выполняется. 
