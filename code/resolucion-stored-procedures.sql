USE [stores7new]

/*
a. Stored Procedures
Crear la siguiente tabla CustomerStatistics con los siguientes campos
customer_num (entero y pk), ordersqty (entero), maxdate (date), uniqueProducts
(entero)
Crear un procedimiento ‘actualizaEstadisticas’ que reciba dos parámetros
customer_numDES y customer_numHAS y que en base a los datos de la tabla
customer cuyo customer_num estén en en rango pasado por parámetro, inserte (si
no existe) o modifique el registro de la tabla CustomerStatistics con la siguiente
información:
Ordersqty contedrá la cantidad de órdenes para cada cliente.
Maxdate contedrá la fecha máxima de la última órde puesta por cada cliente.
uniqueProducts contendrá la cantidad única de productos adquiridos por cada
cliente.
*/
CREATE TABLE CustomerStatistics
(
	customer_num SMALLINT PRIMARY KEY,
	ordersqty INTEGER,
	maxdate DATETIME,
	uniqueProducts INTEGER
)
GO

CREATE PROCEDURE actualizaEstadisticas
@customer_numDES SMALLINT,
@customer_numHAS SMALLINT
AS
BEGIN
	DECLARE customerCursor CURSOR FOR
	SELECT customer_num 
	FROM customer 
	WHERE customer_num BETWEEN @customer_numDES AND @customer_numHAS

	DECLARE @customerNum SMALLINT

	OPEN customerCursor

	FETCH customerCursor INTO @customerNum

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @ordersQty INTEGER, @maxdate DATETIME, @uniqueProducts INTEGER

		SELECT @ordersQty=COUNT(*), @maxdate=MAX(order_date)
		FROM orders WHERE customer_num = @customerNum

		SET @uniqueProducts = (SELECT COUNT(*) FROM 
								(SELECT stock_num, manu_code
									FROM orders O JOIN items I 
									ON(O.order_num = I.order_num) 
									WHERE O.customer_num = @customerNum
									GROUP BY stock_num, manu_code) AS T)
		
		IF(EXISTS (SELECT * FROM CustomerStatistics WHERE customer_num = @customerNum))
		BEGIN
			UPDATE CustomerStatistics
			SET ordersqty = @ordersQty,
				maxdate = @maxdate,
				uniqueProducts = @uniqueProducts
			WHERE customer_num = @customerNum
		END
		ELSE
		BEGIN
			INSERT INTO CustomerStatistics VALUES (@customerNum, @ordersQty, @maxdate, @uniqueProducts)		
		END

		FETCH customerCursor INTO @customerNum
	END

	CLOSE customerCursor
	DEALLOCATE customerCursor
END

/*
b. Crear un procedimiento ‘migraClientes’ que reciba dos parámetros
customer_numDES y customer_numHAS y que dependiendo el tipo de cliente y la
cantidad de órdenes los inserte en las tablas clientesCalifornia, clientesNoCaBaja,
clienteNoCAAlta.
* El procedimiento deberá migrar de la tabla customer todos los
clientes de California a la tabla clientesCalifornia, los clientes que no
son de California pero tienen más de 999u$ en OC en
clientesNoCaAlta y los clientes que tiene menos de 1000u$ en OC en
la tablas clientesNoCaBaja.
* Se deberá actualizar un campo status en la tabla customer con valor
‘P’ Procesado, para todos aquellos clientes migrados.
* El procedimiento deberá contemplar toda la migración como un lote,
en el caso que ocurra un error, se deberá informar el error ocurrido y
abortar y deshacer la operación.
*/ 
alter table customer
add status char(1)
go

