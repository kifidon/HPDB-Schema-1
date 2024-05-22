-- Time Sheety Qurary 
/*
    DROP VIEW IF EXISTS MonthlyBillable;
    DROP VIEW IF EXISTS AttendanceApproved;
    DROP VIEW IF EXISTS TimeSheetOperations;
    DROP VIEW IF EXISTS BankedTimeOffPolicy;
    DROP VIEW IF EXISTS BankedHRS;
*/ 
-- only include oT if missing banked tag
drop view TimeSheetOperations
go
CREATE VIEW TimeSheetOperations as (
    SELECT 
        eu.name,
        eu.email,
        CAST(en.start_time AS DATE) AS [date],
        DATENAME(DW, CAST(en.start_time as DATE )) as [day],
        pj.name as ProjectCode,
        pj.code,
        en.duration,
        en.description
    FROM 
        [Entry] en
    INNER JOIN 
        TimeSheet ts ON ts.id = en.time_sheet_id
    INNER JOIN 
        EmployeeUser eu ON eu.id = ts.emp_id 
    INNER JOIN 
        Project pj ON pj.id = en.project_id and pj.workspace_id = en.workspace_id
    WHERE 
        ts.[status] = 'APPROVED'  and eu.[status] = 'ACTIVE'
) 

go
drop view MonthlyBillable
go
CREATE VIEW MonthlyBillable as (

    SELECT  
        Null as [Number],
        eu.name as [Name], 
        NULL AS [Supplier],
        CAST(SUM(en.duration) AS DECIMAL(10, 2)) AS QTY,
        'hr' AS Unit,
        en.rate/100 AS [Unit Cost],
        CAST(
             SUM(en.duration) * en.rate/100 AS DECIMAL(10, 2)  -- * en.rate
        )AS Amount,
        en.start_time,
        en.project_id
    FROM TimeSheet ts 
        INNER JOIN EmployeeUser eu on eu.id = ts.emp_id 
        INNER JOIN [Entry] en ON en.time_sheet_id = ts.id 
        INNER JOIN Project pj on pj.id = en.project_id and pj.workspace_id = en.workspace_id
        INNER JOIN Client cl on cl.id = pj.client_id and pj.workspace_id = cl.workspace_id
        WHERE ts.[status] = 'APPROVED'
        -- and en.start_time between '2024-02-01' and '2024-02-29' and eu.name like '%Rod%'
        GROUP BY
            pj.code, 
            en.rate,
            en.start_time,
            en.project_id,
            eu.name

    UNION ALL

    SELECT 
        pj.code as [Number],
        pj.title AS [Name],
        cl.name AS [Supplier],
        1 AS QTY,
        'ls' AS Unit,
        CAST(
            SUM(en.duration * en.rate/100) AS DECIMAL(10, 2) -- * en.rate)
        ) AS UnitCost,
        NULL AS Amount,
        CONCAT(
            DATEPART(YEAR, DATEADD(DAY, -24, en.start_time)),
            '-',
            DATEPART(MONTH, DATEADD(DAY, -24, en.start_time)),
            '-25'
        ) AS start_time,
        en.project_id     
    FROM TimeSheet ts 
        INNER JOIN EmployeeUser eu on eu.id = ts.emp_id 
        INNER JOIN [Entry] en ON en.time_sheet_id = ts.id 
        INNER JOIN Project pj on pj.id = en.project_id and pj.workspace_id = en.workspace_id
        INNER JOIN Client cl on cl.id = pj.client_id and pj.workspace_id = cl.workspace_id
        WHERE ts.[status] = 'APPROVED' 
        GROUP BY 
            pj.code,
            pj.title, 
            cl.name,
            en.project_id,
            CONCAT(
                DATEPART(YEAR, DATEADD(DAY, -24, en.start_time)),
                '-',
                DATEPART(MONTH, DATEADD(DAY, -24, en.start_time)),
                '-25'
            )
)
Go 
drop view AttendanceApproved
go
CREATE VIEW AttendanceApproved AS
    with totalHrsPerDay as (
        select 
            Cast(en.start_time as date) as [Date] ,
            eu.name,
            eu.email,
            ROUND(SUM(en.duration) * 4, 0) / 4 AS [TotalHours],
            eu.id
        From 
            [Entry] en
        inner join 
            TimeSheet ts on ts.id = en.time_sheet_id and Cast(en.start_time as date) between ts.start_time and ts.end_time
        inner join 
            EmployeeUser eu on eu.id = ts.emp_id
        where ts.[status] = 'APPROVED' 
        group by 
            Cast(en.start_time as date),
            eu.name,
            eu.email,
            eu.id    
    ),
    TimeOffReasons as (
        select 
            
            d.date,
            eu.name,
            eu.email,
            eu.id,
            CASE 
                WHEN h.[date] IS NULL and d.dayOfWeek NOT IN (1, 7) THEN CAST(tr.paidTimeOff / tr.duration AS DECIMAL(10,2))
                ELSE 0
            END AS TimeOff,
            tp.policy_name,
            case when h.name is not Null then h.name
                else 'N/A'
            end as Holiday
            
        from 
            TimeOffRequests tr 
        inner  join 
            TimeOffPolicies tp on tp.id = tr.pID
        inner join 
            Calendar d on d.[date] between Cast(tr.startDate as Date) and Cast(tr.end_date as Date)
        inner join
            EmployeeUser eu on eu.id = tr.eID 
        left join 
            Holidays h on h.[date] = d.[date]
        where 
           d.dayOfWeek not in (1,7) 
    )
    SELECT 
        
        COALESCE(th.name, tr.name) AS [name],
        COALESCE(th.email, tr.email) AS email,
        COALESCE(th.[Date], tr.[Date]) AS [date],
        case 
            when d.dayOfWeek = 1 then 'Sunday'
            when d.dayOfWeek = 2 then 'Monday'
            when d.dayOfWeek = 3 then 'Tuesday'
            when d.dayOfWeek = 4 then 'Wednesday'
            when d.dayOfWeek = 5 then 'Thursday'
            when d.dayOfWeek = 6 then 'Friday'
            when d.dayOfWeek = 7 then 'Saturday'
        end as DayOfWeek,
        CASE    
            WHEN COALESCE(th.TotalHours, 0) <= 8 THEN COALESCE(th.TotalHours, 0)
            ELSE 8
        END AS RegularHrs,
        CASE 
            WHEN COALESCE(th.TotalHours, 0) > 8 THEN th.TotalHours - 8
            ELSE 0
        END AS Overtime,
        case 
            when th.TotalHours is null then 0
            else th.TotalHours
        end as TotalHours,
        CASE 
            WHEN tr.TimeOff  is null THEN 0
            ELSE tr.TimeOff
        END AS TimeOff,
        case 
            when tr.policy_name is null then  'N/A'
            else tr.policy_name
        end as policy_name,
        case 
            when tr.Holiday is Null then 'N/A' 
            else tr.Holiday
        end as Holiday 
    FROM
        totalHrsPerDay th
    FULL OUTER JOIN 
        TimeOffReasons tr ON th.name = tr.name 
                        AND th.email = tr.email 
                        AND th.[Date] = tr.[Date]
    inner join 
        Calendar d on d.[date] IN (th.[Date], tr.date)
    inner join GroupMembership gm on gm.user_id = th.id
    inner join UserGroups ug on ug.id = gm.group_id
    where ug.id = '662692095d98964711869706'
        
