--Views and triggers 
drop view if exists TimeSheetOperations
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
drop view if exists MonthlyBillable
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
        WHERE ts.[status] = 'APPROVED' and en.billable = 1
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
        WHERE ts.[status] = 'APPROVED' and en.billable = 1
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


go
drop view if exists MonthlyBillableEqp
go
CREATE VIEW MonthlyBillableEqp as (

    SELECT  
        Null as [Number],
        eu.name as [Name], 
        NULL AS [Supplier],
        CAST(SUM(en.duration) AS DECIMAL(10, 2)) AS QTY,
        'hr' AS Unit,
        18.75 AS [Unit Cost],
        CAST(
             SUM(en.duration) * 118.75 AS DECIMAL(10, 2)  -- * truck rate
        )AS Amount,
        en.start_time,
        en.project_id
    FROM TimeSheet ts 
        INNER JOIN EmployeeUser eu on eu.id = ts.emp_id 
        INNER JOIN [Entry] en ON en.time_sheet_id = ts.id 
        INNER JOIN Project pj on pj.id = en.project_id and pj.workspace_id = en.workspace_id
        INNER JOIN Client cl on cl.id = pj.client_id and pj.workspace_id = cl.workspace_id
        WHERE ts.[status] = 'APPROVED' and en.billable = 1 and eu.hasTruck = 1
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
            SUM(en.duration * 18.75) AS DECIMAL(10, 2) -- * en.rate)
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
        WHERE ts.[status] = 'APPROVED' and en.billable = 1 and eu.hasTruck = 1
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
drop view if exists AttendanceApproved 
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
           d.dayOfWeek not in (1,7) and tr.status = 'APPROVED' 
    )     
    SELECT 
        
        COALESCE(th.name, tr.name) AS [name],
        Case 
            when eu.hourly = 1 then 'Hourly' Else 'Salary'
        End as [Type],
        COALESCE(th.[Date], tr.[Date]) AS [date],
        CASE    
            WHEN COALESCE(th.TotalHours, 0) <= 8 
                and DATEPART(WEEKDAY, th.[Date]) between 2 and 6 
                THEN COALESCE(th.TotalHours, 0)
            when COALESCE(th.TotalHours, 0) > 8 
                and DATEPART(WEEKDAY, th.[Date]) between 2 and 6 
                THEN 8
            when  th.[Date] = b.accuredOn and  DATEPART(WEEKDAY, th.[Date])  not between 2 and 6 
                THEN 0
            else COALESCE(th.totalHours, 0)
        END AS RegularHrs,
        case when b.accuredOn is not Null then b.BankedHours else 0
        end as Accrued,
        
        CASE 
            WHEN COALESCE(th.TotalHours, 0) > 8 
                and b.accuredOn is Null then  th.TotalHours - 8
            ELSE 0
        END AS Overtime,
        case 
            when th.TotalHours is null then 0
            when th.[Date] = tr.[date] and tr.policy_name like '%Banked%' then th.TotalHours + tr.TimeOff - Coalesce(b.BankedHours,0) 
            when th.[Date] = tr.[date] and tr.policy_name not like '%Banked%' and eu.id = th.id and eu.hourly = 0 then th.TotalHours + tr.TimeOff - Coalesce(b.BankedHours,0) 
            else th.TotalHours - Coalesce(b.BankedHours,0) 
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
        TimeOffReasons tr ON th.id = tr.id 
            AND th.[Date] = tr.[Date]
    left join 
        Calendar d on d.[date] IN (th.[Date], tr.date)
    Inner join EmployeeUser eu on eu.id = th.id or eu.id = tr.id
    left Join BankedHRS b on b.empID = eu.id and b.accuredOn = d.[date]
    

