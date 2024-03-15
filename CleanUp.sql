--CleanUp

-- time sheet
    DROP TABLE IF EXISTS TimeOffRequests
    DROP TABLE IF EXISTS TimeOffPolicies
    DROP TABLE IF EXISTS TimeOffAccrual
    DROP TABLE IF EXISTS Expense;
    DROP TABLE IF EXISTS ExpenseCategory;
    DROP TABLE IF EXISTS Rates;
    DROP TABLE IF EXISTS [Entry];
    DROP TABLE IF EXISTS Task;
    DROP TABLE IF EXISTS Project;
    DROP TABLE IF EXISTS TimeSheet;
    DROP TABLE IF EXISTS EmployeeUser;
    DROP TABLE IF EXISTS Client;
    DROP TABLE IF EXISTS Workspace;

-- Lem sheet tables 
    DROP TABLE IF EXISTS subContractorsLem;
    DROP TABLE IF EXISTS matOnLem;
    DROP TABLE IF EXISTS EquipLem;
    DROP TABLE IF EXISTS worked_onLem;
    DROP TABLE IF EXISTS LemRates;
    DROP TABLE IF EXISTS worked_on;
    DROP TABLE IF EXISTS Equipment;
    DROP TABLE IF EXISTS Materials;
    DROP TABLE IF EXISTS Equipment;
    DROP TABLE IF EXISTS Employee;
    DROP TABLE IF EXISTS workingUnit;
    DROP TABLE IF EXISTS Category;
    DROP TABLE IF EXISTS LemForDay;
    DROP TABLE IF EXISTS projCode;
    DROP TABLE IF EXISTS representative;
    DROP TABLE IF EXISTS calendarDay;

    -- Drop triggers
    DROP TRIGGER IF EXISTS InsertIntoSubTable;
    DROP TRIGGER IF EXISTS createNewRate;
    DROP TRIGGER IF EXISTS trg_LemForDay_Insert;

    -- Drop views
    DROP VIEW IF EXISTS EmployeeRates;
    DROP VIEW IF EXISTS MostRecentRates;
    DROP VIEW IF EXISTS EmployeeUnit;
    DROP VIEW IF EXISTS MosteRecentEmployeeRates;
    DROP VIEW IF EXISTS EmpLemTable;
    DROP VIEW IF EXISTS EqpLemTable;
    DROP VIEW IF EXISTS MonthlyBillable;
    
SELECT
    fk.name AS constraint_name,
    OBJECT_NAME(fk.parent_object_id) AS table_name,
    c1.name AS column_name,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table_name,
    c2.name AS referenced_column_name
FROM 
    sys.foreign_keys AS fk
INNER JOIN 
    sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN 
    sys.columns AS c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
INNER JOIN 
    sys.columns AS c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id;
