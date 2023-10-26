--insert queries

--normal inserts

--city
insert into Cities values ('name');
--hospital
insert into Hospitals values ('hospital name',city_id);
--materials 
insert into Materials values('material name',unit_price,quantity);
--vendors
insert into Vendors values ('vendor name',contact_number,city_id );
--patients
insert into Patients values ('patient name',phone_number,dc_id);
--walk_in client
insert into WalkInCustomer values('customer name',phone_number,sale_id);

--combined inserts 

insert into DeliveryChallans values(700,getdate(),2,0);
insert into DeliveryChallanDetails values();

delete from purchases where purchase_id = 650
delete from CheapPurchases where purchase_id = 650

--triggers

--1
--trigger on purchase  to enter values into the splitted tables whenever data is entered into purchase
CREATE TRIGGER PurchaseTrigger
ON Purchases
AFTER INSERT
AS
BEGIN

    INSERT INTO CheapPurchases (purchase_id, vendor_id, total_amount, purchase_date)
    SELECT i.purchase_id, i.vendor_id, i.total_amount, i.purchase_date
    FROM inserted i
    INNER JOIN Purchases p ON i.purchase_id = p.purchase_id
    WHERE p.total_amount <= 25000;

    INSERT INTO PricyPurchases (purchase_id, vendor_id, total_amount, purchase_date)
    SELECT i.purchase_id, i.vendor_id, i.total_amount, i.purchase_date
    FROM inserted i
    INNER JOIN Purchases p ON i.purchase_id = p.purchase_id
    WHERE p.total_amount > 25000;
END;

--2
-- Trigger on purchase details to enter values into the splitted tables whenever data is entered into purchase details
CREATE TRIGGER PurchaseDTrigger
ON Purchase_Details
AFTER INSERT
AS
BEGIN
    UPDATE Purchases
    SET total_amount = (
        SELECT SUM(pd.quantity * p.unit_price)
        FROM Purchase_Details pd
        INNER JOIN Products p ON pd.product_id = p.product_id
        WHERE pd.purchase_id = Purchases.purchase_id
    );

    INSERT INTO CheapPurchaseDetails (purchasedetail_id,purchase_id, product_id, quantity)
    SELECT i.purchasedetail_id, i.purchase_id, i.product_id, i.quantity
    FROM inserted i
    INNER JOIN Purchase_Details pd ON i.purchase_id = pd.purchase_id
    INNER JOIN Purchases p ON i.purchase_id = p.purchase_id
    WHERE p.total_amount <= 25000;

    INSERT INTO PricyPurchaseDetails (purchasedetail_id,purchase_id, product_id, quantity)
    SELECT i.purchasedetail_id,i.purchase_id, i.product_id, i.quantity
    FROM inserted i
    INNER JOIN Purchase_Details pd ON i.purchase_id = pd.purchase_id
    INNER JOIN Purchases p ON i.purchase_id = p.purchase_id
    WHERE p.total_amount > 25000;
END;


--trigger for production history table
GO
CREATE TRIGGER Delete_Production
ON productionorders
INSTEAD OF DELETE
AS
BEGIN

    DECLARE @quantity INT;
    DECLARE @product_id INT;
    DECLARE @material_id INT;

    DECLARE cur CURSOR FOR
        SELECT quantity, product_id, material_id
        FROM ProductionDetails
        WHERE order_id IN (SELECT order_id FROM deleted);

    OPEN cur;

    FETCH NEXT FROM cur INTO @Quantity, @Product_id , @material_id;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO ProductionHistory
        VALUES (
            (SELECT order_id FROM deleted),
            (SELECT production_cost FROM deleted),
            (SELECT order_date FROM deleted),
			 @quantity,
            @product_id,
            @material_id,
            GETDATE()
        );

        FETCH NEXT FROM cur INTO @quantity, @product_id, @material_id;
    END;

    CLOSE cur;

    DEALLOCATE cur;

    DELETE FROM ProductionDetails
    WHERE order_id IN (SELECT order_id FROM deleted);

    DELETE FROM ProductionOrders 
    WHERE order_id IN (SELECT order_id FROM deleted);
END;

--trigger for purchases history table
GO
CREATE TRIGGER Delete_Purchases
ON purchases
INSTEAD OF DELETE
AS
BEGIN

    DECLARE @quantity INT;
    DECLARE @product_id INT;

    DECLARE cur CURSOR FOR
        SELECT quantity, product_id
        FROM Purchase_Details
        WHERE purchase_id IN (SELECT purchase_id FROM deleted);

    OPEN cur;

    FETCH NEXT FROM cur INTO @Quantity, @Product_id

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO PurchaseHistory
        VALUES (
            (SELECT purchase_id FROM deleted),
            (SELECT vendor_id FROM deleted),
            (SELECT total_amount FROM deleted),
            (SELECT purchase_date FROM deleted),
			 @quantity,
            @product_id,
            GETDATE()
        );

        FETCH NEXT FROM cur INTO @quantity, @product_id
    END;

    CLOSE cur;

    DEALLOCATE cur;

	declare @temp int
	set @temp = (SELECT total_amount FROM deleted)
	if(@temp<= 25000)
	begin
    DELETE FROM CheapPurchaseDetails
    WHERE purchase_id IN (SELECT purchase_id FROM deleted);
	DELETE FROM CheapPurchases
    WHERE purchase_id IN (SELECT purchase_id FROM deleted);
	end
	else
	begin
	DELETE FROM PricyPurchaseDetails
    WHERE purchase_id IN (SELECT purchase_id FROM deleted);
	DELETE FROM PricyPurchases
    WHERE purchase_id IN (SELECT purchase_id FROM deleted);
	end

	DELETE FROM Purchase_Details
    WHERE purchase_id IN (SELECT purchase_id FROM deleted);
	DELETE FROM Purchases
    WHERE purchase_id IN (SELECT purchase_id FROM deleted);
