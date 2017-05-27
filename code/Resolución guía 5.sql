/*1) Obtener el n�mero de cliente, la compa��a, y n�mero de orden de todos los clientes que
tengan �rdenes. Ordenar el resultado por n�mero de cliente.

SELECT C.customer_num, company, order_num
	FROM customer C JOIN orders O
	ON(C.customer_num = O.customer_num)
	ORDER BY customer_num;*/
 
/*2) Listar los �tems de la orden n�mero 1004, incluyendo una descripci�n de cada uno. El
listado debe contener: N�mero de orden (order_num), N�mero de Item (item_num),
Descripci�n del producto (stock.description), C�digo del fabricante
(manu_code),Cantidad (quantity), Precio total (total_price).

SELECT order_num, item_num, description, I.manu_code, quantity, total_price
	FROM items I JOIN products P ON(I.stock_num = P.stock_num AND I.manu_code = P.manu_code)
	JOIN product_types T ON(P.stock_num = T.stock_num)
	WHERE order_num = 1004*/

/*3) Listar los items de la orden n�mero 1004, incluyendo una descripci�n de cada uno. El
listado debe contener: N�mero de orden (order_num), N�mero de Item (item_num),
Descripci�n del item (description), C�digo del fabricante (manu_code),Cantidad
(quantity), Precio total (total_price) y Nombre del fabricante (manu_name).

SELECT order_num, item_num, description, I.manu_code, quantity, total_price, manu_name
	FROM items I JOIN products P 
		ON(I.stock_num = P.stock_num AND I.manu_code = P.manu_code)
			JOIN product_types T ON(P.stock_num = T.stock_num)
				JOIN manufact M ON(M.manu_code = P.manu_code)
	WHERE order_num = 1004*/

/*4) Se desea listar todos los clientes que posean �rdenes de compra. Los datos a listar son
los siguientes: n�mero de orden, n�mero de cliente, nombre, apellido y compa��a.

SELECT order_num, O.customer_num, fname, lname, company
	FROM customer C JOIN orders O ON(O.customer_num = C.customer_num)*/

/*5) Se desea listar todos los clientes que posean �rdenes de compra. Los datos a listar son
los siguientes: n�mero de cliente, nombre, apellido y compa��a. Se requiere s�lo una fila
por cliente.

SELECT DISTINCT O.customer_num, fname, lname, company
	FROM customer C JOIN orders O ON(O.customer_num = C.customer_num)*/
	
/*6) Se requiere listar para armar una nueva lista de precios los siguientes datos: nombre del
fabricante (manu_name), n�mero de stock (stock_num), descripci�n (description),
unidad (unit), precio unitario (unit_price) y Precio Junio (precio unitario + 20%).

SELECT manu_name, P.stock_num, description, unit, unit_price, unit_price * 1.2 AS precio_junio
	FROM manufact M JOIN products P ON(P.manu_code = M.manu_code)
		JOIN units U ON(U.unit_code = P.unit_code)
			JOIN product_types T ON(P.stock_num = T.stock_num)*/

/*7) Se requiere un listado de los items de la orden de pedido Nro. 1004 con los siguienes
datos: N�mero de �tem (item_num), descripci�n de cada producto (description),
cantidad (quantity) y precio total (total_price).

SELECT item_num, description, quantity, total_price
	FROM items I JOIN products P ON(I.stock_num = P.stock_num AND I.manu_code = P.manu_code)
		JOIN product_types T ON(T.stock_num = P.stock_num)
	WHERE I.order_num = 1004*/

/*8) Informar el nombre del fabricante (manu_name) y el tiempo de env�o (lead_time) de las
ordenes del cliente 104.

SELECT manu_name, lead_time, O.order_num
	FROM orders O JOIN items I ON(O.order_num = I.order_num)
		JOIN products P ON(I.stock_num = P.stock_num AND I.manu_code = P.manu_code)
			JOIN manufact M ON(M.manu_code = P.manu_code)
	WHERE O.customer_num = 104*/

/*9) Se requiere un listado de las todas las �rdenes de pedido con los siguienes datos:
N�mero de orden (order_num), fecha de la orden (order_date), n�mero de �tem
(item_num), descripci�n de cada producto (description), cantidad (quantity) y precio
total (total_price).

SELECT O.order_num, order_date, item_num, description, quantity, total_price
	FROM orders O JOIN items I ON (O.order_num = I.order_num)
		JOIN products P ON(I.stock_num = P.stock_num AND I.manu_code = P.manu_code)
			JOIN product_types T ON(T.stock_num = P.stock_num)*/

/*10) Se requiere un listado con la siguiente informaci�n:
Apellido (lname), Nombre (fname) de Cliente N�mero de tel�fono (phone) Cantidad de ordenes
Se desea obtener concatenado el apellido & �, � & nombre
Se desea obtener el tel�fono con el sig. Formato (999) 999-9999

SELECT lname + ', ' + fname AS ayn, '(' + SUBSTRING(phone, 1, 3) + ') ' + SUBSTRING(phone, 5, 8), COUNT(order_num) cant_ordenes
	FROM customer C JOIN orders O ON(C.customer_num = O.customer_num)
	GROUP BY lname, fname, phone*/