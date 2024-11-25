/* Cargar de dimensiones del almacén de datos */

-- Xaviel Terrero | 2021-2362

/* Se requiere realizar la carga de las siguientes dimensiones de su base de datos DataWarehouse.

DimCustomers
DimEmployee
DimShippers
DimCategory
DimProduct
Nota: Antes de cargar estas dimensiones deben de crear un proceso que permita limpiar las tablas antes de cargarlas.

Deben de subir un documento pdf con la descripción de su proceso debidamente funcional como se muestra en el documento 
adjunto con la descripción de cada una de la tablas cargadas.  */

-----------------------------------------------------------------------------------------------------------------------

-- Carga de dimensiones del almacén de datos DWHNorthwindOrders

-----------------------------------------------------------------------------------------------------------------------

/* Empezare limpiando primero las tablas de dimensiones */

-- Primero hay que verificar las tablas
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('CustomerDimension', 'ProductDimension', 'EmployeeDimension', 'DimShippers', 'DimCategory');

/* Veo que me faltan las dimensiones 'DimShippers', 'DimCategory'. Asi que toca crearlas */

-- DimShippers
CREATE TABLE DimShippers (
    ShipperID INT PRIMARY KEY,
    CompanyName NVARCHAR(100),
    Phone NVARCHAR(50)
);

-- DimCategory
CREATE TABLE DimCategory (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(100),
    Description NVARCHAR(MAX)
);

/* Ahora si, a limpiar */
DELETE FROM CustomerDimension;
DELETE FROM ProductDimension;
DELETE FROM EmployeeDimension;
DELETE FROM DimShippers;
DELETE FROM DimCategory;

-----------------------------------------------------------------------------------------------------------------------

/* Verificando las tablas de Dimensiones */
SELECT COUNT(*) AS TotalRegistros, 'CustomerDimension' AS Tabla FROM CustomerDimension
UNION ALL
SELECT COUNT(*), 'ProductDimension' FROM ProductDimension
UNION ALL
SELECT COUNT(*), 'EmployeeDimension' FROM EmployeeDimension
UNION ALL
SELECT COUNT(*), 'DimShippers' FROM DimShippers
UNION ALL
SELECT COUNT(*), 'DimCategory' FROM DimCategory;

/* Verificando las tablas en la DB Northwind */
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('Customers', 'Products', 'Employees', 'Shippers', 'Categories');

-----------------------------------------------------------------------------------------------------------------------

/* Carga de las dimensiones */

 -- Carga de CustomerDimension
 INSERT INTO CustomerDimension (CustomerID, CustomerName, ContactName, Country, City)
SELECT CustomerID, CompanyName, ContactName, Country, City
FROM Northwind.dbo.Customers;

--------------------------------------------Solucionando errores--------------------------------------------------------
/* Me dio error de conversion por el tipo de datos, toca solucionarlo */

-- Primero hay que eliminar la ForeignKeys en OrderFacts
ALTER TABLE OrderFacts
DROP CONSTRAINT FK__OrderFact__Custo__403A8C7D;

-- Y la clave primaria en CustomerDimension
ALTER TABLE CustomerDimension
DROP CONSTRAINT PK__Customer__A4AE64B83B4EC8BB;

-- Ahora si, a modificar el tipo de dato:
ALTER TABLE CustomerDimension
ALTER COLUMN CustomerID NVARCHAR(10);

/* Volviendo a poners los Keys*/

-- PrimaryKey de CustomerDimension
ALTER TABLE CustomerDimension
ADD CONSTRAINT PK_CustomerDimension PRIMARY KEY (CustomerID);

-- ForeignKey de OrderFacts
ALTER TABLE OrderFacts
ADD CONSTRAINT FK_OrderFacts_CustomerDimension
FOREIGN KEY (CustomerID) REFERENCES CustomerDimension(CustomerID);

/* No me esta dejando volver a poner las Keys */

-- No valores nulos en esa columna de CustomerDimension (Ahora si funciona)
ALTER TABLE CustomerDimension
ALTER COLUMN CustomerID NVARCHAR(10) NOT NULL;

-- Cambiando el tipo de dato en CostumerID
ALTER TABLE OrderFacts
ALTER COLUMN CustomerID NVARCHAR(10);

-- Hay que eliminar el indice que depende de CostumerID pa poder solucionarlo 
-- y que me deje cambiar el tipo de dato en CostumerID
DROP INDEX IDX_OrderFacts_CustomerID ON OrderFacts;
 
 -- A crear el indice de nuevo:
 CREATE INDEX IDX_OrderFacts_CustomerID ON OrderFacts(CustomerID);

 /* Ahora volvi al codigo de arriba pa' crear la clave foranea */

 --Verificando el indice:
 SELECT * 
FROM sys.indexes 
WHERE name = 'IDX_OrderFacts_CustomerID';

--Verificando el ForeignKey
SELECT * 
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_NAME = 'FK_OrderFacts_CustomerDimension';


 --------------------------------------------Solucionando errores--------------------------------------------------------

/* Ahora si, a continuar con las cargas de las dimensiones */

-- Carga de CustomerDimension
INSERT INTO CustomerDimension (CustomerID, CustomerName, ContactName, Country, City)
SELECT CustomerID, CompanyName, ContactName, Country, City
FROM Northwind.dbo.Customers; -- Se completo bien (99 Rows affected)

-- Carga de ProductDimension
INSERT INTO ProductDimension (ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice)
SELECT ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice
FROM Northwind.dbo.Products; -- Se completo bien (77 Rows affected)

-- Carga de EmployeeDimension
INSERT INTO EmployeeDimension (EmployeeID, LastName, FirstName, Title, Country, City)
SELECT EmployeeID, LastName, FirstName, Title, Country, City
FROM Northwind.dbo.Employees; -- Se completo bien (9 Rows affected)

-- Carga de DimShippers
INSERT INTO DimShippers (ShipperID, CompanyName, Phone)
SELECT ShipperID, CompanyName, Phone
FROM Northwind.dbo.Shippers; -- Se completo bien (3 Rows affected)

-- Carga de DimCategory
INSERT INTO DimCategory (CategoryID, CategoryName, Description)
SELECT CategoryID, CategoryName, Description
FROM Northwind.dbo.Categories; -- Se completo bien (8 Rows affected)

/* Verificando la carga de las dimensiones */
SELECT * FROM CustomerDimension;
SELECT * FROM ProductDimension;
SELECT * FROM EmployeeDimension;
SELECT * FROM DimShippers;
SELECT * FROM DimCategory;

