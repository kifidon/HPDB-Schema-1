Drop Table if Exists EqpRateSheet
Drop Table if Exists WorkerRateSheet
Drop Table If Exists ClientRep
Drop Table If Exists LemEntry
Drop Table If Exists LemWorker
Drop Table If Exists EquipEntry
Drop Table If Exists LemSheet
Drop Table If Exists Equipment
Drop Table If Exists Role

CREATE TABLE Role(
    id VARCHAR(50) Primary KEY, 
    [name] NVARCHAR (50), 
);

-- clientRep Table
CREATE TABLE ClientRep(
    _id VARCHAR(50) PRIMARY Key,
    empId VARCHAR(50) Unique,
    clientId VARCHAR(50) Unique, 
    workspaceId Varchar(50),
    FOREIGN KEY (clientId ,workspaceId) REFERENCES Client(id, workspace_id) ON DELETE CASCADE,
    FOREIGN KEY (empId) REFERENCES EmployeeUser(id) 
);
-- Lemsheet Table


CREATE TABLE LemSheet(
    id VARCHAR(50) PRIMARY Key,
    clientId VARCHAR(50),
    workspaceId Varchar(50),
    Unique  (id, workspaceId),
    lem_sheet_date DATE,
    lemNumber Varchar(10),
    [description] Text,
    notes NVARCHAR(250),
    projectId VARCHAR(50),
    projectManagerId VARCHAR(50),
    Unique (lemNumber, projectId, clientId),
    FOREIGN KEY (clientId, workspaceId) REFERENCES Client(id, workspace_id) ON DELETE CASCADE ,
    FOREIGN key(projectId, workspaceId) References Project(id, workspace_id) ,
    FOREIGN key(workspaceId) References Workspace(id) ,
    FOREIGN key(projectManagerId) References EmployeeUser(id) 
);

create TABLE LemWorker (
    _id VARCHAR(50) Primary Key, 
    empId VARCHAR(50),
    roleId VARCHAR(50),
    Unique (empId, roleId),
    FOREIGN KEY (empId) REFERENCES EmployeeUser(id) On Delete CASCADE,
    FOREIGN KEY (roleId) REFERENCES [Role](id) 
);



-- Equipment Table
CREATE TABLE Equipment(
    id VARCHAR(50) Primary Key,
    [name] VARCHAR(50),
);


-- EquipEntry Table
CREATE TABLE EquipEntry (
    _id VARCHAR(50) Primary Key,
    lemId VARCHAR(50),
    workspaceId Varchar(50),
    UNIQUE (_id, lemId, workspaceId),
    equipId VARCHAR (50),
    isUnitRate BIT default 0,
    qty DECIMAL (10, 2) Default 0.00,
    FOREIGN KEY (workspaceId) REFERENCES Workspace(id) , 
    FOREIGN KEY (lemId, workspaceId) REFERENCES LemSheet(id, workspaceId) On Delete CASCADE,
    FOREIGN KEY (equipId) REFERENCES Equipment(id) ,
);

create TABLE LemEntry (
    _id VARCHAR(50) Primary Key,
    lemId VARCHAR(50),
    workerId VARCHAR(50),
    workspaceId Varchar(50),
    Unique (lemId, workerId, workspaceId),
    work DECIMAL(10,2) Default 0.00,
    travel DECIMAL(10,2) Default 0.00,
    Calc DECIMAL(10,2) Default 0.00,
    Meals DECIMAL(10,2) Default 0.00,
    Hotel DECIMAL(10,2) Default 0.00,
    FOREIGN KEY (workspaceId) REFERENCES Workspace(id) ,
    FOREIGN KEY (lemId, workspaceId) REFERENCES LemSheet(id, workspaceId) ON DELETE CASCADE ,
    FOREIGN KEY (workerId) REFERENCES LemWorker(_id) ,
    -- Add other LemEntry columns as needed
);

CREATE TABLE WorkerRateSheet(
    _id VARCHAR(50) Primary key,
    clientId VARCHAR(50),
    roleId VARCHAR(50),
    workspaceId Varchar(50),
    Unique (clientId, roleId, workspaceId),
    workRate DECIMAL(10,2),
    travelRate DECIMAL(10,2),
    calcRate DECIMAL(10,2),
    FOREIGN Key (clientId, workspaceId ) References Client(id, workspace_id),
    FOREIGN Key (roleId) References Role(id),
    FOREIGN Key (workspaceId) References Workspace(id) ,
);

CREATE TABLE EqpRateSheet(
    _id Varchar(50) Primary Key,
    equipId VARCHAR(50),
    clientId VARCHAR(50),
    workspaceId Varchar(50),
    Unique (equipid, clientId, workspaceId),
    unitRate DECIMAL(10,2) Default 0.00,
    dayRate DECIMAL(10,2) Default 0.00,
    FOREIGN Key (equipId) References Equipment(id) ,
    FOREIGN Key (clientId, workspaceId) References Client(id, workspace_id) On Delete Cascade 
);


select * from Client 
insert into Role(id, name) Values ('21232', 'Trucker')
insert into Equipment(id, name) Values ('919394', 'Truck')

select * from LemSheet

select * from Workspace
 
Select * from Equipment

Select * from EquipEntry

Drop table django_celery_beat_crontabschedule


SELECT DISTINCT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'EquipEntry';


INSERT INTO EquipEntry (_id, lemId, workspaceId, equipId, isUnitRate, qty)
VALUES (
    '74fd2c556808b001114bab4886163be403e07d8414c36',  -- _id
    '461fb94fbedf7499259ba46606260df60c6a00323e62c',  -- lemId
    '65c249bfedeea53ae19d7dad',                      -- workspaceId
    '919394',                                        -- equipId
    1,                                               -- isUnitRate (True in SQL is 1)
    9                                                -- qty
);

delete EquipEntry

Select * from EquipEntry

select * from Workspace
select * from Role
Delete Equipment where name like 'Test%'
Delete Role where name like 'Test%'


select * from WorkerRateSheet
select * from EqpRateSheet