create procedure migraClientes
@customer_numDES smallint,
@customer_numHAS smallint
as
begin
	begin try
		declare customerCursor cursor for
		select *
		from customer 
		where customer_num between @customer_numDES and @customer_numHAS

		declare @customerNum smallint, 
				@state char(2), 
				@fname VARCHAR(15),
				@lname VARCHAR(15),
				@company VARCHAR(20),
				@adr1 VARCHAR(20),
				@adr2 VARCHAR(20),
				@city VARCHAR(15),
				@zcode CHAR(5),
				@phone VARCHAR(18),
				@cNumRefBy SMALLINT

		open customerCursor

		fetch customerCursor into @customerNum, 
								  @state, 
								  @fname, 
								  @lname, 
								  @company, 
								  @adr1, 
								  @adr2, 
								  @city, 
								  @zcode, 
								  @cNumRefBy

		while(@@FETCH_STATUS = 0)
		begin
			if @state = 'CA'
			begin
				insert into clientesCalifornia values (@customerNum, 
													   @state, 
													   @fname, 
													   @lname, 
													   @company, 
													   @adr1, 
													   @adr2, 
													   @city, 
													   @zcode, 
												       @cNumRefBy)
			end
			else
			begin
				declare @gastoTotal float

				select @gastoTotal=sum(total_price)
				from orders o join items i
				on(o.order_num = i.order_num)
				where o.customer_num = @customerNum

				if @gastoTotal > 999
				begin
					insert into clientesNoCaAlta values (@customerNum, 
														 @state, 
														 @fname, 
														 @lname, 
														 @company, 
														 @adr1, 
														 @adr2, 
														 @city, 
														 @zcode, 
														 @cNumRefBy)
				end
				else
				begin
					insert into clientesNoCaBaja values (@customerNum, 
													     @state, 
													     @fname, 
													     @lname, 
													     @company, 
													     @adr1, 
													     @adr2, 
													     @city, 
													     @zcode, 
												         @cNumRefBy)
				end
			end

			update customer
			set status = 'P'
			where customer_num = @customerNum

			fetch next from customerCursor into @customerNum, 
												@state, 
												@fname, 
												@lname, 
												@company, 
												@adr1, 
												@adr2, 
												@city, 
												@zcode, 
												@cNumRefBy
		end

		close customerCursor
		deallocate customerCursor
	end try
	begin catch
		throw
	end catch
end

/*
c. Stored Procedures
1. Crear la siguiente tabla CustomerStatistics con los siguientes campos
customer_num (entero y pk), ordersqty (entero), maxdate (date),
uniqueProducts (entero)
2. Crear un procedimiento ‘CustomerStatisticsUpdate’ que reciba el parámetro
fecha_DES (fecha_DES) y que en base a los datos de la tabla customer,
inserte (si no existe) o actualice el registro de la tabla CustomerStatistics
con la siguiente información:
Ordersqty: cantidad de órdenes para cada cliente + las nuevas
órdenes con fecha mayor o igual a fecha_DES
Maxdate: fecha máxima de la última órden puesta por cada cliente.
uniqueProducts: cantidad única de productos adquiridos por cada
cliente histórica
*/

create procedure CustomerStatisticsUpdate
@fecha_DES datetime
as
begin
	declare custCur cursor for
	select customer_num from customer

	declare @customerNum smallint

	open custCur

	fetch custCur into @customerNum

	while(@@FETCH_STATUS = 0)
	begin
		declare @ordersQty int, @maxdate datetime, @uniqueProducts int

		select @ordersQty=count(*), @maxdate=max(order_date)
		from orders 
		where customer_num = @customerNum and order_date >= @fecha_DES
		
		set @uniqueProducts = (select count(*) from (select stock_num, manu_code from orders o join items i 
														on(o.order_num = i.order_num) 
															where o.customer_num = @customerNum
														group by stock_num, manu_code) as T)

		if(exists (select * from CustomerStatistics where customer_num = @customerNum))
		begin
			update CustomerStatistics
			set ordersqty = ordersqty + @ordersQty,
				maxdate = @maxdate,
				uniqueProducts = @uniqueProducts
			where customer_num = @customerNum
		end
		else
		begin
			insert into CustomerStatistics (customer_num, ordersqty, maxdate, uniqueProducts) values (@customerNum, @ordersQty, @maxdate, @uniqueProducts)
		end

		fetch custCur into @customerNum
	end

	close custCur
	deallocate custCur
end
go

/*
d. Crear un procedimiento ‘actualizaPrecios’ que reciba dos parámetro manu_codeDES
y manu_codeHAS y porcActualizacion que dependiendo el tipo de cliente y la
cantidad de órdenes genere las siguientes tablas listaPrecioMayor,
listaPrecioMenor.
* El procedimiento deberá tomar de la tabla stock todos los productos que
correspondan al rango de fabricantes asignados por parámetro.
Por cada producto del fabricante se evaluará la cantidad (quantity) comprada si
la misma es mayor o igual a 500 se grabará el producto en la tabla
listaPrecioMayor con igual estructura de stock y el unit_price deberá ser
actualizado con (unit_price * (porcActualización *0,80)), si la cantidad comprada
del producto para dicho fabricante es menor que 500 se actualizará insertará en
la tabla listaPrecioMenor con igual estructura que la tabla stock y el unit_price
se actualizará con (unit_price * porcActualizacion)
* Se deberá actualizar un campo status en la tabla stock con valor ‘A’ Actualizado,
para todos aquellos productos con cambio de precio actualizado.
* El procedimiento deberá contemplar todas las operaciones de cada fabricante
como un lote, en el caso que ocurra un error, se deberá informar el error
ocurrido y abortar y deshacer la operación de ese fabricante.
*/
begin transaction

