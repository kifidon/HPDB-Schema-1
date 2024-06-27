workspace_id VARCHAR(50),
FOREIGN KEY (workspace_id) REFERENCES Workspace(id)


create TABLE lemEntry (
    id VARCHAR(50),
    lemid VARCHAR(50),
    PRIMARY KEY (id, workspace_id),
    IsForWorker VARCHAR(100),
    work DECIMAL(10,2),
    travel DECIMAL(10,2),
    Calc DECIMAL(10,2),
    Meals DECIMAL(10,2),
    Hotel DECIMAL(10,2)
    FOREIGN KEY (workspace_id) REFERENCES Workspace(id) ON DELETE CASCADE 
    -- Add other lemEntry columns as needed
);
-- Lemworker Table

create TABLE lemWorker (
    EmpId VARCHAR(50),
    roleid VARCHAR(50),
    PRIMARY KEY (id, workspace_id),
);

-- EquipEntry Table

CREATE TABLE EquipEntry (
    id VARCHAR(50),
    lemid VARCHAR(50),
    PRIMARY KEY (id, workspace_id),
    equipid VARCHAR (50),
    is_unitrate BIT default 0,
    Qty DECIMAL (10, 2),
    FOREIGN KEY (workspace_id) REFERENCES Workspace(id) ON DELETE CASCADE 
    FOREIGN KEY (lemid) REFERENCES lemEntry(lemid)
);

-- Equipment Table

CREATE TABLE Equipment(
    id VARCHAR(50),
    Eqp_name VARCHAR(50),
    PRIMARY KEY (id, workspace_id),
);

-- Lemsheet Table

CREATE TABLE LemSheet(
    id VARCHAR(50),
    Clientid VARCHAR(50),
    PRIMARY KEY (id, workspace_id),
    lem_sheet_date DATE,
    Discripation VARCHAR(50),
    notes bigint,
    projectid VARCHAR(50),
    projectmanagerid bigint,
    FOREIGN KEY (Clientid_id) REFERENCES Client(id) ON DELETE CASCADE 
);
-- clientRep Table

CREATE TABLE ClientRep(
    empid VARCHAR(50),
    Clientid VARCHAR(50),
    PRIMARY KEY (empid, workspace_id),
    FOREIGN KEY (Clientid_id) REFERENCES Client(id) ON DELETE CASCADE
);
-- EqpRateSheet Table

CREATE TABLE EqpRateSheet(
    equipid VARCHAR(50),
    Clientid VARCHAR(50),
    unitrate DECIMAL(10,2),
    dayrate DECIMAL(10,2),
    PRIMARY KEY (id, workspace_id),
);
-- WorkRateShet Table

CREATE TABLE workRateShet(
    Clientid VARCHAR(50),
    roleid VARCHAR(50),
    workrate DECIMAL(10,2),
    travelrate DECIMAL(10,2)
    Calc DECIMAL(10,2),
    PRIMARY KEY (id, workspace_id),
);
-- WorkRateShet Table

CREATE TABLE Role(
    id VARCHAR(50),
    Role_Name NVARCHAR (50), 
    PRIMARY KEY (id, workspace_id),
);