go
drop view if exists BankedHRS
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
drop view if exists BankedTimeOffPolicy
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
drop view if exists TotalApprovedTimePerUser
go 
create view TotalApprovedTimePerUser as (
    select  eu.name , Sum(en.duration) as [Approved Time], SUM(en.duration * en.rate/100) as [Billable Amount] ,eu.id from Entry en
    inner join TimeSheet ts on ts.id = en.time_sheet_id
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where ts.status = 'APPROVED' and DATEPART(year, Cast(en.start_time as Date )) = DatePart(YEAR, GETDATE())
    group by eu.name, eu.id)

go 
drop view ExpenseClaim
go
create view ExpenseClaim as 
    with cteExpenses as ( -- Expenses For which an altered Unit Cost on milage is to be applied 
        select 
            ex.id,
            ex.userId,
            ex.quantity,
            0.62 as UnitCost
        from 
            Expense ex
        inner join 
            ExpenseCategory ec on ec.id = ex.categoryId
        where 
            ec.name like 'Mileage' and
            EXISTS (
                select 1 from Expense exI
                where 
                    exI.userId = ex.userId 
                    and exI.date between DateFromParts(Year(ex.date),1,1) and ex.[date]
                    and ex.[status] IN ('APPROVED', 'PENDING') and exI.[status] IN ('APPROVED', 'PENDING')
                    -- AND exI.id != ex.id 
                group by  
                    exI.userId 
                having 
                    SUM(exI.quantity) >= 5000
            )
    )
    select
        ex.id,
        ex.date as [Date],
        eu.name as [Name],
        ec.name as [Expense Type],
        ex.notes as [Description],
        ex.status,
        case 
            when ec.hasUnitPrice = 1 then ex.quantity else 1
            end as [Quantity],
        case 
            when ec.hasUnitPrice = 1 then Cast(Round(COALESCE(cex.UnitCost, ec.priceInCents), 2) as Decimal(10,2)) else 0
            end as [Unit Price],
        p.name as [Project],
        Case when ec.hasUnitPrice = 1 then 0 else CAST(ex.subTotal as Decimal(10,2)) end as [Sub-Total],
        case when ec.hasUnitPrice = 1 then 0 else Cast(ex.taxes as Decimal(10,2)) end as [Tax],
        Case 
            when ec.hasUnitPrice = 1 then Cast(round(Coalesce(cex.UnitCost, ec.priceInCents)* ex.quantity, 2) as decimal(10,2)) 
            else Cast((ex.subTotal + ex.taxes ) as Decimal(10,2))
        end As[Total]
    From
        Expense ex
    left Join cteExpenses cex on cex.id = ex.id
    inner join EmployeeUser eu on eu.id = ex.userId
    Inner join Project p on p.id = ex.projectId
    inner join ExpenseCategory ec on ec.id = ex.categoryId

go
drop view if exists PendingTimesheets
go
CREATE view PendingTimesheets as 
    select eu.name, ts.start_time, ts.id from TimeSheet ts 
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where ts.[status] = 'PENDING'

go 
drop view if exists MissingTimesheets 
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
drop view if exists MalformedTimesheets
go 
Create View MalformedTimesheets as (
    select eu.name, ts.start_time, ts.[status], ts.id From TimeSheet ts
    Inner join EmployeeUser eu on eu.id = ts.emp_id
    where not exists (
        select 1 from Entry en where en.time_sheet_id = ts.id
    ) 
    and ts.status = 'APPROVED'
)

go
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

go
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

Go 
Create Or Alter Trigger CreateFileOnExpense 
    On Expense 
    After Insert 
    as 
    Begin 
        Insert FilesForExpense( expenseId, workspaceId)
        Select id, workspaceId 
        From inserted
    end; 

go 
Create or alter TRIGGER  trg_insert_BackGroundTaskDjango
    ON BackGroundTaskDjango
    AFTER INSERT
    AS
    BEGIN
        SET NOCOUNT ON;

        UPDATE BackGroundTaskDjango
        SET message = 'No Information'
        FROM BackGroundTaskDjango AS b
        JOIN inserted AS i ON b.[time] = b.[time]
        WHERE i.message IS NULL;
    END;

update BackgroundTaskDjango 
set message = 'No Message Provided' where [message] is NULL
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
