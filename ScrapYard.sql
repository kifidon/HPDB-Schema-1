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










