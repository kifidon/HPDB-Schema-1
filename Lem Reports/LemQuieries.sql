
--insertEquip
    -- Declare variables
    DECLARE @workerID VARCHAR(50) = '';
    DECLARE @Name VARCHAR(50) = '';
    DECLARE @Cat VARCHAR(50) = 'Equipment';
    DECLARE @description VARCHAR(50) = '';

    -- Insert into LemWorkingUnit
    INSERT INTO LemWorkingUnit(workerID, [name], category)
    VALUES (@workerID, @Name,  @Cat);

    UPDATE Equipment
    SET [description] = @description 
    WHERE workerID = @workerID ;
-- delete equip 
    DECLARE @ID VARCHAR(10) = '';
    DELETE FROM LemWorkingUnit
    WHERE workerID = @ID
    AND EXISTS (
        SELECT 1
        FROM LemWorkingUnit
        WHERE workerID = @ID
    );

-- insertPeople
    DECLARE @workerID VARCHAR(50) = '';
    DECLARE @Name VARCHAR(50) = '';
    DECLARE @Cat VARCHAR(50) = 'Employee';
    DECLARE @role VARCHAR(50) = '';

    -- Insert into LemWorkingUnit
    INSERT INTO LemWorkingUnit (workerID , [name], category)
    VALUES (@workerID , @Name, @Cat);

    UPDATE LemEmployee
    SET [role] = @role
    WHERE workerID = @ID;

-- deletePeople 
    DECLARE @ID VARCHAR(10) = '';
    DELETE FROM LemWorkingUnit
    WHERE workerID = @ID
        AND EXISTS (
            SELECT 1
            FROM LemEmployee
            WHERE workerID = @ID
        );

-- insertMaterials 
    DECLARE @workerID VARCHAR(50) = '';
    DECLARE @Name VARCHAR(50) = '';
    DECLARE @Cat VARCHAR(50) = 'Materials';
    DECLARE @vendor VARCHAR(50) = '';

    -- Insert into LemWorkingUnit
    INSERT INTO LemWorkingUnit (workerID , [name], category)
    VALUES (@workerID , @Name, @Cat);

    UPDATE LemMaterials
    SET vendor = @vendor
    WHERE unitID= @ID;
    
-------------------InsertWorkDone TO BUILD A LEM TABLE 
DECLARE @DESCRIPTION VARCHAR(MAX) = 'This is a test';
DECLARE @CALENDAR_DAY DATE = '2023-01-22';
DECLARE @PROJ_NUM VARCHAR(50) = 'A23-000-0000';

-- Check if the row exists in the workDone table
INSERT INTO LemForDay ( DESCRIPTION, CALENDAR_DAY, PROJ_NUM)
    VALUES ( @DESCRIPTION, @CALENDAR_DAY, @PROJ_NUM);
    -- Record exists, so update the existing record
   
---------aSSIGN Employee TO LEM ------
DECLARE @WID VARCHAR(50) = '';
DECLARE @PROJ_NUM VARCHAR(50) = '';
DECLARE @LemNumber INT = 0; 
DECLARE @REG_HRS DECIMAL(10,2) = 12; 
DECLARE @OT_HRS DECIMAL(10,2) = 12; 

-- Insert data into the worked_on table
INSERT INTO worked_onLem (WID, PROJ_NUM, LemNumber, REG_HRS, OT_HRS)
VALUES (@WID, @PROJ_NUM, @LemNumber, @REG_HRS, @OT_HRS);

--------------- Insert Equip
DECLARE @UNIT_NO VARCHAR(50) = '';
DECLARE @PROJ_NUM VARCHAR(50) = '';
DECLARE @LemNumber INT = 0; 
DECLARE @REG_HRS DECIMAL(10,2) = 12; 

-- Insert data into the worked_on table
INSERT INTO EquipLem (UNIT_NO, PROJ_NUM, LemNumber, HRS)
VALUES (@UNIT_NO, @PROJ_NUM, @LemNumber, @REG_HRS);

-------------------InsertSubCon
DECLARE @WID VARCHAR(50) = 'YourWID';
DECLARE @PROJ_NUM VARCHAR(50) = 'YourProjNum';
DECLARE @LemNumber INT = 123; -- Your LemNumber
DECLARE @REF_NUM VARCHAR(15) = 'YourRefNum';
DECLARE @DESCRIPTION VARCHAR(50) = 'YourDescription';
DECLARE @QTY DECIMAL(10,2) = 10.5; -- Your QTY
DECLARE @UNIT_PRICE DECIMAL(10,2) = 20.75; -- Your UNIT_PRICE

