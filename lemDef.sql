

Drop Table If Exists Role
CREATE TABLE Role(
    id VARCHAR(50) Primary KEY, 
    [name] NVARCHAR (50), 
);

-- clientRep Table
Drop Table If Exists ClientRep
CREATE TABLE ClientRep(
    empId VARCHAR(50),
    clientId VARCHAR(50) Unique, 
    workspaceId Varchar(50),
    PRIMARY KEY (empId, workspaceId),
    FOREIGN KEY (clientId ,workspaceId) REFERENCES Client(id, workspace_id) ON DELETE CASCADE,
    FOREIGN KEY (empId) REFERENCES EmployeeUser(id) 
);
-- Lemsheet Table


Drop Table If Exists LemSheet
CREATE TABLE LemSheet(
    id VARCHAR(50),
    clientId VARCHAR(50),
    workspaceId Varchar(50),
    PRIMARY KEY (id, workspaceId),
    lem_sheet_date DATE,
    lemNumber Varchar(10),
    discripation VARCHAR(50),
    notes NVARCHAR(250),
    projectId VARCHAR(50),
    projectManagerId VARCHAR(50),
    FOREIGN KEY (clientId, workspaceId) REFERENCES Client(id, workspace_id) ON DELETE CASCADE ,
    FOREIGN key(projectId, workspaceId) References Project(id, workspace_id) ,
    FOREIGN key(workspaceId) References Workspace(id) ,
    FOREIGN key(projectManagerId) References EmployeeUser(id) 
);

Drop Table If Exists LemWorker
create TABLE LemWorker (
    empId VARCHAR(50),
    roleId VARCHAR(50),
    workspaceId Varchar(50),
    Unique (empId, roleId, workspaceId),
    PRIMARY KEY (empId,  workspaceId),
    FOREIGN KEY (workspaceId) REFERENCES Workspace(id) ,
    FOREIGN KEY (empId) REFERENCES EmployeeUser(id) On Delete CASCADE,
    FOREIGN KEY (roleId) REFERENCES [Role](id) 
);



-- Equipment Table
Drop Table If Exists Equipment
CREATE TABLE Equipment(
    id VARCHAR(50),
    [name] VARCHAR(50),
    workspaceId Varchar(50),
    PRIMARY KEY (id, workspaceId),
    FOREIGN Key (workspaceId) REFERENCES Workspace(id)
);


-- EquipEntry Table
Drop Table If Exists EquipEntry
CREATE TABLE EquipEntry (
    -- id VARCHAR(50),
    lemId VARCHAR(50),
    workspaceId Varchar(50),
    PRIMARY KEY  (lemId, workspaceId),
    equipId VARCHAR (50),
    isUnitRate BIT default 0,
    qty DECIMAL (10, 2) Default 0.00,
    FOREIGN KEY (workspaceId) REFERENCES Workspace(id) , 
    FOREIGN KEY (lemId, workspaceId) REFERENCES LemSheet(id, workspaceId) On Delete CASCADE,
    FOREIGN KEY (equipId, workspaceId) REFERENCES Equipment(id, workspaceId) ,
);

Drop Table If Exists LemEntry
create TABLE LemEntry (
    lemId VARCHAR(50),
    workerId VARCHAR(50),
    workspaceId Varchar(50),
    PRIMARY KEY (lemId, workerId, workspaceId),
    work DECIMAL(10,2) Default 0.00,
    travel DECIMAL(10,2) Default 0.00,
    Calc DECIMAL(10,2) Default 0.00,
    Meals DECIMAL(10,2) Default 0.00,
    Hotel DECIMAL(10,2) Default 0.00,
    FOREIGN KEY (workspaceId) REFERENCES Workspace(id) ,
    FOREIGN KEY (lemId, workspaceId) REFERENCES LemSheet(id, workspaceId) ON DELETE CASCADE ,
    FOREIGN KEY (workerId, workspaceId) REFERENCES LemWorker(empId, workspaceId) ,
    -- Add other LemEntry columns as needed
);
Drop Table if Exists WorkerRateSheet
CREATE TABLE WorkerRateSheet(
    clientId VARCHAR(50),
    roleId VARCHAR(50),
    workspaceId Varchar(50),
    PRIMARY KEY (clientId, roleId, workspaceId),
    workRate DECIMAL(10,2),
    travelRate DECIMAL(10,2),
    calcRate DECIMAL(10,2),
    FOREIGN Key (clientId, workspaceId ) References Client(id, workspace_id),
    FOREIGN Key (roleId) References Role(id),
    FOREIGN Key (workspaceId) References Workspace(id) ,
);

Drop Table if Exists EqpRateSheet
CREATE TABLE EqpRateSheet(
    equipId VARCHAR(50),
    clientId VARCHAR(50),
    workspaceId Varchar(50),
    PRIMARY KEY (equipid, clientId, workspaceId),
    unitRate DECIMAL(10,2) Default 0.00,
    dayRate DECIMAL(10,2) Default 0.00,
    FOREIGN Key (equipId, workspaceId) References Equipment(id, workspaceId) ,
    FOREIGN Key (clientId, workspaceId) References Client(id, workspace_id) On Delete Cascade 
);