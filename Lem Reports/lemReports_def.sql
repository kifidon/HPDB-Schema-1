/*-- Drop tables
DROP TABLE IF EXISTS LemSubContractor;
DROP TABLE IF EXISTS LemUsedMat;
DROP TABLE IF EXISTS LemUsedEquip;
DROP TABLE IF EXISTS LemWorkedOn;
DROP TABLE IF EXISTS LemRates;
DROP TABLE IF EXISTS LemWorkedOn;
DROP TABLE IF EXISTS LemEquipment;
DROP TABLE IF EXISTS LemMaterials;
DROP TABLE IF EXISTS LemEquipment;
DROP TABLE IF EXISTS LemEmployee;
DROP TABLE IF EXISTS CategoryLem;
DROP TABLE IF EXISTS LemWorkingUnit;
DROP TABLE IF EXISTS LemCategory;
DROP TABLE IF EXISTS LemForDay;
DROP TABLE IF EXISTS LemProjects;
DROP TABLE IF EXISTS LemRepresentative;
DROP TABLE IF EXISTS LemClient;


-- Drop triggers
DROP TRIGGER IF EXISTS InsertIntoSubTable;
DROP TRIGGER IF EXISTS createNewRate;
DROP TRIGGER IF EXISTS trg_LemForDay_Insert;

-- Drop views
DROP VIEW IF EXISTS LemEmployeeRates;
DROP VIEW IF EXISTS LemRecentRates;
DROP VIEW IF EXISTS LemEmployeeUnit;
DROP VIEW IF EXISTS LemRecentEmployeeRates;
DROP VIEW IF EXISTS LemSubConView;
DROP VIEW IF EXISTS LemMatView;

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG = 'hpdb'
order by TABLE_NAME;



*/

CREATE TABLE LemClient (
    clientID INT IDENTITY(1000, 1) PRIMARY KEY,
    [location] Varchar(250),
    phonNum varchar(20),
    cName VARCHAR(50),
    cEmail varchar(50)
)

create table LemProjects (
    pjCode Varchar(50) primary key,
    pjName varchar(50),
    clientID INT not null ,
    [location] VARCHAR(250),
    FOREIGN KEY (clientID) REFERENCES LemClient(clientID)
    ON DELETE CASCADE  
)
-- Create the representative table
CREATE TABLE LemRepresentative (
    rEmail  VARCHAR(50) PRIMARY KEY,
    repName VARCHAR(MAX) NOT NULL,
    phoneNum  VARCHAR(50) UNIQUE,
    clientID  int NOT NULL,
    FOREIGN KEY (clientID) REFERENCES LemClient(clientID) ON DELETE CASCADE 
);


-- Create the LemForDay table
CREATE TABLE LemForDay (
    lemReportID INT IDENTITY(1,1) PRIMARY KEY, -- ghost primary key 
    pjCode VARCHAR(50),
    lemNumber INT,
    UNIQUE (pjCode, lemNumber),
    -- Computed column for lemID
    lemID AS (CONCAT(pjCode, '-', RIGHT('000' + CAST(lemNumber AS VARCHAR(3)), 3))),
    [description] VARCHAR(MAX),
    CALENDAR_DAY DATE NOT NULL,
    FOREIGN KEY (pjCode) REFERENCES LemProjects(pjCode) ON DELETE CASCADE ,
);

-----------------------------------------------------------------------------------------------
GO
-- AUTO FILLS AND INCREMENTS LEM NUMBER 
CREATE TRIGGER trg_LemForDay_Insert
ON LemForDay
AFTER INSERT
AS
BEGIN
    UPDATE wu
    SET lemNumber = ISNULL((SELECT MAX(wu_inner.lemNumber) FROM LemForDay wu_inner
                            WHERE wu_inner.pjCode = wu.pjCode),-1) + 1
    FROM LemForDay wu
    JOIN inserted i ON wu.lemID = i.lemID;
END;
GO
-----------------------------------------------------------------------------------------------
CREATE TABLE LemCategory(
    category VARCHAR(50) PRIMARY KEY,
    CHECK( 
        category IN ('Equipment', 'Materials', 'SubContractor', 'Employee')
    )
)