INSERT INTO subContractorsLem (WID, PROJ_NUM, LemNumber, REF_NUM, DESCRIPTION, QTY, UNIT_PRICE)
VALUES (@WID, @PROJ_NUM, @LemNumber, @REF_NUM, @DESCRIPTION, @QTY, @UNIT_PRICE);

-----------------------Insert Materials Lem 

DECLARE @UID VARCHAR(50) = 'YourWID';
DECLARE @PROJ_NUM VARCHAR(50) = 'YourProjNum';
DECLARE @LemNumber INT = 123; -- Your LemNumber
DECLARE @UNIT_COST DECIMAL(10,2) = 'YourRefNum';
DECLARE @QTY DECIMAL(10,2) = 10.5; -- Your QTY

INSERT INTO matOnLem (UNIT_ID, PROJ_NUM, LemNumber, UNIT_COST, QTY)
VALUES ( @UID, @PROJ_NUM, @LemNumber, @UNIT_COST, @QTY);

---------------------Insert Rates 
Declare @workerID VARCHAR(50) = ''
Declare @RegRate DECIMAL(10,2) = ''

update LemRates 
set endDay = CAST(GETDATE() as DATE)
where workerID = @workerID and startDay >= All ( 
        Select startDay from LemRates 
        where workerID = @workerID
    ) and endDate = NULL;

Insert into LemRates (workerID, startDay, regRate)
values(@workerID, CAST(GetDate() as DATE), @RegRate);











-- Add any necessary JOIN conditions based on your schema



----------------ASSIGN LEM TO A PROJECT 
-- DECLARE @LEM_ID VARCHAR(50) = '@{outputs('LemIDC')}';
-- DECLARE @DESCRIPTION VARCHAR(MAX) = '@{outputs('Description')}';
-- DECLARE @CALENDAR_DAY DATE = '@{outputs('Compose_2')}';
-- DECLARE @PROJ_NUM VARCHAR(50) = '@{outputs('PN')}';

-- Check if the row exists in the worksDone table
IF NOT EXISTS (SELECT 1 FROM workDone WHERE LEM_ID = @LEM_ID)
BEGIN
    -- Record doesn't exist, so insert a new record
    INSERT INTO workDone (LEM_ID, DESCRIPTION, CALENDAR_DAY)
    VALUES (@LEM_ID, @DESCRIPTION, @CALENDAR_DAY);
END
ELSE
BEGIN
    -- Record exists, so update the existing record
    UPDATE workDone
    SET DESCRIPTION = @DESCRIPTION,
        CALENDAR_DAY = @CALENDAR_DAY
    WHERE LEM_ID = @LEM_ID;
END

-----ASSIGN A LEM TO A PROJECT 
INSERT INTO lemFor (LEM_ID, PROJ_NUM)
VALUES( @LEM_ID, @PROJ_NUM);

-------------All Dates with lems for a given project 
GO
DECLARE @Proj_N VARCHAR(50) = 'A24-000-0000';

SELECT DISTINCT CONVERT(VARCHAR(10), wd.CALENDAR_DAY, 10) AS DATE FROM workDone wd
INNER JOIN lemFor lf ON lf.LEM_ID = wd.LEM_ID
WHERE lf.PROJ_NUM = @Proj_N;

----------------AutoPullLemms  BASED ON DATE AND PROJ NUM
GO

DECLARE @Proj_N VARCHAR(50) = '  ';
DECLARE @DATE DATE = ' ';

SELECT lf.LEM_ID FROM lemFor lf
INNER JOIN workDone wd ON wd.LEM_ID = lf.LEM_ID
WHERE wd.CALENDAR_DAY = @DATE AND lf.PROJ_NUM = @Proj_N;


--------Date filter per person 

