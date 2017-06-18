USE [stores7new]

/*
a. Se pide: Crear un trigger que valide que ante un insert (de una o m�s filas) en la
tabla �tems, realice la siguiente validaci�n.
 Si la �rden de compra a la que pertenecen los �tems ingresados corresponde
a clientes del estado de California, se deber� validar que las �rdenes pueden
contar con hasta 5 registros en la tabla �tem.
 Si se insertan m�s �tems de los definidos, el resto de los �tems se deber�n
insertar en la tabla items_error la cu�l contiene la misma estructura que la
tabla �tems m�s un atributo fecha que deber� contener la fecha del d�a en
que se trat� de insertar.
Si por ejemplo la OC cuenta con 3 items y se realiza un insert masivo de 3 �tems
m�s, el trigger deber� insertar los 2 primeros en la tabla �tems y el restante en la
tabla �tems_error.
Supuesto: En el caso de un insert masivo los �tems pertenecen siempre a la misma
�rden.
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

	FETCH items_cur INTO @item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price

	SET @cant_items = (SELECT COUNT(*) FROM items WHERE order_num = @order_num)

	IF(@estado = 'CA' AND @cant_items + @@CURSOR_ROWS > 5)
	BEGIN
		WHILE((SELECT COUNT(*) FROM items WHERE order_num = @order_num)<=5)
		BEGIN
			INSERT INTO items (item_num, order_num, stock_num, manu_code, quantity, total_price) 
				VALUES (@item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price)

			FETCH items_cur INTO @item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price
		END
		WHILE(@@FETCH_STATUS = 0)
		BEGIN
			INSERT INTO items_error (@item_num, @order_num, @stock_num, @manu_code, @quantity, @total_price, GETDATE())

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
Observaciones: el atributo leadtime deber� insertarse con un valor default 10
El trigger deber� contemplar inserts de varias filas, ante un
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
c. Crear un trigger que valide que ante un update (de una o m�s filas) en la tabla
customer, realice la siguiente validaci�n.
 La cuota de clientes correspondientes al estado de California es de 20, si se supera
dicha cuota se deber�n grabar el resto de los clientes en la tabla
customer_update_pend.
 Validar que si de los clientes a modificar se modifica el Estado, no se puede superar
dicha cuota.
Si por ejemplo el estado de CA cuenta con 18 clientes y se realiza un update masivo
de 5 clientes con estrado de CA, el trigger deber� modificar los 2 primeros en la
tabla customer y los restantes grabarlos en la tabla customer_updates_pend.
La tabla customer_updates_pend tendr� la misma estructura que la tabla customer
con un atributo adicional fecha que deber� actualizarse con la fecha y hora del d�a.
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
			IF((SELECT state FROM customer WHERE customer_num = @c_num) != @state)
			BEGIN;
				THROW 50000, 'No se puede modificar el estado de los clientes si se supera la cuota de clientes de California', 1;
			END;
			ELSE
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
														  @c_num_ref_by,
														  GETDATE()) --creo que es mejor ponerle el GETDATE() como DEFAULT
			END			
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


create trigger temaB
on customer
instead of update
AS
BEGIN
declare @customer_num smallint
declare @fname varchar(15), @lname varchar(15),@city
varchar(15)
declare @company varchar(20),@address1 varchar(20),@address2
varchar(20)
declare @state char(2), @state_old char(2)
declare @zipcode char(18)
declare @phone varchar(18)

declare c_call cursor
for select i.*,d.state
from inserted I join deleted d
on (i.customer_num=d.customer_num)

open c_call

fetch from c_call into
@customer_num,@fname,@lname,@company,
@address1,@address2,@city,@state,@zipcode,@phone,@state_old

while @@fetch_status=0
BEGIN
	if @state='CA' and @state!=@state_old
	begin
		if (select COUNT(*) FROM customer where state='CA')< 20
		begin
			UPDATE customer 
			SET fname=@fname,
				lname=@lname,
				company=@company,
				address1=@address1,
				address2=@address2,
				city=@city,
				state=@state,
				zipcode=@zipcode,
				phone=@phone
			WHERE customer_num=@customer_num
		end
		else
		begin
			INSERT INTO customer_updates_pend
			VALUES (@customer_num,@fname,
										@lname,@company,
										@address1,
										@address2,
										@city,@state,@zipcode,@phone,getDate())
		end
	end
	else
	begin
		UPDATE customer
		SET fname=@fname,
			lname=@lname,
			company=@company,
			address1=@address1,
			address2=@address2,
			city=@city, 
			state=@state,
			zipcode=@zipcode,
			phone=@phone
		WHERE customer_num=@customer_num
	end

	fetch NEXT from c_call into
	@customer_num,@fname,@lname,@company,
	@address1,@address2,@city,@state,@zipcode,@phone,@state_old
END

close c_call
deallocate c_call

END

/*
d. Dada la siguiente vista
*/
CREATE VIEW ProdPorFabricanteDet AS
SELECT m.manu_code, manu_name, stock_num, description
FROM manufact m LEFT OUTER JOIN productos s ON (m.manu_code = s.manu_code)
/*
Se pide: Crear un trigger que permita ante un DELETE en la vista ProdPorFabricante
borrar los datos en la tabla manufact pero s�lo de los fabricantes cuyo campo
description sea NULO (o sea que no tienen stock).
El trigger deber� contemplar borrado de varias filas, ante un DELETE masivo. En
ese caso s�lo borrar� de la tabla los fabricantes que no tengan productos en stock.
*/
CREATE TRIGGER validar_del_manufact
ON ProdPorFabricanteDet
INSTEAD OF DELETE
AS
BEGIN
	DELETE FROM manufact 
	WHERE manu_code IN (SELECT manu_code FROM deleted WHERE description IS NULL)
END