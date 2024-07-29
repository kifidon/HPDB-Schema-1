--TimeTracker_def

-- Workspace Table
-- drop table Workspace
go
CREATE TABLE Workspace (
    id VARCHAR(50) PRIMARY KEY,
    [name] varchar(50)
    -- Add other workspace-related columns as needed
);


select * from Client
-- Client Table
-- drop table Client
GO
create TABLE Client (
    id VARCHAR(50),
    email VARCHAR(50),
    [address] VARCHAR(100),
    [name] VARCHAR(255),
    workspace_id VARCHAR(50),
    PRIMARY KEY (id, workspace_id),
    FOREIGN KEY (workspace_id) REFERENCES Workspace(id) ON DELETE CASCADE 
    -- Add other client-related columns as needed
);
ALTER TABLE Client
ADD longName VARCHAR(255); 

-- User Table
-- drop table EmployeeUser
go
CREATE TABLE EmployeeUser (
    id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255),
    [name] VARCHAR(255),
    [status] VARCHAR(50),
    baseRate DECIMAL(10,2),
    -- may include some information about memberships
);
Alter table EmployeeUser
add start_date DATE
alter TABLE EmployeeUser 
drop column baseRate
Alter Table EmployeeUser 
add [role] VARCHAR(50)
Alter Table EmployeeUser
add [hasTruck] Bit Default 0
Alter Table EmployeeUser 
add [manager] Varchar()


-- TimeSheet Table
-- drop table TimeSheet 
go 
CREATE TABLE TimeSheet (
    id VARCHAR(50) ,
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
    PRIMARY KEY (emp_id, id, workspace_id),
    Unique (id, workspace_id),
    FOREIGN KEY (emp_id) REFERENCES EmployeeUser(id) ON DELETE CASCADE,
    FOREIGN KEY (workspace_id) REFERENCES Workspace(id)
    ON DELETE CASCADE
);

-- Project Table
-- drop table Project 
go 
CREATE TABLE Project (
    id VARCHAR(50),
    [name] NVARCHAR(MAX),
    title NVARCHAR(Max),
    code VARCHAR(50) ,
    client_id VARCHAR(50) NOT NULL,
    workspace_id varchar(50),
    primary key (id, workspace_id),
    FOREIGN KEY (client_id, workspace_id ) REFERENCES Client(id, workspace_id) 
    ON DELETE NO ACTION, 
    foreign key (workspace_id) REFERENCES Workspace(id) on delete cascade 
    -- include info a bout project Representative
);
select * from Entry

-- Entry Table
-- drop table Entry 
go 
CREATE TABLE Entry (
    id VARCHAR(50),
    time_sheet_id VARCHAR(50) ,
    duration Decimal(10,2),
    [description] NVARCHAR(MAX) COLLATE Latin1_General_CS_AS,
    billable BIT,
    project_id VARCHAR(50), -- used this as the WorkedOn relation 
    [type] VARCHAR(20),
    rate DECIMAL (10,2), -- rates for billing 
    start_time datetime,
    end_time DATETIME,
    -- Add other entry-related columns as needed
    workspace_id varchar(50),
    PRIMARY KEY (id, workspace_id), --maybe include workspace Id later
    FOREIGN Key(time_sheet_id, workspace_id) REFERENCES TimeSheet(id, workspace_id) ON DELETE CASCADE , 
    FOREIGN KEY (project_id, workspace_id) REFERENCES Project(id, workspace_id) 
);

--Tags table 
-- drop table TagsFor 
go 
Create Table TagsFor(
    id Varchar(50), 
    [entryID] Varchar(50),
    workspace_id varchar(50)
    primary key (id, entryID, workspace_id),
    [name] Varchar(50),
    foreign key ([entryID], workspace_id) REFERENCES Entry(id, workspace_id)
    on delete cascade
    )