DECLARE @StartDate DATE = '2023-01-01';  -- Replace with your start date
DECLARE @EndDate DATE = '2025-02-24';    -- Replace with your end date
WITH CombinedRatesCTE AS (
    SELECT
        COALESCE(lrv.ID, er.ID) AS ID,
        COALESCE(lrv.CALENDAR_DAY_START, er.CALENDAR_DAY_START) AS CALENDAR_DAY_START,
        COALESCE(
            COALESCE(lrv.CALENDAR_DAY_END, er.CALENDAR_DAY_END), GETDATE()
        ) AS CALENDAR_DAY_END,
        COALESCE(lrv.REG_RATE, er.REG_RATE) AS REG_RATE,
        COALESCE(lrv.OT_RATE, 0) AS OT_RATE,
        COALESCE(lrv.RATE_COST, er.RATE_COST) AS RATE_COST,
        COALESCE(lrv.HOURLY, er.HOURLY) AS HOURLY
    FROM
        liveRatesView lrv
    FULL JOIN
        equipmentRates er ON lrv.ID = er.ID
),
CalendarRange AS (
    Select 
        cd.CALENDAR_DAY
    FROM 
        calendarDay cd
    WHERE 
        cd.CALENDAR_DAY BETWEEN @StartDate AND @EndDate
),
WorkedHoursCTE AS (
    SELECT
        wu.ID AS ID,
        crg.CALENDAR_DAY,
        wo.REG_HRS,
        wo.OT_HRS,
        CASE
            WHEN wu.CATEGORY = 'Equipment' THEN eq.TYPE
            WHEN wu.CATEGORY = 'People' THEN pe.ROLE
            WHEN wu.CATEGORY = 'ThirdParty' THEN tp.CLASS
        END AS Title,
        CASE
            WHEN wo.CALENDAR_DAY BETWEEN cr.CALENDAR_DAY_START AND cr.CALENDAR_DAY_END AND wo.ID =cr.ID THEN cr.REG_RATE
                
        END AS REG_Rate,
        CASE 
            WHEN wo.CALENDAR_DAY BETWEEN cr.CALENDAR_DAY_START AND cr.CALENDAR_DAY_END AND wo.ID =cr.ID THEN cr.OT_RATE
        END AS OT_Rate
    FROM
        CalendarRange crg
    JOIN
        worked_on wo ON crg.CALENDAR_DAY = wo.CALENDAR_DAY 
    JOIN 
        workingUnit wu ON wu.ID = wo.ID
    JOIN
        CombinedRatesCTE cr ON cr.ID = wu.ID
    LEFT JOIN
        Equipment eq ON eq.ID = wu.ID AND wu.CATEGORY = 'Equipment'
    LEFT JOIN
        People pe ON pe.ID = wu.ID AND wu.CATEGORY = 'People'
    LEFT JOIN
        ThirdParty tp ON tp.ID = wu.ID AND wu.CATEGORY = 'ThirdParty'
    WHERE  wo.CALENDAR_DAY BETWEEN cr.CALENDAR_DAY_START AND cr.CALENDAR_DAY_END 
    --ORDER BY crg.CALENDAR_DAY ASC
)
SELECT
    ID,
    Title,
    SUM(REG_HRS) AS TotalRegularHours,
    SUM(OT_HRS) AS TotalOvertimeHours,
    SUM(REG_HRS * REG_RATE) + SUM(OT_HRS * OT_RATE * 1.5) AS TotalAmountPaid
FROM
    WorkedHoursCTE
WHERE
    ID IS NOT NULL
GROUP BY
    ID, Title

UNION ALL  -- Use UNION ALL to include duplicates

-- Final row with sums for all working units
SELECT
    '----' AS ID, -- there is a problem
    -- when passing null so save as this for now 
    'TOTAL AMOUNT' AS Title,
    SUM(TotalRegularHours) AS TotalRegularHours,
    SUM(TotalOvertimeHours) AS TotalOvertimeHours,
    SUM(TotalAmountPaid) AS TotalAmountPaid
FROM (
    -- Subquery to calculate sums for each working unit
    SELECT
        ID,
        Title,
        SUM(REG_HRS) AS TotalRegularHours,
        SUM(OT_HRS) AS TotalOvertimeHours,
        SUM(REG_HRS * REG_Rate) + SUM(OT_HRS * OT_Rate * 1.5) AS TotalAmountPaid
    FROM
        WorkedHoursCTE
    WHERE
        ID IS NOT NULL
    GROUP BY
        ID, Title
) AS SubqueryAlias
ORDER BY Title;
-------------------------------------Delete equip 
DECLARE @ID VARCHAR(10) = ' ';
DELETE FROM workingUnit
WHERE ID = @ID
  AND NOT EXISTS (
    SELECT 1
    FROM equipment
    WHERE ID = @ID
);
----------------------------------------Insert equip rates 
DECLARE @ID VARCHAR(50) = 'YourID';  -- Replace with your actual ID
DECLARE @RegRate DECIMAL(10,2) = 20.0;  -- Replace with your actual RegRate
DECLARE @RateCost DECIMAL(10,2) = 150.0;  -- Replace with your actual RateCost
DECLARE @FuelBurn DECIMAL(10,2) = 5.0;  -- Replace with your actual FuelBurn
DECLARE @EquipmentTime DECIMAL(10,2) = 8.0;  -- Replace with your actual EquipmentTime

