/* Cargar de facts del almacén de datos */

-- Xaviel Terrero | 2021-2362

/* Se requiere realizar la carga de las siguientes fact's de su base de datos DataWarehouse.

FactOrders,
Fact de clientes atendidos.
Fact de orders details, si la tiene creada.
Nota: Antes de cargar estaos fact tables deben de crear un proceso que permita limpiar 
las tablas antes de cargarlas.

Deben de subir un documento pdf con la descripción de su proceso debidamente funcional 
como se muestra en el documento adjunto con la descripción de cada una de la tablas cargadas. 

El informe debe incluir el enlace de github para su revisión. */

-----------------------------------------------------------------------------------------------------------------------

-- Carga de los fact's tables del DWHNorthwindOrders

-----------------------------------------------------------------------------------------------------------------------

/* Lo primero es limpiar las tablas de hechos  */

-- Vamo' a chequear las tablas:
USE DWHNorthwindOrders;
GO
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

/* Resultado:
CustomerDimension
ProductDimension
EmployeeDimension
TimeDimension
OrderFacts
DimShippers
DimCategory
CustomerFacts
*/

-- OrderFacts
TRUNCATE TABLE OrderFacts;

-- CustomerFacts
TRUNCATE TABLE CustomerFacts; /* Funcionaron sin problema */

/* Verificando */
SELECT COUNT(*) AS Registros FROM OrderFacts; -- Resultado 0

-----------------------------------------------------------------------------------------------------------------------

/* Ahora si, a cargar los facts tables */

-- Carga en OrderFacts:
USE DWHNorthwindOrders;
GO

INSERT INTO OrderFacts (OrderID, CustomerID, EmployeeID, ProductID, DateID, Quantity, UnitPrice)
SELECT 
    o.OrderID, 
    c.CustomerID, 
    e.EmployeeID, 
    od.ProductID, 
    CONVERT(DATE, o.OrderDate) AS DateID, -- Ajuste para DateID
    od.Quantity, 
    od.UnitPrice
FROM 
    Northwind.dbo.Orders o
INNER JOIN 
    CustomerDimension c ON o.CustomerID = c.CustomerID
INNER JOIN 
    EmployeeDimension e ON o.EmployeeID = e.EmployeeID
INNER JOIN 
    [Northwind].[dbo].[Order Details] od ON o.OrderID = od.OrderID
INNER JOIN 
    ProductDimension p ON od.ProductID = p.ProductID;

-- Genero el siguiente error:

/* Msg 547, Level 16, State 0, Line 61
The INSERT statement conflicted with the FOREIGN KEY constraint "FK__OrderFact__DateI__4222D4EF". The conflict occurred in database "DWHNorthwindOrders", table "dbo.TimeDimension", column 'DateID'.
The statement has been terminated. */

/* Resolviendo */

-- Verificando las fechas
SELECT DISTINCT DateID
FROM DWHNorthwindOrders.dbo.TimeDimension;

-- Agregando las fechas que faltan
INSERT INTO DWHNorthwindOrders.dbo.TimeDimension (DateID)
SELECT DISTINCT CONVERT(DATE, OrderDate)
FROM Northwind.dbo.Orders
WHERE CONVERT(DATE, OrderDate) NOT IN (SELECT DateID FROM DWHNorthwindOrders.dbo.TimeDimension); -- Se ejecuto, (476 rows affected)


/* Ahora a probar el query de nuevo, pa' cargar OrderFacts */
USE DWHNorthwindOrders;
GO

INSERT INTO OrderFacts (OrderID, CustomerID, EmployeeID, ProductID, DateID, Quantity, UnitPrice)
SELECT 
    o.OrderID, 
    c.CustomerID, 
    e.EmployeeID, 
    od.ProductID, 
    CONVERT(DATE, o.OrderDate) AS DateID, -- Ajuste para DateID
    od.Quantity, 
    od.UnitPrice
FROM 
    Northwind.dbo.Orders o
INNER JOIN 
    CustomerDimension c ON o.CustomerID = c.CustomerID
INNER JOIN 
    EmployeeDimension e ON o.EmployeeID = e.EmployeeID
INNER JOIN 
    [Northwind].[dbo].[Order Details] od ON o.OrderID = od.OrderID
INNER JOIN 
    ProductDimension p ON od.ProductID = p.ProductID; -- Se ejecuto bien, (2155 rows affected)

-- Chequeando OrderFacts:
SELECT TOP 10 * FROM OrderFacts;

/* Ahora a cargar CostumerFacts */

-- Cargar datos de CustomerFacts
USE DWHNorthwindOrders;
GO

-- Chequeando
EXEC sp_columns 'CustomerFacts';


INSERT INTO CustomerFacts (CustomerID, TotalOrders, TotalQuantityPurchased, TotalAmountSpent)
SELECT 
    c.CustomerID, 
    COUNT(o.OrderID) AS TotalOrders, 
    SUM(od.Quantity) AS TotalQuantityPurchased, 
    SUM(od.Quantity * od.UnitPrice) AS TotalAmountSpent
FROM 
    Northwind.dbo.Orders o
INNER JOIN 
    Northwind.dbo.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN 
    CustomerDimension c ON o.CustomerID = c.CustomerID
GROUP BY 
    c.CustomerID; -- Se ejecuto bien, (5 rows affected)

/* Ahora a cargar FactOrderDetails */

--Como no esta creada aun, vamos a crearla
USE DWHNorthwindOrders;
GO

CREATE TABLE FactOrderDetails (
    OrderID INT,
    CustomerID NVARCHAR(10),
    ProductID INT,
    Quantity INT,
    UnitPrice DECIMAL(10, 2),
    TotalPrice DECIMAL(18, 2),
    CONSTRAINT PK_FactOrderDetails PRIMARY KEY (OrderID, CustomerID, ProductID)
);
GO -- Se ejecuto bien.

-- Ahora si a cargar FactOrderDetails
USE DWHNorthwindOrders;
GO

INSERT INTO FactOrderDetails (OrderID, CustomerID, ProductID, Quantity, UnitPrice, TotalPrice)
SELECT 
    o.OrderID, 
    c.CustomerID, 
    od.ProductID, 
    od.Quantity, 
    od.UnitPrice, 
    od.Quantity * od.UnitPrice AS TotalPrice
FROM 
    Northwind.dbo.Orders o
INNER JOIN 
    CustomerDimension c ON o.CustomerID = c.CustomerID
INNER JOIN 
    [Northwind].[dbo].[Order Details] od ON o.OrderID = od.OrderID
INNER JOIN 
    ProductDimension p ON od.ProductID = p.ProductID;
GO -- Se ejecuto bien, (2155 rows affected)

/* Chequeando la carga */
SELECT * FROM DWHNorthwindOrders.dbo.FactOrderDetails;

-----------------------------------------------------------------------------------------------------------------------

/* Por ultimo vamos a verificar las cargas */

-- Verificar FactOrders
SELECT COUNT(*) AS TotalFactOrders FROM DWHNorthwindOrders.dbo.OrderFacts; -- Me dio: 2155

-- Verificar CustomerFacts
SELECT COUNT(*) AS TotalCustomerFacts FROM DWHNorthwindOrders.dbo.CustomerFacts; -- Me dio: 5

-- Verificar FactOrderDetails
SELECT COUNT(*) AS TotalFactOrderDetails FROM DWHNorthwindOrders.dbo.FactOrderDetails; -- Me dio: 2155