go
drop view BankedHRS
go
Create VIEW BankedHRS as 
    with BankedDays as ( -- all the days with an at least one entry that has a banked tag
        select
        distinct
            eu.id as empID,
            eu.name,
            Cast(en.start_time as Date) as sDate
        from EmployeeUser eu 
        Inner join Timesheet ts on ts.emp_id = eu.id 
        Inner join [Entry] en on en.time_sheet_id = ts.id and Cast(en.start_time As Date) between ts.start_time and ts.end_time
        Inner join TagsFor tf on tf.entryID = en.id and tf.name = 'BANKED' and tf.workspace_id = en.workspace_id
        where ts.status = 'APPROVED' and eu.status = 'ACTIVE'
    ),
    TotalHrsOnBankedDay as ( -- total hours worked on a banked day 
        select 
            eu.id,
            bd.sDate,
            sum(en.duration) as total
        from EmployeeUser eu 
        Inner join Timesheet ts on ts.emp_id = eu.id 
        Inner join [Entry] en on en.time_sheet_id = ts.id and Cast(en.start_time As Date) between ts.start_time and ts.end_time
        Inner join BankedDays bd on bd.empID = eu.id and bd.sDate = Cast(en.start_time as Date)
        where ts.status = 'APPROVED' and eu.status = 'ACTIVE'
        group by 
            eu.id,
            bd.sDate
    )
    select  -- historical log of all banked hours (used or unused )
        bd.empID as empID,
        bd.name as empName,
        tbd.sDate as accuredOn,
        case
            -- more than 8 hours on a weekday 
            when tbd.total >= 8 and not DATEPART( dw, tbd.sDate) IN (1,7) then tbd.total - 8 
            -- weekend 
            When  DATEPART(dw, tbd.sDate) IN (1,7)  then tbd.total
            else 0 
        end As BankedHours 
    from TotalHrsOnBankedDay tbd
    Inner join BankedDays bd on tbd.sDate = bd.sDate and bd.empID = tbd.id
    where tbd.total > 8 or DATEPART( dw, tbd.sDate) IN (1,7)

