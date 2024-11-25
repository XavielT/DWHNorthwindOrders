/* Extraccion de datos para la carga de los fact's tables del almacén de datos */

-- Xaviel Terrero | 2021-2362

/* Se requiere realizar las vistas para la extraer los datos para cargar el Fact de Ventas 
y el Fact de clientes antendidos, como también hacer el mapeo de sus vistas en el proceso 
de carga como se muestra en el siguiente video. carga los siguientes fact's en su base 
de datos DataWarehouse.

Deben de subir el informe del la practica anterior con el proyecto completado con la descripción 
de su proceso debidamente funcional como se muestra en el documento adjunto. */

-----------------------------------------------------------------------------------------------------------------------

-- Extraccion de datos para la carga de los fact's tables del DWHNorthwindOrders

-----------------------------------------------------------------------------------------------------------------------

/* Primero creare la nueva tabla CustomerFacts */
CREATE TABLE CustomerFacts (
    CustomerID NVARCHAR(10),
    TotalOrders INT,
    TotalQuantityPurchased INT,
    TotalAmountSpent DECIMAL(18, 2),
    PRIMARY KEY (CustomerID),
    FOREIGN KEY (CustomerID) REFERENCES CustomerDimension(CustomerID)
); -- Funciona

-----------------------------------------------------------------------------------------------------------------------

/* Ahora a crear las vistas de la Extracción */

-- Verificando
USE Northwind;
GO

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'OrderDetails';

/* La tabla no esta, toca crearla */
USE Northwind;
GO

-- Creando la tabla
CREATE TABLE OrderDetails (
    OrderID INT NOT NULL, -- ID del pedido
    ProductID INT NOT NULL, -- ID del producto
    UnitPrice DECIMAL(10, 2) NOT NULL, -- Precio unitario del producto
    Quantity INT NOT NULL, -- Cantidad del producto en el pedido
    Discount FLOAT NOT NULL DEFAULT 0, -- Descuento aplicado (opcional)
    PRIMARY KEY (OrderID, ProductID), -- Clave primaria compuesta
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID), -- Relación con Orders
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) -- Relación con Products
);
GO

-- Llenando la tabla OrderDetails
INSERT INTO OrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
VALUES 
    -- Pedido 10248
    (10248, 1, 18.00, 10, 0.0), -- Producto 1
    (10248, 2, 19.00, 5, 0.1),  -- Producto 2
    (10248, 3, 15.00, 2, 0.05), -- Producto 3
    
    -- Pedido 10249
    (10249, 1, 22.00, 7, 0.05), -- Producto 1
    (10249, 4, 30.00, 3, 0.0),  -- Producto 4
    (10249, 5, 25.50, 6, 0.1),  -- Producto 5
    
    -- Pedido 10250
    (10250, 2, 19.00, 15, 0.0), -- Producto 2
    (10250, 3, 15.00, 4, 0.05), -- Producto 3
    (10250, 6, 35.00, 8, 0.2),  -- Producto 6
    
    -- Pedido 10251
    (10251, 4, 30.00, 10, 0.0), -- Producto 4
    (10251, 5, 25.50, 5, 0.15), -- Producto 5
    (10251, 7, 40.00, 7, 0.05), -- Producto 7
    
    -- Pedido 10252
    (10252, 8, 50.00, 12, 0.0), -- Producto 8
    (10252, 9, 45.00, 9, 0.1),  -- Producto 9
    (10252, 1, 18.00, 6, 0.05); -- Producto 1
	-- Se completo, con 15 Rows affected

	-- Verificando
	SELECT * FROM OrderDetails;

	-- Como OrderDetails depende de las tablas Orders y Products, vamo' a verificarlas.
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
WHERE 
    tp.name = 'OrderDetails';

	-- Estan bien relacionadas

-----------------------------------------------------------------------------------------------------------------------

/* Ahora si a crear las vistas */

USE DWHNorthwindOrders
GO

-- Vista para OrderFacts:
CREATE VIEW vw_FactSales AS
SELECT 
    O.OrderID,
    OD.ProductID,
    O.CustomerID,
    O.EmployeeID,
    CONVERT(DATE, O.OrderDate) AS DateID,
    OD.Quantity,
    OD.UnitPrice,
    (OD.Quantity * OD.UnitPrice) AS TotalAmount
FROM Northwind.dbo.Orders O
INNER JOIN Northwind.dbo.OrderDetails OD ON O.OrderID = OD.OrderID; -- Se creo bien

