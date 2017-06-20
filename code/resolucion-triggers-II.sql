USE [stores7new]

/*
a. Se pide: Crear un trigger que valide que ante un insert (de una o más filas) en la
tabla ítems, realice la siguiente validación.
 Si la órden de compra a la que pertenecen los ítems ingresados corresponde
a clientes del estado de California, se deberá validar que las órdenes pueden
contar con hasta 5 registros en la tabla ítem.
 Si se insertan más ítems de los definidos, el resto de los ítems se deberán
insertar en la tabla items_error la cuál contiene la misma estructura que la
tabla ítems más un atributo fecha que deberá contener la fecha del día en
que se trató de insertar.
Si por ejemplo la OC cuenta con 3 items y se realiza un insert masivo de 3 ítems
más, el trigger deberá insertar los 2 primeros en la tabla ítems y el restante en la
tabla ítems_error.
Supuesto: En el caso de un insert masivo los ítems pertenecen siempre a la misma
órden.
*/ 
CREATE TRIGGER validar_ins
ON items
INSTEAD OF INSERT
AS
BEGIN
	DECLARE items_cur CURSOR FOR
	SELECT item_num, order_num, stock_num, manu_code, quantity, total_price FROM inserted

	DECLARE @estado CHAR(2), @cant_items INTEGER;

	SET @estado = (SELECT TOP 1 state FROM inserted I JOIN orders O
										ON(i.order_num = O.order_num)
											JOIN customer C
												ON(C.customer_num = O.customer_num))

	DECLARE @item_num SMALLINT
	DECLARE @order_num SMALLINT
	DECLARE @stock_num SMALLINT
	DECLARE @manu_code CHAR(3)
	DECLARE @quantity SMALLINT
	DECLARE @total_price DECIMAL(8,2)
	
	OPEN items_cur

	FETCH items_cur INTO @item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price
	
	SET @cant_items = (SELECT COUNT(*) FROM items WHERE order_num = @order_num)

	IF(@estado = 'CA')
	BEGIN
		WHILE((SELECT COUNT(*) FROM items WHERE order_num = @order_num)<=5)
		BEGIN
			INSERT INTO items (item_num, order_num, stock_num, manu_code, quantity, total_price) 
				VALUES (@item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price)

			FETCH items_cur INTO @item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price
		END
		WHILE(@@FETCH_STATUS = 0)
		BEGIN
			INSERT INTO items_error VALUES (@item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price, GETDATE())

			FETCH items_cur INTO @item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price
		END
	END
	ELSE
	BEGIN
		WHILE(@@FETCH_STATUS = 0)
		BEGIN
			INSERT INTO items (item_num, order_num, stock_num, manu_code, quantity, total_price) 
				VALUES (@item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price)

			FETCH items_cur INTO @item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price
		END
	END
	
	CLOSE items_cur
	DEALLOCATE items_cur
END
GO

---------------------------------------------------------------------------------------------

create trigger Tr_temaA

on items

instead of insert

AS

BEGIN

declare @stock_num smallint, @order_num smallint, @item_num

smallint,

@quantity smallint

declare @total_price decimal(8,2)

declare @manu_code char(3),@state char(2)



declare c_call cursor

for select i.*,state from inserted i

JOIN orders o

ON (i.order_num=o.order_num)

JOIN customer c

ON (o.customer_num=c.customer_num)

open c_call

fetch from c_call into

@item_num,@order_num,@stock_num,@manu_code,

@quantity,@total_price,@state

while @@fetch_status=0

BEGIN

if @state='CA'

begin

if (select COUNT(*) FROM items where

order_num=@order_num) < 5

begin

INSERT INTO items



VALUES(@item_num,@order_num,@stock_num,@manu_code,



@quantity,@total_price)



end

else

begin

INSERT INTO items_error



VALUES(@item_num,@order_num,@stock_num,@manu_code,



@quantity,@total_price,getDate())



end



end

else

begin

INSERT INTO items



VALUES(@item_num,@order_num,@stock_num,@manu_code,



@quantity,@total_price)

end



fetch from c_call into

@item_num,@order_num,@stock_num,@manu_code,

@quantity,@total_price,@state



END

close c_call

deallocate c_call

END

----pruebas del trigger

CREATE TABLE [dbo].[items_error](
[item_num] [smallint] NOT NULL,
[order_num] [smallint] NOT NULL,
[stock_num] [smallint] NOT NULL,
[manu_code] [char](3) COLLATE Traditional_Spanish_CI_AS NOT
NULL,
[quantity] [smallint] NULL DEFAULT ((1)),
[total_price] [decimal](8, 2) NULL,
[fecha] [datetime] NULL
)

select * from items where order_num in(
select order_num from orders o, customer c
where o.customer_num=c.customer_num
and c.state='CA')
insert into items values (14,1003,9,'ANZ',1,10)
insert into items values (15,1003,9,'ANZ',1,10)
insert into items values (16,1003,9,'ANZ',1,10)
insert into items values (17,1003,9,'ANZ',1,10)
insert into items values (18,1003,9,'ANZ',1,10)
select * from items_error