GO
drop view BankedTimeOffPolicy
go
CREATE VIEW BankedTimeOffPolicy AS 
    with TimeOffBanked as ( -- historical log of all used banked hours 
        select 
            eu.id as empID,
            tp.id as polID,
            Sum(tr.paidTimeOff) as paidTimeOff
        from 
            TimeOffPolicies tp 
        Inner join 
            TimeOffRequests tr on tp.id = tr.pID
        Left join
            EmployeeUser eu on eu.id = tr.eID 
        where 
            tp.policy_name = 'Banked Time Off' and tr.[status] IN ('PENDING', 'APPROVED') 
            and eu.status = 'ACTIVE'
        group by 
            eu.id,
            tp.id
    )
    select -- Stores for each person the number of banked hours they have accured and used, and the difference between them being the ballance 
        eu.id as id,
        coalesce(tb.polID, '65fc91ca17e548286f7bc026') as polID,
        coalesce(SUM(bh.BankedHours), 0) as [All Time Banked Hours],
        coalesce(tb.paidTimeOff, 0) as [All Time Used Banked Hours],
        coalesce(SUM(bh.BankedHours), 0) - coalesce((tb.paidTimeOff), 0) as balance
    From EmployeeUser eu 
    Left Join BankedHRS bh on bh.empID = eu.id
    left join TimeOffBanked tb on tb.empID = eu.id
    group by
        eu.id,
        tb.polID,
        tb.paidTimeOff
    
go
drop view TotalApprovedTimePerUser
go 
create view TotalApprovedTimePerUser as (
    select  eu.name , Sum(en.duration) as ApprovedTime, eu.id from Entry en
    inner join TimeSheet ts on ts.id = en.time_sheet_id
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where ts.status = 'APPROVED' and eu.status = 'ACTIVE'
    group by eu.name, eu.id)

go 

create view ExpenseClaim as 
    with cteExpenses as ( -- Expenses For which an altered Unit Cost on milage is to be applied 
        select 
            ex.id,
            ex.userId,
            ex.quantity,
            62 as UnitCost
        from 
            Expense ex
        inner join 
            ExpenseCategory ec on ec.id = ex.categoryId
        where 
            ec.name like 'Kilometers' and
            EXISTS (
                select 1 from Expense exI
                where 
                    exI.userId = ex.userId 
                    and exI.date between DateFromParts(Year(ex.date),1,1) and ex.[date]
                    AND exI.id != ex.id 
                group by 
                    exI.userId 
                having 
                    SUM(exI.quantity) > 5000
            )
    )
    select
        ex.id,
        ex.date as [Date],
        eu.name as [Name],
        ec.name as [Expense Type],
        ex.notes as [Description],
        case 
            when ec.hasUnitPrice = 1 then ex.quantity else 1
            end as [Quantity],
        case 
            when ec.hasUnitPrice = 1 then Cast(Round(COALESCE(cex.UnitCost, ec.priceInCents)/100, 2) as Decimal(10,2)) else 0
            end as [Unit Price],
        p.name as [Project],
        CAST(Round( cast(ex.total as real)/(105) ,5) as Decimal(10,2)) as [Sub-Total],
        Cast(round((cast(ex.total as real)/(105) )* 0.05, 5) as Decimal(10,2)) as [GST],
        Cast(ROUND( cast(ex.total as real)/(100) ,3) as Decimal(10,2)) as [Total]
    From
        Expense ex
    left Join cteExpenses cex on cex.id = ex.id
    inner join EmployeeUser eu on eu.id = ex.userId
    Inner join Project p on p.id = ex.projectId
    inner join ExpenseCategory ec on ec.id = ex.categoryId

