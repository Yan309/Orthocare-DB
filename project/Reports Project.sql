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
create proc GeneralLedger
@month int,
@year int
as begin
declare @sales int = (select sum(s.total_amount) from Sales s where month(s.sale_date) = @month and year(s.sale_date) = @year);
declare @purchase int = (select sum(p.total_amount) from Purchases p where month(p.purchase_date) = @month and year(p.purchase_date) = @year);
declare @production int = (select sum(po.production_cost) from ProductionOrders po where month(po.order_date) = @month and year(po.order_date) = @year);
select @sales as total_sales,@purchase as total_purchase,@production as total_production,(isnull(@sales,0)-isnull(@purchase,0)-isnull(@production,0)) as profit;
end

exec GeneralLedger 1,2023

--general ledger year wise
create proc YearlyGeneralLedger
@year int
as begin
declare @sales int = (select sum(s.total_amount) from Sales s where year(s.sale_date) = @year);
declare @purchase int = (select sum(p.total_amount) from Purchases p where year(p.purchase_date) = @year);
declare @production int = (select sum(po.production_cost) from ProductionOrders po where year(po.order_date) = @year);
select @sales as total_sales,@purchase as total_purchase,@production as total_production,(isnull(@sales,0)-isnull(@purchase,0)-isnull(@production,0)) as profit;
end

exec yearlyGeneralLedger 2022

--total sales in different cities
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