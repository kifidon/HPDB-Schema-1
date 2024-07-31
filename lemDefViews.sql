/*
Some Notes on the views
1. View names should be relavant and easily notifiable. Lemv1, Lemv2, Lemv3 give no detail about 
    whats being stored in each view.
2.  You've joined the tables using a cross join which means that without proper filtering in a "where"
    clause, the rows in the views have no meaning, as Data is being shared and douplicated across multiple
    records 
3.  The views should be designed using the keys of relavent columns in a way that makes 
    quering them in the future efficient and simple.  The columns in the views 
    should be the relavant attributes of the underlying tables such that, someone without 
    coding experience can read the table without having to understand the database schema.
    There are no "where" clauses or join clauses which also means finding relavent data
    is going to be tricky without knowing exactly where it is stored
    in the database.

I've included a view for the WorkerRateSheet to help you get started and give more direction.
*/

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
    select 1 as '1' from EqpRateSheet
)

Go 
drop view if Exists lemEquipEntrys
go 
create VIEW lemEquipEntries as (
    select 1 as '1' from EqpRateSheet
)

Go 
drop view if Exists lemWorkerEntries
go 
create VIEW lemWorkerEntries as (
    select 1 as '1' from EqpRateSheet
)

Go 
drop view if Exists DataForLemOutput
go 
create VIEW DataForLemOutput as ( -- combined relavant data
    select 1 as '1' from EqpRateSheet
)

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