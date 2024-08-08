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


select eu.name , '' as Salary from EmployeeUser eu where eu.status = 'ACTIVE' 
order by eu.name 

Update EmployeeUser
set status = 'DEACTIVE'

select * from EmployeeUser where name like 'Cody C%'

Select * from EmployeeUser where manager = null and status = 'ACTIVE'

Update Entry 
set rate = 11388 where id in (

    select en.id from Entry en 
    inner join TimeSheet ts on ts.id = en.time_sheet_id
    inner join EmployeeUser eu on eu.id = ts.emp_id
    inner join Project p on p.id = en.project_id
    where eu.name like 'Tony%'
    and p.name = 'YTC-001 - YTC Centre Renovation'
)


Update EmployeeUser
set manager=  'Matthew Dixon'
where name like 'Akbar%'

select datepart(month, en.start_time), SUM(en.duration * en.rate/100) as [Billable Amount] from Entry en
    inner join TimeSheet ts on ts.id = en.time_sheet_id
    inner join EmployeeUser eu on eu.id = ts.emp_id
    inner join Project p on p.id = en.project_id
    where ts.status = 'APPROVED' and DATEPART(year, Cast(en.start_time as Date )) = DatePart(YEAR, GETDATE())
    and p.code ! = 'YTC-001'
    group by datepart(month, en.start_time)
    order by datepart(month, en.start_time)


select p.code, SUM(en.duration * en.rate/100) as [Billable Amount] from Entry en
    inner join TimeSheet ts on ts.id = en.time_sheet_id
    inner join EmployeeUser eu on eu.id = ts.emp_id
    inner join Project p on p.id = en.project_id
    where ts.status = 'APPROVED'
    and datepart(month, en.start_time) = 1
    group by p.code
    order by p.code


select * from Entry en where en.start_time < '2024-02-28'


Select * from Project

select en.id, en.start_time, en.duration, en.[description] from Entry en 
    inner join TimeSheet ts on ts.id = en.time_sheet_id
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where eu.name like 'Julia C%' and ts.status = 'APPROVED' and ts.start_time = '2024-07-28'

order by ts.start_time

select * from Entry en where DatePart(day, en.start_time) != DATEPART(day, en.end_time)


Update Entry 
set start_time = DATEADD(hour, -6, start_time),
    end_time = DATEADD(hour, -6, end_time)
    where id in (
       select en.id from Entry en 
       where DatePart(day, en.start_time) != DATEPART(day, en.end_time)
    --    and en.duration >= 8
 
    )


Select DATEDIFF(day, ts.start_time, ts.end_time)  From TimeSheet ts where ts.id = '66ad5af7433b4b794e0c3c00'

Select * from Entry

Update TimeSheet 
set end_time = DATEADD(day, -1, end_time)
where id in (
    select id 
    from TimeSheet ts where DATEDIFF(day, ts.start_time, ts.end_time) = 7 and ts.[status] = 'APPROVED' and DATEPART(WEEKDAY, ts.end_time) = 1


)

select * from TimeSheet ts where DATEDIFF(day, ts.start_time, ts.end_time) = 7 and ts.[status] = 'APPROVED' and DATEPART(WEEKDAY, ts.end_time) = 1


select * from TimeSheet ts where DATEDIFF(day, ts.start_time, ts.end_time) = 6 and ts.status = 'APPROVED' and  DATEPART(WEEKDAY, ts.start_time) = 1




select * from LemEntry
select * from LemWorker

select * from lemEquipEntries
Select * from EquipEntry
select Count(id) From Project

Select ts.start_time, sum(en.duration) from ENtry en 
inner join TimeSheet ts on ts.id = en.time_sheet_id
inner join EmployeeUser eu on eu.id = ts.emp_id
where eu.name like 'Jaurie%' 
group by ts.start_time

and Cast(en.start_time as Date) = '2024-07-26' and ts.[status] = 'APPROVED'

delete Entry where id ='66a7691965149e021ec86013'

select * from LemSheet where description is not NULL

delete from Role

Select * from Role


select * from Client 
insert into Role(id, name) Values ('21232', 'Trucker')
insert into Equipment(id, name) Values ('919394', 'Truck')

select * from LemSheet

select * from Workspace
 
Select * from Equipment

Select * from EquipEntry

Drop table django_celery_beat_crontabschedule


SELECT DISTINCT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'EquipEntry';


INSERT INTO EquipEntry (_id, lemId, workspaceId, equipId, isUnitRate, qty)
VALUES (
    '74fd2c556808b001114bab4886163be403e07d8414c36',  -- _id
    '461fb94fbedf7499259ba46606260df60c6a00323e62c',  -- lemId
    '65c249bfedeea53ae19d7dad',                      -- workspaceId
    '919394',                                        -- equipId
    1,                                               -- isUnitRate (True in SQL is 1)
    9                                                -- qty
);

delete EquipEntry

Select * from EquipEntry

Delete Role

Select * from EntryDetails

select * from Workspace
select * from Role
Delete Equipment where name like 'Test%'
Delete Role where name like 'Test%'


select * from WorkerRateSheet
select * from LemSheet ls 
inner join Project p on p.id = ls.[projectId]

SELECT * FROM LemSheet