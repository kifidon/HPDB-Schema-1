

GO -- starts a new batch 
Drop View if Exists WorkerRateSheetView
Go -- starts a new batch, view can be only statement in batch 
Create View WorkerRateSheetView as ( -- descriptive name
    select 
        c.id as [ClientId], -- relavant key for easy retrieval of all rates for a given client
        c.longName as [ClientName], -- formated column names 
        r.name as [Role],
        wr.travelRate as [TravelRate],
        wr.workRate as [WorkRate],
        wr.calcRate as [CalcRate]
    from WorkerRateSheet wr 
    inner join Client c on c.id = wr.clientId -- joined only on matching clients
    inner join Role r on r.id = wr.roleId -- further joined on matching names
)

Go 
drop view if Exists EquipmentRateSheetView
go 
create VIEW EquipmentRateSheetView as (
    Select 
        c.id as [ClientId], -- relavant key for easy retrieval of all rates for a given client
        c.name as [ClientName], -- formated column names 
        eq.id as EquipId,
        eq.name as [EquipmentName],
        er.dayRate as [DayRate],
        er.unitRate as [unitRate]
    from EqpRateSheet er 
    inner join Client c on c.id = er.clientId -- joined only on matching clients
    inner join Equipment eq on eq.id = er.equipId -- further joined on matching names
)

Go 
drop view if Exists lemEquipEntries
go 
create VIEW lemEquipEntries as (
    Select 
        ls.id,
        eq.id as equipID,
        ls.lem_sheet_date,
        Case 
            when ee.isUnitRate = 1 then CONCAT(eq.name, ' - Unit' )
            else Concat(eq.name, ' - Day ')
        end as [name],
        ee.qty,
        case 
            when ee.isUnitRate = 1 then ers.unitRate
            else ers.dayRate
        end as [Rate],
        case 
            when  ee.isUnitRate = 1 then ers.unitRate * ee.qty
            else ers.dayRate * ee.qty
        end as [Cost]
    from EquipEntry ee
    inner join LemSheet ls on ls.id = ee.lemId
    Inner join Equipment eq on eq.id = ee.equipId
    LEFT join EqpRateSheet ers on ers.clientId = ls.clientId and eq.id = ers.equipId
)

Go 
drop view if Exists lemWorkerEntries
go 
create VIEW lemWorkerEntries as (
        Select 
            ls.id,
            ls.lem_sheet_date,
            eu.name as [emp], 
            r.name as [role],
            le.[work],
            le.travel,
            le.Calc,
            Cast(le.[work] *  wr.workRate as Decimal (10,2)) as WorkTotal,
            cast (le.[travel] *  wr.travelRate as decimal(10,2)) as [TravelTotal],
            Cast (le.[Calc] * wr.calcRate as decimal(10,2)) as [CalcTotal],
            le.Meals,
            le.Hotel,
            wr.workRate,
            wr.travelRate,
            wr.calcRate as [Calc Rate]
        from LemEntry le 
        inner join LemSheet ls on ls.id = le.lemId
        inner join LemWorker lw on lw._id = le.workerId
        inner join EmployeeUser eu on eu.id = lw.empId
        inner join Role r on r.id = lw.roleId
        Left join WorkerRateSheet wr on wr.clientId = ls.clientId and wr.roleId = lw.roleId
)

Go 
drop view if Exists DataForLemOutput
go 
create VIEW DataForLemOutput as ( -- combined relavant data
    select 1 as '1' from EqpRateSheet
)

GO
-- For generating lem spreadsheet
Declare @lemId Nvarchar(MAX) = '955b92bd4b19faa330125bb5704336efe442f199975ec'
select Concat(lw.role, ' - Work'), Sum(lw.[work]), lw.workRate, SUM(lw.work * lw.workRate)  From lemWorkerEntries lw
where lw.id = @lemId
group by lw.role, lw.workRate
having Sum(lw.work) != 0
UNION
select Concat(lw.role, ' - Travel'), SUM(lw.travel), lw.travelRate, SUM(lw.travel * lw.travelRate)  From lemWorkerEntries lw
where lw.id = @lemId
group by lw.role, lw.travelRate
having Sum(lw.travel) != 0
Union
select Concat(lw.role, ' - Calc'), Sum(lw.Calc) , lw.[Calc Rate], SUM(lw.calc * lw.[Calc Rate])  From lemWorkerEntries lw
where lw.id = @lemId
group by lw.role, lw.[Calc Rate]
having Sum(lw.calc) != 0

 GO
            -- For generating lem spreadsheet
            Declare @lemId Nvarchar(MAX) = '475d356c168231197f87e1c9c65be8bc05861018d18dd'
            select Concat(lw.role, ' - Work'), Sum(lw.[work]), lw.workRate, SUM(lw.work * lw.workRate)  From lemWorkerEntries lw
            where lw.id = @lemId
            group by lw.role, lw.workRate
            having Sum(lw.work) != 0
            UNION
            select Concat(lw.role, ' - Travel'), SUM(lw.travel), lw.travelRate, SUM(lw.travel * lw.travelRate)  From lemWorkerEntries lw
            where lw.id = @lemId
            group by lw.role, lw.travelRate
            having Sum(lw.travel) != 0
            Union
            select Concat(lw.role, ' - Calc'), Sum(lw.Calc) , lw.[Calc Rate], SUM(lw.calc * lw.[Calc Rate])  From lemWorkerEntries lw
            where lw.id = @lemId
            group by lw.role, lw.[Calc Rate]
            having Sum(lw.calc) != 0