/*
    -- Rates for payroll 
    CREATE TABLE Rates(
        id VARCHAR(50) PRIMARY KEY ,
        hourly BIT,
        rate_cost DECIMAL(10,2)
        FOREIGN KEY (id) REFERENCES EmployeeUser(id)
        ON DELETE CASCADE 
    ) Obsolete


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
-- drop table TimeOffPolicies
go
CREATE TABLE TimeOffPolicies(
    id VARCHAR(50) , -- TIME OFF POLICY ID 
    policy_name VARCHAR(50),
    accrual_amount REAL,
    accrual_period VARCHAR(15),
    time_unit VARCHAR(14),
    archived BIT,
    wID VARCHAR(50), 
    primary key (id , wID),
    FOREIGN KEY (wID) REFERENCES Workspace(id)
    ON DELETE CASCADE 
)

-- drop table TimeOffRequests
go 
CREATE TABLE TimeOffRequests(
    id VARCHAR(50) UNIQUE,
    eID VARCHAR(50) Not Null,
    pID VARCHAR(50) NOT NULL, 
    startDate DATETIME,
    end_date DATETIME,
    duration DECIMAL(10, 2), -- in days 
    paidTimeOff DECIMAL(10,2),
    balanceAfterRequest Decimal(10,2),
    [status] VARCHAR(50),
    workspace_id varchar(50),
    PRIMARY KEY (id, workspace_id),
    foreign key (workspace_id) REFERENCES Workspace(id) on delete  No Action ,
    FOREIGN KEY (eID) REFERENCES EmployeeUser(id) ON delete No action,
    FOREIGN KEY (pID, workspace_id) REFERENCES TimeOffPolicies(id, wID)
    ON delete Cascade 
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
    
    Select * FROM Project where id ='65e79fd044189d689d3eaeff'
    )
*/
-- drop table Calendar
go 
create table Calendar ( 
    [date] Date primary key ,
    dayOfWeek INT,
    [month] INT, 
    [year] INT
)
-- drop table Holidays
go 
create table Holidays(
    holidayID varchar(50),
    [date] DATE,
    [name] varchar(50),
    workspace_id VARCHAR(50),
    primary key (holidayID, workspace_id),
    foreign key (workspace_id) REFERENCES Workspace(id) on delete cascade,
    foreign key ([date]) references Calendar([date])
)

-- drop table UserGroups
go
CREATE TABLE UserGroups(
    id varchar(50) ,
    [name] Varchar(50) Unique,
    workspace_id varchar(50),
    Primary Key (id, workspace_id),
    foreign key (workspace_id) REFERENCES Workspace(id) on delete cascade 
)

Alter Table UserGroups 
    Alter Column name Varchar(250)


-- drop table GroupMembership
go
CREATE TABLE GroupMembership(
    user_id varchar(50), 
    group_id varchar(50),
    workspace_id varchar(50),
    primary key (user_id, group_id, workspace_id),
    foreign key (user_id) references EmployeeUser(id),
    foreign key (group_id, workspace_id) references UserGroups(id, workspace_id)
)

--ExpenseCategory Table
-- drop table ExpenseCategory
go
CREATE TABLE ExpenseCategory (
    id VARCHAR(50),
    [name] VARCHAR(255),
    hasUnitPrice BIT,
    priceInCents DECIMAL(10, 2),
    unit VARCHAR(50),
    workspaceId VARCHAR(50),
    archived BIT,
    PRIMARY key (id, workspaceId),
    FOREIGN KEY (workspaceId) REFERENCES Workspace(id)
    ON DELETE CASCADE 
    -- Add other category-related columns as needed
);
select * from ExpenseCategory

--Expense Table
-- drop table Expense
CREATE TABLE Expense (
    id VARCHAR(64),
    status Varchar(50) default 'PENDING',
    workspaceId VARCHAR(50) Not null,
    userId VARCHAR(50) Not null,
    [date] DATE,
    projectId VARCHAR(50) Not null,
    categoryId VARCHAR(50) Not null,
    notes VARCHAR(MAX),
    quantity REAL default -1,
    subTotal REAL default -1,
    taxes REAL default -1,
    primary key (id, workspaceId),
    FOREIGN key (workspaceId) references Workspace(id),
    FOREIGN KEY (projectId, workspaceId) REFERENCES Project(id, workspace_id) On Delete No ACTION,
    FOREIGN key (categoryId, workspaceId) REFERENCES ExpenseCategory(id, workspaceId) on delete CASCADE,
);

Go 
-- drop table If Exists  FilesForExpense
go 
Create TABLE FilesForExpense(
    expenseId Varchar(64) Primary Key ,
    binaryData Text,
    workspaceId VARCHAR(50),
    FOREIGN key (expenseId, workspaceId) REFERENCES Expense (id,workspaceId) On DELETE CASCADE 
)
Select * From FilesForExpense

go
-- drop table BackGroundTaskDjango
create table BackGroundTaskDjango(
    status_code int,
    message NVARCHAR(MAX),
    data Text,
    [time] DATETIME,
    caller Varchar(50)
)

