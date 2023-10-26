--triggers
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
alter TRIGGER PurchaseDTrigger
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
    )
    WHERE purchase_id IN (SELECT purchase_id FROM inserted);

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

--stock managing triggers
create trigger stock1
on saledetails
after insert
as begin
update stock
set quantity =((select quantity from stock where product_id in
(select product_id from inserted)
and city_id in (select c.city_id from inserted i
inner join Sales s on s.sale_id = i.sale_id
inner join DeliveryChallans dc on dc.DC_id = s.DC_id
inner join Hospitals h on h.hospital_id = dc.hospital_id
inner join cities c on c.city_id = h.city_id
)) - (select quantity from inserted))
where stock.product_id in (select product_id from inserted) and stock.city_id in (select c.city_id from inserted i
inner join Sales s on s.sale_id = i.sale_id
inner join DeliveryChallans dc on dc.DC_id = s.DC_id
inner join Hospitals h on h.hospital_id = dc.hospital_id
inner join cities c on c.city_id = h.city_id
)
end;

create trigger stock2
on purchase_details
after insert
as begin
update stock
set quantity =((select quantity from stock where product_id in
(select product_id from inserted)
and city_id in (select c.city_id from inserted i
inner join Purchases p on p.purchase_id = i.purchase_id
inner join vendors v on v.Vendor_id = p.vendor_id
inner join cities c on c.city_id = v.city_id
)) + (select quantity from inserted))
where stock.product_id in (select product_id from inserted) and stock.city_id in (select c.city_id from inserted i
inner join Purchases p on p.purchase_id = i.purchase_id
inner join vendors v on v.Vendor_id = p.vendor_id
inner join cities c on c.city_id = v.city_id
)
end;

create trigger stockinsertadder
on stock
instead of insert
as begin
update stock
set quantity = ((select quantity from stock where product_id in
(select product_id from inserted)
and city_id in (select city_id from inserted))+ (select quantity from inserted where product_id in
(select product_id from stock)
and city_id in (select city_id from stock)))
where product_id in (select product_id from inserted)
and city_id in (select city_id from inserted);
end;

--material trigger
create trigger materials1
on productiondetails
after insert
as begin
update materials
set quantity = ((select quantity from materials where material_id in
(select material_id from inserted))
 - (select quantity from inserted))
where materials.material_id in (select material_id from inserted)
end;


--amount triggers
CREATE TRIGGER amount1
ON DeliveryChallanDetails
AFTER INSERT
AS
BEGIN
    UPDATE DeliveryChallans
    SET total_amount = (
        SELECT SUM(dcd.quantity * dcd.unit_price)
        FROM DeliveryChallanDetails dcd
        WHERE dcd.DC_id = DeliveryChallans.DC_id
    )
    WHERE DC_id IN (SELECT DC_id FROM inserted);
END;


Create TRIGGER amount2
ON SaleDetails
AFTER INSERT
AS
BEGIN
    UPDATE Sales
    SET total_amount = (
        SELECT SUM(sd.quantity * sd.unit_price)
        FROM SaleDetails sd
        WHERE sd.sale_id = Sales.sale_id
    )
    WHERE sale_id IN (SELECT sale_id FROM inserted);
END;


CREATE TRIGGER amount3
ON SalesReturnDetails
AFTER INSERT
AS
BEGIN
    UPDATE SalesReturns
    SET total_amount = (
        SELECT SUM(sr.quantity * sr.unit_price)
        FROM SalesReturnDetails sr
        WHERE sr.return_id = SalesReturns.return_id
    )
    WHERE return_id IN (SELECT return_id FROM inserted);
END;


CREATE TRIGGER amount4
ON ProductionDetails
AFTER INSERT
AS
BEGIN
    UPDATE ProductionOrders
    SET production_cost = (
        SELECT SUM(pd.quantity * p.unit_price)
        FROM ProductionDetails pd
        INNER JOIN Products p ON pd.product_id = p.product_id
        WHERE pd.order_id = ProductionOrders.order_id
    )
    WHERE order_id IN (SELECT order_id FROM inserted);
END;







