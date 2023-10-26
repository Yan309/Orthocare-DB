-- Table to store cities
CREATE TABLE Cities (
  city_id INT PRIMARY KEY identity(1,1),
  city_name VARCHAR(255)
);
select * from Cities
-- Table to store suppliers
CREATE TABLE Vendors (
  Vendor_id INT PRIMARY KEY identity(1,1),
  Vendor_name VARCHAR(255),
  phone_number VARCHAR(20),
  city_id INT,
  FOREIGN KEY (city_id) REFERENCES Cities (city_id)
);

-- Table to store purchases
CREATE TABLE Purchases (
  purchase_id INT PRIMARY KEY identity(1,1),
  vendor_id INT,
  total_amount INT,
  purchase_date date, 
  FOREIGN KEY (vendor_id) REFERENCES Vendors(Vendor_id)
);

-- Table to store products
CREATE TABLE Products (
  product_id INT PRIMARY KEY identity(1,1),
  product_name VARCHAR(255),
  unit_price int,
  catalog_number int,
  material VARCHAR(255),
);

--Table to store purchase details
CREATE TABLE Purchase_Details (
  purchasedetail_id INT PRIMARY KEY identity(1,1),
  purchase_id INT,
  product_id INT,
  quantity INT,
  FOREIGN KEY (purchase_id) REFERENCES Purchases(purchase_id),
  FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Table to store hospitals
CREATE TABLE Hospitals (
  hospital_id INT PRIMARY KEY identity(1,1),
  hospital_name VARCHAR(255),
  city_id INT,
  FOREIGN KEY (city_id) REFERENCES Cities (city_id)
);

-- Table to store delivery challans
CREATE TABLE DeliveryChallans (
  DC_id INT PRIMARY KEY identity(1,1),
  DC_number INT,
  challan_date DATE,
  hospital_id INT,
  total_amount INT,
  FOREIGN KEY (hospital_id) REFERENCES Hospitals (hospital_id)
);

-- Table to store patients
CREATE TABLE Patients (
  patient_id INT PRIMARY KEY identity(1,1),
  patient_name VARCHAR(255),
  phone_number VARCHAR(20),
  DC_id INT,
  FOREIGN KEY (DC_id) REFERENCES DeliveryChallans (DC_id)
);

-- Table to store delivery challan details
CREATE TABLE DeliveryChallanDetails (
  DC_detail_id INT PRIMARY KEY identity(1,1),
  DC_id INT,
  product_id INT,
  quantity INT,
  unit_price INT,
  FOREIGN KEY (DC_id) REFERENCES DeliveryChallans (DC_id),
  FOREIGN KEY (product_id) REFERENCES Products (product_id)
);

CREATE TABLE Pendings (
  Pending_id INT PRIMARY KEY identity(1,1),
  DC_id INT,
  product_id INT,
  quantity INT,
  FOREIGN KEY (DC_id) REFERENCES DeliveryChallans (DC_id),
  FOREIGN KEY (product_id) REFERENCES Products (product_id)
);

-- Table to store stock in different cities
CREATE TABLE Stock (
  stock_id INT PRIMARY KEY identity(1,1),
  product_id INT,
  city_id INT,
  quantity INT,
  FOREIGN KEY (product_id) REFERENCES Products (product_id),
  FOREIGN KEY (city_id) REFERENCES Cities (city_id)
);

-- Table to store materials
CREATE TABLE Materials (
  material_id INT PRIMARY KEY identity(1,1),
  material_name VARCHAR(255),
  unit_price INT,
  quantity INT,
);

-- Table to store production orders
CREATE TABLE ProductionOrders (
  order_id INT PRIMARY KEY identity(1,1),
  order_date DATE,
  production_cost INT,
);

-- Table to store production order details
CREATE TABLE ProductionDetails (
  productiondetail_id INT PRIMARY KEY identity(1,1),
  order_id INT,
  material_id INT,
  product_id INT,
  quantity INT,
  FOREIGN KEY (order_id) REFERENCES ProductionOrders (order_id),
  FOREIGN KEY (material_id) REFERENCES Materials (material_id),
  FOREIGN KEY (product_id) REFERENCES Products (product_id)
);

-- Table to store sales
CREATE TABLE Sales (
  sale_id INT PRIMARY KEY identity(1,1),
  sale_date DATE,
  DC_id INT,
  total_amount INT,
  FOREIGN KEY (DC_id) REFERENCES DeliveryChallans (DC_id)
);

-- Table to store sale details
CREATE TABLE SaleDetails (
  sale_detail_id INT PRIMARY KEY identity(1,1),
  sale_id INT,
  product_id INT,
  quantity INT,
  unit_price INT,
  total_price INT,
  FOREIGN KEY (sale_id) REFERENCES Sales (sale_id),
  FOREIGN KEY (product_id) REFERENCES Products (product_id)
);

-- Table to store walk-in-customer details
CREATE TABLE WalkInCustomer (
  wic_id INT PRIMARY KEY identity(1,1),
  wic_name varchar(255),
  phone_number INT,
  sale_id INT,
  FOREIGN KEY (sale_id) REFERENCES Sales (sale_id),
);


-- Table to store sales returns
CREATE TABLE SalesReturns (
  return_id INT PRIMARY KEY identity(1,1),
  return_date DATE,
  patient_id INT,
  walkincustomer_id INT,
  total_amount INT,
  FOREIGN KEY (patient_id) REFERENCES Patients (patient_id),
  FOREIGN KEY (walkincustomer_id) REFERENCES walkincustomer (wic_id)

);

-- Table to store sales return details
CREATE TABLE SalesReturnDetails (
  return_detail_id INT PRIMARY KEY,
  return_id INT,
  product_id INT,
  quantity INT,
  unit_price INT,
  FOREIGN KEY (return_id) REFERENCES SalesReturns (return_id),
  FOREIGN KEY (product_id) REFERENCES Products (product_id)
);

CREATE TABLE CheapPurchaseDetails (
  purchasedetail_id INT PRIMARY KEY,
  purchase_id INT,
  product_id INT,
  quantity INT,
  FOREIGN KEY (purchase_id) REFERENCES CheapPurchases(purchase_id),
  FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

CREATE TABLE PricyPurchaseDetails (
  purchasedetail_id INT PRIMARY KEY,
  purchase_id INT,
  product_id INT,
  quantity INT,
  FOREIGN KEY (purchase_id) REFERENCES PricyPurchases(purchase_id),
  FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

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