INSERT INTO equipmentRates (ID, CALENDAR_DAY_START, REG_RATE, RATE_COST, FUEL_BURN, EQP_TIME)
VALUES (@ID, GETDATE(), @RegRate, @RateCost, @FuelBurn, @EquipmentTime);

--------------------------------------------Update equip Rates
DECLARE @ID vARcHAR(10) = ' ';
DECLARE @reg DECIMAL(10,2) = ' ';
DECLARE @COST DECIMAL(10,2) = ' ';
DECLARE @FuelBurn DECIMAL(10,2) = 5.0;  -- Replace with your actual 
DECLARE @EquipmentTime DECIMAL(10,2) = 8.0;
UPDATE liveRates
SET REG_RATE = @reg,
    RATE_COST = @COST,
    FUEL_BURN = @FuelBurn,
    EQP_TIME = @EquipmentTime
      -- Replace with the new REG_RATE value
WHERE ID = @ID
  AND CALENDAR_DAY_START IN (SELECT MostRecentStartDate FROM MostRecentEquipmentRates WHERE ID = @ID);

--------------------------------------DeleteEquip rates 
DECLARE @EquipmentID VARCHAR(50) = 'YourEquipmentID'; -- Replace with the actual EquipmentID

DELETE FROM equipmentRates
WHERE ID = @EquipmentID;

--------------------------------------------Insert PEople 
GO 
-- Declare variables
DECLARE @ID VARCHAR(50) = '';
DECLARE @Name VARCHAR(50) = '';
DECLARE @Cat VARCHAR(50) = 'People';
DECLARE @Shift VARCHAR(50) = '';
DECLARE @Hourly VARCHAR(50) = '';
DECLARE @Type VARCHAR(50) = ''; --role 

-- Insert into workingUnit
INSERT INTO workingUnit (ID, NAME, SHIFT, CATEGORY)
VALUES (@ID, @Name, @Shift, @Cat);

UPDATE People
SET ROLE = @Type
WHERE ID = @ID;

---------------------------------------------------- Delete Peopele 
DECLARE @ID VARCHAR(10) = '';
DELETE FROM workingUnit
WHERE ID = @ID
  AND EXISTS (
    SELECT 1
    FROM People
    WHERE ID = @ID
);

---------------------------------------------insert live rates 
DECLARE @ID VARCHAR(50) = 'YourID';  -- Replace with your actual ID
DECLARE @RegRate DECIMAL(10,2) = 20.0;  -- Replace with your actual RegRate
DECLARE @RateCost DECIMAL(10,2) = 150.0;

INSERT INTO liveRates (ID, CALENDAR_DAY_START,  REG_RATE, RATE_COST)
VALUES ( @ID, GETDATE(), @RegRate, @RateCost);

------------------------------------------------- DElete peopela rates 
DECLARE @ID VARCHAR(50) = 'YourEquipmentID'; -- Replace with the actual EquipmentID

DELETE FROM liveRates
WHERE ID = @ID;

------------------------------------------------------Update rates 
DECLARE @ID vARcHAR(10) = ' ';
DECLARE @reg DECIMAL(10,2) = ' ';
DECLARE @COST DECIMAL(10,2) = ' ';
UPDATE liveRates
SET REG_RATE = @reg,
    RATE_COST = @COST
      -- Replace with the new REG_RATE value
WHERE ID = @ID
  AND CALENDAR_DAY_START IN (SELECT MostRecentStartDate FROM MostRecentLiveRates WHERE ID = @ID);


--------------------------------------------------------Insert ThirdParty 
DECLARE @ID VARCHAR(50) = '';
DECLARE @Name VARCHAR(50) = '';
DECLARE @Cat VARCHAR(50) = 'ThirdParty';
DECLARE @Shift VARCHAR(50) = '';
DECLARE @Hourly VARCHAR(50) = '';
DECLARE @Type VARCHAR(50) = ''; --class
DECLARE @TICKET VARCHAR(50) = '' -- ticket  

INSERT INTO workingUnit (ID, NAME, SHIFT, CATEGORY, HOURLY)
VALUES (@ID, @Name, @Shift, @Cat, @Hourly);

UPDATE ThirdParty
SET CLASS = @Type,
    TICKET = @Ticket
WHERE ID = @ID;

---------------------------------------------------------------Delete third party 
DECLARE @ID VARCHAR(10) = '';
DELETE FROM workingUnit
WHERE ID = @ID
  AND EXISTS (
    SELECT 1
    FROM ThirdParty
    WHERE ID = @ID
);


*/