go
drop VIEW PendingTimesheets
go
CREATE view PendingTimesheets as 
    select eu.name, ts.start_time, ts.id from TimeSheet ts 
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where ts.[status] = 'PENDING'

go 
DROP view MissingTimesheets 
go
CREATE View MissingTimesheets as 
    select eu.name, d.date as WeekStart from EmployeeUser eu
    cross Join Calendar d 
    where not exists( -- exists no record of time entry for a given date 
        select 1 from TimeSheet ts1 
        where ts1.emp_id = eu.id  and( 
            d.date BETWEEN 
                dateadd(day, 1-DATEPART(weekday, ts1.start_time), ts1.start_time) -- ensures Sunday
                and dateadd(day, 7 - DATEPART(WEEKDAY, ts1.end_time), ts1.end_time) -- ensures saturday
            ) -- may cause a logical error if entry is on a sunday, mapped to a timesheet that has start-end (Monday-Sunday)
        ) 
        -- filters date after the sunday that employee started 
        and DATEADD(day, 1 - DATEPART(weekday,eu.start_date) , eu.start_date )<= d.[date] and 
        -- Filters between current date and clockify records start date (2023-12-31),
        d.date between  '2023-12-31' and Cast(dateadd(day, 1-DatePart(weekday,GETDATE()), GETDATE()) as date)
        -- Select the start date of said week,
        and d.dayOfWeek = 1 and eu.name not like 'Ahmad%'
        and eu.status = 'ACTIVE' 

    EXCEPT -- doesn't include users who have no timesheet but had booked time off during this week
    
    select Distinct ap.name, dateadd( day, 1- datepart(weekday,ap.date),ap.date) from AttendanceApproved ap 
    where ap.policy_name != 'N/A'

go 
drop view MalformedTimesheets
go 
Create View MalformedTimesheets as (
    select eu.name, ts.start_time, ts.[status], ts.id From TimeSheet ts
    Inner join EmployeeUser eu on eu.id = ts.emp_id
    where not exists (
        select 1 from Entry en where en.time_sheet_id = ts.id
    ) and not exists(
        Select 1 From Expense ex where ex.timesheetId = ts.id
    )
    and ts.status = 'APPROVED'
)

go



/*
    with cte_totalHrs as ( -- total number of hours per salary or hourly employee
        select eu.id, Sum(en.duration) as [hours], ug.name as [uGroup] From EmployeeUser eu 
        Inner join TimeSheet ts on ts.emp_id = eu.id
        Inner Join Entry en on en.time_sheet_id = ts.id
        inner join GroupMembership gm on gm.user_id = eu.id
        inner join UserGroups ug on ug.id = gm.group_id
        Where DATEPART(year, CAST(en.start_time as date)) = DATEPART(year, GETDATE()) 
            and ug.name in ('Salary', 'Hourly', 'Contractors')
        group by eu.id, ug.name
    ),
    AccruedVacation as ( -- Accured Hours, Max is 160 
        select 
            th.id,
            case 
                when th.[hours] * 0.0767 > 160 then 160
                else CAST(th.[hours] * 0.0767 as decimal(10,2))
            end as VacationAccrued,
            th.uGroup
        from cte_totalHrs th
    ),
    TotalTimeOff as (
        select 
            eu.id,
            case 
                when tp.id is Null then 0
                else SUM(tr.paidTimeOff) 
            end as timeOff,
            tp.id as polID, 
            tp.policy_name
        from EmployeeUser eu 
        Left Join TimeOffRequests tr on tr.eID = eu.id
        left join TimeOffPolicies tp on tp.id = tr.pID
        group by 
            eu.id,
            tp.id, 
            tp.policy_name
        having tp.id is Null or tp.id in (
            select tp1.id from TimeOffPolicies tp1
            where tp1.policy_name in ('Vacation - Salary', 'Vacation - Hourly (Unpaid)', 'Vacation - Contractor')
        )
    )
    select * from EmployeeUser eu 
    where id not in (select id from TotalTimeOff)

    go

    select count(*) from EmployeeUser
    select * from TimeOffRequests
    select * from UserGroups
*/
-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER TRIGGER SetNullValuesToNegative1
    ON Timesheet
    AFTER INSERT, UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;

        UPDATE Timesheet
        SET
            approved_time = CASE WHEN inserted.approved_time IS NULL THEN -1 ELSE inserted.approved_time END,
            billable_time = CASE WHEN inserted.billable_time IS NULL THEN -1 ELSE inserted.billable_time END,
            billable_amount = CASE WHEN inserted.billable_amount IS NULL THEN -1 ELSE inserted.billable_amount END,
            cost_amount = CASE WHEN inserted.cost_amount IS NULL THEN -1 ELSE inserted.cost_amount END,
            expense_total = CASE WHEN inserted.expense_total IS NULL THEN -1 ELSE inserted.expense_total END
        FROM
            Timesheet
        INNER JOIN
            inserted ON Timesheet.id = inserted.id;
    END;
    Go