-- Vista para CustomerFacts:
CREATE VIEW vw_FactCustomerAttended AS
SELECT 
    C.CustomerID,
    COUNT(DISTINCT O.OrderID) AS TotalOrders,
    SUM(OD.Quantity) AS TotalQuantityPurchased,
    SUM(OD.Quantity * OD.UnitPrice) AS TotalAmountSpent
FROM Northwind.dbo.Customers C
LEFT JOIN Northwind.dbo.Orders O ON C.CustomerID = O.CustomerID
LEFT JOIN Northwind.dbo.OrderDetails OD ON O.OrderID = OD.OrderID
GROUP BY C.CustomerID; -- Se creo bien

-- Verificando las vistas
SELECT * FROM vw_FactSales;
SELECT * FROM vw_FactCustomerAttended;

-----------------------------------------------------------------------------------------------------------------------

/* Ahora a cargar los FactTables */

USE DWHNorthwindOrders
GO

/* Verificando */
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('OrderFacts', 'CustomerFacts');

-- Confirmando que vw_FactSales existe
SELECT OBJECT_ID('vw_FactSales') AS ViewID;
-----------------------------------------------------------------------------------------------------------------------
SELECT * FROM vw_FactSales;
-----------------------------------------------------------------------------------------------------------------------
-- Confirmando que vw_FactCustomerAttended existe
SELECT OBJECT_ID('vw_FactCustomerAttended') AS ViewID;
-----------------------------------------------------------------------------------------------------------------------
SELECT * FROM vw_FactCustomerAttended;
-----------------------------------------------------------------------------------------------------------------------

/* Cargando los datos */

-- Carga de OrderFacts desde vw_FactSales
INSERT INTO OrderFacts (OrderID, ProductID, CustomerID, EmployeeID, DateID, Quantity, UnitPrice, TotalAmount)
SELECT 
    OrderID, ProductID, CustomerID, EmployeeID, DateID, Quantity, UnitPrice, TotalAmount
FROM vw_FactSales;

-----------------------------------------------------------------------------------------------------------------------

/* Solucionando este error */

-- al intentar ejecutar la Carga de OrderFacts desde vw_FactSales, sale este error:
/*  Msg 271, Level 16, State 1, Line 177
The column "TotalAmount" cannot be modified because it is either a computed column or is the result of a UNION operator.

Completion time: 2024-11-19T11:41:07.4780540-04:00 */

-- Hay que arreglar eso

-- verificando la definicion de TotalAmount
EXEC sp_help 'OrderFacts';

-- Hay que excluirlo de la carga
INSERT INTO OrderFacts (OrderID, ProductID, CustomerID, EmployeeID, DateID, Quantity, UnitPrice)
SELECT 
    OrderID, ProductID, CustomerID, EmployeeID, DateID, Quantity, UnitPrice
FROM vw_FactSales;

/* Nuevo error */
/* Msg 547, Level 16, State 0, Line 196
The INSERT statement conflicted with the FOREIGN KEY constraint "FK__OrderFact__DateI__4222D4EF". The conflict occurred in database "DWHNorthwindOrders", table "dbo.TimeDimension", column 'DateID'.
The statement has been terminated.

Completion time: 2024-11-19T11:55:51.6031788-04:00 */

-- Verificando
SELECT DISTINCT DateID
FROM vw_FactSales
WHERE DateID NOT IN (SELECT DateID FROM TimeDimension);

/* Intentando solucionar */
INSERT INTO TimeDimension (DateID, Year, Month, Day, Quarter)
VALUES 
    ('1996-07-08', 1996, 7, 8, 3),
    ('1996-07-05', 1996, 7, 5, 3),
    ('1996-07-09', 1996, 7, 9, 3),
    ('1996-07-04', 1996, 7, 4, 3); -- Funciono, 4 Rows affected

	-- Verificando
	SELECT * 
FROM TimeDimension
WHERE DateID IN ('1996-07-08', '1996-07-05', '1996-07-09', '1996-07-04');

/* Ahora a intentar reinsertar de nuevo */
INSERT INTO OrderFacts (OrderID, ProductID, CustomerID, EmployeeID, DateID, Quantity, UnitPrice)
SELECT 
    OrderID, ProductID, CustomerID, EmployeeID, DateID, Quantity, UnitPrice
