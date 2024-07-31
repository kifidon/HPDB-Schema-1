

DROP VIEW lemv1;
SELECT * from lemv1;


-- Create view 
CREATE VIEW Lemv1 AS
SELECT
   Equipment.[name],LemSheet.id,LemSheet.clientId,WorkerRateSheet.workRate,WorkerRateSheet.travelRate,WorkerRateSheet.CalcRate,
EqpRateSheet.dayRate,EqpRateSheet.unitRate
FROM
    LemSheet,LemEntry,WorkerRateSheet,EqpRateSheet,Equipment;


DROP VIEW lemv2;
SELECT * from lemv2;

-- Create view 

CREATE VIEW lemv2 AS
select 
   Equipment.[name],EquipEntry._id,EqpRateSheet.unitRate,EquipEntry.qty
FROM
   EquipEntry,EqpRateSheet,Equipment;


   DROP VIEW lemv3;
SELECT * from lemv3;

-- Create view 

   CREATE VIEW lemv3 AS
   SELECT
      LemWorker.empId,Equipment.name,LemEntry.[work],LemEntry.travel,LemEntry.Calc,
      LemEntry.Meals,LemEntry.Hotel
   FROM
      LemWorker,Equipment,LemEntry;