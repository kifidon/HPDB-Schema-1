-- Time Sheety Qurary 
/*
    DROP VIEW IF EXISTS MonthlyBillable;
    DROP VIEW IF EXISTS AttendanceApproved;
    DROP VIEW IF EXISTS TimeSheetOperations;
    DROP VIEW IF EXISTS BankedTimeOffPolicy;
    DROP VIEW IF EXISTS BankedHRS;
*/ 
-- only include oT if missing banked tag
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

GO
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
        pj.name AS [Name],
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
            pj.name, 
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
CREATE VIEW AttendanceApproved AS
    with totalHrsPerDay as (
        select 
            Cast(en.start_time as date) as [Date] ,
            eu.name,
            eu.email,
            ROUND(SUM(en.duration) * 4, 0) / 4 AS [TotalHours]
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
            eu.email     
    ),
    TimeOffReasons as (
        select 
            
            d.date,
            eu.name,
            eu.email,
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
        inner join 
            TimeOffPolicies tp on tp.id = tr.pID
        inner join 
            Calendar d on d.[date] between Cast(tr.startDate as Date) and Cast(tr.end_date as Date)
        inner join
            EmployeeUser eu on eu.id = tr.eID 
        inner join 
            GroupMembership gm on gm.user_id = eu.id
        inner join 
            UserGroups ug on ug.id = gm.group_id and ug.name in ('Hourly', 'Salary')
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
        where ts.status = 'APPROVED'
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
        where ts.status = 'APPROVED'
        group by 
            eu.id,
            bd.sDate
    )
    select  -- historical log of all banked hours (used or unused )
        tbd.id as empID,
        bd.name as empName,
        tbd.sDate as accuredOn,
        tbd.total - 8 as BankedHours
    from TotalHrsOnBankedDay tbd
    Inner join BankedDays bd on tbd.sDate = bd.sDate
    where tbd.total > 8

GO

CREATE VIEW BankedTimeOffPolicy AS 
    with TimeOffBanked as ( -- historical log of all used banked hours 
        select 
            eu.id as empID,
            tp.id as polID,
            tr.paidTimeOff,
            tr.end_date
        from 
            TimeOffPolicies tp 
        Inner join 
            TimeOffRequests tr on tp.id = tr.pID
        Left join
            EmployeeUser eu on eu.id = tr.eID 
        where tp.policy_name = 'Banked Time Off'
    )
    select -- Stores for each person the number of banked hours they have accured and used, and the difference between them being the ballance 
        eu.id as id,
        coalesce(tb.polID, '65fc91ca17e548286f7bc026') as polID,
        coalesce(SUM(bh.BankedHours), 0) as [All Time Banked Hours],
        coalesce(SUM(tb.paidTimeOff), 0) as [All Time Used Banked Hours],
        coalesce(sum(bh.BankedHours),0) - coalesce(sum(tb.paidTimeOff), 0 )as balance
    from EmployeeUser eu
    Full Outer Join BankedHRS bh on bh.empID = eu.id
    Full OUTER join TimeOffBanked tb on bh.empID = tb.empID
    group by
        tb.empID,
        tb.polID,
        eu.id
    