END;

--reports
--all sales report 
alter proc sales_report
as begin
select s.DC_id as DC_Number,sale_date as Date,(sd.quantity*p.unit_price) as Total_Price,p.product_name as Product,sd.quantity as Quantity,sd.unit_price from Sales s
inner join SaleDetails sd on sd.sale_id = s.sale_id
inner join Products p on p.product_id = sd.product_id
end

--specific dates report
create proc specified_sales_report
@start date,
@end date
as begin
select s.DC_id as DC_Number,sale_date as Date,(sd.quantity*p.unit_price) as Total_Price,p.product_name as Product,sd.quantity as Quantity,sd.unit_price from Sales s
inner join SaleDetails sd on sd.sale_id = s.sale_id
inner join Products p on p.product_id = sd.product_id
where sale_date >= @start and sale_date <= @end;
end

exec specified_sales_report '2022-02-18','2023/6/11'

--specific customer report
create proc customer_report
@customerid int
as begin
select s.DC_id as DC_Number,sale_date as Date,(sd.quantity*p.unit_price) as Total_Price,p.product_name as Product,sd.quantity as Quantity,sd.unit_price from Sales s
inner join SaleDetails sd on sd.sale_id = s.sale_id
inner join Products p on p.product_id = sd.product_id
inner join patients pt on pt.DC_id = s.DC_id
where patient_id = @customerid
end

exec customer_report 3

--general ledger month wise
alter proc GeneralLedger
@month int,
@year int
as begin
declare @sales int = (select sum(s.total_amount) from Sales s where month(s.sale_date) = @month and year(s.sale_date) = @year);
declare @purchase int = (select sum(p.total_amount) from Purchases p where month(p.purchase_date) = @month and year(p.purchase_date) = @year);
declare @production int = (select sum(po.production_cost) from ProductionOrders po where month(po.order_date) = @month and year(po.order_date) = @year);
select @sales as total_sales,@purchase as total_purchase,@production as total_production,(@sales-@purchase-@production) as profit;
end

exec GeneralLedger 1,2023

--general ledger year wise
create proc YearlyGeneralLedger
@year int
as begin
declare @sales int = (select sum(s.total_amount) from Sales s where year(s.sale_date) = @year);
declare @purchase int = (select sum(p.total_amount) from Purchases p where year(p.purchase_date) = @year);
declare @production int = (select sum(po.production_cost) from ProductionOrders po where year(po.order_date) = @year);
select @sales as total_sales,@purchase as total_purchase,@production as total_production,(@sales-@purchase-@production) as profit;
end

exec yearlyGeneralLedger 2023

--report based on sales in different cities
create proc CitySales
as begin
select c.city_name,sum(s.sale_id) as total_sales from sales s 
INNER JOIN DeliveryChallans d on s.DC_id = d.DC_id
INNER JOIN Hospitals h on h.hospital_id = d.hospital_id
INNER JOIN cities c on c.city_id = h.city_id
group by c.city_id,c.city_name
end

exec CitySales

--profit generated in specific city
create proc City_Profit
@cityid int
as begin
declare @sales int = (select sum(s.total_amount) from Sales s 
INNER JOIN DeliveryChallans d on s.DC_id = d.DC_id
INNER JOIN Hospitals h on h.hospital_id = d.hospital_id
INNER JOIN cities c on c.city_id = h.city_id
where c.city_id = @cityid );
declare @purchase int = (select sum(p.total_amount) from Purchases p
INNER JOIN Vendors v on v.Vendor_id = p.vendor_id
INNER JOIN Cities c on c.city_id = v.city_id
where c.city_id = @cityid );
select city_name as city,@sales as total_sales,@purchase as total_purchase,(isnull(@sales,0)-isnull(@purchase,0)) as profit from Cities where city_id=@cityid;
end

exec City_Profit 3

--profit generated for all cities
create proc overallcityprofit
as begin
declare @cityid int
declare cur CURSOR for
select city_id from Cities
open cur
fetch next from cur into @cityid
WHILE @@FETCH_STATUS = 0
 BEGIN
        exec City_Profit @cityid
        FETCH NEXT FROM cur INTO @cityid
    END;
close cur;
deallocate cur;
end

exec overallcityprofit

--total sales by all hospitals
create proc hospitalSales
as begin 
select h.hospital_name,sum(s.sale_id) as total_sales from sales s 
INNER JOIN DeliveryChallans d on s.DC_id = d.DC_id
INNER JOIN Hospitals h on h.hospital_id = d.hospital_id
group by h.hospital_id,h.hospital_name
end

exec hospitalSales

--total purchases from all vendors
create proc vendorpurchases
as begin
select v.Vendor_name,sum(p.purchase_id) as total_purchases from purchases p
INNER JOIN Vendors v on v.Vendor_id = p.vendor_id
group by v.Vendor_id,v.Vendor_name
end

exec vendorpurchases