alter table products
add status char(1)

create table listaPrecioMayor
(
	stock_num smallint,
	manu_code char(3) foreign key references manufact(manu_code),
	unit_price decimal(6,2),
	unit_code smallint foreign key references units(unit_code),
	primary key(stock_num, manu_code)
)
go

create table listaPrecioMenor
(
	stock_num smallint,
	manu_code char(3) foreign key references manufact(manu_code),
	unit_price decimal(6,2),
	unit_code smallint foreign key references units(unit_code),
	primary key(stock_num, manu_code)
)
go

create procedure actualizaPrecios
@manu_codeDES char(3),
@manu_codeHAS char(3),
@porcActualizacion float
as
begin
	begin try
		begin transaction
			declare prodsPorFabrCursor cursor for
			select P.manu_code, P.stock_num, unit_code, unit_price, sum(quantity) as cantVendida
			from products P join items I
				on(P.stock_num = I.stock_num and P.manu_code = I.manu_code)
			--where p.manu_code between @manu_codeDES and @manu_codeHAS
			where p.manu_code between 'HRO' and 'HRO'
			group by P.manu_code, P.stock_num, unit_code, unit_price
			
			declare @manuCode char(3), 
					@stockNum smallint, 
					@unitCode smallint, 
					@unitPrice decimal(6,2), 
					@cantVendida int

			open prodsPorFabrCursor

			fetch prodsPorFabrCursor into @manuCode, @stockNum, @unitCode, @unitPrice, @cantVendida

			while @@FETCH_STATUS = 0
			begin
				if @cantVendida >= 500
				begin
					if not exists (select * from listaPrecioMayor where stock_num = @stockNum and manu_code = @manuCode)
					begin

						insert into listaPrecioMayor (stock_num, manu_code, unit_code, unit_price) 
							values (@stockNum, @manuCode, @unitCode, @unitPrice * @porcActualizacion * 0.8)

					end
					else
					begin

						update listaPrecioMayor
							set unit_price = unit_price * @porcActualizacion * 0.8
						where stock_num = @stockNum and manu_code = @manuCode

					end
				end
				else
				begin
					if not exists (select * from listaPrecioMenor where stock_num = @stockNum and manu_code = @manuCode)
					begin

						insert into listaPrecioMenor (stock_num, manu_code, unit_code, unit_price) 
							values (@stockNum, @manuCode, @unitCode, @unitPrice * @porcActualizacion)

					end
					else
					begin

						update listaPrecioMenor
							set unit_price = unit_price * @porcActualizacion
						where stock_num = @stockNum and manu_code = @manuCode

					end
				end

				update products
					set status = 'A'
				where stock_num = @stockNum and manu_code = @manuCode

				fetch next from prodsPorFabrCursor into @manuCode, @stockNum, @unitCode, @unitPrice, @cantVendida
			end

		close prodsPorFabrCursor
		deallocate prodsPorFabrCursor

		commit
	end try
	begin catch
		rollback;
		throw
	end catch
end
go

/*
e. Stored Procedures
1. Crear la siguiente tabla informeStock con los siguientes campos
fechaInforme (date), stock_num (entero), manu_code (char(3) ), cantOrdenes
(entero), UltCompra (date), cantClientes (entero), totalVentas (decimal). PK
(fechaInforme, stock_num, manu_code)
2. Crear un procedimiento ‘generarInformeGerencial’ que reciba un parámetro
fechaInforme y que en base a los datos de la tabla stock de todos los
productos existentes, inserte un registro de la tabla informeStock con la
siguiente información:
fechaInforme: fecha pasada por parámetro
stock_num: número de stock del producto
manu_code: código del fabricante
cantOrdenes: cantidad de órdenes que contengan el producto.
UltCompra: fecha de última orden para el producto evaluado.
cantClientes: cantidad de clientes únicos que hayan comprado el
producto.
totalVentas: Sumatoria de las ventas de ese producto (total_price)
Validar que no exista en la tabla informeStock un informe con la misma
fechaInforme recibida por parámetro.
*/
create table informeStock (
	fechaInforme datetime, 
	stock_num int, 
	manu_code char(3), 
	cantOrdenes int, 
	UltCompra datetime, 
	cantClientes int, 
	totalVentas decimal, 
	primary key(fechaInforme, stock_num, manu_code)
)
go

