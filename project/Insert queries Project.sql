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
--products
insert into Products values ('product_name',unit_price,catalog_number,material_id);
--stock
insert into stock values (product_id,city_id,quantity);

--combined inserts 
--purchase & purchase details
insert into purchases values (vendor_id,total_amount,GETDATE())
insert into purchase_details values ((SELECT IDENT_CURRENT('Purchases')),product_id,quantity)

--dc,dc details & pending
insert into DeliveryChallans values (dc_num,getdate(),hospital_id,total_amount)
insert into DeliveryChallanDetails values ((SELECT IDENT_CURRENT('DeliveryChallans')),product_id,quantity,(select unit_price from Products where product_id = @productid))
insert into Pendings values((SELECT IDENT_CURRENT('DeliveryChallans'),product_id,quantity)

--sales & sales details
insert into sales values (GETDATE(),dc_id,total_amount)
insert into SaleDetails values ((SELECT IDENT_CURRENT('Sales')),product_id,quantity,(select unit_price from Products where product_id = @productid))

--salesreturn & salesreturndetails
insert into salesreturns values (GETDATE(),patient_id,walk_in_customer_id,total_amount,sale_id)
insert into salesreturndetails values ((SELECT IDENT_CURRENT('Salesreturns')),product_id,quantity,(select unit_price from Products where product_id = @productid))

--productionorder & productiondetails
insert into productionorders values (GETDATE(),total_amount)
insert into productiondetails values ((SELECT IDENT_CURRENT('ProductionOrders')),material_id,product_id,quantity)



