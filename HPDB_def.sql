--TimeTracker_def
/*
DROP TABLE IF EXISTS GroupMembership
DROP TABLE IF EXISTS UserGroups
DROP TABLE IF EXISTS Holidays
DROP TABLE IF EXISTS Calendar
DROP TABLE IF EXISTS Attendance
DROP TABLE IF EXISTS TimeOffRequests
DROP TABLE IF EXISTS TimeOffPolicies
DROP TABLE IF EXISTS TimeOffAccrual
DROP TABLE IF EXISTS Expense;
DROP TABLE IF EXISTS ExpenseCategory;
DROP TABLE IF EXISTS Rates;
DROP TABLE IF EXISTS Entry;
DROP TABLE IF EXISTS Task;
DROP TABLE IF EXISTS Project;
DROP TABLE IF EXISTS TimeSheet;
DROP TABLE IF EXISTS EmployeeUser;
DROP TABLE IF EXISTS Client;
DROP TABLE IF EXISTS Workspace;

DROP VIEW IF EXISTS AttendanceApproved;
DROP VIEW IF EXISTS AttendanceReport;
DROP VIEW IF EXISTS MonthlyBillable;

SELECT * FROM Workspace;
SELECT * FROM EmployeeUser where status != 'ACTIVE';

delete From EmployeeUser 
where email = 'don.salembier@hillplain.com'
delete From EmployeeUser 
where email = 'james.williams@hillplain.com'

delete From EmployeeUser 
where email = 'doug.reti@hillplain.com'



SELECT * FROM Project;
SELECT * FROM Client;
SELECT * FROM TimeOffRequests;
SELECT * FROM TimeSheet;
SELECT * FROM Entry;
SELECT * FROM Expense;
SELECT * FROM Rates;
SELECT * FROM TimeSheet ts 
inner join EmployeeUser eu on eu.id = ts.emp_id
where name = 'Shawna Applejohn';

select * from Entry en where en.time_sheet_id = '65e63cc1e09faa2cc3d11eec'


*/

-- Workspace Table
CREATE TABLE Workspace (
    id VARCHAR(50) PRIMARY KEY,
    [name] varchar(50)
    -- Add other workspace-related columns as needed
);
-- Client Table
CREATE TABLE Client (
    id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(50),
    [address] VARCHAR(100),
    [name] VARCHAR(255)
    -- Add other client-related columns as needed
);


-- User Table
CREATE TABLE EmployeeUser (
    id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255),
    [name] VARCHAR(255),
    [status] VARCHAR(50),
    baseRate DECIMAL(10,2),
    -- may include some information about memberships
);

-- TimeSheet Table
CREATE TABLE TimeSheet (
    id VARCHAR(50) PRIMARY KEY,
    emp_id VARCHAR(50) NOT NULL,
    start_time DATE,
    end_time DATE,
    approved_time REAL,
    billable_time REAL,
    billable_amount DECIMAL(10, 2),
    cost_amount DECIMAL(10, 2),
    expense_total DECIMAL(10, 2),
    workspace_id VARCHAR(50),
    [status] VARCHAR(50),
    FOREIGN KEY (emp_id) REFERENCES EmployeeUser(id) ON DELETE CASCADE ,
    FOREIGN KEY (workspace_id) REFERENCES Workspace(id)
    ON DELETE NO ACTION 
);

-- Project Table
CREATE TABLE Project (
    id VARCHAR(50) PRIMARY KEY,
    [name] NVARCHAR(MAX),
    code VARCHAR(50) UNIQUE,
    client_id VARCHAR(50) NOT NULL,
    FOREIGN KEY (client_id) REFERENCES Client(id)
    -- include info a bout project Representative
    ON DELETE NO ACTION 
);
/*
    Task Table
    CREATE TABLE Task (
        id VARCHAR(50) PRIMARY KEY,
        [name] VARCHAR(255)
        -- Add other task-related columns as needed
    );
*/
-- Entry Table
CREATE TABLE Entry (
    id VARCHAR(50),
    time_sheet_id VARCHAR(50) ,
    duration REAL,
    [description] TEXT,
    billable BIT,
    project_id VARCHAR(50), -- used this as the WorkedOn relation 
    [type] VARCHAR(20),
    rate DECIMAL (10,2), -- rates for billing 
    start_time datetime,
    end_time DATETIME -- maybe change to datetime in the future 
    -- Add other entry-related columns as needed
    PRIMARY KEY (id, time_sheet_id)
    FOREIGN KEY (time_sheet_id) REFERENCES TimeSheet(id) ON UPDATE CASCADE ON DELETE CASCADE ,
    FOREIGN KEY (project_id) REFERENCES Project(id) ON DELETE CASCADE 
);