create procedure generarInformeGerencial
@fechaInforme datetime
as
begin
	declare prodsAInformarCursor cursor for
	select p.stock_num, p.manu_code, count(distinct i.order_num) as cantOrdenes, max(order_date) as UltCompra, 
	count(distinct customer_num) as cantClientes, sum(total_price) as totalVentas
	from products p join items i
		on(p.manu_code = i.manu_code and p.stock_num = i.stock_num)
			join orders o
				on(o.order_num = i.order_num)
	group by p.stock_num, p.manu_code

	declare @stockNum smallint, 
			@manuCode char(3), 
			@cantOrdenes int, 
			@ultCompra datetime, 
			@cantClientes int, 
			@totalVentas decimal

	open prodsAInformarCursor

	fetch prodsAInformarCursor into @stockNum, @manuCode, @cantOrdenes, @ultCompra, @cantClientes, @totalVentas

	while @@FETCH_STATUS = 0
	begin
		if not exists (select * from informeStock where fechaInforme = @fechaInforme and stock_num = @stockNum and manu_code = @manuCode)
		begin
			insert into informeStock (fechaInforme, stock_num, manu_code, cantOrdenes, UltCompra, cantClientes, totalVentas) 
				values (@fechaInforme, @stockNum, @manuCode, @cantOrdenes, @ultCompra, @cantClientes, @totalVentas) 
		end

		fetch next from prodsAInformarCursor into @stockNum, @manuCode, @cantOrdenes, @ultCompra, @cantClientes, @totalVentas
	end

	close prodsAInformarCursor
	deallocate prodsAInformarCursor
end

/*
f. Crear un procedimiento ‘generarInformeVentas’ que reciba un parámetro
fechaInforme y codEstado y que en base a los datos de la tabla customer de todos
los clientes que vivan en el estado pasado por parámetro, inserte un registro de la
tabla informeVentas con la siguiente información:
fechaInforme: fecha pasada por parámetro
codEstado: código de estado recibido por parámetro
customer_num: número de cliente
cantOrdenes: cantidad de órdenes del cliente.
primerVenta: fecha de la primer orden al cliente.
UltVenta: fecha de última orden al cliente.
cantProductos: cantidad de productos únicos que hayan
comprado el cliente.
totalVentas: Sumatoria de las ventas de ese producto (total_price)
Validar que no exista en la tabla informeVentas un informe con la misma
fechaInforme y estado recibido por parámetro.
*/
create table informeVentas (
	fechaInforme datetime,
	codEstado char(2) foreign key references state(code),
	customer_num smallint foreign key references customer(customer_num),
	cantOrdenes int,
	primerVenta datetime,
	UltVenta datetime,
	cantProductos int,
	totalVentas float,
	primary key(fechaInforme, customer_num)
)
go

create procedure generarInformeVentas
@fechaInforme datetime,
@codEstado char(2)
as
begin
	declare custsAInformarCursor cursor for
	select c.customer_num, count(distinct o.order_num) as cantOrdenes, min(order_date) as primerVenta, 
		max(order_date) as UltVenta, count(distinct cast(stock_num as char(3)) + manu_code) as cantProductos, sum(total_price) as totalVentas
	from customer c join orders o
		on(c.customer_num = o.customer_num)
			join items i
				on(o.order_num = i.order_num)
	where state = @codEstado
	group by c.customer_num

	declare @customerNum smallint, @cantOrdenes int, @primerVenta datetime, @ultVenta datetime, @cantProductos int, @totalVentas float

	open custsAInformarCursor

	fetch custsAInformarCursor into @customerNum, @cantOrdenes, @primerVenta, @ultVenta, @cantProductos, @totalVentas

	while @@FETCH_STATUS = 0
	begin
		if not exists (select * from informeVentas where fechaInforme = @fechaInforme and customer_num = @customerNum)
		begin
			insert into informeVentas (fechaInforme, codEstado, customer_num, cantOrdenes, primerVenta, UltVenta, cantProductos, totalVentas) 
				values (@fechaInforme, @codEstado, @customerNum, @cantOrdenes, @primerVenta, @ultVenta, @cantProductos, @totalVentas)
		end

		fetch next from custsAInformarCursor into @customerNum, @cantOrdenes, @primerVenta, @ultVenta, @cantProductos, @totalVentas
	end

	close custsAInformarCursor
	deallocate custsAInformarCursor
end