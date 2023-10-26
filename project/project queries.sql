--insert values
insert into Cities values ('Lahore');
insert into Cities values('Karachi');
insert into Cities values ('Islamabad');
insert into Cities values ('Multan');
insert into Cities values ('Pano Akil');
insert into Cities values ('Peshawar');
insert into Cities values ('Quetta');
insert into Cities values ('Sialkot');
insert into Materials values ('Titanium',2000,10);
insert into Materials values ('Steel',500,15);


--reset id back to 1
DBCC CHECKIDENT('Vendors', RESEED, 0);
DBCC CHECKIDENT('DeliveryChallans', RESEED, 0);
DBCC CHECKIDENT('DeliveryChallanDetails', RESEED, 0);
DBCC CHECKIDENT('Patients', RESEED, 0);
DBCC CHECKIDENT('Pendings', RESEED, 0);
DBCC CHECKIDENT('Sales', RESEED, 0);
DBCC CHECKIDENT('SaleDetails', RESEED, 0);
DBCC CHECKIDENT('Salesreturns', RESEED, 0);
DBCC CHECKIDENT('SalesreturnDetails', RESEED, 0);
DBCC CHECKIDENT('ProductionOrders', RESEED, 0);
DBCC CHECKIDENT('ProductionDetails', RESEED, 0);
DBCC CHECKIDENT('Purchases', RESEED, 0)
DBCC CHECKIDENT('Purchase_Details', RESEED, 0);



--delete values from tables with foreign keys
ALTER TABLE Vendors NOCHECK CONSTRAINT ALL;
delete from Vendors;
ALTER TABLE Vendors WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Products NOCHECK CONSTRAINT ALL;
delete from Products;
ALTER TABLE Products WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Hospitals NOCHECK CONSTRAINT ALL;
delete from Hospitals;
ALTER TABLE Hospitals WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Stock NOCHECK CONSTRAINT ALL;
delete from Stock;
ALTER TABLE Stock WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE DeliveryChallans NOCHECK CONSTRAINT ALL;
delete from DeliveryChallans;
ALTER TABLE DeliveryChallans WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE DeliveryChallanDetails NOCHECK CONSTRAINT ALL;
delete from DeliveryChallanDetails;
ALTER TABLE DeliveryChallanDetails WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Patients NOCHECK CONSTRAINT ALL;
delete from Patients;
ALTER TABLE Patients WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE sales NOCHECK CONSTRAINT ALL;
delete from Sales;
ALTER TABLE sales WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE saledetails NOCHECK CONSTRAINT ALL;
delete from SaleDetails;
ALTER TABLE saledetails WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE salesreturns NOCHECK CONSTRAINT ALL;
delete from salesreturns;
ALTER TABLE salesreturns WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE salesreturndetails NOCHECK CONSTRAINT ALL;
delete from SalesreturnDetails;
ALTER TABLE salesreturndetails WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Pendings NOCHECK CONSTRAINT ALL;
delete from Pendings;
ALTER TABLE Pendings WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE ProductionOrders NOCHECK CONSTRAINT ALL;
delete from ProductionOrders;
ALTER TABLE ProductionOrders WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE ProductionDetails NOCHECK CONSTRAINT ALL;
delete from ProductionDetails;
ALTER TABLE ProductionDetails WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Purchases NOCHECK CONSTRAINT ALL;
delete from Purchases;
ALTER TABLE Purchases WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Purchase_Details NOCHECK CONSTRAINT ALL;
delete from Purchase_Details;
ALTER TABLE Purchase_Details WITH CHECK CHECK CONSTRAINT ALL;


--select statements
select * from Stock;
select * from Products;
SELECT * FROM Hospitals;
select * from vendors;
select * from Cities;
select * from Materials;
Select * from DeliveryChallans;
Select * from DeliveryChallanDetails;
Select * from Pendings;
Select * from Patients;
select * from Sales;
select * from SaleDetails;
select * from SalesReturns;
select * from SalesReturnDetails;
select * from ProductionOrders;
select * from ProductionDetails;
Select * from WalkInCustomer;
select * from Purchases;
Select * from Purchase_Details;
select * from CheapPurchases;
select * from CheapPurchaseDetails;
select * from PricyPurchases;
select * from PricyPurchaseDetails;
select * from PurchaseHistory