go 
Declare @lemId Nvarchar(MAX) = '955b92bd4b19faa330125bb5704336efe442f199975ec'
select ls.lemNumber, c.name, ls.lem_sheet_date, eu.name,  ls.notes, ls.[description] From LemSheet ls
inner join Client c on c.id = ls.clientId
inner join EmployeeUser eu on eu.id = ls.projectManagerId
where ls.id =  @lemId

go 
Declare @lemId Nvarchar(MAX) = '955b92bd4b19faa330125bb5704336efe442f199975ec'
Select 
    lw.emp,
    lw.role,
    lw.work,
    lw.WorkTotal,
    lw.travel,
    lw.TravelTotal, 
    lw.Calc,
    lw.CalcTotal,
    lw.Meals,
    lw.Hotel
from lemWorkerEntries lw
where lw.id = @lemId

GO
Declare @lemId Nvarchar(MAX) = '955b92bd4b19faa330125bb5704336efe442f199975ec'
Select 
    le.name,
    le.qty,
    le.Rate,
    le.cost
from lemEquipEntries le
where le.id = @lemId

---------------------------------------------------------------------------------------------------------------------------------------------------------------
GO
Drop Trigger If Exists trg_UpdateLemNumber_OnDelete
go
CREATE TRIGGER trg_UpdateLemNumber_OnDelete
ON LemSheet
AFTER DELETE
AS
BEGIN
    DECLARE @ClientId nVarchar(50), @ProjectId nVarchar(50), @deletedLemNum Varchar(10);

    -- Get the clientId and projectId from the deleted record
    SELECT @ClientId = d.clientId, @ProjectId = d.projectId, @deletedLemNum = d.lemNumber
    FROM DELETED d;

    -- Update the lemNumber for all remaining records with the same clientId and projectId
    UPDATE LemSheet
    SET lemNumber = 'LEM-' + Right(Replicate('0', 4) + CAST(CAST(SUBSTRING(lemNumber, 5, 4) AS INT) - 1 AS VARCHAR(10)), 4)
    WHERE clientId = @ClientId AND projectId = @ProjectId
    AND CAST(SUBSTRING(lemNumber, 5, 4) AS INT) > Substring(@deletedLemNum, 5, 4);
END;
go 


Select Right(Replicate('0', 4) + CAST(CAST(SUBSTRING(lemNumber, 5, 4) AS INT) - 1 AS VARCHAR(10)), 4)
 from LemSheet where id = '2eb51c801eea1560c4b603d7aa447b2dc0e5fbf3bdcbb'


select * from LemSheet


/*

DROP VIEW lemv1;
SELECT * from lemv1;


go
-- Create view 
CREATE VIEW Lemv1 AS
SELECT
   Equipment.[name],LemSheet.id,LemSheet.clientId,WorkerRateSheet.workRate,WorkerRateSheet.travelRate,WorkerRateSheet.CalcRate,
EqpRateSheet.dayRate,EqpRateSheet.unitRate
FROM
    LemSheet,LemEntry,WorkerRateSheet,EqpRateSheet,Equipment;

go
DROP VIEW lemv2;
SELECT * from lemv2;
go
-- Create view 

CREATE VIEW lemv2 AS
select 
   Equipment.[name],EquipEntry._id,EqpRateSheet.unitRate,EquipEntry.qty
FROM
   EquipEntry,EqpRateSheet,Equipment;

GO
   DROP VIEW lemv3;
SELECT * from lemv3;

-- Create view 
GO
   CREATE VIEW lemv3 AS
   SELECT
      LemWorker.empId,Equipment.name,LemEntry.[work],LemEntry.travel,LemEntry.Calc,
      LemEntry.Meals,LemEntry.Hotel
   FROM
      LemWorker,Equipment,LemEntry;
*/