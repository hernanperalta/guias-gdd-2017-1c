/*1) Obtener el número de cliente, la compañía, y número de orden de todos los clientes que
tengan órdenes. Ordenar el resultado por número de cliente.

SELECT C.customer_num, company, order_num
	FROM customer C JOIN orders O
	ON(C.customer_num = O.customer_num)
	ORDER BY customer_num;*/
 
/*2) Listar los ítems de la orden número 1004, incluyendo una descripción de cada uno. El
listado debe contener: Número de orden (order_num), Número de Item (item_num),
Descripción del producto (stock.description), Código del fabricante
(manu_code),Cantidad (quantity), Precio total (total_price).

SELECT order_num, item_num, description, I.manu_code, quantity, total_price
	FROM items I JOIN products P ON(I.stock_num = P.stock_num AND I.manu_code = P.manu_code)
	JOIN product_types T ON(P.stock_num = T.stock_num)
	WHERE order_num = 1004*/

/*3) Listar los items de la orden número 1004, incluyendo una descripción de cada uno. El
listado debe contener: Número de orden (order_num), Número de Item (item_num),
Descripción del item (description), Código del fabricante (manu_code),Cantidad
(quantity), Precio total (total_price) y Nombre del fabricante (manu_name).

SELECT order_num, item_num, description, I.manu_code, quantity, total_price, manu_name
	FROM items I JOIN products P 
		ON(I.stock_num = P.stock_num AND I.manu_code = P.manu_code)
			JOIN product_types T ON(P.stock_num = T.stock_num)
				JOIN manufact M ON(M.manu_code = P.manu_code)
	WHERE order_num = 1004*/

/*4) Se desea listar todos los clientes que posean órdenes de compra. Los datos a listar son
los siguientes: número de orden, número de cliente, nombre, apellido y compañía.

SELECT order_num, O.customer_num, fname, lname, company
	FROM customer C JOIN orders O ON(O.customer_num = C.customer_num)*/

/*5) Se desea listar todos los clientes que posean órdenes de compra. Los datos a listar son
los siguientes: número de cliente, nombre, apellido y compañía. Se requiere sólo una fila
por cliente.

SELECT DISTINCT O.customer_num, fname, lname, company
	FROM customer C JOIN orders O ON(O.customer_num = C.customer_num)*/
	
/*6) Se requiere listar para armar una nueva lista de precios los siguientes datos: nombre del
fabricante (manu_name), número de stock (stock_num), descripción (description),
unidad (unit), precio unitario (unit_price) y Precio Junio (precio unitario + 20%).

SELECT manu_name, P.stock_num, description, unit, unit_price, unit_price * 1.2 AS precio_junio
	FROM manufact M JOIN products P ON(P.manu_code = M.manu_code)
		JOIN units U ON(U.unit_code = P.unit_code)
			JOIN product_types T ON(P.stock_num = T.stock_num)*/

/*7) Se requiere un listado de los items de la orden de pedido Nro. 1004 con los siguienes
datos: Número de ítem (item_num), descripción de cada producto (description),
cantidad (quantity) y precio total (total_price).

SELECT item_num, description, quantity, total_price
	FROM items I JOIN products P ON(I.stock_num = P.stock_num AND I.manu_code = P.manu_code)
		JOIN product_types T ON(T.stock_num = P.stock_num)
	WHERE I.order_num = 1004*/

/*8) Informar el nombre del fabricante (manu_name) y el tiempo de envío (lead_time) de las
ordenes del cliente 104.

SELECT manu_name, lead_time, O.order_num
	FROM orders O JOIN items I ON(O.order_num = I.order_num)
		JOIN products P ON(I.stock_num = P.stock_num AND I.manu_code = P.manu_code)
			JOIN manufact M ON(M.manu_code = P.manu_code)
	WHERE O.customer_num = 104*/

/*9) Se requiere un listado de las todas las órdenes de pedido con los siguienes datos:
Número de orden (order_num), fecha de la orden (order_date), número de ítem
(item_num), descripción de cada producto (description), cantidad (quantity) y precio
total (total_price).

SELECT O.order_num, order_date, item_num, description, quantity, total_price
	FROM orders O JOIN items I ON (O.order_num = I.order_num)
		JOIN products P ON(I.stock_num = P.stock_num AND I.manu_code = P.manu_code)
			JOIN product_types T ON(T.stock_num = P.stock_num)*/

/*10) Se requiere un listado con la siguiente información:
Apellido (lname), Nombre (fname) de Cliente Número de teléfono (phone) Cantidad de ordenes
Se desea obtener concatenado el apellido & “, “ & nombre
Se desea obtener el teléfono con el sig. Formato (999) 999-9999

SELECT lname + ', ' + fname AS ayn, '(' + SUBSTRING(phone, 1, 3) + ') ' + SUBSTRING(phone, 5, 8), COUNT(order_num) cant_ordenes
	FROM customer C JOIN orders O ON(C.customer_num = O.customer_num)
	GROUP BY lname, fname, phone*/