-- Create the LemWorkingUnit table with category column
CREATE TABLE LemWorkingUnit (
    workerID VARCHAR(50) PRIMARY KEY,
    [name]  VARCHAR(50) NOT NULL UNIQUE,
    category VARCHAR(50),
    FOREIGN KEY (category) REFERENCES LemCategory(category) ON DELETE NO ACTION
);

----- MAY ADD INHERITANCE FOR THIRDPARTY AND EQUIPMENT 
CREATE TABLE LemEmployee (
    workerID VARCHAR(50) PRIMARY KEY,
    [role] VARCHAR(50),
    FOREIGN KEY (workerID) REFERENCES LemWorkingUnit(workerID)
    ON DELETE CASCADE 
)

CREATE TABLE LemEquipment (
    unitNum VARCHAR(50) PRIMARY KEY,
    [description] VARCHAR(50),
    FOREIGN KEY (unitNum) REFERENCES LemWorkingUnit (workerID)
    ON DELETE CASCADE
)

CREATE TABLE LemMaterials (
    unitID VARCHAR (50) PRIMARY KEY,
    vendor VARCHAR(50),
    FOREIGN KEY (unitID) REFERENCES LemWorkingUnit(workerID)
    ON DELETE CASCADE
)

-- RELATE TO LEMMS 
CREATE TABLE LemWorkedOn ( -- FURTHER ABSTRACTION FOR TIME TRACKING. EITHER A VIEW OR EXPAND THE TABLE 
    workerID VARCHAR(50),
    pjCode VARCHAR(50),
    lemNumber INT,
    regHrs DECIMAL(10,2),
    otHrs DECIMAL(10,2),
    lemID AS (CONCAT(pjCode, '-', RIGHT('000' + CAST(lemNumber AS VARCHAR(3)), 3))),
    PRIMARY KEY (workerID, pjCode, lemNumber),
    FOREIGN KEY (workerID) REFERENCES LemEmployee(workerID) ON DELETE CASCADE,
    FOREIGN KEY (pjCode, lemNumber) REFERENCES LemForDay(pjCode, lemNumber) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE LemUsedEquip(
    unitNum VARCHAR(50),
    pjCode VARCHAR(50),
    lemNumber INT, 
    hrs DECIMAL(10,2),
    rate DECIMAL(10,2),
    lemID AS (CONCAT(pjCode, '-', RIGHT('000' + CAST(lemNumber AS VARCHAR(3)), 3))),
    PRIMARY KEY (unitNum, pjCode, lemNumber),
    FOREIGN KEY (unitNum) REFERENCES LemEquipment(unitNum) ON DELETE CASCADE,
    FOREIGN KEY (pjCode, lemNumber) REFERENCES LemForDay(pjCode, lemNumber) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE LemUsedMat(
    unitID VARCHAR(50),
    pjCode VARCHAR(50),
    lemNumber INT,
    QTY DECIMAL(10,2),
    UNIT_COST DECIMAL(10,2),
    lemID AS (CONCAT(pjCode, '-', RIGHT('000' + CAST(lemNumber AS VARCHAR(3)), 3))),
    PRIMARY KEY (unitID, pjCode, lemNumber),
    FOREIGN KEY (unitID) REFERENCES LemMaterials(unitID) ON DELETE CASCADE ,
    FOREIGN KEY (pjCode, lemNumber) REFERENCES LemForDay(pjCode, lemNumber) ON DELETE CASCADE 
)
CREATE TABLE LemSubContractor ( 
    workerID VARCHAR(50) ,
    pjCode VARCHAR(50),
    lemNumber INT,
    REF_NUM VARCHAR(15),
    [description] VARCHAR(50),
    QTY DECIMAL(10,2),
    UNIT_PRICE DECIMAL(10,2),
    AMOUNT AS QTY * UNIT_PRICE,
    lemID AS (CONCAT(pjCode, '-', RIGHT('000' + CAST(lemNumber AS VARCHAR(3)), 3))),
    PRIMARY KEY ( workerID, pjCode, lemNumber),
    FOREIGN KEY (workerID) REFERENCES LemWorkingUnit(workerID) ON DELETE CASCADE ,
    FOREIGN KEY (pjCode, lemNumber) REFERENCES LemForDay(pjCode, lemNumber) ON DELETE CASCADE ON UPDATE CASCADE 
);

-- Create the LemRates table
CREATE TABLE LemRates (
    workerID VARCHAR(50),
    startDay DATE,
    endDay DATE,
    regRate DECIMAL(10,2),
    primary key (workerID, startDay),
    foreign key (workerID) REFERENCES LemWorkingUnit(workerID) on delete cascade
);

GO
--------------------------------------TRIGGERS------------------------------------------------------
-- -- Create the createNewRateA trigger
-- CREATE TRIGGER createNewRate
-- ON LemRates
-- INSTEAD OF UPDATE
-- AS
-- BEGIN
--     -- Debugging: Print messages
--     PRINT 'Trigger Executing';

--     -- Check if the specified columns were updated
--     IF UPDATE(startDay) OR UPDATE(regRate)
--     BEGIN
--         -- Debugging: Print messages
--         PRINT 'Update condition met';

--         DECLARE @CurrentDay DATE;

--         -- Get the current date
--         SET @CurrentDay = GETDATE();

--         -- Debugging: Print messages
--         PRINT 'Setting endDay to ' + CONVERT(VARCHAR(10), @CurrentDay);

--         -- Update the endDay of the existing row
--         UPDATE LemRates
--         SET endDay = @CurrentDay
--         WHERE workerID IN (SELECT workerID FROM INSERTED) -- change to max 
--           AND endDay IS NULL;

--         -- Debugging: Print messages
--         PRINT 'Inserting new row';

--         -- Insert a new row with updated values
--         INSERT INTO LemRates (workerID, startDay, regRate)
--         SELECT 
--             i.workerID,
--             i.startDay,
--             i.regRate
--         FROM INSERTED i;
--     END
-- END;
-- GO
--- UPDATE END DATE FOR RATE PRIOD 



-- -- Updated createNewRate trigger for equipmentRates
-- CREATE TRIGGER createNewLemEquipmentRate
-- ON equipmentRates
-- INSTEAD OF UPDATE
-- AS
-- IF UPDATE(startDay) OR UPDATE (regRate) OR UPDATE (RATE_COST)  OR UPDATE (FUEL_BURN) OR UPDATE (EQP_TIME)
-- BEGIN
--     DECLARE @CurrentDay DATE;

--     -- Get the current date
--     SET @CurrentDay = GETDATE();

--     -- Update the endDay of the existing row
--     UPDATE equipmentRates
--     SET endDay = @CurrentDay
--     WHERE ID IN (SELECT ID FROM INSERTED)
--       AND endDay IS NULL
-- END;
-- BEGIN
--     -- Chec k if the specified columns were updated
--     IF UPDATE(startDay) OR UPDATE (regRate) OR UPDATE (RATE_COST)  OR UPDATE (FUEL_BURN) OR UPDATE (EQP_TIME)
--     BEGIN
--         INSERT INTO equipmentRates (ID, startDay, regRate, RATE_COST, FUEL_BURN, EQP_TIME)
--         SELECT 
--             i.ID,
--             GETDATE() AS startDay,
--             i.regRate,
--             i.RATE_COST,
--             i.FUEL_BURN,
--             i.EQP_TIME
--         FROM INSERTED i;
--     END
-- END
-- GO


-- Create the InsertEmployee trigger
CREATE TRIGGER InsertIntoSubTable
ON LemWorkingUnit
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert into the LemEmployee table for rows with category = 'Employee'
    INSERT INTO LemEmployee (workerID)
    SELECT workerID
    FROM INSERTED
    WHERE category = 'Employee';

    -- Insert into the LemEquipment table for rows with category = 'LemEquipment'
    INSERT INTO LemEquipment (unitNum)
    SELECT workerID
    FROM INSERTED
    WHERE category = 'LemEquipment';

    -- Insert into the ThirdParty table for rows with category = 'ThirdParty'
    INSERT INTO LemMaterials (unitID)
    SELECT workerID
    FROM INSERTED
    WHERE category = 'LemMaterials';
 
    INSERT INTO LemSubContractor (workerID)
    SELECT workerID
    FROM INSERTED
    WHERE category = 'SubContractor';
END;

-------------------------------------------------------VIEWS ------------------------------------------------------

GO 
CREATE VIEW LemEmployeeRates AS (
    SELECT
        r.workerID ,
        r.startDay ,
        r.endDay ,
        r.regRate ,
        r.regRate *1.5 AS otRate,
        r.regRate * 2 AS x2Rate
    FROM 
        LemRates r 
    INNER JOIN LemEmployee emp ON emp.workerID = r.workerID
)

GO
CREATE VIEW LemRecentRates AS
    SELECT
        workerID,
        startDay ,
        regRate,
        ROW_NUMBER() OVER ( PARTITION BY workerID ORDER BY startDay DESC) AS ROWNUM
    FROM
        LemRates
    WHERE
        endDay IS NULL

GO 
CREATE VIEW LemRecentEmployeeRates AS
    SELECT
        lrr.workerID,
        lrr.startDay ,
        ler.endDay ,
        ler.regRate ,
        ler.otRate ,
        ler.x2Rate ,
        ROW_NUMBER() OVER ( PARTITION BY lrr.workerID ORDER BY lrr.startDay DESC) AS ROWNUM
    FROM
        LemRecentRates lrr
    inner join 
        LemEmployeeRates ler on ler.workerID = lrr.workerID and ler.startDay = lrr.startDay
    WHERE
    endDay IS NULL

GO
-----------------------------------Holds LemEmployee Info And Rates 
CREATE VIEW LemEmployeeUnit AS (
    SELECT 
        wu.workerID,
        wu.name,
        emp.role, 
        rer.startDay,
        COALESCE(rer.endDay, CAST(GETDATE() as date)) AS endDay,
        COALESCE(rer.regRate, 0) AS regRate,
        COALESCE(rer.otRate, 0) AS otRate,
        COALESCE(rer.x2Rate, 0) AS x2Rate
        -- Add any other relevant columns from the tables
    FROM
        LemWorkingUnit wu
    INNER JOIN
        LemEmployee emp ON emp.workerID = wu.workerID AND wu.category = 'Employee'
    LEFT JOIN
        LemRecentEmployeeRates rer ON rer.workerID = emp.workerID and rer.ROWNUM = 1
);
GO

--------------------------------- LEM Table
CREATE VIEW LemEmployeeView AS (
    SELECT lm.lemID, 
        e.workerID, 
        wu.NAME, 
        e.role, 
        wko.regHrs, 
        er.regRate, 
        wko.otHrs, 
        er.otRate, 
        wko.regHrs + wko.otHrs AS TotalHrs, 
        (wko.regHrs * er.regRate) + (wko.otHrs * er.otRate) AS TotalPay
        FROM 
            LemForDay lm
        INNER JOIN 
            LemWorkedOn wko ON lm.lemID = (CONCAT(wko.pjCode, '-', RIGHT('000' + CAST(wko.lemNumber AS VARCHAR(3)), 3)))
        INNER JOIN
            LemEmployee e ON e.workerID = wko.workerID
        INNER JOIN 
            LemWorkingUnit wu ON wu.workerID = e.workerID
        INNER JOIN 
            LemRecentEmployeeRates er ON e.workerID = er.workerID    
)
GO
---------------------------------EQP LEM Table
CREATE VIEW LemEqpView AS (
    SELECT lm.lemID, 
        eq.unitNum, 
        wu.NAME, 
        eq.description, 
        el.HRS, 
        mr.regRate,   
        (el.HRS * mr.regRate) AS TotalPay
    FROM 
        LemForDay lm
    INNER JOIN 
        LemUsedEquip el ON lm.lemID = el.lemID
    INNER JOIN
        LemEquipment eq ON eq.unitNum = el.unitNum
    INNER JOIN 
        LemWorkingUnit wu ON wu.workerID = eq.unitNum
    INNER JOIN 
        LemRecentRates mr ON eq.unitNum = mr.workerID    
)

GO
---------------Sub Contractor lem view 
CREATE VIEW LemSubConView AS ( 
    SELECT 
        lm.lemID,
        s.description,
        wu.NAME,
        s.REF_NUM,
        s.QTY,
        s.UNIT_PRICE,
        (s.QTY * s.UNIT_PRICE) AS Amount
    FROM 
        LemForDay lm 
    INNER JOIN 
        LemSubContractor s on lm.lemID = s.lemID
    INNER JOIN LemWorkingUnit wu ON wu.workerID = s.workerID
)

GO 
----MAT LEM VIEW 
CREATE VIEW LemMatView AS (
    SELECT lm.lemID, 
        m.unitID, 
        m.vendor, 
        wu.NAME,
        ml.QTY,
        ml.UNIT_COST,  
        CAST((ml.QTY * ml.UNIT_COST) AS DECIMAL(10,2) ) AS TotalPay
        FROM 
            LemForDay lm
        INNER JOIN 
            LemUsedMat ml ON lm.lemID = ml.lemID
        INNER JOIN
            LemMaterials m ON m.unitID = ml.unitID
        INNER JOIN 
            LemWorkingUnit wu ON wu.workerID = m.unitID
);



-- CREATE VIEW Role AS (
-- SELECT p.role, 
--     lr.regRate, 
--     lr.otRate, 
--     wu.SHIFT, 
--     wu.HOURLY
-- FROM LemEmployee P 
--     JOIN LemWorkingUnit wu ON wu.ID = p.ID 
--     JOIN LemEmployeeRatesView lr on lr.ID = p.ID
-- WHERE
--     lr.startDay IN (
--         SELECT MAX(startDay) FROM LemEmployeeRatesView
--         WHERE startDay <= GETDATE()
--     )

-- );

-- CREATE VIEW EquipUnit AS (
--     SELECT 
--         w.ID,
--         w.NAME,
--         w.SHIFT,
--         eq.TYPE,
--         w.HOURLY,
--         mrer.MostRecentStartDate,
--         CASE 
--             WHEN mrer.MostRecentEndDate IS NULL THEN GETDATE()
--             ELSE mrer.MostRecentEndDate
--         END AS MostRecentEndDate,
--         CASE
--             WHEN mrer.regRate IS NULL THEN 0
--             ELSE mrer.regRate
--         END AS regRate,
--         CASE
--             WHEN mrer.MostRecentRateCost IS NULL THEN 0
--             ELSE mrer.MostRecentRateCost
--         END AS MostRecentRateCost,
--         CASE
--             WHEN mrer.MostRecentFuelBurn IS NULL THEN 0
--             ELSE mrer.MostRecentFuelBurn
--         END AS MostRecentFuelBurn,
--         CASE
--             WHEN mrer.MostRecentEqpTime IS NULL THEN 0
--             ELSE mrer.MostRecentEqpTime
--         END AS MostRecentEqpTime
--         --any other relavant columns 
--     FROM
--         LemWorkingUnit w
--     INNER JOIN LemEquipment eq on eq.ID = w.ID
--     INNER JOIN MostRecentLemEquipmentRates mrer on mrer.ID = w.ID AND mrer.ROWNUM = 1

-- );

-- CREATE VIEW ThirdPartyUnit AS (
--     SELECT 
--         wu.ID,
--         wu.NAME,
--         wu.SHIFT,
--         tp.CLASS, 
--         tp.TICKET,
--         wu.HOURLY,
--         mrlrv.MostRecentStartDate,
--         COALESCE(mrlrv.MostRecentEndDate, GETDATE()) AS MostRecentEndDate,
--         COALESCE(mrlrv.regRate, 0) AS regRate,
--         COALESCE(mrlrv.MostRecentOTRate, 0) AS MostRecentOTRate,
--         COALESCE(mrlrv.MostRecentx2Rate, 0) AS MostRecentx2Rate,
--         COALESCE(mrlrv.MostRecentRateCost, 0) AS MostRecentRateCost
--         -- Add any other relevant columns from the tables
--     FROM
--         LemWorkingUnit wu
--     INNER JOIN
--         ThirdParty tp ON tp.ID = wu.ID AND wu.category = 'ThirdParty'
--     LEFT JOIN
--         MostRecentLiveRates mrlrv ON mrlrv.ID = wu.ID and mrlrv.ROWNUM = 1
-- );
-- GO