/*
b. Dada la siguiente vista
*/
CREATE VIEW ProdPorFabricante AS
SELECT m.manu_code, manu_name, COUNT(*) AS cant_productos
FROM manufact m INNER JOIN products s 
	ON (m.manu_code = s.manu_code)
GROUP BY m.manu_code, manu_name
/*
Se pide: Crear un trigger que permita ante un insert en la vista ProdPorFabricante
insertar los datos en la tabla manufact.
Observaciones: el atributo leadtime deberá insertarse con un valor default 10
El trigger deberá contemplar inserts de varias filas, ante un
INSERT masivo (INSERT SELECT).
*/ 
CREATE TRIGGER insertar_fabricante
ON ProdPorFabricante
INSTEAD OF INSERT
AS
BEGIN
	DECLARE manufacts_cur CURSOR FOR
	SELECT manu_code, manu_name FROM inserted

	DECLARE @manu_code CHAR(3), @manu_name VARCHAR(15)

	OPEN manufacts_cur

	FETCH manufacts_cur INTO @manu_code, @manu_name

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(NOT EXISTS (SELECT * FROM manufact WHERE manu_code = @manu_code))
		BEGIN
			INSERT INTO manufact (manu_code, manu_name, lead_time) VALUES (@manu_code, @manu_name, 10)
		END
	END
END

/*
c. Crear un trigger que valide que ante un update (de una o más filas) en la tabla
customer, realice la siguiente validación.
 La cuota de clientes correspondientes al estado de California es de 20, si se supera
dicha cuota se deberán grabar el resto de los clientes en la tabla
customer_update_pend.
 Validar que si de los clientes a modificar se modifica el Estado, no se puede superar
dicha cuota.
Si por ejemplo el estado de CA cuenta con 18 clientes y se realiza un update masivo
de 5 clientes con estrado de CA, el trigger deberá modificar los 2 primeros en la
tabla customer y los restantes grabarlos en la tabla customer_updates_pend.
La tabla customer_updates_pend tendrá la misma estructura que la tabla customer
con un atributo adicional fecha que deberá actualizarse con la fecha y hora del día.
*/ 
CREATE TRIGGER validar_upd_cust
ON customer
INSTEAD OF UPDATE
AS
BEGIN
	DECLARE clientes_upd_cur CURSOR FOR
	SELECT * FROM inserted

	DECLARE @c_num SMALLINT
	DECLARE @fname VARCHAR(15)
	DECLARE @lname VARCHAR(15)
	DECLARE @company VARCHAR(20)
	DECLARE @adr1 VARCHAR(20)
	DECLARE @adr2 VARCHAR(20)
	DECLARE @city VARCHAR(15)
	DECLARE @state CHAR(2)
	DECLARE @z_code CHAR(5)
	DECLARE @phone VARCHAR(18)
	DECLARE @c_num_ref_by SMALLINT

	OPEN clientes_upd_cur
	FETCH clientes_upd_cur INTO @c_num, 
								@fname, 
								@lname, 
								@company, 
								@adr1, 
								@adr2, 
								@city, 
								@state, 
								@z_code, 
								@phone, 
								@c_num_ref_by

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF((SELECT COUNT(*) FROM customer WHERE state = 'CA') >= 20)
		BEGIN
			INSERT INTO customer_updates_pend VALUES (@c_num, 
														@fname, 
														@lname, 
														@company, 
														@adr1, 
														@adr2, 
														@city, 
														@state, 
														@z_code, 
														@phone, 														  
														GETDATE()) --creo que es mejor ponerle el GETDATE() como DEFAULT
		END
		ELSE
		BEGIN
			UPDATE customer 
			SET fname = @fname, 
				lname = @lname, 
				company = @company, 
				address1 = @adr1, 
				address2 = @adr2, 
				city = @city, 
				state = @state, 
				zipcode = @z_code, 
				phone = @phone, 
				customer_num_referedBy = @c_num_ref_by
			WHERE customer_num = @c_num 
		END

		FETCH clientes_upd_cur INTO @c_num, 
									@fname, 
									@lname, 
									@company, 
									@adr1, 
									@adr2, 
									@city, 
									@state, 
									@z_code, 
									@phone, 
									@c_num_ref_by 
	END

	CLOSE clientes_upd_cur
	DEALLOCATE clientes_upd_cur 
END

/* 
d. Dada la siguiente vista
*/
CREATE VIEW ProdPorFabricanteDet AS
SELECT m.manu_code, manu_name, stock_num, description
FROM manufact m LEFT OUTER JOIN productos s ON (m.manu_code = s.manu_code)
/*
Se pide: Crear un trigger que permita ante un DELETE en la vista ProdPorFabricante
borrar los datos en la tabla manufact pero sólo de los fabricantes cuyo campo
description sea NULO (o sea que no tienen stock).
El trigger deberá contemplar borrado de varias filas, ante un DELETE masivo. En
ese caso sólo borrará de la tabla los fabricantes que no tengan productos en stock.
*/
CREATE TRIGGER validar_del_manufact
ON ProdPorFabricanteDet
INSTEAD OF DELETE
AS
BEGIN
	DELETE FROM manufact 
	WHERE manu_code IN (SELECT manu_code FROM deleted WHERE description IS NULL)
END