CREATE OR ALTER TRIGGER RoundDurationToNearest15Min
    ON Entry
    AFTER INSERT, UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;

        UPDATE Entry
        SET duration = ROUND(duration * 4, 0) / 4; -- Round to the nearest 15 minutes (0.25 hours)

    END;
    go
----------------------------------------------------------------------------------------------------------------------------------------------------
/*
    select * from EmployeeUser where name like 'Molar %'

    update EmployeeUser
    set start_date = '2024-04-8'
    where name like 'Molar %'

    select * From timesheet ts
    Inner join Entry en on en.time_sheet_id = ts.id
    where ts.id = '662265fe38907a5b7a86b090'


    select eu.name, ts.status, ts.start_time from EmployeeUser eu 
    inner join Timesheet ts on ts.emp_id = eu.id 
    --inner join Entry en on en.time_sheet_id = ts.id
    where ts.id = '6622c227c2a4fb3be95ce268'

    select en.id From Entry en
    LEFT join TimeSheet ts on ts.id = en.time_sheet_id
    where ts.[status] = 'PENDING'

    select eu.name  from Timesheet ts  
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where ts.status = 'PENDING'

    select ts. id, ts.status, ts.start_time From TimeSheet ts 
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where eu.name like 'Jason S%'

    select en.id from Entry en 
    inner join TimeSheet ts on ts.id = en.time_sheet_id
    where ts.id = '662661ab258963254d613dd8'

    select * from TimeSheet ts where id ='66268448b79fef6dfdf005f6'

    UPDATE Entry
    SET duration = ROUND(duration / 0.25, 0) * 0.25;

    select ts.start_time, ts.[status] from TimeSheet ts 
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where eu.name like 'Janessa%' 
    order by ts.start_time 

    select sum(ApprovedTime) from total


    select * from AttendanceApproved where name like 'Behrouz%'
    select * from EmployeeUser where id = '661451116b82d163d3d322d8'

    select eu.name from EmployeeUser eu 
    where not exists (
        select 1 from TimeSheet ts 
        inner join Entry en on en.time_sheet_id = ts.id 
        where eu.id = ts.emp_id and en.start_time < '2024-02-24'
    ) and eu.start_date < '2024-02-24'

    select * from TimeSheet ts
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where ts.id = '6622e7845d98964711526890'

    select ts.id, ts.start_time, ts.[status] from TimeSheet ts 
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where eu.name like 'Thulani%'

    select * from Entry where time_sheet_id = '6627d54159257a7eb47a0c0c'

    Select * From Project where id ='66292c80728215543c905e31'

    select BankedHours, accuredOn From BankedHRS where empName like 'Rodney%' 
    and accuredOn between '2024-03-17' and '2024-03-23' order by accuredOn

    select* from  BankedTimeOffPolicy where id = '65dcdd57ea15ab53ab7b14e2'

    select * from TimeOffRequests tr where tr.eID = '65c253aeffbbb676c5e05ff1'

    select * from TimeOffPolicies where id = '65fc91ca17e548286f7bc026'  

    select * from BankedTimeOffPolicy where id ='65c253aeffbbb676c5e05ff1'

    select count(*) from TimeOffRequests where status = 'APPROVED' 

    select * from TimeSheet ts 
    inner join EmployeeUser eu on eu.id = ts.emp_id 
    inner join Entry en on en.time_sheet_id = ts.id
    where eu.name like 'Shawna%' and cast(en.start_time as date) = '2024-03-01'

    Select 
                    p.id, p.code
                from Project p
                where exists (
                    select 1 From Entry en 
                    inner join TimeSheet ts on ts.id = en.time_sheet_id
                    where ts.status = 'APPROVED'
                )


    Select table_name from INFORMATION_SCHEMA.TABLES order by table_name

    Select 
                    DISTINCT en.project_id, p.code
                FROM TimeSheet TS
                INNER JOIN Entry en ON en.time_sheet_id = ts.id
                INNER JOIN Project p on p.id = en.project_id
                WHERE ts.start_time BETWEEN '2024-03-25' AND '2024-04-24'
                    AND ts.[status] = 'APPROVED'

    DROP view if exists LemEqpTable;
    DROP TABLE if exists LemEqpTable;
    DROP TABLE if exists clockify_workspace;
    DROP TABLE if exists clockify_groupmembership;
    DROP TABLE if exists clockify_timesheet;
    DROP TABLE if exists clockify_groupmembership;
    DROP TABLE if exists clockify_timeoffpolicies;
    DROP TABLE if exists clockify_timeoffrequests;
    DROP TABLE if exists clockify_usergroups;
    DROP TABLE if exists clockify_workspace;

    select * from TimeSheet where id = '6638f1354d9c8438ec79bf0a'

    select * from Entry where time_sheet_id ='6638f1354d9c8438ec79bf0a'

    select * from MonthlyBillable mb 
    inner join Project p on p.id = mb.project_id
    where mb.Name like 'Luke%' and p.code like 'A23-004'

    select ts.id,  ts.start_time, sum(en.duration) from TimeSheet ts
    Inner join EmployeeUser eu on eu.id = ts.emp_id
    Inner  join Entry en on en.time_sheet_id = ts.id
    and  eu.name like 'Margar%' and ts.[status] = 'APPROVED'
    group by ts.start_time, ts.id
    order by ts.start_time

    select start_time from TimeSheet ts
    Inner join EmployeeUser eu on eu.id = ts.emp_id
    and  eu.name like 'Marg%' and ts.[status] = 'APPROVED'
    order by ts.start_time

    Select * From Entry where time_sheet_id = '66390fd64d9c8438ec7ee657'
    Select * From TimeSheet where id = '663913ded846bb43224547de'

    delete from Entry where time_sheet_id = '6638f7d4fdaf936e90962a45'
    delete from TimeSheet where id = '6638f1354d9c8438ec79bf0a' 


    select ts.start_time, SUM(en.duration) from TimeSheet ts 
    inner join EmployeeUser eu on eu.id = ts.emp_id
    inner join Entry en on en.time_sheet_id = ts.id
    where eu.name like 'Mohamad%' and ts.[status] = 'APPROVED'
    group by ts.start_time
    order by ts.start_time


    select * from Client

    DECLARE @startDate DATE = '2023-01-01';

            DECLARE @endDate DATE = '2023-12-31';

            -- Loop through each day within the specified range and insert into the Calendar table
            DECLARE @currentDate DATE = @startDate;
            WHILE @currentDate <= @endDate
            BEGIN
                INSERT INTO Calendar ([date], dayOfWeek, [month], [year])
                VALUES (
                    @currentDate,
                    DATEPART(WEEKDAY, @currentDate),  -- Day of the week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
                    DATEPART(MONTH, @currentDate),    -- Month (1-12)
                    DATEPART(YEAR, @currentDate)      -- Year
                );
                
                -- Increment the current date by one day
                SET @currentDate = DATEADD(DAY, 1, @currentDate);
            END;

    with totalHours as (
        select eu.name, Cast(en.start_time as Date) as date, sum(duration) as duration from Entry en
        Inner Join TimeSheet ts on ts.id = en.time_sheet_id
        Inner join EmployeeUser eu on eu.id = ts.emp_id 
        where ts.status = 'APPROVED' and eu.name like 'Eric Sc%'
        group by eu.name, Cast(en.start_time as Date)
    )
    Select name, [date], 
        case 
        when duration >8 then duration - 0.5
        else duration 
        end as WorkedHrs,
        duration as totalHours 
    From  totalHours

    select * from Expense

    select * from timesheet where id = '663517e6fdaf936e90602151'

    select ts.id from TimeSheet ts 
    inner join Entry en on en.time_sheet_id = ts.id 
    where en.id = '6633ec265e8ef3683ba989dd'

    select * from Entry where time_sheet_id = '663d0e8f2021485a003aa44d'
    delete TimeSheet where id = '66421d08ec65c226ff7b30f7'

    select * from Expense

    Update Expense set quantity = 1

    select ts.start_time , sum(en.duration) from TimeSheet ts 
    inner join EmployeeUser eu on eu.id = ts.emp_id
    inner join Entry en on en.time_sheet_id = ts.id 
    where eu.name like '%Thomas%' and ts.status = 'APPROVED'
    group by ts.start_time

    select en.id from Entry en
    inner join Timesheet ts on ts.id = en.time_sheet_id
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where ts.[status]= 'WITHDRAWN_APPROVAL'

    delete from Timesheet where status != 'APPROVED'


    select * from Entry where time_sheet_id is Null;

    with cteTable as (
        SELECT 
            name, FLOOR((DATEDIFF(DAY, '7-May-24', '2024-12-31') / 7.0)) AS weeks_left
        FROM 
            EmployeeUser
        where 
            start_date > '2024-01-01'
    )
    select 
        name, 160 - (weeks_left * 3.068) as ballance 
    From 
        cteTable
    Order by 
        name

    select * FROM EmployeeUser eu where name like 'Daniel%'

    UPDATE EmployeeUser SET start_date = '2024-01-15' WHERE name = 'Tyler Radke';
    UPDATE EmployeeUser SET start_date = '2024-01-22' WHERE name = 'Kendal Cruz';
    UPDATE EmployeeUser SET start_date = '2024-01-29' WHERE name = 'Behrouz Ayaz';
    UPDATE EmployeeUser SET start_date = '2024-02-01' WHERE name = 'Matt Dixon';
    UPDATE EmployeeUser SET start_date = '2024-02-08' WHERE name = 'Luke Dixon';
    UPDATE EmployeeUser SET start_date = '2024-02-08' WHERE name = 'Rocia Luo';
    UPDATE EmployeeUser SET start_date = '2024-03-01' WHERE name = 'Steve Sharon';
    UPDATE EmployeeUser SET start_date = '2024-03-18' WHERE name = 'Dilwinder Singh';
    UPDATE EmployeeUser SET start_date = '2024-03-26' WHERE name = 'Sunny Jinks';
    UPDATE EmployeeUser SET start_date = '2024-04-02' WHERE name = 'Daniel Murangira';
    UPDATE EmployeeUser SET start_date = '2024-04-08' WHERE name = 'Moral Soryal';
    UPDATE EmployeeUser SET start_date = '2024-04-12' WHERE name = 'Isaias Briones';
    UPDATE EmployeeUser SET start_date = '2024-04-15' WHERE name = 'Bill Jinks';
    UPDATE EmployeeUser SET start_date = '2024-04-17' WHERE name = 'Courtney Letendre';
    UPDATE EmployeeUser SET start_date = '2024-05-01' WHERE name = 'Timothy Mohamed';
    UPDATE EmployeeUser SET start_date = '2024-05-01' WHERE name = 'Walter Alexis';
    UPDATE EmployeeUser SET start_date = '2024-05-07' WHERE name = 'Jeremy Hoeksema';
    UPDATE EmployeeUser SET start_date = '2024-05-13' WHERE name = 'Don Fillmore';
    UPDATE EmployeeUser SET start_date = '2024-05-13' WHERE name = 'Zain Ashiq';
    UPDATE EmployeeUser SET start_date = '2024-05-21' WHERE name = 'Shannon Simpson';
    UPDATE EmployeeUser SET start_date = '2024-05-21' WHERE name = 'Maynard Basilides';

*/