/*
    -- Rates for payroll 
    CREATE TABLE Rates(
        id VARCHAR(50) PRIMARY KEY ,
        hourly BIT,
        rate_cost DECIMAL(10,2)
        FOREIGN KEY (id) REFERENCES EmployeeUser(id)
        ON DELETE CASCADE 
    ) Obsolete

    ExpenseCategory Table
    CREATE TABLE ExpenseCategory (
        id VARCHAR(50) PRIMARY KEY,
        [name] VARCHAR(255),
        unit VARCHAR(50),
        priceInCents DECIMAL(10, 2),
        billable BIT,
        workspace_id VARCHAR(50),
        FOREIGN KEY (workspace_id) REFERENCES Workspace(id)
        ON DELETE CASCADE 
        -- Add other category-related columns as needed
    );


    Expense Table
    CREATE TABLE Expense (
        id VARCHAR(50) PRIMARY KEY,
        billable BIT,
        timesheet_id VARCHAR(50),
        category_id VARCHAR(50),
        [date] DATE,
        notes TEXT,
        project_id VARCHAR(50),
        quantity INT,
        total DECIMAL(10, 2),
        -- Add other expense-related columns as needed
        FOREIGN KEY (project_id) REFERENCES Project(id) ON DELETE CASCADE,
        FOREIGN KEY (timesheet_id) REFERENCES TimeSheet(id) ON DELETE CASCADE ,
        FOREIGN KEY (category_id) REFERENCES ExpenseCategory(id) 
        ON DELETE CASCADE 
    );

    CREATE TABLE TimeOffBalances (
        id VARCHAR(50),
        pid varchar(50),
        balance  decimal(10,2) default 0,
        yearToDate varchar(4),
        primary key (id, pid),
        FOREIGN KEY (id) REFERENCES EmployeeUser(id) ON DELETE CASCADE,
        foreign key (pid) references TimeOffPolicies(id) on delete cascade
    )
*/
CREATE TABLE TimeOffPolicies(
    id VARCHAR(50) PRIMARY KEY, -- TIME OFF POLICY ID 
    policy_name VARCHAR(50),
    accrual_amount REAL,
    accrual_period VARCHAR(15),
    time_unit VARCHAR(14),
    archived BIT,
    wID VARCHAR(50), 
    FOREIGN KEY (wID) REFERENCES Workspace(id)
    ON DELETE CASCADE 
)

CREATE TABLE TimeOffRequests(
    id VARCHAR(50) UNIQUE,
    eID VARCHAR(50),
    pID VARCHAR(50) NOT NULL, 
    startDate DATETIME,
    end_date DATETIME,
    duration DECIMAL(10, 2), -- in days 
    paidTimeOff DECIMAL(10,2),
    balanceAfterRequest Decimal(10,2),
    [status] VARCHAR(50),
    PRIMARY KEY (id, eID),
    FOREIGN KEY (eID) REFERENCES EmployeeUser(id) ON DELETE CASCADE ,
    FOREIGN KEY (pID) REFERENCES TimeOffPolicies(id)
    ON DELETE CASCADE  
)
/*
    CREATE TABLE Attendance(
        id VARCHAR(50),
        [date] DATE,
        overtime DECIMAL(10,2),
        timeOff DECIMAL(10,2),
        totalDuration Decimal(10,2)
        PRIMARY KEY (id, [date])
        FOREIGN KEY (id) REFERENCES EmployeeUser (id)
        ON DELETE CASCADE
    )
*/
create table Calendar ( 
    [date] Date primary key ,
    dayOfWeek INT,
    [month] INT, 
    [year] INT
)

create table Holidays(
    holidayID varchar(50),
    [date] DATE,
    [name] varchar(50),
    primary key (holidayID),
    foreign key ([date]) references Calendar([date])
)

CREATE TABLE UserGroups(
    id varchar(50) ,
    [name] Varchar(50) Unique,
    workspace_id varchar(50),
    Primary Key (id, workspace_id)
)

CREATE TABLE GroupMembership(
    user_id varchar(50), 
    group_id varchar(50),
    workspace_id varchar(50),
    primary key (user_id, group_id, workspace_id),
    foreign key (user_id) references EmployeeUser(id),
    foreign key (group_id, workspace_id) references UserGroups(id, workspace_id)
)