--update for calculating total amount through unit prices for products
UPDATE DeliveryChallans SET total_amount = (SELECT SUM(dcd.unit_price * dcd.quantity) FROM DeliveryChallanDetails dcd WHERE dcd.DC_id = DeliveryChallans.DC_id);

--inserts data into pendings from deliverychalandetails
INSERT INTO Pendings(DC_id,product_id,quantity) SELECT dc_id,product_id,quantity FROM DeliveryChallanDetails;

--insert into sales details from sales

INSERT INTO SaleDetails (sale_id, product_id, quantity, unit_price) 
                       SELECT s.sale_id, dcd.product_id, dcd.quantity, dcd.unit_price  
                       FROM Sales s  
                       JOIN DeliveryChallans dc ON s.DC_id = dc.DC_id  
                       JOIN DeliveryChallanDetails dcd ON dc.DC_id = dcd.DC_id

--update for calculating total amount through unit prices for products
UPDATE Sales SET total_amount = (SELECT SUM(dcd.unit_price * dcd.quantity) FROM DeliveryChallanDetails dcd WHERE dcd.DC_id = Sales.DC_id);
UPDATE ProductionOrders
SET production_cost = (
    SELECT SUM(p.quantity * m.unit_price)
    FROM ProductionDetails p
    INNER JOIN Materials m ON p.material_id = m.material_id
    WHERE p.order_id = ProductionOrders.order_id
)
UPDATE Purchases
SET total_amount = (
    SELECT SUM(pd.quantity * p.unit_price)
    FROM Purchase_Details pd
    INNER JOIN Products p ON pd.product_id = p.product_id
    WHERE pd.purchase_id = Purchases.purchase_id
)

UPDATE SaleDetails
SET unit_price = p.unit_price
FROM SaleDetails AS sd
JOIN products AS p ON sd.product_id = p.product_id;

--table splitting
CREATE TABLE CheapPurchases (
  purchase_id INT PRIMARY KEY,
  vendor_id INT foreign key
  references Vendors(Vendor_id),
  total_amount INT,
  purchase_date DATE,
);

CREATE TABLE PricyPurchases (
  purchase_id INT PRIMARY KEY,
  vendor_id INT foreign key
  references Vendors(Vendor_id),
  total_amount INT,
  purchase_date DATE,
);

INSERT INTO CheapPurchases (purchase_id, vendor_id, total_amount, purchase_date)
SELECT purchase_id, vendor_id, total_amount, purchase_date
FROM Purchases
WHERE total_amount <= 25000;


INSERT INTO PricyPurchases (purchase_id, vendor_id, total_amount, purchase_date)
SELECT purchase_id, vendor_id, total_amount, purchase_date
FROM Purchases
WHERE total_amount > 25000;



INSERT INTO CheapPurchaseDetails (purchasedetail_id, purchase_id, product_id, quantity)
SELECT pd.purchasedetail_id, pd.purchase_id, pd.product_id, pd.quantity
FROM Purchase_Details pd
inner join CheapPurchases ch ON pd.purchase_id = ch.purchase_id
WHERE ch.total_amount <= 25000;

INSERT INTO PricyPurchaseDetails (purchasedetail_id, purchase_id, product_id, quantity)
SELECT pd.purchasedetail_id, pd.purchase_id, pd.product_id, pd.quantity
FROM Purchase_Details pd
inner join PricyPurchases pr ON pd.purchase_id = pr.purchase_id
WHERE pr.total_amount > 25000;

--history tables
CREATE TABLE PurchaseHistory (
  PurchaseHistory_id INT PRIMARY KEY identity(1,1),
  Purchase_id INT,
  Vendor_id INT,
  total_amount INT,
  purchase_date Date,
  quantity INT,
  product_id int,
  unit_price INT,
  HistoryDate DATE
);
CREATE TABLE ProductionHistory (
  ProductionHistory_id INT PRIMARY KEY identity(1,1),
  Order_id INT,
  total_amount INT,
  Order_date Date,
  quantity INT,
  product_id int,
  material_id INT,
  HistoryDate DATE
);