go
/*
    GO 
                    DECLARE @ProjID VARCHAR(100)= '65c24acdedeea53ae19dbaec';
                    SELECT 
                        [Number],
                        [Row],
                        [Name],
                        [Supplier],
                        [QTY],
                        [Unit],
                        SUM([Unit Cost]) As [Unit Cost],
                        Amount
                    FROM MonthlyBillable mb
                        WHERE mb.project_id = @ProjID
                    GROUP BY 
                        [Number],
                        [Row],
                        [Name],
                        [Supplier],
                        [QTY],
                        [Unit],
                        Amount 
                    ORDER BY [Number] DESC;

                    Select 
                    DISTINCT en.project_id
                    FROM TimeSheet TS
                    INNER JOIN Entry en ON en.time_sheet_id = ts.id
                    WHERE ts.start_time BETWEEN GETDATE() - 10 AND GETDATE()

    CREATE VIEW AttendanceReport AS (
        SELECT 
            eu.name,
            att.date,
            -- start and end time 
            CASE 
                WHEN att.overtime > 0 Then 8
                WHEN att.overtime < 0 Then 8 + att.overtime
                WHEN att.timeOff != 0 Then 0
                ELSE att.totalDuration - ABS(att.overtime) -- ensures an output although may not be correct 
            END AS [reg hrs],
            CASE 
                WHEN att.overtime <= 0 then 0
                ELSE att.overtime
            END AS overtime,
            att.totalDuration,
            att.timeoff,
            CASE 
                WHEN att.timeOff != 0 THEN po.policy_name
                ELSE 'N/A'
            END AS Reason
        FROM Attendance att
            INNER JOIN EmployeeUser eu on eu.id = att.id
            LEFT JOIN TimeOffRequests tor on tor.eID = att.id AND (att.date BETWEEN CAST(tor.startDate AS DATE) AND CAST(tor.end_date AS DATE)) AND tor.[status] = 'APPROVED'
            LEFT JOIN TimeOffPolicies po on po.id = tor.pID       
    )

    GO 
    SELECT * FROM AttendanceReport
                    WHERE [date] BETWEEN '2024-02-11' AND '2024-02-17'
                    ORDER BY [date]

    SELECT * FROM Attendance att
    inner join EmployeeUser eu on eu.id = att.id
    LEFT JOIN TimeOffRequests tor on tor.eID = att.id AND att.date BETWEEN tor.startDate AND tor.end_date
    WHERE eu.[name] = 'Shawna Applejohn 'and [date] BETWEEN '2024-02-11' AND '2024-02-17'
        ORDER BY [date]

    SELECT
        tr.*
    FROM
        TimeOffRequests tr
    INNER JOIN
        EmployeeUser eu ON tr.eID = eu.id
    WHERE
        eu.name = 'Timmy Ifidon';
    delete from TimeOffRequests 
    where id = '65e7abe6e4c5116661054213'

    select en.start_time, en.end_time, en.duration, p.[code], eu.name,  en.[description] From  Timesheet ts 
    inner join EmployeeUser eu on eu.id = ts.emp_id
    Inner join [Entry] en on en.time_sheet_id = ts.id
    inner join Project p on p.id = en.project_id
    where eu.name like 'Cody%' and ts.start_time = '2024-03-03' and ts.[status] = 'PENDING'

    select ts.id, ts.start_time, ts.end_time, ts.[status] ,eu.name From  Timesheet ts 
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where eu.name like 'Cody%' and ts.status = 'APPROVED'
    order by ts.start_time, ts.[status]

    Select name from EmployeeUser where id = '65e636b0ed9fe04df2770a90'
    select id from EmployeeUser where name Like '%Cody%'
    select * From Project

    select eu.id, eu.name from EmployeeUser eu
    where eu.id not in (
        select eu2.id from EmployeeUser eu2
        inner join Timesheet ts on ts.emp_id = eu2.id 
        where ts.start_time between '2024-02-23' and '2024-03-01' and ( ts.status != 'WITHDRAWN_APPROVAL' )
    )
    and eu.name NOT IN ( 'Keri Cardinal' ,'Eric Scroggins', 'Margaretta Potts Petawaysin', 'Hilary Meng', 'Melissa Bryant', 'Stephanie Alexis', 'Jeff McLeod');

    select * from EmployeeUser eu
    Inner join Timesheet ts on ts.emp_id = eu.id and eu.name Like 'Tony%'

    select * from Entry where time_sheet_id = '6601c8de0d5045194a2cdc08'

    select * from BankedTimeOffPolicy

    select id from EmployeeUser where name Like 'Shiven%'

    Select * FROm TimeOffRequests tr where tr.eID = '65dcdd57ea15ab53ab7b14df'

    select eu.name, en.start_time, en.duration From TagsFor tg 
    inner join Entry en on en.id = tg.entryID
    inner join timesheet ts on ts.id = en.time_sheet_id
    inner join EmployeeUser eu on eu.id = ts.emp_id
    where ts.status = 'APPROVED'
*/