FROM vw_FactSales; -- Funciono, 15 Rows affected

--Verificando
SELECT TOP 10 * FROM OrderFacts; -- Todo bien

-----------------------------------------------------------------------------------------------------------------------

/* Ahora a seguir cargando */

-- Cargar en CustomerFacts desde vw_FactCustomerAttended
INSERT INTO CustomerFacts (CustomerID, TotalOrders, TotalQuantityPurchased, TotalAmountSpent)
SELECT 
    CustomerID, TotalOrders, TotalQuantityPurchased, TotalAmountSpent
FROM vw_FactCustomerAttended; -- Funciono, aunque me dio un waring. 91 Rows Affected

/* Este es el warning que me dio:
Warning: Null value is eliminated by an aggregate or other SET operation. */

-----------------------------------------------------------------------------------------------------------------------
-- Ahora a verificar lo que se cargo

USE DWHNorthwindOrders
GO
-- Datos en OrderFacts
SELECT TOP 10 * FROM OrderFacts;

-- Datos en CustomerFacts
SELECT TOP 10 * FROM CustomerFacts;

-----------------------------------------------------------------------------------------------------------------------

/* Chequeando los datos */

USE Northwind
GO

-- Verificando que todos los OrderID existen en Orders
SELECT od.OrderID
FROM OrderDetails od
LEFT JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.OrderID IS NULL;

-- Verificando que todos los ProductID existen en Products
SELECT od.ProductID
FROM OrderDetails od
LEFT JOIN Products p ON od.ProductID = p.ProductID
WHERE p.ProductID IS NULL;

-- Ahora a chequear las relaciones:
SELECT 
    od.OrderID,
    o.CustomerID,
    od.ProductID,
    p.ProductName,
    od.UnitPrice,
    od.Quantity,
    od.Discount
FROM OrderDetails od
INNER JOIN Orders o ON od.OrderID = o.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID;

/* Prueba de las vistas */
SELECT * FROM vw_FactSales;
SELECT * FROM vw_FactCustomerAttended;

/* Tabla de hechos */
SELECT * FROM OrderFacts;
SELECT * FROM CustomerFacts;

/* Las metricas */
USE DWHNorthwindOrders
Go

SELECT name 
FROM sys.tables
WHERE name IN ('OrderFacts', 'CustomerFacts');

SELECT 
    CustomerID, 
    SUM(TotalAmount) AS TotalAmount_Sum
FROM OrderFacts
GROUP BY CustomerID;

SELECT * FROM CustomerFacts;

-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

/* Puede ignorar esta seccion, estoy sacando resultados para la documentacion */

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';


/* Resultados: */

-- Dimensiones
-- CustomerDimension
SELECT TOP 10 * FROM CustomerDimension;

-- ProductDimension
SELECT TOP 10 * FROM ProductDimension;

-- EmployeeDimension
SELECT TOP 10 * FROM EmployeeDimension;

-- TimeDimension
SELECT TOP 10 * FROM TimeDimension;

-- Hechos
-- OrderFacts
SELECT TOP 10 * FROM OrderFacts;

-- CustomerFacts
SELECT TOP 10 * FROM CustomerFacts;


/* Resultados de Métricas Calculadas */
/* Métricas desde OrderFacts */

--Cantidad total de productos vendidos por cliente:
SELECT 
    CustomerID, 
    SUM(Quantity) AS TotalQuantity
FROM OrderFacts
GROUP BY CustomerID
ORDER BY TotalQuantity DESC;

-- Monto total generado por producto:
SELECT 
    ProductID, 
    SUM(TotalAmount) AS TotalSalesAmount
FROM OrderFacts
GROUP BY ProductID
ORDER BY TotalSalesAmount DESC;

-- Ventas totales por empleado:
SELECT 
    EmployeeID, 
    SUM(TotalAmount) AS TotalSalesByEmployee
FROM OrderFacts
GROUP BY EmployeeID
ORDER BY TotalSalesByEmployee DESC;


/* Métricas desde CustomerFacts */

-- Clientes con mayor cantidad de órdenes:
SELECT 
    CustomerID, 
    TotalOrders, 
    TotalAmountSpent
FROM CustomerFacts
ORDER BY TotalOrders DESC;

-- Clientes con mayor gasto total:
SELECT 
    CustomerID, 
    TotalAmountSpent
FROM CustomerFacts
ORDER BY TotalAmountSpent DESC;
