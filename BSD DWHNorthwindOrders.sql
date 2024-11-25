
/*Creación de un almacén de datos para la base de datos Northwind

Xaviel Terrero 2021-2362

Se requiere diseñar el modelo entidad relación y crear la base de datos 
para el data warehouse de la base de datos DWHNorthwindOrders. */

-- Creando la BSD
CREATE DATABASE DWHNorthwindOrders;
GO

USE DWHNorthwindOrders;
GO

/* -------------------------------------------------------------------------------------------------- */

/* Creando las Tablas de Dimensión. */

-- Dimensión de Clientes
CREATE TABLE CustomerDimension (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(100),
    ContactName NVARCHAR(100),
    Country NVARCHAR(50),
    City NVARCHAR(50)
);

-- Dimensión de Productos
CREATE TABLE ProductDimension (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    SupplierID INT,
    CategoryID INT,
    QuantityPerUnit NVARCHAR(50),
    UnitPrice DECIMAL(10, 2)
);

-- Dimensión de Empleados
CREATE TABLE EmployeeDimension (
    EmployeeID INT PRIMARY KEY,
    LastName NVARCHAR(50),
    FirstName NVARCHAR(50),
    Title NVARCHAR(50),
    Country NVARCHAR(50),
    City NVARCHAR(50)
);

-- Dimensión de Tiempo
CREATE TABLE TimeDimension (
    DateID DATE PRIMARY KEY,
    Year INT,
    Quarter INT,
    Month INT,
    Day INT,
    Weekday NVARCHAR(10)
);


/* Tabla OrderFacts */
CREATE TABLE OrderFacts (
    OrderID INT,
    ProductID INT,
    CustomerID INT,
    EmployeeID INT,
    DateID DATE,
    Quantity INT,
    UnitPrice DECIMAL(10, 2),
    TotalAmount AS (Quantity * UnitPrice), -- Calcula el monto total para cada pedido
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (ProductID) REFERENCES ProductDimension(ProductID),
    FOREIGN KEY (CustomerID) REFERENCES CustomerDimension(CustomerID),
    FOREIGN KEY (EmployeeID) REFERENCES EmployeeDimension(EmployeeID),
    FOREIGN KEY (DateID) REFERENCES TimeDimension(DateID)
);

/* -------------------------------------------------------------------------------------------------- */
/* Ver mis Foreign keys y Indices */

-- Foreign keys
SELECT 
    fk.name AS ForeignKeyName,
    tp.name AS TableName,
    cp.name AS ColumnName,
    rt.name AS ReferencedTableName,
    rc.name AS ReferencedColumnName
FROM 
    sys.foreign_keys AS fk
INNER JOIN 
    sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN 
    sys.tables AS tp ON fkc.parent_object_id = tp.object_id
INNER JOIN 
    sys.columns AS cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN 
    sys.tables AS rt ON fkc.referenced_object_id = rt.object_id
INNER JOIN 
    sys.columns AS rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
ORDER BY 
    tp.name, fk.name;


-- Mis indices

-- Creandolos
CREATE INDEX IDX_OrderFacts_CustomerID ON OrderFacts(CustomerID);
CREATE INDEX IDX_OrderFacts_ProductID ON OrderFacts(ProductID);
CREATE INDEX IDX_OrderFacts_EmployeeID ON OrderFacts(EmployeeID);
CREATE INDEX IDX_OrderFacts_DateID ON OrderFacts(DateID);


-- Ver mis Indices
SELECT 
    i.name AS IndexName,
    t.name AS TableName,
    c.name AS ColumnName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique
FROM 
    sys.indexes AS i
INNER JOIN 
    sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN 
    sys.tables AS t ON i.object_id = t.object_id
INNER JOIN 
    sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE 
    i.is_primary_key = 0  -- Excluye las claves primarias
ORDER BY 
    t.name, i.name;
