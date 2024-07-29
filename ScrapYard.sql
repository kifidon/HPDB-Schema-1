-- For Testing, debugging, and Misc. Sql Operations
-- Coments


select * from AttendanceApproved att where att.name like 'Adrienne Belle Alexis' and att.[date] = '2024-06-19'

SELECT att.name, att.Date, att.RegularHrs, att.Overtime, att.TotalHours , att.TimeOff, att.policy_name, att.Holiday  FROM AttendanceApproved att
            WHERE att.Date BETWEEN '2024-06-16' AND '2024-06-22'

            Union ALL

            Select tt.name,Null, Sum(tt.RegularHrs), Sum(tt.Overtime), Sum(tt.TotalHours), Sum(tt.TimeOff), 'Policy_name', 'Holiday' From AttendanceApproved tt
            WHERE [Date] BETWEEN '2024-06-16' AND '2024-06-22'
            Group By tt.name

            ORDER BY [name], Date DESC

            Select * from Lem


SELECT table_name
FROM information_schema.tables

Update Entry 
set rate = 9787 where id = '669e7af23b572d3bc436b70e'

Select * from LemSheet

--Test changes 
--- test data
INSERT INTO Role(id, [name] )
VALUES
    ('id', 1099),
    ('Name', Dixon);

--- test data
INSERT INTO Equipment (id, [name])
VALUES
    ('id', 1099),
    ('Name', Dixon);

--- test data
INSERT INTO EqpRateSheet (equipId, clientId,unitRate,dayRate)
VALUES
    ('iequipEd', 1099),
    ('clientId', Dixon),
    ('unitRate', 34.5),
    ('dayRate', 21);


DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += 'DROP TABLE ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + '; '
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE 'django_celery%';

EXEC sp_executesql @sql;


Select SUM(duration) from Entry

select * from TimeSheet where id ='6693d60e6270364ebb4a4265'

GO
Drop View IF Exists WeeklyHoursByEmployee 
go
Create View WeeklyHoursByEmployee as 
    Select  eu.name ,ts.start_time, SUM(en.duration) as Duration, ts.id From Entry en
    Inner join TimeSheet ts on ts.id = en.time_sheet_id
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where ts.status = 'APPROVED'
    group by ts.start_time, eu.name, ts.id

GO 


Select * from WeeklyHoursByEmployee where name like 'Don F%'

Delete Entry where time_sheet_id = '669e532d2502bb773e10ab5d'
Delete TimeSheet where id = '669e532d2502bb773e10ab5d'

Select * FROM WeeklyHoursByEmployee where name like '%Thomas R%' 
order by start_time DESC

select Sum(en.duration) From Entry en
where Cast(en.start_time as date) between '2024-07-07' and'2024-07-13' and en.time_sheet_id is NULL

Select * from TagsFor where id = '65fc6ca1285fff3064c4bce7' and entryID = '668cd9929921f74d748828ec'

delete Entry where id = '668cd9929921f74d748828ec'
delete Entry where id = '668cd98af37ecc46962b739d'
delete Entry where id = '668c56796270364ebbaffe11'

DELETE entry where time_sheet_id = '669e94c1411820109ff7c481'

SELECT*
FROM
    information_schema.table_constraints
WHERE
    table_name = 'TagsFor'
    AND constraint_type = 'FOREIGN KEY';

ALTER TABLE TagsFor
DROP CONSTRAINT FK__TagsFor__52668BB5;

ALTER TABLE TagsFor
ADD CONSTRAINT FK_TagsFor_Entry_New FOREIGN KEY (entryID, workspace_id)
REFERENCES Entry(id, workspace_id)
ON DELETE CASCADE;


select * from TagsFor where entryID = '668cd9929921f74d748828ec'

select DATEPART(WEEK, en.start_time), Sum(en.duration), sum(en.duration * en.rate/100) from Entry en 
inner join TimeSheet ts on ts.id = en.time_sheet_id
inner join EmployeeUser eu on eu.id = ts.emp_id
where eu.name like 'Timothy%' and datepart(month, en.start_time) = 7
group by DATEPART(week, en.start_time)



Select * from Entry en 
inner join TimeSheet ts on ts.id = en.time_sheet_id
inner join EmployeeUser eu on eu.id = ts.emp_id
where datepart(week, en.start_time) = 29
and eu.name like 'Timothy%'

Update Entry 
set rate = 6947 where id in ('669e668b3b572d3bc4325efc',
'669e668e2502bb773e14dc89',
'669e6691152dc819e40cc2b3',
'669e6692411820109fef7349',
'669e669376a3f818145bb4fc')


Update Entry 
Set rate = 0 
where rate = -1



Select 
    eu.name, 
    eu.role, 
    SUM(en.duration), 
    'hr' as [Unit Cost] ,
    Cast(en.rate/100 as Decimal(10,2)),
    cast(
        sum(en.duration * en.rate/100) as decimal(10,2)
    )
From Entry en
inner join Timesheet ts on ts.id = en.time_sheet_id
inner join EmployeeUser eu on eu.id = ts.emp_id
inner join Project p on p.id = en.project_id
where p.id = ''
    and en.billable = 1
    and ts.[status] = 'APPROVED'
group by eu.name, eu.role, cast(en.rate/100 as Decimal(10,2))


Select 
    eu.name, 
    eu.role, 
    SUM(en.duration), 
    'hr' as [Unit Cost] ,
    Cast('18.75' as Decimal(10,2)),
    cast(
        sum(en.duration * 18.75) as decimal(10,2)
    )
From Entry en
inner join Timesheet ts on ts.id = en.time_sheet_id
inner join EmployeeUser eu on eu.id = ts.emp_id
inner join Project p on p.id = en.project_id
where p.id = ''
    and eu.hasTruck = 1 
    and en.billable = 1
    and ts.[status] = 'APPROVED'
group by eu.name, eu.role, cast(en.rate/100 as Decimal(10,2))


select p.id from Project p 
where exists(
    select en.id from Entry en 
    where en.billable = 1 and 
    en.project_id = p.id 
    and Cast(en.start_time As Date) between '2024-06-24' and '2024-07-20' 
)



Select 
    eu.name, 
    eu.manager, 
    p.code, 
    p.title, 
    SUM(Case when en.billable = 1 then en.duration else 0 END) AS Billable, 
    SUM(Case when en.billable = 0 then en.duration Else 0 end ) as NonBillable,
From Entry en 
inner join Timesheet ts on ts.id = en.time_sheet_id 
inner join EmployeeUser eu on eu.id = ts.emp_id
Inner join Project p on p.id = en.project_id